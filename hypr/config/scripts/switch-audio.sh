#!/usr/bin/env bash

SPEAKER_NAME="HSC-777"
HEADSET_NAME="H510-PRO"

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

SPEAKER_SINK=$(get_sink_id_by_name "$SPEAKER_NAME")
HEADSET_SINK=$(get_sink_id_by_name "$HEADSET_NAME")
current_sink=$(get_current_sink_id)

if [ -z "$SPEAKER_SINK" ] || [ -z "$HEADSET_SINK" ]; then
    exit 1
fi

if [ "${current_sink}" = "${HEADSET_SINK}" ]; then
    new_sink="${SPEAKER_SINK}"
else
    new_sink="${HEADSET_SINK}"
fi

wpctl set-default "${new_sink}"

# Notificação visual da troca de dispositivo
if [ "${new_sink}" = "${SPEAKER_SINK}" ]; then
    notify-send "Áudio Alterado" "Caixa de Som (HSC-777)"
else
    notify-send "Áudio Alterado" "Headset (H510-PRO)"
fi
