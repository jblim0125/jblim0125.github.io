# Install VIM Version 8.X

YouCompleteMe 를 포함한 플러그인 활성화를 포함  

1. remove vim  

    ```shell
    yum -y remove vim-minimal vim-common vim-enhanced
    ```

2. add epel repo  
  
    ```shell
    yum -y install epel-release
    ```

3. install development tools  

    ```shell
    yum -y groupinstall "Development Tools"
    yum -y install ncurses-devel git-core openssl-devel clang wget curl cmake
    ```

4. install python2, python3, python-devel

    ```shell
    yum install python-devel python3-devel -y
    ```

5. Get VIM source

    ```shell
    git clone https://github.com/vim/vim.git && cd vim
    ```

6. VIM configuration  
    - Get Python Config Path  
        x64의 경우  
        python2 : /usr/lib64/python2.X/config
        python3 : /usr/lib64/python3.X/config....

        ```bash
        export PYTHON2_CONFIG_PATH=/usr/lib64/python2.x/config 
        export PYTHON3_CONFIG_PATH=/usr/lib64/python3.6/config-3.6m-x86_64-linux-gnu
        ```

    ```bash
    $ ./configure  \
    --with-features=huge \
    --enable-python3interp=yes \
    --enable-cscope \
    --enable-terminal \
    --enable-multibyte \
    --enable-fontset \
    --enable-gui=auto \
    --with-python3-command=/usr/bin/python3 \
    --with-python3-config-dir=$PYTHON3_CONFIG_PATH 
    ```

7. Build, Install  
    분산 컴파일을 위한 -j 옵션을 사용한다.  
    'cat /proc/cpuinfo' 를 이용해 CPU core수를 확인하고 적절한 수를 입력한다.  

    ```bash
    make -j 4
    ```

    configuration 과정에서 활성화한 옵션들이 모두 적용되었는지 확인한다.  

    ```bash
    $ ./src/vim --version
    ...
    ...
    +cmdline_compl     +keymap            +postscript        +vartabs
    +cmdline_hist      +lambda            +printer           +vertsplit
    +cmdline_info      +langmap           +profile           +virtualedit
    +comments          +libcall           +python/dyn        +visual
    +conceal           +linebreak         +python3/dyn       +visualextra
    +cryptv            +lispindent        +quickfix          +viminfo
    +cscope            +listcmds          +reltime           +vreplace
    +cursorbind        +localmap          +rightleft         +wildignore
    +cursorshape       -lua               -ruby              +wildmenu
    ...
    ...
    ```

    설치  

    ```bash
    make install
    ```

8. Install VIM Plugin  
    Vundle를 이용한 플러그인 관리  

    8.1. Install Vundle  

      ```shell
      git clone https://github.com/gmarik/Vundle.vim.git ~/.vim/bundle/Vundle.vim
      ```

    8.2 Set .vimrc  
      .vimrc 최상단에 아래의 내용이 추가되어야 한다.  

      ```shell
      set nocompatible              " required
      filetype off                  " required

      " set the runtime path to include Vundle and initialize
      set rtp+=~/.vim/bundle/Vundle.vim
      call vundle#begin()

      " let Vundle manage Vundle, required
      Plugin 'gmarik/Vundle.vim'

      " add all your plugins here (note older versions of Vundle
      " used Bundle instead of Plugin)

      " ...

      " All of your Plugins must be added before the following line
      call vundle#end()            " required
      filetype plugin indent on    " required
      ```

9. How To Install Color Scheme  
    9.1. vim color scheme를 다운
    ex : molokai  

    ```bash
    git clone https://github.com/tomasr/molokai.git && cd molokai
    ```

    9.2. ~/.vim/colors 폴더에 복사  

    ```bash
    mkdir ~/.vim/colors && cp colors/*.vim ~/.vim/colors
    ```

    9.3. ~/.vimrc 파일에 설정  

    ```bash
    $ vi ~/.vimrc

    ...
    ...
    " Colorscheme                   
    syntax enable                   
    set t_Co=256
    colorscheme molokai
    let g:rehash256 = 1             " 어두운 GUI 버전에 가깝게 만들기 위한 옵션  
    let g:molokai_original = 1      " monokai 배경색과 일치하도록 구성표를 선호하는 경우  
    ...
    ...
    ```

