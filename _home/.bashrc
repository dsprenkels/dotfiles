#!/bin/bash

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
    local branches selected_branch detach_branches create_new_branch
    create_new_branch="[create branch] ✨"

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
        branches=("$remote/HEAD" "${branches[@]}")
        detach_branches+=("$remote/HEAD")
    done
    branches+=("$create_new_branch")
    selected_branch=$(gum choose "${branches[@]}")
    if [ -n "$selected_branch" ]; then
        if [ "$selected_branch" = "$create_new_branch" ]; then
            local new_branch_name
            new_branch_name=$(gum input --prompt="new branch name: " --placeholder="branch-name")
            if [ -z "$new_branch_name" ]; then
                echo -e "\e[1;31merror: branch name empty\e[0m"
                return 1
            fi
            git fetch upstream main ||
                echo -e "\e[1;33mwarning: failed to fetch from upstream\e[0m"
            git switch -c "$new_branch_name" upstream/main
            return $?
        fi
        if [[ " ${detach_branches[*]} " == *" $selected_branch "* ]]; then
            git fetch "${selected_branch%%/*}" "${selected_branch##*/}" ||
                echo -e "\e[1;33mwarning: failed to fetch from remote ${selected_branch%%/*}\e[0m"
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
if [[ $- = *i* && $(hostnamectl hostname) =~ ^(aang|suyin-arch)$ ]]; then
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

if [[ $- = *i* ]] && [[ $(hostnamectl hostname) == amber-ThinkPad-P14s-Gen-6-AMD ]] && [[ $(pwd) =~ ^/home/amber/git ]] && [ -d "$HOME/git/scratch" ]; then
    # Make a daily backup of all files up to 4M
    (
        backup_dir="$HOME/git/backup/$(date +"%Y-%m-%d")"
        if [ ! -d "$backup_dir" ]; then
            mkdir -p "$backup_dir"
            find "$HOME/git/scratch" -maxdepth 1 -type f -size -4M -exec cp --reflink=auto --archive {} "$backup_dir/" \;
            backup_size=$(du -sh "$backup_dir" | cut -f1)
            echo >&2 -e "\e[0;34mcreated backup of scratch files at $backup_dir ($backup_size)\e[0m"
        fi
    )
fi

if [[ $- = *i* ]]; then
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
    alias gs='git status'
fi

# liquidprompt settings
# shellcheck source=.liquidprompt
# shellcheck disable=SC1091
[[ $- = *i* ]] && source ~/.liquidprompt

# Explicitly enable bash completion
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        source /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
        source /etc/bash_completion
    fi
fi

# set gopath
if [[ $(hostnamectl hostname) =~ ^(aang|suyin-arch)$ ]]; then
    export GOPATH="$HOME/.cache/go"
    export PATH="$PATH:/usr/lib/go-1.6/bin:$GOPATH/bin"
fi

# set ruby path
if [[ $(hostnamectl hostname) =~ ^(aang|suyin-arch)$ ]]; then
    export PATH="$PATH:$HOME/.gem/ruby/3.0.0/bin"
fi

# add cargo to path if installed
if which cargo >/dev/null 2>/dev/null; then
    export PATH="$HOME/.cargo/bin:$PATH"
fi

# set additional local search path
export PATH="$HOME/.local/bin:$PATH"

# set password store directory
if [[ $(hostnamectl hostname) = aang ]]; then
    export PASSWORD_STORE_DIR=~/Documents/Vault/password-store
fi

# use keychain if we're on aang/suyin-arch and we are logged in via SSH
if [[ $(hostnamectl hostname) =~ ^(aang|S)$ ]]; then
    if [ -n "$SSH_CONNECTION" ]; then
        eval "$(keychain --eval --quiet)"
    fi
fi

# override ripgrep with settings that fit interactive use
if [[ $- = *i* ]] && which rg >/dev/null 2>/dev/null; then
    RIPGREP="$(which rg)"
    function rg() {
        "$RIPGREP" --pretty "$@" | less -RFX
    }
