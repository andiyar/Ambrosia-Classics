# Ferazel's Wand — port gap ledger (2026-10-30)

> What the original has or does that the port does not (yet), found by inventory rather than by testers. Built on
> branch `gap-ledger` from main 2d054d0 (after the four fixes of 2026-10-29: teleporter sparkle 0fd056e, teleport re-seat
> 78e81c3, light PICT 806 + rope faces 48a0620, every boot face b535527). Read-only analysis: no game code changed, the
> game was never launched. Evidence tables live in `docs/ferazel/gap-ledger/`; re-run recipes are in §5.

## Summary (plain English)

**Headline: after yesterday's four fixes, the inventory found nothing left in levels 1–4, the front end, the world map
or the stage screens that ends the game.** Every way the port refuses to draw something was checked against what the
game can actually ask it to draw in those levels, and none of them can be reached today. Every picture, palette, sound,
level file and conversation the original asks for in that scope, the port asks for too. The rest of the missing work is
the enemies (Phase 5) and the bosses (Phase 6), as planned.

What is left is small. The ranked list below is what a player could still run into:

| # | What the player does | What happens | Original routine | Fix size | Confidence |
|---|---|---|---|---|---|
| 1 | Opens a saved game the **original** game made at level 5 or later (Continue, File ▸ Restore, Finder, Windows command line) | Usually "the level could not be loaded", then back to the menu, instead of the planned "level not built yet" message. If a later level's objects all happen to set up, the level could start with some pictures missing, and the first draw of one **would quit the game**. | `.ContinueGame @ 1000d004` | S: the built-levels check New Game already makes (`NewGame.swift:275`) is missing from `ContinueGame.swift:121` | MED |
| 2 | Charges the level-1 teleporter urn, or jumps through a passage | On the frames where the camera and the redrawn screen disagree, the sparkle is drawn from a slightly different run of random numbers than the original. The sparkle looks different, and the game's shared random numbers can drift after it. Not a quit. | `.BlitEncFaceDiffuse @ 10029988` in `.WrapDrawSprites @ 100144c8` | S (QUESTIONS Q15 follow-up 1) | MED |
| 3 | Plays with nothing in the inventory | The selected-item box stays empty. The original reads an unused part of its game state there, so it may show an item-0 or garbage icon. Needs a look at the Let's Play or the Mac OS 9 VM. | `.UpdateItemStat @ 10008f90` | S | LOW |
| 4 | Lots of sounds at once (all 16 voices busy) | The port doesn't model a new sound pushing out an old one, so "is this sound still playing?" can be wrong for one tick. Rare, hard to notice. (Already a known deviation.) | Sound Tool voice table | S | MED |

**Ruled deviations (counted as reachable, but already decided — no fix wanted unless Ben says so):** the hidden debug key
chord ⌘⇧⌥;0 does nothing (ruled out of scope); Windows has no menu bar, so Apple ▸ About (the Credits from the pause)
can't be reached there — the main menu's Credits still works (D21); the Options system-volume slider is stored but not
applied (D35 known deviation 8).

**Not a gap, but unmeasured:** the rule the port uses to shrink a picture (stage screens, map, light 806) has never been
compared with a real capture. It can't quit the game; at worst a few pixels differ. Settle it from the Let's Play or the
VM (Q15 reviewer item).

**Visible today, deliberately left for Phase 5** (worth naming on gate cards so testers don't report them):
- Enemies in all four levels stand still in their first picture and can't hurt or be hurt (Walker, Crawler, Roach, Bat,
  Blob, Frog).
- The boulder spouts on level 4 never throw boulders.
- No blue-green screen tint underwater.

**Watch list for Phases 5–6 — these WOULD quit the game the day their level or object is built, unless built first:**
- Level 5 (the Warrior) cannot open until the OmniPx backdrop overlay is built (also levels 15, 25, 70).
- Level 10's horizon strip uses a draw mode (8) the port refuses.
- The fire backdrop (levels 52, 55), the rippling backdrop (levels 11, 18), water kinds 206–209.
- A sprite lit by nearby lights (boulder, raft, mace) sitting on the brightest light in a completely dark spot; only level
  4 has completely dark spots today, and it has no such sprite.
- Rotated or scaled teleporter sparkle, and a mirrored springboard gauge: still refused, unreachable with shipped data.
The standing phase-end check (Q15 follow-up 2: audit every draw mode Core writes against what the renderer draws, in
every level of the phase) is the guard for all of these.

## Counts

