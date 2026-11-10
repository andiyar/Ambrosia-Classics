#!/bin/bash
# Ferazel's Wand — a self-test of the sweep's and the bot's memory watchdog (2026-11-10), with stand-ins only.
#
# Runs the REAL tools/ferazel-visit-sweep.sh and tools/ferazel-random-play.sh with fakes first on PATH, so no game, no
# test bundle and no real sweep ever runs: `swift` (the build does nothing; it notes which package it was asked to
# build), `memory_pressure` (a fixed free percentage, 50% unless a case says otherwise, or nothing at all), `top`
# (the real one, or nothing at all) and `xcrun`, which becomes a small stand-in: a perl process holding ~300 MB (the
# memory cases; against a 100 MB limit), a sleep (the brake and stop cases), one that prints a passing test (the
# normal case), or one that kills its own worker first (a worker that dies without a row). Each case checks the
# script's rows, its exit code, and that no stand-in is left running afterwards.
#   memory: xcrun execs the stand-in (the way xcrun xctest runs on this Mac); xcrun starts it as a child (the tree
#     walk); the bot's script; neither restarts the worker
#   the machine brake, sweep and bot (MIN_RUNNING_FREE_PCT above the fake 50%)
#   the brake during `both`: the second path is never built
#   free memory still low after the wait (MEMORY_WAIT_S): it refuses, nothing built
#   a normal end (exit 0, no rows), sweep and bot
#   a bad setting (WW_SAMPLE_S=08, …): refuses to start, exit 2, nothing started
#   a worker that dies without a row (its test process ended, or still running): a row, exit 1, nothing left running
#   no reading from top or memory_pressure: one warning each per worker
#   stopping it: TERM to the script and its worker subshells (as `pkill -f` would), TERM to the script alone, Ctrl-C
# Usage: /bin/bash tools/ferazel-watchdog-selftest.sh   (a couple of minutes; exit 0 = every case passed)
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
T="$(mktemp -d "${TMPDIR:-/tmp}/ferazel-watchdog-selftest.XXXXXX")"
MARK="ferazel-watchdog-selftest-$$"
FAILS=0
PASSES=0
trap 'pkill -KILL -f "$MARK" 2>/dev/null; rm -rf "$T"' EXIT
mkdir -p "$T/bin"
cat > "$T/bin/swift" <<'EOF'
#!/bin/bash
[ -n "${SELFTEST_BUILDS:-}" ] && pwd >> "$SELFTEST_BUILDS"
exit 0
EOF
cat > "$T/bin/memory_pressure" <<'EOF'
#!/bin/bash
[ "${SELFTEST_FREE:-50}" = none ] && exit 0
echo "System-wide memory free percentage: ${SELFTEST_FREE:-50}%"
EOF
cat > "$T/bin/top" <<'EOF'
#!/bin/bash
[ "${SELFTEST_TOP:-}" = none ] && exit 0
exec /usr/bin/top "$@"
EOF
cat > "$T/bin/xcrun" <<EOF
#!/bin/bash
# The stand-in for "xcrun xctest -XCTest <test> <bundle>", chosen by SELFTEST_MODE.
pass() {
    [ -n "\${FERAZEL_BOT_OUT:-}" ] && printf '1\t1\t10\t0\t0\t0\t0\n' >> "\$FERAZEL_BOT_OUT/runs.tsv"
    echo "Test Case '-[Stand.In test]' passed (0.001 seconds)."
    echo "Executed 1 test, with 0 failures (0 unexpected)"
}
case "\$SELFTEST_MODE" in
    hog)       exec perl -e 'my \$x = "a" x (300 * 1024 * 1024); sleep 120;' $MARK ;;
    hog-child) perl -e 'my \$x = "a" x (300 * 1024 * 1024); sleep 120;' $MARK & wait ;;
    sleep)     exec perl -e 'sleep 120;' $MARK ;;
    pass)      pass ;;
    slowpass)  perl -e 'sleep 4;' $MARK; pass ;;
    orphan)    sleep 1; kill -KILL \$PPID; exec perl -e 'sleep 120;' $MARK ;;
    dies)      sleep 1; kill -KILL \$PPID; exit 0 ;;
    vanish)    sleep 1; rm -f "\${FERAZEL_VISIT_OUT:-/nonexistent}/test.pid"; kill -KILL \$PPID; exit 0 ;;
