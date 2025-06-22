#!/usr/bin/env bash

# ===========================================================================
# Stow Manager
# ===========================================================================
# Script para gerenciar módulos Stow
# ===========================================================================

# Carrega dependências
source "${BASH_SOURCE%/*}/../lib/utils/logger.sh"
source "${BASH_SOURCE%/*}/../lib/utils/stow_utils.sh"

# Diretório base
DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
STOW_DIR="$DOTFILES_DIR/stow"

# Módulos disponíveis
AVAILABLE_MODULES=(
  "zsh"
  "vscode"
  "hypr"
  "warp-terminal"
  "ax-shell"
)

# Mostra o uso do script
show_usage() {
  cat << EOF
Uso: $(basename "$0") [OPÇÕES] [MÓDULOS...]

Opções:
  -a, --all           Aplicar ação em todos os módulos
  -s, --stow          Aplicar stow nos módulos especificados
  -d, --delete        Aplicar unstow nos módulos especificados
  -r, --restow        Reaplicar stow (unstow + stow) nos módulos
  -l, --list          Listar módulos disponíveis
  -h, --help          Mostrar esta mensagem de ajuda

Se nenhum módulo for especificado, a ação será aplicada a todos os módulos.

Exemplos:
  # Aplicar stow em todos os módulos
  $0 -s -a

  # Aplicar stow apenas nos módulos zsh e vscode
  $0 -s zsh vscode

  # Reaplicar stow em todos os módulos
  $0 -r -a

  # Remover módulos zsh e vscode
  $0 -d zsh vscode
EOF
}

# Lista os módulos disponíveis
list_modules() {
  info "Módulos disponíveis em $STOW_DIR:"
  for module in "${AVAILABLE_MODULES[@]}"; do
    if [ -d "$STOW_DIR/$module" ]; then
      echo "- $module"
    fi
  done
}

# Executa uma ação em um módulo
run_action() {
  local action=$1
  local module=$2
  
  # Garante que estamos usando o caminho absoluto
  STOW_DIR=$(realpath -e "$STOW_DIR" 2>/dev/null || echo "$STOW_DIR")
  
  # Verifica se o diretório Stow existe
  if [ ! -d "$STOW_DIR" ]; then
    error "Diretório Stow não encontrado: $STOW_DIR"
    return 1
  fi
  
  # Verifica se o módulo existe
  if [ ! -d "$STOW_DIR/$module" ]; then
    error "Módulo $module não encontrado em $STOW_DIR"
    return 1
  fi
  
  case $action in
    stow|restow|delete)
      local stow_action="$action"
      [ "$action" = "delete" ] && stow_action="unstow"
      
      # Executa o comando Stow com o caminho absoluto
      stow_manage "$stow_action" "$module" "$STOW_DIR"
      ;;
    *)
      error "Ação inválida: $action"
      return 1
      ;;
  esac
}

# Função principal
main() {
  local action=""
  local all_modules=false
  local modules=()
  
  # Processa argumentos
  while [[ $# -gt 0 ]]; do
    case $1 in
      -a|--all)
        all_modules=true
        shift
        ;;
      -s|--stow)
        action="stow"
        shift
        ;;
      -d|--delete)
        action="delete"
        shift
        ;;
      -r|--restow)
        action="restow"
        shift
        ;;
      -l|--list)
        list_modules
        exit 0
        ;;
      -h|--help)
        show_usage
        exit 0
        ;;
      -*)
        error "Opção inválida: $1"
        show_usage
        exit 1
        ;;
      *)
        modules+=("$1")
        shift
        ;;
    esac
  done
  
  # Se nenhuma ação for especificada, mostra ajuda
  if [ -z "$action" ]; then
    show_usage
    exit 0
  fi
  
  # Se nenhum módulo for especificado, usa todos
  if [ ${#modules[@]} -eq 0 ] && [ "$all_modules" = false ]; then
    info "Nenhum módulo especificado. Use -a para aplicar a todos os módulos ou especifique os módulos."
    show_usage
    exit 1
  fi
  
  # Se a flag --all foi usada, usa todos os módulos disponíveis
  if [ "$all_modules" = true ]; then
    modules=("${AVAILABLE_MODULES[@]}")
  fi
  
  # Executa a ação em cada módulo
  for module in "${modules[@]}"; do
    if [ ! -d "$STOW_DIR/$module" ]; then
      warn "Módulo não encontrado: $module"
      continue
    fi
    
    run_action "$action" "$module"
  done
  
  return 0
}

# Executa a função principal
main "$@"
