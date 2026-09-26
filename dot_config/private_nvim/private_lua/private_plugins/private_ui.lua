return {
    -- upper bufferline
    {
        "akinsho/bufferline.nvim",
        after = "catppuccin",
        config = function()
            require("bufferline").setup({
                highlights = require("catppuccin.special.bufferline").get_theme(),
            })
        end,
        dependencies = { "nvim-tree/nvim-web-devicons" },
    },
    -- bracket / indent scope guide lines
    {
        "lukas-reineke/indent-blankline.nvim",
        main = "ibl",
        event = { "BufReadPre", "BufNewFile" },
        opts = {
            indent = { char = "│" },
            scope = { enabled = true, show_start = false, show_end = false },
        },
    },
    -- rainbow brackets: different color per nesting level (catppuccin mocha)
    {
        "HiPhish/rainbow-delimiters.nvim",
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            local groups = {
                RainbowDelimiterRed = "#f38ba8",
                RainbowDelimiterYellow = "#f9e2af",
                RainbowDelimiterBlue = "#89b4fa",
                RainbowDelimiterOrange = "#fab387",
                RainbowDelimiterGreen = "#a6e3a1",
                RainbowDelimiterViolet = "#cba6f7",
                RainbowDelimiterCyan = "#89dceb",
            }
            for name, fg in pairs(groups) do
                vim.api.nvim_set_hl(0, name, { fg = fg })
            end
            require("rainbow-delimiters.setup").setup({})
        end,
    },
    -- under status line
    {
        "nvim-lualine/lualine.nvim",
        opts = {
            options = {
                theme = "catppuccin",
                globalstatus = true,
            },
            sections = {
                lualine_a = { "mode" },
                lualine_b = { "diff", "diagnostics" },
                lualine_c = { "%S" },
                lualine_x = { "encoding", "fileformat", "filetype" },
                lualine_y = { "progress" },
                lualine_z = { "branch" },
            },
        },
        dependencies = { "nvim-tree/nvim-web-devicons" },
    },
}
