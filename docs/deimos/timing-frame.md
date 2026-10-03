# Deimos Rising 1.0.6 — the game clock: frame controller, FPS limiter, speed divider, interlace, timing prefs

Wave-2 reader 3 (2026-10-03). Code readings only; nothing is behaviour-verified.
**Scope:** the frame controller `0x10030190…0x10030e70` (`FUN_10030190`, `FUN_100301d0`,
`FUN_10030210`, `FUN_100302b0`, `FUN_100302e0`, `FUN_10030350`, `FUN_10030360` begin frame,
`FUN_10030570` end-frame wrapper, `FUN_100305e0`/`FUN_10030640` FPS monitor, `FUN_10030790`,
`FUN_100307b0`, `FUN_100307c0`, `FUN_10030870`, `FUN_10030900`, `FUN_10030910`,
`FUN_10030bc0` end frame, `FUN_10030df0`). Also its two callers (`FUN_100051a0` game loop,
`FUN_1002e310` level selection, only where they touch the controller), the timing prefs
(`FUN_10004ef0/ab0/f00/ac0` accessors, `FUN_10004f20`, `FUN_100050f0` defaults, `FUN_10004f80`
load, `FUN_10004540`), the configuration dialog (`FUN_10010fc0`, `FUN_10011590`, resource-fork
`DITL 190`), the console toggles `FPS`/`LIMITFPS`, the interlace consumers (`FUN_10010120`,
`FUN_10009fd0`, `FUN_100450e0`, `FUN_100064d0` excerpt), and the film per-tick step
(`FUN_1002a3a0`, `FUN_10009830`, `FUN_100097a0`, `FUN_10009750`).
**OUT:** what the world update does inside a tick (engine-loop.md §3, level-scroll-objects.md),
render-layer contents, the DrawSprocket/window display code, sound/music volume semantics.
Conventions as in engine-loop.md: `PermFloat(n)` = `FUN_10020250(n)` = item n of
`flli/Game[gafl]`; `GameString(n)` = `FUN_10020260(n)`; byte pref n = prefs `+4+n`
(`FUN_10004ef0`/`FUN_10004ab0`); int pref n = prefs `+0x68+4n` (`FUN_10004f00`/`FUN_10004ac0`).
Listings come from `$W/disasm-w2s3.txt` / `disasm-w2s3b.txt` (DisasmFuncs.java on `$W/work-w2s3`)
and `scratchpad/handlers.txt` (a range-disassembly script on the same project copy for the console
handlers, which Ghidra had not made functions).

Constants used throughout (`grep -n '^#' "$W/data/Game/flli/Game[gafl].flli.txt"`, line−1 = index):
| idx | key | value |
|---|---|---|
| 18 (0x12) | Game_NumFramesUntilGameAppears | 2 |
| 32 (0x20) | FPS_MaxRate | 30 |
| 33 (0x21) | FPS_Delay | 2 |
| 34 (0x22) | FPS_DeficiencyLevel | 10 |
GameStrings (`$W/data/Game/stli/Game[pgsl].stli.txt`, 0-based): 17 "Interlacing ON", 18
"Interlacing OFF", 19 "Auto Interlacing ON", 20 "Auto Interlacing OFF", 24–30 "Game Speed
Normal / Half / 1/4th / 1/8th / 1/16th / 1/32th / Stopped". [HIGH — file bytes]

## 1. The frame-controller object (0x38 bytes, a stack local of each loop)

