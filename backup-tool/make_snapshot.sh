#!/usr/bin/env bash

##########################################################################
# Shellscript:  Backup a set of folders to a directory using rsync
# Author     :  Paco Orozco <paco@pacoorozco.info>
# Requires   :  mount rsync
##########################################################################
# See CHANGELOG for changes.
##########################################################################
#     Copyright 2018 Paco Orozco <paco@pacoorozco.info>
#
#     This program is free software: you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation, either version 3 of the License, or
#     (at your option) any later version.
#
#     This program is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
#
#     You should have received a copy of the GNU General Public License
#     along with this program.  If not, see <http://www.gnu.org/licenses/>.
##########################################################################

##########################################################################
# CONFIGURATION
##########################################################################
# backup_sources: contains a list of folders to be backed up. They must be
# separated by spaces. If a folder doesn't exists a warning will be raised.
# e.g.: backup_sources=("/home/dir1/ /home/dir2/")
backup_sources=()

# backup_destination_dir: contains an existent folder where backups will be
# kept. This is usually a mounted external disk.
# e.g.: backup_destination_dir=/mnt/backup_hd
backup_destination_dir=""

# exclude_patterns_file: contains a list of files and folders to be excluded from
# backup. You can create a file with common exclusions using this command:
# wget https://raw.githubusercontent.com/rubo77/rsync-homedir-excludes/master/rsync-homedir-excludes.txt -O /tmp/ignorelist
# e.g.: Excludes_File=/tmp/ignorelist
exclude_patterns_file=""

##########################################################################
# DO NOT MODIFY BEYOND THIS LINE
##########################################################################
# Program name and version
program_name=$(basename "$0")
program_version='0.1.0'

# Script exits immediately if any command within it exits with a non-zero status
set -o errexit
# Script will catch the exit status of a previous command in a pipe.
set -o pipefail
# Script exits immediately if tries to use an undeclared variables.
set -o nounset
# Uncomment this to enable debug
# set -o xtrace

# Initialize variables in order to be used later
log_file=""
# 0 - Quiet, 1 - Errors, 2 - Warnings, 3 - Normal, 4 - Verbose, 9 - Debug
verbosity_level=3

current_date=$(date "+%Y%m%d")

