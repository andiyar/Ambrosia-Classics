# Deimos Rising 1.0.6 — Pak container format, tag index, text de-obfuscation

Code readings only; nothing here is behaviour-verified. Dump: `ghidra/Deimos_pef.decompiled.c`
(stripped PEF, see INDEX provenance). Addresses are Ghidra addresses (code base `0x10000000`,
data base `0x100de330`, TOC/r2 = `0x100e6330`). Data strings quoted from the decompile's `s_…`
labels or resolved from the Ghidra memory image (`docs/deimos/tools/DumpMemory.java`).

Game folder: `/Users/andiyar/Developer/Ambrosia/Resources/ambrosia-extracted/Action-Adventure/
DeimosRising/Deimos Rising 1.0.6 (volume)/Deimos Rising/` (below: `$G`). Paks: `$G/ Data/Paks/`
(note the leading space in ` Data`).

## 1. The container is a plain ZIP, STORED only

### 1.1 Census (tool output)
Command: `python3 docs/deimos/tools/list_paks.py "$G/ Data/Paks"` (summary lines, verbatim):
```
== Audio.pak: 1702614 B, 96 central-dir entries (0 folder entries, 96 files), CD at 1694243 size 8349, EOCD at 1702592; methods {0: 96}
   per type: soun=96
== Game.pak: 54956985 B, 776 central-dir entries (13 folder entries, 763 files), CD at 54882803 size 74160, EOCD at 54956963; methods {0: 776}
   per type: coli=1, film=4, flli=1, idli=6, im08=248, im16=38, leve=12, plde=2, reli=1, stli=5, tefo=54, unde=386, wede=5
== Interface.pak: 2849896 B, 11 central-dir entries (2 folder entries, 9 files), CD at 2848908 size 966, EOCD at 2849874; methods {0: 11}
   per type: im08=2, im16=7
== Music.pak: 13601894 B, 3 central-dir entries (0 folder entries, 3 files), CD at 13601605 size 267, EOCD at 13601872; methods {0: 3}
   per type: soun=3
```
Every pak reports `entries with compressed!=uncompressed size: 0`. Total files: 96+763+9+3 = 871.
Magic of every pak: `50 4B 03 04` ("PK\3\4") at offset 0. [HIGH — tool output]

### 1.2 Reader functions
| function | role | evidence |
|---|---|---|
| `FUN_10049de0` | open zip, read End-Of-Central-Directory, read whole Central Directory | strings "Reading ECD (End of Central Directory)", "Cannot span disks", "Seeking to Central Directory", "Reading Central Directory" |
| `FUN_1004a1d0` | parse next 46-byte central-directory record into a cursor struct | reads +4..+0x2a, advances by `0x2e + nameLen + extraLen + commentLen` |
| `FUN_1004a4f0` | seek local header, compute data offset | reads 30-byte local header, `+0x1a`/`+0x1c` lengths |
| `FUN_10049ca0` | per-entry accept/reject (STORED check) | strings "Compressed Zip files are not supported!", "compression size does not equal uncompressed size" |
| `FUN_1004a660` / `FUN_1004a680` | little-endian u16 / u32 readers | used for every ZIP field |
| `FUN_1004a6b0` | ECD search retry | "Retry reading of ECD for %d bytes" |
| `FUN_1004a470` | close zip | called after the entry loop in `FUN_100016c0` |

