# Starship 設定 README

この README は `starship.toml` の使い方メモです。

この設定は macOS / WSL / Linux 共通で使う想定です。fish の bobthefish で見ていた情報を、zsh + Starship + Nerd Font で再現しやすいように整理しています。

## ファイル

- `config/starship/starship.toml`: Starship 本体の設定
- `config/zsh/.zshrc`: `starship init zsh` を呼ぶ zsh 設定

Starship の標準設定ファイル場所は以下です。

```sh
~/.config/starship.toml
```

公式ドキュメントでも、設定は `~/.config/starship.toml` に置く形が基本です。別の場所を使いたい場合は `STARSHIP_CONFIG` を設定できます。

## 導入

macOS / Linuxbrew:

```sh
brew install starship
```

Linux / WSL で公式 install script を使う場合:

```sh
curl -sS https://starship.rs/install.sh | sh
```

設定ファイルを配置します。

```sh
mkdir -p ~/.config
cp config/starship/starship.toml ~/.config/starship.toml
```

`config/zsh/.zshrc` にはすでに以下が入っています。

```zsh
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi
```

`starship` が入っていない環境では何もしないので、エラーにはなりません。

## 全体方針

2行プロンプトです。`UDEV Gothic 35NFLG` のような Nerd Font 対応フォントを前提に、左側は色付きブロックで表示します。

1行目:

```text
user host directory git runtime infra duration
```

2行目:

```text
prompt character
```

1行目:

```text
date time
```

時刻は Starship の通常セグメントとして表示します。
これは現在時刻を見るためではなく、ログを見返した時に「そのプロンプトが出た時刻」を追うためです。
右プロンプトや `fill` は resize 後に崩れやすいため使いません。

## 有効/無効の方針

設定ブロックは多めに入れています。

デフォルトで有効:

- `directory`
- `git_branch`
- `git_status`
- `git_state`
- `python`
- `ruby`
- `golang`
- `nodejs`
- `rust`
- `java`
- `php`
- `swift`
- `dotnet`
- `lua`
- `deno`
- `bun`
- `zig`
- `kotlin`
- `cmake`
- `docker_context`
- `direnv`
- `container`
- `nix_shell`
- `cmd_duration`
- `jobs`
- `status`
- `time`
- `battery`

設定は入れているがデフォルト無効:

- `package`
- `kubernetes`
- `aws`
- `gcloud`
- `azure`
- `terraform`
- `sudo`
- `localip`
- `memory_usage`
- `os`
- `shell`

無効にしているものは、環境依存が強い、表示がうるさくなりやすい、または必要な人が限られるものです。使いたくなったら該当ブロックの `disabled = true` を `disabled = false` に変えます。

## 表示するもの

### Directory

現在ディレクトリを表示します。

```toml
[directory]
truncation_length = 4
fish_style_pwd_dir_length = 1
```

`fish_style_pwd_dir_length = 1` にしているので、長いパスは fish っぽく短縮されます。

### Git

ブランチと状態を表示します。

```text
 main +1 !2 ?3
```

表示対象:

- branch
- staged
- modified
- untracked
- deleted
- renamed
- stashed
- ahead / behind
- rebase / merge などの state

### Python / pyenv

Python プロジェクトでは Python バージョンを表示します。

```text
py:3.12.0
```

仮想環境があれば併記します。

```text
py:3.12.0 venv
```

`pyenv_version_name = true` を有効にしています。
ただし、重くなりやすいため Python プロジェクトではない場所での `pyenv version-name` 常時表示はしていません。

### Ruby / rbenv

Ruby プロジェクトでは Ruby バージョンを表示します。

```text
rb:3.3.0
```

検出対象:

- `Gemfile`
- `.ruby-version`
- `*.rb`

### Go

Go プロジェクトでは Go バージョンを表示します。

```text
go:1.22.0
```

検出対象:

- `go.mod`
- `go.sum`
- `*.go`

### Node.js

Node.js / TypeScript プロジェクトでは Node バージョンを表示します。

```text
node:22.0.0
```

検出対象:

- `package.json`
- `.node-version`
- `.nvmrc`
- `*.js`
- `*.ts`

### Other Languages

