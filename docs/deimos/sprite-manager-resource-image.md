# Deimos Rising 1.0.6 — sprite manager lifecycle, Sprite Groups Cache, resource registry, U_Image import

**Scope (wave 4, reader w4s3).** Every function in three address ranges that the bank had not yet
read, plus the code Ghidra never made into functions inside them:
- **Sprite manager `0x10018740–0x1001b7d0`:** `FUN_10018740`, `FUN_100188d0`, `FUN_10018bf0`,
  `FUN_100193f0`, `FUN_10019ee0`, `FUN_10019fc0`, `FUN_1001a1f0`, `FUN_1001aec0`, `FUN_1001b040`,
  `FUN_1001b390`, `FUN_1001b590`, and the orphan console handlers at `1001af10` and `1001afc0`.
- **Non-blit leftovers in the blit range:** `FUN_1001d5e0`, `FUN_1001d6f0`, `FUN_1001d980`,
  `FUN_1001eea0`, `FUN_1001eeb0`, and the orphan handler at `1001f040`.
- **G_Resource / U_Image `0x1001f7c0–0x10021190`:** `FUN_1001f8d0`, `FUN_1001faf0`,
  `FUN_1001fbe0`, `FUN_1001fc30`, `FUN_10020270`, `FUN_100203e0`, `FUN_10020d60`, `FUN_10020e00`,
  `FUN_10020e60`, `FUN_10020f00`, and the orphan handlers at `100206a0`, `10020740`, `10020a20`.
  Re-checked on the way and upgraded: `FUN_1001f7c0`, `FUN_1001f950`, `FUN_1001a290`,
  `FUN_10019c00`, `FUN_100189f0`.

**OUT:**
- the static initialisers `FUN_1001b760`, `FUN_1001d570`, `FUN_1001f0d0`, `FUN_1001f750`,
  `FUN_10020cf0` (→ static-init-audit.md);
- the blitters `0x1001b7d0–0x1001e9d0` (→ blit-pixel-rules.md);
- functions already HIGH or MED in function-roles.md (`FUN_10018a40`, `FUN_10018b20`,
  `FUN_10018d20`, `FUN_10019530`/`9570`/`9ad0`/`9c10`/`9ca0`, `FUN_1001a260`/`a2a0`/`a450`/`a650`/`a6f0`/`aa90`,
  `FUN_1001d780`, `FUN_1001eec0`, the permanent-list loaders and accessors, `FUN_10020da0`,
  `FUN_10021190`). I opened these only where my functions depend on them.

This is a code reading. Nothing here was checked against the running game. One data check was
run (§6.3).

Raw listings:
- `$W/disasm-w4s3.txt` (DisasmFuncs, 30 functions);
- `$W/disasm-w4s3-range.txt` (DisasmRange over `10018740:1001b7d0 1001d570:1001d9f0 1001ee80:1001eec0 1001f750:10021190`);
- `$W/disasm-w4s3-range2.txt` (`1001efa0:1001f140`).

All from the private copy `$W/work-w4s3`, where `$W` = `/Users/andiyar/ghidra-proj-deimos`. Scratch
scripts are `$W/w4s3-*.py`.

## 0. Constant resolution

All values were read with `$W/w4s3-rd.py` (big-endian; data image at ≥ 0x100de330, code image below;
TOC r2 = 0x100e6330). The method: `python3 -c "…r.u32(slot)…r.cs(addr)"`. An r2 displacement d
resolves to the address `0x100e6330 + d`.

| r2 disp | address | meaning | image value | runtime writers (§3.2 scan) |
|---|---|---|---|---|
| −0x61c0 | `0x100e0170` | port index for flag-8 (terrain) draws | 1 | `FUN_10019c00` `10019c04` (writes 1) |
| −0x61bf | `0x100e0171` | sprite FX on (visibility, highlight, tint, scale) | 1 | only the FX handler `1001afdc` |
| −0x61be | `0x100e0172` | alpha maps in scaled blits | 1 | only `FUN_1001a290` `1001a290` |
| −0x61bc | `0x100e0174` | `sPriv_CachePtr` (whole cache file buffer) | 0 | init, reader, teardown |
| −0x61b8 | `0x100e0178` | write the Sprite Groups Cache at shutdown | 0 | cache loader/reader |
| −0x61b7 | `0x100e0179` | port index for normal draws | 0 | `FUN_10019c00` `10019c00` (writes 0) |
| −0x61b4 | `0x100e017c` | `sPriv_GroupListPtr` (linked list of groups) | 0 | init, teardown |
| −0x61b0 | `0x100e0180` | sprite manager initialised | 0 | init / teardown |
| −0x61af | `0x100e0181` | alpha maps in unscaled blits | 1 | only the ALPHA handler `1001f060` |
| −0x61ac / −0x61a8 | `0x100e0184` / `0x100e0188` | alpha-analysis / encoding pixel buffers | 0 | `FUN_1001d5e0`/`d6f0` |
| −0x61a0 | `0x100e0190` | blitter initialised | 0 | `FUN_1001d5e0`/`d6f0` |
| −0x6194 | `0x100e019c` | resource manager initialised | — | `FUN_1001f7c0`/`f8d0` |
| −0x61cc / −0x61c8 / −0x61c4 | `0x100e0164/68/6c` | → `" IA"`, `" IC"`, `"Sprite Groups Cache"` | | |
| −0x719c / −0x7198 | slots `0x100df194/198` | → `0x100ffd24` (16 render-list ptrs), `0x100ffce4` (16 counts) | | |
| −0x715c | slot `0x100df1d4` | → `0x100d6d8c` = int {300, 256} | | |

Other handler and string addresses:

| TVector | code | registered as |
|---|---|---|
| `0x100e0910` (slot `0x100df190`) | `1001af10` | `LOGSPRITE` |
| `0x100e0908` (slot `0x100df18c`) | `1001afc0` | `FX` |
| `0x100e0918` (slot `0x100df1d0`) | `1001f040` | `ALPHA` |
| `0x100e0930` (slot `0x100df228`) | `100206a0` | `RESLOG` |
| `0x100e0928` (slot `0x100df224`) | `10020740` | `LOGUNUSEDSPRITES` |
| `0x100e0920` (slot `0x100df220`) | `10020a20` | `LOGUNUSEDSOUNDS` |

- String bases: U_Sprite `r2+0x7ac` = `0x100e6adc`; U_SpriteBlit `r2+0x183c` = `0x100e7b6c`;
  G_Resource `r2+0x19ec` = `0x100e7d1c`; U_Image `r2+0x22f0` = `0x100e8620`.
- Path format: `FUN_10048560(dir, name, buf, 1)` uses the format table at `*0x100df59c` =
  `0x100f03e4`: `+0x4f` `"%s%s%s%s"` and `+0x4d` `":"`. The result is
  **`": Data:<name>"`**, a path relative to the application folder; the folder name begins with a
  space.

## 1. Sprite manager lifecycle (U_Sprite.cc, U_SpriteBlit.cc)

### 1.1 `FUN_10018740(normalPort, terrainPort) @ 10018740` — sprite manager init [HIGH]
Called once from app init: `FUN_100000e0` calls `FUN_10018740(0, 1)` after the display is set up.
In order:
1. `FUN_1003a870("Sprite", 1)` (the U_Manager "Manager Init: %s" log).
2. `0x100e0180 ← 1` (`1001877c stb r3,-0x61b0(r2)`).
3. `0x100e0174 ← 0` (`10018784 stw r0,-0x61bc(r2)`).
4. `FUN_10019c00(r3, r4)`, which writes `0x100e0179 ← 0` and `0x100e0170 ← 1`. These are the same
   values as the image.
