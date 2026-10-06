# Deimos Rising 1.0.6 — static-initialiser audit (what runs before `main`, and which bank values it changes)

Scope (reader w3s2, wave 3, 2026-10-04): everything that executes between the PEF main symbol and
`main`: `entry @ 1004d540`, its helpers `FUN_1004d520`/`FUN_1004d530`/`FUN_1004b2b0`, the static-init
dispatcher `FUN_10000000 @ 10000000` and all 32 of its callees (`FUN_10000750 … FUN_100623e0`),
plus the five small game constructors they call (`FUN_1000ad00`, `FUN_10010ca0`, `FUN_10020d60`,
`FUN_10009980`, `FUN_10009a20`) and the destructor registrar `FUN_1004cfa0`. Every one of these was
read by raw listing (`$W/disasm-w3s2.txt`, `$W/w3s2-disasm-callees.txt`, `$W/w3s2-disasm-users.txt`)
and the 29 game initialisers were executed instruction by instruction by a small PPC interpreter
over those listings and the two memory images (`$W/w3s2-emu.py`; stores logged with the address each
stored word was loaded from). Then: a sweep of every bank claim that took a value from the data
image (table B), and a check that no post-`main` code writes the same objects. OUT: anything after
`main` except the writer/reader scans in §4; the prefs defaults `FUN_100050f0`; the MSL library
internals below `FUN_1005a350`/`FUN_1005a8a0` (only their destinations are bounded, §1.4).
`$W` = `/Users/andiyar/Developer/Ambrosia-Classics/ghidra/deimos-proj`; TOC r2 = `0x100e6330`; all scratch scripts are `$W/w3s2-*`.

**Bottom line.** Static initialisation changes exactly **three kinds of value** in the data image,
each identically in every translation unit that includes the header defining it:
1. the 26 copies of the 0x4c-byte **sprite draw-command template** get clip right/bottom
   **480/416** (+0x28/+0x2c; image 0/0);
2. the 7 copies of the 0x2c-byte **spawn-request template** get owner serial **+0x24 = −1**
   (`0xffffffff`; image 0);
3. the 9 copies of the 0x28-byte **notice-post template** get the **sound record**
   +0x0c..+0x23 = `'none'`, 100, 100, 100, 1.0, 1.0 (image all zero).
Every other word written before `main` already equals its image value (0). No post-`main` code
stores into any of these templates (§4), so the runtime values hold for the whole session.
⚑ corrected (review wave 3, 2026-10-06) #C2: the 480/416 clip **does** reach the screen — every text builder keeps it when format
+0x10d ≠ 0 (messages, notices, console, FPS counter, tallies), and the level-select `COST` strip
always keeps it (§4.3).
Of the 49 bank claims swept, **41 are right** (runtime = what the bank states) and **8 are wrong**
(`## ⚑ conflicts`): six state request +0x24 = 0 (it is −1; behaviour-neutral, §5.2) and two
misidentify what an initialiser fills.

## 1. What runs before `main` [HIGH unless noted]

### 1.1 The entry chain
The PEF loader section (parsed from `ghidra/Deimos_pef`, section 2 at file offset 0x80) has
**main = section 1 offset 0x2760, init = −1, term = −1**. Section 1 (data, kind 2 = pattern-initialised)
+0x2760 = `0x100e0a90` holds the TVector `{0x1004d540, 0x100e6330}` = `entry` + TOC. So no CFM init
routine exists; the only pre-`main` code is what `entry` calls. Command: a 20-line `struct.unpack`
of the PEF container header + loader header (output `main 1 0x2760 init -1 0x0 term -1 0x0`).
```
1004d554  bl 0x1004d520   ; li r3,0; stw r3,0x0(r1)  — zero the stack back-chain
1004d558  bl 0x1004d530   ; or r3,r2,r2              — return TOC
1004d560  lwz r3,-0x7874(r2) … 1004d574 lwz r8,-0x7888(r2); 1004d578 bl 0x1004b2b0
1004d580  stw r3,-0x605c(r2)                           ; result → 0x100e02d4
1004d584  bl 0x10000000                               ; static initialisers (§2)
1004d594  bl 0x100000a0                               ; main (FUN_100000a0: 100000e0 / 100229a0 / 10000630)
1004d5a0  bl 0x1004db30                               ; exit(0)
```
`FUN_1004b2b0` gets (code start `0x10000000`, code end `0x100de330`, data start `0x100de330`,
data end `0x1011ef04`, table start `0x100db69c`, table end `0x100de330`, TOC) — TOC slots
`0x100deabc/b8/b0/ac/a8` resolved from the image. It stores them as one 0x1c-byte record
(`1004b354..1004b370 stw r25,0x8(r5) … stw r31,0x18(r5)`) in a 32-slot block list headed at
`*(r2−0x6068)` = `0x100e02c8`, allocating a new 0x384-byte block (`1004b3a0 li r3,0x384`) when full.
On its first call it sets `0x100e02c1` (`1004b2f0 stb r3,-0x606f(r2)`) and, if
`Gestalt('ppcf')` (`1004b2fc lis r3,0x7070; addi 0x6366`) succeeds with bit 0x10, sets `0x100e02c0`.
Role: the Metrowerks runtime's code-fragment / exception-table registration [MED: shape and
arguments; the name is inference]. Its writes (`0x100e02c0`, `02c1`, `02c8`, `02d4` and the heap)
are runtime-private; no bank file cites them (grep for those addresses and r2 displacements: none).

### 1.2 The dispatcher `FUN_10000000 @ 10000000`
Straight-line: 32 `bl` (`1000000c` … `10000088`) in address order of the callees, then return.
Callees, in call order: `10000750 10004520 100092a0 1000ca10 1000f720 100108e0 100125b0 10014120
10017f80 10018670 1001b760 1001d570 1001f0d0 1001f750 10020cf0 100228d0 10025b00 10026100 1002a4f0
1002aa70 1002da40 1002e280 10030020 10030e70 10032b20 10039100 1003ce60 100428b0 100448b0 10046680
10061b30 100623e0`. Each is one translation unit's `__sinit` (C++ dynamic initialisation of
namespace-scope objects whose initialiser copies another const object).

### 1.3 Shape of the 29 game initialisers
No loops (no `mtspr CTR`/`bdnz` in any of the 32; the only `bdnz` in `$W/disasm-w3s2.txt` is
in `FUN_1004b2b0`) — so the 8-byte copy-loop "+8" hazard does not apply: every destination is an
explicit `stw rS,d(rB)` with `rB = addi/subi rB,r2,K`, every source an explicit `lwz rD,d(rA)` with
`rA = lwz rA,slot(r2)` → a constant record in the **code image** (`0x100d6058…0x100d7393`). The
interpreter follows exactly those registers; table A lists its result. Example (`FUN_10014120`,
full listing in the worked example): `1001412c addi r8,r2,0xb4` (= `0x100e63e4`), `10014124 lwz
r4,-0x7244(r2)` (slot `0x100df0ec` → `0x100d6788`), `10014138 lwz r0,0x0(r4); 10014144 stw r0,0x20(r8)`.
The stores `stw rX,-0x8(r1)`/`-0x4(r1)` at the end of several initialisers (e.g. `10014184/88`)
are below the stack pointer — dead temporaries, not globals.

Calls inside them: `FUN_10000750` → `FUN_1000ad00(0x100f7bf8)` and `FUN_10010ca0(0x100f7be8)`,
each followed by `FUN_1004cfa0(obj, dtor TVector, node)`; `FUN_10030020` → `FUN_10020d60(B+0x294)`
→ `FUN_10009980` → `FUN_10009a20` (12 × `stw r0,…(r3)` = zero 0x30 bytes) then `FUN_1004cfa0(B, …)`,
B = `*(r2−0x6f84)` = `0x1010333c` (slot `0x100df3ac`; the level-select global of
scoring-bonuses.md §10). `FUN_1004cfa0` (`1004cfa0..1004cfb8`) links a 0xc-byte node
{next, dtor, obj} at the head `*(r2−0x789c)` = `0x1011bddc` — the destructor chain run at exit.
`FUN_1000ad00` (`1000ad00..1000ad48`) is the constructor of the display object `D` = `0x100f7bf8`
(hud-scorebar.md §1): `stb 0` to +0x08/+0x09/+0x4d/+0x64/+0x65, `stw 0` to +0x04/+0x50/+0x54/
+0x58/+0x5c/+0x60/+0x68/+0x6c/+0x70, **`stb 1` to +0x4c and +0x4e** (`1000ad2c`, `1000ad30`).
All of these are bss (beyond the 0x198b8-byte initialised data, so image = 0): only D+0x4c/+0x4e
differ from zero. `FUN_1000ae20` later overwrites D+0x4e = 0 and D+0x08 = 1 (`*(param_1 + 8) = 1; *(param_1 + 0x4e) = 0;`
in the `FUN_1000ae20` decompile); D+0x4c is not touched by any bank claim. [HIGH listing; reader of D+0x4c not read]

