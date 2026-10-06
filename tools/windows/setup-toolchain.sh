#!/bin/zsh
# tools/windows/setup-toolchain.sh — idempotent. Fills $WIN_CROSS (~/Developer/Toolchains/windows-cross, outside
# git) with everything needed to cross-build Swift for x86_64 Windows on this Mac (plan W0):
#   1. swift.org's open-source macOS toolchain, extracted from its .pkg (not installed)
#   2. the Swift Windows SDK + runtime DLLs, extracted from swift.org's Windows installer (a WiX burn bundle —
#      we carve its attached container and msiextract windows.msi + rtl.amd64.msi; nothing is installed)
#   3. the MSVC CRT + Windows SDK sysroot via `xwin --accept-license splat` (licence accepted by Ben, D15),
#      with the UCRT headers/libs replaced by the SAME Windows SDK's UCRT msi (see README: xwin's UCRT
#      headers are the 10.0.10240 set, which lacks corecrt_math.h and breaks Swift's ucrt.modulemap)
#   4. SDL3's official Windows VC dev zip (libsdl-org)
#   5. a Swift SDK bundle (swift-sdks/windows-x86_64.artifactbundle) tying 1–3 together for SwiftPM
# Each step is skipped when its output already exists; delete an output directory to redo that step.
# Downloads only from download.swift.org, github.com/libsdl-org and Microsoft's servers (via xwin's manifest).
set -euo pipefail
here="${0:A:h}"
. "$here/env.sh"

# ---- Pinned digests (SHA-256) ------------------------------------------------------------------
SWIFT_OSX_PKG="${SWIFT_WIN_TAG}-osx.pkg"
SWIFT_OSX_SHA="8fd03185b98fe27f54a54631c2449decf75d5b466ce8e34abbd414141063c6aa"
SWIFT_WIN_EXE="${SWIFT_WIN_TAG}-windows10.exe"
SWIFT_WIN_SHA="76169a85bcba82854a0cd8f9655ffb74b3758d60c35a245457510095f2823c03"
SDL3_ZIP="SDL3-devel-${SDL3_VERSION}-VC.zip"
SDL3_SHA="1a784cb2a5c64d56fe7a62090fe9d242d9865f235e4ea9678f1a6ba4e693e7de"
SWIFT_BASE="https://download.swift.org/swift-${SWIFT_WIN_VERSION}-release"

say() { print -P "%B[setup]%b $*" >&2; }
# Host tools. Missing ones are NOT installed silently: `brew install` writes outside $WIN_CROSS (into Homebrew's
# prefix), so it only happens when WIN_SETUP_BREW=1 is set; otherwise the script stops and names the formula.
need() {
    command -v "$1" >/dev/null && return
    if [[ "${WIN_SETUP_BREW:-0}" == 1 ]]; then
        say "WARNING: $1 missing — running 'brew install $2' (writes into Homebrew's prefix, OUTSIDE $WIN_CROSS)"
        brew install "$2"
    else
        say "missing host tool '$1' (Homebrew formula '$2')."
        say "Install it yourself (brew install $2), or re-run with WIN_SETUP_BREW=1 to let this script brew it."
        say "Either way it lands in Homebrew's prefix, outside $WIN_CROSS."
        exit 69
    fi
}
sha_ok() { [[ "$(shasum -a 256 "$1" | cut -d' ' -f1)" == "$2" ]]; }
fetch() {   # fetch <url> <file> <sha256>
    local url="$1" file="$2" sha="$3"
    if [[ -f "$file" ]] && sha_ok "$file" "$sha"; then return; fi
    say "downloading ${file:t}"
    curl -fL --retry 3 -C - -o "$file" "$url" || curl -fL --retry 3 -o "$file" "$url"
    sha_ok "$file" "$sha" || { say "SHA-256 mismatch for $file"; exit 1; }
}

