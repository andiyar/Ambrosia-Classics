# Aki — data census (Phase 0)

> Generated 2026-10-03 by `aki-census` (`Aki/Core`) through HectorKit `54dc37d` (README-only
> commit on top of the Task 6 code `1a342ef`; decoder identical). Everything below the
> rule is the tool's stdout, verbatim. Re-run from the repo root:
>
>     swift build --package-path Aki/Core -c release
>     "$(swift build --package-path Aki/Core -c release --show-bin-path)/aki-census" \
>         "$PWD/Resources/Aki/1.1.0.app/Contents/Resources" "$PWD/Resources/Aki/1.2.0.app/Contents/Resources"
>
> `Resources/Aki/*.app` are git-ignored symlinks (docs/DECISIONS.md D1, written in Phase-0 Task 8) to the archive copies:
> 1.1.0 → `~/Developer/Ambrosia/Aki/Aki - Mahjong Solitaire/Aki - Mahjong Solitaire.app`;
> 1.2.0 → `~/Developer/Ambrosia/Resources/ambrosia-extracted/Action-Adventure/Aki - Mahjong Solitaire/Aki 1.2 UB/Aki.app`.

## Spec-vs-data deltas (design-2026-10-03 §4/§5)

1. **71 QuickTime-JPEG PICTs + 11 raw, not 70 + 12.** The raw ones are DirectBitsRect: 7 × 16-bit
   (128, 129, 131, 133, 134, 168, 314) and 4 × 32-bit (135, 5591, 8715, 23098); PICT 135 (2358×68) is
   32-bit **cmpCount 4** — a real alpha plane ("raw32 argb" below), which the decoder carries into the
   RGBA's A channel (a fact for Phase 1's compositing).
2. **0 `'snd '` resources.** The 1.1.0 resource file holds CHNK, STR, PICT, pnot, icns, 8BIM, TEXT, ANPA
   only; every sound is a loose AIFF/MP3 (section 5). HectorKit's `snd` decoder keeps EV's oracle.
3. **The QuickTime PICTs are banded.** Each is `0x0011 · 0x0C00 · 0x00A1 LongComment (kind 498) · 0x0001
   Clip · N × [0x8200 JPEG band · 0x0098 1-bit "decompressor required" BitMap] · 0x00FF`, N ∈ {1, 2, 4, 6}
   (45 / 5 / 20 / 1 PICTs); bands are full-width strips at their matrix ty that tile the frame exactly.
   HectorKit composites them (`PICT.decodeQuickTime`, HectorKit DECISIONS D2) and skips the placeholders.
4. **Three 1.1-vs-1.2 similarity rows sit above the 6.0 threshold in section 3 and are NOT decoder
   defects** (reviewer rendered all three, 2026-10-03): 155 vs `welcome.png` (15.30) and 313 vs
   `buyaki.png` (16.53) are wording changes between versions; 160 vs `paper.png` (122.99) is a 1.1-only
   splash with no 1.2 counterpart (`paper.png` pairs with 315 at 0.07). Band-order mistakes cost ≥ 10,
   which is why the threshold line exists; these rows are version deltas for the RE bank, not Phase 0.

---

## 1. Aki 1.1.0 resource file — `Aki - Mahjong Solitaire.rsrc`

| type | count |
| --- | ---: |
| `CHNK` | 1 |
| `STR ` | 4 |
| `PICT` | 82 |
| `pnot` | 1 |
| `icns` | 1 |
| `8BIM` | 33 |
| `TEXT` | 1 |
| `ANPA` | 1 |
| **total** | **124** |

The 1.2.0 folder has no `.rsrc` file.

## 2. PICT census (1.1.0) — every PICT through HectorKit

`kind`: raw16 / raw32 = DirectBitsRect via `PICT(data:)` ("argb" = cmpCount 4, a real alpha
plane); quicktime = banded 0x8200 JPEG via `PICT.decodeQuickTime(data:)`.

