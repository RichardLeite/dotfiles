#!/usr/bin/env bash

# ===========================================================================
# Backup Utilities
# ===========================================================================
# This file contains utility functions for creating and managing backups
# ===========================================================================

# Load dependencies
source "${BASH_SOURCE%/*}/logger.sh"

# Debug information
debug "=== Backup Utilities Script Started ==="
debug "Script path: ${BASH_SOURCE[0]}"
debug "Current directory: $(pwd)"
debug "BACKUP_DIR: ${BACKUP_DIR:-Not set}"
debug "BACKUP_TYPE: ${BACKUP_TYPE:-Not set}"

# ===========================================================================
# Configuration
# ===========================================================================

# Default backup directories
DEFAULT_BACKUP_DIR="${HOME}/.dotfiles_backup"
BACKUP_DIR="${BACKUP_DIR:-$DEFAULT_BACKUP_DIR}"

# ===========================================================================
# Helper Functions
# ===========================================================================

# Create a timestamp for backup files
generate_timestamp() {
  date +"%Y%m%d_%H%M%S"
}

# Create a backup directory if it doesn't exist
ensure_backup_dir() {
  local backup_type="${1:-general}"
  local timestamp=$(generate_timestamp)
  
  debug "Ensuring backup directory structure for type: $backup_type"
  
  # Create main backup directory if it doesn't exist
  debug "Creating main backup directory: $BACKUP_DIR"
  mkdir -p "$BACKUP_DIR" || {
    error "Failed to create main backup directory: $BACKUP_DIR"
    return 1
  }
  
  # Create type-specific subdirectory
  local type_dir="${BACKUP_DIR}/${backup_type}"
  debug "Creating type directory: $type_dir"
  if ! mkdir -p "$type_dir"; then
    error "Failed to create backup type directory: $type_dir"
    return 1
  fi
  
  # Create timestamped directory
  local backup_dir="${type_dir}/${timestamp}"
  debug "Creating timestamped backup directory: $backup_dir"
  if ! mkdir -p "$backup_dir"; then
    error "Failed to create backup directory: $backup_dir"
    return 1
  fi
  
  debug "Backup directory created successfully: $backup_dir"
  echo "$backup_dir"
  return 0
}

# Create a compressed tarball from a list of files
create_backup_archive() {
  local files=("$@")
  local backup_type="${BACKUP_TYPE:-general}"
  
  debug "Creating backup archive with type: $backup_type"
  debug "BACKUP_DIR is set to: $BACKUP_DIR"
  
  debug "Creating backup directory for type: $backup_type"
  local backup_dir
  backup_dir=$(ensure_backup_dir "$backup_type")
  if [ $? -ne 0 ]; then
    error "Failed to create backup directory for type: $backup_type"
    return 1
  fi
  
  debug "Backup directory created: $backup_dir"
  
  # Verify backup directory exists and is writable
  if [ ! -d "$backup_dir" ] || [ ! -w "$backup_dir" ]; then
    error "Backup directory is not accessible or writable: $backup_dir"
    return 1
  fi
  
  # Create archive name with timestamp
  local timestamp
  timestamp=$(date +"%Y%m%d_%H%M%S")
  local archive_name="${backup_type}_${timestamp}.tar.xz"
  local archive_path="${backup_dir}/${archive_name}"
  
  debug "Archive path: $archive_path"
  
  local files_found=0
  
  # Create a temporary directory for the backup
  local temp_dir=$(mktemp -d)
  
  # Copy files to the temporary directory
  for file in "${files[@]}"; do
    # Handle glob patterns
    if [[ "$file" == *"*"* ]]; then
      # Expand the glob pattern
      local matched=0
      for match in $file; do
        if [ -e "$match" ] || [ -L "$match" ]; then
          local dest_dir="${temp_dir}$(dirname "$match")"
          mkdir -p "$dest_dir"
          if cp -a "$match" "$dest_dir/"; then
            debug "Added to backup: $match"
            matched=1
            ((files_found++))
          fi
        fi
      done
      [ $matched -eq 0 ] && debug "No matches found for pattern: $file"
    # Handle regular files/directories
    elif [ -e "$file" ] || [ -L "$file" ]; then
      local dest_dir="${temp_dir}$(dirname "$file")"
      mkdir -p "$dest_dir"
      if cp -a "$file" "$dest_dir/"; then
        debug "Added to backup: $file"
        ((files_found++))
      fi
    else
      debug "Skipping non-existent file: $file"
    fi
  done
  
  # Check if any files were found
  if [ $files_found -eq 0 ]; then
    error "No files found to back up"
    rm -rf "$temp_dir"
    return 1
  fi
  
  info "Found $files_found files to back up"
  
  # Create the tarball
  (cd "$temp_dir" && tar -cJf "$archive_path" .) || {
    error "Failed to create backup archive"
    rm -rf "$temp_dir"
    return 1
  }
  
  # Clean up
  rm -rf "$temp_dir"
  
  echo "$archive_path"
  return 0
}

