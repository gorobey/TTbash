#!/bin/bash

# Path dello script
SCRIPT_DIR=$(dirname "$(realpath "$0")")

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
LOG_FILE="$SCRIPT_DIR/publish_to_prod.log"

# Importa le funzioni di logging
source $SCRIPT_DIR/logging.sh

# Sincronizza i file di staging con il server di produzione
rsync -avz $STAGING_USER@$STAGING_HOST:$STAGING_UPLOAD_DIR $PROD_UPLOAD_DIR 2>> $LOG_FILE || { log_error "Errore durante rsync dei file di staging"; exit 1; }

# Esegui il dump del database di staging
ssh $STAGING_USER@$STAGING_HOST "pg_dump -U postgres -h localhost -F c -b -v -f $STAGING_DB_DUMP your_staging_database_name" 2>> $LOG_FILE || { log_error "Errore durante il dump del database di staging"; exit 1; }

# Trasferisci il dump del database al server di produzione
scp $STAGING_USER@$STAGING_HOST:$STAGING_DB_DUMP $PROD_DB_DUMP 2>> $LOG_FILE || { log_error "Errore durante il trasferimento del dump del database di staging"; exit 1; }

# Importa il dump del database nel server di produzione
pg_restore -U $PROD_DB_USER -h $PROD_DB_HOST -d $PROD_DB_NAME -v $PROD_DB_DUMP 2>> $LOG_FILE || { log_error "Errore durante l'importazione del dump del database in produzione"; exit 1; }

# Pull delle configurazioni dal branch di staging
cd $DRUPAL_DIR
git pull origin $BRANCH_NAME 2>> $LOG_FILE || { log_error "Errore durante git pull delle configurazioni in produzione"; exit 1; }

# Importa le configurazioni nel server di produzione
./vendor/drush/drush/drush config-import -y 2>> $LOG_FILE || { log_error "Errore durante l'importazione delle configurazioni in produzione"; exit 1; }

# Log di successo
log_success "Esecuzione completata con successo"