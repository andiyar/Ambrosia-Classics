#!/bin/zsh
# tools/windows/stage-ferazel-win.sh [--no-desktop] [--no-icon] [--allow-dirty]
# Phase W WF6 (plan docs/plans/2026-10-26-ferazel-windows.md, gate GW5): stages Ferazel's Wand for Windows as a plain
# folder + zip (no installer, no signing, nothing uploaded). stage-btx.sh's shape, for Ferazel:
#
#   out/Windows/Ferazel's Wand/Ferazel's Wand.exe   release cross-build of FerazelWin, GUI subsystem (no console)
#   out/Windows/Ferazel's Wand/*.dll                every DLL it imports, recursively (PE import tables, llvm-objdump),
#                                                   from the Swift runtime dir ($WIN_RUNTIME, with Microsoft's
#                                                   redistributable vcruntime140*/msvcp140* — D15) and SDL3; Windows'
#                                                   own DLLs are not shipped (list printed)
#   out/Windows/Ferazel's Wand/Data/                the ORIGINAL 1.0.3 data, unchanged (Resources/Ferazel: the six
#                                                   .rsrc files + "Ferazel's Wand Music") and Fonts/*.fzfont (the
#                                                   baked faces, Ferazel/Windows/Resources/Fonts)
#   out/Windows/Ferazel's Wand/WHAT-TO-EXPECT.txt   Ferazel/WINDOWS-WHAT-TO-EXPECT.md, markup stripped, a build stamp
#                                                   under the title, UTF-8 BOM + CRLF
#   out/Windows/Ferazel's Wand/MANIFEST.txt         every file in the zip (relative, '/'-separated, one per line, LF),
#                                                   folders and MANIFEST.txt itself left out — gate GW5 diffs it with
#                                                   the zip's own listing
#   out/Windows/Ferazel's Wand (Windows).zip        the folder's CONTENTS at the zip root (zip -X, no __MACOSX): Windows'
#                                                   "Extract All" names its folder after the zip, so unzipping gives
#                                                   exactly one "Ferazel's Wand (Windows)\" level
#
# The staged layout runs with NO arguments: FerazelWin reads Data\ beside the exe and the fonts from Data\Fonts\
# (main.swift: --data else <exe dir>/Data; --fonts else <data>/Fonts).
# Then, unless --no-desktop, copies them to ~/Desktop/Ferazel's Wand (Windows)/ and ~/Desktop/Ferazel's Wand
# (Windows).zip; only those two Desktop items are replaced.
#
# Committed content only: the repo and the HectorKit checkout the package builds against must have no uncommitted or
# untracked changes, so the stamp ("<classics sha>, HectorKit <sha>") names exactly what was built (exit 65 otherwise).
# --allow-dirty stages anyway and stamps "<sha>-dirty". The check runs before anything is wiped or built: a refused
# stage leaves the previous work, build and out/ folders as they were. smoke-ferazel-win.sh refuses a zip whose stamp
# is not this checkout's HEAD (and HectorKit's), so stage after the last commit.
#   --no-icon   skip the icon + version info (the application manifest is always embedded)
#
# Build roots (Ruling 19): works in $WIN_CROSS/work/stage-ferazel and builds into $WIN_CROSS/build/stage-ferazel —
# never build/stage or work/stage-btx (BTX's) and never build/ferazel (the gates'): build.sh names its scratch folder
# after the package folder, and BTX's package is also called Windows. Both folders are FIXED (no override): a second
# stage — another session's, a reviewer's — wipes and overwrites them (and out/Windows/ of its own checkout); stages
# never run side by side.
#
# GUI subsystem: linked with /SUBSYSTEM:WINDOWS /ENTRY:mainCRTStartup (the CRT's console entry calls Swift's `main`;
# only the PE header's subsystem changes), checked to be 2 after the build. Resources via mingw's windres (brew
# mingw-w64, required): the application manifest (Per-Monitor-V2 DPI awareness, as SDL3 asks at video init; Windows
# 10/11; asInvoker), the icon (Ferazel/App/AppIcon.icon/Assets/ferazel.png, 512 px, resized with sips to 16/32/48/256 —
# there is no .icns for iconutil) and version info.
set -euo pipefail
here="${0:A:h}"
repo="${here:h:h}"
. "$here/env.sh"

