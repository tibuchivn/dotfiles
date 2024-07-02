return {
  {
    "tpope/vim-rails"
  },
  {
    "vim-ruby/vim-ruby",
    init = function()
      vim.g.loaded_ruby_provider = 0
      vim.g.ruby_indent_block_style = "do"
      vim.g.ruby_indent_assignment_style = "variable" -- hanging
    end
  }
}
