#!/bin/sh
# Install gopls (Go language server) with `go install` at a pinned
# version; the Go checksum database verifies the module. Skipped, with
# a note, when Go is not installed. See lib/release.sh for the install
# dir and overrides.
#
# gopls often needs a newer Go to build than the one installed, so
# GOTOOLCHAIN=auto lets go fetch that toolchain (checksum-verified the
# same way) for this build only.
set -eu

TOOL=gopls
VERSION_ARGS=version
. "$(dirname "$0")/../lib/release.sh"

VERSION=0.24.0

if ! have go; then
    log "skipped: go is not installed"
    exit 0
fi

installed "v$VERSION" && exit 0

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT INT TERM

log "building gopls $VERSION"
GOBIN="$tmp" GOTOOLCHAIN=auto GOFLAGS= \
    GOPROXY=https://proxy.golang.org GOSUMDB=sum.golang.org \
    go install "golang.org/x/tools/gopls@v$VERSION" 2>"$tmp/log" ||
    { cat "$tmp/log" >&2; die "go install failed"; }
install_bin "$tmp/gopls" "$VERSION"
