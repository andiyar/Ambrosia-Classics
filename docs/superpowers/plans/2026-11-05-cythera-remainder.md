# Cythera — the remainder: implementation plan (Phase 0b, Phase 1 research, Phases 1–8 as cards)

> **For agentic workers:** execute with `superpowers:subagent-driven-development` — one `fk-implementer` and one
> `fk-reviewer` per task, two reviewer legs per ⚑ MAJOR task, Opus 5.5 throughout (Ben 2026-10-07; `CLAUDE.md`);
> Fable only on a contraindication, and only after asking Ben. Plans in this house carry **contracts, not code**
> (Ben, 2026-10-03): files with line anchors, APIs, test names, commands, commit messages. Steps use checkboxes.

**Goal:** finish Phase 0 (the decoders and the census), then build Cythera to its first gate (the player walking
Catamarca) and beyond, in the design's gate order, on checked ground.

**Architecture:** spec §2 — `CytheraCore` (rules, scripts, world, state, the window model, saves),
`CytheraRender` (pixels, audio, text, the map, the desktop), thin shells. One instruction walker shared by the
decoder and the VM; one state model (spec §3); derived data rebuilt, never saved.

**Authority:** this plan for the waves below; `docs/plans/2026-10-06-cythera-phase0.md` for the C6–C12 contracts it
cites by line (with the deltas recorded here); the spec `docs/superpowers/specs/2026-11-05-cythera-remainder-design.md`;
the audit `docs/superpowers/audits/2026-11-05-cythera-phase0-audit.md` (its rulings correct both).

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
| Hostile input | every decoder throws a named error, never traps; a cut on a record boundary parses to fewer records (⚑ audit 10) |
| Invariant 10 | any unexpected number (count, hash, offset, test total, census line): STOP, report the command output; never edit an expectation to agree |
| Scope fence (G6) | the diff ⊆ the task's Files (+ `docs/DECISIONS.md` where the task says so); explicit paths only, never `git add -A`, never `git stash` |
| Launches | nothing with a window in Phase 0b or the research wave; from Phase 1a the shell is launched only by Ben or by a session he has told to, headless goldens otherwise |
| Ben's gate | a phase closes on the machine side only: "machine gates green; Ben's gate pending" |
| Context | 300k per orchestrator; size a session by context, not task count (Ben 2026-11-04); at ~240k close; a session that cannot merge records why and keeps its worktree |
| HectorKit | pin **ef2c341 / floor 370** (spec §8, Q1); a later clean main is accepted at ≥ floor and recorded |

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

