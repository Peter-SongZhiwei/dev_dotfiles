return {
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        branch = "main",
        config = function()
            local treesitter = require("nvim-treesitter")
            treesitter.setup({})
            -- install when open nvim
            local should_install = {
                "bash",
                "c",
                "cpp",
                "cmake",
                "csv",
                "just",
                "json",
                "lua",
                "markdown",
                "markdown_inline",
                "make",
                "nu",
                "python",
                "rust",
                "toml",
                "vim",
                "vimdoc",
                "yaml",
            }

            treesitter.install(should_install)

            -- 保证编译用的 tree-sitter CLI 存在。缺失时后台异步安装，
            -- 装好后补编 parser 并给已打开的 buffer 补上高亮（无需重启）。
            require("config.treesitter_bootstrap").ensure({
                auto_install = true,
                on_success = function()
                    treesitter.install(should_install)
                    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                        if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype ~= "" then
                            pcall(vim.treesitter.start, buf)
                        end
                    end
                end,
            })

            vim.api.nvim_create_autocmd("FileType", {
                callback = function(args)
                    if vim.list_contains(treesitter.get_installed(), vim.treesitter.language.get_lang(args.match)) then
                        vim.treesitter.start(args.buf)
                    end
                end,
            })
        end,
    },
}
