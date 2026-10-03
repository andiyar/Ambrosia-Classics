# Cythera 1.0.4 — RE bank index

Glenn Andreas' Ultima-style RPG (Ambrosia, 1999), engine name **"Delver"**. Register: **code
readings only — nothing here is behaviour-verified.** Ben's eyes are the only behaviour oracle.

## Provenance
| item | value |
|---|---|
| binary | `…/RPG/Cythera/Cythera (installed)/files/Cythera` data fork, 890,864 B (`ls -l`), PEF `Joy!peffpwpc`, copied as-is to `ghidra/Cythera_pef` |
| dump | `ghidra/Cythera_pef.decompiled.c`, 73,652 lines (`wc -l`) |
| how | Ghidra 12.1.3 headless, language forced **`PowerPC:BE:32:default`**, cspec **`macosx`** (auto-detect picks the wrong VLE language — `ghidra/README.md`), post-script `DumpDecompile.java` |
| function count | `analyze-Cythera_pef.log`: "DumpDecompile: wrote **1955/1955** functions"; `grep -c '^// ==== '` = 1955; `grep '^// ==== FUN_' | wc -l` = **290** unnamed |
| named breakdown | (`tools/gen_classmap.py` output) 139 classes / 793 methods, 263 free game functions, 51 std-template instantiations, 558 import glue stubs (≥ 0x100C1C50) |
| data section | PEF section 1 is pattern-initialised; `tools/pef.py` unpacks it (0x86BA → 0xC18C, zero-filled to 0x7934E); Ghidra places it at 0x100CD280; TOC pointers are section-relative (verified on the "Out of space for new props" string) |
| scenario data | `Cythera Data` data fork 5,608,688 B = a `TSegFile` with **34 TOC pages / 1,558 segments** (`python3 docs/cythera/tools/seg.py`) |
| builtins dump | `ghidra/Cythera_builtins.decompiled.c` (git-ignored), 3,294 lines, 95/95 builtins — ⚑ corrected (review 2026-10-03): made by `docs/cythera/tools/CyDecompBuiltins.java` on a **copy** of the analysed project: `cp -R <proj>/Cythera_pef.{gpr,rep} <scratch>/cythera-fix-proj/; analyzeHeadless <scratch>/cythera-fix-proj Cythera_pef -process Cythera_pef -noanalysis -scriptPath docs/cythera/tools -postScript CyDecompBuiltins.java $PWD/ghidra/Cythera_builtins.decompiled.c` (log line `CyDecompBuiltins: wrote 95/95`) |
| tools | `docs/cythera/tools/`: `seg.py` (TOC census + `dec()` decryptor), `lz.py` (segment LZ), `pef.py` (PEF data unpacker), `toc.py` (resolve a TOC entry address to its string), `rsrc.py` (resource census), `demangle.py` + `gen_classmap.py` (class map; needs `names.txt` = `grep '^// ==== ' dump | sed 's#^// ==== ##; s# ====$##'`), `CyDecompBuiltins.java` (Ghidra post-script: builtin TVector table at 0x100D7270 → functions → decompile) |

Selector census command (script-vm.md §2.3): grep of every `_(DoInterp|HasProperty|GetProperty)__7TInterp…(x, <literal>` in the dump, mapped to the enclosing function header.

