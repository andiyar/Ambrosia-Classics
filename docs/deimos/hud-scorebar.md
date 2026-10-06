# Deimos Rising 1.0.6 — the in-game score bar (G_ScoreBar.cc) and the text routines it uses

Scope: `FUN_10030f40` (score-bar init, perm rects R0–R15), the whole range `0x10031400–0x10032e60`
(16 functions: `FUN_10031400 10031710 10031760 100317e0 10031ad0 10031ae0 10031d70 10031ea0 10032050
10032250 10032500 100327b0 10032a70 10032b20 10032bd0 10032df0`), `FUN_1003bb40` (weapon icons), and
the G_Text.cc helpers `FUN_1000d130 FUN_1000d260 FUN_1000d380 FUN_1000e270` as far as the HUD
uses them. Read as support: `FUN_1000ef90/ed60/edf0` (tefo load), `FUN_1000e670`, `FUN_1000ebd0`,
`FUN_1000ed10`, `FUN_1000ae20` (display rects only), `FUN_10019570` (draw-command fields only),
`FUN_10014060`, `FUN_1002c630`. OUT: the coin-tally text near the ship (`FUN_100298c0`,
scoring-bonuses.md), notices, level select, the blitters themselves.
Evidence: decompile dump `ghidra/Deimos_pef.decompiled.c`; raw listing `$W/disasm-w2s4.txt`
(project copy `$W/work-w2s4`, `DisasmFuncs.java` on the 28 functions above); data from
`$W/data/Game/{flli,reli,idli,tefo,plde,wede}` and `$W/data/{Game,Interface}/im08` (decoded paks);
constants from `$W/mem/10000000.bin` / `100de330.bin` (Python `struct.unpack('>…')` at the
address minus the image base). `$W` = `/Users/andiyar/ghidra-proj-deimos`.

## 1. Coordinate frames and display rects

`FUN_1000ae20 @ 1000ae20` (display setup) fills the display object `D` = `*(r2-0x7904)` =
`0x100f7bf8` (TOC slot `0x100dea2c`). Listing `1000b148…1000b2fc`; each `bl 0x10020250` returns
the flli whose index was loaded by the `li r3` *before* it:

| D field | value (640×480 display) | arithmetic | evidence |
|---|---|---|---|
| +0x1c..+0x28 game area (top,left,bottom,right) | 0, 32, 480, 448 | left = (monW−F52)/2 + F59 (32); right = left + F54 (416); bottom = top + F55 | `1000b1c0 stw r0,0x20(r31)`, `1000b214 stw r0,0x28(r31)` |
| +0x2c..+0x38 **score bar on screen** | 0, **448**, 480, **608** | left = game right (+0x28); right = left + F57 (160); bottom = top + F58 | `1000b2ac stw r0,0x30(r31)`, `1000b2d8 stw r0,0x38(r31)` |
| +0x3c..+0x48 **score bar in the back buffer** | 0, **416**, 480, **576** | left = F54; right = left + F57; bottom = 0 + F58 | `1000b258 stw r4,0x40(r31)`, `1000b25c stw r0,0x3c(r31)`, `1000b280`, `1000b2a4` |
| +0x68 / +0x70 | back buffer / 160×480 score-bar save buffer | `FUN_100099c0(…, F57, F58)` for +0x70 | `1000b43c…` |

[HIGH — listing; values from flli 52–59 (data-tags.md §3)]
Consequences:
- Every `flli` XLoc/YLoc and every `tefo` Loc of the score bar is in **back-buffer coordinates**
  (score bar = x 416..575). On screen the bar is at x 448..607, so **screen x = buffer x + 32**,
  y unchanged (640×480 display; windowed/centred modes add the same offset to both). [HIGH]
  ⚑ conflict engine-loop.md §5 ("Score-bar element positions are absolute screen x"): they are
  back-buffer x. Also: `FUN_1000ae20` places the score bar directly after the 416-px game area;
  `RightBorderWidth` (F60) is not read there, so the remaining 32 px are x 608..639, not between
  the game and the bar as engine-loop.md §5 orders them. [HIGH for the rect arithmetic]
- `reli` rects R0–R15 are relative to the 160-px bar (x 0..159). `FUN_10030f40` stores each one
  twice per player: local (+0x28 + 16·k) and back-buffer (+0xa8 + 16·k) = local + (top `D+0x3c`=0,
  left `D+0x40`=416): listing `100310c4 lwz r0,0x3c(r1)` (= out[1] = D+0x40) added to +0xac/+0xb4
  (left/right), `100310cc lwz r3,0x38(r1)` (= D+0x3c) added to +0xa8/+0xb0. [HIGH]
- **reli memory order settled**: the meter code computes the bar width as `r[3] − r[1]`
  (`10032460 lwz r7,0x4(r26); 10032464 lwz r6,0xc(r26); 1003246c subf r6,r7,r6`). For
  `#Scorebar Player 1 Shields <31, 117, 127, 132>` this gives 127−31 = 96 = the width of the meter
  sprite (`shme` frames are 96×13, `plate_frames.py` scan). So text order is (left, top, right,
  bottom) and memory is a Mac Rect (top, left, bottom, right). Raises data-tags.md §4's reli
  reading from MED to [HIGH].

## 2. Score-bar state (`*(r2-0x6f28)` → `0x10103610`, two records of 0x14c bytes)

