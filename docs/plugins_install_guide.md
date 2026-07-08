# zsh プラグイン導入手順

この手順は `config/zsh/.zshrc` に外部ツール/プラグインを足すためのものです。

対象:

- macOS
- Windows WSL、主に Ubuntu
- Linuxbrew を入れている Linux/WSL

## 方針

プラグインマネージャあり/なしを選べるようにします。
デフォルトは `ZSHRC_PLUGIN_MANAGER=oh-my-zsh` です。
Oh My Zsh の内蔵プラグインをまとめて使うため、Oh My Zsh 本体を `~/.oh-my-zsh` に clone します。

理由:

- macOS と WSL で同じ `.zshrc` を使いやすい
- プラグインマネージャを使う環境と使わない環境を `ZSHRC_PLUGIN_MANAGER` で切り替えられる
- Homebrew / Linuxbrew / apt で入ったものを検出して使える
- どのプラグインが何をしているか追いやすい
- 公式 installer で `.zshrc` を上書きしない

## 入れる候補

| 名前 | 優先度 | 役割 |
| --- | --- | --- |
| `oh-my-zsh` | 高 | 内蔵プラグイン群 |
| `zsh-syntax-highlighting` | 高 | 入力中のコマンド色付け |
| `zsh-autosuggestions` | 高 | 履歴ベースの候補表示 |
| `fzf-tab` | 高 | Tab 補完候補を fzf UI で選択 |
| `zsh-completions` | 中 | 補完定義を増やす |
| `fzf` | 高 | fuzzy finder、履歴/ファイル選択 |
| `zoxide` | 高 | 賢い `cd` |
| `direnv` | 高 | ディレクトリごとの環境変数読み込み |
| `atuin` | 高 | 履歴 DB / 履歴検索 |
| `zsh-abbr` | 高 | fish 風 abbreviation |
| `ripgrep` | 高 | 高速 grep、fzf の候補生成にも使う |
| `terraform` | 中 | Terraform CLI / 補完 |
| `vagrant` | 中 | Vagrant CLI / 補完 |
| `vagrant-prompt` | 中 | Vagrant VM 状態表示関数 |
| `fd` | 中 | 高速 find |
| `eza` | 中 | 見やすい ls |
| `bat` | 中 | 見やすい cat/less |
| `starship` | 別枠 | プロンプト表示 |
| `pyenv` | 別枠 | Python バージョン管理 |

## macOS: Homebrew

まず Homebrew が使えることを確認します。

```sh
brew --version
```

おすすめ全部入り:

```sh
brew install \
  zsh-syntax-highlighting \
  zsh-autosuggestions \
  zsh-completions \
  fzf \
  zoxide \
  ripgrep \
  fd \
  eza \
  bat \
  starship \
  pyenv \
  direnv \
  atuin \
  hashicorp/tap/terraform
```

Oh My Zsh:

```sh
git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git ~/.oh-my-zsh
mkdir -p ~/.zsh
git clone --depth=1 https://github.com/Aloxaf/fzf-tab ~/.zsh/fzf-tab
git clone --depth=1 --recurse-submodules --shallow-submodules https://github.com/olets/zsh-abbr ~/.zsh/zsh-abbr
```

最小セット:

```sh
brew install \
  zsh-syntax-highlighting \
  zsh-autosuggestions \
  fzf \
  zoxide \
  ripgrep \
  starship \
  pyenv \
  direnv \
  atuin \
  hashicorp/tap/terraform
```

## WSL/Ubuntu: apt 中心

まず zsh と基本ツールを入れます。

```sh
sudo apt update
sudo apt install -y \
  zsh \
  git \
  curl \
  ca-certificates \
  zsh-syntax-highlighting \
  zsh-autosuggestions \
  direnv \
  fzf \
  ripgrep \
  fd-find \
  bat \
  xclip \
  xsel
```

`atuin` と Terraform は apt で揃えにくいことがあります。
WSL でも Linuxbrew を使うと macOS と近い手順にできます。

Oh My Zsh:

```sh
git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git ~/.oh-my-zsh
mkdir -p ~/.zsh
git clone --depth=1 https://github.com/Aloxaf/fzf-tab ~/.zsh/fzf-tab
git clone --depth=1 --recurse-submodules --shallow-submodules https://github.com/olets/zsh-abbr ~/.zsh/zsh-abbr
```

Ubuntu/Debian では `fd` と `bat` のコマンド名が違うことがあります。

```sh
fdfind --version
batcat --version
```

`config/zsh/.zshrc` 側では `fdfind` を `fd`、`batcat` を `bat` として扱う alias を用意できます。

## WSL/Ubuntu: Linuxbrew を使う場合

Linuxbrew が使えるなら macOS とほぼ同じです。

```sh
brew install \
  zsh-syntax-highlighting \
  zsh-autosuggestions \
  zsh-completions \
  fzf \
  zoxide \
  ripgrep \
  fd \
  eza \
  bat \
  starship \
  pyenv \
  direnv \
  atuin \
  hashicorp/tap/terraform
```

Oh My Zsh:

```sh
git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git ~/.oh-my-zsh
mkdir -p ~/.zsh
git clone --depth=1 https://github.com/Aloxaf/fzf-tab ~/.zsh/fzf-tab
git clone --depth=1 --recurse-submodules --shallow-submodules https://github.com/olets/zsh-abbr ~/.zsh/zsh-abbr
```

## Oh My Zsh plugins