5. Any old group list is freed (`FUN_100008b0(list, 1)`). A new 0xc-byte list header is made
   (`FUN_1004d320(0xc)` + `FUN_10000890`, which zeroes 3 words). On failure it asserts
   `sPriv_GroupListPtr` (U_Sprite.cc line 0x9d).
6. For each of the 16 layers (`1001885c cmpwi r26,0x10`):
   - count ← 0;
   - free the old list;
   - allocate **0x251c0 bytes** cleared (`10018824 addi r3,r31,0x51c0` with `r31 = 0x20000`,
     `li r4,0x1`; `bl 0x1000cb60`). 0x251c0 / 0x4c = **2000 draw commands** per layer to start
     with [HIGH — ⚑ corrected (review wave 3, 2026-10-06) #M6: was MED; `100187f8 lis r31,0x2; 10018824 addi r3,r31,0x51c0` =
     0x251c0 = 2000 × 0x4c, as blit-pixel-rules.md §7.1 states];
   - on failure it asserts `sPriv_RenderListPtrs[i]` (line 0xac).
7. `FUN_1001d5e0()`, the blitter init (§1.3).
8. Registers `LOGSPRITE` and `FX` with `FUN_1002d080(name, help, TV, 1, **1**, 0)`
   (`1001887c li r6,0x1; 10018880 li r7,0x1` and `1001889c/100188a0`). r7 is the debugOnly flag, so
   **neither command exists in 1.0.6** (`FUN_1002d080` skips debugOnly ≠ 0:
   messages-notices-console.md §5.2).

### 1.2 `FUN_100188d0() @ 100188d0` — sprite manager teardown [HIGH]
Called from the shutdown sequence `FUN_10000630`. It logs "Manager Termination" (`FUN_1003a900`).
If initialised (`10018908 lbz r0,-0x61b0(r2)`), it does the following:
1. If a group list exists:
   - if `0x100e0178` ≠ 0, write the cache: `1001892c bl 0x1001b390` (§4.4);
   - unload every group: `FUN_100193f0('none', 1)` (`10018930..1001893c`);
   - delete the list;
   - free the cache-file buffer `0x100e0174` (`10018964..1001897c`).
2. For all 16 layers, zero the count and free the list (`10018990..100189bc`).
3. `0x100e0180 ← 0`.
4. `FUN_1001d6f0()` (blitter teardown).

### 1.3 Blitter work buffers — `FUN_1001d5e0`, `FUN_1001d6f0`, `FUN_1001d980`, `FUN_1001eea0`, `FUN_1001eeb0` [HIGH]

| function | role | evidence |
|---|---|---|
| `FUN_1001d5e0 @ 1001d5e0` | **Blitter init** (from `FUN_10018740`). `FUN_1003a870("Blitter")`, `0x100e0190 ← 1`. Two 0x30-byte pixel-buffer objects (`FUN_1004d320(0x30)`), each made **300 × 256 × 16-bit** by `FUN_100099c0(buf, 300, 256, 16, 0)`, become the "encoding buffer" `0x100e0188` and the "alpha-analysis buffer" `0x100e0184`. Failure asserts `sPriv_Buffer` / `sPriv_AlphaBuffer` (U_SpriteBlit.cc 0x3c / 0x41). Then it registers `ALPHA` with debugOnly = 1 (`1001d6c0 li r7,0x1`), so ALPHA is never registered. | `1001d5f4 lwz r30,-0x715c(r2)` → {300, 256}; `1001d62c lwz r4,0x0(r30); 1001d630 li r6,0x10; 1001d634 lwz r5,0x4(r30)`; `1001d648 stw r29,-0x61a8(r2)`, `1001d694 stw r29,-0x61ac(r2)` |
| `FUN_1001d6f0 @ 1001d6f0` | **Blitter teardown**. If `0x100e0190` is set: clear it, then `FUN_10009a60(buf, 1)` (dispose the GWorld and delete) on both buffers, nulling the globals | `1001d710..1001d760` |
| `FUN_1001d980(w, h) @ 1001d980` | resize both buffers to w × h × 16. `FUN_10009d70` recreates a GWorld only when w, h or depth differ. Called by the group loader `FUN_10018d20` when a frame's size differs from the last one | `1001d9a0 li r6,0x10; 1001d9a8 lwz r3,-0x61a8(r2); bl 0x10009d70`, and again with `-0x61ac` |
| `FUN_1001eea0 @ 1001eea0` | return the encoding buffer `0x100e0188` | `1001eea0 lwz r3,-0x61a8(r2); blr` |
| `FUN_1001eeb0 @ 1001eeb0` | return the alpha-analysis buffer `0x100e0184` | `1001eeb0 lwz r3,-0x61ac(r2); blr` |

**Replica note.** These buffers only stage plate rectangles for the frame encoder
`FUN_1001d780`. The colour rect is CopyBits'd into the encoding buffer and the 16-bit alpha-plate
rect into the analysis buffer (`FUN_10018d20`, dump lines around `FUN_1001eeb0`/`FUN_1001eea0`).
They have no visible effect.

## 2. Group list queries and helpers

The group record is 0x10 bytes. The layout is the same in memory and in the cache (§4):

| off | type | meaning |
|---|---|---|
| +0x0 | u32 | magic `0x499602d2` |
| +0x4 | 4CC | group id (`bocr`) |
| +0x8 | int | frame count |
| +0xc | ptr | array of `count` pointers to encoded frame blocks (sprite-sound-containers.md §2.3a) |

| function | role | label | evidence |
|---|---|---|---|
| `FUN_100193f0(id, all) @ 100193f0` | **Unload group(s).** `id == 'none'` with `all == 0` does nothing. Otherwise it walks the group list. For each group whose id matches (or every group when `all ≠ 0`): unlink the node (`FUN_10000c00`), free each frame block, free the frame array, delete the record. With `all == 0` it stops after the first match. Callers: teardown (`'none', 1`) and `FUN_1001faf0` (`id, 0`) | HIGH | `10019404 subis r0,r30,0x6e6f; cmplwi r0,0x6e65`; `10019468 lwz r0,0x4(r24); cmpw r0,r30`; `100194b8..100194dc` frame loop over `+0x8`/`+0xc`; `10019500 bl 0x1004d3b0`; `10019508 rlwinm. r0,r31…; beq` exit |
| `FUN_10019ee0(id) @ 10019ee0` | **Frame count of a group** (`+0x8`), or 0. When the group is not in the list it logs "\nRESOURCE: Sprite Group '%s' not loaded." `'none'` gives 0 with no log. Used to range-check frame numbers by `FUN_10019ca0` (error log) and by `FUN_10035cd0` (spawn frame: `f < 0` or `f ≥ count` becomes frame 0, dump `FUN_10035cd0` l. 131–137) | HIGH | `10019f54 lwz r0,0x4(r3); cmpw r0,r27`; `10019f60 lwz r30,0x8(r3)`; `10019f9c addi r3,r3,0xa67` = `0x100e7543` |
| `FUN_10019fc0(id) @ 10019fc0` | **LOGSPRITE body.** If the group is loaded, it logs a dashed block: "Information for Sprite Group '%s'", "Number of frames in group: %i", and per frame "Frame Num %i, Width: %i, Height: %i[, Has Alpha Map]". The sizes come from `FUN_10019ca0(id, n, &wh, 1.0)`; the alpha flag is block `+0x12`. It then posts "Info Logged for Sprite Group '%s'" (message type 0). Otherwise it logs "Cannot log info … not available" (no `im08` tag) or "… not loaded", and posts "Unknown Sprite Group '%s'" / "Sprite Group '%s' not loaded" (type 1). Reached only from the unregistered LOGSPRITE handler (§3.1) | HIGH | `1001a0a8 lfs f1,0x0(r28)` with r28 = slot `−0x71a8` → 1.0; `1001a0b8 bl 0x10019ca0`; `1001a0f4 lbz r0,0x12(r31)`; `1001a024 bl 0x10001f20` (tag exists); `1001a17c`/`1001a1cc bl 0x1002dbd0` with r4 = 0 / 1 |
| `FUN_1001a1f0(char *s) @ 1001a1f0` | Cuts a tag name at `" IA"` and at `" IC"`: `strstr` → write NUL. Used by `FUN_1001fe60` to turn "Bomb Crater IC" into "Bomb Crater" for the loading-screen line ("%s%s" → `FUN_10023040`) while the 8 permanent sprites load | HIGH | `1001a204 lwz r4,-0x61cc(r2)` (" IA"); `1001a208 bl 0x10057a30`; `1001a21c stb r0,0x0(r3)`; same with `-0x61c8` (" IC"); caller dump `FUN_1001fe60` l. 35–39 |
| `FUN_1001aec0(list) @ 1001aec0` | Drains a linked list. `while ((p = FUN_10000d90(list)) != 0) delete p`. `FUN_10000d90` = remove the first node and return its data. Used by `FUN_10018d20` to free the frame-rect list built by the plate scan, before deleting the list itself | MED (list helper `FUN_10000d90` read in the dump only) | `1001aed8 bl 0x10000d90; cmplwi r3,0; beq; bl 0x1004d3b0; b 0x1001aed8` |

