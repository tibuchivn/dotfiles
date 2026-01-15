return {
  "vim-test/vim-test",
  dependencies = { "preservim/vimux" },
  config = function()
    vim.g["test#vim#term_position"] = "belowright"
    -- vim.g["test#strategy"] = "vimux"
    vim.g["test#strategy"] = "basic"
    vim.g["test#ruby#use_binstubs"] = 0
    vim.g["test#basic#start_normal"] = 1

    vim.keymap.set("n", "<leader>f", ":TestFile<cr>")
    vim.keymap.set("n", "<leader>s", ":TestNearest<cr>")
    vim.keymap.set("n", "<leader>l", ":TestLast<cr>")
  end
}
