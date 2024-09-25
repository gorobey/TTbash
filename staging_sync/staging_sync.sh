#!/bin/bash

# Path dello script
SCRIPT_DIR=$(dirname "$(realpath "$0")")

# Imposta le variabili
DB_DUMP="/path/to/db_dump.sql"
DB_NAME="your_staging_database_name"
DB_USER="postgres"
DB_HOST="localhost"
DRUPAL_DIR="/path/to/drupal"
BRANCH_NAME="your_branch_name"
LOG_FILE="$SCRIPT_DIR/staging_sync.log"

# Importa le funzioni di logging
source $SCRIPT_DIR/logging.sh

# Drop delle tabelle esistenti
psql -U $DB_USER -h $DB_HOST -d $DB_NAME -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;" 2>> $LOG_FILE || { log_error "Errore durante il drop delle tabelle"; exit 1; }

# Importa il dump del database
pg_restore -U $DB_USER -h $DB_HOST -d $DB_NAME -v $DB_DUMP 2>> $LOG_FILE || { log_error "Errore durante l'importazione del dump del database"; exit 1; }

# Pull delle configurazioni dal branch
cd $DRUPAL_DIR
git pull origin $BRANCH_NAME 2>> $LOG_FILE || { log_error "Errore durante git pull"; exit 1; }

# Importa le configurazioni
./vendor/drush/drush/drush config-import -y 2>> $LOG_FILE || { log_error "Errore durante l'importazione delle configurazioni"; exit 1; }

# Log di successo
log_success "$(date '+%Y-%m-%d %H:%M:%S') - Esecuzione completata con successo"