Appendix.1. Golang  

```bash
wget https://dl.google.com/go/go1.14.4.linux-amd64.tar.gz
tar -C /usr/local -xzf go1.14.4.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
```

Appendix.2. Python  

Appendix.3. Yaml  

Appendix.4. Markdown  

Appendix.5. Example .vimrc  

```.vimrc
set nocompatible              " required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" let Vundle manage Vundle, required
Plugin 'gmarik/Vundle.vim'

" add all your plugins here (note older versions of Vundle
" used Bundle instead of Plugin)

" Yaml
Plugin 'stephpy/vim-yaml'

" NERDTree
Plugin 'scrooloose/nerdtree'
Plugin 'jistr/vim-nerdtree-tabs'

" Plugin 'iamcco/markdown-preview.nvim'
" markdown preview 는 plugininstall 후 :call mkdp#util#install() 필요 

" All of your Plugins must be added before the following line
call vundle#end()            " required

" Indentation
filetype plugin indent on    " required, ... and enable filetype detection      
" addinig indent
au BufNewFile,BufRead *.js, *.html, *.css
    \ set tabstop=2
    \ set softtabstop=2
    \ set shiftwidth=2

" Color scheme
set t_Co=256
let g:rehash256 = 1
let g:molokai_original = 1      " 회색 배경으로 설정하고자 하는 경우 
colorscheme molokai

" TTY
set ttyfast
set ttymouse=xterm2             " Indicate terminal type for mouse codes
set ttyscroll=3                 " Speedup scrolling

" Status Line
set laststatus=2                " Show status line always

" Encoding                  
set encoding=utf-8
set fileencoding=utf-8
set fileencodings=utf-8

" Disable visualbell
set noerrorbells visualbell t_vb=
if has('autocmd')
  autocmd GUIEnter * set visualbell t_vb=
endif
" Disable beeps
set noerrorbells                " No beeps

" Syntax
syntax enable

" Split
set splitbelow
set splitright

" Split navigations
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

set autoread                    " Automatically read changed files
set autoindent                  " Enabile Autoindent
set backspace=indent,eol,start  " Makes backspace key more powerful.

" Search 
set incsearch                   " Shows the match while typing
set hlsearch                    " Highlight found searches
set ignorecase                  " Search case insensitive...
set smartcase                   " ... but not it begins with upper case

set number                      " Show line numbers
set showcmd                     " Show me what I'm typing
set noswapfile                  " Don't use swapfile
set nobackup                    " Don't create annoying backup files

set splitright                  " Vertical windows should be split to right
set splitbelow                  " Horizontal windows should split to bottom

set autowrite                   " Automatically save before :next, :make etc.
set hidden                      " Buffer should still exist if window is closed
set fileformats=unix,dos,mac    " Prefer Unix over Windows over OS 9 formats

set noshowmatch                 " Do not show matching brackets by flickering
set noshowmode                  " We show the mode with airline or lightline

set completeopt=menu,menuone    " Show popup menu, even if there is one entry
set pumheight=10                " Completion window max size

set nocursorcolumn              " Do not highlight column (speeds up highlighting)
set nocursorline                " Do not highlight cursor (speeds up highlighting)
set lazyredraw                  " Wait to redraw

" Enable to copy to clipboard for operations like yank, delete, change and put
" http://stackoverflow.com/questions/20186975/vim-mac-how-to-copy-to-clipboard-without-pbcopy
if has('unnamedplus')
  set clipboard^=unnamed
  set clipboard^=unnamedplus
endif

" This enables us to undo files even if you exit Vim.
if has('persistent_undo')
  set undofile
  set undodir=~/.config/vim/tmp/undo//
endif

"*****************************************************************************
"" Autocmd Rules
"*****************************************************************************
"" The PC is fast enough, do syntax highlight syncing from start unless 200 lines
augroup vimrc-sync-fromstart
  autocmd!
  autocmd BufEnter * :syntax sync maxlines=200
augroup END

"" Remember cursor position
augroup vimrc-remember-cursor-position
  autocmd!
  autocmd BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g`\"" | endif
