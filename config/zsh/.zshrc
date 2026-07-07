# 2026年版 .zshrc
# macOS / WSL / Linux 共通で使うための zsh 設定。
# fish の見やすさは starship に任せつつ、シェル本体は標準的な zsh として使う。


# ------------------------------------------------------------
# 文字コード
# ------------------------------------------------------------

# 日本語でも英語でも壊れにくいように、UTF-8 ロケールを使う。
# すでに LANG が UTF-8 ならそれを尊重する。
# 未設定または UTF-8 でない場合は、環境に存在する UTF-8 ロケールを選ぶ。
function __zshrc_has_locale() {
  locale -a 2>/dev/null | grep -qx "$1"
}

case "$LANG" in
  *UTF-8*|*utf8*|*UTF8*)
    ;;
  *)
    if __zshrc_has_locale "C.UTF-8"; then
      export LANG="C.UTF-8"
    elif __zshrc_has_locale "C.utf8"; then
      export LANG="C.utf8"
    elif __zshrc_has_locale "en_US.UTF-8"; then
      export LANG="en_US.UTF-8"
    elif __zshrc_has_locale "ja_JP.UTF-8"; then
      export LANG="ja_JP.UTF-8"
    else
      export LANG="C"
    fi
    ;;
esac

# LC_CTYPE も UTF-8 にして、日本語ファイル名や補完表示を扱いやすくする。
export LC_CTYPE="$LANG"
unset -f __zshrc_has_locale


# ------------------------------------------------------------
# 環境判定
# ------------------------------------------------------------

# OS や WSL かどうかを判定して、後続の設定で使う。
ZSHRC_OS="unknown"
ZSHRC_IS_WSL=0

case "$(uname -s 2>/dev/null)" in
  Darwin)
    ZSHRC_OS="macos"
    ;;
  Linux)
    ZSHRC_OS="linux"
    if grep -qi microsoft /proc/version 2>/dev/null; then
      ZSHRC_IS_WSL=1
    fi
    ;;
esac


# ------------------------------------------------------------
# PATH
# ------------------------------------------------------------

# PATH の重複を自動で取り除く。
# .zshrc を何度 source しても同じパスが増え続けないようにする。
typeset -U path PATH

# Homebrew のパスを先に通す。
# Apple Silicon Mac は /opt/homebrew、Intel Mac は /usr/local、
# Linuxbrew / WSL は /home/linuxbrew/.linuxbrew が使われることが多い。
if [ -d /opt/homebrew/bin ]; then
  export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
fi

if [ -d /usr/local/bin ]; then
  export PATH="/usr/local/bin:/usr/local/sbin:$PATH"
fi

if [ -d /home/linuxbrew/.linuxbrew/bin ]; then
  export PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:$PATH"
fi

# ユーザー単位で入れたコマンド置き場。
if [ -d "$HOME/bin" ]; then
  export PATH="$HOME/bin:$PATH"
fi

if [ -d "$HOME/.local/bin" ]; then
  export PATH="$HOME/.local/bin:$PATH"
fi

# Go を使う場合のパス。
if [ -d /usr/local/go/bin ]; then
  export PATH="/usr/local/go/bin:$PATH"
fi

if [ -d "$HOME/go/bin" ]; then
  export GOPATH="$HOME/go"
  export PATH="$PATH:$GOPATH/bin"
fi


# ------------------------------------------------------------
# 外部ツール / プラグイン方針
# ------------------------------------------------------------

# プラグインマネージャは選べるようにする。
# デフォルトは Oh My Zsh。不要な環境では .zshrc.local で ZSHRC_PLUGIN_MANAGER=none にする。
# 外部ツールは入っているものだけを検出して有効化する。
#
# 現在扱うもの:
# - pyenv: Python バージョン管理
# - rbenv: Ruby バージョン管理
# - Oh My Zsh: 内蔵プラグイン群。入っている場合だけ読み込む。
# - fzf: fuzzy finder / 履歴・ファイル・ディレクトリ選択
# - zoxide: 賢い cd
# - ghq: リポジトリ管理と移動
# - fzf-tab: Tab 補完候補を fzf UI で選択
# - direnv: ディレクトリごとの環境変数読み込み
# - atuin: 履歴 DB / 履歴検索
# - zsh-abbr: fish 風 abbreviation
# - wezterm-ssh-log: SSH ログ保存と入室時確認
# - zsh-autosuggestions: fish 風の入力中サジェスト
# - zsh-syntax-highlighting: 入力中コマンドの色付け
# - starship: プロンプト表示
# - dircolors / pbcopy / clip.exe / wl-copy / xclip / xsel: OS 別の補助ツール


# ------------------------------------------------------------
# pyenv
# ------------------------------------------------------------

# pyenv が入っている場合だけ有効化する。
# starship を使うと、現在の Python バージョン表示もプロンプト側に出せる。
export PYENV_ROOT="$HOME/.pyenv"
if [ -d "$PYENV_ROOT/bin" ]; then
  export PATH="$PYENV_ROOT/bin:$PATH"
fi

if command -v pyenv >/dev/null 2>&1; then
  eval "$(pyenv init - zsh)"
fi


# ------------------------------------------------------------
# rbenv
# ------------------------------------------------------------

# rbenv が入っている場合だけ有効化する。
# Ruby バージョンのプロンプト表示は starship 側に任せる。
if command -v rbenv >/dev/null 2>&1; then
  eval "$(rbenv init - zsh)"
