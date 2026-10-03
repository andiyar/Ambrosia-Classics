# Ferazel's Wand 1.0.3 — held item / melee stab, Shadow Double, Double-Speed trail

Code readings only; nothing behaviour-verified. Date 2026-10-03.
Sources: handler dump `ghidra/Ferazel_handlers.decompiled.c`, main dump `ghidra/Ferazel_pef.decompiled.c`,
raw `ghidra/Ferazel_pef.disasm.txt`, `tools/const.py`/`tocrefs.py` (TVector = word + 0x1009f840),
`.InitSounds` slot map, Sprites-file PICTs (sips; PackBits decoder for 771), Mlvl record census.
Scope: Setup/HandleHeldItem, `.HandleItemUse @ 1004d054`, `.SetHeldItemPos @ 1004bf2c`, the USE-item
arm of `.HandleKeys`, the held item inside the player-shot handlers and the Hit routines that see it;
Setup/HandleShadow, `.ShadowBob @ 1004b410`; Setup/HandleTrail, `.DoubleSpeedTrail @ 1004d370`.
⚑ wave 2 (2026-10-04): §4 closes NR 1–3 and 6 (list order, mirroring, `+0x11c`, door `+0xa0`, crunch kinds, revive).

Handler slots used below [HIGH, each resolved through its TVector this session]:
`0x100a0524`/`0x100a04f8` → Setup/Handle HeldItem (`1004bdd0`/`1004be74`); `0x100a04e8` →
`.HandlePlayerShotSprite 10059704`; `0x100a04e4` → `.HitPlayerShotSprite 1005a7fc`; `0x100a04e0` →
`.HitPlayerShotTileSprite 1005b0bc`; `0x100a04dc`/`0x100a0500` → Setup/Handle Shadow (`1004b7d4`/
`1004b4f0`); `0x100a0518`/`0x100a0508` → Setup/Handle Trail (`1004b3b4`/`1004b354`).

## 1. The held-item sprite (one per level)

### 1.1 Creation and idle state  [HIGH]
`.SetupPlayerSprite` (handler dump l. 305–307): `MTNewSprite(100, 0, 0, layer 0x14, rec 0x1ff,
SetupHeldItemSprite)`, pointer kept in `*_DAT_100a065c`. `MTNewSprite` clears the 0x1fc-byte record
(`_MemoryClear`), so `+0x170` (power), `+0xa6`, `+0xa4` start 0. Setup (l. 598–618): type 100, face 0,
position (0,0), layer 0x14, hit and tile callbacks 0, handler HandleHeldItem, rect
`SetRect(−2,2,0x1a,0x16)` (top 2, left −2, bottom 0x16, right 0x1a).
`.HandleHeldItemSprite` (l. 620–650; raw `1004be74–1004bf00`): v = 0, fixed point re-synced from the
integer position, old position = position, layer 0x14, type 100; if a face is set, hot rect = face
record bytes +8..+0xf (`lwz 8/0xc` → `stw 0x34/0x38`, no hidden +8) with **left +1 and right −1**; a
negative `+0xa6` counts up to 0. It never moves the sprite, never calls `.StandardSpriteHandles`.
`.HandlePlayerSprite` zeroes the held face **every frame** before state selection (handler l. 1397),
so outside a swing the item is invisible; its position and rect stay where the last swing left them.
Only `.HandleItemUse` re-faces and re-places it. `.ClearPlayerVars` zeroes the pointer and the counter
(main dump l. 42371–42403); `.SetupPlayerSprite` then recreates the sprite.

### 1.2 Starting a swing (`.HandleKeys`, main dump l. 44446–44680)  [HIGH]
USE (action 6) pressed with the selected slot an **item** (`+0x2c == 0`), shield not raised
(`PTR_DAT_100a05e8 ≤ 0`), not clinging (`_DAT_100a0758 == 0`), not on a rope (`_DAT_100a0588 == 0`):
the whole L/R/steering block is skipped this frame; USE latch `_DAT_100a075c` and spell latch
`_DAT_100a0760` = 1; if the latch was already set nothing more happens (one action per press). Item
switch: ids **0, 0x12, 0x15** → if counter `_DAT_100a0698 == 0` and not in spirit form
(`_DAT_100a0578 == 0 ∧ _DAT_100a0574 == 0`): snd **418 'dagger thrust'** (`_DAT_100a03e8`, vol 0x55),
counter 1, side flag `PTR_DAT_100a04f4 = (F == 1)` (latched for the swing), in-use item
`_DAT_100a5fd8` = id, `.MoveSelectedItemToFront`. Ids **6, 0x1a** (fire / Ziridium seeds): the same
with snd **704 'throw'** (`_DAT_100a0268`) and `.RemoveItem(id)` **at the press**. Item 8 (Hammer)
has no case and no `HasItem(8)` exists anywhere (all `_HasItem` call args: 0xe, 0xf, 0x18) — the
Hammer does nothing in code [HIGH for the absence in both dumps; manual says it breaks cave walls].
The glider flag is **not** tested: USE+item while gliding starts the counter (and plays the sound) but
`.HandleItemUse` is not called in the glider branch (§1.6), so the swing waits for the stow.
`.HandleKeys` early returns (potion drinking, boss grab, pull-up, dying, teleporter charge > 30) and
door transit (HandleKeys not called) also prevent starting.

