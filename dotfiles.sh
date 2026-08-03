#!/bin/bash

# Function to create symbolic link for a dotfile config dir
# Usage: setup_config <source_dir_name> <target_dir>
setup_config() {
    local name="$1"
    local target_dir="$2"

    # Get the directory where this script is located
    local script_dir="$(dirname "$0")"
    # Use absolute path for source directory
    local source_dir="$(realpath "$script_dir/$name")"
    local backup_dir="$script_dir/backup"
    local timestamp="$(date +%Y%m%d_%H%M%S)"

    # Check if source directory exists
    if [ ! -d "$source_dir" ]; then
        echo "Error: Source directory $source_dir does not exist"
        return 1
    fi

    # Create backup directory if it doesn't exist
    mkdir -p "$backup_dir"

    # If target exists and is not a symlink, backup it
    if [ -e "$target_dir" ] && [ ! -L "$target_dir" ]; then
        echo "Backing up existing $name configuration..."
        local backup_path="$backup_dir/${name}_$timestamp"
        mv "$target_dir" "$backup_path"
        echo "Backup saved to: $backup_path"
    fi

    # Remove existing symlink if it exists
    if [ -L "$target_dir" ]; then
        rm "$target_dir"
    fi

    # Create symbolic link using absolute path
    ln -sf "$source_dir" "$target_dir"
    echo "Created symbolic link for $name configuration pointing to: $source_dir"
}

# Run the setup functions
setup_config "hypr" "$HOME/.config/hypr"
setup_config "uwsm" "$HOME/.config/uwsm"

# Make the script executable
chmod +x "$0"
