" Basic settings
set nocompatible              " Use Vim defaults (not vi)
set number                    " Show line numbers
set relativenumber            " Show relative line numbers
set tabstop=8                 " Tabs = 4 spaces
set shiftwidth=8              " Indentation = 4 spaces
" set expandtab                 " Use spaces instead of tabs
set smartindent               " Auto-indent new lines
set autoindent
if has('clipboard')
  set clipboard=unnamedplus     " Use system clipboard if supported
endif
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

" Sync yank to system clipboard via OSC 52 if native clipboard is unavailable
if !has('clipboard') && exists('##TextYankPost') && exists('*echoraw') && exists('*base64_encode') && exists('*str2blob')
  augroup SyncYankToClipboard
    autocmd!
    autocmd TextYankPost * if v:event.operator ==# 'y' | call echoraw(printf("\<Esc>]52;c;%s\<Esc>\\", base64_encode(str2blob(v:event.regcontents)))) | endif
  augroup END
endif
