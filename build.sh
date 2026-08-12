#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
BUILD_DIR="$SCRIPT_DIR/build"
APP_DIR="$BUILD_DIR/默写小程序.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
MODULE_CACHE_DIR="$BUILD_DIR/ModuleCache"
DEFAULT_SDK_PATH="$(xcrun --sdk macosx --show-sdk-path)"
SDK_DIRECTORY="${DEFAULT_SDK_PATH:h}"
VERSIONED_SDK_PATH="$(find "$SDK_DIRECTORY" -maxdepth 1 -type d -name 'MacOSX[0-9]*.sdk' | sort | head -n 1)"
SDK_PATH="${DICTATION_SDK:-${VERSIONED_SDK_PATH:-$DEFAULT_SDK_PATH}}"
TARGET_ARCH="${DICTATION_ARCH:-$(uname -m)}"

mkdir -p "$MACOS_DIR" "$RESOURCES_DIR" "$MODULE_CACHE_DIR"
rm -f "$MACOS_DIR/默写小程序"

xcrun swiftc \
    -O \
    -parse-as-library \
    -target "$TARGET_ARCH-apple-macosx13.0" \
    -sdk "$SDK_PATH" \
    -module-cache-path "$MODULE_CACHE_DIR" \
    -framework SwiftUI \
    -framework AppKit \
    -framework AVFoundation \
    "$SCRIPT_DIR/Sources/DictationCore.swift" \
    "$SCRIPT_DIR/Sources/PreferredVoices.swift" \
    "$SCRIPT_DIR/Sources/DictationApp.swift" \
    -o "$MACOS_DIR/DictationHelper"

cp "$SCRIPT_DIR/Info.plist" "$CONTENTS_DIR/Info.plist"
cp "$SCRIPT_DIR/Assets/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
xattr -cr "$APP_DIR"
codesign --force --deep --sign - "$APP_DIR"

echo "Built: $APP_DIR"
