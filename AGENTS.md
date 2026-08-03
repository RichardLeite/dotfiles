# AGENTS.md

## Repo

Personal dotfiles for Hyprland WM on Linux (Debian/Ubuntu). Active work on `v3`; default is `main`.

## Commands

- `./dotfiles.sh` — symlinks `hypr/` → `~/.config/hypr` and `uwsm/` → `~/.config/uwsm`, auto-backups existing config to `backup/`
- `sudo bash setup-locale.sh` — sets pt_BR.UTF-8 locale + US-Intl keyboard (Debian/Ubuntu only, requires sudo)

## Key conventions

- `backup/` and `wallpapers/` are gitignored — never commit them
- Hyprland config is modular Lua: `hypr/hyprland.lua` requires files under `hypr/config/` via `safe_require` (pcall)
- `hyprland.lua` also loads external ambxst lua config at `~/.local/share/ambxst/hyprland.lua` — not in this repo
- **Env vars live in `uwsm/env` and `uwsm/env-hyprland`** (symlinked to `~/.config/uwsm/`), NOT in Lua — per the wiki for uwsm users. XDG vars are set automatically by uwsm
- Use small focused commits; test config changes locally before pushing

## Ambxst

Visual customizable shell for Hyprland. Site: https://axeni.de/ambxst/ | GitHub: https://github.com/Axenide/Ambxst | Discord: https://discord.com/invite/gHG9WHyNvH

- Install: `curl -L get.axeni.de/ambxst | sh && ambxst install hyprland`
  - Config at `~/.config/ambxst` — not tracked in this repo
- Official support: Arch, Fedora, NixOS (Debian/Ubuntu works but unofficial)
- `hypr/hyprland.lua:37-45` — loads ambxst lua (`~/.local/share/ambxst/hyprland.lua`); ambxst overrides come after
- `hypr/config/scripts/autostart.sh` — `sleep 5 && ambxst lock` (delay items)
- `hypr/config/binds.lua:86-87` — audio/brightness/media binds commented out (ambxst manages them)
- Requires `ambxst` command in `$PATH` (usually `/usr/local/bin/ambxst` after install)

## Gotchas

- `dotfiles.sh` uses `ln -sf` with absolute paths — do not manually copy configs to `~/.config/hypr` or `~/.config/uwsm`
- `setup-locale.sh` edits `/etc/locale.gen`, `/etc/default/keyboard`, and shell profile files — destructive, verify before running
- `.bak` files in `hypr/` should be cleaned up, not committed
- `hypr/config/scripts/` scripts depend on external tools: `wpctl` (PipeWire), `mpvpaper` (animated wallpapers), `notify-send`