### 1.3 The 10-frame swing (`.HandleItemUse`, main dump l. 43547–43650)  [HIGH]
Called from `.HandlePlayerSprite` state selection with the counter `c ≠ 0` (handler l. 2074–2076,
before the grounded/airborne branches, which are skipped for the whole swing) and inside the swim
branch (l. 1983–1985, after the swim face is set — the stab face overrides it). Per call:
1. idle counter `_DAT_100a068c` := fidget count `_DAT_100a0688` if > 0.
2. Player face: crouch depth `_DAT_100a071c ≠ 0` → set `_DAT_100a078c` (PICT 1035) else
   `_DAT_100a07cc` (PICT 1021), index `|c| − 1` (both 5 cells of 100×120).
3. Held face = `*(0x100a5f68 + 4·item)` = PICT **750 + item** (`.InitPlayerSprite` main l. 42252–42255
   loads 27 faces 0x2ee+i; only 750, 756, 768, 771 exist → a null face for every other id, incl.
   Ziridium seeds 0x1a → PICT 776 missing → **invisible held seed**), or 0 when item == −1.
4. Held `+0x158 = −1`, `+0xeb = 0` (raw `1004d138–1004d150`).
5. **Strike test** (raw `1004d154–1004d194`: `eqv/subfc/addze` idiom = signed `c < 3`): `c ≥ 3` →
   held handler = HandlePlayerShot, hit = HitPlayerShot, tile = HitPlayerShotTile (`1004d1b4–
   1004d1d4`); otherwise handler = HandleHeldItem, hit = 0 (`1004d198–1004d1ac`; tile callback left).
6. `.SetHeldItemPos` (§1.4).
7. Item switch (raw `1004d1e4–1004d30c`):

| item | name | `+0xa4` (damage) | `+0x158` crunch | `+0xeb` | raw |
|---|---|---|---|---|---|
| 0 | dagger | **100** | −1 (none) | 0 | `1004d208 li 0x64` |
| 0x15 | Vorpal Dirk | **200** | 1 | 1 | `1004d218 li 0xc8`, `1004d21c li 1` |
| 0x12 | Ice Pick | **300** | 4 | 1 | `1004d23c li 0x12c`, `1004d240 li 4` |
| 6 / 0x1a | fire / Ziridium seeds | **not written — stale** | −1 | 0 | at c == 5: throw (§1.8) |

8. `c += 1`; `c == 6 → −5` (`1004d310–1004d32c`).
Sequence of calls: c = 1,2,3,4,5,−5,−4,−3,−2,−1 → faces 0,1,2,3,4,4,3,2,1,0; then c = 0 and the swing
is over. **Strike frames = the calls with c = 3, 4, 5** (the 3rd–5th frames, faces 2–4, on the way
out); the return frames with the same positions are harmless. Cadence: a new swing needs c == 0 at
`.HandleKeys` time and a fresh press, so the fastest repeat starts 10 frames after the previous
(≈ 3 swings/s at 30 Hz), with at least one USE-up frame in between; presses during a swing are
dropped, not queued [HIGH]. While USE stays held the player has no L/R control (§1.2); after release
L/R works and the player can walk with the stab face (no walk cycle, no footsteps).

### 1.4 Placement (`.SetHeldItemPos`, main dump l. 42810–42880; raw `1004bf2c–1004c0b8`)  [HIGH]
`(dx, dy)` by `|c|`: 1 → (0x2d, 0x1e), 2 → (0x35, 0x1c), 3 → (0x42, 0x18), 4 → (0x47, 0x16), 5 →
(0x54, 0x11) (`1004bf6c–1004bfa0`); crouching → dy + 0xc (`1004bfb4`). Item cell top-left:
`y = (player.y_fixed >> 8) + dy + 0x16`; `x = (player.x_fixed >> 8) + dx` (side 0) or `+ (100 − dx)`
(side 1, `subfic …,0x64` at `1004c008`); then mirror flag `+0x17e` := the player's `+0x17e`, and if
set `x −= 0x20` (`1004c094–1004c09c`). Water: held `+0x11c = max(p+0x11c, p+0x120) + (held.y −
p.y)`, ≥ 1, when the player has water contact (read by nothing that affects a type-100 shot, §1.5;
⚑ wave 2 (2026-10-04): read by the draw only, §4.3).
The side flag is latched at the press but the mirror flag follows the player's current `+0x17e` (as
of the previous frame's facing pass): turning mid-swing (USE released) shifts the item 32 px and
flips its art without changing side [HIGH reading; on-screen effect MED].

