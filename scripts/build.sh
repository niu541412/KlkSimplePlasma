#!/bin/bash
set -euo pipefail

ARCHITECTURE="${1:-arm64}"
case "$ARCHITECTURE" in
    arm64|x86_64) ;;
    *) echo "Unsupported architecture: $ARCHITECTURE" >&2; exit 2 ;;
esac

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build/$ARCHITECTURE"
BUNDLE_NAME="Klk's Simple Plasma.saver"
BUNDLE_DIR="$BUILD_DIR/$BUNDLE_NAME"
CONTENTS_DIR="$BUNDLE_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
INTERMEDIATES_DIR="$BUILD_DIR/Intermediates"
SDK_PATH="$(xcrun --sdk macosx --show-sdk-path)"

rm -rf "$BUILD_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR" "$INTERMEDIATES_DIR"

cp "$ROOT_DIR/Resources/Info.plist" "$CONTENTS_DIR/Info.plist"
cp "$ROOT_DIR/Resources/thumbnail.png" "$RESOURCES_DIR/thumbnail.png"
cp "$ROOT_DIR/Resources/thumbnail@2x.png" "$RESOURCES_DIR/thumbnail@2x.png"

xcrun --sdk macosx metal \
    -c "$ROOT_DIR/Sources/Plasma.metal" \
    -o "$INTERMEDIATES_DIR/Plasma.air"
xcrun --sdk macosx metallib \
    "$INTERMEDIATES_DIR/Plasma.air" \
    -o "$RESOURCES_DIR/Plasma.metallib"

xcrun --sdk macosx clang \
    -arch "$ARCHITECTURE" \
    -isysroot "$SDK_PATH" \
    -mmacosx-version-min=13.0 \
    -fobjc-arc \
    -fmodules \
    -Wall -Wextra -Werror \
    -bundle \
    -framework Cocoa \
    -framework Metal \
    -framework MetalKit \
    -framework QuartzCore \
    -framework ScreenSaver \
    "$ROOT_DIR/Sources/KlkSimplePlasmaView.m" \
    -o "$MACOS_DIR/KlkSimplePlasma"

codesign --force --sign - --timestamp=none "$BUNDLE_DIR"
codesign --verify --deep --strict "$BUNDLE_DIR"
file "$MACOS_DIR/KlkSimplePlasma"
shasum -a 256 "$RESOURCES_DIR/thumbnail.png" "$RESOURCES_DIR/thumbnail@2x.png"
echo "$BUNDLE_DIR"
