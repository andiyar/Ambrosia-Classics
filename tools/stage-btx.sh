#!/usr/bin/env bash
# Stage Bubble Trouble X for Ben (CLAUDE.md "Staged builds"; plan 2026-10-04-btx-playable A1/S5): build Release,
# copy the ORIGINAL 1.1 Contents/Resources files the game loads into the built app unchanged (original names — the
# app resolves them from its own bundle), strip quarantine/xattrs, ad-hoc re-sign, and place
# out/BubbleTroubleX/Bubble Trouble X.app + out/BubbleTroubleX/WHAT-TO-EXPECT.md. out/, .build/ and *.xcodeproj are
# git-ignored; the original data never enters git (plan R13).
# BTX_DATA overrides the data folder. Both are also ditto'd to ~/Desktop (hidden worktrees are unopenable from
# Finder); BTX_STAGE_NO_DESKTOP=1 skips that (implementer test runs — the orchestrator stages for Ben).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BTXR="/Users/andiyar/Developer/Ambrosia/Resources/ambrosia-extracted/Action-Adventure/Bubble Trouble X/BubbleTroubleX_1.1_UB/Bubble Trouble X.app/Contents/Resources"
DATA="${BTX_DATA:-$BTXR}"
FILES=("Bubble Trouble X.rsrc" "BT Levels.rsrc" "BT Sprites.rsrc" "BT Sounds.rsrc" "BT Titles.rsrc"
       "BubbleTrouble.icns" "English.lproj/AboutCredits1.rtf")
for f in "${FILES[@]}"; do
    if [ ! -f "$DATA/$f" ]; then
        echo "stage-btx: no Bubble Trouble X 1.1 Contents/Resources at $DATA (missing \"$f\"; set BTX_DATA)" >&2
        exit 2
    fi
done
DATA="$(cd "$DATA" && pwd -P)"
cd "$ROOT"

mkdir -p .build
LOG="$ROOT/.build/stage-btx-xcodebuild.log"
xcodegen generate --quiet
if ! xcodebuild -project AmbrosiaClassics.xcodeproj -scheme BubbleTroubleX -configuration Release \
        -derivedDataPath "$ROOT/.build/xcode-btx" build > "$LOG" 2>&1; then
    tail -n 30 "$LOG" >&2
    echo "stage-btx: xcodebuild failed (full log: $LOG)" >&2
    exit 1
fi

NAME="Bubble Trouble X.app"
APP="$ROOT/.build/xcode-btx/Build/Products/Release/$NAME"
OUT="$ROOT/out/BubbleTroubleX"
rm -rf "$OUT"
mkdir -p "$OUT"
ditto "$APP" "$OUT/$NAME"
RES="$OUT/$NAME/Contents/Resources"
mkdir -p "$RES/English.lproj"
for f in "${FILES[@]}"; do
    cp "$DATA/$f" "$RES/$f"
done
xattr -cr "$OUT/$NAME"
# --deep is deprecated but still accepted by Xcode 27's codesign (stage-aki.sh precedent)
codesign --force --deep --sign - "$OUT/$NAME"
codesign --verify --deep "$OUT/$NAME"
cp "$ROOT/BubbleTroubleX/WHAT-TO-EXPECT.md" "$OUT/WHAT-TO-EXPECT.md"

if [ "${BTX_STAGE_NO_DESKTOP:-0}" != "1" ]; then
    rm -rf "$HOME/Desktop/$NAME"
    ditto "$OUT/$NAME" "$HOME/Desktop/$NAME"
    cp "$OUT/WHAT-TO-EXPECT.md" "$HOME/Desktop/Bubble Trouble X — WHAT-TO-EXPECT.md"
    echo "desktop: $HOME/Desktop/$NAME"
fi

echo "staged: $OUT/$NAME"
echo "notes:  $OUT/WHAT-TO-EXPECT.md"
