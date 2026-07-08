# zsh setup

macOS / WSL / Linux で共通利用するための zsh + Vim + Starship + WezTerm 設定です。

fish で便利だった見た目、履歴、サジェスト、移動補助を zsh に寄せつつ、SSH は WezTerm 連携で安全に扱う方針です。

## 構成

```text
zsh_setup/
  install.sh
  config/
    zsh/.zshrc
    vim/.vimrc
    starship/starship.toml
    wezterm/
      wezterm.lua
      keybinds.lua
      ssh_profiles.lua
  bin/
    ssh-log
    ssh-prod
    ssh-staging
    ssh-lab
    ssh-dev
    ssh-nolog
    ssh-noprobe
    wezterm-login-shell
    wezterm-ssh-log
    cleanup-install-backups
    install-wezterm-windows-config
    install-wezterm-windows-config.cmd
  docs/
    zshrc_README.md
    vim_README.md
    starship_README.md
    wezterm_README.md
    wsl_wezterm_README.md
    wezterm_KEYBINDINGS.md
    plugins_inventory.md
    plugins_install_guide.md
    ssh_README.md
  extras/
    zsh_plugins_config.zsh
```

`config/` は実際にインストールされる完成版、`docs/` は使い方、`extras/` は昔の `.zshrc` に部分移植したい時の参考資料です。

## インストール

設定ファイルだけ入れる:

```sh
cd zsh_setup
./install.sh
```

推奨ツールも入れる:

```sh
./install.sh --install-tools
```

WSL で `--install-tools` を使うと、Windows 版 WezTerm の安全ペースト高速化用に `win32yank.exe` も Windows 側の `%USERPROFILE%\bin` へ入れます。

確認なしで上書き:

```sh
./install.sh --force
```

実際には変更せず確認:

```sh
./install.sh --dry-run
```

対象を絞る:

```sh
./install.sh --only zsh
./install.sh --only vim
./install.sh --only starship
./install.sh --only wezterm
```

`--install-tools` は Homebrew / Linuxbrew があれば `brew`、なければ `apt` を使います。Oh My Zsh は公式 installer ではなく `git clone` だけで入れるため、既存の `.zshrc` を勝手に置き換えません。

## インストールされるもの

```text
config/zsh/.zshrc             -> ~/.zshrc
config/vim/.vimrc             -> ~/.vimrc
config/starship/starship.toml -> ~/.config/starship.toml
config/wezterm/*.lua          -> ~/.config/wezterm/*.lua
bin/wezterm-login-shell       -> ~/bin/wezterm-login-shell
bin/wezterm-ssh-log           -> ~/bin/wezterm-ssh-log
bin/cleanup-install-backups   -> ~/bin/cleanup-install-backups
bin/ssh-*                     -> ~/bin/ssh-*
```

既存ファイルは上書き前にバックアップします。

```text
~/.zshrc.backup.YYYYMMDD-HHMMSS
~/.vimrc.backup.YYYYMMDD-HHMMSS
~/.config/starship.toml.backup.YYYYMMDD-HHMMSS
```

開発中にバックアップが増えすぎた場合は、対象を確認してから削除できます。

```sh
cleanup-install-backups
cleanup-install-backups --force
```

## 初回確認

```sh
exec zsh
zsh -n ~/.zshrc
starship --version
```

WezTerm は設定を再読み込みします。

```text
Ctrl-Shift-r
```

Windows 版 WezTerm を WSL メインで使う場合は、Windows 側にも WezTerm config を入れます。
初回は WezTerm が `cmd.exe` で開くため、そこから次のどちらかを実行します。

Windows 側にこのフォルダがある場合:

```bat
bin\install-wezterm-windows-config.cmd
```

WSL 側にこのフォルダがある場合:

```sh
wsl -e sh -lc "cd ~/outputs/zsh_setup && sh bin/install-wezterm-windows-config"
```

詳細は `docs/wsl_wezterm_README.md` を見てください。

## プラグイン方針

プラグインマネージャは選択式です。

```zsh
# デフォルト。Oh My Zsh plugins を使う
ZSHRC_PLUGIN_MANAGER=oh-my-zsh

# プラグインマネージャなし
ZSHRC_PLUGIN_MANAGER=none
```

マシン固有の変更は `~/.zshrc.local` に書きます。

主な有効化対象:

- Oh My Zsh plugins: `git`, `1password`, `fzf`, `sudo`, `history-substring-search`, `extract`, `colored-man-pages`, `command-not-found`, `macos`, `brew`, `docker`, `docker-compose`, `gh`, `terraform`, `vagrant`, `vagrant-prompt`, `direnv`, `dotenv`, `jsontools`, `copypath`, `copyfile`, `aliases`, `safe-paste`, `bgnotify`, `fancy-ctrl-z`, `web-search`, `encode64`
- zsh plugins: `zsh-autosuggestions`, `zsh-syntax-highlighting`, `fzf-tab`, `zsh-abbr`
- tools: `fzf`, `zoxide`, `ghq`, `direnv`, `atuin`, `pyenv`, `rbenv`, `starship`

