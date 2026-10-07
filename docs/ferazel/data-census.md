# Ferazel's Wand — data census (Phase 0)

> Generated 2026-10-07 by `ferazel-census` (`Ferazel/Core`, plan `docs/plans/2026-10-06-ferazel-phase1.md` Task C6)
> through HectorKit main `4ca2e18` (tag `v0.3.0` + 8: K1 PICT pixels as stored, review fixes), built on Classics
> `b4616d0` (the parent of the C6 commit). Everything below the rule is the tool's stdout, verbatim
> (`CensusTests.testStdoutEqualsCommittedCensus` keeps it so). Re-run from `Ferazel/Core`:
>
>     swift build -c release --product ferazel-census > /dev/null
>     "$(swift build -c release --show-bin-path)/ferazel-census" "$PWD/../../Resources/Ferazel" > census.md
>
> Add `--render <out dir>` to also write `level1-start.png` (Phase 0's level-1 start window: BG then FG tile faces by
> cell at scroll (0, 10), through clut 202 — no pattern cells, blend, overlay, parallax, lighting or sprites; R1–R6
> draw the real frame), `pict-1020.png` (walk sheet under clut 200) and `pict-207.png` (PxBack under clut 201) —
> ImageIO, census-only. The data is the committed copy `Resources/Ferazel` (DECISIONS D26). "Decoded" means decodes
> to the census — not "looks/sounds right"; every Color2Index choice is [LOW] (D26).

## Spec-vs-data deltas

1. **sprites-backgrounds §1–§2 / design §6 "sprite source pixels copy through exactly":** the sheets carry their own
   colour tables and 326 are 32-bit, so every face index comes out of `Color2Index` at load time (the same LOW).
2. **sprites-backgrounds §1:** all 326 DirectBits PICTs (Sprites 290, Backgrounds 20, Titles 16) carry transfer mode
   64 (ditherCopy) — a second LOW; modelled `.errorDiffusion` by default (D26).
3. **sprites-backgrounds §1 "every … is a version-2 PICT":** five are version-1 1-bit BitMaps (Sprites 183,
   Backgrounds 319, 329, 339, 350); indexed depths are 8-bit 427, 4-bit 11, 2-bit 1.
4. **lighting-tables §1.4 "23 '+ base' CLUTs":** there are 24 — clut 322 'Upper Fire Caverns flame + base o' also
   has entries 0x00..0x9f equal to clut 200 (no level uses it).
5. **rendering-omnipx-titles §3.3, mode 0 "other 19":** 20 levels have OmniPx mode 0 (24 − levels 5, 15, 25, 70).
   (Not a census line; plan Research note 7.)
6. **world-data §3.3 level-1 "FG 7,274 non-zero cells":** 4 of them carry only high bits, so 7,270 cells hold an FG
   tile; 225 shipped cells already carry a crunch-dir nibble. (Not a census line; plan probe p02/p17.)
7. **Plan C6 "1,178,143 of 3,387,696":** Ben 2026-10-07, follow the binary — water 1's 32-bit `mullw` overflow moves
   the 16-CLUT total to 1,178,146 (CLUT 202 unchanged at 75,461); D26 "As built (C4)".
8. **Plan C6 "FG 200 62/239 colours 7,193 px":** FG converts under the level CLUT 201, not level+base 202
   (`.LoadLevelTilesets` l. 1576–1577), so FG reads 44/239 colours, 5,400 px; D26 "As built (C5)".

---

# Ferazel's Wand 1.0.3 — data census

## 1. Files

files 34 · resource files 6 · music 28 of 30 (21, 27 absent) · bytes 85,281,911

| file | bytes | result |
|---|---:|---|
| Ferazel's Wand.rsrc | 264,712 | ok |
| Ferazel's Wand World Data.rsrc | 5,511,430 | ok |
| Ferazel's Wand Backgrounds.rsrc | 15,821,213 | ok |
| Ferazel's Wand Sprites.rsrc | 10,028,422 | ok |
| Ferazel's Wand Sounds.rsrc | 2,448,841 | ok |
| Ferazel's Wand Titles.rsrc | 4,005,325 | ok |
| Ferazel's Wand Music/01 | 1,935,726 | ok |
| Ferazel's Wand Music/02 | 1,831,606 | ok |
| Ferazel's Wand Music/03 | 1,650,862 | ok |
| Ferazel's Wand Music/04 | 1,401,574 | ok |
| Ferazel's Wand Music/05 | 2,059,814 | ok |
| Ferazel's Wand Music/06 | 1,685,474 | ok |
| Ferazel's Wand Music/07 | 1,684,318 | ok |
| Ferazel's Wand Music/08 | 1,544,918 | ok |
| Ferazel's Wand Music/09 | 3,299,070 | ok |
| Ferazel's Wand Music/10 | 1,607,206 | ok |
| Ferazel's Wand Music/11 | 1,503,166 | ok |
| Ferazel's Wand Music/12 | 1,431,358 | ok |
| Ferazel's Wand Music/13 | 2,089,326 | ok |
| Ferazel's Wand Music/14 | 1,499,902 | ok |
| Ferazel's Wand Music/15 | 1,206,142 | ok |
| Ferazel's Wand Music/16 | 1,556,886 | ok |
| Ferazel's Wand Music/17 | 1,469,438 | ok |
| Ferazel's Wand Music/18 | 2,152,702 | ok |
| Ferazel's Wand Music/19 | 1,535,410 | ok |
| Ferazel's Wand Music/20 | 1,687,242 | ok |
| Ferazel's Wand Music/22 | 1,800,882 | ok |
| Ferazel's Wand Music/23 | 1,526,694 | ok |
| Ferazel's Wand Music/24 | 2,202,342 | ok |
| Ferazel's Wand Music/25 | 1,306,238 | ok |
| Ferazel's Wand Music/26 | 1,575,654 | ok |
| Ferazel's Wand Music/28 | 1,426,054 | ok |
| Ferazel's Wand Music/29 | 1,310,726 | ok |
| Ferazel's Wand Music/30 | 1,221,238 | ok |

## 2. Resources per file

resources app 164/28 · World Data 60/7 · Backgrounds 194/7 · Sprites 587/3 · Sounds 175/3 · Titles 86/4

| file | type | count | ids |
|---|---|---:|---|
| app | ALRT | 2 | 500..501 |
| app | BNDL | 1 | 128..128 |
| app | CNTL | 7 | 128..605 |
| app | DITL | 30 | -6043..16903 |
| app | DLOG | 20 | 150..6900 |
| app | FREF | 4 | 128..131 |
| app | ICN# | 5 | -16455..131 |
| app | MBAR | 1 | 128..128 |
| app | MENU | 9 | 128..605 |
| app | Msct | 1 | 0..0 |
| app | PICT | 5 | 145..7000 |
| app | SIZE | 1 | -1..-1 |
| app | STR# | 2 | 300..400 |
| app | Tune | 1 | 6900..6900 |
| app | WIND | 1 | 128..128 |
| app | cfrg | 1 | 0..0 |
| app | clut | 6 | 198..4000 |
| app | dctb | 14 | 150..6900 |
| app | icl4 | 5 | -16455..131 |
| app | icl8 | 5 | -16455..131 |
| app | ics# | 12 | -16455..206 |
| app | ics4 | 12 | -16455..206 |
| app | ics8 | 12 | -16455..206 |
| app | isap | 1 | 128..128 |
| app | setl | 1 | 128..128 |
| app | tset | 2 | 128..256 |
| app | vers | 2 | 1..2 |
| app | wctb | 1 | 128..128 |
| World Data | Mcnv | 29 | 200..401 |
| World Data | Mlvl | 24 | 1..70 |
| World Data | Mmap | 1 | 200..200 |
| World Data | Mwld | 1 | 0..0 |
| World Data | PICT | 1 | 7000..7000 |
| World Data | STR# | 2 | 500..1000 |
| World Data | vers | 2 | 1..2 |
| Backgrounds | PICT | 113 | 200..24069 |
| Backgrounds | TEXT | 1 | 128..128 |
| Backgrounds | VWCI | 1 | 128..128 |
| Backgrounds | cicn | 19 | 200..10137 |
| Backgrounds | clut | 57 | 198..4000 |
| Backgrounds | icns | 1 | -16455..-16455 |
| Backgrounds | vers | 2 | 1..2 |
| Sprites | PICT | 584 | 160..14850 |
| Sprites | icns | 1 | -16455..-16455 |
| Sprites | vers | 2 | 1..2 |
| Sounds | icns | 1 | -16455..-16455 |
| Sounds | snd  | 172 | 128..8030 |
| Sounds | vers | 2 | 1..2 |
| Titles | PICT | 67 | 128..4985 |
| Titles | clut | 16 | 128..729 |
| Titles | icns | 1 | -16455..-16455 |
| Titles | vers | 2 | 1..2 |

## 3. Items (one line each)

PICT 770 · v2 765 (indexed 8-bit 427 · 4-bit 11 · 2-bit 1 · direct 32-bit 326 mode 64) · v1 1-bit 5 · failures 0
clut 79 · app 6 · Backgrounds 57 · Titles 16 · 256 entries each · duplicate ids identical 6 · + base 24 (0x00..0x9f = clut 200)
snd 172 · format 1 · 22050 Hz 138 · 11025 Hz 33 · 22254.545 Hz 1 · samples 2,432,217
music 28 · AIFC ima4 stereo 22050 Hz · packets 694,051 · frames 44,419,264
Mlvl 24 · active records 5,641 · placed types 243 · flag-0 typed 48 · flag 99 1 · unmapped types 0
classes Bonus 2895 · Background 1274 · Box 759 · Platform 169 · Walker 158 · Bat 89 · Gremlin 50 · Rope 49 · Frog 41 · Crawler 31 · Blob 29 · Button 24 · Salamander 22 · Dillo 20 · Roach 16 · Floater 7 · Crab 3 · Chief 1 · Demon 1 · Warrior 1 · Wizard 1 · Xichra 1
world Mwld Teraknorn 0x152be0ed · Mmap nodes 24 · Mcnv 29 (lines 580, text 198, portrait 183) · STR# 1000 99 · STR# 500 19

