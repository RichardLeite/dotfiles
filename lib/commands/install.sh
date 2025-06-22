#!/usr/bin/env bash

# Load core functions
source "${BASH_SOURCE%/*}/../core/dotfiles_core.sh"

# Configure SDDM for Hyprland with Hyprlock
configure_sddm() {
  log "info" "Configuring SDDM for Hyprland..."

  # Create SDDM configuration directory if it doesn't exist
  sudo mkdir -p /etc/sddm.conf.d

  # Create SDDM configuration
  sudo tee /etc/sddm.conf.d/hyprland.conf >/dev/null <<'EOF'
[General]
Current=Hyprland

[Theme]
Current=breeze

[X11]
ServerArguments=-nolisten tcp

[Autologin]
User=$USER
Session=Hyprland
EOF

  # Create xsessions directory if it doesn't exist
  sudo mkdir -p /usr/share/xsessions
  
  # Create Hyprland session file
  sudo tee /usr/share/xsessions/hyprland.desktop >/dev/null <<'EOF'
[Desktop Entry]
Name=Hyprland
Comment=Hyprland
Exec=hyprland
TryExec=hyprland
Type=Application
Keywords=wayland;window manager;hyprland;
EOF

  # Create Hyprlock service file
  sudo tee /etc/systemd/system/hyprlock.service >/dev/null <<'EOF'
[Unit]
Description=Hyprlock Service
After=display-manager.service

[Service]
Type=oneshot
ExecStart=/usr/bin/hyprlock

[Install]
WantedBy=display-manager.service
EOF

  # Enable Hyprlock service
  sudo systemctl enable hyprlock.service

  log "success" "SDDM configured for Hyprland with Hyprlock"
}

# Install dotfiles
install_dotfiles() {
  local source_dir="${DOTFILES_DIR}/files"
  local target_dir="${TARGET_HOME:-$HOME}"
  local tracked_files="${DOTFILES_DIR}/config/tracked_files.conf"
  
  # Ensure source directory exists
  if [ ! -d "$source_dir" ]; then
    error "Source directory does not exist: $source_dir"
    return 1
  fi
  
  # Ensure tracked files list exists
  if [ ! -f "$tracked_files" ]; then
    error "Tracked files list not found: $tracked_files"
    return 1
  fi
  
  info "Installing dotfiles from $source_dir to $target_dir..."
  
  # Call the core install function
  if install_dotfiles "$source_dir" "$target_dir" "$tracked_files"; then
    # Configure SDDM after successful dotfiles installation
    if command -v sddm &> /dev/null; then
      configure_sddm
    else
      log "warning" "SDDM not found. Skipping SDDM configuration."
      log "info" "To configure SDDM later, run: ${BASH_SOURCE[0]} --configure-sddm"
    fi
    
    success "Dotfiles installed successfully!"
    return 0
  else
    error "Failed to install dotfiles"
    return 1
  fi
}

export -f install_dotfiles
