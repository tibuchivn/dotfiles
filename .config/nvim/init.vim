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

set ignorecase
set smartcase
set hlsearch

set noswapfile
"in order to switch between buffers with unsaved change
set hidden

" hightlight column and line
set cursorline
"set cursorcolumn
filetype plugin indent on
syntax on

autocmd BufNewFile,BufRead *_spec.rb set filetype=ruby
" support css word with -
autocmd FileType css,scss,slim,html,eruby,coffee,javascript setlocal iskeyword+=-
autocmd FileType python set shiftwidth=2 tabstop=2 expandtab

" set t_Co=256
autocmd BufWritePre * :%s/\s\+$//e

let mapleader= " "
set completefunc=syntaxcomplete#Complete

call plug#begin('/Users/tungtram/.vim/nvim_bundle')

if !&diff
  Plug 'ludovicchabant/vim-gutentags'
  Plug 'SirVer/ultisnips'
  Plug 'honza/vim-snippets'
endif

Plug 'nvim-treesitter/nvim-treesitter'
Plug 'neovim/nvim-lspconfig'
Plug 'hrsh7th/nvim-compe'
" Plug 'norcalli/snippets.nvim'

Plug 'vim-ruby/vim-ruby'
Plug 'Lokaltog/vim-easymotion'
Plug 'tpope/vim-sensible'
Plug 'tpope/vim-haml'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-unimpaired'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-rails'
Plug 'preservim/nerdcommenter'
Plug 'itchyny/lightline.vim'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
Plug 'junegunn/goyo.vim'
Plug 'junegunn/vim-easy-align'
Plug 'christoomey/vim-tmux-navigator'
Plug '907th/vim-auto-save'
Plug 'lifepillar/vim-solarized8'
Plug 'mhinz/vim-grepper'
Plug 'janko/vim-test'
Plug 'jiangmiao/auto-pairs'
Plug 'AndrewRadev/splitjoin.vim'
Plug 'zivyangll/git-blame.vim'
Plug 'vimlab/split-term.vim'
Plug 'kana/vim-textobj-user'
Plug 'michaeljsmith/vim-indent-object'
Plug 'ryanoasis/vim-devicons'
Plug 'francoiscabrol/ranger.vim'
Plug 'rbgrouleff/bclose.vim'
Plug 'mhinz/vim-signify'

call plug#end()

" configuration for nvim lsp
lua << END
local nvim_lsp = require('lspconfig')

