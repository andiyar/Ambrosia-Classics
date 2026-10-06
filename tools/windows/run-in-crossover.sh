#!/bin/zsh
# tools/windows/run-in-crossover.sh [--clean] <exe> [args…]
# Runs a cross-built Windows executable in the dedicated CrossOver bottle (hector-win, Windows 10 64-bit,
# created on first use, command line only). The Swift runtime DLLs (+ ICU, Foundation, dispatch, vcruntime),
# XCTest/Testing and SDL3 are put on the DLL search path via WINEPATH — nothing is installed into the bottle.
# Prints the program's stdout/stderr and exits with its exit code.
#
# --clean  a shipped build's check (plan W7): run in a separate bottle (`hector-win-clean`, or $HECTOR_BOTTLE if
#          set; created on first use the same way) with NOTHING on WINEPATH — the exe must find every DLL beside it.
#
# Environment:
#   WIN_RUN_TIMEOUT  seconds before the run is killed (default 900); exit 124 on timeout
#   WINEDEBUG        defaults to -all (quiet); set e.g. WINEDEBUG=err+all to see Wine's complaints
#   HECTOR_SDL_AUDIO_DRIVER  REQUIRED (the script exits 64 without it). CrossOver's wine launcher STRIPS every
#            SDL_* variable, so SDL_AUDIO_DRIVER=dummy never reaches the program; HectorSDL reads
#            HECTOR_SDL_AUDIO_DRIVER / HECTOR_SDL_VIDEO_DRIVER instead (SDLHost.applyDriverOverridesFromEnvironment).
#            Automation: HECTOR_SDL_AUDIO_DRIVER=dummy (and HECTOR_SDL_VIDEO_DRIVER=dummy for headless runs).
#            A human playing with sound names SDL's Windows driver: HECTOR_SDL_AUDIO_DRIVER=wasapi (or
#            directsound). There is no "default" value: an unknown name makes SDL's audio init fail.
#            Required even for non-SDL programs, so no run can reach a real audio device by forgetting it.
#   Any other variable (e.g. HECTORKIT_DATA_BTX="Z:\…") is passed through to the program by Wine.
set -euo pipefail
here="${0:A:h}"
user_bottle="${HECTOR_BOTTLE:-}"
. "$here/env.sh"

clean=0
if [[ "${1:-}" == --clean ]]; then
    clean=1; shift
    if [[ -z "$user_bottle" ]]; then
        HECTOR_BOTTLE=hector-win-clean
        HECTOR_BOTTLE_DIR="$HOME/Library/Application Support/CrossOver/Bottles/$HECTOR_BOTTLE"
    fi
fi
if (( $# < 1 )); then
    print -u2 "usage: $0 [--clean] <exe> [args…]"
    exit 64
fi
exe="$1"; shift
if [[ -z "${HECTOR_SDL_AUDIO_DRIVER:-}" ]]; then
    print -u2 "run-in-crossover: set HECTOR_SDL_AUDIO_DRIVER explicitly (CrossOver strips SDL_* variables):"
    print -u2 "  automation:  HECTOR_SDL_AUDIO_DRIVER=dummy HECTOR_SDL_VIDEO_DRIVER=dummy $0 …"
    print -u2 "  a human playing with sound:  HECTOR_SDL_AUDIO_DRIVER=wasapi $0 …"
    exit 64
fi
export HECTOR_SDL_AUDIO_DRIVER
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
(( clean )) && dll_dirs=()
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
