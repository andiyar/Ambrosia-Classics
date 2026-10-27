#!/bin/zsh
# tools/windows/smoke-ferazel-win.sh [--mac-only | --check-guard] — Phase W smoke of Ferazel's Wand for Windows (plan
# docs/plans/2026-10-26-ferazel-windows.md, gates GW4R and GW6).
#
#   (no argument)  GW6, the CrossOver half: the STAGED zip (out/Windows/Ferazel's Wand (Windows).zip, made by
#                  stage-ferazel-win.sh — this script never stages; it stops with exit 66 if the stage is missing) is
#                  unzipped to a scratch folder and its "Ferazel's Wand.exe" run with NO --data / --fonts (the shipped
#                  layout: Data\ and Data\Fonts\ beside the exe) in the clean bottle (`run-in-crossover.sh --clean`:
#                  nothing on WINEPATH, every DLL must come from the zip), muted, dummy drivers. Two headless runs —
#                  the main menu (run A) and New Game with N held (run B) — each `cmp`-ed against the Mac SDL
#                  development build's dump of the same run (whose FNV must also be the recorded reference) — and a
#                  third, run C, on to the first presented frame with text (the baked fonts on Windows). Prints
#                  "main menu: identical", "new game: identical" and "level 1 text: identical", exit 0.
#   --mac-only     GW4R: the Mac SDL development build (Ferazel/Windows `FerazelWin`, brew sdl3), headless: boots to the
#                  main menu in --frames mode, muted, on the dummy SDL drivers, and checks: exit 0, the launch line ends
#                  "video=dummy audio=none" (SDL's real drivers; a --frames run starts no audio subsystem — HectorSDL
#                  starts it only with an output), the presented main menu's RGBA FNV = WF2's (0xae2b1ee08c089b2a).
#   --check-guard  evaluate the launch guard (hour + drivers + mute) and exit: builds nothing, runs nothing
#
# LAUNCH RULE (D42, Ruling 15): refuses (exit 64, one line) unless `date +%H` is in 09..20 and every run it makes is
# muted (`--mute`) on the dummy SDL drivers. The script sets the drivers and the arguments itself; the caller's
# HECTOR_SDL_* / SDL_* values are never inherited (CrossOver strips SDL_*; the HECTOR_SDL_* pair reaches the exe).
# There is no hour override. A run opens no window and no audio device (--frames forces the dummy drivers in-process
# too).
set -euo pipefail
export HECTOR_SDL_AUDIO_DRIVER=dummy HECTOR_SDL_VIDEO_DRIVER=dummy SDL_AUDIO_DRIVER=dummy SDL_VIDEO_DRIVER=dummy
unset HECTORKIT_PATH FERAZEL_DATA FERAZEL_MUTE HECTOR_BOTTLE
here="${0:A:h}"
repo="${here:h:h}"

# ---- The runs' frame counts (measured, never guessed) ------------------------------------------------------------
# `--frames N` counts loop wakes of 1/240 s; the flow steps once per new 60 Hz tick, at a tick's first wake, so after N
# wakes the flow has made floor((N − 1) / 4) + 1 steps, and the first wake count at which step T has run is
# 4 × (T − 1) + 1 (WinGameTests test 1). Measured (WF1, re-measured with the baked text by WF2, pinned by
# FerazelDriverTests.bootTicks / newGameTicks and WinGameTests tests 1 and 18):
#   boot → main menu presented at flow step 360                  → run A = 4 × (360 − 1) + 1 = 1,437 wakes
#   N held from wake 1,440 (the first tick after the menu) → level 1's first frame 107 steps later, step 467
#                                                                 → run B = 4 × (467 − 1) + 1 = 1,865 wakes
#   the same keys on → the first presented frame with text (score, coins, "A Scent Of Peril") 414 steps after level 1's
#   first frame, step 881 (WF2/WF3: BakedTextTests.firstTextPresentTick) → run C = 4 × (881 − 1) + 1 = 3,521 wakes
#   (runs A and B draw no text at all; C is the one whose picture depends on the baked glyphs from Data\Fonts\)
# The plan's "4 × (ticks + a 60-tick margin)" was not what WF3's Mac half used (1,437, exact): the exact count lands
# the dump ON the reference frame, so the Mac dump's FNV can be checked against the recorded one as well.
menu_frames=1437
menu_fnv=0xae2b1ee08c089b2a
newgame_frames=1865
newgame_fnv=0xc99ce8e85b4bd8f7
text_frames=3521
text_fnv=0x908483fb603623e8
newgame_keys="# N held from the first tick after the main menu (WinGameTests test 18)
1440 down n"