fi

# just set RUST_BACKTRACE=1 by default
export RUST_BACKTRACE=1

# set an ssh-agent on aang
if [[ $- = *i* && $(hostnamectl hostname) == aang ]]; then
    if [ -z "$SSH_CONNECTION" ]; then
        eval "$(keychain --ssh-allow-gpg --eval --quick --quiet)"
    fi
fi

# disable gpu on aang (where muffin does not work well with intel xe)
if [[ $- = *i* &&  $(hostnamectl hostname) == aang ]]; then
    export QMLSCENE_DEVICE=softwarecontext
    export QT_OPENGL=software
fi

# add dprint to path if working on work laptop
if [[ $(hostnamectl hostname) == amber-ThinkPad-P14s-Gen-6-AMD ]]; then
    export DPRINT_INSTALL="/home/amber/.dprint"
    export PATH="$DPRINT_INSTALL/bin:$PATH"
fi

# initialize z as zoxide (if present on this machine)
if [[ $- = *i* ]] && type zoxide >/dev/null 2>/dev/null; then
    eval "$(zoxide init bash)"

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
fi

if [[ $- = *i* ]] && [[ $(hostnamectl hostname) == amber-ThinkPad-P14s-Gen-6-AMD ]]; then
    function polars-test-new() {
        local template="$HOME/git/scratch/test-template.py"
        local test_name

        test_name="$(gum input --prompt="Test name: " --placeholder="test-example.py" --value="test-")"

        if [[ ! $test_name =~ ^test-.*\.py$ ]]; then
            echo >&2 -e "\e[1;31merror: test name must match pattern test-*.py\e[0m"
            return 1
        fi
        local script_name="$HOME/git/scratch/$test_name"
        if [ -f "$script_name" ]; then
            echo >&2 -e "\e[1;31merror: file $script_name already exists\e[0m"
            return 1
        fi

        cp --reflink=auto "$template" "$HOME/git/scratch/$test_name" && \
        echo >&2 -e "\e[1;32mcreated new test file at $script_name\e[0m"
    }

    function polars-test() {
        local script_name="$HOME/git/scratch/test.py"
        local args=()
        local found_separator=false

        for arg in "$@"; do
            if [ "$arg" = "--new" ]; then
                polars-test-new
                return $?
            fi
        done

        if [ $# -eq 0 ]; then
            echo >&2 -e "\e[1;34mrunning script: python3 \"$script_name\" ${args[*]}\e[0m"
            python3 "$script_name"
            return $?
        fi

        # Parse arguments to find separator
        for arg in "$@"; do
            if [ "$arg" = "--" ]; then
                found_separator=true
                continue
            fi
            if [ "$found_separator" = true ]; then
                args+=("$arg")
            else
                script_name="$HOME/git/scratch/test-$arg.py"
            fi
        done

        if [ ! -f "$script_name" ]; then
            echo >&2 -e "\e[1;31merror: script $script_name not found\e[0m"
            return 1
        fi

        echo >&2 -e "\e[1;34mrunning script: python3 \"$script_name\" ${args[*]}\e[0m"
        python3 "$script_name" "${args[@]}"
    }

    alias pt='polars-test'

    function _polars_test_complete() {
        local cur="${COMP_WORDS[COMP_CWORD]}"
        local prev="${COMP_WORDS[COMP_CWORD-1]}"

        if [ "$prev" = "polars-test" ] || [ "$prev" = "pt" ]; then
            local scripts
            mapfile -t scripts < <(find "$HOME/git/scratch" -name 'test-*.py' -printf '%f\n' 2>/dev/null | sed 's/^test-//; s/\.py$//')
            mapfile -t COMPREPLY < <(compgen -W "--new ${scripts[*]}" -- "$cur")
        fi
    }

    complete -F _polars_test_complete polars-test pt
fi
