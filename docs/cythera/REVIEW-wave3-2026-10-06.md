# Cythera 1.0.4 RE wave 3 — Fable revision review (2026-10-06)

⚑ wave 3 (2026-10-06) — Fable-grade revision pass over the wave-2 review (which ran on Opus 5.5) and
review of the wave-3 commits. Scope: `git diff 0444b1c..e3138e3 -- docs/cythera/` (wave 2, 28 files) and
`git diff 4333e18..HEAD -- docs/cythera/` (wave 3: `render.md`, `notes-w3-render.md`, six tools, README
rows, engine-classes §3.4/§5 and magic §11 pointers, open-items evidence block, INDEX). Every claim in
§2 was re-derived this session from the worktree root with the banked tools (`$S` = the session
scratchpad; `$S/all.dis` = `python3 docs/cythera/tools/ppcdis.py 10000000 100cd280`, 212,074 lines;
`p:` / `m:` / `x:` = lines of the main / missing / extra dumps). Where the Opus review already checked a
claim I chose a different one. No bank file was edited.

## Verdict: **ACCEPT_WITH_FIXES**

0 Critical · 1 Major · 11 Minor · 8 Notes. **116 claims re-derived, 113 PASS, 3 FAIL** (all three are
Minor: a stale reader list, a count, and a byte dump that does not reproduce; no closure is
overturned). Every wave-2 closure (5, 6, 10, 14, 19, 21, 22, 23, 24, 25, N2) and both wave-1 overturns
(item 22, rules.md §3.4) hold; the wave-3 closure of item 16 (layer order) holds. Hazard sweep clean:
no stray `--help` file (`ls -la | grep -i help`, `ls docs/cythera/tools | grep -i help` → nothing);
no `ppcdis.py` call ≥ 0x100CD280 in either diff; every `find_func.py` in the diffs passes `--file`;
no wave-1/2 text deleted by wave 3; bank sizes ≤ 620 lines (combat.md 620, pre-existing).

## 1. Findings

### Critical
None.

### Major
**M1 — data-format.md still carries three pre-wave-3 readings that render.md overturns, unmarked**
(confidence HIGH on the defect; the render.md readings themselves re-derived below).
`notes-w3-render.md:21` lists them as follow-ups, but the wave-3 commits touch neither file:
- data-format.md:310 `| 0x04, 0x24 | on map, drawn as roof layer (priority 7) | SetStage … local_72 = 7 | MED |`.
  Re-derived: `1004f484: 38000004 li r0,4` / `1004f48c: 98040000 stb r0,0(r4)` and `1004f8c4: 38600024
  li r3,36` / `1004f8d8: 98780000 stb r3,0(r24)` (both in `HatchEgg @ 1004f420`, `tb.py --at`); Render
  pass 4 `kindMask 0x0044 / kindVal 4` (`toc.data_u32(0x100d5fa4,24)` words 8/… → `0x44ff9e`,
  `0x10001`); roofs are kind `'D'` 0x44 drawn by `ApplyRoof` (p:33499 `if (*pcVar14 == 'D') {`).
  Priority 7 never reaches the stage's best-prop word (p:31634 `&& (local_5e != 7)`).
  Fix: append `⚑ wave 3 (2026-10-06): superseded — 0x04/0x24 are creature bodies (HatchEgg 1004f484 /
  1004f8c4), drawn in Render pass 4 above every object layer except tile-flag-0x10 props; roofs are
  kind 0x44 via ApplyRoof. Priority 7 feeds the 124×124 occupant grid, not drawing (render.md §2.4, §5).`
- data-format.md:211 `| 13 (0x2000) | draw with the transparent mask variant (TMaskTile) | … | MED |`.
  Re-derived: `TCopyTile @ 10062de4` / `TMaskTile @ 10063534` write destination row k from source column
  k (render.md §2.3 quote, re-read); Render picks `TCopyTile` at `100675f8` for ground words with 0x2000
  and `t ^ 0x2000` at every mirrored prop site (`10067e80: 6b242000 xori r4,r25,0x2000`).
  Fix: append `⚑ wave 3 (2026-10-06): 0x2000 selects the transposed copy (diagonal flip), not a mask
  variant — render.md §2.3/§2.5.`
- data-format.md:292 `| 4 | bit 7 of byte 4 | mirror: swaps multi-tile extension direction 0x40↔0x80 |`.
  Correct for `SetStage` (`10065b74: cmpwi r4,64` … `10065b94: li r4,64`), incomplete for drawing.
  Fix: append `⚑ wave 3 (2026-10-06): in Render the same bit transposes every tile (t ^ 0x2000) and
  swaps the up/left extension cells — render.md §2.5.`

