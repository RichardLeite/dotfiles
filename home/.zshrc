# ~/.zshrc file for zsh interactive shells
# Created by CodeAssistant for richao

#------------------------------------------------
# POWERLEVEL10K THEME
#------------------------------------------------
# Enable Powerlevel10k instant prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Source Powerlevel10k theme
source ~/.powerlevel10k/powerlevel10k.zsh-theme

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

#------------------------------------------------
# PATH SETTINGS
#------------------------------------------------
# Preserve current PATH from bash
export PATH="/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/bin/site_perl:/usr/bin/vendor_perl:/usr/bin/core_perl"

#------------------------------------------------
# HISTORY SETTINGS
#------------------------------------------------
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY             # Share history between all sessions
setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicate entries first
setopt HIST_IGNORE_DUPS          # Don't record duplicates
setopt HIST_IGNORE_SPACE         # Don't record entries starting with a space
setopt HIST_VERIFY               # Show command with history expansion before running it
setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks from commands

#------------------------------------------------
# COMPLETION SYSTEM
#------------------------------------------------
autoload -Uz compinit
compinit

zstyle ':completion:*' menu select            # Select completions with arrow keys
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}' # Case insensitive completion
zstyle ':completion:*' rehash true            # Automatically find new executables
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}" # Colored completion

#------------------------------------------------
# DIRECTORY NAVIGATION
#------------------------------------------------
setopt AUTO_CD                  # Change directory without cd command
setopt AUTO_PUSHD               # Push the current directory visited on the stack
setopt PUSHD_IGNORE_DUPS        # Do not store duplicates in the stack
setopt PUSHD_SILENT             # Do not print directory stack

#------------------------------------------------
# ALIASES (imported from .bashrc)
#------------------------------------------------
alias ls='ls --color=auto'
alias grep='grep --color=auto'

# Additional useful aliases
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'

#------------------------------------------------
# ZSH PLUGINS (optional - you can install these later)
#------------------------------------------------
# Note: Install these plugins for enhanced functionality:
# 1. zsh-autosuggestions: git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
# 2. zsh-syntax-highlighting: git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.zsh/zsh-syntax-highlighting

# Source plugins if they exist
[[ -f ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
[[ -f ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

#------------------------------------------------
# KEY BINDINGS
#------------------------------------------------
bindkey -e                      # Use emacs keybindings
bindkey '^[[A' up-line-or-search        # Up arrow for search
bindkey '^[[B' down-line-or-search      # Down arrow for search
bindkey '^[[H' beginning-of-line        # Home key
bindkey '^[[F' end-of-line              # End key
bindkey '^[[3~' delete-char             # Delete key
bindkey '^[[1;5C' forward-word          # Ctrl+Right
bindkey '^[[1;5D' backward-word         # Ctrl+Left

#------------------------------------------------
# MISCELLANEOUS
#------------------------------------------------
# Set default editor
export EDITOR='nano'

# Automatically update PATH with ~/.local/bin if it exists
[[ -d $HOME/.local/bin ]] && export PATH="$HOME/.local/bin:$PATH"

# Show welcome message
echo "Welcome to zsh with powerlevel10k! Type 'p10k configure' to customize your prompt."


PATH=~/.console-ninja/.bin:$PATH