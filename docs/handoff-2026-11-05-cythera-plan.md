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

## The brief for session A (paste into a fresh session)

> You are the ORCHESTRATOR (Claude Opus 5.5) for **Cythera wave 1, session A: tasks C8 → C9** in
> `/Users/andiyar/Developer/Ambrosia-Classics` (quote the HectorKit path; the data path has a space). Method:
> `superpowers:subagent-driven-development`; house overlay `~/Developer/Toolkits/fable-kit/orchestrator.md` (read §2–§7
> first) and the repo's `CLAUDE.md`. Ben's rules: `~/.claude/CLAUDE.md` (plain English, numbers in tables).
> **Model policy:** one `fk-implementer` + one `fk-reviewer` per task, no `model` param; both tasks are ⚑ → two
> reviewer legs each; Fable only on a contraindication and only after asking Ben.
>
> **READ FIRST, in order:** (1) `docs/superpowers/plans/2026-11-05-cythera-remainder.md` §0 (verification model, paths,
> gates, ladder) and "Wave 1 — Session A" (C8 and C9 whole); (2) `docs/superpowers/specs/2026-11-05-cythera-remainder-design.md`
> §2 (module map, "one instruction walker") and §7 (how the script decoder is proven); (3)
> `docs/plans/2026-10-06-cythera-phase0.md` lines 14–24 (corrections), 101–141 (invariants), 154–199 (S2);
> (4) `docs/cythera/script-vm.md` §4, §5, §8 and `docs/cythera/script-census.md` §1–§2; (5) `docs/DECISIONS.md` D45 and
> D28; (6) `docs/superpowers/audits/2026-11-05-cythera-phase0-audit.md` rulings 2 and 10.
>
> **SCOPE:** C8 (script instruction decoder, 6 tests → 50) then C9 (segment model + canonical parity for 958 segments,
> `script_canon.py`, the committed `docs/cythera/script-parity.sha256`, the AI band returned as stored, 7 tests → 57).
> NOT in this session: C6, C7, C10, C11, C12, C13, anything of Phase 1, any `Package.swift` target change, any HectorKit
> change, any app target, anything with a window.
>
> **Worktree:** `EnterWorktree`; verify `git branch --show-current` before every commit; never `git stash`, never
> `git add -A`; commit explicit paths with the trailer `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
> The worktree reaches HectorKit through `.claude/worktrees/HectorKit` (exists). Pre-dispatch grounding (do it
> yourself): `SegmentFile.swift` lines 118 (`segment`) and 128 (`scriptSegment`); `ls ghidra/cythera/cythera-scripts | wc -l`
> = 958; the plan's C9 contract 4 numbers (22,166 / 16,899 / 4,665 / 602 / 34 mnemonics) re-measurable by its regexes.
>
> **GATES (the plan §0):** G2 after each task (C8 **50/0**, C9 **57/0**, counted by `^Test Case` lines — there is no
> package total), G6 scope fence, G7 layering greps empty, G8 parity (`script_canon.py` over the committed listings →
> `diff` clean → `PARITY-OK`), G9 clean tree, G1 at the close with the Aki override
> (`HECTORKIT_DATA_AKI11="/Users/andiyar/Developer/Ambrosia/Resources/Aki - Mahjong Solitaire/Aki - Mahjong Solitaire.app/Contents/Resources"`
> → `PASS … executed 370 == floor 370` at ef2c341 or a later clean main, recorded). **Invariant 10:** any number that
> disagrees (a hash, a count, a ladder total) → STOP, show the command output, ask Ben; never edit an expectation.
> Numbers in your close come from commands you ran, never from a subagent's report.
>
> **CLOSE:** merge the worktree to local `main` when verified (never push — a human session pushes); re-run G2/G7/G8 at
> the merge head; append "As executed — session A" to the plan (deviations, numbers); update STATE's Cythera bullet
> (one line); write `docs/handoff-2026-11-05-cythera-wave1-A.md` and **chip session B** (C6 ∥ C7 ∥ C10: the plan's
> "Session B" table; ladder 57 → 63 → 71 → 80; same rules, same reads 1–5; C7 ⚑ two legs); remove the worktree. Cap:
> 300k of your own context — at ~240k finish the task in flight, close, chip; never start a task you cannot close.
> Closing message to Ben in plain English: what landed, the ladder before/after as a table, what review caught, the
> next session to click. No "owed by you" section.
