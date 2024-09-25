#!/bin/bash

# Colori
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\e[0;36m'
NC='\033[0m' # No Color
LOG_FILE="$SCRIPT_DIR/sync.log"

# Funzione per loggare messaggi
log_message() {
    local type=$1
    local message=$2
    local color

    case $type in
        info)
            color=$CYAN
            ;;
        success)
            color=$GREEN
            ;;
        error)
            color=$RED
            ;;
        *)
            color=$NC
            ;;
    esac

    LOG_MSG="${color}$(date '+%Y-%m-%d %H:%M:%S') - $message${NC}"
    echo -e $LOG_MSG | tee -a $LOG_FILE
}