return {
    "stevearc/conform.nvim",
    lazy = true,
    cmd = "ConformInfo",
    opts = {
        formatters_by_ft = {
            python = { "ruff" },
            lua = { "stylua" },
            c = { "clang-format" },
            cpp = { "clang-format" },
            sh = { "shfmt" },
            json = { "biome" },
            jsonc = { "biome" },
            javascript = { "biome" },
        },
        default_format_opts = {
            lsp_format = "first",
        },
    },
    keys = {
        {
            "<leader>=",
            function()
                require("conform").format()
            end,
            desc = "format",
        },
    },
}
