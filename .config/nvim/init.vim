set nocompatible               " be iMproved
set fillchars=diff:⣿,vert:│

nnoremap <silent> <ESC><ESC> :nohlsearch<Bar>:echo<CR>

set tabstop=2
set softtabstop=2
set shiftwidth=2
set expandtab
set autoindent
set foldmethod=indent
set foldnestmax=10
set foldlevelstart=30
set scrolloff=50
" number line show
set nu
" Triger `autoread` when files changes on disk
" https://unix.stackexchange.com/questions/149209/refresh-changed-content-of-file-opened-in-vim/383044#383044
" https://vi.stackexchange.com/questions/13692/prevent-focusgained-autocmd-running-in-command-line-editing-mode
autocmd FocusGained,BufEnter,CursorHold,CursorHoldI * if mode() != 'c' | checktime | endif
" Notification after file change
" https://vi.stackexchange.com/questions/13091/autocmd-event-for-autoread
autocmd FileChangedShellPost *
      \ echohl WarningMsg | echo "File changed on disk. Buffer reloaded." | echohl None

" highlight yanked text
augroup LuaHighlight
  autocmd!
  autocmd TextYankPost * silent! lua require'vim.highlight'.on_yank()
augroup END

set ignorecase
set smartcase
set hlsearch

set noswapfile
"in order to switch between buffers with unsaved change
set hidden

" hightlight column and line
set cursorline
" set cursorcolumn
filetype plugin indent on
syntax on

" live substitution
set inccommand=split

set mouse=

autocmd BufNewFile,BufRead *_spec.rb set filetype=ruby
" support css word with -
autocmd FileType css,scss,slim,html,eruby,coffee,javascript setlocal iskeyword+=-
" autocmd FileType python set shiftwidth=2 tabstop=2 expandtab

" set t_Co=256
autocmd BufWritePre * :%s/\s\+$//e

let mapleader= " "
set completefunc=syntaxcomplete#Complete

call plug#begin('~/.vim/nvim_bundle')

Plug 'ludovicchabant/vim-gutentags'
Plug 'neovim/nvim-lspconfig'
Plug 'WhoIsSethDaniel/toggle-lsp-diagnostics.nvim'
Plug 'vim-ruby/vim-ruby'
" Plug 'nvim-treesitter/nvim-treesitter'
Plug 'easymotion/vim-easymotion'
Plug 'tpope/vim-sensible'
Plug 'tpope/vim-haml'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-unimpaired'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-rhubarb'
Plug 'tpope/vim-rails'
Plug 'tpope/vim-cucumber'
Plug 'preservim/nerdcommenter'
Plug 'itchyny/lightline.vim'
Plug 'spywhere/lightline-lsp'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
Plug 'junegunn/goyo.vim'
Plug 'junegunn/vim-easy-align'
Plug 'junegunn/limelight.vim'
Plug 'christoomey/vim-tmux-navigator'
Plug '907th/vim-auto-save'
Plug 'lifepillar/vim-solarized8'
Plug 'overcache/NeoSolarized'
Plug 'mhinz/vim-grepper'
Plug 'janko/vim-test'
Plug 'jiangmiao/auto-pairs'
Plug 'AndrewRadev/splitjoin.vim'
Plug 'kana/vim-textobj-user'
Plug 'michaeljsmith/vim-indent-object'
Plug 'ryanoasis/vim-devicons'
Plug 'francoiscabrol/ranger.vim'
Plug 'rbgrouleff/bclose.vim'
Plug 'rhysd/git-messenger.vim'
Plug 'ms-jpq/coq_nvim', {'branch': 'coq'}
Plug 'ms-jpq/coq.artifacts', {'branch': 'artifacts'}
" Plug 'ojroques/vim-scrollstatus'
Plug 'AndrewRadev/switch.vim'
Plug 'preservim/vimux'
Plug 'nvim-lua/plenary.nvim'
Plug 'lewis6991/gitsigns.nvim'
Plug 'hashivim/vim-terraform'
Plug 'mechatroner/rainbow_csv'

call plug#end()

" set notgc

set background=dark
" set background=light
let g:solarized_use16=1
" colorscheme solarized8
colorscheme NeoSolarized

" configuration for coq completion
let g:coq_settings = {
      \ 'auto_start': v:true,
      \ 'clients.tmux.enabled': v:false,
      \ 'keymap.jump_to_mark': '<c-j>'
      \ }

" configuration for gitsigns
lua << END
require('gitsigns').setup{
  -- on_attach = function(bufnr)
  --   -- Navigation
  --   map('n', ']c', "&diff ? ']c' : '<cmd>Gitsigns next_hunk<CR>'", {expr=true})
  --   map('n', '[c', "&diff ? '[c' : '<cmd>Gitsigns prev_hunk<CR>'", {expr=true})
  -- end
}
END

