#!/usr/bin/env bash


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

########## Params setup

## get the real path of install.sh
SOURCE="${BASH_SOURCE[0]}"
# resolve $SOURCE until the file is no longer a symlink
while [[ -L "$SOURCE" ]]; do
  APP_PATH="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  # if $SOURCE was a relative symlink, we need to resolve it relative to the path
  # where the symlink file was located
  [[ $SOURCE != /* ]] && SOURCE="$APP_PATH/$SOURCE"
done
APP_PATH="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

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
function error()    { local _message="${*}"; _alert error >&2; }
function warning()  { local _message="${*}"; _alert warning >&2; }
function notice()   { local _message="${*}"; _alert notice; }
function info()     { local _message="${*}"; _alert info; }
function debug()    { local _message="${*}"; _alert debug; }
function input()    { local _message="${*}"; _alert info; }

# Usage info
function show_help () {
  # Variables for formatting
  local U; U=$(tput smul)  # Underline
  local RU; RU=$(tput rmul) # Remove underline
  local B; B=$(tput bold)  # Bold
  local N; N=$(tput sgr0)  # Normal

  cat <<-EOF
    ${B}Usage${N}:

    ${B}${program_name}${N} <task>[ ${U}taskFoo${RU} ${U}taskBar${RU} ...]

    ${B}Tasks:${N}

    ${B}aws_credentials${N}   Configure AWS credentials in .aws/credentials
    ${B}atom_cfg${N}          Configure ATOM editor
    ${B}bash_rc${N}           Install & configure bash-it
    ${B}bin${N}               Make ~/bin accessible
    ${B}editorconfig${N}      Configure .editorconfig
    ${B}env_private${N}       Configure TOKENS in environment variables (needs tokens/TOKENS in pass)
    ${B}defaults${N}          Configure some defaults
    ${B}fonts${N}             Install & configure fonts
    ${B}gnupg${N}             Configure GNUPG
    ${B}git_config${N}        Configure git
    ${B}vim_rc${N}            Configure Vim
    ${B}zsh_rc${N}            Install & configure oh-my-zsh

    Version: ${program_version}

EOF
}

function is_program_exists(){
  if type "$1" &>/dev/null; then
    return 0
  else
    return 1
  fi;
}

# Check file exists or die
function must_file_exists () {
  for file in "$@"; do
    if [[ ! -e "$file" ]]; then
      die -e 1 "You must have file *${file}*"
    fi;
  done;
}

# Check if a program exists, if not recommends you to install it
function better_program_exists_one () {
  local exists="no"
  for program in "$@"; do
    if ( is_program_exists "$program" ); then
      exists="yes"
      break
    fi;
  done;
  if [[ "$exists" = "no" ]]; then
    notice "Maybe you can take full use of this by installing one of ($*)~"
  fi;
}

# Check if a program exists or die
function must_program_exists() {
  for program in "$@"; do
    if ( ! is_program_exists "$program" ); then
      die -e 1 "You must have *$program* installed!"
    fi;
  done;
}

# Check if platform is Linux
function is_linux () {
  [[ "$(uname)" = "Linux" ]] && return 0 || return 1
}

# Link a file if exists
function lnif(){
  if [ -e "$1" ]; then
    info "Linking $1 to $2"
    rm -rf "$2"
    ln -s "$1" "$2"
  fi
}

# Clone a github repo
function sync_repo() {

  must_program_exists "git"

  local repo_uri=$1
  local repo_path=$2
  local repo_branch=${3:-master}
  local repo_name=${1:19} # length of (https://github.com/)

  if [[ ! -d "$repo_path" ]]; then
    info "Cloning $repo_name ..."
    mkdir -p "$repo_path"
    git clone --depth 1 --branch "$repo_branch" "$repo_uri" "$repo_path"
    notice "noticefully cloned $repo_name."
  else
    info "Updating $repo_name ..."
    cd "$repo_path" && git pull origin "$repo_branch"
    notice "noticefully updated $repo_name."
  fi

  if [[ -e "$repo_path/.gitmodules" ]]; then
    info "Updating $repo_name submodules ..."
    cd "$repo_path"
    git submodule update --init --recursive
    notice "noticefully updated $repo_name submodules."
  fi
}

# Configure ATOM
function install_atom_cfg(){

  notice "Installing ATOM configuration ..."

  lnif "$APP_PATH/atom/config.cson" \
       "$HOME/.atom/config.cson"

  notice "noticefully installed ATOM configuration."
}

# Configure GNUPG
function install_gnupg_config(){

  notice "Installing GNUPG configuration ..."

  lnif "$APP_PATH/gnupg/gpg-agent.conf" \
       "$HOME/.gnupg/gpg-agent.conf"

  lnif "$APP_PATH/gnupg/gpg.conf" \
       "$HOME/.gnupg/gpg.conf"

  notice "noticefully installed GNUPG configuration."
}

# Configure bin scripts
function install_bin(){

  notice "Installing useful small scripts ..."

  local source_path="$APP_PATH/bin"

  for bin in $source_path/*; do
    local script_name
    script_name=$(basename "$bin")
    lnif "$bin" "$HOME/bin/$script_name"
  done

  notice "noticefully installed useful scripts."
}

# Configure editorconfig
function install_editorconfig(){

  notice "Installing editorconfig ..."

  lnif "$APP_PATH/editorconfig/editorconfig" \
       "$HOME/.editorconfig"

  notice "Maybe you should install editorconfig plugin for vim or sublime"
  notice "noticefully installed editorconfig."
}

function install_fonts(){

  if ( ! is_linux ); then
    die -e 2 "This support *Linux* only"
  fi;

  must_program_exists "git"

  notice "Installing font Source Code Pro ..."

  sync_repo "https://github.com/adobe-fonts/source-code-pro.git" \
            "$APP_PATH/.cache/source-code-pro" \
            "release"

  local source_code_pro_ttf_dir="$APP_PATH/.cache/source-code-pro/TTF"

  # borrowed from powerline/fonts/install.sh
  local find_command="find \"$source_code_pro_ttf_dir\" \( -name '*.[o,t]tf' -or -name '*.pcf.gz' \) -type f -print0"

  local fonts_dir

  # Linux
  fonts_dir="$HOME/.fonts"
  mkdir -p "$fonts_dir"
 
  # Copy all fonts to user fonts directory
  eval "$find_command" | xargs -0 -I % cp "%" "$fonts_dir/"

  # Reset font cache on Linux
  if [[ -n "$(which fc-cache)" ]]; then
    fc-cache -f "$fonts_dir"
  fi

  notice "noticefully installed Source Code Pro font."
}

# Configure git config
function install_git_config(){

  must_program_exists "git"

  notice "Installing gitconfig..."

  lnif "$APP_PATH/git/gitconfig" \
       "$HOME/.gitconfig"

  info "Now config your name and email for git."

  local user_now
  user_now="$(whoami)"

  input "What's your git username? ($user_now) "

  local user_name
  read -r user_name
  if [ "$user_name" = "" ]; then
    user_name="$user_now"
  fi
  git config --global user.name "$user_name"

  input "What's your git email? ($user_name@example.com) "

  local user_email
  read -r user_email
  if [ "$user_email" = "" ]; then
    user_email="${user_now}@example.com"
  fi
  git config --global user.email "$user_email"

  notice "noticefully installed gitconfig."
}

# Configure vim_rc with Vundle and plugins
function install_vim_rc() {

  must_program_exists "vim"

  notice "Installing vimrc ..."

  sync_repo "https://github.com/VundleVim/Vundle.vim.git" \
            "$APP_PATH/vim/plugins/Vundle.vim"

  lnif "$APP_PATH/vim" \
       "$HOME/.vim"
  lnif "$APP_PATH/vim/vimrc" \
       "$HOME/.vimrc"

  vim +PlugInstall +qall

  notice "noticefully installed vimrc."

  notice "You can add your own configs to ~/.vimrc.local, vim will source them automatically"
}

function util_append_dotvim_group(){
  local group=$1
  local conf="$HOME/.vimrc.plugins.before"

  if ! grep -iE "^[ \t]*let[ \t]+g:dotvim_groups[ \t]*=[ \t]*\[.+]" "$conf" &>/dev/null ; then
    printf "\nlet g:dotvim_groups = ['%s']" "$group" >> "$conf"
  elif ! grep -iE "'$group'" "$conf" &>/dev/null; then
    sed -e "s/]/, '$group']/" "$conf" | tee "$conf" &>/dev/null
    if grep -iE "\[[ \t]*," "$conf" &>/dev/null; then
      sed -e "s/\[[ \t]*,[ \t]*/[/" "$conf" | tee "$conf" &>/dev/null
    fi;
  fi;
}

# Try to change current shell using chsh
function change_shell() {
  local new_shell="$1"
  local TEST_CURRENT_SHELL
  TEST_CURRENT_SHELL=$(expr "$SHELL" : '.*/\(.*\)')
  if [ "$TEST_CURRENT_SHELL" != "$new_shell" ]; then
    # If this platform provides a "chsh" command (not Cygwin), do it, man!
    if hash chsh >/dev/null 2>&1; then
      info "Time to change your default shell to bash!"
      chsh -s "$(grep "/${new_shell}$" /etc/shells | tail -1)"
    # Else, suggest the user do so manually.
    else
      error "I can't change your shell automatically because this system does not have chsh."
      error "Please manually change your default shell to ${new_shell}!"
    fi
  fi
}

# Configure bash_rc with bash-it and plugins
function install_bash_rc() {

  must_program_exists "bash"

  notice "Installing bashrc..."

  sync_repo "https://github.com/Bash-it/bash-it.git" \
            "$APP_PATH/bash/bash_it"

  lnif "$APP_PATH/bash/bash_it" \
       "$HOME/.bash_it"
  lnif "$APP_PATH/bash/bash_profile" \
       "$HOME/.bash_profile"
  lnif "$APP_PATH/bash/bashrc" \
       "$HOME/.bashrc"

  change_shell "bash"

  notice "noticefully installed bash and bash-it."
  notice "You can add your own configs to ~/.bashrc.local , bash will source them automatically"

  notice "Please open a new bash terminal to make configs go into effect."
}

# Configure zsh_rc with oh-my-zsh and plugins
function install_zsh_rc() {

  must_program_exists "zsh"

  notice "Installing zshrc ..."

  sync_repo "https://github.com/robbyrussell/oh-my-zsh.git" \
            "$APP_PATH/zsh/oh-my-zsh"

  # add zsh plugin zsh-syntax-highlighting support
  sync_repo "https://github.com/zsh-users/zsh-syntax-highlighting.git" \
            "$APP_PATH/zsh/oh-my-zsh/custom/plugins/zsh-syntax-highlighting"

  # add zsh plugin zsh-autosuggestions support
  sync_repo "https://github.com/tarruda/zsh-autosuggestions.git" \
            "$APP_PATH/zsh/oh-my-zsh/custom/plugins/zsh-autosuggestions"

  lnif "$APP_PATH/zsh/oh-my-zsh" \
       "$HOME/.oh-my-zsh"
  lnif "$APP_PATH/zsh/zshrc" \
       "$HOME/.zshrc"
  lnif "$APP_PATH/zsh/zshrc.local" \
       "$HOME/.zshrc.local"

  change_shell "zsh"

  notice "noticefully installed zsh and oh-my-zsh."
  notice "You can add your own configs to ~/.zshrc.local , zsh will source them automatically"

  notice "Please open a new zsh terminal to make configs go into effect."
}

# Configure private TOKENS into environment variables
function install_env_private() {

  must_program_exists "pass"

  notice "Installing environment private tokens ..."
  info "You will be asked for decryption key!"

  pass show tokens/ENV_TOKENS > "$HOME/.env_private"

  notice "Successfully installed environment private tokens"
  notice "Please open a new terminal to make configs go into effect."
}

# Configure AWS credentials
function install_aws_credentials() {

  must_program_exists "pass"

  notice "Installing AWS credentials ..."
  info "You will be asked for decryption key!"

  pass show tokens/AWS_CREDENTIALS > "$HOME/.aws/credentials"

  notice "Successfully installed AWS_CREDENTIALS"
  notice "Please open a new terminal to make configs go into effect."
}

# Configure some defaults
function configure_defaults() {
  notice "Configuring some defaults ..."

  lnif "$APP_PATH/defaults/excludes_from_backup" \
       "$HOME/.excludes_from_backup"

  notice "Successfully configured defaults"
}

##########################################################################
# Main function
##########################################################################
function main () {
  if [[ $# = 0 ]]; then
    show_help
    safe_exit 2
  fi

  for arg in "$@"; do
    case "$arg" in
      atom_cfg)
        install_atom_cfg
        ;;
      aws_credentials)
        install_aws_credentials
        ;;
      bin)
        install_bin
        ;;
      bash_rc)
          install_bash_rc
          ;;
      editorconfig)
        install_editorconfig
        ;;
      env_private)
          install_env_private
          ;;
      defaults)
          configure_defaults
          ;;
      fonts)
        install_fonts
        ;;
      gnupg)
        install_gnupg_config
        ;;
      git_config)
        install_git_config
        ;;
      vim_rc)
        install_vim_rc
        ;;
      zsh_rc)
        install_zsh_rc
        ;;
      *)
        error "Invalid params $arg"
        show_help
        safe_exit 2
        ;;
    esac
  done
}

##########################################################################
# Main code
##########################################################################
main "$@"
