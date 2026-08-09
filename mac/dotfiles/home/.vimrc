
" Basic settings
set nocompatible              " Use Vim defaults (not vi)
set number                    " Show line numbers
set relativenumber            " Show relative line numbers
set tabstop=8                 " Tabs = 4 spaces
set shiftwidth=8              " Indentation = 4 spaces
" set expandtab                 " Use spaces instead of tabs
set smartindent               " Auto-indent new lines
set autoindent
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
Plug 'wakatime/vim-wakatime'
call plug#end()

" 1. Enable system clipboard integration
set clipboard+=unnamedplus

" 2. Send OSC 52 escape sequences on yank
function! s:OSCYank() abort
  if v:event.operator ==# 'y'
    let l:str = join(v:event.regcontents, "\n")
    let l:b64 = system('base64 | tr -d "\r\n"', l:str)
    let l:osc = printf("\x1b]52;c;%s\x07", l:b64)

    " Handle Tmux escape sequence wrapping if running inside Tmux
    if !empty($TMUX)
      let l:osc = printf("\x1bPtmux;\x1b%s\x1b\\", substitute(l:osc, "\x1b", "\x1b\x1b", "g"))
    endif

    call writefile([l:osc], '/dev/tty', 'b')
  endif
endfunction

augroup OSC52
  autocmd!
  autocmd TextYankPost * call s:OSCYank()
augroup END
