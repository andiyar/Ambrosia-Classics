# Handoff — 2026-11-07 — Ferazel's Wand, attended run 44 (remainder plan wave 2, part 1): Blobs + Crabs, Gremlins + Wraiths

**Seat:** Claude Fable 5.1 (chained from run 43 per D45.7). Every implementer and reviewer leg Opus 5.5.

## TL;DR
| what | state |
|---|---|
| BL (Blobs and Crabs; the Multi Crystal's Blob exception; audit 4 + 20) | merged — 472e424 + 595892a + fix round 71b1431 + re-review row a515415; two legs MERGEABLE / WITH FIXES (282 mutants, 17 real gaps → all pinned); **wave 5.3 closed** |
| GF (Gremlins — body, back layer, rider — and Wraiths) | merged — a068854 + fix round b6afbc6; two legs MERGEABLE / WITH FIXES (324 mutants, 33 gaps → 30 pinned, re-review MERGEABLE) |
| Ladder | Core **591** = 463 rules + 128 render, 0 failed, 2 opt-in skips by name; WinKit 81/0/2; GW1 0/2, GW3 0/1, GW4 ok, G5 ok ×2 |
| Wave 5.3 end gates | G3 1,108/0; visit sweep 3,360 visits 0 rows; bot 86,400 steps 0 failures; Proof B 581/0/3/0 of 584 (16:3x, muted); Mac SDL smoke main menu identical |
| main | a515415 (BL) → b6afbc6 (GF) → the docs close; pushed |
| Next | run 45 **[DL GY]** in a chained attended session (NEXT.md re-seeded) |

## Rulings with evidence (do not re-chase)
- **A moved BootFaces pin (BL):** the level-3 Blob rec 15 runs one Handle at level start then idles, so
  `BootFacesTests.testHotRectsAndEmittersUnchangedByBootFaces` level 3 f30 / f120 moved. With `handleBlob` and the Blob hit
  stubbed every old value returns (implementer and leg 1 independently). Class turning on, run 42's Bat precedent — not an
  Invariant-10 stop. No golden moved (probe: 0 Blob Handle calls on golden routes).
- **The strike's y truncation (BL re-review):** the 36-direction table stores sin 70° as exactly 0.94 (raw `100a18b8` =
  0x3fee147ae147ae14), so angle 70 cannot tell truncation from rounding and index 22 (−64.27) only from a floor; pinned at
  angle 50 → index 23 (−76.6 → −76).
- **Path modes 10/11 for the Gremlin (GF):** `.SetupProgrammedPath` reads the record's p1 with no filter (M l. 39302–39311,
  39354–39378); the Gremlin Setup calls it at M l. 69226 → `ProgrammedPath.makeRadial`'s first caller. The Bat's refusal stands.
- **The unplaced Wraith variant 0x6fe–0x707** is refused at Setup (no sheets 1790/1791 in the data; its Handle calls
  `FastRand(0)`): a named ◇, acceptable while no level places it (bank §5.1; census not re-run for it).
- **The grounded rider's vx × 0.5 (GF):** on a flat floor the 0xa0 tile bounce turns vy negative before the landing check,
  so only slopes 0x2c–0x2f set the flag; the halving is unpinned — leg 2's setup (a rider at rest on one 0x2c tile, vx 1000,
  one frame, counting tile calls) would pin it. Carried [LOW].
- **Audit 4 landed:** `killProc` keeps only the Walker / Dillo / Warrior / Gremlin / Frog / Salamander arms; a Crawler, Roach,
  Bat or Blob through it gets `+0xe9 = 1` only (their Setups store no `+0x50`; `.InitSprite` zeroes it, M l. 35571).

## Process notes
- Both review legs 1 stopped once "waiting on their own background work": one resume message each. Stop a leg once its
  report is in.
- Seat gate scripts (session scratchpad; recreate from NEXT's GATES): `seat-g2.sh` (archive copy, `HECTORKIT_PATH`, two
  commands: core ~1 min, render ~12 min), `seat-gw.sh` (GW1 → GW3 → GW4 → GW2, ~15 min, own `WIN_BUILD_ROOT`), `seat-wave.sh`
  (G3, G5 with a `../HectorKit` symlink beside the copy, GE core, GWB, GW4R behind the launch guard, ~23 min).
- Ben's RAM rule held: one seat gate run beside one implementer, or two legs alone.
- `docs/ferazel/tools/pef.py` defaults to `ghidra/Ferazel_pef`; the binary is under `ghidra/ferazel/` — set `FZ_PEF`.

## Open (ordered)
1. Run 45 [DL GY] — the chip, in the chained attended session (no wave end; PT closes wave 5.4 in run 46).
2. QUESTIONS: Q17 (Aki data path, note), Q16 (Phase 5 defaults, Ben's later read), Q15 items, Q13. Nothing new this run.
3. Carried [LOW]: BL — an extra bounds guard in the unreachable dying block, the Crab's distance computed every frame (pure),
   aim at (0, 0) with no player sprite, a reach ≤ −47 unreachable, `staleSlot: nil` in the hits; GF — the Floater aim's
   `P.y + 8` at a direction boundary, the slope-grounded rider halving, the early return after `.KillPlayerShot` (Bat
   pattern), the stale "refused" comment in `ProgrammedPath.swift`; `pef.py`'s default path.

## For Ben (nothing blocks)
- Nothing new to play yet: Blobs now live on levels 3 and 4 (they pulse, lunge at you, and melt into a fading puddle when
  killed; a Blob's touch does not cost you a Multi Crystal); the Crabs, Gremlins and Wraiths live on levels the game cannot
  enter yet (first on levels 15 and 62). The next playable gate is still the Phase 5 end (level 5 to the Warrior's arena).
- Resume phrase for an attended session: "let's resume Ferazel from the remainder plan" — it reads `docs/NEXT.md` first.
