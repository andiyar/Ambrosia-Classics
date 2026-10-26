#!/bin/zsh
# tools/windows/smoke-ferazel-win.sh --mac-only | --check-guard — Phase W smoke of Ferazel's Wand for Windows (plan
# docs/plans/2026-10-26-ferazel-windows.md, gate GW4R; WF6 adds the CrossOver half, gate GW6).
#
#   --mac-only     the Mac SDL development build (Ferazel/Windows `FerazelWin`, brew sdl3), headless: boots to the main
#                  menu in --frames mode, muted, on the dummy SDL drivers, and checks: exit 0, the launch line ends
#                  "video=dummy audio=dummy", the presented main menu's RGBA FNV = WF2's (0xae2b1ee08c089b2a).
#   --check-guard  evaluate the launch guard (hour + drivers + mute) and exit: builds nothing, runs nothing
#   (no argument)  the CrossOver half — not built yet (WF6)
#
# LAUNCH RULE (D42, Ruling 15): refuses (exit 64, one line) unless `date +%H` is in 09..20 and the run it makes is
# muted (`--mute`) on the dummy SDL drivers. The script sets the drivers and the arguments itself; the caller's
# HECTOR_SDL_* / SDL_* values are never inherited. There is no hour override. A run opens no window and no audio
# device (--frames forces the dummy drivers in-process too).
set -euo pipefail
export HECTOR_SDL_AUDIO_DRIVER=dummy HECTOR_SDL_VIDEO_DRIVER=dummy SDL_AUDIO_DRIVER=dummy SDL_VIDEO_DRIVER=dummy
unset HECTORKIT_PATH FERAZEL_DATA
here="${0:A:h}"
repo="${here:h:h}"

# The headless main menu (WF1/WF2): 360 game ticks = 1,437 wakes at 240 Hz; its presented frame's RGBA FNV.
frames=1437
menu_fnv=0xae2b1ee08c089b2a

mode=""
case "${1:-}" in
    --mac-only) mode=mac ;;
    --check-guard) mode=guard ;;
    "") print "smoke-ferazel-win: refused: the CrossOver half arrives with WF6; use --mac-only"; exit 64 ;;
    *) print -u2 "usage: $0 --mac-only | --check-guard"; exit 64 ;;
esac

out="${TMPDIR:-/tmp}/smoke-ferazel-win"
run_args=(--mute --frames $frames --dump "$out/menu.ppm"
          --data "$repo/Resources/Ferazel" --fonts "$repo/Ferazel/Windows/Resources/Fonts")

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
if [[ ${run_args[(Ie)--mute]} == 0 ]]; then
    print "smoke-ferazel-win: refused: the run is not muted (--mute)"
    exit 64
fi
if [[ $mode == guard ]]; then
    print "smoke-ferazel-win: guard ok: hour $h; drivers dummy; --mute"
    exit 0
fi

# ---- Build the Mac SDL development build ------------------------------------------------------------
pkg="$repo/Ferazel/Windows"
swift build --package-path "$pkg" --product FerazelWin >&2
bin="$(swift build --package-path "$pkg" --product FerazelWin --show-bin-path)/FerazelWin"
[[ -x "$bin" ]] || { print -u2 "smoke-ferazel-win: no FerazelWin built at $bin"; exit 70; }

# ---- Run (headless, muted, dummy drivers) -------------------------------------------------------------
rm -rf "$out"; mkdir -p "$out"
set +e; "$bin" $run_args > "$out/run.txt" 2>&1; code=$?; set -e
cat "$out/run.txt"
ok=1
(( code == 0 )) || { print "smoke-ferazel-win: exit $code (want 0)"; ok=0; }
grep -qE 'video=dummy audio=dummy$' "$out/run.txt" || { print "smoke-ferazel-win: no 'video=dummy audio=dummy' line"; ok=0; }
grep -qF "presented RGBA FNV $menu_fnv" "$out/run.txt" || { print "smoke-ferazel-win: main menu FNV is not $menu_fnv"; ok=0; }
if (( ok )); then
    print "smoke-ferazel-win: mac-only: main menu: identical (exit 0, video=dummy audio=dummy, FNV $menu_fnv)"
else
    print "smoke-ferazel-win: mac-only: FAILED (log $out/run.txt)"
    exit 1
fi
