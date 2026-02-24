#!/usr/bin/env bash
#
# Xournal++ Build & Install Script (Fedora)
# ------------------------------------------
# Usage:
#   ./install.sh          # Full build + install to /usr/local
#   ./install.sh --clean  # Wipe build dir first, then build + install
#   ./install.sh --deps   # Only install dependencies
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"
INSTALL_PREFIX="/usr/local"
JOBS="$(nproc)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${CYAN}[*]${NC} $*"; }
ok()   { echo -e "${GREEN}[✓]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
err()  { echo -e "${RED}[✗]${NC} $*" >&2; }

# ---------------------------------------------------------------------------
# 1. Dependencies
# ---------------------------------------------------------------------------
install_deps() {
    log "Installing Fedora build dependencies..."
    sudo dnf install -y \
        gcc-c++ cmake \
        gtk3-devel libxml2-devel \
        portaudio-devel libsndfile-devel \
        poppler-glib-devel \
        texlive-scheme-basic texlive-dvipng \
        gettext libzip-devel \
        librsvg2-devel lua-devel \
        gtksourceview4-devel \
        help2man qpdf-devel
    ok "Dependencies installed"
}

# ---------------------------------------------------------------------------
# 2. Configure
# ---------------------------------------------------------------------------
configure() {
    log "Configuring CMake (install prefix: ${INSTALL_PREFIX})..."
    mkdir -p "${BUILD_DIR}"
    cd "${BUILD_DIR}"

    cmake "${SCRIPT_DIR}" \
        -DCMAKE_INSTALL_PREFIX="${INSTALL_PREFIX}" \
        -DCMAKE_BUILD_TYPE=RelWithDebInfo \
        -DENABLE_CPPTRACE=OFF  # Disabled: GCC 15 lacks C++20 module support

    ok "CMake configured"
}

# ---------------------------------------------------------------------------
# 3. Build
# ---------------------------------------------------------------------------
build() {
    log "Building with ${JOBS} parallel jobs..."
    cd "${BUILD_DIR}"

    # cmake --build gracefully handles parallel linking issues better than raw make
    cmake --build . -j"${JOBS}"

    ok "Build complete"
}

# ---------------------------------------------------------------------------
# 4. Install
# ---------------------------------------------------------------------------
install_app() {
    log "Installing to ${INSTALL_PREFIX} (requires sudo)..."
    cd "${BUILD_DIR}"
    sudo cmake --install .
    ok "Installed! Run with: xournalpp"
}

# ---------------------------------------------------------------------------
# 5. Verify
# ---------------------------------------------------------------------------
verify() {
    if command -v xournalpp &>/dev/null; then
        echo ""
        ok "xournalpp $(xournalpp --version 2>&1 | head -1)"
        log "Binary: $(which xournalpp)"
    else
        warn "xournalpp not found in PATH — you may need to add ${INSTALL_PREFIX}/bin to your PATH"
    fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
    local clean=false
    local deps_only=false

    for arg in "$@"; do
        case "${arg}" in
            --clean) clean=true ;;
            --deps)  deps_only=true ;;
            --help|-h)
                echo "Usage: $0 [--clean] [--deps]"
                echo "  --clean   Remove build directory before building"
                echo "  --deps    Only install dependencies, then exit"
                exit 0
                ;;
            *) err "Unknown option: ${arg}"; exit 1 ;;
        esac
    done

    echo ""
    echo "╔══════════════════════════════════════════╗"
    echo "║   Xournal++ Build & Install (Fedora)    ║"
    echo "╚══════════════════════════════════════════╝"
    echo ""

    install_deps

    if ${deps_only}; then
        ok "Dependencies installed. Exiting (--deps mode)."
        exit 0
    fi

    if ${clean}; then
        warn "Cleaning build directory..."
        rm -rf "${BUILD_DIR}"
    fi

    configure
    build
    install_app
    verify
}

main "$@"
