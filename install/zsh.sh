#!/bin/sh
# Install zsh plugins, and make ~/.zshrc source
# zsh/dotfiles.zsh, which loads them.
#
# Each repo is fetched at a pinned commit into ~/.local/share/zsh;
# git checks the content against the commit hash. Needs sh and git.
set -eu

DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"
PLUGIN_DIR="$HOME/.local/share/zsh"
ZSHRC="$HOME/.zshrc"

log() { printf '[zsh] %s\n' "$*"; }
die() { printf '[zsh] error: %s\n' "$*" >&2; exit 1; }

command -v git >/dev/null 2>&1 || die "need git"

# pin <name> <repo url> <commit>
pin() {
    dir="$PLUGIN_DIR/$1"
    if [ "$(git -C "$dir" rev-parse HEAD 2>/dev/null)" = "$3" ]; then
        log "$1 already at ${3%"${3#???????}"}"
        return
    fi
    log "fetching $1 at ${3%"${3#???????}"}"
    rm -rf "$dir"
    mkdir -p "$dir"
    git -C "$dir" init -q
    git -C "$dir" fetch -q --depth 1 "$2" "$3"
    git -C "$dir" checkout -q --detach FETCH_HEAD
}

pin zsh-autosuggestions https://github.com/zsh-users/zsh-autosuggestions.git \
    e52ee8ca55bcc56a17c828767a3f98f22a68d4eb  # v0.7.1
pin zsh-syntax-highlighting https://github.com/zsh-users/zsh-syntax-highlighting.git \
    db085e4661f6aafd24e5acb5b2e17e4dd5dddf3e  # 0.8.0
pin zsh-completions https://github.com/zsh-users/zsh-completions.git \
    28c5bdcaf81bb89e56d0df8267d822c3b8aed9e0  # 0.36.0

line="source \"$DOTFILES/zsh/dotfiles.zsh\""
if [ -f "$ZSHRC" ] && grep -qxF "$line" "$ZSHRC"; then
    log "$ZSHRC already sources zsh/dotfiles.zsh"
else
    printf '\n%s\n' "$line" >> "$ZSHRC"
    log "added to $ZSHRC: $line"
fi

log "done; open a new shell or run: source $ZSHRC"
