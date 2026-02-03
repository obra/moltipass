#!/bin/bash
set -e

# Build with xtool
TARGET="${1:---simulator}"
xtool dev "$TARGET"

APP_BUNDLE="xtool/Moltipass.app"
ICON_SOURCE="AppIcon.png"

# Check if icon exists
if [ ! -f "$ICON_SOURCE" ]; then
    echo "Warning: $ICON_SOURCE not found, skipping icon injection"
    exit 0
fi

echo "Injecting app icon..."

# Copy icon with iOS naming conventions
cp "$ICON_SOURCE" "$APP_BUNDLE/AppIcon60x60@2x.png"
cp "$ICON_SOURCE" "$APP_BUNDLE/AppIcon60x60@3x.png"
cp "$ICON_SOURCE" "$APP_BUNDLE/AppIcon76x76@2x~ipad.png"
cp "$ICON_SOURCE" "$APP_BUNDLE/AppIcon83.5x83.5@2x~ipad.png"

# Update Info.plist with icon configuration
/usr/libexec/PlistBuddy -c "Delete :CFBundleIcons" "$APP_BUNDLE/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :CFBundleIcons dict" "$APP_BUNDLE/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleIcons:CFBundlePrimaryIcon dict" "$APP_BUNDLE/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleIcons:CFBundlePrimaryIcon:CFBundleIconFiles array" "$APP_BUNDLE/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleIcons:CFBundlePrimaryIcon:CFBundleIconFiles:0 string AppIcon60x60" "$APP_BUNDLE/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleIcons:CFBundlePrimaryIcon:CFBundleIconFiles:1 string AppIcon76x76" "$APP_BUNDLE/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleIcons:CFBundlePrimaryIcon:CFBundleIconFiles:2 string AppIcon83.5x83.5" "$APP_BUNDLE/Info.plist"

# iPad icons
/usr/libexec/PlistBuddy -c "Delete :CFBundleIcons~ipad" "$APP_BUNDLE/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :CFBundleIcons~ipad dict" "$APP_BUNDLE/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleIcons~ipad:CFBundlePrimaryIcon dict" "$APP_BUNDLE/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleIcons~ipad:CFBundlePrimaryIcon:CFBundleIconFiles array" "$APP_BUNDLE/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleIcons~ipad:CFBundlePrimaryIcon:CFBundleIconFiles:0 string AppIcon60x60" "$APP_BUNDLE/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleIcons~ipad:CFBundlePrimaryIcon:CFBundleIconFiles:1 string AppIcon76x76" "$APP_BUNDLE/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleIcons~ipad:CFBundlePrimaryIcon:CFBundleIconFiles:2 string AppIcon83.5x83.5" "$APP_BUNDLE/Info.plist"

echo "Icon injected successfully"

# Reinstall to target
if [ "$TARGET" = "--simulator" ]; then
    echo "Reinstalling to simulator..."
    xcrun simctl install booted "$APP_BUNDLE"
    xcrun simctl launch booted com.moltipass.app
elif [ "$TARGET" = "--network" ] || [ "$TARGET" = "--usb" ]; then
    echo "Installing to device ($TARGET)..."
    xtool install "$TARGET" "$APP_BUNDLE"
fi
