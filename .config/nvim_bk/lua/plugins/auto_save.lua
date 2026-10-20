return {
  "907th/vim-auto-save",
  init = function()
    vim.g.auto_save = 1
    vim.g.auto_save_events = { "InsertLeave", "TextChanged" }
  end,
}
