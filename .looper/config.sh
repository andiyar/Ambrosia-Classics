#!/usr/bin/env bash
# Ambrosia Classics — adapter for the unattended session looper (~/Developer/Toolkits/fable-kit/looper/looper.sh).
# Sourced by looper.sh / looper-start.sh / looper-stop.sh. Ben, 2026-10-13: the loop's job is Ferazel's Wand
# (docs/DECISIONS.md D34); its chip is docs/NEXT.md, its question queue docs/QUESTIONS.md, its ledger docs/LOOP-LOG.md.
#
#   start:   bash ~/Developer/Toolkits/fable-kit/looper/looper-start.sh ~/Developer/Ambrosia-Classics/.looper/config.sh
#   stop:    bash ~/Developer/Toolkits/fable-kit/looper/looper-stop.sh  ~/Developer/Ambrosia-Classics/.looper/config.sh
#   monitor: tail -f ~/Developer/Ambrosia-Classics/.looper/logs/looper.log
#
# Never pushes, never touches a remote: the loop merges into LOCAL main only (NEXT.md "NEVER").

REPO=/Users/andiyar/Developer/Ambrosia-Classics
MAIN_BRANCH=main
NEXT_FILE=docs/NEXT.md
QUESTIONS_FILE=docs/QUESTIONS.md
LOOP_LOG=docs/LOOP-LOG.md
STOP_FILE=STOP                       # $REPO/STOP — git-ignored; `touch` it (or looper-stop.sh) to stop after the running session
LOG_DIR=$REPO/.looper/logs           # git-ignored: looper.log (one line per run), looper.out, run-<N>.log (stream-json), looper.pid
MODEL=claude-opus-5-5                # the seat (Ben 2026-10-07: Opus 5.5 primary); Fable only as the phase cross-check (D34)
STALL_LIMIT=3                        # consecutive runs that leave main where it was → stop with exit 2
MAX_RUNS=0                           # 0 = unlimited; the loop ends on STATUS: BLOCKED / DONE, STOP, or a stall
PAUSE_SECONDS=30

# Wait until nothing in this project is building, testing or running before a session starts: xcodegen / xcodebuild /
# SwiftPM processes whose command line names this repo or HectorKit, and the staged game apps themselves (a run's
# G9 boot check, or Ben playing). Checks every 30 s; after PRE_RUN_MAX_SECONDS (default 30 min) it logs and proceeds —
# worktrees and derived-data dirs are separate, so a collision costs CPU, not correctness. (Claude's own `zsh -c`
# shell wrappers are excluded: a build they run is matched by its xcodebuild/swift child anyway.)
pre_run() {
  local waited=0 max=${PRE_RUN_MAX_SECONDS:-1800} busy
  # Guard: looper.sh passes the kit's standing prompt to every session; without it each run fails at once and the
  # stall rule would burn three runs. Stop cleanly instead (the STOP file is checked right after pre_run).
  if [[ -n ${STANDING_PROMPT:-} && ! -f $STANDING_PROMPT ]]; then
    _pre_say "pre_run: standing prompt $STANDING_PROMPT is missing — touching $REPO/$STOP_FILE; write it, rm STOP, restart"
    touch "$REPO/$STOP_FILE"; return 0
  fi
  while :; do
    busy=$( {
      pgrep -fl 'xcodebuild|xcodegen|swift-build|swift-test|swift-package|swift-frontend|ferazel-census' 2>/dev/null \
        | grep -E 'Ambrosia-Classics|HectorKit' | grep -v -e '--show-bin-path' -e 'shell-snapshots'
      pgrep -fl "Ferazel's Wand\.app/|/Aki\.app/|Bubble ?Trouble ?X\.app/|Deimos Rising\.app/|Cythera\.app/" 2>/dev/null
    } | head -n 3 || true )   # `|| true`: looper.sh runs with set -e -o pipefail; an idle pgrep/grep returns 1
    if [[ -z $busy ]]; then
      (( waited > 0 )) && _pre_say "pre_run: project idle after ${waited}s"
      return 0
    fi
    if (( waited >= max )); then
      _pre_say "pre_run: still busy after ${waited}s — proceeding anyway: $(echo "$busy" | tr '\n' ';' | cut -c1-200)"
      return 0
    fi
    (( waited % 300 == 0 )) && _pre_say "pre_run: waiting (${waited}s) — $(echo "$busy" | head -n 1 | cut -c1-160)"
    sleep 30; waited=$(( waited + 30 ))
  done
}
_pre_say() { if declare -F say > /dev/null; then say "$*"; else echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; fi; }
