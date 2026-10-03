# Ferazel's Wand 1.0.3 — spells, items, pickups, power-ups, HUD

Register: code readings only; **nothing behaviour-verified**. Labels per claim (INDEX). Names
in quotes are from the shipped manual (`Ferazel's Wand Documentation`, TEXT 132 "Spells and
Power Ups") or from PICT resource names in the Sprites file; the binary itself has **no spell or
item name strings** (data-section string scan, this session) — every id→name pairing below is
therefore at most [MED], with the evidence named. `G` = game globals (engine.md §9).

## 1. Inventory model  [HIGH]

27 slots × 10 bytes at `G+0x24` (`.InitGameGlobals`, `.HasItem @ 1004c0e0`,
`.RemoveItem @ 10045594`):

| slot off | type | meaning |
|---|---|---|
| +0 | i16 | id (−1 = empty) |
| +2 | i16 | count (clamped to 99 on pickup) |
| +4 | i16 | −1 at init (no reader traced) |
| +6 | i16 | 0 at init |
| +8 | u8 | 1 = **spell** slot, 0 = item slot (spell and item ids are separate namespaces) |

- New game: slot 0 = spell 0 (count 1), slot 1 = item 0 (count 1); the rest empty
  (manual: starts with the dagger and the Fireball spell) [HIGH].
- `G+0x172` selected slot; Next (action 8) / Previous (7) step it ±1 with wrap to the last
  non-empty slot, 12-frame key-repeat (`.UpdateStatusBar @ 100095dc`) [HIGH].
- `.HasItem(id)` / `.RemoveItem(id)` only match **item** slots (flag 0). RemoveItem decrements
  the count; at 0 the slot is removed and later slots shift down, selection adjusted [HIGH].
- Picking up an item id that is already held adds to its count; otherwise the first empty slot
  is used (`.HitPlayerSprite`); scrolls (§3) add spell slots the same way [HIGH].

## 2. Casting (`.HandleKeys @ 10052ac0`, `.HandlePlayerSprite`, `.CastSpell @ 10051d1c`)  [HIGH]

1. USE (action 6) with the selected slot a spell, no cast in progress, not in the mist/potion
   states: if magic `G+0xe ≥ 1` → start the wand animation (`_DAT_100a06ec = 1`,
   `_DAT_100a06d4 = 3`); if magic is 0 → the selection jumps to the first item slot holding
   item 0 or 0x15 (the dagger / Vorpal Dirk).
2. The animation counter reaches 4 → `.CastSpell(player)` if magic > 0 still. Magic is
   decremented by the spell's cost **without a floor check** (can go negative by up to cost−1).
3. `CastSpell` spawns `MTNewSprite(type = spellId·256 + power, x, y, layer 11, …,
   SetupPlayerShotSprite)`; `power = 1 + count(Multi Crystal 0x13)` (but not +1 while the
   crystal-loss timer `_DAT_100a073c > 1`). That composite value lives only in the spawn call:
   `.SetupPlayerShotSprite @ 1005925c` immediately rewrites the fields —
   `*(uint *)(s+0x170) = type & 0xff; *(short *)(s+4) = (char)(type >> 8)` (handler dump
   l. 4929–4930) — so for the shot's whole life **`+0x04` = spell id** and **`+0x170` = power**.
   Every reader (`.HandlePlayerShotSprite`, enemy Hit routines, the statue test of §2.1) sees
   the id [HIGH] ⚑ corrected (review 2026-10-03) #3.
4. Spawn point: player x + 0x26 (+30 on the glider), y + 0x33 (+0x42 while crouching —
   `_DAT_100a071c`, the crouch counter of `.HandleKeys`; +0x23 more on the glider, +8 in the
   0x588 state); spells 5 and 6 use their own offsets (below).
5. Initial velocity (ids 0,1,2,3,4,7): `vx = |player.vx/2| + rand(100) + carried + 0xd2f`
   (0xd2f = 3375 → 13.2 px/frame), `vy = player.vy/2`; holding UP adds `vy −= 1500, vx −= 750`;
   ids 0,1,3,4 add an upward arc `vy −= 1500` (`−1000` while crouching); every shot then gets
   `vy += rand(75) − 40`. Facing left negates vx (inverted while climbing walls 1/2).
6. Shadow Double power-up: a second copy of the shot is spawned at the double's offset with the
   same velocity (`_DAT_100a0658`).
7. `.SetupPlayerShotSprite @ 1005925c`: after the +4/+0x170 split of item 3, power
   (`+0x170`) ≥ 2 spawns `power−1` trailing copies (max 4, i.e. 5 sprites) spaced 6 px (10 px
   for ids 6 and 0x3c); first frame of `.HandlePlayerShotSprite`: damage `+0xa4 ×= power`, and
   a light is attached ⚑ corrected (review 2026-10-03) #3.

### 2.1 Spell table

| id | name (evidence) | MP cost | damage `+0xa4` | launch | shot gravity `+0x110` | behaviour read in code |
|---|---|---|---|---|---|---|
| 0 | "Fireball" — starting spell; PICTs 1100/1101 'fireball right/left' | 8 | 100 | arc | 250 | particles; light 0x16 |
| 1 | "Statue" — enemy Hit routines call `.TurnIntoStatue` when hit by a player shot (handler `PTR_PTR_100a04e8`) with `*(short *)(shot+4) == 1`, i.e. spell id 1 after the §2 item-3 rewrite (12 sites: `.HitPlatformSprite` (handler dump l. 9160–9164) and the Crawler, Walker, Roach, Blob, Bat, SwarmMember, Gremlin, Floater, Frog, Salamander, Dillo Hit routines — the bosses have none) ⚑ corrected (review 2026-10-03) #3 | 32 (0x20) | 200 | arc | 250 | target frozen 120 frames (`+0x130 = 0x78`) |
| 2 | (unnamed, not in the manual) | 10 | 100 | flat | 0 | trail particles; a scroll of id 2 is converted to id 3 on pickup |
| 3 | "Ice Wall" — on entering water spawns Platform 0x57c (ice floe) at the impact | 30 (0x1e) | 300 | arc | 250 | particles; light 0x4d |
| 4 | "Tree Trunk" — hitting tree sprites 0x2c8/0x2c9 adds a trunk segment 0x2c9 on top | 8 | 100 | arc | 250 | light 0x42 |
| 5 | "Boomerang" — after 12 frames homes on the player (accel 800, max 0x1450); caught by the player → `G+0xe += 8` (refund) | 8 | 100 | speed 0xed8, vy −0x80, spawn y +0x20 | 0 | (manual: "not affected by gravity") |
| 6 | "V Blade" — two shots, vy −4000 and +4000 (2nd has 150 dmg) | 8 | 150 | up+down from x centre −20 | 0 | despawn beyond ±500 px vertically |
| 7 | (unnamed) | 12 | 150 | arc-less | 250 | hot rect 16×16 |
| 0x3c, 0x50, 0x5a | non-spell player shots (held/thrown items, §4) | — | — | — | | |

Costs/damages/speeds: `.CastSpell` switch arms; gravity: `.SetupPlayerShotSprite` switch
[HIGH for numbers; names [MED] as stated]. Manual order (Fireball, Boomerang, Tree Trunk,
Statue, Ice Wall, V Blade) = six spells; ids 2 and 7 are never granted by the debug "give
items" key (which grants spells 1,3,4,5,6) [HIGH for the debug list] and no shipped scroll was
checked for them [NOT RESOLVED: scroll sprite params in the levels].

## 3. Pickups (sprite class Bonus; `.HitPlayerSprite @ 100556f4`, `.HitBonusSprite @ 1005fd38`)

Score is `G+0` (i32), coins `G+0x10`, gold-Xichron counter `G+0x14` [HIGH from the arithmetic;
names from the manual]. Type → effect when the player touches it [HIGH arithmetic; [MED] names]:

| type (dec) | PICT name / manual | effect |
|---|---|---|
| 1055 (0x41f) | gold Xichron (animated 'Bonus crystal' strip) | score +10, Xichrons +1 |
| 1056 (0x420) | big Xichron | score +1000, Xichrons +100 |
| — | every 100 Xichrons | Xichrons −100, item 0x16 (Red Xichron) +1 (count ≤ 99) |
| 1290 (0x50a) | '$Big magic crystal' | magic +0x2a0 (672), score +100 |
| 1291 (0x50b) | '$Big health crystal' | HP +0x2a0 (`G+4`, breath `G+6`), sprite HP +0xe0 (sic), score +100 |
| 1292 (0x50c) | '$Moneybag, small' | coins +5, score +25 |
| 1293 (0x50d) | '$Moneybag, big' | coins +25, score +100 |
| 1300 (0x514) | 'magic bonus' (green crystal) | magic +0xe0 (224), score +25 |
| 1301 (0x515) | blue crystal | HP +0xe0, breath +0xe0, `G+8 = 30`, score +25 |
| 1302 (0x516) | coin (also dropped by `.HurtPlayer`) | coins +1, score +5 |
| 1305 (0x519) / 1306 (0x51a) | coins | coins +10 / +100, score +5 |
| 1303, 1307, 3100..3109 | containers ("sparkly torches and rock piles", sign text): a **player shot** opens them: score +150; spawns 1300 (magic) if magic% < health% and HP > 37, else 1301 (health) (`.HitBonusSprite`) |
| 1340 (0x53c) | max-health upgrade | score +2000, flash, refill HP, max HP +0x70 (animated 8 per step) |
| 1341 (0x53d) | max-magic upgrade | score +2000, refill magic, max magic +0x70 |
| 1350 (0x546) | 'Air Bubble' | breath +0x230 (≤ HP) |
| 1330..1339 | power-up spheres | §5 |
| 2000..2049 | spell scroll | learns spell `type−2000` (2000: spell = record param 1; id 2 → 3); sound; status bar |
| 3200..3248 | item | item `type−3200` +1 (fire seeds 3206: +3); 3221 (item 0x15) first removes item 0 (dagger); 3215 (item 0xf) first removes 0xe (shield) |
| 3050 (0xbea) | hang glider | enters glider mode (`_DAT_100a05e0`) |
| 1057 (0x421), 1058 (0x422), 1059 (0x423) | triggers | 0x422: `G+0xad8 + 2·param1 = param2 (or 1)` (world flags); 0x423: sound if param1 ≠ 0, then its callback |

## 4. Items (item-slot ids)  [MED: names from manual order + code use]

| id | name | evidence in code |
|---|---|---|
| 0 | dagger | starting item; held-weapon sprite damage 100 (`.HandleItemUse`); replaced by 0x15 |
| 1, 2, 3 | keys | selecting shows "You don't need to select keys…" (`.HandleKeys` case 1–3, string 0x100a616f) |
| 4 | Magic potion | drinking (frame 20): magic = max |
| 5 | Health potion | drinking: HP = breath = max, sprite HP = max |
| 6 | Fire seeds | thrown at animation frame 5: shot 0x5a01, vx 0x60e (+player vx), vy −0x60e, damage 800 |
| 0xe | Shield | crouch + push away from facing raises it (`.ShieldBlock`); selecting shows the shield hint |
| 0xf | Magical Shield | replaces 0xe on pickup; bigger block animation; reflects shots [LOW for "reflects"] |
| 0x10 | Ring of Smiting | `.SmiteEnemies`, consumed |
| 0x11 | Escape Ring | ends the level with exit −1 (no unlock), skips the stage-complete effect, consumed |
| 0x12 | Hammer? (best melee: damage 300, `+0x158 = 4`, can crunch) | debug kit puts it in slot 1 [LOW name] |
| 0x13 | Multi Crystal | spell power +1 each; one is lost 15 frames after taking damage |
| 0x14 | (not seen in code) | NOT RESOLVED (Ice Pick?) |
| 0x15 | Vorpal Dirk | damage 200 ("double the dagger"); replaces item 0 |
| 0x16 | Red Xichron | counted currency; selecting shows the Xichron hint |
| 0x17 | Resurrection Necklace | revives at death (physics.md §5.2), consumed |
| 0x18 | Fire Charm | immunity to fire sprites 0x4b8/0x4bb..0x4bd and lava pools |
| 0x19 | Mist potion | drinking: spirit mode `_DAT_100a0574` (body sprite 0x45, timer `_DAT_100a0578 = 600` frames = 20 s at 30 Hz; manual says 30 s) |
| 0x1a | Ziridium seeds | like fire seeds with `+0xf4 = 1` (damage 0x578 = 1400 vs 800) |

Melee: USE with item 0/0x12/0x15 selected starts the stab (`_DAT_100a0698`); the held-item sprite
(`_DAT_100a065c`) carries the damage above and the 36 kick rects (`.InitPlayerKickRects`) are
the swing arc positions [MED].

## 5. Power-ups (spheres, `.HitPlayerSprite` switch 0x532..0x53b)  [HIGH arithmetic; names from PICTs]

| type | PICT name | timer (frames) | effect while active |
|---|---|---|---|
| 1330 | 'Sphere, Shadow Double' | 600 | spawns the double sprite 0x1b39 that mirrors casts |
| 1331/1332/1333 | 'Sphere, Solid Water/Acid/Lava' | 600 | `PTR_DAT_100a063c` = 0/1/2: that liquid is solid floor. Liquid-kind labels backed by the reviewer's per-level BG-kind census (kind 2 only in fire levels 50/51/52/55; kind 0 = River of Fears + the two ice levels; kind 5 = quicksand in 22/40/45): 0 water / 2 lava [HIGH], 1 acid [MED] — physics.md §5.1 ⚑ corrected (review 2026-10-03) #8 |
| 1334 | 'Sphere, High Jump' | 600 | jump base J = −2200 (physics.md §4) |
| 1335 | 'Sphere, Invincibility' | 450 (`+0x116 = 0x1c2`) | invulnerability frames |
| 1336 | 'Sphere, Featherfall' | 900 | gravity 64, fall cap 850 |
| 1337 | (unnamed; Double Speed) | 600 | max walk/run 3458/5600 |
| 1338 | '$Sphere, Pentashield' | until hit | +5 orbiting shields (max 8), 360°/n spacing, radius 0x30 |
| 1339 | '$Sphere, Death' | — | HP −0x380, 30 invuln/flash frames |
Timers count down once per frame in `.HandlePlayerSprite` (`.TickTock`); the sphere sprite's
`+0xa6` is set to the duration (32000 for Invincibility-with-param-0 and Pentashield) [HIGH].

## 6. HUD (status bar, 640×88 at screen y 392)  [HIGH]

`.UpdateStatusBar` copies the 640×88 status-bar port to (0,392), then:
- `.UpdateHealthMagic @ 10008430`: health bar = `G+4 >> 3` px (≤196) and breath overlay
  `G+6 >> 3` drawn from the 196×45 HUD piece (`PICT 133`) at x 214; magic bar = `G+0xe >> 3`;
  flashing colours while the pickup counters `PTR_DAT_1009fdbc`/`_DAT_1009fdb8` run; a tick
  sound each second of suffocation.
- `.UpdateTextStats`: score `G+0` at (27,19), coins `G+0x10` at (150,19), level name
  (hdr+0x25c4) at (27,46), font id 20.
- `.UpdateItemStat`: the selected item / spell and the inventory strip (manual: green
  highlight) [MED: drawing not transcribed].
- `.WandGlow @ 10006b6c` is **not** a gameplay effect: it plays Titles PICTs 172..177 (82×82)
  forward then back, 5 ticks each, at (138,286), and is called only from `.AskToContinue`
  (the death/continue screen) [HIGH].
