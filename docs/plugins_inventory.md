# zsh プラグイン / 外部ツール整理

このドキュメントは `config/zsh/.zshrc` が扱っている既存のプラグイン、ライブラリ、外部コマンドの棚卸しです。

今の方針は「プラグインマネージャあり/なしを選べる」です。デフォルトは `ZSHRC_PLUGIN_MANAGER=oh-my-zsh` です。Homebrew、Linuxbrew、apt、手動 clone などで入っている外部ツールは、存在する場合だけ有効化します。

導入済みの本体は `config/zsh/.zshrc` です。
手動導入手順は `plugins_install_guide.md`、古い差し込み用の参考 block は `extras/zsh_plugins_config.zsh` に残しています。

## 現在の分類

| 名前 | 種別 | 必須 | 役割 |
| --- | --- | --- | --- |
| `oh-my-zsh` | zsh フレームワーク | 任意 | 内蔵プラグイン群の読み込み |
| `pyenv` | 外部ツール | 任意 | Python バージョン管理 |
| `rbenv` | 外部ツール | 任意 | Ruby バージョン管理 |
| `fzf` | 外部ツール | 任意 | fuzzy finder、履歴/ファイル/ディレクトリ選択 |
| `fzf-tab` | zsh プラグイン | 任意 | Tab 補完候補を fzf UI で選択 |
| `zoxide` | 外部ツール | 任意 | 賢い `cd` |
| `ghq` | 外部ツール | 任意 | リポジトリ一覧から移動 |
| `direnv` | 外部ツール / OMZ plugin | 任意 | ディレクトリごとの環境変数読み込み |
| `atuin` | 外部ツール | 任意 | 履歴 DB / 履歴検索 |
| `terraform` | 外部ツール / OMZ plugin | 任意 | Terraform CLI と補完/alias |
| `vagrant` | 外部ツール / OMZ plugin | 任意 | Vagrant CLI と補完/alias |
| `vagrant-prompt` | OMZ plugin | 任意 | `vagrant_prompt_info` 関数で Vagrant VM 状態を表示 |
| `zsh-abbr` | zsh プラグイン | 任意 | fish 風 abbreviation |
| `zsh-completions` | zsh 補完集 | 任意 | 補完定義を増やす |
| `zsh-autosuggestions` | zsh プラグイン | 任意 | fish 風の入力中サジェスト |
| `zsh-syntax-highlighting` | zsh プラグイン | 任意 | 入力中コマンドの色付け |
| `starship` | 外部プロンプト | 任意 | プロンプト表示、Git/Python/実行時間表示 |
| `dircolors` | 外部ツール | 任意 | Linux/WSL の色設定 |
| `pbcopy` | OS 標準/外部コマンド | 任意 | macOS クリップボード |
| `clip.exe` | WSL/Windows コマンド | 任意 | WSL から Windows クリップボード |
| `wl-copy` | 外部ツール | 任意 | Wayland Linux クリップボード |
| `xclip` | 外部ツール | 任意 | X11 Linux クリップボード |
| `xsel` | 外部ツール | 任意 | X11 Linux クリップボード |

## 読み込み順

現在の `config/zsh/.zshrc` では、だいたい次の順番です。

1. OS / WSL 判定
2. Homebrew / Linuxbrew / `~/.local/bin` の PATH 設定
3. `pyenv`
4. `rbenv`
5. `zsh-completions` の `fpath` 追加
6. zsh 標準設定、履歴、補完、Vim mode、alias、関数
7. `fzf`
8. `zoxide`
9. 色設定、`dircolors`
10. `fzf-tab`
11. Oh My Zsh plugins
12. `zsh-autosuggestions`
13. `zsh-syntax-highlighting`
14. `zsh-abbr`
15. `starship`
16. `~/.zshrc.local`

`pyenv` は PATH や Python バージョンに関係するので早めに初期化します。

`rbenv` も Ruby の shim に関係するため早めに初期化します。

`zsh-completions` は `compinit` より前に `fpath` へ追加します。

`fzf` と `zoxide` は `compinit` より後に読み込みます。`zoxide` は補完のため `compinit` 後が推奨です。

`fzf-tab` は `compinit` より後、`zsh-syntax-highlighting` より前に読み込みます。

Oh My Zsh は `ZSHRC_PLUGIN_MANAGER=oh-my-zsh` かつ `~/.oh-my-zsh/oh-my-zsh.sh` がある場合だけ読み込みます。参考記事に合わせた内蔵プラグインに、`terraform` と `direnv` を加えて有効化します。starship を使うため `ZSH_THEME=""` にしています。

`zsh-autosuggestions` は zle の設定後、`zsh-syntax-highlighting` より前に読み込みます。fish 風の候補表示を担当します。

`zsh-syntax-highlighting` は zle の設定後に読み込みます。キーバインドや補完ウィジェットを定義した後に読むほうが安定します。

`zsh-abbr` は `zsh-syntax-highlighting` の後に読み込みます。略語定義は `~/.zshrc.local` に置く想定です。

`starship` はプロンプト担当です。Git ブランチ、pyenv/Python、コマンド実行時間などは starship 側で設定します。

## pyenv

`~/.pyenv/bin` があれば PATH に追加し、`pyenv` コマンドが見つかった場合だけ初期化します。

```zsh
export PYENV_ROOT="$HOME/.pyenv"
if [ -d "$PYENV_ROOT/bin" ]; then
  export PATH="$PYENV_ROOT/bin:$PATH"
fi

if command -v pyenv >/dev/null 2>&1; then
  eval "$(pyenv init - zsh)"
fi
```

