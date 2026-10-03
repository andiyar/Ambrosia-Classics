# Ferazel's Wand 1.0.3 — spells detail, part 2: gates, visibility test, steering, list order, followers

Code readings only; nothing behaviour-verified. Date 2026-10-04.
Sources: raw listing `ghidra/Ferazel_pef.disasm.txt` (every HIGH cites it), main dump
`ghidra/Ferazel_pef.decompiled.c` ("main l."), handler dump `ghidra/Ferazel_handlers.decompiled.c`
("handler l."), jump tables and data words via `tools/pef.py`, TOC loads via `tools/tocrefs.py`.
Wave 2 (2026-10-04) continuation of `spells-detail.md` (part 1, 450 lines); closes INDEX item 23 and
the open rows of part 1's NOT RESOLVED list. Labels as INDEX §Labels. Field names per physics §0.

## 1. `.HandleKeys` gate globals and the item latch  [HIGH]

`.HandlePlayerSprite` calls `.HandleKeys` only while `*_DAT_100a06f0 == 0` (`1004e66c..1004e688`);
`.HandleKeys` itself returns at once on three more gates (`10052b1c..10052b64`). Every TOC load of each
slot was followed through its register to every store and load (hazard 2):

| global | meaning | writers | readers |
|---|---|---|---|
| `*_DAT_100a06f0` (i16) | **door-transit counter / input lock**: 1..22 while entering a passage, −22..0 while leaving (+1 per frame of passage contact) | `.ClearPlayerVars`, `.SetupPlayerSprite` (0); `.HitPlayerSprite` passage arm (`10057f68..10057f78` +1, `100581b4..100581bc` −22) | `1004e66c` (≠ 0 → no `.HandleKeys`, L/R bytes cleared, `vx = vy = 0`, `1004e694..1004e6ac`); full timeline triggers-background-2 §8.2 |
| `PTR_DAT_100a0700` (i16) | **teleporter charge** (player-states §3.6): +1 per frame touching a teleporter, −8 otherwise (`10050ff8..10051048`); 21..59 sparkle tint, 60..79 → 79, 80 → fire request; −59 after teleporting, counts back up | `.ClearPlayerVars`; `.HandlePlayerSprite` (`10051008..10051048`, `10051114..1005111c`); `.HitPlayerSprite` (`10057700`) | `.HandleKeys` `10052b1c..10052b34`: **return while \|charge\| > 30**; `1005352c..10053548`: LEFT/RIGHT block skipped while \|charge\| > 20; tint code `1005104c..1005110c` |
| `_DAT_100a05b0` (i16) | potion-drink counter (player-states §2) | `.HurtPlayer`, `.HandlePlayerSprite`, `.HandleKeys` (`10053404`) | `.HandleKeys` `10052b38..10052b54`: > 0 → zero the wand step and crouch, return |
| `_DAT_100a0570` (i16) | **boss-grab counter** | 0x18 by `.HandleChiefSprite` (`1008bbc8..1008bbd0`), 0x14 by `.HandleXichraSprite` (`1008f3e4..1008f3ec`); −1/frame `.HandlePlayerSprite` (`1004df44..1004df5c`); 0 by `.HitPlayerSprite` (`10057be8..10057bf0`) and `.ClearPlayerVars` | `.HandleKeys` `10052b58..10052b64` (> 0 → return); state selection `1004fb90` (player-states §3.4) |
| `_DAT_100a075c` (u8) | **item USE latch** (one item action per press) | 1 at a spell cast press (`100531d0..100531d4`) and at an item press (`100532b8..100532bc`); 0 at `100534e4..100534ec` whenever USE is up, the selected slot is a spell (`slot+0x2c ≠ 0`, `10053244..10053258`), the shield is raised, the player clings, or is on a rope (`1005325c..10053280`); 0 by `.ClearPlayerVars` | only `10053294..1005329c` (item path: latch set → no action) |
| `PTR_DAT_100a04cc` (u8) | **"just stood on a BG-layer surface" timer** | 15 by `.HitPlayerTileSprite` when `.WallBounceBG` reports contact while `+0xce ≠ 0` (`100551fc..10055218`); −1/frame `.HandlePlayerSprite` (`10051ca4..10051cbc`) | only the glider stow: `y += 0x0a` px if ≠ 0, else `y += 0x20` px (`1004f234..1004f260`) |

