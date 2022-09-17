#!/usr/bin/env bash

source_dir=/home/public/Backups/daily/
destination_dir=/home/public/Backups/weekly

# Script exits immediately if any command within it exits with a non-zero status
set -o errexit
# Script will catch the exit status of a previous command in a pipe.
set -o pipefail
# Script exits immediately if tries to use an undeclared variables.
set -o nounset
# Uncomment this to enable debug
# set -o xtrace


if [[ -z "${source_dir}" ]]; then
    echo "No source folder has been defined."
    exit 2
fi

if [[ ! -d "${destination_dir}" ]]; then
    echo "No destination folder has been defined."
    exit 2
fi

echo "Doing rsync ${source_dir} to ${destination_dir}..."

rsync_options="--verbose --human-readable --archive --delete ${source_dir} ${destination_dir}"
rsync ${rsync_options}

echo "Backup process successfully completed for ${source_dir}"
# 
