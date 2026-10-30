#!/bin/sh
# Install Neovim from the official release tarball, fetch the plugins
# nvim/init.lua uses at pinned commits, and link ~/.config/nvim to
# nvim/ in this repo.
#
# Neovim needs its runtime files next to the binary, so the tarball is
# unpacked whole into lib/nvim beside $BIN_DIR (~/.local/lib/nvim or
# /usr/local/lib/nvim) and $BIN_DIR/nvim links into it. Plugins go in
# ~/.local/share/nvim/site/pack/dotfiles/start, which Neovim loads on
# start without a plugin manager. An existing ~/.config/nvim is moved
# to ~/.config/nvim.bak-<date>.
#
# Needs git on top of lib/release.sh's needs.
set -eu

TOOL=nvim
. "$(dirname "$0")/../lib/release.sh"

DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"
PACK_DIR="$HOME/.local/share/nvim/site/pack/dotfiles/start"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"

have git || die "need git"

# Bump together: the version and the checksums of its tarballs.
VERSION=0.12.6
case "$ARCH" in
    amd64) asset=x86_64 sha256=474430d53e6264f6d6dd18db42d6dc9df3a1b56ca9e88a325bbf860e1a811d87 ;;
    arm64) asset=arm64 sha256=8f1f64a0bdb97247034038c3823c6cbad5bdf9ecd5751b85494b71c3ee04c815 ;;
esac

install_nvim() {
    installed "$VERSION" && return

    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT INT TERM

    name="nvim-linux-$asset.tar.gz"
    log "downloading $name"
    fetch "https://github.com/neovim/neovim/releases/download/v$VERSION/$name" "$tmp/download"
    [ "$(sha256 "$tmp/download")" = "$sha256" ] || die "checksum mismatch for $name"

    mkdir "$tmp/x"
    tar -xzf "$tmp/download" -C "$tmp/x"
    install_dir "$tmp/x/nvim-linux-$asset" "$VERSION"
}

# pin <name> <repo url> <commit>
pin() {
    dir="$PACK_DIR/$1"
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

install_nvim

pin fzf-lua https://github.com/ibhagwan/fzf-lua.git \
    3868dcc78d2c2766c9510ab18b6d3815071b389e  # main, 2026-10-14
pin nvim-tree https://github.com/nvim-tree/nvim-tree.lua.git \
    531b807b8f0d6f75016a0ee1e0cd5ce2086e9d95  # v1.18.0

if [ "$(readlink "$CONFIG_DIR" 2>/dev/null)" = "$DOTFILES/nvim" ]; then
    log "$CONFIG_DIR already links to nvim/"
else
    if [ -e "$CONFIG_DIR" ] || [ -L "$CONFIG_DIR" ]; then
        backup="$CONFIG_DIR.bak-$(date +%Y%m%d-%H%M%S)"
        mv "$CONFIG_DIR" "$backup"
        log "moved existing $CONFIG_DIR to $backup"
    fi
    mkdir -p "$(dirname "$CONFIG_DIR")"
    ln -s "$DOTFILES/nvim" "$CONFIG_DIR"
    log "linked $CONFIG_DIR to $DOTFILES/nvim"
fi

log "done; run: nvim"
