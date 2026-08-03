-- =====================================================================
-- config/window-rules.lua
-- Substitui ~/.config/hypr/config/windows-workspaces.conf
--
-- Cada `windowrule = field value,match:class ^(...)$` vira
-- hl.window_rule({ name = "...", match = {...}, field = value }).
-- Cada `workspace = N, monitor:X` vira hl.workspace_rule({...}).
-- https://wiki.hyprland.org/Configuring/Basics/Window-Rules/
-- =====================================================================

-- Regra Universal para Jogos (Steam, Heroic, Proton, Wine e Gamescope)
-- Exclui Rockstar Games Launcher (handled differently por causa do tray)
local game_match = {
    class = "^(steam_app_\\w+|gamescope|steam_proton|.*wine.*|.*\\.exe.*)$",
    title = "negative:^(Rockstar Games Launcher)$",
}

hl.window_rule({
    name  = "games-monitor",
    match = game_match,
    monitor = "HDMI-A-2",
})

hl.window_rule({
    name  = "games-fullscreen",
    match = game_match,
    fullscreen = true,
})

-- Float on pra utilitários
hl.window_rule({
    name  = "float-pwvucontrol",
    match = { class = "^(com.saivert.pwvucontrol)$" },
    float = true,
})

hl.window_rule({
    name  = "float-qalculate",
    match = { class = "^(qalculate-gtk)$" },
    float = true,
})

hl.window_rule({
    name  = "float-drawing",
    match = { class = "^(com.github.maoschanz.drawing)$" },
    float = true,
})

-- Focar automaticamente em janelas de debug
hl.window_rule({
    name  = "focus-vscode-debug",
    match = { class = "(com.visualstudio.code)", title = "(Debug).*" },
    focus_on_activate = true,
})

hl.window_rule({
    name  = "focus-code-oss-debug",
    match = { class = "(code-oss)", title = "(Debug).*" },
    focus_on_activate = true,
})

hl.window_rule({
    name  = "focus-jetbrains-debug",
    match = { class = "(jetbrains-.*)", title = "(Debug).*" },
    focus_on_activate = true,
})

-- Focar automaticamente em novas janelas de terminal
hl.window_rule({
    name  = "focus-terminals",
    match = { class = "(kitty|alacritty|foot|wezterm|dev.warp.Warp)" },
    focus_on_activate = true,
})

-- Focar automaticamente em navegadores
hl.window_rule({
    name  = "focus-browsers",
    match = { class = "(firefox|google-chrome|chromium|brave-browser|zen)" },
    focus_on_activate = true,
})

-- Ignore maximize requests from all apps
hl.window_rule({
    name  = "suppress-maximize",
    match = { class = ".*" },
    suppress_event = "maximize",
})

-- Fix some dragging issues with XWayland
hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

-- Focar automaticamente em janelas de notificação
hl.window_rule({
    name  = "focus-notifications",
    match = { title = "^(Notification|Aviso|Erro|Alerta|Confirmação)", float = true },
    focus_on_activate = true,
})

-- Spotify sempre no workspace 13 (flatpak + native)
hl.window_rule({
    name  = "spotify-workspace",
    match = { class = "^(com.spotify.Client|spotify)$" },
    workspace = "13 silent",
})

-- xembedsniproxy: ponte XEmbed -> SNI para Wine/Proton.
-- Janela orfa 32x32 invisivel, sem foco, no special workspace.
hl.window_rule({
    name  = "xembed-workspace",
    match = { class = "^(xembedsniproxy)$" },
    workspace = "special silent",
})

hl.window_rule({
    name  = "xembed-no-focus",
    match = { class = "^(xembedsniproxy)$" },
    no_focus = true,
})

hl.window_rule({
    name  = "xembed-invisible",
    match = { class = "^(xembedsniproxy)$" },
    opacity = "0 0",
})

-- gcr-prompter (GNOME Keyring unlock): workspace 1, sem auto-focus
hl.window_rule({
    name  = "gcr-prompter-workspace",
    match = { class = "^(gcr-prompter)$" },
    workspace = "1 silent",
})

hl.window_rule({
    name  = "gcr-prompter-no-focus",
    match = { class = "^(gcr-prompter)$" },
    focus_on_activate = false,
})

-- hyprland-dialog: popup do Hyprland (app nao respondendo).
-- Mesmo tratamento do gcr-prompter.
hl.window_rule({
    name  = "hyprland-dialog-workspace",
    match = { class = "^(hyprland-dialog)$" },
    workspace = "1 silent",
})

hl.window_rule({
    name  = "hyprland-dialog-no-focus",
    match = { class = "^(hyprland-dialog)$" },
    focus_on_activate = false,
})

-- Workspace rules (HDMI-A-2 = monitor esquerdo, HDMI-A-1 = direito)
local ws_hdmi_a_2 = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 }
local ws_hdmi_a_1 = { 11, 12, 13, 14, 15, 16, 17, 18, 19, 20 }

for _, id in ipairs(ws_hdmi_a_2) do
    hl.workspace_rule({
        workspace = tostring(id),
        monitor   = "HDMI-A-2",
    })
end

for _, id in ipairs(ws_hdmi_a_1) do
    hl.workspace_rule({
        workspace = tostring(id),
        monitor   = "HDMI-A-1",
    })
end
