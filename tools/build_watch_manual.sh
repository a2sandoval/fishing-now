#!/bin/bash
# Manual watchOS build for Fishing Now.
# Bypasses xcodebuild, which fails on unsigned watchapp2 targets with a
# duplicate-output error (CopyAndPreserveArchs vs the link command) on every
# Xcode tested (16.4, 26.5, 26.6) — including for a minimal xcodegen-generated
# reference watch app, so it is a toolchain behavior, not a project defect.
# Produces an UNSIGNED watch .app bundle; the user re-signs it with his own
# Developer team (or a signing service) to install on his Watch.
set -euo pipefail

XCODE="${XCODE_APP:-/Applications/Xcode_26.5.app}"
SDK="$XCODE/Contents/Developer/Platforms/WatchOS.platform/Developer/SDKs/WatchOS26.5.sdk"
SWIFTC="$XCODE/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc"
ACTOOL="$XCODE/Contents/Developer/usr/bin/actool"
LIPO="$XCODE/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/lipo"

APP_NAME="FishingNowWatch Watch App"
OUT_DIR="watch-build"
APP_DIR="$OUT_DIR/$APP_NAME.app"

echo "--- SDK ---"
ls -d "$SDK" || { echo "watchOS SDK not found at $SDK"; exit 1; }
"$SWIFTC" --version

rm -rf "$OUT_DIR"
mkdir -p "$APP_DIR"

SOURCES=(
  "FishingNowWatch Watch App/FishingNowWatchApp.swift"
  "FishingNowWatch Watch App/GameView.swift"
  "FishingNowWatch Watch App/WatchViews.swift"
  "FishingNowWatch Watch App/WatchStore.swift"
  Shared/Fish.swift Shared/FishData.swift Shared/GameEngine.swift
)

echo "--- compile + link watch executable (universal: arm64 + arm64_32) ---"
"$SWIFTC" \
  -sdk "$SDK" \
  -target arm64-apple-watchos10.0 \
  -O \
  -o "$OUT_DIR/exe-arm64" \
  "${SOURCES[@]}"
"$SWIFTC" \
  -sdk "$SDK" \
  -target arm64_32-apple-watchos10.0 \
  -O \
  -o "$OUT_DIR/exe-arm64_32" \
  "${SOURCES[@]}"
"$LIPO" -create "$OUT_DIR/exe-arm64" "$OUT_DIR/exe-arm64_32" \
  -output "$APP_DIR/$APP_NAME"

echo "--- compile asset catalog (AppIcon + AccentColor) ---"
"$ACTOOL" \
  "FishingNowWatch Watch App/Assets.xcassets" \
  --compile "$APP_DIR" \
  --output-format human-readable-text \
  --notices --warnings \
  --output-partial-info-plist "$OUT_DIR/assetcatalog_generated_info.plist" \
  --app-icon AppIcon \
  --accent-color AccentColor \
  --compress-pngs \
  --enable-on-demand-resources NO \
  --development-region en \
  --target-device watch \
  --minimum-deployment-target 10.0 \
  --platform watchos \
  --bundle-identifier com.a2sandoval.fishingnow.watchkitapp

echo "--- Info.plist (static + actool icon entries) ---"
python3 tools/merge_watch_plist.py \
  tools/Watch-Info.plist \
  "$OUT_DIR/assetcatalog_generated_info.plist" \
  "$APP_DIR/Info.plist"

echo "--- WK stub ---"
mkdir -p "$APP_DIR/_WatchKitStub"
cp "$SDK/Library/Application Support/WatchKit/WK" "$APP_DIR/_WatchKitStub/WK"

echo "--- result ---"
ls -la "$APP_DIR"
file "$APP_DIR/$APP_NAME"
