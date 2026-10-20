return {
  "hrsh7th/nvim-cmp",
  lazy = false, -- capabilities must be registered before any LSP client starts
  dependencies = {
    "hrsh7th/cmp-nvim-lsp", -- LSP completions
    "hrsh7th/cmp-buffer", -- words from the current buffer
    "hrsh7th/cmp-path", -- filesystem paths
  },
  config = function()
    local cmp = require("cmp")

    -- ctags entries from the project's tags file (see lua/cmp_tags/source.lua)
    cmp.register_source("tags", require("cmp_tags.source").new())

    -- Give every language server the completion capabilities cmp advertises.
    vim.lsp.config("*", {
      capabilities = require("cmp_nvim_lsp").default_capabilities(),
    })

    cmp.setup({
      -- Expand snippets (including LSP snippet completions) with the built-in
      -- vim.snippet API; no snippet engine required.
      snippet = {
        expand = function(args)
          vim.snippet.expand(args.body)
        end,
      },
      window = {
        completion = cmp.config.window.bordered(),
        documentation = cmp.config.window.bordered(),
      },
      mapping = cmp.mapping.preset.insert({
        ["<C-b>"] = cmp.mapping.scroll_docs(-4),
        ["<C-f>"] = cmp.mapping.scroll_docs(4),
        ["<C-Space>"] = cmp.mapping.complete(),
        ["<C-e>"] = cmp.mapping.abort(),
        ["<CR>"] = cmp.mapping.confirm({ select = false }), -- only accepts a selected entry
        -- Manual Minuet request (only the AI source, on demand).
        -- ["<A-y>"] = require("minuet").make_cmp_map(),
        ["<Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_next_item()
          else
            fallback()
          end
        end, { "i", "s" }),
        ["<S-Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item()
          else
            fallback()
          end
        end, { "i", "s" }),
      }),
      sources = cmp.config.sources({
        { name = "nvim_lsp" },
        -- { name = "minuet" }, -- AI completion (deepseek FIM); see lua/plugins/minuet.lua
        { name = "tags", keyword_length = 2 }, -- ctags; see lua/cmp_tags/source.lua
        { name = "path" },
        { name = "buffer", keyword_length = 3 },
      }
    ),
      experimental = {
        ghost_text = true,
      },
      performance = {
        -- LLM sources answer slower than LSP/buffer: give Minuet room to reply
        -- instead of dropping the request (cmp default is 500ms).
        fetching_timeout = 2000,
      },
    })
  end,
}
