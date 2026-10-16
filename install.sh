#!/bin/sh
# Run every installer in install/, in name order.
# Usage: ./install.sh            # all installers
#        ./install.sh glab ...   # only the named ones
set -eu

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

if [ "$#" -eq 0 ]; then
    for script in "$DOTFILES"/install/*.sh; do
        [ -e "$script" ] || continue
        sh "$script"
    done
else
    for name in "$@"; do
        script="$DOTFILES/install/$name.sh"
        [ -f "$script" ] || { echo "no installer: $name" >&2; exit 1; }
        sh "$script"
    done
fi
