" 2026年版 .vimrc
" macOS / WSL / Linux / Windows の Vim でなるべく同じ挙動にする設定。
" 古い Vim でも読めるように、プラグイン前提の設定は入れない。

" vi 互換をオフにして、Vim の標準機能を使う。
set nocompatible

" 日本語ファイル名や全角文字を扱いやすくする。
set encoding=utf-8
set fileencodings=utf-8,cp932,sjis,euc-jp,latin1

" 変更中のファイルでも、保存せずに別バッファへ移動できるようにする。
set hidden

" 行番号を表示する。
set number

" マウス操作を有効にする。不要な環境では ~/.vimrc.local で set mouse= にする。
set mouse=a

" Backspace でインデント、改行、挿入開始位置を自然に消せるようにする。
set backspace=indent,eol,start

" 新しい行のインデントを現在行に合わせる。
set autoindent

" Tab キー入力時の桁幅。
set tabstop=4

" インデント操作時に使う幅。
set shiftwidth=4

" Tab キーを押した時に shiftwidth に合わせて動かす。
set smarttab

" Tab をスペースに変換したい場合は、次の行を ~/.vimrc.local で有効化する。
" set expandtab

" インクリメンタルサーチを有効にする。
set incsearch

" 検索結果をハイライトする。
set hlsearch

" 検索時に大文字小文字を賢く扱う。
set ignorecase
set smartcase

" 閉じ括弧を入力した時、対応する括弧を一瞬強調する。
set showmatch

" コマンドライン補完を使いやすくする。
set wildmenu
set wildmode=list:longest,full

" ステータス表示を少し詳しくする。
set ruler
set showcmd

" バックアップ、スワップ、Undo ファイル用のディレクトリ。
" 存在しないと Vim が警告を出すため、起動時に作成する。
let s:vim_cache_dir = expand('$HOME/.vimbackup')
if exists('*mkdir') && !isdirectory(s:vim_cache_dir)
  call mkdir(s:vim_cache_dir, 'p')
endif

" バックアップファイルの保存先。
execute 'set backupdir^=' . fnameescape(s:vim_cache_dir)

" スワップファイルの保存先。
execute 'set directory^=' . fnameescape(s:vim_cache_dir)

" 永続 Undo が使える Vim では Undo ファイルも同じ場所に保存する。
if has('persistent_undo')
  execute 'set undodir^=' . fnameescape(s:vim_cache_dir)
  set undofile
endif

" OS のクリップボードと連携する。
" unnamedplus が使える環境では Linux/WSL の +clipboard と相性がよい。
if has('clipboard')
  if has('unnamedplus')
    set clipboard^=unnamedplus
  else
    set clipboard^=unnamed
  endif
endif

" grep 検索の出力形式。
set grepformat=%f:%l:%m,%f:%l%m,%f\ \ %l%m,%f

" grep は行番号付きで実行する。
set grepprg=grep\ -nh

" Esc 連打で検索結果のハイライトを消す。
nnoremap <silent> <ESC><ESC> :nohlsearch<CR>

" vimgrep / grep の後に quickfix window を開く。
augroup QuickfixWindow
  autocmd!
  autocmd QuickFixCmdPost *grep* cwindow
augroup END

" タブや行末など、見えない文字を表示する。
set list
set listchars=tab:▸\ ,eol:¬

" 全角スペースを見つけやすくする。
function! ZenkakuSpace() abort
  highlight ZenkakuSpace cterm=reverse ctermfg=DarkGray gui=reverse guifg=DarkGray
endfunction

if has('syntax')
  augroup ZenkakuSpace
    autocmd!
    " カラースキーム変更後も全角スペース表示を維持する。
    autocmd ColorScheme * call ZenkakuSpace()
    autocmd VimEnter,WinEnter * match ZenkakuSpace /　/
  augroup END
  call ZenkakuSpace()
endif

" バイナリ編集 xxd モード。
" vim -b で起動した場合、または *.bin を開いた場合に xxd 表示へ変換する。
augroup BinaryXXD
  autocmd!
  autocmd BufReadPre *.bin let &binary = 1
  autocmd BufReadPost * if &binary | silent %!xxd -g 1 | set filetype=xxd | endif
  autocmd BufWritePre * if &binary | silent %!xxd -r | endif
  autocmd BufWritePost * if &binary | silent %!xxd -g 1 | set nomodified | endif
augroup END

" 環境ごとの個別設定。
" 例: set expandtab / set mouse= / colorscheme などをここへ逃がす。
if filereadable(expand('~/.vimrc.local'))
  source ~/.vimrc.local
endif
