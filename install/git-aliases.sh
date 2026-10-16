#!/bin/sh
# Install the oh-my-zsh git aliases (gst, gco, gcmsg, gp, ...) without
# oh-my-zsh itself: fetch lib/git.zsh and plugins/git/git.plugin.zsh at
# a pinned commit into ~/.local/share/zsh/omz-git, where
# zsh/dotfiles.zsh sources them (see install/zsh.sh).
#
# Needs only sh, curl or wget, and sha256sum or shasum.
set -eu

# Bump together: the commit and the checksums of the files it serves.
OMZ_COMMIT=964ddf789b022b6958b27d02d7fa54f552de21e9
GIT_ZSH_SHA256=b135c2cae03645ed07bbefa87f03d6d1c8c6893d654b5846f8349b8ccdcfb1dc
GIT_PLUGIN_SHA256=e64568613b7859f5c4052373dfb4bf8a702f83401001294aa9b2309ab0b013d1

OMZ_DIR="$HOME/.local/share/zsh/omz-git"

log() { printf '[git-aliases] %s\n' "$*"; }
die() { printf '[git-aliases] error: %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

if have curl; then
    fetch() { curl -fsSL -o "$2" "$1"; }
elif have wget; then
    fetch() { wget -q -O "$2" "$1"; }
else
    die "need curl or wget"
fi

if have sha256sum; then
    sha256() { sha256sum "$1" | awk '{print $1}'; }
elif have shasum; then
    sha256() { shasum -a 256 "$1" | awk '{print $1}'; }
else
    die "need sha256sum or shasum"
fi

base="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/$OMZ_COMMIT"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT INT TERM

# install <repo path> <local name> <sha256>
install_file() {
    if [ -f "$OMZ_DIR/$2" ] && [ "$(sha256 "$OMZ_DIR/$2")" = "$3" ]; then
        log "$2 already up to date"
        return
    fi
    log "downloading $1"
    fetch "$base/$1" "$tmp/$2"
    [ "$(sha256 "$tmp/$2")" = "$3" ] || die "checksum mismatch for $1"
    mkdir -p "$OMZ_DIR"
    mv -f "$tmp/$2" "$OMZ_DIR/$2"
}

install_file lib/git.zsh git.zsh "$GIT_ZSH_SHA256"
install_file plugins/git/git.plugin.zsh git.plugin.zsh "$GIT_PLUGIN_SHA256"

log "installed to $OMZ_DIR"
