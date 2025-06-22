#!/usr/bin/env bash

# Cores para saída
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuração do ambiente de teste
TEST_DIR="/tmp/dotfiles-test-update-$(date +%s)"
TEST_HOME="$TEST_DIR/home"
TEST_DOTFILES="$TEST_DIR/dotfiles"

# Função para exibir mensagens de log
log() {
  local level=$1
  local message=$2
  local timestamp
  timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  
  case $level in
    "INFO") echo -e "[${YELLOW}${level}${NC}] $timestamp - $message" ;;
    "SUCCESS") echo -e "[${GREEN}${level}${NC}] $timestamp - $message" ;;
    "ERROR") echo -e "[${RED}${level}${NC}] $timestamp - $message" ;;
    "INPUT") echo -e "[${BLUE}${level}${NC}] $timestamp - $message" ;;
    *) echo -e "[$level] $timestamp - $message" ;;
  esac
}

# Função para limpar o ambiente de teste
cleanup() {
  if [ -d "$TEST_DIR" ]; then
    log "INFO" "Limpando ambiente de teste..."
    rm -rf "$TEST_DIR"
  fi
}

# Configurar armadilha para limpeza ao sair
trap cleanup EXIT

# Função para simular entrada do usuário
simulate_user_input() {
  local prompt="$1"
  local expected_input="$2"
  
  log "INPUT" "$prompt"
  log "INPUT" "Simulando entrada do usuário: $expected_input"
  echo "$expected_input"
}

# Obter diretório do script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIXTURES_DIR="$SCRIPT_DIR/fixtures"

# Criar ambiente de teste
setup_test_environment() {
  log "INFO" "Configurando ambiente de teste em $TEST_DIR..."
  
  # Criar estrutura de diretórios
  mkdir -p "$TEST_HOME/.config/test-app"
  mkdir -p "$TEST_DOTFILES/files/home/.config/test-app"
  mkdir -p "$TEST_DOTFILES/files/home"
  
  # Verificar se os arquivos de fixture existem
  if [ ! -f "$FIXTURES_DIR/testrc" ] || [ ! -f "$FIXTURES_DIR/test-app-config.json" ]; then
    log "ERROR" "Arquivos de fixture não encontrados em $FIXTURES_DIR"
    return 1
  fi
  
  # Copiar arquivos de fixture para o ambiente de teste
  cp "$FIXTURES_DIR/testrc" "$TEST_HOME/.testrc"
  cp "$FIXTURES_DIR/test-app-config.json" "$TEST_HOME/.config/test-app/config.json"
  
  # Copiar o repositório para o diretório de teste
  cp -r "$SCRIPT_DIR/../" "$TEST_DOTFILES" || {
    log "ERROR" "Falha ao copiar o repositório para o diretório de teste"
    return 1
  }
  
  # Criar diretório files/home no repositório de teste
  mkdir -p "$TEST_DOTFILES/files/home/.config/test-app"
  
  # Atualizar TRACKED_FILES no script
  sed -i "/^declare -A TRACKED_FILES=(/a \  [\"$TEST_HOME/.testrc\"]=\".testrc\"\n  [\"$TEST_HOME/.config/test-app/config.json\"]=\".config/test-app/config.json\"" "$TEST_DOTFILES/lib/commands/dotfiles.sh"
  
  # Modificar a função sync_new_files para ser não interativa
  sed -i 's/read -p ".*" choice/choice="U"/g' "$TEST_DOTFILES/lib/commands/dotfiles.sh"
  
  # Exportar variáveis de ambiente para o teste
  export HOME="$TEST_HOME"
  export DOTFILES_DIR="$TEST_DOTFILES"
  
  # Criar um script de instalação/atualização simplificado para teste
  cat > "$TEST_DOTFILES/install.sh" << 'EOL'
#!/bin/bash
# Script de instalação/atualização simplificado para testes

# Importar funções de dotfiles.sh
source "$DOTFILES_DIR/lib/commands/dotfiles.sh"

case "$1" in
  install)
    install_dotfiles
    ;;
  update)
    sync_new_files
    ;;
  *)
    echo "Uso: $0 {install|update}"
    exit 1
    ;;
esac
EOL
  
  chmod +x "$TEST_DOTFILES/install.sh"
  
  log "SUCCESS" "Ambiente de teste configurado com sucesso"
}

# Testar instalação inicial
test_initial_install() {
  log "INFO" "Testando instalação inicial..."
  
  # Executar instalação
  cd "$TEST_DOTFILES" || return 1
  if ! ./install.sh install; then
    log "ERROR" "Falha na instalação inicial"
    return 1
  fi
  
  # Verificar se os arquivos foram instalados corretamente
  if [ ! -f "$TEST_HOME/.testrc" ] || [ ! -d "$TEST_HOME/.config/test-app" ]; then
    log "ERROR" "Arquivos não foram instalados no diretório home"
    return 1
  fi
  
  log "SUCCESS" "Instalação inicial concluída com sucesso"
  return 0
}

# Testar atualização interativa
test_interactive_update() {
  log "INFO" "Testando atualização interativa..."
  
  # Modificar arquivos locais com conteúdo das fixtures
  echo "# Configuração modificada em $(date)" >> "$TEST_HOME/.testrc"
  echo "MODIFICADO=sim" >> "$TEST_HOME/.testrc"
  
  # Modificar o JSON do app
  sed -i 's/"theme": "dark"/"theme": "light"/' "$TEST_HOME/.config/test-app/config.json"
  sed -i 's/"autoUpdate": false/"autoUpdate": true/' "$TEST_HOME/.config/test-app/config.json"
  
  # Executar atualização com entrada simulada do usuário
  cd "$TEST_DOTFILES" || return 1
  
  log "INFO" "Iniciando teste interativo de atualização"
  log "INFO" "Por favor, verifique as diferenças e confirme a atualização"
  
  # Executar o comando de atualização (o usuário interage aqui)
  ./install.sh update
  
  # Verificar se os arquivos foram atualizados no repositório
  if ! grep -q "MODIFICADO=sim" "$TEST_DOTFILES/files/home/.testrc"; then
    log "ERROR" "Arquivo .testrc não foi atualizado corretamente no repositório"
    return 1
  fi
  
  if ! grep -q '"theme": "light"' "$TEST_DOTFILES/files/home/.config/test-app/config.json" || \
     ! grep -q '"autoUpdate": true' "$TEST_DOTFILES/files/home/.config/test-app/config.json"; then
    log "ERROR" "Arquivo config.json não foi atualizado corretamente no repositório"
    return 1
  fi
  
  log "SUCCESS" "Atualização interativa concluída com sucesso"
  return 0
}

# Função principal
main() {
  log "INFO" "Iniciando teste de atualização interativa..."
  
  if ! setup_test_environment; then
    log "ERROR" "Falha ao configurar o ambiente de teste"
    return 1
  fi
  
  if ! test_initial_install; then
    log "ERROR" "Falha no teste de instalação inicial"
    return 1
  fi
  
  if ! test_interactive_update; then
    log "ERROR" "Falha no teste de atualização interativa"
    return 1
  fi
  
  log "SUCCESS" "✅ Todos os testes de atualização interativa foram concluídos com sucesso!"
  log "INFO" "  Diretório de teste: $TEST_DIR"
  log "INFO" "  Diretório home simulado: $TEST_HOME"
  log "INFO" "  Repositório de teste: $TEST_DOTFILES"
  
  return 0
}

# Executar função principal
main "$@"
