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
  
  # Exportar variáveis de ambiente para o teste
  export HOME="$TEST_HOME"
  export DOTFILES_DIR="$TEST_DOTFILES"
  
  # Criar um script de instalação simplificado para teste
  cat > "$TEST_DOTFILES/install.sh" << 'EOL'
#!/bin/bash
# Script de instalação simplificado para testes

# Importar funções de dotfiles.sh
source "$DOTFILES_DIR/lib/commands/dotfiles.sh"

# Executar instalação
install_dotfiles
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
  if [ ! -f "$TEST_HOME/.testrc" ]; then
    log "ERROR" "Arquivo .testrc não foi instalado no diretório home"
    return 1
  fi
  
  if [ ! -f "$TEST_HOME/.config/test-app/config.json" ]; then
    log "ERROR" "Arquivo config.json não foi instalado no diretório .config/test-app/"
    return 1
  fi
  
  # Verificar o conteúdo dos arquivos
  if ! grep -q "ENV=test" "$TEST_HOME/.testrc"; then
    log "ERROR" "Conteúdo do arquivo .testrc não corresponde ao esperado"
    return 1
  fi
  
  if ! grep -q '"app": "test-app"' "$TEST_HOME/.config/test-app/config.json"; then
    log "ERROR" "Conteúdo do arquivo config.json não corresponde ao esperado"
    return 1
  fi
  
  log "SUCCESS" "Installation test passed"
  return 0
}

# Executar testes
log "INFO" "Starting installation test..."

if setup_test_environment && test_install; then
  log "SUCCESS" "✅ All tests passed!"
  exit 0
else
  log "ERROR" "❌ Some tests failed"
  exit 1
fi
