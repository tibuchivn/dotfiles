set nocompatible               " be iMproved
set fillchars=diff:⣿,vert:│

" Press F4 to toggle highlighting on/off, and show current value.
:noremap <F4> :set hlsearch! hlsearch?<CR>

" Press Space to turn off highlighting and clear any message already displayed
:nnoremap <silent> <ESC><ESC> :nohlsearch<Bar>:echo<CR>
" 1 tab to 2 space for ruby
set tabstop=2
set softtabstop=2
set shiftwidth=2
set expandtab
set autoindent
set foldmethod=indent
set foldnestmax=10
set foldlevelstart=30

set scrolloff=50

set updatetime=1000
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

call plug#begin('~/.vim/plugged')

if !&diff
  Plug 'neoclide/coc.nvim', {'do': 'yarn install --frozen-lockfile'}
  Plug 'ludovicchabant/vim-gutentags'
  Plug 'SirVer/ultisnips'
  Plug 'honza/vim-snippets'
endif

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
Plug 'godlygeek/tabular'
Plug 'itchyny/lightline.vim'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
Plug 'junegunn/goyo.vim'
Plug 'christoomey/vim-tmux-navigator'
Plug '907th/vim-auto-save'
Plug 'lifepillar/vim-solarized8'
Plug 'mhinz/vim-grepper'
Plug 'janko/vim-test'
Plug 'sheerun/vim-polyglot'
Plug 'jiangmiao/auto-pairs'
Plug 'AndrewRadev/splitjoin.vim'
Plug 'zivyangll/git-blame.vim'
Plug 'vimlab/split-term.vim'
Plug 'kana/vim-textobj-user'
Plug 'michaeljsmith/vim-indent-object'
Plug 'ryanoasis/vim-devicons'
Plug 'francoiscabrol/ranger.vim'
Plug 'rbgrouleff/bclose.vim'

call plug#end()

set background=dark
" set background=light

let g:solarized_use16=1

colorscheme solarized8

" nerdcommenter to give extra space after #
let NERDSpaceDelims=1

" ranger integration
let g:ranger_map_keys = 0

" let g:airline#extensions#coc#enabled = 1
" let g:airline#extensions#tabline#enabled = 0
" let g:airline#extensions#tabline#formatter = 'unique_tail_improved'
" let g:airline_powerline_fonts = 1
" let g:airline#parts#ffenc#skip_expected_string='utf-8[unix]'
" let g:airline_skip_empty_sections = 1
" let g:airline_section_z = ''
" let g:airline_solarized_bg='dark'
" let g:airline#extensions#tabline#left_sep = ' '
" let g:airline#extensions#tabline#left_alt_sep = '|'
" let g:airline#extensions#tabline#right_sep = ' '
" let g:airline#extensions#tabline#right_alt_sep = '|'

let g:lightline = {
      \ 'colorscheme': 'solarized',
      \ 'active': {
      \   'left': [['mode', 'paste'], ['gitbranch', 'readonly', 'filename', 'modified']],
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

let g:auto_save = 1
let g:auto_save_events = ["InsertLeave", "TextChanged"]

let g:coc_node_path = '/Users/tungtram/.asdf/installs/nodejs/12.13.0/bin/node'

" coc-explorer
let g:coc_explorer_global_presets = {
\   '.vim': {
\     'root-uri': '~/.vim',
\   },
\   'tab': {
\     'position': 'tab',
\     'quit-on-open': v:true,
\   },
\   'floating': {
\     'position': 'floating',
\     'open-action-strategy': 'sourceWindow',
\     'floating-width': '120',
\   },
\   'floatingTop': {
\     'position': 'floating',
\     'floating-position': 'center-top',
\     'open-action-strategy': 'sourceWindow',
\   },
\   'floatingLeftside': {
\     'position': 'floating',
\     'floating-position': 'left-center',
\     'floating-width': 50,
\     'open-action-strategy': 'sourceWindow',
\   },
\   'floatingRightside': {
\     'position': 'floating',
\     'floating-position': 'right-center',
\     'floating-width': 50,
\     'open-action-strategy': 'sourceWindow',
\   },
\   'simplify': {
\     'file-child-template': '[selection | clip | 1] [indent][icon | 1] [filename omitCenter 1]'
\   }
\ }

" map <leader>E :CocCommand explorer --preset simplify<CR>
map <leader>E :Ranger<CR>
map <leader>y "+y
map <leader>p "+p
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
let g:grepper.tools     = ['rg', 'git']
let g:grepper.jump      = 0
let g:grepper.quickfix  = 1
let g:grepper.next_tool = '<leader>g'
let g:grepper.open      = 1

" COMPLETER
"set completeopt=longest,menuone,noinsert
"inoremap <expr> <CR> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"

let test#vim#term_position = "belowright"
let test#strategy = "neovim"
let test#ruby#use_binstubs = 0

let g:python_highlight_all = 1

let g:indentLine_leadingSpaceEnabled = 0
let g:indentLine_leadingSpaceChar = '·'
let g:indentLine_fileTypeExclude = ['coc-explorer']

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
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"
inoremap <silent><expr> <cr> pumvisible() ? coc#_select_confirm() :
      \"\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"
inoremap <silent><expr> <TAB>
      \ pumvisible() ? coc#_select_confirm() :
      \ coc#expandableOrJumpable() ? "\<C-r>=coc#rpc#request('doKeymap', ['snippets-expand-jump',''])\<CR>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <silent><expr> <C-Space> coc#refresh()

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Use <C-k> for jump to previous placeholder, it's default of coc.nvim
let g:coc_snippet_prev = '<C-k>'

nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" Use `:Format` to format current buffer
nnoremap <silent> gh :call <SID>show_documentation()<CR>

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction

" kill coc.nvim after quit vim
autocmd VimLeavePre * :call coc#rpc#kill()
autocmd VimLeave * if get(g:, 'coc_process_pid', 0) | call system('kill -9 -'.g:coc_process_pid) | endif

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