esac
EOF
chmod +x "$T/bin/swift" "$T/bin/memory_pressure" "$T/bin/top" "$T/bin/xcrun"

verdict() { # $1 name, $2 1 = ok
    if [ "$2" = 1 ]; then echo "PASS  $1"; PASSES=$((PASSES + 1)); else echo "FAIL  $1"; FAILS=$((FAILS + 1)); fi
}

check() {   # $1 name, $2 expected exit, $3 actual exit, $4 out file, $5 grep for a row ("" = none expected)
    local ok=1 left
    [ "$3" = "$2" ] || { echo "  exit $3, expected $2"; ok=0; }
    if [ -n "$5" ]; then
        grep -q -- "$5" "$4" || { echo "  no line matching: $5"; ok=0; }
    fi
    left=$(pgrep -f "$MARK" | tr '\n' ' ')
    [ -z "$left" ] || { echo "  stand-ins left running: $left"; pkill -KILL -f "$MARK"; ok=0; }
    verdict "$1" "$ok"
    grep -E "memory|worker killed|interrupted|refusing|watchdog|ended without|^== " "$4" | sed 's/^/      /' | cut -c1-220
}

# The process and everything under it, one per line.
tree() {
    local k
    echo "$1"
    for k in $(pgrep -P "$1" 2>/dev/null); do tree "$k"; done
}

WHICH=windows
run() {     # $1 case name, $2 mode, $3 script, then env assignments
    local name="$1" mode="$2" script="$3"; shift 3
    local out="$T/$name.txt"
    env PATH="$T/bin:$PATH" SELFTEST_MODE="$mode" OUT="$T/$name" JOBS=1 FERAZEL_BOT_LEVELS=1 FERAZEL_BOT_SEEDS=1 \
        FERAZEL_BOT_MINUTES=1 "$@" /bin/bash "$ROOT/tools/$script" "$WHICH" > "$out" 2>&1
    RC=$?
    OUTF="$out"
}

# Starts a script in the background (stand-in: a sleep) and waits until its stand-in runs; SP = the script's pid.
start_bg() {   # $1 case name, $2 script
    env PATH="$T/bin:$PATH" SELFTEST_MODE=sleep OUT="$T/$1" JOBS=1 FERAZEL_BOT_LEVELS=1 FERAZEL_BOT_SEEDS=1 \
        FERAZEL_BOT_MINUTES=1 /bin/bash "$ROOT/tools/$2" windows > "$T/$1.txt" 2>&1 &
    SP=$!
    for _ in $(seq 1 40); do pgrep -f "$MARK" > /dev/null && break; sleep 0.5; done
    pgrep -f "$MARK" > /dev/null || echo "  (the stand-in never started)"
}

# The real memory_pressure must give the helper a reading (the fakes stand in for it everywhere else).
real=$( (unset MAX_WORKER_MB MIN_RUNNING_FREE_PCT WW_SAMPLE_S MIN_FREE_PCT MEMORY_WAIT_S
         . "$ROOT/tools/ferazel-worker-watchdog.sh"; ww_free_pct) )
case "$real" in ''|*[!0-9]*) echo "  the real memory_pressure gave: '$real'"; verdict "the real memory_pressure is read" 0 ;;
    *) verdict "the real memory_pressure is read ($real% free)" 1 ;; esac

# Memory.
run sweep-memory hog ferazel-visit-sweep.sh MAX_WORKER_MB=100
check "sweep: a worker past the limit is killed, one memory row" 1 "$RC" "$OUTF" "worker killed at"
[ "$(ls "$T/sweep-memory/windows/shard-0"/run-*.log | wc -l | tr -d ' ')" = 1 ]; verdict "sweep: no restart after a memory kill" $((1 - $?))

run sweep-memory-child hog-child ferazel-visit-sweep.sh MAX_WORKER_MB=100
check "sweep: the stand-in as xcrun's child is measured and killed too" 1 "$RC" "$OUTF" "worker killed at"

run bot-memory hog ferazel-random-play.sh MAX_WORKER_MB=100
check "bot: a worker past the limit is killed, one memory row" 1 "$RC" "$OUTF" "worker killed at"
[ "$(ls "$T/bot-memory/windows/shard-0"/run-*.log | wc -l | tr -d ' ')" = 1 ]; verdict "bot: no restart after a memory kill" $((1 - $?))

# The machine brake.
run sweep-brake sleep ferazel-visit-sweep.sh MIN_RUNNING_FREE_PCT=60
check "sweep: the machine brake kills the worker" 1 "$RC" "$OUTF" "free memory fell to"