mode=""
case "${1:-}" in
    "") mode=crossover ;;
    --mac-only) mode=mac ;;
    --check-guard) mode=guard ;;
    *) print -u2 "usage: $0 [--mac-only | --check-guard]"; exit 64 ;;
esac

out="${TMPDIR:-/tmp}/smoke-ferazel-win"
common=(--mute)

# ---- Launch guard (D42) -------------------------------------------------------------------------------
h=$(date +%H)
if (( 10#$h < 9 || 10#$h > 20 )); then
    print "smoke-ferazel-win: refused (night rule): hour $h, launches only 09..20; boot check owed (night rule)"
    exit 64
fi
if [[ "$HECTOR_SDL_AUDIO_DRIVER" != dummy || "$HECTOR_SDL_VIDEO_DRIVER" != dummy ]]; then
    print "smoke-ferazel-win: refused: driver $HECTOR_SDL_AUDIO_DRIVER/$HECTOR_SDL_VIDEO_DRIVER, not dummy"
    exit 64
fi
if [[ ${common[(Ie)--mute]} == 0 ]]; then
    print "smoke-ferazel-win: refused: the run is not muted (--mute)"
    exit 64
fi
if [[ $mode == guard ]]; then
    print "smoke-ferazel-win: guard ok: hour $h; drivers dummy; --mute"
    exit 0
fi

# ---- The stage (CrossOver half): present, never made here ----------------------------------------------------
zipfile="$repo/out/Windows/Ferazel's Wand (Windows).zip"
if [[ $mode == crossover && ! -f "$zipfile" ]]; then
    print "smoke-ferazel-win: no staged zip at $zipfile — run tools/windows/stage-ferazel-win.sh --no-desktop first"
    exit 66
fi

# ---- Build the Mac SDL development build ------------------------------------------------------------
pkg="$repo/Ferazel/Windows"
swift build --package-path "$pkg" --product FerazelWin >&2
bin="$(swift build --package-path "$pkg" --product FerazelWin --show-bin-path)/FerazelWin"
[[ -x "$bin" ]] || { print -u2 "smoke-ferazel-win: no FerazelWin built at $bin"; exit 70; }
mac_data=(--data "$repo/Resources/Ferazel" --fonts "$repo/Ferazel/Windows/Resources/Fonts")

rm -rf "$out"; mkdir -p "$out"
print -r -- "$newgame_keys" > "$out/newgame-keys.txt"

# mac_run <label> <frames> <want FNV> [extra args…] — the Mac SDL build, headless; checks exit 0, the launch line and
# the presented frame's FNV; the dump goes to $out/mac-<label>.ppm.
mac_run() {
    local label=$1 frames=$2 fnv=$3; shift 3
    local log="$out/mac-$label.txt" code ok=1
    set +e; "$bin" $common --frames $frames --dump "$out/mac-$label.ppm" $mac_data "$@" > "$log" 2>&1; code=$?; set -e
    cat "$log"
    (( code == 0 )) || { print "smoke-ferazel-win: mac $label: exit $code (want 0)"; ok=0; }
    grep -qE 'video=dummy audio=none$' "$log" || { print "smoke-ferazel-win: mac $label: no 'video=dummy audio=none' line"; ok=0; }
    grep -qF "presented RGBA FNV $fnv" "$log" || { print "smoke-ferazel-win: mac $label: FNV is not $fnv"; ok=0; }
    [[ -s "$out/mac-$label.ppm" ]] || { print "smoke-ferazel-win: mac $label: no dump"; ok=0; }
    (( ok ))
}

if [[ $mode == mac ]]; then
    if mac_run menu $menu_frames $menu_fnv; then
        print "smoke-ferazel-win: mac-only: main menu: identical (exit 0, video=dummy audio=none, FNV $menu_fnv)"
        exit 0
    fi
    print "smoke-ferazel-win: mac-only: FAILED (log $out/mac-menu.txt)"
    exit 1
fi

# ---- CrossOver half (GW6) ---------------------------------------------------------------------------------------
. "$here/env.sh"
fail=0
mac_run menu $menu_frames $menu_fnv || fail=1
mac_run newgame $newgame_frames $newgame_fnv --keys "$out/newgame-keys.txt" || fail=1
mac_run text $text_frames $text_fnv --keys "$out/newgame-keys.txt" || fail=1
(( fail == 0 )) || { print "smoke-ferazel-win: the Mac SDL reference runs FAILED (logs in $out)"; exit 1; }

# The staged zip, unzipped as a tester would ("Extract All" → one folder).
win="$out/Ferazel's Wand (Windows)"
mkdir -p "$win"
unzip -q "$zipfile" -d "$win"
exe="$win/Ferazel's Wand.exe"
[[ -f "$exe" ]] || { print "smoke-ferazel-win: the zip has no \"Ferazel's Wand.exe\" at its root"; exit 1; }
stamp="$(sed -n 3p "$win/WHAT-TO-EXPECT.txt" | tr -d '\r')"
print -r -- "smoke-ferazel-win: staged build: ${stamp:-unknown}; repo HEAD $(git -C "$repo" rev-parse --short HEAD)"

# win_run <label> <frames> [extra args…] — the staged exe in the clean bottle; no --data / --fonts.
win_run() {
    local label=$1 frames=$2; shift 2
    local log="$out/win-$label.txt" code
    set +e
    WIN_RUN_TIMEOUT=600 "$here/run-in-crossover.sh" --clean "$exe" $common --frames $frames \
        --dump "$(win_path "$out")\\win-$label.ppm" "$@" > "$log" 2>&1
    code=$?
    set -e
    tr -d '\r' < "$log"
    if (( code != 0 )); then
        print "smoke-ferazel-win: crossover $label: exit $code (want 0; log $log)"; return 1
    fi
    [[ -s "$out/win-$label.ppm" ]] || { print "smoke-ferazel-win: crossover $label: no dump"; return 1; }
}

start=$SECONDS
results=()
if win_run menu $menu_frames && cmp "$out/mac-menu.ppm" "$out/win-menu.ppm"; then
    results+=("main menu: identical")
else
    results+=("main menu: DIFFERENT"); fail=1
fi
if win_run newgame $newgame_frames --keys "$(win_path "$out/newgame-keys.txt")" \
        && cmp "$out/mac-newgame.ppm" "$out/win-newgame.ppm"; then
    results+=("new game: identical")
else
    results+=("new game: DIFFERENT"); fail=1
fi
if win_run text $text_frames --keys "$(win_path "$out/newgame-keys.txt")" \
        && cmp "$out/mac-text.ppm" "$out/win-text.ppm"; then
    results+=("level 1 text: identical")
else
    results+=("level 1 text: DIFFERENT"); fail=1
fi
print "smoke-ferazel-win: CrossOver runs took $(( SECONDS - start )) s (wakes: main menu $menu_frames, new game $newgame_frames, level 1 text $text_frames)"
print -l $results
if (( fail )); then
    print "smoke-ferazel-win: FAILED (logs and dumps in $out)"
    exit 1
fi
exit 0
