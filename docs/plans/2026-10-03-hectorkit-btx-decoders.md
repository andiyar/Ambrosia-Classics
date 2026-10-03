# Plan — HectorKit decoders for Bubble Trouble X (cicn · ppat · masked PICT · snd census) — 2026-10-03

> Status: LOCKED (orchestrator rulings R1–R4 applied 2026-10-03; Fable-grade review ACCEPT_WITH_FIXES, fixes applied)
> Shape: `~/Developer/Toolkits/fable-kit/plan-template.md`. Contracts, not code (Ben, 2026-10-03).
> Scene: design §6 item 4 ("Bubble Trouble X adds cicn/btSP/PPAT decoders to the kit"); bank
> `docs/bubble-trouble/data-formats.md` §4 §6 §7 §10 + `INDEX.md` "Resource census".
> Sibling plan (out of scope here, written concurrently): `docs/plans/2026-10-03-btx-core-and-film-harness.md`.
> Planner's Python probes (not committed): scratchpad `py/{cicn,ppat,pict,rle,rgn,snd,digest}.py` over
> `rsrc_census.py --extract` output. Every number below came from those runs on 2026-10-03.

## Verification model (read first)

- **Machine-verifiable (HectorKit):** `swift test` + `tools/check-zero-skip.sh` with the new
  `HECTORKIT_DATA_BTX` exported: zero skips, zero failures, executed total = previous floor **+ 28**
  (139 at HectorKit `8287ddb` → **167** if nothing else lands first; see the floor-delta rule, invariant 9).
  Floor ladder in execution order: T1 140 · T5 143 · T2 155 · T3 **160 = the floor at the tag** (Task 6) ·
  T4a 164 · T4b **167** (4a/4b are the last wave and may be deferred to the shell wave). Real-data tests pin the
  census numbers in Research notes 1–24 exactly (counts, histograms, opaque-pixel totals, RGB sums,
  alpha statistics, sound header fields).
