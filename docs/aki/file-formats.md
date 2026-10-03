# Aki — on-disk formats (both versions)

Labels as in `rules.md`. Real files used: the 36 level files in
`…/Aki 1.2 UB/Aki Custom Level Pack 1/` (path abbreviated `$C` below).

## 1. Custom level file (`.aki`, HFS type `LVLE`, creator `AKII`)

### 1.1 Identity [HIGH]
- 1.2 `Info.plist` `CFBundleDocumentTypes`: name "Level", OSType `LVLE`, role Editor, icon
  `Aki_Doc_ICON`, "MIME type" `AKII` (sic). (`plutil -p Info.plist`, this session.)
- 1.2 open panel accepts extension `aki` **or** HFS type `LVLE`
  (`[NSArray arrayWithObjects:@"aki", NSFileTypeForHFSTypeCode(0x4c564c45), nil]` in
  `_LoadCustomLevel` @ 0x14177 and `_LoadFile` @ 0xcb60). Save panel: required type `aki`, default
  name "My Custom Level"; the file is created with `NSFileHFSTypeCode = 'LVLE'`,
  `NSFileHFSCreatorCode = 'AKII'` (`_DoSaveAs` @ 0xb89d).
- 1.1: `FT_FileOpenPicker(…, 0x4c564c45 /*LVLE*/ …)` — type only, no extension test;
  `FT_FileSavePicker(0, "My Custom Level.aki", …)` with `LVLE`/`AKII` (`LoadCustomLevel` @ 0x2155c,
  `DoSaveAs` @ 0x1b77c).
- Real files: `GetFileInfo "$C/A"` → `type: "LVLE" creator: "AKII"`; the pack files have **no**
  extension, so 1.2 can only open them through the HFS type (or after renaming to `.aki`).

### 1.2 Byte layout [HIGH — reader and writer read in code, confirmed on all 36 files]
ASCII text, LF line ends, fixed-width:
| offset | len | content | reader (`_LoadCustomLevel`) | writer (`_DoSaveAs`) |
|---|---|---|---|---|
| 0 | 4 | tile count, 3 digits zero-padded + `\n` (`144\n`) | `_FT_FileRead(f,4,buf); buf[4]=0; StringToNumber` | "0"/"00" padding by the `count−10 > 89` test, `StringFromNumber`, `"\n"` |
| 4+8k | 3 | x, 2 digits zero-padded + space | `FT_FileRead(f,3)` → `g+0x1d8` → tile+0x10 | `"0"` if x < 10.0 (DOUBLE_00033fc8), number, `" "` |
| 7+8k | 3 | y, same | → `g+0x1e0` → tile+0x08 | same |
| 10+8k | 1 | layer z, 1 digit, 0 = bottom … 6 = top | `FT_FileRead(f,1)` → tile+0x00 | `StringFromNumber(z)` |
| 11+8k | 1 | `\n` | read and discarded | `"\n"` |
Coordinates are **half-units already** (no doubling, unlike `_AddTile`); the reader sets the screen
offset g+0x94 = g+0x98 = 0. Record order = list order (matters for dealing/hint order, rules §5, §9).

Worked example (command and output from this session):
```
$ xxd "$C/A" | head -3
00000000: 3134 340a 3135 2030 3120 300a 3137 2030  144.15 01 0.17 0
00000010: 3120 300a 3133 2030 3320 300a 3139 2030  1 0.13 03 0.19 0
00000020: 3320 300a 3131 2030 3520 300a 3231 2030  3 0.11 05 0.21 0
```
`144\n` → 144 tiles. Record 0 = bytes 4..11 `31 35 20 | 30 31 20 | 30 | 0a` → x = 15, y = 1, z = 0.
Screen position (rules §7 formula, z = 0, offsets 0): left = int(23·15) = 345, top = int(27.5·1) = 27.
Record 1 `17 01 0` → x = 17 (one full tile to the right). File length 1156 = 4 + 144·8. ✓

Census over the pack (script in this session, iterating `$C/*` minus `.rtf`, `Icon\r`, dotfiles):
36 files; every header is `144\n`; every record has spaces at +2/+5 and `\n` at +7 (0 bad
separators); ranges over all files: **x 0..32, y 0..17, z 0..6**; 0 duplicate records within the
first 144 of any file. 35 files are 1156 bytes; **"Piles of Pain" is 2308 bytes = 288 records**
with header 144 — the loader reads only the first 144 (the rest is ignored; 28 of the extra 144
records duplicate first-half records).

