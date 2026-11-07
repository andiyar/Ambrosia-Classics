# Handoff — 2026-11-07 — Ferazel's Wand, attended run 45 (remainder plan wave 2, part 2): the Dillo + the geysers

**Seat:** Claude Fable 5.1 (chained from run 44 per D45.7). Every implementer and reviewer leg Opus 5.5.

## TL;DR
| what | state |
|---|---|
| DL (the Dillo) | merged — 8fd9fe8 + tests-only fix round 8431831 + as-built 64a7673; one leg MERGEABLE WITH FIXES (67 mutants, 3 real gaps → 2 pinned) |
| GY ⚑ (geysers) | merged — 76fd6b9 + tests-only fix round 4639d9a + as-built 3bdc5fa; two legs MERGEABLE WITH FIXES (305 mutants, 34 real gaps → all pinned), re-review on a clean copy MERGEABLE (285/305 killed, 20 equivalent) |
| Ladder | Core **603** = 475 rules + 128 render, 0 failed, 2 opt-in skips by name; WinKit 81/0/2; GW1 0/2, GW3 0/1, GW4 ok, GW2 81/0/2, G5 ok (both heads), G1 ef2c341 / 370 |
| Wave end | none this run (PT closes wave 5.4 in run 46: G3, GE core levels 1–4, GWB by day) |
| main | 8fd9fe8 (DL) → 3bdc5fa (GY + docs) → the docs close; pushed |
| Next | run 46 **[PI PT]** in a chained attended session (NEXT.md re-seeded) |

## Rulings with evidence (do not re-chase)
- **Dillo types 1872–1879 refused at Setup (◇):** the original gives them HP 0 and max HP 0; the death test (M l. 72819) follows
  the state switch so they always die on frame 1, but when the `FastRand(10)` timer starts at 0 or 1 the idle decision divides
  by max HP 0 first (raw 10086a48, plain `divw`, undefined, no trap). Bank §8 variants; the Wraith-variant precedent. None placed.
- **The Dillo's idle vx halving** is `× 0.5` truncated toward zero on both signs (M l. 72607–72608; 1001 → 500, −1001 → −500), not a shift.
- **The Dillo retaliates only after a landed hurt** (`HurtSprite` refused → no attack, no RNG draw); a volley count of 2 fires one
  volley, 3 fires two; the roll does one full turn fewer than its count; the 1871 egg does 0x1c0 with the grey tint.
- **The geyser head sorts at layer 2, not 11:** `.MTNewSprite` stores the argument, then `.SetupBoxSprite`'s common store (M l.
  58938) replaces it before the insert. The bank's "layer 11" was wrong (`geysers.md` run-45 corrections 1).
- **Only the segments hurt enemies, never the base:** every enemy hit routine tests the Box handler first (Walker 58578, Crawler
  56625, Roach 65136, Frog 70510); a segment's `+0x150` is 0, so lava segments pass the Crawler and Frog by. `EnemyCommon.environmentalHazard` unchanged.
- **§9 (b) NR 2 closed:** `.IdleToActiveSprite` (M l. 4215ff) copies the whole record back and runs no Setup; `.MTKillSprite`
  (30739ff) frees nothing — the `+0x9c` block survives idling and is reused (pinned: no RNG draw on reactivation).
- **Ruling-16 guards stay silent:** a missing head / segment / child record or a zero period skips a null-pointer write in the
  original; none reachable from the 27 shipped placements (2 water on level 10, 25 lava on 50/51, no triples).

## Process notes
- **Two review legs collided in a shared scratchpad folder** (leg 1 rebuilt and reverted sources where leg 2's mutation harness
  was running). The re-review re-ran the whole table on a clean copy: no contamination (every "killed" held). From now on every
  leg brief says "your own `mktemp` copy, never the scratchpad".
- Leg 2's harness (`scratchpad/mut/gen.py` + `results.tsv`) was handed by path to the fix-round implementer and the re-review
  leg; both re-ran it — cheap and decisive.
- Leg 1 stopped once "waiting on its own background work": one resume message. Stop a leg once its report is in.
- Seat gate scripts (session scratchpad; recreate from NEXT's GATES): `seat-g2.sh <sha> <out>` (archive copy, `HECTORKIT_PATH`,
  two commands: core ~1.5 min, render ~12 min), `seat-gw.sh <out>` (GW1 → GW3 → GW4 → GW2 → G5 with a `HectorKit` symlink beside
  the copy → the greps, ~16 min). One seat gate run beside one implementer, or two legs alone — Ben's RAM rule held.
- The seat applied the re-review's one-line cite fix itself (a comment); its suggested extra assert already existed (line 304
  of `GeyserTests` pins −0x6ff) and the mutant it named is equivalent.

## Open (ordered)
1. Run 46 [PI PT] — the chip, in the chained attended session (PT closes wave 5.4: G3, GE core, GWB by day).
2. QUESTIONS: Q17 (Aki data path, note), Q16 (Phase 5 defaults, Ben's later read), Q15 items, Q13. Nothing new this run.
3. Carried [LOW]: DL — the stale `KillPlayerShot` register left nil (Salamander precedent), the crush's ground side pinned only
   through the Crawler tests, the jump's `+0xce = 0` indistinguishable (the gravity step clears it first); GY — the segment's
   session row indistinguishable from the old no-op (empty handler, correct as read), the stale-head comment in `Geyser.swift`,
   the spray test's branch-boundary proof relies on draws 50/51 occurring under the fixed seed (asserted, so a seed change fails loudly).

## For Ben (nothing blocks)
- Nothing new to play yet: the Dillo lives on levels 15 and 22 and the geysers on levels 10, 50 and 51 — none enterable yet.
  The next playable gate is still the Phase 5 end (level 5 to the Warrior's arena), two runs away after run 46.
- Resume phrase for an attended session: "let's resume Ferazel from the remainder plan" — it reads `docs/NEXT.md` first.
