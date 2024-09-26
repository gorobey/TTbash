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
# Path della cartella di backup
BACKUP_DIR="$SCRIPT_DIR/backup"

# Importa le funzioni di logging
source $SCRIPT_DIR/scripts/logging.sh
# Importa le funzioni di lock
source $SCRIPT_DIR/scripts/lock_file.sh
# Importa le funzioni di comandi
source $SCRIPT_DIR/scripts/commands.sh