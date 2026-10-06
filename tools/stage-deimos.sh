#!/usr/bin/env bash
# Stage Deimos Rising for Ben (CLAUDE.md "Staged builds"; plan 2026-10-06-deimos-phase1 A2, S8): build Release,
# copy the ORIGINAL 1.0.6 Data folder (Paks + Local, committed under Resources/Deimos/Data — D24) into the built app
# at Contents/Resources/Deimos/Data unchanged, strip quarantine/xattrs, ad-hoc re-sign, and place
# out/Deimos/Deimos Rising.app + out/Deimos/WHAT-TO-EXPECT.md. out/, .build/ and *.xcodeproj are git-ignored.
# DEIMOS_DATA overrides the data folder. Both are also ditto'd to ~/Desktop (hidden worktrees are unopenable from
# Finder); DEIMOS_STAGE_NO_DESKTOP=1 skips that (implementer test runs — the orchestrator stages for Ben).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DATA="${DEIMOS_DATA:-$ROOT/Resources/Deimos/Data}"
FILES=("Paks/Game.pak" "Paks/Interface.pak" "Paks/Audio.pak" "Paks/Music.pak")
for f in "${FILES[@]}"; do
    if [ ! -f "$DATA/$f" ]; then
        echo "stage-deimos: no Deimos Rising Data folder at $DATA (missing \"$f\"; set DEIMOS_DATA)" >&2
        exit 2
    fi
done
DATA="$(cd "$DATA" && pwd -P)"
cd "$ROOT"

mkdir -p .build
LOG="$ROOT/.build/stage-deimos-xcodebuild.log"
xcodegen generate --quiet
if ! xcodebuild -project AmbrosiaClassics.xcodeproj -scheme Deimos -configuration Release \
        -derivedDataPath "$ROOT/.build/xcode-deimos" build > "$LOG" 2>&1; then
    tail -n 30 "$LOG" >&2
    echo "stage-deimos: xcodebuild failed (full log: $LOG)" >&2
    exit 1
fi

NAME="Deimos Rising.app"
APP="$ROOT/.build/xcode-deimos/Build/Products/Release/$NAME"
OUT="$ROOT/out/Deimos"
rm -rf "$OUT"
mkdir -p "$OUT"
ditto "$APP" "$OUT/$NAME"
DEST="$OUT/$NAME/Contents/Resources/Deimos/Data"
mkdir -p "$DEST"
# The original Data folder as-is; the git-ignored HID.bundle and Finder Icon\r files are not game data.
rsync -a --exclude '.DS_Store' --exclude 'HID.bundle' --exclude $'Icon\r' "$DATA/" "$DEST/"
xattr -cr "$OUT/$NAME"
# --deep is deprecated but still accepted by Xcode 27's codesign (stage-aki.sh precedent)
codesign --force --deep --sign - "$OUT/$NAME"
codesign --verify --deep "$OUT/$NAME"
cp "$ROOT/Deimos/WHAT-TO-EXPECT.md" "$OUT/WHAT-TO-EXPECT.md"

if [ "${DEIMOS_STAGE_NO_DESKTOP:-0}" != "1" ]; then
    rm -rf "$HOME/Desktop/$NAME"
    ditto "$OUT/$NAME" "$HOME/Desktop/$NAME"
    ditto "$OUT/WHAT-TO-EXPECT.md" "$HOME/Desktop/Deimos Rising — WHAT-TO-EXPECT.md"
    echo "desktop: $HOME/Desktop/$NAME"
fi

echo "staged: $OUT/$NAME ($(du -sh "$DEST" | cut -f1) data)"
echo "notes:  $OUT/WHAT-TO-EXPECT.md"
