return {
  {
    "tpope/vim-sensible"
  },
  {
    "tpope/vim-repeat"
  },
  {
    "tpope/vim-surround"
  },
  {
    "tpope/vim-unimpaired"
  },
  {
    "tpope/vim-fugitive"
  },
  {
    "tpope/vim-rhubarb"
  },
  {
    "tpope/vim-rails"
  },
  {
    "preservim/nerdcommenter",
    config = function()
      vim.g.NERDSpaceDelims = 1
    end
  },
  {
    "easymotion/vim-easymotion"
  },
  {
    "AndrewRadev/splitjoin.vim"
  },
  {
    "AndrewRadev/switch.vim",
    config = function()
      vim.keymap.set("n", "<leader>S", ":Switch<cr>")
    end
  },
  {
    "mechatroner/rainbow_csv"
  },
}
