#!/bin/sh
# Install bat (cat with syntax highlighting) from the official release tarball.
# See lib/release.sh for the install dir and overrides.
set -eu

TOOL=bat
. "$(dirname "$0")/../lib/release.sh"

# Bump together: the version and the checksums of its tarballs.
VERSION=0.26.1
case "$ARCH" in
    amd64) asset=x86_64-unknown-linux-musl  sha256=0dcd8ac79732c0d5b136f11f4ee00e581440e16a44eab5b3105b611bbf2cf191 ;;
    arm64) asset=aarch64-unknown-linux-musl sha256=6369242c584065f195fb20cb36fbd7cb63ae690605bbe89868a7596b596c2c23 ;;
esac

install_release "$VERSION" \
    "https://github.com/sharkdp/bat/releases/download/v$VERSION/bat-v$VERSION-$asset.tar.gz" \
    "$sha256"
