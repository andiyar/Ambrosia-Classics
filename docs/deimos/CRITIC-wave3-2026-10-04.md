# Deimos Rising RE bank: wave 3+4 completeness critic (2026-10-04)

Read-only critic of synthesis **f12f95d** (before = **6c085ca**). Inputs: all topical `docs/deimos/*.md`, `$W/sizes.txt`, `callers.txt`, the decompile, the images, plus a new Ghidra body dump. Scripts `$W/critic3-*.py`; outputs `$W/critic3-work/` (`bodies.txt` = function body ranges, `gaps.txt` = listing of all no-function code).

## 1. Census: 0 unread `FUN_` confirmed; code outside functions is not covered

My own column-aware parser (label column taken from each table header). Best label across files wins.

| scope | | HIGH | MED | LOW | none | H+M lines |
|---|---|---|---|---|---|---|
| gameplay 563 fns / 29 937 l | before | 312 | 171 | 27 | 53 | 88.8 % |
| | **after** | **427** | 136 | 0 | **0** | **100 %** |
| | after, worst | 315 | 214 | 34 | 0 | 95.6 % |
| game 979 fns / 44 851 l | before | 423 | 285 | 28 | 243 | 81.4 % |
| | **after** | **751** | 228 | 0 | **0** | **100 %** |
| | after, worst | 617 | 327 | 35 | 0 | 97.0 % |

- **Cross-checks.** The orchestrator's 4th-cell rule gives 746/233/0/0. An any-cell rule gives 4 LOW, all of them "(was LOW)" text (`FUN_100431f0` `10046840` `10047990` `10047a30`).
- **Families.** All 33 wave-2 families are at 0 unread lines. Sprite+Blit went 2 421 → 0, file/PICT 1 067 → 0, M_Display 765 → 0.
- **Worst-label drift.** 35 functions keep a LOW row in an older file: sprite-geometry (8 scaled leaves, `FUN_10019ee0`), player, spawn, damage, scoring/front, particles, messages and units role rows (`critic3-lowlist.py`). 134 functions are HIGH in one file and MED in another.
- **Borderline label-rule rows.** 40 HIGH §1 rows cite "listing" with no code address: 25 new + 15 corrected, ≈57 functions, not 23 (`critic3-border.py`).
  - 24 rows are static initialisers backed by the static-init §3 data bytes. These are fine.
  - 16 rows need an address range. gameplay-leftovers §5.1/§5.2 (`FUN_1003dd60…1003dfb0`, `1003f830/fa10`) has no address anywhere, so those rows are MED by the rule.
- **Table break.** The `FUN_10000000` row sits above the §1 table header (function-roles.md l. 65).
- **Blind spot: code outside functions.** 245 non-zero gaps (5 390 words) lie between Ghidra function bodies.
  - Most are switch cases of functions already read. The decompile includes them: `FUN_100075e0`, `1000e8d0` (90 glyph cases), `10010fc0`, `10015550`, `100229a0`, `10027930`, `10028170`, `10029b20`, `10029fe0`.
  - The two unrecovered jump tables (`FUN_100016c0`, `FUN_10048f30`) were read by listing.
  - About 49 blocks with a prologue have no Ghidra function. 21 of them have rows. These have **no row**:

