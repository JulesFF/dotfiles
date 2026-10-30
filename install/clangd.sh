#!/bin/sh
# Install clangd (C and C++ language server) from the official release
# zip. clangd needs the clang headers shipped beside it, so the whole
# release goes into lib/clangd; see install_dir in lib/release.sh.
# Upstream builds only for x86_64; elsewhere this is skipped with a
# note.
#
# Needs unzip on top of lib/release.sh's needs.
set -eu

TOOL=clangd
. "$(dirname "$0")/../lib/release.sh"

# Bump together: the version and the checksum of its zip.
VERSION=23.1.0
SHA256=e53b1a96196095faedb7642cf64964f7fb9ad4a0c1f00dd2c172a3d9dcbafdfd

if [ "$ARCH" != amd64 ]; then
    log "skipped: no upstream build for $ARCH; install your distribution's clangd"
    exit 0
fi
have unzip || die "need unzip"

installed "$VERSION" && exit 0

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT INT TERM

name="clangd-linux-$VERSION.zip"
log "downloading $name"
fetch "https://github.com/clangd/clangd/releases/download/$VERSION/$name" "$tmp/download"
[ "$(sha256 "$tmp/download")" = "$SHA256" ] || die "checksum mismatch for $name"

unzip -q "$tmp/download" -d "$tmp/x"
install_dir "$tmp/x/clangd_$VERSION" "$VERSION"
