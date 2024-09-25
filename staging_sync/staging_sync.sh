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
CMD=$(psql -U $DB_USER -h $DB_HOST -d $DB_NAME -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;" 2>&1)
if [ $? -eq 0 ]; then
  log_message "success" "Drop delle tabelle completato con successo"
else
  log_message "error" "Errore durante il drop delle tabelle\n\r$CMD"
  exit 1
fi

# Importa il dump del database
CMD=$(pg_restore -U $DB_USER -h $DB_HOST -d $DB_NAME -v $DB_DUMP 2>&1)
if [ $? -eq 0 ]; then
  log_message "success" "Importazione del dump del database completata con successo"
else
  log_message "error" "Errore durante l'importazione del dump del database:\n\r$CMD"
  exit 1
fi

# Pull delle configurazioni dal branch
cd $DRUPAL_DIR || { log_message "error" "Errore installazione Drupal non trovata in:\n\r$DRUPAL_DIR"; exit 1; }
CMD=$(git pull origin $BRANCH_NAME -y 2>&1)
if [ $? -eq 0 ]; then
  log_message "success" "Git pull delle configurazioni completato con successo"
else
  log_message "error" "Errore durante git pull:\n\r$CMD"
  exit 1
fi

# Importa le configurazioni
CMD=$(./vendor/drush/drush/drush config-import -y 2>&1)
if [ $? -eq 0 ]; then
  log_message "success" "Importazione delle configurazioni completata con successo"
else
  log_message "error" "Errore durante l'importazione delle configurazioni:\n\r$CMD"
  exit 1
fi

# Log di successo
log_message "success" "Esecuzione completata con successo"