外部 plugin や command が入っていなくても起動エラーにならないよう guard しています。

## よく使う操作

Vim:

```text
Esc Esc  検索結果のハイライトを消す
:grep    grep 後に quickfix window を開く
vim -b   xxd バイナリ編集モード
```

詳しくは [vim_README.md](docs/vim_README.md) を見てください。

履歴:

```text
Ctrl-r  zsh / fish / bash 履歴をまとめて fzf 検索
Ctrl-p  入力中の文字列から始まる履歴を上方向に検索
Ctrl-n  入力中の文字列から始まる履歴を下方向に検索
```

補完:

```text
Tab     autosuggestion 表示中は候補確定。候補がない時は補完/fzf-tab
,       fzf-tab で前の group
.       fzf-tab で次の group
Ctrl-f  autosuggestion を確定
```

移動:

```sh
z project
zi project
bd src
croot
mkcd new-project
cdh
```

ghq:

```text
Ctrl-]  ghq + fzf で repo 移動
```

ファイル:

```text
Ctrl-G  fzf でファイルを選んでコマンドラインへ挿入
Ctrl-O  fzf でファイルを選んで Vim で開く
```

## SSH / Vagrant

zsh では通常の `ssh` も wrapper 経由にします。
これにより `ssh host` だけでログ保存、WezTerm 背景色、タブ色、右上表示、複数行ペースト制御が動きます。

`vagrant ssh` も wrapper 経由にしますが、通常 SSH とは別の `vagrant` profile 色にします。
`vagrant up` / `vagrant status` など SSH 以外の Vagrant コマンドは通常通りです。

```sh
ssh example-prod
ssh-log example-prod
ssh-prod example-prod
ssh-staging example-staging
ssh-lab example-lab
ssh-dev example-dev
ssh-nolog example-dev
ssh-noprobe example-dev
vagrant ssh
```

Host 名が `prod-*` / `*-prod` / `*.prod` などに一致する場合、通常の `ssh host` でも自動で `prod` profile になります。
`lab-*` / `*-lab` / `*.lab` は `lab` profile になり、`dev` と `staging` の中間の注意度として扱います。

ログ保存先:

```text
~/.local/share/wezterm/ssh-logs/<profile>/<host>/YYYYMMDD-HHMMSS.log
```

ログ閲覧:

```sh
slog        # 最新ログを less -R で見る
slog-clean  # 最新ログから ANSI 制御コードを剥がして見る
```

`~/.ssh/config` に `RemoteCommand` がある Host では、`id && date && uname -n` は自動スキップします。

Vagrant の状態確認:

```sh
vs   # vagrant status
vgs  # vagrant global-status --prune
```

## WezTerm

主な機能:

- `UDEV Gothic 35NFLG` を第一候補フォントにする
- 初期ウィンドウサイズを大きめにする
- `Ctrl-q` leader key
- SSH profile ごとに背景色、タブ色、右上表示、安全ペースト制御
- prod SSH では複数行ペーストを拒否
- 1 タブ時もタブバーを表示し、右上ステータスを常時見えるようにする

キーバインドは [wezterm_KEYBINDINGS.md](docs/wezterm_KEYBINDINGS.md) を見てください。

## Starship

Starship は prompt 表示担当です。

- directory
- git branch/status
- command duration
- time: コマンドログ上で実行時刻を追えるよう通常セグメントとして表示
- pyenv/rbenv など runtime
- direnv
- terraform

詳しくは [starship_README.md](docs/starship_README.md) を見てください。

## 重い・邪魔な時

`command-not-found` は便利ですが、存在しない command を打った時に数秒待つ場合があります。気になる場合は `.zshrc` の `plugins=(...)` から外します。

`magic-enter` は空 Enter で `ls` や `git status` が走るため、現在は無効です。

`compinit` は補完の土台なので消しません。Oh My Zsh が初期化済みなら `.zshrc` 側では二重実行しないようにしています。

## ドキュメント

- [zshrc_README.md](docs/zshrc_README.md): zsh の使い方
- [vim_README.md](docs/vim_README.md): Vim 設定
- [starship_README.md](docs/starship_README.md): Starship 設定
- [wezterm_README.md](docs/wezterm_README.md): WezTerm 設定
- [wezterm_KEYBINDINGS.md](docs/wezterm_KEYBINDINGS.md): WezTerm キーバインド早見表
- [plugins_inventory.md](docs/plugins_inventory.md): plugin / tool 棚卸し
- [plugins_install_guide.md](docs/plugins_install_guide.md): 手動導入手順
- [ssh_README.md](docs/ssh_README.md): SSH wrapper 運用

`extras/zsh_plugins_config.zsh` は完成版ではなく参考 block です。通常は `install.sh` と `config/zsh/.zshrc` を使ってください。