run bot-brake sleep ferazel-random-play.sh MIN_RUNNING_FREE_PCT=60
check "bot: the machine brake kills the worker" 1 "$RC" "$OUTF" "free memory fell to"

WHICH=both
run sweep-brake-both sleep ferazel-visit-sweep.sh MIN_RUNNING_FREE_PCT=60 SELFTEST_BUILDS="$T/sweep-brake-both.builds"
check "sweep: after a brake, both's second path is not started" 1 "$RC" "$OUTF" "windows: not started"
[ "$(grep -c . "$T/sweep-brake-both.builds")" = 1 ] && grep -q "Ferazel/Core$" "$T/sweep-brake-both.builds"
verdict "sweep: after a brake, both's second path is not built" $((1 - $?))

run bot-brake-both sleep ferazel-random-play.sh MIN_RUNNING_FREE_PCT=60 SELFTEST_BUILDS="$T/bot-brake-both.builds"
check "bot: after a brake, both's second path is not started" 1 "$RC" "$OUTF" "windows: random play — not started"
[ "$(grep -c . "$T/bot-brake-both.builds")" = 1 ]; verdict "bot: after a brake, both's second path is not built" $((1 - $?))
WHICH=windows

# Free memory still low after the wait: refuse, never "continue anyway".
run sweep-lowmem pass ferazel-visit-sweep.sh MIN_FREE_PCT=60 MEMORY_WAIT_S=2 SELFTEST_BUILDS="$T/sweep-lowmem.builds"
check "sweep: free memory still low after the wait refuses (memory row)" 1 "$RC" "$OUTF" "stayed below 60%"
[ ! -s "$T/sweep-lowmem.builds" ] && [ ! -d "$T/sweep-lowmem/windows" ]; verdict "sweep: nothing built or started" $((1 - $?))

run bot-lowmem pass ferazel-random-play.sh MIN_FREE_PCT=60 MEMORY_WAIT_S=2 SELFTEST_BUILDS="$T/bot-lowmem.builds"
check "bot: free memory still low after the wait refuses (memory row)" 1 "$RC" "$OUTF" "stayed below 60%"
[ ! -s "$T/bot-lowmem.builds" ]; verdict "bot: nothing built" $((1 - $?))

# Normal ends.
run sweep-normal pass ferazel-visit-sweep.sh MAX_WORKER_MB=100
check "sweep: a worker that ends by itself leaves no row" 0 "$RC" "$OUTF" ""

run bot-normal pass ferazel-random-play.sh MAX_WORKER_MB=100
check "bot: a worker that ends by itself leaves no row" 0 "$RC" "$OUTF" ""

# Bad settings: refuse to start (exit 2), never default silently, never run unguarded.
for bad in "sweep WW_SAMPLE_S=08" "sweep WW_SAMPLE_S=09" "bot WW_SAMPLE_S=08" "sweep MAX_WORKER_MB=0" \
           "bot MIN_RUNNING_FREE_PCT=abc" "sweep JOBS=08" "bot JOBS=x" "sweep MIN_FREE_PCT=" "bot MEMORY_WAIT_S=-1" \
           "bot FERAZEL_BOT_MINUTES=08" "bot FERAZEL_BOT_WATCHDOG=010"; do
    who="${bad%% *}"; setting="${bad#* }"; name="bad-$who-$(echo "$setting" | tr -c 'A-Za-z0-9\n' '_')"
    script=ferazel-visit-sweep.sh; [ "$who" = bot ] && script=ferazel-random-play.sh
    run "$name" pass "$script" "$setting" SELFTEST_BUILDS="$T/$name.builds"
    check "$who: $setting refuses to start" 2 "$RC" "$OUTF" "${setting%%=*}"
    [ ! -s "$T/$name.builds" ] && [ ! -d "$T/$name/windows" ]; verdict "$who: $setting started nothing" $((1 - $?))
done

