return {
  "ludovicchabant/vim-gutentags",
  config = function()
    vim.cmd([[
      if &diff
        let g:gutentags_enabled = 0
      endif
    ]])
  end
}