### 1.4 The three library initialisers [MED]
- `FUN_10046680` (`10046690 bl 0x1005a350` with r3 = `0x100e0280`, `100466ac bl 0x1005a8a0` with
  r3 = `0x100e027c`, each followed by `FUN_1004cfa0`) = two static `ios_base::Init`-style objects
  (narrow and wide). `FUN_1005a350`: per stream a guard byte (`0x100e03da/d9/d8`), a filebuf
  constructor `FUN_1005cf20(obj, &__files[k])` (`_DAT_100deadc` = `0x100f0e44` + 0/0x54/0xa8 =
  stdin/stdout/stderr), then a nifty counter `*0x1011c82c += 1`; on the first count it builds the
  four streams `0x1011c74c/704/794/7dc`, ties them, and sets flag 0x2000 (unitbuf) on one
  (`1005a540 lhz; 1005a548 sth r0,0x30(r6)`). `FUN_1005a8a0` is the wide twin (guards
  `0x100e03d7/d6/d5`, streams `0x1011c628/5e0/670/6b8`). All destinations are MSL objects in
  `0x1011c3d0…0x1011c832`, the guards `0x100e03d5…0x100e03da` and heap blocks. The game never
  names any of them (bank grep: none). Deeper callees (`FUN_1005c080`, `1005ebc0`, `1005d0f0`, …)
  were **not read**; they are reached only from these constructors (callers.txt).
- `FUN_10061b30` (`10061b34 lbz; extsb.; bnelr; li r0,1; stb r0,0x0(r3)`, r3 = `*(r2−0x780c)` →
  `0x1011c3c8`) and `FUN_100623e0` (same pattern on `0x1011c832`, `0x1011c831`, `0x1011c830`): set
  "already initialised" guard bytes for MSL template static members; no payload. [MED: role from
  shape; the guarded objects not identified]
- Neither writes anything inside the game's data section or any address the bank cites.

### 1.5 The image is the unexecuted data [HIGH]
The PEF data section is pattern-initialised (kind 2): packed 0x15e3d bytes, unpacked 0x198b8 =
104632 bytes = the exact size of `$W/mem/100de330.bin`; total 0x40bd8 (the rest is zero-filled
bss up to `0x1011ef08`). So `100de330.bin` is Ghidra's unpacking of the file's pidata with
relocations applied — the state *before* `entry` runs. Every "runtime" value in this file =
image value, overwritten by the pre-`main` stores below.

## 2. The four record kinds the initialisers fill [HIGH]

Every game initialiser writes some subset of the same five objects, one set per translation unit
(the header constants are duplicated per TU). Which fields are written, and the image vs runtime
values (image bytes from `100de330.bin`, sources from `10000000.bin`):

| kind | size | copies | fields written (source record) | image | runtime | consumer meaning |
|---|---|---|---|---|---|---|
| **D** draw-command template | 0x4c | 26 | +0x04..+0x0b ← 0 (8-B record); +0x20..+0x2f ← `00000000 00000000 000001e0 000001a0` (Rect); +0x38..+0x47 ← 0 (16-B record) | all 0 at those fields; elsewhere +0x0c `'none'`, +0x18 1.0f, +0x30 = 7, +0x34 = 0x7fff | **+0x28 = 480, +0x2c = 416**; all else = image | sprite-geometry-draw.md §3.1: clip {top 0, left 0, bottom 480, right 416} |
| **R** spawn-request template | 0x2c | 7 | +0x04..+0x0b ← 0 (x, y); +0x20..+0x27 ← `00000000 ffffffff` | `'none'`, 0, 0, 0, 0, `ff000000`, 0, 0, **0, 0**, 1.0f | **+0x24 = −1** (owner serial); +0x20 = 0 (owner ptr) | spawn-and-waves.md §1.1 (+0x20/+0x24 → entity +0x140/+0x144) |
| **P** notice-post template | 0x28 | 9 | +0x0c..+0x23 ← `'none'`, 100, 100, 100, 1.0f, 1.0f (0x18-B sound record) | +0 0, +4 = 00 01 (hold 0, fade-in 1), +8 0, **+0x0c..+0x23 all 0**, +0x24 `'CEGA'` | **sound = `'none'`, 100, 100, 100, 1.0, 1.0** | messages-notices-console.md §4.1 post record; unit-def-struct.md sound record (ID, minVol, maxVol, priority, minPitch, maxPitch) |
| **T** text-format template | 0x148 | 16 | +0x100..+0x107 ← 0 (Loc x, y) | 0, 0 (+0x108 `'LEFT'`, +0x10c = 8) | = image | hud-scorebar.md §9 format struct |
| **S** `"nonenone"` pair | 0x10 | 17 | +0x08..+0x0f ← 0 | 0, 0 (+0 `'none'`, +4 `'none'`) | = image | particles-debris-blur.md (`FUN_1002aa70` row) |

How each base was identified: D — the 16-byte Rect store at base+0x20 and the template image
pattern (all 26 dumps identical: `00000000 ×3, 'none', 0, 0, 3f800000, 0 ×5, 07000000, 7fff0000,
0 ×5`); R — base+0 holds `'none'` and base+0x28 `3f800000` in the image (all 7 identical: `6e6f6e65
00000000 ×4 ff000000 00000000 ×4 3f800000`); P — `00000000 00010000 00000000 …` with `'CEGA'` at
+0x24 (all 9 identical); T — `'LEFT'` at base+0x108 and byte 8 at +0x10c; S — the 8 bytes
`"nonenone"` immediately before the written pair. Command: `$W/w3s2-tableA-md.py` (classifier) and
the image dumps in this session's log.

Bases: D `0x100e24d0 3ad0 46fc 5298 5a70 63e4 64dc 6844 6a90 7ad4 7b20 7c48 7cd0 891c 8bc8 8f94 9188
0x100ea86c abe8 addc 0x100eb038 b228 b448 0x100eccc8 cfc4 0x100efdb0`; R `0x100e251c 3ca4 5a44 64b0
91d4 0x100eb41c 0x100ecd14`; P `0x100e2690 3c64 6688 69d8 8ab0 0x100eaf70 0x100eb1cc b3bc b5f4`.

## 3. Table A — one row per initialiser [HIGH: listing + interpreter + both images]

Kinds as in §2. "Image → runtime" lists only the words whose runtime value differs from the image
(all other written words are written with their image value). Source records are the code-image
runs the initialiser loads, with their bytes.