`FUN_100051a0` keeps it at `r1+0xc0` (`auStack_9a0[56]`), `FUN_1002e310` at `r1+0x8c`. Its
address is passed only to controller methods (and, in the game loop, to `FUN_10007170`, which
only forwards it to `FUN_100302e0`); see §3 for the proof that matters. Field map from the
zeroing constructor `FUN_10030df0` and every reader/writer in the range:
| off | type | meaning | written by | evidence |
|---|---|---|---|---|
| +0x00 | u8 | paused (Caps Lock) | `FUN_10030360` set, `FUN_10030870` clear | dump |
| +0x01 | u8 | film playback (no pause allowed) | `FUN_10030210` param_2 | game loop passes `bVar2` = film flag (`param_1+5`) |
| +0x02 | u8 | quit chosen on pause screen | `FUN_10030870` | `FUN_10022ef0` return |
| +0x03 | u8 | auto-interlace allowed | `FUN_10030210` param_4 (game 1, level select 0) | `FUN_10030640` gate |
| +0x04 | u8 | **game-screen layout** (1 = game area + borders + score bar, 0 = full screen) | `FUN_10030210` param_3 (game 1, level select 0) | present choice §2.4; pause notice 4CC `CEGA`/`CEBU` |
| +0x08 | i32 | frames presented | `FUN_10030bc0` `+1` | `10030d34..d3c`; returned by `FUN_10030360`/`FUN_10030350`; game stores it at game `+0x30` (`10005910 stw r3,0x30(r29)`) |
| +0x0c | 5 B | key-edge latches: +0xe `-`, +0xf `=`, +0x10 F6 | `FUN_10030910` | dump |
| +0x14 | i32 | Esc-hold counter | `FUN_100307c0` | listing §2.5 |
| +0x18 | u32 | TickCount at FPS-window start | `FUN_100305e0`, `FUN_10030640` | listing |
| +0x1c | u32 | TickCount at previous present (limiter) | `FUN_10030bc0` | `10030d30 stw r3,0x1c(r29)` |
| +0x20 | i32 | frames counted in current FPS window | `FUN_10030bc0` `+1`, monitor reset | `10030d40..d48` |
| +0x24 | i32 | FPS shown (last window's count) | `FUN_10030640`, init 30 | `10030690 stw r0,0x24(r30)` |
| +0x28 | i32 | deficient-window counter | `FUN_10030640` | listing |
| +0x2c | i32 | speed divider — **only ever 0** (§3) | `FUN_10030df0`, `FUN_10030790` | `10030e4c`, `10030794` |
| +0x30 | i32 | divider countdown | `FUN_10030bc0`, `FUN_10030790` | listing |
| +0x34 | u8 | tick-next-frame flag | `FUN_10030bc0`, `FUN_10030790` (=1) | `100307b0 lbz r3,0x34(r3)` |
[HIGH for offsets (raw listings `10030df0..10030e54`, `10030bc0..10030de8`, `10030640..`); MED for
the names of +0x03/+0x04 (usage pattern)]

Methods:
| function | role | label | evidence |
|---|---|---|---|
| `FUN_10030190 @ 10030190` | construct (= `FUN_10030df0`) | MED ⚑ label audit (review wave 2) | dump, callers game loop + level select |
| `FUN_10030df0 @ 10030df0` | zero every field | HIGH | listing `10030e0c..10030e54` |
| `FUN_100301d0 @ 100301d0` | destructor (`FUN_1004d3b0` delete if `param_2 > 0`) | MED | dump; called with −1 |
| `FUN_10030210 @ 10030210` | start session: zero, set +1/+4/+3, clear layer queues `FUN_100189f0`, console `FUN_1002d040(+8)`, messages `FUN_1002db50`, FPS monitor init, divider reset, FlushEvents | HIGH | dump + listing |
| `FUN_100302e0 @ 100302e0` | level-transition reset: same minus the field writes (does **not** reset +0x1c) | MED ⚑ label audit (review wave 2) | dump; caller `FUN_10007170` |
| `FUN_100302b0 @ 100302b0` | end session: FlushEvents `FUN_10048e30` | MED | dump |
| `FUN_10030350 @ 10030350` | get frames presented (+8) | MED ⚑ label audit (review wave 2) | dump |
| `FUN_10030900 @ 10030900` | get paused (+0) | MED | dump; caller level select |
| `FUN_100307b0 @ 100307b0` | get tick flag (+0x34) | HIGH | listing |
| `FUN_10030790 @ 10030790` | reset divider: +0x2c = 0, +0x30 = 0, +0x34 = 1 | HIGH | listing `10030790..100307a0` |

## 2. One pass of the loop

### 2.1 Begin frame `FUN_10030360 @ 10030360` (every frame) [HIGH — dump + listing `100304e8..10030564`]
Order: music service `FUN_10047f50` → clear 16 render-layer queues `FUN_100189f0` (listing
`100189f0`: zeroes 16 words at `*(r2-0x7198)`; MED that they are the layer heads flushed by
`FUN_10018b20`) → console: if closed and key 0x32 down open it (`FUN_1002d1a0`), else console
update `FUN_1002d230` → message aging `FUN_1002dd90` (per **frame**) → volume/F6 keys
`FUN_10030910` → `GetMouse` `FUN_10048ee0` → Caps Lock (0x39): released → paused = 0; pressed
and not paused and **not a film** → paused = 1 + notice GameString 0 → quit flag =
`FUN_100307c0` (Esc) or +2 → **if tick flag (+0x34): clear input `FUN_1004aa20` and read ISp
`FUN_1004aa90` unless the console is open** → `*param_2 = tick flag`; return +8.
```
10030514  or r3,r28,r28 ; 10030518 bl 0x100307b0 ; 10030524 beq 0x1003054c
10030528  li r31,0x1    ; 1003052c bl 0x1004aa20 ; 10030534 bl 0x1002d190 ; 10030540 bne 0x1003054c
10030544  bl 0x1004aa90 ; 1003054c stb r31,0x0(r29)          ; *param_2 = tick
```
`FUN_10006b50` (update world) clears and re-reads the same input again at its top (dump
`FUN_1004aa20(); if (!FUN_1002d190()) FUN_1004aa90();`) — a harmless double poll per tick.
Opening the console does **not** stop ticks; it only withholds input (the ship coasts). [HIGH]

### 2.2 Game-loop body (`FUN_100051a0`, listing `100058f8..10005ab0`) [HIGH]
```
100058f8 addi r3,r1,0xc0 ; addi r4,r1,0x39 ; addi r5,r1,0x38 ; bl 0x10030360   ; begin
10005910 stw r3,0x30(r29)                                                    ; game+0x30 = frames presented
1000591c bl 0x100064c0          (if quit)                                     ; stop session
10005920 lbz r0,0x39(r1) ; 10005928 beq 0x10005a18                           ; no tick -> skip to draw
  (appear check: if !game[0x38] && gameTime == PermFloat 18 (=2): music, fade-in FUN_1000ba70(..,1),
   restore interlace pref 5 if game[0xf], game[0x38]=1)                      ; 10005930..100059b8
100059cc bl 0x10006b50 ; 100059dc bl 0x10007170                             ; update world, level-complete
100059e0 lwz r3,0x1c(r29) ; addi r0,r3,0x1 ; stw r0,0x1c(r29)               ; gameTime++
10005a18 bl 0x10007070                                                       ; draw world (every frame)
10005aa4 lbz r5,0x38(r29) ; addi r3,r1,0xc0 ; li r4,0x1 ; bl 0x10030570     ; end(ctrl, 1, appeared)
```
`FUN_10030570` passes r4/r5 through untouched to `FUN_10030bc0` (`10030578 or r31,r3,r3` …
`10030584 bl 0x10030bc0`, no write to r4/r5) — so `param_2` = 1 (draw background/particles) and
`param_3` = "game has appeared" (present enabled). [HIGH]

### 2.3 End frame `FUN_10030bc0 @ 10030bc0` — exact arithmetic [HIGH — listing]
1. `FUN_1002dea0` (draw messages; MED by perm F27); if byte pref 9: draw `"%i"` (string
   `0x100eb21b`, resolved from the data image) of +0x24 in text style 0x28 when
   `+0x24 < PermFloat 32 (=30)` else 0x27 (`10030c3c cmpw r0,r3 ; blt`) — the FPS counter, red/
   normal style choice MED.
2. `FUN_1002d410` (console draw, MED) → `FUN_10018b20(0)` (layers 0–1) → if param_2:
   `FUN_10010120` background → `FUN_10018b20(1)` (layers 2–5) → if param_2: `FUN_10043ba0` →
   `FUN_10018b20(2)` (layers 6–15). (Layer numbers from the `FUN_10018b20` dump; HIGH.)
3. **Limiter** (only if byte pref 10):
```
10030ce4 li r3,0xa ; bl 0x10004ef0 ; rlwinm. r0,r3,... ; beq 0x10030d28     ; pref 10 off -> skip
10030cf8 li r3,0x21 ; bl 0x10020250 ; fctiwz f0,f1                          ; FPS_Delay = 2
10030d08 lwz r0,0x1c(r29) ; ... ; add r28,r0,r3                              ; target = lastPresent + 2
10030d18 bl 0x100497f0                                                       ; TickCount()
10030d20 cmplw r3,r28 ; 10030d24 blt 0x10030cf8                              ; spin while now < target (unsigned)
10030d28 bl 0x100497f0 ; 10030d30 stw r3,0x1c(r29)                          ; lastPresent = TickCount()
```
   `FUN_100497f0` = `bl 0x100d456c` = the `TickCount` import glue (dump header
   `// ==== TickCount @ 100d456c ====`). The limiter is a busy-wait; there is no `WaitNextEvent`
   or VBL sync in it. `FPS_MaxRate` (32) is **not** the limiter constant — `FPS_Delay` (33) is.
4. Counters: `+0x08 += 1`, `+0x20 += 1` (`10030d34..10030d48`).
5. **Divider → tick flag for the next frame**:
```
10030d4c lwz r0,0x30(r29) ; cmpwi r0,0x0 ; bne 0x10030d6c
10030d58 li r0,0x1 ; stb r0,0x34(r29) ; lwz r0,0x2c(r29) ; stw r0,0x30(r29) ; b 0x10030d8c
10030d6c li r0,0x0 ; stb r0,0x34(r29) ; lwz r0,0x2c(r29) ; cmpwi r0,0x3e7 ; beq 0x10030d8c
10030d80 lwz r3,0x30(r29) ; subi r0,r3,0x1 ; stw r0,0x30(r29)
```
   With divider D (≠ 999) the next frames tick in the pattern 1, 0×D, 1, 0×D … = one tick per
   D+1 frames; D = 999 freezes the countdown (no tick ever again once it is non-zero). In 1.0.6
   D is always 0 (§3), so **every frame ticks**.
6. Present, only if param_3: `+4 == 1` → `FUN_1000beb0`, `+4 == 0` → `FUN_1000bc60`
   (`10030d94 lbz r0,0x4(r29) ; cmpwi r0,0x1 ; beq 0x10030dc0 → bl 0x1000beb0`).

### 2.4 After end frame (`FUN_10030570`, listing `10030570..100305d4`) [HIGH]
`FUN_100307c0` again (return value discarded, §2.5) → `FUN_10030870` (if paused: run the pause
screen `FUN_10022ef0(+4,0,0)`, which loops until Caps Lock is released — dump `do { if (bVar1 &&
!FUN_10049150(0x39)) goto …; } while (…)`, MED — then set +2 if it returns quit, clear the notice,
paused = 0) → if the tick flag just computed is set: FPS monitor `FUN_10030640`.
⚑ correction to the present labels: `FUN_1000beb0` reads LeftBorderWidth / VisibleGameWidth /
VisibleGameHeight and paints the border rects (dump `.glue::ForeColor(0x21)`, `PaintRect`); it is
the **game-screen** present, chosen by controller +4, not an "interlaced" present. Interlacing
is pref byte 5 and is consumed elsewhere (§5). [HIGH for the branch on +4 and the reader set of
pref 5; MED for the "game layout" name]

### 2.5 Esc (`FUN_100307c0 @ 100307c0`) [HIGH — listing `100307c0..10030864`]
Esc up → counter +0x14 = 0. Esc down: byte pref 8 == 0 → quit at once; else `+0x14 += 1` and quit
when `+0x14 > PermFloat 32 (=30)` (`10030834 cmpw r0,r3 ; ble` → `li r31,0x1`). It is called
**twice per frame** (begin frame, where the result is the quit flag, and the end-frame wrapper,
where it is discarded), so with pref 8 on the counter reaches 31 at the begin-frame call of the
**16th** held frame (counts 1,2 | 3,4 | … | 29,30 | 31) ≈ 0.53 s at 30.07 fps, not 30 frames.
⚑ conflict with engine-loop.md §4 ("held for more than PermFloat 32 (=30) consecutive frames").

### 2.6 FPS monitor `FUN_10030640 @ 10030640` / init `FUN_100305e0` [HIGH — listing]
Init: +0x18 = TickCount, +0x20 = +0x24 = PermFloat 32 (30), +0x28 = 0. Per call (tick frames
only): if `TickCount > +0x18 + 60` (`10030680 cmplw r3,r0 ; ble` exit — strictly more than 60
ticks): +0x24 = +0x20 (published **before** the pref-10 test); if pref 10 (limiter): clamp +0x20 to 30; if `+0x20 < 30`
(`100306b8 cmpw ; bge` skip): `+0x28 += 1`, and when `+0x28 == PermFloat 34 (=10)`: +0x28 = 0 and,
if +3 and byte pref 6 and not byte pref 5 → byte pref 5 = 1 + message GameString 17
"Interlacing ON". Then +0x20 = 0, +0x18 = TickCount. The deficit counter is **never reset by a
good window** — it counts deficient windows cumulatively, not consecutively. On a fast machine
with the limiter, frames land every 2 ticks, so the first check that passes is at +62 ticks with
31 frames counted → the FPS counter shows **31**, and 31 ≥ 30 is not deficient. ⚑ corrected (review wave 2, 2026-10-03) #I1:
was "The monitor does nothing at all when the limiter is off (whole body gated by pref 10)".
The count is published before the pref-10 test — `10030688 lwz r0,0x20(r30); 1003068c li
r3,0xa; 10030690 stw r0,0x24(r30)` precedes `10030694 bl 0x10004ef0` (pref 10) — and the
`100306a0 beq 0x1003075c` on pref 10 off skips only the clamp / deficit / auto-interlace block,
landing on the window reset (`1003075c li r0,0; stw r0,0x20(r30)`, `1003076c stw r3,0x18(r30)` =
TickCount). So with the limiter off the FPS readout still updates every > 60-tick window; only the
deficiency logic is gated. (Pref 10 cannot be cleared in a stock build, §6.) [HIGH arithmetic;
the "31" is MED — it assumes the present stamp falls on the tick boundary, see §4]

## 3. INDEX #12 — the speed divider is never set: the game always runs at "Normal"

- Stores to `+0x2c` inside the controller methods: only `10030794 stw r4,0x2c(r3)` (r4 = 0,
  `FUN_10030790`) and `10030e4c stw r0,0x2c(r31)` (r0 = 0, `FUN_10030df0`). [HIGH — listing of
  every method in the range except the trivial `FUN_100301d0/10030350/10030900`, whose dumps hold
  no stores to +0x2c]
- The controller's address never leaves the controller API: in `FUN_100051a0` every
  `addi rX,r1,0xc0…0xf7` is an `r3` argument to `0x10030190`, `0x10030210`, `0x100301d0`,
  `0x10030360`, `0x10007170`, `0x10030570`, `0x100302b0` (listing lines `10005690…10005c90`);
  `FUN_10007170` uses it only as `or r3,r24,r24 ; bl 0x100302e0`; in `FUN_1002e310` every
  `addi r3,r1,0x8c` feeds `0x10030190/0210/0350/0360/0570/0900/02b0/01d0`. [HIGH]
- No code builds 999: a raw scan of the code image for `li rX,999` finds none; the only `999`
  is the `cmpwi r0,0x3e7` at `10030d78`; the data image holds no aligned or unaligned big-endian
  999. No transition vector in the data section points at any controller method or at
  `FUN_10020260` (scan for the code addresses as data words). [HIGH — `python3` scan over
  `$W/mem/10000000.bin` and `100de330.bin`]
- GameStrings 24–30 ("Game Speed …") have **no consumer**: every `bl 0x10020260` in the code image
  has an immediate `r3` (list: 0x4, 0x5, 0x7, 0x9–0x10, 0x11, 0x12, 0x15–0x17, 0x21–0x23, and 0 at
  `10030480`), and only `FUN_1001fe60`/`FUN_10020260` load the string-list base `-0x712c(r2)`.
  Strings 19/20 ("Auto Interlacing ON/OFF") are orphaned the same way. [HIGH]
- The configuration dialog has no speed item (DITL 190, §6) and no console command names a speed.

**Conclusion:** in 1.0.6 the divider is a vestigial debug feature — `+0x2c` is 0 for the whole
session, `+0x30` stays 0, and the tick flag is 1 on every frame. Ticks per frame = **exactly 1**;
the "Half … Stopped" labels (which would have been D = 1, 3, 7, 15, 31, 999 by the arithmetic of
§2.3, if anything had written them — not recoverable from this build) are unreachable. [HIGH]

## 4. Ticks per second, slow machines, no catch-up

TickCount = the Mac 60.15 Hz tick (brief value). One logic tick per presented frame (§3).
- **Limiter on (default):** a frame is presented at the first TickCount ≥ previous stamp + 2.
  Let W be one frame's work (begin → logic → draw → render) in Mac ticks. If W < 2, the spin
  lands on a tick boundary every time → period exactly 2 ticks = 33.25 ms → **30.07 logic ticks/s**
  (60.15/2). If W > 2 the spin exits at once and the period is W (the stamp is the integer tick,
  so the next target is already passed) → **60.15/W ticks/s**: the whole game, music aside, runs in
  slow motion. [HIGH for the mechanism; MED for the W-model, which ignores the sub-tick phase of
  the stamp]
- **No frame skipping and no catch-up:** the only gate on `FUN_10006b50` is the tick flag
  (always 1); the game loop never runs more than one update per pass and never measures elapsed
  time (it calls TickCount only once, for `srand`). [HIGH — game-loop listing §2.2]
- **Pause / modal screens:** the pause screen and fades block inside the frame; logic does not
  advance and nothing is made up afterwards (the next limiter target is already in the past, so
  one frame goes out unpaced). [HIGH for no tick during the block; MED for the fade timing below]
- **Limiter off** (only possible by editing the prefs file, §6): period = W, so a fast machine
  plays faster than designed; the FPS monitor's deficit/auto-interlace logic is disabled, but the
  counter still publishes (§2.6). ⚑ corrected (review wave 2, 2026-10-03) #I1: was "the FPS monitor is disabled". [HIGH]
- Gameplay code never reads the clock: the 18 callers of `FUN_100497f0` are boot, menus, scores,
  credits, fades (`FUN_1000b9a0`/`FUN_1000ba70`), music fade `FUN_10048120`, the game loop's seed,
  the three controller functions, and (⚑ corrected (review wave 2, 2026-10-03) #M8, previously
  unlisted) `FUN_1000d6d0`, `FUN_10023040`, `FUN_10025330` — text/progress-line timing
  (callers.txt). The conclusion stands. All gameplay durations are in ticks.
  [HIGH for the caller list; MED for "gameplay" = none of those]
- Level start: game time is reset to 0 and `game[0x38]` (appeared) cleared by `FUN_100064d0`
  (dump lines 41/44). Ticks 0 and 1 run with no present (`param_3` = 0); on tick 2 (PermFloat
  18) the music starts, `FUN_1000ba70(…,1)` fades in (9 blend steps 0,4,…,32, each ≥ 1 Mac tick,
  ≈ 0.15 s, blocking), and presenting begins. [HIGH for the gate; MED for the fade step count]

## 5. Interlacing (byte pref 5) and auto-interlacing (byte pref 6)

- **Readers of pref 5** (all `FUN_10004ef0`/`FUN_10004ab0` call sites with 5, plus a raw scan for
  direct `lbz/stb …,0x9(prefs)` that found only the defaults writer): `FUN_10010120` (background
  blit flag), `FUN_100064d0` (suspend at level start), `FUN_100051a0` (restore at tick 2),
  `FUN_10010fc0`/`FUN_10011590` (dialog), `FUN_10030910` (F6), `FUN_10030640` (auto). No logic
  function reads it → **interlacing has no effect on the simulation.** [HIGH]
- **Rendering effect:** `FUN_10010120` passes pref 5 as the last argument of `FUN_10009fd0`
  (terrain picture `+0x6c` → work buffer `+0x68`). Off: two identical `CopyBits` of the whole
  visible terrain (dump; listing not checked). On: `FUN_100450e0` doubles both rowBytes, halves
  the rectangles, offsets the start by one row when the parity word `*param_5` (picture `+0x2c`)
  is odd, does one `CopyBits`, then `*param_5 ^= 1` — i.e. **only every other terrain row is
  refreshed per frame, alternating fields**; the other half keeps the previous frame's composited
  pixels (moving sprites leave one-frame combing). Sprites, HUD and the present are unaffected.
  [MED — decompile arithmetic read; the field semantics are the natural reading]
- Level start (`FUN_100064d0`): if pref 5 is on, save it in game `+0xf`, force pref 5 = 0, draw
  the full background once; the game loop restores pref 5 = 1 at the appear tick
  (`1000599c li r3,0x5 ; li r4,0x1 ; bl 0x10004ab0`, then `stb 0,0xf(r29)`). [HIGH]
- F6 (`FUN_10030910`): edge-triggered toggle of pref 5 with message 17/18 and sound
  `PermSoundID 7`; works in-game only (begin frame). [HIGH]
- Auto-interlace (pref 6): §2.6. Pref 6 is written only by `FUN_100050f0` (= 0); there is no
  dialog item, key or console command for it (its strings 19/20 are orphaned, §3) → **in a stock
  install auto-interlace never fires.** [HIGH for the writer set]

## 6. Pref bytes that drive timing (INDEX #13 part) and the dialog labels

Fresh prefs: `FUN_10004540` → `FUN_10004f80` fails (no file; and no `pref` tag exists in any pak —
`list_paks.py … --all | grep -ic pref` = 0) → zero, version 0x2714, `FUN_10004ae0`,
`FUN_10004f20(1)`. Listings `10004f38..10004f60` and `100050f8..10005194`:
| pref | default | set by | UI | effect |
|---|---|---|---|---|
| byte 2 | 0 → 1 after first dialog | boot | — | config dialog shown at first launch |
| byte 4 | 1 | `FUN_100050f0` (`stb r3,0x8`) | DITL item 8 **"Full Screen (Takes Effect on Relaunch)"** | display mode |
| byte 5 | 0 | `FUN_100050f0` (`stb r29,0x9`) | item 9 **"Interlacing  (Faster but lower quality)"**, F6 | §5 |
| byte 6 | 0 | `FUN_100050f0` (`stb r29,0xa`) | none | auto-interlace §2.6 |
| byte 7 | 0 | `FUN_100050f0` (`stb r29,0xb`) | item 10 **"Bypass System Volume"** (enables slider 12) | sound |
| byte 8 | 0 | `FUN_10004f20` + `FUN_100050f0` | item 17 **"ESC Key Delay  (Requires key to be held down)"** | §2.5 |
| byte 9 | 0 | `FUN_10004f20` (`stb r3,0xd`) | console `FPS` | FPS counter |
| byte 10 | **1** | `FUN_10004f20` (`stb r0,0xe`) | none reachable (below) | limiter |
| int 0 | 50 | `FUN_100050f0` | item 12 slider, label 13 = "%i%%" — **"Sound Volume:"** | — |
| int 1 | 100 | `FUN_100050f0` | item 15 slider, label 16 — **"Music Volume:"** | — |
| int 2 | 50 | `FUN_100050f0` (`stw r5,0x70`) | none found | not resolved |
| int 3 | 1 | `FUN_10004f20` (`stw r0,0x74`) | — | highest sector (engine-loop §10) |
The dialog "Defaults" button (item 3) runs `FUN_10004f20(0)` = `FUN_100050f0` only, so it
never touches bytes 9/10. [HIGH — listings + DITL]
DITL 190 "Game - Preferences" (⚑ corrected (review wave 2, 2026-10-03) #M6: that is the resource
*name* of DITL 190 and DLOG 190; the DLOG 190 window-title pstring is empty) (parsed from the binary's resource fork with a small map parser;
`xattr` `com.apple.ResourceFork`, 151602 B): 1 Save, 2 Cancel, 3 Defaults, 4 Revert, 5–7 group
boxes (CNTL 200 "Video", 201 "Audio", 202 "Controls"), items 8–17 as above, 18 "Set Controls…"
(→ `ISpConfigure` `FUN_1004ae00`), 19 "Set Gamepad Controls..." (hidden by
`HideDialogItem(…,0x13)`), 20 "(Hold down Option during launch to display this dialog)". No
speed, FPS or limiter item. [HIGH — resource bytes; item→pref mapping from `FUN_10010fc0` switch]
**Console:** `FUN_1002d080(name, help, handler, p4, p5, p6)` skips registration when `p5 ≠ 0`
(`1002d0a4 rlwinm. r0,r7,… ; 1002d0ac bne 0x1002d174`). `FPS` is registered with r7 = 0
(`10005274 li r7,0x0`); its handler at `0x10007eb0` toggles byte pref 9
(`10007ebc li r3,0x9 ; bl 0x10004ef0 ; cntlzw ; … bl 0x10004ab0`). `LIMITFPS` (and `SHADOWS`,
`SHADOW`, `PLAYER`) pass r7 = 1 (`10005294 li r7,0x1`) and are **not registered**; its handler
at `0x10007f50` would toggle pref 10. So the limiter is ON in every stock install and cannot be
switched off without editing the prefs file. [HIGH — listings]
Default key table (prefs `+0x14b8…+0x14ec`, 14 ints of Mac virtual key codes, `1000515c..10005194`):
0x7E ↑, 0x7B ←, 0x7C →, 0x7D ↓, 0x37 Command, 0x3A Option, 0x31 Space | 0x5B kp8, 0x56 kp4,
0x58 kp6, 0x57 kp5, 0x77 End, 0x75 Fwd-Delete, 0x79 Page Down — two players × 7 controls. Only the
prefs load/save copies (`100049ec…`, `10004e2c…`) touch it; no game-side consumer found (likely the
OS X keyboard path of INDEX #14). [HIGH values; LOW for the per-slot meaning]

## 7. Film replay is per tick (engine-loop.md §7)

Chain: game loop tick → `FUN_10006b50` → `FUN_10028170` (per player) → `FUN_1002a3a0` (callers.txt
one-to-one), which acts only when player byte `+0xc6 == 4`: zero the 7 input bytes at
`player+0x1fc`; film playback → `FUN_100097a0` (read one byte, cursor++); else read ISp
(`FUN_1004ab50`) and record with `FUN_10009830` (cap `cmplwi r7,0x4e20 ; bge` = 20000). So the
film holds **one input byte per logic tick of a live player**, and in 1.0.6 tick ≡ frame (§3).
[HIGH — dump + listings `10009830..`, `100097a0..`]
- Playback guard `100097bc cmpw r4,r0 ; 100097c0 bgtlr` returns only when cursor **>** count, so
  cursor == count still reads one byte past the recording (zero in all four demos — checked:
  `byte[0x1c+count] = 0`, no non-zero byte after) and the replay runs count+1 input ticks. [HIGH]
- End test `FUN_10009750 @ 10009750` (listing `xor ; srawi ; and ; subf ; rlwinm …,0x1,0x1f,0x1f`)
  is the branchless **signed** **cursor > count** for player 1 (evaluated: (4809,4809)→0,
  (4810,4809)→1), i.e. "film finished". ⚑ corrected (review wave 2, 2026-10-03) #M1: was "unsigned"; the review's M1 also
  called it unsigned, but evaluating the exact sequence (`10009758 xor r0,r4,r0; 1000975c srawi
  r3,r0,0x1; 10009760 and r0,r0,r4; 10009764 subf r0,r0,r3; 10009768 rlwinm r3,r0,0x1,0x1f,0x1f`,
  r4 = cursor `+0x4`, r0 = count `+0x24`) over 200 000 random pairs and every sign-boundary pair
  matches signed `a > b` only — (0x80000000, 1) → 0, (0xFFFFFFFF, 0) → 0 (unsigned would give 1).
  No difference for real counts (< 2³¹). loose-ends-session.md §7 ("signed") was right; the game loop stops the session when it returns 1 or the
  mouse button is down. ⚑ corrected: function-roles.md calls it "film still playing" (the
  polarity is inverted). [HIGH]
- **Replica consequence:** replay determinism needs tick-exact sequencing (one update, one input
  byte, same RNG draw order per tick) — wall-clock timing is irrelevant to correctness. Matching
  the original *feel* needs the 2-Mac-tick period (33.25 ms, 30.07 Hz) with exactly one update
  per presented frame and no catch-up. A replica that ran a fixed-step accumulator at 30.07 Hz
  under a 60 Hz display is replay-safe but would present some ticks twice. [MED — inference from
  the above]

## Worked example — default prefs, fast machine (W < 2 Mac ticks), 10 seconds of play

10 s × 60.15 = 601.5 Mac ticks; the limiter (pref 10 = 1, FPS_Delay = 2) presents a frame every 2
ticks → 300 frames (300.75 on average) → divider 0 → tick flag 1 on every frame → **300 logic
ticks**, game time +300, the map scrolls 300 px if not paused (1 px/tick, engine-loop §5), and a
recording grows by 300 bytes per live player. The FPS counter (if `FPS` was typed in the console)
shows 31 (§2.6). The 20000-tick film cap = 20000 / 30.075 ≈ 665 s ≈ 11 min 5 s; demo 01's 4809
ticks ≈ 160 s, demo 03's 10058 ticks ≈ 334 s.
One frame k (stamp S = TickCount at frame k−1's present):
1. `FUN_10030360`: music service, layer queues cleared, console/messages (aging per frame),
   `-`/`=`/F6 latches, GetMouse, Caps Lock (not pressed → paused 0), Esc (not pressed → +0x14 = 0),
   tick flag = 1 → input cleared + ISp read; returns +8 = k−1 → game `+0x30`.
2. Tick: (game time ≠ 2, so no appear step) `FUN_10006b50` world update (input read again),
   `FUN_10007170` level-complete check, game time `t → t+1`.
3. `FUN_10007070` queues the world's sprites.
4. `FUN_10030bc0(ctrl,1,1)`: messages, (FPS text off), console, layers 0–1, background (full
   copy, pref 5 = 0), layers 2–5, `FUN_10043ba0`, layers 6–15; spin until TickCount ≥ S+2; stamp
   S' = S+2; +8 = k, +0x20 += 1; +0x30 == 0 → tick flag = 1, +0x30 = +0x2c = 0; +4 == 1 →
   `FUN_1000beb0` presents.
5. `FUN_100307c0` (discarded), `FUN_10030870` (not paused), tick flag 1 → `FUN_10030640`: if
   TickCount > window start + 60, publish the count, reset.
Next frame starts at ≈ S+2 with nothing to catch up. On a machine with W = 3 Mac ticks the same
10 s gives 601.5/3 ≈ 200 ticks (game at two-thirds speed); auto-interlace would not help because
pref 6 is 0.

## NOT RESOLVED (this file)
1. Int pref 2 (default 50, `prefs+0x70`): no dialog item, no reader found by the accessor
   (`FUN_10004f00(2)` not searched exhaustively by listing). Settle: raw scan for
   `lwz rX,0x70(prefs)` and `li r3,2 ; bl 0x10004f00`.
2. Per-slot meaning of the default key table (`+0x14b8…`, 2 × 7 codes) and its consumer —
   needs the OS X keyboard path (INDEX #14) or `M_ControlsConfigure.cc` code.
3. ~~`FUN_10018b20(0)` flushes layers 0–1 **before** the background blit: whether
   `FUN_1001a650(0/1)` draws into the terrain picture or into the work buffer (layer 1 = shadows,
   engine-loop §5) — read `FUN_1001a650`.~~ → ⚑ corrected (review wave 2, 2026-10-03) #C3 #S: sprite-geometry-draw.md §6
   step 1 — layers 0/1 are terrain **stamps** (layer 1 = the stamp sprite, layer 0 its shadow),
   drawn into the terrain buffer by flag 8; entity shadows are on layers 2/4/6. "Layer 1 =
   shadows" (engine-loop §5) was wrong.
4. The non-interlaced background path issues two identical `CopyBits` (dump of `FUN_10009fd0`);
   listing not checked; purpose unknown (timing ballast or a bug).
5. Exact TickCount rate on the target OS (60.15 Hz is the brief's value); Ben's machine/emulator
   would decide whether the original felt like 30.07 or 30.00 ticks/s.
6. `FUN_1000beb0` internals (which buffers it copies, whether it waits for VBL); not read beyond
   the border painting.

## Role-table rows (for merge)
| `FUN_10030190` | frame ctrl | construct frame controller (= zero all fields) | MED | dump; callers `FUN_100051a0`, `FUN_1002e310` — ⚑ label audit (review wave 2): was HIGH on dump |
| `FUN_10030df0` | frame ctrl | zero controller fields +0…+0x34 (0x38 B) | HIGH | listing `10030e0c..10030e54` |
| `FUN_100301d0` | frame ctrl | controller destructor (delete if flag > 0) | MED | dump; called with −1 |
| `⚑ corrected` `FUN_10030210` | frame ctrl | start session: zero; +1 film, +4 game-layout, +3 auto-interlace allowed; clear layer queues; FPS monitor init; divider reset; FlushEvents | HIGH | listing — was "frame controller start session" MED |
| `FUN_100302b0` | frame ctrl | end session (FlushEvents) | MED | dump |
| `FUN_100302e0` | frame ctrl | level-transition reset (layers, messages, FPS monitor, divider; keeps limiter stamp) | MED | dump; caller `FUN_10007170` listing — ⚑ label audit (review wave 2): was HIGH on the dump (only the caller is listing-read) |
| `FUN_10030350` | frame ctrl | get frames-presented counter (+8) | MED | dump — ⚑ label audit (review wave 2): was HIGH on dump |
| `FUN_10030900` | frame ctrl | get paused flag (+0) | MED | dump; caller `FUN_1002e310` |
| `⚑ corrected` `FUN_10030360` | frame ctrl | begin frame: music, clear layers, console, message aging, volume/F6, mouse, Caps-Lock pause (not in films), Esc, input poll on tick frames; returns frame count | HIGH | listing `100304e8..` — was "keys, console, pause, quit" |
| `⚑ corrected` `FUN_10030570` | frame ctrl | end-frame wrapper: end frame (r4/r5 passed through), Esc counter (discarded), pause screen, FPS monitor on tick frames | HIGH | listing `10030570..100305d4` |
| `FUN_10030bc0` | frame ctrl | end frame: messages, FPS text (pref 9), console, layers 0–1/bg/2–5/`FUN_10043ba0`/6–15, limiter spin to lastPresent+FPS_Delay (pref 10), counters, divider→tick flag, present by +4 | HIGH | listing `10030bc0..10030de8` |
| `FUN_100305e0` | frame ctrl | FPS monitor init (+0x18 = now, +0x20 = +0x24 = 30, +0x28 = 0) | HIGH | listing |
| `⚑ corrected` `FUN_10030640` | frame ctrl | FPS monitor: per >60-tick window publish count **always** (before the pref-10 test); if limiter on, cumulative deficient windows (count < 30) → every 10th sets pref 5 if +3 and pref 6 | HIGH | listing `10030688..10030694`, `100306a0 beq 0x1003075c` — was MED "FPS monitor + auto interlace"; ⚑ corrected (review wave 2, 2026-10-03) #I1: the publish is not gated |
| `FUN_10030790` | frame ctrl | reset divider (+0x2c = +0x30 = 0, tick = 1) — the only divider writer besides the constructor | HIGH | listing |
| `⚑ corrected` `FUN_100307c0` | frame ctrl | Esc: quit at once, or (pref 8 "ESC Key Delay") when hold counter > 30; called twice per frame → 16 frames | HIGH | listing — was "hold > 30 frames if pref 8" |
| `FUN_10030870` | frame ctrl | if paused: blocking pause screen `FUN_10022ef0`, quit flag, clear notice | MED | dump |
| `FUN_100189f0` |  | clear the 16 render-layer queue heads (`*(r2-0x7198)`) | MED | listing `100189f0..10018a38`; callers begin frame, session start, level start |
| `FUN_10018b20` |  | flush render layers: 0 → 0–1, 1 → 2–5, 2 → 6–15 (`FUN_1001a650(n)`) | HIGH | dump; caller `FUN_10030bc0`; ⚑ label audit (review wave 2): HIGH kept on the raw listing `10018b54..10018b60` (0, 1), `10018b68..10018b84` (2–5), `10018b8c..10018bd8` (6–15) (`$W/disasm-review2.txt`) |
| `⚑ corrected` `FUN_1000beb0` |  | present **game screen** (borders, game area, score bar) — chosen by controller +4, not by interlacing | MED | dump (border PaintRects, F54/F55/F59); was "present frame (interlaced)" |
| `⚑ corrected` `FUN_1000bc60` |  | present full screen (640×480; level select, fades) | MED | dump F52/F53; was "present frame" |
| `FUN_10010120` |  | blit visible terrain (x offset+32) into the work buffer; interlaced if pref 5 | HIGH | dump; caller `FUN_10030bc0`; ⚑ label audit (review wave 2): HIGH kept on the listing (`$W/disasm-review2.txt`) `100101cc li r3,0x5; bl 0x10004ef0; 100101e4 or r7,r3,r3; 100101f8 bl 0x10009fd0` (pref 5 = 5th argument of the copy) and level-scroll-objects.md §9; the every-other-row behaviour inside `FUN_10009fd0`/`FUN_100450e0` stays MED (§5) |
| `FUN_100450e0` |  | interlaced CopyBits: every other row, field parity at picture +0x2c toggled per call | MED | dump |
| `FUN_10009fd0` |  | copy picture → picture (CopyBits ×2, or interlaced `FUN_100450e0`) | MED | dump |
| `FUN_100050f0` | U_Prefs.cc (span) | prefs defaults: byte 4=1, 5/6/7/8=0, int 0/1/2 = 50/100/50, key table 14 codes at +0x14b8 | HIGH | listing `100050f0..1000519c` |
| `FUN_10004f20` | U_Prefs.cc (span) | prefs reset: if arg, bytes 0–3/8/9/11 = 0, byte 10 (limiter) = 1, int 3 = 1; then `FUN_100050f0` | HIGH | listing |
| `FUN_10010fc0` | M_Configuration.cc | preferences dialog DLOG/DITL 190: items 8/9/10/17 toggle byte prefs 4/5/7/8, sliders 12/15 → int prefs 0/1, 18 ISpConfigure, 3 Defaults, 4 Revert, 2 Cancel restores copy | HIGH | dump + DITL 190 resource |
| `FUN_10011590` | M_Configuration.cc (span) | load dialog controls from prefs (items 8/9/10/17, sliders 12/15 + "%i%%" labels 13/16; slider 12 enabled by pref 7) | HIGH | dump + DITL |
| `FUN_10007eb0` (no Ghidra function) |  | console `FPS` handler: toggle byte pref 9, message | HIGH | range listing `10007eb0..10007f44` |
| `FUN_10007f50` (no Ghidra function) |  | console `LIMITFPS` handler: toggle byte pref 10 — command never registered (p5 = 1) | HIGH | range listing `10007f50..10007fe4`, `10005294` |
| `FUN_1002d080` | G_Console.cc | register console command (skipped when p5 ≠ 0) | HIGH | listing `1002d0a4..1002d0ac` |
| `⚑ corrected` `FUN_10009750` |  | film **finished**: P1 cursor > recorded count (branchless **signed** compare) | HIGH | listing `10009750..1000976c`; was "film still playing"; ⚑ corrected (review wave 2, 2026-10-03) #M1: was "unsigned" (§7) |
| `FUN_10022ef0` |  | pause screen (blocking until Caps Lock released / menu) | MED | dump; caller `FUN_10030870` |
| `FUN_1000ba70` |  | fade in/out over 9 steps (blend 0..32 by 4), ≥1 Mac tick each, blocking | MED | dump |
Touched but **not read**: `FUN_1002dea0` (messages draw, LOW by perm F27), `FUN_1002d410`
(console draw, LOW; its draw/visible flag `DAT_100e01f0` is described in messages-notices-console.md
§5.1), `FUN_10043ba0` (⚑ corrected (review wave 2, 2026-10-03) #C5: = the particle draw, HIGH in
particles-debris-blur.md §2.9; was LOW "draws something sized to the game area"), `FUN_1001a650`
(layer flush, LOW), `FUN_1002d1a0/1002d230/1002d190` (console open/update/is-open, LOW),
`FUN_1002db50`, `FUN_1002d040` (console/message reset, LOW), `FUN_10047990/10047a30` (volume
down/up returning %, LOW), `FUN_1000bd80` (present used by fades, not read), `FUN_10048220`.

## INDEX updates (for merge)
- **#12 closed** → timing-frame.md §3: no code writes the divider; the game always runs at
  Normal (1 tick per frame); "Game Speed" strings 24–30 (and 19/20) have no consumer.
- **#13 narrowed** → timing-frame.md §6: DITL 190 labels — byte pref 4 "Full Screen (Takes Effect
  on Relaunch)", 5 "Interlacing (Faster but lower quality)", 7 "Bypass System Volume", 8 "ESC Key
  Delay (Requires key to be held down)"; int prefs 0/1 = Sound/Music Volume (defaults 50/100);
  `FUN_100050f0` defaults read (key table at +0x14b8). Still open: int pref 2 (=50) and the rest of
  the ≈0x1000-byte block.
- **#14 narrowed** → §6: default key codes (2 × 7) written by `FUN_100050f0`; consumer not found.
- New ⚑ conflicts for engine-loop.md §4: (a) Esc-hold is 16 frames (counter bumped twice per
  frame), not 30; (b) controller +4 selects the game-screen present, it is not the interlace
  flag (`FUN_1000beb0` is not an "interlaced" present); (c) the limiter constant is `FPS_Delay`
  (idx 33); `FPS_MaxRate` (idx 32) is the monitor/Esc threshold; (d) the limiter cannot be
  toggled in a stock build (`LIMITFPS` unregistered) and auto-interlace has no UI.
  For function-roles.md: `FUN_10009750` polarity (finished, not playing).
