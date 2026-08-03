-- =====================================================================
-- config/input.lua
-- Substitui ~/.config/hypr/config/input.conf
--
-- Bloco `input { ... }` vira hl.config({ input = { ... } })
-- Bloco `cursor { ... }` vira hl.config({ cursor = { ... } })
-- Bloco `device { ... }` vira hl.device({ ... })
-- https://wiki.hyprland.org/Configuring/Variables/#input
-- =====================================================================

hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "intl",
        kb_model   = "pc105",
        kb_options = "compose:ralt",
        kb_rules   = "",

        follow_mouse = 1,

        sensitivity = 0,

        touchpad = {
            natural_scroll = false,
        },
    },
})

hl.config({
    cursor = {
        no_warps = true,
    },
})

-- Exemplo de config per-device (mesmo do .conf)
-- https://wiki.hyprland.org/Configuring/Keywords/#per-device-input-configs
hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})