Two consequences [HIGH]:
- The spell-press write `_DAT_100a075c = 1` is **dead**: the cast path ends `bl .MoveSelectedItemToFront;
  b 0x10053230` (`10053218..10053220`), which enters the item block in the same call; the selected slot
  is still a spell, so `10053250..10053258` branches to the clear at `100534e4`. The latch therefore never
  survives a spell press; part 1 §2.1's "latch = 1, `_DAT_100a075c = 1`" is as written but without effect.
- The glider's 10 px vs 32 px drop: within 15 frames of landing on a BG-tile surface (kind 100..199,
  `.WallBounceBG`) the stowed player is moved down only 10 px. Why the designers distinguished BG ledges
  is UNDETERMINABLE; the rule is as stated.

## 2. The light / impact "on-screen" test is a wall-tunnel visibility test  [HIGH]

The test `face+0xe ≤ s+0x1b6 || s+0x1b8 ≤ face+0xa` (part 1 §3.2, §3.7) reads:
- `face+0xa`, `face+0xe` = **left and right of the face's opaque-bounds Rect** at face `+0x08`
  (top, left, bottom, right; sprites-backgrounds-sounds §2.1 [HIGH there]); the same Rect is what
  `.ActiveToIdleSprite` copies into an idle entry (`10007f20..10007f3c`, triggers-background-2 §8.3).
- `s+0x1b6`, `s+0x1b8` = left-skip / right-edge draw clip (physics §0.1). For a player shot only two
  routines write them (raw scan of every `sth …,0x1b6(`/`0x1b8(`): `.StandardSpriteHandles` resets them to
  0 / 32000 at the top of every handler call (`100368a8..100368bc`), and `.StandardSpriteCleanup` sets them
  only inside a **wall-tunnel window** (`+0x1be..+0x1c4`, InitSprite 32000 = no window; `10036f20..10036ff0`,
  triggers-background §2.12). The other writers (`.HandleBoxSprite` `1006efa0`, `1006efe0`, `1006f048`,
  `1006f058`) clip the emerging child of Box 0x5d2..0x5d5, never a shot.

So the condition is "the visible column window `[+0x1b6, +0x1b8)` misses the opaque columns" — the shot is
entirely hidden inside a wall tunnel. **Nothing tests the screen.** Call order (hazard 3):

| site | when the fields are read | effect |
|---|---|---|
| `.HandlePlayerShotSprite` age-1 block (`10059f7c` Cleanup, `10059f90..10059fa0` test; handler l. 5323–5331) | after a mid-handler `.StandardSpriteCleanup` | `AddLight` skipped if hidden |
| end of every handler call (`1005a77c` Cleanup, `1005a790..1005a7b4` test; l. 5562–5567) | after the end-of-frame Cleanup | `.RemoveLight` if hidden — the light is never re-added (only age 1 adds one), so a shot that passes a tunnel loses its glow for good |
| `.KillPlayerShot` `1005ad10..1005ad3c` | from `.MTCollideSprites` (after all handlers, `.HandleSprites` `10007c30..10007c38`): this frame's tunnel clip; from the tile callback (inside `.SeparateFromTiles2`, after the top-of-handler reset): 0 / 32000 except on the age-1 frame | `r26` (the caller's effect flag) = 0 → the effect-sprite arms tested at `1005ad68` (id 0) and `1005afe8` (ids 1–7, 0x3c) are skipped; so in practice only a sprite-hit kill inside a tunnel suppresses the impact effect |

Part 1's "no effect sprite when the face is off-screen" is therefore wrong (correction S1).

## 3. Boomerang steering (`FUN_1003f218`, name proposal `.AddDirImpulse`)  [HIGH]

Call site (`.HandlePlayerShotSprite`, id 5, `10059c58..10059cb0`; handler l. 5198–5211): when the shot's age
`+0x14c` > 12 (`10059c5c cmpwi r0,0xc; ble`), every frame:
1. target = the player's centre Point `*(player+0xe)` (v = centre y, h = centre x) with **v − 4**
   (`10059c64..10059c80`); from = the shot's centre Point `+0xe` (`10059c84`);
