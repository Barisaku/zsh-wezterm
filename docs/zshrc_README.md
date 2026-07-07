# zsh 設定 README

この README は `config/zsh/.zshrc` の使い方メモです。

この設定は macOS / WSL / Linux の共通利用を想定しています。プロンプトの見た目や Git ブランチ、Python バージョン、実行時間表示は starship に任せ、zsh 側では履歴、補完、Vim mode、alias、便利関数を整えています。

プラグインや外部ツールの棚卸しは `plugins_inventory.md` にまとめています。

## 使い始める

現在の `.zshrc` をバックアップしてから使うのがおすすめです。

```sh
cp ~/.zshrc ~/.zshrc.backup
cp config/zsh/.zshrc ~/.zshrc
exec zsh
```

このファイルを直接編集したくない設定は `~/.zshrc.local` に書けます。

```sh
touch ~/.zshrc.local
```

プラグインマネージャは `ZSHRC_PLUGIN_MANAGER` で選べます。
デフォルトは `oh-my-zsh` です。

```zsh
# Oh My Zsh を使う
ZSHRC_PLUGIN_MANAGER=oh-my-zsh

# プラグインマネージャを使わない
ZSHRC_PLUGIN_MANAGER=none
```

## 対応環境

- macOS
- Windows WSL
- Linux
- 日本語 / 英語の UTF-8 ロケール

`LANG` がすでに UTF-8 なら尊重します。未設定または UTF-8 ではない場合は、存在するロケールから `C.UTF-8`、`C.utf8`、`en_US.UTF-8`、`ja_JP.UTF-8` の順に選びます。

## PATH / Runtime

Homebrew、Linuxbrew、ユーザー用 bin、Go のパスを自動で見ます。

```sh
/opt/homebrew/bin
/usr/local/bin
/home/linuxbrew/.linuxbrew/bin
~/.local/bin
/usr/local/go/bin
~/go/bin
```

Go を使う場合は `GOPATH="$HOME/go"` も設定します。

## 履歴

複数ターミナルで履歴を共有します。

```sh
history
```

行頭にスペースを入れたコマンドは履歴に残りません。

```sh
 private-command
```

`Ctrl-r` は fzf がある場合、zsh / fish / bash の履歴をまとめて検索します。

対象:

- zsh: `~/.zsh_history`
- fish: `~/.local/share/fish/fish_history`
- bash: `~/.bash_history`

fzf がない環境では、zsh 標準の履歴検索に fallback します。

履歴には実行時刻と実行時間も保存されます。

## Vim Mode

入力は Vim 風です。

- `Esc`: command mode
- `i`: insert mode
- `k`: 入力中の文字列から始まる過去コマンドを上方向に検索
- `j`: 入力中の文字列から始まる過去コマンドを下方向に検索
- `Ctrl-p`: 履歴を上方向に検索
- `Ctrl-n`: 履歴を下方向に検索

対応ターミナルでは、insert mode は細いカーソル、command mode はブロックカーソルになります。

## コマンドライン編集

vi mode ですが、insert mode 中は Emacs 風の基本キーも使えるようにしています。

```text
Ctrl-a  行頭へ移動
Ctrl-e  行末へ移動
Ctrl-b  1文字左へ移動
Ctrl-f  1文字右へ移動。ただし autosuggestion 表示中は候補確定
Ctrl-u  カーソルより左を削除
Ctrl-k  カーソルより右を削除
Ctrl-w  カーソル左の単語を削除
Ctrl-y  削除した内容を貼り戻す
Ctrl-l  画面クリア
```

Mac / Windows / WSL で挙動がずれないよう、`emacs` / `viins` / `vicmd` の各 keymap に明示しています。

## 補完

Tab 補完はメニュー選択できます。

```sh
cd <Tab>
git checkout <Tab>
```

大文字小文字はゆるく補完されます。

```sh
cd documents<Tab>
```

`--prefix=/usr` のような `=` 以降も補完できます。

補完キャッシュは次の場所に保存されます。

```sh
~/.cache/zsh
```

古い `.zshrc` から、害が少なく便利な補完設定も取り込んでいます。

```zsh
setopt mark_dirs
setopt auto_param_keys
setopt always_last_prompt
```

`kill` 補完では PID とコマンド名を見分けやすくする色設定を入れています。

保留設定として `complete_aliases` もコメントアウトで置いてあります。alias 周りの補完挙動が変わるため、必要になったら `.zshrc` 内のコメントを外してください。

`fzf-tab` が入っている場合、Tab 補完候補を fzf UI で絞り込めます。

```text
Tab  補完候補を表示
,    前の group へ移動
.    次の group へ移動
```

## ディレクトリ移動

ディレクトリ名だけで移動できます。

```sh
src
```

`cd` 後は自動で `ls` します。

```sh
cd ~/projects
```

親ディレクトリ移動 alias もあります。

```sh
..
...
....
.....
```

よく使う変数ディレクトリも用意しています。

```sh
cd proj
cd docs
cd desk
```

標準では以下を指します。

```sh
proj="$HOME/projects"
docs="$HOME/Documents"
desk="$HOME/Desktop"
```

