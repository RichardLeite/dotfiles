#!/usr/bin/env bash

# Cores para saída
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuração do ambiente de teste
TEST_DIR="/tmp/dotfiles-test-$(date +%s)"
TEST_HOME="$TEST_DIR/home"
TEST_DOTFILES="$TEST_DIR/dotfiles"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIXTURES_DIR="$SCRIPT_DIR/fixtures"

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
    *) echo -e "[$level] $timestamp - $message" ;;
  esac
}

# Função para limpar o ambiente de teste
cleanup() {
  if [ -d "$TEST_DIR" ]; then
    log "INFO" "Cleaning up test environment..."
    rm -rf "$TEST_DIR"
  fi
}

# Configurar armadilha para limpeza ao sair
trap cleanup EXIT

# Criar ambiente de teste
setup_test_environment() {
  log "INFO" "Setting up test environment in $TEST_DIR..."
  
  # Criar estrutura de diretórios
  mkdir -p "$TEST_HOME/.config/test-app"
  mkdir -p "$TEST_DOTFILES/files/home/.config/test-app"
  
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
    log "ERROR" "Failed to copy repository to test directory"
    return 1
  }
  
  # Criar diretório files/home no repositório de teste
  mkdir -p "$TEST_DOTFILES/files/home/.config/test-app"
  
  # Atualizar TRACKED_FILES no script
  sed -i "/^declare -A TRACKED_FILES=(/a \  [\"$TEST_HOME/.testrc\"]=\".testrc\"\n  [\"$TEST_HOME/.config/test-app/config.json\"]=\".config/test-app/config.json\"" "$TEST_DOTFILES/lib/commands/dotfiles.sh"
  
  # Modificar a função sync_new_files para ser não interativa
  sed -i 's/read -p "\(.*\)" choice/echo "\1 U"\nchoice="U"/g' "$TEST_DOTFILES/lib/commands/dotfiles.sh"
  
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
  
  log "SUCCESS" "Test environment set up successfully"
}

# Testar instalação
test_install() {
  log "INFO" "Testing installation..."
  
  # Remover arquivos de destino
  rm -f "$TEST_HOME/.testrc"
  rm -rf "$TEST_HOME/.config/test-app"
  
  # Executar instalação
  cd "$TEST_DOTFILES" || return 1
  if ! ./install.sh install; then
    log "ERROR" "Installation failed"
    return 1
  fi
  
  # Verificar se os arquivos foram instalados corretamente
  if [ ! -f "$TEST_HOME/.testrc" ] || [ ! -d "$TEST_HOME/.config/test-app" ]; then
    log "ERROR" "Files were not installed to the home directory"
    return 1
  fi
  
  log "SUCCESS" "Installation test passed"
  return 0
}

# Testar atualização
test_update() {
  log "INFO" "Testing update..."
  
  # Modificar arquivos locais com conteúdo das fixtures
  echo "# Configuração modificada em $(date)" >> "$TEST_HOME/.testrc"
  echo "MODIFICADO=sim" >> "$TEST_HOME/.testrc"
  
  # Modificar o JSON do app
  sed -i 's/"theme": "dark"/"theme": "light"/' "$TEST_HOME/.config/test-app/config.json"
  sed -i 's/"autoUpdate": false/"autoUpdate": true/' "$TEST_HOME/.config/test-app/config.json"
  
  # Executar atualização (não interativa)
  cd "$TEST_DOTFILES" || return 1
  if ! (echo "U" | ./install.sh update); then
    log "ERROR" "Update failed"
    return 1
  fi
  
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
  
  log "SUCCESS" "Update test passed"
  return 0
}

# Executar testes
log "INFO" "Starting update test..."

if setup_test_environment && test_install && test_update; then
  log "SUCCESS" "✅ All tests passed!"
  exit 0
else
  log "ERROR" "❌ Some tests failed"
  exit 1
fi
