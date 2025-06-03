#!/usr/bin/env pwsh
# build_all.ps1 - Build Flutter binaries for all platforms on Windows

# Exit immediately if a command fails
$ErrorActionPreference = "Stop"

Write-Host "Building Android APK..."
flutter build apk

Write-Host "Building Android App Bundle..."
flutter build appbundle

Write-Host "Building iOS (no code signing, requires macOS)..."
flutter build ios --no-codesign

Write-Host "Building Windows desktop..."
flutter build windows --release

Write-Host "Building Linux desktop..."
flutter build linux --release

Write-Host "Building macOS desktop..."
flutter build macos --release

Write-Host "Building web..."
flutter build web --release

Write-Host "All builds completed."

Write-Host "Collecting build artifacts..."
$releaseDir = "release"
if (Test-Path $releaseDir) { Remove-Item $releaseDir -Recurse -Force }
New-Item -ItemType Directory -Path $releaseDir | Out-Null

# Android outputs
$androidOut = Join-Path $releaseDir "android"
New-Item -ItemType Directory -Path $androidOut -Force | Out-Null
Copy-Item "build/app/outputs/flutter-apk/app-release.apk" -Destination $androidOut
Copy-Item "build/app/outputs/bundle/release/app-release.aab" -Destination $androidOut

# iOS app bundle
$iosOut = Join-Path $releaseDir "ios"
New-Item -ItemType Directory -Path $iosOut -Force | Out-Null
Copy-Item "build/ios/iphoneos/Runner.app" -Destination $iosOut -Recurse

# Windows desktop
$winOut = Join-Path $releaseDir "windows"
New-Item -ItemType Directory -Path $winOut -Force | Out-Null
Copy-Item "build/windows/runner/Release" -Destination $winOut -Recurse

# Linux desktop
$linuxOut = Join-Path $releaseDir "linux"
New-Item -ItemType Directory -Path $linuxOut -Force | Out-Null
Copy-Item "build/linux/x64/release/bundle" -Destination $linuxOut -Recurse

# macOS desktop
$macosOut = Join-Path $releaseDir "macos"
New-Item -ItemType Directory -Path $macosOut -Force | Out-Null
Copy-Item "build/macos/Build/Products/Release/*.app" -Destination $macosOut -Recurse

# Web build
$webOut = Join-Path $releaseDir "web"
New-Item -ItemType Directory -Path $webOut -Force | Out-Null
Copy-Item "build/web/*" -Destination $webOut -Recurse

Write-Host "Artifacts copied to '$releaseDir' folder."
