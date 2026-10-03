# RESUME — one-paste session triggers (refreshed 2026-10-03)

## FOR BEN

Two sessions can run from here, in either order or at the same time: the **RE-bank lane** (Trigger A:
decompile and bank every game on the hit list) and **Phase 0 execution** (Trigger B2: build HectorKit from
the locked plan, then census the Aki data). The Phase 0 plan is written and reviewed; B2 executes it.

---

## Trigger A — RE-bank lane: DONE 2026-10-03

All five banks are on `main` (head 01cb120): `docs/aki/`, `docs/bubble-trouble/`, `docs/cythera/`, `docs/deimos/`,
`docs/ferazel/`. See `docs/handoff-2026-10-03-re-bank.md`. Ruling: Aki targets 1.2.0.

## Trigger A2 — optional RE deepening (only if a build session hits a NOT-RESOLVED wall)

```
Session: Ambrosia Classics — RE deepening for <game>. Repo ~/Developer/Ambrosia-Classics (main; push allowed).
READ FIRST: CLAUDE.md; docs/STATE.md; docs/handoff-2026-10-03-re-bank.md ("What remains"); docs/<game>/INDEX.md
(NOT-RESOLVED list + Review ledger) and ONLY the topical file the wall names; ghidra/README.md (recipe; the dumps
are git-ignored — regenerate with decompile.sh, PEF needs -processor PowerPC:BE:32:default -cspec macosx; set
GHIDRA_PROJ outside any dot-dir). Method: fable-kit orchestrator.md; Opus implementer, Fable-grade reviewer that
demands raw-disasm/data evidence per HIGH claim, Opus fix pass; append findings to the topical file + one INDEX line
(never a monolith), ⚑ corrected markers for changed readings. Known walls: Deimos gameplay code (movement, spawn
sets, weapons, damage — consider running the original under emulation to label functions by behaviour); Cythera
combat arithmetic (script bytecode; builtins are decompiled in script-builtins.md); Ferazel INDEX item 14.
Hazards: otool -tV fails on the Aki 1.1 PPC binary (use a Ghidra disasm post-script, e.g. docs/ferazel/tools/
FzDisasm.java); subagents cannot write files named REPORT-*.md. Commit per finished bank to main and push;
one STATE line; handoff + chip at the cap (250k orchestrator context).
```

## Trigger B2 — Phase 0 EXECUTE: HectorKit lift + Aki census, from the locked plan

```
You are the ORCHESTRATOR for Ambrosia Classics — Phase 0 execution: lift HectorKit out of the EV engine and
census the Aki data, from the LOCKED plan. Repos ~/Developer/Ambrosia-Classics (work in a worktree: EnterWorktree,
never `git stash`, verify the branch before every commit) and ~/Developer/HectorKit (work on `main` directly —
nobody else touches it). Push both. 300k-token orchestrator HARD CAP measured by the drop in <total_tokens>
since your first message (note the opening figure now); at the cap finish the in-flight task, wrap, chip.
Invoke `superpowers:subagent-driven-development` first. House method: ~/Developer/Toolkits/fable-kit/
orchestrator.md (§2 loop, §5 cap, §6 model policy); if you are not Fable, opus-driver.md before anything else.

MODEL SEAT: say which model you are in your first message. Every subagent `model: "opus"` — never Sonnet/Haiku,
never omitted — except the Task 5 (MAJOR) second review leg: omit `model` so it runs Fable-grade.

READ FIRST (in order): 1. docs/plans/2026-10-03-phase0-hectorkit-lift.md — "Verification model",
"Non-negotiable invariants", "Research notes", then the tasks you will run. 2. docs/STATE.md (whole).
3. docs/handoff-2026-10-03-phase0-plan.md. 4. CLAUDE.md of both repos. 5. Design doc §2 and §5 only.
Do NOT read the EV repo's STATE/DECISIONS/ghidra findings. The EV repo is read-only this phase (no edits, no
commits); its HEAD e23122f4 is the lift source.

STATE (live, 2026-10-03): HectorKit = one commit (door), no code. Classics `main` = design + plan + handoff.
Aki data facts are in the plan's research notes (82 PICT = 71 banded QuickTime-JPEG + 11 raw; 0 snd; 50 PNG;
14/15 audio files). The plan was dry-run by its reviewer: 112 HectorKit tests green with real data, Classics
census 6/6. Deviations the plan doesn't know about: none yet.

SCOPE: plan Tasks 0–8 in order; expect to close Tasks 0–4 in this session and chip Tasks 5–8 (Task 5 is MAJOR:
implementer + spec reviewer + Fable-grade quality reviewer). Per task: pre-dispatch grounding by you (grep the
real files the task names), one Opus implementer (TDD, explicit `git add` paths, commit with the trailer
`Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`), one Opus reviewer that RUNS `swift test` and
reports every finding with confidence/severity (no self-filtering), a fix round if needed. Deviations you may
settle alone: test names, file splits, script wording. Everything that changes a decoded byte, a public API
shape, a census number or a ruling in the plan's D1–D3 is Ben's — STOP and ask. Do NOT start HectorShell,
Phase 1 screens, or the EV shim.

VERIFICATION GATE (run yourself from the merge head, never relay a subagent's number):
`cd ~/Developer/HectorKit && tools/check-zero-skip.sh` must print 0 skipped, 0 failures, and the floor the
plan records for the task you just closed (89 after Task 4, 109 after Task 5, 112 after Task 6);
`cd Aki/Core && AKI_DATA_11=… AKI_DATA_12=… swift test` 6/6 after Task 7; `swift run aki-census` output pasted
verbatim into docs/aki/data-census.md. Tag HectorKit v0.1.0 only after Task 8's gates pass.
Honesty gates: none this phase (no screens); Ben reads docs/aki/data-census.md.

AUTHORIZATIONS: merge the Classics worktree branch to main when a task's gates pass: yes; push both repos:
yes; tag HectorKit v0.1.0: yes (Task 8 only); EV repo: NEVER edit or commit; game data: never commit
(Resources/ is ignored; symlinks only).

HAZARDS: `swift test` prints one 'All tests' block per test bundle, no package total — count `Test Case` lines
(the plan's script does). The Classics path dependency `../../../HectorKit` needs the untracked symlink
`.claude/worktrees/HectorKit → ~/Developer/HectorKit` when working in a worktree (plan Task 0). `grep skipped`
also matches the `[HectorResources] skipped A Corrupt.rez` log line — anchor on `Test Case`. A worktree with
untracked files is fine; "clean" means no modified tracked files.

CLOSE: finish the in-flight task at the cap, never start another. Merge when verified; STATE + DECISIONS
(plan Task 8 seeds docs/DECISIONS.md in both repos; if you stop before Task 8, seed them yourself with the
rulings in the handoff) + handoff; memory file + index line; remove the worktree, delete the branch; spawn ONE
chip for the next tasks carrying THIS block updated (state as it will be, last SHAs, floor reached);
closing message in plain English: what landed, what review caught, "Still owed by you", "Chips queued".
```
