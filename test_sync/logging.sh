#!/bin/bash

# Colori
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color
LOG_FILE="$SCRIPT_DIR/prod_sync.log"

# Funzione per loggare errori
log_error() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - ${RED}$1${NC}" >> $LOG_FILE
}

# Funzione per loggare successi
log_success() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - ${GREEN}$1${NC}" >> $LOG_FILE
}