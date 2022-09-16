#!/usr/bin/env bash

SOURCE="/home/paco/"
DESTINATION="/home/public/Backups"


if [ "$1" = "remote" ]; then
    DESTINATION="/media/paco/BACKUP_HD/BACKUP-$(uname -n)"        
    echo "Starting remote backup to: ${DESTINATION}"
fi

make_snapshot.sh -d -b "${SOURCE}" -t "${DESTINATION}"