記事に合わせて、`.zshrc` では以下の内蔵プラグインを有効化します。

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
`command-not-found` plugin は便利なので有効化しています。missing command 時の待ち時間が気になる場合は、`plugins=(...)` から外してください。

## zoxide

Homebrew なら:

```sh
brew install zoxide
```

Linuxbrew でも同じです。

```sh
brew install zoxide
```

apt の zoxide はディストリビューションによって古かったり存在しなかったりするため、WSL/Ubuntu では Homebrew/Linuxbrew または公式 install script を使う方が揃えやすいです。

```sh
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
```

`.zshrc` 側ではこれを使います。

```zsh
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi
```

## fzf

Homebrew:

```sh
brew install fzf
```

Ubuntu:

```sh
sudo apt install -y fzf
```

公式の zsh integration は次です。

```zsh
if command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh)
fi
```

古い fzf で `fzf --zsh` が使えない場合は、パッケージ側の shell script を source する方式に切り替えます。

## zsh-autosuggestions

Homebrew:

```sh
brew install zsh-autosuggestions
```

Ubuntu:

```sh
sudo apt install -y zsh-autosuggestions
```

手動 clone:

```sh
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
```

`.zshrc` 側では存在する場所だけ source します。

## zsh-syntax-highlighting

Homebrew:

```sh
brew install zsh-syntax-highlighting
```

Ubuntu:

```sh
sudo apt install -y zsh-syntax-highlighting
```

手動 clone:

```sh
git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.zsh/zsh-syntax-highlighting
```

これは `.zshrc` のなるべく最後に読み込みます。ZLE widget や `compinit` より後に置くのが大事です。

## zsh-completions

Homebrew:

```sh
brew install zsh-completions
```

手動 clone:

```sh
git clone https://github.com/zsh-users/zsh-completions ~/.zsh/zsh-completions
```

`zsh-completions` は `compinit` より前に `fpath` へ追加します。

```zsh
fpath=("$HOME/.zsh/zsh-completions/src" $fpath)
autoload -Uz compinit
compinit
```

## starship

Homebrew:

```sh
brew install starship
```

公式 install script:

```sh
curl -sS https://starship.rs/install.sh | sh
```

`.zshrc`:

```zsh
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi
```

## pyenv

Homebrew:

```sh
brew install pyenv
```

`.zshrc`:

```zsh
export PYENV_ROOT="$HOME/.pyenv"
if [ -d "$PYENV_ROOT/bin" ]; then
  export PATH="$PYENV_ROOT/bin:$PATH"
fi

if command -v pyenv >/dev/null 2>&1; then
  eval "$(pyenv init - zsh)"
fi
```

## config の扱い

現在の完成版は `config/zsh/.zshrc` に統合済みです。
通常は `install.sh` で `.zshrc` を入れ替えれば十分です。

`extras/zsh_plugins_config.zsh` は、昔の `.zshrc` に一部だけ取り込みたい時の参考 block です。
そのまま丸ごと貼るより、必要な block だけ読む用途にしてください。

入れる場所:

1. `zsh-completions` ブロック: `autoload -Uz compinit` より前
2. `fzf` / `zoxide` / `direnv` / `atuin` / `fzf-tab` ブロック: `compinit` より後
3. `Oh My Zsh` block: `ZSHRC_PLUGIN_MANAGER=oh-my-zsh` の場合だけ
4. `zsh-autosuggestions` block: zle 設定後
5. `zsh-syntax-highlighting` block: `.zshrc` のかなり最後、`starship` より前
6. `zsh-abbr` block: syntax highlighting 後

## 動作確認

```sh
zsh -n ~/.zshrc
exec zsh
```

各ツール:

```sh
pyenv --version
starship --version
fzf --version
zoxide --version
rg --version
fd --version || fdfind --version
bat --version || batcat --version
```

zsh プラグインは新しいシェルで体感確認します。

- `zsh-syntax-highlighting`: 入力中のコマンドに色が付く
- `zsh-autosuggestions`: 過去コマンドが薄く表示される
- `fzf`: `Ctrl-r` で zsh / fish / bash 履歴検索
- `fzf-tab`: `Tab` で補完候補を fzf 表示
- `zoxide`: `z <dir>` で過去に行った場所へ移動
- `atuin`: `ah` で履歴 DB 検索
- `zsh-abbr`: `abbr` で略語を登録
- `terraform`: `terraform version`

## トラブルシュート

補完がおかしい場合:

```sh
rm -f ~/.cache/zsh/zcompdump*
exec zsh
```

`fzf --zsh` が失敗する場合:

```sh
fzf --version
```

古い fzf の可能性があります。Homebrew/Linuxbrew 版に寄せると揃えやすいです。

`zsh-syntax-highlighting` が効かない場合は、読み込み位置を `.zshrc` の後ろへ移動します。

`zsh-autosuggestions` が見えにくい場合は色を変えます。

```zsh
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=244'
```

## このリポジトリでの推奨

通常は次の順番で使います。

```sh
./install.sh --dry-run
./install.sh
./install.sh --install-tools
```

WSL で実行した場合は、Windows 版 WezTerm 用に `%USERPROFILE%\bin\win32yank.exe` も導入します。
WezTerm の安全ペーストは `win32yank.exe` を優先し、未導入なら PowerShell `Get-Clipboard` に fallback します。

マシン固有の上書きは `~/.zshrc.local` に置きます。
たとえば Oh My Zsh を使わない環境では次を書きます。

```zsh
ZSHRC_PLUGIN_MANAGER=none
```
