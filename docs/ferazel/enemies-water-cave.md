# Ferazel's Wand 1.0.3 — water / cave enemies: Frog, Salamander, Blob, Crab

Code readings only; nothing behaviour-verified. Date 2026-10-03.
Sources: `ghidra/Ferazel_handlers.decompiled.c` ("handler dump", the Setup/Handle/Hit/Kill
callbacks), `ghidra/Ferazel_pef.decompiled.c` ("main dump", helpers), raw disassembly
`ghidra/Ferazel_pef.disasm.txt` (addresses quoted as `@1008xxxx`), data constants via
`tools/const.py`, TVector names resolved by reading TOC slot → TVector → code entry and matching
the dump separators (scratch script; method: `pointer = word + 0x1009f840`, INDEX §Provenance).
Scope: classes Frog (types 1800..1809), Salamander (1810..1819), Blob (1730..1739), Crab
(1890..1899) and the helpers they call; the enemy shots they fire (types 0x709, 0x712); their
contact-damage arms in `.HitPlayerSprite`. Units as physics.md (px; velocities 1/256 px/frame;
one frame = one `.GameLoop` pass). Field names: physics.md §0; new fields are written `+0xNN`.
Faces: a face-set slot holds face *i* at `slot + 4 + 4·i` (`.LoadCachedSpriteFaces`, main dump,
writes `piVar9[1+i] = base + i·0x34`) [HIGH]; "face *i*" below means that.
`SetRect` arguments are `(left, top, right, bottom)`; the sprite rect at `+0x34` is stored
top,left,bottom,right (centre x uses +0x36/+0x3a) [HIGH].

## 0. Census of shipped placements  [HIGH — Python over the 24 `Mlvl` records, this session]

Method: `tools/rsrc_census.py` `parse()` on `Ferazel's Wand World Data.rsrc`; each `Mlvl` record
`i < 511` at body offset `4 + 16·i`, unpacked `>BBhhhhhhh` (flag, byte+1, type, p1..p4, y, x)
as world-data-format.md §3.4; filtered to the four ranges.

