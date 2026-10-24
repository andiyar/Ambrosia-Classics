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
   authorization for exactly what it says; record it in DECISIONS). Open: **Q2** (the Phase 2 gate card — Ben DEFERRED it
   until he is back; not a verdict, keep it open), **Q5** (system Quit/logout during a level waits for a pause or the
   menu, as the original — built as (a)), **Q6** (run 17: the Phase 3 gate card — first real play of the new front end).
   If Ben answers Q2 or Q6 with (b)/(c), his notes become fix tasks for that phase — plan them FIRST, before Phase 4
   work, and say so in LOOP-LOG; Q5 (b)/(c) is a small App task, plan it first too. Q1, Q3, Q4 are answered and acted on.
2. `CLAUDE.md`; `docs/STATE.md` (whole file); `docs/DECISIONS.md` **D26** (the Ferazel design ruling), **D33** (Phase 2
   as built), **D34** (the loop's authorizations), **D35** (Phase 3 rulings + its "As built (loop run 9 … 17)"
   paragraphs), **D37** (Ferazel controller).
3. **The design: `docs/plans/2026-10-06-ferazel-design.md`** — §1 scope, §8 the phase table (l. 168: **Phase 4 "Spells
   + items"** = casting, the spells and player shots, items/inventory/HUD, pickups, boxes (crates, chests, doors, keys,
   switches, teleporters), held weapon; Ben's gate "first levels as the original allows"), §9 open items.
4. **The Phase 3 plan as the template and the carry source: `docs/plans/2026-10-14-ferazel-phase3.md`** — its shape
   (Verification model, Invariants + Hazards, Shared architecture LOCKED, waves of tasks with Files/Contract/Tests/Gate/
   Commit, Execution order, Stand-ins, Bank corrections, Rulings, Review ledger, the gate card), its **"Stand-ins kept
   (◇)" table (l. ~1628)** — every row marked "Phase 4" is Phase 4's to replace (HUD from G's inventory, USE-item hint
   conversations, Escape Ring, the 1058 world-flag Bonus class, `BuiltLevels` widening as levels' Setups land) — and the
   "As executed" bullets of GP and A2 (carried NOTEs). Next free bank correction number: grep `BC` in that plan (last
   was BC34 → **BC35**).
5. The bank: `docs/ferazel/INDEX.md` then the topical files for items, spells, boxes, inventory (load only what the plan
   needs); the decompile `ghidra/ferazel/` (the dump beats the bank: "follow the binary"; the "digest A–F" files were
   never committed — ground on the bank + the dump, say so in every brief).

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

## STATE (live, 2026-10-24, written by loop run 17 at its close; head of `main` = run 17's docs-close commit on top of 3553392 — read `git log -8 main`)
- **Phase 2 "Ferazel moves" is CLOSED on the machine side** (loop run 7). **Ben's gate: QUESTIONS Q2 — DEFERRED.**
- **Phase 3 "Front end + saves" is CLOSED on the machine side** (loop run 17): every task of the plan
  `docs/plans/2026-10-14-ferazel-phase3.md` done — X1 R1 SV1 SV2 FE0 O1 L2 L1 RX M1 M2 F1a D1 F1b S1 P1 EC C1 C2 A1a A1b
  **GP** (325d2e4 + 88a0809, a game controller as the original keys, → 349) **A2** (4184463 + Fable fixes 3553392).
  Staged build **3553392** at `~/Desktop/Ferazel's Wand.app` + `~/Desktop/Ferazel's Wand — WHAT-TO-EXPECT.md` (the gate
  card) + icon previews; **G9 2/2** (the first launches of the GameFlow app: boot reaches the main menu, quits clean, no
  crash report). Fable phase-end leg: "stage as is after doc fixes" (dump MATCH across the front end, saves, map,
  pause, stage panel; 9/9 mutations killed). **Ben's gate: QUESTIONS Q6.**
- `Ferazel/Core` suite: **349 passed, 0 failed/skipped**. Census `Totals: items 1,108 decoded, failures 0`. HectorKit
  `~/Developer/HectorKit` main **35a85ba**, clean, floor **361** (unchanged since the BTX gamepad work).
- Worktrees: `inspiring-cannon-e97ccd` (deimos-phase2) and `~/Developer/gamepad-wt/Ambrosia-Classics` (branch
  `gamepad`, merged) are Ben's — never touch. Run 17's own worktree is the looper's to remove.
- Goldens: Phase 1 `9db8f32f7e3d88b4` / `b80b0efd384ffdb9` / pan 30 `172596fa2f3b6c58` / pan 60 `cc9786ba763d383a` /
  chain `b4230ba5a643c5b5`; Phase 2 L2 `565e867a02736c18` / `df22325e851e782d`, jump `e4f4bf977dd98eaa`, swim
  `95ff5176412df650`, 600-frame chain `9532d65a42d39666` / cues `a875a96c2801dbe9`; Phase 3 main-menu screen
  `ed142fed9e3bdce7` (FE0), world map first frame `38563faaa2276f05` (M1/M2), map RNG `0x7b052a62` (M1), sign frame
  `c8e41941c1e4d6da` (C2).
