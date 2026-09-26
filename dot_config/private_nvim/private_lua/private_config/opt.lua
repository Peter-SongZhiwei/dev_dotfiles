vim.g.mapleader = " "
vim.g.maplocalleader = ","
local opt = vim.opt

-- search
opt.ignorecase = true
opt.smartcase = true

-- show number
opt.number = true
opt.relativenumber = true
opt.cursorline = true

-- tab config
-- > < operator shiftwidth
opt.shiftwidth = 4
-- tab key behavior
opt.softtabstop = 4
-- expand tab to spaces
opt.expandtab = true

-- force using true color
opt.termguicolors = true

-- terminal features
local termfeatures = vim.g.termfeatures or {}
termfeatures.osc52 = true
vim.g.termfeatures = termfeatures
-- vim.opt.clipboard = "unnamedplus" +寄存器也设置为默认寄存器 yank->"+ reg -> osc52 -> <tmux> -> terminal -> windows clipboard

-- Don't show mode since we have a status line
opt.showmode = false

-- list chars
opt.list = true
opt.listchars = "tab:➜ ,trail:·,extends:❯,precedes:❮"

-- no word wrap
opt.wrap = false
opt.showcmdloc = "statusline"
opt.cmdheight = 0

-- scroll config
opt.smoothscroll = true

-- confirm to save changes when leave
opt.confirm = true

-- don't show some messages
opt.shortmess:append({ I = true, c = true, C = true })

-- window border
opt.winborder = "rounded"

-- set vim grep using ripgrep
if vim.fn.executable("rg") then
    opt.grepformat = "%f:%l:%c:%m"
    opt.grepprg = "rg --vimgrep --smart-case"
end