##########################################################################
# Main function
##########################################################################
function main() {
  args_management "$@"
  check_requirements

  # Check supplied arguments
  if [[ ${#backup_sources[@]} -eq 0 ]]; then
    error "No source folders has been defined to be backed up."
    safe_exit 2
  fi

  notice "Source folders are: ${backup_sources[*]}"

  if [[ -z "${backup_destination_dir}" ]]; then
    error "No target folder has been defined to backup to."
    safe_exit 2
  fi

  if [[ ! -d "${backup_destination_dir}" ]]; then
    error "Target folder does not exist: ${backup_destination_dir}"
    safe_exit 2
  fi

  backup_destination_dir_at_runtime="${backup_destination_dir}/backup-${current_date}.LATEST"

  # Avoid to rotate folders when is not needed (eg. running the command several times per day)
  if [[ ! -d "${backup_destination_dir_at_runtime}" ]]; then
    rotate_backup_targets
  fi

  notice "Destination folder is '${backup_destination_dir_at_runtime}'."

  local exclude_options=""
  if [[ -z "${exclude_patterns_file}" ]] &&
    [[ -r "$HOME/.excludes_from_backup" ]]; then
    exclude_patterns_file=$HOME/.excludes_from_backup
  fi

  if [[ -n "${exclude_patterns_file}" ]]; then
    notice "Using exclusions file: ${exclude_patterns_file}"
    exclude_options="--exclude-from=${exclude_patterns_file}"
  fi

  for source_dir in "${backup_sources[@]}"; do

    notice "Going to next source: ${source_dir}"

    if [[ -d "${source_dir}" ]]; then
      # Create destination_dir folder name, uppercased last part of source name
      destination_dir="${backup_destination_dir_at_runtime}/$(basename "${source_dir}" | tr '[:lower:]' '[:upper:]')"
      
      debug "Creating backup destination folder: ${destination_dir}"
      mkdir --parents "${destination_dir}"

      # Do rsync from the system into the latest snapshot (notice that
      # rsync behaves like cp --remove-destination_dir by default, so the
      # destination_dir is unlinked first.  If it were not so, this would
      # copy over the other snapshot(s) too!
      debug "Doing rsync '${source_dir}' to '${destination_dir}'..."

      rsync_options=("--verbose" "--human-readable" "--archive" "--delete" "--delete-excluded" "${exclude_options}" "${source_dir}" "${destination_dir}")
      number_of_files=$(rsync --dry-run "${rsync_options[@]}" | wc -l)
      
      rsync "${rsync_options[@]}" | pv --line-mode --eta --progress --size "${number_of_files}" >/dev/null
      
      info "Backup process successfully completed for '${source_dir}'."
    else
      warning "Skipping source - invalid folder '${source_dir}'."
    fi
  done

  safe_exit
}

##########################################################################
# Functions
##########################################################################
# Do every cleanup task before exit.
function safe_exit() {
  local _error_code=${1:-0}
  exit "${_error_code}"
}

# Print a message, do format and treat verbose level
declare -A LOG_LEVELS
LOG_LEVELS=([error]=1 [warning]=2 [notice]=3 [info]=4 [debug]=9)

function _alert() {
  # TODO: This variables are reserved for future use
  local color=""
  local reset=""

  # Print message to log file. Debug messages are not printed.
  if [[ -n "${log_file}" ]] && [[ "${1}" != "debug" ]]; then
    echo -e "$(date +"%d-%m-%Y %X") $(printf "[%s]" "${1}") ${_message}" >>"${log_file}"
  fi

  # Print to console depending of verbosity level
  if [[ "${verbosity_level}" -ge "${LOG_LEVELS[${1}]}" ]]; then
    echo -e "$(date +"%X") ${color}$(printf "[%s]" "${1}") ${_message}${reset}"
  fi
}

# Print a message and exit
function die() {
  local _error_code=0
  [[ "${1}" = "-e" ]] && shift
  _error_code=${1}
  shift
  error "${*} Exiting."
  safe_exit "${_error_code}"
}

# Deal with severity level messages
function error() {
  local _message="${*}"
  _alert error >&2
}
function warning() {
  local _message="${*}"
  _alert warning >&2
}
function notice() {
  local _message="${*}"
  _alert notice
}
function info() {
  local _message="${*}"
  _alert info
}
function debug() {
  local _message="${*}"
  _alert debug
}
function input() {
  local _message="${*}"
  _alert info
}

# Show program version
function show_version() {
  echo "${program_name} v${program_version}"
}

# Usage info
function show_help() {
  # Variables for formatting
  local U
  U=$(tput smul) # Underline
  local RU
  RU=$(tput rmul) # Remove underline
  local B
  B=$(tput bold) # Bold
  local N
  N=$(tput sgr0) # Normal

  cat <<-EOF
    ${B}Usage${N}:

    ${B}${program_name}${N} -b ${U}source_folder${RU} -t ${U}destination_folder${RU} [options]...

    ${B}Options:${N}

    ${B}-h, --help${N}     Display this help message

    ${B}-V, --version${N}  Show version information

    ${B}-v, --verbose${N} ${U}number${RU}
    Set VERBOSITY level. Use 0 to 9, where default is 3

    ${B}-d, --debug${N}    Enable debug information

    ${B}-q, --quiet${N}    Quiet

    ${B}-e, --excludes${N} ${U}file${RU}
    This option specifies a FILE that contains exclude patterns (one per line). Blank lines in
    the file and lines starting with ’;’ or ’#’ are ignored. If FILE is -, the list will be
    read from standard input. It will use ${U}\$HOME/.excludes_from_backup${RU} otherwise.

    ${B}-s, --source${N} ${U}source_folder${RU}
    Mandatory. This is the path of folder to be backed up. You can use this option as many times
    as folders you want to back up.

    ${B}-t, --target${N} ${U}destination_folder${RU}
    Mandatory. This is the path where snapshots will be kept.

    ${B}Examples:${N}

    \$ ${program_name} --source /home/user1 --source /home/user2 --target /mnt/backup_hd
    Minimal options. Will backup ${U}/home/user1${RU} and ${U}/home/user2${RU} into ${U}/mnt/backup_hd${RU}

EOF

}

# Manage arguments and configure variables according to it
function args_management() {

  while [ $# -gt 0 ]; do

    case $1 in
    -h | -\? | --help)
      show_help
      safe_exit 0
      ;;
    -V | --version)
      show_version
      safe_exit 0
      ;;
    -d | --debug)
      verbosity_level=${LOG_LEVELS['debug']}
      ;;
    -q | --quiet)
      verbosity_level=0
      ;;
    -v | --verbose)
      if [[ $2 =~ ^[0-9]+$ ]]; then
        verbosity_level=$2
        shift
      else
        die -e 2 "'--verbose' requires a level [0-9]."
      fi
      ;;
    --verbose=?*)
      verbosity_level=("${1#*=}") # Delete everything up to "=" and assign the remainder.
      ;;
    --verbose=) # Handle the case of an empty --verbose=
      die -e 2 "'--verbose=' requires a level [0-9]."
      ;;
    -s | --source)
      if [ -n "${2-}" ]; then
        backup_sources+=("$2")
        shift
      else
        die -e 2 "'--source' requires an existent directory."
      fi
      ;;
    --source=?*)
      backup_sources+=("${1#*=}") # Delete everything up to "=" and assign the remainder.
      ;;
    --source=) # Handle the case of an empty --source=
      die -e 2 "'--source' requires an existent directory."
      ;;
    -t | --target)
      if [ -n "${2-}" ]; then
        backup_destination_dir=$2
        shift
      else
        die -e 2 "'--target' requires an existent directory."
      fi
      ;;
    --target=?*)
      backup_destination_dir=${1#*=} # Delete everything up to "=" and assign the remainder.
      ;;
    --target=) # Handle the case of an empty --target=
      die -e 2 "'--target' requires an existent directory."
      ;;
    -e | --excludes)
      if [ -n "${2-}" ]; then
        exclude_patterns_file=$2
        shift
      else
        die -e 2 "'--excludes' requires an existent file."
      fi
      ;;
    --excludes=?*)
      exclude_patterns_file=${1#*=} # Delete everything up to "=" and assign the remainder.
      ;;
    --excludes=) # Handle the case of an empty --excludes=
      die -e 2 "'--excludes' requires an existent file."
      ;;
    --) # End of all options.
      shift
      break
      ;;
    -?*)
      warning "Unknown option (ignored): $1"
      ;;
    *) # Default case: No more options, so break out of the loop.
      break
      ;;
    esac

    shift

  done
}

