#!/usr/bin/env bash

# Script exits immediately if any command within it exits with a non-zero status
set -o errexit
# Script will catch the exit status of a previous command in a pipe.
set -o pipefail
# Script exits immediately if tries to use an undeclared variables.
set -o nounset
# Uncomment this to enable debug
# set -o xtrace

shellcheck bin/*.sh install.sh