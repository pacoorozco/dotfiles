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
# Backup_Sources: contains a list of folders to be backed up. They must be
# separated by spaces. If a folder doesn't exists a warning will be raised.
# e.g.: Backup_Sources="/home/dir1/ /home/dir2/"
Backup_Sources="/home/paco/"

# Backup_Destination: contains an existent folder where backups will be
# kept. This is usually a mounted external disk.
# e.g.: Backup_Destination=/mnt/backup_hd
Backup_Destination=/media/paco/BACKUP_HD/BACKUP

# Exclusion_File: contains a list of files and folders to be excluded from 
# backup. You can create a file with common exclusions using this command:
# wget https://raw.githubusercontent.com/rubo77/rsync-homedir-excludes/master/rsync-homedir-excludes.txt -O /tmp/ignorelist
# e.g.: Excludes_File=/tmp/ignorelist
Exclusion_File=/tmp/ignorelist

##########################################################################
# DO NOT MODIFY BEYOND THIS LINE
##########################################################################
# Program name and version
Program_Name=$(basename "$0")
Program_Version='0.0.1'

# Script exits immediately if any command within it exits with a non-zero status
set -o errexit
# Script will catch the exit status of a previous command in a pipe.
set -o pipefail
# Script exits immediately if tries to use an undeclared variables.
set -o nounset
# Uncomment this to enable debug
set -o xtrace

# Initialize variables in order to be used later
Log_File=''
# 0 - Quiet, 1 - Errors, 2 - Warnings, 3 - Normal, 4 - Verbose, 9 - Debug
Verbosity_Level=3

##########################################################################
# Main function
##########################################################################
function main () {
	args_management "${@}"
	check_requirements

	#rotate_backup_targets

	for Source_Dir in ${Backup_Sources}
	do
		# Do rsync from the system into the latest snapshot (notice that
		# rsync behaves like cp --remove-destination by default, so the
		# destination is unlinked first.  If it were not so, this would
		# copy over the other snapshot(s) too!
    Destination="$(basename "${Source_Dir}" | tr 'a-z' 'A-Z')"

    mkdir -p "${Backup_Destination}/backup.0/${Destination}"

    rsync -va --delete --delete-excluded --exclude-from="${Exclusion_File}" \
        "${Source_Dir}" "${Backup_Destination}/backup.0/${Destination}"

    debug "Backup process for ${Source_Dir} has been completed."
	done

	# Update the mtime of backup.0 to reflect the snapshot time
	touch "${Backup_Destination}/backup.0"

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
  if [[ -n "${Log_File}" ]] && [[ "${1}" != "debug" ]]; then
    echo -e "$(date +"%d-%m-%Y %X") $(printf "[%s]" "${1}") ${_message}" >> "${Log_File}"
  fi

  # Print to console depending of verbosity level
  if [[ "${Verbosity_Level}" -ge "${LOG_LEVELS[${1}]}" ]]; then
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


# Usage info
function show_help () {
  # Variables for formatting
  local U; U=$(tput smul)  # Underline
  local RU; RU=$(tput rmul) # Remove underline
  local B; B=$(tput bold)  # Bold
  local N; N=$(tput sgr0)  # Normal

  cat <<-"EOF"
    ${B}Usage:${N}

    ${B}${Program_Name}${N} (v.${U}${Program_Version}${RU}) [options]...
    
    ${B}Options:${N}
    
    ${B}-h${N}  Display this help message
    
    ${B}Examples:${N}
    \$ ${Program_Name}
    Minimal options. Will backup 

	EOF
}

# Manage arguments and configure variables according to it
function args_management () {
    local OPTIND=1
    while getopts "hv:" OPTION; do
        case "${OPTION}" in
			h)
        		usage
        		safe_exit 1
        		;;
            v)
      			if [[ ! ${OPTARG} =~ ^[0-9]+$ ]] ; then
        			die -e 1 "Bad verbose level"
      			else
        			Verbosity_Level=${OPTARG}
      			fi
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
    local REQUIRED_BINARIES="rsync"
  
    for Binary in $REQUIRED_BINARIES; do
        [[ $(type -P "${Binary}") ]] && info "${Binary} is in PATH"  || die -e 127 "${Binary} is NOT in PATH."
    done
}

# Rotating snapshots of Backup_Destination to keep 3 versions
function rotate_backup_targets () {
	[ -d "${Backup_Destination}/backup.3" ] && rm -rf "${Backup_Destination}/backup.3"
	[ -d "${Backup_Destination}/backup.2" ] && mv "${Backup_Destination}/backup.2" "${Backup_Destination}/backup.3"
	[ -d "${Backup_Destination}/backup.1" ] && mv "${Backup_Destination}/backup.1" "${Backup_Destination}/backup.2"
	[ -d "${Backup_Destination}/backup.0" ] && cp -al "${Backup_Destination}/backup.0" "${Backup_Destination}/backup.1"
}

##########################################################################
# Main code
##########################################################################
main "${@}"
