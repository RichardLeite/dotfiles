#!/usr/bin/env bash

# ===========================================================================
# Configuração de Locale e Teclado
# ===========================================================================
# Configura o sistema para usar pt_BR.UTF-8 com teclado US-International
# Inclui suporte a caracteres especiais do português (ç, ã, õ, etc.)
# ===========================================================================

# Verifica se o script está sendo executado como root
if [ "$EUID" -ne 0 ]; then
  echo "Este script precisa ser executado com privilégios de superusuário (sudo)."
  echo "Por favor, execute com: sudo $0"
  exit 1
fi

# Verifica se o arquivo de locale existe
if [ ! -f "/etc/locale.gen" ]; then
  echo "Arquivo /etc/locale.gen não encontrado. Instalando pacotes necessários..."
  apt-get update && apt-get install -y locales
fi

# Habilita os locales necessários
for locale in "pt_BR.UTF-8" "en_US.UTF-8"; do
  if ! grep -q "^${locale} UTF-8" /etc/locale.gen; then
    echo "Habilitando locale ${locale}..."
    echo "${locale} UTF-8" | tee -a /etc/locale.gen > /dev/null
  fi
done

# Gera os locales
locale-gen

# Configura o locale padrão para pt_BR.UTF-8
echo "Configurando locale padrão para pt_BR.UTF-8..."
update-locale LANG=pt_BR.UTF-8 LC_MESSAGES=POSIX

# Configura o teclado para US International com dead keys
echo "Configurando teclado para US International..."
cat > /etc/default/keyboard << 'EOL'
# KEYBOARD CONFIGURATION FILE

# Consult /usr/share/doc/keyboard-configuration/README.Debian for
# documentation on what to do after having modified this file.

# The following variables describe your keyboard and can have the same
# values as the XkbModel, XkbLayout, XkbVariant and XkbOptions options
# in /etc/X11/xorg.conf.

XKBMODEL="pc105"
XKBLAYOUT="us"
XKBVARIANT="intl"
XKBOPTIONS=""

# If you don't want to use XKB options on the console, you can
# specify an alternative keymap that will be used instead of
# the system default (think userspace keymap, then XKB keyboard
# map in the X server, so you have to define both).

# KMAP=/etc/console-setup/defkeymap.kmap.gz
# BACKSPACE="guess"
EOL

# Aplica a configuração do teclado
setupcon --save --force

# Configura o fuso horário para America/Sao_Paulo (opcional)
if [ -f /usr/share/zoneinfo/America/Sao_Paulo ]; then
  echo "Configurando fuso horário para America/Sao_Paulo..."
  timedatectl set-timezone America/Sao_Paulo
fi

# Configura as variáveis de ambiente para a sessão atual
export LANG=pt_BR.UTF-8
export LANGUAGE=pt_BR:pt:en
export LC_ALL=pt_BR.UTF-8

# Adiciona as configurações aos arquivos de perfil do shell
for shell_file in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile" "/etc/environment"; do
  if [ -f "$shell_file" ] || [ "$shell_file" = "/etc/environment" ]; then
    # Cria o arquivo se não existir
    [ -f "$shell_file" ] || touch "$shell_file"
    
    # Adiciona as configurações de locale
    for var in LANG LANGUAGE LC_ALL; do
      # Remove configurações existentes
      sed -i "/^export ${var}=/d" "$shell_file" 2>/dev/null || true
      # Adiciona as novas configurações
      echo "export ${var}=${!var}" | tee -a "$shell_file" >/dev/null
    done
    
    echo "Configurações de locale adicionadas a ${shell_file}"
  fi
done

echo -e "\nConfiguração concluída com sucesso!"
echo "- Idioma do sistema: Português do Brasil (pt_BR.UTF-8)"
echo "- Layout do teclado: US International (com dead keys)"
echo "- Fuso horário: $(timedatectl | grep 'Time zone' | cut -d: -f2-)"
echo "\nReinicie o sistema para aplicar todas as alterações."
