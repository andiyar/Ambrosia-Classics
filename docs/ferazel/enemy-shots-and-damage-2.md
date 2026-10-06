# Ferazel's Wand 1.0.3 — enemy shots and damage, part 2 (wave 2 loose ends)

Code readings only; nothing behaviour-verified. Date 2026-10-04.
Sources: `ghidra/Ferazel_pef.disasm.txt` (every HIGH cites raw addresses), `ghidra/Ferazel_pef.decompiled.c` / `ghidra/Ferazel_handlers.decompiled.c` (orientation), `tools/const.py`, `tools/tocrefs.py`, placement census over all 24 `Mlvl`, PICT decodes from `Ferazel's Wand Sprites.rsrc`.
Continues `enemy-shots-and-damage.md` (§1–§3; section numbers continue). Labels per INDEX.md.

## 4. Wave 2 (2026-10-04) — spawn set, collision passes, list order, loose ends

### 4.1 Every enemy-shot type that can exist; dead fields  [HIGH]
All 17 loads of the SetupEnemyShot slot 0x100a0830 (`tocrefs.py`) were followed to their
`MTNewSprite` calls (`bl 0x10033060`, r8 = the slot or the register holding it) and the type in r3:

| spawner | r3 (type) | raw |
|---|---|---|
| Walker | `lbz 0x17e` (0/1); 0x6a9; own type `lha 0x4` (0x6d6 Walkers); `addi r3,r3,0x6e1` (= 0x6e1 + p1) | 10068638, 10069084, 10069288/100692b4, 100699f4 |
| Box spouts 0x5aa..0x5ad | `lhax r3,r4,r5` = own p4, `addi 0x6e1` | 1006e958/1006e960 (all four calls) |
| Background traps | `addi r3,r3,0x5` (own type + 5) | 10074a68 |
| Floater | own type `lha 0x4` (class range 0x6f4..0x707) | 100818f8 |
| literals | 0x712 (Bat, Gremlin, Salamander), 0x709, 0x753 (Dillo, Xichra), 0x754 ×7, 0x71f, 0x46a (Demon, Wizard ×3, `.DoXichraShot`), 0x77b, 0x6d6 ×2 / 0x771 / 0x772 (Xichra), 0x6e6 (`.KillEnemyShot`) | 1007ee9c, 100804c0, 100833d0, 100826cc, 10086f10, 1008f12c, 10086508…10086708, 100882cc, 1008aadc, 1008ce60/ceb4/cf08, 1008e408, 1008bd3c, 1008ec7c/ecb4, 1008f1cc/f218, 1005cca0 |

The only literal uses of 0x46b/0x46c are compares in the EnemyShot routines and `.HitPlayerSprite`
(raw scan `,0x46[bc]`: 10057ad0, 1005bee8, 1005bf30, 1005c730, 1005c774, 1005ca54, 1005ca5c); no
`addi …,0x46a` exists; `.GenerateSprite` routes no class to 0x46a..0x46c (`gensprite_map.py` → none).
The computed types cannot reach them in shipped data: Walker 1760 p1 ∈ {0,1} (census 24 records),
spout p4 ∈ {0,1} (5 records, all L4), traps give 0x771..0x77a, Floaters 0x6f4..0x707. So **0x46b /
0x46c are dead types** (their Setup arms, 64×64 faces and 0x70/0xa8 damage rows are unreachable).
**0x77b's `+0x14c` is never written**: the only `stw …,0x14c(` in the EnemyShot code are
`.SetupEnemyShotSprite` 1005bb04 (type 0x6a9 only, `cmpwi 0x6a9` 1005bad4) and the decrement-if-positive
in `.HandleEnemyShotSprite` 1005c06c; `MTNewSprite` clears the record. The `.HitPlayerSprite` test
`lwz r0,0x14c` at 100579b0 is therefore always 0 → the boulder always takes the damage path.