### 1.5 Hit geometry  [MED: depends on the face +8 bounds rule, sprites-backgrounds-sounds §2.1, ~~and on the blitter mirroring within the 32-px frame~~ (⚑ wave 2 (2026-10-04): mirroring within the cell confirmed HIGH, §4.2)]
Item PICTs are 32×24. Opaque bounds (white = index 0) and the resulting hot rect (face+8 =
`(top, left−1 clamped 0, bottom+1, right+2)`, then left+1 / right−1 = the exact opaque box):

| PICT | item | opaque x / y | hot rect (left, top)–(right, bottom), cell-relative |
|---|---|---|---|
| 750 | dagger | 0..20 / 8..15 | (1, 8)–(21, 16) |
| 768 | Ice Pick | 0..28 / 8..15 | (1, 8)–(29, 16) |
| 771 | Vorpal Dirk | 0..22 / 7..16 | (1, 7)–(23, 17) |
| 756 | fire seeds | 1..9 / 8..14 | (1, 8)–(10, 15) |

`.CalcHotRect` (main l. 30158, `10032614`) only offsets `+0x34` by the position — **the hot rect is
never mirrored**. Strike-frame boxes relative to the player's 100×120 cell (player body x 38..62,
y 34..85; crouch adds 12 to y):

| c | dagger, facing right | dagger, facing left | Ice Pick right / left | y (standing) |
|---|---|---|---|---|
| 3 | x 67..87 | x 3..23 | 67..95 / 3..31 | 54..62 |
| 4 | x 72..92 | x −2..18 | 72..100 / −2..26 | 52..60 |
| 5 | x 85..105 | x −15..5 | 85..113 / −15..13 | 47..55 |

So the drawn (mirrored) blade and the hit box disagree when facing left: the box sits
`32 − (left+right)` px further out — dagger 10, Dirk 8, Ice Pick 2 — and the left-facing reach
beyond the body is 35/40/53 px against 25/30/43 facing right (dagger).
Collision timing [HIGH]: ~~`.GameLoop` runs `.MTHandleSprites` then `.MTCollideSprites` (main l.
4006–4007)~~ (⚑ wave 2 (2026-10-04): `.PaintFrameWrap` → `.HandleSprites` runs them, after the draw — platforms-ropes-radial-2 §8.1); the strike state set during the player's handler is live in the same frame's collision
pass. In strike frames the held item's own HandleHeldItem does not run, so its rect is the one set on
its last inert frame (same face) ~~[MED: active-list order]~~ (⚑ wave 2 (2026-10-04): HIGH — the player (layer 10) precedes the
held item (0x14), §4.1).

### 1.6 Interaction with other states  [HIGH reading]
`.HandleItemUse` is reached only from the swim branch and the generic `c ≠ 0` test (handler l. 1984,
2075). Branches that win earlier — glider (l. 1476), dying (1729), spirit (1813), boss grab (1848),
hurt-stun (1890), doors (1918), rope (1942), wall cling (2006) — **freeze the counter**; the swing
resumes when the state ends (nothing else writes `_DAT_100a0698`: `tocrefs` 100a0698 → ClearPlayerVars,
SetHeldItemPos, HandleItemUse, HandleKeys ×4 and two reads). Consequences:
- Frozen after a call with c = 3..5 (counter 4, 5 or −5): the held sprite **keeps the player-shot
  handler and hit callback**, invisible (face zeroed each frame), at its last position — an invisible
  stationary hit box that keeps damaging what walks into it for the whole stun / rope / cling / glide
  [MED for the in-play effect].
- Seeds pressed while gliding are removed from the inventory at once and thrown only after the stow.
- Crouching mid-swing switches to the crouch faces and lowers the item 12 px. Swimming: crouch is 0
  (zeroed by DOWN off the ground, else decays), the swim stroke counter keeps running under the stab face.
- Airborne: the air-animation counter and spin faces are not updated during the swing.
- Death: dying freezes the swing; no revive path writes the counter ~~[MED: revive not re-read]~~ (⚑ wave 2 (2026-10-04): HIGH,
  the swing resumes after the revive, §4.6).

