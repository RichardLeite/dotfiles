#!/bin/bash
# TODO: refactor and fix this script

CALL_APPS=("Vesktop" "teams-for-linux")

# Carrega o módulo de ducking se não estiver presente
if ! pactl list modules short | grep -q "module-role-ducking"; then
    pactl load-module module-role-ducking trigger_roles=phone ducking_volume=0.2 > /dev/null
    notify-send "Audio Ducking" "Módulo ativado e monitorando chamadas."
fi

# Monitora eventos do PipeWire para aplicar e remover a role dinamicamente
pw-mon --remote default --all | while read -r line; do
    # Encontra o ID do nó de áudio
    if ! node_id=$(echo "$line" | sed -n 's/.*"id": \([0-9]\+\),.*/\1/p'); then
        continue
    fi

    # Espera um pouco para garantir que as propriedades do nó estejam disponíveis
    sleep 0.1
    props=$(pw-cli info "$node_id")

    # Extrai as informações necessárias
    app_name=$(echo "$props" | grep -oP 'application.name = "\K[^"]+')
    media_class=$(echo "$props" | grep -oP 'media.class = "\K[^"]+')
    app_pid=$(echo "$props" | grep -oP 'application.process.id = "\K[^"]+')

    # Verifica se o app é um dos apps de chamada
    is_call_app=false
    for app in "${CALL_APPS[@]}"; do
        if [[ "$app_name" == "$app" ]]; then
            is_call_app=true
            break
        fi
    done

    if $is_call_app && [[ "$media_class" == "Stream/Output/Audio" ]]; then
        # Se o app de chamada tem um stream de SAÍDA, verificamos se ele também tem um de ENTRADA (microfone)
        if pactl list source-outputs | grep -q "application.process.id = \"$app_pid\""; then
            # CHAMADA ATIVA: Aplica a role "phone"
            pw-cli "$node_id" set-param props '{ media.role: "phone" }'
        else
            # CHAMADA INATIVA: Remove a role "phone" para parar o ducking
            pw-cli "$node_id" set-param props '{ media.role: "music" }' # Define como 'music' ou outra role neutra
        fi
    fi
done
