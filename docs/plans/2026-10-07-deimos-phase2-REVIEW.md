# Review record — Deimos Rising Phase 2 plan (`2026-10-07-deimos-phase2.md`, reviewed at a70a37d)

Two Opus review legs, 2026-10-07, both **ACCEPT_WITH_FIXES**. One fix pass by the planner applied every finding except
one (rejected below, with evidence), under the orchestrator's rulings 1–9. Leg files (session scratchpad, not
committed): `review-legA.md` (probes `legA/`), `review-legB.md` (probes `legB/`).

| leg | focus | verdict | Critical / Important / Minor | claims checked and passed |
|---|---|---|---|---|
| A | fidelity vs bank, listing and data | ACCEPT_WITH_FIXES | 1 / 9 / 15 | **85** (every probe p11–p18 reproduced; de01–de04 decoded independently; RNG audit: 20 int / 4 float RandomRange callers, all owned except the two in C-1/I-2) |
| B | executability vs code and HectorKit | ACCEPT_WITH_FIXES | 2 / 17 / 16 | baseline re-run **189/0**; ladder and test names checked; every seam/type name the plan uses exists; D31 free on origin/main; `PCMMixer` conformance compiles as written |

## Orchestrator rulings applied
1. HectorKit main 4ca2e18, floor 322 (Cythera K1 landed) → G1 expects **326**; K2 Files gain HectorKit `Package.swift`
   (HectorShell → HectorAudio); K2's G5 adds an AkiPad simulator build.
2. Gate commands moved into a fenced code block with real `|` (the table keeps names and expected values).
3. `GameState` storage: C7 declares the complete stored-field table incl. placeholder sub-structs (`MediaMask`,
   `TallyState`, `FilmCursor`, `TickTrace`) and `tickOps: [RenderOp]`; index-based API; invariant 13 (a task alone in
   its wave may add fields; a parallel task STOPs and reports).
4. C11 → C11a (collision/damage/pickups) + C11b (destruction/removal/media/terrain stamps), different waves; C18 →
   C18a (session loop, film playback, re-pointed session/frame tests) + C18b (stub removal, re-pointed player tests, the
   early de01 report); waves re-sequenced so a split pair never shares a wave or a file; ladder recomputed: G2 **338**,
   G4 bundle 3.
