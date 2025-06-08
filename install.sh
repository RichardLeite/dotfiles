#!/usr/bin/env bash

#===============================================================================
# dotfiles.sh - Dotfiles Management Script for Arch Linux with Hyprland
#===============================================================================
# This script helps manage dotfiles by:
# 1. Initializing a dotfiles repository with existing configs
# 2. Installing/symlinking dotfiles from the repository to the system
# 3. Updating the repository with the latest local changes
# 4. Backing up existing configs before overwriting
#
# Author: Richard C.
# Created: June 2025
#===============================================================================

# Exit on error
set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script variables
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"
CONFIG_DIR="$HOME/.config"
VERBOSE=0
FORCE=0

# Configuration file mapping (source:destination)
# These are relative paths from the dotfiles repo to the home directory
declare -A HOME_CONFIG_FILES=(
  ["zshrc"]=".zshrc"
  ["bashrc"]=".bashrc"
  ["p10k.zsh"]=".p10k.zsh"
)

# Configuration directories mapping (source:destination)
# These are relative paths from the dotfiles repo to the ~/.config directory
declare -A CONFIG_DIRS=(
  ["hypr"]="hypr"
  ["kitty"]="kitty"
  ["cava"]="cava"
  ["warp-terminal"]="warp-terminal"
  ["matugen"]="matugen"
  ["sddm"]="sddm"
)

#===============================================================================
# Helper Functions
#===============================================================================

# Print usage information
usage() {
  echo -e "${BLUE}Usage:${NC} $0 [options] command"
  echo
  echo -e "${BLUE}Commands:${NC}"
  echo "  init       Initialize dotfiles repository with existing configs"
  echo "  install    Install/symlink dotfiles to the system"
  echo "  update     Update repository with latest local changes"
  echo "  list       List managed dotfiles"
  echo "  help       Show this help message"
  echo
  echo -e "${BLUE}Options:${NC}"
  echo "  -v, --verbose   Enable verbose output"
  echo "  -f, --force     Force overwrite without confirmation"
  echo "  -h, --help      Show this help message"
  echo
  echo -e "${BLUE}Examples:${NC}"
  echo "  $0 init             # Initialize repository with existing configs"
  echo "  $0 install          # Install dotfiles to system"
  echo "  $0 update           # Update repository with local changes"
  echo "  $0 -f install       # Force install without confirmation"
  echo
}

# Print log message
log() {
  local level="$1"
  local message="$2"
  local color=""

  case "$level" in
  "info") color="${GREEN}" ;;
  "warn") color="${YELLOW}" ;;
  "error") color="${RED}" ;;
  "debug") color="${CYAN}" ;;
  *) color="${NC}" ;;
  esac

  # Only show debug messages when verbose is enabled
  if [[ "$level" == "debug" && "$VERBOSE" -eq 0 ]]; then
    return
  fi

  echo -e "${color}[${level^^}]${NC} $message"
}

# Check if running on Arch Linux
check_arch_linux() {
  if [ -f /etc/arch-release ]; then
    log "info" "Running on Arch Linux"
  else
    log "warn" "This script is designed for Arch Linux but you're running on $(cat /etc/os-release | grep "PRETTY_NAME" | cut -d= -f2 | tr -d '"')"
    read -p "Continue anyway? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      log "error" "Aborted"
      exit 1
    fi
  fi
}

