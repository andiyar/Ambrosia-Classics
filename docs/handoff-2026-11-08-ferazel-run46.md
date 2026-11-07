# Handoff — 2026-11-08 — Ferazel's Wand, attended run 46 (remainder plan wave 2, end): the enemy pipes + the renderer's traps

**Seat:** Claude Fable 5.1 (chained from run 45 per D45.7). Every implementer and reviewer leg Opus 5.5. **No run 47 chained** (Ben's word, 2026-11-08): the re-plan repair session rebuilds `docs/NEXT.md` and the plan and starts run 47 itself. This run did NOT re-seed NEXT.md.

## TL;DR
| what | state |
|---|---|
| PI (enemy pipes) | merged — 43b2842 + tests-only fix round cab8d5c; one Opus leg MERGEABLE WITH FIXES (42 mutants, 10 real gaps → all pinned) |
| PT (renderer traps → refusals) | merged — 178788f (abf08f9 in the pt-lane clone) (built in a scratch clone, cherry-picked); one Opus leg MERGEABLE; two minor census wording notes carried |
| Ladder | Core **607** = 479 rules + 128 render, 0 failed, 2 opt-in skips by name; WinKit 81/0/2 |
| Wave 5.4 END | G3 1,108/0; GE core levels 1–4: visit 3,360/0, bot 86,400/0; **Proof B 604/0/3/0 of 607** (10:00, muted); GW4R main menu identical; GW1 0/2, GW3 0/1, GW4 ok, G5 ok, greps empty, G1 ef2c341/370 |
| main | 43b2842 → cab8d5c → 178788f (abf08f9 in the pt-lane clone) → docs close; pushed |
| Next | run 47 [OX LV5] — the repair session's rebuilt chip; **not started by this session** |

## As-executed notes (for the repair session to fold into the new plan)
- **PI:** `docs/plans/2026-10-30-ferazel-phase5.md`, under `#### PI` ("As executed — PI (run 46)").
- **PT:** `docs/superpowers/plans/2026-11-04-ferazel-remainder.md`, under `#### PT` ("As executed — PT (run 46)", the 18-site decision table).
- Both summarised in D44's "As built — attended run 46" paragraph.

## Rulings with evidence (do not re-chase)
- **A pipe waits for its child to die.** The release (`+0x150 > +0x154`) clears the child's emerging flag and resets the clip but does NOT clear the pipe's `+0x1d4` link; that clears only on the child's `+0xe9`/`+0xea` (M l. 60758–60767). The card's "release clears the link" was wrong.
- **`.SetupBoxSprite` spawns a throwaway child** (M l. 59347–59353) and kills it at once — it still draws random numbers and bumps the enemy count. Ported as the Setup's field stores only; the throwaway spawn lands with level 21's spawn code (no built level places a pipe; marked).
- **`+0x150` is 2 after the spawn frame; the child keeps its own Setup's layer** (Walker 4, Blob 8), not pipe + 1.
- **18 trap sites, not 17:** the 18th is `preconditionFailure()` at `SpriteBlitter.swift:486`. 7 refusals, 11 kept — the reviewer agreed with every "unreachable from any data" call (light-face size: `ConvertedPicture.pixel` reads 0 outside the picture; glyph mask: both rasterizers allocate w × h; parallax cells: fixed 0x80 constants).
- **The census now fails on a new trap without a row** (proven: a stray `precondition(` in Mosaic.swift failed `DrawModeAuditTests:1527/:1532`).

## Process notes (this is the run Ben audited the method on)
- **The seat read ~150k before dispatching** (chip 20k words, STATE 20k words, plan cards, audit, bank, dump lines, census tables). Ben's rulings (D44 as-built run 46): STATE/NEXT current-only; one self-contained plan file; the seat hands a leg the card + a line range and never pre-reads source (kit `orchestrator.md` §3 corrected, c5f706d); the superpowers skill line in the chip was for planning only; sweep + bot after level tasks and phase ends only, not every wave end.
- Two implementers ran in parallel (one in the worktree, one in a scratch `git clone` at the same base, cherry-picked after — no conflict, both touched `DrawModeAuditTests.swift` in different regions). Two review legs ran in parallel, each in its own `mktemp` copy. One implementer stopped "waiting on its own background work": one resume message.
- Seat gate scripts: `seat-g2.sh` / `seat-gw.sh` (session scratchpad, copied from run 45 with the paths changed); the wave-end chain ran census → sweep → bot → Proof B → GW4R in one background shell (~23 min).

## Open (ordered)
1. Run 47 [OX LV5] — from the repair session's chip. LV5 closes wave 5.5 with the full GE on levels 1–5 both shells.
2. Carried [LOW], PT: a census row marked "trap: unreachable" is not checked to point at a trap (`DrawModeAuditTests.swift:1257`); the failure message says "throw" for traps (`:1527`); `try!` ×3 and `assert` (`FrameRenderer.swift:411`) are not counted by the census.
3. Carried [LOW], PI: `setupPipe` is not wired into level-spawn (deferred to level 21, marked); the pipe's throwaway Setup child's random draws and count bump land with it.
4. QUESTIONS unchanged: Q17, Q16, Q15 items, Q13.

## For Ben (nothing blocks)
- Nothing new to play: the pipes live on level 21 only. What changed for a player on a later level: a level whose header asks for rain, interlace or a horizon strip now says "the level could not be loaded" instead of opening with the effect silently missing; a Windows proof run reports a refusal instead of crashing when the renderer meets data it cannot draw.
