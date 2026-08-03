-- =====================================================================
-- HYPRLAND LUA ENTRYPOINT
-- Substitui o antigo hyprland.conf. Cada secao da config foi convertida
-- pra um modulo .lua separado. Os .conf originais foram removidos apos
-- validacao (eram legado de referencia/rollback).
--
-- NOTA DE SEGURANCA: cada require() e' envolvido em pcall() pra que
-- um modulo com erro NAO QUEBRE a sessao inteira (causaria tela em
-- branco). Se um modulo falhar, o erro e' logado via io.write e a
-- sessao continua com os outros.
-- =====================================================================

local function safe_require(name)
    local ok, err = pcall(require, "config." .. name)
    if not ok then
        io.write("[hyprland.lua] ERRO ao carregar config." .. name .. ": " .. tostring(err) .. "\n")
    end
end

-- Ordem importa: programs primeiro (define vars usadas em outros),
-- depois o resto em ordem logica.
safe_require("programs")
safe_require("permissions")
safe_require("monitors")
safe_require("look-and-feel")
safe_require("input")
safe_require("window-rules")
safe_require("binds")
safe_require("autostart")

-- Ambsxt (Ax-Shell) - barra/launcher/dashboard
-- Substitui o `source = ~/.local/share/ambxst/hyprland.conf` que era
-- feito pelo hyprland.conf antigo. O upstream agora gera um .lua
-- equivalente (commit b83a195c), entao carregamos ele diretamente.
-- https://github.com/Axenide/Ambxst/commit/b83a195c
local ambxst_lua = os.getenv("HOME") .. "/.local/share/ambxst/hyprland.lua"
local ambxst_chunk, ambxst_err = loadfile(ambxst_lua)
if ambxst_chunk then
    local ok, run_err = pcall(ambxst_chunk)
    if not ok then
        io.write("[hyprland.lua] Ambsxt ERRO em runtime: " .. tostring(run_err) .. "\n")
    end
else
    io.write("[hyprland.lua] Ambsxt NAO encontrado: " .. ambxst_lua .. " (" .. tostring(ambxst_err) .. ")\n")
end
