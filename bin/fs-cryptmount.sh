#!/usr/bin/env bash
##########################################################################
# Shellscript:  Mount an encFS filesystem
# Author     :  Paco Orozco <paco@pacoorozco.info>
# Requires   :
##########################################################################
# See CHANGELOG for changes.
##########################################################################
#     Copyright 2017 Paco Orozco <paco@pacoorozco.info>
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

# Configuration variables
Encrypted_FS_Path=~/Dropbox/ENCRYPTED
Mounting_Point_Path=~/Private
# How many time (minutes) will a mounted filesystem be idle before umount
Idle_Timeout=10

##########################################################################
# DO NOT MODIFY BEYOND THIS LINE
##########################################################################
# Program name and version
Program_Name=$(basename "$0")
Program_Version='0.0.5'

# Script exits immediately if any command within it exits with a non-zero status
set -o errexit
# Script will catch the exit status of a previous command in a pipe.
set -o pipefail
# Script exits immediately if tries to use an undeclared variables.
set -o nounset
# Uncomment this to enable debug
# set -o xtrace

# Initialize variables in order to be used later
Log_File=''
# 0 - Quiet, 1 - Errors, 2 - Warnings, 3 - Normal, 4 - Verbose, 9 - Debug
Verbosity_Level=3

EncFS_Path=$(command -v encfs)
fusermount_Path=$(command -v fusermount)

##########################################################################
# Main function
##########################################################################
function main () {
  # Resetting OPTIND is necessary if getopts was used previously in the script.
  OPTIND=1

  # Process command line options
  while getopts "hu" OPTION; do
    case ${OPTION} in
      h)
        usage
        safeExit 1
        ;;
      u)
        fs_umount "${Mounting_Point_Path}"
        safeExit
        ;;
      \?)
        warning "Unknown option (ignored): -${OPTARG}"
        ;;
    esac
  done
  # Shift off the options and optional --.
  shift "$((OPTIND - 1))"

  check-requirements

  EncFS_Path="${EncFS_Path} --idle=${Idle_Timeout}"

  # declare variables as readonly
  readonly EncFS_Path
  readonly Encrypted_FS_Path
  readonly Mounting_Point_Path

  if ! fs_mount "${Encrypted_FS_Path}" "${Mounting_Point_Path}"; then
      die -e 1 "Can't mount ${Encrypted_FS_Path}..."
  fi
}

##########################################################################
# Functions
##########################################################################
# Do every cleanup task before exit.
function safeExit () {
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
  safeExit "${_error_code}"
}

# Deal with severity level messages
function error ()     { local _message="${*}"; _alert error >&2; }
function warning ()   { local _message="${*}"; _alert warning >&2; }
function notice ()    { local _message="${*}"; _alert notice; }
function info ()      { local _message="${*}"; _alert info; }
function debug ()     { local _message="${*}"; _alert debug; }
function input()      { local _message="${*}"; _alert info; }

# Check if requirements are satisfied
function check-requirements () {
  if [[ ! -x "${EncFS_Path}" ]]; then
    die -e 127 "We require EncFS binary."
  fi
  if [[ ! -x "${fusermount_Path}" ]]; then
    die -e 127 "We require fusermount binary."
  fi
}

function usage () {
  # Variables for formatting
  local U; U=$(tput smul)  # Underline
  local RU; RU=$(tput rmul) # Remove underline
  local B; B=$(tput bold)  # Bold
  local N; N=$(tput sgr0)  # Normal

  cat <<-EOF
    ${B}Usage:${N}

    ${B}${Program_Name}${N} (v.${U}${Program_Version}${RU}) [options]...
    ${B}Options:${N}

    ${B}-h${N}  Display this help message

    ${B}-u${N}  Umount EncFS mounting point.

    ${B}Examples:${N}

    \$ ${Program_Name}
    Minimal options. Will mount a specified EncFS into a specified mounting point.

    \$ ${Program_Name} ${B}-u${N}
    Will umount the EncFS.

EOF
}

# Return if the encrypted FS is mounted
function check_if_mounted() {
  return "$(grep -c encfs /proc/mounts)"
}

# Mount an encrypted filesystem into a mounting point
function fs_mount () {
  local Encrypted_FS="$1"
  local Mounting_Point="$2"

  if check_if_mounted "${Mounting_Point}"; then
    echo "Please suply credentials to mount ${Encrypted_FS}..."
    ${EncFS_Path} "${Encrypted_FS}" "${Mounting_Point}" || return 1
  fi
  echo  "Succesfully mounted"
}

function fs_umount () {
  local Mounting_Point="$1"

  check_if_mounted "${Mounting_Point}" \
    || ${fusermount_Path} -u "${Mounting_Point}" \
    && echo "encfs... unmounted"
}

##########################################################################
# Main code
##########################################################################

main "${@}"
