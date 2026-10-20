return {
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require('gitsigns').setup{
        -- on_attach = function(bufnr)
          --   -- Navigation
          --   map('n', ']c', "&diff ? ']c' : '<cmd>Gitsigns next_hunk<CR>'", {expr=true})
          --   map('n', '[c', "&diff ? '[c' : '<cmd>Gitsigns prev_hunk<CR>'", {expr=true})
          -- end
        }
    end
  },
  {
    "rhysd/git-messenger.vim"
  }
}
