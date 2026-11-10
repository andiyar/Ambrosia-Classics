# Ferazel's Wand — the memory watchdog for the test workers (2026-11-10). Sourced (not run) by
# tools/ferazel-visit-sweep.sh and tools/ferazel-random-play.sh; bash 3.2 (macOS /bin/bash).
#
# Why: on 2026-11-08 and again on 2026-11-10 the visit sweep's four workers grew to 36-40 GB each on Ben's 64 GB Mac
# (every Windows-path visit leaked a whole game) and the Mac kernel-panicked. The scripts only waited for free memory
# before a worker started; nothing watched a worker while it ran. Now each worker's own loop watches its test process:
#   - every WW_SAMPLE_S seconds (default 3) it measures the test process and everything under it: the larger of the
#     resident size (`ps -o rss=`) and the footprint that counts compressed pages too (`top -l 1 -pid P -stats mem`,
#     the same number Activity Monitor shows as Memory), summed over the process tree;
#   - past MAX_WORKER_MB (default 4096) it kills that worker (TERM, then KILL after 5 s) and the caller writes a
#     `memory` failure row and does NOT restart it (a restart would leak again);
#   - when the whole machine's free memory (`memory_pressure`) falls below MIN_RUNNING_FREE_PCT (default 15) it drops
#     a brake file (WW_BRAKE, holding the reason) and kills its worker; every other worker sees the file at its next
#     sample and stops too, no new worker starts and no later path is built.
#   - before a build or a worker start, `ww_wait_for_memory` waits while free memory is below MIN_FREE_PCT (default
#     30), up to MEMORY_WAIT_S seconds (default 600); still below then, it refuses: it pulls the same brake.
# The measuring loop runs beside the worker (`ww_watch`); if that loop itself dies or cannot measure, the test process
# is killed and the caller writes a `watchdog` row — a test process is never left running unwatched. Each worker
# records its test process (pid and start time) in <its folder>/test.pid and traps TERM / INT / HUP to kill it; the
# scripts' own trap (`ww_cleanup`) kills every worker and every recorded test process, so nothing is left running
# even when the worker shells are killed first (`pkill -f`). A setting that is not a plain positive whole number
# stops the script before it starts anything (exit 2): "08" is a broken octal number to bash, and a watchdog that
# died on it once left the test running unwatched.
# When `top` or `memory_pressure` gives no reading, each worker says so once (stderr and <its folder>/
# watchdog-warnings.log) and carries on with what it has (resident size; no brake).
#
# `xcrun xctest` execs xctest in place on this Mac (the pid stays the same), but the tree walk (`pgrep -P`) also
# catches the case where xcrun starts xctest as a child.
# Never force-kill (`kill -9` / `pkill -9`) the sweep or bot script: no trap runs, the watcher dies with it and the
# test process is left running unwatched. Stop a run with a plain `kill <script pid>` (its trap cleans up).

# A numeric setting ($1, the variable's name; $2 its default when unset): digits only, no leading zero, at most 9
# digits, not empty. Anything else stops the script at once (exit 2) — never a silent default.
ww_number() {
    local v
    eval "v=\${$1-\$2}"
    case "$v" in
        ''|0*|*[!0-9]*|??????????*)
            echo "refusing to start: $1='$v' is not a positive whole number (digits only, no leading zero)" >&2
            exit 2 ;;
    esac
    eval "$1=\$v"
}
ww_number MAX_WORKER_MB 4096
ww_number MIN_RUNNING_FREE_PCT 15
ww_number WW_SAMPLE_S 3
ww_number MIN_FREE_PCT 30
ww_number MEMORY_WAIT_S 600

# A warning ($2) said once per worker (per key $1): to stderr and to $WW_LOG_DIR/watchdog-warnings.log.
ww_warn_once() {
    local d="${WW_LOG_DIR:-}"
    if [ -n "$d" ]; then
        [ -f "$d/.watchdog-warned-$1" ] && return 0
        : > "$d/.watchdog-warned-$1"
        echo "watchdog warning: $2" >> "$d/watchdog-warnings.log"
    fi
    echo "watchdog warning (${d:-script}): $2" >&2
}