変えたい場合は `~/.zshrc.local` に書きます。

```sh
proj="$HOME/dev"
```

## 便利関数

ディレクトリを作って移動します。

```sh
mkcd new-project
```

一時ディレクトリを作って移動します。

```sh
cdt
```

上位ディレクトリをさかのぼって、指定ファイルやディレクトリがある場所へ移動します。

```sh
croot .git
croot package.json
```

引数なしなら `.git` を探します。

```sh
croot
```

cd 履歴を表示します。

```sh
cdh
```

番号を指定して移動します。

```sh
cdh 2
```

現在のパスに含まれる親ディレクトリ名へ戻れます。

```sh
bd src
bd app
```

`ghq` と `fzf` が入っていれば、`Ctrl-]` でリポジトリ一覧から選んで移動できます。

```sh
ghq-fzf-cd
```

## SSH helpers

zsh では通常の `ssh` も WezTerm SSH wrapper 経由にします。

これにより `ssh host` だけで、ログ保存、WezTerm 背景色、タブ色、右上表示、入室時確認が動きます。
profile を明示したい場合は以下も使えます。

```sh
ssh example-dev
ssh-log example-prod
ssh-prod example-prod
ssh-staging example-staging
ssh-lab example-lab
ssh-dev example-dev
```

`ssh` / `ssh-log` は `wezterm-ssh-log` を呼び出します。`wezterm-ssh-log` が PATH にない場合は、通常の `ssh` に fallback します。

`ssh prod-db01` のように Host 名が `prod-*` / `*-prod` / `*.prod` に一致する場合は、自動で `prod` profile になります。
staging / lab / dev も同様に Host 名規約で判定します。
判定順は `prod > staging > lab > dev > default` です。

```zsh
ZSHRC_SSH_PROD_PATTERNS+=(bastion-prod *.critical)
ZSHRC_SSH_STAGING_PATTERNS+=(qa-* *-qa)
ZSHRC_SSH_LAB_PATTERNS+=(lab-bastion sandbox-*)
```

ログ保存先:

```text
~/.local/share/wezterm/ssh-logs/<profile>/<host>/YYYYMMDD-HHMMSS.log
```

接続直後に remote 側で以下を実行します。

```sh
id && date && uname -n
```

ログなしで入りたい場合:

```sh
ssh-nolog example-dev
```

入室時確認コマンドなしで入りたい場合:

```sh
ssh-noprobe example-dev
```

`vagrant ssh` は Vagrant 専用 profile で WezTerm SSH wrapper 経由にします。
`vagrant up` / `vagrant status` など SSH 以外の Vagrant コマンドは通常通りです。

```sh
vagrant ssh
```

状態確認は短い alias もあります。

```sh
vs   # vagrant status
vgs  # vagrant global-status --prune
```

例外的に通常の `ssh` へ戻したい環境では、`~/.zshrc.local` に次を書きます。

```zsh
ZSHRC_WRAP_SSH_WITH_WEZTERM=0
```

## alias

基本 alias です。

```sh
ll
lla
la
lf
du
df
where zsh
```

安全寄りに、以下は確認付きです。

```sh
rm
cp
mv
```

`sudo` 後も alias が展開されます。

```sh
sudo ll
```

## Global Alias

zsh の global alias により、コマンドの途中や末尾でパイプを短く書けます。

```sh
ps aux G python
git diff L
cat app.log H
cat app.log T
```

展開後の意味です。

```sh
G='| grep'
L='| less'
H='| head'
T='| tail'
```

クリップボード用の `C` もあります。

```sh
git branch C
pwd C
```

環境ごとに以下を自動で使います。

- macOS: `pbcopy`
- WSL: `clip.exe`
- Wayland Linux: `wl-copy`
- X11 Linux: `xclip` または `xsel`

## Suffix Alias

拡張子に応じて、ファイル名だけで開けます。

```sh
README.md
config.json
app.log
```

対応は以下です。

```sh
md, markdown, txt, json, yaml, yml -> vim
log -> less
```

## glob

拡張 glob が有効です。

特定ファイルを除外できます。

```sh
ls *.txt~memo.txt
```

再帰的に探せます。

```sh
ls **/*.log
```

dotfile も glob 対象に入ります。

```sh
ls *
```

数字は自然順で並びます。

```sh
ls file*
```

`file2` が `file10` より前に来ます。

## OS 別の動き

`ls` の色指定は OS ごとに切り替えます。

- macOS: `ls -G`
- Linux / WSL: `ls --color=auto`

現在のディレクトリを GUI で開く `o` もあります。

```sh
o
```

- macOS: `open .`
- WSL: `explorer.exe .`

## pyenv

`~/.pyenv` が存在し、`pyenv` コマンドが使える場合だけ初期化します。

```sh
pyenv versions
pyenv local 3.12.0
```

Python バージョンのプロンプト表示は starship 側に任せる想定です。

## rbenv

`rbenv` コマンドが使える場合だけ初期化します。

```sh
rbenv versions
rbenv local 3.3.0
```

