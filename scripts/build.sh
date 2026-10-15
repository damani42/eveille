#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD="$ROOT/build"
APP="$BUILD/Eveille.app"
MODE="${1:---native}"
case "$MODE" in
  --native) ARCHITECTURES="$(uname -m)"; LABEL="$(uname -m)" ;;
  --universal) ARCHITECTURES="arm64 x86_64"; LABEL="universal" ;;
  *) echo "Usage: $0 [--native|--universal]" >&2; exit 2 ;;
esac
mkdir -p "$BUILD/module-cache" "$APP/Contents/MacOS" "$ROOT/dist"
for ARCH in $ARCHITECTURES; do
  xcrun swiftc "$ROOT/Sources/AwakeSession.swift" "$ROOT/Sources/main.swift" \
    -O -target "$ARCH-apple-macos13.0" -module-cache-path "$BUILD/module-cache" \
    -framework AppKit -framework IOKit -o "$BUILD/Eveille-$ARCH"
done
if [ "$MODE" = "--universal" ]; then
  xcrun lipo -create "$BUILD/Eveille-arm64" "$BUILD/Eveille-x86_64" -output "$APP/Contents/MacOS/Eveille"
else
  cp "$BUILD/Eveille-$LABEL" "$APP/Contents/MacOS/Eveille"
fi
cp "$ROOT/Resources/Info.plist" "$APP/Contents/Info.plist"
codesign --force --sign - "$APP"
codesign --verify --strict "$APP"
plutil -lint "$APP/Contents/Info.plist"
ARCHIVE="$ROOT/dist/Eveille-macos-$LABEL.zip"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$ARCHIVE"
(cd "$ROOT/dist" && shasum -a 256 "Eveille-macos-$LABEL.zip" > "Eveille-macos-$LABEL.zip.sha256")
echo "Built: $APP"
echo "Packaged: $ARCHIVE"
