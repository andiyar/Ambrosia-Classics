#!/bin/zsh
# tools/windows/proof-b-ferazel.sh [--check-guard | --class NAME] — Phase W WF0 Proof B (plan
# docs/plans/2026-10-26-ferazel-windows.md, gate GWB): cross-build Ferazel/Core WITH its tests and run the XCTest
# executable in CrossOver against the repo's Resources/Ferazel. proof-b.sh's shape, for Ferazel.
#
# Never touches the repo's Ferazel/Core: it works on a copy under $WIN_CROSS/work/proof-b-ferazel laid out like the
# repo (Ferazel/Core reaches HectorKit through ../../../HectorKit = $WIN_CROSS/work/HectorKit, the same symlink
# proof-b.sh makes; CensusTests finds docs/ferazel/data-census.md five levels above its #filePath).
# Builds into $work/build (never the gates' $WIN_CROSS/build/ferazel, never BTX's build/Core — Ruling 19).
#
#   (no argument)   run the whole suite ONCE (one CrossOver launch, plus a short --list-tests launch for the count)
#   --class NAME    re-run one test class (e.g. FerazelCoreTests.FerazelDataTests) — only after a crash, to find it
#   --check-guard   evaluate the launch guard (hour + driver) and exit: builds nothing, runs nothing
#
#   HECTORKIT_DIR   HectorKit checkout to build against (default ~/Developer/HectorKit)
#
# LAUNCH RULE (D42): refuses (exit 64, one line) unless `date +%H` is in 09..20 and the audio driver it passes is
# `dummy`. The script sets the drivers itself; the caller's HECTOR_SDL_* values are never inherited. There is no
# hour override. A watchdog kill (exit 124, WIN_RUN_TIMEOUT=3600 here) is reported as "timed out", never as a count.
set -euo pipefail
export HECTOR_SDL_AUDIO_DRIVER=dummy HECTOR_SDL_VIDEO_DRIVER=dummy
unset WIN_SWIFT_FLAGS HECTORKIT_PATH FERAZEL_PNG_OUT
here="${0:A:h}"
repo="${here:h:h}"

mode=all class=""
case "${1:-}" in
    "") ;;
    --check-guard) mode=guard ;;
    --class) mode=class; class="${2:-}"; [[ -n "$class" ]] || { print -u2 "usage: $0 [--check-guard | --class NAME]"; exit 64; } ;;
    *) print -u2 "usage: $0 [--check-guard | --class NAME]"; exit 64 ;;
esac

# ---- Launch guard (D42) -------------------------------------------------------------------------------
h=$(date +%H)
if (( 10#$h < 9 || 10#$h > 20 )); then
    print "proof-b-ferazel: refused (night rule): hour $h, launches only 09..20; driver $HECTOR_SDL_AUDIO_DRIVER"
    exit 64
fi
if [[ "$HECTOR_SDL_AUDIO_DRIVER" != dummy || "$HECTOR_SDL_VIDEO_DRIVER" != dummy ]]; then
    print "proof-b-ferazel: refused: driver $HECTOR_SDL_AUDIO_DRIVER/$HECTOR_SDL_VIDEO_DRIVER, not dummy"
    exit 64
fi
if [[ $mode == guard ]]; then
    print "proof-b-ferazel: guard ok: hour $h; driver $HECTOR_SDL_AUDIO_DRIVER"
    exit 0
fi

. "$here/env.sh"
hk="${HECTORKIT_DIR:-$HOME/Developer/HectorKit}"
data="$repo/Resources/Ferazel"
[[ -d "$data" ]] || { print -u2 "proof-b-ferazel: no Ferazel data at $data"; exit 66; }
work="$WIN_CROSS/work/proof-b-ferazel"

# ---- The copy -------------------------------------------------------------------------------------------
core="$work/Ferazel/Core"
mkdir -p "$core" "$work/docs/ferazel"
rsync -a --delete --exclude .build --exclude .swiftpm "$repo/Ferazel/Core/" "$core/"
cp "$repo/docs/ferazel/data-census.md" "$work/docs/ferazel/"
ln -sfn "${hk:A}" "$WIN_CROSS/work/HectorKit"

# ---- Build --------------------------------------------------------------------------------------------
WIN_BUILD_ROOT="$work/build" "$here/build.sh" "$core" all --tests >&2
exe="$work/build/Core/$WIN_TRIPLE/debug/FerazelCorePackageTests.exe"
[[ -f "$exe" ]] || { print -u2 "proof-b-ferazel: test executable not built"; exit 70; }

# ---- Run ----------------------------------------------------------------------------------------------
export FERAZEL_DATA="$(win_path "$data")"
export WIN_RUN_TIMEOUT=3600
logs="$work/logs"; rm -rf "$logs"; mkdir -p "$logs"
"$here/run-in-crossover.sh" "$exe" --list-tests > "$logs/list.txt" 2>&1 || true
tests=(${(f)"$(tr -d '\r' < "$logs/list.txt" | grep -E '^[A-Za-z0-9_]+\.[A-Za-z0-9_]+/[A-Za-z0-9_]+$' || true)"})
if (( ${#tests} == 0 )); then
    print -u2 "proof-b-ferazel: --list-tests yielded 0 tests (build or CrossOver problem?) — see $logs/list.txt"
    tail -n 20 "$logs/list.txt" >&2 || true
    exit 1
fi
if [[ $mode == class ]]; then
    tests=(${(M)tests:#$class/*})
    (( ${#tests} )) || { print -u2 "proof-b-ferazel: no tests in class $class"; exit 64; }
    run_args=("$class"); log="$logs/${class}.txt"
else
    run_args=(); log="$logs/suite.txt"
fi
print -r -- "proof-b-ferazel: ${#tests} tests; data $FERAZEL_DATA; driver $HECTOR_SDL_AUDIO_DRIVER"

start=$SECONDS
set +e; "$here/run-in-crossover.sh" "$exe" $run_args > "$log" 2>&1; code=$?; set -e
elapsed=$(( SECONDS - start ))
if (( code == 124 )); then
    print "proof-b: timed out after ${WIN_RUN_TIMEOUT} s (watchdog) — no verdict; raise WIN_RUN_TIMEOUT in this script"
    print "logs: $logs"
    exit 124
fi

verdicts="$logs/verdicts.txt"; : > "$verdicts"
for t in $tests; do
    name="${t#*.}"; name="${name/\//.}"          # Module.Class/test -> Class.test (XCTest's log form)
    if grep -qF "Test Case '$name' passed" "$log"; then print "passed $t"
    elif grep -qF "Test Case '$name' skipped" "$log"; then print "skipped $t"
    elif grep -qF "Test Case '$name' failed" "$log"; then print "failed $t"
    else print "crashed $t"; fi
done >> "$verdicts"

passed=$(grep -c '^passed' "$verdicts" || true); failed=$(grep -c '^failed' "$verdicts" || true)
skipped=$(grep -c '^skipped' "$verdicts" || true); crashed=$(grep -c '^crashed' "$verdicts" || true)
print "  exit $code after ${elapsed} s"
grep -v '^passed' "$verdicts" | sed 's/^/  /' || true
(( crashed > 0 )) && print "  a crash: re-run one class with --class NAME to find it"
print "logs: $logs"
print "proof-b: $passed passed / $failed failed / $skipped skipped / $crashed crashed (of ${#tests})"
(( failed == 0 && skipped == 0 && crashed == 0 ))