| type | class | n | levels (count) | p1 | p2..p4 | byte +1 |
|---|---|---|---|---|---|---|
| 1800 | Frog | 41 | 2 (2), 3 (1), 4 (6), 11 (7), 30 (3), 31 (9) → p1 0; 15 (1) → p1 **2**; 45 (3) → p1 **4**; 50 (7), 52 (2) → p1 **1** | 0/1/2/4 | all 0 | 0 |
| 1801..1809 | Frog | 0 | — (1801 = 0x709 is the frog's *shot* type, spawned by code with the EnemyShot setup, §1.4) | | | |
| 1810 | Salamander | 22 | 50 (10), 51 (12) | 0 | 0 | 0 |
| 1811..1819 | Salamander | 0 | — (0x712 = 1810 is also the salamander's *shot* type, §2.4) | | | |
| 1730 | Blob | 11 | 3 (4), 4 (1), 11 (3), 21 (3) | 0 | 0 | 0 |
| 1731 | Blob | 5 | 30 (4), 31 (1) | 0 | 0 | 0 |
| 1732 | Blob | 13 | 22 (3), 40 (2), 50 (3), 51 (3), 52 (2) | 0 | 0 | 0 |
| 1733..1739 | Blob | 0 | — | | | |
| 1892 | Crab | 3 | 62 "Ends of the Earth" (recs 97–99) | 0 (→ reach 100) | 0 | 0 |
| 1890, 1891, 1893..1899 | Crab | 0 | — (1895 = 0x767 is the chain-segment type, spawned by code) | | | |

All 105 records have flag 1. **Placement params used by these classes** (closes INDEX
NOT-RESOLVED 1 for them): Frog reads p1 only (variant, §1.1); Crab reads p1 only (reach, §4.1);
Salamander and Blob read no param (Blob variant = type). Record byte +1: never read. A grep of
every `* 0x10 +` record access inside the four classes' handler ranges finds exactly: SetupFrog
`+8` (handler dump l. 18300), SetupCrab `+8` (l. 20592), and the dead Blob write `+4 = 0`
(l. 16113, §3.3) [HIGH].

## 0.1 Shared machinery (all four classes)  [HIGH unless noted]

- **Setup runs at level load.** `.MTNewSprite @ 10033060` clears the 0x1fc-byte record, stores
  type/x/y/layer/record index (`+0x48`) and **calls the setup proc immediately**
  (`FUN_1009f80c(pcVar4)`, main dump `.MTNewSprite`); `.AddIdleSprite` creates the sprite with
  `MTNewSprite`, copies the set-up record into the idle table and kills it, so an idle enemy is
  re-activated with the state drawn at load (including its `FastRand` timers) ~~[MED: one
  `MTNewSprite` argument is lost in the decompile of `.AddIdleSprite`]~~ ⚑ wave 2 (2026-10-04): HIGH —
  the lost argument is the caller's r8 (setup proc), passed through untouched (§7.5).
- **Enemy statistic.** `.SetupLevel` sets `*_DAT_1009fe8c = 1` around `.SetupLevelSprites`
  (main dump l. 2521–2527). Frog/Salamander/Blob Setups then set `+0x1b5 = 1` and increment
  `*_DAT_1009ffb4`, which `.SetupLevel` stores to **G+0x6ee + 2·L** (first visit, l. 2533).
  Their Kill routines decrement it and increment **G+0x306 + 2·L** when `+0xe9 == 0 && +0x1b5`
  (KillFrog raw `@10082c30..10082c58`). So the pair (0x306, 0x6ee) is the **enemies defeated**
  stat (closes the enemy third of world-data-format.md §4.3 "which counter is which"). The Crab
  never sets `+0x1b5` → not counted [HIGH].
- `+0x4c` handler / `+0x5c` sprite-hit / `+0x1f8` tile-hit / `+0x50` kill proc; `+0xb0` state;
  `+0x46` frame counter; `+0xe9` kill; `+0xea` = clear the placement flag on removal
  (`.UpdateSprites`, main dump l. 4936–4944) so killed enemies never respawn.
- Every Handle starts `if (+0xe9 == 0 && +0x1b2 == 0)`; `+0x1b2` is set by `.HandleBoxSprite`
  (handler dump l. 12866) on a sprite it generates from a container and cleared later
  (l. 12969) ~~[MED: "held in container" reading]~~ ⚑ wave 2 (2026-10-04): the generator is the
  enemy pipe (Box 1490..1493); `+0x1b2` = "being pushed out of the pipe" — enemies-flyers §7.4 [HIGH].
- `.StandardSpriteHandles` first (counts `+0x116`/`+0xaa` down, resets `+0x140`, water current
  because `+0x8a = 1` from `.InitSprite`); **no wind**: the wind block needs `+0x90 > 0`
  (`.StandardSpriteHandles` line `if (0 < *(short *)(param_1 + 0x90))`) and none of these
  Setups writes `+0x90` [HIGH].
- `.StandardSpriteCleanup @ 10036e0c`: splash on leaving water, centre refresh, and
  `if (+0x1a2 != 0) .HandleBurn` (the death dissolve, §0.3).
- Tile-hit callbacks (Frog, Salamander, Blob) share one shape: `param_4 == 1` (FG) →
  `.WallBounce`; else BG kind `< 100` → `.WallBounce`, `100..199` → `.WallBounceBG(kind−100)`,
  water kinds 200..209 → `.HandleUnderWater` once per frame (`+0x140` latch: set at the end of
  `.HandleUnderWater`, main dump l. 37992; cleared by `.StandardSpriteHandles`, l. 32380). None
  of these classes sets `+0x19e`, so `.HandleFlotation` (physics §8.6) is never called for them.
  The Crab has no tile callback at all.
- **`+0x11c` is zeroed at the top of every frame.** `.StandardSpriteHandles` copies `+0x11c` to
  `+0x120` and stores 0 to `+0x11c` whenever `+0x118 < 0x1d` (raw `@100368d4..100369ac`;
  `+0x118` is 0 for every sprite here — its only writers store 0: `.InitSprite`, handler dump l. 7823). `+0x11c` becomes
  non-zero again only inside `.HandleUnderWater`, i.e. during `.ApplyGravityAndSeparateFromTiles`.
  So a handler that tests `+0x11c` **before** its first gravity call never sees water: the
  Frog's and Salamander's water blocks (self-buoyancy, lava damage, healing) are **dead code**
  (Frog: `bl 0x10036854 @10082190` then `lwz r0,0x11c @10082198`); the Blob tests after its
  gravity call and its block is live [HIGH].
- `.ApplyGravityAndSeparateFromTiles` picks `g' = max(0.7·g, 0x100)` only when `+0x11c ≠ 0` **at
  its entry** (raw `lwz r0,0x11c @100375c8; cmpwi; beq 10037618`, then `cmpwi 0x100; bge` /
  `li r30,0x100` at `1003760c–10037614`), i.e. before its own `SeparateFromTiles2` (`bl 1003c804
  @10037624`, which is where `.HandleUnderWater` sets `+0x11c`). Since `+0x11c` was zeroed at
  `100369ac` that frame, it is 0 on every sprite's **first** call each frame, so the **dry gravity**
  is used; only a **second** call in the same frame (the airborne Frog, §1.2 step 6, after the first
  call's `.HandleUnderWater`) can take the 0x100 branch — and for every class here `0.7·g < 256`, so
  that second call uses 256 [HIGH] ⚑ corrected (review 1a, 2026-10-03) #2 — earlier "in water
  gravity becomes 256 per call".
- `.FastRand(n)` = `n·(seed & 0xffff) >> 16` after a Park–Miller step (×0x41a7), i.e. 0..n−1
  (main dump `.FastRand @ 100340e0`) [HIGH].
- `+0x17e` (physics §0 "facing left") is passed as the blitter's **flip** flag
  (`.WrapDrawSprites` → `.WrapDrawFace(..., +0x17e)`); for these classes the art faces left, so
  `+0x17e = 1` means **facing right** (Frog spit spawns at `+90 px` with `vx = +2000` when set,
  §1.4) [HIGH for these classes].

### 0.2 Draw mode `+0xb8` and the variant tints  [HIGH for the dispatch; colours: requested HIGH, index LOW]
`+0xb8 = mode<<16 | sub` is the `.BlitEncFaceX` mode argument (`.WrapDrawSprites` main dump
l. 10246–10351). Mode 1 = per-pixel remap through the 256-byte table `_DAT_100a0140 + sub·0x100`
(`.BlitEncFaceSpecialClipX`, case 1), built by `.BuildTintTable @ 10020a5c`. ⚑ wave 2 corr (2026-10-04)
DE #10, LT #8: the hurt flash replaces the tint for the flash's frames (`100146f0..10014728`), and a
fully submerged sprite (`+0x11c == 1`) is drawn with the water table instead of its tint
(`100148f0..1001491c`); the tables are built from the level+base **working copy** (indices 0..0x9f
equal CLUT 200 in every level), colours rendered in lighting-tables §3.2 (chosen index LOW,
particles §4.3). Tables used here:

| sub | `.BuildTintTable` formula (per palette entry, lum = (R+G+B)/3) | reads as |
|---|---|---|
| 4 | R/2, G/2, B = 2·lum | blue |
| 0xb | R = G = B = lum | grey (the Statue tint, §5) |
| 0xc | R = 0xffff, G = lum, B = 0 | red-orange |
| 0xf | lum>>12 → fixed indices 0x43, 0x8d..0x88 (CLUT 200: 0x88 = (ff,ae,fe) … 0x8d = (54,03,53)) | magenta / purple |
| 0x17 | (2·lum − 32000)>>12 → 0xff, 0x35, 0x76..0x71, 0x2a (0x71 = (6b,9c,30) … 0x76 = (2f,4c,17)) | olive green |

Other modes met: 9 (water tint table `_DAT_100a0170`, Crab in water), 0xb (translucent,
dead-blob fade), 6 (submerged part drawn with `0x60000 + water kind`); ~~0xe~~ no code writes mode
0xe to `+0xb8` — it is only tested in `.WrapDrawSprites` (store scan) ⚑ wave 2 corr (2026-10-04) DE #3.

### 0.3 Death dissolve `.HandleBurn @ 10043cd8` (Frog, Salamander)  [HIGH]
Started by `+0x1a2 = 1`. First call: sound **462 "enemyconsumed"** (`PTR_DAT_100a01ec`, loaded
from id 0x1ce in `.InitSounds`) at volume 0xab via `.STPlay3DSoundRand` (pitched 110000 +
`FastRand(15000)` vol 0x41 if `+0x8c`, never set here). `+0x1a2` jumps to the face's opaque top
(`face+8`) and then advances `+0x8d + 1` (= 1) rows per frame. ⚑ wave 2 corr (2026-10-04) DE #1, #2:
`.BurnFaceRow(face, pos, 2, row, flip, style)` **erases nothing** — it spawns particles along the
row's opaque pixels (particle kind 1, or 0xd when `+0x8e` is set — Frog only, on levels with
hdr+0x26cd ≠ 0, i.e. the freezing-water levels 30/31; `100438c4..10043974`); the face is hidden by the
top clip `+0x1bc = row` (`10043e5c..10043e64`). When `+0x1a2 >` the opaque bottom (`face+0xc`) the
kill proc `+0x50` is called (else `+0xe9 = 1`). The dissolve lasts `⌊(face+0xc − max(face+8,1))/k⌋ + 1`
frames, k = `+0x8d + 1` (opaque height + 1 at k = 1; `10043e7c..10043e8c`; draw-effects §4.2).

## 1. Frog (types 1800..1809)

Callbacks: `.SetupFrogSprite @ 10081f14` (handler dump l. 18256–18341), `.HandleFrogSprite
@ 1008214c` (l. 18342–18580), `.HitFrogSprite @ 100828cc` (l. 18581–18674), `.KillFrog
@ 10082c14` (l. 18675–18722), `.HitFrogTileSprite @ 10082d04` (l. 18723–18760); main dump
`.InitFrogSprite @ 10081df4`, `.STPlay3DSoundRandFrog @ 10081e68`. Face sheet: PICT **1800**
(unnamed), 8 cells of 120×100, one row (`_CacheEncFaceSetFromPICT(slot 0x100a0cd0, 0x708, 8,
0x78, 100, 8, …)`); Setup marks the slot needed (`slot[1] = 1`). Layer 11. Hot rect
SetRect(11, 20, 72, 73).

### 1.1 Setup and variants (selection = placement **p1**, stored at `+0x15c`)  [HIGH]
Common: HP 500, `+0xb0 = 0xb` (idle), `+0x14c = −20 − FastRand(30)` (first-decision delay),
gravity `+0x110 = 0x8c` (140), `+0x150 = −1`, `+0xc0` = face 0, `+0x8e = 1` if hdr+0x26cd,
**voice pitch** `+0xf0 = 0xbfff + 2·FastRand(0x5fff)` (raw `@10081ff8..10082010`:
`rlwinm ×2; addis +0x10000; subi −0x4001`) = 49151..98299 (0x10000 = 1.0).
Switch on p1 (raw `@10082014..100820a8`):

| p1 | HP `+0xa4` | tint `+0xb8` | score (KillFrog, raw `@10082c68..10082cdc`) | spit HP multiplier (§1.4, dead) | shipped |
|---|---|---|---|---|---|
| 0 | 350 (0x15e) | 0 (natural) | 500 | ×1 | 37 frogs |
| 1 | 500 (0x1f4) | 0x1000c red-orange | 600 | ×2, tint 0x1000c | 9 (levels 50, 52) |
| 2 | 350 | 0x10017 green | 600 | ×1, tint 0x10017 | 1 (level 15) |
| 3 | 1500 (0x5dc) | 0x1000f purple | 2000 | ×4, tint 0x1000f | 0 |
| 4 | 1000 (0x3e8) | 0x1000b grey | 1000 | ×3, tint 0x1000b | 3 (level 45) |
| <0 or >4 | 500 | 0 | **none** | none | 0 |

(physics.md §7 listed "500, 350, 1000" — see Corrections.)

### 1.2 Per-frame order (`.HandleFrogSprite`)  [HIGH]
1. `.StandardSpriteHandles`.
2. Water block — **dead code** (§0.1: `+0x11c` was just zeroed). As written: `vy −= 100` while
   `vy > −800` (raw `@100821a4..100821b4`); if (fully submerged `+0x11c == 1` in kind 0) or any
   kind > 0: kind 3 → HP += 2 up to 500; kind 2 only and `+0x116 == 0` → `+0x116 = 19`, HP −100,
   flash 17, sound 701 vol 0x55. A faithful replica omits its effect: a frog in water takes no
   lava damage and is not healed. Gravity in water: step 3's call (the frame's first) uses the
   **dry** gravity (`+0x11c` is 0 at its entry, §0.1); step 6's second call uses 256 only if step 3
   ran this frame (airborne) and its `.HandleUnderWater` set `+0x11c`; a grounded frog (one call)
   always gets dry gravity [HIGH: raw `100375c8`, `100369ac`] ⚑ corrected (review 1a, 2026-10-03)
   #2 — earlier "falls at gravity 256 per call".
3. If not grounded (`+0xce == 0`, previous frame): `.ApplyGravityAndSeparateFromTiles`.
4. State switch (jump table at TOC−0xa0c, raw `@10082278`), below.
5. If HP < 1 and state ≠ 4 → `+0x46 = 0`, state 4, sound **615 "frogdie"** (vol 0x100, frog pitch).
6. `x += vx; y += vy` (no collision), then `.ApplyGravityAndSeparateFromTiles` again, then
   `.StandardSpriteCleanup`.
So an airborne frog integrates vx/vy **three times** per frame (twice with collision, gravity
added twice), a grounded one twice. A replica must transcribe this order, not "fix" it.
Gravity: 140 until first ground contact; **400** while touching FG ground (`.HitFrogTileSprite`:
`param_4 == 1 && +0xce` → `+0x110 = 400`); **90** set on every jump launch and airborne frame.

### 1.3 States  [HIGH; raw addresses for the constants]
- **0xb idle**: `vx = 0`; `+0x14c++`; face toward the player (`+0x17e = frog x < playerX`,
  signed, raw `@100822a0..100822bc`; playerX/Y = `_DAT_1009fd94/_DAT_1009fd90`, the player's
  centre — `.HandlePlayerSprite` stores the same value to player+0x10 and playerX `@10051410/14`
  [HIGH x, MED y]); face 0. When `+0x14c ≥ 0`: `dx = |frog cx − playerX|`;
  if `dx ≥ 250` → state 9; else `r = FastRand(100)`; if `10 < r ≤ 70` and playerY < frog cy −
  50 → `r = 100`; then if `r > 70` or `+0x154 < 0` → state 9; else if `r > 7` → state 2 (spit);
  else state 9 with `+0x154 = −3 − FastRand(3)` (a hop chain). `+0x46 = 0` on every exit.
  (raw `@100822ec..100823b4`.)
- **9 crouch → launch**: `vx = 0`; face `min(+0x46/3, 2)` (0,1,2). At `+0x46 ≥ 8`
  (`@10082400`): face 3, state 10; frogjump **613** (vol 0x80, frog pitch) when
  `FastRand(100) > 55`; `+0xce = 0`; `vx = −650 − FastRand(200)`, `vy = −1300 − FastRand(400)`
  (`@10082454..10082480`); hop chain: if `+0x154 < 0` → `+0x154++`, `+0x14c = 0` (re-decide at
  once, so 3–5 hops in a row), else `+0x14c = −10 − FastRand(10)`. Aim, first match:
  playerY < frog cy − 40 → `vy −= 200 + FastRand(150)`; else `dx ≤ 250` → with
  `FastRand(100) > 80`: `vy −= 350, vx −= 200`; else (far) `vx ×= 0.7, vy ×= 0.7` (double
  `0x100a1bd8` = 0.7) and `+0x14c = −4 − FastRand(4)`. Then gravity 90; `vx = −vx` if facing
  right; `+0x158 = vx`. `+0x46++` every frame. So the frog always hops **toward** the player,
  small quick hops when farther than 250 px.
- **10 airborne**: face 3 while `vy < 0`, else face 4; `vx = +0x158` every frame (a wall
  cannot stop it); gravity 90; on ground (`+0xce`) → face 5, state 0xb.
- **2 spit** (15 frames): `vx = 0`; `k = +0x46/3` (`mulhw 0x55555556`); `k ≥ 5` → state 0xb,
  `+0x14c = −10 − FastRand(10)`, face 0; else face `5 + (k ≤ 2 ? k : 4 − k)` (5,5,5,6,6,6,7,7,7,
  6,6,6,5,5,5). At `+0x46 == 6` it fires the spit (§1.4).
- **4 dying**: `vx ×= 0.9` (double `0x100a1bd0`, `@100827bc..100827f0`); face 4;
  `+0x1a2 = max(+0x1a2, 1)` → burn dissolve (§0.3), then `.KillFrog`.

### 1.4 Spit (enemy shot type 0x709 = 1801)  [HIGH]
`MTNewSprite(0x709, cx + flip·90 − 45, cy − 20, layer + 1, −1, .SetupEnemyShotSprite)`
(`@100826c8..100826f8`), `vx = +2000` if facing right else −2000 (`@1008270c/18`). The p1 switch
then multiplies the shot's `+0xa4` (×2/×4/×3) and sets its tint (table §1.1) — but
`.SetupEnemyShotSprite @ 1005ba5c` handles 0x709 in its **first** arm (gravity 0,
SetRect(8,3,15,12)) and never sets `+0xa4`; the second `0x709` arm that would set 0x38 is
**unreachable** (raw: `cmpwi r3,0x709 @1005bbd0` then again `@1005bcb4`). `+0xa4` is 0 from
`.InitSprite`, so all multipliers yield 0, and the player's damage does not read it anyway
(§6). Visible effect of p1 on the spit: tint only. Shot behaviour (`.HandleEnemyShotSprite`
l. 6043ff): 6-frame loop of faces from PICT 1109 (left, `vx < 1`) / 1108 (right), 24×15, one
`.ApplyGravityAndSeparateFromTiles` per frame (straight line, 2000/256 ≈ 7.8 px/frame); killed
silently on the first FG wall hit (`+0x150` 0 → 1 ≥ 0, `.HitEnemyShotTileSprite`), on
touching the player (after damage, §6), on a Statue/Box solid (`.HitEnemyShotSprite`), more than
1000 px beyond the view horizontally, or below the map; `.KillEnemyShot` has no 0x709 arm
(no sound, no effect).

### 1.5 Damage taken (`.HitFrogSprite`)  [HIGH]
Ignored entirely while state 4. Player shot (`+0x4c == .HandlePlayerShotSprite`, `+0xa6 == 0`;
every spell and thrown/held item that is a player shot): `.KillPlayerShot(shot, 0, 0)` (no impact
sound, no impact effect; fire seeds still explode); spell id 1 → `.TurnIntoStatue` (§5); else
`.HurtSprite(frog, shot+0xa4, shot vx>>3, shot vy>>3, invul 8, flash 8)`; on a hit: sound 701
when `FastRand(100) ≤ 45` else **614 "froghit"** (vol 0x100, frog pitch); state 9 unless
airborne (10), `+0x46 = 3` (it hops 5 frames later); if still alive
`.BloodSpray(frog, shot, 40, 400, 150, kind 2)`.
Statue or Box sprite: `.PlatformBounce(frog, solid, …)`; if it returns 2 (frog hit it from
below) and (solid vy > 0 or frog grounded) → **crushed**: HP 0, `+0x150 = 0x16`.
Explosion Effect 0x4b7 while its `+0x46 < 8` (`@10082ad4/e0`; spawned by fire-seed shots and
crates) or a geyser segment 0x5a0 (`.HandleGeyserSegSprite`) with `+0x14c == 1 || +0x150 == 2`:
`.HurtSprite(100, vx>>3, vy>>3, 8, 8)`, same state/blood; sound 702 "Crawler uh oh" if HP < 201
else 701 (unpitched) [MED: "explosion"/"geyser active" readings].

### 1.6 Death, score  [HIGH]
`.KillFrog` (called by the dissolve): stat bookkeeping (§0.1), `+0xe9 = +0xea = 1`, score
`G+0 +=` by p1 (table §1.1). No drop, no spawn.

## 2. Salamander (types 1810..1819; only 1810 shipped)

`.SetupSalamanderSprite @ 10082f20` (l. 18761–18811), `.HandleSalamanderSprite @ 10083074`
(l. 18812–18965), `.HitSalamanderSprite @ 1008350c` (l. 18966–19019), `.KillSalamander
@ 10083724` (l. 19020–19045), `.HitSalamanderTileSprite @ 100837b8` (l. 19046–19088).
Sheet PICT **1810 "Salamander"**, 9 cells 80×100 (`.InitSalamanderSprite`). Layer 11.
Hot rect SetRect(14, 20, 66, 73). No type or param dependence anywhere [HIGH].

### 2.1 Setup  [HIGH]
HP 500, state 0xc, `+0x14c = −20 − FastRand(30)`, gravity 140, `+0x150 = −1`, kill proc
`.KillSalamander`, `+0xc0 = 0` (no face until the first frame).

### 2.2 Per-frame order and water  [HIGH]
`.StandardSpriteHandles`; water block — **dead code** like the Frog's (tests `+0x11c` before
the gravity call; §0.1). As written it would cost −100 HP per 19 frames when fully submerged in
kind 0 or in **any** kind > 0 (lava, healing pool, quicksand alike; raw `@100830e4..1008312c`)
plus the same `vy −= 100` buoyancy — so salamanders are in effect immune to lava. Then **one**
`.ApplyGravityAndSeparateFromTiles` — the frame's only call, so `+0x11c` is 0 at its entry and the
**dry** gravity is always used, in water too (§0.1; raw `100375c8`) ⚑ corrected (review 1a,
2026-10-03) #2. Then `vx = 0`
(the salamander never moves horizontally), state switch, death check (HP < 1 → state 4, no
sound), `x += vx; y += vy` without collision (vertical motion applied twice), cleanup.
Tile callback: while state 0xb, BG solid (< 100) and BG-ledge (100..199) cells are **ignored**
(it passes through them; FG still collides); after any tile hit, if grounded, gravity = 350.

