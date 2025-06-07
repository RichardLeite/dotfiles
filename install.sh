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
  ["Ax-Shell"]="Ax-Shell"
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
  local deps=("git" "ln" "mkdir" "cp")
  local missing=()
  
  # Check which dependencies are missing
  for dep in "${deps[@]}"; do
    if ! command -v "$dep" &> /dev/null; then
      missing+=("$dep")
    fi
  done
  
  # If there are missing dependencies, install them
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
  
  log "info" "All required dependencies are installed"
}

# Backup a file or directory
backup() {
  local path="$1"
  local backup_path="${BACKUP_DIR}${path}"
  
  # If the file/directory doesn't exist, no need to back up
  if [ ! -e "$path" ]; then
    log "debug" "Nothing to backup at $path"
    return 0
  fi
  
  # Create the backup directory structure
  mkdir -p "$(dirname "$backup_path")"
  
  # Copy the file/directory
  cp -r "$path" "$backup_path"
  log "info" "Backed up $path to $backup_path"
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
  
  # Create the parent directory if it doesn't exist
  mkdir -p "$(dirname "$destination")"
  
  # Copy the file/directory
  if [ -d "$source" ]; then
    cp -rT "$source" "$destination"
  else
    cp "$source" "$destination"
  fi
  log "info" "Copied: $source -> $destination"
}

# Copy file to dotfiles repository
copy_to_repo() {
  local source="$1"
  local repo_destination="$2"
  
  # Check if source exists
  if [ ! -e "$source" ]; then
    log "warn" "Source does not exist: $source"
    return 1
  fi
  
  # Create the parent directory in the repo if it doesn't exist
  mkdir -p "$(dirname "$repo_destination")"
  
  # Copy files and directories
  if [ -f "$source" ]; then
    cp -p "$source" "$repo_destination"
    log "info" "Copied file $source to $repo_destination"
  elif [ -d "$source" ]; then
    # For directories, create it in the repo
    mkdir -p "$repo_destination"
    log "info" "Created directory $repo_destination"
    
    # Copy only the contents of the directory
    cp -rp "$source"/* "$repo_destination/" 2>/dev/null || true
    cp -rp "$source"/.* "$repo_destination/" 2>/dev/null || true
  fi
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
  )
  
  # Install yay if not already installed
  if ! command -v yay &> /dev/null; then
    log "info" "Installing yay..."

    sudo pacman -S --noconfirm base-devel
    
    # Clone yay repository
    git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin
    cd /tmp/yay-bin
    
    # Build and install yay
    makepkg -si --noconfirm
    
    # Clean up
    cd - > /dev/null
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
  
  # Set up SDDM for Hyprland
  if [ -d "/etc/sddm.conf.d" ]; then
    log "info" "Setting up SDDM for Hyprland..."
    
    # Create SDDM config directory in repo if it doesn't exist
    mkdir -p "$DOTFILES_DIR/config/sddm/sddm.conf.d"
    
    # Create or update wayland.conf for SDDM
    local sddm_wayland_conf="$DOTFILES_DIR/config/sddm/sddm.conf.d/wayland.conf"
    echo "[General]" > "$sddm_wayland_conf"
    echo "DisplayServer=wayland" >> "$sddm_wayland_conf"
    echo "" >> "$sddm_wayland_conf"
    echo "[Wayland]" >> "$sddm_wayland_conf"
    echo "SessionDir=/usr/share/wayland-sessions" >> "$sddm_wayland_conf"
    echo "" >> "$sddm_wayland_conf"
    echo "[Autologin]" >> "$sddm_wayland_conf"
    echo "User=$(whoami)" >> "$sddm_wayland_conf"
    echo "Session=hyprland.desktop" >> "$sddm_wayland_conf"
    echo "Relogin=false" >> "$sddm_wayland_conf"
    
    # Check if /etc/sddm.conf.d/wayland.conf already exists
    local system_sddm_wayland_conf="/etc/sddm.conf.d/wayland.conf"
    if [ -e "$system_sddm_wayland_conf" ]; then
      # Backup the existing file
      backup "$system_sddm_wayland_conf"
    fi
    
    # Create the destination directory if it doesn't exist
    if [ ! -d "/etc/sddm.conf.d" ]; then
      sudo mkdir -p "/etc/sddm.conf.d"
    fi
    
    # Copy the file to the system with sudo
    sudo cp "$sddm_wayland_conf" "$system_sddm_wayland_conf"
    log "info" "SDDM configured for Hyprland"
    
    # Enable SDDM service
    log "info" "Enabling SDDM service..."
    sudo systemctl enable sddm.service
  fi
  
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
    -v|--verbose)
      VERBOSE=1
      shift
      ;;
    -f|--force)
      FORCE=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    init|install|update|list|help)
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

# Check if a command was provided
if [ -z "${COMMAND:-}" ]; then
  log "error" "No command specified"
  usage
  exit 1
fi

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

