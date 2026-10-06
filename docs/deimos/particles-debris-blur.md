# Deimos Rising 1.0.6 — particles, debris (ground obstacles) and motion blur, with replay order

Scope (wave 2, reader 2): G_Particle.cc and its neighbours `0x100431f0–0x10044850`
(`FUN_100431f0`, `FUN_10043280`, `FUN_100432d0`, `FUN_10043340` emit, `FUN_100438c0` update,
`FUN_10043ba0` draw, `FUN_10044550`, `FUN_10044630` table init, `FUN_10044840`); the G_Debris
span `0x1002a4f0–0x1002ab20`; G_MotionBlur.cpp `0x100467c0–0x10047100`, plus its init/teardown
pair `FUN_100466e0`/`FUN_10046760` just below the range. The call sites in `FUN_10033850`,
`FUN_10014f10`, `FUN_10016300`, `FUN_10006b50`, `FUN_10007070`, `FUN_10030bc0`, `FUN_100000e0`
and `FUN_100064d0` were walked only at those sites. OUT: the sprite blitter `FUN_10012f20`, the
spawn path `FUN_10033220` (spawn-and-waves.md), sound `FUN_100475e0` (engine-loop.md §9), and
`FUN_1002ab20` (weapons-projectiles.md §1.1).
Evidence: `$W/disasm-w2s2.txt` (raw listing of every function named here; command in brief, project
copy `$W/work-w2s2`). Constants come from `$W/mem/*.bin` through a small reader:
`u32(TOC+off)` with TOC = 0x100e6330, big-endian `f32`/`f64` at the resolved address. Shown as
"(mem: …)".

**Answer in one paragraph.** None of the three subsystems feeds gameplay except debris. Debris is
an invisible list of obstacle rectangles that stops ground units, and it uses no RNG. Particles and
motion blur are purely visual. But particle emission **consumes the shared LCG**: one
`RandomRange(0,4)` per particle (5/10/20/40 per burst), drawn inside the logic tick, after the
game-start `srand`. A replica must make those draws in the same order, or every later gameplay
draw in a film drifts. The motion-blur interval draw is also per tick, but in the shipped data every
blur state has Min = Max = 0, so it never draws. The 302 app-start draws (velocity table + two
start indices) run before any `srand`, so they do not affect replays. They do fix the particle
direction table, which comes out identical on every launch.

## 1. RNG — every draw in scope, in order [HIGH unless marked]

All draws go through `FUN_10046580` (int `R(min,max)`, no draw when min == max; engine-loop.md §9).
No function in scope calls the float variant `FUN_100465e0` (callers.txt: its 4 callers are
`FUN_10017510 FUN_10037930 FUN_10037b50 FUN_100475e0`).

| # | site | draws, in order | when | before/after the game `srand` | replay-relevant? |
|---|---|---|---|---|---|
| 1 | `FUN_10044630` (called first thing by `FUN_100431f0`) | 100 × [`R(0,W)`, `R(0,H)`, `R(0,3)`], W = trunc(flli 54) = 416, H = trunc(flli 55) = 480 → 300 draws | app start, once (`FUN_100000e0` `100005d0 bl 0x100431f0`) | **before** (the only `srand` callers are `FUN_100051a0` and `FUN_100069b0`, callers.txt) | no — every game reseeds |
| 2 | `FUN_100431f0` | `R(0,99)` → burst index `0x100e026c`, then `R(0,99)` → ring index `0x100e0268` | app start, right after #1 | before | no (but see §2.5: the indices are never reset) |
| 3 | `FUN_10043340` emit | per active particle k = 0..N−1: `R(0,4)` (colour variant), N = 5/10/20/40 by type | inside the logic tick, at each emit (callers §2.6) | **after** | **yes** — must replicate |
| 4 | `FUN_10033850` motion-blur gate (`10034340..48`) | `R(stateMinTimeBetweenBlurs +0x2f0, Max +0x2f4)` every tick per entity whose state has `MotionBlur_Required` and whose sprite ID (entity +0x1c) ≠ `none` | inside the logic tick, in entity update step 9 (waves-and-enemies.md §3) | after | yes in principle; **no draw with shipped data** (all 27 blur states have 0/0, §4.4) |
| — | `FUN_100438c0`, `FUN_10043ba0`, `FUN_10046840`, `FUN_10046a10`, `FUN_10046ae0`, `FUN_10046eb0`, all of G_Debris | none (no `bl 0x10046580` / `0x100465e0` in their listings) | | | |

