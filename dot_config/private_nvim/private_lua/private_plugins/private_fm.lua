-- file manager
return {
    {
        "stevearc/oil.nvim",
        opts = {
            skip_confirm_for_simple_edits = true,
            float = {
                max_width = 0.8,
                max_height = 0.8,
            },
        },
        dependencies = { "nvim-tree/nvim-web-devicons" },
        lazy = false,
    },
}
