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
#   JOBS=n                    processes per path (default 4, never more than 6 — Ben's Mac panicked out of RAM on
#                             2026-10-30 when 14 sweep processes ran beside builds)
#   MIN_FREE_PCT=n  MEMORY_WAIT_S=s   each build and each worker start waits while the Mac's free memory is below n%
#                             (default 30), for up to s seconds (default 600); still below then, it REFUSES: a
#                             `memory` row, nothing more is built or started, exit 1.
#   Every number here must be a plain positive whole number (no leading zero, as "08"): anything else stops the
#   script before it starts anything (exit 2).
#   FERAZEL_BOT_SEEDS=4  FERAZEL_BOT_MINUTES=3  FERAZEL_BOT_LEVELS=1,2      (the defaults: 4 seeds, 3 minutes, all)
#   FERAZEL_BOT_WATCHDOG=s    wall-clock limit of one test process (default 120 s + 120 s per minute of play per run
#                             it has to do); a process past it is killed and its run is a row (then the next run)
#   MAX_WORKER_MB=n           the hard memory limit of one running worker (default 4096). Added 2026-11-10 after
#                             the visit sweep kernel-panicked Ben's 64 GB Mac twice (2026-11-08, 2026-11-10: four
#                             Windows-path workers at 36-40 GB each, a whole game leaked per run); the bot uses the
#                             same path. Every ~3 s each worker's test process is measured (the larger of `ps` resident
#                             size and `top`'s footprint, compressed pages included); past the limit it is killed, a
#                             `memory` row says "worker killed at N MB (limit M MB)", the exit is 1, and that worker is
#                             NOT restarted (a restart would only leak again). See tools/ferazel-worker-watchdog.sh.
#   MIN_RUNNING_FREE_PCT=n    the whole-machine brake (default 15): if the Mac's free memory (`memory_pressure`) falls
#                             below n% while workers run, every worker is killed, no new one starts, no later path
#                             (`both`) is built, and a `memory` row says so.
#   Stopping it: Ctrl-C in a terminal, or `kill <script pid>` (TERM), kills every worker and its test process
#   (nothing is left running; exit 130 / 143). A run started in the background from a script or any other
#   non-interactive shell CANNOT be stopped with Ctrl-C or `kill -INT`: bash starts such background jobs with
#   interrupts ignored, and an ignored signal cannot be caught. Stop it with `kill <script pid>`.
#   Quick mode for a class task: FERAZEL_BOT_LEVELS=n FERAZEL_BOT_MINUTES=1 tools/ferazel-random-play.sh core
# Exit 0 = no rows and every expected run (levels x seeds) reported; 1 = rows (the table is printed: a failed or
# skipped test, a run that never reported, a watchdog kill, a trap, the bot's own rows); 2 = a build failed or a bad
# setting (a level outside BuiltLevels.range, a number that is not a plain positive whole number); 130 / 143 / 129 =
# stopped (INT / TERM / HUP).
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
# The running workers' memory limit, the machine brake and the memory wait (2026-11-10); it checks its settings
# (MAX_WORKER_MB, MIN_RUNNING_FREE_PCT, WW_SAMPLE_S, MIN_FREE_PCT, MEMORY_WAIT_S) and refuses bad ones (exit 2).
. "$ROOT/tools/ferazel-worker-watchdog.sh"
ww_number JOBS 4
[ "$JOBS" -gt 6 ] && JOBS=6
[ -n "${FERAZEL_BOT_WATCHDOG+set}" ] && ww_number FERAZEL_BOT_WATCHDOG 0

bad() { echo "random play: $1"; exit 2; }
# A plain positive whole number (no leading zero: bash reads "08" as a broken octal number).
positive() { case "$1" in ''|0*|*[!0-9]*|??????????*) return 1 ;; esac; }

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

OUT="${OUT:-$(mktemp -d "${TMPDIR:-/tmp}/ferazel-random-play.XXXXXX")}"
mkdir -p "$OUT"
export FERAZEL_BOT=1
WW_BRAKE="$OUT/memory-brake"
WW_LOG_DIR="$OUT"   # the script's own warnings (each worker has its own folder)
rm -f "$WW_BRAKE" "$OUT"/.watchdog-*
trap 'ww_cleanup 130' INT
trap 'ww_cleanup 143' TERM
trap 'ww_cleanup 129' HUP

# Only the files this script writes.
for p in core windows; do
    rm -f "${OUT:?}/$p-failures.tsv" "${OUT:?}/$p-runs.tsv"
    for d in "${OUT:?}/$p"/shard-*; do
        [ -d "$d" ] && rm -f "${d:?}"/failures.tsv "${d:?}"/runs.tsv "${d:?}"/progress "${d:?}"/run-*.log
    done
done
rm -f "${OUT:?}/build-Core.log" "${OUT:?}/build-Windows.log"

