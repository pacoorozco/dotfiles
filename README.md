# dotfiles

[![Build Status][build-badge]][build]
[![License][license-badge]][license]

This project contains the dotfiles and custom shell scripts that I use on my workstations.

Why keep them at GitHub? It’s a way to share advanced shell tips with other developers, and more practically, a way to back up my configuration. I was tired of having a bunch of configurations across all my machines, especially when trying to keep all up to date. So I got fed up and threw them on GitHub. It's not perfect (yet!), but it's a great starting point for any Linux config.

Contents
-----

### Introduction
Each folder is named after a package and contains every configuration file used by that application. Besides some noted exceptions, the files inside the folders are relative to home (e.g. the file `vim/.vimrc` goes to `~/.vimrc`).

Every section here explains which settings and (if any) workarounds/fixes are used to obtain the described result.

For further reference, read carefully every section in this file, and copy only the configuration files relative to the parts you are trying to setup.

If none of these helped, feel free to open an issue here. Include your distro informations and the configuration values you are trying.

### Overview
- OS: kubuntu 20.04 LTS
- DE: Plasma
- Global theme: Breeze Dark
- Plasma style: Breeze Dark
- Application style: Breeze
- Windows decoration: Breeze
- Colors: Breeze Dark
- Icon Theme: Breeze Dark
- Login Manager: SDDM

### Handy scripts
These scripts will be installed to `~/bin` and added to your `$PATH`:

* `fs-cryptmount.sh` Mounts a encFS filesystem where I keep personal data.
* `make_snapshot.sh` My personal backup solution to an external HD.
* `myip.sh` An script to obtain my real IP

### Shell enhancements

#### zsh (default)
* [oh-my-zsh](https://github.com/robbyrussell/oh-my-zsh) - framework for managing your zsh configuration. It includes autocompletion, themes, aliases, custom functions...
* [powerlevel10k/powerlevel10k](https://github.com/romkatv/powerlevel10k) theme - emphasizes speed, flexibility and out-of-the-box experience.
* Plugins:
   * aws
   * colored-man-pages
   * extract
   * git
   * pass
   * [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) - suggest commands as you type, based on command history
* `$EDITOR` is `vim`.
* `umask` is `077`.
* Configure private tokens from `$HOME/.env_private`.
* Set `$GOPATH`.

#### bash
* Enable [Bash-it](https://github.com/Bash-it/bash-it) framework. It includes autocompletion, themes, aliases, custom functions...
* Improved Bash history based on [this post](https://www.digitalocean.com/community/tutorials/how-to-use-bash-history-commands-and-expansions-on-a-linux-vps).
* Add useful aliases, like `ll`, `la`...
* `$EDITOR` is `vim`.
* `umask` is `077`.
* Configure private tokens from `$HOME/.env_private`.
* Set `$GOPATH`.

### Git configuration
* Enables color output and line-ending checks.
* Shortens common commands: `br`, `ci`, `co`, `df`, `lg`.

Remember to configure `user.name`, `user.email` and `user.signingkey` on `.gitconfig`.

### Vim Configuration
- 4 spaced tabs
- Autocompletion always on
- Case insensitive search
- Global highlighting of search matches
- Numbered lines
- Trailing whitespace highlighting
- Tons of plugins through [Vundle](https://github.com/VundleVim/Vundle.vim): `onedark`, `lightline`, `vim-ployglot`.
- [One Dark](https://github.com/joshdick/onedark.vim) theme


## Installation
Choose a place to store the dotfiles, like `~/dotfiles`.

```
git clone https://github.com/pacoorozco/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

[license]: https://github.com/pacoorozco/dotfiles
[license-badge]: https://img.shields.io/github/license/pacoorozco/dotfiles.svg?style=flat-square
[build]: https://travis-ci.org/pacoorozco/dotfiles
[build-badge]: https://travis-ci.org/pacoorozco/dotfiles.svg