need 7z sevenzip; need msiextract msitools; need xwin xwin
mkdir -p "$WIN_DOWNLOADS"
tmp="$WIN_CROSS/tmp"; rm -rf "$tmp"; mkdir -p "$tmp"
trap 'rm -rf "$tmp"' EXIT

# ---- 1. macOS toolchain ----------------------------------------------------------------------------
fetch "$SWIFT_BASE/xcode/$SWIFT_WIN_TAG/$SWIFT_OSX_PKG" "$WIN_DOWNLOADS/$SWIFT_OSX_PKG" "$SWIFT_OSX_SHA"
if [[ ! -x "$WIN_TOOLCHAIN/usr/bin/swiftc" ]]; then
    say "extracting the macOS toolchain"
    pkgutil --expand-full "$WIN_DOWNLOADS/$SWIFT_OSX_PKG" "$tmp/osx"
    rm -rf "$WIN_TOOLCHAIN"; mv "$tmp/osx/${SWIFT_WIN_TAG}-osx-package.pkg/Payload" "$WIN_TOOLCHAIN"
fi

# ---- 2. Windows SDK + runtime ----------------------------------------------------------------------
fetch "$SWIFT_BASE/windows10/$SWIFT_WIN_TAG/$SWIFT_WIN_EXE" "$WIN_DOWNLOADS/$SWIFT_WIN_EXE" "$SWIFT_WIN_SHA"
if [[ ! -d "$WIN_XCTEST" || ! -f "$WIN_RUNTIME/swiftCore.dll" ]]; then
    say "extracting the Windows SDK and runtime from the burn bundle"
    ( cd "$tmp" && 7z x -y -o"$tmp/ux" "$WIN_DOWNLOADS/$SWIFT_WIN_EXE" 0 >/dev/null )
    # The burn manifest (UX container file "0") names the attached container's size and each payload's
    # SourcePath inside it. Carve the container (the cabinet whose header size matches), extract what we need.
    python3 - "$WIN_DOWNLOADS/$SWIFT_WIN_EXE" "$tmp/ux/0" "$tmp/attached.cab" "$tmp/names.txt" <<'PY'
import mmap, re, struct, sys
exe, manifest, out, names = sys.argv[1:]
m = open(manifest, encoding="utf-8", errors="replace").read()
size = int(re.search(r'<Container Id="WixAttachedContainer" FileSize="(\d+)"', m).group(1))
want = ["windows.msi", "windows.cab", "sdk.windows.x64.cab", "sdk.windows.arm64.cab", "sdk.windows.x86.cab",
        "rtl.amd64.msi", "rtl.amd64.cab"]
src = {}
for p in re.finditer(r'<Payload [^>]*>', m):
    t = p.group(0)
    fp = re.search(r'FilePath="([^"]+)"', t).group(1); sp = re.search(r'SourcePath="([^"]+)"', t).group(1)
    if fp in want and 'Container="WixAttachedContainer"' in t: src[fp] = sp
assert len(src) == len(want), f"burn manifest is missing payloads: {set(want) - set(src)}"
with open(exe, "rb") as f, mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ) as mm:
    i = mm.find(b"MSCF")
    while i != -1 and struct.unpack_from("<I", mm, i + 8)[0] != size:
        i = mm.find(b"MSCF", i + 4)
    assert i != -1, "attached container not found"
    with open(out, "wb") as o:
        for off in range(i, i + size, 1 << 24): o.write(mm[off:min(off + (1 << 24), i + size)])
