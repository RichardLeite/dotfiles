-- =====================================================================
-- config/programs.lua
-- Substitui ~/.config/hypr/config/programs.conf
--
-- Variaveis globais com paths de programas. Outros modulos (binds.lua,
-- autostart.lua) usam direto: hl.exec_cmd(EDITOR).
-- =====================================================================

TERMINAL  = "warp-terminal"
FILEMGR   = "nautilus"
BROWSER   = "zen-browser"
BROWSER_P = 'zen-browser -P "Default (release)"'
EDITOR    = "code"
TEAMS     = "flatpak run com.github.IsmaelMartinez.teams_for_linux"
MUSIC     = "flatpak run com.spotify.Client"
