#!/usr/bin/env bash
set -euo pipefail

# ─── Colors ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC}   $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# ─── Detect OS ────────────────────────────────────────────────────────────────
OS="$(uname -s)"
case "$OS" in
  Darwin) PLATFORM="macos" ;;
  Linux)  PLATFORM="linux" ;;
  *)      error "Unsupported OS: $OS"; exit 1 ;;
esac
info "Platform: $PLATFORM"

DOTFILES_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"

# ─── Helpers ──────────────────────────────────────────────────────────────────
command_exists() { command -v "$1" &>/dev/null; }

# ─── macOS: Homebrew ──────────────────────────────────────────────────────────
install_homebrew() {
  if command_exists brew; then
    success "Homebrew already installed"
    return
  fi
  info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Add brew to PATH for Apple Silicon
  if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
  success "Homebrew installed"
}

install_brew_packages() {
  info "Installing Homebrew packages from Brewfile..."
  # Install only brew/cask entries (skip 'go' lines — handled separately)
  grep -E '^(brew|cask) ' "$DOTFILES_DIR/Brewfile" | while read -r line; do
    pkg=$(echo "$line" | awk '{print $2}' | tr -d '"')
    type=$(echo "$line" | awk '{print $1}')
    if [[ "$type" == "cask" ]]; then
      if brew list --cask "$pkg" &>/dev/null 2>&1; then
        success "Cask $pkg already installed"
      else
        info "Installing cask: $pkg"
        brew install --cask "$pkg" || warn "Failed to install cask: $pkg"
      fi
    else
      if brew list "$pkg" &>/dev/null 2>&1; then
        success "$pkg already installed"
      else
        info "Installing: $pkg"
        brew install "$pkg" || warn "Failed to install: $pkg"
      fi
    fi
  done
}

# ─── Linux: apt ───────────────────────────────────────────────────────────────
install_linux_packages() {
  info "Updating apt package list..."
  sudo apt-get update -qq

  local pkgs
  pkgs=(
    git
    curl
    wget
    unzip
    build-essential
    stow
    tmux
    zsh
  )

  for pkg in "${pkgs[@]}"; do
    if dpkg -s "$pkg" &>/dev/null 2>&1; then
      success "$pkg already installed"
    else
      info "Installing: $pkg"
      sudo apt-get install -y "$pkg" || warn "Failed to install: $pkg"
    fi
  done
}

install_neovim_linux() {
  if command_exists nvim; then
    success "Neovim already installed ($(nvim --version | head -1))"
    return
  fi
  info "Installing Neovim (latest stable appimage)..."
  local tmp
  tmp=$(mktemp -d)
  curl -Lo "$tmp/nvim.appimage" \
    "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage"
  chmod +x "$tmp/nvim.appimage"
  "$tmp/nvim.appimage" --appimage-extract --target "$tmp/nvim-squash" &>/dev/null
  sudo mkdir -p /opt/nvim
  sudo cp -r "$tmp/nvim-squash/"* /opt/nvim/
  sudo ln -sf /opt/nvim/usr/bin/nvim /usr/local/bin/nvim
  rm -rf "$tmp"
  success "Neovim installed"
}

install_go_linux() {
  if command_exists go; then
    success "Go already installed ($(go version))"
    return
  fi
  info "Installing Go (latest stable)..."
  local go_version
  go_version=$(curl -fsSL "https://go.dev/VERSION?m=text" | head -1)
  local archive="${go_version}.linux-amd64.tar.gz"
  curl -Lo /tmp/"$archive" "https://dl.google.com/go/$archive"
  sudo rm -rf /usr/local/go
  sudo tar -C /usr/local -xzf /tmp/"$archive"
  rm /tmp/"$archive"
  export PATH="$PATH:/usr/local/go/bin"
  success "Go installed: $(go version)"
}

install_docker_linux() {
  if command_exists docker; then
    success "Docker already installed"
    return
  fi
  info "Installing Docker Engine..."
  curl -fsSL https://get.docker.com | sudo sh
  sudo usermod -aG docker "$USER"
  success "Docker installed (re-login required for group to take effect)"
}

# ─── Go tools (both platforms) ────────────────────────────────────────────────
install_go_tools() {
  if ! command_exists go; then
    warn "Go not found, skipping Go tools"
    return
  fi
  info "Installing Go tools from Brewfile..."
  grep '^go ' "$DOTFILES_DIR/Brewfile" | while read -r _ pkg; do
    pkg=$(echo "$pkg" | tr -d '"')
    info "go install $pkg@latest"
    go install "${pkg}@latest" || warn "Failed: go install $pkg"
  done
  success "Go tools installed"
}