Evidence for #1/#2: listing `100431f0..10043244` (`bl 0x10044630; li r3,0; li r4,0x63; bl
0x10046580; stw r3,-0x60c4(r2)` then the same into `-0x60c8(r2)`). For the inner loop
`100446d0..10044818`: `or r4,r25 (W); li r3,0; bl 0x10046580` → `or r4,r24 (H); bl 0x10046580` →
`li r4,3; bl 0x10046580`, `cmpwi r23,0x64`. Nothing earlier in `FUN_100000e0` reaches `rand`. A
transitive-caller closure of `FUN_100553e0` over callers.txt meets none of the earlier direct
callees (MED for that part: indirect calls are not in callers.txt). So the LCG starts these 302 draws
from its image value `*(u32*)0x100e032c = 1` (mem). That value is MED: it assumes the data image is
the unexecuted PEF data.
For #3, the listing is `1004378c bl 0x10046580` with `li r3,0; li r4,4` (`10043778`, `10043780`),
inside the slot loop `cmpwi r23,0x28`. The draw runs only while `r23 < count +0x46c` (`10043764
cmpw r23,r0; bge`). The slots past the count are cleared without a draw (`10043880 stb 0`).
For #4, the listing is `10034324 lbz r0,0x2ec(r18); beq` → `10034330 lwz r3,0x1c(r19)` vs
`'none'` → `10034340 lwz r3,0x2f0(r18); lwz r4,0x2f4(r18); bl 0x10046580`. The draw comes
**before** the interval compare and before the pool-full check, so it happens even when no blur
is created.

⚑ conflict (engine-loop.md §9 last paragraph): "`FUN_100431f0` draws `R(0,99)` twice at app init".
In fact it makes **302** draws: 300 in `FUN_10044630` first, then the two `R(0,99)`. The
conclusion still holds, because the draws run before any `srand`.
⚑ conflict (damage-health-death.md NR 8, spawn-and-waves.md §9 note): the motion-blur draw is
real, but in the shipped data it consumes nothing (§4.4).

## 2. Particles (G_Particle.cc, strings at `*(r2−0x6dec)` = 0x100efdfc: "Particle", "NUMPG",
"sPriv_GroupListPtr", "G_Particle.cc", "newGroupPtr")

### 2.1 Lifecycle functions [HIGH — listing]
| function | role | evidence |
|---|---|---|
| `FUN_100431f0 @ 100431f0` | module init: register "Particle" (`FUN_1003a870`), live flag `0x100e0274 = 1`, build the velocity tables (`FUN_10044630`), draw both start indices (§1 #2), register console command `NUMPG` ("Displays the current number of Particle Groups in use.") | `100431f8..10043260` |
| `FUN_10043280 @ 10043280` | module teardown: unregister, and if live → `FUN_10044550`, flag = 0 | `10043280..100432b4`; caller `FUN_10000630` |
| `FUN_100432d0 @ 100432d0` | per-level reset: free all groups (`FUN_10044550`), make a new 12-byte list header (`FUN_1004d320(0xc)` + `FUN_10000890`) → `0x100e0270`; assert "sPriv_GroupListPtr" line 0x8f on failure. **Does not touch the two indices.** | `100432e8..10043320`; caller `FUN_100064d0` (level setup) |
| `FUN_10044550 @ 10044550` | free every group, dispose the list, `0x100e0270 = 0` (only if live) | decompile + `-0x60c0(r2)` accesses `1004452c..10044604` |
| `FUN_10044840 @ 10044840` | free one group (`FUN_1004d3b0` if non-null) | `10044840..10044868`; caller `FUN_100438c0` |
Global accesses: a scan of the whole code image for `d(r2)` loads/stores at −0x60bc/−0x60c0/
−0x60c4/−0x60c8 finds only `0x100431f0–0x10044610`. So the particle state is private to the module.
[HIGH — raw scan]

### 2.2 Emit request (argument of `FUN_10043340`, 0x18 bytes) [HIGH]
| off | type | meaning | evidence |
|---|---|---|---|
| +0x00/+0x04 | float | x / y (world; the draw subtracts the horizontal offset, §2.9) | `10043740 lwz r3,0(r22); lwz r0,4(r22)` → each particle +0xc/+0x10 |
| +0x08 | u16 RGB555 | colour (the unit-def `pix16`) | `10043518 lhz r4,0x8(r22)` (extracts `>>10`, `>>5`, `&0x1f`) |
| +0x0c | int | start delay → group +0x468; **all three callers pass 0** | `100434c0 lwz r4,0xc(r22); stw r4,0x468(r24)`; callers `stw r4(=0)` at `10033b28`, `100150f4`, `100163a4` |
| +0x10 | byte | "scrolls with the ground" → group +0x464; callers set it to `unit+0x8 == 'grnd'` (`subf; cntlzw; rlwinm >>5`) | `100434d0`; `10033b2c..40`, `100150f8..10`, `100163a8..c0` |
| +0x14 | OSType | burst type (table §2.3); `'none'` or 0 → return without allocating | `10043370..10043384` |

### 2.3 Burst types — `FUN_10043340` switch [HIGH — listing `10043388..10043478`]
| ID | count N | speed scale (+0x466) | ring (+0x467) |
|---|---|---|---|
| `tiny` | 5 | ×3.0 | no |
| `tici` | 5 | ×3.0 | yes |
| `smal` | 10 | ×3.0 | no |
| `smci` | 10 | ×3.0 | yes |
| `med ` | 20 | ×5.0 | no |
| `meci` | 20 | ×5.0 | yes |
| `larg` | 40 | ×5.0 | no |
| `laci` | 40 | ×5.0 | yes |
Any other ID returns silently, with no allocation and no draw. The scale is +0x466 = 1 → `lfs f1,0x8(r30)` = 3.0, else
`lfs f1,0xc(r30)` = 5.0 (`10043834..10043878`). r30 = `*(r2−0x6df4)` = 0x100d73a4 →
floats {0.03125, 65535.0, 3.0, 5.0, −32.0, 7.0, 0.0, 0.5} (mem). Shipped data uses `tiny smal
smci med meci larg` (unde grep: destruct 13/19/1/55/2/9, state tiny 2/smal 4/larg 1, hit tiny 3).
⚑ `hitParticleDoCircularBurst_BOOL` (unit +0x131) is **not read** at the hit-particle site
(`100150bc..10015114` reads only +0x2d8, +0x17e and unit+8). The ring/burst choice comes only
from the ID's `ci` suffix [HIGH for the site; LOW that no other reader exists].

### 2.4 Group (0x470 bytes, `FUN_1004d320(0x470)`, appended to `0x100e0270`) and particle (0x1c) [HIGH]
| off | type | meaning | evidence |
|---|---|---|---|
| G+0x000 | u32 | magic 0x499602D2 (1234567890) | `100434a4..ac` |
| G+0x004 + 0x1c·k | particle[40] | k = 0..39 | slot loop `addi r26,r26,0x1c; cmpwi r23,0x28` |
| G+0x464 | byte | ground-scroll flag | `100434d4` |
| G+0x465 | byte | "fade-in mode", **always 0** (`100434e0 stb r0(=0)`); the 1-branch of update is dead | |
| G+0x466 | byte | small-speed flag (§2.3) | `100434d8` |
| G+0x467 | byte | ring flag | `100434e4` |
| G+0x468 | int | start delay, −1 per update; particles move/draw only when ≤ 0 | `10043988..1004399c`, `10043c5c..64` |
| G+0x46c | int | particle count N | `100434dc` |
| P+0x00 | byte | alive | `10043774` |
| P+0x01 | byte | 0 | `100437b8` |
| P+0x02 | u16 | core colour (variant `R(0,4)`) | `100437ac sth r5,0x2(r25)` ← `lhzx (r1+0x4c)` |
| P+0x04 | u16 | fringe colour (same variant index) | `100437b0` ← `lhzx (r1+0x40)` |
| P+0x08 | u32 | fade 0..32 (0 = solid) | `100437b4 stw 0` |
| P+0x0c/+0x10 | float | x / y | `10043784/88` |
| P+0x14/+0x18 | float | vx / vy | `100437d8..e0` / `10043810..18`, scaled `10043840..78` |
No cap on the number of groups: one heap block per emit. An allocation failure asserts "newGroupPtr",
G_Particle.cc line 0xde (`10043490..9c`). [HIGH]

### 2.5 Velocity tables — `FUN_10044630 @ 10044630` [HIGH listing; numbers MED]
Two float[100][2] tables: **burst** at `*(r2−0x6e00)` = 0x101185f0, **ring** at `*(r2−0x6dfc)` =
0x101182d0 (mem). For i = 0..99 (`100446d0..10044818`):
```
x = R(0,W); y = R(0,H)                      ; W = trunc(flli54)=416, H = trunc(flli55)=480
dx = W*0.5 − x ; dy = H*0.5 − y              ; f31 = W·0.5, f30 = H·0.5 (lfs 0x1c(r31) = 0.5)
len = FUN_10042f20( trunc(dx*dx + dy*dy) )   ; 10044728 fmuls f0,f28,f28; fmadds f0,f29,f29,f0; fctiwz
ring[i]  = burst[i] = (dx/len, dy/len)       ; 10044748/58 fdivs; 1004475c..68 stfs
k = R(0,3): burst[i] *= {1, 0.85, 0.70, 0.55}[k]   ; doubles at 0x100d73dc/e4/ec (mem), 1004476c..10044808
```
So the ring table holds unit vectors and the burst table holds vectors of length 1/0.85/0.7/0.55.
Quirk: if x = 208 and y = 240 then len = 0 and the entry is NaN. It does not happen with seed 1.
Emit reads entry `idx` of the table and then does `idx += 1; if idx ≥ 99 → 0` (`100437e8 addi;
cmpwi r0,0x63; blt; stw 0`). Entry 99 can be used only as the very first index. Neither index is
reset per level, game, demo or film (§2.1 scan). So the direction sequence of a film's particles
depends on how many particles were emitted since launch. That is **visual only**.
Simulated with MSL rand from seed 1 (MED: it assumes seed 1, a correct LCG, and float sqrt in place
of the sqrt table): the first raw draws are (158, 467, k=1), (1, 267, 3), (75, 204, 0), … The start
indices are burst = **50** and ring = **79**. Burst entries 50..54 are (0.3346, −0.4365), (−0.9206,
−0.3905), (0.0, 0.85), (−0.5189, −0.1823), (−0.3003, −0.6323).

### 2.6 Emitters (all inside the logic tick) [HIGH — listings]
| caller | condition | x, y | colour | type |
|---|---|---|---|---|
| `FUN_10033850` step 2 (`10033a7c..10033b60`) | entity spawn-in delay +0xb0 ≤ 0 (after −1); `stateParticles_ID` (state+0x2d0) ≠ none; if `Repeat` (+0x2d6): last burst +0xf0 == 0 **or** now ≥ +0xf0 + `RepeatDelay` (+0x2d8); else burst count +0xf4 == 0; then if `MaxNumBursts` (+0x2dc) ≠ 0 and +0xf4 ≥ it → **skip the emit but still** +0xf4++ and +0xf0 = now (`10033aec bge 0x10033b54`) | entity +0/+4 (`FUN_100128d0` = plain copy) | state+0x2d4 | state+0x2d0 |
| `FUN_10014f10` (`100150bc..10015114`) | the entity **survived** the hit (the death branch exits at `10015078 bl 0x10016300; b 0x10015260` before this) and `hitParticles_ID` (+0x2d8) ≠ none | entity +0/+4 | unit +0x17e | unit +0x2d8 |
| `FUN_10016300` step 3 (`1001636c..100163c4`) | `destructParticle_ID` (+0x47c) ≠ none; after the obstacle add, before destructSpawn | entity +0/+4 | unit +0x480 | unit +0x47c |
State-change resets: `FUN_100146f0` zeroes +0xf4 (burst count) but **not** +0xf0. Entity reset
`FUN_100142f0` zeroes +0xec/+0xf0/+0xf4 [MED — decompile]. A non-repeating state therefore bursts
once per entry. A repeating state re-entered within `RepeatDelay` of its last burst waits for the
delay to run out.

### 2.7 Colour build in `FUN_10043340` (5 variants per emit) [HIGH listing `10043518..1004373c`]
For variant i = 0..4 and each 5-bit channel c of the request colour:
```
c16  = trunc(65535.0 * (c * 0.03125))                 ; f4 = 65535, f5 = 1/32
core = trunc(c16 * (float)(1.0 − (float)(i*CVA)))      ; CVA = flli 145 Particle_ColorVariationAdjust = 0.12
fringe = trunc(core * FCA)                             ; FCA = flli 146 Particle_FringeColorAdjust = 0.6
pix  = FUN_10010bd0(rgb16) = (R>>1 & 0x7c00) | (G>>6 & 0x3e0) | (B>>11)
```
Values go through u16 stores (`sth`/`lhz`) between steps. Quirk: c = 31 gives c16 = 63487, which
packs back to 30, so even variant 0 is one step darker. Variant factors are 1.0, 0.88, 0.76, 0.64,
0.52. Each particle takes the variant `R(0,4)`, and its core and fringe come from the same i.
`FUN_10010bd0` is MED (decompile only, one line).

### 2.8 Update — `FUN_100438c0 @ 100438c0` (world update, `FUN_10006b50` `10006be0`) [HIGH listing `100438c0..10043b9c`]
It runs once per logic tick, after debris scroll and before motion blur, players and entities
(`10006bd8 bl 0x1002a770` → `10006be0 bl 0x100438c0` → `10006be8 bl 0x10046a10` → … →
`1000702c bl 0x10033850`). A burst emitted in tick N therefore first moves in tick N+1.
Per group: `+0x468 −= 1`. If the result is > 0, skip. Otherwise, for each alive particle:
1. ground flag → `y += scrollDelta` (`FUN_1000fed0` = int `0x100e0130`, pixels scrolled this tick).
2. `vx *= G; vy *= G` with G = flli 144 `Particle_Gravity` = 0.96. Despite the name, this is a
   **uniform drag**, with no downward term (`10043a0c fmuls f1,f1,f31` on both components).
3. `x += vx; y += vy`.
4. Kill the particle if `x < −32.0` (`fcmpo; blt`), or `x + 7.0 > W + 32` (`bgt`), or `y < 0.0`
   (`blt`), or `y + 7.0 > H` (`ble` keeps). Here W = 416 and H = 480.
5. Otherwise, if fade < 32: `fade += trunc(flli 148)` (BlendAmountRate_Long = 1.0 → 1), clamped to 32.
   If fade ≥ 32 already: kill.
A group with no live particle is removed and freed (`10043b60..78`). flli 147
`Particle_BlendAmountRate_Short` (3.0) has **no reader**: there is no `FUN_10020250(0x93)` in the
dump, and a raw `li r3,0x93`→`bl 0x10020250` scan finds nothing [MED — an indirect index stays
possible].
Lifetime: fade runs 0 (emit tick) → 32 after 32 updates. On the 33rd update the particle dies. Its
displacement after n updates is v0·Σ₁ⁿ 0.96ᵏ, at most 17.5·v0 over a life. That is ≈ 52 px at ×3
and ≈ 87 px at ×5.

### 2.9 Draw — `FUN_10043ba0 @ 10043ba0` [HIGH listing `10043ba0..10044500`; layer placement MED]
Called from the end-frame routine `FUN_10030bc0` (`10030cd0`), **every frame whether ticked or
not**. ⚑ corrected (review wave 2, 2026-10-03) #C4 (critic C4 checked against the listing and **not** adopted): the call is
gated on the end-frame **`param_2`** byte, not on the tick flag — `10030be0 or r28,r4,r4` …
`10030cc8 rlwinm. r0,r28,0x0,0x18,0x1f; 10030ccc beq 0x10030cd8` (skips only `10030cd0 bl
0x10043ba0`). `param_2` is the "draw background + particles" argument that `FUN_10030570` passes
through: the game loop passes the constant 1 (`10005aac li r4,0x1; 10005ab0 bl 0x10030570`), level
selection passes 0 (`1002e840 li r4,0x0`, `1002ee1c li r4,0x0`). The tick flag is a separate
byte (`r1+0x39`, §2.1 of timing-frame.md). So in a game the particles are drawn **every
presented frame, ticked or not**, and never in level selection. It sits between `FUN_10018b20(1)` and `FUN_10018b20(2)`, after the terrain blit
`FUN_10010120`, and writes straight into the game pixel buffer `*(*(r2−0x7904)+0x68)` via
`FUN_1000a4a0`. Groups with +0x468 > 0 are skipped. Per alive particle: `sx = x − hOffset`
(`FUN_100100a0` = `0x100e0144`), `sy = y`. It draws only if `sx ≥ 0`, `sx + 7 < W`, `sy ≥ 0`, `sy + 7 < H`.
A 7×7 stamp is drawn with its **top-left** at (trunc sx, trunc sy) (`10043d48 mullw` row·rowBytes +
col·2). The stamp is not centred, so a burst sits 3 px right of and below its source. Each pixel is
`dst' = (dst·w + col·(32−w)) >> 5` in the spread-555 form `(c & 0x7c1f) | (c & 0x3e0) << 15`.
The weights per pixel, with f = fade, are:
```
row0: A A B B B A A      A = min(f+22,31) fringe   B = min(f+10,31) fringe
row1: A B C C C B A      C = min(f+6,31)  fringe
row2: B C D E D C B      D = f fringe      E = f core
row3: B C E X E C B      X = (f > 6 ? f − 7 : f) core   (centre)
row4: B C D E D C B
row5: A B C C C B A
row6: A A B B B A A
```
Quirks: the outer weights are capped at 31, so the A/B/C pixels keep 1/32 of the particle colour
even at f = 32. The centre is solid at f = 0, fades over f = 1..6, then **snaps back** to solid at
f = 7 and ends at 7/32 colour (`10043d30 cmplwi r4,6; ble; subi r31,r4,7`).

