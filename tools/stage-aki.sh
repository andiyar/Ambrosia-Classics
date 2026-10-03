#!/usr/bin/env bash
# Stage Aki for Ben (CLAUDE.md "Staged builds"): build Release, copy the ORIGINAL Aki 1.2.0
# Contents/Resources into the built app unchanged (original names, no re-encoding — the app loads
# everything from its own bundle), strip quarantine/xattrs, ad-hoc re-sign, and place
# out/Aki/Aki.app + out/Aki/WHAT-TO-EXPECT.md. out/, .build/ and *.xcodeproj are git-ignored.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DATA="${AKI_DATA_12:-$ROOT/Resources/Aki/1.2.0.app/Contents/Resources}"
if [ ! -f "$DATA/map.png" ]; then
    echo "stage-aki: no Aki 1.2.0 Contents/Resources at $DATA (set AKI_DATA_12)" >&2
    exit 2
fi
DATA="$(cd "$DATA" && pwd -P)"
cd "$ROOT"

mkdir -p .build
LOG="$ROOT/.build/stage-aki-xcodebuild.log"
xcodegen generate --quiet
if ! xcodebuild -project AmbrosiaClassics.xcodeproj -scheme Aki -configuration Release \
        -derivedDataPath "$ROOT/.build/xcode-aki" build > "$LOG" 2>&1; then
    tail -n 30 "$LOG" >&2
    echo "stage-aki: xcodebuild failed (full log: $LOG)" >&2
    exit 1
fi

APP="$ROOT/.build/xcode-aki/Build/Products/Release/Aki.app"
OUT="$ROOT/out/Aki"
rm -rf "$OUT"
mkdir -p "$OUT"
ditto "$APP" "$OUT/Aki.app"
mkdir -p "$OUT/Aki.app/Contents/Resources"
rsync -a --exclude '.DS_Store' "$DATA/" "$OUT/Aki.app/Contents/Resources/"
# Release Notes.rtf is set in Osaka-Mono, a downloadable asset on current macOS: bundle Apple's copy
# (registered by Info.plist ATSApplicationFontsPath = Fonts) so the notes never prompt for a download.
OSAKA="$(find /System/Library/AssetsV2 -name OsakaMono.ttf -print -quit 2>/dev/null || true)"
if [ -n "$OSAKA" ]; then
    mkdir -p "$OUT/Aki.app/Contents/Resources/Fonts"
    cp "$OSAKA" "$OUT/Aki.app/Contents/Resources/Fonts/OsakaMono.ttf"
else
    echo "stage-aki: warning: OsakaMono.ttf not found under /System/Library/AssetsV2; Release Notes fall back to Menlo" >&2
fi
xattr -cr "$OUT/Aki.app"
# --deep is deprecated but still accepted by Xcode 27's codesign (dry run 2026-10-03); errors stay visible
codesign --force --deep --sign - "$OUT/Aki.app"
codesign --verify --deep "$OUT/Aki.app"
cp "$ROOT/Aki/WHAT-TO-EXPECT.md" "$OUT/WHAT-TO-EXPECT.md"

echo "staged: $OUT/Aki.app ($(find "$OUT/Aki.app/Contents/Resources" -name '*.png' | wc -l | tr -d ' ') PNG)"
echo "notes:  $OUT/WHAT-TO-EXPECT.md"