fi

# ここから下は補完・履歴・ZLE・prompt などの対話シェル用設定。
# `zsh -i -c ...` や一部の端末 wrapper では stdin/stdout が TTY でない場合がある。
# TTY 有無ではなく zsh の interactive 状態で判定し、SSH helper が読み飛ばされないようにする。
if [[ ! -o interactive ]]; then
  return 0 2>/dev/null || true
fi


# ------------------------------------------------------------
# Oh My Zsh plugins
# ------------------------------------------------------------

# Zenn の参考記事に合わせた Oh My Zsh プラグイン群。
# ZSHRC_PLUGIN_MANAGER=oh-my-zsh の時だけ有効化する。
# Oh My Zsh が未インストールならエラーにせずスキップする。
# 1Password の SSH agent と競合しやすい ssh-agent plugin は入れない。
ZSHRC_PLUGIN_MANAGER="${ZSHRC_PLUGIN_MANAGER:-oh-my-zsh}"
export ZSH="${ZSH:-$HOME/.oh-my-zsh}"

if [ "$ZSHRC_PLUGIN_MANAGER" = "oh-my-zsh" ] && [ -r "$ZSH/oh-my-zsh.sh" ]; then
  # starship を使うため、Oh My Zsh 側のテーマは無効にする。
  ZSH_THEME=""

  # compaudit の警告で起動が止まらないようにする。
  ZSH_DISABLE_COMPFIX=true

  plugins=(
    # 基本
    git
    1password
    z
    fzf
    sudo
    history-substring-search
    extract
    colored-man-pages
    command-not-found

    # macOS
    macos
    brew

    # 開発
    docker
    docker-compose
    gh
    terraform
    vagrant
    vagrant-prompt
    direnv
    dotenv
    jsontools

    # 生産性
    copypath
    copyfile
    aliases
    safe-paste
    bgnotify
    fancy-ctrl-z
    web-search
    encode64
  )

  source "$ZSH/oh-my-zsh.sh"
fi


# ------------------------------------------------------------
# 履歴
# ------------------------------------------------------------

# 履歴ファイル。
HISTFILE="$HOME/.zsh_history"

# 履歴の保存件数。大きめだが、極端に大きくしすぎない。
HISTSIZE=100000
SAVEHIST=100000

# 履歴を追記保存する。
setopt append_history

# 履歴に実行時刻と実行時間を保存する。
setopt extended_history

# コマンド実行ごとに履歴を保存する。
setopt inc_append_history

# 複数ターミナル間で履歴を共有する。
setopt share_history

# 重複した履歴を減らす。
setopt hist_ignore_dups
setopt hist_ignore_all_dups
setopt hist_find_no_dups

# 行頭がスペースのコマンドは履歴に残さない。
setopt hist_ignore_space

# 余分な空白を詰めて履歴に保存する。
setopt hist_reduce_blanks

# history コマンド自体を履歴に残さない。
setopt hist_no_store

# 履歴展開をすぐ実行せず、一度編集できる状態にする。
setopt hist_verify


# ------------------------------------------------------------
# zsh の基本挙動
# ------------------------------------------------------------

# ディレクトリ名だけを入力したら cd する。
setopt auto_cd

# cd したディレクトリを自動でスタックに積む。
setopt auto_pushd

# 同じディレクトリを pushd スタックに重複登録しない。
setopt pushd_ignore_dups

# コマンドライン上でも # 以降をコメントとして扱う。
setopt interactive_comments

# ビープ音を鳴らさない。
setopt no_beep
setopt no_list_beep

# 日本語ファイル名を補完候補で正しく表示しやすくする。
setopt print_eight_bit

# 拡張 glob を使えるようにする。
# 例: ls *.txt~memo.txt で memo.txt 以外の txt にマッチ。
setopt extended_glob

# 明示的に . を指定しなくても dotfile を glob 対象に含める。
setopt glob_dots

# glob 展開でディレクトリにマッチした場合、末尾に / を付ける。
setopt mark_dirs

# file2 が file10 より前に来るような自然な数字順で glob を並べる。
setopt numeric_glob_sort

# 変数名を cd 先として使えるようにする。
# 例: proj="$HOME/projects" としてから cd proj
setopt cdable_vars

# よく使う移動先の例。必要に応じて .zshrc.local で上書きする。
proj="$HOME/projects"
docs="$HOME/Documents"
desk="$HOME/Desktop"


# ------------------------------------------------------------
# 補完
# ------------------------------------------------------------

# zsh-completions が入っている場合、補完関数の探索パスに追加する。
# これは compinit より前に置く必要がある。
zsh_completions_paths=(
  /opt/homebrew/share/zsh-completions
  /usr/local/share/zsh-completions
  /home/linuxbrew/.linuxbrew/share/zsh-completions
  /usr/share/zsh/vendor-completions
  "$HOME/.zsh/zsh-completions/src"
)

for zsh_completion_dir in "${zsh_completions_paths[@]}"; do
  if [ -d "$zsh_completion_dir" ]; then
    fpath=("$zsh_completion_dir" $fpath)
  fi
done

unset zsh_completion_dir zsh_completions_paths

# 補完キャッシュ用ディレクトリ。
ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
mkdir -p "$ZSH_CACHE_DIR"

