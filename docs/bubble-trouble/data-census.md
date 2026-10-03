> Generated 2026-10-04 by `btx-census` (`BubbleTrouble/Core`) through HectorKit `4d3746d` (tag `v0.2.0`):
> `CIcon`, `PixelPattern`, `PICT.decodeAny` (raster · banded QuickTime · 0x0099 region · 0x8201 matte),
> `SndSound`. Everything below the rule is the tool's stdout, verbatim —
> `BTXCensusTests.testStdoutEqualsCommittedCensus` pins it byte for byte. Re-run from the repo root:
>
>     swift build --package-path BubbleTrouble/Core -c release
>     "$(swift build --package-path BubbleTrouble/Core -c release --show-bin-path)/btx-census" "$HECTORKIT_DATA_BTX"
>
> `HECTORKIT_DATA_BTX` = the Bubble Trouble X 1.1 UB `Contents/Resources` folder; the archive copy is
> `~/Developer/Ambrosia/Resources/ambrosia-extracted/Action-Adventure/Bubble Trouble X/BubbleTroubleX_1.1_UB/Bubble Trouble X.app/Contents/Resources`
> (game data never enters git). Plan: `docs/plans/2026-10-03-hectorkit-btx-decoders.md` Tasks 7 and 4c.
>
> **Read with the numbers:**
> 1. **The 9 masked PICTs decode via `PICT.decodeAny`.** 0x0099 PackBitsRgn (9001 9002 9012 9020: alpha 255
>    inside the region, 0 outside — 9001/9002's region is the whole frame, so opaque) and 0x8201 QuickTime
>    'rle ' matte (2910 7000 9030 9031 9077: alpha = the 8-bit matte sample) — kit plan Tasks 4a/4b. Both
>    masked paths are census-verified on ONE game (this one): no EV or Aki PICT carries either opcode (plan
>    delta 2), so the kit calls them verified on one game's data, not yet general.
> 2. **PICT 200 (32-bit, cmpCount 4) has an all-zero alpha plane** — 102,300 of 102,300 pixels A = 0
>    (re-checked in Python by unpacking the 0x009A rows: alpha-plane histogram `{0: 102300}`). The kit
>    carries the plane faithfully. [HIGH] for the bytes. Classic QuickDraw ignores the high (alpha) byte of a
>    32-bit pixel, so the original shows this splash opaque [MED — QuickDraw convention; Ben's eyes on the
>    splash close it]: a consumer must not composite PICT 200 by its alpha. (The plan's note 13 "real alpha"
>    means only that a fourth plane is stored.)
> 3. "Decodes to the census" is the machine claim; that any image *looks like the game* is Ben's to close.

---

# Bubble Trouble X 1.1 — data census

Every `cicn`, `ppat`, `PICT` and `snd ` in the five resource files, decoded through HectorKit
(`CIcon`, `PixelPattern`, `PICT`, `SndSound`). A summary line closes each section.

## 1. Files — resource types per file

| file | resources | types (map order) |
| --- | ---: | --- |
| `BT Levels.rsrc` | 119 | `LEVL` 50 · `MAZE` 50 · `PICT` 6 · `ppat` 7 · `vers` 2 · `FILM` 4 |
| `BT Sounds.rsrc` | 53 | `snd ` 51 · `vers` 2 |
| `BT Sprites.rsrc` | 662 | `TMPL` 2 · `SpIL` 1 · `cicn` 331 · `vers` 2 · `SpIc` 1 · `btSP` 325 |
| `BT Titles.rsrc` | 9 | `PICT` 7 · `vers` 2 |
| `Bubble Trouble X.rsrc` | 223 | `MENU` 10 · `DITL` 42 · `BNDL` 1 · `ics8` 7 · `ics4` 3 · `ics#` 9 · `ICN#` 3 · `icl8` 2 · `icl4` 2 · `FREF` 6 · `ALRT` 28 · `STR#` 27 · `STR ` 2 · `DARK` 2 · `MBAR` 1 · `DLOG` 11 · `PICT` 15 · `CURS` 8 · `cicn` 4 · `CNTL` 4 · `crsr` 1 · `ICON` 3 · `SPIN` 2 · `Bubb` 1 · `SCOR` 1 · `hfdr` 1 · `vers` 2 · `TMPL` 1 · `Rect` 7 · `IMAG` 1 · `carb` 1 · `snd ` 1 · `plst` 1 · `dlgx` 11 · `icns` 1 · `xmnu` 1 |

files 5 · resources 1066 (BT Levels.rsrc 119 · BT Sounds.rsrc 53 · BT Sprites.rsrc 662 · BT Titles.rsrc 9 · Bubble Trouble X.rsrc 223)

## 2. `cicn` — every colour icon through `CIcon(data:)`

opaque px = mask-on pixels (A = 255); RGB sum = Σ(R+G+B) over every pixel (RGB is 0 where masked);
blank = no opaque pixel.

| file | cicn | opaque px | RGB sum | blank |
| --- | ---: | ---: | ---: | ---: |
| `BT Sprites.rsrc` | 331 | 234,347 | 64,064,551 | 7 |
| `Bubble Trouble X.rsrc` | 4 | 2,340 | 914,039 | 0 |

Size × depth (all files):

| size | 1-bit | 2-bit | 4-bit | 8-bit | total |
| --- | ---: | ---: | ---: | ---: | ---: |
| 18×18 | 3 | — | — | — | 3 |
| 22×30 | — | — | 20 | — | 20 |
| 22×32 | — | — | 10 | — | 10 |
| 23×23 | 3 | — | — | — | 3 |
| 26×26 | — | — | 13 | 11 | 24 |
| 27×35 | — | — | 10 | — | 10 |
| 28×28 | — | — | 4 | — | 4 |
| 29×29 | 3 | — | — | — | 3 |
| 32×32 | — | — | 1 | 15 | 16 |
| 38×38 | — | — | — | 5 | 5 |
| 40×40 | 8 | 11 | 21 | 153 | 193 |
| 43×43 | 3 | — | — | — | 3 |
| 45×49 | — | — | 2 | — | 2 |
| 48×23 | — | — | 2 | 22 | 24 |
| 64×38 | — | — | 1 | 12 | 13 |
| 64×64 | — | — | — | 2 | 2 |

| file | id | name | size | depth | colours | opaque px | RGB sum |
| --- | ---: | --- | --- | ---: | ---: | ---: | ---: |
| `Bubble Trouble X.rsrc` | 128 | Game | 32×32 | 8 | 54 | 651 | 224,791 |
| `Bubble Trouble X.rsrc` | 1000 | Sound | 32×32 | 8 | 23 | 413 | 173,451 |
| `Bubble Trouble X.rsrc` | 1001 | Keys | 32×32 | 4 | 6 | 625 | 291,006 |
| `Bubble Trouble X.rsrc` | 1002 | Game | 32×32 | 8 | 54 | 651 | 224,791 |

cicn 335 (331 + 4) · depth {1: 20, 2: 11, 4: 84, 8: 220} · opaque px 236,687 · RGB sum 64,978,590 · blank 7: 25004 25108 25208 25308 25408 25504 27308

## 3. `ppat` — every pixel pattern through `PixelPattern(data:)`

colour table: device = ctFlags 0x8000 (looked up by position), value-indexed = ctFlags 0 (by entry
value); read from the resource's ColorTable for this label only. RGB sum = Σ(R+G+B), every pixel opaque.

| file | id | name | size | depth | colours | colour table | RGB sum | pixel (0,0) |
| --- | ---: | --- | --- | ---: | ---: | --- | ---: | --- |
| `BT Levels.rsrc` | 912 | Main Menu Pattern | 256×256 | 8 | 256 | device | 5,703,279 | (0, 0, 17) |
| `BT Levels.rsrc` | 13000 | Waves Dark | 256×256 | 8 | 256 | device | 12,290,014 | (0, 0, 221) |
| `BT Levels.rsrc` | 13001 | Blue Coral | 256×256 | 8 | 256 | device | 11,721,636 | (0, 51, 153) |
| `BT Levels.rsrc` | 13002 | Squid Monsters | 256×256 | 8 | 256 | device | 17,298,231 | (153, 102, 102) |
| `BT Levels.rsrc` | 13003 | Dead Sea | 256×256 | 8 | 256 | device | 15,543,355 | (0, 102, 255) |
| `BT Levels.rsrc` | 13004 | Red & Green Plankton | 256×256 | 8 | 256 | device | 10,237,077 | (204, 102, 0) |
| `BT Levels.rsrc` | 13005 | Blue Bubbles | 256×256 | 8 | 256 | device | 17,108,171 | (0, 51, 255) |

ppat 7 · 256×256 8-bit · device colour table 7 · RGB sum 89,901,763

## 4. `PICT` — every picture through HectorKit

path (every picture through `PICT.decodeAny(data:)`): raw = `PICT(data:)`; quicktime = banded 0x8200 JPEG
via `PICT.decodeQuickTime(data:)`; region = 0x0099 PackBitsRgn, alpha 255 inside the region and 0 outside;
matte = 0x8201 QuickTime 'rle ' matte, alpha = the 8-bit matte sample. A decode throw is a failure.
frame = picFrame; a decode must match it. alpha: opaque = every A 255, else counts of A 255 / 0 / partial.

| file | id | name | frame | path | alpha |
| --- | ---: | --- | --- | --- | --- |
| `BT Levels.rsrc` | 13000 | — | 640×480 | quicktime · 3 bands | opaque |
| `BT Levels.rsrc` | 13001 | — | 640×480 | quicktime · 3 bands | opaque |
| `BT Levels.rsrc` | 13002 | — | 640×480 | quicktime · 3 bands | opaque |
| `BT Levels.rsrc` | 13003 | — | 640×480 | quicktime · 3 bands | opaque |
| `BT Levels.rsrc` | 13004 | — | 640×480 | quicktime · 3 bands | opaque |
| `BT Levels.rsrc` | 13005 | — | 640×480 | quicktime · 3 bands | opaque |
| `BT Titles.rsrc` | 9001 | Letters | 546×46 | region | opaque |
| `BT Titles.rsrc` | 9002 | Letters Highlighted | 546×46 | region | opaque |
| `BT Titles.rsrc` | 9010 | Small title | 239×150 | raw | opaque |
| `BT Titles.rsrc` | 9011 | Title | 640×480 | raw | opaque |
| `BT Titles.rsrc` | 9020 | High Scores | 222×37 | region | α255 5,930 · α0 2,284 · partial 0 |
| `BT Titles.rsrc` | 9099 | Register please | 640×480 | raw | opaque |
| `BT Titles.rsrc` | 9100 | — | 300×300 | raw | opaque |
| `Bubble Trouble X.rsrc` | 200 | Large Ambrosia logo | 300×341 | raw | α255 0 · α0 102,300 · partial 0 |
| `Bubble Trouble X.rsrc` | 900 | -Ambrosia Logo | 99×151 | raw | opaque |
| `Bubble Trouble X.rsrc` | 912 | — | 640×480 | raw | opaque |
| `Bubble Trouble X.rsrc` | 913 | — | 640×480 | raw | opaque |
| `Bubble Trouble X.rsrc` | 998 | Keyboard PICT | 32×32 | raw | opaque |
| `Bubble Trouble X.rsrc` | 999 | Icon PICT | 32×32 | raw | opaque |
| `Bubble Trouble X.rsrc` | 2910 | — | 309×328 | matte | α255 18,659 · α0 69,858 · partial 12,835 |
| `Bubble Trouble X.rsrc` | 7000 | — | 92×47 | matte | α255 3,136 · α0 800 · partial 388 |
| `Bubble Trouble X.rsrc` | 8001 | And so it seems | 160×234 | raw | opaque |
| `Bubble Trouble X.rsrc` | 9012 | By Alex Metcalf & David Wareing | 182×14 | region | α255 1,927 · α0 621 · partial 0 |
| `Bubble Trouble X.rsrc` | 9030 | Pause 1 | 330×16 | matte | α255 3,074 · α0 1,228 · partial 978 |
| `Bubble Trouble X.rsrc` | 9031 | Pause 2 | 260×16 | matte | α255 2,503 · α0 836 · partial 821 |
| `Bubble Trouble X.rsrc` | 9077 | Custom levels | 47×23 | matte | α255 433 · α0 231 · partial 417 |
| `Bubble Trouble X.rsrc` | 29401 | David | 148×172 | quicktime · 1 band | opaque |
| `Bubble Trouble X.rsrc` | 29402 | Alex | 148×172 | quicktime · 1 band | opaque |

PICT 28 · raw 11 · quicktime 8 · region 4 (9001 9002 9012 9020) · matte 5 (2910 7000 9030 9031 9077)

## 5. `snd ` — every sound through `SndSound(data:)`

encode 0x00 = pcm8 (mono 8-bit offset PCM); 0xFE = compressed (codec named). rate = the header's
Fixed rate >> 16 (whole Hz). length: frames for pcm8, packets (header numFrames) for compressed.

| file | id | name | format | encode | rate | channels | length |
| --- | ---: | --- | ---: | --- | ---: | ---: | ---: |
| `BT Sounds.rsrc` | 9000 | Squish | 1 | 0x00 pcm8 | 22050 Hz | 1 | 7,974 frames |
| `BT Sounds.rsrc` | 9001 | Click | 1 | 0x00 pcm8 | 22050 Hz | 1 | 2,267 frames |
| `BT Sounds.rsrc` | 9002 | Get Ready! [New Game] | 1 | 0x00 pcm8 | 22050 Hz | 1 | 47,520 frames |
| `BT Sounds.rsrc` | 9003 | Game Over! | 1 | 0x00 pcm8 | 22050 Hz | 1 | 58,921 frames |
| `BT Sounds.rsrc` | 9004 | Bop | 1 | 0x00 pcm8 | 22050 Hz | 1 | 3,895 frames |
| `BT Sounds.rsrc` | 9005 | Push - Successful | 1 | 0x00 pcm8 | 22050 Hz | 1 | 6,691 frames |
| `BT Sounds.rsrc` | 9006 | Pop | 1 | 0x00 pcm8 | 22050 Hz | 1 | 2,158 frames |
| `BT Sounds.rsrc` | 9007 | Push - Failed | 1 | 0x00 pcm8 | 22050 Hz | 1 | 7,631 frames |
| `BT Sounds.rsrc` | 9008 | Hahohaho! [Hero Start] | 1 | 0x00 pcm8 | 22050 Hz | 1 | 14,062 frames |
| `BT Sounds.rsrc` | 9009 | Minor Jewel Join | 1 | 0x00 pcm8 | 22050 Hz | 1 | 13,461 frames |
| `BT Sounds.rsrc` | 9010 | Oooer! [Hero Caught] | 1 | 0x00 pcm8 | 22050 Hz | 1 | 8,375 frames |
| `BT Sounds.rsrc` | 9011 | Zoiks! [Hero squished] | 1 | 0x00 pcm8 | 22050 Hz | 1 | 6,334 frames |
| `BT Sounds.rsrc` | 9012 | Warble | 1 | 0x00 pcm8 | 22050 Hz | 1 | 13,114 frames |
| `BT Sounds.rsrc` | 9013 | Extra Life | 1 | 0x00 pcm8 | 22050 Hz | 1 | 25,827 frames |
| `BT Sounds.rsrc` | 9014 | Balloon Launch | 1 | 0x00 pcm8 | 22050 Hz | 1 | 683 frames |
| `BT Sounds.rsrc` | 9015 | Enemy Ballooned | 1 | 0x00 pcm8 | 22050 Hz | 1 | 12,120 frames |
| `BT Sounds.rsrc` | 9016 | Enemy Hatch | 1 | 0x00 pcm8 | 22050 Hz | 1 | 4,439 frames |
| `BT Sounds.rsrc` | 9017 | Bloop | 1 | 0x00 pcm8 | 22050 Hz | 1 | 2,811 frames |
| `BT Sounds.rsrc` | 9018 | Boing! | 1 | 0x00 pcm8 | 22050 Hz | 1 | 4,562 frames |
| `BT Sounds.rsrc` | 9019 | Harp - Bonus Appears | 1 | 0x00 pcm8 | 22050 Hz | 1 | 17,782 frames |
| `BT Sounds.rsrc` | 9020 | Bounce | 1 | 0x00 pcm8 | 22050 Hz | 1 | 8,176 frames |
| `BT Sounds.rsrc` | 9021 | Bonus Timer Warning | 1 | 0x00 pcm8 | 22050 Hz | 1 | 1,962 frames |
| `BT Sounds.rsrc` | 9022 | Stretch Bounce | 1 | 0x00 pcm8 | 22050 Hz | 1 | 9,116 frames |
| `BT Sounds.rsrc` | 9023 | No Bonus Points | 1 | 0x00 pcm8 | 22050 Hz | 1 | 15,453 frames |
| `BT Sounds.rsrc` | 9024 | Ignite Dynamite | 1 | 0x00 pcm8 | 22050 Hz | 1 | 10,052 frames |
| `BT Sounds.rsrc` | 9025 | Dull Explosion | 1 | 0x00 pcm8 | 22050 Hz | 1 | 18,217 frames |
| `BT Sounds.rsrc` | 9026 | Get Bonus | 1 | 0x00 pcm8 | 22050 Hz | 1 | 20,050 frames |
| `BT Sounds.rsrc` | 9027 | Bubbles | 1 | 0x00 pcm8 | 22050 Hz | 1 | 28,783 frames |
| `BT Sounds.rsrc` | 9028 | Short Bubbles | 1 | 0x00 pcm8 | 22050 Hz | 1 | 8,232 frames |
| `BT Sounds.rsrc` | 9029 | More Bubbles | 1 | 0x00 pcm8 | 22050 Hz | 1 | 18,028 frames |
| `BT Sounds.rsrc` | 9030 | Hurry Up! | 1 | 0x00 pcm8 | 22050 Hz | 1 | 17,179 frames |
| `BT Sounds.rsrc` | 9031 | Invisibility Bonus | 1 | 0x00 pcm8 | 22050 Hz | 1 | 10,096 frames |
| `BT Sounds.rsrc` | 9032 | Bonus Multiplier Flash | 1 | 0x00 pcm8 | 22050 Hz | 1 | 3,616 frames |
| `BT Sounds.rsrc` | 9033 | All Jewels Joined | 1 | 0x00 pcm8 | 22050 Hz | 1 | 63,032 frames |
| `BT Sounds.rsrc` | 9034 | Hero Death Groan | 1 | 0x00 pcm8 | 22050 Hz | 1 | 30,942 frames |
| `BT Sounds.rsrc` | 9035 | End of Level | 1 | 0x00 pcm8 | 22050 Hz | 1 | 33,924 frames |
| `BT Sounds.rsrc` | 9036 | AllRightyThen! | 1 | 0x00 pcm8 | 22050 Hz | 1 | 17,123 frames |
| `BT Sounds.rsrc` | 9037 | Ayeeee [Hero Scream] | 1 | 0x00 pcm8 | 22050 Hz | 1 | 17,462 frames |
| `BT Sounds.rsrc` | 9038 | Eat Seaweed Fish Breath! | 1 | 0x00 pcm8 | 22050 Hz | 1 | 19,677 frames |
| `BT Sounds.rsrc` | 9039 | Heyahoo [Hero] | 1 | 0x00 pcm8 | 22050 Hz | 1 | 8,950 frames |
| `BT Sounds.rsrc` | 9040 | Hooley Dooleys | 1 | 0x00 pcm8 | 22050 Hz | 1 | 12,371 frames |
| `BT Sounds.rsrc` | 9041 | Oh My [Hero] | 1 | 0x00 pcm8 | 22050 Hz | 1 | 12,652 frames |
| `BT Sounds.rsrc` | 9042 | Oh No [Hero] | 1 | 0x00 pcm8 | 22050 Hz | 1 | 16,094 frames |
| `BT Sounds.rsrc` | 9043 | Oooch [Hero] | 1 | 0x00 pcm8 | 22050 Hz | 1 | 8,359 frames |
| `BT Sounds.rsrc` | 9044 | Shazam [Hero] | 1 | 0x00 pcm8 | 22050 Hz | 1 | 20,712 frames |
| `BT Sounds.rsrc` | 9045 | Yeow [Hero] | 1 | 0x00 pcm8 | 22050 Hz | 1 | 9,390 frames |
| `BT Sounds.rsrc` | 9046 | Non the dog | 1 | 0x00 pcm8 | 11127 Hz | 1 | 3,664 frames |
| `BT Sounds.rsrc` | 11001 | Level set 1 music.1 | 1 | 0xFE ima4 | 22254 Hz | 2 | 24,032 packets |
| `BT Sounds.rsrc` | 11002 | Level set 2 music.1 | 1 | 0xFE ima4 | 22254 Hz | 2 | 19,168 packets |
| `BT Sounds.rsrc` | 11003 | Level set 3 music.1 | 1 | 0xFE ima4 | 22254 Hz | 2 | 21,924 packets |
| `BT Sounds.rsrc` | 11004 | Level set 4 music.1 | 1 | 0xFE ima4 | 22254 Hz | 2 | 26,064 packets |
| `Bubble Trouble X.rsrc` | 9047 | Squeak squeak | 1 | 0x00 pcm8 | 22254 Hz | 1 | 11,498 frames |

snd 52 · pcm8 48 · ima4 4 (stereo) · 22050 Hz 46 · 22254 Hz 5 · 11127 Hz 1

## Totals

Totals: cicn 335 (331 + 4), ppat 7, PICT 28 (raw 11 · quicktime 8 · region 4 · matte 5), snd 52 (pcm8 48 · ima4 4), failures 0
