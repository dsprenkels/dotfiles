#!/bin/sh

set -eu

readonly AUTORCDIR="$(realpath "$(dirname "$0")/_home")"

if [ -z "${HOST+x}" ]
then
    echo >&2 "\$HOST variable is not set"
    exit 2
fi

if [ "${HOST}" = "aang" ]; then
    rm --verbose -rf "$HOME/.liquidprompt"
    cp --verbose -r "$AUTORCDIR/." "$HOME"
else
    ssh "$HOST" -- rm --verbose -rf "\$HOME/.liquidprompt"
    rsync -ravuh "$AUTORCDIR/." "$HOST:"
fi
