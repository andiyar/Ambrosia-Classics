# Handoff — Cythera re-planning pass → wave 1 (Phase 0b) — 2026-11-05

Seat: Claude Fable 5.1 (planning only; nothing built). Ben accepted all five questions (DECISIONS **D45**). Documents:
spec `docs/superpowers/specs/2026-11-05-cythera-remainder-design.md` · plan
`docs/superpowers/plans/2026-11-05-cythera-remainder.md` · audit `docs/superpowers/audits/2026-11-05-cythera-phase0-audit.md`.

- **State at hand-over:** `Cythera/Core` **44/0/0** (34 core + 10 render) on HectorKit main **ef2c341** (new pin, floor
  **370**); `Resources/Cythera/` 20 files; the decompile committed at `ghidra/cythera/`; no Cythera branch or worktree.
- **Next:** wave 1, session A (C8 → C9). Then sessions B (C6 ∥ C7 ∥ C10) and C (C13 → C11 → C12), each chipped by its
  predecessor. **Waits for Ben's go.**
- **Carried, not in wave 1:** the HectorKit gate script's default Aki path is stale (`tools/check-zero-skip.sh`, the
  `HECTORKIT_DATA_AKI11` line) — a one-line kit fix for whoever next touches HectorKit; the PICT opcode-walk kit carry
  (D14: an error naming the first bits opcode); Phase 4's writable-store protocol and `RefindSegment` rule (audit 1, 11).

*Everything above this line is history (2026-11-05). The brief below was rebuilt from nothing on 2026-11-08 and is
the only part a new session reads.*

## The brief for the next session (wave 1, session A — paste into a fresh session)

> You are the ORCHESTRATOR for **Cythera wave 1, session A: tasks C8 then C9**, in
> `"/Users/andiyar/Developer/Ambrosia-Classics"`. Method: `~/Developer/Toolkits/fable-kit/orchestrator.md`. Ben's
> rules: `~/.claude/CLAUDE.md` (plain English, numbers in tables).
>
> **Authority:** `docs/superpowers/plans/2026-11-05-cythera-remainder.md` is the one plan. Read its headings
> "0. The verification model", "0b. Done before this plan, the binding invariants, the locked surface", the
> "Wave 1 — Phase 0b" introduction, and "Session A — C8 then C9" (both cards whole). Nothing else in that file is
> this session's.
>
> **Read first, in order:** the repo's `CLAUDE.md`; `docs/STATE.md` (where things stand — do not rely on any copy of
> it); this brief; the plan headings above; the research the cards mirror: `docs/cythera/script-vm.md` §4, §5, §8 and
> `docs/cythera/script-census.md` §1–§2.
>
> **This session's tasks:**
>
> | task | what it delivers | acceptance |
> |---|---|---|
> | C8 ⚑ | the script instruction decoder: one statement or expression at a time, 95 builtin names | 6 tests green; suite 50/0; the 0x1802 head decodes exactly as the card lists |
> | C9 ⚑ | the segment model, reachability and canonical parity for all 958 script segments; the combat-AI band read as stored | 7 tests green; suite 57/0; `script-parity.sha256` committed (958 lines) and every Swift hash equal |
>
> Not this session: C6, C7, C10, C11, C12, C13, anything of Phase 1, any `Package.swift` target change, any HectorKit
> change, any app target, anything with a window.
>
> **Gates, expected as of 2026-11-08** (commands in the plan's gate table):
>
> | gate | expected |
> |---|---|
> | G2 suite (count `^Test Case` lines) | 44 before · C8 **50**, then `0` failed/skipped · C9 **57**, then `0` |
> | G8 parity | `PARITY-OK`; 958 hash lines; 22,166 canonical lines |
> | G7 layering greps | both empty |
> | G6 scope fence · G9 clean tree | the diff ⊆ the card's Files · empty after every commit |
> | G1 HectorKit, at the close | `PASS: zero skips, zero failures, executed 370 == floor 370` at `ef2c341` (or a later clean main, recorded) — only with `HECTORKIT_DATA_AKI11` set as the plan's G1 row says |
> | grounding before the first dispatch | `ls ghidra/cythera/cythera-scripts \| wc -l` = 958; `SegmentFile.swift` has `segment` at line 118 and `scriptSegment` at 128 |
>
> **Binding rules (each has bitten here or on this machine):**
> - Any number that disagrees with the plan (count, hash, ladder total): STOP, show the command output; never edit an expectation.
> - Numbers in your close come from commands you ran at the merge head, never from a subagent's report.
> - One `fk-implementer` + one `fk-reviewer` per task, no `model` param; both tasks ⚑ → two reviewer legs; Fable only after asking Ben.
> - Work in your own worktree (`EnterWorktree`); `git branch --show-current` before every commit; explicit paths; never `git stash`, never `git add -A`.
> - `Resources/Cythera/` and `ghidra/cythera/` are read-only data.
> - At most 4–6 heavy processes at once (builds, test suites); one full suite at a time — Ben's Mac has run out of memory before.
> - Your own context cap is 300k: at ~240k finish the task in flight, close, hand over; never start a task you cannot close.
> - Merge to `main` and push (the repo's `CLAUDE.md`: commit each verified step to main and push). Never touch any Ferazel file or `docs/NEXT.md`, `docs/LOOP-LOG.md`, `docs/QUESTIONS.md` — the Ferazel chain owns them.
>
> **Close:** re-run G2, G7, G8 (and G1) at the merge head; add "As executed — session A" under the two cards in the
> plan (deviations, numbers); update STATE's Cythera bullet in one line; write `docs/handoff-<date>-cythera-wave1-A.md`
> whose brief is rebuilt from nothing for session B (the plan's "Session B" heading: C6, C7 ⚑, C10; ladder 57 → 63 →
> 71 → 80); remove your worktree; then start the next attended Cythera session yourself (`start_session`, fresh context, brief = "read the new handoff's brief and run it" — the repo's chaining rule, 2026-11-07), unless a question only Ben can answer blocks session B, in which case stop and name it. Closing message to Ben in plain
> English: what landed, the test count before and after as a table, what review caught, what runs next.
