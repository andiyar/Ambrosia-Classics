# Deimos Rising 1.0.6 — gameplay leftovers (wave 4, reader w4s5, 2026-10-04)

Scope: the 56 functions the wave-4 brief lists for w4s5. The brief header says 69, but the list
itself holds 56, and all 56 are read here. They are G_Game `10005d10 10006200 10007150 10007280
10009400`, G_Film / PixelBuffer `10009970 10009980 10009a20 10009a60`, GameObject/Entity `10012610
10012750 100128c0 100128f0 10012930 10012ba0 10012c00 10012c10 100141a0 10014290 10017e10`, Player /
Debris `10026d60 10027560 10027610 10027620 100299f0 10029a00 10029be0 10029bf0 10029f60 10029fd0
1002a920`, LevelSelection / ScoreBar `1002fc60 1002fc90 1002ff30 100313b0`, PlayerDefinitions `100391f0
10039230 10039940 100399a0 10039a80 10039c00`, and UnitDefinitions `1003dd60 1003ddc0 1003de00 1003de30
1003de70 1003dfb0 1003e040 1003e120 1003e1a0 1003f410 1003f830 1003fa10 1003fa80 100417d0 100418a0`. The
brief labels the last group "weapon handler/defs", but every one of them is G_UnitDefinitions.cc
(inventory). The file also closes, from listings, the open items the brief assigns: O4, O5, O6 and the
O7 set. That work reads `FUN_1000fee0`, `FUN_1000fec0`, `FUN_10005d40`, `FUN_10015280`, `FUN_100146f0`,
`FUN_10033850` (parts), `FUN_1003c7a0` and `FUN_1003c940`.
OUT of scope: the static initialisers (wave 3), w4s1–w4s4 ranges, and the bodies of callers that are
only cited.
Evidence: listing `$W/disasm-w4s5.txt` (65 functions) and `$W/disasm-w4s5b.txt` (raw ranges
`1002aa30`, `10020740`, `100207e0`, `10020a20`, `10020ac0`). Other inputs are earlier listings in
`$W/disasm-*.txt` (read with `$W/w4s5-lst.py`), the raw `bl` scan `$W/w4s5-blscan.py`, the displacement
scan `$W/w4s5-dispscan.py`, the r2-slot scan `$W/w4s5-r2scan.py`, the data census `$W/w4s5-census.py`,
and constants from `$W/w4s5-rd.py` (images `mem/10000000.bin`, `mem/100de330.bin`, TOC r2 = `0x100e6330`).

## 1. G_Game counters and the film object

### 1.1 Game-struct `G` writers [HIGH — listings]
`G` = `*(r2−0x7360)` = `PTR_DAT_100defd0` (scoring-bonuses.md §1.2 has the field table).
| function | listing | effect | callers (raw `bl`) |
|---|---|---|---|
| `FUN_10005d10 @ 10005d10` | `lwz r3,-0x7360(r2); li r0,0; stb r0,0xc(r3)` | accuracy reward armed `G+0x0c` ← 0 | `1001659c` only (`FUN_10016300`) |
| `FUN_10006200 @ 10006200` | `lwz r3,0x40(r4); addi r0,r3,1; stw r0,0x40(r4)` | ground-accuracy destroyed `G+0x40` += 1 | `10016514` only (`FUN_10016300`, gate `10016508 lbz r0,0x134(r30)`) |
| `FUN_10007150 @ 10007150` | `stw r0,0x3c(r3); stw r0,0x40(r3)` (r0 = 0) | created/destroyed counts ← 0 | `10005564` (session start), `10006518` (level start) |
| `FUN_10007280 @ 10007280` | `stb r3,0x48; stw r3,0x4c; li r0,0x20; stw r0,0x50; stw r3,0x54/0x58/0x5c; stb r3,0x60; stw r3,0x160; stb r3,0x164; stw r3,0x168` | accuracy-tally reset: state 0, timers 0, **alpha 32**, bonus/step 0, text "" (first byte), percent 0, mission flag 0, payments 0 | `10005568` (session), `1000651c` (level start) |

`FUN_10005d10` in context (`FUN_10016300` `10016530..100165a4`) [HIGH]. `r = R(0,100)`. If `r <
trunc(F209)` and the reward is armed (`bl 0x10005d00`), then `r < trunc(F218
Game_RandomBonusPercent_GroundAccuracyReward)` → bonus object `PermObjectID(30)` and the armed flag
is cleared. So the 100 %-accuracy reward drops **at most once per level**. Otherwise the code falls
through to `PermObjectID(25)`.
`FUN_10006200` has no killer test. **Any** `FUN_10016300` destroy of a unit with
`includeInGroundAccuracyCount` (+0x134) counts as a hit. §7.5 shows that only player damage reaches
counted units in 1.0.6.

### 1.2 Film object (`gameFilmPtr`, 0x9d7c bytes) [HIGH]
Layout, from ctor `FUN_10009390` (`100093cc bl 0x10009970`, `100093d8 stw r0,0xc(r31)`, `100093e0 stw
r0,0x10(r31)`) and dtor `FUN_10009400`:
| off | meaning | evidence |
|---|---|---|
| +0x00 | u8 valid (1 after ctor) | ctor; dtor clears it (`10009468 stb r0,0x0(r26)`) |
| +0x04 / +0x08 | replay cursors P1 / P2 | `FUN_10009970` `10009974 stw r0,0x4(r3); stw r0,0x8(r3)`; read by `FUN_100097a0`/`FUN_10009750` (timing-frame.md §7) |
| +0x0c / +0x10 | two heap blocks, released by the dtor | dtor loop `10009438 addi r29,r30,0xc; lwzx r3,r26,r29; … bl 0x1000cc00; stwx r31,r26,r29` (2 iterations, stride 4) |
| +0x14 … | film image 0x9d68 bytes, version 0x2715 | ctor |
- `FUN_10009400(film, flag)`: if valid, each non-null +0xc/+0x10 goes to `FUN_1000cc00`. That is
  `GetPtrSize` and `DisposePtr`, adding the size to the freed-bytes counter `0x100e0108` and 1 to
  `0x100e0104`. Then +0 = 0, and `operator delete` (`FUN_1004d3b0`) runs when flag > 0. Its only
  caller is `10005b30` in `FUN_100051a0`, right after the `last` film save (`10005b18 bl
  0x100095b0`). It runs once per session.
- [MED] Inside G_Film (`0x10009390–0x10009980`, displacement scan) only the ctor writes +0xc/+0x10,
  so the free loop is presumably always a no-op. A writer outside that range was not searched.
- `FUN_10009970(film)` zeroes both cursors. Callers: the ctor (`100093cc`) and `FUN_10009680`
  (`100096dc`, load film header for playback). Every replay therefore starts at frame 0 for both
  players.
- Module span ⚑: the film ctor/dtor (`0x10009390`, `0x10009400`) lie **before** the G_Film span start
  `0x100095b0` used by `$W/w4-unread.py`. G_Film begins at or below `0x10009390` [MED — call shape and
  the `gameFilmPtr` assert string].

### 1.3 Pixel-buffer object lifetime (M_PixelBuffer) [HIGH]
The object is 12 words. +0 holds the `GWorldPtr`; the dispose path `FUN_10009d00` calls
`DisposeGWorld` when +0 ≠ 0 and clears the same 12 words. The other fields belong to w4s1
(display-window-present.md).
- `FUN_10009a20 @ 10009a20` clears it: `stw r0` to +0x0, +0x8, +0xc, +0x10, +0x14, +0x18, +0x20,
  +0x1c, +0x28, +0x24, +0x2c, +0x4. There are 12 stores, in that order, and no field is skipped.
