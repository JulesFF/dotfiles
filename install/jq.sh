#!/bin/sh
# Install jq (JSON processor) from the official release binary.
# See lib/release.sh for the install dir and overrides.
set -eu

TOOL=jq
. "$(dirname "$0")/../lib/release.sh"

# Bump together: the version and the checksums of its binarys.
VERSION=1.8.2
case "$ARCH" in
    amd64) asset=amd64 sha256=b1c22172dd303f3be49e935aa56aa48a8b7a46e0bc838b4997d3bb451495870f ;;
    arm64) asset=arm64 sha256=8b85c817833814ddca00a144c33705546355afccf0cf39b188f3cdb48b852309 ;;
esac

install_release "$VERSION" \
    "https://github.com/jqlang/jq/releases/download/jq-$VERSION/jq-linux-$asset" \
    "$sha256"
