# Handoff — Deimos Rising Phase 4, section S3b: the level select (closed 2026-11-20)

Seat: Claude Opus 5.5 (the plan's tag for S3b). Helpers: Opus 5.5 (`fk-implementer`, two `fk-reviewer` legs), foreground;
the one Fable 5.2 cross-check at the close. Section S3b of `docs/superpowers/plans/2026-11-20-deimos-phase4.md` is done
and on main.

## What a player would notice
Nothing yet: the app still opens straight into a game. Underneath, choosing 1 PLAYER or 2 PLAYER now reaches the
original's level select instead of a placeholder: three level previews (the sector before, the chosen one, the one
after, wrapping 12 ↔ 1), the level's name and number, START or NO ACCESS by the best sector reached, a cyan outline
under the mouse, ← → to move with the change sound, the fire or select keys or a click on the middle preview to accept
(Return does not), the green accept flash then a fade to black and the game, the red refusal flash with
"Sector Not Reached", Esc back to the menu (at once, or on the 16th held frame by the preference), and the Caps Lock
pause. It appears on screen when S8a connects the mouse and keyboard to the front end.

## What landed

| Commit | What |
|---|---|
| `18fb2e5` | the level select in `FE/LevelSelect.swift`; 7 tests in `LevelSelectTests`, 1 in `LevelSelectDrawTests`; its own line out of `testStubScreensPassThrough` |
| `0260ddd` | the older tests that walked menu → start → level select now step through the real screen (see Departures 2) |
| `5a7ad54` | fix round: 11 behaviour-changing mutants the quality leg found unpinned are now caught; flash scales pinned as fixed float32 values; all five input latches zeroed on entry as the listing does |

One implementer (two seat rulings mid-task), spec leg (MERGEABLE, numbers checked against the listing), quality leg
(MERGEABLE; 42 mutants, 29 caught, 11 reachable survivors, all pinned in the fix round), Fable cross-check (PASS WITH
FIXES, documentation only — this file).

## Gates, measured by the seat at the branch tip (main had not moved)

| Gate | Result |
|---|---|
| G2 `Deimos/Core` without the replay and campaign bundles | **441 / 0 / 0** (433 + 8) |
| G4 `DeimosReplayTests`; `deimos-replay --all` | **4 / 0**; four PASS lines, exit 0 |
| G12 the direct start matches a bare session | passes (inside G2) |
| G5 Deimos Debug and Release | both `** BUILD SUCCEEDED **` (Aki, BubbleTroubleX not built: no `project.yml` or kit change) |
| G3 census, G7 layering, G10 clean tree | empty diff; prints nothing; clean |
| G6 scope | the six files below |
| G1, G8 | not run (no kit change; G8 is for S1b, S5 and S8b) |

**G2 base for the next sections: 441** (S6 adds its own; whoever merges second measures the sum).

## How the level select was built (what the next reader needs)

- **Frozen entry unchanged:** `LevelSelect()`, the pass signature, the result (`Int?`: sector 1…12, nil for Esc).
  Start/return's hand-off is exact: called after the fade to black with `ammu` playing; the screen never touches the
  music; it fades in (9 steps, after a non-presenting end frame) and fades to black on the way out.
- **Its own bare `GameState`** (ruling 14) carries the frame controller, the console and the pause; no gameplay or
  closed file changed. Every count is in two-tick frames (flash 16, message hold 40, Esc hold 16).
- **Draw order per frame** (read from L 1002f3c0..1002fc5c, 10006240..1000634c): restore from save (not accepted) →
  flash step, notice tick → notice text (queued) → per preview: hover outline (drawn now), the preview or the middle's
  scaled copy plus wash (drawn now), the video grid (queued, layer 15) → name or message, number (queued) → button
  sprites (queued; START skipped while paused) → message fade → end frame.
- **No `Render/LevelSelectDraw.swift`.** The opaque scaled copy is S1a's existing `RenderOp.scaledCopy`; the video
  grid is Core-side draw commands. Nothing render-side was needed.

## Corrections to the plan and grounding A (the listing wins; S8b, carry these onto the gate-4 card)

1. **The right-hand preview DOES show its hover outline.** Plan ruling 15 (first quirk), grounding A §3.3, risk 7 and
   the §10 test row say it never does. L 1002f920..1002f934 (X 1002fd00..1002fd14) give the outline the back buffer's
   full 640×480 bounds as its clip and 1002f998 draws it at once, so all three previews show it; only the flash wash
   keeps the 416 clip. Checked by the seat, both legs and the Fable cross-check. The plan's test
   `testHoverStripRightPreviewRejected` is therefore `testHoverStripRightPreviewDrawn` (count unchanged). Leg 2's plan
   mutant "right strip drawn" is the original's behaviour; the inverted mutant is caught.
2. The card's "the description text": the listing draws the level's name only (L 1002f4c8..1002f50c). Built as the listing.
3. Grounding §3.3's "blit flags 0x0f" for the video grid is the layer byte (L 10006408).
4. The three draw templates 0x100eaddc / 0x100e63e4 / 0x100e3ad0 are byte-identical; the code uses the game's.

## Departures and known differences

1. **The Files list:** `FilmsTests.swift` (S5's, closed section) and `StartReturnTests.swift` / `FrontEndSkeletonTests.swift`
   were edited beyond S3b's list, as the S3a handoff foresaw (mailbox NOTE 16:55): their helpers now press select and
   pass until the game starts, with a bound. No test renamed, no assertion loosened. Numbers that moved only because of
   the extra passes: skeleton t1 t0+8 → t0+44; StartReturn's game pass tick 3,008 → 3,044 (now pinned); Films' bound
   20 → 60. The stop + `ammu` music check is now made on the pass that calls the level select.
2. **For the gate-4 card:** START / NO ACCESS lags one frame after a move (L 1002ea94 reads the middle before the move
   at 1002edd4) — replicated, pinned by `testLevelSelectUnlock`.
3. **For the gate-4 card:** Quit (Dock or menu) on the level select does nothing until Esc or a sector is chosen, and
   choosing one starts the level (X, `osx-build.md` D10); a Quit during the level-select pause leaves as Esc does
   (X 10030cb0..10030cb8). Compare Ben's answer to plan question 4 (Command-Q ignored mid-game).
4. **For the gate-4 card (eyes only):** during the accept flash the name and number are redrawn without a restore
   (L 1002e8ac), so their edge pixels brighten over the 15 frames, as the original.
5. Switching apps on the level select is left to the driver (D11; MED).
6. ShowCursor / HideCursor are requested before their fades (the listing has them after: L 1002e864, 1002ee68): S3a's
   convention.
7. Console cheats typed on the level select act on its empty game state (ruling 14), not the last game's.

## Follow-ups (none blocks the next sections)

- **After a game, the menu loads `back` into the save buffer while that buffer is still level-map size** (found by the
  implementer; outside S3b's files; the Fable probe found no trap). For S8a or a fix wave to check against the listing.
- Three silent fallbacks in `LevelSelect.swift` (~:173 grid sprite, ~:361 `?? LevelDefinition()`, ~:382 `try?` image
  size) only defer a failure to the renderer; unreachable with the shipped data.
- No committed test renders the flash frames; S8b's goldens should include one accept and one fail flash frame.
- `LevelSelect.swift` ~:557–575 repeats the session's end-frame sequence; a shared helper would need a closed file.

## Worktree

`.claude/worktrees/keen-wilson-17bacc` (branch `claude/keen-wilson-17bacc`), removed at the close; it held this
section's three commits and this handoff (all on main) and nothing else. Build products were in the session scratch folder.