# The pid and every process under it, one per line, parents first.
ww_tree() {
    local k
    echo "$1"
    for k in $(pgrep -P "$1" 2>/dev/null); do ww_tree "$k"; done
}

# One process's memory in MB: the larger of its resident size and its footprint (compressed pages included); 0 when
# it is gone. When `top` gives no footprint for a live process, the resident size alone (said once per worker).
ww_process_mb() {
    local rss mem fp
    rss=$(ps -o rss= -p "$1" 2>/dev/null | tr -d ' ')
    case "$rss" in ''|*[!0-9]*) rss=0 ;; esac
    rss=$((10#$rss / 1024))
    mem=$(top -l 1 -pid "$1" -stats mem 2>/dev/null | tail -n 1 | tr -d ' +-')
    fp=$(printf '%s\n' "$mem" | awk '{
        u = substr($0, length($0)); n = substr($0, 1, length($0) - 1)
        if (n !~ /^[0-9.]+$/) { print "none"; exit }
        if (u == "G") n *= 1024; else if (u == "K") n /= 1024; else if (u == "B") n /= 1048576
        else if (u == "T") n *= 1048576; else if (u != "M") { print "none"; exit }
        printf "%d\n", n }')
    # A miss on one sample can be a process caught mid-exec (xcrun → xctest); two in a row for a live process is
    # said once (the marker file carries the first miss between samples, each measured in its own subshell).
    local miss="${WW_LOG_DIR:-${TMPDIR:-/tmp}}/.watchdog-topmiss-$1"
    case "$fp" in
        ''|*[!0-9]*)
            if kill -0 "$1" 2>/dev/null; then
                [ -f "$miss" ] && ww_warn_once top \
                    "top gave no reading for process $1 ('$mem') twice: measuring resident size (ps) only, compressed pages not counted"
                : > "$miss" 2>/dev/null
            fi
            fp=0 ;;
        *) rm -f "$miss" ;;
    esac
    [ "$((10#$fp))" -gt "$rss" ] && echo "$((10#$fp))" || echo "$rss"
}

# A process tree's memory in MB (the sum of `ww_process_mb` over `ww_tree`).
ww_tree_mb() {
    local p total=0 mb
    for p in $(ww_tree "$1"); do
        mb=$(ww_process_mb "$p")
        case "$mb" in ''|*[!0-9]*) return 1 ;; esac   # cannot happen; if it does, the caller stops watching
        total=$((total + 10#$mb))
    done
    echo "$total"
}

# The system's free memory percentage (`memory_pressure`): digits, or empty when it cannot be read.
ww_free_pct() {
    local f
    f=$(memory_pressure 2>/dev/null | awk -F': ' '/free percentage/ {gsub(/[% ]/,"",$2); print $2; exit}')
    case "$f" in ''|*[!0-9]*) return 0 ;; esac
    echo "$((10#$f))"
}

# Before a build or a worker start: waits while free memory is below MIN_FREE_PCT, up to MEMORY_WAIT_S seconds.
# Returns 0 to go on; 1 to refuse — the brake is already pulled, or free memory stayed low (it pulls the brake then,
# so nothing more starts; the caller writes a `memory` row). No reading at all: it goes on, and says so.
ww_wait_for_memory() {
    local waited=0 free step
    while :; do
        ww_braked && return 1
        free=$(ww_free_pct)
        if [ -z "$free" ]; then
            ww_warn_once wait "memory_pressure gave no reading: starting without checking the machine's free memory"
            return 0
        fi
        [ "$free" -ge "$MIN_FREE_PCT" ] && return 0
        if [ "$waited" -ge "$MEMORY_WAIT_S" ]; then
            echo "the machine's free memory stayed below ${MIN_FREE_PCT}% for ${MEMORY_WAIT_S} s (${free}% at the end): nothing more was started" \
                > "${WW_BRAKE:?}"
            echo "memory: $(ww_brake_text)" >&2
            return 1
        fi
        step=$((MEMORY_WAIT_S - waited)); [ "$step" -gt 10 ] && step=10
        sleep "$step"; waited=$((waited + step))
    done
}

