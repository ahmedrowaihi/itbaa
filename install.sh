#!/bin/sh
# Itbaa installer — https://github.com/ahmedrowaihi/itbaa
#
#   curl -fsSL https://raw.githubusercontent.com/ahmedrowaihi/itbaa/main/install.sh | sh
#
# Environment overrides:
#   ITBAA_VERSION      release tag, e.g. v1.1.0    (default: latest)
#   ITBAA_INSTALL_DIR  install directory           (default: /usr/local/bin)
#   ITBAA_BIN_NAME     installed binary name       (default: itbaa)
#
# Uninstall:
#   curl -fsSL https://raw.githubusercontent.com/ahmedrowaihi/itbaa/main/install.sh | sh -s -- --uninstall

set -eu

REPO="ahmedrowaihi/itbaa"
VERSION="${ITBAA_VERSION:-latest}"
INSTALL_DIR="${ITBAA_INSTALL_DIR:-/usr/local/bin}"
BIN_NAME="${ITBAA_BIN_NAME:-itbaa}"

info() { printf '%s\n' "itbaa: $*" >&2; }
err() {
    printf '%s\n' "itbaa: error: $*" >&2
    exit 1
}
have() { command -v "$1" >/dev/null 2>&1; }

download() {
    # download <url> <dest>
    if have curl; then
        curl -fSL --proto '=https' --tlsv1.2 -o "$2" "$1"
    elif have wget; then
        wget -qO "$2" "$1"
    else
        err "need curl or wget"
    fi
}

fetch_stdout() {
    if have curl; then
        curl -fsSL --proto '=https' --tlsv1.2 "$1"
    elif have wget; then
        wget -qO - "$1"
    else
        err "need curl or wget"
    fi
}

# Run a command, escalating to sudo only if the direct attempt fails.
as_root() {
    if "$@" 2>/dev/null; then
        return 0
    elif have sudo; then
        sudo "$@"
    else
        return 1
    fi
}

detect_platform() {
    case "$(uname -s)" in
    Linux) OS=linux EXT=tar.gz ;;
    Darwin) OS=macos EXT=zip ;;
    *) err "unsupported OS: $(uname -s) (Linux and macOS only)" ;;
    esac
    case "$(uname -m)" in
    x86_64 | amd64) ARCH=x86_64 ;;
    arm64 | aarch64) ARCH=arm64 ;;
    *) err "unsupported architecture: $(uname -m)" ;;
    esac
    if [ "$OS" = "macos" ] && [ "$ARCH" != "arm64" ]; then
        err "macOS builds are Apple Silicon (arm64) only"
    fi
}

resolve_version() {
    [ "$VERSION" = "latest" ] || return 0
    VERSION=$(fetch_stdout "https://api.github.com/repos/$REPO/releases/latest" \
        | grep '"tag_name"' | head -1 | sed -E 's/.*"tag_name" *: *"([^"]+)".*/\1/')
    [ -n "$VERSION" ] || err "could not determine the latest release"
}

uninstall() {
    removed=0
    for dir in "$INSTALL_DIR" /usr/local/bin "$HOME/.local/bin"; do
        target="$dir/$BIN_NAME"
        if [ -f "$target" ]; then
            if as_root rm -f "$target"; then
                info "removed $target"
                removed=1
            else
                err "could not remove $target (try with sudo)"
            fi
        fi
    done
    [ "$removed" = 1 ] || info "$BIN_NAME not found in known locations"
    exit 0
}

install() {
    detect_platform
    resolve_version

    base="https://github.com/$REPO/releases/download/$VERSION"
    asset="itbaa-arabic-$OS-$ARCH.$EXT"

    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' EXIT

    info "downloading $VERSION for $OS-$ARCH"
    if ! download "$base/$asset" "$tmp/pkg" 2>/dev/null; then
        err "no build for $OS-$ARCH in $VERSION (looked for $asset)"
    fi

    (
        cd "$tmp"
        case "$EXT" in
        tar.gz) tar -xzf pkg ;;
        zip) have unzip || err "need unzip to extract macOS builds"; unzip -qo pkg ;;
        esac
    )

    # The archive contains a single executable named like the asset (without extension).
    bin=$(find "$tmp" -type f ! -name 'pkg' ! -name '*.commit' -perm -u+x 2>/dev/null | head -1)
    [ -n "$bin" ] || bin=$(find "$tmp" -type f -name 'itbaa-*' ! -name '*.commit' | head -1)
    [ -n "$bin" ] || err "could not find the itbaa binary inside $asset"
    chmod +x "$bin"

    dest="$INSTALL_DIR/$BIN_NAME"
    as_root mkdir -p "$INSTALL_DIR" 2>/dev/null || true
    if ! as_root cp "$bin" "$dest" 2>/dev/null; then
        INSTALL_DIR="$HOME/.local/bin"
        dest="$INSTALL_DIR/$BIN_NAME"
        mkdir -p "$INSTALL_DIR"
        cp "$bin" "$dest" || err "could not install to $dest"
        info "no write access to the requested directory; installed to $INSTALL_DIR"
    fi
    as_root chmod +x "$dest" || true

    # Clear macOS quarantine so Gatekeeper doesn't block the downloaded binary.
    [ "$OS" = "macos" ] && as_root xattr -d com.apple.quarantine "$dest" 2>/dev/null || true

    info "installed $VERSION -> $dest"
    case ":$PATH:" in
    *":$INSTALL_DIR:"*) ;;
    *) info "note: $INSTALL_DIR is not on your PATH" ;;
    esac
    if [ "$OS" = "linux" ]; then
        deps="libstdc++6 libgcc-s1"
        [ "$ARCH" = "arm64" ] && deps="$deps libatomic1"
        info "Linux runtime deps: $deps"
    fi
    "$dest" version 2>/dev/null || true
}

case "${1:-}" in
--uninstall) uninstall ;;
-h | --help)
    sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'
    exit 0
    ;;
"") install ;;
*) err "unknown argument: $1 (use --uninstall or --help)" ;;
esac
