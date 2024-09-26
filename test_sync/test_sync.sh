#!/bin/bash
# Questo script deve essere eseguito a .git/hooks/pre-push
# Deve essere eseguito sul server di TEST
# Viene utilizzato per fare il push di  file modificati e configurazioni della versione di TEST su git

# Imposta le variabili
STAGING_SYNC_DIR="/path/to/staging_sync"
TEST_SYNC_DIR="/path/to/test_sync"
DRUPAL_DIR="/path/to/drupal"
BRANCH_NAME="your_branch_name"

# Path dello script
SCRIPT_DIR=$(dirname "$(realpath "$0")")
# Nome del file di lock dinamico
SCRIPT_NAME=$(basename "$0" .sh)

# Path della cartella di Sync
SYNC_DIR="$SCRIPT_DIR/sync"

# Importa le funzioni di logging
source $SCRIPT_DIR/scripts/logging.sh
# Importa le funzioni di lock
source $SCRIPT_DIR/scripts/lock_file.sh

# Log di avvio
log_message "info" "TEST Sync - Inizio esecuzione"

# Esporta le configurazioni da Drupal
cd $DRUPAL_DIR || { log_message "error" "Errore installazione Drupal non trovata in $DRUPAL_DIR"; exit 1; }
CMD=$(./vendor/drush/drush/drush config-export --destination=$SYNC_DIR -y 2>&1)
if [ $? -eq 0 ]; then
  log_message "success" "Esportazione delle configurazioni da Drupal completata con successo"
else
  log_message "error" "Errore durante l'esportazione delle configurazioni da Drupal:\n\r$CMD"
  exit 1
fi

# Add, Commit e Push delle configurazioni esportate
cd $SYNC_DIR  || { log_message "error" "Errore installazione Drupal non trovata in $SYNC_DIR"; exit 1; }
CMD=$(git add . 2>&1)
if [ $? -eq 0 ]; then
  log_message "success" "Git add completato con successo"
else
  log_message "error" "Errore durante git add"
  exit 1
fi

# Log di successo
log_message "info" "Esecuzione completata con successo!"