| fn | destinations (kind + base) | source records (code image bytes) | image → runtime where different | differs? |
|---|---|---|---|---|
| `FUN_10000750` | D `100e24d0`, R `100e251c`, P `100e2690`, T `100e2548`, S `100e26b8` | `100d6058` 00000000 00000000 00000000 00000000; `100d6070` 6e6f6e65 00000064 00000064 00000064 3f800000 3f800000 00000000 00000000 000001e0 000001a0 00000000 00000000 00000000 00000000 00000000 ffffffff | D`24d0` +0x28/+0x2c 0,0 → 480,416; R`251c` +0x24 0 → −1; P`2690` +0x0c..+0x23 0 → 'none',100,100,100,1.0,1.0 | **yes** |
| `FUN_10004520` | S `100e2bac` | `100d61b0` 00000000 00000000 | all written words = image (0) | no |
| `FUN_100092a0` | D `100e3ad0`, R `100e3ca4`, P `100e3c64`, T `100e3b1c`, S `100e3c8c` | `100d62fc` 00000000 00000000 00000000 00000000; `100d6314` 6e6f6e65 00000064 00000064 00000064 3f800000 3f800000 00000000 00000000 000001e0 000001a0 00000000 00000000 00000000 00000000 00000000 ffffffff | D`3ad0` +0x28/+0x2c 0,0 → 480,416; R`3ca4` +0x24 0 → −1; P`3c64` +0x0c..+0x23 0 → 'none',100,100,100,1.0,1.0 | **yes** |
| `FUN_1000ca10` | D `100e46fc`, T `100e4748` | `100d6388` 00000000 00000000; `100d6398` 00000000 00000000 000001e0 000001a0 00000000 00000000 00000000 00000000 | D`46fc` +0x28/+0x2c 0,0 → 480,416 | **yes** |
| `FUN_1000f720` | D `100e5298`, T `100e52e4` | `100d63b8` 00000000 00000000; `100d63d0` 00000000 00000000 000001e0 000001a0 00000000 00000000 00000000 00000000 | D`5298` +0x28/+0x2c 0,0 → 480,416 | **yes** |
| `FUN_100108e0` | D `100e5a70`, R `100e5a44`, S `100e5a2c` | `100d6404` 00000000 00000000 00000000 00000000 00000000 ffffffff 00000000 00000000 000001e0 000001a0 00000000 00000000 00000000 00000000 | D`5a70` +0x28/+0x2c 0,0 → 480,416; R`5a44` +0x24 0 → −1 | **yes** |
| `FUN_100125b0` | S `100e618c` | `100d6460` 00000000 00000000 | all written words = image (0) | no |
| `FUN_10014120` | D `100e63e4`, S `100e6430` | `100d6778` 00000000 00000000; `100d6788` 00000000 00000000 000001e0 000001a0 00000000 00000000 00000000 00000000 | D`63e4` +0x28/+0x2c 0,0 → 480,416 | **yes** |
| `FUN_10017f80` | D `100e64dc`, R `100e64b0`, P `100e6688`, T `100e6540`, S `100e6528` | `100d67f4` 00000000 00000000 00000000 00000000; `100d680c` 6e6f6e65 00000064 00000064 00000064 3f800000 3f800000; `100d6c64` 00000000 ffffffff 00000000 00000000 000001e0 000001a0 00000000 00000000 00000000 00000000 | D`64dc` +0x28/+0x2c 0,0 → 480,416; R`64b0` +0x24 0 → −1; P`6688` +0x0c..+0x23 0 → 'none',100,100,100,1.0,1.0 | **yes** |
| `FUN_10018670` | D `100e6844`, P `100e69d8`, T `100e6890`, S `100e6a00` | `100d6cbc` 00000000 00000000 6e6f6e65 00000064 00000064 00000064 3f800000 3f800000 00000000 00000000 000001e0 000001a0 00000000 00000000 00000000 00000000 | D`6844` +0x28/+0x2c 0,0 → 480,416; P`69d8` +0x0c..+0x23 0 → 'none',100,100,100,1.0,1.0 | **yes** |
| `FUN_1001b760` | D `100e6a90` | `100d6cfc` 00000000 00000000; `100d6d0c` 00000000 00000000 000001e0 000001a0 00000000 00000000 00000000 00000000 | D`6a90` +0x28/+0x2c 0,0 → 480,416 | **yes** |
| `FUN_1001d570` | D `100e7ad4` | `100d6d50` 00000000 00000000 00000000 00000000 000001e0 000001a0 00000000 00000000 00000000 00000000 | D`7ad4` +0x28/+0x2c 0,0 → 480,416 | **yes** |
| `FUN_1001f0d0` | D `100e7b20` | `100d6d84` 00000000 00000000; `100d6d94` 00000000 00000000 000001e0 000001a0 00000000 00000000 00000000 00000000 | D`7b20` +0x28/+0x2c 0,0 → 480,416 | **yes** |
| `FUN_1001f750` | D `100e7c48` | `100d6dc0` 00000000 00000000 00000000 00000000 000001e0 000001a0 00000000 00000000 00000000 00000000 | D`7c48` +0x28/+0x2c 0,0 → 480,416 | **yes** |
| `FUN_10020cf0` | D `100e7cd0` | `100d6de8` 00000000 00000000; `100d6df8` 00000000 00000000 000001e0 000001a0 00000000 00000000 00000000 00000000 | D`7cd0` +0x28/+0x2c 0,0 → 480,416 | **yes** |
| `FUN_100228d0` | D `100e891c`, P `100e8ab0`, T `100e8968`, S `100e8904` | `100d6e18` 00000000 00000000; `100d6e28` 6e6f6e65 00000064 00000064 00000064 3f800000 3f800000 00000000 00000000 000001e0 000001a0 00000000 00000000 00000000 00000000 | D`891c` +0x28/+0x2c 0,0 → 480,416; P`8ab0` +0x0c..+0x23 0 → 'none',100,100,100,1.0,1.0 | **yes** |
| `FUN_10025b00` | D `100e8bc8`, T `100e8c14`, S `100e8d5c` | `100d6e60` 00000000 00000000; `100d6e70` 00000000 00000000 000001e0 000001a0 00000000 00000000 00000000 00000000 | D`8bc8` +0x28/+0x2c 0,0 → 480,416 | **yes** |
| `FUN_10026100` | D `100e8f94`, T `100e8fe0` | `100d6e98` 00000000 00000000; `100d6ea8` 00000000 00000000 000001e0 000001a0 00000000 00000000 00000000 00000000 | D`8f94` +0x28/+0x2c 0,0 → 480,416 | **yes** |
| `FUN_1002a4f0` | D `100e9188`, R `100e91d4`, T `100e9200`, S `100e9170` | `100d6ec8` 00000000 00000000 00000000 00000000 00000000 00000000 000001e0 000001a0 00000000 00000000 00000000 00000000 00000000 ffffffff | D`9188` +0x28/+0x2c 0,0 → 480,416; R`91d4` +0x24 0 → −1 | **yes** |
| `FUN_1002aa70` | S `100e99d4` | `100d6ff4` 00000000 00000000 | all written words = image (0) | no |
| `FUN_1002da40` | D `100ea86c`, T `100ea8b8` | `100d702c` 00000000 00000000; `100d703c` 00000000 00000000 000001e0 000001a0 00000000 00000000 00000000 00000000 | D`a86c` +0x28/+0x2c 0,0 → 480,416 | **yes** |
| `FUN_1002e280` | D `100eabe8`, T `100eac34` | `100d705c` 00000000 00000000; `100d706c` 00000000 00000000 000001e0 000001a0 00000000 00000000 00000000 00000000 | D`abe8` +0x28/+0x2c 0,0 → 480,416 | **yes** |
| `FUN_10030020` | D `100eaddc`, P `100eaf70`, T `100eae28`, S `100eadc4` | `100d708c` 00000000 00000000; `100d70a4` 6e6f6e65 00000064 00000064 00000064 3f800000 3f800000 00000000 00000000 000001e0 000001a0 00000000 00000000 00000000 00000000 | D`addc` +0x28/+0x2c 0,0 → 480,416; P`af70` +0x0c..+0x23 0 → 'none',100,100,100,1.0,1.0 | **yes** |
| `FUN_10030e70` | D `100eb038`, P `100eb1cc`, T `100eb084`, S `100eb1f4` | `100d70ec` 00000000 00000000 6e6f6e65 00000064 00000064 00000064 3f800000 3f800000 00000000 00000000 000001e0 000001a0 00000000 00000000 00000000 00000000 | D`b038` +0x28/+0x2c 0,0 → 480,416; P`b1cc` +0x0c..+0x23 0 → 'none',100,100,100,1.0,1.0 | **yes** |
| `FUN_10032b20` | D `100eb228`, P `100eb3bc`, T `100eb274` | `100d712c` 00000000 00000000 6e6f6e65 00000064 00000064 00000064 3f800000 3f800000 00000000 00000000 000001e0 000001a0 00000000 00000000 00000000 00000000 | D`b228` +0x28/+0x2c 0,0 → 480,416; P`b3bc` +0x0c..+0x23 0 → 'none',100,100,100,1.0,1.0 | **yes** |
| `FUN_10039100` | D `100eb448`, R `100eb41c`, P `100eb5f4`, T `100eb4ac`, S `100eb494` | `100d7194` 00000000 00000000 00000000 00000000; `100d71b4` 6e6f6e65 00000064 00000064 00000064 3f800000 3f800000 00000000 ffffffff 00000000 00000000 000001e0 000001a0 00000000 00000000 00000000 00000000 | D`b448` +0x28/+0x2c 0,0 → 480,416; R`b41c` +0x24 0 → −1; P`b5f4` +0x0c..+0x23 0 → 'none',100,100,100,1.0,1.0 | **yes** |
| `FUN_1003ce60` | D `100eccc8`, R `100ecd14`, S `100ecd40` | `100d7270` 00000000 00000000 00000000 00000000; `100d7288` 00000000 00000000 000001e0 000001a0 00000000 00000000 00000000 00000000 00000000 ffffffff | D`ccc8` +0x28/+0x2c 0,0 → 480,416; R`cd14` +0x24 0 → −1 | **yes** |
| `FUN_100428b0` | D `100ecfc4` | `100d72d0` 00000000 00000000; `100d72f8` 00000000 00000000 000001e0 000001a0 00000000 00000000 00000000 00000000 | D`cfc4` +0x28/+0x2c 0,0 → 480,416 | **yes** |
| `FUN_100448b0` | D `100efdb0`, S `100efd98` | `100d7374` 00000000 00000000; `100d7384` 00000000 00000000 000001e0 000001a0 00000000 00000000 00000000 00000000 | D`fdb0` +0x28/+0x2c 0,0 → 480,416 | **yes** |
| `FUN_10046680` | MSL stream objects `0x1011c3d0…0x1011c82c` (bss), guards `0x100e03d5…da`, dtor nodes | (constructors; §1.4) | bss 0 → constructed streams; guards 0 → 1 | yes (library only) |
| `FUN_10061b30` | guard byte `0x1011c3c8` (bss) | `li r0,0x1` | 0 → 1 | yes (library only) |
| `FUN_100623e0` | guard bytes `0x1011c830/31/32` (bss) | `li r0,0x1` | 0 → 1 | yes (library only) |

