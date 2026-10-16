#!/bin/sh
# Install zoxide (smarter cd) from the official release tarball.
# See lib/release.sh for the install dir and overrides.
set -eu

TOOL=zoxide
. "$(dirname "$0")/../lib/release.sh"

# Bump together: the version and the checksums of its tarballs.
VERSION=0.10.0
case "$ARCH" in
    amd64) asset=x86_64-unknown-linux-musl  sha256=2d93385b99f3e82cf2701609a1bffcad863fbeb75aa3fe7eb6be4d29be68b1ae ;;
    arm64) asset=aarch64-unknown-linux-musl sha256=f1f16c5d6298d63dee467eedea1cdcd8490e43e493bea43acd416dc9033ef641 ;;
esac

install_release "$VERSION" \
    "https://github.com/ajeetdsouza/zoxide/releases/download/v$VERSION/zoxide-$VERSION-$asset.tar.gz" \
    "$sha256"
