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

- **Aki Phases 1–3 plan REVIEWED** (`docs/plans/2026-10-03-aki-phases-1-3.md`, contracts not code — Ben's ruling
  2026-10-03). **Phase 1 built through P1.8 (MERGEABLE) + P1.9 (unreviewed)** on branch `claude/suspicious-tu-1af46f`
  (pushed, not merged); AkiCore 31 tests; app builds and stages. HectorShell built by the HectorKit session (main
  `8287ddb`, floor 139). Handoff: `docs/handoff-2026-10-03-aki-phase1-wip.md`. DECISIONS D3 = present path.

## Open, ordered

1. **Phase 1 finish** (handoff 2026-10-03 aki-phase1-wip): P1.9 review+fix, P1.10–P1.12, P1.13 gate → Ben's verdict. Then Phase 2 per the plan.
   ~~Trigger C~~ superseded by the plan; HectorShell done.
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
