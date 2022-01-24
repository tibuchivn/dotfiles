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

" live substitution
set inccommand=split

autocmd BufNewFile,BufRead *_spec.rb set filetype=ruby
" support css word with -
autocmd FileType css,scss,slim,html,eruby,coffee,javascript setlocal iskeyword+=-
autocmd FileType python set shiftwidth=2 tabstop=2 expandtab

" set t_Co=256
autocmd BufWritePre * :%s/\s\+$//e

let mapleader= " "
set completefunc=syntaxcomplete#Complete

call plug#begin('/Users/tungtram/.vim/nvim_bundle_compe')

Plug 'ludovicchabant/vim-gutentags'
Plug 'neovim/nvim-lspconfig'
Plug 'vim-ruby/vim-ruby'
Plug 'easymotion/vim-easymotion'
Plug 'tpope/vim-sensible'
Plug 'tpope/vim-haml'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-unimpaired'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-rails'
Plug 'tpope/vim-cucumber'
Plug 'preservim/nerdcommenter'
Plug 'itchyny/lightline.vim'
Plug 'spywhere/lightline-lsp'
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
Plug 'vimlab/split-term.vim'
Plug 'kana/vim-textobj-user'
Plug 'michaeljsmith/vim-indent-object'
Plug 'ryanoasis/vim-devicons'
Plug 'francoiscabrol/ranger.vim'
Plug 'rbgrouleff/bclose.vim'
Plug 'mhinz/vim-signify'
Plug 'rhysd/git-messenger.vim'
" Plug 'ms-jpq/coq_nvim', {'branch': 'coq'}
" Plug 'ms-jpq/coq.artifacts', {'branch': 'artifacts'}
Plug 'ojroques/vim-scrollstatus'
Plug 'AndrewRadev/switch.vim'

Plug 'neovim/nvim-lspconfig'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-cmdline'
Plug 'hrsh7th/nvim-cmp'

Plug 'SirVer/ultisnips'
Plug 'honza/vim-snippets'
Plug 'quangnguyen30192/cmp-nvim-ultisnips'
Plug 'onsails/lspkind-nvim'

call plug#end()

set background=dark
" set background=light
let g:solarized_use16=1
colorscheme solarized8
"
" configuration for vim-scrollstatus
let g:scrollstatus_symbol_track = '-'
let g:scrollstatus_symbol_bar = '|'

" configuration for coq completion
" let g:coq_settings = {
      " \ 'auto_start': v:true,
      " \ 'clients.tmux.enabled': v:false,
      " \ 'keymap.jump_to_mark': '<c-j>'
      " \ }

" highlight yanked text
augroup LuaHighlight
  autocmd!
  autocmd TextYankPost * silent! lua require'vim.highlight'.on_yank()
augroup END

" configuration for nvim lsp
lua << END
  -- Setup nvim-cmp.
local cmp = require'cmp'
local lspkind = require('lspkind')

cmp.setup({
  formatting = {
    format = lspkind.cmp_format({
      with_text = true,
      menu = ({
        buffer = "[Buffer]",
        nvim_lsp = "[LSP]",
        luasnip = "[LuaSnip]",
        nvim_lua = "[Lua]",
        latex_symbols = "[Latex]",
      })
    }),
  },
  snippet = {
    -- REQUIRED - you must specify a snippet engine
    expand = function(args)
      -- vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
      -- require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
      vim.fn["UltiSnips#Anon"](args.body) -- For `ultisnips` users.
      -- require'snippy'.expand_snippet(args.body) -- For `snippy` users.
    end,
  },
  mapping = {
    ['<C-b>'] = cmp.mapping(cmp.mapping.scroll_docs(-4), { 'i', 'c' }),
    ['<C-f>'] = cmp.mapping(cmp.mapping.scroll_docs(4), { 'i', 'c' }),
    ['<C-Space>'] = cmp.mapping(cmp.mapping.complete(), { 'i', 'c' }),
    ['<C-y>'] = cmp.config.disable, -- Specify `cmp.config.disable` if you want to remove the default `<C-y>` mapping.
    ['<C-e>'] = cmp.mapping({
      i = cmp.mapping.abort(),
      c = cmp.mapping.close(),
    }),
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
  },
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
    -- { name = 'vsnip' }, -- For vsnip users.
    -- { name = 'luasnip' }, -- For luasnip users.
    { name = 'ultisnips' }, -- For ultisnips users.
    -- { name = 'snippy' }, -- For snippy users.
  }, {
    { name = 'buffer' },
  })
})

-- Use buffer source for `/` (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline('/', {
  sources = {
    { name = 'buffer' }
  }
})

-- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline(':', {
  sources = cmp.config.sources({
    { name = 'path' }
  }, {
    { name = 'cmdline' }
  })
})
local capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities())

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
  buf_set_keymap('n', '<leader>d', '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>', opts)

  vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
    vim.lsp.diagnostic.on_publish_diagnostics, {
      virtual_text = false,
      underline = true,
      signs = true,
    }
  )
  -- vim.cmd [[autocmd CursorHold * lua vim.lsp.diagnostic.show_line_diagnostics()]]
  -- vim.cmd [[autocmd CursorHoldI * silent! lua vim.lsp.buf.signature_help()]]
end

local servers = {'solargraph', 'tsserver'}
-- local coq = require 'coq'
for _, lsp in ipairs(servers) do
  nvim_lsp[lsp].setup { on_attach = on_attach, capabilities = capabilities, autostart = false }
  -- nvim_lsp[lsp].setup(coq.lsp_ensure_capabilities({ on_attach = on_attach }))
end

END


" nerdcommenter to give extra space after #
let NERDSpaceDelims=1

" ranger integration
let g:ranger_map_keys = 0

" gutentags ignore javascript and not load in diff mode
let g:gutentags_exclude_filetypes = ['javascript', 'javascriptreact']
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
map <leader>y "+y
map <leader>P "+p
map <leader>p "0p
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
nnoremap <leader>gg :Grepper -quickfix -open<cr>
nnoremap <leader>gq :Grepper -quickfix -open<cr>
nnoremap <leader>gl :Grepper -noquickfix -open<cr>

nnoremap <Leader>et :tabnew ~/code_temp.rb<CR>
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

map <leader>S :Switch<cr>

" quocle map cfdo
" vnoremap <leader>h y:%s/<C-R>"/<C-R>"/g<left><left>
" xmap <leader>ah y:Grepper -noprompt -quickfix -query <C-R>"<CR>:cfdo %s/<C-R>"/<C-R>"/g<left><left>

nnoremap <silent> <C-p> :FZF<CR>

let g:fzf_layout = { 'window': { 'width': 0.9, 'height': 0.6, 'rounded': v:true } }
" [Buffers] Jump to the existing window if possible
let g:fzf_buffers_jump = 1

inoremap jj <ESC>

let g:grepper           = {}
let g:grepper.tools     = ['rg', 'ag', 'git']
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

onoremap q i'
onoremap Q i"

" junegunn/vim-easy-align
" Start interactive EasyAlign in visual mode (e.g. vipga)
xmap ga <Plug>(EasyAlign)

" Start interactive EasyAlign for a motion/text object (e.g. gaip)
nmap ga <Plug>(EasyAlign)
