# WezTerm キーバインド早見表

この設定では `Ctrl-q` が leader キーです。

```text
Ctrl-q を押してから、2 秒以内に次のキーを押す
```

`SUPER` は macOS では `Cmd`、Windows / Linux では環境により Windows キー相当です。
Windows では `SUPER` が押しづらいため、主要操作に `Ctrl-Shift` / `Alt` の代替キーを用意しています。

## まず覚える 10 個

| キー | 機能 |
|---|---|
| `Cmd-t` / `Ctrl-Shift-t` | 新しいタブ |
| `Cmd-w` / `Ctrl-Shift-w` | タブを閉じる |
| `Ctrl-Tab` | 次のタブ |
| `Ctrl-Shift-Tab` | 前のタブ |
| `Cmd-1` から `Cmd-9` / `Alt-1` から `Alt-9` | 指定タブへ移動 |
| `Ctrl-q d` | pane を上下分割 |
| `Ctrl-q r` | pane を左右分割 |
| `Ctrl-q h/j/k/l` | pane 移動 |
| `Ctrl-q x` | pane を閉じる |
| `Ctrl-q [` | copy mode |

## タブ

| キー | 機能 |
|---|---|
| `Cmd-t` / `Ctrl-Shift-t` | 現在と同じ domain で新しいタブを作る |
| `Cmd-w` / `Ctrl-Shift-w` | 現在のタブを確認付きで閉じる |
| `Ctrl-Tab` | 次のタブへ移動 |
| `Ctrl-Shift-Tab` | 前のタブへ移動 |
| `Cmd-1` / `Alt-1` | 1 番目のタブへ移動 |
| `Cmd-2` / `Alt-2` | 2 番目のタブへ移動 |
| `Cmd-3` / `Alt-3` | 3 番目のタブへ移動 |
| `Cmd-4` / `Alt-4` | 4 番目のタブへ移動 |
| `Cmd-5` / `Alt-5` | 5 番目のタブへ移動 |
| `Cmd-6` / `Alt-6` | 6 番目のタブへ移動 |
| `Cmd-7` / `Alt-7` | 7 番目のタブへ移動 |
| `Cmd-8` / `Alt-8` | 8 番目のタブへ移動 |
| `Cmd-9` / `Alt-9` | 最後のタブへ移動 |
| `Ctrl-q {` | タブを左へ移動 |
| `Ctrl-q }` | タブを右へ移動 |

## Pane

| キー | 機能 |
|---|---|
| `Ctrl-q d` | pane を上下分割 |
| `Ctrl-q r` | pane を左右分割 |
| `Ctrl-q h` | 左の pane へ移動 |
| `Ctrl-q j` | 下の pane へ移動 |
| `Ctrl-q k` | 上の pane へ移動 |
| `Ctrl-q l` | 右の pane へ移動 |
| `Ctrl-q x` | 現在の pane を確認付きで閉じる |
| `Ctrl-q z` | 現在の pane を zoom / unzoom |
| `Ctrl-Shift-[` | pane 選択 UI |

## Pane サイズ変更

`Ctrl-q s` でサイズ変更モードに入ります。

| キー | 機能 |
|---|---|
| `h` | 左方向へサイズ調整 |
| `j` | 下方向へサイズ調整 |
| `k` | 上方向へサイズ調整 |
| `l` | 右方向へサイズ調整 |
| `Enter` | サイズ変更モード終了 |
| `Escape` | サイズ変更モード終了 |

## Pane 移動モード

`Ctrl-q a` で pane 移動モードに入ります。1 秒だけ有効です。

| キー | 機能 |
|---|---|
| `h` | 左の pane へ移動 |
| `j` | 下の pane へ移動 |
| `k` | 上の pane へ移動 |
| `l` | 右の pane へ移動 |

通常は `Ctrl-q h/j/k/l` だけ覚えれば十分です。

## Workspace / Launch Menu

| キー | 機能 |
|---|---|
| `Ctrl-q w` | workspace 一覧 |
| `Ctrl-q Shift-W` | 新しい workspace 作成 |
| `Ctrl-q $` | 現在の workspace 名を変更 |
| `Ctrl-q Shift-S` | launch menu を表示 |

SSH 接続先を `config/wezterm/ssh_profiles.lua` の `M.hosts` に書くと、`Ctrl-q Shift-S` から起動できます。

## コピー / ペースト

| キー | 機能 |
|---|---|
| `Cmd-c` / `Ctrl-Shift-c` | 選択範囲を clipboard へコピー |
| `Cmd-v` / `Ctrl-Shift-v` | 安全ペースト |
| `Ctrl-Shift-V` | 安全ペースト |
| `Ctrl-q [` | copy mode に入る |

安全ペーストの動き:

