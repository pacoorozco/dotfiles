#!/usr/bin/env bash

##########################################################################
# Shellscript:  Mount an encFS filesystem
# Author     :  Paco Orozco <paco@pacoorozco.info>
# Requires   :  encfs, grep
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

# Path to the encrypted filesystem
ENCRYPTED_FILESYSTEM=~/Dropbox/Encrypted

# Folder to mount the filesystem in plain
PLAIN_MOUNT_POINT=~/Private

# Enable automatic unmount of the filesystem after a period of inactivity (in minutes).
IDLE_TIMEOUT=10

##########################################################################
# DO NOT MODIFY BEYOND THIS LINE
##########################################################################
PROGRAM_NAME=$(basename "$0")
PROGRAM_VERSION='0.0.7'

REQUIRED_BINARIES="encfs grep"

# Script exits immediately if any command within it exits with a non-zero status
set -o errexit
# Script will catch the exit status of a previous command in a pipe.
set -o pipefail
# Script exits immediately if tries to use an undeclared variables.
set -o nounset
# Uncomment this to enable debug
# set -o xtrace

# declare global variables as readonly
readonly PROGRAM_NAME
readonly PROGRAM_VERSION
readonly REQUIRED_BINARIES

readonly ENCRYPTED_FILESYSTEM
readonly PLAIN_MOUNT_POINT
readonly IDLE_TIMEOUT

##########################################################################
# Main function
##########################################################################
main() {

  check-requirements

  while [ $# -gt 0 ]; do

    case $1 in
    -h | -\? | --help)
      show_help
      safe_exit
      ;;
    -u | --unmount)
      unmount_filesystem "${PLAIN_MOUNT_POINT}"
      safe_exit $?
      ;;
    --) # End of all options.
      shift
      break
      ;;
    -?*)
      echo "Unknown option (ignored): $1"
      ;;
    *) # Default case: No more options, so break out of the loop.
      break
      ;;
    esac

    shift

  done

  if is_filesystem_mounted "${PLAIN_MOUNT_POINT}"; then
    echo "Filesystem already mounted at ${PLAIN_MOUNT_POINT}"
    safe_exit
  fi

  mount_filesystem "${ENCRYPTED_FILESYSTEM}" "${PLAIN_MOUNT_POINT}" &&
    echo "Filesystem was mounted at ${PLAIN_MOUNT_POINT}"
}

##########################################################################
# Functions
##########################################################################
# Check if requirements are satisfied
check-requirements() {
  local binary
  for binary in ${REQUIRED_BINARIES}; do
    if ! command -v "${binary}" >/dev/null 2>&1; then
      die -e 127 "${binary} has NOT been found in PATH."
    fi
  done
}

show_help() {
  # Variables for formatting
  local -r U=$(tput smul)  # Underline
  local -r RU=$(tput rmul) # Remove underline
  local -r B=$(tput bold)  # Bold
  local -r N=$(tput sgr0)  # Normal

  cat <<-EOF
    ${B}Usage:${N}

    ${B}${PROGRAM_NAME}${N} (v.${U}${PROGRAM_VERSION}${RU}) [options]...
    ${B}Options:${N}

    ${B}-h, --help${N}     Display this help message

    ${B}-u, --unmount${N}  Umount EncFS mounting point.

    ${B}Examples:${N}

    \$ ${PROGRAM_NAME}
    Minimal options. Will mount a specified EncFS into a specified mounting point.

    \$ ${PROGRAM_NAME} ${B}--unmount${N}
    Will umount the EncFS.

EOF
}

# Return if the encrypted FS is mounted
is_filesystem_mounted() {
  grep --quiet "encfs" /proc/mounts
}

# Mount an encrypted filesystem into a mounting point
mount_filesystem() {
  local -r filesystem=$1
  local -r mount_point=$2

  echo "Please supply the credentials to mount ${filesystem}..."

  encfs --idle=${IDLE_TIMEOUT} "${filesystem}" "${mount_point}"
}

# Umount the mounting point
unmount_filesystem() {
  local -r mount_point=$1

  encfs -u "${mount_point}"
}

# Do every cleanup task before exit.
safe_exit() {
  local -r _error_code=${1:-0}
  exit "${_error_code}"
}

# Print a message and exit
die() {
  local _error_code=0
  [[ "${1}" = "-e" ]] && shift
  _error_code=${1}
  shift
  echo "${*} Exiting."
  safe_exit "${_error_code}"
}

##########################################################################
# Main code
##########################################################################

main "${@}"
