-- diagnostic
vim.diagnostic.config({ virtual_text = true })

-- lsp config
-- vim.lsp.enable("jedi_language_server")
-- vim.lsp.enable("pyright")
vim.lsp.enable("bashls")
vim.lsp.enable("lua_ls")
vim.lsp.enable("neocmake")
vim.lsp.enable("clangd")
vim.lsp.enable("rust_analyzer")
vim.lsp.enable("denols")
vim.lsp.enable("tombi")
vim.lsp.enable("ty")
vim.lsp.enable("ruff")
vim.lsp.enable("nushell")
vim.lsp.enable("hls")

local autocmd = vim.api.nvim_create_autocmd
-- codelens and inlay hints
autocmd("LspAttach", {
    callback = function(args)
        local bufnr = args.buf
        local client = vim.lsp.get_client_by_id(args.data.client_id)

        if client:supports_method("textDocument/codeLens") then
            vim.lsp.codelens.refresh()
            vim.api.nvim_create_autocmd({ "BufEnter", "InsertLeave" }, {
                buffer = bufnr,
                callback = vim.lsp.codelens.refresh,
            })
        end

        if client:supports_method("textDocument/inlayHint") then
            vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
        end
    end,
})
