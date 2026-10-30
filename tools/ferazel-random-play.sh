#!/bin/bash
# Ferazel's Wand — the random-play bot (Phase 5 task RB, D44; Ben's "yes" to Q15 item 5).
#
# For every level in the playable scope (RandomPlay.levels = BuiltLevels.range) and FERAZEL_BOT_SEEDS seeds, a fresh
# game boots, New Game starts at the level by the hidden FerazelLevel switch, and a seeded bot (its own random stream,
# never the game's) plays FERAZEL_BOT_MINUTES minutes (30 steps a second, two game ticks a step) through the real path:
# held directions in runs of 5-60 steps, jump/run/use/cast taps and holds, item stepping, mashing bursts, now and then
# Esc, Cmd-P and the Caps Lock pause; conversations read through, dialogs answered as the shells answer them (Cancel
# on a confirm), a save point's panel given a file, death -> Continue, the first level end -> the map -> the same level
# again, every later level end -> a fresh game started at the level (as the run's start).
# Any render refusal, thrown error, error/report dialog, quit, stuck modal (600 ticks with nothing moving) or trap
# (the process dies: the run and step it was on, from the progress file) is a row. Two paths:
#   core     Ferazel/Core    FerazelRenderTests.RandomPlayTests/testRandomPlay   (Core + FerazelRender, driver mirrored)
#   windows  Ferazel/Windows FerazelWinKitTests.WinRandomPlayTests               (headless WinGame + the shared driver)
#
# Usage: tools/ferazel-random-play.sh [core|windows|both]   (default both)
#   JOBS=n                    processes per path (default 4, at least 1, never more than 6 — Ben's Mac panicked out
#                             of RAM on 2026-10-30 when 14 sweep processes ran beside builds; each build and each
#                             worker also waits while free memory is < MIN_FREE_PCT, default 30%)
#   FERAZEL_BOT_SEEDS=4  FERAZEL_BOT_MINUTES=3  FERAZEL_BOT_LEVELS=1,2      (the defaults: 4 seeds, 3 minutes, all)
#   FERAZEL_BOT_WATCHDOG=s    wall-clock limit of one test process (default 120 s + 120 s per minute of play per run
#                             it has to do); a process past it is killed and its run is a row (then the next run)
#   Quick mode for a class task: FERAZEL_BOT_LEVELS=n FERAZEL_BOT_MINUTES=1 tools/ferazel-random-play.sh core
# Exit 0 = no rows and every expected run (levels x seeds) reported; 1 = rows (the table is printed: a failed or
# skipped test, a run that never reported, a watchdog kill, a trap, the bot's own rows); 2 = a build failed or a bad
# setting (a level outside BuiltLevels.range, a seed or minute count that is not a positive number).
# At its start it deletes only the files it writes in OUT (build logs, <path>-runs/-failures.tsv, the shard folders'
# runs/failures/progress/logs), so a reused OUT starts clean.
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
case "$WHICH" in core|windows|both) ;; *) echo "usage: $0 [core|windows|both]"; exit 2 ;; esac
JOBS="${JOBS:-4}"
case "$JOBS" in ''|*[!0-9]*) JOBS=1 ;; esac
[ "$JOBS" -ge 1 ] || JOBS=1
[ "$JOBS" -gt 6 ] && JOBS=6
MIN_FREE_PCT="${MIN_FREE_PCT:-30}"
OUT="${OUT:-$(mktemp -d "${TMPDIR:-/tmp}/ferazel-random-play.XXXXXX")}"
mkdir -p "$OUT"
export FERAZEL_BOT=1

bad() { echo "random play: $1"; exit 2; }
positive() { case "$1" in ''|*[!0-9]*) return 1 ;; esac; [ "$1" -ge 1 ]; }

# The scope, read from the source the test reads (BuiltLevels.range), and the settings the test will see, checked here
# so the summary can say how many runs there should have been.
RANGE="$(sed -nE 's/.*static let range = ([0-9]+)\.\.\.([0-9]+).*/\1 \2/p' "$ROOT/Ferazel/Core/Sources/FerazelCore/Front/BuiltLevels.swift")"
read -r LO HI <<< "$RANGE"
positive "${LO:-}" && positive "${HI:-}" || bad "cannot read BuiltLevels.range"
SEEDS="${FERAZEL_BOT_SEEDS:-4}"; positive "$SEEDS" || bad "FERAZEL_BOT_SEEDS=$SEEDS is not a positive number"
MINUTES="${FERAZEL_BOT_MINUTES:-3}"; positive "$MINUTES" || bad "FERAZEL_BOT_MINUTES=$MINUTES is not a positive number"
LEVELS=""
if [ -n "${FERAZEL_BOT_LEVELS:-}" ]; then
    for l in $(echo "$FERAZEL_BOT_LEVELS" | tr ',' ' '); do
        positive "$l" && [ "$l" -ge "$LO" ] && [ "$l" -le "$HI" ] \
            || bad "level $l is outside BuiltLevels.range ($LO...$HI)"
        LEVELS="$LEVELS${LEVELS:+,}$l"
    done
