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
#                  third, run C, on to the first full-brightness frame with text (the baked fonts on Windows). Prints
#                  "main menu: identical", "new game: identical" and "level 1 text: identical", exit 0.
#                  STALE STAGE (exit 66, one line): the zip's build stamp (line 3 of its WHAT-TO-EXPECT.txt,
#                  "Windows build <date> (<classics sha>, HectorKit <sha>)." — stage-ferazel-win.sh writes it) must name
#                  this checkout's HEAD and the HectorKit checkout's HEAD, with no "-dirty": a stage from any other
#                  commit, or from uncommitted files, is refused — re-stage after every commit (the simplest rule that is
#                  never wrong; a docs-only commit also asks for a re-stage).
#   --mac-only     GW4R: the Mac SDL development build (Ferazel/Windows `FerazelWin`, brew sdl3), headless: boots to the
#                  main menu in --frames mode, muted, on the dummy SDL drivers, and checks: exit 0, the launch line ends
#                  "video=dummy audio=none" (SDL's real drivers; a --frames run starts no audio subsystem — HectorSDL
#                  starts it only with an output), the presented main menu's RGBA FNV = the recorded menu reference.
#   --check-guard  evaluate the launch guard (hour + drivers + mute) and exit: builds nothing, runs nothing
#
# Each run's logs and dumps go to a fresh `mktemp -d` folder (its path is printed). Every run's log, Mac and Windows,
# must carry the launch line ending "video=dummy audio=none" (the exe's own report of the SDL drivers it started — the
# real proof that a run was on the dummy drivers; the guard below only checks values this script sets itself) and no
# "BakedTextRasterizer:" line (the baked text's report of a face file it could not use or a face it was asked for and
# does not have — its text would draw nothing).
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
#   the same keys on → level 1's status bar text (score, coins, "A Scent Of Peril") is first presented at step 881
#   (BakedTextTests.firstTextPresentTick), but faded nearly to black (every channel 0–5, 76 colours), so a wrong glyph
#   could still dump identical; the level's fade-in (`_GammaFadeInAsync(0x28)`, one step every other tick) presents
#   its last, full-gamma step at step 959 (WF6 review fix, measured through WinGame's scripted host with N held as run
#   B: max channel 255, 178 colours; the same run with every glyph's coverage blanked dumps a different frame —
#   281 pixels differ, all in the status bar, x 27–155, y 403–437) → run C = 4 × (959 − 1) + 1 = 3,833 wakes
#   (runs A and B draw no text at all; C is the one whose picture depends on the baked glyphs from Data\Fonts\)
# The plan's "4 × (ticks + a 60-tick margin)" was not what WF3's Mac half used (1,437, exact): the exact count lands
# the dump ON the reference frame, so the Mac dump's FNV can be checked against the recorded one as well.
# These six values are also pinned in-process, headless, by Ferazel/Windows/Tests/FerazelWinKitTests/
# WinReferenceFramesTests.swift (testSmokeReferencesInProcess: the exe's --frames loop through the scripted host, the
# same wakes, keys and baked fonts). The three reference FNVs are read from that test (below, after the launch guard:
# the `hex(0x…)` on the assert line tagged "smoke <name>", underscores dropped); a change that moves a reference moves
# it there, and this script follows. If any of the three cannot be read, the script stops (exit 65, one line).
menu_frames=1437
newgame_frames=1865
text_frames=3833
newgame_keys="# N held from the first tick after the main menu (WinGameTests test 18)
1440 down n"

mode=""
case "${1:-}" in
    "") mode=crossover ;;
    --mac-only) mode=mac ;;
    --check-guard) mode=guard ;;
    *) print -u2 "usage: $0 [--mac-only | --check-guard]"; exit 64 ;;
esac

common=(--mute)

# ---- Launch guard (D42) -------------------------------------------------------------------------------
# Defence only: the driver and mute checks below test values this script itself sets above. The real proof is each
# run's own launch line, "video=dummy audio=none" (no window, no audio device started), checked by log_ok in mac_run
# and win_run.
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