| id | frame | kind | bands | decode |
| ---: | --- | --- | ---: | --- |
| 5591 | 128×4 | raw32 | — | ok |
| 135 | 2358×68 | raw32 argb | — | ok |
| 8715 | 2×128 | raw32 | — | ok |
| 131 | 39×2100 | raw16 | — | ok |
| 23098 | 14×128 | raw32 | — | ok |
| 132 | 237×2172 | quicktime | 4 | ok |
| 14242 | 128×80 | quicktime | 1 | ok |
| 314 | 240×150 | raw16 | — | ok |
| 12456 | 111×128 | quicktime | 1 | ok |
| 134 | 416×480 | raw16 | — | ok |
| 25064 | 29×128 | quicktime | 1 | ok |
| 130 | 392×1727 | quicktime | 6 | ok |
| 168 | 416×480 | raw16 | — | ok |
| 16331 | 128×96 | quicktime | 1 | ok |
| 140 | 800×600 | quicktime | 4 | ok |
| 2650 | 128×96 | quicktime | 1 | ok |
| 142 | 800×600 | quicktime | 4 | ok |
| 2495 | 128×96 | quicktime | 1 | ok |
| 151 | 800×600 | quicktime | 4 | ok |
| 18588 | 128×96 | quicktime | 1 | ok |
| 145 | 800×600 | quicktime | 4 | ok |
| 7406 | 128×96 | quicktime | 1 | ok |
| 149 | 800×600 | quicktime | 4 | ok |
| 8559 | 128×96 | quicktime | 1 | ok |
| 146 | 800×600 | quicktime | 4 | ok |
| 31902 | 128×96 | quicktime | 1 | ok |
| 144 | 800×600 | quicktime | 4 | ok |
| 17399 | 128×96 | quicktime | 1 | ok |
| 147 | 800×600 | quicktime | 4 | ok |
| 5164 | 128×96 | quicktime | 1 | ok |
| 150 | 800×600 | quicktime | 4 | ok |
| 18569 | 128×96 | quicktime | 1 | ok |
| 148 | 800×600 | quicktime | 4 | ok |
| 24276 | 128×96 | quicktime | 1 | ok |
| 141 | 800×600 | quicktime | 4 | ok |
| 21854 | 128×96 | quicktime | 1 | ok |
| 143 | 800×600 | quicktime | 4 | ok |
| 155 | 523×338 | quicktime | 2 | ok |
| 156 | 400×425 | quicktime | 2 | ok |
| 4945 | 112×128 | quicktime | 1 | ok |
| 199 | 440×503 | quicktime | 2 | ok |
| 313 | 800×600 | quicktime | 4 | ok |
| 160 | 420×338 | quicktime | 2 | ok |
| 164 | 800×600 | quicktime | 4 | ok |
| 129 | 53×1104 | raw16 | — | ok |
| 128 | 467×468 | raw16 | — | ok |
| 179 | 128×98 | quicktime | 1 | ok |
| 306 | 237×181 | quicktime | 1 | ok |
| 304 | 237×181 | quicktime | 1 | ok |
| 303 | 237×181 | quicktime | 1 | ok |
| 27067 | 128×98 | quicktime | 1 | ok |
| 301 | 237×181 | quicktime | 1 | ok |
| 302 | 237×181 | quicktime | 1 | ok |
| 308 | 237×181 | quicktime | 1 | ok |
| 300 | 237×181 | quicktime | 1 | ok |
| 311 | 237×181 | quicktime | 1 | ok |
| 310 | 237×181 | quicktime | 1 | ok |
| 24376 | 128×98 | quicktime | 1 | ok |
| 309 | 237×181 | quicktime | 1 | ok |
| 307 | 237×181 | quicktime | 1 | ok |
| 305 | 237×181 | quicktime | 1 | ok |
| 133 | 132×144 | raw16 | — | ok |
| 21338 | 128×103 | quicktime | 1 | ok |
| 315 | 420×338 | quicktime | 2 | ok |
| 29380 | 110×128 | quicktime | 1 | ok |
| 136 | 224×260 | quicktime | 1 | ok |
| 6413 | 128×98 | quicktime | 1 | ok |
| 403 | 237×181 | quicktime | 1 | ok |
| 400 | 237×181 | quicktime | 1 | ok |
| 22365 | 128×98 | quicktime | 1 | ok |
| 402 | 237×181 | quicktime | 1 | ok |
| 15277 | 128×98 | quicktime | 1 | ok |
| 404 | 237×181 | quicktime | 1 | ok |
| 32369 | 128×98 | quicktime | 1 | ok |
| 401 | 237×181 | quicktime | 1 | ok |
| 1069 | 128×96 | quicktime | 1 | ok |
| 202 | 800×600 | quicktime | 4 | ok |
| 201 | 800×600 | quicktime | 4 | ok |
| 28062 | 128×96 | quicktime | 1 | ok |
| 204 | 800×600 | quicktime | 4 | ok |
| 200 | 800×600 | quicktime | 4 | ok |
| 203 | 800×600 | quicktime | 4 | ok |

