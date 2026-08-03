-- =====================================================================
-- config/autostart.lua
-- Substitui ~/.config/hypr/config/autostart.conf
--
-- Os comandos diretos de autostart vivem em config/autostart.list
-- (uma linha = um comando, '#' = comentario). Este modulo le o arquivo
-- no evento `hyprland.start` e executa cada linha com hl.exec_cmd()
-- (async, nao bloqueia). Itens com delay (lock 5s, bluetooth 10s) sao
-- delegados ao config/scripts/autostart.sh com log em hypr/logs/.
-- https://wiki.hyprland.org/Configuring/Basics/Autostart/
-- =====================================================================

-- ---------------------------------------------------------------------
-- Funcao utilitaria: lanca um app com guard idempotente.
-- Usada pelo work_apps() abaixo.
-- ---------------------------------------------------------------------
local M = {}

local function has_class(class_name)
    local wins = hl.get_windows({ class = class_name, mapped = true })
    return wins and #wins > 0
end

local function has_proc(pattern)
    local ok, _, code = os.execute("pgrep -f " .. string.format("%q", pattern) .. " >/dev/null 2>&1")
    return ok == true or code == 0
end

local function launch(name, class_or_proc, workspace, cmd)
    if has_class(class_or_proc) or has_proc(class_or_proc) then
        return false
    end
    hl.exec_cmd(string.format("[workspace %d silent] %s", workspace, cmd))
    return true
end

-- ---------------------------------------------------------------------
-- Executa os comandos de autostart listados em config/autostart.list.
-- Uma linha por comando; linhas vazias e que comecam com '#' sao
-- ignoradas. io.open nao expande "~", entao usamos os.getenv("HOME").
-- ---------------------------------------------------------------------
local AUTOSTART_LIST = os.getenv("HOME") .. "/.config/hypr/config/autostart.list"

local function run_boot_autostart()
    local f = io.open(AUTOSTART_LIST, "r")
    if not f then
        io.write("[autostart.lua] ERRO: nao achei " .. AUTOSTART_LIST .. "\n")
        return
    end
    local cmds = {}
    for line in f:lines() do
        local trimmed = line:match("^%s*(.-)%s*$")
        if trimmed ~= "" and not trimmed:match("^#") then
            cmds[#cmds + 1] = trimmed
        end
    end
    f:close()
    -- Executa apos fechar o arquivo pra nao vazar o fd pro processo filho
    -- (caso real: xsettingsd herdou o fd do autostart.list).
    for _, cmd in ipairs(cmds) do
        hl.exec_cmd(cmd)
    end
end

-- ---------------------------------------------------------------------
-- Work apps: code (workspace 1), zen (11), teams (12)
-- Chamado pelo bind SUPER+SHIFT+W (definido em binds.lua).
-- Resolve o problema do keyring: code/teams sobem DEPOIS do unlock.
-- ---------------------------------------------------------------------
function M.work_apps()
    launch("code",  "code",              1, EDITOR)
    launch("zen",   "zen-browser",      11, BROWSER)
    launch("teams", "teams_for_linux",  12, TEAMS)
end

-- ---------------------------------------------------------------------
-- Boot sequence: le config/autostart.list e executa cada comando.
-- ---------------------------------------------------------------------
hl.on("hyprland.start", function ()
    run_boot_autostart()

    -- Spotify workspace 13 (idempotente via launch())
    launch("spotify", "spotify", 13, MUSIC)
end)

return M