# ---- The three reference FNVs, read from WinReferenceFramesTests.swift (after the argument check and the guard, so a
# bad argument still exits 64 and --check-guard never reads the test file) --------------------------------------------
refs_file="$repo/Ferazel/Windows/Tests/FerazelWinKitTests/WinReferenceFramesTests.swift"
# -- reference parse (begin) --
# ref_fnv <name>: prints the FNV the test pins for "smoke <name>" in the exe's own spelling, or fails. The exe prints
# `"0x" + String(fnv, radix: 16)` (Ferazel/Windows/Sources/FerazelWin/main.swift): lower case, no leading zeros. So the
# test's literal (1–16 hex digits after the underscores go) is printed the same way: leading zeros dropped, "0x0" for 0.
ref_fnv() {
    local -a lines
    lines=("${(@f)$(grep -F "\"smoke $1\"" "$refs_file" 2>/dev/null || true)}")
    lines=(${lines:#})
    (( ${#lines} == 1 )) || return 1
    [[ "${lines[1]}" =~ 'hex\((0x[0-9a-f_]+)\)' ]] || return 1
    local v="${match[1]//_/}"
    [[ "$v" =~ '^0x[0-9a-f]{1,16}$' ]] || return 1
    v="${v#0x}"
    while [[ "$v" == 0?* ]]; do v="${v#0}"; done
    print -r -- "0x$v"
}
for ref in menu_fnv newgame_fnv text_fnv; do
    if ! val="$(ref_fnv $ref)"; then
        print -u2 "smoke-ferazel-win: cannot read the reference $ref from $refs_file (want exactly one assert line tagged \"smoke $ref\" with a hex(0x…) FNV)"
        exit 65
    fi
    typeset -g "$ref=$val"
done
# -- reference parse (end) --

# ---- The stage (CrossOver half): present, never made here ----------------------------------------------------
zipfile="$repo/out/Windows/Ferazel's Wand (Windows).zip"
if [[ $mode == crossover && ! -f "$zipfile" ]]; then
    print "smoke-ferazel-win: no staged zip at $zipfile — run tools/windows/stage-ferazel-win.sh --no-desktop first"
    exit 66
fi
if [[ $mode == crossover ]]; then
    stamp="$(unzip -p "$zipfile" WHAT-TO-EXPECT.txt 2>/dev/null | sed -n 3p | tr -d '\r' || true)"
    hk="${repo:h}/HectorKit"; hk="${hk:A}"        # where Ferazel/Windows reaches it (../../../HectorKit)
    fresh=0
    if [[ "$stamp" =~ '^Windows build [0-9-]+ \(([0-9a-f]+), HectorKit ([0-9a-f]+)\)\.$' ]]; then
        [[ "$(git -C "$repo" rev-parse -q --verify "${match[1]}^{commit}" 2>/dev/null)" == "$(git -C "$repo" rev-parse HEAD)" \
           && "$(git -C "$hk" rev-parse -q --verify "${match[2]}^{commit}" 2>/dev/null)" == "$(git -C "$hk" rev-parse HEAD)" ]] \
            && fresh=1
    fi
    if (( ! fresh )); then
        print -r -- "smoke-ferazel-win: stale stage: the zip says '${stamp:-no stamp}', HEAD is $(git -C "$repo" rev-parse --short HEAD), HectorKit $(git -C "$hk" rev-parse --short HEAD 2>/dev/null) — re-run tools/windows/stage-ferazel-win.sh --no-desktop"
        exit 66
    fi
fi

# ---- Build the Mac SDL development build ------------------------------------------------------------
pkg="$repo/Ferazel/Windows"
swift build --package-path "$pkg" --product FerazelWin >&2
bin="$(swift build --package-path "$pkg" --product FerazelWin --show-bin-path)/FerazelWin"
[[ -x "$bin" ]] || { print -u2 "smoke-ferazel-win: no FerazelWin built at $bin"; exit 70; }
mac_data=(--data "$repo/Resources/Ferazel" --fonts "$repo/Ferazel/Windows/Resources/Fonts")

out="$(mktemp -d "${TMPDIR:-/tmp}/smoke-ferazel-win.XXXXXX")"
print "smoke-ferazel-win: logs and dumps in $out"
print -r -- "$newgame_keys" > "$out/newgame-keys.txt"

# log_ok <side> <label> <log> — the launch line ends "video=dummy audio=none" (\r dropped: Windows' lines end CRLF) and
# no "BakedTextRasterizer:" line (a face file not used / a face asked for and not baked).
log_ok() {
    local side=$1 label=$2 log=$3 ok=1
    tr -d '\r' < "$log" | grep -qE 'video=dummy audio=none$' \
        || { print "smoke-ferazel-win: $side $label: no 'video=dummy audio=none' line"; ok=0; }
    if tr -d '\r' < "$log" | grep -qF 'BakedTextRasterizer:'; then
        print "smoke-ferazel-win: $side $label: the baked text reported a missing face (BakedTextRasterizer: line)"; ok=0
    fi
    (( ok ))
}

# mac_run <label> <frames> <want FNV> [extra args…] — the Mac SDL build, headless; checks exit 0, the launch line, no
# baked-text report and the presented frame's FNV; the dump goes to $out/mac-<label>.ppm.
mac_run() {
    local label=$1 frames=$2 fnv=$3; shift 3
    local log="$out/mac-$label.txt" code ok=1
    set +e; "$bin" $common --frames $frames --dump "$out/mac-$label.ppm" $mac_data "$@" > "$log" 2>&1; code=$?; set -e
    cat "$log"
    (( code == 0 )) || { print "smoke-ferazel-win: mac $label: exit $code (want 0)"; ok=0; }
    log_ok mac $label "$log" || ok=0
    # End-anchored (the FNV is followed by ", wrote …" or the line end), so a reference that is a prefix of the printed
    # value does not match; $fnv is already in the exe's spelling (ref_fnv).
    grep -qE "presented RGBA FNV ${fnv}(,|\$)" "$log" || { print "smoke-ferazel-win: mac $label: FNV is not $fnv"; ok=0; }
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
print -r -- "smoke-ferazel-win: staged build: $stamp; repo HEAD $(git -C "$repo" rev-parse --short HEAD)"

# win_run <label> <frames> [extra args…] — the staged exe in the clean bottle; no --data / --fonts; checks exit 0, the
# launch line, no baked-text report and a dump.
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
    log_ok crossover $label "$log" || return 1
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
