# Deimos Rising 1.0.6 — listing micro-wave (2026-10-06)

Scope: the optional micro-wave of `CRITIC-wave3-2026-10-04.md` §6 / `handoff-2026-10-04-deimos-re-wave34.md`
"Next session" item 2. Three parts. (a) Role rows for the code blocks that have no Ghidra function: the
prefs slider action procs `0x10011750` / `0x100118e0` and the AppleEvent handlers `0x10049c20–0x10049c50`.
(b) Listing addresses for the 13 replay-critical MED rows of critic §2. (c) INDEX #40, #47, #54, #60.
OUT of scope: INDEX #13 (`+0x70` load scan) and #59 (remaining clip builders). The critic named both, but
this brief did not assign them. Debug console handler bodies stay unread (ruling).

Evidence: new raw listings `$W/disasm-micro.txt` (20 functions), `$W/disasm-micro2.txt` (20) and
`$W/disasm-micro3.txt` (`FUN_10028170`, `FUN_1002a3a0`, `FUN_100069b0`), from project copy
`$W/work-micro`. The no-function blocks come from the critic's `$W/critic3-work/gaps.txt`. Constants were
read from `$W/mem/*.bin` with inline Python (`struct.unpack('>…')`, TOC r2 = `0x100e6330`). Data values
come from the decoded `$W/data/Game/{unde,flli}`. Labels follow `brief.md`.

---

## 1. Prefs-dialog slider action procs `0x10011750`, `0x100118e0` [HIGH]

**Installation.** In `FUN_10010fc0` (listing `10011190..10011220`), for each slider:
- `NewRoutineDescriptor(TV, procInfo 0x2c0, 1)` (`1001119c`, `100111e8` → glue `0x100d37a4`).
- `GetDialogItemAsControl(dlg, item)`, item 0x0C then 0x0F (`100111b4`, `10011200`).
- `SetControlReference(ctl, dlg)` (`100111c4`, `10011210`).
- `SetControlAction(ctl, upp)` (`100111d4`, `10011220`).

TVs: `r2−0x78ec` → `0x100e08f0` → **`0x10011750`** goes on item 12 (Sound Volume, int pref 0).
`r2−0x78f0` → `0x100e08e8` → **`0x100118e0`** goes on item 15 (Music Volume, int pref 1). The item↔pref
mapping is from sound-music.md §3 table rows `+0x68`/`+0x6C`.

**Body** (the two procs are identical except for the label item). Arguments are `(ControlRef r3,
part r4)`.
```
10011774 bl GetControlValue           ; v
1001177c extsh r29,r28 ; cmpwi 0x16   ; part switch
part 20 (0x14, up arrow):   1001179c..100117cc  GetControlMinimum; if v > min → d = −1
part 21 (0x15, down arrow): 100117d4..100117f0  GetControlMaximum; if v < max → d = +1
part 22 (0x16, page up):    100117f8..10011814  if v > min → d = −10
part 23 (0x17, page down):  1001181c..10011838  if v < max → d = +10
1001183c extsh. r0,r28 ; beq          ; d ≠ 0 → SetControlValue(ctl, v + d)   (10011850)
10011858 cmpwi r29,0x81 ; beq relabel ; part 129 (indicator, live thumb) or d ≠ 0 → relabel
1001186c bl GetControlReference       ; dlg
1001187c bl GetControlValue           ; v' (re-read after the set, so Toolbox pinning applies)
10011894 bl 0x10055390                ; sprintf(buf, "%i%%", v')   fmt r2−0x1cc+0x21 = 0x100e6185
100118a4 li r4,0xd ; bl 0x10045980    ; set item 13 text + Draw1Control      (proc 2: item 0x10 = 16, 10011a34)
100118b4 bl 0x10045640                ; SetGWorld(dlg, NULL)
```
- The ±10 step is not clamped in the proc; `SetControlValue` pins to [min, max] (standard Control Manager
  behaviour). The label always shows the pinned value because of the re-read at `1001187c`.
- "Up" decrements and "down" increments, following the Mac scroll-bar part convention (for a horizontal
  bar, up = left arrow).
- These procs do **not** write the prefs. The value reaches int prefs 0/1 only through `FUN_10010fc0`
  cases 0x0C/0x0F (sound-music.md §3.3).

Replica: visual only (the live "%" label while a slider is held).

## 2. AppleEvent handlers `0x10049c20–0x10049c50` and installer `FUN_10049aa0` [HIGH]

`FUN_10049aa0` (listing `10049aa0..10049c14`, caller `FUN_10048330`) installs four handlers, each with
`NewRoutineDescriptor(TV, 0xfe0, 1)` and then `AEInstallEventHandler('aevt', id, upp, refcon 0,
isSysHandler false)` (glue `0x100d37bc`). Install order and TV resolution:

| id | install at | TV slot → TV | handler | body | returns |
|---|---|---|---|---|---|
| `oapp` | `10049ae4` | `r2−0x78b0` → `0x100e0a40` | `0x10049c40` | `li r3,0; blr` | noErr |
| `odoc` | `10049b38` | `r2−0x78b4` → `0x100e0a38` | `0x10049c20` | `li r3,0; blr` | noErr (documents ignored) |
| `quit` | `10049b8c` | `r2−0x78b8` → `0x100e0a30` | `0x10049c50` | `SetA5(refcon)` `10049c64`, **`bl 0x10022ed0`** `10049c70` (quit `b8` = 1: `10022ed0 li r0,1; stb r0,−0x6178(r2)` = `0x100e01b8`), `SetA5(old)` `10049c7c` | noErr (`10049c84`) |
| `pdoc` | `10049be0` | `r2−0x78bc` → `0x100e0a28` | `0x10049c30` | `li r3,−0x6ac; blr` | −1708 errAEEventNotHandled |

