#!/usr/bin/env bash

# ===========================================================================
# Stow Utilities
# ===========================================================================
# Funções auxiliares para gerenciamento de dotfiles com GNU Stow
# ===========================================================================

# Verifica se um arquivo/diretório já está sendo gerenciado pelo Stow
# Retorna 0 se for gerenciado pelo Stow, 1 caso contrário
is_managed_by_stow() {
  local target="$1"
  
  # Se não existir, não está sendo gerenciado
  [ -e "$target" ] || return 1
  
  # Se for um link simbólico que aponta para dentro do diretório stow/
  if [ -L "$target" ]; then
    local link_target
    link_target=$(readlink -f "$target" 2>/dev/null)
    
    # Verifica se o link aponta para dentro do diretório stow/
    if [[ "$link_target" == *"/stow/"* ]]; then
      return 0
    fi
  fi
  
  # Se for um diretório, verifica se contém um arquivo .stow
  if [ -d "$target" ] && [ -f "$target/.stow" ]; then
    return 0
  fi
  
  return 1
}

# Aplica uma ação do Stow (stow, unstow, restow) em um módulo
stow_manage() {
  local action=$1  # stow, unstow, restow
  local module=$2
  local stow_dir="${3:-$DOTFILES_DIR/stow}"
  local target_dir="${4:-$HOME}"
  
  # Verifica se o diretório do módulo existe
  if [ ! -d "$stow_dir/$module" ]; then
    error "Módulo $module não encontrado em $stow_dir"
    return 1
  fi
  
  # Verifica se o Stow está instalado
  if ! command -v stow &> /dev/null; then
    error "GNU Stow não está instalado"
    return 1
  fi
  
  # Executa o comando Stow apropriado
  case "$action" in
    stow|restow|unstow)
      info "Executando 'stow $action' no módulo: $module"
      stow --dir="$stow_dir" --target="$target_dir" "$action" "$module"
      local status=$?
      
      if [ $status -eq 0 ]; then
        success "Módulo $module $action com sucesso"
      else
        error "Falha ao executar 'stow $action' no módulo $module"
      fi
      return $status
      ;;
    *)
      error "Ação inválida: $action. Use 'stow', 'unstow' ou 'restow'"
      return 1
      ;;
  esac
}

# Inicializa um novo módulo Stow
init_stow_module() {
  local module=$1
  local stow_dir="${2:-$DOTFILES_DIR/stow}"
  
  # Cria o diretório do módulo
  mkdir -p "$stow_dir/$module" || {
    error "Falha ao criar diretório do módulo: $stow_dir/$module"
    return 1
  }
  
  # Cria arquivo .stow para identificar o diretório
  touch "$stow_dir/$module/.stow" || {
    error "Falha ao criar arquivo .stow em $stow_dir/$module"
    return 1
  }
  
  success "Módulo Stow '$module' inicializado em $stow_dir/$module"
  return 0
}

# Migra um arquivo/diretório para ser gerenciado pelo Stow
migrate_to_stow() {
  local source="$1"
  local module="$2"
  local rel_path="$3"
  local stow_dir="${4:-$DOTFILES_DIR/stow}"
  
  # Verifica se o arquivo/diretório de origem existe
  if [ ! -e "$source" ] && [ ! -L "$source" ]; then
    warn "Arquivo/diretório de origem não encontrado: $source"
    return 1
  fi
  
  # Cria o diretório de destino no módulo Stow
  local target_dir="$(dirname "$stow_dir/$module/$rel_path")"
  mkdir -p "$target_dir" || {
    error "Falha ao criar diretório de destino: $target_dir"
    return 1
  }
  
  # Cria um backup do arquivo original
  local backup_path="${source}.stow_backup_$(date +%s)"
  
  # Copia o arquivo/diretório para o módulo Stow
  if [ -d "$source" ] && [ ! -L "$source" ]; then
    # Para diretórios, usamos rsync
    info "Copiando diretório: $source"
    if ! rsync -a "$source/" "$stow_dir/$module/$rel_path/"; then
      error "Falha ao copiar diretório: $source"
      return 1
    fi
    
    # Cria um backup do diretório original
    if ! mv "$source" "$backup_path"; then
      error "Falha ao criar backup do diretório original: $source"
      return 1
    fi
    
    # Cria um link simbólico para o diretório no repositório
    if ! ln -s "$stow_dir/$module/$rel_path" "$source"; then
      error "Falha ao criar link simbólico para: $source"
      # Tenta restaurar o backup em caso de falha
      mv "$backup_path" "$source" || error "Falha ao restaurar backup de: $backup_path"
      return 1
    fi
    
  else
    # Para arquivos, copiamos e criamos um link simbólico
    info "Copiando arquivo: $source"
    if ! cp -a "$source" "$stow_dir/$module/$rel_path"; then
      error "Falha ao copiar arquivo: $source"
      return 1
    fi
    
    # Cria um backup do arquivo original
    if ! mv "$source" "$backup_path"; then
      error "Falha ao criar backup do arquivo original: $source"
      return 1
    fi
    
    # Cria um link simbólico para o arquivo no repositório
    if ! ln -s "$stow_dir/$module/$rel_path" "$source"; then
      error "Falha ao criar link simbólico para: $source"
      # Tenta restaurar o backup em caso de falha
      mv "$backup_path" "$source" || error "Falha ao restaurar backup de: $backup_path"
      return 1
    fi
  fi
  
  success "Migrado para Stow: $source -> $stow_dir/$module/$rel_path"
  info "Backup mantido em: $backup_path"
  return 0
}

# Exporta as funções para serem usadas em outros scripts
export -f is_managed_by_stow stow_manage init_stow_module migrate_to_stow
