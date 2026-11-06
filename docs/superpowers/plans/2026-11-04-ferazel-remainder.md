# Ferazel's Wand — the remainder: implementation plan (Phase 5 second half, Phase 6A/6B/6C, release)

> **For agentic workers:** this plan is executed by the unattended loop (`docs/NEXT.md` is one run's chip; D34) with
> `superpowers:subagent-driven-development` — one `fk-implementer` and one `fk-reviewer` per task, two review legs
> per ⚑ MAJOR task, Opus 5.5 throughout, Fable only at phase plans and phase ends (D34). Plans in this house carry
> **contracts, not code** (Ben, 2026-10-03): files with line anchors, APIs, test names, commands, commit messages.
> Steps use checkboxes for tracking.

**Goal:** finish Ferazel's Wand as design §1 defines it — every enemy, every boss, all 24 levels, victory, on Mac and
Windows — then release it, in gates Ben can play.

**Architecture:** unchanged (spec §2): `FerazelCore` rules, `FerazelRender` pixels, `Ferazel/Shared` driver, the Mac
and Windows shells. Every remaining class lands in `World/Enemies/`, every engine feature in the module that owns the
original routine, every level in a `Level<N>Tests` file; the seam types only gain cases.

**Authority:** this plan for the waves below; `docs/plans/2026-10-30-ferazel-phase5.md` (D44) for the task cards it
names (FR … A5 are **not** re-copied here — the loop reads them there, with the deltas this plan records); the spec
`docs/superpowers/specs/2026-11-04-ferazel-remainder-design.md`; the audit
`docs/superpowers/audits/2026-11-04-ferazel-audit.md` (its rulings correct both).

---

## 0. The verification model (fable-kit, read before any dispatch)

| rule | what it means here |
|---|---|
| Numbers from the seat's own runs | every count in a close note comes from a command the seat ran (G2 in a background shell from a `git archive` copy); a subagent's number is never relayed on faith |
| One implementer + one reviewer per task; two review legs per ⚑ | the second leg builds a mutation table (it has found 20–40 unpinned behaviours per class task, every time); the fix round is tests-only unless the dump says otherwise |
| Reviewers run things | each leg builds in its own scratch copy, re-runs the task's test class, and confirms one numeric prediction (a golden, a count) |
| The dump beats the bank beats the plan | every brief: "re-read each cited M line in the committed dump before coding; record disagreements in As executed" |
| ◈ goldens move only for the named cause, with the switch-off check | implementer and leg 1 independently: the class's `forClass` row back to `.inert` → every old value returns |
| Invariant 10 | any other moved value: STOP, reconcile, record |
| Scope fence (G6) | the diff ⊆ the task's Files (+ DECISIONS, the bank file a BC names, the plan's As executed) |
| Launches | never by the loop except muted, few, short, 09:00–21:00 (D42); never by the planning or audit sessions |
| Ben's gate | a phase closes on the machine side only; "machine gates green; Ben's gate pending" |
| Context | 300k per run; 2 tasks a run (3 when at most one is ⚑); at ~240k close; a run that cannot merge records why in LOOP-LOG + QUESTIONS and keeps its worktree |

**Gates:** the Phase 5 plan's gate table and fenced commands (`docs/plans/2026-10-30-ferazel-phase5.md:101–:199`)
stand for every task in this plan, with these changes:

| gate | change (from this plan on) |
|---|---|
| G1 HectorKit | **pending Q-B** (spec §6). Default if Ben says (a): `git -C ~/Developer/HectorKit log --oneline -1` = the SHA recorded in NEXT's STATE block at the run's start (today **ef2c341**, floor 370); a later HectorKit main is accepted at reconcile when its tree is clean and `tools/check-zero-skip.sh` passes at ≥ the recorded floor — the run records the new SHA + floor in NEXT, STATE and LOOP-LOG. "No HectorKit change" = no change *by a Ferazel task*. If (b): pin through a HectorKit worktree at 35a85ba (`git -C ~/Developer/HectorKit worktree add ~/Developer/HectorKit-worktrees/ferazel-pin 35a85ba`) and point the run's `.claude/worktrees/HectorKit` symlink at it. |
| G2 Core suite | the ladder below; the suite is run **once per task at merge** by the seat, in a background shell with a 40-minute timeout, from a `git archive` copy, **as two commands** (⚑ audit 11): `swift test --filter FerazelCoreTests` (432 rules tests, ~1 min) then `swift test --filter FerazelRenderTests` (128, ~12 min) — the totals are the same; the skipped lines are checked **by name** (`grep -oE "^Test Case '[^']*' skipped"` = exactly the opt-in list), not by count (⚑ audit 15); implementers and reviewers run `--filter <Class>` per touched class and never end a turn while anything runs |
| opt-in tests | a task that adds one edits `tools/windows/proof-b-ferazel.sh:21–22` (its switch cleared) and `:126–127` (the opt-in list) in the same commit, and the G2/GW2 skip lists in NEXT (⚑ audit 14) |
| switch-off check (◈) | **stub the class's Handle body (and any hit it adds) with one local patch, never committed; every old value must return; revert** — never "set the `forClass` row to `.inert`", which switches nothing off (every class Setup stores its own handler; ⚑ audit 1) |
| GE phase-end checks | extended to every built level at each phase end (R7); each level task runs the bot's quick mode on its level |
| heavy processes | never two whole suites or sweeps at once (Ben's RAM rule, 8f7746f); the sweep and the bot keep 4 workers |

**Ladders** (Core total / opt-in skips; WinKit 81 / 2 unless a row says otherwise). The Phase 5 ladder is the
plan's +1 (D44 run 37): BA **569**, FR 577, BL 584, GF 591, DL 596, GY 603, PI 607, OX 612, LV5 618, A5 618;
Proof B at A5 615 / 0 / 3 / 0 (of 618). Phase 6 ladders are set by its plans (wave 4).

**Goldens:** as the Phase 5 plan's Verification model lists them after run 41 (NEXT.md STATE "Goldens (current, after
run 41)"), plus the audit's confirmation; BA moved none (run 42's probe), FR may move level-2 goldens (Frogs ×2) if a
Frog wakes on a route.

