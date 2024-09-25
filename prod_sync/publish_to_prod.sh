#!/bin/bash

# Imposta le variabili
STAGING_USER="staging_user"
STAGING_HOST="staging_host"
STAGING_UPLOAD_DIR="/path/to/staging/upload"
STAGING_DB_DUMP="/path/to/staging/db_dump.sql"
PROD_USER="prod_user"
PROD_HOST="localhost"
PROD_UPLOAD_DIR="/path/to/prod/upload"
PROD_DB_DUMP="/path/to/prod/db_dump.sql"
PROD_DB_NAME="your_prod_database_name"
PROD_DB_USER="postgres"
PROD_DB_HOST="localhost"
DRUPAL_DIR="/path/to/drupal"
BRANCH_NAME="your_branch_name"

# Path dello script
SCRIPT_DIR=$(dirname "$(realpath "$0")")
# Nome del file di lock dinamico
SCRIPT_NAME=$(basename "$0" .sh)
LOCK_FILE="$SCRIPT_DIR/${SCRIPT_NAME}.lock"

# Crea il file di lock
touch $LOCK_FILE

# Funzione per rimuovere il file di lock
cleanup() {
  if [ $? -eq 0 ]; then
    rm -f $LOCK_FILE
  fi
}

# Registra la funzione cleanup per essere eseguita all'uscita con successo
trap cleanup 0

BACKUP_DIR="$SCRIPT_DIR/backup"

# Importa le funzioni di logging
source $SCRIPT_DIR/scripts/logging.sh

# Controlla se il file di lock esiste
if [ -f "$LOCK_FILE" ]; then
  log_message "error" "File di lock presente. Un'altra istanza dello script è in esecuzione."
  exit 1
fi

source $SCRIPT_DIR/scripts/commands.sh