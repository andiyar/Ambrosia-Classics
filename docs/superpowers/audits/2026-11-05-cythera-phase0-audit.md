> Superseded by `docs/superpowers/plans/2026-11-05-cythera-remainder.md` on 2026-11-08. Kept as history; nothing current reads it.

# Audit of the built Cythera Phase 0 work (K1, C0–C5) — 2026-11-05

*Two read-only reviewers (Opus 5.5, `fk-reviewer`), dispatched in parallel by Claude Fable 5.1 in the seat, each with
the Phase 0 plan's contracts, the design, one area, nine questions, two or three rules to re-derive by hand from the
committed decompile, and a numeric prediction to confirm. Nothing was edited, built in or launched inside the
repository; every build ran in a scratch copy. The seat's rulings come first; the two reports follow verbatim.*

## The verdict in one paragraph

Every rule both reviewers re-derived by hand from the binary matches the code: the segment cipher's three
constants and its skip loop, the map body offsets on both paths and the chunked byte copy line for line, the prop
record's x/y/parent bit maths and the worked records of level 2, the compo-tile quadrant rule, the tile-sheet range
and the zero fill of the absent sheet, the pix row padding (it is in the stream itself), the displacement-filter
layout with its signed offsets, the palette's data-file-first order, all 21 picture outcomes. Both predictions
confirmed (the AI segment 0x0410 reads "Attack Nearest" through `segment` and garbage through `scriptSegment`;
the Catamarca screenshot decodes as 16-bit 640×480 mode 0). No input traps: every prefix of the schedules, the
tile names, the character table and a prop segment throws or parses to fewer records. The suite is 44 / 0 / 0 in
both scratch copies; the layering greps are empty. What the audit found is seams, as on Castles and Ferazel: **the
save overlay is not yet a segment store** (nothing can read a map, props or a script through it), **reading a
script id in the combat-AI band through the script reader silently scrambles it**, and **compo tiles are built from
frame 0's tile table in the original, not the current frame** (the code is right today, its comment is wrong, and
Phase 1 must pass the table, not the raw store). Three carried minors still stand. No "redo" of built code.

## Rulings (the seat's; applied to the spec and the plan, marked ⚑ audit there)

