# Cythera 1.0.4 RE wave 2 — fix pass (2026-10-06)

⚑ corrected (review wave 2 2026-10-06) — fixer's record for `REVIEW-wave2-2026-10-06.md` (commit 015f1e1).
Every finding's evidence was re-run with the banked tool it names before editing; every edit is marked
`⚑ corrected (review wave 2 2026-10-06)` at its place, beside the text it corrects (nothing deleted).
INDEX.md and the REVIEW file were not touched. Result: **25 applied, 0 declined** (m8 applied as a register
note; the orchestrator may rule differently).

## Major
- **M1** applied — rules.md §3.4 last bullet. Re-ran `ppcdis.py 10006540 100065c0` + `10006690 10006730`:
  old visible → `100066a4: stb r25,22(r31)`; old-not-visible / new-visible / monster → `10006724: li r0,128`.
  Points at open-items-2026-10-06.md §3.2 and schedules-npcs.md §10 item 4.
- **M2** applied — quests-flags.md §10 item 2. Re-grepped 1025 (0445/044F/0458) and 1802 (02F8/050A/06E3):
  quality 0 → var 2 → damned; ≠ 0 → var 1 → saved. Points at §5 and open-items-2026-10-06.md §7.
- **M3** applied — the chain is now cited, so HIGH kept: engine-classes.md §3.4 (four steps, each
  `Name @ addr` + quoted line + line number: x:759–762 → p:7783 / m:5876 → p:12559/12566 → p:12026,
  p:12137–12138, p:12167); new fact: space = `HeartBeat(game, 10)`, repeated while space is held.
  app-shell.md §2.3 dangling pointer replaced by a marked pointer to engine-classes §3.4.

## Minor
- **m1** applied — open-items-2026-10-06.md §5: `100432c4: bl 0x10008694` in `AnimThread__10TMapWindowFPv`
  (re-run on a fresh whole-code listing + `tb.py --at`); conclusion (bare `blr`) stands.
- **m2** applied — script-builtins.md D4 row + §3: param_5 = 4th argument after `this` (signature re-read).
- **m3** applied — data-format.md §8.2 row: PostInitMac m:4384 also reads bits 2–5 (dead 0x88 block).
- **m4** applied — engine-classes.md §3.4: "at most 10 frames/s" (m:5753/5756 re-read).
- **m5** applied — app-shell.md §4.1 and §8: MENU 135 inserted with −1 (`CreateMenu__12TCommandMenuFss`
  p:3641 → `InsertMenu(iVar1,param_2)`); only `bl 0x100b1b38` = 1002f390 in `TCharacterWindow::MouseRoutine`.
- **m6** applied — app-shell.md §5.1: `ppcdis.py 100171c0 10017214`: 1 + one per non-NULL frame slot, ≤ 7.
- **m7** applied — open-items-2026-10-06.md evidence base: four inline recipes (prop census, F008/F005/F007,
  0x80-clear scan, byte-7 heuristic) run verbatim from the doc this session; A–C reproduce exactly; D gives
  N = 7 → 0 with control 41 (doc said 38: window handling differs; conclusion unchanged). app-shell.md §0:
  classifier body named (census §0 python, per-row print; re-run → 125 / 30,876) and the slot helper
  named (dialogue.md §0 one-liner; control `vt 0x100d4358 +0x44` → 0x10012c24 `MyGetEvent`). The tools
  were inlined, not banked under `tools/` (outside this pass's write set).
- **m8** applied as a register note — app-shell.md header (the §1.1/§1.3/§4.2/§5.x quotes are engine
  identifiers, not prose) and scripted-windows.md §4.1 (button titles are the byte evidence). open-items §7
  checked: one game-text line + one documentation line — within the rule as worded; left as is.
  **Orchestrator:** rule whether UI/engine labels count as game text.
- **m9** applied — dialogue-ui.md §0 (71 rows / 15,788 B) and scripted-windows.md §0 (128 / 18,292),
  full class :: method @ addr len lists, re-derived with the census classifier this session.
- **m10** applied — missing-census.md §1 C row: frames, not turns.
- **m11** applied — open-items-2026-10-06.md §8 row 132–134: sends come from the @01FB/@0209/@0217
  handlers (1175 listing re-grepped), via `TWPixButton::MouseRoutine`.
- **m12** applied — dialogue-ui.md §9: reachability lowered to MED.
- **m13** applied — app-shell.md §4.3: any item ≠ 1 (m:4970/4976); MENU 200 item 2 = `-` (rsrc.parse).

## Notes
- **N1(a)** applied — dialogue-ui.md §8: 0x110/0x113 = Home/End (`TApp::TranslateKey` p:3153–3166).
- **N1(b)** applied — scripted-windows.md §10: 0x3E90 = WDEF 1001 var 0 = `TPixsWDEF`; a1 pix id, a2 x, a3 y.
- **N1(c)** applied (MED) — ui-play.md §10 item 3 + the GetGesture paragraph: TaskThread m:5869 coalesce
  mark reaches the gesture call via `TDroppableWindow::MouseRoutine`'s vtable call (slot not resolved).
- **N1(d)** applied — dialogue-ui.md §8: 0x3E91 = CDEF 1001 var 1 = `TProgBarCDEF`, refCon on the knob.
- **N2** applied (MED) — script-builtins.md §3: D4 stalls the whole program (no yield; helper calls nothing).
- **N3** applied — data-format.md §4.3 kind-0x11 row and §5 F005/F007 row (labels kept, correction
  appended); open-items-2026-10-03.md §10 PORT table row, §10 PORT line, open list items 1–4; combat.md
  §16 item 4 → open-items-2026-10-06.md §2.2–§2.3; open-items-2026-10-06.md §10 marked as applied.
  INDEX NOT RESOLVED list left to the orchestrator.
- **N4** applied — scripted-windows.md §7: 100+frame is script-only too.
- **N5** applied as an open note — data-format.md §8.1: code default 8 (p:6948) vs music 0..3, unreconciled.
- **N6** applied — ui-toolkit.md §3.2: filter stored by `InitInterface` (p:36817), read by `MyAlert`,
  `DefineFKey`, `MakeNote`; DLOG 133 `;;Mm;Fm` mismatch, DLOG 141 title empty. LOW for DLOG coverage.
- **N7** applied — app-shell.md §2.3: `TDelverApp::TranslateKey` calls `TApp::TranslateKey` first; F1–F4
  and ⌘1–⌘4 share 0x100–0x103; the map window sends 0x100–0x109 to `PerformMacro` (x:746).
- **N8** applied — open-items-2026-10-06.md §1: statement vs 0x9C-opcode offsets, same four sites.
- **N9** applied — app-shell.md §3.3: `next == 0` re-tested every call (m:5709).

## For the orchestrator (INDEX.md)
- NOT RESOLVED list: 5, 6, 10, 14, 19, 21, 22, 23, 24, 25 closed per the review's §3; 16 = wall-clock half
  closed (wording "at most 10 fps"), layer order still open.
- Optional INDEX rows: engine-classes §3.4 "space = HeartBeat(10)"; open-items-2026-10-06 evidence base
  now carries inline recipes; dialogue-ui / scripted-windows §0 carry full address lists.

## Line counts after the pass
app-shell 535 · combat 620 · data-format 564 · dialogue-ui 400 · engine-classes 253 · missing-census 252 ·
open-items-2026-10-03 537 · open-items-2026-10-06 441 · quests-flags 465 · rules 155 · script-builtins 274 ·
scripted-windows 438 · ui-play 524 · ui-toolkit 211. dialogue.md untouched (659).