2. `dir = .FindDesiredDirectionGeneric(target, from)` (`10059c88`) — the 10°-step direction 0..35 of the
   vector from the shot to the target (enemies-flyers §1.1; 0 left, 9 down, 18 right, 27 up);
3. `FUN_1003f218(shot, dir, 800)` (`10059c98..10059c9c`): returns at once for a null sprite
   (`1003f218..1003f21c`) or dir > 35 (`1003f224..1003f228`); else a jump table at `0x100a5694`
   (`1003f22c..1003f23c`) adds an impulse of magnitude 800 to the **velocity**: dir 0 → `vx −= m`
   (`1003fb60..1003fb68`), 9 → `vy += m` (`1003fff0..1003fff8`), 18 → `vx += m` (`1003f240..1003f248`),
   27 → `vy −= m` (`1003f6d0..1003f6d8`), others `vx −= cos(10k)·m`, `vy += sin(10k)·m` with the doubles at
   0x100a18b0..0x100a18c8 (dir 1: `lfd f2,-0x5f78(r2)` = 0.985, `1003fb70..1003fbc8`);
4. `.EnforceMaxSpeed(shot, 0x1450)` (`10059ca4..10059cac`): if |vx| > 5200, scale vy by 5200/|vx| and set
   |vx| = 5200; then if |vy| > 5200 the same with the axes swapped (main l. 36553ff) [HIGH arithmetic,
   MED that the integer division truncates toward zero as C does].

The velocity is integrated later in the same handler call (`vy += 0`, id 5 has gravity 0; `x += vx`).
So the boomerang flies straight for 12 frames, then accelerates 800/256 ≈ 3.1 px/frame² toward a point
4 px above the player's centre, capped at 20.3 px/frame per axis; it is caught on contact after age 10
(part 1 §3.7) — it has no lifetime and never stops homing.

## 4. Same-frame handling of new sprites (active-list order)  [HIGH]

