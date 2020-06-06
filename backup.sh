#!/bin/bash

SERVER_PASSWORD=""
BACKUP_WAIT_MINUTES=
MAX_LOCAL_BACKUP_DAYS=
MAX_CLOUD_BACKUPS=
CLOUD_DIR=""

function rcon {
  /opt/minecraft/tools/mcrcon/mcrcon -H 127.0.0.1 -P 25575 -p "$SERVER_PASSWORD" "$1"
}

echo "Waiting $BACKUP_WAIT_MINUTES minutes for users to prepare for backup"
rcon "say Server is going offline to backup in $BACKUP_WAIT_MINUTES minutes!"
sleep ${BACKUP_WAIT_MINUTES}m
rcon "save-off"
rcon "save-all"
FILE=server-$(date +%F-%H-%M).tar.gz
tar -cvpzf /opt/minecraft/backups/"$FILE" /opt/minecraft/server
rcon "save-on"

echo "Deleting local backups older than $MAX_LOCAL_BACKUP_DAYS days"
find /opt/minecraft/backups/ -type f -mtime +$MAX_LOCAL_BACKUP_DAYS -name '*.gz' -delete

echo "Uploading latest backup to the cloud"
/opt/minecraft/Dropbox-Uploader/dropbox_uploader.sh upload /opt/minecraft/backups/"$FILE" "$CLOUD_DIR/$FILE"

FILES=($(/opt/minecraft/Dropbox-Uploader/dropbox_uploader.sh list $CLOUD_DIR | awk '{print $3}' | tail -n +2))
COUNT=${#FILES[@]}
DELETE_UP_TO=$(( $COUNT - $MAX_CLOUD_BACKUPS ))
if (( 0 < DELETE_UP_TO )); then
  echo "Found files older than the max limit of $MAX_CLOUD_BACKUPS, deleting..."
  for (( i=0; i<DELETE_UP_TO; i++ )); do
    /opt/minecraft/Dropbox-Uploader/dropbox_uploader.sh delete "$CLOUD_DIR/${FILES[i]}"
  done
fi