# A worker that dies without writing a row (its stand-in kills it, then ends / keeps running).
run sweep-vanish vanish ferazel-visit-sweep.sh
check "sweep: a shard that ends without finishing or a row is a process row" 1 "$RC" "$OUTF" "without a row (see"
run sweep-dies dies ferazel-visit-sweep.sh
check "sweep: ... a worker that died during a run is one too" 1 "$RC" "$OUTF" "test process had ended"
run sweep-orphan orphan ferazel-visit-sweep.sh
check "sweep: ... and a test process its dead worker left running is killed" 1 "$RC" "$OUTF" "still ran (killed now)"
run bot-dies dies ferazel-random-play.sh
check "bot: a shard that ends without a row is a row (the run never reported)" 1 "$RC" "$OUTF" "never reported"
run bot-orphan orphan ferazel-random-play.sh
check "bot: ... and a test process its dead worker left running is killed" 1 "$RC" "$OUTF" "still ran (killed now)"

# No reading from top / memory_pressure: one warning each, per worker (the stand-in lives ~4 s, sampled every 1 s).
run sweep-noreading slowpass ferazel-visit-sweep.sh SELFTEST_TOP=none SELFTEST_FREE=none WW_SAMPLE_S=1
check "sweep: no top / memory_pressure reading still runs" 0 "$RC" "$OUTF" ""
W="$T/sweep-noreading/windows/shard-0/watchdog-warnings.log"
[ "$(grep -c "top gave no reading" "$W" 2>/dev/null)" = 1 ] && [ "$(grep -c "brake cannot work" "$W" 2>/dev/null)" = 1 ] \
    && grep -q "top gave no reading" "$OUTF" && grep -q "brake cannot work" "$OUTF"
verdict "sweep: one warning per kind, in the worker's folder and on stderr" $((1 - $?))

run bot-noreading slowpass ferazel-random-play.sh SELFTEST_TOP=none SELFTEST_FREE=none WW_SAMPLE_S=1
check "bot: no top / memory_pressure reading still runs" 0 "$RC" "$OUTF" ""
W="$T/bot-noreading/windows/shard-0/watchdog-warnings.log"
[ "$(grep -c "top gave no reading" "$W" 2>/dev/null)" = 1 ] && [ "$(grep -c "brake cannot work" "$W" 2>/dev/null)" = 1 ]
verdict "bot: one warning per kind in the worker's folder" $((1 - $?))

# The measuring loop itself dies (KILL) while the test runs: the test process is killed, a `watchdog` row, exit 1.
# The loop is the script-named process two levels under the script (script → worker → loop).
for s in ferazel-visit-sweep.sh ferazel-random-play.sh; do
    start_bg "watcher-dies-$s" "$s"
    loop=""
    for p in $(tree "$SP"); do
        pp=$(ps -o ppid= -p "$p" 2>/dev/null | tr -d ' '); ppp=$(ps -o ppid= -p "${pp:-0}" 2>/dev/null | tr -d ' ')
        [ "$ppp" = "$SP" ] && ps -o command= -p "$p" 2>/dev/null | grep -q "$s" && ps -o command= -p "$pp" | grep -q "$s" \
            && loop="$p"
    done
    [ -n "$loop" ] && kill -KILL "$loop"
    wait "$SP"; RC=$?
    check "$s: the watchdog loop killed mid-run takes its test process with it (watchdog row)" 1 "$RC" \
        "$T/watcher-dies-$s.txt" "memory watchdog stopped working"
done

# Stopping it. TERM to the script and every subshell of it (what `pkill -f ferazel-visit-sweep.sh` does, scoped to
# this run so another session's real sweep is never touched).
for s in ferazel-visit-sweep.sh ferazel-random-play.sh; do
    start_bg "term-all-$s" "$s"
    targets=""
    for p in $(tree "$SP"); do ps -o command= -p "$p" 2>/dev/null | grep -q "$s" && targets="$targets $p"; done
    # shellcheck disable=SC2086
    kill -TERM $targets
    wait "$SP"; RC=$?
    check "$s: TERM to the script and its worker subshells leaves nothing running" 143 "$RC" "$T/term-all-$s.txt" "interrupted"
done

start_bg term-main ferazel-visit-sweep.sh
kill -TERM "$SP"
wait "$SP"; RC=$?
check "sweep: kill <script pid> (TERM) kills the worker and its test process" 143 "$RC" "$T/term-main.txt" "interrupted"

# Ctrl-C: job control on, so the script's background job does not start with SIGINT ignored.
set -m
start_bg sweep-int ferazel-visit-sweep.sh
kill -INT "$SP"
wait "$SP"; RC=$?
set +m
check "sweep: Ctrl-C kills the worker and its test process" 130 "$RC" "$T/sweep-int.txt" "interrupted"

echo "watchdog self-test: $PASSES passed, $FAILS failed"
[ "$FAILS" = 0 ]
