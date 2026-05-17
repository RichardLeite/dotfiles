#!/bin/bash

# Script para atualizar Flatpak, ajustar permissões do Spotify e aplicar Spicetify

echo "Atualizando Flatpak..."
flatpak update -y

if [ $? -eq 0 ]; then
    echo "Ajustando permissões do Spotify..."
    sudo chmod a+wr /var/lib/flatpak/app/com.spotify.Client/x86_64/stable/active/files/extra/share/spotify && \
    sudo chmod a+wr -R /var/lib/flatpak/app/com.spotify.Client/x86_64/stable/active/files/extra/share/spotify/Apps
    
    echo "Aplicando Spicetify..."
    spicetify update 
    spicetify restore backup apply
    
    echo "Concluído!"
else
    echo "Erro ao atualizar Flatpak. Execute o Spotify manualmente."
fi