- `FUN_10009980 @ 10009980` is the default ctor (`bl 0x10009a20`; returns `this`). Callers are the
  image ctors `FUN_10020d60` (`10020d74`) and `FUN_10020da0` (`10020dc4`). The sized ctor is
  `FUN_100099c0` → `FUN_10009a20` then `FUN_10009bd0`.
- `FUN_10009a60 @ 10009a60` is the dtor: if `this`, `bl 0x10009d00`, then `operator delete` when
  flag > 0. Callers: the fades (`1000b5c4`, `1000bb90`, `1000bba8`), the sprite manager (`1001937c`,
  `10019394`, `100193ac`), `1001d734`/`1001d754` and the image dtor `10020e24`.
- Module span ⚑: these three sit inside the `0x100095b0–0x10009ac0` "G_Film" bracket. By call shape
  they are M_PixelBuffer, so that module starts at or below `0x10009980`.

## 2. GameObject / Entity helpers

### 2.1 `FUN_10012750(o) @ 10012750` — visibility and tint ramps, per tick [HIGH — full listing]
Two independent ramps, the same code twice:
```
visibility: cur +0x68, target +0x6c, step +0x70     tint: cur +0x58, target +0x5c, step +0x60
10012750 lfs f2,0x68 ; lfs f0,0x6c ; fcmpo ; ble 100127a4       (cur ≤ target → rising or equal)
  falling: cur −= step (10012770 fsubs) ; if cur < 0.0 → cur = 0.0 (1001277c fcmpo f1,f0 ; bge)
           ; if cur < target → cur = target (10012794 fcmpo ; bge)
100127a4 bge 100127c8 (equal → done)
  rising:  cur += step (100127ac fadds) ; if cur > target → cur = target (100127bc fcmpo ; ble)
tint: 100127c8..10012838, same shape (bgelr / blelr)
```
Both constants are 0.0. The floor is `r2−0x7248` → `0x100df0e8` → double at `0x100d67c4` = 0.0, and
the reset value is `r2−0x7240` → `0x100df0f0` → float at `0x100d67a8` = 0.0 (`w4s5-rd.py
toc:-0x7248 toc:-0x7240`; code-image literal pool, no initialiser writes it). Step semantics:
linear, clamped at the target, never overshoots. The ramp never moves away from the target, so a
step of 0 freezes the value.
Callers (raw `bl`), all once per logic tick:
- player update `10029080` (`FUN_10028170`);
- entity update `10033e98` (`FUN_10033850`);
- the crosshair object `1003ba2c` (`FUN_1003b3c0`, `addi r3,r22,0x8c` = player+0x2cc), only while its
  sprite `+0xa8` ≠ `none`.
So the crosshair fade-in of loose-ends-combat.md §6.2 (0 → 100 at F149 per tick) is this ramp.
Initial values for entities come from `FUN_100146f0` on the initial state (§7.3): visibility ←
`initialVisibilityPercent` (unit+0x1b4); target ← `stateRequiredVisibilityPercent` (+0x3c4); step ←
`stateVisibilityDeltaPercent` (+0x3c8); tint current **and** target ← `stateTintPercent` (+0x3cc);
tint step ← `stateTintDeltaPercent` (+0x3d0). Listing `10014a38..10014aec`.

### 2.2 Hit glow: `FUN_10012c00` off, `FUN_10012c10` tick [HIGH — listings]
Start is `FUN_10012bc0` (already HIGH). It sets +0x74 = 1, level +0x78 = 32, phase +0x75 = 1
(falling), step +0x7c = speed and colour +0x80 (`10012be0..10012bf8`).
Tick `FUN_10012c10` (`10012c10..10012c9c`):
- +0x74 = 0 → return.
- Phase 1: `level −= step`; `10012c3c cmplwi r0,0x4; bgelr`; otherwise level = 4 and phase flips
  (`cntlzw; rlwinm …,0x1b,5,31` = logical NOT).
- Phase 0: `level += step`; `10012c74 cmplwi r0,0x20; blelr`; otherwise level = 32, phase flips and
  **+0x74 = 0** (glow ends).
Both compares are **unsigned**. Every shipped speed is 6: units hard-wire `li r5,0x6` at `100150ac`
(damage) and `1003767c` (pickup), and the player's `plde hitGlowSpeed_INT <6>` holds in both files.
The sequence after a hit is **26, 20, 14, 8, 2→4, 10, 16, 22, 28, 34→32 (off)**. That is 10 ticks of
glow, peak alpha 28/32 at the clamp tick. Latent quirk: a speed with `32 mod s ≥ 4` (7, 9, 11, …)
steps from ≥ 4 straight to a negative level. Unsigned, that is ≥ 4, so it never clamps and the glow
never ends. Unreachable with 1.0.6 data.
- `FUN_10012c00 @ 10012c00` = `stb 0,0x74(r3)`. Callers: `10016330` (`FUN_10016300`, destroy:
  damage-health-death.md §4 step 1) and `10026a30` (`FUN_100269a0`, player level start).
- Tick callers: `100290bc` (player update) and `10033f08` (entity update), once per tick.

### 2.3 Accessors [HIGH — listings]
| function | listing | role | callers |
|---|---|---|---|
| `FUN_100128c0 @ 100128c0` | `blr` | **identity**: returns its argument (r3 untouched). Used as "position pointer of entity": callers read `lfs 0x0(r3)` / `lfs 0x4(r3)` | `10034708…10034a48` (`FUN_100345f0` debug labels), `10034fc4` (`FUN_10034ee0`), `10035148` (`FUN_10035070`) |
| `FUN_100128f0 @ 100128f0` | `lfs f0,0x0(r3); stfs f0,0(r4); lfs f0,0x4(r3); stfs f0,0(r5)` | get x, y into two float outs | `100168bc` (`FUN_10016880` media gate), `10037fdc` (`FUN_10037ed0`) |
| `FUN_10012930 @ 10012930` | `stfs f1,0x0(r3); stfs f2,0x4(r3)` | set x = f1, y = f2 | player setup `10026b78/10026bc4`, respawn `10029d50/10029da0`, owner lock/link/orbit `10037214`, `10037310`, `100374b8`, `100374e0`, `10037504` |
| `FUN_10012ba0 @ 10012ba0` | `lwz r0,0x24(r3); stw r0,0(r4); lwz r0,0x28(r3); stw r0,0(r5)` | scaled frame w′, h′ (sprite-geometry-draw.md §2.1) | `10029838` (`FUN_10028170`, on the crosshair object player+0x2cc) |
(`FUN_100128d0` / `FUN_10012910` are the point-struct twins of `FUN_100128f0` / `FUN_10012930`.)

### 2.4 Constructors, destructors, list frees [HIGH — listings]
- `FUN_100141a0 @ 100141a0` is the **entity ctor**. It is unoptimised code (`stw r3,0x58(r1)`
  reload before every store). The sequence is `bl 0x100125d0` (GameObject ctor), then `stw 0` to
  +0x94 (unit def), +0x98 (unit ID / PERM, spawn-and-waves.md §1) and the 20 per-state spawn-record
  list pointers **+0x19c … +0x1e8** (stride 4; `100141d4 … 1001426c`), then `bl 0x100142f0` (field
  reset). The last word, +0x1e8, ends the 0x1ec-byte entity. The only caller is `100383f4`
  (`FUN_10038390`, pool of 1000 entities).
- `FUN_10014290 @ 10014290` is the **entity dtor**: `bl 0x10012610` with r4 = 0 (base dtor, no
  delete), then `operator delete` if flag > 0. The only caller is `10038588` (`FUN_10038540`, pool
  dispose).
