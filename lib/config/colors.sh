#!/usr/bin/env bash

# Colors configuration
if [ -t 1 ]; then
    # Use tput for better compatibility with different terminals
    if command -v tput >/dev/null 2>&1; then
        export RED=$(tput setaf 1)
        export GREEN=$(tput setaf 2)
        export YELLOW=$(tput setaf 3)
        export BLUE=$(tput setaf 4)
        export MAGENTA=$(tput setaf 5)
        export CYAN=$(tput setaf 6)
        export BOLD=$(tput bold)
        export NC=$(tput sgr0) # Reset color
    else
        # Fallback to ANSI color codes if tput is not available
        export RED='\e[0;31m'
        export GREEN='\e[0;32m'
        export YELLOW='\e[0;33m'
        export BLUE='\e[0;34m'
        export MAGENTA='\e[0;35m'
        export CYAN='\e[0;36m'
        export BOLD='\e[1m'
        export NC='\e[0m' # Reset color
    fi
else
    # No colors if not a terminal
    export RED='' GREEN='' YELLOW='' BLUE='' MAGENTA='' CYAN='' BOLD='' NC=''
fi
