#!/bin/sh
# Install ripgrep (rg, grep alternative) from the official release
# tarball. See lib/release.sh for the install dir and overrides.
set -eu

TOOL=rg
. "$(dirname "$0")/../lib/release.sh"

# Bump together: the version and the checksums of its tarballs.
VERSION=15.2.0
case "$ARCH" in
    amd64) asset=x86_64-unknown-linux-musl  sha256=33e15bcf1624b25cdd2a55813a47a2f95dbe126268203e76aa6a585d1e7b149c ;;
    arm64) asset=aarch64-unknown-linux-musl sha256=800b1e7206afe799dfb5a6901f23147cfaabe0e52210538100f61e86e1740915 ;;
esac

install_release "$VERSION" \
    "https://github.com/BurntSushi/ripgrep/releases/download/$VERSION/ripgrep-$VERSION-$asset.tar.gz" \
    "$sha256"
