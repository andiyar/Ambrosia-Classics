# Handoff — 2026-10-06 — Cythera RE wave 3 CLOSED

Orchestrator: **Opus 5.5** seat. Reader and fixer on Opus 5.5; the revision reviewer on **Fable** (`model:
"fable"`, passed explicitly), discharging the Fable pass wave 2 owed. Branch `claude/pensive-hertz-c62e4e`,
merged to `main`. Cap lifted for Cythera ("ignore cap").

## Landed (all under `docs/cythera/`)
- Dumps regenerated and verified: main 1955/1955 (73,652 lines, 290 `FUN_`), builtins 95/95, extra 37/37,
  missing 840/840, traceback 1,994, `tb.py --missing` over three = 0, scriptdis 958 / 0 unknown / census
  byte-identical.
- `render.md` (7dbf43a, 309 lines): `Render__7TViewerFssss` read whole — closes NOT RESOLVED 16.
- Six tools (ebb666c, argparse in fbe5e29): `props_census.py`, `f008_dump.py`, `scan_clr80.py`,
  `scan_byte7.py`, `listing.py`, `tileflag_census.py`; open-items-2026-10-06.md now runs them.
- Review `REVIEW-wave3-2026-10-06.md` (4bd5940, Fable): ACCEPT_WITH_FIXES, 0 Critical / 1 Major / 11 Minor /
  8 Notes, 116 claims re-derived, 113 pass. Fix pass `FIXPASS-wave3-2026-10-06.md` (fbe5e29): 12 / 0 declined.
  Seat re-derived M1 (kind 4 written by `HatchEgg` at `1004f484`), m2 (26 send_signal sites) and N4 (one
  store to 148(r1) in Render).

## Findings worth knowing without opening the banks
- Draw order: ground (unseen cells = tile 0xFF) → pass 0 (props on tile flag 0x100000) → 1 (0x200) → 3
  (none of those) → creatures (prop kinds 4/0x24) → in-flight missiles → pass 5 (0x10 tiles) → 'B'
  frame-10 backdrops → roofs → colour filter and lighting. Pass 2 is compiled dead (constant test).
- `SetStage`'s priority ladder 1..8 is not the draw order — Render never reads the stage; the ladder serves
  targeting. Main and extension tiles are tested separately, so one multi-tile object can split across passes.
- Every wave-2 closure and both wave-1 overturns (item 22 saved ending; rules.md §3.4 0x80) survived the
  Fable re-derivation.

## Still open (all small)
- THood insertion order (`AddToHood`/`MoveHood`) — decides which of two same-pass props on a cell is on top.
- Carried: QTMA music events (9), over-encumbrance effect (15, none found), 0x03/0x05 data words (2), 0x0210
  "Return" (3); N2 intent MED.
- Fixer follow-up: ui-play.md §2.6 does not mention that `CloseAtDistance` only resizes when bit 0x40 of the
  character-table byte is clear.

## Hazards learned
- `model: "fable"` works from an Opus seat; say it in the prompt as a FABLE-GRADE gate.
- Tools without argparse die with tracebacks on `--help`; every new tool now takes `--help`.
