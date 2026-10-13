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
   **D32** (Phase 1 gate), **D33** (Phase 2 rulings + as-built waves 2.0–2.3), **D34** (the loop's authorizations).
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

## STATE (live, 2026-10-14, written by loop run 4 at its close; head of `main` = run 4's docs-close commit on top of f68f170 — read `git log -8 main`)
- Loop run 4 built **W2b + W3 + W4** and merged them (wave 2.3 CLOSED): `ea28448` W2b, `f2f3239` W2b review fixes,
  `2f986d7` W3, `f3b089d` W3 review fixes, `0f7dd62` W4, `f68f170` W4 review fixes, then the docs close. Run 1's dirty
  worktree `loop-1-20261013-180951` is still there (Q1, unanswered): not yours — never delete it, never build on it.
  Run 2's worktree `loop-2-20261013-182411` (9136a70, already merged) is also still listed — not yours.
- `Ferazel/Core` suite: **234 passed, 0 failed/skipped** (G2 grep). Census `Totals: items 1,108 decoded, failures 0`,
  exit 0. Ferazel app: BUILD SUCCEEDED. HectorKit `~/Developer/HectorKit` main **0c65dcb**, clean, floor **328**.
- Phase 2 plan position: waves 2.0–2.3 MERGED (as-built in D33 "As built (wave 2.3, second part …)" and each task's
  "⚑ As executed" bullet, plan l. 907 / 945 / 1004). **Next = wave 2.4: E1a, E1b (both ⚑ MAJOR), then S1 (minor).**
  Ladder as executed: … W2a 215, W2b 220, W3 228, W4 **234** now; E1a (+5) → **239**, E1b (+3) → **242**, S1 (+7) →
  **249**, GD (+4) → **253**; then A3 (⚑, app), A4 (stage + gate card) — "previous total + the task's N" (the plan's own
  "→ N" headers are stale).
- Goldens today (P5 moved the pan pair; W1–W4 moved none): `testFirstFrameGoldenLevel1`
  `9db8f32f7e3d88b4`, `…HighestTieBreak` `b80b0efd384ffdb9`, pan frame 30 `172596fa2f3b6c58`, frame 60
  `cc9786ba763d383a`, chain `b4230ba5a643c5b5`. Only ◈ tasks (E1b, GD; E1a only if a splash enters a golden — none
  expected) may move one, in-commit, old → new + reason.
- What wave 2.3 established (read the W2b/W3/W4 "⚑ As executed" bullets): a level-2 session now builds (L2 starts 33
  active / 196 idle — stalactite children made at Setup; 212 records, 40 spokes + 4 siblings after frame 1);
  `LevelFlow` + `ShellRequest.loadLevel(Int)` / `.deathEffect` exist with no-op app arms (A3 wires them);
  `LevelCarry` (`session.carry` → `init(…carry:)`) carries the parity always and, on an **exit**, the whole G (only
  `_NewGame` inits G — the plan was corrected); death → fresh G (Ben D33 ◇). Passages emit `DrawOp.gammaStep` (21
  iterations per fade). Cannon launches make 415 FastRand draws (smoke sprites; their particles are `// later: E1a`).
  NPCs are never solid. Box push/fall is Phase 4 (crates rest 2–6 px off the binary's settle — a gate-card note for A4).
- Carries into wave 2.4: **E1a**: `.ExplodeFaceIntoParticles` / `.ParticleGlow` unbuilt; fill `HurtPlayer.bloodSpray`
  (`.BloodSpray @100549f4`, 40 particles); W2b's cannon smoke `// later: E1a` stubs (smoke particles) live in
  `World/Movers/BackgroundSprite.swift` / `Player/GroundCeilingEffects.swift`; the RNG drifts from the first pendulum hit
  until E1a and the Phase-4 coin spawn land; P3's `+0x1a8 = 0x10` → `.StandardSpriteCleanup` → `.ParticleGlow` (draws
  FastRand). **E1b**: water-face parity reads `_DAT_1009fd30` (flipped on drawn iterations only; carried across levels by
  `LevelCarry`). **S1**: P4's material-2 stop is a `PlayerCue .stopIfPlaying` (reconcile with `soundStops`); 508 via
  `.regPitched`; W4: the music fade `.FadeAIFFMusic` + the sound stops after the loop (M l. 5296–5304) are not emitted
  (S1 or A3 owns them — S1 decides, records it); the exit cue 421 is plain `STPlayRegSound`. **E2/0148**: mode 0xb not
  reachable on L1/L2. **A3**: `FrameRenderer.setTile` re-parses the level per op; the suite never renders L2 (a W4
  reviewer's 5-frame probe did) — A3/GD should. Open, unowned: M6 (Bonus guard `p1Negative: false`), M7
  (`TileHotRects.init(level:)` reads `level` beside `world.tiles`); `200..<210` literals in `SetupFaces.swift` /
  `PlayerTiles.swift` (could use `UnderWater.isWaterTile`) — fix when a task touches them.

## THIS RUN'S JOB — wave 2.4: **E1a** (⚑ MAJOR → two Opus legs), then **E1b** (⚑ MAJOR ◈ → two Opus legs)
Plan sections: **E1a** "#### E1a" (≈ l. 1028–1048), **E1b** "#### E1b" (≈ l. 1050–1063); read each in full plus the
Invariants (l. 123–172, esp. 3 — the parity flip position and drawn-vs-skipped iterations — and 4 — one RNG stream) and
Shared architecture S3 (`DrawOp` cases `wrapDrawWaterEffects`, `drawParticles`, `eraseParticles`).
- **E1a**: Files + 5 tests as the plan; G2 → **239 / 0**; G5 (touches FerazelRender). The exhaustive `switch op` in
  `SessionTests` (l. 183–193) and `testFirstFrameOpsOrder` (l. 149) change because three `DrawOp` cases are added —
  that is expected by the plan, not an Invariant-10 event; any OTHER count/golden moving is.
- **E1b**: Files + 3 tests; G2 → **242 / 0**; G5; ◈ level-1 goldens are predicted to move (motes, acid bubbles, water
  faces on parity frames) — record old → new + reason in-commit; verify the cause by revert (no water effects → old
  hashes return). If they do NOT move, rule as run 3 did for W1 (find out why, record it).
- Unit size: two ⚑ MAJOR tasks = the chip's unit. Do not start S1 in this run. If your own context passes ~170k after
  E1a merges, close with E1b as the next run's first task.
- Per task: brief the implementer per orchestrator §3 with the full scene (the planner's probes/digests were NEVER
  committed: the plan's numbers are the targets; the dump is the authority — "M l. N" = line N of
  `ghidra/ferazel/Ferazel_pef.decompiled.c`, raw addresses in `ghidra/ferazel/Ferazel_pef.disasm.txt`). **Dispatch every
  subagent with `run_in_background: false`**; see the HAZARD below. Insist on tests FIRST, seen failing (run 4's W2b and
  W4 implementers wrote code first). Run the gates yourself from the merge head and never relay a subagent's number.
  Review legs must RUN the suite and try ≥ 20 targeted mutations (run 4: W2b 133 mutants / 12 real survivors, W3 60/7,
  W4 52/4 — ask implementers to pin every branch with exact values up front). Ask the fidelity leg to read the dump
  for anything the plan does not mention that L1/L2 reach (run 4's W4 leg found the globals-carry bug that way). Then
  one implementer fix round; **if the fix round changes behaviour (not only asserts), one short Opus re-review leg of
  it**. Re-run G2 and commit with explicit paths. STOP on any number the plan did not predict (Invariant 10). Precedent
  rulings (runs 2–4): when real rows replace a stub, or the binary creates sprites the plan's counts did not include,
  counts may move — rule under "follow the binary", verify the cause by trace (revert the cause → old numbers return),
  record old → new. Where the dump contradicts the plan, the dump wins; record it in the As-executed bullet. Never let a
  kinematic number move silently.
- Merge each task's green commits to `main` (`--ff-only`) as soon as its gates pass, so a cap or a crash later in the
  run loses nothing.

### HAZARD — headless session (learned run 1, 2026-10-13)
The looper runs you with `claude -p`: **when you end your turn, the session exits and every background subagent or
background shell is killed.** Run 1 ended its turn "waiting on the implementer" and lost the whole run. Always pass
`run_in_background: false` to the Agent tool and never `run_in_background: true` on Bash. Independent calls (a review
leg and your own G2 run) can go in the same message: they run in parallel and both return before you continue. Do not
use SendMessage to resume a finished agent: it may return asynchronously. Dispatch a fresh implementer with the full
context instead (run 2 did this for every fix round).

## GATES (fenced; verified on this machine 2026-10-14 from f68f170 (run 4) — copy literally; `$WT` = your worktree)
```sh
WT=$PWD; SCRATCH=$(mktemp -d)
# G1 HectorKit untouched (Phase 2); later phases: a local HK main you made + floor ≥ 328 (see AUTHORIZATIONS)
git -C ~/Developer/HectorKit status --porcelain; git -C ~/Developer/HectorKit log --oneline -1      # empty; 0c65dcb
# G2 suite: first number = the ladder total (234 today; E1a 239; E1b 242; S1 249; GD 253), second = 0
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