- `.MTNewSprite @ 10033060`: next-fit allocation over 700 slots of 0x1fc bytes with the cursor
  `*_DAT_100a01c4` (`10033094..100330c0` fast path, `100330c4..10033160` scans), clears the slot
  (`100331b8..100331c0`), stores type/x/y/layer/record index, **calls the Setup proc**
  (`10033210..1003321c`), then `.MTInsertSprite` (`1003322c`) — so a Setup may change the layer `+0x80`
  before insertion, and sprites created *inside* a Setup (the shot's followers) are inserted *before* their
  creator.
- `.MTInsertSprite @ 10032f1c`: the list is sorted by layer ascending; a new sprite becomes the head if its
  layer is below the head's (`10032f38..10032f5c`), otherwise it is linked before the first sprite whose
  layer is **strictly** greater (`10032f74..10032f9c`, `cmpw; bge`) — i.e. after every sprite of equal or
  lower layer — or appended.
- `.MTHandleSprites @ 1003259c` loads the next pointer **before** calling the handler
  (`100325b8 lwz r12,0x4c(r3)`, `100325bc lwz r31,0x68(r3)`, call, `100325d0 or r3,r31,r31`).

A spell is cast from inside the player's handler (part 1 §2.2: `.HandleKeys` → step 4 → `.CastSpell`).
The player is layer 10 (`1004afac`), shots and followers layer 11. Mechanically: the new sprite is linked
before the first sprite (walking from the head) whose **current** `+0x80` exceeds 11; it is handled in the
creation frame **iff that point lies beyond the player's cached successor**, i.e. iff the sprite right
after the player has `+0x80 ≤ 11`. In the normal sorted list that means: at least one layer-10/11 sprite
follows the player (a layer-11 effect or earlier shot, a Bat/Crawler/Floater/Frog/Roach/Salamander —
their Setups set 11 —, or a layer-10 sprite created after the player). Otherwise the new shot and its
followers sit directly between the player and its cached successor and are first handled next frame.
(Handlers that store `+0x80` directly — Walker, Crawler, Roach set 11 in their Handle — do not re-sort;
only `.MTChangeSpriteLayer @ 10033288` removes and re-inserts, main l. 30727–30735.)

Consequences for part 1 §2.4:
- In the creation frame the shot always takes part in `.MTCollideSprites` (which runs after all handlers,
  `.HandleSprites` `10007c30..10007c38`) with its **base** damage: the ×power multiply needs age 1, and
  age goes −1 → 0 on the first handler call.
- Frame 2: if the shot was handled at creation, age reaches 1 in frame 2's handler → multiplied before
  frame 2's collisions; if not, age is 0 in frame 2 → a frame-2 hit is still base damage, multiplied from
  frame 3.
- Followers precede their main in the list, so each frame they integrate their own `x += vx` first and are
  then overwritten by the main's placement (handler l. 5480ff) — their drawn position is always the
  main's current one; no follower lag exists.

## 5. Follower lifecycle: kills, orphans, slot reuse  [HIGH mechanism; LOW frequency]

**Kill pipeline** (`.UpdateSprites`, once per frame after `.HandleSprites`; main l. 4934–5032): a sprite
with `+0xe9 = 1` stays linked for three passes (`1000996c..10009970` test `e9 < 4`; each pass `e9 += 1`
`10009a74`, hit/tile procs and face cleared, type negated `100099b4`, light removed, record flag cleared)
and is unlinked by `.MTKillSprite` on the fourth (`10009a58`), which frees the slot (`+0 = 0`). The walk
restarts from the head after every kill. Most handlers — the shot's included — return at once while
`+0xe9 ≠ 0`.

**Paths that kill a main shot without killing its followers** (all others go through `.KillPlayerShot`,
which flags the four followers `1005ac88..1005acc4`, or the liquid rule, which flags them
`1005a360..1005a39c`):

| path | raw | id |
|---|---|---|
| level-bottom rule `y > H·32` | `1005a3a0..1005a3c8` | all |
| V-Blade ±500 px rule | `10059cec..10059d24`, `10059d60..10059d98` | 6, 0x3c |
| Tree Trunk landing | `1005b3b8..1005b3c0` (`.HitPlayerShotTileSprite`) | 4 |
| Tree Trunk growth | `1005aa34..1005aa3c` (`.HitPlayerShotSprite`) | 4 |

On the kill frame the main's handler still finishes (it does not re-test `+0xe9`), so its followers are
placed once more; from the next frame they are **orphans**: power 0, gravity 0, `vy` never written (0
from the slot clear), `vx` = the main's last value.

**What an orphan does** (as written): its own handler keeps running — age, id branch (id 4 emits 7
particles per frame; id 6/0x3c applies the ±500 rule to itself, so V-Blade orphans die as soon as they
are 500 px from the player's y — they are at the main's y), `x += vx`; it has **no tile interaction at
all** (`.SeparateFromTiles2` skips everything when `+0x1f8 == 0`, `1003c86c..1003c874 → 1003cec8`), no
liquid kill (needs `+0x11c`, set only through the tile callback), and with `vy = 0` the level-bottom rule
cannot fire (wind cells can still add to its `vy` — `+0x90 = 0x100` from Setup, triggers-background-2
§8.4). It therefore flies horizontally through walls until something else consumes it: an enemy
whose Hit routine accepts player shots (`+0x4c == HandlePlayerShot && +0xa6 == 0` → `.KillPlayerShot(f,0,0)`,
0 damage, petrify if id 1 — part 1 §2.4 item 3), or a Button (`.HitButtonSprite` sets level 11 for a
player-shot hitter — an orphan can **press a switch**, triggers-background §1). Otherwise it lives until
the level is left. A Tree-Trunk orphan of a power-5 cast is 4 invisible sprites × 7 particles/frame.

**Slot reuse.** The main never clears `+0x1d4..+0x1e0` (Setup writes them once, the follower block only
reads them, handler l. 5480–5545). If a follower dies while its main lives (e.g. consumed by an enemy that
the main does not touch), its slot is freed three frames later and the main keeps writing `+0xc`, `+0xa`,
`+0x14`, `+0x1c`, `+0x24` and `+0x1aa` into it every frame. `.MTNewSprite` hands that slot out again only
when its next-fit cursor reaches it: the followers were allocated just below the main, so the cursor has
already passed them and reuse needs the cursor to wrap past slot 699 (`10033098 cmpwi r10,0x2bc`) or the
slots above it to fill — hundreds of allocations. If it happens, the newcomer (any class) is dragged to the
follower position with the main's vx each frame for the rest of the main's life [HIGH that the code
allows it; LOW how often it occurs in play].

## 6. Part-1 rows closed by other files  [HIGH by reference]

- NR 4: enemy shot 0x77b = the Goblin Chief's boulder (enemy-shots-and-damage §1, spawner Chief
  `+0x46 == 7`); Box 0xb7c = gate 2940 (switch / boss / timer gate), 0xb7d = weakened ice wall 2941
  (triggers-background §1); Bonus 0x517 = rock pile 1303, 0x51b = torch 1307 — for 1307 `+0xb0` = "not yet
  opened" (1 when p4 = 0, pickups-boxes §1.5); 1303's Setup writes no `+0xb0` (its arm, handler l. 6792–6794,
  is only `SetRect(2,−8,0x1c,0xb)`) and InitSprite zeroes it, so the `0x517` arm of `.HitPlayerShotSprite` (part 1
  §3.7 row "Bonus types 0x517/0x51b") never fires for a placed rock pile [MED: no other `+0xb0` writer
  for 0x517 was searched beyond the Setup].