- `FUN_10012610 @ 10012610` is the **GameObject dtor**. It owns nothing, so it is just `operator
  delete` when flag > 0. Callers: `100142b4` (entity dtor), `100263d8` (player dtor `FUN_100263a0`),
  `100331e0`, `100358a8`, `10035b94`, `100368e8` (EntityGroup), `1003ad9c` (weapon-handler dtor) and
  `10046e68` (motion blur).
- `FUN_10017e10(this, list) @ 10017e10` frees one spawn-record list. Loop: `bl 0x10000d90` (pop head)
  → `operator delete` until it returns 0, then `FUN_100008b0(list, 1)` (list dtor + delete). Callers:
  `1001437c` (`FUN_100142f0`, before re-allocating) and `10014504` (`FUN_100144a0`).

## 3. Player accessors (G_Player) [HIGH — listings]
| function | listing | role | callers (raw) |
|---|---|---|---|
| `FUN_10026d60` | `addis r4,r4,0x1525; subi r0,r4,0x2311; stw r0,0x98(r3)` | lives set, stored = n + 0x1524DCEF | ctor `10026364`, session lives `10026cf0/10026d00/10026d24` |
| `FUN_10027560` | `lwz r4,-0x702c(r2); lfs f0,0x8(r4); fadds f0,f0,f1; stfs f0,0xa8(r3)` | shield set, stored = s + 1324366.0 (`0x100d6fc8`+8) | ctor `10026348`, damage `100271b4`, reset `10027428/10027464`, add `1002750c` |
| `FUN_10027610` / `FUN_10027620` | `lwz r3,0xac; subis 0xb; subi 0x2cce` / `addis 0xb; addi 0x2cce; stw 0xac` | money get/set, ± 0xB2CCE | get `100275d8`; set ctor `10026374`, `10027590`, `100275e8` |
| `FUN_100299f0` / `FUN_10029a00` | `lwz r3,0xb0; subis 0x553; subi 0x2a3e` / `addis 0x553; addi 0x2a3e; stw 0xb0` | score get/set, ± 0x05532A3E | get: session results `10005b84`, score bar `10031610/10031664/10031870/10031888`; set `100299d0` |
| `FUN_10029be0` / `FUN_10029bf0` | `lbz r3,0xbd(r3)` / `stb r4,0xbd(r3)` | **cheated flag** get/set | get `10005ba8` (session result `param_2` "cheated"). Set: 0 at `100268ec` (`FUN_10026410` setup); **1** at 16 console sites (`li r4,0x1` before each, `w4s5-prevli.py`): the six registered cheats LIFE `10008ab8`, ACCURACY `10008c58`, FUNDS `10008d80`, SCORE `10008ee4`, SHIELDS `10009058`, MULT `100091bc` (reachable), and ten in the unregistered PLAYER family `10008118…100085f0` (unreachable, messages-notices-console.md §5.2) |
| `FUN_10029fd0` | `li r0,1; stb r0,0xb4(r3)` | score multiplier ← 1 | setup `10026898` (`FUN_10026410`), death `10028150` (`FUN_10027e50`, per `$W/callers.txt`) |
| `FUN_10029f60` | §3.1 | ship sprite from weapon face | `10029118` (`FUN_10028170`, when `FUN_1003b3c0` reports a weapon select), `10029f24` (`FUN_10029f10`) |

### 3.1 `FUN_10029f60(player) @ 10029f60` [HIGH]
`10029f70 addi r3,r31,0x240; bl 0x1003bce0` → the handler's displayed air weapon (pending `+0x50`
if non-null, else current `+0x58`: `1003bce0 lwz r0,0x50(r3); cmplwi; beq; … lwz r3,0x58(r3)`).
Then `lbz r0,0xcc(r31); extsb` (player index):
- `== 1` → `lwz r0,0x148(r3); stw r0,0x1c(r31)` (`player2AppearanceFace_ID`);
- `0` → `lwz r0,0x144(r3); stw r0,0x1c(r31)` (`player1AppearanceFace_ID`);
- negative or ≥ 2 → sprite left unchanged.
It always sets `+0x34 = 1` (size dirty, so `FUN_10012940` re-measures the frame). `FUN_10029f10`
(`10029f24`) wraps it: sprite, then frame +0x20 = 0, banking timer +0xd4 = 0, layer +0x4c = `'play'`
(`10029f34 lis r3,0x706c; addi r0,r3,0x6179`).

## 4. Debris, level-select, score-bar and player-definition modules

### 4.1 `FUN_1002a920 @ 1002a920` — NUMDEBRIS readout value [HIGH; unreachable]
`lwz r3,-0x6164(r2)` (`0x100e01cc`, the debris list) → `bl 0x10000ce0` (list count), returned in r3.
It has no direct caller. Its TVector is at `0x100e0940` (data image), referenced from TOC slot
`r2−0x78e4`, and that slot's only load is `1002aa40` in the NUMDEBRIS handler `0x1002aa30` (raw range
listing): `addi r3,r2,0x36bc; addi r3,r3,0x7c` ("Num Debris:  ", `0x100e9a68`), `li r4,2`, `li r5,0`,
`lwz r6,-0x78e4(r2)`, `bl 0x1002dbd0` (post a type-2 sticky readout whose value callback is
`FUN_1002a920`), `li r3,1`. NUMDEBRIS is registered with debugOnly = 1 (`FUN_1002a5b0` → `FUN_1002d080(…,
1, 1, 0)`), so it is never created (messages-notices-console.md §5.2). Unreachable in 1.0.6.

### 4.2 Level-selection helpers (`FUN_1002e310` screen) [HIGH]
- `FUN_1002fc60(list) @ 1002fc60` = `li r4,1; bl 0x10000cf0`, i.e. element 1 of the 3-preview list
  (the centre preview = the selected sector record). The only call is `1002ea98`. The caller then
  tests record `+0x2c4` to pick button frame `PermFloat 97` (START) vs `98` (NO ACCESS) (dump
  l. 265–272 of the screen).
- `FUN_1002fc90 @ 1002fc90` resets the selection-message flash state at `*(r2−0x6f7c)` =
  `0x100df3b4` → `0x1010332c`: `stb 0,+0` (mode none), `sth 0x7fff,+2` (colour white), `stw 0x20,+4`
  (alpha 32), `stfs +8` ← `*(r2−0x6f90)` = `0x100d70dc` = **1.0** (scale), `stb 0,+0xc` (growing
  flag). Callers: `1002e338` (screen entry), and `1002ed34`/`1002ed74` (moving left / right while a
  flash is shown cancels it, guarded by `if (*state != 0)`). The setter `FUN_1002fe40(mode)` (mode
  1 = acceptance, text format 27, flli 44/45; mode 2 = failure, format 28, flli 46/47) and the
  stepper `FUN_1002fcc0` are outside this scope (front-end NR 9 / O15) [setter roles MED from the
  dump].
- `FUN_1002ff30(button, mousePt) @ 1002ff30` is the button hover test with rollover sound.
  `1002ff44 lwz r3,-0x7904(r2)` (display object `0x100dea2c`) → `FUN_1000c2f0` copies the display's
  window rect (+0xc..+0x18) to the stack: `0x40(r1)` = top, `0x44(r1)` = left. Then x′ = mouse.h −
  left (`1002ff70 subf r4,r4,r6`) and y′ = mouse.v − top (`1002ff78`). The test is **inclusive on all
  four sides**: `x′ < +0x08 → out (blt)`, `x′ > +0x10 → out (bgt)`, `y′ < +0x04 → out`, `y′ > +0x0c
  → out`. Button = {u8 hover @+0, int Rect {top +4, left +8, bottom +0xc, right +0x10}}. The new hover
  goes to +0 (`1002ffc8 stb r31,0x0(r30)`). On a 0 → 1 edge it plays `PermSoundID(11)` (`mbro`)
  with `FUN_10047670(id, 0x4b, 100, 0)` (priority 75, volume 100, no multiple). It returns hover.
  The mouse comes from `FUN_10048ee0` (`GetMouse`, h → [0], v → [1]). Calls: `1002e98c`, `1002ea14`,
  `1002eaf0` (the `<`, `>`, START buttons).

