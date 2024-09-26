#!/bin/bash
# Questo è uno script da eseguire via cron
# Viene utilizzato per sincronizzare la copia di staging con quella di produzione
# Deve essere eseguito sul server di PRODUZIONE
# Deve essere eseguito per primo

# Imposta le variabili
STAGING_SYNC_DIR="/path/to/staging_sync"
TEST_SYNC_DIR="/path/to/test_sync"
UPLOAD_DIR="/path/to/upload"
DB_DUMP="db_dump.sql"
STAGING_USER="staging_user"
STAGING_HOST="staging_host"
STAGING_UPLOAD_DIR="/path/to/staging/upload"
STAGING_DB_DUMP="/path/to/staging/db_dump.sql"

# Path dello script
SCRIPT_DIR=$(dirname "$(realpath "$0")")

# Nome del file di lock dinamico
SCRIPT_NAME=$(basename "$0" .sh)
# Path della cartella di Sync
SYNC_DIR="/path/to/staging_sync"

# Importa le funzioni di logging
source $SCRIPT_DIR/scripts/logging.sh
# Importa le funzioni di lock
source $SCRIPT_DIR/scripts/lock_file.sh

# Log di avvio
log_message "info" "PROD Sync - Inizio esecuzione"

# Scarica i file di upload
CMD=$(rsync -avz $UPLOAD_DIR $STAGING_USER@$STAGING_HOST:$STAGING_UPLOAD_DIR 2>&1)
if [ $? -eq 0 ]; then
  log_message "success" "Rsync dei file di upload completato con successo"
else
  log_message "error" "Errore durante rsync dei file di upload:\n\r$CMD"
  exit 1
fi

# Esegui il dump del database
CMD=$(pg_dump -U postgres -h localhost -F c -b -v -f $DB_DUMP your_database_name 2>&1)
if [ $? -eq 0 ]; then
  log_message "success" "Dump del database completato con successo"
else
  log_message "error" "Errore durante il dump del database:\n\r$CMD"
  exit 1
fi

# Trasferisci il dump del database al server di staging
CMD=$(rsync -avz $DB_DUMP $STAGING_USER@$STAGING_HOST:$STAGING_DB_DUMP 2>&1)
if [ $? -eq 0 ]; then
  log_message "success" "Trasferimento del dump del database completato con successo"
else
  log_message "error" "Errore durante il trasferimento del dump del database:\n\r$CMD"
  exit 1
fi

# Log di successo
log_message "info" "Esecuzione completata con successo!"

ssh $STAGING_USER@$STAGING_HOST "nohup bash -c 'cd $STAGING_SYNC_DIR && ./staging_sync.sh' > /dev/null 2>&1 &"