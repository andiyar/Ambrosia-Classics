#!/bin/zsh
# tools/windows/stage-btx.sh [--package DIR] [--resources DIR] [--out DIR] [--no-desktop] [--no-icon]
# Plan W7: stages Bubble Trouble X for Windows as a plain folder (no installer, no signing, nothing uploaded):
#
#   <out>/Bubble Trouble X.exe     release cross-build of BubbleTroubleXWin, GUI subsystem (no console window)
#   <out>/*.dll                    every DLL it imports, recursively (PE import tables read with llvm-objdump),
#                                  resolved from the Swift runtime dir ($WIN_RUNTIME, which also holds Microsoft's
#                                  redistributable vcruntime140*/msvcp140* — D15) and SDL3; Windows' own DLLs are not
#                                  shipped (list printed; see SYSTEM_DLLS below)
#   <out>/Data/                    the five original .rsrc files (D10), Fonts/*.btxfont, Decoded/*.rgba (regenerated
#                                  here by btx-predecode — D16.1, D18.3)
#   <out>/WHAT-TO-EXPECT.txt       docs/bubble-trouble/WINDOWS-WHAT-TO-EXPECT.md, CRLF, markup stripped
#
# then (unless --no-desktop) copies it to ~/Desktop/Bubble Trouble X (Windows)/ and zips that to
# ~/Desktop/Bubble Trouble X (Windows).zip (the zip holds the folder). Nothing else on the Desktop is touched.
#
#   --package   the BubbleTroubleX/Windows package to build (default: this repo's). Pass a mirror when the build must
#               see a HectorKit other than the shared symlink's (SwiftPM resolves path dependencies by realpath).
#   --resources the 1.1 UB `Bubble Trouble X.app/Contents/Resources` (default: the archive mirror's copy)
#   --out       default <repo>/out/Windows/Bubble Trouble X (out/ is git-ignored)
#   --no-icon   skip the icon + version resource (it needs mingw's windres: brew mingw-w64; skipped if missing)
#
# GUI subsystem: linked with /SUBSYSTEM:WINDOWS and /ENTRY:mainCRTStartup — the CRT's console entry point, which
# calls Swift's `main` (no WinMain needed); only the PE header's subsystem changes, so Windows opens no console.
set -euo pipefail
here="${0:A:h}"
repo="${here:h:h}"
. "$here/env.sh"

pkg="$repo/BubbleTroubleX/Windows"
res="$HOME/Developer/Ambrosia/Resources/ambrosia-extracted/Action-Adventure/Bubble Trouble X/BubbleTroubleX_1.1_UB/Bubble Trouble X.app/Contents/Resources"
out="$repo/out/Windows/Bubble Trouble X"
desktop=1; icon=1
while (( $# )); do
    case "$1" in
        --package) pkg="${2:A}"; shift ;;
        --resources) res="$2"; shift ;;
        --out) out="${2:A}"; shift ;;
        --no-desktop) desktop=0 ;;
        --no-icon) icon=0 ;;
        *) print -u2 "usage: $0 [--package DIR] [--resources DIR] [--out DIR] [--no-desktop] [--no-icon]"; exit 64 ;;
    esac
    shift
done
[[ -f "$pkg/Package.swift" ]] || { print -u2 "stage-btx: no package at $pkg"; exit 66; }
[[ -f "$res/Bubble Trouble X.rsrc" ]] || { print -u2 "stage-btx: no BTX 1.1 resources at $res"; exit 66; }
objdump="$WIN_TOOLCHAIN/usr/bin/llvm-objdump"
[[ -x "$objdump" ]] || { print -u2 "stage-btx: no llvm-objdump in $WIN_TOOLCHAIN — run setup-toolchain.sh"; exit 69; }

work="$WIN_CROSS/work/stage-btx"            # no spaces: the .res path goes to lld-link verbatim
rm -rf "$work"; mkdir -p "$work"
stamp="$(git -C "$repo" rev-parse --short HEAD 2>/dev/null || print unknown)"
date_built="$(date +%Y-%m-%d)"

# ---- Icon + version info (optional) -------------------------------------------------------------------
link=(-Xlinker /SUBSYSTEM:WINDOWS -Xlinker /ENTRY:mainCRTStartup)
windres="$(command -v x86_64-w64-mingw32-windres || true)"
if (( icon )) && [[ -z "$windres" ]]; then
    print -u2 "stage-btx: no x86_64-w64-mingw32-windres (brew mingw-w64): staging without an icon"; icon=0
