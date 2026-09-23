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
SDK_PATH="$(xcrun --sdk macosx --show-sdk-path)"

rm -rf "$BUILD_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp "$ROOT_DIR/Resources/Info.plist" "$CONTENTS_DIR/Info.plist"
cp "$ROOT_DIR/Resources/thumbnail.tiff" "$RESOURCES_DIR/thumbnail.tiff"
cp "$ROOT_DIR/Sources/Plasma.fsh" "$RESOURCES_DIR/Plasma.fsh"

xcrun --sdk macosx clang \
    -arch "$ARCHITECTURE" \
    -isysroot "$SDK_PATH" \
    -mmacosx-version-min=13.0 \
    -fobjc-arc \
    -fmodules \
    -Wall -Wextra -Werror \
    -bundle \
    -framework Cocoa \
    -framework QuartzCore \
    -framework ScreenSaver \
    -framework SpriteKit \
    "$ROOT_DIR/Sources/KlkSimplePlasmaView.m" \
    -o "$MACOS_DIR/KlkSimplePlasma"

codesign --force --sign - --timestamp=none "$BUNDLE_DIR"
codesign --verify --deep --strict "$BUNDLE_DIR"
file "$MACOS_DIR/KlkSimplePlasma"
shasum -a 256 "$RESOURCES_DIR/thumbnail.tiff"
echo "$BUNDLE_DIR"