### 4.2 Collision passes and the active-list order rule  [HIGH]
**List.** Active sprites form one doubly linked list: head `*(_DAT_1009ff58)+0x5c`, next `+0x68`,
prev `+0x6c` (`.MTInsertSprite` 10032f1c–10032fcc). Insertion is by **layer `+0x80` ascending; a new
sprite goes after every sprite whose layer is ≤ its own** (`cmpw new,next; bge` keeps walking,
10032f40/10032f7c). `.MTNewSprite` calls the Setup **before** inserting (10033210–1003322c), so a
layer written by the Setup counts. Later direct `+0x80` writes (e.g. `.HandleWalkerSprite` 11 every
frame at 10068470, `.HandleCannonedSprite` 2 at 10058888–10058890) do **not** re-sort; only
`.MTChangeSpriteLayer` re-inserts (callers: Chain, Box, Background, Dillo, Xichra). Nodes are unlinked
only by `.MTKillSprite`, whose callers are `.UpdateSprites`, `.AddIdleSprite`, `.IdleToActiveSprite`,
`.KillAllSprites` and `.MTKillPxSprites` (`100334ec`; ⚑ corrected (review 2h, 2026-10-04) #4) — never
during the handle/collide passes.
**Frame order** (`.HandleSprites` 10007c24): (1) `.MTHandleSprites`, (2) `.MTCollideSprites`,
(3) `.MTCollideSpecialSprite(player, HitPlayerSprite)` unless `*_DAT_1009ffa8` (player died) or no player.
1. **Handle pass** (1003259c): walks the list, loading `next` **before** calling `+0x4c`
   (100325b8/100325bc). A sprite created inside a handler runs its Handle in the same frame iff it is
   inserted after that pre-loaded `next` node, i.e. iff some sprite of layer ≤ the new layer already
   follows the creator — assuming no sprite *before* the creator carries a current layer above the new
   one (insertion walks from the head; direct `+0x80` writes do not re-sort; spells-detail-2 §4; ⚑ corrected (review 2h, 2026-10-04) #5).
   ⚑ wave 2 corr (2026-10-04) P1 W1: the one statement of this rule (player-states §9.1, platforms-ropes-radial-2 §8.2; raw `100325b8..100325d8`,
   `10032f1c..10032fd0`); e.g. a Shadow Double (layer 9, created by the layer-10 player) is never handled in its creation frame.
2. **Main pass** (100326cc): clears every `+0x44` (hot-rect-built flag); for each outer sprite A with
   `+0x5c ≠ 0`, `+0x1b2 == 0`, `+0xe9 == 0` (10032738–10032758), scans the whole list for partners
   B ≠ A with `+0xe9 == 0`, `|ΔA.x|, |ΔA.y| < 360` (top-left integers; `li 0x168` stored by
   `.MTInit` 10032274/10032278), not (A`+0x184` ∧ same `+0x4c`), and absolute hot rects
   (`.CalcHotRect`: `+0x34` offset by (x,y) into `+0x3c`, 10032628–10032650) intersecting
   (`.TheSectRect` 10032820). Up to 6 partners are buffered; a 7th+ is processed at once (A(B), then
   B(A) if B`+0x5c`). One partner: A(B), B(A) (10032898–100328c8). Several: the partner with the
   **largest** key |B's far edge in y − A.cy| + |B's near edge in x − A.cx| goes first (⚑ corrected
   (review 2h, 2026-10-04) ruling 2: axis wording as platforms-ropes-radial-2 §8.3; keys stored
   negated, 10032950, then a strict-minimum search, 1003299c), then the rest in list order; each pair
   A(B) then B(A). No `+0xe9` re-test between the two calls. A pair of two callback sprites is
   therefore visited twice per frame (once from each end) unless the first visit kills one.
   ⚑ wave 2 (2026-10-04) corrects part 1 §3.1's "nearest first" (applied there in place).
3. **Player pass** (`.MTCollideSpecialSprite` 10032ac8): partners = every sprite with a handler
   `+0x4c ≠ 0`, `+0xe9 == 0`, ≠ player (10032bdc–10032bf8), whose rect `+0x34`+position meets the
   player's (`.SectRectFast` 10032c88; no distance gate). Up to 16 buffered (10032c9c); beyond that
   `HitPlayerSprite(player, B)` at once. One partner: HitPlayerSprite(player,B), then B's own `+0x5c`
   (10032ce8–10032d18). Several: if none of them is a see-saw segment (handler = TOC 0x100a01c8,
   10032db0–10032dc4) each in **list order** (the "minimum" search breaks at the first unprocessed
   entry: `addi r6,r27` 10032e30) gets HitPlayerSprite then its own callback; if any is a see-saw
   segment, only HitPlayerSprite runs, in list order (10032e9c–10032ed8).
Consequences: every other sprite's hit callback sees the player twice per frame (main pass as A,
player pass as B) unless it killed itself in the first; `.HitPlayerSprite` sees each partner once.
Layers that matter: player 10 (`.SetupPlayerSprite` `li r5,0xa` 1004af88 → `stw r5,0x80(r23)` 1004afac;
spawn arg `li r6,0xa` 10009e4c → `MTNewSprite` `bl` 10009ec4 — ⚑ corrected (review 2h, 2026-10-04) #3 — reviewer's cite adjudicated wrong, both cites kept), held item
0x14, Walkers 11 (each frame), Walker-thrown shots Walker+1 = 12, spout shots the spout's 10
(`lwz r6,0x80` 1006e988), Pentashield orbs player+1 (`addi r6,r4,1` 1004cef4), 0x6a9 0x14
(1005badc), Effect 0x4b7 0xc.

### 4.3 Consequences for bombs, 0x6a9 and shards  [HIGH unless marked]
- **Bombs 0x6e1/0x6e2 never reach `.HitPlayerSprite`.** In the main pass the bomb (A) calls
  `.HitEnemyShotSprite(bomb, player)`, whose player arm kills every type outside its exclusion list
  (1005c9dc–1005caac; 0x6e1/0x6e2 are not in it) → `.KillEnemyShot` sets `+0xe9`
  (1005cd28 for 0x6e1, 1005cd7c for 0x6e2) → the player pass skips it. So a bomb touching Ferazel does **no contact damage and
  no shield test**; it splits (and 0x6e2 explodes). What hurts is spawned in that same main pass and
  met by the same frame's player pass: shards 0x6e6 (layer = bomb's, `lwz r0,0x80(r24)` 1005cc88;
  `+0x164 = 0` → 0x38) and, for 0x6e2, Effect 0x4b7 (layer 0xc; 0x70 while frame ≤ 7). Shards are
  inserted before the later-created explosion, so the first overlapping shard's 0x38 + 60 invulnerability
  frames usually pre-empts the 0x70 [MED: depends on which random shard positions overlap]. (The two
  passes test the same absolute rects; the main pass adds only the 360-px top-left gate, which a
  16×16 bomb overlapping the player always meets, so the main pass always sees the contact first.)
- **Double split.** Two `.KillEnemyShot` calls on one bomb need two killing callbacks in one visit with
  the bomb's own first. Killers besides the bomb's own arm (`.KillEnemyShot` callers; not relevant to the
  main pass and omitted: `.ShieldBlock` 1005567c, `.HitPlayerSprite` 10057c6c, `.HitEnemyShotTileSprite`
  1005d214/1005d350/1005d46c — ⚑ corrected (review 2h, 2026-10-04) #4): Pentashield
  orb arm of `.HitPlayerShotSprite` (no `+0xe9` test, 1005a944), `.HitWalkerSprite` (shot age > 2,
  other type; 1006a36c/1006a468), `.HitBackgroundSprite` 10075134, `.HitFloaterSprite` (same type only).
  The bomb's own arm kills only against the player, a player shot (0x6e1/0x6e2/0x753), a solid
  Statue/Box. So the one double split is **spout bomb (layer 10) vs a Pentashield orb (layer 11)**: the
  bomb is A first → it splits, then `.HitPlayerShotSprite(orb, bomb)` splits it again. Walker bombs
  (12) come after orbs (11) → single. Orbs come from sphere 1338 (L22, 30, 31, 70); spouts exist only in
  L4, and `.ClearPlayerVars` clears the orb state (`PTR_DAT_100a053c` load 1004aeb8) → **unreachable in
  the shipped levels** [HIGH census; MED that the orb state cannot carry into L4].
- **0x6a9 is collidable in exactly one frame.** It is created in the Walker's Handle (layer 11) with
  layer 0x14; the held item (layer 0x14, made by `.SetupPlayerSprite`) already follows the Walker, so the
  new shot lands after the pre-loaded `next` and its Handle runs the same frame (`+0x14c` 2 → 1). It
  is then collidable in that frame's two passes (its own callback never kills it: `cmpwi 0x6a9` 1005ca98
  exempts it); on player contact `.HitPlayerSprite` kills it; the next
  frame's Handle takes `+0x14c` to 0 and kills it before any pass [HIGH; MED that the held item is
  always present; MED also because it assumes the Walker's **insertion-time** layer is ≤ 0x14 — its
  direct 11 writes do not re-sort (§4.2) — ⚑ corrected (review 2h, 2026-10-04) #5].

### 4.4 `_DAT_100a0570` = boss-landing stagger  [HIGH]
Setters: `.HandleChiefSprite` `li r0,0x18; sth` 1008bbc8–1008bbd0 and `.HandleXichraSprite`
`li r0,0x14; sth` 1008f3e4–1008f3ec, each on the boss's landing frame and only if the player
(`*_DAT_1009fdd8`) has `+0xce` or `+0xcd` (on ground or on a top). While > 0: `.HandleKeys` skips all
input (10052b58–10052b64); `.HandlePlayerSprite` −1/frame (1004df44–1004df5c), halves vx each frame
(0.5 at 0x100a1a28, 1004fbc0), shows the PICT 1037 face cycle (1004fc48–1004fcf0) and skips the
state machine — the reading already in player-states §3.4 and bosses §3. `.HitPlayerSprite` zeroes it
when an enemy shot's hit lands (10057be8–10057bf0): a projectile knocks Ferazel out of the stagger.
Also closes spells-detail NR 3 for this global.

### 4.5 Gremlin spit `+0x1aa` = draw rotation  [HIGH write/copy; MED units]
`.HandleGremlinSprite` 1008052c–10080554: direction `+0x158 == 4` → facing 1 and `+0x1aa = 0xdc`;
`== 0xe` → `+0x1aa = 0x140`. `.WrapDrawSprites` copies `+0x1aa` into the face's `+0x1a` (10014688/
1001468c) and `.BlitEncFaceRot` indexes the f64 sin/cos tables `_DAT_100a0164/0168` by it, with
`subfic 0x168` (360 − a) when mirrored (1002ad24): degrees. So the 0x712 spit is drawn rotated 220°
(dir 4) or 320° (dir 14), i.e. aligned with those two diagonal launch directions; every other
direction draws it unrotated. No EnemyShot routine touches `+0x1aa`.

