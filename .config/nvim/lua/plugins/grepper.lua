return {
  "mhinz/vim-grepper",
  init = function()
    local my_grepper = {}
    my_grepper.tools = { "rg", "ag", "git" }
    my_grepper.jump = 0
    my_grepper.quickfix = 1
    my_grepper.next_tool = "<leader>g"
    my_grepper.open = 2

    vim.g.grepper = my_grepper
  end,
  config = function()
    vim.keymap.set("n", "<leader>G", ":Grepper -tool rg<cr>")
    vim.keymap.set("n", "<leader>gg", ":Grepper -tool rg -quickfix -open<cr>")
  end
}