| side | rows | class (a) future phase | (b) faithful to the original | (c) reachable gap | (d) unreachable with shipped data | (n) noise / not a gap | other |
|---|---:|---:|---:|---:|---:|---:|---|
| Port markers (§2) | 678 + 1 found outside a marker | 56 | 50 | 7 (4 real + 3 ruled deviations; incl. the continue-save gap) | 176 | 389 | 1 unmeasured |
| Draw audit (§2.1) | 25 inputs | — | — | 1 (sparkle drift) | 7 | 17 | — |
| Data (§1) | 1,187 game resources + 28 music tracks (+79 Finder/system, out of scope) | 172 (later levels, enemy/boss sheets, victory) | 11 ids asked for but absent from the files | 0 | 308 never asked for by the original | rest used (≈ 735) | — |
| Original routines (§3) | 1,236 | 151 not built (all Phase 5, Phase 6, or a later-level feature) | — | 0 | 10 dead | 498 out of scope | 501 built, 55 done under another name, 21 partial |

## 1. Data side — every resource × does the port ask for it

Method (both halves agree):
- **Static, original side** (`gap-ledger/resources-classified.tsv`, one row per resource): every constant passed to the
  original's loaders (515 sites), every computed id read from its loop (menu buttons 0x1324+n, death buttons, wand glow,
  chapter card n·10+0x11f8 with clut n+0x118, the Init Player/Bonus/Crawler/Box/Background loops, the Init Sounds
  arrays), tilesets/cluts/music/parallax from all 24 level headers, dialog picture items, conversation portraits. Reach
  from `placements-1-4.tsv` / `placements-all.tsv`, conversation placements and the OmniPx mode.
- **Dynamic, port side** (`gap-ledger/resources-joined.tsv`): `tools/ferazel/gap-trace.sh` ran the whole Ferazel/Core
  suite against a traced copy of HectorKit and logged every lookup with its call stack (20,056 distinct lookups).
  `trace=game` means the lookup came through the game's own code (GameFlow, LevelRun, the session, the frame/map/death
  renderers, the boot face list…); `test` means only a test called a loader directly.

