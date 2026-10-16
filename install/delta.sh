#!/bin/sh
# Install delta (git diff pager) from the official release tarball.
# See lib/release.sh for the install dir and overrides.
set -eu

TOOL=delta
. "$(dirname "$0")/../lib/release.sh"

# Bump together: the version and the checksums of its tarballs.
VERSION=0.19.2
case "$ARCH" in
    amd64) asset=x86_64-unknown-linux-musl sha256=f1ea01ca7728ce3462debc359f39dfc7cbbc1a63224b71fefabf92042864aa1b ;;
    arm64) asset=aarch64-unknown-linux-gnu sha256=0bfce159a5cddd5feb3d6db4a616d883ff51253ce08ac7ec11cb1d208cfaab9e ;;
esac

install_release "$VERSION" \
    "https://github.com/dandavison/delta/releases/download/$VERSION/delta-$VERSION-$asset.tar.gz" \
    "$sha256"

# Make git use delta for diff, log, show and `add -p`, without
# overriding a pager that is already configured.
have git || exit 0
# git_default <key> <value>
git_default() {
    current="$(git config --global --get "$1" || true)"
    if [ -z "$current" ]; then
        git config --global "$1" "$2"
        log "set git $1 = $2"
    elif [ "$current" != "$2" ]; then
        log "git $1 is already '$current', leaving it"
    fi
}
git_default core.pager delta
git_default interactive.diffFilter 'delta --color-only'
git_default delta.navigate true