# TERM to the pid and everything under it, then KILL whatever is left after 5 s.
ww_kill_tree() {
    local all p i alive
    all=$(ww_tree "$1")
    for p in $all; do kill -TERM "$p" 2>/dev/null; done
    for ((i = 0; i < 10; i++)); do
        alive=""
        for p in $all; do kill -0 "$p" 2>/dev/null && alive="$alive $p"; done
        [ -z "$alive" ] && return 0
        sleep 0.5
    done
    for p in $all; do kill -KILL "$p" 2>/dev/null; done
    return 0
}

# True when the memory brake has been pulled (WW_BRAKE exists).
ww_braked() { [ -n "${WW_BRAKE:-}" ] && [ -f "$WW_BRAKE" ]; }

# What the brake file says (why it was pulled).
ww_brake_text() {
    local f
    f=$(cat "$WW_BRAKE" 2>/dev/null)
    echo "${f:-the memory brake was pulled}"
}

# The measuring loop (run in the background by `ww_watch`; its one output line is the result). $1 pid, $2 deadline in
# $SECONDS (empty: none). Prints "exit 0" (it ended by itself) | "timeout 0" (past the deadline, still running: the
# caller kills it) | "memory <MB>" (killed past MAX_WORKER_MB) | "brake 0" (killed by the machine brake). Returns
# non-zero, printing nothing, when it cannot measure — `ww_watch` then kills the test process.
# Polls every second; measures every WW_SAMPLE_S seconds, starting at once.
ww_watch_loop() {
    local pid="$1" deadline="${2:-}" next=0 free mb
    case "$deadline" in *[!0-9]*) return 3 ;; esac
    while kill -0 "$pid" 2>/dev/null; do
        if [ -n "$deadline" ] && [ "$SECONDS" -ge "$deadline" ]; then echo "timeout 0"; return 0; fi
        if [ "$SECONDS" -ge "$next" ]; then
            next=$((SECONDS + WW_SAMPLE_S))
            if ww_braked; then ww_kill_tree "$pid"; echo "brake 0"; return 0; fi
            free=$(ww_free_pct)
            if [ -z "$free" ]; then
                ww_warn_once brake "memory_pressure gave no reading: the machine brake cannot work for this worker (its own limit, MAX_WORKER_MB, still does)"
            elif [ "$free" -lt "$MIN_RUNNING_FREE_PCT" ]; then
                [ -n "${WW_BRAKE:-}" ] && echo "the machine's free memory fell to ${free}% (floor ${MIN_RUNNING_FREE_PCT}%) while workers ran: every worker was killed" > "$WW_BRAKE"
                ww_kill_tree "$pid"; echo "brake 0"; return 0
            fi
            mb=$(ww_tree_mb "$pid") || return 3
            case "$mb" in ''|*[!0-9]*) return 3 ;; esac
            if [ "$mb" -gt "$MAX_WORKER_MB" ]; then
                ww_kill_tree "$pid"; echo "memory $mb"; return 0
            fi
        fi
        sleep 1
    done
    echo "exit 0"
}

