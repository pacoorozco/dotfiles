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
# e.g.: backup_sources="/home/dir1/ /home/dir2/"
backup_sources=""

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
program_version='0.0.1'

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

##########################################################################
# Main function
##########################################################################
function main () {
	args_management "$@"
	check_requirements

  # Check supplied arguments
  if [[ -z "${backup_sources}" ]]; then
    error "No source folders has been defined to be backed up."
    show_help
    safe_exit 2
  fi

  notice "Source folders are '${backup_sources}'"

  if [[ ! -d "${backup_destination_dir}" ]]; then
    error "No backup destination_dir defined."
    show_help
    safe_exit 2
  fi

  notice "Destination folder is ${backup_destination_dir}"

	rotate_backup_targets

  local exclude_options=""
  if [[ -z "${exclude_patterns_file}" ]] \
     && [[ -r "$HOME/.excludes_from_backup" ]]; then
    exclude_patterns_file=$HOME/.excludes_from_backup
  fi

  if [[ -n "${exclude_patterns_file}" ]]; then
    notice "Using exclusions file ${exclude_patterns_file}"
    exclude_options="--exclude-from=${exclude_patterns_file}"
  fi

	for source_dir in ${backup_sources}; do
    notice "Going to next source ${source_dir}"
    if [[ -d "${source_dir}" ]]; then
      # Create destination_dir folder name, uppercased last part of source name
      destination_dir="${backup_destination_dir}/backup.0/$(basename "${source_dir}" | tr '[:lower:]' '[:upper:]')"
      debug "Creating backup destination folder: ${destination_dir}"
      mkdir --parents "${destination_dir}"

      # Do rsync from the system into the latest snapshot (notice that
      # rsync behaves like cp --remove-destination_dir by default, so the
      # destination_dir is unlinked first.  If it were not so, this would
      # copy over the other snapshot(s) too!
      debug "Doing rsync ${source_dir} to ${destination_dir}..."
      rsync_options="--verbose --human-readable --archive --delete --delete-excluded ${exclude_options} ${source_dir} ${destination_dir}"
      number_of_files=$(rsync --dry-run ${rsync_options} | wc -l)
      rsync ${rsync_options} | pv --line-mode --eta --progress --size $number_of_files >/dev/null
      info "Backup process successfully completed for ${source_dir}"
    else 
      warning "Skipping source - invalid folder ${source_dir}"
    fi
  done

	# Update the mtime of backup.0 to reflect the snapshot time
	touch "${backup_destination_dir}/backup.0"

	safe_exit
}

##########################################################################
# Functions
##########################################################################
# Do every cleanup task before exit.
function safe_exit () {
  local _error_code=${1:-0}
  exit "${_error_code}"
}

# Print a message, do format and treat verbose level
declare -A LOG_LEVELS
LOG_LEVELS=([error]=1 [warning]=2 [notice]=3 [info]=4 [debug]=9)

function _alert () {
  # TODO: This variables are reserved for future use
  local color=""; local reset=""

  # Print message to log file. Debug messages are not printed.
  if [[ -n "${log_file}" ]] && [[ "${1}" != "debug" ]]; then
    echo -e "$(date +"%d-%m-%Y %X") $(printf "[%s]" "${1}") ${_message}" >> "${log_file}"
  fi

  # Print to console depending of verbosity level
  if [[ "${verbosity_level}" -ge "${LOG_LEVELS[${1}]}" ]]; then
    echo -e "$(date +"%X") ${color}$(printf "[%s]" "${1}") ${_message}${reset}"
  fi
}

# Print a message and exit
function die () {
  local _error_code=0
  [[ "${1}" = "-e" ]] && shift; _error_code=${1}; shift
  error "${*} Exiting."
  safe_exit "${_error_code}"
}

# Deal with severity level messages
function error ()     { local _message="${*}"; _alert error >&2; }
function warning ()   { local _message="${*}"; _alert warning >&2; }
function notice ()    { local _message="${*}"; _alert notice; }
function info ()      { local _message="${*}"; _alert info; }
function debug ()     { local _message="${*}"; _alert debug; }
function input()      { local _message="${*}"; _alert info; }

# Show program version
function show_version () {
  echo "${program_name} v${program_version}"
}

