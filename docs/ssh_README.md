# SSH helper README

`wezterm-ssh-log` は、WezTerm から SSH する時に RLogin 的な安全運用を足すための wrapper です。
`ssh-prod` などは shell function ではなく `~/bin` の実行ファイルなので、zsh / fish / bash から同じ名前で使えます。

## 方針

zsh では通常の `ssh` も wrapper 経由にします。

`vagrant ssh` は Vagrant 専用 profile で wrapper 経由にします。
`vagrant up` / `vagrant status` など SSH 以外の Vagrant コマンドは通常通りです。

profile 指定が必要な接続では、明示的に以下も使います。

```sh
ssh
ssh-log
ssh-prod
ssh-staging
ssh-lab
ssh-dev
```

## できること

- SSH 接続先ごとにログ保存
- profile ごとにログを分ける
- 接続直後に `id && date && uname -n`
- WezTerm 側に渡すための環境変数をセット
- SSH 終了後や接続失敗後に WezTerm 側の SSH 表示を解除
- WezTerm の背景色、タブ色、右上表示を SSH profile に合わせる
- 背景の透明度や macOS のぼかしは profile ごとに切り替えず、タブ切替時の負荷を抑える
- 複数行ペースト確認は一時入力 UI を出さず、背景色が揺れにくい二段階方式にする

## タブ移動の軽さ

WezTerm 側は `wezterm-ssh-log` が送る user vars を見て SSH profile を判定します。
タブ切替を軽くするため、wrapper なしの素の `/usr/bin/ssh` を前面プロセス名から推測する fallback はデフォルトで無効です。

どうしても wrapper なし SSH も generic SSH 色にしたい場合だけ、WezTerm 起動前の環境で次を設定します。

```sh
export WEZTERM_ENABLE_PLAIN_SSH_DETECTION=1
```

## 使い方

標準:

```sh
ssh example-prod
ssh-log example-prod
```

profile 指定:

```sh
ssh-log --profile prod -- example-prod
```

短縮関数:

```sh
ssh-prod example-prod
ssh-staging example-staging
ssh-lab example-lab
ssh-dev example-dev
```

## ssh config Host 名から profile を自動判定

zsh では通常の `ssh` も wrapper 経由です。
そのため、`~/.ssh/config` の `Host` 名に規約を付けると、`ssh host` だけで profile を自動選択できます。

本番扱いになる例:

```sshconfig
Host prod-db01
  HostName 192.0.2.10
  User app

Host db01-prod
  HostName 192.0.2.11
  User app
```

この場合:

```sh
ssh prod-db01
ssh db01-prod
```

は内部的に次と同じ profile で動きます。

```sh
wezterm-ssh-log --profile prod ...
```

デフォルトの判定:

```text
prod:     prod-* / *-prod / *.prod / production-* / *-production
staging:  stg-* / *-stg / staging-* / *-staging / *.stg / *.staging
lab:      lab-* / *-lab / *.lab
dev:      dev-* / *-dev / *.dev
```

追加したい場合は `~/.zshrc.local` に書きます。

```zsh
ZSHRC_SSH_PROD_PATTERNS+=(core-db bastion-prod *.critical)
ZSHRC_SSH_STAGING_PATTERNS+=(qa-* *-qa)
ZSHRC_SSH_LAB_PATTERNS+=(lab-bastion sandbox-*)
```

`~/.ssh/config` だけでローカルの `ssh-prod` コマンドを直接呼ぶことは基本できません。
Host 名規約を zsh wrapper が読む方式にしています。

user や port を指定:

```sh
ssh-prod -- -p 22 alice@example-prod
```

表示名/ログ名を指定:

```sh
ssh-log --profile prod --name example-prod -- alice@192.0.2.10
```

## ログ

保存先:

```text
~/.local/share/wezterm/ssh-logs/<profile>/<host>/YYYYMMDD-HHMMSS.log
```

例:

```text
~/.local/share/wezterm/ssh-logs/prod/example-prod/20260704-110000.log
```

ログ保存先を変える:

```sh
export WEZTERM_SSH_LOG_DIR="$HOME/ssh-logs"
```

ログを見る:

```sh
ssh-log-view                 # 最新ログを less -R で見る
ssh-log-view path/to/log     # 指定ログを見る
slog                         # ssh-log-view の短縮 alias
```

`script(1)` のログには色やカーソル制御の ANSI escape sequence が含まれます。
通常の `less` で生コードに見える場合は `less -R` 相当の `ssh-log-view` を使います。
`^M` / `^G` / `^H` / `file://...` / Nerd Font glyph が邪魔な場合は、色や制御コードを剥がす `ssh-log-clean` を使います。

```sh
ssh-log-clean
slog-clean
```

## 入室時確認

デフォルトでは remote 側で最初に以下を実行します。

```sh
id && date && uname -n
```

その後、remote の login shell に入ります。

入室時確認をスキップ:

```sh
ssh-noprobe example-dev
```

`~/.ssh/config` 側で `RemoteCommand` が設定されている Host では、OpenSSH の制約により入室時確認を自動でスキップします。
`RemoteCommand` とコマンドライン指定を同時に使うと接続が失敗するためです。

ログ保存をスキップ:

```sh
ssh-nolog example-dev
```

## Vagrant

`vagrant ssh` は `vagrant ssh-config` を使って接続情報を取り出し、`wezterm-ssh-log --profile vagrant` 経由で接続します。

```sh
vagrant ssh
```

VM 名を指定する場合:

```sh
vagrant ssh default
```

複雑な `vagrant ssh` option を使う場合は、Vagrant 本体の挙動を優先して通常実行へ fallback します。

通常の `ssh` wrapper を無効化したい場合:

```zsh
ZSHRC_WRAP_SSH_WITH_WEZTERM=0
```

## WezTerm 連携

wrapper は以下の環境変数をセットします。

```sh
WEZTERM_SSH_PROFILE
WEZTERM_SSH_HOST
```

後続の WezTerm 設定では、この profile / host を使って以下を実装できます。

- 右上に `PROD example-prod` 表示
- profile ごとの背景色
- profile ごとのタブ色
- 背景変更時に文字色、ANSI 色、選択範囲、カーソル色も読みやすく調整
- prod は複数行 paste を赤い右上警告付きの二段階確認にする
- launch menu から `wezterm-ssh-log` を呼ぶ
