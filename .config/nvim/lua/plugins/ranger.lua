return {
  "francoiscabrol/ranger.vim",
  dependencies = { "rbgrouleff/bclose.vim" },
  config = function()
    vim.g.ranger_map_keys = 0
    vim.keymap.set("n", "<leader>E", ":Ranger<cr>")
  end
}
