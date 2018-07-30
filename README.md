# dotfiles

[![Build Status][build-badge]][build]
[![License][license-badge]][license]

This project contains the dotfiles and custom shell scripts that I use on my workstations.

Why keep them at GitHub? It’s a way to share advanced shell tips with other developers, and more practically, a way to back up my configuration. I was tired of having a bunch of configurations across all my machines, especially when trying to keep all up to date. So I got fed up and threw them on GitHub. It's not perfect (yet!), but it's a great starting point for any Linux config.

Contents
-----

### Handy scripts

These scripts will be installed to `~/bin` and added to your `$PATH`:

* `fs-cryptmount.sh` Mounts a encFS filesystem where I keep personal data.
* `make_snapshot.sh` My personal backup solution to an external HD.
* `myip.sh` An script to obtain my real IP

### Shell enhancements (bash)

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
* Configure `user.name`, `user.email` and `user.signingkey`.

In addition, during installation (see below), you will be prompted for your full name and email address, which are automatically added to the git config file.

### Vim Configuration
- 4 spaced tabs
- Autocompletion always on
- Case insensitive search
- Cursor crosshair
- Dark background
- Global config base
- Global highlighting of search matches
- Dracula theme
- Marks in gutter
- Mouse support
- NERDTree Configuration
- Numbered lines
- Rainbow Parentheses Configuration
- TAB toggles Taglist
- Tons of plugins through Pathogen
- Trailing whitespace highlighting

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