- **Machine-verifiable (Classics):** `swift test` in `BubbleTrouble/Core` green with `HECTORKIT_DATA_BTX`
  set (0 skips), and `btx-census` exits 0 with the exact summary lines of Task 7, ending in the Totals line —
  at Task 7: **`Totals: cicn 335 (331 + 4), ppat 7, PICT 28 (raw 11 · quicktime 8 · deferred region 4 · deferred
  matte 5), snd 52 (pcm8 48 · ima4 4), failures 0`**; after Task 4c: the same with `region 4 · matte 5`.
  `docs/bubble-trouble/data-census.md` is that stdout verbatim under a header (and the test's golden).
- **Honesty gates (only Ben closes):** that a decoded sprite/pattern/title *looks like the game*. The
  machine proves "decodes to the census numbers"; the planner eyeballed four renders (cicn 25000, ppat
  13000, PICT 9077/7000 matte, PICT 9020 region) — that is a planner's look, not Ben's. Phrase every
  completion claim as "decodes to the census", never "renders correctly".
- **Known deltas to disclose up front:**
  1. `SndSound.sampleRateHz` truncates the Fixed rate: 22254.545 Hz → 22254, 11127.27 → 11127
     (≤ 0.0025 % pitch). Unchanged here (editing `SndSound.swift` is out of the new-files-only fence);
     deferred (Scope).
  2. The masked-PICT paths (0x0099 regions, 0x8201 mattes) are census-verified on ONE game (BTX): no EV or
     Aki PICT carries either opcode (planner walked every PICT in `data/nova/*`, `Nova Graphics 1.ndat`
     and Aki 1.1.0). Doc comments say "verified on one game's data, not yet called general" (the kit stays
     game-agnostic, invariant 1); HectorKit STATE (a doc, not a source file) may name the game
     (precedent: D2 banded QuickTime was Aki-only until now).
  3. Conversely the D2 banded-QuickTime walk gains its **second game**: BTX's 8 JPEG PICTs are the Aki shape
     (proved by the Classics census at Task 7; pinned in a kit test by Task 4b's `testEveryPICTDecodesToItsFrame`).
  4. Sprite *compositing* is not decided here: BTX's OS X plotter has a 10.4-only path that drops white
     pixels (Research note 25). The kit returns the honest cicn mask; the rule belongs to the sprite plan.

## Non-negotiable invariants

1. **Zero dependencies; nothing game-specific in a product target.** No type, symbol or doc comment in
   `Sources/HectorGraphics|HectorAudio|HectorResources` says "Bubble", "BTX", "Aki" or "EV". Game names live
   only in test files and `HectorTestSupport` locators (D3 ruling precedent).
2. **New files only in HectorKit**, except two minimal edits: `tools/check-zero-skip.sh` (one `export` +
   one `echo` + `FLOOR`) and, in Task 6 (and the as-built lines of Task 4b) only, `docs/STATE.md`,
   `docs/DECISIONS.md`, `CLAUDE.md`. Task 4b may edit `PICT+Masks.swift` / `BTXPICTCensusTests.swift`, which are
   this plan's own new files from Task 4a (precedent: Task 3 edits Task 2's test file).
   `Package.swift` is NOT touched (new files join existing targets automatically). `PICT.swift`,
   `PICT+QuickTime.swift`, `SndSound.swift`, `HectorData.swift` are NOT touched.
3. **Hostile-resource posture:** every read bounds-checked; malformed input throws, never traps, never
   allocates from an unchecked size (check `rowBytes × height` against `data.count` before allocating).
4. **Refuse what the census has not shown** (D2 style): an unsupported depth / pattern type / matte codec /
   region shape throws a named error rather than decoding approximately. Every refusal has a synthetic test.
5. **Colour-table rule = PICT.swift's rule** (Research note 7): `ctFlags & 0x8000` → entry *i* is index *i*;
   otherwise the entry's `value` field is the index. 16-bit channels → 8-bit by the HIGH byte (`>> 8`).
   ⚠️ LANDMINE: position-indexing a cicn table is wrong for 227 of 331 BTX sprites (230 of 335 with the app's 4):
   their pixel values exceed the colour count. Value lookup is confirmed correct — every one of those tables is
   entries 0…n−2 at values 0…n−2 plus a final black entry whose value is 2^d−1 (d = pixel depth).
6. ⚠️ LANDMINE — **padding is garbage, not zero.** Mask/bitmap bits past `width` (cicn 25000's mask padding
   holds stale art) and pixel bytes past `width` in a row (every BTX ppat: rowBytes 272, width 256, 16 junk
   bytes/row) must never be read as image. Iterate `0..<width`, address by the stored `rowBytes`.
7. ⚠️ LANDMINE — **use the stored rowBytes, never a computed one.** cicn mask/bitmap rowBytes are 4-byte
   aligned (w ≤ 32 → 4, w 38–64 → 8); pixel rowBytes too (w 26 at 8-bit → 28; w 40 at 2-bit → 12).
   rowBytes = stored value `& 0x3FFF` (bits 15/14 are flags; bit 15 MUST be set on a PixMap).
8. **Data-gated real-data tests** read through `HectorTestSupport` (`HectorData.btxVar` =
   `HECTORKIT_DATA_BTX`, the 1.1 UB `Contents/Resources`) and XCTSkip naming the variable when absent; the
   gate exports a default and fails on any skip (D3).
9. **Floor-delta rule (concurrency):** another session (Phase 1 / HectorShell) may add tests and edit
   `check-zero-skip.sh` in parallel (it moved the floor 119 → 139 on 2026-10-03). Each task's acceptance is
   "executed = (executed on the rebased base) + this task's new tests"; on a `FLOOR` merge conflict, re-run the
   gate on the rebased tree and set `FLOOR` to the executed total printed. Never hand-add numbers from two branches.
10. **Never build in the shared main checkout (R4).** HectorKit tasks run on a branch in a dedicated linked
    worktree (Task 0), never in `~/Developer/HectorKit`: that checkout is the target of the
    `.claude/worktrees/HectorKit` symlink every Classics worktree builds through, and the HectorShell session
    works there. (HectorShell is committed — `8226a7e`, `8287ddb` — and the checkout was clean on 2026-10-03.)
    The main checkout catches up only per R4.
11. **Commit per task with explicit paths** (`git add <paths>`, never `-A`), trailer
    `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; `git fetch origin && git rebase origin/main`
    immediately before each commit; merge the worktree branch to HectorKit main with `git push origin HEAD:main`
    (fast-forward only; on rejection rebase, re-gate, retry). Never `git stash`. After each push, R4's catch-up
    rule applies to the main checkout.
12. **Game data never enters git** (either repo). Tests print ids/names, never machine paths.

## Research notes the executor must know

All offsets big-endian, relative to the resource start unless stated. Probe files under the planner's
scratchpad; payloads from `python3 docs/bubble-trouble/tools/rsrc_census.py --extract <dir> <file>.rsrc`.

**cicn (`CIcon`, Inside Macintosh: Imaging With QuickDraw "CIcon")**

1. **Worked decode, `cicn 25000` (2,658 B, Hero idle 1, BT Sprites.rsrc).** IconPMap (PixMap, 50 B):
   `@0` baseAddr u32 = 0 · `@4` rowBytes u16 = **0x8028** (bit 15 set → PixMap; 0x28 = 40) · `@6` bounds
   = (0,0,40,40) · `@14` pmVersion 0 · `@16` packType 0 · `@18` packSize 0 · `@22/@26` h/vRes 0x00480000 ·
   `@30` pixelType 0 · `@32` pixelSize **8** · `@34` cmpCount 1 · `@36` cmpSize 8 · `@38` planeBytes 0 ·
   `@42` pmTable 0 · `@46` pmReserved 0. IconMask (BitMap, 14 B) `@50`: baseAddr 0, `@54` rowBytes **8**,
   `@56` bounds (0,0,40,40). IconBMap (BitMap) `@64`: baseAddr 0, `@68` rowBytes 8, `@70` bounds (0,0,40,40).
   `@78` iconData handle u32 = 0. **Data from `@82`:** mask `8×40 = 320` B (`@82`), 1-bit icon 320 B
   (`@402`), ColorTable `@722` (ctSeed 0, ctFlags 0x0000, ctSize 40 → 41 entries × 8 B = `@730..@1057`),
   pixels `40 × 40 = 1600` B `@1058..@2657` = end of resource (0 trailing bytes).
   Layout formula (all 339 BTX cicns + 45 EV, 0 trailing): `size = 82 + maskRB·maskH + bmapRB·bmapH + 8 +
   8·(ctSize+1) + (pixRB & 0x3FFF)·h`.
2. Entry 0 = (0xFFFF,0xFFFF,0xFFFF) white, value 0; masked-out pixels are index 0 in 321/331 sprites (the
   other 10 use 0 plus 1–2 stray indices) — irrelevant once the mask is applied, but every used index (in or
   out of the mask) IS present in the table (339/339).
3. Decoded 25000: 943 opaque px (1600 − 657 masked), RGB sum over all pixels 242,420 (RGB 0 where masked),
   first opaque pixel (x 11, y 2) = (136, 0, 0, 255); pixel (20,20) = index 4 = (204, 153, 51, 255).
4. **Mask padding holds junk**: rows of 25000's mask carry set bits in columns 40–63 (rowBytes 8 = 64 bits);
   only columns 0..<40 are mask. Same for the 1-bit icon.
5. The 1-bit icon (IconBMap) equals the mask in-bounds in 319/331 sprites; QuickDraw draws it only on 1-/2-bit
   screens. The decoder parses it for the layout and DROPS it (not exposed). BMap rowBytes is non-zero in every
   census cicn; per Apple a zero rowBytes means "no bitmap data" (synthetic test only).
6. **Census, all 339 BTX cicns** (identical header shape: bit-15 rowBytes, origin (0,0), packType 0,
   pixelType 0, cmpCount 1, cmpSize = pixelSize, pmVersion 0, ctFlags 0x0000, ctSeed 0, mask & bmap bounds =
   pixmap bounds, all handle fields 0, 0 trailing):
   - **BT Sprites.rsrc, 331:** size (w×h) → count {18×18: 3, 22×30: 20, 22×32: 10, 23×23: 3, 26×26: 24,
     27×35: 10, 28×28: 4, 29×29: 3, 32×32: 12, 38×38: 5, 40×40: 193, 43×43: 3, 45×49: 2, 48×23: 24,
     64×38: 13, 64×64: 2}; depth → count **{8: 217, 4: 83, 1: 20, 2: 11}**; depth×size {1: 18², 23², 29², 43²
     ×3 each, 40² ×8 · 2: 40² ×11 · 4: 22×30 ×20, 22×32 ×10, 26² ×13, 27×35 ×10, 28² ×4, 40² ×21, 45×49 ×2,
     48×23 ×2, 64×38 ×1 · 8: 26² ×11, 32² ×12, 38² ×5, 40² ×153, 48×23 ×22, 64×38 ×12, 64² ×2};
     colorCount 1…70; **opaque px total 234,347; RGB sum 64,064,551**; table values non-sequential in 227,
     and pixel values ≥ colorCount in exactly those 227 (230 of 335 with the app's 4) — each such table is entries
     0…n−2 at values 0…n−2 plus a final black entry at value 2^d−1 (re-probed 2026-10-03 at fix pass) → value
     indexing is the only consistent reading.
   - **7 all-transparent blanks** (mask all zero, 40×40 1-bit): 25004, 25108, 25208, 25308, 25408, 25504
     (exactly the six cicns with no btSP twin, bank §4) and 27308.
   - Depth examples: 1-bit 27307 (40×40, 2 colours, 33 opaque, RGB sum 10,098); 2-bit 27305 (40×40,
     4 colours, 214, 142,596); 4-bit 26601 (64×38, 14 colours, rowBytes 32, 417, 70,890).
   - **Bubble Trouble X.rsrc, 4** (all 32×32): 128 "Game" 8-bit 54 colours 651 opaque RGB 224,791 ·
     1000 "Sound" 8-bit 23 · 413 · 173,451 · 1001 "Keys" **4-bit** 6 · 625 · 291,006 · 1002 "Game" = 128's
     numbers. Total opaque 2,340, RGB 914,039.
   - (Not in the five files: `extras/BT Level Editor.rsrc` cicn 13001–13004, 32×32 8-bit — decoded fine.)
7. **Second game (EV Nova, `HECTORKIT_DATA_NOVA`)** — same shape, ctFlags 0, value-indexed:
   `Override Graphics` 29 cicn (ids 10000–20000) {16×16×1: 24, 16×16×2: 2, 32×16×4: 1, 32×32×4: 1,
   32×32×8: 1}, opaque 2,318, RGB 388,297 · `Override Data 2` 16 cicn (ids 1000–1015) all 4-bit
   {8²: 2, 16²: 2, 24²: 2, 32²: 4, 40²: 4, 48²: 2}, opaque 3,444, RGB 604,860. Depths across both games:
   1, 2, 4, 8 — all four are census-backed; 16/32-bit cicns appear nowhere (refuse).
8. Pixel unpacking for depth d ∈ {1,2,4,8}: MSB-first within each byte (QuickDraw pixel order, as
   PICT.swift's 4-bit branch: high nibble first). Row y starts at `pixOff + y·rowBytes`.

**ppat (`PixelPattern`, Inside Macintosh "PixPat", resource form: handles replaced by offsets)**

9. **Worked decode, `ppat 912` "Main Menu Pattern" (71,766 B, BT Levels.rsrc):** `@0` patType i16 = **1**
   (full-colour pixel pattern) · `@2` patMap u32 = **28** (offset of the PixMap) · `@6` patData u32 = **78**
   (offset of pixel data) · `@10` patXData 0x005CC564 (stale handle — ignore) · `@14` patXValid −1 ·
   `@16` patXMap 0x005CC550 (stale — ignore) · `@20` pat1Data 8 B = `AA55AA55AA55AA55` (1-bit fallback, not
   exposed). PixMap `@28`: baseAddr 0x00828380 (stale — ignore) · rowBytes **0x8110 → 272** · bounds
   (0,0,256,256) · pmVersion **1** · packType 0 · pixelSize 8 · cmpCount 1 · cmpSize 8 · `@28+42` pmTable =
   **69,710** (offset of the ColorTable) · pmReserved 0. Pixels `@78`, 272 × 256 = 69,632 B → end `@69,710` =
   pmTable exactly. ColorTable `@69,710`: ctSeed 8, **ctFlags 0x8000** (device-relative), ctSize 255 → 256
   entries; every `value` = 0x0800 (meaningless → positional); entry 0 white, entry 255 black; ends at
   71,766 = resource end.
10. **All 7 BTX ppats** (912, 13000–13005): identical shape (patType 1, offsets 28/78/69,710, 256×256 8-bit,
    rowBytes 272, pmVersion 1, ctFlags 0x8000, 256 entries). Columns 256–271 of every row are junk (planner
    render: coloured noise strip) — never read. RGB sums (opaque, A = 255 everywhere): 912 5,703,279 ·
    13000 12,290,014 · 13001 11,721,636 · 13002 17,298,231 · 13003 15,543,355 · 13004 10,237,077 ·
    13005 17,108,171. Pixel (0,0): 912 (0,0,17) · 13000 (0,0,221) · 13001 (0,51,153) · 13002 (153,102,102) ·
    13003 (0,102,255) · 13004 (204,102,0) · 13005 (0,51,255). 13000 (128,128) = (0,0,136); (255,255) = (0,0,221).
11. **Second game:** EV `Nova Essentials` (resource fork) ppat 128–137 (10): patType 1, offsets 28/78/4,174,
    64×64 8-bit, rowBytes 64, pmVersion 0, **ctFlags 0x0000** (value-indexed; used ⊆ values, used ≥ n in 9/10),
    total RGB sum 2,357,016. ⇒ both colour-table forms occur in real ppats — the shared table code needs both.
12. Usage: the planner found no `GetPixPat`/`PixPat` call in `BTX_i386.decompiled.c` (grep), and bank §7
    shows the level backgrounds use the same ids as PICT. The ppats look unused by the shipping game; they
    are decoded because the census covers them and EV ships them.

**PICT (28 across the five files) — the existing kit decodes 19; 9 need new paths**

13. Opcode-stream walk of all 28 (planner's `pict.py`, every stream reached 0x00FF):
    - **raw via `PICT(data:)` — 11:** Titles 9010 239×150, 9011 640×480, 9099 640×480 (16-bit DirectBits
      packType 3); Titles 9100 300×300 (8-bit, ctFlags 0); app 200 300×341 (**32-bit cmpCount 4**, real alpha),
      900 99×151, 998 32×32, 999 32×32, 8001 160×234 (8-bit ctFlags 0; 998/999 carry 0x00A0 before 0x00FF),
      912 640×480, 913 640×480 (16-bit).
    - **banded QuickTime via `PICT.decodeQuickTime` — 8:** Levels 13000–13005 640×480, each
      `0x0011 0x0C00 0x00A1 0x0001 3×[0x8200 0x0098-placeholder] 0x00FF`, bands JPEG 640×{192,192,96} at
      ty {0,192,384}, mode 64, srcRect = whole band, matte 0, mask 0, matrix identity + translation, depth 24;
      app 29401 "David" / 29402 "Alex" 148×172, one band. Exactly D2's Aki shape.
    - **0x0099 PackBitsRgn — 4 (PICT.init throws `unsupportedOpcode(0x0099)`):** Titles 9001 "Letters" and
      9002 "Letters Highlighted" 546×46, 9020 "High Scores" 222×37; app 9012 "By Alex Metcalf & David
      Wareing" 182×14. Stream `0x0011 0x0C00 0x001E 0x0001 <clip> 0x0099 <record> 0x00FF` (0x001E DefHilite is
      a zero-data state op `PICT.init` already accepts). All 8-bit, packType 0, **ctFlags 0x8000**, 256 entries,
      srcRect = dstRect = bounds = frame, mode 0, rowBytes 546/546/222/182 (>250 → u16 byte counts for 9001/9002 only).
    - **0x8201 UncompressedQuickTime + raster — 5 (PICT.init throws `unsupportedOpcode(0x8201)`):** app
      2910 309×328, 7000 92×47, 9030 "Pause 1" 330×16, 9031 "Pause 2" 260×16, 9077 "Custom levels" 47×23.
      Stream `0x0011 0x0C00 0x00A1 0x0001 0x8201 <raster> 0x00FF`, the 0x8201 opcode at byte 80 in all five;
      raster = 0x0098 8-bit ctFlags 0 (2910, 9030) or 0x009A 32-bit cmpCount 3 (7000, 9031, 9077).
14. **0x0099 record** (preceded by `0x0011 0x0C00 0x001E 0x0001`, note 13) = opcode · PixMap-sans-baseAddr 46 B (rowBytes, bounds, …, pmReserved) · ColorTable
    (8 + 8·n) · srcRect 8 · dstRect 8 · mode 2 · **maskRgn (rgnSize bytes, rgnSize includes itself)** · packed
    rows exactly as 0x0098. I.e. it is 0x0098 with a region inserted before the rows.
15. **QuickDraw region** (verified on 9020 and 9012): `rgnSize` u16, `rgnBBox` Rect; rgnSize == 10 → the
    rectangle itself (9001, 9002: bbox = frame → fully opaque). Otherwise scanline records
    `[i16 y][i16 x₀ x₁ x₂ x₃ … ][0x7FFF]`, list ended by y = 0x7FFF; row state(y) = state(y−1) XOR the spans
    [x₀,x₁), [x₂,x₃), … of every record with that y (rows before the first record are empty). 9020: rgnSize
    964, 38 records, consumed exactly 964, **5,930 of 8,214 px inside**; 9012: rgnSize 556, 15 records,
    **1,927 of 2,548 inside**; every x-list even-length. Outside-region pixels are a single colour in both
    (index 0 white in 9020, 255 black in 9012) — a true cut-out (planner render of 9020 confirms).
16. **0x8201 record** (opSize u32 after the opcode covers everything to the next opcode; 7000's opSize 1,822
    includes one pad byte): version u16 · matrix 9×u32 (all five: identity, w = 0x40000000) · matteSize u32 ·
    matteRect 8 (= (0,0,h,w) of the frame in all five) · **matte = an ImageDescription + its data** (no mask,
    no srcRect fields — unlike 0x8200). ImageDescription: idSize 86, cType **'rle '** (QuickTime Animation),
    version 1, revision 1, vendor 'appl', spatialQuality 0x400, width/height = frame, dataSize, frameCount 1,
    name "Animation", **depth 40 (8-bit grey)**, clutID 40. matteSize = 86 + dataSize exactly.
    opSize / matteSize / dataSize: 2910 56,264/56,214/56,128 · 7000 1,822/1,771/1,685 · 9030 4,644/4,594/4,508 ·
    9031 3,756/3,706/3,620 · 9077 1,286/1,236/1,150.
17. **'rle ' depth-8/40 data** (all five): u32 = (flag byte 0x40 << 24) | (24-bit size == dataSize); u16
    header **0x0008** (start line + line count present); u16 startLine **0**; u16 0; u16 lineCount = **height**;
    u16 0. Per line: u8 skip byte (**always 1** = no skip; units of 4 px), then codes i8: **−1 end of line**;
    **> 0** copy `code × 4` literal bytes; **< −1** repeat the next 4 bytes `−code` times; 0 would mean
    "another skip byte" — **never occurs** (lit/rep only: 2910 1,666/1,867 · 7000 92/64 · 9030 124/117 ·
    9031 96/81 · 9077 26/7). Rows are padded to a multiple of 4 px (309→312, 330→332, 47→48). Parsing
    consumes **dataSize − 1** bytes in all five; the one remaining byte is 0x00.
18. **Matte semantics:** alpha = the raw 8-bit matte sample (255 = picture drawn, 0 = destination kept).
    Planner renders: 9077 "CUSTOM LEVELS" and 7000 "BUBBLE TROUBLE" logo are 255 exactly over the glyphs,
    0 around, soft edges between. [MED — visual + QuickTime-matte convention; Ben's eyes on the pause banners
    close it.] Alpha statistics (in-frame pixels): 2910 α0 69,858 · α255 18,659 · partial 12,835 · Σα
    5,661,031 · 7000 800 · 3,136 · 388 · 833,833 · 9030 1,228 · 3,074 · 978 · 899,774 · 9031 836 · 2,503 ·
    821 · 736,802 · 9077 231 · 433 · 417 · 169,745.
19. Kit internals that shape the contracts (read 2026-10-03 at f578925; `PICT.swift` / `PICT+QuickTime.swift`
    unchanged at 8287ddb): `PICT.decodePackBitsRect` / `decodeDirectBitsRect` are `private static` (not reusable);
    `PICT.Cursor` (`PICT.swift`, internal struct: `u8/u16/i16/u32/skip/take/align2`, every over-read throws
    `truncated`) is internal to HectorGraphics — usable from `PICT+Masks.swift` in the same module; the internal
    memberwise `PICT.init(width:height:rgba:droppedPaintOps:)` lives in `PICT+QuickTime.swift`;
    `PICT.DecodeError` cases cannot be added from another file; `HectorResources.ByteReader` is internal to
    HectorResources (not usable from HectorGraphics). ⇒ the masked paths **rewrite the opcode stream and
    hand it to `PICT(data:)`**, walking it with **`PICT.Cursor`** (Tasks 4a/4b need nothing from Task 2);
    `CIcon`/`PixelPattern` use the bounds-checked reader in Task 2's `PixMapRecord.swift`.
19a. **Where the 9 masked PICTs are drawn (shell art — why the shell plan needs Tasks 4a/4b):** letter font
    9001/9002 via `_LoadLetters @ 0001e2ff` (`_LoadPict(0x2329)` / `_LoadPict(0x232a)` into the sprite GWorld,
    decompile lines 20041/20043) · 9012 menu credit (`_DrawMainMenu @ 00009eb3`, `_DrawPictInRect(0x2334, …)`
    line 4843) · 9020 high-scores header (`_DisplayHiScores @ 00025733`, `_GetPicture(0x233c)` line 24153) ·
    9030/9031 pause notices (`_DrawNotice @ 00027948`, `_DrawPictInRect(0x2346/0x2347, _gResumeNoticeRect…)`
    lines 25713/25714) · 9077 custom-level marker · 7000 prefs logo · 2910 quote easter egg. [The last three are
    the orchestrator's reading, 2026-10-03; their ids do not appear as literals in the decompile (likely dialog
    picture items or computed ids) — the shell plan re-confirms them.]

**snd (52) — `SndSound` already covers all of them**

20. All 52 (`BT Sounds.rsrc` 9000–9046 + 11001–11004 = 51; `Bubble Trouble X.rsrc` 9047): **format 1**, one
    modifier (sampledSynth 5, init 128/160/224), one command **0x8051** bufferCmd|dataOffset, header at
    **offset 20**. Matches `SndSound.init(data:)` exactly (format-1 mod-list skip, 0x8051 walk).
21. **encode 0x00 (stdSH), 48:** mono 8-bit offset PCM, 0 trailing bytes; rates (Fixed → `>>16`):
    9000–9045 22050 Hz (46), **9046 11127 Hz** (0x2B7745D1 = 11127.27), **9047 22254 Hz** (0x56EE8BA3 =
    22254.545). Worked: 9000 length 7,974 frames (header `0001 0001 0005 00000080 0001 8051 0000 00000014`);
    9046 3,664 frames; 9047 11,498 frames "Squeak squeak". baseFrequency 60 in 49 of 52 (three are 64, 67, 71).
22. **encode 0xFE (cmpSH), 4 — music 11001–11004 "Level set N music.1":** codec **'ima4'**, **numChannels 2**
    (stereo), rate 22254 Hz (0x56EE8BA3), compressionID −1; numFrames (packets) 24,032 ·
    19,168 · 21,924 · 26,064; packet bytes to resource end 1,634,176 · 1,303,424 · 1,490,832 · 1,772,352 =
    numFrames × 34 × 2 exactly ⇒ `ima4EffectivePacketCount(headerCount:byteCount:channels: 2)` == numFrames.
23. **No encode 0xFF (extended) anywhere** ⇒ no HectorAudio decoder gap; Task 5 is tests only. Bank §6 says
    the music is "@ 22255 Hz" (rounded) and omits 9047's rate — ⚑ corrections in Task 7.

**Locations and repos**

24. Data: `HECTORKIT_DATA_BTX` default = `$HOME/Developer/Ambrosia/Resources/ambrosia-extracted/Action-Adventure/Bubble Trouble X/BubbleTroubleX_1.1_UB/Bubble Trouble X.app/Contents/Resources`.
    The five `.rsrc` files are flat data-fork resource maps (`ResourceReader.read(fileAt:)` falls back to the data
    fork). Type counts per file = `INDEX.md` "Resource census" (Levels 119 resources, Sounds 53, Sprites 662,
    Titles 9, app 223 — totals verified against the extracted file counts).
25. Downstream note (NOT this plan): `_ASWPlotCIconHandle @ 000148cb` / `_ASWPlotCIcon @ 000147c4` take a
    special path only when `gRunningTiger` (set at decompile line 2396: `sysVersion − 0x1040 < 0x10`, i.e. 10.4.x
    only): erase a transparent GWorld, `PlotCIcon` into it, `CopyBits` mode **0x24** (transparent — white pixels
    dropped), plus a per-pixel inversion pass for the transform variant. On 10.5+ it is plain `PlotCIcon`
    (mask only). Which OS behaviour to replicate is a Ben ruling for the sprite plan.
26. HectorKit is at `origin/main` **8287ddb** (HectorShell landed: `8226a7e`, `8287ddb`; gate FLOOR **139**;
    only tag `v0.1.0`, at f578925), remote `github.com/andiyar/HectorKit`; main checkout clean (verified at fix pass,
    2026-10-03). Classics `BubbleTrouble/Core` does not exist yet (the sibling core plan's Task 0 creates it, R3).
    `.claude/worktrees/HectorKit` is a symlink to the HectorKit MAIN checkout (shared by every Classics worktree).

## Scope

- **Does:**
  1. HectorGraphics `CIcon` (`'cicn'` → RGBA with mask alpha; 1/2/4/8-bit) — all 335 BTX + 45 EV decode to
     the census numbers.
  2. HectorGraphics `PixelPattern` (`'ppat'` type 1 → opaque RGBA tile) — 7 BTX + 10 EV.
  3. HectorGraphics `PICT.decodeMasked` (0x0099 regions → alpha, Task 4a; 0x8201 'rle ' mattes → alpha, Task 4b)
     and `PICT.decodeAny` (one entry point choosing raster / QuickTime / region / matte) — all 28 BTX PICTs.
     Last wave, after Task 7; may be deferred to the shell wave without blocking the tag (note 19a).
  4. HectorAudio: real-data tests proving `SndSound` parses all 52 BTX sounds (no source change).
  5. `HectorTestSupport` BTX locator; gate exports `HECTORKIT_DATA_BTX`; floor +28.
  6. Classics `BubbleTrouble/Core`: `btx-census` executable + `BTXCensusTests` added to the core plan's manifest;
     `docs/bubble-trouble/data-census.md`; ⚑ corrections appended to `data-formats.md` §4/§6/§7 (Task 7); census
     catch-up to `decodeAny` once 4a + 4b land (Task 4c).
- **Untouched (load-bearing):** every existing HectorKit source file and test; `Package.swift` (HectorKit);
  `PICT(data:)` / `decodeQuickTime` / `SndSound` behaviour; the Aki target and `docs/aki/`; HectorShell; the EV repo;
  the sibling core plan's targets.
- **Explicitly deferred:** `btSP` decoder → **dropped** per ruling R2 (BTX-private compiled-sprite format,
  unused on OS X per bank §4, byte-order evidence it mis-decodes on i386, fails the kit's two-game rule) ·
  exact fractional sample rate on `SndSound` (`sampleRateFixed`) → BTX audio plan (needs `SndSound.swift` edit) ·
  `crsr`/`CURS`/`ICON`/`ics#`/`icl8`/`IMAG` decoders → BTX shell/screens plan if a screen needs them ·
  QuickTime 'rle ' depths other than 8/40 and skip codes → whenever a census shows one · 1-bit icon / pat1Data
  exposure → never unless a 1-bit display mode is replicated · sprite compositing rule (note 25) → sprite plan.
- **Rulings (RESOLVED by the orchestrator, 2026-10-03):**
  - **R1 tag name — RESOLVED: `v0.2.0`.** Only `v0.1.0` exists today (verified at fix pass). Task 6 tags `v0.2.0`;
    if `v0.2.0` already exists at landing time (e.g. HectorShell tagged first), tag `v0.3.0` instead and say so in
    the Task 6 commit message. Classics depends by path, so no build waits on the tag.
  - **R2 btSP — RESOLVED: dropped from the kit** (unused on OS X per bank §4; fails the two-game rule).
  - **R3 Classics manifest — RESOLVED:** the sibling core plan's Task 0 creates `BubbleTrouble/Core/Package.swift`
    (package name `BubbleTroubleCore`). This plan's Task 7 **adds** its `btx-census` executable target (+ product)
    and `BTXCensusTests` test target to that existing manifest; it never creates the manifest. If the manifest is
    absent when Task 7 starts, STOP and report.
  - **R4 main-checkout catch-up — RESOLVED:** kit work happens on a HectorKit worktree branch, merged to HectorKit
    main (`git push origin HEAD:main`, fast-forward). The `~/Developer/HectorKit` main checkout is then updated with
    `git -C ~/Developer/HectorKit pull --ff-only` **only when `git -C ~/Developer/HectorKit status --porcelain` is
    empty**; otherwise Classics builds use the env fallback: the manifest's dependency reads
    `Context.environment["HECTORKIT_PATH"] ?? "../../../HectorKit"` and the build exports
    `HECTORKIT_PATH=<the HectorKit worktree holding the landed commits>`.

## Tasks

HectorKit work happens on a branch in `HK=/Users/andiyar/Developer/HectorKit-btx` (Task 0, R4). Gate command, every task:
`cd "$HK" && HECTORKIT_TEST_LOG="${TMPDIR:-/tmp}/hk-btx-$$.log" tools/check-zero-skip.sh`.
"+N tests" means the executed total rises by exactly N over the rebased base (invariant 9).

### Task 0 — HectorKit worktree + baseline
- Steps: `git -C ~/Developer/HectorKit fetch origin` · `git -C ~/Developer/HectorKit worktree add "$HK" -b btx-decoders origin/main`
  (parallel Wave-2 agents use `-btx-cicn`, `-btx-snd` suffixed paths/branches; Wave 5 uses `-btx-pict`) ·
  in `$HK`: `swift build`, then the gate.
- Verify: gate PASS; note the executed total E₀ (**139** at 8287ddb unless origin/main moved).
- Commit: none.

### Task 1 — BTX locator + five-file type census (+1 test)
- Files (new): `Sources/HectorTestSupport/HectorData+BTX.swift`, `Tests/HectorResourcesTests/BTXResourceCensusTests.swift`.
  Edit: `tools/check-zero-skip.sh` (export + echo the default from note 24; FLOOR).
- Contracts:
  - `extension HectorData { public static let btxVar = "HECTORKIT_DATA_BTX" }` — doc: "Bubble Trouble X 1.1 UB
    `Contents/Resources` (five data-fork `.rsrc` files); a data locator for the census, like `aki11Var` (D3)".
  - `public func btxFile(_ fileName: String) throws -> ResourceCollection` — `HectorData.file(fileName, in: btxVar)`
    then `ResourceReader.read(fileAt:)`; XCTSkip naming the variable when absent / not a container (mirror `novaFork`).
- Test: `BTXResourceCensusTests.testFiveFilesTypeCounts` — per file,
  `Dictionary(uniqueKeysWithValues: collection.counts().map { ($0.type, $0.count) })` (`counts()` returns
  `[(type: String, count: Int)]`) equals INDEX.md's table
  exactly: Levels {LEVL 50, MAZE 50, PICT 6, ppat 7, vers 2, FILM 4} (119) · Sounds {snd  51, vers 2} (53) ·
  Sprites {TMPL 2, SpIL 1, cicn 331, vers 2, SpIc 1, btSP 325} (662) · Titles {PICT 7, vers 2} (9) · app: the 36-type
  table (223; includes cicn 4, PICT 15, snd  1, DITL 42, DLOG 11).
- Verify: `swift test --filter BTXResourceCensusTests` (with the env var) green; gate PASS at E₀+1 (140 from 139); set FLOOR.
- Commit: `HectorTestSupport: HECTORKIT_DATA_BTX locator + BTX five-file type census; gate exports it; floor <E₀+1>`
  — paths: the two new files + `tools/check-zero-skip.sh`. Push `HEAD:main`.

### Task 2 — `CIcon` ('cicn') + shared PixMap pieces (+12 tests)
- Files (new): `Sources/HectorGraphics/PixMapRecord.swift`, `Sources/HectorGraphics/CIcon.swift`,
  `Tests/HectorGraphicsTests/CIconTests.swift`, `Tests/HectorGraphicsTests/BTXCIconCensusTests.swift`,
  `Tests/HectorGraphicsTests/NovaColorRecordCensusTests.swift`. Edit: FLOOR.
- Contracts (`PixMapRecord.swift`):
  - `public enum PixMapDecodeError: Error, Equatable { case truncated; case notAPixMap; case unsupportedDepth(Int);
    case unsupportedPixMap(String); case colorIndexMissing(Int); case unsupportedPatternType(Int) }`
    (`unsupportedPixMap` names the field: "packType", "pixelType", "cmpCount", "maskBounds", "origin", …).
  - internal: a bounds-checked big-endian offset reader over `[UInt8]` (throws `.truncated`); `PixMapHeader`
    (parse 50-byte PixMap at an offset or the 46-byte baseAddr-less form; rowBytes `& 0x3FFF`, require bit 15 →
    else `.notAPixMap`; expose bounds, pixelSize, packType, pixelType, cmpCount, cmpSize, pmTable); `ColorTable`
    (parse at offset → 256-slot optional RGB lookup + byte length; rule of invariant 5); an indexed-row unpacker
    (depth 1/2/4/8, MSB-first, exactly `width` indices).
- Contracts (`CIcon.swift`):
  ```swift
  public struct CIcon: Sendable, Equatable {
      public let width: Int, height: Int
      public let pixelDepth: Int        // 1, 2, 4 or 8
      public let colorCount: Int        // ctSize + 1
      public let rgba: Data             // width*height*4, top row first; mask bit 1 → (r,g,b,255); 0 → (0,0,0,0)
      public init(data: Data) throws    // throws PixMapDecodeError
  }
  ```
  Layout = note 1 formula; reject: depth ∉ {1,2,4,8} (`unsupportedDepth`), packType ≠ 0, pixelType ≠ 0,
  cmpCount ≠ 1, mask/bmap bounds size ≠ pixmap size, bounds width/height ≤ 0, pixel rowBytes·8 < width·depth,
  any pixel index absent from the table (`colorIndexMissing`), short data (`truncated`). Trailing bytes ignored.
  RGB is zeroed where transparent, so premultiplied and straight alpha are the same bytes (state it in the doc).
- Tests (`CIconTests`, synthetic, built with `HectorTestSupport.be16/be32`):
  `testSynthetic8BitValueIndexedTableWithMask` (sparse values {0, 7, 255}; index 255 → its colour; masked → 0,0,0,0) ·
  `testSynthetic1BitMaskPaddingBitsIgnored` (mask/pixel padding bits set past width → no effect) ·
  `testSynthetic2BitAnd4BitUnpackMSBFirst` · `testDeviceRelativeTableIsPositional` (ctFlags 0x8000, values all 0) ·
  `testZeroBitmapRowBytesMeansNoBitmapData` · `testTruncatedAndHostileInputThrowsNeverTraps` (every prefix of a valid
  blob throws `.truncated`; huge rowBytes/height throws before allocating) · `testUnsupportedShapesRefused`
  (16-bit → `unsupportedDepth(16)`, bit 15 clear → `notAPixMap`, packType 1, missing index → `colorIndexMissing`).
- Tests (`BTXCIconCensusTests`, `btxFile`): `testAllSpriteCIconsDecodeToTheCensus` (331; size histogram, depth
  histogram {8:217,4:83,1:20,2:11}, opaque total 234,347, RGB sum 64,064,551, the 7 blank ids of note 6 have 0 opaque) ·
  `testAppCIconsDecodeToTheCensus` (4; per-id numbers of note 6) · `testCIcon25000WorkedDecode` (note 3 values).
- Tests (`NovaColorRecordCensusTests`, `novaFork`): `testOverrideGraphicsCIcons` (29, histogram, 2,318, 388,297) ·
  `testOverrideData2CIcons` (16, histogram, 3,444, 604,860). (Task 3 adds the ppat test to this file.)
- Verify: `swift test --filter 'CIconTests|BTXCIconCensusTests|NovaColorRecordCensusTests'` green; gate PASS at base+12
  (155 if it lands after T1 + T5 at 143).
- Commit: `HectorGraphics: CIcon ('cicn') decoder — 1/2/4/8-bit, value-indexed + device colour tables, mask alpha; BTX 335 + EV 45 census; floor <n>`.

### Task 3 — `PixelPattern` ('ppat' type 1) (+5 tests) — after Task 2 landed
- Files (new): `Sources/HectorGraphics/PixelPattern.swift`, `Tests/HectorGraphicsTests/PixelPatternTests.swift`,
  `Tests/HectorGraphicsTests/BTXPixelPatternCensusTests.swift`. Edit: `NovaColorRecordCensusTests.swift` (created in Task 2,
  this plan's own file), FLOOR.
- Contract:
  ```swift
  public struct PixelPattern: Sendable, Equatable {
      public let width: Int, height: Int, pixelDepth: Int, colorCount: Int
      public let rgba: Data             // width*height*4, opaque (A = 255); one tile, top row first
      public init(data: Data) throws    // throws PixMapDecodeError
  }
  ```
  patType must be 1 (`unsupportedPatternType(t)` otherwise); PixMap at patMap (u32 @2), pixels at patData (u32 @6),
  ColorTable at the PixMap's pmTable (offset); every offset + length range-checked; stale handle fields ignored;
  depth 1/2/4/8 via the shared unpacker; only `width` pixels per row (invariant 6).
- Tests: `PixelPatternTests.testSyntheticPositionalTableAndJunkRowPadding` (rowBytes > width, junk ignored) ·
  `testSyntheticValueIndexedTable` · `testRefusals` (patType 0 and 2, offsets past end, truncated) ·
  `BTXPixelPatternCensusTests.testAllSevenLevelPatternsDecode` (7 × 256×256, per-id RGB sums + pixel (0,0) of note 10,
  13000's (128,128)/(255,255)) · `NovaColorRecordCensusTests.testNovaEssentialsPixelPatterns` (10 × 64×64, RGB 2,357,016).
- Verify: filtered `swift test` green; gate base+5 (160 — the floor at the tag).
- Commit: `HectorGraphics: PixelPattern ('ppat' type 1) decoder; BTX 7 + EV 10 census; floor <n>`.

### Task 5 — `SndSound` over all 52 BTX sounds (+3 tests, no source change)
- Files (new): `Tests/HectorAudioTests/BTXSndCensusTests.swift`. Edit: FLOOR.
- Tests: `testAllFiftyOneSoundsFileSoundsParse` (51 parse; format 1 ×51; pcm8 ×47 + compressed ×4; rates
  22050 ×46 (ids 9000–9045), 11127 ×1 (9046), 22254 ×4; 9000 frameCount 7,974; 9046 3,664) ·
  `testAppSound9047` (format 1, pcm8, 11,498 frames, 22254 Hz, mono, name "Squeak squeak") ·
  `testMusicIsStereoIma4` (11001–11004: codec "ima4", numChannels 2, packetCount {24032, 19168, 21924, 26064},
  `packets.count` = packetCount × 68, `ima4EffectivePacketCount(…, channels: 2)` == packetCount).
- Verify: `swift test --filter BTXSndCensusTests` green; gate base+3 (143 after T1 at 140).
- Commit: `HectorAudio tests: all 52 BTX snd parse through SndSound (48 pcm8, 4 stereo ima4); floor <n>`.

### Task 6 — HectorKit docs + tag `v0.2.0` (after Tasks 1, 2, 3, 5 on origin/main)
- Edits (minimal, after rebase): `docs/STATE.md` (modules list gains CIcon/PixelPattern; gate floor 160 (or the re-gated
  total, invariant 9); census line "BTX: 335 cicn, 7 ppat, 19 of 28 PICT (9 masked — Tasks 4a/4b, last wave), 52 snd";
  carried: masked PICTs pending and one-game-only when they land, sampleRate truncation) · `docs/DECISIONS.md` —
  **D5** (verified at fix pass: D1–D4 exist, D4 = HectorShell; re-check after the final rebase and use the next free
  number): "BTX decoders: value-indexed cicn tables, padding ignored, PixelPattern type 1 only, masked PICT via stream
  rewrite + straight alpha (planned; lands with Tasks 4a/4b), 'rle ' 8-bit refusal set, btSP rejected (R2),
  HECTORKIT_DATA_BTX locator accepted as D3" with Rejected alternatives (position-indexed tables; editing PICT.swift;
  ImageIO for 'rle ' — it cannot read it; a btSP decoder) · `CLAUDE.md` env-var sentence gains `HECTORKIT_DATA_BTX`.
- Tag (R1): `git tag -l v0.2.0` empty → `git tag -a v0.2.0 -m "BTX decoders: CIcon, PixelPattern, snd census"` and
  `git push origin v0.2.0`; if `v0.2.0` exists, use `v0.3.0` and say so in the commit message.
- Verify: gate PASS on origin/main HEAD (160 unless re-gated); `git log origin/main` shows Tasks 1, 2, 3, 5, 6.
- Commit: `docs: BTX decoders landed (STATE, DECISIONS D5, CLAUDE env vars); tag v0.2.0`. Then R4's catch-up rule.

### Task 7 — Classics `btx-census` + tests + census doc + bank corrections
- Precondition (R3/R4): `BubbleTrouble/Core/Package.swift` exists (the core plan's Task 0) — else STOP and report.
  `git -C ~/Developer/HectorKit merge-base --is-ancestor <Task-6 sha> HEAD` succeeds. If it does not: when
  `git -C ~/Developer/HectorKit status --porcelain` is empty and the checkout is on `main`, run
  `git -C ~/Developer/HectorKit pull --ff-only` and re-check; otherwise use R4's fallback (manifest dependency
  `Context.environment["HECTORKIT_PATH"] ?? "../../../HectorKit"`, build with `HECTORKIT_PATH=$HK` after
  `git -C "$HK" merge-base --is-ancestor <Task-6 sha> HEAD` succeeds). Never edit the shared symlink; never
  touch the main checkout beyond that clean `pull --ff-only`.
- Files: `BubbleTrouble/Core/Package.swift` (add targets per R3; dependency line only if R4's fallback is used),
  `BubbleTrouble/Core/Sources/btx-census/BTXCensus.swift`, `BubbleTrouble/Core/Tests/BTXCensusTests/BTXCensusTests.swift`,
  `docs/bubble-trouble/data-census.md` (new), `docs/bubble-trouble/data-formats.md` (append-only ⚑ corrections),
  `docs/bubble-trouble/INDEX.md` (one pointer line).
- Manifest contract (additions only): product `.executable(name: "btx-census", targets: ["btx-census"])`;
  `.executableTarget(name: "btx-census")` and `.testTarget(name: "BTXCensusTests", dependencies: ["btx-census", …])`,
  both depending only on HectorKit products `HectorResources`, `HectorGraphics`, `HectorAudio`. The core plan's
  targets are untouched.
- Tool contract: `btx-census <Bubble Trouble X Contents/Resources>`; Markdown on stdout, file NAMES never paths;
  exit 0 / 1 on any failure / 2 on bad args (Aki convention). Testable seam: `enum BTXCensus { static func
  render(resourcesDirectory: URL) -> (stdout: String, failures: Int) }` (tests use `@testable import btx_census`).
  Sections: 1 per-file type counts · 2 cicn (size×depth table, opaque total, blank ids) · 3 ppat (id, name, size,
  colour form) · 4 PICT (file, id, name, frame, path, alpha summary) · 5 snd (id, name, format, encode, rate,
  channels, frames/packets) · Totals line. PICT path at Task 7 (before Tasks 4a/4b): `PICT(data:)` → on
  `unsupportedOpcode(0x8200)` `PICT.decodeQuickTime`; `unsupportedOpcode(0x0099)` → "deferred region",
  `unsupportedOpcode(0x8201)` → "deferred matte" (named deferrals, not failures); any other throw is a failure.
- **Exact summary lines** (each a whole stdout line, in this order; the Totals line is the last line):
  ```
  # Bubble Trouble X 1.1 — data census
  files 5 · resources 1066 (BT Levels.rsrc 119 · BT Sounds.rsrc 53 · BT Sprites.rsrc 662 · BT Titles.rsrc 9 · Bubble Trouble X.rsrc 223)
  cicn 335 (331 + 4) · depth {1: 20, 2: 11, 4: 84, 8: 220} · opaque px 236,687 · RGB sum 64,978,590 · blank 7: 25004 25108 25208 25308 25408 25504 27308
  ppat 7 · 256×256 8-bit · device colour table 7 · RGB sum 89,901,763
  PICT 28 · raw 11 · quicktime 8 · deferred region 4 (9001 9002 9012 9020) · deferred matte 5 (2910 7000 9030 9031 9077)
  snd 52 · pcm8 48 · ima4 4 (stereo) · 22050 Hz 46 · 22254 Hz 5 · 11127 Hz 1
  Totals: cicn 335 (331 + 4), ppat 7, PICT 28 (raw 11 · quicktime 8 · deferred region 4 · deferred matte 5), snd 52 (pcm8 48 · ima4 4), failures 0
  ```
  (Derived from notes 6, 10, 13, 20–22: depth 8 = 217 + 3 app, 4 = 83 + 1001; opaque 234,347 + 2,340; RGB 64,064,551 +
  914,039; ppat RGB = Σ of note 10; 22254 Hz = 9047 + 4 music. Arithmetic re-checked at fix pass.)
- Tests (`BTXCensusTests`, env `HECTORKIT_DATA_BTX`, XCTSkip naming it): `testFiveFilesOpen` ·
  `testEveryCIconAndPixelPatternDecodes` (335, 7) · `testEveryPICTClassified` (28: raw 11, quicktime 8, deferred region 4,
  deferred matte 5; no other error) · `testEverySoundParses` (52; 48 pcm8, 4 compressed) · `testSummaryLinesExact`
  (the seven lines above, verbatim, in order, Totals last; `failures == 0`) · `testStdoutEqualsCommittedCensus`
  (stdout byte-equals the body of `docs/bubble-trouble/data-census.md` below its rule, located via `#filePath`).
- Doc: `data-census.md` = header (generated date, HectorKit sha, re-run commands as in `docs/aki/data-census.md`)
  + rule + stdout verbatim. Bank ⚑ corrections (dated, evidence = this census / planner probe): §4 cicn depths and the
  7 blank ids, value-indexed tables; §6 rates 22254.545 Hz (music + 9047), 11127.27 Hz (9046), music stereo; §7 the four
  PICT shapes (masked two pending kit Tasks 4a/4b) and the ppat rowBytes/device-table facts.
- Verify: `cd BubbleTrouble/Core && HECTORKIT_DATA_BTX="<R>" swift test` (0 skips, 6 + core-plan tests green);
  `swift build -c release` then run the tool — summary lines as stated, exit 0.
- Commit (Classics worktree branch): `BubbleTrouble/Core: btx-census + BTXCensusTests (HECTORKIT_DATA_BTX); data-census.md; bank ⚑ corrections §4 §6 §7`.
  Merge/push per the orchestrator.

### Task 4a — masked PICTs, part 1: 0x0099 PackBitsRgn regions + `decodeAny` (+4 tests) — LAST WAVE
> Lands after Task 7. **May be deferred to the shell wave without blocking the tag** (Task 6); the shell plan needs
> it (note 19a). Budget: ≤ ~250 lines of new Swift (sources). Independent of Task 2 (byte reader = `PICT.Cursor`).
- Files (new): `Sources/HectorGraphics/PICT+Masks.swift`, `Sources/HectorGraphics/QuickDrawRegion.swift`,
  `Tests/HectorGraphicsTests/PICTRegionMaskTests.swift`, `Tests/HectorGraphicsTests/BTXPICTCensusTests.swift`. Edit: FLOOR.
- Contracts:
  ```swift
  extension PICT {
      public enum MaskDecodeError: Error, Equatable {
          case noMask                        // stream has neither 0x0099 nor 0x8201 — use PICT(data:)
          case unsupportedRegion(String)     // "overrun", "oddInversions", "srcDst", …
          case unsupportedMatte(String)      // "codec", "depth", "size", "matrix", "rleHeader", "skip", "trailing" (used from 4b)
      }
      public enum DecodePath: String, Sendable { case raster, quickTime, packBitsRegion, quickTimeMatte }
      /// Raster PICT carrying ONE mask: a 0x0099 PackBitsRgn (4a), or an 0x8201 matte + one raster op (4b).
      public static func decodeMasked(data: Data) throws -> PICT
      /// PICT(data:) → on unsupportedOpcode(0x8200) decodeQuickTime → on 0x0099/0x8201 decodeMasked.
      public static func decodeAny(data: Data) throws -> (pict: PICT, path: DecodePath)
  }
  ```
  Until 4b lands, a stream whose mask construct is 0x8201 still throws `PICT.DecodeError.unsupportedOpcode(0x8201)`.
  Method (note 19): walk with `PICT.Cursor` the state ops `PICT.init` accepts (incl. 0x001E, note 13) up to the
  0x0099, then **rewrite the stream**: copy with the opcode changed to 0x0098 and the `rgnSize` region bytes removed
  (located at opcode end + 46 + 8 + 8·n + 18, note 14); refuse srcRect ≠ dstRect or dstRect ≠ pixmap bounds. Decode the
  rewrite with `PICT(data:)`, then alpha: region inside → 255 / outside → 0 (`QuickDrawRegion`, note 15, rasterised into
  frame coordinates, record must end exactly at rgnSize). Alpha is **straight** (RGB kept as decoded) — matches
  `PICT(data:)`'s cmpCount-4 contract; doc comment says so and says "verified on one game's data, not yet called
  general" (delta 2; no game name, invariant 1). `droppedPaintOps` carried from the inner `PICT(data:)`.
- Tests (`PICTRegionMaskTests`, synthetic): `testPackBitsRgnRectangularRegionIsOpaque` ·
  `testPackBitsRgnInversionRegionAlpha` (two records, XOR carry-down, hand-computed mask) · `testRegionRefusals`
  (region overrun, odd-length x-list, srcRect ≠ dstRect, `noMask` on a plain 0x0098 PICT).
- Tests (`BTXPICTCensusTests`): `testRegionPICTsDecodeToTheCensus` (9001/9002 546×46 inside 25,116 each, 9020 222×37
  5,930, 9012 182×14 1,927; each via `decodeAny` with path `packBitsRegion`; outside pixels α 0).
- Verify: filtered `swift test` green; gate base+4 (164 from 160). Existing `PICTTests`/`PICTQuickTimeTests`/`AkiPICTCensusTests` unchanged and green.
- Commit: `HectorGraphics: PICT.decodeMasked 0x0099 region masks + decodeAny; 4 BTX region PICTs; floor <n>`. Then R4.

### Task 4b — masked PICTs, part 2: 0x8201 'rle ' mattes (+3 tests) — LAST WAVE, after 4a
> Same deferral rule as 4a. Budget: ≤ ~250 lines of new Swift (sources).
- Files (new): `Sources/HectorGraphics/AnimationRLE.swift`, `Tests/HectorGraphicsTests/PICTMatteTests.swift`.
  Edit: `PICT+Masks.swift` and `BTXPICTCensusTests.swift` (this plan's own files from 4a), FLOOR; as-built docs:
  `docs/STATE.md` census line → "28 of 28 PICT" + one-game-only carried note; `docs/DECISIONS.md` one dated as-built
  line appended to D5.
- Contract: `decodeMasked` / `decodeAny` gain the 0x8201 branch (`DecodePath.quickTimeMatte`; refusals as
  `MaskDecodeError.unsupportedMatte(…)`). Method: copy the stream with the whole 0x8201 record (opcode + 4 + opSize,
  then word-align) removed; decode the rewrite with `PICT(data:)`; alpha = the raw matte sample (`AnimationRLE`,
  note 17: depth 40/8 only, header 0x0008, start line 0, lineCount = height, skip byte 1 only, code 0 refused, ≤ 1
  trailing byte, matte size and matteRect = frame, identity matrix; note 18 polarity). Straight alpha, same doc wording
  as 4a.
- Tests (`PICTMatteTests`, synthetic): `testUncompressedQuickTimeMatteLiteralAndRepeatCodes` (4-px units, row padding
  5→8) · `testMatteRefusals` (cType 'jpeg', depth 32, matte size ≠ frame, rle code 0, skip byte ≠ 1, > 1 trailing byte,
  non-identity matrix).
- Tests (`BTXPICTCensusTests`): `testEveryPICTDecodesToItsFrame` (28 via `decodeAny`; frames + paths per note 13: raster
  11, quickTime 8, packBitsRegion 4, quickTimeMatte 5; matte α0/α255/partial/Σα of note 18; QuickTime band structure
  through the existing public API of `PICT+QuickTime.swift`: 13000–13005 heights [192,192,96] at y [0,192,384],
  29401/29402 one 148×172 band, one placeholder per band, all codec "jpeg").
- Verify: filtered `swift test` green; gate base+3 (**167**, the plan's final floor). No new tag in this plan.
- Commit: `HectorGraphics: PICT.decodeMasked 0x8201 'rle ' mattes; all 28 BTX PICTs; STATE/D5 as-built; floor <n>`. Then R4.

### Task 4c — Classics census catch-up (after 4b reaches the build per R4)
- Precondition: as Task 7's, with `<Task-4b sha>` in place of `<Task-6 sha>`.
- Files: `BubbleTrouble/Core/Sources/btx-census/BTXCensus.swift`, `BubbleTrouble/Core/Tests/BTXCensusTests/BTXCensusTests.swift`,
  `docs/bubble-trouble/data-census.md` (regenerated, header sha updated).
- Change: the PICT section uses `PICT.decodeAny` (paths printed raw / quicktime / region / matte, with alpha summary).
  Summary lines that change: `PICT 28 · raw 11 · quicktime 8 · region 4 (9001 9002 9012 9020) · matte 5 (2910 7000 9030 9031 9077)`
  and `Totals: cicn 335 (331 + 4), ppat 7, PICT 28 (raw 11 · quicktime 8 · region 4 · matte 5), snd 52 (pcm8 48 · ima4 4), failures 0`;
  `testEveryPICTClassified` expects raw 11 / quicktime 8 / region 4 / matte 5. No new tests.
- Verify: as Task 7. Commit (Classics): `BubbleTrouble/Core: btx-census PICTs via decodeAny (masked 9 decoded); data-census.md regenerated`.

## Execution order

- **Wave 0:** Task 0 (one agent).
- **Wave 1:** Task 1 — lands first; every real-data test needs `btxVar` and the gate export.
- **Wave 2 (parallel, two Opus implementers, each in its own HectorKit worktree from post-Task-1 origin/main):**
  Task 5 (snd, smallest) · Task 2 (CIcon + shared). Land serially in that order; each lander rebases, resolves
  `FLOOR` by re-gating (invariant 9), pushes.
- **Fable review A** after Wave 2 (colour-table rule, padding, hostile-input bounds, refusal coverage).
- **Wave 3:** Task 3 (needs `PixMapRecord.swift` from Task 2).
- **Wave 4:** Task 6 (tag `v0.2.0`, floor 160), then Task 7 once R4's precondition holds. **Fable review B** over
  Tasks 3, 6, 7.
- **Wave 5 (LAST; may be deferred to the shell wave without blocking the tag):** Task 4a → Task 4b → Task 4c,
  strictly sequential (4b edits 4a's files; 4c needs 4b in the build). **Fable review C** over 4a/4b/4c (rewrite
  offsets, region XOR, matte polarity, refusal coverage).
- Harden-first rationale: the locator and the cheap snd proof go first; the riskiest decoder (masked PICT, one
  game only) gets its own review before its first consumer — the shell plan (note 19a) — touches it.

## Pre-execution self-audit

1. Does `PICT(data:)` really throw `unsupportedOpcode(0x0099)` / `(0x8201)`? ✅ ok — `default:` branch of the opcode
   switch in `PICT.swift` throws `unsupportedOpcode(op)`; neither opcode has a case.
2. Can the new code reuse `ByteReader`? ✅→FIXED: it is internal to HectorResources; `CIcon`/`PixelPattern` get an internal
   reader in `PixMapRecord.swift` (Task 2); the masked-PICT walk uses the existing internal `PICT.Cursor` (same module),
   so Tasks 4a/4b do not depend on Task 2.
3. Can `decodeMasked` call the PackBits row decoders? ✅→FIXED: they are `private static`; switched to the
   stream-rewrite method (note 19), which also keeps `PICT.swift` untouched.
4. Can `decodeMasked` construct a `PICT`? ✅ ok — internal memberwise init exists in `PICT+QuickTime.swift`.
5. New error cases on `PICT.DecodeError`? ✅→FIXED: impossible from another file; nested `PICT.MaskDecodeError` instead.
6. Does any task need `Package.swift` (HectorKit)? ✅ ok — all new files join existing targets; `HectorTestSupport`
   already depends on HectorResources.
7. Static stored property in an extension of `HectorData`? ✅ ok — allowed for `static let`.
8. Floor arithmetic with a concurrent session bumping the same line? ✅→FIXED: invariant 9 (delta rule + re-gate on
   conflict); acceptance stated as "+N over the rebased base".
9. Tag collision with Trigger C's reserved v0.2.0? ✅→FIXED: R1 RESOLVED — `v0.2.0` (only `v0.1.0` exists), `v0.3.0` if
   taken at landing time.
10. Classics build picking up a stale or dirty HectorKit through the shared symlink? ✅→FIXED: invariant 10; Task 7/4c
    precondition checks Task 6's (resp. 4b's) commit is an ancestor of the main checkout's HEAD; clean-only
    `pull --ff-only`, else `HECTORKIT_PATH` (R4).
11. "Census-verified against two games" for every decoder? ✅→FIXED partly: CIcon and PixelPattern have EV Nova data
    (notes 7, 11; tests added); masked PICT has NO second game anywhere (planner walked EV + Aki) — disclosed as delta 2
    and in the doc comment, not hidden.
12. Is value-indexing really right, or an artefact of tables that happen to be sequential? ✅ ok — 227 of 331 sprites
    (230 of 335) use pixel values ≥ colorCount that exist only as `value` fields (each table: values 0…n−2 plus a final
    black entry at 2^d−1); position-indexing would read past the table.
13. Matte polarity (alpha = sample vs 255 − sample)? ✅ ok at MED — renders of 9077/7000 show 255 over the art;
    flagged as an honesty gate rather than claimed.
14. Could the census tool pass while a decoder is wrong? ✅→FIXED: tests pin digests (opaque counts, RGB sums,
    alpha sums, specific pixels), not just sizes — a band swap, palette misindex or padding read changes them.
15. snd "coverage" claimed without a parse? ✅→FIXED: the planner's Python mirrors `SndSound`'s walk; Task 5's
    tests are the Swift proof, and the plan states no source change is expected — if one fails, STOP and report
    (that would be a real gap to plan, not to patch inline).
16. Does every Scope "Does" item have a task and every task a verify + commit? ✅ ok — Does 1→T2, 2→T3, 3→T4a+T4b,
    4→T5, 5→T1(+each FLOOR), 6→T7+T4c; T0 has no commit by design.
17. Hidden dependencies: Task 3 edits a test file created by Task 2; Task 4b edits two files created by Task 4a; Task 4c
    needs 4b in the build. ✅ ok — each is sequenced after its predecessor lands.
18. Planner wrote no Swift and verified no Swift build; all numbers are Python-derived. ✅ disclosed — the first
    filtered `swift test` of each task is the cross-check; a mismatch is investigated against the Python probe
    (both readings cited), never "fixed" by editing the expectation.
19. Is a masked-PICT task small enough to review? ✅→FIXED: split into 4a (regions, 4 PICTs) and 4b (mattes, 5 PICTs),
    each ≤ ~250 lines of new Swift, moved to the last wave; Task 7 names the 9 as deferrals until 4c.
20. Floor numbers re-derived against the live tree (fix pass): base 139 at 8287ddb; +28 = 167; 160 at the tag.

## Orchestration notes

- All implementers **Opus**; reviews per house rule (Fable reviewers, report everything with confidence).
  Prompt skeleton: fable-kit `orchestrator.md` §3; each prompt carries this plan's path, its task number, the
  invariants, and "do not touch any file outside your task's list".
- **Coordination hazard:** the Phase-1 / HectorShell session works in HectorKit too (HectorShell committed as
  `8226a7e`, `8287ddb`; main checkout clean at fix pass, 2026-10-03). Hence: our work only on branches in linked
  worktrees; new files only; `check-zero-skip.sh` touched on three lines; `git fetch && git rebase origin/main`
  before every commit; fast-forward pushes; DECISIONS number chosen after the final rebase; main checkout touched
  only by R4's clean `pull --ff-only`.
- Parallel-safe: Tasks 2 and 5 share no source file (only `FLOOR`). Not parallel: Task 3 after 2; Task 6 after 1, 2,
  3, 5; Task 7 after 6 + R4; 4a → 4b → 4c after Task 7. Two gates may run concurrently only with distinct `HECTORKIT_TEST_LOG` paths.
- STOP conditions for any implementer: a census number disagrees with this plan after one honest re-check; a
  decoder would need to edit an existing kit file; the main-checkout precondition fails; a test would need to skip.

## Review ledger (fix pass, 2026-10-03)

Fable-grade review verdict ACCEPT_WITH_FIXES; orchestrator rulings R1–R4. Each item and where it landed:

| # | Finding / ruling | Landed in |
|---|---|---|
| R1 | Tag `v0.2.0` (`v0.3.0` if taken at landing) | Scope "Rulings" R1; Task 6 Tag + Commit; self-audit 9 |
| R2 | btSP dropped from the kit | Scope "Rulings" R2; Scope "Explicitly deferred" |
| R3 | Core plan's Task 0 owns `BubbleTrouble/Core/Package.swift` (`BubbleTroubleCore`); Task 7 only adds targets | Scope "Rulings" R3; Task 7 Precondition, Files, Manifest contract; Scope Does 6 |
| R4 | Worktree branch → HectorKit main → clean-only `pull --ff-only`, else `HECTORKIT_PATH` | Scope "Rulings" R4; invariants 10–11; Tasks header; Task 7/4c Precondition; Orchestration notes |
| 1 | Floor 139 at 8287ddb, target 167 (+28) | Verification model (ladder 140/143/155/160/164/167); Task 0 E₀; Tasks 1, 2, 3, 5, 6, 4a, 4b Verify; note 26; invariant 9; self-audit 20 |
| 2 | Delete the "uncommitted HectorShell WIP" claim | Invariant 10; note 26; Orchestration notes "Coordination hazard" |
| 3 | Task 7 precondition = Task 6's commit is an ancestor of the main checkout's HEAD | Task 7 Precondition (4c: Task 4b's); self-audit 10 |
| 4 | DECISIONS number D5 (D1–D4 exist; D4 = HectorShell) | Task 6 Edits + Commit; Task 4b as-built line |
| 5 | `PICT.Cursor` is the masked-PICT byte reader (no Task 2 dependency) | Note 19; Task 4a header + Method; self-audit 2 |
| 6 | Apply R1 | as R1 |
| 7 | 227 of 331 (230 of 335); value lookup confirmed (tables = values 0…n−2 + final black at 2^d−1) — re-probed at fix pass, matches | Invariant 5; note 6; self-audit 12 |
| 8 | No "BTX" in source doc comments: "verified on one game's data" | Delta 2; Task 4a Method (4b refers to it) |
| 9 | Region streams run `0x0011 0x0C00 0x001E 0x0001 0x0099` | Notes 13, 14; Task 4a Method |
| 10 | `Dictionary(counts())` does not compile | Task 1 Test (uniqueKeysWithValues form) |
| 11 | Task 7 tests assert the exact stdout | Task 7 "Exact summary lines" + `testSummaryLinesExact` + `testStdoutEqualsCommittedCensus`; Task 4c changed lines; Verification model |
| 12 | Split Task 4 → 4a (0x0099, 4 PICTs) / 4b (0x8201, 5 PICTs), ≤ ~250 lines each, last wave after Task 7, deferrable; record per-PICT drawing sites | Tasks 4a, 4b (+ Task 4c Classics catch-up, needed so Task 7 can run first); Scope Does 3; Execution order Wave 5; note 19a (sites; 9077/7000/2910 marked orchestrator-supplied, not found as literals); invariant 2; self-audit 16, 17, 19 |
| 13 | Rename PixPat → PixelPattern (orchestrator ruling 2026-10-03: SDK name collision reported by the Task 3 implementer) | Task 3 (header, Files, contract, Tests, Commit); notes 9–11 heading + note on the shared reader; Scope; Task 6 Edits + Tag; Task 7 test name; self-audit 2, 11 |