5. G4 miss path: H3 lands the gate in a separate bundle (`DeimosReplayTests`, excluded from G2 by `--skip`); a red G4
   is recorded "pending trace" and opens **F1 — replay triage** (orchestrator-owned; fixes as `fix(<task>)` under that
   task's Files); A4 may stage with the gate pending and Ben's `-film de01` viewing on the card.
6. Bank corrections: one owner, **B1** (orchestrator-run, after A4); implementers report corrections in PR notes only.
7. Q4 volume keys: one switch `VolumeKeyBehaviour` (C19; A2 applies only what arrives) with both variants specified,
   **default OS X** (D30) pending Ben. Note: the ruling said "OS 9: ±10 steps from 90"; the plan writes "from the
   pref's value (fresh prefs 50; the boot quantisation turns 100 into 90)" — sound-music §4.2/§4.4: int pref 0 defaults
   to 50 and only a stored 100 becomes 90 at boot. Flagged for the orchestrator.
8. D31 reserved; free on `origin/main` (b4616d0) at the fix pass — re-verify at commit.
9. This record written; plan header updated.

## Leg A — dispositions
| id | finding | disposition |
|---|---|---|
| C-1 | animation step `FUN_10015930` (random-frame `R` at `10015a0c`) missing from C12's order and the RNG owner list | **applied** — C12 order pause flag → animation (`10033d8c`) → rules; C9 `testRandomFrameDrawsEveryStep` (`plsh`); invariant 6 and self-audit 5 list C9 |
| I-1 | C12 put the pause flag after the rules | **applied** — `10033d70` → `10033d8c` → `10033db0` |
| I-2 | cyclic motion draws twice per tick, untested | **applied** — C9 contract + `testCyclicMotionTwoDrawsPerTick`; owner list |
| I-3 | G4 sampled the score at the end of the tick; the recorder stores it mid-tick | **applied** — `FilmCursor.scoreAtRead` written at the film read (C14); G4.1, S6, H3 test renamed `…AtRead4809` |
| I-4 | A1's mixer functions are not in `$LISTING` | **applied** — `$LISTX` path line; `FUN_100d1d90` disassembled first with `DisasmRange.java` |
| I-5 | R4 stamped D with the core colour | **applied** — core for E/X, fringe for A/B/C/D (`10044014..10044040`) |
| I-6 | the pause click is cut by the same pass's halt | **applied** — positional `haltEffectsAt: Int?` (S3, CueBuffer, S5); A2 `testPauseClickSurvivesHalt`; C18a `testCapsLockPassSequence` |
| I-7 | pitch literal one ulp off | **applied** — bit pattern 0x3f0693da (planner re-check agrees) |
| I-8 | tick-time terrain stamps had no route into the ops | **applied** — `GameState.tickOps` (C7), filled by C11b (`testDrawToTerrainStampsIntoTickOps`), emitted before draw world (C18a); C12 `groupCommands` honours +0x36 |
| I-9 | Q4 default contradicted D30 | **applied** per ruling 7 |
| m1 | five Bonus Stations, not two | applied (gate card 1) |
| m2 | the bomb flies 114 px toward the crosshair | applied (gate card 4) |
| m3 | shortened decimals in two tests | applied — bit patterns / exact float32 literals; bank correction 7 |
| m4 | level-end window [3,919, 4,718]; last tick 4,864 | applied (p11) |
| m5 | `stli` newer than the films | applied (G4 text, bank correction 6) |
| m6 | "Interlacing      ON" has 6 spaces | applied (C19) |
| m7 | missing `min(P, 100)` priority clamp | applied (A1; S2 note) |
| m8 | owner copy and +0x352 test omitted from C12's order | applied |
| m9 | GameFlags missing +0x34 and +0x0b | applied (S2) |
| m10 | `testLevelStartDrawsAndOrder` film/non-film ambiguity | applied — non-film start seeded 0x469c2 |
| m11 | game over is strict: start + 111 | applied (C17, S9.2) |
| m12 | "P1 active" gate already settled | applied — `GameFlags.p1Active`, C14 precondition points to loose-ends-session §4 |
| m13 | AllowOnlyOneInstance would couple Core to audio | applied — Hazards + C12 census assertion |
| m14 | `MSLRandom.draws` changes `==` | applied — excluded from equality, reset by init/srand (S3, C0 test) |
| m15 | REPLAY banner geometry; not drawn on the ending pass | applied (C18a precondition and test; Research notes "settled") |

## Leg B — dispositions
| id | finding | disposition |
|---|---|---|
| C1 | `\|` in table gate commands matches a literal bar (G2 reads 0; G7/G8 can never fail) | **applied** per ruling 2; landmine (g) |
| C2 | HectorShell does not depend on HectorAudio | **applied** per ruling 1 (Package.swift edge, D-entry, AkiPad build) |
| I1 | GameState fields owned by later tasks | **applied** per ruling 3 (`mask`, `tally`, `tickOps`, `entityLimitWarned`; step logs as closure params) |
| I2 | no entity-field / access convention across parallel waves | **applied** — per-offset Entity table in C7; index-based API (invariant 13) |
| I3 | `DeimosSessionTests.kind` is an exhaustive switch | **applied** — C0 Files (verified: no `default`) |
| I4 | C18 missed `TestWorld.swift` and session accessors; counts 7/11/6 | **applied** — TestWorld in C18b; forwarding accessors (invariant 12); counts corrected (+ EntityDrawTests 5) |
| I5 | C10 needed C11's destroy | **applied** — hook stub `Combat/Destruction.swift` (invariant 14); C10 asserts the hook call |
| I6 | C19/C17 tests asserted `pass` output before C18 | **applied** — re-specified against `FrameKeysResult` / `GameFlags`; pass-level checks moved to C18a |
| I7 | timeline tests need the world loop | **applied** — C12 owns `updateWorld` (p15 order); C8 placement filter + its own bounded stepping helper |
| I8 | K2 contract gaps (SDL init direction, stream rate on reconfigure, interleaved scratch) | **applied** (S8) |
| I9 | music decode would allocate on the audio thread | **applied** — ruling (a): non-allocating ima4 decoder in DeimosAudio, kit `IMA4` as test oracle |
| I10 | `.pauseWait` trap untestable | **applied** — `RenderOp.isHostOp` (C0) and R4's test |
| I11 | `(0, −10)` exact contradicts the tables | **applied** — expressed through S[180]/C[180] |
| I12 | C15's edits to `Player.swift` understated | **applied** |
| I13 | A3's audible smoke not doable by an agent | **applied** — DEBUG counters; audible checks on Ben's card |
| I14 | C18, C11, C14 too big | **partially applied** — C11 and C18 split (ruling 4), `updateWorld` moved to C12, trace recording to H2; **C14 kept whole** (one subsystem, one file family; its precondition is long but the code is ≤ ~700 lines) — orchestrator may split it at execution if a seat runs short |
| I15 | G4 miss path not executable | **applied** per ruling 5 (F1, pending trace, separate G4 bundle) |
| I16 | no owner for bank corrections | **applied** per ruling 6 (B1) |
| I17 | RNG path first checked at H3 | **applied** — C18b `testEarlyDemo01Report` (report, not a gate) |
| m1 | HectorKit moved | applied (header, Paths, G1) |
| m2 | `draws` in Equatable, reset | applied |
| m3 | "`EntityDraw.entry` doesn't exist" | **rejected** — it exists: `Deimos/Core/Sources/DeimosCore/Draw/EntityDraw.swift:199` `public static func entry(_ e: inout GameObject, hOffset: Int32, floats: [Float]) -> [DrawCommand]`; C13 now says "the existing `EntityDraw.entry`" |
| m4 | wrong owner of `FilmCursor` | applied (C7) |
| m5 | flee point had two owners | applied — C8 owns `FUN_10017510` and `testFleeTargets` |
| m6 | `updatePlayer` lacked the gate parameter | applied — `GameFlags.p1Active` |
| m7 | six unsettled items | applied — Research notes split into settled / still open |
| m8 | "as read" tests should be re-derived | applied — header + self-audit 4 (first review leg re-derives) |
| m9 | G11 bounds only named for H3 | applied — bounds named in the timeline, film, driver and replay tests |
| m10 | G3 diffed against stale local main | applied — merge-base with origin/main |
| m11 | new test targets need their own data locator | applied (invariant 5; A1/H3 Files) |
| m12 | redundant `index:` parameter | applied — `DeimosAudioEngine.init(assets:)` |
| m13 | A1 missing the priority clamp | applied |
| m14 | interim `.pauseWait` trap | applied — C18a's `HeadlessRun` steps it as a no-op; no staging in between |
| m15 | typed keys need Mac charCodes | applied — C19 charCode table; A3 mapping |
| m16 | when `testPrefsSurviveRestart` checks pref 5 | applied — on the carried prefs value |

## Ladder after the fix pass
189 → C0 195 → A1 203 → C13 211 → C16 217 → A2 224 → R4 227 → C7 235 → C8 246 → C9 256 → C10 265 → C14 275 → C11a 281
→ C15 290 → C19 299 → C11b 305 → C17 313 → C12 321 → C18a 329 → C18b 330 → H2 338 (G2); H3 +3 in the G4 bundle.
HectorKit 322 → 326 (+1 SDL).
