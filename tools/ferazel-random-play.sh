#!/bin/bash
# Ferazel's Wand — the random-play bot (Phase 5 task RB, D44; Ben's "yes" to Q15 item 5).
#
# For every level in the playable scope (RandomPlay.levels = BuiltLevels.range) and FERAZEL_BOT_SEEDS seeds, a fresh
# game boots, New Game starts at the level by the hidden FerazelLevel switch, and a seeded bot (its own random stream,
# never the game's) plays FERAZEL_BOT_MINUTES minutes (30 steps a second, two game ticks a step) through the real path:
# held directions in runs of 5-60 steps, jump/run/use/cast taps and holds, item stepping, mashing bursts, now and then
# Esc, Cmd-P and the Caps Lock pause; conversations read through, dialogs answered as the shells answer them (Cancel
# on a confirm), a save point's panel given a file, death -> Continue, a level end -> the map -> the same level again.
# Any render refusal, thrown error, error/report dialog, quit, stuck modal (600 ticks with nothing moving) or trap
# (the process dies: the run and step it was on, from the progress file) is a row. Two paths:
#   core     Ferazel/Core    FerazelRenderTests.RandomPlayTests/testRandomPlay   (Core + FerazelRender, driver mirrored)
#   windows  Ferazel/Windows FerazelWinKitTests.WinRandomPlayTests               (headless WinGame + the shared driver)
#
# Usage: tools/ferazel-random-play.sh [core|windows|both]   (default both)
#   JOBS=n                    processes per path (default: half the cores)
#   FERAZEL_BOT_SEEDS=4  FERAZEL_BOT_MINUTES=3  FERAZEL_BOT_LEVELS=1,2      (the defaults: 4 seeds, 3 minutes, all)
#   Quick mode for a class task: FERAZEL_BOT_LEVELS=n FERAZEL_BOT_MINUTES=1 tools/ferazel-random-play.sh core
# Exit 0 = no rows; 1 = rows (the table is printed); 2 = a build failed.
# Release builds (-enable-testing): a debug build is far too slow. Headless: no window, no audio device, nothing
# launched; it writes only to a temporary folder (OUT=dir keeps the rows, counts and logs there).
#
# One fixed summary line per path (GE greps '^== (core|windows):'):
#   == core: random play — levels L, seeds S, steps T, deaths D, exits E, conversations C, saves V, failures F in W s
#
# THE UNATTENDED LOOP runs it at every phase end (with the visit sweep and the draw-mode audit), from the phase's
# worktree:
#     tools/ferazel-random-play.sh both > "$OUT/random-play.txt" 2>&1; echo "exit $?"
# A non-zero exit blocks the phase end: every row is a game-ending bug for a player — file each as a fix task, do not
# stage. Paste the two summary lines into the gate card.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WHICH="${1:-both}"
JOBS="${JOBS:-$(( $(sysctl -n hw.ncpu 2>/dev/null || echo 8) / 2 ))}"
OUT="${OUT:-$(mktemp -d "${TMPDIR:-/tmp}/ferazel-random-play.XXXXXX")}"
mkdir -p "$OUT"
export FERAZEL_BOT=1

build() {   # $1 package dir
    (cd "$1" && swift build -c release --build-tests -Xswiftc -enable-testing > "$OUT/build-$(basename "$1").log" 2>&1) \
        || { echo "BUILD FAILED: $1 (see $OUT/build-$(basename "$1").log)"; exit 2; }
}

# One shard of one path; resumes after a trap from the run after the one it died on.
worker() {  # $1 path name, $2 xctest bundle, $3 test, $4 shard index
    local dir="$OUT/$1/shard-$4" from=0 n=0
    mkdir -p "$dir"
    while :; do
        n=$((n + 1))
        FERAZEL_BOT_SHARD="$4/$JOBS" FERAZEL_BOT_OUT="$dir" FERAZEL_BOT_FROM="$from" \
            xcrun xctest -XCTest "$3" "$2" > "$dir/run-$n.log" 2>&1
        if grep -q "Executed 1 test" "$dir/run-$n.log"; then break; fi
        # Died mid-run: the progress file names it (index, level, seed, step).
        if [ ! -f "$dir/progress" ]; then
            printf '0\t-\tprocess\tdied before any run (see %s)\n' "$dir/run-$n.log" >> "$dir/failures.tsv"
            break
        fi
        IFS=$'\t' read -r index level seed step < "$dir/progress"
        sig="$(grep -m1 -E "Fatal error|Illegal instruction|signal|Trace/BPT|Segmentation|precondition" "$dir/run-$n.log" | cut -c1-200)"
        printf '%s\t%s\tstep %s trap\tprocess died: %s\n' "$level" "$seed" "$step" "${sig:-no message}" >> "$dir/failures.tsv"
        printf '%s\t%s\t%s\t0\t0\t0\t0\n' "$level" "$seed" "$step" >> "$dir/runs.tsv"
        rm -f "$dir/progress"
        from=$((index + 1))
        [ "$n" -ge 50 ] && { printf '0\t-\tprocess\t50 traps, gave up\n' >> "$dir/failures.tsv"; break; }
    done
}

play() {    # $1 path name, $2 package dir, $3 bundle name, $4 test
    local start=$SECONDS
    build "$2"
    local bundle="$2/.build/release/$3"
    for ((i = 0; i < JOBS; i++)); do worker "$1" "$bundle" "$4" "$i" & done
    wait
    cat "$OUT/$1"/shard-*/failures.tsv 2>/dev/null | sort -t$'\t' -k1,1n -k2,2n > "$OUT/$1-failures.tsv"
    cat "$OUT/$1"/shard-*/runs.tsv 2>/dev/null > "$OUT/$1-runs.tsv"
    local sums
    sums=$(awk -F'\t' '{ l[$1] = 1; s[$2] = 1; t += $3; d += $4; e += $5; c += $6; v += $7 }
        END { nl = 0; for (k in l) nl++; ns = 0; for (k in s) ns++
              printf "levels %d, seeds %d, steps %d, deaths %d, exits %d, conversations %d, saves %d", nl, ns, t, d, e, c, v }' \
        "$OUT/$1-runs.tsv")
    echo "== $1: random play — $sums, failures $(wc -l < "$OUT/$1-failures.tsv" | tr -d ' ') in $((SECONDS - start)) s"
    if [ -s "$OUT/$1-failures.tsv" ]; then
        echo "level | seed | step / context / keys | error"
        awk -F'\t' '{ printf "%s | %s | %s | %s\n", $1, $2, $3, $4 }' "$OUT/$1-failures.tsv"
    fi
}

case "$WHICH" in
    core) play core "$ROOT/Ferazel/Core" FerazelRenderTests.xctest FerazelRenderTests.RandomPlayTests/testRandomPlay ;;
    windows) play windows "$ROOT/Ferazel/Windows" FerazelWinKitTests.xctest FerazelWinKitTests.WinRandomPlayTests ;;
    both)
        play core "$ROOT/Ferazel/Core" FerazelRenderTests.xctest FerazelRenderTests.RandomPlayTests/testRandomPlay
        play windows "$ROOT/Ferazel/Windows" FerazelWinKitTests.xctest FerazelWinKitTests.WinRandomPlayTests ;;
    *) echo "usage: $0 [core|windows|both]"; exit 2 ;;
esac
echo "(rows, counts and logs: $OUT)"
cat "$OUT"/*-failures.tsv 2>/dev/null | grep -q . && exit 1
exit 0
