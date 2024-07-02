vim.cmd([[map <leader>y "+y]])
-- vim.keymap.set("n", "<leader>y", [["+y]], {noremap=false})
vim.keymap.set("n", "<leader>P", [["+p]])
vim.keymap.set("n", "<leader>p", [["0p]])
vim.keymap.set("n", "<leader>=", "<esc>gg=G<C-o><C-o>zz")
vim.keymap.set("n", "<leader>wb", [[:%bd|e#|bd#<cr>]])

vim.keymap.set("n", "<leader>\\", "<C-w>v<C-w>l")
vim.keymap.set("n", "<leader>-", "<C-w>s<C-w>j")

vim.keymap.set("n", "<leader>ps", ':let @*=expand("%")<CR>')
vim.keymap.set("n", "<leader>pl", ':let @*=expand("%:p")<CR>')

vim.keymap.set("n", "<leader>o", "ddO")
vim.keymap.set("n", "<leader>et", ":tabnew ~/code_temp.rb<CR>")
vim.keymap.set("n", "<leader>ek", ":tabnew ~/.config/kitty/kitty.conf<CR>")
vim.keymap.set("n", "<leader>ea", ":tabnew ~/.config/alacritty/alacritty.toml<CR>")
vim.keymap.set("n", "<leader>ez", ":tabnew ~/.zshrc<CR>")
vim.keymap.set("n", "<leader>sv", ":so ~/.config/nvim/init.lua<CR>")
vim.keymap.set("n", "<leader>ev", [[:lua require'fzf-lua'.files({ cwd="~/.config/nvim" })<cr>]])

vim.keymap.set("i", "jj", "<esc>")

vim.keymap.set("n", "p", "p=`]")
vim.keymap.set("n", "j", "gj")
vim.keymap.set("n", "k", "gk")
vim.keymap.set("n", "=j", ":%!jq<CR>")
vim.keymap.set("n", "H", "gT")
vim.keymap.set("n", "L", "gt")

vim.keymap.set("n", "<esc><esc>", ":nohlsearch<Bar>:echo<CR>")
