set nocompatible               " be iMproved
set fillchars=diff:⣿,vert:│

" Press F4 to toggle highlighting on/off, and show current value.
:noremap <F4> :set hlsearch! hlsearch?<CR>

" Press Space to turn off highlighting and clear any message already displayed
:nnoremap <silent> <Space> :nohlsearch<Bar>:echo<CR>
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

" support css word with -
autocmd FileType css,scss,slim,html,eruby,coffee,javascript setlocal iskeyword+=-
autocmd FileType python set shiftwidth=2 tabstop=2 expandtab

" If more than one window and previous buffer was NERDTree, go back to it.
autocmd BufEnter * if bufname('#') =~# "^NERD_tree_" && winnr('$') > 1 | b# | endif

" set t_Co=256
autocmd BufWritePre * :%s/\s\+$//e

" filetype on           " Enable filetype detection
" filetype indent on    " Enable filetype-specific indenting
" filetype plugin on    " Enable filetype-specific plugins
let mapleader= " "
set completefunc=syntaxcomplete#Complete

call plug#begin('~/.vim/plugged')
Plug 'tpope/vim-sensible'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-surround'
Plug 'vim-ruby/vim-ruby'
Plug 'tpope/vim-cucumber'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-rvm'
Plug 'Lokaltog/vim-easymotion'
Plug 'tpope/vim-rails'
Plug 'preservim/nerdcommenter'
Plug 'godlygeek/tabular'
Plug 'plasticboy/vim-markdown'
Plug 'Yggdroot/indentLine'
Plug 'JulesWang/css.vim'
Plug 'cakebaker/scss-syntax.vim'
Plug 'isRuslan/vim-es6'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
Plug 'christoomey/vim-tmux-navigator'
Plug '907th/vim-auto-save'
Plug 'kana/vim-textobj-user'
Plug 'michaeljsmith/vim-indent-object'
Plug 'joshdick/onedark.vim'
Plug 'morhetz/gruvbox'
Plug 'lifepillar/vim-solarized8'
Plug 'mhinz/vim-grepper'
Plug 'luochen1990/rainbow'
Plug 'janko/vim-test'
Plug 'ludovicchabant/vim-gutentags'
Plug 'sheerun/vim-polyglot'
Plug 'mhinz/vim-signify'
Plug 'jiangmiao/auto-pairs'
Plug 'AndrewRadev/splitjoin.vim'
Plug 'kremso/vim-spectator'
Plug 'neoclide/coc.nvim', {'do': 'yarn install --frozen-lockfile'}
Plug 'zivyangll/git-blame.vim'
Plug 'tpope/vim-haml'
Plug 'yssl/QFEnter'
Plug 'vimlab/split-term.vim'
Plug 'SirVer/ultisnips'
Plug 'honza/vim-snippets'

call plug#end()

set background=dark

let g:solarized_use16=1

colorscheme solarized8

"set rtp+=/usr/local/opt/fzf


let g:airline#extensions#coc#enabled = 1
let g:airline#extensions#tabline#enabled = 0
let g:airline_powerline_fonts = 0
let g:airline#parts#ffenc#skip_expected_string='utf-8[unix]'
let g:airline_skip_empty_sections = 1
" let g:airline_section_z = '%3p%% %3l/%L:%3v'
let g:airline_section_z = ''


" let g:lightline = { \ 'active': { \   'left': [ [ 'mode', 'paste' ], \
" [ 'gitbranch', 'readonly', 'filename', 'modified', 'cocstatus' ] ] \ }, \
" 'component_function': { \   'gitbranch': 'fugitive#head', \   'filename':
" 'FilenameForLightline', \   'cocstatus': 'coc#status' \ }, \ }

" function! FilenameForLightline() return expand('%') endfunction

let g:auto_save = 1
let g:auto_save_events = ["InsertLeave", "TextChanged"]

let g:coc_node_path = '/Users/tungtram/.asdf/installs/nodejs/12.13.0/bin/node'

" map <silent><F8> :NERDTreeFocus<CR>
" map <leader>r :NERDTreeFind<cr>
" map <leader>e :NERDTreeToggle<cr>
" let NERDTreeMinimalUI = 1
" let NERDTreeDirArrows = 1
" let NERDSpaceDelims=1
map <leader>e :CocCommand explorer<CR>

map <leader>y "+y<cr>
map <leader>p "+p<cr>
let $FZF_DEFAULT_OPTS="--reverse --bind up:preview-up,down:preview-down"
"let $FZF_DEFAULT_COMMAND='ag --nocolor --hidden --ignore node_modules --ignore .git -g ""'

let $FZF_DEFAULT_COMMAND='rg --files --no-ignore --hidden --follow --glob "!.git/*" --glob "!node_modules" --glob "!node_modules" --glob "!tmp/*" --glob "!**/*.min.js" --glob "!**/*.min.css"'
nnoremap <silent> <C-p> :FZF<CR>
let g:fzf_layout = { 'window': { 'width': 0.9, 'height': 0.6, 'rounded': v:true } }