### 1.3 Validation and malformed input
| condition | 1.2 behaviour (code reading) | label |
|---|---|---|
| header ≠ 144 | file is opened **in the Level Editor** (`_AnimationMapScreenToLevelEditor`, `_LoadFile(fileRef)`) and dialog 0x51 ("Transfer" nib) shown | [HIGH] |
| header = 144 | exactly 144 records read; no range, layer, overlap, support or duplicate check | [HIGH] |
| short file | `FT_FileRead` results ignored in 1.2 → remaining fields parse from stale buffers | [MED] (library FT_ code not in dump) |
| non-digit field | `StringToNumber` (Matt Slot toolkit, stub only) — result for garbage unknown | NOT RESOLVED |
| FT_FileOpen error −7209 (0xe3d7) | dialog 0x56 ("Permissions") | [HIGH] code; meaning of −7209 [LOW] |
| FT_FileOpen error −7203 | dialog 0x58 ("FileNotFound"), forget last file, disable Replay | [HIGH] |
The editor writes whatever count it has (1..144) and refuses more than 144 tiles; files with < 144
tiles are "incomplete" (g+0x228 → dialog 0x50 "Incomplete" after saving). The editor's own reader
(`_LoadFile`) accepts any header count and reads that many records. [HIGH]
1.1 reader is the same format and the same 144 test; it additionally `printf`s FT errors. [HIGH]

### 1.4 Editor grid ↔ file [HIGH]
`_CreateTile` @ 0xc6ec: column = (h − 20)/23.0 (≤ 32), row = (v + 7)/27.5 (≤ 17), layer = current
editor layer 0..6 (buttons or keys 1–7). `_CheckNotOverlap` @ 0xa5e5: same layer & same cell →
removes it (toggle); same layer & within ±1 in both axes → rejected (cancel sound). **No cross-layer
check** — a tile may float over nothing. Max 144 tiles. Nudge arrows / arrow keys shift all tiles
by 1 half-unit unless one would leave the grid (`_SlideLeft` @ 0xa0a9 refuses if any x == 0).

## 2. Preferences and statistics — 1.2 (`NSUserDefaults`)

### 2.1 Keys [HIGH]
Complete list of `__cfstring` literals in the binary (all 92 decoded this session,
`flags 0x7c8`/`0x7d0`): the only key the game itself stores is **`GameSettings`** (cfstring @
0x345d0), an `NSData` written by `_SavePrefs` @ 0x2882c (`setObject:forKey:`) and read by
`_LoadPrefs` @ 0x293f6. Other defaults touched: `SUCheckAtStartupKey`,
`SUAutomaticVersionCheckEnabledKey` (Sparkle constants, imported symbols at 0x38018/0x3801c;
out of scope). Registration (RT3) keeps its own license file/CFPreferences — out of scope.
Domain = bundle id `com.ambrosiasw.aki` (Info.plist) → `~/Library/Preferences/com.ambrosiasw.aki.plist`.
[MED] for the path (standard NSUserDefaults behaviour, not read in code).

