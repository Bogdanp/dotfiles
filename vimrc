" Disable filetype plugins for Vundle
filetype off

" Set up Vundle
set rtp+=~/.vim/bundle/Vundle.vim

" Plugins
call vundle#begin()

Plugin 'VundleVim/Vundle.vim'
Plugin 'tpope/vim-commentary'
Plugin 'tpope/vim-fugitive'
Plugin 'tpope/vim-surround'
Plugin 'Bogdanp/quicksilver.vim'

call vundle#end()

" Enable plugins and indentation for specific file types
filetype plugin indent on

" Backup
set nobackup
set nowritebackup

" Folding
set fdm=marker                          " Fold by marked area

" Completion
set completeopt=menu,menuone,longest    " Completion menu options
set history=10000                       " Number of commands to remember
set wildmenu                            " Show a menu when doing completion

" Persistent undo
set undodir=/Users/bogdan/.vimundo      " Where undo files are saved
set undofile                            " Undo diffs are saved in files
set undolevels=10000                    " Max number of undos per file
set undoreload=100000                   " Save the whole buffer for undo when reloading it

" Searching
set hlsearch                            " Enable highlighting of search terms
set incsearch                           " Search incrementally
set ignorecase                          " Ignore case when searching

" Tabs
set expandtab
set tabstop=4
set shiftwidth=4
set softtabstop=4
set autoindent

" UI
syntax on                               " Enable syntax highlighting

set backspace=indent,eol,start          " Backspace over everything
set cursorline                          " Highlight current line
set cursorcolumn                        " Highlight current column
set colorcolumn=100                     " Highlight the 100th column in a window
set hidden                              " Allow switching buffers without saving
set ruler                               " Show the cursor position all the time
set scrolloff=3                         " Top and bottom padding when scrolling
set showcmd                             " Display incomplete commands
set sidescrolloff=3                     " Left and right padding when scrolling

" Autocommands
" Open buffers with cursor set to its last position
autocmd BufReadPost *
  \ if line("'\'") > 0 && line("'\'") <= line("$") |
  \   exe "normal g`\"" |
  \ endif

" Enable omni completion.
autocmd FileType css setlocal omnifunc=csscomplete#CompleteCSS
autocmd FileType html,markdown setlocal omnifunc=htmlcomplete#CompleteTags
autocmd FileType javascript setlocal omnifunc=javascriptcomplete#CompleteJS
autocmd FileType python setlocal omnifunc=pythoncomplete#Complete
autocmd FileType xml setlocal omnifunc=xmlcomplete#CompleteTags

" Miscellaneous
set formatprg=par                       " Use par to format documents with gq
set linebreak                           " Wrap at spaces
set nowrap                              " Turn wrapping off
set autochdir                           " Change dir to current file automatically
set tags+=./.tags;/
set shell=/bin/bash

" OCaml
let g:opamshare = substitute(system('opam config var share'),'\n$','','''')
execute "set rtp+=" . g:opamshare . "/merlin/vim"

" Bindings
" zz is a stupid binding for this 
nnoremap <C-l> zz

" Enhance buffer switching
nnoremap <silent><leader>b :ls<CR>:b

" Toggle listchars
nnoremap <silent><leader>l :set list!<CR>

" :help emacs-keys
cnoremap <C-G> <Esc>
cnoremap <C-A> <Home>
cnoremap <C-B> <Left>
cnoremap <C-D> <Del>
cnoremap <C-E> <End>
cnoremap <C-F> <Right>
cnoremap <C-N> <Down>
cnoremap <C-P> <Up>
cnoremap <M-b> <S-Left>
cnoremap <M-f> <S-Right>
