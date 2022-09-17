#!/usr/bin/env bash

DESTINATION=/home/public/Backups/weekly

SOURCE=/home/public/Backups/daily

# Script exits immediately if any command within it exits with a non-zero status
set -o errexit
# Script will catch the exit status of a previous command in a pipe.
set -o pipefail
# Script exits immediately if tries to use an undeclared variables.
set -o nounset
# Uncomment this to enable debug
# set -o xtrace

echoerr() { echo "[ERROR] $*" 1>&2; }

if [[ ! -d "${SOURCE}" ]]; then
    echoerr "The source folder '${SOURCE}' does NOT exist." 
    exit 2
fi

if [[ -z "${DESTINATION}" ]]; then
    echoerr "No destination folder has been defined."
    exit 2
fi

echo "Doing rsync ${SOURCE} to ${DESTINATION}..."

mkdir -p "${DESTINATION}"

# The last '/' is important. It will be added if it's not present.
RSYNC_SRC=${SOURCE}
if [[ "${RSYNC_SRC: -1}" != "/" ]]; then
    RSYNC_SRC="${RSYNC_SRC}/"
fi

rsync --human-readable --info=progress2 --archive --delete "${RSYNC_SRC}" "${DESTINATION}"

echo "Backup process successfully completed for ${SOURCE}"
