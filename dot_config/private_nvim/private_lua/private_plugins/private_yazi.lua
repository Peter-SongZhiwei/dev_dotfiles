-- file manager
return {
    {
        "mikavilpas/yazi.nvim",
        version = "*",
        lazy = false,
        init = function()
            vim.g.loaded_netrwPlugin = 1
        end,
        dependencies = {
            { "nvim-lua/plenary.nvim", lazy = true },
        },
        keys = {
            {
                "<leader>n",
                "<cmd>Yazi<cr>",
                desc = "Open yazi at the current file",
            },
            {
                "<leader>-",
                mode = { "n", "v" },
                "<cmd>Yazi<cr>",
                desc = "Open yazi at the current file",
            },
            {
                "<leader>cw",
                "<cmd>Yazi cwd<cr>",
                desc = "Open yazi in Neovim's working directory",
            },
            {
                "<c-up>",
                "<cmd>Yazi toggle<cr>",
                desc = "Resume the last yazi session",
            },
        },
        opts = {
            open_for_directories = true,
            keymaps = {
                show_help = "<f1>",
            },
        },
    },
}