## 3. Debris = ground-obstacle rectangles (G_Debris.cc) [HIGH — listings]

There are no sprites and no particles here. "Debris" is a list of int rects `{top, left, bottom,
right}` (16 bytes) in `0x100e01cc` (`r2−0x6164`). All code-image accesses to that slot are in
`0x1002a69c–0x1002aa0c` (raw scan).
| function | role | evidence |
|---|---|---|
| `FUN_1002a5b0 @ 1002a5b0` | init: register "Debris", live flag `0x100e01d0`, console `NUMDEBRIS` ("Displays the number of Debris ob…") | decompile strings |
| `FUN_1002a610 @ 1002a610` | teardown → `FUN_1002a950` | decompile; caller `FUN_10000630` |
| `FUN_1002a660 @ 1002a660` | per-level reset: free all, new list (assert "sPriv_ListPtr" line 0x58) | decompile; caller `FUN_100064d0` — MED, ⚑ label audit (review wave 2) (no listing line cited) |
| `FUN_1002a6d0 @ 1002a6d0` | add: alloc 0x10 ("newDebris" line 0x69), copy words +0/+4/+8/+c | `1002a6f4..1002a744` |
| `FUN_1002a770 @ 1002a770` | per tick: `top += d; bottom += d` with d = `FUN_1000fed0()` (scroll delta) — obstacles ride the terrain; **never removed** until the level reset | `1002a7e4..1002a7fc` |
| `FUN_1002a830 @ 1002a830` | hit test of rect e against every entry, inclusive: `e.bottom ≥ d.top && e.top ≤ d.bottom && e.right ≥ d.left && e.left ≤ d.right` | `1002a8a4 lwz 8(r28)…blt`, `1002a8b4…bgt`, `1002a8c4 lwz 0xc…blt`, `1002a8d4…bgt` |
| `FUN_1002a920 @ 1002a920` | count (no direct caller; probably the NUMDEBRIS callback via `*(r2−…)` = `_DAT_100df318`) | HIGH (⚑ corrected (review wave 3, 2026-10-06) #L: was LOW; NUMDEBRIS readout via TV `0x100e0940`, handler `0x1002aa30`, debug-only (gameplay-leftovers.md §4.1)) |
| `FUN_1002a950 @ 1002a950` | free all + dispose list (if live) | decompile |
Writers (who spawns debris): `FUN_10016300` step 2 (destroyed unit with `destructCreateObstacle`
+0x4b3 that was not spawned on the air layer, rect from `FUN_10012a00`, `10016338..10016364`).
`FUN_10033850` (`10034560..1003456c`) adds an entity's rect when that entity was stopped by an
obstacle and has +0x4b3. `FUN_10035cd0` adds one when the entity was spawned stationary
(damage-health-death.md §2.4).
Reader: only `FUN_10033850` `10034524` (entities with `collidesWithGroundObstacles` +0x128 and not
already stopped) — on hit: velocity 0, +0x13c = 1. **Physics:** the rects only scroll. They have no
velocity, lifetime or drawing. **Collision:** yes. Debris is gameplay-relevant, because queues of
stopped tanks form behind wrecks. It uses no RNG.
⚑ raises damage-health-death.md §2.4 "MED for the inequalities — decompile only" to HIGH (listing above).
`FUN_1002a4f0` (static init — ⚑ caution ⚑ corrected (review wave 2, 2026-10-03) #C1: runtime values of its templates come from these
writes, not the data image, INDEX #56 — copies template words from `PTR_DAT_100df2c0`/`_DAT_100df2b8`/`…2b4`/
`…2fc`/`…2b0` into `0x100e9178..0x100e9304`) and `FUN_1002aa70` (static init of the `"nonenone"`
string pair at `0x100e99d4`) sit in the range but belong to neighbouring modules [LOW].
`FUN_1002aa90`/`FUN_1002aad0` are "Weapon Definition" register+load (`FUN_1002ab20(1)`) and
unregister+free (`FUN_1002b590`) [MED — decompile strings; callers `FUN_100000e0`/`FUN_10000630`].

## 4. Motion blur (G_MotionBlur.cpp; strings at `*(r2−0x6dc4)` = 0x100efef0: "Motion Blur", "NUMBLURS",
"G_MotionBlur.cpp", "Reached Motion Blur Limit", "\nDEBUG: Reached the end of preallocated Motion Blur list!  Num in use: %i")