# 補完システムを読み込む。
# Oh My Zsh が既に compinit 済みの場合は、二重実行を避ける。
if (( ! ${+functions[compdef]} )); then
  autoload -Uz compinit compaudit

  # 補完ディレクトリの権限がゆるい場合、compinit は確認プロンプトを出す。
  # 起動時に毎回止まると使いにくいため、ここでは compinit -i で静かに続行する。
  # 根本対応は、別途 `compaudit` で表示されたディレクトリの権限を直すこと。
  insecure_completion_dirs=("${(@f)$(compaudit 2>/dev/null)}")
  if [ -n "${insecure_completion_dirs[*]}" ]; then
    compinit -i -d "$ZSH_CACHE_DIR/zcompdump"
  else
    compinit -d "$ZSH_CACHE_DIR/zcompdump"
  fi
  unset insecure_completion_dirs
fi

# 補完候補を順番に選べるようにする。
setopt auto_menu

# 補完候補一覧でファイル種別を表示する。
setopt list_types

# 補完候補を詰めて表示する。
setopt list_packed

# --prefix=/usr のような = 以降でも補完する。
setopt magic_equal_subst

# 単語の途中でも補完できるようにする。
setopt complete_in_word

# ディレクトリ補完時に末尾の / を自動で付ける。
setopt auto_param_slash

# 補完時に括弧などの対応を補助する。
setopt auto_param_keys

# 補完候補の末尾にカーソルを移動する。
setopt always_to_end

# 補完一覧を表示しても、最後のプロンプト位置を扱いやすくする。
setopt always_last_prompt

# 保留: alias 展開後の補完を強める。
# 補完挙動が少し変わるので、必要になったら有効化する。
# setopt complete_aliases

# Tab で補完候補をメニュー選択する。
zstyle ':completion:*:default' menu select=1

# 大文字小文字をゆるく補完する。
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# 補完候補をグループ化する。
zstyle ':completion:*' group-name ''

# 補完メッセージを少し読みやすくする。
zstyle ':completion:*' verbose yes
zstyle ':completion:*:descriptions' format 'completing %B%d%b'
zstyle ':completion:*:warnings' format 'No matches for: %d'

# 補完結果をキャッシュして、重い補完を少し軽くする。
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path "$ZSH_CACHE_DIR"

# kill 補完で PID / コマンド名を見分けやすくする。
zstyle ':completion:*:kill:*' list-colors \
  '=(#b) #([0-9]#)*( *[a-z])*=34=31=33'

# fzf-tab が入っている場合、Tab 補完候補を fzf UI で選べるようにする。
# compinit より後、zsh-syntax-highlighting より前に読み込む。
fzf_tab_paths=(
  /opt/homebrew/share/fzf-tab/fzf-tab.plugin.zsh
  /usr/local/share/fzf-tab/fzf-tab.plugin.zsh
  /home/linuxbrew/.linuxbrew/share/fzf-tab/fzf-tab.plugin.zsh
  "$HOME/.zsh/fzf-tab/fzf-tab.plugin.zsh"
)

for zsh_plugin_file in "${fzf_tab_paths[@]}"; do
  if [ -r "$zsh_plugin_file" ]; then
    source "$zsh_plugin_file"
    break
  fi
done

# 補完候補の preview。対応できる範囲だけ軽く出す。
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls -la --color=auto $realpath 2>/dev/null || ls -la $realpath 2>/dev/null'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls -la --color=auto $realpath 2>/dev/null || ls -la $realpath 2>/dev/null'
zstyle ':fzf-tab:*' switch-group ',' '.'

unset zsh_plugin_file fzf_tab_paths

# 保留: zsh 組み込み editor。
# 普段 Vim を使うなら不要。必要になったら有効化する。
# autoload -Uz zed


# ------------------------------------------------------------
# キーバインド
# ------------------------------------------------------------

# Vim 風キーバインドにする。
# insert mode / command mode を使えるようにする。
bindkey -v

# ESC 後に command mode へ入る待ち時間を短くする。
export KEYTIMEOUT=1

# Home / End / Delete キーの基本対応。
bindkey -M viins '^[[1~' beginning-of-line
bindkey -M viins '^[[4~' end-of-line
bindkey -M viins '^[[3~' delete-char
bindkey -M vicmd '^[[1~' beginning-of-line
bindkey -M vicmd '^[[4~' end-of-line
bindkey -M vicmd '^[[3~' delete-char

# Emacs 風の基本移動/編集キー。
# vi mode でも insert mode 中は Ctrl-a/e などを使えるように明示する。
for zshrc_keymap in emacs viins vicmd; do
  bindkey -M "$zshrc_keymap" '^A' beginning-of-line
  bindkey -M "$zshrc_keymap" '^E' end-of-line
  bindkey -M "$zshrc_keymap" '^F' forward-char
  bindkey -M "$zshrc_keymap" '^B' backward-char
  bindkey -M "$zshrc_keymap" '^U' backward-kill-line
  bindkey -M "$zshrc_keymap" '^K' kill-line
  bindkey -M "$zshrc_keymap" '^W' backward-kill-word
  bindkey -M "$zshrc_keymap" '^Y' yank
  bindkey -M "$zshrc_keymap" '^L' clear-screen
done
unset zshrc_keymap