| off | type | meaning | written by | evidence |
|---|---|---|---|---|
| +0x00/+0x04 | 4CC/int | lives symbol face/frame = plde `spriteScoreBar_ID/Frame` (+0x30/+0x34) | `FUN_10031400` | `1003154c lwz r0,0x30(r3)` … `10031574 lwz r0,0x44(r3)`; P2 `10031594 stw r0,0x14c(r30)` [HIGH] |
| +0x08/+0x0c | 4CC/int | shield meter face/frame = plde `spriteScoreBarShield_*` (+0x38/+0x3c) | same | [HIGH] |
| +0x10/+0x14 | 4CC/int | power meter face/frame = plde `spriteScoreBarPower_*` (+0x40/+0x44) | same | [HIGH] |
| +0x18 | int | last score drawn (decoded, `FUN_100299f0`) | init, update | `10031890 stw r3,0x18(r26)` [HIGH] |
| +0x1c | int | last lives value (`FUN_10026d50`) | init, update | `100318c0 stw r3,0x1c(r26)` [HIGH] |
| +0x20 | float | **displayed shield %** (smoothed follower) | update, `FUN_10031710` | §3 [HIGH] |
| +0x24 | float | **displayed power %** (smoothed follower) | update, `FUN_10031760` | §3 [HIGH] |
| +0x28..+0xa7 | 8 Rect | local rects R0..R7 (P1) / R8..R15 (P2): score, life symbol, life count, weapon 1, 2, 3, shields, power | `FUN_10030f40` | `10030fbc addi r4,r28,0x28; li r3,0x0; bl 0x10020220` … `10031044 li r3,0x8` [HIGH] |
| +0xa8..+0x127 | 8 Rect | the same rects in back-buffer coordinates (+416 x) | `FUN_10030f40` | §1 [HIGH] |
| +0x128…+0x12d | 6 bytes | dirty flags: score, life symbol, life count, weapons, shield, power | update / init | `10031818…10031830` [HIGH] |
| +0x12e | byte | "still to be retired": in game at level start; cleared by the one-shot dim redraw | init, update | `10031a9c stb r3,0x12e(r26)` [HIGH] |
| +0x12f | byte | **draw active** (0 = draw dimmed, hide icons) | init, update | `10031a7c` [HIGH] |
| +0x134..+0x14b | 3×{4CC,int} | weapon icons {face, frame}: current, next, next-after | `FUN_1003bb40` | `100318ec addi r4,r26,0x134` [HIGH] |
Constant pools: `r2-0x6f30` → `0x100d7174` doubles {1.0, 100.0, 0.0, 2^52+2^31}; `r2-0x6f2c` →
`0x100d716c` floats {0.0, 100.0} (Python on `10000000.bin`). Init flag `0x100e0200` = 1
(`10030f78 stb r0,-0x6130(r2)`). [HIGH]

## 3. Per-tick update `FUN_100317e0 @ 100317e0(p1, p2)` (caller: update world `FUN_10006b50`, after the players)

For each player (listing `10031810…10031aac`):
1. Clear the six dirty flags.
2. If **not in game** (`FUN_10026c10`, player `+0xc4`) **or out of lives** (`FUN_10026c20`, state 1):
   if `+0x12e` is set → `+0x12f`=0, all six dirty = 1, `+0x12e`=0 (one dimmed redraw), then
   nothing more for this player for the rest of the level. [HIGH `10031a6c…10031a9c`]
3. Otherwise:
   - score changed → store, dirty score; lives changed → store, dirty life count. [HIGH]
   - `FUN_1003bb30(player+0x240)` (handler `+0x08`) ≠ 0 → dirty weapons + rebuild icons
     `FUN_1003bb40(player+0x240, rec+0x134)`. [HIGH `100318cc…100318f0`]
   - **Shield follower**, target s = `FUN_10027540(player)` = true shield % (player `+0xa8` −
     1324366.0, player-physics.md §1). If `+0x20` ≠ s: dirty; if `+0x20 > s`: `+0x20 −= F121`
     (ShieldMeterDecreaseRate 3.0), floored at s; else if `+0x20 < s` **and life state == 4**
     (`FUN_10026c60(player,4)`): `+0x20 += F120` (IncreaseRate 2.0), capped at s.
     ```
     100318fc bl 0x10027540 ; fmr f31,f1 ; lfs f0,0x20(r26) ; fcmpu ; beq skip
     10031920 fcmpo f0,f31 ; ble up ; li r3,0x79 ; bl 0x10020250 ; fsubs ; … fcmpo ; bge ; stfs f31,0x20(r26)
     10031954 bge skip ; li r4,0x4 ; bl 0x10026c60 ; beq skip ; li r3,0x78 ; … fadds ; fcmpo ; ble ; stfs f31
     ```
     [HIGH]
   - **Power follower**, target p = `FUN_1003bb20(handler)` = handler `+0x24` (air power percent
     = 100·level/max, weapons-projectiles.md §2.5). Same scheme with F127 (decrease 4.0) and
     F126 (increase 2.0, again only in state 4). [HIGH `10031998…10031a34`]
   - Then the displayed power is clamped: `< 1.0 → 0.0`, `> 100.0 → 100.0`
     (`10031a3c lfd f0,0x0(r29)` = 1.0; `10031a48 lfs f0,0x0(r30)` = 0.0; `10031a54 lfd f0,0x8(r29)` = 100.0). [HIGH]
- Direct setters: `FUN_10031710(idx, v)` → `+0x20 = v` (no clamp); `FUN_10031760(idx, v)` →
  `+0x24 = v` with the same 1.0/100.0 clamp. [HIGH listing] Callers pass player `+0xcc` (index)
  and 0.0 (`r2-0x702c` pool +0 = 0.0): player death `FUN_10027e50` (both, `10027f4c`/`10027f5c`),
  life-state step `FUN_1002a150` state 2 entering (shield only, `1002a1dc`) and state 3 dying
  (both, every tick, `1002a278`/`1002a288`). [HIGH]
