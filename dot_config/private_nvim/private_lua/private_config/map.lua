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



