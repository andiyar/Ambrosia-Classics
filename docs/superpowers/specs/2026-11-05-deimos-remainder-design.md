# Deimos Rising — the remainder: rest of Phase 2, then Phases 3–5 — design (re-planning pass, 2026-11-05)

> Status: **DRAFT for Ben** (seat: Claude Fable 5.1, re-planning pass per `~/Developer/Toolkits/fable-kit/replan.md`).
> Written after reading the design (`docs/plans/2026-10-06-deimos-design.md`), the Phase 0, 1 and 2 plans and their
> reviews, the handoffs, DECISIONS D22–D31 (D31 and its addendum live on branch `deimos-phase2`), the research bank
> `docs/deimos/` and the branch's code. Nothing was built in this pass. The questions for Ben are §10; the build
> proceeds on the recommendation in each until he answers.
>
> Companion documents: the plan `docs/superpowers/plans/2026-11-05-deimos-remainder.md` and the audit
> `docs/superpowers/audits/2026-11-05-deimos-phase2-audit.md`.

## 1. Where the port stands (the review, measured 2026-11-05)

Every number below comes from a command the seat ran on 5 November, not from STATE.

| Phase | State | Evidence |
|---|---|---|
| 0 Data + decoders | done, on main | D24 as built; census 872/0 inside the suite |
| 1 Level 1 look | done, gate 1 passed by Ben 7 Oct | D30; main `Deimos/Core` suite passes (count below) |
| 2 Level 1 plays | **part built on branch `deimos-phase2`, unmerged since 7 Oct** | 44 commits; waves 2.0–2.5 built and reviewed; wave 2.6 (destruction and removal, end of level) built with three review legs owed; waves 2.7–2.12 (C12, C18a, C18b, H2, H3, A3, A4, F1, B1) not started |
| 3 Campaign | not started | design §8 |
| 4 Front end | not started | design §8 |
| 5 Windows + release | not started | design §8 |

Test runs by the seat:

| Suite | Result |
|---|---|
| branch `Deimos/Core` against **current** HectorKit main (ef2c341) | 313 passed, 0 failed, 0 skipped |
| branch `Deimos/Core` against the **pinned** HectorKit e595472 (through a `HectorKit`-named symlink: a kit worktree folder named `deimos-k2` does not resolve as the package `HectorKit`) | 313 passed, 0 failed, 0 skipped — identical |
| main `Deimos/Core` | 189 passed, 0 failed, 0 skipped |
| main `Deimos/DeimosCore` | 189 / 0 / 0 — the same package: it is a **symlink** to `Core` (see §1.2) |
| HectorKit zero-skip gate at e595472 | executed 328 = 324 passed + 4 skipped, 0 failed |
| HectorKit zero-skip gate at current main ef2c341 | executed 370 = 366 passed + 4 skipped, 0 failed |

The four kit skips are the Aki 1.1 census tests: the folder `HECTORKIT_DATA_AKI11` points at no longer exists on this
machine. A kit-side data path, the same at both commits; not a Deimos matter.

### 1.1 Why the sessions churned (diagnosis)

Unlike Castles, the Phase 2 plan was not thin: it is 1,132 lines of contracts with line anchors and test names, and
two review legs fixed it before execution. The churn had three other causes:

1. **Parallel waves found their seams at review time.** Waves 2.4 (C9 ∥ C10 ∥ C14) and 2.5 (C11a ∥ C15 ∥ C19) ran three
   tasks at once on one `GameState`. Each review then found a seam between siblings: which state value gates owner
   links and collisions (the state read *before* the motion controller), two copies of the nearest-player helper, two
   sources of the sector number, a stub whose dropped out-parameter mattered, walkers that still called a stub. The
   plan was amended in place five times; the amendments all land on C12 and C18a, the tasks that join the pieces.
2. **One day, one seat, 44 commits.** The orchestrator built sixteen tasks and ran twenty-odd review legs in one
   session, and stopped with wave 2.6 built but three legs unreviewed. Nothing was wrong with the work; the session
   ran out.