### 1.7 What a strike does (the held sprite as a player shot, `+0x04` = 100)  [HIGH unless noted]
`.HandlePlayerShotSprite` (handler l. 5089–5568) on it: `.StandardSpriteHandles`; age `+0x14c` +1 to
200; no id arm matches 100; the power block (`+0x14c == 1 ∧ +0x170 > 0`) never runs (power 0), so
`+0xa4` is not multiplied and no light is added; positions are **not** recomputed for ids ≥ 100
(l. 5448–5457); `.SeparateFromTiles2` only when `+0x158 > 0` (l. 5410: Dirk, Ice Pick); no water kill
(ids < 100 only); **killed if its y > map height·32** (l. 5444–5446) — a stab near the map bottom
kills the held sprite and leaves `*_DAT_100a065c` dangling for the rest of the level [HIGH reading,
LOW in-play].
- **Enemies**: every enemy Hit routine treats it as a player shot (handler 0x100a04e8, `+0xa6 == 0`;
  enemies-ground §2.3, bosses §1.5) and applies `HurtSprite(enemy, held+0xa4, …)` with its own
  knockback/invulnerability; knockback derived from the shot's v is 0 (v = 0). `.HurtSprite` refuses
  damage ≤ 0 and any target with ~~`+0x116 > 0`~~ **`+0x116 ≠ 0`** (also negative; raw `10037058..1003709c` — ⚑ corrected (review 1c, 2026-10-03) #13) (main l. 32479ff), so with the usual 4–8 invul frames a
  swing lands **once** per target. **Statue never**: the 12 statue sites test `+0x04 == 1`.
- **`+0xa6` gate**: no code writes a non-zero `+0xa6` on the held item — raw scan of every `sth
  …,0xa6` in `1004b354–1004c000`, `1004d054–1004d370`, `100556f4–10058594`, `10059704–1005b670`: the
  only shot-side writes are 0x5a (0) and `.KillPlayerShot`'s > 100 arm, unreachable for 100. So the
  boss gate `shot+0xa6 == 0` always passes for melee (closes bosses-2 NR 4).
- **`.KillPlayerShot` returns at once for type 100** (`cmpwi r0,0x64; beq 0x1005b084` at
  `1005ac64–1005ac68`): a stab is never consumed, makes no impact sound or effect. The "dagger hit /
  `+0xa6 = −6`" arm (`1005accc–1005ad08`) runs only for `+0x04 > 100`, which no player shot has.
- **Crates 3090..3099** (`.HitBoxSprite` handler l. 13436–13442): HP −= held `+0xa4` on **every**
  overlapping frame (no invul gate) → `.KillCrate` at ≤ 0. **Box 2932** (0xb74, l. 13444–13449):
  HP −= dmg, `+0xa6 = dmg/20 + rand(dmg/40)`. Doors 2910/2911: the held item is one of the four handlers
  exempt from the door's `+0xa0 = 0` reset (l. 13427–13433; the only Hit-routine reference to the
  HeldItem slot, `tocrefs` 100a04f8 → `1007059c`).
- **Weakened ice wall 2941** (`.HitPlayerShotSprite` l. 5663–5672): only `+0xa4 == 300` → wall HP −80,
  flash/invul 10, snd **419 'dagger hit'** pitched 35000 — the Ice Pick (or stale 300, §1.8). Gates
  2940, Tree-Trunk boxes 712/713 (id-4 only), statues/solids with a top or surface fn
  (`.PlatformBounce` on the held item, position discarded next call): nothing breaks.
- **Enemy shots**: `.HitEnemyShotSprite` (l. 6340–6393) kills 0x6e1 goblin boulder, 0x6e2 bomb
  boulder and 0x753 Dillo egg-bomb on contact with any player shot — a stab splits/detonates them.
  Chief's 0x77b: snd 303 'metal hit' vol 0xab on each overlapping frame, nothing else.
- **Tiles** (`.HitPlayerShotTileSprite` l. 5697–5868): FG/BG arms skip id 100; only the crunch pass
  (`param_4 == 2`) calls `.CrunchTile(tile, +0x158)` (main l. 38956ff). With crunch kind k of the
  2×2 block: Dirk (1) — k 0 breaks at once, k 1/3 crack (crunch-sprite HP −1 per cooldown), k 2/4
  resist (rock-crack sound); Ice Pick (4) — k 0 and **k 4** break at once, k 1/3 crack, k 2 nothing
  unless a crunch sprite already exists. The dagger never touches tiles. (Seeds: strength 2 breaks
  k 0..3.) [HIGH arithmetic; ~~kind meanings NOT RESOLVED~~ ⚑ wave 2 (2026-10-04): kind behaviour table player-states-2 §13].
- The player is not hurt by it: `.HitPlayerSprite` has no type-100 arm [MED: hazard arm scanned by
  type, not exhaustively].