## Risk waves

| wave | what | risk it retires | runs |
|---|---|---|---|
| 0 | the audit (this session; read-only) | "the built half is sound" is a claim, not a check | — |
| 1 | reconcile (HectorKit, the kept worktree), finish BA, build FR | the parked work and the drift | 1 |
| 2 | BL, GF, DL, GY, PI, PT (wave 5.3 end, 5.4, the audit's census fix) | the last enemy classes; synthetic tests for classes no built level places; the renderer's traps | 3 |
| 3 | OX, LV5, A5 + Fable phase review → Ben's gate | level 5 and the first engine feature (OmniPx); "through the first boss door" | 2 |
| 4 | Phase 6 research: R1 later-level ledger, R2 boss contracts, R3 engine-feature contracts; then the 6A plan | every Phase 6 number measured before a build task exists | 1–2 |

Runs: 43 (wave 1), 44–46 (wave 2), 47–48 (wave 3), 49 (wave 4), then 6A.
| 5 | Phase 6A — engine features of levels 10–22, levels 10–22 enterable, the Goblin Chief; gate | the first boss fight; six new engine features | ~8 |
| 6 | Phase 6B — levels 25–52, the Wizard, ice, timer, CLUT animation, auto-scroll, fire; gate | the renderer's last big features | ~7 |
| 7 | Phase 6C — levels 55–70, the Fire Guardians, Xichra's lair, victory; gate = the whole game | the end of the game | ~6 |
| 8 | release (attended) | — | 1 session |

---

## Wave 0 — the audit (done in this session, 2026-11-04)

Five read-only `fk-reviewer`s (spec §7): A foundation + shots, B ground enemies, C the Bat branch, D the loop's
gates and tools, E the front end against 24 levels. Reports and rulings:
`docs/superpowers/audits/2026-11-04-ferazel-audit.md`. Every ruling that changes a wave-1 task is applied below and
marked ⚑ audit.

---

## Wave 1 — run 43: reconcile, finish the Bat, build the Frog and Salamander

Run shape: RC (seat, no subagent) → BAf (one fix-round implementer + one re-review leg) → FR (⚑: one implementer,
two legs, fix round). FR starts only after BAf has merged (it shares `SetupFaces.swift`, `SpriteSlot.swift`,
`LevelRun.swift`).

### Task RC — reconcile (seat only, minor, no ladder change)

**Files:** `docs/NEXT.md` (STATE block, G1 line, the goldens list), `docs/LOOP-LOG.md` (one line for run 42: stopped
by the STOP file at 21:00 with BA at 005058f reviewed, fix round unrun, worktree kept), `docs/DECISIONS.md` D45
(Ben's answers from the presentation), `docs/QUESTIONS.md` (answered items moved).

- [ ] **Step 1 — HectorKit per Q-B.** `git -C ~/Developer/HectorKit status --porcelain` empty; `log --oneline -1`
  = ef2c341 (or later main). Run `bash ~/Developer/HectorKit/tools/check-zero-skip.sh` (the floor must be ≥ 370; if
  HectorKit's STATE records a higher floor, that number). Record the SHA + floor in NEXT's STATE block and the G1
  line. If Ben chose (b), make the pin worktree instead (table above) and record that.
- [ ] **Step 2 — the kept worktree.** `git -C "$REPO" log --oneline main..loop/42-20261031-162344` prints exactly
  `005058f`. Cherry-pick it onto the run's branch: `git cherry-pick 005058f` (expected clean: main has not moved since
  07bc11d; if it has, resolve and record). Do **not** delete the run-42 worktree or branch (the run that merges BAf
  does, after the merge: `git worktree remove .claude/worktrees/loop-42-20261031-162344 && git branch -D
  loop/42-20261031-162344`).
- [ ] **Step 3 — G2 once at the cherry-picked head** (background shell): expected **569 / 0 failed / 2 opt-in skips**
  (run 42's implementer measured 569 in four filtered batches; the seat's whole-suite number is the one recorded).
  Any other number: Invariant 10, STOP.
- [ ] **Step 4 — commit** the docs: `git add docs/NEXT.md docs/LOOP-LOG.md docs/DECISIONS.md docs/QUESTIONS.md`,
  message `Run 43 reconcile: HectorKit <SHA> floor <N> (Q-B), run 42's BA cherry-picked, D45 recorded`.

### Task BAf — ⚑ MAJOR ◈ (no golden moves) — the Bat class's fix round (→ 569, asserts only)

**Scene.** Run 42 built the Bat class (commit 005058f: `Bat.swift` 786 lines, `BatTests.swift` 9 tests) and ran both
review legs: leg 1 MERGEABLE (faithful to the dump everywhere checked; three minor findings), leg 2 MERGEABLE WITH
FIXES (409 mutants, 347 killed, 22 equivalent, **40 real survivors**, all in `Bat.swift`). The run was stopped before
the fix round. This task is that fix round: asserts inside the existing nine tests (no new test, ladder unchanged),
plus the three minor findings. ⚑ audit: audit C's rows on the branch are applied here too.

**Files (worktree paths after the cherry-pick):** `Ferazel/Core/Sources/FerazelCore/World/Enemies/Bat.swift`, `Ferazel/Core/Sources/FerazelCore/World/Movers/ProgrammedPath.swift` (new — the `ProgrammedPath` pair moved out of `Bat.swift:706–781` unchanged except as below; ⚑ audit 3),
`Ferazel/Core/Sources/FerazelCore/Sprites/SpriteSlot.swift` (`pathMode` doc cite), `Ferazel/Core/Sources/FerazelCore/Front/LevelRun.swift`
(`:1155` the 0x73a… mark range), `Ferazel/Core/Tests/FerazelCoreTests/Enemies/BatTests.swift`,
`Tests/FerazelCoreTests/LevelFlowTests.swift` and `LevelThreeTests.swift` (dump cites only). Bank: `docs/ferazel/enemies-flyers.md`
(run 42 appended six ⚑ corrections — keep them).

**Contract — the survivors to pin, each as an assert in the named test (line numbers in `Bat.swift` at 005058f):**

| `Bat.swift` line | behaviour unpinned | pin in |
|---|---|---|
| :310 | the chaser arm also runs for the 1850 family (`t == 0x73a`) and the insect (`0x744`) — steering, water damage, waking | `testChaserAI` (run a 0x73a and a 0x744 chaser one frame each; assert their vx/vy change and the water damage) |
| :664 ×4 | the bat hit's blood spray: count, speed, spread, kind | `testBatDeathCoinsBlood` (assert the four `BloodSpray` arguments from the dump, M l. ~68795–68830) |
| :693–:696 | the swarm member's damage push (`vx >> 3`, `vy >> 3`), invulnerability 2, flash 8, blood count 0x28, HP > 0 boundary; :687 the player-shot check | `testSwarmMembersHome` (hit a member with a player shot: assert push, invul, flash, blood count; a shot that is not live does nothing) |
| :668 | the "uh oh" sound volume 0x100 | `testBatDeathCoinsBlood` (assert the cue's volume) |
| :419, :422, :413 | the 0x745 insect animation; the insect counter clamp at 8; the animation bound 0x6d5 | `testInsectBodyFollows` (an insect at counter 8 stays 8; a 0x745 steps its frame) · `testChaserAI` (a 0x6d5 animates, a 0x6d6 does not) |
| :465–:468 | heading wrap 35 → 0 and 0 → 35 | `testChaserAI` (two frames at the wrap) |
| :150 | the 1850 family's thrust 0x1e | `testBatSetupBySubRange` |
| :302, :304, :313 | facing when bat and player are level (`<` vs `<=`) | `testChaserAI` (player exactly level: assert the facing the dump picks, M l. ~68530) |
| :438 | vy kept when exactly on the surface line | `testChaserAI` |
| :517, :554 | the dying state's face 0; blood particle delay 0 | `testBatDeathCoinsBlood` |
| :588, :602 | swarm member `x + 12`; `abs(vy) < 0x578` | `testSwarmMembersHome` |
| :774 | `+0x194 = 0` | `testBatSetupBySubRange` |
| :749, :750, :758–:779 | path modes 10/11: the Setup zeroes `+0xf8`; **the Handle body is missing** — the dump counts `+0xf8` up, zeroes vx and vy, runs the radial updates and zeroes `+0x194` (M l. 39446–39466); and the "no radius" flag for p1 110/111 is dropped (`:719–:720`; the dump clears it so `.MakeRadial` gets radius 0, M l. 39307–39309, 39352–39368) — **⚑ run 43: wrong on the argument — the flag zeroes the swing SPEED (p3, `.MakeRadial`'s fifth argument), not the radius (M l. 39310–39313, 39354–39378, 35737–35767); built and pinned as speed 0** | `testPathBat1741` (a synthetic mode-10 path: the four writes above; a p1-110 path: radius 0) — **change** `ProgrammedPath` for both, failing assert first (⚑ audit 3, R5) |
| :187, :192 | `r >> 1` for a negative radius; the insect face cell 3 on the crate path | `testSwarmMembersHome` (negative radius) · `testKillCrateBatDropArm` (cell 3) |
| `BoxSprite.swift:1188` | the crate's record 0x200 read as zeros | `testKillCrateBatDropArm` |

**The three minor findings:** (1) dump cites: `LevelFlowTests` 68135–68140 → **68147**, `+0xa6 = 0` 68296 → **68297**;
`LevelThreeTests` 68137 → **68147**; `SpriteSlot.swift` `pathMode` doc 68733 → **68715**. (2) ~~`LevelRun.swift:1155` marks 0x73a…0x73e where the dump marks 0x73a…0x743~~ — **wrong** (⚑ audit 2): the class
dispatch (M l. 1750–1753) sends 0x73f–0x743 to the Background class; the 0x73a…0x73e range is right; no change, and the
five "survivors" on that bound (`Bat.swift:132, :418, :435, :493, :495`) are equivalent — not pinned. (3) `Bat.swift:444`'s
out-of-range face guard checks a cell index where the dump compares the face with one global placeholder pointer
(M l. 68877 — **⚑ run 43: 68882**): leave as built, add a one-line comment naming the dump's test (never fires; bank).

- [ ] **Step 1** (implementer): read `BatTests.swift` and `Bat.swift` at the cited lines; re-read M l. 68092–69079
  and 39446–39466. Add the asserts above, run `swift test --filter BatTests` — expected 9 / 0 / 0 before and after
  (asserts, no new tests); the `ProgrammedPath` change must be covered by a failing assert first.
- [ ] **Step 2** quick bot: `tools/ferazel-random-play.sh core` on levels 2–4 (quick mode); record the `== core:` line
  (run 42's: levels 3, seeds 4, steps 21,600, failures 0).
- [ ] **Step 3** commit with explicit paths: `BA fix round: asserts for the 1850/insect chaser arm, blood spray, swarm
  member hits, animation bounds, heading wrap, path modes 10/11; 0x73a…0x743 cache marks; cites`.
- [ ] **Step 4** (re-review leg, read-only): re-run the mutation set on the remaining rows (the leg's own table in
  `.looper/logs/run-42.log` — extract with the python snippet in audit C's report; audit C's per-row verdicts in
  the audit file); every row killed or ruled equivalent; `swift test --filter BatTests` 9/0/0; `--filter
  FrameGoldenTests` and `Phase2GoldenTests` unchanged; the switch-off re-done the right way (stub `Bat.handle`:
  `BootFacesTests`' two L3 rows return to `0xd4f7e113045d39a2` / `0x5a2e3d4e64f7c1ee`; revert).
- [ ] **Step 5** (seat): G2 whole suite **569 / 0 / 2**, G5, GW1, GW2 81/0/2, GW3, GW4; merge; remove the run-42
  worktree and branch; D44 "As built — run 43" paragraph; `enemies-flyers.md` corrections kept.

### Task FR — ⚑ MAJOR ◈ — Frog and Salamander (→ 577)

The card is the Phase 5 plan's **FR** (`docs/plans/2026-10-30-ferazel-phase5.md:1136–:1149`): files,
contract (enemies-water-cave §0–§2, §5–§7; Frog M l. 70111–70641, Salamander 70642–70981), eight tests, gate. Deltas
from this plan:

- Ladder **577** (plan 576 + 1).
- ⚑ audit: apply audit A's rulings on the handler no-ops (`.frog` / `.salamander` cases) and audit B's on the write-back
  flags idiom (set exactly at the dump's sites; a test row per flag the dump writes).
- The Frog's spit 0x709 is an EnemyShot type: `BootFaces` / `CachedFaces` per the Faces rule (plan l. 404–413).
- ◈: the level-2 goldens (Frogs ×2 on level 2) move only if a Frog wakes on the route — probe first (a temporary
  print, as BA did), record "none moved" if none does; switch-off check regardless — **by stubbing the Frog's Handle
  body**, not the `forClass` row (⚑ audit 1).
- Quick bot on levels 2–4; wave 5.3 is not closed by FR (BL closes it) — no GE here.

Commit: `FerazelCore: Frogs and Salamanders; 8 tests`.

**Run 43 close:** NEXT → run 44 [BL GF]; LOOP-LOG line; STATE's Ferazel bullet; D44 as-built; the Phase 5 plan's
"As executed" under BA and FR.

---

## Wave 2 — runs 44–45: the last enemy classes (Phase 5 waves 5.3 end, 5.4)

| run | tasks | cards (Phase 5 plan lines) | ladder | notes |
|---|---|---|---|---|
| 44 | **BL** ⚑ → **GF** ⚑ | BL `:1150–:1161`, GF `:1165–:1173` | 584, 591 | BL closes wave 5.3: G3, GWB by day, GE `core` on levels 1–4. GF: synthetic (levels 15+); the Wraith's reflected shot already exists (ES) |
| 45 | **DL** → **GY** ⚑ | DL `:1175–:1182`, GY `:1184–:1205` | 596, 603 | R2 (spec §4): the Dillo is an enemy class here, not a Phase 6 boss |
| 46 | **PI** → **PT** (new, minor) | PI `:1207–:1215`; PT below | 607, 607 | PI's children are Walkers, Blobs, insects — all built by then. PT closes wave 5.4: G3, GWB by day |

**Deltas from the audit:** **BL** also drops `EnemyCommon.killProc`'s Crawler / Roach / Bat / Blob arms (none of
those Setups stores a Kill proc; the default arm `+0xe9 = 1` is the original's — `EnemyCommon.swift:93–99`) and
retargets `EnemyCommonTests.testKillBookkeeping`; appends the correction to `enemy-shots-and-damage.md` §3.6 (a
reflected dart ends with `+0xe9 = 1`, no `+0x50`); fixes the five dump-line cites in `Walker.swift:352/:370/:378`
and `AxGoblin.swift:199/:207` (⚑ audit 4, 20). **GF** calls `ProgrammedPath` from `World/Movers/` (BAf moved it;
⚑ audit 3). Every ◈ switch-off = stub the Handle (⚑ audit 1).

#### PT — minor — the renderer's traps into the refusal census; the two header checks (→ 607, asserts only)
- **Files:** `Ferazel/Core/Sources/FerazelRender/Frame/TileGridRenderer.swift:286` (water table ≥ 6, tile kinds
  206–209), `FerazelRender/Frame/LightRenderer.swift:91/:252/:298/:398`, and the other `precondition` sites audit D
  lists (18 in all — `grep -rn "precondition(" Ferazel/Core/Sources/FerazelRender`), `Tests/FerazelRenderTests/DrawModeAuditTests.swift`
  (`:1076–:1079` the header checks; the census rows), `Ferazel/Core/Sources/FerazelCore/Front/LevelRun.swift` (the
  level-open refusal for `hdr+0x26c7` ∉ {0, 2, 4, 5} and for `hdr+0x2716` ≠ 0 — caught by `GameFlow.swift:555` as
  every level-open refusal, not a quit), `docs/ferazel/port-gap-ledger.md` (the draw-audit rows).
- **Contract:** every `precondition` in FerazelRender that shipped data could reach becomes a `throw Refusal.…` with
  a reason row in the audit's census (Proof B then reports a refusal, not a crashed run); one proven unreachable from
  any data stays and gets a census row saying so. The audit gains the two header checks (⚑ audit 9): the horizon
  strip (`0x2716` ≠ 0 → refused at level open until 6A-S8) and OmniPx modes 1/3/6/7/≥ 8 (refused at level open —
  today they open silently; OX's card already names this refusal, PT lands it first if PT runs before OX).
- **Tests:** asserts inside `DrawModeAuditTests` (the census row count moves by +18; the two header rows); no new
  test. **Gate:** G2 607 / 2 skips; GWB by day. **Commit:** `FerazelRender: the 18 traps become refusals with census
  rows; the horizon-strip and OmniPx header checks`.

Every card carries "Every class task also" (plan l. 414–421): Statue arm, Smite reaction, liquids/hazards, Kill
bookkeeping, idle margins, cache marks, write-back flags, the quick bot. ⚑ audit rulings that touch these classes
are listed in the audit file's rulings table by task code; the run applies them as deltas.

---

## Wave 3 — runs 46–47: level 5 and the Phase 5 end

| run | tasks | cards | ladder | notes |
|---|---|---|---|---|
| 47 | **OX** ⚑ → **LV5** ⚑ | OX `:1219–:1251`, LV5 `:1253–:1316` | 612, 618 | LV5 closes wave 5.5: G3, GWB by day, the full GE on levels 1–5 both shells. ⚑ audit E's rows on the front end (`1...5` pins, the boss-music rule) are applied inside LV5 |
| 48 | **A5** + FABLE-GRADE phase review + fixes | A5 `:1320–:1336`; the card `:1338–:1377` | 618 | both builds staged; `later: Phase 5` grep empty; the card to QUESTIONS as **Q17** (Phase 5 gate, Mac + Windows). **STOP for Ben** — the loop's next run is the planning run (wave 4), which does not wait for Q17 (D34) |

**A5 deltas from the audit:** the comment sweep also relabels the stale `later:` owners (`GroundCeilingEffects.swift:69`,
`EnemyCommon.swift:95`, `Camera.swift:46`, `BackgroundSprite.swift:498`, `StatueSprite.swift:5`) and the boss grab
(`PlayerState.swift:196`, `PlayerStates.swift:371` → "later: Phase 6"); the Windows smoke reads its three reference
hashes from `WinReferenceFramesTests.swift` (one source; `smoke-ferazel-win.sh:63–67` today) (⚑ audit 12, 15); the
Phase 5 plan's A5 gate line reads 618 / 615 (not 617 / 614); the headless-burn note (a burn with no face provider is a
no-op in headless runs only) goes into the test-harness notes (⚑ audit 7).

---

## Wave 4 — run 49 (planning run): Phase 6 research, then the 6A plan

A planning run per D34 ("one planning run = the next phase's plan"), extended: three research tasks run first (two
Opus researchers in parallel + one; each writes a document and a checker script, no game code), then the Opus
planner writes the 6A plan from them and from the cards in waves 5–7, two Opus review legs, one FABLE-GRADE leg,
fix rounds, D46 rulings, Q18 (Ben's later read).

### Task R1 — the later-level ledger (research; `fk-implementer`, docs + a script only)

**Files:** `docs/ferazel/later-levels-ledger.md` (new), `tools/ferazel/later-levels-ledger.py` (new, `-I`-safe,
reads `Resources/Ferazel/` and `docs/ferazel/gap-ledger/placements-all.tsv` and the committed dump's headers;
regenerates every table in the document), `docs/ferazel/INDEX.md` (one line).

**Contract — one section per level 10 … 70, each with:**
1. The header switches that differ from every built level (fields `0x26c6`–`0x26d0`, `0x2706`–`0x2736`, `0x284a`,
   per `world-data-format.md` §3.2), with the original routine each switches on and the port file that owns it
   (spec §3.2 table) and today's state (built / refused / not built), citing the refusal row in `DrawModeAuditTests`
   where one exists.
2. Every placed type not placed on levels 1–5 (spec §3.1 counts; the census says 23, 22, 21, 4, 17, 23, 26, 3, 21,
   26, 17, 12, 23, 19, 17, 2, 36, 2, 15 for levels 10 … 70), with its class, the port's arm (`notTranscribed` /
   `later:` site: file:line) or "built", the dump span of its Setup/Handle arm (from the 1,236 headers: `grep -n
   "==== " ghidra/ferazel/<dump>`), and the bank section.
3. The resources it needs that the port never loads today (`resources-classified.tsv` "future phase" rows:
   125 PICTs, 3 cluts, music track 29, the 20 `Mlvl` / 23 `Mcnv`), and which loader (boot list, level cache,
   the stage screens) loads them in the original.
4. The conversations (`Mcnv` ids) on it and whether the interpreter already handles every opcode they use.
5. A proposed task owner (a 6A/6B/6C card below, or a new card) — every type and switch owned exactly once.
6. ⚑ audit 19: the original's picture-cache registration order per class from `.LoadCachedSpriteFaces` (M l.
   73769–73869) and each `.Init*Sprite`, so every class / level task slots its `CachedFaces` entries
   (`LevelRun.swift:1062–1162`) at the original's position.

**Acceptance:** `python3 -I tools/ferazel/later-levels-ledger.py --check` exits 0 (every type in the census appears once;
every nonzero header field appears); the document's totals equal the census (5,641 active records over 24 levels);
reviewed by one Opus leg against the dump on three sampled levels (10, 50, 62). Commit: `Ferazel bank: later-levels
ledger (levels 10–70: switches, types, resources, owners) + checker`.

### Task R2 — the boss contracts (research)

**Files:** `docs/ferazel/phase6-boss-contracts.md` (new), ⚑ corrections appended to `bosses.md`, `bosses-2.md`,
`bosses-3.md` where the dump disagrees, `docs/ferazel/INDEX.md` (one line).

**Contract — for each of the Warrior (M l. 72975–73532), Chief, Wizard, Demon, Xichra (spans from the headers; the
bank's `l.` numbers are the old 64,189-line dump — re-map every one):** the Setup's writes in dump order (as LV5's
Files list does for the Warrior); the Handle's state machine as a table (state → entry, per-frame, exit; the random
draws in order; the sounds; the shots spawned with their EnemyShot types; the children); the Hit routine (what hurts
it, bosses §1.5); the Kill's writes (the four of bosses §1.4 + any class extra); the Init's cache sets; the arena
and music rules it relies on (already LV5's); for Xichra also the three cannons, the minions (0x6d6 record 500), the
lair gates (p1 = 0), the CLUT animation of level 67 (bosses-3 §8–§9) and the hand-off to `.Victory`. Each contract
ends with the **test list** its build task will carry (names + the number each pins) and a scripted-keys kill
scenario (seed, keys, expected frame of death) the build task turns into `test<Boss>ScriptedKill`.

**Acceptance:** every routine in `routines-classified.tsv` with "phase 6 (boss)" or "boss face cache registration"
appears in exactly one contract (52 rows); one Opus leg re-derives two states per boss from the dump. Commit:
`Ferazel bank: Phase 6 boss contracts (Warrior, Chief, Wizard, Fire Guardians, Xichra) from the dump`.

### Task R3 — the engine-feature contracts (research)

**Files:** `docs/ferazel/phase6-engine-contracts.md` (new), ⚑ corrections to `rendering-omnipx-titles.md`,
`lighting-tables.md`, `draw-effects.md`, `particles.md` where the dump disagrees, `docs/ferazel/INDEX.md`.

**Contract — one section per feature of spec §3.2 not built by Phase 5:** OmniPx rain (mode 1) and interlace (mode
6), the horizon strip (draw mode 8, `.BlitEncFaceBehindTiles*`), wind cells (`.LookupModedImpulse`), the parallax
ripple, the constant side push, auto-scroll (x, y, the marker sprites), the fire backdrop and flame buffer (the
eight `.Flame*` / `.My*` routines, `.LoadCoolingMap`, the fire variant of `.DoubleBlitUniversal`), CLUT animation
(`.AnimateCLUT`, bosses-3 §9), the level-wide liquid flag and the tinted submerged tiles, the countdown digits, the
programmed-path cannon/mace arms, rope bridge, trees, clouds, the rotating blade (`.SectLineSegs`), falling rocks,
spiked balls, carpet, snowball, table, water kinds 206–209, `.Victory` + stitch + credits. For each: the dump span,
the header/type that switches it, the port module and the exact seam change (a `DrawOp` case? a `ScreenGammaOp`?
none?), the first level that shows it, **the golden plan** (which level, which frame, both shells' references), the
test list, and the Phase (6A/6B/6C) it belongs to.

**Acceptance:** the 27 "later-level" routines and the Phase 6 "not built" non-boss rows of `routines-classified.tsv`
each appear once; one Opus leg re-derives OmniPx mode 1's rain generator and the CLUT animation's step from the dump.
Commit: `Ferazel bank: Phase 6 engine-feature contracts from the dump`.

### Task P6A — the Phase 6A plan (the planning run's product)

Written by the Opus planner from R1–R3 and the cards in wave 5, in the shape of the Phase 5 plan (Verification
model with the gate commands, invariants, Shared architecture additions, tasks with Files/Contract/Tests/Gate/Commit,
Execution order, Carries, Known deviations, Rulings → D46, Review ledger); two Opus legs + FABLE-GRADE leg; saved as
`docs/plans/2026-<date>-ferazel-phase6a.md`. Its first task is the Warrior (replacing LV5's stand-in, R6). The 6B and
6C plans are written by their own planning runs at the end of 6A and 6B, from R1–R3 and waves 6–7's cards.

---

## Wave 5 — Phase 6A (cards; expanded by P6A after R1–R3)

Gate: **"through the Goblin Chief"** — levels 1–22 playable, the Warrior and the Chief beatable, Mac and Windows.

| card | what | files (today's owners) | acceptance |
|---|---|---|---|
| 6A-BL built-level list (first task of 6A; ⚑ audit 8) | `BuiltLevels` becomes an explicit list of the built level ids (`[1, 2, 3, 4, 5, 10]` …) with `contains`; `NewGame.swift:66/:275–284`, `ContinueGame.swift:134–141`, `Shared/FerazelDriver.swift:44` (`-FerazelLevel`, both shells) read it; the bot and the sweep (`ferazel-random-play.sh:62/:76`, `ferazel-visit-sweep.sh`) take the list from a printed source, not `sed`/`seq`; the tests pinned to a range move (`GameFlowGameTests.swift:247–260/:458–487/:691–699`, `LevelFourTests.swift:156–199`, `LevelThreeTests.swift:8/:390`, `BootFacesTests.swift:281`, `FaceTests.swift:596–602`) | `Front/BuiltLevels.swift:9`, the readers above, both scripts | every reader compiles against the list; the bot runs on `[1…5, 10]` |
| 6A-FB the fireball cache (⚑ audit 5, before 6A-W) | picture 0x46a is cut three ways (48×48 for 0x46a; 64×64 twice for the dead types 0x46b / 0x46c, M l. 51822–51861) but cached by picture: key cached faces by record | `World/Enemies/EnemyShot.swift:381/:400`, `Front/LevelRun.swift:1216–1251` | a test that the three cuts differ and 0x46b draws the 64×64 cut |
| 6A-W Warrior ⚑ | the real Handle / Hit / Kill replacing LV5's stand-in: eggs, random attacks, the three falling crates (0x433 into `+0x1d4/+0x1d8/+0x1dc`), the kill's four writes, the gate opens, track 30 (R6) | `World/Enemies/Warrior.swift`, `BossArena`, `LevelRun.swift` (music), `Tests/.../Enemies/WarriorTests.swift` | the scripted-keys kill test; LV5's goldens return with the Handle stubbed (switch-off) |
| 6A-FR falling rocks 0x433/0x434 | the Warrior's crates and the rocks' player arm in `.HurtPlayer` | `World/Movers/BoxSprite.swift`, `Player/HitPlayerSprite.swift` | built with 6A-W or just before |
| 6A-S8 horizon strip (draw mode 8) ⚑ | `.BlitEncFaceBehindTiles{Clip,NoClip}`, the `Px` strip sprite from `hdr+0x2716/18/1a` | `FerazelRender/Frame/SpriteBlitter.swift` (the refusal row), `ParallaxBlitter.swift`, `DrawModeAuditTests` (PT's `0x2716` header check becomes a draw check) | level-10 first-frame golden; the audit row moves to "drawn" |
| 6A-WD wind cells | `.LookupModedImpulse` on the overlay cells | `Player/PlayerTiles.swift`, `Physics/` | level-10 test rows |
| 6A-RP parallax ripple ⚑ | `.RipplePxBackOffsets` for levels 11, 18 | `ParallaxBlitter.swift` | level-11 golden |
| 6A-RN OmniPx rain (mode 1) ⚑ | `.GenerateRain` + overlay faces 6000/6001; the side push `0x272c` | `World/OmniPx.swift`, `Camera/`, `DrawModeAuditTests` (PT's mode-1 refusal becomes a draw check) | level-15 golden; push pinned |
| 6A-T11 tinted submerged tiles | `hdr+0x26c6` in `.PlainWrapFGTile` / overlay | `FerazelRender/Frame/TileGridRenderer.swift` | level-11 golden |
| 6A-BG1 Background types of 10–22 (42 new, R1 lists them) | trees 0xc08…, clouds 0xb4a…, the rotating blade 0xbf4 (`.SectLineSegs`), 1091–1097, 1150–1153, 1840/1843, 1900–1903, 2700–2711, 2890–2893, 3080–3084 | `World/Movers/BackgroundSprite.swift` | each type's Setup/Handle rows; split by R1 into 2–3 tasks |
| 6A-BX1 Box types of 10–22 (R1) | geysers 1440 (GY built), pipes (PI built), 2808–2876…, 1060/1061/1080, the programmed-path cannon/mace arms (R5) | `World/Movers/BoxSprite.swift`, `World/Enemies/Bat.swift` (`ProgrammedPath`) | split by R1 |
| 6A-BN1 Bonus / Platform / Rope types of 10–22 | 1290–1339, 3050…3223, Platform 1404/1407, Rope 3020 | `BonusSprite.swift`, `PlatformSprite.swift`, `RopeSprite.swift` | — |
| 6A-L10…L22 levels enterable (R4: one or two levels a task) | 10, 11, 15, 18, 20, 21, 22 — every record set up, cache marks, load bar, `Level<N>Tests`, the sweep and the bot extended | `Front/BuiltLevels.swift`, `LevelRun.swift`, new `Level<N>Tests.swift` | `testLevel<N>SetsUpEveryRecord`; bot quick mode 0 failures |
| 6A-CH Goblin Chief ⚑ | R2's contract; the boss grab (`PlayerStates.swift:371`, `PlayerState.swift:196`) | `World/Enemies/Chief.swift`, `Player/PlayerStates.swift` | scripted kill test; level-18 arena rows (second bound −640) |
| 6A-MC conversations + chapter cards for 10–22 | the `Mcnv` ids and cards R1 lists; the resources loaded as the original | `Front/StageScreens.swift`, `Talk/` | the card goldens |
| 6A-END phase end | GE both shells over levels 1–22, Proof B, Fable review, both builds staged, the card → Ben (Q19) | — | — |

## Wave 6 — Phase 6B (cards; expanded by its planning run)

Gate: **"through the Wizard and the fire"** — levels 25–52 playable.

| card | what |
|---|---|
| 6B-WZ Wizard ⚑ | R2's contract (eleven states, projectiles); level 25's arena bounds 592 / 1384; OmniPx on 25 (built, OX) |
| 6B-ICE levels 30/31 | the level-wide liquid flag `0x26cd`, ice friction 220, the ice types (R1) |
| 6B-TM countdown digits (level 40) | `.UpdateDigits`, the 2907 timer, the digit Effect ids |
| 6B-CA CLUT animation ⚑ | `.AnimateCLUT` (bosses-3 §9): levels 50, 51 (and 67 later) — a Render-side op on the current CLUT |
| 6B-AS auto-scroll ⚑ | `0x2726`–`0x272a`, the marker sprites of `.SetupLevelSprites`, `.FindUpperLeftCorner`'s arm; levels 51 (x), 52 (y) |
| 6B-FI fire backdrop + flame buffer ⚑ | `.LoadCoolingMap`, the eight flame routines, `.DoubleBlitPPCParallaxOneLayerFire`, `.MyRandom` (its own generator); level 52 mode 1 |
| 6B-BG2 / BX2 / BN2 | the Background / Box / Bonus / Platform / Rope types first placed on 25–52 (R1) |
| 6B-L25…L52 levels enterable | 25, 30, 31, 40, 45, 50, 51, 52 (R4) |
| 6B-MC | conversations + cards for 25–52 |
| 6B-END | phase end, gate card → Ben |

## Wave 7 — Phase 6C (cards)

Gate: **the whole game** — levels 55–70, the Fire Guardians, Xichra, victory.

| card | what |
|---|---|
| 6C-DM Fire Guardians ⚑ | R2's contract: two guardians (partner at x − p3·32), segments, fire mode 2 backdrop; the arena never locks (bosses-3 §11); +1000 score each |
| 6C-BG3 / BX3 / BN3 | the 36 types of level 62 and the rest (R1): Background ×16, Box ×8, Bonus ×8 … |
| 6C-L55…L70 levels enterable | 55, 62, 67, 70 (R4); level 70's OmniPx interlace (mode 6, `.InterlaceBlit128`) ⚑ |
| 6C-XL Xichra's lair ⚑ | the three cannons, the minions (0x6d6, record 500), the lair gates (p1 = 0), the CLUT animation of 67 (bosses-3 §8) |
| 6C-XI Xichra ⚑ | R2's contract: float, wings, phases, `.DoXichraShot`, `.UpdateXichraCannons`; the kill ends the game |
| 6C-VI victory (R8) | `.Victory`, `.CopyVictoryStitch`, `.CreditScreen` as a `GameFlow` state; music track 29; a golden per screen |
| 6C-END | phase end over all 24 levels both shells; the three invented gates (New Game clamp, map refusal, Continue refusal of unbuilt-level saves — the original has none) deleted now that every level is built (⚑ audit 8); the "whole game" card → Ben |

## Wave 8 — release (attended session, after Ben's whole-game verdict)

| card | what |
|---|---|
| REL-1 | `tools/package-ferazel-release.sh` from `tools/package-btx-release.sh` (Developer ID sign, notarize via notarize-kit, staple; the Windows zip from `stage-ferazel-win.sh`); `CFBundleVersion` 1.0; `docs/release/ferazel-1.0.md`; the assets + `.sha256` copied to `releases/ferazel-1.0/` in the **main** checkout; README download links. Ben tries the downloaded DMG → "publish" (D25's shape). |

## Standing cards (not scheduled; the seat schedules one when its trigger fires)

| card | trigger | what |
|---|---|---|
| HK-REPIN | HectorKit main moves (Castles, Deimos) | reconcile per G1's rule; record SHA + floor |
| NOTES-FIRST | Ben answers a gate with notes | a small named wave of fix tasks goes before the next scheduled wave (D39's shape) |

---

## Self-review (seat, 2026-11-04)

1. **Spec coverage.** §3.4 Phase 5 remainder → waves 1–3 ✅; §3.1/§3.2/§3.3 → R1–R3 then waves 5–7 (every level,
   feature and boss has a card; the per-type split is R1's) ✅; §4 rulings R1–R8 → wave 4's P6A instructions and the
   cards (R2 wave 2, R3 the engine cards, R4 the level cards, R5 BAf/6A-BX1, R6 6A-W, R7 the gates table, R8 6C-VI)
   ✅; §5 proofs → the gate table + each card's acceptance ✅; §6 questions → RC (Q-B, Q-C), wave 5–7 cut (Q-D),
   wave 8 (Q-E), NOTES-FIRST (Q-A) ✅; §1.4 the drift → G1 + RC ✅.
2. **Placeholders.** None: every wave-1 step has files, lines, tests, expected numbers and a commit message; waves
   2–3 point at bite-sized cards that exist; waves 5–7 are cards by design (expanded after R1–R3), each with files and
   an acceptance line.
3. **Names.** `BossArena.noBossAlive`, `BuiltLevels.range` (→ a list at 6A-BL), `CachedFaces`, `SpriteHandler` cases,
   `ProgrammedPath` (→ `World/Movers/` at BAf) — as in the Phase 5 plan's S2 and the code at 07bc11d / 005058f.
4. **Audit applied (2026-11-04).** Rulings 1–22 of the audit file: §0 (1, 11, 14, 15), BAf (1–3), FR (1), BL (4, 20),
   PT (9, 10), A5 (7, 12, 15), R1 (19), 6A-BL / 6A-FB (5, 8), 6C-END (8); the visit sweep's summary line is at
   `tools/ferazel-visit-sweep.sh:91` (the Phase 5 plan cites `:75`).