## 3. Debug console commands and the three draw switches (closes sprite-geometry-draw.md NR 3, INDEX #9 residue)

### 3.1 The six commands registered in this range — all debugOnly, none exist in 1.0.6 [HIGH]
Each of these is passed to `FUN_1002d080(name, help, TV, 1, 1, 0)`, so r7 (debugOnly) = 1. The
listing lines: `1001887c/80`, `1001889c/a0`, `1001d6bc/c0`, `1001f858/5c`, `1001f878/7c`,
`1001f898/9c`. Ghidra made none of the handlers into functions; I read them from the range
listings.

| command | help text | handler | what it does |
|---|---|---|---|
| `LOGSPRITE` | "Given a Sprite ID (e.g. 'pork'), logs the details of that Sprite Group to file." | `1001af10` | Duplicates the argument (`FUN_100462e0`), then `strtok` on `'` twice (`FUN_100578f0`). Success → `FUN_100140b0` (string → 4CC) → `FUN_10019fc0`. Failure → posts "Syntax Error (LOGSPRITE 'xxxx')" (type 1). Returns 1 / 0 |
| `FX` | "Toggles the drawing of special effects such as visibility, highlighting, colorisation and scaling." | `1001afc0` | `0x100e0171 ← !0x100e0171` (`1001afd0 lbz; cntlzw; rlwinm …,27,5,31; 1001afdc stb r0,-0x61bf(r2)`). Then posts "Sprite FX Enabled" / "Sprite FX Disabled" |
| `ALPHA` | "Toggles the use of the alpha channel when drawing sprites." | `1001f040` | `0x100e0181 ← !0x100e0181` (`1001f054..1001f060 stb r3,-0x61af(r2)`). Then `FUN_1001a290(new)` copies the same value into `0x100e0172` (`1001f064 bl 0x1001a290`; `1001a290 stb r3,-0x61be(r2)`). Posts "Sprite Alpha Drawing Enabled/Disabled" |
| `RESLOG` | "Logs all loaded Game Resources to file." | `100206a0` | Logs a banner, then "Permanent Resources Loaded:" `FUN_10020270(0)`, "Temporary …" `(2)`, "Level …" `(1)`. Posts "Resources Logged to File" |
| `LOGUNUSEDSPRITES` | "Logs all unused Sprite Resources to file." | `10020740` | Builds an id list: the 8 permanent sprite ids (table `*0x100df214` = `0x10101524`, loop `100207f0 cmpwi r27,0x8`), plus the sprite ids referenced by `FUN_1003f0b0`, `FUN_10039a80`, `FUN_1002b400` (flag 1). Then enumerates every `im08` tag (`FUN_10002340`) and logs "ID: '%s', File: \"%s\"" for each tag not in the list. Posts "No Unused Sprites Found" / "Unused Sprite Refs Found: %i" |
| `LOGUNUSEDSOUNDS` | "Logs all unused Sound Resources to file." | `10020a20` | The same for `soun`: 24 permanent sound ids (`*0x100df210`, `10020ac8 cmpwi r26,0x18`), the same three collectors with flag 0, and tags whose name contains "Music" skipped (`10020b24 addi r4,r31,0x850; bl 0x10057a30`) |

The three collector callees (`FUN_1003f0b0`, `FUN_10039a80`, `FUN_1002b400`) were not read by me.
They are labelled by call pattern only [LOW]. That does not matter: the commands are unreachable.

### 3.2 Writers of the three switches: exhaustive scan [HIGH]
`$W/w4s3-stbscan.py` scans the whole code image for D-form instructions with RA = r2. The mask:
primary opcode = `w >> 26` ∈ {38 stb, 39 stbu, 34 lbz, 35 lbzu, 36 stw, 37 stwu, 32 lwz,
14 addi}; RA = `(w >> 16) & 31` = 2; D = sign-extended `w & 0xffff`. It keeps the hits whose
`0x100e6330 + D` is a sprite global. A second pass lists every `addi rD,r2,D` whose result falls in
`0x100e0160..0x100e01a0`. The only hit is `1001fde8` → `0x100e0194` (the permanent-list area, not
a switch). `$W/w4s3-ptrscan.py` finds no data or code word equal to any address
`0x100e0170..0x100e0181`, so no pointer-based writes exist either.

| global | every store in the code image |
|---|---|
| `0x100e0171` (FX) | `1001afdc` (FX handler) only |
| `0x100e0172` (scaled alpha) | `1001a290` (`FUN_1001a290`). Its only caller is `1001f064` (ALPHA handler): `w4s3-ptrscan.py` lists every `bl` to it |
| `0x100e0181` (unscaled alpha) | `1001f060` (ALPHA handler) only |

The handler TVectors `0x100e0908/0910/0918` are referenced only by the three registration loads
(`10018870`, `10018890`, `1001d6b0`). **Therefore all three switches keep their image value 1 for
the whole 1.0.6 session.** Sprite FX are always on and alpha maps are always used, in both the
scaled and the unscaled path. No static initialiser writes them (the scan covers `FUN_10000000`'s
callees too). Replica: hard-wire all three on; the `DAT_100e0171 == 0` branch of `FUN_10018a40`
(alpha 0, scale 1) is dead code.
This agrees with the independent store scan in blit-pixel-rules.md §6 (w3s1, written in parallel).
That reader found the same two handlers; this file adds the debugOnly registration proof.

## 4. Sprite Groups Cache (` Data:Sprite Groups Cache`, type `Data`, creator `Deim`)

### 4.1 Load policy — `FUN_10018bf0() @ 10018bf0` [HIGH]
Called once from app init (`FUN_100000e0`), just after the publisher logo is shown.
1. `FUN_1001b040()` (reader, §4.3). If it returns 1, log "Sprite Groups Cache loaded OK." and stop.
2. Otherwise, if **not** Mac OS X (`FUN_100461b0` = Gestalt 'sysv' ≥ 0x0A00 is false): log
   "Sprite Groups Cache not loaded. (Loading sprites as required.)" and set `0x100e0178 ← 0`.
   Groups then load on first use through `FUN_1001f950` / `FUN_10019ca0`.
