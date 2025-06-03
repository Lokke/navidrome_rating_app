#!/usr/bin/env bash
# build_all.sh - Build Flutter binaries for all platforms
set -e

echo "Building Android APK..."
flutter build apk

echo "Building Android App Bundle..."
flutter build appbundle

echo "Building iOS (no code signing, requires macOS)..."
flutter build ios --no-codesign

echo "Building Windows desktop..."
flutter build windows --release

echo "Building Linux desktop..."
flutter build linux --release

echo "Building macOS desktop..."
flutter build macos --release

echo "Building web..."
flutter build web --release

echo "All builds completed."