| type | file | id | name | decoded | result |
|---|---|---:|---|---|---|
| PICT | app | 145 | — | 32×32 · v2 indexed 8-bit | ok |
| PICT | app | 146 | — | 180×16 · v2 indexed 8-bit | ok |
| PICT | app | 150 | — | 64×64 · v2 indexed 8-bit | ok |
| PICT | app | 151 | — | 64×64 · v2 indexed 8-bit | ok |
| PICT | app | 7000 | — | 608×384 · v2 indexed 8-bit | ok |
| PICT | World Data | 7000 | — | 608×384 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 200 | — | 256×384 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 201 | — | 256×384 · v2 direct 32-bit mode 64 | ok |
| PICT | Backgrounds | 203 | — | 256×384 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 206 | — | 256×256 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 207 | — | 768×768 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 208 | — | 768×256 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 210 | — | 256×384 · v2 direct 32-bit mode 64 | ok |
| PICT | Backgrounds | 211 | — | 256×384 · v2 direct 32-bit mode 64 | ok |
| PICT | Backgrounds | 213 | — | 256×384 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 214 | — | 256×384 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 216 | — | 256×256 · v2 direct 32-bit mode 64 | ok |
| PICT | Backgrounds | 217 | — | 768×768 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 220 | — | 256×384 · v2 direct 32-bit mode 64 | ok |
| PICT | Backgrounds | 222 | — | 256×256 · v2 direct 32-bit mode 64 | ok |
| PICT | Backgrounds | 237 | — | 768×768 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 240 | — | 256×384 · v2 direct 32-bit mode 64 | ok |
| PICT | Backgrounds | 243 | — | 256×384 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 244 | — | 256×384 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 246 | — | 256×256 · v2 indexed 4-bit | ok |
| PICT | Backgrounds | 247 | EC2 back | 768×768 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 250 | — | 256×384 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 251 | — | 256×384 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 253 | — | 256×384 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 256 | — | 256×256 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 257 | — | 768×708 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 258 | — | 768×256 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 259 | — | 768×256 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 260 | — | 256×384 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 263 | — | 256×384 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 264 | — | 256×384 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 265 | — | 768×30 · v2 direct 32-bit mode 64 | ok |
| PICT | Backgrounds | 266 | — | 256×256 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 267 | — | 768×768 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 268 | — | 768×256 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 269 | — | 768×256 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 270 | — | 256×384 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 273 | — | 256×384 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 275 | — | 768×44 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 276 | — | 256×256 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 277 | — | 768×768 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 278 | — | 768×256 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 279 | — | 768×256 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 280 | — | 256×384 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 283 | — | 256×384 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 286 | — | 256×256 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 287 | — | 768×768 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 288 | — | 768×256 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 289 | — | 768×256 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 290 | — | 256×384 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 291 | — | 256×384 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 293 | — | 256×384 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 296 | — | 256×256 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 297 | — | 768×768 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 298 | — | 768×256 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 299 | — | 768×256 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 305 | — | 768×25 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 307 | — | 768×768 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 310 | — | 256×384 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 313 | — | 256×384 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 314 | — | 256×384 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 315 | — | 768×33 · v2 direct 32-bit mode 64 | ok |
| PICT | Backgrounds | 316 | — | 256×256 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 317 | — | 768×768 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 318 | — | 768×256 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 319 | — | 768×256 · v1 1-bit | ok |
| PICT | Backgrounds | 325 | — | 768×57 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 326 | — | 256×256 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 327 | — | 768×768 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 328 | — | 768×256 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 329 | — | 768×256 · v1 1-bit | ok |
| PICT | Backgrounds | 330 | — | 256×384 · v2 direct 32-bit mode 64 | ok |
| PICT | Backgrounds | 336 | — | 256×256 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 337 | — | 768×768 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 338 | — | 768×256 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 339 | — | 768×256 · v1 1-bit | ok |
| PICT | Backgrounds | 340 | — | 256×384 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 345 | — | 768×46 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 346 | — | 256×256 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 347 | — | 768×768 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 348 | — | 768×256 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 349 | — | 768×256 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 350 | — | 768×768 · v1 1-bit | ok |
| PICT | Backgrounds | 357 | — | 768×768 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 360 | — | 256×384 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 366 | — | 256×256 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 367 | — | 768×768 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 370 | — | 256×384 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 376 | — | 256×256 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 377 | — | 768×768 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 378 | — | 768×256 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 379 | — | 768×256 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 380 | — | 256×384 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 385 | — | 768×60 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 387 | — | 768×768 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 391 | — | 256×384 · v2 direct 32-bit mode 64 | ok |
| PICT | Backgrounds | 400 | — | 256×384 · v2 direct 32-bit mode 64 | ok |
| PICT | Backgrounds | 456 | — | 256×256 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 458 | — | 768×256 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 459 | — | 768×256 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 500 | — | 256×256 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 501 | — | 256×256 · v2 direct 32-bit mode 64 | ok |
| PICT | Backgrounds | 502 | — | 256×256 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 504 | — | 256×256 · v2 direct 32-bit mode 64 | ok |
| PICT | Backgrounds | 505 | — | 256×256 · v2 direct 32-bit mode 64 | ok |
| PICT | Backgrounds | 506 | — | 256×256 · v2 direct 32-bit mode 64 | ok |
| PICT | Backgrounds | 507 | — | 256×256 · v2 direct 32-bit mode 64 | ok |
| PICT | Backgrounds | 509 | — | 256×256 · v2 direct 32-bit mode 64 | ok |
| PICT | Backgrounds | 510 | — | 256×256 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 511 | — | 256×256 · v2 direct 32-bit mode 64 | ok |
| PICT | Backgrounds | 600 | — | 768×768 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 601 | — | 768×768 · v2 indexed 8-bit | ok |
| PICT | Backgrounds | 1263 | — | 256×384 · v2 direct 32-bit mode 64 | ok |
| PICT | Backgrounds | 24069 | — | 256×384 · v2 indexed 8-bit | ok |
| PICT | Sprites | 160 | — | 256×256 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 170 | — | 32×16 · v2 indexed 8-bit | ok |
| PICT | Sprites | 180 | — | 256×384 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 181 | — | 256×384 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 182 | — | 256×384 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 183 | — | 256×384 · v1 1-bit | ok |
| PICT | Sprites | 185 | — | 256×384 · v2 indexed 8-bit | ok |
| PICT | Sprites | 198 | — | 608×96 · v2 indexed 8-bit | ok |
| PICT | Sprites | 206 | — | 256×256 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 207 | — | 512×768 · v2 indexed 8-bit | ok |
| PICT | Sprites | 265 | — | 768×30 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 328 | fireball right | 24×90 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 428 | — | 400×240 · v2 indexed 8-bit | ok |
| PICT | Sprites | 528 | — | 700×120 · v2 indexed 8-bit | ok |
| PICT | Sprites | 600 | — | 20×20 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 601 | — | 12×12 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 649 | — | 12×12 · v2 indexed 8-bit | ok |
| PICT | Sprites | 650 | classic rope bend frames | 300×40 · v2 indexed 8-bit | ok |
| PICT | Sprites | 651 | — | 20×20 · v2 indexed 8-bit | ok |
| PICT | Sprites | 652 | — | 300×40 · v2 indexed 8-bit | ok |
| PICT | Sprites | 653 | — | 20×20 · v2 indexed 8-bit | ok |
| PICT | Sprites | 658 | — | 360×48 · v2 indexed 4-bit | ok |
| PICT | Sprites | 700 | — | 1215×47 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 701 | — | 621×46 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 702 | — | 1215×47 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 703 | — | 621×46 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 711 | frozen water platform | 40×72 · v2 indexed 8-bit | ok |
| PICT | Sprites | 712 | trunk bottom | 36×36 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 713 | trunk segment | 36×36 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 750 | — | 32×24 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 756 | — | 32×24 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 768 | — | 32×24 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 771 | — | 32×24 · v2 indexed 8-bit | ok |
| PICT | Sprites | 801 | — | 192×192 · v2 indexed 8-bit | ok |
| PICT | Sprites | 802 | — | 192×192 · v2 indexed 8-bit | ok |
| PICT | Sprites | 803 | — | 192×192 · v2 indexed 8-bit | ok |
| PICT | Sprites | 806 | — | 192×192 · v2 indexed 8-bit | ok |
| PICT | Sprites | 807 | — | 84×84 · v2 indexed 8-bit | ok |
| PICT | Sprites | 810 | — | 72×72 · v2 indexed 8-bit | ok |
| PICT | Sprites | 811 | — | 72×72 · v2 indexed 8-bit | ok |
| PICT | Sprites | 812 | — | 72×72 · v2 indexed 8-bit | ok |
| PICT | Sprites | 813 | — | 72×72 · v2 indexed 8-bit | ok |
| PICT | Sprites | 820 | — | 128×128 · v2 indexed 8-bit | ok |
| PICT | Sprites | 821 | — | 128×128 · v2 indexed 8-bit | ok |
| PICT | Sprites | 822 | — | 52×52 · v2 indexed 8-bit | ok |
| PICT | Sprites | 830 | — | 64×16 · v2 indexed 8-bit | ok |
| PICT | Sprites | 950 | — | 384×384 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 951 | — | 128×128 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 952 | — | 128×128 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1001 | — | 64×64 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1002 | — | 32×32 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1003 | — | 400×120 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1004 | — | 100×120 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1008 | — | 64×64 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1009 | — | 64×64 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1010 | — | 1000×120 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1011 | — | 400×120 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1012 | — | 600×120 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1013 | — | 400×120 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1014 | — | 600×120 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1015 | — | 400×240 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1016 | — | 700×120 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1017 | — | 400×240 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1020 | — | 400×480 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1021 | — | 500×120 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1022 | — | 1500×120 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1023 | — | 1200×120 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1024 | — | 400×360 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1025 | — | 800×120 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1026 | — | 400×152 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1027 | — | 600×120 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1028 | — | 1000×120 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1029 | — | 600×120 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1030 | — | 300×120 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1031 | — | 600×120 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1032 | — | 600×120 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1033 | — | 600×120 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1034 | — | 500×120 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1035 | — | 500×120 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1036 | — | 600×120 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1037 | — | 400×120 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1038 | — | 400×120 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1039 | — | 900×120 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1040 | bubble | 32×8 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1050 | — | 480×320 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1051 | — | 640×160 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1052 | — | 480×320 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1053 | — | 640×160 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1054 | — | 400×76 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1055 | Bonus crystal | 240×20 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1057 | — | 320×32 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1058 | — | 320×32 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1059 | — | 320×32 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1060 | teleporter | 32×32 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1061 | Teleporter 2 | 32×32 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1062 | Teleporter 3 | 32×32 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1065 | save point | 252×100 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1070 | — | 32×32 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1071 | Boulder 2 | 32×32 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1072 | Boulder 3 | 32×32 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1080 | — | 113×144 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1090 | — | 750×150 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1100 | fireball right | 24×90 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1101 | fireball left | 24×90 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1102 | — | 24×90 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1103 | — | 24×90 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1104 | — | 24×90 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1105 | — | 24×90 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1106 | — | 32×108 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1107 | — | 32×108 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1108 | — | 24×90 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1109 | — | 24×90 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1110 | — | 24×90 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1111 | — | 24×90 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1112 | boomerang right | 24×90 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1113 | — | 192×32 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1114 | — | 320×80 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1115 | — | 168×28 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1116 | — | 96×12 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1117 | — | 360×24 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1118 | — | 20×20 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1130 | — | 288×48 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1131 | — | 384×64 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1132 | — | 384×64 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1133 | — | 384×64 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1135 | — | 192×32 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1139 | — | 384×64 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1150 | — | 240×60 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1151 | — | 240×60 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1152 | — | 240×60 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1154 | — | 240×60 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1200 | explosion | 624×48 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1201 | dust cloud | 336×8 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1202 | — | 8×20 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1203 | — | 5×16 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1204 | — | 4×12 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1205 | — | 3944×242 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1206 | — | 2176×116 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1207 | big explosion | 1248×96 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1208 | — | 1536×72 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1209 | — | 1536×72 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1210 | crumble overlay | 96×32 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1211 | — | 72×1536 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1212 | — | 1536×72 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1215 | — | 64×17 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1220 | — | 24×264 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1250 | — | 252×108 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1251 | — | 216×36 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1252 | — | 38×36 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1290 | $Big magic crystal | 20×33 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1291 | $Big health crystal | 20×33 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1292 | $Moneybag, small | 32×32 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1293 | $Moneybag, big | 32×32 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1300 | magic bonus | 108×20 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1301 | — | 108×20 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1302 | — | 90×10 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1303 | — | 34×18 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1304 | — | 34×19 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1307 | — | 60×28 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1308 | — | 132×31 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1309 | gold coins | 90×10 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1310 | Platinum coins | 90×10 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1311 | — | 29×8 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1320 | — | 84×12 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1321 | — | 84×12 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1322 | — | 256×21 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1330 | Sphere, Shadow Double | 32×32 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1331 | Sphere, Solid Water | 32×32 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1332 | Sphere, Solid Acid | 32×32 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1333 | Sphere, Solid Lava | 32×32 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1334 | Sphere, High Jump | 32×32 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1335 | Sphere, Invincibility | 32×32 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1336 | Sphere, Featherfall | 32×32 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1337 | — | 32×32 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1338 | $Sphere, Pentashield | 32×32 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1339 | $Sphere, Death | 32×32 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1340 | — | 264×42 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1341 | — | 264×42 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1350 | Air Bubble | 32×32 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1400 | — | 800×41 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1410 | Catapult | 216×1400 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1420 | — | 50×16 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1421 | — | 50×17 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1422 | — | 24×45 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1430 | — | 16×16 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1431 | — | 16×16 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1432 | — | 16×16 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1433 | — | 160×96 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1434 | — | 24×24 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1435 | — | 24×1080 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1436 | — | 24×24 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1440 | — | 96×48 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1441 | — | 288×32 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1442 | — | 120×32 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1450 | — | 128×32 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1460 | Bridge - Wooden - Full | 264×48 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1461 | Bridge - Wooden - Left half | 164×48 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1463 | Bridge - Stone | 264×64 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1464 | Bridge - Stone - Left half | 152×64 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1466 | Bridge - Rope | 268×96 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1467 | — | 268×96 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1470 | — | 216×56 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1480 | — | 128×100 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1481 | — | 128×100 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1482 | — | 128×100 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1483 | — | 128×100 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1484 | — | 128×100 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1485 | — | 100×100 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1486 | — | 100×100 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1487 | — | 100×100 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1488 | — | 100×100 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1490 | !Enemy pipe facing up | 96×36 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1491 | !Enemy pipe facing down | 96×36 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1492 | !Enemy pipe facing right | 36×96 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1493 | !Enemy pipe facing left | 36×96 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1600 | glow | 192×48 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1700 | — | 100×80 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1701 | — | 400×160 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1702 | — | 600×80 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1703 | — | 96×48 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1704 | — | 94×640 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1705 | — | 204×267 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1706 | — | 204×178 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1707 | — | 204×801 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1710 | — | 384×44 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1711 | — | 384×44 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1712 | — | 64×44 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1713 | — | 384×44 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1720 | — | 600×54 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1721 | — | 600×54 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1730 | — | 1024×44 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1740 | bat | 616×52 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1750 | — | 216×110 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1751 | — | 216×880 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1752 | — | 216×660 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1753 | — | 216×330 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1754 | — | 216×660 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1760 | — | 756×92 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1761 | goblin boulders | 256×32 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1762 | bomb boulder | 256×32 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1766 | — | 128×16 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1770 | — | 1320×120 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1771 | — | 1320×120 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1772 | — | 128×32 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1780 | Wraith | 600×80 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1800 | — | 960×100 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1810 | Salamander | 720×100 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1820 | — | 1440×160 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1821 | — | 1440×160 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1822 | — | 1080×160 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1823 | — | 384×96 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1830 | — | 192×140 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1831 | — | 1536×140 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1832 | — | 1536×140 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1840 | — | 288×128 · v2 indexed 4-bit | ok |
| PICT | Sprites | 1842 | !Retracting spikes floor | 128×24 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1843 | !Retracting spikes ceiling | 128×24 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1850 | — | 768×80 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1851 | — | 768×80 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1855 | !Water Urchin | 41×24 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1856 | !Water Urchin 2 | 34×28 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1860 | — | 432×44 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1869 | — | 192×22 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1870 | — | 600×80 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1871 | — | 500×80 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1872 | — | 500×80 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1873 | — | 200×80 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1875 | — | 24×20 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1876 | 18x18 | 144×18 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1880 | — | 416×40 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1881 | — | 364×40 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1890 | — | 600×100 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1892 | — | 528×88 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1895 | — | 40×40 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1900 | — | 552×92 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1902 | — | 552×92 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1903 | — | 552×92 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1905 | — | 60×8 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1906 | — | 60×8 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1907 | — | 8×60 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1908 | — | 8×60 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 1910 | !Goblin Chief | 256×264 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1911 | — | 1024×264 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1912 | — | 1024×264 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1913 | — | 1024×264 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1914 | — | 1024×264 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1915 | — | 448×448 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1920 | — | 432×232 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1921 | — | 432×232 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1922 | — | 432×116 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1923 | — | 576×116 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1924 | — | 192×96 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1928 | — | 288×96 · v2 indexed 4-bit | ok |
| PICT | Sprites | 1929 | — | 288×96 · v2 indexed 4-bit | ok |
| PICT | Sprites | 1970 | — | 480×400 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1971 | — | 480×400 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1972 | — | 480×200 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1973 | — | 480×400 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1974 | — | 480×200 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1975 | — | 480×400 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1976 | — | 480×400 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1977 | — | 480×400 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1980 | — | 480×400 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1981 | — | 480×400 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1982 | — | 480×200 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1983 | — | 480×400 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1984 | — | 480×200 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1985 | — | 480×400 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1986 | — | 480×400 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1987 | — | 480×400 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1990 | — | 2400×200 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1991 | — | 1440×200 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1992 | — | 2640×200 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1995 | — | 2400×200 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1996 | — | 1440×200 · v2 indexed 8-bit | ok |
| PICT | Sprites | 1997 | — | 2640×200 · v2 indexed 8-bit | ok |
| PICT | Sprites | 2000 | — | 32×32 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2700 | Leafy Small Plant 1 | 61×60 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2701 | Leafy Small Plant 2 | 74×43 · v2 indexed 8-bit | ok |
| PICT | Sprites | 2702 | Leafy Small Plant 3 | 73×43 · v2 indexed 8-bit | ok |
| PICT | Sprites | 2703 | Wavy Small Plant 1 | 40×66 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2704 | Wavy Small Plant 2 | 60×52 · v2 indexed 8-bit | ok |
| PICT | Sprites | 2705 | Wavy-Leafy Combo Small Plant | 77×58 · v2 indexed 8-bit | ok |
| PICT | Sprites | 2706 | Tentacly Small Plant 1 | 37×63 · v2 indexed 8-bit | ok |
| PICT | Sprites | 2707 | Tentacly Small Plant 2 | 61×51 · v2 indexed 8-bit | ok |
| PICT | Sprites | 2708 | Bluish Undersea Plant | 60×63 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2709 | Purply Undersea Plant | 56×63 · v2 indexed 8-bit | ok |
| PICT | Sprites | 2710 | Mini Hanging Vine 1 | 36×36 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2711 | Mini Hanging Vines 2 | 42×60 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2712 | — | 28×57 · v2 indexed 8-bit | ok |
| PICT | Sprites | 2713 | Mossy Patch brownish | 62×59 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2714 | Mossy Patch greenish | 52×59 · v2 indexed 8-bit | ok |
| PICT | Sprites | 2715 | Mossy Patch orangish | 74×57 · v2 indexed 8-bit | ok |
| PICT | Sprites | 2716 | Mossy Patch reddish | 65×62 · v2 indexed 8-bit | ok |
| PICT | Sprites | 2717 | Mossy Patch beigeish | 71×68 · v2 indexed 8-bit | ok |
| PICT | Sprites | 2800 | !Rathole | 16×33 · v2 indexed 8-bit | ok |
| PICT | Sprites | 2801 | — | 168×14 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2808 | — | 88×160 · v2 indexed 8-bit | ok |
| PICT | Sprites | 2809 | *Ziridium Mine Stuff | 256×90 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2810 | *Wavy Grass | 249×96 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2811 | *Metal Blocks | 246×80 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2812 | *Red Ruins 1 | 157×96 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2813 | *Red Ruins 2 | 140×88 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2814 | *Grassy Rocks & Stumps | 256×92 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2815 | *Thorny Tangles Big | 256×96 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2816 | *Cattails | 151×93 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2817 | *Cattails 2 | 127×96 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2818 | *Icicles & Stuff | 256×96 · v2 indexed 8-bit | ok |
| PICT | Sprites | 2819 | *Spiked Habnabit Heads | 256×99 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2820 | *Skeleton1 | 81×26 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2821 | *Skeleton 2 | 82×24 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2822 | *Skeleton 3 | 68×21 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2823 | *Skeleton 4 | 59×46 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2824 | *Robed Body 1 | 91×28 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2825 | *Robed Body 2 | 95×21 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2826 | *Armored Body 1 | 60×79 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2827 | *Armored Body 2 | 74×46 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2828 | *Armor Rubbish 1 | 62×27 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2829 | *Armor Rubbish 2 | 66×18 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2830 | *Armor Rubbish 3 | 43×33 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2831 | *Armor Rubbish 3 | 62×26 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2832 | *Pedestal | 54×71 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2833 | *Grave 1 | 64×73 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2834 | *Grave 2 | 40×38 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2835 | *Grave 3 | 36×36 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2836 | *Grave 4 | 34×39 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2837 | *Straw Rug | 131×13 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2838 | *Purply Rug | 131×13 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2839 | *Skull Rug | 131×13 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2840 | *Manditraki Pillar | 63×174 · v2 indexed 8-bit | ok |
| PICT | Sprites | 2841 | *Gray Pedestal | 32×64 · v2 indexed 8-bit | ok |
| PICT | Sprites | 2842 | *Book pile | 47×47 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2843 | *Cobweb Chair | 80×64 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2844 | *Cobweb Chair 2 | 70×42 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2845 | *Cobweb Table | 81×43 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2846 | *Grassy lightboulder | 140×96 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2847 | *Grassy Lightboulder 2 | 145×70 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2848 | *Scraggly Vines | 145×96 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2849 | *Scraggly Vines 2 | 117×86 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2850 | — | 100×100 · v2 indexed 8-bit | ok |
| PICT | Sprites | 2851 | — | 100×100 · v2 indexed 8-bit | ok |
| PICT | Sprites | 2852 | — | 100×100 · v2 indexed 8-bit | ok |
| PICT | Sprites | 2853 | — | 100×100 · v2 indexed 8-bit | ok |
| PICT | Sprites | 2854 | — | 100×100 · v2 indexed 8-bit | ok |
| PICT | Sprites | 2855 | — | 100×100 · v2 indexed 8-bit | ok |
| PICT | Sprites | 2856 | — | 100×100 · v2 indexed 8-bit | ok |
| PICT | Sprites | 2857 | — | 100×100 · v2 indexed 8-bit | ok |
| PICT | Sprites | 2858 | — | 100×100 · v2 indexed 8-bit | ok |
| PICT | Sprites | 2859 | — | 100×100 · v2 indexed 8-bit | ok |
| PICT | Sprites | 2860 | — | 100×100 · v2 indexed 8-bit | ok |
| PICT | Sprites | 2861 | — | 100×100 · v2 indexed 8-bit | ok |
| PICT | Sprites | 2862 | — | 100×100 · v2 indexed 8-bit | ok |
| PICT | Sprites | 2863 | — | 100×100 · v2 indexed 8-bit | ok |
| PICT | Sprites | 2864 | — | 100×100 · v2 indexed 8-bit | ok |
| PICT | Sprites | 2865 | — | 100×100 · v2 indexed 8-bit | ok |
| PICT | Sprites | 2866 | — | 100×100 · v2 indexed 8-bit | ok |
| PICT | Sprites | 2867 | — | 100×100 · v2 indexed 8-bit | ok |
| PICT | Sprites | 2868 | — | 100×100 · v2 indexed 8-bit | ok |
| PICT | Sprites | 2869 | — | 100×100 · v2 indexed 8-bit | ok |
| PICT | Sprites | 2870 | — | 72×72 · v2 indexed 8-bit | ok |
| PICT | Sprites | 2871 | — | 72×72 · v2 indexed 8-bit | ok |
| PICT | Sprites | 2872 | — | 72×72 · v2 indexed 8-bit | ok |
| PICT | Sprites | 2873 | — | 71×72 · v2 indexed 8-bit | ok |
| PICT | Sprites | 2874 | — | 72×72 · v2 indexed 8-bit | ok |
| PICT | Sprites | 2875 | — | 72×72 · v2 indexed 8-bit | ok |
| PICT | Sprites | 2876 | — | 72×72 · v2 indexed 8-bit | ok |
| PICT | Sprites | 2877 | — | 72×72 · v2 indexed 8-bit | ok |
| PICT | Sprites | 2878 | — | 72×72 · v2 indexed 8-bit | ok |
| PICT | Sprites | 2879 | — | 72×72 · v2 indexed 8-bit | ok |
| PICT | Sprites | 2880 | — | 72×72 · v2 indexed 8-bit | ok |
| PICT | Sprites | 2881 | — | 72×72 · v2 indexed 8-bit | ok |
| PICT | Sprites | 2882 | — | 72×72 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2883 | — | 72×72 · v2 indexed 8-bit | ok |
| PICT | Sprites | 2884 | — | 72×72 · v2 indexed 8-bit | ok |
| PICT | Sprites | 2885 | — | 72×72 · v2 indexed 8-bit | ok |
| PICT | Sprites | 2890 | — | 174×73 · v2 indexed 8-bit | ok |
| PICT | Sprites | 2891 | *Cloud 2 | 197×71 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2892 | *Cloud 3 | 220×97 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2893 | *Cloud 4 | 193×117 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2899 | *Cloud 1 | 174×73 · v2 indexed 8-bit | ok |
| PICT | Sprites | 2900 | Passage | 68×87 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2901 | Passage (Ornate) | 90×111 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2902 | Sign | 39×60 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2903 | Book | 26×40 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2904 | — | 27×17 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2905 | Wall Map | 72×45 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2906 | Steel Plaque | 52×32 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2907 | — | 39×60 · v2 indexed 8-bit | ok |
| PICT | Sprites | 2910 | — | 360×88 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2915 | Door right | 360×84 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2920 | Bale of hay | 56×60 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2921 | Crate | 56×60 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2922 | Barrel | 56×60 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2923 | Barstool | 24×41 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2924 | Wooden chair | 40×55 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2925 | Steel chair | 53×52 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2926 | Steel Table | 62×39 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2927 | Wooden table | 79×53 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2928 | Fancy table | 81×59 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2929 | — | 142×52 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2930 | Mine cart | 896×192 · v2 indexed 8-bit | ok |
| PICT | Sprites | 2931 | minecar wheel | 895×174 · v2 indexed 8-bit | ok |
| PICT | Sprites | 2932 | — | 384×20 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2933 | — | 384×108 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2940 | — | 32×116 · v2 indexed 8-bit | ok |
| PICT | Sprites | 2941 | — | 32×116 · v2 indexed 8-bit | ok |
| PICT | Sprites | 2951 | Geroditus | 100×33 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2952 | merchant | 54×86 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2953 | Limping Habnabit | 39×80 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2954 | Sitting Habnabit | 51×64 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2955 | Nimbo | 96×74 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2956 | Dimbo | 88×82 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2957 | Hooded Figure | 38×106 · v2 indexed 8-bit | ok |
| PICT | Sprites | 2958 | Taryn | 45×102 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2959 | Sara | 45×102 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2960 | Forest Nymph Matriarch | 50×110 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2961 | Blue Short Hooded | 38×87 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2962 | Gray-Robed Sitting Habnabit | 51×64 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2963 | Gray-Robed Short Hooded | 38×87 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2964 | Hooded Bluegray Merchant | 54×86 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 2965 | Left Bluebrown merchant | 54×86 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 3000 | HPassage, 1 tile | 128×128 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 3001 | HPassage, 2 tiles | 160×128 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 3002 | HPassage, 3 tiles | 192×128 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 3003 | HPassage, 4 tiles | 224×128 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 3004 | HPassage, 5 tiles | 256×128 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 3005 | HPassage, 6 tiles | 288×128 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 3006 | HPassage, 7 tiles | 320×128 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 3007 | HPassage, 8 tiles | 352×128 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 3008 | HPassage, 9 tiles | 384×128 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 3009 | HPassage, 10 tiles | 416×128 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 3050 | $Hang Glider | 160×160 · v2 indexed 8-bit | ok |
| PICT | Sprites | 3060 | !Rotating sword | 187×187 · v2 indexed 8-bit | ok |
| PICT | Sprites | 3070 | — | 128×128 · v2 indexed 8-bit | ok |
| PICT | Sprites | 3071 | — | 128×128 · v2 indexed 8-bit | ok |
| PICT | Sprites | 3072 | — | 128×128 · v2 indexed 8-bit | ok |
| PICT | Sprites | 3080 | *Tree, slight tilt | 226×221 · v2 indexed 8-bit | ok |
| PICT | Sprites | 3081 | *Tree, normal | 227×206 · v2 indexed 8-bit | ok |
| PICT | Sprites | 3082 | *Tree, squat | 264×171 · v2 indexed 8-bit | ok |
| PICT | Sprites | 3083 | *Tree, aspen | 198×263 · v2 indexed 8-bit | ok |
| PICT | Sprites | 3084 | *Tree, bare, fullspiky | 141×314 · v2 indexed 8-bit | ok |
| PICT | Sprites | 3085 | *Tree, bare, semibroken | 223×255 · v2 indexed 8-bit | ok |
| PICT | Sprites | 3086 | *Tree, bare, jagged trunk | 114×248 · v2 indexed 8-bit | ok |
| PICT | Sprites | 3087 | *Tree, horizontal trunk | 414×88 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 3090 | $Crate - bonus | 38×38 · v2 indexed 4-bit | ok |
| PICT | Sprites | 3091 | $Crate - question mark | 38×38 · v2 indexed 8-bit | ok |
| PICT | Sprites | 3092 | $Crate - exclamation point | 38×38 · v2 indexed 8-bit | ok |
| PICT | Sprites | 3099 | — | 192×48 · v2 indexed 4-bit | ok |
| PICT | Sprites | 3100 | Standing Candelabra, Regular | 36×90 · v2 indexed 8-bit | ok |
| PICT | Sprites | 3101 | Standing Candelabra, Spiky | 36×90 · v2 indexed 8-bit | ok |
| PICT | Sprites | 3102 | Standing Candelabra, Wooden | 36×90 · v2 indexed 8-bit | ok |
| PICT | Sprites | 3103 | Magic Tentacle Light | 36×90 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 3104 | Wall Candelabra, Gold | 40×48 · v2 indexed 4-bit | ok |
| PICT | Sprites | 3105 | Wall Candelabra, Silver | 40×48 · v2 indexed 4-bit | ok |
| PICT | Sprites | 3106 | — | 40×48 · v2 indexed 4-bit | ok |
| PICT | Sprites | 3107 | Glowing Bug Light | 40×48 · v2 indexed 8-bit | ok |
| PICT | Sprites | 3108 | Horned Skull Light | 40×48 · v2 indexed 8-bit | ok |
| PICT | Sprites | 3201 | — | 32×24 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 3202 | Gold Key | 32×24 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 3203 | Platinum Key | 32×24 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 3204 | magic ptn | 32×27 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 3205 | — | 32×26 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 3206 | Fire seeds | 32×26 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 3207 | $Locket | 32×35 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 3208 | $Hammer | 37×35 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 3209 | $Poppyseed Muffin | 31×32 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 3210 | $Algernon Piece | 32×26 · v2 indexed 8-bit | ok |
| PICT | Sprites | 3211 | $Algernon Frame | 32×34 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 3212 | $Algernon | 33×34 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 3213 | $Gwendolyn | 33×34 · v2 indexed 8-bit | ok |
| PICT | Sprites | 3214 | $Wooden Shield | 32×35 · v2 indexed 8-bit | ok |
| PICT | Sprites | 3215 | $Magic Shield | 32×35 · v2 indexed 8-bit | ok |
| PICT | Sprites | 3216 | $Gold Ring | 32×24 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 3217 | $Green Ring | 32×24 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 3218 | $Ice Pick | 32×43 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 3219 | $Multiplier Crystal | 32×34 · v2 indexed 8-bit | ok |
| PICT | Sprites | 3220 | $Light Orb | 35×35 · v2 indexed 8-bit | ok |
| PICT | Sprites | 3221 | $Vorpal Dirk | 32×43 · v2 indexed 8-bit | ok |
| PICT | Sprites | 3222 | $Xichron | 32×28 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 3223 | $Rez Necklace | 32×42 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 3224 | $Fire Charm | 32×39 · v2 indexed 8-bit | ok |
| PICT | Sprites | 3225 | $Mist Potion | 32×32 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 3226 | — | 32×26 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 3250 | — | 48×38 · v2 indexed 8-bit | ok |
| PICT | Sprites | 3999 | — | 96×96 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 4000 | — | 387×308 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 4001 | — | 96×96 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 4002 | — | 96×96 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 4003 | — | 96×96 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 4004 | — | 96×96 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 4005 | — | 96×96 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 4006 | — | 96×96 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 4007 | — | 96×96 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 4008 | — | 96×96 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 4009 | — | 96×96 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 4010 | Taryn | 96×96 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 4011 | Sara | 96×96 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 4012 | Matriarch | 96×96 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 4013 | Nimbo | 96×96 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 4014 | Dimbo | 96×96 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 4015 | Andrew Hunter | 96×96 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 4016 | — | 96×96 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 4017 | — | 96×96 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 4018 | — | 96×96 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 4019 | — | 96×96 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 4020 | — | 96×96 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 4021 | — | 96×96 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 4022 | — | 96×96 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 4023 | — | 96×96 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 4024 | — | 96×96 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 4025 | — | 96×96 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 4030 | — | 96×96 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 4031 | — | 96×96 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 4032 | — | 96×96 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 4033 | — | 96×96 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 5000 | — | 512×768 · v2 indexed 8-bit | ok |
| PICT | Sprites | 5001 | — | 768×256 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 5002 | — | 768×256 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 5069 | — | 512×768 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 5999 | — | 128×128 · v2 indexed 8-bit | ok |
| PICT | Sprites | 6000 | — | 128×128 · v2 indexed 8-bit | ok |
| PICT | Sprites | 6001 | — | 128×128 · v2 indexed 8-bit | ok |
| PICT | Sprites | 6002 | — | 128×128 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 6003 | — | 128×128 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 6004 | — | 128×128 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 6011 | — | 128×128 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 6012 | — | 128×128 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 6031 | — | 128×128 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 6100 | — | 128×128 · v2 indexed 8-bit | ok |
| PICT | Sprites | 6200 | — | 128×128 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 6201 | — | 128×128 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 6209 | — | 128×128 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 6210 | — | 128×128 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 6300 | — | 128×128 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 6301 | — | 128×128 · v2 indexed 8-bit | ok |
| PICT | Sprites | 8000 | — | 24×24 · v2 indexed 8-bit | ok |
| PICT | Sprites | 8001 | — | 192×24 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 8002 | — | 192×24 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 8003 | — | 24×24 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 8004 | — | 512×86 · v2 indexed 8-bit | ok |
| PICT | Sprites | 10200 | orig headsmooth walk | 400×304 · v2 indexed 8-bit | ok |
| PICT | Sprites | 13070 | — | 72×22 · v2 direct 32-bit mode 64 | ok |
| PICT | Sprites | 14340 | — | 24×24 · v2 indexed 8-bit | ok |
| PICT | Sprites | 14850 | — | 100×100 · v2 indexed 8-bit | ok |
| PICT | Titles | 128 | Loading Screen | 640×480 · v2 indexed 8-bit | ok |
| PICT | Titles | 129 | Game Screen | 640×480 · v2 indexed 4-bit | ok |
| PICT | Titles | 130 | — | 640×480 · v2 indexed 8-bit | ok |
| PICT | Titles | 131 | Publisher Logo | 640×480 · v2 indexed 8-bit | ok |
| PICT | Titles | 132 | — | 640×88 · v2 indexed 8-bit | ok |
| PICT | Titles | 133 | — | 196×45 · v2 direct 32-bit mode 64 | ok |
| PICT | Titles | 134 | — | 640×480 · v2 indexed 8-bit | ok |
| PICT | Titles | 136 | — | 640×480 · v2 indexed 8-bit | ok |
| PICT | Titles | 137 | — | 640×480 · v2 indexed 8-bit | ok |
| PICT | Titles | 138 | — | 640×480 · v2 indexed 8-bit | ok |
| PICT | Titles | 140 | — | 320×110 · v2 indexed 8-bit | ok |
| PICT | Titles | 141 | — | 52×714 · v2 indexed 8-bit | ok |
| PICT | Titles | 142 | — | 320×64 · v2 indexed 8-bit | ok |
| PICT | Titles | 159 | — | 640×416 · v2 indexed 8-bit | ok |
| PICT | Titles | 161 | — | 640×416 · v2 indexed 8-bit | ok |
| PICT | Titles | 162 | — | 640×128 · v2 indexed 8-bit | ok |
| PICT | Titles | 172 | — | 82×82 · v2 indexed 8-bit | ok |
| PICT | Titles | 173 | — | 82×82 · v2 indexed 8-bit | ok |
| PICT | Titles | 174 | — | 82×82 · v2 indexed 8-bit | ok |
| PICT | Titles | 175 | — | 82×82 · v2 indexed 8-bit | ok |
| PICT | Titles | 176 | — | 82×82 · v2 indexed 8-bit | ok |
| PICT | Titles | 177 | — | 82×82 · v2 indexed 8-bit | ok |
| PICT | Titles | 4600 | — | 535×269 · v2 indexed 8-bit | ok |
| PICT | Titles | 4601 | — | 345×188 · v2 indexed 8-bit | ok |
| PICT | Titles | 4602 | — | 454×52 · v2 indexed 8-bit | ok |
| PICT | Titles | 4603 | — | 209×49 · v2 indexed 8-bit | ok |
| PICT | Titles | 4604 | — | 378×49 · v2 indexed 8-bit | ok |
| PICT | Titles | 4605 | — | 354×49 · v2 indexed 8-bit | ok |
| PICT | Titles | 4606 | — | 222×80 · v2 indexed 8-bit | ok |
| PICT | Titles | 4607 | — | 315×189 · v2 indexed 8-bit | ok |
| PICT | Titles | 4610 | — | 640×480 · v2 indexed 8-bit | ok |
| PICT | Titles | 4620 | — | 608×480 · v2 indexed 8-bit | ok |
| PICT | Titles | 4630 | — | 608×480 · v2 indexed 8-bit | ok |
| PICT | Titles | 4640 | — | 608×480 · v2 indexed 8-bit | ok |
| PICT | Titles | 4650 | — | 640×480 · v2 indexed 8-bit | ok |
| PICT | Titles | 4660 | — | 640×480 · v2 indexed 8-bit | ok |
| PICT | Titles | 4670 | — | 608×480 · v2 indexed 8-bit | ok |
| PICT | Titles | 4803 | — | 144×811 · v2 indexed 2-bit | ok |
| PICT | Titles | 4804 | — | 200×276 · v2 indexed 8-bit | ok |
| PICT | Titles | 4901 | — | 154×42 · v2 direct 32-bit mode 64 | ok |
| PICT | Titles | 4902 | — | 192×40 · v2 direct 32-bit mode 64 | ok |
| PICT | Titles | 4903 | — | 171×42 · v2 direct 32-bit mode 64 | ok |
| PICT | Titles | 4904 | — | 114×40 · v2 direct 32-bit mode 64 | ok |
| PICT | Titles | 4905 | — | 83×42 · v2 direct 32-bit mode 64 | ok |
| PICT | Titles | 4911 | — | 154×42 · v2 direct 32-bit mode 64 | ok |
| PICT | Titles | 4912 | — | 192×40 · v2 direct 32-bit mode 64 | ok |
| PICT | Titles | 4913 | — | 171×42 · v2 direct 32-bit mode 64 | ok |
| PICT | Titles | 4914 | — | 114×40 · v2 direct 32-bit mode 64 | ok |
| PICT | Titles | 4915 | — | 83×42 · v2 direct 32-bit mode 64 | ok |
| PICT | Titles | 4921 | — | 225×96 · v2 direct 32-bit mode 64 | ok |
| PICT | Titles | 4925 | — | 83×42 · v2 direct 32-bit mode 64 | ok |
| PICT | Titles | 4935 | — | 83×42 · v2 direct 32-bit mode 64 | ok |
| PICT | Titles | 4951 | — | 194×53 · v2 indexed 8-bit | ok |
| PICT | Titles | 4952 | — | 242×52 · v2 indexed 8-bit | ok |
| PICT | Titles | 4953 | — | 216×52 · v2 indexed 8-bit | ok |
| PICT | Titles | 4954 | — | 149×52 · v2 indexed 8-bit | ok |
| PICT | Titles | 4955 | — | 109×53 · v2 indexed 8-bit | ok |
| PICT | Titles | 4961 | — | 194×53 · v2 indexed 8-bit | ok |
| PICT | Titles | 4962 | — | 242×52 · v2 indexed 8-bit | ok |
| PICT | Titles | 4963 | — | 216×52 · v2 indexed 8-bit | ok |
| PICT | Titles | 4964 | — | 149×52 · v2 indexed 8-bit | ok |
| PICT | Titles | 4965 | — | 109×53 · v2 indexed 8-bit | ok |
| PICT | Titles | 4970 | — | 138×22 · v2 indexed 8-bit | ok |
| PICT | Titles | 4971 | — | 117×21 · v2 direct 32-bit mode 64 | ok |
| PICT | Titles | 4980 | — | 138×22 · v2 indexed 8-bit | ok |
| PICT | Titles | 4981 | — | 117×21 · v2 direct 32-bit mode 64 | ok |
| PICT | Titles | 4985 | — | 32×28 · v2 indexed 8-bit | ok |
| clut | app | 198 | cooling map clut | 256 entries | ok |
| clut | app | 199 | base sprite clut grays | 256 entries | ok |
| clut | app | 200 | base sprite clut | 256 entries | ok |
| clut | app | 700 | world map clut | 256 entries | ok |
| clut | app | 801 | System CLUT | 256 entries | ok |
| clut | app | 4000 | dialogue palette | 256 entries | ok |
| clut | Backgrounds | 198 | cooling map clut | 256 entries | ok |
| clut | Backgrounds | 199 | base sprite clut grays | 256 entries | ok |
| clut | Backgrounds | 200 | base sprite clut | 256 entries | ok |
| clut | Backgrounds | 201 | earthcav | 256 entries | ok |
| clut | Backgrounds | 202 | base + earthcav | 256 entries · 0x00..0x9f = clut 200 | ok |
| clut | Backgrounds | 203 | lake | 256 entries | ok |
| clut | Backgrounds | 204 | base + lake | 256 entries · 0x00..0x9f = clut 200 | ok |
| clut | Backgrounds | 205 | night rock lake | 256 entries | ok |
| clut | Backgrounds | 206 | night rock lake + base | 256 entries · 0x00..0x9f = clut 200 | ok |
| clut | Backgrounds | 207 | forest | 256 entries | ok |
| clut | Backgrounds | 208 | forest + base | 256 entries · 0x00..0x9f = clut 200 | ok |
| clut | Backgrounds | 209 | EC2 | 256 entries | ok |
| clut | Backgrounds | 210 | EC2 + base | 256 entries · 0x00..0x9f = clut 200 | ok |
| clut | Backgrounds | 211 | forest 2 | 256 entries | ok |
| clut | Backgrounds | 212 | forest 2 + base | 256 entries · 0x00..0x9f = clut 200 | ok |
| clut | Backgrounds | 213 | forest 1 new | 256 entries | ok |
| clut | Backgrounds | 214 | forest 1 new + base | 256 entries · 0x00..0x9f = clut 200 | ok |
| clut | Backgrounds | 215 | Upper Ice Caverns | 256 entries | ok |
| clut | Backgrounds | 216 | Upper Ice Caverns + base | 256 entries · 0x00..0x9f = clut 200 | ok |
| clut | Backgrounds | 217 | Lower Ice Caverns | 256 entries | ok |
| clut | Backgrounds | 218 | Lower Ice Caverns + base | 256 entries · 0x00..0x9f = clut 200 | ok |
| clut | Backgrounds | 219 | Upper Fire Caverns | 256 entries | ok |
| clut | Backgrounds | 220 | Upper Fire Caverns + base | 256 entries · 0x00..0x9f = clut 200 | ok |
| clut | Backgrounds | 221 | Upper Fire Caverns flame | 256 entries | ok |
| clut | Backgrounds | 222 | Upper Fire Caverns flame + base | 256 entries · 0x00..0x9f = clut 200 | ok |
| clut | Backgrounds | 223 | newlake | 256 entries | ok |
| clut | Backgrounds | 224 | newlake + base | 256 entries · 0x00..0x9f = clut 200 | ok |
| clut | Backgrounds | 225 | Hunter forest | 256 entries | ok |
| clut | Backgrounds | 226 | Hunter forest + base | 256 entries · 0x00..0x9f = clut 200 | ok |
| clut | Backgrounds | 227 | Desert | 256 entries | ok |
| clut | Backgrounds | 228 | Desert + base | 256 entries · 0x00..0x9f = clut 200 | ok |
| clut | Backgrounds | 229 | Plains | 256 entries | ok |
| clut | Backgrounds | 230 | Plains + base | 256 entries · 0x00..0x9f = clut 200 | ok |
| clut | Backgrounds | 231 | Mountains1 | 256 entries | ok |
| clut | Backgrounds | 232 | Mountains1 + base | 256 entries · 0x00..0x9f = clut 200 | ok |
| clut | Backgrounds | 235 | Boss1abstract | 256 entries | ok |
| clut | Backgrounds | 236 | Boss1abstract + base | 256 entries · 0x00..0x9f = clut 200 | ok |
| clut | Backgrounds | 237 | RuinsBoss | 256 entries | ok |
| clut | Backgrounds | 238 | RuinsBoss + base | 256 entries · 0x00..0x9f = clut 200 | ok |
| clut | Backgrounds | 239 | Mountains2 | 256 entries | ok |
| clut | Backgrounds | 240 | Mountains2 + base | 256 entries · 0x00..0x9f = clut 200 | ok |
| clut | Backgrounds | 241 | Purple abstract | 256 entries | ok |
| clut | Backgrounds | 242 | Purple abstract + base | 256 entries · 0x00..0x9f = clut 200 | ok |
| clut | Backgrounds | 243 | Breathing | 256 entries | ok |
| clut | Backgrounds | 244 | Breathing + base | 256 entries · 0x00..0x9f = clut 200 | ok |
| clut | Backgrounds | 245 | Ruins1 | 256 entries | ok |
| clut | Backgrounds | 246 | Ruins1 + base | 256 entries · 0x00..0x9f = clut 200 | ok |
| clut | Backgrounds | 247 | Throne Room | 256 entries | ok |
| clut | Backgrounds | 248 | Throne Room + base | 256 entries · 0x00..0x9f = clut 200 | ok |
| clut | Backgrounds | 300 | Blue tinge altClut orig | 256 entries | ok |
| clut | Backgrounds | 301 | Gold tinge altClut | 256 entries | ok |
| clut | Backgrounds | 302 | Purply tinge altClut | 256 entries | ok |
| clut | Backgrounds | 322 | Upper Fire Caverns flame + base o | 256 entries · 0x00..0x9f = clut 200 | ok |
| clut | Backgrounds | 401 | bluepurp ting | 256 entries | ok |
| clut | Backgrounds | 700 | world map clut | 256 entries | ok |
| clut | Backgrounds | 801 | System CLUT | 256 entries | ok |
| clut | Backgrounds | 4000 | dialogue palette | 256 entries | ok |
| clut | Titles | 128 | splash screen clut | 256 entries | ok |
| clut | Titles | 130 | main menu clut | 256 entries | ok |
| clut | Titles | 131 | preview clut | 256 entries | ok |
| clut | Titles | 132 | death clut | 256 entries | ok |
| clut | Titles | 260 | Victory | 256 entries | ok |
| clut | Titles | 281 | 1 intro chapter | 256 entries | ok |
| clut | Titles | 282 | 2 forest chapter | 256 entries | ok |
| clut | Titles | 283 | 3 desert chapter | 256 entries | ok |
| clut | Titles | 284 | 4 fire chapter | 256 entries | ok |
| clut | Titles | 285 | 5 ruins chapter | 256 entries | ok |
| clut | Titles | 286 | 6 ice chapter | 256 entries | ok |
| clut | Titles | 287 | 7 mountain chapter | 256 entries | ok |
| clut | Titles | 288 | interstitial 1 | 256 entries | ok |
| clut | Titles | 289 | interstitial 2 | 256 entries | ok |
| clut | Titles | 290 | interstitial 3 | 256 entries | ok |
| clut | Titles | 729 | splash screen clut orig | 256 entries | ok |
| snd | Sounds | 128 | soft impact | format 1 · 22050 Hz · 8,896 frames | ok |
| snd | Sounds | 129 | whoosh | format 1 · 22050 Hz · 15,744 frames | ok |
| snd | Sounds | 130 | froghitold | format 1 · 22050 Hz · 7,808 frames | ok |
| snd | Sounds | 131 | frogdieold | format 1 · 22050 Hz · 9,024 frames | ok |
| snd | Sounds | 132 | frogjumpold | format 1 · 22050 Hz · 4,702 frames | ok |
| snd | Sounds | 198 | pause | format 1 · 11025 Hz · 1,400 frames | ok |
| snd | Sounds | 215 | oil | format 1 · 22050 Hz · 11,776 frames | ok |
| snd | Sounds | 231 | charge1 | format 1 · 11025 Hz · 19,808 frames | ok |
| snd | Sounds | 238 | magic1 | format 1 · 11025 Hz · 8,704 frames | ok |
| snd | Sounds | 239 | metallic click | format 1 · 22050 Hz · 5,760 frames | ok |
| snd | Sounds | 240 | unlock | format 1 · 11025 Hz · 6,304 frames | ok |
| snd | Sounds | 300 | Fireball | format 1 · 22050 Hz · 9,968 frames | ok |
| snd | Sounds | 301 | fireball hit new | format 1 · 22050 Hz · 9,968 frames | ok |
| snd | Sounds | 302 | statue hit | format 1 · 22050 Hz · 14,976 frames | ok |
| snd | Sounds | 303 | metal hit | format 1 · 22050 Hz · 6,112 frames | ok |
| snd | Sounds | 304 | swoosh big | format 1 · 22050 Hz · 7,712 frames | ok |
| snd | Sounds | 401 | Ouch 1 | format 1 · 22050 Hz · 7,264 frames | ok |
| snd | Sounds | 402 | Ouch 2 | format 1 · 22050 Hz · 6,816 frames | ok |
| snd | Sounds | 403 | Ouch 3 | format 1 · 22050 Hz · 5,952 frames | ok |
| snd | Sounds | 404 | head bonk | format 1 · 22050 Hz · 2,992 frames | ok |
| snd | Sounds | 405 | splash1new3 | format 1 · 22050 Hz · 26,624 frames | ok |
| snd | Sounds | 406 | splash2new | format 1 · 22050 Hz · 9,088 frames | ok |
| snd | Sounds | 407 | groan | format 1 · 22050 Hz · 26,176 frames | ok |
| snd | Sounds | 408 | breathe1 | format 1 · 22050 Hz · 14,464 frames | ok |
| snd | Sounds | 409 | breathe2 | format 1 · 22050 Hz · 19,772 frames | ok |
| snd | Sounds | 410 | Footstep1 | format 1 · 22050 Hz · 4,512 frames | ok |
| snd | Sounds | 411 | Footstep2 | format 1 · 22050 Hz · 4,128 frames | ok |
| snd | Sounds | 412 | Footstep3 | format 1 · 22050 Hz · 4,080 frames | ok |
| snd | Sounds | 413 | Footstep4 | format 1 · 22050 Hz · 4,592 frames | ok |
| snd | Sounds | 414 | jump | format 1 · 22050 Hz · 7,264 frames | ok |
| snd | Sounds | 415 | bubble | format 1 · 11025 Hz · 3,224 frames | ok |
| snd | Sounds | 416 | corner climb | format 1 · 22050 Hz · 12,800 frames | ok |
| snd | Sounds | 417 | death | format 1 · 22050 Hz · 79,104 frames | ok |
| snd | Sounds | 418 | dagger thrust | format 1 · 22050 Hz · 5,440 frames | ok |
| snd | Sounds | 419 | dagger hit | format 1 · 22050 Hz · 9,216 frames | ok |
| snd | Sounds | 420 | teleport in | format 1 · 22050 Hz · 21,428 frames | ok |
| snd | Sounds | 421 | teleport out | format 1 · 22050 Hz · 25,088 frames | ok |
| snd | Sounds | 422 | really big anvil-like crash8-22 | format 1 · 22050 Hz · 17,792 frames | ok |
| snd | Sounds | 423 | rock crack | format 1 · 22050 Hz · 7,296 frames | ok |
| snd | Sounds | 424 | rock crush | format 1 · 22050 Hz · 16,832 frames | ok |
| snd | Sounds | 425 | rock selfcrack | format 1 · 22050 Hz · 7,296 frames | ok |
| snd | Sounds | 426 | rock selfcrush | format 1 · 22050 Hz · 16,832 frames | ok |
| snd | Sounds | 427 | player magic spin | format 1 · 22050 Hz · 33,091 frames | ok |
| snd | Sounds | 428 | Tick 1 | format 1 · 11025 Hz · 840 frames | ok |
| snd | Sounds | 429 | Tick 2 | format 1 · 11025 Hz · 568 frames | ok |
| snd | Sounds | 430 | geyser start | format 1 · 22050 Hz · 22,144 frames | ok |
| snd | Sounds | 431 | geyser loop | format 1 · 22050 Hz · 55,040 frames | ok |
| snd | Sounds | 432 | monster snarl | format 1 · 22050 Hz · 29,952 frames | ok |
| snd | Sounds | 433 | monster snarl 2 | format 1 · 22050 Hz · 25,856 frames | ok |
| snd | Sounds | 434 | monster snarl 3 | format 1 · 22050 Hz · 28,672 frames | ok |
| snd | Sounds | 435 | explosion | format 1 · 22050 Hz · 26,305 frames | ok |
| snd | Sounds | 436 | Object Hit | format 1 · 22050 Hz · 6,622 frames | ok |
| snd | Sounds | 437 | Door unlock open | format 1 · 22050 Hz · 21,139 frames | ok |
| snd | Sounds | 438 | Door open | format 1 · 22050 Hz · 16,267 frames | ok |
| snd | Sounds | 439 | chest unlock | format 1 · 22050 Hz · 5,320 frames | ok |
| snd | Sounds | 440 | catapult_step.snd | format 1 · 22050 Hz · 7,829 frames | ok |
| snd | Sounds | 441 | catapult_launch.snd | format 1 · 22050 Hz · 7,178 frames | ok |
| snd | Sounds | 442 | drown warning | format 1 · 22050 Hz · 2,112 frames | ok |
| snd | Sounds | 443 | drown choke | format 1 · 22050 Hz · 13,696 frames | ok |
| snd | Sounds | 444 | bonus 1 | format 1 · 22050 Hz · 13,109 frames | ok |
| snd | Sounds | 445 | bonus 2 | format 1 · 22050 Hz · 22,829 frames | ok |
| snd | Sounds | 446 | bonus 3 | format 1 · 22050 Hz · 11,976 frames | ok |
| snd | Sounds | 447 | bonus 4 | format 1 · 22050 Hz · 20,610 frames | ok |
| snd | Sounds | 448 | bonus 5 | format 1 · 22050 Hz · 8,312 frames | ok |
| snd | Sounds | 449 | bonus 6 | format 1 · 22050 Hz · 15,773 frames | ok |
| snd | Sounds | 450 | Big ouch | format 1 · 22050 Hz · 11,584 frames | ok |
| snd | Sounds | 451 | majorbonus new | format 1 · 11025 Hz · 21,248 frames | ok |
| snd | Sounds | 452 | rainloop.snd | format 1 · 22050 Hz · 61,384 frames | ok |
| snd | Sounds | 453 | thunder.snd | format 1 · 22050 Hz · 45,150 frames | ok |
| snd | Sounds | 454 | water step | format 1 · 22050 Hz · 9,185 frames | ok |
| snd | Sounds | 455 | wall grab | format 1 · 22050 Hz · 4,440 frames | ok |
| snd | Sounds | 456 | bubblebreathe | format 1 · 22050 Hz · 8,544 frames | ok |
| snd | Sounds | 457 | spike emerge | format 1 · 22050 Hz · 7,032 frames | ok |
| snd | Sounds | 458 | spike retract | format 1 · 22050 Hz · 6,265 frames | ok |
| snd | Sounds | 459 | enemygenerate | format 1 · 22050 Hz · 13,067 frames | ok |
| snd | Sounds | 460 | rock barrier move | format 1 · 11025 Hz · 18,167 frames | ok |
| snd | Sounds | 461 | platformdisappear 11kHz | format 1 · 11025 Hz · 3,968 frames | ok |
| snd | Sounds | 462 | enemyconsumed | format 1 · 11025 Hz · 10,400 frames | ok |
| snd | Sounds | 463 | dillo shoot | format 1 · 22050 Hz · 13,600 frames | ok |
| snd | Sounds | 464 | toad | format 1 · 11025 Hz · 3,647 frames | ok |
| snd | Sounds | 465 | goblingrowl1 | format 1 · 11025 Hz · 24,448 frames | ok |
| snd | Sounds | 466 | goblingrowl2 | format 1 · 11025 Hz · 17,504 frames | ok |
| snd | Sounds | 467 | goblintaunt | format 1 · 11025 Hz · 18,432 frames | ok |
| snd | Sounds | 468 | goblinhurt | format 1 · 11025 Hz · 10,144 frames | ok |
| snd | Sounds | 469 | goblindie | format 1 · 11025 Hz · 23,232 frames | ok |
| snd | Sounds | 470 | bat | format 1 · 22254.545 Hz · 7,422 frames | ok |
| snd | Sounds | 471 | snarl | format 1 · 11025 Hz · 11,881 frames | ok |
| snd | Sounds | 472 | metalhitsoft | format 1 · 11025 Hz · 2,538 frames | ok |
| snd | Sounds | 473 | metalhithard | format 1 · 11025 Hz · 4,298 frames | ok |
| snd | Sounds | 474 | sparkleloop | format 1 · 22050 Hz · 29,376 frames | ok |
| snd | Sounds | 475 | endlevelsound | format 1 · 22050 Hz · 31,454 frames | ok |
| snd | Sounds | 476 | electricitySound | format 1 · 22050 Hz · 10,976 frames | ok |
| snd | Sounds | 477 | monster1Sound | format 1 · 22050 Hz · 31,040 frames | ok |
| snd | Sounds | 478 | monster2Sound | format 1 · 22050 Hz · 33,452 frames | ok |
| snd | Sounds | 479 | monster3Sound | format 1 · 11025 Hz · 15,634 frames | ok |
| snd | Sounds | 480 | swarmMemberDieSound | format 1 · 11025 Hz · 7,552 frames | ok |
| snd | Sounds | 481 | swarmSound | format 1 · 11025 Hz · 7,552 frames | ok |
| snd | Sounds | 482 | wind loop | format 1 · 11025 Hz · 42,670 frames | ok |
| snd | Sounds | 483 | cannon shoot | format 1 · 22050 Hz · 20,352 frames | ok |
| snd | Sounds | 484 | cannon load | format 1 · 11025 Hz · 4,208 frames | ok |
| snd | Sounds | 485 | cannon shift | format 1 · 22050 Hz · 2,448 frames | ok |
| snd | Sounds | 486 | ropecreak1 | format 1 · 22050 Hz · 14,053 frames | ok |
| snd | Sounds | 487 | ropecreak2 | format 1 · 22050 Hz · 9,833 frames | ok |
| snd | Sounds | 488 | ropecreak3 | format 1 · 22050 Hz · 9,478 frames | ok |
| snd | Sounds | 489 | chaincreak1 | format 1 · 22050 Hz · 8,608 frames | ok |
| snd | Sounds | 490 | chaincreak2 | format 1 · 22050 Hz · 8,800 frames | ok |
| snd | Sounds | 491 | chaincreak3 | format 1 · 22050 Hz · 6,488 frames | ok |
| snd | Sounds | 492 | cratesmash | format 1 · 22050 Hz · 13,568 frames | ok |
| snd | Sounds | 493 | superspring | format 1 · 22050 Hz · 14,016 frames | ok |
| snd | Sounds | 494 | flap | format 1 · 22050 Hz · 8,832 frames | ok |
| snd | Sounds | 495 | firehiss | format 1 · 22050 Hz · 12,800 frames | ok |
| snd | Sounds | 496 | firehiss2 | format 1 · 22050 Hz · 14,774 frames | ok |
| snd | Sounds | 497 | swim | format 1 · 22050 Hz · 17,152 frames | ok |
| snd | Sounds | 498 | Egg Drop | format 1 · 22050 Hz · 4,496 frames | ok |
| snd | Sounds | 499 | ArrowShootSound | format 1 · 22050 Hz · 14,304 frames | ok |
| snd | Sounds | 500 | magic bonus | format 1 · 22050 Hz · 24,192 frames | ok |
| snd | Sounds | 501 | coin bonus | format 1 · 22050 Hz · 10,464 frames | ok |
| snd | Sounds | 502 | health bonus | format 1 · 22050 Hz · 18,176 frames | ok |
| snd | Sounds | 503 | newspell | format 1 · 22050 Hz · 46,720 frames | ok |
| snd | Sounds | 504 | elecshot | format 1 · 22050 Hz · 13,952 frames | ok |
| snd | Sounds | 505 | puzzleunlock | format 1 · 22050 Hz · 28,672 frames | ok |
| snd | Sounds | 506 | itemfind | format 1 · 22050 Hz · 35,200 frames | ok |
| snd | Sounds | 507 | crystalbreak | format 1 · 22050 Hz · 15,392 frames | ok |
| snd | Sounds | 508 | hurtthud | format 1 · 22050 Hz · 6,624 frames | ok |
| snd | Sounds | 509 | corpsethud | format 1 · 22050 Hz · 11,296 frames | ok |
| snd | Sounds | 510 | whoosh | format 1 · 11025 Hz · 7,872 frames | ok |
| snd | Sounds | 511 | fireloop | format 1 · 22050 Hz · 38,784 frames | ok |
| snd | Sounds | 600 | hit ground | format 1 · 22050 Hz · 14,464 frames | ok |
| snd | Sounds | 601 | hit ground soft | format 1 · 22050 Hz · 4,320 frames | ok |
| snd | Sounds | 602 | hit ground | format 1 · 22050 Hz · 7,216 frames | ok |
| snd | Sounds | 603 | spring down | format 1 · 22050 Hz · 9,270 frames | ok |
| snd | Sounds | 604 | spring up | format 1 · 22050 Hz · 19,500 frames | ok |
| snd | Sounds | 605 | sandsplash | format 1 · 22050 Hz · 7,872 frames | ok |
| snd | Sounds | 606 | deathcontinue | format 1 · 22050 Hz · 13,696 frames | ok |
| snd | Sounds | 607 | slimemove | format 1 · 22050 Hz · 5,280 frames | ok |
| snd | Sounds | 608 | batdisturb | format 1 · 22050 Hz · 12,658 frames | ok |
| snd | Sounds | 609 | bathit | format 1 · 22050 Hz · 6,000 frames | ok |
| snd | Sounds | 610 | axgoblinjumproar | format 1 · 11025 Hz · 11,648 frames | ok |
| snd | Sounds | 611 | axgoblinhit1 | format 1 · 22050 Hz · 22,656 frames | ok |
| snd | Sounds | 612 | axgoblinhit2 | format 1 · 11025 Hz · 7,614 frames | ok |
| snd | Sounds | 613 | frogjump | format 1 · 22050 Hz · 6,080 frames | ok |
| snd | Sounds | 614 | froghit | format 1 · 22050 Hz · 18,304 frames | ok |
| snd | Sounds | 615 | frogdie | format 1 · 22050 Hz · 16,192 frames | ok |
| snd | Sounds | 700 | Crawler jump | format 1 · 22050 Hz · 6,224 frames | ok |
| snd | Sounds | 701 | Crawler Ouch | format 1 · 22050 Hz · 13,568 frames | ok |
| snd | Sounds | 702 | Crawler uh oh | format 1 · 22050 Hz · 20,352 frames | ok |
| snd | Sounds | 703 | crawler death | format 1 · 22050 Hz · 20,832 frames | ok |
| snd | Sounds | 704 | throw | format 1 · 22050 Hz · 4,160 frames | ok |
| snd | Sounds | 705 | throw old | format 1 · 22050 Hz · 4,256 frames | ok |
| snd | Sounds | 800 | zeropercent | format 1 · 22050 Hz · 7,088 frames | ok |
| snd | Sounds | 801 | middlepercent | format 1 · 22050 Hz · 7,584 frames | ok |
| snd | Sounds | 802 | hundredpercent | format 1 · 22050 Hz · 9,632 frames | ok |
| snd | Sounds | 803 | fillerup | format 1 · 22050 Hz · 12,192 frames | ok |
| snd | Sounds | 804 | donefilling | format 1 · 22050 Hz · 2,304 frames | ok |
| snd | Sounds | 805 | popup | format 1 · 22050 Hz · 4,306 frames | ok |
| snd | Sounds | 1301 | fireball hit 8/22 old | format 1 · 22050 Hz · 9,968 frames | ok |
| snd | Sounds | 1980 | pause.snd old | format 1 · 11025 Hz · 17,792 frames | ok |
| snd | Sounds | 4050 | splash1old | format 1 · 22050 Hz · 13,918 frames | ok |
| snd | Sounds | 4051 | splash1newold | format 1 · 22050 Hz · 27,648 frames | ok |
| snd | Sounds | 4052 | splash1new2 | format 1 · 22050 Hz · 32,495 frames | ok |
| snd | Sounds | 4060 | splash2 old | format 1 · 22050 Hz · 10,064 frames | ok |
| snd | Sounds | 4510 | majorbonus old | format 1 · 22050 Hz · 56,192 frames | ok |
| snd | Sounds | 4701 | generic splat | format 1 · 22050 Hz · 6,604 frames | ok |
| snd | Sounds | 4703 | bottle break | format 1 · 22050 Hz · 11,072 frames | ok |
| snd | Sounds | 4704 | buttondown1 | format 1 · 11025 Hz · 2,492 frames | ok |
| snd | Sounds | 4705 | buttonup1 | format 1 · 11025 Hz · 1,576 frames | ok |
| snd | Sounds | 4706 | buttondown2 | format 1 · 11025 Hz · 728 frames | ok |
| snd | Sounds | 4707 | buttonup2 | format 1 · 11025 Hz · 1,199 frames | ok |
| snd | Sounds | 4801 | switch item | format 1 · 22050 Hz · 2,392 frames | ok |
| snd | Sounds | 4803 | Interface/Mouse Down | format 1 · 22050 Hz · 568 frames | ok |
| snd | Sounds | 4804 | Interface/Mouse Up | format 1 · 22050 Hz · 515 frames | ok |
| snd | Sounds | 8030 | fillerup old | format 1 · 22050 Hz · 22,912 frames | ok |
| music | Ferazel's Wand Music | 01 | — | AIFC ima4 stereo 22050 Hz · packets 28,463 · frames 1,821,632 | ok |
| music | Ferazel's Wand Music | 02 | — | AIFC ima4 stereo 22050 Hz · packets 26,932 · frames 1,723,648 | ok |
| music | Ferazel's Wand Music | 03 | — | AIFC ima4 stereo 22050 Hz · packets 24,274 · frames 1,553,536 | ok |
| music | Ferazel's Wand Music | 04 | — | AIFC ima4 stereo 22050 Hz · packets 20,608 · frames 1,318,912 | ok |
| music | Ferazel's Wand Music | 05 | — | AIFC ima4 stereo 22050 Hz · packets 30,288 · frames 1,938,432 | ok |
| music | Ferazel's Wand Music | 06 | — | AIFC ima4 stereo 22050 Hz · packets 24,783 · frames 1,586,112 | ok |
| music | Ferazel's Wand Music | 07 | — | AIFC ima4 stereo 22050 Hz · packets 24,766 · frames 1,585,024 | ok |
| music | Ferazel's Wand Music | 08 | — | AIFC ima4 stereo 22050 Hz · packets 22,716 · frames 1,453,824 | ok |
| music | Ferazel's Wand Music | 09 | — | AIFC ima4 stereo 22050 Hz · packets 48,512 · frames 3,104,768 | ok |
| music | Ferazel's Wand Music | 10 | — | AIFC ima4 stereo 22050 Hz · packets 23,632 · frames 1,512,448 | ok |
| music | Ferazel's Wand Music | 11 | — | AIFC ima4 stereo 22050 Hz · packets 22,102 · frames 1,414,528 | ok |
| music | Ferazel's Wand Music | 12 | — | AIFC ima4 stereo 22050 Hz · packets 21,046 · frames 1,346,944 | ok |
| music | Ferazel's Wand Music | 13 | — | AIFC ima4 stereo 22050 Hz · packets 30,722 · frames 1,966,208 | ok |
| music | Ferazel's Wand Music | 14 | — | AIFC ima4 stereo 22050 Hz · packets 22,054 · frames 1,411,456 | ok |
| music | Ferazel's Wand Music | 15 | — | AIFC ima4 stereo 22050 Hz · packets 17,734 · frames 1,134,976 | ok |
| music | Ferazel's Wand Music | 16 | — | AIFC ima4 stereo 22050 Hz · packets 22,892 · frames 1,465,088 | ok |
| music | Ferazel's Wand Music | 17 | — | AIFC ima4 stereo 22050 Hz · packets 21,606 · frames 1,382,784 | ok |
| music | Ferazel's Wand Music | 18 | — | AIFC ima4 stereo 22050 Hz · packets 31,654 · frames 2,025,856 | ok |
| music | Ferazel's Wand Music | 19 | — | AIFC ima4 stereo 22050 Hz · packets 22,576 · frames 1,444,864 | ok |
| music | Ferazel's Wand Music | 20 | — | AIFC ima4 stereo 22050 Hz · packets 24,809 · frames 1,587,776 | ok |
| music | Ferazel's Wand Music | 22 | — | AIFC ima4 stereo 22050 Hz · packets 26,480 · frames 1,694,720 | ok |
| music | Ferazel's Wand Music | 23 | — | AIFC ima4 stereo 22050 Hz · packets 22,448 · frames 1,436,672 | ok |
| music | Ferazel's Wand Music | 24 | — | AIFC ima4 stereo 22050 Hz · packets 32,384 · frames 2,072,576 | ok |
| music | Ferazel's Wand Music | 25 | — | AIFC ima4 stereo 22050 Hz · packets 19,206 · frames 1,229,184 | ok |
| music | Ferazel's Wand Music | 26 | — | AIFC ima4 stereo 22050 Hz · packets 23,168 · frames 1,482,752 | ok |
| music | Ferazel's Wand Music | 28 | — | AIFC ima4 stereo 22050 Hz · packets 20,968 · frames 1,341,952 | ok |
| music | Ferazel's Wand Music | 29 | — | AIFC ima4 stereo 22050 Hz · packets 19,272 · frames 1,233,408 | ok |
| music | Ferazel's Wand Music | 30 | — | AIFC ima4 stereo 22050 Hz · packets 17,956 · frames 1,149,184 | ok |
| Mlvl | World Data | 1 | A Scent Of Peril | 200×50 · active 162 · CLUT 201/202 | ok |
| Mlvl | World Data | 2 | Central Caverns | 200×50 · active 212 · CLUT 201/202 | ok |
| Mlvl | World Data | 3 | Western Reaches | 350×50 · active 216 · CLUT 209/210 | ok |
| Mlvl | World Data | 4 | Eastern Reaches | 350×50 · active 250 · CLUT 209/210 | ok |
| Mlvl | World Data | 5 | Manditraki Warrior | 64×14 · active 32 · CLUT 235/236 | ok |
| Mlvl | World Data | 10 | Unemployed In Greenland | 360×60 · active 312 · CLUT 213/214 | ok |
| Mlvl | World Data | 11 | River of Fears | 512×32 · active 397 · CLUT 223/224 | ok |
| Mlvl | World Data | 15 | Storm Valley | 400×60 · active 183 · CLUT 213/214 | ok |
| Mlvl | World Data | 18 | Goblin Chief | 64×32 · active 34 · CLUT 223/224 | ok |
| Mlvl | World Data | 20 | Hangnabit | 600×32 · active 333 · CLUT 211/212 | ok |
| Mlvl | World Data | 21 | Obfuscation & Edification | 350×65 · active 325 · CLUT 211/212 | ok |
| Mlvl | World Data | 22 | The Labyrinth | 256×128 · active 510 · CLUT 245/246 | ok |
| Mlvl | World Data | 25 | Manditraki Wizard | 64×32 · active 24 · CLUT 237/238 | ok |
| Mlvl | World Data | 30 | Flash Freeze | 500×32 · active 323 · CLUT 215/216 | ok |
| Mlvl | World Data | 31 | Iceconoclasm | 360×60 · active 319 · CLUT 217/218 | ok |
| Mlvl | World Data | 40 | Parched Earth | 512×60 · active 234 · CLUT 227/228 | ok |
| Mlvl | World Data | 45 | The Dig | 48×256 · active 270 · CLUT 227/228 | ok |
| Mlvl | World Data | 50 | Fire In The Hole | 360×60 · active 404 · CLUT 219/220 | ok |
| Mlvl | World Data | 51 | If You Can’t Stand The Heat… | 300×60 · active 326 · CLUT 219/220 | ok |
| Mlvl | World Data | 52 | Out of the Frying Pan | 20×512 · active 291 · CLUT 221/222 | ok |
| Mlvl | World Data | 55 | Fire Guardians | 64×14 · active 26 · CLUT 221/222 | ok |
| Mlvl | World Data | 62 | Ends of the Earth | 360×60 · active 312 · CLUT 239/240 | ok |
| Mlvl | World Data | 67 | Xichra’s Lair | 28×19 · active 13 · CLUT 247/248 | ok |
| Mlvl | World Data | 70 | Purple Haze | 128×60 · active 133 · CLUT 241/242 | ok |
| Mcnv | World Data | 200 | Rojinko Conv | lines 20 · text 19 · portrait 14 | ok |
| Mcnv | World Data | 201 | Geroditus conv 1 | lines 20 · text 16 · portrait 16 | ok |
| Mcnv | World Data | 202 | Andrew | lines 20 · text 8 · portrait 8 | ok |
| Mcnv | World Data | 203 | Sernis magic crystal 1 | lines 20 · text 5 · portrait 6 | ok |
| Mcnv | World Data | 204 | Unfriendly Fellow frsd Conv | lines 20 · text 15 · portrait 12 | ok |
| Mcnv | World Data | 205 | Wounded Habnabit Health Potion conv | lines 20 · text 15 · portrait 15 | ok |
| Mcnv | World Data | 206 | Nimbo conv | lines 20 · text 16 · portrait 14 | ok |
| Mcnv | World Data | 207 | Elber Ice Merchant Conv | lines 20 · text 15 · portrait 12 | ok |
| Mcnv | World Data | 208 | Korta conv | lines 20 · text 10 · portrait 9 | ok |
| Mcnv | World Data | 209 | Hooded Figure | lines 20 · text 7 · portrait 6 | ok |
| Mcnv | World Data | 210 | Babbling conv | lines 20 · text 4 · portrait 4 | ok |
| Mcnv | World Data | 211 | Cedric Ice Merchant Conv | lines 20 · text 15 · portrait 14 | ok |
| Mcnv | World Data | 212 | Jason conv | lines 20 · text 8 · portrait 8 | ok |
| Mcnv | World Data | 213 | Eric Conv | lines 20 · text 9 · portrait 9 | ok |
| Mcnv | World Data | 214 | AH conv | lines 20 · text 2 · portrait 2 | ok |
| Mcnv | World Data | 220 | Dimbo saved | lines 20 · text 1 · portrait 1 | ok |
| Mcnv | World Data | 221 | Dimbo | lines 20 · text 6 · portrait 6 | ok |
| Mcnv | World Data | 250 | Xichra 1 | lines 20 · text 1 · portrait 1 | ok |
| Mcnv | World Data | 251 | Xichra 2 | lines 20 · text 1 · portrait 1 | ok |
| Mcnv | World Data | 252 | Xichra 3 | lines 20 · text 3 · portrait 3 | ok |
| Mcnv | World Data | 260 | Grave 1 | lines 20 · text 1 · portrait 1 | ok |
| Mcnv | World Data | 261 | Grave 2 | lines 20 · text 1 · portrait 1 | ok |
| Mcnv | World Data | 280 | Haze Plaque | lines 20 · text 2 · portrait 2 | ok |
| Mcnv | World Data | 281 | andrew plaque | lines 20 · text 2 · portrait 2 | ok |
| Mcnv | World Data | 282 | Eric plaque | lines 20 · text 2 · portrait 2 | ok |
| Mcnv | World Data | 283 | jason plaque | lines 20 · text 2 · portrait 2 | ok |
| Mcnv | World Data | 300 | Obfusc Character | lines 20 · text 7 · portrait 7 | ok |
| Mcnv | World Data | 400 | Statue spell warn guy | lines 20 · text 3 · portrait 3 | ok |
| Mcnv | World Data | 401 | Ben conv | lines 20 · text 2 · portrait 2 | ok |
| Mwld | World Data | 0 | Mascot World | Teraknorn · stamp 0x152be0ed · start level 1 | ok |
| Mmap | World Data | 200 | Map | nodes 24 | ok |
| STR# | app | 300 | Warning Strings | strings 6 | ok |
| STR# | app | 400 | Fatal Error Strings | strings 14 | ok |
| STR# | World Data | 500 | signs | strings 19 | ok |
| STR# | World Data | 1000 | level names | strings 99 | ok |