3. On OS X, probe that the volume can be written: `fopen(": Data:Sprite Temp", "w+")`
   (`10018c34 bl 0x10048560`; `10018c44 bl 0x10050390`; mode string `0x100e6c17` = "w+").
   - It fails → "(Cannot write to this volume, skipping.)", `0x100e0178 ← 0`.
   - It succeeds → `FUN_10050140(path)`, which is MSL `remove` (it reaches `PBHDeleteSync` /
     `FSDeleteObject` via `FUN_100514f0`). The `FILE*` from `fopen` is never closed. Then log
     "(Attempting to load all Groups instead.)" and **load every `im08` tag**:
     `for i: FUN_10002340(i, 'im08', &id, name)` → `FUN_10018d20(id)`, with one OS event pumped
     per group (`FUN_10048d70`) (`10018c98..10018cd0`). `0x100e0178` keeps the 1 the reader
     set, so the cache is written at shutdown.
   - `FUN_10002340` enumerates all tags of the type without a name filter (dump), and
     `FUN_10018d20` has no lower-case guard. So the load-all path also builds a "group" for every
     upper-case alpha-plate id (e.g. `BOCR`) whose colour plate is the IA plate itself. [MED — both
     read in the dump, not by listing]

**Consequence.** On Classic Mac OS the cache never exists and sprites load lazily. On OS X the
first run loads all 250 `im08` tags at start-up and writes the cache at quit. Later runs read the
cache instead of decoding GIFs. No `Sprite Groups Cache` ships in the game folder
(unit-def-struct.md §8 lists ` Data` = HID.bundle, Icon, Local, Paks).

### 4.2 File layout [HIGH]
All integers are big-endian. The layout is a byte image of the in-memory group list.
```
off 0   int32  groupCount          = list node count (FUN_10000ce0)
off 4   int32  recordSize          = 0x10            (reader rejects anything else)
then per group, in list order:
        16 B   group record        = {0x499602d2, id 4CC, frameCount, stale frame-array pointer}
        per frame n < frameCount:
          int32  blockSize         = GetPtrSize(frame block)  (FUN_1000cc60)
          blockSize bytes          = the encoded frame block verbatim:
                                     0x18 header + w·h RGB555 + (w·h u16 alpha map if +0x12)
```
- `blockSize = 0x18 + 2wh`, plus `2wh` when the frame has an alpha map. Evidence: encoder
  `1001d7a8 mullw r30,r25,r26; rlwinm r4,r30,1; addi r3,r4,0x18; beq; add r3,r3,r4`.
- The alpha-map offset `+0x14` is relative to the block, so a block is position-independent and
  survives the round trip.
- Block byte `+0x13` is never written by the encoder from a defined value. `1001d850 stb r31,0x13(r5)`
  stores whatever the caller left in r31, and the cache preserves that byte. [HIGH for the store; the
  value is meaningless]
- File size = `8 + Σgroups (16 + Σframes (4 + blockSize))`.

### 4.3 Reader — `FUN_1001b040() @ 1001b040` → 1 loaded / 0 not [HIGH]
- Only on OS X (`1001b064 bl 0x100461b0; beq` → return 0, leaving `0x100e0178` at 0).
- Path `": Data:Sprite Groups Cache"` (`1001b074 lwz r4,-0x61c4(r2)`).
- Each of these failures sets **`0x100e0178 ← 1`** (rebuild at shutdown) and returns 0:

  | failure | log |
  |---|---|
  | `FUN_10044ce0` (FSMakeFSSpec) | "could not find cache file. It will be rebuilt." |
  | `FUN_10044f00` (PBHGetFInfoSync) returns 0 | "could not get modification date …" |
  | open `FUN_10001200(f, path, 0x11, 'Data', 'Deim')` | "FILE ERROR: Could not find/open …" |
  | read the whole file (`FUN_100014b0` size → `FUN_1000cb60(size, 1)` → `FUN_100013f0`) | "Could not read …" |
  | header word 1 ≠ 0x10 (`1001b1c4 lwz r0,0x4(r3); 1001b1d0 cmplwi r0,0x10`) | "Sprite Groups Cache Invalid. The Cache will be rebuilt. …" |

- **The modification date is fetched but never compared**: `1001b0b0 cmpwi r3,0x0; bne` is its
  only use. Unlike the Units Cache (unit-def-struct.md §8), a stale sprite cache is never
  invalidated by newer paks or local files.
- Per group (`1001b200..1001b2bc`):
  - read id `+4` and count `+8`; the stored magic `+0` and pointer `+0xc` are ignored;
  - allocate a fresh 0x10 record `{0x499602d2, id, count, FUN_1000cb60(count·4, 1)}`;
  - append it to the group list (`FUN_100009e0`).
- Per frame (`1001b2d0..1001b34c`):
  - assert `sizeOfFrame > 0` (data-error assert, line 0x942);
  - `FUN_1000cb60(size, 1)`, memcpy, store into the frame array.
- No magic, size or bounds check on frame blocks. No duplicate-id check, so a group already loaded
  would appear twice; none is loaded at that point.
- The whole file buffer stays allocated in `0x100e0174` until teardown, even though every frame is
  copied out of it.

### 4.4 Writer — `FUN_1001b390() @ 1001b390` and `FUN_1001b590(buf, size, flag) @ 1001b590` [HIGH]
`FUN_1001b390` runs from teardown when `0x100e0178 ≠ 0`.
- **Size pass** (`1001b3d8..1001b444`): start at 8; `+0x10` per node with non-null data
  (`1001b3f8 addi r28,r28,0x10`); `+4 + GetPtrSize` per frame.
- Buffer `FUN_1000cb60(size, 0)` (assert `tempData`, line 0x9c3).
- **Write pass** (`1001b478..1001b548`):
  - header `{count, 0x10}`;
  - the 16-byte record copied word by word (`1001b4bc..1001b4d8`);
  - per frame: `{size, bytes}`.
- Then `FUN_1001b590(buf, size, 1)` and free.
- Edge case: a list node with null data would still be counted in the header but emit no record.
  The list never holds one: `FUN_100009e0` is only called with fresh records.

`FUN_1001b590` is the generic "save a data file into ` Data`" helper, the sprite twin of the Units
Cache's `FUN_100426e0`.
1. Build the path; `remove(path)` (`1001b5d8 bl 0x10050140`).
2. Create with `FUN_10001200(f, path, flag ? 0x17 : 0xf, 'Data', 'Deim')` (`1001b60c li r5,0x17` /
   `1001b634 li r5,0xf`); close.
3. Reopen with the same mode and type/creator 0, 0 (`1001b684..1001b6b0`).
4. `FUN_10001430(f, buf, size)` (write); close.
5. Log "Data Saved: \"%s\"".

Error logs: "Could not create new file", "Could not open newly created file", "Could not write to
file". All of them return; none quits. The M_File helpers `FUN_10001200/1570/13a0/1430/14b0/13f0/10f0/11a0`
were read by call pattern only [HIGH for the mode semantics — ⚑ corrected (review wave 3, 2026-10-06) #M4: was MED; app-pak-music-library.md
§1.2 reads them by listing: `0x11` = "rb", `0x0f` = "a+t", `0x17` = "a+b" (`10001238..1000131c`)].

