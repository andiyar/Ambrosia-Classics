# Ferazel's Wand 1.0.3 — bosses (1 of 2): shared boss framework, Warrior, Wizard, Goblin Chief

**Code readings only; nothing behaviour-verified.** Date 2026-10-03.
Sources: `ghidra/Ferazel_handlers.decompiled.c` ("handler dump", sprite callbacks),
`ghidra/Ferazel_pef.decompiled.c` ("main dump", helpers), `ghidra/Ferazel_pef.disasm.txt` (raw
disasm, cited as bare addresses), data constants via `tools/const.py`, TOC/TVector slots resolved
by reading TOC word → `word + 0x1009f840` → TVector code word → traceback name (scratch script;
same arithmetic as `tools/tocrefs.py`), level data via `tools/rsrc_census.py`.
Scope: Warrior 1820..1829, Wizard 1830..1839, Chief 1910..1919, Demon / Fire Guardians
1920..1929, Xichra 1990..1999, and the main-dump helpers they call. Part 2 (`bosses-2.md`):
Demon, Xichra, boss projectiles, NOT RESOLVED, proposed §0 fields, corrections.

Conventions. Sprite fields as in physics.md §0. `SetRect` arguments are quoted in Toolbox order
`(left, top, right, bottom)`; the stored Rect at `+0x34` is `(top, left, bottom, right)`.
Velocities are 1/256 px per frame. `FastRand(n)` returns 0..n−1 (Park–Miller 16807 step,
`.FastRand @ 100340e0`, main dump l. 31106ff) [HIGH]. "Placement param k" = the i16 at record
`+4+2(k−1)`, read as `hdr + idx·0x10 + {8,0xa,0xc,0xe}` (world-data-format.md §3.4). Sound ids are
`snd ` resource ids resolved through `.InitSounds @ 10045838` (`FUN_10091748(id)` =
`GetResource('snd ', id)`) and named from the Sounds file's resource map (table §1.8).

---------------------------------------------------------------------------------------------

## 1. Shared boss framework

### 1.1 Placement census and parameters  [HIGH]
Python over every `Mlvl` (record layout world-data-format.md §3.4): exactly one boss record per
boss level, all flag 1, record byte +1 = 0.

| level | rec | type | p1 | p2 | p3 | p4 | y | x | hdr 0x2724 | hdr 0x272e | music 0x284a |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 5 Manditraki Warrior | 0 | 1820 | 0 | 0 | 0 | 1 | 227 | 875 | −1444 | 0 | 23 |
| 18 Goblin Chief | 1 | 1910 | 0 | 0 | 0 | 1 | 410 | 897 | −1400 | −640 | 23 |
| 25 Manditraki Wizard | 1 | 1830 | 0 | 0 | 0 | 1 | 786 | 931 | 592 | 1384 | 23 |
| 55 Fire Guardians | 7 | 1920 | 0 | 0 | 20 | 1 | 105 | 1095 | 16000 | −448 | 23 |
| 67 Xichra's Lair | 5 | 1990 | 0 | 0 | 0 | 0 | 78 | 342 | 0 | 0 | 28 |

Parameter use (every record read in the boss code, grep of `* 0x10 +` over both dumps):

| class | p1 | p2 | p3 | p4 | byte +1 |
|---|---|---|---|---|---|
| Warrior | — | written 150 if 0 (`lhau r0,0xa(r3)` 10087a00, `li r0,0x96` 10087a0c), never read by the boss code | — | **boss flag**: ≠0 → HP 2000 + boss mode; 0 → HP 1200 (handler l. 20066–20077; `li r0,0x4b0` 1008795c / `0x7d0` 10087968) | not read |
| Wizard | — | same 150 write (l. 22036–22039, 1008c814), never read by the boss code | — | **boss flag**: ≠0 → HP **1000**; 0 → 1200 (l. 22011–22021; 1008c75c / 1008c768) | not read |
| Chief | — | — | — | **boss flag**: ≠0 → HP 2000; 0 → 1200 (l. 21516–21528; 1008b600 / 1008b60c) | not read |
| Demon | — | — | **partner offset**: second guardian at x − p3·32 (l. 21001) | **boss flag**: ≠0 → HP 2000; 0 → 1000 (l. 20943–20953; 1008a178 / 1008a184) | not read |
| Xichra | — | — | — | not read (HP 5000 fixed, `li r9,0x1388` 1008dd98) | not read |

Placement x/y: used by all except Xichra, whose Setup overwrites the position with (x 0x145 = 325,
y 0x48 = 72) (l. 22704–22705; 1008df0c/1008df14) [HIGH]. No boss Setup or Handle reads its own
type (`+4`) except the Demon (0x780/0x781 special-cased, part 2), so every type in each 10-wide
range behaves identically to the placed one [HIGH, grep of `param_1 + 4)` over l. 20023–23708].

