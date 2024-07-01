return {
  "nvim-lualine/lualine.nvim",
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  config = function()
    require("lualine").setup({
      options = {
        theme = "solarized_dark",
        component_separators = { left = '', right = '' },
        section_separators = { left = '', right = '' },
      },
      sections = {
        lualine_b = { "diff", "diagnostics" },
        lualine_c = { {"filename", path = 1} }
      },
      tabline = {
        lualine_a = {
          {
            "tabs",
            tab_max_length = 30,
            max_length = function()
              return vim.o.columns * 2 / 3
            end,
            mode = 2,
            path = 0,
            use_mode_colors = false,
            -- tabs_color = {
              -- active = "lualine_a_normal",
              -- inactive = "lualine_b_normal",
            -- },
          },
        },
        lualine_b = {},
        lualine_c = {},
        lualine_x = {},
        lualine_y = {},
        lualine_z = {},
      },
    })
  end
}
