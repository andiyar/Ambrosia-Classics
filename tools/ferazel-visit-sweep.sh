#!/bin/bash
# Ferazel's Wand — the "visit every object" sweep (2026-10-29, after the Windows beta's teleporter and level-2 quits).
#
# For every level in the playable scope (VisitSweep.levels = BuiltLevels.range) and every spawned placement record,
# Ferazel is put beside the record by a checkpoint save (on it, 48 px left, 48 px right, 64 px above), the real flow
# continues that save (GameFlow → LevelRun, the real renderers) and plays ~4 s of keys (stand, walk into it, tap up,
# down, cast, jump, use); conversations are read through and left by their last answer, dialogs answered as the shells
# answer them. Any render refusal, thrown error, error/report dialog, quit, stuck modal (600 ticks with nothing moving)
# or trap (the process dies: the visit it was on, from the progress file) is a row. Two paths:
#   core     Ferazel/Core    FerazelRenderTests.VisitSweepTests        (Core + FerazelRender, the driver mirrored)
#   windows  Ferazel/Windows FerazelWinKitTests.WinVisitSweepTests     (headless WinGame + the shared FerazelDriver)
#
# Usage: tools/ferazel-visit-sweep.sh [core|windows|both]   (default both)
#   JOBS=n            processes per path (default 4, never more than 6 — Ben's Mac panicked out of RAM on 2026-10-30
#                     when 14 sweep processes ran beside builds)
#   MIN_FREE_PCT=n  MEMORY_WAIT_S=s   each build and each worker start waits while the Mac's free memory is below n%
#                     (default 30), for up to s seconds (default 600); still below then, it REFUSES: a `memory` row,
#                     nothing more is built or started, exit 1.
#   Every number above and below must be a plain positive whole number (no leading zero, as "08"): anything else
#   stops the script before it starts anything (exit 2).
#   MAX_WORKER_MB=n   the hard memory limit of one running worker (default 4096). Added 2026-11-10 after the sweep
#                     kernel-panicked Ben's 64 GB Mac twice (2026-11-08, 2026-11-10: four Windows-path workers at
#                     36-40 GB each, a whole game leaked per visit). Every ~3 s each worker's test process is measured
#                     (the larger of `ps` resident size and `top`'s footprint, compressed pages included); past the
#                     limit it is killed, a `memory` row says "worker killed at N MB (limit M MB)", the exit is 1, and
#                     that worker is NOT restarted (a restart would only leak again). See tools/ferazel-worker-watchdog.sh.
#   MIN_RUNNING_FREE_PCT=n   the whole-machine brake (default 15): if the Mac's free memory (`memory_pressure`) falls
#                     below n% while workers run, every worker is killed, no new one starts, no later path (`both`)
#                     is built, and a `memory` row says so.
#   Stopping it: Ctrl-C in a terminal, or `kill <script pid>` (TERM), kills every worker and its test process
#   (nothing is left running; exit 130 / 143). A run started in the background from a script or any other
#   non-interactive shell CANNOT be stopped with Ctrl-C or `kill -INT`: bash starts such background jobs with
#   interrupts ignored, and an ignored signal cannot be caught. Stop it with `kill <script pid>`.
#   FERAZEL_VISIT_LEVELS=2,3  FERAZEL_VISIT_OFFSETS=on,above  FERAZEL_VISIT_LIMIT=n   narrow it (a quick look)
# Exit 0 = no rows; 1 = rows (the table is printed; a shard that ended without finishing is a row too); 2 = a build
# failed or a bad setting; 130 / 143 / 129 = stopped (INT / TERM / HUP).
# Release builds (-enable-testing): a debug build is far too slow. Headless: no window, no audio device, nothing
# launched; it writes only to a temporary folder (OUT=dir keeps the rows, coverage and logs there).
#
# THE UNATTENDED LOOP runs it at every phase end (before staging, beside the gate card), from the phase's worktree:
#     tools/ferazel-visit-sweep.sh both > "$OUT/visit-sweep.txt" 2>&1; echo "exit $?"
# A non-zero exit blocks the phase end: every row is a game-ending bug for a player (both shells quit on a render
# failure) — file each as a fix task, do not stage. When a phase adds levels, BuiltLevels.range grows and the sweep
# follows. Paste the summary lines (visits, teleporter arrivals, exits that reached the map) into the gate card.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WHICH="${1:-both}"
case "$WHICH" in core|windows|both) ;; *) echo "usage: $0 [core|windows|both]"; exit 2 ;; esac
# The running workers' memory limit, the machine brake and the memory wait (2026-11-10); it checks its settings
# (MAX_WORKER_MB, MIN_RUNNING_FREE_PCT, WW_SAMPLE_S, MIN_FREE_PCT, MEMORY_WAIT_S) and refuses bad ones (exit 2).
. "$ROOT/tools/ferazel-worker-watchdog.sh"
ww_number JOBS 4
[ "$JOBS" -gt 6 ] && JOBS=6
OUT="${OUT:-$(mktemp -d "${TMPDIR:-/tmp}/ferazel-visit-sweep.XXXXXX")}"
mkdir -p "$OUT"
export FERAZEL_VISIT_SWEEP=1
WW_BRAKE="$OUT/memory-brake"
WW_LOG_DIR="$OUT"   # the script's own warnings (each worker has its own folder)
rm -f "$WW_BRAKE" "$OUT"/.watchdog-*
trap 'ww_cleanup 130' INT
trap 'ww_cleanup 143' TERM
trap 'ww_cleanup 129' HUP