### Minor
**m1 — render.md:267–268 reader list of the quarter-tile grid (+0x15FF4) is incomplete** (HIGH; FAIL in
§2). `awk '/^\/\/ ==== /{fn=$0} /0x15ff4/{print fn}'` over the three code dumps → `BuildStageEntry` ×2
(1006b76c, 1006b4c8), `ClearMonstStage @ 1006ac14`, **`GetBestPropRel @ 1006b2e0`** (its body lines
303–304: `if (*(short *)(param_1 + (param_3 + 0x3c) * 0xf8 + (param_2 + 0x3c) * 2 + 0x15ff4) != 0) return …`),
**`GetBestProp @ 1006b188`** (body lines 763/774), `HatchEgg`, `InteractProps`, `SetMonstStage @ 1006aed8`,
`SetStage`, `SwitchParty`. So the grid is consulted **first** by the two targeting lookups — which
strengthens the "occupant grid" reading (creatures are targetable through it) but the text names only
three readers. Fix: replace "Readers: `HatchEgg`, `SwitchParty`, `InteractProps` (grep `0x15ff4`)" with
the full list and add "`GetBestProp`/`GetBestPropRel` test the quarter cell before the stage's best-prop
word, so priority-7 props are found through this grid".

**m2 — open-items-2026-10-06.md:364 "25 sites"** (HIGH; FAIL). `grep -c 'send_signal(' ghidra/cythera-scripts/*.txt`
summed = **26** (0C48, 0D06, 1025, 108E, 1099, 10BB ×2, 10C1 ×2, 10E8 ×2, 109A, 1107 ×2, 1100 ×2, 1104,
1110, 1162, 1175, 1165, 1417, 1864 ×3, 3043). Fix: "26 sites".

**m3 — open-items-2026-10-06.md:322–323 PORT 1 head bytes do not reproduce** (MED; FAIL). `rsrc.parse` +
`lz.unlz` (returns `(bytes, consumed)`): raw head `c3 b2 80 01 3e 75 30 28 22 24`, decoded head
`b2 80 01 3e 75 30 28 22 24 20 00 13` (4096 B, consumed 2351, 204 distinct values); the quoted
`00 0b 5d e8 01 3e 75 40` appears in neither. PORT 0 reproduces exactly (0 ×3830, 255 ×266). Fix:
replace the quoted bytes with the decoded head above (role stays LOW).

**m4 — six new tools: no argument handling** (HIGH). `scan_byte7.py --help` and `scan_clr80.py --help` →
`FileNotFoundError: [Errno 2] No such file or directory: '--help'` (traceback, exit 1);
`tileflag_census.py --help` / `tileflag_census.py zz` → `ValueError: invalid literal for int() with base
16`; `tileflag_census.py --eq` alone silently applies `--eq` to the four default masks; `props_census.py`
/ `f008_dump.py` ignore every argument. No stray file is written by any of them. Fix: a four-line
guard in each `main` (`if argv and argv[0] in ('-h','--help'): print(__doc__); return`) and, in
`tileflag_census.py`, reject non-hex with a message.

**m5 — render.md:46 cites p:31292 for the LUT line** (HIGH, nit). `grep -n 'pbVar5 = \*(byte \*)(param_2 +
(uint)\*pbVar5)'` → **p:31295** (p:31292 is `iVar3 = (*param_1 + 1) * 0x20;`). Fix the line number.

**m6 — render.md:69 "census of every `r31`-relative operand"** (HIGH, nit). Offsets actually used off
r31: 0, 2, 4, 12, 13, 16, 120, 176, 180, 185. +0xB8 and +0xBA are read off **r3** at entry
(`10066adc: a9c300ba lha r14,186(r3)`, `10066b08: 89c300b8 lbz r14,184(r3)`). Wording: "every
viewer-relative operand (r31, and r3 before `mr r31,r3`)".

**m7 — open-items-2026-10-06.md §7 holds two verbatim prose quotes** (LOW). The `end_game("You have
damned Cythera to darkness.")` line (game text) and the hintbook sentence (line 353). The INDEX m8 ruling
exempts engine/UI labels but names "dialogue, books, hintbook" as prose, so this section is at two.
Fix: paraphrase the hintbook step and keep the line number.

**m8 — notes-w3-render.md is 205 words by `wc -w`** (LOW). 192 without the H1 line; the wave-2 notes
were measured "before the INDEX block" and this file has none. Fix: trim 5 words or append the INDEX
block convention.

**m9 — INDEX.md:17 "tools" provenance row does not list the six wave-3 tools** (LOW). Only
`tools/README.md` has them. Fix: add `⚑ wave 3 (2026-10-06): tileflag_census.py, props_census.py,
f008_dump.py, scan_clr80.py, scan_byte7.py, listing.py (open-items recipes A–D, render §2.4 census)`.

**m10 — ui-play.md:308 "you see a stranger's belongings only while standing next to them"** (LOW,
register). Behaviour phrasing inside a HIGH code paragraph (the code fact — `CloseAtDistance` shrinks
the window to 0x42 px when not adjacent — is right and re-derived). Fix: "(code: the window shrinks to
the portrait strip unless the character is adjacent)".