## 3. 1.1.0 QuickTime art ↔ 1.2.0 PNG

For each QuickTime PICT: the same-size 1.2.0 PNG with the smallest mean absolute RGB
difference (0–255 scale) from the decoded composite. A wrong band order/offset costs ≥ 10.

| PICT | frame | closest 1.2.0 PNG | mean abs diff |
| ---: | --- | --- | ---: |
| 132 | 237×2172 | `previews.png` | 4.98 |
| 14242 | 128×80 | — (no same-size PNG) | — |
| 12456 | 111×128 | — (no same-size PNG) | — |
| 25064 | 29×128 | — (no same-size PNG) | — |
| 130 | 392×1727 | `proverbs.png` | 2.53 |
| 16331 | 128×96 | — (no same-size PNG) | — |
| 140 | 800×600 | `background7.png` | 1.77 |
| 2650 | 128×96 | — (no same-size PNG) | — |
| 142 | 800×600 | `background9.png` | 3.43 |
| 2495 | 128×96 | — (no same-size PNG) | — |
| 151 | 800×600 | `background2.png` | 2.95 |
| 18588 | 128×96 | — (no same-size PNG) | — |
| 145 | 800×600 | `background11.png` | 2.76 |
| 7406 | 128×96 | — (no same-size PNG) | — |
| 149 | 800×600 | `background5.png` | 2.87 |
| 8559 | 128×96 | — (no same-size PNG) | — |
| 146 | 800×600 | `background10.png` | 1.71 |
| 31902 | 128×96 | — (no same-size PNG) | — |
| 144 | 800×600 | `background12.png` | 2.59 |
| 17399 | 128×96 | — (no same-size PNG) | — |
| 147 | 800×600 | `background8.png` | 1.64 |
| 5164 | 128×96 | — (no same-size PNG) | — |
| 150 | 800×600 | `background4.png` | 1.61 |
| 18569 | 128×96 | — (no same-size PNG) | — |
| 148 | 800×600 | `background6.png` | 1.75 |
| 24276 | 128×96 | — (no same-size PNG) | — |
| 141 | 800×600 | `background3.png` | 2.80 |
| 21854 | 128×96 | — (no same-size PNG) | — |
| 143 | 800×600 | `background1.png` | 2.91 |
| 155 | 523×338 | `welcome.png` | 15.30 |
| 156 | 400×425 | — (no same-size PNG) | — |
| 4945 | 112×128 | — (no same-size PNG) | — |
| 199 | 440×503 | `guide.png` | 2.60 |
| 313 | 800×600 | `buyaki.png` | 16.53 |
| 160 | 420×338 | `paper.png` | 122.99 |
| 164 | 800×600 | `map.png` | 3.02 |
| 179 | 128×98 | — (no same-size PNG) | — |
| 306 | 237×181 | `preview7.png` | 2.82 |
| 304 | 237×181 | `preview5.png` | 4.13 |
| 303 | 237×181 | `preview4.png` | 2.01 |
| 27067 | 128×98 | — (no same-size PNG) | — |
| 301 | 237×181 | `preview2.png` | 4.12 |
| 302 | 237×181 | `preview3.png` | 3.55 |
| 308 | 237×181 | `preview9.png` | 4.00 |
| 300 | 237×181 | `preview1.png` | 3.16 |
| 311 | 237×181 | `preview12.png` | 3.38 |
| 310 | 237×181 | `preview11.png` | 3.53 |
| 24376 | 128×98 | — (no same-size PNG) | — |
| 309 | 237×181 | `preview10.png` | 2.47 |
| 307 | 237×181 | `preview8.png` | 2.68 |
| 305 | 237×181 | `preview6.png` | 2.18 |
| 21338 | 128×103 | — (no same-size PNG) | — |
| 315 | 420×338 | `paper.png` | 0.07 |
| 29380 | 110×128 | — (no same-size PNG) | — |
| 136 | 224×260 | `layer_buttons.png` | 1.64 |
| 6413 | 128×98 | — (no same-size PNG) | — |
| 403 | 237×181 | `preview16.png` | 2.43 |
| 400 | 237×181 | `preview13.png` | 3.47 |
| 22365 | 128×98 | — (no same-size PNG) | — |
| 402 | 237×181 | `preview15.png` | 2.36 |
| 15277 | 128×98 | — (no same-size PNG) | — |
| 404 | 237×181 | `preview17.png` | 4.47 |
| 32369 | 128×98 | — (no same-size PNG) | — |
| 401 | 237×181 | `preview14.png` | 2.86 |
| 1069 | 128×96 | — (no same-size PNG) | — |
| 202 | 800×600 | `background15.png` | 1.86 |
| 201 | 800×600 | `background14.png` | 1.96 |
| 28062 | 128×96 | — (no same-size PNG) | — |
| 204 | 800×600 | `background17.png` | 2.96 |
| 200 | 800×600 | `background13.png` | 2.07 |
| 203 | 800×600 | `background16.png` | 1.71 |

