#!/bin/zsh
# tools/windows/build.sh <package-dir> <product|all> [--tests] [--release] [--sdl] [-- <swift build args>…]
# Cross-builds a SwiftPM package for x86_64-unknown-windows-msvc with the pinned open-source toolchain and
# the Swift SDK bundle setup-toolchain.sh generated. Prints the path of every .exe it produced (last lines).
#   <product>  an executable product to build, or `all` (every target of the package)
#   --tests    also build the test bundle; it is copied to <Package>PackageTests.exe beside it (Wine wants .exe)
#   --sdl      the package uses SDL3 through a pkg-config system library (`sdl3`, e.g. HectorKit/SDL's CSDL3):
#              writes a Windows sdl3.pc for the VC dev zip at $WIN_SDL3 (include/, lib/x64/SDL3.lib) and puts
#              it first on PKG_CONFIG_PATH, so SwiftPM takes -I/-L/-lSDL3 for Windows, not brew's Mac copy.
#              No unsafeFlags anywhere, so it also works when the SDL package is a path dependency.
#   -- …       everything after `--` is appended verbatim to each `swift build` (e.g. -Xcc -DFOO -Xlinker …).
#              WIN_SWIFT_FLAGS (whitespace-split) is appended the same way, before the `--` args. It LEAKS into
#              every build that inherits it (proof-b.sh unsets it); prefer `--` for one build.
# pkg-config: a cross-build never sees the Mac's (brew's) .pc files — PKG_CONFIG_PATH/LIBDIR are the
#              generated Windows dir (with --sdl) or an empty one, and a pkg-config shim hides brew's search path
#              (and brew) from SwiftPM. So a package needing CSDL3/sdl3 built without --sdl fails loudly (no SDL3 headers),
#              never against the Mac's SDL.
# Build dir: $WIN_BUILD_ROOT/<package-dir-name> (default ~/Developer/Toolchains/windows-cross/build).
#
# Why `--build-system native`: SwiftPM 6.4's default (swift-build) refuses a Windows destination from a
# macOS host ("unable to find platform for 'windows'"); the native build system cross-builds cleanly.
# Why a Swift SDK bundle, not `--triple/--sdk`: with bare --sdk SwiftPM injects host flags (`-Xcc -fPIC`,
# the macOS -F frameworks path) that clang rejects for an msvc target.
set -euo pipefail
here="${0:A:h}"
. "$here/env.sh"

usage() { print -u2 "usage: $0 <package-dir> <product|all> [--tests] [--release] [--sdl] [-- <swift build args>…]"; exit 64; }
(( $# >= 2 )) || usage
pkg="${1:A}"; product="$2"; shift 2
tests=0; config=debug; sdl=0
extra=(${=WIN_SWIFT_FLAGS:-})
while (( $# )); do
    case "$1" in
        --tests) tests=1 ;;
        --release) config=release ;;
        --sdl) sdl=1 ;;
        --) shift; extra+=("$@"); break ;;
        *) usage ;;
    esac
    shift
done
[[ -f "$pkg/Package.swift" ]] || { print -u2 "build: no Package.swift in $pkg"; exit 66; }
[[ -x "$WIN_TOOLCHAIN/usr/bin/swift" && -f "$WIN_SWIFT_SDKS/$WIN_SDK_BUNDLE/info.json" ]] || {
    print -u2 "build: toolchain not set up — run tools/windows/setup-toolchain.sh"; exit 69; }

scratch="${WIN_BUILD_ROOT:-$WIN_CROSS/build}/${pkg:t}"
pcdir="$scratch/pkgconfig-windows"
rm -rf "$pcdir"; mkdir -p "$pcdir"
if (( sdl )); then
    [[ -f "$WIN_SDL3/lib/x64/SDL3.lib" && -f "$WIN_SDL3/include/SDL3/SDL.h" ]] || {
        print -u2 "build: no SDL3 dev zip at $WIN_SDL3 — run tools/windows/setup-toolchain.sh"; exit 69; }
    # SwiftPM parses .pc files itself: it takes quotes literally but honours backslash-escaped spaces.
    cat > "$pcdir/sdl3.pc" <<PC
prefix=${WIN_SDL3// /\\ }
Name: sdl3
Description: SDL3 $SDL3_VERSION VC dev zip (x64) for the Windows cross-build (tools/windows/build.sh --sdl)
Version: $SDL3_VERSION
Cflags: -I\${prefix}/include
Libs: -L\${prefix}/lib/x64 -lSDL3
PC
fi
# SwiftPM reads .pc files itself, from PKG_CONFIG_PATH plus the search path it asks `pkg-config --variable
# pc_path pkg-config` for (brew's, on this Mac) and from `brew --prefix` for a .brew provider. Shims first on
# PATH answer the first with $pcdir only and fail the second, so the Mac's sdl3.pc is never in reach.
shimdir="$scratch/pkgconfig-shim"
mkdir -p "$shimdir"
cat > "$shimdir/pkg-config" <<'SH'
#!/bin/sh
# tools/windows/build.sh: cross-builds see only the generated Windows .pc dir, never the host's.
if [ "$1" = "--variable" ] && [ "$2" = "pc_path" ]; then printf '%s\n' "$PKG_CONFIG_LIBDIR"; exit 0; fi
echo "pkg-config (cross-build shim): host pkg-config disabled; use build.sh --sdl for sdl3" >&2
exit 1
SH
# SwiftPM also asks `brew --prefix` for a .brew provider's pkgconfig dir: hide brew the same way.
cat > "$shimdir/brew" <<'SH'
#!/bin/sh
echo "brew (cross-build shim): hidden from Windows cross-builds" >&2
exit 1
SH
chmod +x "$shimdir/pkg-config" "$shimdir/brew"
export PKG_CONFIG_LIBDIR="$pcdir" PKG_CONFIG_PATH="$pcdir" PATH="$shimdir:$PATH"
swift=("$WIN_TOOLCHAIN/usr/bin/swift" build --package-path "$pkg" --scratch-path "$scratch" -c "$config"
       --build-system native --swift-sdks-path "$WIN_SWIFT_SDKS" --swift-sdk "$WIN_TRIPLE" $extra)
# SwiftPM won't take --product with --build-tests, so a named product and the tests are two builds.
if [[ "$product" != all ]]; then
    $swift --product "$product"
fi
if (( tests )); then
    $swift --build-tests
elif [[ "$product" == all ]]; then
    $swift
fi

out="$scratch/$WIN_TRIPLE/$config"
if (( tests )); then
    for x in "$out"/*.xctest(N); do cp -f "$x" "${x%.xctest}.exe"; done
fi
print -l "$out"/*.exe(N)