- NR 6: no shipped scroll grants spell 7 (INDEX 11 → pickups-boxes §1.7).
- NR 7: trunk `+0xa6` = lifetime with blink and kill (pickups-boxes §2.4.9); `.TurnIntoStatue(s)` takes no
  power argument — duration 120 frames and thaw damage 200 are fixed (enemy-shots-and-damage §2.2), so
  power does not change the Statue spell.

## NOT RESOLVED

1. (Part 1 NR 1, carried) `.NewParticle` arguments and effect-sprite visuals — INDEX items 15/28, not
   this lane.
2. The byte `0x100a5114` cleared by the camera look-ahead decay and read by `.FindUpperLeftCorner`
   (triggers-background-2 NR 12) — camera owner.
3. How often follower-slot reuse (§5) happens in real play — needs a behaviour run; the code permits it.
   Tried: allocator arithmetic only.

## Proposed additions to physics.md §0

| off | type | meaning |
|---|---|---|
| +0x00 | u8 | slot in use: `.MTNewSprite` 1, `.MTKillSprite` 0 (`100331c8..100331cc`) [HIGH] |
| +0x6c | ptr | previous in the active list (`.MTInsertSprite`/`.MTRemoveSprite`/`.MTKillSprite`) [HIGH] |
| +0x80 | i32 | layer = **active-list sort key**, ascending, ties after existing sprites; read at insertion only (`10032f38..10032f9c`), so a Setup's own layer write counts (Setup runs before insertion) [HIGH; replaces "[MED]"] |
| +0xe9 | u8 | kill request: `.UpdateSprites` advances 1→2→3→4 (procs, face, light cleared, type negated) and unlinks/frees at 4 (`1000996c..10009a74`) [HIGH] |
| +0x1d4..+0x1e0 | ptr ×4 | (extends part 1) shot followers — never cleared by the main, so they dangle after a follower dies (§5) |

## Corrections to the existing bank

| # | file § | old | new | evidence |
|---|---|---|---|---|
| S1 | spells-detail §3.2 / §3.7 (owned — corrected in place) | lights/effects gated by an "on-screen test" [MED] | a wall-tunnel visibility test; face +0xa/+0xe = opaque-bounds left/right | §2 |
| S2 | enemy-shots-and-damage.md §3.5 and NR 3 ("`_DAT_100a0570` … its setter not found") | setter not found | set to 0x18 by the Chief (`1008bbc8..1008bbd0`), 0x14 by Xichra (`1008f3e4..1008f3ec`); −1/frame `1004df44..1004df5c`; zeroed by `.HitPlayerSprite` `10057be8..10057bf0` (player-states §2 already had the setters) | §1 |
| S3 | physics.md §0 `+0x80` | "layer (MTNewSprite arg) [MED]" | the active-list sort key, effective value = whatever Setup leaves (Setup runs before insertion) [HIGH] | §4 |
| S4 | enemies-flyers.md §1.1 `FUN_1003f218` | `[name proposal: AddDirImpulse]` table from the decompile | confirmed from raw: jump table `0x100a5694`, null/range guards `1003f218..1003f228`, cases 0/9/18/27 at `1003fb60`/`1003fff0`/`1003f240`/`1003f6d0` | §3 |