## 4. PNG census (1.2.0) — every PNG through `CodecImage`

| file | size | decode |
| --- | --- | --- |
| `arrow.png` | 132×144 | ok |
| `background1.png` | 800×600 | ok |
| `background10.png` | 800×600 | ok |
| `background11.png` | 800×600 | ok |
| `background12.png` | 800×600 | ok |
| `background13.png` | 800×600 | ok |
| `background14.png` | 800×600 | ok |
| `background15.png` | 800×600 | ok |
| `background16.png` | 800×600 | ok |
| `background17.png` | 800×600 | ok |
| `background2.png` | 800×600 | ok |
| `background3.png` | 800×600 | ok |
| `background4.png` | 800×600 | ok |
| `background5.png` | 800×600 | ok |
| `background6.png` | 800×600 | ok |
| `background7.png` | 800×600 | ok |
| `background8.png` | 800×600 | ok |
| `background9.png` | 800×600 | ok |
| `buyaki.png` | 800×600 | ok |
| `guide.png` | 440×503 | ok |
| `layer_buttons.png` | 224×260 | ok |
| `map.png` | 800×600 | ok |
| `misc.png` | 467×468 | ok |
| `nopairs.png` | 416×480 | ok |
| `notavail.png` | 240×150 | ok |
| `paper.png` | 420×338 | ok |
| `pause.png` | 416×480 | ok |
| `plate.png` | 2358×68 | ok |
| `preview1.png` | 237×181 | ok |
| `preview10.png` | 237×181 | ok |
| `preview11.png` | 237×181 | ok |
| `preview12.png` | 237×181 | ok |
| `preview13.png` | 237×181 | ok |
| `preview14.png` | 237×181 | ok |
| `preview15.png` | 237×181 | ok |
| `preview16.png` | 237×181 | ok |
| `preview17.png` | 237×181 | ok |
| `preview2.png` | 237×181 | ok |
| `preview3.png` | 237×181 | ok |
| `preview4.png` | 237×181 | ok |
| `preview5.png` | 237×181 | ok |
| `preview6.png` | 237×181 | ok |
| `preview7.png` | 237×181 | ok |
| `preview8.png` | 237×181 | ok |
| `preview9.png` | 237×181 | ok |
| `previews.png` | 237×2172 | ok |
| `proverbs.png` | 392×1727 | ok |
| `tile_pictures.png` | 39×2100 | ok |
| `tiles.png` | 53×1104 | ok |
| `welcome.png` | 523×338 | ok |

## 5. Audio — every AIFF/MP3 through `AVAudioFile(forReading:)`

### 1.1.0