確認コマンド:

```sh
pyenv --version
pyenv versions
```

## rbenv

`rbenv` コマンドが見つかった場合だけ初期化します。

```zsh
if command -v rbenv >/dev/null 2>&1; then
  eval "$(rbenv init - zsh)"
fi
```

確認コマンド:

```sh
rbenv --version
rbenv versions
```

## fzf

`fzf` コマンドが見つかり、かつ `fzf --zsh` が使える場合だけ zsh integration を読み込みます。

```zsh
if command -v fzf >/dev/null 2>&1 && fzf --zsh >/dev/null 2>&1; then
  source <(fzf --zsh)
fi
```

古い `fzf` では静かにスキップします。

## zoxide

`zoxide` コマンドが見つかった場合だけ初期化します。

```zsh
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi
```

## ghq

`ghq-fzf-cd` 関数は常に定義しますが、`ghq` または `fzf` がない場合は実行時にだけエラーを表示します。

## fzf-tab

`~/.zsh/fzf-tab/fzf-tab.plugin.zsh` などがある場合だけ読み込みます。

Tab 補完候補を fzf UI で絞り込めます。

```text
Tab     補完候補を fzf で表示
,       fzf-tab 内で前の group へ移動
.       fzf-tab 内で次の group へ移動
```

## direnv

`direnv` コマンドが見つかった場合だけ初期化します。
`.envrc` は明示的に許可したディレクトリだけ有効です。

```sh
direnv allow
direnv deny
```

## atuin

`atuin` コマンドが見つかった場合だけ初期化します。
既存の `Ctrl-r` と ↑ 履歴操作は維持するため、atuin 側のキーバインドは無効化しています。

```sh
ah   # atuin search
ahi  # atuin import auto
```

## zsh-abbr

`~/.zsh/zsh-abbr/zsh-abbr.zsh` などがある場合だけ読み込みます。
略語定義は `~/.zshrc.local` に置く想定です。

```zsh
abbr gs git status
abbr gc git commit
abbr gco git checkout
```

## Oh My Zsh plugins

`ZSHRC_PLUGIN_MANAGER=oh-my-zsh` かつ `~/.oh-my-zsh/oh-my-zsh.sh` がある場合だけ、以下の内蔵プラグインを読み込みます。

プラグインマネージャなしにしたい環境では、`~/.zshrc.local` に次を書きます。

```zsh
ZSHRC_PLUGIN_MANAGER=none
```

```zsh
plugins=(
  git
  1password
  z
  fzf
  sudo
  history-substring-search
  extract
  colored-man-pages
  command-not-found
  macos
  brew
  docker
  docker-compose
  gh
  terraform
  vagrant
  vagrant-prompt
  direnv
  dotenv
  jsontools
  copypath
  copyfile
  aliases
  safe-paste
  bgnotify
  fancy-ctrl-z
  web-search
  encode64
)
```

`ssh-agent` plugin は 1Password SSH agent と競合しやすいため入れていません。

## zsh-autosuggestions

入力中のコマンドへ fish 風の薄い候補を出すプラグインです。存在するパスを上から順に探し、最初に見つかったものだけ読み込みます。

探索先:

```text
/opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
/usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh
/home/linuxbrew/.linuxbrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
```

操作:

```text
Ctrl-f  サジェストを確定
```

## zsh-syntax-highlighting

入力中のコマンドを色付けするプラグインです。存在するパスを上から順に探し、最初に見つかったものだけ読み込みます。

探索先:

```text
/opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
/usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
/home/linuxbrew/.linuxbrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
/usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
```

確認コマンド例:

```sh
ls /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
ls /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
```

## starship

プロンプト表示の担当です。`starship` コマンドが見つかった場合だけ有効化します。

```zsh
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi
```

確認コマンド:

```sh
starship --version
```

設定ファイルは通常ここです。

```text
~/.config/starship.toml
```

## dircolors

Linux/WSL で `LS_COLORS` を生成するために使います。存在しない場合は固定の `LS_COLORS` に fallback します。

```zsh
if command -v dircolors >/dev/null 2>&1; then
  eval "$(dircolors -b)"
else
  export LS_COLORS='di=34:ln=35:so=32:pi=33:ex=31:bd=46;34:cd=43;34:su=41;30:sg=46;30:tw=42;30:ow=43;30'
fi
```

## クリップボード系

global alias `C` のために使います。

```sh
pwd C
git branch C
```

環境ごとの優先順:

1. `pbcopy`
2. WSL の `clip.exe`
3. `wl-copy`
4. `xclip`
5. `xsel`

## 現時点で入れていないもの

`.zshrc` 側には alias fallback だけ用意しています。
コマンド本体は環境により未導入の場合があります。

- `eza`
- `bat`
- `fd`

入れる場合は `./install.sh --install-tools`、または Homebrew/Linuxbrew/apt で個別に入れます。

`command-not-found` は便利なので有効化しています。
missing command 時の待ち時間が気になる場合は、`plugins=(...)` から外してください。

## 整理方針

設定は次の3層に分けます。

1. zsh 標準機能: `.zshrc` 本体に置く
2. どの環境にも入れたい外部ツール: README にインストール手順を書く
3. 環境ごとの好み: `~/.zshrc.local` に逃がす

これで macOS と WSL の両方を同じ `.zshrc` で運用しやすくなります。
