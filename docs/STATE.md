# STATE — Ambrosia Classics — 2026-10-04 (late night)

> Live state only. Dated; re-verify before acting. Narrative goes in handoffs, forks in DECISIONS.

## Where we are

- **Phase 0 DONE (2026-10-03).** HectorKit **v0.1.0** (`~/Developer/HectorKit`, tag on f578925): HectorResources /
  HectorGraphics / HectorAudio lifted from EV e23122f + the new banded-QuickTime decoder; machine gate
  `tools/check-zero-skip.sh` PASS at **floor 119** (0 skips with the three `HECTORKIT_DATA_*` vars; EV Override
  forks + Aki 1.1 data). Classics: `Aki/Core` (AkiCore + `aki-census` + 6 data-gated tests, 6/6) and
  `docs/aki/data-census.md` (tool output: 82 PICT = 71 QuickTime + 11 raw, all decode to frame; 50 PNG; 14 + 15
  audio files open; 0 `snd `). Plan: `docs/plans/2026-10-03-phase0-hectorkit-lift.md` (DONE).
- **Replica target is 1.2.0** (Ben's ruling 2026-10-03, recorded by the RE lane in `docs/aki/INDEX.md`; all
  1.1↔1.2 deltas resolve to 1.2). Art therefore comes from the 1.2.0 PNGs (same native sizes as the 1.1 PICTs;
  `data-census.md` §3 maps them); the PICT path stays as oracle and for Bubble Trouble.
- **RE-bank lane COMPLETE (2026-10-03, head 01cb120):** `docs/aki/`, `docs/bubble-trouble/`, `docs/cythera/`,
  `docs/deimos/`, `docs/ferazel/` — each Opus-built, Fable-reviewed (all ACCEPT_WITH_FIXES), fix-passed;
  handoff `docs/handoff-2026-10-03-re-bank.md`; optional deepening = RESUME Trigger A2.
- **Deimos RE deepening, wave 1 landed (2026-10-03 night):** nine gameplay files in `docs/deimos/` (movement, spawn sets, weapons, damage, player, scoring, unit-def structs, bosses, level/scroll), Fable-reviewed ACCEPT_WITH_FIXES + fix-passed; role table 293→510 rows (240 HIGH / 256 MED / 14 LOW); INDEX closes #7 #17 #19 #20 #22 #24 #25 #26 #28. Wave 2 (sprite geometry, particles/RNG, timing, HUD, messages, loose ends, sound, front end) committed on branch `claude/modest-chandrasekhar-868895` c79d5e2 — synthesis/review/fix pass UNFINISHED (usage limit); see `docs/handoff-2026-10-03-deimos-re.md`.
- **Originals:** Aki 1.1.0 + 1.2.0 UB (symlinked as git-ignored `Resources/Aki/1.1.0.app`, `1.2.0.app`);
  Bubble Trouble X 1.1 UB; Ferazel's Wand 1.0.3, Deimos Rising 1.0.6, Cythera 1.0.4 (PEF).
  Archive map: `~/Developer/Ambrosia/docs/ARCHIVE-INDEX.md`.
- **Local-path dependency:** `Aki/Core` → `../../../HectorKit`; a worktree needs the untracked symlink
  `.claude/worktrees/HectorKit → ~/Developer/HectorKit` (Classics DECISIONS D1).

- **Aki Phase 1 DONE — Ben's verdict 2026-10-04: "yes it absolutely is Aki"** (splash + map gate passed). Plan
  `docs/plans/2026-10-03-aki-phases-1-3.md` (contracts not code). P1.2–P1.13 all reviewed MERGEABLE (Opus
  implementers, Opus/Fable reviews; fix round for P1.9/P1.10 at 5da2bf0); merged to main this session. AkiCore 31
  tests / 0 skips; `xcodegen generate && xcodebuild -scheme Aki build` BUILD SUCCEEDED; `tools/stage-aki.sh` →
  `out/Aki/Aki.app` (50 PNG + bundled `Fonts/OsakaMono.ttf`). HectorShell is the HectorKit session's (main
  5a33384+, floor 167 at the gate). Rulings this session: DECISIONS D4. Handoff `docs/handoff-2026-10-04-aki-phase1-done.md`.
