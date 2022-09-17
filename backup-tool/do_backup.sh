#!/usr/bin/env bash

SOURCE="/home/paco"
DESTINATION="/media/paco/BACKUP_HD/BACKUP-$(uname -n)"        

echo "Starting remote backup to: ${DESTINATION}"

make_snapshot.sh -d -b "${SOURCE}" -t "${DESTINATION}"