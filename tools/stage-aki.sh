#!/usr/bin/env bash
# Stage Aki for Ben (CLAUDE.md "Staged builds"): build Release, copy the ORIGINAL Aki 1.2.0
# Contents/Resources into the built app unchanged (original names, no re-encoding — the app loads
# everything from its own bundle), strip quarantine/xattrs, ad-hoc re-sign, and place
# out/Aki/Aki.app + out/Aki/WHAT-TO-EXPECT.md. out/, .build/ and *.xcodeproj are git-ignored.
# Remaster (DECISIONS D11): Resources/Aki/hd-4x/ (the U1 art set, git-ignored) goes to Contents/Resources/hd-4x/;
# AKI_REMASTER_BACKGROUNDS=plain|dedither (default plain) — dedither overlays Resources/Aki/hd-4x-dedither/
# background*.png onto it. No hd-4x/ → a warning; the app then shows Remastered Art disabled.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DATA="${AKI_DATA_12:-$ROOT/Resources/Aki/1.2.0.app/Contents/Resources}"
if [ ! -f "$DATA/map.png" ]; then
    echo "stage-aki: no Aki 1.2.0 Contents/Resources at $DATA (set AKI_DATA_12)" >&2
    exit 2
fi
DATA="$(cd "$DATA" && pwd -P)"
HD="$ROOT/Resources/Aki/hd-4x"
HD_DEDITHER="$ROOT/Resources/Aki/hd-4x-dedither"
BACKGROUNDS="${AKI_REMASTER_BACKGROUNDS:-plain}"
case "$BACKGROUNDS" in
    plain|dedither) ;;
    *) echo "stage-aki: warning: AKI_REMASTER_BACKGROUNDS must be plain or dedither (got $BACKGROUNDS); using plain" >&2
       BACKGROUNDS=plain ;;
esac
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
if [ -d "$HD" ]; then
    rsync -a --delete --exclude '.DS_Store' "$HD/" "$OUT/Aki.app/Contents/Resources/hd-4x/"
    if [ "$BACKGROUNDS" = dedither ]; then
        if compgen -G "$HD_DEDITHER/background*.png" > /dev/null; then
            cp "$HD_DEDITHER"/background*.png "$OUT/Aki.app/Contents/Resources/hd-4x/"
        else
            echo "stage-aki: warning: AKI_REMASTER_BACKGROUNDS=dedither but no $HD_DEDITHER/background*.png; plain backgrounds staged" >&2
            BACKGROUNDS=plain
        fi
    fi
else
    echo "stage-aki: warning: no $HD (run the U1 upscale tool); Remastered Art will show disabled" >&2
fi
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

echo "staged: $OUT/Aki.app ($(find "$OUT/Aki.app/Contents/Resources" -maxdepth 1 -name '*.png' | wc -l | tr -d ' ') PNG)"
if [ -d "$OUT/Aki.app/Contents/Resources/hd-4x" ]; then
    echo "remaster: Contents/Resources/hd-4x $(find "$OUT/Aki.app/Contents/Resources/hd-4x" -name '*.png' | wc -l | tr -d ' ') PNG," \
         "$(du -sh "$OUT/Aki.app/Contents/Resources/hd-4x" | cut -f1), backgrounds $BACKGROUNDS"
fi
echo "notes:  $OUT/WHAT-TO-EXPECT.md"