### 1.2 Spawn timing, the "no boss alive" flag, enemy counting  [HIGH unless noted]
- Warrior, Demon, Xichra spawn **now** (`MTNewSprite`), Wizard and Chief **idle** (world-data
  §3.5). Both paths run the Setup during `.SetupLevelSprites`: `MTNewSprite` calls the setup proc
  immediately (`FUN_1009f80c(sprite)` before `MTInsertSprite`, main dump l. 30679–30683), and
  `.AddIdleSprite @ 10007d8c` passes its caller's r8 (= setup proc from `.GenerateSprite`)
  untouched into `bl MTNewSprite` at 10007e08 (r3..r7 re-loaded, r8 never written), then snapshots
  and kills the sprite; `.IdleToActiveSprite` later restores the snapshot without re-running Setup.
- `_DAT_1009fed0` (u8, below "no boss alive"): `.SetupLevelSprites` sets it to 1 (main l. 2019)
  before spawning; a boss Setup with the boss flag set (all Xichra) writes 0; the boss Kill routine
  writes 1 (Demon: only when both guardians are dead, part 2). Because both spawn paths run Setup
  at load, the flag is already 0 when `.GameLoop` starts in levels 5/18/25/55/67 [HIGH: raw
  10007df4–10007e08 reloads r3, r4, r5, r7, `li r6,0x1`, and never writes r8 before `bl 0x10033060`
  (MTNewSprite) — ⚑ corrected (review 1b, 2026-10-03) #9, raised from MED].
- `PTR_DAT_1009fed4` (u8, "arena locked"): cleared by `.SetupLevelSprites` (l. 2016), set by
  `.PlayerConstraints` (§1.3).
- Enemy count: each boss Setup, if `_DAT_1009fe8c` (set 1 only around `SetupLevelSprites`, main
  l. 2524–2528) is set, sets `+0x1b5 = 1` and increments `_DAT_1009ffb4`; `.SetupLevel` copies that
  count into the level's enemy total `G+0x6ee+2L`. A Kill routine with `+0x1b5` set and `+0xe9`
  still clear decrements the count and increments `G+0x306+2L` (enemies defeated) (e.g.
  `.KillWarrior` l. 20477–20482). The 16 Demon neck segments are counted too (part 2 §5.5).
- Every boss sets `+0x18a = 1` (Demon/Warrior/Wizard/Xichra; Chief does not): `.UpdateSprites`
  then never copies the boss's type/x/y back into its record (`.UpdateSprites @ 1000982c`,
  main l. 4924–4930: guard `+0x188/+0x18a/+0x189` clear and `+0x48 ∈ [0,0x1ff)`). Record index 0x1ff is the
  "no record" sentinel for that guard [HIGH].

### 1.3 Boss arena: player lock and camera  (hdr 0x2724 / 0x272e)  [HIGH arithmetic]
Active only while `_DAT_1009fed0 == 0` and hdr+0x2724 = `v` ≠ 0.
- `.PlayerConstraints @ 1004cb4c` (main l. 43386–43449): `v < 0`: if player x < |v + 60| → if
  not yet locked, `_DAT_1009ff9c = −40` (camera pan counter), then `fed4 = 1`; else if locked and
  x > |v + 60| → x clamped to |v + 60|. `v > 0`: mirror image with |v − 60| (lock when x > it,
  clamp x ≥ it once locked). The arena is the side of `|v ∓ 60|` the boss is on.
- `.FindUpperLeftCorner @ 1000b5ec` (main l. 5905–5960, clamp at l. 6133–6137): bounds on the
  camera left `h`: `h ≥ lo`, `h + 0x260 ≤ hi`. Unlocked: `v<0` → lo = |v|; `v>0` → hi = |v|
  (camera stops at the arena edge). Locked: `v<0` → hi = |v|, lo = |v| − 0x260 while the pan
  counter is negative, else −32000, then lo = |hdr+0x272e| if that is ≥ lo; `v>0` → lo = |v|, hi =
  0x7f60 (counter < 0) / 32000, then hi = |hdr+0x272e| if ≤ hi. While `_DAT_1009ff9c < 0` it
  counts up 1/frame and shifts both bounds by 16·|counter| (40-frame pan).
- Per level: 5 → lock when x < 1384, camera window then [map left, 1444]; 18 → x < 1340, window
  [640, 1400]; 25 → x > 532, window [592, 1384]; **55 → v = 16000: lock needs x > 15940, so the
  Fire Guardians never lock the arena** (only the gate and music of §1.4 apply) [HIGH for the
  arithmetic, MED that no level-55 geometry reaches x 15940]; 67 → v = 0, no arena.
- Chief only: its idle timer advances only while `fed4` is set (§4). Warrior: its decision state
  returns early (no gravity, no AI) while `fed4` is clear (§2).