### 4.1 What it is [HIGH]
Afterimages. Each blur is a frozen **copy of an entity's sprite instance** (frame, scale, tint and
the rest) at the entity's position. Its visibility percent starts at `InitialVisibility` and drops
by `VisibilityDelta` each tick. The blur is deleted when visibility goes below 0. It does not move
and does not scroll with the ground. The frame buffer is not post-processed.

### 4.2 Pool and lifecycle [HIGH — listings]
| function | role | evidence |
|---|---|---|
| `FUN_100466e0 @ 100466e0` | init: register, live flag `0x100e0288`; once: `FUN_10046c70`; console `NUMBLURS` | decompile; caller `FUN_100000e0` `100005e8` |
| `FUN_10046c70 @ 10046c70` | prealloc: clear the 0x2eec-byte table (`FUN_1000cd90`), cached free index = −1; 1000 × `FUN_1004d320(0x94)` + `FUN_100125d0` (sprite ctor), entry {inUse, index, ptr}; object +0xc = index | `10046cbc li r3,0x94`, `10046d10 cmpwi r27,0x3e8` |
| `FUN_10046760 @ 10046760` / `FUN_10046e20 @ 10046e20` | teardown: list free, pool destroy (`FUN_10012610`) | decompile |
| `FUN_100467c0 @ 100467c0` | per-level reset: `FUN_10046ba0` (empty list), new list `0x100e0284`, `FUN_10046d30` (cached = 0 ⚑, count 0, warn flag 0, all 1000 inUse = 0) | decompile; caller `FUN_100064d0` |
| `FUN_10046eb0 @ 10046eb0` | allocate: if count ≥ 1000 → print the limit message once (`FUN_10049550`, `FUN_1002dbd0`) and return 0; else use the cached free index, or scan for the first free slot; count++, cached = −1 | `10046ed0 lwz r4,4(r30); cmpwi r4,0x3e8; blt` |
| `FUN_100470f0 @ 100470f0` | free: inUse = 0, count−−, cached = this index | decompile |
| `FUN_10046ba0` | remove all from the list (objects stay in the pool) | decompile |
| `FUN_10046b70 @ 10046b70` | count (no direct caller; NUMBLURS callback?) | HIGH (⚑ corrected (review wave 3, 2026-10-06) #L: was LOW; NUMBLURS readout via TV `0x100e0a18`, listing `10046b7c..10046b94` (file-pict-alerts-manager.md §8)) |
Quirk: `FUN_10046d30` sets the cached free index to **0** (not −1), so the first blur of a level
takes slot 0 without a scan. That is harmless.

### 4.3 Emit, update, draw [HIGH — listings]
Emit `FUN_10046840(req)` is called only from `FUN_10033850` (`100343a4`):
- Gate (`10034318..1003435c`): entity not deleted (+0xcb == 0), state `MotionBlur_Required`
  (+0x2ec), entity sprite ID +0x1c ≠ `none`; `d = R(Min +0x2f0, Max +0x2f4)` (§1 #4); emit iff
  `now > lastBlur(+0xec) + d` (`cmpw r17,r0; ble skip`); then +0xec = now.
- req = {entity, `InitialVisibilityPercent` +0x2f8, `VisibilityDeltaPercent` +0x2fc,
  `AllowGlowDrawing` +0x2ed}.
- Copy (`10046874..100469e8`): sprite fields +0x18..+0x70 and +0x84..+0x8c from the entity, then
  forced +0x1a = 0 and +0x38 = 0. Glow fields +0x74..+0x80 are copied only if AllowGlow. Otherwise
  they keep whatever that pool slot last held (MED: stale-state quirk; unseen in data, where all are
  FALSE). Then +0x68 = Initial, +0x6c = `*(float*)0x100d7408` = **0.0** (mem), +0x70 = Delta. The
  position is copied (`FUN_100128d0` → `FUN_10012910`).
Update `FUN_10046a10` (world update, `10006be8`): `vis(+0x68) −= delta(+0x70)`. If `vis < +0x6c
(0.0)`, the blur is removed and freed (`10046a94 fcmpo; bge keep`). Lifetime: drawn at Initial,
then ⌊Initial/Delta⌋ more ticks. A Delta ≤ 0 would never expire (no data does this).
Draw `FUN_10046ae0` (draw world `FUN_10007070` `10007094`, right after the entity draw
`FUN_100345f0`): `FUN_10012f20(blur)` for each. The sprite blitter is out of scope, and how it uses
+0x68 is MED (player-physics.md §1 names +0x68/+0x6c/+0x70 the appear-fade current/required/delta).
**Not pref-gated:** none of the blur functions calls the byte-pref reader `FUN_10004ef0`, and the
only limit is the 1000-slot pool [HIGH — listings].

### 4.4 Data [HIGH — unde grep]
27 states in 24 units have `state_MotionBlur_Required_BOOL <TRUE>`. The units are the Flare Gun,
Screw, Screw Mk 2, Screw Mk 3, Twin Gun and Tank Laser bullets, the Iris mine projectile, the
Flipper flame (2 states), Shuriken – Destruction, Random Bonus – Enemy, the Geyser notice, the 12
level-title notices and the War Crime notice. **All 27 have Min = Max = 0**, so there is no RNG
draw and they blur every tick (`now > last + 0`). Initial/Delta pairs: 50/10 ×17 (6 frames of
trail), 100/20 ×6, 60/20 ×2, 100/25 ×1, 100/30 ×1. AllowGlow is FALSE everywhere.
(Python regex over all `*.unde.txt` blocks between `state_MotionBlur_Required_BOOL <TRUE>` and
`stateParticles_ID`.)

## 5. Feedback into gameplay [HIGH]
- Particles: the group list, the tables and the indices are touched only by module code (§2.1, §2.5
  scans). No collision, score or state reads them. **Visual only**, but the emit-time `R(0,4)`
  draws advance the gameplay LCG.
- Motion blur: the list and pool are touched only by module code (scan: `r2−0x60ac` hits only in
  `0x100467fc–0x10046c48`). The entity field +0xec only paces blurs. **Visual only.** The interval
  draw advances the LCG whenever Min ≠ Max (never with shipped data).
- Debris: **gameplay** (stops ground units). No RNG.
- Consequence for the replica: reproduce the exact count and order of particle colour draws. That
  means N per burst, in the burst order of §2.6, interleaved with the other per-entity draws exactly
  where the caller makes them. The particles' look (directions, colours, stamp) can be approximated
  without affecting films. The app-start table draws need not be replayed against the game seed,
  but replaying them from seed 1 gives the original directions.

## Worked example — `Panzer - Scatter Bullet` [psbu] rams a player

Data (`grep` of `$W/data/Game/unde/Panzer - Scatter Bul[psbu].unde.txt` and `…[psbh]…`): psbu has
shields 0.5, score 0, `isGroundBased TRUE`, `doDeathSpawnOnAnyMedia TRUE`, `destructParticle_ID
<smal>`, `destructParticleColor F898F8`, `destructSpawn_ID <psbh>`, destructSound `exsl` with pitch
0.50–0.55, `destructReleaseRandomBonus FALSE`, `destructCreateObstacle FALSE`, `hitParticles_ID
<none>`. psbh ("Scatter Bullet Hit FX") has group 1–1, appears 100, x/yOffset −2..2, randomise FALSE,
speed 0–0, tolerance 0, and state 0 "Expanding" with timer 7–7, frame 4–4, `stateParticles_ID <smal>`,
colour `F880F0`, Repeat FALSE, MaxNumBursts 0, no blur.
Draws in tick N, in order, during psbu's own `FUN_10033850` update (step 8 player collision):
0. Any draws inside the player-hit `FUN_10027100` come first. That is player-physics scope; it can
   reach `rand`.
1. `FUN_10014f10(psbu, …, 100)`: shields 0.5 − 100 → 0, so the death branch runs. Score 0 goes to
   the player (`FUN_10006190`: no draw expected at 0 points, MED). Then `FUN_10016300`. There are no
   hit particles, because the death branch exits first and the ID is none anyway.
2. `FUN_10016300`: obstacle — none. **Destruct particles `smal`: 10 draws `R(0,4)`** (§1 #3).
3. destructSpawn gate `FUN_10016880`: `isGroundBased && !doDeathSpawnOnAnyMedia` is false, so it
   returns 1 with **no draw** (decompile `FUN_10016880`, MED). Spawn request psbh → `FUN_10033220`:
   size 1–1 gives no draw, appears 100 gives no draw, and both offset ranges are open, so radial
   placement **`R(0,359)` = 1 draw**. Speed F(0,0), timer 7–7, frame 4–4, scale tol 0, group delay
   0–0 and tolerance 0 give no draws (spawn-and-waves.md §3.2, waves-and-enemies.md §4; MED for this
   count).
4. destructSound `exsl`: **`F(0.50, 0.55)` = 1 float draw** (engine-loop.md §9 `FUN_100475e0`).
5. No random bonus → no `R(0,100)`.
6. psbh's first update (`FUN_10033850`; the group loop re-reads its bound every pass, `100345a0` /
   `100345c0`, so this is the same tick N if the new group is appended at the tail — NR 2). Spawn-in
   delay 0 → −1 ≤ 0. State particles `smal`, count 0 → **10 draws `R(0,4)`**, and +0xf4 = 1. It
   never bursts again (Repeat FALSE).
Total in scope: **20 int draws `R(0,4)`** (two bursts of 10). Around them sit 1 int (placement)
and 1 float (pitch) from other modules. Order: 10 colour → 1 placement → 1 pitch → 10 colour.
Visual result of the first burst (MED numbers, seed-1 table, first emit since launch): the request
colour F898F8 → pix16 (31,19,31) gives core variants 0x7A5E, 0x6E1B, 0x5DD7, 0x4D93, 0x4130 and
fringe 0x4972, 0x4150, 0x390E, 0x2CEB, 0x24A9. The ten velocities are burst entries 50..59 ×3.0,
e.g. particle 0 = (1.004, −1.310) px/tick, particle 2 = (0.0, 2.55). The second burst (psbh,
F880F0 → (31,16,30)) continues at entries 60..69. Each stamp fades over 32 ticks. Ground
flag = `unit+8 == 'grnd'`, where unit+8 is the derived layer, `'grnd'` iff `isGroundBased`
(unit-def-struct.md row 0x008). So psbu's burst (isGroundBased TRUE) gets +0x464 = 1 and slides
down with the terrain scroll. psbh's burst (FALSE → `'air '`) does not [HIGH for the rule; the layer
derivation is from unit-def-struct.md].

## NOT RESOLVED (this file)
1. `FUN_10043340`'s request colour: whether the unde `RRGGBB` reader packs 8-bit channels into
   555 by `>>3` (assumed in the worked example). Settle: listing of the COLOR reader in
   G_UnitDefinitions (unit-def-struct.md P@ rows).
2. ~~Whether `FUN_100009e0` appends at the list tail. It decides whether an entity spawned during
   `FUN_10033850` (e.g. psbh) emits its state particles in the same tick, and so where its 10 draws
   fall relative to the remaining entities' draws. Settle: listing of `FUN_100009e0`/`FUN_10000e10`.~~
   → ⚑ corrected (review wave 2, 2026-10-03) #C5 #S: **appends at the tail** (listing `$W/disasm-w2s5c.txt`: list header
   {+0 count, +4 head, +8 tail}, node {+0 prev, +4 next, +8 data}; `10000a40 lwz r0,0x4(r28);
   cmplwi; bne; 10000a4c stw r31,0x4(r28)` head only if empty, `10000a5c stw r31,0x4(r3)` old
   tail→next, `10000a68 stw r3,0x0(r31)` node→prev = old tail, `10000a70 stw r31,0x8(r28)` tail =
   node, `10000a7c` count+1). So psbh is updated in the same tick N (worked example step 6).
   Also loose-ends-combat.md §4.5; INDEX #38 struck.