- So: the displayed shield is a smoothed follower of the true shield %, falling 3 %/tick, rising
  2 %/tick only while the ship is active; it is forced to 0 while entering/dying, so after every
  (re)spawn the meter fills from empty at 2 %/tick (100 % in 50 ticks ≈ 1.7 s at 30 fps).
  The displayed power falls 4 %/tick, rises 2 %/tick. [HIGH]

## 4. Draw `FUN_10031ae0 @ 10031ae0` (callers: draw world `FUN_10007070` every loop pass; `FUN_10031400`)

For each player, each dirty element: restore its background by copying its local rect from the
save buffer `D+0x70` to its back-buffer rect (`FUN_10009fd0(src, dst, srcRect, dstRect, 0)`),
draw, then — if the global `DAT_100e01ff` is set — copy that rect from the back buffer to the
screen (`FUN_10032a70`: screen rect = local rect + (`D+0x2c`, `D+0x30`) = +(0, 448), then
`FUN_1000bbd0`). [HIGH for the call shape (listing lines `10031b04…10031d3c`); MED for the
copy semantics of `FUN_10009fd0`/`FUN_1000bbd0` (usage)]
`DAT_100e01ff` is set by `FUN_10031ad0(b)`; level start brackets `FUN_10031400` with 0/1, and
draw world sets it 0 around `FUN_10031ae0` while game `+0x38` (the "game has appeared" flag,
engine-loop.md §3) is 0. So before the game appears HUD updates stay in the back buffer; after,
each redrawn element is blitted to the screen at once (dirty-rect update). [HIGH for the writes;
MED for the purpose]

Element functions (all `HIGH` from listing unless noted; "dim" = `+0x12f == 0`):

| function | element | position source | drawing |
|---|---|---|---|
| `FUN_10031d70 @ 10031d70` | score | tefo 43 `sbs1` (P1) / 44 `sbs2` (P2) Loc | `sprintf(buf, "%0.7i", score)` (`0x100eb411`, `10031e40 addi r4,r2,0x50b4; addi r4,r4,0x2d`) → `FUN_1000d380`. Dim: blend += (32 − blend)/2, cap 32 (`10031e14…10031e3c`) |
| `FUN_10031ea0 @ 10031ea0` | lives symbol | F112/F113 (P1), F114/F115 (P2) = sprite centre | plde `spriteScoreBar` face/frame, draw cmd mode 0. Dim: flag word `|= 1`, blend 16 (`10031ff0 li r0,0x10; stw r0,0x54(r1)`) |
| `FUN_10032050 @ 10032050` | lives count | tefo 45 `sbl1` / 46 `sbl2`; last life 47 `sll1` / 48 `sll2` | n = lives − 1 (floor 0); if F143 (9) > 0 and n > F143 → n = F143 (`10032058 subic. r29,r6,0x1` … `100320a8`); red last-life format when active and n == 0 (`10032148…1003215c li r3,0x2f`); `sprintf("%i")` (`0x100eb417`); dim as score |
| weapons (inline in `FUN_10031ae0`) + `FUN_100327b0 @ 100327b0` | 3 icons | slot 0: F128/129 (P1), F134/135 (P2); slot 1: F130/131, F136/137; slot 2: F132/133, F138/139 | skipped entirely when dim or face = `none`. Flag word 1 (`10032840 stw r3,0x4c(r1)`). Slot 0: scale 1.0 (template), blend = int(F141 Selected 6). Slots 1–2: scale F142 0.7 (`10032980 stfs f1,0x50(r1)`), blend = int(F140 NonSelected 16). float→int via `FUN_1004d5c0` [MED: callee not read] |
| `FUN_10032250 @ 10032250` | shield meter | F116/F117 (P1), F118/F119 (P2) = sprite centre | §5 |
| `FUN_10032500 @ 10032500` | power meter | F122/F123, F124/F125 | §5 (tefo 42 `sbpm` instead of 41) |