fi
[ -n "$LEVELS" ] || LEVELS="$(seq -s, "$LO" "$HI")"
export FERAZEL_BOT_SEEDS="$SEEDS" FERAZEL_BOT_MINUTES="$MINUTES" FERAZEL_BOT_LEVELS="$LEVELS"
# Every expected run, in the test's order (levels outer, seeds inner): "level<TAB>seed".
EXPECTED="$(for l in $(echo "$LEVELS" | tr ',' ' '); do for ((s = 1; s <= SEEDS; s++)); do printf '%s\t%s\n' "$l" "$s"; done; done)"
NRUNS=$(printf '%s\n' "$EXPECTED" | grep -c .)

# Only the files this script writes.
for p in core windows; do
    rm -f "${OUT:?}/$p-failures.tsv" "${OUT:?}/$p-runs.tsv"
    for d in "${OUT:?}/$p"/shard-*; do
        [ -d "$d" ] && rm -f "${d:?}"/failures.tsv "${d:?}"/runs.tsv "${d:?}"/progress "${d:?}"/run-*.log
    done
done
rm -f "${OUT:?}/build-Core.log" "${OUT:?}/build-Windows.log"

# Waits (up to 10 min) while the system's free memory is below MIN_FREE_PCT, so the bot never pushes the Mac into swap.
wait_for_memory() {
    local tries=0 free
    while :; do
        free=$(memory_pressure 2>/dev/null | awk -F': ' '/free percentage/ {gsub(/%/,"",$2); print $2}')
        [ -z "$free" ] || [ "$free" -ge "$MIN_FREE_PCT" ] && return 0
        [ "$tries" -ge 60 ] && { echo "memory still below ${MIN_FREE_PCT}% free after 10 min; continuing"; return 1; }
        tries=$((tries + 1)); sleep 10
    done
}

build() {   # $1 package dir
    wait_for_memory
    (cd "$1" && swift build -j 4 -c release --build-tests -Xswiftc -enable-testing > "$OUT/build-$(basename "$1").log" 2>&1) \
        || { echo "BUILD FAILED: $1 (see $OUT/build-$(basename "$1").log)"; exit 2; }
}