- **Bubble Trouble X core lane (2026-10-04 evening, Opus 5.5 orchestrator, cap lifted):** core Tasks 0–11 on main
  (`22e228d`): Task 10 (frame step) and Task 11 (FILM replay harness `btx-replay` + `FilmReplayTests`) each Opus-reviewed
  MERGEABLE; merge-head suite **130** tests, 0 failed/skipped with `HECTORKIT_DATA_BTX` (106 passed / 24 skipped without).
  Replay table (seat-run): FILM 1 `count,level` **FLAG** (level completed frame 1167, samples out 1227 — a pass to name to
  Ben); FILMs 2/3/4 end by the hero's death at frames 645 / 1097 / 447 (pinned as `knownDiverging` in the acceptance test,
  orchestrator ruling). **Diagnosis protocol open:** the hero side stays in sync in every FILM up to its catch (every fresh
  push lands on an object), so the drift is enemy-side; the RNG 0x8000 variant is moot (no such draw occurs), pool counters
  never drift, prefs-off variants are worse, and four Opus audits (eels, blocks/jewels, starfish/multiplier, FILM-3 paths)
  found no discrepancy against the decompile. Strongest lead: FILM 4's original makes **one more `Random()`** between frame
  212's eel roll and frame 213's piranha roll (one inserted draw there makes the player's later pushes squash enemies);
  FILM 3 has a similar window at frames 473–512; FILM 2's catch is a 1-pixel overlap. Mechanism hunt in progress. HectorKit
  v0.2.0 tagged (`4d3746d`, floor 167). Memory `btx-core-lane-2026-10-03.md`.

## Open, ordered
- **Cythera RE wave 1 DONE (2026-10-04):** eight rules banks Fable-reviewed ACCEPT_WITH_FIXES (1 Critical/2 Major/6 Minor, all fixed) and merged; binary decompiled to 100 % of traceback-named functions (1,994 across three git-ignored dumps, `tools/missing-addrs.txt`); open: `docs/cythera/INDEX.md` NOT RESOLVED 5/6/10/16/21–25 — handoff `docs/handoff-2026-10-04-cythera-re.md`.

1. **Aki Phase 2 — the game: CODE COMPLETE, STAGED FOR BEN'S GATE (2026-10-04 night).** P2.1–P2.9 as before (AkiCore
   complete, 107 tests; GameScreen drawing). **P2.10** (level start → tick → end, the event executor, game music and tick;
   4a6d906) and **P2.11** (input, button bar, Give Up / Undo / Tip / Reshuffle / Pause menus, focus-loss pause, Stacked,
   Level Statistics; 5e96287) — both ⚑ MAJOR, spec + quality legs each (P2.10 MERGEABLE ×2; P2.11 MERGEABLE +
   MERGEABLE_WITH_FIXES), one fix round 70becea; plan ⚑ corrections 51ac4a2; **P2.12** note 9ea8c5d = origin/main. Gates
   from the merge head (seat-run): AkiCore **107 / 0**, M2 BUILD SUCCEEDED (0 our warnings), M3 floor **167**, staged
   `out/Aki/Aki.app` (50 PNG) + `out/Aki/WHAT-TO-EXPECT.md`, boot smoke ok. Opus seat (cap lifted by Ben). **Ben's first play (2026-10-04, DECISIONS D6): delighted; matched pairs VANISH → fade fix owed (one refresh wait per
   frame); Esc-Cancel kept; Q25 left as is. Open: the fade fix, then Ben's formal P2
   gate** — play a level start to finish on each difficulty, "it plays like Aki", watch the fade (Q24) and the Give Up
   time-out edge (Q25). Not done: the plan's P2.12 screenshot script (Ben declined computer-use control of the app this
   session). Handoff `docs/handoff-2026-10-04-aki-phase2-p210-p212.md`. Next after the gate: Phase 3 (editor, `.aki`).
