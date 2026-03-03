" Neovim config
" Minimal setup

set number
set relativenumber
set tabstop=4
set shiftwidth=4
set expandtab
set smartindent
set wrap
set linebreak
set scrolloff=8
set signcolumn=yes
set colorcolumn=80
set updatetime=50
set timeoutlen=300

" Theme
colorscheme catppuccin-mocha

" Leader
let mapleader = " "
let maplocalleader = " "

" Save & quit
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
nnoremap <leader>Q :qa!<CR>

" Splits
nnoremap <leader>sv :vsplit<CR>
nnoremap <leader>sh :split<CR>

" Navigation
nnoremap <leader>h :wincmd h<CR>
nnoremap <leader>j :wincmd j<CR>
nnoremap <leader>k :wincmd k<CR>
nnoremap <leader>l :wincmd l<CR>

" Buffers
nnoremap <leader>bn :bnext<CR>
nnoremap <leader>bp :bprevious<CR>
nnoremap <leader>bd :bdelete<CR>

" Search
nnoremap <leader>/ :nohlsearch<CR>

" Terminal
tnoremap <Esc> <C-\><C-n>
nnoremap <leader>tt :terminal<CR>

" Disable arrows
nnoremap <up> <nop>
nnoremap <down> <nop>
nnoremap <left> <nop>
nnoremap <right> <nop>
