#!/usr/bin/env bash

########## Params setup

## get the real path of install.sh
SOURCE="${BASH_SOURCE[0]}"
# resolve $SOURCE until the file is no longer a symlink
while [ -L "$SOURCE" ]; do
  APP_PATH="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  # if $SOURCE was a relative symlink, we need to resolve it relative to the path
  # where the symlink file was located
  [[ $SOURCE != /* ]] && SOURCE="$APP_PATH/$SOURCE"
done
APP_PATH="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

# color params
dot_color_none="\033[0m"
dot_color_dark="\033[0;30m"
dot_color_dark_light="\033[1;30m"
dot_color_red="\033[0;31m"
dot_color_red_light="\033[1;31m"
dot_color_green="\033[0;32m"
dot_color_green_light="\033[1;32m"
dot_color_yellow="\033[0;33m"
dot_color_yellow_light="\033[1;33m"
dot_color_blue="\033[0;34m"
dot_color_blue_light="\033[1;34m"
dot_color_purple="\033[0;35m"
dot_color_purple_light="\033[1;35m"
dot_color_cyan="\033[0;36m"
dot_color_cyan_light="\033[1;36m"
dot_color_gray="\033[0;37m"
dot_color_gray_light="\033[1;37m"

########## Basics setup
function msg(){
  printf '%b\n' "$*$dot_color_none" >&2
}
function prompt(){
  printf '%b' "$dot_color_purple[+] $*$dot_color_none "
}
function step(){
  msg "\n$dot_color_yellow[→] $*"
}
function info(){
  msg "$dot_color_cyan[>] $*"
}
function success(){
  msg "$dot_color_green[✓] $*"
}
function error(){
  msg "$dot_color_red_light[✗] $*"
}
function tip(){
  msg "$dot_color_red_light[!] $*"
}

function is_file_exists(){
  [[ -e "$1" ]] && return 0 || return 1
}
function is_dir_exists(){
  [[ -d "$1" ]] && return 0 || return 1
}
function is_program_exists(){
  if type "$1" &>/dev/null; then
    return 0
  else
    return 1
  fi;
}
function must_file_exists(){
  for file in $@; do
    if ( ! is_file_exists $file ); then
      error "You must have file *$file*"
      exit
    fi;
  done;
}
function better_program_exists_one(){
  local exists="no"
  for program in $@; do
    if ( is_program_exists "$program" ); then
      exists="yes"
      break
    fi;
  done;
  if [[ "$exists" = "no" ]]; then
    tip "Maybe you can take full use of this by installing one of ($*)~"
  fi;
}
function must_program_exists(){
  for program in $@; do
    if ( ! is_program_exists "$program" ); then
      error "You must have *$program* installed!"
      exit
    fi;
  done;
}

function is_platform(){
  [[ `uname` = "$1" ]] && return 0 || return 1
}
function is_linux(){
  ( is_platform Linux ) && return 0 || return 1
}
function is_mac(){
  ( is_platform Darwin ) && return 0 || return 1
}

function lnif(){
  if [ -e "$1" ]; then
    info "Linking $1 to $2"
    if ( ! is_dir_exists `dirname "$2"` ); then
      mkdir -p `dirname "$2"`
    fi;
    rm -rf "$2"
    ln -s "$1" "$2"
  fi;
}

function sync_repo(){

  must_program_exists "git"

  local repo_uri=$1
  local repo_path=$2
  local repo_branch=${3:-master}
  local repo_name=${1:19} # length of (https://github.com/)

  if ( ! is_dir_exists "$repo_path" ); then
    info "Cloning $repo_name ..."
    mkdir -p "$repo_path"
    git clone --depth 1 --branch "$repo_branch" "$repo_uri" "$repo_path"
    success "Successfully cloned $repo_name."
  else
    info "Updating $repo_name ..."
    cd "$repo_path" && git pull origin "$repo_branch"
    success "Successfully updated $repo_name."
  fi;

  if ( is_file_exists "$repo_path/.gitmodules" ); then
    info "Updating $repo_name submodules ..."
    cd "$repo_path"
    git submodule update --init --recursive
    success "Successfully updated $repo_name submodules."
  fi;
}

function util_must_python_pipx_exists(){
  if ( ! is_program_exists pip ) && ( ! is_program_exists pip2 ) && ( ! is_program_exists pip3 ); then
    error "You must have installed pip or pip2 or pip3 for installing python packages."
    exit
  fi;
}

########## Steps setup

function usage(){
  echo
  echo 'Usage: install.sh <task>[ taskFoo taskBar ...]'
  echo
  echo 'Tasks:'
  printf "$dot_color_green\n"
  echo '    - aws_credentials'
  echo '    - atom_cfg'
  echo '    - bash_rc'
  echo '    - bin'
  echo '    - editorconfig'
  echo '    - env_private'
  echo '    - fonts_source_code_pro'
  echo '    - git_config'
  echo '    - vim_rc'
  echo '    - zsh_rc'
  printf "$dot_color_none\n"
}

function install_atom_cfg(){

  step "Installing ATOM configuration ..."

  lnif "$APP_PATH/atom/config.cson" \
       "$HOME/.atom/config.cson"

  success "Successfully installed ATOM configuration."
}

function install_bin(){

  step "Installing useful small scripts ..."

  local source_path="$APP_PATH/bin"

  for bin in `ls -p $source_path | grep -v /`; do
    lnif "$source_path/$bin" "$HOME/bin/$bin"
  done;

  success "Successfully installed useful scripts."
}

function install_editorconfig(){

  step "Installing editorconfig ..."

  lnif "$APP_PATH/editorconfig/editorconfig" \
       "$HOME/.editorconfig"

  tip "Maybe you should install editorconfig plugin for vim or sublime"
  success "Successfully installed editorconfig."
}

function install_fonts_source_code_pro(){

  if ( ! is_mac ) && ( ! is_linux ); then
    error "This support *Linux* and *Mac* only"
    exit
  fi;

  must_program_exists "git"

  step "Installing font Source Code Pro ..."

  sync_repo "https://github.com/adobe-fonts/source-code-pro.git" \
            "$APP_PATH/.cache/source-code-pro" \
            "release"

  local source_code_pro_ttf_dir="$APP_PATH/.cache/source-code-pro/TTF"

  # borrowed from powerline/fonts/install.sh
  local find_command="find \"$source_code_pro_ttf_dir\" \( -name '*.[o,t]tf' -or -name '*.pcf.gz' \) -type f -print0"

  local fonts_dir

  if ( is_mac ); then
    # MacOS
    fonts_dir="$HOME/Library/Fonts"
  else
    # Linux
    fonts_dir="$HOME/.fonts"
    mkdir -p $fonts_dir
  fi

  # Copy all fonts to user fonts directory
  eval $find_command | xargs -0 -I % cp "%" "$fonts_dir/"

  # Reset font cache on Linux
  if [[ -n `which fc-cache` ]]; then
    fc-cache -f $fonts_dir
  fi

  success "Successfully installed Source Code Pro font."
}

function install_git_config(){

  must_program_exists "git"

  step "Installing gitconfig ..."

  lnif "$APP_PATH/git/gitconfig" \
       "$HOME/.gitconfig"

  info "Now config your name and email for git."

  local user_now=`whoami`

  prompt "What's your git username? ($user_now) "

  local user_name
  read user_name
  if [ "$user_name" = "" ]; then
    user_name=$user_now
  fi;
  git config --global user.name $user_name

  prompt "What's your git email? ($user_name@example.com) "

  local user_email
  read user_email
  if [ "$user_email" = "" ]; then
    user_email=$user_now@example.com
  fi;
  git config --global user.email $user_email

  if ( is_mac ); then
    git config --global credential.helper osxkeychain
  fi;

  success "Successfully installed gitconfig."
}

function install_vim_rc(){

  must_program_exists "vim"

  step "Installing vimrc ..."

  sync_repo "https://github.com/VundleVim/Vundle.vim.git" \
            "$APP_PATH/vim/bundle/Vundle.vim"

  lnif "$APP_PATH/vim" \
       "$HOME/.vim"
  lnif "$APP_PATH/vim/vimrc" \
       "$HOME/.vimrc"

  vim +PlugInstall +qall

  success "Successfully installed vimrc."

  success "You can add your own configs to ~/.vimrc.local, vim will source them automatically"
}

function util_append_dotvim_group(){
  local group=$1
  local conf="$HOME/.vimrc.plugins.before"

  if ! grep -iE "^[ \t]*let[ \t]+g:dotvim_groups[ \t]*=[ \t]*\[.+]" "$conf" &>/dev/null ; then
    printf "\nlet g:dotvim_groups = ['$group']" >> "$conf"
  elif ! grep -iE "'$group'" "$conf" &>/dev/null; then
    sed -e "s/]/, '$group']/" "$conf" | tee "$conf" &>/dev/null
    if grep -iE "\[[ \t]*," "$conf" &>/dev/null; then
      sed -e "s/\[[ \t]*,[ \t]*/[/" "$conf" | tee "$conf" &>/dev/null
    fi;
  fi;
}

function install_bash_rc(){

  must_program_exists "bash"

  step "Installing bashrc ..."

  sync_repo "https://github.com/Bash-it/bash-it.git" \
            "$APP_PATH/bash/bash_it"

  lnif "$APP_PATH/bash/bash_it" \
       "$HOME/.bash_it"
  lnif "$APP_PATH/bash/bash_profile" \
       "$HOME/.bash_profile"
  lnif "$APP_PATH/bash/bashrc" \
       "$HOME/.bashrc"

  # borrowed from oh-my-zsh install script
  # If this user's login shell is not already "bash", attempt to switch.
  local TEST_CURRENT_SHELL=$(expr "$SHELL" : '.*/\(.*\)')
  if [ "$TEST_CURRENT_SHELL" != "bash" ]; then
    # If this platform provides a "chsh" command (not Cygwin), do it, man!
    if hash chsh >/dev/null 2>&1; then
      info "Time to change your default shell to bash!"
      chsh -s $(grep /bash$ /etc/shells | tail -1)
    # Else, suggest the user do so manually.
    else
      error "I can't change your shell automatically because this system does not have chsh."
      error "Please manually change your default shell to bash!"
    fi
  fi

  success "Successfully installed bash and bash-it."
  tip "You can add your own configs to ~/.bashrc.local , bash will source them automatically"

  success "Please open a new bash terminal to make configs go into effect."
}

function install_zsh_rc(){

  must_program_exists "zsh"

  step "Installing zshrc ..."

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

  # borrowed from oh-my-zsh install script
  # If this user's login shell is not already "zsh", attempt to switch.
  local TEST_CURRENT_SHELL=$(expr "$SHELL" : '.*/\(.*\)')
  if [ "$TEST_CURRENT_SHELL" != "zsh" ]; then
    # If this platform provides a "chsh" command (not Cygwin), do it, man!
    if hash chsh >/dev/null 2>&1; then
      info "Time to change your default shell to zsh!"
      chsh -s $(grep /zsh$ /etc/shells | tail -1)
    # Else, suggest the user do so manually.
    else
      error "I can't change your shell automatically because this system does not have chsh."
      error "Please manually change your default shell to zsh!"
    fi
  fi

  success "Successfully installed zsh and oh-my-zsh."
  tip "You can add your own configs to ~/.zshrc.local , zsh will source them automatically"

  success "Please open a new zsh terminal to make configs go into effect."
}

function install_env_private(){

  must_program_exists "pass"

  step "Installing environment private tokens ..."
  info "You will be asked for decryption key!"

  pass show tokens/ENV_TOKENS > "$HOME/.env_private"

  success "Successfully installed environment private tokens"
  success "Please open a new terminal to make configs go into effect."
}

function install_aws_credentials(){

  must_program_exists "pass"

  step "Installing AWS credentials ..."
  info "You will be asked for decryption key!"

  pass show tokens/AWS_CREDENTIALS > "$HOME/.aws/credentials"

  success "Successfully installed AWS_CREDENTIALS"
  success "Please open a new terminal to make configs go into effect."
}

if [ $# = 0 ]; then
  usage
else
  for arg in $@; do
    case $arg in
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
      fonts_source_code_pro)
        install_fonts_source_code_pro
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
        echo
        error "Invalid params $arg"
        usage
        ;;
    esac;
  done;
fi;