desktop=1; icon=1; allow_dirty=0
while (( $# )); do
    case "$1" in
        --no-desktop) desktop=0 ;;
        --no-icon) icon=0 ;;
        --allow-dirty) allow_dirty=1 ;;
        *) print -u2 "usage: $0 [--no-desktop] [--no-icon] [--allow-dirty]"; exit 64 ;;
    esac
    shift
done

name="Ferazel's Wand"
pkg="$repo/Ferazel/Windows"
data="$repo/Resources/Ferazel"
fonts="$pkg/Resources/Fonts"
card="$repo/Ferazel/WINDOWS-WHAT-TO-EXPECT.md"
png="$repo/Ferazel/App/AppIcon.icon/Assets/ferazel.png"
out="$repo/out/Windows/$name"
zipfile="$repo/out/Windows/$name (Windows).zip"
rsrc=("Ferazel's Wand.rsrc" "Ferazel's Wand Backgrounds.rsrc" "Ferazel's Wand Sounds.rsrc"
      "Ferazel's Wand Sprites.rsrc" "Ferazel's Wand Titles.rsrc" "Ferazel's Wand World Data.rsrc")
music="Ferazel's Wand Music"

[[ -f "$pkg/Package.swift" ]] || { print -u2 "stage-ferazel-win: no package at $pkg"; exit 66; }
for f in $rsrc; do [[ -f "$data/$f" ]] || { print -u2 "stage-ferazel-win: no \"$f\" in $data"; exit 66; }; done
[[ -d "$data/$music" ]] || { print -u2 "stage-ferazel-win: no \"$music\" folder in $data"; exit 66; }
fontfiles=("$fonts"/*.fzfont(N))
(( ${#fontfiles} )) || { print -u2 "stage-ferazel-win: no baked fonts (*.fzfont) in $fonts"; exit 66; }
[[ -f "$card" ]] || { print -u2 "stage-ferazel-win: no gate card at $card"; exit 66; }
objdump="$WIN_TOOLCHAIN/usr/bin/llvm-objdump"
[[ -x "$objdump" ]] || { print -u2 "stage-ferazel-win: no llvm-objdump in $WIN_TOOLCHAIN — run setup-toolchain.sh"; exit 69; }
windres="$(command -v x86_64-w64-mingw32-windres || true)"
[[ -n "$windres" ]] || { print -u2 "stage-ferazel-win: no x86_64-w64-mingw32-windres (brew mingw-w64; not installed by this script)"; exit 69; }

# ---- Version stamp from committed content (before anything is wiped) ----------------------------------------
hk="$pkg/../../../HectorKit"; hk="${hk:A}"
stamp_of() {    # <git dir> <label>
    local sha dirty=""
    sha="$(git -C "$1" rev-parse --short HEAD 2>/dev/null)" || { print -u2 "stage-ferazel-win: $1 is not a git checkout"; exit 66; }
    if [[ -n "$(git -C "$1" status --porcelain 2>/dev/null)" ]]; then
        if (( allow_dirty )); then
            dirty="-dirty"
        else
            print -u2 "stage-ferazel-win: $2 ($1) has uncommitted or untracked changes — commit them (or --allow-dirty):"
            git -C "$1" status --short >&2
            exit 65
        fi
    fi
    print -r -- "$sha$dirty"
}
stamp="$(stamp_of "$repo" "the repo")"
[[ -d "$hk" ]] || { print -u2 "stage-ferazel-win: no HectorKit at $hk (Ferazel/Windows reaches it at ../../../HectorKit)"; exit 66; }
stamp="$stamp, HectorKit $(stamp_of "$hk" "HectorKit")"
print "Version stamp: $stamp"
date_built="$(date +%Y-%m-%d)"

work="$WIN_CROSS/work/stage-ferazel"         # no spaces: the .res path goes to lld-link verbatim
rm -rf "$work"; mkdir -p "$work"

# ---- Resources: manifest (always), icon + version info (unless --no-icon) -----------------------------------
link=(-Xlinker /SUBSYSTEM:WINDOWS -Xlinker /ENTRY:mainCRTStartup)
cat > "$work/ferazel.manifest" <<'XML'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<assembly xmlns="urn:schemas-microsoft-com:asm.v1" manifestVersion="1.0">
  <assemblyIdentity type="win32" name="AmbrosiaClassics.FerazelsWand" version="1.0.3.0" processorArchitecture="amd64"/>
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
print '1 24 "ferazel.manifest"' > "$work/ferazel.rc"     # CREATEPROCESS_MANIFEST_RESOURCE_ID, RT_MANIFEST
if (( icon )); then
    [[ -f "$png" ]] || { print -u2 "stage-ferazel-win: no icon image at $png (or pass --no-icon)"; exit 66; }
    # The app icon's one layer image (512 px) → 16, 32, 48, 256 px PNGs → a PNG-entry .ico.
    sizes=(16 32 48 256); pngs=()
    for s in $sizes; do
        sips -z $s $s "$png" --out "$work/icon-$s.png" >/dev/null
        pngs+=("$work/icon-$s.png")
    done
    python3 - "$work/ferazel.ico" $pngs <<'PY'
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
    cat >> "$work/ferazel.rc" <<RC
1 ICON "ferazel.ico"
1 VERSIONINFO
FILEVERSION 1,0,3,0
PRODUCTVERSION 1,0,3,0
FILEOS 0x40004
FILETYPE 0x1
BEGIN
  BLOCK "StringFileInfo"
  BEGIN
    BLOCK "040904B0"
    BEGIN
      VALUE "CompanyName", "Ambrosia Classics (non-commercial preservation)"
      VALUE "FileDescription", "Ferazel's Wand"
      VALUE "FileVersion", "1.0.3 (Windows build $date_built, $stamp)"
      VALUE "InternalName", "FerazelWin"
      VALUE "LegalCopyright", "Ferazel's Wand (c) Ambrosia Software"
      VALUE "OriginalFilename", "Ferazel's Wand.exe"
      VALUE "ProductName", "Ferazel's Wand"
      VALUE "ProductVersion", "1.0.3"
    END
  END
  BLOCK "VarFileInfo"
  BEGIN
    VALUE "Translation", 0x409, 1200
  END
END
RC
fi
(cd "$work" && "$windres" --target=pe-x86-64 -O res -i ferazel.rc -o ferazel.res)
link+=(-Xlinker "$work/ferazel.res")

# ---- Release cross-build ------------------------------------------------------------------------------------
build_root="$WIN_CROSS/build/stage-ferazel"
rm -rf "$build_root"      # a clean release build every time
WIN_SWIFT_FLAGS="" WIN_BUILD_ROOT="$build_root" "$here/build.sh" "$pkg" FerazelWin --sdl --release -- $link >&2
bin="$build_root/${pkg:t}/$WIN_TRIPLE/release"
[[ -f "$bin/FerazelWin.exe" ]] || { print -u2 "stage-ferazel-win: the build produced no FerazelWin.exe"; exit 70; }
subsystem="$("$objdump" -p "$bin/FerazelWin.exe" | awk '/^Subsystem/ {print $2}')"
[[ "$subsystem" == <-> ]] && (( 10#$subsystem == 2 )) || { print -u2 "stage-ferazel-win: subsystem is '$subsystem', not 2 (Windows GUI)"; exit 70; }

rm -rf "$out" "$zipfile"; mkdir -p "$out/Data/Fonts"
cp "$bin/FerazelWin.exe" "$out/$name.exe"

# ---- DLLs: walk the import tables (stage-btx.sh's walk) --------------------------------------------------------
SYSTEM_DLLS=(kernel32 user32 gdi32 advapi32 shell32 ole32 oleaut32 imm32 winmm version setupapi cfgmgr32 ws2_32
             bcrypt bcryptprimitives ntdll shlwapi rpcrt4 dbghelp crypt32 secur32 userenv mswsock iphlpapi combase
             dwmapi dxgi d3d11 d3d12 dinput8 hid uxtheme ucrtbase msvcrt synchronization powrprof netapi32 winhttp
             mpr ncrypt normaliz psapi comdlg32 comctl32 shcore winspool)
search=("$WIN_RUNTIME" "$WIN_SDL3/lib/x64")
typeset -A shipped excluded
queue=("$out/$name.exe")
while (( ${#queue} )); do
    file="${queue[1]}"; queue=("${(@)queue[2,-1]}")
    for dll in ${(f)"$("$objdump" -p "$file" | awk '/DLL Name:/ {print $3}')"}; do
        lower="${dll:l}"
        [[ -n "${shipped[$lower]:-}" || -n "${excluded[$lower]:-}" ]] && continue
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
            print -u2 "stage-ferazel-win: $dll (imported by ${file:t}) is neither in ${search[*]} nor a known system DLL"
            exit 70
        fi
    done
done
print "Shipped DLLs (${#shipped}):"
for k in ${(ok)shipped}; do print "  ${shipped[$k]}"; done
print "Not shipped (${#excluded}):"
for k in ${(ok)excluded}; do print "  $k — ${excluded[$k]}"; done

# ---- Data: the original files unchanged + the baked fonts ---------------------------------------------------------
for f in $rsrc; do cp "$data/$f" "$out/Data/"; done
mkdir -p "$out/Data/$music"
# The music folder as-is (01..30, 28 files); Finder litter is not game data (tools/stage-ferazel.sh's rule).
rsync -a --exclude '.DS_Store' --exclude $'Icon\r' "$data/$music/" "$out/Data/$music/"
cp $fontfiles "$out/Data/Fonts/"

# ---- What to expect ----------------------------------------------------------------------------------------------
python3 - "$card" "$out/WHAT-TO-EXPECT.txt" "Windows build $date_built ($stamp)." <<'PY'
import re, sys
text = open(sys.argv[1], encoding="utf-8").read()
text = re.sub(r"\*\*(.+?)\*\*", r"\1", text)        # bold
text = text.replace("`", "")
text = re.sub(r"^#+ ", "", text, flags=re.M)
first, _, rest = text.partition("\n")
text = first + "\n\n" + sys.argv[3] + "\n" + rest     # the build stamp under the title (the repo file stays stamp-free)
# UTF-8 with a BOM, CRLF: what every Notepad (old ones included) opens correctly.
open(sys.argv[2], "w", encoding="utf-8-sig", newline="").write(text.replace("\r\n", "\n").replace("\n", "\r\n"))
PY
xattr -cr "$out"

# ---- Manifest + zip -------------------------------------------------------------------------------------------------
(cd "$out" && find . -type f ! -path ./MANIFEST.txt ! -name .DS_Store | sed 's|^\./||' | LC_ALL=C sort) > "$work/MANIFEST.txt"
cp "$work/MANIFEST.txt" "$out/MANIFEST.txt"
(cd "$out" && zip -q -r -X "$zipfile" . -x '*.DS_Store')
# Self-check (gate GW5's diff): the zip's files, less folder entries and the manifest itself, = the manifest.
if ! diff <(zipinfo -1 "$zipfile" | grep -v '/$' | grep -vx 'MANIFEST.txt' | LC_ALL=C sort) \
          <(LC_ALL=C sort "$out/MANIFEST.txt") >&2; then
    print -u2 "stage-ferazel-win: the zip's file list differs from MANIFEST.txt"; exit 70
fi
print "Staged: $out ($(du -sh "$out" | cut -f1), $(wc -l < "$out/MANIFEST.txt" | tr -d ' ') files + MANIFEST.txt)"
print "Zip: $zipfile ($(du -h "$zipfile" | cut -f1))"

# ---- Desktop copies --------------------------------------------------------------------------------------------------
if (( desktop )); then
    dest="$HOME/Desktop/$name (Windows)"
    rm -rf "$dest" "$dest.zip"
    cp -R "$out" "$dest"
    cp "$zipfile" "$dest.zip"
    print "Desktop: $dest ($(du -sh "$dest" | cut -f1)), $dest.zip ($(du -h "$dest.zip" | cut -f1))"
fi
