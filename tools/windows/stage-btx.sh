#!/bin/zsh
# tools/windows/stage-btx.sh [--package DIR] [--resources DIR] [--out DIR] [--no-desktop] [--no-icon] [--allow-dirty]
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
# then (unless --no-desktop) copies it to ~/Desktop/Bubble Trouble X (Windows)/ and zips that folder's CONTENTS to
# ~/Desktop/Bubble Trouble X (Windows).zip: the game files sit at the zip's root, so Windows' "Extract All" (which makes
# a folder named after the zip) gives exactly one "Bubble Trouble X (Windows)\" level. Nothing else on the Desktop is
# touched.
#
# Committed content only: the repo (and the HectorKit checkout the package builds against) must have no uncommitted or
# untracked changes, so the version stamp ("<classics sha>, HectorKit <sha>") names exactly what was built.
# --allow-dirty stages anyway and stamps "<sha>-dirty".
#
#   --package   the BubbleTroubleX/Windows package to build (default: this repo's). Pass a mirror when the build must
#               see a HectorKit other than the shared symlink's (SwiftPM resolves path dependencies by realpath).
#   --resources the 1.1 UB `Bubble Trouble X.app/Contents/Resources` (default: the archive mirror's copy)
#   --out       default <repo>/out/Windows/Bubble Trouble X (out/ is git-ignored). It is deleted and rebuilt, so it must
#               be inside <repo>/out/ or be a folder named "Bubble Trouble X" (and never $HOME, the Desktop, /, …)
#   --no-icon   skip the icon + version info (the application manifest is always embedded)
#
# Resources (mingw's windres, brew mingw-w64 — required): the application manifest (Per-Monitor-V2 DPI awareness, the
# same SDL3 asks for at video init, so it holds from process start; Windows 10/11; asInvoker), the icon and version info.
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
desktop=1; icon=1; allow_dirty=0
while (( $# )); do
    case "$1" in
        --package) pkg="${2:A}"; shift ;;
        --resources) res="$2"; shift ;;
        --out) out="${2:A}"; shift ;;
        --no-desktop) desktop=0 ;;
        --no-icon) icon=0 ;;
        --allow-dirty) allow_dirty=1 ;;
        *) print -u2 "usage: $0 [--package DIR] [--resources DIR] [--out DIR] [--no-desktop] [--no-icon] [--allow-dirty]"
           exit 64 ;;
    esac
    shift
done
[[ -f "$pkg/Package.swift" ]] || { print -u2 "stage-btx: no package at $pkg"; exit 66; }
[[ -f "$res/Bubble Trouble X.rsrc" ]] || { print -u2 "stage-btx: no BTX 1.1 resources at $res"; exit 66; }
# --out is rm -rf'd below: only a staging folder may be replaced.
case "$out" in
    /|"$HOME"|"${HOME:h}"|"$HOME/Desktop"|"$HOME/Developer"|"$repo"|"$repo/out"|"$repo/out/Windows")
        print -u2 "stage-btx: refusing --out $out (it would be deleted)"; exit 64 ;;
esac
if [[ "$out" != "$repo/out/"* && "${out:t}" != "Bubble Trouble X" ]]; then
    print -u2 "stage-btx: --out must be inside $repo/out/ or be a folder named \"Bubble Trouble X\" (it is deleted first): $out"
    exit 64
fi
objdump="$WIN_TOOLCHAIN/usr/bin/llvm-objdump"
[[ -x "$objdump" ]] || { print -u2 "stage-btx: no llvm-objdump in $WIN_TOOLCHAIN — run setup-toolchain.sh"; exit 69; }

work="$WIN_CROSS/work/stage-btx"            # no spaces: the .res path goes to lld-link verbatim
rm -rf "$work"; mkdir -p "$work"
# Version stamp from committed content (see the header).
hk="${pkg}/../../../HectorKit"; hk="${hk:A}"
stamp_of() {    # <git dir> <label>
    local sha dirty=""
    sha="$(git -C "$1" rev-parse --short HEAD 2>/dev/null)" || { print -u2 "stage-btx: $1 is not a git checkout"; exit 66; }
    if [[ -n "$(git -C "$1" status --porcelain 2>/dev/null)" ]]; then
        if (( allow_dirty )); then
            dirty="-dirty"
        else
            print -u2 "stage-btx: $2 ($1) has uncommitted or untracked changes — commit them (or --allow-dirty):"
            git -C "$1" status --short >&2
            exit 65
        fi
    fi
    print -r -- "$sha$dirty"
}
stamp="$(stamp_of "$repo" "the repo")"
if [[ -d "$hk" ]]; then hk_stamp="$(stamp_of "$hk" "HectorKit")"; stamp="$stamp, HectorKit $hk_stamp"; fi
print "Version stamp: $stamp"
date_built="$(date +%Y-%m-%d)"