# Usage info
function show_help () {
  # Variables for formatting
  local U; U=$(tput smul)  # Underline
  local RU; RU=$(tput rmul) # Remove underline
  local B; B=$(tput bold)  # Bold
  local N; N=$(tput sgr0)  # Normal

  cat <<-EOF
    ${B}Usage${N}:

    ${B}${program_name}${N} -b ${U}source_folder${RU} -t ${U}destination_folder${RU} [options]...

    ${B}Options:${N}

    ${B}-h${N}  Display this help message

    ${B}-V${N}  Show version information

    ${B}-v${N}  ${U}number${RU}
    Set VERBOSITY level. Use 0 to 9, where default is 3

    ${B}-d${N}  Enable debug information

    ${B}-q${N}  Quiet

    ${B}-e${N}  ${U}file${RU}
    This option specifies a FILE that contains exclude patterns (one per line). Blank lines in
    the file and lines starting with ’;’ or ’#’ are ignored. If FILE is -, the list will be
    read from standard input. It will use ${U}\$HOME/.excludes_from_backup${RU} otherwise.

    ${B}-b${N}  ${U}source_folder${RU}
    Mandatory. This is the path of folder to be backed up. You can use this option as many times
    as folders you want to back up.

    ${B}-t${N}  ${U}destination_folder${RU}
    Mandatory. This is the path where snapshots will be kept.

    ${B}Examples:${N}

    \$ ${program_name} -b /home/user1 -b /home/user2 -t /mnt/backup_hd
    Minimal options. Will backup ${U}/home/user1${RU} and ${U}/home/user2${RU} into ${U}/mnt/backup_hd${RU}

EOF

}

# Manage arguments and configure variables according to it
function args_management () {
  local OPTIND=1
  while getopts "hdqVv:b:t:e:" OPTION; do
    case "${OPTION}" in
      h)
        show_help
        safe_exit 1
        ;;
      V)
        show_version
        safe_exit 0
        ;;
      v)
        if [[ ! ${OPTARG} =~ ^[0-9]+$ ]] ; then
          die -e 1 "Bad verbose level"
        else
          verbosity_level=${OPTARG}
        fi
        ;;
      d)
        verbosity_level=${LOG_LEVELS['debug']}
        ;;
      q)
        verbosity_level=0
        ;;
      b)
        backup_sources+="${OPTARG} "
        ;;
      t)
        backup_destination_dir=${OPTARG}
        ;;
      e)
        exclude_patterns_file=${OPTARG}
        [[ ! -r "${exclude_patterns_file}" ]] && die -e 2 "Invalid exclude patterns file"
        ;;
      '?')
        show_help >&2
        exit 1
      ;;
    esac
  done
  # Shift off the options and optional --.
  shift "$((OPTIND - 1))"
}

# Check if requirements are satisfied
function check_requirements () {
  local REQUIRED_BINARIES="rsync pv"
  
  for binary in $REQUIRED_BINARIES; do
    if [[ $(type -P "${binary}") ]]; then
      info "${binary} has been found in PATH"
    else
      die -e 127 "${binary} has NOT been found in PATH."
    fi
  done
}

# Rotating snapshots of backup_destination_dir to keep 3 versions
function rotate_backup_targets () {
	if [[ -d "${backup_destination_dir}/backup.3" ]]; then
    debug "Deleting oldest snapshot ${backup_destination_dir}/backup.3"
    rm --recursive --force "${backup_destination_dir}/backup.3"
  fi

	if [[ -d "${backup_destination_dir}/backup.2" ]]; then
    debug "Rotating snapshot ${backup_destination_dir}/backup.2"
    mv "${backup_destination_dir}/backup.2" "${backup_destination_dir}/backup.3"
  fi

  if [[ -d "${backup_destination_dir}/backup.1" ]]; then
    debug "Rotating snapshot ${backup_destination_dir}/backup.1"
    mv "${backup_destination_dir}/backup.1" "${backup_destination_dir}/backup.2"
  fi

	if [[ -d "${backup_destination_dir}/backup.0" ]]; then
    debug "Rotating last created snapshot "
    cp --archive --link "${backup_destination_dir}/backup.0" "${backup_destination_dir}/backup.1"
  fi
}

##########################################################################
# Main code
##########################################################################
main "$@"