### 1.4 What a boss kill triggers  [HIGH unless noted]
Death sequence common to Warrior/Wizard/Chief/Demon: when `HP ≤ 0` and state ≠ 4, the Handle sets
state 4, `+0x46 = +0xa6 = 0`, plays snd 703 (vol 0x100). State 4 animates the death frames and at a
class-specific frame sets `+0x1a2 = 1`, which starts `.HandleBurn @ 10043cd8` (called from
`.StandardSpriteCleanup` while `+0x1a2 ≠ 0`, main l. 32436): the face burns away row by row
(`.BurnFaceRow`, `+0x8d + 1` rows/frame; first row plays the burn sound `PTR_DAT_100a01ec`);
negative `+0x1a2` is a delay that counts up to 1. When the burnt row passes the face height the
**Kill callback `+0x50`** is called (else `+0xe9 = 1`) (main l. 38598–38608).
Kill routines (`.KillWarrior` l. 20464–20496, `.KillWizard` 22510, `.KillChief` 21897,
`.KillDemon` 21430, `.KillXichra` 23654):
1. Enemy count/defeated stats (§1.2). `+0xe9 = 1`, `+0xea = 1` — `.UpdateSprites` clears the
   placement record's flag byte for a sprite with `+0xea` set (unless `+0x188`; main l. 4936–4942), so a killed boss
   is gone for good from the level's record block (and from any later save snapshot).
2. Only if the boss flag (p4, `+0x170`) is set (Xichra: always): snd 453 "thunder.snd" at rate
   48000 (`subi r7,r4,0x4480` 100887c8), screen shake `_DAT_1009ffa0 = 30` (engine.md §5),
   lightning flash `_DAT_100a00fc = 3` (`.PaintFrameWrap` shows the alternate buffer
   `*_DAT_100a0008` on alternate frames while the counter runs, main l. 9391–9412 [MED: buffer
   content not traced]), and `_DAT_1009fed0 = 1`.
3. Consequences of `fed0 = 1`: arena lock and camera bounds released (§1.3); the gate sprites type
   2940 (Box class) with **p1 = −1** open (`.HandleBoxSprite` l. 13235–13285: condition `fed0 ==
   1` → y −= 2 px/frame until 100 px above its home `+0x158`, else y += 2 px/frame back down; snd
   `puVar9` while moving) — one such gate per boss level: L5 x 416, L18 x 628, L25 x 1391, L55
   x 1174 (census); the gate is therefore **closed while the boss lives and open before Setup and
   after the kill**; music: `.GameLoop` (main l. 5231–5240) with **hdr+0x2724 ≠ 0** ∧ `fed0 ≠ 0` ∧
   current track `_DAT_100a5be0 ≠ 0x1e` ∧ prefs music on ∧ `cRam100a5be2 ≠ 0` → if the music volume
   `_DAT_1009fd6c` ≤ 0 start track 30 and fade in over 60, else fade out over 60 — i.e. the level
   track (23) fades out, then **track 30** fades in. On level 67 (hdr 0x2724 = 0, census §1.1) this
   never fires. ⚑ corrected (review 1b, 2026-10-03) #4 (the 0x2724 gate was missing; main l. 5231).
4. Nothing else: no pickup spawned, no level-complete flag (`_DAT_100a0088`), no map unlock. The
   level still ends through a level-exit sprite 3249 beyond the opened gate (census: L5 x −93 exit
   1, L18 x −76 exit 1; L25/L55 only exit −1 records). Score: only `.KillDemon` adds `G+0 += 1000`
   (`addi r3,r3,0x3e8` 1008b338), per call (part 2 §5.5). Xichra ends the game (part 2 §6.6).
5. Revisit [MED, chain of readings]: with the record cleared and the level's snapshot restored
   (`G+0x176` set, engine.md §9), no boss spawns, `fed0` stays 1, so the gate stands open, the arena
   never locks and `.GameLoop` forces hdr+0x284a = 30 at level start (main l. 5183–5185) — that
   force is gated `hdr+0x2724 ≠ 0 ∧ fed0` (main l. 5183), so it never fires on level 67.
   ⚑ corrected (review 1b, 2026-10-03) #4.

### 1.5 What can hurt each boss  [HIGH unless noted]
Player shots are sprites whose handler `+0x4c` is `.HandlePlayerShotSprite` (TOC slot
0x100a04e8): spells (`+4` = spell id after `.SetupPlayerShotSprite`), held melee weapons during the
strike frames (`.HandleItemUse` gives the held item that handler, main l. 43598 [MED: frame
condition not decoded]), Fire seeds / Smite bolts (id 0x5a). Every boss Hit routine tests only
shots with `shot+0xa6 == 0` (`.SetupPlayerShotSprite` writes 0; no non-zero writer found in the
shot code [MED]). "Falling solid" = a sprite whose handler is `.HandleStatueSprite` (slot
0x100a01f8: an enemy turned to stone) or `.HandleBoxSprite` (0x100a0484) that `.PlatformBounce`
reports as hitting the boss from above (return 2, physics.md §8.1) while `solid.vy > 0` or the boss
is grounded (`+0xce`); the solid is destroyed (`.KillBox`).

