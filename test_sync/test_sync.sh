#!/bin/bash

# Path dello script
SCRIPT_DIR=$(dirname "$(realpath "$0")")

# Imposta le variabili
DRUPAL_DIR="/path/to/drupal"
SYNC_DIR="/path/to/sync"
BRANCH_NAME="your_branch_name"
LOG_FILE="$SCRIPT_DIR/test_sync.log"

# Importa le funzioni di logging
source $SCRIPT_DIR/logging.sh

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
cd $SYNC_DIR  || { log_message "error" "Errore installazione Drupal non trovata"; exit 1; }
CMD=$(git add . 2>&1)
if [ $? -eq 0 ]; then
  log_message "success" "Git add completato con successo"
else
  log_message "error" "Errore durante git add"
  exit 1
fi

CMD=$(git commit -m "Daily config export" 2>&1)
if [ $? -eq 0 ]; then
  log_message "success" "Git commit completato con successo"
else
  log_message "error" "Errore durante git commit:\n\r$CMD"
  exit 1
fi

CMD=$(git push origin $BRANCH_NAME 2>&1)
if [ $? -eq 0 ]; then
  log_message "success" "Git push completato con successo"
else
  log_message "error" "Errore durante git push:\n\r$CMD"
  exit 1
fi

# Log di successo
log_message "info" "Esecuzione completata con successo!"