`FUN_1004a1d0 @ 1004a1d0` (central directory record → cursor fields; `p = base + pos`):
```c
    uVar3 = FUN_1004a660(param_1[5] + param_1[6] + 10);      // method   (cd+10)
    *(undefined2 *)((int)param_1 + 0x26) = uVar3;
    uVar2 = FUN_1004a680(param_1[5] + param_1[6] + 0x14);    // csize    (cd+20)
    param_1[0xc] = uVar2;
    uVar2 = FUN_1004a680(param_1[5] + param_1[6] + 0x18);    // usize    (cd+24)
    param_1[0xd] = uVar2;
    uVar3 = FUN_1004a660(param_1[5] + param_1[6] + 0x1c);    // nameLen  (cd+28)
    ...
    uVar2 = FUN_1004a680(param_1[5] + param_1[6] + 0x2a);    // local header offset (cd+42)
    param_1[0x12] = uVar2;
    ...
      param_1[6] = (uint)*(ushort *)(param_1 + 0xe) + (uint)*(ushort *)((int)param_1 + 0x3a) +
                   (uint)*(ushort *)(param_1 + 0xf) + param_1[6] + 0x2e;
```
`FUN_10049ca0 @ 10049ca0` (the STORED-only rule):
```c
    if (*(short *)((int)param_1 + 0x26) == 0) {          // method must be 0 (stored)
      if (param_1[0xc] == param_1[0xd]) {                // csize must equal usize
        iVar2 = FUN_1004a4f0(param_1,param_1 + 7);       // -> data offset
        ...
            *(undefined4 *)(param_2 + 0x204) = param_1[0xc];
```
`FUN_1004a4f0 @ 1004a4f0` (data offset = local header offset + 30 + local nameLen + local extraLen):
```c
  iVar2 = FUN_10051890(param_1[1],*(undefined4 *)(param_2 + 0x2c),0);          // seek LHO
  ...  iVar2 = FUN_1004fa20(auStack_38,0x1e,1,param_1[1]);                      // read 30 bytes
      uVar4 = FUN_1004a660(auStack_1e);   uVar5 = FUN_1004a660(auStack_1c);     // +26,+28
      iVar2 = FUN_10051890(param_1[1],
                           *(int *)(param_2 + 0x2c) + (uVar4 & 0xffff) + (uVar5 & 0xffff) + 0x1e,0);
```
Claims:
- Method must be 0 and compressed size must equal uncompressed size, otherwise the entry is
  rejected with the "Compressed Zip files are not supported!" message and an assert
  (`FUN_10000f30`). [HIGH — read in code; all constants literal]
- Data for an entry starts at `LHO + 30 + localNameLen + localExtraLen` (from the LOCAL header,
  not the central one). [HIGH]
- The zlib inflate code is linked (strings "inflateInit error", "invalid distance code", …) but
  `FUN_10049ca0` never reaches it; all 871 shipped entries are method 0. [MED — the inflate
  callers were not traced; the gate above is HIGH]

