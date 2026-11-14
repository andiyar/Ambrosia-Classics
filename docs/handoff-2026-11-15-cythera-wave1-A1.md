# Handoff — Cythera wave 1, session A1 (C8) → session A2 (C9) — 2026-11-15

Seat: Opus 5.5. Session A was split in two by the Desk (the session that starts orchestrators and relays Ben's
answers): A1 did C8 alone, A2 does C9 alone.

- **Landed:** C8, the script instruction decoder — commits 89ac2af + 9bb4b78 (review fix round), pushed to origin as a
  fast-forward; merged into local main as f932830. Suite 44 → **50**, 0 failed or skipped; HectorKit ef2c341, 370 run,
  0 skipped. The numbers, both review legs and every deviation are under the C8 card: "As executed — session A1".
- **Review caught:** the plan's 0x9C wording is wrong (the binary reads two expressions on both branches); the 0x9E
  local-subroutine target is exposed nowhere (carried to C9, below); a wrong doc comment and a partial prefix sweep
  (fixed in 9bb4b78).
- **Ben's answer (2026-11-15, via the Desk), word for word: "One after C9".** One Fable cross-check after C9 merges,
  over C8 and C9 together.
- **Main at hand-over:** local main is ahead of origin by three Deimos plan commits (b27067b, 611347d, 5c1e98a) that
  the Deimos chain has not pushed. A1 did not push them: it pushed only its own commits (`git push origin
  <sha>:refs/heads/main`, a fast-forward) and merged its branch into local main.

*Everything above this line is history. The brief below was rebuilt from nothing and is the only part a new session
reads.*

## The brief for the next session (wave 1, session A2 — C9 alone)