### 1.8 Seeds in hand  [HIGH reading]
Seeds run the same 10 calls: the hand shows PICT 756 (fire) or nothing (Ziridium), and **at c = 3..5
the held sprite is a live player shot with whatever `+0xa4` the last blade swing left** (0 if none
since level start → `.HurtSprite` refuses; 100/200/300 otherwise). At c == 5 the seed shot
`MTNewSprite(0x5a01, held centre x, centre y − 4, layer 0xb, −1, SetupPlayerShot)` is thrown
(`vx ±0x60e` + player vx, x +12 px when side 1, `vy −0x60e` + player vy if falling, Ziridium `+0xf4 = 1`;
raw `1004d260–1004d30c`; flight and blast: spells-detail §3.8, pickups-boxes §3.2) and the in-use item
becomes −1. The centre used is the one computed by the held sprite's last handler run, i.e. the c = 4
placement (SetHeldItemPos does not write `+0xe/+0x10`) ~~[MED: list order]~~ (⚑ wave 2 (2026-10-04): HIGH, §4.1).

### 1.9 No carrying  [HIGH for the item path; MED as a global absence]
No routine name in either dump mentions carry/lift/throw/pick/grab, and the USE-item switch has no
case that attaches a Box or Bonus to the player. Shot ids 0x3c,
0x50, 0x5a are the V Blade lower half, Pentashield orb and seeds (spells-detail §3.8).
Shipped availability (record census, all Box/Bonus records and params): **Ice Pick (3218) and Vorpal
Dirk (3221) are never placed nor held by any crate, chest, candelabra or pile**; Ziridium seeds 3226
×2 in L30 [HIGH census; MED "unobtainable": enemy drops and conversations not checked].

## 2. The Shadow Double (sprite type 0x1b39 = 6969)  [HIGH unless noted]
Manual: "It will make a double to shadow Ferazel." Power-up sphere 1330: `.HitPlayerSprite` case
0x532 sets the timer `PTR_DAT_100a064c = 600` and the flag `PTR_DAT_100a0654 = 1` (handler l.
3742–3746). Each frame (l. 1004–1011) the flag = `timer > 0 ∧ blink toggle cRam100a5fd4`; `.TickTock`
(main l. 42933ff) toggles that shared bit at timer 210, 195, … 15 and sets it at 0, so in the last 210
frames the double vanishes and reappears every 15 frames. Flag on and no double → `MTNewSprite(0x1b39,
player pos, player layer − 1, −1, SetupShadow)` into `*_DAT_100a0658`; flag off → `+0xe9 = 1`,
pointer 0 (l. 930–940). Dying clears it (§3.2 of player-states).
Setup (l. 582–596): `.InitSprite`, hit and tile callbacks 0, handler HandleShadow. Its rect is never
set (cleared record) → an empty hot rect, so `.TheSectRect` never pairs it: **it collides with
nothing**. Its only game effect is the 0-damage copy shots of `.CastSpell` (spells-detail §2.3).
**Pose history** (`PTR_DAT_100a0520`, 14 × 16 B: (y,x) +0, grounded-and-not-on-a-platform byte +4,
face +8, mirror +0xc; newest entry 13 at +0xd0; init x = y = −1, face 0 — handler l. 313–350,
2817–2869): shifted and recorded each frame unless "still" (`PTR_DAT_100a0674`: position equal to the
last drawn position `+0xc4/+0xc6` [MED: draw-routine writer, main l. 10349], not in a cannon, not
gliding, no wind `+0x92`, no pull-up — set from the first unmoved frame, l. 2753–2770).
**Replay index** `PTR_DAT_100a0590` (entry = index >> 1): −2/frame to 0 (13 frames behind) when not
riding; +2/frame to 0x1b (newest, in step) while riding a sprite (`PTR_DAT_100a0558`); `_DAT_100a05bc`
+1 to 8 while riding, −1 otherwise (l. 2771–2790).
**`.HandleShadowSprite`** (l. 467–580; raw `1004b4f0–1004b7d0`): flag off → face 0, return. Entry
x == −1 → face 0. Else, with wand phase `w = _DAT_100a06d4`, wand-held `h = _DAT_100a06d0`:
- **not casting** (`w < 1`, or `h ≥ 4` and not still — `cmpwi r3,4; blt` at `1004b564`): player
  crouching now and entry grounded → face 1011[crouch − 1]; else not still → the entry's face; still
  and entry airborne → `.ShadowBob` + entry face; still and entry grounded → face 1003[index>>1]
  (breathing frame 0 in practice) and bob reset.
- **casting**: face 1014[s − 1] with `s = w` (if not still: `h == 2 → 2`, `h == 3 → 1`), bobbing when
  the entry is airborne — the double "casts" with the player's current wand phase.
- then position = entry (y,x), `x += _DAT_100a05bc >> 1` (0..4 px), `y += bob _DAT_100a05c0`, mirror =
  entry, tint `+0xb8 = 0x1000b` (`lis 1; addi 0xb` at `1004b728`), `+0x88 = 0`. Outside the bob
  branches the bob decays 1 px/frame toward 0.