# ---- Resources: manifest (always), icon + version info (unless --no-icon) ---------------------------------
link=(-Xlinker /SUBSYSTEM:WINDOWS -Xlinker /ENTRY:mainCRTStartup)
windres="$(command -v x86_64-w64-mingw32-windres || true)"
[[ -n "$windres" ]] || { print -u2 "stage-btx: no x86_64-w64-mingw32-windres (brew install mingw-w64)"; exit 69; }
# Per-Monitor-V2 DPI awareness from process start (SDL3 sets the same at video init — SetProcessDpiAwarenessContext —
# so window sizes, which SDL keeps in pixels on Windows, are unchanged); Windows 10/11; no elevation.
cat > "$work/btx.manifest" <<'XML'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<assembly xmlns="urn:schemas-microsoft-com:asm.v1" manifestVersion="1.0">
  <assemblyIdentity type="win32" name="AmbrosiaClassics.BubbleTroubleX" version="1.1.0.0" processorArchitecture="amd64"/>
  <trustInfo xmlns="urn:schemas-microsoft-com:asm.v3">
    <security>
      <requestedPrivileges>
        <requestedExecutionLevel level="asInvoker" uiAccess="false"/>
      </requestedPrivileges>
    </security>
  </trustInfo>
  <compatibility xmlns="urn:schemas-microsoft-com:compatibility.v1">
    <application>
      <!-- Windows 10 and 11 -->
      <supportedOS Id="{8e0f7a12-bfb3-4fe8-b9a5-48fd50a15a9a}"/>
    </application>
  </compatibility>
  <application xmlns="urn:schemas-microsoft-com:asm.v3">
    <windowsSettings>
      <dpiAware xmlns="http://schemas.microsoft.com/SMI/2005/WindowsSettings">true/pm</dpiAware>
      <dpiAwareness xmlns="http://schemas.microsoft.com/SMI/2016/WindowsSettings">PerMonitorV2, PerMonitor</dpiAwareness>
    </windowsSettings>
  </application>
</assembly>
XML
print '1 24 "btx.manifest"' > "$work/btx.rc"     # CREATEPROCESS_MANIFEST_RESOURCE_ID, RT_MANIFEST
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
    cat >> "$work/btx.rc" <<RC
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
fi
(cd "$work" && "$windres" --target=pe-x86-64 -O res -i btx.rc -o btx.res)
link+=(-Xlinker "$work/btx.res")

# ---- Release cross-build -------------------------------------------------------------------------------
build_root="$WIN_CROSS/build/stage"
rm -rf "$build_root"      # a clean release build every time (a stale one may point at another package's sources)
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
        # Windows' own DLLs are never shipped, even when a search dir holds a copy (checked before the search).
        if [[ "$lower" == api-ms-win-* || "$lower" == ext-ms-* ]]; then
            excluded[$lower]="API set (resolved by Windows itself)"; continue
        elif (( ${SYSTEM_DLLS[(Ie)${lower%.dll}]} )); then
            excluded[$lower]="Windows system DLL"; continue
        fi
        found=""
        for d in $search; do
            for f in "$d"/*(N.); do [[ "${f:t:l}" == "$lower" ]] && { found="$f"; break 2; }; done
        done
        if [[ -n "$found" ]]; then
            shipped[$lower]="${found:t}"
            cp "$found" "$out/"
            queue+=("$out/${found:t}")
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
[[ -s "$out/Data/Decoded/manifest.txt" ]] || { print -u2 "stage-btx: btx-predecode wrote no Decoded/manifest.txt"; exit 70; }

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
    # The folder's contents at the zip root: "Extract All" names the folder after the zip (one level, not two).
    (cd "$dest" && zip -q -r -X "../$name.zip" . -x '*.DS_Store')
    print "Desktop: $dest ($(du -sh "$dest" | cut -f1)), $dest.zip ($(du -h "$dest.zip" | cut -f1))"
fi