open(names, "w").write("\n".join(f"{sp} {fp}" for fp, sp in src.items()) + "\n")
PY
    mkdir -p "$tmp/burn"
    while read -r sp fp; do
        7z x -y -o"$tmp/burn" "$tmp/attached.cab" "$sp" >/dev/null && mv "$tmp/burn/$sp" "$tmp/burn/$fp"
    done < "$tmp/names.txt"
    rm -f "$tmp/attached.cab"
    ( mkdir -p "$tmp/sdk" && cd "$tmp/sdk" && msiextract "$tmp/burn/windows.msi" >/dev/null )
    ( mkdir -p "$tmp/rtl" && cd "$tmp/rtl" && msiextract "$tmp/burn/rtl.amd64.msi" >/dev/null )
    rm -rf "$WIN_PLATFORM" "$WIN_RUNTIME"
    mv "$tmp/sdk/LocalApp/Programs/Swift/Platforms/$SWIFT_WIN_VERSION/Windows.platform" "$WIN_PLATFORM"
    mkdir -p "$WIN_RUNTIME"; find "$tmp/rtl" -type f -exec mv {} "$WIN_RUNTIME/" \;
fi

# ---- 3. MSVC CRT + Windows SDK (xwin) + matching UCRT ------------------------------------------------
if [[ ! -d "$WIN_VCTOOLS/lib/x64" || ! -f "$WIN_KITS/Include/$WINSDK_VERSION/ucrt/corecrt_math.h" ]]; then
    say "xwin splat (MSVC $MSVC_VERSION, Windows SDK $WINSDK_VERSION) — Microsoft licence accepted by Ben (D15)"
    rm -rf "$WIN_SYSROOT" "$WIN_CROSS/xwin-cache/unpack"
    xwin --accept-license --arch x86_64 --sdk-version "$WINSDK_VERSION" --crt-version "$MSVC_VERSION" \
        --cache-dir "$WIN_CROSS/xwin-cache" splat --use-winsysroot-style --preserve-ms-arch-notation \
        --output "$WIN_SYSROOT" >&2
    say "replacing xwin's UCRT with Windows SDK $WINSDK_VERSION's own UCRT msi"
    ucrt="$WIN_DOWNLOADS/ucrt-$WINSDK_VERSION"; mkdir -p "$ucrt"
    python3 - "$WIN_CROSS/xwin-cache/dl" "$WINSDK_VERSION" "$ucrt" <<'PY'
import glob, hashlib, json, os, subprocess, sys, urllib.request
dl, ver, out = sys.argv[1:]
man = json.load(open(glob.glob(os.path.join(dl, "pkg_manifest_*.vsman"))[0]))
pkg = next(p for p in man["packages"] if p["id"].startswith("Win1") and p["id"].endswith("SDK_" + ver))
pay = {p["fileName"]: p for p in pkg["payloads"]}
def get(name):
    p = pay["Installers\\" + name]; dst = os.path.join(out, name)
    if not (os.path.exists(dst) and hashlib.sha256(open(dst, "rb").read()).hexdigest().upper() == p["sha256"].upper()):
        urllib.request.urlretrieve(p["url"], dst)
    assert hashlib.sha256(open(dst, "rb").read()).hexdigest().upper() == p["sha256"].upper(), name
    return dst
msi = get("Universal CRT Headers Libraries and Sources-x86_en-us.msi")
media = subprocess.run(["msiinfo", "export", msi, "Media"], capture_output=True, text=True, check=True).stdout
for line in media.splitlines()[3:]:
    f = line.split("\t")
    if len(f) > 3 and f[3].endswith(".cab"): get(f[3])
PY
    ( mkdir -p "$tmp/ucrt" && cd "$tmp/ucrt" && msiextract "$ucrt/Universal CRT Headers Libraries and Sources-x86_en-us.msi" >/dev/null )
    u="$tmp/ucrt/Program Files/Windows Kits/10"
    rm -rf "$WIN_KITS/Include/$WINSDK_VERSION/ucrt" "$WIN_KITS/Lib/$WINSDK_VERSION/ucrt/x64"
    cp -R "$u/Include/$WINSDK_VERSION.0/ucrt" "$WIN_KITS/Include/$WINSDK_VERSION/ucrt"
    cp -R "$u/Lib/$WINSDK_VERSION.0/ucrt/x64" "$WIN_KITS/Lib/$WINSDK_VERSION/ucrt/x64"
fi