| type | in files | port asks (game path) | reached in scope but not asked | future phase | never asked by the original |
|---|---:|---:|---:|---:|---:|
| PICT | 770 (+10 absent ids) | 314 traced game path; 477 static | 0 | 125 | 178 |
| clut | 79 | 15 traced; 52 static | 0 | 3 | 24 |
| snd | 172 (+1 absent) | all 172 (the app decodes every sound at start) | 0 | 0 | 25 |
| music | 28 tracks | 22 | 0 | 1 (victory, track 29) | 5 (7, 11, 14, 19, 20) |
| Mlvl / Mcnv | 24 / 29 | 4 / 5 (levels 1–4) | 0 | 20 / 23 | 0 / 1 |
| dialogs, menus, controls | DLOG 20, DITL 30, CNTL 7, MENU 9, MBAR 1, dctb 14 | Options, confirm, report, credits, menus | 0 (the 38 in-scope dialog rows are App/Windows-only paths the suite doesn't run; static check says asked) | — | the rest (CD request, resolution switch, warp/debug, Navigation-Services replaced by native panels — D35) |
| Mmap, Mwld, STR#, WIND | 1, 1, 4, 1 | all | 0 | — | STR# 2 |
| cicn, TEXT, Tune, Msct, wctb, ALRT | 19, 1, 1, 1, 1, 2 | none | 0 | — | all (no code site in the original either) |

**Asked for by the original but not in any file (class b, the port matches):** held-item faces 751–776 except 756, 768,
771 (750 exists); crawler faces 1500–1503; signs 2908–2909; bonus 3109; the item-0 face 3200; snd 199 (main-menu easter
egg). The trace shows the port asks for exactly the same missing ids and the boot list drops them, as the original gets
nothing back and draws nothing. Every face the port actually draws in levels 1–4 is loaded (§2.1 row A18).

**Trace vs static disagreements:** two, both harmless — CNTL 605 (the system-volume popup) and DITL 1500 (the
Restore dialog, replaced by a native panel, D35) are read by the port's dialog loaders though the original's use is
unreachable/replaced.

**Loaded but never used by the original:** PICT 1600, PICT 8003, clut 131, clut 4000's second use, the cicn icons.
**Duplicates:** the world map PICT 7000 exists twice (the app's copy is drawn, by the port too); Sprites 206/207 are
shadowed by the Backgrounds copies inside levels; 600/601 are the map's in Sprites and levels 5/25's backdrops in
Backgrounds — the port follows the original's search order (`ResourceChain`).

## 2. Port markers — every refusal, stub, skip and "later" in the port

`tools/ferazel/gap-markers.py` lists 678 markers in Core, Shared, App and Windows (words: refuse, not built, later,
Phase N, TODO, stub, placeholder, out of scope, unsupported, skip/ignore, fatalError/precondition, `throw`). Each was
classified by hand: `gap-ledger/markers-render-classified.tsv` (225, the renderer), `markers-world-classified.tsv` (205,
objects, player, physics, shots, items, particles, lights, camera), `markers-front-classified.tsv` (248 + X001, front end,
session, saves, input, sound, conversations, App, Shared, Windows).

What ends the game: the Mac controller (`FerazelController.swift:270`) and the Windows loop (`WinGame.swift:253`) quit on
a failed tick, and the only throws that reach them come from drawing. Errors while opening a level are caught
(`GameFlow.swift:555`) and shown as "the level could not be loaded". Hard traps are internal consistency checks Core can't
trip (class d).

Class (c) rows: listed in the Summary (X001 continue save, A22 sparkle drift, M0554 empty-inventory box, M0260 voice
eviction; ruled M0060/M0061 debug chord, M0652 Windows menu bar, M0069 system volume).

Class (a), by phase: Phase 5 — enemy Handles/Hits/Kills (the `inert` class), enemy contacts in `.HitPlayerSprite`, shots
vs enemies, the Crawler shot-kill, Statue spell / burning on enemies, geysers NR 2–4, boulder-spout boulders, the
underwater tint, the Magical Shield crouch picture; Phase 6 — bosses, rope bridge 1466, magic carpet, spiked balls,
falling rocks, rotating blade; level 5+ entry (the planned "not built yet" dialog).

Class (b) highlights: rope types 3023–3039 divide by zero in the original (refused); missing PICT ids above; the
original's undefined reads that the port refuses rather than invent (e.g. a light index past the table).

Class (d) highlights (every one checked against `placements-all.tsv` or the level headers): auto-scroll (level 51),
boss-arena bounds (5, 18, 25, 55), OmniPx (5, 15, 25, 70), fire backdrop (52, 55), backdrop ripple (11, 18), wind and
the horizon strip (first on level 10), programmed-path cannons (first on level 10), mace modes 1–2 (level 20), the
countdown digits (level 40), water kinds 206–209.

Lower-confidence items (no quit possible, at most an omission): every passage in levels 1–4 assumed to have p2 0
(`HitPlayerSprite.swift:957`), every crate drop in levels 1–4 assumed item 3219 (`BoxSprite.swift:1148`), wind first on
level 10 (probed on levels 1–2 only). Reading p2 from the level files settles them.

Stale comments (noise, worth a tidy): `Camera.swift:46` and `BackgroundSprite.swift:402/437` ("later: SH" — built; the
enemy-shot part is Phase 5), `StatusBarCalls.swift:65` (callers built at `HandleKeys.swift:207/219`), `UnderWater.swift:12`
(six callers now), `LevelFlow.swift:35` (written at `LevelRun.swift:585`), `FerazelSession.swift:1200` (fade-in built at
`LevelRun.swift:524`), `TileGridRenderer.swift:33` (mask-only redraw is built), `LightFaces.swift:69` (Q15 item).

### 2.1 Draw audit — every input the renderer can refuse × can Core produce it in levels 1–4

From `markers-render-classified.tsv`, section DRAW AUDIT (25 rows A01–A25). Every sprite draw mode, rotation, scale,
mirror flag, face reference, light face, rope face, water kind, backdrop mode and conversation portrait that Core writes
was traced to its writer and checked against the placements:

| input | reachable in L1–4 | renderer | class |
|---|---|---|---|
| modes 0, 1 (tints, max sub 22 of 25), 3/4 (hurt flash), 6 (water), 9, 0xb (translucent), 0xc (lights), rotation 0–359, scale | yes | handled | n |
| mode 5 sparkle (fixed 0fd056e), mode 0xa gauge (fixed 0fd056e), rope faces + light 806 (48a0620), boot faces (b535527), re-seat (78e81c3) | yes | handled | n |
| mode 5 rotated/scaled, mode 0xa mirrored/transformed, mode 0xb rotated | no writer in scope | refused | d |
| mode 0xc at full darkness under the brightest light; light byte −1 | no (level 4 only dark spots, no lit sprite there) | refused | d (latent quit) |
| modes 2, 7, 8, 0xd, 0xe, ≥0xf | only the never-active parallax sprites | refused | d |
| backdrop fire / ripple / OmniPx; water kinds ≥ 6 | no (header 0 on levels 1–4) | refused at level open | d |
| sparkle random walk at the camera scroll vs the drawn grid scroll | yes (teleport/passage frames) | draws, slightly different | c (MED) |

## 3. Original routines — every routine × where the port has it

`tools/ferazel/gap-routines.py` lists the 1,236 routines of the decompile (154 of them the sprite/system callbacks of
`docs/ferazel/tools/targets.txt`) with how many port lines cite each by name or address; the hand classification is
`gap-ledger/routines-classified.tsv` (every row: status, phase or reason, reachable in levels 1–4, confidence; hand
decisions in `tools/ferazel/gap-legs/routines/overrides.py`).

| status | count | what it means |
|---|---:|---|
| built | 501 | cited by the port; ~120 hand-checked, ~440 by citation only (MED) |
| absorbed | 55 | the port does the job under another name (where: the table's note) |
| partial | 21 | missing arms named per row — every missing arm is Phase 5/6 or an object not placed in levels 1–4 |
| not built | 151 | 72 Phase 5 (enemy classes, enemy shots, geysers, burn-away, shield block, underwater tint), 52 Phase 6 (Dillo, Warrior, Demon, Chief, Wizard, Xichra, victory, rope bridge), 27 later-level features (fire backdrop, OmniPx + rain, backdrop ripple, horizon strip, auto-scroll, boss arena, wind, programmed cannons/maces, trees, rotating blade) — header values all 0 on levels 1–4 |
| out of scope | 498 | Toolbox/system/runtime plumbing (Apple events, resolution switch, date checks, memory, cursor, thread manager, debug, movie capture, FPS display, the C runtime) |
| dead | 10 | no reachable caller: `.InitPlayerKickRects`, `.AltClutMod`, the track map (3), `.DoSaveGame`, `.BuildPosterizationTable`, `.BlitEncFaceTransRippleClip` (mode 0xd), dynamic sounds (2) |

Partial, the ones a player meets: the six enemy Setups placed in levels 1–4 (face and fields built, behaviour Phase 5);
`.HitPlayerSprite`, `.HitPlayerShotSprite`, `.KillPlayerShot`, `.HitButtonSprite` (their enemy arms are Phase 5). Every
other partial row's missing arms belong to object types placed only on later levels.

Citation is not proof of building: the enemy Handles are "cited" only because the Smiting Ring lists them as targets —
the hand pass caught that. What is left at MED: ~440 "built" rows judged by citation; the 498 out-of-scope rows by name
(the 39 unnamed `FUN_` ones were read); one LOW row (`.InitScenery` clears a global whose reader wasn't traced).

## 4. Confidence and limits

- Reachability was checked against the shipped level data (`placements-*.tsv`, level headers) and Core's writers, not by
  playing. The trace covers what the test suite exercises; App/Windows-only paths (dialog colour tables, native panels)
  were checked statically.
- The routine table's "built" verdicts are mostly by citation (MED); a routine can be cited and still miss a rare arm.
  The 78 cited routines whose cite lines mention later/not built/refused were all opened by hand.
- Nothing here was verified by running the original. The two items that need Ben's eyes or a capture: the
  empty-inventory box (row 3) and the picture-shrink rule.

## 5. Re-running

```sh
tools/ferazel/gap-markers.py    > docs/ferazel/gap-ledger/markers.tsv        # port markers (seconds)
tools/ferazel/gap-routines.py   > docs/ferazel/gap-ledger/routines.tsv       # routines × port cites (~40 s)
tools/ferazel/gap-placements.py     > docs/ferazel/gap-ledger/placements-1-4.tsv
tools/ferazel/gap-placements.py all > docs/ferazel/gap-ledger/placements-all.tsv
tools/ferazel/gap-trace.sh "$TMPDIR/res.trace"                               # traced Core suite (~15 min; temp HectorKit copy)
tools/ferazel/gap-resources.py "$TMPDIR/res.trace" > docs/ferazel/gap-ledger/resources-joined.tsv
```
New markers or routines show up as rows missing from the `*-classified.tsv` tables (join on the M-id / address); a
resource whose `note` says CHECK is one the trace and the static table disagree on. The classification aids the legs
wrote are in `tools/ferazel/gap-legs/` (see its README).