## 5. Resource registry (G_Resource.cc)

The resource record is 0xc bytes, kept in the list `0x100e0198` [HIGH]. Writes: `1001fa60 stw r0,0x0(r26)`,
`1001fa74 stb r28,0x4(r26)`, `1001fa78 stb r30,0x5(r26)`, `1001fa7c stw r29,0x8(r26)`. Reads:
`100202e4 lbz r3,0x5(r4)`, `100202f4 lbz r0,0x4(r4)`, `1002044c lbz r0,0x4(r3)`,
`10020458 lwz r0,0x8(r3)`.

| off | meaning |
|---|---|
| +0x0 | magic `0x499602d2` |
| +0x4 | u8 kind: **1 = sprite group (`im08`), 0 = sound (`soun`)** |
| +0x5 | u8 usage: **0 = permanent, 1 = level, 2 = temporary** (RESLOG labels, §3.1) |
| +0x8 | 4CC id |

| function | role | label | evidence |
|---|---|---|---|
| ⚑ upgraded `FUN_1001f7c0 @ 1001f7c0` | Resource manager init: `FUN_1003a870("Resource")`, flag `0x100e019c ← 1`, recreate the list (assert `sPriv_ListPtr`, line 99), register RESLOG / LOGUNUSEDSPRITES / LOGUNUSEDSOUNDS, all debugOnly (never registered) | HIGH | `1001f7f0 stb r0,-0x6194(r2)`; `1001f85c/7c/9c li r7,0x1` |
| ⚑ upgraded `FUN_1001f950(kind, id, usage) @ 1001f950` | **G_Res_Load.** `'none'` gives 0 silently. If a record (kind, id) exists (`FUN_100203e0`), its usage is lowered to `min(old, usage)` and the call returns 1 — it is not loaded again. Otherwise kind 1 → `FUN_10018d20(id)`; kind 0 → `FUN_10047330(id)` (sound load); any other kind → "Unknown", fail. On success it appends a record. On failure it logs "RESOURCE FAILURE: Couldn't load a %s resource. Type: %i, ID: '%s'." and returns 0 (no quit) | HIGH | `1001f974 subis r0,r29,0x6e6f; cmplwi r0,0x6e65`; `1001f9b4 cmpwi r0,0x1`; `1001fa84 lbz r0,0x5(r3); 1001fa8c cmplw r4,r0; 1001fa90 bge; 1001fa94 stb r30,0x5(r3)` |
| `FUN_1001f8d0 @ 1001f8d0` | Resource manager teardown (from `FUN_10000630`): if initialised, `FUN_1001faf0(1)` (sprites) then `FUN_1001faf0(0)` (sounds), clear the flag, delete the list | HIGH | `1001f8f0 lbz r0,-0x6194(r2)`; `1001f8fc li r3,0x1; bl 0x1001faf0`; `1001f908 li r3,0x0; bl 0x1001faf0`; `1001f91c stb` |
| `FUN_1001faf0(kind) @ 1001faf0` | Unload every registered resource of a kind: sprite → `FUN_100193f0(id, 0)`; sound → `FUN_10047510(id)`; then unlink and free the record. **No usage filter**, and its only caller is the shutdown path | HIGH | `1001fb5c lbz r3,0x4(r4); cmplw`; `1001fb88 bl 0x10047510`; `1001fb9c bl 0x100193f0`; `1001fbb0 bl 0x10000c00`; callers.txt |
| `FUN_1001fbe0(kind, id) @ 1001fbe0` | **Resource tag exists?** kind 1 → `'im08'`, kind 0 → `'soun'`, any other kind → `'im08'`; then `FUN_10001f20(type, id)`; returns its byte. Used by the data parsers `FUN_1002ba00` (weapons), `FUN_10039e70` (plde), `FUN_10041960` to validate references | HIGH | `1001fbec cmpwi r0,0x1; 1001fbf0 lis r3,0x696d; …3038`; `1001fc10 lis r3,0x736f; …756e`; `1001fc18 bl 0x10001f20` (r4 = id passes through) |
| `FUN_1001fc30(kind, id) @ 1001fc30` | **Resource registered?** (1/0) — a linear search on +4/+8. Called by the draw dispatcher `FUN_10019570` when a frame pointer is null: registered → "ERROR: Sprite Draw: invalid encoded data … frame"; not registered → "encoded data" error plus the fatal `FUN_10001040("A Sprite Group was not loaded …", 1)` | HIGH | listing `1001fc30..` (same search as `100203e0`); caller dump `FUN_10019570` l. 54–63 |
| `FUN_100203e0(kind, id) @ 100203e0` | find record (kind, id) → pointer or 0 | HIGH | `1002044c lbz r0,0x4(r3); cmplw r0,r31; 10020458 lwz r0,0x8(r3); cmpw r0,r27` |
| `FUN_10020270(usage) @ 10020270` | RESLOG body: "\n    Sprites:" then "    %s" (tag display name `FUN_10002420`) for each sprite record with that usage, then the same for "Sounds:". No direct caller: only the unregistered RESLOG handler `100206a0` reaches it | HIGH | `100202e4 lbz r3,0x5(r4)`; `100202f4 lbz r0,0x4(r4); cmplwi r0,0x1`; `10020388 cmplwi r0,0x0`; handler `100206cc li r3,0x0; bl 0x10020270` |

**Usage levels by caller** (from the dump; ⚑ corrected (review wave 3, 2026-10-06) #M5: now listing-cited — the `li r5,N` before each
`bl 0x1001f950` in the fix-pass listing `$W/disasm-review3-all.txt`: usage 0 at `1000d0a0`, `1001ff00`,
`10020078`, `10024068`, `10024098`, `100240c8`; usage 1 at `1002b798…1002b814` (6), `1002beb0`, `1002bfac`,
`100399b0…10039a0c` (5), `10039fac`, `1003a0a8`, `1003a1a4`, `1003a2a0`, `1004180c`, `100418dc`; usage 2 at
`10019d48`, `10047ce4` — 27 call sites in 11 functions):

| usage | callers |
|---|---|
| 0 (permanent) | `FUN_1001fe60` (permanent sprites and sounds), `FUN_1000d010`, `FUN_10023fd0` (front-end buttons) |
| 1 (level) | `FUN_1002b790`/`FUN_1002ba00` (weapons), `FUN_100399a0`/`FUN_10039e70` (player definitions), `FUN_100417d0`/`FUN_100418a0` |
| 2 (temporary, load on miss) | `FUN_10019ca0` (`(1, id, 2)`), `FUN_10047bf0` (`(0, id, 2)`) |

[HIGH for the arguments (listing, above); MED for the caller roles of `FUN_1000d010`/`100417d0`/`100418a0`, which I
did not read]

**Replica consequence** [HIGH, direct callers only]: nothing unloads a resource by usage during a
session. Groups and sounds loaded for a level stay resident until quit. The usage byte only labels
the debug log.

## 6. U_Image import (U_Image.cc) and TGA orientation (INDEX #10)

