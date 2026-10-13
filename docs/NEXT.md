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
   authorization for exactly what it says; record it in DECISIONS).
2. `CLAUDE.md`; `docs/STATE.md` (whole file); `docs/DECISIONS.md` **D26** (Ferazel design rulings, as-built C0…A2),
   **D32** (Phase 1 gate), **D33** (Phase 2 rulings + as-built waves 2.0, 2.1), **D34** (the loop's authorizations).
3. `docs/plans/2026-10-10-ferazel-phase2.md` — "Verification model" (lines 66–121), "Non-negotiable invariants" +
   "Hazards" (123–182), "Shared architecture" (184–278), then ONLY the task sections this run executes (below).
4. `docs/plans/2026-10-06-ferazel-design.md` §1, §2, §8 (what "done" means; the phase table; oracles).
5. The bank files each task names (`docs/ferazel/…`), then the dump ranges it names (`ghidra/ferazel/`).

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

## STATE (live, 2026-10-13, written by loop run 3 at its close; head of `main` = run 3's docs-close commit on top of af15839 — read `git log -6 main`)
- Loop run 3 built **W1 + W2a** and merged them: `b481ebe` W1, `710c689` W1 review fixes, `dce1871` W2a, `af15839` W2a
  review fixes, then the docs close. Run 1's dirty worktree `loop-1-20261013-180951` is still there (Q1, unanswered):
  not yours — never delete it, never build on it.
- `Ferazel/Core` suite: **215 passed, 0 failed/skipped** (G2 grep). Census `Totals: items 1,108 decoded, failures 0`,
  exit 0. Ferazel app: BUILD SUCCEEDED. HectorKit `~/Developer/HectorKit` main **0c65dcb**, clean, floor **328**.
- Phase 2 plan position: waves 2.0–2.2 MERGED; wave 2.3 **W1, W2a MERGED** (as-built in D33 "As built (wave 2.3, first
  part)" and each task's "⚑ As executed" bullet). **Next = W2b, W3, then W4 (closes wave 2.3).** Ladder as executed:
  … P5 203, W1 211, W2a **215** now; W2b (+5) → **220**, W3 (+8) → **228**, W4 (+6) → **234**, E1a (+5) → 239, E1b (+3)
  → 242, S1 (+7) → 249, GD (+4) → 253 ("previous total + the task's N").
- Goldens today (unchanged by W1/W2a): `testFirstFrameGoldenLevel1` `9db8f32f7e3d88b4`, `…HighestTieBreak`
  `b80b0efd384ffdb9`, pan frame 30 `172596fa2f3b6c58`, frame 60 `cc9786ba763d383a`, chain `b4230ba5a643c5b5`. Only ◈
  tasks (E1b, GD; E1a conditionally) may move one, in-commit, old → new + reason. W2b/W3/W4 are not ◈.
- What W1/W2a established (read the two "⚑ As executed" bullets, plan ≈ l. 823–870 and after W2a's commit line):
  platforms are created active and faceless (`+0xc0 = 0`) until their first Handle; the stored radial centre is 0
  until then (the L1 wheel's frame-1 bounce is real, pinned); `.ActiveToIdleSprite` leaves the record listed with
  `handleCleared` and `SpriteWorld.updateSprites` kills it at step end; physics reads `record(id:)`; mace chains (1434)
  are made inside `.SetupBackgroundSprite` (level-1 start list = 38); `.HurtPlayer` exists (attacker gate: EnemyShot/Box
  exempt; coins `FastRand(3)+4` capped, recorded in `PlayerState.coinsLost`); seams `HurtPlayer.bloodSpray` (E1a) and
  `PlayerCue.Call.regPitched` (S1, cue 508). A level-2 **session** cannot be built until W4 (Setup of type 2848 throws).
- Carries: **W2b**: its `testBackgroundRecordDefaultsWrittenBack` (p2 0 → 140, p3 0 → 30) is already asserted inside
  W2a's `testPendulumDoubleHandleFrames` — still write W2b's own test (ladder +5), on a W2b type if one has the
  defaults, and say so. Passages emit `DrawOp.gammaStep`; cannons' smoke Effect sprites draw FastRand. **W3**: Box arm
  of `.HitPlayerSprite` sits in `Player/HitPlayerSprite.swift` beside W1's Platform and W2a's Background arms; the
  attacker gate already exempts Box. **W4**: `SpriteWorld.playerDead` (`_DAT_1009ffa8`) is set only after the game loop
  exits (l. 5303); the parity and the crunch log must survive level loads; the L2 counts the plan names (212 active, 40
  spokes + 4 siblings) are measured with W1's spokes created in the first Handle and W2a's chains at Setup — if they
  differ, trace before ruling. **E1a**: `.ExplodeFaceIntoParticles` / `.ParticleGlow` unbuilt; fill
  `HurtPlayer.bloodSpray`; the RNG drifts from the first pendulum hit until E1a and the Phase-4 coin spawn land.
  **S1**: P4's material-2 stop is a `PlayerCue .stopIfPlaying` (reconcile with `soundStops`); 508 via `.regPitched`.
  **E2/0148**: mode 0xb is not reachable through the L2 raft light path; still written directly by crumble/blink/floe
  platforms, spirit form, Bonus, Effect, shots (none placed on L1/L2). **A3**: `FrameRenderer.setTile` re-parses the
  level per op. Open, unowned: M6 (Bonus guard `p1Negative: false`), M7 (`TileHotRects.init(level:)` reads `level`
  beside `world.tiles`) — fix when a task touches them.

## THIS RUN'S JOB — wave 2.3 continued: **W2b** (⚑ MAJOR → two Opus legs), **W3** (minor → one leg), then **W4** (minor → one leg) if the cap allows
Plan sections: **W2b** "#### W2b" (≈ l. 870–890 after W1/W2a's As-executed bullets; grep `^#### W2b`), **W3**
"#### W3", **W4** "#### W4" (incl. its Precondition: enumerate every FastRand site in the L2 new types' Setups into the
W4 ⚑ note before coding). Read each in full with its carries, plus W1/W2a's "As executed" bullets.
- **W2b**: Files + 5 tests as the plan; G2 → **220 / 0**; G5 (FrameRenderer sheets 3000+, 2700+).
- **W3**: Files + 8 tests; G2 → **228 / 0**.
- **W4**: Files + 6 tests; G2 → **234 / 0**; G5 (touches `Ferazel/App`); G3 census at the wave end. W4 closes wave 2.3
  — after it, the D33 "As built (wave 2.3)" paragraph is completed.
- Unit size: three tasks with one MAJOR is the chip's maximum. Do W2b, then W3; start W4 only if your own context is
  under ~170k after W3 merges; otherwise close with W4 as the next run's first task.
- Per task: brief the implementer per orchestrator §3 with the full scene (the planner's probes/digests were NEVER
  committed: the plan's numbers are the targets; the dump is the authority). **Dispatch every subagent with
  `run_in_background: false`**; see the HAZARD below. Run the gates yourself from the merge head and never relay a
  subagent's number. Review legs must RUN the suite and try ≥ 20 targeted mutations (run 3: W1 26/67 and W2a 10/62
  survivors before the fix rounds — ask implementers to pin every branch with exact values up front). Then one
  implementer fix round; **if the fix round changes behaviour (not only asserts), one short Opus re-review leg of it**.
  Re-run G2 and commit with explicit paths. STOP on any number the plan did not predict (Invariant 10). Precedent
  rulings (runs 2–3): when real rows replace a stub, or the binary creates sprites the plan's counts did not include
  (W2a's Setup-time chains), counts may move — rule under "follow the binary", verify the cause by trace (revert the
  cause → old numbers return), record old → new. Where the dump contradicts the plan (W2a: the attacker gate, the
  coin draw), the dump wins; record it in the As-executed bullet. Never let a kinematic number move silently.
- Merge each task's green commits to `main` (`--ff-only`) as soon as its gates pass (run 3 did this), so a cap or a
  crash later in the run loses nothing.

### HAZARD — headless session (learned run 1, 2026-10-13)
The looper runs you with `claude -p`: **when you end your turn, the session exits and every background subagent or
background shell is killed.** Run 1 ended its turn "waiting on the implementer" and lost the whole run. Always pass
`run_in_background: false` to the Agent tool and never `run_in_background: true` on Bash. Independent calls (a review
leg and your own G2 run) can go in the same message: they run in parallel and both return before you continue. Do not
use SendMessage to resume a finished agent: it may return asynchronously. Dispatch a fresh implementer with the full
context instead (run 2 did this for every fix round).

## GATES (fenced; verified on this machine 2026-10-13 from af15839 (run 3) — copy literally; `$WT` = your worktree)
```sh
WT=$PWD; SCRATCH=$(mktemp -d)
# G1 HectorKit untouched (Phase 2); later phases: a local HK main you made + floor ≥ 328 (see AUTHORIZATIONS)
git -C ~/Developer/HectorKit status --porcelain; git -C ~/Developer/HectorKit log --oneline -1      # empty; 0c65dcb
# G2 suite: first number = the ladder total (215 today; W2b 220; W3 228; W4 234), second = 0
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
  `main` for the next free number — D31 lives on the unmerged `deimos-phase2` branch, so skip it; after D34 the next
  free is **D35**); listed in QUESTIONS for Ben's later read; **execution starts the next run without waiting.**
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
