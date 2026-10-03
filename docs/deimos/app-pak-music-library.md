# Deimos Rising 1.0.6: boot/list/file helpers, U_Pak leftovers, M_Application, input glue, unzip tail

Reader w4s2, wave 4 (2026-10-04). Scope: the 71 unread functions the wave-4 brief lists for
`app-pak-music-library.md`, in five groups:
- boot/list/file `0x10000890–0x100016c0`;
- U_Pak `0x100016c0–0x10004640` leftovers, plus U_Prefs `FUN_100047c0`, the G_Background
  colour packers `FUN_10010bd0`/`FUN_10010c00`, and Registration `FUN_10010ca0`/`10010da0`/`10010e00`/`10010e60`;
- M_Application `0x100491d0–0x10049ca0` and the M_Music-span file helpers `0x100484e0–0x10048ee0`;
- `0x10049ca0–0x1004b400`. The brief calls this range "unzip.c". Only `0x10049ca0–0x1004a8a0` is
  the zip reader. `0x1004a8b0–0x1004b2a0` is the **input / InputSprocket module**, and
  `FUN_1004b2b0` is a runtime registration helper that `entry` calls (§5).

The scope also covers the INDEX #1 jump table (§2.1) and the #3 tag-count threshold (§2.3).

OUT of scope:
- the initialisers `FUN_10000000`, `FUN_10000750`, `FUN_10004520`, `FUN_100108e0` (wave 3, static-init-audit.md);
- every function already carrying a role row;
- the library code above `0x1004b400` (MSL, zlib, the registration library).

I name library callees by call shape only (MED): `FUN_10050390` fopen, `FUN_10050170` fclose,
`FUN_1004fa20` fread, `FUN_1004fdd0` fwrite, `FUN_10051890` fseek, `FUN_10051640` ftell,
`FUN_100577f0` strcat, `FUN_10057a30` strstr, `FUN_10055390` sprintf, `FUN_1004d320`/`FUN_1004d3b0`
new/delete. `FUN_100503e0` is MSL freopen: it parses the mode and seeks to the end when the mode is
append. `FUN_10050390` = `freopen(name, mode, __find_unopened_file())`.

Evidence:
- Listing: `$W/disasm-w4s2.txt`, made by `DisasmRange.java` over `10000880:10004800`,
  `10010bd0:10010ec0` and `100484e0:1004b400`.
- Data: the image `mem/100de330.bin`. Scratch reader: `$W/w4s2-rd.py s|w <addr>[+off]`.
  r2 = `0x100e6330`.
- Pre-main caveat: none of the data values quoted below has a writer in code. The tag threshold
  (§2.3) and the jump table (§2.1) were checked by raw scan. Everything else is a string, which
  initialisers do not touch.

## 1. Boot range `0x10000890–0x100016c0`

### 1.1 U_LinkedList helpers [HIGH]
List header = {+0 count, +4 head, +8 tail}; node = {+0 prev, +4 next, +8 data} (as `FUN_100009e0`).
| function | role | listing evidence |
|---|---|---|
| `FUN_10000890 @ 10000890` | list ctor: count = head = tail = 0 | `10000894 stw r0,0x4(r3)`, `…98 stw r0,0x8(r3)`, `…9c stw r0,0x0(r3)` |
| `FUN_100008b0 @ 100008b0` | list dtor(this, flag): if this, clear (`FUN_10000af0`); if `(short)flag > 0`, delete this | `100008d0 bl 0x10000af0`, `100008d8 extsh. r0,r31; ble`, `100008e4 bl 0x1004d3b0`; 51 callers |
| `FUN_10000af0 @ 10000af0` | clear: frees every **node** (not the data) by walking next, then zeroes the header | `10000b10 lwz r31,0x4(r3)` / `10000b14 bl 0x1004d3b0` loop; `10000b2c..b34` stores 0 |
| `FUN_10000aa0 @ 10000aa0` | remove-by-data(list, data): find node, unlink it; returns −2 if absent | `10000ab4 bl 0x10000e40`, `10000ac8 bl 0x10000b50`, `10000ad4 li r3,-0x2`; one caller, `FUN_1003b180` (weapon set) |
| `FUN_10000b50 @ 10000b50` | unlink node (list, node) and free it, count −1; returns −3 if node NULL | head fix `10000b88 lwz r0,0x4(r4); stw r0,0x4(r30)` else `prev->next = next` (`10000b94..9c`); tail fix `10000bac..b0` else `next->prev = prev` (`10000bb8..c0`); `10000bd0 bl 0x1004d3b0`; `10000bdc subi r0,r3,0x1` |
| `FUN_10000cf0 @ 10000cf0` | nth data (list, i): NULL unless `0 ≤ i < count`; walks next i times (8× unrolled) | `10000cf4 blt`, `10000cfc cmpw r4,r0; blt`, unroll `10000d3c..d60`, remainder `10000d74`, `10000d7c lwz r3,0x8(r5)` |
| `FUN_10000d90 @ 10000d90` | pop front: data = head->data (0 if empty); unlink the first node holding it; return data | `10000dac cmpwi r0,0; bgt`, `10000dc0 lwz r31,0x8(r3)`, `10000ddc bl 0x10000e40`, `10000df0 bl 0x10000b50`; 22 callers |
| `FUN_10000e40 @ 10000e40` | find the first node whose data == p, else NULL | `10000e48 lwz r0,0x8(r3); cmplw r0,r4; beqlr`, `10000e58 lwz r3,0x4(r3)` |
`FUN_10000b50` does not adjust iterator cursors. Callers that remove while iterating use
`FUN_10000c00` instead (loose-ends-session.md).

### 1.2 The File object (a one-word wrapper around an MSL `FILE*`) [HIGH for the wrapper, MED for the library identity]
| function | role | listing evidence |
|---|---|---|
| `FUN_10001590 @ 10001590` | `f = NULL` (no close) | `10001590 li r0,0; stw r0,0x0(r3)` |
| `FUN_100010f0 @ 100010f0` | ctor: `FUN_10001590`, return this | `10001104 bl 0x10001590` |
| `FUN_10001130 @ 10001130` | ctor + open(path, mode) with no type/creator | `10001154 bl 0x10001590`, `10001168 li r6,0; li r7,0; bl 0x10001200` |
| `FUN_10001200 @ 10001200` | **open(this, path, modeBits, type, creator)** → 1/0. Builds an fopen mode string from bits (table below), then `fopen(path, mode)`. On failure it clears the handle. If modeBits is exactly `0x0f` or `0x17` and type ≠ 0, it stamps the Finder type/creator (`FUN_100484e0`) | mode base `1000120c subi r31,r2,0x3794` = `0x100e2b9c`; bit tests `rlwinm.` masks 4/1/2 (`10001238`, `10001240`, `10001248`); `10001324..132c bl 0x10050390`; `10001344 cmpwi r28,0xf`, `1000134c cmpwi r28,0x17`, `10001354 cmpwi r29,0`, `10001368 bl 0x100484e0` |
| `FUN_100013a0 @ 100013a0` | close: fclose if open, then NULL | `100013c0 bl 0x10050170`, `100013cc bl 0x10001590` |
| `FUN_100011a0 @ 100011a0` | dtor(this, flag): close; delete this if `(short)flag > 0` (callers pass −1, so this is a stack object) | `100011c0 bl 0x100013a0`, `100011c8 extsh.; ble`, `100011d4 bl 0x1004d3b0` |
| `FUN_100013f0 @ 100013f0` | read(this, buf, n) = `fread(buf, 1, n, f)`; 0 if closed | `10001408 or r3,r4,r4; li r4,0x1; bl 0x1004fa20` (r5 = n, r6 = f pass through) |
| `FUN_10001430 @ 10001430` | write(this, buf, n) = `fwrite(buf, 1, n, f)` | `1000144c li r4,0x1; bl 0x1004fdd0` |
| `FUN_10001470 @ 10001470` | seek(this, off, whence) = `fseek(f, off, whence)`; 0 if closed | `1000147c lwz r3,0x0(r3)`, `10001488 bl 0x10051890` |
| `FUN_100014b0 @ 100014b0` | size: pos = ftell; fseek(0, SEEK_END = 2); size = ftell; fseek(pos, SEEK_SET) | `100014dc bl 0x10051640`, `10001500 li r4,0; li r5,0x2; bl 0x10051890`, `1000151c bl 0x10051640`, `10001544 li r5,0x0; bl 0x10051890` |
| `FUN_10001570 @ 10001570` | isOpen = (f ≠ 0) | `10001574 neg; or; rlwinm r3,r0,1,31,31` |

