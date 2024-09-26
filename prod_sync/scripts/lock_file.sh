#!/bin/bash

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

# Controlla se il file di lock esiste
if [ -f "$LOCK_FILE" ]; then
  log_message "error" "File di lock presente. Un'altra istanza dello script è in esecuzione."
  exit 1
fi