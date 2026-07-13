#!/usr/bin/env bash

# Ordem do ciclo: SPEAKER → HEADPHONE → HEADSET → SPEAKER...
DEVICES=(
    "HSC-777|Caixa de Som (HSC-777)|SPEAKER"
    "HD Audio Controller|Fones de Ouvido (HD Audio Controller)|HEADPHONE"
    "H510-PRO|Headset (H510-PRO)|HEADSET"
)

status_output=$(wpctl status)

get_sink_id_by_name() {
    local sink_name="$1"
    awk -v sink_name="$sink_name" '
        /Sinks:/ { in_sinks = 1; next }
        in_sinks && /^[[:space:]]*[[:graph:]]+:/ { in_sinks = 0 }
        in_sinks && index($0, sink_name) {
            if (match($0, /[0-9]+\./)) {
                print substr($0, RSTART, RLENGTH - 1)
                exit
            }
        }
    ' <<< "$status_output"
}

get_current_sink_id() {
    awk '
        /Sinks:/ { in_sinks = 1; next }
        in_sinks && /^[[:space:]]*[[:graph:]]+:/ { in_sinks = 0 }
        in_sinks && /\*/ {
            if (match($0, /[0-9]+\./)) {
                print substr($0, RSTART, RLENGTH - 1)
                exit
            }
        }
    ' <<< "$status_output"
}

# Construir lista dinâmica de dispositivos disponíveis
available_ids=()
available_labels=()

for entry in "${DEVICES[@]}"; do
    IFS='|' read -r pattern label _ <<< "$entry"
    sink_id=$(get_sink_id_by_name "$pattern")
    if [ -n "$sink_id" ]; then
        available_ids+=("$sink_id")
        available_labels+=("$label")
    fi
done

# Se nenhum dispositivo disponível, sair silenciosamente
if [ ${#available_ids[@]} -eq 0 ]; then
    exit 1
fi

# Se só 1 disponível, notificar e não trocar
if [ ${#available_ids[@]} -eq 1 ]; then
    notify-send "Áudio" "${available_labels[0]} (único disponível)"
    exit 0
fi

current_sink=$(get_current_sink_id)

# Encontrar índice do sink atual
current_idx=-1
for i in "${!available_ids[@]}"; do
    if [ "${available_ids[$i]}" = "$current_sink" ]; then
        current_idx=$i
        break
    fi
done

# Se sink atual não está na lista (ex: Easy Effects), usar índice 0
if [ "$current_idx" -eq -1 ]; then
    current_idx=0
fi

# Avançar para próximo (com wrap-around)
next_idx=$(( (current_idx + 1) % ${#available_ids[@]} ))
new_sink="${available_ids[$next_idx]}"
new_label="${available_labels[$next_idx]}"

wpctl set-default "$new_sink"
notify-send "Áudio Alterado" "$new_label"
