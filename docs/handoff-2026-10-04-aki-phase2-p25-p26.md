# Handoff — Aki Phase 2, tasks P2.5–P2.6 (`AkiGame` state machine) — 2026-10-04 evening

Fable 5.1 orchestrator (seat), Opus implementers, two Opus review legs per task (both ⚑ MAJOR), house method
`~/Developer/Toolkits/fable-kit/orchestrator.md` over `superpowers:subagent-driven-development`. Plan:
`docs/plans/2026-10-03-aki-phases-1-3.md` P2.5–P2.6. Previous: `docs/handoff-2026-10-04-aki-phase2-p21-p24.md`.
Session cut at the 250k seat cap after P2.6 (two MAJOR tasks = the session); P2.7–P2.8 re-chipped.

## What landed (all on `main`)

| task | commit(s) | AkiCore M1 | review |
|---|---|---|---|
| P2.5 — `AkiGame` select / match / stacked loss, `GameEvent`, `FadeJob`, `UndoJob`, `TimeBarStep` | 49ed89a | 79 / 0 | spec MERGEABLE 3 Minor; quality MERGEABLE 5 Minor |
| plan ⚑ — P2.6 reshuffle-button test line | 94d8685 | — | seat ruling (below) |
| P2.6 — hint, reshuffle (button vs menu), undo, pause, button bar, tick, time bar | bb9513d | 92 / 0 | spec MERGEABLE 4 Minor; quality MERGEABLE 2 Important (test gaps) + 8 Minor |
| P2.6 fix round — tests pin hint scan start, thaw guards, undo guard; undo docs | 69e7398, 95ba274 | 92 / 0 | mutation-verified by the fix agent; seat re-ran |

Gates from the merge head, run by the seat: M1 **92 / 0** (0 `aki-*` plists), M2 `** BUILD SUCCEEDED **`, M3 HectorKit
`PASS … executed 167 == floor 167` (read-only; HectorKit untouched).

## Rulings this session (seat, invariant 1 — recorded in the plan text)
- **P2.6 `testReshuffleButtonRestoresFrozenRemaining`: no `.pressButton(4)`.** `_SelectCGButton` (DC:7753) draws the pressed
  button only when `g+0x60 ≠ 0`; the plan's behaviour bullet 5 said so, its test line contradicted it. Caught in
  pre-dispatch grounding; plan line corrected with a ⚑ note; implementer built to the corrected line.
- **Ownership-rule wording vs effect.** Two places keep the original's draw-then-mutate order by plan prescription:
  `undo` emits `.undoRedraw` before `setVisible/setOpen/recount` (the original's `_DrawGameTiles` there reads
  removed/face/position/selected/hinted and `g+0x60` only — never isOpen/isVisible — so the deferred draw sees the same
  picture; `openPairsAtDraw` carries the count); the hint "same pair" case emits `.redrawTile(F)` before re-flagging F,
  covered by the `.redrawGameScreen` that follows. Both ruled acceptable; the P2.5 `.redrawTile`-before-flag sites were
  reordered in bb9513d (no behaviour change).
- **`.undoRedraw` is a FULL `_DrawGameTiles` rebuild**, not a two-tile redraw — the App executor (P2.9/P2.10) must rebuild the
  whole tile buffer with `openPairsAtDraw` deciding grey. Doc comments now say so.

## What review caught (carried, not fixed — Minor, within "may settle alone")
- Idle-hint compare is unsigned (`&+ 1800 < now`) where the original is signed (otool 0x132c3 `setg`); differs only past
  2^31 ticks (~414 days uptime). Plan sanctioned unsigned; add a plan note if anyone cares.
- `isRepeatClick` traps on a negative `doubleClickTicks` (GetDblTime is never negative).
- Removed clicked tile keeps `fadeFrame` 0 where the original leaves 11 (nothing reads it; fades read the ST copies).
- `_CalculateSurroundingTiles` sweep is ~1.6M cell checks per match (faithful; debug-build slow, release fine).
- Untested boundaries: pause stop at remaining 15 (<15 vs <16), latch-off with remaining <16 producing no event,
  `applyTimeBarAdjustments` on Practice / the 300 s cap, reshuffle penalty's `remaining ≠ 0` guard (unobservable).
- `.startMusic` after a reshuffle from pairs 0: the original also gates on the music preference (`p+0x20e > 1`) — that
  gate is the App executor's (P2.10), not AkiCore's.
- HectorKit warning `ContainerBackend.swift:20` — Ben's HectorKit session's.

## Machine lessons
- Fresh worktree needs the three `Resources/Aki/*` symlinks (git-ignored) and `.claude/worktrees/HectorKit`; the chip's
  SETUP paragraph was exact. The write hook was no problem once the session ran in its own worktree on a fresh branch.
- `xcodebuild … | tail -n 1` prints an empty line on this machine; grep `BUILD (SUCCEEDED|FAILED)` instead.
- Two MAJOR tasks (impl + 2 legs + fix) ≈ 190k seat tokens with pre-written briefs. P2.7 + P2.8 (one leg each) fit one
  session with room.

## Next (chip spawned): P2.7 → P2.8, then P2.9–P2.12
P2.7 `Stats` + `AkiLevels` (+8 → 100; one data-gated nib test — reviewer exports need `AKI_DATA_12`), P2.8 `AkiGameArt`
rects (+7 → 107; recompute rects from the `_SetRect` calls, R3). Then P2.9–P2.11 (App, all ⚑ MAJOR) and the P2.12 gate:
Ben plays a level start to finish on each difficulty — "it plays like Aki". Ben's eyes only.
