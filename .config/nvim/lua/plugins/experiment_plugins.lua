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
    "kevinhwang91/nvim-ufo",
    dependencies = {
      "kevinhwang91/promise-async",
    },
    init = function()
      vim.o.foldcolumn = "0"
      vim.o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
      vim.o.foldlevelstart = 99
      vim.o.foldenable = true
    end,
    config = function()
      vim.keymap.set('n', 'zR', require('ufo').openAllFolds)
      vim.keymap.set('n', 'zM', require('ufo').closeAllFolds)

      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities.textDocument.foldingRange = {
        dynamicRegistration = false,
        lineFoldingOnly = true
      }
      local language_servers = vim.lsp.get_clients() -- or list servers manually like {'gopls', 'clangd'}
      for _, ls in ipairs(language_servers) do
        vim.lsp.enable(ls, {
          capabilities = capabilities
          -- you can add other fields for setting up lsp server in this table
        })
        -- require('lspconfig')[ls].setup({
        --   capabilities = capabilities
        --   -- you can add other fields for setting up lsp server in this table
        -- })
      end
      require('ufo').setup()
    end
  },
}
