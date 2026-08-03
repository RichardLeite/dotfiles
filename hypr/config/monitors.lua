-- =====================================================================
-- config/monitors.lua
-- Substitui ~/.config/hypr/config/monitors.conf
--
-- Cada linha `monitor=OUTPUT,MODE,POSITION,SCALE` vira hl.monitor({...}).
-- https://wiki.hypr.land/Configuring/Basics/Monitors/
-- =====================================================================

hl.monitor({
    output   = "HDMI-A-1",
    mode     = "preferred",
    position = "0x0",
    scale    = 1,
})

hl.monitor({
    output   = "HDMI-A-2",
    mode     = "2560x1080@59.98Hz",
    position = "1920x0",
    scale    = 1,
})
