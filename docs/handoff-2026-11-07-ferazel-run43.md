# Handoff — 2026-11-07 — Ferazel's Wand, attended run 43 (remainder plan wave 1): the Bat finished, Frogs + Salamanders alive

**Seat:** Claude Fable 5.1 (Ben's resume request; D45.6). Every implementer and reviewer leg Opus 5.5.

## TL;DR
| what | state |
|---|---|
| Ben's re-planning answers | D45 (Ferazel): Q11 Phase 4 pass (Fireball only tested), Q14 Windows pass (Andrew), Q16 defaults stand (unread); HectorKit follows kit main (ef2c341, floor 370); Bat resumed; Phase 6 = 6A/6B/6C gates; release = one `ferazel-1.0` (Mac DMG + Windows zip) |
| RC reconcile | done — run 42's Bat cherry-picked (e605eb0), G2 569/0/2, docs 4dc48c0 |
| BAf (Bat fix round) | merged — 60d92f7 + 54964b6 (+ docs 37dddf5); re-review MERGEABLE 26/26; **the 1xx path form zeroes the swing speed, not the radius** (audit ruling 3 was wrong; plan/audit/spec corrected) |
| FR (Frogs + Salamanders) | merged — 1f052b4 + fix round 8fa5ca2; two legs + re-review MERGEABLE 25/25; **the Frog's aim test reads playerX** (binary quirk; bank §1.3 ⚑); ◈ none moved |
| Ladder | Core **577** = 449 rules + 128 render, 0 failed, 2 opt-in skips; WinKit 81/0/2; GW1 0/2, GW3 0/1, GW4 ok |
| New standing rule | **D45.7 sessions chain automatically** — a closing session re-seeds NEXT and restarts the loop unless a Ben-only question blocks (CLAUDE.md "Workflow") |
| Next | loop run 44 **[BL GF]** (NEXT.md re-seeded; the loop restarted at this close) |

## Root causes / rulings with evidence (do not re-chase)
- **"No radius" flag (BAf):** M l. 39354–39378 zeroes the path record's p3 = `.MakeRadial`'s fifth argument; M l. 35737–35767
  stores the fourth as the radius and the fifth at block +0x14; the radial update adds +0x14 to the angle each frame →
  it is the speed. The platform's 10/11 arm (`PlatformSprite.swift:227`) already passes speed 0.
- **Frog aim (FR):** M l. 70358 compares `*_DAT_1009fd94` (playerX — engine.md l. 170; `Walker.swift:80`) with cy − 0x28;
  raw `1008215c lwz r30,-0x7aac(r2)`, `100824bc lha r4,0x0(r30)`. The idle state reads playerY via `-0x7ab0`
  (`10082314`). Two legs contradicted; the seat ruled from the raw. Ported as written (Ben: follow the binary).
- **"Frog rests 16 px lower" (re-review):** does not reproduce — a test comment's threshold (573) was wrong (589); the
  switch frame's 0x5a gravity crosses no pixel, so `+0xce` is 0 for one frame; solver timing, same for every arc.
- **HectorKit zero-skip 4 Aki skips:** the Aki 1.1.0 app moved on this Mac; the repo's git-ignored `Resources/Aki/1.1.0.app`
  symlink re-pointed at `~/Developer/Ambrosia/Resources/ambrosia-extracted/…/Aki 1.1.0/…/Aki - Mahjong Solitaire.app`;
  the kit's default still misses → set `HECTORKIT_DATA_AKI11` (NEXT RECONCILE 4; QUESTIONS Q17).
- **`DrawModeAuditTests` is line-anchored:** every comment an implementer adds shifts its writer rows (BAf: 14 rows, FR: 11);
  every class brief must say "run `--filter DrawModeAuditTests` and re-anchor".

## Process notes
- Implementers end turns "waiting on a background run" (FR did, twice across the task); one SendMessage resume finishes
  them; TaskStop the agent once its report is in.
- The seat's G2 = `seat-g2.sh` pattern (git archive copy, HectorKit symlink, two commands): core ~1 min, render ~12 min.
  Windows gates `seat-gw.sh` (GW1 → GW3 → GW4 → GW2, ~15 min). Both in the session scratchpad; recreate from NEXT's GATES.
- Ben's RAM rule held: one whole suite at a time beside at most one reviewer's filtered builds.

## Open (ordered)
1. Loop run 44 [BL GF] — the chip. BL closes wave 5.3 (G3, GE levels 1–4, GWB by day).
2. QUESTIONS: Q17 (Aki data path, note), Q16 (Phase 5 defaults, Ben's later read), Q15 items, Q13.
3. Carried [LOW]: `ProgrammedPath.makeRadial` has no caller yet (GF); headless burns never end (EC rule); the Salamander's
   stale register nil on `.KillPlayerShot`.

## For Ben (nothing blocks)
- Nothing to play yet from this run: the enemies on levels 1–4 are now the Walkers, Crawlers, Roaches, Bats and Frogs;
  the next playable gate is the Phase 5 end (level 5 to the Warrior's arena), several runs away.
- Resume phrase for an attended session: "let's resume Ferazel from the remainder plan" — it reads `docs/NEXT.md` first.
