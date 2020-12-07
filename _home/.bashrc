#!/bin/bash

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=100000
HISTFILESIZE=200000
HISTCONTROL=ignorespace

# enable color support of ls and also add handy aliases
alias ls='ls --color=auto'
alias dir='dir --color=auto'
alias vdir='vdir --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# liquidprompt settings
# shellcheck source=.liquidprompt/liquidprompt
# shellcheck disable=SC1091
[[ $- = *i* ]] && source ~/.liquidprompt/liquidprompt

# set gopath
if [[ $(hostname) == aang ]]; then
	export GOPATH=$HOME/Documents/Code/go
	export PATH=$PATH:/usr/lib/go-1.6/bin:$GOPATH/bin
	# [2020-05-08] Fix for being able to compile the Go standard library.
	export GOROOT=
fi

# set additional local search path
export PATH=$HOME/.local/bin:$HOME/.cargo/bin:$PATH

# set password store directory
if [[ $(hostname) =~ ^(aang|suyin-arch)$ ]]; then
	export PASSWORD_STORE_DIR=~/Documents/Vault/password-store
fi

# add an alias for starting factorio
if [[ $(hostname) == aang ]]; then
	alias factorio="firejail \$HOME/Games/Factorio/bin/x64/factorio"
fi

# use keychain if we're on aang/suyin-arch and we are logged in via SSH
if [[ $(hostname) =~ ^(aang|suyin-arch)$ ]]; then
	if [ -n "$SSH_CONNECTION" ]; then
		eval "$(keychain --eval --quiet)"
	fi
fi

RIPGREP="$(which rg)"
function rg()
{
	"$RIPGREP" --pretty "$@" | less -RFX
}

# preferred editor, pager on suyin-arch is vim, "bat --plain"
# add an alias for starting factorio
if [[ $(hostname) == suyin-arch ]]; then
	export EDITOR="vim"
	export PAGER="bat --plain"
fi