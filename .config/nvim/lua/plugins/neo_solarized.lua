return {
  {
    "overcache/NeoSolarized",
    init = function()
      vim.g.neosolarized_italic = 1
    end,
    config = function()
      vim.cmd.colorscheme("NeoSolarized")
    end,
  }
}
