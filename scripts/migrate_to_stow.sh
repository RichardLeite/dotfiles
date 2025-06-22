#!/usr/bin/env bash

# ===========================================================================
# Migrate to Stow
# ===========================================================================
# Script para migrar arquivos existentes para a estrutura do Stow
# ===========================================================================

# Carrega dependências
source "${BASH_SOURCE%/*}/../lib/utils/logger.sh"
source "${BASH_SOURCE%/*}/../lib/utils/stow_utils.sh"

# Diretório base
DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
STOW_DIR="${STOW_DIR:-$DOTFILES_DIR/stow}"
BACKUP_DIR="${BACKUP_DIR:-$DOTFILES_DIR/backups}"

# Carrega o arquivo de configuração com os arquivos rastreados
TRACKED_FILES_CONF="${DOTFILES_DIR}/config/tracked_files.conf"

# Verifica se o arquivo de configuração existe
if [ ! -f "$TRACKED_FILES_CONF" ]; then
  error "Arquivo de configuração não encontrado: $TRACKED_FILES_CONF"
  exit 1
fi

# Carrega o arquivo de configuração
source "$TRACKED_FILES_CONF" || {
  error "Falha ao carregar o arquivo de configuração: $TRACKED_FILES_CONF"
  exit 1
}

# Função para agrupar arquivos por módulo
get_modules_from_tracked_files() {
  declare -A modules
  
  info "Processando arquivos rastreados..."
  
  for source_path in "${!TRACKED_FILES[@]}"; do
    # Remove a variável $HOME do caminho e expande ~
    local expanded_path=$(eval echo "$source_path")
    local rel_path="${TRACKED_FILES[$source_path]}"
    
    # Remove o prefixo 'home/' do caminho relativo, se existir
    if [[ "$rel_path" == home/* ]]; then
      rel_path="${rel_path#home/}"
    fi
    
    # Determina o módulo baseado no primeiro diretório/nome do arquivo
    local module
    if [[ "$rel_path" == .* ]]; then
      # Se começar com ponto, é um arquivo oculto na home
      module="${rel_path#.}"  # Remove o ponto inicial
      module="${module%%/*}"  # Pega apenas o primeiro componente
      
      # Se for um arquivo oculto na raiz (sem barras)
      if [ "$module" = "$rel_path" ]; then
        module="${module#.}"  # Remove o ponto se ainda existir
      fi
      
      # Se for um arquivo de configuração do shell
      if [[ "$module" == *zsh* ]] || [[ "$module" == *bash* ]]; then
        module="shell"
      fi
    else
      # Pega o primeiro diretório do caminho
      module="${rel_path%%/*}"
    fi
    
    # Limpa o nome do módulo (remove caracteres inválidos)
    module=$(echo "$module" | tr -cd '[:alnum:]._-')
    
    # Se não conseguir determinar o módulo, usa 'misc'
    [ -z "$module" ] && module="misc"
    
    # Adiciona o caminho ao módulo correspondente
    modules[$module]="${modules[$module]} $rel_path"
    debug "Adicionado ao módulo '$module': $rel_path"
  done
  
  # Mostra um resumo dos módulos encontrados
  info "Módulos identificados: ${!modules[*]}"
  
  # Retorna o array associativo de módulos
  declare -p modules | sed -e 's/^declare -A [^=]*=//'
}

# Carrega os módulos a partir dos arquivos rastreados
eval "$(get_modules_from_tracked_files)"

# Converte para o formato antigo para compatibilidade
declare -A STOW_MODULES=()
for module in "${!modules[@]}"; do
  STOW_MODULES["$module"]="${modules[$module]}"
done

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Função auxiliar para mensagens de depuração
debug() {
  [ "${DEBUG:-false}" = "true" ] && echo -e "[DEBUG] $1" >&2
  return 0
}

# Mostra mensagem de ajuda
show_help() {
  echo -e "${GREEN}Uso: $0 [OPÇÕES] [MÓDULO]${NC}"
  echo "Migra arquivos de configuração para serem gerenciados pelo Stow"
  echo ""
  echo "Opções:"
  echo "  -l, --list      Lista todos os módulos disponíveis"
  echo "  -f, --force     Força a migração mesmo se o arquivo já estiver sendo gerenciado"
  echo "  -h, --help      Mostra esta mensagem de ajuda"
  echo ""
  echo "Argumentos:"
  echo "  MÓDULO          Nome do módulo específico para migrar (opcional)"
  echo ""
  echo "Exemplos:"
  echo "  $0                  # Migra todos os módulos"
  echo "  $0 zsh             # Migra apenas o módulo zsh"
  echo "  $0 --force zsh     # Força a migração do módulo zsh"
  echo "  $0 --list          # Lista todos os módulos disponíveis"
}

# Verifica se um comando está disponível
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Verifica as dependências necessárias
check_dependencies() {
  local missing_deps=0
  
  if ! command_exists stow; then
    error "GNU Stow não está instalado. Por favor, instale-o primeiro."
    missing_deps=$((missing_deps + 1))
  fi
  
  if ! command_exists rsync; then
    error "rsync não está instalado. Por favor, instale-o primeiro."
    missing_deps=$((missing_deps + 1))
  fi
  
  [ $missing_deps -eq 0 ] || return 1
  return 0
}

# Lista todos os módulos disponíveis
list_modules() {
  echo -e "${GREEN}Módulos disponíveis:${NC}"
  for module in "${!STOW_MODULES[@]}"; do
    echo "- $module"
    for file in ${STOW_MODULES[$module]}; do
      echo "  → $HOME/$file"
    done
    echo
  done
}

# Inicializa um módulo Stow
init_module() {
  local module=$1
  local force=${2:-false}
  local files=(${STOW_MODULES[$module]})
  
  if [ ${#files[@]} -eq 0 ] || [ -z "${files[*]}" ]; then
    error "Módulo não encontrado ou vazio: $module"
    return 1
  fi
  
  info "Inicializando módulo: $module"
  
  # Cria o diretório de backup se não existir
  mkdir -p "$BACKUP_DIR" || {
    error "Falha ao criar diretório de backup: $BACKUP_DIR"
    return 1
  }
  
  # Cria o módulo Stow
  if ! init_stow_module "$module" "$STOW_DIR"; then
    error "Falha ao inicializar módulo: $module"
    return 1
  fi
  
  local migrated=0
  local skipped=0
  local errors=0
  
  # Para cada arquivo/diretório no módulo
  for rel_path in "${files[@]}"; do
    local source_path="$HOME/$rel_path"
    
    # Remove espaços em branco extras
    rel_path=$(echo "$rel_path" | xargs)
    
    # Pula se estiver vazio
    [ -n "$rel_path" ] || continue
    
    # Verifica se o arquivo/diretório existe
    if [ ! -e "$source_path" ] && [ ! -L "$source_path" ]; then
      warn "Arquivo/diretório não encontrado: $source_path"
      skipped=$((skipped + 1))
      continue
    fi
    
    # Verifica se já está sendo gerenciado pelo Stow
    if ! $force && is_managed_by_stow "$source_path"; then
      info "Já gerenciado pelo Stow: $source_path (use --force para substituir)"
      skipped=$((skipped + 1))
      continue
    fi
    
    # Migra para o Stow
    info "Migrando para Stow: $source_path"
    if migrate_to_stow "$source_path" "$module" "$rel_path" "$STOW_DIR"; then
      success "Migrado com sucesso: $source_path"
      migrated=$((migrated + 1))
    else
      error "Falha ao migrar: $source_path"
      errors=$((errors + 1))
      continue
    fi
  done
  
  # Resumo
  echo -e "\n${GREEN}=== Resumo do módulo '$module' ===${NC}"
  echo -e "${GREEN}✓ Migrados: $migrated${NC}"
  echo -e "${YELLOW}↷ Pulados: $skipped${NC}"
  
  if [ $errors -gt 0 ]; then
    echo -e "${RED}✗ Erros: $errors${NC}"
    return 1
  else
    success "Módulo '$module' processado com sucesso"
    return 0
  fi
}

# Função principal
main() {
  local modules_to_migrate=()
  local force_migration=false
  
  # Processa argumentos
  while [ $# -gt 0 ]; do
    case "$1" in
      -h|--help)
        show_help
        return 0
        ;;
      -l|--list)
        list_modules
        return 0
        ;;
      -f|--force)
        force_migration=true
        shift
        ;;
      -*)
        error "Opção inválida: $1"
        show_help
        return 1
        ;;
      *)
        # Verifica se o módulo existe
        if [ -n "${STOW_MODULES[$1]}" ]; then
          modules_to_migrate+=("$1")
        else
          warn "Módulo desconhecido: $1 (será ignorado)"
        fi
        shift
        ;;
    esac
  done
  
  # Se nenhum módulo foi especificado, usa todos
  if [ ${#modules_to_migrate[@]} -eq 0 ]; then
    modules_to_migrate=("${!STOW_MODULES[@]}")
  fi
  
  # Verifica dependências
  if ! check_dependencies; then
    return 1
  fi
  
  info "Iniciando migração para Stow..."
  info "Diretório Stow: $STOW_DIR"
  info "Diretório de backup: $BACKUP_DIR"
  
  # Cria diretório stow se não existir
  mkdir -p "$STOW_DIR" || {
    error "Falha ao criar diretório stow: $STOW_DIR"
    return 1
  }
  
  # Inicializa cada módulo
  local total_migrated=0
  local total_errors=0
  
  for module in "${modules_to_migrate[@]}"; do
    echo -e "\n${GREEN}=== Processando módulo: $module ===${NC}"
    if init_module "$module" "$force_migration"; then
      # Instala o módulo Stow
      info "Instalando módulo Stow: $module"
      if stow_manage "stow" "$module" "$STOW_DIR"; then
        success "Módulo '$module' instalado com sucesso"
        total_migrated=$((total_migrated + 1))
      else
        error "Falha ao instalar módulo: $module"
        total_errors=$((total_errors + 1))
      fi
    else
      error "Falha ao processar módulo: $module"
      total_errors=$((total_errors + 1))
    fi
  done
  
  # Resumo final
  echo -e "\n${GREEN}=== Migração concluída ===${NC}"
  echo -e "${GREEN}✓ Módulos migrados com sucesso: $total_migrated${NC}"
  
  if [ $total_errors -gt 0 ]; then
    echo -e "${RED}✗ Módulos com erros: $total_errors${NC}"
    return 1
  else
    success "Todos os módulos foram migrados com sucesso!"
    return 0
  fi
}

# Executa a função principal
main "$@"