Plus, from `FUN_10000750`: display object `D` = `0x100f7bf8` constructed (§1.3; bss, +0x4c = +0x4e = 1),
byte `0x100f7be8` ← 0, destructor nodes `0x100f7bec`/`0x100f7c6c`; from `FUN_10030020`: B+0x294 =
`0x101035d0..0x101035ff` ← 0 (bss, same as image), destructor node `0x10103604`. No address is
written by two initialisers except the destructor-chain head `0x1011bddc` (checked: duplicate scan of
the interpreter's store log).

## 4. Static-ness, and who writes these objects later [HIGH unless noted]

### 4.1 Each initialiser runs exactly once, before `main`
- callers.txt: each of the 32 has exactly one caller, `FUN_10000000`; `FUN_10000000` has one, `entry`.
- Raw `bl` scan of the whole code image (mask `0xFC000003 == 0x48000001`, target = pc + sign-extended
  LI): the only `bl` to any of the 33 addresses are `1000000c…10000088` and `1004d584`.
- No word in either image equals any of the 32 addresses (pointer/TVector scan, 2-byte steps); the
  words equal to `0x10000000` are the exception-table entries `0x100dad9a…0x100de2f0` (code image)
  and the registration argument slot `0x100deabc`. Command: `python3 $W/w3s2-scan.py calls`.
- `FUN_10020d60` (the B+0x294 member constructor) is also called by `FUN_1002e310` (level select)
  — a normal constructor call, not a re-run of the static initialiser.

### 4.2 No post-`main` code stores into any template
- Scan of every D-form instruction with RA = r2 (opcode `w>>26` ∈ {14 addi, 32 lwz, 34 lbz, 36 stw,
  38 stb, 40 lhz, 44 sth, 48 lfs, 50 lfd, 52 stfs, 54 stfd, 46/47 lmw/stmw}, `(w>>16)&31 == 2`, EA =
  `0x100e6330 + simm16`) for an EA inside any D/R/P object: **82 hits, all `addi`** (base formation);
  none is a direct load or store. Command: `python3 $W/w3s2-scan.py objs $W/w3s2-objs.txt`.
- Of the 82, the 41 outside the initialisers are in 40 functions (`FUN_10006240 100064d0 10006b50
  1000d380 1000d7f0 1000db90 1000df00 1000e670 10012fa0 10013460 10014f10 10015b40 10016300 10016880
  100184b0 10026d70 10027100 10027670 10027e50 10028170 10029cc0 10029fe0 1002f3c0 1002f7a0 10030360
  10031ea0 10032050 10032250 10032500 100327b0 10033090 10036120 10036610 100380e0 10038810 1003b3c0
  1003c0d0 1003c4f0 1003c7a0 1003c940`). A register-tracking pass over their listings
  (`$W/w3s2-usecheck.py`, follows the base register and every `addi/subi/or` copy of it until
  redefined or clobbered by a `bl`) finds **only loads** (copies of the template to the stack) and
  no store through the base; the three sites in code Ghidra did not attribute (`100185c8`,
  `10038bdc`, `10038e0c`) were read with `DisasmRange` — loads only (`100185cc lwz r0,0x0(r12)` …
  `100185f4 lwz r0,0x24(r12)`; `10038be8 lwz r4,0x0(r28)` … `10038c18 lhz r4,0x2a(r28)`).
- 42 TOC slots in the data image point at a D/R/P object start; code loads only one of them
  (`100448bc` in `FUN_100448b0`, the initialiser of `0x100efdb0`, which is out of `addi` range).
- So no constructor (e.g. the frame-controller zeroing `FUN_10030190` → `FUN_10030df0`, which works
  on its own object) and no game code rewrites a template: **the post-initialiser value is the value
  at the first frame and for the whole session.** [HIGH for direct and slot-based access; a store
  through a pointer derived some other way (e.g. `addis`) is not excluded — none was seen]

### 4.3 Where the D-template clip could survive into a draw [HIGH for the lines quoted]
The template clip only matters if a builder keeps it. ⚑ corrected (review wave 3, 2026-10-06) #C2: was "Every builder read keeps **no**
template clip" — wrong for the text builders: `FUN_1000d380` (`1000d504 lbz r0,0x1a1(r1)` = format
+0x10d; `1000d538 bne 0x1000d550` skips `bl 0x1000a530`), `FUN_1000e670` (`1000e72c lbz r0,0x22(r26)`;
`1000e734 bne 0x1000e74c`) and the list draws/fades `FUN_1000d7f0`/`1000db90`/`1000df00` (`1000d9b0
lbz r0,0x10d(r26)`; `1000d9b8 bne 0x1000d9cc`; `1000de64`/`1000e1d4 bne` past `bl 0x1000a530`) keep the
template clip {0,0,480,416} whenever format +0x10d ≠ 0. Messages, notices, the console, the FPS
counter and the tallies set +0x10d = 1 (text-metrics-lists.md §2.2), so **the 480/416 clip reaches the
screen: queued overlay glyphs and strips are clipped to buffer x < 416, y < 480**. The level-select
`COST` strip of `FUN_1002f7a0` also keeps it (template `0x100eaddc` copied at `1002fb94..1002fbd8`, no
store to cmd+0x20..+0x2c (r1+0x108..0x114) before `1002fc10 bl 0x10019570`). The rows below keep no
template clip:
| builder | template | clip source | evidence |
|---|---|---|---|
| `FUN_10012fa0` entity draw | `0x100e63e4` | entity +0x3c..+0x48 | `10013098 lwz r0,0x3c(r25); 1001309c stw r0,0x58(r1)` … `100130b4 stw r0,0x64(r1)` (cmd at r1+0x38) |
| `FUN_10013460` shadow | `0x100e63e4` | entity +0x3c..+0x48 | `10013554 lwz r4,0x3c(r23); 10013558 stw r4,0x58(r1)` … `1001356c lwz r4,0x48(r23); 10013570 stw r4,0x64(r1)` |
| `FUN_10031ea0 10032050 10032250 10032500 100327b0` HUD | `0x100eb228` | `FUN_1000a530` (buffer bounds) | `10031f28 addi r4,r1,0x58; 10031f3c bl 0x1000a530` (cmd r1+0x38); `10032110`→`10032124`; `100322e0 addi r4,r1,0xa4`→`100322f4`, `10032590`→`100325a4` (cmd r1+0x84); `10032808`→`10032820` |
| `FUN_1002f3c0` level-select previews (3 sites) | `0x100eaddc` | `FUN_1000a530` | cmd r1+0xd8/+0x8c/+0x40 (`1002f590`/`1002f644`/`1002f6ec addi r6,r1,…`); `1002f5b0 addi r4,r1,0xf8; 1002f5cc bl`, `1002f668 addi r4,r1,0xac; 1002f67c bl`, `1002f710 addi r4,r1,0x60; 1002f724 bl 0x1000a530` |
| `FUN_10006240` video grid | `0x100e3ad0` | rect argument r29 | `100063bc stw r7,0x60(r1)` … `100063f8 stw r5,0x6c(r1)` (cmd r1+0x40) |
| `FUN_1000d380` text | `0x100e5298` | `FUN_1000a530` **only when format +0x10d = 0** | `1000d540 addi r4,r1,0x68; 1000d548 bl 0x1000a530` (cmd r1+0x48), skipped by `1000d538 bne 0x1000d550` when +0x10d ≠ 0 — ⚑ corrected (review wave 3, 2026-10-06) #C2 |
~~`FUN_1002f7a0`, `FUN_1000d7f0/db90/df00/e670` were not traced to their clip store (NR 2).~~ ⚑ corrected (review wave 3, 2026-10-06) #C2:
traced above (fix-pass listing `$W/disasm-review3-all.txt`).

## 5. Table B — the sweep of bank claims that took a value from the data image