build() {   # $1 package dir (in the background and waited for, so a TERM is acted on at once)
    (cd "$1" && swift build -j 4 -c release --build-tests -Xswiftc -enable-testing > "$OUT/build-$(basename "$1").log" 2>&1) &
    wait $! || { echo "BUILD FAILED: $1 (see $OUT/build-$(basename "$1").log)"; exit 2; }
}

# One shard of one path; resumes after a trap from the visit after the one it died on — never after a memory kill or
# a watchdog failure. Its test process is recorded (test.pid) and killed with it, however the worker ends.
worker() {  # $1 path name, $2 xctest bundle, $3 test, $4 shard index
    local dir="$OUT/$1/shard-$4" from="0:0" n=0 pid
    mkdir -p "$dir"
    WW_LOG_DIR="$dir"
    rm -f "$dir"/.watchdog-* "$dir"/test.pid "$dir"/watchdog-warnings.log
    ww_worker_traps
    while :; do
        n=$((n + 1))
        if ww_braked; then
            printf '0\t-\t-\t-\tmemory\tnot started: %s\n' "$(ww_brake_text)" >> "$dir/failures.tsv"
            break
        fi
        FERAZEL_VISIT_SHARD="$4/$JOBS" FERAZEL_VISIT_OUT="$dir" FERAZEL_VISIT_FROM="$from" \
            xcrun xctest -XCTest "$3" "$2" > "$dir/run-$n.log" 2>&1 &
        pid=$!
        ww_track "$pid"
        ww_watch "$pid"
        wait "$pid" 2>/dev/null
        ww_untrack
        if [ "$WW_RESULT" = memory ] || [ "$WW_RESULT" = brake ] || [ "$WW_RESULT" = broken ]; then
            # Killed for memory (or the watchdog failed): one row (on the visit it was on, when the progress file
            # names it), and no restart.
            local why kind=memory lv="0" rc="-" ty="-" of="-"
            if [ -f "$dir/progress" ]; then
                IFS=$'\t' read -r lv index label rc ty of < "$dir/progress"
            fi
            if [ "$WW_RESULT" = memory ]; then
                why="worker killed at $WW_MB MB (limit $MAX_WORKER_MB MB)"
            elif [ "$WW_RESULT" = brake ]; then
                why="$(ww_brake_text)"
            else
                why="$WW_WHY"; kind=watchdog
            fi
            printf '%s\t%s\t%s\t%s\t%s\t%s (see %s)\n' "$lv" "$rc" "$ty" "$of" "$kind" "$why" "$dir/run-$n.log" \
                >> "$dir/failures.tsv"
            break
        fi
        if grep -q "Executed 1 test" "$dir/run-$n.log"; then break; fi
        # Died mid-visit: the progress file names it (level, index, label, record, type, offset).
        if [ ! -f "$dir/progress" ]; then
            printf '0\t-\t-\t-\tprocess\tdied before any visit (see %s)\n' "$dir/run-$n.log" >> "$dir/failures.tsv"
            break
        fi
        IFS=$'\t' read -r level index label record type offset < "$dir/progress"
        sig="$(grep -m1 -E "Fatal error|Illegal instruction|signal|Trace/BPT|Segmentation|precondition" "$dir/run-$n.log" | cut -c1-200)"
        printf '%s\t%s\t%s\t%s\ttrap\tprocess died: %s\n' "$level" "$record" "$type" "$offset" "${sig:-no message}" >> "$dir/failures.tsv"
        rm -f "$dir/progress"
        case "$index" in ''|*[!0-9]*)
            printf '0\t-\t-\t-\tprocess\tunreadable progress file (index %s), not resumed\n' "$index" >> "$dir/failures.tsv"
            break ;;
        esac
        from="$level:$((10#$index + 1))"
        [ "$n" -ge 50 ] && { printf '0\t-\t-\t-\tprocess\t50 traps, gave up\n' >> "$dir/failures.tsv"; break; }
    done
}

