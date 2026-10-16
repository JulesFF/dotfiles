#!/bin/sh
# Install tree from source. Upstream ships no binaries, so this fetches
# a pinned commit (git checks the content against the hash) and builds
# it. See lib/release.sh for the install dir and overrides.
#
# Needs git, make and a C compiler on top of lib/release.sh's needs.
set -eu

TOOL=tree
. "$(dirname "$0")/../lib/release.sh"

# Bump together: the version and its commit.
VERSION=2.3.2
COMMIT=1a41b51bea1cec4109eb9f726370449b384b4576

installed "$VERSION" && exit 0

for cmd in git make cc; do
    have "$cmd" || die "need $cmd"
done

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT INT TERM

log "building tree $VERSION"
git -C "$tmp" init -q
git -C "$tmp" fetch -q --depth 1 https://gitlab.com/OldManProgrammer/unix-tree.git "$COMMIT"
git -C "$tmp" checkout -q --detach FETCH_HEAD
make -s -C "$tmp" >/dev/null

install_bin "$tmp/tree" "$VERSION"
