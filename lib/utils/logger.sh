#!/usr/bin/env bash

# Load colors
source "${BASH_SOURCE%/*}/../config/colors.sh"

# Logging functions
error() { printf "%b\n" "${RED}ERROR: $1${NC}" >&2; }
warn() { printf "%b\n" "${YELLOW}WARN: $1${NC}" >&2; }
success() { printf "%b\n" "${GREEN}SUCCESS: $1${NC}"; }
info() { printf "%b\n" "${BLUE}INFO: $1${NC}"; }
debug() { 
  if [ "$VERBOSE" -eq 1 ] || [ -n "$DEBUG" ]; then 
    printf "%b\n" "${MAGENTA}DEBUG: $1${NC}" >&2; 
  fi 
}
trace() { [ "$VERBOSE" -eq 1 ] && printf "%b\n" "${CYAN}TRACE: $1${NC}" >&2; }

# Check if running as root
check_root() {
  if [ "$EUID" -eq 0 ]; then
    error "This script should not be run as root"
    exit 1
  fi
}

# Verify dependencies
check_dependencies() {
  local required=("git" "rsync" "ln")
  local missing=()
  local retries=3
  local delay=2

  # Check dependencies
  for dep in "${required[@]}"; do
    if ! command -v "$dep" &>/dev/null; then
      missing+=("$dep")
    fi
  done

  if [ ${#missing[@]} -gt 0 ]; then
    error "Missing dependencies: ${missing[*]}"

    # Attempt to install missing dependencies with retries
    local attempt=1
    while [ $attempt -le $retries ]; do
      info "Attempt $attempt/$retries: Installing missing dependencies..."
      if sudo pacman -S --noconfirm "${missing[@]}"; then
        success "Dependencies installed successfully"
        return 0
      else
        warn "Attempt $attempt failed. Retrying in $delay seconds..."
        sleep $delay
        attempt=$((attempt + 1))
      fi
    done

    error "Failed to install dependencies after $retries attempts"
    exit 1
  fi
}

# Create directory if it doesn't exist
create_dir() {
  local dir="$1"
  if [ ! -d "$dir" ]; then
    mkdir -p "$dir"
    debug "Created directory: $dir"
  fi
}

# Cleanup function
cleanup() {
  local temp_dir="/tmp/dotfiles-tmp-$$"
  if [ -d "$temp_dir" ]; then
    rm -rf "$temp_dir"
  fi
  trap - EXIT
}

# Set up trap for cleanup
setup_cleanup() {
  trap cleanup EXIT INT TERM
}

export -f error warn success info debug trace check_root check_dependencies create_dir cleanup setup_cleanup
