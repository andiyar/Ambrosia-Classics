# Handoff — 2026-10-06 — Cythera RE deepening, wave 2 CLOSED

Orchestrator: opened on Claude Fable 5.1, switched by Ben to **Opus 5.5** after the dump regeneration ("resuming
with opus runner"); every dispatch below ran on Opus 5.5 — including the review, which was meant to be
Fable-grade (model omitted ⇒ inherited the session's Opus 5.5). Branch `claude/musing-burnell-fb45e0`, merged to
`main`. Cap lifted for Cythera ("ignore cap").

## Landed (all under `docs/cythera/`)
- Dumps regenerated and verified against the bank: main 1955/1955 (290 `FUN_`, 73,652 lines), builtins 95/95,
  extra 37/37, missing 840/840 (23,585 lines), traceback 1,994, `tb.py --missing` over three = 0, scriptdis 958
  listings / 0 unknown / census byte-identical.
- Seat probe: all 95 script builtins are traceback-named functions at the same address (0xA0 `RangeIter`, 0xA1
  `EachIter`, the rest `cb…`) — now in `script-builtins.md` §2.1 and `missing-census.md` §4.
- `missing-census.md` (triage, d1cae64) → five readers on disjoint files: `ui-play.md` (105 bodies), `dialogue-ui.md`
  + `scripted-windows.md` (199), `app-shell.md` (125), `ui-toolkit.md` (316 incl. 41 std templates, identify-level),
  `open-items-2026-10-06.md` (whole-program attack on the open items). 95 + 105 + 199 + 125 + 316 = 840.
- Review `REVIEW-wave2-2026-10-06.md`: ACCEPT_WITH_FIXES, 0 Critical / 3 Major / 13 Minor / 9 Notes, 84 claims
  re-derived, 82 pass. Fix pass `FIXPASS-wave2-2026-10-06.md`: 25 applied, 0 declined. Seat re-derived M1 (rules.md
  §3.4 0x80 condition backwards: `ppcdis.py 10006690 1000673c`) and m1 (`ColorCycle` has one caller, 100432c4,
  body a bare `blr`).
- INDEX: Files rows, NOT RESOLVED verdicts, ledger, m8 register ruling (UI/engine labels are not "game text").

## Findings worth knowing without opening the banks
- Item 22: wave 1 had the ending inverted — crystal quality 1 (Charax charges the distiller) = the saved ending.
- Pacing: the map animation runs at most every F ticks, F = 6 by default on every CPU class ⇒ at most 10 frames/s;
  the speed menu that would change F is never put in the menu bar. Wave 1's MoveAll throttle is dead code.
- Two original code bugs (TRunStart::CloseRoutine releases the wrong picture; TMemoryStream::ReadTo copies into
  the length variable) and two player-visible list/dialog key quirks — all confirmed on disassembly.

## Still open
- 16 `Render__7TViewer` per-pass layer order (FX are drawn at the start of pass 5 of 0–5; the passes are not read).
- Carried sub-points: QTMA music events (9), over-encumbrance effect (15, none found), 0x03/0x05 data words (2),
  0x0210 "Return" (3); N2 narrowed only (0C80 picks by bits 6/7 — intent MED).
- A Fable revision pass over the wave-2 banks (the review ran on Opus 5.5).
- The four scripts inlined in `open-items-2026-10-06.md` could be banked as tools (fixer m7 note).

## Hazards learned
- Omitting `model` on a "Fable-grade" dispatch inherits the session model — after a `/model` switch that is not Fable.
- Five readers committing in one worktree: `git commit -m … -- <own paths>` keeps each commit to its own files.