### 2.3 States  [HIGH]
- **0xc idle**: `vx = 0`; `+0x14c++`; face player; face 0. When `+0x14c ≥ 0` and `|cx −
  playerX| < 250`: face 1, state 10, `vy = −3200 − FastRand(700)` (`@100831f0..1008320c`).
- **10 leap**: face 2 while `vy < 0` else face 1; gravity 170 (0xaa); landing: face 0; if out of
  water or only partly in (`+0x11c ≠ 1`) → state 2; fully submerged → state 0xc with
  `+0x14c = −20 − FastRand(30)`.
- **2 spit**: face player; if `+0x14c < 0`: face 0, `+0x46 = 0`, `+0x14c++` (pause). Else
  `k = +0x46/3`: `k ≤ 5` → face `3 + k` (faces 3..8 over 18 frames), at `+0x46 == 12` fire
  (§2.4); `k ≥ 6` → `FastRand(10) < 7` (70 %): `+0x46 = 0`, `+0x14c = −10 − FastRand(10)` and
  spit again after the pause; else (30 %): `+0x14c = −10 − FastRand(10)`, state 0xb, face 1,
  `vy = −1800 − FastRand(600)` (`@10083368..10083384`).
- **0xb hop**: face 2/1 by vy; gravity 210 (0xd2); landing → face 0, state 0xc.
- **4 dying**: face 5; `+0x1a2 ≥ 1` → dissolve (§0.3) → `.KillSalamander`.