fi
if (( icon )); then
    # The app's own icon (BubbleTrouble.icns) → a PNG-entry .ico (16, 32, 48, 256), then an .rc → .res for lld-link.
    iconutil -c iconset -o "$work/btx.iconset" "$res/BubbleTrouble.icns"
    # (the 2008 .icns carries 16, 32, 48, 128, 256 and 512 px images; 48 is made from 128 if ever absent)
    i48="$work/btx.iconset/icon_48x48.png"
    [[ -f "$i48" ]] || sips -z 48 48 "$work/btx.iconset/icon_128x128.png" --out "$i48" >/dev/null
    python3 - "$work/btx.ico" "$work/btx.iconset/icon_16x16.png" "$work/btx.iconset/icon_32x32.png" \
        "$i48" "$work/btx.iconset/icon_256x256.png" <<'PY'
import struct, sys
out, pngs = sys.argv[1], sys.argv[2:]
blobs = [open(p, "rb").read() for p in pngs]
sizes = [struct.unpack(">II", b[16:24]) for b in blobs]          # PNG IHDR width, height
head = struct.pack("<HHH", 0, 1, len(blobs))
offset = 6 + 16 * len(blobs)
entries = b""
for (w, h), b in zip(sizes, blobs):
    entries += struct.pack("<BBBBHHII", w % 256, h % 256, 0, 0, 1, 32, len(b), offset)
    offset += len(b)
open(out, "wb").write(head + entries + b"".join(blobs))
PY
    cat > "$work/btx.rc" <<RC
1 ICON "btx.ico"
1 VERSIONINFO
FILEVERSION 1,1,0,0
PRODUCTVERSION 1,1,0,0
FILEOS 0x40004
FILETYPE 0x1
BEGIN
  BLOCK "StringFileInfo"
  BEGIN
    BLOCK "040904B0"
    BEGIN
      VALUE "CompanyName", "Ambrosia Classics (non-commercial preservation)"
      VALUE "FileDescription", "Bubble Trouble X"
      VALUE "FileVersion", "1.1 (Windows build $date_built, $stamp)"
      VALUE "InternalName", "BubbleTroubleXWin"
      VALUE "LegalCopyright", "Bubble Trouble X (c) Ambrosia Software"
      VALUE "OriginalFilename", "Bubble Trouble X.exe"
      VALUE "ProductName", "Bubble Trouble X"
      VALUE "ProductVersion", "1.1"
    END
  END
  BLOCK "VarFileInfo"
  BEGIN
    VALUE "Translation", 0x409, 1200
  END
END
RC
    (cd "$work" && "$windres" --target=pe-x86-64 -O res -i btx.rc -o btx.res)
    link+=(-Xlinker "$work/btx.res")
fi

