# Handoff — Aki Phase 2, task P2.9 (`GameScreen` drawing — the QuickDraw pipeline) — 2026-10-04 late

Fable 5.1 orchestrator (seat; same session as P2.7–P2.8, continued on Ben's "Do 2.9 here"), Opus implementer, two Opus review
legs (spec, quality — ⚑ MAJOR), one fix round. Plan: `docs/plans/2026-10-03-aki-phases-1-3.md` P2.9. Previous:
`docs/handoff-2026-10-04-aki-phase2-p27-p28.md`. Worktree `aki-p29` (fresh from 4d2e77d; the earlier session worktree had
already been deregistered).

## What landed (all on `main`)

| step | commit | gates | review |
|---|---|---|---|
| P2.9 — `GameScreen` + `GameScreenDrawing` (drawGameTiles, drawBufferTiles, redrawTile, runFade, redrawCustomGameScreen, time bar, elapsed, open pairs, no-more-pairs, flashButton, pressButton, undoRedraw, redrawEntireWindow), `AkiG` +4 fields | 11cdd1d | M2 BUILD SUCCEEDED | spec MERGEABLE 1 Important / 5 Minor; quality MERGEABLE 1 Important / 9 Minor |
| plan ⚑ — fade window rect | 44bf29e | — | seat ruling |
| fix — `AkiGameArt.fadeWindowRect(_:)` + `screenRect` (AkiCore, tested inside `testTileRectsFromABox`), App uses them, `guard let` cleanups, `updateGame` doc | f61b8eb | M1 107 / 0, M2 SUCCEEDED | seat re-ran + diff-audited |
| plan — Q24 fade-pacing note | 20f55ab | — | seat |

Gates from the merge head, run by the seat: M1 **107 / 0** (0 `aki-*` plists), M2 `BUILD SUCCEEDED` with **0** warnings from our
files (the one remaining line is the toolchain's AppIntents metadata notice), M3 `PASS … executed 167 == floor 167`.

## Grounding + rulings (seat, invariant 1)
- Decompile recomputed before dispatch: `_DrawGameTiles` sweep (z 0→6, d 0→49, x 32→0 with y = d−(32−x), break y < 0, list
  order in a cell), face paint (0,50f−10000,38,…) → (8,5,46,54), blank + `fadeMask(0)`, overlay choice by `g+0x60 == 0` /
  selected / hinted under `overlayMask`, window copy (l,t+1,l+51,t+67); `_RedrawCustomGameScreen` order incl. the Practice
  base-tick reset and 300 s cap between the time bar and the digits; elapsed/open-pairs rects; no-pairs overlay. The ±4
  neighbourhood constant `DOUBLE_00033fe0` read from the i386 binary = **4.0** (pixel constants 55 / 0.5 / 46 beside it).
- **⚑ Fade window rect:** `_RedrawMatchedTiles` DC:7957/7960 copies (left, top+1, left+53, top+69) — the plan's bullet 4 said
  `tileRect`. Ruled: new `AkiGameArt.fadeWindowRect(_:)` (AkiCore reopened for exactly this + `screenRect`, the 800×600 port).
- `updateGame(_:)` is an internal mutator on `GameScreen` (S3 says `private(set) var game`): the drawing extension is a second
  file and P2.10's `startLevel` sets the game. Accepted as-built; intent "only GameScreen mutates" stands.
- `perform(_:)` is a `// P2.10` no-op stub; `game` stays nil until P2.10; every draw early-returns on nil; `controller.gameScreen`
  is NOT wired yet (P2.10).
- `redrawNoMorePairs` calls `enterNoMorePairs` (which freezes the clock) before the overlay and splits its events: stop-sound
  before the overlay, `.setNoPairsFlash` after (DC:6433–6447 does freeze after the overlay — unobservable).

## What review caught (carried for Ben / later tasks)
- **Fade pacing (spec Important, MED):** 11 frames × 2 presents with no wait ≈ 22 `CATransaction.flush()` inside one display
  refresh → CoreAnimation likely shows only the last; on 10.4 each QuickDraw flush may have waited for the beam (~22/60 s fade).
  Recorded in S6 **Q24**. If Ben sees no fade at the gate, a per-frame refresh wait is fidelity, not an affordance.
- `pressButton` restores with CopyBits where the original's mask rect lay outside plate.png (Q26, ruled in P2.8) — Ben's eyes.
- Per-call allocations (sweep keys array, two event-array slices, the `surrounding` copy) — once per event, none per tile;
  invariant 15 holds. Sweep keys pack the list index in 16 bits (no tile list approaches that).
- `board.tiles[index]` in `redrawTile` has no bounds check — P2.11's hit-test is the only caller.
- `drawBufferTiles` takes the neighbourhood from `selected` where the original reads `param_2` (same value for its one caller).

## Machine lessons
- The worktree-isolation hook refuses Bash lines that mention `git` beside computed paths or `&&`-chained python/sed with
  variables — run `git` in its own plain command from the worktree, and use the Write/Edit tools for scratchpad briefs.
- One ⚑ MAJOR App task (impl 180k + two legs 110k/138k + fix 73k subagent tokens) ≈ 75k seat with pre-written briefs.
- `git worktree remove` cannot delete the session's own cwd directory (a safety check refuses `rm -rf` of the cwd); deregister
  and leave the 1 MB of ignored build output for Ben, or close from a different worktree.

## Next (chip spawned): P2.10 → P2.11 → P2.12
P2.10 ⚑ MAJOR (two legs): `startLevel` / `perform(_:)` executor / `leaveLevel`, `AkiSound.loopTick`, `AkiMusic` game tracks,
`controller.loadLayout` replaces the Phase-1 stay-on-map body, wires `controller.gameScreen = gameScreenImpl`; `.startMusic` after
a reshuffle gated on `p.musicFlags > 1` in the executor; `.undoRedraw` = `undoRedraw(job)` (full rebuild); `.fade` = `runFade`;
`.flashButton(n, glow)` = step-then-draw already inside `flashButton`. Then P2.11, then P2.12: `tools/stage-aki.sh` → `out/Aki/Aki.app`
+ WHAT-TO-EXPECT.md; Ben plays each difficulty — "it plays like Aki" (and watches whether a matched pair FADES — Q24).