> You are the ORCHESTRATOR for **Cythera wave 1, session A2: task C9 only**, in
> `"/Users/andiyar/Developer/Ambrosia-Classics"`. Seat: Opus 5.5. Method: `~/Developer/Toolkits/fable-kit/orchestrator.md`.
> Ben's rules: `~/.claude/CLAUDE.md` (plain English, numbers in tables).
>
> **Authority:** `docs/superpowers/plans/2026-11-05-cythera-remainder.md` is the one plan. Read its headings
> "0. The verification model", "0b. Done before this plan, the binding invariants, the locked surface", the
> "Wave 1 — Phase 0b" introduction, the C8 card's **"As executed — session A1"** paragraph (what C9 builds on), and
> "#### Task C9" whole. Nothing else in that file is this session's.
>
> **Read first, in order:** the repo's `CLAUDE.md`; `docs/STATE.md` (do not rely on any copy of it); this brief; the
> plan headings above; the research the card mirrors: `docs/cythera/script-census.md` §1–§2, `docs/cythera/ai-scripts.md`
> §3, `docs/cythera/script-vm.md` §8; the tool `docs/cythera/tools/scriptdis.py` (`class Dis`: classification,
> reachability, gap sweep, listing output).
>
> **What C8 left you** (`Cythera/Core/Sources/CytheraCore/Script/`): `InstructionDecoder.statement(in:at:)` and
> `.expressionEnd(in:at:)`, `ScriptInstruction` (`offset`, `length`, `mnemonic`, `flag`, `jumpTargets`, `kind`),
> `ScriptOpcodes`, `BuiltinNames` (95 names), `ScriptDecodeError` (`invalidOpcode`, `truncated`, `textRunsPastEnd`,
> `nullBuiltin`). It matches the committed listings on all 18,864 non-AI instruction lines (length + mnemonic).
>
> **This session's task:**
>
> | task | what it delivers | acceptance |
> |---|---|---|
> | C9 ⚑ | the segment model, reachability and canonical parity for all 958 script segments; the combat-AI band read as stored | 7 tests green; suite 57/0; `docs/cythera/script-parity.sha256` committed (958 lines) and every Swift hash equal |
>
> **Two additions to the C9 card (from C8's review):**
> 1. `jumpTargets` carries only jump targets (0x88/89/8C/8D/90 — the listing's `>` marks). The **0x9E local-subroutine
>    target is not exposed**; reachability needs it (0x1802 @0060 is reached only by the callsubs at @0326 and @055F;
>    corpus 15 local subroutines, 40 callsub sites, none inside an expression). Add it to `ScriptInstruction` as its
>    **own field** (not into `jumpTargets`, which would break the `>` flags); the same for 0x43 code pointers if the
>    walk needs them. This touches `ScriptInstruction.swift` and `InstructionDecoder.swift` — record that file-list
>    widening in As executed (G6 = the card's Files + those two).
> 2. The C8 card's contract 1 says "0x9C seg16 + (seg ≠ 0xFFFF: one int expr) + one arg expr"; the binary reads two
>    expressions on both branches and the decoder already does. Do not "correct" it back.
>
> Not this session: C6, C7, C10, C11, C12, C13, anything of Phase 1, any `Package.swift` target change, any HectorKit
> change, any app target, anything with a window.
>
> **Gates, expected as of 2026-11-15** (commands in the plan's gate table, section 0):
>
> | gate | expected |
> |---|---|
> | grounding before the first dispatch | `ls ghidra/cythera/cythera-scripts \| wc -l` = 958; `SegmentFile.swift` has `segment` at line 118 and `scriptSegment` at 128; suite at the base = 50 |
> | G2 suite (count `^Test Case` lines) | 50 before · **57** after, then `0` failed/skipped |
> | G8 parity (C9 step 6) | `PARITY-OK`; 958 hash lines; 22,166 canonical lines |
> | script_canon.py over the listings (C9 step 1) | 958 files · 22,166 lines · flags `-` 16,899 · `>` 4,665 · `x` 602 · 34 mnemonics as the card's histogram |
> | G7 layering greps | both empty |
> | G6 scope fence · G9 clean tree | the diff ⊆ the card's Files (+ the two C8 files above) · empty after every commit |
> | G1 HectorKit, at the close | `PASS: zero skips, zero failures, executed 370 == floor 370` at `ef2c341` (or a later clean main, recorded) — only with `HECTORKIT_DATA_AKI11` set as the plan's G1 row says |
>
> **Binding rules (each has bitten here or on this machine):**
> - Any number that disagrees with the plan (count, hash, ladder total): STOP, show the command output; never edit an expectation.
> - Numbers in your close come from commands you ran at the merge head, never from a subagent's report.
> - One `fk-implementer` + two `fk-reviewer` legs (C9 is ⚑; leg 2 as the card says: re-derive the dictionary layout and
>   `At`'s probe from `At__7TInterpF5VAddrs @ 10083798`, confirm "deleting one byte from the 0x1802 listing's canon
>   changes exactly one hash"), no `model` param. Each leg builds in its OWN scratch copy (`git archive <sha> | tar -x`
>   into a fresh directory, `HECTORKIT_PATH=/Users/andiyar/Developer/HectorKit`), never the worktree, never another leg's copy.
> - **Fable cross-check: exactly one, after C9 merges, over C8 + C9 together (Ben, 2026-11-15: "One after C9").** The
>   diff is `bf8b9e0..<C9 merge>` restricted to `Cythera/` and `docs/cythera/`, plus the plan's two As-executed notes.
>   Fixes it asks for go through an `fk-implementer` and are re-gated (G2, G8) before the close.
> - Work in your own worktree (`EnterWorktree` if `git branch --show-current` says `main`); `git branch --show-current`
>   before every commit; explicit paths; never `git stash`, never `git add -A`.
> - `Resources/Cythera/` and `ghidra/cythera/` (incl. the 958 listings — the oracle) are read-only data.
> - At most 4–6 heavy processes at once; one full suite at a time — Ben's Mac has run out of memory before.
> - Your own context cap is 300k: read it with `get_usage` before every dispatch and at the close; at ~240k finish the
>   task in flight, close, hand over.
> - **Merging and pushing:** commit each verified step to main and push — but push only Cythera's own commits.
>   If local main is ahead of origin with another chain's commits (it was at A1's close: three Deimos plan commits),
>   do not push them: base your branch on `origin/main`, push your commits with `git push origin <sha>:refs/heads/main`
>   (fast-forward only), then merge your branch into local main from the main checkout. Never touch any Ferazel or
>   Deimos file, or `docs/NEXT.md`, `docs/LOOP-LOG.md`, `docs/QUESTIONS.md`.
>
> **Close:** re-run G2, G8, G7 (and G1) at the merge head; run the Fable cross-check; add "As executed — session A2"
> under the C9 card (deviations, numbers, the Fable verdict); update STATE's Cythera bullet in one line; write
> `docs/handoff-<date>-cythera-wave1-A2.md` whose brief is rebuilt from nothing for session B (the plan's "Session B"
> heading: C6, C7 ⚑, C10; ladder 57 → 63 → 71 → 80); remove your worktree. Who starts session B: whatever the session
> that started you says (the Desk); if it said nothing, the repo's chaining rule. Closing message to Ben in plain
> English: what landed, the test count before and after as a table, what review and Fable caught, what runs next.
