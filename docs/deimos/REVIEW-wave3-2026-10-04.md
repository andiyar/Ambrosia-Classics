# Deimos Rising RE bank — Fable review, wave 3+4 (eight files at 2ff0756), 2026-10-04

Evidence: own Ghidra copy `$W/work-review3`, own full raw listing `$W/disasm-review3-all.txt`
(DisasmRange `10000000:1004b400`), scratch `$W/review3-*` (`-lst.py` range printer, `-rd.py`
image reader, `-stbscan.py` r2-relative access scan, `-emu.py` my own interpreter for the 29
initialisers, `-census.py` per-file role-row census, `-tesm.py` plate rescan). `entry @ 1004d540`
lies outside my listing; checked from `$W/disasm-w3s2.txt`. Repo untouched.

## Verdicts
| file | verdict |
|---|---|
| blit-pixel-rules.md | **ACCEPT** |
| static-init-audit.md | **ACCEPT_WITH_FIXES** (cosmetic attribution, M1) |
| text-metrics-lists.md | **ACCEPT_WITH_FIXES** (I1, M3) |
| display-window-present.md | **ACCEPT_WITH_FIXES** (M2) |
| app-pak-music-library.md | **ACCEPT** |
| sprite-manager-resource-image.md | **ACCEPT_WITH_FIXES** (M4–M6) |
| file-pict-alerts-manager.md | **ACCEPT** |
| gameplay-leftovers.md | **ACCEPT** |
Overall **ACCEPT_WITH_FIXES**. No HIGH claim carrying a number, offset, inequality or RNG order
was found wrong; every priority claim in the trigger reproduced from my own listing or data.

## Findings
### Critical — none.