| boss | player shots / melee | falling Statue or Box | other |
|---|---|---|---|
| Warrior | **immune**: shot killed, snd 303 "metal hit" | **200** (HurtSprite invul 2, flash 8, vx += solid.vx/2, vy −1000) | lava (kind 2) −100 / 19 invul frames; healing water +4/frame below 500 |
| Wizard | **immune**: shot burns away (`shot+0x1a2 = 1`, `+0x8c = 1`, vx ×0.4) | **100**, only if `solid+0x160 ≥ 0` (not his own conjured box while it hovers) | — |
| Chief | **full damage** `shot+0xa4` (invul 2 then `+0x116 = 15`, flash 8, blood spray) | 200 | — |
| Demon | only during state 9 frames 5..47: `shot+0xa4`, **except V Blade (id 6)**: shot killed, no damage; otherwise shot killed + snd 303 | not tested (Hit ignores solids) | ungated key 0x77 (End) sets HP −1 (part 2 §5.2) |
| Xichra | phase-dependent: id 0x5a lowers the phase counter; other shots deflected; any shot hurts during the 30 vulnerable frames after a crash | 100 (`solid+0x160 ≥ 0`) | — |

- **Statue spell**: no boss calls `.TurnIntoStatue` — raw scan of `bl 0x10043138`: 12 sites, none
  in 0x100878ac..0x10090478 (the boss code) [HIGH; confirms spells-items.md §2.1]. A Statue shot
  is an ordinary shot to the bosses (deflected / burnt / damage as above).
- Ring of Smiting (`.SmiteEnemies`, main l. 44078) includes all five boss handlers in its target
  list (spawns an id-0x5a bolt at each); the Warrior, Wizard and Demon (outside its window) reject
  it like any shot; on Xichra it is an id-0x5a hit.
- HP-damage callback: `.HurtSprite @ 10037034(s, dmg, dvx, dvy, invul, flash)` subtracts only when
  `dmg ≥ 1`, `HP ≥ 1` and `+0x116 == 0`, then sets `+0x116 = invul`, `+0xaa = flash` (main
  l. 32479–32500) [HIGH].

### 1.6 Damage dealt to the player  [HIGH]
Contact: the boss handlers Warrior, Wizard, Chief, Demon are in the list that reaches the generic
enemy branch of `.HitPlayerSprite` (handler l. 4224–4230 list, l. 4511–4624 branch): `.ShieldBlock`
first; damage 0x70 = 112 for all four (Warrior/Wizard/Chief explicit, Demon the default), invul
60 (`0x3c`), coin loss 3 with probability 19 % (`FastRand(100) > 80`), via `.HurtPlayer`
(physics.md §5.1). **Xichra's body never hurts**: its handler slot 0x100a048c is referenced only
by `.SmiteEnemies` and `.SetupXichraSprite` (`tocrefs.py 100a048c`), so no `.HitPlayerSprite`
branch exists for it. Projectile damage: part 2 §7.

### 1.7 Shared fields and timers seen in all bosses
| field | use |
|---|---|
| +0xb0 | AI state (per class) [HIGH] |
| +0x46 | animation/frame counter within the state [HIGH] |
| +0xa6 | state timer / counter (bosses only; for player shots a separate meaning) [HIGH] |
| +0x17e | facing: **1 = right** for every boss (Warrior shot vx `0xb00` negated when 0, Demon head x = anchor + neck when 1, Xichra 1 when player x > cx − 4). The `eqv/subfc/addze` idiom written by Ghidra as `(a <= b) − (…)` evaluates to `1 iff player x > own centre x` (raw 10087f3c..10087f50) — the opposite of the player's own `+0x17e` sense (physics §0 "facing left") [HIGH] |
| +0xf0 | wounded-glow pulse timer: counts down; at 6..4 `+0xb8 = 0x10009`, 3..1 `0x10008` (only below an HP threshold); at ≤0 reload 30 (or 15/12 at low HP), `+0xb8 = 0`; a falling-solid hit sets it to 0 [HIGH] |
| +0xb8 | draw-effect word `mode<<16 | param` consumed by `.WrapDrawSprites` (main l. 10246–10296; hurt flash overrides it with `0x30000+n`, or `0x40000+2n` when `+0x1b4` is set — Warrior/Wizard/Demon set `+0x1b4 = 1`); modes 1 and 0xb used by bosses [MED; mode semantics NOT RESOLVED] |
| +0x1a2 | burn-away counter (§1.4) [HIGH] |
| +0x50 | Kill callback, run when the burn completes [HIGH] |
| +0x170 | the boss flag (copy of p4) [HIGH] |
| +0xea | "clear my placement record" request (§1.4) [HIGH] |

