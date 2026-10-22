local map = vim.keymap.set

-- oil configurations
local oil = require("oil")
map("n", "<leader>n", oil.toggle_float, { desc = "Toggle oil floating window" })

-- useful map
map("n", "H", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
map("n", "L", "<cmd>bnext<cr>", { desc = "Next buffer" })

-- lsp map
map("n", "<leader>r", vim.lsp.buf.rename, { desc = "Lsp rename", silent = true })
map("n", "<leader>a", vim.lsp.buf.code_action, { desc = "Lsp action", silent = true })
map("n", "gd", vim.lsp.buf.definition, { desc = "Lsp def", silent = true })
map("n", "gi", vim.lsp.buf.implementation, { desc = "Lsp impl", silent = true })
map("n", "J", vim.diagnostic.open_float, { desc = "Open diagnostic", silent = true })
map("n", "<leader>i", function()
    vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ 0 }), { 0 })
end)

-- useful map
map("v", "<A-j>", ":m '>+1<cr>gv=gv", { desc = "move down", silent = true })
map("v", "<A-k>", ":m '<-2<cr>gv=gv", { desc = "move up", silent = true })

map('n', '<A-k>', ':m .-2<CR>==', { desc = '交换行与上一行' })
map('n', 'K', ':m .-2<CR>==', { desc = '交换行与上一行' })
map('n', '<A-j>', ':m .+1<CR>==', { desc = '交换行与下一行' })
map('n', 'J', ':m .+1<CR>==', { desc = '交换行与下一行' })

map("v", "<c-c>", '"+y', { desc = "Copy to clipboard", silent = false })
map("i", "<c-v>", function()
  vim.api.nvim_put(vim.fn.getreg("+", 1, true), "c", false, true)
end, { desc = "Paste from system clipboard", silent = true })

-- better indenting
map("v", "<", "<gv")
map("v", ">", ">gv")

-- visual normal
map("v", ".", ":norm.<cr>", { desc = "Visual normal" })

-- ==========================================================
--  VS Code vim parity (ported from Code/User/settings.json)
-- ==========================================================

-- black-hole delete (don't clobber clipboard): x / <leader>d
map("n", "x", '"_x', { desc = "Delete char (black hole)" })
map({ "n", "x" }, "<leader>d", '"_d', { desc = "Delete (black hole)" })

-- inner-word operations: D / Y / P / <leader>v / <leader>y
map("n", "D", "diw", { desc = "Delete inner word" })
map("n", "Y", "viwy", { desc = "Yank inner word" })
map("n", "P", 'viw"_dhp', { desc = "Replace word with register" })
map("n", "<leader>v", "viw", { desc = "Select inner word" })
map("n", "<leader>y", "viwy", { desc = "Yank inner word" })

-- buffer: <leader>w save-all / <leader>q close / <leader>x save+close
map("n", "<leader>w", "<cmd>wa<cr>", { desc = "Save all buffers" })
map("n", "<leader>q", "<cmd>bd<cr>", { desc = "Close buffer" })
map("n", "<leader>x", "<cmd>w | bd<cr>", { desc = "Save & close buffer" })

-- lsp extras: gr references / gD def-aside / [d ]d diagnostics
map("n", "gr", vim.lsp.buf.references, { desc = "Lsp references", silent = true })
map("n", "gD", function()
    vim.cmd.vsplit()
    vim.lsp.buf.definition()
end, { desc = "Lsp def in vsplit", silent = true })
map("n", "[d", function()
    vim.diagnostic.jump({ count = -1, float = true })
end, { desc = "Prev diagnostic", silent = true })
map("n", "]d", function()
    vim.diagnostic.jump({ count = 1, float = true })
end, { desc = "Next diagnostic", silent = true })

-- visual: $->g_ / J K move line / surround ( [ {
map("x", "$", "g_", { desc = "Last non-blank char" })
map("x", "J", ":m '>+1<cr>gv=gv", { desc = "Move line down", silent = true })
map("x", "K", ":m '<-2<cr>gv=gv", { desc = "Move line up", silent = true })
map("x", "(", "S)", { remap = true, desc = "Surround ()" })
map("x", "[", "S[", { remap = true, desc = "Surround []" })
map("x", "{", "S{", { remap = true, desc = "Surround {}" })