# 入力済み文字列から始まる履歴を検索する。
autoload -Uz history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey -M viins '^p' history-beginning-search-backward-end
bindkey -M viins '^n' history-beginning-search-forward-end
bindkey -M viins '^[p' history-beginning-search-backward-end
bindkey -M viins '^[n' history-beginning-search-forward-end
bindkey -M vicmd '^p' history-beginning-search-backward-end
bindkey -M vicmd '^n' history-beginning-search-forward-end
bindkey -M vicmd '^[p' history-beginning-search-backward-end
bindkey -M vicmd '^[n' history-beginning-search-forward-end

# Vim の感覚に寄せて、command mode の k/j で履歴検索を使う。
bindkey -M vicmd 'k' history-beginning-search-backward-end
bindkey -M vicmd 'j' history-beginning-search-forward-end

# Shift-Tab で補完候補を逆順に移動する。
bindkey -M viins '^[[Z' reverse-menu-complete
bindkey -M vicmd '^[[Z' reverse-menu-complete

# 対応ターミナルでは、insert mode は細いカーソル、command mode はブロックカーソルにする。
function zle-keymap-select() {
  case "$KEYMAP" in
    vicmd)
      printf '\e[2 q'
      ;;
    *)
      printf '\e[6 q'
      ;;
  esac
}
zle -N zle-keymap-select

function zle-line-init() {
  zle-keymap-select
}
zle -N zle-line-init

function zle-line-finish() {
  printf '\e[0 q'
}
zle -N zle-line-finish

# ------------------------------------------------------------
# fzf / zoxide
# ------------------------------------------------------------

# fzf の見た目と挙動。
export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:---height=40% --layout=reverse --border --info=inline}"