## 4. Color2Index: ruled vs exact-nearest per level CLUT

| clut | name | ruled ≠ exact | requests |
|---:|---|---:|---:|
| 202 | base + earthcav | 75,461 | 211,731 |
| 210 | EC2 + base | 77,037 | 211,731 |
| 212 | forest 2 + base | 73,640 | 211,731 |
| 214 | forest 1 new + base | 72,846 | 211,731 |
| 216 | Upper Ice Caverns + base | 78,302 | 211,731 |
| 218 | Lower Ice Caverns + base | 74,684 | 211,731 |
| 220 | Upper Fire Caverns + base | 71,105 | 211,731 |
| 222 | Upper Fire Caverns flame + base | 63,104 | 211,731 |
| 224 | newlake + base | 68,552 | 211,731 |
| 228 | Desert + base | 67,849 | 211,731 |
| 236 | Boss1abstract + base | 79,478 | 211,731 |
| 238 | RuinsBoss + base | 73,737 | 211,731 |
| 240 | Mountains2 + base | 78,219 | 211,731 |
| 242 | Purple abstract + base | 73,026 | 211,731 |
| 246 | Ruins1 + base | 77,463 | 211,731 |
| 248 | Throne Room + base | 73,643 | 211,731 |

color2index CLUT 202 ruled vs exact: tint 1168/3603 · water 397/1280 · redden 1885/6144 · ambient 1887/4096 · pairs 70124/196608 · total 75461/211731
color2index 16 level CLUTs: 1,178,146 of 3,387,696 requests differ

## 5. Phase-1 face conversion exposure (level 1, ruled vs exact-nearest)

| sheet | PICT | conversion clut | colours | exact in clut | ruled ≠ exact | pixels |
|---|---:|---:|---:|---:|---:|---:|
| FG | 200 | 201 | 239 | 30 | 44 | 5,400 |
| BG | 203 | 202 | 234 | 28 | 67 | 13,898 |
| pattern | 206 | 202 | 200 | 30 | 73 | 8,606 |
| PxBack | 207 | 201 | 52 | 52 | 0 | 0 |
| walk | 1020 | 200 | 51 | 6 | 5 | 1,333 |

faces level 1 ruled vs exact: FG 200 44/239 colours 5,400 px · BG 203 67/234 13,898 px · pattern 206 73/200 8,606 px · PxBack 207 0/52 · walk 1020 5/51 1,333 px
short sheet PICT 257 768×708 (cells 30..35, 60 rows)

## 6. Totals

Totals: items 1,108 decoded, failures 0
