return {
  { "tpope/vim-sensible" },
  { "tpope/vim-repeat" },
  { "tpope/vim-surround" },
  { "tpope/vim-unimpaired" },
  { "tpope/vim-fugitive" },
  { "tpope/vim-rhubarb" },
  { "mechatroner/rainbow_csv" },
  { "easymotion/vim-easymotion" },
  { "AndrewRadev/splitjoin.vim" },
  {
    "preservim/nerdcommenter",
    config = function()
      vim.g.NERDSpaceDelims = 1
    end
  },
  {
    "AndrewRadev/switch.vim",
    config = function()
      vim.keymap.set("n", "<leader>S", ":Switch<cr>")
    end
  },
  {
    "christoomey/vim-tmux-navigator",
    config = function()
      vim.g.tmux_navigator_disable_when_zoomed = 1
    end
  },
}
