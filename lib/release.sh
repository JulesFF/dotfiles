# Shared by the single-binary installers in install/. Source it after
# setting TOOL; it sets ARCH (amd64 or arm64) and BIN_DIR, and defines
# install_release.
#
# Installs to /usr/local/bin when root or passwordless sudo is
# available, otherwise to ~/.local/bin. Override with BIN_DIR=/some/dir.
#
# Needs only sh, tar, uname, curl or wget, and sha256sum or shasum.

log() { printf '[%s] %s\n' "$TOOL" "$*"; }
die() { printf '[%s] error: %s\n' "$TOOL" "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

[ "$(uname -s)" = "Linux" ] || die "unsupported OS: $(uname -s)"

case "$(uname -m)" in
    x86_64 | amd64)  ARCH=amd64 ;;
    aarch64 | arm64) ARCH=arm64 ;;
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

# installed <version>
# True when $TOOL in $BIN_DIR or on PATH reports <version>.
installed() {
    for existing in "$BIN_DIR/$TOOL" "$(command -v "$TOOL" || true)"; do
        [ -x "$existing" ] || continue
        if "$existing" --version 2>/dev/null | grep -qF "$1"; then
            log "$TOOL $1 already installed at $existing"
            return 0
        fi
    done
    return 1
}

# install_bin <file> <version>
# Installs <file> as $BIN_DIR/$TOOL.
install_bin() {
    $SUDO mkdir -p "$BIN_DIR"
    # cp + chmod rather than `install`, which busybox may lack.
    $SUDO cp "$1" "$BIN_DIR/$TOOL.new"
    $SUDO chmod 0755 "$BIN_DIR/$TOOL.new"
    $SUDO mv -f "$BIN_DIR/$TOOL.new" "$BIN_DIR/$TOOL"

    log "installed $TOOL $2 to $BIN_DIR/$TOOL"
    check_path
}

check_path() {
    case ":$PATH:" in
        *":$BIN_DIR:"*) ;;
        *) log "note: $BIN_DIR is not on your PATH" ;;
    esac
}

# install_release <version> <url> <sha256>
# Downloads <url>, checks it against <sha256>, and installs the binary
# named $TOOL from it to $BIN_DIR. <url> is a .tar.gz holding the
# binary anywhere inside, or the binary itself. Skips the download when
# `$TOOL --version` already mentions <version>.
install_release() {
    installed "$1" && return

    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT INT TERM

    log "downloading ${2##*/}"
    fetch "$2" "$tmp/download"
    [ "$(sha256 "$tmp/download")" = "$3" ] || die "checksum mismatch for ${2##*/}"

    case "$2" in
        *.tar.gz)
            mkdir "$tmp/x"
            tar -xzf "$tmp/download" -C "$tmp/x"
            bin="$(find "$tmp/x" -type f -name "$TOOL" | head -n1)"
            [ -n "$bin" ] || die "no $TOOL binary in ${2##*/}"
            ;;
        *) bin="$tmp/download" ;;
    esac

    install_bin "$bin" "$1"
}
