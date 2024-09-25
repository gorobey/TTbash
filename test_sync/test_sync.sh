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
cd $DRUPAL_DIR || { log_error "Errore installazione Drupal non trovata"; exit 1; }
./vendor/drush/drush/drush config-export --destination=$SYNC_DIR -y 2>> $LOG_FILE || { log_error "Errore durante l'esportazione delle configurazioni da Drupal"; exit 1; }

# Add, Commit e Push delle configurazioni esportate
cd $SYNC_DIR
git add . 2>> $LOG_FILE || { log_error "Errore durante git add"; exit 1; }
git commit -m "Daily config export" 2>> $LOG_FILE || { log_error "Errore durante git commit"; exit 1; }
git push origin $BRANCH_NAME 2>> $LOG_FILE || { log_error "Errore durante git push"; exit 1; }

# Log di successo
echo "$(date '+%Y-%m-%d %H:%M:%S') - Esecuzione completata con successo" >> $LOG_FILE