# dotfiles

Repositório de configurações pessoais para Arch Linux com Hyprland.

## 📋 Sobre

Este repositório contém as configurações pessoais do sistema, incluindo arquivos de configuração para:

- Shell (zsh, bash)
- Terminal (kitty, warp-terminal)
- WM (Hyprland)
- Outros programas (Ax-Shell, cava, etc.)

## 🚀 Instalação

### Pré-requisitos

- Arch Linux
- Git
- Zsh (opcional para configurações zsh)

### Comandos disponíveis

O script `install.sh` oferece os seguintes comandos:

```bash
./install.sh [opções] comando
```

### Comandos

- `init`: Inicializa o repositório com as configurações existentes no sistema
- `install`: Copia os dotfiles para o sistema
- `update`: Atualiza o repositório com as mudanças locais
- `list`: Lista os dotfiles gerenciados
- `help`: Mostra esta mensagem de ajuda

### Opções

- `-v, --verbose`: Ativa saída detalhada
- `-f, --force`: Força a sobrescrita sem confirmação
- `-h, --help`: Mostra esta mensagem de ajuda

### Exemplos

```bash
# Inicializar repositório com configurações existentes
./install.sh init

# Instalar dotfiles no sistema
./install.sh install

# Forçar instalação sem confirmação
./install.sh -f install
```

## 📁 Estrutura do Repositório

```
dotfiles/
├── home/              # Arquivos de configuração da home
│   ├── zshrc
│   ├── bashrc
│   └── p10k.zsh
├── config/           # Diretórios de configuração
│   ├── hypr
│   ├── Ax-Shell
│   ├── kitty
│   ├── cava
│   ├── warp-terminal
│   └── matugen
└── install.sh       # Script de instalação
```

## 🛡️ Backup

O script realiza automaticamente backup dos arquivos existentes antes de sobrescrevê-los. Os backups são armazenados em:

```
~/.dotfiles_backup/20250603_174842/
```

## 🔧 Configurações

As configurações são organizadas em dois tipos:

1. Arquivos de configuração da home:
   - `.zshrc`
   - `.bashrc`
   - `.p10k.zsh`

2. Diretórios de configuração:
   - `hypr`
   - `Ax-Shell`
   - `kitty`
   - `cava`
   - `warp-terminal`
   - `matugen`

## 📝 Notas

- O script não usa links simbólicos, fazendo cópia direta dos arquivos
- Sem dependência do repositório git após a instalação
- Backup automático de arquivos existentes
- Verificação de arquivos antes de sobrescrever
- Opção de força para sobrescrever sem confirmação

## 📝 Licença

MIT License - veja o arquivo LICENSE para detalhes.