### 1.8 Sounds used by the bosses (`.InitSounds` handle → `snd ` id → resource name)  [HIGH]
| handle (TOC slot) | id | name | used for |
|---|---|---|---|
| `_DAT_100a0268` | 704 | throw | Warrior swing (frame 7), Chief throw |
| `_DAT_100a026c` | 703 | crawler death | every boss reaching HP ≤ 0 |
| `_DAT_100a0270` | 702 | Crawler uh oh | Demon/Chief hit with HP ≤ 200 after the hit |
| `_DAT_100a0274` | 701 | Crawler Ouch | boss hurt; Warrior lava |
| `_DAT_100a0320[0..2]` | 477..479 | monster1/2/3Sound | hit grunts (`[FastRand(2)]` → only 477/478) |
| `_DAT_100a041c` | 303 | metal hit | shot deflected |
| `_DAT_100a0424` | 300 | Fireball | Demon/Wizard/Xichra fireballs |
| `_DAT_100a03f8` | 414 | jump | Chief jump |
| `_DAT_1009fdec` | 435 | explosion | Chief/Xichra landing, Xichra death explosions |
| `_DAT_1009fd68` | 453 | thunder.snd | boss killed (48000) |
| `_DAT_100a0350/034c/0348` | 465/466/467 | goblingrowl1/2, goblintaunt | Chief cries |
| `_DAT_100a0344` | 468 | goblinhurt | Xichra phase changes (rate 78000–102000) |

Calls are `.STPlay3DSound(snd, 1, vol, pos)` / `.STPlay3DSoundPitched(snd, 1, vol, pos, rate)`;
`rate` values are near 65536 (e.g. 42000+`FastRand(10000)`) [MED: 16.16 rate meaning not traced].

---------------------------------------------------------------------------------------------

## 2. Manditraki Warrior (types 1820..1829; level 5)

Callbacks: Setup `.SetupWarriorSprite @ 100878ac` (handler l. 20023–20113), Handle
`.HandleWarriorSprite @ 10087c04` (l. 20114–20420), Hit `@ 1008854c` (l. 20421–20463), Kill
`@ 1008874c` (l. 20464–20496), HitTile `@ 10088834` (l. 20497–20531; WallBounce/WallBounceBG/
water like the walkers). Helpers (main dump): `.InitWarriorSprite @ 100877d0` (l. 52954),
`.WarriorLayEgg @ 10087afc` (l. 52968), `.RandomWarriorAttack @ 10087b6c` (l. 52983).

### 2.1 Setup  [HIGH]
Layer `+0x80 = 0xc`; gravity `+0x110 = 0x122` (290); HP 1200/2000 by p4 (§1.1); boss mode also
sets `_DAT_1009fed0 = 0`, `+0x88 = 0`. `+0x1b4 = 1`. Initial hot rect `SetRect(0x1a,0x17,0x4a,0x3a)`,
replaced every frame by the Handle (§2.2). State `+0xb0 = 6`, `+0xb2 = 0`, `+0x46 = 2`, `+0x14c =
0`, `+0xa6 = FastRand(10)`, `+0x150 = −1`. Patrol bounds `+0x15c = x − 350`, `+0x160 = x + 350`
(`0x15e`), home `+0x168 = x` (after first holding the HP), `+0x164 = 0`. Facing `+0x17e = 1 (right)
iff FastRand(100) > 50` (raw 10087a48..10087a68: `li r4,0x32`, signed `>` idiom). Face = walk set
frame 0; `+0xf0 = 0x1e`. Face sets (`.InitWarriorSprite`): PICT 1820 → `PTR_DAT_100a0d50` walk,
8 frames 180×160; PICT 1821 → `_DAT_100a0d4c` attack, 8 frames; PICT 1822 → `_DAT_100a0d48` death,
6 frames.

### 2.2 Per-frame (boss mode extras first)  [HIGH]
Skips everything if `+0xe9` or `+0x1b2`. `.StandardSpriteHandles`; hot rect
`SetRect(0x2a,0x3c,0x89,0x88)` then extended 10 px toward the facing side (left −10 if facing
left, right +10 if facing right).
Boss mode only (`+0x170 ≠ 0`):
- **Falling crates**: three slots `+0x1d4/+0x1d8/+0x1dc` hold Box sprites type **0x433** (1075,
  Box setup) at (home−186, y−400), (home+70, y−500), (home+326, y−400) (`addi … 0x46 / 0x146`
  10087d98/10087ddc, 0xba subtract), layer 9. A slot empties when its sprite has `+0xe9`; while any
  slot is empty `+0x16c` counts down and at < 1 the empty slots are refilled; while all three are
  present `+0x16c = 15`. First frame: all three spawn at once (fields start 0). A crate resting on
  the floor keeps its slot, so only destroyed crates respawn.
- Wounded glow (§1.7) with HP ≤ 1000 (`cmpwi 0x3e8`, 10087e28), period 30 frames, 15 when HP < 500.

State machine (`+0xb0`):