### 4.3 Module init / teardown pairs (U_Manager register `FUN_1003a870`, unregister `FUN_1003a900`) [HIGH]
| function | listing | effect | caller (raw) |
|---|---|---|---|
| `FUN_100313b0` | `addi r3,r2,0x50b4; addi r3,r3,0xf` ("Score Bar" `0x100eb3f3`), `li r4,1; bl 0x1003a900`; `lbz r0,-0x6130(r2)` → if set, `stb 0` | ScoreBar teardown: unregister (logs "Manager Termination: %s"), live flag `0x100e0200` ← 0 | `100006e4` (`FUN_10000630` shutdown) |
| `FUN_100391f0` | `addi r3,r2,0x5d70` ("Player Definition" `0x100ec0a0`), `li r4,1; bl 0x1003a870`; `li r0,1; stb r0,-0x60f8(r2)`; `li r3,1; bl 0x10039280` | PlayerDefinitions init: register, live flag `0x100e0238` ← 1, build the `plde` list (logging on) | `100005b8` (`FUN_100000e0` boot) |
| `FUN_10039230` | `bl 0x1003a900("Player Definition",1)`; if `0x100e0238`: `bl 0x10039c00`, flag ← 0 | PlayerDefinitions teardown | `100006dc` (`FUN_10000630`) |

### 4.4 Player-definition list helpers [HIGH]
- `FUN_100399a0(plde) @ 100399a0` preloads a `plde`'s resources. `FUN_1001f950(1, id, 1)` (sprite)
  for `spriteHighScore_ID` +0x28, `spriteScoreBar_ID` +0x30, `spriteScoreBarShield_ID` +0x38 and
  `spriteScoreBarPower_ID` +0x40 (`100399b8…100399fc`). `FUN_1001f950(0, id, 1)` (sound) for
  `powerupOverloadSound_ID` +0xf0 (`10039a04`). `FUN_1003e580(unit)` for `entry_Spawn_ID` +0xa0,
  `life_Spawn_ID` +0x70, `death_Spawn_ID` +0xbc, `active_MoneyCounterSpawn_ID` +0xc4,
  `active_SpawnOnHit_ID` +0xc8, `active_ShieldWarningObject_ID` +0xcc and
  `active_DefenceBonusObject_ID` +0xd0 (`10039a18…10039a64`). Keys per unit-def-struct.md §9.
  Callers: `100264cc`, `10026534`, `100265b8` (`FUN_10026410` player setup).
- `FUN_10039a80(list, mode) @ 10039a80`: for every `plde` (`FUN_10039520(i)` until 0), mode 1 appends
  each non-`none` sprite ID (+0x28, +0x30, +0x38, +0x40) and mode 0 appends the overload sound
  (+0xf0) as a fresh 4-byte cell (`FUN_1004d320(4)`, `FUN_100009e0`). Other modes are ignored. It
  has no decompile caller. Raw calls come from `10020814` (`li r4,1`) and `10020aec` (`li r4,0`)
  inside the LOGUNUSEDSPRITES (`0x10020740`) / LOGUNUSEDSOUNDS (`0x10020a20`) handlers, between
  `FUN_1003f0b0` (units) and `FUN_1002b400` (weapons). Those commands are debug-only → **unreachable**.
- `FUN_10039940(list) @ 10039940` frees a list of heap cells (pop → delete; `FUN_100008b0(list,1)`).
  The only caller is `10039688` (`FUN_100395d0`, "is unit X referenced by any plde"). That one's only
  raw caller is `10041cb0` in the LOGUNUSEDUNITS handler `0x10041b70`, which is unregistered →
  **unreachable**.
- `FUN_10039c00 @ 10039c00`: if live (`0x100e0238`) and the list `0x100e0234` exists, each element
  whose first word is the magic `0x499602D2` (`10039c80 subis r0,r3,0x4996; cmplwi r0,0x2d2`) is
  unlinked (`FUN_10000c00`) and deleted. Then the list dtor runs and the slot ← 0. Callers:
  `10039258` (teardown) and `100392ac` (`FUN_10039280`, rebuild).

## 5. Unit-definition leftovers (G_UnitDefinitions.cc)

### 5.1 Copy-assignment helpers of `fileData` (Units Cache writer only) [HIGH — listings]
These are all leaves called from `FUN_1003d650` (copy-assignment of unit+0xc, 0x7a54 bytes), whose
only caller is the cache writer `FUN_10041e40`. The offsets agree with unit-def-struct.md §1/§3/§4
(no conflict). Each copies field by field: holes are not copied, bytes are `lbz/stb`, floats
`lfs/stfs`.
| function | target block (unit-relative / state-relative) | size | listing shape |
|---|---|---|---|
| `FUN_1003e1a0` | sound record: unit `entryNoticeSound` +0x424 (also the record shape inside `e120`) | 0x18 | 4× `lwz/stw`, `lfs/stfs 0x10, 0x14` |
| `FUN_1003e120` | shields block unit +0x43c: 3 floats + `shieldSound` + `unshieldedSound` | 0x3c | `lfs 0/4/8`, then two sound-record patterns |
| `FUN_1003e040` | destruct block unit +0x478: IDs, colour (`lhz +8`), `destructNotice_STR` copied as 8 unaligned words +0xa…+0x29, ints, 6 bytes +0x38…+0x3d (incl. key-less +0x3d = unit 0x4b5), words +0x40…+0x50, floats +0x54/+0x58 | 0x5c | `1003e050 lhz r0,0x8(r4)`, `1003e058 lwz r5,0xa(r4)` … `1003e0dc stb r0,0x3d(r3)`, `1003e108 lfs f0,0x54(r4)` |
| `FUN_1003dfb0` | state +0x000: entry-sound record, 4 bools +0x18…+0x1b, loop delay +0x1c, max-to-play +0x20 | 0x24 | `1003dfd0 lfs 0x10`, `1003dfe0..dff8 lbz 0x18..0x1b` |
| `FUN_1003de70` | state +0x024: active-rule count + 5 rules × 0x88 | 0x2ac | `1003de80 addi r0,r3,0x2ac`; loop body 0x88 bytes (`1003df94 addi r4,r4,0x88`) |
| `FUN_1003de30` | state +0x2d0 particles: ID, colour (`lhz +4`), 2 bools +6/+7, 2 ints | 0x10 | listing |
| `FUN_1003de00` | state +0x2e0 collision: ID, 2 bools +4/+5, delay +8 | 0xc | listing |
| `FUN_1003ddc0` | state +0x2ec motion blur: 2 bools, 2 ints, 2 floats | 0x14 | `1003dde0 lfs f0,0xc(r4)` |
| `FUN_1003dd60` | state +0x300 animation: 4 bools + 7 words (+0x304…+0x31c) | 0x20 | listing |
`FUN_1003e020` and `FUN_1003dce0` (pickup block, owner bools) are siblings outside this list
(already HIGH in unit-def-struct.md). Reachability: the Units Cache writer runs at shutdown only
when the cache flag `DAT_100e024c` is set (unit-def-struct.md §8).

### 5.2 List and module frees [HIGH — listings]
- `FUN_1003f410(list) @ 1003f410` frees a state's spawn-set list (`state+0x5dc`): pop → delete, then
  the list dtor. Callers: `1003e210` (`FUN_1003e1e0` unit defaults), `1003e3f8` (`FUN_1003e3d0` state
  defaults) and `1003f3b8` (`FUN_1003f360` free master list).