# Watches a running test process until it ends. $1 pid, $2 deadline in $SECONDS (empty: none). Needs WW_LOG_DIR.
# Sets WW_RESULT: exit | timeout | memory (WW_MB = what it had) | brake — or broken: the measuring loop died or could
# not measure, and the test process has been killed (WW_WHY says so; the caller writes a row and does not restart).
# The loop runs in the background and is waited for, so the worker's TERM / INT / HUP trap runs at once.
ww_watch() {
    local pid="$1" deadline="${2:-}" res="${WW_LOG_DIR:?ww_watch needs WW_LOG_DIR}/watch-result" rc=0
    rm -f "$res"
    ww_watch_loop "$pid" "$deadline" > "$res" &
    WW_WATCHER=$!
    wait "$WW_WATCHER" || rc=$?
    WW_WATCHER=""
    WW_RESULT=""; WW_MB=0; WW_WHY=""
    [ -f "$res" ] && read -r WW_RESULT WW_MB < "$res"
    case "$WW_MB" in ''|*[!0-9]*) WW_MB=0 ;; esac
    case "$rc:$WW_RESULT" in
        0:exit|0:timeout|0:memory|0:brake) ;;
        *)  ww_kill_tree "$pid"
            WW_WHY="the memory watchdog stopped working (status $rc, result '${WW_RESULT}'): its test process was killed rather than left running unwatched"
            WW_RESULT=broken ;;
    esac
}

# The start time of a process (stable across exec: xcrun → xctest), empty when it is gone.
ww_started() { ps -o lstart= -p "$1" 2>/dev/null | tr -s ' ' | sed 's/^ //; s/ $//'; }

# Records a worker's test process ($1) in $WW_LOG_DIR/test.pid (pid, start time) for the traps and the cleanup.
ww_track() { printf '%s\t%s\n' "$1" "$(ww_started "$1")" > "${WW_LOG_DIR:?}/test.pid"; }
ww_untrack() { rm -f "${WW_LOG_DIR:?}/test.pid"; }

# Kills the process tree a test.pid file ($1) records — only while that pid is still the process recorded (the same
# start time), never a recycled pid. Then removes the file. WW_KILLED=1 when it killed something.
ww_kill_recorded() {
    local pid="" st="" now
    WW_KILLED=0
    [ -f "$1" ] || return 0
    IFS=$'\t' read -r pid st < "$1"
    case "$pid" in ''|*[!0-9]*) rm -f "$1"; return 0 ;; esac
    now=$(ww_started "$pid")
    if [ -n "$now" ] && [ "$now" = "$st" ]; then ww_kill_tree "$pid"; WW_KILLED=1; fi
    rm -f "$1"
    return 0
}

# Called first thing in a worker shell (after setting WW_LOG_DIR): on TERM / INT / HUP, and whenever the shell ends,
# its measuring loop and its test process go with it.
ww_worker_traps() {
    WW_WATCHER=""
    trap 'ww_worker_stop 143' TERM
    trap 'ww_worker_stop 130' INT
    trap 'ww_worker_stop 129' HUP
    trap 'ww_worker_gone' EXIT
}
ww_worker_gone() {
    [ -n "${WW_WATCHER:-}" ] && kill -TERM "$WW_WATCHER" 2>/dev/null
    [ -n "${WW_LOG_DIR:-}" ] && ww_kill_recorded "$WW_LOG_DIR/test.pid"
    return 0
}
ww_worker_stop() { trap - TERM INT HUP; ww_worker_gone; exit "$1"; }

# The scripts' INT / TERM / HUP trap ($1 the exit code: 130, 143, 129): kill every background job (the workers, a
# build) with everything under it, then every test process a worker recorded (it may have outlived its worker).
ww_cleanup() {
    trap - INT TERM HUP
    local j f
    for j in $(jobs -p); do ww_kill_tree "$j"; done
    for f in "${OUT:?}"/*/shard-*/test.pid; do ww_kill_recorded "$f"; done
    echo "interrupted: every worker and its test process killed"
    exit "$1"
}

# After a path's workers have all ended: a shard ($1, its folder) whose worker still had a test process recorded
# (the worker died) — that process is killed now if it still runs; returns 1 so the caller writes a row, with
# WW_REAPED saying what was found. 0 = nothing was left.
ww_reap_shard() {
    [ -f "$1/test.pid" ] || return 0
    ww_kill_recorded "$1/test.pid"
    if [ "$WW_KILLED" = 1 ]; then
        WW_REAPED="its worker died while its test process still ran (killed now)"
    else
        WW_REAPED="its worker died during a run (its test process had ended)"
    fi
    return 1
}
