# WSL WezTerm README

Windows 版 WezTerm を WSL メインで使うための手順です。
目的は、WezTerm 起動時に `cmd.exe` ではなく WSL の zsh 環境を開くことです。

## 仕組み

Windows 版 WezTerm は Windows 側で動くアプリです。
そのため、設定ファイルも WSL 内の `~/.config/wezterm` ではなく、Windows 側の次を読みます。

```text
%USERPROFILE%\.config\wezterm\wezterm.lua
```

この設定では Windows 上で WezTerm が起動した場合だけ、WezTerm の WSL domain を探して `default_domain` に設定します。

```lua
config.default_domain = "WSL:Ubuntu"
```

WSL domain 起動時は、WSL 側の `~/bin/wezterm-login-shell` を優先します。
これによりローカルターミナルログも WSL 側に保存されます。
wrapper がまだ入っていない初回は zsh、zsh もなければ bash に fallback します。

```text
~/bin/wezterm-login-shell がある: ローカルログ保存付き shell
zsh がある: zsh -l
zsh もない: bash -l
```

実際の distro 名は自動検出します。
複数の WSL distro がある場合は、環境変数 `WEZTERM_WSL_DISTRO` で優先 distro を指定できます。

```powershell
setx WEZTERM_WSL_DISTRO Ubuntu
```

## 初回 cmd.exe からの流れ

Windows 版 WezTerm は、まだ設定が入っていない初回起動では `cmd.exe` を開きます。
その `cmd.exe` から Windows 側の WezTerm 設定を配置します。

まず WSL distro を確認します。

```bat
wsl -l -v
```

この設定フォルダが Windows 側にある場合は、`cmd.exe` でそのフォルダへ移動して実行します。

```bat
cd path\to\outputs\zsh_setup
bin\install-wezterm-windows-config.cmd
```

この設定フォルダが WSL 側にある場合は、`cmd.exe` から WSL に実行させます。
`~/outputs/zsh_setup` の部分は実際の配置場所に合わせます。

```bat
wsl -e sh -lc "cd ~/outputs/zsh_setup && sh bin/install-wezterm-windows-config"
```

使う distro を固定したい場合:

```bat
setx WEZTERM_WSL_DISTRO Ubuntu
```

最後に WezTerm を完全に再起動します。
次回起動から `cmd.exe` ではなく WSL が開きます。

## WSL 側の zsh 環境を入れる

WSL の中で実行します。

```sh
cd outputs/zsh_setup
./install.sh --install-tools
exec zsh
```

`--install-tools` は WSL 上の zsh 関連ツールに加えて、Windows 側の `%USERPROFILE%\bin` に `win32yank.exe` も入れます。
Windows 版 WezTerm の安全ペーストは `win32yank.exe` を優先して clipboard を読むため、PowerShell fallback より軽くなります。
WezTerm Lua から見える PATH と WSL/shell から見える PATH は違うことがあるため、設定側では `%USERPROFILE%\bin\win32yank.exe` のフルパスも試します。

設定だけ入れる場合:

```sh
./install.sh
```

SSH の背景変更、タブ色、右上表示、ログ保存は WSL 側の `.zshrc` と `~/bin/wezterm-ssh-log` に依存します。
そのため、Windows 側の WezTerm config だけでなく、WSL 側でも `./install.sh` を実行してください。

## Windows 側の WezTerm config を入れる

WSL の中で実行します。

```sh
cd outputs/zsh_setup
sh bin/install-wezterm-windows-config
```

Windows 側にこの設定フォルダを置いている場合は、`cmd.exe` から次でも入れられます。

```bat
bin\install-wezterm-windows-config.cmd
```

この script は `config/wezterm/*.lua` を Windows 側の次へコピーします。

```text
%USERPROFILE%\.config\wezterm\
```

その後、Windows 版 WezTerm で設定を再読み込みします。

```text
Ctrl-Shift-r
```

または WezTerm を再起動してください。

## 複数 distro がある場合

Windows PowerShell で distro 名を確認します。

```powershell
wsl -l -v
```

使いたい distro を固定します。

```powershell
setx WEZTERM_WSL_DISTRO Ubuntu
```

WezTerm を完全に再起動すると反映されます。

## 動作確認

WezTerm の新規ウィンドウを開きます。
期待値は次です。

```text
cmd.exe ではなく WSL が開く
zsh / starship のプロンプトが出る
Cmd-t / Ctrl-q で作る新規タブも WSL domain で開く
```

