#!/bin/bash

# Function to create symbolic link for Hyprland config
setup_hypr_config() {
    # Get the directory where this script is located
    local script_dir="$(dirname "$0")"
    # Use absolute path for source directory
    local source_dir="$(realpath "$script_dir/hypr")"
    local target_dir="$HOME/.config/hypr"
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
        echo "Backing up existing Hyprland configuration..."
        local backup_path="$backup_dir/hypr_$timestamp"
        mv "$target_dir" "$backup_path"
        echo "Backup saved to: $backup_path"
    fi

    # Remove existing symlink if it exists
    if [ -L "$target_dir" ]; then
        rm "$target_dir"
    fi

    # Create symbolic link using absolute path
    ln -sf "$source_dir" "$target_dir"
    echo "Created symbolic link for Hyprland configuration pointing to: $source_dir"
}

# Run the setup function
setup_hypr_config

# Make the script executable
chmod +x "$0"