#!/usr/bin/env bash

source_dir=/home/paco/
destination_dir=/home/public/Backups/daily/paco/

exclude_patterns_file=/home/paco/.excludes_from_backup

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

if [[ -z "${exclude_patterns_file}" ]]; then
    echo "No file for exclussions has been defined."
    exit 2
fi

echo "Doing rsync ${source_dir} to ${destination_dir}..."

rsync_options="--verbose --human-readable --archive --delete-excluded --exclude-from ${exclude_patterns_file} ${source_dir} ${destination_dir}"
number_of_files=$(rsync --dry-run ${rsync_options} | wc -l)
rsync ${rsync_options} | pv --line-mode --eta --progress --size "${number_of_files}" >/dev/null

echo "Backup process successfully completed for ${source_dir}"
