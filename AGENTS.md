# AGENTS.md

## Repo

Personal dotfiles for Hyprland WM on Linux (Debian/Ubuntu). Active work on `v3`; default is `main`.

## Commands

- `./dotfiles.sh` — symlinks `hypr/` → `~/.config/hypr`, auto-backups existing config to `backup/`
- `sudo bash setup-locale.sh` — sets pt_BR.UTF-8 locale + US-Intl keyboard (Debian/Ubuntu only, requires sudo)

## Key conventions

- `backup/` and `wallpapers/` are gitignored — never commit them
- Hyprland config is modular: `hypr/hyprland.conf` sources files under `hypr/config/`
- `hyprland.conf` also sources external ambxst config at `~/.local/share/ambxst/hyprland.conf` — not in this repo
- Use small focused commits; test config changes locally before pushing

## Ambxst

Visual customizable shell for Hyprland. Site: https://axeni.de/ambxst/ | GitHub: https://github.com/Axenide/Ambxst | Discord: https://discord.com/invite/gHG9WHyNvH

- Install: `curl -L get.axeni.de/ambxst | sh && ambxst install hyprland`
  - Adds `source = ~/.local/share/ambxst/hyprland.conf` to `hyprland.conf`
  - Config at `~/.config/ambxst` — not tracked in this repo
- Official support: Arch, Fedora, NixOS (Debian/Ubuntu works but unofficial)
- `hypr/hyprland.conf:47-51` — sources ambxst; everything after line 49 overrides ambxst
- `hypr/config/autostart.conf:40` — `exec-once = bash -c "sleep 5 && ambxst lock"`
- `hypr/config/binds.conf:69-84` — audio/brightness/media binds commented out (ambxst manages them)
- Requires `ambxst` command in `$PATH` (usually `~/.local/bin/ambxst` after install)

## Gotchas

- `dotfiles.sh` uses `ln -sf` with absolute paths — do not manually copy configs to `~/.config/hypr`
- `setup-locale.sh` edits `/etc/locale.gen`, `/etc/default/keyboard`, and shell profile files — destructive, verify before running
- `.bak` files in `hypr/` (e.g. `hypridle.conf.bak`) should be cleaned up, not committed
- `hypr/config/scripts/` scripts depend on external tools: `wpctl` (PipeWire), `mpvpaper` (animated wallpapers), `notify-send`
