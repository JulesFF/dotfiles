#!/bin/sh
# Install fd (find alternative) from the official release tarball.
# See lib/release.sh for the install dir and overrides.
set -eu

TOOL=fd
. "$(dirname "$0")/../lib/release.sh"

# Bump together: the version and the checksums of its tarballs.
VERSION=10.5.0
case "$ARCH" in
    amd64) asset=x86_64-unknown-linux-musl  sha256=761c72dc8e120d85b22292063be8a796e2eeb20eb3e4f38b8fa2343ccf3514a7 ;;
    arm64) asset=aarch64-unknown-linux-musl sha256=d76c4317f7d5dba69f8a2a15856c90c777e7f0dd4e85f0de8c76de6992c374d4 ;;
esac

install_release "$VERSION" \
    "https://github.com/sharkdp/fd/releases/download/v$VERSION/fd-v$VERSION-$asset.tar.gz" \
    "$sha256"