Draw command (copy of the template at `0x100eb228`, 0x4c bytes; the decompile shows `0x100eb224`
— the copy-loop +8 hazard: `100327b8 addi r7,r2,0x4ef8` = `0x100eb228`; `subi r5,r7,0x4` then
`lwz r3,0x4(r5)`): +0x04 x, +0x08 y, +0x0c face (or `COST`), +0x10 frame, +0x14 flag word,
+0x18 float scale (template 1.0), +0x1c blend 0..32, +0x20 clip rect (= buffer bounds via
`FUN_1000a530`), +0x31 byte = 1, +0x38..+0x44 COST rect, +0x48 COST colour. [HIGH for the stores
in this file's functions; field meanings from `FUN_10019570` (sprite-sound-containers.md §2.3a):
unscaled sprites are drawn with **(x, y) = frame centre** (`iVar15 - iVar16/2`, int division)
[HIGH, decompile of the dispatcher]; whether the scaled path (`FUN_1001a6f0/aa90`, slots 1–2) also
centres is MED (the reli rects fit only if it does)]
Template statics are filled before `main` by `FUN_10032b20`: the draw-command template `0x100eb228`
(only change vs the image: clip +0x28/+0x2c = 480/416, which every HUD builder overwrites via
`FUN_1000a530`), the text-format template `0x100eb274` (+0x100/+0x104 = `0x100eb374` ← 0) and the sound
record of the notice-post template `0x100eb3bc` (+0x0c = `0x100eb3c8` ← `'none'`,100,100,100,1.0,1.0).
[HIGH — static-init-audit.md §3, §5.1 #4–6] ⚑ corrected (wave 3+4, 2026-10-04): was "copies from `_DAT_100df3f8/f4/f0` and
`PTR_DAT_100df3e4` into `0x100eb22c…0x100eb26c` and two further templates `0x100eb374`, `0x100eb3c8`"
[MED]; the caution below is answered — x = y = 0, face `none`, scale 1.0 are the runtime values. ⚑ caution ⚑ corrected (review wave 2, 2026-10-03) #C1: a static initialiser runs before `main`, so the data-image
bytes of these templates are **not** their runtime values (the same trap as the sprite template
`0x100e63e4`, whose clip `FUN_10014120` sets to {0, 0, 480, 416} — sprite-geometry-draw.md §3.1).
No value read from the image here is trusted until the static-initialiser audit (INDEX #56).

## 5. Meter fill arithmetic (`FUN_10032250`, `FUN_10032500`)

Inputs: f1 = displayed % (`+0x20` / `+0x24`, `10031d0c lfs f1,0x20(r27)`), local rect, buffer rect
`r`, face/frame. Listing `100323a8…100324bc`:
1. Restore background; draw the meter sprite (plde shield/power face+frame, e.g. `shme` 0/1) at
   the flli centre.
2. Clamp v: `> 100.0 → 100.0`, `< 0.0 → 0.0`.
3. If `v < 100.0`: load tefo 41 `sbsh` (shield) / 42 `sbpm` (power) **only for** ColorStrip
   BlendAmount (+0x138, `10032434 lwz r4,0x208(r1)` with the copy at r1+0xd0) and ColorStrip
   Color (+0x13c, `10032458 lhz r0,0x20c(r1)`); draw a `COST` translucent rectangle
   ```
   fill  = fctiwz( (float)(v / 100.0f) * (float)(r.right − r.left) )   ; 1003243c fdivs, 10032484 fsubs, 1003248c fmuls, 10032498 fctiwz
   COST  = { top r.top, left r.left + fill, bottom r.bottom, right r.right }, blend 8, colour 000000
   ```
   i.e. the empty part of the meter is darkened; nothing is drawn over a full meter. [HIGH]
   With blend a = 8 the dispatcher blends `(dst·8 + 0·24)/32`: the empty part shows at 25 %
   brightness [MED — blend formula from sprite-sound-containers.md §2.3a].
   The sbsh/sbpm Loc/Format/strip-offset fields are unused ("Supplied in code"). [HIGH]

## 6. Weapon icons `FUN_1003bb40 @ 1003bb40(handler, out[6])` (callers `FUN_10031400`, `FUN_100317e0`)

`cur = FUN_1003bce0(h)` (pending air weapon, else current); `L = FUN_10005cd0()` (sector).
out[0..1] = cur `scoreBarPreviewFace_ID/Frame` (wede +0x130/+0x134). `n1 = FUN_1002adb0('PEAA',
cur+4 id, L)`; out[2..3] = n1 preview (or cur's if none). If out[2..3] == out[0..1] → slots 1
and 2 = `none`. Else `n2 = FUN_1002adb0('PEAA', n1 id, L)`; out[4..5] = n2 preview (cur's if
none); if equal to slot 0 or slot 1 → slot 2 = `none`. Listing `1003bb70…1003bcb4`. [HIGH]
- Duplicates are detected by **face+frame**, not weapon identity. [HIGH]
- The `cmplwi r3,0x0; bne; lwz r0,0x130(r3)` at `1003bc08…1003bc10` (decompile `iRam00000130`)
  is unreachable: n1 = none makes slot 1 equal slot 0. [HIGH]
- Shipped previews: `wesy` frame 0 Ion, 1 Bacta, 2 Photon, 3 Rear (26×26 frames); Plasma Bomb
  `none`. Slot 0 = selected (opaque-ish, full size), slots 1–2 = what the next two select
  presses give (translucent, 0.7×). [HIGH data; cycle order per weapons-projectiles.md §2.4 MED]
- No ground weapon, ammo, aux-weapon or **bomb count** is shown anywhere on the score bar (no
  handler field other than `+0x08`, `+0x24` and the air weapon is read by any function in scope;
  F151/F152 are read only by the handler). [HIGH by callee census of this range]

### 6.1 Handler `+0x08` (critic D10, weapons-projectiles.md NR 5)
Byte stores to `+0x08` relative to a handler base, whole code image scan (`stb`/`stbu`, d = 8 in
`0x1003a800–0x1003d800`; d = 0x248 from a player base anywhere):
`1003ae34 stb r0,0x8(r27)` (setup `FUN_1003ade0`, r0 = 0, right after its reset call),
`1003afd4 stb r29,0x8(r3)` (reset `FUN_1003af90`, `1003afa0 li r29,0x1`),
`1003b8fc stb r0,0x8(r22)` (select, `1003b8f8 li r0,0x1`). No player-relative store at 0x248
(the four hits are all `r1`, stack). [HIGH]
So `+0x08` = "score-bar weapon icons need rebuilding". It is set by every reset (level start
`FUN_100269a0 → FUN_1003af90(h,1)`, respawn) and every successful select, and is **never
cleared by its consumer** — only setup clears it, and the first level start sets it again. From
the first level start on it stays 1: `FUN_100317e0` rebuilds the icons and redraws the three
icon rects every tick while the player is active. No visible effect (same image redrawn); a
replica may simply rebuild the icons every frame. [HIGH]

## 7. Level start `FUN_10031400 @ 10031400(p1, p2)` (caller: level start `FUN_100064d0`) and init `FUN_10030f40`

`FUN_10030f40` (caller `FUN_100000e0`, module init list; logs "Score Bar"): rects for both
players (§1), `+0x18/+0x1c` = 0, `+0x20/+0x24` = 0.0, all dirty = 1, icon IDs `none`. [HIGH]
`FUN_10031400`: SetGWorld(back buffer); load image `scor` `TGA ` (`1003144c lis r4,0x7363` …
`addi r4,r4,0x6f72`; `Scorebar[scor]` is 160×480, sprite-sound-containers.md §3) and copy it to
the back-buffer bar rect `D+0x3c` and to the save buffer `D+0x70`; if `DAT_100e01ff` blit the
whole bar to the screen rect `D+0x2c` (skipped: the caller clears the flag); build both players'
icons (`1003151c addi r4,r30,0x134`, `1003152c addi r4,r30,0x280`); copy the plde sprite IDs;
per player: dirty score/symbol/count/weapons/shield/power = 1, displayed shield/power = 0.0,
last score/lives = current, `+0x12e = +0x12f = in game (+0xc4)`; then `FUN_10031ae0`; release the
image (`FUN_10020e00(img,-1)`). Player index outside 0/1 → assert `"FALSE"`, `G_ScoreBar.cc`
line 0x16b. [HIGH]

## 8. Two-player layout and the solo game

Player 2 uses its own records (+0x14c), reli R8–R15, flli 114/115, 118/119, 124/125, 134–139,
tefo `sbs2`/`sbl2`/`sll2` and plde `Player 2` (`play` frame 1). Its block sits 235 px lower
(flli and tefo Y, e.g. 41→276, 124→359); the reli rects are lower by 235–244 px (data quirk: P2
Life Count `<56,263,102,307>` is +244, P2 Score bottom +238). `sbl2` X is 498 (P1 499). [HIGH — data]
Solo game: player 2 is not in game at level start → `+0x12e = +0x12f = 0` → its block is drawn
once, dimmed — score digits and lives count at blend 16 (count in the normal cyan format),
lives symbol at blend 16, both meters fully darkened (displayed 0.0 → fill 0), no weapon icons —
and never updated (update branch 2 with `+0x12e` already 0). [HIGH by reading; P2's score/lives
values in a solo game are whatever setup left (player-physics.md §7)]
A player who runs out of lives (state 1) is dimmed the same way on that tick and frozen. [HIGH]

## 9. Text formats and the text renderer (as used by the HUD)

Table: `FUN_1000ed60` loads **54** formats (`cmpwi …0x36` loop; `FUN_10003520('gate', i)` →
`FUN_1000edf0` → `FUN_1000ef90`) into `*(0x100df03c)` = `0x100fb340`, 0x148 bytes each, so format
index i = item i of `idli/Formats[gate]`. ⚑ conflict data-tags.md §4 "Formats[gate] (55 tefo IDs)":
the file has 54 items (0..53) and the loader reads 54. [HIGH]
`FUN_1000d130(i, dst)` copies format i (0x148 bytes) to a local. [HIGH]

Format struct (from `FUN_1000ef90` stores and the default template at `0x100e52e4`):
| off | field | key / default |
|---|---|---|
| +0x000 | char[256] text (sprintf target) | |
| +0x100/+0x104 | x, y | `#Loc_X_INT`, `#Loc_Y_INT` |
| +0x108 | alignment 4CC | `#Format_ID` (default `LEFT`) |
| +0x10c/+0x10d | byte (default 8) / "use own clip" (0 → buffer bounds) | not in file |
| +0x10e | monospaced | `#Monospaced_BOOL` |
| +0x10f | shadows | `#DrawShadows_BOOL` |
| +0x110 | byte → draw cmd +0x31 (default 1; HUD writes 1) | not in file |
| +0x114 | blend 0..32 | `#BlendAmount_0To32_INT` |
| +0x118 | float glyph scale (default 1.0) | not in file |
| +0x11c | extra spacing | `#SpaceBetweenChars_INT` |
| +0x120/+0x122 | colourise / colour | `#Colorise_Do_BOOL`, `#ColoriseColor_RGB` |
| +0x12c, +0x130/+0x134, +0x138, +0x13c, +0x140/+0x144 | colour strip: on, H/V offset, blend, colour, min W/H | `#ColorStrip_*` |
[HIGH for the stores (decompile) and template bytes; ~~MED for +0x10c/+0x110 meanings~~ → ⚑ corrected (review wave 3, 2026-10-06) #S: HIGH — +0x10c = render layer, +0x10d = clip select (0 buffer bounds, 1 template clip 480/416), +0x110 = draw-now (text-metrics-lists.md §2.2, `1000e72c…1000e794`, `100195ac`)]
⚑ conflict data-tags.md §5: `#Size_INT` is never read — the string "Size_INT" does not occur in
the data image and `FUN_1000ef90` reads only the 16 keys above. Every format uses the one font
`*(0x100e0120)` (Fonts[tesp] lists only `tesm`). [HIGH for the absence; MED for the font]

HUD formats (decoded files): | idx | tag | Loc | align | mono | spacing | colour |
|---|---|---|---|---|---|---|
| 41 | sbsh | (code) | — | — | — | strip blend 8, colour 000000 (meter overlay only) |
| 42 | sbpm | (code) | — | — | — | same |
| 43/44 | sbs1/sbs2 | 494,83 / 494,318 | CENT | yes | 4 | 94dee6 |
| 45/46 | sbl1/sbl2 | 499,50 / 498,285 | CENT | yes | 0 | 94dee6 |
| 47/48 | sll1/sll2 | 499,50 / 498,285 | CENT | yes | 0 | ff0000 |
[HIGH — files + index mapping above]

`FUN_1000d380 @ 1000d380(fmt, rectOut)` = draw text:
1. First call only: measure glyph frames `f('1') + i`, i = 0..9, keep the max width/height in the
   cache `*(0x100df044)` and set `DAT_100e0124 = '0' + i` of the **first strictly widest** frame
   (`1000d3f4 li r4,0x31; bl 0x1000ebd0` → frame of '1'; `1000d418 add r4,r28,r24`;
   `1000d434 ble`; `1000d438 addi r0,r24,0x30`; `1000d474 stb r25,-0x620c(r2)`). Frame f('1')+i
   is the glyph for digit i+1 (frames 52–61 = 1…9,0, data-tags.md §5), so the label is off by one:
   with tesm widths 5,6,7,7,7,7,6,7,7,7 (frames 52–61; ⚑ corrected (wave 3+4, 2026-10-04): was "5,6,7,7,7,6,7,7,7,7" — the 6-px
   digit is frame 58 ('7'), not 57 ('6'); outcome unchanged; text-metrics-lists.md §1.4) the widest-first is
   frame 54 ('3', 7 px) but `DAT_100e0124` = '2', whose glyph is 6 px. **Monospaced cells are 6 px,
   not 7** — an original quirk the replica must copy. [HIGH for the code; MED for the frame widths]
2. If shadows: one pass with shadows (`FUN_1000e670`: offset F19/F20, blend max(F21, blend)). [HIGH; was MED]
3. If colour strip: measure, grow by H/V offsets, apply min width by alignment and min height,
   draw a `COST` rect (strip blend/colour). [HIGH; was MED] ⚑ corrected (review wave 3, 2026-10-06) #S: both steps are listing-read in
   text-metrics-lists.md §2.2–§2.3 (`1000e6c4…1000e8ac` shadow variant; strip `1000d528…1000d55c`,
   grow/min `1000d56c…1000d68c`; the strip is always queued, cmd+0x31 = 0); the shadow pass
   is dead in 1.0.6 (no `tefo` sets `#DrawShadows_BOOL`).
4. Draw the text (shadows off). [HIGH for the call order]

`FUN_1000e270 @ 1000e270(font, fmt, rectOut, draw)` = layout (+ draw if `draw`); returns
(top = y, left = start x, bottom = y + max glyph height, right = end + 1). Width pass (not for
LEFT): `W = 0.0 + Σ (spacing + glyph width)`, glyph = `DAT_100e0124` when monospaced
(`1000e328…1000e380`). Start x: CENT `fctiwz(X − 0.5·W)` (`1000e410 fnmsubs`); RIGH `X − W`;
CEBU `fctiwz((F52 640 − W)·0.5)`; CEGA `fctiwz((F54 416 − W)·0.5)` (X ignored for both); LEFT X.
Draw pass: per char `cell = x + spacing`; glyph drawn left-aligned at `cell` (monospaced: the
real glyph in a cell as wide as `DAT_100e0124`); `x = cell + width`. `FUN_1000e670` draws the
frame centred at `(cell + w/2, y + h/2)`, so **Y = glyph top**; colourise → flag 4 + colour, else
blend > 0 → flag 1. [HIGH for the alignment arithmetic (listing `1000e39c…1000e4fc`, `r30` →
`0x100d63f0` floats {1.0, 0.0, 0.5}); MED for the per-glyph draw (decompile)]
`FUN_1000d260 @ 1000d260(fmt, rectOut)` = the same digit-cache step, then `FUN_1000e270(…, 0)`:
measure only. Not called by the HUD. [HIGH — ⚑ corrected (review wave 3, 2026-10-06) #S: was MED; listing `1000d260…1000d368`, text-metrics-lists.md §4]
Glyph order: the HUD prints only `0`–`9`; frames 52–61 (`1`…`9`,`0`) of `tesm` (data-tags.md §5).

Side finding — INDEX #5 (`#Format_ID <3>`/`<4>`): `FUN_1002c630` returns the value via
`strtok(found,"<")`, `strtok(NULL,">")` (`FUN_100578f0` calls; MED that it is MSL strtok), which
writes NUL over `>`. The 4 bytes copied are `'3' 0 …`, `FUN_10014060` makes the C string "3"
(clears 5 bytes, copies 4), and `strcmp` with "3"/"4" matches → **3 = CEBU, 4 = CEGA**, agreeing
with the file comments ("Centre in game area" on the `<4>` files). [MED]

## Worked example

Player 1, sector 5, true shield 62.5 %, air power level 7 of max 20 (handler `+0x24` =
100·7/20 = 35.0), 2 lives, score 123456; steady state (followers already at target), Photon Beam
selected. Back-buffer coordinates; add 32 to x for the screen.

| element | rect/xy (buffer) | source index | value / pixels this tick |
|---|---|---|---|
| bar background | 416..575 × 0..479 | `D+0x3c` (F54, F57, F58) | `scor` TGA |
| score text | restore rect x 441..551, y 81..95 | R0 `<25,81,135,95>` | "%0.7i" → `0123456`; mono cell 6 + spacing 4 → W = 7·10 = 70; start = fctiwz(494 − 35.0) = 459; glyph lefts 463, 473, 483, 493, 503, 513, 523; rows 83..95 (h 13); colour 94dee6 (tefo 43) |
| lives symbol | restore 514..554 × 22..62 | R1, F112/F113 (534, 41) | `play` frame 0 (38×38) at 515..552 × 22..59 |
| lives count | restore 472..518 × 19..63 | R2, tefo 45 (499, 50) | n = 2 − 1 = 1 ≤ F143 (9) → "1", cyan; W = 6; start = fctiwz(499 − 3.0) = 496; glyph '1' (5 px) at 496..500 × 50..62. (With 1 life: "0" in ff0000, tefo 47.) |
| weapon slot 0 | restore 449..481 × 181..216 | R3, F128/F129 (467, 199) | Photon `wesy` 2, 26×26 at 454..479 × 186..211, blend 6 |
| weapon slot 1 | restore 492..511 × 188..210 | R4, F130/F131 (502, 199) | Rear `wesy` 3, scale 0.7, blend 16 (≈18 px, centred, MED) |
| weapon slot 2 | restore 519..540 × 188..210 | R5, F132/F133 (530, 199) | Bacta `wesy` 1, scale 0.7, blend 16 |
| shield meter | rect 447..543 × 117..132 | R6, F116/F117 (495, 124) | `shme` 0 (96×13) at 447..542 × 118..130; fill = fctiwz(0.625 × 96) = **60**; COST {117, 507, 132, 543}: bright 447..506 (60 px), dark 507..542 (36 px) |
| power meter | rect 447..543 × 152..167 | R7, F122/F123 (495, 159) | `shme` 1 at 447..542 × 153..165; fill = fctiwz(0.35f × 96 = 33.6) = **33**; COST {152, 480, 167, 543}: bright 447..479, dark 480..542 |

Transients: if the shield had just dropped from 100 to 62.5, the displayed value goes 97, 94, …,
64, then 61 → floored to 62.5 on the 13th tick; widths 93 (0.97·96 = 93.12), 90, …, 61, 60.
If power had stepped 30 → 35 (level 6 → 7), the display goes 32, 34, 35 (capped) → widths 30
(30.72), 32 (32.64), 33. On screen the shield COST rect is {117, 539, 132, 575} and the score
glyphs start at x 495. [HIGH for the arithmetic; MED for glyph and icon widths (plate scan) and
for the slot-1/2 contents (cycle order)]

## NOT RESOLVED (this file)
1. ~~`FUN_1004d5c0` (float → int for the icon blend values 6/16): assumed truncation; not read.~~ →
   ⚑ corrected (review wave 2, 2026-10-03) #S: sprite-geometry-draw.md §4.1 and its role row (`FUN_1004d5c0` = MSL double →
   unsigned int, listing; truncation).
2. ~~The scaled sprite path `FUN_1001a6f0`/`FUN_1001aa90`: whether (x, y) is the centre and how
   0.7 × 26 is rounded (slots 1–2 pixel extents).~~ → ⚑ corrected (review wave 2, 2026-10-03) #S: sprite-geometry-draw.md
   §3.3 (centred; w' = trunc(w·s), left = trunc(X − 0.5·W); listing `1001a75c..1001a7e8`).
3. ~~Format byte `+0x10c` (default 8 → draw cmd +0x30) and the `+0x31 == 0` path `FUN_1001a450`
   (`+0x110`): meanings unknown; the HUD always uses `+0x110 = 1`.~~ → ⚑ corrected (wave 3+4, 2026-10-04): text-metrics-lists.md
   §2.2 — +0x10c = render layer, +0x10d = clip select, +0x110 = draw now (0 queues on layer +0x10c).
4. ~~`FUN_1000bbd0` / `FUN_10009fd0` exact copy semantics (mode 0; interlacing interaction).~~ → ⚑ corrected (wave 3+4, 2026-10-04):
   display-window-present.md §2.1, §5.2 — one `CopyBits` srcCopy per rect, no offset; `FUN_10009fd0`'s two
   CopyBits are identical; interlacing touches only the background copy.
5. Frame widths come from the plate re-scan, not from the game's own frame table; a run of
   `FUN_10019ca0` on `tesm` frames 52–61 would confirm the 6-px monospaced cell. ⚑ corrected (wave 3+4, 2026-10-04) narrowed:
   an index-plate re-scan confirms 6 px (text-metrics-lists.md §1.4–§1.5; widths still MED, its NR 6).
6. ~~Space-character advance (INDEX #6) narrowed only: with scale 1.0 `FUN_1000ebd0` takes the size
   from the per-ASCII cache `*(0x100df024)` (`FUN_1000ed10`, 128 × 8 bytes); its filler is unread.~~ →
   ⚑ corrected (wave 3+4, 2026-10-04): text-metrics-lists.md §1.2–§1.5 — filler `FUN_1000ec70`; space = invisible frame 90,
   4 px at scale 1.0 (`trunc(4·s)` otherwise), never drawn (INDEX #6 closed).
7. ~~`FUN_10032b20` source values (`_DAT_100df3f8/f4/f0`, `PTR_DAT_100df3e4`) not resolved; the
   template bytes in the image already give x=y=0, face `none`, scale 1.0. ⚑ caution ⚑ corrected (review wave 2, 2026-10-03)
   #C1: those image bytes are pre-initialiser values; `FUN_10032b20` overwrites (at least)
   `0x100eb22c…0x100eb26c`, `0x100eb374`, `0x100eb3c8` before `main`, exactly as `FUN_10014120`
   turns the sprite template's zero clip into {0, 0, 480, 416} (sprite-geometry-draw.md §3.1).
   The image reading is not evidence for the runtime template; settle with the INDEX #56 audit.~~ → ⚑ corrected (wave 3+4, 2026-10-04): closed — static-init-audit.md §5.1 #6 (conflict 7):
   `FUN_10032b20` writes only x, y ← 0 and the clip (overwritten by every builder), so the image values
   x = y = 0, face `none`, scale 1.0 are the runtime values; the two "further templates" are T+0x100 and the
   notice sound record.

## Role-table rows (for merge)
| `FUN_10030f40` | G_ScoreBar.cc | score-bar init: per player 8 local rects (R0–7 / R8–15) + back-buffer copies (+416 x), state reset | HIGH | listing `10030fbc…10031124` — ⚑ corrected: was "score bar rects" MED |
| `FUN_10031400` | G_ScoreBar.cc | level start: load `scor` background into back + save buffers, icons, plde sprite IDs, all dirty, meters 0, draw | HIGH | listing; caller `FUN_100064d0` |
| `FUN_10031710` | G_ScoreBar.cc | set displayed shield % (+0x20) for player index | HIGH | listing; callers `FUN_10027e50`, `FUN_1002a150` |
| `FUN_10031760` | G_ScoreBar.cc | set displayed power % (+0x24), clamp <1→0, >100→100 | HIGH | listing |
| `FUN_100317e0` | G_ScoreBar.cc | per-tick HUD update: dirty flags, shield/power followers (F120/121/126/127; rise only in state 4), icon rebuild on handler +0x08, one-shot dim on game over | HIGH | listing `10031810…10031aac` — ⚑ corrected: was "score bar meters update" MED |
| `FUN_10031ad0` | G_ScoreBar.cc | set "blit element to screen" flag `DAT_100e01ff` | MED | read — ⚑ label audit (review wave 2): was HIGH on read only |
| `FUN_10031ae0` | G_ScoreBar.cc | draw dirty elements of both players (restore bg, draw, optional screen blit) | HIGH | listing |
| `FUN_10031d70` | G_ScoreBar.cc | draw score: tefo 43/44, "%0.7i", dim = blend halfway to 32 | HIGH | listing |
| `FUN_10031ea0` | G_ScoreBar.cc | draw lives symbol at F112–115 (dim: blend 16) | HIGH | listing |
| `FUN_10032050` | G_ScoreBar.cc | draw reserve lives = lives−1 capped F143, "%i", tefo 45/46, red 47/48 at 0 | HIGH | listing — ⚑ corrected: was "lives display" MED |
| `FUN_10032250` | G_ScoreBar.cc | draw shield meter F116–119 + COST overlay from left+fill (tefo 41 strip blend/colour) | HIGH | listing |
| `FUN_10032500` | G_ScoreBar.cc | draw power meter F122–125 (tefo 42) | HIGH | listing |
| `FUN_100327b0` | G_ScoreBar.cc | draw weapon icon slot 0/1/2 (F128–139, scale F142, blend F140/F141) | HIGH | listing |
| `FUN_10032a70` | G_ScoreBar.cc | blit one element rect back buffer → screen (local rect + D+0x2c/0x30) | MED | read — ⚑ label audit (review wave 2): was HIGH on read only |
| `FUN_10032b20` | G_ScoreBar.cc (static init) | fill draw template `0x100eb228` (clip), text-format template `0x100eb274` (+0x100/+0x104 = `0x100eb374`), notice-post sound record `0x100eb3c8` | HIGH | listing + interpreter (static-init-audit.md §3) — ⚑ corrected (wave 3+4, 2026-10-04): was "fill draw-command templates `0x100eb228`, `0x100eb374`, `0x100eb3c8`" MED on read |
| `FUN_10032bd0` | G_EntityGroup.cc | "Entity Group" module init: counters, flags `DAT_100e021c..f`, NUMENT/LOGENT/TRACKENT/ENTSTATES/SPAWNTOP/ENTID/ENTFAMILIES/ENTNAMES/PLAYERACTIVESPAWNS console commands | MED | strings |
| `FUN_10032df0` | G_EntityGroup.cc | "Entity Group" module teardown | MED | strings |
| `FUN_1003bb40` | G_WeaponHandler.cc | score-bar icons: {face,frame} of cur(pending)/next/next-after air weapon; repeats (by face+frame) → none | HIGH | listing `1003bb70…1003bcb4` — ⚑ corrected: was MED |
| `FUN_1000d130` | G_Text.cc | copy text format i (0x148 B) | MED | read — ⚑ label audit (review wave 2): was HIGH on read only |
| `FUN_1000d260` | G_Text.cc | measure formatted text (digit cache, no draw) | HIGH | listing `1000d260…1000d368` (text-metrics-lists.md §4) — ⚑ corrected (review wave 3, 2026-10-06) #S: was MED on read |
| `FUN_1000d380` | G_Text.cc | draw formatted text: digit cache (`DAT_100e0124` off-by-one), shadow pass, colour strip, text | HIGH | listing `1000d3e8…1000d474` + decompile |
| `FUN_1000e270` | G_Text.cc | text layout/draw per alignment (CENT X−W/2, RIGH X−W, CEBU/CEGA centred in 640/416), returns bounds | HIGH | listing `1000e304…1000e4fc` |
| ⚑ corrected `FUN_1000e670` | G_Text.cc | measure/draw one glyph (centre x+w/2, y+h/2; shadow offset F19/F20, blend F21; colourise flag 4) | MED | decompile — was "text shadow settings" MED |
| `FUN_1000ed60` | G_Text.cc | load the 54 permanent text formats (gate idli order) | MED | read — ⚑ label audit (review wave 2): was HIGH on read only |
| `FUN_1000edf0` | G_Text.cc | load one tefo tag and parse it | MED | read |

## INDEX updates (for merge)
- **#5 closed (MED)**: `<3>` = CEBU, `<4>` = CEGA (strtok NUL + 4-byte copy + strcmp) — this file §9.
- **#6 narrowed**: space advance comes from the per-ASCII size cache `0x100df024` when scale is
  1.0 — §9, NR 6.
- Critic D10 / weapons-projectiles.md NR 5 closed: handler `+0x08` is never cleared after setup;
  icons rebuild every tick — §6.1 (HIGH).
- Corrections to merge: engine-loop.md §5 (score-bar coordinates are back-buffer, screen = +32;
  bar at screen x 448..607) — §1; data-tags.md §4 reli order MED → HIGH (§1), "55 tefo IDs" → 54
  (§9); data-tags.md §5 `#Size_INT` is not a parsed key (§9).
