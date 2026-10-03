# Aki — asset census (1.2.0 bundle; 1.1.0 resource fork for comparison)

`$A` = `/Users/andiyar/Developer/Ambrosia/Resources/ambrosia-extracted/Action-Adventure/Aki - Mahjong Solitaire/Aki 1.2 UB/Aki.app/Contents`.
All numbers below are tool output from this session.

## 1. PNGs (1.2 `Resources/`) — 50 files
Command: `cd "$A/Resources"; for f in *.png; do sips -g pixelWidth -g pixelHeight "$f"; done`
(`ls *.png | wc -l` → 50). "Loaded as" = the GWorld slot in `_InitializeGWorlds` @ 0x27a36 or the
code path that opens it by name; "layout" = how code indexes it (rules/method-map).
| file | w×h | bytes | loaded as / used by | internal layout read from code |
|---|---|---|---|---|
| background1..17.png (17) | 800×600 each | 121762–337566 | g+0x14 via `background%d` | full screens; 1–12 levels, 13–17 custom decorations (levels.md §3) |
| preview1..17.png (17) | 237×181 each | 21416–37663 | LevelDescription window `preview%d` | one image each |
| previews.png | 237×2172 | 339653 | g+0x18 (map hover) | 12 strips × 181 px (`sVar7*0xb5`) |
| map.png | 800×600 | 340371 | g+0x20 | map screen |
| misc.png | 467×468 | 33412 | g+0x00 | time-stone rows (y 39..78 stones, 78..117 mask, 117..273 partial caps), digits (x 0x9b..0xcc, 30-px rows), difficulty words (x 296..379, y 241 + 23·d: Hard/Medium/Easy/Practice), button sprites (x 205.., y 411..436), flash frames (x 233..258, 25-px rows) |
| tiles.png | 53×1104 | 5830 | g+0x04 | 16 rows × 69: 0 blank, 69 selected, 138 hint, 207 greyed (no pairs), 276..1035 eleven fade masks, 1035 tile mask; editor ghost row at y 0x1e3 (483) |
| tile_pictures.png | 39×2100 | 59326 | g+0x0c | 42 faces × 50 px, row = (face − 200)·50 |
| plate.png | 2358×68 | 45946 | g+0x1c | bottom status bar pieces (bar background at x 0x86.., buttons at x 7 + 38·k) |
| pause.png | 416×480 | 61106 | g+0x10 | 208×480 panel + 208×480 mask, drawn at (296,26) when paused |
| nopairs.png | 416×480 | 60401 | g+0x24 | same scheme, "no more pairs" panel |
| notavail.png | 240×150 | 13925 | g+0x28 | 3 strips × 50: demo-unavailable / mask / locked |
| arrow.png | 132×144 | 5304 | g+0x34 | map-bar arrows (difficulty ±) 33×28 cells |
| layer_buttons.png | 224×260 | 25850 | g+0x40 | editor layer buttons / nudge arrows [LOW: cell grid not read] |
| proverbs.png | 392×1727 | 211478 | `_RandomProverbScreen` | 11 strips × 157 px |
| paper.png | 420×338 | 42522 | dialogs' background (`PaperBackgroundView`, `_CreateNewDialog`) | tiled |
| guide.png | 440×503 | 62513 | `SplashScreen("guide")` | first-run guide |
| welcome.png | 523×338 | 52060 | `SplashScreen("welcome")` | first launch |
| buyaki.png | 800×600 | 235505 | `AkiQuitView` | unregistered quit nag — out of scope |

## 2. Audio (1.2) — `afinfo` this session
| file | format | duration s | id in `_InitializeSound` / music slot |
|---|---|---|---|
| chime.aiff | ima4 mono 44.1k | 1.39 | 0x4b pause |
| Reshuffle.aiff | ima4 stereo | 3.33 | 0x14 no more pairs |
| LevelComplete.aiff | ima4 stereo | 2.46 | 0x1e win |
| GameOver.aiff | ima4 stereo | 2.85 | 0x28 loss |
| LevelStart.aiff | ima4 stereo | 3.70 | 0x32 level slide-in |
| Preview.aiff | ima4 mono | 0.30 | 0x3c map hover |
| TileMatch.aiff | ima4 mono | 0.16 | 0x46 match |
| cancel.aiff | ima4 mono | 0.25 | 0x50 mismatch / editor reject |
| unclick.aiff | ima4 stereo | 0.04 | 0x5a deselect |
| tick.mp3 | mp3 mono | 46.05 | 100 low-time loop |
| tilehit.mp3 | mp3 stereo | 0.05 | 10 select / editor place |
| tick.aiff | ima4 mono | 0.29 | **not referenced** (`strings` finds only `tick.mp3` in `_InitializeSound`) |
| Aki Theme 3.mp3 | mp3 stereo | 34.66 | music track 0 (map, loops) |
| Aki Theme 1.mp3 | mp3 stereo | 163.24 | music track 1 (game) |
| Aki Theme 2.mp3 | mp3 stereo | 174.92 | music track 2 (game, alternates with 1) |
Played through QuickTime Movies (`NewMovieFromFile`, `StartMovie`), not NSSound. 1.1 ships the same
files except `tilehit.aiff` instead of `tilehit.mp3` (1.1 `Resources/` listing).

