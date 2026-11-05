# Handoff — 2026-11-05 — Deimos Rising: re-planning pass done; next = wave 2a then 2b (waits for Ben's go)

**TL;DR.** The re-planning pass (`~/Developer/Toolkits/fable-kit/replan.md`, Fable 5.1 in the seat) reviewed the
whole Deimos lane, wrote the remainder spec and plan, and audited the 44 commits of branch `deimos-phase2` with five
Opus reviewers: every rule matches the oracle, 0 redo, 23 change, 12 missing. Ben answered the six questions (D45).
Nothing was built. **The next session runs wave 2a; the one after runs wave 2b; nothing past 2b.** Ben says go.

## Read first (in order)
1. `docs/superpowers/plans/2026-11-05-deimos-remainder.md` — the verification model, the gates, Tasks 2.1–2.5.
2. `docs/superpowers/audits/2026-11-05-deimos-phase2-audit.md` — "Rulings" (the fix round's rows), then the five
   reports for `File:line` and addresses.
3. `docs/superpowers/specs/2026-11-05-deimos-remainder-design.md` §3, §4, §6, §7.
4. The Phase 2 plan on the branch, `git show deimos-phase2:docs/plans/2026-10-07-deimos-phase2.md` — the contracts for
   C12 (§"C12") and C18a (§"C18a"), with their ⚑ Amendment lines.
5. `docs/DECISIONS.md` D31 (+ addendum, on the branch until the merge), D45.

## State of the lane (live, 2026-11-05)
| Item | Value |
|---|---|
| branch `deimos-phase2` tip | adea0e3, 44 commits past merge base cc84fb0, pushed, unmerged |
| worktree | `.claude/worktrees/inspiring-cannon-e97ccd` (branch checked out there; do not reset or switch it) |
| `Deimos/Core` suite at the tip | 313 / 0 / 0 (against HectorKit main ef2c341 through the `.claude/worktrees/HectorKit` symlink; identical against e595472) |
| main `Deimos/Core` | 189 / 0 / 0 |
| HectorKit main | ef2c341, zero-skip 370 executed, 0 failed, 4 Aki 1.1 skips (machine data path; not ours) |
| HectorKit worktree `~/Developer/HectorKit-worktrees/deimos-k2` | at e595472, merged into kit main; may be removed |
| oracles | dump `ghidra/deimos/Deimos_pef.decompiled.c` (main; the branch worktree lacks it — read main's); listing `ghidra/deimos-proj/disasm-review3-all.txt`; decoded units `~/Developer/Ghidra/deimos/proj/data/Game/unde/*.txt` |
| sibling sessions | a Cythera pass and an Expedition 33 pass may be writing docs in this checkout; commit only your own paths |

## The brief for the next orchestrator (wave 2a)

```
You are the ORCHESTRATOR for Deimos Rising (Ambrosia Classics) — wave 2a of the remainder plan: the audit's fix
round on branch deimos-phase2, the merge of that branch into LOCAL main, and the research-bank corrections.
Repo /Users/andiyar/Developer/Ambrosia-Classics. Local only: merge to main is authorised (Task 2.2), push is NOT
(Ben pushes). Work in the existing branch worktree .claude/worktrees/inspiring-cannon-e97ccd for Task 2.1
(never git stash, never reset or switch branches anywhere; verify `git branch --show-current` = deimos-phase2
before every commit); Tasks 2.2 and 2.3 run in the main checkout on main. Invoke
superpowers:subagent-driven-development first. House method ~/Developer/Toolkits/fable-kit/orchestrator.md
(§2 loop, §5 cap, §6 model policy); if you are Opus, opus-driver.md §3. Echo the mission in one sentence, say what
you'll do first, start.

MODEL SEAT: Opus 5.5 may hold this seat (wave 2a is mechanical). Say which model you are in your first message.
Every subagent runs on claude-opus-5-5 exactly: dispatch fk-implementer / fk-reviewer and OMIT the Agent `model`
param. Reviews are Opus-only (Ben, 2026-10-07, restated 2026-11-05). Floor: one implementer + one reviewer per task.

CAP: 300k of your own context, subagents excluded. Sized for three tasks (2.1 in three families, 2.2, 2.3); do not
add one; do not start wave 2b. Note the opening <total_tokens>; before every dispatch write one line: task, spend
so far, next. At ~240k start closing.

READ FIRST: docs/handoff-2026-11-05-deimos-replan.md (this file, "Read first" 1–5).

TASKS (the plan is the authority; copy its commands):
 2.1 the fix round — three families A/B/C exactly as the plan's Task 2.1 lists (files, rows, tests, commits); each
     family: failing tests first, fix, G2 by filter, explicit-path commit, one fk-reviewer leg that runs the tests
     and re-reads every listing address the fix cites. Close: G2 at the branch tip = 318/0/0.
 2.2 merge deimos-phase2 into local main (plan Task 2.2 steps 1–4): expect conflicts only in docs/STATE.md and
     possibly docs/DECISIONS.md (D31 is free on main); G2 = 318/0/0 at the merge head; G3; G5 = the first app build
     against current HectorKit (xcodegen generate; Deimos, Aki, BubbleTroubleX BUILD SUCCEEDED) — a G5 failure is a
     kit-drift finding: STOP and report, never patch the kit from this lane. Do not push.
 2.3 bank corrections (plan Task 2.3): one implementer over docs/deimos/*.md from the handoff's "Bank corrections
     collected for B1", the Phase 2 plan's eight items and the audit's nine; one reviewer confirms every note at its
     address; commit `docs(deimos): Phase 2 bank corrections (<n> notes)`.

GATES: G1 370 executed (4 skips recorded), G2 318, G3 empty diff, G5 ×3, G6 per task, G7 empty, G10 clean.
NOT in this wave: C12, C18a, anything in wave 3+, any kit change, any push, any windowed launch.

CLOSE: STATE (the Deimos Phase 2 paragraph: numbers as measured), DECISIONS D45 as-built lines, remove the branch
worktree after 2.2 is green, memory file + index line, then ONE chip for wave 2b (C12 then C18a; the plan's Tasks
2.4 and 2.5; a fresh worktree from main; recommended seat Fable 5.1 — the joins are where the seat's judgement
matters — Ben decides). Closing message to Ben in plain English: what landed, the numbers before/after, what review
caught, the next session to click. No "owed by you" section.
```

## Wave 2b (the chip after 2a; for the record)
C12 (plan Task 2.4, +9 → 327) then C18a (Task 2.5, +8 → 335), each ⚑ MAJOR with two Opus legs, in a fresh worktree
from main; G5 at the close. Recommended seat: Fable 5.1 (the join tasks; the audit's twelve "missing" seams are
theirs). Nothing past C18a.

## Machine notes
- A kit worktree folder not named `HectorKit` does not resolve as the package `HectorKit`; point `HECTORKIT_PATH`
  at a `HectorKit`-named symlink if you ever test against another kit commit.
- `grep` may be a shell function in agent shells; use `/usr/bin/grep`. There is no `timeout` binary.
- Parallel implementers in one worktree: own `--scratch-path` each; explicit-path commits.
- `xcodegen generate` writes a git-ignored `*.xcodeproj`; fine in a worktree.
