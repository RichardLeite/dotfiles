#!/usr/bin/env bash

# Load dependencies
source "${BASH_SOURCE%/*}/../utils/logger.sh"
source "${BASH_SOURCE%/*}/../utils/backup_utils.sh"
source "${BASH_SOURCE%/*}/file_operations.sh"

# ===========================================================================
# Configuration
# ===========================================================================

# Base directories
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
FILES_DIR="${DOTFILES_DIR}/files"

# Tracked files and directories configuration
declare -A TRACKED_FILES=(
  # Shell configurations
  ["$HOME/.zshrc"]="home/.zshrc"
  ["$HOME/.p10k.zsh"]="home/.p10k.zsh"
  ["$HOME/.zsh_history"]="home/.zsh_history"

  # Hyprland configuration (entire directory)
  ["$HOME/.config/hypr"]="home/.config/hypr"

  # Warp Terminal
  ["$HOME/.config/warp-terminal"]="home/.config/warp-terminal"

  # VSCode
  ["$HOME/.config/Code/User/settings.json"]="home/.config/Code/User/settings.json"
  ["$HOME/.config/Code/User/keybindings.json"]="home/.config/Code/User/keybindings.json"
  ["$HOME/.config/Code/User/snippets"]="home/.config/Code/User/snippets"

  # VSCode OSS (Open Source)
  ["$HOME/.config/Code - OSS/User/settings.json"]="home/.config/Code - OSS/User/settings.json"
  ["$HOME/.config/Code - OSS/User/keybindings.json"]="home/.config/Code - OSS/User/keybindings.json"
  ["$HOME/.config/Code - OSS/User/snippets"]="home/.config/Code - OSS/User/snippets"

  # AX-Shell
  ["$HOME/.config/ax-shell"]="home/.config/ax-shell"
)

# ===========================================================================

