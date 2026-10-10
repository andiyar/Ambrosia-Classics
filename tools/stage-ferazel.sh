#!/usr/bin/env bash
# Stage Ferazel's Wand for Ben (CLAUDE.md "Staged builds"; plan 2026-10-06-ferazel-phase1 A2, S7): build Release,
# copy the ORIGINAL 1.0.3 data (the six .rsrc files + "Ferazel's Wand Music", committed under Resources/Ferazel — D26)
# into the built app at Contents/Resources/Ferazel unchanged, strip quarantine/xattrs, ad-hoc re-sign, and place
# out/Ferazel/Ferazel's Wand.app + out/Ferazel/WHAT-TO-EXPECT.md + out/Ferazel/icon-previews/ (Icon Composer renders
# of Ferazel/App/AppIcon.icon; skipped with a message when ictool is missing). out/, .build/ and *.xcodeproj are
# git-ignored. FERAZEL_DATA overrides the data folder. All three are also ditto'd to ~/Desktop (hidden worktrees are
# unopenable from Finder); FERAZEL_STAGE_NO_DESKTOP=1 skips that (implementer test runs — the orchestrator stages for Ben).
# Every path is quoted: the app's name has an apostrophe.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DATA="${FERAZEL_DATA:-$ROOT/Resources/Ferazel}"
FILES=("Ferazel's Wand.rsrc" "Ferazel's Wand Backgrounds.rsrc" "Ferazel's Wand Sounds.rsrc"
       "Ferazel's Wand Sprites.rsrc" "Ferazel's Wand Titles.rsrc" "Ferazel's Wand World Data.rsrc")
MUSIC="Ferazel's Wand Music"
for f in "${FILES[@]}"; do
    if [ ! -f "$DATA/$f" ]; then
        echo "stage-ferazel: no Ferazel's Wand data folder at $DATA (missing \"$f\"; set FERAZEL_DATA)" >&2
        exit 2
    fi
done
if [ ! -d "$DATA/$MUSIC" ]; then
    echo "stage-ferazel: no \"$MUSIC\" folder in $DATA (set FERAZEL_DATA)" >&2
    exit 2
fi
DATA="$(cd "$DATA" && pwd -P)"
cd "$ROOT"

mkdir -p .build
LOG="$ROOT/.build/stage-ferazel-xcodebuild.log"
xcodegen generate --quiet
if ! xcodebuild -project AmbrosiaClassics.xcodeproj -scheme Ferazel -configuration Release \
        -derivedDataPath "$ROOT/.build/xcode-ferazel" build > "$LOG" 2>&1; then
    tail -n 30 "$LOG" >&2
    echo "stage-ferazel: xcodebuild failed (full log: $LOG)" >&2
    exit 1
fi

NAME="Ferazel's Wand.app"
APP="$ROOT/.build/xcode-ferazel/Build/Products/Release/$NAME"
OUT="$ROOT/out/Ferazel"
rm -rf "$OUT"
mkdir -p "$OUT"
ditto "$APP" "$OUT/$NAME"
DEST="$OUT/$NAME/Contents/Resources/Ferazel"
mkdir -p "$DEST/$MUSIC"
for f in "${FILES[@]}"; do
    cp "$DATA/$f" "$DEST/$f"
done
# The music folder as-is (01..30, 28 files); Finder litter is not game data.
rsync -a --exclude '.DS_Store' --exclude $'Icon\r' "$DATA/$MUSIC/" "$DEST/$MUSIC/"
xattr -cr "$OUT/$NAME"
# --deep is deprecated but still accepted by Xcode 27's codesign (stage-aki.sh precedent)
codesign --force --deep --sign - "$OUT/$NAME"
codesign --verify --deep "$OUT/$NAME"
cp "$ROOT/Ferazel/WHAT-TO-EXPECT.md" "$OUT/WHAT-TO-EXPECT.md"

# Icon previews for Ben's pick (gate card line 13). Icon Composer's ictool (the one on xcrun's path is actool's and
# does not export images).
ICTOOL="$(xcode-select -p)/../Applications/Icon Composer.app/Contents/Executables/ictool"
PREVIEWS="$OUT/icon-previews"
if [ -x "$ICTOOL" ]; then
    mkdir -p "$PREVIEWS"
    for r in Default Dark TintedLight TintedDark ClearLight ClearDark; do
        if ! "$ICTOOL" "$ROOT/Ferazel/App/AppIcon.icon" --export-image --output-file "$PREVIEWS/Ferazel icon - $r.png" \
                --platform macOS --rendition "$r" --width 512 --height 512 --scale 2 > /dev/null 2>&1 \
                || [ ! -s "$PREVIEWS/Ferazel icon - $r.png" ]; then
            echo "stage-ferazel: ictool could not render the $r preview (skipped)" >&2
            rm -f "$PREVIEWS/Ferazel icon - $r.png"
        fi
    done
else
    echo "stage-ferazel: Icon Composer's ictool not found at $ICTOOL — icon previews skipped" >&2
fi

if [ "${FERAZEL_STAGE_NO_DESKTOP:-0}" != "1" ]; then
    rm -rf "$HOME/Desktop/$NAME"
    ditto "$OUT/$NAME" "$HOME/Desktop/$NAME"
    ditto "$OUT/WHAT-TO-EXPECT.md" "$HOME/Desktop/Ferazel's Wand — WHAT-TO-EXPECT.md"
    if [ -d "$PREVIEWS" ]; then
        rm -rf "$HOME/Desktop/Ferazel icon previews"
        ditto "$PREVIEWS" "$HOME/Desktop/Ferazel icon previews"
        echo "desktop: $HOME/Desktop/Ferazel icon previews"
    fi
    echo "desktop: $HOME/Desktop/$NAME"
fi

echo "staged: $OUT/$NAME ($(du -sh "$DEST" | cut -f1) data)"
echo "notes:  $OUT/WHAT-TO-EXPECT.md"
[ -d "$PREVIEWS" ] && echo "icons:  $PREVIEWS"
exit 0
