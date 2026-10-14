STATUS: CONTINUE

# NEXT — the chip for the next unattended loop run (rewritten by every run at CLOSE)

You are the ORCHESTRATOR for **Ferazel's Wand** in Ambrosia Classics — mission: **get Ferazel's Wand DONE**: the whole
game as design §1 defines it (all 24 levels, world map, saves, spells, enemies, bosses, victory; then Windows), built
phase by phase in Ben's order (design §8), machine-gated by you, feel-gated by Ben. **Ben is away (Fiji, from
2026-10-13, a few days) and wants to come back to a playable, or at least testable, game — get as much done as you
can, in order, without cutting corners on the 100 % rule.** Repo `/Users/andiyar/Developer/Ambrosia-Classics`
(`$REPO`); local-only — **never push, fetch, or touch a remote**. You are already in your own worktree on your own
`loop/<N>-<stamp>` branch (the looper made it from `main`); verify `git branch --show-current` before EVERY commit.
Invoke `superpowers:subagent-driven-development` first. House method: `~/Developer/Toolkits/fable-kit/orchestrator.md`
(§2 loop, §3 subagent brief, §5 cap, §6 model policy) and `opus-driver.md` §3. Echo the mission in one sentence, say
what you'll do first, start.

## MODEL SEAT (Ben 2026-10-07 + 2026-10-13; CLAUDE.md "Workflow"; D34)
- You are Opus 5.5 (the looper's `MODEL`). Every implementer and reviewer is `fk-implementer` / `fk-reviewer` with
  **NO `model` param** (frontmatter pins `claude-opus-5-5`; `"opus"` there is the wrong Opus). Never Sonnet/Haiku,
  never general-purpose for typed work. Floor: one implementer + one reviewer per task; ⚑ MAJOR = two Opus review legs.
- **Fable 5.1 is the cross-check, not the gate.** Exactly these Fable legs (`fk-reviewer` with `model: "fable"`,
  named "FABLE-GRADE gate" in its prompt; it re-runs the gates itself): (1) **each phase plan**, once, after its two
  Opus review legs, before execution; (2) **each phase end**, once, over the phase's whole diff
  (`git diff <phase-start SHA>..HEAD`) plus the gate card, before staging; (3) a tie-break when two Opus legs
  contradict each other on a MAJOR finding and one fix round did not settle it (log "Fable tie-break" in LOOP-LOG).
  **This chip narrows the kit's standing prompt for this project:** its Fable list also names "a task the plan marks
  MAJOR" and "an exact port from a binary" — here that would be most tasks, which is the per-gate spending Ben stopped
  on 2026-10-07 (memory `feedback-no-fable-gate-every-task`; D34). Nothing else runs on Fable. Fable findings are
  fixed by Opus implementers before the phase is staged. If Fable is unavailable, record "Fable check owed" in STATE +
  QUESTIONS and continue.
- Stop finished subagents (`TaskStop`) when their notice says background work is still running.

## CAP
300k of your own context, subagents excluded. **One run = one unit of work:** the next **2 tasks** of the current
phase's ladder (3 when at most one is ⚑ MAJOR); or one **phase-end run** (the phase's stage/gate-card task + the Fable
phase review + fixes); or one **planning run** (the next phase's plan). Note the opening `<total_tokens>`; before every
dispatch write one line: task, spend so far, next. At ~240k start closing; at 300k finish the in-flight task only, then
CLOSE. Partial progress is progress: merge what is green, say what is not.

## READ FIRST (in order)
1. This file, then `docs/QUESTIONS.md` (act on any new text under an item's `Answer:` before anything else — it is an
   authorization for exactly what it says; record it in DECISIONS). Q2 is the Phase 2 gate card: if Ben answered (b)/(c),
   his notes become Phase 2 fix tasks — plan them FIRST (a small fix ladder ahead of the next Phase 3 task, or a separate
   unit if large) and say so in LOOP-LOG. Q3 is the Phase 3 plan's four choices: a non-default answer becomes a small
   task in the phase (add it to the plan's ladder).
2. `CLAUDE.md`; `docs/STATE.md` (whole file); `docs/DECISIONS.md` **D33** (Phase 2 as built), **D34** (the loop's
   authorizations), **D35** (Phase 3 rulings).
3. **The plan: `docs/plans/2026-10-14-ferazel-phase3.md`** — Verification model (l. 69), Invariants + Hazards (l. 129),
   Shared architecture LOCKED (l. 209), this run's task sections (F1a l. 967, D1 l. 1010, F1b l. 1034), Execution order
   (l. 1364), Bank corrections (l. 1511, each task appends the BCs it relies on), Rulings (l. 1624). Line numbers are
   as of run 12's close. Read the "⚑ As executed" bullets of L2, L1 (l. 693, 781) and RX, M1, M2 (l. 824, 910, 953) —
   the `LevelRun` and `WorldMapRun` APIs F1b composes, where the dump beat the plan, and what was carried.
4. The bank files and dump ranges each task section cites (`docs/ferazel/*.md`, `ghidra/ferazel/`).

## RECONCILE FIRST (before any dispatch — the chip can be stale)
1. `git -C "$REPO" worktree list` and `git -C "$REPO" branch --list 'loop/*'`: a leftover `loop-*` worktree or branch
   means an earlier run did not merge. Read its log; if its commits pass the gates, rebase them onto `main` in YOUR
   worktree (cherry-pick), re-run G2, continue from there; otherwise record it in LOOP-LOG + QUESTIONS and start from
   `main`. Never delete another run's worktree or branch.
2. `git -C "$REPO" log --oneline -8 main` and `git -C "$REPO" status --porcelain`: the STATE block below must name
   main's head. If main moved past it, re-derive the state from `main` + `docs/LOOP-LOG.md` + the plan's "as executed"
   ladder, and fix this file in this run. If Ben's main checkout is dirty, never touch those files; merge `--ff-only`
   still works when the dirty paths are not in your diff.
3. Run G2 once from your worktree before dispatching (3–4 min): the count must equal the STATE block's. Any other
   number is Invariant 10: STOP the task, reconcile, record.
4. `git -C ~/Developer/HectorKit status --porcelain` empty and `log -1` = the HK SHA below (or a later local main that
   a previous run recorded in STATE); a dirty HectorKit checkout is Ben's — do not touch it; use an HK worktree.

## STATE (live, 2026-10-14, written by loop run 12 at its close; head of `main` = run 12's docs-close commit on top of 548019f — read `git log -8 main`)
- **Phase 2 "Ferazel moves" is CLOSED on the machine side** (loop run 7; staged d5586fb → `~/Desktop/Ferazel's Wand.app`).
  **Ben's gate pending: QUESTIONS Q2** (gates queue, D34).
- **Phase 3 "Front end + saves" is UNDER WAY** (plan `docs/plans/2026-10-14-ferazel-phase3.md`, D35 + its "As built
  (loop run 9/10/11/12)" paragraphs). **Waves 3.0–3.3 CLOSED.** Done: X1 256, R1 260, SV1 ⚑ 266 (run 9); SV2 272,
  FE0 ⚑ 278, O1 284 (run 10); L2 289, L1 ⚑ 297 (run 11); **run 12:** RX (83786a7) 297, M1 ⚑ (072bf8b + fix 70384af)
  305, M2 (b79e58e + fix 548019f) 308. Wave 3.3 end gates G3 + G5 green at 548019f.
  **Remaining ladder:** **F1a 313 → D1 317 → F1b ⚑ 323** → S1 ⚑ 330 → P1 335 → C1 ⚑ 342 → C2 345 → A1a ⚑, A1b ⚑ (app, no
  tests) → A2 phase end. Runs: **[F1a D1 F1b]**, [S1 P1], [C1 C2], [A1a A1b], phase end. Q3 = Ben's four choices
  (defaults built unless he answers).
- `Ferazel/Core` suite: **308 passed, 0 failed/skipped**. Census `Totals: items 1,108 decoded, failures 0`. HectorKit
  `~/Developer/HectorKit` main **0c65dcb**, clean, floor **328** (no HK change this phase).
- Worktrees: run 1's dirty `loop-1-20261013-180951` (Q1, unanswered — never delete, never build on), runs 2 and 8's
  `loop-2-20261013-182411` / `loop-8-20261014-142204` (merged; the looper's to remove) are still listed;
  `inspiring-cannon-e97ccd` (deimos-phase2) is Ben's.
- Goldens (unchanged by run 12 except the new one): Phase 1 `9db8f32f7e3d88b4` / `b80b0efd384ffdb9` / pan 30
  `172596fa2f3b6c58` / pan 60 `cc9786ba763d383a` / chain `b4230ba5a643c5b5`; Phase 2 L2 `565e867a02736c18` /
  `df22325e851e782d`, jump `e4f4bf977dd98eaa`, swim `95ff5176412df650`, 600-frame chain `9532d65a42d39666` / cues
  `a875a96c2801dbe9`; Phase 3 main-menu screen `ed142fed9e3bdce7` (FE0), **world map first frame `38563faaa2276f05`**
  (M2, after level 1 seed 1, self-derived); map RNG after entry + 150 flash draws `0x7b052a62` (M1, self-derived).
- **Carries for the next tasks** (full lists in the plan's "⚑ As executed" bullets, L1 l. 781, M1 l. 910, M2 l. 953):
  to **F1b**: compose `LevelRun` (tagged `.level`/`.screen` segments — `GameFlow.tick` keeps them) and `WorldMapRun`
  (init takes `exit1`/`exit2`/`levelComplete`/`sprites:`; reads back `exit1`/`exit2` = −1 — that IS the exit2 global's
  reset, only `ShowWorldMap` resets it (M l. 67561), `LevelEnd` must not treat it per level; `sprites` carried across
  entries, emptied on exit and by `.InitPlayerMapData` (M l. 66610) on a new game; `result == nil` with `quitRequested` on
  the no-node path; a clear level-complete flag or missing Mmap returns 1); `.hideMenuBar` in `.ContinueGame`
  (M l. 6877); the face cache + tileset globals 267d/267e persist across games (`LevelCarry()` starts fresh); `.NewGame`
  writes save +0xc/+0x10; the plan's F1b text that says Continue skips `FadeAIFFMusic(0,4)` is wrong (it is inside
  `.GameLoop`). To **F1a**: `.hideMenuBar` (`.main` M l. 8280, `.MainMenu` 7349) — a hosted session no longer sends it;
  Foundation errors → OSErr −34/−33/−44 for the save-error strings. To **P1**: the map's Caps Lock pause point is a
  `// later: P1` stub in `WorldMapRun.swift`. To **A1a**: route `LevelRunOutput` segments (`.level` → FrameRenderer,
  `.screen` → ScreenRenderer) and `WorldMapOutput` → `MapRenderer`; move the app onto LevelRun (then the non-hosted
  per-iteration cursor path and the three ◇ `.loadLevel`/`.deathEffect` LevelFlowTests go, plan-named); fill
  `FrontInput.capsLock` and the `StageSounds` length table from `SoundBank`; with a shared surface `FrameRenderer` does
  not set the level CLUT at init. To **A1b**: the `.Options` sequence has no Core function; the dialog model works on its
  own copy of live prefs + music. `PutFileRequest {prompt, defaultName, message}` (FE0) for F1b/A1. Unbuilt record
  write-backs for later phases' classes are listed in RX's as-executed bullet (l. 824).
- **Lessons (runs 9–12):** (1) the plan's "digest A–F" were never committed — ground on the bank files + the dump (say so
  in every brief); (2) the plan is wrong against the dump about once per task — the dump wins, the as-executed bullet
  records it (run 12: 5 places in M1, an impossible test geometry in M2); (3) run the seat's own gates from the worktree
  once no agent is building, or from a `git archive` copy with `HECTORKIT_PATH=~/Developer/HectorKit`; (4) `Agent` calls
  return async here — **stay in the turn**: block in ≤10-minute Bash loops that poll the branch head and the agent output
  file's mtime (`stat -L`; idle > 480 s ≈ done; `sleep N; echo` is blocked by a hook — put the sleep inside a loop with a
  condition); (5) independent work runs side by side when files are disjoint (run 12: RX ∥ M1; M1's two review legs ∥ M2's
  implementation; M2 review ∥ M1 fix round; M1 re-review ∥ M2 test fix) — the parallel implementer uses its own
  `swift test --scratch-path`; (6) a fix round that changes behaviour gets a re-review; (7) a fix that moves an existing
  expectation is reverted and becomes a NAMED plan task (Invariant 10); (8) Opus reviewers' mutation runs are the best
  signal — a test-strengthening fix round adds assertions inside the existing test functions so the ladder total holds.

## THIS RUN'S JOB — Phase 3 run 5: **[F1a D1 F1b]** (wave 3.4; one ⚑ MAJOR)
- **F1a — minor — `GameFlow` part 1: boot, title, main menu, Credits timing (→ 313)**, plan l. 967–1009 (5 tests). One
  Opus leg.
- **D1 — minor — the death screen (→ 317)**, plan l. 1010–1033 (4 tests; `TurnGray` maths in Core). One Opus leg. D1 is
  independent of F1a's files — it can run alongside F1a (own `--scratch-path`).
- **F1b — ⚑ MAJOR — `GameFlow` part 2: New Game, the level ⇄ map loop, Continue, death (→ 323)**, plan l. 1034–1092
  (6 tests; composes `LevelRun` + `WorldMapRun` + D1's death screen; mind the carries above). **Two Opus legs.**
- Wave 3.4 end: G3 + G5. Close: plan "⚑ As executed" bullets per task, D35 "As built" paragraph, STATE, memory, this
  file, LOOP-LOG. If the cap allows nothing more after F1a + D1, close with F1b as the next run's first task.

## GATES (fenced; verified on this machine 2026-10-14; G2 308/0, G3, G5 re-run by run 12 at 548019f — copy literally; `$WT` = your worktree)
```sh
WT=$PWD; SCRATCH=$(mktemp -d)
# G1 HectorKit untouched (Phase 3 plan: no HK task); later phases: a local HK main you made + floor ≥ 328 (see AUTHORIZATIONS)
git -C ~/Developer/HectorKit status --porcelain; git -C ~/Developer/HectorKit log --oneline -1      # empty; 0c65dcb
# G2 suite: first number = the ladder total (308 at start; 313 after F1a, 317 after D1, 323 after F1b), second = 0
cd "$WT/Ferazel/Core" && swift test > "$SCRATCH/fz.log" 2>&1; grep -cE "^Test Case '.*' (passed|failed|skipped) \(" "$SCRATCH/fz.log"; grep -cE "^Test Case '.*' (failed|skipped) \(" "$SCRATCH/fz.log"
# G3 census (once per wave end, and whenever Resources/ or a decoder changes): 0 and the Totals line
cd "$WT/Ferazel/Core" && swift build -c release --product ferazel-census > /dev/null && "$(swift build -c release --show-bin-path)/ferazel-census" "$WT/Resources/Ferazel" > "$SCRATCH/census.md"; echo $?; tail -n 1 "$SCRATCH/census.md"   # 0 / Totals: items 1,108 decoded, failures 0
# G5 app builds (every task that touches Ferazel/App or project.yml; always at a wave end): ** BUILD SUCCEEDED **
cd "$WT" && xcodegen generate --quiet && xcodebuild -scheme Ferazel -derivedDataPath "$SCRATCH/dd" build 2>&1 | grep -E "BUILD (SUCCEEDED|FAILED)"   # tail -n 1 prints a blank line
# G6 scope fence: ⊆ the task's Files (+ the DECISIONS / bank file it names)
git -C "$WT" diff --name-only "$TASK_BASE"..HEAD        # TASK_BASE = the commit the task started from
# G7 layering (plan Phase 1 G7): both greps empty, Sources/ferazel-census excluded
grep -rlE '^import (AppKit|CoreGraphics|AVFoundation|Metal|QuartzCore|SwiftUI|UIKit)' "$WT/Ferazel/Core/Sources" | grep -v ferazel-census
# G10 clean tree after every commit: empty
git -C "$WT" status --porcelain | grep -v '^??'
# HK floor (only in a run that changed HectorKit): ends PASS with Executed ≥ 328 — record the new floor in HK + STATE
~/Developer/HectorKit/tools/check-zero-skip.sh | tail -n 3
# G9 staged app boots (phase-end runs only; D34 authorizes the launch). First `bash tools/stage-ferazel.sh` (Release build,
# data copied in, ad-hoc signed → "$WT/out/Ferazel/Ferazel's Wand.app", also ditto'd to ~/Desktop); then: pid line printed
# after 5 s, the second pgrep prints nothing (clean quit), and no new "Ferazel" crash log in the listing
APP="$WT/out/Ferazel/Ferazel's Wand.app"; open -n "$APP"; sleep 5; pgrep -fl "Ferazel's Wand" | cut -c1-100; osascript -e 'tell application "Ferazel'"'"'s Wand" to quit'; sleep 2; pgrep -fl "Ferazel's Wand"; ls -t ~/Library/Logs/DiagnosticReports | head -n 3
```

## AUTHORIZATIONS (Ben, 2026-10-13, AskUserQuestion in the setup session — D34; a loop run inherits nothing else)
- **Scope:** the whole game, phases 2 → 3 → 4 → 5 → 6 → 7 in design §8 order. **Gates queue, they do not block:** at
  each phase end stage the build (`tools/stage-ferazel.sh` → `out/Ferazel/` + `~/Desktop/Ferazel's Wand.app` +
  `WHAT-TO-EXPECT.md`), run G9, write the gate card as a QUESTIONS item ("Ben: play this; pass looks like …"), log the
  LOOP-LOG line, and the NEXT run **plans the next phase**. Ben's later verdict can re-open a phase (his answer in
  QUESTIONS becomes a task). Completion wording stays "machine gates green; Ben's gate pending" — never "plays like
  Ferazel".
- **Phase plans (3–7):** the loop writes each plan when its turn comes (Opus planner, `superpowers:writing-plans`
  shape, contracts not code — `feedback-plans-carry-contracts-not-code`), against the design + the bank + what landed;
  two Opus review legs; **one Fable review leg**; fixes applied; rulings in a new D-number (check `docs/DECISIONS.md` on
  `main` for the next free number — D31 lives on the unmerged `deimos-phase2` branch, so skip it; after D35 the next
  free is **D36**); listed in QUESTIONS for Ben's later read; **execution starts the next run without waiting.**
  A phase plan must carry: its own ladder, gate commands with numbers, the stand-ins it keeps (◇, named), the gate card.
- **Run / stage:** launching the staged `.app` for G9 and replacing `~/Desktop/Ferazel's Wand.app` (+ notes + icon
  previews) at each phase end is authorized. Never delete the prefs domain `com.ambrosiaclassics.ferazel` or any other
  `com.ambrosiaclassics.*`. No notarization, no release packaging, no installs of anything (brew/pip/Xcode components):
  those go to QUESTIONS.
- **HectorKit:** when a phase plan needs a kit change, you may commit to HectorKit's **local** `main` — own HK worktree
  (`git -C ~/Developer/HectorKit worktree add …`), `tools/check-zero-skip.sh` floor may only rise (bump `FLOOR` in the
  same commit), an HK D-number in `~/Developer/HectorKit/docs/DECISIONS.md`, Classics STATE pins the new HK SHA; merge
  to HK local main `--ff-only`; never push HK either. Keep HectorKit Foundation-only in its core modules (HK D6).
- **Merge:** when every gate of the run is green, `git -C "$REPO" merge --ff-only <your branch>` (rebase onto `main`
  in your worktree first if it moved); `--no-ff` only when the plan's wave-close convention asks for it.
- **Windows (Phase 7)** follows the BTX W-plan shape (D15–D21, `tools/windows/`); the zip is staged, his brother's test
  and the notarized Mac DMG are QUESTIONS (credentials, remote) → when nothing on the ladder can proceed without Ben,
  write `STATUS: BLOCKED` with the list. **Never write `STATUS: DONE` yourself** — DONE is Ben's word.

## NEVER (hazards; each with the safe alternative)
- Never `git push` / `git fetch` / `gh` / any remote; never `git add -A` or `.` (explicit paths); never `git stash`
  (WIP commit instead); never check out, reset, or edit files in Ben's main checkout at `$REPO` (only `merge --ff-only`
  there); never force-anything; never delete a branch or worktree that is not yours.
- Never edit the originals under `Resources/Ferazel/` or the dumps under `ghidra/ferazel/` (regenerate only via
  `ghidra/regen-ferazel.sh`, and this phase never needs to); never hand-edit `AmbrosiaClassics.xcodeproj`
  (`project.yml` is truth, `xcodegen generate`); never touch `~/Developer/Ambrosia`, `~/Developer/Ghidra`,
  `~/Developer/Toolkits` (read-only oracles and method).
- Never edit a golden or an expectation to make a number agree (Invariant 10 — STOP, reconcile, record); the dump beats
  the bank (Ben: "follow the binary"), and a correction is appended to the bank file by the task that relies on it.
- Never add a modern affordance (coyote time, jump buffer, smoothing, collision "fixes", audio normalisation —
  Invariant 7); never "simplify" a named later-phase stub away (Invariant 6).
- Never build Aki / AkiPad / BubbleTroubleX / Deimos / Cythera for a Ferazel-only task (only when `project.yml`,
  HectorKit, or shared Resources change — then build them all); never run `tools/package-*-release.sh`.
- Never let a file that is git-ignored into git by editing `.gitignore` (`/Resources/*` except the three games, `out/`,
  `releases/`, `.build/`, `STOP`, `.looper/logs/`, `hd-4x`); never commit `~/Desktop` paths or scratch logs.
- Never spawn a chip (`spawn_task`), never `EnterWorktree` (you are in one; a session cannot make a second Classics
  worktree — HectorKit worktrees are fine), never `AskUserQuestion` (disabled; use QUESTIONS.md), never use the
  `Workflow` tool; never edit `.looper/config.sh`, the kit under `~/Developer/Toolkits`, or any `~/.claude` settings.
- Traps: `Ferazel/FerazelCore` is a symlink to `Core` (SwiftPM package naming, D13.8); the app name has an apostrophe —
  quote every path; from a worktree HectorKit resolves through the `.claude/worktrees/HectorKit` symlink
  (`HECTORKIT_PATH` overrides); Swift `>>` binds tighter than `&*` (F2 review bug); the bank's wave-1 "handler dump l. N"
  numbers drift — use M lines / raw addresses from the plan; `swift test` prints two "Executed" lines; parallel lanes in
  one worktree need their own `swift test --scratch-path`; agents cannot screenshot on this machine; a reviewer builds
  in a `mktemp` archive, not in your worktree.

## CLOSE (every run, in this order; never start a new task at the cap)
1. Finish the in-flight task (merge what is green; an unfinished task's branch stays, say so).
2. **As-built docs:** the plan's task section gets an "As executed" note (ladder numbers, deviations, bank corrections
   landed); `docs/DECISIONS.md` D33 (or the phase's D-number) "As built" paragraph; `docs/STATE.md` Ferazel bullet
   updated (small by rule — replace, don't append history); the gate card / WHAT-TO-EXPECT only in phase-end runs.
3. **Memory:** one file in `~/.claude/projects/-Users-andiyar-Developer-Ambrosia-Classics/memory/` (project type, what
   landed, SHAs, counts, what the next run must know) + one index line in `MEMORY.md` there.
4. **Rewrite this file** completely for the next run: first line `STATUS: CONTINUE` (or `STATUS: BLOCKED` with the
   QUESTIONS item that blocks); STATE block with the new `main` SHA (the one your merge will produce — verify after the
   merge and amend if needed), test counts, HK SHA/floor, ladder position; THIS RUN'S JOB = the next unit (2 tasks, or
   the phase-end run, or the planning run) grounded to plan lines and file:line; GATES with the next expected numbers;
   AUTHORIZATIONS and NEVER carried verbatim unless Ben changed them in QUESTIONS.
5. **One line in `docs/LOOP-LOG.md`** (the line format in its header: date | run N | what landed | gates | boots |
   merged SHA).
6. QUESTIONS: add any item Ben must decide (the item shape in its header: Context / Options / Recommendation /
   Blocks / Answer:); move answered items you acted on to "Answered".
7. Commit the docs (explicit paths), G10 clean, **merge `--ff-only` into `main` at `$REPO`**, confirm
   `git -C "$REPO" log --oneline -1` is your commit. The looper removes your worktree and branch once merged.
8. **No chips, no handoff file, no closing offers.** Your last message: what landed, what review caught, what the next
   run does — plain English, for a reader who did not see this run.
