#!/usr/bin/env sh
set -eu

# zsh setup installer for macOS / WSL / Linux.
# - Backs up existing files before copying.
# - Installs config files by default.
# - Installs external tools only when --install-tools is passed.

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
CONFIG_DIR="$SCRIPT_DIR/config"
BIN_DIR="$SCRIPT_DIR/bin"

INSTALL_TOOLS=0
DRY_RUN=0
FORCE=0
ONLY=all

usage() {
  cat <<'EOF'
Usage:
  ./install.sh [options]

Options:
  --install-tools  Install recommended tools with brew or apt when available.
  --dry-run        Print actions without changing files.
  --force          Overwrite without asking. Existing files are still backed up.
  --only TARGET    Install only one target: all, zsh, starship, wezterm, vim.
  -h, --help       Show this help.

Installed config files:
  config/zsh/.zshrc              -> ~/.zshrc
  config/vim/.vimrc              -> ~/.vimrc
  config/starship/starship.toml  -> ~/.config/starship.toml
  config/wezterm/*.lua           -> ~/.config/wezterm/*.lua
  bin/wezterm-login-shell        -> ~/bin/wezterm-login-shell
  bin/wezterm-ssh-log            -> ~/bin/wezterm-ssh-log
  bin/ssh-*                      -> ~/bin/ssh-*

Notes:
  External tools are optional. The .zshrc has guards, so missing tools do not
  cause shell startup errors.
EOF
}

log() {
  printf '%s\n' "$*"
}

run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '[dry-run] %s\n' "$*"
  else
    "$@"
  fi
}

confirm() {
  if [ "$FORCE" -eq 1 ]; then
    return 0
  fi

  printf '%s [y/N] ' "$1"
  read answer
  case "$answer" in
    y|Y|yes|YES)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

backup_file() {
  target=$1
  if [ ! -e "$target" ] && [ ! -L "$target" ]; then
    return 0
  fi

  timestamp=$(date '+%Y%m%d-%H%M%S')
  backup="${target}.backup.${timestamp}"
  log "Backup: $target -> $backup"
  run cp -p "$target" "$backup"
}

install_file() {
  source_file=$1
  target_file=$2
  target_dir=$(dirname -- "$target_file")

  if [ ! -f "$source_file" ]; then
    log "Missing source file: $source_file"
    exit 1
  fi

  if [ -e "$target_file" ] || [ -L "$target_file" ]; then
    if ! confirm "Overwrite $target_file?"; then
      log "Skip: $target_file"
      return 0
    fi
    backup_file "$target_file"
  fi

  log "Install: $source_file -> $target_file"
  run mkdir -p "$target_dir"
  run cp "$source_file" "$target_file"
}

detect_os() {
  os_name=$(uname -s 2>/dev/null || printf unknown)
  case "$os_name" in
    Darwin)
      printf macos
      ;;
    Linux)
      if grep -qi microsoft /proc/version 2>/dev/null; then
        printf wsl
      else
        printf linux
      fi
      ;;
    *)
      printf unknown
      ;;
  esac
}

install_tools_with_brew() {
  log "Installing recommended tools with brew..."
  run brew install \
    zsh-syntax-highlighting \
    zsh-autosuggestions \
    zsh-completions \
    fzf \
    zoxide \
    ripgrep \
    fd \
    eza \
    bat \
    vim \
    starship \
    pyenv \
    rbenv \
    ghq \
    direnv \
    atuin \
    hashicorp/tap/terraform
}

install_tools_with_apt() {
  log "Installing available tools with apt..."
  run sudo apt update
  run sudo apt install -y \
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
    vim \
    xclip \
    xsel

  log "apt package names may differ by distro. Install starship, zoxide, pyenv, rbenv, ghq, atuin, and terraform separately if unavailable."
}

install_zsh_plugin_repos() {
  if ! command -v git >/dev/null 2>&1; then
    log "git is not installed. Skipping zsh plugin clone."
    return 0
  fi

  run mkdir -p "$HOME/.zsh"

  if [ ! -d "$HOME/.zsh/fzf-tab" ]; then
    log "Installing fzf-tab..."
    run git clone --depth=1 https://github.com/Aloxaf/fzf-tab "$HOME/.zsh/fzf-tab"
  else
    log "fzf-tab is already installed: $HOME/.zsh/fzf-tab"
  fi

  if [ ! -d "$HOME/.zsh/zsh-abbr" ]; then
    log "Installing zsh-abbr..."
    run git clone --depth=1 --recurse-submodules --shallow-submodules https://github.com/olets/zsh-abbr "$HOME/.zsh/zsh-abbr"
  else
    log "zsh-abbr is already installed: $HOME/.zsh/zsh-abbr"
    run git -C "$HOME/.zsh/zsh-abbr" submodule update --init --recursive --depth=1
  fi
}

install_oh_my_zsh() {
  if [ -d "$HOME/.oh-my-zsh" ]; then
    log "Oh My Zsh is already installed: $HOME/.oh-my-zsh"
    return 0
  fi

  if ! command -v git >/dev/null 2>&1; then
    log "git is not installed. Skipping Oh My Zsh clone."
    return 0
  fi

  log "Installing Oh My Zsh by git clone..."
  run git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
}

install_tools() {
  if command -v brew >/dev/null 2>&1; then
    install_tools_with_brew
    install_oh_my_zsh
    install_zsh_plugin_repos
    return 0
  fi

  if command -v apt >/dev/null 2>&1; then
    install_tools_with_apt
    install_oh_my_zsh
    install_zsh_plugin_repos
    return 0
  fi

  log "No supported package manager found. Install tools manually."
  log "See docs/plugins_install_guide.md"
  install_oh_my_zsh
  install_zsh_plugin_repos
}

post_check() {
  log ""
  log "Post-check:"

  if [ "$ONLY" = "all" ] || [ "$ONLY" = "zsh" ]; then
    if command -v zsh >/dev/null 2>&1; then
      run zsh -n "$HOME/.zshrc"
    else
      log "zsh is not installed or not in PATH."
    fi
  fi

  if [ "$ONLY" = "all" ] || [ "$ONLY" = "starship" ]; then
    if command -v starship >/dev/null 2>&1; then
      log "starship: $(starship --version 2>/dev/null || printf installed)"
    else
      log "starship is not installed. Prompt config will be skipped by .zshrc."
    fi
  fi

  if [ "$ONLY" = "all" ] || [ "$ONLY" = "wezterm" ]; then
    if command -v luac >/dev/null 2>&1; then
      run luac -p "$HOME/.config/wezterm/wezterm.lua"
      run luac -p "$HOME/.config/wezterm/keybinds.lua"
      run luac -p "$HOME/.config/wezterm/ssh_profiles.lua"
    else
      log "luac is not installed. Skipping WezTerm Lua syntax check."
    fi
  fi

  if [ "$ONLY" = "all" ] || [ "$ONLY" = "vim" ]; then
    if command -v vim >/dev/null 2>&1; then
      run vim -Nu "$HOME/.vimrc" -n -es -c 'q'
    else
      log "vim is not installed or not in PATH."
    fi
  fi

  log ""
  log "Done. Start a new shell with:"
  log "  exec zsh"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --install-tools)
      INSTALL_TOOLS=1
      ;;
    --dry-run)
      DRY_RUN=1
      ;;
    --force)
      FORCE=1
      ;;
    --only)
      ONLY="${2:-}"
      case "$ONLY" in
        all|zsh|starship|wezterm|vim)
          shift
          ;;
        *)
          log "Invalid --only target: $ONLY"
          usage
          exit 2
          ;;
      esac
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      log "Unknown option: $1"
      usage
      exit 2
      ;;
  esac
  shift
done

OS=$(detect_os)
log "Detected OS: $OS"

if [ "$INSTALL_TOOLS" -eq 1 ]; then
  install_tools
else
  log "Skip tool installation. Pass --install-tools to install recommended tools."
fi

if [ "$ONLY" = "all" ] || [ "$ONLY" = "zsh" ]; then
  install_file "$CONFIG_DIR/zsh/.zshrc" "$HOME/.zshrc"
fi

if [ "$ONLY" = "all" ] || [ "$ONLY" = "vim" ]; then
  install_file "$CONFIG_DIR/vim/.vimrc" "$HOME/.vimrc"
  run mkdir -p "$HOME/.vimbackup"
fi

if [ "$ONLY" = "all" ] || [ "$ONLY" = "starship" ]; then
  install_file "$CONFIG_DIR/starship/starship.toml" "$HOME/.config/starship.toml"
fi

if [ "$ONLY" = "all" ] || [ "$ONLY" = "wezterm" ]; then
  install_file "$CONFIG_DIR/wezterm/wezterm.lua" "$HOME/.config/wezterm/wezterm.lua"
  install_file "$CONFIG_DIR/wezterm/keybinds.lua" "$HOME/.config/wezterm/keybinds.lua"
  install_file "$CONFIG_DIR/wezterm/ssh_profiles.lua" "$HOME/.config/wezterm/ssh_profiles.lua"

  if [ -f "$BIN_DIR/wezterm-login-shell" ]; then
    install_file "$BIN_DIR/wezterm-login-shell" "$HOME/bin/wezterm-login-shell"
    run chmod +x "$HOME/bin/wezterm-login-shell"
  fi

  if [ -f "$BIN_DIR/wezterm-ssh-log" ]; then
    install_file "$BIN_DIR/wezterm-ssh-log" "$HOME/bin/wezterm-ssh-log"
    run chmod +x "$HOME/bin/wezterm-ssh-log"
  fi

  for shortcut in ssh-log ssh-prod ssh-staging ssh-lab ssh-dev ssh-nolog ssh-noprobe; do
    if [ -f "$BIN_DIR/$shortcut" ]; then
      install_file "$BIN_DIR/$shortcut" "$HOME/bin/$shortcut"
      run chmod +x "$HOME/bin/$shortcut"
    fi
  done
fi

post_check
