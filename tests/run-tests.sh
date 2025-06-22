#!/usr/bin/env bash

# Cores para saída
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Diretório raiz do projeto
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_DIR="$PROJECT_ROOT/tests"

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

# Função para executar um teste individual
run_test() {
  local test_script=$1
  local test_name
  test_name=$(basename "$test_script")
  
  log "INFO" "Executing test: $test_name"
  
  # Executa o teste e captura a saída
  if "$test_script"; then
    log "SUCCESS" "Test $test_name passed"
    return 0
  else
    log "ERROR" "Test $test_name failed"
    return 1
  fi
}

# Verifica se um diretório de teste temporário deve ser usado
if [ "$1" = "--temp-dir" ] || [ "$1" = "-t" ]; then
  export USE_TEMP_DIR=1
fi

# Cria diretório temporário para testes, se necessário
if [ -n "$USE_TEMP_DIR" ]; then
  TEMP_TEST_DIR="/tmp/dotfiles-test-$(date +%s)"
  mkdir -p "$TEMP_TEST_DIR"
  export TEST_DIR="$TEMP_TEST_DIR"
  log "INFO" "Using temporary test directory: $TEST_DIR"
fi

# Lista de testes para executar (em ordem)
TEST_SCRIPTS=(
  "$TEST_DIR/test-install.sh"
  "$TEST_DIR/test-update-noninteractive.sh"
  "$TEST_DIR/test-update.sh"
  # Adicione mais testes aqui
)

# Contadores de resultados
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Executa todos os testes
for test_script in "${TEST_SCRIPTS[@]}"; do
  if [ -x "$test_script" ]; then
    ((TOTAL_TESTS++))
    if run_test "$test_script"; then
      ((PASSED_TESTS++))
    else
      ((FAILED_TESTS++))
    fi
  else
    log "ERROR" "Test script not found or not executable: $test_script"
  fi
done

# Resumo
log "INFO" "Tests completed: $TOTAL_TESTS total, $PASSED_TESTS passed, $FAILED_TESTS failed"

# Limpa diretório temporário, se usado
if [ -n "$USE_TEMP_DIR" ] && [ -d "$TEMP_TEST_DIR" ]; then
  rm -rf "$TEMP_TEST_DIR"
  log "INFO" "Cleaned up temporary test directory"
fi

# Retorna código de saída apropriado
if [ $FAILED_TESTS -gt 0 ]; then
  exit 1
else
  exit 0
fi