**Gates** (the Phase 0 plan's G1–G9, re-pathed):

| gate | command | expected |
|---|---|---|
| G1 HectorKit | `git -C "$HK" log --oneline -1`; `HECTORKIT_DATA_AKI11="$AKI" HECTORKIT_TEST_LOG="$SCRATCH/hk.log" "$HK/tools/check-zero-skip.sh" 2>&1 \| tail -n 1` | `ef2c341` (or a later clean main, recorded); `PASS: zero skips, zero failures, executed N == floor N`, N ≥ 370 (the script's default Aki path is stale — the override is mandatory until HectorKit fixes it) |
| G2 suite | `cd "$WT/Cythera/Core" && swift test > "$SCRATCH/cy.log" 2>&1; grep -cE "^Test Case '.*' (passed\|failed\|skipped) \(" "$SCRATCH/cy.log"; grep -cE "^Test Case '.*' (failed\|skipped) \(" "$SCRATCH/cy.log"` | the ladder total, then `0` |
| G3 census (C11 on) | `cd "$WT/Cythera/Core" && swift build -c release --product cythera-census > /dev/null && "$(swift build -c release --show-bin-path)/cythera-census" "$WT/Resources/Cythera" > "$SCRATCH/census.md"; echo $?; tail -n 1 "$SCRATCH/census.md"` | `0`; `Totals: segments 1,558 (decoded 1,557 · no reader 1) · resources decoded 198 · files 14 · failures 0` |
| G4 data = archive | `cd "$WT/Resources/Cythera" && for f in *; do cmp "$f" "$G/$f" \|\| echo "DIFF $f"; done; ls \| wc -l` | no DIFF; `20` |
| G5 apps untouched | `cd "$WT" && xcodegen generate && for s in Aki BubbleTroubleX; do xcodebuild -scheme "$s" build 2>&1 \| tail -n 1; done` | `** BUILD SUCCEEDED **` ×2 (Phase 0b adds no app target) |
| G6 scope fence | `git -C "$WT" diff --name-only <task base>..HEAD` | ⊆ the task's Files |
| G7 layering | `grep -rnE "^import (AppKit\|UIKit\|SwiftUI\|CoreGraphics\|CoreText\|ImageIO\|AVFoundation\|QuartzCore\|AudioToolbox)" "$WT/Cythera/Core/Sources" \| grep -v "Sources/cythera-census/"`; `grep -rnE "^import (HectorGraphics\|HectorAudio)" "$WT/Cythera/Core/Sources/CytheraCore"` | both empty (both empty today — audit B) |
| G8 parity (C9 on) | the recipe in C9 step 6 | 958 lines, every hash equal |
| G9 clean tree | `git -C "$WT" status --porcelain \| grep -v '^??'` | empty after every commit |

**Ladder (`Cythera/Core`, cumulative, in THIS merge order — Phase 0 plan's canonical numbers are superseded):**
C8 **50** → C9 **57** → C6 **63** → C7 **71** → C10 **80** → C13 **86** → C11 **91** (⚑ audit 2, 5–7: C9 gained one test,
C13 is new). A different merge order: previous + the task's N (C8 6, C9 7, C6 6, C7 8, C10 9, C11 5, C13 6).

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

## Wave 0 — the audit (done in this session, 2026-11-05)

Two read-only `fk-reviewer`s (spec §10): A data and world records, B render and pictures. Reports and the seat's
rulings: `docs/superpowers/audits/2026-11-05-cythera-phase0-audit.md`. Rulings that change a task below are marked
**⚑ audit N** at the task.

---

## Wave 1 — Phase 0b (three Opus 5.5 orchestrator sessions)

Every task: G2 (its ladder number), G6, G7, G9; ⚑ tasks two reviewer legs. Commits carry the trailer
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Read the Phase 0 plan's invariants (lines 101–141) and
S2 (154–199) first; its contracts for C6, C7, C10, C11, C12 stand and are cited by line below.

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
3. Mnemonics = the listing's 34 tokens (the Phase 0 plan's Research note 14; C9's histogram); `builtin` carries the
   builtin's name in the operand text, not the mnemonic.
4. Hostile input: every prefix of 0x1802's decrypted bytes throws, never traps; a text or 0x45 block past the end
   throws `textRunsPastEnd` / `truncated`.

**Tests (6; verbatim from the Phase 0 plan C8, lines 489–498, numbers re-checked against the committed listing
`$LISTINGS/1802.txt`):** `testStatementOperandLengthsSynthetic` · `testExpressionWorkedDecode` (`82 00 9F 0F02 30 41 01
40 40` → `set`, length 10) · `testSegment0x1802Head` (`.hdr` @0000 len 2; `.array` @0002 len 6; `.array` @0008 len 34;
`frame` @002A len 3; `jf` @002D len 23 → target 0x005C; `setfield` @0044 len 10; `setfield` @004E len 7; `return` @0055
len 7; `return` @005C len 4 — note `.hdr`/`.array` are C9's segment-level lines: this test decodes from @002A and
pins the three literal lines as byte ranges) · `testTextStatementLength` (`text` @0063 is 555 B, ends before `return`
@028E) · `testBuiltinForms` (`d9 41 00 40` → `builtin` set_outdoor_sky, len 4) · `testInvalidOpcodesRefused`.

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
- **⚑ audit 2** — modify `Cythera/Core/Sources/CytheraCore/Segments/SegmentFile.swift:46–49` and `:128–134`: a second named
  set `storedPlaintextBand: ClosedRange<UInt16> = 0x0410...0x0436` (the combat-AI segments `PerformAI` loads with plain
  `GetSegment`, ai-scripts.md §3); `scriptSegment(_:)` returns those as stored too, so every script-band id is read
  through one call and nothing is scrambled silently.
- Create `docs/cythera/tools/script_canon.py` (stdlib; `--help`); create `docs/cythera/script-parity.sha256` (958
  lines `<sha256>  <ID4>`, sorted by id); modify `docs/cythera/tools/README.md` (one row after `scriptdis.py`, line
  ≈ 21) and `docs/cythera/INDEX.md` Files table (one row after `tools/scriptdis.py`, line 44).

**Contract.**
1. Kinds as `scriptdis.py` measures them (script-census.md §1; `Dis` classification): class 700 · routine 218 ·
   strtab 20 · dict 1 · array 2 · data 3 · ai 14 = 958 (re-measured over the committed listings 2026-11-05: equal).
2. Reachability as the tool does it: statements reached from dictionary entries, the routine entry, jumps and code
   pointers; then a **gap sweep** decoding unreached bytes as dead code (`x`); jump targets `>`; 0x45 blocks listed
   indented and booked as bytes.
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

**Tests (7; Phase 0 plan C9, lines 538–546, plus ⚑ audit 2):** `testAIBandReturnedAsStored` (in `SegmentFileTests`:
`scriptSegment(0x0410)` begins with the length byte 0x0E then "Attack Nearest"; `scriptSegment(0x0436)` equals
`segment(0x0436)`; `scriptSegment(0x0201)` still differs from `segment(0x0201)`) · `testKindClassification` · `testDictionaryAndMethods0x1802`
(dictionary @0x288E; methods sel 32 @002A, sel 12 @0292; property sel 68) · `testReachabilityFlags` (the corpus
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

| task | contract (Phase 0 plan lines) | files | tests | ladder | deltas from this pass |
|---|---|---|---|---|---|
| C6 sound | 417–433 | `Sources/CytheraRender/Audio/SoundSegment.swift`; `Tests/CytheraRenderTests/SoundSegmentTests.swift` | 6 (names there) | **63** | none |
| C7 ⚑ music | 435–477 | `Sources/CytheraRender/Audio/{TuneSequence,TuneEvent,NoteRequestPart}.swift`; `Tests/CytheraRenderTests/TuneSequenceTests.swift` | 8 | **71** | leg 2 re-derives the event-word classification from Apple's `QuickTimeMusic.h` field layout as the contract states it (the MED items: extended-note velocity, knob fields) and records the raw words of three events beside the decode |
| C10 UI records + fonts | 549–589 | `Sources/CytheraCore/UI/{DialogTemplate,…,PrefDefault}.swift`; `Sources/CytheraRender/Text/BitmapFont.swift`; `Tests/CytheraCoreTests/UIRecordTests.swift`; `Tests/CytheraRenderTests/BitmapFontTests.swift` | 9 | **80** | `TextStyle` keeps the raw style byte (Research note 13); the `DialogItemList` cross-check against `HectorGraphics.Ditl.decode` is test-only (CytheraCoreTests may not import HectorGraphics — put that one assertion in `BitmapFontTests` or a new `CytheraRenderTests/UIOracleTests.swift`, G7) |

Merge order B: C6, then C7, then C10 (or previous + N).

### Session C — C13 → C11 → C12 and the re-base record

#### Task C13 — minor — the audit's seams and carried minors (→ 86 after C10; previous + 6)

**Scene.** The audit (`docs/superpowers/audits/2026-11-05-cythera-phase0-audit.md`, rulings 1, 3, 5–9, 11, 14) found
seams between the built parts, no wrong readings. This task closes the ones Phase 0 can close; the rest are named on
later cards. One reviewer leg.

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
§1.4 (append one ⚑ line: `RefindSegment` picks the bottom-most file; `SaveSegment` always re-points slot 0 — audit A
7b/7c); tests: `Tests/CytheraCoreTests/SegmentFileTests.swift` (+2), `Tests/CytheraCoreTests/WorldGlobalsTests.swift`
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

| task | contract | deltas |
|---|---|---|
| C11 census + doc + `--render` | Phase 0 plan 591–632 (`Package.swift` adds the executable + `CytheraCensusTests`; `Sources/CytheraRender/Census/CytheraCensus.swift`; `Sources/cythera-census/main.swift`; `Tests/CytheraCensusTests/CytheraCensusTests.swift`; `docs/cythera/data-census.md`; INDEX row) → **previous + 5** (91 when C13 precedes it) | the doc header's HectorKit sha = **ef2c341**; the `scripts` summary line's `parity 958/958 · canonical lines 22,166` comes from `ScriptCanonical` against the committed list, not from Python |
| C12 final gates + as-built | 634–640 | G1 with the `$AKI` override (record "gate PASS 370 at ef2c341"); append to D28 "As built — Phase 0 complete": test total **91**, the three recorded S2 deviations (⚑ audit 9: `SegmentOverlay.write` throws, `LZ.decode(_:limit:)` + `.outputLimit`, `LevelMap.init(file:level:)` concrete), the census Totals line, **the pin ef2c341 / floor 370 and the accept-later-clean-main rule (Q1)**, the D28 ruling-2 wording fix (Q4: "the player walks"), C7's open markers; INDEX NOT RESOLVED 9 line; STATE's Cythera bullet; the handoff + chip for wave 2 (R1) |

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
| R1-T text and sky | `AADrawText @ 10075B58`, `TDisableAntiAliasText`; the `TextFont/TextSize/TextFace` sites (Phase 0 plan Research note 18); `DrawSky`, `CalcLocations @ 1006be68`, `ChangeOutdoor`; `DrawPortrait @ 100086c4`; `DrawCharStatus`, `DrawMacros` | which strings are anti-aliased and how; the exact font/size/style per window text; the sky strip's body positions per quarter hour; the status panel's draw order |

**Acceptance:** every body above read whole and cited; the closing table filled with no "not read" row; R1-S names
the start level and coordinates; R1-R closes THood order with a HIGH line or says precisely what is still open.
No code, no `Package.swift` change. Commit: `docs/cythera: Phase 1 research — windows, keys, movement, render tail, start state, text (R1)`.
Then the orchestrator writes **the Phase 1 plan** (`docs/plans/2026-11-<dd>-cythera-phase1.md`) from the cards below
and R1's table, in the Phase 0 plan's shape, and chips wave 3.

---

## Wave 3 — Phase 1a: the still picture (cards; expanded into the Phase 1 plan after R1)

| card | builds | files (planned) | acceptance |
|---|---|---|---|
| 1a-ST state slice | `GameState` with the Phase 1 rows of spec §3 (`PropTable` from 0x8100+L + 0xF306, `CharacterTable` from 0xF009, `GameClock` fixed at the start hour, seen bits); the level loaded as `NewModel` does | `Sources/CytheraCore/State/{GameState,PropTable,CharacterTable,GameClock}.swift`; tests | the start level's prop count and the leader's cell equal R1-S's numbers |
| 1a-WM window model | desktop, `WindowModel` (rects, layers, z-order, visible, kind), the default layout from R1-W; the Map window's N from its rect | `Sources/CytheraCore/Windows/`; tests | every default rect pinned; N = 9 for the shipped WIND 129 rect (`(min(w,h)+32)/64·2+1`, ui-play.md §5.3) |
| 1a-TB tile tables | per-animation-frame tile pointer tables from 0xF001 (builtin A5's shape), the transposed and masked copies (`TCopyTile`, `TMaskTile`, `CopyCompoTile` from frame 0 — ⚑ audit B1), compo tiles | `Sources/CytheraRender/Map/{TileTables,TileBlits}.swift` | the eight frame tables' SHA-256s; a transposed tile equals the hand-transposed golden |
| 1a-SG stage | `SetStage` (the 31×31 stage, the ladder, the quarter grid), `NoLOS`/`LOS`, the staged lists | `Sources/CytheraCore/Engine/{Stage,LineOfSight,Hood}.swift` | the staged list for the start view equals a hand-derived list from the props (count + order) |
| 1a-RN render | `Render` as render.md §2 (backdrop pre-pass, ground, passes 0/1/3/4/5, FX stub, post-pass), `ApplyRoof`, `ApplyFilter` (reads from the store, not a lone tile; steps hold/counter as `AdvanceDisplacementFilters` — ⚑ audit 13), `ApplyLight` | `Sources/CytheraRender/Map/{MapRenderer,Roofs,Lighting,Filters}.swift` | one golden (hash + PNG) per step for the start view; the Catamarca screenshot's map area within the mismatch budget the seat sets |
| 1a-UI frames | the WDEF/CDEF frames and controls from tiles 0x19C–0x1AF per R1-W | `Sources/CytheraRender/Desktop/{Frames,Controls}.swift` | goldens per frame kind at two sizes |
| 1a-TX text | glyph sheets (Q2) + `TextOut` rules (fonts per TxSt, AA per R1-T) | `Sources/CytheraRender/Text/`; `Resources/CytheraGlyphs/` (the baked sheets + a census test) | the Status panel's strings match the screenshot's pixels |
| 1a-SP status + roster + text windows | `TStatusWindow` layout (`k` widening), sky strip, portraits, macros; Roster; Text log | `Sources/CytheraRender/Desktop/{StatusPanel,Roster,TextWindow}.swift` | goldens at 640 and 1024 wide |
| 1a-DT desktop | composition in z-order → `DesktopFrame`; palette + gamma | `Sources/CytheraRender/Desktop/Compositor.swift` | the whole-screen golden |
| 1a-K2 kit | HectorShell resizable 1:1 canvas mode (design §6; shape: D17's policy) | `HectorKit/Sources/HectorShell/…` (own kit task, floor +N, DECISIONS there) | kit gate PASS at the new floor |
| 1a-APP shell | `Cythera/App` target (`project.yml`), full screen, menu bar auto-hide, presents `DesktopFrame` | `Cythera/App/`; `project.yml` | `xcodebuild -scheme Cythera build`; staged `~/Desktop/Cythera.app` for Ben's gate |

**Gate 1a (Ben):** side by side with the Catamarca screenshot; the gate card lists the clut choice (the four pairs:
entry 0 white vs grey, 16 two greys, 252/253 dark blues vs black — ⚑ audit 4), the duplicate black, the paper-doll
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
`DoMove` whole; `TPathFinder`; `ScheduleTime`/`ScheduleOne`/`RepositionChar` (re-check the §3.4 overturn). Then the
Phase 2 plan. Cards: VM-VA values and frames · VM-ST statements · VM-EX expressions · VM-DI dispatch and selectors ·
VM-HP heap · BI-1…BI-6 builtins by family (iterators; props/items; party/characters; world/time/sound; UI/conversation
stubs; flags/variables/to-do) · EN-CK clock rates · EN-SC schedules · EN-AI `DoMove` + activity queue · EN-PF pathfinder
· EN-HD hood/eggs/spawn · EN-SG signals · AU-MX mixer · AU-MU music cues → the shell's synth · TH-WR wait reasons ·
PR-WE the worked-example goldens (spec §7 row "the VM") · PR-BOT the Catamarca day bot. Gate: a day in Catamarca.

## Waves 6–8 — Phases 3–8 (cards, one line each; each phase's plan written after its research)

| phase | cards |
|---|---|
| 3 Talk | CV-WIN conversation window + panes · CV-MODES the five modes · CV-IN `input`/`match`/chips · CV-PR prompts/how-many/pick · CV-MORE · CV-BARK · JN journal · TD to-do · SW scripted windows (`sysnew` class map) · gate: talk to the town |
| 4 Start + saves | ST-SPL splash + start screen · ST-CP Create Player · SV-OV file-backed overlay store (the writable-store protocol: write, remove, TOC flush, encrypted save; `RefindSegment` = bottom-most file; an empty save masks lower copies — ⚑ audit 1, 11) · SV-CH the `'Char'` stream + chunks · SV-IO open/save/save as/backup/revert · PF prefs file · QT quit flow · gate: new game → save → quit → resume |
| 5 Items + shops | CW character windows (panes, doll, slots, `CanDrop`) · CT containers · DD drag and drop · GT give/take/drop/throw · WT weight · SH shops + haggling · SV services/training · TH theft · gate: a shopping trip |
| 6 Fights + magic | CB combat chain · CS status/death/XP · SP spells/runes · AL alchemy · FX missiles/FX classes · AI `.ai` compiler + evaluator · ED strategy editor + `TAIDebug` · CH cheat keys · gate: first dungeon |
| 7 The whole story | the remaining scripted windows and transitions, cut scenes, both endings; a play-through harness from quests-flags.md §5–§7; gate: play it through |
| 8 Windows + docs + release | SDL twin (BTX shape), rendered music, the DOCMaker viewer, notarized DMG; gate: his brother's report, the DMG |

---

## Orchestration notes

- Session A's two ⚑ tasks and session B's three lanes each fit one orchestrator under the cap; session C (C13, C11, C12) is three small tasks.
  Each session ends with STATE's Cythera bullet, a handoff and a chip for the next.
- Pre-dispatch grounding for C8/C9: confirm `SegmentFile.scriptSegment` / `segment` line numbers (118, 128) and that
  `$LISTINGS` has 958 files (`ls | wc -l`) before writing the brief.
- The orchestrator re-runs G1 (with the `$AKI` override), G2 and G7 at every merge head and records the numbers.
