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
   authorization for exactly what it says; record it in DECISIONS). **Open: Q11** (run 30's Phase 4 gate card — Ben's play verdict; a pass/notes/fail answer is acted on first: notes become a small named wave planned before anything else, a fail re-opens Phase 4 as tasks). Q10 → D41 (Windows straight after Phase 4, then lockstep) is THIS run's reason. **Ben's later notes on the text** (Q8:
   if the smoothed modern Times still looks off against the Let's Play, bundle classic Times/Geneva — allowed, D39) become
   a task the same way (plan it first as a named wave). Ben may commit to `main` mid-run (runs 25 and 26 both saw it):
   rebase onto `main` before each merge and re-run G2.
2. `CLAUDE.md`; `docs/STATE.md` (whole file); `docs/DECISIONS.md` **D26** (the Ferazel design ruling), **D33** (Phase 2
   as built), **D34** (the loop's authorizations), **D35** (Phase 3 rulings + as built), **D37** (Ferazel controller),
   **D38** (Phase 4 rulings — the plan's "Rulings" section is the full text), **D40** (Ben's Q5 + Q7 answers + QT as built), **D41** (Ben's Q10: Windows after Phase 4, then lockstep), and the BTX Windows rulings **D15, D16, D18, D19, D20, D21** (cross-compile, HectorSDL, bundled data, no menu bar, Ctrl shortcuts, 640×480 window; D20 = publishing was Ben's act, the loop never publishes).
3. **The model for this run: `docs/plans/2026-10-06-btx-windows.md`** (BTX's W-plan: W0 toolchain proof, W0.5 parity,
   W1 `HectorAudio.PCMMixer`, W2 bitmap font, W3 `HectorSDL`, W4 `WinGameDriver` + the Windows app, W5 in-window menu
   bar, W6 in-window dialogs, W7 stage; Ben's gates; orchestration notes) and `tools/windows/README.md` (toolchain pins,
   `build.sh`, `run-in-crossover.sh` + its driver env rule, `proof-b.sh`, `stage-btx.sh`, the CrossOver traps). Then the
   BTX Windows code it reuses: `BubbleTroubleX/Windows/`, `~/Developer/HectorKit/SDL` (HectorSDL), HectorKit
   `HectorAudio`/`HectorInput`. The Ferazel design `docs/plans/2026-10-06-ferazel-design.md` §3 (the "Windows twin"
   layer: `Ferazel/Windows`, shells only present a finished 640×480 RGBA buffer), l. ~105 (keys, D15/D16/D21
   precedent), l. ~119 (the staged `.app` and the zip carry the same data folder), l. ~158 (Windows has no menu bar,
   re-ruled for Ferazel), §8 row 7. Then what the Mac app does that Windows must match: `Ferazel/App/` (the
   `FerazelController` — `GameFlow` driving, the original's dialogs (DLOG/DITL) and MBAR menus, saved-game files and
   panels (D35 Q3 answers: modern panels on the Mac — Windows needs its own ruling), Options key remapping, the gamepad
   (D37), sound via `SoundTool`, text smoothing via CoreText (D39 — Windows has no CoreText: the BTX W2 bitmap-font
   route or a baked glyph cache is the question), the system Quit (D40)) and `tools/stage-ferazel.sh`. The Phase 4 plan
   (`docs/plans/2026-10-24-ferazel-phase4.md`) is now history except its "Stand-ins kept" table and A4's as-executed
   note.
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

## STATE (live, 2026-10-26, written by loop run 30 at its close; head of `main` = run 30's docs-close commit on top of 4bca4bd — read `git log -8 main`)
- **Phases 2 and 3 PASSED WITH NOTES by Ben (2026-10-25, D39).** Q9 (keep the speed), Q5 + Q7 (D40), Q10 (D41) answered.
- **Phase 3 "Front end + saves" CLOSED on the machine side** (loop run 17). Staged build **3553392** at
  `~/Desktop/Ferazel's Wand.app` + `~/Desktop/Ferazel's Wand — WHAT-TO-EXPECT.md` (Ben played it — Q6 answered).
- **Phase 4 "Spells + items" CLOSED on the machine side** (loop run 30; plan `docs/plans/2026-10-24-ferazel-phase4.md`,
  D38 + its "As built — Phase 4 end"): ladder 349 → **490** reached; A4 2f01491 + 28ebcab + 4bca4bd (comment sweep, gate
  card `Ferazel/WHAT-TO-EXPECT.md` as built). Staged build **4bca4bd** at `~/Desktop/Ferazel's Wand.app` +
  `~/Desktop/Ferazel's Wand — WHAT-TO-EXPECT.md` (two clean boots). FABLE-GRADE phase review PASS WITH FIXES (no code
  divergence; card wording fixed). **Ben's gate: QUESTIONS Q11.**
- **Handed to Phase 5 by seat ruling (run 30):** the underwater screen tint (`.TintScreen`, row 41 M 46450–46474; stubs
  `Player.swift` ~360, `PlayerLiquids.swift` ~139 — missing since Phase 2, on the gate card's stand-ins) → the Phase 5 plan
  takes it as a **named task**; the Magical Shield crouch face (`PlayerStates.swift` ~555) → Phase 5 with `.ShieldBlock`.
- `Ferazel/Core` suite: **490 passed, 0 failed/skipped** (run 30, seat-run and Fable-run from 4bca4bd's parents; card-only after). Census `Totals: items 1,108
  decoded, failures 0`. Ferazel BUILD SUCCEEDED. HectorKit `~/Developer/HectorKit` main **35a85ba**, clean, floor **361**.
- Worktrees: `inspiring-cannon-e97ccd` (deimos-phase2) and `~/Developer/gamepad-wt/Ambrosia-Classics` (branch
  `gamepad`, merged) are Ben's — never touch. Earlier runs' worktrees are the looper's to remove.
- **Goldens (current, after run 30 — it moved none):** Phase 1 `9db8f32f7e3d88b4` / `b80b0efd384ffdb9` / pan 30 `b1f4efcf3c34735f` / pan 60
  `80d88efdc8fac27c` / chain `aaab15c0710cbcf7`; Phase 2 L2 `565e867a02736c18` / `df22325e851e782d`, jump `deb577ecdeb64c58`,
  swim `c1dd428a3f146d77` (particles [67,321]), 600-frame `a8dda9cf3e448016` / cues `28a48762cfff1b2b` (cue words 3114, seed
  1574122804, particles 156); Phase 3 FE0 `ed142fed9e3bdce7`, map first frame `38563faaa2276f05`, map RNG `0x7b052a62`, sign
  frame `c8e41941c1e4d6da`. A Windows planning run changes no Core behaviour: any moved value is Invariant 10 — STOP, reconcile, record.
- **Run 30 notes:** the G9 quit Apple event answers "User cancelled (-128)" by design (D40: the flow queues the quit and
  the main menu's pass quits; the process is gone 3 s later) — not a failure; the Windows toolchain is already on this
  machine (`~/Developer/Toolchains/windows-cross/` with Swift 6.4.0, SDL3 3.4.16, winsysroot; `/Applications/CrossOver.app`)
  — no install is needed to plan, and building only needs what is there.
- **Run 29 carries:** the enemy stubs set counted-in-totals (`+0x1b5`) unconditionally where the dump gates it on
  `_DAT_1009fe8c` (matters once Phase 5 spawns enemies through Setup at run time) [MED]; the Bat's cache marks cover
  0x6cc/0x6cd of the dump's 0x6cc–0x6d5; the Roach Setup's `+0x154 = x` and speed 0x4b0 (M l. 64945–64946) unset (Phase 5);
  the Bat's path mode lives in the `voicePitch` slot (documented); the replica loads chest/crate drop faces per level where
  the original loads every Bonus face at boot (a seam, test pins it per level); the plan's LV3 test text had the spike frames
  backwards (frame 0 = out) and LV4's "node 5's neighbour" is node 5 itself (D35); `testEverySpawnableTypeHasSheet` ~15 s.
- **Run 28 carries:** the mosaic's cell-20 out-frame is never presented (last out-blit and first in-blit share a tick)
  [LOW]; the copy-before-`.mosaic` routing in `FrameRenderer.swift:~379` is an unstated coupling [LOW]; a teleporter
  with a missing record falls back to partner 0 [LOW]; the gamepad treats a teleport / upgrade as normal play [LOW]; a
  statue platform's own pair latch is never cleared while frozen (built as written); the trunk growth walk returns on a
  dead link (unreachable) [LOW]; the floe x not re-truncated to 16 bits [LOW]; light face 820 load unchecked in the app;
  the enemies' 11 statue sites ◇ Phase 5; the plan's own task headings still carry the pre-shift ladder numbers ("→ 477")
  — the shifted totals in this file and l. ~119 rule.
- **Run 27 carries:** a level that fails to load while a system Quit is held loses the quit [LOW]; QT's "already
  pending" guard untested (harmless); a chest dropping 0xc25 still throws (none in the census) [LOW]; BX2's timer test
  checks the sound position only at (0,0); `BonusSprite.swift:87–89` doc predates the chest-drop flag; the goldens are
  blind to chests/doors (forcing them open moved none); a firing spout skips the spawned shot's Setup draws (◇ Phase 5 —
  level 4's RNG shifts when it lands); a record-less sprite (index −1) reads record 0 in the gate/spout arms [LOW];
  `LevelRun.swift:508` hard-codes "boss alive" though `world.bossFlag` exists [LOW, Phase 6].
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
- **Run 26 carries (BX2/BT items now done):** a New Game builds a fresh `LevelCarry`, so the Shadow Double ring's mirror bytes reset there where the
  original keeps them until the app quits [LOW]; the Bat 0x6cc crate-drop arm is unreachable until Phase 5 builds non-Bonus
  drops; unbuilt Box arms skip `.StandardSpriteHandles` until their tasks (BX2/BT/SW); a stomped switch block only loses HP
  until BT builds its Handle (done, run 27); stale `// later: Phase 4` at `HitPlayerSprite.swift` ~l. 180, 815, 851, 889 (A4's sweep); a
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
  foreground reviewer works.** (23) **run 25: when an implementer STOPS on an existing test the dump contradicts, read the cited M lines yourself, then rule and record it in the commit body + D38 (it took one SendMessage); a new suspension case can break the app's exhaustive switches — run G5 before merging even a Core-only task that touches `FrameSuspension`; Ben's attended session may commit to main mid-run (Q9) — rebase before the merge.** (24) **run 26: an implementer that STOPS on an old test pinning a named stub ("pushing is the Phase-4 tail") gets the seat ruling by SendMessage with a condition — re-derive the new value from the dump and explain every pixel, else STOP again; both review legs then re-derive it. A ◈ task may legitimately move no golden — have a reviewer probe why (which sprites wake on the golden routes).** (22) **run 24: a test that pinned a named stub's placeholder (GL's steering row) may take the dump's value by seat ruling, recorded in the commit body + D-number; the implementer must STOP and report first (it did); mislabelled `// later:` owners are worth a check (the Statue arm is SW's, not Phase 5).** (25) **run 27: Ben may commit to main mid-run (Q10 arrived during QT) — `merge --ff-only` fails, rebase, re-run G2, merge; a reviewer's mutation that survives on a fallback line is worth a seat ruling when it exposes a hole in Ben's intent (a Dock Quit lost during the opening screens); an implementer's "plan says one press, dump says two" claim gets its reviewer pointed at both call sites.** (26) **run 28: implementers and resumed agents always run in the background here — wait with a `stat -L` mtime loop on the task output (idle > 500 s, or the notification); reviewers' mutation tables keep finding arms the whole suite does not pin (TP: unpinned centre/scroll; SW: four Statue arms) — a tests-only round inside existing functions, seat-read, is the standard fix; an agent made the HK self-link again (removed at close).** (27) **run 29: a level's "enterable" task also owns its level-load picture cache (`CachedFaces` in `Front/LevelRun.swift`) — every Setup's cache marks, pinned by the bar step count; a reviewer leg that runs the real level load finds it; the census test's "nothing refused" is not the whole job.**

## THIS RUN'S JOB — loop run 31: **the Ferazel Windows PLANNING run** (D41: before the Phase 5 plan)
- First, if Ben wrote an answer under **Q11**: act on it first (READ FIRST 1) — record it in DECISIONS (next free **D42**),
  a pass closes Phase 4; notes become a small named wave planned (and, if small, built) before the Windows plan.
- **Write `docs/plans/2026-10-2x-ferazel-windows.md`** (Opus planner — dispatch one `fk-implementer` as planner, or a
  `Plan` agent then an implementer to write the file; `superpowers:writing-plans` shape, **contracts not code** —
  memory `feedback-plans-carry-contracts-not-code`): Ferazel's Windows twin as its own short phase on the BTX W-plan
  shape, grounded on what BTX already proved (toolchain, `HectorSDL`, `PCMMixer`, the baked bitmap font, the in-window
  menu/dialog drawing, `stage-btx.sh`) — reuse, don't rebuild. It must carry: its own task list with ⚑ MAJOR marks and
  file:line contracts; its own ladder (Ferazel/Core stays 490 unless a Windows parity fix adds tests; a Windows Proof B —
  the Core suite cross-built and run in CrossOver — with its own expected count and skip rules); gate commands with
  numbers (the Mac gates G1–G10 kept, plus Windows build, Proof B, staged-zip boot in a clean CrossOver bottle); the
  stand-ins it keeps (◇, named); the Windows gate card (what Ben's tester checks); the **lockstep rule** from D41 written
  as a standing contract for Phase 5+ (every task that changes what the Mac app shows or does carries its Windows side;
  every phase end stages both); and rulings for the open Windows questions — at least: no CoreText on Windows (text
  smoothing D39 → baked glyphs? measured how?), save/open panels (D35 Q3 chose modern Mac panels — Windows equivalent or
  the original's Standard File drawn in-window), the original's dialogs drawn in-window (BTX W6), no menu bar (D21 re-ruled
  for Ferazel, design l. ~158), the keypad defaults and the gamepad on Windows (HectorInput / SDL gamepad), the 30-step
  speed cap and the 240 Hz/2-tick clock under SDL, the system quit (D40) on Windows, where saves and prefs live
  (`%APPDATA%`?), the `-FerazelLevel` switch, the data folder carried as on the Mac. Owner-only choices go to QUESTIONS
  as non-blocking items with defaults (D34).
- Reviews: **two Opus `fk-reviewer` legs** on the plan (one grounds it against BTX's Windows code + `tools/windows/`,
  one against Ferazel's App + design + D-rulings), fixes applied, then **one FABLE-GRADE leg** (`fk-reviewer`,
  `model: "fable"`, named "FABLE-GRADE gate", told "no background agents"), fixes applied. Rulings → **D42** (or the next
  free number). A QUESTIONS item lists the plan for Ben's later read (execution does not wait, D34).
- Commit: `Ferazel Windows plan (D42)`. No code, no HectorKit change in a planning run (G1 must stay 35a85ba).
- Then CLOSE. The next chip names the plan's first execution unit (2 tasks, or 3 if at most one is ⚑ MAJOR).

## GATES (fenced; verified on this machine 2026-10-26; G2 490/0, G3 1,108/0, G5 SUCCEEDED re-run by run 30 and by its Fable leg — copy literally; `$WT` = your worktree; a planning run needs only G1, G2 once at RECONCILE, G10; the new plan writes the Windows gates)
```sh
WT=$PWD; SCRATCH=$(mktemp -d)
# G1 HectorKit untouched (no Phase 4 task changes it — D38 Ruling 10)
git -C ~/Developer/HectorKit status --porcelain; git -C ~/Developer/HectorKit log --oneline -1      # empty; 35a85ba
# G2 suite: first number = 490, second = 0
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
  free is **D42** — D36 is BTX's gamepad, D37 Ferazel's controller, D38 Phase 4, D39 Ben's verdicts, D40 Q5/Q7, D41 Q10 Windows); listed in QUESTIONS for Ben's later read; **execution starts the next run without waiting.**
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
- **Windows — moved forward by Ben's Q10 (D41, 2026-10-26):** after Phase 4's end run, the NEXT run plans Ferazel's
  Windows twin as its own short phase BEFORE the Phase 5 plan (staged as a zip under `out/`, never published); from then
  on every task that changes what the Mac app shows or does carries its Windows side, and every phase end stages both
  builds with one gate card. **Windows (formerly Phase 7)** follows the BTX W-plan shape (D15–D21, `tools/windows/`); the zip is staged, his brother's test
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
