# Handoff — 2026-11-05 — Deimos Rising: re-planning pass done; next = wave 2a then 2b (waits for Ben's go)

## Brief for the next session (rebuilt 2026-11-08)

Everything below this brief is the history of the 2026-11-05 pass. The live state is `docs/STATE.md`.

```
You are the ORCHESTRATOR for Deimos Rising (Ambrosia Classics), wave 2a of the remainder plan: the audit's fix
round on branch deimos-phase2, the merge of that branch into LOCAL main, and the research-bank corrections.
Repo "/Users/andiyar/Developer/Ambrosia-Classics". Method ~/Developer/Toolkits/fable-kit/orchestrator.md
(§2 loop, §5 cap, §6 model policy). Seat: Fable 5.1 (Ben's choice, 2026-11-05); say which model you are in your
first message, echo the mission in one sentence, say what you do first, start.

AUTHORITY: docs/superpowers/plans/2026-11-05-deimos-remainder.md, and nothing else. Read its headings
"Verification model (read first)" (incl. "Standing rules for every implementer") and "Wave 2a" (Tasks 2.1,
2.2, 2.3). The cards are complete there; do not open older plans, hand-overs or the audit.

READ FIRST: CLAUDE.md; docs/STATE.md (the Deimos lines: grep -n -i deimos); this brief; the plan headings above;
for Task 2.3 only, the research-bank sections its table names (docs/deimos/<file> by section heading).

BEFORE TASK 2.1: git -C .claude/worktrees/inspiring-cannon-e97ccd status --porcelain must print nothing (the
superseded notes on the branch's old plan and hand-over were committed there on 2026-11-08).

TASKS (one fk-implementer + one fk-reviewer each; copy commands from the plan's code block):
 2.1 fix round, three families A/B/C in parallel in the branch worktree (disjoint files, own --scratch-path):
     failing tests first, fix, G2 by filter (+2, +1, +2), explicit-path commit, one review leg each that runs the
     tests and re-reads every listing address cited. Done = G2 at the branch tip 318/0/0, seat's own run.
 2.2 merge deimos-phase2 --no-ff into local main in the main checkout: conflicts only in docs/STATE.md and maybe
     docs/DECISIONS.md; G2 318/0/0 at the merge head; G3 empty; G5 three BUILD SUCCEEDED; then remove the branch
     worktree and the local branch. A G5 failure is kit drift: STOP and report.
 2.3 bank corrections: one implementer appends the 53 notes of the plan's table; data-census.md takes its note
     above the first `---` only; one reviewer confirms every note at its address. Done = marker count 53, G2
     318/0/0 at main, commit "docs(deimos): Phase 2 bank corrections (53 notes)".

GATES, expected as of 2026-11-08 (nothing under Deimos/ or in HectorKit has changed since the 2026-11-05 runs):
 G1 HectorKit zero-skip at kit main ef2c341: executed 370 (366 passed + 4 Aki 1.1 skips — a machine data path,
    record it, never "fix" it here)
 G2 Deimos/Core without DeimosReplayTests: 313/0/0 at the branch tip now -> 318/0/0 after 2.1, through 2.3
 G3 data-census.md diff vs the merge base: empty (2.1, 2.2)
 G5 Deimos, Aki, BubbleTroubleX: ** BUILD SUCCEEDED ** after xcodegen generate (2.2)
 G6 changed paths within the task's Files; G7 layering grep empty; G10 tree clean after each commit

BINDING RULES (each has bitten on this repo):
 - Every subagent is Opus 5.5: dispatch fk-implementer / fk-reviewer and OMIT the Agent `model` param.
 - Cap: 300k of your own context; note the opening total; one line before each dispatch (task, spend, next);
   start closing at ~240k. This wave is three tasks; do not start wave 2b.
 - Never push (Ben pushes). Merging to LOCAL main is authorised for Task 2.2 only.
 - Never git stash, reset or switch branches; never git add -A; explicit paths; trailer on every commit.
 - No app launches in this wave (G5 builds only; a launch opens a window and sound — Ben's say-so only).
 - At most four heavy processes at once (swift test / xcodebuild); Ben's Mac ran out of memory before.
 - Never patch HectorKit from this lane. Never touch Cythera or Ferazel files or their worktrees; other
   sessions write docs in this checkout — commit only your own paths.
 - Research data and dumps are read-only; the dump is ghidra/deimos/Deimos_pef.decompiled.c on main (the
   branch worktree lacks it).

CLOSE: STATE (the Deimos Phase 2 paragraph, numbers as you measured them); DECISIONS as-built lines under the
Deimos D45 entry; memory file + index line; a new handoff whose brief for wave 2b (Tasks 2.4 C12 -> 327 and 2.5
C18a -> 335, a fresh worktree from main) is built the same way from the plan's "Wave 2b" heading; then start the
next attended session yourself (CLAUDE.md, sessions chain) unless a question only Ben can answer blocks. Closing
message to Ben in plain English: what landed, the numbers before and after, what review caught, what is next.
```

## History — the 2026-11-05 re-planning pass (kept as record; not instructions)

**TL;DR.** The re-planning pass (`~/Developer/Toolkits/fable-kit/replan.md`, Fable 5.1 in the seat) reviewed the
whole Deimos lane, wrote the remainder spec and plan, and audited the 44 commits of branch `deimos-phase2` with five
Opus reviewers: every rule matches the oracle, 0 redo, 23 change, 12 missing. Ben answered the six questions (D45).
Nothing was built. **The next session runs wave 2a; the one after runs wave 2b; nothing past 2b.** Ben says go.

### State of the lane (as of 2026-11-05)
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

### Wave 2b (as planned 2026-11-05)
C12 (plan Task 2.4, +9 → 327) then C18a (Task 2.5, +8 → 335), each ⚑ MAJOR with two Opus legs, in a fresh worktree
from main; G5 at the close. Seat: Fable 5.1 (Ben's choice, 2026-11-05); agents Opus 5.5. Nothing past C18a.

### Machine notes
- A kit worktree folder not named `HectorKit` does not resolve as the package `HectorKit`; point `HECTORKIT_PATH`
  at a `HectorKit`-named symlink if you ever test against another kit commit.
- `grep` may be a shell function in agent shells; use `/usr/bin/grep`. There is no `timeout` binary.
- Parallel implementers in one worktree: own `--scratch-path` each; explicit-path commits.
- `xcodegen generate` writes a git-ignored `*.xcodeproj`; fine in a worktree.