| state | behaviour |
|---|---|
| 6 decide | face = walk frame 0; `+0xa6` (if > 0) counts down; **if `fed4` (arena locked) is clear the handler returns here** (no gravity, no cleanup). At `+0xa6 ≤ 0`: `r = FastRand(100)`; if `|playerCY − cy| < 80` (`cmpwi 0x50` 10087f28): threshold T = 65 and face the player, else T = 19; T = −1 while the game-over flag `_DAT_1009ffa8` is set (only set after death, so never in play). `r > T` → **walk/run** (state 7, `+0x46 = 1`, cycles `+0xa6 = FastRand(3)+2`; run if `FastRand(100) > 100 − T` else walk, and on walk with `FastRand(100) > 80` `.WarriorLayEgg` → `+0x154 = 2` (never read), `+0xa6 = 5`, `+0x14c = FastRand(2)+1` (≠0 → run); then if x > `+0x160` face left, if x < `+0x15c` face right). Else → `.RandomWarriorAttack` (state 2, `+0x46 = 0`, `+0x154 = 0`, `+0xa6 = 16`, swings `+0x14c = FastRand(2)+1`). Then vx ×0.5 |
| 7 walk (`+0x14c == 0`) | frames walk[`+0x46>>1`], cycle 15 frames, vx ±0x600 (6 px/frame) by facing; each completed cycle `+0xa6 −= 1`, forced to 0 if x left `[+0x15c, +0x160]`; at 0 → state 6 with `+0xa6 = FastRand(9)+4` |
| 7 run (`+0x14c ≠ 0`) | frames walk[`+0x46`], cycle 7 frames, vx ±0xc00 (12 px/frame); same cycle/bounds rule |
| 2 attack | vx ×0.4; `+0x46 < 2`: walk frame 0, face the player; else attack frame `+0x46/2 − 1` (8 frames; read as `set + (n>>1)·4`, i.e. no `+4`). `+0x46 == 7`: snd 704, rate 50000+`FastRand(6000)`. `+0x46 == 9`: enemy shot **0x71f** at (cx ± 0x30 − 0x18, cy − 0x25), layer 0, vx ±0xb00 (11 px/frame) by facing (part 2 §7). `+0x46 > 16`: `+0x46 = 0`, swings −1, at < 1 → state 6, `+0xa6 = FastRand(9)+4` |
| 4 dying | vx ×0.9; death frame `+0x46>>2` (cap `+0x46` 0x17); `+0xa6 == 45` → `+0x1a2 = 1` (burn) |

Constants: 0.5 / 0.4 / 0.9 = doubles at 0x100a1c40 / 0x100a1c38 / 0x100a1c30 (`lfd -0x5c00`
10088044, `-0x5c08` 100881f0, `-0x5c10` 1008837c). States 0, 1, 3, 5 and > 7 do nothing.
After the switch: HP ≤ 0 → state 4 + snd 703 (§1.4); `.ApplyGravityAndSeparateFromTiles`; liquid
(`+0x11c ≠ 0` and (`+0x11c == 1` with kind 0, or kind > 0)): kind 3 heals +4/frame while HP <
500; kind 2 only (lava) with `+0x116 == 0`: HP −100, `+0x116 = 19`, `+0xaa = 17`, snd 701 vol 0x55;
`.StandardSpriteCleanup`.

### 2.3 Damage, death  [HIGH]
Hit: player shots killed + snd 303 (immune); falling Statue/Box → 200, `+0xf0 = 0`, `.KillBox`,
snd 701 and 477/478 at 42000+`FastRand(10000)`. So in level 5 the fight is "make the dropped
crates land on him": 2000/200 = **10 crate hits** [HIGH arithmetic; "intended" LOW]. Contact
damage 0x70 (§1.6). Kill: §1.4 (thunder, shake, flash, `fed0 = 1`), no score.

---------------------------------------------------------------------------------------------

## 3. Manditraki Wizard (types 1830..1839; level 25)

Callbacks: Setup `@ 1008c6a8` (l. 21965–22060), Handle `@ 1008c8e8` (l. 22061–22460), Hit
`@ 1008d470` (l. 22461–22509), Kill `@ 1008d69c` (l. 22510–22542), HitTile `@ 1008d784`
(l. 22543–22577). `.InitWizardSprite @ 1008c5c8` (main l. 53607): PICT 1830 single standing face
(`_DAT_100a0db4`), PICT 1831 → `PTR_DAT_100a0dbc` move set 8 frames 192×140, PICT 1832 →
`_DAT_100a0db8` cast set 8 frames.

### 3.1 Setup  [HIGH]
Layer `+0x80 = 1`; gravity 0x122; HP **1000 with the boss flag**, 1200 without; boss mode sets
`fed0 = 0`, `+0x88 = 0`; `+0x1b4 = 1`; hot rect `SetRect(0x42,0x1e,0x7c,0x7e)` (never changed);
state 6; `+0x46 = 2`; `+0xa6 = FastRand(10)`; `+0xf0 = 0x1e`; p2 default write (§1.1); `+0x15c/
+0x160 = x ∓ 256`, `+0x168 = x` (**never read** by the Handle); `+0x17e = 0`. Work block
`+0x9c = AllocateGameMem(0xe)` (zeroed, 7 i16): `w[0]` actions left in the current attack,
`w[2]` state to enter after the attack, `w[3]` attack kind (0 fireballs, 1 crate), `w[4]` attack
counter (only incremented), `w[5]` crate-carry timer, `w[6]` consecutive fireball attacks;
`w[1]` unused.

