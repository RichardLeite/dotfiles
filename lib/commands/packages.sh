#!/usr/bin/env bash

# Load dependencies
source "${BASH_SOURCE%/*}/../utils/logger.sh"

# Install base packages and dependencies
install_base_packages() {
  info "Installing base packages..."

  # Check if running on Arch Linux
  if ! command -v pacman &>/dev/null; then
    error "This script requires Arch Linux's pacman package manager"
    return 1
  fi

  # Update package database
  info "Updating package database..."
  if ! sudo pacman -Syy; then
    error "Failed to update package database"
    return 1
  fi

  # Install base packages
  local packages=(
    # Core system
    "base-devel"
    "stow"  # Para gerenciamento de dotfiles
    "git"   # Necessário para clonar repositórios
    
    # Desktop environment
    "hyprland"
    "hyprlock"
    "hypridle"
    "sddm"
    
    # Terminal and shell
    "kitty"
    "zsh"
    
    # File manager
    "nautilus"
    
    # Security
    "gnome-keyring"
    
    # Fonts
    "ttf-jetbrains-mono"
    "ttf-fira-code"
    "ttf-hack"
    "ttf-roboto"
    
    # Multimedia
    "gst-plugins-base"
    "gst-plugins-good"
    "gst-plugins-bad"
    "gst-plugins-ugly"
    "gst-libav"
    
    # System utilities
    "rsync"
  )

  # Install packages in batches to avoid argument list too long
  local batch_size=20
  for ((i = 0; i < ${#packages[@]}; i += batch_size)); do
    local batch=("${packages[@]:i:batch_size}")
    info "Installing batch of packages: ${batch[*]}"
    if ! sudo pacman -S --noconfirm --needed "${batch[@]}"; then
      warn "Failed to install some packages, continuing..."
    fi
  done

  # Enable services
  local services=(
    "sddm"
    "NetworkManager"
  )

  for service in "${services[@]}"; do
    if ! systemctl is-enabled "$service" &>/dev/null; then
      info "Enabling service: $service"
      if ! sudo systemctl enable --now "$service"; then
        warn "Failed to enable service: $service"
      fi
    fi
  done

  # Configure zsh as default shell
  if command -v zsh &>/dev/null && [ "$(basename "$SHELL")" != "zsh" ]; then
    info "Setting zsh as default shell..."
    if ! chsh -s "$(which zsh)"; then
      warn "Failed to set zsh as default shell"
    fi
  fi

  success "Base packages installation completed"
  return 0
}

# Install development and dotfiles management tools
install_dev_tools() {
  info "Installing development and dotfiles management tools..."

  # Check if running on Arch Linux
  if ! command -v pacman &>/dev/null; then
    error "This script requires Arch Linux's pacman package manager"
    return 1
  fi

  # Development and dotfiles tools
  local dev_packages=(
    # Version control
    "git"
    "github-cli"  # Para interação com o GitHub CLI
    
    # Dotfiles management
    "stow"         # Já instalado, mas incluído para referência
    "chezmoi"      # Gerenciador de dotfiles alternativo
    "rcm"          # Gerenciador de dotfiles
    
    # Ferramentas de desenvolvimento
    "neovim"
    "python-pip"
    "python-pipx"
    "shellcheck"   # Linter para shell scripts
    "shfmt"        # Formatador para shell scripts
  )

  # Install packages in batches to avoid argument list too long
  local batch_size=10
  for ((i = 0; i < ${#dev_packages[@]}; i += batch_size)); do
    local batch=("${dev_packages[@]:i:batch_size}")
    info "Installing development tools batch: ${batch[*]}"
    if ! sudo pacman -S --noconfirm --needed "${batch[@]}"; then
      warn "Failed to install some development tools, continuing..."
    fi
  done

  # Configurações pós-instalação
  if command -v pipx &>/dev/null; then
    info "Setting up pipx..."
    pipx ensurepath
  fi

  success "Development and dotfiles tools installation completed"
  return 0
}

# Install AUR helper (yay)
install_aur_helper() {
  info "Installing AUR helper (yay)..."

  if command -v yay &>/dev/null; then
    info "yay is already installed"
    return 0
  fi

  # Create temporary directory
  local temp_dir
  temp_dir=$(mktemp -d)

  # Install dependencies
  sudo pacman -S --needed --noconfirm git base-devel

  # Clone and install yay
  if git clone https://aur.archlinux.org/yay.git "$temp_dir/yay"; then
    cd "$temp_dir/yay" || return 1
    if makepkg -si --noconfirm; then
      success "yay installed successfully"
      cd - >/dev/null || return 1
      rm -rf "$temp_dir"
      return 0
    fi
  fi

  # Cleanup on failure
  error "Failed to install yay"
  cd - >/dev/null || return 1
  rm -rf "$temp_dir"
  return 1
}

# Install AUR packages
install_aur_packages() {
  if ! command -v yay &>/dev/null; then
    error "yay is not installed. Please install it first using install_aur_helper"
    return 1
  fi

  local packages=(
    # Fonts
    "ttf-source-code-pro"
    "ttf-consolas"
    "ttf-monaco"
    "ttf-meslo-nerd-font"
    # Applications
    "warp-terminal-bin"
    "microsoft-edge-stable-bin"
  )

  info "Installing AUR packages..."
  if yay -S --noconfirm --needed "${packages[@]}"; then
    success "AUR packages installed successfully"
    return 0
  else
    error "Failed to install AUR packages"
    return 1
  fi
}

export -f install_base_packages install_dev_tools install_aur_helper install_aur_packages