Mode-bit table from `FUN_10001200`. Strings come from the data image (`w4s2-rd.py s 100e2b9c …`):
`0x100e2b9c` "r", `+2` "a", `+4` "a+", `+7` "w", `+9` "r+", `+0xc` "b", `+0xe` "t".
| bits (1 = read, 2 = write, 4 = append) | string | then |
|---|---|---|
| append, read only | "r" | `0x10` → append "b"; `0x08` → append "t" |
| append, write only | "a" | |
| append, other | "a+" | |
| no append, read only | "r" | |
| no append, write only | "w" | |
| no append, other | "r+" | |

Uses seen in this scope: `0x11` = "rb" (Local scan, §2.2); `0x0f` = "a+t" and `0x17` = "a+b" plus a
type/creator stamp of 'Data'/'Deim' (`FUN_10002640` tag write). [HIGH]

### 1.3 Errors, U_Pak shutdown [HIGH]
| function | role | evidence |
|---|---|---|
| `FUN_10001040 @ 10001040` | `FUN_1000ced0("Error", msg, fatal)`: shows the alert; fatal ≠ 0 means shutdown (loose-ends-session.md §8.2) | `10001044 or r5,r4,r4`, `1000104c or r4,r3,r3`, `10001050 subi r6,r2,0x3a3c` + `0x287` = `0x100e2b7b` "Error", `1000105c bl 0x1000ced0`; 8 callers |
| `FUN_10001080 @ 10001080` | **anti-tamper message swap.** Copies 256 bytes from `PTR 0x100deed0 → 0x100d60b0`, terminates them, decodes in place with `FUN_10046470`, then `strcpy` over the shared "Sorry, but critical files are missing…" text at `0x100e27f4`. Every later `FUN_10000fd0` alert then shows the decoded text instead: **"A device configuration error (-65) has occurred.  Please contact the publisher for help."** | `10001084 lwz r4,-0x7460(r2)` (= `0x100deed0`), `1000108c li r5,0x100; bl 0x1000cd60`, `100010a4 stb r0,0x137(r1)`, `100010bc bl 0x10046470`, `100010c4 subi r3,r2,0x3b3c` (= `0x100e27f4`) `; bl 0x10057780`. Decoded with Python `~rotl8(b,4)` over `mem/10000000.bin[0xd60b0:]` (88 characters, then a 0 byte) |
| `FUN_10001670 @ 10001670` | U_Pak shutdown: unregister "Pak" (`FUN_1003a900`). If the pak-init flag `0x100e00f4` is set, free the tag index (`FUN_10003840`) and clear the flag | `10001674 subi r3,r2,0x3540; addi +0x336` = `0x100e3126` "Pak", `10001690 lbz r0,-0x623c(r2)` (= `0x100e00f4`; set by `FUN_100015a0` at `100015cc`), `1000169c bl 0x10003840`; caller `FUN_10000630` (shutdown) |

`FUN_10001080` callers [MED for the purpose, HIGH for the calls]:
- `FUN_100064d0` (level start) calls it when the level tag ≠ none, `param_1 == 0`, `DAT_100e00fc == 0`
  and `FUN_10011b00()` (4) < the sector. This is the unregistered-copy demo limit
  (level-scroll-objects.md §8).
- `FUN_10028170` calls it when the registration integrity check fails (player-physics.md §9).

Both callers follow it with `FUN_10011b10`. A replica of the registered game never takes this path.

## 2. U_Pak leftovers, INDEX #1 and #3

### 2.1 The 15-way jump table at `0x100e2db4` is a type selector, not 15 handlers [HIGH]
Command: `python3 -c "…b(0x100e2db4+4*i,4)…"` over `mem/100de330.bin`. The 15 words are
loader-relocated code addresses. Each one is a two-instruction case that loads a 4CC into r29 and
then branches to the **single shared body** at `0x10001844`.
| i | word | case code | r29 (folder/type) |
|---|---|---|---|
| 0 | `10001794` | `lis r3,0x696d; addi r29,r3,0x3038` | `im08` |
| 1 | `100017a0` | `0x696d/0x3136` | `im16` |
| 2 | `100017ac` | `0x736f/0x756e` | `soun` |
| 3 | `100017b8` | `0x7374/0x6c69` | `stli` |
| 4 | `100017c4` | `0x666c/0x6c69` | `flli` |
| 5 | `100017d0` | `0x7765/0x6465` | `wede` |
| 6 | `100017dc` | `0x7265/0x6c69` | `reli` |
| 7 | `100017e8` | `0x6964/0x6c69` | `idli` |
| 8 | `100017f4` | `0x636f/0x6c69` | `coli` |
| 9 | `10001800` | `0x7465/0x666f` | `tefo` |
| 10 | `1000180c` | `0x706c/0x6465` | `plde` |
| 11 | `10001818` | `0x7072/0x6566` | `pref` |
| 12 | `10001824` | `0x6669/0x6c6d` | `film` |
| 13 | `10001830` | `0x756e/0x6465` | `unde` |
| 14 | `1000183c` | `0x6c65/0x7665` (falls through to `10001844`) | `leve` |

The next word (`0x100e2df0` = `4c617374` "Last…") is a string, so the table has exactly 15 entries.
The dispatch is `1000177c cmplwi r30,0xe; bgt 0x10001b20`, `10001784 subi r3,r2,0x357c` (=
`0x100e2db4`), `10001788 lwzx r3,r3,r25`, `1000178c mtspr CTR,r3`, `10001790 bctr`. The loop end is
`10001b20 addi r30,r30,1; cmpwi r30,0xf; addi r25,r25,4; blt 0x1000177c`. The order matches the
suffix tables (pak-format.md §2.2). No code writes into the table: it is in the data section, and the
only access is the `lwzx` read.

### 2.2 The Local-folder scan body `0x10001844–0x10001b1c` (inside `FUN_100016c0`) [HIGH]
For each type T in the table order:
1. `FUN_10014060(T, buf)` turns the 4CC into text (`10001848`).
2. `FUN_10048560(" Data:Local", buf, dir, 1)` builds `dir = ": Data:Local:<T>"` (`10001854..64`;
   string `0x100e2df0+0x458` = `0x100e3248`; path rules in §3.1). If logging, it prints
   `"    Scanning %s"` (`+0x466`).
3. Enumerate `n = 1, 2, …` with `FUN_10048810(dir, n, name)` (`10001b00..1c`, §3.2) until it returns 0.
   Per item:
   - `FUN_10048560(dir, name, path, 0)` → `": Data:Local:<T>:<name>"` (`100018a8..b8`).
   - `File(path, 0x11)` = "rb" (`100018c4 li r5,0x11; bl 0x10001130`). If the file is not open, or
     its size (`FUN_100014b0`) ≤ 0 → destroy and skip (`100018f4 cmpwi r3,0; bgt`). This silently
     drops the 0-byte `Icon\r` files.
   - Clear a 0x40-byte tag header H at `r1+0x134` (`10001914 li r4,0x40`).
   - If the lower-cased name contains **".tag"** (`FUN_10004050`): read the first 0x40 bytes of the
     file into H (`10001930..3c bl 0x100013f0`). Type, ID, data offset and size then come from the
     file. No `.tag` file ships [MED for the meaning of H fields `+0x28/+0x2c/+0x38`, not read].
   - Otherwise: `H+0x34 = size` (`10001958 stw r3,0x168(r1)`), `H+0x3c = 'Deim'`, and
     `FUN_100021a0(name, H)` fills H+0 (display name, 32 bytes), `H+0x20` type and `H+0x24` ID. On
     failure → skip (`10001978 bne` else `FUN_100011a0`). `H+0x30` (offset) stays 0, meaning the
     whole file.
   - **Wrong-folder check:** if `H+0x20 ≠ T` (`10001990 lwz r3,0x154(r1); cmplw r3,r29`) it logs
     `"\nFILE ALERT. Incorrect file location.  The file should be placed in the "%s" folder!…"`
     (`+0x476`) and calls `FUN_10000f30("FALSE", "U_Pak.cc", 0x192)` (`100019c8`). That alert is
     non-fatal (loose-ends-session.md §8.2), so the record is **still added** under its suffix type.
   - Record: `FUN_10003910(H)` (`100019d4`); `new(0x158)`; `+0 = 0x499602d2`; append to the index
     (`10001a14 bl 0x100009e0`). Fields: `+4` type = H+0x20, `+8` ID = H+0x24, `+0xc` offset =
     H+0x30, `+0x150` size = H+0x34, **`+0x154` = 1 (Local flag)** (`10001a48 stb r0,0x154(r24)`),
     `+0x110` file name, `+0x10` full path, `+0x130` display name (re-parsed from `+0x110`, else
     "Unknown").
   - Close and destroy the File (`10001ae8`, `10001af8`).

