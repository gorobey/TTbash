#!/bin/bash

# Path dello script
SCRIPT_DIR=$(dirname "$(realpath "$0")")

# Imposta le variabili
UPLOAD_DIR="/path/to/upload"
DB_DUMP="/path/to/db_dump.sql"
STAGING_USER="staging_user"
STAGING_HOST="staging_host"
STAGING_UPLOAD_DIR="/path/to/staging/upload"
STAGING_DB_DUMP="/path/to/staging/db_dump.sql"

# Importa le funzioni di logging
source $SCRIPT_DIR/logging.sh

# Scarica i file di upload
rsync -avz $UPLOAD_DIR $STAGING_USER@$STAGING_HOST:$STAGING_UPLOAD_DIR 2>> $LOG_FILE || { log_error "Errore durante rsync dei file di upload"; exit 1; }

# Esegui il dump del database
pg_dump -U postgres -h localhost -F c -b -v -f $DB_DUMP your_database_name 2>> $LOG_FILE || { log_error "Errore durante il dump del database"; exit 1; }

# Trasferisci il dump del database al server di staging
scp $DB_DUMP $STAGING_USER@$STAGING_HOST:$STAGING_DB_DUMP 2>> $LOG_FILE || { log_error "Errore durante il trasferimento del dump del database"; exit 1; }

# Log di successo
echo "$(date '+%Y-%m-%d %H:%M:%S') - Esecuzione completata con successo" >> $LOG_FILE