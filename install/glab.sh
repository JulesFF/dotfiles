#!/bin/sh
# Install glab (GitLab CLI) from the official release tarball.
#
# Distro-agnostic: needs only sh, tar, uname, curl or wget, and
# sha256sum or shasum. Installs to /usr/local/bin when root or
# passwordless sudo is available, otherwise to ~/.local/bin.
#
# Overrides:
#   GLAB_VERSION=1.119.0   version to install
#   BIN_DIR=/some/dir      install directory
set -eu

GLAB_VERSION="${GLAB_VERSION:-1.119.0}"

log() { printf '[glab] %s\n' "$*"; }
die() { printf '[glab] error: %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

[ "$(uname -s)" = "Linux" ] || die "unsupported OS: $(uname -s)"

case "$(uname -m)" in
    x86_64 | amd64)        arch=amd64 ;;
    aarch64 | arm64)       arch=arm64 ;;
    armv6* | armv7* | arm) arch=armv6 ;;
    i386 | i486 | i586 | i686) arch=386 ;;
    ppc64le)               arch=ppc64le ;;
    s390x)                 arch=s390x ;;
    *) die "unsupported architecture: $(uname -m)" ;;
esac

# Choose the install dir and whether writing to it needs sudo.
SUDO=""
if [ -z "${BIN_DIR:-}" ]; then
    if [ "$(id -u)" -eq 0 ]; then
        BIN_DIR=/usr/local/bin
    elif have sudo && sudo -n true 2>/dev/null; then
        BIN_DIR=/usr/local/bin
        SUDO=sudo
    else
        BIN_DIR="$HOME/.local/bin"
    fi
elif [ ! -w "$BIN_DIR" ] && [ "$(id -u)" -ne 0 ] && have sudo; then
    SUDO=sudo
fi

# Skip if the requested version is already installed, either in
# BIN_DIR (which may not be on PATH yet) or anywhere on PATH.
version_of() { "$1" --version 2>/dev/null | awk '{print $2; exit}'; }
for existing in "$BIN_DIR/glab" "$(command -v glab || true)"; do
    [ -x "$existing" ] || continue
    if [ "$(version_of "$existing")" = "$GLAB_VERSION" ]; then
        log "glab $GLAB_VERSION already installed at $existing"
        exit 0
    fi
done

if have curl; then
    fetch() { curl -fsSL -o "$2" "$1"; }
elif have wget; then
    fetch() { wget -q -O "$2" "$1"; }
else
    die "need curl or wget"
fi

if have sha256sum; then
    sha256() { sha256sum "$1" | awk '{print $1}'; }
elif have shasum; then
    sha256() { shasum -a 256 "$1" | awk '{print $1}'; }
else
    die "need sha256sum or shasum"
fi

tarball="glab_${GLAB_VERSION}_linux_${arch}.tar.gz"
base="https://gitlab.com/gitlab-org/cli/-/releases/v${GLAB_VERSION}/downloads"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT INT TERM

log "downloading $tarball"
fetch "$base/$tarball" "$tmp/$tarball"
fetch "$base/checksums.txt" "$tmp/checksums.txt"

expected="$(awk -v f="$tarball" '$2 == f {print $1}' "$tmp/checksums.txt")"
[ -n "$expected" ] || die "no checksum listed for $tarball"
actual="$(sha256 "$tmp/$tarball")"
[ "$expected" = "$actual" ] || die "checksum mismatch for $tarball"

tar -xzf "$tmp/$tarball" -C "$tmp" bin/glab

$SUDO mkdir -p "$BIN_DIR"
# cp + chmod rather than `install`, which busybox may lack.
$SUDO cp "$tmp/bin/glab" "$BIN_DIR/glab.new"
$SUDO chmod 0755 "$BIN_DIR/glab.new"
$SUDO mv -f "$BIN_DIR/glab.new" "$BIN_DIR/glab"

log "installed $("$BIN_DIR/glab" --version | head -n1) to $BIN_DIR/glab"

case ":$PATH:" in
    *":$BIN_DIR:"*) ;;
    *) log "note: $BIN_DIR is not on your PATH" ;;
esac
