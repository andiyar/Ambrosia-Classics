#!/bin/zsh
# tools/windows/build.sh <package-dir> <product|all> [--tests] [--release]
# Cross-builds a SwiftPM package for x86_64-unknown-windows-msvc with the pinned open-source toolchain and
# the Swift SDK bundle setup-toolchain.sh generated. Prints the path of every .exe it produced (last lines).
#   <product>  an executable product to build, or `all` (every target of the package)
#   --tests    also build the test bundle; it is copied to <Package>PackageTests.exe beside it (Wine wants .exe)
# Build dir: $WIN_BUILD_ROOT/<package-dir-name> (default ~/Developer/Toolchains/windows-cross/build).
#
# Why `--build-system native`: SwiftPM 6.4's default (swift-build) refuses a Windows destination from a
# macOS host ("unable to find platform for 'windows'"); the native build system cross-builds cleanly.
# Why a Swift SDK bundle, not `--triple/--sdk`: with bare --sdk SwiftPM injects host flags (`-Xcc -fPIC`,
# the macOS -F frameworks path) that clang rejects for an msvc target.
set -euo pipefail
here="${0:A:h}"
. "$here/env.sh"

usage() { print -u2 "usage: $0 <package-dir> <product|all> [--tests] [--release]"; exit 64; }
(( $# >= 2 )) || usage
pkg="${1:A}"; product="$2"; shift 2
tests=0; config=debug
for a in "$@"; do
    case "$a" in
        --tests) tests=1 ;;
        --release) config=release ;;
        *) usage ;;
    esac
done
[[ -f "$pkg/Package.swift" ]] || { print -u2 "build: no Package.swift in $pkg"; exit 66; }
[[ -x "$WIN_TOOLCHAIN/usr/bin/swift" && -f "$WIN_SWIFT_SDKS/$WIN_SDK_BUNDLE/info.json" ]] || {
    print -u2 "build: toolchain not set up — run tools/windows/setup-toolchain.sh"; exit 69; }

scratch="${WIN_BUILD_ROOT:-$WIN_CROSS/build}/${pkg:t}"
swift=("$WIN_TOOLCHAIN/usr/bin/swift" build --package-path "$pkg" --scratch-path "$scratch" -c "$config"
       --build-system native --swift-sdks-path "$WIN_SWIFT_SDKS" --swift-sdk "$WIN_TRIPLE")
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