3. **A ledger that was never applied.** Forty-odd corrections to the research bank were parked for the end-of-phase
   task B1 (D31.11). Every later implementer and reviewer reads a bank that is known to be wrong in those places.

Since then the kit moved (HectorKit e595472 → ef2c341: the gamepad input layer, SDL gamepads, a second scaling
policy, 7 commits) and a month passed. The branch still passes against the current kit, so the drift is small at the
library level; the app build is unchecked until the next wave's gate.

### 1.2 The two package folders

`Deimos/DeimosCore` is a symlink to `Deimos/Core` (git mode 120000, D29 as-built): SwiftPM names a local package after
its folder, and `Aki/Core` already took the name "core", so `project.yml` reaches the Deimos package through the
symlink. **Ruling: `Deimos/Core` is live; the symlink stays; nothing is duplicated.** The survey's "duplicate layout"
was a misreading of `ls`.

## 2. What is being built (unchanged from the design, restated)

The whole game, Mac and Windows (D27.1): twelve sectors, every unit and weapon, tallies and bonuses, the finale,
one- and two-player games, the front end (logos, menu, level select, scores, name entry, credits, attract demos,
Last Film, the configuration dialog), the console with the ten commands 1.0.6 registers. Replicated 100 %, no
modern affordances (CLAUDE.md). Out of scope stays out: the level editor, registration, the website link, the HID
bundle, the debug-only console commands, iPad, Remaster art.

## 3. The shape of the whole program — one state model

Four kinds of state, each owned by one layer. The rule that mattered most in Phase 2 and holds for the rest:
**the simulation is one value, `GameState`, and every rule is a method on it taking indices.**

| State | Type | Owner | Lifetime |
|---|---|---|---|
| **The simulation** | `GameState` (flags, scroll, entity world, two players, score bar, particles, debris, blurs, notice, messages, cues, film cursor, trace, media mask, tally, tick ops) | DeimosCore | one game session (`FUN_100051a0`), **across its levels** from Phase 3 |
| **The frame** | frame controller, console, key table, score-bar drawer, pending ops | `DeimosSession` (DeimosCore) | one session; reset at level transitions as `FUN_100302e0` does |
| **The front end** (Phase 4) | menu buttons and elements, level-select state, scores/name-entry screens, attract counter `G+0x24`, suspended/quit flags | `FrontEnd` (DeimosCore, new) | the app's life |
| **The prefs** | `DeimosPrefs` (the 0x34f0 record) | DeimosHost owns the file (Phase 4); the session reads/writes the live copy | the app's life, saved at quit |

The driver (`DeimosHost`) is the only thing that sees a clock. It runs **screens** in the order the original's
`FUN_100000a0` → `FUN_100229a0` → `FUN_100234d0` → `FUN_100051a0` call chain does: boot → menu ⇄ (level select →
game → scores) and attract films. Each screen is a resumable state machine that yields at the original's
`TickCount` waits. Phase 2 gives the driver one screen, the game session, with ◇ stand-ins for the rest (S9); Phase 3
makes the session multi-level; Phase 4 adds the other screens.

Layers and seams are LOCKED (D29.1): `DeimosCore` (Foundation + HectorResources + HectorAudio), `DeimosRender`,
`DeimosAudio` (D31.1), `DeimosHost`, thin shells. Seam types grow by added cases only. Nothing in this pass changes
the layering.

## 4. The rest of Phase 2 — what is left and how it fits

Built and reviewed (waves 2.0–2.5): the seams, the effects mixer and music streamer, particle stamps, particles/
debris/blur, notices and messages, trig/entity world/`GameState`, spawning, motion and animation, the state machine,
the player, collisions and damage, weapons, begin-frame keys and the console. Built, three legs owed (wave 2.6):
destruction/removal/media gate/terrain stamps (C11b), end of level (C17).