### 4.6 `.WallBounce` argument 5 = restitution  [HIGH]
Arg 5 (r7 → r23 at 10037a70) is used only when arg 8 (r10 → r29, low byte) is non-zero, at the
moment of a resolved contact moving into the surface: the normal component is reflected and scaled,
the tangential one scaled, both by `f·v >> 8` (`srawi 8`, rounds toward −∞) — e.g. kind 0:
`mullw; srawi 0x8; neg` → vx, `mullw; srawi 0x8` → vy (10037c90–10037cc4); the "into-the-wall
component → 0" step that follows no longer fires because the sign flipped. Enemy shots pass f = 0xa0,
flag 1: they rebound at **160/256 = 0.625** of their speed in both axes; the bounce counter
(§1.3) then decides their death.

### 4.7 Shadow-double flags  [HIGH; pointer]
Named elsewhere and re-confirmed: `PTR_DAT_100a0674` = "standing still" (player-states §1 l. 2753–2770,
held-item-melee §2), `_DAT_100a06d4` = wand phase 0..7, `_DAT_100a06d0` = wand-held counter
(player-states §2), `_DAT_100a071c` = crouch depth. Full face rule: held-item-melee §2. Why riding
re-syncs: the pose ring stores world positions, so while the ridden sprite moves a 13-frame-old pose
would float off the platform; the replay index climbs to the newest entry instead [LOW intent;
mechanism HIGH there].