inoremap jj <ESC>
nnoremap <leader>\ <C-w>v<C-w>l
nnoremap <leader>- <C-w>s<C-w>j
nnoremap <C-\> <C-w>v<C-w>l
nnoremap <C-_> <C-w>s<C-w>j
nnoremap <leader>G :Grepper<cr>
nnoremap <leader>g :Grepper -quickfix -open<cr>

nmap gs <plug>(GrepperOperator)
nmap gu viw<plug>(GrepperOperator)
xmap gs <plug>(GrepperOperator)

nmap gis viw<plug>(GrepperOperator)

" Optional. The default behaviour should work for most users.
let g:grepper               = {}
let g:grepper.tools         = ['rg', 'git', 'ag']
let g:grepper.jump          = 0
let g:grepper.quickfix          = 1
let g:grepper.next_tool     = '<leader>g'
let g:grepper.open      = 1

let g:rainbow_active = 1


" COMPLETER
"set completeopt=longest,menuone,noinsert
"inoremap <expr> <CR> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"

map <leader>h :History<cr>
map <leader>b :Buffers<cr>
map <leader>t :BTags<cr>
map <leader>? :GFiles?<cr>
nmap <leader>ps :let @*=expand("%")<CR>
nmap <leader>pl :let @*=expand("%:p")<CR>

let test#vim#term_position = "belowright"
let test#strategy = "neovim"
let test#ruby#use_binstubs = 0

let g:python_highlight_all = 1
let g:ycm_min_num_of_chars_for_completion = 1
let g:ycm_max_num_candidates = 20

let g:indentLine_leadingSpaceEnabled = 0
let g:indentLine_leadingSpaceChar = '·'
let g:indentLine_fileTypeExclude = ['coc-explorer']

let g:SuperTabDefaultCompletionType = "<c-n>"
let g:SuperTabLongestHighlight = 1

let g:tmux_navigator_disable_when_zoomed = 1

let g:ruby_indent_block_style = 'do'
let g:ruby_indent_assignment_style = 'variable'

nmap <Leader>f :TestFile<CR>
nmap <Leader>s :TestNearest<CR>
nmap <Leader>l :TestLast<CR>
map <Leader>= gg=G<C-o>


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
" inoremap <silent><expr> <TAB>
      " \ pumvisible() ? "\<C-n>" :
      " \ <SID>check_back_space() ? "\<TAB>" :
      " \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"
inoremap <silent><expr> <cr> pumvisible() ? coc#_select_confirm() :
                                           \"\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"
inoremap <silent><expr> <TAB>
      \ pumvisible() ? coc#_select_confirm() :
      \ coc#expandableOrJumpable() ? "\<C-r>=coc#rpc#request('doKeymap', ['snippets-expand-jump',''])\<CR>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

let g:coc_snippet_next = '<tab>'

inoremap <silent><expr> <C-Space> coc#refresh()

" inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"

nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
nmap <leader>rn <Plug>(coc-rename)

" Use `:Format` to format current buffer
command! -nargs=0 Format :call CocAction('format')
nnoremap <silent> gh :call <SID>show_documentation()<CR>

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction

noremap <Leader>tn :tabnew %<CR>
nnoremap <Leader>bl :<C-u>call gitblame#echo()<CR>

" edit init.vim
nnoremap <Leader>ev :e ~/.config/nvim/init.vim<CR>

" source init.vim
nnoremap <Leader>sv :so ~/.config/nvim/init.vim<CR>

" zoom
set winminheight=0
set winminwidth=0
nnoremap <C-w>h     <C-w>h<C-w>=
nnoremap <C-w>j     <C-w>j<C-w>=
nnoremap <C-w>k     <C-w>k<C-w>=
nnoremap <C-w>l     <C-w>l<C-w>=
nnoremap <C-w><C-h> <C-w>h<C-w>_<C-w><Bar>
nnoremap <C-w><C-j> <C-w>j<C-w>_<C-w><Bar>
nnoremap <C-w><C-k> <C-w>k<C-w>_<C-w><Bar>
nnoremap <C-w><C-l> <C-w>l<C-w>_<C-w><Bar>

" quocle
vnoremap <leader>h y:%s/<C-R>"/<C-R>"/g<left><left>
xmap <leader>ah y:Grepper -noprompt -quickfix -query <C-R>"<CR>:cfdo %s/<C-R>"/<C-R>"/g<left><left>

" browse quickfix
nnoremap <expr> <Leader>j   (&diff ? "]c" : ":cnext\<CR>")
nnoremap <expr> <Leader>k (&diff ? "[c" : ":cprev\<CR>")

map <leader>bd :%bd\|e#\|bd#<cr>
