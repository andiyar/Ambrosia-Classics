# Handoff — Aki Phase 2, P2.10 → P2.12 (the game playable; staged for Ben's gate) — 2026-10-04 late night

Opus 5.5 orchestrator (seat; Ben lifted the token cap mid-session: "finish the damn game"), Opus implementers, Opus
review legs (spec + quality per ⚑ MAJOR task), one shared fix round. Plan: `docs/plans/2026-10-03-aki-phases-1-3.md`
P2.10–P2.12. Previous: `docs/handoff-2026-10-04-aki-phase2-p29.md`. Commits carry the project's Fable 5.1 trailer
(invariant 16), on the record: the seat and the agents were Opus.

## What landed (all on `main`, 9ea8c5d)

| step | commit | review |
|---|---|---|
| P2.10 — `startLevel` / `idle` (`_CustomGameScreen`) / `leaveLevel`, both slides, the `perform(_:)` executor, `pauseGame`, `AkiSound.loopTick`, `AkiMusic` game tracks, `controller.gameScreen` wired, `loadLayout`, `triggerGameToMap` | 4a6d906 | spec MERGEABLE (4 Minor); quality MERGEABLE (1 Important = the Q25 edge, 7 Minor) |
| P2.11 — mouse (button bar, double-click guard, select), Esc, pause/unpause/redrawWindow, `abortGame`, menu cases 2/3/4/6/7/9, `showStatistics`, Undo validation, `notYetBuilt` = Phase 3 only | 5e96287 | spec MERGEABLE (3 Minor); quality MERGEABLE_WITH_FIXES (1 Important = same Q25 edge, 5 Minor) |
| plan ⚑ seat corrections + Q25 note | 51ac4a2 | seat |
| fix round — slide draws only on tick change (+autoreleasepool), background before music, idle-hint tick after the redraw, give-up from `g.levelIndex`, param rename, dialog-id assert, docs | 70becea | seat diff audit + M1/M2 |
| P2.12 — `Aki/WHAT-TO-EXPECT.md` (69 lines, 33 bullets) | 9ea8c5d | seat |

Gates from 9ea8c5d, run by the seat: M1 **107 / 0** (0 `aki-*` plists); M2 `BUILD SUCCEEDED`, 0 warnings from our files; M3
`PASS … executed 167 == floor 167`; `tools/stage-aki.sh` → `staged: …(50 PNG)`; boot smoke running → quit, domain empty.

## Grounding + rulings (seat, against the decompile before dispatch)
- `_CustomGameScreen`: the g+0x68 test is ONE if/else (a win leaves in the same call, a time-out on the next game tick); the
  win block is not gated by pause; `b8 < 15 → _LoopSound` reads b8 after a same-call leave (captured before the board drops).
- Return slide lights ALL 12 unlocked flags (DC table = `AkiMap.lanterns`), not `litLanternCount`. Slides are TickCount-paced
  busy loops; `CATransaction.flush()` after each flushing frame (P2.9's runFade pattern).
- `pauseGame(_:)` landed in P2.10 (the executor needs it); `_HandleMenuCommand` case 9 calls `_PauseGame` in BOTH modes — on
  the map the flags run and the core is skipped (g+0x60 == 0).
- Game-mode Undo validation = `game.undoEnabled` (g+0x1f1, DC:1175) — P1.9 had left a placeholder `false`.
- The Stats window's two `IBCarbonPicture` controls (PICT 315) are correctly skipped: 1.2 ships no PICT 315 (paper.png, drawn
  by image view 200, replaced it) and they carry no controlID. The carried P2.11 note is closed.
- `.startMusic` → `startCurrentIfMusicOn()`, whose `musicFlags > 1` test IS DC:7712's gate. Q24: no wait added anywhere.

## What review caught (carried for Ben / later)
- **Q25 edge (both quality legs, Important MED):** the idle timer runs in `.common` modes (the original also adds its timer to
  the modal-panel mode, DC:209–216), so a time-out can end and LEAVE the level while "Are you sure…?" is up; OK then stops
  the map theme and latches end-level, so the next level ends on its first tick. Faithful only if the original's timer fired
  under Carbon's `RunAppModalLoopForWindow` — unknown. **Ruled: no guard; Ben's recall decides** (Q25 row + the note).
- **Esc auto-repeat vs the Give Up dialog (P2.11 quality Minor):** `CarbonDialog` (P1.10) maps Esc to every `not!` button; the
  original sets no cancel button (no `SetWindowCancelButton`), so held Esc may flicker the dialog in the replica. Carried —
  a P1.10 ruling to revisit with Ben, not changed here.
- P3.4 must add the editor arm of `handleMenuCommand` (case 9 Statistics, 2, 3 with its LE-undo fall-through, 10).
- AkiCore idle-hint test is unsigned where the original is signed (differs after ~414 days uptime) — note only.
- `g.paused` survives a leave (faithful: g+0x67 untouched by `_AnimationCustomGameScreenToMap`).

## Not done
- The plan's P2.12 screenshot script: Ben declined computer-use control of `com.ambrosiaclassics.aki` this session.
- `git worktree remove` of this session's own worktree (cwd) — deregister from another shell if wanted.

## Next
Ben's P2 gate on `out/Aki/Aki.app` (Hard, Medium, Easy, Practice start to finish; watch the fade Q24 and the Q25 edge). On a
pass: Phase 3 (P3.1–P3.x — editor, `.aki`, Play Custom Level, Replay). On a fail: a fix chip with Ben's exact words.