# ---- 4. SDL3 Windows dev zip ---------------------------------------------------------------------------
fetch "https://github.com/libsdl-org/SDL/releases/download/release-$SDL3_VERSION/$SDL3_ZIP" \
      "$WIN_DOWNLOADS/$SDL3_ZIP" "$SDL3_SHA"
if [[ ! -f "$WIN_SDL3/lib/x64/SDL3.dll" ]]; then
    say "unpacking SDL3 $SDL3_VERSION"
    rm -rf "$WIN_SDL3"; ( cd "$WIN_CROSS" && 7z x -y "$WIN_DOWNLOADS/$SDL3_ZIP" >/dev/null )
fi

# ---- 5. Swift SDK bundle for SwiftPM -------------------------------------------------------------------
bundle="$WIN_SWIFT_SDKS/$WIN_SDK_BUNDLE"
say "writing the Swift SDK bundle"
mkdir -p "$bundle/sdk"
ln -sfn "$WIN_SDK" "$bundle/sdk/Windows.sdk"
cat > "$bundle/info.json" <<EOF
{ "schemaVersion": "1.0",
  "artifacts": { "windows-x86_64": { "type": "swiftSDK", "version": "$SWIFT_WIN_VERSION",
      "variants": [ { "path": "sdk", "supportedTriples": ["arm64-apple-macosx"] } ] } } }
EOF
cat > "$bundle/sdk/swift-sdk.json" <<EOF
{ "schemaVersion": "4.0",
  "targetTriples": { "$WIN_TRIPLE": {
      "sdkRootPath": "Windows.sdk",
      "swiftResourcesPath": "Windows.sdk/usr/lib/swift",
      "swiftStaticResourcesPath": "Windows.sdk/usr/lib/swift_static",
      "toolsetPaths": ["toolset.json"] } } }
EOF
# The driver builds its ucrt/WinSDK/vcruntime VFS overlay from -windows-sdk-root / -visualc-tools-root;
# lld-link gets the import-library dirs explicitly; XCTest's module + import lib live outside Windows.sdk.
python3 - "$bundle/sdk/toolset.json" <<PY
import json, sys
kits, vc = "$WIN_KITS", "$WIN_VCTOOLS"
lib = kits + "/Lib/$WINSDK_VERSION"
xct = "$WIN_XCTEST/usr/lib/swift/windows"
opts = ["-windows-sdk-root", kits, "-windows-sdk-version", "$WINSDK_VERSION",
        "-visualc-tools-root", vc, "-visualc-tools-version", "$MSVC_VERSION", "-use-ld=lld",
        "-L", vc + "/lib/x64", "-L", lib + "/ucrt/x64", "-L", lib + "/um/x64",
        "-I", xct, "-L", xct + "/x86_64"]
json.dump({"schemaVersion": "1.0", "rootPath": "$WIN_TOOLCHAIN/usr/bin",
           "swiftCompiler": {"extraCLIOptions": opts}}, open(sys.argv[1], "w"), indent=1)
PY

# ---- Report --------------------------------------------------------------------------------------------
say "ready"
print "swift (macOS host):  $("$WIN_TOOLCHAIN/usr/bin/swiftc" --version 2>&1 | head -1)"
print "Windows SDK:         $SWIFT_WIN_TAG ($WIN_SDK)"
print "MSVC CRT:            $MSVC_VERSION   Windows SDK: $WINSDK_VERSION   xwin: $(xwin --version)"
print "SDL3:                $SDL3_VERSION"
print "SHA-256:"
( cd "$WIN_DOWNLOADS" && shasum -a 256 "$SWIFT_OSX_PKG" "$SWIFT_WIN_EXE" "$SDL3_ZIP" | sed 's/^/  /' )
print "download total:      $(du -sh "$WIN_DOWNLOADS" "$WIN_CROSS/xwin-cache/dl" | awk '{print $1}' | paste -sd+ -) (swift.org+SDL+UCRT, xwin)"