### 2.4 Fireball (enemy shot type 0x712 = 1810)  [HIGH]
`MTNewSprite(0x712, cx + flip·60 − 45, cy − 25, layer + 1, −1, .SetupEnemyShotSprite)`,
`vx = ±2000` by facing (`@100833d0..1008341c`). Setup arm: gravity 0, SetRect(8,3,15,12),
`+0xa4` not set. Handler: `+0x88 = 0` (no lighting pass), 6-frame loop of PICT 1111 (left) /
1110 (right). Removal as §1.4, but `.KillEnemyShot` plays **301 "fireball hit new"** and spawns
Effect type 0 at (x−8, y−12), layer 11 (the small fireball burst, same call as a player
fireball's impact) [MED for "burst"].

### 2.5 Damage taken, death  [HIGH]
Player shot: `.KillPlayerShot(shot,0,0)`; Statue spell → `.TurnIntoStatue`; else
`.HurtSprite(shot+0xa4, shot vx>>5, shot vy>>3, invul **2**, flash 8)`; on a hit: `+0xa6 = 21`
if it was < 2 (no reader found — NOT RESOLVED; ⚑ wave 2 (2026-10-04): write-only, §7.1), blood (kind 2) if alive, sound 702 if HP < 201
else 701. Statue/Box crush as Frog. **No explosion/geyser branch** (fire-seed blasts do not
hurt it beyond the shot itself). No state-4 guard (a dying salamander can still be statued).
`.KillSalamander`: stat, score **+400** (only if `+0xe9 == 0`), `+0xe9 = +0xea = 1`.

## 3. Blob (types 1730..1739)

`.SetupBlobSprite @ 1007cdb0` (l. 15972–16038), `.HandleDeadBlobSprite @ 1007cf64`
(l. 16039–16066), `.HandleBlobSprite @ 1007d044` (l. 16067–16281), `.HitBlobSprite @ 1007d6e0`
(l. 16282–16331), `.HitBlobTileSprite @ 1007d968` (l. 16332–16366); main `.KillBlob @ 1007d8dc`,
`.InitBlobSprite`. Sheet PICT **1730** (unnamed), 16 cells 64×44 in one row. Layer 8. Gravity
250 (0xfa). Hot rect SetRect(14, 12, 47, 33). No kill proc (`+0x50` stays 0).

### 3.1 Variants (selection = **type**; raw `@1007ce0c..1007ce88`)  [HIGH]

| type | HP | tint | shipped |
|---|---|---|---|
| 1730 (0x6c2) | 700 | 0 | 11 |
| 1731 | 1100 (0x44c) | 0x10004 blue | 5 (ice levels 30/31) |
| 1732 | 1500 (0x5dc) | 0x1000c red-orange | 13 |
| 1733 | 2000 | 0x1000f purple | 0 |
| 1734..1739 | **0** (`.InitSprite`) → dies on its first frame | 0 | 0 |

Setup also: state 6, `+0xb2 = 0`, `+0x46 = 2`, `+0x14c = 0`, `+0x150 = −1`, face 0.

### 3.2 Per frame  [HIGH]
`.StandardSpriteHandles`; facing `+0x17e = 1` if cx < playerX, 0 if >, kept if equal; state
switch; HP < 1 → state 4; `.ApplyGravityAndSeparateFromTiles` (once); water (only when fully
submerged in kind 0 or kind > 0): kind 3 → HP += 4 up to 500; kind 2 → −100/19 frames, flash
17, sound 701 vol 0x55 (no self-buoyancy: a blob sinks at gravity 256); face = `face(+0x46>>1)`
(0..9), or in state 4 `face(10 + (+0x46>>2))` (10..15).

### 3.3 States  [HIGH; raw addresses]
- **6 pulse/wait** (start): `+0x17e = 0`; `+0xa6` counts down if > 0. Phase `+0xb2 = 0`:
  `+0x46++` to 9, then `+0xb2 = 1`. Phase 1: when `+0xa6 == 1` → `+0xb2 = 0`; when `+0xa6 == 0`
  → `+0x46--`, and below 3 → `+0x46 = 2`, `+0xa6 = 2 + FastRand(14)`. (Grow 2→9, shrink 9→2,
  pause, repeat.) Trigger (`@1007d18c..1007d1e0`): `|playerX − cx| < 200` and `|playerY − cy| <
  220` and `playerY > cy − 128` and `+0xa6 == 1` (only at the end of a pause) → `+0xa6 = 0`,
  state 2. Then `vx ×= 0.8` (double `0x100a1b78`) and `vx = 0` if `vx < 100` — a **signed**
  test (`cmpwi r0,0x64 @1007d234`), so any leftward vx is zeroed at once.
- **2 lunge**: `side = player right of blob`; if side ≠ `+0x14c` or vx opposes side → state 5
  (brake); `+0x14c = side`. If `+0xa6 == 0`: `a = +400` if `cx < playerX` else −400; while
  `+0x46 < 20`: at `+0x46 == 4` sound **607 "slimemove"** vol 0x55, rate `50000 +
  FastRand(30000)` (`@1007d2f4..1007d320`), then `+0x46++`; `8 ≤ +0x46 < 14` → `vx += a`;
  `14 ≤ +0x46 < 20` → `vx −= a` (`@1007d334..1007d370`; peak ±2400, ends at 0); at `+0x46 == 20`
  → `+0x46 = 0`, `+0xa6 = FastRand(20)`, and `FastRand(100) > 92` (7 %) → state 6. If
  `+0xa6 > 0` → `+0xa6--` (rest between lunges).
- **5 brake**: `vx ×= 0.8`; `+0x46` cycles 0..19; `|vx| < 200` → `vx = 0`, state 2.
- **4 dying**: (dead block, below) `+0x14c++`; `vx ×= 0.8`, `|vx| < 200` → 0; `+0x46++` capped
  at 20; once > 19: if `vy == 0` or standing on a sprite (`+0xcd`) → handler =
  `.HandleDeadBlobSprite`; `+0x5c = 0` (no more sprite contacts). `+0x46` is **not** reset on
  entry, so the death strip starts wherever the counter was.
  Dead code: an entry block guarded by `+0x14c == −1` (`cmpwi r0,-0x1 @1007d454`) would reset
  `+0x46`, add score 200, play **703 "crawler death"** and clear the placement flag; no Blob
  routine ever stores −1 to `+0x14c` (Setup 0, lunge 0/1) [MED: unreachable as far as traced].
- **Dead puddle** (`.HandleDeadBlobSprite`, raw `@1007cf98..1007cfec`): `+0x15c++` from 0,
  `+0xaa = 0`, `+0xea = 1`; > 60 → `+0x88 = 0` (unlit); > 66 → draw mode 0xb0001; > 72 →
  0xb0000; > 78 → 0xb0002 (translucency steps); > 84 → `.KillBlob`, face cleared. `.KillBlob`:
  score **+250** (0xfa) if `+0xe9 == 0`, stat, `+0xe9 = +0xea = 1`.

### 3.4 Damage taken  [HIGH]
Player shot while blob HP > 0: `.KillPlayerShot(shot,0,0)`; Statue spell → statue; else
`.HurtSprite(shot+0xa4, shot vx>>1, **−1000**, invul 2, flash 8)` (`li r6,-0x3e8 @1007d760`;
the hit pops it up); on a hit: state 5, `.BloodSpray(…, 40, 400, 150, kind 0xc9)` (different
particle kind from Frog's 2; ~~[MED: slime-coloured]~~ kind 201 = palette indices 113–116, olive green
#6B9C30 → #476C21, identical on every level — `10030fc0..10030ffc`, particles §4.1 ⚑ wave 2 corr
(2026-10-04) PA #5), sound 702 if HP < 201 else 701. Statue/Box
crush as Frog. No explosion branch.

## 4. Crab (types 1890..1899; only 1892 shipped) — an invulnerable claw on a chain

`.SetupCrabSprite @ 100894e4` (l. 20532–20657), `.HandleCrabSprite @ 10089828` (l. 20658–20857),
`.HandleCrabSegSprite @ 10089dec` (l. 20858–20869), `.HitCrabSprite @ 10089e24`
(l. 20870–20882); main `.InitCrabSprite @ 10089454`. Sheets: claw PICT **1890**, 6 cells
100×100; chain link PICT **1895** (one face). Layer 8 (links 7). Hot rect SetRect(24,24,76,76).
No gravity, **no tile callback**, no kill proc, HP 1000 never reduced.

### 4.1 Setup  [HIGH]
Anchor `+0x150/+0x154` = initial x/y; reach `+0x14c` = **p1, 0 → 100**; in-water flag `+0x16c
= 1` if the BG tile under the top-left cell is water (`.GetBGTile(x>>5, y>>5)` →
`.IsWaterTile`) ~~[MED: GetBGTile arg order]~~ ⚑ wave 2 (2026-10-04): HIGH — `.GetBGTile(col, row)`,
and no shipped crab is in water (§7.3); links: `n = min((reach + 23)/24, 12)` sprites of type
0x767 via `MTNewSprite(0x767, x+30, y+30, layer−1, 0x1ff, .SetupCrabSprite)` stored in a
0x34-byte block at `+0x9c` (12 pointers, count at +0x30); type 0x767's Setup arm gives them a
zero rect, no callbacks, handler `.HandleCrabSegSprite` (face only). In water, claw and links
get `+0xb8 = 0x90000`. Start angle `+0x46` by type: 1890 → 0, 1891 → 180, 1892 → **90**,
1893 → 270, 1894 → 90. State 0, `+0xa6 = 0`.

### 4.2 Aiming (state 0)  [HIGH]
`d = .FindDesiredDirectionGeneric(crab centre, player sprite centre)` — 36 sectors of 10°,
**0 = right, 9 = up, 18 = left, 27 = down** (thresholds tan 5°, 15°, … 85° at
`0x100a1880..0x100a1848`, quadrant by the signs of −dy and dx). Allowed target directions by
type (raw `@100898b8..10089974`): 1890 `d < 9 or d > 27`; 1891 `9 < d < 27`; **1892 `0 < d < 18`
(upper half)**; 1893 `18 < d < 36`; 1894 any. If allowed, the angle steps **5°/frame** toward
`T = 10·d` the short way round, wrapped to 0..359. `+0x1aa` (face rotation, degrees) = angle
(1891: `+0x17e = 1` and angle + 180 mod 360). If `+0xa6 < 1` and angle == T exactly and
`.PEDistance(playerX − cx, playerY − cy) ≤ reach + 54` (PEDistance = max(|a|,|b|) +
min(|a|,|b|)/3; `addi r0,r4,0x36 @10089ad4`) → state 1, `+0xa6 = 0`; else `+0xa6--`. Face 0.

### 4.3 Strike (state 1, 30 frames)  [HIGH]
`t = ++(+0xa6)`. `t ≤ 5`: face t (claw opens). `u = t − 5`; `u == 1`: vector
`(+0x16c, +0x170) = FUN_100417bc((angle/10 + 18) mod 36, reach)` (the 36-entry 10° table, index
0 = (−r, 0), index 1 = (−0.985r, +0.174r) — physics §6) → points along the aim. `u ≤ 12`: claw
top-left = anchor + v·u²/144 (accelerating out to full reach at u = 12). `13 ≤ u ≤ 24`: face
`max(17 − u, 0)`, position = anchor + v·(144 − (u−12)²)/144 (decelerating back). `u ≥ 25` →
state 0, `+0xa6 = 10` (10-frame cooldown). Every frame link i (0..n−1) sits at
`anchor + (claw − anchor)·i/(n+1) + 30` on both axes.
HP < 1 → state 3 (no code; unreachable since nothing hurts it).

### 4.4 Damage  [HIGH]
`.HitCrabSprite`: a live player shot is destroyed with `.KillPlayerShot(shot, 1, 1)` (impact
sound 301 + impact effect) and sound **303 "metal hit"** vol 0xab — **no damage, no Statue**
(spell id never tested). `.SmiteEnemies` (Ring of Smiting) does not list the crab handler.
Contact: §6.

## 5. Statue spell on these classes  (extends spells-items.md §2.1)  [HIGH]
`.TurnIntoStatue @ 10043138`: sound 302 "statue hit" vol 0x32; saves `+0x4c/+0x5c/+0x1f8` to
`+0x1ec/+0x1f0/+0x1f4` and `+0xb8` to `+0x134`; `+0x130 = 120`; handlers become
`.HandleStatueSprite` / `.HitBoxSprite` / `.HitBoxTileSprite`; `vx = vy = 0`.
`.HandleStatueSprite @ 100664a8` each frame: adds a light once, tint `0x1000b` (grey), layer
2, `vx = vy = 0` (no gravity call: a frog statued mid-jump hangs in the air), `+0x130--`; for
`+0x130 < 20` odd values draw untinted (blink); at `+0x130 < 1` restores handlers and tint and
**HP −200**, removes the light. Frog, Salamander and Blob have the Statue test; Crab does not.
While a statue, the sprite is a Box-class solid to others (Frog/Salamander/Blob crush rule).

## 6. Damage dealt to the player (`.HitPlayerSprite @ 100556f4`)  [HIGH]
Contact is resolved in the player's hit callback by the other sprite's handler:

| source | handler | arm (handler dump) | `.HurtPlayer(dmg, blood, invul, coins lost)` |
|---|---|---|---|
| Frog body | `.HandleFrogSprite` | generic table l. 4553 → 0x70 | 112, 1, 60, 3 coins if `FastRand(100) > 80` else 0 (l. 4610–4619) |
| Salamander body | `.HandleSalamanderSprite` | own arm l. 4232–4241 | 112, **0**, 60, 3 coins if `FastRand(100) ≥ 81` |
| Blob body | `.HandleBlobSprite` | generic l. 4547 → 0x38 | 56, 1, 60, 0 |
| Dead blob | `.HandleDeadBlobSprite` | no arm (and `+0x5c` cleared) | none |
| Crab claw | `.HandleCrabSprite` | own arm l. 4254–4262 | 112, 0, 60, 3 coins if `FastRand(100) ≥ 61` (39 %) |
| Frog spit 0x709, salamander fireball 0x712 | `.HandleEnemyShotSprite` | generic, type falls to the default `iVar37 = 0x38` (l. 4599) | 56, 1, 60, 0; then `.KillEnemyShot` |

The generic path first calls `.ShieldBlock(player, sprite)` (l. 4523): an enemy shot arriving on
the guarded side while the guard counter `PTR_DAT_100a05e8 > 2` is destroyed with sound 303 and
no damage. Shot `+0xa4` is not read for 0x709/0x712 (only for 0x753/0x754/0x771..0x774). The
player's own invulnerability (`+0x116`, 60 frames after each hit) gates all of these
(`.HurtSprite`). No class here can be stomped (no `.PlatformBounce` arm for them in
`.HitPlayerSprite`).

## 7. Wave 2 (2026-10-04): loose ends  [labels per item]
Sources for this section: raw listing, both dumps, a field-access scan (scratch Python over every
`l*/st* rX,0xNN(rY)` of the raw listing, bucketed by function, `(r1)` dropped), World Data `Mlvl` 62
decoded with `tools/rsrc_census.py` + world-data-format §3.1/§3.3, and the demo binary
`…/Action-Adventure/ferazelswand/Ferazel Demo (installed)/files/Ferazel's Wand Demo` unpacked with
`tools/pef.py` (`FZ_PEF`). Closes INDEX item 18.

### 7.1 Salamander `+0xa6 = 21` is write-only  [HIGH]
Accesses to `+0xa6` in the Salamander routines: Setup store (`10082fec`), `.HitSalamanderSprite`
`10083538` (the *shot's* `+0xa6 == 0` test, r31 = other) and `100835ac..100835bc` (own: `< 2 → 0x15`);
`.HandleSalamanderSprite` (`10083074..1008350c`) has **no** `+0xa6` access. Generic routines that
load `+0xa6` (`.HitPlayerSprite` `100557a4`/`10056f7c`, `.HitPlayerShotSprite` `1005a9dc`, the other
`.Hit*` routines) read it only behind a handler/type gate (player shot, EnemyShot, Bonus, type
0xb5b/0x2c8) that a Salamander never passes; the remaining loads are blitter stack slots `(r1)`.
The write is the Bat's wake-up idiom copied verbatim (enemies-flyers §7.3); for the Salamander it
has no effect.

### 7.2 Crush `+0x150 = 0x16`: read only by Crawler and Roach  [HIGH]
The crush idiom `+0xa4 = 0; +0x150 = 0x16` sits in nine Hit routines: Frog `10082ab0..10082abc`,
Salamander `100836d4..100836e0`, Blob `1007d894..1007d8a0`, Bat `1007f6ec..1007f6f8`, Gremlin
`10081088..10081094`, Floater `10081c14..10081c20`, Dillo `10087570..1008757c`, Crawler
`1006682c..10066838`, Roach `100781c4..100781d0`. Loads of `+0x150` in enemy routines: Crawler
`10066170..10066204` and Roach `10077dc4..10077e20` (their death counter — a crush makes them die next
frame), the swarm member and the Crab (other meanings), and two reads of the *other* sprite behind
the geyser-segment gate `type == 0x5a0` (`1006687c`, `10082b00`). So for Frog, Salamander and Blob
the value is never read; the crush kills through HP 0 alone.

### 7.3 `.GetBGTile(col, row)`; no shipped crab is in water  [HIGH]
`.GetBGTile @ 1003c204`: `.ConstrainXY(a, b, W−1, H−1, &c, &r)` with `W = hdr+0xb280`, `H = hdr+0xb282`
(`1003c22c..1003c244`; `.ConstrainXY` clamps r3 into `[0, r5]` → `*r7` and r4 into `[0, r6]` → `*r8`,
`1003be0c..1003be6c`); cell = `map[r·W + c]` (`1003c24c..1003c274`: `r` times `2W`, `c` times 2);
returns low byte − 1. So the **first argument is the column (x)**. The Crab passes `(+0xc >> 5,
+0xa >> 5)` = (x/32, y/32) (`10089594..100895ac`) — the top-left cell, correct order. Then
`.LookupBGTileKind` (`10041f98`: tile 0..95 → `*TOC−0x762c` table, else −1) and `.IsWaterTile`
(`100430c8`: 200 ≤ kind < 210).
Level 62 (W = 360, H = 60), decoded from the World Data `Mlvl 62` (BG map at `0xb29c + 2(w0h0 +
w1h1)`, kind table hdr+0x29a0): water tiles are BG 0..5 (kinds 200, 200, 203, 203, 201, 201); 102
water cells, all in rows 20..49.

| rec | type | x, y | cell (col, row) | BG tile → kind | nearest water cell |
|---|---|---|---|---|---|
| 97 | 1892 | 7620, 1655 | (238, 51) | none (−1) → −1 | (231, 28), 30 cells away (Manhattan; Chebyshev 23 — ⚑ corrected (review 2d, 2026-10-04) #7) |
| 98 | 1892 | 8098, 1655 | (253, 51) | none → −1 | 45 cells (Chebyshev 23) |
| 99 | 1892 | 8556, 1629 | (267, 50) | none → −1 | 58 cells (Chebyshev 36) |

All three get `+0x16c = 0`: the in-water `+0xb8 = 0x90000` tint (§4.1) never appears in 1.0.3.
(With the arguments swapped the cells would be kind 495, also not water — the shipped outcome does
not depend on the order.)

### 7.4 The dead Frog/Salamander water blocks in "another build"  [HIGH for the demo; UNDETERMINABLE beyond]
The archive holds exactly two Ferazel builds (ARCHIVE-INDEX rows 22–23): this 1.0.3 (PEF timestamp
2000-03-21 12:57) and the demo (`Ferazel's Wand Demo`, PEF timestamp 2000-03-13 12:41; both
`vers 2` = "1.0.3"). (The lane prompt's `$FW/../../ferazelswand/` is one level short: the demo is
`$FW/../../../ferazelswand/`.) Locating each routine in the demo by its traceback name and diffing
instruction words with branch displacements and r2-relative load/store offsets masked (the two `addi
rX,r2,…` hits below are the only unmasked r2 forms; masking them too gives **0** differing words in all
seven routines — ⚑ corrected (review 2d, 2026-10-04) #8):

| routine | full / demo words | differing words after masking |
|---|---|---|
| `.HandleFrogSprite` | 471 / 471 | 1 (`10082278 addi r3,r2,−0xa0c` jump-table address: `3862f5f4` vs `3862f4b8`) |
| `.HandleSalamanderSprite` | 283 / 283 | 1 (`1008316c`, the same kind of r2-relative `addi`) |
| `.StandardSpriteHandles` | 329 / 329 | 0 |
| `.ApplyGravityAndSeparateFromTiles` | 120 / 120 | 0 |
| `.HandleUnderWater` | 157 / 157 | 0 |
| `.HitFrogTileSprite`, `.HitSalamanderTileSprite` | 96, 103 / same | 0 |

So in the demo the blocks are dead for the same reason (the `+0x11c` zeroing at `100369ac` precedes
the test at `10082198`). Whether an earlier retail build (1.0.0–1.0.2, none archived) had them live
is **UNDETERMINABLE** from code: no such binary exists to read, and 1.0.3's own code cannot say what a
different compile contained.

### 7.5 `.AddIdleSprite`'s "lost" argument is the setup proc  [HIGH]
Callers pass six arguments (m. l. 1924: `AddIdleSprite(type, x, y, rec, 0, setup)` → r3..r8).
`10007d94..10007da4` save r3..r6; `10007df4..10007e04` re-load r3 = type, r4 = x, r5 = y, r7 = rec,
`li r6,1` (layer) and leave **r8 = setup** unwritten before `bl .MTNewSprite` (`10007e08`); no
instruction in `10007d8c..10007e08` writes r8. So `.MTNewSprite` runs the class Setup at load for idle
enemies too (same as bosses.md §1.2). The §0.1 reading is now HIGH.

### 7.6 `+0x1b2`  [pointer]
Writer = enemy pipes 1490..1493 (level 21 only; a Blob 1730 comes out of two of them). Full reading
(handler skipped, drawn, still collidable, released after length/3 + 4 frames): enemies-flyers §7.4.

## NOT RESOLVED
1. ~~Salamander `+0xa6 = 21` on hurt: no reader found in the Salamander routines or the main dump
   `+0xa6` readers.~~ → closed: §7.1 (write-only).
2. ~~`+0x150 = 0x16` written on a crush (all three killable classes): no reader found here.~~ →
   closed: §7.2 (read only by Crawler/Roach).
3. Exact rendered colours of tint tables 0x4/0xb/0xc/0xf/0x17 (assumes CLUT 200 is current
   when `.BuildTintTable` runs) and of `.BurnFaceRow` styles 1 vs 0xd.
   ⚑ wave 2 (2026-10-04): INDEX item 15, another lane — not attempted by L7.
4. ~~BloodSpray particle kinds 2 vs 0xc9 (colours);~~ (closed: kind 2 blood red, 201 olive green,
   particles §4.3 / §5.3 ⚑ wave 2 corr (2026-10-04) PA #5) Effect type 0 appearance.
   ⚑ wave 2 (2026-10-04): INDEX item 15, another lane.
5. ~~`.GetBGTile` argument order (Crab water test) and whether any level-62 crab sits in water.~~ →
   closed: §7.3 (col, row; none in water).
6. ~~Whether the Frog/Salamander dead water blocks were ever live in another build (only 1.0.3
   read).~~ → closed: §7.4 (dead in the demo build too; other builds UNDETERMINABLE — none archived).
7. ~~`.AddIdleSprite`'s lost `MTNewSprite` argument (setup proc) — the load-time Setup reading
   rests on the `.MTNewSprite` body.~~ → closed: §7.5.
8. ~~The `+0x1b2` "contained" meaning (writer is `.HandleBoxSprite`; not traced further).~~ →
   closed: §7.6 / enemies-flyers §7.4.

## Proposed additions to physics.md §0
| off | type | meaning (this file) |
|---|---|---|
| +0x50 | proc | kill proc, called by `.HandleBurn` when the dissolve ends (Frog, Salamander) |
| +0x88 / +0x8a / +0x8c / +0x8d / +0x8e | u8 | lit (WrapLightFace) / water current applies / burn sound variant / burn rows−1 per frame / burn style 0xd |
| +0x90 | i16 | wind response (0 = immune; enemy shots 0x100) |
| +0x9c | ptr | Crab: link block (12 ptrs + count at +0x30) |
| +0xa6 | i16 | per class: Blob pause timer; Crab strike frame / cooldown; shots: age |
| +0xb0 / +0xb2 | i16 | state / sub-phase (Blob pulse) |
| +0xb8 | i32 | draw mode `mode<<16 | sub` (§0.2) |
| +0xc0 | ptr | current face record (`.WrapDrawSprites`) |
| +0xcd | u8 | standing on a sprite (`.PlatformBounce`); also the start-of-frame copy of `+0xce` (`.StandardSpriteHandles` `100368c4..c8`) — both hold (physics §0.1, synthesis ledger A5) |
| +0xea | u8 | clear placement flag on removal |
| +0xf0 | i32 | Frog voice pitch (0x10000 = 1.0) |
| +0x130 / +0x134 | i32 | statue frames left / saved `+0xb8` |
| +0x140 | u8 | water handled this frame |
| +0x14c | i32 | Frog/Salamander decision counter (counts up to 0); Blob last side; Crab reach |
| +0x150 / +0x154 | i32 | Crab anchor x / y; Frog `+0x154` hop-chain counter |
| +0x158 | i32 | Frog jump vx |
| +0x15c | i32 | Frog variant (= p1); dead-blob timer |
| +0x16c / +0x170 | i32 | Crab in-water flag (setup) / strike vector x, y |
| +0x1a2 | i16 | burn row (0 = not burning) |
| +0x1aa | i16 | face rotation angle, degrees (copied to face +0x1a) |
| +0x1b2 | u8 | ~~inert (inside a container) [MED]~~ ⚑ wave 2 (2026-10-04): emerging from an enemy pipe — handler skipped, still drawn and collidable [HIGH] (§7.6) |
| +0x1b5 | u8 | counts toward the enemies stat |
| +0x1bc | i16 | rows clipped from the face top |
| +0x1ec / +0x1f0 / +0x1f4 | proc | saved handler / hit / tile-hit while a statue |

## Corrections to the existing bank
1. physics.md §7 table, Frog HP "500, 350, 1000" → selection by placement p1: 0 → 350,
   1 → 500, 2 → 350, 3 → 1500, 4 → 1000, other → 500 (raw `@10082014..100820a8`).
2. physics.md §7, Blob HP "1500, 700, 1100, 2000" → by type 1730/1731/1732/1733 = 700/1100/
   1500/2000; 1734..1739 get 0 (raw `@1007ce0c..1007ce88`).
3. physics.md §7, Crab "HP 1000": never reduced — `.HitCrabSprite` only destroys the shot;
   the crab is invulnerable and has no tile callback (§4.4).
4. physics.md §0 `+0x17e` "facing left": it is the blitter flip flag; for Frog, Salamander,
   Blob, Crab a value of 1 = facing right (§0.1). Other classes not checked.
5. physics.md §7 "variants… conditions not traced" (INDEX NOT-RESOLVED 6) — resolved for these
   four classes (Frog p1, Blob type, Salamander single, Crab type = aim window only).
6. world-data-format.md §4.3 "[MED: which counter is which not traced]": G+0x306/G+0x6ee is
   the enemies-defeated pair (§0.1, main dump l. 2521–2534, KillFrog raw `@10082c30..58`).
7. spells-items.md §2.1 Statue: add the thaw penalty HP −200, the grey tint 0x1000b, the
   last-20-frame blink, layer 2, and that the statue hangs without gravity (§5); the Crab is a
   non-boss without the Statue test.
8. physics.md §2 / §0 `+0x11c`: add that `.StandardSpriteHandles` zeroes `+0x11c` each frame
   (when `+0x118 < 0x1d`), so it is valid only after the frame's `.HandleUnderWater`; handlers
   that read it earlier (Frog, Salamander water blocks) never see water (§0.1). Other classes'
   handlers should be checked for the same ordering.
9. physics.md §2 water gravity `max(0.7·g, 0x100)` — add the caveat (review 1a #2, adjudication 4):
   the branch is taken only when `+0x11c ≠ 0` at the routine's entry (`100375c8`), before its own
   `SeparateFromTiles2` (`10037624`); after the per-frame zero (`100369ac`) it is 0 on each sprite's
   first call, so dry gravity applies; only a second same-frame call (Frog) or a sprite whose
   `+0x11c` is written directly between clear and call (Bonus 1055 in-water flag, 1350 air bubble)
   can take the 0x100 branch.
10. physics.md §7 (review 1a #5, adjudications 2–3): Bat HP "100, 200" → 1740 family 500
   (`1007dcbc cmpwi 0x6d6; bge` → `1007dcc0 li 0x1f4`), 1850 family 100 (`1007dde0`), insects 200
   (`1007e144`); "Statue/Box/Platform set +0x185" — the Statue does **not** (no `0x185` store in
   `100664a8–100665bc` or `10043138–100431c4`; thaw `lha 0xa4; subi 0xc8; sth` at
   `1006656c–10066574`, `+0x130 = 0x78`, `+0x134 ← +0xb8` at `10043194–1004319c`); Floater rect
   (0x17,2,0x38,0x5c) → shipped 1780 (0x23,1,0x3e,0x4b) at `10081550–1008155c`.
11. spells-items.md §2.1 (review 1a adjudication 1): names only — id 2 = "Ice Crystals" (cost 10,
   gravity 0, unholdable), id 3 = "Ice Wall" (cost 0x1e `1005213c`, dmg 0x12c `10052138`; floes
   `1005a2e4–1005a30c`, ledges `1005b2c4/1005b2f4`), id 7 = second Ice-Wall icon (cost 0xc, dmg
   0x96, gravity 0xfa, no floe); PICT 700 captions 0..11 = Fireball, Statue, Ice Crystals, Ice Wall,
   Tree Trunk, Boomerang, VBlade, Ice Wall, DensityBall, Sandstorm, EnergyBolt, Ice Shards.

Wave 2 (2026-10-04) corrections:

| # | file § | old | new | evidence |
|---|---|---|---|---|
| W1 | INDEX.md item 18 | open | closed: §7.1 (`+0xa6 = 21` write-only), §7.2 (crush `+0x150` read only by Crawler/Roach), §7.3 (`.GetBGTile(col,row)`, no crab in water), §7.4 (demo identical; earlier builds UNDETERMINABLE) | this file |
| W2 | world-data-format.md §3.3 "Getters clamp `x,y`" | arg order implied | state it: every `.Get*Tile(a, b)` that goes through `.ConstrainXY` takes **(column, row)** — shown for `.GetBGTile` (`1003c204..1003c27c`) [HIGH]; other getters not re-checked here | §7.3 |
| W3 | bosses.md §1.2 / pickups-boxes.md (`_DAT_1009fe8c`) | from the decompile | raw: `10004da4..10004dc0` (`stb 1`, `bl .SetupLevelSprites`, `stb 0`) | enemies-ground-2 §4 |
