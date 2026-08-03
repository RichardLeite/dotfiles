-- =====================================================================
-- config/binds.lua
-- Substitui ~/.config/hypr/config/binds.conf
--
-- NOTA: nomes de dispatchers MUDARAM no Hyprland Lua API 0.56+.
-- Equivalencias (do template oficial):
--   killactive       -> hl.dsp.window.close()
--   togglefloating   -> hl.dsp.window.float({ action = "toggle" })
--   pseudo           -> hl.dsp.window.pseudo()
--   fullscreen       -> hl.dsp.window.fullscreen()
--   layoutmsg        -> hl.dsp.layout(MSG)
--   workspace N      -> hl.dsp.focus({ workspace = "N" })
--   movetoworkspace  -> hl.dsp.window.move({ workspace = "N" })
--   movefocus DIR    -> hl.dsp.focus({ direction = "DIR" })
--   movewindow       -> hl.dsp.window.drag()   (com { mouse = true })
--   resizewindow     -> hl.dsp.window.resize() (com { mouse = true })
--
-- NOTA: Os binds do Ambsxt (SUPER+R launcher, SUPER+D dashboard, etc)
-- estao em ~/.local/share/ambxst/hyprland.conf. Esse .conf E gerado
-- pelo axctl. Nao carregamos ele aqui (require do Hyprland so aceita
-- .lua). Resolver em fase futura.
-- https://wiki.hyprland.org/Configuring/Basics/Binds/
-- =====================================================================

local M = "SUPER"

-- ---------------------------------------------------------------------
-- Apps basicos
-- ---------------------------------------------------------------------
hl.bind(M .. " + T", hl.dsp.exec_cmd(TERMINAL))
hl.bind(M .. " + Q", hl.dsp.window.close())
-- hl.bind(M .. " + M", hl.dsp.exit())  -- commented
hl.bind(M .. " + E", hl.dsp.exec_cmd(FILEMGR))
hl.bind(M .. " + B", hl.dsp.exec_cmd(BROWSER_P))

-- ---------------------------------------------------------------------
-- Window management
-- ---------------------------------------------------------------------
hl.bind(M .. " + X", hl.dsp.window.float({ action = "toggle" }))
hl.bind(M .. " + F", hl.dsp.window.fullscreen())
-- hl.bind(M .. " + R", hl.dsp.exec_cmd(menu))  -- commented
hl.bind(M .. " + P", hl.dsp.window.pseudo())
hl.bind(M .. " + J", hl.dsp.layout("togglesplit"))

-- ---------------------------------------------------------------------
-- Move focus com SUPER + arrows
-- ---------------------------------------------------------------------
hl.bind(M .. " + left",  hl.dsp.focus({ direction = "l" }))
hl.bind(M .. " + right", hl.dsp.focus({ direction = "r" }))
hl.bind(M .. " + up",    hl.dsp.focus({ direction = "u" }))
hl.bind(M .. " + down",  hl.dsp.focus({ direction = "d" }))

-- ---------------------------------------------------------------------
-- Switch workspaces (SUPER + [0-9])
-- ---------------------------------------------------------------------
for i = 1, 10 do
    local key = i % 10
    hl.bind(M .. " + " .. key, hl.dsp.focus({ workspace = tostring(i) }))
    hl.bind(M .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = tostring(i) }))
end

-- ---------------------------------------------------------------------
-- Scroll through workspaces (SUPER + scroll)
-- ---------------------------------------------------------------------
hl.bind(M .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(M .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- ---------------------------------------------------------------------
-- Move/resize windows (SUPER + LMB/RMB + drag)
-- ---------------------------------------------------------------------
hl.bind(M .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(M .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- ---------------------------------------------------------------------
-- Audio
-- ---------------------------------------------------------------------
-- Open volume control com pwvucontrol
hl.bind("CTRL + XF86AudioMute", hl.dsp.exec_cmd("pwvucontrol"))

-- Switch audio device
hl.bind(M .. " + XF86AudioMute", hl.dsp.exec_cmd("~/.config/hypr/config/scripts/switch-audio.sh"))

-- Mic mute (esse NAO e' do Ambsxt, mantemos ativo)
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"))

-- Os binds de volume, brightness e media keys estao comentados:
-- Ambsxt gerencia eles. Resolver na fase futura.

-- ---------------------------------------------------------------------
-- Handy
-- ---------------------------------------------------------------------
hl.bind("Control_L + space", hl.dsp.exec_cmd("handy --toggle-post-process"))

-- ---------------------------------------------------------------------
-- WORK MODE (bind do plano v1 que ficou pendente)
-- Chama a funcao M.work_apps() definida no autostart.lua.
-- SUPER+SHIFT+W = "W" de Work.
-- ---------------------------------------------------------------------
local autostart = require("config.autostart")
hl.bind("SUPER + SHIFT + W", autostart.work_apps, { description = "Sobe work apps (code, zen, teams)" })
