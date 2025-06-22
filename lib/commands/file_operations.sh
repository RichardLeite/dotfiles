#!/usr/bin/env bash

# Load dependencies
source "${BASH_SOURCE%/*}/../utils/logger.sh"

# Copy a file or directory with backup and verification
copy_file() {
  local src="$1"
  local dest="$2"
  local backup_enabled=${3:-1}  # Default to enabled
  
  if [ ! -e "$src" ]; then
    error "Source does not exist: $src"
    return 1
  fi
  
  # Create destination directory if it doesn't exist
  create_dir "$(dirname "$dest")"
  
  # Backup existing file if it exists
  if [ -e "$dest" ]; then
    if [ "$backup_enabled" -eq 1 ]; then
      if ! backup "$dest" "${dest}.bak"; then
        error "Failed to create backup of $dest"
        return 1
      fi
    else
      rm -rf "$dest"
    fi
  fi
  
  # Copy the file or directory
  if cp -r "$src" "$dest"; then
    debug "Copied $src to $dest"
    return 0
  else
    error "Failed to copy $src to $dest"
    return 1
  fi
}

# Create a symbolic link with backup support
create_symlink() {
  local target="$1"
  local link_name="$2"
  
  if [ ! -e "$target" ]; then
    error "Target does not exist: $target"
    return 1
  fi
  
  # Remove existing symlink or file
  if [ -L "$link_name" ] || [ -e "$link_name" ]; then
    if ! rm -rf "$link_name"; then
      error "Failed to remove existing file/link: $link_name"
      return 1
    fi
  fi
  
  # Create parent directories if they don't exist
  create_dir "$(dirname "$link_name")"
  
  # Create the symlink
  if ln -s "$target" "$link_name"; then
    debug "Created symlink: $link_name -> $target"
    return 0
  else
    error "Failed to create symlink: $link_name -> $target"
    return 1
  fi
}

# Exclude files/directories from operations
exclude_files() {
  local excludes=(
    "*.swp" "*.swo" "*~" "*.bak" "*.backup" "*.tmp" "*.temp"
    ".git" ".gitignore" ".DS_Store" "Thumbs.db"
    "node_modules" "__pycache__" "*.pyc" "*.pyo" "*.pyd"
    ".cache" ".local/share/Trash" ".Trash" "lost+found"
  )
  
  for pattern in "${excludes[@]}"; do
    echo "--exclude=$pattern"
  done
}

export -f copy_file create_symlink exclude_files