**m11 — render.md §5 does not cite SetStage's extension dispatch** (LOW, completeness). The single-ext
cases agree with Render and the proof is one window: `10065bb4: cmpwi r0,128 / beq 0x10065dc0` →
`10065de4: stwu r0,-8(r19)` (left, t−1); `10065bc0: cmpwi r0,64 / beq 0x10065be4` → `10065c08: stwu
r3,-248(r19)` (up, t−1); `10065bd8: cmpwi r0,192 / beq 0x10065f98` → the three-store chain. Adding it
makes the "only 0xC0 disagrees" sentence self-contained.

### Notes
**N1 — item 22's overturn rests on two VM facts, both re-derived.** (a) `IsTrue @ 10080964`: `if (param_1
== *(uint *)PTR_DAT_100cddec) return true;` and script-vm §5 (`__sinit_THeap_cp` sets that word to
0x50000001) — so in `DoExpr` case 0x54 (p:41650) "equal → push `*puVar5` = `PTR_DAT_100cddec`" is `==`
and case 0x53 is `!=`. (b) `DoInterpAt`'s 0x8D handler (p:42808–42821, the `else if (local_88 < 0x8e)`
branch after 0x8E): `cVar15 = _IsTrue(…); if (cVar15 == '\0') { … puVar17 = (ushort *)(param_2[2] +
(int)(short)local_64); } else { puVar17 = local_50[0] + 1; }` — jump when false. With the bytes
`0445: 8d 30 62 06 41 00 54 40 04 58`, quality 0 falls through to `044F set_variable(0, 2)` and 1802
`02F8 jf (get_variable(0) == 2) -> 0539` falls through to `050A end_game(damned)`. Confirmed.
**N2 — rules.md §3.4 overturn.** r19 = `IsVisibleAbs` of the prop's own x/y (`10006540: lwz r0,0(r30)` /
`10006544: lha r4,2(r30)` → `bl 0x1006ab28` at 10006564 → `1000657c: rlwinm r19,r3,0,24,31`); r23 =
`IsVisibleAbs` of the packed new location r29 (`10006588`/`1000658c` → `bl` at 1000659c → `100065b0`);
both forced 0 when the prop's kind has 0x80 (`100065c8: rlwinm. r0,r0,0,24,24` → `li r23,0 / addi
r19,r23,0`). `10006694: rlwinm. r0,r19 / beq 0x10006714` → old visible: `100066a4: stb r25,22(r31)`;
else `10006714: rlwinm. r0,r23 / beq`, `1000671c: cmplwi r28,0x0 / beq` (r28 = `GetCharacter` result),
`10006724: li r0,128 / 10006728: stb r0,22(r31)`. Confirmed.
**N3 — pacing (engine-classes §3.4, app-shell §3.3).** `MyScheduler` m:5660–5785 re-read: the anim
thread is chosen only on the final `else` path; `next` advances by `DAT_100d3e20 >> 2 & 0xf` (m:5753
from `next` when early, m:5756 from `now`); the byte read is `1001ce60: 881a0000 lbz r0,0(r26)` with
`1001cb9c: addi r26,r2,-5216 ; = 0x100d3e20`; static word 0x98C00000 and all four CPU defaults give
F = 6; MENU 136 items 10/11/12 = "Limit to 16 / 10 / 8 FPS" (`rsrc.parse`). "At most 10 frames/s" is
right. One sharpening available: in mode 3 (m:5740–5744) the scheduler spins **to** `next` and then runs
the frame, so while the leader is stepping the spacing is exactly F ticks, not merely ≥ F. LOW.
**N4 — pass-2 dead test (render.md §2.4) holds with the strongest form.** Over all 2,191 instructions of
Render (10066ac0–10068cfc) the only writes to 148(r1) and 150(r1) are `10067a74: b1c10094 sth
r14,148(r1)` (r14 ← `10067a4c: li r14,1` via 496(r1)) and `100679f8: sth r14,150(r1)` (the kind); the
frame is fixed (`stwu r1,-816(r1)` once, `addi r1,r1,816` at exit; no r1-indexed stores). Then
`10067a98: and r13,r14,r13` (r13 = A at 156(r1) ← table 0x100d5fa4) / `10067a9c: cmpw r15,r13` (r15 = B
at 154(r1) ← 0x100d5fb0) / `bne 0x1006875c`. A = [0,0,1,1,0,0], B = [0,0,0,1,0,0] → pass 2 false.
**N5 — "Render never reads the stage" holds.** All 27 `addis …,1|2` sites in Render resolve to +0xC0C9,
+0xC1EC, +0x1FC18/+0x1FC1A or +0x20C1C..22 (table in §2); there is no `lis` in Render; the whole-dump
`0x141ec` readers are `BuildStageEntry` ×2, `IsStraightAbs`, `SetStage` only, and none of Render's
callees (`CopyTile`, `TCopyTile`, `CopyCompoTile`, `TCopyCompoTile`, `MaskAnyTile` ×2 forms, `AdjustPropFX`,
`NewPix`, `RenderMissiles` via `bl 0x100c50e8`, three glue calls) appears in that list.
**N6 — CMNU 129 command words** verified from the raw resource bytes (`00 4f 00 00 | 00 00 00 03` after
"Open Game"; `03 e8` Close Window, `05`, `06`, `6a`, `07`, `02 ee` Preferences) — my item parser
mis-stepped, so the table row is PASS on the dump, not on a clean decode.
**N7 — TSimpleInteraction +0x114/+0x118/+0x11C** are zero / past the vtable's end; the "—" cells in
dialogue-ui §0 are right.
**N8 — Opus m7 is fully discharged**: all four recipes are banked, stdlib, and print byte-identical
output to the evidence block (A, B, C, D run both with `all.dis` and in-process; 0.02–0.5 s).

## 2. Claims re-derived

| file § | claim | command (abridged) | result |
|---|---|---|---|
| render §2.4 | six per-pass tables = §0 word dump | `toc.data_u32(0x100d5fa4,24)` split u16/u32 | PASS (kindMask ff9e×4,0044,ff9e; A 0,0,1,1,0,0; B 0,0,0,1,0,0; flagMask/Val as table) |
| render §2.4 | table bases loaded at 10067744/4c/60/74/c4/d8 | `ppcdis.py 10067740 100677f0` | PASS |
| render §2.4 | kind test `and r13,r15,r13` / `cmpw r14,r13` at 10067a68/a7c; r15 = 150(r1) kind | disasm 10067a40–10067ab0 | PASS |
| render §2.4 | dead test: `li r14,1` 10067a4c → 148(r1) sole store 10067a74; and/cmp 10067a98/9c | python scan of all 2,191 Render lines for `(148|150)(r1)` and r1 moves | PASS (N4) |
| render §2.4 | pass loop 162(r1) 0..5, `cmpwi r13,6 / blt 0x100676ec` at 1006878c/90 | `ppcdis.py 10068780 10068798` | PASS |
| render §2.4 | RenderMissiles at pass 5: `cmpwi r13,5` 100676f0 → `bl 0x100c50e8` 10067704 | `ppcdis.py 100676e0 10067710` | PASS |
| render §2.4 | r20/r19 = flagMask/flagVal at 10067804/10067818 | disasm 100677f0–10067840 | PASS |
| render §2.4 | list walk last→first: `lha r13,152(r1)` / −1 / `bge 0x10067838` | `ppcdis.py 10068750 10068780` | PASS |
| render §2.4 | kinds 4 (`1004f484`/`1004f48c`) and 0x24 (`1004f8c4`/`1004f8d8`) written in HatchEgg | disasm + `tb.py --at` | PASS |
| render §2.4 | census 0x10 295 / 0x200 973 / 0x100000 295 / 0x10000000 22; `--eq 0xc0` 79; `--eq 0x100010` 1 cavern; `--eq 0x210` 72 | `tileflag_census.py` | PASS |
| render §2.4 | AdjustPropFX only in pass 5 and only for FX ≠ 0 | `ppcdis.py 100678d8 10067914` (`cmpwi r14,5 / bne`, `cmplwi r14,0x0 / beq`) | PASS |
| render §2.1 | +0xC cleared on exit `10068ce4: stb r13,12(r31)` | `ppcdis.py 10068cd0 10068cfc` | PASS |
| render §2.1 | 27 `addis` sites → +0xC0C9 / +0xC1EC / +0x1FC18/1A / +0x20C1C..22; no stage read | python scan + `addi` operands (−16183, −15892, −1000, −998, 3100–3106) | PASS (N5) |
| render §2.1 | field census | r31 operand set {0,2,4,12,13,16,120,176,180,185} | PASS (m6 wording) |
| render §2.2 | gate `10066b08 lbz r14,184(r3)` / `10066b3c beq 0x10067038`; fill `10066b70 bl 0x100b46a0`; `cmplwi r14,0x42` 10066c04; `cmplwi r7,0xa` 10066c24; `bge` 10066c50; `addi r14,r14,34` 10066e28; NewPix 10066d50 | grep each address in `$S/all.dis` | PASS |
| render §2.2 | SetStage sets +0xB8 (p:31463); SetEraseColor(…,0xff) from ChangeZone (p:27705) | sed / grep | PASS |
| render §2.3 | `10067058 rlwinm. r13,r13,0,30,31`; `10067084 lwz r4,1020(r15)`; `1006732c ori 0x8000`; `1006733c cmpwi r15,2`; `10067448 rlwinm. …,3,3`; calls 10067480/1006751c/1006758c/100675f8/10067654 to MaskAnyTile(ll)/TCopyCompoTile/CopyCompoTile/TCopyTile/CopyTile | grep + `bl` census of Render | PASS |
| render §2.3 | rows/cols −h…h+1 (p:32488–32492) | sed | PASS |
| render §2.5 | 12 `MaskAnyTile(…lls)` calls; r5 = x, r6 = y | `bl` census (12 × 0x10063cc0); `MaskTile` body line 446 `param_3 * 0x20 + rowBytes * param_4 * 0x20`; `MaskAnyTile` 10063cd4/d8 r5→r25, r6→r26 | PASS |
| render §2.5 | unmirrored 0xC0: t−1 at (x−1,y) 10068634; t−2 at (x,y−1) 100686c0; t−3 at (x−1,y−1) 10068750 | `ppcdis.py 100685f0 10068754` (`addi r4,r25,-1 / addi r5,r15,-1 / extsh r6,r27`; `addi r4,r25,-2 / extsh r5,r28 / addi r6,r13,-1`; `-3 / -1 / -1`) | PASS |
| render §2.5 | 0x40 → (x,y−1) 100684e4; 0x80 → (x−1,y) 10068584; mirror sites xor 0x2000 and swap | disasm 100684c0–100684e8, 10068560–10068588, 10067f8c–10067fb4, 10068058–10068080, 10067e70–10067e94 | PASS |
| render §2.5 | ext flag test reads `tileflags[t−k]` (`10068688: addi r15,r13,-2` → `lwzx` 10068690) | disasm | PASS |
| render §2.5 | mirror bit `10067dd8 rlwinm r14,r15,25,31,31` / `10067df0 beq 0x10068340` | grep | PASS |
| render §5 | SetStage 0xC0 cells: `10065fbc stwu r4,-248(r19)` t−1; `10066190 stwu r0,240(r19)` t−2; `10066364 stwu r4,-248(r19)` t−3; stride 248 = 31·8 (`mulli r5,r5,248` 10065694, `rlwinm r8,r3,3,0,28`, `+16876` = 0x141EC) | `ppcdis.py 10065034 10066730` greps | PASS |
| render §5 | mirror swaps only 0x40↔0x80 (`10065b74`–`10065b98`); 0xC0 untouched | disasm | PASS |
| render §5 | single-ext dispatch: 128 → −8 (left), 64 → −248 (up), 192 → chain | `ppcdis.py 10065ba0 10065c10`, `10065d98 10065df0` | PASS (m11) |
| render §5 | ladder p:31576–31627; `local_5e != 7` p:31634; cell = `(dy+15)*0xf8 + (dx+15)*8 + 0x141ec` | sed | PASS |
| render §5 | GetBest* callers = Look/Search/UseOn/ShortName/Move/XDirection/CursorRoutine/FindSurface/PointToProp/KeyTargetToProp/TLineEffect | awk over four dumps | PASS |
| render §5 | +0x15FF4 readers = HatchEgg, SwitchParty, InteractProps | awk over three dumps | **FAIL** (m1: + GetBestProp, GetBestPropRel, SetMonstStage, ClearMonstStage, BuildStageEntry ×2) |
| render §6 | SetStage list ≤ 0x1000 (+0x1DC16); Render list ≤ 0x800 (`param_1[0xfe0c] < 0x800`) | decompiled SetStage lines 160–163; LOS/NoLOS lines | PASS |
| render §6 | NoLOS sets cells to 1; LOS keeps leader + state 1 or state 2 with 0x420 | p:33624–33644, p:33914–33960 | PASS |
| render §1 | DrawRoutine chain 1005cd4c LOS / cd64 NoLOS / cd78 InteractProps / cd8c CalcLighting / cda0 DimOffLevel / cdbc Render / ce04 ApplyRoof / ce34, ce8c ApplyFilter / cec8 ApplyLight / cef4 glue / cf2c ShowBarks / cf70 MaskTile | `ppcdis.py 1005cd40 1005cf80 \| grep bl` | PASS |
| render §1 | p:27923 `(PTR_DAT_100cdbf0[0x1a] & 0x80) == 0`; p:27932–27934; p:27954–27959 tile 0x186 at +0x20C32/34 + h | sed | PASS |
| render §1 | ApplyFilter LUT line | grep → p:31295 | PASS value / **nit** p:31292 (m5) |
| render §1.1 | ApplyRoof p:33499 `'D'`, p:33542 leader roof cleared, p:33567 MaskAnyTile(ll), p:33569 `& 3) == 0 → \| 3`, p:33588 | sed | PASS |
| render §4 | FX byte: `NewPtrClear(0x4400)` p:432–434; GetField p:47521; SetField p:47893; MoveAll p:21564/21607; FollowLeader p:21902; `100678e8 lbzx r21` sole r21 write; `10067968 stbx` | grep / sed / r21 scan | PASS |
| render §3 | `10067ad4`, `10067b2c cmplwi 0x4`, `10067b38 cmplwi 0x24`, `10067b60 rlwinm. …,17,17`, `10067bcc rlwinm …,26,0,6`, `10067b20 add r25` | grep | PASS |
| render §2.6 | `100687a0 lha r14,-1000(r14)`, `10068890 blt 0x10068ca8`, `10068a60 subfic r13,r13,32`, NewPix 10068998, glue 10068c70/ca0 | grep | PASS |
| render §2.6 | restore p:33437 `*(int *)(param_1 + 0x58) = local_2a0;`; fill p:32331; CopyBits p:32462 | sed | PASS |
| engine-classes §3.4 | MyScheduler: frame only on the final else; `next += F` / `= now + F`; mode-3 spin to `next` | m:5660–5785 read | PASS (N3) |
| engine-classes §3.4 | byte read `lbz r0,0(r26)`, r26 = 0x100d3e20 | `ppcdis.py 1001cb94 1001ced8` | PASS |
| engine-classes §3.4 | word 0x98C00000; defaults 0x18800000 ×2, 0x99800000, 0xDBC80000; F = 6 | `toc.data_u32` | PASS |
| engine-classes §3.4 | DefaultMenu 10/11/12 `& 0xc3 \| 0x10/0x18/0x20` (m:4949/4955/4961); MENU 136 labels | sed; `rsrc.parse` | PASS |
| engine-classes §3.4 | AnimThread loop (m:10843–10857), no wait; DoTick mode 3 + Yield (p:21461–21467) | sed | PASS |
| engine-classes §3.4 | `ColorCycle` one caller 100432c4 in AnimThread; body `blr` | grep `$S/all.dis`; `ppcdis.py 10008694 +1` | PASS |
| missing-census §0 | 840 rows / 158,680 B; class counts; TWidget 17; free 23 | §0 classifier re-run | PASS |
| missing-census §1 C | TTaskMaster 3/2,496 (2/2,408 + dtor 88); TaskThread 0x624, MyScheduler 0x344 | classifier; `tb.py --at` | PASS |
| missing-census §1 E | `WantAutoKey__9TConvMode` returns 1 (m:9208) | sed | PASS |
| missing-census §2 | item 14: 8 `bl` sites (DoMove ×6, 100b1854, 1002f390); toc word scan → only 0x100d05c8 | grep; python | PASS |
| missing-census §2 | item 23: `bl 0x10053794` at 100542f8/1005cba0/1005cc00/1009844c | grep | PASS |
| missing-census §2 | item 5: `MyCDEF case 0x11:` m:12109 | sed | PASS |
| missing-census §4 | A0 RangeIter 10083CA8, D3 cbPlaySound 100985C0, D4 cbPlaySoundSync 1009874C, C5 cbSendSignal 10098418, FE cbDebugStr 1009B12C | `tb.py --at` | PASS |
| ui-play §0 | vtable 0x100D47F4 slots +0x24/+0x28/+0x84/+0x9C/+0xA8/+0xB0 | toc→TVector→`tb.py` | PASS |
| ui-play §0 | `PTR_DAT_100cdd00` writers p:17771 (=1) and m:8817 (=0) only | grep four dumps | PASS |
| ui-play §1.4 | CloseAtDistance inequality m:7701–7704 | sed | PASS |
| ui-play §1.5 | cmpprops repeated frame test m:8424/8427 | sed | PASS |
| ui-play §2.3 | "(Not weildable)" at 0x100C60CC | code bytes at file 0x3470+0xC60CC | PASS |
| ui-play §2.5 | +0x1E := refcon m:7279; `(char)sVar9 + -0x53` m:7307 | sed | PASS |
| ui-play §4.3 | scratch prop 0x3FFF (kind 0x1C, type 0xFF−refcon), `DoUse(0x40503fff)`, `HeartBeat(0)` m:8061–8073 | sed | PASS |
| ui-play §5.1 | PointToCoordinate refusal `DAT_100d3e20 < '\0'` + byte-6 `& 3` / `>> 4 & 3` | find_func | PASS |
| ui-play §5.3 | ResizeRoutine `((min+32)>>6)*2+1`, window n·32−32; HandleResizeWindow 128..448 | find_func | PASS |
| ui-play §7 | to-do details index `+ 0x400` m:13095 | sed | PASS |
| ui-play §8 | journal colours (255, 1, 5, 8) at 0x100D6578 | `toc.D` → `00ff 0001 0005 0008` | PASS |
| dialogue-ui §0 | TConversation slots +0x24/6C/70/E4/F4/F8/104/114/118/11C; TSimpleInteraction +0x24 = TScriptedWindow::CloseRoutine | toc→TVector→`tb.py` | PASS (N7) |
| dialogue-ui §0 | TOC strings 100ce7ec…100ce7c0 | `toc.py` | PASS |
| dialogue-ui §1 | `WantAutoKey__13TConvMoreMode` returns 0 | find_func | PASS |
| dialogue-ui §2 | GetInteractRect `SetRect(…,0x74,0xbc,0x200,0x114)` | find_func | PASS |
| dialogue-ui §3 | TTextOut hint word in 0x199 | find_func | PASS |
| dialogue-ui §4 | TConvMoreMode Key 0x1B → +0x38 = 1 | find_func | PASS |
| dialogue-ui §6 | chip 0xCD inside / 0x45 outside; `PlayIFSound(0)` | find_func | PASS |
| dialogue-ui §7 | slot +0x11C only at 10035bb4; 8 `bl 0x10035b88` all in `KeyRoutine__10TMapWindowFs` | grep + `tb.py` | PASS |
| dialogue-ui §8 | HowMany ctor step 1 (p:18946); slider proc 0x3e91 (p:18880) | grep | PASS |
| dialogue-ui §9.1 | GetItemHeight 0x14 / 0x20; `%d`/`%s` at TOC 0x100cee20/78 | find_func; `toc.py` | PASS |
| scripted-windows §1 | ids `\| 0x41040000` (256 slots) / `\| 0x41050000` (1024) | grep + loop bounds | PASS |
| scripted-windows §1 | DispatchWindowMethod sel 4 → `*param_1 = Nil` always | find_func | PASS |
| scripted-windows §1 | DeleteSysObj `10091c90: lwz r12,36(r12)` | grep | PASS |
| scripted-windows §2.1 | sysnew use counts (12, 1, 18, 17, 1, 15, 8, 12, 1, 4, 3, 3, 2, 1, 1) | grep/uniq | PASS |
| scripted-windows §3 | CloseRoutine `1008637c li r4,1` / `10086380 bl 0x10082658` | disasm | PASS |
| scripted-windows §4 | TWidget ctor `param_1[1] = … \| 0x40000000` (p:45058) | grep | PASS |
| scripted-windows §4.1 | shortcut parse listing 1008a3a4/b0/d4/d8/dc; `Cancel/c/` 100E@026F, `Leave/l/` 300F@010C | grep | PASS |
| scripted-windows §5.7 | TWPixButton 0x40 True→0 / False→2; 0x37 True→1 / False→0 / Nil→2 | `SetField__11TWPixButtonFs5VAddr` body | PASS |
| scripted-windows §6 | 13 registrar tags → TVector → `CreateFromStream<…>` names (0x100cdf90…c0) | python + `tb.py` | PASS |
| scripted-windows §7 | `1008d4f4 rlwinm r4,r4,4,0,27`, `1008d510 rlwinm r0,r25,0,4,31`, `1008d534 li r4,10`, `1008d538 bl 0x100826f4` | grep | PASS |
| app-shell §1.1 | catch-handler strings TOC 0x100ce2b0/ac/a8/a4/a0 | `toc.py` | PASS |
| app-shell §1.3 | STR 128/129/130; Pref 128 Volume 5, Pref 129 Music 2; MemU 129 `00560000 000c0000 50` | `rsrc.parse` | PASS |
| app-shell §2.1 | InitMac +0x3A = 3, +0x1E = 1, +0x3C = 0, +0x21 = 0 | m:2951–3076 grep | PASS |
| app-shell §2.2 | event jump table (24 words; distinct handlers at 1, 3, 5, 6, 8, 15, 23) | `toc.data_u32(0x100d3f98,24)` | PASS |
| app-shell §2.3 | MyGetEvent: `+ 0x14` ticks, `*param_3 = 3`, `param_3[2] = 0x20` | m:4569–4578 | PASS |
| app-shell §3.1 | TVectors 0x2950 → MyScheduler, 0x2948 → TaskThread, 0x2E90 → AnimThread | toc + `tb.py` | PASS |
| app-shell §3.2 | m:5869 `& 0xfffffffc \| 2`; kind 4 FindSkill / 0x3FFF / DoUse / `HeartBeat(3)` | sed | PASS |
| app-shell §4.1 | MBAR 128 = [128, 129], MBAR 129 = [135]; MENU 135 "Strategy" items | `rsrc.parse` | PASS |
| app-shell §4.2 | CMNU 129 commands 3 / 1000 / 5 / 6 / 0x6A / 7 / 750 | raw bytes | PASS (N6) |
| app-shell §4.3 | MENU 200 "Party Mode", "-", 8 × "None" | `rsrc.parse` | PASS |
| app-shell §5.1 | nrct 128 eight rects as listed | `rsrc.parse` | PASS |
| app-shell §5.2 | portrait segment `+ 0x88ef`; radios `+0xE = 1/0` + `LScroll(∓1,0,…)`; end modal `+0x1D = 1` | find_func | PASS |
| ui-toolkit §0 | 15 TOC → TVector → `Create__…CDEF/WDEF`, MyMenuDef, MyCDEF, MyWDEF, MyLDEF | §0 loop re-run | PASS |
| ui-toolkit §1 | MyCDEF `' ok '` m:12037; `case 0x11` m:12109; TCDEF `NewGWorld(…,8,…)` m:12224 | sed | PASS |
| ui-toolkit §1 | `Register(iVar4,PTR_PTR_100ce09c,7,0)` p:51680 | sed | PASS |
| ui-toolkit §1 | TBorderWDEF `InsetRect(−16,−16)` m:21374; TThinBorderWDEF `(−8,−4)` m:21451 | sed | PASS |
| ui-toolkit §1 | TScrollBarCDEF `+ 0x6b800` m:22810 (= tile 0x1AE) | sed | PASS |
| ui-toolkit §1 | MyMenuDef `100a83e4: ori r4,r4,0x4000` | disasm | PASS |
| ui-toolkit §2 | InitMac `Gestalt('appr')` bit 0 → +0x16 (m:3042); AddAppearance tests +0x16 (p:238) | sed | PASS |
| open-items A–D | props_census / f008_dump / scan_clr80 / scan_byte7 outputs = evidence block | run (with and without `all.dis`) | PASS |
| open-items §1 | `1007ec88 cmpwi r3,-1`; `1007ee60 addi r5,r3,1`; push 1007ee7c; stmt `100822a0 addi r4,r3,1`; return `10081794 lwz r0,0(r28)`; 0x9D `1007f250/54` | disasm windows | PASS |
| open-items §1 | four `callx` FFFF sites (0816@007C, 0C00@0010, 0C43@0003, 0EA5@003B) | grep listings | PASS |
| open-items §2 | GetMonstAttrs ORs; HandleMove `& 2`; CanMove `& 4` → `DoInterp(9)`; TGameSys::CanMove masks; base loads (LoadGlobals, ObjToMonst, Ctor ×2, GetField); ObjToMonst callers; GetField cases 0x2C–0x33/35/36; script f32/f33 tests | find_func, `ppcdis.py --func`, grep | PASS |
| open-items §3 | 26 `stb …,22(` / 27 `lbz …,7(` → common function HatchEgg only; DoMove no byte-7 load; no `activity == 128`; 53 `f07:byte7`; HatchEgg roll p:22083; frame-7 `\| 0x80` p:27869/82/86 | grep + `tb.py` | PASS |
| open-items §4 | 8 `cmp…,17` sites and their functions | grep + `tb.py` | PASS |
| open-items §5 | `,-4091$` / `,-4089$` = 0; controls −4094/−4088; no data halfword F005/F007; no 0x8694 word | grep; python | PASS |
| open-items §6 | PORT 0/1 → 4096 B, consumed 413/2351; PORT 0 values {0: 3830, 255: 266}; PORT 1 204 distinct; no 4CC/'Lite' control | `rsrc.parse` + `lz.unlz`; grep | PASS, head bytes **FAIL** (m3) |
| open-items §7 | 1025 0445/044F/0458; 1802 02F8/050A/06E3; 184F 04B7/05B2/05CF/05DA/05E2; 10EA 00A8/00B2/00BF/00C6/00CE; 6181 = type 37 frame 6 | grep listings; arithmetic | PASS (N1) |
| open-items §8 | send_signal sites | grep | **FAIL** count (m2: 26, not 25) |
| open-items §8 | 1099 0098/00B0 (0xF79C3), 109A 005F/0070 (0xFC6), 10C1 12865/4675, 1864 ×3, 1417, 1025@05D7, 10E8 ×2, 1175 handlers @01FB/0209/0217 → sub_0063(…,132/133/134) → 00B7; 40 `sel21/signal` files | grep listings | PASS |
| open-items §9 | 0C80 001D/007F/00B1/01B6/01D9; callers 1829@0147, 182D@00F7; R0C84/85 in 1834/1837/1865 | grep | PASS |
| open-items §3.2 / rules §3.4 | RepositionChar r19/r23 provenance and the 0x80 case | `ppcdis.py 10006530 100065e0`, `10006690 10006740` | PASS (N2) |
| script-builtins §3/§4 | D3 `…,0,uVar2)` / D4 `…,1,uVar2)`; PlaySound `param_5` loop on `FUN_100b7f40`; that body counts table entries by word 0/1; 3 D4 / 83 D3 calls | find_func; sed; grep | PASS |
| INDEX 16 wave-3 line | matches render.md order and open point | read | PASS |

## 3. NOT RESOLVED items

| item | verdict | basis |
|---|---|---|
| 5 kind 0x11 | **holds** (HIGH no reader / MED role) | `props_census.py` byte-identical; 8 compares all non-prop |
| 6 F005/F007 | **holds** | zero immediates, no data halfword, `ColorCycle` = `blr` with its one caller |
| 10 PORT | **holds**; one quoted byte string wrong (m3) | LZ decode reproduced |
| 14 indirect callers | **holds** (HIGH) | 8 direct `bl`; toc scan → control only |
| 16 wall clock | **holds** as "at most 10 fps"; exactly F in mode 3 (N3) | scheduler body |
| 16 layer order (wave 3) | **holds** (HIGH) | tables, dead pass, 12 sites, SetStage cells, no stage read; reader list fix m1 |
| 19 D4 | **holds** | wait loop + `FUN_100b7f40` body |
| 21 0x9C FFFF | **holds** | three windows + four sites |
| 22 crystal quality | **holds** — wave-1 inversion confirmed via `IsTrue`/0x54/0x8D (N1) | listings + VM |
| 23 signals | **holds**; count 26 (m2) | listings + native senders |
| 24 F008 byte 7 / bits | **holds** | tool B + readers |
| 25 eggs / activity | **holds** | tool C + RepositionChar |
| N2 served | **narrowed, holds** | 0C80 bytes |
| N3 native senders | **holds** (not re-walked; the four-wrapper and toc checks re-run via item 14's scan shape) | — |