# Check if requirements are satisfied
function check_requirements() {
  local REQUIRED_BINARIES="rsync pv"

  for binary in $REQUIRED_BINARIES; do
    if [[ $(type -P "${binary}") ]]; then
      debug "${binary} has been found in PATH"
    else
      die -e 127 "${binary} has NOT been found in PATH."
    fi
  done
}

# Rotating snapshots of backup_destination_dir to keep 3 versions
function rotate_backup_targets() {
  revisions=("LATEST-3" "LATEST-2" "LATEST-1" "LATEST")

  last_revision=${revisions[${#revisions[@]} - 1]}
  previous=""

  for revision in "${revisions[@]}"; do

    backup_revision=$(find "${backup_destination_dir}" -maxdepth 1 -name "backup-*.${revision}" -print | sort -r | head -1)

    if [ -z "${backup_revision}" ]; then
      notice "Snapshot was not found for revision: ${revision}."
      previous=$revision
      continue
    fi

    if [ -z "${previous}" ]; then
      debug "Deleting the oldest snapshot: ${backup_revision}"
      rm --recursive --force "${backup_revision}"
      previous=$revision
      continue
    fi

    # The latest snapshot have a different treatment.
    if [ "$revision" == "$last_revision" ]; then
      debug "Copying the latest snapshop: ${backup_revision} --> ${backup_revision::-7}.${previous}"
      cp --archive --link "${backup_revision}" "${backup_revision::-7}.${previous}"
      mv "${backup_revision}" "${backup_destination_dir}/backup-${current_date}.${revision}"
      previous=$revision
      continue
    fi

    # Normal snapshots are kept.
    debug "Moving snapshots: ${backup_revision} --> ${backup_revision::-9}.${previous}"
    mv "${backup_revision}" "${backup_revision::-9}.${previous}"
    previous=$revision

  done
}

##########################################################################
# Main code
##########################################################################
main "$@"
