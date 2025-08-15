set nocompatible              " be iMproved, required
filetype off                  " required

set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" Plugin manager
Plugin 'VundleVim/Vundle.vim'

" Color schemes
Plugin 'morhetz/gruvbox'

" Essential plugins (uncomment as needed)
"Plugin 'tpope/vim-sensible'          " Sensible defaults
"Plugin 'tpope/vim-fugitive'          " Git integration
"Plugin 'scrooloose/nerdtree'         " File explorer
"Plugin 'ctrlpvim/ctrlp.vim'          " Fuzzy file finder
"Plugin 'vim-airline/vim-airline'     " Status bar
"Plugin 'vim-airline/vim-airline-themes'
"Plugin 'tpope/vim-commentary'        " Easy commenting
"Plugin 'tpope/vim-surround'          " Surround text with quotes/brackets
"Plugin 'airblade/vim-gitgutter'      " Git diff in gutter
"Plugin 'dense-analysis/ale'          " Linting and fixing

call vundle#end()            " required
filetype plugin indent on    " required

" Basic settings
syntax on
colorscheme gruvbox
set background=dark

" Editor settings
set number                    " Show line numbers
set relativenumber           " Show relative line numbers
set cursorline               " Highlight current line
set wrap                     " Wrap lines
set linebreak                " Break lines at word boundaries
set scrolloff=8              " Keep 8 lines visible when scrolling
set sidescrolloff=8          " Keep 8 columns visible when scrolling

" Indentation
set expandtab                " Use spaces instead of tabs
set tabstop=4                " Tab width
set shiftwidth=4             " Indent width
set softtabstop=4            " Soft tab width
set autoindent               " Auto indent
set smartindent              " Smart indent

" Search
set hlsearch                 " Highlight search results
set incsearch                " Incremental search
set ignorecase               " Case insensitive search
set smartcase                " Case sensitive if uppercase present

" File handling
set hidden                   " Allow unsaved buffers
set autoread                 " Auto reload changed files
set backup                   " Enable backups
set backupdir=~/.vim/backup  " Backup directory
set directory=~/.vim/swap    " Swap directory
set undofile                 " Persistent undo
set undodir=~/.vim/undo      " Undo directory

" Create backup directories if they don't exist
if !isdirectory($HOME."/.vim/backup")
    call mkdir($HOME."/.vim/backup", "p")
endif
if !isdirectory($HOME."/.vim/swap")
    call mkdir($HOME."/.vim/swap", "p")
endif
if !isdirectory($HOME."/.vim/undo")
    call mkdir($HOME."/.vim/undo", "p")
endif

" Key mappings
let mapleader = " "          " Set leader key to space

" Clear search highlighting
nnoremap <leader>h :nohlsearch<CR>

" Quick save and quit
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
nnoremap <leader>x :x<CR>

" Buffer navigation
nnoremap <leader>n :bnext<CR>
nnoremap <leader>p :bprev<CR>
nnoremap <leader>d :bdelete<CR>

" Window navigation
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Plugin-specific settings (uncomment when plugins are enabled)
"" NERDTree
"nnoremap <leader>e :NERDTreeToggle<CR>
"let NERDTreeShowHidden=1

"" CtrlP
"let g:ctrlp_working_path_mode = 'ra'
"let g:ctrlp_custom_ignore = '\v[\/]\.(git|hg|svn)$'

"" Airline
"let g:airline_powerline_fonts = 1
"let g:airline#extensions#tabline#enabled = 1

"" ALE
"let g:ale_sign_error = '●'
"let g:ale_sign_warning = '.'
"let g:ale_lint_on_enter = 0