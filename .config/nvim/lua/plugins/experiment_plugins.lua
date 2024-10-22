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
  }
}
