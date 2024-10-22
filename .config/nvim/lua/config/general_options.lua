-- set vim options
vim.opt.tabstop        = 2
vim.opt.softtabstop    = 2
vim.opt.shiftwidth     = 2
vim.opt.expandtab      = true
vim.opt.autoindent     = true
vim.opt.smartindent    = true
vim.opt.foldmethod     = "indent"
vim.opt.foldnestmax    = 10
vim.opt.foldlevelstart = 30
vim.opt.scrolloff      = 50
vim.opt.number         = true
vim.opt.relativenumber = true
vim.opt.fillchars      = "diff:⣿,vert:│"
vim.opt.ignorecase     = true
vim.opt.smartcase      = true
vim.opt.hlsearch       = true
vim.opt.swapfile       = false
vim.opt.hidden         = true
vim.opt.cursorline     = true
vim.opt.inccommand     = "split"
vim.opt.mouse          = ""
vim.opt.completefunc   = "syntaxcomplete#Complete"
vim.opt.background     = "dark"
vim.opt.termguicolors  = true
vim.opt.completeopt    = "menuone,noselect"
vim.opt.hidden         = true
vim.opt.backup         = false
vim.opt.writebackup    = false
vim.opt.updatetime     = 300
vim.opt.signcolumn     = "yes"
vim.opt.cmdheight      = 1
vim.opt.showmode       = false
vim.opt.laststatus     = 3

-- set leader key
vim.g.mapleader = " "

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})
-- autocmd from vimrc
vim.cmd([==[
" Triger `autoread` when files changes on disk
" https://unix.stackexchange.com/questions/149209/refresh-changed-content-of-file-opened-in-vim/383044#383044
" https://vi.stackexchange.com/questions/13692/prevent-focusgained-autocmd-running-in-command-line-editing-mode
autocmd FocusGained,BufEnter,CursorHold,CursorHoldI * if mode() != 'c' | checktime | endif
" Notification after file change
" https://vi.stackexchange.com/questions/13091/autocmd-event-for-autoread
autocmd FileChangedShellPost *
\ echohl WarningMsg | echo "File changed on disk. Buffer reloaded." | echohl None

autocmd BufNewFile,BufRead *_spec.rb set filetype=ruby
" support css word with -
autocmd FileType css,scss,slim,html,eruby,coffee,javascript setlocal iskeyword+=-
" autocmd FileType python set shiftwidth=2 tabstop=2 expandtab

autocmd BufWritePre * :%s/\s\+$//e
]==])

-- custom commands from vimrc
vim.cmd([==[

function! DeleteFile(...)
  if(exists('a:1'))
    let theFile=a:1
  elseif ( &ft == 'help' )
    echohl Error
    echo "Cannot delete a help buffer!"
    echohl None
    return -1
  else
    let theFile=expand('%:p')
  endif
  let delStatus=delete(theFile)
  if(delStatus == 0)
    echo "Deleted " . theFile
  else
    echohl WarningMsg
    echo "Failed to delete " . theFile
    echohl None
  endif
  return delStatus
endfunction

"delete the current file
com! Rm call DeleteFile()
"delete the file and quit the buffer (quits vim if this was the last file)
com! RM call DeleteFile() <Bar> q!
]==])
