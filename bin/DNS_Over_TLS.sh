#!/usr/bin/env bash
##########################################################################
# Shellscript:  Enable/Disable DNS-Over-TLS
# Author     :  Paco Orozco <paco@pacoorozco.info>
# Requires   :  systemctl, resolvectl
##########################################################################

# Configuration variables
Configuration_File=/etc/systemd/resolved.conf.d/50-DNSOverTLS.conf

##########################################################################
# DO NOT MODIFY BEYOND THIS LINE
##########################################################################
Program_Name=$(basename "$0")
Program_Version='0.0.1'

# Script exits immediately if any command within it exits with a non-zero status
set -o errexit
# Script will catch the exit status of a previous command in a pipe.
set -o pipefail
# Script exits immediately if tries to use an undeclared variables.
set -o nounset
# Uncomment this to enable debug
# set -o xtrace

##########################################################################
# Main function
##########################################################################
function main() {

  if [[ $# -ne 1 ]]; then
    show_status_DNS_Over_TLS
    exit
  fi

  check_requirements

  case "$1" in
  --enable)
    enable_DNS_Over_TLS
    ;;
  --disable)
    disable_DNS_Over_TLS
    ;;
  --status)
    show_status_DNS_Over_TLS
    exit
    ;;
  --help|-h)
    show_usage
    exit
    ;;
  *)
    echo "ERROR: Unknown argument: $1."
    echo
    show_usage
    exit 1
    ;;
  esac

  show_status_DNS_Over_TLS
}

##########################################################################
# Functions
##########################################################################

function check_requirements() {
  if [[ "$(whoami)" != "root" ]]; then
    echo "ERROR: You must be root to execute this command."
    exit 127
  fi

  if [[ ! -f "${Configuration_File}" && ! -f "${Configuration_File}.disabled" ]]; then
    echo "ERROR: Neither ${Configuration_File} nor ${Configuration_File}.disable exists."
    exit 127
  fi
}

function show_usage() {
  cat <<-EOF
    Version: ${Program_Version}

    Usage: ${Program_Name} --enable | --disable | --status | --help

EOF
}

function show_status_DNS_Over_TLS() {
  if [[ $(resolvectl | grep -c '+DNSOverTLS') -eq 0 ]]; then
    echo "DNS-Over-TLS is disabled."
  else
    echo "DNS-Over-TLS is enabled."
  fi
}

function enable_DNS_Over_TLS() {
  if [[ -f "${Configuration_File}" ]]; then
    return
  fi

  mv "${Configuration_File}.disabled" "${Configuration_File}"
  restart_Systemd_Resolved
}

function disable_DNS_Over_TLS() {
  if [[ -f "${Configuration_File}.disabled" ]]; then
    return
  fi

  mv "${Configuration_File}" "${Configuration_File}.disabled"
  restart_Systemd_Resolved
}

function restart_Systemd_Resolved() {
  systemctl restart systemd-resolved.service
}

##########################################################################
# Main code
##########################################################################

main "${@}"