sweep() {   # $1 path name, $2 package dir, $3 bundle name, $4 test
    local start=$SECONDS i d last
    # The brake pulled (an earlier path), or free memory still low after the wait: no build, no worker, one row.
    if ! ww_wait_for_memory; then
        printf '0\t-\t-\t-\tmemory\tnot started (not built): %s\n' "$(ww_brake_text)" > "$OUT/$1-failures.tsv"
        echo "== $1: not started: $(ww_brake_text); rows 1"
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
    # Every shard must have finished (its last run log says "Executed 1 test") or written a row; a worker that died
    # without either is a row, and a test process it left behind is killed now.
    for ((i = 0; i < JOBS; i++)); do
        d="$OUT/$1/shard-$i"
        mkdir -p "$d"
        if ! ww_reap_shard "$d"; then
            printf '0\t-\t-\t-\tprocess\tshard %s ended without finishing and without a row: %s (see %s)\n' \
                "$i" "$WW_REAPED" "$d" >> "$d/failures.tsv"
            continue
        fi
        [ -s "$d/failures.tsv" ] && continue
        last=$(ls "$d" | sed -n 's/^run-\([0-9][0-9]*\)\.log$/\1/p' | sort -n | tail -n 1)
        [ -n "$last" ] && grep -q "Executed 1 test" "$d/run-$last.log" && continue
        printf '0\t-\t-\t-\tprocess\tshard %s ended without finishing and without a row (see %s)\n' "$i" "$d" >> "$d/failures.tsv"
    done
    cat "$OUT/$1"/shard-*/failures.tsv 2>/dev/null | sort -t$'\t' -k1,1n -k2,2n > "$OUT/$1-failures.tsv"
    cat "$OUT/$1"/shard-*/seen.tsv 2>/dev/null > "$OUT/$1-seen.tsv"
    local visits tele arrived exits mapped
    visits=$(wc -l < "$OUT/$1-seen.tsv" | tr -d ' ')
    tele=$(awk -F'\t' '$8 ~ /teleport1/' "$OUT/$1-seen.tsv" | wc -l | tr -d ' ')
    arrived=$(awk -F'\t' '$5=="true"' "$OUT/$1-seen.tsv" | wc -l | tr -d ' ')
    exits=$(awk -F'\t' '$6=="true"' "$OUT/$1-seen.tsv" | wc -l | tr -d ' ')
    mapped=$(awk -F'\t' '$7=="true"' "$OUT/$1-seen.tsv" | wc -l | tr -d ' ')
    echo "== $1: $visits visits in $((SECONDS - start)) s (build included); a teleport fired in $tele, arrived in $arrived;" \
         "a level exit taken in $exits, reached the world map in $mapped; rows $(wc -l < "$OUT/$1-failures.tsv" | tr -d ' ')"
    if [ -s "$OUT/$1-failures.tsv" ]; then
        echo "level | record | type | offset | frame / input | error"
        awk -F'\t' '{ printf "%s | %s | %s | %s | %s | %s\n", $1, $2, $3, $4, $5, $6 }' "$OUT/$1-failures.tsv"
    fi
}

case "$WHICH" in
    core) sweep core "$ROOT/Ferazel/Core" FerazelRenderTests.xctest FerazelRenderTests.VisitSweepTests ;;
    windows) sweep windows "$ROOT/Ferazel/Windows" FerazelWinKitTests.xctest FerazelWinKitTests.WinVisitSweepTests ;;
    both)
        sweep core "$ROOT/Ferazel/Core" FerazelRenderTests.xctest FerazelRenderTests.VisitSweepTests
        sweep windows "$ROOT/Ferazel/Windows" FerazelWinKitTests.xctest FerazelWinKitTests.WinVisitSweepTests ;;
esac
echo "(rows, coverage and logs: $OUT)"
cat "$OUT"/*-failures.tsv 2>/dev/null | grep -q . && exit 1
exit 0
