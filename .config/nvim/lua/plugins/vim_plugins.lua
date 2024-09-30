return {
  { "tpope/vim-sensible" },
  { "tpope/vim-repeat" },
  {
    "tpope/vim-surround",
    init = function()
      vim.g.surround_no_insert_mappings = 1
    end
  },
  { "tpope/vim-unimpaired" },
  { "tpope/vim-fugitive" },
  { "tpope/vim-rhubarb" },
  { "mechatroner/rainbow_csv" },
  { "easymotion/vim-easymotion" },
  { "AndrewRadev/splitjoin.vim" },
  {
    "preservim/nerdcommenter",
    init = function()
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
    init = function()
      vim.g.tmux_navigator_disable_when_zoomed = 1
    end
  },
}
