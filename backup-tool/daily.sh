#!/usr/bin/env bash

SOURCE=/home/paco/

DESTINATION=/home/public/Backups/daily/paco/

exclude_patterns_file=/home/paco/.excludes_from_backup

# Script exits immediately if any command within it exits with a non-zero status
set -o errexit
# Script will catch the exit status of a previous command in a pipe.
set -o pipefail
# Script exits immediately if tries to use an undeclared variables.
set -o nounset
# Uncomment this to enable debug
# set -o xtrace

echoerr() { echo "[ERROR] $@" 1>&2; }

if [[ ! -d "${SOURCE}" ]]; then
    echoerr "The source folder '${SOURCE}' does NOT exist." 
    exit 2
fi

if [[ -z "${DESTINATION}" ]]; then
    echoerr "No destination folder has been defined."
    exit 2
fi

if [[ ! -f "${exclude_patterns_file}" ]]; then
    echo "No file for exclussions has been found."
    exit 2
fi

echo "Doing rsync '${SOURCE}' to '${DESTINATION}'"

mkdir -p "${DESTINATION}"

rsync --human-readable --info=progress2 --archive --delete-excluded --exclude-from "${exclude_patterns_file}" "${SOURCE}" "${DESTINATION}"

echo "Backup process successfully completed for ${SOURCE}"