3. LCG state at the first app draw = image value 1. This assumes the data image is pre-execution
   and that no indirect call reaches `rand` earlier in `FUN_100000e0`. Settle: confirm the image
   provenance in `dumpmem.log`, or trace at runtime. It affects only the particle direction table.
4. ~~How `FUN_10012f20` turns visibility +0x68 into blending, and what blur fields +0x1a and +0x38
   are (forced 0). Settle: the sprite blitter listing (sprite-sound-containers.md reader).~~ →
   ⚑ corrected (review wave 2, 2026-10-03) #S: sprite-geometry-draw.md §4.1 (visibility → alpha; +0x38 = shadow pass flag,
   +0x1a = shadow-scaling flag, §5.2).
5. ~~The `FUN_10018b20(n)` layer passes around the particle draw: which sprites are drawn over or
   under particles. Settle: read `FUN_10018b20`.~~ → ⚑ corrected (review wave 2, 2026-10-03) #S: sprite-geometry-draw.md §6
   (particles over layers 0–5 = terrain, ground shadows, ground units; under layers 6–15 = air
   shadows, air units, player, effects, atmosphere, HUD).
6. ~~Console callbacks `FUN_1002a920` / `FUN_10046b70` (no direct callers) are presumed to be the
   NUMDEBRIS/NUMBLURS handlers via TOC function descriptors `_DAT_100df318` / `_DAT_100df568`.
   Settle: resolve the descriptors in the data image.~~ → ⚑ corrected (review wave 3, 2026-10-06) #S: gameplay-leftovers.md §4.1 (`FUN_1002a920` = NUMDEBRIS readout, TV `0x100e0940`, handler `0x1002aa30`) and file-pict-alerts-manager.md §8 (`FUN_10046b70` = NUMBLURS readout, TV `0x100e0a18`, handler `0x10047120`); both debug-only, unreachable (critic wave 3 §3).