| # | finding (report) | ruling | where it lands |
|---|---|---|---|
| 1 | `SegmentOverlay` does not conform to `SegmentStore` (no `entry`), so `PropSegment`, `WorldGlobals` and `LevelMap` cannot read through a save overlay; no decrypted `scriptSegment` on the overlay; the store protocol has no write path (A 4a, 7d, 7e) | **change (new task C13).** The overlay conforms (`entry` = the topmost store that has the id) and gains `scriptSegment(_:)` with the same plaintext rule; the writable-store protocol (`write`, `remove`, flush, encrypted save) is Phase 4's and is named on its card — Phase 0 writes no file | plan wave 1 session C (C13); Phase 4 card SV-OV |
| 2 | `scriptSegment` scrambles the 14 present combat-AI ids 0x0410–0x0436; leaving the routing to the caller is a trap for any "every script id" loop (A 5b) | **change (C9).** `SegmentFile.scriptSegment` returns the AI band as stored through a second named set (`storedPlaintextBand`), one test; C9's decoder then reads every script-band id through one call | plan C9 (Files + test 7); the ladder +1 from C9 on |
| 3 | Compo tiles: the original builds them from the frame-0 tile pointer table (no frame term at `100051b0`/`100051fc`), so they never animate and see tile 1275 as 1274's pixels; the Swift reads the raw store (identical today: no shipped compo entry touches an animated tile, 0 of 4,224) but its comment says "current frame" (B Q1b, Q7c) | **change (comment now, shape in Phase 1).** C13 fixes the comment; card 1a-TB builds the eight pointer tables and `compoTile` takes the frame-0 table | plan C13; wave 3 card 1a-TB |
| 4 | The four differing `clut 256` entries are visible colours: entry 0 white vs grey, 16 two greys, 252/253 dark blues vs black (B Q5d) | **change (gate card).** The Phase 1a gate card names the four pairs, not "four differ"; the data file's stays the default | spec §5 row 1; wave 3 gate |
| 5 | Carried minors still stand: `AnimationRecord.tile(forFrame:)` has no 0…7 guard (frame −3 → tile 9); `LZ.decode(_:limit:)` accepts a negative limit; the F007 length assertion re-asserts what the loader enforced (A 8a–8c) | **change (C13).** Guard by `frame & 7` as the caller's 8-frame counter does; throw `outputLimit` up front for a negative limit; the test checks the TOC length instead | plan C13 |
| 6 | `Palette.clut256` reads the data file directly instead of through the lookup chain whose answer it claims to be (B Q5b); the `rgba` doc says RGBA for 0xAARRGGBB words (Q5e); the Color2Index high-byte claim is unsourced (Q5f) | **change (C13, doc and one line).** Go through `resource(type:id:)`; fix the two comments (the name `rgba` is locked by S3) | plan C13 |
| 7 | No test pins the built compo tiles' bytes (B Q1d); no test pins a Rect picture's by-value colour table order (Q6d) | **change (C13, tests only).** One SHA-256 over the 264 built compo tiles; one pinned Rect table | plan C13 |
| 8 | The side cap is stricter than the original (per side ≤ D, where the original only allocates D·D·2 and never checks W or H) (A 2c); a chunked map with a side < 8 yields zeros where the original leaves the old buffer (A 2d); a malformed present sheet throws where the original zero-fills (B Q2b) | **keep (Invariant 4 refusals, documented).** Each gets one comment line in C13 saying it is a census refusal the original does not make | plan C13 |
| 9 | `SegmentOverlay.write` throws where S2 said non-throwing; `LZ.decode(_:limit:)` and `LZError.outputLimit` are additions; `LevelMap.init(file:level:)` takes the concrete file (A 4b–4d) | **keep (record).** C12's as-built lists the three deviations; a store-based map initialiser comes with C13's conformance (`init(store:level:maxMapDimension:)`) | plan C12, C13 |
| 10 | "Every prefix throws" is not literally true: cuts on record boundaries parse to fewer records (A 6b) | **keep (wording).** The invariant reads "never traps; a cut on a record boundary parses to fewer records" | plan §0 (Invariant text) |
| 11 | `RefindSegment` picks the bottom-most file, not the topmost (used only after compiling a user AI); an empty write reveals the lower store's copy where the original's `SaveSegment` masks it (A 7b, 7c) | **missing (Phase 4, expected).** Both on the Phase 4 SV-OV card; a one-line bank note in data-format §1.4 lands with C13 | Phase 4 card; bank |
| 12 | The PICT opcode walk duplicates kit logic; a kit error naming the first bits opcode (D14 carry) removes it; the kit already has a QuickTime 0x8200 path the Land King Hall oracle might use (B Q6b, Q6c) | **keep (kit carry stands).** Nothing changes until HectorKit names the opcode; Land King Hall stays a named refusal | — |
| 13 | Displaced filter reads can leave the tile; the hold/counter stepping is not modelled (B Q4c, Q4d) | **missing (Phase 1, expected).** Card 1a-RN's filter reads from the store and steps hold/counter as `AdvanceDisplacementFilters` does | wave 3 card 1a-RN |
| 14 | `IndexedImage` is immutable; `tile(_:)` returns an empty slice out of range (B Q7b, Q7e) | **keep.** Phase 1 adds a mutable framebuffer type beside it; the pointer tables make `tile(_:)`'s range question moot (one comment line in C13) | wave 3 card 1a-TB |
| 15 | Suite 44 / 0 / 0 in both copies; CytheraCoreTests 34 (Data 5, Segment 9, LZ 6, LevelMap 4, Prop 3, Globals 7), CytheraRenderTests 10; G7 greps empty (A 9, B Q8, Q9) | **keep.** Equal to the seat's own run | — |

**Net effect on the next wave:** one task added (C13, minor, one reviewer leg, 6 tests), one test added to C9, the
ladder becomes C8 50 → C9 57 → C6 63 → C7 71 → C10 80 → C11 85 → C13 91. No built code is redone.

---

## Report A — data and world records (verbatim)

# Audit A — Cythera data and world records (CytheraCore Data/Segments/Codec/World), 2026-11-05

Read-only audit of tasks C1–C4 against the Phase 0 plan (S2, C1–C4) and the committed decompile. Suite run in a
scratch copy (`A-core`) against HectorKit at the path given; probes added only in that copy (`AuditAProbes.swift`).

