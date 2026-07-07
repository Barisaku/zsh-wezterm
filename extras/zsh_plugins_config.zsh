# zsh plugin config blocks
# 古い .zshrc に一部だけ移植したい時の参考 block。
#
# 完成版の設定は config/zsh/.zshrc に統合済み。
# 通常はこのファイルではなく install.sh と config/zsh/.zshrc を使う。
#
# 使い方:
# - PRE-COMPINIT ブロックは compinit より前に置く。
# - POST-COMPINIT ブロックは compinit より後に置く。
# - LAST ブロックは .zshrc のかなり最後、starship より前に置く。


# ------------------------------------------------------------
# PRE-COMPINIT: zsh-completions
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


# ------------------------------------------------------------
# POST-COMPINIT: fzf
# ------------------------------------------------------------

# fzf の key bindings / fuzzy completion を有効化する。
# 新しい fzf では fzf --zsh が使える。
if command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh)
fi

# fzf の見た目と挙動。
# ripgrep があれば Ctrl-T などの候補を .gitignore 尊重の高速検索にする。
export FZF_DEFAULT_OPTS="
  --height=40%
  --layout=reverse
  --border
  --info=inline
"

if command -v rg >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/*"'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi


# ------------------------------------------------------------
# POST-COMPINIT: zoxide
# ------------------------------------------------------------

# zoxide は賢い cd。
# z / zi コマンドを追加する。補完のため compinit より後に置く。
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi


# ------------------------------------------------------------
# POST-COMPINIT: zsh-autosuggestions
# ------------------------------------------------------------

# fish 風の履歴ベースの薄い候補表示。
# Vim mode でも使いやすいよう、右矢印で採用できる設定にする。
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_USE_ASYNC=true
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
ZSH_AUTOSUGGEST_ACCEPT_WIDGETS=(
  forward-char
  end-of-line
  vi-forward-char
  vi-end-of-line
)

zsh_autosuggestions_paths=(
  /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
  /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh
  /home/linuxbrew/.linuxbrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
  /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
  "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"
)

for zsh_plugin_file in "${zsh_autosuggestions_paths[@]}"; do
  if [ -r "$zsh_plugin_file" ]; then
    source "$zsh_plugin_file"
    break
  fi
done

unset zsh_plugin_file zsh_autosuggestions_paths


# ------------------------------------------------------------
# Optional CLI aliases
# ------------------------------------------------------------

# eza があれば ls 系を少し見やすくする。
# 使い勝手が変わるので、不要ならこのブロックを外す。
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --group-directories-first'
  alias ll='eza -lh --group-directories-first --git'
  alias la='eza -a --group-directories-first'
  alias lla='eza -lha --group-directories-first --git'
  alias tree='eza --tree --group-directories-first'
fi

# bat があれば cat を置き換えず、読みやすい別名を用意する。
if command -v bat >/dev/null 2>&1; then
  alias catp='bat --paging=never'
  alias less='bat'
elif command -v batcat >/dev/null 2>&1; then
  alias bat='batcat'
  alias catp='batcat --paging=never'
  alias less='batcat'
fi

# fd があれば短い find alias を用意する。
if command -v fd >/dev/null 2>&1; then
  alias f='fd'
elif command -v fdfind >/dev/null 2>&1; then
  alias fd='fdfind'
  alias f='fdfind'
fi

# ripgrep があれば grep 用途の短い alias を用意する。
if command -v rg >/dev/null 2>&1; then
  alias r='rg'
fi


# ------------------------------------------------------------
# LAST: zsh-syntax-highlighting
# ------------------------------------------------------------

# zsh-syntax-highlighting は zle widget 定義の後、なるべく最後に読み込む。
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
