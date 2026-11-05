# Audit — Deimos Rising Phase 2, branch `deimos-phase2` (44 commits) against the remainder spec — 2026-11-05

> Seat: Claude Fable 5.1 (re-planning pass, `replan.md` step 4). Five read-only `fk-reviewer` legs (Opus 5.5) ran in
> parallel over the branch worktree, each re-deriving two or three rules by hand from the committed Ghidra dump
> (`ghidra/deimos/Deimos_pef.decompiled.c`) or the PowerPC listing, running its area's suites on its own scratch path,
> and answering one prediction. Spec: `docs/superpowers/specs/2026-11-05-deimos-remainder-design.md`. Plan:
> `docs/superpowers/plans/2026-11-05-deimos-remainder.md`. The five reports follow the rulings verbatim.

## Headline

| | |
|---|---|
| Rules re-derived by hand | about 60 (trig build, pool, spawn draw order, cull, cyclic draws, rules #5/#14–16, timer, spawn-set executor, destroy order, bonus ladder, media gate, sweep, hold-up, death, overload, collisions, IMA step, insertion, gain/step, music level, level end, tally states 0–10, tier, coin bonus, notices, messages, particle colours, stamp kernel, blur, keys, console) |
| Rules found wrong in the code | **0** |
| Rows ruled **redo** | **0** |
| Rows ruled **change** (code or test, in the next wave's fix round) | 23 |
| Rows ruled **missing** (seams the join tasks C12 / C18a / H2 must build, now written into their briefs) | 12 |
| Bank corrections found beyond the handoff's list | 9 |
| Tests run by the reviewers | 134 passed, 0 failed, 0 skipped (the whole suite: 313/0/0, seat's run) |
| Predictions | 10 of 10 derived by hand and matched by the tests |
| The three owed review legs (C11b ×2, C17 leg 2) | **discharged**: C17 MERGEABLE (minors); C11b one Important seam (the wreck-stamp time field) and one Minor (the leftover stub name); both go to the fix round and C12 |

The shape is the one the Castles audit predicted: every rule matches the oracle; every problem is a seam between
parts, or a test that checks the code against itself. Two data questions the reviewers left open were settled by the
seat from the decoded unit files (`~/Developer/Ghidra/deimos/proj/data/Game/unde`, 386 units / 1,167 states):

| Question | Answer | Effect |
|---|---|---|
| Does any state draw to terrain every tick (`stateDrawToTerrain`)? | **yes, 2 units**: Bomb Crater `bocr` and Tank Tracks `tatr`; 32 units stamp on destruction | craters are reachable in level 1 (plasma bombs), so the "+0x90 last stamp time" field and the draw-pass terrain path are built in C12 (audit 4 rows 1–2) |
| Does any cyclic state have max speed < 1 (one draw instead of two)? | **no**: 40 cyclic states, max speeds 1, 2, 4 | audit 3 row 6 closed; "two draws per tick" holds for shipped data |
| Do shipped units use a scale tolerance (a spawn-time RNG draw no test pins)? | **17 units** | audit 2 row 12 stays Important: a spawn test pins that draw in the fix round |

## Rulings (every change / missing / note row; keep rows stand as the reports give them)

Owner codes: **2.1** = the next wave's fix round · **2.3** = bank corrections task · **C12**, **C18a**, **H2** = the
join tasks' briefs · **card** = the Phase 2 gate card · **—** = no action.

| Report · row | Finding (short) | Ruling | Owner | Why |
|---|---|---|---|---|
| 1·13 | the halt test does not assert the `.pause` music cue | keep | — | the halt order is asserted; music pause is C18a's sequence test |
| 1·15 | engine starts at level 128; nothing sends `.level(pref)` yet | missing | C18a | already the C18a amendment (A2 review m4); C18a's `testLevelStartDrawsAndOrder` asserts the cue |
| 1·17 | music decoder re-sync rule is the kit's, not a proven Sound Manager rule | keep, disclose | card | harmless on the three shipped tracks (handoff A2 probe) |
| 1·18 | per-block refcount traffic on the render path | keep | — | not an allocation |
| 1·19 | `init(effects:)` can copy-on-write on the audio thread if the caller keeps its mixer | change | 2.1 | take `consuming effects`; production path is already safe |
| 1·21 / 1·22 | effect-gate vs music fallback differ from the original for unshipped data shapes | keep, note | — | unreachable with shipped data; a Phase 3 card notes it |
| 1·23 | the preload count (96) is not asserted | change (test) | 2.1 | add the count assertion to `testEngineIsAPullSource` |
| 1·24 | `GameState.cues` is never moved into `PassOutput`, never cleared, never fed to `apply` | missing | C18a + H2 | C18a's pass moves and clears `game.cues` into the output (one holder: `PassOutput` carries a `CueBuffer`-shaped triple already); H2 feeds the sink at pass begin (D31.4) |
| 1·25 | state sounds (`FUN_10033850` step 3) have no record call site | missing | C12 | the plan's C12 contract owns "state sound (AllowOnlyOneInstance = not playing)" with its pitch draw; written into the brief with the draw |
| 1·26 | `@discardableResult` above the doc comment | change | 2.1 | cosmetic |
| 1·27 | plan A1 text says ±32767 | change (text) | 2.3 | with the bank's same line |
| 1·bank | four sound-music corrections (clamp, accumulation note, the 2·P tail, NR #51 closed) | apply | 2.3 | |
| 2·5 | `freeHint` default −1, every reachable world has 0 | change | 2.1 | default 0 |
| 2·7 | only +0x134 of the not-reset fields is pinned | change (test) | 2.1 | extend `testPoolCapAndHint` |
| 2·11 | the bank says state entry calls the owner init at spawn; the listing skips it | keep (code) | 2.3 | spawn-and-waves §3.2, §4 and the plan's C8 text corrected |
| 2·12 | four spawn-path draw sites pinned by no test (scale tolerance, flee, arming, delay-before-cyclic) | missing (test) | 2.1 | **Important**: 17 shipped units draw the tolerance; one new spawn test pins the sequence against the in-test LCG |
| 2·14 | the type-exists refusal is untested | missing (test) | 2.1 | new case |
| 2·15 | `EntityWorld.Walk` is used by no production code | missing | C12 | C12's entity loop iterates with `Walk`; its order test appends mid-update |
| 2·19 | `testLoadPassBand` per-level check mirrors the code | change (test) | 2.1 | pin the literals 2,1,2,1,3,0,0,0,0,1,2,1 |
| 2·21 | `GameFlags` has five fields plan S2 does not list | keep | plan | listed in the new plan's C12/C18a notes (two are session-lifetime stack bytes) |
| 2·23 | nearest-player distance in three places | change | C12 | the Rules copy goes (audit 3 row 1); `closestActivePlayer` in Spawn is a different function (`FUN_10005ed0`) and stays |
| 2·26 | `Entity` reset's keep-list rests on micro-wave §3.6, not re-derived | keep, verify | C12 leg 1 | C12's first leg reads `FUN_10012650`'s store list (it also sets +0x90 = 0, audit 4 row 1) |
| 2·27 | the tick-78 prediction assumes no earlier scroll pause | keep | — | true for le07 (`01m1` at 1660) |
| 2·bank | spawn-and-waves §3.2 / §4 owner-init correction | apply | 2.3 | |
| 3·1 | two nearest-player helpers, proven equivalent on 200,000 cases | change | C12 | keep Motion's; delete Rules'; rules #8/#9 call `playerWithinRange` |
| 3·2 | `updateMotion`, `integrateAndCull`, `playerWithinRange` have no caller | missing | C12 | the join |
| 3·4 | cull test uses equal half sizes | change (test) | 2.1 | hw 10, hh 14 |
| 3·6 | "two draws" doc vs max speed 0 | keep | 2.1 (doc) | census: no shipped cyclic state below 1; one doc line |
| 3·8 | the cyclic test mirrors the formula | keep | — | the LCG is independent; literal L values optional |
| 3·11 | `isOnScreen` rejects a NaN x where the original passes it | change | 2.1 | write the x tests as the listing's negated compares |
| 3·16 | spawn-set test reads rates from the code | change (test) | 2.1 | pin 1000, 1125, 1245 for seed 0x469c2 |
| 3·17 | `runSpawnSets` indexes without a bound | change | 2.1 | add the guard |
| 3·19 | doc says 0.0 is a placeholder; it is the original's | change (doc) | 2.1 | |
| 4·1 | the wreck-stamp time test is "always true"; a same-tick draw-pass stamp (craters, tank tracks) or game time 0 makes it false | change | C12 | **Important**: add `lastStampTime` (+0x90) to `GameObject` (init 0; written by every terrain-path stamp); the draw pass honours +0x36; `terrainStamp` tests it; a test stamps a crater in the draw pass and sweeps it the same tick |
| 4·2 | nothing reads `drawToTerrain` (+0x36) | missing | C12 | the group draw's terrain branch (`10034b28..10034b5c`) |
| 4·3 | `removeMemberStub` still exists (forwards correctly) | change | 2.1 | inline and delete |
| 4·5 | owner destruction before the death spawn is untested | missing (test) | 2.1 | new case with an owned unit |
| 4·6 | `testDeathOrder` cannot tell `now` from game time | change (test) | 2.1 | |
| 4·9 | the bonus draw is checked by step log, not RNG replay | change (test) | 2.1 | replay on a copy as `testMediaGateWater` does |
| 4·11 | mask index assumes unpadded rows | keep, verify | C18a | the mask loader (C18a) decodes the TGA into a tight row-major array; its test asserts width × height cells |
| 4·13 | deletion spawn uses the shared template; the listing copies a different one | keep, note | 2.1 (doc) | static-init audit: the seven spawn templates differ only by +0x24 = −1, which the shared template carries; one doc line |
| 4·14 | C11b's 7-line edit to C11a's test | keep | — | justified; the shot dies first |
| 4·15 | the player-ram redirect is already built | keep | plan | struck from the C12 brief |
| 4·17 | collision entry points and the sweep have no caller | missing | C12 | the join |
| 4·19 | `Player.sector` lingers; doc stale | change | C18a (retire) + 2.1 (doc) | |
| 4·20 | `resetHandler` defaults sector to 0 | change | 2.1 | make it required |
| 4·23 | the platform test hard-codes 0.4 | change (test) | 2.1 | read `plbo`'s damage |
| 4·bank | sprite-geometry-draw §3.2: +0x90 initialised 0, written by the terrain stamp | apply | 2.3 | |
| 5·1 | nothing calls `tally.reset()`, the ground-count reset or `playerLevelStart` | missing | C18a | in `FUN_100064d0`'s order; a two-level test comes with Phase 3 |
| 5·2 | the end-of-level, effects, notice, key and console steps have no production caller | missing | C12 + C18a | each named in its brief with its slot |
| 5·3 | the "Reached Motion Blur Limit" message is never posted | missing | C12 | `(text, 1, 1, 0)` at the limit |
| 5·4 | tally text request untested | change (test) | 2.1 | |
| 5·5 | notice and money-counter positions unasserted | change (test) | 2.1 | |
| 5·6 | flli 173 read in unused states | keep | — | pure read |
| 5·7 | the `noal` branch not driven through `levelEndStep` | change (test) | 2.1 | |
| 5·8 | the transition reset's effects unasserted | change (test) | 2.1 | |
| 5·9 | one `TickCount` read instead of two | keep | — | |
| 5·10 | `HeldKeys` doc pointer | change (doc) | 2.1 | |
| 5·bank | scoring-bonuses §6.4 (MED → HIGH for states 1–5, 7, 9; `moco` on the exits of 2 and 3; priority 100), §6.5 (same; the add-score call outside the game) | apply | 2.3 | |
| 5·open | the tally text draw's owner | ruled | C18a | draw world: groups → blurs → players → **tally text** → notice → score bar, as the plan says |

**Fix round size (Task 2.1):** code changes 7 (1·19, 1·26, 2·5, 3·11, 3·17, 4·3, 4·20), doc lines 6, test edits 9,
new tests 5 (2·12, 2·14, 4·5, 5·4, 5·7) → ladder 313 → **318**.

**What the audit changes in the spec:** §4 (C12 gains the draw-pass terrain path, the stamp-time field, the state
sounds, the blur-limit message, the `Walk` iteration, the dedupe; C18a gains the level-start resets and the cue
move; the ram redirect is struck); §7 ruling 1 is confirmed (the owed legs are discharged); nothing in §3, §5, §6
changes.

---

## The five reports, verbatim


---

# Audit 1 — audio (K2 kit side, C0 cue side, A1, A2) — 2026-11-05
Tests run (own scratch path `build-1`): DeimosAudioTests 15/0/0 (EffectMixerTests 8, MusicEngineTests 7);
Phase2SeamTests 6/0/0. Plan counts match (A1 +8, A2 +7, C0 +6).
Extra probe (scratch package `probe1`, links the branch's DeimosCore/DeimosAudio, reads the committed data): 99 `soun`
tags, 99 distinct ids, 0 duplicates; **96 load as effects**, 3 refused as stereo (`mu03`, `ammu`, `inmu` → music).

Predictions:
- Q8 `exsl` MinVol 100 / MaxVol 70 / Prio 0x132 / pitch 0.50–0.55 after srand(1) → volume **100** (RandomRange(100,100),
  no draw), priority **0x32 = 50** (0x132 & 0xFF), pitch **0.52569354 = 0x3f0693da**, **1 draw**. Derivation: rand
  after state 1 = (1·0x41c64e6d + 0x3039) >> 16 & 0x7fff = 0x41c6 = 16838; single precision 0.5 + (0.55f − 0.5f)·16838
  / 32767 (each op rounded to float32) = 0x3f0693da. Pitch16 = 34451. Test pins all four; passes.
- Q7 effect preload → **96 effects**; every gaso id (21 non-`none` of 24) and every `SoundRecord` id reachable by
  reflection over `definitions` (68 distinct) plus `publ` is in the 96. **No shipped id falls outside → bank NR #51
  (INDEX #51 / sound-music NR 4) is closed for shipped data** (the on-demand-load wrong-sound path is unreachable).
  Not a code-path census of literal ids outside gaso/records (only `publ` checked).

## Findings
| # | Finding | keep / change / redo / missing | File:line | Why (cite listing/dump/bank) | The fix (one sentence) | Confidence | Severity |
|---|---|---|---|---|---|---|---|
| 1 | IMA difference ⌊(16m+8)·step>>6⌋ with the step BEFORE the update; index clamp 0…88; predictor clamp −32768…32767; no re-sync | keep | Sources/DeimosAudio/Voice.swift:93-102,133 | listing 100d3368..100d33d0 (`rlwinm r8,r14,4,25,27; ori 8; mullw r8,r15; srawi 6`; `cmpwi r19,-0x8000` / `0x7fff`); r15 reloaded only at 100d34e8 | — | HIGH | — |
| 2 | Interpolation, acc/prev reset per call, mid-sample exit with `last` stale, silent path frame count, saturating add −32768…32767 | keep | Voice.swift:84,103-131 | 100d32e4/ec `li 0`; 100d33d4..100d34ec; 100d3498 `beq 100d34f0` skips 100d34dc | — | HIGH | — |
| 3 | `testIMADecodeClamps` pins nibble 7 at step 7 → 13 (reference shift-sum gives 11) and 43 next (step 16 → 30) | keep | Tests/DeimosAudioTests/EffectMixerTests.swift:81 | only the (2m+1)/8 formula gives [13,43,…] | — | HIGH | — |
| 4 | Insertion: first slot where new ≥ old on BOTH keys (unsigned prio `cmplw`, signed gain sum `cmpw`), prio 0→1, gains clamp 0x80, refuse when i ≥ 16, count 16 → 15 then shift (16th overwritten), id counter from 1 step 2 | keep | Sources/DeimosAudio/EffectMixer.swift:123-149 | listing 100d1918..100d1aec | — | HIGH | — |
| 5 | Ranking tests exercise both keys (prio 60 with gain sum 128 loses to prio 50/256), newest-first among equals, eviction of 16th, refusal, refused start → lastVoice 0 → isPlaying counts all | keep | EffectMixerTests.swift:152-207 | 100d1978/100d1998 `blt` → next; 10047e1c `stw r3,0xc(r29)` | — | HIGH | — |
| 6 | Unsigned-vs-signed compares are untestable with legal inputs (prio ≤ 100, gains ≤ 0x80); tests cannot distinguish them | keep (note) | EffectMixer.swift:133-134 | value ranges | none needed | HIGH | Minor |
| 7 | Gain trunc(128·(v/100)) in float32 (fdivs then fmuls, fctiwz), stored as halfword; constants 128.0/100.0/65536.0 at 0x100d7418/1c/24 | keep | EffectMixer.swift:110-117 | 10047d88..10047e0c; data image `*(r2−0x6dbc)` = 0x100d7414 → {1.0, 128.0, 100.0, 0.0, 65536.0} (read from mem/10000000.bin) | — | HIGH | — |
| 8 | step = FixMul(FixDiv(44100, rate), pitch16.16); FixMul/FixDiv truncate, 0 if either 0, overflow → 0xFFFFFFFF | keep | EffectMixer.swift:141,144,221-232 | 100d1a70..100d1a9c; FUN_1006e250 (disasm-w2s8b.txt:1460) overflow iff p>>48 ≠ 0; FUN_1006e2b0 iff quotient high word ≠ 0 | — | HIGH | — |
| 9 | Play priority `min(P & 0xFF, 100)`; allowMultiple check before the lookup; record lookup first match | keep | EffectMixer.swift:83-95 | 10047c40..10047c60, 10047d9c; FUN_100476e0 breaks on first match (10047790) | — | HIGH | — |
| 10 | `SoundPlay.record`: none → no draw; pitch the only draw; volume R(MinVol,MinVol); prio & 0xFF; allowMultiple passed through | keep | Sources/DeimosCore/Audio/SoundPlay.swift:12-18 | 10047600..1004764c; dump FUN_100475e0 (line 42301) | — | HIGH | — |
| 11 | `MSLRandom.draws` excluded from `==` (custom `==` on state) and reset by srand; tested | keep | Sources/DeimosCore/Game/MSLRandom.swift:10,21 ; Phase2SeamTests.swift:39-46 | plan S3 | — | HIGH | — |
| 12 | Positional halt: sounds before k start, stopAll at k, rest start, halt == count → stop after all, then music; out-of-range halt clamped | keep | Sources/DeimosAudio/DeimosAudioEngine.swift:96-104 | plan A2/S5; FUN_100476a0 → FUN_100d1be0(0) | — | HIGH | — |
| 13 | `testPauseClickSurvivesHalt` discriminates (no halt → 2 voices, halt after → 0) and covers k = count and k = 0; it does not check the `.pause` music cue it sends | keep | Tests/DeimosAudioTests/MusicEngineTests.swift:305-317 | — | optionally assert music paused | HIGH | Minor |
| 14 | Music level `FUN_100482c0` clamp 0…128 float32; amp = min(255, m·fade >> 8), m capped 0x100; gain amp/255 (Q3) | keep | Sources/DeimosAudio/MusicStream.swift:106-123 | 100d139c `mullw`; 100d13a8 `rlwinm …,24,8,31`; 100d13b0 `cmplwi 0xff`; ampCmd 0x2b at 100d13cc | — | HIGH | — |
| 15 | Engine starts at level 128 (pref 100) while the data image holds m = 0x100; correct only if H2/A3 sends `.level(pref)` at startup (handoff carry) — nothing sends it yet | missing (carry) | DeimosAudioEngine.swift:43 | handoff "Carries for later tasks" | H2/A3 send `.level(music pref)` once at startup and a test pins it | HIGH | Important |
| 16 | `.play` restarts from frame 0, `.stop` disposes, pause freezes without consuming; loop wraps the whole SSND with decoder state carried | keep | MusicStream.swift:129-144; DeimosAudioEngine.swift:105-123 | §6.3/§6.5; handoff A2 block (carry = reset on the 3 tracks) | — | HIGH | — |
| 17 | Music decoder uses the kit's re-sync rule (continue at full precision when header agrees within 0x7F) — that is HectorKit's choice, not a proven Sound Manager behaviour; harmless on shipped tracks per handoff probe | keep (disclose) | MusicStream.swift:164-166 | plan A2 ruling (a): kit is the oracle | disclose on gate card | MED | Minor |
| 18 | Render path: no allocation found — empty-array swaps (`[]` literal doesn't allocate), `withUnsafe*` non-escaping, buffers preallocated; retain/release of the sound's byte array per voice per block (`let sound = sounds[…]`) is atomic refcount, not allocation | keep | EffectMixer.swift:182-199; MusicStream.swift:150-189 | plan A2 "never allocates" | optionally pass the sound by `borrowing`/index to avoid the refcount traffic | MED | Minor |
| 19 | COW trap: `init(effects:)` copies the mixer by value; if the caller's copy stays alive (debug builds keep locals to scope end, e.g. `engineMixer` in `testUnityGainNoMasterVolume`), the first `mixBlock` on the audio thread copies `voices`/`block` — an allocation on the render path. Production `init(assets:)` is safe (local dies before any render) | change (low) | DeimosAudioEngine.swift:83-86 | Swift value semantics | take `consuming effects` or document "caller must not keep the mixer" | MED | Minor |
| 20 | Imports: only Foundation, DeimosCore, HectorAudio, Synchronization across DeimosAudio | keep | Sources/DeimosAudio/*.swift:1-4 | plan invariant 1 + A2 carry | — | HIGH | — |
| 21 | Effects preload uses `IMAContinuous(soundFile:)` as the gate (refuses WAVE, PCM, ima4 with sample size ≠ 16) rather than "DeimosSound's effect gate" named in the plan; any refused tag that parses as ima4 becomes a *music* track (e.g. a mono ima4 with sample size 4 would) | change (low) | DeimosAudioEngine.swift:64-78 | plan A2 contract line "passes DeimosSound's effect gate"; FUN_100d1780 accepts WAVE/PCM | restrict the music fallback to channels == 2 (or to the tags the music code names) | HIGH (code) / LOW (impact: unshipped) | Minor |
| 22 | A `.play` of a mono effect tag as music plays nothing (tracks hold only effect-gate failures); the original streams any `soun` | change (low) | DeimosAudioEngine.swift:130-133 | FUN_10047f90 tests only `none` | load every `soun` as a potential track lazily, or disclose | MED | Minor |
| 23 | `testEngineIsAPullSource` says "every mono soun tag is preloaded" but pins no count | missing | MusicEngineTests.swift:324-328 | plan A2 "Effects preload: every soun tag" | add an internal count accessor and assert 96 | HIGH | Minor |
| 24 | Cue seam not wired: `GameState.cues` (CueBuffer) is filled by Core (FrameKeys, Console, Tallies, NoticeSlot…) but nothing copies it into `PassOutput.sounds/music/haltEffectsAt`, nothing clears it per pass, and nothing calls `DeimosAudioSink.apply`; `PassOutput` and `CueBuffer` duplicate the same three fields | missing (H2 owns it) | Sources/DeimosCore/Game/GameState.swift:40; Seams/PassOutput.swift:6-14; Game/DeimosSession.swift:197 | spec §3 row H2 "cue routing"; plan D31 "cue routing at pass begin" | H2: move/clear `game.cues` into the pass output (one holder), test the halt index survives the copy | HIGH | Important |
| 25 | State sounds (`FUN_10033850` step 3, sound-music §5) have no `SoundPlay.record` call site in Core — the one RNG draw per state-sound trigger is missing from the draw order | missing (other area?) | grep: no caller outside Damage/Destruction/NoticeSlot/PlayerLife | sound-music §5 `10033c3c`; §8.6 draw on every call | the state-machine task adds the §5 handler with its draw; test the draw count | MED (may be scheduled elsewhere) | Important |
| 26 | `@discardableResult` sits above a doc comment block, so the `///` paragraph is not the function's doc (cosmetic) | change | EffectMixer.swift:74-82 | — | move the attribute below the comment | HIGH | Minor |
| 27 | Plan A1 contract text still says predictor/mix clamp "±32767"; code (correctly) uses −32768 | change (plan/bank) | plan line ~460 | 100d33b4/100d3440/100d3470 | fix at B1 with the bank | HIGH | Minor |
| 28 | K2: `PCMPullSource` and `ShellMixer` stream voice match S8 (source-format node, preallocated scratch, chunk loop, paused = silence without calling the source, nonisolated node factory) | keep | HectorKit Sources/HectorAudio/PCMPullSource.swift:11-16; Sources/HectorShell/ShellMixer.swift:202-235,352-406 | plan S8 | — | HIGH | — |

## Re-derivations
**IMA step (Q1).** disasm-review2.txt 21693–21843 (`FUN_100d32d0`). Nibble = `srw r16,r3` with r3 = 28 − 4·(pos&7), so the
high nibble of each byte comes first. 100d3374 `rlwinm r8,r14,4,25,27` = (nib&7)<<4, 100d3384 `ori r8,8`, 100d33a0
`mullw r9,r8,r15` (r15 = the step loaded from the OLD index: 100d333c at entry, 100d34e8 after each sample), 100d33a8
`srawi 6` → ⌊(16m+8)·step/64⌋ = ⌊(2m+1)·step/8⌋. Sign = bit 3 (100d33a4). Clamps −0x8000 / 0x7fff (100d33b4, 100d33c8).
Voice.swift:95-102 is exactly this; the test's 13 (not 11) and the following 43 are only produced by this formula. Match.

**Insertion (Q2).** disasm-review2.txt 21440ff (`FUN_100d18d0`): loop while slot `+4` ≠ 0 and i < 16; `cmplw` prio
(unsigned) `blt` → next; `cmpw` (L+R) (signed) `blt` → next; else stop. i ≥ 16 → return 0. Count ≥ 16 → 15; BlockMove
(count − i)·0x38 from i to i+1; fill; id = request id or counter (+2); count += 1. EffectMixer.start matches line for
line; the 16th voice is overwritten. Tests pin both keys, equals-goes-first, eviction and refusal.

**Gain and step (Q3).** 10047d88..10047e0c: volume int→double (0x4330 magic) − bias, `fsubs` (rounds to float32),
`fdivs` by 100.0, `fmuls` by 128.0, `fctiwz`, `sth` to both gains; pitch `fmuls` 65536.0 × f31, `fctiwz`, `stw` request
+8. Constants read from the code image at 0x100d7414. 100d1a74 FixDiv(*(r2−0x74d4) = output rate, asnd+8), 100d1a8c
FixMul(ratio, request+8). FUN_1006e250/1006e2b0 truncate with overflow → −1. Swift matches; tests pin 100→128 … 50→64,
pitch 1.1 → 72089, 22050 Hz → ratio 0x20000.

**SoundPlay.record (Q4).** 10047600–1004764c and dump line 42301: id test, `FUN_100465e0(+0x10,+0x14)` (the draw),
`FUN_10046580(+4,+4)` (no draw), `+0xc & 0xff`, allowMultiple = caller r4 → r7. Swift matches; the test pins
0x3f0693da and draws 1 (independently recomputed in float32: 0x3f0693da).

**Halt (Q5).** `apply` loops sounds, stopAll at index k, after the loop when k == count, then music. Matches S5/A2.

**Music (Q6).** 100d136c: `mullw m,fade`, `>>8` (rlwinm 24,8,31), `cmplwi 0xff; bge → 0xff`, ampCmd 0x2b. 100482c0 level
clamp. Swift matches. One `Mutex`; render path non-allocating (finding 18/19).

## Bank corrections found by the audit
- sound-music.md §3.2 lines 175, 179 and the worked example line 439 still say ±32767 → −32768…32767 (100d33b4,
  100d3440, 100d3470) — already on the handoff list, not yet applied.
- sound-music.md §2.2: "differences from a reference ima4 decode are rounding-level" — the per-sample difference is
  rounding-level, but with no re-sync it accumulates over the whole sound; say so. Also the drop/swap rows can go
  MED → HIGH (listing `FUN_100d1d90` read for A1).
- sound-music.md §2.2: the 2·P tail is not a "held, slowly decaying DC level": nibble 0 adds ⌊step/8⌋ per sample while
  the index falls, so the level creeps upward until step < 8, then holds.
- INDEX #51 / sound-music NR 4: closed for shipped data — all 96 effects are preloaded and every gaso and SoundRecord
  id (and `publ`) is among them.

## Open questions for the seat
- Who owns the state-sound handler (§5) and its RNG draw — is it in a later wave, or a gap (finding 25)?
- H2 must route `game.cues` into the pass output and clear it; should `PassOutput` hold a `CueBuffer` instead of three
  copied fields (one holder, finding 24)?
- Should the music fallback be limited to stereo tags (finding 21), and should a mono effect be playable as music
  (finding 22)? Both unreachable with shipped data.

---

# Audit 2 — trig, the entity world and spawning (C7, C8) — 2026-11-05
Tests run (own scratch path build-2): TrigTests 4/0/0, EntityWorldTests 4/0/0, SpawnTests 11/0/0 (passed/failed/skipped).

Predictions:
- le07 first level object → scroll tick **78** = game time **77**, unit **bsgr** (file index 25, the only placement at
  the highest yLoc below 3056, yLoc 2978), group at **(371, −64)**: x = 403 − 32 (ground), y = 2978 − (3120 − 78).
  Derived from the decoded level (scratch probe over DeimosAssets: top = 3600 − 480 = 3120, tick k spawns row 3056 − k,
  so k = 3056 − 2978) — matches `testFirstLevelObjectSpawnRow`. Assumes no scroll pause before tick 78.
- Load-pass band (rows 3056…3600): **13 of 565** placements (le01 2, le02 1, le03 2, le04 1, le05 3, le09 2, le10 1,
  le12 1; le06/07/08/11 none; all 565 have a unit definition). Matches `testLoadPassBand`.

## Findings
| # | Finding | keep / change / redo / missing | File:line | Why (cite listing/dump/bank) | The fix (one sentence) | Confidence | Severity |
|---|---|---|---|---|---|---|---|
| 1 | Trig table build precision exact: sin/cos of fl32(0x3c8efa35·i) as double then frsp; atan trunc(atan(0.01i)·57.2957795) in double; sqrt (float)sqrt((double)(float)n); 1024/16384/360 entries | keep | Math/Trig.swift:44-59 | listing 10042970..10042a6c (`fmuls f30,f31,f0` at 10042a30; `fmul`/`fctiwz` 100429a4..a8; `fsubs`+`frsp` 100429e0..ec); independent Python recompute gives the same S[90]/C[180]/C[90]/S[180] bits, sin/cos/atan/sqrt sums and atan[100]=44 | — | HIGH | — |
| 2 | `testTrigTablesAsRead` pins bit patterns (S[90], C[180], plus C[90] = 0xb33bbd2e which discriminates float-vs-double argument), atan[100] = 44 and whole-table sums | keep | Tests/TrigTests.swift:13-43 | S[90]=1.0 and C[180]=−1.0 alone would not detect a double-precision argument; C[90]/S[180] and the sums do | — | HIGH | — |
| 3 | `compassAngle` matches `FUN_10043090` branch for branch incl. NaN/−0 handling (`ble`/`bge` take unordered), "up-right 46" reproduced and pinned | keep | Math/Trig.swift:105-124; TrigTests.swift:67 | listing 10043090..100431e8 | — | HIGH | — |
| 4 | Pool rule: 1000 slots, count ≥ 1000 → nil, hint used without an in-use check, free sets hint = slot, reset stores hint 0 and count 0 and clears 1000 in-use bytes; serial 1000, group id 20000000 post-increment, PERM first | keep | Units/EntityWorld.swift:77-122 | listing 100385fc..100387dc, 10038810..10038834, 10038450..10038534 (25 × 40 stores), 10032f88..10033068 | — | HIGH | — |
| 5 | `freeHint` property default is −1 but every reachable world has 0 (init calls levelReset) | change | Units/EntityWorld.swift:47-48 | 10038450 stores 0 | Make the default 0 (or drop it) so the declaration agrees with the only reachable state | HIGH | Minor |
| 6 | Entity reset leaves +0xb8, +0x100…+0x114, +0x134, +0x138 untouched; doc and behaviour agree; test pins shields stale | keep | Units/Entity.swift:155-221; EntityWorldTests.swift:123-145 | every store in 100142f0..10014478 listed: none to those offsets | — | HIGH | — |
| 7 | Only +0x134 of the not-reset set is pinned by a test; +0xb8, +0x100…+0x114, +0x138 staleness untested | missing | Tests/EntityWorldTests.swift:123 | same | Add the four other kept fields to `testPoolCapAndHint` | HIGH | Minor |
| 8 | Byte −0x611c = 1 in the data image; code treats it as a constant true; all doc comments now say 1 | keep | Units/Spawn.swift:76-79; EntityWorld.swift:28-35 | mem/100de330.bin offset 0x1ee4 = 0x01; readers 100332d8, writer only 1003909c | — | HIGH | — |
| 9 | Request order: lookup → size/appears draws → players-active → type-exists → cap (≤ 1000, once-per-level message) → deleteExisting → group → y conversion → members → entry notice | keep | Units/Spawn.swift:120-173 | listing 100332c0..10033388, 100333a4..1003351c | — | HIGH | — |
| 10 | Per-member order D1 (10035ee4) → +0x13c/+0x13d → placement (10035f38) → initial motion with the post-D1 heading (10035f54, r26) → state 0 (10035f74) → +0x19/+0x1a → owner init (10035fb4) → group delay (10035fc8, equal → min, no draw) → cyclic (1003600c) → obstacle → parent direction → ground count | keep | Units/Spawn.swift:193-276 | listing 10035ec8..100360d8; FUN_10046580 itself skips the draw when lo == hi (100465a0) | — | HIGH | — |
| 11 | At spawn the owner init inside state entry is skipped (spawning path `10014c84 b 0x10014d7c`; lock path `10014cb0 b` too); the non-spawning call is gated on +0xa0 ≠ −1 (10014d64). Code right; bank and plan C8 contract say otherwise | keep (code) / bank fix | Units/StateEntry.swift:217-219 | listing 10014bb0..10014d74 | Correct spawn-and-waves §3.2 and §4 (see below) | HIGH | Minor |
| 12 | `testShurikenRequestFiftyOneDraws` exercises 6 draw sites (size, placement h, speed, timer, frame, delay); any swap or move among them fails (each value pinned per member, vy pins speed). It does not reach D1, scale tolerance 10014b14, flee 10017510, spawn-set arming at spawn, or the delay-before-cyclic order; D1 is pinned elsewhere (StateMachineTests:389), the other four in the spawn path by no test | missing | Tests/SpawnTests.swift:85-124 | per-member sites above | Add one spawn of a cyclic unit with scale tolerance and a flee/spawn-set state 0, pinning the draw sequence against the Oracle | HIGH | Important |
| 13 | Type-already-exists check counts deleted-but-unreaped members (no +0xcb test), over every group incl. PERM | keep | Units/Spawn.swift:108-114 | FUN_10036af0 10036b90..10036bb8 compares only unit id | — | HIGH | — |
| 14 | No test drives the `typeExists` refusal at all | missing | Tests/SpawnTests.swift | — | Add a case: a deleted, unreaped member of the unit still refuses the request after the size draw | HIGH | Minor |
| 15 | `EntityWorld.Walk` (re-reads both counts) is the only same-pass walk and is used by no production code; the test proves the helper, not the entity loop (C12 not built) | change (C12) | Units/EntityWorld.swift:160-182; EntityWorldTests.swift:198 | FUN_10033850 100345a0/100345c0 | C12's entity loop must iterate with `Walk` (or re-read counts the same way) and its own test must cover an append during the real update | MED | Important |
| 16 | deleteExisting re-removes a member already deleted earlier in the same tick (group live −1 twice); faithful to the original | keep | Units/Spawn.swift:480-496 | FUN_10036be0 10036c88..10036cb8: no deleted check | Note it in the doc comment as read | HIGH | Minor |
| 17 | Stationary initial motion leaves +0x100/+0x104 stale (faithful); a never-used slot starts 0 here vs uninitialised heap in the original | keep | Units/Spawn.swift:384-391 | 10037b94..10037bb4 store +0x10/+0x14/+0x108…+0x114 only | — | HIGH | Minor |
| 18 | Level objects: pending list in file order, `none`/unknown skipped, ground x −32.0, y = float(yLoc); row match by `fctiwz(y) == row`, row < 0 → nothing; every match unlinked whatever the request does; load pass rows bottom … top − 64 | keep | Units/LevelObjects.swift:33-89 | 10035990..10035ae4, 10033090..100331fc, 1000fa38..1000fa70 | — | HIGH | — |
| 19 | `testLoadPassBand` per-level check compares the code with a filter of the same rule; only the totals 565 / 13 are independent | change | Tests/SpawnTests.swift:494 | — | Pin the per-level counts (2,1,2,1,3,0,0,0,0,1,2,1) as literals | HIGH | Minor |
| 20 | `GameState` has exactly the 20 stored fields plan S2 names, none extra | keep | Game/GameState.swift:12-54 | plan S2 | — | HIGH | — |
| 21 | `GameFlags` has five fields plan S2 does not name: +0x0f restoreInterlace, +0x21 numPlayers, +0x28 drawShadows, +0x30 framesPresented, and `gameOverNoticed` (a `FUN_100051a0` stack byte, like `p1Active`, kept in the G mirror) | keep (plan gap) | Game/GameFlags.swift:23-76 | invariant 13 table | Add them to the S2 table in the new plan; say the two stack bytes are session-lifetime | HIGH | Minor |
| 22 | `FilmCursor.score(player:atRead:)` present; read of byte 4808 is the right one: de01 frames = 4809 and the recorder writes the byte at the cursor, then frames = cursor + 1 and the score (1000991c..1000993c), so the last written byte is 4808 | keep | Game/FilmCursor.swift:47-60 | FUN_10009830; FilmTests:23 | — | HIGH | — |
| 23 | Nearest-player distance computed in three places (Spawn `closestActivePlayer` = FUN_10005ed0, Motion `nearestActivePlayer` and a private copy in Rules = FUN_10005d40) | change | Units/Spawn.swift:342; Units/Rules.swift:189-199; Units/Motion.swift:35 | handoff C10 note | Dedupe the Rules copy onto Motion's at the fix round; 5ed0 is a different function and stays | MED | Minor |
| 24 | No `inout Entity`/`inout Player` held across a `GameState` call in this area; every `var e = world.entities[i]` block writes back before the next mutating call | keep | Spawn.swift, StateEntry.swift | invariant 13 | — | HIGH | — |
| 25 | All test loops bounded (1000 allocations, walk step cap 10, scroll loops 200/1700, seeds 1…40) | keep | the three test files | — | — | HIGH | — |
| 26 | Entity reset replaces the whole `GameObject` keeping only five fields; correct only if micro-wave §3.6's store list of FUN_10012650 is complete — not re-derived here | keep (check elsewhere) | Units/Entity.swift:214-220 | 10012674..1001273c (other area) | The object-reset reviewer confirms the list | MED | Minor |
| 27 | The prediction (tick 78) holds only with the scroll unpaused for the first 77 ticks; the test runs the scroll without the entity update, so a real pause before then would shift it | keep (note) | Tests/SpawnTests.swift:446-465 | level-scroll-objects §3 | — | LOW | Minor |

## Re-derivations
- **Trig build** (listing 10042920..10042a6c): atan loop `fsub` magic → exact double i, `fmul` by double 0.01, atan,
  `fmul` by double 57.2957795 (0x404ca5dc1a47a9e3), `fctiwz`, `addi; cmpwi 0x3ff; ble` → 1024 entries; sqrt loop `fsubs`
  (float n) → sqrt → `frsp`, 16384; sin/cos loop `fsubs` float i, `fmuls` by the float 0x3c8efa35 (single-rounded angle),
  cos (0x100d5784, stored to r26 = −0x6e30) then sin (0x100d579c, r25 = −0x6e34), each `frsp`, 360. Code identical;
  recomputed independently in Python: sums 765,787,171,276 / 766,622,680,769 / 72,543 / 18,308,834,383,206, atan[100] 44,
  atan[1023] 84 — all equal the test's pins. Verdict: right.
- **Heading** (10043090..100431e8): |a|,|b| via `fcmpo; ble → fneg`; `|a| ≥ |b|` → b/a else a/b; `r ≤ 0 → −r`;
  idx = fctiwz(100·r) clamped 0…1023; |atan[idx]|; then 90 − t, quadrant fix-ups, −90, wrap. (−50, 50) → 44 → 136 → 46.
  Verdict: right.
- **Pool** (100385d0, 10038810, 10038450, 10032e60): as finding 4. Verdict: right.
- **Reset** (100142f0..10014478): the store list has no +0xb8, +0x100…+0x114, +0x134, +0x138. Verdict: right.
- **Spawn request** (10033220..100335fc) and **member** (10035cd0..1003611c): as findings 9–10; state entry
  (100146f0) timer 100148dc → frame 100149f0 (spawning or face changed; editor-heading units take FUN_10016230, no
  draw) → scale tolerance 10014b14 → velocity (no draws) → [owner init skipped at spawn] → flee 10014d90 →
  10017cb0. Verdict: right; bank's step list is wrong about the owner init.
- **Level objects** (10035900, 10033090, 1000fa10): as finding 18; template r2+0x50ec = 0x100eb41c. Verdict: right.

## Bank corrections found by the audit
- spawn-and-waves.md §3.2 (≈ line 287): the state-0 entry at spawn does **not** call `FUN_10033600` at 10014d74 — the
  spawning branch jumps to 10014d7c (`10014c84 b`); `FUN_10035cd0` calls it once, after state entry (10035fb4).
- spawn-and-waves.md §4 (≈ line 340): `FUN_100146f0` calls `FUN_10033600` only when not spawning, the new state is not
  LockToOwnerLoc, **and +0xa0 ≠ −1** (10014d64..10014d6c). The plan's C8 contract repeats the §3.2 error.
- (Already in the handoff, still unapplied:) units-movement.md §3 (≈ line 154) says the reset sets the velocity copies —
  it does not; loose-ends-combat.md §1.3 (≈ line 97) "30" quirk headings → 34.

## Open questions for the seat
- Do any shipped units have `initialScalePercentTolerance ≠ 0`? If yes, finding 12 rises (that draw sits between frame
  and flee in every such spawn and nothing pins it before G4).
- Should C12's brief name `EntityWorld.Walk` as the mandatory iteration for `FUN_10033850` (finding 15)?

---

# Audit 3 — motion, animation and the state machine (C9, C10) — 2026-11-05
Tests run (own scratch path `build-3`): MotionTests 10/0/0, StateMachineTests 9/0/0.
A probe (a COPY of `Deimos/Core` in the scratchpad, `probe3/`, one extra test file; nothing in the repo touched) was used
for the srand(1) prediction and a 200,000-case equivalence check of the two nearest-player helpers.

Predictions:
- 07s1 "Pause, Spawn Shurikens", srand(1), entered at T0 = 1000 → requests at **1000, 1123, 1247**.
  How: the entry makes exactly one draw (timer 300..300, volley 1..1 and delay 0..0 draw nothing) — the rate,
  first LCG output 16838 → 120 + 16838 mod 6 = **r1 = 122** (by hand). r2 = **124** comes after the shur group's own
  spawn draws, so it was read from the probe run, not by hand. Formula T0, T0+r1+1, T0+r1+r2+1 holds: the re-arm tick
  (lastArm + rate) issues nothing, the next tick issues (countdown 0). For the test's seed 0x469c2 the probe gives
  rates 124, 120 → requests 1000, 1125, 1245; `testShurikenControllerThreeGroups` passes.
- The Shuriken range trigger fires on update **50**: before the update-n integration y = −100 + 6(n−1); n = 49 →
  y 188, distance 142; n = 50 → y 194, distance 136 < 140 (strict). Confirmed by `testRangeTriggerOnUpdate50`.

## Findings
| # | Finding | keep / change / redo / missing | File:line | Why (cite listing/dump/bank) | The fix (one sentence) | Confidence | Severity |
|---|---|---|---|---|---|---|---|
| 1 | Two nearest-player helpers: `nearestActivePlayer`/`playerWithinRange` (Motion) and `ruleNearestActivePlayerDistance`/`ruleWithinRangeOfPlayer` (Rules). Equivalent for every game input: same subtraction order, same fused multiply-add then truncate then root, first found kept, later only if strictly nearer, strict `<` range test, none → false. 200,000 random cases (ties, one or no active player, ranges −5…900): 0 mismatches. Only difference: Rules loops `players.indices`, Motion loops `min(2, count)` (the listing's loop bound is 2, `10005e54`). | change (C12) | Units/Rules.swift:184-203; Units/Motion.swift:35-54 | `FUN_10005d40` 10005dd8..10005e64, `FUN_10017ef0` 10017f1c..10017f54 | Keep Motion's (it also gives the position and player number the controller needs); delete the Rules copy and call `playerWithinRange` for #8/#9. | HIGH | Important |
| 2 | `playerWithinRange` has no caller yet (dead until the dedupe). `updateMotion` and `integrateAndCull` have no caller in Sources either — expected, C12 wires them. | missing (C12) | Units/Motion.swift:50, 70, 278 | grep of Sources | C12 joins them per its amendment (delete/destroy outcome; false → silent delete). | HIGH | Minor |
| 3 | Cull of `FUN_10012ca0(e, 128, 1)` is right: keep iff x+hw ≥ −m, x−hw ≤ W+m, y ≥ −m (centre, no half-height), y−hh ≤ H+m; the last test `ble`-keeps so an unordered compare culls; the first three let NaN through — the code matches both. | keep | Units/Motion.swift:278-294 | 10012d5c..10012e38 | — | HIGH | — |
| 4 | `testCullBoundsMode1`'s eight edges are right (W 416, H 480, hw = hh = 10: −138/−138.5, 554/554.5, −128/−128.5, 618/618.5). But hw and hh are both 10, so swapping the half-width and half-height fields would not be caught. | change | Tests/DeimosCoreTests/MotionTests.swift:98-114 | — | Use different half sizes (e.g. hw 10, hh 14) in the cull edges. | HIGH | Minor |
| 5 | Cyclic motion right: m = trunc(MaxSpeed), a = R(m/2 C-division, m) at 10017024, b = R(1, 100) at 10017054, L = a + b/100 (single), x then y clamp-and-flip, then v += accel, desired = v. | keep | Units/Motion.swift:180-196 | 10016fe0..1001712c | — | HIGH | — |
| 6 | Doc says "two draws every tick"; with trunc(MaxSpeed) = 0 the first range is R(0, 0) and draws nothing (the code does this right via `range`'s min == max rule). Not checked whether any shipped cyclic state has MaxSpeed < 1. | change (doc) | Units/Motion.swift:25-27, 175 | 10046594..100465a4 | Say "two draws unless trunc(MaxSpeed) = 0". | MED | Minor |
| 7 | Animation random frame right: draw at 10015a0c R(base, last) whenever the gate passes, stopped flag not consulted; row uses truncation of NumDirections·heading/360; +0xbc and +0x34 written on both paths. | keep | Units/Animation.swift:24-66 | 10015930..10015b08 | — | HIGH | — |
| 8 | `testCyclicMotionTwoDrawsPerTick` re-implements the same formula (oracle mirrors the code), so it pins draw order and float bits, not the interpretation of L; independent only in the LCG. | keep (note) | Tests/DeimosCoreTests/MotionTests.swift:355-387 | — | Optionally pin two literal L values. | MED | Minor |
| 9 | Rule #14 equality, #15 count < range, #16 count > range, signed (branchless idiom checked over 200,000 random pairs, 0 errors); #8/#9 with range 0 both false (r3 = 0 before the jump, 100156c0); #9 true with no player. | keep | Units/Rules.swift:91-103 | 10015870..100158d8, 100157cc..1001581c | — | HIGH | — |
| 10 | Rule #5: some member with includeInGroundAccuracyCount AND on screen (inclusive 0 ≤ x ≤ trunc(PF54), 0 ≤ y ≤ trunc(PF55)); no spawn-delay or deleted test. Test's eight edge values are right. | keep | Units/Rules.swift:163-178 | 100353e0..100354c0, 10016bd0..10016c9c | — | HIGH | — |
| 11 | `isOnScreen` NaN: the original's x tests (`blt`, `bgt`) let a NaN x pass and only the y tests decide; the replica's `x >= 0` rejects it. | change | Units/Rules.swift:172-178 | 10016bf4..10016c3c | Write the x tests as `!(x < 0)` and `!(x > W)` to match. | HIGH | Minor (NaN only) |
| 12 | Timer right: fires only on `now == start + timer`; "Delete" → +0xcb = 1, +0xd9 = −1, not destroyed; "Destroy" → destroy with killer −1 and now; empty or "none" → nothing; else enter by name, then the out-bytes; pause flag read from the current (new) state; a timer removal skips the flag. | keep | Units/StateTimer.swift:25-72 | 10033c58..10033d80 | — | HIGH | — |
| 13 | The destroy-hook stub of C10 (a40d986, flags only) is gone; `removeByStateMachine` now calls C11b's real `destroyEntity(i, killer: −1, now:)`. No stub left in the area files. | keep | Units/StateTimer.swift:53-64; Combat/Destruction.swift | git log | — | HIGH | — |
| 14 | Spawn-set executor right: skip tests (none, inactive, rate < 0, fleeing without SpawnIfFleeing); off-screen cancel only when 0 < remaining ≥ volley; countdown −1 then issue at ≤ 0 with the delay redrawn first; re-arm when now ≥ last + rate, draws delay → volley → rate, no request that tick; TimeToPause raises +0xc4 only when strictly greater. | keep | Units/SpawnSets.swift:34-85 | 10015bb8..10015d58 | — | HIGH | — |
| 15 | Rotated offset: facing + HeadingDegrees (one −360 when > 359) when SetHeading, used for both the rotation and the request heading; dx = fused xr·c − yr·n (`fmsubs`), dy = fused xr·n + yr·c (`fmadds`), truncated, added to x/y. `addingProduct` is used exactly where the listing has `fmsubs`/`fmadds` (negating yn is exact, so `(−yn).addingProduct(xr, c)` equals `fmsubs`). Absolute and scaled branches also match. | keep | Units/SpawnSets.swift:106-150 | 10015e18..10016188 (10016048/4c, 100160d0/dc) | — | HIGH | — |
| 16 | `testShurikenControllerThreeGroups` checks requests against rates READ FROM THE IMPLEMENTATION (`rates` from the record), without saying so; only the range 120…125 is independent. The first rate is oracle-checked in another test, the later ones are not. | change | Tests/DeimosCoreTests/StateMachineTests.swift:303-335 | — | Pin the literal ticks (seed 0x469c2: 1000, 1125, 1245) or say they are self-derived. | HIGH | Minor |
| 17 | `runSpawnSets` indexes `st.spawnSets[k]` for k < the record count without a bound; safe only while records are built one per set (they are, `StateEntry.swift:241`). | keep (note) | Units/SpawnSets.swift:40 | 10015ba4 count taken once | Add `k < st.spawnSets.count` to the loop guard as the rotation gate does. | MED | Minor |
| 18 | Range trigger / controller right: OnRange 0.0 or dist ≥ OnRange → hunt = Hunts; "Delete"/"Destroy" out; an empty or "none" name keeps the old state for the hold test; an entered state's ReverseDirection and Hold/Hunts come from the new state; fleeing re-read after. | keep | Units/Motion.swift:70-125 | 100153d4..10015534 | — | HIGH | — |
| 19 | Not-found distance 0: the original's initial distance is `*(float*)0x100d6354` = 0.0 (code image), so 0 is exact, not a placeholder. | keep | Units/Motion.swift:34, 45 | 10005d48..10005d68 | Change the doc to say the 0.0 is the original's. | HIGH | Minor |
| 20 | Rotation gate right (pause countdown floored at 0, hold when active ∧ PauseAnyRotation ∧ 0 < remaining < volley, skip `none`). | keep | Units/Animation.swift:75-98 | 10017150..100172b0 | — | HIGH | — |
| 21 | No `inout` across a GameState call and no unbounded loop in the seven area files: loops are `for` over bounded ranges or `while k < count` with `defer k += 1`; local entity copies are written back before `issueSpawnSetRequest`/`enterState`. | keep | area files | grep | — | HIGH | — |

## Re-derivations
- **Cull** (`FUN_10012ca0`, 10012d5c..10012e38): hw = +0x2c, hh = +0x30; tests x+hw vs −m (`blt` culls), x−hw vs W+m (`bgt`), y vs −m (`blt`, no half-height), y−hh vs H+m (`ble` keeps). Code identical, including NaN behaviour. Keep.
- **Cyclic** (10017008..1001712c): `rlwinm/add/srawi` = signed m/2; draws R(m/2, m) then R(1, 100); `fdivs` by the table's 100.0, `fadds`; per axis `ble`/`bge` clamps with `fneg` of +0x110/+0x114. Code identical. Keep.
- **Random frame** (10015998..10015a14): dir from `fmuls(fl32(NumDir), fl32(heading/360))` then `fctiwz`; random branch at 10015a08 goes straight to 10015b00 without reading +0xc2. Keep.
- **Rules #14/#15/#16, #5** (10015870..100158d8, 100353e0, 10016bd0): equality via `subf; cntlzw`; less/greater via the signed branchless idiom; #5 calls the on-screen test per member with the ground-accuracy flag. Keep (NaN note #11).
- **Timer** (10033c58..10033d80): `cmpw now, +0xa4 + +0xb8; bne`; three `strcmp`s; out-bytes; `FUN_10014650` re-read into r18 before `lbz 0x346(r18)`. Keep.
- **Spawn sets** (10015bb8..10016188): order and draws as row 14; rotation path `10015f88..10015fb4` adds HeadingDegrees and wraps once; `fmsubs`/`fmadds` in both scaled and unscaled branches. Keep.
- **Nearest player** (10005d40..10005ec0, 10017ef0..10017f74): loop of 2; `fmuls dy·dy` then `fmadds dx·dx + that`; `fctiwz`; root; first kept (`cmpwi r23,−1`), later only when `fcmpo; bge` is not taken (strictly smaller). Range test `fcmpo d, float(range); bge` = strict. Both copies match.

## Bank corrections found by the audit
- none new. The handoff's C9 (right edge uses the scaled width +0x24, random-frame draw ignores the stopped flag) and C10 (rotated offset uses facing + HeadingDegrees) corrections are confirmed at 10016e28, 10015a08..10015a18 and 10015f88..10015fb4.

## Open questions for the seat
- Should the dedupe also replace the rules' `range != 0` guards with `playerWithinRange`'s own guard (they agree), or keep the guard at the dispatch as the listing does (100157d0)? Either is correct.
- Does any shipped CyclicMotion state have MaxSpeed < 1 (then the tick makes one draw, not two)? Worth one census line before C12's draw-count tests.

---

# Audit 4 — the player, combat and weapons (plus C11b's two missing review legs) — 2026-11-05

Tests run (own scratch path `build-4`): PlayerTests 10/0/0, CombatTests 6/0/0, DestructionTests 6/0/0, WeaponTests 9/0/0,
PlayerWeaponLevelTests 8/0/0 (39 executed, 0 failures).

Predictions:
- Q8 `plla` (2.6f) hit seven times by 0.4f, single-precision subtract, clamp at 0.0 → stored shields
  2.1999998 (0x400ccccc), 1.7999998 (0x3fe66665), 1.3999999 (0x3fb33332), 0.9999999 (0x3f7ffffe),
  0.5999999 (0x3f199998), 0.1999999 (0x3e4cccc6), 7th: 0.0 (0x00000000, the −0.2 clamped) and destroyed.
  Computed with a standalone Float script; `testPlatformSevenBombHits` pins exactly these bit patterns and passes.
- Q4 hold-up (step 1.6, cap 7.8, Float): y 328.4, 325.19998, 320.4, 314.0, 306.2, 298.40002, 290.60004, 282.80005,
  275.00006, 267.20007; release 261.00006, 256.40005, 253.40005, 252.00006 (tick 14), vy snaps to 0.0 on tick 15 and the
  ship rests at 252.00006 (0x437c0004). `testHoldUpTenTicks` pins the bit patterns; it passes.
- Q5 overload: simulated with interval 8, min 3, 8 warnings, fade 20 → warnings at S+9, 17, 24, 30, 36, 42, 48 and death at
  S+54, the same as `testOverloadTimeline`; S = T0+181 (activation at the 15th held tick T0 = t+14). Release stream
  r, r+2 … r+38 (20 spawns), idle at r+39 — confirmed by the listing order (`1003c35c` level ≤ 0 test precedes the `1003c368`
  timing).

## Findings
| # | Finding | keep / change / redo / missing | File:line | Why (cite listing/dump/bank) | The fix (one sentence) | Confidence | Severity |
|---|---|---|---|---|---|---|---|
| 1 | The "+0x90 last stamp time" test is treated as always true, but a shipped path can make it false: the state-entry code copies `stateDrawToTerrain` (+0x353) into +0x36 (`10014a28..10014a30`), the entity draw pass then sprite-stamps that entity (`10034b48..10034b54` → `FUN_10012f20`), which writes +0x90 = now (`100132a4`); if the same entity is destroyed and swept in that tick, the sweep's stamp sees now > now false (`10013274 ble`) and draws a normal sprite instead of a terrain stamp. Also false when game time ≤ 0, since object init sets +0x90 = 0 (`1001273c`). The code comment's reasoning (slot reuse) is moot: init zeroes +0x90 anyway. | change | Combat/Removal.swift:242-246 | listing `1001326c..100132a4`, `100126ac`/`1001273c`, `10014a30`, `10034b54` | Add the +0x90 field to the object (init 0, written by every terrain-path sprite stamp) and test it in `terrainStamp`; the draw pass must also honour +0x36 (seam for the draw owner). | MED (whether any shipped unit sets `stateDrawToTerrain` is unchecked — the paks are not plain text) | Important |
| 2 | Nothing in the replica reads `object.drawToTerrain` (+0x36): the state copy at StateEntry.swift:125 and the sweep's write are dead; the per-tick terrain stamp of a state-drawn entity (`10034b48..10034b54`) is missing. | missing | Units/StateEntry.swift:125; Combat/Removal.swift:56 | `FUN_100345f0` `10034b28..10034b5c`; `FUN_10012f20` | Route the entity draw pass through the +0x36 branch (C12/C18 draw seam). | MED | Important |
| 3 | `removeMemberStub` still exists and is the only path both walkers use; it forwards to the real `removeMember` with byPlayer false, so behaviour is right, but the name says stub. | change | Combat/Removal.swift:199, 201, 220, 228-230 | `10034c74..10034ca8` (r6 = 0), `10034e98..` | Inline it: call `removeMember(..., byPlayer: false)` directly and delete the stub. | HIGH | Minor |
| 4 | Walkers `destroyEntitiesOwned(byPlayer:)` / `removeEntity(serial:)` are wired to the real removal with both counts snapshotted once — matches `10034bc0`/`10034c14` (and `10034e04`/`10034e58`); destroyed arg 1/0 and byPlayer 0 match. | keep | Combat/Removal.swift:188-224 | listing `10034b90..10034cd4`, `10034de0..` | — | HIGH | — |
| 5 | No test exercises `destroyEntitiesOwned` with an owned entity (death with a live player-owned unit); `testDeathOrder` has none, so the "owner destruction first" step and its draws are unproven. | missing | Tests/PlayerTests.swift:292-324 | `10027e70..10027e74` runs before the death spawn | Add a case: a player-owned unit with `canBeDestroyedOnOwnerDestruction` dies (and draws) before the death spawn. | HIGH | Minor |
| 6 | `testDeathOrder` passes `now: s.flags.gameTime`, so it cannot tell `now` from game time; `killPlayer` correctly takes `now` (listing stores r25 = r4 at `10028110`; callers pass r29 at `100271d8`, r30 at `10027058`). | change | Tests/PlayerTests.swift:301 | `10027e64`, `10028110` | Call with `now ≠ gameTime` and assert `stateEntered == now`. | HIGH | Minor |
| 7 | `killPlayer` order matches the listing: owner destruction, death spawn (+0x14 = +0xcc), shield 0 if not in game, hit timers, displayed shield and power 0.0, coins 50/10/5/1 (gaob 2/3/4/5, one struct, count decremented even for `none`), money 0 (obfuscated 0xb2cce), state 3 at now, +0xce if in game, multiplier reset via `FUN_10034de0` + `FUN_10029fd0`. | keep | Player/PlayerLife.swift:170-205 | `10027e50..10028168` | — | HIGH | — |
| 8 | `destroyEntity` order and guards match `10016300..10016530`; the bonus draw `R(0, 100)` is the last action before the ladder; the ladder thresholds (flli 209…219) and the reward rule (armed ∧ r < F(218) → O(30) and disarm) match `1001653c..100167b8`. | keep | Combat/Destruction.swift:57-150 | listing as cited | — | HIGH | — |
| 9 | `testDestroyOrder` checks the bonus object with the replica's own `randomBonusObject(r)` and only `0…100` for r — the draw's value is never replayed from an independent RNG copy, so "R(0,100) is the last draw" is checked by step log, not by RNG state. | change | Tests/DestructionTests.swift:68-71 | — | Replay the RNG on a copy (as `testMediaGateWater` does) and pin r. | HIGH | Minor |
| 10 | Media gate and mask lookup match `10016880..10016bb4` and `1000fee0..1000ffb4` (not-ground-based or any-media → allowed; point trunc x + 32, trunc y + window top; divw toward zero then bounds; cell == 0x001f; smra/mera/lara draws at `10016a24`/`10016a64`/`10016ac8`; impact spawned from r2+0x180; returns 0). | keep | Combat/MediaGate.swift:14-69 | listing | — | HIGH | — |
| 11 | `isWater` indexes `row·width + col` into packed cells; the original uses rowBytes from `FUN_1000a4a0` (`1000ff70..1000ff84`). Correct only if the loader unpacks rows without padding. | keep (check loader) | Combat/MediaGate.swift:19 | `1000ff78 mullw r3,r31,rowBytes` | Confirm the mask loader strips row padding. | LOW | Minor |
| 12 | Sweep matches `10036610..10036928`: counts once, accuracy −1, +0x36/+0x35/+0x38 then stamp, owner destroy with +0xd9 at game time, deletion spawn only when not destroyed and the gate allows (template r2+0x50ec), byPlayer = +0xd9 ≠ −1 (`10036850..10036860`), unlink, free, group freed when empty and not PERM. `removeMember` matches `10036120..100363b8` (children, +0xac/+0xa4 group kill, coins with +0xca guard and count read once, group coin not for PERM, destroy, +0xcb, +0xa8 −1, return). | keep | Combat/Removal.swift:38-137 | listing | — | HIGH | — |
| 13 | The deletion spawn uses `childRequest` (shared `SpawnRequest.template`) although the listing copies r2+0x50ec, not r2+0x180; correct only if both runtime templates are identical. | keep (verify) | Combat/Removal.swift:68 | `100367a4..1003683c` vs `100163f0..` | State the equality of the two templates (memory image) in the doc comment. | LOW | Minor |
| 14 | C11b's 7-line edit to C11a's `testShotResolvesPairOnce`: justified — the old test relied on the stub that drew nothing; the shot (A) does die first and its destruction draws precede B's (`10037014..10037050` before `10037058`). But the expected RNG state now comes from replaying the replica's own `damageEntity` on a copy (implementation vs implementation). | keep | Tests/CombatTests.swift:390-396 | listing `10036fc4..100370ec` | Accept; optionally pin the shot's destruct draws by count. | HIGH | Minor |
| 15 | The player ram redirect to the owner (`10034228..100342b4`, the pre-controller state's +0x32b, `FUN_10036ab0`) is **already built** in `collideWithPlayers`; the plan's "C12 must build it" is stale. Uses the passed pre-controller state. | keep | Combat/Collision.swift:145-153 | listing | Strike the item from C12. | HIGH | — |
| 16 | Collision rules match: strict circle (`dist < ra + rb`), entity radius = signed half height (C division), player cache radius = float(b−t)·0.5, per-victim hit delay `now > lastHit + trunc(flli 167)`, A-then-B resolution with the B-side copy-paste bug kept (`10037074..100370c4` tests A's owner link), `damageEntity` keeps the old state pointer after an on-hit state change (`10014fc4..1001502c`). | keep | Combat/Collision.swift:52-68, 120-160, 207-272; Combat/Damage.swift:35-99 | listing `10042f80`, `10034180`, `10014f10`, `10036cf0` | — | HIGH | — |
| 17 | `collideWithPlayers`, `entityCollisionStep`, `sweepDeleted` and `playerCollisionCache` have no caller outside tests — the entity update (C12) is not wired yet. | missing (seam) | Combat/Collision.swift:72,120,182; Combat/Removal.swift:38 | — | C12 wires them in the listing order. | HIGH | Important |
| 18 | `tickWeapons` calls `refreshFaceFromWeapon()` when switched and stores the previous-button bytes at `1003b9d4..1003b9e8`; listing order of select/air/bombs/crosshair/launch matches `1003b8a8..1003ba8c`. | keep | Weapons/WeaponTick.swift:64-114 | listing | — | HIGH | — |
| 19 | `Player.sector` still exists; its only readers are `Player.levelStart`'s `sector ?? self.sector` fallback and WeaponTests:312 (the Phase-1 session). Its doc comment still names `scoreBarIcons()` and `ScoreBarState` "without a sector" — both now require one. | change | Player/Player.swift:228-232, 307; Tests/WeaponTests.swift:312 | — | Retire in C18a with the session; fix the doc now. | HIGH | Minor |
| 20 | `resetHandler(levelStart:sector:)` defaults sector to 0; a future level-start caller that forgets it equips nothing silently. | change | Weapons/WeaponHandler.swift:201 | `1003b0dc` reads G+0x14 | Make `sector` required. | MED | Minor |
| 21 | Overload flash ramps the object glow +0x58 (`10026fdc..10027008`, `1002707c..100270b0`), not +0x214; tail writes +0x54/+0x5c/+0x60/+0x64 (`100270b4..100270d8`); the clear path resets +0x210…+0x220 and +0x54…+0x64 (`10026f24..10026f58`). | keep | Player/PlayerLife.swift:213-258; Player/Player.swift:348-354 | listing | — | HIGH | — |
| 22 | Power-up machine and release stream match `1003c0d0..1003c4d8` (activation at held ≥ 15, overload `now > start + OverloadTime`, level step, percent single `fdivs` × double 100 `frsp`, clamps, state-3 level ≤ 0 test before the release timing → idle at r+39). | keep | Weapons/PowerUp.swift:45-119 | listing | — | HIGH | — |
| 23 | `testPlatformSevenBombHits` hard-codes `damage: 0.4` rather than reading the Plasma Bomb's `damage_FLOAT`, so the "bomb" in the name is not checked against data. | change | Tests/DestructionTests.swift:147 | — | Read `plbo`'s damage from the assets and assert it is 0.4f. | HIGH | Minor |
| 24 | `addScore` matches `10029a10..10029b10`, including the odd raw path (+0xa0 = new + trunc(flli 182)) and the strict threshold. | keep | Player/PlayerScoring.swift:19-37 | listing | — | HIGH | — |

## Re-derivations
- **Destroy order (Q1).** `FUN_10016300`: +0xcb guard `10016320`; glow off `10016330`; obstacle when not air and +0x4b3 (`10016338..10016364`); particles when +0x47c ≠ none (`1001636c..100163c4`); spawn only when +0x478 ≠ none and the gate allows (`100163cc..10016488`); notice (`10016490..100164d0`); sound (`100164d8..100164f0`); +0xcb/+0xd9/+0xda (`100164f8..10016504`); accuracy (`10016508..10016514`); bonus `R(0,100)` at `10016530` then the ladder. The code and `testDestroyOrder` follow this. Ladder: flli 209 (70): armed → flli 218 (10) → gaob 30 + disarm, else gaob 25; flli 210…216 → gaob 26…32; then sector < flli 219 (3) → gaob 32; r < flli 217 (100) → 33 else 34. So 69 → rb01, 70 → rb02, 97 → rb08, 98 → rb08 at sector 1/2, rb09 at sector 3, 100 → rb10 at sector 3; armed ∧ r < 10 → rb06 once. Verdict: right.
- **Media gate (Q2).** As row 10; the impact objects gaob 6–9; return 0 after the impact. Sweep `FUN_10036610` / `FUN_10036120` as row 12. The +0x90 test is not in `10036610..` itself but in the stamp it calls (`FUN_10012f20` → `10013264..100132a4`); see row 1.
- **Seams (Q3).** Walkers right (row 4); `removeMemberStub` exists and is called at Removal.swift:199, 201, 220, but forwards to the real removal (row 3); `killPlayer(_:now:)` takes now (row 6).
- **Hold-up (Q4).** Velocity `fsubs`/cap and the integrate `fadds` reproduce the pinned values; see Predictions.
- **Death and overload (Q5).** As rows 7, 21, 22 and the Predictions.
- **Collisions (Q6).** As rows 15–16.
- **Seams for C12/C18a (Q7).** Rows 15, 17, 18, 19, 21.

## Bank corrections found by the audit
- sprite-geometry-draw.md §3.2 (and the handoff's C11b note): the +0x90 "last stamp time" is initialised to 0 by the object init `FUN_10012650` (`1001273c`) and written only by the terrain-path sprite stamp (`100132a4`); a state with `stateDrawToTerrain` makes the draw pass stamp every tick (`10034b54`), so a same-tick sweep stamp fails the test.

## Open questions for the seat
- Does any shipped unit state set `stateDrawToTerrain` (+0x353)? If none, row 1 drops to Minor (time ≤ 0 only).
- Are the runtime templates r2+0x180, r2+0x50ec and r2+0x2ea4 byte-identical apart from what the code sets? `SpawnRequest.template` assumes one template for all.

---

# Audit 5 — end of level, notices and messages, particles, begin-frame keys, console — 2026-11-05
Also discharges C17 review leg 2 (spec / tests / seams) on f22a2a0. **Verdict on C17: MERGEABLE** (minors only).

Tests run (own scratch path `build-5`): LevelEndTests 8/0/0, NoticeMessageTests 6/0/0, EffectsTests 8/0/0,
FrameKeysTests 4/0/0, ConsoleTests 5/0/0, ParticleStampTests 3/0/0 (34 passed, 0 failed, 0 skipped).

Predictions:
- Q8: sector 1, 17 of 20 destroyed → (float)17/(float)20 = 0.85f, × 100.0 (double) → frsp → **85.0** → percent 85.
  Gap flli 188 = 5, so the steps are 100/95/90/85/80; 85.0 ≥ 85 → **tier flli 192 = 500**; bonus 500 × sector 1 =
  500; step max(trunc(500 × 0.02f) = 10, 100) = **100**; state 6 pays 5 × 100 = **500 exactly** (no overshoot), times
  each in-game player's multiplier. `testAccuracyTiers` row (17, 20, 1 → 500, 100, 85 %, not perfect) passes.
- Q3 overshoot: 16/20 → 80.0 → tier flli 193 = 250; step 100; remaining 250 → 150 → 50 → 0 (clamped) but each
  payment is the full step → 300 (`testTallyOvershoot` asserts 300 × multiplier 2). Coin: money 30 → bonus 3000,
  step max(60, 100) = 100 → 30 payments; money 60 → 6000, step 120 → 50 payments; both sum to the bonus exactly.
- Q6: `testMotionBlurLifetime` asserts BOTH 6 passes in the list and 5 visible draws. 5 visible is right (the 6th
  pass has visibility 0.0 and the entity draw skips ≤ 0).

## Findings
| # | Finding | keep / change / redo / missing | File:line | Why (cite listing/dump/bank) | The fix (one sentence) | Confidence | Severity |
|---|---|---|---|---|---|---|---|
| 1 | Nothing in production calls `TallyState.reset()` (`FUN_10007280`), nor resets the ground counts (`FUN_10007150`), nor calls `playerLevelStart` (which holds the coin-tally reset). Only the tests call them. | missing (carry) | TallyState.swift:59; LevelEndTests.swift:23 | dump 4557 (`FUN_10007280`); handoff "C18a: call tally.reset() at level start" | C18a's level start must call `tally.reset()`, the ground-count reset and `playerLevelStart` in `FUN_100064d0`'s order; add a test that a second level starts its tally clean. | HIGH | Important |
| 2 | No caller yet for `gameOverStep`, `levelEndStep`, `levelCompleteStep`, `notice.tick`, `particles.update/stamps`, `blurs.update/drawCommands`, `debris.update`, the message/console/notice/tally draws, `FrameKeys.beginFrame/endFrameWrapper`, `PauseScreen.musicAfterWait`. | missing (carry, by plan) | LevelEnd.swift:51,73,125; FrameKeys.swift:32,99,192 | C12 (wave 2.7) and C18a (2.8) are unbuilt; DeimosSession is still Phase 1's | C12/C18a briefs list each of these with its slot in `FUN_10006b50` / `FUN_10007070` / the pass. | HIGH | Important |
| 3 | The "Reached Motion Blur Limit" text exists in no source file; `emit` only returns `postLimitMessage`. | missing (carry) | MotionBlurPool.swift:26–29,74–79 | listing 10046ef4..10046f04: `FUN_1002dbd0(text, 1, 1, 0)` | C12's caller posts it with kind .error, uppercase true, readout 0. | HIGH | Minor |
| 4 | `tallyTextRequest` / `tallyTextCommands` still untested and uncalled; the record itself matches the dump. | change (test) | Tallies.swift:353–366 | dump `FUN_10007d60` (after 4945): state ≠ 0, alpha < 0x20 unsigned, format 0x35, +0x10c = 15, +0x10d = 1, +0x110 = 0, +0x114 = alpha | Add a test: nil at state 0 and at alpha 32, the record at state 2 with alpha 29. | HIGH | Minor |
| 5 | Notice spawn position (208, 240) and the money counter's (105, 248) / stacked +70 are not asserted; tests check only the unit IDs and `textYOffset`. | change (test) | LevelEndTests.swift:174,203,260,303 | dump 4302–4311, 4365–4370 (flli 54/55 × 0.5); 23400–23412 (flli 179/180/181) | Assert the spawned entity's x/y for `nogo`, `nole` and `p1mc`/`p2mc`. | HIGH | Minor |
| 6 | flli 173 is read on every coin-tally call, including states 0, 1, 6, 7, 8 where it is unused. Pure read, no effect. | keep (cosmetic) | Tallies.swift:277 | dump 23440+: read only inside states 2–5 | Optionally move the read into those states. | HIGH | Minor |
| 7 | The `noal` branch (sector 12 and 12 levels started → G+0x0d) is not exercised through `levelEndStep`; the timeline test sets `allLevels` directly. | change (test) | LevelEndTests.swift:144–152, 240–292 | dump 4334–4344 | Add a case with sector = levelsStarted = 12 asserting `.notice(noal)` and `allLevels`. | MED | Minor |
| 8 | `testLevelCompleteClearsRunningInFilm` does not check the `levelTransitionReset` effects (messages cleared, console reset, FPS init, divider). | change (test) | LevelEndTests.swift:347–355 | dump 4504 (`FUN_100302e0` after the flags) | Post a message and open the console before, assert both cleared after. | MED | Minor |
| 9 | The FPS monitor stores the same `ticks` as the window start; the original calls TickCount a second time (10030764). | keep | FrameKeys.swift:241 | dump `FUN_10030640` | None (equal inside one call in practice). | LOW | Minor |
| 10 | HeldKeys doc "C19 pins the codes" flagged stale by the C19 review; Console now does pin them (Console.swift:101–109), so the line is accurate but points nowhere. | change (doc) | Seams/HeldKeys.swift:11 | handoff "C19 review" | Name `Console.upArrow…tildeKey` as the pinned codes. | LOW | Minor |
| 11 | Level end: first tick, later ticks, coin setup and tally per player, level complete — every branch and order as in the dump. | keep | LevelEnd.swift:51–116 | dump 4295–4441 | — | HIGH | — |
| 12 | Game over: `nogo` once, latch + start; running cleared at start + 111 (strict). | keep | LevelEnd.swift:51–62 | dump 4296–4330 (`+0x34 + int(flli 13) < now`) | — | HIGH | — |
| 13 | Level complete: nobody in game or film → running 0 only; else music stop, `tran` (75, 100, 1), +9/+0x39 cleared, transition reset, then the S9.1 stand-in. | keep | LevelEnd.swift:125–144 | dump 4504–4552 | — | HIGH | — |
| 14 | Accuracy tier, tally states 0–10, coin setup and tally match the dump state by state (waits, sounds, texts, alpha, clamps). | keep | Tallies.swift:88–346 | dump 4579–4945, 23327–23560 | — | HIGH | — |
| 15 | Notice slot: `lastTick` stored before the active test; delay > 0 start/sound one tick late; fade-in 2, clear at start + 61, fade-out 4, active off at ≥ 32. | keep | NoticeSlot.swift:124–148 | dump `FUN_10018320` (`&&` short-circuit stores first) | — | HIGH | — |
| 16 | Messages: cap 20 drops the NEW one, readout match clears sticky, empty text ignored, aging `post + 60 < clock` unsigned, +1 per frame, delete at > 31 and return (one per frame) → 92-frame life. | keep | MessageQueue.swift:98–131 | dump `FUN_1002dbd0`, `FUN_1002dd90` | — | HIGH | — |
| 17 | Particle colour variants and the stamp kernel match the listing; D is fringe, E/X core. | keep | ParticleSystem.swift:183–206; ParticleStamps.swift:53–81 | listing 10043518..1004373c; 10043d20..10043dd4, 10043fc4, 10044014..10044054 | — | HIGH | — |
| 18 | Motion blur: cache-0 quirk at level reset, cached index used without an in-use check, 1000 cap, limit flag once per level, 6 passes / 5 visible. | keep | MotionBlurPool.swift:60–126 | listing 10046eb0..10046f24 | — | HIGH | — |
| 19 | Keys and console: Caps Lock pause (halt, `incl` 50/100/1, music pause, `.pauseWait(.gameScreen)`, resume in `musicAfterWait`); volume keys pref-only ∓10 clamped; F6 message then toggle then gaso 7 (100, 100, 1); FPS init 30 into both counters; ten commands; `supermunki`; 30-char cap; 120-frame expiry; unknown command posts type 1 with no sound and no recall; up-arrow strcpy keeps the tail; reset clears the draw flag. | keep | FrameKeys.swift:99–242; Console.swift:136–210; Cheats.swift | dump `FUN_10030910`, `FUN_10030640`, `FUN_100305e0`; listing 10008e2c..10008f38 (SCORE) | — | HIGH | — |

## Re-derivations
- **Level end (`FUN_10006b50`, dump line 4222).** Game over: after the player loop, no player in game (+0xc4) → G+0x0a = 1;
  latch (stack byte `param_3`) clear → `FUN_100201f0(0x18)` unless `none`, request at flli 54/55 × `*(puVar2+8)`, then
  latch = 1, G+0x34 = now; else `G+0x34 + int(flli 13) < now` → G+8 = 0. Then `FUN_10010000() == 1` → G+0x39 = 1;
  G+0x29 clear: G+0x0a set → G+0x29 = 1 only; else G+0x14 and G+0x10 == `FUN_10011de0` → G+0x0d; 0x16/0x17 notice;
  G+0x29 = 1, G+0x2c = now; `FUN_10027de0(p,1,0)` per in-game player; `FUN_100072c0(now)`. Later: `FUN_100075e0`
  done → all = 1, stacked = 0; setup for in-game players whose +0xd8 == 0 (all = 0); `FUN_10027930` for each in-game
  player; all → G+9. The code is the same branch for branch, and `testLevelEndSequenceOrder` pins the order.
- **Accuracy tally (`FUN_100075e0`, dump 4679–4945).** State 0 returns 1. 1: wait flli 195 (196 if G+0x0d) → 2,
  moco. 2: alpha −1 × int(flli 203) not below 0; wait 197 → 3, moco, then text "%s%i%%". 3: wait 197 → 4, text +
  pgsl 12, then moco. 4: wait 197 → 5; 100 % → G+0x44 += 1 + acbo, bonus 0 → nobo, else moco. 5: text "None!" or the
  bonus every tick; wait 197 → 6. 6: bonus < 1 → 7 at once; else past tick timer + flli 198: tick timer = now, bonus
  −= step clamped at 0, `FUN_10029a10(Pn, step, 0)` for both, moco, text. 7: wait 201 → 8. 8: alpha < 0x20 unsigned →
  += flli 204, capped 0x20; wait 202 → G+0x44 == 12 → flag, payments 0, state 9, alpha 0, pgsl 10, miac (priority 100)
  else return 1. 9: wait 206 → 10, alpha 0x20, text "". 10: flag clear → 1; past flli 207: payments += 1, both
  players `FUN_10029a10(Pn, int(flli 205), 1)`; payments < flli 208 → 9 (alpha 0, pgsl 10) else flag 0.
  `Tallies.swift` matches each state, and `testAccuracyTallyTimeline` pins it (1061 → 2, then every 21 ticks; payments
  1146/1149/1152; done at 1195; alpha 29 at 1062 … 0 at 1072; 3 at 1175 … 32 at 1185) — I re-computed the numbers by
  hand and they agree. The bank's MED labels for states 1–5, 7 and 9 can be raised to HIGH.
- **Tier and coin (`FUN_100072c0` 4579, `FUN_10027670` 23327, `FUN_10027930` 23440).** The tier compares the
  untruncated float against `(double)(float)(100 − k·g)` (≥); bonus = int(tier) × G+0x14; step = max(trunc(f × flli
  200), int(flli 199)). Coin: value = flli 170 == 0 ? flli 171 : sector × flli 171; money0 = +0xac − 0xb2cce (the
  plain `Player.money`); bonus = money0 × value; state 6 calls `FUN_10029a10` even when out of the game but takes the
  money only in game; the remaining amount is not clamped. The code matches. I checked the counter's template
  (`0x100e91d4`) against the notice template (`0x100e3ca4`): their copied constants are the same (both zero / −1), so
  the code's use of the generic `SpawnRequest` is correct.
- **Notices and messages.** Re-derived above (rows 15–16). Message life: posted at clock c, opaque through c + 60, fade
  1 at c + 61, 31 at c + 91, deleted at c + 92. Notice: post at 100 with fade-in, first tick 101 (start = 101, sound,
  alpha 30), 0 by 116, flag off 117, cleared at 162 (> 101 + 60), alpha 4 … 32 and off at 169.
- **Particles.** App-start tables from a private seed-1 generator (300 draws + 2 → burst index 50, ring index 79,
  `testStartIndicesFromSeedOne`). Colour: per channel `trunc(65535 × (c × 0.03125))`; factor `frsp(1.0 − i × CVA)`;
  core `trunc(c16 × factor)`; fringe `trunc(core × FCA)`; packed `(R>>1 & 0x7c00) | (G>>6 & 0x3e0) | B>>11`. For
  0x7FFF: c16 = 63487 → core 0x7BDE; with FCA 0.6 the fringe channel is 38092 >> 11 = 18 → 0x4A52; the test's variants
  30/27/23/19/16 imply CVA 0.12. Kernel: dst spread × w + colour spread × (32 − w), >> 5, re-packed (10043da8..dd4).
- **Motion blur.** Listing 10046ed0: count ≥ 1000 → flag at header + 8 tested, message posted `(text, 1, 1, 0)` once;
  else cached index (−1 → scan of 100 × 10). Update `vis −= step`, freed when `vis < 0.0`: 50/10 → drawn at 50, 40,
  30, 20, 10, kept at 0 (not < 0), freed on the 6th update.
- **Keys (`FUN_10030910`, `FUN_10030640`, `FUN_100305e0` in the dump).** The volume latches and the F6 order (message
  by the old pref 5, then the toggle, then gaso 7 at (100, 100, 1)) match; the OS 9 click/message branch is gated by
  `FUN_100461b0` and is correctly not built. FPS init writes int(flli 32) into +0x20 and +0x24. The monitor counts
  deficient windows only with byte pref 10 and compares `==` flli 34.

## Bank corrections found by the audit
- scoring-bonuses.md §6.4: raise states 1–5, 7, 9 from MED to HIGH (dump 4679–4945).
- scoring-bonuses.md §6.4 table: moco (gaso 20) plays on the exits of states 1, 2 **and 3** (2 → 3 and 3 → 4 too); the
  table shows a sound only at 1 → 2. State 8's mission sound is **priority** 100 (volume 100); the bank says only
  "at volume 100" (`FUN_10047670(id, 100, 100, 0)`, dump 4907).
- scoring-bonuses.md §6.5: the coin tally also plays moco on the exits of states 2 and 3 (dump 23472, 23486), not only
  1; and `FUN_10029a10` in state 6 is called even when the player is out of the game (only the money −1 is gated).
- The particles, notice and message corrections already in the handoff hold. Nothing new found there.

## Open questions for the seat
- C18a's level start: confirm the order of `FUN_10007280`, `FUN_10007150` and the per-player `FUN_100269a0` inside
  `FUN_100064d0` before briefing (row 1).
- Is the tally text draw (`FUN_10007d60`) C12's, as part of `FUN_10007070` (dump 4446: after the player draws, before
  the notice draw `FUN_100184b0`)? If so, add it to the C12 brief with that order.
