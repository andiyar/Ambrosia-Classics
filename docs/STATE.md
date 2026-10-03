# STATE — Ambrosia Classics — 2026-10-03 (evening)

> Live state only. Dated; re-verify before acting. Narrative goes in handoffs, forks in DECISIONS.

## Where we are

- **Repos:** `andiyar/Ambrosia-Classics` (this) and `andiyar/HectorKit` (`~/Developer/HectorKit`). HectorKit
  still holds **no code** (door + gitignore only). This repo: doors, design doc, the Phase 0 plan.
- **Phase 0 plan written, Fable-reviewed, fixed, LOCKED:** `docs/plans/2026-10-03-phase0-hectorkit-lift.md`
  (Tasks 0–8; the reviewer dry-ran it end to end: HectorKit 112 tests green with real data, Classics census
  6/6, census tool output matched). Execute it next — Trigger B2 in `docs/RESUME.md`.
- **Aki 1.1 data facts (tool output, 2026-10-03):** the `.rsrc` is a data-fork resource map, 124 resources,
  **82 PICT = 71 QuickTime-JPEG + 11 raw DirectBits** (design said 70/12), **0 `snd `**. Every QuickTime PICT
  is BANDED: N × [0x8200 JPEG band at matrix ty · 1-bit BitMap "QuickTime required" placeholder]; the lifted
  EV extractor returns one band and throws on the LongComment every Aki PICT carries, so the plan adds a band
  walker + ImageIO composite (plan Task 5, MAJOR).
- **Aki originals in hand (both):** 1.1.0 Carbon/PPC (`~/Developer/Ambrosia/Aki/…`) and 1.2.0 Cocoa UB
  (`~/Developer/Ambrosia/Resources/ambrosia-extracted/Action-Adventure/Aki - Mahjong Solitaire/Aki 1.2 UB/`),
  50 PNG / 10 AIFF / 5 MP3. 1.1.0 PPC decompile: `~/Developer/Ambrosia/ghidra/Aki_ppc.decompiled.c`.
- **Bubble Trouble X 1.1 UB** + Intel decompile; **Ferazel's Wand 1.0.3, Deimos Rising 1.0.6, Cythera 1.0.4**
  extracted (PEF). Archive map: `~/Developer/Ambrosia/docs/ARCHIVE-INDEX.md`.
- **RE-bank lane COMPLETE (2026-10-03, head 01cb120):** `docs/aki/`, `docs/bubble-trouble/`, `docs/cythera/`, `docs/deimos/`,
  `docs/ferazel/` — each Opus-built, Fable-reviewed (all ACCEPT_WITH_FIXES), fix-passed; ruling: **Aki targets 1.2.0**;
  handoff `docs/handoff-2026-10-03-re-bank.md`; optional deepening = RESUME Trigger A2.

## Open, ordered

1. **Execute Phase 0** (Trigger B2): HectorKit lift → zero-skip floor → QuickTime bands → Aki census →
   `v0.1.0`. Expect two orchestrator sessions (Tasks 0–4, then 5–8).
2. ~~RE-bank lane~~ done (see above); Aki build chip queued (waits on Phase 0).
3. Phase 1 (HectorShell + Aki static screens), then phases 2–3, then Bubble Trouble X (design §6).

## Carried (not blockers)

- Design doc §4 says 70 QuickTime / 12 raw PICTs; the data says 71 / 11 (PICT 135 is 32-bit cmpCount 4 —
  real alpha plane). Fix the doc when Phase 0 closes.
- Ambrosia's 1996 in-house installer format unreversed. HD-art packs (§4a item 3) late polish per game.
- Licence: decided at the very end (EV D65 carried).
