# STATE — Ambrosia Classics — 2026-10-03 (night)

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
- **Originals:** Aki 1.1.0 + 1.2.0 UB (symlinked as git-ignored `Resources/Aki/1.1.0.app`, `1.2.0.app`);
  Bubble Trouble X 1.1 UB; Ferazel's Wand 1.0.3, Deimos Rising 1.0.6, Cythera 1.0.4 (PEF).
  Archive map: `~/Developer/Ambrosia/docs/ARCHIVE-INDEX.md`.
- **Local-path dependency:** `Aki/Core` → `../../../HectorKit`; a worktree needs the untracked symlink
  `.claude/worktrees/HectorKit → ~/Developer/HectorKit` (Classics DECISIONS D1).

## Open, ordered

1. **Phase 1 — HectorShell + Aki static screens** (Trigger C in `docs/RESUME.md`): brainstorm → plan → build.
   800x600 logical canvas, integer-crisp / fit-smooth scaling (design §4a), Metal vs CALayer decided by
   measuring (§7); splash (`welcome.png`), map (`map.png` + lanterns), prefs dialog from the 1.2 nibs' strings.
   First staged `.app` for Ben: gate "that is Aki's map screen".
2. ~~RE-bank lane~~ done; Trigger A2 only if a build session hits a NOT-RESOLVED wall.
3. Phases 2–3 Aki, then Bubble Trouble X (design §6). EV's adoption of HectorKit (re-export shim): separate task.

## Carried (not blockers)

- Design doc §4 says 70 QuickTime / 12 raw PICTs; the data says 71 / 11 (PICT 135 is 32-bit cmpCount 4 — a
  real alpha plane). Fix the design doc when it is next edited.
- HectorKit carries EV-engine arithmetic in `SndSound` (`loadSoundsTicks`, `playbackDurationFrames`) by the
  "rename prefixes only" rule; trim only with a ruling. Only data-gated tests cover `snd` format 1.
- `quickTimeBands` returns a tuple, not a struct (API polish for v0.2). No dimension cap on codec images.
- Ambrosia's 1996 installer format unreversed. HD-art packs late polish. Licence at the very end (EV D65).
- **Ferazel RE deepening WIP (2026-10-03 late, branch `claude/recursing-rhodes-932ac0`, worktree kept):** 11 Opus readers + 2 gap readers wrote 17 new `docs/ferazel/` files (~6,400 lines: enemies ×3, bosses ×2, enemy-shots-and-damage, pickups-boxes, triggers-background ×2, spells-detail, save-continue, platforms-ropes-radial, player-states ×2, geysers, held-item-melee, coverage, physics-sprites); three Fable review legs all ACCEPT_WITH_FIXES (1a 0/4/6, 1b 1 Critical/3/9, 1c 0/4/11; `REVIEW-2026-10-03-deepening.md`); fix passes 1a/1b landed; the **consolidated fix pass was in flight when the session's usage limit cut it off** — verify `FIXPASS-2026-10-03-deepening.md` exists and INDEX ledger verdicts are filled before merging to main. Handoff `docs/handoff-2026-10-03-ferazel-re.md`.
