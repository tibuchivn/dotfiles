return {
  "ibhagwan/fzf-lua",
  -- optional for icon support
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    -- calling `setup` is optional for customization
    require("fzf-lua").setup({
      {"fzf-vim", "telescope"},
      fzf_opts = { ["--layout"] = "reverse", ["--marker"] = "+" },
      -- winopts = { split = "belowright new" },
    })
    -- vim.api.nvim_set_keymap("n", "<C-\\>", [[<Cmd>lua require"fzf-lua".buffers()<CR>]], {})
    -- vim.api.nvim_set_keymap("n", "<C-k>", [[<Cmd>lua require"fzf-lua".builtin()<CR>]], {})
    -- vim.api.nvim_set_keymap("n", "<C-l>", [[<Cmd>lua require"fzf-lua".live_grep_glob()<CR>]], {})
    vim.api.nvim_set_keymap("n", "<C-p>", [[<Cmd>lua require"fzf-lua".files()<CR>]], {})
    vim.api.nvim_set_keymap("n", "<C-g>", [[<Cmd>lua require"fzf-lua".grep_project()<CR>]], {})
    vim.keymap.set("n", "<leader>H", ":FzfLua oldfiles<cr>")
    vim.keymap.set("n", "<leader>B", ":FzfLua buffers<cr>")
    vim.keymap.set("n", "<leader>T", ":FzfLua btags<cr>")
    vim.keymap.set("n", "<leader>?", ":FzfLua git_status<cr>")
    vim.keymap.set("n", "<leader>F", ":FzfLua<cr>")
  end
}