- `FUN_1003f830 @ 1003f830`: `stw 0` to `−0x60dc(r2)` = `0x100e0254` (family count) and `−0x60e0(r2)`
  = `0x100e0250` (units-in-families count, both printed by the LOGFAMILIES log). Then, if the
  module is live (`lbz −0x60cc(r2)` = `0x100e0264`) and the family list `−0x60d4(r2)` = `0x100e025c`
  exists: pop each family → `FUN_1003fa10`, then the list dtor, and the slot ← 0. Callers:
  `1003d07c` (`FUN_1003d030` shutdown), `1003d10c` (`FUN_1003d0a0` master-list build: clears before
  rebuilding) and `10042208` (`FUN_100420f0` cache reader).
- `FUN_1003fa10(family) @ 1003fa10`: pop each member cell of the embedded list at +0x40 → delete;
  `FUN_100008b0(fam+0x40, −1)` (embedded list: destruct, no delete); delete the 0x4c-byte family.
  The only caller is `1003f874`.
- `FUN_1003fa80 @ 1003fa80`: if live and the "already-loaded resources" list `−0x60d8(r2)` =
  `0x100e0258` exists, it unlinks and deletes every non-null cell, then the list dtor, and the slot ←
  0. Callers: `1003d080` (shutdown) and `1003e528` (`FUN_1003e510`, recreate at game start, so every
  session re-validates unit resources).

### 5.3 Resource-presence checks used by `FUN_1003e680` [HIGH — listings]
`FUN_100417d0(&id, unit, descr)` (sound) and `FUN_100418a0(&id, unit, descr)` (sprite):
1. `id == 'none'` → return (`100417f8 subis r0,r3,0x6e6f; cmplwi r0,0x6e65; beq`).
2. `FUN_1001f950(type, id, 1)`: `li r3,0x0` for sound (`10041808`), `li r3,0x1` for sprite
   (`100418d8`). Success → return.
3. On failure it logs through `FUN_10049550`: `"\n    SOUND RESOURCE MISSING. Tag ID:  '%s',  Calling
   Unit:  \"%s\",  Description:  \"%s\""` (`r2+0x6ce0+0x218c` = `0x100ef19c`) or the SPRITE variant
   (`+0x21e2` = `0x100ef1f2`), with the 4CC text (`FUN_10014060`), the unit's tag name
   (`FUN_10002420('unde', unit+4)`) and `descr`. **The sound variant logs only when sound is
   available** (`10041820 bl 0x10047910; beq` skips the log). The sprite variant always logs.
4. In both, the field is set to `'none'` (`10041870 lis r3,0x6e6f; addi r0,r3,0x6e65; stw r0,0(r29)`).
   The unit def is patched in memory. A missing resource silently disables that sound or sprite for
   the rest of the run (and for the Units Cache if it is written later).
Call sites: `FUN_100417d0` at `1003e6b8`, `1003e6c8`, `1003e6d8`, `1003e6e8` (the four unit sound
records) and `1003ea7c` (each state's entry sound); `FUN_100418a0` at `1003ea8c` (each state's
`stateSpriteFace_ID`).

## 6. Reachability summary
Every function of §1–§5 runs in normal 1.0.6 play except these:
- `FUN_1002a920`, `FUN_10039a80`, `FUN_10039940` are reachable only from unregistered debug
  commands → **unreachable**.
- The §5.1 copy helpers run only when the Units Cache is written (shutdown, cache flag).
- Ten of the 16 `FUN_10029bf0` sites are unreachable (PLAYER).
- The `FUN_10009400` free loop is presumably a no-op (§1.2).

## 7. Open items closed by listing (O4–O7)

### 7.1 O4 — `req+0x28` in the air launchers (combat NR 4, INDEX #46) → **closed** [HIGH]
`FUN_1003c7a0`: `1003c7a8 addi r31,r2,0x69e4` (r31 = `0x100ecd14`, the launcher request template) …
`1003c874 lhz r9,0x28(r31)`, `1003c878 lhz r8,0x2a(r31)` → `1003c8a8 sth r9,0x68(r1)`, `1003c8ac sth
r8,0x6a(r1)` with the request at `0x40(r1)` (`1003c844 addi r3,r1,0x40` → `bl 0x10033220`), so
req+0x28/+0x2a = template+0x28/+0x2a.
`FUN_1003c940`: `1003c950 addi r30,r2,0x69e4`, `1003ca54 lhz r10,0x28(r30)`, `1003ca58 lhz r9,0x2a(r30)`
→ `1003ca88 sth r10,0x70(r1)`, `1003ca8c sth r9,0x72(r1)`, request at `0x48(r1)`.
Template +0x28 = `0x3f800000` = **1.0** (data image `0x100ecd3c`). The pre-main initialiser
`FUN_1003ce60` writes only `0x100ecd18..1f` and `0x100ecd34..3b` of this block (`$W/w3s2-emu.txt`
l. 406–415; `0x100ecd38` becomes `0xffffffff` at runtime). A scan of all seven `r2+0x69e4`
references (`w4s5-r2scan.py 0x69e0 0x6a20`: `1003b3d4`, `1003c0fc`, `1003c4fc`, `1003c7a8`, `1003c950`,
`1003cea4`, plus `1003cec8` = `+0x6a10`): `1003cea4`/`1003cec8` are the initialiser itself (stores
covered by the emulation above); every other base register (`FUN_1003b3c0` r20, `FUN_1003c0d0` r6,
`FUN_1003c4f0` r31, the two air launchers) is used for loads only (listings checked for `st*` through
it). ⇒ **Air and aux launches always pass speed multiplier 1.0.**
Only the ground launcher overrides it (`1003c6cc fdivs; 1003c6d0 stfs f0,0x9c(r1)` = req+0x28 =
distance ratio).
Side note: template +0x24 is −1 at runtime (initialiser), not 0 as damage-health-death.md §2.5 reads
from the image ("+0x20/+0x24 = 0"). +0x20 (the owner) is 0 either way, so that file's conclusion
stands. ⚑ conflict (minor): the image value of +0x24 is quoted where the runtime value is −1.

### 7.2 O5 — the scale-tolerance draw (spawn NR 5 residue) → **closed** [HIGH]
`FUN_100146f0` has three `bl 0x10046580` (int RandomRange):
| site | r3 (lo) | r4 (hi) | result | gate |
|---|---|---|---|---|
| `100148dc` | `100148b8 lwz r3,0x3ac(r28)` `stateOnTimerMin` | `100148c0 lwz r4,0x3b0(r28)` `stateOnTimerMax` | `100148e4 stw r3,0xb8(r31)` timer | every state change |
| `100149f0` | `100149e8 lwz r3,0x30c(r28)` `stateSpriteFrameMin` | `100149ec lwz r4,0x310(r28)` `…Max` | `100149f8 stw r3,0x20(r31)` frame | sprite changed or initial, and `unit+0x124 == 0` (`100149dc`) |
| `10014b14` | `10014b10 neg r3,r4` = −(tol/2) | `10014b04 rlwinm r0,r4,1,31,31; add; srawi r4,r0,1` = tol/2 (C division) | `10014b1c add. r17,r17,r3; bge; li r17,0` | initial state (`10014a34` r21 = arg 2 ≠ 0) and `tol ≠ 0` (`10014afc cmpwi r4,0; beq`) |
Here tol = `unit+0x1b0` `initialScalePercentTolerance_INT` (`10014af4`) and r17 = `unit+0x1ac`
`initialScalePercent_INT` (`10014af8`). The result is clamped at ≥ 0 and converted by
`FUN_1001a260` (percent → float) into scale +0x84. +0x88 ← `stateRequiredScalePercent` (+0x3bc) and
+0x8c ← `stateScaleDeltaPercent` (+0x3c0) follow (`10014b38..10014b54`).
So **scale% = max(0, initial + R(−(tol/2), tol/2))**, drawn once at spawn.
Census (`$W/data/Game/unde`, 386 units): **17 units have tol ≠ 0**, all even (10–90), so tol/2 is exact:
`aieg` 80±15, `aerg` 60±10, `bocr` 100±45, `bude` 50±10, `gesm` 30±5, `pbhf` 100±30, `pdex` 70±20,
`plle` 50±15, `s3cl` 20±5, `shde` 50±10, `smcy`/`smor`/`smbl`/`smgr` 30±10, `tfte` 60±10, `tase` 80±30,
`tgse` 80±30. These are effects (smoke, explosions, crater). Each spawn of one consumes one extra RNG
draw, in the order timer → frame → scale (replay-relevant; the ranges are now exact).