## Files
| file | sections | labels present |
|---|---|---|
| `data-format.md` | 1 segment file (layout, xxd, encryption, overlay/saves, id map) · 2 LZ codec · 3 level maps (header, cell bits, chunks/roofs, tiles/animation/compo tiles/displacement filters, seen bits) · 4 props (table, record, kind byte, per-type tables, worked decode) · 5 world globals 0xF0xx · 6 characters (CharEntry, names/portraits, schedules) · 7 save game | HIGH MED LOW NOT RESOLVED |
| `script-vm.md` | 1 VAddr values & literals · 2 segments, classes, dispatch, selector table · 3 frames · 4 statement opcodes · 5 expression opcodes + worked decode · 6 builtin table (resolved: location, calling convention → `script-builtins.md`) · 7 persistent heap | HIGH MED LOW NOT RESOLVED |
| `script-builtins.md` | 0 provenance/recipe/notation · 1 iterator protocol · 2 opcode → address → behaviour table (0xA0–0xFE, 95 rows) · 3 what it settles · 4 builtin NOT RESOLVED | HIGH MED LOW NOT RESOLVED |
| `ai-scripts.md` | 1 vocabulary (STR# 9300–9321) · 2 lexer/grammar · 3 compiled form + xxd · 4 evaluator, objects/modifiers, built-in tests · 5 scenario tests/actions = script routines · 6 binding · 7 `.rsrc` siblings · 8 the seven scripts | HIGH MED LOW NOT RESOLVED |
| `rules.md` | 1 combat · 2 movement/party/levels · 3 schedules & `EvalCondition` · 4 status/regeneration · 5 conversation · 6 magic/skills/trade | HIGH MED LOW NOT RESOLVED |
| `engine-classes.md` | 1 program shape · 2 class roles (framework, world, logic, rendering, out-of-scope) · 3 clock, rates, pacing, day/night, sky · 5 screen pipeline | HIGH MED LOW NOT RESOLVED |
| `engine-classmap-1/2/3.md` | mechanical demangled listing (classes CharEntry…TInteraction, TInterp…VAddr, free functions) | HIGH (mechanical) |

## Class map summary (class → decompiled methods)
TActiveMonster 45, TScriptedWindow 38, TViewer 36, TGameSys 32, TGameViewer 28, TStatusWindow 26,
TSegFile 24, TInventoryWindow 22, TInterp 21, TAudio 20, TCachedSegFiles 18, TDroppableWindow 18,
TWindow 18, TCharacterWindow 17, TConversation 16, TDelverApp 16, THeap 15, TPathFinder 13,
TBaseDragger 12, TInteraction 12, TApp 11, THeapObj 11, THeapDict 10, TPrefs 10, TSpellFX 9,
TTaskMaster 9, TGremlin 8, THeapList 8, GMSTune 7, SCombatAIEntry 7, TCache 7, TJournalSegment 7,
TTextOut 7, TBark 6, THood 6, TInventoryPile 6, TJournal 6, TTextContext 6, TApPrefWindow 5,
TInventoryList 5, TListBox 5, TToDo 5, TApWindow 4, TDialog 4, TPixCacheBase 4, TRunStart 4,
TSegLoad 4, TSpinCursor 4, TWAutoMap 4, TWControl 4, TWScrollText 4, TAIDebug 3, TCDEFRegister 3,
TCommandMenu 3, TConvMode 3, TCreatePlayerDialog 3, TDisableAntiAliasText 3, TDragonMonster 3,
TFadeInTextImageObject 3, TImageCompositor 3, TJournalList 3, TSoundTracker 3, TStyleRun 3,
TWDEFRegister 3, TWInvent 3, VAddr 3, CharEntry 2, TAbilityList 2, TApWidget 2, TBackdropWind 2,
TCDEF 2, TCrawlMonster 2, TDrawToGWorld 2, THowManyMode 2, TMapWindow 2, TMemoryStream 2,
TOctoMonster 2, TPickMode 2, TPixsWDEF 2, TProgBarCDEF 2, TRegistry 2, TScrollBarCDEF 2,
TSegFileIterator 2, TSegStream 2, TStaticImageObject 2, TToDoList 2, TWButton 2, TWDEF 2, TWIcon 2,
TWList 2, TWMusicBox 2, TWNumber 2, TWNumberEntry 2, TWPix 2, TWPixButton 2, TWText 2,
TWTextEntry 2, and 1 each: MemRange, PropItem, SCombatAIHeader, SegFileHeader, T7Adapter,
T7ControlWidget, T7GroupBox, T7IconWidget, T7LabelWidget, T7SliderWidget, T7Widget, TAIList,
TAppearanceAdapter, TAppearanceMenu, TArchetypeList, TAudit, TBorderWDEF, TBres, TBufferGWorld,
TCheckButtonCDEF, TCircleShower, TCMNU, TConvResponseMode, TDrawerWDEF, TEditNumberCDEF,
TEditUserBehavior, TMissileSpinner, TMissileStream, TMissileThrower, TModalMode, TNumberCDEF,
TPortraitList, TPushButtonCDEF, TRadioButtonCDEF, TSanityChunk, TScrollingCreditImageObject,
TSimpleInteraction, TStringFadeInTextImageObject, TSTRScrollingCreditImageObject,
TThinBorderWDEF, TTileShower, TWListList. (Nested `TScriptedWindow::TWidget` methods are listed
with the free functions — the demangler does not split `Q2` names.)

## Resource census (command: `python3 docs/cythera/tools/rsrc.py <file>`; type:count(min..max bytes))
- **Cythera.rsrc** — 339 resources, 52 types: ALRT:5(14) Audt:1(52) BNDL:1(52) CDEF:3(6) CMNU:1(219)
  CNTL:8(23..34) CODE:9(24..168220) CURS:1(68) DATA:1(64432) DITL:20(40..494) DLOG:17(21..36)
  Delv:1(1) FOND:1(1150) FREF:4(7) ICN#:17(256) LDEF:1(128) Lite:25(65..14401) MBAR:2(4..6)
  MDEF:1(6) MENU:14(32..241) MemU:2(9) PICT:2(11154..41934) Page:13(1..292) Pref:2(4) SIZE:1(10)
  STR:3(13..20) STR#:16(2..674) TEXT:2(79..646) TILE:1(4626) TMPL:2(56..112) TxSt:8(9..12)
  WDEF:4(6) WIND:10(22..30) actb:3(48) acur:1(36) cfrg:1(144) cicn:3(322..922) clut:1(2056)
  crsr:57(202..570) dctb:14(48) icl4:20(512) icl8:6(1024) ics#:4(64) ics4:4(128) ics8:4(256)
  mctb:1(1266) pltt:1(4112) ppat:2(126..270) snd:13(132..45192) styl:2(42..162) vers:2(35..42)
  xmnu:1(252). Read by code: `Lite` (light masks, engine-classes §3.3), `STR#` 9300–9321 (AI
  vocabulary), 500–503 (combat buttons, equipment slots, behaviour names, help), `Page` (help),
  `MENU`/`CMNU`/`xmnu`, `DLOG/DITL/WIND/CNTL`, `crsr/acur`, `snd` (interface sounds), `clut`.
- **Cythera Data.rsrc** — 113 resources, 18 types: DATA:10(2..8192) FILT:7(6180..8228)
  FOND:2(66..678) LINF:3(12) MSta:3(64) NFNT:2(904..1478) PICT:19(3088..419744) PORT:2(413..2351)
  RMAP:1(16) STR#:5(27..1141) TMPL:2(66..111) TxSt:12(4..16) clut:1(2056) eBRS:25(32)
  eSTM:16(132..164) nrct:1(66) sfnt:1(19220) vers:1(35). Read by code: `FILT` (displacement
  filters). `STR# 135` = 41 level names ("World", "Odemia", "LKH", …, matching map segments
  0x8001–0x8029), `STR# 128` = default talk topics, `STR# 134` = editor object categories,
  `STR# 255` = credits, `STR# 900` = registration strings. `PORT`, `LINF`, `MSta`, `eBRS`, `eSTM`,
  `RMAP` have **no 4CC reference in the PPC code** (`grep -c 0x504f5254` etc. = 0) — editor or
  68K-only leftovers. NOT RESOLVED.
- **Cythera Documentation.rsrc** — 268 resources, 40 types (a self-contained documentation
  viewer: CODE:9, conp:18, PICT:62(400..185492), TEXT:10(1964..11295), styl:10, pInf:82 …). The
  manual text oracle; out of scope as code.
- **AI Scripting Document.rsrc** and every **`*.ai.rsrc`** (8 files) — 2 resources each:
  BBST:1(1048), MPSR:1(72) (editor state; ai-scripts.md §7).

## NOT RESOLVED (consolidated)
Data format
1. Segment file header bytes 0x00–0x7F (title "Cythera: Fate of Alaric", version word at 0x40 `1300 0200`) — `SegFileHeader::CompatibleVersions(a,b)` (same major byte, b.minor ≤ a.minor) is known, but which header field it compares was not traced.
2. Script pages 0x01, 0x03, 0x05, 0x08, 0x0A–0x0F: which script kind each page holds (beyond 0x02 string tables, 0x04 AI, 0x09 AI routines, 0x10–0x1E object classes, 0x30 routines).
3. Segment 0x0210 stored plaintext and 0x0101 not decryptable with its id key.
4. Map header +0x04 and +0x14..+0x1F; chunked-map body offset `C*0x40` vs `C*0x80`.
5. Prop bytes +0x0A..+0x0B and +0x0E..+0x0F; kinds 0x11 and 0x80; 'B' frames 0, 1, 3, 4, 6, 7 semantics.
6. Globals 0xF005, 0xF007, 0xF00A, 0xF014, 0xF015 (no reader), 0xF008, 0xF00D, 0xF011, 0xF012 meanings; 0xF00F arrival byte meaning.
7. CharEntry +0x12 role beyond busy counter naming, +0x17, +0x18, +0x1D, +0x1F.
8. Save stream: the four `hhhh` values; encodings of `SaveMonsters`, `WriteFXQueue`, `MarshalAll`, `SaveGremlins`.
9. Music (0x9000+) and sound (0x9100+, `'asnd'` header confirmed) formats.
10. Resource types PORT/LINF/MSta/eBRS/eSTM/RMAP; `Lite` 128–133 use.

Script VM
11. ~~Builtin opcodes 0xA0–0xFF: target table unresolved~~ — **RESOLVED** (⚑ corrected (review 2026-10-03)): TVector table at TOC+0x1FF0 = 0x100D7270, 95 bodies decompiled and read → `script-builtins.md`. Remaining builtin unknowns (unnamed glue callees, a few argument meanings, iterator loop shape) are listed in its §4. Combat to-hit/damage is **not** a builtin (→ item 15).
12. Class ids 0x28, 0x48 meanings. (⚑ corrected (review 2026-10-03): 0x50 = spell/skill classes keyed by prop type — decrypted 0x1A00/0x1A01 are spells, builtin 0xF5 makes skill props class-0x50 objects; the 0x50/0x58 overlap is a data invariant, types < 0x100 — script-vm.md §2.1.)
13. Statements 0x8E/0x8F I/O helper identities; keyword compare semantics (`FUN_100b6dc8`).

AI / rules
14. Mapping CharEntry +0x1E values < 0xB0 → built-in tactics; who calls `PerformAI` / `CompileAIFile` (no direct caller in the dump; no builtin calls them). ⚑ corrected (review 2026-10-03): `EditUserBehaviors__Fv @ 100b1b38` (constructs `TEditUserBehavior`) is the likely `CompileAIFile` owner [MED] — ai-scripts.md §6.
15. Combat to-hit/damage/armour/XP (script selector 28 — script bytecode, not a builtin); spell internals (`TSpellFX`; the script-facing add/remove/temp/has-ability builtins are now known, script-builtins.md); trading; alchemy; what over-encumbrance does.
16. Wall-clock pacing of `MoveAll`; `Render__7TViewer` details; per-body meaning of the sky-object parameters.
17. ~~"afternoon" unreachable — confirm with disassembly~~ — **CLOSED** (⚑ corrected (review 2026-10-03)): confirmed by disasm at 0x10093D60 (engine-classes.md §3.3).
18. Global override byte `PTR_DAT_100cde4c` (all-ally) — who sets it.

19. Builtin rows labelled MED/LOW and the open items in `script-builtins.md` §4 (glue callees in A2/A6/B5/DB/E7/EA/EB/ED/EE/F8, D0's monster word 0, FC's viewer flag, E2's `TBres` callback, iterator loop shape).

Out of scope (identified only): registration, InputSprocket, CD audio, desktop-comment copying,
AppleEvents, `TSanity`, `Audt`, the documentation viewer app.

## Append rule
New findings go into the topical file (or a new topical file ≤ ~600 lines) **plus one line
here** (in the Files table or the NOT RESOLVED list). Never grow a monolith; every claim keeps its
`name @ addr`, quoted lines, resolved constants with the command used, and a per-claim label.

## Review ledger
**2026-10-03 — verdict ACCEPT_WITH_FIXES** (20 findings, 2 Critical; full text `REVIEW-2026-10-03.md`;
fix pass summary `FIXPASS-2026-10-03.md`). Every fix is marked `⚑ corrected (review 2026-10-03)` at
the cited place.
1. Critical — 0x53/0x54 swapped (0x53 = `!=`, 0x54 = `==`) → script-vm.md §5 table row.
2. Critical — args/locals reversed (0x00–0x2F locals = TInterp[1], 0x30–0x3F args = TInterp[0]) → script-vm.md §3 frame text, §4 0x82 row, §5 0x00–0x2F / 0x30–0x3F rows, §5 worked decode (`local0 = Routine0F02(arg0, 1)`).
3. Important — builtin table resolvable → script-vm.md §6 rewritten; new `script-builtins.md` (95 bodies decompiled by `tools/CyDecompBuiltins.java`); NOT RESOLVED 11 closed; rules.md intro.
4. Important — MoveCommand auto-`DoUse` of property-0x3A props → rules.md §2 "Map edges / auto-use on step" row (MED → HIGH).
5. Important — 0x9C extra integer operand for seg ≠ 0xFFFF → script-vm.md §4 0x9C row (+ §5 0x9B–0x9F row).
6. Important — map-header exits MED → HIGH + half-edge fallback → data-format.md §3.1 rows 0x0C–0x12 and the paragraph after the table.
7. Important — "Hurt" unreachable in `DrawStatPart` → rules.md §1 health-categories row.
8. Important — `MatchStr` is prefix-of-token → ai-scripts.md §1.
9. Important — `EditUserBehaviors__Fv @ 100b1b38` + unmentioned game-logic names → ai-scripts.md §6, engine-classes.md §2.3 (row + names list before §2.4), NOT RESOLVED 14.
10. Minor — dictionary header 0xA0–0xAF only; 0xB0–0xBF returned unchanged; `Len` of a dict = 0 → script-vm.md §1 literals paragraph.
11. Minor — tag-3 string index clamps to `count−1` → script-vm.md §1 tag table row 3.
12. Minor — 0x9B with class 0 pushes an int/id, creates nothing → script-vm.md §4 0x9B row.
13. Minor — class 0x50 = spell/ability classes; overlap is a data invariant → script-vm.md §2.1 class row + note; NOT RESOLVED 12.
14. Minor — "afternoon" unreachable confirmed → engine-classes.md §3.3; NOT RESOLVED 17 closed.
15. Minor — 0xF00E absent from shipped data → data-format.md §5 0xF00E row.
16. Minor — sounds begin `'asnd'` → data-format.md §1.5 row 0x9100+n; NOT RESOLVED 9 wording.
17. Minor — page 0x0B (and 0x01) have 1 segment → data-format.md §1.5 row 0x02xx–0x0Fxx.
18. Minor — zone minimum floors at `zoneMin / 3` → engine-classes.md §3.3.
19. Minor — statement 0x80 invalid; 0x9D non-object receiver → script-vm.md §4 (new 0x80 row, 0x9D row).
20. Minor — unlabelled "Combat AI" pointer row → rules.md §1 (labelled as a pointer row).
