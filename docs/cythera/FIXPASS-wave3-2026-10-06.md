# Cythera 1.0.4 RE wave 3 — fix pass (2026-10-06)

⚑ corrected (review wave 3 2026-10-06) — fixer's record for `REVIEW-wave3-2026-10-06.md` (commit 4bd5940).
Every finding's command was re-run from the worktree root before editing (`$S` = session scratchpad;
`$S/all.dis` = `python3 docs/cythera/tools/ppcdis.py 10000000 100cd280`, 212,074 lines). Every edit is
marked `⚑ corrected (review wave 3 2026-10-06)` at its place; superseded claims are struck or
superseded in place, not deleted. The REVIEW file and INDEX.md's NOT RESOLVED list / review ledger were
not touched. Result: **12 applied (M1, m1–m11), 0 declined; N3 applied as a sharpening; N1, N2, N4–N8
confirmations, no edit.** Three re-runs refined the reviewer's text (m3, m6, m7 — marked ◆).

## Major
- **M1** applied — data-format.md §3.2 bit-13 row, §4.2 byte-4 bit-7 row, §4.3 kind 0x04/0x24 row.
  Re-ran `grep -E '^(1004f484|1004f48c|1004f8c4|1004f8d8|10067e80|100675f8|10065b74|10065b94):' $S/all.dis`
  (all eight instructions as quoted), `tb.py --at 1004f484` / `1004f8c4` → `HatchEgg @ 1004f420`,
  `toc.data_u32(0x100d5fa4,24)` (word 8 = `0x44ff9e`), `sed -n '33499p;31634p'` (`'D'`, `local_5e != 7`).
  0x2000 and kind rows struck + superseded (conf → HIGH, render.md §2.3 / §2.4, §5); mirror row
  extended (render.md §2.5).

## Minor
- **m1** applied — render.md §5 priority-7 bullet. `awk '/^\/\/ ==== /{fn=$0} /0x15ff4/{print fn}'` over
  the three dumps → BuildStageEntry ×2, ClearMonstStage, GetBestPropRel, GetBestProp, HatchEgg,
  InteractProps, SetMonstStage, SetStage, SwitchParty (extra/missing: none); `find_func.py
  'GetBestPropRel__7TViewerFss' --file …pef…` body: quarter cell tested before `+0x141f2`.
- **m2** applied — open-items-2026-10-06.md §8 "Senders" line: 26. `grep -c` summed = 26;
  `grep -o 'send_signal(' … | wc -l` = 26 (19 files).
- **m3** applied ◆ — open-items-2026-10-06.md §6 PORT 1 bullet. `rsrc.parse` + `lz.unlz`: raw head
  `c3 b2 80 01 3e 75 30 28 22 24`, decoded head `b2 80 01 3e 75 30 28 22 24 20 00 13`, 4096 B,
  consumed 2351, 204 values; PORT 0 {0: 3830, 255: 266}. **Disagreement:** the review says the quoted
  `00 0b 5d e8 01 3e 75 40` appears in neither stream; it does occur once in the decoded stream, at
  offset 0xE (`o.find(q)` = 0xe). So the fix text says "not the head" rather than "absent".
- **m4** applied — the six tools: stdlib `argparse` in a `cli()` wrapper (`main` unchanged for in-process
  use); `--help` exits 0 for all six; a missing `all.dis` / `--data` path → one line
  `<tool>: error: no such file: …`, exit 1; `tileflag_census.py zz` → "not a hex mask", `--eq` with no
  MASK → error (exit 2); `props_census.py junk` → "unrecognized arguments". `--data PATH` added to the
  three seg.py tools; `listing.py` run as a script prints the line count (212075). Before/after
  captured to `$S/before`, `$S/after` with the documented arguments (props_census; f008_dump;
  scan_clr80 and scan_byte7 with `all.dis` and in-process; tileflag_census with the four masks, no
  args, `--eq 0xc0 0x80 0x40`, `--eq 0xc0`, `--eq 0x100010`, `--eq 0x210`; listing as library with and
  without a path): **13/13 `cmp` byte-identical**. `ls -la | grep -- --help` → nothing; `pef.py` not run.
- **m5** applied — render.md §1 step 5: `grep -n` → p:31295 (p:31292 = `iVar3 = (*param_1 + 1) * 0x20;`).
- **m6** applied ◆ — render.md §2.1 heading. `grep -oE '[-0-9]+\(r31\)'` over `ppcdis.py 10066ac0
  10068cfc` → {0, 2, 4, 12, 13, 16, 120, 176, 180, 185}; r3 reads `10066adc` (186), `10066ae8` (4),
  `10066b08` (184). **Refinement:** these come *after* `10066acc: mr r31,r3` (r3 still holds the
  viewer), not before it; wording says so.
- **m7** applied ◆ — open-items-2026-10-06.md §7: hintbook sentence paraphrased, line 1611 kept
  (`pdftotext -layout Cythera_Hintbook.pdf` line 1611 re-read). The quote was replaced, not struck —
  a struck quote would still be a verbatim quote; the `end_game` line stays as the section's one.
  "distil an element" checked: a paraphrase (script text is "Distill what element?"), not a quote.
- **m8** applied — notes-w3-render.md: `wc -w` 205 → **200** (status line and tools line shortened, marker added).
- **m9** applied — INDEX.md provenance "tools" row: the six wave-3 tools appended (marked).
- **m10** applied — ui-play.md §2.6: behaviour phrase struck, code phrasing added. `find_func.py
  'CloseAtDistance' --file ghidra/Cythera_missing.decompiled.c`: `SizeWindow(…,0xdc,0x42,0)` when not
  adjacent, `0x110` when adjacent.
- **m11** applied — render.md §5 0xC0 bullet: `ppcdis.py 10065ba0 10065c10`, `10065dc0 10065df0`,
  `10065f98 10065fc0`: 128 → `addi r0,r4,-1` … `stwu r0,-8(r19)` (left); 64 → `addi r4,r5,-1` …
  `stwu r3,-248(r19)` (up); 192 → `10065f98` chain.

## Notes
- **N3** applied (sharpening) — engine-classes.md §3.4: m:5740 mode-3 spin to the deadline, m:5753/5756
  re-arm, m:5762 mode := 2 (`sed -n '5700,5790p' ghidra/Cythera_missing.decompiled.c`): a sub-step's
  frame starts at the deadline; exact F spacing while sub-steps arrive early [HIGH code / MED].
- **N1, N2, N4, N5, N6, N7, N8** — confirmations; no text change asked.

## Follow-ups (outside the review's findings — not edited)
- `tools/README.md` rows for the six tools do not mention `--help` / `--data`; `listing.py` row still says
  "library only" (it now also has a CLI).
- ui-play.md §2.6: `TCharacterWindow::CloseAtDistance` resizes only when character-table byte
  `PTR_DAT_100cdbf0[idx·0x20 + 8] & 0x40` is clear — not mentioned in the bank.
- notes-w3-render.md "Follow-ups" line (data-format §3.2/§4.2/§4.3) is now discharged by M1.

## Line counts after the pass
data-format 564 · engine-classes 267 · INDEX 208 · notes-w3-render 21 (200 words) ·
open-items-2026-10-06 424 · render 322 · ui-play 525.
