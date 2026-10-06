#!/bin/zsh
# tools/windows/proof-b.sh — plan W0 Proof B: cross-build the BTX core package WITH tests and run the XCTest
# executable in CrossOver against the real data. Never touches the repo's BubbleTrouble/Core: it works on a
# copy under $WIN_CROSS/work/proof-b whose HectorKit dependency resolves to $HECTORKIT_DIR.
#
#   HECTORKIT_DIR      HectorKit checkout to build against (default ~/Developer/HectorKit)
#   HECTORKIT_DATA_BTX the BTX data folder as a MAC path (converted to Z:\… for Wine); default = the 1.1 UB copy
#
# Before the run, btx-predecode (Mac-only, from the repo — not the copy) decodes the QuickTime-JPEG bands into
# $work/decoded, exported to the tests as HECTORKIT_DECODED_DIR (Z:\…; D16.1 — no ImageIO on Windows).
#
# One CrossOver run per test class (a crash only loses its class); a class that dies is re-run test by test
# so every test gets a verdict. Prints per-class lines and a final "passed / failed / skipped / crashed" tally.
set -euo pipefail
# The test exe is not SDL, but run-in-crossover.sh requires an explicit audio driver (CrossOver strips SDL_*);
# and WIN_SWIFT_FLAGS (build.sh appends it to every build) must not leak an unrelated package's flags in here.
export HECTOR_SDL_AUDIO_DRIVER=dummy HECTOR_SDL_VIDEO_DRIVER=dummy
unset WIN_SWIFT_FLAGS
here="${0:A:h}"
repo="${here:h:h}"
. "$here/env.sh"

hk="${HECTORKIT_DIR:-$HOME/Developer/HectorKit}"
data="${HECTORKIT_DATA_BTX:-$HOME/Developer/Ambrosia/Resources/ambrosia-extracted/Action-Adventure/Bubble Trouble X/BubbleTroubleX_1.1_UB/Bubble Trouble X.app/Contents/Resources}"
[[ -d "$data" ]] || { print -u2 "proof-b: no BTX data at $data"; exit 66; }
work="$WIN_CROSS/work/proof-b"

# ---- The copy -----------------------------------------------------------------------------------
# Laid out like the repo so Package.swift and the tests need no path edits: work/proof-b/BubbleTrouble/Core reaches HectorKit
# through ../../../HectorKit (= work/HectorKit, a symlink to $HECTORKIT_DIR), and BTXCensusTests finds
# docs/bubble-trouble/data-census.md five levels above its #filePath (= work/proof-b/docs).
core="$work/BubbleTrouble/Core"
mkdir -p "$core" "$work/docs/bubble-trouble"
rsync -a --delete --exclude .build --exclude .swiftpm "$repo/BubbleTrouble/Core/" "$core/"
cp "$repo/docs/bubble-trouble/data-census.md" "$work/docs/bubble-trouble/"
ln -sfn "${hk:A}" "$WIN_CROSS/work/HectorKit"
# Test-only shim, copy only: PNGWriter (the opt-in BTX_RENDER_PNG_DIR eyes dump) uses ImageIO; off Apple it
# reports failure instead. It is never reached unless that env var is set.
python3 - "$core/Tests/BubbleTroubleRenderTests/Support/PNGWriter.swift" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
if "#if canImport(ImageIO)" not in s:
    s = s.replace("import ImageIO\nimport UniformTypeIdentifiers\n",
                  "#if canImport(ImageIO)\nimport ImageIO\nimport UniformTypeIdentifiers\n#endif\n", 1)
    s = s.replace("    static func write(_ image: RGBAImage, to url: URL) -> Bool {\n",
                  "    static func write(_ image: RGBAImage, to url: URL) -> Bool {\n"
                  "        #if !canImport(ImageIO)\n        return false\n        #else\n", 1)
    s = s.replace("        return CGImageDestinationFinalize(dest)\n    }\n",
                  "        return CGImageDestinationFinalize(dest)\n        #endif\n    }\n", 1)
    assert s.count("#if") == 2, "PNGWriter shim did not apply"
    open(p, "w").write(s)
PY

# ---- Build ----------------------------------------------------------------------------------------
WIN_BUILD_ROOT="$work/build" "$here/build.sh" "$core" all --tests >&2
exe="$work/build/Core/$WIN_TRIPLE/debug/BubbleTroubleCorePackageTests.exe"
[[ -f "$exe" ]] || { print -u2 "proof-b: test executable not built"; exit 70; }

# ---- Precomputed decodes (on the Mac) ----------------------------------------------------------------
# The repo's btx-predecode builds against the repo's HectorKit symlink, not $HECTORKIT_DIR.
swift run -c release --package-path "$repo/BubbleTroubleX/Windows" btx-predecode "$data" "$work/decoded" >&2

# ---- Run ----------------------------------------------------------------------------------------------
export HECTORKIT_DATA_BTX="$(win_path "$data")"
export HECTORKIT_DECODED_DIR="$(win_path "$work/decoded")"
export WIN_RUN_TIMEOUT="${WIN_RUN_TIMEOUT:-900}"
logs="$work/logs"; rm -rf "$logs"; mkdir -p "$logs"
"$here/run-in-crossover.sh" "$exe" --list-tests > "$logs/list.txt" 2>&1 || true
tests=(${(f)"$(tr -d '\r' < "$logs/list.txt" | grep -E '^[A-Za-z0-9_]+\.[A-Za-z0-9_]+/[A-Za-z0-9_]+$' || true)"})
classes=(${(u)${tests%%/*}})
if (( ${#tests} == 0 )); then
    print -u2 "proof-b: --list-tests yielded 0 tests (build or CrossOver problem?) — see $logs/list.txt"
    tail -n 20 "$logs/list.txt" >&2 || true
    exit 1
fi
print -r -- "proof-b: ${#tests} tests in ${#classes} classes; data $HECTORKIT_DATA_BTX"

verdicts="$logs/verdicts.txt"; : > "$verdicts"
record() {  # record <log> <test-ids…>: one verdict line per test id
    local log="$1"; shift
    local t name
    for t in "$@"; do
        name="${t#*.}"; name="${name/\//.}"          # Module.Class/test -> Class.test (XCTest's log form)
        if grep -q "Test Case '$name' passed" "$log"; then print "passed $t"
        elif grep -q "Test Case '$name' skipped" "$log"; then print "skipped $t"
        elif grep -q "Test Case '$name' failed" "$log"; then print "failed $t"
        else print "crashed $t"; fi
    done >> "$verdicts"
}
for c in $classes; do
    log="$logs/$c.txt"
    set +e; "$here/run-in-crossover.sh" "$exe" "$c" > "$log" 2>&1; code=$?; set -e
    members=(${(M)tests:#$c/*})
    if (( code == 0 || code == 1 )); then
        record "$log" $members
        print "  $c: exit $code"
    else
        print "  $c: exit $code — re-running its ${#members} tests one by one"
        for t in $members; do
            tl="$logs/${t//\//__}.txt"
            set +e; "$here/run-in-crossover.sh" "$exe" "$t" > "$tl" 2>&1; set -e
            record "$tl" "$t"
        done
    fi
done

print "proof-b: $(grep -c '^passed' "$verdicts") passed / $(grep -c '^failed' "$verdicts") failed /" \
      "$(grep -c '^skipped' "$verdicts") skipped / $(grep -c '^crashed' "$verdicts") crashed (of ${#tests})"
grep -v '^passed' "$verdicts" | sed 's/^/  /' || true
print "logs: $logs"