### 3.2 State machine  [HIGH]
HP bands used below: **high** HP > 600, **mid** 301..600, **low** ≤ 300 (`cmpwi 0x258 / 0x12c`).

| state | behaviour |
|---|---|
| 6 idle | standing face, vx 0, face the player; `+0xa6++`; when `+0xa6 ≥ W + FastRand(10)` (W = 22 high, 16 mid, 10 low) → state 9 |
| 9 advance | move-set frame `(n mod 16)/2`, vx ±0x500 toward the facing (5 px/frame); from `+0x46 > 31` stand still (standing face, vx 0); at `+0x46 > 35`: face the player, `w[2] = 12`, state 2 and choose the attack: if `FastRand(100) < 40 + B` (B = 0 high, 10 mid, 20 low) and `w[6] < 3` → **fireballs**: `w[6]++`, `w[3] = 0`, `w[0] = 1` if `FastRand(100) > R` else `FastRand(3)+2`, R = 22 when HP > 600 else 35; else → **crate**: `w[6] = 0`, `w[3] = 1`, `w[0]` = 1 if `FastRand(100) > 90`, 2 if > 20, else `FastRand(2)+3`; `w[4]++` |
| 2 attack, fireballs | cast frame `min(n/2,7)`. At `+0x46 == 7` a 20-frame charge holds the frame (`+0xa6` 20→0, `+0xb8 = 0x1000c` on odd frames by the frame-parity flag `_DAT_1009fd30`, keeps facing the player). `+0x46 == 8`: three enemy shots **0x46a** at (cx−24, cy−24), layer +1, velocities (0x1194, 0), (0x1068, −0x5dc), (0xce4, −0xbb8) mirrored when facing left; snd 300 rate 36000+`FastRand(12000)`; `w[0]−−`. After `+0x46 > 15`: stand, face the player; `w[0] == 0` → done; else if `w[5] < 1` restart at `+0x46 = 0` |
| 2 attack, crate | cast frame `min(n/2,7)`; `+0x46 == 10`: Box **0x434** at (cx−16, cy−16), layer 9, `box+0x160 = −52`, `w[5] = 52`, `w[0]−−`; after 15: same ending, but the next crate waits until `w[5] < 1` |
| done | `+0xa6 = +0x46 = 0`, state = `w[2]` = 12 |
| 12 | face the player → state 10 |
| 10 retreat-animation | move-set frame `7 − (n mod 16)/2` (reverse), vx ±0x500 toward the facing; stand from `+0x46 > 31`; at > 35 → state 6 |
| 11 | same as 10 with the opposite vx sign; **no writer of state 11 exists** (dead) |
| 4 dying | vx ×0.9 (0x100a1cc0); cast-set frame `+0x46>>2` (cap 16); `+0xa6 == 20` → burn |

Crate carry (every frame while `w[5] > 0`, l. 22370–22394): `w[5]−−`; if the crate is gone
→ `w[5] = 0`; else while `w[5] > 10`: `t = max(w[5] − 22, 0)/30` (0x100a1cb8 = 30.0), crate x =
`(playerX − 16)(1 − t) + x·t`, y = `(playerCY − 136)(1 − t) + y·t` — it glides from the Wizard to
136 px above the player, tracks the player exactly for `w[5]` 22..11, then hangs still. The Box
handler (`.HandleBoxSprite` l. 12443–12470) keeps a 0x433/0x434 with `+0x160 < 0` weightless and
collision-less, `+0x160++`, flickering `+0xb8` 0xb0000/0xb0002; at 0 it gets gravity 0x96, its
collision callbacks, and vx = last frame's drift ·256 — so the crate drops 52 frames after it
appeared [HIGH].
After the switch: HP ≤ 0 → state 4 + snd 703; else wounded glow (§1.7) for 0 < HP ≤ 600, period
30, 12 when HP ≤ 300. Gravity + cleanup.

Dead code [HIGH, raw]: the choice of R reads `cmpwi r0,0x258; ble → bgt` reusing the same CR,
so the `li r25,0x2d` (45 at low HP, 1008cb5c) is unreachable — R is 22 or 35 only.

### 3.3 Damage, death  [HIGH]
Shots and melee burn away harmlessly (§1.5). Only falling solids with `+0x160 ≥ 0` hurt: 100,
`.KillBox`, snd 701 + 477/478. The Wizard's own crates are harmless to him only while hovering;
once released (`+0x160 = 0`) a crate landing on him counts — 1000/100 = **10 hits** with the boss
flag. Crate on the player: §7 of part 2 (0x434: 0x70). Contact 0x70. Kill §1.4.

---------------------------------------------------------------------------------------------

## 4. Goblin Chief (types 1910..1919; level 18)