# ripgrep があれば、fzf のデフォルト候補を .gitignore 尊重の高速検索にする。
if command -v rg >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/*"'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

# fzf の key bindings / fuzzy completion を有効化する。
# 新しい fzf では fzf --zsh が使える。古い fzf では何もせず静かにスキップする。
if command -v fzf >/dev/null 2>&1 && fzf --zsh >/dev/null 2>&1; then
  source <(fzf --zsh)
fi

# zoxide は賢い cd。
# z / zi コマンドを追加する。補完のため compinit より後に置く。
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# direnv はディレクトリごとの環境変数を自動で読み込む。
# .envrc は初回に `direnv allow` したディレクトリだけ有効になる。
# Oh My Zsh の direnv plugin が既に hook を入れている場合は二重登録しない。
if command -v direnv >/dev/null 2>&1 && (( ! ${+functions[_direnv_hook]} )); then
  eval "$(direnv hook zsh)"
fi

# atuin は履歴を DB 化して高速に検索できる。
# 既存の Ctrl-r / ↑ 履歴操作を優先するため、キーバインドは奪わせない。
if command -v atuin >/dev/null 2>&1; then
  eval "$(atuin init zsh --disable-ctrl-r --disable-up-arrow --disable-ai)"
  alias ah='atuin search'
  alias ahi='atuin import auto'
fi


# ------------------------------------------------------------
# alias
# ------------------------------------------------------------

alias where='command -v'
alias j='jobs -l'

# OS ごとに ls の色オプションを切り替える。
case "$ZSHRC_OS" in
  macos)
    alias ls='ls -G'
    ;;
  linux)
    alias ls='ls --color=auto'
    ;;
esac

alias la='ls -a'
alias lf='ls -F'
alias ll='ls -lh'
alias lla='ls -lha'

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

alias du='du -h'
alias df='df -h'

alias mkdir='mkdir -p'

# sudo 後でも alias を展開できるようにする。
alias sudo='sudo '

# 安全寄りに確認を出す。
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

alias vi='vim'

# グローバル alias。
# 例: ls G foo で ls | grep foo
alias -g L='| less'
alias -g G='| grep'
alias -g H='| head'
alias -g T='| tail'

# 拡張子に応じて開くコマンドを決める suffix alias。
# 例: README.md だけで vim README.md、app.log だけで less app.log
alias -s md=vim
alias -s markdown=vim
alias -s txt=vim
alias -s json=vim
alias -s yaml=vim
alias -s yml=vim
alias -s log=less

# 末尾に C を付けるとクリップボードへ送れるようにする。
# 例: git branch C
if command -v pbcopy >/dev/null 2>&1; then
  alias -g C='| pbcopy'
elif [ "$ZSHRC_IS_WSL" -eq 1 ] && command -v clip.exe >/dev/null 2>&1; then
  alias -g C='| clip.exe'
elif command -v wl-copy >/dev/null 2>&1; then
  alias -g C='| wl-copy'
elif command -v xclip >/dev/null 2>&1; then
  alias -g C='| xclip -selection clipboard'
elif command -v xsel >/dev/null 2>&1; then
  alias -g C='| xsel --input --clipboard'
fi

# macOS では open、WSL では explorer.exe で現在位置を開く。
case "$ZSHRC_OS:$ZSHRC_IS_WSL" in
  macos:*)
    alias o='open .'
    ;;
  linux:1)
    alias o='explorer.exe .'
    ;;
esac


# ------------------------------------------------------------
# cd 後に ls
# ------------------------------------------------------------

# ディレクトリ移動後に中身を軽く表示する。
# 不要ならこの関数をコメントアウトする。
function cd() {
  builtin cd "$@" && ls
}

# ディレクトリを作って、そのまま移動する。
function mkcd() {
  if [ $# -ne 1 ]; then
    echo "usage: mkcd <directory>" >&2
    return 2
  fi

  mkdir -p "$1" && cd "$1"
}

# 一時ディレクトリを作って、そのまま移動する。
function cdt() {
  local dir
  dir="$(mktemp -d)" || return
  cd "$dir"
}

# 上位ディレクトリへさかのぼり、指定ファイル/ディレクトリがある場所へ移動する。
# 例: croot .git / croot package.json
function croot() {
  local marker="${1:-.git}"
  local dir="$PWD"

  while [ "$dir" != "/" ]; do
    if [ -e "$dir/$marker" ]; then
      cd "$dir"
      return
    fi
    dir="${dir:h}"
  done

  echo "not found: $marker" >&2
  return 1
}

# cd 履歴を選んで移動する。
# 例: cdh で最近移動したディレクトリ一覧を表示、cdh 2 で 2 番へ移動。
function cdh() {
  if [ $# -eq 0 ]; then
    dirs -v
    return
  fi

  builtin cd +"$1"
}

# 現在のパスに含まれる親ディレクトリ名へ一気に戻る。
# 例: /a/b/c/d にいる時、bd b で /a/b へ移動する。
function bd() {
  local pattern="${1:-}"
  local oldpwd="$PWD"
  local newpwd=""

  if [ -z "$pattern" ]; then
    cd ..
    return
  fi

  case "$pattern" in
    -h|--help)
      echo "usage: bd <parent-directory-name>"
      return
      ;;
  esac

  local parts=("${(@s:/:)PWD}")
  local path=""
  local part

  for part in "${parts[@]}"; do
    [ -z "$part" ] && continue
    path="$path/$part"
    if [ "$part" = "$pattern" ]; then
      newpwd="$path"
    fi
  done

  if [ -z "$newpwd" ] || [ "$newpwd" = "$oldpwd" ]; then
    echo "bd: parent not found: $pattern" >&2
    return 1
  fi

  cd "$newpwd"
}

# ghq のリポジトリ一覧から fzf で選んで移動する。
# ghq または fzf がない場合は起動時エラーにせず、実行時にだけ知らせる。
function ghq-fzf-cd() {
  if ! command -v ghq >/dev/null 2>&1; then
    echo "ghq-fzf-cd: ghq is not installed" >&2
    return 1
  fi

  if ! command -v fzf >/dev/null 2>&1; then
    echo "ghq-fzf-cd: fzf is not installed" >&2
    return 1
  fi

  local repo
  repo="$(ghq list | fzf --query "$BUFFER")" || return
  [ -n "$repo" ] || return

  local dir
  dir="$(ghq list --full-path --exact "$repo")" || return
  [ -n "$dir" ] || return

  cd "$dir"
  zle reset-prompt 2>/dev/null || true
}

zle -N ghq-fzf-cd
bindkey -M viins '^]' ghq-fzf-cd
bindkey -M vicmd '^]' ghq-fzf-cd

# fzf でファイルを選び、コマンドラインへ挿入する。
function fzf-insert-file() {
  if ! command -v fzf >/dev/null 2>&1; then
    echo "fzf-insert-file: fzf is not installed" >&2
    return 1
  fi

  local selected
  selected="$(eval "${FZF_DEFAULT_COMMAND:-find . -type f}" | fzf --multi)" || return
  [ -n "$selected" ] || return

  local -a files
  files=("${(@f)selected}")
  LBUFFER+="${(j: :)${(q)files[@]}}"
  zle reset-prompt
}

zle -N fzf-insert-file
bindkey -M viins '^G' fzf-insert-file
bindkey -M vicmd '^G' fzf-insert-file

# fzf でファイルを選び、EDITOR で開く。
function fzf-open-in-editor() {
  if ! command -v fzf >/dev/null 2>&1; then
    echo "fzf-open-in-editor: fzf is not installed" >&2
    return 1
  fi

  local selected
  selected="$(eval "${FZF_DEFAULT_COMMAND:-find . -type f}" | fzf --multi)" || return
  [ -n "$selected" ] || return

  local editor="${EDITOR:-vim}"
  local -a editor_cmd files
  editor_cmd=("${(@z)editor}")
  files=("${(@f)selected}")

  zle -I
  command "${editor_cmd[@]}" "${files[@]}"
  zle reset-prompt
}

zle -N fzf-open-in-editor
bindkey -M viins '^O' fzf-open-in-editor
bindkey -M vicmd '^O' fzf-open-in-editor

# zsh / fish / bash の履歴をまとめて fzf 検索する。
# fzf がない場合は zsh 標準の Ctrl-r 履歴検索へ fallback する。
function history-fzf-all() {
  if ! command -v fzf >/dev/null 2>&1; then
    zle history-incremental-search-backward
    return
  fi

  local selected
  selected="$(
    {
      # zsh history。fc は古い順で出し、最後に fzf --tac で新しい順に見せる。
      fc -l 1 2>/dev/null | sed 's/^[[:space:]]*[0-9]\+[[:space:]]*//'

      # fish history。fish が無い環境では静かにスキップする。
      if command -v fish >/dev/null 2>&1; then
        fish -c 'history' 2>/dev/null
      fi

      # bash history。タイムスタンプ行は除外する。
      if [ -r "$HOME/.bash_history" ]; then
        sed '/^#[0-9]\+$/d; /^[[:space:]]*$/d' "$HOME/.bash_history"
      fi
    } | awk 'NF && !seen[$0]++' | fzf --tac --query "$LBUFFER"
  )" || return

  [ -n "$selected" ] || return
  LBUFFER="$selected"
  zle reset-prompt
}

