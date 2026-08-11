#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
BUILD_DIR="$SCRIPT_DIR/build/tests"
MODULE_CACHE_DIR="$BUILD_DIR/ModuleCache"
DEFAULT_SDK_PATH="$(xcrun --sdk macosx --show-sdk-path)"
SDK_DIRECTORY="${DEFAULT_SDK_PATH:h}"
VERSIONED_SDK_PATH="$(find "$SDK_DIRECTORY" -maxdepth 1 -type d -name 'MacOSX[0-9]*.sdk' | sort | head -n 1)"
SDK_PATH="${DICTATION_SDK:-${VERSIONED_SDK_PATH:-$DEFAULT_SDK_PATH}}"
TARGET_ARCH="${DICTATION_ARCH:-$(uname -m)}"

mkdir -p "$BUILD_DIR" "$MODULE_CACHE_DIR"

xcrun swiftc \
    -O \
    -target "$TARGET_ARCH-apple-macosx13.0" \
    -sdk "$SDK_PATH" \
    -module-cache-path "$MODULE_CACHE_DIR" \
    "$SCRIPT_DIR/Sources/DictationCore.swift" \
    "$SCRIPT_DIR/Tests/DictationCoreTests.swift" \
    -o "$BUILD_DIR/DictationCoreTests"
"$BUILD_DIR/DictationCoreTests"

xcrun swiftc \
    -O \
    -target "$TARGET_ARCH-apple-macosx13.0" \
    -sdk "$SDK_PATH" \
    -module-cache-path "$MODULE_CACHE_DIR" \
    -framework AVFoundation \
    "$SCRIPT_DIR/Sources/PreferredVoices.swift" \
    "$SCRIPT_DIR/Tests/VoiceAvailabilityTests.swift" \
    -o "$BUILD_DIR/VoiceAvailabilityTests"
"$BUILD_DIR/VoiceAvailabilityTests"