build() {   # $1 package dir (in the background and waited for, so a TERM is acted on at once)
    (cd "$1" && swift build -j 4 -c release --build-tests -Xswiftc -enable-testing > "$OUT/build-$(basename "$1").log" 2>&1) &
    wait $! || { echo "BUILD FAILED: $1 (see $OUT/build-$(basename "$1").log)"; exit 2; }
}

# One shard of one path; resumes after a trap or a timeout kill from the run after the one it stopped on — never
# after a memory kill or a watchdog failure. Its test process is recorded (test.pid) and killed with it, however the
# worker ends.
worker() {  # $1 path name, $2 xctest bundle, $3 test, $4 shard index
    local dir="$OUT/$1/shard-$4" from=0 n=0
    mkdir -p "$dir"
    WW_LOG_DIR="$dir"
    rm -f "$dir"/.watchdog-* "$dir"/test.pid "$dir"/watchdog-warnings.log
    ww_worker_traps
    while :; do
        n=$((n + 1))
        local log="$dir/run-$n.log" left=0 i limit pid timedout=0
        if ww_braked; then
            printf '0\t-\tshard %s\tnot started: %s\n' "$4" "$(ww_brake_text)" >> "$dir/failures.tsv"
            break
        fi
        for ((i = from; i < NRUNS; i++)); do [ $((i % JOBS)) -eq "$4" ] && left=$((left + 1)); done
        limit="${FERAZEL_BOT_WATCHDOG:-$((120 + left * MINUTES * 120))}"
        FERAZEL_BOT_SHARD="$4/$JOBS" FERAZEL_BOT_OUT="$dir" FERAZEL_BOT_FROM="$from" \
            xcrun xctest -XCTest "$3" "$2" > "$log" 2>&1 &
        pid=$!
        ww_track "$pid"
        local deadline=$((SECONDS + limit))
        ww_watch "$pid" "$deadline"
        if [ "$WW_RESULT" = timeout ]; then
            timedout=1
            pkill -KILL -P "$pid" 2>/dev/null; kill -KILL "$pid" 2>/dev/null
        fi
        wait "$pid" 2>/dev/null
        ww_untrack
        if [ "$WW_RESULT" = memory ] || [ "$WW_RESULT" = brake ] || [ "$WW_RESULT" = broken ]; then
            # Killed for memory (or the watchdog failed): one row (on the run it was on, when the progress file names
            # it), and no restart.
            local why kind=memory
            if [ "$WW_RESULT" = memory ]; then
                why="worker killed at $WW_MB MB (limit $MAX_WORKER_MB MB)"
            elif [ "$WW_RESULT" = brake ]; then
                why="$(ww_brake_text)"
            else
                why="$WW_WHY"; kind=watchdog
            fi
            if [ -f "$dir/progress" ]; then
                IFS=$'\t' read -r index level seed step < "$dir/progress"
                printf '%s\t%s\tstep %s %s\t%s (see %s)\n' "$level" "$seed" "$step" "$kind" "$why" "$log" >> "$dir/failures.tsv"
                printf '%s\t%s\t%s\t0\t0\t0\t0\n' "$level" "$seed" "$step" >> "$dir/runs.tsv"
            else
                printf '0\t-\tshard %s\t%s before any run (see %s)\n' "$4" "$why" "$log" >> "$dir/failures.tsv"
            fi
            break
        fi
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
        case "$index" in ''|*[!0-9]*)
            printf '0\t-\tshard %s\tunreadable progress file (index %s), not resumed\n' "$4" "$index" >> "$dir/failures.tsv"
            break ;;
        esac
        from=$((10#$index + 1))
        [ "$n" -ge 50 ] && { printf '0\t-\tprocess\t50 traps, gave up\n' >> "$dir/failures.tsv"; break; }
    done
}

play() {    # $1 path name, $2 package dir, $3 bundle name, $4 test
    local start=$SECONDS i
    # The brake pulled (an earlier path), or free memory still low after the wait: no build, no worker, one row.
    if ! ww_wait_for_memory; then
        printf '0\t-\tmemory\tnot started (not built): %s\n' "$(ww_brake_text)" > "$OUT/$1-failures.tsv"
        echo "== $1: random play — not started: $(ww_brake_text), failures 1"
        FAILED=1
        return 0
    fi
    build "$2"
    local bundle="$2/.build/release/$3"
    for ((i = 0; i < JOBS; i++)); do
        ww_wait_for_memory   # refused: the brake is pulled, so this worker and the rest write "not started"
        worker "$1" "$bundle" "$4" "$i" &
        ww_braked || sleep 5
    done
    wait
    # A worker that died leaving its test process running: that process is killed now, and it is a row (the runs it
    # never reported are rows too, below).
    for ((i = 0; i < JOBS; i++)); do
        mkdir -p "$OUT/$1/shard-$i"
        ww_reap_shard "$OUT/$1/shard-$i" || printf '0\t-\tshard %s\t%s\n' "$i" "$WW_REAPED" >> "$OUT/$1/shard-$i/failures.tsv"
    done
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
esac
echo "(rows, counts and logs: $OUT)"
exit "$FAILED"
