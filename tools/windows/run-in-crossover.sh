#!/bin/zsh
# tools/windows/run-in-crossover.sh <exe> [args…]
# Runs a cross-built Windows executable in the dedicated CrossOver bottle (hector-win, Windows 10 64-bit,
# created on first use, command line only). The Swift runtime DLLs (+ ICU, Foundation, dispatch, vcruntime),
# XCTest/Testing and SDL3 are put on the DLL search path via WINEPATH — nothing is installed into the bottle.
# Prints the program's stdout/stderr and exits with its exit code.
#
# Environment:
#   WIN_RUN_TIMEOUT  seconds before the run is killed (default 900); exit 124 on timeout
#   WINEDEBUG        defaults to -all (quiet); set e.g. WINEDEBUG=err+all to see Wine's complaints
#   Any other variable (e.g. HECTORKIT_DATA_BTX="Z:\…") is passed through to the program by Wine.
#   Automated SDL runs must set SDL_AUDIO_DRIVER=dummy (no real-time audio from automation).
set -euo pipefail
here="${0:A:h}"
. "$here/env.sh"

if (( $# < 1 )); then
    print -u2 "usage: $0 <exe> [args…]"
    exit 64
fi
exe="$1"; shift
[[ -f "$exe" ]] || { print -u2 "run-in-crossover: no such file: $exe"; exit 66; }
[[ -x "$CX_BIN/wine" ]] || { print -u2 "run-in-crossover: CrossOver not found at $CX_BIN"; exit 69; }

# ---- Bottle (first use) -------------------------------------------------------------------------
if [[ ! -d "$HECTOR_BOTTLE_DIR" ]]; then
    print -u2 "run-in-crossover: creating bottle $HECTOR_BOTTLE (win10_64)…"
    "$CX_BIN/cxbottle" --bottle "$HECTOR_BOTTLE" --create --template win10_64 \
        --description "Hector Windows cross-compile test bottle (command-line only)" >&2
    # A crash must print a backtrace and exit, never park on a GUI dialog.
    "$CX_BIN/wine" --bottle "$HECTOR_BOTTLE" --cx-app reg.exe add 'HKCU\Software\Wine\WineDbg' \
        /v ShowCrashDialog /t REG_DWORD /d 0 /f >&2
fi

# ---- DLL search path ------------------------------------------------------------------------------
dll_dirs=("$WIN_RUNTIME" "$WIN_XCTEST/usr/bin64" "$WIN_TESTING/usr/bin64")
[[ -d "$WIN_SDL3/lib/x64" ]] && dll_dirs+=("$WIN_SDL3/lib/x64")
winepath=""
for d in $dll_dirs; do
    [[ -d "$d" ]] || continue
    winepath+="${winepath:+;}$(win_path "$d")"
done

export WINEPATH="$winepath" HECTOR_BOTTLE_DIR CX_BIN
export WINEDEBUG="${WINEDEBUG:--all}"
timeout_s="${WIN_RUN_TIMEOUT:-900}"
wexe="$(win_path "$exe")"

# Run with a watchdog (macOS has no `timeout`): perl forks the run, kills the bottle's wineserver on expiry.
set +e
perl -e '
    my $t = shift; my $pid = fork();
    if ($pid == 0) { exec @ARGV or exit 127 }
    local $SIG{ALRM} = sub {
        print STDERR "run-in-crossover: timed out after ${t}s\n";
        kill "TERM", $pid;
        system("env", "WINEPREFIX=$ENV{HECTOR_BOTTLE_DIR}", "$ENV{CX_BIN}/wineserver", "-k");
        exit 124;
    };
    alarm $t; waitpid($pid, 0); alarm 0;
    exit($? & 127 ? 128 + ($? & 127) : $? >> 8);
' "$timeout_s" "$CX_BIN/wine" --bottle "$HECTOR_BOTTLE" --cx-app "$wexe" "$@"
code=$?
set -e
exit $code