Found with `grep -n -i 'data image\|image bytes\|from the image\|100de330\|b(0x100e\|memory image\|template' docs/deimos/*.md`
(REVIEW/CRITIC/FIXPASS/REPORT skipped; 145 lines) plus `$W/w3s2-sweep.py` (every `0x100e…/0x100f…/
0x1011…` address or `r2±d` in the bank within 0x4c of a pre-`main` store). Lines that only describe
method (how constants were read) are not claims and are not rows. "No pre-main writer" = the address
is outside every store of §3 and §1.3/§1.4 (the complete pre-`main` store set; MSL deeper callees
bounded to MSL objects, §1.4) and, for the named globals, the r2-based writer scan
(`$W/w3s2-globals.py`) finds writers only in post-`main` functions.

### 5.1 Rows
| # | file:§ (line) | address + what | image value | overwritten by | runtime | bank claim |
|---|---|---|---|---|---|---|
| 1 | sprite-geometry-draw.md §0 row r2+0xb4 (61) + §3.1 (171–199) | `0x100e63e4` draw template, clip | 0,0,0,0 | `FUN_10014120` | {0,0,480,416}; rest = image | right (already corrected #C1) |
| 2 | sprite-geometry-draw.md §0 (60, 59) | `0x100d6788`, `0x100d6d0c` Rects | code image | none (code) | {0,0,480,416} | right |
| 3 | sprite-geometry-draw.md §0 (66–67) | `0x100e0170/71/72/79/81` switches | 1,1,1,0,1 | no pre-main writer (writers `FUN_10019c00`, `FUN_1001a290` and the no-function FX/ALPHA handlers at `0x1001afc0` (`1001afdc stb r0,-0x61bf(r2)`) / `0x1001f040` (`1001f060 stb r3,-0x61af(r2)`) are post-main) — ⚑ corrected (review wave 3, 2026-10-06) #M1: was "`FUN_1001aec0`, `FUN_1001eec0`" (nearest-function attribution; `FUN_1001aec0` ends at `1001af08 blr`, `FUN_1001eec0` = alpha-map builder) | = image at `main` | right |
| 4 | hud-scorebar.md §4 (132–136) | `0x100eb228` template: scale +0x18 1.0, clip | 1.0; 0 | `FUN_10032b20` (clip only) | 1.0; clip then overwritten by `FUN_1000a530` | right |
| 5 | hud-scorebar.md §4 (141–142) + function-roles.md `FUN_10032b20` (564) + hud role row (357) | "fill draw-command templates `0x100eb228`, `0x100eb374`, `0x100eb3c8`" | — | `FUN_10032b20` | `0x100eb374` = T `0x100eb274`+0x100 ← 0; `0x100eb3c8` = sound record of P `0x100eb3bc` | **wrong** (identification) |
| 6 | hud-scorebar.md NR 7 (335–340) | `0x100eb228` x = y = 0, face `none`, scale 1.0 | 0,0,`none`,1.0 | `FUN_10032b20` writes x,y ← 0 | 0, 0, `none`, 1.0 | right — NR 7 closes |
| 7 | hud-scorebar.md §9 (233) | `0x100e52e4` default format (T) | +0x100/+0x104 0, `LEFT`, 8 | `FUN_1000f720` (+0x100/+0x104 ← 0) | = image | right |
| 8 | hud-scorebar.md §4 (125, 127) | strings `0x100eb411` `"%0.7i"`, `0x100eb417` `"%i"` | strings | no pre-main writer | = image | right |
| 9 | hud-scorebar.md §1 (19–20) | display object `0x100f7bf8` (bss) fields set by `FUN_1000ae20` | 0 | `FUN_1000ad00` (+0x4c, +0x4e ← 1) | claims are post-`FUN_1000ae20` values | right (no conflict) |
| 10 | timing-frame.md §2.3 (115) | string `0x100eb21b` `"%i"` | string | no pre-main writer | = image | right |
| 11 | sound-music.md (230) | string `0x100eb21f` `"%s%i%s"` | string | no pre-main writer | = image | right |
| 12 | sound-music.md (311) | `fade` `0x100e0730` = 0x100 | 0x100 | no pre-main writer (writers `FUN_100d04d8`, `FUN_100d05d0`) | 0x100 | right |
| 13 | front-end.md §4.2 (240) | scores symbol text-settings "`0x100e8964`", face `none` | face `'none'` at `0x100e8968`+0x124 | `FUN_100228d0` writes only +0x100/+0x104 ← 0 | face `none` | right (value); address is the decompile's −4 copy-loop artefact: base is `0x100e8968` (`100222fc addi r25,r2,0x2638`; loop `100224b0 subi r4,r25,0x4; 100224b8 lwz r3,0x4(r4); 100224bc lwzu r0,0x8(r4)`, 0x20 × 8 B) |
| 14 | front-end.md role row `FUN_100228d0` (404) + function-roles.md (390) | "static init of the scores symbol template (`0x100e8964`)" | — | `FUN_100228d0` | writes D `0x100e891c`, S `0x100e8904`, T `0x100e8968` (+0x100/+0x104 only), P `0x100e8ab0` | **wrong** (identification; the symbol template's values are unchanged) |
| 15 | front-end.md §4.2 (237) | strings `0x100e8ba1/ba6/bac` | strings | no pre-main writer | = image | right |
| 16 | front-end.md §6 (337–338) | strings `0x100e9128/30/58` | strings | no pre-main writer (`FUN_1002a4f0` stops at `0x100e9307`) | = image | right |
| 17 | front-end.md §2.5 (131–132) | jump table `0x100f0384` | table | no pre-main writer | = image | right |
| 18 | spawn-and-waves.md §1.1 (34–37) | `0x100e64b0` / `0x100eb41c` request templates "bytes identical", listed with `…` | as §2 R | `FUN_10017f80` / `FUN_10039100` | +0x24 = −1 in both; still identical | right (the elided words include +0x24; see #19) |
| 19 | spawn-and-waves.md §7 (430–431) | `0x100ecd14` "+0x20/+0x24 = 0" | 0, 0 | `FUN_1003ce60` | 0, **−1** | **wrong** |
| 20 | bosses.md §3.5 table (221) | `0x100ecd14` "+0x20/+0x24 = 0, read from the data image" | 0, 0 | `FUN_1003ce60` | 0, **−1** | **wrong** |
| 21 | bosses.md NR 3 (365) | `0x100ecd14` "+0x20/+0x24 = 0" | 0, 0 | `FUN_1003ce60` | 0, **−1** | **wrong** |
| 22 | damage-health-death.md §2.5 (197–198) | `0x100ecd14` "+0x20/+0x24 = 0" | 0, 0 | `FUN_1003ce60` | 0, **−1** | **wrong** |
| 23 | weapons-projectiles.md §3.1 (295–296) | `0x100ecd14` "Template image: none, 0.0, 0.0, 0, 0, 0xff000000, 0, 0, 0, 0, 1.0f" used as the launch template | +0x24 = 0 | `FUN_1003ce60` ("refreshes parts", values not given) | +0x24 = −1 | **wrong** (as a runtime value) |
| 24 | level-scroll-objects.md §6.3 (202–203) | `0x100eb41c` "bytes = `'none'`, 0…, +0x14 = 0xff, +0x28 = 1.0f" | +0x24 = 0 | `FUN_10039100` | +0x24 = −1 | **wrong** (the "0…" covers +0x24) |
| 25 | level-scroll-objects.md §7 (284) | `0x100e3ca4` req +0x0c = 0 | 0 | `FUN_100092a0` (not +0x0c) | 0 | right |
| 26 | loose-ends-combat.md §4.3 (286–289) | five(four named) request templates +0x14 = 0xff, +0x28 = 1.0 | 0xff, 1.0 | +0x14/+0x28 not written | 0xff, 1.0 | right (two more R templates exist, `0x100e251c`, `0x100e5a44`, with no post-main user) |
| 27 | loose-ends-combat.md §4.5 (323) | player template `0x100e91d4` +0x20 = 0 | 0 | `FUN_1002a4f0` (+0x20 ← 0) | 0 | right |
| 28 | loose-ends-combat.md §0 (50) | `DAT_100e0214` = 1 | 1 | no pre-main writer (`FUN_10038810` post-main) | 1 | right |
| 29 | loose-ends-session.md §8.3 (335) | `DAT_100e024c` = 0 | 0 | no pre-main writer (`FUN_10041e40`, `FUN_100420f0` post-main) | 0 | right |
| 30 | loose-ends-session.md §8.5 (346–350), §7 (316) | pointer/word scans of the images (no pointer to `0x100e0040–0x100e0140` / to `0x10029c00`) | — | pre-main writes add only bss dtor nodes pointing at `0x100e0878/08e0/0958/0e08/0e28` and objects | unchanged | right |
| 31 | particles-debris-blur.md §1 (47) + NR 3 (376) + INDEX #39 | LCG state `0x100e032c` = 1 at first draw | 1 | no pre-main writer (only `FUN_100553e0`/`FUN_10055400` store it; neither in the pre-main call closure) | 1 at `main` | right (pre-`main` part HIGH; indirect calls inside MSL stream constructors MED) |
| 32 | particles-debris-blur.md §3 (248–251) | `FUN_1002a4f0` → `0x100e9178..0x100e9304`; `FUN_1002aa70` → `0x100e99d4` | — | same | stores span `0x100e9178..0x100e9307`; S `0x100e99d4` +8/+0xc | right |
| 33 | particles-debris-blur.md §2 (63) | strings at `0x100efdfc` | strings | no pre-main writer (D `0x100efdb0` ends `0x100efdfb`) | = image | right |
| 34 | messages-notices-console.md §4.4 (202) | `0x100eb1cc` hold 0, delay 0, sound `'none'` (static init from `0x100d70f4`) | hold 0, delay 0, sound 0 | `FUN_10030e70` (sound record) | hold 0, delay 0, `'none'`,100,100,100,1.0,1.0 | right |
| 35 | messages-notices-console.md §4.1 (163) | notice reset sound from `0x100d6cc4` | code image | — | `'none'`,100,100,100,1.0,1.0 | right |
| 36 | scoring-bonuses.md §6 (65, 495) + function-roles.md (172) | jump table `0x100e3cd0` | table | no pre-main writer (R `0x100e3ca4` ends `0x100e3ccf`) | = image | right |
| 37 | scoring-bonuses.md §5 (145) | jump table `0x100e93c0` | table | no pre-main writer | = image | right |
| 38 | scoring-bonuses.md (419) + function-roles.md (537) | `FUN_10030e70` writes `0x100eb03c`/`184`/`1d8` | — | same | = D `0x100eb038`+4, T `0x100eb084`+0x100, P `0x100eb1cc`+0xc | right |
| 39 | player-physics.md §3 (122–124) | jump tables r2+0x303c/0x3058/0x3074 | tables | no pre-main writer | = image | right |
| 40 | engine-loop.md §5 (223) | `*(float*)(_DAT_100df440+0xc)` = 32.0 | code image `0x100d7204+0xc` | none (code) | 32.0 | right |
| 41 | pak-format.md (170) | `0x100e2bc4…0x100e2d90` | data | no pre-main writer (`FUN_10004520` stops at `0x100e2bbb`) | = image | right |
| 42 | unit-def-struct.md (62) | `_DAT_100e0244` → `0x100ed01f` `" Misc"` | string | no pre-main writer | = image | right |
| 43 | unit-def-struct.md §6 (133), bosses.md (122) | string pool r2+0x6ce0 = `0x100ed010` | strings | no pre-main writer (`FUN_100428b0` stops at `0x100ed00b`) | = image | right |
| 44 | damage-health-death.md (77) + function-roles.md (658) | `FUN_100428b0` → `0x100ecfc8…0x100ed008` | — | same | = D `0x100ecfc4` +4/+0x20/+0x38 | right |
| 45 | weapons-projectiles.md (375) | `FUN_1003ce60` → `0x100ecccc…0x100ecd4c` | — | same | D `0x100eccc8`, R `0x100ecd14`, S `0x100ecd40` | right |
| 46 | units-movement.md (388) | `FUN_100125b0` "2-word global `0x100e6194`" | 0, 0 | same | = S `0x100e618c`+8 ← 0 | right (refine identity) |
| 47 | function-roles.md (277), units-movement.md (408) | `FUN_10014120` row | — | same | as stated | right |
| 48 | data-tags.md §5 (152), hud-scorebar.md (249–250) | "`Size_INT` does not occur in the data image" | absent | pre-main stores write only 0, −1, 480, 416, `'none'`, 100, 1.0 | absent | right |
| 49 | damage-health-death.md NR 2 (444) | request templates "`0x100e64bc…`, `0x100eb420…`" | — | — | bases are `0x100e64b0`, `0x100eb41c` | right as a pointer (addresses off by +0xc/+4; NR already closed by loose-ends-combat.md §4.3) |

Totals: 49 rows; **41 right, 8 wrong** (#5, #14, #19–#24). [HIGH for every row: image bytes from
`100de330.bin`, runtime from the interpreter's store log (`$W/w3s2-emu.txt`) and the listing lines in
§3/§4; row 31 has the MED caveat stated]

### 5.2 What the wrong +0x24 means for behaviour [HIGH, with one MED link]
`FUN_10035cd0` copies the request's +0x20/+0x24 into the entity (`*(e+0x140) = req+0x20;
*(e+0x144) = req+0x24`, dump; bank listing `10035d54`). So every entity spawned from a request that does not write +0x24 carries **owner serial −1**, not 0 —
e.g. level objects (`FUN_10033090` writes only +0x00/+0x04/+0x08/+0x0c/+0x18/+0x1c/+0x1d,
level-scroll-objects.md §6.3) and player shots (the launchers never write +0x20/+0x24, bosses.md §3.5). Readers: the owner-link
validity test (`FUN_10036ab0`/inlined in `FUN_10036cf0`) needs a non-null +0x140 first, so it is
unaffected; `FUN_100363c0` (owner destroyed) compares `+0x144 == dying +0x9c` with no pointer test
(dump: `*(int *)(local_34 + 0x144) == *(int *)(param_1 + 0x9c)`). Serials come from
`_DAT_100e0204++`, reset to 1000 at level init (`10032f9c stw r3,-0x612c(r2)`, value
`10032f90 li r3,0x3e8`) and to −1 only at module shutdown `FUN_10032df0` (`10032e2c`). So neither 0
nor −1 matches a live serial and the shipped behaviour is the same either way [MED: assumes no spawn
between shutdown and the next level init]. A replica should still store −1: it is the original value,
and a replica that numbered serials from 0 would otherwise make every owner-less entity a child of
entity 0.

## ⚑ conflicts
Exact sentences for the fix pass (this file does not edit them):
1. **bosses.md §3.5 table, `passHitsToOwner` row (l. 221):** "(spawn-request template `0x100ecd14`
   +0x20/+0x24 = 0, read from the data image; …" → "(spawn-request template `0x100ecd14` +0x20 = 0
   (no owner pointer) and +0x24 = −1 (written before `main` by `FUN_1003ce60`,
   `1003ceec`/`1003cf00` from `0x100d72a8`; static-init-audit.md §5.2); …".
2. **bosses.md NR 3 (l. 365):** "(no owner: template `0x100ecd14` +0x20/+0x24 = 0, …" → "(no owner:
   template `0x100ecd14` +0x20 = 0, +0x24 = −1, …".
3. **damage-health-death.md §2.5 (l. 197–198):** "(spawn-request template `0x100ecd14`
   +0x20/+0x24 = 0; …" → "+0x20 = 0, +0x24 = −1 (static init, static-init-audit.md)".
4. **spawn-and-waves.md §7 (l. 430–431):** "(request template `0x100ecd14` +0x20/+0x24 = 0, …" →
   "+0x20 = 0, +0x24 = −1, …". Suggested addition to §1.1's +0x20/+0x24 row: "template 0 / −1 at
   runtime (`FUN_10017f80`, `FUN_10039100`)".
5. **weapons-projectiles.md §3.1 (l. 295–296):** "Template image: `none, 0.0, 0.0, 0, 0, 0xff000000,
   0, 0, 0, 0, 1.0f` … `FUN_1003ce60` (static init) refreshes parts of it." → "Runtime template
   (image overwritten before `main` by `FUN_1003ce60`): `none, 0.0, 0.0, 0, 0, 0xff000000, 0, 0, 0,
   −1, 1.0f` — only +0x24 differs from the image (`1003cf00 stw r0,0x24(r12)`, source `0x100d72a8`
   = `00000000 ffffffff`)."
6. **level-scroll-objects.md §6.3 (l. 202–203):** "bytes = `'none'`, 0…, +0x14 = 0xff, +0x28 = 1.0f"
   → "runtime bytes = `'none'`, 0…, +0x14 = 0xff, +0x24 = −1 (`FUN_10039100`), +0x28 = 1.0f".
7. **hud-scorebar.md §4 (l. 141–142), NR 7 (l. 335–340) and its role row (l. 357) + function-roles.md
   `FUN_10032b20` (l. 564):** "fill draw-command templates `0x100eb228`, `0x100eb374`, `0x100eb3c8`"
   → "fill the draw-command template `0x100eb228` (only change vs the image: clip +0x28/+0x2c =
   480/416, overwritten by every HUD builder via `FUN_1000a530`), the text-format template
   `0x100eb274` (+0x100/+0x104 = `0x100eb374` ← 0) and the sound record of the notice-post template
   `0x100eb3bc` (+0x0c = `0x100eb3c8` ← `'none'`,100,100,100,1.0,1.0)". NR 7 closes: the image
   values x = y = 0, face `none`, scale 1.0 are the runtime values.
8. **front-end.md role row `FUN_100228d0` (l. 404) + function-roles.md (l. 390):** "static init of
   the scores symbol template (`0x100e8964`)" → "static init of the TU's draw template `0x100e891c`
   (clip), `"nonenone"` pair `0x100e8904`, text-settings template `0x100e8968` (+0x100/+0x104 ← 0 only)
   and notice-post template `0x100e8ab0` (sound record)". Also front-end.md §4.2 (l. 240): the
   template is at **`0x100e8968`** (r2+0x2638), not `0x100e8964` (decompile −4 copy-loop artefact),
   and its image values (face `none`) are the runtime values — the "runtime values unverified"
   caution can be removed.
Not conflicts but refinements: units-movement.md `FUN_100125b0` row (it writes +8/+0xc of the
`"nonenone"` object `0x100e618c`); damage-health-death.md NR 2 addresses (`0x100e64b0`, `0x100eb41c`);
sprite-geometry-draw.md §3.1 "any command builder that keeps the template clip" — ⚑ corrected (review wave 3, 2026-10-06) #C2: was "no
builder read keeps it"; the text builders and the level-select strip keep it when +0x10d ≠ 0 (§4.3).

## Worked example — the sprite draw template, image → `FUN_10014120` → entity draw
1. **Image** (`b(0x100e63e4,0x4c)` from `100de330.bin`):
   `+00 00000000 +04 00000000 +08 00000000 +0c 6e6f6e65('none') +10 00000000 +14 00000000
   +18 3f800000(1.0) +1c 00000000 +20 00000000 +24 00000000 +28 00000000 +2c 00000000
   +30 07000000 +34 7fff0000 +38..+48 00000000`.
2. **`FUN_10014120`** (`$W/disasm-w3s2.txt`; slots resolved from the image: `0x100df0dc` →
   `0x100d6778`, `0x100df0ec` → `0x100d6788`, `0x100df0d8` → `0x100d6798`; code-image bytes
   `0x100d6778` = `00000000 00000000`, `0x100d6788` = `00000000 00000000 000001e0 000001a0`,
   `0x100d6798` = 16 × `00`):
   ```
   10014120 lwz r3,-0x7254(r2) ; 10014128 lwz r7,0x0(r3) ; 10014130 lwz r6,0x4(r3)
   1001412c addi r8,r2,0xb4                          ; r8 = 0x100e63e4
   10014134 stw r7,0x4(r8) ; 1001413c stw r6,0x8(r8) ; +0x04/+0x08 <- 0, 0
   10014124 lwz r4,-0x7244(r2)
   10014138 lwz r0,0x0(r4) ; 10014144 stw r0,0x20(r8) ; +0x20 <- 0
   10014140 lwz r3,0x4(r4) ; 1001414c stw r3,0x24(r8) ; +0x24 <- 0
   10014148 lwz r0,0x8(r4) ; 10014154 stw r0,0x28(r8) ; +0x28 <- 0x1e0 = 480
   10014158 lwz r0,0xc(r4) ; 10014160 stw r0,0x2c(r8) ; +0x2c <- 0x1a0 = 416
   10014150 lwz r5,-0x7258(r2) ; 1001415c/64/74/7c lwz ; 10014168/70/80/8c stw 0x38/0x3c/0x40/0x44(r8) ; <- 0
   1001416c addi r3,r2,0x100 ; 10014178 stw r7,0x8(r3) ; 10014190 stw r6,0xc(r3) ; "nonenone" 0x100e6430 +8/+0xc <- 0
   ```
3. **Runtime template** = image with +0x28 = 480 and +0x2c = 416. Nothing writes it again (§4.2).
4. **Entity draw `FUN_10012fa0`** copies it to the stack command at r1+0x38: `10013000 addi
   r4,r2,0xb4; 10013004 li r0,0x9; 10013008 mtspr CTR,r0; 1001300c addi r6,r1,0x34; 10013010 subi
   r5,r4,0x4`, loop `10013018 lwz r4,0x4(r5); 1001301c lwzu r0,0x8(r5); 10013020 stw r4,0x4(r6);
   10013024 stwu r0,0x8(r6); 10013028 bdnz` (9 × 8 = 0x48 B) + `1001302c/10013034 lhz`,
   `1001303c/10013040 sth` (+0x48/+0x4a) = 0x4c bytes. Then it overwrites, from the entity e (r25):
   | cmd field | store | source |
   |---|---|---|
   | +0x00 frame ptr | `10013048 stw r0,0x38(r1)` | e+0x50 |
   | +0x0c sprite ID / +0x10 frame | `10013050 stw 0x44(r1)` / `10013058 stw 0x48(r1)` | e+0x1c / e+0x20 |
   | +0x04 x | `10013074 stw r0,0x3c(r1)` | trunc(e+0x0) − hOffset + (32 if e+0x36) |
   | +0x08 y | `1001308c stw r0,0x40(r1)` | trunc(e+0x4) + windowTop if e+0x36 |
   | +0x18 scale | `10013094 stfs f0,0x50(r1)` | e+0x84 |
   | +0x20..+0x2c clip | `1001309c`, `100130a4`, `100130ac`, `100130b4` | e+0x3c, +0x40, +0x44, +0x48 |
   | +0x31 draw-now | `100130bc stb r0,0x69(r1)` | e+0x35 |
   So for an entity the template contributes only **+0x14 flags = 0** (OR-ed later), **+0x1c alpha
   = 0** (set only when visibility ≠ 100), **+0x30 layer = 7** (until the 4CC table, sprite §6),
   **+0x34 colour = 0x7fff**, +0x32/+0x33 and +0x38..+0x4b = 0. The static-init change (clip
   480/416) never reaches an entity draw: the clip is the entity's own +0x3c rect (default
   {0,0,480,416} from `FUN_10012650`, sprite §0 — the same numbers by another route).
   Example: an entity at e+0x0 = 100.7, e+0x4 = 50.2, e+0x18 = 0, e+0x36 = 0 gives x = 100,
   y = 50 (`fctiwz` truncation, `10013060`, `1001307c`), scale = e+0x84, layer 7 → table, colour
   0x7fff, clip = e's rect.

## NOT RESOLVED (this file)
1. MSL stream constructors below `FUN_1005a350`/`FUN_1005a8a0` (`FUN_1005cf20`, `1005e0d0`,
   `1005c080`, `1005ebc0`, `1005d0f0`, `1005ecc0`, `1005b6b0`, `1005bb70`, `10061bd0`, `10059f40`,
   `1005a0b0`) not read; their writes are bounded to MSL objects only by argument tracing and by the
   r2-based writer scan (none touches a game global). Indirect (virtual) calls in them are not
   covered by callers.txt — the only residue on INDEX #39. Settle: read `FUN_1005cf20` and
   `FUN_1005e0d0` listings for `bctrl`.
2. ~~Clip source not traced in `FUN_1002f7a0` (template `0x100eaddc`) and in the text functions
   `FUN_1000d7f0`, `FUN_1000db90`, `FUN_1000df00`, `FUN_1000e670` (template `0x100e5298`). Only if one
   of them keeps the template clip does the 480/416 change reach the screen. Settle: find the store to
   cmd+0x20..+0x2c or the `addi rX,r1,cmd+0x20; bl 0x1000a530` in each (text: text-metrics-lists.md).~~ →
   ⚑ corrected (review wave 3, 2026-10-06) #C2 / INDEX #59: §4.3 — all five traced; the four text functions keep the clip iff +0x10d ≠ 0,
   the `FUN_1002f7a0` `COST` strip always keeps it. Residue (INDEX #59): whether that level-select
   strip rect reaches x ≥ 416 or y ≥ 480 (and whether the `COST` leaf honours the clip) [open].
3. ~~Who reads display-object D+0x4c (set to 1 by `FUN_1000ad00`, image 0). Settle: r31-relative
   `lbz …,0x4c(` scan in the display functions `FUN_1000ae20…FUN_1000b9a0`.~~ → ⚑ corrected (review wave 3, 2026-10-06) #C5 / S:
   display-window-present.md §4 table and §7: D+0x4c = cursor visible, read/written by
   `FUN_1000b6e0` (HideCursor if set), `FUN_1000b730` (ShowCursor if clear), `FUN_1000b780`.
4. ~~The 0x1-byte object `0x100f7be8` (`FUN_10010ca0` ctor, dtor TVector `0x100e08e0` → `0x10010cb0`)
   and the guarded MSL objects of `FUN_10061b30`/`FUN_100623e0` are not identified.~~ → ⚑ corrected (review wave 3, 2026-10-06) #C5 / S:
   app-pak-music-library.md §6: `0x100f7be8` is the Registration object (`FUN_10010ca0` ctor,
   `10010ca0 li r0,0; stb r0,0(r3)`: +0 initialised = 0). Residue: the two guarded MSL objects stay
   unidentified (library, no game effect) [LOW].
5. A store into a template through a pointer formed without `addi rX,r2,…` or a TOC slot (e.g.
   `addis`) is not excluded by §4.2's scan; none was seen in the 40 functions read.

## Role-table rows (for merge)
| `entry` | (MW runtime) | PEF main symbol (`__start`): zero back-chain, register fragment (`FUN_1004b2b0`), static inits `FUN_10000000`, `main` `FUN_100000a0`, `exit` `FUN_1004db30` | HIGH | listing `1004d540..1004d5b4`; PEF loader main = TVector `0x100e0a90`, init/term −1 |
| `FUN_1004d520` | (MW runtime) | zero the stack back-chain word | HIGH | `1004d520 li r3,0; stw r3,0x0(r1)` |
| `FUN_1004d530` | (MW runtime) | return TOC (r2) | HIGH | `1004d530 or r3,r2,r2` |
| `FUN_1004b2b0` | (MW runtime) | register code/data/exception-table ranges + TOC in a 32 × 0x1c record list (`0x100e02c8`); Gestalt `'ppcf'` flag `0x100e02c0` | MED | listing `1004b2b0..1004b400` (static-init-audit.md §1.1) |
| `FUN_10000000` | (static init) | static-initialiser dispatcher: 32 TU `__sinit` calls, once, before `main` | HIGH | listing `10000000..10000098`; raw `bl` scan (only caller `entry`) |
| ⚑ corrected `FUN_10000750` | (static init) | TU init: D `0x100e24d0`, R `0x100e251c`, P `0x100e2690`, T `0x100e2548`, S `0x100e26b8`; constructs display object `0x100f7bf8` (`FUN_1000ad00`) and byte object `0x100f7be8` (`FUN_10010ca0`), registers both destructors | HIGH | listing `10000750..1000088c`; interpreter (static-init-audit.md §3); was "no row" |
| `FUN_1000ad00` | G_Display (ctor) | display-object constructor: zero fields, +0x4c = +0x4e = 1 | HIGH | listing `1000ad00..1000ad48` |
| `FUN_10010ca0` | (ctor) | 1-byte object ← 0 | HIGH | listing |
| `FUN_1004cfa0` | (MW runtime) | register a global destructor: node {next, dtor, obj} at chain head `0x1011bddc` | HIGH | listing `1004cfa0..1004cfb8` |
| `FUN_10009a20` | (ctor) | zero a 0x30-byte buffer-holder object (12 words) | HIGH | listing `10009a20..10009a54`; callers `FUN_10009980`, `FUN_100099c0` |
| `FUN_10004520` / `FUN_100125b0` / `FUN_1002aa70` | (static init) | TU init: only a `"nonenone"` pair +8/+0xc ← 0 (`0x100e2bac` / `0x100e618c` / `0x100e99d4`); values = image | HIGH | listings; interpreter |
| `FUN_100092a0` | (static init) | TU init: D `0x100e3ad0`, R `0x100e3ca4` (+0x24 ← −1), P `0x100e3c64`, T `0x100e3b1c`, S `0x100e3c8c` | HIGH | listing; interpreter |
| `FUN_1000ca10` / `FUN_1000f720` / `FUN_1002da40` / `FUN_1002e280` / `FUN_10026100` | (static init) | TU init: D + T only (`0x100e46fc`/`4748`, `0x100e5298`/`52e4`, `0x100ea86c`/`a8b8`, `0x100eabe8`/`ac34`, `0x100e8f94`/`8fe0`) | HIGH | listings; interpreter |
| `FUN_100108e0` | (static init) | TU init: D `0x100e5a70`, R `0x100e5a44`, S `0x100e5a2c` | HIGH | listing; interpreter |
| `FUN_10014120` | (static init) | (row unchanged; confirmed) | HIGH | listing; interpreter |
| ⚑ corrected `FUN_10017f80` | (static init) | TU init: R `0x100e64b0` (+0x24 ← −1), D `0x100e64dc`, P `0x100e6688`, T `0x100e6540`, S `0x100e6528` | HIGH | listing; interpreter; was MED "static init (incl. spawn-request template `0x100e64b0`)" |
| ⚑ corrected `FUN_10018670` | (static init) | TU init: D `0x100e6844`, P `0x100e69d8`, T `0x100e6890`, S `0x100e6a00` | HIGH | listing; was LOW "static initialiser" |
| `FUN_1001b760` / `FUN_1001d570` / `FUN_1001f0d0` / `FUN_1001f750` / `FUN_10020cf0` / `FUN_100428b0` / `FUN_100448b0` | (static init) | TU init: D only (`0x100e6a90`, `7ad4`, `7b20`, `7c48`, `7cd0`, `0x100ecfc4`, `0x100efdb0`; `FUN_100448b0` also S `0x100efd98`) | HIGH | listings; interpreter |
| ⚑ corrected `FUN_100228d0` | (static init) | TU init: D `0x100e891c`, P `0x100e8ab0`, T `0x100e8968` (the scores text-settings template; +0x100/+0x104 only), S `0x100e8904` | HIGH | listing; was LOW "scores symbol template `0x100e8964`" |
| ⚑ corrected `FUN_10025b00` | (static init) | TU init: D `0x100e8bc8`, T `0x100e8c14`, S `0x100e8d5c` | HIGH | listing; was LOW |
| ⚑ corrected `FUN_1002a4f0` | (static init) | TU init: D `0x100e9188`, R `0x100e91d4` (player request, +0x24 ← −1), T `0x100e9200`, S `0x100e9170` | HIGH | listing; was LOW "spawn-request template statics" |
| ⚑ corrected `FUN_10030020` | (static init) | TU init: D `0x100eaddc`, P `0x100eaf70`, T `0x100eae28`, S `0x100eadc4`; constructs level-select global `0x1010333c` member +0x294 (`FUN_10020d60`) and registers its destructor | HIGH | listing `10030020..1003012c`; was LOW "static inits" |
| ⚑ corrected `FUN_10030e70` | (static init) | TU init: D `0x100eb038`, P `0x100eb1cc` (pause-notice template sound), T `0x100eb084`, S `0x100eb1f4` | HIGH | listing; was LOW |
| ⚑ corrected `FUN_10032b20` | (static init) | TU init: D `0x100eb228` (HUD template), P `0x100eb3bc`, T `0x100eb274` | HIGH | listing; was MED "templates `0x100eb228`, `0x100eb374`, `0x100eb3c8`" |
| ⚑ corrected `FUN_10039100` | (static init) | TU init: R `0x100eb41c` (level request, +0x24 ← −1), D `0x100eb448`, P `0x100eb5f4`, T `0x100eb4ac`, S `0x100eb494` | HIGH | listing; was LOW |
| ⚑ corrected `FUN_1003ce60` | (static init) | TU init: D `0x100eccc8`, R `0x100ecd14` (weapon request, +0x24 ← −1: `1003cf00`), S `0x100ecd40` | HIGH | listing; was MED |
| `FUN_10046680` | (MSL static init) | two `ios_base::Init`-style objects (`0x100e0280`, `0x100e027c`) → narrow/wide standard streams | MED | listing + decompile of `FUN_1005a350`/`FUN_1005a8a0` |
| `FUN_10061b30` / `FUN_100623e0` | (MSL static init) | set 1 / 3 init-guard bytes (`0x1011c3c8`; `0x1011c830..32`) | MED | listings |

## INDEX updates (for merge)
- **#56 closed** (this file §2–§5): 3 value kinds change before `main` (D clip 480/416 ×26, R +0x24 = −1
  ×7, P sound record ×9); no post-`main` writer; 49 claims swept, 41 right, 8 wrong (`## ⚑ conflicts`).
- **#39 narrowed** (§1.5, table B #31): the data image is the unpacked pidata (pre-execution) and no
  pre-`main` code writes the LCG `0x100e032c`; residue = indirect calls inside MSL stream
  constructors (NR 1) and anything in `FUN_100000e0` before the first draw (particles NR 3).
- hud-scorebar.md **NR 7 closed** (table B #6, conflict 7).
- New NR for the fix pass: NR 2 here (clip survivors in five builders).