Ruby バージョンのプロンプト表示は starship 側に任せる想定です。

## fzf

`fzf` が入っている場合だけ zsh integration を読み込みます。古い `fzf` で `fzf --zsh` が使えない場合は静かにスキップします。

`ripgrep` がある場合は、fzf のファイル候補に `rg --files` を使います。

```sh
Ctrl-R  # fzf の履歴検索
Ctrl-T  # fzf のファイル選択
Alt-C   # fzf のディレクトリ移動
Ctrl-G  # ファイルを選んでコマンドラインに挿入
Ctrl-O  # ファイルを選んで EDITOR で開く
```

## zoxide

`zoxide` が入っている場合だけ有効化します。

```sh
z project
zi project
```

fish の `jethrokuan/z` 相当は、zsh では `zoxide` で置き換える方針です。

## zsh-autosuggestions

インストールされている場合だけ読み込みます。

入力中に、履歴や補完候補から fish 風の薄いサジェストを表示します。

代表的な場所を自動で見ます。

- `/opt/homebrew/share/zsh-autosuggestions`
- `/usr/local/share/zsh-autosuggestions`
- `/home/linuxbrew/.linuxbrew/share/zsh-autosuggestions`
- `/usr/share/zsh-autosuggestions`
- `~/.zsh/zsh-autosuggestions`

使い方:

```text
Ctrl-f    サジェストを確定
Right     環境によってはサジェストを確定
```

## direnv

`direnv` が入っている場合だけ有効化します。

プロジェクトごとの環境変数は `.envrc` に書き、初回だけ許可します。

```sh
direnv allow
direnv deny
```

## atuin

`atuin` が入っている場合だけ有効化します。

既存の `Ctrl-r` と ↑ 履歴操作を維持するため、atuin 側のキーバインドは無効化しています。

```sh
ah
ahi
```

## zsh-abbr

`zsh-abbr` が入っている場合だけ有効化します。

略語は `~/.zshrc.local` に書くのがおすすめです。

```zsh
abbr gs git status
abbr gc git commit
abbr gco git checkout
```

## zsh-syntax-highlighting

インストールされている場合だけ読み込みます。

代表的な場所を自動で見ます。

- `/opt/homebrew/share/zsh-syntax-highlighting`
- `/usr/local/share/zsh-syntax-highlighting`
- `/home/linuxbrew/.linuxbrew/share/zsh-syntax-highlighting`
- `/usr/share/zsh-syntax-highlighting`
- `~/.zsh/zsh-syntax-highlighting`

## starship

`starship` が入っている場合だけ有効化します。

```sh
starship --version
```

Git ブランチ、pyenv/Python、コマンド実行時間などの表示は starship の設定で行います。

この環境用の設定例は `starship.toml`、使い方は `starship_README.md` にまとめています。

## プラグイン / 外部ツール整理

プラグインマネージャは選択式です。

デフォルトでは Oh My Zsh を使います。

```zsh
ZSHRC_PLUGIN_MANAGER=oh-my-zsh
```

プラグインマネージャなしにしたい場合は `~/.zshrc.local` に次を書きます。

```zsh
ZSHRC_PLUGIN_MANAGER=none
```

`.zshrc` で扱っている主な外部要素は以下です。

- `pyenv`
- `rbenv`
- `fzf`
- `fzf-tab`
- `zoxide`
- `ghq`
- `direnv`
- `atuin`
- `terraform`
- `zsh-abbr`
- `zsh-autosuggestions`
- `zsh-syntax-highlighting`
- Oh My Zsh plugins
- `starship`
- `dircolors`
- クリップボード系の `pbcopy` / `clip.exe` / `wl-copy` / `xclip` / `xsel`

詳細は `plugins_inventory.md` を見てください。

## 好みに応じて外す候補

`cd` 後の自動 `ls` がうるさい場合は、この関数をコメントアウトします。

```zsh
function cd() {
  builtin cd "$@" && ls
}
```

`rm`、`cp`、`mv` の確認が不要なら alias を外します。

```zsh
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
```

suffix alias が予想外に感じる場合は、このあたりを外します。

```zsh
alias -s md=vim
alias -s log=less
```

Vim mode のカーソル形状変更で表示が崩れるターミナルでは、`zle-keymap-select`、`zle-line-init`、`zle-line-finish` の3関数を外します。

terminal title 更新と `zed` はコメントアウトで保留しています。WezTerm 側で SSH 接続先名や profile を表示する設計とぶつかりやすいため、今は zsh 側から title を更新しない方針です。

`command-not-found` は便利なので有効化しています。存在しない command を打った時の待ち時間が気になる場合は、Oh My Zsh の `plugins=(...)` から外してください。

`magic-enter` は空 Enter で `ls` などが走るため無効化しています。

## あえて入れていないもの

`setopt correct` や `setopt correct_all` は、勝手に補正確認が出てストレスになることがあるため入れていません。

`setopt no_nomatch` は bash っぽくなりますが、typo に気づきにくくなるため入れていません。

`ssh-agent` plugin は 1Password SSH agent と競合しやすいため入れていません。
