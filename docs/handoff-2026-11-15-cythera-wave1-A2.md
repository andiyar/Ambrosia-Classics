# Handoff — Cythera wave 1, session A2 (C9) → session B (C6, C7, C10) — 2026-11-15

Seat: Opus 5.5 (Ben's choice for this test). Started by the Desk (the session that starts orchestrators and relays
Ben's answers); the Desk decides when session B runs.

- **Landed:** C9, the script segment model, reachability and canonical parity — commits ea8275f, 6cc6e98, fa7ccd6,
  a91f991 (review fix round), 1e6eb5c (Fable fix round), pushed to origin as fast-forwards; merged into local main. Suite 50 → **57**,
  0 failed or skipped; all 958 script segments' canonical hashes equal the committed golden. Numbers, both legs and
  every deviation: the C9 card's "As executed — session A2".
- **Review caught:** test checks that only compared constants or counted a stand-in (fixed), no mutation sweep over a
  class segment and no test of the walk's three anomaly branches (added), comments that said "byte order" where the
  order is the tool's (fixed). Parity proves lengths, mnemonics and flags, not operands (carried).
- **Fable cross-check over C8 + C9 (Ben: "One after C9"):** PASS WITH FIXES, nothing blocking session B; its code fixes landed in 1e6eb5c (anomalies recorded and pinned at 0, empty-block guard, docs, corpus totals; suite still 57, parity equal); its plan-level points are carried into the Wave 5, C11, C12 and C13 cards.
- **Main at hand-over:** local main is ahead of origin by the three Deimos plan commits (b27067b, 611347d, 5c1e98a) and
  the two local merge commits of A1/A2; this session pushed only Cythera's own commits.

*Everything above this line is history. The brief below was rebuilt from nothing and is the only part a new session
reads.*

## The brief for the next session (wave 1, session B — C6, C7 ⚑, C10)

> You are the ORCHESTRATOR for **Cythera wave 1, session B: tasks C6, C7 ⚑ and C10**, in
> `"/Users/andiyar/Developer/Ambrosia-Classics"`. Seat: Opus 5.5 unless the session that starts you says otherwise.
> Method: `~/Developer/Toolkits/fable-kit/orchestrator.md`. Ben's rules: `~/.claude/CLAUDE.md` (plain English, numbers
> in tables).
>
> **Authority:** `docs/superpowers/plans/2026-11-05-cythera-remainder.md` is the one plan. Read its headings
> "0. The verification model", "0b. Done before this plan, the binding invariants, the locked surface", the
> "Wave 1 — Phase 0b" introduction, "### Session B" with its three cards "#### Task C6", "#### Task C7", "#### Task C10"
> whole, and the research each card cites. Nothing else in that file is this session's (C8 and C9 are done; read their
> As-executed notes only if a card points there).
>
> **Read first, in order:** the repo's `CLAUDE.md`; `docs/STATE.md` (do not rely on any copy of it); this brief; the
> plan headings above.
>
> **What is already on main for you:** `Cythera/Core` at **57** tests (34 + 10 from Phase 0, 6 from C8, 7 from C9);
> the data in `Resources/Cythera/` (20 files, read-only); `SegmentFile` (`segment`, `scriptSegment`, which now returns
> the combat-AI band 0x0410–0x0436 as stored); the script decoder and listing model in `CytheraCore/Script/` (not yours
> to change).
>
> **This session's tasks** (three lanes, disjoint files; none touches `Package.swift`; merge order C6, C7, C10):
>
> | task | what it delivers | tests | suite after |
> |---|---|---|---|
> | C6 minor | the 46 `'asnd'` sound segments and the 13 interface `snd ` resources decoded to PCM, with the converter rule | 6 | **63** |
> | C7 ⚑ | the 11 QuickTime music descriptions and their event words decoded (nothing played) | 8 | **71** |
> | C10 minor | the UI resource records (dialogs, items, windows, controls, alerts, menus, strings, styles, font families, start rects, prefs) and the bitmap fonts | 9 | **80** |
>
> If the merge order changes, each merge is previous + that task's count (C6 6, C7 8, C10 9).
>
> Not this session: C11, C12, C13 (session C), anything of Phase 1, any `Package.swift` target change, any HectorKit
> change, any app target, anything with a window, any file under `CytheraCore/Script/`.
>
> **Gates, expected as of 2026-11-15** (commands in the plan's gate table, section 0):
>
> | gate | expected |
> |---|---|
> | grounding before the first dispatch | suite at the base = **57**, 0 failed or skipped; `ls Resources/Cythera \| wc -l` = 20; HectorKit main `ef2c341` |
> | G2 suite (count `^Test Case` lines) | 57 → 63 → 71 → 80, then `0` failed/skipped after each merge |
> | G8 parity (C9's recipe, a no-regression check) | still `PARITY-OK` at the session's final head |
> | G7 layering greps | both empty |
> | G6 scope fence · G9 clean tree | each task's diff ⊆ its card's Files · empty after every commit |
> | G1 HectorKit, at the close | `PASS: zero skips, zero failures, executed 370 == floor 370` at `ef2c341` (or a later clean main, recorded) — only with `HECTORKIT_DATA_AKI11` set as the plan's G1 row says |
>
> **Binding rules (each has bitten here or on this machine):**
> - Any number that disagrees with the plan (count, size, sample total, ladder total): STOP, show the command output;
>   never edit an expectation.
> - Numbers in your close come from commands you ran at the merge head, never from a subagent's report.
> - Per task one `fk-implementer`, then two `fk-reviewer` legs (spec, then quality); for C7 ⚑ leg 2 does what the C7
>   card's "Reviewer legs" line says (re-derive the event-word classification from Apple's `QuickTimeMusic.h` field layout
>   as contract 2 states it, and record the raw words of three events beside their decode). No `model` param. Each leg builds in its OWN scratch copy (`git archive <sha> | tar -x` into a fresh
>   directory, `HECTORKIT_PATH=/Users/andiyar/Developer/HectorKit`), never the worktree, never another leg's copy.
> - **Fable cross-check:** exactly one, when all three tasks are merged, over the session's whole diff (restricted to
>   `Cythera/` and `docs/cythera/`) plus the three As-executed notes. Fixes it asks for go through an `fk-implementer`
>   and are re-gated (G2, G8) before the close. If Ben or the Desk says otherwise, they win.
> - The three lanes may run in parallel only in separate worktrees or scratch clones (one session cannot write a second
>   worktree); merge them in order. At most 4–6 heavy processes at once; one full suite at a time — Ben's Mac has run
>   out of memory before.
> - Work in your own worktree (`EnterWorktree` if `git branch --show-current` says `main`); `git branch --show-current`
>   before every commit; explicit paths; never `git stash`, never `git add -A`.
> - `Resources/Cythera/` and `ghidra/cythera/` are read-only data.
> - Your own context cap is 300k: read it with `get_usage` before every dispatch and at the close; at ~240k finish the
>   task in flight, close, hand over (e.g. C10 to a follow-on session).
> - **Merging and pushing:** commit each verified step to main and push — but push only Cythera's own commits. Local
>   main is ahead of origin with other chains' commits (Deimos plan commits, and local merge commits): base your branch
>   on `origin/main`, push your commits with `git push origin <sha>:refs/heads/main` (fast-forward only), then merge your
>   branch into local main from the main checkout. Never touch any Ferazel or Deimos file, or `docs/NEXT.md`,
>   `docs/LOOP-LOG.md`, `docs/QUESTIONS.md`.
>
> **Close:** re-run G2, G8, G7 (and G1) at the merge head; run the Fable cross-check; add "As executed — session B"
> under each card (deviations, numbers, the verdicts); update STATE's Cythera block; write
> `docs/handoff-<date>-cythera-wave1-B.md` whose brief is rebuilt from nothing for session C (the plan's "### Session C":
> C13 → C11 → C12 and the re-base record; ladder 80 → 86 → 91); remove your worktree. Who starts session C: whatever the
> session that started you says (the Desk); if it said nothing, the repo's chaining rule. Closing message to Ben in
> plain English: what landed, the test count before and after as a table, what review and Fable caught, what runs next.
