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
| `dotfiles.sh` | Main setup script—creates symlinks and manages backups for Hyprland and uwsm configuration |
| `setup-locale.sh` | Locale and keyboard configuration script (requires sudo) |
| `hypr/` | Hyprland window manager configuration files (Lua config) |
| `uwsm/` | uwsm environment files (`env`, `env-hyprland`) loaded before the graphical session starts |
| `backup/` | Timestamped backups of previous configurations |

## 🚀 Quick Start

### Run the main setup script

```bash
chmod +x dotfiles.sh
./dotfiles.sh
```

This script will:

- Link `hypr/` directory to `~/.config/hypr`
- Link `uwsm/` directory to `~/.config/uwsm`
- Automatically backup any existing configuration to `backup/<name>_YYYYMMDD_HHMMSS/`
- Use absolute paths for symlinks

### Optional: Configure locale and keyboard

```bash
sudo bash setup-locale.sh
```

Enables `pt_BR.UTF-8` and `en_US.UTF-8` locales with US-International keyboard layout.

## 📋 Hyprland Configuration Structure

```
hypr/
├── hyprland.lua            # Main Hyprland configuration (Lua entrypoint)
└── config/                # Modular configuration files (Lua)
    ├── autostart.lua
    ├── binds.lua
    ├── input.lua
    ├── monitors.lua
    ├── permissions.lua
    ├── programs.lua
    ├── look-and-feel.lua
    ├── window-rules.lua
    └── scripts/           # Utility scripts
        ├── animated-wallpaper.sh
        ├── audio-ducking.sh
        └── autostart.sh
```

`uwsm/` holds environment files sourced by the uwsm preloader before the
graphical session starts (format: `export KEY=VAL`):

```
uwsm/
├── env             # theming, xcursor, toolkit, input method vars
└── env-hyprland    # HYPR* / AQ_* vars specific to Hyprland
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
├── hypr_20250704_093045/  # Example backup from July 4, 2025
└── uwsm_20260101_000000/  # Example backup of ~/.config/uwsm
```

To restore a previous backup:

```bash
rm -rf ~/.config/hypr ~/.config/uwsm
cp -r backup/hypr_YYYYMMDD_HHMMSS ~/.config/hypr
cp -r backup/uwsm_YYYYMMDD_HHMMSS ~/.config/uwsm
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
