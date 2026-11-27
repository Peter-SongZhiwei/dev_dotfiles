return {
    'dmtrKovalenko/fff',
    -- The upstream build hook and lazy.nvim both cap builds at 120 seconds,
    -- which a cold Rust build on this host exceeds. config.fff_build tries the
    -- prebuilt library first, checks it against the host glibc, and otherwise
    -- compiles from source without a timeout. See that file for when a rebuild
    -- happens and why the prebuilt is rejected on glibc 2.28 hosts.
    build = function(plugin)
        require('config.fff_build').build(plugin)
    end,
    lazy = false, -- the plugin lazy-initialises itself
    -- for nixos:
    -- build = "nix run .#release",
    opts = {
        prompt = '🦢 ',
        debug = {
            enabled = true,
            show_scores = true,
        },
    },
    keys = {
        { 'ff', function() require('fff').find_files() end, desc = 'FFFind files' },
        { 'fg', function() require('fff').live_grep() end, desc = 'LiFFFe grep' },
        {
            'fz',
            function() require('fff').live_grep({ grep = { modes = { 'fuzzy', 'plain' } } }) end,
            desc = 'Live fffuzy grep',
        },
        { 'fw', -- 查找cursor所在的位置
            function() require('fff').live_grep_under_cursor() end,
            mode = { 'n', 'x' },
            desc = 'Search current word / selection',
        },
    },
}
