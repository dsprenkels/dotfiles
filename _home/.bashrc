#!/bin/bash

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

# interactively choose git branches to delete
function git-branchgc() {
	local branches

    if ! command -v gum &> /dev/null; then
        echo "gum could not be found, please install it first."
        return 1
    fi

    if ! git rev-parse --is-inside-work-tree &> /dev/null; then
        echo "Not inside a git repository."
        return 1
    fi
    readarray -t branches < <(git branch --format='%(refname:short)' | grep -v 'main\|master\|dev\|development\|staging\|production' | sort)
	readarray -t branches < <(gum choose --no-limit --selected-prefix="✗ " "${branches[@]}")
	[ ${#branches[@]} -eq 0 ] && echo "No branches selected for deletion." && return 0
	printf "The following branches will be deleted:\n\n"
	printf '  • %s\n' "${branches[@]}"
	printf "\n"
	if gum confirm "Are you sure you want to delete these branches?"; then
		git branch -D "${branches[@]}"
		return $?
	fi
	return 1
}

# interactive git switch branch
function git-sb() {
    local branches selected_branch detach_branches

    if ! command -v gum &> /dev/null; then
        echo "gum could not be found, please install it first."
        return 1
    fi

    if ! git rev-parse --is-inside-work-tree &> /dev/null; then
        echo "Not inside a git repository."
        return 1
    fi
    readarray -t branches < <(git for-each-ref --format='%(color:reset)%(refname:short)' refs/heads/ | sort)
	detach_branches=()
	for remote in $(git remote); do
		main_branch=$(git remote show "$remote" | awk '/HEAD branch/ {print $NF}')
		if [ -n "$main_branch" ]; then
			branches=("$remote/$main_branch" "${branches[@]}")
			detach_branches+=("$remote/$main_branch")
		fi
	done
    selected_branch=$(gum choose "${branches[@]}")
    if [ -n "$selected_branch" ]; then
		if [[ " ${detach_branches[*]} " == *" $selected_branch "* ]]; then
			git fetch "${selected_branch%%/*}" "${selected_branch##*/}"
			git switch --detach "$selected_branch"
			return $?
		fi
        git switch "$selected_branch"
		return $?
    else
        echo "No branch selected."
		return 1
    fi
}

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

# END OF NON-INTERACTIVE SECTION, START OF INTERACTIVE SECTION

# If not running interactively, don't go any further
[ -z "$PS1" ] && return

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=100000
HISTFILESIZE=200000
HISTCONTROL=ignorespace

# enable color support of ls and also add handy aliases
alias ls='ls --color=auto'
alias ll='ls --color=always -lh | less --RAW-CONTROL-CHARS --quit-if-one-screen'
alias lt='ls --color=always -lth | less --RAW-CONTROL-CHARS --quit-if-one-screen'
alias dir='dir --color=auto'
alias vdir='vdir --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# liquidprompt settings
# shellcheck source=.liquidprompt
# shellcheck disable=SC1091
[[ $- = *i* ]] && source ~/.liquidprompt

# Explicitly enable bash completion
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

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

# add devkitpro tools to path
if [[ $(hostnamectl hostname) == suyin-arch ]]; then
	PATH="$PATH:/opt/devkitpro/devkitARM/bin:/opt/devkitpro/tools/bin"
fi

# just set RUST_BACKTRACE=1 by default
export RUST_BACKTRACE=1

# set an ssh-agent on aang
if [[ $(hostnamectl hostname) == aang ]]; then
	if [ -z "$SSH_CONNECTION" ]; then
		eval "$(keychain --ssh-allow-gpg --eval --quick --quiet)"
	fi
fi

# disable gpu on aang (where muffin does not work well with intel xe)
if [[ $(hostnamectl hostname) == aang ]]; then
	export QMLSCENE_DEVICE=softwarecontext
	export QT_OPENGL=software
fi

# add dprint to path if working on work laptop
if [[ $(hostnamectl hostname) == amber-ThinkPad-P14s-Gen-6-AMD ]]; then
	export DPRINT_INSTALL="/home/amber/.dprint"
	export PATH="$DPRINT_INSTALL/bin:$PATH"
fi

# if bin tool is installed, then use .bin as the directory to store bin binaries
if [[ $(which bin) ]]; then
	export PATH="$HOME/.bin:$PATH"
fi
