# RESUME — one-paste session triggers (refreshed 2026-10-03)

## FOR BEN

Two sessions can run from here, in either order or at the same time: the **RE-bank lane** (Trigger A:
decompile and bank every game on the hit list) and **Phase 0 execution** (Trigger B2: build HectorKit from
the locked plan, then census the Aki data). The Phase 0 plan is written and reviewed; B2 executes it.

---

## Trigger A — RE-bank lane (all hit-list games)

```
Session: Ambrosia Classics — RE-bank lane (all hit-list games). Repo ~/Developer/Ambrosia-Classics.
READ FIRST (scoped): CLAUDE.md; docs/STATE.md (whole); docs/design-2026-10-03-hectorkit-and-classics.md §1, §4, §6
only; ghidra/README.md (the decompile recipe + binary forms); ~/Developer/Ambrosia/docs/ARCHIVE-INDEX.md
(where every original lives). Method: ~/Developer/Toolkits/fable-kit/fable.md §4 §6 §10 if first session here.
Do NOT read the EV repo's STATE/DECISIONS/ghidra findings.

GOAL: produce a confidence-labelled RE bank per game under docs/<game>/ (INDEX.md + topical files, same
discipline as the EV repo's docs/ghidra/INDEX.md: code readings, HIGH/MED/LOW per claim, NOT-RESOLVED
listed, nothing behaviour-verified until Ben's eyes). Games, in this order:
 1. Aki 1.2.0 (Intel slice of ~/Developer/Ambrosia/Resources/ambrosia-extracted/Action-Adventure/Aki -
    Mahjong Solitaire/Aki 1.2 UB/Aki.app) — Cocoa/ObjC rewrite; bank the ObjC method map, the rules
    (open-tile test, timer/bonus/penalty maths per difficulty, shuffle/hint/undo), level progression (17),
    the plain-text .aki format, prefs/stats storage; then DIFF against the 1.1.0 PPC dump
    (~/Developer/Ambrosia/ghidra/Aki_ppc.decompiled.c, Layout1..12 = AddTile(x,y,layer) lists; resolve the
    DOUBLE_ literals via read_const.py adapted to the PPC __literal8 section) — every rule delta is a
    banked item for Ben to arbitrate (1.1.0 = what he remembers, 1.2.0 = last word).
 2. Bubble Trouble X 1.1 (dump exists: ~/Developer/Ambrosia/ghidra/BTX_i386.decompiled.c, 1559 fns, all
    named): hero/enemy movement + AI per enemy type, bubble push/pop/bounce, dynamite, balloons, jewels,
    bonuses/EXTRA/multiplier/time bonus, MAZE(176 B)/LEVL(64 B)/btSP(TMPL in file)/FILM record layouts,
    the 30 fps frame step, FILM replay semantics (the future machine oracle).
 3. Ferazel's Wand 1.0.3 (PEF data fork `Ferazel's Wand` + .rsrc, under …/Ferazel's Wand (installed)/files/):
    engine identity, World Data / Sprites / Backgrounds record formats, physics constants, spell system.
 4. Deimos Rising 1.0.6 (PEF, …/DeimosRising/Deimos Rising 1.0.6 (volume)/Deimos Rising/): Pak format,
    sprite/sound containers, wave scripting.
 5. Cythera 1.0.4 (PEF, …/RPG/Cythera/Cythera (installed)/files/): Cythera Data format, .ai scripts.

RULES: Ghidra headless per ghidra/README.md (reuse existing dumps; new dumps + binaries stay git-ignored);
Opus implementers for each game's bank, a Fable reviewer per bank that reports EVERYTHING with confidence
(no self-filtering) and demands raw-disasm/data evidence for every HIGH claim; census numbers only from tool
output; write files, not chat reports (background agents: name an output path). Commit each bank to main
and push. Orchestrator stop at ~300k of its OWN context: wrap (STATE + handoff + RESUME) and chip the
continuation; never start a new game's bank you cannot finish. This lane edits docs/<game>/ and appends ONE
status line to docs/STATE.md; it does not touch the design doc or HectorKit.
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
