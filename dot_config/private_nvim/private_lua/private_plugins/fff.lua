local fff_dir = vim.fn.expand('~/tools/fff')
local use_local = vim.fn.isdirectory(fff_dir) == 1
if not use_local then
  vim.fn.system({ 'git', 'clone', '--depth=1', 'https://github.com/dmtrKovalenko/fff.git', fff_dir })
  use_local = vim.v.shell_error == 0
end

return {
  'dmtrKovalenko/fff',
  dir = use_local and fff_dir or nil,
  build = use_local and '$HOME/.cargo/bin/cargo build --release -p fff-nvim' or function()
    -- downloads a prebuilt binary or falls back to cargo build
    require("fff.download").download_or_build_binary()
  end,
  lazy = false, -- the plugin lazy-initialises itself
  -- for nixos:
  -- build = "nix run .#release",
  opts = {
    prompt = '👉👉👉  ',
    debug = {
      enabled = true,
      show_scores = true,
    },
  },
  keys = {
    { "ff", function() require('fff').find_files() end, desc = 'FFFind files' },
    { "fg", function() require('fff').live_grep() end, desc = 'LiFFFe grep' },
    { "fz",
      function() require('fff').live_grep({ grep = { modes = { 'fuzzy', 'plain' } } }) end,
      desc = 'Live fffuzy grep',
    },
    { "fw", -- 查找cursor所在的位置
      function() require('fff').live_grep_under_cursor() end,
      mode = { 'n', 'x' },
      desc = 'Search current word / selection',
    },
  },
}
