# AGENTS.md

## Repo

Personal dotfiles for Hyprland WM on Linux (Debian/Ubuntu). Current work on `v2` branch; default is `main`.

## Commands

- `./dotfiles.sh` — symlinks `hypr/` → `~/.config/hypr`, auto-backups existing config to `backup/`
- `sudo bash setup-locale.sh` — sets pt_BR.UTF-8 locale + US-Intl keyboard (Debian/Ubuntu only, requires sudo)

## Key conventions

- `backup/` and `wallpapers/` are gitignored — never commit them
- Hyprland config is modular: `hypr/hyprland.conf` sources files under `hypr/config/`
- Use small focused commits; test config changes locally before pushing

## Gotchas

- `dotfiles.sh` uses `ln -sf` with absolute paths — do not manually copy configs to `~/.config/hypr`
- `setup-locale.sh` edits `/etc/locale.gen`, `/etc/default/keyboard`, and shell profile files — destructive, verify before running
- `.bak` files in `hypr/` (e.g. `hypridle.conf.bak`) should be cleaned up, not committed
