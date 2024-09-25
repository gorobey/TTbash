#!/bin/bash

# Funzione per eseguire il backup
make_backup() {
  log_message "info" "BACKUP - Inizio esecuzione"

  # Crea una copia di backup della directory di Drupal
  CMD=$(rsync -avz $DRUPAL_DIR $BACKUP_DIR/webroot 2>&1)
  if [ $? -eq 0 ]; then
    log_message "success" "Copia di backup della directory di Drupal completata con successo"
  else
    log_message "error" "Errore durante la copia di backup della directory di Drupal"
    exit 1
  fi

  # Esegui un dump del database di produzione
  CMD=$(pg_dump -U $PROD_DB_USER -h $PROD_DB_HOST -F c -b -v -f $BACKUP_DIR/database/prod_db_backup.sql $PROD_DB_NAME 2>&1)
  if [ $? -eq 0 ]; then
    log_message "success" "Dump del database di produzione completato con successo"
  else
    log_message "error" "Errore durante il dump del database di produzione"
    exit 1
  fi

  log_message "info" "Backup completato con successo!"
}

# Funzione per ripristinare il backup della directory di Drupal
restore_backup() {
  log_message "info" "RESTORE - Inizio esecuzione"
  log_message "info" "Ripristino del backup di Drupal"
  CMD=$(rsync -avz $BACKUP_DIR/webroot/ $DRUPAL_DIR/ 2>&1)
  if [ $? -eq 0 ]; then
    log_message "success" "Ripristino della copia di backup della directory di Drupal completato con successo"
  else
    log_message "error" "Errore durante il ripristino della copia di backup della directory di Drupal"
    exit 1
  fi

  log_message "info" "Ripristino del dump del database di produzione"
  CMD=$(pg_restore -U $PROD_DB_USER -h $PROD_DB_HOST -d $PROD_DB_NAME -v $BACKUP_DIR/database/prod_db_backup.sql 2>&1)
  if [ $? -eq 0 ]; then
    log_message "success" "Ripristino del dump del database di produzione completato con successo"
  else
    log_message "error" "Errore durante il ripristino del dump del database di produzione"
    exit 1
  fi
}

# Funzione per eseguire la pubblicazione
publish_to_prod() {
  log_message "info" "PUBLISH TO PROD - Inizio esecuzione"

  log_message "info" "Creazione della copia di backup di Drupal"

  # Crea una copia di backup della directory di Drupal
    CMD=$(rsync -avz $DRUPAL_DIR $BACKUP_DIR/webroot 2>&1)
  if [ $? -eq 0 ]; then
    log_message "success" "Copia di backup della directory di Drupal completata con successo"
  else
    log_message "error" "Errore durante la copia di backup della directory di Drupal:\n\r$CMD"
    exit 1
  fi

  # Esegui un dump del database di produzione
  CMD=$(pg_dump -U $PROD_DB_USER -h $PROD_DB_HOST -F c -b -v -f $BACKUP_DIR/database/prod_db_backup.sql $PROD_DB_NAME 2>&1)
  if [ $? -eq 0 ]; then
    log_message "success" "Dump del database di produzione completato con successo"
  else
    log_message "error" "Errore durante il dump del database di produzione:\n\r$CMD"
    exit 1
  fi

  # Sincronizza i file di staging con il server di produzione
    CMD=$(rsync -avz --exclude='settings.php' $STAGING_USER@$STAGING_HOST:$STAGING_UPLOAD_DIR $PROD_UPLOAD_DIR 2>&1)
  if [ $? -eq 0 ]; then
    log_message "success" "Rsync dei file di staging completato con successo"
  else
    log_message "error" "Errore durante rsync dei file di staging:\n\r$CMD"
    exit 1
  fi

  # Esegui il dump del database di staging
    CMD=$(ssh $STAGING_USER@$STAGING_HOST "pg_dump -U postgres -h localhost -F c -b -v -f $STAGING_DB_DUMP your_staging_database_name" 2>&1)
  if [ $? -eq 0 ]; then
    log_message "success" "Dump del database di staging completato con successo"
  else
    log_message "error" "Errore durante il dump del database di staging:\n\r$CMD"
    exit 1
  fi

  # Trasferisci il dump del database al server di produzione
    CMD=$(scp $STAGING_USER@$STAGING_HOST:$STAGING_DB_DUMP $PROD_DB_DUMP 2>&1)
  if [ $? -eq 0 ]; then
    log_message "success" "Trasferimento del dump del database completato con successo"
  else
    log_message "error" "Errore durante il trasferimento del dump del database di staging:\n\r$CMD"
    exit 1
  fi

  # Importa il dump del database nel server di produzione
    CMD=$(pg_restore -U $PROD_DB_USER -h $PROD_DB_HOST -d $PROD_DB_NAME -v $PROD_DB_DUMP 2>&1)
  if [ $? -eq 0 ]; then
    log_message "success" "Importazione del dump del database completata con successo"
  else
    log_message "error" "Errore durante l'importazione del dump del database in produzione:\n\r$CMD"
    exit 1
  fi

  # Sincronizza la directory di Drupal escludendo settings.php
    CMD=$(rsync -avz --exclude='settings.php' $STAGING_USER@$STAGING_HOST:$DRUPAL_DIR/ $DRUPAL_DIR/ 2>&1)
  if [ $? -eq 0 ]; then
    log_message "success" "Sincronizzazione della directory di Drupal completata con successo"
  else
    log_message "error" "Errore durante la sincronizzazione della directory di Drupal:\n\r$CMD"
    exit 1
  fi

  # Pull delle configurazioni dal branch di staging
  cd $DRUPAL_DIR
  CMD=$(git pull origin $BRANCH_NAME 2>&1)
  if [ $? -eq 0 ]; then
    log_message "success" "Git pull delle configurazioni completato con successo"
  else
    log_message "error" "Errore durante git pull delle configurazioni in produzione"
    exit 1
  fi

  # Importa le configurazioni nel server di produzione
  CMD=$(./vendor/drush/drush/drush config-import -y 2>&1)
  if [ $? -eq 0 ]; then
    log_message "success" "Importazione delle configurazioni completata con successo"
  else
    log_message "error" "Errore durante l'importazione delle configurazioni in produzione"
    exit 1
  fi

  # Log di successo
  log_message "info" "Pubblicazione completata con successo!"
}

# Funzione per mostrare il menu di aiuto
show_help() {
  echo "Usage: $0 {restore|publish|backup|help}"
  echo
  echo "Commands:"
  echo "  restore   Ripristina il backup della directory di Drupal e il dump del database"
  echo "  publish   Esegue la pubblicazione sincronizzando i file e il database di staging con il server di produzione"
  echo "  backup    Esegue il backup della directory di Drupal e del database di produzione"
  echo "  help      Mostra questo menu di aiuto"
}

# Controlla i parametri passati allo script
case "$1" in
  restore)
    restore_backup
    ;;
  publish)
    publish_to_prod
    ;;
  backup)
    make_backup
    ;;
  help|*)
    show_help
    ;;
esac