### 6.1 Functions [HIGH]
| function | role | evidence |
|---|---|---|
| `FUN_10020d60(img) @ 10020d60` | U_Image constructor: `FUN_10009980(img)` (pixel-buffer object init), returns img. Callers `FUN_1002e310` and the static initialiser `FUN_10030020` (a global image object) | `10020d74 bl 0x10009980` |
| `FUN_10020e00(img, flags) @ 10020e00` | U_Image destructor: `FUN_10009a60(img, 0)` (dispose the GWorld, no delete), then `delete img` if flags > 0. Every caller passes −1, which means a stack/embedded object with no delete | `10020e20 li r4,0x0; bl 0x10009a60`; `10020e38 bl 0x1004d3b0` |
| `FUN_10020e60(img, id, type) @ 10020e60` | **U_Image_LoadInBuffer.** A buffer still holding a GWorld logs "DEBUG: Image not disposed of before loading new data. Bad style." and is disposed. Then `FUN_10020f00(id, img, type)`. Failure → `FUN_10000f30("U_Image_LoadInBuffer(id, this, imageType)", "U_Image.cc", 0x37)`, the FILE ERROR assert | `10020e8c lwz r0,0x0(r3); cmplwi`; `10020ebc bl 0x10020f00`; `10020ed4 li r5,0x37; bl 0x10000f30` |
| `FUN_10020f00(id, img, type) @ 10020f00` | **QuickTime import into an image object** (sequence below). Sole caller `FUN_10020e60`, so every TGA the game loads goes through here: map, mask, menu, scorebar, previews | listing below |

`FUN_10020f00` in order:
1. Container: `'im08'` if type is `'GIF '` or `'BMP '`, else `'im16'`. Get the tag bytes as a handle
   (`FUN_10002a20`).
2. `OpenADefaultComponent('grip', type)` → `GraphicsImportSetDataHandle` →
   `GraphicsImportGetImageDescription`.
3. TGA whose ImageDescription depth `+0x52` ≠ 16 → "FILE WARNING: unsupported pixel depth (%i) in
   file \"%s\"", and it carries on.
