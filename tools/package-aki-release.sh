#!/usr/bin/env bash
#
# tools/package-aki-release.sh — build, assemble, Developer-ID-sign, notarize + staple and DMG the public
# Aki release (Aki 1.0: the rebuild of Aki — Mahjong Solitaire 1.2.0, Remastered art included).
#
# WHAT IT IS. tools/stage-aki.sh's build/assembly shape (Release build, the ORIGINAL 1.2.0
# Contents/Resources rsync'd unchanged into the bundle, the Remaster hd-4x/ set beside it, xattrs
# stripped) turned into a release: a clean checkout is required, the app is signed inside-out with
# the hardened runtime and a secure timestamp, then notarized, stapled and wrapped in a signed +
# notarized + stapled drag-to-Applications DMG "the notarize-kit way" — this script CALLS
# ~/Developer/Toolkits/notarize-kit/notarize-bundle.sh and package-dmg.sh rather than re-implementing
# them. It ends with a GATE SUMMARY block: there is no cloud CI, so the script is its own receipt.
#
# WHY A MANIFEST. The app loads the original data from its own bundle and must replicate it 100 %,
# so the shipped data must be the original, unmodified and complete. The source data dir is first
# pinned to the known Aki 1.2 UB Contents/Resources (one sha256 over its sorted per-file manifest),
# then every file is hashed and checked against the assembled copy (check #1, before signing) and
# again against the app inside the mounted final DMG (check #3) — the DMG is what players receive.
# hd-4x/ is checked the same way against Resources/Aki/hd-4x/ (50 PNGs). .DS_Store is never shipped.
#
# NOT SHIPPED. Apple's OsakaMono.ttf (stage-aki.sh bundles it for Ben's machine only; it is not
# redistributable — the app falls back to Menlo, DECISIONS D4). The script asserts no *.ttf / *.otf
# anywhere in the bundle, on the assembled copy and on the final artifact.
#
# SIGNING happens on the assembled copy only (project.yml stays ad-hoc). No --deep for signing and
# no entitlements: nothing in the app needs one (audio playback is not a hardened-runtime exception).
#
# USAGE
#   tools/package-aki-release.sh --version 1.0 --dry-run                     # print the plan only
#   tools/package-aki-release.sh --version 1.0 --sign "Developer ID Application: …"   # sign + verify, no DMG
#   tools/package-aki-release.sh --version 1.0 --sign "Developer ID Application: …" --notarize <profile>
#
#   --version X.Y[.Z]     required; names the output (out/release/Aki-<version>.dmg)
#   --sign "<identity>"   Developer ID Application identity; required unless --dry-run
#   --notarize <profile>  `xcrun notarytool` keychain profile; without it the script stops after signing +
#                         local verification (the app is NOT notarized and no DMG is made)
#   --allow-dirty         package from a dirty working tree (refused otherwise); the summary says DIRTY
#   --skip-build          reuse the existing Release build in .build/xcode-aki-release
#   --dry-run             print the plan; build, copy, sign and write nothing
#
#   AKI_DATA_12           the original 1.2.0 Contents/Resources (default
#                         <repo>/Resources/Aki/1.2.0.app/Contents/Resources, a symlink to the original app)
#   AKI_RELEASE_TEST_TAMPER=<path under Contents/Resources>
#                         TEST ONLY: flip the first byte of that file in the ASSEMBLED copy before check #1,
#                         to prove the verbatim check fails.
#
# Output (out/ is git-ignored): out/release/Aki-<version>/{Aki.app, MANIFEST.sha256, xcodebuild log},
# and with --notarize out/release/Aki-<version>.dmg + Aki-<version>.dmg.sha256.

set -euo pipefail
export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
KIT="$HOME/Developer/Toolkits/notarize-kit"
# sha256 of the sorted "<sha256>  <relative path>" manifest of the original Aki 1.2 UB Contents/Resources
# (91 files, .DS_Store excluded) — the data this release must ship verbatim.
DATA_PIN="894325dd62304c9c1514c2dbde4f43a13dc777e6ba6bc2e9a225b3b0b1700cf8"
HD_EXPECT=50

VERSION=""
SIGN=""
NOTARIZE=""
ALLOW_DIRTY=0
SKIP_BUILD=0
DRY_RUN=0

