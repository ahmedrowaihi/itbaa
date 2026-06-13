#!/bin/bash
# Itbaa (اطبع) Build Script
# Copyright (c) 2025, sudorw <ahmedrowaihi@sudorw.com>

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Parse arguments
STATIC_BUILD=false
CLEAN_BUILD=false
SKIP_CLONE=false
VARIANT=arabic

while [[ $# -gt 0 ]]; do
    case $1 in
        --static)
            STATIC_BUILD=true
            shift
            ;;
        --clean)
            CLEAN_BUILD=true
            shift
            ;;
        --skip-clone)
            SKIP_CLONE=true
            shift
            ;;
        --variant)
            VARIANT="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: build.sh [--variant arabic|vanilla] [--static] [--clean] [--skip-clone]"
            exit 1
            ;;
    esac
done

case "$VARIANT" in
    vanilla) LADYBIRD_REPO="https://github.com/LadybirdBrowser/ladybird.git";    LADYBIRD_REF="master"   ;;
    arabic)  LADYBIRD_REPO="https://github.com/ahmedrowaihi/ladybird-itbaa.git"; LADYBIRD_REF="upstream" ;;
    *)       echo "Unknown variant: $VARIANT (expected 'arabic' or 'vanilla')"; exit 1 ;;
esac

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║           Itbaa (اطبع) - HTML to PDF Converter               ║"
echo "║           Copyright (c) 2025, Ahmed Rowaihi                  ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Clone or update Ladybird
if [ "$SKIP_CLONE" = false ]; then
    if [ ! -d "$SCRIPT_DIR/ladybird" ]; then
        echo "📥 Cloning Ladybird ($VARIANT: $LADYBIRD_REPO @ $LADYBIRD_REF)..."
        git clone --depth 1 --branch "$LADYBIRD_REF" "$LADYBIRD_REPO" "$SCRIPT_DIR/ladybird"
    else
        echo "📂 Ladybird directory exists"
    fi
fi

cd "$SCRIPT_DIR/ladybird"

# Apply patches
echo "🔧 Applying patches..."
for patch in "$SCRIPT_DIR/patches"/*.patch; do
    if [ -f "$patch" ]; then
        echo "  Applying $(basename "$patch")..."
        git apply --check "$patch" 2>/dev/null && git apply "$patch" || echo "  (already applied or skipped)"
    fi
done

# Copy new files
if [ -d "$SCRIPT_DIR/new-files" ]; then
    echo "📁 Copying new files..."
    cp -r "$SCRIPT_DIR/new-files"/* .
fi

# Configure
echo ""
echo "⚙️  Configuring..."
if [ "$STATIC_BUILD" = true ]; then
    PRESET="Itbaa_Static"
    BUILD_DIR="Build/itbaa-static"
else
    PRESET="Itbaa"
    BUILD_DIR="Build/itbaa"
fi

if [ "$CLEAN_BUILD" = true ] && [ -d "$BUILD_DIR" ]; then
    rm -rf "$BUILD_DIR"
fi

# macOS: mainline llvm clang rejects the SDK's CF_ENUM macro (-Welaborated-enum-base)
# in CoreFoundation-including vcpkg ports (e.g. libproxy). Apple's own clang exempts it.
# This hook is read by Ladybird's vcpkg base triplet for dependency builds.
if [ "$(uname)" = "Darwin" ]; then
    cat > "$SCRIPT_DIR/ladybird/Meta/CMake/vcpkg/user-variables.cmake" <<'CMK'
if (APPLE)
    set(VCPKG_C_FLAGS "${VCPKG_C_FLAGS} -Wno-elaborated-enum-base")
    set(VCPKG_CXX_FLAGS "${VCPKG_CXX_FLAGS} -Wno-elaborated-enum-base")
endif()
CMK
fi

# macOS: the Rust crate static archives (LibJS/LibGfx/LibURL) aren't 8-byte aligned, which the
# new ld rejects; the classic linker tolerates them.
EXTRA_CMAKE_ARGS=()
if [ "$(uname)" = "Darwin" ]; then
    EXTRA_CMAKE_ARGS+=(-DCMAKE_EXE_LINKER_FLAGS="-Wl,-ld_classic" -DCMAKE_SHARED_LINKER_FLAGS="-Wl,-ld_classic" -DCMAKE_MODULE_LINKER_FLAGS="-Wl,-ld_classic")
else
    # CPU-only render: disable Vulkan so LibGfx doesn't require system libdrm under vcpkg.
    EXTRA_CMAKE_ARGS+=(-DCMAKE_DISABLE_FIND_PACKAGE_Vulkan=ON -DCMAKE_DISABLE_FIND_PACKAGE_VulkanHeaders=ON)
fi

cmake --preset "$PRESET" "${EXTRA_CMAKE_ARGS[@]}"

# Build
echo ""
echo "🔨 Building..."
cmake --build "$BUILD_DIR" --target itbaa-cli

# Report
echo ""
echo "✅ Build complete!"
echo ""
echo "Binary location: $SCRIPT_DIR/ladybird/$BUILD_DIR/bin/itbaa"
echo ""
echo "Usage:"
echo "  $BUILD_DIR/bin/itbaa <input.html> <output.pdf>"
echo "  $BUILD_DIR/bin/itbaa --help"