| block (words) | what it is (critic listing) | replica |
|---|---|---|
| `0x10011750`, `0x100118e0` (200) | prefs-dialog slider action procs (TVs loaded in `FUN_10010fc0`, `10011190`/`100111dc`). Part 20 → −1 if > min; part 21 → +1 if < max; parts 22/23 → ∓10. Then SetControlValue and redraw `"%i%%"` in item 13 (sound) or 16 (music) | **visual** (prefs dialog) |
| `0x10049c20/30/40/50` (25) | AppleEvent handlers of `FUN_10049aa0` (TVs `10049ab4/b08/b5c/bb0`): two return noErr, one returns −1708. **`0x10049c50` calls `FUN_10022ed0` (set quit `b8`)** | flow (#48) |
| `0x10038840…0x10039030` (11 blocks, ≈540) | EntityGroup console handler bodies (registered `10032c54…10032d94`). `0x100354e0`/`0x10037700` are their counters | no (debugOnly) |
| `0x10041a40/b30/b70/d70` (250) | unit-def console handlers (named in the `FUN_1003cf10` row). `b70` calls `FUN_1003ef90`/`100395d0`/`1002b150` | no |
| `0x10001000` (13) | new_handler: fatal "Insufficient Memory" alert. The `FUN_1000ca90` row calls it "`FUN_10001000`", but no such function exists | no |
| `0x10030130` (24) | destructor of the level-select global | no |
| `0x10010350` (2) | getter `lwz r3,−0x61e4(r2)` (G_Background handler) | no |

## 2. Replica relevance

No `FUN_` is unread. The gameplay range has 133 MED rows with no address (5 559 lines). The ones a bit-exact replica relies on:

| row | why it matters | current evidence |
|---|---|---|
| `FUN_100352f0` `100353e0` `100351f0` | rule conditions #4/#5/#14–16 | dump |
| `FUN_10016230` | heading → frame rounding | — |
| `FUN_10014670` | power-up-release state switch | — |
| `FUN_1003bff0` | aux fire timing | — |
| `FUN_1002c960` | FLOAT reader | "strings" |
| `FUN_10012650` | object reset | — |
| `FUN_100385d0` / `10038810` | entity pool | — |
| `FUN_1002fcc0` `100298c0` `10011fd0` | — | — |

## 3. NOT-RESOLVED consolidation

**Stale file-level NRs to strike.** Each is closed elsewhere but still open in its own file; INDEX l. 445's "not re-marked" policy left them.

| file NR | settled by |
|---|---|
| bosses 4–8 | combat §5.1, §1.4, §6.6; spawn §6; session §5 |
| damage 2, 3, 4 | combat §4.3, §4.2, §3.2 |
| level 2, 3, 5, 6, 7, 9 | session §8.5, §8.6; combat §3.3, §6.5; session §8.9, §6 |
| combat 5 | `FUN_10015550` HIGH (cases `100156dc…` decompiled) |
| spawn 1, 2, 4, 6, 7 | combat §4.1, §1, §7, #38 |
| player 1, 2, 6, 8 | session §1; combat §6.1; session §4; sprite §4 |
| scoring 1, 2, 5, 7 | session §3.1, §2.2–3, §5; messages §5.5 |
| unit-def 3–6 | session §8.2–8.4; `10041b70` (above) |
| units 1, 4, 6 | combat §1.2, §7.4; timing §3 |
| weapons 1, 2, 5–8 | #30; combat §3.3; hud §6.1; combat §6.4, §1.3; session §8.7 |
| particles 6 / sound 3 | gameplay §4.1 + file-pict §8 / timing §6 |
| text 1, 3, 5 | display §1 (+0x68 = 640×480×16, `1000b320`); blit §1.2/§3; display §5.2 |
| static 3, 4 | display §7 (+0x4c = cursor visible); app-pak §6 (Registration) |
| sprite-mgr 2, 5 | app-pak §1; blit `FUN_1001a450` (`1001a56c..`) |
| sprite-mgr 6, blit 4 | critic scan: only four `stb …,0x1a(`; the player's comes from `FUN_10012650` `100126f0` |
| display 5, app-pak 4, file-pict 4 | file-pict §3–4, §1.2–1.3; display `FUN_1000b620`/`c2a0` |
| inline | data-tags l. 159/174/195; engine-loop l. 347/351; sprite-sound-containers l. 172; timing §5; hud §9 format table |

**INDEX #1–#61.**
- **Closed and confirmed:** 1–8, 11, 12, 15–30, 32–34, 36–38, 43, 46, 53, 55, 56.
- **Still open or closable:**

| # | status |
|---|---|
| 9 | closed; residue = blit NR 2 (indirect stores), MED |
| 10 | closed MED; **Ben's eyes** |
| 13 | int pref 2 is inert: all 13 `bl 0x10004f00` pass index 0/1/3 (MED). The rest of the block is open |
| 14 | a `0x14b8` D-form scan finds only the defaults writer and the copy routines `FUN_100047f0`/`10004c30`: no consumer in the PEF. Ruling |
| 31, 35 | inert, mod-only |
| 39 | MSL `bctrl` residue |
| 40 | lead: `FUN_10043340` calls the RGBColor→555 packer `FUN_10010bd0` (`1004370c`/`1004371c`) |
| 41 | no `lbz/stb …,0x131(` in game code → likely inert (MED) |
| 42, 44 | **ruling for Ben** |
| 45, 57 | **need a run** |
| 47, 54, 60 | code-answerable |
| **48** | **closable.** Quit `b8` (r2−0x6178) has 11 accesses. The writers are only `FUN_100229a0`, `10023b00`, `10023330` and `10022ed0`. `FUN_10022ed0` is called only from `10022ce8` (menu loop) and the AE handler `10049c50`, which only the menu pump `FUN_10048f30` dispatches. Play calls only `Button()`. So nothing sets quit during play, a Quit AE waits for the menu, and the pause loop's quit branch is dead. Also, `FUN_10048c90` (scores/credits/advert screens) drops what = 23 events |
| 49, 50 | **Ben's ear** |
| 51, 52, 61 | data checks |
| 58 | closable: `FUN_10012840` clamps exactly to the target (`10012840–100128b0`) and `FUN_1001a260` divides by 100.0, so a walk to 100 ends at exactly 1.0f |
| 59 | closed for text (C2); open for `FUN_1002f7a0`, `1000d7f0/db90/df00` |

## 4. Contradictions

| C | readings | ruling (checked) | sev |
|---|---|---|---|
| 1 (open ⚑) | static-init §5.1 #3: writers `FUN_1001aec0`/`1001eec0` ↔ blit §6, sprite-mgr §3.2: no-function handlers | **blit/sprite-mgr are right.** `FUN_1001aec0` ends at `1001af0b` (blr `1001af08`); `FUN_1001eec0` = `1001eec0–1001ef7b` + `1001ef80–1001f033`. The stores `1001afdc`/`1001f060` lie in the handlers `0x1001afc0`/`0x1001f040`. static-init used nearest-function attribution; its verdict "right" stands | LOW |
| 2 (new) | static-init §4.3 [HIGH]: "every builder keeps **no** template clip" ↔ text §2.2 | **text is right.** `FUN_1000e670` (`1000e72c bne`) keeps the clip when fmt+0x10d ≠ 0, and so does `FUN_1000d380`: `1000d504 lbz r0,0x1a1(r1)`, `1000d538 bne 0x1000d550` skips `bl 0x1000a530`. Messages, notices, the FPS counter and the tallies set +0x10d = 1. So **the 480/416 clip reaches the screen**: overlay glyphs and strips are clipped at buffer x < 416 | MED |
| 3 | scoring NR 2: `DAT_100e01b8` "likely a film/demo gate" ↔ front §0, session §2.3: quit requested | session | MED |
| 4 | text NR 1 / NR 3 open ↔ display §1 (640×480), blit §1.2 (mode 3 takes α) | newer readings | LOW |
| 5 | static NR 3 / NR 4 open ↔ display §7, app-pak §6 | newer readings | LOW |
| 6 | sprite-mgr NR 5 "not re-read" ↔ blit `FUN_1001a450` HIGH | blit | LOW |
| 7 | display §5.6 "background → sprites → limiter → present" ↔ timing §2.3: layers 0–1 → background → 2–5 → particles → 6–15; limiter only if pref 10 | timing | LOW |
| 8 | units NR 6 "divider writer unresolved" ↔ timing §3: there is none | timing | LOW |
| 9 | session §2.3: pause loop "exits with quit" ↔ #48: no writer runs during play | dead branch | LOW |

After the C1 sweep, no `+0x20/+0x24 = 0` or `0x100e8964` claim remains. Hit glow, fades, interlace and score-bar coordinates agree across files.

## 5. Beyond code reading

| kind | items |
|---|---|
| **Ben's eyes** | upright title (#10); invulnerability on level 2+ (player NR 9); damage NR 10 gates; hover strip (display NR 3); tearing (no VBL wait) |
| **Ben's ear** | pitch direction (#49); ampCmd (#50) |
| **Rulings** | TickCount 60.15 vs 60 Hz (#42); OS X volume (#44); OS X keys (#14); mods (#31, #35) |
| **Run of the original** | atan ulp (#45); QuickTime GIF→555 (#57); `tesm` widths (text NR 6); DSp fallback (display NR 4); alias launch (file-pict NR 1) |
| **Data checks** | preloaded vs played sounds (#51); pausing-controller order (#61); KCHR (#52); `im08` order (sprite-mgr NR 1) |

## 6. Recommendation

No reading wave is needed for coverage. One **listing-only micro-wave** (one reader, ≈900 lines) would make the bank replica-complete:
1. Rows for the slider procs and the AE handlers.
2. Listings for the §2 rows.
3. INDEX #40, #47, #54, #59 (the rest) and #60, plus a direct `+0x70` load scan for #13.

Fix pass:
- strike the §3 list;
- apply C1–C9;
- close #48, #58 and the text half of #59;
- reconcile the 35 LOW and 40 borderline rows;
- move the `FUN_10000000` row below the header.

The debug console handler bodies can stay unread by ruling.