die()   { printf '\npackage-aki-release: FAIL — %s\n' "$*" >&2; exit 1; }
step()  { printf '\n== %s\n' "$*"; }
info()  { printf '   %s\n' "$*"; }
would() { printf '   would: %s\n' "$*"; }
usage() { sed -n '3,/^# Output/p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }
need_value() { [[ $# -ge 2 && -n "$2" ]] || die "$1 needs a value (see --help)"; }

while (( $# )); do
    case "$1" in
        --version)     need_value "$@"; VERSION="$2"; shift 2 ;;
        --sign)        need_value "$@"; SIGN="$2"; shift 2 ;;
        --notarize)    need_value "$@"; NOTARIZE="$2"; shift 2 ;;
        --allow-dirty) ALLOW_DIRTY=1; shift ;;
        --skip-build)  SKIP_BUILD=1; shift ;;
        --dry-run)     DRY_RUN=1; shift ;;
        -h|--help)     usage; exit 0 ;;
        *)             die "unknown argument “$1” (see --help)" ;;
    esac
done

[[ -n "$VERSION" ]] || die "--version X.Y[.Z] is required"
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]] || die "--version must look like 1.0 or 1.0.1 (got “$VERSION”)"
if [[ -z "$SIGN" ]] && (( ! DRY_RUN )); then
    die "--sign \"Developer ID Application: …\" is required (unless --dry-run)"
fi

OUT="$ROOT/out/release"
REL="$OUT/Aki-$VERSION"
APP="$REL/Aki.app"
MANIFEST="$REL/MANIFEST.sha256"
DMG="$OUT/Aki-$VERSION.dmg"
DERIVED="$ROOT/.build/xcode-aki-release"
BUILT_APP="$DERIVED/Build/Products/Release/Aki.app"
BUILD_LOG="$ROOT/.build/package-aki-release-xcodebuild.log"
HD="$ROOT/Resources/Aki/hd-4x"

if (( DRY_RUN )); then
    printf 'package-aki-release: DRY RUN — Aki %s (nothing is built, copied, signed or written)\n' "$VERSION"
else
    printf 'package-aki-release: Aki %s\n' "$VERSION"
fi

# ── manifest helpers ────────────────────────────────────────────────────────────────────────────
# manifest_of <dir> <prefix> — "<sha256>  <prefix><relative path>" for every file, sorted, no .DS_Store.
manifest_of() {
    local dir="$1" prefix="$2" rel sum
    ( cd "$dir" && find . -type f ! -name .DS_Store -print0 ) | sort -z \
        | while IFS= read -r -d '' rel; do
            rel="${rel#./}"
            sum="$(shasum -a 256 < "$dir/$rel")"
            printf '%s  %s%s\n' "${sum%% *}" "$prefix" "$rel"
        done
}

# check_manifest <app> <label> — every manifest line must hash identically at <app>/<path>.
check_manifest() {
    local app="$1" label="$2" out
    if ! out="$(cd "$app" && grep -v '^#' "$MANIFEST" | shasum -a 256 -c --quiet 2>&1)"; then
        printf '%s\n' "$out" | head -n 40 >&2
        die "VERBATIM CHECK FAILED ($label) — the bundle's data is not a byte-identical, complete copy"
    fi
}

no_fonts() {
    local hit
    hit="$(find "$1" -type f \( -iname '*.ttf' -o -iname '*.otf' \) -print -quit)"
    [[ -z "$hit" ]] || die "a font file is in the bundle ($hit) — Apple's fonts are not redistributable (D4)"
}

# ── 1. Inputs ───────────────────────────────────────────────────────────────────────────────────
step "inputs"
PROBLEMS=()
problem() { if (( DRY_RUN )); then info "PROBLEM (a real run would stop): $*"; PROBLEMS+=("$*"); else die "$*"; fi; }

DATA="${AKI_DATA_12:-$ROOT/Resources/Aki/1.2.0.app/Contents/Resources}"
DATA_OK=0
if [[ -f "$DATA/map.png" ]]; then
    DATA="$(cd "$DATA" && pwd -P)"
    DATA_OK=1
    info "data: $DATA"
else
    problem "no Aki 1.2.0 Contents/Resources at $DATA (no map.png; set AKI_DATA_12)"
