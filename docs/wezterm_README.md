# WezTerm README

この設定は zsh / fish / bash などの shell から使える WezTerm 設定です。
zsh と Starship を主環境にしつつ、SSH wrapper は `~/bin` の実行ファイルとして置くため、shell に依存しません。

## ファイル

```text
config/wezterm/
  wezterm.lua
  keybinds.lua
  ssh_profiles.lua
```

キーバインドの早見表は `docs/wezterm_KEYBINDINGS.md` にあります。

## できること

- ローカル WezTerm セッションをログ保存
- SSH 接続を profile / host ごとにログ保存
- SSH 接続直後に `id && date && uname -n`
- SSH profile / host を右上に表示
- profile ごとに背景色を変更
- profile ごとにタブ色を変更
- 背景変更時に文字色、ANSI 色、カーソル色、選択色も合わせて変更
- `prod` profile では複数行ペーストを拒否
- `staging` / `dev` / ローカルでは複数行ペーストを1回確認
- zsh では通常の `ssh` も wrapper 経由にする
- `vagrant ssh` は Vagrant 専用 profile 色で wrapper 経由にする
- zsh / fish / bash など、shell に依存しない `ssh-prod` などの実行ファイルを提供
- `UDEV Gothic 35NFLG` を第一候補フォントとして使う

## インストール

```sh
cd zsh_setup
./install.sh --only wezterm
```

実際に変更せず確認:

```sh
./install.sh --only wezterm --dry-run
```

Windows 版 WezTerm を WSL メインで使う場合は、WSL 側から Windows 側の WezTerm config へコピーします。
初回は WezTerm が `cmd.exe` を開くため、そこから導入します。

この設定フォルダが Windows 側にある場合:

```bat
bin\install-wezterm-windows-config.cmd
```

この設定フォルダが WSL 側にある場合:

```sh
wsl -e sh -lc "cd ~/outputs/zsh_setup && sh bin/install-wezterm-windows-config"
```

詳しくは `docs/wsl_wezterm_README.md` を見てください。

## Windows / WSL

Windows 上で WezTerm が動いている場合、この設定は WSL domain を自動検出して `default_domain` にします。
これにより、起動時の既定 shell が `cmd.exe` ではなく WSL になります。
WSL domain では WSL 側の `~/bin/wezterm-login-shell` を優先して起動します。
これによりローカルターミナルログも WSL 側へ保存されます。
wrapper がまだない場合は zsh、zsh もない場合は bash に fallback します。

複数の WSL distro がある場合は、Windows 側で優先 distro を指定できます。

```powershell
setx WEZTERM_WSL_DISTRO Ubuntu
```

SSH ログ保存や背景変更は WSL 側の `.zshrc` と `~/bin/wezterm-ssh-log` が必要です。
Windows 側に WezTerm config を入れた後、WSL 側でも次を実行してください。

```sh
cd outputs/zsh_setup
./install.sh
exec zsh
```

確認:

```sh
command -v wezterm-login-shell
command -v wezterm-ssh-log
type ssh
```

## 基本操作

設定を再読み込み:

```text
Ctrl-Shift-r
```

コマンドパレット:

```text
Cmd-p
Ctrl-Shift-p
```

SSH launch menu:

```text
Ctrl-q Shift-S
```

詳細は `docs/wezterm_KEYBINDINGS.md` を見てください。

## SSH

zsh では通常の `ssh` も wrapper 経由です。
`ssh-prod` などは function ではなく `~/bin` の実行ファイルなので、fish / bash からも同じ名前で使えます。

```sh
ssh example-prod
ssh-prod -- -p 22 alice@example-prod
ssh-staging example-staging
ssh-dev example-dev
```

ログ保存先:

```text
~/.local/share/wezterm/ssh-logs/<profile>/<host>/YYYYMMDD-HHMMSS.log
```

## Vagrant

`vagrant ssh` は WezTerm SSH wrapper 経由にし、通常 SSH とは別の `VAGRANT` profile として扱います。
`vagrant up` / `vagrant status` など SSH 以外の Vagrant コマンドは通常通りです。

```sh
vagrant ssh
```

VM 名を指定する場合:

```sh
vagrant ssh default
```

## 背景色

`ssh` / `ssh-prod` / `ssh-staging` / `ssh-dev` / `ssh-log` / `vagrant ssh` から入った SSH は、WezTerm の右上表示、背景色、タブ色が profile に合わせて変わります。

通常の `ssh host` も、WezTerm が foreground process を `ssh` として検出できる間は generic SSH 色に変えます。
接続先名や本番扱いを確実に出したい場合は `ssh-prod` などを使ってください。

SSH 接続が失敗した時、または SSH から抜けた時は、wrapper が WezTerm の SSH 表示用変数を消します。
これにより背景色と右上表示はローカル状態へ戻ります。

背景色だけを変えると文字が読みにくくなる場合があるため、この設定では profile ごとに次もまとめて変えています。

```text
foreground
cursor_bg
cursor_fg
cursor_border
selection_bg
selection_fg
ansi
brights
```

右上表示は WezTerm のタブバー右端に出ます。
そのため、この設定では 1 タブだけの時もタブバーを表示します。

## Launch Menu

`config/wezterm/ssh_profiles.lua` の `M.hosts` に接続先を書くと、WezTerm の launch menu から起動できます。

```lua
M.hosts = {
  { label = "PROD example-prod", profile = "prod", args = { "-p", "22", "alice@example-prod" }, name = "example-prod" },
}
```

呼び出し:

```text
Ctrl-q Shift-S
```

## 複数行ペースト

`prod`:

```text
拒否
```

`staging` / `dev` / ローカル:

```text
1回確認
```

profile ごとの動きは `config/wezterm/ssh_profiles.lua` で変更できます。
