#!/usr/bin/env bash

# Configuration variables
GPUPBinary=/home/paco/web/gpup/gpup

##########################################################################
# DO NOT MODIFY BEYOND THIS LINE
##########################################################################
# Program name and version
programName=$(basename "$0")
programVersion='0.0.1'

# Script exits immediately if any command within it exits with a non-zero status
set -o errexit
# Script will catch the exit status of a previous command in a pipe.
set -o pipefail
# Script exits immediately if tries to use an undeclared variables.
set -o nounset
# Uncomment this to enable debug
# set -o xtrace

# 0 - Quiet, 1 - Errors, 2 - Warnings, 3 - Normal, 4 - Verbose, 9 - Debug
verbosityLevel=3
dryRunFlag=0
forceNewDatabase=0
databasePath=""

##########################################################################
# Main function
##########################################################################
function main () {
	argsManagement "$@"

	checkRequirements

	[[ -z "${databasePath}" ]] && databasePath="${DirToUpload}"
	# This is the file where we are going to track uploaded files.
	uploadedFilesDatabase="${databasePath}/.uploaded_files_database.txt"
	touch "${uploadedFilesDatabase}"
	[[ ! -f "${uploadedFilesDatabase}" ]] && die -e 127 "Failed to create uploaded files database: ${uploadedFilesDatabase}."
	debug "Uploaded files database is: ${uploadedFilesDatabase}"

 	# declare variables as readonly
 	readonly DirToUpload
 	readonly uploadedFilesDatabase

 	if [[ "${forceNewDatabase}" -eq "1" ]]; then
		debug "Creating new database: ${uploadedFilesDatabase}"
		cp /dev/null "${uploadedFilesDatabase}"
	fi

	find "${DirToUpload}" -mindepth 1 -maxdepth 1 -type d -print0 |
	while IFS= read -r -d '' Dir; do
    	info "Processing ${Dir}"
    	if keyIsNotInDatabase "${Dir}" "${uploadedFilesDatabase}"; then
        	debug "Uploading: ${Dir}"
        	if uploadDirectory "${Dir}"; then
            	addKeyToDatabase "${Dir}" "${uploadedFilesDatabase}"
            	info "    Upload succeeded."
        	else
            	die -e 2 "An error ocurred when uploading: ${Dir}"
        	fi
    	else
        	debug "Directory was found in uploaded files database. Skipped!"
    	fi
	done
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

# Print to console depending of verbosity level
function _alert () {
  if [[ "${verbosityLevel}" -ge "${LOG_LEVELS[${1}]}" ]]; then
    echo -e "$(date +"%X") $(printf "[%s]" "${1}") ${_message}"
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
function input ()     { local _message="${*}"; _alert info; }

# Manage arguments and configure variables according to it
function argsManagement () {
  local OPTIND=1
  while getopts "hv:dqfnb:" OPTION; do
    case "${OPTION}" in
      h)
        usage
        safeExit 1
        ;;
      v)
        if [[ ! ${OPTARG} =~ ^[0-9]+$ ]] ; then
          die -e 1 "Bad verbose level"
        else
          verbosityLevel=${OPTARG}
        fi
        ;;
      d)
        verbosityLevel=${LOG_LEVELS['debug']}
        debug "Debug mode has been enabled."
        ;;
      q)
        verbosityLevel=0
       ;;
      n)
        dryRunFlag=1
        warning "Dry run mode enabled. No uploads will be done."
        ;;
      f)
		forceNewDatabase=1
		debug "User has asked to create a new uploaded files databases."
		;;
	  b)
		databasePath=${OPTARG}
		warning "Custom database path has been defined: ${databasePath}"
		;;
      '?')
        warning "Unknown option (ignored): -${OPTARG}"
      ;;
    esac
  done
  # Shift off the options and optional --.
  shift "$((OPTIND - 1))"

  # Get first parameter as directory to be uploaded.
  DirToUpload=${1:-}
}

# Check if requirements are satisfied
function checkRequirements () {
    local _requiredBinaries="${GPUPBinary}"

  if [[ -z "${DirToUpload}" ]]; then
    die -e 127 "Missing argument. You must supply a directory to be uploaded."
  fi

  if [[ ! -d "${DirToUpload}" ]]; then
  	die -e 127 "Supplied arguments is not a directory."
  fi

  for reqCommand in ${_requiredBinaries}
  do
    if [[ ! -x "$(command -v "${reqCommand}")" ]]; then
        die -e 127 "You need '${reqCommand}' command to use this script."
    fi
  done
}

# Show usage
function usage () {
    cat <<-EOF
    Upload pictures to Google Photos service.
    It keeps track of uploaded files in order to be able to resume uploads.

    Usage:

    ${programName} [options] [-b <Database Path>] <Directory>
    Version: ${programVersion}

    Options:
    -h  Display this help message
    -b  <Database Path> Set the database path where uploaded files will be kept.
    -f  Remove uploaded files database. It will upload all files.
    -n  Dry run. Executes the program without uploading anything.
    -v  Set verbose level [0-9].
    -d  Debug mode.
    -q  Quiet mode.

    Examples:
    \$ ${programName} /home/myuser/Pictures
    Will upload all pictures in the given path to Google Photos service.
EOF
}

# Uploads a directory and creates a new album using `gpup`.
function uploadDirectory() {
	local _directory
	_directory=${1:-}
	[[ -z "${_directory}" ]] && die -e 127 "No directory has been specified."
	local _albumName

        _albumName=$(basename "${_directory}")
	local _ret
	 _ret=0
	if [[ "${dryRunFlag}" -eq "0" ]]; then
		${GPUPBinary} --new-album "${_albumName}" "${_directory}"
		_ret=$?
	fi
	return ${_ret}
}

# Add a new key to uploaded files database
function addKeyToDatabase() {
	local _key; _key=${1:-}
	[[ -z "${_key}" ]] && die -e 127 "A null key has been supplied."
	local _db; _db=${2:-}
	[[ -z "${_db}" ]] && die -e 127 "No database has been specified."

	local _ret; _ret=0
	if [[ "${dryRunFlag}" -eq 0 ]]; then
		echo "${_key}" >> "${_db}"
		_ret=$?
	fi

	return ${_ret}
}

# Returns if a key exists in database.
function keyIsInDatabase() {
	local _key; _key=${1:-}
	[[ -z "${_key}" ]] && die -e 127 "A null key has been supplied."
	local _db; _db=${2:-}
	[[ -z "${_db}" ]] && die -e 127 "No database has been specified."

	local _ret
	grep -q "${_key}" "${_db}"
	_ret=$?
	return ${_ret}
}

# Returns if a key does not exists in database.
function keyIsNotInDatabase() {
	local _ret
	keyIsInDatabase "$1" "$2"
	_ret=$?
	if [[ "${_ret}" -eq "0" ]]; then
		return 1
	fi
	return 0
}

##########################################################################
# Main code
##########################################################################

main "${@}"
