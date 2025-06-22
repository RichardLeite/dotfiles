#!/usr/bin/env bash

# ===========================================================================
# Dotfiles Management Script
# ===========================================================================
# This script helps manage dotfiles with a modular structure following SOLID
# principles. Each major functionality is separated into its own module.
# ===========================================================================
# Author: Richard Leite.
# Created: June 2025
# ===========================================================================

# ---------------------------------------------------------------------------
# Load logger first
# ---------------------------------------------------------------------------
# Get the directory where this script is located (this is our dotfiles directory)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="${DOTFILES_DIR:-$SCRIPT_DIR}"

# Load logger
source "${DOTFILES_DIR}/lib/utils/logger.sh"

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
# Set default values
VERBOSE=0
FORCE=0
DEBUG=0

# Ensure consistent backup location
DOTFILES_BACKUP_DIR="${DOTFILES_DIR}/backups"

# Use absolute path for backup directory
if [ -z "$BACKUP_DIR" ]; then
  BACKUP_DIR="$DOTFILES_BACKUP_DIR"
fi

# Ensure BACKUP_DIR is absolute
case "$BACKUP_DIR" in
  /*) # Already absolute
    ;;
  *)  # Relative path, make it absolute
    BACKUP_DIR="$(cd "$BACKUP_DIR" 2>/dev/null && pwd || echo "$DOTFILES_BACKUP_DIR")"
    ;;
esac

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR" 2>/dev/null || {
  # Fallback to home directory if we can't create the backup directory
  BACKUP_DIR="$HOME/.dotfiles_backup"
  mkdir -p "$BACKUP_DIR" 2>/dev/null || {
    error "Failed to create backup directory: $BACKUP_DIR"
    exit 1
  }
  warn "Using fallback backup directory: $BACKUP_DIR"
}

CACHE_DIR="${CACHE_DIR:-$HOME/.cache/dotfiles}"

# Create cache directory if it doesn't exist
mkdir -p "$CACHE_DIR" 2>/dev/null || {
  warn "Failed to create cache directory: $CACHE_DIR"
  CACHE_DIR="/tmp/dotfiles-cache-$(id -u)"
  mkdir -p "$CACHE_DIR" 2>/dev/null || {
    error "Failed to create cache directory: $CACHE_DIR"
    exit 1
  }
  warn "Using fallback cache directory: $CACHE_DIR"
}

export BACKUP_DIR

# ---------------------------------------------------------------------------
# Import modules
# ---------------------------------------------------------------------------
# Load logger
source "${DOTFILES_DIR}/lib/utils/logger.sh"

# Load configuration
source "$SCRIPT_DIR/lib/config/colors.sh"

# Load utilities
source "${DOTFILES_DIR}/lib/utils/backup_utils.sh"

# Load commands
source "$SCRIPT_DIR/lib/commands/backup.sh"
source "$SCRIPT_DIR/lib/commands/file_operations.sh"
source "$SCRIPT_DIR/lib/commands/dotfiles.sh"
source "$SCRIPT_DIR/lib/commands/packages.sh"

# ---------------------------------------------------------------------------
# Command line arguments
# ---------------------------------------------------------------------------
# Process command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
  -v | --verbose)
    VERBOSE=1
    shift
    ;;
  -d | --debug)
    DEBUG=1
    VERBOSE=1 # Debug also enables verbose
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
  init)
    CMD="init"
    shift
    ;;
  install)
    CMD="install"
    shift
    ;;
  update)
    CMD="update"
    shift
    ;;
  backup)
    CMD="backup"
    shift
    ;;
  list)
    CMD="list"
    shift
    ;;
  *)
    error "Unknown argument: $1"
    usage
    exit 1
    ;;
  esac
done

# ---------------------------------------------------------------------------
# Usage information
# ---------------------------------------------------------------------------
usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS] COMMAND

Options:
  -v, --verbose   Enable verbose output
  -d, --debug     Enable debug mode (implies verbose)
  -f, --force     Force operations without confirmation
  -h, --help      Show this help message

Commands:
  init            Initialize dotfiles repository
  install         Install dotfiles
  update          Update dotfiles repository
  backup          Create backup of current configuration
  list            List managed dotfiles
  install-dev-tools  Install development tools and dotfiles managers
  menu            Show interactive menu (default if no command provided)

Examples:
  $(basename "$0") init
  $(basename "$0") install
  $(basename "$0") --verbose update
  $(basename "$0") --force backup

Environment variables:
  DOTFILES_DIR    Directory for dotfiles (default: ~/.dotfiles)
  BACKUP_DIR      Directory for backups (default: ~/.dotfiles_backup)
  CACHE_DIR       Directory for cache files (default: ~/.cache/dotfiles)
EOF
}

# ---------------------------------------------------------------------------
# Show interactive menu
# ---------------------------------------------------------------------------
show_menu() {
  while true; do
    clear
    info "=== Dotfiles Management Menu ==="
    echo "1. Install dotfiles"
    echo "2. Update dotfiles"
    echo "3. Create backup"
    echo "4. List managed files"
    echo "5. Install development tools"
    echo "6. Manage Stow modules"
    echo "0. Exit"
    echo ""
    read -rp "Enter your choice [0-6]: " choice
  
    case $choice in
      1) install_dotfiles ;;
      2) sync_new_files ;;
      3) backup_system_config ;;
      4) list_managed_files ;;
      5) install_dev_tools ;;
      6) manage_stow_modules ;;
      0) exit 0 ;;
      *) error "Invalid option. Try again." ;;
    esac

    echo ""
    read -p "Press [Enter] to continue..."
  done
}

# ---------------------------------------------------------------------------
# Main function
# ---------------------------------------------------------------------------
main() {
  # Ensure we're not running as root
  if [[ $EUID -eq 0 ]]; then
    error "This script should not be run as root"
    exit 1
  fi

  # Create cache directory if it doesn't exist
  mkdir -p "$CACHE_DIR"

  # Execute the specified command or show menu
  case "$CMD" in
  init)
    init_dotfiles
    ;;
  install)
    install_dotfiles
    ;;
  update)
    sync_new_files
    ;;
  backup)
    backup_system_config
    ;;
  list)
    list_managed_files
    ;;
  install-dev-tools)
    install_dev_tools
    ;;
  stow)
    shift  # Remove 'stow' from arguments
    "${DOTFILES_DIR}/scripts/stow" "$@"
    ;;
  menu | *)
    show_menu
    ;;
  esac
}

# ===========================================================================
# Stow Modules Management
# ===========================================================================

# Gerenciamento de módulos Stow
manage_stow_modules() {
  # Verifica se o Stow está instalado
  if ! command -v stow &> /dev/null; then
    error "GNU Stow não está instalado. Por favor, instale-o primeiro."
    return 1
  fi
  
  # Carrega as funções do Stow
  source "${DOTFILES_DIR}/lib/utils/stow_utils.sh" 2>/dev/null || {
    error "Falha ao carregar as funções do Stow"
    return 1
  }
  
  # Mostra o menu de gerenciamento do Stow
  while true; do
    clear
    info "=== Gerenciador de Módulos Stow ==="
    echo "1. Listar módulos disponíveis"
    echo "2. Aplicar módulo (stow)"
    echo "3. Remover módulo (unstow)"
    echo "4. Reaplicar módulo (restow)"
    echo "5. Migrar arquivos para o Stow"
    echo "0. Voltar ao menu principal"
    echo ""
    read -rp "Escolha uma opção [0-5]: " choice
    
    case $choice in
      1)
        echo ""
        info "Módulos disponíveis:"
        "${DOTFILES_DIR}/scripts/stow" --list
        ;;
      2)
        echo ""
        "${DOTFILES_DIR}/scripts/stow" --list
        echo ""
        read -p "Digite o nome do(s) módulo(s) para aplicar (ou 'all' para todos): " modules
        if [ "$modules" = "all" ]; then
          "${DOTFILES_DIR}/scripts/stow" --stow --all
        else
          "${DOTFILES_DIR}/scripts/stow" --stow $modules
        fi
        ;;
      3)
        echo ""
        "${DOTFILES_DIR}/scripts/stow" --list
        echo ""
        read -p "Digite o nome do(s) módulo(s) para remover (ou 'all' para todos): " modules
        if [ "$modules" = "all" ]; then
          "${DOTFILES_DIR}/scripts/stow" --delete --all
        else
          "${DOTFILES_DIR}/scripts/stow" --delete $modules
        fi
        ;;
      4)
        echo ""
        "${DOTFILES_DIR}/scripts/stow" --list
        echo ""
        read -p "Digite o nome do(s) módulo(s) para reaplicar (ou 'all' para todos): " modules
        if [ "$modules" = "all" ]; then
          "${DOTFILES_DIR}/scripts/stow" --restow --all
        else
          "${DOTFILES_DIR}/scripts/stow" --restow $modules
        fi
        ;;
      5)
        echo ""
        info "Iniciando migração para o Stow..."
        "${DOTFILES_DIR}/scripts/migrate_to_stow.sh"
        ;;
      0)
        return 0
        ;;
      *)
        error "Opção inválida. Tente novamente."
        ;;
    esac
    
    echo ""
    read -n 1 -s -r -p "Pressione qualquer tecla para continuar..."
  done
}

# ===========================================================================
# Bootstrap function - Minimal version to clone the full repository
# ===========================================================================
bootstrap_dotfiles() {
  local repo_url="https://github.com/RichardLeite/dotfiles.git"
  local target_dir="${DOTFILES_DIR:-$HOME/.dotfiles}"

  # If the directory already exists and we're not forcing, just return
  if [ -d "$target_dir" ]; then
    if [ "$FORCE" -eq 1 ]; then
      info "Removing existing directory: $target_dir"
      rm -rf "$target_dir"
    else
      info "Using existing directory: $target_dir"
      return 0
    fi
  fi

  # Check for git
  if ! command -v git &>/dev/null; then
    error "Git is required but not installed"
    return 1
  fi

  # Create parent directory if it doesn't exist
  local parent_dir="$(dirname "$target_dir")"
  if [ ! -d "$parent_dir" ]; then
    mkdir -p "$parent_dir" || {
      error "Failed to create directory: $parent_dir"
      return 1
    }
  fi

  # Clone the repository
  info "Cloning dotfiles repository to: $target_dir"
  if ! git clone "$repo_url" "$target_dir" 2>/dev/null; then
    error "Failed to clone repository from $repo_url"
    return 1
  fi

  # Create the files directory structure
  local files_dir="$target_dir/files"
  if [ ! -d "$files_dir" ]; then
    mkdir -p "$files_dir" || {
      error "Failed to create files directory: $files_dir"
      return 1
    }
  fi

  success "Repository cloned successfully to $target_dir"
  echo "Run 'cd $target_dir && ./install.sh' to continue"
  return 0
}

# ===========================================================================
# Entry Point
# ===========================================================================
# If running from a gist, bootstrap the full repository first
if [[ $(pwd) == *"gist"* ]] || [ ! -f "$SCRIPT_DIR/lib/commands/dotfiles.sh" ]; then
  if ! bootstrap_dotfiles; then
    echo "ERROR: Failed to bootstrap dotfiles repository" >&2
    exit 1
  fi
  exit 0
fi

# If we have the full repository, load all functions
if [ -f "$SCRIPT_DIR/lib/commands/dotfiles.sh" ]; then
  source "$SCRIPT_DIR/lib/commands/dotfiles.sh"
  
  # Initialize dotfiles repository before doing anything
  if ! init_dotfiles; then
    error "Failed to initialize dotfiles repository"
    exit 1
  fi
else
  error "Dotfiles repository not found at $SCRIPT_DIR"
  exit 1
fi

# Call the main function and exit with the appropriate status
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  trap 'error "Script terminated by user"; exit 1' INT
  main "$@"
  exit $?
fi
