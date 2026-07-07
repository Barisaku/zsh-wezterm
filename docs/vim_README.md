# Vim 設定 README

この README は `config/vim/.vimrc` の使い方メモです。
macOS / WSL / Linux / Windows の Vim で、なるべく同じ基本操作になるようにしています。

## インストール

全部まとめて入れる:

```sh
./install.sh
```

Vim 設定だけ入れる:

```sh
./install.sh --only vim
```

インストール先:

```text
config/vim/.vimrc -> ~/.vimrc
```

Windows native の Vim / gVim で使う場合は、`config/vim/.vimrc` を次へ置きます。

```text
%USERPROFILE%\.vimrc
```

既存の `~/.vimrc` は上書き前にバックアップします。

```text
~/.vimrc.backup.YYYYMMDD-HHMMSS
```

## キャッシュディレクトリ

バックアップ、スワップ、Undo ファイルは次に集めます。

```text
~/.vimbackup
```

Vim 起動時にも作成しますが、`install.sh` でも作成します。

## 主な設定

- `set nocompatible`: vi 互換を切って Vim として使う
- `set number`: 行番号を表示
- `set hidden`: 保存前でも別バッファへ移動できる
- `set mouse=a`: マウス操作を有効化
- `set backspace=indent,eol,start`: Backspace を自然に使う
- `set tabstop=4` / `set shiftwidth=4`: Tab とインデント幅を 4 にする
- `set incsearch` / `set hlsearch`: 検索しながら結果表示
- `set ignorecase` / `set smartcase`: 小文字検索は大小無視、大文字を含む検索は大小区別
- `set list`: タブと行末を表示
- 全角スペースを反転表示
- `vim -b` または `*.bin` で xxd バイナリ編集モード

## クリップボード

Vim が clipboard 機能付きでビルドされている場合だけ、OS のクリップボードと連携します。

優先順:

```text
unnamedplus
unnamed
```

WSL では Vim の種類によって clipboard 機能がない場合があります。
その場合も起動エラーにはせず、Vim 内部のレジスタだけを使います。

確認:

```sh
vim --version | grep clipboard
```

`+clipboard` なら OS クリップボード連携あり、`-clipboard` ならなしです。

## 環境別の調整

共通設定を直接編集せず、環境ごとの差分は `~/.vimrc.local` に書きます。

例:

```vim
" Tab をスペースに変換する
set expandtab

" マウスを無効にする
set mouse=

" 好きなカラースキームを使う
colorscheme desert
```

`~/.vimrc.local` が存在する場合だけ読み込むため、ない環境でもエラーになりません。

## よく使う操作

検索ハイライトを消す:

```text
Esc Esc
```

grep して quickfix を開く:

```vim
:grep keyword %
:cnext
:cprev
:cclose
```

バイナリを見る:

```sh
vim -b file.bin
```