### 4.8 Names and the frog tint source  [HIGH code / MED names]
| type | what | evidence |
|---|---|---|
| 0x57d (1405) | spiked-underside platform | platforms-ropes-radial §2 table; ×9 in L50, 62, 70 |
| 0x433 / 0x434 (1075/1076) | falling boulders (face PICT 1070, a grey boulder, decoded) dropped by Warrior / Wizard (`+0x160 = −52`, 1008d060–1008d06c) / Xichra (no `+0x160` write → falls at once); 0x433 is routable by `.GenerateSprite`, 0x434 is not; none placed | pickups-boxes-2 §5 |
| 0x5c3 / 0x5c4 (1475/1476) | spiked balls, face **PICT 1487** (red spiked ball, decoded) | pickups-boxes-2 §4.1 |
| 0x5c8..0x5d1 (1480..1489) | swinging bars / circling spiked balls (PICTs 1482 pendulum blade, 1485..1487 grey/white/red spiked balls) | triggers-background §2.5 |
Frog spit tint `+0x15c` = **placement p1** (`.SetupFrogSprite` `lha r0,0x8(rec); stw r0,0x15c` 10081fe0–
10081ff4); census 1800: p1 0 ×28, 1 ×9, 2 ×1, 4 ×3 — tint 0x1000f (p1 = 3) is never placed.