# Check required dependencies and install if missing
check_dependencies() {
  local deps=("git" "ln" "rsync")
  local missing=()
  local installed=()

  # Check which dependencies are missing
  for dep in "${deps[@]}"; do
    if ! command -v "$dep" &>/dev/null; then
      missing+=("$dep")
    else
      installed+=("$dep")
    fi
  done

  if [ ${#missing[@]} -gt 0 ]; then
    log "warn" "Missing dependencies: ${missing[*]}"
    log "info" "Installing missing dependencies..."

    # Run sudo pacman -S with the missing dependencies
    if sudo pacman -S --noconfirm "${missing[@]}"; then
      log "info" "Dependencies installed successfully"
    else
      log "error" "Failed to install dependencies"
      exit 1
    fi
  fi

  if [ ${#installed[@]} -gt 0 ]; then
    log "info" "Already installed: ${installed[*]}"
  fi

  log "info" "All required dependencies are installed"
}

# Backup a file or directory using rsync
backup() {
  local path="$1"
  local backup_path="${BACKUP_DIR}${path}"

  if [ ! -e "$path" ]; then
    log "debug" "Nothing to backup at $path"
    return 0
  fi

  # Create backup directory structure
  mkdir -p "$(dirname "$backup_path")"

  # Use rsync for efficient backup
  rsync -av --delete "$path" "$backup_path"
  log "info" "Backed up $path to $backup_path"
}

# Create directory if it doesn't exist
create_dir() {
  local dir="$1"
  if [ ! -d "$dir" ]; then
    mkdir -p "$dir"
    log "debug" "Created directory: $dir"
  fi
}

# Copy a file or directory
copy_file() {
  local source="$1"
  local destination="$2"

  # Check if source exists
  if [ ! -e "$source" ]; then
    log "error" "Source does not exist: $source"
    return 1
  fi

  # Check if destination already exists
  if [ -e "$destination" ]; then
    # If force is not enabled, ask for confirmation
    if [ "$FORCE" -eq 0 ]; then
      log "warn" "$destination already exists"
      read -p "Overwrite? [y/N] " -n 1 -r
      echo
      if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "info" "Skipping $destination"
        return 0
      fi
    fi

    # Backup the existing file/directory
    backup "$destination"

    # Remove the existing file/directory
    rm -rf "$destination"
  fi

  # Create parent directory
  create_dir "$(dirname "$destination")"

  # Copy using rsync for better efficiency
  rsync -av "$source" "$destination"
  log "info" "Copied $source to $destination"
}

# Copy file to dotfiles repository
copy_to_repo() {
  local source="$1"
  local dest="$2"
  local repo_path="$DOTFILES_DIR/config/$dest"
  local system_path="$CONFIG_DIR/$source"

  if [ ! -e "$system_path" ]; then
    log "error" "Source does not exist: $system_path"
    return 1
  fi

  create_dir "$(dirname "$repo_path")"

  # Copy using rsync for better efficiency
  rsync -av "$system_path" "$repo_path"
  log "info" "Copied $system_path to $repo_path"
}

# Install base packages and dependencies
install_base_packages() {
  log "info" "Installing base packages..."

  # Essential packages from official repositories
  local official_packages=(
    "base-devel"
    "hyprland"
    "hyprlock"
    "hypridle"
    "sddm"
    "kitty"
    "nautilus"
    "zsh"
    "ttf-jetbrains-mono"
    "ttf-fira-code"
    "ttf-hack"
    "ttf-roboto"
    "gst-plugins-base"
    "gst-plugins-good"
    "gst-plugins-bad"
    "gst-plugins-ugly"
    "gst-libav"
  )

  # Install official packages
  if sudo pacman -S --noconfirm "${official_packages[@]}"; then

    # Install powerlevel10k font assets if not already installed
    if [ ! -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k-media" ]; then
      log "info" "Installing powerlevel10k font assets..."
      git clone --depth=1 https://github.com/romkatv/powerlevel10k-media.git "$HOME/.oh-my-zsh/custom/themes/powerlevel10k-media"
    fi

    log "success" "Base packages installed successfully"
  else
    log "error" "Failed to install base packages"
    exit 1
  fi

  # AUR packages
  local aur_packages=(
    "ttf-source-code-pro"
    "ttf-consolas"
    "ttf-monaco"
    "ttf-meslo-nerd-font"
    "warp-terminal-bin"
    "microsoft-edge-stable-bin"
  )

  # Install yay if not already installed
  if ! command -v yay &>/dev/null; then
    log "info" "Installing yay..."

    sudo pacman -S --noconfirm base-devel

    # Clone yay repository
    git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin
    cd /tmp/yay-bin

    # Build and install yay
    makepkg -si --noconfirm

    # Clean up
    cd - >/dev/null
    rm -rf /tmp/yay-bin
  fi

  # Install AUR packages
  log "info" "Installing AUR packages..."
  yay -S --noconfirm "${aur_packages[@]}"

  # Install oh-my-zsh and powerlevel10k if not already installed
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    log "info" "Installing oh-my-zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  fi

  if [ ! -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]; then
    log "info" "Installing powerlevel10k..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
  fi

  # Set zsh as default shell
  if [ "$SHELL" != "/usr/bin/zsh" ]; then
    log "info" "Setting zsh as default shell..."
    chsh -s /usr/bin/zsh
  fi

  # Install Ax-Shell if not already installed
  if [ ! -d "$HOME/.config/Ax-Shell" ]; then
    log "info" "Installing Ax-Shell..."
    curl -fsSL https://raw.githubusercontent.com/Axenide/Ax-Shell/main/install.sh | bash
  fi

  # Configure SDDM for Hyprland
  log "info" "Configuring SDDM for Hyprland..."

  # Create SDDM configuration directory if it doesn't exist
  sudo mkdir -p /etc/sddm.conf.d

  # Create SDDM configuration
  sudo tee /etc/sddm.conf.d/hyprland.conf >/dev/null <<'EOF'
[General]
Current=Hyprland

[Theme]
Current=breeze

[X11]
ServerArguments=-nolisten tcp

[Autologin]
User=$USER
Session=Hyprland
EOF

  # Create Hyprland session file
  # Create xsessions directory if it doesn't exist
  sudo mkdir -p /usr/share/xsessions
  sudo tee /usr/share/xsessions/hyprland.desktop >/dev/null <<'EOF'
[Desktop Entry]
Name=Hyprland
Comment=Hyprland
Exec=hyprland
TryExec=hyprland
Type=Application
Keywords=wayland;window manager;hyprland;
EOF

  # Create Hyprlock service file
  sudo tee /etc/systemd/system/hyprlock.service >/dev/null <<'EOF'
[Unit]
Description=Hyprlock Service
After=display-manager.service

[Service]
Type=oneshot
ExecStart=/usr/bin/hyprlock

[Install]
WantedBy=display-manager.service
EOF

  # Enable Hyprlock service
  sudo systemctl enable hyprlock.service

  log "success" "SDDM configured for Hyprland with Hyprlock"
}

#===============================================================================
# Main Functions
#===============================================================================

# Initialize dotfiles repository with existing configs
init_dotfiles() {
  log "info" "Initializing dotfiles repository..."

  # Create repository structure
  mkdir -p "$DOTFILES_DIR/home"
  mkdir -p "$DOTFILES_DIR/config"

  # Copy home config files
  for src in "${!HOME_CONFIG_FILES[@]}"; do
    local dest="${HOME_CONFIG_FILES[$src]}"
    local system_path="$HOME/$dest"
    local repo_path="$DOTFILES_DIR/home/$src"

    if [ -e "$system_path" ]; then
      copy_to_repo "$system_path" "$repo_path"
    else
      log "warn" "File not found: $system_path"
    fi
  done

  # Copy config directories
  for src in "${!CONFIG_DIRS[@]}"; do
    local dest="${CONFIG_DIRS[$src]}"
    local system_path="$CONFIG_DIR/$dest"
    local repo_path="$DOTFILES_DIR/config/$src"

    if [ -e "$system_path" ]; then
      copy_to_repo "$system_path" "$repo_path"
    else
      log "warn" "Directory not found: $system_path"
    fi
  done

  log "info" "Repository initialized at $DOTFILES_DIR"
  log "info" "You might want to commit the changes:"
  log "info" "git -C \"$DOTFILES_DIR\" add ."
  log "info" "git -C \"$DOTFILES_DIR\" commit -m \"Initial commit\""
}

# Copy dotfiles to the system
install_dotfiles() {
  log "info" "Copying dotfiles..."

  # Create backup directory
  mkdir -p "$BACKUP_DIR"

  # Copy home config files
  for src in "${!HOME_CONFIG_FILES[@]}"; do
    local dest="${HOME_CONFIG_FILES[$src]}"
    local repo_path="$DOTFILES_DIR/home/$src"
    local system_path="$HOME/$dest"

    if [ -e "$repo_path" ]; then
      copy_file "$repo_path" "$system_path"
    else
      log "warn" "File not found in repository: $repo_path"
    fi
  done

  # Copy config directories
  for src in "${!CONFIG_DIRS[@]}"; do
    local dest="${CONFIG_DIRS[$src]}"
    local repo_path="$DOTFILES_DIR/config/$src"
    local system_path="$CONFIG_DIR/$dest"

    if [ -e "$repo_path" ]; then
      copy_file "$repo_path" "$system_path"
    else
      log "warn" "Directory not found in repository: $repo_path"
    fi
  done

  # Copy Ax-Shell config separately
  local ax_shell_config_repo="$DOTFILES_DIR/config/Ax-Shell/config/config.json"
  local ax_shell_config_system="$CONFIG_DIR/Ax-Shell/config/config.json"

  if [ -e "$ax_shell_config_repo" ]; then
    copy_file "$ax_shell_config_repo" "$ax_shell_config_system"
  else
    log "warn" "Ax-Shell config not found in repository: $ax_shell_config_repo"
  fi

  # Set up SDDM for Hyprland
  log "info" "Setting up SDDM for Hyprland..."

  # Create SDDM configuration directory if it doesn't exist
  sudo mkdir -p /etc/sddm.conf.d

  # Backup existing SDDM config if it exists
  local system_sddm_conf="/etc/sddm.conf.d/wayland.conf"
  if [ -e "$system_sddm_conf" ]; then
    backup "$system_sddm_conf"
  fi

  # Create SDDM configuration
  sudo tee "$system_sddm_conf" >/dev/null <<'EOF'
[General]
DisplayServer=wayland

[Wayland]
SessionDir=/usr/share/wayland-sessions

[Autologin]
User=$(whoami)
Session=hyprland.desktop
Relogin=false
EOF

  log "info" "SDDM configured for Hyprland"

  # Enable SDDM service
  log "info" "Enabling SDDM service..."
  sudo systemctl enable sddm.service

  log "info" "Dotfiles installation complete"
}

# Update repository with latest local changes
update_repo() {
  log "info" "Updating repository with latest local changes..."

  # Update home config files
  for src in "${!HOME_CONFIG_FILES[@]}"; do
    local dest="${HOME_CONFIG_FILES[$src]}"
    local system_path="$HOME/$dest"
    local repo_path="$DOTFILES_DIR/home/$dest"

    # Only update if it's not a symlink (meaning it wasn't installed by this script)
    # or if the symlink doesn't point to our repo
    if [ -e "$system_path" ] && { [ ! -L "$system_path" ] || [ "$(readlink -f "$system_path")" != "$(readlink -f "$repo_path")" ]; }; then
      copy_to_repo "$system_path" "$repo_path"
    fi
  done

  # Update config directories
  for src in "${!CONFIG_DIRS[@]}"; do
    local dest="${CONFIG_DIRS[$src]}"
    local system_path="$CONFIG_DIR/$dest"
    local repo_path="$DOTFILES_DIR/config/$src"

    # Only update if it's not a symlink (meaning it wasn't installed by this script)
    # or if the symlink doesn't point to our repo
    if [ -e "$system_path" ] && { [ ! -L "$system_path" ] || [ "$(readlink -f "$system_path")" != "$(readlink -f "$repo_path")" ]; }; then
      # Remove old copy in repo if it exists
      if [ -e "$repo_path" ]; then
        rm -rf "$repo_path"
      fi
      copy_to_repo "$system_path" "$repo_path"
    fi
  done

  # Update Ax-Shell config separately
  local ax_shell_config_system="$CONFIG_DIR/Ax-Shell/config/config.json"
  local ax_shell_config_repo="$DOTFILES_DIR/config/Ax-Shell/config/config.json"

  # Only update if it's not a symlink (meaning it wasn't installed by this script)
  # or if the symlink doesn't point to our repo
  if [ -e "$ax_shell_config_system" ] && { [ ! -L "$ax_shell_config_system" ] || [ "$(readlink -f "$ax_shell_config_system")" != "$(readlink -f "$ax_shell_config_repo")" ]; }; then
    # Remove old copy in repo if it exists
    if [ -e "$ax_shell_config_repo" ]; then
      rm -rf "$ax_shell_config_repo"
    fi
    copy_to_repo "$ax_shell_config_system" "$ax_shell_config_repo"
  fi

  log "info" "Repository update complete"
  log "info" "You might want to commit the changes:"
  log "info" "git -C \"$DOTFILES_DIR\" add ."
  log "info" "git -C \"$DOTFILES_DIR\" commit -m \"Update dotfiles\""
}

# List managed dotfiles
list_dotfiles() {
  log "info" "Managed home config files:"
  for src in "${!HOME_CONFIG_FILES[@]}"; do
    local dest="${HOME_CONFIG_FILES[$src]}"
    local repo_path="$DOTFILES_DIR/home/$src"
    local system_path="$HOME/$dest"

    if [ -e "$repo_path" ]; then
      echo -e "${BLUE}$system_path${NC} -> ${GREEN}$repo_path${NC}"
    else
      echo -e "${BLUE}$system_path${NC} -> ${RED}Not in repository${NC}"
    fi
  done

  echo
  log "info" "Managed config directories:"
  for src in "${!CONFIG_DIRS[@]}"; do
    local dest="${CONFIG_DIRS[$src]}"
    local repo_path="$DOTFILES_DIR/config/$src"
    local system_path="$CONFIG_DIR/$dest"

    if [ -e "$repo_path" ]; then
      echo -e "${BLUE}$system_path${NC} -> ${GREEN}$repo_path${NC}"
    else
      echo -e "${BLUE}$system_path${NC} -> ${RED}Not in repository${NC}"
    fi
  done
}

#===============================================================================
# Main Script
#===============================================================================

# Parse command-line options
while [[ $# -gt 0 ]]; do
  case "$1" in
  -v | --verbose)
    VERBOSE=1
    shift
    ;;
  -f | --force)
    FORCE=1
    shift
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  init | install | update | list | help)
    COMMAND="$1"
    shift
    ;;
  *)
    log "error" "Unknown option: $1"
    usage
    exit 1
    ;;
  esac
done

# Set default command to install if none specified
COMMAND=${COMMAND:-"install"}

# Execute the command
case "$COMMAND" in
init)
  check_arch_linux
  check_dependencies
  init_dotfiles
  ;;
install)
  check_arch_linux
  check_dependencies
  install_base_packages
  install_dotfiles
  ;;
update)
  check_arch_linux
  check_dependencies
  update_repo
  ;;
list)
  list_dotfiles
  ;;
help)
  usage
  ;;
*)
  log "error" "Unknown command: $COMMAND"
  usage
  exit 1
  ;;
esac

exit 0