### 1.3 Byte tables (standard PKZIP 2.0 — little-endian)
Local file header (30 bytes + name + extra), at `LHO`:
| off | size | field | Deimos value |
|---|---|---|---|
| 0 | 4 | signature `50 4B 03 04` | |
| 4 | 2 | version needed | `0x0014` on 870 files; `0x000A` on the 15 folders **and 1 file**, `Music.pak:Ambient Music Loop[ammu].IMA` (⚑ corrected (review 2026-10-03) #11; Python `zipfile` census: 870 files 20, 1 file 10, 15 folders 10). The game does not read this field. |
| 6 | 2 | flags | 0 |
| 8 | 2 | method | **0 (stored)** |
| 10 | 4 | DOS time+date | |
| 14 | 4 | CRC-32 | (not checked by the game — no CRC call found; [LOW]) |
| 18 | 4 | compressed size | = uncompressed |
| 22 | 4 | uncompressed size | |
| 26 | 2 | name length | |
| 28 | 2 | extra length | 18 (`0x12`) on all 886 entries |
| 30 | n | name (Mac Roman, `/` folder separator) | |
| 30+n | x | extra field (ZipIt Mac, below) | |

Central directory record (46 bytes + name + extra + comment): standard PKZIP; fields the game reads
are listed in `FUN_1004a1d0` above (+10 method, +20 csize, +24 usize, +28 nameLen, +30 extraLen,
+32 commentLen, +42 local header offset). End of central directory (22 bytes): `50 4B 05 06`,
+10 total entries, +12 CD size, +16 CD offset.

Extra field id `0x2705` "ZipIt Macintosh (short form)": `05 27` id, `0E 00` size 14, `"ZPIT"`,
then for files 4-byte Mac file type + 4-byte creator + 2 bytes Finder flags; for folders 4+4 zero
bytes + `03 E0`. The game never reads it (the data offset skips it by length) [MED — no reader
found; "never" is a negative claim]. Type/creator per entry are shown by `list_paks.py`
(e.g. `GIFf/Cit2`, `TPIC/GKON`, `AIFC/Nqst`, `TEXT/CWIE`, `Data/Deim`) — authoring-tool residue,
irrelevant to loading (the type comes from the file-name suffix, §2.2).

### 1.4 Worked decode — Interface.pak (smallest pak)
Command: `xxd -s 2849874 "$G/ Data/Paks/Interface.pak"` (EOCD):
```
002b7c52: 504b 0506 0000 0000 0b00 0b00 c603 0000  PK..............
002b7c62: 8c78 2b00 0000                           .x+...
```
→ disk 0, cd-disk 0, entries-this-disk `0x000b`=11, total `0x000b`=11, CD size `0x03c6`=966,
CD offset `0x002b788c`=2848908, comment length 0. Matches the tool census line.

Command: `xxd -s 2848908 -l 200 "$G/ Data/Paks/Interface.pak"` (first CD records):
```
002b788c: 504b 0102 1407 0a00 0000 0000 4758 ac28  PK..........GX.(
002b789c: 0000 0000 0000 0000 0000 0000 0500 1200  ................
002b78ac: 0000 0000 0000 1000 ed41 0000 0000 696d  .........A....im
002b78bc: 3136 2f05 270e 005a 5049 5400 0000 0000  16/.'..ZPIT.....
002b78cc: 0000 0003 e050 4b01 0214 070a 0000 0000  .....PK.........
...
002b790c: 0000 0000 0000 0000 03e0 504b 0102 1407  ..........PK....
002b791c: 1400 0000 0000 8a81 ff28 6bba 838a 1260  .........(k....`
002b792c: 0900 1260 0900 1f00 1200 0000 0000 0000  ...`............
002b793c: 0000 a481 6a00 0000 696d 3136 2f44 6576  ....j...im16/Dev
```
Record 1 (folder): made-by `0x0714`, need `0x000a`, flags 0, **method 0**, csize 0, usize 0,
nameLen 5, extraLen 18, commentLen 0, LHO 0, name `im16/`, extra `05 27 0e 00 "ZPIT" 00…00 03 e0`.
Record 3 (file, at `0x2b7918`): need `0x0014`, method 0, CRC `0x8a83ba6b`, csize `0x00096012` =
614418, usize 614418 (equal ⇒ accepted by `FUN_10049ca0`), nameLen `0x1f`=31, extraLen 18,
LHO `0x6a`=106, name `im16/Developer Credit[decr].TGA`.

Command: `xxd -s 0x6a -l 0x60 "$G/ Data/Paks/Interface.pak"` (that entry's local header):
```
0000006a: 504b 0304 1400 0000 0000 8a81 ff28 6bba  PK...........(k.
0000007a: 838a 1260 0900 1260 0900 1f00 1200 696d  ...`...`......im
0000008a: 3136 2f44 6576 656c 6f70 6572 2043 7265  16/Developer Cre
0000009a: 6469 745b 6465 6372 5d2e 5447 4105 270e  dit[decr].TGA.'.
000000aa: 005a 5049 542e 7461 6754 6167 6701 0000  .ZPIT.tagTagg...
000000ba: 0002 0000 0000 1800 0000 0080 02e0 0110  ................
```
Data offset = 0x6a + 30 + 31 + 18 = 0x6a + 79 = **185** (= `@185` in the tool listing). At 185
(`0xb9`) the TGA header starts: `00 00 02 00 00 00 00 00 00 00 00 00 80 02 e0 01 10 01` = type 2,
640×480, 16 bpp, descriptor 1 (see sprite-sound-containers.md §3).

## 2. Entry naming and the tag index (U_Pak.cc)

### 2.1 Name → (display name, tag ID, suffix)
`FUN_100021a0 @ 100021a0` (module U_Pak.cc by assert string `0x100e31ff`="U_Pak.cc"):
- display name = characters before the first `[`;
- tag ID = exactly 4 characters between `[` and `]` (`FUN_10003a40`: `strtok`-style search for
  `0x100e38e2`="[" then `0x100e38e4`="]", `strlen == 4` required);
- type = from the suffix (§2.2).
Failure strings: "Could not find Tag ID in file", "Could not find a valid suffix in file".
`FUN_10004230` rebuilds a name with format `0x100e38eb` = `"%s[%s].%s"`. [HIGH]

Tag IDs are case-sensitive 4-byte big-endian codes (`[bocr]` ≠ `[BOCR]`); an ID of `none`
(`0x6e6f6e65`) means "no resource" everywhere in the engine. [HIGH — `0x6e6f6e65` comparisons
throughout, e.g. `FUN_10047330`, `FUN_100095b0`]

### 2.2 Suffix → resource type (`FUN_10003b20 @ 10003b20`)
The suffix is copied from the FIRST `.` in the name (max 15 chars) and compared (`FUN_10057820`,
strcmp) against 15 pointer tables in this fixed order; first match wins. Tables dumped from the
memory image (`python3 rd.py` over `mem/100de330.bin`, addresses `0x100e2bc4…0x100e2d90`):
| type (4CC returned) | accepted suffixes |
|---|---|
| `im08` 0x696d3038 | .im08 .Im08 .IM08 .gif .GIF .giff .GIFf .GIFF |
| `im16` 0x696d3136 | .im16 .Im16 .IM16 .tga .TGA .Targa .targa .TARGA |
| `soun` 0x736f756e | .snd .Snd .SND .sound .Sound .SOUND .aif .Aif .AIF .aiff .Aiff .AIFF .ima .IMA |
| `stli` 0x73746c69 | .txt .Txt .TXT .text .Text .TEXT .string .String .STRING .stli .Stli .STLI |
| `flli` 0x666c6c69 | .flt .Flt .FLT .float .Float .FLOAT .flli .Flli .FLLI |
| `wede` 0x77656465 | .we .WE .wep .Wep .WEP .wede .Wede .WEDE |
| `reli` 0x72656c69 | .rect .Rect .RECT .reli .Reli .RELI .rectlist .RectList .RECTLIST |
| `idli` 0x69646c69 | .id .ID .Id .idli .IDLI .Idli .idlist .IDLIST .IDList |
| `coli` 0x636f6c69 | .co .CO .Co .coli .COLI .Coli .color .COLOR .Color .colorlist .COLORLIST .ColorList |
| `tefo` 0x7465666f | .tefo .Tefo .TEFO .textformat .TEXTFORMAT .Textformat .TextFormat |
| `plde` 0x706c6465 | .plde .Plde .PLDE .player .PLAYER .Player |
| `pref` 0x70726566 | .pref .Pref .PREF |
| `film` 0x66696c6d | .film .Film .FILM |
| `unde` 0x756e6465 | .unde .Unde .UNDE .unitdef .UnitDef .UNITDEF .unit |
| `leve` 0x6c657665 | .lvl .Lvl .LVL .leve .Leve .LEVE .level .Level .LEVEL |
[HIGH — table bytes read, loop counts 8/8/14/12/9/8/9/9/12/7/6/3/3/7/9 literal in the code]

Consequence: the folder name inside the zip (`im08/`, `unde/` …) is NOT what types an entry;
the suffix is. The folders mirror the type names by authoring convention. [HIGH]

### 2.3 Building the index (`FUN_100016c0 @ 100016c0`, "Building Tag Index")
1. Scan `Data:Local` first: a 15-way jump table at `PTR_LAB_100e2db4` (one handler per type
   sub-folder `coli film flli idli im08 im16 leve plde pref reli soun stli tefo unde wede` —
   the 15 folders that exist in `$G/ Data/Local/`). Ghidra could not recover the jump table
   ("Could not recover jumptable at 0x10001790"), so the per-folder handler is unread. [MED for
   "Local first"; the handlers are NOT RESOLVED]
2. Scan `" Data:Paks"` (`s_Data_Paks_100e331c`): each file whose suffix passes `FUN_100040c0`
   (".zip" `0x100e2dff` or ".pak" `0x100e2e04`) is opened with `FUN_10049de0`; every accepted
   entry with non-zero size becomes a 0x158-byte tag record:
   ```c
            puVar2 = (undefined4 *)FUN_1004d320(0x158);
            *puVar2 = 0x499602d2;                 // record magic 1234567890
            ...
              puVar2[1] = local_8cc;              // type 4CC
              puVar2[2] = local_8c8;              // tag ID 4CC
              puVar2[3] = local_2c;               // data offset in the zip
              puVar2[0x54] = local_28;            // size
              FUN_10057780(puVar2 + 0x44,auStack_12c);   // entry name
              FUN_10057780(puVar2 + 4,auStack_22c);      // zip path
   ```
   Non-zip files in Paks are skipped ("Only Zip files are supported in the Paks directory");
   `.DS_Store` silently. Zip files in Local are skipped ("Zip files are not supported in the Local
   directory"). [HIGH for the Paks path and record fields]
3. Duplicate (type,ID) pairs are counted (`FUN_10003970`) and logged "Duplicate (%i) tags
   found" (non-fatal); `FUN_10004300` then resolves overrides, logging `"Tag Overridden: …"`.
   Which copy wins (Local vs Pak, or pak order) is NOT RESOLVED (`FUN_10004300`/`FUN_100043c0`
   not read). The intent stated by strings ("Local Folder" scanned first, "Tag Overridden") is
   that Local files override pak entries. [LOW] ⚑ corrected (wave 2, 2026-10-03): was "Which copy wins … NOT
   RESOLVED" — each Local record removes every non-Local record with the same (type, ID); pak
   duplicates are both kept and the first in list order wins — see loose-ends-session.md §8.7.
4. If the index holds fewer tags than `_DAT_100e00ec` → "Tag Index Incomplete! Aborting."
   (`FUN_10000fd0`, fatal). The threshold value is NOT RESOLVED (set elsewhere). [MED]
   ⚑ corrected (wave 2, 2026-10-03): was "fatal" — `FUN_10000fd0` calls `FUN_1000ced0("Error", msg, 0)`
   (`10000fdc li r4,0x0`), which shows the alert and returns, so the game continues (unless the
   alert routine `FUN_10045ab0` itself quits, MED) — see loose-ends-session.md §8.2.

### 2.4 Reading an entry
`FUN_10002850(type, id)` / `FUN_10002a20` / `FUN_10002be0(index, type, &id)` open the owning zip
and return a pointer/handle to the stored bytes ("couldn't open file", "Required Tag '%s' not
found in Tag Index"). `FUN_10002080(type,id,path,&offset,&length)` returns the zip path plus the
byte range instead — used for music streaming straight out of `Music.pak` (`FUN_10047f90`, see
sprite-sound-containers.md §5). `FUN_10002640` writes a tag back as a loose file under
`Data:Local` (type `Data`, creator `Deim`, 4CCs 0x44617461/0x4465696d) — used for the "Last Film"
replay (`FUN_100095b0` → `FUN_100025b0`). [MED — callers read, internals skimmed]

`$G/ Data/Local/film/Last Film[last].film` is byte-identical to `Game.pak:film/Demo 01[de01].film`
(command: `md5 -q` on both → `a3c680e39d252ba52603593519f4bfcc` twice). [HIGH — tool output]

## 3. Text-resource obfuscation (all data text types)

`FUN_10046470 @ 10046470` — in-place, length-driven, involutive:
```c
      *param_1 = (*param_1 >> 4 | *param_1 << 4) ^ 0xff;
```
i.e. `plain = ~rotl8(cipher, 4)` (swap nibbles, invert). The same function encodes and decodes.
[HIGH — read directly; 20 callers listed by `find_func.py 'FUN_10046470\('`]
⚑ corrected (review 2026-10-03) #10: was "21 callers"; the 21 blocks `find_func.py` prints include the definition
`void FUN_10046470(` itself.

Applied to: every `stli flli wede reli idli coli tefo plde unde leve` entry before parsing
(e.g. `FUN_10002e50` stli reader, `FUN_100204a0` flli loader, `FUN_10003520` idli reader,
`FUN_10012230` leve); the hard-coded level-order table (§ engine-loop.md 6), the cheat word in
`FUN_100051a0`, high-score names in prefs (`FUN_10004640`/`FUN_10004f80`). `FUN_1003fda0` (unit
defs) decodes only when the plain text `"#name_STR"` is NOT found, so unde files may be shipped
plain or encoded. [HIGH for the `FUN_1003fda0` test; MED that every other loader always decodes
— each was read individually, but plain-text fallbacks in the other loaders were not searched]

Worked decode — `Game.pak:coli/Colors[gaco].coli` (30 bytes). Command:
`python3 docs/deimos/tools/list_paks.py "$G/ Data/Paks" --decode /tmp/x` then
`xxd "/tmp/x/Game/coli/Colors[gaco].coli"`:
```
cd c8 c9 09 d8 a9 db e9 d8 0a bb 69 89 69 b8 6f 6f 6f 6f 6f 6f 6f 3c ac dc c9 ac 6c bc 1c
```
`0xcd`: swap → `0xdc`, invert → `0x23` `#`; `0x3c` → `0xc3` → `0x3c` `<`; `0x6f` → `0xf6` → `0x09`
TAB; `0x1c` → `0xc1` → `0x3e` `>`. Whole file: `#scoreBar_Digit<7×TAB><52c594>`.
Line ends are CR (`0x2f` → `0xf2` → `0x0d`); some files use CR LF (`0x5f` → `0x0a`). [HIGH]

## 4. Census of ` Data/` (tool output)
Command: `cd "$G"; find . -type f ! -name .DS_Store -exec ls -la {} \;` (sizes):
| path | bytes | identification |
|---|---|---|
| ` Data/Paks/Game.pak` | 54956985 | ZIP, 763 files (all game data except audio/interface) |
| ` Data/Paks/Music.pak` | 13601894 | ZIP, 3 AIFC ima4 stereo music files |
| ` Data/Paks/Interface.pak` | 2849896 | ZIP, 9 files (menus, logos, small text font) |
| ` Data/Paks/Audio.pak` | 1702614 | ZIP, 96 AIFC ima4 mono sound effects |
| ` Data/Local/film/Last Film[last].film` | 40296 | loose replay = Demo 01 (§2.4) |
| ` Data/Local/<15 type folders>/Icon` | 0 | empty override folders (Icon files only) |
| ` Data/HID.bundle/Contents/MacOS/libHIDUtilities.dylib` | 447884 | Mach-O ppc dylib (`file`), OS X HID helper — identify only |
| ` Data/HID.bundle/Contents/Info.plist` | 526 | CFBundleExecutable libHIDUtilities.dylib, version 0.0.1d1 |
| `Deimos Rising` | 2045976 | PEF `Joy!peffpwpc` + resource fork 151602 B (xattr) |
| `Register Deimos Rising` | 1143368 | PEF (`Joy!peffpwpc`) — registration app, out of scope |
| `Deimos Rising Player Guide/Deimos Guide.html` | 44767 | rules oracle (+ 50 GIF/JPG images) |
Local sub-folders present: `coli film flli idli im08 im16 leve plde pref reli soun stli tefo
unde wede` (15; `tefo` and `unde` contain nothing at all). [HIGH — `ls -la` output]

## 5. Full listing tool and first-20 output
Full listing (871 file lines): `python3 docs/deimos/tools/list_paks.py "$G/ Data/Paks" --all`.
Columns: type, tag ID, size, data offset, ZipIt type/creator, entry name. First 20 per pak
(command without `--all`, verbatim):
```
== Audio.pak: 1702614 B, 96 central-dir entries (0 folder entries, 96 files), CD at 1694243 size 8349, EOCD at 1702592; methods {0: 96}
   soun acbo     15060 @72        AIFC/Nqst  Accuracy Bonus[acbo].IMA
   soun bash      6084 @15205     AIFC/Nqst  Baccula Shields[bash].IMA
   soun bgbu      9008 @21365     AIFC/Nqst  Bacta Gun - Bullet[bgbu].IMA
   soun balh     17508 @30449     AIFC/Nqst  Bang - Loud Hollow[balh].IMA
   soun bass     13388 @48032     AIFC/Nqst  Bang - Soft Short[bass].IMA
   soun baso     16992 @61489     AIFC/Nqst  Bang - Soft[baso].IMA
   soun bocr      6798 @78550     AIFC/Nqst  Bomb Crater[bocr].IMA
   soun bop       5364 @85409     AIFC/Nqst  Bop[bop ].IMA
   soun cabo     20058 @90841     AIFC/Nqst  Cash Bonus[cabo].IMA
   soun cash      5922 @110961    AIFC/Nqst  Cash[cash].IMA
   soun clic       788 @116946    AIFC/Nqst  Click[clic].IMA
   soun cohi      5616 @117800    AIFC/Nqst  Coin Hit[cohi].IMA
   soun cbba     31788 @123491    AIFC/Nqst  Cyclo Bomber Bang[cbba].IMA
   soun cbgu     28320 @155353    AIFC/Nqst  Cyclo Bomber Gun[cbgu].IMA
   soun cbla     40900 @183750    AIFC/Nqst  Cyclo Bomber Launch[cbla].IMA
   soun cbsh      7758 @224727    AIFC/Nqst  CycloBomber Shields[cbsh].IMA
   soun elst      7614 @232557    AIFC/Nqst  Electric Steel[elst].IMA
   soun elri     15536 @240243    AIFC/SCPL  Electro Ripple[elri].IMA
   soun ex2s     39426 @255849    AIFC/Nqst  Ex - 2 Stage[ex2s].IMA
   soun exae     17576 @295349    AIFC/SwRx  Ex - Abrupt Echo[exae].IMA
== Game.pak: 54956985 B, 776 central-dir entries (13 folder entries, 763 files), CD at 54882803 size 74160, EOCD at 54956963; methods {0: 776}
   im08 EXSR      3319 @186       GIFf/Cit2  im08/Expl Small Red IA[EXSR].gif
   im08 exsr      3981 @3585      GIFf/Cit2  im08/Expl Small Red IC[exsr].gif
   im08 BOCR       476 @7696      GIFf/Cit2  im08/Bomb Crater IA[BOCR].gif
   im08 bocr       305 @8249      GIFf/Cit2  im08/Bomb Crater IC[bocr].gif
   im08 BASH      5637 @8688      GIFf/Cit2  im08/Baccula Shields IA[BASH].gif
   im08 bash     37074 @14406     GIFf/Cit2  im08/Baccula Shields IC[bash].gif
   im08 BGBU      4370 @51562     GIFf/Cit2  im08/Bacta Gun Bullet IA[BGBU].gif
   im08 bgbu      6035 @56014     GIFf/Cit2  im08/Bacta Gun Bullet IC[bgbu].gif
   im08 BAGU      4506 @62124     GIFf/Cit2  im08/Bacta Gun IA[BAGU].gif
   im08 bagu      6553 @66705     GIFf/Cit2  im08/Bacta Gun IC[bagu].gif
   im08 BURS     15903 @73329     GIFf/Cit2  im08/Burst IA[BURS].gif
   im08 burs      2554 @89303     GIFf/Cit2  im08/Burst IC[burs].gif
   im08 BUZZ      4264 @91930     GIFf/Cit2  im08/Buzzsaw IA[BUZZ].gif
   im08 buzz      8459 @96267     GIFf/Cit2  im08/Buzzsaw IC[buzz].gif
   im08 EDUT       878 @104806    GIFf/Cit2  im08/Editor Utility IA[EDUT].gif
   im08 edut      1241 @105764    GIFf/Cit2  im08/Editor Utility IC[edut].gif
   im08 GALO      1351 @107080    GIFf/Cit2  im08/Game Logo IA[GALO].gif
   im08 galo     10403 @108506    GIFf/Cit2  im08/Game Logo IC[galo].gif
   im08 ICBU      4843 @118992    GIFf/Cit2  im08/Ion Cannon Bullet IA[ICBU].gif
   im08 icbu      4858 @123918    GIFf/Cit2  im08/Ion Cannon Bullet IC[icbu].gif
== Interface.pak: 2849896 B, 11 central-dir entries (2 folder entries, 9 files), CD at 2848908 size 966, EOCD at 2849874; methods {0: 11}
   im16 decr    614418 @185       .tag/Tagg  im16/Developer Credit[decr].TGA
   im16 edpa    107538 @614678    TPIC/GKON  im16/Editor Panel[edpa].TGA
   im16 pucr    177858 @722295    TPIC/GKON  im16/Publisher Credit[pucr].TGA
   im08 TESM      4744 @900231    GIFf/Cit2  im08/Text - Small IA[TESM].gif
   im08 tesm      1972 @905053    GIFf/Cit2  im08/Text - Small IC[tesm].gif
   im16 back    614444 @907098    TPIC/8BIM  im16/Background[back].TGA
   im16 menu    614444 @1521609   TPIC/8BIM  im16/Menu[menu].TGA
   im16 BIGR     98282 @2136133   TPIC/GKON  im16/Editor Background[BIGR].TGA
   im16 adve    614418 @2234490   TPIC/GKON  im16/Advertisment[adve].TGA
== Music.pak: 13601894 B, 3 central-dir entries (0 folder entries, 3 files), CD at 13601605 size 267, EOCD at 13601872; methods {0: 3}
   soun mu03   9172810 @65        AIFF/TVOD  Music 3[mu03].aif
   soun ammu   1629918 @9172951   AIFC/Nqst  Ambient Music Loop[ammu].IMA
   soun inmu   2798658 @10802947  AIFC/Nqst  Interface Music Loop[inmu].IMA
```
