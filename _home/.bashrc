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

# use keychain if we're on aang and we are logged in via SSH
if [[ $(hostname) == aang ]]; then
	if [ -n "$SSH_CONNECTION" ]; then
		eval "$(keychain --eval --quiet)"
	fi
fi

# also use keychain by default on suyin-arch
if [[ $(hostname) == suyin-arch ]]; then
	eval "$(keychain --eval --quiet)"
fi

RIPGREP="$(which rg)"
function rg()
{
	"$RIPGREP" --pretty "$@" | less -RFX
}

function incarnate()
{
	local action
	local this_host
	local other_host
	
	action="$1"
	this_host="$(hostname)"
	case "$this_host" in
		aang)
			other_host=suyin-arch
			;;
		suyin-arch)
			other_host=aang
			;;
		*)
			echo >&2 "incarnate(): not set up for this host ('$this_host'), aborting."
			return 1
			;;
	esac
	case "$action" in
		push)
			for dir in "Documents" "Videos" "Music" "Games" "Zotero" ".factorio"; do
				rsync -ravuzhn --delete "$HOME/${dir}/" "helikon:katarastorage/private/sync_${this_host}/${dir}/"
			done
			;;
		pull)
			for dir in "Documents" "Videos" "Music" "Games" "Zotero" ".factorio"; do
				rsync -ravuzhn --delete "helikon:katarastorage/private/sync_${other_host}/${dir}/" "$HOME/${dir}/"
			done
			;;
		*)
			echo >&2 "incarnate(): usage: incarnate <push|pull>"
			return 1
			;;
	esac
}