Callbacks: Setup `@ 1008b538` (l. 21470–21556), Handle `@ 1008b878` (l. 21557–21838), Hit
`@ 1008c0e0` (l. 21839–21896), Kill `@ 1008c350` (l. 21897–21929), HitTile `@ 1008c434`
(l. 21930–21964, same as Warrior's). `.InitChiefSprite @ 1008b3f8` (main l. 53540): PICT 1910
"!Goblin Chief" single standing face (`_DAT_100a0d94`), PICTs 1911..1914 → sets
`PTR_DAT_100a0da4` (throw A), `_DAT_100a0da0` (throw B), `_DAT_100a0d9c` (jump),
`_DAT_100a0d98` (death), 4 frames 256×254 each. `.GoblinChiefRandomCry @ 1008b724` (main l. 53563).

### 4.1 Setup  [HIGH]
Layer 0xc; gravity **0x276** (630); HP 1200/2000 by p4; boss mode `fed0 = 0`, `+0x88 = 0`;
`+0x8d = 1` (burns 2 rows/frame); no `+0x1b4`; hot rect `SetRect(0x5e,0x55,0xa5,0xd4)` replaced
each frame by `SetRect(0x58,0x73,0xac,0xd2)`; state 6; lane `+0x15c = 2`; `+0x164 = 0`; facing
right; `+0xf0 = 0x1e` (no glow code reads it); `+0xa6 = −40` (`li r0,-0x28` 1008b690).

### 4.2 State machine  [HIGH]
| state | behaviour |
|---|---|
| 6 wait | vx 0, standing face; `+0xa6++` **only while the arena is locked** (`fed4`); when `+0xa6 > 15` and `+0xcd` (grounded) → state 1. First jump = 56 frames after the lock, later ones 16 frames after the last throw |
| 1 jump | jump-set frame `min(n/2, 2)`; at `+0x46 == 3`: snd 414 (args `0x14, 0xab`) rate 35000+`FastRand(6000)`, vy **−0x2904** (−10500), `+0xce = 0`, and a lane change by `r = FastRand(100)` (<33 / <66 / else): from lane 2: vx −0x700→1 / 0→2 / +0x700→3; from 1: 0→1 / +0x700→2 / +0xe00→3; from 3: −0xe00→1 / −0x700→2 / 0→3. When `+0x46 > 3` and vy > 0 → state 3 |
| 3 land | airborne: jump frame 3. Grounded (`+0xcd`), first frame: snd 435 rate 40000+`FastRand(12000)`, **shake 22** (`_DAT_1009ffa0 = 0x16`), **player stunned 24 frames** (`_DAT_100a0570 = 0x18`) if the player `+0xce` or `+0xcd` is set, vx 0, face the player. Frames: n 0–1 standing, 2–4 throw-A 0, 5–6 standing; at n = 6: throw counter `+0x158 = FastRand(2)+2`, state 2 |
| 2 throw | 19-frame cycle `+0x46` 0..18: at n = 0 face the player and `+0x158−−` (→ state 6 with `+0xa6 = 0` when < 1 — the decrement precedes the first throw, so a landing yields **1 or 2 throws**); frames n/2 0–3 throw-A, 4–7 throw-B, ≥8 standing; at **n = 7**: snd 704 vol 0x5f rate 45000+`FastRand(8000)`, enemy shot **0x77b** at (x + (facing right ? 0xa1 : −0x11), y + 0x33), layer −1, facing copied, `+0x46 = 15`, vx 4000+`FastRand(500)`, vy −1200−`FastRand(150)`; if `|playerX − cx| < 240`: vx ×0.8, vy = **+2000** (thrown down at a near player); the following `< 155` branch (vx ×0.5, vy 0xc80) is unreachable; vx negated when facing left |
| 4 dying | vx ×0.9; death frame `min(n>>2, 3)`, n cap 16; `+0xa6 == 20` → burn |

`+0xb2` (set 1 by a hit) counts 1..5 then 0; nothing else reads it [HIGH; purpose LOW].
On HP ≤ 0: 60 % (`FastRand(100) < 60`) a random cry, then snd 703.
Constants: 0.9 / 0.8 / 0.5 at 0x100a1c88 / 0x100a1c98 / 0x100a1c90 (`lfd -0x5bb8/-0x5ba8/-0x5bb0`,
1008bf44 / 1008bdf8 / 1008be54); vy and lane speeds `li` at 1008ba00..1008baf8; 0x77b spawn
1008bd3c; `vx 0xfa0` 1008bd9c; `0xf0` 1008bdd8.

Random cry: only if none of 465/466/467 is playing: `r < 41` → 467 vol 0xc9, `< 71` → 466,
else 465 (vol 0xab), rate 42000+`FastRand(10000)`.

### 4.3 Damage, death  [HIGH]
The only boss that takes ordinary spells and melee: `.HurtSprite(dmg = shot+0xa4, 0, 0, 2, 8)`
then `+0x116 = 15` (15 invulnerable frames), `+0xb2 = 1`, `.BloodSpray(…,0x28,400,0x96,2)`,
snd 702 if HP ≤ 200 else 701, 60 % a cry; the shot is killed silently. With Fireball (100 per
shot at power 1) 2000 HP = 20 hits [HIGH arithmetic]. Falling Statue/Box: 200 + cry. Contact
0x70; the thrown 0x77b and the landing stun are the other threats. Kill §1.4.