Left, in the order the plan's critical path needs them:

| Task | What it is | Why it is next |
|---|---|---|
| the owed legs + fix round | C11b two legs, C17 second leg, then one fix round | nothing after C12 can be trusted until the pieces it joins are reviewed |
| bank corrections (was B1) | apply the ~40 corrections in the handoff and the plan's 8 to `docs/deimos/*` now | C12 and C18a implementers read the bank; it must be right first (§6 ruling 3) |
| **C12** — the entity update, the world update, the entity draw | the per-entity step order of `FUN_10033850` and the per-tick order of `FUN_10006b50`; the group draw. **From the audit:** the loop iterates with the same-pass `Walk`; the state-sound step with its pitch draw; one nearest-player helper (Motion's); the group draw's terrain branch for states that draw to terrain every tick (bomb craters, tank tracks) and the `lastStampTime` field (+0x90) that makes the sweep's stamp test real; the "Reached Motion Blur Limit" message; the player-ram redirect is already built and is struck | the join of every wave-2.4/2.5 piece; alone in its wave |
| **C18a** — `DeimosSession` Phase 2 | full level start, the loop with update/draw/end frame in the original order, film playback, pause. **From the audit:** the level start calls the tally reset, the ground-count reset and each player's level start in `FUN_100064d0`'s order; the pass moves and clears the game's cue buffer into the pass output (one holder); the music-level cue at session start; the mask loader proves tight rows; `Player.sector` retired | the join of C12 with the frame layer |
| C18b | delete the Phase-1 player stub; early de01 report | tidy-up once C18a has taken over |
| H2 | driver Phase 2: pause wait, cue routing, typed keys, Esc latch on any idle, headless runner, replay trace | the host half of film replay |
| H3 | `deimos-replay` and the de01 gate | the machine gate |
| A3, A4 | app audio/keys/`-film`; stage + gate card | Ben's gate |
| F1 | replay triage, only if G4 is red | D31.10 |

The Phase 2 plan's contracts for these tasks stand, with its five amendments and the audit's rulings folded into the
new plan's next wave (the plan is the authority for files, anchors and tests).

## 5. Phases 3–5 — the shape (cards; each expands in its own plan after its research)

### Phase 3 — the campaign (gate: de02–de04 replays; Ben plays through)
- **Level transitions inside one session** (level-scroll-objects §8, loose-ends-session §6): level complete →
  stop music → `tran` → the 33-step fade to black (a host wait) → frame-controller reset → `FUN_100064d0` for sector
  + 1 (game time 0, players' level start, pending list, load pass, notice, score bar, first terrain blit) → the next
  level's appear tick starts its music and the 9-step fade in. Sector 13 → tag `none` → session ends.
- **What carries and what resets between levels** (the §8 table): lives, next extra-life score, score carry; coins
  reset; weapons re-picked per sector; dead players stay out; invulnerability carry-over as read (Q5, Ben's eyes).
- **Game over → session end** already in C17; the finale (`noal` → `12gc` → `miof` chain, loose-ends-session §5, 1,200-
  frame tally wait, mission bonus) at sector 12 of a run from sector 1.
- **Two players in the app**: the second key set, the solo-vs-duo start positions, the shared view shift
  (player-physics §8), score-bar two-player layout (hud-scorebar §8).
- **Random bonuses and extra lives** are already generic (C11b, C14); Phase 3 proves them over more data.
- Proof: `deimos-replay --all`: de02 116,180 at read 8,357 (le06), de03 57,520 at 10,058 (le02), de04 24,670 at 5,649
  (le08) — each a one-level session (a film replays only its start level); the campaign itself is proven by a
  headless run through the twelve sectors with a bot that only survives (bounded), and by Ben.

### Phase 4 — the front end (gate: Ben: cold start → game → scores → quit)
- Boot: the loading screen and progress lines, logos (`pucr`/`publ`, developer logo + `inmu`), the fade lengths of
  front-end §5 and the worked example.
- Main menu (`FUN_100229a0`): buttons, hover strip, copyright/registration flip (the registered banner), keyboard,
  the event pump's part the replica needs (keys, clicks, quit), menu bar.
- Level select (`FUN_1002e310`, scoring-bonuses §10): previews, unlock by int pref 3, the accept/fail flash (#62).
- Scores, name entry, easter eggs; credits (paged); attract mode cycling the "Demo" films with `G+0x24`; Last Film
  save after every non-film session and its tag-index rebuild.
- The prefs file (0x34f0 layout, obfuscation kept, Application Support path — design §7.5) read at boot and written at
  quit; the configuration dialog (DITL 190) and the controls window (DITL 191, Q8) drawn by the replica.
- Mouse enters `HeldKeys` (the film is ended by a click too; S9.8).
- Proof: screen goldens per screen against the TGAs; the worked cold-start timeline in ticks; Ben's eyes.

### Phase 5 — Windows + release
`Deimos/Windows` on HectorSDL over the same libraries (Ferazel's Phase W is the template: `FerazelWin`, the mute
switch, Proof B); a drawn DITL dialog (candidate kit lift of BTXWinKit's renderer); staged for Ben's brother;
notarized DMG + Windows zip (BTX D25).

Sizes (from Phase 2's measured cost of about three dispatches per task): Phase 3 ≈ 6 tasks, Phase 4 ≈ 10, Phase 5 ≈ 5.

## 6. Faithful, rulings, switches

| Kind | Items |
|---|---|
| **Faithful** (the listing decides; a test pins it) | every rule in §4–§5; the RNG draw order at every site; float fidelity (fused multiply-adds, truncation); the 16-voice mixer; the film format and replay rules; the prefs layout |
| **Rulings** (the seat's, recorded; disclosed on the gate card) | design §7's deviations (whole-frame presents, no OS volume writes, no InputSprocket, registered build, prefs path, Last Film path, debug alert); D31's uninitialised-memory divergences (refused indicator +0xb8 = −1, PERM +0x9c/+0xa0 = 0, flee target (0,0)); `AllowOnlyOneInstance` = "not playing" (dead in data); cue routing at pass begin (≤ 1 frame early); pause music resumes on the pass after the wait |
| **New rulings this pass** (§7) | the audit discharges the owed legs; bank corrections now, not at B1; merge after the fix round; current kit |
| **Switches** (Ben's choices, kept as data) | `TickRate` (.osx by D30); scaling policy (.integerFit by D27.3); `-film deNN` (◇, replaced by attract mode in Phase 4); a gamepad mapping (Q-E, if Ben wants one) |
| **By ear / by eye** (on gate cards, never machine-settled) | pitch direction (Q2), music loudness (Q3), invulnerability carry-over (Q5), the 24→16 colour cut, particle shades, title upright |

## 7. Rulings this pass makes (recorded in DECISIONS when Ben has seen them)

1. **The audit discharges the three owed review legs.** The five audit reviewers (Opus 5.5, read-only) each carry the
   questions those legs would have asked (C11b: listing/RNG leg and spec/tests/seams leg; C17: spec/tests leg) and
   re-run the tests. Their findings become the next wave's first fix round. No separate legs are run.
2. **Bank corrections are applied in the next wave, as a docs task**, not at the end of the phase (changes D31.11).
   One Opus implementer edits `docs/deimos/*` from the handoff's list and the plan's eight items, each as a ⚑ note
   with its address; one reviewer checks every note against the listing. Implementers of later tasks keep reporting
   corrections in PR notes; the orchestrator applies them at each wave's close.
3. **`Deimos/Core` is live; `Deimos/DeimosCore` is its symlink** (§1.2).
4. **HectorKit: build against current main from now on** (Q-B recommendation; floor re-measured in the plan). The pin
   e595472 was the K2 landing, not a constraint.
5. **The next wave is fenced** to: the fix round, the merge, the bank corrections, C12, C18a — two orchestrator
   sessions (the cap is the seat's context, orchestrator.md §5; MAJOR tasks ≈ one seat each).
6. **The audit's verdict (2026-11-05):** every rule re-derived matches the oracle; zero rows ruled redo; 23 rows
   ruled change (code, doc or test strength, all in the fix round) and 12 ruled missing (seams, all written into the
   C12 / C18a / H2 briefs). The three owed legs are discharged by it. Two data facts settled from the decoded units:
   two shipped units draw to terrain every tick (craters, tank tracks — reachable in level 1), and no cyclic state
   has a max speed below 1.

## 8. How each part is proven

| Part | Proof | Who closes it |
|---|---|---|
| each rule | transcription tests pinning the bank's number by bit pattern, first review leg re-derives from the listing/dump | reviewers |
| the joins (C12, C18a) | order tests through a step log; the le07 controller timelines (`01m1` created 1660, pause 1840, frozen top 1279 for 800 ticks; `01b1` at 346) | reviewers |
| level 1 plays | **G4**: de01 replays to 25,050 at the read of byte 4808 (`FilmCursor.score(player: 0, atRead: 4808)`); miss path D31.10 (pending trace → F1; "predates the code" only after two reviewers agree) | H3 + the seat |
| the campaign | de02–de04 (information in Phase 2, gates in Phase 3); a bounded twelve-sector headless run | Phase 3 |
| the look | frame goldens + independent pixel oracles (design §9.3) | reviewers |
| feel, sound, look | Ben at each gate card | Ben |

## 9. The HectorKit re-base

| | Pinned e595472 (floor 328) | Current main ef2c341 |
|---|---|---|
| what changed | — | HectorInput + `ShellGamepad` + `ShellView.padMapping` (nil default: Deimos unchanged), HectorSDL gamepads, `ShellScalingPolicy.aspectFitNearest` (Deimos keeps `.integerFit`), README |
| branch suite | 313/0/0 | 313/0/0 |
| app build | built 7 Oct | unchecked; G5 in the next wave |

Recommendation: current main. The K2 API (`PCMPullSource`, `ShellMixer.attachStream`, `SDLAudioOut(source:)`) is
unchanged since the pin. The one new thing worth taking is the gamepad layer (Q-E).

## 10. Questions for Ben (each with the recommendation the build proceeds on)

| # | Question | Recommendation | Why |
|---|---|---|---|
| **Q-A** | Merge `deimos-phase2` to main **before** the next wave or **after** it? | **after the fix round, before C12** — i.e. the merge is the next wave's second task | the audit stands in for the owed legs; once its fixes land the whole branch is reviewed work and "never park verified work" applies; main has touched nothing under `Deimos/` since the branch |
| **Q-B** | HectorKit: stay on the pin e595472 or move to current main? | **current main** | the branch already passes 313/0 against it; the pin was only K2's landing commit |
| **Q-C** | The two package folders | **no action**: `DeimosCore` is a symlink to `Core` | §1.2 |
| **Q-D** | Phase order after Phase 2 (design Q7, never answered): campaign first, or front end first as Ferazel did? | **campaign first (3), then front end (4)** | the de02–de04 films prove the campaign by machine; the front end is self-contained and proves only by eye |
| **Q-E** | A game controller for Deimos, as Bubble Trouble X (D36) and Ferazel (D37) now have? | **yes, in Phase 4 with the controls window**, as the original's keys | the kit has it for two games; Phase 2 does not need it |
| **Q-F** | Reviews: Opus only (your 7 Oct rule) stays? | **yes**; Fable only at the phase-end cross-check (CLAUDE.md model policy) | this pass is the Fable cross-check for Phase 2's plan and built work |

Not re-asked: Q2 pitch, Q3 music level, Q5 invulnerability (gate card, by ear/eye); Q8 controls window (Phase 4,
default: build DITL 191).