# ===========================================================================
# Main Backup Functions
# ===========================================================================

# Create a backup of existing dotfiles before installation
backup_existing_dotfiles() {
  info "Creating backup of existing dotfiles..."
  
  # Set backup type
  local backup_type="pre_install"
  export BACKUP_TYPE="$backup_type"
  
  # Load tracked files
  local files_to_backup=()
  local config_file="${BASH_SOURCE%/*}/../config/tracked_files.conf"
  
  if [ ! -f "$config_file" ]; then
    error "Configuration file not found: $config_file"
    return 1
  fi
  
  # Source the config file
  if ! source "$config_file"; then
    error "Failed to load configuration from: $config_file"
    return 1
  fi
  
  # Check if TRACKED_FILES is set
  if [ ${#TRACKED_FILES[@]} -eq 0 ]; then
    warn "No files are being tracked in the configuration"
    return 1
  fi
  
  info "Found ${#TRACKED_FILES[@]} tracked files in configuration"
  
  # Add user files to backup list with existence check
  local found_files=0
  for file in "${!TRACKED_FILES[@]}"; do
    if [ -e "$file" ] || [ -L "$file" ]; then
      if [ -r "$file" ] || [ -L "$file" ]; then
        files_to_backup+=("$file")
        ((found_files++))
      else
        warn "Skipping unreadable file (permission denied): $file"
      fi
    else
      debug "Tracked file not found: $file"
    fi
  done
  
  if [ $found_files -eq 0 ]; then
    error "No existing dotfiles found to back up"
    return 1
  fi
  
  info "Found $found_files existing dotfiles to back up"
  
  # Create backup
  local backup_path
  backup_path=$(create_backup_archive "${files_to_backup[@]}")
  
  if [ $? -eq 0 ] && [ -n "$backup_path" ]; then
    # Get backup size in human-readable format
    local size
    size=$(du -h "$backup_path" | cut -f1)
    success "Backup created successfully: $backup_path (${size})"
    return 0
  else
    error "Failed to create backup"
    return 1
  fi
}

# Create a backup of repository files before update
backup_repository_files() {
  info "Creating backup of repository files..."
  
  # Set backup type
  local backup_type="pre_update"
  export BACKUP_TYPE="$backup_type"
  
  # Get list of files in the repository
  local repo_root="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
  local files_dir="${repo_root}/files"
  
  if [ ! -d "$files_dir" ]; then
    error "Repository files directory not found: $files_dir"
    return 1
  fi
  
  # Count files to be backed up
  local file_count
  file_count=$(find "$files_dir" -type f | wc -l)
  
  if [ "$file_count" -eq 0 ]; then
    warn "No files found in repository directory: $files_dir"
    return 1
  fi
  
  info "Found $file_count files to back up from repository"
  
  # Create a temporary directory for the backup
  local temp_dir
  temp_dir=$(mktemp -d) || {
    error "Failed to create temporary directory"
    return 1
  }
  
  # Copy files to the temporary directory, preserving the directory structure and permissions
  info "Copying repository files to temporary directory..."
  (cd "$files_dir" && find . -type f -print0 | while IFS= read -r -d $'\0' file; do
    local dest_dir="${temp_dir}/$(dirname "$file")"
    
    # Create destination directory
    if ! mkdir -p "$dest_dir"; then
      error "Failed to create directory: $dest_dir"
      continue
    fi
    
    # Copy file
    if ! cp -a "$files_dir/$file" "$dest_dir/"; then
      error "Failed to copy file: $file"
      continue
    fi
  done)
  
  # Check if any files were copied
  local copied_files
  copied_files=$(find "$temp_dir" -type f | wc -l)
  
  if [ "$copied_files" -eq 0 ]; then
    error "No files were copied to temporary directory"
    rm -rf "$temp_dir"
    return 1
  fi
  
  info "Copied $copied_files files to temporary directory"
  
  # Get list of all files in the temp directory
  local files_to_backup=()
  while IFS= read -r -d '' file; do
    files_to_backup+=("$file")
  done < <(find "$temp_dir" -type f -print0)
  
  # Create backup using create_backup_archive
  local backup_path
  backup_path=$(create_backup_archive "${files_to_backup[@]}")
  
  # Clean up
  rm -rf "$temp_dir"
  
  if [ $? -eq 0 ] && [ -n "$backup_path" ]; then
    # Get backup size in human-readable format
    local size
    size=$(du -h "$backup_path" | cut -f1)
    success "Repository backup created successfully: $backup_path (${size})"
    return 0
  else
    error "Failed to create repository backup"
    return 1
  fi
  return 0
}

# Create a backup of system configuration files
backup_system_configs() {
  info "Creating backup of system configuration files..."
  
  # Set backup type
  local backup_type="system_config"
  export BACKUP_TYPE="$backup_type"
  
  debug "BACKUP_TYPE set to: $BACKUP_TYPE"
  debug "BACKUP_DIR is: $BACKUP_DIR"
  
  # Load system configs
  local files_to_backup=()
  debug "Loading system configs from: ${BASH_SOURCE%/*}/../config/tracked_files.conf"
  source "${BASH_SOURCE%/*}/../config/tracked_files.conf"
  
  # Add system configs to backup list with proper permissions
  for config in "${SYSTEM_CONFIGS[@]}"; do
    # Skip empty entries
    [ -z "$config" ] && continue
    
    # Handle glob patterns
    if [[ "$config" == *"*"* ]]; then
      # Expand the glob pattern
      local matched=0
      for file in $config; do
        if [ -e "$file" ] || [ -L "$file" ]; then
          # Check if we can read the file (or if we have permissions)
          if [ -r "$file" ] || [ -L "$file" ]; then
            files_to_backup+=("$file")
            ((matched++))
          else
            warn "Skipping unreadable file (permission denied): $file"
          fi
        fi
      done
      [ $matched -eq 0 ] && debug "No matches found for pattern: $config"
    elif [ -e "$config" ] || [ -L "$config" ]; then
      if [ -r "$config" ] || [ -L "$config" ]; then
        files_to_backup+=("$config")
      else
        warn "Skipping unreadable file (permission denied): $config"
      fi
    else
      debug "System config not found: $config"
    fi
  done
  
  # Check if we have any files to back up
  if [ ${#files_to_backup[@]} -eq 0 ]; then
    error "No system configuration files found to back up"
    return 1
  fi
  
  info "Found ${#files_to_backup[@]} system configuration files to back up"
  
  # Create backup with preserved permissions
  local backup_path
  backup_path=$(create_backup_archive "${files_to_backup[@]}")
  
  if [ $? -eq 0 ] && [ -n "$backup_path" ]; then
    # Get backup size in human-readable format
    local size
    size=$(du -h "$backup_path" | cut -f1)
    success "System configuration backup created successfully: $backup_path (${size})"
    return 0
  else
    error "Failed to create system configuration backup"
    return 1
  fi
}

# Export functions
export -f generate_timestamp ensure_backup_dir create_backup_archive \
         backup_existing_dotfiles backup_repository_files backup_system_configs