## NOT RESOLVED
1. Whether the Pentashield orb state (`PTR_DAT_100a053c` / `PTR_DAT_100a0614`) is reset on every level
   entry — the only remaining path to a double bomb split (§4.3). `.ClearPlayerVars` loads both slots
   (1004aeb8, 1004acfc); its call sites were not traced.
2. Which shard positions overlap the player when a 0x6e2 bursts on him (0x38 from a shard vs 0x70 from
   the explosion, §4.3) — random per burst; play decides.
3. Intent of re-syncing the shadow double while riding (§4.7) — mechanism HIGH, purpose LOW.

## Proposed additions to physics.md §0
| off | type | meaning (writer/reader) |
|---|---|---|
| +0x3c..+0x42 | Rect | absolute hot rect = `+0x34` offset by (x,y), built by `.CalcHotRect` (10032628–10032650) for `.MTCollideSprites` (§4.2) |
| +0x44 | u8 | hot rect built this frame: cleared for every sprite at the start of `.MTCollideSprites` (100326f4), set by `.CalcHotRect` (10032650) |
| +0x6c | ptr | previous in the active list (`.MTInsertSprite` 10032f54/10032f8c; +0x68 = next) |
| +0x80 | i32 | layer = list sort key **at insertion only** (Setup runs before the insert, 10033210–1003322c); direct writes later do not re-sort (§4.2) |
| +0x1aa | i16 | draw rotation, degrees (also set on the Gremlin's 0x712 spit: 220° / 320°, §4.5) |

## Corrections to the existing bank
| # | file § | old | new | evidence |
|---|---|---|---|---|
| W1 | enemies-ground §2.1 | "`.MTCollideSprites` calls both hit callbacks for intersecting hot rects … The damage is applied by `.HitPlayerSprite`" | the player's `+0x5c` is 0, so `.MTCollideSprites` only calls the other sprite's callback; `.HitPlayerSprite` runs only in the later `.MTCollideSpecialSprite` pass (no distance gate, list order) | §4.2: 1004af44/1004afd4, 10007c38/10007c64, 10032bdc–10032ed8 |
| W2 | enemies-flyers §1.3 | "`.MTCollideSprites` … the player's callback runs whatever B's own `+0x5c` is" | the player's callback never runs there; the player pass calls HitPlayerSprite(player, B), then B's own callback | as W1 |
| W3 | enemies-ground §7 table, row 0x6e1/0x6e2 | damage 0x38 | none on contact: `.HitEnemyShotSprite` kills the bomb in the main pass (1005c9dc–1005caac → 1005cd28/1005cd7c) before the player pass; the hurt comes from shards 0x6e6 (0x38) / explosion 0x4b7 (0x70) | §4.3 |
| W4 | engine §4 loop sketch | "MTCollideSprites; player special collisions" | add: the special pass is the only caller of `.HitPlayerSprite` (slot 0x1009fdd4 loaded only at 10007c60) and is skipped while `*_DAT_1009ffa8` (player died) | 10007c40–10007c64 |
| W5 (merged into L10's ⚑ wave 2 text, FIXPASS; ⚑ corrected (review 2i, 2026-10-04) #4) | held-item-melee §1 "Collision timing … [MED: active-list order]" | active-list order unresolved | rule in §4.2: sorted by layer at insertion (Setup first), ties by creation time; the handle pass pre-loads `next`; nothing is unlinked during the passes | 10032f1c–10032fcc, 100325b8/100325bc, 10033210–1003322c |
| W6 | enemy-shots-and-damage §3.1 (own; applied in place) | "with several partners the nearest is processed first" | main pass: largest edge-distance key first, then list order; player pass: list order only | 10032950, 1003299c; 10032e30 |
| W7 (stale — already closed by spells-detail-2 §1, not re-applied; ⚑ corrected (review 2i, 2026-10-04) #4) | spells-detail NR 3 (`_DAT_100a0570`) | open | Chief/Xichra landing stagger (already player-states §3.4) | §4.4: 1008bbc8–1008bbd0, 1008f3e4–1008f3ec |