So the double replays Ferazel 13 recorded frames late, catches up while he rides a platform, and when
he stops it stays where he was 13 moving frames earlier — floating and bobbing if that pose was in
the air.
**`.ShadowBob`** (main l. 42543–42584; raw `1004b410–1004b4d0`): table at 0x100a5fda, 24 shorts
`0,2,4,7,8,9,10,9,8,7,4,2,0,−2,−4,−7,−8,−9,−10,−9,−8,−7,−4,−2` (const.py); phase `_DAT_100a0604`
+1/frame wrapping after 46 → bob = table[phase >> 1] (47-frame cycle, ±10 px). On the first bob frame
after a reset (`PTR_DAT_100a0608 == 0`) a re-sync search runs, but it compares the **same**
`table[phase]` (byte index `phase·2`, not `phase>>1`, overrunning the table into 0x100a600a… when
phase ≥ 24) 24 times: phase := 46 if `|table[phase] − bob| < 2`, else 0 [HIGH; reproduce as shipped].

## 3. The Double-Speed trail (five type-1 sprites)  [HIGH]
`.SetupPlayerSprite` l. 352–360: five `MTNewSprite(1, −1, −1, player layer − 1, 0x1ff, SetupTrail)`
(slot `0x100a0518` → `1004b3b4`, closing player-states §8's MED) into the 5 × 16 B ring at
`PTR_DAT_100a051c` (sprite +0, face +4, (y,x) +8, mirror +0xc; init −1/−1/0). Setup: `.InitSprite`,
handler HandleTrail = `.StandardSpriteHandles` + `.StandardSpriteCleanup` only. No hit callback, empty
rect → never collides. `.DoubleSpeedTrail` (main l. 43652ff; called handler l. 2871 and from the
cannon, l. 4702): shift entries 0←1←2←3←4, entry 4 = this frame's (y,x), face, mirror. Double Speed
off (`PTR_DAT_100a0620 == 0`) → all five faces 0. On → trail i at entry `(i>>1) + 2`, odd i at the
midpoint of entries s and s+1 (≤ 4):

| trail | pose | tint `+0xb8` |
|---|---|---|
| 0 | 2 frames ago | 0xb0002 |
| 1 | midpoint 2–1 frames ago | 0xb0000 |
| 2 | 1 frame ago | 0xb0001 |
| 3 | midpoint 1–0 frames ago | 0 |
| 4 | this frame (on the player) | 0 |

Entries 0 and 1 are recorded but never shown. Tint meanings: bosses-2 NR 1.

## 4. Wave 2 (2026-10-04): list order, mirroring, `+0x11c`, door `+0xa0`, revive

### 4.1 The player runs before the held item  [HIGH]
The active list is sorted by layer, ascending, insertion order within a layer, and one list serves
handlers, collisions and drawing (platforms-ropes-radial-2 §8). The player is layer 10 (`1004af88` →
`1004afac`), the held item 0x14 (`1004bdfc` → `1004be20`, re-stored every frame at `1004beb0`; created
inside `.SetupPlayerSprite` at `1004b018..1004b030`). So in every frame `.HandlePlayerSprite` (with
`.HandleItemUse` and `.SetHeldItemPos`) runs **before** the held sprite's handler, and both before
every hit callback. Consequences:
- Calls c = 1, 2 and the return calls: the held handler is `.HandleHeldItemSprite`; it runs after the
  player set this frame's face, so `+0x34` is that face's bounds (§1.1).
- Strike calls c = 3, 4, 5: the player's call has already switched the held sprite to
  `.HandlePlayerShotSprite` / `.HitPlayerShotSprite` when the list reaches it, so the shot handler runs
  **in the same frame** (no `.HandleHeldItemSprite`): `+0x34` keeps the last inert frame's rect (the
  same item face), the position is this frame's `.SetHeldItemPos` result, and the collision pass tests
  `.CalcHotRect` = `+0x34` + that position: the strike box is this frame's placement. With the Dirk
  or the Ice Pick (`+0x158 > 0`) the shot handler also runs `.SeparateFromTiles2`, which may push the
  held sprite out of a solid tile before the collision pass [MED: in-play effect].
- The held sprite is the outer sprite of `.MTCollideSprites` (it has a hit callback); an enemy with a
  hit callback is visited both ways, so its Hit routine sees the stab twice per strike frame — the
  first `.HurtSprite` sets invulnerability and the second is refused (§1.7, "lands once").
- Seed throw at c = 5: the centre `+0xe/+0x10` comes from the held sprite's previous-frame handler
  (`.HandlePlayerShotSprite` → `.StandardSpriteHandles` writes it at `10036dc0`/`10036de4`), i.e. the c = 4
  placement (§1.8).