| file | format | sample rate | channels | length (frames) | processing format |
| --- | --- | ---: | ---: | ---: | --- |
| `Aki Theme 1.mp3` | .mp3 | 44100 | 2 | 7198848 | Float32 44100 Hz 2 ch non-interleaved |
| `Aki Theme 2.mp3` | .mp3 | 44100 | 2 | 7713792 | Float32 44100 Hz 2 ch non-interleaved |
| `Aki Theme 3.mp3` | .mp3 | 44100 | 2 | 1528704 | Float32 44100 Hz 2 ch non-interleaved |
| `GameOver.aiff` | ima4 | 44100 | 2 | 125632 | Float32 44100 Hz 2 ch non-interleaved |
| `LevelComplete.aiff` | ima4 | 44100 | 2 | 108544 | Float32 44100 Hz 2 ch non-interleaved |
| `LevelStart.aiff` | ima4 | 44100 | 2 | 163264 | Float32 44100 Hz 2 ch non-interleaved |
| `Preview.aiff` | ima4 | 44100 | 1 | 13056 | Float32 44100 Hz 1 ch non-interleaved |
| `Reshuffle.aiff` | ima4 | 44100 | 2 | 147072 | Float32 44100 Hz 2 ch non-interleaved |
| `TileMatch.aiff` | ima4 | 44100 | 1 | 7104 | Float32 44100 Hz 1 ch non-interleaved |
| `cancel.aiff` | ima4 | 44100 | 1 | 11008 | Float32 44100 Hz 1 ch non-interleaved |
| `chime.aiff` | ima4 | 44100 | 1 | 61120 | Float32 44100 Hz 1 ch non-interleaved |
| `tick.mp3` | .mp3 | 44100 | 1 | 2030976 | Float32 44100 Hz 1 ch non-interleaved |
| `tilehit.aiff` | ima4 | 44100 | 2 | 1152 | Float32 44100 Hz 2 ch non-interleaved |
| `unclick.aiff` | ima4 | 44100 | 2 | 1664 | Float32 44100 Hz 2 ch non-interleaved |

### 1.2.0

| file | format | sample rate | channels | length (frames) | processing format |
| --- | --- | ---: | ---: | ---: | --- |
| `Aki Theme 1.mp3` | .mp3 | 44100 | 2 | 7198848 | Float32 44100 Hz 2 ch non-interleaved |
| `Aki Theme 2.mp3` | .mp3 | 44100 | 2 | 7713792 | Float32 44100 Hz 2 ch non-interleaved |
| `Aki Theme 3.mp3` | .mp3 | 44100 | 2 | 1528704 | Float32 44100 Hz 2 ch non-interleaved |
| `GameOver.aiff` | ima4 | 44100 | 2 | 125632 | Float32 44100 Hz 2 ch non-interleaved |
| `LevelComplete.aiff` | ima4 | 44100 | 2 | 108544 | Float32 44100 Hz 2 ch non-interleaved |
| `LevelStart.aiff` | ima4 | 44100 | 2 | 163264 | Float32 44100 Hz 2 ch non-interleaved |
| `Preview.aiff` | ima4 | 44100 | 1 | 13056 | Float32 44100 Hz 1 ch non-interleaved |
| `Reshuffle.aiff` | ima4 | 44100 | 2 | 147072 | Float32 44100 Hz 2 ch non-interleaved |
| `TileMatch.aiff` | ima4 | 44100 | 1 | 7104 | Float32 44100 Hz 1 ch non-interleaved |
| `cancel.aiff` | ima4 | 44100 | 1 | 11008 | Float32 44100 Hz 1 ch non-interleaved |
| `chime.aiff` | ima4 | 44100 | 1 | 61120 | Float32 44100 Hz 1 ch non-interleaved |
| `tick.aiff` | ima4 | 44100 | 1 | 12736 | Float32 44100 Hz 1 ch non-interleaved |
| `tick.mp3` | .mp3 | 44100 | 1 | 2030976 | Float32 44100 Hz 1 ch non-interleaved |
| `tilehit.mp3` | .mp3 | 44100 | 2 | 2304 | Float32 44100 Hz 2 ch non-interleaved |
| `unclick.aiff` | ima4 | 44100 | 2 | 1664 | Float32 44100 Hz 2 ch non-interleaved |

## Totals

- PICT: 82 (raw 11, quicktime 71, failed 0)
- PNG: 50 (failed 0)
- Audio: 1.1.0 14 of 14 opened, 1.2.0 15 of 15 opened
- Failures: 0