augroup END

""""""""""""""""""""""
"      Mappings      "
""""""""""""""""""""""

" Set leader shortcut to a comma ','. By default it's the backslash
let mapleader = ","

"" Split
noremap <Leader>h :<C-u>split<CR>
noremap <Leader>v :<C-u>vsplit<CR>

" Jump to next error with Ctrl-n and previous error with Ctrl-m. Close the
" quickfix window with <leader>a
map <C-n> :cnext<CR>
map <C-m> :cprevious<CR>
nnoremap <leader>a :cclose<CR>

"" Clean search (highlight)
nnoremap <silent> <leader><space> :noh<cr>

"" Move visual block
vnoremap J :m '>+1<CR>gv=gv
vnoremap K :m '<-2<CR>gv=gv

" Search mappings: These will make it so that going to the next one in a
" search will center on the line it's found in.
nnoremap n nzzzv
nnoremap N Nzzzv

" Act like D and C
nnoremap Y y$

" Set paste mode
set pastetoggle=<F10>

" For vimdiff ignore white space
if &diff
    " diff mode
    set diffopt+=iwhite
endif

"" Buffer nav
noremap <leader>z :bp<CR>
noremap <leader>q :bp<CR>
noremap <leader>x :bn<CR>
noremap <leader>w :bn<CR>

"" Close buffer
noremap <leader>c :bd<CR>

"" Tabs
nnoremap <Tab> gt
nnoremap <S-Tab> gT
nnoremap <silent> <S-t> :tabnew<CR>

" Enter automatically into the files directory
autocmd BufEnter * silent! lcd %:p:h

"""""""""""""""""""""
"      NERDTree     "
"""""""""""""""""""""
let g:NERDTreeChDirMode=2
let g:NERDTreeDirArrowExpandable = '+'
let g:NERDTreeDirArrowCollapsible = '-'
let g:NERDTreeIgnore=['\.rbc$', '\~$', '\.pyc$', '\.db$', '\.sqlite$', '__pycache__']
let g:NERDTreeSortOrder=['^__\.py$', '\/$', '*', '\.swp$', '\.bak$', '\~$']
let g:NERDTreeShowBookmarks=1
let g:nerdtree_tabs_focus_on_files=1
let g:NERDTreeMapOpenInTabSilent = '<RightMouse>'
let g:NERDTreeWinSize = 35
set wildignore+=*/tmp/*,*.so,*.swp,*.zip,*.pyc,*.db,*.sqlite
nnoremap <silent> <F3> :NERDTreeToggle<CR>

"" start time turn on nerdtree
autocmd VimEnter * if argc() == 1 | NERDTree | wincmd p | endif
"" end time turn off nerdtree
function! CheckLeftBuffers()
  if tabpagenr('$') == 1
    let i = 1
    while i <= winnr('$')
      if getbufvar(winbufnr(i), '&buftype') == 'help' ||
          \ getbufvar(winbufnr(i), '&buftype') == 'quickfix' ||
          \ exists('t:NERDTreeBufName') &&
          \   bufname(winbufnr(i)) == t:NERDTreeBufName ||
          \ bufname(winbufnr(i)) == '__Tag_List__'
        let i += 1
      else
        break
      endif
    endwhile
    if i == winnr('$') + 1
      qall
    endif
    unlet i
  endif
endfunction
autocmd BufEnter * call CheckLeftBuffers()
```

## YouCompleteMe python3버전 설치

```shell
cd ~/.vim/bundle/YouCompleteMe/
scl enable devtoolset-8 -- bash
find / -name "libstdc++.so.6*"
```

## 6.0.20 version 이상의 libstdc를 찾아서 /usr/lib64에 넣는다

```shell
cp /var/lib/docker/overlay2/49355c5fbe511421a1113d67fff04f4c3ec5f3def5c299771c592fb50413f691/diff/opt/conda/lib/libstdc++.so.6.0.26 /usr/lib64 
mv libstdc++.so.6 libstdc++.so.6.bkp
cd /usr/lib64
ln -s libstdc++.so.6.26 libstdc++.so.6
cd /root/.vim/bundle/YouCompleteMe
python3 ./install.sh --clang-completer
```
