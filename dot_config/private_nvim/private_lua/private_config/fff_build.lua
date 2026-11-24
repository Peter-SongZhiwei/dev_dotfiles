-- Build hook for dmtrKovalenko/fff.
--
-- Two independent 120-second limits break the upstream build path on machines
-- whose glibc is older than the prebuilt release. A cold cargo build takes
-- several minutes here, so both limits fire in the middle of the compile:
--
--   * fff's own download_or_build_binary() waits at most two minutes
--   * lazy.nvim kills every command it spawns after `git.timeout` (120 s)
--
-- This module owns the whole build instead: it prefers the prebuilt library,
-- rejects it when its glibc requirement exceeds the host's, and otherwise
-- compiles through vim.system():wait(), which has no timeout.

local M = {}

local uv = vim.uv
local log = vim.log.levels

---@param message string
---@param level? integer
local function notify(message, level)
    vim.notify('fff.nvim: ' .. message, level or log.INFO)
end

---Run a command and block until it exits.
---@param cmd string[]
---@param opts? table
---@return vim.SystemCompleted
local function run(cmd, opts)
    opts = opts or {}
    opts.text = true
    return vim.system(cmd, opts):wait()
end

---@param cmd string[]
---@return string|nil
local function output_of(cmd)
    local ok, result = pcall(run, cmd)
    if not ok or result.code ~= 0 then return nil end
    return (result.stdout or '') .. (result.stderr or '')
end

---@class GlibcVersion
---@field major integer
---@field minor integer

---@param text string
---@return GlibcVersion|nil
local function parse_glibc_version(text)
    local major, minor = text:match('(%d+)%.(%d+)')
    if not major then return nil end
    return { major = tonumber(major), minor = tonumber(minor) }
end

---@param a GlibcVersion
---@param b GlibcVersion
---@return boolean
local function is_newer(a, b)
    if a.major ~= b.major then return a.major > b.major end
    return a.minor > b.minor
end

---@param required GlibcVersion
---@param provided GlibcVersion
---@return boolean
local function is_compatible(required, provided)
    if required.major ~= provided.major then return required.major < provided.major end
    return required.minor <= provided.minor
end

---@param version GlibcVersion
---@return string
local function format_version(version)
    return string.format('%d.%d', version.major, version.minor)
end

---glibc version of the running host.
---@return GlibcVersion|nil
local function host_glibc()
    return parse_glibc_version(output_of({ 'ldd', '--version' }) or '')
        or parse_glibc_version(output_of({ 'getconf', 'GNU_LIBC_VERSION' }) or '')
end

---Highest glibc symbol version required by a shared library. The dynamic symbol
---table is authoritative, so no guess work from the build environment is needed.
---@param path string
---@return GlibcVersion|nil
local function required_glibc(path)
    local tools = {
        { 'readelf', '--version-info', '--wide', path },
        { 'objdump', '-T', path },
    }

    for _, cmd in ipairs(tools) do
        if vim.fn.executable(cmd[1]) == 1 then
            local output = output_of(cmd)
            if output then
                local highest
                for major, minor in output:gmatch('GLIBC_(%d+)%.(%d+)') do
                    local version = { major = tonumber(major), minor = tonumber(minor) }
                    if not highest or is_newer(version, highest) then highest = version end
                end
                if highest then return highest end
            end
        end
    end

    return nil
end

---@return string
local function library_extension()
    local sysname = uv.os_uname().sysname:lower()
    if sysname == 'darwin' then return 'dylib' end
    if sysname:match('windows') then return 'dll' end
    return 'so'
end

---@param plugin_dir string
---@return string
local function library_path(plugin_dir)
    return plugin_dir .. '/target/release/libfff_nvim.' .. library_extension()
end

---@param path string
---@return boolean loaded, string? err
local function loads(path)
    if uv.fs_stat(path) == nil then return false, 'file not found' end
    local loader, err = package.loadlib(path, 'luaopen_fff_nvim')
    if not loader then return false, err end
    return true
end

---True when an existing binary loads and was produced from the current commit.
---@param plugin_dir string
---@return boolean
local function is_current(plugin_dir)
    if vim.env.FFF_FORCE_BUILD == '1' then return false end

    local stat = uv.fs_stat(library_path(plugin_dir))
    if not stat or not loads(library_path(plugin_dir)) then return false end

    local commit_time = output_of({ 'git', '-C', plugin_dir, 'log', '-1', '--format=%ct' })
    local committed_at = tonumber((commit_time or ''):match('%d+') or '')
    if not committed_at then return true end

    return stat.mtime.sec >= committed_at
end

---Release tag the current checkout downloads binaries from. Reuses fff's own
---helper so nightly builds resolve to their per-commit release.
---@param plugin_dir string
---@return string|nil
local function release_tag(plugin_dir)
    local ok, versions = pcall(require, 'fff.utils.version')
    if not ok then return nil end

    local tag = versions.current_release_tag(plugin_dir)
    if tag then return tag end

    local info = versions.resolve(plugin_dir)
    return info and info.release_tag or nil
end

