#!/bin/bash
# Ferazel's Wand — a self-test of the sweep's and the bot's memory watchdog (2026-11-10), with stand-ins only.
#
# Runs the REAL tools/ferazel-visit-sweep.sh and tools/ferazel-random-play.sh with a fake `swift` (the build does
# nothing) and a fake `xcrun` first on PATH, so no game, no test bundle and no real sweep ever runs. The fake xcrun
# becomes a small stand-in: a perl process holding ~300 MB (the memory cases; against a 100 MB limit), a sleep (the
# brake and Ctrl-C cases), or one that prints a passing test (the normal case). Each case checks the script's rows,
# its exit code, and that no stand-in is left running afterwards.
#   memory, xcrun execs the stand-in      (the way xcrun xctest runs on this Mac)
#   memory, xcrun starts it as a child     (the tree walk)
#   memory, the bot's script
#   the machine brake (MIN_RUNNING_FREE_PCT=101, so free memory is always "below the floor")
#   a normal end (exit 0, no rows)
#   Ctrl-C (SIGINT to the script while its worker runs)
# Usage: tools/ferazel-watchdog-selftest.sh   (about a minute; exit 0 = every case passed)
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
T="$(mktemp -d "${TMPDIR:-/tmp}/ferazel-watchdog-selftest.XXXXXX")"
MARK="ferazel-watchdog-selftest-$$"
FAILS=0
mkdir -p "$T/bin"
printf '#!/bin/bash\nexit 0\n' > "$T/bin/swift"
cat > "$T/bin/xcrun" <<EOF
#!/bin/bash
# The stand-in for "xcrun xctest -XCTest <test> <bundle>", chosen by SELFTEST_MODE.
case "\$SELFTEST_MODE" in
    hog)       exec perl -e 'my \$x = "a" x (300 * 1024 * 1024); sleep 120;' $MARK ;;
    hog-child) perl -e 'my \$x = "a" x (300 * 1024 * 1024); sleep 120;' $MARK & wait ;;
    sleep)     exec perl -e 'sleep 120;' $MARK ;;
    pass)      [ -n "\${FERAZEL_BOT_OUT:-}" ] && printf '1\t1\t10\t0\t0\t0\t0\n' >> "\$FERAZEL_BOT_OUT/runs.tsv"
               echo "Test Case '-[Stand.In test]' passed (0.001 seconds)."
               echo "Executed 1 test, with 0 failures (0 unexpected)" ;;
esac
EOF
chmod +x "$T/bin/swift" "$T/bin/xcrun"

check() {   # $1 name, $2 expected exit, $3 actual exit, $4 out file, $5 grep for a row ("" = none expected)
    local ok=1 left
    [ "$3" = "$2" ] || { echo "  exit $3, expected $2"; ok=0; }
    if [ -n "$5" ]; then
        grep -q -- "$5" "$4" || { echo "  no row matching: $5"; ok=0; }
    fi
    left=$(pgrep -f "$MARK" | tr '\n' ' ')
    [ -z "$left" ] || { echo "  stand-ins left running: $left"; pkill -KILL -f "$MARK"; ok=0; }
    if [ "$ok" = 1 ]; then echo "PASS  $1"; else echo "FAIL  $1"; FAILS=$((FAILS + 1)); fi
    grep -E "memory|worker killed|interrupted|^== " "$4" | sed 's/^/      /' | cut -c1-220
}

run() {     # $1 case name, $2 mode, $3 script, then env assignments
    local name="$1" mode="$2" script="$3"; shift 3
    local out="$T/$name.txt"
    env PATH="$T/bin:$PATH" SELFTEST_MODE="$mode" OUT="$T/$name" JOBS=1 FERAZEL_BOT_LEVELS=1 FERAZEL_BOT_SEEDS=1 \
        FERAZEL_BOT_MINUTES=1 "$@" "$ROOT/tools/$script" windows > "$out" 2>&1
    RC=$?
    OUTF="$out"
}

run sweep-memory hog ferazel-visit-sweep.sh MAX_WORKER_MB=100
check "sweep: a worker past the limit is killed, one memory row, no restart" 1 "$RC" "$OUTF" "worker killed at"
[ "$(ls "$T/sweep-memory/windows/shard-0"/run-*.log | wc -l | tr -d ' ')" = 1 ] \
    || { echo "FAIL  sweep: the worker was restarted after a memory kill"; FAILS=$((FAILS + 1)); }

run sweep-memory-child hog-child ferazel-visit-sweep.sh MAX_WORKER_MB=100
check "sweep: the stand-in as xcrun's child is measured and killed too" 1 "$RC" "$OUTF" "worker killed at"

run bot-memory hog ferazel-random-play.sh MAX_WORKER_MB=100
check "bot: a worker past the limit is killed, one memory row" 1 "$RC" "$OUTF" "worker killed at"

run sweep-brake sleep ferazel-visit-sweep.sh MIN_RUNNING_FREE_PCT=101
check "sweep: the machine brake kills the worker" 1 "$RC" "$OUTF" "free memory fell to"

run sweep-normal pass ferazel-visit-sweep.sh MAX_WORKER_MB=100
check "sweep: a worker that ends by itself leaves no row" 0 "$RC" "$OUTF" ""

run bot-normal pass ferazel-random-play.sh MAX_WORKER_MB=100
check "bot: a worker that ends by itself leaves no row" 0 "$RC" "$OUTF" ""

# Ctrl-C: job control on, so the script's background job does not start with SIGINT ignored.
set -m
env PATH="$T/bin:$PATH" SELFTEST_MODE=sleep OUT="$T/sweep-int" JOBS=1 "$ROOT/tools/ferazel-visit-sweep.sh" windows \
    > "$T/sweep-int.txt" 2>&1 &
SP=$!
for _ in $(seq 1 40); do pgrep -f "$MARK" > /dev/null && break; sleep 0.5; done
pgrep -f "$MARK" > /dev/null || echo "  (the stand-in never started)"
kill -INT "$SP"
wait "$SP"; RC=$?
set +m
check "sweep: Ctrl-C kills the worker and its test process" 130 "$RC" "$T/sweep-int.txt" "interrupted"

echo "(outputs: $T)"
[ "$FAILS" = 0 ] && { echo "watchdog self-test: all cases passed"; exit 0; }
echo "watchdog self-test: $FAILS case(s) failed"; exit 1
