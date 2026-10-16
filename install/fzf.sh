#!/bin/sh
# Install fzf (fuzzy finder) from the official release tarball.
# See lib/release.sh for the install dir and overrides.
set -eu

TOOL=fzf
. "$(dirname "$0")/../lib/release.sh"

# Bump together: the version and the checksums of its tarballs.
VERSION=0.74.4
case "$ARCH" in
    amd64) asset=amd64 sha256=05e6813a337cc722c3ed07e54a764b75cc5d671e2e60459db0ba696ee5fa7504 ;;
    arm64) asset=arm64 sha256=5d673b849f494f0d64ec471d8640b153ca8849e3846a31da17abdcfce8df6b46 ;;
esac

install_release "$VERSION" \
    "https://github.com/junegunn/fzf/releases/download/v$VERSION/fzf-$VERSION-linux_$asset.tar.gz" \
    "$sha256"
