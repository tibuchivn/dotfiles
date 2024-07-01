return {
  "mhinz/vim-grepper",
  config = function()
    vim.g.grepper.tools = { "rg", "ag", "git" }
    vim.g.grepper.jump = 0
    vim.g.grepper.quickfix = 1
    vim.g.grepper.next_tool = "<leader>g"
    vim.g.grepper.open = 1

    vim.keymap.set("n", "<leader>G", ":Grepper -tool rg<cr>")
    vim.keymap.set("n", "<leader>gg", ":Grepper -tool rg -quickfix -open<cr>")
  end
}
