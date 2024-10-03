#!/bin/bash

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=100000
HISTFILESIZE=200000
HISTCONTROL=ignorespace

# enable color support of ls and also add handy aliases
alias ls='ls --color=auto'
alias lt='ls --color=auto -lt'
alias dir='dir --color=auto'
alias vdir='vdir --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# liquidprompt settings
# shellcheck source=.liquidprompt
# shellcheck disable=SC1091
[[ $- = *i* ]] && source ~/.liquidprompt

# set gopath
if [[ $(hostnamectl hostname) =~ ^(aang|suyin-arch)$ ]]; then
	export GOPATH="$HOME/.cache/go"
	export PATH="$PATH:/usr/lib/go-1.6/bin:$GOPATH/bin"
	# [2020-05-08] Fix for being able to compile the Go standard library.
	export GOROOT=
fi

# set ruby path
if [[ $(hostnamectl hostname) =~ ^(aang|suyin-arch)$ ]]; then
	export PATH="$PATH:$HOME/.gem/ruby/3.0.0/bin"
fi

# set additional local search path
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

# set password store directory
if [[ $(hostnamectl hostname) =~ ^(aang|suyin-arch)$ ]]; then
	export PASSWORD_STORE_DIR=~/Documents/Vault/password-store
fi

# use keychain if we're on aang/suyin-arch and we are logged in via SSH
if [[ $(hostnamectl hostname) =~ ^(aang|suyin-arch)$ ]]; then
	if [ -n "$SSH_CONNECTION" ]; then
		eval "$(keychain --eval --quiet)"
	fi
fi

# override ripgrep with settings that fit interactive use
if which rg >/dev/null 2>/dev/null; then
	RIPGREP="$(which rg)"
	function rg() {
		"$RIPGREP" --pretty "$@" | less -RFX
	}
fi

# preferred editor is vim, and preferred pager is less
if [[ $(hostnamectl hostname) =~ ^(aang|suyin-arch)$ ]]; then
	export EDITOR="vim"
	export PAGER="less"
fi

# add an alias for `bat --plain`
if type bat >/dev/null 2>/dev/null && ! type bp >/dev/null 2>/dev/null; then
	function bp() {
		bat --plain "$@"
	}
fi

# add devkitpro tools to path
if [[ $(hostnamectl hostname) == suyin-arch ]]; then
	PATH="$PATH:/opt/devkitpro/devkitARM/bin:/opt/devkitpro/tools/bin"
fi

# just set RUST_BACKTRACE=1 by default
export RUST_BACKTRACE=1

# initialize z as zoxide (if present on this machine)
if type zoxide >/dev/null 2>/dev/null; then
	eval "$(zoxide init bash)"
fi

# add z as zoxide or cd
\builtin unalias z &>/dev/null || \builtin true
function z() {
	if type __zoxide_z >/dev/null 2>/dev/null; then
		__zoxide_z "$@"
	else
		# shellcheck disable=2164
		cd "$@"
	fi
}
function __as8_z_complete() {
	if type __zoxide_z >/dev/null 2>/dev/null; then
		# use `zoxide` completions
		__zoxide_z_complete "$@"
	else
		# use `cd` completions
		\builtin mapfile -t COMPREPLY < <(
			\builtin compgen -A directory -- "${COMP_WORDS[-1]}" || \builtin true
		)
	fi
}
\builtin complete -F __as8_z_complete -o filenames -- z

# set an ssh-agent on aang
if [[ $(hostnamectl hostname) == aang ]]; then
	if [ -z "$SSH_CONNECTION" ]; then
		eval "$(keychain --agents ssh --eval --quick --quiet)"
	fi
fi

# disable gpu on aang (where muffin does not work well with intel xe)
if [[ $(hostnamectl hostname) == aang ]]; then
	export QMLSCENE_DEVICE=softwarecontext
	export QT_OPENGL=software
fi
