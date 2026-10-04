# Handoff — Aki Q24 fade fix, Phase 2 gate PASSED, iPad scoped — 2026-10-04 night

Opus 5.5 orchestrator (seat), Opus implementer + Opus review leg (spec+quality in one), Opus research agent. Commits carry
the project's Fable 5.1 trailer (invariant 16), on the record: the seat and the agents were Opus.

## What landed (all on `main`)
| step | commit | review |
|---|---|---|
| plan Q24 ⚑ ruling — one refresh wait per PRESENT (two `_DrawToWindow(…,1)` per frame, DC:7958/7961, each a `QDFlushPortBuffer` throttled to the refresh on 10.4+) | 66e0468 | seat |
| `runFade`: `waitOneRefresh()` (full 1/60 s busy-wait on ShellClock's uptime clock) after each present | 6603e55 | MERGEABLE, 4 Minor |
| WHAT-TO-EXPECT fade note | 4b66f3a | seat |
| iPad scope plan | 9676a6b | seat + research agent |
| DECISIONS D7 (iPad rulings) + plan §0 as ruled | c86a7a4 | Ben |
| DECISIONS D9 (P2 gate passed) + STATE + this handoff | this commit | Ben |

Gates from 6603e55: M1 107/0/0; M2 BUILD SUCCEEDED, 0 Aki/ warnings; M3 PASS 167 == 167; staged (50 PNG) → ~/Desktop/Aki.app.

## Review Minors (accepted, notes only)
D6 wording said "per frame" (D9/plan Q24 carry the as-built per-present ruling); the replica waits after a present where
10.4 throttled before the next flush (≈ one refresh longer, negligible); 59.94 Hz margin covered by draw time; `runFade`
has no per-frame `autoreleasepool` (pre-existing).

## Ben this session
Fade: "Yes, it fades". P2 gate: Pass. Difficulty question answered (timer always starts at 150 s; difficulty = bonus /
penalties / Undo / Practice freeze). iPad: six rulings (D7), cap lifted, chip queued.

## Housekeeping
Old worktree `hopeful-diffie-9c7147` + branch `aki-p2-10` removed. A sibling session had just pushed a README with
screenshots (1e82189) from that worktree — safe on main. This session's own worktree `trusting-bose-693641` stays
registered (cwd); remove from another shell when convenient.

## Next
The iPad chip (plan `docs/plans/2026-10-04-aki-ipad.md`, D7). Then Phase 3.