2. Bubble Trouble X core lane: Tasks 0–11 merged (130 tests); Diagnosis protocol on FILMs 2–4, then golden freeze (Task 11.5); then the BTX shell on HectorShell.
3. RE deepening chains (Deimos wave 2 fix pass landed; Cythera wave 1 review owed) — separate chips.
4. Phase 3 Aki, then Bubble Trouble X shell on HectorShell (design §6). EV's adoption of HectorKit: separate task.

## Carried (not blockers)

- Design doc §4 says 70 QuickTime / 12 raw PICTs; the data says 71 / 11 (PICT 135 is 32-bit cmpCount 4 — a
  real alpha plane). Fix the design doc when it is next edited.
- HectorKit carries EV-engine arithmetic in `SndSound` (`loadSoundsTicks`, `playbackDurationFrames`) by the
  "rename prefixes only" rule; trim only with a ruling. Only data-gated tests cover `snd` format 1.
- `quickTimeBands` returns a tuple, not a struct (API polish for v0.2). No dimension cap on codec images.
- Ambrosia's 1996 installer format unreversed. HD-art packs late polish. Licence at the very end (EV D65).
- **Aki, for Ben's HectorKit session:** (a) `ShellSoundBank.start` on a track at its end replays from 0; QuickTime left
  `IsMovieDone` true for `_LoopMusic` — Phase-2 effect only (theme alternation window); (b) quitting from fullscreen:
  `exitFullscreen()` re-shows the windowed window, so `windowDidBecomeMain` → `unpause` fires at quit — the original's
  deferred step never ran; HectorShell needs an exit that only orders out (P1.12 review Minor 1); (c)
  `ShellFullscreenWindow.canBecomeMain` true where the original allowed key only (no visible effect yet).
- **Aki carried from Phase 1 reviews (not blockers):** Release Notes — Ben wants the replica's own notes at the very
  end (with the licence); ASWAboutBox/ASWTextViewer-faithful windows after P3 (Q10); the Carbon dialog centres on the
  MAIN display, not the game window's display (as the Carbon code did — Q6, multi-display);  one `fullscreen` accessor (ivar vs `shell.isFullscreen`); the Osaka-Mono guard's Menlo branch is only provable offline on this Mac
  (the font is now installed system-wide); bundling Apple's font is for Ben's machine only (licence).
- **Ferazel RE deepening (2026-10-03, CLOSED 2026-10-04):** 11 Opus readers + 2 gap readers wrote 17 new `docs/ferazel/` files (~6,400 lines: enemies ×3, bosses ×2, enemy-shots-and-damage, pickups-boxes, triggers-background ×2, spells-detail, save-continue, platforms-ropes-radial, player-states ×2, geysers, held-item-melee, coverage, physics-sprites); three Fable review legs all ACCEPT_WITH_FIXES (1a 0/4/6, 1b 1 Critical/3/9, 1c 0/4/11; `REVIEW-2026-10-03-deepening.md`); fix passes 1a/1b landed; consolidated fix pass landed (`FIXPASS-2026-10-03-deepening.md`; labels HIGH 727 / MED 228 / LOW 27); merged to main at 5b15177. Fable spot-review 1d of the fix-pass diff (2026-10-04): ACCEPT_WITH_FIXES, 0 Critical / 0 Important / 6 Minor, 66/66 markers + 76 raw addresses confirmed; fixes + the held-item-melee carries (rows 3, 4, 6–8) landed at 02f29cc. Worktree and branch `recursing-rhodes-932ac0` removed. Still open in the bank: INDEX NOT-RESOLVED items 15–29 (`+0xb8` draw modes, tint/remap colours, NewParticle args, Xichra cannons, OmniPx/PxMid, Mcnv item 3, lighting item 10, Titles item 12). Nothing needs Ben's play check. Handoff `docs/handoff-2026-10-03-ferazel-re.md`.