# Initialize dotfiles repository (automatically called at script start)
init_dotfiles() {
  # If running from a gist, let bootstrap_dotfiles handle it
  if [[ $(pwd) == *"gist"* ]]; then
    return 0
  fi
  
  # Create base directory if it doesn't exist
  if [ ! -d "$DOTFILES_DIR" ]; then
    mkdir -p "$DOTFILES_DIR" || {
      error "Failed to create directory: $DOTFILES_DIR"
      return 1
    }
    success "Created directory: $DOTFILES_DIR"
  fi
  
  # Initialize git repository if git is available and not already a git repo
  if command -v git &>/dev/null && [ ! -d "$DOTFILES_DIR/.git" ]; then
    git init "$DOTFILES_DIR" &>/dev/null || {
      error "Failed to initialize git repository in $DOTFILES_DIR"
      return 1
    }
    success "Initialized git repository in $DOTFILES_DIR"
  fi
  
  # Create necessary directories
  local dirs=(
    "$FILES_DIR"
    "$DOTFILES_DIR/config"
    "$DOTFILES_DIR/scripts"
  )
  
  for dir in "${dirs[@]}"; do
    if [ ! -d "$dir" ]; then
      mkdir -p "$dir" || {
        error "Failed to create directory: $dir"
        return 1
      }
      success "Created directory: $dir"
    fi
  done
  
  # Create .gitignore if it doesn't exist
  if [ ! -f "$DOTFILES_DIR/.gitignore" ]; then
    cat > "$DOTFILES_DIR/.gitignore" << 'EOF'
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
*~

# Sensitive data
*.env
*.pem
*.key
*.crt
*.cert

# Local overrides
local/

# Cache directories
.cache/
node_modules/

# Vim swap files
*.swp
*.swo

# Temp files
*.tmp
*.temp

# Logs
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Editor directories and files
.idea/
.vscode/
*.suo
*.ntvs*
*.njsproj
*.sln
*.sw?
EOF
    success "Created .gitignore file"
  fi
  
  # Create README.md if it doesn't exist
  if [ ! -f "$DOTFILES_DIR/README.md" ]; then
    cat > "$DOTFILES_DIR/README.md" << 'EOF'
# Dotfiles

My personal dotfiles managed with a simple bash script.

## Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/dotfiles.git ~/.dotfiles
   cd ~/.dotfiles
   ```

2. Run the installation script:
   ```bash
   ./install.sh
   ```

## Usage

- `./install.sh install`: Install dotfiles
- `./install.sh update`: Update dotfiles from home directory
- `./install.sh list`: List managed files
- `./install.sh backup`: Create a backup of current dotfiles

## Adding new dotfiles

1. Add the file path to the `TRACKED_FILES` array in `lib/commands/dotfiles.sh`
2. Run `./install.sh update` to sync the file to the repository

## License

MIT
EOF
    success "Created README.md file"
  fi
  
  success "Dotfiles repository initialized in $DOTFILES_DIR"
  return 0
}

# Install dotfiles
install_dotfiles() {
  info "Installing dotfiles..."
  
  # Backup existing dotfiles before installation
  backup_existing_dotfiles || {
    error "Failed to backup existing dotfiles"
    return 1
  }

  # Process each tracked file/directory
  for source_path in "${!TRACKED_FILES[@]}"; do
    # Skip if source doesn't exist and not forcing
    if [ ! -e "$source_path" ] && [ ! -L "$source_path" ]; then
      warn "Source not found: $source_path"
      continue
    fi

    # Create target directory if it doesn't exist
    mkdir -p "$target_dir" || {
      error "Failed to create target directory: $target_dir"
      continue
    }

    # Handle directories
    if [ -d "$target_path" ]; then
      if [ -d "$source_path" ]; then
        # Directory exists, sync contents
        if rsync -av --progress "$target_path/" "$source_path/"; then
          success "Synced directory: $source_path"
        else
          error "Failed to sync directory: $source_path"
        fi
      else
        # New directory, copy it
        if cp -r "$target_path" "$source_path"; then
          success "Copied directory: $source_path"
        else
          error "Failed to copy directory: $source_path"
        fi
      fi
      continue
    fi

    # Handle files
    if [ -f "$target_path" ]; then
      # If target exists and is different, create a backup
      if [ -e "$source_path" ] && ! cmp -s "$target_path" "$source_path"; then
        local backup_file="$source_path.bak.$(date +%s)"
        if cp "$source_path" "$backup_file"; then
          info "Created backup: $backup_file"
        else
          error "Failed to create backup: $backup_file"
          continue
        fi
      fi

      # Copy the file
      if cp "$target_path" "$source_path"; then
        success "Copied: ${TRACKED_FILES[$source_path]} -> $source_path"
      else
        error "Failed to copy: ${TRACKED_FILES[$source_path]} -> $source_path"
      fi
    fi
  done

  success "Dotfiles installation completed"
  return 0
}

# Sync files that are not managed by Stow from home directory to repository
sync_new_files() {
  info "Synchronizing non-Stow managed files to repository..."
  
  # Load stow utilities
  source "${BASH_SOURCE%/*}/../utils/stow_utils.sh" 2>/dev/null || {
    error "Failed to load Stow utilities"
    return 1
  }
  
  # Create files directory if it doesn't exist
  mkdir -p "$FILES_DIR" || {
    error "Failed to create files directory: $FILES_DIR"
    return 1
  }

  local synced_count=0
  local skipped_count=0
  local error_count=0

  # Process each tracked file/directory
  for source_path in "${!TRACKED_FILES[@]}"; do
    local rel_path="${TRACKED_FILES[$source_path]}"
    local target_path="$FILES_DIR/$rel_path"
    local target_dir="$(dirname "$target_path")"

    # Skip if source doesn't exist and not a symbolic link
    if [ ! -e "$source_path" ] && [ ! -L "$source_path" ]; then
      debug "Source not found: $source_path"
      continue
    fi

    # Skip if already managed by Stow
    if is_managed_by_stow "$source_path"; then
      debug "Skipping Stow-managed file: $source_path"
      ((skipped_count++))
      continue
    fi

    # Ensure target directory exists
    mkdir -p "$target_dir" || {
      error "Failed to create target directory: $target_dir"
      ((error_count++))
      continue
    }

    # Handle directories
    if [ -d "$source_path" ] || [ -L "$source_path" ]; then
      if [ -d "$target_path" ] || [ -L "$target_path" ]; then
        # Directory exists in repo, sync contents without deleting
        info "Syncing directory: ${TRACKED_FILES[$source_path]}"
        if rsync -av --exclude='.git' "$source_path/" "$target_path/"; then
          success "Synced directory: ${TRACKED_FILES[$source_path]}"
          ((synced_count++))
        else
          error "Failed to sync directory: $source_path"
          ((error_count++))
        fi
      else
        # New directory, copy it
        info "Copying new directory: ${TRACKED_FILES[$source_path]}"
        if cp -r "$source_path" "$target_path"; then
          success "Copied directory: ${TRACKED_FILES[$source_path]}"
          ((synced_count++))
        else
          error "Failed to copy directory: $source_path"
          ((error_count++))
        fi
      fi
      continue
    fi

    # Handle files
    if [ -f "$source_path" ] || [ -L "$source_path" ]; then
      if [ -f "$target_path" ] || [ -L "$target_path" ]; then
        # File exists in repo, check for differences
        if ! cmp -s "$source_path" "$target_path"; then
          # Show differences in a non-interactive way
          if [ -t 1 ]; then  # Only show diff if output is a terminal
            echo -e "${YELLOW}=== Updating file: ${TRACKED_FILES[$source_path]} ===${NC}"
            # Show a compact diff if diff-so-fancy is available
            if command -v diff-so-fancy >/dev/null 2>&1; then
              diff -u "$target_path" "$source_path" | diff-so-fancy
            else
              diff -u "$target_path" "$source_path"
            fi
            echo -e "${YELLOW}========================================${NC}"
          fi
          
          # Update the repository with the local version
          if cp -f "$source_path" "$target_path"; then
            success "Updated: ${TRACKED_FILES[$source_path]}"
            ((synced_count++))
          else
            error "Failed to update: ${TRACKED_FILES[$source_path]}"
            ((error_count++))
          fi
        else
          debug "No changes detected: ${TRACKED_FILES[$source_path]}"
        fi
      else
        # New file, copy it to the repository
        info "Adding new file: ${TRACKED_FILES[$source_path]}"
        if cp "$source_path" "$target_path"; then
          success "Added new file: ${TRACKED_FILES[$source_path]}"
          ((synced_count++))
        else
          error "Failed to add new file: ${TRACKED_FILES[$source_path]}"
          ((error_count++))
        fi
      fi
    fi
  done

  # Summary
  echo -e "\n${GREEN}=== Synchronization Summary ===${NC}"
  echo -e "${GREEN}✓ Synced: $synced_count${NC}"
  echo -e "${YELLOW}↷ Skipped (managed by Stow): $skipped_count${NC}"
  
  if [ $error_count -gt 0 ]; then
    echo -e "${RED}✗ Errors: $error_count${NC}"
    error "Synchronization completed with $error_count error(s)"
    return 1
  else
    success "Synchronization completed successfully"
    return 0
  fi
}

# List managed dotfiles
list_managed_files() {
  info "Listing managed dotfiles in $FILES_DIR"

  if [ ! -d "$FILES_DIR" ]; then
    error "Dotfiles directory not found: $FILES_DIR"
    return 1
  fi

  info "Listing dotfiles in: $FILES_DIR"

  # List all tracked files and their status
  for source_path in "${!TRACKED_FILES[@]}"; do
    local target_path="$FILES_DIR/${TRACKED_FILES[$source_path]}"
    local rel_path="${TRACKED_FILES[$source_path]}"
    
    # Check if the file exists in the repository
    if [ ! -e "$target_path" ]; then
      echo -e "${RED}✗ $rel_path (not in repository)${NC}"
      continue
    fi
    
    # Check if the file exists in home directory
    if [ -e "$source_path" ]; then
      # Check if the file is different
      if [ -d "$source_path" ] && [ -d "$target_path" ]; then
        # For directories, just show they exist
        echo -e "${GREEN}✓ $rel_path/ (directory)${NC}"
      elif [ -f "$source_path" ] && [ -f "$target_path" ]; then
        if cmp -s "$source_path" "$target_path"; then
          echo -e "${GREEN}✓ $rel_path${NC}"
        else
          echo -e "${YELLOW}⚠ $rel_path (modified)${NC}"
        fi
      else
        echo -e "${YELLOW}⚠ $rel_path (type mismatch)${NC}"
      fi
    else
      echo -e "${RED}✗ $rel_path (not installed)${NC}"
    fi
  done

  echo ""
  echo "Tracked files and directories are defined in the TRACKED_FILES array at the top of this script."
  echo "To add new files, update the TRACKED_FILES array with the source and target paths."
  echo ""
  echo "Example of current tracked files:"
  for source_path in "${!TRACKED_FILES[@]}"; do
    echo "  - $source_path -> $FILES_DIR/${TRACKED_FILES[$source_path]}"
  done

  success "Finished listing managed dotfiles"
}

export -f init_dotfiles install_dotfiles sync_new_files list_managed_files
