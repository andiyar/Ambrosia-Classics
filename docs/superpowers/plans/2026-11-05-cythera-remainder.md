# Cythera — the remainder: implementation plan (Phase 0b, Phase 1 research, Phases 1–8 as cards)

> **For agentic workers:** the method is `~/Developer/Toolkits/fable-kit/orchestrator.md` — one `fk-implementer` and
> one `fk-reviewer` per task, two reviewer legs per ⚑ MAJOR task, Opus 5.5 throughout with no `model` param (Ben
> 2026-10-07; `CLAUDE.md`); Fable only on a contraindication, and only after asking Ben. Plans in this house carry
> **contracts, not code** (Ben, 2026-10-03): files with line anchors, APIs, test names, commands, commit messages.
> Steps use checkboxes.

**Goal:** finish Phase 0 (the decoders and the census), then build Cythera to its first gate (the player walking
Catamarca) and beyond, in the design's gate order, on checked ground.

**Architecture:** the spec's "The shape of the whole program" — `CytheraCore` (rules, scripts, world, state, the
window model, saves), `CytheraRender` (pixels, audio, text, the map, the desktop), thin shells. One instruction walker
shared by the decoder and the VM; one state model (the spec's "The one state model"); derived data rebuilt, never saved.
The design this builds is `docs/superpowers/specs/2026-11-05-cythera-remainder-design.md` (referenced by heading).

**This file is the authority for the remaining work; the earlier plans and the audit are history.** Every remaining
task card is here in full, with the 2026-11-05 audit's corrections already written into its text.

**Tech:** Swift 6 / Xcode 27 beta, SwiftPM, XCTest; HectorKit by local path (`HECTORKIT_PATH` or `../../../HectorKit`);
Python 3 (stdlib, run with `-I`) only as the parity oracle and one-off generator — never a build or test dependency.

---

## 0. The verification model (fable-kit; read before any dispatch)

| rule | what it means here |
|---|---|
| Numbers from the seat's own runs | every count in a close note comes from a command the seat ran (G2 from the merge head); a subagent's number is never relayed on faith |
| One implementer + one reviewer per task; two legs per ⚑ | the second leg re-derives one rule from the dump and confirms one numeric prediction; it builds in a scratch copy, never the worktree |
| Reviewers run things | `swift test --filter <Class>` in their copy; the parity hash list regenerated and diffed; a review that only reads the diff is not a review |
| The dump beats the bank beats the plan | the decompile is committed at `ghidra/cythera/`; every brief says "re-read each cited line before coding; record disagreements in As executed" |
| Hostile input | every decoder throws a named error, never traps; a cut on a record boundary parses to fewer records (so the "every prefix" tests assert "throws or parses to fewer records", never "every prefix throws") |
| Invariant 10 | any unexpected number (count, hash, offset, test total, census line): STOP, report the command output; never edit an expectation to agree |
| Scope fence (G6) | the diff ⊆ the task's Files (+ `docs/DECISIONS.md` where the task says so); explicit paths only, never `git add -A`, never `git stash` |
| Launches | nothing with a window in Phase 0b or the research wave; from Phase 1a the shell is launched only by Ben or by a session he has told to, headless goldens otherwise |
| Ben's gate | a phase closes on the machine side only: "machine gates green; Ben's gate pending" |
| Context | 300k per orchestrator; size a session by context, not task count (Ben 2026-11-04); at ~240k close; a session that cannot merge records why and keeps its worktree |
| HectorKit | pin **ef2c341 / floor 370** (Ben's ruling, 2026-11-05; the spec's "The HectorKit re-base"); a later clean main is accepted at ≥ floor and its SHA/floor recorded at the merge |

**Paths** (each session: `EnterWorktree`; the worktree reaches HectorKit through `.claude/worktrees/HectorKit →
~/Developer/HectorKit`, which exists):
```
WT      = the session's worktree (branch of its own; the orchestrator merges to main)
HK      = /Users/andiyar/Developer/HectorKit                      (main ef2c341, floor 370; never build or write in it)
G       = "/Users/andiyar/Developer/Ambrosia/Resources/ambrosia-extracted/RPG/Cythera/Cythera (installed)/files"
SCRATCH = the session's scratchpad (logs, canon files, PNGs; never the repo)
LISTINGS= $WT/ghidra/cythera/cythera-scripts                       (958 committed listings = the parity oracle)
AKI     = "/Users/andiyar/Developer/Ambrosia/Resources/Aki - Mahjong Solitaire/Aki - Mahjong Solitaire.app/Contents/Resources"
```

**Gates:**

| gate | command | expected |
|---|---|---|
| G1 HectorKit | `git -C "$HK" log --oneline -1`; `HECTORKIT_DATA_AKI11="$AKI" HECTORKIT_TEST_LOG="$SCRATCH/hk.log" "$HK/tools/check-zero-skip.sh" 2>&1 \| tail -n 1` | `ef2c341` (or a later clean main, recorded); `PASS: zero skips, zero failures, executed N == floor N`, N ≥ 370 (the script's default Aki path is stale — the override is mandatory until HectorKit fixes it) |
| G2 suite | `cd "$WT/Cythera/Core" && swift test > "$SCRATCH/cy.log" 2>&1; grep -cE "^Test Case '.*' (passed\|failed\|skipped) \(" "$SCRATCH/cy.log"; grep -cE "^Test Case '.*' (failed\|skipped) \(" "$SCRATCH/cy.log"` | the ladder total, then `0` |
| G3 census (C11 on) | `cd "$WT/Cythera/Core" && swift build -c release --product cythera-census > /dev/null && "$(swift build -c release --show-bin-path)/cythera-census" "$WT/Resources/Cythera" > "$SCRATCH/census.md"; echo $?; tail -n 1 "$SCRATCH/census.md"` | `0`; `Totals: segments 1,558 (decoded 1,557 · no reader 1) · resources decoded 198 · files 14 · failures 0` |
| G4 data = archive | `cd "$WT/Resources/Cythera" && for f in *; do cmp "$f" "$G/$f" \|\| echo "DIFF $f"; done; ls \| wc -l` | no DIFF; `20` |
| G5 apps untouched | `cd "$WT" && xcodegen generate && for s in Aki BubbleTroubleX; do xcodebuild -scheme "$s" build 2>&1 \| tail -n 1; done` | `** BUILD SUCCEEDED **` ×2 (Phase 0b adds no app target) |
| G6 scope fence | `git -C "$WT" diff --name-only <task base>..HEAD` | ⊆ the task's Files |
| G7 layering | `grep -rnE "^import (AppKit\|UIKit\|SwiftUI\|CoreGraphics\|CoreText\|ImageIO\|AVFoundation\|QuartzCore\|AudioToolbox)" "$WT/Cythera/Core/Sources" \| grep -v "Sources/cythera-census/"`; `grep -rnE "^import (HectorGraphics\|HectorAudio)" "$WT/Cythera/Core/Sources/CytheraCore"` | both empty (both empty at 44 tests, 2026-11-05). `Sources/cythera-census` may import ImageIO behind `#if canImport(ImageIO)` for `--render` |
| G8 parity (C9 on) | the recipe in C9 step 6 | 958 lines, every hash equal |
| G9 clean tree | `git -C "$WT" status --porcelain \| grep -v '^??'` | empty after every commit |

**Ladder (`Cythera/Core`, cumulative, in THIS merge order; base 44 = 34 core + 10 render):**
C8 **50** → C9 **57** → C6 **63** → C7 **71** → C10 **80** → C13 **86** → C11 **91** (C9 carries 7 tests because it
also fixes the combat-AI read; C13 is the audit's seam task). A different merge order: previous + the task's N (C8 6,
C9 7, C6 6, C7 8, C10 9, C11 5, C13 6).

`pNN` beside a number = the October planner's probe of that number (2026-10-06, re-measured where the text says so);
the number stands as written, and Invariant 10 applies if it disagrees.

---

## 0b. Done before this plan, the binding invariants, the locked surface

**Done (on main; not repeated here):**

| task | what it built | numbers |
|---|---|---|
| K1 | HectorKit `PICT.decodePixels` takes 0x0099/0x009B region opcodes and 16-bit DirectBits; direct modes {0, 36, 64} as stored | HectorKit 4ca2e18, floor 322 (since re-based to ef2c341 / 370) |
| C0 | `Resources/Cythera/` = 20 files byte-identical to the archive | G4: 20, no DIFF |
| C1–C2 | package skeleton, `CytheraData`, `CytheraResources` (data file first, then app), `SegmentFile` (TOC, cipher, `segment` returns a zero-based copy, `scriptSegment` decrypts except 0x0101/0x0210), `SegmentOverlay` (in memory) | suite 14 |
| C3–C5 | `LZ` (all 378 streams), world records (42 maps, 14,485 props, 20 globals typed; 0xF001 = 8 records + the zero terminator, 66 B; 0xF009 is 0x4000 B), CytheraRender pixels (tiles, portraits, sky, pix with 4-byte-padded rows, macro icons, palette, compo tiles, Lite/FILT, PICTs as stored) | suite 44 |

**Invariants (every task; a reviewer checks them):**
1. **Layering.** `CytheraCore` imports Foundation + HectorResources only — no pixels, no PCM. `CytheraRender` adds
   CytheraCore, HectorGraphics, HectorAudio. Only `Sources/cythera-census` may import ImageIO (behind
   `#if canImport(ImageIO)`); `CytheraCensus` itself lives in CytheraRender and hands the executable indexed buffers +
   palette. Windows traps: no `String.Encoding.macOSRoman` — use `HectorResources.MacRoman.decode`; resolve symlinks
   before enumerating; no `FileManager` tricks on paths with spaces.
2. **Decode as the original reads, not as the format's ideal** — the `asnd` zero tail kept, 0x0101/0x0210 never
   decrypted, the stale `FOND 128` association left as stored, NFNT's short owTable — each with a doc comment citing the
   bank section.
3. **Refuse what the census has not shown:** any shape outside the measured corpus throws a named error with a
   synthetic test — a QTMA word with an undefined type nibble (8, 0xC, 0xD, 0xE), an `asnd` whose length ≠
   blocks·0x800 + 0x40C, a script opcode the tables mark invalid.
4. **Hostile input:** every read bounds-checked; malformed input throws, never traps, never allocates from an unchecked
   size (`count × stride ≤ data.count` before allocating); every decoder gets a prefix test (throws or fewer records).
5. **Commits:** explicit paths only, never `git add -A` / `git add .`, never `git stash`; the trailer above; G9 after
   each commit.
6. **STOP on any unexpected number** (counts, hashes, offsets, test totals, census lines): report the command output;
   never edit an expectation or the code to make them agree. The decompile is committed at `ghidra/cythera/`; re-read
   each cited line before coding.
7. **Landmines.** (a) `swift test` has no package-wide total: count `^Test Case` lines (G2). (b) `swift run` mixes build
   output into stdout: run the built binary (G3). (c) SwiftPM rejects a declared target with no sources — C11 is the
   only task that adds targets (the executable + `CytheraCensusTests`). (d) File names with spaces and no extension
   (`Cythera Data`, `AI Scripting Document`): quote every path. (e) D-numbers collide across sessions: confirm the
   number at commit time. (f) Two different `clut 256` resources exist (app and data file, differing in entries 0, 16,
   252, 253): every palette consumer names which one it used; the data file's is the default. (g) `0x8EFF` sits in the
   tile-sheet page but is NOT a tile sheet (4,694 B, not LZ, read by nothing): the census lists it as "no reader".
8. **Hazards carried:** the C8/C9 decoder must not "fix" the 0x9C `FFFF` encoding it lists (the VM's stack must not
   clear popped slots — script-vm.md §3, §8); the 168 QTMA value-1 end markers + TuneDifference events are decoded and
   counted, not interpreted (C7); `Land King Hall screenshot.pict` is QuickTime-compressed (0x8200) — a named refusal,
   never a census failure; `Cythera Documentation`'s data fork is 0 bytes (only the `.rsrc` is committed).

**The locked public surface the remaining Phase 0 tasks create** (★ = locked after Phase 0; later phases add, never
rename):
- Package (C11 completes it): `Cythera/Core/Package.swift`, tools 6.0, macOS 15, dependency
  `.package(path: Context.environment["HECTORKIT_PATH"] ?? "../../../HectorKit")`. Products: library `CytheraCore`,
  library `CytheraRender`, executable `cythera-census`. Targets: `CytheraCore` (HectorResources), `CytheraRender`
  (CytheraCore, HectorResources, HectorGraphics, HectorAudio), `cythera-census` (CytheraRender + the kit products it
  needs); tests `CytheraCoreTests` (CytheraCore, HectorResources), `CytheraRenderTests` (CytheraRender + kit incl.
  HectorGraphics for the `Ditl` oracle), `CytheraCensusTests` (`cythera-census`, CytheraRender).
- ★ Script (CytheraCore, C8/C9): `ScriptInstruction` (`offset`, `length`, `mnemonic: String`,
  `flag: .reached/.jumpTarget/.dead`, plus C8's `jumpTargets`, `kind`), `ScriptSegmentListing` (`id`,
  `kind: ScriptSegmentKind` (.class, .routine, .strtab, .dict, .array, .data, .ai), `length`, `instructions`),
  `ScriptDecoder.listing(_:in:)`, `ScriptCanonical.text(_:)`.
- ★ UI records (CytheraCore, C10): `DialogTemplate` (DLOG), `DialogItemList` (DITL items: rect, type byte, text/handle
  bytes), `WindowTemplate` (WIND), `ControlTemplate` (CNTL), `AlertTemplate` (ALRT), `MenuResource` (MENU: id, width,
  height, procID, enableFlags, title, items (name, icon, key, mark, style)), `MenuBar` (MBAR ids), `StringList` (STR#),
  `PascalString` (STR), `TextStyle` (TxSt: size, raw style byte, font name), `FontFamily` (FOND: flags, familyID,
  firstChar, lastChar, associations (size, style, fontID)), `StartRects` (nrct 128: 8 rects), `PrefDefault` (Pref:
  name, u32).
- CytheraRender (C6, C7, C10, C11): `BitmapFont` (NFNT: header fields, `locTable`, `owTable`,
  `glyph(_ c: UInt8) -> (bits: [UInt8], width: Int, offset: Int)?`); `SoundSegment` (`'asnd'` → `blocks`,
  `sampleRate`, `samples [Int16]` as stored, `trimmedCount`; `func pcm() -> SndPCM`;
  `static func from(snd: SndSound) -> SoundSegment` = the converter rule); `TuneSequence` (QTMA: `description` fields,
  `headerEvents [TuneEvent]`, `events [TuneEvent]`, `parts [NoteRequestPart]`); `TuneEvent` (enum: `.rest(duration)`,
  `.note(part, pitch, velocity, duration)`, `.extendedNote(part, pitch16, velocity, duration)`,
  `.control(part, controller, value)`, `.extendedControl(part, controller, value)`, `.knob(part, knob, value)`,
  `.marker(subtype, value)`, `.general(part, subtype, payload [UInt32])`); `CytheraCensus`
  (`static func render(dataDirectory: URL) -> (stdout: String, failures: Int)`,
  `static func renderImages(dataDirectory: URL) -> [(name: String, image: IndexedImage, palette: Palette)]`).
- Tests read data through `CytheraData.dataDirectory()`; `CYTHERA_DATA` overrides; a missing file is a FAILURE naming
  the path, never a skip.

---

## Risk waves

| wave | what | risk it retires | sessions |
|---|---|---|---|
| 0 | the audit (this session, read-only) | "the built half is sound" is a claim, not a check | — |
| 1 | **Phase 0b**: C8 → C9 (session A); C6 ∥ C7 ∥ C10 (session B); C13 → C11 → C12 + the re-base record (session C) | the script decoder's fetch is proven on all 22,166 instructions before any VM exists; the census closes Phase 0 | 3 |
| 2 | **R1** Phase 1 research (one session, no code) | every Phase 1 number measured before a build task exists | 1 |
| 3 | Phase 1a — the still picture (gate: the Catamarca screenshot) | the frame loop, the palette question, the fonts, the window model | ~4 |
| 4 | Phase 1b — walking (gate: the player walks, roofs lift) | movement, the turn/frame split, the thread model | ~2 |
| 5 | R2 + Phase 2 — the world runs (gate: a day in Catamarca) | the VM proven by the bank's worked examples | ~7 |
| 6 | Phase 3 talk · Phase 4 start + saves | the save format both ways | ~8 |
| 7 | Phase 5 items + shops · Phase 6 fights + magic | the rest of the rules | ~10 |
| 8 | Phase 7 the whole story · Phase 8 Windows + docs viewer + release | the end | ~8 |

---

## Wave 0 — the audit (done 2026-11-05)

Done. Two read-only `fk-reviewer`s (the spec's "The audit of the built work") checked the data and world records and
the render layer against the decompile: every re-derived rule matched, no built code is redone, and what they found
(seams between parts and three carried minors) is written into the cards below — C9 (the combat-AI read), C13 (the
seams), C12 (the recorded deviations), 1a-TB, 1a-RN, the 1a gate card and the Phase 4 save card.

---

## Wave 1 — Phase 0b (three Opus 5.5 orchestrator sessions)

Every task: G2 (its ladder number), G6, G7, G9; ⚑ tasks two reviewer legs. Commits carry the trailer
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Read §0 and §0b first. Paths in the cards below are
relative to `Cythera/Core/` unless they begin `docs/`.

### Session A — C8 then C9 (both ⚑)

#### Task C8 — ⚑ script instruction decoder (→ 50)

**Scene.** Native code sends selectors to bytecode; the replica's VM (Phase 2) fetches instructions through the
decoder this task builds, and C9 proves that fetch on every shipped instruction against `scriptdis.py`. This task
decodes one statement or expression at a time; it does not classify segments, walk reachability or execute.

**Files.**
- Create `Cythera/Core/Sources/CytheraCore/Script/ScriptOpcodes.swift` — the statement table (script-vm.md §4 rows
  0x00–0x9F) and the expression table (§5 rows 0x00–0x64, 0x9B–0x9F, ≥ 0xA0), each row = (opcode, mnemonic, operand
  form); invalid: statements 0x80 and 0x94–0x9A, expressions 0x65–0x9A (§8 "0x82 with a slot byte ≥ 0x40 consumes only
  the slot byte"; 0xFF is a null-table call in the original — refuse it by name).
- Create `Cythera/Core/Sources/CytheraCore/Script/BuiltinNames.swift` — the 95 names, verbatim from
  `docs/cythera/tools/scriptdis.py` lines 39–135 (`BUILTINS`), 0xA0–0xFE; these are the listing's tokens and the
  parity form's vocabulary.
- Create `Cythera/Core/Sources/CytheraCore/Script/ScriptInstruction.swift` — S2's `ScriptInstruction` (`offset`,
  `length`, `mnemonic: String`, `flag: .reached / .jumpTarget / .dead`) plus `jumpTargets: [Int]` (absolute offsets in
  the segment; script-vm.md §8 "all branch operands are absolute") and `kind: .statement / .expressionOnly`.
- Create `Cythera/Core/Sources/CytheraCore/Script/InstructionDecoder.swift` — `enum InstructionDecoder` with
  `static func statement(in bytes: [UInt8], at offset: Int) throws -> ScriptInstruction` and
  `static func expressionEnd(in bytes: [UInt8], at offset: Int) throws -> Int` (the offset just past the 0x40
  terminator); errors `ScriptDecodeError.{invalidOpcode(offset, byte), truncated(offset), textRunsPastEnd(offset)}`.
- Create `Cythera/Core/Tests/CytheraCoreTests/InstructionDecoderTests.swift`.
- `SegmentFile.scriptSegment(_:)` (`Segments/SegmentFile.swift:128–134`) is the input for script pages; the AI band
  0x0410–0x0436 is NOT this task's (C9 routes it through `segment(_:)`, line 118).

**Contract** (every rule cites script-vm.md; `scriptdis.py` is the oracle where they disagree — report the disagreement):
1. Statements (§4): 0x00 no-op (1 B); 0x01–0x7F literal text running to the first byte that is 0 or ≥ 0x80 **with the
   pc left ON that byte** (§8 first ⚑; the terminator is the next statement); 0x81 a b (3 B); 0x82 slot + expr (slot
   ≥ 0x40: 2 B, no expr); 0x83 u16 + expr; 0x84 three exprs; 0x85 u16 u16 + expr; 0x86 field obj value (byte + two
   exprs); 0x87 byte + expr; 0x88 u16; 0x89 expr + u16 n + n×u16; 0x8A/0x8B expr; 0x8C/0x8D expr + u16; 0x8E (1 B);
   0x8F C string **then the terminator byte is skipped** (§8 second ⚑); 0x90 text + u16; 0x91 (1 B); 0x92 byte + expr;
   0x93 expr; 0x9B cls8 + one arg expr; 0x9C seg16 + (seg ≠ 0xFFFF: one int expr) + one arg expr; 0x9D sel8 + one
   expr; 0x9E off16 + one expr; 0x9F seg16 + one expr; 0xA0–0xFE one arg expr; invalid as listed.
2. Expressions (§5, RPN until 0x40): 0x00–0x3F 1 B; 0x41 2 B; 0x42 3 B; 0x43 5 B; 0x44 inline C string to NUL (NUL
   consumed; bytes ≥ 0x80 allowed — §8); 0x45 u16 len + len bytes (literal block, booked as bytes); 0x46/0x4A–0x5F
   1 B; 0x47 3 B; 0x48 2 B; 0x49 5 B; 0x60/0x62/0x63/0x64 2 B; 0x61 3 B; 0x9B–0x9F and ≥ 0xA0 as the statements, nested
   (each nested call's own arg expression ends at its own 0x40).
3. Mnemonics = the listing's 34 tokens (the histogram in C9 contract 4: `.hdr .array .dict .strtab .string .word
   text goto jf jt return match set setfield setglobal builtin frame call callsub callx send print input prompt atput
   release sysnew gstore store raise switch name entry .data`); `builtin` carries the builtin's name in the operand
   text, not the mnemonic. Where the bank and `scriptdis.py` disagree, the tool's listing wins for parity and the
   implementer reports the disagreement.
4. Hostile input: every prefix of 0x1802's decrypted bytes throws, never traps; a text or 0x45 block past the end
   throws `textRunsPastEnd` / `truncated`.

**Tests (6; numbers re-checked against the committed listing `$LISTINGS/1802.txt`, 2026-11-05):**
`testStatementOperandLengthsSynthetic` (one hand-built statement per opcode row of script-vm.md §4) ·
`testExpressionWorkedDecode` (the §5 worked decode `local0 = Routine0F02(arg0, 1)`: `82 00 9F 0F02 30 41 01 40 40` →
`set`, length 10) · `testSegment0x1802Head` (on the decrypted bytes: `.hdr` @0000 len 2 (dictionary 0x288E); `.array`
@0002 len 6; `.array` @0008 len 34; `frame` @002A len 3 (args 1 locals 0); `jf` @002D len 23 → target 0x005C;
`setfield` @0044 len 10; `setfield` @004E len 7; `return` @0055 len 7; `return` @005C len 4 — `.hdr`/`.array` are C9's
segment-level lines: this test decodes from @002A and pins the three literal lines as byte ranges) ·
`testTextStatementLength` (`text` @0063 in 0x1802's subroutine @0060 is 555 B and ends before `return` @028E) ·
`testBuiltinForms` (`d9 41 00 40` → `builtin` set_outdoor_sky(0), len 4 — the statement form, 8 shipped sites; the
expression inside 0x1802's `jf` @002D that the listing renders `random(0, 4)` decodes to the same operand length) ·
`testInvalidOpcodesRefused` (statements 0x80, 0x94–0x9A and expressions 0x65–0x9A → `invalidOpcode`; 0xFF refused by
name; a `text` running past the segment end → `textRunsPastEnd`; never a trap).

**Steps.**
- [ ] 1. Read script-vm.md §4, §5, §8 whole and `scriptdis.py` `class Dis` (lines 493–1271) for the operand walk;
      list every disagreement before coding (expected: none — the tool was written from the same bank after review).
- [ ] 2. Write the six tests; `swift test --filter InstructionDecoderTests` → 6 failures for "not defined".
- [ ] 3. Build the tables and the decoder; run the filter → 6/0; run G2 → **50/0**.
- [ ] 4. Self-review against the contract; G6, G7, G9.
- [ ] 5. Commit: `Cythera/Core: script instruction decoder (statements §4, expressions §5, 95 builtin names); 6 tests`.

**Reviewer legs (two):** leg 1 spec compliance row by row; leg 2 re-derives the 0x9C and 0x8F operand rules from
`DoInterpAt__7TInterpFsP5VAddr @ 10080c98` in `ghidra/cythera/Cythera_pef.decompiled.c` (find with
`grep -n '^// ==== .*DoInterpAt' …`) and confirms the prediction "0x1802 @02D4 decodes as `text` of 33 bytes with the pc
left on 0x88".

#### Task C9 — ⚑ script segment model + canonical parity for 958 segments (→ 57) — needs C8

**Scene.** The listing tool `scriptdis.py` classifies every script-band segment, walks reachability and prints one
line per instruction; this task reproduces that in Swift and proves it equal for all 958 segments through a
canonical text form hashed per segment. The hash list is generated once by a Python recipe from the **committed**
listings and committed; a Swift mismatch is a Swift bug by definition.

**Files.**
- Create `Cythera/Core/Sources/CytheraCore/Script/ScriptSegmentListing.swift` — S2's `ScriptSegmentListing` (`id`,
  `kind: ScriptSegmentKind` = `.class, .routine, .strtab, .dict, .array, .data, .ai`, `length`, `instructions`).
- Create `Cythera/Core/Sources/CytheraCore/Script/ScriptDecoder.swift` — `static func listing(_ id: UInt16, in file:
  SegmentFile) throws -> ScriptSegmentListing`: reads the bytes (`scriptSegment` for pages 0x01–0x3F except the AI
  band, `segment` for 0x0410–0x0436 — `SegmentFile.swift:118/:128`), classifies, walks.
- Create `Cythera/Core/Sources/CytheraCore/Script/ScriptCanonical.swift` — `static func text(_ listing:
  ScriptSegmentListing) -> String`, the parity form below.
- Create `Cythera/Core/Sources/CytheraCore/Script/CombatAISegment.swift` — `name` (0x20-byte header, ai-scripts.md
  §3.1) and `entries: [[UInt8]]` (8 B each, §3.2); kind `.ai`; its canonical lines are `name` and `entry` with length 0.
- Create `Cythera/Core/Tests/CytheraCoreTests/ScriptParityTests.swift`; modify
  `Cythera/Core/Tests/CytheraCoreTests/SegmentFileTests.swift` (one test added at the end).
- Modify `Cythera/Core/Sources/CytheraCore/Segments/SegmentFile.swift:46–49` and `:128–134`: a second named set
  `storedPlaintextBand: ClosedRange<UInt16> = 0x0410...0x0436` (the combat-AI segments `PerformAI` loads with plain
  `GetSegment`, ai-scripts.md §3); `scriptSegment(_:)` returns those as stored too, so every script-band id is read
  through one call and nothing is scrambled silently. Why: today `scriptSegment(0x0410)` returns garbage (the
  2026-11-05 audit confirmed it), and any "every script id" loop would hit it.
- Create `docs/cythera/tools/script_canon.py` (stdlib; `--help`); create `docs/cythera/script-parity.sha256` (958
  lines `<sha256>  <ID4>`, sorted by id); modify `docs/cythera/tools/README.md` (one row directly after the
  `scriptdis.py` row) and `docs/cythera/INDEX.md` Files table (one row directly after the `tools/scriptdis.py` row).

**Contract.**
1. Kinds as `scriptdis.py` measures them (script-census.md §1; `Dis` classification): `class` (u16 dictionary
   offset whose target is a 0xA0–0xAF dictionary that fits), `routine` (starts 0x81), `strtab` (0x90–0x9F array of
   string pointers), `dict`/`array` (bare literal block), `ai` (page 0x04: 0x20-byte name, 8-byte entries), `data`.
   class 700 · routine 218 · strtab 20 · dict 1 · array 2 · data 3 · ai 14 = 958 (re-measured over the committed
   listings 2026-11-05: equal).
2. Reachability as the tool does it: statements reached from dictionary entries, the routine entry, jumps and code
   pointers; then a **gap sweep** decoding unreached bytes as dead code (`x`); jump targets `>`; 0x45 blocks listed
   indented and booked as bytes (script-census.md §2 "dead-code runs": `8B 41 00 40` epilogues 420, lone `88` 175,
   longer 4; 0x1802 has 3).
3. **Canonical parity form** (`ScriptCanonical.text` and `script_canon.py` produce identical bytes):
   ```
   seg <ID4> kind <kind> len <TOC length>
   <OFFS4> <LEN> <MNEMONIC> <FLAG>
   ```
   one line per listing instruction in listing order; `OFFS4` four upper-case hex digits; `LEN` decimal bytes (the
   byte pairs shown + the `…+N` continuation, where `…` is U+2026; 0 for `name`/`entry`; the byte count for data
   lines); `FLAG` `-` reached, `>` jump target, `x` dead. The Python side derives it from the listing text with:
   ```
   instruction:  ^([0-9A-F]{4}):([> x])(?:((?:[0-9a-f]{2} )*[0-9a-f]{2})(?: …\+(\d+))?)?\s*(\S+)
   data line:    ^([0-9A-F]{4}):  ((?:[0-9a-f]{2} ?)+)$   → mnemonic .data
   ```
   **Apply the data-line regex FIRST for data-kind segments** (`; kind data`): the instruction regex also matches a
   data line and would yield the mnemonic `00` (the seat hit this on 2026-11-05 — 4 lines). The kind is the token
   after `; kind ` in the header (`ai` when the header says "compiled combat AI"); the length is the TOC length.
4. **Measured over the committed listings (seat, 2026-11-05, equal to the planner's p17):** 958 files; **22,166**
   instruction lines; flags `-` **16,899** · `>` **4,665** · `x` **602**; **34** mnemonics: text 3,785 · goto 2,611 · jf
   2,509 · return 2,283 · match 1,556 · set 1,480 · builtin 1,417 · frame 1,271 · .array 853 · .string 828 · .dict 701 ·
   .hdr 700 · setfield 554 · call 552 · print 289 · entry 178 · jt 161 · input 108 · prompt 95 · send 70 · callsub 40 ·
   atput 26 · .strtab 20 · setglobal 18 · release 17 · name 14 · sysnew 10 · gstore 5 · .word 4 · .data 4 · raise 3 ·
   switch 2 · callx 1 · store 1.
5. The oracle is the committed `$LISTINGS` (byte-identical to the census; INDEX provenance). Do not regenerate
   unless a listing is missing; if regenerated, the census must be byte-identical first.

**Tests (7):** `testAIBandReturnedAsStored` (in `SegmentFileTests`:
`scriptSegment(0x0410)` begins with the length byte 0x0E then "Attack Nearest"; `scriptSegment(0x0436)` equals
`segment(0x0436)`; `scriptSegment(0x0201)` still differs from `segment(0x0201)`) · `testKindClassification` (958 by kind
as contract 1; the per-page counts of script-census.md §1: 0x10 180, 0x18 121, 0x1B 111, 0x11 88, 0x1A 87, 0x0E 66, …) ·
`testDictionaryAndMethods0x1802` (dictionary @0x288E; methods sel 32 @002A, sel 12 @0292; property sel 68; class 0x40
id 2) · `testReachabilityFlags` (the corpus
flags above; 0x1802 dead-code runs 3) · `testLiteralAndDataSegments` (0x0201 strtab 256 entries, [2] "Alaric" @0409;
0x0101 plaintext dictionary 127 slots / 55 keys; 0x0301 array; 0x033F data 4 B; 0x0500 data 20 B; 0x0540 data 4 B) ·
`testCombatAISegments` (14; lengths 128,128,128,168,88,176,120,128,128,128,88,168,176,120; 0x0410 name "Attack
Nearest"; entries (len − 32)/8) · `testCanonicalParityAll958` (every hash equal; 22,166 lines; the histogram).

**Steps.**
- [ ] 1. Write `script_canon.py` (input: a listings directory; `--out DIR` writes one `.canon` per segment;
      `--sha256 FILE` writes the sorted hash list); run it on `$LISTINGS`; check the five numbers of contract 4.
- [ ] 2. Commit the golden and the tool (explicit paths; `docs/cythera/tools/script_canon.py`,
      `docs/cythera/script-parity.sha256`, the README and INDEX rows): `docs/cythera: script_canon.py + script-parity.sha256 (958 segments, 22,166 canonical lines)`.
- [ ] 3. Write the seven tests (the AI-band one first, in `SegmentFileTests`); filter runs → 7 failures.
- [ ] 4. Build the listing model, the decoder (kinds, reachability, gap sweep) and the canonical text; iterate on
      the parity test with a per-segment diff of the first mismatching line (print `seg`, `OFFS4`, both lines).
- [ ] 5. G2 → **57/0**; G6, G7, G9.
- [ ] 6. G8 recipe: `python3 -I docs/cythera/tools/script_canon.py "$LISTINGS" --sha256 "$SCRATCH/parity.sha256" && diff "$SCRATCH/parity.sha256" docs/cythera/script-parity.sha256 && echo PARITY-OK` → `PARITY-OK`.
- [ ] 7. Commit: `Cythera/Core: script segment model + canonical parity (958/958 vs scriptdis.py); AI band read as stored; 7 tests`.

**Reviewer legs (two):** leg 2 re-derives the dictionary layout and `At`'s open-addressing probe from
`At__7TInterpF5VAddrs @ 10083798` and confirms the prediction "deleting one byte from the 0x1802 listing's canon
changes exactly one hash".

### Session B — C6, C7 ⚑, C10 (three lanes, disjoint files; none touches `Package.swift`)

Merge order B: C6, then C7, then C10 (or previous + N). Each lane owns its files: `CytheraRender/Audio/SoundSegment`
(C6), `CytheraRender/Audio/Tune*` + `NoteRequestPart` (C7), `CytheraCore/UI` + `CytheraRender/Text` + the UI tests
(C10).

#### Task C6 — minor — sound: `'asnd'` segments and the 13 interface `snd ` → PCM (→ 63)

**Files.** Create `Sources/CytheraRender/Audio/SoundSegment.swift`; create
`Tests/CytheraRenderTests/SoundSegmentTests.swift`.

**Contract** (open-items-2026-10-03.md §9, HIGH): `'asnd'` = tag, u32 blocks, Fixed rate, i16 BE ×
(blocks·1024 + 512), 8-bit precision; the true length is not stored, so `samples` are kept **as stored** (zero tail
included; the mixer's end rule is Phase 2's) and `trimmedCount` is reported; `length == blocks·0x800 + 0x40C` is
enforced (Invariant 3). `snd ` goes through HectorAudio's `SndSound(data:)` (format 1, one `bufferCmd`, 8-bit), then
the converter rule of `FUN_100b7fac`: blocks = ceil(n/1024), min 1; sample − 0x80; zero tail.

**Tests (6):** `testAsndCensus` — 46 segments; tag ok; the length rule holds in all; rates 0x56220000 ×40 (22,050 Hz),
0x2B110000 ×2, 0x56EE8B9F ×2, 0x2B7745D0 ×2; Σ samples 1,053,696; Σ trimmed 998,777; every sample in −128..127;
samples == blocks·1024 + 512 for all (p09) · `testAsnd0x9101Worked` — 17,420 B, 8 blocks, 22,050 Hz, 8,704 samples,
trimmed 7,567, min −128 max 127, SHA-256 of the raw sample bytes begins `015dfac04505ead3` (p09) · `testAsndToPCM` —
`pcm()` mono, `sampleRate == rate/65536`, frames == samples.count, values as stored (not scaled) ·
`testThirteenInterfaceSnds` — ids 128, 129, 130, 133, 134, 135, 139, 140, 141, 142, 143, 145, 256; all format 1, one
command 0x8051, 8-bit, encode 0; rates 22,050 ×10, 7,418.18 (140), 22,254.55 (141, 142); base notes 60 except 142 = 72;
Σ header sample counts 108,669 (p07) · `testSndToAsndConversion` — snd 134 (90 samples) → 1 block, 1,536 samples,
sample[k] = byte − 0x80, tail zero; snd 256 (45,150 samples) → 45 blocks · `testHostileAsndThrowsNeverTraps` (odd
length, bad tag, every prefix throws or yields fewer records).

**Steps.** - [ ] tests first (6 failures for "not defined") · - [ ] build · - [ ] filter 6/0, G2 **63/0** · - [ ] G6,
G7, G9 · - [ ] commit `Cythera/Core: SoundSegment — 46 'asnd' + 13 snd → PCM, converter rule; 6 tests`.
**Review:** one leg (spec compliance and quality).

#### Task C7 — ⚑ music: MusicDescription + QTMA event decoder for the 11 tunes (→ 71)

**Scene.** The 11 tunes (0x9000–0x900A) are QuickTime Music Architecture sequences. This task decodes them end to end
into events and parts; it plays nothing (the synth is Phase 2's). It closes the "events not decoded" sub-point of the
bank's open music item.

**Files.** Create `Sources/CytheraRender/Audio/{TuneSequence,TuneEvent,NoteRequestPart}.swift`; create
`Tests/CytheraRenderTests/TuneSequenceTests.swift`.

**Contract.**
1. Container (open-items-2026-10-03.md §9, HIGH layout / MED names): u32@0 = description size = offset of the tune
   events; +4 `'musi'`; +0x0E u16 1; +0x10 u32 flags (1 in all 11); header events from +0x14 to size; tune events from
   size to the end; `(length − size) % 4 == 0` in all 11.
2. Event words are 32-bit big-endian, classified by the top bits (QTMA event encoding, Apple's `QuickTimeMusic.h`;
   confirmed by the corpus: 44,519 tune words + 2,422 header words classify with 0 undefined-type words, every general
   event's tail word carries the same length as its head, every tune ends on an end marker, and the NoteRequest
   payloads decode to readable strings): `000` rest (duration 24 bits) · `001` note (part 5 bits @24, pitch 6 bits
   @18 + 32, velocity 7 bits @11, duration 11 bits) · `010` control (part 5 @24, controller 8 @16, value 16) · `011`
   marker (subtype 8 @16: 0 end, 1 beat, 2 tempo; value 16) · `1001` extended note, 2 words (part 12 @16, pitch 16
   bits; w2 `10`, velocity 7 @22, duration 22) · `1010` extended control, 2 words (part 12 @16, controller 16; w2 `10`,
   value 16) · `1011` knob, 2 words · `1111` general: head `F part12 len16`, `len − 2` payload words, tail
   `11 subtype14 len16` with the same length; subtypes 1 NoteRequest, 4 PartKey, 5 TuneDifference, 6
   AtomicInstrument, 7 Knob, 8 MIDIChannel, 9 PartChange, 10 NoOp, 11 UsedNotes, 12 PartMix. Types `1000`, `1100`,
   `1101`, `1110` → `TuneError.undefinedEvent(wordIndex)`. **MED:** the extended-note pitch is read as an integer (the
   corpus's merged pitch range 17–84 rules out 8.8 fixed values ≥ 0x1100); the extended-note velocity bit position and
   the knob fields are the October planner's recollection — the decoder exposes the raw words beside the decoded
   fields so Phase 2 can re-read them against Apple's header.
3. NoteRequest payload (84 B = 21 words): NoteRequestInfo {flags u8, reserved u8, polyphony i16, typicalPolyphony
   Fixed} then ToneDescription {synthesizerType 4CC, synthesizerName Str31, instrumentName Str31, instrumentNumber i32,
   gmNumber i32} → `NoteRequestPart` (part index = the general event's part field).
4. The walker skips general-event payloads by length, so the count of interior end markers is event-level (the
   payload of a TuneDifference holds `0x60000000` words that are not markers).

**Tests (8):** `testElevenDescriptions` — description sizes 924, 412, 1180, 1308, 540, 540, 668, 796, 1692, 796, 1052
for 0x9000–0x900A; tags, u16@0xE, flags; lengths 8412, 40612, 20200, 19032, 9332, 12812, 12908, 12728, 13608, 9808,
28532 (p10; data-format.md §1.5) · `testHeaderEventsParseToEnd` — header words 226, 98, 290, 322, 130, 130, 162, 194,
418, 194, 258; each header = 3 general events per part (NoteRequest, MIDIChannel, UsedNotes) + 1 rest + 1 end marker;
MIDIChannel payload = part + 1 · `testNoteRequestParts` — 75 parts: 7, 3, 9, 10, 4, 4, 5, 6, 13, 6, 8 per tune; 70
`'ss  '` "Best Synthesizer" "(GS Instrument)" + 5 "Standard Kit" (gmNumber 16385; 0x9002 part 6, 0x9003 part 4,
0x9006 part 4, 0x9008 part 9, 0x900A part 3); 0x9000 gmNumbers 87, 54, 93, 25, 9, 102, 36; the GM set across tunes =
{1, 4, 9, 13, 15, 17, 19, 25, 27, 28, 34, 36, 40, 43, 46, 47, 48, 49, 50, 53, 54, 55, 57, 61, 62, 64, 65, 72, 74, 76,
77, 81, 87, 90, 92, 93, 95, 96, 97, 100, 102, 103, 104, 109, 110, 122, 123, 126, 16385} (p10b) ·
`testTuneEventsParseToEnd` — tune words 1872, 10050, 4755, 4431, 2198, 3068, 3060, 2983, 2979, 2253, 6870 (Σ 44,519);
0 undefined; the last word of every tune is `0x60000000` (end marker value 0) · `testEventCensus` — 0x9000: rest 638,
note 674, extended note 87, control 25 (controllers 7 ×6, 10 ×6, 33 ×13), beat markers 210, tempo 1, end-value-0 1,
end-value-1 7 (at tune-word indices 255, 515, 790, 1076, 1363, 1640, 1846; the final value-0 marker at 1871),
TuneDifference 7, rest Σ 57,648; corpus: notes + extended notes 13,401, TuneDifference 168 = interior end markers
(value 1) 168, final end markers 11 · `testFirstWordsOf0x9000` — `0x60020000` → marker(tempo, 0); `0x400A01C2` →
control(part 0, controller 10, 0x01C2); `0x40075100` → control(0, 7, 0x5100); `0x410A01BA` → control(1, 10, 0x01BA) ·
`testSyntheticNoteAndExtendedFields` (hand-built words for note / extended note / extended control / knob / general
round-trip the field formulas of contract 2) · `testTruncatedAndUndefinedThrowNeverTrap` (prefixes; a
`0x8…`/`0xC…`/`0xD…`/`0xE…` top nibble outside a general payload → `undefinedEvent`).

**Steps.** - [ ] tests first (8 failures) · - [ ] build · - [ ] filter 8/0, G2 **71/0** · - [ ] G6, G7, G9 · - [ ] commit
`Cythera/Core: TuneSequence — QTMA MusicDescription + events for 11 tunes (75 parts, 44,519 words, 0 undefined); 8 tests`.

**Reviewer legs (two):** leg 1 spec compliance row by row; leg 2 re-derives the event-word classification from
Apple's `QuickTimeMusic.h` field layout as contract 2 states it (the MED items: extended-note velocity, knob fields)
and records the raw words of three events beside their decode in As executed. **Open for Phase 2:** the value-1 end
markers + TuneDifference pairs (what the Tune Player did at them).

#### Task C10 — minor — UI resource records and fonts (→ 80)

**Files.** Create `Sources/CytheraCore/UI/{DialogTemplate,DialogItemList,WindowTemplate,ControlTemplate,AlertTemplate,MenuResource,MenuBar,StringList,PascalString,TextStyle,FontFamily,StartRects,PrefDefault}.swift`;
create `Sources/CytheraRender/Text/BitmapFont.swift`; create `Tests/CytheraCoreTests/UIRecordTests.swift` (6 tests),
`Tests/CytheraRenderTests/BitmapFontTests.swift` (2 tests) and `Tests/CytheraRenderTests/UIOracleTests.swift` (1 test:
`testDialogsAndItems`, which needs `HectorGraphics.Ditl` — `CytheraCoreTests` may not import HectorGraphics, G7).

**Contract.** Classic record layouts (Inside Macintosh; ui-toolkit.md §1 "Which window uses which frame" decoded them
with `struct.unpack('>4hhhhI', …)`): DLOG = rect (4×i16), procID, visible, filler, goAway, filler, refCon i32,
itemsID i16, title Str255; WIND = rect, procID, visible, filler, goAway, filler, refCon, title; CNTL = rect, value,
visible, filler, max, min, procID, refCon, title; ALRT = rect, itemsID, stages u16; DITL = i16 count−1, items {4 B,
rect, type u8, Str}; MENU = id, width, height, procID, filler, enableFlags u32, title, items…; MBAR = count, ids;
STR# = count, Str255s; TxSt per TMPL 128 = size u8, style byte, name Str255; FOND = 52-byte header + association table
at 0x34 (count−1, {size, style, id}); NFNT = 26-byte header, strike rowWords·2·fRectHeight bytes, locTable
(lastChar − firstChar + 3) u16, owTable at 16 + owTLoc·2. Strings are Mac Roman via `MacRoman.decode`.
- **`TextStyle` keeps the raw style byte.** The TMPL 128 field order differs between the two files (app: Reserved,
  Extend, Condense, Shadow, Outline, Underline, Italic, Bold; data: Bold, Italic, Underline, Outline, Shadow, Condense,
  Extend, Reserve), so the decoder stores the byte and Phase 1 reads it as a QuickDraw `Style` (0x01 bold); the 0x80
  bit on "Stats" is unexplained (carried to C12's as-built).
- **Both shipped NFNTs are 2 bytes short of the full owTable** (100 of 101 entries): the missing last entry reads as
  0xFFFF (no glyph), decoded as stored (Invariant 2). NFNT 25740: strike 476 B at 26, locTable at 502 (101 u16,
  monotonic, last 257 ≤ rowWords·16 = 272), owTable at 704 → would end at 906 but the resource is 904 B; 72 of 100
  entries 0xFFFF. NFNT 25746: strike 1,050 B, loc at 1,076, ow at 1,278.
- The `DialogItemList` cross-check against `HectorGraphics.Ditl.decode` is a test oracle only; no CytheraCore source
  imports HectorGraphics.

**Tests (9):** `testDialogsAndItems` (in `UIOracleTests`) — 17 DLOG: ids 128–142, 900, 9300; procID 16001 for 128–139
and 141, 1 for 140, 142, 900, 9300; titles 128 `oO;qQ;nN;lL`, 129/134/135 `sSyY;cC;DdnN`, 130–133 `;;Mm;Fm`; rects 128
(40,40,356,420), 133 (37,65,440,450), 140 (40,40,163,421); 20 DITL items 5, 4, 4, 20, 8, 13, 4, 3, 11, 4, 4, 14, 5, 4,
6, 6, 3, 2, 24, 3 (Σ 147) and equal to `HectorGraphics.Ditl.decode(_:).count` for all 20 (p07; ui-toolkit.md §1,
§3.2) · `testWindows` — 10 WIND: 128 "Delver" (20,0,480,640) procID 12; 129 "Map" (16,304,336,624) 16004; 130 "Text"
16016 refCon 0x1220; 131 "Roster" 16000; 132 "Character" 16000 goAway 1; 133 "Spellbook" 16016 refCon 0x22018 goAway
1; 134 "New Window" 16048; 135 "Status" (354,0,482,640) procID 2; 136 "To Do" (352,10,352,223) 16032; 1134 "New
Window" 16017 · `testControls` — 8 CNTL: 128 "Quit", 129 "Onward!", 130 "Load Player", 131 "New Player"
(50,200,82,296) procID 16000; 132 "Save" (0,0,32,64); 133 "Cancel"; 134 "Don't Save" (0,0,32,96); 135 procID 1017 min
135 · `testAlertsMenusBars` — ALRT 129, 134, 135, 901, 1024; MENU ids 128–138, 200, 201, 202; MBAR 128 → 2 menus, 129
→ 1; CMNU 129 counted (219 B) (app-shell.md §4) · `testStringLists` — app STR# counts 500:4, 501:10, 502:7, 503:5,
990:6, 9300:4, 9301:8, 9303:16, 9304:16, 9305:2, 9306:0, 9307:6, 9308:13, 9320:6, 9321:16, 31999:13; data 128:4
("Bye", "Name", "Job", …), 134:7, 135:41 ("World", "Odemia", "LKH", …), 255:82, 900:4; STR 128 "Cythera Preferences",
129 "Cythera Data", 130 "Cythera Patch"; every list consumes its resource exactly · `testTextStylesPrefsStartRects` —
app TxSt 128 "Sys Large" 12 Chicago · 129 "Sys Small" 10 style 0x01 Geneva · 130 "Labels" 9 Geneva · 131 "Stats" 10
0x01 Geneva · 132 "Text" 10 Espy Sans · 133–135 Lang0 10/12/18 Espy Sans; data TxSt 128 18 ArgosANouveau · 129 14 0x01
ArgosANouveau · 130 9 Geneva · 131 9 0x81 Geneva · 132 10 Geneva · 133–135 14/22/24 ArgosANouveau · 136–138 10/12/18
Seldane · 999 "Label Colors" bytes A8 4D DD BD; the lookup order (data file first) makes the data styles effective;
Pref 128 "Volume" 5, 129 "Music" 2 (data-format.md §8.1); nrct 128 = 8 rects, rect 0 (102,166,133,317), rect 6
(19,279,47,465), rect 7 (0,0,155,88) (app-shell.md §5.1) · `testFontFamilies` — app FOND 128 "Rogue Font" family
7707, one association (12, 0, 128) whose NFNT 128 exists in no committed file; data FOND 128 "Seldane" family 128 →
(12,0,25740), (18,0,25746); FOND 1046 "ArgosANouveau" → (0,0,7289) = sfnt 7289 (TrueType: 12 tables, unitsPerEm 4096,
81 glyphs, name "ArgosANouveau") (p15) · `testBitmapFonts` (in `BitmapFontTests`) — NFNT 25740: fontType 0x9000,
chars 0–98, widMax 16, kernMax −1, rect 16×14, ascent 12 descent 2 leading 1, rowWords 17, strike 476 B, loc table 101
entries monotonic (last 257), ow table 100 entries, 27 chars with glyphs (`A–K M N P–Z b` + 2 control codes); NFNT
25746: 24×21, ascent 18 descent 3 leading 2, rowWords 25, strike 1,050 B, 29 glyphs (p18) · `testGlyphExtraction` (in
`BitmapFontTests`) — glyph 'A' of NFNT 25740: columns loc['A'+1] − loc['A'] > 0, width from the ow low byte, offset
from the ow high byte; a 0xFFFF entry returns nil; hostile (short strike) throws.

**Steps.** - [ ] tests first (9 failures) · - [ ] build · - [ ] filters 9/0, G2 **80/0** · - [ ] G6, G7 (the HectorGraphics
grep over `Sources/CytheraCore` stays empty), G9 · - [ ] commit `Cythera/Core: UI resource records (DLOG/DITL/WIND/CNTL/ALRT/MENU/STR#/TxSt/FOND/nrct/Pref) + BitmapFont (NFNT); 9 tests`.
**Review:** one leg.

### Session C — C13 → C11 → C12 and the re-base record

#### Task C13 — minor — the audit's seams and carried minors (→ 86 after C10; previous + 6)

**Scene.** The 2026-11-05 audit of the built work found seams between the built parts, no wrong readings: the save
overlay is not yet a segment store (nothing can read a map, props or a script through it); compo tiles are built from
frame 0's tile table in the original, not the current frame (the code is right today — no shipped compo entry touches
an animated tile, 0 of 4,224 — but its comment says "current frame"); three minors were carried from Phase 0 (no
0…7 guard on an animation frame, so frame −3 gives tile 9; `LZ.decode(_:limit:)` accepts a negative limit; the F007
test re-asserts what the loader already enforced); `Palette.clut256` reads the data file directly instead of through
the lookup chain whose answer it claims to be; nothing pins the 264 built compo tiles' bytes or a Rect picture's
colour-table order; three census refusals the original does not make are undocumented. This task closes them. The
overlay's write path (write, remove, flush, encrypted save) is NOT here — it is the Phase 4 card SV-OV; Phase 0 writes
no file. One reviewer leg.

**Files.** `Sources/CytheraCore/Segments/SegmentOverlay.swift` (:39 conformance; new `entry(_:)`, new
`scriptSegment(_:)` using `SegmentFile.storedPlaintext` + `storedPlaintextBand`); `Sources/CytheraCore/World/LevelMap.swift`
(:60 add `init(store: some SegmentStore, level: Int, maxMapDimension: Int16)`; :74 one comment line: the per-side cap
is a census refusal, the original only allocates D·D·2; :98 one comment line on sides < 8);
`Sources/CytheraCore/World/AnimationRecord.swift:25–28` (`frame & 7`); `Sources/CytheraCore/Codec/LZ.swift:40–43`
(negative limit → `outputLimit` up front); `Sources/CytheraRender/Pixels/TileStore.swift` (:24 comment: the original
zero-fills a sheet it cannot load; :45 comment on the out-of-range slice; :54–57 comment: compo tiles use frame 0's
table always — Phase 1 passes the table); `Sources/CytheraRender/Pixels/Palette.swift` (:31–33 through
`resources.resource(type:id:)`; :40 doc "0xAARRGGBB words"); `Sources/CytheraCore/Art/ColorTableRecord.swift:57`
(cite `rgb8` = the high byte as `GetCTable`'s 16-bit components → 8-bit, or soften); `docs/cythera/data-format.md`
§1.4 (append one ⚑ line: `RefindSegment` picks the bottom-most file, not the topmost — used only after compiling a
user AI; `SaveSegment` always re-points slot 0, so an empty write masks the lower store's copy); tests: `Tests/CytheraCoreTests/SegmentFileTests.swift` (+2), `Tests/CytheraCoreTests/WorldGlobalsTests.swift`
(:276 the F007 check against the TOC length; +1 animation guard), `Tests/CytheraCoreTests/LZTests.swift` (+1),
`Tests/CytheraRenderTests/TileStoreTests.swift` (+1 digest over the 264 built compo tiles),
`Tests/CytheraRenderTests/StoredPictureTests.swift` (+1 one Rect picture's colour table pinned by value order).

**Tests (6):** `testOverlayIsASegmentStoreAndReadsMapsAndGlobals` (a `SegmentOverlay` of the data file + an empty
memory store opens level 2 through `LevelMap(store:…)` → 64×64, and `WorldGlobals(store:)` → 20 ids) ·
`testOverlayScriptSegmentDecryptsAndKeepsPlaintext` (0x0201 differs from raw; 0x0101 and 0x0410 equal raw) ·
`testAnimationFrameMasksToEight` (frame 8 == frame 0; frame −3 == frame 5) · `testLZNegativeLimitThrowsUpFront` ·
`testCompoTilesDigest` (SHA-256 over the 264 non-zero records' output, recorded on first green run — Invariant 10:
the value is measured, not typed) · `testRectPictureTableByValue` (PICT 130's 256-entry table: values ascend, entry
k's value == k, three colours pinned).

**Gate:** G2 previous + 6; G6, G7, G9. **Commit:** `Cythera/Core: audit seams — overlay is a SegmentStore (+ scriptSegment), store-based map init, carried minors, comments; 6 tests`.

#### Task C11 — minor — `cythera-census` + `docs/cythera/data-census.md` + `--render` (→ 91; previous + 5) — needs C6–C10, C13

**Files.** Modify `Package.swift` (adds the executable `cythera-census` and the test target `CytheraCensusTests`, as
§0b's package line); create `Sources/CytheraRender/Census/CytheraCensus.swift`, `Sources/cythera-census/main.swift`,
`Tests/CytheraCensusTests/CytheraCensusTests.swift`, `docs/cythera/data-census.md`; modify `docs/cythera/INDEX.md`
(one pointer row in the Files table).

**Tool contract.** `cythera-census <Resources/Cythera dir> [--render <out dir>]`; Markdown on stdout, names never
machine paths; exit 0 / 1 (any failure, each named) / 2 (bad args). Sections: files · segment file (header, pages, one
line per non-script segment with band, length, decode result; the script band as one line per page + the parity
verdict) · maps · props · globals · pixels · sounds · music (per tune: parts with gmNumbers, event census) · resources
(per-type counts for the three files; one line per decoded resource) · fonts · unread · Totals. `--render` writes
`tiles-0x8E19-0x8E1A.png` (the 32 UI-art tiles as two 16-tile rows), `portrait-0x8800.png`, `sky-0x8400.png`,
`start-screen-pict-132.png` (through its own 224-entry table), `pix-0x8F80.png` (status art, data clut) — ImageIO in
`Sources/cythera-census` only; optional, nothing for Ben to judge.

**Exact summary lines** (each a whole stdout line, in this order, Totals last; the `scripts` line's
`parity 958/958 · canonical lines 22,166` comes from `ScriptCanonical` against the committed hash list, not from
Python):
```
# Cythera 1.0.4 — data census
files 20 · bytes 11,570,723 · Cythera Data 5,608,688 · Cythera Data.rsrc 1,247,331 · Cythera.rsrc 1,008,484 · Cythera Documentation.rsrc 2,420,779 · ai 8 · pict 5
segments 1,558 · TOC pages 34 · bytes 5,524,330 · overlaps 0 · header 0x1300 0x0200 0x0200
scripts 958 · code 918 (class 700 · routine 218) · strtab 20 · dict 1 · array 2 · data 3 · ai 14 · unknown opcodes 0 · parity 958/958 · canonical lines 22,166
maps 42 · cells 206,976 · chunk records 233 · chunked 0 · with exits 23 · compo cells 19,650 · max tile 0x429
props 40 · records 14,485 · kinds 00:12104 01:116 02:46 08:618 09:241 0A:7 10:32 11:55 18:31 1C:1 42:879 44:298 80:52 FF:5
globals 20 · base tiles 395 · anim 8 · tile flags 2,125 · names 547 · creatures 50 · chars 131 · schedules 617 · teleports 190 · wall 50 · compo 264 · filter tiles 124
pixels sheets 159 (0x8E96 absent) · portraits 142 · sky 18 · pix 59 · macro 62 · LZ ops 554,796 · LZ bytes 5,191,304 · raw bytes 31,744
sounds asnd 46 · 22050 Hz 40 · 11025 Hz 2 · 22254.5 Hz 2 · 11127.3 Hz 2 · samples 1,053,696 (trimmed 998,777) · snd 13 · samples 108,669
music 11 · parts 75 (GS 70 · Standard Kit 5) · tune words 44,519 · notes 13,401 · undefined 0 · end markers 11 · tune differences 168
resources app 339/52 · data 113/18 · documentation 268/40 · PICT 21 (indexed 14 · direct 7) · clut 2 (differ 4) · Lite 25 · FILT 7 · snd 13 · DLOG 17 · DITL 20 (items 147) · WIND 10 · CNTL 8 · ALRT 5 · MENU 14 · MBAR 2 · STR# 21 · STR 3 · TxSt 20 · FOND 3 · NFNT 2 · sfnt 1 · pltt 1 · nrct 1 · Pref 2
fonts Sys Large ArgosANouveau 18 · Sys Small ArgosANouveau 14 bold · Labels Geneva 9 · Stats Geneva 9 bold · Text Geneva 10 · Lang0 ArgosANouveau 14/22/24 · TxSt 136–138 Seldane 10/12/18 · literal TextFont 0/1/3 · TextSize 0/9/10
unread 0x8EFF 4,694 B · PORT 2 · LINF 3 · MSta 3 · eBRS 25 · eSTM 16 · RMAP 1 · DATA 10 · CMNU 1 · crsr 57
Totals: segments 1,558 (decoded 1,557 · no reader 1) · resources decoded 198 · files 14 · failures 0
```
Arithmetic: 198 = PICT 21 + clut 2 + pltt 1 + Lite 25 + FILT 7 + nrct 1 + Pref 2 + snd 13 + DLOG 17 + DITL 20 + WIND
10 + CNTL 8 + ALRT 5 + STR# 21 + STR 3 + TxSt 20 + FOND 3 + NFNT 2 + sfnt 1 + MENU 14 + MBAR 2; files 14 = 8 `.ai` +
`AI Scripting Document` (CR-terminated ASCII: 17/20/19/13/29/12/19/30 and 301 lines, no LF, no byte ≥ 0x80) + 5
screenshots (4 raster decoded, Land King Hall named as QuickTime); 1,557 = 1,558 − 0x8EFF. "max tile 0x429" is over
all cells' low 12 bits (over non-compo cells it is 0x32C). The "fonts" literal values (TextFont immediates 0 ×2, 1 ×2,
3 ×3; TextSize 0 ×4, 9 ×1, 10 ×2, at the 22 call sites whose argument is a literal — 15 more load it from a register)
are printed from a constant table with that provenance, not by reading the binary.

**The doc** `docs/cythera/data-census.md` = a header (generated date, HectorKit sha **ef2c341**, Classics sha, the two
re-run commands of G3, and the "Spec-vs-data deltas" list — the bank corrections below, two lines each), a rule
`---`, then `cythera-census` stdout verbatim (golden test). Numbers in the doc come only from the tool.

**Tests (5):** `testSummaryLinesExact` (the 14 lines above verbatim, in order) · `testStdoutEqualsCommittedCensus`
(stdout byte-equals the doc body below its rule) · `testExitCodes` (bad args → 2; a temp folder with `Cythera Data`
truncated to 0x1000 bytes → 1 and the line names the file) · `testOneLinePerSegment` (600 non-script segment lines +
24 script-page lines + 198 resource lines) · `testRenderWritesFivePNGs` (temp dir; five files of the named sizes:
512×64, 64×64, 288×32, 640×480, 128×128).

**Gate:** G2 **91/0** (when C13 precedes it), G3. **Commit:** `Cythera/Core: cythera-census + docs/cythera/data-census.md (1,558 segments, 198 resources, 0 failures); 5 tests`.

#### Task C12 — minor — final gates, bank corrections, as-built (no tests)

**Steps.**
- [ ] 1. Re-run G1 (with the `$AKI` override; record "gate PASS 370 at ef2c341" or the later clean main's SHA/floor),
      G2 (**91/0**), G3, G4, G5, G7, G9.
- [ ] 2. Append the bank corrections below, each as one `⚑ planner-probe (Phase 0)` line in the named bank file (no
      rewrites).
- [ ] 3. Append to DECISIONS D28 an "As built — Phase 0 complete" paragraph: the HectorKit SHA + floor; the
      `Cythera/Core` test total **91**; the census Totals line; the pin ef2c341 / floor 370 and the rule that a later
      clean main is accepted at ≥ the recorded floor (Ben's ruling, 2026-11-05); the wording fix to D28's second ruling,
      "the player walks", not "Alaric walks" (Ben's ruling, 2026-11-05; Alaric is character 2, the player character 1);
      three deviations from the locked surface, kept: `SegmentOverlay.write` throws (the surface said non-throwing),
      `LZ.decode(_:limit:)` + `LZError.outputLimit` are additions, `LevelMap.init(file:level:)` takes the concrete file
      (C13 added the store-based initialiser beside it); the MED/LOW items carried — which `clut 256` the resource
      chain returned (data file's by the open order, MED; entries 0, 16, 252, 253 differ), the TxSt style byte read raw
      (TMPL field order differs between the files; the 0x80 bit on "Stats" unexplained), the NFNTs' short owTable, how
      the 16-bit paper doll (PICT 129) and 32-bit start-screen frames (133–138) were colour-searched into the 8-bit
      screen (LOW), C7's open markers.
- [ ] 4. `docs/cythera/INDEX.md` NOT RESOLVED 9: one line "QTMA events decoded (Phase 0 C7, data-census.md); open:
      value-1 end markers / TuneDifference semantics".
- [ ] 5. Commit: `docs: Cythera Phase 0 as built (D28)`. STATE's Cythera bullet, the handoff and the next session's
      brief (wave 2, R1) are the orchestrator's close.

**Bank corrections to append (C12 step 2; also the census doc's delta list):**
1. data-format.md §1.5 / §3.4 "160 sheets 0x8E00..0x8E9F": 159 sheets lie in `LoadTiles`' range (0x8E96 is absent →
   tiles 0x960–0x96F have no pixels); the 160th segment of the page is 0x8EFF (4,694 B), not an LZ stream, read by
   nothing.
2. data-format.md §1.5 rows 0x8F00+n / 0x8F80+n: the LZ output is `((w+3) & ~3) · h` bytes — rows padded to 4 bytes;
   11 of 59 images have `w % 4 ≠ 0`.
3. data-format.md §3.4 / §5 0xF001: 8 records, then the zero i16 terminator, nothing after (66 B).
4. data-format.md §5 0xF004 "547 names": confirmed; 6 bytes follow the 0x7FFF terminator.
5. engine-classes.md §5 / ui-toolkit.md §0 "palette = clut 256": two `clut 256` resources exist — `Cythera.rsrc`
   (SHA `f3373625…`) and `Cythera Data.rsrc` (`e7fe2eef…`) — differing in entries 0, 16, 252, 253 (entry 0: 0xFC00 vs
   0xFFFF white); the data file is opened after the app, so the chain returns its copy (MED).
6. the October design's "committed (≈ 16 MB)": 20 files, 11,570,723 B.
7. the October design's "which font ids/sizes the game requests is not in the bank": the `TxSt` resources carry them
   (TMPL 128: size, style byte, font name); the data file's twelve override the app's eight (the list in C10's
   `testTextStylesPrefsStartRects`); literal Toolbox calls: `TextFont` 22 sites (immediates 0 ×2, 1 ×2, 3 ×3; 15
   register-loaded), `TextSize` 22 (0 ×4, 10 ×2, 9 ×1; 15 register-loaded), `TextFace` 27, `TextMode` 7 (0, 1 ×3,
   49 ×3), `GetFNum` 1.
8. INDEX "Resource census" FOND/NFNT/sfnt: FOND 128 "Seldane" (12 → NFNT 25740, 18 → NFNT 25746; 27/29 glyphs,
   upper-case letters + 'b'), FOND 1046 "ArgosANouveau" → sfnt 7289 (TrueType, 81 glyphs, 4096 upem); app FOND 128
   "Rogue Font" (family 7707) → NFNT 128, which no committed file holds; both NFNTs end 2 bytes before the full owTable.
9. open-items-2026-10-03.md §9 / INDEX NOT RESOLVED 9 "QTMA events not decoded": decoded (C7) — 11 tunes, 75
   NoteRequest parts (70 GS instruments, 5 Standard Kit), 44,519 tune words, 13,401 notes, 0 undefined words; every
   tune: tempo marker first, end marker (value 0) last; 168 interior end markers with value 1, each followed by a
   3-word `TuneDifference` whose payload word is `0x60000000` — semantics open.
10. open-items-2026-10-03.md §9 `'asnd'`: confirmed on all 46; Σ samples 1,053,696, Σ non-zero-trimmed 998,777; range
    −128..127; the 13 interface `snd ` are format 1 / `bufferCmd` / 8-bit; three rates (22,050; 7,418.18 for id 140;
    22,254.55 for 141–142); base note 72 on 142.
11. data-format.md §4.2 rows +0xA / +0xE..0xF: confirmed — 0 in all 14,485 records; byte 0xE bits 6–7 and byte 0xF
    zero; the §4.3 kind census and §6.1 CharEntry field census reproduce exactly.
12. script-census.md: regenerated byte-identical (958 listings, 0 unknown opcodes); C9's canonical form adds 22,166
    instruction lines / 34 mnemonics as a second mechanical check.
13. data-format.md §1.5 "page 0x80: 42 maps" / STR# 135 "41 level names": 0x8000 (32×32, no 0x8100 props) has no name;
    0x8001–0x8029 ↔ the 41 names; 0x8125 has no props.
14. data-format.md §5 0xF009 row "0x2000 B": the segment is 0x4000 B (512 × 0x20).

---

## Wave 2 — R1: the Phase 1 research task (one session, no code, fully specified)

**Scene.** Phase 1 builds the frame loop end to end; the bank (render.md §0 "Not read", app-shell.md, ui-play.md,
engine-classes.md §5) names the bodies it never read. R1 reads them all, at instruction level where the bank asks,
and writes one note the Phase 1 plan pins its numbers to. The seat (an Opus 5.5 orchestrator) may split R1 across
two or three reader subagents by the groups below; one Fable-free review leg per group re-derives one rule each.

**Output.** `docs/cythera/phase1-research-2026-11.md` (≤ 600 lines; HIGH/MED/LOW labels; every claim `name @ addr`
+ quoted line; plain English), one INDEX Files row, and a closing table **"What Phase 1 must know"** (one row per
number: value, where it came from, which 1a/1b card uses it). Corrections to existing bank files are appended as
`⚑ corrected (phase1 research 2026-11)` lines, never rewrites.

**Groups and bodies** (addresses from the bank; find each with `grep -n '^// ==== .*<Name>' ghidra/cythera/*.decompiled.c`,
then `python3 -I docs/cythera/tools/ppcdis.py` for the instruction-level reads; `tb.py --at` for lengths):

| group | bodies | what the note must settle |
|---|---|---|
| R1-W windows | `CreateWindows @ 10013c04`; `PutInALayer`, `TWindow` layer code (ui-toolkit.md §1 TWindow row); the four WDEF draw routines `TBorderWDEF`, `TThinBorderWDEF`, `TPixsWDEF`, `TDrawerWDEF` and the CDEF `Draw`s (missing dump, ui-toolkit.md §1 rows); `TStatusWindow::LayoutObjects @ 100334f4`, `DrawRoutine @ 10034708`; `TMapWindow` ctor (p:19092 reads the saved rect) | the default rects, layers and z-order of every window at a new game; the frame geometry per WDEF (which tile cell draws which edge/corner, title placement, close box, grow box); the layer names |
| R1-K keys | `KeyRoutine__10TMapWindowFs @ 100437b8` (extra dump) whole; `TDroppableWindow::KeyRoutine @ 1002a07c`; `XDirection @ 10028ff4`; `TDelverApp::TranslateKey @ 10012b0c` | the full key table (which key → which command, with modifiers), the hold/repeat rule, the cheat-mode gate |
| R1-M movement | `MoveCommand`, `CanMove`, `TryMove`, `CanSlide` (TGameSys); `HandleMove @ 100488e4`, `HandleSubMove @ 10048fb0`; `DoTick @ 1004ded8` leader branch; `HeartBeat @ 10053a80` | the step rule (bump 4 / step 10 busy; diagonal/slide; what blocks; the "walk around obstacles" pref bit), sub-step phases per quality setting, the starting phase (MED in §3.4) |
| R1-R render tail | `CalcLighting`, `DimOffLevel`, `InteractProps` (call sites `1005cd78/8c/a0`); `AddToHood`, `MoveHood`, `ResetHood` (THood); the vtable hook `*_DAT_100cea80`; the `LOS @ 10069554` shadow walk; `DrawRoutine__11TGameViewerFs @ 1005c844` transition kinds 1–8 (p:28009–28153); `SetLight`, `CopyLight`, `RecalcPartyLight`, `AmbientLight @ 10063fc0`, `GetBrightness @ 1006c0ac` | the light map formula end to end (ambient level, party `Lite` stamp, roofs' b/5, `SubLightSolid/Dither`), the hood's insertion order (closes render.md §7), what the post-light hook does, each transition's pixel rule |
| R1-S start state | `NewModel`, `InitWorld @ 10012e38`, `CreateGlobals @ 10004d0c`, `BeginPlay`, `ChangeZone`, `FindCurZone`; `CharEntry` 1's shipped location (0xF009, `tools/seg.py`) | where a new game begins (level, x, y) and **which level is Catamarca** (STR# 135 name ↔ map id); what runs before the first frame without scripts; the erase colour and backdrop state at start |
| R1-T text and sky | `AADrawText @ 10075B58`, `TDisableAntiAliasText`; the `TextFont/TextSize/TextFace` sites (glue `TextFont` 0x100C35A0, `TextSize` 0x100C35B8, `TextFace` 0x100C35D0, `GetFNum` 0x100C50B8, `TextMode` 0x100C4908; literal-argument sites TextFont 0 @1000204C, 100024EC · 1 @100024BC, 10002578 · 3 @10002514, 1000253C, 100357F0; TextSize 0 @10002058, 100024C8, 100024F8, 10002584 · 10 @10002520, 10002548 · 9 @100357FC — the `T7LabelWidget` fonts −1/−2/−3 of ui-toolkit.md §1 and the portrait popup "font 3 size 9" of ui-play.md §10 item 7); `DrawSky`, `CalcLocations @ 1006be68`, `ChangeOutdoor`; `DrawPortrait @ 100086c4`; `DrawCharStatus`, `DrawMacros` | which strings are anti-aliased and how; the exact font/size/style per window text; the sky strip's body positions per quarter hour; the status panel's draw order |

**Acceptance:** every body above read whole and cited; the closing table filled with no "not read" row; R1-S names
the start level and coordinates; R1-R closes THood order with a HIGH line or says precisely what is still open.
No code, no `Package.swift` change. Commit: `docs/cythera: Phase 1 research — windows, keys, movement, render tail, start state, text (R1)`.
Then the orchestrator **expands the wave 3 and wave 4 cards in this file** (no separate Phase 1 plan) from R1's
table, in wave 1's card shape (Scene, Files with line anchors, Contract, Tests with numbers, Steps, Reviewer legs),
and writes the next session's brief for wave 3.

---

## Wave 3 — Phase 1a: the still picture (cards; expanded here after R1)

| card | builds | files (planned) | acceptance |
|---|---|---|---|
| 1a-ST state slice | `GameState` with the Phase 1 rows of spec §3 (`PropTable` from 0x8100+L + 0xF306, `CharacterTable` from 0xF009, `GameClock` fixed at the start hour, seen bits); the level loaded as `NewModel` does | `Sources/CytheraCore/State/{GameState,PropTable,CharacterTable,GameClock}.swift`; tests | the start level's prop count and the leader's cell equal R1-S's numbers |
| 1a-WM window model | desktop, `WindowModel` (rects, layers, z-order, visible, kind), the default layout from R1-W; the Map window's N from its rect | `Sources/CytheraCore/Windows/`; tests | every default rect pinned; N = 9 for the shipped WIND 129 rect (`(min(w,h)+32)/64·2+1`, ui-play.md §5.3) |
| 1a-TB tile tables | per-animation-frame tile pointer tables from 0xF001 (builtin A5's shape), the transposed and masked copies (`TCopyTile`, `TMaskTile`, `CopyCompoTile`), compo tiles built from **frame 0's** table always — the original has no frame term at `100051b0`/`100051fc`, so compo tiles never animate and see tile 1275 as 1274's pixels; `compoTile` takes the frame-0 table, not the raw store; a mutable framebuffer type beside the immutable `IndexedImage` | `Sources/CytheraRender/Map/{TileTables,TileBlits}.swift` | the eight frame tables' SHA-256s; a transposed tile equals the hand-transposed golden |
| 1a-SG stage | `SetStage` (the 31×31 stage, the ladder, the quarter grid), `NoLOS`/`LOS`, the staged lists | `Sources/CytheraCore/Engine/{Stage,LineOfSight,Hood}.swift` | the staged list for the start view equals a hand-derived list from the props (count + order) |
| 1a-RN render | `Render` as render.md §2 (backdrop pre-pass, ground, passes 0/1/3/4/5, FX stub, post-pass), `ApplyRoof`, `ApplyFilter` (a displaced read can leave the tile, so it reads from the tile store, not a lone tile; it steps each filter's hold/counter as `AdvanceDisplacementFilters` does), `ApplyLight` | `Sources/CytheraRender/Map/{MapRenderer,Roofs,Lighting,Filters}.swift` | one golden (hash + PNG) per step for the start view; the Catamarca screenshot's map area within the mismatch budget the seat sets |
| 1a-UI frames | the WDEF/CDEF frames and controls from tiles 0x19C–0x1AF per R1-W | `Sources/CytheraRender/Desktop/{Frames,Controls}.swift` | goldens per frame kind at two sizes |
| 1a-TX text | glyph sheets baked once on the Mac from the shipped `sfnt`/`NFNT` and the system fonts at exactly the TxSt sizes and styles, committed as data with a census test — no own rasteriser (Ben's ruling, 2026-11-05) + `TextOut` rules (fonts per TxSt, AA per R1-T) | `Sources/CytheraRender/Text/`; `Resources/CytheraGlyphs/` (the baked sheets + a census test) | the Status panel's strings match the screenshot's pixels |
| 1a-SP status + roster + text windows | `TStatusWindow` layout (`k` widening), sky strip, portraits, macros; Roster; Text log | `Sources/CytheraRender/Desktop/{StatusPanel,Roster,TextWindow}.swift` | goldens at 640 and 1024 wide |
| 1a-DT desktop | composition in z-order → `DesktopFrame`; palette + gamma | `Sources/CytheraRender/Desktop/Compositor.swift` | the whole-screen golden |
| 1a-K2 kit | HectorShell resizable 1:1 canvas mode (canvas = window content size in points, 1:1, re-laid on resize or display change — the original's `HandleMonitorChanged`; shape: HectorKit's `ShellScalingPolicy.aspectFitNearest`) | `HectorKit/Sources/HectorShell/…` (own kit task, floor +N, DECISIONS there) | kit gate PASS at the new floor |
| 1a-APP shell | `Cythera/App` target (`project.yml`), full screen, menu bar auto-hide, presents `DesktopFrame` | `Cythera/App/`; `project.yml` | `xcodebuild -scheme Cythera build`; staged `~/Desktop/Cythera.app` for Ben's gate |

**Gate 1a (Ben):** side by side with the Catamarca screenshot; the gate card lists the clut choice (the four pairs:
entry 0 white vs grey, 16 two greys, 252/253 dark blues vs black — the data file's table stays the default), the duplicate black, the paper-doll
colour search (none shown yet) as "check this".

## Wave 4 — Phase 1b: walking (cards)

| card | builds | acceptance |
|---|---|---|
| 1b-EV events | the event loop model, the TaskEvent queue (kinds 1–5), `InputEvent` → window hit → `ScheduleMouseDown/KeyDown` | queued events drain in the original's order; coalescing rule for mouse |
| 1b-MV movement | `MoveCommand`/`CanMove`/`TryMove`/`CanSlide`, `HandleMove`/`HandleSubMove`, `HeartBeat` → `MoveAll` with the leader only; busy 10/4; the clock per leader tick | the R1-M rules pinned; a 10-step walk's state golden |
| 1b-TH threads | the three threads taking strict turns; `MyScheduler`'s rules (F ticks, mode word); the wait-reason seam (no waits yet) | a fake-clock test: frames exactly F apart while sub-steps arrive early |
| 1b-RF roofs + grow + bar | roofs lift (`ApplyRoof`'s leader rule), the map window's grow box (64-px snap), the menu bar show/hide | goldens before/after a step under a roof |
| 1b-GT gate | staged app; `WHAT-TO-EXPECT.md` | Ben walks Catamarca |

## Wave 5 — R2 + Phase 2: the world runs (cards)

R2 research (one session): `DoExpr @ 1007ddfc` and `DoInterpAt @ 10080c98` whole at instruction level where the bank
is MED; `At`, `Len`, `IsEqual`, `IsTrue`, `Ctor`, `VAddrToPtr`, `DispatchSysObj`, `GetField/SetField` every case; the
`TAudio` voice table and end-of-sample path (`FUN_100b7a58`, `FUN_100b7f40`, `FUN_100b7d60`); `TuneQueue`/`GMSTune` use;
`DoMove` whole; `TPathFinder`; `ScheduleTime`/`ScheduleOne`/`RepositionChar` (re-check the rules.md §3.4 overturn).
Then the seat expands these cards in this file. Cards: VM-VA values and frames · VM-ST statements · VM-EX expressions · VM-DI dispatch and selectors ·
VM-HP heap · BI-1…BI-6 builtins by family (iterators; props/items; party/characters; world/time/sound; UI/conversation
stubs; flags/variables/to-do) · EN-CK clock rates · EN-SC schedules · EN-AI `DoMove` + activity queue · EN-PF pathfinder
· EN-HD hood/eggs/spawn · EN-SG signals · AU-MX mixer · AU-MU music cues → the shell's synth · TH-WR wait reasons ·
PR-WE the worked-example goldens (spec §7 row "the VM") · PR-BOT the Catamarca day bot. Gate: a day in Catamarca.

## Waves 6–8 — Phases 3–8 (cards, one line each; each expanded in this file after its research)

| phase | cards |
|---|---|
| 3 Talk | CV-WIN conversation window + panes · CV-MODES the five modes · CV-IN `input`/`match`/chips · CV-PR prompts/how-many/pick · CV-MORE · CV-BARK · JN journal · TD to-do · SW scripted windows (`sysnew` class map) · gate: talk to the town |
| 4 Start + saves | ST-SPL splash + start screen · ST-CP Create Player · SV-OV file-backed overlay store (the writable-store protocol: write, remove, TOC flush, encrypted save; the overlay already reads as a `SegmentStore` after C13; `RefindSegment` = the bottom-most file; an empty save masks lower copies as the original's `SaveSegment` does) · SV-CH the `'Char'` stream + chunks · SV-IO open/save/save as/backup/revert · PF prefs file · QT quit flow · gate: new game → save → quit → resume |
| 5 Items + shops | CW character windows (panes, doll, slots, `CanDrop`) · CT containers · DD drag and drop · GT give/take/drop/throw · WT weight · SH shops + haggling · SV services/training · TH theft · gate: a shopping trip |
| 6 Fights + magic | CB combat chain · CS status/death/XP · SP spells/runes · AL alchemy · FX missiles/FX classes · AI `.ai` compiler + evaluator · ED strategy editor + `TAIDebug` · CH cheat keys · gate: first dungeon |
| 7 The whole story | the remaining scripted windows and transitions, cut scenes, both endings; a play-through harness from quests-flags.md §5–§7; gate: play it through |
| 8 Windows + docs + release | SDL twin (BTX shape), rendered music, the DOCMaker viewer, notarized DMG; gate: his brother's report, the DMG |

---

## Orchestration notes

- Session A's two ⚑ tasks and session B's three lanes each fit one orchestrator under the cap; session C (C13, C11, C12) is three small tasks.
  Each session ends with STATE's Cythera bullet, an "As executed" note under its cards here, and a handoff whose
  "brief for the next session" is written from nothing (this file named as the one plan, the next wave's tasks, the
  gates with expected numbers, the few binding rules); then it chains or stops as the repo's `CLAUDE.md` says.
- Pre-dispatch grounding for C8/C9: confirm `SegmentFile.scriptSegment` / `segment` line numbers (118, 128) and that
  `$LISTINGS` has 958 files (`ls | wc -l`) before writing the brief.
- The orchestrator re-runs G1 (with the `$AKI` override), G2 and G7 at every merge head and records the numbers.
