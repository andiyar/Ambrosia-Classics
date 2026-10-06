# Handoff — 2026-10-04 — Deimos Rising RE deepening, waves 3+4 (the 100 % wave) — FIX PASS OWED

**TL;DR.** Ben ruled (2026-10-04) the Deimos game code is to be read to 100 %. Wave 2 is fully closed
and on `origin/main` (6c085ca: review, fix pass, label reconciliation, records). Waves 3+4 — eight
new reader files — are read, synthesised (f12f95d), Fable-reviewed (ca45615, ACCEPT_WITH_FIXES,
0 Critical / 1 Important / 7 Minor, 135/135 HIGH claims confirmed) and critiqued
(`docs/deimos/CRITIC-wave3-2026-10-04.md`). **The wave 3+4 fix pass has NOT run** — the session hit
Ben's usage limit. Branch `claude/modest-chandrasekhar-868895` is pushed; nothing after 6c085ca is on main.

## State of the bank (branch head)
- 32 topical files. Role table 938 rows = 698 HIGH / 240 MED / 0 LOW (orchestrator recount).
  Census (best label across files, `/Users/andiyar/Developer/Ambrosia-Classics/ghidra/deimos-proj/w4-census-all.py`): **0 unread
  functions** in `0x10000000–0x1004b400`; the critic confirmed independently (751/228/0/0).
- New files (wave 3): `blit-pixel-rules.md`, `static-init-audit.md`, `text-metrics-lists.md`;
  (wave 4): `display-window-present.md`, `app-pak-music-library.md`, `sprite-manager-resource-image.md`,
  `file-pict-alerts-manager.md`, `gameplay-leftovers.md`. INDEX #1 #3 #6 #9 #10 #36 #37 #43 #46 #53 #56
  closed by the synthesis; #57–#61 added.
- Briefs (reuse verbatim): `$W/brief.md`, `brief-wave3.md`, `brief-wave4.md`, `synthesis.md`,
  `critic.md`, `review.md`, `fixpass-wave2.md` (the fix-pass format). `$W = /Users/andiyar/Developer/Ambrosia-Classics/ghidra/deimos-proj`.

## Next session, in order
1. **Fix pass (one Opus agent, brief like `fixpass-wave2.md`)**: apply review I1 + M1–M7
   (`REVIEW-wave3-2026-10-04.md`) and critic C1–C9, the stale-NR strike table, #48/#58/#59-text
   closures, the `FUN_10000000` row above the table header (function-roles.md ~line 65), the 35 stale
   LOW rows in older files and the 40 "listing, no address" HIGH rows (gameplay-leftovers §5.1/§5.2 →
   MED); ledger block + `FIXPASS-wave3-2026-10-04.md`. Then recount with the header command.
2. Optional micro-wave (critic §6, ~900 lines, one reader): rows for the prefs slider procs
   `0x10011750`/`0x100118e0` and AppleEvent handlers `0x10049c20–c50`; listing addresses for the ~13
   replay-critical MED rows (`FUN_100351f0/100352f0/100353e0`, `FUN_10016230`, `FUN_1003bff0`,
   `FUN_1002c960`, entity pool); #40 via `FUN_10010bd0` call sites `1004370c/1004371c`; #47 #54 #60.
3. Merge `origin/main`, push `HEAD:main`, STATE line, memory, remove worktree, delete branch.

## Headline readings (waves 3+4, code only)
Alpha is additive (α = cmd + map, skip ≥ 32; shadow partial α = trunc(a + 0.032·p²)); kernel
floor((dst·α + src·(32−α))/32); scaled sprites = nearest neighbour, integer division, hard 416×480 clamp;
the three sprite switches are always 1 (debug-only writers); static initialisers set 26 draw-template
clips to {0,0,480,416}, 7 spawn-request +0x24 = −1, 9 notice sound records (critic C2: text with
format +0x10d ≠ 0 keeps that clip → in-game overlay text clips at the game-area edge); space = frame 90,
4 px; monospaced cell 6 px; list fades 32 passes; Full Screen pref never read; DrawSprocket
640×480×16, no VBL wait, presents = srcCopy CopyBits; "Tag Index Incomplete! Aborting." does not
abort; Local scanned before Paks; tag threshold 100; zip reader never calls zlib; air launchers'
multiplier always 1.0; scale tolerance = one RNG draw at spawn for 17/386 units; +0xcb never checked
in the entity loop; nothing sets the quit flag during play (#48).

## Owed by Ben
Title screen upright (#10 TGA orientation); pitch direction (#49) and ampCmd scale (#50) by ear;
invulnerability carry-over at level start; TickCount 60.15 vs 60 Hz ruling (#42); OS X volume
messages (#44); optional SheepShaver for atan ±1° (#45), finale ±1 tick (#47), tesm widths, DSp fallback.
