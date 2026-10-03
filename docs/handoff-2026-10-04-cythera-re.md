# Handoff — 2026-10-04 — Cythera RE deepening, wave 1 CLOSED (+ 100 % decompile)

Orchestrator: Claude Fable 5.1. Branch `claude/optimistic-rosalind-dd2c63` carried the unmerged wave-1 head d5339a6
(from `claude/dazzling-ramanujan-8d8f23`, which was checked out in a sibling worktree), merged `origin/main`, and was merged
back to `main` at the end of this session. Ben lifted the 250k cap ("ignore cap"); mid-session he added: *"i want this
decompiled to 100%"*.

## Landed on main this session
- **Fix pass 6f216e8** (four Opus fixers, disjoint file groups): every finding of `docs/cythera/notes-critic.md`
  (1 Blocker / 7 Major / 23 Minor) and `notes-tools.md` applied and marked `⚑ corrected (wave 1 2026-10-03)`; INDEX synthesis
  (eight Files rows, provenance rows for the extra dump + traceback table, NOT RESOLVED 1–25 annotated, review ledger);
  `rules.md` cross-refs; `data-format.md` §5/§6.1 rows; `script-vm.md` §2.1 0x28/0x48; `script-builtins.md` §4;
  `REPORT-implementer.md → notes-implementer.md`. Record: `docs/cythera/FIXPASS-wave1-2026-10-04.md`.
- **Fable-grade review** `docs/cythera/REVIEW-wave1-2026-10-04.md`: **ACCEPT_WITH_FIXES**, 1 Critical / 2 Major / 6 Minor /
  7 Notes; 142 HIGH claims re-derived with banked tools, 139 pass; independent `scriptdis.py` re-run byte-identical.
  Critical: dialogue §3.3 `TConvResponseMode` vtable slot numbers (+0x10 Mouse, +0x1C Key). Majors: critic m12 never applied
  (0x1AF6 is the "Wait" command, not a spell); INDEX 14 still called the `CompileAIFile` caller open
  (`TEditUserBehavior::DialogItemRoutine`, one `bl` in the whole code section). All fixed in the post-review pass (Opus),
  plus `ghidra/find_func.py` header regex now accepts the builtins dump's `(name)` suffix.
- **100 % decompile of traceback-named functions.** `docs/cythera/tools/missing-addrs.txt` (840 rows, regenerate command in
  its header) → `CyDecompAt.java` → `ghidra/Cythera_missing.decompiled.c` (log `CyDecompAt: wrote 840/840`, 23,585 lines).
  `tb.py --missing` over the three dumps concatenated = **0**. The 15 inter-body gaps > 0x100 B in the code section are
  traceback tables with long std-template names (e.g. 0x10057A6C: name length u16 0x0458 = 1,112 bytes), not code. Dumps are git-ignored; regenerate per `docs/cythera/INDEX.md`
  provenance (main: `GHIDRA_PROJ=/tmp/ghidra-proj-cythera ghidra/decompile.sh Cythera_pef -processor PowerPC:BE:32:default
  -cspec macosx`; extra/missing/builtins: copy the project, run the postScript `-noanalysis -readOnly`).

## Still open (INDEX NOT RESOLVED, carried)
- 5 prop kind 0x11 · 6 globals 0xF005/0xF007 contents · 10 PORT resource content · 16 `Render__7TViewer` layer order and the
  per-frame wait · 14 indirect (TVector) `CompileAIFile` callers · 19 builtin D4 flag · 21 0x9C FFFF stack effect ·
  22 damned-ending crystal-quality source (hintbook: not in the installed folder — a copy is at
  `~/Developer/Ambrosia/Resources/ambrosiaarchive-mac/RPG/Cythera/Cythera_Hintbook.pdf`, unread; ARCHIVE-INDEX says
  "installed folder", which is wrong) · 23 signal receivers 1/34/35/100+/129–135 · 24 F008 byte 7 · 25 egg re-arming.
- Review notes worth a later lift: library §0/§9 native-sender scan (MED → reproducible now, N3); quests §2.3 "served"
  reading (MED, N2).
- The 840 newly decompiled bodies have NOT been read into any bank yet — wave 2 material (what the banks cite as
  "not in the dump" is now all present).

## Hazards learned
- A branch checked out in a sibling worktree cannot be checked out again: carry its head onto the session's own branch
  (`git reset --hard <sha>` on an empty worktree branch) and merge back; delete the stale branch after.
- `ghidra/find_func.py` defaults `--file` to Aki's dump; always pass `--file` for Cythera dumps.
- `ppcdis.py` reads only the code section; data-section words (vtables at 0x100D5xxx) go through `toc.py`.
- zsh: a bare `=====` token in a shell line is a glob; quote it.