fi
if (( DATA_OK )); then
    RSRC="$(find "$DATA" -type f ! -name .DS_Store -exec sh -c 'for f; do if [ -s "$f/..namedfork/rsrc" ]; then echo "$f"; fi; done' _ {} + | head -n 1)"
    [[ -z "$RSRC" ]] || problem "a data file carries a resource fork ($RSRC); xattr -cr / codesign would drop it"
    DATA_MANIFEST="$(manifest_of "$DATA" "")"
    DATA_FILES="$(printf '%s\n' "$DATA_MANIFEST" | wc -l | tr -d ' ')"
    GOT_PIN="$(printf '%s\n' "$DATA_MANIFEST" | shasum -a 256)"; GOT_PIN="${GOT_PIN%% *}"
    if [[ "$GOT_PIN" == "$DATA_PIN" ]]; then
        info "data pin: OK — $DATA_FILES files are the original Aki 1.2 UB Contents/Resources"
    else
        problem "data pin mismatch: $DATA ($DATA_FILES files) is not the original Aki 1.2 UB Contents/Resources (manifest sha256 $GOT_PIN, expected $DATA_PIN)"
    fi
fi

if [[ -d "$HD" ]]; then
    HD_FILES="$(find "$HD" -type f -name '*.png' | wc -l | tr -d ' ')"
    [[ "$HD_FILES" == "$HD_EXPECT" ]] || problem "Resources/Aki/hd-4x holds $HD_FILES PNGs, expected $HD_EXPECT"
    if CHECK_OUT="$(cd "$ROOT" && python3 tools/upscale-aki-art.py --check 2>&1)"; then
        info "remaster: $HD — $(printf '%s\n' "$CHECK_OUT" | tail -n 1)"
    else
        printf '%s\n' "$CHECK_OUT" | tail -n 20 >&2
        problem "python3 tools/upscale-aki-art.py --check failed — Remastered art is part of this release"
    fi
else
    problem "no $HD — run python3 tools/upscale-aki-art.py (Remastered art is part of this release)"
fi

GIT_SHA="$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null)" || die "not a git checkout: $ROOT"
TREE="clean"
if [[ -n "$(git -C "$ROOT" status --porcelain)" ]]; then
    if (( ALLOW_DIRTY )); then
        TREE="DIRTY, allowed by --allow-dirty"
    elif (( DRY_RUN )); then
        TREE="DIRTY — a real run would REFUSE (commit first, or pass --allow-dirty)"
    else
        git -C "$ROOT" status --short >&2
        die "the working tree is dirty — commit first, or pass --allow-dirty"
    fi
fi
info "git $GIT_SHA · tree $TREE"

if [[ -n "$NOTARIZE" ]]; then
    for s in notarize-bundle.sh package-dmg.sh; do
        [[ -x "$KIT/$s" ]] || problem "notarize-kit script missing or not executable: $KIT/$s"
    done
    command -v create-dmg >/dev/null 2>&1 || problem "create-dmg missing (brew install create-dmg)"
fi
if [[ -n "$SIGN" ]] && (( ! DRY_RUN )); then
    security find-identity -v -p codesigning | grep -q -F "\"$SIGN\"" \
        || die "signing identity not found in the keychain: $SIGN"
fi