" configuration for nvim lsp
lua << END
local nvim_lsp = require('lspconfig')

local on_attach = function(client, bufnr)
  local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
  local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

  -- Mappings.
  local opts = { noremap=true, silent=true }
  buf_set_keymap('n', 'gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
  buf_set_keymap('n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<CR>', opts)
  buf_set_keymap('n', ']d', '<cmd>lua vim.diagnostic.goto_next()<CR>', opts)
  buf_set_keymap('n', '<leader>q', '<cmd>lua vim.diagnostic.setloclist()<CR>', opts)

  vim.diagnostic.config({
    virtual_text = false,
    underline = true,
    signs = true
  })

  -- vim.cmd [[autocmd! CursorHold,CursorHoldI * lua vim.diagnostic.open_float(nil, {focus=false})]]
  vim.cmd [[autocmd! CursorHold,CursorHoldI * lua vim.diagnostic.open_float(nil, {focus=false, scope="cursor"})]]

  vim.cmd [[
    highlight! DiagnosticLineNrError guibg=#51202A guifg=#FF0000 gui=bold
    highlight! DiagnosticLineNrWarn guibg=#51412A guifg=#FFA500 gui=bold
    highlight! DiagnosticLineNrInfo guibg=#1E535D guifg=#00FFFF gui=bold
    highlight! DiagnosticLineNrHint guibg=#1E205D guifg=#0000FF gui=bold

    sign define DiagnosticSignError text= texthl=DiagnosticSignError linehl= numhl=DiagnosticLineNrError
    sign define DiagnosticSignWarn text= texthl=DiagnosticSignWarn linehl= numhl=DiagnosticLineNrWarn
    sign define DiagnosticSignInfo text= texthl=DiagnosticSignInfo linehl= numhl=DiagnosticLineNrInfo
    sign define DiagnosticSignHint text= texthl=DiagnosticSignHint linehl= numhl=DiagnosticLineNrHint
  ]]
end

-- require('rust-tools').setup({})

local servers = {'solargraph', 'tsserver', 'rust_analyzer'}
local coq = require 'coq'
for _, lsp in ipairs(servers) do
  -- nvim_lsp[lsp].setup { on_attach = on_attach, autostart = false}
  nvim_lsp[lsp].setup(coq.lsp_ensure_capabilities({ on_attach = on_attach, autostart = false }))
end

require'toggle_lsp_diagnostics'.init()
END

nmap <leader>tu <Plug>(toggle-lsp-diag-vtext)

let g:limelight_conceal_ctermfg = 245  " Solarized Base1
let g:limelight_conceal_guifg = '#8a8a8a'  " Solarized Base1

" nerdcommenter to give extra space after #
let NERDSpaceDelims=1

" ranger integration
let g:ranger_map_keys = 0

if &diff
  let g:gutentags_enabled = 0
endif

let g:lightline = {
      \ 'colorscheme': 'solarized',
      \ 'active': {
      \   'left': [['mode', 'paste'], ['readonly', 'filename', 'modified']],
      \   'right': [[ 'linter_errors', 'linter_warnings', 'linter_infos', 'linter_hints', 'linter_ok' ], ['lineinfo'], ['percent'], ['filetype']]
      \ },
      \ 'tabline': {
      \   'left': [['tabs']],
      \   'right': [[]]
      \ },
      \ 'tab': {
      \   'active': ['tabnum', 'filename'],
      \   'inactive': ['tabnum', 'filename']
      \ },
      \ 'component_function': {
      \   'filetype': 'MyFiletype',
      \   'fileformat': 'MyFileformat',
      \   'gitbranch': 'FugitiveHead',
      \   'filename': 'LightlineFilename',
      \   'percent': 'ScrollStatus',
      \ },
      \ 'component_expand': {
      \   'linter_hints': 'lightline#lsp#hints',
      \   'linter_infos': 'lightline#lsp#infos',
      \   'linter_warnings': 'lightline#lsp#warnings',
      \   'linter_errors': 'lightline#lsp#errors',
      \   'linter_ok': 'lightline#lsp#ok',
      \ },
      \ 'component_type': {
      \   'linter_hints': 'right',
      \   'linter_infos': 'right',
      \   'linter_warnings': 'warning',
      \   'linter_errors': 'error',
      \   'linter_ok': 'right',
      \ }
      \ }
function! MyFiletype()
  return winwidth(0) > 70 ? (strlen(&filetype) ? &filetype . ' ' . WebDevIconsGetFileTypeSymbol() : 'no ft') : ''
endfunction

function! MyFileformat()
  " return winwidth(0) > 70 ? (&fileformat . ' ' . WebDevIconsGetFileFormatSymbol()) : ''
  return (&fileformat . ' ' . WebDevIconsGetFileFormatSymbol())
endfunction


function! LightlineFilename()
  return expand('%')
endfunction

autocmd OptionSet background call lightline#colorscheme() | call lightline#update()

let g:auto_save = 1
let g:auto_save_events = ["InsertLeave", "TextChanged"]

map <leader>E :Ranger<CR>
" map <leader>E :CHADopen<CR>
map <leader>y "+y
map <leader>P "+p
map <leader>p "0p
map <leader>H :History<cr>
map <leader>B :Buffers<cr>
map <leader>W :Windows<cr>
map <leader>T :BTags<cr>
map <leader>ft :Filetypes<cr>
map <leader>? :GFiles?<cr>
map <Leader>= <esc>gg=G<C-o><C-o>zz
map <leader>wb :%bd\|e#\|bd#<cr>

nnoremap <leader>\ <C-w>v<C-w>l
nnoremap <leader>- <C-w>s<C-w>j
nnoremap <leader>G :Grepper<cr>
nnoremap <leader>gg :Grepper -quickfix -open<cr>
nnoremap <leader>gq :Grepper -quickfix -open<cr>
nnoremap <leader>gl :Grepper -noquickfix -open<cr>

let g:grepper           = {}
let g:grepper.tools     = ['rg', 'ag', 'git']
let g:grepper.jump      = 0
let g:grepper.quickfix  = 1
let g:grepper.next_tool = '<leader>g'
let g:grepper.open      = 1

nnoremap <Leader>et :tabnew ~/code_temp.rb<CR>
nnoremap <Leader>ev :tabnew ~/.config/nvim/init.vim<CR>
nnoremap <Leader>sv :so ~/.config/nvim/init.vim<CR>
nnoremap <Leader>ek :tabnew ~/.config/kitty/kitty.conf<CR>
nnoremap <Leader>ea :tabnew ~/.config/alacritty/alacritty.toml<CR>
nnoremap <Leader>ez :tabnew ~/.zshrc<CR>
nnoremap <leader>o ddO

nmap <leader>ps :let @*=expand("%")<CR>
nmap <leader>pl :let @*=expand("%:p")<CR>
nmap <Leader>f :TestFile<CR>
nmap <Leader>s :TestNearest<CR>
nmap <Leader>l :TestLast<CR>

map <leader>S :Switch<cr>

" quocle map cfdo
" vnoremap <leader>h y:%s/<C-R>"/<C-R>"/g<left><left>
" xmap <leader>ah y:Grepper -noprompt -quickfix -query <C-R>"<CR>:cfdo %s/<C-R>"/<C-R>"/g<left><left>

nnoremap <silent> <C-p> :FZF<CR>

" let g:fzf_layout = { 'window': { 'width': 0.9, 'height': 0.6, 'rounded': v:true } }
" - down / up / left / right
let g:fzf_layout = { 'down': '30%' }
" [Buffers] Jump to the existing window if possible
let g:fzf_buffers_jump = 1

inoremap jj <ESC>

set completeopt=menuone,noselect

let test#vim#term_position = "belowright"
let test#strategy = "vimux"
let test#ruby#use_binstubs = 1

let g:python_highlight_all = 1

let g:indentLine_leadingSpaceEnabled = 0
let g:indentLine_leadingSpaceChar = '·'

let g:tmux_navigator_disable_when_zoomed = 1

let g:loaded_ruby_provider = 0
let g:ruby_indent_block_style = 'do'
let g:ruby_indent_assignment_style = 'variable'
" let g:ruby_indent_assignment_style = 'hanging'

tnoremap <Esc> <C-\><C-n>
tnoremap <A-h> <C-\><C-N><C-w>h
tnoremap <A-j> <C-\><C-N><C-w>j
tnoremap <A-k> <C-\><C-N><C-w>k
tnoremap <A-l> <C-\><C-N><C-w>l
inoremap <A-h> <C-\><C-N><C-w>h
inoremap <A-j> <C-\><C-N><C-w>j
inoremap <A-k> <C-\><C-N><C-w>k
inoremap <A-l> <C-\><C-N><C-w>l
nnoremap <A-h> <C-w>h
nnoremap <A-j> <C-w>j
nnoremap <A-k> <C-w>k
nnoremap <A-l> <C-w>l

vnoremap // y/<C-R>"<CR>

set hidden
set nobackup
set nowritebackup
set updatetime=300
set signcolumn=yes
set cmdheight=2

let g:goyo_linenr=1
let g:goyo_width=120
let g:goyo_height='100%'
noremap <Leader>z :Goyo<CR>

nnoremap p p=`]
nnoremap j gj
nnoremap k gk
nmap =j :%!jq<CR>
nnoremap H gT
nnoremap L gt

onoremap q i'
onoremap Q i"

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

" junegunn/vim-easy-align
" Start interactive EasyAlign in visual mode (e.g. vipga)
xmap ga <Plug>(EasyAlign)

" Start interactive EasyAlign for a motion/text object (e.g. gaip)
nmap ga <Plug>(EasyAlign)
