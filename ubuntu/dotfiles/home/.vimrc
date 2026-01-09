
" Basic settings
set nocompatible              " Use Vim defaults (not vi)
set number                    " Show line numbers
set relativenumber            " Show relative line numbers
set tabstop=8                 " Tabs = 4 spaces
set shiftwidth=8              " Indentation = 4 spaces
" set expandtab                 " Use spaces instead of tabs
set smartindent               " Auto-indent new lines
set autoindent
set clipboard=unnamedplus     " Use system clipboard
set hlsearch                  " Highlight search results
set incsearch                 " Show search matches as you type
set ignorecase smartcase      " Case-insensitive unless capital used
set scrolloff=8               " Keep 8 lines above/below cursor
set splitbelow splitright     " Better split behavior
syntax on
highlight LineNr ctermfg=white guifg=white

" Key mappings
nnoremap <Space> :noh<CR>     " Clear search highlight with space
inoremap kj <Esc>             " Exit insert mode with jk

" Auto-pairs without plugin
inoremap ( ()<Left>
inoremap [ []<Left>
inoremap { {}<Left>
inoremap < <><Left>
inoremap ' ''<Left>
inoremap " ""<Left>

call plug#begin('~/.vim/plugged')
Plug 'tpope/vim-commentary'
call plug#end()
