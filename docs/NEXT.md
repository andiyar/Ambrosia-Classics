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
   authorization for exactly what it says; record it in DECISIONS). **Open: none** (run 26 moved Q5 and Q7 to Answered:
   D40 — Q5 became task QT, this run's first job; Q7 = the plan's defaults stand). **Ben's later notes on the text** (Q8:
   if the smoothed modern Times still looks off against the Let's Play, bundle classic Times/Geneva — allowed, D39) become
   a task the same way (plan it first as a named wave). Ben may commit to `main` mid-run (runs 25 and 26 both saw it):
   rebase onto `main` before each merge and re-run G2.
2. `CLAUDE.md`; `docs/STATE.md` (whole file); `docs/DECISIONS.md` **D26** (the Ferazel design ruling), **D33** (Phase 2
   as built), **D34** (the loop's authorizations), **D35** (Phase 3 rulings + as built), **D37** (Ferazel controller),
   **D38** (Phase 4 rulings — the plan's "Rulings" section is the full text), **D40** (Ben's Q5 + Q7 answers — QT's why).
3. **The plan: `docs/plans/2026-10-24-ferazel-phase4.md`** — read "Verification model" (l. 78, gates G1–G10 incl. G7b
   and G8, and the run-21 ladder-shift note at l. ~119), "Non-negotiable invariants" + "Hazards" (l. 154, 195), "Shared
   architecture LOCKED" (l. 222), then your tasks (QT l. ~1105 — written by run 26 from Ben's Q5 answer; BX2 l. ~1137; BT l. ~1172) and the run-26 ladder-shift note (l. ~119), "Execution order" (l. ~1409), "Stand-ins kept (◇)" (l. ~1447),
   "Bank corrections to append" (l. ~1543) and "Rulings" (l. ~1642). Read the "As executed" notes of waves 4.0–4.6 (X1,
   VS, LT, US, IV, HU, TB, BN, PK, TX, EF, CS, SH, GL, PU, IU, MS, SD, BX1 — grep `As executed (`) — they change seams you will use (`killCount`/write-back flags,
   `addItem` returns the slot, `StatusBarCalls` + the flow-wide status-bar globals, `BonusSprite`, `Outcome.upgrade`,
   `PlayerState.passRequests`, `fadeOut` returning whether it armed, IU's `.hint` suspension + resumable handle pass `continueHandlePass` + `suspendedInNestedPass`, MS's halfword spirit timer, SD's `PlayerState.shadowRing` + `LevelCarry.shadowMirrors`, BX1's `boxPairLatch`, the Box tail in `BoxSprite.handle` and its unbuilt-arm early return after the latch clear). The design `docs/plans/2026-10-06-ferazel-design.md`
   §8 row 4 is the scope; the Phase 3 plan is history.
4. The bank: `docs/ferazel/INDEX.md` then only the topical files your tasks cite; the decompile `ghidra/ferazel/` (the
   dump beats the bank: "follow the binary"; Phase 3's "digest A–F" files were never committed — the Phase 4 plan is
   grounded on the bank + the dump + the planner's census scripts (not committed); say so in every brief). **Every
   brief must tell the implementer to re-read each cited M line in the committed dump before coding** — the plan is
   wrong against the dump about once per task; the dump wins and the task's "As executed" note records it.

## RECONCILE FIRST (before any dispatch — the chip can be stale)
1. `git -C "$REPO" worktree list` and `git -C "$REPO" branch --list 'loop/*'`: a leftover `loop-*` worktree or branch
   means an earlier run did not merge. Read its log; if its commits pass the gates, rebase them onto `main` in YOUR
   worktree (cherry-pick), re-run G2, continue from there; otherwise record it in LOOP-LOG + QUESTIONS and start from
   `main`. Never delete another run's worktree or branch.
2. `git -C "$REPO" log --oneline -8 main` and `git -C "$REPO" status --porcelain`: the STATE block below must name
   main's head. If main moved past it, re-derive the state from `main` + `docs/LOOP-LOG.md` + the plan's "as executed"
   ladder, and fix this file in this run. If Ben's main checkout is dirty, never touch those files; merge `--ff-only`
   still works when the dirty paths are not in your diff.
3. Run G2 once from your worktree before dispatching (3–5 min): the count must equal the STATE block's. Any other
   number is Invariant 10: STOP, reconcile, record.
4. `git -C ~/Developer/HectorKit status --porcelain` empty and `log -1` = the HK SHA below (**35a85ba**, or a later local
   main that a previous run or Ben recorded in STATE); a dirty HectorKit checkout is Ben's — do not touch it; use an HK
   worktree.

## STATE (live, 2026-10-26, written by loop run 26 at its close; head of `main` = run 26's docs-close commit on top of d6958e2 — read `git log -8 main`)
- **Phases 2 and 3 PASSED WITH NOTES by Ben (2026-10-25, D39).** His notes became wave 4.2F (done by loop run 22). Q9
  (keep the speed, D39 addendum), Q5 + Q7 (D40) answered 2026-10-26.
- **Phase 3 "Front end + saves" CLOSED on the machine side** (loop run 17). Staged build **3553392** at
  `~/Desktop/Ferazel's Wand.app` + `~/Desktop/Ferazel's Wand — WHAT-TO-EXPECT.md` (Ben played it — Q6 answered).
- **Phase 4 "Spells + items" UNDER WAY** (plan `docs/plans/2026-10-24-ferazel-phase4.md`; D38 + its "As built — wave
  4.0 … 4.6" + D39 "As built — wave 4.2F" + D40): 24 tasks + the seat-inserted TB + wave 4.2F (TX, SP) + wave 4.6Q (QT)
  + phase end A4. **Ladder 349 → 490** (plan l. ~119: +6 from EF, +3 more from BX2 for QT). `BuiltLevels` widens to 1...3 at
  LV3 and 1...4 at LV4. Waves 4.0 → 357, 4.1 → 374, 4.2 → 393, 4.2F → 396, 4.3 → 412, 4.4 → 431, 4.5 → 444.
  **Wave 4.6 DONE (loop run 26):** SD 9b1693f + fb41893 (`Player/ShadowDouble.swift`, `Player/Pentashield.swift`; the
  real 14-entry pose ring `PlayerState.shadowRing`, its mirror bytes ride `LevelCarry.shadowMirrors`) → 449; BX1 5f4928b +
  d6958e2 (the Box tail and arms in `World/Movers/BoxSprite.swift`, `.KillCrate`, the spin stomp in `HitPlayerSprite.swift`,
  `SpriteSlot.boxPairLatch`; no golden moved — no Box is awake on the golden routes) → **457**.
- `Ferazel/Core` suite: **457 passed, 0 failed/skipped** (run 26, seat-run from the rebased merge head d6958e2). Census `Totals: items
  1,108 decoded, failures 0`. Ferazel BUILD SUCCEEDED. HectorKit `~/Developer/HectorKit` main **35a85ba**, clean, floor **361**.
- Worktrees: `inspiring-cannon-e97ccd` (deimos-phase2) and `~/Developer/gamepad-wt/Ambrosia-Classics` (branch
  `gamepad`, merged) are Ben's — never touch. Earlier runs' worktrees are the looper's to remove.
- **Goldens (current, after wave 4.6 — it moved none):** Phase 1 `9db8f32f7e3d88b4` / `b80b0efd384ffdb9` / pan 30 `b1f4efcf3c34735f` / pan 60
  `80d88efdc8fac27c` / chain `aaab15c0710cbcf7`; Phase 2 L2 `565e867a02736c18` / `df22325e851e782d`, jump `deb577ecdeb64c58`,
  swim `c1dd428a3f146d77` (particles [67,321]), 600-frame `a8dda9cf3e448016` / cues `28a48762cfff1b2b` (cue words 3114, seed
  1574122804, particles 156); Phase 3 FE0 `ed142fed9e3bdce7`, map first frame `38563faaa2276f05`, map RNG `0x7b052a62`, sign
  frame `c8e41941c1e4d6da`. **Only BX2 (◈) may move a golden from here**, recording old → new and the cause,
  the reviewer confirming the cause by switching it off (the method that worked in run 21).
- **Carried minor follow-ups (not adopted, D38 Ruling 15 — left to Ben's Q6 verdict):** report fade-in when faded (M l. 35448)
  unbuilt; a second queued main-menu pick dropped; boot bar jumps; music decoded on play; `.savePoint(saved:)` carries no
  polled input after the save dialog; `SavedGameFile.writeErrorReport` code typed optional; `CoreTextRasterizer` widths
  untested; `FerazelController.fail()` exits with only an NSLog; the save panel's field label repeats the prompt. **Runs
  19–20 carries:** `SeparateFromTiles.swift:109` names landed tasks (relabel when touched); the app's `SoundTool` "unloaded"
  rule + `isPlaying`/`playingSounds` lack the nil-handle-counts-all rule; `GroundCeilingEffects.swift:207` builds a lookup
  per smoke frame; `SpriteWorld.valid()` extra bound; the Px strip `+0xea`; conversation action 2's `0bf4`/`0bf0` stores
  unwired; the status bar's source-clip model untested [MED]; Render's text caches per renderer. **Run 21 carries:** TB's
  test fixture uses one face in every parallax cell slot and assumes rowBytes 128; several `BonusSprite.swift` cites run ~20
  lines short of the dump; a Core-only session with no faces skips the Xichron burst's draws quietly; a 1058 with p1 out of
  range is dropped where the binary writes past the end; `BonusSprite` 0xc25 and 0xc9b…0xcb0 still `notTranscribed` —
  **recheck at LV3/LV4**.
- **Run 23 carries:** the Continue route's level carry is untested; the 1090 cannon smoke's Setup exists twice
  (`BackgroundSprite.swift:~737` and `EffectSprite`); Core never reuses sprite records (followers never alias a reused record);
  the "no free record" error report is not modelled; `noCastBegan`/`wandHeld` are the plan's `castBegan`/`wandHold`;
  `rideRamp` doubles as the Shadow Double history index (SD).
- **Run 24 carries:** a shot whose side of a torch contact runs first is killed twice (two sounds, two effects — the
  binary's collide loop has no dead check, built as written); the stale r29 at the sprite-hit and tile-hit sites changes no
  light [LOW]; the crunch strength is passed as 8 bits where the binary passes 16 (always 1) [LOW]; the dump clears the
  Shadow Double flag in two state-selection branches (M l. 45410, 45478) — **SD's**; the trail's 0xb000x tints are not
  checked by eye; SW owns the Statue arm of `.HitPlayerShotSprite` and BX1 the crate arm's r29 (seat notes in their plan sections).
- **Run 25 carries:** the Magical Shield's crouch face is still a stub that treats the shield as absent; with slot −1 (empty
  inventory) the binary's move-to-front copies the empty slot's raw words into slot 0 — not modelled [LOW]; two
  health-potion loops in `ItemUseTests` are unbounded; the resumed player's map-redraw ops are unpinned (the next Handle's
  cleanup flushes them); Smite computes the inert Phase-1 enemies' centre from the hot rect (`// later: Phase 5`); MS: the
  Blob-attacker exception of the crystal shards is Phase 5's; the forced-death flag `0568` is always 0.
- **Run 26 carries:** a New Game builds a fresh `LevelCarry`, so the Shadow Double ring's mirror bytes reset there where the
  original keeps them until the app quits [LOW]; the Bat 0x6cc crate-drop arm is unreachable until Phase 5 builds non-Bonus
  drops; unbuilt Box arms skip `.StandardSpriteHandles` until their tasks (BX2/BT/SW); a stomped switch block only loses HP
  until BT builds its Handle; stale `// later: Phase 4` at `HitPlayerSprite.swift` ~l. 180, 815, 851, 889 (A4's sweep); a
  crate with no placement record reads p4 as 0 [LOW]; `BonusSprite` 0xc25 / 0xc9b…0xcb0 still `notTranscribed` (no crate
  on levels 1–4 drops them — recheck at LV3/LV4); `BonusSprite.sheets` names PICTs 3109/3200 the data lacks (not drawn).
- **Run 22 carries:** the smoothing mix is linear with no gamma and the 14 pt threshold is read from the LP, both [MED];
  the LP's Times still looks a little heavier and ~5 % wider than today's system Times (D39 allows bundling classic Times if
  Ben asks); SP left the level-start pan, the load bar and walk distance per step unmeasured [LOW].
- **Lessons (runs 9–21, 22):** (1) ground on the bank + the dump; (2) the plan is wrong against the dump about once per task —
  the dump wins, the as-executed bullet records it; (3) run the seat's own gates from the worktree once no agent is
  building; (4) foreground `Agent` calls return the report directly — two review legs in one message run in parallel in
  `git archive` temp copies; (5) a fix round that changes behaviour gets a re-review; a tests-only or tiny round the seat
  reads itself; (6) reviewers' mutation runs are the best signal — strengthen inside existing test functions so the ladder
  holds; (7) check `FerazelSession.swift`'s switch, `SessionTests.swift`, `ScreenRenderer.swift` and the FrameRenderer sheet
  table whenever a task adds a case or a spawnable type; (8) merge each green task to main before starting the next; (9)
  AppKit: never leave a `.terminateLater` pending across play; (10) tell Fable reviewers "no background agents"; (11) read
  each layout/flow table against its ruling's why; (12) a resumed subagent (SendMessage) runs in the background — stay in
  the turn until its notice arrives; (13) **reviewers keep making the `~/Developer/HectorKit/HectorKit` self-link (again in
  run 21, mtime during the run) — check G1 with `git -C ~/Developer/HectorKit status --porcelain` at the close and `rm` only
  that symlink (`[ -L … ]`) if this run's agents made it**; (14) fix rounds driven by a mutation table work well; (15)
  audit the dump for every writer of a newly-read field; (16) accept a whole-struct expectation edit only after reading the
  diff; (17) check each "not built" item against the task's M lines; (18) **run 21: when an implementer is BLOCKED by a gap
  no task owns (mode 0xb), park its work as a WIP commit on a side branch, rewind, insert a small task for the gap first,
  then cherry-pick the parked work and have a fresh implementer finish — history stays task-by-task; the ladder shift is
  recorded in the plan and D38;** (19) the golden "switch the new behaviour off → old values return" check is what makes a
  ◈ move acceptable — ask both implementer and reviewer to do it; (20) **run 22: a "measure first" task runs well as a read-only
  investigator in parallel with the other task's implementer, then a reviewer who re-measures independently; wait on a
  background agent by `stat -L` on its transcript (the task file is a symlink).** (21) **run 23: a stub that skips a routine's
  sound or spawn draws desynchronises the RNG — when built code reaches a later task's routine (the spring → `.KillPlayerShot`),
  build the routine faithfully now and tell the owning task; run the wave-end gates in a background Bash while a
  foreground reviewer works.** (23) **run 25: when an implementer STOPS on an existing test the dump contradicts, read the cited M lines yourself, then rule and record it in the commit body + D38 (it took one SendMessage); a new suspension case can break the app's exhaustive switches — run G5 before merging even a Core-only task that touches `FrameSuspension`; Ben's attended session may commit to main mid-run (Q9) — rebase before the merge.** (24) **run 26: an implementer that STOPS on an old test pinning a named stub ("pushing is the Phase-4 tail") gets the seat ruling by SendMessage with a condition — re-derive the new value from the dump and explain every pixel, else STOP again; both review legs then re-derive it. A ◈ task may legitimately move no golden — have a reviewer probe why (which sprites wake on the golden routes).** (22) **run 24: a test that pinned a named stub's placeholder (GL's steering row) may take the dump's value by seat ruling, recorded in the commit body + D-number; the implementer must STOP and report first (it did); mislabelled `// later:` owners are worth a check (the Statue arm is SW's, not Phase 5).**

## THIS RUN'S JOB — loop run 27: **QT, then BX2 + BT** (3 tasks, none ⚑ MAJOR, one Opus review leg each)
- **QT** (plan `#### QT`, l. ~1105–1134, minor, → **460**; written by run 26 from Ben's Q5 answer, D40): a Dock or
  app-menu Quit while a level runs shows the game's own quit box at once (the in-level ⌘Q path: `Front/Pause.swift:82`
  `.confirmQuit` → `LevelRun.swift:~753` → `FerazelSession.swift:~695`); a logout/restart/shutdown (`kAEQuitReason`) quits
  at once without a dialog; elsewhere unchanged. Touches `Ferazel/App/FerazelController.swift:~652`
  (`applicationShouldTerminate`) + a Core seam in `GameFlow`/`LevelRun` + 3 tests in an existing test file. **G5 required**
  (App). Never leave `.terminateLater` pending (Lesson 9). The reviewer reads the logout path (AppKit, not unit-testable);
  agents must NOT launch the app (no G9 this run — D34 authorizes launches only at phase ends). No golden may move.
- **BX2** (plan `#### BX2`, l. ~1137, minor ◈, → **466** = plan 457 + 9): chests, doors and keys, the thought balloons.
  BX1 left the doors/chest/timer arms of `HitPlayerSprite` (relabelled `// later: BX2`) and the chest/door Box arms
  returning early (after the `+0x182` clear). ◈: may move goldens only for chest lids and key balloons near a locked chest
  or door — old → new + cause, both implementer and reviewer confirm by switching it off.
- **BT** (plan `#### BT`, l. ~1172, minor, → **472** = plan 463 + 9): Buttons, gates, switch blocks, boulder spouts. BX1's
  spin stomp already takes a switch block's HP (it vanishes once BT builds the block's Handle); the ice wall 2941's clip-top
  update and descent (M l. 61041–61064) were left to BT by BX1. No golden may move.
- Order QT → BX2 → BT, each merged to main before the next (rebase first — Ben may commit mid-run). After BT: G3 + G5
  (wave 4.7 ends after TP, but run them at this run's close anyway). Then CLOSE. The next chip names TP (⚑ MAJOR, two
  legs, → 476, wave 4.7 end) + SW (minor, → 482).
- First, if Ben wrote a new answer or text notes in QUESTIONS: plan that small task first (READ FIRST 1).

## GATES (fenced; verified on this machine 2026-10-26; G2 457/0, G3 1,108/0, G5 SUCCEEDED re-run by run 26 — copy literally; `$WT` = your worktree; the plan's Verification model adds G7b and G8 — copy those from plan l. ~106–110)
```sh
WT=$PWD; SCRATCH=$(mktemp -d)
# G1 HectorKit untouched (no Phase 4 task changes it — D38 Ruling 10)
git -C ~/Developer/HectorKit status --porcelain; git -C ~/Developer/HectorKit log --oneline -1      # empty; 35a85ba
# G2 suite: first number = the ladder total (QT 460, BX2 466, BT 472), second = 0
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
# HK floor (only in a run that changed HectorKit): ends PASS with Executed ≥ 361 — record the new floor in HK + STATE
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
  `main` for the next free number — D31 lives on the unmerged `deimos-phase2` branch, so skip it; the next
  free is **D41** — D36 is BTX's gamepad, D37 Ferazel's controller, D38 Phase 4, D39 Ben's verdicts, D40 Q5/Q7); listed in QUESTIONS for Ben's later read; **execution starts the next run without waiting.**
  A phase plan must carry: its own ladder, gate commands with numbers, the stand-ins it keeps (◇, named), the gate card.
- **Run / stage:** launching the staged `.app` for G9 and replacing `~/Desktop/Ferazel's Wand.app` (+ notes + icon
  previews) at each phase end is authorized. Never delete the prefs domain `com.ambrosiaclassics.ferazel` or any other
  `com.ambrosiaclassics.*`. No notarization, no release packaging, no installs of anything (brew/pip/Xcode components):
  those go to QUESTIONS.
- **HectorKit:** when a phase plan needs a kit change, you may commit to HectorKit's **local** `main` — own HK worktree
  (`git -C ~/Developer/HectorKit worktree add …`), `tools/check-zero-skip.sh` floor may only rise (now **361**; bump `FLOOR` in the
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
