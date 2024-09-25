#!/bin/bash
# Questo è uno script da eseguire via cron
# Viene utilizzato per importare file modificati e configurazioni della versione di TEST in quella di STAGING
# deve essere eseguito per secondo
# Deve essere eseguito sul server di TEST
# Deve essere eseguito dopo aver l'esecuzione di Prod Sync sul server di PRODUZIONE

# Imposta le variabili
STAGING_SYNC_DIR="/path/to/staging_sync"
TEST_SYNC_DIR="/path/to/test_sync"
DRUPAL_DIR="/path/to/drupal"
BRANCH_NAME="your_branch_name"

# Path dello script
SCRIPT_DIR=$(dirname "$(realpath "$0")")

# Path della cartella di Sync
SYNC_DIR="$SCRIPT_DIR/sync"

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

# Importa le funzioni di logging
source $SCRIPT_DIR/scripts/logging.sh

# Controlla se il file di lock esiste
if [ -f "$LOCK_FILE" ]; then
  log_message "error" "File di lock presente. Un'altra istanza dello script è in esecuzione."
  exit 1
fi

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