| 状態 | 動き |
|---|---|
| 単一行 | そのまま貼り付け |
| 複数行、通常環境 | 1回確認 |
| 複数行、`prod` SSH | 拒否 |

Windows の clipboard は単語だけでも末尾改行を返すことがあるため、安全ペーストでは末尾の改行を取り除きます。
また、Windows の CRLF 改行は LF に揃えます。
中間の改行自体は残すので、複数行ペースト検出はそのまま動きます。

## Copy Mode

`Ctrl-q [` で入ります。Vim 風に移動できます。

| キー | 機能 |
|---|---|
| `h/j/k/l` | 左 / 下 / 上 / 右へ移動 |
| `w` | 次の単語へ移動 |
| `b` | 前の単語へ移動 |
| `e` | 次の単語末尾へ移動 |
| `0` | 行頭へ移動 |
| `^` | 空白を除いた行頭へ移動 |
| `$` | 行末へ移動 |
| `g` | scrollback の一番上へ移動 |
| `G` | scrollback の一番下へ移動 |
| `H` | 表示領域の上へ移動 |
| `M` | 表示領域の中央へ移動 |
| `L` | 表示領域の下へ移動 |
| `Ctrl-b` | 1 ページ上へ移動 |
| `Ctrl-f` | 1 ページ下へ移動 |
| `Ctrl-u` | 半ページ上へ移動 |
| `Ctrl-d` | 半ページ下へ移動 |
| `v` | 文字単位選択 |
| `V` | 行単位選択 |
| `Ctrl-v` | 矩形選択 |
| `y` | clipboard へコピー |
| `Enter` | コピーして copy mode を閉じる |
| `Escape` / `q` / `Ctrl-c` | copy mode を閉じる |

## Jump 操作

copy mode 内で使います。

| キー | 機能 |
|---|---|
| `f` | 指定文字へ前方 jump |
| `t` | 指定文字の直前へ前方 jump |
| `F` | 指定文字へ後方 jump |
| `T` | 指定文字の直後へ後方 jump |
| `;` | 直前の jump を繰り返す |

## コマンド / 設定

| キー | 機能 |
|---|---|
| `Cmd-p` | コマンドパレット |
| `Ctrl-Shift-p` | コマンドパレット |
| `Ctrl-Shift-r` | 設定再読み込み |
| `Alt-Enter` | フルスクリーン切り替え |
| `Ctrl-+` | フォントサイズを大きくする |
| `Ctrl--` | フォントサイズを小さくする |
| `Ctrl-0` | フォントサイズを初期値に戻す |

## SSH 関連機能

WezTerm のキーではなく shell command ですが、この設定の重要機能です。

| コマンド | 機能 |
|---|---|
| `ssh example-host` | zsh では SSH ログ保存 + 背景色/タブ色変更 + 入室時確認 |
| `ssh-log example-host` | SSH ログ保存 + 入室時確認 |
| `ssh-prod example-host` | 本番 profile。背景色変更、右上表示、複数行ペースト拒否 |
| `ssh-staging example-host` | staging profile |
| `ssh-lab example-host` | lab profile。dev と staging の中間の注意度 |
| `ssh-dev example-host` | dev profile |
| `ssh-nolog example-host` | ログ保存なし |
| `ssh-noprobe example-host` | `id && date && uname -n` なし |
| `vagrant ssh` | Vagrant profile。ログ保存 + 背景色/タブ色変更 + 入室時確認 |

zsh では通常の `ssh` と `vagrant ssh` が wrapper 経由です。Vagrant の SSH 以外のコマンドは通常通りです。

## 覚える順番

1. macOS は `Cmd-t` / `Cmd-w`、Windows は `Ctrl-Shift-t` / `Ctrl-Shift-w`、共通で `Ctrl-Tab`
2. `Ctrl-q d/r`、`Ctrl-q h/j/k/l`、`Ctrl-q x`
3. `Ctrl-q [`、`y`、`Enter`、`Escape`
4. macOS は `Cmd-v`、Windows は `Ctrl-Shift-v` の安全ペースト
5. `Ctrl-q Shift-S` の launch menu
6. `Ctrl-q s` の pane サイズ変更

## 現在のキーバインドを確認する

```sh
wezterm show-keys
```

Lua 形式で見る場合:

```sh
wezterm show-keys --lua
```

Windows で設定が反映されているか確認する場合:

```bat
wezterm show-keys | findstr /i "CTRL           T"
wezterm show-keys | findstr /i "CTRL           W"
wezterm show-keys | findstr /i "ALT 1"
```

WezTerm の表示では `Ctrl-Shift-t` が `CTRL T` のように出ます。
これは未反映ではなく、Shift 付き英字が大文字キーとして表示されているだけです。

何も出ない場合は、Windows 側の `%USERPROFILE%\.config\wezterm\keybinds.lua` が古いか、WezTerm が別の config を読んでいます。