### 4.2 Mirroring of the item face  [HIGH]
`.WrapDrawSprites` (main l. 10221ff) draws every face at the sprite's x plus the left clip with width =
face `+6` minus clips (`.InitSprite` sets clips 0 / 32000) and passes `+0x17e` as the flip flag;
`.BlitEncFaceX` sends a flipped draw to `.BlitEncFaceFlip*`, which starts every row at
`dest + width − 1` and writes leftwards (`.BlitEncFaceFlipNoClip`, raw `10028d08` width = 5th argument,
`10028ed4..10028ed8 subi r10,r8,1; add r10,r7,r10`). So pixel column c of the 32-px item cell lands on
column 31 − c of the same cell: §1.5's assumption holds, and since `.CalcHotRect` never mirrors the hot
rect, the left-facing offsets of §1.5 (dagger 10, Dirk 8, Ice Pick 2 px) stand.

### 4.3 The held item's `+0x11c`  [HIGH for the rule; intent UNDETERMINABLE]
`.SetHeldItemPos` writes it only while the player has water contact (`+0x11c` or `+0x120` ≠ 0):
`held+0x11c = max(p+0x11c, p+0x120) − (p.y − held.y)`, then at least 1 (raw `1004c028..1004c07c`:
`subf r5,r6,r5` = p.y − held.y, `subf r0,r5,r0`). Its only reader is the draw: `.WrapDrawSprites`
(raw `100147c0..1001486c`, main l. 10336ff) — `< 1` plain face; `== 1` whole face with effect
`0x60000 + +0x128` (water ripple); `> 1` the top `+0x11c` rows plain and the rest with the water
effect; it is also the light-overlay argument (`100149f4`). For a sprite `+0x11c` counts face rows
above the surface (physics §0), which for the item would be `p+0x11c − (held.y − p.y)`; the code adds
`(held.y − p.y)` (always > 0: `dy + 0x16`), so the item's water line falls `2·(dy + 0x16)` rows lower
than the surface and the item is drawn dry unless the player is deep. In strike frames the shot
handler's `.StandardSpriteHandles` copies and may zero `+0x11c` before the draw (physics §0 rule)
[MED: the held sprite's `+0x118` not traced]; `+0x128` is never written for the held sprite [MED].
Copy as written; whether the sign was meant cannot be settled from code.

### 4.4 Door `+0xa0`  [HIGH]
Scan of every `0xa0(rN)` operand (rN ≠ r1, r2) in the listing: `.DrawBlackLines` `1001fb7c`,
`.InitParticles` `10030660`, `.ConvertKeyName` `100776a0` (not sprites); `.HitBoxSprite` `100705ac`
(the door reset, store); `.HandleButtonSprite` `10070f3c` (load) / `100710a0` (store) — Buttons only
(previous press level, triggers-background §1). **No load of a Box's `+0xa0`**: the door reset is dead
and doors keep no state there (the idle↔active struct copies carry it unread).

### 4.5 Crunch kinds 0..4
Behaviour per kind and strength: player-states-2 §13 (kind 3 crumbles under any contact; 2 and 4 resist
weak strikes; 0 and 1 give way). The art of a crunch cell is the level's own FG tile, so a name per
kind is UNDETERMINABLE from code; the behaviour table is what a replica needs.

### 4.6 Revive vs a frozen swing  [HIGH reading; MED in play]
- The counter `_DAT_100a0698` has 9 TOC loads (`tocrefs`): `.ClearPlayerVars` (store 0), `.SetHeldItemPos`
  (read), `.HandleItemUse` (r31), `.HandlePlayerSprite` `1004ffcc` / `100502a8` (reads, followed),
  `.HandleKeys` ×4 (two reads, two stores when a swing starts). The dying / revive branch (handler
  l. 1729–1812) touches neither the counter nor the held sprite.
- While dying (≥ 80 or 100 frames) and reviving (30 frames) the counter stays frozen and the held face
  is zeroed every frame (handler l. 1397, before the state branches): invisible. If it froze after a
  strike call (counter 4, 5 or −5), the held sprite keeps the shot handler and hit callback: a live,
  invisible hit box at its last placement for the whole death and revive.
- The revive ends with dying counter 0 (handler l. 1754–1767); on the next frame the generic `c ≠ 0`
  test (l. 2074) calls `.HandleItemUse` and the swing **resumes** from the frozen counter and finishes
  its remaining calls (frozen at 4: calls 4, 5, −5, …, −1), with the stale item id `_DAT_100a5fd8`.
- Without a revive the level ends; the next `.SetupPlayerSprite` → `.ClearPlayerVars` zeroes the counter
  and makes a new held sprite.

## NOT RESOLVED
1. ~~Mirroring of a 32-px face by `+0x17e` (§1.5 assumes within the frame width); held `+0x11c` use.~~
   → closed: §4.2, §4.3 — ⚑ wave 2 (2026-10-04)
2. ~~Active-list order player vs held sprite (frame of the seed centre / strike rect, §1.5, §1.8).~~
   → closed: §4.1 — ⚑ wave 2 (2026-10-04)
3. ~~Door `+0xa0` (zeroed by non-exempt touchers) — no reader found. Crunch kinds 0..4 as art.~~
   → closed: §4.4 (write-only), §4.5 (behaviour; art UNDETERMINABLE) — ⚑ wave 2 (2026-10-04)
4. Whether conversations/enemy drops grant Ice Pick, Vorpal Dirk, Hammer; the Hammer's intent.
5. ~~Lead (Box/shot reader): Pentashield orbs (0x50, `+0xa4` 300) also pass the 2941 `== 300` test.~~
   Confirmed (⚑ corrected (review 1c, 2026-10-03) #2): `li r3,0x12c; sth r3,0xa4` `10059494..1005949c`, arm
   `cmpwi 0x50` `10059384`; the Ice Wall spell at power 1 qualifies too (spells-items §4 row 0x12).
6. ~~Revive path vs a frozen swing (§1.6).~~ → closed: §4.6 — ⚑ wave 2 (2026-10-04)

## Proposed additions to physics.md §0
| off | type | meaning |
|---|---|---|
| +0x158 | i32 | held item: crunch strength (−1 none, Dirk 1, Ice Pick 4); > 0 enables its tile pass |
| +0x11c | i32 | held item: player's water depth + (held.y − player.y), ≥ 1 |
| +0xc4/+0xc6 | i16 | last drawn y/x (main l. 10349–10350); player "still" test [MED] |

Globals: `_DAT_100a065c` held sprite; `_DAT_100a5fd8` in-use item; `PTR_DAT_100a04f4` swing side;
`0x100a5f68` held faces; `_DAT_100a0658`/`PTR_DAT_100a0654`/`064c` double sprite/flag/timer;
`cRam100a5fd4` power-up blink bit; `PTR_DAT_100a0520`/`0590`/`_DAT_100a05bc` pose ring/replay
index/riding offset; `_DAT_100a05c0`/`0604`/`PTR_DAT_100a0608` bob; `PTR_DAT_100a051c` trail ring.

## Corrections to the existing bank
| # | file § | old | new | evidence |
|---|---|---|---|---|
| 1 | spells-detail §3.7 last sentence | types > 100 = held item, snd 419, `+0xa6 = −6` re-hit guard [MED] | held item is type 100; `.KillPlayerShot` exits at once for it; the > 100 arm is unreachable; one hit per target comes from target invul | raw `1005ac64–68`, `1005accc–ad08` |
| 2 | bosses §1.5 "[MED: frame condition not decoded]"; bosses-2 NR 4; INDEX NR 19 | open | strike = calls c = 3, 4, 5; held `+0xa6` never non-zero | §1.3, §1.7; raw `1004d154–1d4` |
| 3 | pickups-boxes §3.1 rect | face rect inset 1 px | exact opaque bbox; not mirrored facing left (+10/8/2 px out) [MED] | §1.5; raw `1004bec4–ee8` |
| 4 | pickups-boxes §3.1 no carry [MED] | MED | HIGH for the item path | §1.9 |
| 5 | player-states §8 trail setup [MED] | MED | HIGH: slot 0x100a0518 → `1004b3b4` | §3 |
| 6 | enemy-shots §2.4 shadow [MED] | partial | face rule, empty rect (no collisions), still-freeze, blink respawn, bob table + re-sync bug | §2 |
| 7 | enemy-shots §2.3 trail | — | trail 4 = current pose; entries 0/1 never shown | §3 |
| 8 | ~~spells-items §4 item 8~~ no bank target (manual-only claim) ⚑ corrected (review 1d, 2026-10-03) #C8 | Hammer breaks cave walls (manual) | no code reads item 8 | §1.2 |
| 9 | player-states §3.10 | stab | add stale-damage seed stab, frozen live hit box, glider deferral, cadence | §1.3, §1.6, §1.8 |

Wave 2 (2026-10-04):

| # | file § | old | new | evidence |
|---|---|---|---|---|
| W1 | pickups-boxes NR 8 ("Door `+0xa0` cleared by `.HitBoxSprite`") / INDEX 21 | reader unknown | no reader anywhere: write-only | §4.4 field scan |
| W2 | enemies-* notes that a stab "hits once" | via invulnerability | also: the enemy's Hit routine runs twice per strike frame (pair visited both ways); the second call is the one refused | §4.1; platforms-ropes-radial-2 §8.3 |
