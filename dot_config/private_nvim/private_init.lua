require("config.lazy")
vim.cmd.colorscheme("catppuccin")
require("config.lsp")
require("config.map")
require("config.autocmd") 


vim.filetype.add({
  extension = {
    -- 格式: 文件扩展名 = 文件类型
    ac = 'cpp',
    -- 可以在这里添加更多，例如:
    -- txt = 'text',
  }
})