以下の language module も設定済みです。該当するプロジェクトに入った時だけ表示されるため、デフォルト有効にしています。

- Rust: `rs:...`
- Java: `java:...`
- PHP: `php:...`
- Swift: `swift:...`
- .NET: `dotnet:...`
- Lua: `lua:...`
- Deno: `deno:...`
- Bun: `bun:...`
- Zig: `zig:...`
- Kotlin: `kt:...`
- CMake: `cmake:...`

### Package

`package.json` などからパッケージバージョンを表示します。

```text
pkg:1.2.3
```

デフォルトでは無効です。うるさくなければ `[package] disabled = false` にします。

### Docker

Docker 関連ファイルがある場合に Docker context を表示します。

```text
docker:desktop-linux
```

### Kubernetes

Kubernetes context / namespace を表示します。

```text
k8s:dev/default
```

デフォルトでは無効です。使う場合は以下にします。

```toml
[kubernetes]
disabled = false
```

### AWS

AWS profile / region を表示します。

```text
aws:my-profile/ap-northeast-1
```

デフォルトでは無効です。使う場合は以下にします。

```toml
[aws]
disabled = false
```

### Cloud / IaC

以下も設定ブロックだけ用意しています。デフォルトでは無効です。

- Google Cloud: `gcloud`
- Azure: `azure`
- Terraform: `terraform`

有効化例:

```toml
[terraform]
disabled = false
```

### Nix

Nix shell に入っている場合に表示します。

```text
nix:pure
```

### Command Duration

100ms 以上かかったコマンドの実行時間を表示します。

```text
took 153ms
took 2.3s
```

fish / bobthefish の command duration 相当です。

### Time / Battery

1行目に時刻を表示します。
ログを見返した時に、そのコマンド周辺の時刻を追いやすくするためです。

```text
10:30 bat:42%
```

バッテリーは 50% 以下、20% 以下で色が変わります。

## Vim Mode

zsh 側で Vim mode を使っているため、Starship の `character` も mode ごとに変えています。

```text
❯ insert mode / normal success
❮ command mode
```

色:

- 成功: green
- エラー: red
- command mode: yellow
- visual mode: cyan

## 色

独自 palette `main` を使っています。

```toml
palette = "main"
```

落ち着いた色だけにして、macOS / WSL / Linux のどのターミナルでも破綻しにくい方向です。

## 好みに応じて切る候補

この設定では、うるさそうなものは最初から無効化しています。

有効化候補:

```toml
[kubernetes]
disabled = false

[aws]
disabled = false

[gcloud]
disabled = false

[azure]
disabled = false

[terraform]
disabled = false

[package]
disabled = false
```

Kubernetes が重い/不要:

```toml
[kubernetes]
disabled = true
```

AWS が不要:

```toml
[aws]
disabled = true
```

package version がうるさい:

```toml
[package]
disabled = true
```

時刻が不要:

```toml
[time]
disabled = true
```

バッテリー表示が不要:

```toml
[battery]
disabled = true
```

コマンド実行時間をもっと細かく出したい:

```toml
[cmd_duration]
min_time = 0
```

逆に長いコマンドだけでよい:

```toml
[cmd_duration]
min_time = 1000
```

## 動作確認

```sh
starship --version
starship explain
starship prompt
```

`starship explain` は、今表示されている各 module の理由を見るのに便利です。

設定の読み込み場所を変えたい場合:

```sh
export STARSHIP_CONFIG="$HOME/.config/starship.toml"
```

## zshrc との関係

`config/zsh/.zshrc` 側では以下を担当します。

- PATH
- pyenv
- rbenv
- fzf
- zoxide
- ghq-fzf-cd
- Vim mode
- 補完
- alias / 関数

`starship.toml` 側では以下を担当します。

- Git branch/status
- pyenv/Python 表示
- rbenv/Ruby 表示
- Go / Node 表示
- command duration
- time / battery
- AWS / Kubernetes / Docker / Nix

役割を分けておくと、zsh の挙動とプロンプトの見た目を独立して調整できます。

## 参照

- [Starship Configuration](https://starship.rs/config/)
- [Starship Guide](https://starship.rs/guide/)