# ─── Oh My Zsh ────────────────────────────────────────────────────────────────
install_ohmyzsh() {
  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    success "Oh My Zsh already installed"
    return
  fi
  info "Installing Oh My Zsh..."
  RUNZSH=no CHSH=no sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  success "Oh My Zsh installed"
}

# ─── Powerlevel10k ────────────────────────────────────────────────────────────
install_p10k() {
  local p10k_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
  if [[ -d "$p10k_dir" ]]; then
    success "Powerlevel10k already installed"
    return
  fi
  info "Installing Powerlevel10k..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir"
  success "Powerlevel10k installed"
}

# ─── Zsh plugins ──────────────────────────────────────────────────────────────
install_zsh_plugins() {
  local custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"

  if [[ ! -d "$custom/zsh-syntax-highlighting" ]]; then
    info "Installing zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
      "$custom/zsh-syntax-highlighting"
    success "zsh-syntax-highlighting installed"
  else
    success "zsh-syntax-highlighting already installed"
  fi

  if [[ ! -d "$custom/zsh-autosuggestions" ]]; then
    info "Installing zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions.git \
      "$custom/zsh-autosuggestions"
    success "zsh-autosuggestions installed"
  else
    success "zsh-autosuggestions already installed"
  fi
}

# ─── NVM ──────────────────────────────────────────────────────────────────────
install_nvm() {
  if [[ -d "$HOME/.nvm" ]]; then
    success "NVM already installed"
    return
  fi
  info "Installing NVM..."
  local nvm_version
  nvm_version=$(curl -fsSL https://api.github.com/repos/nvm-sh/nvm/releases/latest \
    | grep '"tag_name"' | cut -d'"' -f4)
  curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${nvm_version}/install.sh" | bash
  success "NVM installed"
}

# ─── Tmux Plugin Manager ──────────────────────────────────────────────────────
install_tpm() {
  if [[ -d "$HOME/.tmux/plugins/tpm" ]]; then
    success "TPM already installed"
    return
  fi
  info "Installing Tmux Plugin Manager..."
  git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
  success "TPM installed (run prefix+I inside tmux to install plugins)"
}

# ─── Stow dotfiles ────────────────────────────────────────────────────────────
stow_dotfiles() {
  if ! command_exists stow; then
    warn "stow not found, skipping dotfile symlinking"
    return
  fi
  info "Stowing dotfiles..."
  cd "$DOTFILES_DIR"
  # Stow everything (creates symlinks in $HOME)
  stow --target="$HOME" --restow . 2>/dev/null || \
    stow --target="$HOME" --adopt . && git checkout . \
    || warn "stow encountered conflicts — check manually"
  success "Dotfiles symlinked"
}

# ─── Set default shell to zsh ─────────────────────────────────────────────────
set_default_shell() {
  local zsh_path
  zsh_path=$(command -v zsh)
  if [[ "$SHELL" == "$zsh_path" ]]; then
    success "Default shell is already zsh"
    return
  fi
  info "Setting default shell to zsh..."
  if ! grep -q "$zsh_path" /etc/shells; then
    echo "$zsh_path" | sudo tee -a /etc/shells
  fi
  chsh -s "$zsh_path"
  success "Default shell set to zsh"
}

# ─── Main ─────────────────────────────────────────────────────────────────────
main() {
  echo ""
  echo -e "${BLUE}╔══════════════════════════════════╗${NC}"
  echo -e "${BLUE}║     dotfiles installer           ║${NC}"
  echo -e "${BLUE}╚══════════════════════════════════╝${NC}"
  echo ""

  if [[ "$PLATFORM" == "macos" ]]; then
    install_homebrew
    install_brew_packages
  else
    install_linux_packages
    install_neovim_linux
    install_go_linux
    install_docker_linux
  fi

  install_go_tools
  install_ohmyzsh
  install_p10k
  install_zsh_plugins
  install_nvm
  install_tpm
  stow_dotfiles
  set_default_shell

  echo ""
  success "All done! Start a new shell session to apply changes."
  if [[ "$PLATFORM" == "linux" ]]; then
    warn "Docker: log out and back in for group membership to apply."
  fi
  warn "Tmux: open tmux and press prefix+I to install plugins."
  warn "Neovim: run 'nvim' to trigger Lazy.nvim plugin installation."
  echo ""
}

main "$@"
