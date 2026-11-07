> Superseded by `docs/superpowers/plans/2026-11-04-ferazel-remainder.md` on 2026-11-08. Kept as history; nothing current reads it.

# Audit of the built Ferazel work against the remainder spec — 2026-11-04

*Five read-only reviewers (Opus 5.5, `fk-reviewer`), dispatched in parallel by Claude Fable 5.1 in the seat, each with
the spec (`docs/superpowers/specs/2026-11-04-ferazel-remainder-design.md`), one area, five to eight questions, two or
three rules to re-derive by hand from the decompile. Nothing was edited, built in or launched inside the repository;
every build ran in a scratch copy. The seat's rulings come first; the five reports follow verbatim.*

## The verdict in one paragraph

Every rule the five reviewers re-derived by hand from the binary matches the code: the Walker tier table and its
three random draws, the Crawler's leap cooldowns, the Roach's home and speed, the 1760's boulder-or-bomb choice, the
Ax goblin's whole core logic, the Kill idiom, the shield block, the burn's end, the Bat's Setup table, steering and
waking, the programmed path's modes 1–3, the map's 24 nodes and their unlocking, the chapter cards and stage stats
for any level number, the 100-level save block. Every golden holds (the Bat branch moves none and applies cleanly).
The test classes the reviewers ran are all green (counts in each report). What the audit found is, as on Castles,
seams and method, not wrong readings: **the "switch-off check" as every brief phrased it switches nothing off**
(the Setups store their own Handle; only stubbing the Handle does), **the built-level list is a closed range** that
cannot say "1 to 5, then 10", the draw-mode audit **does not know the horizon strip or OmniPx's rain/interlace**,
**18 renderer traps sit outside its refusal census** (a trap takes Proof B's whole run down), one picture is **cut three
ways but cached once** (bites the first boss), and the spec's suite-split card was wrong (the render tests already
have their own target and are the slow part). Three rows change the next wave's Bat fix round. No "redo" of built code.

## Rulings (the seat's; each applied to the spec and the plan, marked ⚑ audit there)