WezTerm の launch menu には WSL domain と Windows PowerShell / cmd.exe を出します。
Windows shell を使いたい時だけ menu から選びます。

## SSH の考え方

SSH wrapper やログ保存は WSL 側の `~/bin` に入ります。
そのため SSH は Windows 側ではなく、WSL タブの中から実行します。

```sh
ssh example
ssh-prod example
ssh-lab example
slog
```

Windows 側の launch menu から SSH を直接起動するより、WSL を開いてから SSH する方が path、key、config、log の扱いが揃います。

WSL タブで次を確認できます。

```sh
echo "$SHELL"
command -v zsh
command -v wezterm-ssh-log
command -v wezterm-login-shell
type ssh
echo "$WEZTERM_PANE"
```

期待値:

```text
zsh が使われている
wezterm-ssh-log が見つかる
wezterm-login-shell が見つかる
ssh is a shell function と表示される
WEZTERM_PANE は環境によって空の場合がある
```

この状態で `ssh host` すると、ログ保存と WezTerm の SSH 表示用 user var が動きます。
`WEZTERM_PANE` が空でも、wrapper は OSC user var を送るため、Windows 側 WezTerm Lua が読み込まれていれば背景色とタブ色は変わります。
ログは WSL 側の次に保存されます。

```text
~/.local/share/wezterm/ssh-logs/
```

ローカルターミナルログは WSL 側の次に保存されます。

```text
~/.local/share/wezterm/session-logs/
```

## トラブルシュート

まだ `cmd.exe` が開く:

```powershell
wsl -l -v
```

で distro が存在するか確認します。
その後、Windows 側に設定がコピーされているか確認します。

```powershell
dir $env:USERPROFILE\.config\wezterm
```

設定をコピーし直す:

```sh
cd outputs/zsh_setup
sh bin/install-wezterm-windows-config
```

初回の `cmd.exe` からコピーし直す:

```bat
cd path\to\outputs\zsh_setup
bin\install-wezterm-windows-config.cmd
```

Windows 側の WezTerm が本当に新しい keybinds を読んでいるか確認:

```bat
wezterm show-keys | findstr /i "CTRL           C"
wezterm show-keys | findstr /i "CTRL           V"
wezterm show-keys | findstr /i "CTRL           T"
wezterm show-keys | findstr /i "CTRL           1"
wezterm show-keys | findstr /i "ALT T"
wezterm show-keys | findstr /i "ALT W"
wezterm show-keys | findstr /i "ALT 1"
```

Windows では Caps Lock=Ctrl 運用に合わせ、`Ctrl-c` / `Ctrl-v` / `Ctrl-t` を優先して使います。
`Ctrl-c` は選択範囲がある時だけコピーし、選択がない時は shell へ中断を送ります。
タブ移動は `Ctrl-1..9` と `Alt-1..9` の両方で使えます。
Alt-ime-ahk が Alt+キーを pass-through する前提で、`Alt-t` / `Alt-w` なども補助として使えます。
`Ctrl-Shift-t` / `Ctrl-Shift-w` も保険として残しています。

何も出ない場合は、WezTerm が別の設定ディレクトリを読んでいるか、コピー先が違います。
Windows 側の実体を確認してください。

```bat
dir "%USERPROFILE%\.config\wezterm"
findstr /n "Alt-t" "%USERPROFILE%\.config\wezterm\keybinds.lua"
```

WezTerm を完全に終了して再起動してください。

SSH の背景色やログ保存が動かない:

```sh
cd outputs/zsh_setup
./install.sh
exec zsh
command -v wezterm-ssh-log
command -v wezterm-login-shell
type ssh
echo "$WEZTERM_PANE"
```

`type ssh` が `ssh is a shell function` にならない場合は、zsh ではなく bash が起動しているか、`.zshrc` が入っていません。
`wezterm-login-shell` が見つからない場合は、WSL 側で `./install.sh` が完了していないため、ローカルターミナルログは保存されません。
`WEZTERM_PANE` は WSL domain では空の場合があります。背景色が変わらない時は、Windows 側の `%USERPROFILE%\.config\wezterm\*.lua` が更新されているか、WezTerm を完全に再起動したかを確認してください。

別 distro を使いたい:

```powershell
setx WEZTERM_WSL_DISTRO Debian
```

`WEZTERM_WSL_DISTRO` は `Ubuntu` のような distro 名だけでも、`WSL:Ubuntu` のような domain 名でも指定できます。