If any install fails (`extsh. r0,r3; beq` skip), `FUN_10000ed0` reports "error is_eq noErr" in
"M_Application.cpp" at lines 0x65c / 0x669 / 0x66d / 0x671 (strings at `*(r2−0x6d94)+0x85/+0xdb`).
`SetA5` is a no-op glue on PPC. Combined with critic §3 #48, a Quit AE only raises the quit flag. The
flag is acted on when the menu pump `FUN_10048f30` runs `AEProcessAppleEvent`; it is not pumped during
play.

---

## 3. Replay-critical MED rows → listing

### 3.1 Rule conditions #4/#5/#14–16: `FUN_100352f0`, `FUN_100353e0`, `FUN_100351f0` [HIGH]
All three walk the active group list `*(r2−0x6108)` = `0x100e0228` (spawn-and-waves.md §1.2). Each walk:
- outer count via `FUN_10000ce0`, then the iterator `FUN_10000e10`; the cursor seed is copied from
  `*(r2−0x6edc)`;
- for each group, its member list `group+0xb0`: count, then iterate;
- for each member, unit def `entity+0x94`.

- **`FUN_100351f0(unitID)`** (rule #14–16 count):
  - `10035208 subis r0,r24,0x6e6f; cmplwi 0x6e65; beq exit`: unit `none` → 0.
  - `1003529c lwz r3,0x94(r4); lwz r0,0x4(r3); cmpw r0,r24`: member's unit ID equals the argument.
  - `100352ac lwz r0,0xb0(r4); cmpwi r0,0; bgt skip`: spawn countdown ≤ 0.
  - `100352b8 addi r28,r28,1`: count it.
  - No deleted (`+0xcb`) or on-screen test.
  - Use in `FUN_10015550`:
    - #14 `10015874..10015888`: `count − range`, `cntlzw`: **count == range**.
    - #15 `10015894..100158b0`: branchless `count < range`, **signed**.
    - #16 `100158bc..100158d4`: `count > range`, **signed**.
    - range = `rule+0x84`. The #15/#16 idioms were evaluated in Python for count ∈ [−1, 3] × range ∈ [0, 3].
- **`FUN_100352f0()`** (rule #4):
  - `10035390 lbz r0,0x133(r3)`: unit `includeInAirAccuracyCount_BOOL`.
  - `cmplwi; beq next; li r28,1; b exit`: first hit → 1.
  - No spawn-countdown, deleted or on-screen test, so pending members count.
  - Rule use `10015754..10015764`: result = `!any`, rule true when no such entity exists.
- **`FUN_100353e0()`** (rule #5):
  - `10035480 lbz r0,0x134(r4)`: `includeInGroundAccuracyCount_BOOL`.
  - Then `1003548c bl 0x10016bd0` (on-screen, HIGH row) `rlwinm.; beq next`: needs both.
  - Rule use `1001576c..1001577c`.
  - Bonus: `10015784..100157ac` evaluates **`!#4 && !#5`** (`bne` short-circuit after `FUN_100352f0`).
    That is the "no destroyable air **and** ground" condition. Its rule number is not re-derived here;
    the case wiring is in bosses.md §3.1.

All three: caller `FUN_10015550` (listing above, `$W/disasm-bosses.txt`). Bosses.md §3.1 rows 4/5/14 move
MED → HIGH unchanged in meaning.

### 3.2 Heading → frame `FUN_10016230(entity, h)` [HIGH]
```
10016230 lwz r0,0xa8(r3) ; lwz r5,0x94(r3) ; mulli 0x5e0 ; addi 0x4e0   ; state block of current state
10016244 lwz r5,0x308(r6) ; cmpwi 0 ; bgt ; li r5,1   ; n = stateNumDirections, ≤0 → 1
10016254 li r0,0x168 ; divw r0,r0,r5                 ; step = 360 / n   (C integer division)
10016284..10016298 fsubs ; fdivs f2,f2,f1           ; q = (float)h / (float)step   SINGLE precision
1001629c fctiwz                                      ; k = trunc(q)  (toward zero)
100162b8 fsubs f2,f2,f1 ; fcmpo f2,f0 ; cror eq,gt,eq ; bne
100162c8 addi r3,r3,1                                ; if q − k ≥ 0.5 → k+1   (f0 = 0.5 = *(double*)(0x100d6ca4+0x10))
100162cc cmpwi r3,0 ; bge ; subi r3,r5,1             ; k < 0 → n−1
100162dc subi r0,r5,1 ; cmpw ; ble ; li r3,0         ; k > n−1 → 0
100162ec lwz r0,0x314(r6) ; mullw                    ; × stateFramesPerDirection
```
Constants: slot `r2−0x7208` → `0x100d6ca4` = {`4330000080000000`, 0.0, **0.5**} (code image).
Rounding: half-up for h ≥ 0. For h < 0 the fraction is ≤ 0, so it truncates toward zero. 360 is not
divisible by every n, so `step` truncates (e.g. n = 7 → 51). Callers: `FUN_100146f0`, `FUN_100172d0`,
`FUN_10035cd0` (callers.txt).

### 3.3 Power-up release state `FUN_10014670(entity, now)` [HIGH] — ⚑ refines the reading
```
100146c8 lwz r7,0x94(r3) ; lwz r0,0x14(r7) ; cmpw r6,r0 ; blt     ; s < numStates_INT (U+0x14)
10014688 addi r0,r5,0x835 ; lbzx r0,r7,r0 ; cmplwi ; beq next      ; U+0x4e0+s·0x5e0+0x355 = stateUseThisStateOnWeaponPowerupRelease
10014698 mulli r5,r6,0x5e0 ; addi r5,r5,0x97c                      ; U+0x97c+s·0x5e0 = stateName_STR of s
100146a0 or r6,r4,r4 ; li r4,0 ; bl 0x100146f0 ; b exit            ; change state BY NAME, now → +0xa4
```
The first flagged state is selected **by its name**. `FUN_100146f0` resolves names "last match wins",
so a unit with two states of the same name would enter the later one. Shipped data has no such case:
`bgpo`, `icpo`, `pbpo` and `rgpo` all flag state 2 `_Powerup Release, Dwindle & Del`, and none has a
duplicate name (script over `$W/data/Game/unde/*.txt`). No flagged state → nothing happens. Caller
`FUN_10034ce0` (`10034d98`, HIGH row).

### 3.4 Aux-weapon fire timing `FUN_1003bff0(handler, now)` [HIGH]
For every record of the aux list `handler+0x70` (the null list → 0, `1003c010`). The record layout is
{def +0, last +4, last2 +8, … count +0x10} (weapons-projectiles.md §2.2).
```
1003c054 lwz r4,0x0(r5) ; lwz r3,0x4(r5) ; lwz r0,0x1b0(r4) ; add ; cmpw r31,r0 ; ble skip   ; now > last + delayBetweenLaunches
1003c06c lbz r0,0x1ac(r4) ; li r3,1 ; bne fire                                            ; autoRepeat → fire
1003c07c lbz r0,0xa(r30) ; beq fire ; li r3,0                                              ; else only if fireAir was UP last tick
1003c094 lwz r3,0x10(r5) ; addi 1 ; stw 0x10(r5) ; stw r31,0x4(r5) ; stw r31,0x8(r5)        ; count+1, last = last2 = now
```
This is the same rule as the air shot `FUN_1003bf80`, applied to each aux weapon independently. Every
record that passes fires on that tick. Returns 1 if any fired. Caller `FUN_1003b3c0` (§2.3 step 5).

### 3.5 FLOAT key reader `FUN_1002c960(text, cursor*, key, float* dst)` [HIGH]
- `1002c994 bl 0x1002c550`: locate the key and its `<`…`>` value. Delimiters at `r2+0x42a0+0x7c/0x7e`
  = "<", ">". Returns the value pointer and its length.
- Not found → `FUN_1002ce60("Couldn't find KEY for a Float", key, *cursor)` (`1002ca10..1002ca1c`).
- Length ≤ 0 → `FUN_1002ce60("Invalid Floating Point Length (must be 1 or more characters)", …)`
  (`1002c9a4..1002c9b8`).
- Otherwise:
  - zero a 32-byte buffer (`1002c9c8`);
  - clamp length to 31 (`1002c9d4 cmplwi 0x1f; ble; li 0x1f`; unsigned compare);
  - copy (`1002c9f0` memcpy);
  - `sscanf(buf, "%f", dst)` (`1002ca04 bl 0x10057660`, fmt `0x100ea731`).
- The sscanf result is ignored, so malformed text leaves `dst` as MSL sscanf leaves it.
- On both error paths `dst` is untouched and the function returns normally.

Callers: `FUN_1002ba00`, `FUN_10039e70`, `FUN_1003fda0`, `FUN_10040920`. The bit-exact float value is
whatever MSL `%f` produces (MED for MSL internals).

### 3.6 Object reset `FUN_10012650(obj)` [HIGH]
Listing `10012650..10012748`. Every store, with constants read from the code image:

| off | value | listing |
|---|---|---|
| +0x00/+0x04, +0x10/+0x14 | 0.0 (x, y, vx, vy) | `10012674`, `10012680`, `1001268c`, `10012694` (slot `r2−0x7238` → `0x100d6770` = 0,0) |
| +0x0c | 0 | `1001269c` |
| +0x18 / +0x19 / +0x1a | 1 / 1 (air) / 0 | `100126ec`, `100126a4`, `100126f0` |
| +0x1c / +0x20 | `none` / 0 | `100126c4`, `100126cc` |
| +0x24..+0x30 | 0 ×4 (w′, h′, half w′, half h′) | `100126d4..100126e4` (slot `r2−0x723c` → `0x100d6780` = 0,0) |
| +0x34 / +0x35 / +0x36 / +0x37 / +0x38 | 1 / 0 / 0 / 1 / 1 | `10012710`, `10012714`, `100126ac`, `100126b4`, `100126bc` |
| +0x3c..+0x48 | clip {0, 0, 480, 416} | `10012718..10012724` (slot `r2−0x7244` → `0x100d6788` = `0 0 1e0 1a0`, code image, so no static-init writer) |
| +0x4c / +0x50 / +0x54 | `defa` / 0 / 0 | `10012728`, `100126e8`, `100126f4` |
| +0x58/+0x5c/+0x60 | 0.0 (tint cur/target/step) | `100126f8..10012700` |
| +0x68/+0x6c/+0x70 | 100.0 / 100.0 / 0.0 (visibility) | `10012704..1001270c` (slot `r2−0x7240` → `0x100d67a8` = {0.0, 100.0, 1.0}) |
| +0x74 | 0 (glow off) | `1001272c` |
| +0x84/+0x88/+0x8c | 1.0 / 1.0 / 0.0 (scale) | `10012730..10012738` |
| +0x90 | 0 | `1001273c` |

+0x64 (tint colour), +0x78/+0x7c/+0x80 (glow level/step/colour) are **not** reset. Callers
`FUN_100125d0`, `FUN_100142f0`. This agrees with sprite-geometry-draw.md §2.1 field by field.

### 3.7 Entity pool `FUN_100385d0` alloc / `FUN_10038810` free [HIGH]
Pool = `*(r2−0x6ee4)` = `*0x100df44c` = `0x101038a8` (bss). Layout: +0 free hint (−1 = none), +4 count
in use, slots of 12 bytes at +8: {u8 inUse +8, …, entity* +0x10}.
- **Alloc.**
  - `10038600 cmpwi r4,0x3e8; blt`: if count ≥ **1000** → log
    `"\nDEBUG: Reached the end of preallocated Entity list!  Num in use: %i"` (r4 = count, `1003860c`)
    and return **NULL**.
  - Hint ≠ −1 → use it (`1003879c`).
  - Else linear scan from slot 0. The loop is unrolled 10× and runs 100 times (`10038628 li r0,0x64;
    mtctr`, `10038638..10038778`), giving the first slot whose byte +8 is 0. None found →
    `FUN_10000f80("indexToUse not_eq kG_EG_NoEntityOwner", "G_EntityGroup.cc", 5230)` (`10038790`).
  - Then count+1 (`100387b4`), inUse = 1 (`100387c0`), entity = slot+0x10 (`100387c4`),
    **`FUN_100142f0(entity)`** (`100387cc`, field reset), `entity+0x148 = slot index` (`100387d4`),
    hint = −1 (`100387dc`).
- **Free** (`10038810..10038838`): slot `entity+0x148`: inUse = 0, count−1, **hint = that slot**.

Consequence: the next alloc reuses the most recently freed slot; otherwise it takes the lowest free
slot. This fixes object addresses only. Update order comes from the group lists, so it is replay-neutral
unless the replica iterates its pool. Callers `FUN_10035cd0` / `FUN_10036610`. Who fills the slot's
entity pointers (pre-allocation) was not read (MED for that).

### 3.8 Level-select flash stepper `FUN_1002fcc0()` [HIGH]
State `*(r2−0x6f7c)` = `0x1010332c` (bss): +0 mode (0 off / 1 accept / 2 fail), +2 u16, +4 alpha,
+8 scale (float), +0xc growing flag. Base scale `*(r2−0x6f90)` = `0x100d70dc` = 1.0f (code image).
```
1002fce4 lbz mode ; beq exit
1002fcf4 lwz r3,0x4 ; cmplwi 0x20 ; beq ; +1 ; cmplwi 0x20 ; ble ; =0x20     ; alpha → 32, +1/tick (unsigned)
1002fd38 mode 1: f31 = PermFloat 44 (0.18), f1 = PermFloat 45 (2.0)          ; LevSel_Acceptance_ScalingRate / MaxScale
1002fd58 mode 2: f31 = PermFloat 46 (0.25), f1 = PermFloat 47 (2.0)          ; LevSel_Failure_*
1002fd78 growing: scale += rate (fadds) ; fcmpo ; cror eq,gt,eq → ≥ max: scale = max, growing = 0
1002fdb4 else:    scale −= rate (fsubs) ; cror eq,lt,eq → ≤ 1.0: scale = 1.0
1002fde8 fcmpu scale,1.0 ; bne ; alpha == 32 → mode 0, +2 = 0x7fff, alpha 32, scale 1.0, growing 0
```
Values from `$W/data/Game/flli/Game[gafl].flli.txt` lines 45–48. Accept (float32): 6 ticks up
(1.9 → 2.08 → clamp 2.0), 6 down (0.92 → 1.0). Fail: exactly 4 + 4. The flash ends on the first tick
where both scale is back at 1.0 and alpha has reached 32, i.e. the alpha walk dominates. The
starter/initial values are set by the caller `FUN_1002e310` (not re-read here). Mode ≥ 3 would use
uninitialised f31/f1, but it is unreachable as far as read. Closes gameplay-leftovers NR 2 and front-end
NR 9 except for the initial alpha.

### 3.9 Player draw `FUN_100298c0(player)` [HIGH]
Only when life state `+0xc6 == 4` (`100298d4..100298dc`):
1. `FUN_1003bd00(player+0x240)`: the crosshair (`100298e4`).
2. Shadow-only pass: `+0x38 = 1, +0x37 = 0`, `FUN_10012f20` (`100298f0..10029900`).
3. Sprite-only pass: `+0x37 = 1, +0x38 = 0`, `FUN_10012f20` (`10029908..10029920`).
4. Restore `+0x38 = 1` (`1002992c`).
5. Coin-tally text if `+0xd8 ≠ 0` and `+0xe0 < 32` (unsigned, `10029930..10029944`):
   - `FUN_1000d130(30, fmt)`: text format 30;
   - `strcpy(fmt, player+0xec)`;
   - fmt `+0x114` (blend) = `+0xe0`, `+0x10d` = 1 (keep the game-area clip, critic C2), `+0x110` = 0
     (queued), `+0x10c` = 15 (layer);
   - fmt y (`+0x104`) += `+0x1f8`;
   - `FUN_1000d380` (`10029948..100299a0`).

The shadow and sprite are submitted as two separate draw-entry calls, so the shadow is queued before the
sprite. Caller `FUN_10007070`.

### 3.10 Load level by sector `FUN_10011fd0(sector, a, b)` [HIGH]
- `10011ff0 lbz r0,−0x61df(r2)`: editor/abort flag `0x100e0151` ≠ 0 → `FUN_10000f30("FALSE",
  "G_Level.cc", 388)`.
- `10012010`: list `sPriv_LevelInfoListPtr` (`0x100e0154`) NULL → `FUN_10000f80(…, 334)`.
- Walk the level-order list (`10012068..10012098`): node `+4 == sector` → tag = node `+0`. **First match**
  (`1001208c b`); default `none`.
- `none` → `FUN_10000f80("tagID not_eq kG_GameObject_ID_None", "G_Level.cc", 394)`
  (`1001209c..100120b4`).
- Then `FUN_100120f0(tag, a, b)` (`100120c8`).

Callers `FUN_100051a0`, `FUN_100064d0`, `FUN_1002efb0`. Whether the two `FUN_10000f80` asserts return
was not re-read (existing MED row).

---

## 4. INDEX #40 — particle colour packing [closed, HIGH]

The chain from data to screen:
1. **COLOR key reader `FUN_1002cbd0`** (`1002cc04 bl 0x1002c550`; ≤ 31 chars, `1002cc2c`):
   `FUN_10010990(text, dst)` (`1002cc50`); on 0 → `FUN_1002ce60("Invalid COLOR…")` (`1002cc68`).
   - If the key is missing, the 32-byte buffer is **not** zeroed (`1002cc0c beq 0x1002cc48` skips the
     memset at `1002cc18`), so `FUN_10010990` parses stale stack bytes. It almost surely fails and
     reports an error with `dst` untouched. [MED for the stack contents]
2. **`FUN_10010990` (HTML RRGGBB → pix16)**, listing `10010990..10010bcc`:
   - `strlen == 1`: compares with `"0"` (`0x100e609c`). Either way it returns 0 with no store
     (`"0"` → silent; anything else logs "ERROR: HTML RGB String (%s) in incorrect format.").
   - `strlen == 6`: three `sscanf("%x")` on character pairs (`10010a78`, `10010ab0`, `10010ae8`; fmt
     `0x100e60cf`).
   - Then per channel `c16 = trunc(65535.0f × ((float)c / 255.0f))`: `fdivs` `10010b34/54/58`,
     `fmuls` `10010b50/5c/60`, `fctiwz` `10010b64..6c`. Constants `*(r2−0x7284)` = `0x100d6444` =
     {255.0f, 65535.0f}; magic `0x100d6458`.
   - Then `FUN_10010c00(r16, g16, b16)` (`10010b94`) and `sth` to `dst` (`10010ba0`); returns 1.
   - Other lengths → log, 0.
3. **`FUN_10010c00`** (`10010c00..10010c14`): `(r>>11)<<10 | (g>>11)<<5 | (b>>11)`:
   - `rlwimi r0,r3,0x1f,0x11,0x15` gives mask 0x7c00 from r >> 1;
   - `rlwinm r0,r4,0x1a,0x16,0x1a` gives 0x3e0 from g >> 6;
   - `srawi r0,r5,0xb`.
   **Result:** a brute force over all 256 inputs in float32 (numpy, same op order) gives
   `(trunc(65535·c/255) >> 11) == c >> 3` for **every** c. So the unde `RRGGBB` → 555 packing is
   exactly `>> 3` per channel. The particles-debris-blur.md worked example (F898F8 → (31,19,31)) stands.
4. **Emit `FUN_10043340`** (already HIGH, §2.7 there): request+8 pix16 → 5-bit channels
   (`1004352c rlwinm r4,r4,0x16,0x1b,0x1f` etc.) → `trunc(65535·(c·1/32))` (`*(r2−0x6df4)` =
   `0x100d73a4` = {0.03125, 65535.0}) → variant factor → **`FUN_10010bd0`** at `1004370c` (core, from
   r1+0x78+6i) and `1004371c` (fringe, r1+0x58+6i), stored at `r20`/`r21` (`10043714`, `10043728`).
5. **`FUN_10010bd0`** (`10010bd0..10010bf0`): the same packing from an RGBColor (`lhz` +0/+2/+4).

So #40 is closed at HIGH: data colours pack by `>>3` and particles then lose one step per channel
(the known "variant 0 is one step darker", now listing-backed end to end).

## 5. INDEX #47 — finale same-tick order and `aieg` group delay [closed, HIGH]

- **Order inside the tick (`FUN_10006b50`).** The level-end branch `10006d9c bl 0x10010000` →
  `10006dac bne 0x10007028`.
  - The notice id is `gaob[23]` `noal` (`10006e14 li r3,0x17`) or `gaob[22]` `nole`.
  - It is requested with **no owner** at `10006ee4 bl 0x10033220` (`r4 = 0`, `r5 = 0`, `10006ed4/dc`).
  - Every path then reaches `10007028 → 1000702c bl 0x10033850` (the tally branches also end at
    `b 0x10007028`). So the notice is created **before** the entity update of the same tick T0.
- **Placement.** A one-member, owner-less request goes to the PERM group (spawn-and-waves.md §1.2), which
  is the first group in the active list. `FUN_100009e0` appends at the tail (INDEX #38), so the member is
  reached in the same pass.
- **First visit.** `10033a54 lwz r4,0xb0(r19); subi; stw; cmpwi 0; ble process` (else `10033a74 stw
  r17,0xa4(r19)` restamps). `noal`, `12gc`: `groupDelayMin/Max = 0/0` (data, decoded `unde`), so the
  spawn countdown is 0 → −1 ≤ 0 and they are **processed on their creation tick**. State 0 was entered
  in `FUN_10035cd0` with `now` = T0, so the first timer fires at T0 + timer (noal Flash Off at T0+3, as
  tabulated).
- **`12gc`** is requested by `noal`'s spawn set, as a singleton with owner `noal`, which is in PERM. It
  goes to the PERM tail and is processed in the same pass (loose-ends-combat.md §4 rule, HIGH there), so
  its S0 starts at T0+90. That confirms the timeline.
- **`aieg` group delay = a staggered spawn countdown per member, not one group delay.**
  - `FUN_10035cd0` `10035fb8 lwz r3,0x19c(r31); lwz r4,0x1a0(r31); cmpw; beq` → `10035fc8 bl 0x10046580`
    `R(5,6)`.
  - `10035fd4 add; stw 0x0(r24)` adds it to the running sum, which starts at 0 (`10035c20`), including
    the first member.
  - `10035fe0 stw r0,0xb0(r28)` writes it to the member's countdown.
  - With R = the tick the 50-member group is requested and S_k = Σ_{j≤k} R(5,6), member k is first
    processed at **R + S_k − 1**. The first explosion is at R+4 or R+5 and the last at R+249 … R+299.
  - That is 50 RNG draws for the delays alone, in member order.
  - Correct the loose-ends-session §5.3 row "T0+95 … ≈ T0+370" to "R+S_k−1, last ∈ [R+249, R+299]"
    (R = T0+95 if the set has delay 0; the set's own delay was not re-checked here).

## 6. INDEX #54 — music after a demo/replay [closed, HIGH]

In film modes (session record +5 ≠ 0 → `r21`/`G+0x20`, `FUN_100051a0` `10005670..1000568c`; film flag
`r27` in `FUN_100234d0` `10023500..10023524`) no music call that changes the stream runs:

| site | normal mode | film mode |
|---|---|---|
| `FUN_100234d0` start | `10023518` pause, `100235a0` stop, `100235b8` `ammu` | skipped (`1002350c bne`, `10023598 bne`) |
| `FUN_100064d0` level load | `10006770` stop + `10006788` `ammu` if nothing is playing; `100067c8` stop | skipped (`10006754`, `100067bc` on `r22` = film arg) |
| `FUN_100064d0` sector → `none` | `1000669c` resume | runs, but resume is a no-op unless paused (`100d0424 lbz −0x5bb8(r2); beq`, `100d0430 saved rate; beq`) |
| `FUN_100051a0` game appears | `10005974` level `#music_ID` | skipped (`10005960 bne`) |
| `FUN_10007170` level complete | `10007204` stop | session ends at once (`100071e8 beq` not taken → `100071f4 stb 0,+8`; no stop): films cover one level |
| `FUN_100051a0` game end | `10005ad8` stop effects, `10005ae4` stop music | skipped (`10005ad4 bne`) |
| `FUN_100234d0` return | `10023774` stop; `b6 = 1` at `10023974` / `10023ae4` | stop skipped (`1002376c`), `b6` not set (`1002396c`, `10023adc`) |
| pause screen `FUN_10022ef0` | pause + resume around Caps Lock | same (net no change) |

⇒ The menu's `inmu` keeps playing, uninterrupted, from the menu through the whole demo/replay and back
to the menu. The menu pass does not touch it because `b6` stays 0. No level music or `ammu` is heard in
a film.

## 7. INDEX #60 — film object +0xc/+0x10 writers [closed, HIGH]

The film object is allocated in `FUN_100051a0` (`10005624 bl 0x1004d320`, size 0x9d7c), held only in
non-volatile `r25`, and **never stored to memory**. All uses of `r25` are register moves into calls:

- `100056c4` → `FUN_100069b0` → only `FUN_100094a0` (`10006afc`) and `FUN_10009680` (`10006b1c`);
- `100057e0` → `FUN_10009710`;
- `100059c0` → `FUN_10006b50` (`10006b70` r24) → `10006c04` → `FUN_10028170` (`10028190` r15, used
  only at `10029054`) → `FUN_1002a3a0` (r30) → `FUN_100097a0` (`1002a3f8`) / `FUN_10009830`
  (`1002a42c`);
- `10005a34` → `FUN_10009750`;
- `10005b10` → `FUN_100095b0`;
- `10005b28` → `FUN_10009400`.

Every consumer lies inside `0x10009390–0x10009980`. A store scan of their listings finds only these
stores at +0xc/+0x10:
- ctor `100093d8 stw r0(=0),0xc(r31)` and `100093e0 stw r0,0x10(r31)`;
- the loader `FUN_100094a0` free loop `100094d8..10009500` (`100094f0 stwx r31(=0),r24,r28`);
- the dtor loop `10009438…` (gameplay-leftovers §1.2).

All of them store **0**. So +0xc/+0x10 are always NULL and both free loops are no-ops: vestigial fields.

Side readings:
- `FUN_100094a0(film, tag)`: tag `none` → 0. Otherwise it frees +0xc/+0x10, loads `film` tag
  (`FUN_10002850`); a missing tag logs and returns 0. It copies 0x9d68 bytes to +0x14 (`10009540`). The
  version must equal 0x2715 (`1000954c`), else it logs "…%d…" and returns 0. It frees the loaded copy
  (`10009588`) and returns 1 on success.
- `FUN_10009680(film, &level, &players, &seed)` = `FUN_10009780` / `FUN_10009790` / `FUN_10009770` to
  the out-params (`100096b4/c4/d4`), then `FUN_10009970` (cursors 0, `100096dc`).

---

## NOT RESOLVED (this file)
1. Initial alpha / scale set when a level-select flash starts (caller `FUN_1002e310`). This decides the
   exact flash length (§3.8). Settle with the `FUN_1002e310` listing at the stores to `0x1010332c+4/+8`.
2. Entity-pool slot pre-allocation (who fills slot +0x10, §3.7). Not replay-relevant.
3. Whether `FUN_10000f80` / `FUN_10000f30` return (§3.10). Existing rows are MED; loose-ends-session §8
   owns them.
4. `aieg` spawn-set delay on `12gc` S2 (fixes R in §5). Settle by decoding `12gc`'s spawn set.
5. Not done by brief: INDEX #13 (`+0x70` load scan), #59 remaining builders.

## Role-table rows (for merge)
| `FUN_100351f0` | G_EntityGroup.cc | ⚑ label MED→HIGH: count members (all active groups, list `0x100e0228`) whose unit ID == arg and spawn countdown `+0xb0 ≤ 0`; unit `none` → 0; rules #14 `==`, #15 `<`, #16 `>` (signed) vs `rule+0x84` | HIGH | listing `10035208..100352b8`; rule sites `10015874..100158d4`; caller `FUN_10015550` (micro-wave §3.1) |
| `FUN_100352f0` | G_EntityGroup.cc | ⚑ label MED→HIGH: any member whose unit has `includeInAirAccuracyCount` (+0x133); no countdown/deleted/on-screen test (rule #4 = none) | HIGH | `10035390 lbz r0,0x133(r3)`, `1003539c li r28,1`; rule `10015754` (micro-wave §3.1) |
| `FUN_100353e0` | G_EntityGroup.cc | ⚑ label MED→HIGH: any member with `includeInGroundAccuracyCount` (+0x134) **and** on screen (`FUN_10016bd0`) (rule #5 = none); `!#4 && !#5` combined at `10015784..100157ac` | HIGH | `10035480 lbz r0,0x134(r4)`, `1003548c bl 0x10016bd0` (micro-wave §3.1) |
| `FUN_10016230` | G_Entity.cc (span) | ⚑ label MED→HIGH: frame for heading h: n = NumDirections (≤0→1), step = 360/n (int), k = trunc((float)h/(float)step) +1 if frac ≥ 0.5 (single precision; negatives truncate toward 0), k<0→n−1, k>n−1→0, × FramesPerDirection | HIGH | listing `10016230..100162f4`; 0.5 at `0x100d6ca4+0x10` (micro-wave §3.2) |
| `FUN_10014670` | G_Entity.cc (span) | ⚑ corrected: enter the first state with `UseThisStateOnWeaponPowerupRelease` (+0x355) **by its name** (`stateName_STR` U+0x97c+s·0x5e0) via `FUN_100146f0(e, 0, name, now)`; duplicate names would pick the last — none in shipped data | HIGH | `10014688..100146b4` (micro-wave §3.3) — was MED "switch entity to its UseThisStateOnWeaponPowerupRelease state" |
| `FUN_1003bff0` | G_WeaponHandler.cc | ⚑ label MED→HIGH: per aux record (list +0x70): fire if now > last + delayBetweenLaunches and (autoRepeat or fireAir up last tick): count+1, last = last2 = now; returns any-fired | HIGH | `1003c054..1003c0a8` (micro-wave §3.4) |
| `FUN_1002c960` |  | ⚑ label MED→HIGH: read FLOAT key: locate `<…>`, ≤31 chars, `sscanf "%f"`; missing / empty → `FUN_1002ce60` error, dst untouched | HIGH | `1002c994`, `1002c9d4`, `1002ca04`; strings `0x100ea6f4`, `0x100ea731`, `0x100ea734` (micro-wave §3.5) |
| `FUN_10012650` | G_GameObject (span) | ⚑ label MED→HIGH: object reset, full field list (clip {0,0,480,416} from code image `0x100d6788`, vis 100, scale 1.0, `defa`, `none`, flags 18/19/34/37/38 = 1) | HIGH | `10012650..10012748` (micro-wave §3.6) |
| `FUN_100385d0` | G_EntityGroup.cc | ⚑ label MED→HIGH: pool alloc (1000 slots at `0x101038a8`): count ≥ 1000 → log + NULL; free hint else first free slot; inUse, `FUN_100142f0`, +0x148 = slot | HIGH | `10038600`, `10038628..10038778`, `100387b4..100387dc` (micro-wave §3.7) |
| `FUN_10038810` | G_EntityGroup.cc (span) | ⚑ label MED→HIGH: pool free: slot +0x148 inUse = 0, count−1, hint = slot (next alloc reuses it) | HIGH | `10038810..10038838` (micro-wave §3.7) |
| `FUN_1002fcc0` | G_LevelSelection (span) | ⚑ label MED→HIGH: accept/fail flash step: alpha +1→32; scale ± F44/F46 between 1.0 and F45/F47 (2.0); ends when scale == 1.0 and alpha == 32 | HIGH | `1002fce4..1002fe18`; base `0x100d70dc` (micro-wave §3.8) |
| `FUN_100298c0` | G_Player.cc | ⚑ label MED→HIGH: state 4 only: crosshair, shadow-only pass, sprite-only pass, coin-tally text (fmt 30, layer 15, keep-clip, blend = +0xe0, y += +0x1f8) while +0xd8 and +0xe0 < 32 | HIGH | `100298d4..100299a0` (micro-wave §3.9) |
| `FUN_10011fd0` | G_Level.cc | ⚑ label MED→HIGH: load level by sector: asserts `0x100e0151` clear and list non-null; first order-list node with +4 == sector → tag +0 (`none` asserts); `FUN_100120f0(tag,…)` | HIGH | `10011ff0..100120c8` (micro-wave §3.10) |
| `0x10011750` (no function) | M_Configuration.cc | NEW: Sound-volume slider action proc (item 12): parts 20/21 ∓1, 22/23 ∓10 within min/max, SetControlValue; relabel item 13 `"%i%%"` on change or part 129; SetGWorld(dlg) | HIGH | `10011774..100118b4`; installed `10011190..100111d4` (micro-wave §1) |
| `0x100118e0` (no function) | M_Configuration.cc | NEW: Music-volume slider action proc (item 15), label item 16; else identical | HIGH | `10011904..10011a44`; installed `100111dc..10011220` (micro-wave §1) |
| `0x10049c20` / `0x10049c30` / `0x10049c40` (no function) | M_Application.cpp | NEW: AE handlers odoc → noErr / pdoc → −1708 / oapp → noErr | HIGH | `10049c20 li r3,0`, `10049c30 li r3,-0x6ac`, `10049c40 li r3,0`; TVs `0x100e0a38/28/40` (micro-wave §2) |
| `0x10049c50` (no function) | M_Application.cpp | NEW: AE `quit` handler: set quit `b8` (`FUN_10022ed0`), noErr | HIGH | `10049c70 bl 0x10022ed0`, `10049c84 li r3,0`; TV `0x100e0a30` (micro-wave §2) |
| `FUN_10049aa0` | M_Application.cpp | ⚑ label MED→HIGH: install aevt oapp, odoc, quit, pdoc (procInfo 0xfe0, refcon 0, app table); failure → `FUN_10000ed0` "error is_eq noErr" | HIGH | `10049ac0..10049c00` (micro-wave §2) |
| `FUN_10010990` | G_Background (span) | ⚑ label MED→HIGH: HTML RRGGBB → pix16: len 6 → 3×`%x`, c16 = trunc(65535·c/255) (float32), `FUN_10010c00` (≡ c>>3 for all c); len 1 "0" → 0 silently; else log + 0 | HIGH | `10010990..10010bcc`; consts `0x100d6444` (micro-wave §4) |
| `FUN_10009680` | G_Film | ⚑ label MED→HIGH: film header → out level, player count, seed; reset cursors | HIGH | `100096ac..100096dc` (micro-wave §7) |
| `FUN_100094a0` | G_Film | ⚑ label MED→HIGH: load film tag: free +0xc/+0x10 (always NULL), copy 0x9d68 B to +0x14, version must be 0x2715; 1 = ok | HIGH | `100094d8..10009588` (micro-wave §7) |
| `FUN_10007170` | G_Game.cc (span) | ⚑ label MED→HIGH (meaning unchanged): if +9 and a player alive: film → +8 = 0 (session ends, no music stop); else stop music, `tran`, fade, clear +9/+0x39, `FUN_100302e0`, `FUN_100064d0`; no player → +8 = 0 | HIGH | `10007194..10007268` (micro-wave §6) |

Label changes in topical files (for the fix pass):
- bosses.md §3.1: rows 4, 5 and 14 MED → HIGH.
- units-movement.md §8.2: "MED for the helper arithmetic" → HIGH; add "single precision; negatives
  truncate".
- units-movement.md §10 and weapons-projectiles.md §2.5/role row `FUN_10014670`: add "by name".
- particles-debris-blur.md l. 170: "`FUN_10010bd0` is MED" → HIGH (`10010bd0..10010bf0`).
- loose-ends-session.md §5.3: the timeline is HIGH for same-tick order; correct the `aieg` row as in §5.

## INDEX updates (for merge)
- **#40** closed (micro-wave §4): `unde` RRGGBB packs to 555 as exactly `>>3`. The path is
  trunc(65535·c/255) >> 11, identical for all 256 c (brute force). FUN_10010bd0 is listing-read at the
  call sites `1004370c`/`1004371c`. Strike particles-debris-blur.md NR 1.
- **#47** closed (micro-wave §5): noal is requested at `10006ee4` before `FUN_10033850` (`1000702c`). It
  goes into PERM with group delay 0, so it is processed on T0; 12gc likewise on T0+90. `aieg` delay =
  per-member cumulative countdown `R(5,6)` (member k at R+S_k−1). Strike loose-ends-session.md NR 3.
- **#54** closed (micro-wave §6): in film modes no stream-changing music call runs and `b6` is not set,
  so `inmu` plays on uninterrupted. Strike front-end.md NR 4.
- **#60** closed (micro-wave §7): the film pointer never leaves registers. Its only +0xc/+0x10 writers
  (ctor, loader, dtor) store 0, so the fields are vestigial NULLs. Strike gameplay-leftovers.md NR 1.
- Also closable: gameplay-leftovers.md NR 2 and front-end.md NR 9 (flash fields and arithmetic, §3.8;
  residue = initial alpha, this file NR 1).
- Critic §1 "no row" table: `0x10011750`, `0x100118e0`, `0x10049c20/30/40/50` now have rows.

## Fold-in notes (2026-10-06)
- Spot check: every HIGH claim above was re-read at its cited lines in `$W/disasm-micro*.txt` and
  `critic3-work/gaps.txt` (TV slots, constants and strings from `$W/mem/*.bin`; #15/#16 idioms and the
  `>>3` brute force re-run). All hold; none was folded as MED.
- §5: the running sum that starts at 0 lives in the wrapper `FUN_10035bf0` (`10035c20 stw r0,0x38(r1)`,
  passed as `r7` = `r24` into `FUN_10035cd0`); when min == max the countdown adds min. Meaning unchanged.
- §3.8 / NR 1: ⚑ corrected (micro-wave, 2026-10-06) #62 — the start values are stored by
  `FUN_1002fe40(mode)` (`1002fea8..1002ff14`), not by `FUN_1002e310`: scale 1.0, growing 1, colour =
  text format 0x1b/0x1c +0x122, alpha = that format's BlendAmount (+0x114). Residue → INDEX #62.
- NOT RESOLVED mapping: NR 1 → INDEX #62 (narrowed), NR 2 → #63, NR 4 → #64; NR 3 is covered by
  loose-ends-session.md §8.2 (both asserts end in the non-fatal `FUN_10000fd0`; INDEX #3) and gets no
  new number; NR 5 = existing INDEX #13, #59.
