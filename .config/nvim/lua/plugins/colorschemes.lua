return {
  {
    "overcache/NeoSolarized",
    init = function()
      vim.g.neosolarized_italic = 1
    end,
    config = function()
      -- vim.cmd.colorscheme("NeoSolarized")
    end,
  },
  {
    "0xstepit/flow.nvim",
    lazy = false,
    priority = 1000,
    opts = {},
    config = function()
      require("flow").setup{
        transparent = true, -- Set transparent background.
        fluo_color = "orange", --  Fluo color: pink, yellow, orange, or green.
        mode = "normal",
        aggressive_spell = false,
      }
    end
  },
  {
    "AlexvZyl/nordic.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("nordic").load()
    end
  },
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {},
  }
}