### Important
**I1. text-metrics-lists.md: merge rows missing.** `FUN_1000d380` (157 lines), `FUN_1000e270`
(163), `FUN_1000e8d0` (196), `FUN_1000ef90` (211) are read by listing (§1.1, §2.1, §2.3, §4) but
have no row in "Role-table rows". The existing rows for `e8d0` and `ef90` are HIGH with evidence
"read" only — a label-audit hit now that listings exist. Confidence High. Fix: add four rows citing
`1000e8d4..1000e8e8` + table `0x100e542c`; `1000f01c` + store census; `1000d3c4..1000d474`;
`1000e328..1000e398`. (The brief's range to `0x1000fbc0` also holds `FUN_1000f990/f9c0/fbc0/fed0/
ffe0/fff0`, still MED "read" in function-roles; the file's "not re-read" is allowed, but they are
the last non-HIGH there.)

### Minor
**M1. static-init-audit.md table B row 3** names `FUN_1001aec0`, `FUN_1001eec0` as post-main
writers of the switches. Neither stores there: my scan finds only `1001afdc stb r0,-0x61bf(r2)` and
`1001f060 stb r3,-0x61af(r2)`, inside the orphan handlers `0x1001afc0`/`0x1001f040` (Ghidra made no
function; the reader's tool fell back to the preceding function). Verdict unchanged; conflicts with
blit §6 / sprite §3.2, which are right. High. Fix the two names.

**M2. display-window-present.md §6.2** says `FUN_10045f70` "walks the GDevice list and validates
the pixmaps". Listing `10045f80 lwz r28,0xd66(0)` … `10046188..10046194`: it walks the low-memory
PortList and validates every GrafPort (file-pict §4 is right). High. Fix the clause.

**M3. text-metrics-lists.md NR 1 / NR 5 are already closed** by display-window-present.md: `D+0x68`
= 640×480×16 work buffer (`1000b320`); `FUN_1000c3b0` adds `+0x10` to left/right, `+0xc` to
top/bottom (`1000c3b0..1000c3e4`); `FUN_1000bbd0` = one CopyBits srcCopy. High. Fix: strike both;
§2.4 "[MED for the target buffer]" → HIGH.

**M4. sprite-manager NR 2** (M_File modes) is closed by app §1.2 (`0x11` "rb", `0x0f` "a+t", `0x17`
"a+b"; `10001238..1000131c`). High. Fix: strike; §4.4 "[MED for the mode semantics]" → HIGH.

**M5. sprite-manager §5 "Usage levels by caller (from the dump) [HIGH for the arguments]"** — a
HIGH on the decompile alone. Med. Fix: MED, or cite the `li r5,N` at the eleven call sites.

**M6. Label mismatch on one fact:** sprite §1.1 "2000 draw commands [MED]" vs blit §6 HIGH
(`100187f8 lis r31,0x2; 10018824 addi r3,r31,0x51c0`; 0x251c0/0x4c = 2000). Low. Fix: HIGH in both.

**M7. app §3.2** "HFS catalog order, i.e. alphabetical" sits under a HIGH heading but is OS
behaviour (file-pict labels the same point MED). Low. Fix: MED.

## Sample table (HIGH claims re-derived from my listing / data bytes)
| file | checked | confirmed | wrong | unverifiable |
|---|---|---|---|---|
| blit-pixel-rules | 24 | 24 | 0 | 0 |
| static-init-audit | 20 | 20 | 0 (M1 is a name) | 0 |
| text-metrics-lists | 16 | 16 | 0 | 0 |
| display-window-present | 18 | 18 | 0 | 0 |
| app-pak-music-library | 14 | 14 | 0 | 0 |
| sprite-manager-resource-image | 13 | 13 | 0 | 0 |
| file-pict-alerts-manager | 10 | 10 | 0 | 0 |
| gameplay-leftovers | 20 | 20 | 0 | 0 |

Re-derived (my listing addresses):
- **Blit.** Kernel `1001da88..1001dab8` (10-bit fields, `>>5`, no rounding → floor). Mode 1
  `1001dc18 add r28,r8,r11; cmplwi 0x20; bge`, mode 3 `1001dfc8`. Mode 2 partial: `*(r2−0x7164)` =
  `0x100d6db4` = `3d03126f` (0.032f), `fmuls`, `fmadds f1,f2,f1,f0`, `bl 1004d5c0`, `cmplwi 0x20;
  bge`; a = 20 table recomputed (p 5→20, 19→31, 20 skip). Scaled `1001b7d0`: clamps `0x1a0`/`0x1e0`,
  table `subf/mullw r8/divw r12/×2`, row `mullw r9/divw r31`; scaled mode-1 clamp `1001bc7c..88`;
  clipped scaled `1001cb40` column-major, no clamp. Twin `1001e0d0`: marker `1001e1d8` before
  predicate `1001e1f0..1001e20c`, kernel identical. Dispatcher priority `100197d4..fc`, inside/reject
  `10019754..a8`, scale test `100195dc..10019600`, rect compare vs `0x100d6d0c`. Switch scan: stores
  only `1001afdc`, `1001a290` (sole caller `1001f064`), `1001f060`; TVectors `0x100e0908/0918` only
  via slots `0x100df18c/1d0` loaded at `10018890`/`1001d6b0` with `li r7,0x1`; `1002d0ac bne
  1002d174` exits when r7 ≠ 0; no image word points into `0x100e0168..0x100e0188`. Worked example
  (0x4cc6, 0x3125) reproduced by hand.
- **Static-init.** 32 `bl` in order. My interpreter over the 29 game initialisers reproduces
  table A exactly: 26 D get +0x28/+0x2c = 0x1e0/0x1a0; 7 R get +0x24 = −1 (`0x100e2540 3cc8 5a68 64d4
  91f8 b440 cd38`); 9 P get the sound record; all other stores = image; three change nothing.
  r2-relative scan over the 42 objects: 82 hits, all `addi`. One `bl` per callee; only
  `0x10000000` appears as a pointer word (exception table). `FUN_10032b20`/`FUN_100228d0` bases
  re-read → conflicts #5/#14 right. Entity-draw clip copy `10013098..b4` confirmed.
- **Text.** Table base `r2−0xf04` = **`0x100e542c`** (not `…30`; my first pass with the wrong base
  gave a shifted table): '1'…'9','0' → 52…61, space/≥0x80 → 90. `FUN_1000ec70` fills
  `*(0x100df024)` for c 0..127, sole writer. Digit cache `1000d3f4 li r4,0x31`, frames 52+i, label
  `'0'+i` on strict increase (`1000d434 ble`) → `'2'` → frame 53 = 6 px (plate rescan 5,6,7,7,7,7,6,
  7,7,7; frame 90 4×13). `+0x10c → cmd+0x30` (`1000e798`), `+0x110 → cmd+0x31` (`1000e790`),
  `+0x10d` → `FUN_1000a530(D+0x68)` vs template (`1000e72c`); `100195ac..b8` queues when +0x31 = 0.
  `FUN_1000f720` clip {0,0,480,416}. Fades `li r25,0x20`, decrement then pass, `bne` at 0 (32
  passes), out 1→32; rate `li r3,0xa0` → `Interface_FadeRate <1.0>`. Strip `1000d530`. Example A
  positions recomputed.
- **Display.** `FUN_1000c470` r7 unsaved, first use `1000c520 or r7`; attrs +4/+8 = w/h, +0x14 = 2,
  +0x1c = 0, +0x20..2c = 16, +0x30 = 1. `FUN_1000ae20 or r28,r7,r7` → 0 unless both dims exceed
  F52/F53. `FUN_1000beb0`: `1000bf64 sth r0,0x3c(r1)` never rewritten (bug); borders `li r3,0x3b`
  twice, no F60; bar from `+0x68` (`1000c234`); 2 CopyBits. `FUN_1000ac20` one CopyBits `li r7,0;
  li r8,0`, arg r7 first written `1000ac58`. `FUN_10009fd0` CopyBits ×2; all 59 call sites `li r7,0`
  except `100101e4`/`1000a434`. Hover `10022c1c..64`. `+0x4d` stores: `1000ad28` and the message
  record only. `FUN_10045010` flag 4 iff `MaxBlock < need+0x40000`.
- **App/pak.** Table `0x100e2db4` = `10001794..1000183c`, next word "Last"; dispatch
  `1000177c..10001790`; loop end `10001b20..2c` before ` Data:Paks`. `0x100e00ec` = 0x64, sole
  access `10001ee4`. Anti-tamper: `0x100d60b0`, `~rotl8(b,4)` → "A device configuration error
  (-65)…" over `0x100e27f4`; callers `10006664`, `10028efc`. Log strings confirmed. Zip reader `bl`
  census = the file's 23 targets. `-0x6d8c(r2)` accessed once. `FUN_10048810 100489ac..b8`.
- **Sprite manager.** Date `1001b0b0 cmpwi r3,0; bne` only; header `cmplwi r0,0x10`; writer
  passes `1001b3d8..1001b548`; encoder size `1001d7a8..bc`; `FUN_10020f00` after Draw:
  log/DisposeHandle/CloseComponent only; TGA descriptors 0x01.
- **File/alerts.** `FUN_10045ab0`: one `bl 100d498c`, single `blr 10045c54`; `\n` loop CTR =
  len−1; message length unclamped. `1000cfd4..dc` fatal → `10000630`. `FUN_10045f70` PortList,
  `li r3,0x1` at `10046198`. Record `li r3,0x88`; reserve `lis 0x2; subi 0x7000`.
- **Gameplay.** Launchers `1003c874/78 lhz 0x28/0x2a(r31)` → req +0x28 (`sth 0x68/0x6a`; req at
  0x40), `1003ca54/58`; `0x100ecd3c` = `3f800000`; the six `addi …,r2,0x69e4` bases carry no stores;
  initialiser writes `cd18..1f`, `cd34..3b` only. `FUN_100146f0`: exactly three `bl 10046580`;
  `10014b04..10` = (tol+sign)>>1, negated; `add.; bge; li r17,0`. unde: 17/386 tolerance ≠ 0.
  Ground-accuracy census re-run: 36 units, no non-player path. Loop head `10033a2c..78` has no
  `+0xcb` read (first `10034068`). `FUN_1000fee0` 0/1, `divw.`+`blt`. Crosshair `cror eq,gt`/`bge`
  = half-open. `100342c0 lfs f1,0x274(r31)`, sole `bl 10027100`. Ramp constants `0x100d67c4`/
  `0x100d67a8` = 0.0. Glow `cmplwi 0x4/0x20`. `FUN_10016300`: one draw, F209/F218, objects 30/25.

## Replay-order check
Only `FUN_100146f0` (gameplay §7.2) and `FUN_10016300` (§1.1) draw in scope; documented orders
(timer → frame → scale; one draw before the F209 compare) match the listing including the gates
that skip the frame and scale draws.

## Cross-file consistency
Checked and consistent: entity `+0x1a` writer (blit §7.2 = sprite §7); render-list reset callers
(`10006824 10030250 100302f4 10030388`); pixel-buffer layout (display §1 = gameplay §1.3);
`FUN_10001200` modes (app = sprite §4.4); `FUN_10048810` quirk (app = file-pict); request +0x24 = −1
(static-init = gameplay §7.1). Conflicts: M1, M2 only.

## Hazards
No offset taken from a copy loop; float-compare senses checked in text §3.1 and gameplay §2.1/§7.4b;
both recovered jump tables verified word by word. New hazard: `subi r3,r2,0xf04` puts the text
jump table at `0x100e542c`, not `0x100e5430`.

## Unmentioned heavy functions (≥ 60 lines, no row)
None in any declared scope. The four text functions of I1 have function-roles rows but no merge row.

## Open questions
1. MBarHeight at runtime; DSp fallback when 640×480×16 is unavailable (display §7, NR 4).
2. Default directory vs `processAppSpec.parID` (file-pict NR 1).
3. QuickTime TGA bit-5 handling (sprite §6 / INDEX #10) — Ben's eyes on the title screen.
4. RGB8 → RGB555 plate conversion (blit NR 1) — decides every map value p.
5. Player `+0x1a` writer (blit NR 4); `FUN_10029bf0`'s 16 console sites (not re-derived here);
   G_Background MED residue `FUN_1000f990/f9c0/fbc0/fed0/ffe0/fff0`.
