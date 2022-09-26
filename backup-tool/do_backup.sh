#!/usr/bin/env bash

SOURCE="/home/paco"
DESTINATION="/media/paco/BACKUP_HD/BACKUP-$(uname -n)"        

#--- End of configuration ---

script_directory=$( dirname -- "$0"; )

"$script_directory/make_snapshot.sh" --source "${SOURCE}" --target "${DESTINATION}"