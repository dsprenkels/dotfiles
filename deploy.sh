#!/bin/sh

set -eu

readonly AUTORCDIR="$(realpath "$(dirname "$0")/_home")"

if [ -z "${HOST+x}" ]
then
    echo >&2 "\$HOST variable is not set"
    exit 2
fi

if [ "${1+x}" != "--force" ] && [ "$(git status --porcelain=v1 2>/dev/null | grep -vc '_drafts/')" -ne 0 ]
then
    git status
    echo
    echo >&2 "There are unstaged changes! Refusing to deploy."
    echo >&2 "Please stash or discard the changes and try again."
    exit 1
fi

if [ "${HOST}" = "local" ]; then
    rm --verbose -rf "$HOME/.liquidprompt"
    cp --verbose -r "$AUTORCDIR/." "$HOME"
else
    ssh "$HOST" -- rm --verbose -rf "\$HOME/.liquidprompt"
    rsync -ravuh "$AUTORCDIR/." "$HOST:"
fi
