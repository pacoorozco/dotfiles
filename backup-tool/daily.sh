#!/usr/bin/env bash

DESTINATION=/home/public/Backups/daily/paco

SOURCE=/home/paco

EXCLUDE_PATTERNS_FILE="${HOME}/.excludes_from_backup"

# Script exits immediately if any command within it exits with a non-zero status
set -o errexit
# Script will catch the exit status of a previous command in a pipe.
set -o pipefail
# Script exits immediately if tries to use an undeclared variables.
set -o nounset
# Uncomment this to enable debug
# set -o xtrace

readonly DESTINATION
readonly SOURCE
readonly EXCLUDE_PATTERNS_FILE

##########################################################################
# Main function
##########################################################################
main() {
    if [[ ! -d "${SOURCE}" ]]; then
        echoerr "The source folder '${SOURCE}' does NOT exist."
        exit 2
    fi

    if [[ -z "${DESTINATION}" ]]; then
        echoerr "No destination folder has been defined."
        exit 2
    fi

    if [[ ! -f "${EXCLUDE_PATTERNS_FILE}" ]]; then
        echo "No file for exclussions has been found."
        exit 2
    fi

    echo "Doing rsync '${SOURCE}' to '${DESTINATION}'"

    mkdir -p "${DESTINATION}"

    # The last '/' is important to apply the `EXCLUDE_PATTERS_FILE` properly. It will be added if it's not present.
    local rsync_source=${SOURCE}
    if [[ "${rsync_source: -1}" != "/" ]]; then
        rsync_source="${rsync_source}/"
    fi

    rsync --human-readable --info=progress2 --archive --delete-excluded --exclude-from "${EXCLUDE_PATTERNS_FILE}" "${rsync_source}" "${DESTINATION}"

    echo "Backup process successfully completed for ${SOURCE}"
}

##########################################################################
# Functions
##########################################################################
echoerr() { echo "[ERROR] $*" 1>&2; }

##########################################################################
# Main code
##########################################################################
main
