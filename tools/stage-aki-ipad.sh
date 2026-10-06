#!/usr/bin/env bash
# Stage Aki for Ben's iPad (CLAUDE.md "Staged builds", DECISIONS D7): build the AkiPad target Release for a
# device (Automatic signing, team from project.yml; the target's own build phase copies the ORIGINAL Aki 1.2.0
# Contents/Resources into the bundle before signing), place out/AkiPad/Aki.app + WHAT-TO-EXPECT-iPad.md, check
# the bundle, then install it on the paired iPad with devicectl (skip with --no-install).
# out/, .build/ and *.xcodeproj are git-ignored.
#   AKI_DATA_12     the Aki 1.2.0 Contents/Resources (default Resources/Aki/1.2.0.app/Contents/Resources)
#   AKI_IPAD_DEVICE devicectl device identifier or name (default: Ben's iPad mini)
# Remaster (D11): the same build phase mirrors Resources/Aki/hd-4x/ into <bundle>/hd-4x/ (no hd-4x → Remastered
# Art disabled).
# Exit: 1 build/bundle failure, 2 no data, 3 install failed (device locked / unavailable / not paired).
set -euo pipefail

INSTALL=1
for arg in "$@"; do
    case "$arg" in
        --no-install) INSTALL=0 ;;
        *) echo "usage: $0 [--no-install]" >&2; exit 64 ;;
    esac
done

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DATA="${AKI_DATA_12:-$ROOT/Resources/Aki/1.2.0.app/Contents/Resources}"
if [ ! -f "$DATA/map.png" ]; then
    echo "stage-aki-ipad: no Aki 1.2.0 Contents/Resources at $DATA (set AKI_DATA_12)" >&2
    exit 2
fi
DATA="$(cd "$DATA" && pwd -P)"
export AKI_DATA_12="$DATA"   # read by the AkiPad "Copy original Aki data" build phase
DEVICE="${AKI_IPAD_DEVICE:-08C59560-D6CD-5E0B-98A4-89454AB9A7F8}"
cd "$ROOT"

mkdir -p .build
LOG="$ROOT/.build/stage-aki-ipad-xcodebuild.log"
xcodegen generate --quiet
if ! xcodebuild -project AmbrosiaClassics.xcodeproj -scheme AkiPad -configuration Release \
        -destination 'generic/platform=iOS' -derivedDataPath "$ROOT/.build/xcode-akipad-device" \
        -allowProvisioningUpdates build > "$LOG" 2>&1; then
    tail -n 30 "$LOG" >&2
    echo "stage-aki-ipad: xcodebuild failed (full log: $LOG)" >&2
    exit 1
fi

APP="$ROOT/.build/xcode-akipad-device/Build/Products/Release-iphoneos/Aki.app"
OUT="$ROOT/out/AkiPad"
rm -rf "$OUT"
mkdir -p "$OUT"
ditto "$APP" "$OUT/Aki.app"
cp "$ROOT/Aki/WHAT-TO-EXPECT-iPad.md" "$OUT/WHAT-TO-EXPECT-iPad.md"

PNGS="$(find "$OUT/Aki.app" -maxdepth 1 -name '*.png' | wc -l | tr -d ' ')"
if [ ! -f "$OUT/Aki.app/English.lproj/Aki.nib/objects.xib" ]; then
    echo "stage-aki-ipad: English.lproj/Aki.nib/objects.xib missing from the built bundle" >&2
    exit 1
fi
echo "staged: $OUT/Aki.app ($PNGS PNG, expect 50; Aki.nib/objects.xib present)"
if [ -d "$OUT/Aki.app/hd-4x" ]; then
    echo "remaster: hd-4x $(find "$OUT/Aki.app/hd-4x" -name '*.png' | wc -l | tr -d ' ') PNG, $(du -sh "$OUT/Aki.app/hd-4x" | cut -f1)"
else
    echo "stage-aki-ipad: warning: no hd-4x/ in the bundle (Resources/Aki/hd-4x absent); Remastered Art will show disabled" >&2
fi
echo "notes:  $OUT/WHAT-TO-EXPECT-iPad.md"

if [ "$INSTALL" -eq 0 ]; then
    exit 0
fi
echo "installing on $DEVICE ..."
if ! xcrun devicectl device install app --device "$DEVICE" "$OUT/Aki.app"; then
    echo "stage-aki-ipad: install failed — is the iPad unlocked, awake, connected (cable or same network) and" >&2
    echo "  paired, with Developer Mode on? Unlock it and run again (or: $0 --no-install)." >&2
    exit 3
fi
echo "installed: com.ambrosiaclassics.aki.ipad on $DEVICE"
