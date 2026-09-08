-- return {}
return {
  {
    "kevinhwang91/nvim-bqf",
    config = function()
      require("bqf").setup({
        auto_enable = false,
        preview = {
          auto_preview = true,
        },
      })
    end,
  },
  {
    "sindrets/diffview.nvim"
  },
  {
    "chrisgrieser/nvim-rip-substitute",
    cmd = "RipSubstitute",
    opts = {},
    keys = {
      {
        "<leader>rs",
        function() require("rip-substitute").sub() end,
        mode = { "n", "x" },
        desc = " rip substitute",
      },
    },
  },
  {
    "Imngzx/jisho.nvim",
    cmd = "Jisho",
    keys = {
      {
        '<leader>tj',
        function() require('jisho').search() end,
        mode = 'n',
        desc = 'Jisho (Word under cursor)',
      },
      {
        '<leader>tj',
        function()
          local start_pos = vim.fn.getpos('v')
          local end_pos = vim.fn.getpos('.')
          local lines = vim.fn.getregion(start_pos, end_pos)
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', true)
          require('jisho').search(table.concat(lines, ' '))
        end,
        mode = 'v',
        desc = 'Jisho (Selection)',
      },
    },
    opts = {},
  },
}