## 3. Strings, nibs, docs
- `English.lproj/Localizable.strings` (UTF-16 BE): **56** entries (`iconv … | grep -c '" = "'`):
  menu titles (Open/Exit Level Editor, Give Up, New Game, Replay Last Level, Replay %@), save-alert
  texts, Practice-mode alert, `level1..17_title`, `level1..17_description`, `level13..17_custom_title`.
  `Japanese.lproj/Localizable.strings` (UTF-8 with BOM): 56 entries.
- Nibs: `MainMenu.nib` (menu tags — method-map §4), `Preferences.nib` (5 checkboxes),
  `LevelDescription.nib` (image 237×181, title, description, checkbox, Cancel/Continue),
  `Aki.nib` (Carbon `objects.xib`: windows Warning, Unavailable, Stats, Stacked, Incomplete,
  Transfer, TryAgain, PleaseReg, Permissions, LoadLevel, FileNotFound; texts e.g. "The remaining
  tiles are stacked and are impossible to remove…", "Are you sure you want to end this game?",
  "This level has less than the required 144 tiles, and cannot be played. Instead, it has been
  loaded into the Level Editor…"). One orphan dialog text: "Changing the difficulty setting will end
  the current game…" (no `_CreateNewDialog` call reaches it — dialog 0x1e is never requested in 1.2;
  `grep '_CreateNewDialog(0x1e' ` → none).
- `Aki Handbook.pdf` (rules cross-check, read with `pdftotext`), `Release Notes.rtf`,
  `AboutCredits1.rtf`, icons `aki.icns`, `Aki_Doc_ICON.icns`.
- Frameworks (not game data): ASWAboutBox, ASWAppKit, ASWFoundation, ASWRegistration,
  AmbrosiaTools, Sparkle.
- No level data files of any kind in the bundle (levels 1–12 are code; levels.md §3).

## 4. 1.1.0 resource fork — PICT census
File: `/Users/andiyar/Developer/Ambrosia/Aki/Aki - Mahjong Solitaire/Aki - Mahjong Solitaire.app/Contents/Resources/Aki - Mahjong Solitaire.rsrc`
(7925076 bytes; byte size identical to the copy under `Resources/ambrosia-extracted/…/Aki 1.1.0/`).
Parser: `docs/aki/tools/rsrc_census.py` (written this session; header = 4 BE u32, map type list at
map+24, 8-byte type entries, 12-byte refs, data length-prefixed — see its docstring).
```
$ python3 docs/aki/tools/rsrc_census.py ".../Aki - Mahjong Solitaire.rsrc" PICT
header dataOff=256 mapOff=7922960 dataLen=7922704 mapLen=2116
'8BIM': 33 resources, 18419 bytes
'ANPA': 1 resources, 43 bytes
'CHNK': 1 resources, 19581 bytes
'PICT': 82 resources, 7864662 bytes
'STR ': 4 resources, 43 bytes
'TEXT': 1 resources, 31 bytes
'icns': 1 resources, 19415 bytes
'pnot': 1 resources, 14 bytes
```
**82 PICT** resources. Ids: 128–136 (9: GWorld sources 0x80–0x87 = misc, tiles, proverbs,
tile_pictures, previews, arrow, pause, plate per `InitializeGWorlds`; 136 = 0x88 layer buttons),
140–151 (12 level backgrounds), 155, 156, 160, 164 (0xa4 map), 168 (0xa8 nopairs), 179, 199 (guide
splash, `SplashScreen(199)`; other splash ids 0x9b/0x9c/0xa0/0x82 appear in 1.1 code), 200–204
(5 custom-level backgrounds), 300–311 (12 level-description previews), 313, 314 (= 0x13a notavail
GWorld), 315, 400–404 (5 custom-level description previews), and 30 small PICTs with ids
1069..32369 (1154–13956 bytes; not referenced by any constant or nib seen — probably leftovers
alongside the 33 Photoshop `8BIM` resources) [LOW for their purpose]. Nib references, from
`grep -A1 contentResID` on 1.1 `Aki.nib/objects.xib` (value: count): 300..311, 313, 400..404 once
each, **315 × 53** (the dialogs' paper background), 132 once. 1.2 replaced all of them with the
PNGs in §1 (paper.png ↔ 315, preview1..17.png ↔ 300–311/400–404) [MED for the ↔ pairs: by role,
not by pixel comparison].