---@param plugin_dir string
---@return string
local function target_triple(plugin_dir)
    local ok, system = pcall(require, 'fff.utils.system')
    if ok and type(system.get_triple) == 'function' then return system.get_triple() end

    local uname = uv.os_uname()
    local arch = uname.machine:lower()
    local sysname = uname.sysname:lower()
    if sysname == 'darwin' then return arch .. '-apple-darwin' end
    if sysname:match('windows') then return arch .. '-pc-windows-msvc' end
    return arch .. '-unknown-linux-gnu'
end

---@param url string
---@param destination string
---@return boolean ok, string? err
local function download(url, destination)
    vim.fn.mkdir(vim.fn.fnamemodify(destination, ':h'), 'p')

    local result = run({
        'curl', '--fail', '--location', '--silent', '--show-error',
        '--output', destination, url,
    })
    if result.code ~= 0 then
        return false, (result.stderr or 'curl failed'):gsub('%s+$', '')
    end
    return true
end

---Download the prebuilt library and install it when the host can run it.
---@param plugin_dir string
---@return boolean installed, string? reason
local function install_prebuilt(plugin_dir)
    local tag = release_tag(plugin_dir) --[[@as string|nil]]
    if not tag then return false, 'could not determine the release tag' end

    local asset = target_triple(plugin_dir) .. '.' .. library_extension()
    local url = ('https://github.com/dmtrKovalenko/fff/releases/download/%s/%s'):format(tag, asset)
    local destination = library_path(plugin_dir)
    local staging = destination .. '.download'

    notify(('trying prebuilt %s (%s)'):format(tag, asset))
    local downloaded, download_err = download(url, staging)
    if not downloaded then
        uv.fs_unlink(staging)
        return false, 'download failed: ' .. (download_err or 'unknown error')
    end

    -- A prebuilt that needs a newer glibc fails inside dlopen with an
    -- unhelpful "cannot map segments from shared object" error, so compare the
    -- version requirement before attempting to load it.
    local required, provided = required_glibc(staging), host_glibc()
    if required and provided and not is_compatible(required, provided) then
        uv.fs_unlink(staging)
        return false,
            ('prebuilt requires glibc %s, host provides %s'):format(format_version(required), format_version(provided))
    end

    local loaded, load_err = loads(staging)
    if not loaded then
        uv.fs_unlink(staging)
        return false, 'prebuilt is not loadable: ' .. (load_err or 'unknown error')
    end

    -- Safe on Linux/macOS: the staging file is already mapped and the next
    -- Neovim session opens the final path.
    local renamed, rename_err = uv.fs_rename(staging, destination)
    if not renamed then
        uv.fs_unlink(staging)
        return false, 'could not install the prebuilt library: ' .. tostring(rename_err)
    end

    notify(('prebuilt %s installed'):format(tag))
    return true
end

---@return string|nil
local function cargo_executable()
    local candidates = {}
    local from_env = vim.env.CARGO
    if from_env and from_env ~= '' then table.insert(candidates, from_env) end
    table.insert(candidates, (vim.env.HOME or '') .. '/.cargo/bin/cargo')
    table.insert(candidates, 'cargo')

    for _, candidate in ipairs(candidates) do
        if vim.fn.executable(candidate) == 1 then return candidate end
    end
    return nil
end

---@param text string|nil
---@param lines integer
---@return string
local function tail(text, lines)
    local kept = {}
    for line in (text or ''):gmatch('[^\n]*') do
        kept[#kept + 1] = line
        if #kept > lines then table.remove(kept, 1) end
    end
    return table.concat(kept, '\n')
end

---@param plugin_dir string
local function build_from_source(plugin_dir)
    local cargo = cargo_executable()
    if not cargo then
        error('fff.nvim: cargo not found. Install Rust from https://rustup.rs and rerun :Lazy build fff')
    end

    notify('compiling from source; a cold Rust build can take several minutes')
    local started = uv.hrtime()
    local compiled = 0

    local result = run({ cargo, 'build', '--release', '-p', 'fff-nvim' }, {
        cwd = plugin_dir,
        stderr = function(_, data)
            for line in (data or ''):gmatch('[^\n]+') do
                if line:match('^%s+Compiling') then
                    compiled = compiled + 1
                    if compiled % 25 == 0 then notify(('compiling… %d crates'):format(compiled)) end
                end
            end
        end,
    })

    local seconds = (uv.hrtime() - started) / 1e9
    if result.code ~= 0 then
        error(('fff.nvim: cargo build failed after %.0fs\n%s'):format(seconds, tail(result.stderr, 30)))
    end

    local loaded, load_err = loads(library_path(plugin_dir))
    if not loaded then
        error('fff.nvim: built library cannot be loaded: ' .. (load_err or 'unknown error'))
    end

    notify(('compiled from source in %.0fs'):format(seconds))
end

---lazy.nvim build entry point.
---@param plugin table
function M.build(plugin)
    local plugin_dir = plugin.dir
    vim.opt.rtp:prepend(plugin_dir)

    if is_current(plugin_dir) then
        notify('binary is up to date')
        return
    end

    local installed, reason = install_prebuilt(plugin_dir)
    if installed then return end

    notify('prebuilt rejected: ' .. (reason or 'unknown error') .. '; falling back to cargo', log.WARN)
    build_from_source(plugin_dir)
end

return M