# ── Dry run stops here ──────────────────────────────────────────────────────────────────────────
if (( DRY_RUN )); then
    step "plan"
    if (( SKIP_BUILD )); then would "reuse $BUILT_APP"
    else
        would "xcodegen generate --quiet"
        would "xcodebuild -project AmbrosiaClassics.xcodeproj -scheme Aki -configuration Release -derivedDataPath $DERIVED build  (log $BUILD_LOG)"
    fi
    would "report lipo -archs of the Aki executable"
    would "wipe $REL/; ditto the app to $APP"
    would "rsync the data (no .DS_Store) into Contents/Resources/; rsync --delete hd-4x into Contents/Resources/hd-4x/"
    would "assert no *.ttf/*.otf (OsakaMono is NOT shipped, D4); xattr -cr"
    would "verbatim check #1: data + hd-4x sha256 vs the assembled copy → $MANIFEST"
    would "codesign --force --options runtime --timestamp --sign \"${SIGN:-<identity>}\" — nested code first, then the app (no --deep, no entitlements)"
    would "codesign --verify --deep --strict --verbose=2; codesign -dv (Authority, flags=runtime, Timestamp)"
    if [[ -n "$NOTARIZE" ]]; then
        would "$KIT/notarize-bundle.sh \"$APP\" \"$NOTARIZE\""
        would "$KIT/package-dmg.sh \"$APP\" \"${SIGN:-<identity>}\" \"$NOTARIZE\" \"<data>/aki.icns\" → $DMG (+ .sha256)"
        would "mount the DMG read-only: stapler validate, spctl execute, codesign verify, verbatim check #3, no fonts; stapler + spctl open on the DMG"
    else
        would "stop after signing: NOT notarized, no DMG (pass --notarize <profile>)"
    fi
    if (( ${#PROBLEMS[@]} )); then
        printf '\npackage-aki-release: DRY RUN complete — %d problem(s) above would stop a real run.\n' "${#PROBLEMS[@]}"
    else
        printf '\npackage-aki-release: DRY RUN complete — nothing was built, copied or written.\n'
    fi
    exit 0
fi

MNT=""
cleanup() {
    if [[ -n "$MNT" ]]; then
        hdiutil detach "$MNT" -quiet >/dev/null 2>&1 || hdiutil detach "$MNT" -force >/dev/null 2>&1 || true
        rmdir "$MNT" 2>/dev/null || true
    fi
}
trap cleanup EXIT

# ── 2. Build ────────────────────────────────────────────────────────────────────────────────────
step "build"
mkdir -p "$ROOT/.build"
if (( SKIP_BUILD )); then
    info "reusing $BUILT_APP (--skip-build)"
else
    ( cd "$ROOT" && xcodegen generate --quiet ) || die "xcodegen generate failed"
    info "building Release (log: $BUILD_LOG) …"
    if ! ( cd "$ROOT" && xcodebuild -project AmbrosiaClassics.xcodeproj -scheme Aki -configuration Release \
            -derivedDataPath "$DERIVED" build ) > "$BUILD_LOG" 2>&1; then
        tail -n 30 "$BUILD_LOG" >&2
        die "xcodebuild failed (full log: $BUILD_LOG)"
    fi
fi
[[ -d "$BUILT_APP" ]] || die "no built app at $BUILT_APP"
EXE_NAME="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$BUILT_APP/Contents/Info.plist")" \
    || die "the built app's Info.plist has no CFBundleExecutable"
ARCHS="$(lipo -archs "$BUILT_APP/Contents/MacOS/$EXE_NAME")" || die "lipo cannot read the Aki executable"
BUNDLE_VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$BUILT_APP/Contents/Info.plist" 2>/dev/null || echo '?')"
info "app: $BUILT_APP"
info "archs: $ARCHS · Info.plist CFBundleShortVersionString $BUNDLE_VERSION"

# ── 3. Assemble ─────────────────────────────────────────────────────────────────────────────────
step "assemble"
rm -rf "$REL"
mkdir -p "$REL"
rm -f "$DMG" "$DMG.sha256"
ditto "$BUILT_APP" "$APP"
mkdir -p "$APP/Contents/Resources"
rsync -a --exclude '.DS_Store' "$DATA/" "$APP/Contents/Resources/"
rsync -a --delete --exclude '.DS_Store' "$HD/" "$APP/Contents/Resources/hd-4x/"
no_fonts "$APP"
xattr -cr "$APP"
cp "$BUILD_LOG" "$REL/" 2>/dev/null || true
info "$APP — no font files; xattrs cleared"

# ── 4. Verbatim check #1 ────────────────────────────────────────────────────────────────────────
step "verbatim check #1 (source → assembled copy)"
{
    printf '# Aki %s — shipped original data + Remaster art, sha256, paths relative to Aki.app\n' "$VERSION"
    printf '# made by tools/package-aki-release.sh at git %s from %s and Resources/Aki/hd-4x\n' "$GIT_SHA" "$DATA"
    printf '%s\n' "$DATA_MANIFEST" | sed 's#  #  Contents/Resources/#'
    manifest_of "$HD" "Contents/Resources/hd-4x/"
} > "$MANIFEST"

if [[ -n "${AKI_RELEASE_TEST_TAMPER:-}" ]]; then
    target="$APP/Contents/Resources/$AKI_RELEASE_TEST_TAMPER"
    [[ -s "$target" ]] || die "TEST TAMPER: nothing to alter at $target"
    byte="$(head -c 1 "$target" | od -An -tu1 | tr -d ' ')"
    # shellcheck disable=SC2059  # the format IS the octal escape being written
    printf "\\$(printf '%03o' $(( (byte + 1) % 256 )))" | dd of="$target" bs=1 count=1 conv=notrunc 2>/dev/null
    info "TEST TAMPER: altered the first byte of Contents/Resources/$AKI_RELEASE_TEST_TAMPER"
fi

check_manifest "$APP" "#1, assembled copy"
BUNDLE_HD="$(find "$APP/Contents/Resources/hd-4x" -type f -name '*.png' | wc -l | tr -d ' ')"
[[ "$BUNDLE_HD" == "$HD_EXPECT" ]] || die "the bundle's hd-4x holds $BUNDLE_HD PNGs, expected $HD_EXPECT"
info "data: $DATA_FILES files identical · hd-4x: $BUNDLE_HD PNGs identical · manifest $MANIFEST"

# ── 5. Sign inside-out ──────────────────────────────────────────────────────────────────────────
step "sign"
sign() { codesign --force --options runtime --timestamp --sign "$SIGN" "$1" || die "codesign failed on $1"; }
MAIN_EXE="$APP/Contents/MacOS/$EXE_NAME"
NESTED=()
# Loose Mach-O files (exec bit + `file` says Mach-O; the original's .aiff/.mp3/.icns carry exec bits too),
# deepest first, skipping the main executable and anything inside a nested bundle (signed as a bundle).
# loose_macho — NUL-separated candidates on stdin → "<depth>\t<path>" lines for the loose Mach-O files.
loose_macho() {
    local f slashes
    while IFS= read -r -d '' f; do
        [[ "$f" == "$MAIN_EXE" ]] && continue
        if [[ "$f" == *.framework/* || "$f" == *.appex/* || "$f" == *.xpc/* || "$f" == *.bundle/* \
              || "$f" == */Contents/*.app/* ]]; then continue; fi
        file -b "$f" | grep -q 'Mach-O' || continue
        slashes="${f//[^\/]/}"
        printf '%d\t%s\n' "${#slashes}" "$f"
    done
}
while IFS= read -r f; do
    [[ -n "$f" ]] && NESTED+=("$f")
done < <(find "$APP/Contents" -type f \( -perm +111 -o -name '*.dylib' -o -name '*.so' \) -print0 \
            | loose_macho | sort -rn | cut -f 2-)
for d in Frameworks PlugIns XPCServices; do
    [[ -d "$APP/Contents/$d" ]] || continue
    while IFS= read -r -d '' b; do NESTED+=("$b"); done \
        < <(find "$APP/Contents/$d" -mindepth 1 -maxdepth 1 \( -name '*.framework' -o -name '*.appex' -o -name '*.xpc' -o -name '*.bundle' -o -name '*.app' \) -print0)
done
if (( ${#NESTED[@]} )); then
    for n in "${NESTED[@]}"; do info "nested: ${n#"$APP/"}"; sign "$n"; done
else
    info "nested code: none (SwiftPM packages are linked statically into the executable)"
fi
sign "$APP"
codesign --verify --deep --strict --verbose=2 "$APP" 2>&1 | sed 's/^/   /' \
    || die "codesign --verify --deep --strict failed on $APP"
SIG="$(codesign -dv --verbose=4 "$APP" 2>&1)"
printf '%s\n' "$SIG" | grep -E '^(Identifier=|Format=|CodeDirectory |Authority=|Timestamp=|TeamIdentifier=|Runtime Version=)' | sed 's/^/   /'
printf '%s\n' "$SIG" | grep -q '^Authority=Developer ID Application' || die "not signed by a Developer ID Application identity"
printf '%s\n' "$SIG" | grep -E '^CodeDirectory' | grep -q 'runtime' || die "the hardened runtime flag is missing"
printf '%s\n' "$SIG" | grep -q '^Timestamp=' || die "no secure timestamp in the signature"
check_manifest "$APP" "#2, after signing"
no_fonts "$APP"
info "signed: $SIGN — hardened runtime, secure timestamp, verify --deep --strict OK, data still verbatim"

# ── 6 + 7. Notarize, DMG, final check ───────────────────────────────────────────────────────────
NOTARIZED="no"
DMG_LINE="(none — not notarized; pass --notarize <profile>)"
DMG_SHA="-"
if [[ -n "$NOTARIZE" ]]; then
    step "notarize (notarize-kit)"
    "$KIT/notarize-bundle.sh" "$APP" "$NOTARIZE" || die "notarize-bundle.sh failed"
    step "dmg (notarize-kit)"
    "$KIT/package-dmg.sh" "$APP" "$SIGN" "$NOTARIZE" "$DATA/aki.icns" || die "package-dmg.sh failed"
    [[ -f "$REL/Aki.dmg" ]] || die "package-dmg.sh produced no $REL/Aki.dmg"
    mv "$REL/Aki.dmg" "$DMG"
    ( cd "$OUT" && shasum -a 256 "Aki-$VERSION.dmg" ) > "$DMG.sha256"
    DMG_SHA="$(cut -d ' ' -f 1 < "$DMG.sha256")"
    NOTARIZED="yes (app + DMG accepted, tickets stapled)"

    step "final check (the DMG players download)"
    MNT="$(mktemp -d "${TMPDIR:-/tmp}/aki-release-mnt.XXXXXX")"
    hdiutil attach -nobrowse -readonly -noautoopen -mountpoint "$MNT" "$DMG" >/dev/null || die "hdiutil attach failed"
    FAPP="$MNT/Aki.app"
    [[ -d "$FAPP" ]] || die "the DMG has no Aki.app at its root"
    xcrun stapler validate "$FAPP" >/dev/null || die "stapler validate failed on the app inside the DMG"
    spctl --assess --type execute -vv "$FAPP" 2>&1 | sed 's/^/   /'
    spctl --assess --type execute "$FAPP" 2>/dev/null || die "Gatekeeper rejects the app inside the DMG"
    codesign --verify --deep --strict "$FAPP" || die "codesign --verify failed on the app inside the DMG"
    check_manifest "$FAPP" "#3, app inside the DMG"
    no_fonts "$FAPP"
    FINAL_HD="$(find "$FAPP/Contents/Resources/hd-4x" -type f -name '*.png' | wc -l | tr -d ' ')"
    [[ "$FINAL_HD" == "$HD_EXPECT" ]] || die "the DMG's app holds $FINAL_HD hd-4x PNGs, expected $HD_EXPECT"
    cleanup; MNT=""
    xcrun stapler validate "$DMG" >/dev/null || die "stapler validate failed on the DMG"
    spctl --assess --type open --context context:primary-signature -vv "$DMG" 2>&1 | sed 's/^/   /'
    spctl --assess --type open --context context:primary-signature "$DMG" 2>/dev/null \
        || die "Gatekeeper rejects the DMG"
    DMG_LINE="$DMG ($(du -h "$DMG" | cut -f 1 | tr -d ' '))"
    info "inside the DMG: stapled, Gatekeeper-accepted, signature intact, data verbatim, no fonts"
fi

# ── 8. Gate summary ─────────────────────────────────────────────────────────────────────────────
NEXT=""
[[ -n "$NOTARIZE" ]] || NEXT="NOT NOTARIZED — signed + verified locally only; no DMG was made"
cat <<SUMMARY

=== GATE SUMMARY — Aki $VERSION ===
version         $VERSION (Info.plist CFBundleShortVersionString $BUNDLE_VERSION)
git sha         $GIT_SHA ($TREE)
archs           $ARCHS
signed as       $SIGN (hardened runtime, secure timestamp)
notarized       $NOTARIZED
data files      $DATA_FILES verified verbatim (pinned to the original Aki 1.2 UB Contents/Resources)
hd-4x           $BUNDLE_HD PNGs verified verbatim (upscale-aki-art.py --check OK)
fonts           none bundled (OsakaMono not shipped, D4)
manifest        $MANIFEST
dmg             $DMG_LINE
dmg sha256      $DMG_SHA
=== END GATE SUMMARY ===
SUMMARY
[[ -z "$NEXT" ]] || printf '\npackage-aki-release: %s\n' "$NEXT"