# ---- Release cross-build -------------------------------------------------------------------------------
build_root="$WIN_CROSS/build/stage"
WIN_SWIFT_FLAGS="" WIN_BUILD_ROOT="$build_root" "$here/build.sh" "$pkg" BubbleTroubleXWin --sdl --release -- $link >&2
bin="$build_root/${pkg:t}/$WIN_TRIPLE/release"
[[ -f "$bin/BubbleTroubleXWin.exe" ]] || { print -u2 "stage-btx: the build produced no BubbleTroubleXWin.exe"; exit 70; }
subsystem="$("$objdump" -p "$bin/BubbleTroubleXWin.exe" | awk '/^Subsystem/ {print $2}')"
[[ "$subsystem" == <-> ]] && (( 10#$subsystem == 2 )) || { print -u2 "stage-btx: subsystem is '$subsystem', not 2 (Windows GUI)"; exit 70; }

rm -rf "$out"; mkdir -p "$out/Data"
cp "$bin/BubbleTroubleXWin.exe" "$out/Bubble Trouble X.exe"

# ---- DLLs: walk the import tables ------------------------------------------------------------------------
# Windows' own DLLs. ucrtbase (+ its api-ms-win-crt-* API sets) is part of Windows 10 and later; the rest are core
# system libraries. Anything imported that is neither found in the search dirs nor listed here stops the staging.
SYSTEM_DLLS=(kernel32 user32 gdi32 advapi32 shell32 ole32 oleaut32 imm32 winmm version setupapi cfgmgr32 ws2_32
             bcrypt bcryptprimitives ntdll shlwapi rpcrt4 dbghelp crypt32 secur32 userenv mswsock iphlpapi combase
             dwmapi dxgi d3d11 d3d12 dinput8 hid uxtheme ucrtbase msvcrt synchronization powrprof netapi32 winhttp
             mpr ncrypt normaliz psapi comdlg32 comctl32 shcore winspool)
search=("$WIN_RUNTIME" "$WIN_SDL3/lib/x64")
typeset -A shipped excluded
queue=("$out/Bubble Trouble X.exe")
while (( ${#queue} )); do
    file="${queue[1]}"; queue=("${(@)queue[2,-1]}")
    for dll in ${(f)"$("$objdump" -p "$file" | awk '/DLL Name:/ {print $3}')"}; do
        lower="${dll:l}"
        [[ -n "${shipped[$lower]:-}" || -n "${excluded[$lower]:-}" ]] && continue
        found=""
        for d in $search; do
            for f in "$d"/*(N.); do [[ "${f:t:l}" == "$lower" ]] && { found="$f"; break 2; }; done
        done
        if [[ -n "$found" ]]; then
            shipped[$lower]="${found:t}"
            cp "$found" "$out/"
            queue+=("$out/${found:t}")
        elif [[ "$lower" == api-ms-win-* || "$lower" == ext-ms-* ]]; then
            excluded[$lower]="API set (resolved by Windows itself)"
        elif (( ${SYSTEM_DLLS[(Ie)${lower%.dll}]} )); then
            excluded[$lower]="Windows system DLL"
        else
            print -u2 "stage-btx: $dll (imported by ${file:t}) is neither in ${search[*]} nor a known system DLL"
            exit 70
        fi
    done
done
print "Shipped DLLs (${#shipped}):"
for k in ${(ok)shipped}; do print "  ${shipped[$k]}"; done
print "Not shipped (${#excluded}):"
for k in ${(ok)excluded}; do print "  $k — ${excluded[$k]}"; done

# ---- Data ----------------------------------------------------------------------------------------------
for f in "Bubble Trouble X.rsrc" "BT Levels.rsrc" "BT Sprites.rsrc" "BT Sounds.rsrc" "BT Titles.rsrc"; do
    cp "$res/$f" "$out/Data/"
done
mkdir -p "$out/Data/Fonts"
cp "$pkg/Resources/Fonts/"*.btxfont "$out/Data/Fonts/"
# Pre-decoded JPEG bands, regenerated on this Mac (D18.3). The Mac tool builds against the brew SDL / Mac host.
swift build --package-path "$pkg" -c release --product btx-predecode > "$work/predecode-build.log" 2>&1 || {
    cat "$work/predecode-build.log" >&2; print -u2 "stage-btx: btx-predecode did not build"; exit 70; }
"$(swift build --package-path "$pkg" -c release --show-bin-path)/btx-predecode" "$res" "$out/Data/Decoded" | tail -1

# ---- What to expect ----------------------------------------------------------------------------------------
python3 - "$repo/docs/bubble-trouble/WINDOWS-WHAT-TO-EXPECT.md" "$out/WHAT-TO-EXPECT.txt" <<'PY'
import re, sys
text = open(sys.argv[1], encoding="utf-8").read()
text = re.sub(r"\*\*(.+?)\*\*", r"\1", text)        # bold
text = text.replace("`", "")
text = re.sub(r"^#+ ", "", text, flags=re.M)
# UTF-8 with a BOM, CRLF: what every Notepad (old ones included) opens correctly.
open(sys.argv[2], "w", encoding="utf-8-sig", newline="").write(text.replace("\r\n", "\n").replace("\n", "\r\n"))
PY
xattr -cr "$out"
print "Staged: $out ($(du -sh "$out" | cut -f1))"

# ---- Desktop copy + zip --------------------------------------------------------------------------------------
if (( desktop )); then
    name="Bubble Trouble X (Windows)"
    dest="$HOME/Desktop/$name"
    rm -rf "$dest" "$dest.zip"
    cp -R "$out" "$dest"
    (cd "$HOME/Desktop" && zip -q -r -X "$name.zip" "$name" -x '*.DS_Store')
    print "Desktop: $dest ($(du -sh "$dest" | cut -f1)), $dest.zip ($(du -h "$dest.zip" | cut -f1))"
fi
