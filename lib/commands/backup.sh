#!/usr/bin/env bash

# Load dependencies
source "${BASH_SOURCE%/*}/../utils/logger.sh"

# Load configuration
load_tracked_files() {
  echo "=== DEBUG: Starting load_tracked_files function ===" >&2
  echo "Current user: $(whoami)" >&2
  echo "Current directory: $(pwd)" >&2
  
  # Get the script's directory
  local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
  echo "Script directory: $script_dir" >&2
  
  # Use hardcoded absolute path to config file
  local config_file="/home/richao/repositories/dotfiles/config/tracked_files.conf"
  echo "Config file: $config_file" >&2
  
  # Check if file exists and is readable
  if [ ! -f "$config_file" ]; then
    echo "ERROR: Configuration file not found at: $config_file" >&2
    echo "Directory contents: $(ls -la $(dirname "$config_file") 2>&1)" >&2
    return 1
  fi
  
  if [ ! -r "$config_file" ]; then
    echo "ERROR: Cannot read configuration file: $config_file" >&2
    echo "File permissions: $(ls -l "$config_file" 2>&1)" >&2
    return 1
  fi
  
  echo "File exists and is readable" >&2
  
  # Source the config file
  echo "Sourcing config file..." >&2
  if ! source "$config_file"; then
    echo "ERROR: Failed to source configuration from $config_file" >&2
    return 1
  fi
  
  # Verify variables are set
  if [ ${#TRACKED_FILES[@]} -eq 0 ]; then
    echo "WARNING: TRACKED_FILES is empty" >&2
  else
    echo "Found ${#TRACKED_FILES[@]} tracked files" >&2
  fi
  
  if [ ${#SYSTEM_CONFIGS[@]} -eq 0 ]; then
    echo "WARNING: SYSTEM_CONFIGS is empty" >&2
  else
    echo "Found ${#SYSTEM_CONFIGS[@]} system configs" >&2
  fi
  
  # Copy the tracked files to the output array
  local -n files_array=$1
  
  # Add user files from TRACKED_FILES
  for file in "${!TRACKED_FILES[@]}"; do
    if [ -e "$file" ] || [ -L "$file" ]; then
      files_array+=("$file")
      echo "Added to backup: $file" >&2
    else
      echo "Skipping non-existent file: $file" >&2
    fi
  done
  
  # Add system files from SYSTEM_CONFIGS
  for file in "${SYSTEM_CONFIGS[@]}"; do
    if [ -e "$file" ] || [ -L "$file" ]; then
      files_array+=("$file")
      echo "Added system config to backup: $file" >&2
    else
      echo "Skipping non-existent system config: $file" >&2
    fi
  done
  
  echo "=== DEBUG: Finished load_tracked_files function ===" >&2
}

# Backup existing files
backup() {
  local src="$1"
  local dest="$2"

  if [ ! -e "$src" ]; then
    debug "Source file does not exist, nothing to backup: $src"
    return 0
  fi

  # Create backup directory if it doesn't exist
  create_dir "$(dirname "$dest")"

  # Backup file or directory
  if [ -e "$dest" ]; then
    local backup_file="${dest}.bak.$(date +%s)"
    mv "$dest" "$backup_file"
    info "Backed up existing file to: $backup_file"
  fi

  # Move the original to backup location
  if mv "$src" "$dest"; then
    debug "Moved $src to $dest for backup"
    return 0
  else
    error "Failed to backup $src to $dest"
    return 1
  fi
}

# Backup system configuration files
backup_system_config() {
  # Load backup utilities
  source "${BASH_SOURCE%/*}/../utils/backup_utils.sh"
  
  # Set backup type
  export BACKUP_TYPE="system_config"
  
  # Load tracked files from configuration
  local files_to_backup=()
  
  info "Loading tracked files configuration..."
  
  if ! load_tracked_files files_to_backup; then
    error "Failed to load tracked files configuration"
    return 1
  fi
  
  if [ ${#files_to_backup[@]} -eq 0 ]; then
    error "No files to back up"
    return 1
  fi
  
  # Create backup using the utility function
  local backup_path
  backup_path=$(create_backup_archive "${files_to_backup[@]}")
  
  if [ $? -eq 0 ]; then
    success "System configuration backup completed: $backup_path"
    local backup_size=$(du -h "$backup_path" | cut -f1)
    info "Backup size: $backup_size"
  else
    error "Failed to create system configuration backup"
    return 1
  fi
}

export -f backup backup_system_config
