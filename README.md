# dotfiles

Personal configuration files (dotfiles) and setup scripts for my development environment. This repository maintains all configurations versioned and synchronized via Git for easy replication across machines.

## 🎯 Goals

- Keep configuration files versioned and auditable
- Synchronize environment settings across multiple machines
- Automate setup and backup processes
- Maintain clean, reproducible system configuration

## 📁 Contents

| Item | Purpose |
|------|---------|
| `dotfiles.sh` | Main setup script—creates symlinks and manages backups for Hyprland configuration |
| `setup-locale.sh` | Locale and keyboard configuration script (requires sudo) |
| `hypr/` | Hyprland window manager configuration files |
| `backup/` | Timestamped backups of previous configurations |

## 🚀 Quick Start

### Run the main setup script

```bash
chmod +x dotfiles.sh
./dotfiles.sh
```

This script will:

- Link `hypr/` directory to `~/.config/hypr`
- Automatically backup any existing Hyprland configuration to `backup/hypr_YYYYMMDD_HHMMSS/`
- Use absolute paths for symlinks

### Optional: Configure locale and keyboard

```bash
sudo bash setup-locale.sh
```

Enables `pt_BR.UTF-8` and `en_US.UTF-8` locales with US-International keyboard layout.

## 📋 Hyprland Configuration Structure

```
hypr/
├── hyprland.conf          # Main Hyprland configuration
├── hypridle.conf          # Idle behavior settings
├── hyprlock.conf          # Lock screen configuration
└── config/                # Modular configuration files
    ├── autostart.conf
    ├── binds.conf
    ├── environment-variables.conf
    ├── input.conf
    ├── monitors.conf
    ├── permissions.conf
    ├── programs.conf
    ├── windows-workspaces.conf
    ├── look-and-feel/     # Visual customization
    │   ├── animations.conf
    │   ├── decoration.conf
    │   ├── dwindle.conf
    │   ├── general.conf
    │   ├── index.conf
    │   ├── master.conf
    │   ├── misc.conf
    │   └── workspace.conf
    └── scripts/           # Utility scripts
        ├── animated-wallpaper.sh
        └── audio-ducking.sh
```

## 🔄 Workflow

### On your main machine

1. Make changes to configuration files in `hypr/`
2. Test changes locally
3. Commit and push changes:

```bash
git add .
git commit -m "Update Hyprland configuration"
git push
```

### On a new/another machine

1. Clone the repository:

```bash
git clone <repository-url> ~/.config/.dotfiles
cd ~/.config/.dotfiles
```

1. Run the setup script:

```bash
./dotfiles.sh
```

1. (Optional) Configure locale:

```bash
sudo bash setup-locale.sh
```

## 💾 Backup and Restore

Backups are automatically created when running `dotfiles.sh` if an existing configuration is found. Backups are stored in `backup/` with timestamps:

```
backup/
├── hypr_20250703_124311/  # Example backup from July 3, 2025
└── hypr_20250704_093045/  # Example backup from July 4, 2025
```

To restore a previous backup:

```bash
rm -rf ~/.config/hypr
cp -r backup/hypr_YYYYMMDD_HHMMSS ~/.config/hypr
```

## ⚙️ Requirements

- **dotfiles.sh**: Bash, no elevated privileges required
- **setup-locale.sh**: Bash with `sudo` access, works on Debian/Ubuntu systems
- **Hyprland**: Must be installed to use the Hyprland configuration

## 📝 Best Practices

- Test configuration changes locally before committing
- Use small, focused commits with clear messages
- Keep sensitive information out of the repository
- Review changes before pushing to remote
- Run setup scripts whenever pulling major changes

## 📄 License

Personal configuration repository. Modify freely for your own use.

---

**Repository:** main branch | **Last updated:** February 2, 2026