The Local loop (`1000177c–10001b2c`) runs completely before the Paks scan starts
(`10001b50 addi r3,r31,0x52c` = " Data:Paks", `10001b60 bl 0x10048560`). Local records are therefore
**ahead** of pak records in list order. This makes the "Local first" insertion order (INDEX #2 tail)
HIGH. Pak records get `+0x154 = 0` (`*(puVar2+0x55) = 0` in the dump).

### 2.3 Tag-count threshold `_DAT_100e00ec` = **100** (INDEX #3) [HIGH]
- Value: `w4s2-rd.py w 100e00ec` → `00000064`.
- The only access in the whole code image is `10001ee4 lwz r0,-0x6244(r2)`.
  - Scan: every word with RA = 2 and d ∈ {`0x9dbc`..`0x9dbf`}, any opcode. One other hit, a `b`
    at `0x100ac284` with the same low bits, is not an access.
  - No `lis 0x100e` + `0x00ec` pair exists.
  - No data-image word equals `0x100e00ec`.
- Compare: `10001ed8 bl 0x10000ce0` (count **after** the override pass `FUN_10004300` at `10001e94`),
  `10001ee8 cmpw r3,r0; bge 0x10001f04` → otherwise log "Tag Index Incomplete!  Aborting." (`+0x708`)
  and `FUN_10000fd0` (non-fatal).
- 1.0.6 ships 871 pak files plus 1 Local film, all with distinct (type, ID) apart from duplicates
  counted in pak-format.md. The check therefore passes by a wide margin. It fires only for a missing
  or empty Paks folder.

### 2.4 The other U_Pak functions
| function | role | label | evidence |
|---|---|---|---|
| `FUN_10003840 @ 10003840` | free the tag index: for each record, unlink the node (`FUN_10000c00`) and delete the record; then list dtor(flag 1); index ptr `0x100e00f0` = 0 | HIGH | `10003858 lwz r3,-0x6240(r2)`, `100038b0 bl 0x10000c00`, `100038bc bl 0x1004d3b0`, `100038dc li r4,1; bl 0x100008b0`, `100038ec stw r0,-0x6240(r2)`; callers `FUN_10001670`, `FUN_100016c0` (rebuild) |
| `FUN_10003910 @ 10003910` | set "current tag name" buffer (`PTR 0x100def28 → 0x100f7c88`, 32 bytes): zero it, bounded-copy 31 chars | HIGH | `10003918 lwz r31,-0x7408(r2)`, `1000391c li r4,0x20; bl 0x1000cd90`, `10003944 li r5,0x1f; bl 0x10046510`; 7 callers (index build, every tag loader) |
| `FUN_10001fe0 @ 10001fe0` | get current tag name into dst: whole (31 max) if flag = 0, else only the part before the first '.'; dst[31] = 0 | HIGH | `10001ff8 rlwinm. r0,r4…; beq`, loop `10002038 lbz r6,0(r4); cmpwi r6,0x2e`, `10002058 bl 0x10046510`, `10002064 stb r0,0x1f(r30)`; caller `FUN_1000ef90` (G_Text, error text) |
| `FUN_10003970 @ 10003970` | count records with (type, ID) whose Local flag equals `local` | HIGH | `100039d4..e8` type/ID compares, `100039f4/10003a08 lbz r0,0x154(r3)`; caller `100016c0` duplicate pass `10001e04 lbz r5,0x154(r25); bl 0x10003970`, log if > 1 (`10001e10 cmpwi r28,1; ble`) |
| `FUN_100024f0 @ 100024f0` | display name of tag (type, ID) → `record+0x130`; NULL if ID = 'none' or not found | HIGH | `10002508 subis r0,r28,0x6e6f; cmplwi r0,0x6e65`, `10002568/10002574` compares, `1000257c addi r30,r3,0x130`; 5 callers (G_Text, image, `FUN_1002ab20`, `FUN_10039280`, `FUN_1003d0a0`) |
| `FUN_100025b0 @ 100025b0` | save tag as loose file: `name = "%s[%s].%s"` (`FUN_10004230`: display ≤ 20 chars, ID, type), `size = GetPtrSize(ptr)` (`FUN_1000cc60`), `FUN_10002640(type, ptr, size, name, binary, reindex)` | HIGH | `100025e4 bl 0x10004230`, `100025ec bl 0x1000cc60`, `1000260c bl 0x10002640`; caller `FUN_100095b0` ('film', id, ptr, `_DAT_100e0100`, 1, 1) = Last Film |
| `FUN_10004050 @ 10004050` | lower-cased name contains ".tag" | HIGH | `10004064 bl 0x100462e0` (strdup), `10004070 bl 0x10046410` (to-lower via MSL map `0x100f1094`: 'A' → 'a'), `10004078/80` `0x100e38e6` ".tag", `10004084 bl 0x10057a30`, `10004094 bl 0x10046380` (free); caller `10001924` |
| `FUN_10004150 @ 10004150` | strip a path prefix in place: keep the text after the **last** '/' (zip entry `im08/X[id].gif` → `X[id].gif`) | HIGH | `10004198 lbz r0,0(r3); cmpwi r0,0x2f`, `100041e4 bl 0x1000cd60`, `10004204 bl 0x10057780`; caller `100016c0` pak loop |
| `FUN_100044b0 @ 100044b0` | LOGTAGS console handler: rebuild the index with logging (`FUN_100016c0(1,1)`), print "Tag Index Logged.  (%i Tags Found)". **Unreachable in 1.0.6**: registered with debugOnly r7 = 1 | HIGH | registration `100015d8 lwz r5,-0x73fc(r2)` → descriptor `0x100e07d0` = {`100044b0`, TOC}, `100015e8 li r7,0x1`, `100015f0 bl 0x1002d080` (messages-notices-console.md §5.2) |
| `FUN_100047c0 @ 100047c0` | present the Configuration dialog: `FUN_10010fc0(PTR 0x100def40 → 0x100f7ca8, arg)` | HIGH | `100047cc lwz r3,-0x73f0(r2)`, `100047d4 bl 0x10010fc0`; callers `FUN_100000e0` (first run / key held, arg 1) and `FUN_10024e40` |

## 3. File-system helpers in the M_Music span `0x100484e0–0x10048ee0`

### 3.1 Paths are relative and built with ':' joins [HIGH]
`FUN_10048560 @ 10048560 (dir, name, out, rel)`. Strings sit in the block at `PTR 0x100df59c →
0x100f03e4`: `+0x46` "%s%s%s", `+0x4d` ":", `+0x4f` "%s%s%s%s", `+0x58` "%s%s".
| rel | name | out | listing |
|---|---|---|---|
| ≠ 0 | NULL | `":" dir ":"` | `10048588..94` |
| ≠ 0 | set | `":" dir ":" name` | `100485a0..b0` |
| 0 | NULL | `dir ":"` | `100485c4..d0` |
| 0 | set | `dir ":" name` | `100485dc..ec` |
8 callers: tag index, tag write, sprite cache, Units Cache.

### 3.2 Catalog enumeration rooted at the application's folder [HIGH]
Both functions below do the same steps:
1. Copy the C path into a zeroed Str63 template and convert it to Pascal (`FUN_10044930`).
2. `GetCurrentProcess`, then `GetProcessInformation`, with `processInfoLength = 0x3c` and
   `processAppSpec` → a local FSSpec (`10048700 li r3,0x3c`, `10048704 stw r0,0xb8(r1)` = info
   +0x38). The FSSpec name is replaced by the path (`10048740 bl BlockMoveData`).
3. First `PBGetCatInfoSync`, on the PB at `r1+0xbc`: `ioNamePtr` (+0x12), `ioVRefNum` (+0x16) =
   the app volume, `ioFDirIndex` (+0x1c) = 0, `ioDirID` (+0x30) = the app's parent directory. This
   resolves the folder and returns its directory ID in +0x30.
4. Second `PBGetCatInfoSync` with `ioFDirIndex = n`. This gets item n of that folder. Item order
   is HFS catalog order, i.e. alphabetical.

Glue addresses: `100d3d2c` GetCurrentProcess, `100d3d44` GetProcessInformation, `100d48b4`
PBGetCatInfoSync, `100d3a2c` BlockMoveData.
| function | after the 2nd call | evidence |
|---|---|---|
| `FUN_10048810 @ 10048810 (path, n, outName)` | returns 1 on success. If `ioFlAttrib` bit 4 (directory) is **clear**, it converts the name back to C and copies it to outName. For a **sub-folder** it still returns 1 but leaves outName unchanged | `10048954 sth r4,0xd8(r1)` (index 0), `10048984 sth r29,0xd8(r1)` (index n), `1004899c lbz r0,0xda(r1)`, `100489a0 li r31,0x1`, `100489ac rlwinm. r0,r0,0,27,27; bne 0x100489e4`, `100489c0..dc` copy; sole caller `FUN_100016c0` (both scans) |
| `FUN_10048610 @ 10048610 (path, n, &date, &isDir)` | returns 1. Directory → `*isDir = 1`, `*date = FUN_10044f70(spec)`. File → `*date = FUN_10044f00(spec)`. Both helpers return the modification date: `ioFlMdDat`/`ioDrMdDat`, PB +0x4c in their own decompile | `10048790 sth r28,0xd8(r1)`, `100487a8 lbz r0,0xda(r1)`, `100487b0 lwz r3,0x120(r1)` (ioFlParID +0x64 → spec parID), `100487c4 li r0,1; stb r0,0(r30)`, `100487d0 bl 0x10044f70`, `100487e4 bl 0x10044f00`; sole caller `FUN_100420f0` (Units Cache: newest ` Data:Local:unde` date, unit-def-struct.md §8) |

Consequence of the `FUN_10048810` sub-folder case [HIGH for the code, LOW for the effect]: a
sub-folder inside ` Data:Paks` or ` Data:Local:<T>` makes the scan re-process the **previous** name.
In Paks that opens the previous pak a second time, which creates duplicate records (logged,
first wins). No sub-folder ships, so this does not happen in 1.0.6.

### 3.3 Small helpers
| function | role | label | evidence |
|---|---|---|---|
| `FUN_100484e0 @ 100484e0 (path, type, creator)` | if both ≠ 0: `FUN_10044e80` (FSpGetFInfo/FSpSetFInfo). On a non-zero OSErr, log "ERROR: (%i) could not change file type for file '%s'" and return 0; on success return 1 | HIGH | `100484e8 cmpwi r4,0`, `10048504 cmpwi r5,0`, `1004850c bl 0x10044e80`, `10048514 extsh.`, `1004851c lwz r3,-0x6d94(r2); addi +0x11`; caller `FUN_10001200` |
| `FUN_10048c00 @ 10048c00` | is the game the front process: `GetFrontProcess(&f)`, `SameProcess({0, kCurrentProcess = 2}, &f, &same)` → same ≠ 0 | HIGH | `10048c18 li r0,2`, `10048c30 bl 0x100d600c`, `10048c4c bl 0x100d6024`, `10048c5c lbz r3,0x38(r1)`; caller `FUN_10025190` (REGISTER button: re-enter the display only if still front) |
| `FUN_10048ea0 @ 10048ea0` | `StillDown() ≠ 0` | HIGH | `10048eac bl 0x100d4314`; caller `FUN_10024a50` (button click tracking) |

## 4. M_Application `0x10049320–0x10049900`

### 4.1 The log file **": Data:Deimos Rising.log"** [HIGH]
`FUN_10049400 @ 10049400 (folder, name)`, called once from `FUN_100000e0` as `(" Data", 0)`
(`0x100e26df`):
1. App name ← `FUN_10049700`.
2. Name = given, else `sprintf("%s.log", app)` (`+0xb7`).
3. Path = name if folder is NULL, else `":" folder ":" name` (`+0x4f`, `+0x4d`). Stored in the global
   path buffer `PTR 0x100df58c → 0x1011b894`.
4. `fopen(path, "w+")`, which **truncates on every launch**. Fallback `"a+"`. If both fail, return
   with logging off.
5. Write `"%s log opened %s\n"` (app name, `ctime(time(0))`, `FUN_100598d0`/`FUN_10059a40`), then
   fflush and fclose.
6. Set the log-enabled byte `0x100e02b4` (`1004952c stb r0,-0x607c(r2)`).

Listing: `10049430 bl 0x10049700`, `10049444 addi r4,r31,0xb7`, `100494b0 addi r4,r31,0xbe` (w+),
`100494c8 addi r4,r31,0xc1` (a+), `10049500 addi r4,r31,0xc4`, `10049514 bl 0x10050240`,
`10049520 bl 0x10050170`.

Every later `FUN_10049550` line reopens the file with "a+", writes `"%s\n"`, flushes and closes
(dump), and does nothing while the flag is 0. No log ships in ` Data/`.

`FUN_10049700 @ 10049700 (dst)` returns the **application file name**:
- `GetProcessInformation` with `processAppSpec` → FSSpec at `r1+0x9c` (`10049740 stw r0,0x98(r1)`
  = info +0x38).
- Pascal → C on the FSSpec name (`1004974c addi r31,r1,0xa2` = spec +6, `10049754 bl 0x10044a60`).
- `strncpy(dst, name, 63)` (`10049764 li r5,0x3f`).
- Callers: `FUN_10049400`, and `FUN_10048480` (the "Shutting Down %s" log line).

### 4.2 Toolbox wrappers [HIGH]
| function | role | evidence |
|---|---|---|
| `FUN_10049320 @ 10049320 (on)` | Enable (on ≠ 0) or Disable **Apple-menu item 1** (`PTR 0x100e02ac` = `GetMenuHandle(128)` + `AppendResMenu 'DRVR'` in `FUN_100491d0`) | `10049334/48 lwz r3,-0x6084(r2)`, `10049338 li r4,1`, `1004933c bl 0x10045a80` (EnableItem), `10049350 bl 0x10045a50` (DisableItem); caller `FUN_100234d0`: 0 on entering a game, 1 on return |
| `FUN_10049600 @ 10049600 (url)` | open a URL with Internet Config. Returns false only if ICStart is not linked (weak import). Sequence: `ICStart(&inst, 'Deim')`; if OK, `ICFindConfigFile(inst, 0, 0)`; if OK, `ICLaunchURL(inst, hint "", url as Str255, len, &0, &len)`; then `ICStop` | `1004961c lwz r0,-0x7f84(r2); beq` → `li r30,-1`, `1004965c lis r4,0x4465; addi 0x696d`, `10049668 bl 0x100d5094`, `10049684 bl 0x100d50ac`, `100496ac addi r4,r4,0xda` (""), `100496bc bl 0x100d5cdc`, `100496c8 bl 0x100d513c`; caller `FUN_10025270` (web-link button, URL at interface text `+0x1300`) |
| `FUN_10049790 @ 10049790` | `SysBeep(1)` | `10049794 li r3,1; bl 0x100d399c`; caller `FUN_10010fc0` (config dialog) |
| `FUN_100497c0 @ 100497c0` | `GetMBarHeight()` sign-extended | `100497cc bl 0x100d543c; extsh`; caller `FUN_1000ae20` (display rects) |
| `FUN_10049820 @ 10049820 (ticks)` | busy wait: `end = TickCount() + ticks; while TickCount() < end` (unsigned) | `10049834 bl 0x100d456c`, `1004983c add r31,r3,r31`, `10049848 cmplw r3,r31; blt 0x10049840`; 8 callers (boot logo `FUN_10049820(5)`, shutdown, display, front end) |
| `FUN_10049870 @ 10049870` | `InitCursor()` (arrow) | `1004987c bl 0x100d3774`; callers alert `FUN_1000ced0`, config dialog, REGISTER |
| `FUN_100498a0 @ 100498a0` | watch cursor: `SetCursor(*GetCursor(4))` | `100498a4 li r3,4; bl 0x100d3f0c`, `100498b8 lwz r3,0(r3)`, `100498bc bl 0x100d3924`; caller `FUN_10048330` (Toolbox init) |
| `FUN_100498e0 @ 100498e0` | pass-through to `FUN_10045ef0` (r3–r7 untouched): if the game display is active, leave it (`FUN_1000c2a0`); show the `FUN_10045c60` alert; return result == 1. A yes/no confirm | `100498ec bl 0x10045ef0` with no register setup; callers `FUN_10025270` (confirm before ICLaunchURL), `FUN_100229a0` |

## 5. `0x10049ca0–0x1004b400`: the zip reader tail, the input module, the runtime registrar

### 5.1 It is not Gilles Vollant's unzip.c ⚑ conflict (with the wave-4 brief, not with the bank) [HIGH]
The zip reader's string block `PTR 0x100df5a0 → 0x100f04d4` uses its own API names:
- "Unzip_LoadFileData(): Unable to read uncompressedzip"
- "Priv_OpenZip_UsingCache - Could not open zipfile"
- step texts "Opening for reading", "Seeking to end", "Reading ECD (End of Central Directory)",
  "Cannot span disks", "Version too new", "OS not supported", "Inflating compressed data",
  "Compression method unsupported", "Error: %s, File: %s"
- module name "unzip.c" at `+0x66`

None of these is a minizip `unzOpen`/`unzGoToFirstFile`/`unzLocateFile`/`unzReadCurrentFile` name.
The functions are therefore named by role, not by minizip counterpart. pak-format.md never claims
Vollant; it says "unzip.c" only.

| function | role | label | evidence |
|---|---|---|---|
| `FUN_1004a620 @ 1004a620 (step, path)` | format `"Error: %s, File: %s"` into the static buffer `PTR 0x100df5a4 → 0x1011bc94`. The buffer is **never read**: the only `-0x6d8c(r2)` access in the code image is this store | HIGH | `1004a630 lwz r7,-0x6d90(r2)`, `1004a638 lwz r3,-0x6d8c(r2)`, `1004a63c addi r4,r7,0x50b`, `1004a640 bl 0x10055390`; 12 call sites in `FUN_10049de0`/`1004a1d0`/`1004a4f0`; whole-image scan for d = `0x9274`, RA = 2 → only `1004a638` |
| `FUN_1004a840 @ 1004a840 (zip)` | lazy open: zip handle = {+0 path, +4 FILE*}; if FILE* is 0, `fopen(path, "rb")` (`+0x363`); return zip, or NULL on failure | HIGH | `1004a854 lwz r0,0x4(r3)`, `1004a868 addi r4,r4,0x363`, `1004a86c bl 0x10050390`, `1004a874 stw r3,0x4(r31)`; caller `FUN_1004a4f0` |

**Inflate is unreachable (INDEX ledger #17 → HIGH).** I took a census of every `bl` target in
`0x10049ca0–0x1004a8a0`:
- zip-reader internals: `1004a1d0`, `1004a4f0`, `1004a620`, `1004a660`, `1004a680`, `1004a6b0`, `1004a840`;
- MSL: `1004ea90`, `1004ead0`, `1004fa20`, `10050170`, `10050390`, `10051640`, `10051660`, `10051890`,
  `10051fe0`, `10055390`, `10057760`, `10057780`;
- game helpers: `10000f30`, `1000cd60`, `10046510`, `10049550`.

None is zlib. The block's inflate strings (`+0x4d2` "Inflating compressed data", `+0x542` "1.1.3",
`+0x548` "inflateInit error", `+0x55f`, `+0x589`, `+0x59c`, `+0x5b2`) and `+0x2f2..+0x333`
(Unzip_LoadFileData) have no reference:
- the 7 code sites that load the block pointer (`10049ca8`, `10049df8`, `1004a3c8`, `1004a4fc`,
  `1004a630`, `1004a6b8`, `1004a860`) use only offsets `0x0`, `0x60`, `0x66`, `0x6e`, `0xb4`,
  `0x363`, `0x366`, `0x37a`, `0x389`, `0x397`, `0x3a2`, `0x3c9`, `0x3db`, `0x3f8`, `0x412`, `0x437`,
  `0x449`, `0x458`, `0x50b` and `0x51f` (the base register traced through each whole function in
  the listing, e.g. `10049cf4 or r3,r31,r31` for `+0`, `1004a814 addi r3,r31,0x51f`);
- no data-image word points into the block except the two TOC entries.

The zlib that is linked (inflate tables near `FUN_10071080`, libpng 1.2.1 `FUN_100ba1d0`, the
registration library's 'zlib' users) belongs to libraries above `0x1004b400`. A STORED-only reader
is therefore what 1.0.6 runs.

### 5.2 Input module: U_Manager names "Input" / "InputSprocket" [HIGH]
Globals: `0x100e02bf` ISp initialised (r2 −0x6071), `0x100e02be` ISp started (−0x6072),
`0x100e02bd` ISp resumed/active (−0x6073), `0x100e02bc` input module up (−0x6074).

Buffers (BSS):
- game input 2×7 bytes at `PTR 0x100df5a8 → 0x1011bd94`;
- polled ISp input 2×7 bytes at `PTR 0x100df5b0 → 0x1011bdcc`;
- 10 element refs at `PTR 0x100df5b4 → 0x1011bda4`.

The glue addresses are confirmed by the dump's `// ==== Name @ addr` headers.
| function | role | evidence |
|---|---|---|
| `FUN_1004a910 @ 1004a910` | input shutdown: unregister "Input" (`PTR 0x100df5ac → 0x100f0aa0`), clear `0x100e02bc`, ISp shutdown | `1004a914 lwz r3,-0x6d84(r2)`, `1004a924 bl 0x1003a900`, `1004a930 stb r0,-0x6074(r2)`, `1004a934 bl 0x1004ad40`; caller `FUN_10000630` |
| `FUN_1004ad40 @ 1004ad40` | ISp shutdown: unregister "InputSprocket" (`0x100f0aec`). If initialised: if started, suspend (`FUN_1004ae30`) then **`ISpStop`**. Clear initialised | `1004ad44 lwz r3,-0x6d74(r2)`, `1004ad5c lbz r0,-0x6071(r2)`, `1004ad68 lbz r0,-0x6072(r2)`, `1004ad74 bl 0x1004ae30`, `1004ad7c bl 0x100d4aac` (ISpStop), `1004ad88 stb r0,-0x6071(r2)` |
| `FUN_1004a950 @ 1004a950` | per-level input reset: clear game input (`FUN_1004aa20`), flush the 10 elements (`FUN_1004ada0`), clear polled input (`FUN_1004af30`) | `1004a95c`, `1004a964`, `1004a96c`; caller `FUN_100064d0` (level start) |
| `FUN_1004ada0 @ 1004ada0` | `ISpElement_Flush(elem[i])` for i = 0..9 | `1004ada8 lwz r31,-0x6d7c(r2)`, `1004adc4 bl 0x100d4e54`, `1004add0 cmpwi r30,0xa` |
| `FUN_1004af30 @ 1004af30` | if ISp initialised, zero the polled buffer (2 × 7 bytes) | `1004af38 lwz r31,-0x6d80(r2)`, `1004af4c lbz r0,-0x6071(r2); beq`, `1004af64 li r4,7; bl 0x1000cd90`, `1004af74 cmpwi r29,2` |
| `FUN_1004ae30 @ 1004ae30` | suspend: if initialised, started and active: `ISpDevices_ActivateClass('mous')`, **`ISpSuspend`**, active = 0 | `1004ae3c/48/54` the three flag tests, `1004ae60 lis r3,0x6d6f; addi 0x7573`, `1004ae68 bl 0x100d48fc`, `1004ae70 bl 0x100d4914`, `1004ae7c stb r0,-0x6073(r2)` |
| `FUN_1004a9c0 @ 1004a9c0` | public wrapper → `FUN_1004ae30` | `1004a9cc bl 0x1004ae30`; callers game end (`FUN_100051a0`), alert `FUN_1000ced0`, menu `FUN_100229a0`, `FUN_100234d0`, console open `FUN_1002d1a0` |
| `FUN_1004aea0 @ 1004aea0 (mouse)` | resume: if initialised, started and **not** active: **`ISpResume`**, active = 1, then `ISpDevices_ActivateClass('mous')` if mouse ≠ 0, else `ISpDevices_DeactivateClass('mous')` | `1004aecc lbz r0,-0x6073(r2); bne`, `1004aed8 bl 0x100d49a4`, `1004aee8 stb r3,-0x6073(r2)`, `1004aef8 bl 0x100d48fc` / `1004af0c bl 0x100d49bc` |
| `FUN_1004a990 @ 1004a990 (mouse)` | public wrapper → `FUN_1004aea0`, r3 passed through | `1004a99c bl 0x1004aea0`. Arguments at the callers (dump): `FUN_100051a0` 1 (just before the first `FUN_100064d0` level start), `FUN_1002d230` 1/0 (console close), `FUN_1000ced0` 0, `FUN_100234d0` 0 |
| `FUN_1004ae90 @ 1004ae90` / `FUN_1004a9f0 @ 1004a9f0` | ISp active? (`lbz r3,-0x6073(r2)`) / its wrapper | `1004ae90`, `1004a9fc bl 0x1004ae90`; callers alert `FUN_1000ced0` (save, then restore), console open `FUN_1002d1a0` (`DAT_100e01e2` = saved state) |
| `FUN_1004b1e0 @ 1004b1e0 (player, dst)` | copy the polled 7 bytes of player 0 or 1 to dst; other indices: no-op (unlike `FUN_1004ab50`, which logs "DEBUG: Input - unknown Player Number") | `1004b1e4 lwz r5,-0x6d80(r2)`, `1004b1ec extsb; cmpwi 1`, `1004b210..18` (src +0), `1004b228..30` (src +7), `bl 0x1004b270`; caller `FUN_1004aa90` |
| `FUN_1004b250 @ 1004b250` | InputSprocket available = weak import `ISpInit` TVect ≠ 0 | `1004b250 lwz r3,-0x7938(r2); neg; or; rlwinm 1,31,31`; caller `FUN_1004abd0`. If absent → log "ERROR: InputSprocket is not available on this machine." and fatal alert "Input Sprocket could not be initialised.…" (`FUN_1000ced0(…, 1)` in `FUN_1004abd0`, dump) |
| `FUN_1004b270 @ 1004b270 (dst, src, n)` | byte copy; returns at once if dst = 0 or n = 0 | `1004b270 cmplwi r3,0; beqlr`, `1004b278 cmplwi r5,0; beqlr`, loop `1004b288..9c`; callers `FUN_1004ab50`, `FUN_1004b1e0`, prefs `FUN_100047f0`/`FUN_10004c30` |

ISp setup, for reference: `FUN_1004abd0` (already HIGH) calls `ISpInit(10 needs, …, 'Deim',
'0002', 0, 0xde6, 0)`, then `ActivateClass('keyd')`, `ActivateClass('mous')`, `ISpSuspend`, so
input starts suspended.

### 5.3 `FUN_1004b2b0 @ 1004b2b0`: runtime fragment registrar called by `entry` [MED]
`entry @ 1004d540` (CFM main) calls, in this order:
1. `FUN_1004b2b0(0x10000000, 0x100de330, <TVect sqrt label>, 0x1011ef04, 0x100db69c, 0x100de330, TOC)`;
2. `FUN_10000000` (static init);
3. `FUN_100000a0` (main);
4. `FUN_1004db30(0)` (exit).

The first argument pair is the code-section bounds. `0x100db69c–0x100de330` is the tail of the
code section (an index range; MED that it is the C++ exception table).

`FUN_1004b2b0` does two things:
- **Once**, it checks `Gestalt('ppcf')` (weak-import check `-0x7b88(r2)`). If bit 4 is set (AltiVec
  per Apple's `gestaltPowerPCHasVectorInstructions`; MED, from Apple headers), it sets `0x100e02c0`.
  The bytes above `0x1004b400` that read `DAT_100e02c0` are unwinder code (dump lines near
  `FUN_1004c7f0`).
- It stores the 7 arguments as a 28-byte record `{p5, p6, p1, p2, p3, p4, p7}` in the first free
  slot (`+8` = 0) of a chain of 900-byte blocks of 32 slots each (next pointer at `+0x380`). The
  chain head is `0x100e02c8`. A new block comes from `NewPtrClear(0x384)`. The function returns the
  slot index (−1 on failure), which `entry` stores in `0x100e02d4`.

Listing: `1004b2dc lbz r0,-0x606f(r2)`, `1004b2fc lis r3,0x7070; addi 0x6366`,
`1004b308 bl 0x100d3684` (Gestalt), `1004b31c rlwinm. r0,r0,0,27,27`, `1004b328 stb r0,-0x6070(r2)`,
`1004b338 li r0,0x20`, `1004b348 lwz r3,0x8(r5)`, `1004b354..70` slot stores, `1004b388 lwz r4,0x380(r4)`,
`1004b3a0 li r3,0x384; bl 0x100d369c`.

This is compiler runtime only; nothing in it is game behaviour. [HIGH for the code, MED for the
"exception-table registrar" name]

## 6. G_Background colour packers and the Registration object

| function | role | label | evidence |
|---|---|---|---|
| `FUN_10010bd0 @ 10010bd0 (RGBColor*)` | 48-bit RGBColor → RGB555: `((r>>1)&0x7c00) \| ((g>>6)&0x3e0) \| (b>>11)`, bit 15 = 0 | HIGH | `10010bd0 lhz r4,0x2(r3)` (g), `10010bd4 lhz r0,0x4(r3)` (b), `10010bd8 lhz r5,0x0(r3)` (r), `10010bdc rlwinm r3,r4,26,22,26`, `10010be0 srawi r0,r0,0xb`, `10010be4 rlwimi r3,r5,31,17,21`, `10010be8 rlwimi r0,r3,0,17,26`; caller `FUN_10043340` (particle colours) |
| `FUN_10010c00 @ 10010c00 (r, g, b)` | the same packing from three ints; b is shifted unmasked (`srawi r0,r5,0xb`), so b must be ≤ 0xffff | HIGH | `10010c00 rlwinm r0,r4,26,22,26`, `10010c04 rlwimi r0,r3,31,17,21`, `10010c0c srawi r0,r5,0xb`, `10010c14 rlwinm r3,r0,0,16,31`; caller `FUN_10010990` (HTML RRGGBB → pixel) |
| `FUN_10010ca0 @ 10010ca0 (this)` | Registration object ctor: `this->initialised (+0) = 0`, return this | HIGH | `10010ca0 li r0,0; stb r0,0(r3); blr`; caller static init `FUN_10000750` with `PTR 0x100dea30 → 0x100f7be8`, followed by `FUN_1004cfa0(obj, dtor, …)` (global-object registration). The dtor is the unnamed code at `10010cb0` (delete if flag > 0) |
| `FUN_10010da0 @ 10010da0 (this)` | Registration shutdown: unregister "Profile" (`0x100e60d4`). If initialised: `FUN_1007ede0()`, `FUN_1006bfd0()` (registration library, not read), initialised = 0 | HIGH (calls) / LOW (library meaning) | `10010dac subi r3,r2,0x25c` = `0x100e60d4`, `10010dbc bl 0x1003a900`, `10010dc4 lbz r0,0(r31)`, `10010dd0 bl 0x1007ede0`, `10010dd8 bl 0x1006bfd0`, `10010de4 stb r0,0(r31)`; caller `FUN_10000630` |
| `FUN_10010e00 @ 10010e00 (this, mode)` | REGISTER: `FUN_100805f0(mode, 0)` (registration-library dialog; its profile shows SysBeep and 'CHNK'). A non-zero result → TOOL ERROR assert "err is_eq 0", M_Registration.cc line 0xbe (`FUN_10000ed0`, MED fatal per §8.2). Then `FUN_1007ef10` | HIGH (calls) / LOW (library) | `10010e08 rlwinm r3,r4,0,24,31`, `10010e14 li r4,0`, `10010e1c bl 0x100805f0`, `10010e24 cmpwi r3,0`, `10010e34 li r5,0xbe; bl 0x10000ed0`, `10010e40 bl 0x1007ef10`; caller `FUN_10025190` (REGISTER button, `(PTR 0x100dea30, 1)`) |
| `FUN_10010e60 @ 10010e60` | registration-library idle: `FUN_1007ef10()`. Per its decompile: if the library is enabled and at least 2× its interval has passed since the last stamp, it runs `FUN_1007f7e0` | HIGH (call) / MED (library) | `10010e6c bl 0x1007ef10`; callers main menu `FUN_100229a0`, `FUN_10023e10` |

## Worked example: the Local-folder scan finds `Last Film[last].film`
The data is `$G/ Data/Local/film/` (`ls -la`): `.DS_Store` (6148 bytes, a modern-macOS extraction
artefact), `Icon\r` (0 bytes), and `Last Film[last].film` (40296 bytes).
1. `FUN_100016c0` reaches `r30 = 12`, `r25 = 48`. `lwzx` reads `0x100e2db4 + 48 = 0x100e2de4` →
   `0x10001824`. `bctr` lands on `lis r3,0x6669; addi r29,r3,0x6c6d`, so r29 = `'film'`. The case
   branches to `10001844`.
2. `FUN_10014060('film')` gives "film". `FUN_10048560(" Data:Local", "film", dir, 1)` gives
   `dir = ": Data:Local:film"`.
3. `FUN_10048810(dir, n, name)`. Inside it, PBGetCatInfo #1 resolves ": Data:Local:film"
   relative to the application's parent directory, and #2 takes item n. In HFS order:
   - n = 1 `.DS_Store`: opened "rb", 6148 bytes, not ".tag". `FUN_100021a0` finds no '[', and the
     name contains ".DS_Store", so it rejects the file silently (`10002274` strstr hit →
     `1000231c`). Skipped. On the original volume the file is absent.
   - n = 2 `Icon\r`: size 0, so `100018f4 bgt` is not taken. Skipped.
   - n = 3: path `": Data:Local:film:Last Film[last].film"`, `File(path, 0x11)` → `fopen(…, "rb")`,
     size 40296. The lower-cased name has no ".tag". H+0x34 = 40296, H+0x3c = 'Deim'.
     `FUN_100021a0` fills H = {"Last Film", type `'film'` (suffix ".film", pak-format.md §2.2),
     ID `'last'` = `0x6c617374`}. The type equals r29, so there is no alert.
   - n = 4: PBGetCatInfo fails, so `FUN_10048810` returns 0 and the type loop advances.
4. Record (0x158 bytes): `+0` `0x499602d2`; `+4` `'film'`; `+8` `'last'`; `+0xc` 0;
   `+0x150` 40296; `+0x154` 1; `+0x110` "Last Film[last].film"; `+0x10` the full path;
   `+0x130` "Last Film".
5. The Paks scan adds Game.pak's films `de01…` (none with ID `last`). `FUN_10004300` has nothing to
   override for (`film`, `last`). Replay mode 1 (`FUN_100234d0`) later loads `last` from this Local
   record. Saving a new film (`FUN_100025b0('film', 'last', ptr, "Last Film", 1, 1)`) does two
   things: (a) it rewrites `": Data:Local:film:Last Film[last].film"` through `"a+b"` with type
   'Data' / creator 'Deim'; (b) it rebuilds the whole index with `FUN_100016c0(0,0)` (reindex flag,
   `FUN_10002640`, dump).

## NOT RESOLVED (this file)
1. `.tag` Local files (§2.2): the meaning of H fields `+0x28`, `+0x2c`, `+0x38` in the 64-byte
   header. Settle by listing `FUN_100021a0`'s callers' use of H, or by finding an authoring tool
   that writes `.tag`. None ships; replica-neutral.
2. `FUN_1004b2b0` (§5.3): which MW runtime routine this is, and what argument 3 (labelled
   `TVect::sqrt` by Ghidra) really points to. Settle by reading the `0x100e02c8` chain consumer at
   dump line ~44865 and the PEF loader sections. Compiler runtime only.
3. Registration-library internals `FUN_100805f0`, `FUN_1007ef10`, `FUN_1007ede0`, `FUN_1006bfd0`
   (above `0x1004b400`). Out of the 100 % range; only the call shape is recorded.
4. `FUN_10045c60`/`FUN_10045ef0` (the confirm alert under `FUN_100498e0`) are w4s4's.
   `FUN_10044f00`/`FUN_10044f70`/`FUN_10044e80` were read here only from the dump (mod date,
   SetFInfo) and are w4s4's to label.

## Role-table rows (for merge)
| `FUN_10000890` | U_LinkedList.cc (span) | list ctor: count/head/tail = 0 | HIGH | listing `10000894–1000089c` |
| `FUN_100008b0` | U_LinkedList.cc (span) | list dtor(this, flag): clear nodes; delete this if (short)flag > 0 | HIGH | `100008d0 bl 0x10000af0`, `100008d8 extsh.`, `100008e4 bl 0x1004d3b0` |
| `FUN_10000af0` | U_LinkedList.cc (span) | free all nodes (not data), zero header | HIGH | loop `10000b10–10000b24`, stores `10000b2c–34` |
| `FUN_10000aa0` | U_LinkedList.cc (span) | remove node holding data; −2 if absent | HIGH | `10000ab4 bl 0x10000e40`, `10000ac8 bl 0x10000b50`, `10000ad4 li r3,-0x2` |
| `FUN_10000b50` | U_LinkedList.cc (span) | unlink node + free, count −1; −3 if NULL (no iterator fix-up) | HIGH | `10000b74 li r31,-0x3`, head/tail fix `10000b88–10000bc0`, `10000bdc subi` |
| `FUN_10000cf0` | U_LinkedList.cc (span) | nth data (0-based), NULL if out of range | HIGH | `10000cf4/10000d00` bounds, `10000d7c lwz r3,0x8(r5)` |
| `FUN_10000d90` | U_LinkedList.cc (span) | pop front data | HIGH | `10000dc0 lwz r31,0x8(r3)`, `10000ddc/10000df0` find + unlink |
| `FUN_10000e40` | U_LinkedList.cc (span) | find first node with data == p | HIGH | `10000e48–10000e60` |
| `FUN_10001040` | — (errors) | `FUN_1000ced0("Error", msg, fatal)` | HIGH | `10001050–1000105c` (`0x100e2b7b` "Error") |
| `FUN_10001080` | — (errors) | anti-tamper: overwrite the "critical files" alert text with the decoded "A device configuration error (-65) has occurred.…" | HIGH | `10001084 lwz r4,-0x7460(r2)`, `100010bc bl 0x10046470`, `100010c4 subi r3,r2,0x3b3c; bl 0x10057780`; callers `FUN_100064d0` demo limit, `FUN_10028170` integrity check |
| `FUN_10001590` / `FUN_100010f0` | File (U_Pak span) | File handle = NULL / File ctor | HIGH | `10001590–10001594`; `10001104 bl 0x10001590` |
| `FUN_10001130` | File | ctor + open(path, mode) without type/creator | HIGH | `10001168 li r6,0; li r7,0; bl 0x10001200` |
| `FUN_10001200` | File | open(path, modeBits 1 r/2 w/4 append/8 t/0x10 b → "r" "w" "r+" "a" "a+" + "b"/"t"); stamp type/creator when modeBits = 0x0f/0x17 | HIGH | `1000120c` mode base `0x100e2b9c`, `1000132c bl 0x10050390`, `10001344/4c cmpwi 0xf/0x17`, `10001368 bl 0x100484e0` |
| `FUN_100013a0` / `FUN_100011a0` | File | close / dtor(this, flag) | HIGH | `100013c0 bl 0x10050170`; `100011c0 bl 0x100013a0`, `100011d4 bl 0x1004d3b0` |
| `FUN_100013f0` / `FUN_10001430` | File | read / write = fread / fwrite(buf, 1, n, f) | HIGH | `1000140c li r4,1; bl 0x1004fa20`; `1000144c li r4,1; bl 0x1004fdd0` |
| `FUN_10001470` / `FUN_100014b0` / `FUN_10001570` | File | fseek pass-through / size via ftell + SEEK_END + restore / isOpen | HIGH | `10001488 bl 0x10051890`; `10001504 li r5,0x2`, `10001544 li r5,0x0`; `10001574–1000157c` |
| `FUN_10001670` | U_Pak.cc (span) | Pak shutdown: unregister "Pak", free index if inited (`0x100e00f4`) | HIGH | `10001688 bl 0x1003a900`, `10001690 lbz r0,-0x623c(r2)`, `1000169c bl 0x10003840` |
| `FUN_10001fe0` | U_Pak.cc (span) | get current tag name (whole, or up to first '.') | HIGH | `10001fe8 lwz r31,-0x7408(r2)`, `1000203c cmpwi r6,0x2e`, `10002064 stb r0,0x1f(r30)` |
| `FUN_100024f0` | U_Pak.cc (span) | (type, ID) → display name `rec+0x130`; NULL for 'none' / missing | HIGH | `10002508–1000250c` 'none', `1000257c addi r30,r3,0x130` |
| `FUN_100025b0` | U_Pak.cc (span) | save tag as Local file `"%s[%s].%s"` via `FUN_10002640` (Last Film) | HIGH | `100025e4 bl 0x10004230`, `100025ec bl 0x1000cc60`, `1000260c bl 0x10002640` |
| `FUN_10003840` | U_Pak.cc (span) | free tag index (records + list), ptr `0x100e00f0` = 0 | HIGH | `100038b0 bl 0x10000c00`, `100038bc bl 0x1004d3b0`, `100038e0 bl 0x100008b0`, `100038ec stw` |
| `FUN_10003910` | U_Pak.cc (span) | set current tag name buffer `0x100f7c88` (31 chars) | HIGH | `10003918 lwz r31,-0x7408(r2)`, `1000391c li r4,0x20`, `10003944 li r5,0x1f` |
| `FUN_10003970` | U_Pak.cc (span) | count records (type, ID) with the same Local flag (duplicate log) | HIGH | `100039d8/100039e4` compares, `100039f4/10003a08 lbz r0,0x154(r3)` |
| `FUN_10004050` | U_Pak.cc (span) | name (lower-cased) contains ".tag" → Local tag-header file | HIGH | `10004070 bl 0x10046410`, `10004080 addi r4,r4,0xaf6` (`0x100e38e6`), `10004084 bl 0x10057a30` |
| `FUN_10004150` | U_Pak.cc (span) | strip zip folder prefix (keep text after last '/') | HIGH | `1000419c cmpwi r0,0x2f`, `100041e4 bl 0x1000cd60`, `10004204 bl 0x10057780` |
| `FUN_100044b0` | U_Pak.cc (span) | LOGTAGS handler (rebuild + log); unreachable: debugOnly registration | HIGH | `100015e8 li r7,0x1`, descriptor `0x100e07d0` → `100044b0` |
| ⚑ corrected `FUN_100016c0` | U_Pak.cc | build tag index: Local scan over 15 type folders via a type-selector jump table (§2.1–2.2, Local first, wrong-folder alert non-fatal), then Paks; threshold 100 tags | HIGH | was "build tag index (Local then Paks)" with handlers "NOT RESOLVED"; listing `1000177c–10001b2c`, `10001ee4–10001efc` |
| `FUN_100047c0` | U_Prefs.cc (span) | present Configuration dialog `FUN_10010fc0(PTR 0x100def40, arg)` | HIGH | `100047cc lwz r3,-0x73f0(r2)`, `100047d4 bl 0x10010fc0` |
| `FUN_10010bd0` / `FUN_10010c00` | G_Background.cc (span) | RGBColor (48-bit) → RGB555 / same from 3 ints | HIGH | `10010bd0–10010bec`; `10010c00–10010c14` |
| `FUN_10010ca0` | M_Registration.cc (span) | Registration object ctor (+0 initialised = 0) | HIGH | `10010ca0 stb r0,0(r3)`; caller `FUN_10000750` |
| `FUN_10010da0` | M_Registration.cc (span) | Registration shutdown: unregister "Profile", library teardown if inited | HIGH | `10010dbc bl 0x1003a900`, `10010dd0 bl 0x1007ede0`, `10010dd8 bl 0x1006bfd0` |
| `FUN_10010e00` | M_Registration.cc | REGISTER: library dialog `FUN_100805f0(mode, 0)`, assert err == 0, then idle | HIGH | `10010e1c bl 0x100805f0`, `10010e34 li r5,0xbe; bl 0x10000ed0`, `10010e40 bl 0x1007ef10` |
| `FUN_10010e60` | M_Registration.cc (span) | registration-library idle tick `FUN_1007ef10` | HIGH | `10010e6c bl 0x1007ef10`; callers `FUN_100229a0`, `FUN_10023e10` |
| `FUN_100484e0` | M_Music.cpp (span) | set Finder type/creator (`FUN_10044e80`), log on OSErr; 1 = ok | HIGH | `1004850c bl 0x10044e80`, `1004851c lwz r3,-0x6d94(r2); addi +0x11` |
| `FUN_10048560` | M_Music.cpp (span) | path join: rel ? ":"dir":"[name] : dir":"[name] | HIGH | `10048588–100485ec`, formats `0x100f03e4+0x46/0x4f/0x58` |
| `FUN_10048610` | M_Music.cpp (span) | n-th item of an app-relative folder → mod date, isDir | HIGH | `1004871c` GetProcessInformation, `10048768/10048798` PBGetCatInfoSync, `100487a8 lbz 0xda`, `100487d0/100487e4` |
| `FUN_10048810` | M_Music.cpp (span) | n-th item name of an app-relative folder (files only; sub-folder → 1 with name unchanged) | HIGH | `1004895c/1004898c` PBGetCatInfoSync, `100489a0 li r31,1`, `100489b8 bne` skip copy |
| `FUN_10048c00` | M_Application (span) | game is front process (GetFrontProcess + SameProcess) | HIGH | `10048c30 bl 0x100d600c`, `10048c4c bl 0x100d6024` |
| `FUN_10048ea0` | M_Application (span) | StillDown() ≠ 0 | HIGH | `10048eac bl 0x100d4314` |
| `FUN_10049320` | M_Application.cpp (span) | Enable/Disable Apple-menu item 1 (off in game) | HIGH | `10049334 lwz r3,-0x6084(r2)`, `1004933c`/`10049350` |
| `FUN_10049400` | M_Application.cpp (span) | open log ": Data:<app>.log" with "w+" (fallback "a+"), header line, log flag `0x100e02b4` = 1 | HIGH | `100494b0 addi +0xbe`, `100494c8 +0xc1`, `10049500 +0xc4`, `1004952c stb r0,-0x607c(r2)` |
| `FUN_10049600` | M_Application.cpp (span) | open URL: ICStart('Deim') → ICFindConfigFile → ICLaunchURL → ICStop | HIGH | `10049668`, `10049684`, `100496bc`, `100496c8` |
| `FUN_10049700` | M_Application.cpp (span) | application file name (process FSSpec name, ≤ 63) | HIGH | `10049744 bl 0x100d3d44`, `1004974c addi r31,r1,0xa2`, `10049764 li r5,0x3f` |
| `FUN_10049790` / `FUN_100497c0` | M_Application.cpp (span) | SysBeep(1) / GetMBarHeight | HIGH | `100497a0 bl 0x100d399c`; `100497cc bl 0x100d543c` |
| `FUN_10049820` | M_Application.cpp (span) | busy-wait n ticks (TickCount) | HIGH | `1004983c add`, `10049848 cmplw; blt` |
| `FUN_10049870` / `FUN_100498a0` | M_Application.cpp (span) | InitCursor / watch cursor (GetCursor 4) | HIGH | `1004987c bl 0x100d3774`; `100498a4 li r3,4`, `100498bc bl 0x100d3924` |
| `FUN_100498e0` | M_Application.cpp (span) | confirm alert pass-through to `FUN_10045ef0` | HIGH | `100498ec bl 0x10045ef0` with no argument setup |
| `FUN_1004a620` | unzip.c | format "Error: %s, File: %s" into a never-read buffer `0x1011bc94` | HIGH | `1004a638 lwz r3,-0x6d8c(r2)`, `1004a63c addi +0x50b`; single access of `-0x6d8c(r2)` in the image |
| `FUN_1004a840` | unzip.c | lazy fopen(path, "rb") of zip handle {path, FILE*} | HIGH | `1004a868 addi +0x363`, `1004a86c bl 0x10050390`, `1004a874 stw r3,0x4(r31)` |
| `FUN_1004a910` / `FUN_1004ad40` | input (span) | input shutdown / ISp shutdown (suspend + ISpStop) | HIGH | `1004a924 bl 0x1003a900`; `1004ad74 bl 0x1004ae30`, `1004ad7c bl 0x100d4aac` |
| `FUN_1004a950` | input (span) | per-level input reset (clear, flush 10 elements, clear polled) | HIGH | `1004a95c/64/6c`; caller `FUN_100064d0` |
| `FUN_1004ada0` / `FUN_1004af30` | input (span) | ISpElement_Flush × 10 / zero polled 2×7 if inited | HIGH | `1004adc4 bl 0x100d4e54`, `1004add0 cmpwi 0xa`; `1004af4c lbz -0x6071(r2)`, `1004af64 li r4,7` |
| `FUN_1004ae30` / `FUN_1004a9c0` | input (span) | ISp suspend (mouse class re-activated, ISpSuspend) / wrapper | HIGH | `1004ae68 bl 0x100d48fc`, `1004ae70 bl 0x100d4914`; `1004a9cc` |
| `FUN_1004aea0` / `FUN_1004a990` | input (span) | ISp resume (+ mouse class on/off by arg) / wrapper | HIGH | `1004aed8 bl 0x100d49a4`, `1004aef8`/`1004af0c`; `1004a99c` |
| `FUN_1004ae90` / `FUN_1004a9f0` | input (span) | ISp active flag `0x100e02bd` / wrapper | HIGH | `1004ae90 lbz r3,-0x6073(r2)`; `1004a9fc` |
| `FUN_1004b1e0` | input (span) | copy polled 7 bytes of player 0/1 | HIGH | `1004b1ec extsb; cmpwi 1`, `1004b218`/`1004b230 bl 0x1004b270` |
| `FUN_1004b250` | input (span) | InputSprocket present (weak ISpInit ≠ 0) | HIGH | `1004b250 lwz r3,-0x7938(r2)` |
| `FUN_1004b270` | input (span) | byte copy (dst, src, n), dst/n = 0 → return | HIGH | `1004b270–1004b2a0` |
| `FUN_1004b2b0` | MW runtime (span) | register code fragment (7-word record, 32-slot 900-byte blocks) + one-time Gestalt('ppcf') AltiVec flag; called by `entry` | MED | `1004b2fc–1004b328`, `1004b338 li r0,0x20`, `1004b3a0 li r3,0x384` |

## INDEX updates (for merge)
- **#1 closed** → §2.1–2.2. The "15 handlers" are 15 two-instruction type selectors feeding one
  shared Local-scan body. Table words recovered from the data image; the body was read by listing.
- **#2 tail ("Local first" insertion order) MED → HIGH** → §2.2. The Local loop completes before
  the Paks scan starts, so Local records precede pak records in the list.
- **#3 closed** → §2.3. Threshold = 100 (`0x64`), with no writer anywhere. It is compared after the
  override pass. The alert is non-fatal.
- **Ledger #17 (zlib reachability) MED → HIGH** → §5.1. The zip reader contains no call into zlib.
  Its inflate strings are unreferenced.
- New facts for other files:
  - the log file `: Data:<app name>.log`, truncated each launch (§4.1);
  - the anti-tamper text swap (§1.3) for player-physics.md §9 and level-scroll-objects.md §8;
  - `0x10049ca0–0x1004b400` is unzip **plus the input module**, not unzip.c only (§5).
