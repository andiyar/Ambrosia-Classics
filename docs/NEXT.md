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
   authorization for exactly what it says; record it in DECISIONS). Open: **Q5** (system Quit/logout during a level waits
   for a pause or the menu, as the original — built as (a)), **Q7** (run 18: the Phase 4 plan's three non-blocking
   choices — defaults are being built), **Q9** (run 22: game speed — the port runs at the original's cap, 30 steps/s; the
   Let's Play ~25; keep / hidden slower cap / slower default — default (a) keep, nothing changes). A (b)/(c) answer to Q5
   or Q9 is a small App task, plan it first (as wave 4.2F was: a named wave before the next one in the Phase 4 plan); a
   non-default Q7 answer becomes a small task in Phase 4. **Ben's later notes on the text** (Q8 says: if the smoothed
   modern Times still looks off against the Let's Play, bundle classic Times/Geneva — allowed, D39) become a task the same way.
   Phase 4. Q1, Q2, Q3, Q4, Q6, Q8 are answered and acted on (D39 records Q2/Q6/Q8).
2. `CLAUDE.md`; `docs/STATE.md` (whole file); `docs/DECISIONS.md` **D26** (the Ferazel design ruling), **D33** (Phase 2
   as built), **D34** (the loop's authorizations), **D35** (Phase 3 rulings + as built), **D37** (Ferazel controller),
   **D38** (Phase 4 rulings — the plan's "Rulings" section is the full text).
3. **The plan: `docs/plans/2026-10-24-ferazel-phase4.md`** — read "Verification model" (l. 78, gates G1–G10 incl. G7b
   and G8, and the run-21 ladder-shift note at l. ~119), "Non-negotiable invariants" + "Hazards" (l. 154, 195), "Shared
   architecture LOCKED" (l. 222), then your wave's tasks, "Execution order" (l. ~1298), "Stand-ins kept (◇)" (l. ~1336),
   "Bank corrections to append" (l. ~1432) and "Rulings" (l. ~1531). Read the "As executed" notes of waves 4.0–4.2 (X1,
   VS, LT, US, IV, HU, TB, BN, PK — grep `As executed (`) — they change seams you will use (`killCount`/write-back flags,
   `addItem` returns the slot, `StatusBarCalls` + the flow-wide status-bar globals, `BonusSprite`, `Outcome.upgrade`,
   `PlayerState.passRequests`, `fadeOut` returning whether it armed). The design `docs/plans/2026-10-06-ferazel-design.md`
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

## STATE (live, 2026-10-25, written by loop run 22 at its close; head of `main` = run 22's docs-close commit on top of 480d46e — read `git log -8 main`)
- **Phases 2 and 3 PASSED WITH NOTES by Ben (2026-10-25, D39).** His notes became wave 4.2F (done by loop run 22).
- **Phase 3 "Front end + saves" CLOSED on the machine side** (loop run 17). Staged build **3553392** at
  `~/Desktop/Ferazel's Wand.app` + `~/Desktop/Ferazel's Wand — WHAT-TO-EXPECT.md` (the gate card; Ben played it — Q6 answered).
- **Phase 4 "Spells + items" UNDER WAY** (plan `docs/plans/2026-10-24-ferazel-phase4.md`; D38 + its "As built — wave
  4.0/4.1/4.2" + D39 "As built — wave 4.2F"): 24 tasks + the seat-inserted TB + wave 4.2F (TX, SP) + phase end A4. **Ladder
  now 349 → 487** (TB +3 before BN, TX +3 before EF: every total from EF on is the plan's + 6 — plan l. ~119 says so). `BuiltLevels` widens to 1...3 at LV3 and 1...4 at LV4.
  Waves 4.0 (run 19) → 357 and 4.1 (run 20) → 374 done. **Wave 4.2 DONE (loop run 21):** TB 46d2173 + d4c1f7b (sprite
  draw mode 0xb, translucency — `.BlitEncFaceTransClip`/`…FlipClip`, `.CalcPxRowContents`, table 0148; a flipped sprite over
  the left edge reads what the binary reads, never refuses) → 377; BN 8180590 + 9b2faaf (`World/Movers/BonusSprite.swift`:
  Setup/Handle/Hit/HitTile/Kill, write-back flags, M6, `LightTable.clearFace`; still `notTranscribed`: 0xc25 and
  0xc9b…0xcb0 — not on levels 1–2, **recheck at LV3/LV4**) → 385; PK 7208dbd + eb754a1 + 92419b6 (the pickup arm in
  `Player/HitPlayerSprite.swift`, `.upgrade(type:)` suspension run by `LevelRun` over 120 ticks, `Outcome.upgrade` carries
  the resume tick's keys + Caps Lock, hurt coins spawned on layer 1 (the dump, not 0x14), `fadeOut` returns whether it armed
  → `.hideCursor` via `PlayerState.passRequests`, one ordered list for pass draws) → **393**. **Wave 4.2F DONE (loop run 22,
  Ben's notes):** TX cdcb8b8 + 480d46e (`TextRasterizer` returns coverage 0…255; one blend helper in `TextRasterizer.swift`;
  the App's `CoreTextRasterizer` smooths at ≥ 14 pt as the LP shows; status bar mixes through the screen CLUT) → **396**;
  SP (measured, no code: port = binary cap 30 steps/s; LP ~25 — Q9).
- `Ferazel/Core` suite: **396 passed, 0 failed/skipped** (run 22, seat-run from the merge head). Census `Totals: items 1,108
  decoded, failures 0`. Ferazel BUILD SUCCEEDED. HectorKit `~/Developer/HectorKit` main **35a85ba**, clean, floor **361**.
- Worktrees: `inspiring-cannon-e97ccd` (deimos-phase2) and `~/Developer/gamepad-wt/Ambrosia-Classics` (branch
  `gamepad`, merged) are Ben's — never touch. Earlier runs' worktrees are the looper's to remove.
- **Goldens (current, after wave 4.2F — it moved none):** Phase 1 `9db8f32f7e3d88b4` / `b80b0efd384ffdb9` / pan 30 `b1f4efcf3c34735f` / pan 60
  `80d88efdc8fac27c` / chain `aaab15c0710cbcf7`; Phase 2 L2 `565e867a02736c18` / `df22325e851e782d`, jump `deb577ecdeb64c58`,
  swim `c1dd428a3f146d77` (particles [67,321]), 600-frame `a8dda9cf3e448016` / cues `28a48762cfff1b2b` (cue words 3114, seed
  1574122804, particles 156); Phase 3 FE0 `ed142fed9e3bdce7`, map first frame `38563faaa2276f05`, map RNG `0x7b052a62`, sign
  frame `c8e41941c1e4d6da`. **Only BX1 and BX2 (◈) may move a golden from here**, each recording old → new and the cause,
  the reviewer confirming the cause by switching it off (the method that worked in run 21).
- **Carried minor follow-ups (not adopted, D38 Ruling 15 — left to Ben's Q6 verdict):** report fade-in when faded (M l. 35448)
  unbuilt; a second queued main-menu pick dropped; boot bar jumps; music decoded on play; `.savePoint(saved:)` carries no
  polled input after the save dialog; `SavedGameFile.writeErrorReport` code typed optional; `CoreTextRasterizer` widths
  untested; `FerazelController.fail()` exits with only an NSLog; the save panel's field label repeats the prompt. **Runs
  19–20 carries:** `SeparateFromTiles.swift:109` names landed tasks (relabel when touched); the app's `SoundTool` "unloaded"
  rule + `isPlaying`/`playingSounds` lack the nil-handle-counts-all rule; `GroundCeilingEffects.swift:207` builds a lookup
  per smoke frame (EF touches this file — fix it there if cheap); `SpriteWorld.valid()` extra bound; the Px strip `+0xea`;
  conversation action 2's `0bf4`/`0bf0` stores unwired; the status bar's source-clip model untested [MED]; Render's text
  caches per renderer. **Run 21 carries:** TB's test fixture uses one face in every parallax cell slot (cell choice and the
  128-px step untested) and assumes rowBytes 128; several `BonusSprite.swift` cites run ~20 lines short of the dump; a
  Core-only session with no faces skips the Xichron burst's draws quietly (faithful fix: load all `BonusSprite.sheets` in
  Core, or stop when missing); **sphere timers are not counted down until PU** (a walk-on-liquid sphere stays on — level 2
  has one; PU owns it); a 1058 with p1 out of range is dropped where the binary writes past the end; the glider's 0x41a sheet
  is GL's.
- **Run 22 carries:** the smoothing mix is linear with no gamma and the 14 pt threshold is read from the LP, both [MED];
  the LP's Times still looks a little heavier and ~5 % wider than today's system Times (the font — D39 allows bundling
  classic Times if Ben asks); SP left the level-start pan, the load bar and walk distance per step unmeasured [LOW].
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
  background agent by `stat -L` on its transcript (the task file is a symlink).**

## THIS RUN'S JOB — loop run 23: **Phase 4 wave 4.3 = [EF CS]** (2 tasks, both ⚑ MAJOR)
- **EF** (plan `#### EF`, l. ~705–745, ⚑ MAJOR, → **403** = plan 397 + 6): the Effect ids Phase 4 spawns (0…15, 0x442,
  0x4b6, 0x4b7, 0xc1b, 0xc81, the balloons — Ruling 14), the explosion package, `ScreenFlash` (`Particles/ScreenFlash.swift`,
  `_DAT_100a00fc`/`_DAT_100a00cc`, M l. 9437–9447), `DrawOp.copyMaskToScreen`, the Camera shake counter `_DAT_1009ffa0`;
  `GroundCeilingEffects.swift` is its main file (fix the per-smoke-frame lookup carry there if cheap). Every Effect type
  spawned at run time needs its sheet in the renderer's sheet table (plan l. ~318–323). No golden may move (not ◈) — STOP if
  one does. Two Opus review legs.
- **CS** (plan `#### CS`, l. ~746–811, ⚑ MAJOR, → **412** = plan 406 + 6): casting (`.CastSpell`; the cast sound's
  `FastRand(10000)` precedes the shot Setup's `FastRand(5)` — Hazards) and the player shots in flight
  (`SpriteHandler.playerShot`, `+0x170` power / `+4` spell id split, `+0x14c` shot age); the no-free-record rule (Ruling 16).
  Not ◈. Two Opus review legs.
- Order EF → CS (CS uses EF's effect 5 for the liquid rule), each merged to main before the next. Wave end: G3 + G5. Then
  CLOSE. The next chip names wave 4.4 = [SH GL PU] (plan `#### SH` l. ~812ff, → 431; SH ⚑ — a 3-task run if only SH is MAJOR).
- First, if Ben answered Q5/Q9 with (b)/(c) or wrote text notes: plan that small task first (see READ FIRST 1).

## GATES (fenced; verified on this machine 2026-10-25; G2 396/0, G3 1,108/0, G5 SUCCEEDED re-run by run 22 — copy literally; `$WT` = your worktree; the plan's Verification model adds G7b and G8 — copy those from plan l. ~106–110)
```sh
WT=$PWD; SCRATCH=$(mktemp -d)
# G1 HectorKit untouched (no Phase 4 task changes it — D38 Ruling 10)
git -C ~/Developer/HectorKit status --porcelain; git -C ~/Developer/HectorKit log --oneline -1      # empty; 35a85ba
# G2 suite: first number = the ladder total (EF 403, CS 412), second = 0
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
  `main` for the next free number — D31 lives on the unmerged `deimos-phase2` branch, so skip it; after D35 the next
  free is **D38** — D36 is BTX's gamepad, D37 Ferazel's controller); listed in QUESTIONS for Ben's later read; **execution starts the next run without waiting.**
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