| # | finding (report) | ruling | where it lands |
|---|---|---|---|
| 1 | The switch-off check "set the class's `forClass` row back to `.inert`" changes nothing: every class Setup stores its own handler (B: `CrawlerRoach.swift:57`, `Walker.swift:92`; C: `Bat.setup`); only stubbing the Handle brings the old values back — and when it is done that way, the old values do return exactly (B: swim `[67, 321]` / `c1dd428a3f146d77`, 600-frame `a8dda9cf3e448016`…; C: the two L3 hot-rect rows) | **change (method).** The switch-off check is: *stub the class's Handle body (and any hit it adds) with one local patch, never committed; every old value must return; then revert.* The two writers of the handler (`forClass` + the Setup) stay as they are (harmless). The ◈ causes recorded by runs 40–41 stand: the audit re-ran the right recipe for the Crawler and the Bat and the old values returned | spec §4 R6; plan §0 gates, BAf step 4, FR delta, 6A-W; the Phase 5 plan's Verification model gets a ⚑ audit note (doc-only, committed with this pass) |
| 2 | BAf's minor item (2) "widen the 0x73a… marks to 0x743" is wrong: the class dispatch (M l. 1750–1753) sends 0x73f–0x743 to the Background class; the five "survivors" on that bound are equivalent (C) | **change (the plan).** Item dropped; the five rows removed from BAf's assert list; leg 2's claim was wrong | plan BAf |
| 3 | `ProgrammedPath` (built inside `Bat.swift`) lacks the mode 10/11 Handle body (count `+0xf8`, zero vx/vy, radial updates, zero `+0x194`, M l. 39446–39466) and the "no radius" flag for p1 110/111 (M l. 39307–39309, 39352–39368) **[⚑ run 43: the flag zeroes the swing speed, p3, not the radius — BAf's re-review leg, M l. 39354–39378 + 35737–35767]**; three other classes call the same pair (cannons, maces, the Gremlin) (C) | **change.** BAf builds both (a failing assert first) and moves the pair to `World/Movers/ProgrammedPath.swift`; GF (the Gremlin) and 6A-BX1 (cannon/mace arms) call it — spec R5 | plan BAf (files + scope), GF delta, 6A-BX1 |
| 4 | `EnemyCommon.killProc` has Crawler / Roach / Bat / Blob arms, but none of those Setups stores a Kill proc; a burn on them only marks `+0xe9` in the original (A, B) | **change (small).** BL drops the four arms (default arm: `+0xe9 = 1` only) and retargets `testKillBookkeeping`; the bank's enemy-shots §3.6 wording ("dies through its `+0x50`") gets a correction note in the same task | plan BL delta |
| 5 | Picture 0x46a is cut three ways (48×48 fireball; 64×64 twice for the dead types 0x46b / 0x46c) but the cache keys faces by picture only; the original reads three caches (M l. 51822–51861) (A) | **change (before the first boss).** New minor task **FB** in Phase 6A, before 6A-W: key cached faces by record (`EnemyShot.swift:381/:400`, `LevelRun.swift:1216–1251`), a test that the three cuts differ | plan wave 5 (6A-FB) |
| 6 | Bosses have no `killProc` case, no step-7 contact row (damage 0x70, dump l. 49836–49846) and no Smite entry (A) | **missing (Phase 6, expected).** R2's contract for each boss names all three; each boss task builds them | plan R2 |
| 7 | Carried LOW items: the egg's 0.9 / −0.15 match the data section (A) — closed; the burn is a silent no-op with no face provider (headless only) (A); the other LOWs of runs 40–41 are equivalent or invisible (B, five rows) | **keep.** The egg carry is dropped from NEXT; the headless-burn note goes into the test-harness notes at A5; the rest stay carried | RC (NEXT carries), A5 |
| 8 | `BuiltLevels.range` is a closed range (`1...4`); the levels after 5 are 10, 11, 15…; `1...10` would admit 6–9 (no level data → the original's load error); the bot's script parses the range with `sed`/`seq` (D, E) | **redo (small, Phase 6A's first task).** New task **6A-BL**: `BuiltLevels` becomes an explicit list of built level ids with `contains`; the bot and the sweep read the list from a printed source, not `sed`; `-FerazelLevel` (both shells) refuses an id not in the list; the tests pinned to `1...4`/`1...5` (E's list) move with it; the invented gates (New Game clamp, map refusal, Continue refusal) are deleted at 6C's end when all 24 are built (the original has none) | plan wave 5 (6A-BL), 6C-END |
| 9 | The draw-mode audit has no header check for the horizon strip (`0x2716`), and OmniPx rain / interlace are not refused at level open — level 15 or 70 would open silently with no rain (D) | **change.** Spec §3.2 corrected ("silent", not "refused"); task **PT** (run 46) adds the two header checks to the audit as refusals at level open; 6A-S8 / 6A-RN turn them into draws | spec §3.2; plan PT, 6A-S8, 6A-RN |
| 10 | 18 `precondition` traps in the renderer sit outside the audit's refusal census (`TileGridRenderer.swift:286` water kinds 206–209, `LightRenderer.swift:91/:252/:298/:398`, …); a trap takes the whole Proof B run down (D) | **change.** Task **PT** converts each to a `Refusal` throw with a reason row in the census (or proves it unreachable from any data and says so in the row) | plan PT |
| 11 | The spec's SUITE-SPLIT card would split nothing: `FerazelRenderTests` is already its own target (`Package.swift:43`); Render = 128 tests / 716 s, Core rules = 432 tests / 61 s (D) | **change (spec).** Card dropped; G2 becomes two commands in every brief — `swift test --filter FerazelCoreTests` first (a rules failure shows in a minute), then `--filter FerazelRenderTests` — same totals | spec §5.4; plan §0 gates, standing cards |
| 12 | The Windows smoke's three reference hashes live in two code copies (`smoke-ferazel-win.sh:63–67`, `WinReferenceFramesTests.swift:39–47`) (D) | **change (A5).** The script reads them from the test file (one source); until then a ◈ task edits both | plan A5 delta |
| 13 | Reconcile step 4 / G1 do not say what to do when HectorKit is clean but at a later commit; today G1 fails on every task (D) | **change.** RC rewrites NEXT's step 4 and G1 per Ben's Q-B answer | plan RC |
| 14 | Proof B accepts exactly one Wine skip + two opt-in skips; a third opt-in test fails the run; its switch must also be cleared (`proof-b-ferazel.sh:21–22`, `:126–127`) (D) | **keep (a brief rule).** Any task that adds an opt-in test edits those two lines in the same commit | plan §0 gates |
| 15 | Stale `later:` owners (`GroundCeilingEffects.swift:69`, `EnemyCommon.swift:95`, `Camera.swift:46`, `BackgroundSprite.swift:498`, `StatueSprite.swift:5`); the boss grab labelled Phase 5 (`PlayerState.swift:196`, `PlayerStates.swift:371`); the sweep citation is `:91` not `:75`; A5's gate line still says 617 / 614; G2 counts skips without their names (D) | **change (comment-only / doc).** A5's sweep relabels; this plan cites `:91`, 618 / 615, and the skipped-names grep | plan A5 delta, §0 |
| 16 | The looper's watchdog ends a session after 45 silent minutes; no `busy()` hook (D, low confidence) | **keep.** The seat never waits silently (background gates, `stat -L` polls that print); noted in NEXT's orchestration line | NEXT (RC) |
| 17 | Boss music at level start is a constant and the in-loop fade to track 30 is a comment (E) | **keep (owned).** LV5's card already builds both sites from M l. 5218–5221 / 5266–5274; E's "redo" is LV5's scope, confirmed | plan LV5 (no change) |
| 18 | `.Victory` is not built: a finished level always goes to the map (`NewGame.swift:175`); the end-of-game pictures exist (E) | **keep (owned).** 6C-VI | — |
| 19 | The picture cache (`CachedFaces`) is a per-class subset copy of the original's registration order (`LevelRun.swift:1062–1162`); each class must slot its entries at the original's position (E) | **change (R1).** R1 records the original's registration order per class from `.LoadCachedSpriteFaces` (M l. 73769–73869); every class / level task cites its slot | plan R1 |
| 20 | Node ≠ level on two map nodes (node 60 → level 62, node 62 → level 67) (E); a few dump-line citations a few lines off in `Walker.swift` / `AxGoblin.swift` (B) | **keep / change (comment-only).** 6C's level tests walk 40 → 60 → 62 and 62 → 67; the citations are fixed by BL's comment round | 6C cards; BL delta |
| 21 | A 1760 with record p1 ≥ 2 would spawn a Walker type through the enemy-shot Setup; the swarm block holds 20 in the original; the idle 0x6cc Setup face pre-set (B, C) | **keep (as the original; comments).** One-line comments in BAf / BL's rounds | — |
| 22 | The level-1 enemy total 0xf; the ladder BA 569 … LV5 618; every golden; every test class run — all confirmed (A, B, C, D, E) | **keep.** The spec's §1.2 numbers and the plan's ladders stand | — |

**Corrections to the spec from the rulings:** §3.2 (rain/interlace open silently), §3.4 (BA: about 28 of the 40
survivors are real), §4 R5/R6 (the path's home; the switch-off recipe), §5.4 (the suite rule), §7 (done).
**Corrections to the plan:** §0 gates (G2 two commands, the skipped-names grep, the Proof B opt-in rule, the sweep
citation), BAf (rulings 1–3), BL (4, 20), PT inserted at run 46 (9, 10), A5 (12, 15), R1 (19), 6A-BL first and 6A-FB
before the Warrior (5, 8), 6C-END (8).

---

# The five reports, verbatim


---

# Report A-foundation

# Audit A — enemy foundation and enemy shots (Phase 5 EC + ES, runs 39–40), main 07bc11d

| Finding | keep / change / redo / missing | File:line | Why | The fix (one sentence) |
|---|---|---|---|---|
| The "Kill proc" switch treats Crawler, Roach, Bat and Blob as counting kills, but none of those four Setups stores a Kill proc (`+0x50`): in the original a burn or any other `+0x50` caller only sets `+0xe9` for them (no live − 1, no stat + 1, no `+0xea`, no Roach/Bat score). Unreachable today (no writer burns those four classes; `+0x1a2` writers are Walker, swarm member, Gremlin, Frog, Salamander, Dillo, Warrior, bosses, ShieldBlock, Wizard/Xichra hits on player shots), but the bank already says so (enemies-ground Corrections #10b, run 41) and the code was not brought in line. Confidence high, severity low (latent). | change | `World/Enemies/EnemyCommon.swift:93` (and the test `Tests/FerazelCoreTests/Enemies/EnemyCommonTests.swift:105-119` that pins the wrong rows) | Dump: `.SetupCrawlerSprite` M l. 56153–56246, `.SetupRoachSprite` 64899–64957, `.SetupBatSprite` 68108ff, `.SetupBlobSprite` 67671ff store `+0x4c`/`+0x5c` only; `.InitSprite` zeroes `+0x50` (M l. 35571). | Route `.crawler/.roach/.bat/.blob` to the no-Kill-proc arm (`+0xe9 = 1` only) and re-point the bookkeeping test to Walker / Gremlin / a Frog-or-Dillo stand-in. |
| `killsForGood`'s list is right as a list of which Kill routines store `+0xea`, but it is used only through the Kill-proc switch, so with the fix above Crawler/Roach/Bat/Blob entries are dead there (their own Handles call their Kills directly). The doc-comment says "13 enemy Kills"; the dump has 10 class Kills + 4 boss Kills (Demon, Chief, Wizard, Xichra all store `+0xea`, M l. 74968ff, 75502ff, 76136ff, 77451ff). Confidence high, severity minor. | change | `EnemyCommon.swift:41-49` | Comment count and boss coverage. | Correct the count in the comment and add the four boss Kills (and their score tails) when Phase 6 adds their cases. |
| Phase 6 gap: the Kill-proc switch has no boss cases, so a burnt boss (Demon/Chief/Wizard/Xichra Handles write `+0x1a2 = 1`, M l. 74712, 75207, 75857) would get `+0xe9 = 1` instead of its own Kill. Step 7 lacks the Demon/Chief/Wizard rows (damage 0x70, dump l. 49836–49846) and Smite lacks four boss Handles. All correct today (bosses are `.inert`). Confidence high, severity important for Phase 6. | missing (Phase 6) | `EnemyCommon.swift:91-104`; `Player/HitPlayerSprite.swift:64`; `Items/Smite.swift:18` | Bosses are on the step-7 list and Smite's 15-Handle list in the dump. | Phase 6's boss tasks must each add the case to `killProc`, the step-7 handler list and `Smite.enemyHandlers` (name it in their Contracts). |
| The fireball cache: 0x46a is cut three ways (6 × 48×48 for 0x46a, 6 × 64×64 twice for 0x46b / 0x46c), but `FaceRef(pict: 0x46a, …)` and `loadedSets` key only by PICT, and the Handle's 0x46b/0x46c arm reads `face(fireball, phase)` — the same key as the 48×48 fireball. In the dump 0x46b reads `_DAT_100a0844`, 0x46c `_DAT_100a0840`, 0x46a `_DAT_100a0848` (M l. 51822–51861). Phase 6 would draw the dead fireballs at the wrong cell size. Confidence high, severity important (latent until Phase 6). | change (before Phase 6) | `World/Enemies/EnemyShot.swift:381, :400`; `Front/LevelRun.swift:1216-1251`; `EnemyShot.swift:49-53` | Three records of one PICT need three distinct face sets. | Key cached sets (and `FaceRef`) by cache record, not PICT, and make 0x46b/0x46c point at the 64×64 records. |
| Carried LOW "egg 0.9 / −0.15 unchecked": checked now with `docs/ferazel/tools/const.py` — `0x100a1a58` = 0.9 (egg roll, M l. 51786–51787), `0x100a1a00` = −0.15 (Chief boulder rebound, M l. 49917), `0x100a1a18` = −0.38 (shield), `0x100a1a38`/`1a50` = the int→double magic. All match the code. | keep (close the carry) | `EnemyShot.swift:60-64` | Verified against the data section. | Drop the carry from NEXT.md. |
| Carried LOW: the Setup-face fallback width for 0x6a5/0x6a6 measures the whole picture when no renderer is present (headless only). Does not touch Phase 6. Confidence medium, severity minor. | keep | WK1 note, `Sprites/SetupFaces.swift` | Only headless runs see it; shells pass the renderer. | Leave carried; fix only if a headless golden starts depending on it. |
| Carried LOW: the airborne face's `onSprite` term unpinned. Walker-only, not Phase 6. Confidence medium, severity minor. | keep | `World/Enemies/Walker.swift:694` | Test gap, not a wrong reading. | Add one assert with `onSprite ≠ 0` while airborne in a Walker test when next touched. |
| Burn with no face provider (headless) is a silent no-op, so a burning sprite never reaches its Kill in a headless session — a shield-reflected dart or a burning Walker lives forever there. The shells always pass the renderer, so play is unaffected. Confidence high, severity minor. | keep (document) | `Particles/Burn.swift:29` | Divergence only in headless runs/tests. | Note it in the test harness doc; tests that need a burn end must supply `particleFaces`. |
| Bank wording: enemy-shots-and-damage §3.6 says a reflected dart "dies through its `+0x50` Kill callback"; `.SetupEnemyShotSprite` stores no `+0x50`, so it ends with `+0xe9 = 1` (the code is right). Confidence high, severity minor. | change (bank) | `docs/ferazel/enemy-shots-and-damage.md:375` | Bank lags the code. | Append a correction note. |
| `EnemyCounting.kill` guards the stat write with `0..<100`; the dump has no bound. Harmless (level index is always in range). Confidence high, severity trivial. | keep | `EnemyCommon.swift:35` | Defensive bound. | None needed. |
| Every unbuilt class is dormant: `forClass` returns `.inert` for gremlin, floater, frog, salamander, blob, crab, dillo, warrior, geyser segment (dead Blob, crab segments, swarm members and insect bodies are never created); the step-6/step-7 contact rows, Smite and the statue wrapper key on the handler, so none fires. | keep | `Sprites/SpriteSlot.swift:566-580` | Verified by grep of every use. | — |
| `.ShieldBlock`, the step-7 rows, the step-6 rows and the Kill idiom match the dump line by line (details below). | keep | `EnemyShot.swift:648-698`; `HitPlayerSprite.swift:1203-1305` | — | — |

## Re-derivations

**1. Kill idiom.** `.KillWalker` (M l. 58620–58628) and `.KillCrawler` (56693–56702): if `+0xe9 == 0` and `+0x1b5 ≠ 0` → `*_DAT_1009ffb4 − 1` (live) and `G + 0x306 + 2·L` + 1 (L = `*_DAT_1009feac`); then `+0xe9 = 1` always; Crawler also `+0xea = 1` always (Walker never). Gremlin (69736) returns first while `+0xe9 ≠ 0`; Roach / Bat add score only (Roach: only if `+0xe9` was 0; Bat: always +100). `EnemyCounting.kill` matches line by line (count first, then the unconditional 1 — which also resets a running `.UpdateSprites` count-up, as the original does). Note: the Walker corpse-raft branch (M l. 57785–57790) counts without setting `+0xe9`, so a raft later killed through `.KillWalker` counts twice — the code copies that faithfully (`Walker.swift:380-384`).

**2. `.ShieldBlock`** (M l. 48359–48444). ax = shot `+0x10` − (vx >> 8); side 2 if ax > player x + rect right − 10, side 1 if ax < x + rect left + 10 (left wins). Acts only on EnemyShot Handles (0488), a matched side equal to the facing `_DAT_100a5f5a`, and the shield counter > 2; counter = 7. Darts 0x76c–0x775 / spine 0x754: snd 303, Magical Shield → burn start `+0x1a2 = 1`, vx·−0.38, vy·−0.38 − 0x5dc, gravity 0x100 (reflect, not killed). 0x6f4 with the Magical Shield: only while `+0x160 == 0`: snd, vx/vy negated, vy + 0x140, `+0x160 = 1`, particles (1,1,1,100,0x65) — a second block does nothing but still blocks. Everything else (incl. 0x6f4 without the shield): snd, `.KillEnemyShot`. Non-shot arm unreachable. Code matches.

**3. Burn end** (M l. 38765–38840). `+0x8d + 1` rows a frame; each row +1; ≤ 0 returns (0 → 1). After the loop, row > face bottom (`face+0xc`) → `+0x50` Kill proc, or `+0xe9 = 1` without one (type 0x780 → 0x781 → 0x780, no change). `.BurnFaceRow` (38514–38663): counter c, draw order R4, R12, R100, R150, R50, R25, R5 [R200, R100, R250, R25]; shape 0 keeps the last. `Burn.swift` matches.

**4.** All dormant (table). **5.** Live step-7 rows today: Walker, Crawler, Roach, EnemyShot (+ the Bat on the unmerged run-42 branch); waiting: Gremlin, Frog, Blob, swarm member, Warrior, and step 6's Salamander / Floater / Crab / Dillo; bosses absent (Phase 6). Row set and damage/coin rules match §3.4–§3.5 for the built classes.

**7.** Level-1 total 0xf = Walkers 7 + Crawlers 3 + Roaches 5 (`LevelRunTests.swift:284-287`, `EnemyCommonTests.swift:74-75`, 85). Roach Setups outside the window → 10 (0xa).

## Tests measured (scratch copy of 07bc11d, HectorKit 35a85ba)
- `swift test --filter EnemyCommonTests`: 8 run / 0 failed / 0 skipped.
- `swift test --filter EnemyShotTests`: 11 run / 0 failed / 0 skipped.

---

# Report B-ground

# Audit B — the ground enemies (Walker, Ax goblin, Crawler, Roach), main 07bc11d, HectorKit 35a85ba

Read-only. Built and run in a `git archive` scratch copy (`scratchpad/auditB/`), HectorKit archived at 35a85ba,
`FERAZEL_DATA` = the main checkout's `Resources/Ferazel`. One build at a time.

| Finding | keep / change / redo / missing | File:line | Why | The fix (one sentence) |
|---|---|---|---|---|
| The "switch-off" as phrased (only the Crawler's `forClass` row back to `.inert`) does **not** switch the Crawler off: every golden stays on today's values (11/0). The Crawler Setup stores its own Handle (`s.handler = .crawler`), so the row is not the switch. With the Setup's store also routed through `forClass`, the old values return exactly (swim `[67, 321]` / `c1dd428a3f146d77`; 600-frame `a8dda9cf3e448016` / 3114 / `28a48762cfff1b2b` / 1574122804 / 156). The run-41 check did it right (both rows **and** the old `SetupFaces`). | change (spec + plan wording) | `CrawlerRoach.swift:57`, `Walker.swift:92` (same pattern), `SpriteSlot.swift:566–580`; spec §4 R6 | Confidence high, severity medium. R6's "with its Handle stubbed back" must name what the stub is, or a future switch-off on the Warrior passes vacuously. | Word R6 and the ◈ recipe as "the class's `forClass` row **and** its Setup's `handler` store set to `.inert` (or the Handle body made a no-op)", and note that the moved goldens live in `Phase2GoldenTests` (`FrameGoldenTests` does not move). |
| `forClass` and every class Setup both write the Handle; the row only matters for slots made without a Setup. | keep (note) | `SpriteSlot.swift:575–577`, `Walker.swift:92`, `CrawlerRoach.swift:57/107` | Confidence high, severity low. Two writers of one fact; harmless, but it is what made the check above vacuous. | Leave as built; say in the Phase 6 brief that the Setup's store is the effective switch. |
| Walker tier table, the three Setup draws (order 0x5fff → 0x46 → 400), flips, hot rects, the 1750 HP column (type 0x6d6 exactly) | keep | `Walker.swift:57–68`, `:82–138`; test `WalkerTests.swift:78` | Re-derived by hand from M l. 56898–57100; matches the code and the test. The question's "four draws" is wrong: the Setup makes **three**. | — |
| Crawler `+0xa6`: 3 from Setup, 10 + R(10) at the leap, 20 + R(30) at the hop, counted down on the ground; Roach `+0xa6` 3 and written only; Roach `+0x154 = x` and vx 0x4b0 written straight (not through `.SetSpriteSpeed`) | keep | `CrawlerRoach.swift:52–131`, `:178–203`, `:268–290` | Re-derived from M l. 56186, 56312, 56371, 56388, 64945–64946; exact. | — |
| 1760 boulder or bomb = `0x6e1 + record p1` (p1 0 boulder, 1 bomb), x = cx ± 0x1c − 0x10, y = cy − 0x26, layer + 1, shot `+0xa6` −30, vy before vx, vx negated when flipped; the blink, re-arm, ×0.7 friction | keep | `Walker.swift:502–574` | M l. 57995–58079; exact. | — |
| A 1760 with record p1 ≥ 2 would spawn type 0x6e3+, which is a Walker type, through the enemy-shot Setup | keep (note) | `Walker.swift:563–566` | Confidence high, severity low. The original does the same. No shipped level places it (p1 0 or 1 everywhere, levels 1–62). | None needed; a one-line comment would stop a later reader "fixing" it. |
| `.AxGoblinCoreLogic` (flee or chase, wall jump, swing entry, jump, retreat, hop) and the 1750 arm (walk, swing at `+0x46` 8, airborne, dying) | keep | `AxGoblin.swift:43–353` | Line-by-line against M l. 57101–57347 and 58082–58306: every compare, draw order, clamp and store matches, including the signed-compare idiom for the wall test. | — |
| Statue arm present where the dump puts it in all four classes: Walker/Ax goblin before the "not dying" test (M l. 58527–58529); Crawler and Roach **after** `.KillPlayerShot` (M l. 56580–56582, 65174–65176) | keep | `Walker.swift:813–815`, `CrawlerRoach.swift:446–451`, `:473–478` | Order and conditions exact. | — |
| Smite / geyser hazard: Walker and Ax goblin go through `.HurtGoblin` 100 (the Ax goblin's extra 611 / 612 cries); Crawler reads `+0x14c == 1 ∨ +0x150 == 2` (as read); Roach `+0x14c` 1 or 2; the knockback is 0.65·vx (Crawler) or vx >> 1 (Roach) | keep | `Walker.swift:845–846`, `EnemyCommon.swift:159–201`, `CrawlerRoach.swift:458–486` | M l. 58590–58595, 56636–56640, 65152–65158; exact. | — |
| Liquids: Walker kind 0 → 0xc / −150 / 0xc, kinds 1–2 → 0x13 / −100 / 0x11, kind 3 heals; Crawler kinds 1–2 only; Roach every kind; Walker surface damage `hdr+0x270e` on material 2; Crawler and Roach have no material test | keep | `EnemyCommon.swift:211–236`, `Walker.swift:678–687` | M l. 58426–58458, 56497–56512, 65103–65110; exact. | — |
| Save write-backs: no class stores `+0x188…+0x18b` (none anywhere in M l. 56123–58700 or 64886–65262). `+0xea` only on the 1700 dying path (every frame, M l. 57740; this covers the 1705 and 1760, which become 0x6a4 on death), `.KillCrawler` (56701) and `.KillRoach` (65218); none on the 1750 path | keep | `Walker.swift:352`, `CrawlerRoach.swift:355–365`, `AxGoblin.swift:178` | Matches the dump. | — |
| Line citations a few lines off: `+0xea` cited as M l. 57752 (it is 57740); record `+4` as 57774 (57773); `.KillWalker` 57784 and 58237 (≈ 57785 / 58238); record `+4` in the Ax goblin's death as 58226 (≈ 58224) | change | `Walker.swift:352`, `:370`, `:378`; `AxGoblin.swift:199`, `:207` | Confidence high, severity minor. Not visible in play; misleads the next reader. | Re-cite the five comments. |
| Carried LOW 1: `EnemyCommon.killProc`'s Crawler / Roach arm cannot be reached (neither Setup stores a Kill proc; only the burn and the Walker deaths call `killProc`, and nothing burns a Crawler or Roach) | keep | `EnemyCommon.swift:93–94` | Confidence high. Not visible. If a later path ever calls it on a Crawler, the port would **count** the kill where the original (`+0x50` = 0) only sets `+0xe9`. | Move `.crawler` and `.roach` to the `default` arm (`+0xe9` only) when a Phase 6 task next touches `killProc`, with a one-line test. |
| Carried LOW 2: the ceiling Crawler's slot face is 0x6b0 from Setup; the dump stores the absent 0x5dc (no face) | keep | `SetupFaces.swift:518`, `:610–612` | Confidence medium. Not visible: it is idled at spawn and its Handle sets 0x6b0 before any draw. The only readers before the Handle would be a face-width or burn read, and none happens on an idled sprite. | Keep. If it is ever touched, give `.handle` entries for the Crawler a nil slot face, as the Platform and Button already do. |
| Carried LOW 3: both CR Hits read the shot's light slot before `.KillPlayerShot`'s cleanup | keep | `CrawlerRoach.swift:444`, `:471` | Confidence high. Equivalent: `.StandardSpriteCleanup` does not touch `+0x9a` (checked), so before and after give the same slot. Visible only as the dying shot's light changing colour for its last frame, which matches the original. | — |
| Carried LOW 4: the `+0x160` audit excludes `AxGoblin.swift` by file name | keep | `DrawModeAuditTests.swift:1389–1398` | Confidence high, severity low. The paired assert proves `AxGoblin` code runs only from the Walker's 0x6d6 arm, so the exclusion is sound today. It would hide a future Box write placed in that file. | Optionally assert that every `AxGoblin.swift` write is on `s`, the goblin. |
| Carried LOW 5: the Walker Hit's shot-kill recolour (`.KillPlayerShot(o, 0, 0)` on the hurt path) | keep | `Walker.swift:801–809` (no `staleSlot` passed) | Resolved from the raw: in `.HitWalkerSprite`, r29 = the **Walker** (`addi r29,r3,0x0`, raw `1006a278`), so the original recolours the Walker's own `+0x9a`. A Walker never holds a light (a statue's light is removed on restore), so the slot is −1 and `.ChangeLightColor` ignores it. The port's nil is equivalent and not visible. | Write that reason into the comment, so no later reader passes the shot's slot. |
| `HitWalkerTileSprite` reads pos.h after `.WallBounce` | keep | `Walker.swift:869–874` | Checked in the raw: it reloads from the stack home that `.WallBounce` updated (`lha r3,0x9e(r1)`, raw `1006a8e8`), as the port's `inout pos` does. | — |
| Walker sheets for levels ≥ 10: only 1700 / 1705 / 1750 / 1760 are placed on levels 10–62 (tiers p3 ∈ {0, 1, 3, 4, 5, 6}, p1 0/1, one p4 = 1). The tier changes only the tint word 0x10010…0x10015 (mode 1, tint tables 16–21 of 25 — already rows in the draw-mode audit), never a sheet | keep | `LevelRun.swift:1121–1186` | Every sheet the four types use is marked (1750: single 0x6d6 + sets 0x6d7…0x6da, M l. 56998–57005) and held in `handleSets` or the Setup table. A later level needs no new Walker mark. | — |
| Plan WK1 / CR golden predictions ("every level-1/2 golden moves") were wrong; recorded in "As executed" | keep | plan l. 975–976, 1013–1020 | Already corrected in the plan. | — |

## Re-derivations

**1. Walker tier table (`.SetupWalkerSprite`, M l. 56898–57100).** The tier is read from the live record's p3
(`rec + 0xc`, M l. 57013). The defaults are `+0x158` 8 and HP 500, with `+0xb8` left as `.InitSprite` set it:

| p3 | `+0x158` | HP (others) | HP (0x6d6) | `+0xb8` | other store |
|---|---|---|---|---|---|
| 1 | 16 | 250 | 500 | 0x10010 | |
| 2 | 6 | 675 | 1200 | 0x10011 | |
| 3 | 13 | 950 | 1680 | 0x10012 | |
| 4 | 4 | 1500 | 2000 | 0x10013 | `+0x100 = 1` |
| 5 | 10 | 850 | 1500 | 0x10014 | |
| 6 | 6 | 750 | 1350 | 0x10015 | |
| 0, ≥ 7, < 0 | 8 | 500 | 500 | — | |

The draws in order are `R(0x5fff)` (voice `+0xf0`, M l. 56957), then `R(0x46)` (`+0x14c` = 120 + r, l. 57079), then
`R(400)` (`+0x154` = 1000 + r, l. 57082). That is three draws, not four, and both the code and `testWalkerTierTable`
pin all three.

**2. Crawler and Roach.** The Setup stores `+0xa6 = 3` (M l. 56186). In state 2, on the ground, `+0xa6` counts down to
0 (l. 56328). At 0, with the wind-up idle (`+0xb2 == −1`) and the player within 70 px across and 100 px up or down,
the wind-up starts (`+0xb2 = 5`, l. 56342). When the wind-up reaches 0 the Crawler leaps and stores
`+0xa6 = 10 + R(10)` (l. 56311–56312). The same frame's ground count-down then takes 1 more off. In state 3 the hop
stores `+0xa6 = 20 + R(30)` (l. 56370–56371); the "else" branch decrements with no floor (l. 56388).

The Roach Setup stores `+0x154 = +8`, the spawn x (l. 64945), and writes `+0x24 = 0x4b0` straight, not through
`.SetSpriteSpeed` (l. 64946). Its live record's p3 of 0 is rewritten to 0xaa (l. 64940–64944). Every value matches
the code.

**3. The 1760 and the 1750.** The 1760 throws at `+0xb2 == 8` (M l. 58046), calling `MTNewSprite(rec.p1 + 0x6e1, …)`:
p1 0 is the boulder, p1 1 the bomb. The 1750 enters the swing only through the core logic. It needs the target
within 40 px up or down and 110 px across, not fleeing (`+0xb6 == 0`), and no wall jump (l. 57185–57196). The swing
then counts `+0x46`: at 5 it plays snd 704 at 45000; at 8 it re-arms `+0xa6 = 10 + R(12)` and spawns the axe hitbox,
type 0x6d6 (l. 58157–58176).

The jump branch fires when the target is above (`T.y < cy + 25`) or on a wall jump, with `+0x160` in 0…2. The landing
cooldown `+0xa6 = 2 + R(4)` is set in the shared tail (l. 58415–58419). All of it matches `AxGoblin.swift` and the arms
in `Walker.swift`.

**4.** Answered row by row in the table above. Every Statue, Smite, liquids and write-back site is where the dump
puts it; none is missing.

**5. Switch-off prediction.**

| Patch (scratch copy, reverted afterwards) | Result |
|---|---|
| None (main as built) | FrameGolden 7/0 + Phase2Golden 4/0 |
| Crawler `forClass` row only → `.inert` | still 11/0: today's values, the prediction fails |
| Plus the Crawler Setup's `handler` store through `forClass` | 7 failures, all in `Phase2GoldenTests`: swim `[67, 321]` / `c1dd428a3f146d77`; 600-frame `a8dda9cf3e448016` / 3114 / `28a48762cfff1b2b` / 1574122804 / 156 — exactly the old values |

Reverted; `cmp` against main shows both files identical.

**8.** The probe over every level's live records (scratch-only test) found the following Walker types on levels
10–62:

| Type | Levels |
|---|---|
| 1700 | 10, 11, 21, 22, 30, 31, 45, 50, 51, 52 |
| 1705 | 10, 11, 21, 22, 31, 51 |
| 1750 | 10, 11, 15, 22, 30, 31, 45, 62 |
| 1760 | 10, 11, 15, 21, 22, 30, 51 |

The tier values p3 seen are 0, 1, 3, 4, 5 and 6. A Roach is placed on level 21.

## Test counts (scratch copy, `swift test --filter`)

| Class | Total | Failed | Skipped | Test time | Wall time |
|---|---|---|---|---|---|
| `FerazelCoreTests.WalkerTests` | 15 | 0 | 0 | 9.87 s | 13.7 s |
| `FerazelCoreTests.CrawlerRoachTests` | 8 | 0 | 0 | 5.16 s | 6.6 s |
| `FrameGoldenTests` | 7 | 0 | 0 | 51.9 s | |
| `Phase2GoldenTests` | 4 | 0 | 0 | 61.3 s | |

The two golden classes ran together in about 115 s of wall time.

---

# Report C-bat

# Audit C: the unmerged Bat class (branch loop/42-20261031-162344, commit 005058f)

Verdict: the Bat code matches the decompile everywhere I re-derived it. The branch is safe to cherry-pick. The fix-round
plan (task BAf) needs three corrections before it runs:
- its "widen the marks to 0x743" item is wrong;
- six of the 40 "real survivors" can never happen, because of the class table;
- the switch-off check named in the brief does not switch the Bat off.

| Finding | keep / change / redo / missing | File:line | Why | The fix (one sentence) |
|---|---|---|---|---|
| The commit applies cleanly to main | keep | — | 005058f's parent is 07bc11d, which is main. `git merge-tree --write-tree main 005058f` gives tree 3a9a8b1 with no conflicts. | Cherry-pick as RC step 2 says. |
| BAf minor item (2), "widen the 0x73a… mark range to 0x743", is **wrong** | change (the plan) | `LevelRun.swift:1155`; plan `2026-11-04-ferazel-remainder.md` "three minor findings" (2) | The binary's class dispatch (M l. 1750–1753) sends types 0x73a–0x73e to the Bat class (`_DAT_1009ff14`) and types 0x73f–0x743 to the Background class (`_DAT_1009ff30`). `SpriteClassTable.swift:65–66` copies this. A 0x73f–0x743 sprite can never reach `.SetupBatSprite`, so the Setup's wider check is dead code. The existing 0x73a…0x73e range is right, and `testBatSetupBySubRange` already asserts 0x73f marks nothing. Widening would wrongly mark the Bat sheet for Background types (0x73f has its own Background single, M l. 61867). | Drop item (2) and its BootFaces assert. Keep 0x73a…0x73e and add a comment citing M l. 1750–1753. |
| Five survivors on the 0x743 upper bound are equivalent, not real | change (the plan) | `Bat.swift:132, :418, :435, :493, :495` | Same reason: no sprite of type 0x73f–0x743 runs Bat code. The Setup is reached only through the class table (SetupFaces, `BoxSprite.generate`), and no runtime retype lands in that range. | Remove these five rows from BAf's assert list and mark them equivalent (class table). |
| The brief's switch-off check (set `forClass` back to `.inert`) switches nothing off | change (the method) | `SpriteSlot.swift:619` | With that one patch, BootFacesTests passed 4/0 on the **new** values. `SetupFaces` dispatches on `SpriteClassTable.classify`, and `Bat.setup` sets `handler = .bat` itself, so the `forClass` row plays no part in a level load. Stubbing `Bat.handle` (early return) brings back L3 f30 `0xd4f7e113045d39a2` and f120 `0x5a2e3d4e64f7c1ee` (2 expected failures, measured). So run 42's own switch-off, which stubbed the Handle, holds. | Write the switch-off recipe as "stub the class Handle", not "flip the forClass row", in the plan and in FR's ◈ note. |
| `ProgrammedPath` silently accepts modes 10/11 | change | `Bat.swift:749–750, :758–779` | The Setup only zeroes `+0xf8`. The Handle does nothing for 10/11, where the dump counts `+0xf8` up, zeroes vx and vy, calls the radial updates and zeroes `+0x194` (M l. 39446–39466). Today only `SetupFaces:547`'s throw stops a mode-10/11 bat. | Do as BAf says: zero vx, vy and `+0x194` and count `+0xf8`, then fail loudly (precondition) for the radial calls until R5's task builds them. |
| `ProgrammedPath` drops the "no radius" flag **[⚑ run 43: it is a "no speed" flag — `.MakeRadial` gets p3 = 0 as its speed, the radius p2 stays]** | missing (for R5) | `Bat.swift:719–720` | For p1 110/111 the dump clears `bVar1`, so `.MakeRadial` gets radius 0 instead of p3 (M l. 39307–39309, 39352–39368). The Swift code subtracts 100 and forgets the flag. | Keep a `radial: Bool` (or store the raw p1) when the radial modes are added. |
| `ProgrammedPath` is filed inside `Bat.swift` | change (small) | `Bat.swift:706–781` | Three other classes call the same pair: Background p1<0 and the mace modes 1–2 (M l. 62072, 62343, 62976, 63143) and the Gremlin (69226, 69307). R5 needs one shared implementation, and its home should say so. | Move it to `World/Movers/ProgrammedPath.swift` unchanged during BAf (a file move only). |
| Path mode at +0xf0 has two storages (`pathMode` and `voicePitch`) | keep (watch) | `SpriteSlot.swift:144, :252` | This breaks the "one storage per offset" rule on purpose (plan BA). It is fine while Walkers and Frogs never run a path. A Background or Gremlin that uses both would have to pick one. | When the cannon, mace and Gremlin arms land, read only `pathMode` and note it in their cards. |
| Setup face pre-set for idle 0x6cc… bats | keep (uncertain) | `SetupFaces.swift:558`; `Bat.swift:105` | The dump's Setup leaves `+0xc0 = 0`, while the SetupFaces entry draws cell 0 (the Phase-1 picture). This matters only for a bat that never runs a Handle. Low confidence it is visible. | No change. Note it as the Phase-1 ◇ choice in the D44 as-built paragraph. |
| The spit and the Setup read records without a range check | keep | `Bat.swift:225–230` | Record 0x200 (crate) reads as zeros. The dump reads past the table, so this is a guess, but no shipped crate drops a Bat: the `.KillCrate` 0x6cc arm, M l. 61312, only seeds the drop. | Keep the [LOW] label. |
| The swarm block holds at most 20 members (0x54 bytes) | keep (note) | `Bat.swift:160–181` | A p2 above 20 overruns memory in the original. The Swift array grows instead. No shipped swarm goes above 12. | Add a one-line comment. |
| Leg 1 minor cites (68147, 68297, 68715) and the face-guard comment | keep (in BAf) | as BAf lists | Confirmed against the dump. | Apply as planned. |

## Re-derivations

**Q2: Setup sub-ranges (M l. 68108–68316).**

The common head: `+0x84/+0x86` 0, layer 0xb, the Handle, hit and tile callbacks, gravity 0, face 0, position from `+8/+6`, `+0x150 = −1`.

- **Types 0x6cc–0x6d5:** HP 500, rect (0xc,0xf,0x2b,0x2f), counted, set 0x6cc marked. 0x6ce is retyped to 0x6cd with `+0x188`, `+0x14c = 1`, `+0xb8 = 0x1000c` and `+0x154 = R(0x50)+0x32` (the one draw). Then 0x6cc gets `a6 = 0`; 0x6cd gets `+0x188`, `a6 = 1`, gravity 0 and the path; 0x6d1 gets `a6 = 1`. All end with `+0x158 = 0x1e`, `+0x15c = 0`, `+0xb0 = 7`.
- **Types 0x73a–0x743:** set 0x73a marked unconditionally, `+0x188 = 1`, HP 100, rect (0x10,0x1e,0x30,0x32). 0x73c is retyped to 0x73b as above; 0x73a gets `a6 = 0`; 0x73b gets `a6 = 1` and the path. Then `+0x158 = 0x1e` and `+0x15c = 0`. With p1 < 0: layer 8, `+0x160 = 1`, set 0x73b marked, not counted. Otherwise `+0x160 = 0` and counted. Finally `+0xb0 = 7`.
- **Type 0x74d (swarm):** set marked, x and y +0x40, a 0x54-byte block. Member type = p1 (0 → 0x74c), count = p2 (0 → 8), radius = p3 (0 → 0x4b) stored at `+0x154`. HP 100, no hit callback. Each member draws R(2r) for y first, then R(2r) for x, then its own Setup's R(7). Alive < 1 sets `+0xe9`. Rect ±r/2, rounded toward zero; counted.
- **Types 0x744–0x74c (insects):** rect (6,6,0x2a,0x26), set 0x744 marked, face cell 3 (`set+0x10`), HP 200, `b0 = 7`, `a6 = 3`, `+0x46 = 3`, `b8 = 0xb0004`, `+0x158 = 0x28`, `+0x15c = 0`, `+0x88 = 0`. The body is a separate sprite at layer −1 whose Handle is the body Handle; counted.
- **Tail:** the 24.8 position comes from `+8/+6`.

`Bat.setup` (`Bat.swift:96–220`) and `testBatSetupBySubRange` match every value and the draw order.

**Q3: chaser steering and waking (M l. 68519–68683; hit M l. 68955–68958).**

- **Steering:** awake (a6 > 0) and 0x6cc turns into 0x6d1. The bat faces the player. If it is more than 40 px off and moving away faster than 0x100, it brakes by 0x48.
- **Water:** in liquid, vy rises by −100 while above −800. Plain water fully under, or liquid kind > 0 and ≠ 3, with no invulnerability: invulnerability 0x13, HP −100, flash 0x11, sound 701 at volume 0x55.
- **Waking:** asleep (a6 < 1), |dx| < 0x9c and P.y − c.y < 200 and c.y + 0x20 < P.y: sound 608 (random pitch) and a6 = 0x14.
- **States:**
  - 7: turn one step toward d (+1 when d > h by less than 18), wrapping 0…35; when d equals h, go to 8.
  - 5: heading = d.
  - 6: the always-zero pair, then back to 7.
  - 8: if heading is within ±2 of d (also ±36), thrust `+0x158` unless gated: 0xb3 on the pair for 0x6cc–0x6d5, 0x4f for 0x73a–0x743, 0x1c1 on vx/vy for the others. Otherwise go to 6.
- **Hit wake:** a hurt with a6 < 2 sets a6 = 0x15.

All of these match `Bat.swift:310–339`, `steer` (:452–504) and `hit` (:654–675).

**Q4: programmed path.**

- **Setup:** mode = |p1|, and 100–199 subtract 100 (setting the "no radius" flag). Speed = p3, direction 1.
  - Mode 3: rect (7,0,0x46,0x1e), 0x19e = 0x50, gravity 0x15e, 0x13a = 0x2d, 0x138 = 0x3c, direction 0.
  - Mode 1: bounds start ± 8·p3 with + 256·p2 on y, vy = p3, vx = 0, 0x13a = 0.
  - Mode 2: the same on x, vx = p3, vy = 0.
  - Modes 10/11 with a record: direction 0, then `.MakeRadial` (and `.MakeRadiusSprites` only when the first argument ≠ −1; every one of the five callers passes −1).
- **Handle:**
  - Mode 2: direction 1 means reverse past the high bound, otherwise accelerate by p3>>4 up to p3. The other direction is the mirror image. Then `+0x194 = 0`.
  - Mode 1: the same on y.
  - Modes 10/11: direction < 0 counts up, otherwise set to 0; vx = vy = 0; `.UpdateRadialPos`, `.UpdateRadiusSprites`; `+0x194 = 0`.

The Swift code matches modes 1, 2 and 3. For R5 it lacks the 10/11 Handle body and the no-radius flag, and it sits in `Bat.swift`. Its signature (`inout SpriteSlot`, `Placement?`) already suits the Background and Gremlin callers. Leaving out `MakeRadiusSprites` matches every caller.

**Q5: leg 2's 40 survivors, judged.** Leg 2's own results file (`/tmp/batmut/results.txt`, 411 rows) lists 62 survivors: these 40 plus its 22 equivalents. I agree with all 22 equivalents. Of the 40:

*Real — pin them:*
- `:310` 0x73a and `:310` 0x744 (the 1850 bats and the insects never steer, wake or take water damage).
- `:664` count, speed, spread and kind (blood amount, and the random draws that follow).
- `:693`/`:694` the push of vx>>3 and vy>>3, invulnerability 2, flash 8.
- `:687` the player-shot check (any touching sprite would hurt a member).
- `:696` blood count 0x28.
- `:465`, `:466`, `:468` the heading wrap.
- `:150` thrust 0x1e.
- `:302`, `:304`, `:313` facing at exact level. One frame, but it sets the direction of the spitting bat's shot.
- `:438` surface line `<` (with `<=`, the 1850 family's vy is zeroed every frame on land, killing vertical knock-back).
- `:588` the member target x+12.
- `:192` insect face cell 3 (an idle insect keeps it; level 21 has five).
- `:554` particle delay 0 (visible, cosmetic).
- `:668` volume 0x100 (audible, cosmetic).
- `:422` insect clamp at 8 (reachable when a hit lands at a6 = 1; one frame, cosmetic).

*Real only for unplaced types or boundaries (pin cheaply, low value):*
- `:419` 0x745 (unplaced).
- `:413` 0x6d5 (types 0x6d2–0x6d5 unplaced).
- `:695` the HP > 0 boundary (HP exactly 1 is unlikely with shipped shot damages).
- `:602` |vy| < 0x578 (exactly ±0x577 only).
- `:187` negative radius (no shipped swarm has one).
- `BoxSprite:1188` crate record 0x200 (no crate drops a Bat).

*Equivalent now:*
- The five 0x743 rows (class table, see the table above).
- `:517` dying face 0: the animation re-faces every placed type in the same frame. It matters only for 0x746–0x74c, which are unplaced.
- `:774` `+0x194 = 0`: nobody sets or reads it for a Bat. It becomes real when a ridden Background or platform reuses the path, so pin it anyway for R5.
- `:749`/`:750` modes 10/11: refused at level load, so unreachable now. Pin them together with the Handle change.

Net: about 28 real or cheap pins. The five 0x743 rows come out.

**Q8: cache sets.** All five `.InitBatSprite` sets are registered in order (0x6cc 11, 0x744 9, 0x74d 8, 0x73a 12, 0x73b 12). The marks cover:
- 0x6cc–0x6d5 → 0x6cc;
- 0x73a–0x73e → 0x73a, plus 0x73b when p1 < 0;
- 0x74d → 0x74d;
- 0x744–0x74c → 0x744.

That is complete. Leg 2's 0x73a…0x743 finding is a false positive (see the table).

## Counts measured (scratch copy of 005058f, HectorKit 35a85ba)

| Run | Result |
|---|---|
| BatTests | 9 / 0 failures |
| FrameGoldenTests | 7 / 0 (L1 `9db8f32f7e3d88b4` / `b80b0efd384ffdb9` in the file, unchanged from main) |
| Phase2GoldenTests | 4 / 0 (swim `3e99f74fa10e87e2`, 600-frame `cce4b0446e2a48e`, L2 `565e867a02736c18` / `b310ef334de49c00`, jump `deb577ecdeb64c58`; no golden file touched by the commit) |
| BootFacesTests with `forClass` → `.inert` | 4 / 0 (the new values stay, so this is not a switch-off) |
| BootFacesTests with `Bat.handle` stubbed | 4 / 2 failures; L3 f30 = `0xd4f7e113045d39a2`, f120 = `0x5a2e3d4e64f7c1ee` (run 42's claim confirmed); patch reverted, sources diff-clean |

---

# Report D-gates

# Audit D — the loop's own gates and tools, against what Phase 6 will throw at them

Read at main 07bc11d (plus the unmerged branch 005058f where noted). Nothing was built or launched. The numbers come from the seat's whole-suite log, `fz-core.log`.

| Finding | keep / change / redo / missing | File:line | Why | The fix (one sentence) |
|---|---|---|---|---|
| The list of built levels is a closed range (`1...4`), but the levels after 5 are 10, 11, 15, 18 and so on | **redo** (high confidence, Critical for Phase 6) | `Ferazel/Core/Sources/FerazelCore/Front/BuiltLevels.swift:9` | A range can't skip numbers. `1...10` would include levels 6–9, which have no level data, so the draw-mode audit (`BuiltLevels.range.map { audit }`), the sweep and the bot would all fail on level 6. | Make it a sorted list of level numbers and check membership with `contains`, in the task before the first Phase 6 level opens. |
| The bot's script reads the level list from the source with `sed` and expects `static let range = A...B`, then counts with `seq` | change (high, Important) | `tools/ferazel-random-play.sh:62`, `:76` | Once the list is no longer a range, the script exits 2 ("cannot read BuiltLevels.range"), or with `seq` it fills in the missing numbers. The visit sweep has no such problem: it reads the list through Swift (`VisitSweepPlan.swift:18`). | Have the script read the list in the same form the Swift change uses (a `[ … ]` literal or a plain-text file), and test the parse. |
| The draw-mode audit has no header check for the horizon strip (header 0x2716), although it has one for the fire backdrop, the backdrop ripple and OmniPx | **missing** (high, Important) | `Ferazel/Core/Tests/FerazelRenderTests/DrawModeAuditTests.swift:1076–1079` | Nothing ever puts the strip sprites (`PxSprites`, draw mode 0x80000) into the sprite table, so level 10 can open with no strip and every check passes. The strip simply isn't there. Only when a task writes that mode into a sprite does the audit's source scan ask for a row, and the row would then be refused. | Add `XCTAssertEqual(L.header.stripPict, 0, …)` beside the other three until the horizon-strip engine task lands. |
| OmniPx rain and interlace (modes 1 and 6) are not "refused at level open" today | change (high, Important) | spec §3.2; `DrawModeAuditTests.swift:1079` | Nothing in Core or the renderer reads `omniPxMode`. Level 15 or 70 would open and draw with no rain and no error. Only the audit's header check (`== 0`) catches it. The sweep and the bot would see nothing. The level-open refusal exists only in OX's plan card. | Correct the spec row to say "caught by the audit's header check (line 1079) until OX adds the level-open throw". OX must narrow line 1079 to "0, 2, 4 or 5", not delete it. |
| 18 `precondition` traps in the renderer sit outside the audit's census of refusals, which counts only `throw` statements | **missing** (medium-high, Important) | `TileGridRenderer.swift:286` (water table 6 or above, i.e. tile kinds 206–209), `LightRenderer.swift:91`, `:252`, `:298`, `:398` (darkness, light index and overlay "outside the census"), and 13 others | A later level that hits one of these doesn't produce a failure row: it kills the process. That takes down the whole FerazelRenderTests bundle in `swift test`, and every remaining test in Proof B is marked "crashed". The sweep and the bot do record it as a "trap" row and resume, so they catch it, but the audit doesn't. | Either add the census-guard preconditions to the audit's refusal table, or turn the ones a level's data can reach into named `Refusal` throws. |
| Level loops written as a literal `1...4` and assertions that the range equals `1...4` | change (high, Minor) | `FaceTests.swift:595–602` (the `keys[n]!` force-unwrap would trap if the loop were widened), `BootFacesTests.swift:281` (hot-rect golden), `GameFlowGameTests.swift:249`, `LevelFourTests.swift:157` | These don't follow the built-level list. LV5's card names FaceTests and GameFlowGameTests but not BootFacesTests:281 or LevelFourTests:157. | Put all four on the "level N enterable" checklist (rule R4). |
| The spec's suite-split card would split nothing | change (high, Important) | `Ferazel/Core/Package.swift:37`, `:43`; the log's bundle lines 189, 526, 531, 1588 | `FerazelRenderTests` is already its own test target. The log shows two bundles: Render with 128 tests in 716 s, and Core rules with 432 tests in 61 s. The ten slowest classes are all render classes. | Rewrite the card: split the heavy render classes (the audit, the level sweep, boot faces, the two golden classes, census) into a third target, or run them only at wave ends by `--filter`. |
| The Windows smoke's three reference hashes exist in two code copies and nothing checks that they agree | change (high, Minor) | `tools/windows/smoke-ferazel-win.sh:63–67`; `WinReferenceFramesTests.swift:39`, `:43`, `:47`; also `tools/windows/README.md:307`, `:314` | A task that moves a reference must edit two code files plus the README. The test writes the hashes with underscores (`0xae2b_1ee0_…`), so a grep for the hash misses the test copy. | Have the test read `menu_fnv`, `newgame_fnv` and `text_fnv` from the script, or move both into one data file. |
| Reconcile step 4 doesn't say what to do when HectorKit is clean but at a later commit; G1 expects 35a85ba exactly | change (high, Important) | `docs/NEXT.md:81–83`, `:355`; plan `:107`, `:128`, `:1396`, `:1630` | With HectorKit at ef2c341, G1 fails on every task. Step 4 accepts "a later local main recorded in STATE", but STATE still records 35a85ba, and no STOP or record action is written. | Record the ruling (Q-B), and rewrite G1 as "clean; contains 35a85ba; SHA and floor recorded in STATE". |
| HectorKit ef2c341 changes only the Mac/iPad shell (three files plus tests) | keep (high) | `git show --stat ef2c341`; Ferazel's Mac controller at `FerazelController.swift:114` | Ferazel uses `.integerFit`, whose code path is unchanged. Nothing changed in the SDL layer (so no effect on Windows or the smoke references), nor in HectorResources, HectorInput, HectorGraphics or HectorAudio. The HectorKit floor reads 370 in `tools/check-zero-skip.sh:8` and in `docs/STATE.md:42`. | None. Minor note: HectorKit's own STATE (lines 1 and 40) still says "branch castles-k1 … awaiting review, then merge" although the commit is on main. |
| Proof B and a third opt-in test | change (high, Minor) | `tools/windows/proof-b-ferazel.sh:21–22` (switches cleared), `:126–127` (the opt-in list) | Proof B accepts exactly one Wine-only skip plus two opt-in skips. A third opt-in test fails as "skipped but not on the … lists". Its environment switch must also go on the clearing line (`unset`), or under Wine it runs whenever the caller has the switch set. | Keep one opt-in table that both the list and the clearing line read from, and add "a new opt-in test edits Proof B" to Invariant 8's list. |
| A crash in Proof B costs the rest of the run | change (medium, Minor) | `proof-b-ferazel.sh:96`, `:139` | The suite runs in one CrossOver process, so a trap marks every later test "crashed". The script's header documents `--class` (`:11`) and the verdict prints the hint, but it doesn't name the class of the first crashed test. | Print the first "crashed" test's class next to the hint. |
| `later:` notes whose owner has already merged | change (high, Minor) | `GroundCeilingEffects.swift:69` (WK1, CR), `EnemyCommon.swift:95` (CR), `Camera.swift:46` and `BackgroundSprite.swift:498` (SH, Phase 4), `StatueSprite.swift:5` ("one caller", but Walker, Crawler and Roach now call it) | Stale owners mislead the phase-end grep for stubs. | Re-label them to the real owner, or remove them. |
| "later: Phase 5" on the boss grab, which belongs to the Goblin Chief and Xichra (Phase 6) | change (high, Minor) | `PlayerState.swift:196`, `PlayerStates.swift:371` | These are counted in the 19 "later: Phase 5" notes, but no Phase 5 task owns them. | Re-label them "Phase 6". |
| The plan cites the sweep's summary line at `:75` | change (high, Minor) | plan's Verification model, near `:196`; actual line `tools/ferazel-visit-sweep.sh:91` | The citation is stale. | Fix the citation. |
| G2 counts skipped tests but not their names | change (medium, Minor) | `docs/NEXT.md:357` | "2" would pass with the wrong two tests skipped. | Grep the two opt-in names. |
| The loop's watchdog ends a session after 45 silent minutes, and `config.sh` has no "busy" hook | change (low confidence, Minor) | `fable-kit/looper/looper.sh:23`, `:111`; `.looper/config.sh` | As the suite grows towards ~860 tests, a seat silently waiting on a whole-suite run could be killed. | Add a `busy()` hook that reports `swift-test` processes. |
| Rotated or scaled sparkle, and the mirrored gauge | keep (high) | `DrawModeAuditTests.swift:1370` (modes with no rotation or scale table, on any sprite that rotates or scales), `:1449` (gauge never mirrored) | These checks run over every writer row of the table, whatever the level. | None. |
| Fire backdrop and backdrop ripple | keep (high) | `ParallaxBlitter.swift:125–126`; audit `:1077–1078`, refusal rows `:1200`, `:1202` | Caught by the audit's header checks, and they throw on a level's first frame, so the sweep and the bot catch them too. | None. |
| The ladder (BA 569, FR 577, BL 584, GF 591, DL 596, GY 603, PI 607, OX 612, LV5 618) | keep (high) | plan `:1114–:1307` | 560 plus 9, 8, 7, 7, 5, 7, 4, 5, 6 gives exactly those totals. Each card's "Tests (N)" equals the test names it lists, and BA's commit adds 9. | Minor: the A5 gate line (`:1333`) still says 617 / 614, not +1 (618 / 615). |

## Re-derivations

**Q1 — which check catches each "refused" feature when its level opens.**

| feature | what catches it today |
|---|---|
| Horizon strip (draw mode 8) | Nothing until the strip sprites are actually set up; then the audit's writer scan, then its draw check. |
| OmniPx rain (1) and interlace (6) | The audit's header check only (line 1079); the game itself draws without them and doesn't quit. |
| Fire backdrop | The audit (line 1077), the sweep and the bot (it throws on the first frame). |
| Water kinds 206–209 | Sprites: the audit's liquid rows (refused at `SpriteBlitter.swift:574`). Tiles: a trap (`TileGridRenderer.swift:286`), which the audit misses but the sweep and the bot record as a "trap" row. |
| Rotated or scaled sparkle | The audit (line 1370). |
| Mirrored gauge | The audit (line 1449). |

**Q2 — can the sweep and the bot take a level 10 or above?** Not today. Both enumerate `Array(BuiltLevels.range)`; the Windows plan files are symlinks to Core's. The bot's script also parses the range with `sed`. A "level N enterable" task must touch:
- `BuiltLevels.swift:9`
- the bot script's lines 62 and 76, on the first change of shape
- the level-load picture cache in `LevelRun.swift` (near lines 1059 and 1137)
- `FaceTests.swift:595–602`, `BootFacesTests.swift:281`, `GameFlowGameTests.swift:249` and `LevelFourTests.swift:157`
- a `Level<N>Tests` file

**Q3 — the HectorKit drift.** Under the current text, reconcile step 4 has no action to take, and G1 fails on every task. Nothing in Ferazel's tests, the smoke references or the Windows build can change under it, because the SDL layer is untouched. The floor reads 370 at ef2c341.

**Q8 — the "later: Phase 5" notes.** 19, confirmed at 07bc11d; 17 on the BA branch, which removes the two bat notes in `SetupFaces.swift`. The remaining owners:

| owner | where |
|---|---|
| GY (geysers) | `BoxSprite.swift:142`, `:421`, `:1191`; `HitPlayerSprite.swift:189`, `:228`, `:1168` |
| PI (pipes) | `BoxSprite.swift:142`, `:421` |
| BL (Blob) | `SetupFaces.swift:567`, `BoxSprite.swift:1167` |
| FR (Frog) | `SetupFaces.swift:584` |
| LV5 | `LevelRun.swift:508` |
| generic "Phase 5–6" | `SetupFaces.swift:646`, `LevelRun.swift:1059`, `:1137`, `FerazelSession.swift:1122`, `StatueSprite.swift:5` |
| wrongly "Phase 5" (Phase 6 bosses) | `PlayerState.swift:196`, `PlayerStates.swift:371` |

GF, DL and OX own no specific note; they appear only in the generic list. None of the 19 names a merged task, but five other `later:` notes elsewhere do: WK1, CR and SH (rows above).

## Counts measured (from `fz-core.log`, main 07bc11d)

| check | result |
|---|---|
| Test cases | 560 |
| Failed or skipped | 2 (both opt-in skips), 0 failed |
| FerazelRenderTests bundle | 128 tests, 716 s |
| FerazelCoreTests bundle | 432 tests, 61 s |

Ten slowest classes (all in FerazelRenderTests):

| class | seconds |
|---|---|
| DrawModeAuditTests | 147.3 |
| LevelSweepTests | 85.2 |
| BootFacesTests | 64.5 |
| Phase2GoldenTests | 61.5 |
| CensusTests | 57.2 |
| FrameGoldenTests | 52.0 |
| ColorSearchTests | 44.2 |
| DrawEffectTests | 30.6 |
| FaceTests | 29.2 |
| ConversationRenderTests | 26.2 |

Moving FerazelRenderTests to its own target would separate none of these: it is already a separate target.

---

# Report E-frontend

# Audit E — the front end, the map, the saves and level opening against all 24 levels

Main 07bc11d, read-only. Scratch build: `git archive` of `Ferazel/Core` + HectorKit 35a85ba into the scratchpad `E/` folder;
data from the main checkout's `Resources/Ferazel`. Header values below were read straight from `Mlvl` in the world file.

**Short answer:** the front end is driven by the data almost everywhere. The map walks, draws and unlocks all 24 nodes
from `Mmap 200`. Chapter cards, stage-complete stats and the save block work for any level number. Opening a level
needs one switch (`BuiltLevels.range`), the picture-cache marks of each new class, and test retargets. Three things a
Phase 6 plan has to name: the boss-music rule (start of level and inside the loop), `.Victory`, and what a player sees
when an unbuilt level is entered.

| Finding | keep / change / redo / missing | File:line | Why | The fix (one sentence) |
|---|---|---|---|---|
| `BuiltLevels.range = 1...4` is the one intended switch; New Game, the map and Continue all read it | keep | `Front/BuiltLevels.swift:9` | All three gates read the same constant; nothing else in the front end is keyed on 1–4 | Widen it per level-opening task. At Phase 6 end, delete the gate rather than writing `1...70`. |
| A closed range cannot name the 24 real levels (no level file for 6–9, 12–14, …, 63–66, 68–69) | change (low) | `BuiltLevels.swift:9`, `NewGame.swift:66`, `Shared/FerazelDriver.swift:44` | `1...70` makes the hidden `FerazelLevel` switch pass levels 6, 7 … and then hit the original's load error instead of clamping to level 1. The map never offers those levels, so only the switch is affected. | Make it a set of built level ids, or have the switch check that the level file exists. |
| An unbuilt level entered by mistake shows the original's "could not be loaded from the world file" error | change (med) | `Camera/Camera.swift:53–54`, `Sprites/SetupFaces.swift` throws, `GameFlow.swift:555–558`, `NewGame.swift:155–160` | Widening the range before every class of a level is built does not crash, but it reports the wrong cause. Measured: with `1...70`, entering level 5 gives that text. | Keep the safety refusals. A level task widens the range only once its census sets up every record. |
| Not-built report text "(Phases 5-6)" | change | `BuiltLevels.swift:11–13` | LV5 plans "(Phase 6)" | As planned in LV5. |
| Invented ◇ gates: New Game clamp, map refusal, Continue refusal of unbuilt-level saves (e9fa8b0) | keep until Phase 6 end, then remove | `NewGame.swift:66`, `:275–284`; `ContinueGame.swift:134–141` | The original has none of these. Each is a single `contains` test on the range, so widening the range moves all three together. | At Phase 6 end delete all three and the report text. Continue's level > 0x4f "demo" refusal is the original's and stays. |
| Test pins that must move with the range | change (b) | `GameFlowGameTests.swift:247–260`, `:458–487`, `:691–699`; `LevelFourTests.swift:7–8`, `:156–181`, `:185–199`; `LevelThreeTests.swift:8`, `:390`; `BootFacesTests.swift:281` (`for level in 1...4`); `FaceTests.swift:596–602` (a per-level drops/keys table for 1–4); `FerazelSettingsTests.swift:17` and `FerazelDriver.swift:12,40` (comments) | Measured below (question 6) | Each level task retargets these to the next unbuilt node. Re-derive `FaceTests`' drops/keys table for each new level. |
| Tests that follow `BuiltLevels.range` on their own | keep (watch cost) | `VisitSweepPlan.swift:18`, `RandomPlayPlan.swift:120`, `BootFacesTests.swift:173,234`, `DrawModeAuditTests.swift:798,1548`, `LevelSweepTests.swift:60–80` | Correct design. But they grow from 4 to 24 levels, and the sweep is already a heavy run (Ben's RAM rule). | The Phase 6 plan budgets the sweep's time and memory at 24 levels. |
| Map graph: 128 slots, 24 existing nodes, boss face on nodes 5, 18, 25, 55, 62; the walk, draw and unlock are all data-driven | keep | `World/WorldMap.swift:38–50`; `WorldMapRun.swift:662–689`, `:744–765`, `:768–790`, `:838–857` | Matches `.MakeNodeSprites` (M l. 66696–66739) and the unlock test `G+0x23e+2·level` (M l. 67277ff, `sVar14 < 7` loops, l. 119/139 of the routine). Boss faces come from the node's `+0x116` → PICT 8002. | None. |
| Node ≠ level on two nodes (node 60 → level 62, node 62 → level 67) | keep | `GameFlow.swift`, `NewGame.swift:182` (`mapNodeLevel`), `:279` | Return to the map uses `FindCurrNode(hdr+0x26c4)`, so the not-built re-entry for level 62 finds node 60 | None. A Phase 6 test should walk 40 → 60 → 62 (levels 62/67) once. |
| Chapter cards worked out from any number: PICT `n·10+0x11f8`, clut `n+0x118`, gate `hdr+0x273c ≠ 0 ∧ G+0x176+2L == 0` | keep | `StageScreens.swift:237–248`, `LevelRun.swift:513–519` | All 7 cards and cluts exist (4610–4670, 281–287). Chapters in the data: levels 1→1, 10→2, 40→3, 50→4, 22→5, 30→6, 62→7 | None. |
| Stage-complete stats: `.CalcPercent` / `.FillPercent` read `achieved[k][L]` / `totals[k][L]` for L < 100 | keep | `StageScreens.swift:59`, `:183–199`; `LevelRun.swift:604–611` | No level table | None. The bank's note that levels 10, 11, 21, 62 can never reach 100 % enemies follows from swarm/Wraith counting (class tasks). |
| Save block / G image: 100 snapshot slots × 511, every per-level array sized to 100 | keep | `Saves/SaveBlock.swift:13–16`, `:126–150` | `SaveBlockTests` round-trip `hasSnapshot[99]`, `achieved[4][99]`, the level-7 snapshot | Optional: add one round-trip on a real later level (e.g. 62) through `savePointSave` and `restoreSnapshot`. |
| Per-class save write-back flags (`+0x188…+0x18b`, `+0xea`) | keep (per class) | class Setups | Per class, not per level. Each class task owns them. | None here. |
| Picture cache (`CachedFaces`): per-class marks plus a subset copy of the original's registration lists. The load-bar count is computed. | change (per class) | `LevelRun.swift:1062–1082` (`sets`), `:1092–1114` (`singles`), `:1138–1162` (`marks`), `:1173–1186` (`handleSets`) | No per-level table. But the lists hold only the records levels 1–4 mark, in registration order (M l. 106–145). Each new class must insert its records at the right place, or the bar steps and counts drift. | Each class task adds its `marks` case and its records at their registration index. Better: transcribe the whole `.Init*Sprite` registration list once, so only `marks` grows. |
| Boss music at level start is a constant `noBossAlive = false` | redo (LV5 / Phase 6) | `LevelRun.swift:504–509` | The dump picks track 30 when `hdr+0x2724 ≠ 0 ∧ fed0 ≠ 0` (M l. 5218–5220). `fed0` is set to 1 in `.SetupLevelSprites` (M l. 2002–2019) and cleared only by a boss Setup that runs (Warrior only when p4 ≠ 0). So a revisit after the boss is dead, or a Warrior placed with p4 = 0, starts on 30 in the original but on the header track here. | `BossArena.noBossAlive` read live, as LV5 plans. |
| Boss music inside the loop (fade out, then 30) is not built | missing (Phase 6) | `LevelRun.swift:684–687` (comment only) | M l. 5266–5274: `hdr 0x2724 ≠ 0 ∧ fed0 ∧ track ≠ 0x1e ∧ prefs+0xc ∧ music-on byte` → volume `fd6c` < 1 ? `SetAIFFMusic(30)` + `FadeAIFFMusicAsync(1, 60)` : `FadeAIFFMusicAsync(0, 60)` | Build it with the first boss Kill (Phase 6), in the iteration-end slot where `handleAsyncFade` already runs. |
| Stale comment "levels 1–2: 0" | change (low) | `LevelRun.swift:507` | Levels 1–4 have 0. Levels 5, 18, 25, 55 have −1444, −1400, 592, 16000. Level 67 has 0. | Fix with LV5. |
| `.Victory` not built: a completed level always goes to the map | missing (Phase 6) | `NewGame.swift:175–181`; the Continue loop shares `levelEnded` | `*_DAT_1009ffc4` is set by `.HandleXichraSprite` (M l. 77190) and the debug keys (47152). `.NewGame`/`.ContinueGame` test it (M l. 5737, 6697). The end-of-game resources (PICT 4600–4607, 11 rows marked "end of game" in the gap ledger) are present but unused. | A victory flow state in `GameFlow`, as spec §2 says, with `levelEnded` checking the flag before `openMap`. |
| `WorldMapRun.levelNames` covers STR# 1000 indices < 100 | keep | `WorldMapRun.swift` | Covers 70 | None. |

## Re-derivations

**Unlock and movement (Q2).** `.MakeNodeSprites` (M l. 66716–66737) walks all 128 slots: a slot exists if byte `+0` ≠ 0;
its sprite is drawn if `G+0x23e + 2·node.level` ≠ 0, with face `+0x116`; each of the 7 links > 0 whose target's level is
unlocked is drawn. `.CheckPlayerNodeMovement` uses the same unlock test on the target (M l. 67395/67415). `.ShowWorldMap`
unlocks `node[node[cur].links[exit]].level` for exit1/exit2 ≥ 0. The port matches line for line and holds no node or
level list. The data has 24 nodes, and `+0x116 == 1` exactly on nodes 5, 18, 25, 55, 62.

**Boss music (Q7).** M l. 5218–5221: `if (hdr[0x2724] ≠ 0 && *fed0) hdr[0x284a] = 0x1e; SetAIFFMusic(hdr[0x284a])`.
`OpenDefaultWorldLevel` detaches a fresh copy of the level each time (M l. 41551–41554), and only `.GameLoop` reads
0x284a, so the header write does not carry over. On a first visit to 18/25/55 the boss Setup clears `fed0` (Chief
M l. 75088, Wizard 75647, Demon 74434) → the header track (23). The current constant gives that same answer by
accident. It is wrong on a revisit with the boss dead (no Setup, `fed0` stays 1 → 30) [MED: depends on the Kill's record
write-back, Phase 6]. Level 67 has `0x2724` = 0 → always track 28: right. The in-loop switch to 30 (M l. 5266–5274) is
absent, but nothing can trigger it before a boss can be killed.

**Chapter cards (Q3).** `.GameLoop` M l. 5223–5227 → `.ChapterScreen(hdr+0x273c)`. The port works out both ids from the
number. Every chapter card the data asks for exists. None of the 26 "later levels" resource rows in the gap ledger is a
front-end resource. The front end's only missing resources are the end-of-game set (4600–4607), for `.Victory`.

## Measured

| Run | Total | Failed | Skipped |
|---|---|---|---|
| WorldMapRunTests | 8 | 0 | 0 |
| StageScreenTests | 5 | 0 | 0 |
| SaveBlockTests | 6 | 0 | 0 |
| GameFlowGameTests (baseline) | 9 | 0 | 0 |
| LevelFourTests (baseline) | 3 | 0 | 0 |
| GameFlowGameTests, range `1...70` | 9 | 3 tests (10 assertions) | 0 |
| LevelFourTests, range `1...70` | 3 | 2 tests (9 assertions) | 0 |

**Prediction (written before the run):** GameFlowGameTests would fail testNewGameStartsLevel1, testLevel1ToMapToLevel2 and
testContinueRefusals; LevelFourTests would fail testBuiltLevelsFour and testStartLevelSwitch. The cause predicted: the
range pins, plus level 5 now being entered. The camera refuses its arena bound (`hdr+0x2724` = −1444), so the flow
reports the original's "level could not be loaded from the world file!" error instead of the not-built text, and the
start-level switch 5 no longer clamps to 1.

**Actual:** exactly those 5 tests, for exactly that reason. Every failing assertion either reads the load-error text,
sees level 5 where level 1 was expected (`prepared` = [5]), or times out waiting for the not-built dialog. The scratch
copy was reverted afterwards.