# One shard of one path; resumes after a trap or a watchdog kill from the run after the one it stopped on.
worker() {  # $1 path name, $2 xctest bundle, $3 test, $4 shard index
    local dir="$OUT/$1/shard-$4" from=0 n=0
    mkdir -p "$dir"
    while :; do
        n=$((n + 1))
        local log="$dir/run-$n.log" left=0 i limit pid timedout=0
        for ((i = from; i < NRUNS; i++)); do [ $((i % JOBS)) -eq "$4" ] && left=$((left + 1)); done
        limit="${FERAZEL_BOT_WATCHDOG:-$((120 + left * MINUTES * 120))}"
        FERAZEL_BOT_SHARD="$4/$JOBS" FERAZEL_BOT_OUT="$dir" FERAZEL_BOT_FROM="$from" \
            xcrun xctest -XCTest "$3" "$2" > "$log" 2>&1 &
        pid=$!
        local deadline=$((SECONDS + limit))
        while kill -0 "$pid" 2>/dev/null; do
            if [ "$SECONDS" -ge "$deadline" ]; then
                timedout=1
                pkill -KILL -P "$pid" 2>/dev/null; kill -KILL "$pid" 2>/dev/null
                break
            fi
            sleep 1
        done
        wait "$pid" 2>/dev/null
        if [ "$timedout" = 0 ] && grep -qE "Executed [0-9]+ tests?" "$log"; then
            # The test finished: it must have passed. A failure the bot did not write as rows (its own assertion
            # carries "random-play failures") — a thrown error, a missing data folder — is a row; so is a skip.
            if ! grep -qE "^Test Case '.*' passed \(" "$log"; then
                local other
                other="$(grep -E ": error: " "$log" | grep -v "random-play failures" | head -n 3 | cut -c1-300 | tr '\t\n' '  ')"
                if grep -qE "^Test Case '.*' skipped \(" "$log"; then
                    printf '0\t-\tshard %s\tthe test was skipped (see %s)\n' "$4" "$log" >> "$dir/failures.tsv"
                elif ! grep -qE "^Test Case '.*' failed \(" "$log"; then
                    printf '0\t-\tshard %s\tno test ran (see %s)\n' "$4" "$log" >> "$dir/failures.tsv"
                elif [ -n "$other" ] || ! grep -q "random-play failures" "$log"; then
                    printf '0\t-\tshard %s\tthe test failed: %s (see %s)\n' "$4" "${other:-no message}" "$log" \
                        >> "$dir/failures.tsv"
                fi
            fi
            break
        fi
        local what="process died" how="trap"
        [ "$timedout" = 1 ] && { what="watchdog: still running after $limit s, killed"; how="timeout"; }
        # Stopped mid-run: the progress file names it (index, level, seed, step).
        if [ ! -f "$dir/progress" ]; then
            printf '0\t-\tshard %s\t%s before any run (see %s)\n' "$4" "$what" "$log" >> "$dir/failures.tsv"
            break
        fi
        IFS=$'\t' read -r index level seed step < "$dir/progress"
        if [ "$timedout" = 1 ]; then
            printf '%s\t%s\tstep %s %s\t%s (see %s)\n' "$level" "$seed" "$step" "$how" "$what" "$log" >> "$dir/failures.tsv"
        else
            sig="$(grep -m1 -E "Fatal error|Illegal instruction|signal|Trace/BPT|Segmentation|precondition" "$log" | cut -c1-200)"
            printf '%s\t%s\tstep %s trap\tprocess died: %s\n' "$level" "$seed" "$step" "${sig:-no message}" >> "$dir/failures.tsv"
        fi
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
    for ((i = 0; i < JOBS; i++)); do wait_for_memory; worker "$1" "$bundle" "$4" "$i" & sleep 5; done
    wait
    cat "$OUT/$1"/shard-*/failures.tsv 2>/dev/null | sort -t$'\t' -k1,1n -k2,2n > "$OUT/$1-failures.tsv"
    cat "$OUT/$1"/shard-*/runs.tsv 2>/dev/null > "$OUT/$1-runs.tsv"
    # Every expected run must have reported (a line in runs.tsv); each one that did not is a row.
    local missing
    missing="$(printf '%s\n' "$EXPECTED" | while IFS=$'\t' read -r l s; do
        awk -F'\t' -v l="$l" -v s="$s" '$1 == l && $2 == s { f = 1 } END { exit !f }' "$OUT/$1-runs.tsv" \
            || printf '%s\t%s\t-\tthe run never reported (see the shard logs in %s)\n' "$l" "$s" "$OUT/$1"
    done)"
    [ -n "$missing" ] && printf '%s\n' "$missing" >> "$OUT/$1-failures.tsv"
    local done_runs
    done_runs=$(awk -F'\t' '{ k[$1 "\t" $2] = 1 } END { n = 0; for (x in k) n++; print n }' "$OUT/$1-runs.tsv")
    local sums
    sums=$(awk -F'\t' '{ l[$1] = 1; s[$2] = 1; t += $3; d += $4; e += $5; c += $6; v += $7 }
        END { nl = 0; for (k in l) nl++; ns = 0; for (k in s) ns++
              printf "levels %d, seeds %d, steps %d, deaths %d, exits %d, conversations %d, saves %d", nl, ns, t, d, e, c, v }' \
        "$OUT/$1-runs.tsv")
    echo "== $1: random play — $sums, failures $(wc -l < "$OUT/$1-failures.tsv" | tr -d ' ') in $((SECONDS - start)) s"
    [ "$done_runs" -lt "$NRUNS" ] && echo "   only $done_runs of $NRUNS runs reported"
    if [ -s "$OUT/$1-failures.tsv" ]; then
        FAILED=1
        echo "level | seed | step / context / keys | error"
        awk -F'\t' '{ printf "%s | %s | %s | %s\n", $1, $2, $3, $4 }' "$OUT/$1-failures.tsv"
    fi
}

FAILED=0
case "$WHICH" in
    core) play core "$ROOT/Ferazel/Core" FerazelRenderTests.xctest FerazelRenderTests.RandomPlayTests/testRandomPlay ;;
    windows) play windows "$ROOT/Ferazel/Windows" FerazelWinKitTests.xctest FerazelWinKitTests.WinRandomPlayTests ;;
    both)
        play core "$ROOT/Ferazel/Core" FerazelRenderTests.xctest FerazelRenderTests.RandomPlayTests/testRandomPlay
        play windows "$ROOT/Ferazel/Windows" FerazelWinKitTests.xctest FerazelWinKitTests.WinRandomPlayTests ;;
    *) echo "usage: $0 [core|windows|both]"; exit 2 ;;
esac
echo "(rows, counts and logs: $OUT)"
exit "$FAILED"