4. **Create the GWorld at the file's own size and depth:** `FUN_10009bd0(img, desc+0x20 width,
   desc+0x22 height, desc+0x52 depth, 0)`. This is SetRect, NewGWorld (`FUN_10045010`),
   LockPixels, SetGWorld, **EraseRect**, cache base/rowBytes.
5. `DisposeHandle(desc)`; `GraphicsImportSetGWorld(gi, port, 0)`; `GraphicsImportDraw(gi)`.
6. Free the tag handle (`FUN_1000cd00`); `CloseComponent`.
7. Every error logs "ERROR %i: couldn't …" and returns 0. The caller then asserts.

Listing: `10021048 subis r0,r27,0x5447; cmplwi r0,0x4120`; `1002105c lha r0,0x52(r3); cmpwi r0,0x10`;
`100210a4 lha r4,0x20(r6); lha r5,0x22(r6); lha r6,0x52(r6); bl 0x10009bd0`; glue stubs `100d55d4`
(OpenADefaultComponent), `100d5634` (SetGWorld), `100d564c` (Draw). The ImageDescription offsets
are the QuickTime layout: width 0x20, height 0x22, depth 0x52.

- ⚑ correction to sprite-sound-containers.md §1. That section quotes `FUN_10021190` (M_Image.cc)
  as "the" TGA/GIF import. `FUN_10021190` has **one caller, the sprite-group loader
  `FUN_10018d20`** (callers.txt), and takes the GWorld depth from its caller (8 or 16) instead of
  from the file. TGAs never reach it. The two importers share the same QuickTime sequence and
  warnings, so the §1 claims about `im08`/`im16` decoding still hold. Only the function attribution
  changes. [HIGH]
- No call to `GraphicsImportSetFlags`, `GraphicsImportSetMatrix` or `SetBoundsRect` exists in
  either importer, and neither touches the pixels after the draw. **The game does no row flip of
  its own.** [HIGH — listing: the only calls after Draw are DisposeHandle/CloseComponent/log]

### 6.2 What the media-mask reader indexes [HIGH, code]
`FUN_1000fbc0` loads both the map and the media mask through `FUN_10020da0(…, 'TGA ')`, which is
`FUN_10020e60` (dump l. 34 and 67). `FUN_1000fee0` reads
`*(u16*)(base + (y/5)·rowBytes + (x/5)·2) == 0x001f`. That is GWorld row `y/5`, counted from the
first row in memory, with no `(h−1−row)` term. Map and mask therefore land in memory with the
**same** orientation, whatever QuickTime does.

### 6.3 Data check: the files are bottom-up; map and mask agree [HIGH, tool output]
- `python3 $W/w4s3-tga.py`: `Menu[menu]`, `Canyon 1 Map[cam1]` and `Canyon 1 Media[cat1]` all have
  descriptor `0x01` (bit 5 = 0 = bottom-up rows).
- Drawing Menu's rows in **file order** (`$W/w4s3-fileorder-menu.png`) shows the "DEIMOS RISING"
  title **upside down**. The stored first row is the visual bottom.
- `python3 $W/w4s3-maskalign.py` compares cam1's mask water rows (`0x001f`) with the map's teal
  rows (`b5 > r5 + 4`, sampled at `x·5+2, y·5+2`), both in file order:

  | mask col | mask water rows | map teal rows/5 |
  |---|---|---|
  | 5 | 371–389 | 372–388 |
  | 30 | 375–391 | 377–389 |
  | 60 | 384–407 | 389–407 |
  | 90 | 421–453 | 423–450 |

  A second river matches the same way (e.g. col 5: 600–633 against 600–631). The two files are
  stored in the same orientation and aligned; there is no horizontal mirror.

**Conclusion for INDEX #10** [MED, one inferred link]: the shipped title screen reads upright, and
the game does no flip, so QuickTime's TGA importer honours descriptor bit 5. **GWorld row 0 is
the visual top** of every TGA, and the media-mask lookup indexes mask row `y/5` from the top of the
map image. Ben's eyes on the title screen settle the link. It is safe for a replica either way: decode every TGA
honouring bit 5 and index `mask[y/5][x/5]` with y in the same top-down map coordinates used to draw
the map.

## 7. Two neighbouring NOT-RESOLVED items closed on the way
- **Render lists reset (sprite-geometry-draw.md NR 2, INDEX #36)** [HIGH]:
  `FUN_100189f0 @ 100189f0` is `lwz r3,-0x7198(r2)` followed by 16 × `stw r0(=0),k(r3)` for
  k = 0…0x3c. It zeroes all 16 per-layer counts; the list memory is kept. It is called from
  begin-frame `FUN_10030360` (`10030388 bl 0x100189f0`), session start `FUN_10030210`
  (`10030250`), level transition `FUN_100302e0` (`100302f4`) and level start `FUN_100064d0`
  (`10006824`). Every frame starts with empty layer queues.
- **Writer of entity `+0x1a` (sprite-geometry-draw.md NR 5)** [HIGH]: entity create `FUN_10035cd0`,
  `10035fac lbz r0,0x12c(r31); 10035fb0 stb r0,0x1a(r28)`. This copies unit-def
  `adjustShadowLocForScaling_BOOL` (U+0x12c, unit-def-struct.md key table) into the entity,
  right after `10035fa0 stb r0,0x19(r28)` (the air flag). Other `stb …,0x1a(` sites in the
  existing listings (`100126f0`, `1003dff4`, `1004688c`) were not traced.

## Worked example — `Bomb Crater` (`bocr`): pak → frame blocks → cache bytes → frame table
Commands: `python3 $W/w4s3-bocr.py`, which reuses `tools/plate_frames.py` for the frame rects and
the alpha-map rule of `FUN_1001eec0` (sprite-sound-containers.md §2.3a). Colour conversion is
8-bit → 5-bit by `>>3`; QuickTime's exact rounding is assumed [LOW], though 222 and 16 give the same
5-bit value either way.

1. **Load.** On OS X with no cache, `FUN_10018bf0` reaches `bocr` in the `im08` enumeration →
   `FUN_10018d20('bocr')`. Alpha plate `BOCR` and colour plate `bocr` (55 × 21) give three frame
   rects (top, left, bottom, right): (3,3,19,19) 16×16, (3,22,19,37) 15×16, (7,40,19,53) 13×12.
   - The colour key is pixel (2,0) of the colour plate, (0,222,0) → RGB555 **`0x0360`**.
2. **Encode** (`FUN_1001d780`), per frame:

   | frame | w × h | has alpha | block size | alpha map at | empty-row markers (1000) |
   |---|---|---|---|---|---|
   | 0 | 16 × 16 | 1 | 0x18+512+512 = **1048** (0x418) | +0x218 | none |
   | 1 | 15 × 16 | 1 | 0x18+480+480 = **984** (0x3d8) | +0x1f8 | row 15 |
   | 2 | 13 × 12 | 1 | 0x18+312+312 = **648** (0x288) | +0x150 | rows 0, 6, 7 |

   Frame 0 header: `49 96 02 d2 | 00 00 00 10 | 00 00 00 10 | 00 00 00 10 | 03 60 | 01 | ?? |
   00 00 02 18`, where `??` is the stale-register byte `+0x13` (§4.2).
   - First colour row: 8 × `0360`, 4 × `0842` (crater (16,16,16)), 4 × `0360`.
   - First alpha row: `32 ×8, 28, 30, 28, 30, 32 ×4` as u16 (0x0020 = skip; 28/30 = mostly
     transparent dark edge).
3. **Frame table.** Record `{0x499602d2, 'bocr', 3, P}`, where `P[n]` points to frame n's block.
   `FUN_10019ad0('bocr', 2)` returns `P[2]`, and `FUN_10019ee0('bocr')` returns 3.
4. **Cache bytes** (shutdown, `FUN_1001b390`). After the 8-byte header, this group contributes:
   ```
   49 96 02 d2  62 6f 63 72  00 00 00 03  pp pp pp pp      record (pp = stale pointer)
   00 00 04 18  <1048 bytes frame 0>
   00 00 03 d8  <984 bytes frame 1>
   00 00 02 88  <648 bytes frame 2>
   ```
   That is 16 + (4+1048) + (4+984) + (4+648) = **2708 bytes**. On the next OS X launch
   `FUN_1001b040` rebuilds the same record with a fresh `P` and byte-identical blocks. The `BOCR`
   pseudo-group (§4.1) follows somewhere else in tag order.

## NOT RESOLVED (this file)
1. `FUN_10002340` tag order and the exact set of `im08` tags (Game.pak 248 + Interface.pak 2)
   enumerated by the load-all path. This decides the cache's group order and whether the 125
   upper-case pseudo-groups really appear. Settles: read `FUN_10002340`/tag-index build by listing,
   or inspect a cache file written by the OS X build.
2. ~~Mode semantics of `FUN_10001200` (0x11 read, 0x17 / 0xf create-write) and of the other M_File
   helpers. Read here by call pattern only. Settles: M_File listing (another reader's range).~~ → ⚑ corrected (review wave 3, 2026-10-06) #M4: app-pak-music-library.md §1.2: `0x11` = "rb", `0x0f` = "a+t", `0x17` = "a+b" (`10001238..1000131c`) (#M4).
3. The collectors `FUN_1003f0b0`, `FUN_10039a80`, `FUN_1002b400` used by LOGUNUSEDSPRITES/SOUNDS.
   They are unreachable debug code. Settles: read them, if anyone wants the "unused resource" list.
4. INDEX #10's last link: that QuickTime's TGA importer honours descriptor bit 5. It is inferred
   from the upright title screen; nothing in the binary shows it. Settles: Ben's eyes on the menu
   screen, or one screenshot.
5. ~~The capacity rule of the render lists after the initial 2000 commands. `FUN_1001a450` grows ×2
   (bank MED); the exact compare against 0x251c0 / 0x4c was not re-read here.~~ → ⚑ corrected (review wave 3, 2026-10-06) #C6: blit-pixel-rules.md `FUN_1001a450` (HIGH, `1001a56c..`): the capacity compare and ×2 growth are listing-read (#C6).
6. ~~The `stb …,0x1a(` sites `100126f0`, `1003dff4`, `1004688c` (reset / copy paths of entity `+0x1a`)
   were not traced to their functions.~~ → ⚑ corrected (review wave 3, 2026-10-06) #S: only four `stb …,0x1a(` exist in the code range (fix-pass listing): `100126f0` (GameObject reset `FUN_10012650`, `10012668 li r12,0x0` → 0; reached from the player ctor via `FUN_100125d0`), `10035fb0` (entity creation `FUN_10035cd0`), `1003dff4` (state copy-assign `FUN_1003dfb0`, a state byte) and `1004688c` (`FUN_10046840`, blur) (critic wave 3 §3).

## Role-table rows (for merge)
| function | module | role | conf | evidence |
|---|---|---|---|---|
| `FUN_10018740` | U_Sprite.cc | sprite manager init (normalPort, terrainPort): manager log, flags, port indices, new group list, 16 render lists × 0x251c0 B (2000 cmds), blitter init, LOGSPRITE/FX registered debugOnly (never exist) | HIGH | listing `10018740–100188c0` (sprite-manager-resource-image.md §1.1) |
| `FUN_100188d0` | U_Sprite.cc | sprite manager teardown: write cache if `0x100e0178`, unload all groups, free cache buffer and render lists, blitter teardown | HIGH | listing `100188d0–100189ec` (§1.2) |
| `FUN_10018bf0` | U_Sprite.cc | Sprite Groups Cache load policy: cache OK → done; Classic → lazy loading; OS X → write probe, load every `im08` tag, cache written at quit | HIGH | listing `10018bf0–10018d10` (§4.1) |
| `FUN_100193f0` | U_Sprite.cc | unload group(s) (id, all): frees frame blocks, frame array, record | HIGH | listing `100193f0–1001952c` (§2) |
| ⚑ corrected `FUN_10019ee0` | U_Sprite.cc | frame count of a group (+0x8), 0 + "RESOURCE: Sprite Group '%s' not loaded." if absent; range check for `FUN_10019ca0`, `FUN_10035cd0` | HIGH | listing `10019f54–10019f60` (was LOW "frame count of a group (error message only)") (§2) |
| `FUN_10019fc0` | U_Sprite.cc | LOGSPRITE body: log frame count, per-frame w/h/alpha flag (+0x12); unreachable | HIGH | listing `1001a0a8–1001a0f4` (§2) |
| `FUN_1001a1f0` | U_Sprite.cc (span) | cut a tag name at " IA" / " IC" (loading-screen text of the permanent sprites) | HIGH | listing `1001a204–1001a23c`; caller `FUN_1001fe60` (§2) |
| `FUN_1001aec0` | U_Sprite.cc (span) | drain a linked list, deleting each element (frame-rect list of the group loader) | MED | listing `1001aed8–1001aef4`; `FUN_10000d90` dump only (§2) |
| `1001af10` (no Ghidra function) | U_Sprite.cc | LOGSPRITE handler (strtok on `'` → `FUN_10019fc0`); unregistered | HIGH | range listing `1001af10–1001afb4` (§3.1) |
| `1001afc0` (no Ghidra function) | U_Sprite.cc | FX handler: toggle `0x100e0171`, post Enabled/Disabled; unregistered | HIGH | `1001afdc stb r0,-0x61bf(r2)` (§3.1) |
| `FUN_1001b040` | U_Sprite.cc | Sprite Groups Cache reader (OS X only; header word 1 must be 0x10; mod date fetched, never compared; failure → rebuild flag) | HIGH | listing `1001b040–1001b384` (§4.3) |
| `FUN_1001b390` | U_Sprite.cc | Sprite Groups Cache writer: `{count, 0x10}`, per group 16-B record + `{size, block}` per frame | HIGH | listing `1001b390–1001b580` (§4.2, §4.4) |
| `FUN_1001b590` | U_Sprite.cc (span) | save buffer as ` Data:<name>` (remove, create 0x17/0xf 'Data'/'Deim', reopen, write, "Data Saved") | HIGH (sequence) / MED (M_File modes) | listing `1001b590–1001b734` (§4.4) |
| `FUN_1001d5e0` | U_SpriteBlit.cc | blitter init: encoding + alpha-analysis buffers 300×256×16; ALPHA registered debugOnly (never exists) | HIGH | listing `1001d5e0–1001d6e8` (§1.3) |
| `FUN_1001d6f0` | U_SpriteBlit.cc | blitter teardown (dispose both buffers) | HIGH | listing `1001d6f0–1001d770` (§1.3) |
| `FUN_1001d980` | U_SpriteBlit.cc | resize both staging buffers to w×h×16 (`FUN_10009d70`) | HIGH | listing `1001d980–1001d9c0` (§1.3) |
| `FUN_1001eea0` / `FUN_1001eeb0` | U_SpriteBlit.cc | getters: encoding buffer `0x100e0188` / alpha-analysis buffer `0x100e0184` | HIGH | `1001eea0 lwz r3,-0x61a8(r2)`; `1001eeb0 lwz r3,-0x61ac(r2)` (§1.3) |
| `1001f040` (no Ghidra function) | U_SpriteBlit.cc | ALPHA handler: toggle `0x100e0181`, copy to `0x100e0172` via `FUN_1001a290`; unregistered | HIGH | range listing `1001f040–1001f0c0` (§3.1) |
| ⚑ upgraded `FUN_1001a290` | U_Sprite.cc (span) | set `0x100e0172`; sole caller the unregistered ALPHA handler, so `0x100e0172` stays 1 | HIGH | `1001a290 stb r3,-0x61be(r2)`; bl scan (§3.2) (was MED "set DAT_100e0172") |
| ⚑ upgraded `FUN_10019c00` | U_Sprite.cc (span) | set port indices `0x100e0179` ← r3, `0x100e0170` ← r4; sole caller init with (0, 1) | HIGH | `10019c00 stb r3,-0x61b7(r2)`; `10019c04 stb r4,-0x61c0(r2)` (§0) (was MED, dump) |
| ⚑ upgraded `FUN_100189f0` | U_Sprite.cc | zero the 16 render-layer counts (lists kept); begin frame, session start, level transition, level start | HIGH | listing `100189f0–10018a38`; call sites `10030388`, `10030250`, `100302f4`, `10006824` (§7) (was MED) |
| ⚑ upgraded `FUN_1001f7c0` | G_Resource.cc | resource manager init; RESLOG / LOGUNUSEDSPRITES / LOGUNUSEDSOUNDS registered debugOnly (never exist) | HIGH | `1001f85c/7c/9c li r7,0x1` (§5) (was MED, strings) |
| ⚑ upgraded `FUN_1001f950` | G_Resource.cc | G_Res_Load(kind 1 sprite / 0 sound, id, usage 0 perm / 1 level / 2 temp): registered → usage = min, return 1; else load + record; failure logs, returns 0 | HIGH | listing `1001f974–1001fa94` (§5) (was MED, strings) |
| `FUN_1001f8d0` | G_Resource.cc | resource manager teardown: unload all sprites, then all sounds, delete list | HIGH | listing `1001f8f0–1001f92c` (§5) |
| `FUN_1001faf0` | G_Resource.cc | unload every registered resource of a kind (no usage filter; shutdown only) | HIGH | listing `1001fb5c–1001fbb0` (§5) |
| `FUN_1001fbe0` | G_Resource.cc | resource tag exists? (kind 1/other → im08, 0 → soun) | HIGH | listing `1001fbe0–1001fc2c` (§5) |
| `FUN_1001fc30` | G_Resource.cc | resource registered? (kind, id) → 1/0; draw-dispatcher error triage | HIGH | listing; caller `FUN_10019570` (§5) — ⚑ corrected (review wave 3, 2026-10-06) #L: label audit, address cited — `1001fc9c lbz r0,0x4(r3); cmplw r0,r31`, `1001fca8 lwz r0,0x8(r3); cmpw r0,r27`, `1001fcb4 li r29,0x1` |
| `FUN_10020270` | G_Resource.cc | RESLOG body: list sprite then sound records of one usage level; unreachable | HIGH | `100202e4`, `100202f4`, `10020388` (§5) |
| `FUN_100203e0` | G_Resource.cc | find resource record (kind, id) → ptr/0 | HIGH | `1002044c`, `10020458` (§5) |
| `100206a0` / `10020740` / `10020a20` (no Ghidra functions) | G_Resource.cc | handlers RESLOG / LOGUNUSEDSPRITES (8 perm ids + collectors) / LOGUNUSEDSOUNDS (24 perm ids, skips "Music"); unregistered | HIGH (role) / LOW (collector callees) | range listing `100206a0–10020ce0` (§3.1) |
| `FUN_10020d60` | U_Image.cc (span) | U_Image constructor (`FUN_10009980`) | HIGH | `10020d74 bl 0x10009980` (§6.1) |
| `FUN_10020e00` | U_Image.cc (span) | U_Image destructor (dispose GWorld; delete if flags > 0) | HIGH | `10020e20–10020e38` (§6.1) |
| `FUN_10020e60` | U_Image.cc | U_Image_LoadInBuffer(img, id, type): dispose old, `FUN_10020f00`, FILE ERROR assert line 0x37 on failure | HIGH | `10020e8c–10020ed8` (§6.1) |
| `FUN_10020f00` | U_Image.cc | QuickTime import: 'grip' component, GWorld = file w/h/depth (desc +0x20/+0x22/+0x52), erase, draw; no row flip; TGA depth ≠ 16 only warns; errors return 0 | HIGH | listing `10021048–100210b0` (§6.1) |
| ⚑ corrected `FUN_10021190` | M_Image.cc | QuickTime import of **sprite plates only** (sole caller `FUN_10018d20`), caller-chosen depth 8/16 | HIGH | callers.txt; was "QuickTime image import into pixel buffer" (§6.1) |

## INDEX updates (for merge)
- **#9 residue closed** (§3.2): the writers of `DAT_100e0171` (FX), `DAT_100e0172` (via
  `FUN_1001a290`) and `DAT_100e0181` (ALPHA) are only the handlers of the debugOnly console
  commands, which are never registered. All three are 1 for the whole session.
- **#10 narrowed to one outside link** (§6): the game does no flip; map and mask share the
  importer and the stored orientation (data check); row 0 = visual top, given that the title screen
  shows upright. Remaining: Ben confirms the upright title (NR 4).
- **#36 closed** (§7): `FUN_100189f0` zeroes the 16 layer counts at begin frame (`10030388`).
- sprite-geometry-draw.md **NR 2, NR 3, NR 5 closed** (§7, §3.2, §7).
- sprite-sound-containers.md §1: function attribution corrected (§6.1). §2.4: the Sprite Groups
  Cache format is now written out (§4), and the cache is OS-X-only and never date-checked.
- Census (this scope): 26 listed functions + 6 orphan handlers, all with rows; 5 rows upgraded.
  Unread in range: none.