| # | Finding | keep / change / redo / missing | File:line | Why | The fix (one sentence) |
|---|---|---|---|---|---|
| 1 | Cipher constants and seed match the code (HIGH, —) | keep | Segments/SegmentCipher.swift:12-20 | Dump and raw PPC agree: multiplier `(id&0x3F)·4+1`, increment `(id>>6)&0xFF`, seed `(id>>8)^id`, state stepped before each XOR, low byte used | none |
| 1b | `skip` = the `offset` loop, run before the byte loop (HIGH, —) | keep | SegmentCipher.swift:17 | `Encrypt` loops `param_4` times on the state before touching bytes; a negative skip loops ~2^32 times in the original, Swift ignores it (harmless) | none (optionally document negative skip = 0) |
| 2 | Map body offset: flat `0x20+C·0x80`, chunked `0x20+C·0x40` (HIGH, —) | keep | World/LevelMap.swift:55-57 | Dump p:899 (flat) and p:850 (chunked index read) | none |
| 2b | Chunked copy: 8 rows × 8 bytes of the first 64 bytes of each 128-byte record, row stride W bytes, +8 per block, `(W·7)&~3` per block row (HIGH, —) | keep | LevelMap.swift:98-127 | Matches p:856-892 line for line; synthetic probe reproduced the byte layout and the index array overlapping chunk record 1 | none |
| 2c | Side cap stricter than the original (MED, Minor) | change | LevelMap.swift:74 | `CreateGlobals` (p:388-392) only allocates D·D·2; it never checks W or H, so the real limit is W·H ≤ D²; Swift refuses any side > D (e.g. 0x400×0x100 under D=0x200) | Keep per-side cap but say in the doc comment it is an Invariant-4 refusal, not the original's rule (or cap W·H ≤ D²) |
| 2d | Chunked map with W or H < 8 yields all-zero cells; the original leaves the previous level's buffer (LOW, Minor) | keep | LevelMap.swift:98-127 | Zero blocks copied; original never clears the buffer on this path | Note it in the comment; unreachable by shipped data |
| 3 | Prop x/y/parent extraction matches `SetStage` and `GetPropParent` (HIGH, —) | keep | World/PropRecord.swift:24-28 | p:31375 `(short)(u32>>8)>>4`, p:31376 sign-extended low 12 bits, p:25064 `(short)u32` | none |
| 3b | Worked records 0x8102 #2 and #3 re-derived independently in Python (HIGH, —) | keep | Tests/PropTests.swift:44-50 | #2 = kind 0, x 10, y 32, type 39, frame 3, byte6 1, no mirror; #3 = kind 0x44, x 15, y 17, type 1 — test agrees | none |
| 3c | type/frame/mirror/spriteOffset6 bit maths right (HIGH, —) | keep | PropRecord.swift:30-48 | `&0x3FF`, `(b4>>2)&0x1F`, bit 7, sign-extend 6 bits | none |
| 4a | `SegmentOverlay` does not conform to `SegmentStore` (HIGH, Important) | change | Segments/SegmentOverlay.swift:39 | It has no `entry`, so `PropSegment(file:)` and `WorldGlobals(store:)` cannot read through an overlay; Phase 4 needs exactly that | Add `entry(_:)` (topmost store that has it) and conform the overlay to `SegmentStore` — additive |
| 4b | `LevelMap.init(file:level:)` takes the concrete `SegmentFile` (HIGH, Minor) | change | LevelMap.swift:60 | Confirmed; a save overlay CAN open a map today only via `LevelMap(data: overlay.segment(id)!, maxMapDimension: file.header.maxMapDimension)` (probe ran it: 64×64) | Add `init(store: some SegmentStore, level:, maxMapDimension:)` once 4a lands; no rename needed |
| 4c | `SegmentOverlay.write` is `throws`; S2 lists it non-throwing (HIGH, Minor) | keep | SegmentOverlay.swift:53 | Throws `slotZeroNotWritable` when slot 0 is not a memory store; a reasonable addition but a signature change to a ★ row | Record the deviation in D28 as-built |
| 4d | `LZ.decode(_:limit:)` and `LZError.outputLimit` added (HIGH, Minor) | keep | Codec/LZ.swift:13,40 | Additive, but a new case in a public enum breaks exhaustive `switch` in callers | Record in D28; fine before Phase 0 locks |
| 4e | Other ★ rows present as written: CytheraData, CytheraResources, SegmentFile (header fields, pages, entry, segment zero-based copy, scriptSegment, isSegmentFile, ids), SegmentCipher, LevelMap (header, chunks, cells, cell), MapCell, PropRecord (all 13 accessors), PropSegment, WorldGlobals (all 22 members), CharEntry (every §6.1 field), ScheduleEntry (HIGH, —) | keep | Data/*, World/* | Extras only (root, byteCount, init(data:), blockIndices, creatureTail, animationTerminatorOffset, count16, CytheraDataError.unreadable) | none |
| 5 | Prediction confirmed: `segment(0x0410)` = length byte 0x0E then "Attack Nearest"; `scriptSegment(0x0410)` = scrambled (HIGH, —) | keep | SegmentFile.swift:117-123 | Probe and Python both; 14 AI segments in 0x0410–0x0436 | none |
| 5b | Routing left to the caller is a trap (MED, Important) | change | SegmentFile.swift:117 | `scriptSegment` silently returns garbage for 14 present ids; any generic "read all script ids" loop (C9's listing, census) will hit them | Make `scriptSegment` return the AI band as stored (extend the plaintext rule to 0x0410–0x0436 with its own named set) or add `aiSegment(_:)` and have `scriptSegment` return nil there |
| 6 | Hostile prefixes through public initialisers: no trap (HIGH, —) | keep | WorldGlobals.swift, PropSegment.swift | F00B 5448 prefixes all threw; F009 16384 all threw; F004 5780 threw, 6 parsed (cuts after the terminator, trailing shortened); 0x8101 (6864 B) 6435 threw, 429 parsed (whole records) via `init(data:)`, 428 via a store | none |
| 6b | "Every prefix throws" is not literally true for 0xF004 and props (HIGH, Minor) | keep | WorldGlobals.swift:203-216; PropSegment.swift:26 | Prefixes on record boundaries are valid shapes; only "never traps" holds | Word the invariant test as "never traps; record-boundary cuts parse to fewer records" |
| 7a | Overlay reads equivalent for the 4-file case (HIGH, —) | keep | SegmentOverlay.swift:45-51 | `AddFile` (p:40682) shifts slots and `SetEntry`s every id of the new file with non-zero length (iterator p:39880 tests length) — newest file wins, same as topmost-wins | none |
| 7b | `RefindSegment` picks the BOTTOM-most file, not the topmost (MED, Minor) | missing | SegmentOverlay.swift | p:41013: loops slots 0..15 and keeps the last match, i.e. the oldest file, testing offset≠0; called only after compiling a user AI into the player file (p:55611) | Note it in the bank and model it in Phase 4 when user AI compile lands |
| 7c | Empty write reveals the lower store's copy; original SaveSegment points the id at slot 0 regardless (LOW, Minor) | change | SegmentOverlay.swift:31-33; SegmentFileTests.swift:210-211 | `SaveSegment__15TCachedSegFiles` (p:40968) always `SetEntry`s slot 0, so a zero-length save masks lower copies | Decide and document delete semantics before Phase 4 |
| 7d | Protocol cannot carry a writable file store (HIGH, Important) | missing | SegmentFile.swift:30-35; SegmentOverlay.swift:53-55 | `SegmentStore` has only `entry`/`segment`; `write` down-casts slot 0 to `MemorySegmentStore`; a save file needs write, TOC flush (`SaveTOC`) and encrypted save (`SaveEncryptedSegment`) | Add a `WritableSegmentStore` protocol (write, remove, flush) and have the overlay write through it |
| 7e | No encrypted read through the overlay (HIGH, Important) | missing | SegmentOverlay.swift | The original decrypts in `GetEncryptedSegment` on the cache (the overlay), so patch/save script segments are read decrypted from any slot; Swift offers `scriptSegment` only on `SegmentFile`, and S2 `ScriptDecoder` takes `in: SegmentFile` | Add `scriptSegment(_:)` to the overlay with the same plaintext rule |
| 8a | `AnimationRecord.tile(forFrame:)` still has no 0…7 guard (HIGH, Minor) | change | World/AnimationRecord.swift:25-28 | Probe: frame −3 → tile 9, outside the record's 10…12; no trap (divisor and count > 0) | Clamp or `frame & 7` as the caller's 8-frame counter does, or return nil outside 0…7 |
| 8b | `LZ.decode(_:limit:)` still accepts a negative limit (HIGH, Minor) | change | Codec/LZ.swift:40-43,56-58 | Probe: limit −5 on terminator-only stream returns 0 bytes; any output throws `outputLimit(-5)`; Int.min also throws cleanly — no trap | Throw `outputLimit` up front for limit < 0 |
| 8c | F007 length check still partly tautological (HIGH, Minor) | change | Tests/WorldGlobalsTests.swift:276 | `2 + 33·5 == f007.count` re-asserts what `checkF007` already enforced (WorldGlobals.swift:147-150) | Replace with a check against the TOC length or a record field value |
| 9 | Suite 44 passed / 0 failed / 0 skipped; CytheraCoreTests 34 (Data 5, Segment 9, LZ 6, LevelMap 4, Prop 3, Globals 7), CytheraRenderTests 10 (HIGH, —) | keep | — | Measured in the scratch copy | none |

## Re-derivations

**1. Cipher.** `Encrypt__8TSegFileFPvlUsl @ 1007ba30` (p:40171-40192; raw listing 1007ba30-1007bab0): r31 =
`((id<<2)&0xFC)+1` (multiplier), r30 = `(id>>6)&0xFF` (increment), r5 = `((id&0xFFFF)>>8) ^ id` (seed). First loop:
`r6` (the `offset` argument) times `state = inc + state·mult`; second loop, per byte: step, then `byte ^= low byte`.
`Decrypt` (p:40195) just calls it; `GetEncryptedSegment` (p:40796) calls `Decrypt(buf, length, id, 0)` after the
load. Swift (SegmentCipher.swift:12-20) is identical; the upper 16 bits of the seed never reach the low byte.

**2. Map body and side.** `LoadLevelMap__Fs @ 10005cb8`: header 0x20 bytes, chunk records at 0x20 for `C<<7`
bytes (p:839-843); chunked when `hdr+6 < hdr+8` (p:845); block index read at `C·0x40+0x20`, `(W>>3)·(H>>3)·2`
bytes (p:850-853); each block copies record words 0..15 two per row with a W-byte stride (p:858-889), `+8` bytes
per block, `(W·7)&~3` per block row (p:892). Flat path reads `W·H·2` at `C·0x80+0x20` (p:897-901).
`CreateGlobals__Fs @ 10004d0c` sets D from its argument, 0 → 0x400, `NewPtr(D·D·2)` (p:388-392). Swift
LevelMap.swift:55-57, 98-127 match; the per-side cap at :74 is stricter than D².

**3. Props.** `SetStage__7TViewerFss @ 10065034` p:31375-31377: x = `(short)(u32>>8)>>4`, y = low 12 bits of
`u16@2` sign-extended. `GetPropParent__FP8PropItem @ 10055d4c` p:25055-25075 returns `(short)u32` for kinds
0x08–0x0B, 0x10, 0x18 (and 0x42 frame 9). PropRecord.swift:24-28 match; worked records re-decoded from the raw file.

**7. Overlay.** `AddFile` p:40680-40700: shift slots 15..1, store in slot 0, iterate the new file's ids
(`TSegFileIterator::++` p:39878 skips length-0 slots) and `SetEntry(id, file)` (p:40729) — owner = newest. For
data+patch+save+scratch this equals "topmost store that has the id". `RefindSegment` p:41013-41040 and
`SaveSegment` p:40968-40975 are the two places the models part.

## Probes run (scratch copy only)
Every prefix of 0xF00B, 0xF004, 0xF009 through `WorldGlobals(store:)`; every prefix of 0x8101 through
`PropSegment(data:)` and `PropSegment(file: MemorySegmentStore)`; 0x0410 through `segment` vs `scriptSegment`;
a map through an overlay via `LevelMap(data:)`; a synthetic chunked map (layout, index overlap, all 288 prefixes,
W < 8, negative D); `LZ.decode(limit:)` with −5 and Int.min; `tile(forFrame:)` over −3…9 and Int.min. No traps.

---

## Report B — render and pictures (verbatim)

# Audit B — Cythera render layer and pictures (task C5), 2026-11-05, read-only

Scope: the render layer's picture types (`Cythera/Core/Sources/CytheraRender/Pixels/`) and the art records
(`Cythera/Core/Sources/CytheraCore/Art/`). Suite run in a scratch copy (`scratchpad/B-core`): 44 tests, 0 failed,
0 skipped; the render test target 10/10. Probes (scratch-only tests `ProbeB`, `ProbeB2`, never in the repo): compo
entries vs the animation table, absent sheets, the pix padding bytes, Catamarca, the Land King Hall walk, the two cluts.

| Finding | keep / change / redo / missing | File:line | Why | The fix (one sentence) |
|---|---|---|---|---|
| Q1a Compo-tile bit rule and output placement | keep (HIGH) | TileStore.swift:62–71 | Matches BuildCompoTile @ 100051a8 exactly: tile = low 12 bits, bits 14–15 = source column ×8 px, bits 12–13 = source row ×8 rows, entry k lands at row k/4, column k%4 | none |
| Q1b Compo tiles read the frame-0 pointer table, not the current frame | change (HIGH, Important for Phase 1) | TileStore.swift:54–57 (doc), 66 | The listing loads the table base from TOC 0x100cdc28 with no frame offset (100051b0, 100051fc); plain tiles in MaskAnyTile add frame × 0x2800, compo tiles do not. So compo tiles never animate, and they see frame 0 AFTER the animation table rewrote it (tile 1275 → tile 1274's pixels). The Swift reads raw store bytes (identity), and its comment says "current-frame". No shipped compo entry touches an animated tile (probe: 0 of 4,224 entries), so no shipped picture differs today | Fix the comment to "frame 0 always", and in Phase 1 let `compoTile` take the frame-0 pointer table instead of the raw store |
| Q1c Refusing entries ≥ 0xA00 | keep (HIGH) | TileStore.swift:64 | The original would read frame 1's pointer for tile e − 0xA00; no shipped entry does (max 0x9FF, probe) | none; optionally pin "max entry 0x9FF" in the test |
| Q1d Test does not pin any real compo tile's bytes | change (MED, Minor) | TileStoreTests.swift:76–85 | It only checks the 264 records build; a SHA of all built compo tiles would catch a later regression | Add one digest over the 264 built compo tiles |
| Q2 Sheet range 0x8E00–0x8E9F and absent sheet → zeros | keep (HIGH) | TileStore.swift:14, 20–29 | LoadTiles @ 10005080 breaks at s > 0x9F; `Loaded()` false → memset 0x4000; 160 × 16 = 0xA00 tiles. Confirmed: only 0x8E96 absent, tiles 0x960–0x96F all zero, tile 0x19C has 1,024 non-zero pixels; 0x8EFF exists and is never read | none |
| Q2b A malformed (present) sheet throws instead of zero-filling | keep (MED, Minor) | TileStore.swift:24 | The original's `Loaded()` would also be false on a load failure and zero the sheet; refusing is the Invariant-4 posture, worth one comment | Note in the comment that the original zero-fills any sheet it could not load |
| Q3 Pix row padding | keep (HIGH) | PixImage.swift:28–30 | LoadPixs__FPUcssR6PixMap @ 10073d8c sets rowBytes = (w+3)&~3 \| 0x8000 and allocates rowBytes × h, then LZ-decodes unbounded into it. The padding is in the stream: the padding bytes carry real non-zero data (0x8F04: 193 bytes, 0x8F81: 208), so the loader's rowBytes and the stream agree | none |
| Q4a FILT layout | keep (HIGH) | DisplacementFilter.swift:20–34 | LoadDisplacementFilters @ 100052a0: bytes 0–3 copied as one state word (hold, counter), 32-byte mask from +4, frames from +0x24 to the handle's end; offsets are signed (`extsb` at 10005484); mask bit order bit (i&7) of byte (i>>3) tested on the SOURCE pixel | none |
| Q4b "Prefix on a frame boundary is a shorter valid filter" | keep (HIGH) | PaletteAndMasksTests.swift:125–135 | No count field; AdvanceDisplacementFilters @ 10005520 wraps when frame pointer ≥ handle end, so k whole frames behave as a k-frame filter. Refusing N = 0 and partial frames is stricter than the original (which would read past the handle) | none |
| Q4c Displaced reads can leave the tile | missing (HIGH, Minor, Phase 1) | DisplacementFilter.swift:6–7 | `in[i + offset]` with offsets −128…127 reads outside the 1,024-byte tile into whatever buffer surrounds it (the tile store neighbour) | Say so in the comment; Phase 1's filter must read from the store, not a lone tile copy |
| Q4d Hold/counter semantics not modelled | missing (MED, Minor) | DisplacementFilter.swift:11–12 | Counter 0 → reload from hold and step; else decrement — a step every hold+1 calls; Phase 1 needs this | Leave to Phase 1; record the rule in the comment |
| Q5a Data file's clut first | keep (HIGH) | CytheraResources.swift:45–47 | `data` then `app`; the test checks the chain's answer equals the data clut | none |
| Q5b `Palette.clut256` bypasses the chain | change (HIGH, Minor) | Palette.swift:31–33 | It reads `resources.data` directly; same answer today, but the comment claims "what resource(type:id:) returns" | Use `resources.resource(type:id:)` for `.dataFile` |
| Q5c Index 0 opaque in `Palette` | keep (HIGH) | Palette.swift:8, 24–27 | Transparency of 0 is the tile mask rule (FindBoundsRect @ 10005640, mask copies); CopyBits pictures and the offscreen erase (0xFF) are opaque, so the compositor must apply alpha per blit, not per palette | none |
| Q5d The four differing clut entries are VISIBLE | change (MED, Important, carry to Phase 1 gate) | Palette.swift:4–7 | Probe: entry 0 white (data) vs 0xFC grey (app); entry 16 0xF0 vs 0xFC grey; 252/253 dark blues (0x61, 0x29) vs black. An 8-bit Mac screen forces index 0 white and 255 black, which favours the data clut for entry 0 (LOW) | Record the four colour pairs in the Phase 1 gate card, not just "four differ" |
| Q5e Name `argb` vs `rgba(_:)` | change (HIGH, Minor) | Palette.swift:20, 40 | The function is named rgba but returns 0xAARRGGBB (S3 locked the name) | Leave the name (locked), fix the doc to say ARGB words |
| Q5f "as QuickDraw's Color2Index uses it" unverified | change (LOW, Minor) | ColorTableRecord.swift:57 | No citation for the high-byte claim; it is the obvious rule but unsourced | Cite or soften |
| Q6a 21 PICT outcomes and the screenshots | keep (HIGH) | StoredPictureTests.swift:11–77 | 11 indexed-rect, 3 indexed-rgn (data 131, 512, 513, flags 0x8000), 1 direct16 (data 129, mode 36), 6 direct32 (133–138, mode 0). Catamarca: direct16 640×480 mode 0 (prediction confirmed); Land King Hall refused "0x8200 QuickTime" | none |
| Q6b The opcode walk duplicates the kit | change (HIGH, Minor, kit carry) | StoredPicture.swift:110–134 | It repeats the kit's state-op table (PICT+Pixels.swift:164–185) plus 0x0007 and 0x0030–0x0034, only to reach past 0x0032; the kit throws `unsupportedOpcode(50)`. A kit error naming the first bits opcode (D14) removes it | Keep until the kit carry lands, then delete |
| Q6c The kit already has a 0x8200 decode path | missing (LOW, Minor) | HectorKit PICT+QuickTime.swift, CodecImage.swift | Land King Hall might decode through it; it is an oracle file so refusal is fine for Phase 0 | Note for Phase 1 if the screenshot is wanted as an oracle image |
| Q6d Indexed mode test pins 0 but indexed tables' meaning untested | change (MED, Minor) | StoredPictureTests.swift:26–33 | Rect pictures' tables (flags 0) map by value, Rgn ones by position; nothing pins a value ≠ position case | Pin one Rect table's value order |
| Q7a `TileStore.bytes` flat `let` array | keep (HIGH) | TileStore.swift:18 | Phase 1's 8 × 0xA00 pointer tables are offsets into it; transposed and masked copies are derived buffers | none |
| Q7b `IndexedImage` immutable | change (MED, Minor) | IndexedImage.swift:33–37 | The (N+1)·32 square offscreen and the light map need a mutable buffer; a separate mutable type is cleaner than widening this one | Add a mutable framebuffer type in Phase 1; keep this one |
| Q7c `compoTile` shape | change (HIGH, Important) | TileStore.swift:58 | Takes the raw store; must take the frame-0 pointer table (Q1b); also allocates and throws per call — cache built compo tiles per pointer-table rebuild | Change signature in Phase 1 |
| Q7d `Palette` as 0xAARRGGBB | keep (HIGH) | Palette.swift:20 | Fine as a presentation lookup; the light pass writes indices (0xFF fill, SubLight*) before conversion | none |
| Q7e `tile(_:)` returns empty slice out of range | change (MED, Minor) | TileStore.swift:45–47 | A silent empty slice hides a bad index (Invariant 5 names errors) | Return nil or throw |
| Q7f Unused HectorAudio dependency on CytheraRender | keep (HIGH, Minor) | Package.swift (CytheraRender target) | No file imports it yet; C6 sound lands there | none |
| Q8 Layering greps (G7) | keep (HIGH) | Cythera/Core/Sources | Both greps empty | none |
| Q9 Suite | keep (HIGH) | scratch copy | 44 / 0 / 0; CytheraRenderTests 10 | none |

## Re-derivations

**Compo tile (Q1).** `BuildCompoTile__FPUcP15CompoTileRecord @ 100051a8` (p:488–521, listing 100051a8–10005260):
three loops — quadrant row 0–3, pixel row 0–7, quadrant column 0–3 — read entry `record[col]` (record pointer moves 8
bytes per quadrant row), copy 8 bytes as two words to the output, which simply advances, so entry k lands at output
offset (k/4)·256 + row·32 + (k%4)·8 — the Swift `dst` (TileStore.swift:67). Source = `table[e & 0xFFF]` +
`((e>>8)>>3 & 0x18)` + `((e>>8) & 0x30)·0x10` + row·32: bits 14–15 pick the column (0, 8, 16, 24 bytes), bits 12–13 the
row (0, 256, 512, 768 bytes = 8 rows each) — the Swift `src` (line 66). The table is loaded once from TOC 0x100cdc28
(`lwz r25,-30296(r2)` at 100051b0) and indexed with no frame term (`lwzx r8,r25,r0` at 100051fc), while
`MaskAnyTile__7TViewerFUsll @ 10063b9c` adds `viewer+0xBA × 0x2800` only for plain tiles. The table is built in the
globals loader (p:729–752): every frame's entry t = store + t·0x400, then 0xF001 rewrites entries to
`base + (f/div mod n)`, so frame 0 of tile 1275 points at tile 1274 (shipped record t1275 b1274 n2 d4). An entry
0xA00–0xFFF reads `table[1][e−0xA00]`. Refusal is the right Phase 0 posture (no shipped entry; max 0x9FF).

**Tile range (Q2).** `LoadTiles__Fv @ 10005080` (p:449–485): `while (s ≤ 0x9F)`, a TSegLoad of 0x8E00 + s;
not loaded → `memset(store + s·0x4000, 0, 0x4000)`; else LZ into the same place. Swift TileStore.swift:20–29 is the
same, stricter in requiring exactly 0x4000 bytes and full consumption.

**Pix padding (Q3).** `LoadPixs__FPcR6PixMap @ 10073d04` passes w, h from the first two shorts;
`LoadPixs__FPUcssR6PixMap @ 10073d8c` (p:36938–36960) sets bounds (0,0,w,h), rowBytes `(w+3) & 0xFFFC | 0x8000`,
`NewPtr(rowBytes·h)`, then the LZ decoder. `LoadPattern__13TBackdropWindFv @ 100382cc` uses it for 0x8F00 + ordinal
(ordinal 0–1 only). The streams themselves are rowBytes·h long with real data in the pad columns, so both agree;
PixImage.swift:28–30 keeps the padding as rowBytes.

**FILT (Q4).** Loader p:524–563, tile filter p:567–600 (listing confirms `extsb` on the offset at 10005484), advance
p:604–636 — as in the table. The displaced pixel is chosen by the source pixel's colour bit; the filter is skipped
entirely when a preference bit (byte 0x100d3e21 bit 3) is off.

**Palette (Q5).** CytheraResources.swift:45–47 searches `data` first. Data vs app clut entries (probe): 0 = FFFF vs
FC00 grey; 16 = F000 vs FC00; 252 = (0, 2, 6184) vs black; 253 = (0, 1, 29DC) vs black.