- **Carried minor follow-ups (unowned; the Phase 4 plan may adopt any):** report fade-in when faded (M l. 35448) unbuilt;
  a second queued main-menu pick dropped; boot bar jumps (all map faces load in one callback); music decoded on play;
  `.savePoint(saved:)` carries no polled input after the save dialog; `SavedGameFile.writeErrorReport` code typed
  optional; `CoreTextRasterizer` widths untested; `FerazelController.fail()` exits with only an NSLog (a Release alert
  would help); the save panel's field label repeats the prompt; stale "later: W1/W3/W4/P2" comments (Phase 2 tasks) in
  `SpriteSlot.swift:135`, `SpriteWorld.swift:57,297`, `Player.swift:17`, `RectBounce.swift:155`, `BoxSprite.swift:36`,
  `BackgroundSprite.swift:25`.
- **Lessons (runs 9–17):** (1) the plan's "digest A–F" were never committed — ground on the bank files + the dump (say so
  in every brief); (2) the plan is wrong against the dump about once per task — the dump wins, the as-executed bullet
  records it; (3) run the seat's own gates from the worktree once no agent is building; (4) foreground `Agent` calls
  return the report directly — two review legs in one message run in parallel in `git archive` temp copies; (5) a fix
  round that changes behaviour gets a re-review; a tests-only or tiny round the seat reads itself; (6) Opus reviewers'
  mutation runs are the best signal — strengthen inside existing test functions so the ladder total holds; (7) plan file
  lists miss flow wiring and seams — every A/GP task needed files the plan did not list; a Phase 4 plan should list the
  `Front/` flow files and `Ferazel/App/` seams each task touches; (8) merge each green task to main before starting the
  next; (9) on AppKit: never leave a `.terminateLater` pending across play; pass UCKeyTranslate option MASKS; (10) **run
  17: a Fable reviewer that launches its own background helpers returns early and does NOT wake on their results** (the
  notices come to the seat) — resume it with SendMessage giving the helpers' output-file paths, or tell it up front "no
  background agents"; (11) a plan table can contradict its own ruling's reason (GP's map − tap aborted a game) — read
  each layout/flow table against the ruling's stated why.

## THIS RUN'S JOB — loop run 18: **the Phase 4 planning run** ("Spells + items")
- Write `docs/plans/<date>-ferazel-phase4.md` with an Opus planner (`fk-implementer`, no model param — never
  Sonnet/Haiku, never general-purpose), `superpowers:writing-plans` shape, **contracts not code**
  (`feedback-plans-carry-contracts-not-code`), against the design §8 row 4, the bank, the dump and what landed (Phase 3
  as built + its ◇ table). It must carry: its own ladder from **349**, gate commands with numbers, waves of 2–3 tasks
  (⚑ MAJOR marked), Files lists that include the flow/App seams (lesson 7), the stand-ins it keeps (◇, named) and
  replaces, bank corrections numbered from BC35 (or the Phase 4 plan's own series, say which), the gate card ("first
  levels as the original allows" — say which levels are enterable at the end of Phase 4: `BuiltLevels` widens only as
  each level's Setups are transcribed; decide whether Phase 4 widens it and how far), and whether HectorKit changes.
- Then **two Opus review legs** (`fk-reviewer`, no model param, in parallel, each grounded on the dump), fixes, then
  **one Fable leg** (`fk-reviewer`, `model: "fable"`, "FABLE-GRADE gate" in its prompt, told: no background agents),
  fixes. Rulings → **D38** in `docs/DECISIONS.md` (next free; D36 is BTX's gamepad, D37 Ferazel's controller). List the
  plan for Ben's later read in QUESTIONS (non-blocking, like Q3). **Execution starts the next run without waiting.**
- The NEXT chip you write then names the first wave of Phase 4 tasks (2 tasks, 3 if at most one is ⚑ MAJOR).

## GATES (fenced; verified on this machine 2026-10-24; G2 349/0, G3, G5, G9 re-run by run 17 — copy literally; `$WT` = your worktree)
```sh
WT=$PWD; SCRATCH=$(mktemp -d)
# G1 HectorKit untouched unless the Phase 4 plan names an HK task; then: a local HK main you made + floor ≥ 361 (see AUTHORIZATIONS)
git -C ~/Developer/HectorKit status --porcelain; git -C ~/Developer/HectorKit log --oneline -1      # empty; 35a85ba
# G2 suite: first number = the ladder total (349 at the start of Phase 4; a planning run must not change it), second = 0
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
