vim.o.foldlevel = 99
vim.o.foldlevelstart = 99
vim.o.foldcolumn = "0"
vim.o.foldtext = ""
vim.opt.fillchars:append({ fold = " " })

function _G.indent_fold_expr()
  local lnum = vim.v.lnum
  if vim.fn.getline(lnum):match("^%s*$") then
    return "="
  end

  local sw = vim.bo.shiftwidth
  if sw == 0 then sw = vim.bo.tabstop end

  local level = math.floor(vim.fn.indent(lnum) / sw)

  local next = lnum + 1
  local last = vim.fn.line("$")
  while next <= last and vim.fn.getline(next):match("^%s*$") do
    next = next + 1
  end

  if next <= last and math.floor(vim.fn.indent(next) / sw) > level then
    return ">" .. (level + 1)
  end

  return tostring(level)
end

local function apply_fold(args)
  if vim.bo[args.buf].buftype == "" then
    vim.wo.foldenable = true
    vim.wo.foldmethod = "expr"
    vim.wo.foldexpr = "v:lua.indent_fold_expr()"
  end
end

vim.api.nvim_create_autocmd("BufWinEnter", { callback = apply_fold })

vim.api.nvim_create_autocmd("SessionLoadPost", {
  callback = function()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.bo[buf].buftype == "" then
        vim.wo[win].foldenable = true
        vim.wo[win].foldmethod = "expr"
        vim.wo[win].foldexpr = "v:lua.indent_fold_expr()"
      end
    end
  end,
})
