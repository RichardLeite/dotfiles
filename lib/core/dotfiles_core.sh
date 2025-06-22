#!/usr/bin/env bash

# ===========================================================================
# Core Dotfiles Management Functions
# ===========================================================================

# Install dotfiles from source to target
#
# Globals:
#   None
# Arguments:
#   $1 - Source base directory (where the dotfiles are stored)
#   $2 - Target base directory (where to install the dotfiles, usually $HOME)
#   $3 - Path to a file containing the list of files to manage (format: source_path:target_relative_path)
# Returns:
#   0 on success, non-zero on error
install_dotfiles() {
  local source_base="$1"
  local target_base="${2:-$HOME}"
  local tracked_files_file="$3"
  
  if [ ! -d "$source_base" ]; then
    echo "Error: Source directory does not exist: $source_base" >&2
    return 1
  fi
  
  if [ ! -d "$target_base" ]; then
    echo "Error: Target directory does not exist: $target_base" >&2
    return 1
  fi
  
  if [ ! -f "$tracked_files_file" ]; then
    echo "Error: Tracked files list not found: $tracked_files_file" >&2
    return 1
  }
  
  local source_path target_rel_path target_path
  
  while IFS=: read -r source_rel_path target_rel_path || [ -n "$source_rel_path" ]; do
    # Skip empty lines and comments
    [ -z "$source_rel_path" ] || [[ "$source_rel_path" == \#* ]] && continue
    
    source_path="${source_base}/${source_rel_path}"
    target_path="${target_base}/${target_rel_path}"
    
    # Skip if source doesn't exist in the repository
    if [ ! -e "$source_path" ]; then
      echo "WARN: Source not found: $source_path"
      continue
    fi
    
    echo "Processing: $source_path -> $target_path"
    
    # Create target directory if it doesn't exist
    local target_dir="$(dirname "$target_path")"
    if [ ! -d "$target_dir" ]; then
      if ! mkdir -p "$target_dir"; then
        echo "ERROR: Failed to create target directory: $target_dir" >&2
        continue
      fi
      echo "Created directory: $target_dir"
    fi
    
    # Handle directories
    if [ -d "$source_path" ]; then
      if [ -d "$target_path" ]; then
        # Directory exists, sync contents
        if rsync -a --delete "$source_path/" "$target_path/"; then
          echo "Synced directory: $source_path -> $target_path"
        else
          echo "ERROR: Failed to sync directory: $source_path" >&2
        fi
      else
        # New directory, copy it
        if cp -r "$source_path" "$target_path"; then
          echo "Copied directory: $source_path -> $target_path"
        else
          echo "ERROR: Failed to copy directory: $source_path" >&2
        fi
      fi
      continue
    fi
    
    # Handle files
    if [ -f "$source_path" ]; then
      # If target exists and is different, create a backup
      if [ -e "$target_path" ] && ! cmp -s "$source_path" "$target_path"; then
        local backup_file="${target_path}.bak.$(date +%s)"
        if cp "$target_path" "$backup_file"; then
          echo "Created backup: $backup_file"
        else
          echo "ERROR: Failed to create backup: $backup_file" >&2
          continue
        fi
      fi
      
      # Copy the file
      if cp "$source_path" "$target_path"; then
        echo "Copied: $source_path -> $target_path"
      else
        echo "ERROR: Failed to copy: $source_path -> $target_path" >&2
      fi
    fi
  done < "$tracked_files_file"
  
  echo "Installation completed successfully"
  return 0
}

# Initialize dotfiles repository
#
# Globals:
#   None
# Arguments:
#   $1 - Base directory for the dotfiles repository
# Returns:
#   0 on success, non-zero on error
init_dotfiles_repo() {
  local dotfiles_dir="${1:-$HOME/.dotfiles}"
  
  # Create base directory if it doesn't exist
  if [ ! -d "$dotfiles_dir" ]; then
    if ! mkdir -p "$dotfiles_dir"; then
      echo "ERROR: Failed to create directory: $dotfiles_dir" >&2
      return 1
    fi
    echo "Created directory: $dotfiles_dir"
  fi
  
  # Create necessary subdirectories
  local subdirs=("files" "config" "scripts")
  for subdir in "${subdirs[@]}"; do
    local dir_path="${dotfiles_dir}/${subdir}"
    if [ ! -d "$dir_path" ]; then
      if ! mkdir -p "$dir_path"; then
        echo "ERROR: Failed to create directory: $dir_path" >&2
        return 1
      fi
      echo "Created directory: $dir_path"
    fi
  done
  
  # Create .gitignore if it doesn't exist
  if [ ! -f "${dotfiles_dir}/.gitignore" ]; then
    cat > "${dotfiles_dir}/.gitignore" << 'EOF'
# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# Backup files
*.bak
*.swp
*.backup
*~

# Temporary files
*.tmp
*.temp

# Logs
*.log

# Local development files
.env
.env.local

# System files
.DS_Store
.AppleDouble
.LSOverride

# Thumbnails
._*

# Files that might appear in the root of a volume
.DocumentRevisions-V100
.fseventsd
.Spotlight-V100
.TemporaryItems
.Trashes
.VolumeIcon.icns
.com.apple.timemachine.donotpresent

# Directories potentially created on remote AFP share
.AppleDB
.AppleDesktop
Network Trash Folder
Temporary Items
.apdisk
EOF
    echo "Created .gitignore file"
  fi
  
  return 0
}

# Create a tracked files list from a source and target directory
#
# Globals:
#   None
# Arguments:
#   $1 - Source directory
#   $2 - Target directory
#   $3 - Output file for the tracked files list
# Returns:
#   0 on success, non-zero on error
create_tracked_files_list() {
  local source_dir="$1"
  local target_dir="$2"
  local output_file="$3"
  
  if [ ! -d "$source_dir" ] || [ ! -d "$target_dir" ]; then
    echo "Error: Source and target directories must exist" >&2
    return 1
  fi
  
  # Create or clear the output file
  > "$output_file"
  
  # Find all files in source directory and create relative paths
  while IFS= read -r -d $'\0' file; do
    # Get relative path
    rel_path="${file#$source_dir/}"
    
    # Skip the tracked files list itself
    [ "$rel_path" = "${output_file#$source_dir/}" ] && continue
    
    # Add to tracked files list
    echo "$rel_path:$rel_path" >> "$output_file"
  done < <(find "$source_dir" -type f -not -path "$source_dir/.git/*" -not -path "$source_dir/.git" -print0)
  
  echo "Created tracked files list: $output_file"
  return 0
}

# Main function for testing
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  case "$1" in
    install)
      shift
      install_dotfiles "$@"
      ;;
    init)
      shift
      init_dotfiles_repo "$@"
      ;;
    create-tracked-files)
      shift
      create_tracked_files_list "$@"
      ;;
    *)
      echo "Usage: $0 {install|init|create-tracked-files} [args...]" >&2
      exit 1
      ;;
  esac
fi