zle -N history-fzf-all
bindkey -M viins '^R' history-fzf-all
bindkey -M vicmd '^R' history-fzf-all


# ------------------------------------------------------------
# SSH helpers
# ------------------------------------------------------------

# 通常の ssh も WezTerm SSH wrapper 経由へ寄せる。
# これにより `ssh host` だけでも背景色、タブ色、右上表示、ログ保存、入室時確認が動く。
# 例外的に戻したい環境では ~/.zshrc.local で ZSHRC_WRAP_SSH_WITH_WEZTERM=0 にする。
# vagrant ssh も別 profile で wrapper 経由にする。
ZSHRC_WRAP_SSH_WITH_WEZTERM="${ZSHRC_WRAP_SSH_WITH_WEZTERM:-1}"
ZSHRC_WRAP_VAGRANT_SSH_WITH_WEZTERM="${ZSHRC_WRAP_VAGRANT_SSH_WITH_WEZTERM:-1}"
export WEZTERM_SSH_LOG_DIR="${WEZTERM_SSH_LOG_DIR:-$HOME/.local/share/wezterm/ssh-logs}"
export LESSCHARSET="${LESSCHARSET:-utf-8}"

# ssh config の Host 名規約から WezTerm SSH profile を自動判定する。
# 例: Host prod-db01 / db01-prod / app.prod は prod profile になる。
# 追加したい場合は ~/.zshrc.local で配列を上書きまたは追記する。
typeset -ga ZSHRC_SSH_PROD_PATTERNS
typeset -ga ZSHRC_SSH_STAGING_PATTERNS
typeset -ga ZSHRC_SSH_LAB_PATTERNS
typeset -ga ZSHRC_SSH_DEV_PATTERNS

