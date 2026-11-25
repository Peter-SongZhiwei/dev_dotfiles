-- lazy-lock.json is managed by chezmoi as dot_config/private_nvim/private_lazy-lock.json.
-- lazy.nvim only rewrites it on update/install/clean, never when a spec is added
-- or removed, so it can silently go stale (it once lost four plugin pins that way).
-- After changing plugins on purpose, run :Lazy update or :Lazy clean and commit
-- the resulting lockfile explicitly.

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local lazyrepo = "https://github.com/folke/lazy.nvim.git"
    local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
    if vim.v.shell_error ~= 0 then
        vim.api.nvim_echo({
            { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
            { out, "WarningMsg" },
            { "\nPress any key to exit..." },
        }, true, {})
        vim.fn.getchar()
        os.exit(1)
    end
end
vim.opt.rtp:prepend(lazypath)

-- Make sure to setup `mapleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
require("config.opt")

-- Setup lazy.nvim
require("lazy").setup({
    -- 默认插件路径 ~/.local/share/nvim/lazy/
    -- 可以自定义路径 root=path/to/lazy-pulgin/
    spec = {
        -- import your plugins
        { import = "plugins" },
    },
    -- Configure any other settings here. See the documentation for more details.
    -- colorscheme that will be used when installing plugins.
    install = { colorscheme = { "catppuccin" } },
    -- No automatic update checks: updates stay deliberate. :Lazy update is
    -- expensive here because moved plugin commits re-run build hooks (fff
    -- compiles Rust for minutes on glibc 2.28 hosts), and it also rewrites the
    -- chezmoi-managed lockfile. :Lazy restore only checks out pinned commits and
    -- skips builds unless a checkout actually changes a plugin's commit.
    checker = { enabled = false },
    -- disable lua rocks
    rocks = {
        enabled = false,
    },
})
