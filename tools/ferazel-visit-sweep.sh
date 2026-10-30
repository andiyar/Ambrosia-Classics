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
#                     when 14 sweep processes ran beside builds; each worker also waits while free memory is < 30%)
#   FERAZEL_VISIT_LEVELS=2,3  FERAZEL_VISIT_OFFSETS=on,above  FERAZEL_VISIT_LIMIT=n   narrow it (a quick look)
# Exit 0 = no rows; 1 = rows (the table is printed); 2 = a build failed.
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
JOBS="${JOBS:-4}"
[ "$JOBS" -gt 6 ] 2>/dev/null && JOBS=6
[ "$JOBS" -lt 1 ] 2>/dev/null && JOBS=1
MIN_FREE_PCT="${MIN_FREE_PCT:-30}"
OUT="${OUT:-$(mktemp -d "${TMPDIR:-/tmp}/ferazel-visit-sweep.XXXXXX")}"
mkdir -p "$OUT"
export FERAZEL_VISIT_SWEEP=1

# Waits (up to 10 min) while the system's free memory is below MIN_FREE_PCT, so the sweep never pushes the Mac into swap.
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

# One shard of one path; resumes after a trap from the visit after the one it died on.
worker() {  # $1 path name, $2 xctest bundle, $3 test, $4 shard index
    local dir="$OUT/$1/shard-$4" from="0:0" n=0
    mkdir -p "$dir"
    while :; do
        n=$((n + 1))
        FERAZEL_VISIT_SHARD="$4/$JOBS" FERAZEL_VISIT_OUT="$dir" FERAZEL_VISIT_FROM="$from" \
            xcrun xctest -XCTest "$3" "$2" > "$dir/run-$n.log" 2>&1
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
        from="$level:$((index + 1))"
        [ "$n" -ge 50 ] && { printf '0\t-\t-\t-\tprocess\t50 traps, gave up\n' >> "$dir/failures.tsv"; break; }
    done
}

sweep() {   # $1 path name, $2 package dir, $3 bundle name, $4 test
    local start=$SECONDS
    build "$2"
    local bundle="$2/.build/release/$3"
    for ((i = 0; i < JOBS; i++)); do wait_for_memory; worker "$1" "$bundle" "$4" "$i" & sleep 5; done
    wait
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
    *) echo "usage: $0 [core|windows|both]"; exit 2 ;;
esac
echo "(rows, coverage and logs: $OUT)"
cat "$OUT"/*-failures.tsv 2>/dev/null | grep -q . && exit 1
exit 0