local on_attach = function(client, bufnr)
  local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
  local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

  --Enable completion triggered by <c-x><c-o>
  --buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Mappings.
  local opts = { noremap=true, silent=true }
  buf_set_keymap('n', 'gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
  buf_set_keymap('n', '[d', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>', opts)
  buf_set_keymap('n', ']d', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>', opts)
  buf_set_keymap('n', '<leader>q', '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts)

  vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
    vim.lsp.diagnostic.on_publish_diagnostics, {
      virtual_text = false,
      underline = true,
      signs = true,
    }
  )
  vim.cmd [[autocmd CursorHold <buffer> lua vim.lsp.diagnostic.show_line_diagnostics({show_header = false})]]
  -- vim.cmd [[autocmd CursorHoldI * silent! lua vim.lsp.buf.signature_help()]]
end

local servers = {'solargraph'}
for _, lsp in ipairs(servers) do
  nvim_lsp[lsp].setup {
    on_attach = on_attach,
  }
end

require'nvim-treesitter.configs'.setup {
  highlight = {
      enable = true
  },
}


END


" configuration for autocomplete compe
let g:compe = {}
let g:compe.enabled = v:true
let g:compe.autocomplete = v:true
let g:compe.debug = v:false
let g:compe.min_length = 1
let g:compe.preselect = 'enable'
let g:compe.throttle_time = 80
let g:compe.source_timeout = 200
let g:compe.resolve_timeout = 800
let g:compe.incomplete_delay = 400
let g:compe.max_abbr_width = 100
let g:compe.max_kind_width = 100
let g:compe.max_menu_width = 100
let g:compe.documentation = v:true

let g:compe.source = {}
let g:compe.source.path = v:true
let g:compe.source.buffer = v:true
let g:compe.source.calc = v:true
let g:compe.source.nvim_lsp = v:true
let g:compe.source.nvim_lua = v:true
let g:compe.source.vsnip = v:true
let g:compe.source.ultisnips = v:true
let g:compe.source.luasnip = v:true
let g:compe.source.emoji = v:true

inoremap <silent><expr> <C-Space> compe#complete()
inoremap <silent><expr> <CR>      compe#confirm('<CR>')
inoremap <silent><expr> <C-e>     compe#close('<C-e>')
inoremap <silent><expr> <C-f>     compe#scroll({ 'delta': +4 })
inoremap <silent><expr> <C-d>     compe#scroll({ 'delta': -4 })

" <Tab>: completion
inoremap <silent><expr> <TAB> pumvisible() ? "\<C-n>" : "\<TAB>"
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

" configuration for autocomplete compe END

set background=dark
" set background=light

let g:solarized_use16=1

colorscheme solarized8
" colorscheme PaperColor

" nerdcommenter to give extra space after #
let NERDSpaceDelims=1

" ranger integration
let g:ranger_map_keys = 0


" let g:lightline = { 'colorscheme': 'paperColor' }
let g:lightline = {
      \ 'colorscheme': 'solarized',
      \ 'active': {
      \   'left': [['mode', 'paste'], ['readonly', 'filename', 'modified']],
      \   'right': [['lineinfo'], ['filetype']]
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
map <leader>y "+y
map <leader>p "+p
map <leader>P "0p
map <leader>H :History<cr>
map <leader>B :Buffers<cr>
map <leader>W :Windows<cr>
map <leader>T :BTags<cr>
map <leader>ft :Filetypes<cr>
map <leader>? :GFiles?<cr>
map <Leader>= gg=G<C-o>
map <leader>wb :%bd\|e#\|bd#<cr>
map <leader>cc vipyPgvO<Esc>O<Esc>gv:!curl --config -<CR>

nnoremap <leader>\ <C-w>v<C-w>l
nnoremap <leader>- <C-w>s<C-w>j
nnoremap <leader>G :Grepper<cr>
nnoremap <leader>g :Grepper -quickfix -open<cr>

nnoremap <Leader>ev :tabnew ~/.config/nvim/init.vim<CR>
nnoremap <Leader>sv :so ~/.config/nvim/init.vim<CR>
nnoremap <Leader>ek :tabnew ~/.config/kitty/kitty.conf<CR>
nnoremap <Leader>ea :tabnew ~/.config/alacritty/alacritty.yml<CR>
nnoremap <Leader>ez :tabnew ~/.zshrc<CR>
nnoremap <leader>o ddO

nmap <leader>ps :let @*=expand("%")<CR>
nmap <leader>pl :let @*=expand("%:p")<CR>
nmap <Leader>f :TestFile<CR>
nmap <Leader>s :TestNearest<CR>
nmap <Leader>l :TestLast<CR>

" quocle map cfdo
" vnoremap <leader>h y:%s/<C-R>"/<C-R>"/g<left><left>
" xmap <leader>ah y:Grepper -noprompt -quickfix -query <C-R>"<CR>:cfdo %s/<C-R>"/<C-R>"/g<left><left>

nnoremap <silent> <C-p> :FZF<CR>

let g:fzf_layout = { 'window': { 'width': 0.9, 'height': 0.6, 'rounded': v:true } }
" [Buffers] Jump to the existing window if possible
let g:fzf_buffers_jump = 1

inoremap jj <ESC>

let g:grepper           = {}
let g:grepper.tools     = ['git', 'rg']
let g:grepper.jump      = 0
let g:grepper.quickfix  = 1
let g:grepper.next_tool = '<leader>g'
let g:grepper.open      = 1

" COMPLETER
"set completeopt=longest,menuone,noinsert
"inoremap <expr> <CR> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"

set completeopt=menuone,noselect

let test#vim#term_position = "belowright"
let test#strategy = "neovim"
let test#ruby#use_binstubs = 0

let g:python_highlight_all = 1

let g:indentLine_leadingSpaceEnabled = 0
let g:indentLine_leadingSpaceChar = '·'

let g:tmux_navigator_disable_when_zoomed = 1

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

" junegunn/vim-easy-align
" Start interactive EasyAlign in visual mode (e.g. vipga)
xmap ga <Plug>(EasyAlign)

" Start interactive EasyAlign for a motion/text object (e.g. gaip)
nmap ga <Plug>(EasyAlign)

