#!/usr/bin/env bash

# =====================================================================
# config/scripts/autostart.sh
# Responsavel SOMENTE pelos itens de autostart que precisam de delay
# (antigos hl.timer, que nao disparavam de forma confiavel no boot).
# Comandos diretos (daemons) ficam no autostart.lua como hl.exec_cmd
# (async, nao bloqueiam).
#
# Log em hypr/logs/autostart.log para monitorar OK/FAIL.
# =====================================================================

# Log em hypr/logs/autostart.log (via symlink ~/.config/hypr)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$(realpath "$SCRIPT_DIR/../../logs" 2>/dev/null || echo "$SCRIPT_DIR/../../logs")"
LOG="$LOG_DIR/autostart.log"
mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%F %T')] $*" >>"$LOG"
}

# run <cmd...>: executa em subshell, loga OK/FAIL + saida no log.
# So use com comandos que terminam (nao-daemon), senao trava aqui.
run() {
    local desc="$*"
    log ">> $desc"
    if bash -c "$*" >>"$LOG" 2>&1; then
        log "OK   $desc"
    else
        local rc=$?
        log "FAIL (exit $rc)  $desc"
    fi
}

log "===== autostart: itens com delay ====="

# Lock screen apos 5s
( sleep 5 && run "ambxst lock" ) &

# Bluetooth apos 10s (tempo pro audio/stack settle)
( sleep 10 && run "bluetoothctl connect 41:42:82:8D:0B:47" ) &

wait

log "===== autostart: fim ====="