### 2.2 `GameSettings` blob — 143 bytes, packed, big-endian multi-byte fields [HIGH]
Derived by walking `_SavePrefs` (`appendBytes:length:` calls in order, `<<8|>>8` swaps) and
cross-checked against `_LoadPrefs` (`puVar9 + 0x17`, `+0x5f`, …).
| blob off | len | field (`_p` offset) | meaning | default (no key) |
|---|---|---|---|---|
| 0..11 | 12×u8 | p+0x200..0x20b | level i unlocked | 1,0,0,…,0 |
| 12 | u16 | p+0x20c | difficulty 0 Hard / 1 Medium / 2 Easy / 3 Practice | 1 |
| 14 | u16 | p+0x20e | bit1 = Music on (Prefs `_musicCheckbox`); bit0 = registered (recomputed each launch by the RT3 check in `_LoopMusic(1)`) | 2 |
| 16 | u16 | p+0x210 | bit1 = Sound on (`_soundCheckbox`); bit0 preserved by `save:` but never set by code read; `_PlaySound` tests `!= 0` | 2 |
| 18 | u8 | p+0x212 | Fullscreen (`_fullscreenCheckbox`) | 0 |
| 19 | u8 | p+0x213 | Tile Animation (`_animationCheckbox`) | 1 |
| 20 | u8 | p+0x214 | Display Level Description (`_descriptionCheckbox` and the LevelDescription window's checkbox) | 1 |
| 21 | u8 | p+0x215 | first launch → `finishLaunch:` clears it, saves, shows `SplashScreen("welcome")` (C string @ 0x32ac3, read from `otool -tV`) | 1 |
| 22 | u8 | p+0x216 | unused in 1.2 (1.1 Preferences had a control for it; never read) | 1 |
| 23 | 12×u16 | p+0x218 | wins per level (Practice wins included) | 0 |
| 47 | 12×u16 | p+0x230 | losses per level (time-outs only) | 0 |
| 71 | 12×u16 | p+0x248 | give-ups per level | 0 |
| 95 | 12×u32 | p+0x260 | best time per level, seconds (0 = none; Practice excluded) | 0 |
Total 95 + 48 = **143** bytes. Checkbox ↔ ivar mapping is HIGH: `otool -oV` gives `Preferences`
ivars `_soundCheckbox` 0x28, `_fullscreenCheckbox` 0x2c, `_animationCheckbox` 0x30,
`_musicCheckbox` 0x34, `_descriptionCheckbox` 0x38, and `-[Preferences save:]` @ 0x62ee writes
0x28→p+0x210, 0x34→p+0x20e, 0x30→p+0x213, 0x38→p+0x214, 0x2c→p+0x212 (toggling fullscreen
also calls `toggleFullscreen:`). Nib titles (from `Preferences.nib/keyedobjects.nib` strings):
Sound, Music, Tile Animation, Fullscreen, Display Level Description.
No real `GameSettings` blob exists on this machine (`defaults read com.ambrosiasw.aki` → domain
not found), so no worked example from a real file: **NOT RESOLVED (no sample)**.

Statistics window (`_CreateNewDialog(0x3c)`, nib "Stats" in `Aki.nib`): for level i (0..11) it fills
control IDs 401+i (best minutes = t/60), 413+i (seconds = t%60), 1+i (wins), 13+i (losses),
25+i (give-ups), and totals in IDs 40 (wins), 41 (losses), 42 (give-ups). [HIGH] for the IDs and
arithmetic; which on-screen column is which label is in the nib XML (not read).

### 2.3 Migration from 1.1 [HIGH]
If `GameSettings` is absent, `_LoadPrefs` sets the defaults above, then tries
`FindFolder(kOnSystemDisk /*0x8000*/, 'pref')` + `":Aki Prefs"`; if that file opens it reads
**0x290 bytes raw into `_p`** and byte-swaps the u16/u32 fields (it is the 1.1 struct, §3). There
is no write-back to the old file; the next `_SavePrefs` writes `GameSettings`.

## 3. Preferences and statistics — 1.1 [HIGH]
`SavePrefs` @ 0xa348: deletes and recreates `<Preferences folder>/Aki Prefs` with
`FSpCreate(…, creator '*LMS' (0x2a4c4d53), type 'Pref' (0x50726566))`, writes the whole 0x290-byte
`PrefsType` struct (big-endian, the same offsets as 1.2's `_p`: unlock 0x200, difficulty 0x20c,
0x20e, 0x210, flags 0x212..0x216, wins 0x218, losses 0x230, give-ups 0x248, best 0x260). Bytes
0x000..0x1ff are two 256-byte areas cleared by `SetDefaultPrefs` and never read by game code —
NOT RESOLVED purpose (likely legacy Pascal strings). Defaults (`SetDefaultPrefs` @ 0xa424) are the
same values as 1.2's table. No sample file found in the archive (`find … -iname '*aki prefs*'` → none).

## 4. Other on-disk artefacts
- None written by the game besides §1–3. `find_func.py 'createFileAtPath|_FSpCreate|FT_FileSave|_fwrite|FSpCreateResFile' --names`
  hits only `_DoSaveAs`, RT3 (`__RT3_WriteLogEntry`, `__RT3_LicenseSave`, `_WriteToFileAsSuperUser`
  — out of scope) and `_MakeRelativeAliasFile` @ 0x283a2 (creates an `alis` resource file; no
  caller in the dump — dead code). [HIGH]
