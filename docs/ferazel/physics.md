# Ferazel's Wand 1.0.3 — physics: integration, tile collision, player movement, damage, enemies

Register: code readings only; **nothing behaviour-verified**. Labels per claim (INDEX §Labels).
Units: px; velocities and accelerations in **1/256 px per frame**, one frame = one `.GameLoop`
iteration (≤ 30.08 Hz, engine.md §4). Sprite record offsets are `s+0x..` (0x1fc-byte sprite).
Player-handler code lives in the supplementary dump (`.HandlePlayerSprite @ 1004d5fc`,
`.HitPlayerSprite @ 100556f4`, `.HitPlayerTileSprite @ 10054ca8`), the rest in the main dump.
§8 (non-enemy sprite physics) lives in `physics-sprites.md` with its numbering kept; "§8.x"
below means that file ⚑ corrected (deepening 2026-10-03).

## 0. Sprite fields used by physics  [HIGH unless noted]

| off | type | meaning (writer/reader) |
|---|---|---|
| +0x00 | u8 | slot in use: `.MTNewSprite` 1, `.MTKillSprite` 0 (`100331c8..100331cc`) [HIGH] ⚑ wave 2 (2026-10-04) (SD2 §Proposed) |
| +0x04 | i16 | type — **except player shots**: `.SetupPlayerShotSprite` rewrites it to the spell id (`(char)(type>>8)`) and moves the power to +0x170 for the shot's whole life (§7; spells-items.md §2) ⚑ corrected (review 2026-10-03) #3 |
| +0x06/+0x08 | i16 | y/x copy (old position; set with +0xa/+0xc each integration step) |
| +0x0a/+0x0c | i16 | y/x integer position (top-left of the face cell) |
| +0x0e/+0x10 | i16 | centre y/x of the hot rect (`.CalcCenterPos`) |
| +0x14/+0x1c | i32 | x/y in 24.8 fixed point |
| +0x24/+0x2c | i32 | vx/vy (1/256 px/frame) |
| +0x34..+0x3a | Rect | hot rect relative to the face cell (top,left,bottom,right) |
| +0x46 | i16 | per-class scratch (rope rider offset, spring cooldown, platform/crumble counters — §8) ⚑ corrected (review 2026-10-03) #2. Further uses: player walk/run cycle phase (player-states-2 §Proposed); button press level 0..11, spring cooldown = face 0..3, cannon aim (1/32 turn), spike frame, arrow-trap state, sword angle °, effect frame (triggers-background-2 §6); Wraith visibility phase (enemies-flyers §5.2) ⚑ corrected (deepening 2026-10-03) |
| +0x48 | i16 | placement-record index (written `*(short *)(s+0x48) = recIndex` at the end of `.GenerateSprite`; −1 = no record, the sentinel `.SetupProgrammedPath`/`.DoSetupPlatformSprite` test; read by the `.UpdateSprites` write-back and by the `.HitPlayerSprite` sign/trigger param reads — world-data §3.4 "records are live" depends on it) ⚑ corrected (review 2026-10-03) #7 |
| +0x4c | proc | per-frame handler (Setup replaces itself with Handle) |
| +0x5c | proc | sprite-sprite hit callback; +0x1f8 tile-hit callback |
| +0x68 / +0x6c | ptr | active list **next / previous** (`.MTInsertSprite` `10032f54`/`10032f8c`, `.MTRemoveSprite`, `.MTKillSprite`); head `*(_DAT_1009ff58)+0x5c` [HIGH] ⚑ wave 2 (2026-10-04) (SD2, PR2, ES2 §Proposed merged) |
| +0x80 | i32 | layer ~~(MTNewSprite arg) [MED]~~ = the **active-list sort key**, ascending, signed (`cmpw`); a new sprite goes after every sprite of equal or lower layer (ties after existing sprites, `bge` `10032f44`/`10032f80`). Read **at insertion only**: `.MTNewSprite` stores the argument (`10033200`), runs the Setup (`1003321c`) and then inserts (`1003322c`), so the effective value is whatever the Setup leaves; direct `+0x80` writes later do **not** re-sort (e.g. `10066518`, `1004beb0`, `100632d8`, `10063400`), only `.MTChangeSpriteLayer` re-inserts. Draw, handle and collision passes all walk this **one** list (platforms-ropes-radial-2 §8.2, enemy-shots-and-damage-2 §4.2). Caveat (review 2f #1): the same-frame rule for sprites created inside a handler (spells-detail-2 §4) assumes no sprite *before* the creator carries a current layer above the new one, since insertion walks from the head (`10032f68..10032f9c`) [HIGH] ⚑ wave 2 (2026-10-04) corr SD2 #S3 = PR2 #3 (+ SD2, PR2, ES2 §Proposed merged) |
| +0xa4 | i16 | hit points (`.HurtSprite`) |
| +0xaa | i16 | hurt-flash frames; +0x116 invulnerability frames |
| +0xce | u8 | ground/surface kind under the sprite this frame (0 = airborne) |
| +0xcf | u8 | ceiling kind hit this frame |
| +0xd8 | i16 | surface material = FG kind / 100 of the tile stood on (1..), 0 = plain (`.WallBounce`) |
| +0xdc | ptr | platform sprite being ridden |
| +0xe9 | u8 | kill request (handled by `.UpdateSprites`) — ⚑ wave 2 (2026-10-04) (SD2 §Proposed): `.UpdateSprites` advances it 1→2→3→4 (procs, face, light cleared, type negated) and unlinks/frees the sprite at 4 (`1000996c..10009a74`) [HIGH] |
| +0x110 | i16 | gravity per frame |
| +0x112 | i16 | slipperiness value (ice) |
| +0x11c/+0x120 | i32 | water contact: `surfaceY − y − face top inset`, clamped ≥ 1 while in water (so 1 = fully submerged, larger = visible top that far above the surface), 0 = not in water / previous frame's (fix-pass reading of `.HandleUnderWater`, §5.1) [MED]. ⚑ corrected (deepening 2026-10-03): `.StandardSpriteHandles` copies `+0x11c` into `+0x120` (when non-zero) and **zeroes `+0x11c` every frame** while `+0x118 < 0x1d` (raw `10036990..100369ac`), so `+0x11c` is valid only after the frame's own tile pass ran `.HandleUnderWater`; handlers that test it earlier never see water (Frog/Salamander water blocks are dead code — enemies-water-cave §0.1) [HIGH]. ⚑ corrected (review 1c, 2026-10-03) #4 (adjudication B4 tail): readers between that zeroing and their own tile pass — Frog `10082198/b8`, Salamander `100830c4/e4` and **Gremlin `10080628/48`** (a second `.StandardSpriteHandles` on the gremlin itself at `1008061c` precedes the read) are dead; Walker `10068adc` and Platform `100649c4` test `+0x11c == 0 ∧ +0x120 == 0`, so they degrade to a one-frame lag (previous frame via `+0x120`, harmless); the Bat reads at `1007e744` **before** its SSH (previous-frame value, copied to a child); every other class reads after `bl 0x100375b0` [HIGH] |
| +0x128 | i16 | water kind (BG kind − 200) |
| +0x138 / +0x13a / +0x13c | i16 | push mass (a sideways push by a mover adds `mover+0x13c · (+0x138 · Δvx >> 8) >> 8` to this vx) / landing sag (`vy += landing vy · +0x13a >> 8` when landed on at vy > 0x200) / pusher factor — `.RectBounce`, `.PlatformBounce` (§8.1) [HIGH arithmetic, MED names] ⚑ corrected (review 2026-10-03) #2 |
| +0x170 | i32 | player shot: **power** (`type & 0xff`; `.SetupPlayerShotSprite`, handler dump l. 4929) ⚑ corrected (review 2026-10-03) #3. Per-class reuse ⚑ corrected (deepening 2026-10-03): bosses = boss flag (placement p4, bosses §1.1); rope = animated flag (platforms-ropes-radial §3.1); Background 1480.. = harmful flag (triggers-background §2.5); Walker = wall-hit lockout (enemies-ground §Proposed) |
| +0x17e | u8 | facing left — ⚑ corrected (deepening 2026-10-03): it is the **horizontal mirror flag** of the blitter; the facing it means depends on the sheet: player (player-states §6) and Walker 1700 (enemies-ground §3.3) 1 = left; Crawler, Dillo, every flyer, Frog/Salamander/Blob/Crab and every boss 1 = right (enemies-flyers corr. 4, enemies-water-cave corr. 4, bosses-2 corr. 2) [HIGH per class] |
| +0x185 | u8 | one-way top: `.RectBounce` skips side/underside resolution and lands a mover only if its previous-frame bottom was above the top (+8 px slack, +0x20 on sloped tops) (§8.1) ⚑ corrected (review 2026-10-03) #2. Writers ⚑ corrected (deepening 2026-10-03) (synthesis scan of every `stb …,0x185(`): `.InitSprite` (0), Platform setup (**every platform one-way by default**, platforms-ropes-radial §2.1), see-saw segments, the Walker corpse (enemies-ground §3.8), `.SetupBoxSprite` per type (pickups-boxes §2.2 table), geyser column, Background setup, `.SetupTree`; **not** the statue (enemies-ground §2.2). ⚑ corrected (review 1c, 2026-10-03) #9: also `.DoSetupPlatformSprite` (3 stores), `.HandleBoxSprite` (4) and `.HitBoxSprite` (`10070570`: the magic carpet 0x438 → 0x439 **clears** it) (60 `stb …,0x185(` sites in all) |
| +0x186 | u8 | "ridden this frame" (set by `.PlatformBounce`/`.RopeCollide`, cleared by the owner's handler) ⚑ corrected (review 2026-10-03) #2 |
| +0x194 | i32 | jump bonus lent to a rider: `.HandleKeys` copies the ridden sprite's +0x194 into the jump base J of §4 (`*piVar12 = *(int *)(platform + 0x194)`, main dump l. 44901/44937) ⚑ corrected (review 2026-10-03) #2 |
| +0x19e / +0x1a0 | i16 | buoyancy strength (0 = sinks) / float-line offset (`.HandleFlotation`, §8.6) ⚑ corrected (review 2026-10-03) #7; the player's `+0x19e` is written only by the death/revive sequence (3 stores, platforms-ropes-radial §5) ⚑ corrected (deepening 2026-10-03) — ⚑ wave 2 (2026-10-04) (EG2 §Proposed): type 0x6a4 (Walker corpse) under the Platform handler ramps `+0x19e` +1 w.p. ½ per frame to 0x50 (`10064988..100649c0`); every other class leaves it 0 (store scan) [HIGH] |
| +0x1e8 | proc | surface-height function of a ridable non-flat top, called through ptr-glue `FUN_1009f80c` with (sprite, x offset); ropes get TOC slot `_DAT_100a0ce4` (→ `.GetRopeHeight` [MED: TVector→name link not decoded]) (§8.2) ⚑ corrected (review 2026-10-03) #2; link now HIGH and Box type 1466 (rope bridge) installs `.GetRopeBridgeHeight` (platforms-ropes-radial §3.3, §3.7) ⚑ corrected (deepening 2026-10-03) |

### 0.1 Fields added by the deepening  ⚑ corrected (deepening 2026-10-03)
Merged from the "Proposed additions to physics.md §0" of the 14 deepening files (deduplicated;
labels are the proposing readers', not re-derived here unless "synthesis" gives a raw address).
File keys as in `coverage.md` (EG enemies-ground, EF enemies-flyers, EW enemies-water-cave, B2
bosses-2, ES enemy-shots-and-damage, PB pickups-boxes, T2 triggers-background-2, SD spells-detail,
PR platforms-ropes-radial, P2 player-states-2). **⚠** = the readers named the offset differently;
both readings are kept.
⚑ wave 2 (2026-10-04): the wave-2 "Proposed additions" (LT lighting-tables, DE draw-effects, PA particles,
EG2 enemies-ground-2, SD2 spells-detail-2, PR2 platforms-ropes-radial-2, ES2 enemy-shots-and-damage-2,
PB2 pickups-boxes-2) are merged into the existing rows here and in §0 (`+0x00`, `+0x68/+0x6c`, `+0x80`,
`+0xe9`, `+0x19e`), one row per field; new rows `+0x3c..+0x44`, `+0x1b3`.

| off | type | meaning (source) |
|---|---|---|
| +0x18/+0x20/+0x28/+0x30 | i32 | previous-frame copies (vx `+0x28`, vy `+0x30` per EF/EG; x/y by analogy) written by `.WrapDrawSprites` (EG, EF) [MED for +0x18/+0x20] |
| +0x3c..+0x42 / +0x44 | Rect / u8 | absolute hot rect = `+0x34` offset by (x, y), built by `.CalcHotRect` (`10032628..10032650`) for `.MTCollideSprites` / "built this pass" flag, cleared for every sprite at the start of `.MTCollideSprites` (`100326f4`), set by `.CalcHotRect` (`10032650`) [HIGH] ⚑ wave 2 (2026-10-04) (ES2, PR2 §Proposed merged) |
| +0x50 | proc | Kill callback, called by `.HandleBurn` when the burn-away ends (EF, EW, B2; EG `.KillWalker`) |
| +0x54 / +0x58 | proc | active→idle / idle→active callbacks; ropes `.RopeIdleize` / `.RopeDeIdleize` (EF, PR) |
| +0x84 / +0x86 | i16 | ~~zeroed for bats … NOT RESOLVED~~ ⚑ wave 2 corr (2026-10-04) EF W1: i16 pair (`+0x86` x, `+0x84` y) of a vestigial bounce velocity, **0 in every sprite all game** — every writer stores 0 or rescales 0 (`.RectBounceFake2`'s only caller passes 0, h. l. 3095); the shot-particle offsets that subtract them (SD) subtract 0 (enemies-flyers §7.1) [HIGH] |
| +0x88 | u8 | ~~**⚠** "lit / draw the light overlay, default 1" (EF, PR) vs "draw-normal flag" (P2) vs "[draw/collide flag?]" (ES)~~ ⚑ corrected (review 1c, 2026-10-03) #5 (adjudication A8): **light-overlay gate** — its only reader, `.WrapDrawSprites` `1001493c..1001499c`, selects the **second** pass `.WrapLightFace @ 100156c8` after the unconditional `.WrapDrawFace @ 100151c4` (`100148e4`/`1001491c`); that pass is also skipped when prefs (`−0x79fc`) +6 == 3 (Effects = Reduced) or draw mode 0xe; its arg r4 = `+0x11c` unless `+0x18c`. Default 1 (`.InitSprite` `1003d3d0 li r5,0x1` → `1003d444 stb r5,0x88`); boss Setups clear it (B2). EF/PR right, P2 wrong [HIGH] |
| +0x89 | u8 | dynamic lighting: `.WrapDrawSprites` samples the light map and writes `+0xb8 = 0xc0000 + …` (PR, T2) — ⚑ wave 2 (2026-10-04) (LT, DE §Proposed merged): `+0xb8 = D·0x100 + 0xc0000 + F`, D = BG-cell light byte − 1 (signed; D = −1 with F ≥ 1 turns the word into **mode 0xb**); runs after and so overrides the hurt flash; writes `+0xb8 = 0` when unlit (`100147b8`) (lighting-tables §2.2, draw-effects §1.1) [HIGH] |
| +0x8a | u8 | water current applies (= not clinging for the player) (EW, P2; §2) |
| +0x8c / +0x8d / +0x8e | u8 | burn sound variant (sole reader `.HandleBurn`, synthesis `10043d3c`) / extra burn rows per frame / burn style 0xd (EW, B2); `.SetupEnemyShotSprite` writes `+0x8c = 1` (ES) — ⚑ wave 2 (2026-10-04) (DE, PA §Proposed merged): confirmed — `+0x8c` pitched burn sound (vol 0x41, 110000 + rand(15000)); `+0x8d` = burn rows per frame − 1 (`.HandleBurn` loop bound `10043e68..10043e78`; Chief = 1); `+0x8e ≠ 0` → main burn particle kind 0xd (blue flame) instead of 1 (`10043db8..10043dcc`) [HIGH] |
| +0x90 | i16 | wind/current scale /256: ≤ 0 immune, ≥ 0xff full (player 0x100, 0 while dying, glider by pitch) (EW, SD §5.3, P2; §6) |
| +0x92 | u8 | in-wind flag (§6); holds the player's fall animation (P2) |
| +0x9a | i16 | light handle from `.AddLight` (−1 none) (SD, T2) |
| +0x9c | ptr | per-class block: rope sag block 0x4130 B, Crab links, Demon segments, Wizard 7×i16, Xichra 0x374, swarm table, timer digits (PR, EW, B2, EF, T2) |
| +0xa0 | i32 | previous frame's `+0x46` (button release sound) (T2); a door's `+0xa0` is cleared by `.HitBoxSprite` (PB NR 8) — ⚑ wave 2 (2026-10-04) corr PB2 #P7: the door write is **dead**, no reader (pickups-boxes-2 §6) [HIGH] |
| +0xa6 | i16 | per-class counter: bat awake/anim, Wraith hidden countdown, Gremlin wing index, Blob pause, Crab strike, enemy-shot age, Bonus sphere respawn timer / shard life, Box per-type timer; **player shot: 0 = live** (boss Hit gate) (EF, EW, ES, PB, B1 §1.5) — ⚑ wave 2 (2026-10-04) (EG2 §Proposed): Crawler leap / flee-hop cooldown (initial 3 live, consumer `10065f48`); Roach write-only (its only reader, state 3, is unreachable) [HIGH] |
| +0xb0 / +0xb2 / +0xb4 / +0xb6 | i16 | AI state / sub-state / per-class counters (EG, EF, EW, B2); platform mode (PR); radial angle written into chain/see-saw links (T2); Bonus pickup delay (PB) |
| +0xb8 / +0xbc | i32 | draw-effect word `mode<<16 \| sub` read by `.WrapDrawSprites` / `.WrapDrawFace` → `.BlitEncFaceX` / last frame's copy (`.WrapEraseSprites` forces an erase when its mode was 0xb or 5, `10014d08..10014d1c`). ~~(… 0xb fade/blink, 0xc lighting, 0x10..0x13 blends) … Pixel semantics NOT RESOLVED~~ ⚑ wave 2 (2026-10-04) corr DE #4 = LT #7 (+ LT, DE §Proposed merged; draw-effects' semantics): **written modes 0, 1, 5, 8, 9, 0xa, 0xb, 0xc** only; 3/4 (hurt flash) and 6 (submerged rows) are draw-time substitutes; 2, 7, 0xd, 0xe, 0xf never written (0xe is only tested); **0x10..0x15 are mode-1 table indices** (Walker tiers, `10067638..10067758`), not modes. 1 = remap through tint table sub; 5 = diffuse sparkle; 8 = behind tiles (word add, MED); 9 = water table 0; **0xa = vertical squash** by sub/256, raw copy (`10027614..10027630`); 0xb = translucent through a pair table chosen by sub (0 ½, 1 ¾, 2 ¼, 3 grey-avg, 4 glow, 5 additive, ≥ 0x80 grey-pull); 0xc = light (`D<<8 \| F`). Per-pixel rules draw-effects §2, table colours lighting-tables §2–§6 (chosen indices LOW, particles §4.3) [HIGH] |
| +0xc0 | ptr | current face record (0 = not drawn; `+6` = width) (EF, EW, P2, T2) |
| +0xcd | u8 | **⚠** "previous-frame ground flag" (EG) vs "standing on a sprite" (EW, B2). Synthesis: both — `.StandardSpriteHandles` copies `+0xce` into it at frame start (`100368c4..c8`) and `.PlatformBounce` sets 1 on a landing (`100379c4`) |
| +0xd0 | u8 | on a one-way top: `.WallBounceBG` 1, `.WallBounce` 0, `.PlatformBounce` on a one-way solid (P2; §8.1) |
| +0xe4 | u8 | **⚠** player: enables `.SeparateFromTiles2`'s second (dead) loop (P2); Button: first-frame-done (T2). Synthesis: two readers, `1003cce8` and `10070e84` — per-class reuse |
| +0xea | u8 | killed for good: `.UpdateSprites` clears the placement record's active byte (EG, EF, PB, B2) |
| +0xeb | u8 | crunches tiles on contact (§3.1; 2 = big explosion, T2); player: spin ∨ grounded (P2 corr.); shots 1, seeds 2, Ice Pick 4 strength in `+0x158` (SD) |
| +0xec | i16 | composite part index (Gremlin body/back/rider) (EF) |
| +0xf0 / +0xf4 | i32 | per class: path mode (§8.5), goblin/Frog voice pitch base, boss wounded-glow timer, seed no-fragments flag / Ziridium flag (EG, EW, B2, SD) |
| +0x100 | i32 | per class: path bound (§8.5); Walker tier-4 flag (EG) |
| +0x112 / +0x114 | i16 | (refines "slipperiness") also a one-shot `vx += 7.07·(+0x112)` kick in `.WallBounce` latched by `+0x181` [MED] / friction (Bonus decay, Box `.ApplyFriction`) (PB) |
| +0x130 / +0x134 | i32 | statue frames left (120) / saved `+0xb8` while a statue (EG §2.2, ES §2.2); cannon hold timer, negative = post-launch re-entry block counted up by `.StandardSpriteHandles` (ES, T2; synthesis `10036894..100368a4`) |
| +0x140 | u8 | water handled this frame / skip water (EW, P2) |
| +0x14c..+0x174 | i32 | per-class scratch — see the class files (EG §Proposed, EF §3–5, EW table, B2, PB, PR, T2, SD); player `+0x14c` = catapult launch request (P2, §8.9); player shot `+0x14c` age, `+0x158` crunch strength, `+0x160..+0x16c` follower step / stack offset (SD); enemy shot `+0x14c` lifetime, `+0x150` bounce counter, `+0x154` bounce lockout, `+0x16c` pass walls (ES) — ⚑ wave 2 (2026-10-04) (EG2, PB2 §Proposed): `+0x150` Crawler/Roach death counter (crush writes 0x16 → dies next frame), write-only crush mark for Dillo, Frog, Salamander, Blob, Bat, Gremlin, Floater; `+0x154` stalactite home x for the shake; `+0x160` falling-boulder hover counter (Wizard writes −52); `+0x168` Bonus p4 copy = "no cannon" (`.TurnIntoCannoned` refuses `== 1`, `100585f0..100585f8`), containers: spent |
| +0x17c | u8 | first-frame setup done (Platform, PR) / tree branches built (T2) |
| +0x180 / +0x181 / +0x182 | u8 | radial wall-bounce latch (PR; cleared each frame by `.StandardSpriteHandles`, synthesis `100368cc`) / ice-slide latch (P2, PB) / Box-box contact handled (PB) |
| +0x184 | u8 | no collision with sprites of the same handler (`.MTCollideSprites`) (EF) |
| +0x187 / +0x198 | u8 / ptr | has radial block / the 0xa4-byte radial block (PR §1.2, T2) |
| +0x188 / +0x189 / +0x18a / +0x18b | u8 | placement write-back gates in `.UpdateSprites` (synthesis reads `10009880`, `1000988c`, `10009898`, `10009a00`, `10009ac4`): type/x/y copied back only when 188, 189 and 18a are all 0; 188 also keeps the record on death; 18b keeps it on the final kill frame (EG, EF, PB, B2) |
| +0x18c | u8 | effect-active flag (P2); tested next to `+0x88` in `.WrapDrawSprites` — ⚑ wave 2 (2026-10-04) (DE §Proposed): disables the water split and passes water row 0 to the light pass (`100147dc`, `10014964`) [HIGH] |
| +0x190 | i32 | platform: ~~cleared before `.TurnIntoStatue` — NOT RESOLVED (PR)~~ **dead** — written 0 only (three stores), never read (platforms-ropes-radial-2 §11) [HIGH] ⚑ wave 2 (2026-10-04) (PR2 §Proposed) |
| +0x1a2 | i16 | burn-away row (≠ 0 → `.HandleBurn`; < 0 delay) (EG, EF, EW, B2). ~~vs enemy shots: reflected by the Magical Shield (ES). Per-class reuse — NOT RESOLVED whether a reflected shot can burn~~ ⚑ corrected (review 1c, 2026-10-03) #3 (adjudication A12): **one field, one meaning**. `.ShieldBlock` stores 1 (`10055550`, gated by `.HasItem(0xf)` `bl 0x1004c0e0`); `.HandleEnemyShotSprite` calls `.StandardSpriteCleanup` (`1005c844`), the **only** caller of `.HandleBurn` (`10036ed0 lha 0x1a2; cmpwi 0; beq` → `10036ee0 bl 0x10043cd8`). A shield-reflected enemy shot therefore starts the burn-away from row 1 and dies through its `+0x50` Kill callback — a replica with a mere "reflected" flag draws it wrong [HIGH] — ⚑ wave 2 (2026-10-04) (DE §Proposed): token-row counter; the burn starts at max(face+8, 1) and kills when `+0x1a2 >` face+0xc; `+0x1bc = +0x1a2` hides the consumed rows (draw-effects §4.2) [HIGH] |
| +0x1a6 / +0x1a8 | i16 | ~~draw-effect parameters (P2)~~ glow particle kind / glow chance per outline pixel per frame in % (0 = off), read by `.ParticleGlow` from `.StandardSpriteCleanup` (`10036f0c`; particles §5.6); only the player sets them [HIGH] ⚑ wave 2 (2026-10-04) (PA §Proposed) |
| +0x1aa / +0x1ae | i16 | draw rotation in degrees (copied to face +0x1a) / draw scale, 0x100 = 1.0 (EF, EW, PB, PR, T2) — ⚑ wave 2 (2026-10-04) (ES2 §Proposed): also set on the Gremlin's 0x712 spit (220° / 320°, enemy-shots-and-damage-2 §4.5) |
| +0x1b2 | u8 | handler skip — every handler returns at once; ~~writer `.HandleBoxSprite` (inside a container)~~ ⚑ wave 2 corr (2026-10-04) EF W2: set on the child of an enemy pipe (Box 1490..1493) while it is pushed out (3 px/frame), cleared on release (`1006ecdc`, `1006f040`); still drawn, never the outer sprite of `.MTCollideSprites` (`10032744`) but still collidable as the inner one (enemies-flyers §7.4) (EW, P2, B2) |
| +0x1b3 | u8 | burning: set every `.HandleBurn` call (`10043d10`), cleared by `.StandardSpriteHandles` (`100368c0`), read by `.WrapEraseSprites` [HIGH] ⚑ wave 2 (2026-10-04) (DE §Proposed) |
| +0x1b4 | u8 | hurt flash uses mode 4 instead of 3 (B2; 2941 ice wall, PB) |
| +0x1b5 | u8 | counted in the level totals (enemies, Xichrons, secrets) (EG, EF, EW, PB, B2) |
| +0x1b6 / +0x1b8 / +0x1ba / +0x1bc | i16 | draw clips **left, right, bottom, top as edges in face-local px** (PR) — ⚑ corrected (review 1c, 2026-10-03) #6 (adjudication A10): T2's "visible width / visible height" is wrong; `.WrapDrawSprites` `1001461c..10014684` draws rows `min(+0x1ba, h) − +0x1bc` and cols `min(+0x1b8, w) − +0x1b6`; `.StandardSpriteCleanup` writes `+0x1b8 = occluder xmin − x` or `+0x1b6 = occluder xmax − x`, clamped 0..w (`10036f74..10036ff0`); reset each frame to 0 / 32000 / 32000 / 0 (`100368a8..100368bc`); `+0x1bc` = burn row clip (EF, EW) [HIGH] |
| +0x1be / +0x1c0 / +0x1c2 / +0x1c4 | i16 | occluder rect in world px (PR) = wall-tunnel window **xmin / xmax / ymax / ymin** (T2) — ⚑ corrected (review 1c, 2026-10-03) #7 (adjudication A11): order settled, `10036f20..10036f58` tests `x+w+8 ≥ +0x1be`, `x−8 ≤ +0x1c0`, `cy ≥ +0x1c4`, `cy ≤ +0x1c2`, then clips only horizontally (row above); InitSprite 32000; consumed by `.StandardSpriteCleanup` [HIGH] |
| +0x1c6 / +0x1c8..+0x1ce | u8 / i16 | may go idle off-screen / idle-test margins left, right, top, bottom (EG, PR, T2); ⚑ wave 2 corr (2026-10-04) T2 W3: the margins serve activation (from the idle entry's copy at `+0x1ec..+0x1f2`) and deactivation (live sprite, `+0x1c6 ≠ 0`) alike, one rule, no hysteresis; window = view origin h −24..+632, v −24..+408, ∪ player hot rect, outset 96; `.HandleIdleSprites` scans 511 of the 512 entries (`100081b4..100083f0`, triggers-background-2 §8.3) |
| +0x1d4..+0x1e0 | ptr | linked sprites: children, siblings, parent, followers, trunk chain (EF, B2, PB, PR, T2, SD) — ⚑ wave 2 (2026-10-04) (SD2 §Proposed): shot followers are never cleared by the main shot, so they dangle after a follower dies (spells-detail-2 §5) |
| +0x1e4 | ptr | the cannon holding this sprite (ES, T2, P2) |
| +0x1ec / +0x1f0 / +0x1f4 | proc | saved Handle / Hit / HitTile while a statue or cannoned (EG, EW, ES, T2, P2) |

## 1. `.LoadLevelPhysics @ 1000332c` — loaded, never read  [HIGH]

```c
if (*(short*)(hdr+0x2860) != 0) { G40[0..4] = hdr[0x2862,0x2864,0x2866,0x2868,0x286a]; return; }
G40[0]=0x32; G40[1]=0x46; G40[2]=0xf5; G40[3]=0xfc; G40[4]=0x96;   // 50,70,245,252,150
```
`G40` = the 10-byte global at 0x10225730 (TOC slot `_DAT_1009ff40`). A scan of every
`lwz rD,-0x7900(r2)` in the code section (the only way PPC code loads that TOC slot) finds one
hit, inside `.LoadLevelPhysics` itself (`tools/tocrefs.py 1009ff40` → `0x10003330`), and no other
TOC slot points into 0x10225730..0x10225739 (scan of the TOC words, this session). hdr+0x2860
is 0 in all 24 levels. **The per-level physics table is vestigial in 1.0.3**: the five values
are written and never read [HIGH; residual risk: an address formed by arithmetic from an
unrelated base — none seen]. Every constant below is hard-coded in the handlers.

## 2. Generic integration helpers  [HIGH]

- `.ApplyGravityAndSeparateFromTiles @ 100375b0` (most non-player sprites): `g = s+0x110`; in
  water (`s+0x11c ≠ 0`) `g = (int)(g · 0.7)` but at least 0x100 (double at 0x100a1938 = 0.7);
  `s+0xce = 0`; separate; `vy += g`; `x += vx`; then `y += vy` in sub-steps of at most 0xc00
  (12 px), calling `.SeparateFromTiles2` after each step; then refresh integer and centre
  positions. ⚑ corrected (review 1a, 2026-10-03) #2: the water test reads `+0x11c` at entry
  (`100375c8`), before the first `.SeparateFromTiles2` (`10037624`); since `.StandardSpriteHandles`
  zeroes `+0x11c` every frame (`100369ac`, §0 row), the first call of a frame always uses the dry
  gravity — the 0.7 / ≥ 0x100 branch is reachable only by a **second** call in the same frame after a
  first call's `.HandleUnderWater` (the Frog) [HIGH].
- `.ApplySpeedAndSeparateFromTiles @ 1004b83c` (player): `x += vx`; `y += vy` in sub-steps of
  0x400 (4 px) while `vy > 0x400`, stopping early when a collision changed vy; separate after
  each.
- `.ApplyFriction(s, f)`: move vx toward 0 by `f`, no overshoot.
- `.AccelerateSprite(s, ax, ay, maxX, maxY)`: in water (`+0x11c` or `+0x120`) all four args ×0.8
  (double 0x100a1928 = 0.8); `vx += ax; vy += ay`; clamp |vx| ≤ maxX and |vy| ≤ maxY when non-zero.
- `.SetSpriteSpeed(s, vx, vy)`: ×0.8 in water.
- `.EnforceMaxSpeed(s, m)`: scales the vector so the larger axis is ≤ m.
- `.AccelerateBasedOnSlope @ 10037350 (s, a, max)`: in water a,max ×0.8; if standing on a
  slope kind (`s+0xce`) and pushing uphill, the accel **and** the cap are multiplied:
  kind 0xc (a<0) or 0xf (a>0) → ×0.707; 0x20..0x21 (a<0) or 0x22..0x23 (a>0) → ×0.923;
  0x2c..0x2d (a<0) or 0x2e..0x2f (a>0) → ×0.382 (floats 0x100a1920/191c/1918, read with
  `tools/const.py`); `vx += a`; clamp |vx| ≤ cap. (So the slope families are 45°, ~22.5° and
  ~67.5° — cos values; the 0x24..0x2b family has no uphill penalty.)
- `.HurtSprite @ 10037034 (s, dmg, kvx, kvy, invul, flash)`: only if `dmg>0`, `hp>0`,
  invulnerability `s+0x116 == 0`: `hp −= dmg; vx += kvx; vy += kvy; s+0x116 = invul;
  s+0xaa = flash`; returns 1.
- `.StandardSpriteHandles @ 10036854` (start of most handlers): count down +0x116/+0xaa; reset
  per-frame contact fields; **water current**: if `s+0x118 < 0x1d` and in water and kind 0 and
  `s+0x8a`: ramp a counter +0x94 up to 33 and push `x += hdr[0x2714]·n/33` (full push after 33
  frames, decays when out); **wind** (§6); carry with a ridden platform `s+0xdc` (x by the
  platform's dx, y snapped on top +1 px).
- ⚑ corrected (deepening 2026-10-03): `.StandardSpriteHandles` also zeroes `+0x11c` each frame (§0 row), counts a negative
  `+0x130` up by 1 and resets the draw clips `+0x1b6..+0x1bc` (§0.1). `.HandleBatSprite` and
  `.HandleGremlinSprite` add v to the position themselves **before** calling
  `.ApplyGravityAndSeparateFromTiles`, so bats and gremlins move 2·v per frame
  (enemies-flyers §1.1).

## 3. Tile collision

### 3.1 Neighbourhood and dispatch (`.SeparateFromTiles2 @ 1003c804`)  [HIGH]
Only sprites with a tile callback (`s+0x1f8`) collide. The 3×3 cells around the hot-rect centre
(`cx>>5, cy>>5` ±1) are tested in the order centre, then (−1,−1)…; for each cell:
- FG tile `t`, kind `k = FGkind(t)`; if `k ≠ −1` and the sprite's hot rect intersects the
  tile's **FG hot rect** (table §3.2, indexed by tile `t`), call
  `tileHit(s, (cellY·32, cellX·32), k, 1)`. Before that, if `s+0xeb` (can-crunch) is set,
  every crunch-direction nibble > 0 in the 2×2 block up-left of the cell whose 32×32 box at
  (+16,+16) intersects the sprite → `tileHit(s, pos, dir, 2)`.
- BG tile kind `kb = BGkind(t)`; if `kb ≠ 0` and the sprite intersects the full 32×32 cell →
  `tileHit(s, pos, kb, 0)`.
(The second 9-cell loop gated by `s+0xe4` computes rects and discards them — dead code.)

### 3.2 FG hot rects (`.InitTileHotRects @ 10002824`)  [HIGH]
Per FG tile, from `kind mod 100` (`SetRect(l,t,r,b)` arguments, tile-local px):

| kind mod 100 | rect (l,t,r,b) | shape |
|---|---|---|
| 0 | 0,0,16,32 | left half |
| 1 | 0,0,32,16 | top half |
| 2 | 16,0,32,32 | right half |
| 3 | 0,16,32,48 | floor: from half height down into the next row |
| 4 | 0,16,16,32 | bottom-left quarter |
| 5 | 0,0,16,16 | top-left quarter |
| 6 | 16,0,32,16 | top-right quarter |
| 7 | 16,16,32,48 | bottom-right quarter, extended down |
| 0x2d | 0,0,16,48 | left half extended |
| 0x2f | 16,0,32,48 | right half extended |
| other (incl. <0, 8..0x2c, 0x2e, ≥0x30) | 0,0,32,48 | full, extended 16 px down |

A second 64-entry table at +0xc (`DAT_100a4794`, by kind 0..63) and a 96-entry table at
`DAT_100a4314` (inset 6 px for 3..5, else 2 px) are built but their readers were not traced
[NOT RESOLVED]. ⚑ corrected (deepening 2026-10-03): `+0xc` is read only by the dead second loop of
`.SeparateFromTiles2`; `.WallBounce`/`.WallBounceBG` read the per-tile `+4` rect **indexed by
kind**, a quirk a replica must copy (player-states-2 §9.1, platforms-ropes-radial §7).

### 3.3 Kind semantics (`.HitPlayerTileSprite` → `.WallBounce @ 10037a54`)  [MED overall]
- FG kinds are reduced `mod 100`; the hundreds digit (1, 2, …) becomes the **surface
  material** `s+0xd8` when the sprite is resolved against the tile [HIGH]. Material 2 = damaging surface:
  every frame the player stands on it while not invulnerable (and not dying) costs
  `hdr+0x270e` HP (default 0x70), sets 60 invulnerability frames, 18 flash frames and the
  hurt-stun counter `_DAT_100a0748` (also set by `.HurtPlayer`); material 3 = ice: ground deceleration `(256 − hdr+0x2710)·800 >> 8` and `s+0x112 =
  hdr+0x2710 >> 4` (used to slide down 0x20.. slopes) [HIGH, `.HandlePlayerSprite`].
- `.WallBounce(s, kind, tilePos, …, bounce)` resolves the hot rect against the shape:
  kind 0: push right of x+16; 1: push below y+16, sets ceiling `+0xcf`; 2: push left of x+16;
  3: put the hot-rect bottom on y+16 and set ground `+0xce = 3` when falling; 4–7: quarter
  blocks choosing the shallower axis; 8–0xb: L-shaped two-rect blocks; 0x20/0x21 and
  0x22/0x23: two-tile 1:2 slopes (surface height interpolated `(sprite x − tile x)/2`,
  clamped 0..16 / 16..32), standing sets `vy = |vx|/2 + 0x100` and `+0xce`; further cases
  0xc..0x1f, 0x24..0x2f, 0x32..0x3b exist (63 cases total) [HIGH for the cases quoted; the
  rest NOT RESOLVED]. Kind 0x3c is treated as kind 3 shifted 8 px up. Kinds outside 0..0x3c
  are ignored.
- BG kinds (`param_4 == 0`): `< 100` → `.WallBounce` (solid like FG); `100..199` →
  `.WallBounceBG(kind−100)` (a separate solver; one-way/background ledges by name) [LOW for
  "one-way"]; `200..209` → water of kind `kind−200` (`.IsWaterTile`, `.GetWaterTileKind`) →
  `.HandleUnderWater`; `600, 601` ignored [HIGH for dispatch].
- Crunch tiles (`param_4 == 2`, `.CrunchTile`): the player breaks them when falling faster than
  0x9c4 (2500 → 9.8 px/frame) with the spin flag; ~~bounce if not broken (`.RectBounceFake2`)~~ the bounce
  (below) follows whenever it falls fast onto a crunch cell, **broken or not** — `.CrunchTile` returns 1 for
  every processed cell when the strength is non-zero (`10044c18`; tested `100552c0..100552fc`;
  player-states-2 §13) ⚑ wave 2 corr (2026-10-04) P2 W1; stay in spin while DOWN is held [HIGH].
- ⚑ corrected (deepening 2026-10-03): the **complete** `.WallBounce` kind table (0..0x3c, composites 0x10..0x1f, the
  0x30/0x31/0x3a/0x3b no-case kinds), `.WallBounceBG` (one-way floors from above with +1/+3 px
  slack, two-way ceilings; `+0xd0 = 1`; was [LOW]), `.HitPlayerTileSprite` and the per-level kind
  census are in player-states-2 §9–§11; the full player state machine in player-states §1–§8.
  Crunch: the call needs `+0xeb` = spin ∨ grounded, the break test is `cooldown == 0 ∧ vy > 0x9c4`,
  and the `vy = −0.9·vy` bounce happens only with DOWN held (player-states-2 corrections). The
  hurt-stun `_DAT_100a0748` is a 10-frame stun (enemy-shots-and-damage §3.8).

### 3.4 Wall cling / climb  [HIGH]
In `.HitPlayerTileSprite`, kind (mod 100) and input decide a cling: moving left (vx<0) with LEFT
held (or already climbing) into kind 0, or into kind 4/0x14/0x2d when the sprite's bottom is
below the tile's mid line, or kind 5 within 4 px; mirror for right with kinds 2, 7/0x13/0x2f,
6. Cling requires not on ground, not in the 0x588 state, no glider; it sets the climb state
`_DAT_100a0758 = 1`, zeroes vx/vy, faces the wall; at a wall top with an empty cell above, a
"pull-up" (`_DAT_100a06a0 = 1`) starts, else the player is pushed down 1000/256 px.
Climb and pull-up as states, and the tile side: player-states §3.9, player-states-2 §10 ⚑ corrected (deepening 2026-10-03).

## 4. Player movement constants (`.HandleKeys @ 10052ac0`, `.HandlePlayerSprite`)  [HIGH]

Action indices as engine.md §7.1 (0 L, 1 R, 2 U, 3 D, 4 run, 5 jump, 6 use).

| quantity | value (1/256 px/frame) | ≈ px/frame | where / condition |
|---|---|---|---|
| gravity, normal | 0x1b8 = 440 | 1.72 | `s+0x110` set every frame |
| gravity, swimming or deep water | 0x50 = 80 | 0.31 | `_DAT_100a0714 ≠ 0` or depth == 1 |
| gravity, spin jump | 0x118 = 280 | 1.09 | spin flag `PTR_DAT_100a0668` — ⚑ corrected (deepening 2026-10-03): only when swimming or fully submerged; out of water a spin falls at 0x1b8 (player-states-2 corr., raw `1004da90..1004dacc`); confirmed (adjudication B24) — marker ⚑ corrected (review 1d, 2026-10-03) #3 |
| gravity, feather-fall power-up | 0x40 = 64, vy clamped ≤ 0x352 = 850 | 3.3 max | `PTR_DAT_100a062c` |
| terminal fall speed | 12000 | 46.9 | clamp after gravity; vy 0 is bumped to 1 |
| walk accel (from rest / turning) | 0x14f = 335 | 1.31 | `.AccelerateBasedOnSlope`, ground |
| walk accel (already moving that way, or ice) | 0x104 = 260 | 1.02 | |
| walk max | 0x76c = 1900 | 7.42 | `_DAT_100a600a` |
| run accel turn / continue | 500 / 300 | 1.95 / 1.17 | RUN held |
| run max | 0xc80 = 3200 | 12.5 | `_DAT_100a600c` |
| double-speed power-up max walk / run | 0xd82 = 3458 / 0x15e0 = 5600 | 13.5 / 21.9 | `PTR_DAT_100a0620` |
| ground deceleration (no input) | 800; 300 while hurt-stunned (`_DAT_100a0748`); ice formula §3.3 | 3.1 | |
| air drag (no input) | 100; 600 in state `_DAT_100a0588` (= **on a rope**: the byte `.RopeCollide` sets to 1, §8.2 — fix-pass reading [HIGH for the write, MED that this is its only meaning]); 20 on the glider | 0.39 | ⚑ corrected (deepening 2026-10-03): applied every airborne frame **regardless of input** (player-states-2 corr.; ⚑ corrected (review 1c, 2026-10-03) #15: not re-derived by review 1c — the drag site was not located by constant in `1004d5fc..10054ca8`; the label is the reader's); the glider's 20 also on the ground (spells-detail C10) |
| air control | ±0x14a = 330 per frame up to walk/run max | | not on ground, not swimming — ⚑ corrected (deepening 2026-10-03): asymmetric — LEFT only in plain air, **RIGHT in every non-cling state** (ground, rope, swim, air), so ground right accel = 0x14f/0x104 + 0x14a (player-states-2 corr., raw `10053748..100539a8`) |
| air control in `_DAT_100a0588` state | ±1000 per frame, clamp ±0x960 = 2400 | | |
| swim horizontal | ±0xd2 = 210 up to ±0x76c | | `_DAT_100a0714 ≠ 0` |
| jump impulse | `vy = 0; vy += J + (−0xc80 − ((|vx| + 0x4e2) >> 3))`, cap 8000 | −13.1 at rest | J = `_DAT_100a0678`: carried platform vy, or −0x898 (−2200) with High Jump |
| jump hold | the impulse is re-applied each frame JUMP is held, while the counter (6 on ground, 3 when leaving a rope/ladder) > 0 | | `_DAT_100a0764` — ⚑ corrected (deepening 2026-10-03): 3 = clinging to a wall; rope = 6 (`.RopeCollide`); ~~refilled only while JUMP is up~~ ⚑ corrected (review 1c, 2026-10-03) #8 (= review 1b #7): the refill is the `else` of `glider == 0 ∧ JUMP ∧ charge < 1` (main l. 44962–44973), so it also refills with JUMP held while gliding or with charge ≥ 1 — no coyote time, no buffer (player-states-2 corr., player-states §5) |
| swim stroke | `−0x640 − ((|vx|+200)>>3)`, halved on later strokes, cap 2000; gravity 0x50 | | in water |
| spin jump | DOWN + JUMP with counter 1..6 → spin flag, sound | | ⚑ corrected (deepening 2026-10-03): also refills the counter to 6 (cooldown 20) → a second rise; DOWN alone with counter 1..5 also spins (player-states-2 corr.) |
| wall-climb vertical | vy = −1000 (UP) / +1000 (DOWN) / 0, or ±0x578 = 1400 with Double Speed | 3.9 | climb state `_DAT_100a0758 ≠ 0` (§3.4) — ⚑ corrected (deepening 2026-10-03): effective **±900** (±1300 Double Speed): a same-frame ±100 ease (player-states-2 corr., raw `1004ea5c..1004eacc`) |
| wall jump | JUMP while clinging: vx = +0x8ca if the wall side `PTR_DAT_100a074c` is 1 else −0x8ca; vy = 0 (−0x8cb when the counter is 3) | 8.8 | ⚑ corrected (deepening 2026-10-03): the counter is 3 while clinging, so the jump-sustain arm runs in the same call: net ~~vy = −3610~~ **vy = −3637** = −0xc80 − ((0x8ca + 0x4e2) >> 3) = −3200 − 437 (⚑ corrected (review 1c, 2026-10-03) #1, = review 1b #3; raw `10053f54 li r0,0x8ca`, `100541c4`/`10054240 addi r0,r3,0x4e2`); the −0x8cb store is dead (player-states-2 corr.) |
| magic-carpet ride (ridden sprite type 0x438/0x439) | the **carpet's** vx ±0x140/frame (cap ±0xc80), vy ±0x100/frame (cap ±4000) from the arrows; player vx forced 0 | | `PTR_DAT_100a05a4` |

Additional rules read in `.HandlePlayerSprite`:
- Deep "type 5" liquid (`s+0x128 == 5`) scales max walk/run by submersion:
  `f = (bodyHeight − depthClamp)·256/bodyHeight`, `max = 0x76c − f·0x3b6>>8` (walk),
  `0xc80 − f·0x640>>8` (run); vertical speed × **0.65** (`dRam100a1a30`; `tools/const.py 100a1a30` →
  bytes `3fe4cccccccccccd`, f64 0.65) [HIGH] ⚑ corrected (review 2026-10-03) #6. Kind 5 is desert **quicksand** by where it
  occurs (§5.1) [MED].
- Level side-push hdr+0x272c (−320 in level 15): airborne vx drifts by v up to 5·v; grounded
  x += v/4 per frame [HIGH].
- Camera look-ahead and focus: engine.md §5.
- Hot rect: `(l,t,r,b) = (0x26,0x22,0x3e,0x55)` = 24×51 px inside the 100×120 cell; crouching
  with a shield changes it; on the glider `(0x37,0x3e,0x63,0x61)`. ⚑ corrected (deepening 2026-10-03): every ground crouch
  uses `(0x26,0x37,0x3e,0x55)`; the shield extends it forward 0..7 px (player-states-2 corr.).
- Glider ⚑ corrected (deepening 2026-10-03): the full model (pitch-dependent gravity 20..120 and wind scale, fall cap
  2000, climb floor −2500, 12 grounded frames end the glide, no other cancel, blocks the
  Resurrection Necklace) is spells-detail §5 (closes INDEX NOT-RESOLVED 7).

## 5. Health, hazards, death

### 5.1 Values  [HIGH]
- Health: `G+4` and the player's `s+0xa4`; max `G+0xa` (start 560 = 0x230). Magic `G+0xe`, max
  `G+0xc` (start 560). Bars are value>>3 px, max 196 px (`.UpdateHealthMagic`).
- Breath (oxygen): `G+6`, never above health; refilled on surfacing. While
  `.ShouldEmitBubbles` is true it drops 1/frame (8/frame in kind-5 liquid); at 0 (and not
  invulnerable) a 30-frame (15 in kind 5) countdown `G+8`, then breath sound, **−0x70 HP**,
  `+0x116 = 0x28` (40 invulnerability frames), countdown re-armed, repeating. Arithmetic:
  `.HandlePlayerSprite`, handler dump lines 2461–2487 (function-relative 1810–1836); the
  countdown is re-armed to 0x1e when the gate is false (l. 2743) [HIGH] ⚑ corrected (review 2026-10-03) #11.
  `.ShouldEmitBubbles @ 1004ba14` is **not** "underwater" in general: it returns 1 iff the
  player is not dying and `0 < s+0x120 < 0xf` (previous frame's `+0x11c`). `.HandleUnderWater`
  computes `+0x11c = surfaceY − s+0x0a − face top inset` clamped ≥ 1, i.e. the height of the
  sprite's visible top above the water line, 1 when fully under — so the gate is "visible top
  less than 15 px above the surface or below it" [MED: face-inset meaning of `*(short*)s+0xc0`
  inferred]. (Fix-pass note: this also makes §0's "+0x11c depth below surface" read as
  "top-above-surface, clamped ≥1"; physics §4's "depth == 1" = fully submerged.)
- Liquids (`s+0x128` = BG water kind − 200), after 2 frames inside: kind 0 hurts only on levels
  with hdr+0x26cd ≠ 0 (30, 31 — the "freezing-cold water" levels); kinds 1 and 2 always hurt:
  −0x70 HP, 60 invulnerability frames, 13 flash frames, cooldown `_DAT_100a06d8 = 35` frames,
  only while HP > 4; kind 3 heals per frame: breath +8, HP +4, magic +4 up to max (the
  manual's "Ziridium Brine"); kind 5 is the slow-sinking liquid of §4 [HIGH for arithmetic].
  With a walk-on power-up active, a water cell whose kind equals the power-up's kind is
  resolved as solid floor 16 px higher instead (`.HitPlayerTileSprite`) [HIGH]. Kind names:
  0 water, 1 acid, 2 lava by the power-up order (spheres 1331 Solid Water, 1332 Solid Acid,
  1333 Solid Lava → kinds 0,1,2; `.HitPlayerSprite` handler dump l. 3755 (function line 601)
  `PTR_DAT_100a063c = type − 0x533`) [MED]. Level census (reviewer's Python over the
  `0x29a0` BG-kind tables × BG maps, REVIEW-2026-10-03 #8; not re-run in the fix pass): kind 2
  occurs **only** in the fire levels 50/51/52/55 (693/1205/394/52 cells) → lava; kind 0 is River
  of Fears' 6,144 cells plus the two `0x26cd = 1` ice levels → water; kind 5 occurs only in 22/40/45
  (The Labyrinth, Parched Earth, The Dig) → desert **quicksand**; kind 3 (heals) is small pools in
  22 levels. Labels: 0 water / 2 lava / 5 quicksand [HIGH on code + census]; 1 acid [MED,
  power-up order only] ⚑ corrected (review 2026-10-03) #8.
- `.HurtPlayer @ 1005473c (p, attacker, dmg, blood, invul, coinsLost)`: ⚑ corrected (review 1a,
  2026-10-03) #1: first returns 0 (no damage) when the attacker's HP `+0xa4` < 1 unless its handler
  is EnemyShot (TOC −0x73b8) or Box (−0x73bc) — dead or dying enemies never hurt (raw `10054768 lha
  r0,0xa4(r4)`; `cmpwi 0; bgt 1005479c`; else `10054794 li r3,0`) [HIGH]; otherwise `HurtSprite(p, dmg,
  attacker.vx, −1000, invul, 12)`; on a hit: if a Multi Crystal (item 0x13) is held, 4 crystal
  shards fly and a 15-frame timer later removes one crystal; climb/spin/pull-up states end;
  scream sound by damage (< 0xe0 vs larger); `coinsLost` (randomised ±1 when > 2, capped at
  `G+0x10`) coins are subtracted and spawned as 0x516 pickups.
- Damaging surface / ice: §3.3. Fire sprites 0x4b8, 0x4bb..0x4bd: −0xe0 unless Fire Charm (item
  0x18); lava/acid pools (Box class 0x5a0, mode `s+0x14c` 1/2): −0x70 / −0x150 unless the
  matching walk-on power-up or (lava) Fire Charm (`.HitPlayerSprite`).
  ⚑ corrected (deepening 2026-10-03): the Fire Charm protects only from fires with p1 ≤ 0 (`+0x14c ≤ 0`; tinted fires in
  level 62 burn through it) (triggers-background §2.4, enemy-shots-and-damage corr. 3; ⚑ corrected (review 1c, 2026-10-03) #15:
  not re-derived by review 1c — label is the readers'). ~~lava/acid
  pools (Box class 0x5a0)~~: the hurting 0x5a0 sprites are the Effect-class **geyser-column
  segments** (`.HandleGeyserSegSprite`, ±300 knockback) and the Box geyser head 0x5a9 when stood on
  (±400), both via `.HurtSprite` (no coins); a Box-class 0x5a0 never reaches that test because
  the Box arm of `.HitPlayerSprite` returns first (enemy-shots-and-damage §3.3–§3.4; synthesis
  check of the dispatch, handler dump l. 3859/4214; triggers-background-2 §2.2's "any sprite of
  type 1440" needs that qualifier). ⚑ corrected (review 1c, 2026-10-03) (adjudication A2): settled
  from raw — the Box/SeeSaw arm `10056b2c..10057860` (entered at `10056b18` on TOC −0x73bc / −0x7678)
  leaves by 25 branches, all to the epilogue `1005855c`; the hazard arm `10058458..10058494` is entered
  only from `10057e00` on the non-Box path. Only **non-Box** type-1440 sprites hurt [HIGH].
  `.HurtPlayer` refuses dead attackers (HP < 1) except enemy
  shots and boxes [HIGH, raw `10054768..10054798`], takes the knockback from the attacker's own vx, skips the Multi-Crystal loss for
  Blobs and spikes, randomises coins only when n > 2 (enemy-shots-and-damage §3.7; ⚑ corrected
  (review 1c, 2026-10-03) #14: these three are the file's readings, **MED here** — spot-checked
  consistent: `1005476c lwz r5,0x24(r4)`, handler compares −0x7380/−0x73c0 at `100547c4`/`100547d0`,
  `cmpwi 0x3`/`0x2` at `1005486c`/`1005487c`). Per-class contact damage: enemy-shots-and-damage §3.4–§3.5.
- Death power-up sphere (0x53b): −0x380 HP.

### 5.2 Death sequence  [HIGH]
When HP ≤ 0 the dying counter `_DAT_100a069c` runs (animation frames, hot rect drifts 2 px/frame
after frame 8). At frame 80 (100 if `PTR_DAT_100a0560`): if the Resurrection Necklace (0x17) is
held, not on the glider, not killed by the debug key, and inside the map → revive: counter back
to 30, revive animation, at the end HP = breath = max, necklace removed, 60 invulnerability
frames; otherwise `DAT_100a5106 = 1` ends `.GameLoop` → `.DeathEffect` (engine.md §6).

## 6. Wind and currents  [HIGH] ⚑ wave 2 corr (2026-10-04) T2 W1 (orientation was [MED])
Overlay layer o1 in 0..15 at the sprite's centre cell with strength o2 > 0 (`.StandardSpriteHandles`):
`dir = (o1 + 18) mod 36`; `.LookupModedImpulse(dir, o2·15)` gives a vector from a 36-entry
10°-step table (dir 0 = (−m, 0), dir 1 = (−0.985m, +0.174m), …; doubles at 0x100a1890..18c8);
if the sprite is not already moving faster than the impulse in that direction, a second
lookup with `o2·14` (scaled by `s+0x90/256` when < 255) is applied: x += ramped (over 33 frames)
horizontal part, vy += vertical part; flag `s+0x92` set. Water current: §2.
⚑ wave 2 corr (2026-10-04) T2 W1: orientation **HIGH** — o1 = k blows toward k·10° counter-clockwise from screen-right (0 right,
9 straight up, 12 up-left, 15 = 150°; nothing downward); the h part moves the **x position** (33-frame
ramp), the v part is added to vy (`10036b78..10036c14`; axis cases via jump table `0x100a5724` →
`10040e2c`/`100412dc`/`100404cc`/`1004097c`). The overlay drives wind only — water currents are
`hdr+0x2714` (§2) — in or out of liquid. Shipped wind: levels 10 and 20 only, 96 % o1 = 9 updrafts
(triggers-background-2 §8.4).

## 7. Enemies (classes from world-data-format.md §3.5)  [MED]

Callbacks per class (`.Setup…/.Handle…/.Hit…/.Hit…Tile…/.Kill…`, addresses in
`tools/targets.txt`). Values read from each Setup (several HP values = variants selected by
type/params, conditions not traced — ⚑ corrected (deepening 2026-10-03): the selection rules are now traced, table §7.1):

| class | HP (`+0xa4`) values in Setup | gravity `+0x110` | hot rect (first SetRect) |
|---|---|---|---|
| Walker (goblins, 1700..1769) | 500, 2000, 1500 | 0x151 = 337 | (0x28,10,0x3c,0x46) |
| Crawler (1712) | 1000, 500, 300, 1600 | ±0x151 (−337 = ceiling crawler) | (0x14,0xc,0x2c,0x21) |
| Roach (1720) | 200 | 0x151 | (0x23,0x1b,0x44,0x2d); vx 0x4b0 |
| Blob (1730..) | 1500, 700, 1100, 2000 | 0xfa | (0xe,0xc,0x2f,0x21) |
| Bat / insect swarms | ~~100, 200~~ ⚑ corrected (review 1a, 2026-10-03) #5: 500 (1740..1749, raw `1007dcc0 li 0x1f4`), 100 (1850.., `1007dde0`), 200 (insects, `1007e144`), 100 (swarm) | 0 | varies |
| Gremlin (1770..) | 500 | 0 | (0x28,0x26,0x59,0x50) |
| Floater (1780..) | 500 | 0 | (0x17,2,0x38,0x5c) ⚑ corrected (review 1a, 2026-10-03) #5 (adjudication B25): = the unplaced 1790..1799 variant; the shipped 1780 Wraith is (0x23,1,0x3e,0x4b) (raw `10081550..1008155c`), no tile callback |
| Frog (1800..) | 500, 350, 1000 | 0x8c | (0xb,0x14,0x48,0x49) |
| Salamander (1810..) | 500 | 0x8c | (0xe,0x14,0x42,0x49) |
| Warrior (boss, 1820) | 1200, 2000 | 0x122 | (0x1a,0x17,0x4a,0x3a) |
| Wizard (boss, 1830) | 1200, 1000 | 0x122 | (0x42,0x1e,0x7c,0x7e) |
| Dillo (armadillopine, 1870..) | 500, 1100 | 0x122 | (0x1a,0x17,0x4a,0x3a) |
| Crab (1890..) | 1000 | 0 | (0x18,0x18,0x4c,0x4c) |
| Chief (goblin chief boss, 1910) | 1200, 2000 | 0x276 | (0x5e,0x55,0xa5,0xd4) |
| Demon (fire guardians, 1920) | 1000, 2000 | 0 | (0x1a,0x17,0x4a,0x3a) |
| Xichra (final boss, 1990) | 5000 | 0 | (0x5c,0x3a,0x93,0x90) |

### 7.1 HP selection, behaviour, damage  ⚑ corrected (deepening 2026-10-03)

| class | HP selection rule (raw evidence in the file cited) | file § |
|---|---|---|
| Walker | by placement **p3** (tier 0..6) and type: 1750 → 500/500/1200/1680/2000/1500/1350, other types → 500/250/675/950/1500/850/750; only 1700/1705/1750/1760 have behaviour | enemies-ground §3.1 (raw 10067608–10067758) |
| Crawler | by **p2**: 0 → 500, 1 → 300, 2 → 1000, 3 → 1600; p1 = 0 → ceiling (gravity −0x151) | enemies-ground §4 |
| Roach | 200 (single) | enemies-ground §5 |
| Dillo | by type: 1870 → 500, 1871 → 1100 | enemies-ground §6 |
| Blob | by type: 1730/1731/1732/1733 → 700/1100/1500/2000; 1734..1739 → 0 | enemies-water-cave §3.1 |
| Bat | by type sub-range: 1740..1749 → **500** (raw `1007dcc0`; the old "100, 200" was wrong for them), 1850.. → 100 (p1 < 0: harmless background bat), 1860.. insects 200, swarm 1869 + members 100 | enemies-flyers §3.1 |
| Gremlin / Floater | 500 / 500; the Wraith takes **no** damage from player shots (statue only) and has no death path | enemies-flyers §4, §5.3 |
| Frog | by **p1**: 0 → 350, 1 → 500, 2 → 350, 3 → 1500, 4 → 1000, else 500 (also tint and score) | enemies-water-cave §1.1 |
| Salamander | 500 (single); lava-immune in effect | enemies-water-cave §2 |
| Crab | 1000, **never reduced** (invulnerable claw) | enemies-water-cave §4.4 |
| Warrior / Wizard / Chief / Demon | by **p4** (boss flag): 0 → 1200 / 1200 / 1200 / 1000, ≠ 0 → 2000 / **1000** / 2000 / 2000 | bosses §1.1, bosses-2 §5.1 |
| Xichra | 5000 fixed; 9999 at phase 6 | bosses-2 §6 |

The table above (§7) lists the **Setup** hot rects; boss Handles replace theirs every frame
(bosses-2 corr. 1). Behaviour per class: enemies-ground.md (Walker, Crawler, Roach, Dillo),
enemies-flyers.md (Bat, Gremlin, Floater), enemies-water-cave.md (Frog, Salamander, Blob, Crab),
bosses.md / bosses-2.md (Warrior, Wizard, Chief, Demon, Xichra), enemy-shots-and-damage.md (every
enemy projectile, contact damage per class, `.HurtPlayer`). What hurts each boss: bosses §1.5.

~~Behaviour patterns (patrol/turn rules, attack timers, projectile types) are in the 22
`.Handle<Class>Sprite` routines (e.g. `.HandleWalkerSprite` 763 lines, `.AxGoblinCoreLogic`,
`.RandomDilloAttack`, `.RandomWarriorAttack`, `.ShootSpines`, `.HandleDemonSegs`,
`.UpdateXichraCannons`) — **NOT RESOLVED** in this pass.~~ (was the review-pass text; now the
files above.) Shared facts: enemies hit by a player
shot whose `+0x04 == 1` call `.TurnIntoStatue` (120-frame statue, handlers swapped to the statue
set) [HIGH, 12 call sites found by a `bl` scan]. `+0x04` of a player shot is the **spell id**,
not the spawn type `id·256+power`: `.SetupPlayerShotSprite @ 1005925c` does
`*(uint *)(s+0x170) = type & 0xff; *(short *)(s+4) = (char)(type >> 8)` (handler dump
l. 4929–4930) before anything reads it, so the statue test means "Statue spell (id 1)" and a
replica must store the id in +4 and the power in +0x170 ⚑ corrected (review 2026-10-03) #3. ~~The Statue/Box/Platform classes
set `+0x185` (one-way top, §8.1) [MED].~~ ⚑ corrected (deepening 2026-10-03): the statue does **not** set `+0x185`
(statues are full solids through the Box callbacks); Box sets it per type and every Platform is
one-way by default (§0 row). ⚑ corrected (review 1a #5, 2026-10-03)
(marker added ⚑ corrected (review 1d, 2026-10-03) #4): raw — `.TurnIntoStatue` `li r6,0x78` → `+0x130` (1004316c/10043194),
`+0x134 ← +0xb8` (10043198–1004319c); thaw `lha 0xa4; subi 0xc8; sth 0xa4` (1006656c–10066574);
no store to `+0x185` (or a word covering it) in 100664a8–100665bc or 10043138–100431c4 [HIGH]. The statue lasts 120 frames, hangs without gravity, blinks on odd
counts below 20, and **costs 200 HP when it ends** — the shot's own damage is never applied
(enemies-ground §2.2, enemy-shots-and-damage §2.2; raw `10066570`). No boss can be petrified
(bosses §1.5). For the Floater the statue is the only effect of a player shot (enemies-flyers §5.3).

## 8. Non-enemy sprite physics → `physics-sprites.md`

⚑ corrected (deepening 2026-10-03): §8 (8.1 sprite solids / PlatformBounce, 8.2 ropes, 8.3
springs, 8.4 FootPressure, 8.5 programmed paths, 8.6 flotation and quicksand, 8.7 landing effects,
8.8 panting, 8.9 platform modes) moved, numbering and text kept (deepening corrections marked in place), to **`physics-sprites.md`** — this
file had passed the ~650-line split rule. References to "physics §8.x" mean that file.
