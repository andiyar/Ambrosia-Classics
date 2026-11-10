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
#     a brake file (WW_BRAKE) and kills its worker; every other worker sees the file at its next sample and stops too,
#     and no new worker starts.
# The watchdog is a loop inside the worker, not a separate process, so it ends with the worker and leaves nothing
# behind; `ww_cleanup` (the scripts' INT / TERM trap) kills every worker tree on Ctrl-C.
#
# `xcrun xctest` execs xctest in place on this Mac (the pid stays the same), but the tree walk (`pgrep -P`) also
# catches the case where xcrun starts xctest as a child.

MAX_WORKER_MB="${MAX_WORKER_MB:-4096}"
MIN_RUNNING_FREE_PCT="${MIN_RUNNING_FREE_PCT:-15}"
WW_SAMPLE_S="${WW_SAMPLE_S:-3}"
case "$MAX_WORKER_MB" in ''|*[!0-9]*) MAX_WORKER_MB=4096 ;; esac
case "$MIN_RUNNING_FREE_PCT" in ''|*[!0-9]*) MIN_RUNNING_FREE_PCT=15 ;; esac
case "$WW_SAMPLE_S" in ''|*[!0-9]*|0) WW_SAMPLE_S=3 ;; esac

# The pid and every process under it, one per line, parents first.
ww_tree() {
    local k
    echo "$1"
    for k in $(pgrep -P "$1" 2>/dev/null); do ww_tree "$k"; done
}

# One process's memory in MB: the larger of its resident size and its footprint (compressed pages included); 0 when
# it is gone.
ww_process_mb() {
    local rss mem fp
    rss=$(ps -o rss= -p "$1" 2>/dev/null | tr -d ' ')
    case "$rss" in ''|*[!0-9]*) rss=0 ;; esac
    rss=$((rss / 1024))
    mem=$(top -l 1 -pid "$1" -stats mem 2>/dev/null | tail -n 1 | tr -d ' +-')
    fp=$(printf '%s\n' "$mem" | awk '{
        u = substr($0, length($0)); n = substr($0, 1, length($0) - 1)
        if (n !~ /^[0-9.]+$/) { print 0; exit }
        if (u == "G") n *= 1024; else if (u == "K") n /= 1024; else if (u == "B") n /= 1048576
        else if (u == "T") n *= 1048576; else if (u != "M") n = 0
        printf "%d\n", n }')
    case "$fp" in ''|*[!0-9]*) fp=0 ;; esac
    [ "$fp" -gt "$rss" ] && echo "$fp" || echo "$rss"
}

# A process tree's memory in MB (the sum of `ww_process_mb` over `ww_tree`).
ww_tree_mb() {
    local p total=0 mb
    for p in $(ww_tree "$1"); do
        mb=$(ww_process_mb "$p")
        total=$((total + mb))
    done
    echo "$total"
}

# The system's free memory percentage (`memory_pressure`), empty when it cannot be read.
ww_free_pct() {
    memory_pressure 2>/dev/null | awk -F': ' '/free percentage/ {gsub(/%/,"",$2); print $2}'
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

# What the brake file says (the free percentage that pulled it).
ww_brake_text() {
    local f
    f=$(cat "$WW_BRAKE" 2>/dev/null)
    echo "the machine's free memory fell to ${f:-?}% (floor ${MIN_RUNNING_FREE_PCT}%): every worker was killed"
}

# Watches a running test process until it ends. $1 pid, $2 deadline in $SECONDS (empty: none).
# Sets WW_RESULT: exit (it ended by itself) | timeout (past the deadline, still running: the caller kills it) |
#   memory (killed past MAX_WORKER_MB; WW_MB = what it had) | brake (killed by the machine brake).
# Polls every second; measures every WW_SAMPLE_S seconds, starting at once.
ww_watch() {
    local pid="$1" deadline="${2:-}" next=0 free mb
    WW_RESULT=exit; WW_MB=0
    while kill -0 "$pid" 2>/dev/null; do
        if [ -n "$deadline" ] && [ "$SECONDS" -ge "$deadline" ]; then WW_RESULT=timeout; return 0; fi
        if [ "$SECONDS" -ge "$next" ]; then
            next=$((SECONDS + WW_SAMPLE_S))
            if ww_braked; then ww_kill_tree "$pid"; WW_RESULT=brake; return 0; fi
            free=$(ww_free_pct)
            if [ -n "$free" ] && [ "$free" -lt "$MIN_RUNNING_FREE_PCT" ] 2>/dev/null; then
                [ -n "${WW_BRAKE:-}" ] && echo "$free" > "$WW_BRAKE"
                ww_kill_tree "$pid"; WW_RESULT=brake; return 0
            fi
            mb=$(ww_tree_mb "$pid")
            if [ "$mb" -gt "$MAX_WORKER_MB" ]; then
                ww_kill_tree "$pid"; WW_RESULT=memory; WW_MB="$mb"; return 0
            fi
        fi
        sleep 1
    done
    return 0
}

# The INT / TERM trap: kill every background worker (and the test process under each), then leave with 130.
ww_cleanup() {
    trap - INT TERM
    local j
    for j in $(jobs -p); do ww_kill_tree "$j"; done
    echo "interrupted: every worker killed"
    exit 130
}