7. `hitParticleDoCircularBurst_BOOL` (+0x131): no reader found at the hit site. A whole-binary
   scan for `lbz rX,0x131(rY)` would settle whether it is inert.
8. The `FUN_10006190` (score) and `FUN_10027100` (player hit) draws that precede the destruction
   draws in the worked example — out of scope.

## Role-table rows (for merge)
| `FUN_100431f0` | G_Particle (span) | ⚑ corrected particle module init: register, `FUN_10044630` table (300 draws), then R(0,99) burst index → 0x100e026c, R(0,99) ring index → 0x100e0268, NUMPG command; app start, before any srand (was LOW "two RandomRange(0,99) + FUN_1002d080") | HIGH | listing `100431f0..10043260`; caller `FUN_100000e0` `100005d0` |
| `FUN_10043280` | G_Particle (span) | particle module teardown (free groups if live) | HIGH | listing; caller `FUN_10000630` |
| `FUN_100432d0` | G_Particle.cc | per-level reset: free groups, new group list 0x100e0270; indices NOT reset | HIGH | listing; caller `FUN_100064d0` |
| ⚑ corrected `FUN_10043340` | G_Particle.cc | emit burst: type tiny/tici 5, smal/smci 10, med/meci 20, larg/laci 40 (`ci` = ring table, small ×3 / others ×5); 5 colour variants (flli 145/146); per particle **R(0,4)** colour draw; velocity from the cycling table entry (was MED "emit particles", perm F145/146) | HIGH | listing `10043340..100438b0`; callers `FUN_10033850` `10033b4c`, `FUN_10014f10` `10015114`, `FUN_10016300` `100163c4` |
| ⚑ corrected `FUN_100438c0` | G_Particle (span) | particle update: delay, ground scroll, drag ×flli144 (0.96, not gravity), move, bounds x∈[−32, W+25] y∈[0, H−7], fade += trunc(flli148) to 32 then die; frees empty groups (was MED "particles update (gravity)") | HIGH | listing `100438c0..10043b9c`; caller `FUN_10006b50` `10006be0` |
| `FUN_10043ba0` | G_Particle (span) | particle draw: 7×7 top-left-anchored 555 blend stamp into the game buffer, every presented frame (gated on end-frame `param_2`, constant 1 in the game loop, 0 in level select), at end-frame | HIGH | listing; caller `FUN_10030bc0` `10030cd0`, gate `10030cc8 rlwinm. r0,r28; beq 0x10030cd8` — ⚑ corrected (review wave 2, 2026-10-03) #C4 |
| `FUN_10044550` | G_Particle (span) | free all groups + list | HIGH | listing; callers `FUN_10043280`, `FUN_100432d0` |
| `FUN_10044630` | G_Particle (span) | build ring (unit) and burst (×1/.85/.7/.55) direction tables, 100 entries, 3 draws each (R(0,W), R(0,H), R(0,3)) | HIGH | listing `10044630..10044834`; caller `FUN_100431f0` |
| `FUN_10044840` | G_Particle (span) | free one group | HIGH | listing; caller `FUN_100438c0` |
| `FUN_1002a5b0` | G_Debris.cc (span) | debris module init + NUMDEBRIS (row exists; unchanged) | MED | strings |
| `FUN_1002a610` | G_Debris.cc (span) | debris teardown | MED | decompile |
| `FUN_1002a660` | G_Debris.cc | per-level reset of the obstacle-rect list | MED | decompile + assert string; caller `FUN_100064d0` — ⚑ label audit (review wave 2): was HIGH without a listing line |
| `FUN_1002a6d0` | G_Debris.cc | add obstacle rect (16 bytes) — unchanged | HIGH | listing `1002a6d0..1002a760` |
| `FUN_1002a770` | G_Debris.cc (span) | per tick: shift every obstacle rect's top/bottom by the scroll delta | HIGH | listing; caller `FUN_10006b50` `10006bd8` |
| ⚑ corrected `FUN_1002a830` | G_Debris.cc (span) | rect vs obstacle list, inclusive on all sides (was MED decompile) | HIGH | listing `1002a8a4..1002a8e4` |
| `FUN_1002a920` | G_Debris.cc (span) | obstacle count (NUMDEBRIS callback?) | HIGH | no direct caller — ⚑ corrected (review wave 3, 2026-10-06) #L: was LOW; gameplay-leftovers.md §4.1 (NUMDEBRIS readout, unreachable) |
| `FUN_1002a950` | G_Debris.cc (span) | free all obstacles + list | MED | decompile |
| `FUN_1002aa70` | (static init) | `"nonenone"` string pair template | HIGH | decompile; caller `FUN_10000000` — ⚑ corrected (review wave 3, 2026-10-06) #L: was LOW on decompile; TU init, only the pair `0x100e99d4` +8/+0xc ← 0, static-init-audit.md §3 table A (listing + interpreter); function-roles.md row |
| `FUN_1002aa90` / `FUN_1002aad0` | G_WeaponDefinitions.cc (span) | register+build / unregister+free the weapon list | MED | decompile; callers `FUN_100000e0` / `FUN_10000630` |
| `FUN_100466e0` / `FUN_10046760` | G_MotionBlur.cpp (span) | blur module init (prealloc once) / teardown | MED | decompile; callers `FUN_100000e0` / `FUN_10000630` |
| `FUN_100467c0` | G_MotionBlur.cpp | per-level reset: empty list, new list 0x100e0284, clear pool flags | HIGH | listing; caller `FUN_100064d0` |
| ⚑ corrected `FUN_10046840` | G_MotionBlur.cpp | emit blur: copy entity sprite instance (+0x18..+0x8c, glow only if AllowGlow), vis = Initial, floor 0.0, delta (was LOW "emit motion blur") | HIGH | listing `10046840..10046a04`; caller `FUN_10033850` `100343a4` |
| `FUN_10046a10` | G_MotionBlur.cpp | per tick: vis −= delta; < 0.0 → remove + free | HIGH | listing; caller `FUN_10006b50` `10006be8` |
| `FUN_10046ae0` | G_MotionBlur.cpp | draw all blurs (`FUN_10012f20`) | HIGH | listing; caller `FUN_10007070` `10007094` |
| `FUN_10046b70` | G_MotionBlur.cpp | blur count (NUMBLURS callback?) | HIGH | no direct caller — ⚑ corrected (review wave 3, 2026-10-06) #L: was LOW; file-pict-alerts-manager.md §8 (NUMBLURS readout, unreachable) |
| `FUN_10046ba0` | G_MotionBlur.cpp | remove all from list | MED | decompile |
| `FUN_10046c70` | G_MotionBlur.cpp | prealloc 1000 × 0x94 sprite objects | HIGH | listing |
| `FUN_10046d30` | G_MotionBlur.cpp | clear pool in-use flags, cached index 0 | MED | decompile |
| `FUN_10046e20` | G_MotionBlur.cpp | destroy pool | MED | decompile |
| `FUN_10046eb0` | G_MotionBlur.cpp | allocate pool slot (cap 1000, warn once) | HIGH | listing `10046ed0..` |
| `FUN_100470f0` | G_MotionBlur.cpp | free pool slot | MED | decompile |

## INDEX updates (for merge)
- **#33 closed** → particles-debris-blur.md §1. `FUN_100431f0` makes 302 draws (300 in
  `FUN_10044630` + 2), all before any `srand`, so they do not affect replays. The emitter
  `FUN_10043340` makes one `R(0,4)` per particle inside the tick, which does affect replays. The
  motion-blur interval draw is real, but every shipped blur state has 0/0, so it never draws.
- engine-loop.md §9 last paragraph: ⚑ "R(0,99) twice at app init" → 302 draws (§1). Add the
  emitter's per-particle `R(0,4)` to the per-tick consumer list.
- damage-health-death.md NR 7 closed and NR 8 closed (§1, §4.4); §2.4 debris inequalities MED → HIGH (§3).
- New open items: this file's NR 1–8 (NR 2 matters for replay order; the others are visual).
