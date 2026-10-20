return {
  {
    "junegunn/goyo.vim",
    init = function()
      vim.g.goyo_linenr = 1
      vim.g.goyo_width = 120
      vim.g.goyo_height = "100%"
    end,
    config = function()
      vim.keymap.set("n", "<leader>z", ":Goyo<cr>")
      vim.cmd([[
      command! ShowLuaLine lua require('lualine').hide({unhide=true})
      command! HideLuaLine lua require('lualine').hide()
      autocmd! User GoyoEnter nested HideLuaLine
      autocmd! User GoyoLeave nested ShowLuaLine
      ]])
    end
  },
  {
    "junegunn/vim-easy-align",
    config = function()
      vim.keymap.set("x", "ga", "<Plug>(EasyAlign)")
      vim.keymap.set("n", "ga", "<Plug>(EasyAlign)")
    end
  },
}