if (( ${#ZSHRC_SSH_PROD_PATTERNS[@]} == 0 )); then
  ZSHRC_SSH_PROD_PATTERNS=('prod-*' '*-prod' '*.prod' 'production-*' '*-production')
fi

if (( ${#ZSHRC_SSH_STAGING_PATTERNS[@]} == 0 )); then
  ZSHRC_SSH_STAGING_PATTERNS=('stg-*' '*-stg' 'staging-*' '*-staging' '*.stg' '*.staging')
fi

if (( ${#ZSHRC_SSH_LAB_PATTERNS[@]} == 0 )); then
  ZSHRC_SSH_LAB_PATTERNS=('lab-*' '*-lab' '*.lab')
fi

if (( ${#ZSHRC_SSH_DEV_PATTERNS[@]} == 0 )); then
  ZSHRC_SSH_DEV_PATTERNS=('dev-*' '*-dev' '*.dev')
fi

function ssh-log() {
  if ! command -v wezterm-ssh-log >/dev/null 2>&1; then
    echo "ssh-log: wezterm-ssh-log is not installed in PATH" >&2
    return 1
  fi

  wezterm-ssh-log "$@"
}

function ssh-prod() {
  ssh-log --profile prod "$@"
}

function ssh-staging() {
  ssh-log --profile staging "$@"
}

function ssh-lab() {
  ssh-log --profile lab "$@"
}

function ssh-dev() {
  ssh-log --profile dev "$@"
}

function ssh-nolog() {
  ssh-log --no-log "$@"
}

function ssh-noprobe() {
  ssh-log --no-probe "$@"
}

function zshrc_ssh_option_takes_value() {
  case "$1" in
    -b|-c|-D|-E|-e|-F|-I|-i|-J|-L|-l|-m|-O|-o|-p|-Q|-R|-S|-W|-w)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

function zshrc_ssh_find_target() {
  local arg
  local skip_next=0

  for arg in "$@"; do
    if [[ "$skip_next" -eq 1 ]]; then
      skip_next=0
      continue
    fi

    case "$arg" in
      --)
        continue
        ;;
      -*)
        if zshrc_ssh_option_takes_value "$arg"; then
          skip_next=1
        fi
        ;;
      *)
        print -r -- "$arg"
        return 0
        ;;
    esac
  done
}

function zshrc_ssh_target_matches_patterns() {
  local target="$1"
  shift

  local pattern
  for pattern in "$@"; do
    if [[ "$target" == ${~pattern} ]]; then
      return 0
    fi
  done

  return 1
}

function zshrc_ssh_profile_for_args() {
  local target
  target="$(zshrc_ssh_find_target "$@")"

  if [[ -z "$target" ]]; then
    print -r -- default
    return 0
  fi

  if zshrc_ssh_target_matches_patterns "$target" "${ZSHRC_SSH_PROD_PATTERNS[@]}"; then
    print -r -- prod
    return 0
  fi

  if zshrc_ssh_target_matches_patterns "$target" "${ZSHRC_SSH_STAGING_PATTERNS[@]}"; then
    print -r -- staging
    return 0
  fi

  if zshrc_ssh_target_matches_patterns "$target" "${ZSHRC_SSH_LAB_PATTERNS[@]}"; then
    print -r -- lab
    return 0
  fi

  if zshrc_ssh_target_matches_patterns "$target" "${ZSHRC_SSH_DEV_PATTERNS[@]}"; then
    print -r -- dev
    return 0
  fi

  print -r -- default
}

function ssh-log-latest() {
  local log_dir="${1:-$WEZTERM_SSH_LOG_DIR}"

  if [[ ! -d "$log_dir" ]]; then
    echo "ssh-log-latest: log directory not found: $log_dir" >&2
    return 1
  fi

  find "$log_dir" -type f -name '*.log' -print 2>/dev/null \
    | while IFS= read -r log_file; do
        printf '%s\t%s\n' "$(stat -f '%m' "$log_file" 2>/dev/null || stat -c '%Y' "$log_file" 2>/dev/null)" "$log_file"
      done \
    | sort -nr \
    | sed -n '1s/^[^	]*	//p'
}

function ssh-log-view() {
  local log_file="${1:-$(ssh-log-latest)}"

  if [[ -z "$log_file" || ! -f "$log_file" ]]; then
    echo "ssh-log-view: log file not found" >&2
    return 1
  fi

  LESSCHARSET=utf-8 LESSUTFBINFMT='*' LESSBINFMT='*' less -R "$log_file"
}

function ssh-log-clean() {
  local log_file="${1:-$(ssh-log-latest)}"

  if [[ -z "$log_file" || ! -f "$log_file" ]]; then
    echo "ssh-log-clean: log file not found" >&2
    return 1
  fi

  perl -CSDA -Mutf8 -pe '
    s/\e\][^\a]*(?:\a|\e\\)//g;          # OSC: title / cwd / file:// metadata
    s/\e\[[0-?]*[ -\/]*[@-~]//g;         # CSI: color / cursor movement
    s/\e[()][0-9A-Za-z]//g;              # charset switching
    s/\e[@-Z\\-_]//g;                    # other 7-bit escape sequences
    s/\r/\n/g;                           # CR shows up as ^M in script logs
    s/\a//g;                             # BEL shows up as ^G
    1 while s/[^\n]\x08//g;              # backspace editing
    s/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]//g;
    s/[\x{E000}-\x{F8FF}]//g;            # Nerd Font / private-use glyphs
    s/\n{3,}/\n\n/g;
  ' "$log_file" | LESSCHARSET=utf-8 less
}

alias slog='ssh-log-view'
alias slog-clean='ssh-log-clean'

if [ "$ZSHRC_WRAP_SSH_WITH_WEZTERM" = "1" ]; then
  function ssh() {
    local ssh_profile

    if ! command -v wezterm-ssh-log >/dev/null 2>&1; then
      command ssh "$@"
      return $?
    fi

    ssh_profile="$(zshrc_ssh_profile_for_args "$@")"
    wezterm-ssh-log --profile "$ssh_profile" "$@"
  }
fi


# ------------------------------------------------------------
# Vagrant helpers
# ------------------------------------------------------------

# Vagrant の状態確認を短くする。
# Oh My Zsh の vagrant plugin がある場合は補完や alias も追加される。
if command -v vagrant >/dev/null 2>&1; then
  alias vs='vagrant status'
  alias vgs='vagrant global-status --prune'
fi

function vagrant() {
  if [[ "$ZSHRC_WRAP_VAGRANT_SSH_WITH_WEZTERM" != "1" || "${1:-}" != "ssh" ]]; then
    command vagrant "$@"
    return $?
  fi

  if ! command -v wezterm-ssh-log >/dev/null 2>&1; then
    command vagrant "$@"
    return $?
  fi

  shift

  local machine=""
  local -a ssh_extra_args=()
  local -a vagrant_fallback_args=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --)
        shift
        ssh_extra_args=("$@")
        break
        ;;
      -*)
        # 複雑な vagrant ssh option は Vagrant 本体へ任せる。
        vagrant_fallback_args=(ssh)
        [[ -n "$machine" ]] && vagrant_fallback_args+=("$machine")
        vagrant_fallback_args+=("$@")
        command vagrant "${vagrant_fallback_args[@]}"
        return $?
        ;;
      *)
        if [[ -z "$machine" ]]; then
          machine="$1"
          shift
        else
          vagrant_fallback_args=(ssh "$machine" "$@")
          command vagrant "${vagrant_fallback_args[@]}"
          return $?
        fi
        ;;
    esac
  done

  local ssh_config_file
  ssh_config_file="$(mktemp "${TMPDIR:-/tmp}/vagrant-ssh-config.XXXXXX")" || return 1

  local vagrant_ssh_status
  if [[ -n "$machine" ]]; then
    command vagrant ssh-config "$machine" >| "$ssh_config_file"
    vagrant_ssh_status=$?
  else
    command vagrant ssh-config >| "$ssh_config_file"
    vagrant_ssh_status=$?
  fi

  if [[ "$vagrant_ssh_status" -ne 0 ]]; then
    rm -f "$ssh_config_file"
    return "$vagrant_ssh_status"
  fi

  local host_alias
  host_alias="$(awk 'tolower($1) == "host" { print $2; exit }' "$ssh_config_file")"
  [[ -n "$host_alias" ]] || host_alias="default"

  local display_name
  display_name="vagrant-${PWD:t}"
  if [[ -n "$machine" ]]; then
    display_name="${display_name}-${machine}"
  fi

  wezterm-ssh-log --profile vagrant --name "$display_name" -- -F "$ssh_config_file" "${ssh_extra_args[@]}" "$host_alias"
  vagrant_ssh_status=$?
  rm -f "$ssh_config_file"
  return "$vagrant_ssh_status"
}


# ------------------------------------------------------------
# 色
# ------------------------------------------------------------

# ls や補完候補の色。
# macOS は LSCOLORS、Linux/WSL は LS_COLORS を使う。
if [ "$ZSHRC_OS" = "macos" ]; then
  export LSCOLORS='exfxcxdxbxegedabagacad'
fi

if command -v dircolors >/dev/null 2>&1; then
  eval "$(dircolors -b)"
else
  export LS_COLORS='di=34:ln=35:so=32:pi=33:ex=31:bd=46;34:cd=43;34:su=41;30:sg=46;30:tw=42;30:ow=43;30'
fi

zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}


# ------------------------------------------------------------
# zsh-autosuggestions
# ------------------------------------------------------------

# fish 風に、入力中のコマンドへ薄い候補を出す。
# 入っている場合だけ読み込むため、未インストール環境でもエラーにしない。
# zsh-syntax-highlighting より前に読み込む。
zsh_autosuggestions_paths=(
  /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
  /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh
  /home/linuxbrew/.linuxbrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
  /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
  "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"
)

# 履歴を優先し、必要なら補完候補も使ってサジェストする。
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# 入力中の候補は控えめなグレーで表示する。
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=244'

# 可能なら非同期で候補を計算して、入力の引っかかりを減らす。
ZSH_AUTOSUGGEST_USE_ASYNC=true

for zsh_plugin_file in "${zsh_autosuggestions_paths[@]}"; do
  if [ -r "$zsh_plugin_file" ]; then
    source "$zsh_plugin_file"
    break
  fi
done

# fish に近い操作感として、Ctrl-f でサジェストを確定する。
if (( ${+widgets[autosuggest-accept]} )); then
  bindkey -M viins '^F' autosuggest-accept
  bindkey -M vicmd '^F' autosuggest-accept
fi

# autosuggestion が薄く表示されている時は Tab でも候補を確定する。
# 表示中の候補がない時は、通常の Tab 補完または fzf-tab に戻す。
function zshrc-tab-or-autosuggest() {
  if [[ -n "$POSTDISPLAY" ]] && (( ${+widgets[autosuggest-accept]} )); then
    zle autosuggest-accept
    return
  fi

  if (( ${+widgets[fzf-tab-complete]} )); then
    zle fzf-tab-complete
  else
    zle expand-or-complete
  fi
}

zle -N zshrc-tab-or-autosuggest
bindkey -M viins '^I' zshrc-tab-or-autosuggest

unset zsh_plugin_file zsh_autosuggestions_paths


# ------------------------------------------------------------
# zsh-syntax-highlighting
# ------------------------------------------------------------

# 入っている場合だけ読み込む。
# Homebrew / Linuxbrew / 手動 clone の代表的な場所を見る。
zsh_syntax_highlighting_paths=(
  /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
  /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
  /home/linuxbrew/.linuxbrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
  /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
  "$HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
)

for zsh_plugin_file in "${zsh_syntax_highlighting_paths[@]}"; do
  if [ -r "$zsh_plugin_file" ]; then
    source "$zsh_plugin_file"
    break
  fi
done

unset zsh_plugin_file zsh_syntax_highlighting_paths


# ------------------------------------------------------------
# zsh-abbr
# ------------------------------------------------------------

# fish の abbr 相当。短い入力をスペースや Enter で展開できる。
# 既定では plugin を読み込むだけ。略語は ~/.zshrc.local に書くと管理しやすい。
zsh_abbr_paths=(
  /opt/homebrew/share/zsh-abbr/zsh-abbr.zsh
  /usr/local/share/zsh-abbr/zsh-abbr.zsh
  /home/linuxbrew/.linuxbrew/share/zsh-abbr/zsh-abbr.zsh
  "$HOME/.zsh/zsh-abbr/zsh-abbr.zsh"
)

for zsh_plugin_file in "${zsh_abbr_paths[@]}"; do
  if [ -r "$zsh_plugin_file" ]; then
    source "$zsh_plugin_file"
    break
  fi
done

# 略語の例。必要なら ~/.zshrc.local に同じ形式で追加する。
# abbr g git
# abbr gs git status
# abbr gc git commit
# abbr gco git checkout

unset zsh_plugin_file zsh_abbr_paths


# ------------------------------------------------------------
# Terminal title optional
# ------------------------------------------------------------

# 保留: ターミナルタイトルを zsh 側から更新する。
# WezTerm 側で SSH 接続先名や profile を表示する設計とぶつかりやすいため、
# 現時点では無効化しておく。
#
# autoload -Uz add-zsh-hook
#
# function zshrc_update_title() {
#   print -Pn "\e]0;%n@%m:%~\a"
# }
#
# add-zsh-hook precmd zshrc_update_title
# add-zsh-hook chpwd zshrc_update_title


# ------------------------------------------------------------
# starship
# ------------------------------------------------------------

# fish で欲しかった情報表示は starship に任せる。
# Git ブランチ、pyenv/Python バージョン、実行時間などをまとめて表示できる。
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi


# ------------------------------------------------------------
# 個人用の追加設定
# ------------------------------------------------------------

# このファイルに書きたくない秘密情報やマシン固有設定はここへ。
if [ -r "$HOME/.zshrc.local" ]; then
  source "$HOME/.zshrc.local"
fi