### 7.3 O6 — orphaned orbiter / no-player fall-through → **closed** (shipped data) [HIGH code; census by script]
**Orbiter (combat NR 2).** `FUN_10037350` uses the owner link (`+0x140` with `+0x144 == owner+0x9c`
and owner `+0xcb == 0`), else the owning player (`+0xd8 ≠ −1` → `FUN_10006090`, state 4 only), else
nothing. Census: 4 units set `stateOrbitOwner` — `bgpp` `icpp` `pbpp` `rgpp` (weapon power-up
sparkles), in both of their states ("Expand, Brighten, Orbit Owner" 30 ticks → "Orbit, Fade Out &
Delete" 15 → `Delete`). Each has `canBeDeletedOnOwnerDeletion` TRUE in every state. They are spawned
by `bgpo`/`icpo`/`pbpo`/`rgpo`, which lock to the player (`stateLockToOwnerLoc` TRUE) and carry the
player index in `+0xd8` (inherited, loose-ends-combat.md §4.3).
- Owner deleted → reaper → `FUN_10036120` → `FUN_100364f0` deletes the children with state 0x32a.
- Player death → `FUN_10027e50` calls `FUN_10034b90(index)` first (`10027e70 lbz r3,0xcc(r3); 10027e74
  bl 0x10034b90`), and that deletes every entity of that player whose state has 0x32a (`10034c4c lbz
  r0,0xd8(r23); cmpw` … `10034c8c lbz r0,0x32a(r3)` → `bl 0x10036120`).
⇒ No shipped orbiter can outlive both its owner and its player, so the straight-line orphan motion
never happens in 1.0.6. In the one same-tick window (owner flagged, not yet reaped), the fallback is the
player position. The owner is locked to that same position, so nothing changes visibly.
**No-player fall-through (units NR 3).** `FUN_10015280` with no active player (`10015300 rlwinm.
r0,r3; bne` not taken):
1. `+0x118 = −1`; then Delete/Destruct-on-no-players or flee north/south `nora`/`sora` (unit
   +0x126/+0x127) return early.
2. Otherwise cyclic and constrain run.
3. `100153bc..100153d0` store the stale out-point of `FUN_10005d40` (`10005e68 rlwinm r4,r23,3` with
   r23 = −1 → `lfsx …0x44−8`) into +0x11c/+0x120, and +0x118 ← −1 (`10005e90 li r0,-1`).
4. `100153dc beq 0x1001550c` with `r3 = 0` (`100153c4`) → **no seek**, ramp only (`10015534 bl
   0x10017a10`).
Readers of +0x11c/+0x120 in all of the code (`w4s5-dispscan.py 0x11c/0x120`): `FUN_10016cc0` (seek;
called at `100152bc` (fleeing, target from `FUN_10017510`) and `10015524` (needs `r3 = Hunts` on the
player-present path)) and `FUN_100172d0` (turn; `10017328 lbz r0,0x118(r27); cmpwi r0,-1; bne` → no
turn when −1 and not fleeing). ⇒ The garbage target is **never read**. The next tick with a player
overwrites it first. A replica may store (0, 0). Closed.

### 7.4 O7 items [HIGH]
**(a) `FUN_1000fee0` return codes (damage NR 6) → closed.** r30 starts 0 (`1000feec li r30,0x0`) and
becomes 1 only at `1000ff98 li r30,0x1`. The function returns **0 or 1 only**. 1 means
`mask[y/e][x/e] == 0x001f` (`1000ff88 lhzx; cmpwi r0,0x1f`), where e = `_DAT_100e0134`
(`lwz r4,-0x61fc(r2)`), the mask is `_DAT_100e0138` and its size comes from `FUN_1000a480`. Bounds
are `0 ≤ col < w`, `0 ≤ row < h` **after** `divw` (C division truncates toward 0). So map
coordinates −(e−1) … −1 fall into column/row 0 and are tested, not rejected. `FUN_1000fec0` =
`subi r3,r2,0x864; lwz r3,0(r3)` = window top `0x100e5acc` → **HIGH** (was MED).
**(b) Crosshair "locked" rectangle (damage NR 5) → closed.** The test is in `FUN_10033850`
`100343ac..100344e8`, not inside `FUN_1003bab0`. Unit gates, in order:
- not `harmlessToPlayers` (`lbz 0x11a(r31); bne skip`, r31 = `entity+0x94` from `10033a5c`);
- `unit+8 == 'grnd'` (`subis 0x6772; cmplwi 0x6e64`);
- `canBeHitByPlayerProjectile` (`lbz 0x11c(r31); beq skip`);
- state `IsTargetable` (`lbz 0x34e(r18)`).
Then, per player slot active this tick and not already locked (`lbzx r0,r26,r27` = player `+0x361`
cached at `10033948`), it takes the crosshair point (crosshair object position, cached at `10033940`)
and the entity rect from `FUN_10012ad0` (`10034078..84`: l → `0x50(r1)`, t → `0x4c`, r → `0x48`, b →
`0x44`):
`cx ≥ l` (`fcmpo; cror eq,gt,eq; bne skip`), `cx < r` (`fcmpo; bge skip`), `cy ≥ t` (cror), `cy < b`
(`bge skip`). The rect is **half-open: `l ≤ cx < r`, `t ≤ cy < b`**. The decompile reading is right.
A hit calls `FUN_1003bab0(player+0x240, 1)` (locked frame) and marks the slot, so the first match in
list order wins. The handler clears the lock every tick at the end of `FUN_1003b3c0` (`1003ba80 li
r4,0; 1003ba84 bl 0x1003bab0`), which runs in the player update before the entity pass.
**(c) Hit factor f1 (player NR 7) → closed.** `100342c0 lfs f1,0x274(r31)` with r31 = colliding
`entity+0x94` (set once at `10033a5c lwz r31,0x94(r19)`; no other write to r31 in the function) →
`100342d0 bl 0x10027100`, its only call site (raw scan). So f1 = the colliding unit's `damage_FLOAT`
(+0x274).
**(d) Spawn-countdown entities vs scroll pause (level NR 8) → closed** (bosses.md §2.2 already says
so; listing confirmed here). The loop head runs `10033a60 subi r0,r4,1; stw r0,0xb0(r19); cmpwi
r0,0; ble 10033a7c`, then `stw r17,0xa4(r19); b 0x10034598` (next entity), so a counting entity never
reaches `10033d70 lbz r0,0x346(r18)` (`statePauseVerticalScrolling` → `stb 1,0x140(r1)`, returned at
`100345d8`). New detail: the loop head has **no `+0xcb` test** (`10033a2c..10033d70`, quoted in
full in the reading). An entity flagged deleted or destroyed **earlier in the same pass**, for
example by a player shot processed before it in `FUN_10036cf0`, still runs its particles, sound,
state timer and the pause check this tick. A pausing controller killed that way keeps the scroll
paused for that tick [HIGH code; MED that shipped list order produces it].
**(e) Destroy-action census (scoring NR 6) → closed.** `$W/w4s5-census.py` checks the 36 units with
`includeInGroundAccuracyCount` TRUE. In every state, none has OnTimer/OnHit/OnRange/OnCounter →
`Destroy`/`Delete`, none has an active rule (unit ≠ none) with a Destroy/Delete action, none has
`stateDestructOnNoActivePlayers` and none has `canBeDestroyedOnOwnerDestruction`. No unit anywhere
has `destroyOwnerOnDestruction`. The only ground-layer `playerProjectile` is the player's Plasma
Bomb `plbo` (entity-vs-entity rules, damage-health-death.md §2.5), and level objects carry `+0xd8 =
0xff`, so `FUN_10034b90` never takes them. ⇒ In 1.0.6 a counted unit is destroyed **only by player
damage** (bomb or ramming). `G+0x40` cannot rise from any non-player event. Accuracy falls only
through counted units that leave without being destroyed.

## Worked example — `#player1AppearanceFace_ID` of the Bacta Gun → the ship sprite
Data: `$W/data/Game/wede/Air - Bacta Gun[aibg].wede.txt` line 11 `#player1AppearanceFace_ID <pl1g>`
(line 12 `player2… <pl2g>`, line 9 `minimumLevelAvailable_INT <2>`).
1. **Parse** (`FUN_1002ba00`, listing `disasm-weapons.txt`): r29 = `r2+0x3748`; `1002bc04 addi
   r5,r29,0x37a` → key string `0x100e9df2` = `"#player1AppearanceFace_ID"`; `1002bc08 addi
   r6,r31,0x144; bl 0x1002c7d0` (read ID) stores `'pl1g'` (0x706c3167) at **def+0x144**. Check:
   `1002bc24 li r3,1; bl 0x1001fbe0` (the sprite exists?); if not, it logs and `1002bca0 stw
   'none',0x144(r31)`. The same at `1002bcb0` for +0x148 (`0x100e9e0c`).
2. **Equip**: entering sector 2, `FUN_1003af90(h,1)` equips Bacta (loose-ends-combat.md §6.5) as
   handler current `+0x58` (or pending `+0x50` during a power-up).
3. **Apply**: the select flag from `FUN_1003b3c0` (`10029104 lbz r0,0x38(r1); beq`) → `10029118 bl
   0x10029f60`. That calls `FUN_1003bce0(P1+0x240)` → pending if non-null, else current = the Bacta
   def. P1 `+0xcc` = 0 → `10029fa0 lwz r0,0x144(r3); stw r0,0x1c(r31)`: **P1+0x1c = `'pl1g'`**.
   Then `10029fb8 stb 1,0x34(r31)`.
4. **Measure**: the next `FUN_10012940` (`100290b0`, same player update) sees dirty +0x34 and sets
   +0x24/+0x28 = the `pl1g` frame size and +0x2c/+0x30 = half of it (the collision radius and clamp
   margins of player-physics.md §2 follow).
5. A level start or respawn takes the same path through `FUN_10029f10` (`10029f24`), which also sets
   frame 0 (level), +0xd4 = 0 and layer `'play'`.
Player 2 reads +0x148 (`pl2g`). A player index outside 0/1 keeps the previous sprite.

## NOT RESOLVED (this file)
1. Film +0xc/+0x10 (`FUN_10009400` free loop): writers outside `0x10009390–0x10009980` were not
   searched. Settle with a whole-image scan for stores at +0xc/+0x10 off the `gameFilmPtr` register in
   `FUN_100051a0` and G_Film callers.
2. The flash state fields the stepper `FUN_1002fcc0` uses (+4 alpha toward 32, +8 scale between 1.0
   and flli 45/47) were read from the dump only. Front-end O15 owns them.
3. The same-pass processing of +0xcb entities (§7.4 d) is code-certain. Whether any shipped pausing
   controller is ever destroyed before its own update in list order needs a boss/controller list-order
   check (bosses.md).
4. The latent unsigned hit-glow overflow (§2.2) depends on modded `hitGlowSpeed`. It needs a ruling
   only if mods are in scope (they are not, per D30/D67).

## Role-table rows (for merge)
| `FUN_10005d10` | G_Game.cc (span) | clear accuracy-reward-armed `G+0x0c`; called once when the random bonus picks the 100 %-accuracy reward (once per level) | HIGH | listing `10005d10–10005d1c`; caller `1001659c` in `FUN_10016300` (§1.1) |
| `FUN_10006200` | G_Game.cc (span) | ground-accuracy destroyed `G+0x40` += 1; no killer test | HIGH | listing `10006200–10006210`; sole caller `10016514` (§1.1) |
| `FUN_10007150` | G_Game.cc (span) | accuracy counts `G+0x3c`/`+0x40` ← 0 | HIGH | listing; callers `10005564`, `10006518` (§1.1) |
| `FUN_10007280` | G_Game.cc (span) | accuracy-tally reset (+0x48 state, +0x4c/+0x54 timers, +0x50 alpha **32**, +0x58/+0x5c, +0x60 text, +0x160 pct, +0x164 flag, +0x168 payments) | HIGH | listing `10007280–100072b4`; callers `10005568`, `1000651c` (§1.1) |
| `FUN_10009400` | G_Film (span ⚑) | film-object dtor: free +0xc/+0x10 via `FUN_1000cc00`, valid +0 ← 0, delete | HIGH | listing `10009400–10009494`; caller `10005b30` (§1.2) |
| `FUN_10009970` | G_Film | reset replay cursors P1 +4 / P2 +8 | HIGH | listing; callers `100093cc`, `100096dc` (§1.2) |
| `FUN_10009980` / `FUN_10009a20` / `FUN_10009a60` | M_PixelBuffer (span ⚑) | pixel-buffer default ctor / clear 12 words (+0 GWorld) / dtor (`FUN_10009d00` DisposeGWorld + delete) | HIGH | listings; callers §1.3 |
| `FUN_10012610` | G_GameObject (span) | GameObject dtor (owns nothing; delete if flag > 0) | HIGH | listing; 8 callers (§2.4) |
| `FUN_10012750` | G_GameObject (span) | per-tick ramps: visibility +0x68 → +0x6c by +0x70, tint +0x58 → +0x5c by +0x60; clamp at target, floor 0.0 | HIGH | listing `10012750–10012838`; constants `0x100d67c4`/`0x100d67a8` = 0.0; callers `10029080`, `10033e98`, `1003ba2c` (§2.1) |
| `FUN_100128c0` | G_GameObject (span) | identity (`blr`): entity → its position pointer | HIGH | listing; 12 callers in EntityGroup (§2.3) |
| `FUN_100128f0` / `FUN_10012930` | G_GameObject (span) | get x,y into two floats / set x = f1, y = f2 | HIGH | listings; callers §2.3 |
| `FUN_10012ba0` | G_GameObject (span) | get scaled frame w′,h′ (+0x24/+0x28) | HIGH | listing; caller `10029838` (crosshair) |
| `FUN_10012c00` / `FUN_10012c10` | G_GameObject (span) | hit glow off / tick: falling by +0x7c until (unsigned) < 4 → 4, rising until > 32 → 32 and off; speed 6 ⇒ 10 ticks | HIGH | listings `10012c00–10012c9c`; callers `10016330`, `10026a30` / `100290bc`, `10033f08` (§2.2) |
| `FUN_100141a0` | G_Entity.cc (span) | entity ctor: GameObject ctor, +0x94/+0x98 ← 0, 20 spawn-record list ptrs +0x19c…+0x1e8 ← 0, field reset | HIGH | listing `100141a0–1001428c`; caller `100383f4` (§2.4) — was MED in the `FUN_100125d0` shared row |
| `FUN_10014290` | G_Entity.cc (span) | entity dtor (base dtor, delete) | HIGH | listing; caller `10038588` |
| `FUN_10017e10` | G_Entity.cc (span) | free one spawn-record list (pop/delete, list dtor) | HIGH | listing; callers `1001437c`, `10014504` |
| `FUN_10026d60` | G_Player.cc | lives set (stored + 0x1524DCEF) | HIGH | `10026d60 addis r4,r4,0x1525; subi r0,r4,0x2311; stw r0,0x98(r3)` |
| `FUN_10027560` | G_Player.cc | shield set (stored + 1324366.0) | HIGH | `10027560..1002756c`; 5 call sites (§3) |
| `FUN_10027610` / `FUN_10027620` | G_Player.cc | money get / set (± 0xB2CCE) | HIGH | listings (§3) |
| `FUN_100299f0` / `FUN_10029a00` | G_Player.cc | score get / set (± 0x05532A3E) | HIGH | listings (§3) |
| `FUN_10029be0` / `FUN_10029bf0` | G_Player.cc | cheated flag `+0xbd` get / set; set 1 by the 6 registered cheats (and 10 unreachable PLAYER sites), 0 at setup; read into the session result | HIGH | listings; 17 raw call sites with `li r4` (§3) |
| `FUN_10029f60` | G_Player.cc | ship sprite +0x1c ← displayed air weapon's `player1/2AppearanceFace_ID` (+0x144 / +0x148) by index; +0x34 dirty | HIGH | listing `10029f60–10029fcc` (§3.1) |
| `FUN_10029fd0` | G_Player.cc | score multiplier `+0xb4` ← 1 | HIGH | listing; callers `10026898`, `10028150` |
| `FUN_1002a920` | G_Debris.cc (span) | NUMDEBRIS readout value = debris-list count; called via TV `0x100e0940` from handler `0x1002aa30`; **unreachable** (debug-only command) | HIGH | listing + raw range `1002aa30–1002aa68` (§4.1) — was LOW |
| `FUN_1002fc60` | G_LevelSelection.cc | element 1 (centre preview) of the preview list | HIGH | listing; caller `1002ea98` (§4.2) |
| `FUN_1002fc90` | G_LevelSelection.cc | reset selection-message flash state `0x1010332c` {mode 0, colour 0x7fff, alpha 32, scale 1.0, grow 0} | HIGH | listing `1002fc90–1002fcbc` (§4.2) |
| `FUN_1002ff30` | G_LevelSelection.cc | button hover test, inclusive rect relative to the display window; SND 11 (pri 75, vol 100) on entry | HIGH | listing `1002ff30–10030010` (§4.2) |
| `FUN_100313b0` | G_ScoreBar.cc (span) | ScoreBar teardown: unregister "Score Bar", live flag `0x100e0200` ← 0 | HIGH | listing; caller `100006e4` (§4.3) |
| `FUN_100391f0` / `FUN_10039230` | G_PlayerDefinitions.cc | module init (register, flag `0x100e0238`, build `plde` list) / teardown (unregister, free list) | HIGH | listings; callers `100005b8` / `100006dc` (§4.3) |
| `FUN_10039940` | G_PlayerDefinitions.cc | free a temporary ID-cell list (LOGUNUSEDUNITS path only → unreachable) | HIGH | listing; caller `10039688` ← `10041cb0` (§4.4) |
| `FUN_100399a0` | G_PlayerDefinitions.cc | preload a `plde`'s 4 sprites, overload sound, 7 units | HIGH | listing `100399a0–10039a7c` (§4.4) |
| `FUN_10039a80` | G_PlayerDefinitions.cc | collect `plde` sprite IDs (mode 1) or sounds (mode 0) into a list; LOGUNUSEDSPRITES/SOUNDS only → **unreachable** | HIGH | listing; raw callers `10020814`, `10020aec` (§4.4) |
| `FUN_10039c00` | G_PlayerDefinitions.cc | free the `plde` list (magic-checked cells) | HIGH | listing `10039c00–10039ce8` (§4.4) |
| `FUN_1003dd60` `FUN_1003ddc0` `FUN_1003de00` `FUN_1003de30` `FUN_1003de70` `FUN_1003dfb0` | G_UnitDefinitions.cc | copy-assign state sub-blocks +0x300 anim / +0x2ec blur / +0x2e0 collision / +0x2d0 particles / +0x024 rules (0x2ac) / +0x000 sound | HIGH | listings (§5.1) |
| `FUN_1003e040` `FUN_1003e120` `FUN_1003e1a0` | G_UnitDefinitions.cc | copy-assign unit destruct block (0x5c) / shields block (0x3c) / sound record (0x18) | HIGH | listings (§5.1) |
| `FUN_1003f410` | G_UnitDefinitions.cc | free a state's spawn-set list (+0x5dc) | HIGH | listing; callers `1003e210`, `1003e3f8`, `1003f3b8` |
| `FUN_1003f830` / `FUN_1003fa10` | G_UnitDefinitions.cc | zero family counters + free family list / free one family (embedded list +0x40) | HIGH | listings (§5.2) |
| `FUN_1003fa80` | G_UnitDefinitions.cc | free the loaded-resources list `0x100e0258` | HIGH | listing `1003fa80–1003fb58` (§5.2) |
| `FUN_100417d0` / `FUN_100418a0` | G_UnitDefinitions.cc | sound / sprite presence check: load → on failure log "… RESOURCE MISSING" (sound: only if sound available) and set the field `'none'` | HIGH | listings `100417d0–10041954`; strings `0x100ef19c`/`0x100ef1f2` (§5.3) — was MED |
| ⚑ corrected `FUN_1000fee0` | G_Background.cc (span) | water test: returns **only 0/1**; 1 iff mask16[row][col] == 0x001f, col/row = map/e by `divw` (−(e−1)…−1 → 0) | HIGH | listing `1000fee0–1000ffb4` (§7.4a) — was MED |
| ⚑ corrected `FUN_1000fec0` | G_Background.cc | scroll window top `0x100e5acc` | HIGH | `1000fec0 subi r3,r2,0x864; lwz r3,0(r3); blr` — was MED |
| ⚑ corrected `FUN_1003c7a0` / `FUN_1003c940` | G_WeaponHandler.cc | air / aux launch: request from template `0x100ecd14`, req+0x28 = template 1.0 (halfword copy) | HIGH | `1003c874/78`, `1003ca54/58` (§7.1) — `FUN_1003c940` was MED |

## INDEX updates (for merge)
- **#46 closed** → §7.1: both air launchers copy req+0x28 from the template (1.0). Air/aux shots
  always have multiplier 1.0. Minor ⚑: template +0x24 is −1 at runtime (damage-health-death.md §2.5
  quotes the image 0; its conclusion is unaffected).
- File-level NRs closed: damage-health-death.md NR 5 (§7.4b, half-open rect) and NR 6 (§7.4a, codes
  0/1 only; `FUN_1000fec0` HIGH); player-physics.md NR 7 (§7.4c, f1 = `damage_FLOAT`);
  level-scroll-objects.md NR 8 (§7.4d, plus the new same-pass +0xcb detail); scoring-bonuses.md NR 6
  (§7.4e, no non-player destroy path in 1.0.6); loose-ends-combat.md NR 2 (§7.3, data census) and
  NR 4 (§7.1); units-movement.md NR 3 (§7.3, never read); spawn-and-waves.md NR 5 residue and NR 8
  (§7.2, §7.1).
- Narrowed: player-physics.md NR 4 (§2.1: the crosshair fade is `FUN_10012750` on the crosshair
  object). Module spans ⚑: G_Film starts ≤ `0x10009390`; M_PixelBuffer starts ≤ `0x10009980`
  (§1.2–§1.3).
- New NR candidates: this file's NR 1, NR 3 (append rule).
