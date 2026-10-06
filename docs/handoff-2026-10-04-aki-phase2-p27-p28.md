# Handoff — Aki Phase 2, tasks P2.7–P2.8 (`Stats`, `AkiLevels`, `AkiGameArt`) — 2026-10-04 night

Fable 5.1 orchestrator (seat), Opus implementers, one Opus review leg per task (spec then quality, neither task ⚑ MAJOR),
house method `~/Developer/Toolkits/fable-kit/orchestrator.md` over `superpowers:subagent-driven-development`. Plan:
`docs/plans/2026-10-03-aki-phases-1-3.md` P2.7–P2.8. Previous: `docs/handoff-2026-10-04-aki-phase2-p25-p26.md`.
Seat spend ≈ 115k at close; P2.9 (⚑ MAJOR, two legs) re-chipped rather than started.

## What landed (all on `main`)

| task | commit(s) | AkiCore M1 | review |
|---|---|---|---|
| P2.7 — `Stats` (win/loss/give-up bookkeeping, unlock, dialog table), `AkiLevels` (13–17 slot, `randomDecoration`) | c70c815 | 100 / 0 | MERGEABLE, 0 Important / 4 Minor |
| P2.7 fix — drop public `Stats.Row` init (S2 lists none); tests pin unlock `< 11` from below (level 10), Practice keeps an existing best, Int16 wrap | 46bd9e4 | — | seat re-ran |
| P2.8 — `AkiGameArt`: tiles, plate, buttons, flash, digits, stones, overlays, slides | 5ade8a5 | 107 / 0 | MERGEABLE, 0 Important / 5 Minor |
| P2.8 fix — flash docs say step-then-draw; slides clamp a negative tick delta to 60 (unsigned compare DC:6600); tests pin cap `r ≤ 11` and stone src/mask | 11e6d9c | 107 / 0 | seat re-ran |
| plan ⚑ — P2.8 `overlayMask` named twice | 67ab939 | — | seat ruling |

Gates from the merge head (= branch head; origin/main had not moved), run by the seat: M1 **107 / 0** (0 `aki-*` plists,
re-checked after the whole gate run), M2 `BUILD SUCCEEDED`, M3 `PASS … executed 167 == floor 167` (HectorKit untouched).

## Pre-dispatch grounding (seat, all confirmed — no ⚑ arithmetic corrections this session)
- P2.7: win block DC:7479–7501 (wins `< 12` incl. Practice; best Int32 set-if-0-else-min, not Practice; unlock `< 11`, not
  Practice — the `g+0x22b` clear at DC:7503 is the App's), stats fill DC:1722–1780 (Int16 minutes/seconds split, Int16 totals),
  `_RandomBackground` DC:7416 `rand()%5+13`. Stats nib parsed with Python: 63 static texts at x 144/206/267/312/374, totals at
  y 289, OK button controlID 2 first — R8 exact.
- P2.8: every `_FlashCGButton` rect (DC:5429–5471) and the time-bar restore/stone/cap rects plus the full cap-cell switch
  (DC:5890–6200) recompute to the plan's bullets 3 and 5; the `r == 0, k > 0` cell falls through to (128,156,153,195).

## Rulings this session (seat, invariant 1)
- **P2.8 naming (within "May settle alone"):** the plan's Interfaces list used `overlayMask` for both the tiles.png mask and the
  pause/nopairs sheet mask. Tiles keep `overlayMask` (P2.9 names it); the sheet mask is `overlaySourceMask`. Also as-built:
  `pairsHundredsDigit(_:)` (hundreds digit has no 0→10 row map), `FlashRects.glowMask(_ p:)` (the glow mask depends on the
  phase, which `flash(_ n:)` cannot know), `*Restore` members as (src, dst) tuples, `StoneDraw.k` with nil full-stone fields
  at k 0. Recorded in the plan text at the Interfaces bullet.
- **Flash phase order for P2.9:** `_FlashCGButton` steps `p` FIRST, then draws the glow with the new p; step and glow happen only
  when the glow flag is set; restore + sprite copies every call. Doc comments say so (11e6d9c).

## What review caught (carried, not fixed — Minor, within "may settle alone")
- `Stats` indexes the `GameSettings` arrays directly (no `at` guard); every blob-decoded settings value has 12 slots.
- Int16 minutes truncation (best ≥ 1,966,080 s) untested; totals wrap untested.
- `AkiGameArt` members verified against the decompile by the reviewer but without a test: `pairsDigitDestination`,
  `elapsedDestinations`, `buttonSprite`, `buttonDestination`, `pressedSprite`, `flash(3)`, the flash restore/sprite/glow rects,
  `faceDestination`, the tile rows. Unused `import Foundation` (matches sibling files).

## Machine lessons
- Setup paragraph exact again; `.claude/worktrees/HectorKit` already existed at the shared worktrees level (not inside the
  session worktree). Baseline 92 / 0 took one `swift test`.
- Two non-MAJOR tasks with one leg each + two fix rounds ≈ 115k seat tokens with pre-written briefs; subagent spend ≈ 550k.
- Reviewer and next implementer in parallel (export vs worktree) worked; the fix agent waited for the implementer's commit.

## Next (chip spawned): P2.9 → P2.10 → P2.11 → P2.12
P2.9 ⚑ MAJOR App `GameScreen` drawing (two review legs, M2 from the head) — read S3 (plan 648–812), D3–D4, R2–R4;
`.undoRedraw` is a FULL `_DrawGameTiles` rebuild with `openPairsAtDraw` deciding grey; flash = step p, then draw. Then P2.10
(`.startMusic` after a reshuffle gated on the music preference in the App executor) and P2.11; P2.12 = `tools/stage-aki.sh` →
`out/Aki/Aki.app` + WHAT-TO-EXPECT.md, Ben plays each difficulty — Ben only.
