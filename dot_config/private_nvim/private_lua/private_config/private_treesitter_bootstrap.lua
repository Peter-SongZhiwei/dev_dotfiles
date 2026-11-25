-- 保证 nvim-treesitter 能找到可用的 tree-sitter CLI。
-- 上游的失败只写内存日志（:TSLog），这里改为落盘 + 明确 notify。
-- auto_install 走后台异步链：不阻塞启动，装好后回调 on_success。
local M = {}

local MIN_VERSION = "0.26.1"
local BIN_DIR = vim.fs.joinpath(vim.fn.expand("~"), ".local", "bin")
local LOG = vim.fs.joinpath(vim.fn.stdpath("state"), "treesitter-bootstrap.log")

local state = { running = false }

local function log(msg)
    local fd = io.open(LOG, "a")
    if not fd then
        return
    end
    fd:write(("[%s] %s\n"):format(os.date("%Y-%m-%d %H:%M:%S"), msg))
    fd:close()
end

local function parse_version(str)
    local major, minor = str:match("(%d+)%.(%d+)")
    return major and tonumber(major), minor and tonumber(minor)
end

local function version_ok(str)
    local major, minor = parse_version(str)
    local need_major, need_minor = parse_version(MIN_VERSION)
    if not major then
        return false
    end
    if major ~= need_major then
        return major > need_major
    end
    return minor >= need_minor
end

--- 本机 glibc minor 版本（2.28 -> 28）；非 glibc 系统返回 nil
local function glibc_minor()
    local r = vim.system({ "ldd", "--version" }, { text = true }):wait(5000)
    if r.code ~= 0 then
        return nil
    end
    local _, minor = r.stdout:match("(%d+)%.(%d+)")
    return minor and tonumber(minor)
end

--- 探测某路径能否真正执行；glibc 不匹配会在这一步暴露，而不是等到编译时
local function usable(path)
    if vim.fn.executable(path) ~= 1 then
        return nil
    end
    local r = vim.system({ path, "--version" }, { text = true }):wait(5000)
    if r.code ~= 0 then
        log(("CLI 不可执行（疑似 glibc 不匹配）: %s -> %s"):format(path, vim.trim(r.stderr or "")))
        return nil
    end
    local version = vim.trim(r.stdout or "")
    if not version_ok(version) then
        log(("CLI 版本过低: %s (%s < %s)"):format(path, version, MIN_VERSION))
        return nil
    end
    return path, version
end

--- 按优先级探测：PATH -> ~/.local/bin
local function find_cli()
    -- 不能用 `a or b`，那样会把第二个返回值（版本号）丢掉
    local path, version = usable("tree-sitter")
    if path then
        return path, version
    end
    return usable(vim.fs.joinpath(BIN_DIR, "tree-sitter"))
end

local function add_to_path()
    if not vim.env.PATH:find(BIN_DIR, 1, true) then
        vim.env.PATH = BIN_DIR .. ":" .. vim.env.PATH
    end
end

local function notify(msg, level)
    vim.schedule(function()
        vim.notify(msg, level)
    end)
end

--- 安装策略：run(done) 必须异步回调，绝不 :wait()，避免卡住编辑器
local strategies = {
    {
        name = "官方预编译资产(glibc>=2.35)",
        available = function()
            local minor = glibc_minor()
            return minor ~= nil and minor >= 35
        end,
        run = function(done)
            local url = "https://github.com/tree-sitter/tree-sitter/releases/download/v0.27.2/tree-sitter-linux-x64.gz"
            local target = vim.fs.joinpath(BIN_DIR, "tree-sitter")
            vim.system(
                { "bash", "-c", ("mkdir -p %s && curl -sSfL %s | gunzip > %s && chmod +x %s"):format(BIN_DIR, url, target, target) },
                { text = true },
                function(r)
                    done(r.code == 0, vim.trim(r.stderr or ""))
                end
            )
        end,
    },
    {
        name = "cargo 源码编译",
        available = function()
            return vim.fn.executable("cargo") == 1 and vim.fn.executable("cc") == 1
        end,
        run = function(done)
            vim.system(
                { "cargo", "install", "tree-sitter-cli", "--locked", "--root", vim.fs.dirname(BIN_DIR) },
                { text = true },
                function(r)
                    done(r.code == 0, vim.trim(r.stderr or ""))
                end
            )
        end,
    },
    {
        name = "rustup 引导后源码编译",
        available = function()
            local minor = glibc_minor()
            return minor ~= nil and minor >= 17 and vim.fn.executable("cc") == 1
        end,
        run = function(done)
            -- --no-modify-path: 不碰 chezmoi 管理的 .bashrc/.profile
            vim.system(
                { "bash", "-c", "curl -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path --profile minimal" },
                { text = true },
                function(r)
                    if r.code ~= 0 then
                        return done(false, "rustup 安装失败: " .. vim.trim(r.stderr or ""))
                    end
                    local cargo = vim.fs.joinpath(vim.fn.expand("~"), ".cargo", "bin", "cargo")
                    vim.system(
                        { cargo, "install", "tree-sitter-cli", "--locked", "--root", vim.fs.dirname(BIN_DIR) },
                        { text = true },
                        function(b)
                            done(b.code == 0, vim.trim(b.stderr or ""))
                        end
                    )
                end
            )
        end,
    },
}

local function succeed(path, version, opts)
    add_to_path()
    log(("安装成功: %s (%s)"):format(path, version))
    notify(("tree-sitter CLI 就绪 (%s)，开始后台编译 parser"):format(version), vim.log.levels.INFO)
    state.running = false
    if opts.on_success then
        vim.schedule(opts.on_success)
    end
end

local function try_strategy(list, index, opts)
    local strategy = list[index]
    if not strategy then
        state.running = false
        log("所有安装策略均失败")
        notify("tree-sitter CLI 安装失败，详见 " .. LOG, vim.log.levels.ERROR)
        return
    end

    if not strategy.available() then
        log(("策略跳过(不适用): %s"):format(strategy.name))
        return try_strategy(list, index + 1, opts)
    end

    log(("尝试策略: %s"):format(strategy.name))
    strategy.run(function(ok, detail)
        vim.schedule(function()
            if ok then
                local path, version = find_cli()
                if path then
                    return succeed(path, version, opts)
                end
                detail = "安装后仍不可执行"
            end
            log(("策略失败: %s (%s)"):format(strategy.name, detail or ""))
            try_strategy(list, index + 1, opts)
        end)
    end)
end

--- @param opts? { auto_install?: boolean, notify?: boolean, on_success?: function, strategies?: table }
--- @return boolean cli_available_now 本次会话是否已可用（后台安装未完成时为 false）
function M.ensure(opts)
    opts = vim.tbl_extend("force", { auto_install = false, notify = true, strategies = strategies }, opts or {})

    local path, version = find_cli()
    if path then
        add_to_path()
        log(("CLI 可用: %s (%s)"):format(path, version))
        return true
    end

    if not opts.auto_install then
        log("CLI 缺失，且未开启 auto_install")
        if opts.notify then
            notify("tree-sitter CLI 缺失：新增/更新语法将静默失败。\n安装：cargo install tree-sitter-cli --locked --root ~/.local", vim.log.levels.WARN)
        end
        return false
    end

    if state.running then
        return false
    end

    state.running = true
    log("CLI 缺失，启动后台安装链")
    if opts.notify then
        notify("缺少 tree-sitter CLI，正在后台安装（不阻塞编辑器，稍后自动编译语法）…", vim.log.levels.WARN)
    end
    vim.schedule(function()
        try_strategy(opts.strategies, 1, opts)
    end)
    return false
end

return M
