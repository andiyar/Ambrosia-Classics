# Plan — Bubble Trouble X core simulation + FILM replay harness — 2026-10-03

> Status: LOCKED (two Fable-grade reviews ACCEPT_WITH_FIXES 2026-10-03; fixes applied; orchestrator rulings recorded)
> Planner: Opus, 2026-10-03. Every review finding and where it landed: §"Review ledger" at the end.
> **For agentic workers:** execute task by task with superpowers:subagent-driven-development. Steps use
> checkbox (`- [ ]`) syntax. This plan carries **contracts, not code** (Ben, 2026-10-03): exact paths, public
> signatures, test names with their numeric bars and citations, commands, commit messages. Every number a
> step "expects" was produced by a tool on this machine on 2026-10-03 (decompile/disasm reads, Python over
> the extracted resources); if reality differs, STOP and report — never edit an expectation to match.

**Goal:** a pure-Swift package `BubbleTrouble/Core` (library `BubbleTroubleCore`, executable `btx-replay`,
tests `BubbleTroubleCoreTests`) that loads the real `MAZE`/`LEVL`/`FILM` resources through HectorResources,
builds a level in the original's exact RNG draw order, steps it frame by frame in `_PlayGame`'s exact update
order (cosmetic pools included, because they consume RNG), and replays the four shipped FILM demos until
their recorded input runs out.

**Architecture:** value-type simulation. `GameRandom` (one swappable LCG step + `_GetRandomFast`) is
threaded `inout` through every system. Cosmetic pools (stars, air bubbles, score points, splats) are
self-contained structs; `GameState` owns all entity arrays at their original capacities and slot order;
each original function becomes one `GameState` method in a file named after its domain. No AppKit, no
rendering, no sound playback — sound calls are dropped (they consume no RNG), sprite set/frame numbers and
rects are kept so a later shell can draw.

**Tech stack:** Swift 6.4 (`swift --version` → `Apple Swift version 6.4`), SwiftPM tools 6.0, macOS 15,
XCTest, Foundation, HectorResources (HectorKit v0.1.0 by local path; HectorKit head on 2026-10-03 is `8287ddb`
= `v0.1.0-2-g8287ddb` — the two commits since the tag are HectorShell-only, and every HectorResources API this plan
cites (`ContainerBackend.swift:23/87`, `Resource.swift:33-35`, `ByteReader.swift:9`) was re-checked at that head).
No other dependency.

**Spec (read before any task):** the RE bank `docs/bubble-trouble/` — `INDEX.md`, `engine-loop.md`,
`hero-and-input.md`, `enemies-ai.md`, `bubbles-items-scoring.md`, `data-formats.md`, `replay-oracle.md` —
plus the corrections in this plan's §"Bank corrections to append" (they override the bank where they differ).
The decompile is the tie-breaker: `D=/Users/andiyar/Developer/Ambrosia/ghidra/BTX_i386.decompiled.c`, read
with `python3 ghidra/find_func.py --func <name> --file "$D"`; folded enemy functions via
`otool -tV /Users/andiyar/Developer/Ambrosia/ghidra/BTX_i386`.

**Paths used by every command block** (shell state does not persist — each block re-declares):
```sh
WT=<root of the executing Classics worktree>          # never the main checkout; a parallel lane = its OWN worktree
SCRATCH=<the executing session's scratchpad directory> # logs/traces live here — never /tmp (lanes must not share logs)
R="/Users/andiyar/Developer/Ambrosia/Resources/ambrosia-extracted/Action-Adventure/Bubble Trouble X/BubbleTroubleX_1.1_UB/Bubble Trouble X.app/Contents/Resources"
D=/Users/andiyar/Developer/Ambrosia/ghidra/BTX_i386.decompiled.c
```

---

## Verification model (read first)

**Machine-verifiable — the executor closes these alone:**

| # | gate | expected (exact) |
|---|---|---|
| G1 | whole suite, data wired | `HECTORKIT_DATA_BTX="$R" swift test` → **119** `Test Case … passed` lines, **0** `failed`/`skipped` lines (count after Task 11's golden freeze, run from the final merge head; per-task counts below) |
| G2 | the replay table | `btx-replay` prints one row per FILM 1–4 with `samples == count` (1118 / 846 / 943 / 890), `end = count` — or `end = count,level` when the level completed within the final 70 frames before count exhaustion, which **passes but is FLAGGED** on the row and in the gate message to Ben (Invariant 14, orchestrator ruling) — `first-catch = -` (or the final frame, see Invariant 14), then `ACCEPT 4/4`; exit status 0 |
| G3 | data gating | without the env var the suite still runs: **100** passed (synthetic), **19** skipped (data-gated: T0 1, T2 8, T4 5, T10 2, T11 3), 0 failed; every skip message contains `HECTORKIT_DATA_BTX` (before the golden freeze: 100 / 18) |
| G4 | determinism | `testReplayIsDeterministic`: two runs of each FILM produce identical per-frame `(drawCount, samplesConsumed, score)` sequences |
| G5 | scope fence | this plan's commits touch only `BubbleTrouble/Core/**`, `docs/bubble-trouble/**` (Task 12) — `git diff --name-only <base>..HEAD` proves it; no HectorKit file, no `Aki/`, no other game's docs |

Gate commands (each is also a task step):
```sh
cd "$WT/BubbleTrouble/Core" && HECTORKIT_DATA_BTX="$R" swift test > "$SCRATCH/btx-test.log" 2>&1; echo "exit $?"
grep -cE "^Test Case '.*' (passed|failed|skipped) \(" "$SCRATCH/btx-test.log"     # → per-task total
grep -cE "^Test Case '.*' (failed|skipped) \(" "$SCRATCH/btx-test.log"            # → 0
cd "$WT/BubbleTrouble/Core" && swift build > "$SCRATCH/btx-build.log" 2>&1 && \
  HECTORKIT_DATA_BTX="$R" "$(swift build --show-bin-path)/btx-replay"; echo "exit $?"
```

**The FILM oracle, stated honestly (brief non-negotiable 5).** The bank derives **no** end state (frames,
score) for any FILM — `replay-oracle.md` §6 only says FILM 1 "should end by `count` exhaustion (1118 samples)
unless the hero dies first". So the machine bar is behavioural self-consistency, not equality with the original:
(a) the sample pointer advances only on `_CheckHeroMovement` calls; (b) each demo ends by count exhaustion —
the hero is not caught before the final frame and the level does not complete-and-stop before the samples run
out (a desync almost always walks the hero into an enemy early) — **orchestrator ruling:** a level completed within
the final 70 frames before count exhaustion (so its +70 stop had not yet fired) is a pass, but the harness prints
`end = count,level` and FLAGS the row, and the gate message to Ben names it; (c) the harness prints frames, samples,
total RNG draws, score, lives, level, end reason (+ per-frame RNG draws on `--trace`); (d) after a Fable
plausibility review the observed numbers (incl. total draws) are frozen as goldens **labelled self-derived, not
bank-derived**.

**Honesty gates (Ben only):** that our replay *looks like* the original's demo (NR-10 — only Ben's eyes on the
original, at default prefs, can close it; it needs the later shell plan to show anything). Phrase every
completion claim as "the core replays FILMs 1–4 to count exhaustion with self-consistent numbers", never
"matches the original".

**Known deltas to disclose up front (so none is mistaken for a bug):**
1. Nothing to look at or hear: no rendering, no sound, no menus — the core exposes sprite set/frame numbers and
   rects only.
2. The QuickDraw `Random()` step is an **external fact at [LOW]** (Apple's documented Park–Miller step with the
   0x8000→0 adjustment; NR-3). It is the first suspect if any FILM desyncs; `btx-replay --rng-variant` exists
   for that diagnosis only.
3. FILM recording conditions are unknown (NR-9) and the FILMs may predate X 1.1 (NR-10); a FILM that will not
   reach count exhaustion after the Diagnosis protocol is reported as such, never "fixed" by tuning.
4. Golden numbers (frames, score, lives, total RNG draws) are self-derived (Task 11), not oracle values.
5. Registration is modelled "registered, valid licence" (INDEX Decision 2). **For levels 1–4 the choice is
   RNG-neutral** (Research note 6) — the FILMs cannot distinguish it.
6. Session latches default to u = 1, L = 15 (process seed 1, NR-3 [LOW]); they only matter from level 9 (u) /
   13 (L), so not for FILMs 1–4.
7. Play-mode level transitions (`_TimeBonus_CountDown`, `_NewLevel` for level n+1, the unregistered level-7 stop),
   pause cheats, orbit stars, the level editor, high scores, prefs UI are deferred (Scope).
8. The plan corrects the bank in 12 places (§"Bank corrections to append"); the code follows the corrections.
9. A FILM whose level completes inside its last 70 frames is accepted but FLAGGED (`end = count,level`) — Ben is
   told at the gate; it is not hidden inside an `ACCEPT`.

---

## Non-negotiable invariants

These override any task step if they conflict.

1. **Scope fence.** Write only under `BubbleTrouble/Core/` and (Task 12 only) `docs/bubble-trouble/`. Never
   touch `Aki/`, `docs/<other-game>/`, HectorShell, HectorKit (another lane is concurrently writing HectorKit
   decoders — `docs/plans/2026-10-03-hectorkit-btx-decoders.md`), or the EV repo. The core must not import
   HectorGraphics/HectorAudio or depend on any cicn/ppat/snd decoder.
2. **Never `git add -A` / `git add .`**; add the paths each commit lists. Never `git stash`. Commit on the
   executing worktree's branch; the orchestrator merges to `main` and pushes (repo CLAUDE.md workflow). Every
   commit ends with the trailer the orchestrator fixes for the executing model. **Parallel lanes never share a
   worktree** (orchestrator ruling): each lane has its own git worktree, `.build` and scratchpad log path
   (§Execution order).
3. **No game data in git.** Tests read `HECTORKIT_DATA_BTX` (the `…/Contents/Resources` directory) and throw
   `XCTSkip` naming the variable when it is unset or not a directory (Aki/Core convention, HectorKit D3).
4. **A skip is a failure** for G1. STOP on any unexpected number (test totals, draw counts, census values).
5. ⚠️ **LANDMINE — the sample pointer.** A FILM sample is consumed **only** inside `_CheckHeroMovement`, which
   `_ProcessHero` reaches only in hero state 2, not push/pop-frozen (`+0x40`), not balloon-trapped (`+0x4c`),
   and not on the trap-release frame (`_ProcessHero`: `if (frame <= +0x4e + 0x5a) return; +0x4c = 0; return;`).
   States 1/3/4 return before it. Sample index ≠ frame index. (`hero-and-input.md` §2/§6, `replay-oracle.md` §2.)
6. ⚠️ **LANDMINE — star pre-draw clip.** `_NewStar @ 0000329a` frees the slot and returns **before** the type-0xb
   `GetRandomFast(0,1)` when the new rect leaves x 0..640 / y 0..440:
   `if ((left < 0) || (0x280 < right) || (top < 0) || (0x1b8 < bottom)) { star[0] = 0; return; }` precedes
   `if (param_5 == 0xb) {… _GetRandomFast(0,1) …}`. The 60-cap and free-slot checks come first; a clipped star
   does not count as active. (`replay-oracle.md` §4.2.)
7. ⚠️ **LANDMINE — blast double count.** `_CheckForBombKills @ 000116eb` increments its count for every enemy in
   states 1/3/4/5/6 whose rect overlaps — **without testing the dead flag `+0x47`**; `_SquishEnemy` ignores the
   dead one but the count advances (`local_1e = local_1e + 1; _SquishEnemy(iVar3, param_2 + local_1e);`).
   Reproduce it. (`bubbles-items-scoring.md` §4.)
   **Same class — `_WasEnemySquished @ 00010eca`** returns the first enemy in states 1/4/5/6/3 whose rect overlaps,
   **without testing `+0x47`** (decompile: the loop tests only `*pcVar4` state and `_RectsCollide`). A squished
   enemy keeps its state until the draw pass frees it, so a moving block that overlaps it again is handed the same
   slot: `_MoveBlock` still does `n = ++block.count` before `_SquishEnemy` ignores the dead enemy — the chain count
   advances and the next real squish in that chain scores at the higher n. Reproduce it.
8. ⚠️ **LANDMINE — iteration order and slot allocation.** Every pool scans slots from 0 and allocates the
   **first free** slot; enemies are processed 0..29, blocks 0..34, balloons 0..29, stars 0..59, air bubbles
   0..7, points 0..7, splats 0..11, bonus 0..1. Slots are freed **only in the draw pass** (end of frame), never
   in the logic that killed them. Iteration order is part of the RNG order. (`replay-oracle.md` §4.6.)
9. ⚠️ **LANDMINE — u16 frame counter.** `gFrameCounter` is `UInt16`, incremented with wrapping (`&+= 1`),
   zeroed by `_NewLevel`. Timer comparisons promote to `Int` *without* wrapping (`(uint)start + delay <
   (uint)frame`): compute `Int(start) + delay < Int(frame)`. Never compare in `UInt16` arithmetic.
10. ⚠️ **LANDMINE — the RNG step is swappable and suspect #1.** `QuickDrawRandom.step` is the single place the LCG
   lives; `GameRandom` takes the step as a `@Sendable` function value. Nothing else may call a different
   generator. On any FILM divergence, the LCG (step, 0x8000 adjustment, seed install) is checked first
   (Diagnosis protocol).
11. **Assumptions, recorded, not decided by the executor:** registration = registered + valid licence;
   prefs stars (bool 0x35) and air bubbles (bool 0x36) = ON; session latches u = 1, L = 15; `gPointsNotReg` =
   false (NR-4). All four live in `SessionConfig` with these defaults; changing a default is Ben's call. Evidence
   for the prefs default: the folded `_DoFXSuitabilityCheck @ 0000f760` is `SetBooleanPref(0x35, 1);
   SetBooleanPref(0x36, 1)` (`otool -tV` 0000f766–0000f789), tail-jumped from `_AlexPrefsGameInit @ 0000fa24`
   (0000fa8e `jmp _DoFXSuitabilityCheck`) — ON is the shipped default; whether the prefs are *exposed* stays Ben's.
12. ⚠️ **LANDMINE — HectorResources' `ByteReader` is internal** (`ByteReader.swift:9 struct ByteReader`, no
   `public`). The core decodes big-endian fields itself (`Data/BigEndian.swift`). Do not "make it public" —
   HectorKit is out of scope.
13. ⚠️ **LANDMINE — `Resource`/`ResourceCollection` are not `Sendable`.** Convert to the core's own `Sendable`
   value types (`Maze`, `LevelRecord`, `Film`) at load time; never store a `ResourceCollection` in game state.
14. **End-reason semantics** (derived from `_PlayGame`): a demo stops at the top of the next loop iteration
   after any of: hero state-4 timeout, level complete + 70, `FILM.count <= gRecordingCounter`. All are tested at
   their places in the frame; record **every** reason that fired on the final frame. A catch on the final frame
   is legitimate only when it happened after that frame's `_ProcessHero` (blocks/blast) — report it, do not fail
   on it; a catch on any earlier frame is a FAIL. **Level completed in the last 70 frames (orchestrator ruling):**
   if `gIsEndOfLevel` was set at frame E and the count runs out at frame F ≤ E + 71 (so the +70 stop had not fired,
   or fired on F itself), the demo is a **pass that is FLAGGED**: the harness prints `end = count,level`, marks the
   row `FLAG`, and the orchestrator's gate message to Ben names the FILM and E/F. A `.levelCompleted` stop on any
   frame before F is a FAIL.
15. ⚠️ **LANDMINE — HectorKit is a live local path.** `../../../HectorKit` resolves to `~/Developer/HectorKit`
   through the worktree symlink; a concurrent lane may leave WIP there. If a build fails inside HectorKit
   sources, STOP and report; never edit HectorKit.
16. ⚠️ **LANDMINE — `swift run` mixes build progress into stdout.** Capture tool output by building first and
   running `"$(swift build --show-bin-path)/btx-replay"`.
17. ⚠️ **LANDMINE — SwiftPM rejects a declared target with no sources.** Task 0 creates one source file in each
   of the three targets.
18. **Original quirks are replicated, never fixed** (repo CLAUDE.md standing ruling): signed homing compares,
   `_ToastBubble` never testing right, the balloon box growing once, blue/purple bounce sound asymmetry, the
   double count, `_LoadLevel` clamps. Undefined behaviour is replicated only where Research notes say how
   (NR-6: no-op; NR-7: the original quits — the replica stops with `StopReason.originalWouldAbort`).

---

## Research notes the executor must know

Each verified 2026-10-03 against the decompile/disasm or the extracted data (commands in brackets). Bank
citations are `file §`. "Decompile:" quotes are verbatim from `$D`.

### RNG

1. **`_GetRandomFast(lo, hi) @ 0000c4cc`** — decompile: `uVar1 = _Random(); uVar1 = ((hi - lo) + 1) * (uVar1 &
   0xffff); if (0x7fffffff < uVar1) uVar1 = uVar1 + 0xffff; return lo + ((int)uVar1 >> 0x10) & 0xffff;`
   Disasm `imull / leal 0xffff(%ebx) / cmpl $-0x1 / cmovlel / sarl $0x10 / movzwl`. With r taken as the
   unsigned low word, the result is in `[lo, hi]`. Every range in the game keeps the product < 2^31 (largest n
   is `(1, r)` with r ≤ 751), so the `+0xffff` branch never fires in play — keep it anyway. Examples
   [Python]: `(0,6)` r=0xffff → 6; r=0 → 0; `(40,480)` r=0xffff → 480; `(1,750)` r=0x8000 → 376.
2. **QuickDraw `Random()`** — `_Random` is an undefined import (`nm -u`); the only `calll _Random` is 0000c4d9.
   Algorithm (Apple, Inside Macintosh, cited at **[LOW]**, NR-3): `randSeed = randSeed × 16807 mod (2^31 − 1)`;
   result = low 16 bits of the new seed as `Int16`, with −32768 (0x8000) returned as 0.
   Reference values [Python, this plan's computation]: seed 1 → seed 16807, value 16807; next seed 282475249,
   value 15089 (0x3af1). Seed 32768 → seed 550731776 (0x20d38000), low word 0x8000 → value **0**.
   FILM 1 seed 0x004642a0 → values 5764, 13963, 4202, −22575, −23569; seeds 0x04c01684, 0x5f06368b, 0x10e7106a,
   0x31e6a7d1, 0x1e13a3ef (seed after 5 draws 504603631).
3. **Seeding** (`engine-loop.md` §3; `_PlayGame` decompile): demo mode calls `SetQDGlobalsRandomSeed(FILM.seed)`
   once, before `SetLevel/ResetHeroLives/ResetScore/Multiplier_Reset/EXTRA_Reset/_NewLevel`. The seed is the u32
   at FILM+4. Levels inherit the running state; no reseed per level.
4. **Session latches** — `_Get0To6 @ 0000ccc9` / `_Get13To22 @ 0000ccfb`: `if (_val == 99) _val =
   GetRandomFast(0,6)` (resp. `(0xd,0x16)`); static 99 at 0x3408c/0x34090 (`__data` bytes `63000000 63000000`
   [rdata dump]). First called from `_Interface` before any game, so in-game they never draw. From process seed
   1: u = **1**, L = **15** [Python; NR-3 LOW]. `_gLevelForEffect` starts at **50** (`__data` 0x34254 = `32000000`)
   and `_ProcessHero` replaces it: `if (_gLevelForEffect == 0x32) _gLevelForEffect = _Get13To22();` on its first
   state-2 call.
5. **All 61 `_GetRandomFast` call sites** (`engine-loop.md` §3 table, 27 functions; REVIEW "Verified OK") —
   homes in Self-audit item 1.
6. **Registration is RNG-neutral for levels 1–4** [derived]: the unregistered-only dummy `(0,7)` needs
   `level ≥ u + 9 ≥ 9` (`_FigureEnemyMove`: `if ((uVar8 + 9 <= level) && (*gAIRegistered == 0)) _GetRandomFast(0,7);`);
   the sprite-swap `(0,1)` draws happen at `level ≥ L ≥ 13` for registered and unregistered alike; the
   `_DrawPointsToComp` trap needs `level ≥ threshold (20..24)`; the `(1,30)`, `(0,30)`, `(0,40)`, `(0,20)` draws are
   cracked/blacklisted-licence paths only. Model registered-valid: `gAIRegistered = 1`, hero `+0x3a = 1`,
   hero `+0x24 = 1`, enemy `+0x22 = 1`, `gPointsNotReg = false`.

### Data (`data-formats.md` §1–3)

7. **Files.** `BT Levels.rsrc` is a **data-fork** resource file (1,345,319 B): `ResourceReader.read(fileAt:)`
   (`ContainerBackend.swift:23`) falls back to the data fork (`forkBytes`, line 87). Census [rsrc_census.py]:
   LEVL 50 × 64 B (ids 1..50), MAZE 50 × 176 B (1..50), FILM 4 × 10012 B (1..4), PICT 6, ppat 7, vers 2.
   API used: `ResourceCollection.resources(of:)`, `.resource(type:id:)`, `.counts()` (`Resource.swift:33-35`),
   `Resource { type: String, id: Int16, name: String?, data: Data }`.
8. **MAZE** = 176 bytes, `cells[col + 16·row]`, col 0..15, row 0..10, row 0 = top (`_LoadMaze @ 0002626e`
   memmoves 0xb0 into `gMaze` **and** `gMazeCopy` after zeroing both). Codes: 0 empty, 10 normal, 15 blue,
   16 purple, 20 jewel (runtime), 30 cluster (runtime), 40 popping (runtime), 50 wall (returned off-grid by
   `_GetNextObject`/`_GetDistantObject`, never stored), 52 dynamite, 60 egg (runtime); 70 'F' / 80 'P' are
   passable balloon tags, never in the maze. Shipped census over all 50 [Python]:
   `[(0,4747),(10,3692),(15,169),(16,115),(52,77)]`; byte 0x67 (cell (7,6)) is 0 in all 50.
9. **LEVL** = 32 big-endian i16 words (flipper swaps all; `_LoadLevel @ 00002ef7` copies into `level`):

   | w | meaning | consumer (task) |
   |---|---|---|
   | 0 | MAZE id (= level id in all 50) | `_NewLevel` → `_LoadMaze` (T4) |
   | 1 | background **PICT** id: 912 (9 levels; PICT 912 lives in `Bubble Trouble X.rsrc`, 457,926 B) or 13000–13005 (`BT Levels.rsrc`). The same ids also exist as `ppat` in `BT Levels.rsrc`, but `_DrawMaze` → `_DrawAndCentrePict @ 0000bd14` calls `GetPicture` (type PICT only) — data-formats.md §7 | shell (exposed) |
   | 2 | music set 1..4 | shell (exposed) |
   | 3, 4 | "hurt block" redraw frame (bubble / jewel) — draw only | shell (exposed) |
   | 5, 9, 11, 13, 14, 24–31 | unused by the game | stored raw only |
   | 6 | total enemies, **clamped**: `sVar8 = 0x1e; if (w6 < 0x1f) sVar8 = w6;` | spawn gate (T9a), end check (T10) |
   | 7 | max active | spawn gate (T9a) |
   | 8 | egg time (50 everywhere) | egg block (T8), hatch (T9a) |
   | 10 | pre-egg delay (10 everywhere) | enemy state 2→3 (T9a) |
   | 12 | jewels, **clamped** 3..4 (`if (2 < w12) …; if (4 < s) 4`) | `_PositionJewels` (T4) |
   | 15 / 16 | balloon flash / release frames | `_Balloons_Process` (T7a) |
   | 17 | 300 everywhere; only the array base of `level+0x22+type*2` | pool indexing only (NR-8) |
   | 18..23 | enemy pool per type 1..6 (mutated at run time) | `_NewEnemy` (T9a), disappear/starfish (T5b/T8) |

   `_LoadLevel` also: level ≥ 51 → `GetRandomFast(0x15,0x32)` (never for 1..50); Σw18..23 must equal the clamped
   w6. Level-1 words [Python]: `1, 912, 1, 1, 1, 1, 4, 2, 50, 2, 10, 20, 3, 10, 20, 140, 170, 300, 4, 0 …0`.
   w15/w16 steps [Python]: 140/170 (L1), 130/160 (L2), 120/150 (L3), 110/140 (L4–12), 100/130 (L13–15), 90/120
   (L16–50). Jewels 3 (L1–12), 4 (L13–50). First eel L3, shark L6, starfish L12.
10. **FILM** = 10012 B: u32 BE count, u32 BE seed, u32 BE level-field (unused, NR-1), then five 2000-byte arrays
   up @12, down @2012, left @4012, right @6012, push @8012; nonzero = held. Census [Python]:
   FILM 1 count 1118 seed 0x4642a0 field 0x00020000; FILM 2 846 / 0x45f1f8 / 0x00020000; FILM 3 943 / 0x461498 /
   0x00030000; FILM 4 890 / 0x4621ef / 0x00040000. All array bytes ∈ {0,1}. FILM 1: leftovers past 1118 (up,
   down, left, right, push) = 89/100/90/92/1; held within count = 86/67/59/98/19; first runs `..... ×16, ...R. ×25,
   ..... ×5, U.... ×37, ..... ×8, ..L.. ×7`; first push at sample 212. Samples with >1 direction held:
   FILM 1–4 = 0 / 11 / 11 / 18 (so the priority rule matters for FILMs 2–4). FILM n plays level n.

### Level construction (`replay-oracle.md` §3, `_PlayGame` + `_NewLevel @ 0001735f`)

11. **Demo prologue order:** load FILM → `gRecordingCounter = 0` → seed → `SetLevel(id−1)` → `ResetHeroLives`
   (lives 3, hero `+0x24 = 1`) → `ResetScore(0)` (`gNextExtraLifeScore = 10000`) → `Multiplier_Reset` (1) →
   `EXTRA_Reset` → `_NewLevel`. Loop-local `first = true` (70-frame first appearance).
12. **`_NewLevel` order and draw counts:** `gIsEndOfLevel = 0; gFrameCounter = 0; NextLevel (level = id);
   LoadLevel (0 draws); ResetBlocks (all 35 free, gJewelsDone = 0, gJewelAnimDir = 1, **gNumNormalBlocks =
   100**); ResetHurtBlockList; TimeBonus_Reset; LoadMaze(w0); InitHero; PositionJewels (2 draws per jewel:
   (1,14),(1,9)); Splats_Init; Bubbles_Init (109 draws); Balloons_Init; InitStars (42 draws); InitPoints
   (8 draws); InitEnemies; InitEnemyAI (no-op); Bonus_Init (3 + per armed slot 2 [+1 if type 5..8] [+1 if
   type 3/14] + 21 draws); DrawMaze (sets `gAIRegistered = licence != 0`, no RNG)`.
   `_TimeBonus_Reset @ 00006930`: level < 5 → 2500; < 10 → 3000; < 15 → 3500; else 4000; timer = frame.
13. **`_InitHero @ 000217b3` / `_ResetHeroPosition @ 0002165f`:** state 1, stateStart = frame (0), speed 5,
   invisibility off, trap off, push flag 0, last-bubble frame (`+0x0c`) = frame; position: (7,6) if
   `gMaze[0x67] == 0`, else first empty cell scanning rows 5..7 × cols 6..8 row-major, else first non-jewel
   (0x14/0x1e) cell of the same scan, else the original quits ("can't find good starting loc"). Then aligned,
   offsets 0, rect = cell, facing 3, sprite set 1, frame 3, `+0x4b = +0x4c = 0`.
14. **`_PositionSingleJewel @ 0001c544`:** `c = GetRandomFast(1,14); r = GetRandomFast(1,9); tries = 0;` loop:
   `tries++`; if cell == 10: reject if (c,r) == (7,6); reject if any 0x14 in row r and `tries < 151`; reject if
   any 0x14 in column c and `tries < 151`; else write 0x14 and record. Advance: while `tries < 501`: `c++`, if
   `c > 14` → `r++`, `c = 1`, and `r ≥ 10` → `r = 1`; after that: `c++`, if `c > 15` → `r++`, `c = 0`, `r ≥ 11` →
   `r = 0`. Only jewels (0x14) block, not clusters.
15. **`_Bubbles_CreateRandomLUT @ 000161f6`** (sizes from nm): 33 × `(0x28,0x1e0)` x-table (0x34e80–0x34ec2),
   21 × `(0,4)` drift (bytes), 21 × `(2,5)` vertical (bytes), 13 × `(0x19,0x5a)` delay (shorts), 21 × `(0,0xe)`
   mapped to groups `0,1→0; 2,3→1; 4,5→2; 6→3; 7,8→4; 9,10→5; 11→6; 12,13→7; 14→8`. All indices 0.
   `_Bubbles_Init` then: `NumActive = 0; TimeLastGroupLaunched = 0; DelayTilNextGroup = 0x1e`.
16. **`_CreateStarRandomLocLookupTable @ 0000323e`:** 21 × { `v = GetRandomFast(0,8); if (GetRandomFast(0,1) != 0)
   v = −v` }; index 0. **`_InitPoints @ 0000241b`:** 8 × `threshold = GetRandomFast(2,6) + 0x12` (20..24).
17. **`_Bonus_Init @ 00019734`:** `slot0.armed = 1; slot1.armed = GetRandomFast(0,100) < 0x32;` then **always**
   `slot0.launch = GetRandomFast(0xdc,600); slot1.launch = GetRandomFast(0x1c2,0x3b6)`; per armed slot in order:
   `left = GetRandomFast(0x46,0x212)`, rect (440, left, 480, left+40), rise speed `+0x18 = 2`; `type =
   GetRandomFast(1,14)`; `3 → 14`; `5..8 → GetRandomFast(9,13)`; if 14: index `GetRandomFast(lo,hi)` with
   (lo,hi) = (0,1) L<3, (0,2) L<6, (1,3) L<11, else (2,6) into values 500, 800, 1000, 2000, 3000, 4000, 5000;
   then 21 × `(0,4)` drift shorts (0x37700–0x3772a). `gBonus_NumEnemiesSquishedAtOnce` = 0 at level 1.
18. **Planner-computed level-build expectations** [Python over the extracted resources, QuickDraw LCG assumed —
   self-derived, not bank-derived]:

   | FILM | jewels (col,row) | draws after jewels / LUT / stars / points / Bonus_Init | bonus slot 0 | bonus slot 1 |
   |---|---|---|---|---|
   | 1 | (2,2) (1,6) (9,7) | 6 / 115 / 157 / 165 / **191** | launch 578, left 492, type 11 | unarmed |
   | 2 | (14,2) (10,4) (6,5) | 6 / 115 / 157 / 165 / **194** | 434, 430, type 10 | 577, 343, type 10 |
   | 3 | (6,1) (8,6) (10,8) | 6 / 115 / 157 / 165 / **194** | 256, 303, type 13 | 716, 492, type 14 (1000) |
   | 4 | (1,4) (5,9) (8,5) | 6 / 115 / 157 / 165 / **193** | 481, 237, type 9 | 612, 263, type 9 |

   FILM 1 tables: x-table starts `159, 228, 277, 133, 262`; delay table `85, 69, 53, 53, 56, 54, 78, 51, 49, 90,
   51, 49, 74`; groups `2,0,0,3,5,4,0,4,7,5,5,4,6,3,7,0,0,2,6,1,0`; vertical starts `5,4,2,3,4`; drift starts
   `2,0,3,2,3`; star lookup starts `−6, 4, 8, 8, 4, −3`; point thresholds `23,24,21,22,20,24,23,23`; bonus drift
   starts `3,4,2,2,2`; seed after `_Bonus_Init` **446091883**. Normal bubbles after jewels: 80/70/78/57.

### Frame step (`engine-loop.md` §4, `_PlayGame` loop, decompile)

19. **Order:** `gTimerFired = 0; frame &+= 1;` → hero state machine → (pause: ignored in demo) → **if
   `gNumNormalBlocks > 0`: recount** (`_NormalBlockCount` = number of 10s); if it became 0 → `AddToScore(2000,
   ×mult)`, `NewStarGroup(hero.col·40, hero.row·40, 2)`, `NewPoint(hero.left, hero.top, 12, 12)`, `FinishLevel`
   (squished = total) → `_Bubbles` → `_ProcessEnemies` → `_ProcessHero` → `_Splats_Process` →
   `_Bubbles_Process` → `_Balloons_Process` → `_Bonus_Process` → `_ProcessBlocks` → `_ProcessStars` →
   `_ProcessPoints` → `_TimeBonus_Process` → draw pass (frees, in this order: `_DrawEnemiesToComp` dead enemies
   (`+0x47`) + `gNumEnemiesActive--`; `_Balloons_DrawToComp` dead balloons (`+0x21`); `_DrawBlocksToComp` retired
   blocks (`+0x28`); `_Splats_DrawToComp`; `_Bonus_Draw` dead bonus (`+1`); `_DrawStarsToComp` dead stars
   (`+0x26`); `_DrawPointsToComp` (trap draw `(0,0x14)` per live point if `+0x16`, then free if `+0x17`);
   `_Bubbles_DrawToComp` dead bubbles (`+0x21`)) → end-of-level check → demo count check.
   **Draw-pass side effects that are not frees** (model them; none touches the RNG — `_DrawPointsToComp`'s trap is
   the only draw-pass RNG site): `_DrawHurtBlocksToComp @ 0001b8b1` (first in the pass) clears every hurt-block
   entry it draws; `_DrawHeroToComp` and the enemy/balloon/block/star/bubble draws copy `rect` → `prevRect` for live
   slots; `_Balloons_DrawToComp @ 00024280` clears a live balloon's `visible` (`+0x20`) when its rect leaves
   0..640 × 0..440 (it is not restored). The core keeps these so the shell plan can draw from the same state.
20. **Hero state machine (top of frame):** state 2: `if (stateStart + 10 < frame) _CheckNewEnemies()`.
   State 1: delay = lives < 1 ? 95 : (first ? 70 : 60) (`(-(ushort)!bVar1 & 0xfff6) + 0x46`); when
   `stateStart + delay < frame`: lives < 1 → stop (play mode); else maze[hero cell] = 0, state 2, stateStart =
   frame, visible, invisibility off, speed 5, `NewStarGroup(col·40,row·40,0)` (motion 0, no RNG),
   `_Blocks_DeactivateRubberBlocks` (every active 15/16 block retired and written into the maze at its col/row);
   `first = false`. State 3: when `stateStart + 0x1e < frame` → state 4, stateStart = frame, `SubtractLife`,
   `+0x3e = 1, +0x42 = 0, +0x48 = 0`, `_MakeAllEnemiesDisappear`. State 4: when `stateStart + 0x41 < frame` →
   demo: stop; play: state 1, respawn (`_ResetHeroPosition`), `Multiplier_Reset`.
   ⇒ First appearance: state 2 on **frame 71**; first `_CheckNewEnemies` on **frame 82**.
21. **End checks (after the draw pass):** if `!gIsEndOfLevel` and hero state ∈ {1,2} and
   `total <= squished` → `gIsEndOfLevel = 1; gEndOfLevelTime = frame`. Then if state ∈ {1,2}, lives > 0,
   `gIsEndOfLevel` and `gEndOfLevelTime + 0x46 < frame` → demo: stop (play: level transition, deferred).
   Then demo: `if (gRecording.count <= gRecordingCounter) stop`. Stops take effect at the next loop top.
   ⇒ level complete at frame E stops at frame **E + 71**; a catch at frame C stops at frame **C + 97**.
22. **Planner-computed FILM 1 checkpoints** [Python; QuickDraw LCG assumed; self-derived]: total draws at the
   end of frame 30 = **191**; frame 31 = **192** (first air-bubble group: group 2 = one bubble, `(5,9)`);
   frames 32–81 stay 192; frame 82 = **198** (egg: `(0,15),(0,10)`, scan, `(1,4)`, 3 × `(0,5)`); frame 83 = **208**
   (egg: 7 × `(0,5)`); stays 208 through frame 116; frame 117 = **209** (next group launches when `frame >
   31 + 85`; groups[1] = 0 → one bubble). Eggs: slot 0 laid frame 82 in (0,6), dir 2, piranha; slot 1 laid frame
   83 in (11,6), dir 1, piranha. Samples consumed at the end of frame f, 71 ≤ f < first push = **f − 70**.
   Time bonus 2500 through frame 100, 2450 at frame 101 (timer = 70 from the last state-1 frame).
   Egg 0 timeline: enemy state 3 at 93, hatches at 154, first `_EnemyAI` at 171; egg block state 4 at 132,
   popping (cell 40) at 148, cell empty at 156.

### Hero (`hero-and-input.md`)

23. **`_ProcessHero @ 00022de0` exact flow** (decompile): states 3 and 1 return; state 4 = death animation
   (sprite 7; `+0x42++`; when `> 1`: `+0x42 = 0; +0x3e++`; when `+0x3e > 16`: if visible and `!+0x4b` →
   `_Bubbles_NewGroup(hero.left, hero.top, 0xb)` and `+0x4b = 1`; `+0x3e = 16; +0x48++`) — the death bubbles
   fire on the **32nd** state-4 call. State 2: latch `gLevelForEffect`; invisibility (`+0x52 + 300 < frame` →
   off; else `+0x52 + 0xd2 < frame` → blink toggle every 3 calls); trap (Invariant 5); push freeze (`+0x42++`;
   `<= +0x46` → return; else clear, restore walking sprite for facing — **draws `(0,1)` if `gLevelForEffect <=
   level`** — frame 1, return); `_CheckHeroMovement()`; not aligned → `_MoveHeroNotAligned`; aligned + push held
   → `_HeroPushCrushCheck`: 1 → sprite 6, frame = facing, `+0x40 = 1`, `+0x42 = 0`, `+0x46 = 2`, return; 2 →
   same with `+0x46 = 5`, return (registered-valid path); otherwise (result 0, or push not held) if any direction
   held → `_MoveHeroAligned`. ⇒ push: the push call + 3 frozen calls; pop: + 6 frozen calls. **Draw order (exact):**
   on an aligned frame the push check runs **before** `_MoveHeroAligned` and its turn `(0,1)` draw; only a 0 result
   falls through to `_MoveHeroAligned`, so a successful push/pop frame makes no turn draw. Death bubbles need
   `+0x4a` (visible) set — not the invisibility flag `+0x50`.
24. **`_CheckHeroMovement @ 00021f49`:** demo: the five flags = `FILM.x[gRecordingCounter] != 0`, then
   `gRecordingCounter++`; sets Up/Down/Left/Right/Push/MoveKeyDown.
25. **Movement:** speed 5 px/frame (8 frames per cell). `_MoveHeroAligned @ 00022847`: priority Up > Down >
   Left > Right; sets facing, sprite set (2/3/4/5), frame 1, the `(0,1)` draw when `gLevelForEffect <= level`
   (result used only if `+0x3a == 0`); moves only if the next cell ∈ {0, 'P'}. Offsets accumulate; at ±40 col/row
   steps and the offset resets. `_MoveHeroNotAligned @ 000224c8`: keeps direction; only the exact opposite key
   reverses (walk frame −1 on a reversal frame, else +1, wrapping 1..8); same conditional `(0,1)` draw on a
   direction (re)choice. Enemies are not in the maze — the hero can walk into them.
26. **Push table** (`hero-and-input.md` §4, `_HeroPushCrushCheck @ 000220d8`) — transcribe; it uses the
   **facing**, `N = _GetNextObject(face)`, `D = _GetDistantObject(face)`. `_PushBlock @ 0001bd62`:
   `_NewBlock(next cell, face, type, −1, moving=1)` and maze cell 0. `_CrushBlock @ 0001bc14`: pop block (type
   0x28) in the adjacent cell, maze 0x28 unless dynamite, `AddToScore(1, ×mult)` when the score flag is set
   (hero only). Dynamite: blocked → crush + `_ActivateBombBlock` (static fuse block, state 3; already lit >
   30 frames → explode now, else nothing); free to slide but already lit → return 0. Egg (60) →
   `_KillEggBlock @ 0001be3b`: egg block → pop (type 0x28, state 2, sprite 0x18), maze 0x28, `AddToScore(50)`,
   `NewPoint(block.left, block.top, 0x15, 0xc)`, `_KillEnemy(block.enemy, 0)`, star group 3 (piranha 0x1b) /
   4 (eel 0x1c, starfish 0x1e) / 5 (other) at the egg cell ×40.
27. **Catch:** `_IsHeroCaught(rect, protectInvisible, bigInset) @ 00021c79` only in hero state 2; rect inset 4
   (11 if big), hero rect inset 8 if big; `_RectsCollide @ 0000c398` strict on all four edges. Enemy body
   (1,1): same row, `|dx| ≤ 20` caught, 21 not. `_HeroCaught(kind) @ 00021dfa` sets **state 3 first**,
   stateStart = frame, `_StopAllEnemies` (states 1,2,3,4,6 → 5, stateStart = frame), Ouch; kind 1: one
   `(0,1)`; kind 2: one `(0,1)`, splat (kind 1 at hero left/top), **star group 0xe at hero col·40/row·40**,
   then `hero[0x4a] = 0` — the **visible** flag (`hero-and-input.md` §0 `+0x4a visible`), not the invisibility
   bonus `+0x50`. Consequence: a kind-2 death (block/blast) never emits the state-4 death bubbles (note 23 needs
   `+0x4a`), so it makes none of group 0xb's draws (5 `_Bubbles_New` anim-period draws on a non-full pool) that a
   kind-1 death of a visible hero makes.
28. **Lives/score:** 3 at start; `_AddHero` caps 9. `_AddToScore(v, mult) @ 000280dd`: `v ×= multiplier` when
   flagged; if `score >= next`: one life, `next = next < 40000 ? 40000 : next + 40000` (one life per call).

### Enemies (`enemies-ai.md`)

29. **`_CheckNewEnemies @ 000124fa` + folded `_NewEnemy`** (decompile + disasm): gates in order — hero state 2;
   `gNumNormalBlocks < 1` (→ if no enemy active, squished = total); `TimeBonus < 1` → squished = total −
   active; `total <= squished + active` → return; `max <= active` → return; first free slot of 30 or return.
   Then `c = GetRandomFast(0,15); r = GetRandomFast(0,10)`; `do { c++; if (c >= 16) { r++; if (r >= 11) r = 0;
   c = 0 } } while (maze[c + 16r] != 10)`; enemy rect = cell, tier 4, state 2, stateStart = frame,
   `dir = GetRandomFast(1,4)`, aligned, `+0x5a = frame`; if pool words 18..23 all zero → word 18 = 1;
   `do i = GetRandomFast(0,5) while pool[i] == 0`; `pool[i]--`; type i+1, sprite set 0x1b/0x1c/0x1d/0x1e; anim
   frame by dir 1→1, 2→4, 3→7, 4→10 (starfish 1); balloon index −1; maze cell = 0x3c; `gNumNormalBlocks--`;
   `_NewBlock(c, r, 0, 0x3c, slot, 0)` (egg block: state 3, sprite 0x1f, frame = type, `+0x2a = 15`);
   `gNumEnemiesActive++`.
30. **`_ProcessEnemies @ 00011ad3`, per slot 0..29:** state 1: if post-hatch flag `+0x4b` → `+0x44++`, clear
   when `> 15`; else `_EnemyAI(i)`; then animation (piranha/shark 3-frame cycles every 3 ticks, eel 5-frame
   every 4, starfish 7-frame every 4 — transcribe). State 2: `start + w10 < frame` → state 3, start = frame.
   State 3: `start + 10 + w8 < frame` → hatch: state 1, start = frame, drawn, `+0x4b = 1`, `+0x44 = 0`.
   Then for every non-free slot: `_CorrectEnemyAligned`; if **not** aligned: cell = dir 1/3 → `gMaze[col,row]`,
   dir 2 → `_GetNextObject(2,…)`, dir 4 → `_GetNextObject(4,…)`; if ∈ {10,15,16,20,30} → `_SquishEnemy(i,1)`.
   Finally **state 1 only**: hero state 2 and `_IsHeroCaught(rect,1,1)` → `_HeroCaught(1)` — the dead flag is
   not tested, so an enemy squished on entry this very call can still catch the hero. **Order within one slot
   (exact):** squish-on-entry runs **before** the catch test; the squish's star-group draws therefore precede the
   catch's single `(0,1)` draw (kind 1 has no star group).
31. **`_EnemyAI @ 00014296`:** aligned = left%40 == 0 && top%40 == 0; aligned → `_FigureEnemyMove`; paused
   (`+0x4a`) → return; `_MoveEnemy` (speeds `enemies-ai.md` §4a, recomputed only when aligned; move by speed,
   `col = left/40, row = top/40`). Shark counter c = ++`+0x4e` per aligned frame: c ≤ 1 keep (initial 2);
   2–3 → 4; 4–5 → 2 (8 if bonus ≤ 0); 6–7 → 4; 8–9 → 2/8; 10 → 4; 11 → 8; 12 → 4; ≥ 13 → 2, c = 0.
32. **`_FigureEnemyMove @ 00013bd4`:** pending action (`+0x58`: 2 pop, 1 push, 3 balloon — success → pause,
   return; 4 wait: `+0x52 < 10` → `+0x52++`, pause, return; else clear); `old = dir; dir = 0`; if old ≠ 0:
   next cell bursting (`_EnemyCheckBurstingBubble`) and paused → `dir = old`, return; not bursting, paused and
   `_TryAndTurnEnemy(old)` → unpause, return; clear pause; `r = _FigureEnemyRandomness(i)` (base / (frame −
   stateStart) + 1, min 1; base starfish `750 − 15·level`, eel 120, shark 180, piranha 600);
   `roll = GetRandomFast(1, r)`; `roll ≠ 1 && TimeBonus > 0` → `dir = old`, tail-jump `_MoveEnemyRandomly`
   (`enemies-ai.md` §4c, folded @ 0001396f, disasm): it **repeats the pending-action dispatch** of the step above
   (success → pause, return), then `old = dir; dir = 0`, then 16 draws: 8 × {`a = (0,3)`, `b = (0,3)`,
   `swap(order[b], order[a])`} on `[3,4,1,2]`; tries each `d ≠ opposite(old)` in order with `_TryAndTurnEnemy`;
   reverse as last resort (old ≠ 0); then the **stuck fallback**: `stuck (+0x48) > 0` → `_ToastBubble(i)`,
   stuck = 0, return; else stuck++, `dir = 3`, pause. Else homing with **signed** dx = e.col − hero.col, dy = e.row −
   hero.row and the (p, s) table of `enemies-ai.md` §4d (verified against the decompile 2026-10-03; tie cases
   draw one `GetRandomFast(1,2)`), then the try-sequence of §4d. Old dir 0 in homing → `_LocationErrorInt(0x7d8,
   1)` → **the original quits** (Bank correction C11) → replica stops with `.originalWouldAbort`.
33. **Actions** (`enemies-ai.md` §4e): pop wait starfish 10 else `max(5, 40 − level)`; push wait starfish 10
   else `max(5, 70 − 2·level)`; balloon wait `max(5, 70 − 3·level)` (shark only). **Enemy push
   (`_TryEnemyPushBlock @ 000131fd`, decompile):** edge limits first (`d` 2 down: row ≤ 8; 1 up: row ≥ 2; 3 left:
   col ≥ 2; 4 right: col ≤ 13, else return 0); then the adjacent cell must be a **normal bubble (10)** and the cell
   beyond **empty (0) or 'F' (70)** — blue/purple/jewel/dynamite never, 'P' beyond never; waiting frames set
   `+0x58 = 1`, `+0x52++`, `dir = d`, pause; on the frame the count reaches the wait: count/pending cleared,
   `_PushBlock(col, row, d, 10)`, `dir = d`, pause, `+0x5a = frame`. `_CanDoNormalPop`:
   `lastPop + 0x78 < frame && (short)(10 − frame) < (short)((frame − stateStart)/0x1e)`; `_ToastBubble` tests
   up, down, left — never right. Jewels and dynamite are never popped/pushed by enemies (mask 0x18400).
34. **Mutations:** `_SquishEnemy(i, n) @ 0001131b` (ignored if dead or free): n=1 → 200, 2 → 400, 3 → 800 +
   step(3), 4 → 1600 + step(4), else 3200 + step(n) — all ×mult; `NewPoint(rect.left, rect.top, sprite
   2/4/8/0xb/0x18, 0xc)`; dead, drawn = 0, `squished++`, maze cell cleared, splat kind 0 at rect, star group by
   (state 6: type 1→3, 3→5, else 4; otherwise sprite 0x1b→3, 0x1c/0x1e→4, else 5) at **col·40/row·40**.
   `_PopEnemy` +100 ×mult, dead, squished++. `_KillEnemy` dead, squished++. `_CaptureEnemy` state 6, sprite
   0x20, frame = type. `_ReleaseEnemyFromBalloon` unless state 5 → state 1, stateStart = frame.
   `_MakeAllEnemiesDisappear`: `_Balloons_PopAll`; every non-free enemy dead, `level.pool[type]++`, not
   counted. `_WasEnemySquished(rect) @ 00010eca`: first enemy in states 1/4/5/6/3 overlapping — **dead flag not
   tested** (Invariant 7) → if state 6 pop its balloon → return index, else −1.

### Blocks, dynamite, jewels (`bubbles-items-scoring.md` §1–4)

35. **`_NewBlock @ 0001b94b`:** first free of 35, "none free" → original error (replica: precondition).
   Types: 10/15/16 moving (state 1, sprite 0x11/0x14/0x15); 20 jewel moving (sprite 0x16); 30 cluster static
   (sprite 0x17, frame 1); 40 pop (state 2, sprite 0x18); 52 dynamite (moving → state 1; fuse → state 3,
   frame 2; sprite 0x12 below level 12, 0x13 from 12); 60 egg (state 3, sprite 0x1f, frame = enemy type,
   `+0x2a = 15`). start = frame; `gNumActiveBlocks++`.
36. **`_MoveBlock @ 0001cccb`:** jewel/cluster with TimeBonus < 1 → becomes type 10. Unless bouncing: move 10 px;
   offsets ±40 step col/row. Aligned flag. Collisions on the rect inset 3: `_WasEnemySquished` → `n =
   ++block.count; _SquishEnemy(e, n)`; `_IsHeroCaught(blockRect, 1, 0)` → `_HeroCaught(2)`;
   `_Balloons_CheckSquishes` (flying balloons only — C5); `_Bonus_WasHit` (bonus rect inset 8). If aligned:
   jewel → `_CheckJewelMovement`; else next = `_GetNextObject(dir)`; empty/'P' and not bouncing → keep; otherwise
   non-rubber: retire, maze = type, dynamite → `_ExplodeBombBlock`; blue/purple: the 4-step squash (frames per
   direction up 2,3,2,1 · down 4,5,4,1 · left 6,7,6,1 · right 8,9,8,1), reverse, `bounces++`, retire when
   blue > 1 / purple > 2. Then the block–block pass (`bubbles-items-scoring.md` §1.5).
37. **`_ProcessBlocks @ 0001d2b8`** (decompile), per slot 0..34: move if `+0x1a`; type 0x28: frame++ and `> 8` →
   retire + maze 0; type 0x1e: cluster animation (`gJewelAnimDir`, `gJewelsDone` retires); type 0x34 static: maze
   = 0x34 every frame, `start + 0x3c < frame` → explode, else fuse anim; type 0x3c: state 3 while `frame < start
   + w8` (toggle egg/bubble sprite every 9 frames), else state 4, start = frame; state 4 and `start + 15 < frame`
   → type 0x28, state 2, frame 1, maze 0x28. Then block–block reversal pass.
38. **`_ExplodeBombBlock @ 0001c032`:** retire, maze 0; level < 12: rect = block rect grown 40 (`_InsetRect(−40)`),
   star group 0xf, one `_CheckForBombKills(rect, 0)`; level ≥ 12: star group 0x10; A = (top−80, left−40, bottom−40,
   right+40) base 0 → n_A; B = (top+80, left−40, bottom+80, right+40) base n_A → n_B; C = (top−40, left−80,
   bottom+40, right+80) base n_A+n_B. `_CheckForBombKills` then tests the hero once per rect (`_IsHeroCaught(rect,
   1, 1)` → `_HeroCaught(2)` — at most once in total, C1).
39. **Jewels:** joining, partial-join starfish, `_Jewels_GiveBonus @ 0001c7c5` (border 1000; L1 5000, L2 6000,
   L3 7000, L4 8000, L5 9000, ≥ L6 10000; ×mult; `_Balloons_CaptureAllEnemies`; `NewStarGroup(target, 2)`),
   `_Jewels_TurnToBlocks` at TimeBonus 0 (every 20/30 cell → 10, star group 0 per cell) — `bubbles-items-
   scoring.md` §3.

### Balloons, bonus, EXTRA, multiplier, time bonus (`bubbles-items-scoring.md` §5–10)

40. **Balloons** (30 × 0x2c at 0x379e0): `_Balloons_New(e) @ 000237f9` (cap 30; first free; position by
   direction; sprite 0x31, frame 1; anim period `GetRandomFast(4,7)`; rect = enemy rect offset 20 px in `dir`;
   collision box 17×17 in front). `_Balloons_Process @ 00024394`: state 1 → move 8 px (box too); first enemy in
   states 1/4/5 hit by the box → capture (state 2, sprite 0x32, rect = the enemy's rect); else hero (not trapped, not
   invisible) overlapping the box → `_Balloons_CaptureHero`; else hard object (box beyond (1,1)..(639,439) or the
   cell in front ∈ 10..60) → pop; else growth (C4). State 2: anim; hero not trapped overlapping the box → pop +
   `_PopEnemy(holder)` (NR-6: holder −1 = hero balloon → no-op); flash after w15; release after w16 (pop +
   `_ReleaseEnemyFromBalloon`). State 3: 4-frame pop, then dead. **Hero balloon (C12):** it pops on the trap-release
   frame h+91 via the "hero not trapped, box overlaps" branch (`_PopEnemy(-1)`, NR-6 no-op), so its w16 release
   (`_ReleaseEnemyFromBalloon(-1)`, ≥ h+121) is unreachable while the hero stays in state 2; the single residual
   path (caught by an enemy on exactly h+91 at a w16 = 120 level, L16–50) is also an NR-6 no-op. Unreachable in
   levels 1–4. `_Balloons_CaptureAllEnemies @ 000240dd`: per
   enemy in states 1/4/5, a holding balloon with one `GetRandomFast(4,7)`.
41. **Bonus bubbles:** `_Bonus_Process @ 0001a92b`: EXTRA blink animation (`_gEXTRA_Timer + 5`, 10 steps,
   pattern masks 0x155/0xaa/0x200); `_Multiplier_Process` (flash only); per armed slot: on `frame == launch`
   harp; skip while `frame <= launch`; flying: rise 2 px, snaking x from `_gBonus_SnakingLUT` (0x341c0, 19 i16:
   `1,1,1,1,0,−1,−1,−1,−1,−1,−1,−1,−1,0,1,1,1,1,0`), drift from the 21-entry table (index wraps 21; 0 none,
   1 −1, 2 −2, 3 +1, 4 +2), top < 0 → dead; x clamp 5..635; shell anim every 3 frames; hero touch (bonus rect
   inset 8 vs hero rect, hero state 2) → `_Bonus_Pop` (popped, `NewStarGroup(left, top, 2)`, `_Bonus_Reward`).
   Popped: floats up, dead `+0x26 + 0x1e < frame`. Rewards: 1 capture all; 2 `_RegenerateBlocks`; 4 invisibility
   (300 frames); 5–8 `_Multiplier_Change` (unreachable — remapped); 9..13 EXTRA E/X/T/R/A; 14 time bonus +value
   (cap 99950) + popup.
42. **EXTRA** (`_EXTRA_Change @ 0001a163`): all five → animate, clear, +1 life, the collected bonus icon becomes
   type 14 (cosmetic), `AddToScore(10000, ×mult)`, `_Balloons_CaptureAllEnemies`.
43. **Multiplier** (`_Bonus_SetNumEnemySquishes @ 0001a818`): n < 3 → no-op (C8); n = 3: 1→2, 2→3, 3→4, 4→5;
   n = 4: 1,2→3, 3→4, 4→5; n = 5: 1..3→4, 4→5; n ≥ 6: 1..4→5; at 5 → +2000 (level < 9) / +4000 ×mult and
   `NewPoint(hero.left, hero.top, 0xc / 0xe, 0)`. Reset to 1 at game start and every play-mode respawn.
44. **Time bonus** (`_TimeBonus_Process @ 00006a15`): only while not end-of-level and bonus > 0; hero state ≠ 2 →
   timer = frame; state 2 and `timer + 0x1e < frame` → −50, timer = frame; reaching exactly 0 →
   `_Jewels_TurnToBlocks`. `_TimeBonus_Increase` caps 99950.
45. **`_RegenerateBlocks @ 0001c3db`:** 6 attempts; each `(1,14),(1,9)` start, walk (pre-increment, skipping the
   hero's row and column) until maze 0 and `gMazeCopy` 10; level < 11 → 15, else `GetRandomFast(0,1)`: 0 → 16,
   1 → 15; enemy under the new bubble (inset 3, `_WasEnemySquished`) → `_SquishEnemy(e,1)`; a walk wrapping twice
   gives up that attempt.

### Cosmetic pools (they consume RNG — model exactly)

46. **Stars** (60 × 0x38 at 0x38640): `_NewStar(x, y, kind, delay, motion, orbitIdx)`: cap `gNumActiveStars ==
   0x3c` → return; first free (none → return); claim; size 26 (kinds 1–6; kind 7 is 38 at x+1/y+1); rect;
   **clip → free + return** (Invariant 6); motion 2 orbit (cheat only — out of scope); motion 0xb: dy −10, period
   7, `dx = GetRandomFast(0,1) == 0 ? −5 : 5`; others dx = dy = 0, period 2; delay > 0 → hidden until `start +
   delay < frame`; `gNumActiveStars++`. `_ProcessStars @ 00004b05`: delayed → wait; motions 3–10 fixed (dx,dy)
   (3 (0,−4), 4 (3,−3), 5 (4,0), 6 (3,3), 7 (0,4), 8 (−3,3), 9 (−4,0), 10 (−3,−3) — offsets as (dh,dv) per the
   decompile `_MyOffsetRect(rect, uVar7, uVar8)`); motion 0xb: dy++ clamped ±18, offset, bounce/exit tests on all
   four edges (exit beyond one star size → dead); then `counter++`; `period < counter` → counter 0, frame++;
   frame > 5 → dead. ⇒ a motion-0xb star dies on its **40th** process call (if not off-screen first); motion 0
   on its **15th**.
47. **Star groups** (`_NewStarGroup @ 000035b5`; pref 0x35 gates all but 0xf/0x10): 0 hero appear/jewel join (8
   stars, motion 0); 2 bonus/jewel bonus/last bubble (8 stars, motions 3..10); 3/4/5 squish/egg kill (4 stars,
   motion 0xb, offsets (−8,−8) (+6,+6) (−16,+20) (+6,+20)); 0xe hero squash (**14** stars, motion 0xb — C2);
   0xf small blast (9, motion 0); 0x10 big blast (21, motion 0); 6–9 speed-up (dead path); 1, 0xb–0xd no callers
   (C3); 10 pause cheat (out of scope). Clip draw counts [Python]: group 3 at cell (0,6) → 2 draws, (5,0) → 3,
   (5,10) → 2, (0,10) → 1, (15,5) → 4, (7,6) → 4; group 0xe at (0,0) → 8, (0,6) → 10, (15,5) → 14.
48. **Air bubbles** (8 × 0x26 at 0x34d40; pref 0x36 gates `_Bubbles` and `_Bubbles_NewGroup`). Launcher
   `_Bubbles @ 000169e2`: return while `frame <= last + delay`; if hero state 2, aligned and `hero+0x0c + 0x8c <
   frame`: facing 3 → group 9 at (hero.left, hero.top), facing 4 → group 10 at (hero.right, hero.top), set
   `hero+0x0c = frame`; otherwise (incl. facing up/down) group `groups[gIdx]` at (`xLoc[xIdx]`, 0x181) with xIdx
   wrapping after 32 and gIdx after 20; then `last = frame; delay = delayTable[dIdx]` (wrap 13). Group sizes
   (number of `_Bubbles_New` calls): 0–3 → 1; 4–6 → 2; 7 → 3; 8 → 4; 9, 10 → 3 (delays 0, 2, 4); 0xb → 5
   (delays 0, 2, 3, 4, 6). `_Bubbles_New @ 00016349`: `NumActive == 8` → return **before** the draw; first free;
   anim period `GetRandomFast(5,9)`; sizes 0..3 → sprite 0x2d..0x30, side 18/23/29/43; rise speed =
   `vertical[vIdx]` clamped (size 0: ≥ 4 → 3; size 1: > 4 → 4; size 2/3: ≤ 2 → 3), vIdx wraps 21.
   `_Bubbles_Process @ 00016b1a`: delayed → wait (`delay + start < frame` → visible), no movement, **no drift-index
   advance**; else anim, rise (top and bottom −= speed), snaking x (`_gBubbles_SnakingTable` 0x3414a, 19 i8:
   `1,1,1,1,0,−1,−1,−1,−1,−1,−1,−1,−1,0,1,1,1,1,0`), drift (global index, wraps 21), **dead when bottom < 0**
   (C7), x clamp 5..635.
49. **Score points** (8 × 0x18 at 0x34620): `_NewPoint(x, y, frame, delay)`: cap 8; x −= 4, clamp to 0 / 592;
   rect (y+8, x, y+36, x+48); sprite 0x34; `+0x16 = (threshold <= level && gPointsNotReg)`; delayed until
   `counter > delay`. `_ProcessPoints`: visible → rise 1 px while top > 0, `counter > 0x1e` → dead. No RNG in the
   modelled licence state.
50. **Splats** (12 × 0x1e at 0x34700): `_Splats_NewSplat(x, y, kind)` sprite 0x26 (enemy) / 0x27 (hero); dead
   when `start + 7 < frame`. No RNG.

---

## Scope

- **Does (done-when):**
  - `BubbleTrouble/Core` builds with Swift 6 (strict concurrency) and its suite is green at **119** tests with
    data wired, zero skips (G1).
  - `MAZE`/`LEVL`/`FILM` load from the real `BT Levels.rsrc` through HectorResources and reproduce the census
    (Task 2).
  - A level builds in the original's draw order with the planner's draw-count checkpoints (Task 4).
  - The frame step mirrors `_PlayGame` incl. all RNG-consuming cosmetic pools (Tasks 3a, 3b, 10).
  - `btx-replay` prints the four-demo table and `ACCEPT 4/4` (G2); `--trace <film>` prints per-frame draws and the
    sample index; goldens (frames, score, lives, total draws) frozen after review (Task 11).
  - Bank corrections C1–C12 appended with evidence (Task 12).
- **Untouched (load-bearing):** HectorKit (any file), `Aki/`, HectorShell, every other game's docs, the EV repo,
  `docs/STATE.md`/`DECISIONS.md`/handoffs (orchestrator-owned).
- **Explicitly deferred (each to a named later plan):**
  - Shell/screens, sprite decoding and drawing, the score bar, notices, cursor → *BTX shell plan* (after this core
    passes the FILMs; uses HectorKit cicn/ppat decoders from `2026-10-03-hectorkit-btx-decoders.md`).
  - Sound playback and the delayed-sound queue → *BTX shell plan* (the core drops `_PlayMySnd`; no RNG).
  - Play-mode level transitions (`_TimeBonus_CountDown`, next `_NewLevel`, unregistered level-7 stop), game-over
    flow, high scores → *BTX play-loop plan* (follows the shell plan).
  - Pause screen and cheat codes incl. the orbit-star burst (`SPIN 1`) → *BTX play-loop plan*.
  - Prefs UI, key sets, registration UI → Ben's gate decision first (INDEX Decisions 2–3).
  - The level editor → last (repo CLAUDE.md; brief).

---

## Tasks

Test counts are exact: each task lists its test names; the per-task count and the cumulative total are STOP
numbers. Commit after each task with the listed paths only.

### Task 0 — Package skeleton, data locator, geometry

**Files:** `BubbleTrouble/Core/Package.swift`; `Sources/BubbleTroubleCore/Geometry/QDRect.swift`,
`Geometry/Direction.swift`, `Data/BTXResourceFiles.swift`; `Sources/btx-replay/main.swift` (placeholder);
`Tests/BubbleTroubleCoreTests/Support/BTXTestData.swift`, `Tests/BubbleTroubleCoreTests/SkeletonTests.swift`
(all paths below `BubbleTrouble/Core/`).

- [ ] **0.1** Verify the worktree: `git -C "$WT" status --porcelain` clean apart from untracked plan files;
  `ls -la "$WT/../HectorKit"` is a symlink to `~/Developer/HectorKit` (create it if absent:
  `ln -s ~/Developer/HectorKit "$WT/../HectorKit"`); `git -C ~/Developer/HectorKit describe --tags` contains
  `v0.1.0` (head on 2026-10-03: `v0.1.0-2-g8287ddb`). Record `BASE=$(git -C "$WT" rev-parse HEAD)` for G5. Every
  lane worktree the orchestrator creates later repeats the symlink check (§Execution order).
- [ ] **0.2** `Package.swift` (config, given whole):
```swift
// swift-tools-version: 6.0
import PackageDescription
// Bubble Trouble X core: data loading + frame-exact simulation + FILM replay. HectorKit by local path
// (three levels up holds both repos; in a worktree, the .claude/worktrees/HectorKit symlink — DECISIONS D1).
let package = Package(
    name: "BubbleTroubleCore",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "BubbleTroubleCore", targets: ["BubbleTroubleCore"]),
        .executable(name: "btx-replay", targets: ["btx-replay"]),
    ],
    dependencies: [.package(path: "../../../HectorKit")],
    targets: [
        .target(name: "BubbleTroubleCore",
                dependencies: [.product(name: "HectorResources", package: "HectorKit")]),
        .executableTarget(name: "btx-replay", dependencies: ["BubbleTroubleCore"]),
        .testTarget(name: "BubbleTroubleCoreTests",
                    dependencies: ["BubbleTroubleCore", .product(name: "HectorResources", package: "HectorKit")]),
    ]
)
```
- [ ] **0.3** Contracts:
```swift
public struct QDRect: Equatable, Hashable, Sendable {          // QuickDraw order
    public var top, left, bottom, right: Int16
    public init(top: Int16, left: Int16, bottom: Int16, right: Int16)
    public static func cell(col: Int, row: Int) -> QDRect        // (row·40, col·40, +40, +40)
    public func collides(_ other: QDRect) -> Bool                // _RectsCollide @ 0000c398, strict
    public mutating func inset(dx: Int16, dy: Int16)             // _MyInsetRect @ 0000c3f1 (left+=dx,right-=dx,top+=dy,bottom-=dy)
    public mutating func offset(dx: Int16, dy: Int16)            // _MyOffsetRect / OffsetRect
}
public enum Direction: Int8, Sendable { case up = 1, down = 2, left = 3, right = 4
    public var opposite: Direction }
public enum BTXDataError: Error, Equatable {
    case missingFile(String), notAResourceFile(String)
    case missingResource(type: String, id: Int16), badSize(type: String, id: Int16, size: Int) }
public struct BTXResourceFiles: Sendable {                       // eager; converts to own value types (Invariant 13)
    public static let levelsFileName = "BT Levels.rsrc"
    public init(resourcesDirectory: URL) throws                  // Task 0: opens the file, records type counts
    public let typeCounts: [String: Int]                         // e.g. ["LEVL": 50, "MAZE": 50, "FILM": 4, …]
}
```
  `BTXTestData` (test support): `static let variable = "HECTORKIT_DATA_BTX"`;
  `static func resourcesDirectory(environment: [String: String] = ProcessInfo.processInfo.environment) throws -> URL`
  (resolves symlinks; `XCTSkip("HECTORKIT_DATA_BTX unset — set it to Bubble Trouble X.app/Contents/Resources")` or
  `"HECTORKIT_DATA_BTX=<v> is not a directory"`); `static func files() throws -> BTXResourceFiles`.
  `btx-replay/main.swift` placeholder prints `btx-replay: not yet implemented (Task 11)` and exits 64.
- [ ] **0.4 Tests (4)** — `SkeletonTests`: `testLocatorSkipsNamingTheVariable` (environment `[:]` → the thrown
  `XCTSkip`'s description contains `HECTORKIT_DATA_BTX`; catch it, do not let it propagate);
  `testRectCollisionIsStrict` (two 40×40 cells sharing an edge do not collide; overlap of 1 px does);
  `testInsetAndOffset` (cell (7,6) inset (8,8) → (248, 288, 272, 312); offset (−5,0) moves left/right only);
  `testLevelsFileOpens` (data-gated: `typeCounts` has LEVL 50, MAZE 50, FILM 4).
- [ ] **0.5 Verify:** gate command → **4** tests, 0 failed/skipped. Without the env var: 4 lines, 1 skipped.
- [ ] **0.6 Commit:** `BubbleTrouble/Core: package skeleton, QDRect/Direction, data locator (4 tests)`.

### Task 1 — RNG: QuickDraw `Random`, `_GetRandomFast`, session latches — ⚑ MAJOR

**Files:** `Sources/BubbleTroubleCore/Random/QuickDrawRandom.swift`, `Random/GameRandom.swift`,
`Random/SessionLatches.swift`; `Tests/BubbleTroubleCoreTests/RandomTests.swift`.

- [ ] **1.1** Contracts:
```swift
public enum QuickDrawRandom {
    /// randSeed = randSeed × 16807 mod (2^31 − 1); value = low 16 bits as Int16, 0x8000 → 0. [LOW] NR-3.
    public static func step(_ seed: UInt32) -> (seed: UInt32, value: Int16)
    /// Diagnosis-only variant (no 0x8000 adjustment) — selected by btx-replay --rng-variant qd-no8000.
    public static func stepWithout8000Adjustment(_ seed: UInt32) -> (seed: UInt32, value: Int16)
}
public struct GameRandom: Sendable {
    public typealias Step = @Sendable (UInt32) -> (seed: UInt32, value: Int16)
    public private(set) var seed: UInt32
    public private(set) var drawCount: Int
    public init(seed: UInt32, step: @escaping Step = QuickDrawRandom.step)
    public mutating func random() -> Int16                       // one Random(); drawCount += 1
    public mutating func fast(_ lo: Int, _ hi: Int) -> Int       // _GetRandomFast @ 0000c4cc, exact arithmetic (note 1)
}
public struct SessionLatches: Equatable, Sendable {
    public var u: Int        // _Get0To6
    public var L: Int        // _Get13To22
    public static let fromProcessSeedOne = SessionLatches(u: 1, L: 15)
    public static func derive(processSeed: UInt32, step: @escaping GameRandom.Step = QuickDrawRandom.step) -> SessionLatches
}
```
  `fast` computes in `UInt32`/`Int32` exactly as the decompile (product, `> 0x7fffffff → += 0xffff`, arithmetic
  shift, `& 0xffff`) — no shortcut. Illustrative core:
  `var p = UInt32(hi - lo + 1) &* UInt32(UInt16(bitPattern: random())); if p > 0x7fff_ffff { p &+= 0xffff };
  return (lo + Int(Int32(bitPattern: p) >> 16)) & 0xffff`.
- [ ] **1.2 Tests (7)** — `RandomTests` (values from Research notes 1–2, 4):
  `testStepFromSeedOne` (→ (16807, 16807), then (282475249, 15089));
  `testStepMaps0x8000ToZero` (seed 32768 → seed 550731776, value 0; the no-8000 variant → −32768);
  `testFilm1SeedFirstFiveRandoms` (values 5764, 13963, 4202, −22575, −23569; seed after 5 = 504603631);
  `testFastMappingWithStubbedStep` (stub returning a fixed value: 0xffff on (0,6) → 6; 0 → 0; 0xffff on (40,480)
  → 480; 0x8000 on (1,750) → 376; 0x8000 on (0,0xffff) → 32768 (the `+0xffff` branch));
  `testFilm1FirstJewelStart` (seed 0x4642a0: `fast(1,14)`, `fast(1,9)` → 2, 2);
  `testSessionLatchesFromSeedOne` (`derive(processSeed: 1)` == (u 1, L 15) == `.fromProcessSeedOne`);
  `testDrawCountCountsEveryRandom` (3 `fast` + 2 `random` → drawCount 5; a custom step is actually used).
- [ ] **1.3 Verify:** gate in the T1 lane worktree → **11** tests (4 + 7), 0 failed/skipped.
- [ ] **1.4 Commit:** `BubbleTrouble/Core: QuickDraw Random + GetRandomFast + session latches (7 tests)`.

### Task 2 — Resource loaders: MAZE, LEVL, FILM (lane 2 of W2, parallel with Task 1)

**Files:** `Sources/BubbleTroubleCore/Data/BigEndian.swift`, `Data/Maze.swift`, `Data/LevelRecord.swift`,
`Data/Film.swift`; extend `Data/BTXResourceFiles.swift`; `Tests/BubbleTroubleCoreTests/ResourceLoaderTests.swift`.

- [ ] **2.1** Contracts:
```swift
public enum CellCode {                                           // UInt8 constants, data-formats.md §1
    public static let empty: UInt8 = 0, normal: UInt8 = 10, blue: UInt8 = 15, purple: UInt8 = 16,
        jewel: UInt8 = 20, cluster: UInt8 = 30, popping: UInt8 = 40, wall: UInt8 = 50,
        dynamite: UInt8 = 52, egg: UInt8 = 60, passableF: UInt8 = 70, passableP: UInt8 = 80 }
public struct Maze: Equatable, Sendable {
    public static let columns = 16, rows = 11, byteCount = 176
    public var cells: [UInt8]                                    // cells[col + 16·row]
    public init(data: Data) throws                               // badSize unless 176
    public subscript(col: Int, row: Int) -> UInt8 { get set }
}
public struct LevelRecord: Equatable, Sendable {
    public var words: [Int16]                                    // 32 raw words as stored (unclamped)
    public init(data: Data) throws                               // badSize unless 64; big-endian
    public var mazeID: Int, pictID: Int, musicSet: Int, hurtFrameBubble: Int, hurtFrameJewel: Int { get }
    public var totalEnemies: Int { get }                         // w6 clamped: w6 < 31 ? w6 : 30
    public var maxActive: Int, eggTime: Int, preEggDelay: Int { get }      // w7, w8, w10
    public var jewelCount: Int { get }                           // w12 clamped to 3...4
    public var balloonFlash: Int, balloonRelease: Int { get }   // w15, w16
    public var pool: [Int16] { get }                             // w18...w23
}
public struct FilmSample: Equatable, Sendable { public var up, down, left, right, push: Bool }
public struct Film: Equatable, Sendable {
    public static let byteCount = 10012, capacity = 2000
    public let id: Int, count: Int, seed: UInt32, levelField: UInt32
    public let up, down, left, right, push: [UInt8]              // 2000 each
    public init(id: Int, data: Data) throws                      // badSize unless 10012
    public func sample(_ index: Int) -> FilmSample               // precondition index < 2000
}
extension BTXResourceFiles {
    public var levelIDs: [Int], mazeIDs: [Int], filmIDs: [Int] { get }   // sorted
    public func maze(_ id: Int) throws -> Maze
    public func level(_ id: Int) throws -> LevelRecord
    public func film(_ id: Int) throws -> Film
}
```
- [ ] **2.2 Tests (11)** — `ResourceLoaderTests` (numbers: Research notes 7–10):
  synthetic: `testMazeRejectsWrongSize`, `testFilmRejectsWrongSize`, `testLevelClamps` (words with w6 = 40 →
  30, w12 = 2 → 3, w12 = 7 → 4; raw `words` unchanged);
  data-gated: `testLevelsCensus` (ids 1...50 / 1...50 / 1...4, all sizes exact);
  `testFilmHeaders` (four (count, seed, levelField) triples); `testFilmArraysBinaryAndLeftovers` (all bytes 0/1;
  FILM 1 leftovers 89/100/90/92/1, held-in-range 86/67/59/98/19); `testFilm1RunLengthsAndFirstPush` (the six
  first runs, first push at 212); `testMultiDirectionSamples` (0/11/11/18); `testMazeCensusAndStartCell`
  (census list exact; `maze[7,6] == 0` for all 50); `testLevel1Words` (the 32 words of note 9);
  `testLevelTablesAllFifty` (Σpool == totalEnemies for all; w15/w16 step table; jewels 3 (1–12) / 4 (13–50);
  w8 == 50, w10 == 10, w17 == 300 everywhere; mazeID == id).
- [ ] **2.3 Verify:** gate in the T2 lane worktree → **15** (4 + 11); after the orchestrator merges W2 → **22**;
  0 failed/skipped.
- [ ] **2.4 Commit:** `BubbleTrouble/Core: MAZE/LEVL/FILM loaders reproducing the census (11 tests)`.

### Task 3a — Cosmetic pools I: stars, incl. the pre-draw clip and the 14-star group 0xe — ⚑ MAJOR

Self-contained struct: it takes everything it reads from the world as parameters, so this task needs only Task 1.
(Split from the original Task 3 at review — A3; 3a and 3b run in one lane, 3a first.) **Files:**
`Sources/BubbleTroubleCore/Pools/CosmeticPrefs.swift` (`CosmeticPrefs` + `HeroAnchor`, shared with 3b),
`Pools/StarPool.swift`; `Tests/BubbleTroubleCoreTests/StarPoolTests.swift`.

- [ ] **3a.1** Contracts (field lists mirror the slot layouts of Research notes 46–47; names are the seat's):
```swift
public struct CosmeticPrefs: Equatable, Sendable { public var stars = true; public var airBubbles = true }
public struct HeroAnchor: Sendable {                            // what _NewStarGroup 6–9 / _Bubbles read from the hero
    public var state: Int16, aligned: Bool, facing: Direction, rect: QDRect, lastBubbleFrame: UInt16 }
public struct Star: Equatable, Sendable { /* active, startFrame, kind, motion, rect, prevRect, width, height,
    spriteSet, frame, animCounter, period, dx, dy, delay, delayed, visible, dead, orbitIndex, orbitOrigin */ }
public struct StarPool: Sendable {
    public static let capacity = 60
    public internal(set) var slots: [Star]; public internal(set) var activeCount: Int
    public internal(set) var locationLookup: [Int16]; public internal(set) var locationIndex: Int
    public mutating func reset(rng: inout GameRandom)                      // _InitStars: 42 draws
    public mutating func newStar(x: Int16, y: Int16, kind: Int16, delay: Int16, motion: Int16,
                                 orbitIndex: Int16, frame: UInt16, rng: inout GameRandom)   // _NewStar
    public mutating func newGroup(x: Int16, y: Int16, group: Int, hero: HeroAnchor, frame: UInt16,
                                  prefs: CosmeticPrefs, rng: inout GameRandom)              // _NewStarGroup
    public mutating func process(frame: UInt16)                             // _ProcessStars
    public mutating func drawPassFree()                                     // free part of _DrawStarsToComp (+ prevRect copy)
}
```
  Transcribe `_NewStar`, `_NewStarGroup` (every live group, incl. the shared tail call — C2), `_ProcessStars` from
  the decompile; group 10 (orbit, pause cheat) → `preconditionFailure` with a message naming the deferral.
- [ ] **3a.2 Tests (7)** — `StarPoolTests` (numbers: Research notes 46–47):
  `testStarResetDraws42`; `testSquishGroupClipDrawCounts` (group 3: (0,6)→2, (5,0)→3, (5,10)→2, (0,10)→1,
  (15,5)→4, (7,6)→4 draws; clipped stars leave `activeCount` unchanged); `testGroup0xEHasFourteenStars`
  (at (7,6): 14 active, 14 draws; at (0,0): 8 draws); `testStarCapSixtyDrawsNothing` (60 active → group 3 draws 0);
  `testStarsPrefOffOnlyBlastGroups` (prefs off: group 3 → 0 stars; both blast groups placed at x = 300, y = 200 —
  group 0x10 is kind 7 (38 px at x+1/y+1) with offsets ±80, so it clips unless x ∈ 79…521 and y ∈ 79…321
  (`_NewStarGroup @ 000035b5` case 0x10): group 0xf → 9 stars, 0 draws; group 0x10 → 21 stars, 0 draws);
  `testMotion0xBStarDiesOnCall40` (a centred motion-0xb star is alive after 39 `process` calls, dead after 40,
  freed by `drawPassFree`); `testMotion0StarDiesOnCall15`.
- [ ] **3a.3 Verify:** gate → **29** (after Tasks 1–2 merged), 0 failed/skipped.
- [ ] **3a.4 Commit:** `BubbleTrouble/Core: star pool with the pre-draw clip and the 14-star group 0xe (7 tests)`.

### Task 3b — Cosmetic pools II: air bubbles, score points, splats — ⚑ MAJOR

Needs Task 3a (`CosmeticPrefs`, `HeroAnchor`). **Files:** `Sources/BubbleTroubleCore/Pools/AirBubblePool.swift`,
`Pools/PointPool.swift`, `Pools/SplatPool.swift`; `Tests/BubbleTroubleCoreTests/CosmeticPoolTests.swift`.

- [ ] **3b.1** Contracts (Research notes 48–50):
```swift
public struct AirBubble: Equatable, Sendable { /* active, startFrame, animTimer, animPeriod, size, rect,
    prevRect, snakeIndex, riseSpeed, spriteSet, frame, visible, dead, delayed, delay */ }
public struct AirBubblePool: Sendable {
    public static let capacity = 8
    public internal(set) var slots: [AirBubble]; public internal(set) var activeCount: Int
    public internal(set) var xLoc: [Int16], drift: [Int8], vertical: [Int8], delayTable: [Int16], groups: [Int8]
    public internal(set) var xIndex, driftIndex, verticalIndex, delayIndex, groupIndex: Int
    public internal(set) var timeLastGroupLaunched: UInt16, delayTilNextGroup: Int16
    public mutating func reset(rng: inout GameRandom)                       // _Bubbles_Init: 109 draws
    public mutating func launch(frame: UInt16, hero: inout HeroAnchor, prefs: CosmeticPrefs, rng: inout GameRandom) // _Bubbles
    public mutating func newGroup(x: Int16, y: Int16, group: Int, frame: UInt16, prefs: CosmeticPrefs, rng: inout GameRandom)
    public mutating func newBubble(x: Int16, y: Int16, size: Int8, delay: Int16, frame: UInt16, rng: inout GameRandom)
    public mutating func process(frame: UInt16)                             // _Bubbles_Process
    public mutating func drawPassFree()
}
public struct PointPool: Sendable {                                         // 8 slots
    public mutating func reset(rng: inout GameRandom)                       // _InitPoints: 8 draws
    public internal(set) var thresholds: [Int16]                            // 20...24
    public mutating func newPoint(x: Int16, y: Int16, sprite: Int16, delay: Int16, level: Int, notRegistered: Bool)
    public mutating func process()
    public mutating func drawPass(rng: inout GameRandom)                    // trap draw if flagged, then free
}
public struct SplatPool: Sendable {                                         // 12 slots
    public mutating func reset(); public mutating func newSplat(x: Int16, y: Int16, kind: Int8, frame: UInt16)
    public mutating func process(frame: UInt16); public mutating func drawPassFree()
}
```
  Transcribe `_Bubbles`, `_Bubbles_NewGroup`, `_Bubbles_New`, `_Bubbles_Process`, `_NewPoint`, `_ProcessPoints`,
  `_DrawPointsToComp`, `_Splats_*` from the decompile.
- [ ] **3b.2 Tests (9)** — `CosmeticPoolTests` (numbers: Research notes 48–50):
  `testBubbleResetDraws109AndGroupMap` (drawCount 109; a stub step forcing `(0,14)` results 0…14 maps to
  0,0,1,1,2,2,3,4,4,5,5,6,7,7,8);
  `testBubbleGroupSizes` (groups 0…0xb → draws 1,1,1,1,2,2,2,3,4,3,3,5 on an empty pool);
  `testBubbleCapEight` (8 alive → `newBubble` draws 0); `testBubbleDiesWhenBottomBelowZero` (size 2 at y 385,
  speed 3: alive after 138 `process` calls, dead flag after 139); `testDelayedBubbleNeitherMovesNorDrifts`
  (group 9's delayed bubble keeps its rect and leaves `driftIndex` untouched until visible);
  `testLauncherTimingAndHeroMouth` (after `reset`: no launch at frame 30, launch at 31; hero aligned facing left
  with `lastBubbleFrame + 140 < frame` → group 9 at the hero's left/top and `lastBubbleFrame = frame`; facing up
  → random-table group); `testPointResetThresholds` (all in 20...24, 8 draws); `testPointLifetimeAndTrap`
  (visible point dead after 31 `process` calls; `drawPass` draws 0 unless `notRegistered && threshold <= level`,
  then 1 per live point per call); `testSplatLifetime` (dead when `start + 7 < frame`).
- [ ] **3b.3 Verify:** gate → **38**, 0 failed/skipped.
- [ ] **3b.4 Commit:** `BubbleTrouble/Core: air-bubble/point/splat pools (9 tests)`.

### Task 4 — `GameState` and level construction in draw order — ⚑ MAJOR

**Files:** `Sources/BubbleTroubleCore/Sim/SessionConfig.swift`, `Sim/Entities.swift`, `Sim/GameState.swift`,
`Sim/LevelBuild.swift`, `Sim/TestWorld.swift` (the internal no-files test factory every later synthetic test uses —
moved here from Task 5 at review, A4/B2); `Tests/BubbleTroubleCoreTests/LevelBuildTests.swift`.

- [ ] **4.1** Contracts. `Entities.swift` declares **every** field the later tasks need (Invariant: later tasks
  must not add stored properties elsewhere — Swift extensions cannot; if one is missing, add it here in its own
  one-line commit and tell the parallel lane):
```swift
public struct SessionConfig: Sendable {                          // NOT Equatable: it holds an @Sendable closure, so a
    public var latches = SessionLatches.fromProcessSeedOne       // synthesized == cannot compile (A2). If equality is ever
                                                                 // needed, hand-write == over the four non-closure fields.
    public var registeredValidLicence = true                     // INDEX Decision 2 (assumption)
    public var prefs = CosmeticPrefs()                           // stars + air bubbles ON (assumption)
    public var pointsNotRegistered = false                       // NR-4 (assumption)
    public var rngStep: GameRandom.Step = QuickDrawRandom.step   // Invariant 10
}
public enum GameMode: Sendable { case play, demo }
public struct Hero: Equatable, Sendable { /* hero-and-input.md §0: state, stateStart, lastBubbleFrame, rect,
    prevRect, licenceValid, facing, col, row, aligned, xOffset, yOffset, registered, spriteSet, spriteFrame,
    frozen, freezeCounter, freezeDuration, deathCounter, visible, deathBubblesEmitted, trapped, trapStart,
    invisible, invisibleStart, blinkCounter, blinkToggle, drawTransparent, speedUp(false), speed */ }
public struct Enemy: Equatable, Sendable { /* enemies-ai.md §0 incl. state, stateStart, type, rect, prevRect,
    direction (0 = none), col, row, aligned, spriteSet, tier, marker, animFrame, animTick, balloonIndex (−1),
    postHatchCounter, postHatchDelay, drawn, dead, stuck, paused, speedCounter, speed, actionWait, pendingAction,
    lastPop, licenceValid */ }
public struct Block: Equatable, Sendable { /* bubbles-items-scoring.md §1 table + jewel col/row (+0x22/+0x23) */ }
public struct Balloon: Equatable, Sendable { /* state 1 fly/2 hold/3 pop, start, animTimer, animPeriod, rect,
    prevRect, direction, spriteSet, frame, counter, visible, dead, captureKind (0x46 hero / 0x50 enemy),
    holder (Int8, −1 hero), box */ }
public struct BonusBubble: Equatable, Sendable { /* armed, dead, popped, visible, type, rect, prevRect,
    snakeIndex, riseSpeed, iconSet, iconFrame, animTimer, shellFrame, timeValue, launchFrame, poppedFrame */ }
public enum StopReason: Hashable, Sendable {
    case countExhausted, heroDeathAnimationDone, levelCompleted, gameOverNoLives, originalWouldAbort(String) }
public struct GameState: Sendable {
    public internal(set) var config: SessionConfig, mode: GameMode, rng: GameRandom, frame: UInt16, level: Int
    public internal(set) var maze: Maze, mazeCopy: Maze, levelRecord: LevelRecord       // working copy (pool mutates)
    public internal(set) var hero: Hero, enemies: [Enemy] /*30*/, blocks: [Block] /*35*/, balloons: [Balloon] /*30*/
    public internal(set) var bonus: [BonusBubble] /*2*/, bonusDrift: [Int16] /*21*/, bonusDriftIndex: Int
    public internal(set) var stars: StarPool, airBubbles: AirBubblePool, points: PointPool, splats: SplatPool
    public internal(set) var score: Int32, nextExtraLifeScore: Int32, lives: Int16, multiplier: Int16
    public internal(set) var extraLetters: [Bool] /*E X T R A*/, extraAnimating: Bool, extraTimer: UInt16, extraAnimCounter: Int16
    public internal(set) var timeBonus: Int32, timeBonusTimer: UInt16
    public internal(set) var numJewels: Int, jewelFound: Bool, targetJewel: (col: Int8, row: Int8)?, jewelCount: Int,
                             jewelsDone: Bool, jewelAnimDir: Bool, jewelCells: [(col: Int8, row: Int8)]
    public internal(set) var numNormalBlocks: Int16                 // 100 after _ResetBlocks (C6)
    public internal(set) var numEnemiesActive: Int8, numEnemiesSquished: Int8, numActiveBlocks: Int, numActiveBalloons: Int
    public internal(set) var bonusSquishedAtOnce: Int16
    public internal(set) var isEndOfLevel: Bool, endOfLevelTime: UInt16, firstAppearance: Bool, playing: Bool
    public internal(set) var levelForEffect: Int                    // 50 until the first state-2 _ProcessHero
    public internal(set) var pendingStops: Set<StopReason>
    /// _PlayGame prologue (demo/play) + _NewLevel. Seeds with `seed`, level = `level`.
    public static func newGame(level: Int, mode: GameMode, seed: UInt32, files: BTXResourceFiles,
                               config: SessionConfig = SessionConfig()) throws -> GameState
    mutating func newLevel(files: BTXResourceFiles) throws          // _NewLevel @ 0001735f, exact order (note 12)
}
```
  (Tuples are not `Equatable`; use a small `struct CellRef: Equatable, Sendable { col, row: Int8 }` instead of the
  tuples shown — seat's choice.) `LevelBuild.swift` holds `_LoadLevel` (incl. the ≥ 51 branch), `_ResetBlocks`,
  `_TimeBonus_Reset`, `_LoadMaze`, `_InitHero`, `_ResetHeroPosition`, `_PositionJewels`, `_PositionSingleJewel`,
  `_InitEnemies`, `_Balloons_Init`, `_Bonus_Init`, calling the Task 3a/3b pools' `reset` in `_NewLevel`'s order.
  `TestWorld.swift` contract (internal; tests reach it through `@testable import BubbleTroubleCore`):
```swift
extension GameState {
    /// No files, ZERO RNG draws (rng.drawCount == 0 on return). Synthetic LEVL = level-1 words with w0 = level,
    /// w6 = totalEnemies, w7 = maxActive, w12 = jewelCount, w15/w16 from note 9's step table for `level`,
    /// w18…w23 = pool. mazeCopy = maze. Runs _ResetBlocks (numNormalBlocks = 100), _TimeBonus_Reset, _InitHero
    /// (start-cell rules of note 13), then hero.state = heroState, stateStart 0, visible. Jewels NOT placed; pools
    /// empty and NOT reset (tables zero); frame 0; lives 3; score 0; next extra life 10000; multiplier 1;
    /// levelForEffect 50; playing = true.
    static func testWorld(maze: Maze, level: Int = 1, seed: UInt32 = 1, jewelCount: Int = 3,
                          totalEnemies: Int = 4, maxActive: Int = 2, pool: [Int16] = [4, 0, 0, 0, 0, 0],
                          heroState: Int16 = 2, mode: GameMode = .demo,
                          config: SessionConfig = SessionConfig()) -> GameState
}
```
- [ ] **4.2 Tests (6)** — `LevelBuildTests` (Research note 18; data-gated unless noted):
  `testNewLevelDrawCheckpoints` (for FILMs 1–4: drawCount 6 after jewels, 115 after the bubble LUT, 157 after
  stars, 165 after points, final 191 / 194 / 194 / 193 — expose the checkpoints via an internal
  `newLevel(files:checkpoints:)` hook or by stepping the sub-steps in the test with `@testable import`);
  `testJewelPlacement` (the 12 cells); `testBonusInit` (launch/left/type/time value per slot, slot 1 of FILM 1
  unarmed); `testFilm1Tables` (x-table head, delay table, groups, vertical/drift heads, star lookup head, point
  thresholds, bonus drift head, final seed 446091883); `testStateAfterNewLevel` (FILM 1: hero (7,6), state 1,
  facing left, speed 5, stateStart 0; lives 3; score 0; multiplier 1; time bonus 2500; `numNormalBlocks == 100`;
  80 cells == 10; all enemy/block/balloon slots free; `levelForEffect == 50`; frame 0);
  `testJewelWalkWidensAfter500` (synthetic, `testWorld(maze:…, jewelCount: 3)` — **3, so the walk terminates**; with
  4 jewels and 3 candidate cells the original loops forever: a maze whose only normal bubbles are (0,0), (5,0),
  (10,0) → `positionJewels` places all three on row 0; drawCount 6).
- [ ] **4.3 Verify:** gate → **44**, 0 failed/skipped.
- [ ] **4.4 Commit:** `BubbleTrouble/Core: GameState + NewLevel in the original draw order + test world (6 tests)`.

### Task 5a — Shared primitives I: maze and jewel queries, scoring, catches — ⚑ MAJOR

(Split from the original Task 5 at review — B3; 5a and 5b run in one lane, 5a first.) Every synthetic test builds
its world with Task 4's `GameState.testWorld(…)`. **Files:** `Sources/BubbleTroubleCore/Sim/MazeQueries.swift`
(`_GetNextObject`, `_GetDistantObject`, `_NormalBlockCount`), `Sim/JewelQueries.swift` (`_IsTargetJewelFound`,
`_IsJewelTheTarget`, `_IsJewelTheDistantTarget` — B1: Task 6's push table and Task 8's jewel movement call them),
`Sim/Scoring.swift` (`_AddToScore`, `_AddHero`, `_Bonus_SetNumEnemySquishes`, `_Multiplier_Change/Reset`),
`Sim/Catch.swift` (`_IsHeroCaught`, `_HeroCaught`, `_StopAllEnemies`, `_SetHeroInvisibility`);
`Tests/BubbleTroubleCoreTests/PrimitivesTests.swift`.

- [ ] **5a.1** Contracts: each original function is one `mutating func` (or non-mutating query) on `GameState`
  named in lowerCamelCase after it, `internal` unless the shell needs it: `getNextObject(_ dir: Direction, col: Int,
  row: Int) -> UInt8`, `getDistantObject(…) -> UInt8` (off-grid → 50), `normalBlockCount() -> Int16`,
  `addToScore(_ v: Int32, multiply: Bool)`, `bonusSetNumEnemySquishes(_ n: Int)`, `heroCaught(kind: Int)`,
  `isHeroCaught(_ rect: QDRect, protectInvisible: Bool, bigInset: Bool) -> Bool`, `stopAllEnemies()`, and the jewel
  queries:
```swift
func isTargetJewelFound() -> Bool                                   // _IsTargetJewelFound @ 0001c9b9: returns gJewelFound
func isJewelTheTarget(_ dir: Direction, col: Int8, row: Int8) -> Bool          // _IsJewelTheTarget @ 0001c8fb
func isJewelTheDistantTarget(_ dir: Direction, col: Int8, row: Int8) -> Bool   // _IsJewelTheDistantTarget @ 0001c95a
```
  Decompile semantics: both target queries return false unless `gJewelFound`; they step (col,row) one cell (resp.
  two) in `dir` — 3 → col −1, 4 → col +1, 1 → row −1, 2 → row +1 (`char` arithmetic) — and return whether that cell
  equals (`gTargetJewelXLoc`, `gTargetJewelYLoc`). Star/point/splat side effects call the Task 3a/3b pools with
  `hero` mapped to `HeroAnchor`.
- [ ] **5a.2 Tests (5)** — `PrimitivesTests` part 1 (Research notes 27–28, 43):
  `testMultiplierStepTable` (all 4 × 5 cells of note 43; at multiplier 5 the award is `_AddToScore(v, 1)` — ×5 —
  so **+10000** at level 8 (2000 × 5) and **+20000** at level 9 (4000 × 5), multiplier stays 5; n = 0, 1, 2 → no
  change — C8); `testAddToScoreExtraLives` (lives +1 at 10000, next 40000, then 80000; a single +100000 from 0
  gives one life only); `testHeroCatchInsetBoundary` (enemy rect same row: dx 20 caught, 21 not; invisible hero with
  protect = 1 never caught); `testHeroCaughtKind2` (state 3, stateStart = frame, all enemies in states 1,2,3,4,6 → 5,
  one splat, `hero.visible == false` (+0x4a) while `hero.invisible` (+0x50) is unchanged — B6, 14 star slots tried,
  1 + 14 draws at (7,6)); `testJewelTargetHelpers` (B1; `jewelFound` false → all three false; target (5,5) found:
  from (4,5) dir right → `isJewelTheTarget` true, distant false; from (3,5) dir right → distant true, target false;
  from (5,7) dir up → distant true; from (5,4) dir up → both false).
- [ ] **5a.3 Verify:** gate → **49**, 0 failed/skipped.
- [ ] **5a.4 Commit:** `BubbleTrouble/Core: maze/jewel queries, scoring, catches (5 tests)`.

### Task 5b — Shared primitives II: enemy mutations, block creation, dynamite — ⚑ MAJOR

Needs Task 5a. **Files:** `Sources/BubbleTroubleCore/Sim/EnemyMutations.swift` (`_SquishEnemy`, `_PopEnemy`,
`_KillEnemy`, `_CaptureEnemy`, `_ReleaseEnemyFromBalloon`, `_MakeAllEnemiesDisappear`, `_WasEnemySquished`,
`_Balloons_PopBalloon`, `_Balloons_PopAll`), `Sim/BlockCreation.swift` (`_NewBlock`, `_PushBlock`, `_CrushBlock`,
`_KillEggBlock`, `_IsActiveBombBlock`, `_ActivateBombBlock`), `Sim/Dynamite.swift` (`_ExplodeBombBlock`,
`_CheckForBombKills`); `Tests/BubbleTroubleCoreTests/PrimitivesMutationTests.swift`.

- [ ] **5b.1** Contracts (same naming rule): `squishEnemy(_ slot: Int, count: Int)`, `popEnemy(_:)`, `killEnemy(_:
  score:)`, `captureEnemy(_:balloon:)`, `releaseEnemyFromBalloon(_:)` (slot −1 → no-op, NR-6/C12),
  `makeAllEnemiesDisappear()`, `wasEnemySquished(_ rect: QDRect) -> Int` (−1 none; **no dead-flag test** —
  Invariant 7), `newBlock(col:row:direction:type:enemy:moving:)`, `pushBlock(col:row:direction:type:)`,
  `crushBlock(col:row:direction:score:)`, `killEggBlock(col:row:)`, `isActiveBombBlock(col:row:) -> Bool`,
  `activateBombBlock(col:row:direction:)`, `explodeBombBlock(_ slot: Int)`, `checkForBombKills(_ rect: QDRect,
  base: Int) -> Int`.
- [ ] **5b.2 Tests (11)** — `PrimitivesMutationTests` (Research notes 26, 34–35, 38):
  `testSquishScoreTable` (B4: **each case on a fresh `testWorld`** — multiplier 1, `bonusSquishedAtOnce` 0 — so the
  n = 3 step cannot leak into the next case: n 1…6 → +200, 400, 800, 1600, 3200, 3200; multiplier afterwards 1, 1,
  2, 3, 4, 5); `testHeroCaughtOncePerFrame` (three overlapping blast rects on the hero → exactly one `heroCaught`;
  draws = 1 + the visible stars of one group 0xe — C1); `testNewBlockFirstFreeSlotAndTypes` (slot reuse after a
  free; type table of note 35); `testPushBlockClearsCell`; `testCrushBlockScoresAndMarksCell` (+1 ×mult, cell 40,
  dynamite cell stays 52); `testKillEggBlock` (+50, cell 40, enemy dead + squished++, point sprite 0x15, star group
  by type); `testFuseAndRelight` (fuse lit at f: relight at f+30 → nothing; at f+31 → explodes now);
  `testSmallBlastRect` (B12: level 1, bomb (5,5), blast rect (160,160,280,280); enemy **slot 0** at (4,4), **slot 1**
  at (6,6), **slot 2** at (3,5) (its right edge 160 only touches — strict collide): slots 0/1 squished with n = 1, 2
  (+200, +400 → score 600), slot 2 untouched; star group 0xf, 0 draws (kind 7, motion 0));
  `testBigBlastDoubleCount` (level 12, bomb (5,5), enemy slot 0 at (5,4), slot 1 at (3,5), hero far: score 1000
  = 200 + 800, multiplier 2 — without the quirk it would be 600 and 1); `testStopAllAndDisappear` (pool words
  restored, squished unchanged, balloons popped); `testWasEnemySquishedPopsHeldBalloon` (state-6 enemy → its
  balloon state 3; returns the slot; **and** a dead-but-unfreed state-1 enemy overlapping the rect is still returned
  — B7).
- [ ] **5b.3 Verify:** gate → **60**, 0 failed/skipped.
- [ ] **5b.4 Commit:** `BubbleTrouble/Core: enemy mutations, block creation, dynamite (11 tests)`.

### Task 6 — Hero: input, movement, push/pop, death animation — ⚑ MAJOR (lane A of W6, parallel with Tasks 7a–7b)

**Files:** `Sources/BubbleTroubleCore/Sim/Input.swift`, `Sim/Hero.swift`;
`Tests/BubbleTroubleCoreTests/HeroTests.swift`.

- [ ] **6.1** Contracts:
```swift
public protocol InputSource {
    mutating func readSample() -> FilmSample      // called ONLY from checkHeroMovement (Invariant 5)
    var samplesConsumed: Int { get }
    var isExhausted: Bool { get }                 // demo: film.count <= samplesConsumed; live: false
}
public struct FilmInput: InputSource, Sendable { public init(film: Film) /* precondition < 2000 */ }
public struct ScriptedInput: InputSource, Sendable { public init(samples: [FilmSample]) }   // tests, synthetic
extension GameState {
    mutating func processHero<I: InputSource>(input: inout I)       // _ProcessHero @ 00022de0 (note 23)
    mutating func checkHeroMovement<I: InputSource>(input: inout I) // _CheckHeroMovement @ 00021f49
    mutating func moveHeroAligned()                                  // _MoveHeroAligned @ 00022847
    mutating func moveHeroNotAligned()                               // _MoveHeroNotAligned @ 000224c8
    mutating func heroPushCrushCheck() -> Int                        // _HeroPushCrushCheck @ 000220d8 → 0/1/2
}
```
  The push table's jewel rows use Task 5a's `isTargetJewelFound` / `isJewelTheTarget` / `isJewelTheDistantTarget`.
- [ ] **6.2 Tests (12)** — `HeroTests` (Research notes 5, 23–26):
  `testSampleConsumptionByState` (states 1, 3, 4 → 0 samples; state 2 → 1 per call);
  `testPushFreezeDurations` (push: call 1 consumes, calls 2–4 consume 0, call 5 consumes; pop: calls 2–7 consume
  0, call 8 consumes); `testTrapReleaseFrameConsumesNone` (trapped at f0: calls at f0+1…f0+90 consume 0, f0+91
  clears and consumes 0, f0+92 consumes 1); `testDirectionPriorityAligned` (Up+Left → up; Down+Right → down;
  Left+Right → left); `testReversalBetweenCells` (mid-cell moving left: Right reverses at once, Up is ignored);
  `testEightFramesPerCell` (Left held from (7,6) with (6,6) empty: aligned again at (6,6) after exactly 8 calls);
  `testPushTableBubble` (empty beyond → moving block + cell 0, return 1; wall/edge beyond → pop, return 2);
  `testPushTableJewels` (no join yet: push into empty/jewel; thud otherwise; cluster/wall thud — return 1, no
  block); `testPushTableEggAndDynamite` (egg → kill, return 2; free dynamite → slides; blocked → crush + fuse;
  lit dynamite free to slide → 0); `testDeathAnimationBubblesOnce` (visible hero (`+0x4a`) in state 4: the 32nd
  call emits group 0xb (5 bubble draws on an empty pool), never again; a hero with `visible == false` — as
  `heroCaught(kind: 2)` leaves it (B6) — emits nothing and draws 0; the invisibility bonus `+0x50` does not gate it);
  `testLevelForEffectDraws` (level 15 with L = 15: a direction choice draws 1; level 14 draws 0; the push-freeze
  end draws 1 at level 15); `testInvisibilityTimeline` (off after `start + 300 < frame`; blink toggles from
  `start + 210 < frame`, every 3 calls).
- [ ] **6.3 Verify:** gate in the T6 lane worktree → **72** (60 + 12); after the orchestrator merges W6 → **84**;
  0 failed/skipped.
- [ ] **6.4 Commit:** `BubbleTrouble/Core: hero input, movement, push table, death animation (12 tests)`.

### Task 7a — Items I: balloons — ⚑ MAJOR (lane B of W6, parallel with Task 6)

(Split from the original Task 7 at review — B3; the contract divides cleanly: balloons are self-contained, and
Task 7b's capture-all rewards call into them. 7a then 7b in one lane.) **Files:**
`Sources/BubbleTroubleCore/Sim/Balloons.swift`; `Tests/BubbleTroubleCoreTests/BalloonTests.swift`.

- [ ] **7a.1** Contracts: `balloonsNew(enemy:)`, `balloonsProcess()`, `balloonsCaptureHero(_:)`,
  `balloonsCheckBalloonEnemyHit(_:) -> Bool`, `balloonsCheckHardObjectHit(_:) -> Bool`,
  `balloonsCheckSquishes(_ rect: QDRect)`, `balloonsCaptureAllEnemies()` — all `mutating` on `GameState`,
  transcribed from the functions of Research note 40 (incl. the C12 hero-balloon behaviour: holder −1 → the
  `_PopEnemy(-1)` / `_ReleaseEnemyFromBalloon(-1)` calls are no-ops).
- [ ] **7a.2 Tests (6)** — `BalloonTests`:
  `testBalloonNew` (shark facing down at (5,5): one `(4,7)` draw, rect offset +20 down, box 17×17, sprite 0x31);
  `testBalloonGrowsOnceOnThirdFrame` (box becomes (top+8, left+8, top+31, left+26) on the 3rd flying call and
  never changes again — C4); `testBalloonCaptureOrder` (box over an enemy and the hero → the enemy is captured,
  the hero is not trapped); `testBalloonHoldFlashRelease` (level 1: flash toggling from `h + 140 < frame`,
  release + pop at `h + 171`); `testCheckSquishesFlyingOnly` (a flying balloon pops, a holding one does not —
  C5); `testCaptureAllDraws` (three enemies in states 1/4/5 + one egg → 3 draws, 3 holding balloons).
- [ ] **7a.3 Verify:** gate in the T7a/7b lane worktree → **66** (60 + 6), 0 failed/skipped.
- [ ] **7a.4 Commit:** `BubbleTrouble/Core: balloons (6 tests)`.

### Task 7b — Items II: bonus bubbles, EXTRA, time bonus, regenerate — ⚑ MAJOR (lane B of W6, after 7a)

**Files:** `Sources/BubbleTroubleCore/Sim/Bonus.swift`, `Sim/Extra.swift`, `Sim/TimeBonus.swift` (incl.
`_Jewels_TurnToBlocks`, `_TimeBonus_Increase`), `Sim/Regenerate.swift`; `Tests/BubbleTroubleCoreTests/ItemsTests.swift`.

- [ ] **7b.1** Contracts: `bonusProcess()`, `bonusWasHit(_ rect: QDRect) -> Bool`, `bonusDoesHeroTouch(_:) -> Bool`,
  `bonusPop(_:)`, `bonusReward(_:)`, `extraChange(letter:bonusSlot:)`, `timeBonusProcess()`, `timeBonusIncrease(_:)`,
  `jewelsTurnToBlocks()`, `regenerateBlocks()` — all `mutating` on `GameState`, transcribed from the functions of
  Research notes 41–45 (`_Bonus_Reward @ 0001a2c5`, `_RegenerateBlocks @ 0001c3db`).
- [ ] **7b.2 Tests (6)** — `ItemsTests`:
  `testBonusLaunchRiseAndExit` (FILM-1-like slot launching at 578: no movement at 578, top 438 at 579; dead the
  call its top goes negative); `testBonusRewardTable` (B12, `bonusReward` on a `testWorld` at frame 500, time bonus
  2500: type 14 value 1000 → time bonus **3500**, and from 99500 → **99950** (cap); type 4 → `hero.invisible`,
  `invisibleStart == 500`; types 9…13 → EXTRA letters 0…4 set one at a time; type 1 with two state-1 enemies →
  **2** draws, 2 holding balloons; type 2 at level 1 → **12** draws (`_RegenerateBlocks`, no enemy under));
  `testExtraCompletion` (fifth letter → +1 life, +10000 ×mult, all enemies captured, letters cleared);
  `testTimeBonusTicks` (2500 at level 1; state 2 from frame 71 with timer 70 → 2450 at 101, 2400 at 132; a
  state-3 frame re-arms the timer); `testTimeBonusZeroRevertsJewels` (reaching exactly 0 turns 20/30 cells into
  10); `testRegenerateBlocks` (B12; synthetic: `mazeCopy` = 10 and `maze` = 0 at exactly six cells inside cols 1–14
  × rows 1–9, none on the hero's row 6 or column 7, everything else non-candidate: level 10 → all six become 15,
  **12** draws (2 per attempt), **0** star draws; level 11 → six cells 15/16 by each `(0,1)` result (0 → 16,
  1 → 15), **18** draws; level 10 with a state-1 piranha on one candidate cell → squished n = 1 (+200) and its
  group-3 stars add **4** draws (interior cell, no clip) → **16** total; `_RegenerateBlocks` itself emits no star
  group).
- [ ] **7b.3 Verify:** gate in the T7a/7b lane worktree → **72**; after the orchestrator merges W6 → **84**;
  0 failed/skipped.
- [ ] **7b.4 Commit:** `BubbleTrouble/Core: bonus bubbles, EXTRA, time bonus, regenerate (6 tests)`.

### Task 8 — Blocks in motion and jewel joining — ⚑ MAJOR (lane A of W7, parallel with Tasks 9a–9c)

**Files:** `Sources/BubbleTroubleCore/Sim/MoveBlock.swift`, `Sim/ProcessBlocks.swift`, `Sim/Jewels.swift`
(`_CheckJewelMovement`, `_Jewels_GiveBonus`), `Sim/RubberBlocks.swift` (`_Blocks_DeactivateRubberBlocks`);
`Tests/BubbleTroubleCoreTests/BlocksTests.swift`.

- [ ] **8.1** Contracts: `moveBlock(_ slot: Int)`, `processBlocks()`, `checkJewelMovement(_ slot: Int, col:row:)`,
  `jewelsGiveBonus()`, `blocksDeactivateRubberBlocks()` (Research notes 36–39).
- [ ] **8.2 Tests (13)** — `BlocksTests`:
  `testPushedBubbleSlides10px` (4 calls per cell; stops and rewrites the maze at the first obstacle);
  `testBounceCounts` (B11, `_MoveBlock @ 0001cccb`: `bounces` (`+0x2e`) increments at the end of each 4-step squash;
  a **blue** block reverses at its first obstacle (bounces 1) and **retires when bounces reaches 2** (at the second
  obstacle, after that squash); **purple retires when bounces reaches 3**; squash frames per direction as note 36);
  `testBlockBlockReversal` (two moving blocks overlapping → both reverse once per frame, sound-free);
  `testSquishCountChains` (one block through three enemies → 200, 400, 800 and a multiplier step; plus Invariant 7's
  `_WasEnemySquished` case: a second moving block that, in the same frame, overlaps the enemy the first block just
  squished (dead, not yet freed) gets that slot back — its count advances to 1 with no score, so its next real
  squish scores 400, not 200);
  `testMovingBlockCatchesHero` (block rect inset 4 vs the plain hero rect → `heroCaught(2)`);
  `testEggBlockTimeline` (laid at L: state 4 at L+50, popping cell at L+66, empty at L+74);
  `testPopClearsCellAfter8`; `testDynamiteSlidesThenExplodes` (explodes on the stop frame);
  `testFuseExplodesAt61` (static fuse at f explodes on frame f+61); `testJewelJoinPartial` (second of three
  jewels joins → cluster + starfish added only when active < max); `testJewelBonusValues` (levels 1–6 →
  5000…10000; border target → 1000; capture-all follows); `testMovingJewelBecomesBubble` (TimeBonus 0 → type 10);
  `testRubberBlocksDeactivate` (a moving blue block mid-cell is written into the maze at its col/row).
- [ ] **8.3 Verify:** gate in the T8 lane worktree → **97** (84 + 13); after the orchestrator merges W7 → **110**;
  0 failed/skipped.
- [ ] **8.4 Commit:** `BubbleTrouble/Core: moving blocks, egg/fuse/pop timers, jewel joining (13 tests)`.

### Tasks 9a–9c — Enemies (lane B of W7, parallel with Task 8; 9a → 9b → 9c in one lane)

Split from the original Task 9 at review (B3). The five folded functions are read from `otool -tV`
(`enemies-ai.md` header lists the jump sites). **Seam rule** (the call graph runs 9a → 9b → 9c: `_ProcessEnemies`
calls `_EnemyAI`; the AI calls the actions): an earlier sub-task creates the later sub-task's callee with the body
`preconditionFailure("Task 9b")` / `preconditionFailure("Task 9c")`, its tests are built never to reach a seam, and
the later sub-task replaces the body. Never a silent stub (`return false`). Task 9c's verify proves none remain.

#### Task 9a — Spawn, eggs, `_ProcessEnemies`, animation — ⚑ MAJOR

**Files:** `Sources/BubbleTroubleCore/Sim/EnemySpawn.swift` (`_CheckNewEnemies` + folded `_NewEnemy`),
`Sim/EnemyProcess.swift` (`_ProcessEnemies` incl. the per-type animation cycles, `_CorrectEnemyAligned`),
`Sim/EnemyAI.swift` (seam: `enemyAI(_:)` only, body `preconditionFailure("Task 9b")`);
`Tests/BubbleTroubleCoreTests/EnemySpawnTests.swift`.

- [ ] **9a.1** Contracts: `checkNewEnemies()`, `processEnemies()`, `correctEnemyAligned(_ slot: Int)` (Research notes
  29–30; order within one slot: squish-on-entry **before** the catch test — note 30).
- [ ] **9a.2 Tests (4)** — `EnemySpawnTests`:
  `testNewEnemyScanAndDraws` (B12: `testWorld` whose only normal bubbles are (3,2), (12,7), (0,10); seed **42**;
  pool `[4,0,0,0,0,0]` → `(0,15)` = 12, `(0,10)` = 7, `(1,4)` = 2, then `(0,5)` = 5 (rejected, pool[5] = 0) and
  `(0,5)` = 0 (accepted) → **5** draws = 4 + k with **k = 1**, where k = the number of rejected `(0,5)` draws; the
  scan starts at (13,7) — the start cell (12,7) is tested last — so the egg is laid at **(0,10)**, dir 2, piranha,
  maze 0x3c, egg block in block slot 0, enemy slot 0, `numNormalBlocks` 100 → 99, `numEnemiesActive` 1 [Python,
  QuickDraw LCG]); `testPoolFallbackWord18` (all-zero pool → piranha); `testEggToHatchTimeline` (laid at L: state 3
  at L+11, hatch at L+72; the post-hatch flag clears on the L+88 call (`+0x44` reaches 16), so the first
  `enemyAI` call is due at L+89 — the test stops at L+88 and never reaches the seam);
  `testSquishOnEntryAndSameFrameCatch` (post-hatch flag set so no AI runs: enemy entering a resting bubble while
  overlapping the hero → squished (200) and `heroCaught(1)` in the same call, squish draws before the catch's
  `(0,1)` — C10).
- [ ] **9a.3 Verify:** gate in the T9a–9c lane worktree → **88** (84 + 4), 0 failed/skipped.
- [ ] **9a.4 Commit:** `BubbleTrouble/Core: enemy spawn, eggs, ProcessEnemies (4 tests)`.

#### Task 9b — `_EnemyAI`, movement, random walk, homing — ⚑ MAJOR

**Files:** `Sim/EnemyAI.swift` (replace the seam: `_EnemyAI`, `_FigureEnemyMove`, `_FigureEnemyRandomness`,
`_CanDoNormalPop`, `_CanDoNormalOtherPop`, `_EnemyCheckBurstingBubble`), `Sim/EnemyMove.swift` (folded `_MoveEnemy`,
`_MoveEnemyRandomly`, `_CorrectEnemyMazeX/Y`, `_TryAndTurnEnemy`, `_CheckUp/Down/Left/Right`),
`Sim/EnemyActions.swift` (seams: `tryRemoveGo`, `tryEnemyPushBlock`, `tryEnemyCreateBalloon`, `toastBubble`, bodies
`preconditionFailure("Task 9c")`); `Tests/BubbleTroubleCoreTests/EnemyAITests.swift`.

- [ ] **9b.1** Contracts: `enemyAI(_ slot: Int)`, `figureEnemyMove(_ slot: Int)`, `figureEnemyRandomness(_ slot: Int)
  -> Int`, `canDoNormalPop(_:) -> Bool`, `canDoNormalOtherPop(_:) -> Bool`, `moveEnemy(_ slot: Int)`,
  `moveEnemyRandomly(_ slot: Int)` (incl. the repeated pending-action dispatch and the stuck/`_ToastBubble` fallback —
  note 32, `enemies-ai.md` §4c), `tryAndTurnEnemy(_ slot: Int, _ dir: Direction) -> Bool`. Homing with old dir 0 →
  `pendingStops.insert(.originalWouldAbort("LocationErrorInt 0x7d8/1"))` and leave the enemy unmoved (C11).
- [ ] **9b.2 Tests (6)** — `EnemyAITests` (Research notes 31–32):
  `testSpeedTables` (piranha 2 / 4; eel 2 / 4 / 8; shark sequence over 13 aligned steps 2,4,4,2,2,4,4,2,2,4,8,4,2;
  starfish 4,4,4,8,8,8,4,2 with bonus > 0); `testRandomnessR` (16 frames after hatch: piranha 38, eel 8, shark 12,
  starfish at level 12 → 36; 600 frames: piranha 2); `testHomingTable` (r forced to 1, piranha so no balloon/push
  path, primary direction open: the nine (dy,dx) sign cases give the table's (p, s); tie cases draw one extra
  `(1,2)`); `testMoveEnemyRandomlyDraws16` (B12: seed **1**, piranha 16 frames after hatch (r = 38), aligned at an
  open junction, old dir 3, no pending action: roll `(1,38)` = **10** ≠ 1 with bonus > 0 → random walk; swap pairs
  (a,b) = (0,2),(0,2),(3,2),(0,0),(0,2),(0,0),(3,3),(0,0) → order **[2,4,3,1]** → new dir **2**; **17** draws total
  [Python, QuickDraw LCG]); `testCanDoNormalPopCooldown` (false at `lastPop + 120`, true at `+121`);
  `testHomingWithOldDirZeroStops` (C11 → `.originalWouldAbort`).
- [ ] **9b.3 Verify:** gate in the T9a–9c lane worktree → **94**, 0 failed/skipped.
- [ ] **9b.4 Commit:** `BubbleTrouble/Core: enemy AI, movement, random walk, homing (6 tests)`.

#### Task 9c — Enemy actions — ⚑ MAJOR

**Files:** `Sim/EnemyActions.swift` (replace the seams: `_TryRemoveGo`, `_TryEnemyPushBlock`,
`_TryEnemyCreateBalloon`, `_ToastBubble`); `Tests/BubbleTroubleCoreTests/EnemyActionTests.swift`.

- [ ] **9c.1** Contracts: `tryRemoveGo(_:_:) -> Bool`, `tryEnemyPushBlock(_:_:) -> Bool`,
  `tryEnemyCreateBalloon(_:_:) -> Bool`, `toastBubble(_:)` (Research note 33, `enemies-ai.md` §4e).
- [ ] **9c.2 Tests (3)** — `EnemyActionTests`:
  `testToastBubbleNeverRight` (bubbles only to the right → none popped, dir 1, paused); `testActionWaits` (level 1:
  pop after 39 waiting frames, push 68, shark balloon 67; starfish 10); `testEnemyPushNeedsNormalThenEmptyOrF` (B8,
  `_TryEnemyPushBlock @ 000131fd`: normal bubble then empty → pushes after the wait; normal then 'F' → pushes;
  normal then 'P', blue then empty, dynamite then empty → 0, never waits; enemy at row 1 facing up, row 9 facing
  down, col 1 facing left, col 14 facing right → 0 before any maze read).
- [ ] **9c.3 Verify:** gate in the T9a–9c lane worktree → **97**; `grep -rn 'preconditionFailure("Task 9'
  "$WT/BubbleTrouble/Core/Sources"` → no output; after the orchestrator merges W7 → **110**; 0 failed/skipped.
- [ ] **9c.4 Commit:** `BubbleTrouble/Core: enemy pop/push/balloon actions and ToastBubble (3 tests)`.

### Task 10 — The frame step and end conditions — ⚑ MAJOR

**Files:** `Sources/BubbleTroubleCore/Sim/FrameStep.swift`; `Tests/BubbleTroubleCoreTests/FrameStepTests.swift`.

- [ ] **10.1** Contracts:
```swift
public struct FrameReport: Equatable, Sendable {
    public let frame: UInt16, drawsThisFrame: Int, totalDraws: Int, samplesConsumed: Int
    public let heroState: Int16, heroCell: CellRef, score: Int32, lives: Int16
    public let heroCaughtThisFrame: Bool, stops: Set<StopReason>
}
extension GameState {
    /// One _PlayGame loop iteration, in Research note 19's order. Returns the report; `playing` turns false
    /// when any stop fired (it takes effect before the next call).
    public mutating func stepFrame<I: InputSource>(input: inout I) -> FrameReport
}
```
- [ ] **10.2 Tests (6)** — `FrameStepTests` (data-gated where FILM 1 is used; Research notes 19–22):
  `testFilm1Checkpoints` (total draws 191 / 192 / 192 / 192 / 192 / 198 / 208 / 208 / 209 at the end of frames
  30 / 31 / 70 / 71 / 81 / 82 / 83 / 116 / 117; hero state 2 first at frame 71; samples consumed 0 at frame 70,
  1 at 71, 12 at 82; time bonus 2500 at 100, 2450 at 101); `testFilm1EggTimeline` (egg slot 0 at (0,6) dir 2
  piranha on frame 82; slot 1 at (11,6) dir 1 on frame 83; enemy 0 state 3 at 93, hatched at 154; its egg cell
  40 at 148, 0 at 156); `testStopReasonsSameFrame` (synthetic: count exhausted on the level-complete stop frame →
  both reasons reported); `testNormalBlockSentinel` (100 until frame 1's recount, then the real count; reaching 0
  awards 2000 ×mult and sets squished = total); `testLevelCompleteStopsAtPlus71` (last enemy squished at frame E
  → stop reported on frame E+71, not earlier); `testDemoDeathStopsAtPlus97` (caught at frame C → state 4 at
  C+31, stop on frame C+97; no sample consumed after C−1 when the catch came from `_ProcessEnemies`).
- [ ] **10.3 Verify:** gate → **116** (from the W7 merge head), 0 failed/skipped. If `testFilm1Checkpoints` fails,
  STOP and run the Diagnosis protocol — do not touch the expectations.
- [ ] **10.4 Commit:** `BubbleTrouble/Core: PlayGame frame step and stop conditions (6 tests)`.

### Task 11 — FILM replay harness, `btx-replay`, acceptance, golden freeze — ⚑ MAJOR

**Files:** `Sources/BubbleTroubleCore/Replay/FilmReplay.swift`, `Sources/btx-replay/main.swift`;
`Tests/BubbleTroubleCoreTests/FilmReplayTests.swift`.

- [ ] **11.1** Contracts:
```swift
public struct FilmReplayResult: Equatable, Sendable {
    public let filmID: Int, level: Int, count: Int, frames: Int, samplesConsumed: Int, totalDraws: Int
    public let score: Int32, lives: Int16, stops: Set<StopReason>, firstCatchFrame: Int?
    public let levelCompletedFrame: Int?                   // gEndOfLevelTime if gIsEndOfLevel was set (A10)
    public let reports: [FrameReport]?                     // filled when tracing
    public var accepted: Bool                              // Invariant 14 + brief bar (b)
    public var flagged: Bool                               // accepted && levelCompletedFrame != nil (ruling)
}
public enum FilmReplay {
    public static func run(filmID: Int, files: BTXResourceFiles, config: SessionConfig = SessionConfig(),
                           trace: Bool = false, maxFrames: Int = 65_535) throws -> FilmReplayResult
}
```
  `accepted` ⇔ `stops.contains(.countExhausted) && samplesConsumed == count && (firstCatchFrame == nil ||
  firstCatchFrame == frames)` and `stops` holds no `.originalWouldAbort`; a `.levelCompleted` stop can only
  appear on the final frame (by construction — assert it). `flagged` ⇔ accepted and the level completed at all
  (necessarily within the final 70 frames — Invariant 14 ruling); a flagged FILM still counts toward `ACCEPT n/4`.
  `btx-replay` usage: `btx-replay [--data DIR] [--trace FILM] [--rng-variant qd|qd-no8000]`; data from `--data`
  or `HECTORKIT_DATA_BTX`; prints:
```
film  level  count  frames  samples  draws  score  lives  end                 first-catch
1     1      1118   <n>     1118     <n>    <n>    <n>    count               -
…
ACCEPT 4/4
```
  (end = the reasons, comma-separated: `count`, `death`, `level`, `abort:<msg>`; `level` is printed whenever the
  level completed, even if its +70 stop had not fired, and such a row ends with ` FLAG`; when any row is flagged a
  line `FLAGGED: film <n> level completed at frame <E>, count exhausted at frame <F>` follows `ACCEPT`, for the
  orchestrator's gate message to Ben); exit 0 iff 4/4 accepted (flags do not change the exit code). `--trace N`
  prints one line per frame: `frame=<n> draws=<this> total=<n> sample=<consumed> hero=<state>@<col>,<row>
  score=<n> enemies=<active>` then the summary row.
- [ ] **11.2 Tests (2, then 3)** — `FilmReplayTests` (data-gated): `testAllFourFilmsEndByCountExhaustion`
  (per FILM: accepted; samplesConsumed == 1118 / 846 / 943 / 890; prints the result row in the failure message);
  `testReplayIsDeterministic` (two runs per FILM with `trace: true` → identical `reports`).
- [ ] **11.3 Verify:** gate → **118**, 0 failed/skipped; the replay command prints 4 rows + `ACCEPT 4/4`, exit 0
  (any `FLAG` row is reported to the orchestrator verbatim — it is a pass to be named at Ben's gate, not a STOP).
  Also run the suite **without** the env var and record the counts in the commit message (G3 before the golden:
  **100** passed, **18** skipped, 0 failed). If any FILM is not accepted: STOP, run the
  Diagnosis protocol, report DONE_WITH_CONCERNS with the table and the trace of the first anomaly — never adjust
  the simulation to force acceptance without a decompile citation.
- [ ] **11.4 Commit:** `BubbleTrouble/Core: FILM replay harness + btx-replay; FILMs 1–4 end by count exhaustion (2 tests)`.
- [ ] **11.5 Golden freeze (after a Fable plausibility review of the table and one trace):** add
  `testGoldenReplayNumbers` asserting each FILM's `(frames, score, lives, totalDraws, end string)` exactly as
  printed (A11: the total RNG draws per FILM are frozen too — the most sensitive desync detector), with the comment
  `// Self-derived 2026-10-xx by this replica after Fable review; NOT bank-derived — the bank has no FILM end
  state (replay-oracle.md §6). Change only with a decompile-cited fix.` Gate → **119**; without the env var
  **100** passed / **19** skipped (G3).
  Commit: `BubbleTrouble/Core: freeze self-derived FILM replay goldens (1 test)`.

### Task 12 — Bank corrections (docs only; lane 3 of W2, in its own worktree)

**Files:** `docs/bubble-trouble/replay-oracle.md`, `engine-loop.md`, `hero-and-input.md`, `enemies-ai.md`,
`bubbles-items-scoring.md`, `INDEX.md` (append only; never edit existing text).

- [ ] **12.1** For each item in §"Bank corrections to append", re-read the cited decompile/disasm lines yourself,
  then append a numbered subsection (or a `⚑ corrected (plan 2026-10-03 btx-core)` paragraph at the end of the
  cited section) with `name @ addr`, the quoted line(s), the command, and a label; add one line per item to
  `INDEX.md` (review-ledger style list "Plan 2026-10-03 btx-core corrections"); update NR-7 in place only by
  appending "→ RESOLVED by C11 (…)" to its line, and NR-6 only by appending "→ narrowed by C12 (…)".
- [ ] **12.2 Verify:** in the T12 lane worktree (which holds no other lane's work), `git diff --stat` shows only
  those six files; `grep -c '⚑ corrected (plan 2026-10-03 btx-core)' docs/bubble-trouble/*.md` totals ≥ 12.
- [ ] **12.3 Commit:** `docs(bubble-trouble): append plan-time bank corrections C1–C12 with evidence`.

---

## Execution order

Harden first (data and RNG proven against census numbers before any simulation), then march; the long run (FILM
replay) comes last so it qualifies the work instead of rediscovering catalogued issues.

| wave | lanes (each lane = its own worktree; `→` = sequential inside the lane) | gate per lane | gate at the merge head |
|---|---|---|---|
| W1 | T0 | 4 | 4 |
| W2 | T1 ∥ T2 ∥ T12 | 11 / 15 / — (docs) | 22 |
| W3 | T3a → T3b | 29 → 38 | 38 |
| W4 | T4 | 44 | 44 |
| W5 | T5a → T5b | 49 → 60 | 60 |
| W6 | T6 ∥ (T7a → T7b) | 72 / 66 → 72 | 84 |
| W7 | T8 ∥ (T9a → T9b → T9c) | 97 / 88 → 94 → 97 | 110 |
| W8 | T10 | 116 | 116 |
| W9 | T11 (+ golden after review) | 118 → 119 | 119 |

**Lane isolation (orchestrator ruling, 2026-10-03): parallel lanes NEVER share a worktree.**
- The orchestrator creates each parallel lane's git worktree, branched from the integration branch head at the start
  of the wave, under `.claude/worktrees/` (so `BubbleTrouble/Core/../../../HectorKit` resolves through the existing
  `.claude/worktrees/HectorKit` symlink — Task 0.1 checks it per worktree). Each lane therefore has its own
  `BubbleTrouble/Core/.build`, and its implementer writes logs and traces only under **its own session scratchpad**
  (`$SCRATCH/btx-test.log`, `$SCRATCH/btx-build.log`, `$SCRATCH/film-N.trace`) — never `/tmp/btx-test.log` or any
  shared path. Single-lane waves may run in the integration worktree or a fresh lane worktree (orchestrator's call).
- Sub-tasks joined by `→` run in order in one lane and commit in order on that lane's branch.
- Lane file sets are disjoint: W2 `Random/` vs `Data/` + loader tests vs `docs/bubble-trouble/`; W6 `Sim/Input.swift`,
  `Sim/Hero.swift` vs `Sim/Balloons|Bonus|Extra|TimeBonus|Regenerate.swift`; W7 `Sim/MoveBlock|ProcessBlocks|Jewels|
  RubberBlocks.swift` vs `Sim/Enemy*.swift` — each with its own test files.
- The orchestrator merges lanes in wave order (within a wave, in the order listed: T1, T2, T12; T6, then T7a–7b;
  T8, then T9a–9c), runs the **full** gate from the merge head (the "merge head" column), and only then opens the next wave.
  Task 12's `git diff --stat` audit therefore sees only its own files.
- Shared files: `Sim/Entities.swift` / `Sim/GameState.swift` are read-only to parallel lanes. If a lane needs a
  missing stored field it adds it in its own one-line commit (`BubbleTrouble/Core: add <field> to <type> (lane T<n>)`)
  and names it in its hand-back; if both lanes of a wave touched those files the orchestrator resolves the merge
  (keeping both additions) before running the merge-head gate.

---

## Diagnosis protocol for a diverging FILM

Symptom: a FILM ends by `death` (or `level`, or `abort`) before its samples run out, or a checkpoint test fails.

1. **Get the first anomaly frame.** `"$(swift build --show-bin-path)/btx-replay" --trace N > "$SCRATCH/film-N.trace"`. Note the catch frame C and the
   sample index at C. Desyncs usually start tens to hundreds of frames earlier.
2. **Check the deterministic prefix.** For FILM 1, frames 1–117 have planner-computed draw totals (Research note
   22). A mismatch there localises the bug to level build (Task 4), the air-bubble launcher, egg spawning, or the
   LCG. Re-derive the expected numbers by hand from the cited functions before suspecting either side.
3. **Plausibility probes on the trace** (cheap, no oracle needed): (a) at FILM 1 sample 212 (first push) the hero
   should be aligned and facing an object — a push into empty water means the hero's position already drifted
   (input/movement bug, not RNG); (b) count samples where a held direction moved the hero into a wall vs. into
   water — a human recording turns at junctions; a sudden run of wall-bumps marks the desync frame; (c) eggs must
   appear only in former normal-bubble cells.
4. **Suspects, in order** (stop at the first that explains the anomaly; every fix cites the decompile):
   1. **The LCG** — `QuickDrawRandom.step` (multiplier, modulus, low-word extraction), the 0x8000→0 adjustment
      (try `--rng-variant qd-no8000`; if that variant reaches count exhaustion and the default does not, report
      it — NR-3 evidence — do not silently switch), and seed installation (FILM+4 as written by
      `SetQDGlobalsRandomSeed`; first `Random()` uses it).
   2. **Star pre-draw clip and group sizes** — clip before the `(0,1)`; group 0xe = 14 stars; groups 3/4/5 at the
      enemy's **cell** origin, not its rect; no death bubbles after a kind-2 catch (`+0x4a` cleared).
   3. **Sample consumption rule** — state 2 only; push freeze 3/6 calls; trap and trap-release frame; first
      appearance 70 frames (state 2 on frame 71).
   4. **Slot order and free timing** — first-free allocation everywhere; frees only in the draw pass; enemy slot
      reuse the frame after death; the `gNumNormalBlocks = 100` sentinel.
   5. **Enemy AI tie-breaks** — signed dx/dy compares (no abs), the `(1,2)` tie draws, `_MoveEnemyRandomly`'s 16
      draws and swap order `swap(order[b], order[a])`, `_ToastBubble` order (up, down, left), CanDoNormalPop's
      120-frame window, action waits, shark speed counter.
   6. **Air-bubble lifetime** — death at bottom < 0, delayed bubbles (groups 9/10/0xb) frozen and not advancing
      drift, vertical-speed clamps by size, the 8-cap check before the draw.
   7. **Frame order** — `_CheckNewEnemies` at the loop top (before `_Bubbles`), enemies before hero, blocks after
      both, end checks after the draw pass; inside a slot, squish-on-entry before the catch; inside `_ProcessHero`,
      the push check before `_MoveHeroAligned`'s turn draw; `_WasEnemySquished`'s missing dead-flag test.
   8. **Hero movement** — priority, reversal, speed 5, `_GetNextObject` passability {0, 'P'}.
   9. **Assumptions** — prefs ON, registration (RNG-moot for levels 1–4), latches (moot below 9/13).
   10. **NR-10** — the FILM may come from another engine build: only after 1–9 are exhausted, and only Ben can
       close it (watch the original's demo).
5. Record the root cause, the fix, and its decompile citation in the commit; append a bank correction if the bank
   was wrong.

---

## Bank corrections to append (Task 12; evidence re-checked at append time)

| # | file § | bank says | decompile/disasm says | label |
|---|---|---|---|---|
| C1 | `replay-oracle.md` §4.5; `hero-and-input.md` §5; `bubbles-items-scoring.md` §4 | `_HeroCaught` "can be called up to three times in one frame by a large blast"; hero killed "once per rect that hits" | `_IsHeroCaught @ 00021c79` returns 0 unless `*(short *)(hero + 2) == 2`; `_HeroCaught @ 00021dfa` begins `*(undefined2 *)(hero + 2) = 3;`; all three callers (`_CheckForBombKills`, `_ProcessEnemies`, `_MoveBlock`) gate on `_IsHeroCaught` (`find_func.py '_HeroCaught\('` → 4 blocks). ⇒ at most one `_HeroCaught` (one `(0,1)`, one group 0xe) per catch | HIGH |
| C2 | `replay-oracle.md` §4.2; REVIEW finding 1 | group 0xe (hero squash) = 13 stars | case 0xe has 13 explicit `_NewStar` calls then `break` to the shared tail `LAB_00004af8: _NewStar(iVar12, iVar8, uVar13, uVar14, uVar15, uVar16)` with `iVar12 = x + 10, iVar8 = y − 2` ⇒ **14** stars (two at (x+10, y−2)). `otool -tV` count of `calll _NewStar` in `_NewStarGroup` = 83 = 82 explicit + 1 tail | HIGH |
| C3 | `replay-oracle.md` §4.1 | type-0xb draws from "star groups 3/4/5 … 0xb–0xe incl. hero squash" | callers of `_NewStarGroup` (`otool` group immediates): 3/4/5 (`_SquishEnemy`, `_KillEggBlock`), 0xe (`_HeroCaught`), 0/2 (`_PlayGame`, jewels, `_Bonus_Pop`), 0xf/0x10 (`_ExplodeBombBlock`), 6–9 (`_ProcessHero` speed-up, dead), 10 (`_PauseGame`). Groups **1, 0xb, 0xc, 0xd have no callers** | HIGH |
| C4 | `bubbles-items-scoring.md` §5 | collision box "grows to the full balloon over the first few frames" [MED] | `_Balloons_Process` 0002449f `cmpw $0x1,-0x5(%ebx); jg` — growth runs only while the sprite frame ≤ 1; on the 3rd flying call frame → 2 and the box becomes (top+8, left+8, top+31, left+26); the frame-3 (0002451b) and frame-4 (00024544) arms are unreachable from the flying path | HIGH |
| C5 | `bubbles-items-scoring.md` §1 step 3 | moving block pops "flying/holding balloons overlapping" | `_Balloons_CheckSquishes @ 00023ae8` tests `*pcVar2 == '\x01'` (flying only); a held enemy's balloon pops via `_WasEnemySquished @ 00010eca` (`if (state == 6) _Balloons_PopBalloon(enemy + 0x43)`); a balloon holding the hero is never popped by a block | HIGH |
| C6 | `engine-loop.md` §4/§5 | (omitted) | `_ResetBlocks @ 0001b90e`: `*(undefined2 *)gNumNormalBlocks = 100;` — the sentinel that lets frame 1's recount run (`if (0 < gNumNormalBlocks) { recount }`) | HIGH |
| C7 | `bubbles-items-scoring.md` §11 | "a bubble dies when it rises above y 0" | `_Bubbles_Process @ 00016b1a`: `if (*(short *)(pcVar11 + 0xe) < 0) pcVar11[0x21] = 1;` — dead when the rect **bottom** < 0; delayed bubbles (`+0x22`, groups 9/10/0xb) skip movement **and** the drift-index advance until `delay + start < frame` | HIGH |
| C8 | `bubbles-items-scoring.md` §6; `enemies-ai.md` §5 | `_Bonus_SetNumEnemySquishes` called "on n ≥ 3 (and 0)" | `_SquishEnemy` calls it with n for n ≥ 3 and n ≤ 0, but `_Bonus_SetNumEnemySquishes @ 0001a818` starts `if (param_1 < 3) { …AtOnce = 0; return; }` — n ≤ 2 never steps | HIGH |
| C9 | `replay-oracle.md` §3; `engine-loop.md` §4 | "the hero's first appearance takes 70 frames" | `stateStart (0) + 0x46 < frame` ⇒ state 2 on **frame 71**; `hero.stateStart (71) + 10 < frame` ⇒ first `_CheckNewEnemies` on **frame 82** | HIGH (arithmetic) |
| C10 | `enemies-ai.md` §3 | squish-on-entry, then "Finally, state 1 only: … `_HeroCaught(1)`" | the catch test (`if (bVar14 && hero.state == 2 && _IsHeroCaught(...) && state != 4)`) does not test the dead flag `+0x47`, and `bVar14` is set from the state at the top of the iteration ⇒ an enemy squished on entry can still catch the hero in the same call | HIGH |
| C11 | `enemies-ai.md` §4d; `INDEX.md` NR-7 | old dir 0 → `back` uninitialised, outcome unknown | `_LocationErrorInt(0x7d8,1)` (disasm 00013e3a) → `_DoLocationError @ 00014511` → `_StopAlert(0x232c)`; `_CleanUp()` → … `_ExitToShell()` — **the original quits**; `back` is never used. NR-7 → RESOLVED | HIGH |
| C12 | `INDEX.md` NR-6; `bubbles-items-scoring.md` §5 | `_PopEnemy(-1)` / `_ReleaseEnemyFromBalloon(-1)` after a hero balloon: "effect unknown" (both treated as live paths) | `_Balloons_CaptureHero @ 00023cbb` sets the balloon state 2, start = h, holder `0xff`, hero `+0x4c = 1`, `+0x4e = h`; `_ProcessHero` clears `+0x4c` when `+0x4e + 0x5a < frame` (h+91, state 2 only); later that frame `_Balloons_Process @ 00024394` state 2 tests `(hero[0x4c] == 0) && _RectsCollide(box, hero rect)` → `_Balloons_PopBalloon; _PopEnemy(-1)`, before its `level+0x20` (w16 ≥ 120) release test → `_ReleaseEnemyFromBalloon(-1)` is unreachable while the hero stays in state 2. Residual path [derived]: an enemy catches the hero in `_ProcessEnemies` on exactly frame h+91 (before `_ProcessHero` clears the trap) at a w16 = 120 level (L16–50) → release at h+121, one frame before state 4's `_MakeAllEnemiesDisappear` → `_Balloons_PopAll` (h+122). Never in levels 1–4 (w16 ≥ 140). Replica: both calls with holder −1 are no-ops | HIGH (code path); MED (residual-path arithmetic) |

Note for INDEX (not a correction): registration is RNG-neutral for levels 1–4 (Research note 6), so FILMs 1–4
cannot discriminate Decision 2.

---

## Pre-execution self-audit

Run against the bank and the decompile on 2026-10-03; outcomes inline.

1. **Every `_GetRandomFast` site has a home** (61 call sites in 27 functions incl. the folded `_NewEnemy` /
   `_MoveEnemyRandomly` — REVIEW "Verified OK"; re-grepped in the decompile 2026-10-03):
   `_LoadLevel` → T4; `_PositionSingleJewel` → T4; `_Bubbles_CreateRandomLUT` → T3b (reset) called by T4;
   `_CreateStarRandomLocLookupTable` → T3a; `_InitPoints` → T3b; `_Bonus_Init` → T4; `_CheckNewEnemies`/`_NewEnemy`
   → T9a; `_ProcessEnemies (1,30)` → T9a (cracked path: modelled as not taken, licence valid); `_FigureEnemyMove`
   incl. folded `_MoveEnemyRandomly` → T9b; `_MoveHeroAligned`, `_MoveHeroNotAligned`, `_ProcessHero (0,1)` → T6;
   `_ProcessHero (0,30)` → T6 (cracked path, not taken); `_HeroCaught` → T5a; `_CrushBlock (0,40)` → T5b (cracked,
   not taken); `_RegenerateBlocks` → T7b; `_Balloons_New`, `_Balloons_CaptureAllEnemies` → T7a; `_Bubbles_New` → T3b;
   `_NewStar` → T3a; `_DrawPointsToComp` → T3b; `_PlayGame (0,20)` → deferred (end-of-level blacklist, play-mode
   transition); `_Get0To6`/`_Get13To22` → T1 (latches); `_CheckHiScore`, `_HandleMSMouse`, `_ProcessMenuStars` →
   out of scope (menus). ✅ ok — every sim site has a task; the three cracked-licence sites are explicitly not
   taken under Invariant 11.
2. **Every LEVL word is consumed or deliberately not** — table in Research note 9. ✅ ok.
3. **Every timing constant has a test:** 70 (T10 checkpoints); death 30/65 (`testDemoDeathStopsAtPlus97`); egg
   10/50/15/9 (T8/T9a); fuse 60/30 (T5b/T8); trap 90 (T6); invisibility 300/210 (T6); time bonus 31 (T7b/T10);
   balloon w15/w16 (T7a); stars 40/15 calls (T3a); points 31 (T3b); splats 7 (T3b); end +70 (T10); pop cooldown 120
   (T9b); action waits (T9c). ✅→FIXED: the
   play-mode-only 60 (later appearances) and 95 (game over) are implemented in T10 but have no test in this plan;
   recorded here and covered by the BTX play-loop plan (Scope, deferred) — they cannot occur in a demo.
4. **The bank's "first appearance 70 frames" vs the strict `>`** — the plan uses frame 71 (C9). ✅→FIXED (added C9).
5. **Group 0xe star count** — the bank and review say 13; the decompile and disasm count say 14. ✅→FIXED (Research
   note 47, `testGroup0xEHasFourteenStars`, C2).
6. **`_HeroCaught` multiplicity** — the bank says up to three per blast; the code says one. ✅→FIXED (C1,
   `testHeroCaughtOncePerFrame`).
7. **HectorResources API exists as cited** — `ResourceReader.read(fileAt:)` (line 23), `resource(type:id:)`
   (34), `resources(of:)` (33); `ByteReader` is internal. ✅→FIXED (Invariant 12, own `BigEndian.swift`).
8. **`Sendable` across the module boundary** — `Resource`/`ResourceCollection` are not `Sendable`. ✅→FIXED
   (Invariant 13; `BTXResourceFiles` converts eagerly).
9. **No dependency on the concurrent HectorKit decoder lane** — the core imports HectorResources only; no cicn/
   ppat/snd anywhere. ✅ ok (Invariant 1, Package.swift).
10. **Data gating** — every real-data test goes through `BTXTestData`; T0 proves the skip message names the
    variable. ✅ ok.
11. **Parallel lanes are file-disjoint and worktree-isolated** — W2, W6, W7 file lists checked; all stored fields
    live in T4's files; each parallel lane runs in its own worktree with its own `.build` and scratchpad logs, merged
    by the orchestrator in wave order (orchestrator ruling). ✅→FIXED at review (A1: the draft let lanes share one
    worktree, `.build` and `/tmp/btx-test.log`).
12. **Planner-computed numbers reproducible** — draw checkpoints, jewels, bonus, FILM 1 frames 30–117 and egg
    timeline re-run in Python twice from the extracted resources. ✅ ok; flagged self-derived everywhere.
13. **The NR-7 path** — previously "unknown"; resolved as an abort. ✅→FIXED (C11, `StopReason.originalWouldAbort`,
    `testHomingWithOldDirZeroStops`).
14. **Air-bubble death edge** — bank "above y 0" is ambiguous; code uses bottom < 0. ✅→FIXED (C7, test).
15. **Stop semantics with a catch on the final frame** — a FILM recorded until a death ends by count exhaustion
    at the last state-2 frame; a block/blast catch after `_ProcessHero` on that frame is legitimate. ✅→FIXED
    (Invariant 14, `accepted` definition).
16. **Test-count arithmetic** — T0 4 + T1 7 + T2 11 + T3a 7 + T3b 9 + T4 6 + T5a 5 + T5b 11 + T6 12 + T7a 6 +
    T7b 6 + T8 13 + T9a 4 + T9b 6 + T9c 3 + T10 6 + T11 2 + golden 1 = **119** (draft 117 + review-added
    `testJewelTargetHelpers` (B1) and `testEnemyPushNeedsNormalThenEmptyOrF` (B8)). Data-gated: T0 1, T2 8, T4 5,
    T10 2, T11 3 = **19**; synthetic **100**. ✅ ok.
17. **Swift 6 strict concurrency** — the injected LCG step is `@Sendable`; all state is value types; no type that
    stores the closure (`GameRandom`, `SessionConfig`, `GameState`) claims synthesized `Equatable`. ✅→FIXED at review
    (A2: the draft's `SessionConfig: Equatable` would not compile).
18. **The brief's decomposition** (T0 skeleton … T8 harness) maps to T0–T11 here; T4–T6 of the brief were split
    by dependency (primitives / hero ∥ items / blocks ∥ enemies) to make waves 6–7 parallel and each task testable
    alone; review then split the four over-long tasks (T3 → 3a/3b, T5 → 5a/5b, T7 → 7a/7b, T9 → 9a/9b/9c) keeping
    the original numbers so other documents can cite them. ✅ ok (recorded here as the seat's ruling on
    decomposition).
19. **Bank-correction evidence is re-checked at append time**, not copied from this plan. ✅ ok (Task 12.1).

---

## Orchestration notes

- **Models:** every implementer Opus (repo CLAUDE.md; fable-kit `orchestrator.md` §6 — Opus-or-better for all
  subagents). Reviewers Fable.
- **Reviews:** MAJOR tasks (T1, T3a, T3b, T4, T5a, T5b, T6, T7a, T7b, T8, T9a, T9b, T9c, T10, T11 — 15) get two
  legs — spec-compliance (against this plan + the cited decompile functions) then quality; T0, T2, T12 get one leg. Reviewers report everything
  with confidence, no self-filtering. Review prompts pin the commit SHA under review and its parent.
- **Prompt scene-setting for each implementer:** this plan's Invariants + the Research notes for its task + the
  bank sections cited + the exact decompile functions to read (`find_func.py --func`), and the instruction to
  STOP on any numeric mismatch.
- **Waves:** 9 (18 implementer dispatches: T0, T1, T2, T12, T3a, T3b, T4, T5a, T5b, T6, T7a, T7b, T8, T9a, T9b,
  T9c, T10, T11 (+ its golden step); 33 review legs). Critical path T0 → T1 → T3a → T3b → T4 → T5a → T5b → T7a →
  T7b → T9a → T9b → T9c → T10 → T11 (T6 and T8 ride beside the longer lanes).
- **Lane isolation (orchestrator ruling):** parallel lanes NEVER share a worktree. The orchestrator creates one git
  worktree per parallel implementer under `.claude/worktrees/`, branched from the integration branch; each has its
  own `.build` and its own log path under that implementer's session scratchpad (never `/tmp/btx-test.log`). The
  orchestrator merges the lanes in wave order and runs the full suite from the merge head before opening the next
  wave; the merge-head counts are the STOP numbers (§Execution order). Implementer prompts state the lane's worktree
  path and `SCRATCH` explicitly.
- **FILM acceptance flag (orchestrator ruling):** a FILM whose level completed within the final 70 frames before
  count exhaustion is a pass, but `btx-replay` prints `end = count,level` with ` FLAG` and a `FLAGGED:` line, and
  the orchestrator's gate message to Ben names the FILM, the completion frame E and the exhaustion frame F.
- **Ben's gate list (never guessed by the seat):** (1) registration state (assumed registered-valid; RNG-neutral
  for FILMs 1–4); (2) whether the stars / air-bubbles prefs are exposed (assumed ON, not exposed); (3) NR-10 —
  watching the original's demo against ours once the shell exists; (4) the [LOW] QuickDraw `Random` reading
  (NR-3) if any FILM needs the no-0x8000 variant; (5) the editor stays last; (6) any FLAGGED FILM
  (`end = count,level`) — accepted by the machine bar, shown to Ben by name.
- **After T11:** STATE update, DECISIONS entry (seat rulings: module/file naming, harness format, task
  decomposition, test counts; assumptions of Invariant 11), handoff, and the next-session chip (the BTX shell
  plan) — orchestrator-owned.

---

## Review ledger

Two Fable-grade reviews, both ACCEPT_WITH_FIXES (2026-10-03): Reviewer A (RNG/data/level/frame/harness), Reviewer B
(hero/enemies/items). Every finding was applied; decompile/data facts were re-verified by the fix-pass editor
(commands: `find_func.py --func`, `otool -tV`, `rsrc_census.py --extract` + Python, Python QuickDraw LCG).

**Orchestrator rulings**
| # | ruling | landed in |
|---|---|---|
| R1 | Parallel lanes NEVER share a worktree: one git worktree per parallel implementer (created by the orchestrator from the integration branch, under `.claude/worktrees/`), own `.build`, own log path under its session scratchpad (never `/tmp/btx-test.log`); the orchestrator merges lanes in wave order and runs the full suite from the merge head; Task 12's diff audit sees only its own files | Paths block (`SCRATCH`); gate commands; Invariant 2; Task 0.1; per-task Verify lines (lane vs merge-head counts); Task 12.2; §Execution order (table + "Lane isolation"); Diagnosis step 1; Self-audit 11; Orchestration notes |
| R2 | A level completed within the final 70 frames before count exhaustion is a pass, FLAGGED as `end = count,level` in the harness output and in the gate message to Ben | G2; FILM-oracle paragraph (b); Known delta 9; Invariant 14; Task 11.1 (`levelCompletedFrame`, `flagged`, output format); Task 11.3; Orchestration notes (ruling + Ben's gate item 6) |

**Reviewer A**
| # | finding | resolution / where |
|---|---|---|
| A1 | parallel lanes shared one worktree/.build/log | R1 above |
| A2 | `SessionConfig: Equatable` holds an `@Sendable` closure — synthesized `==` will not compile | Task 4.1: `SessionConfig: Sendable` only, note to hand-write `==` over the non-closure fields if ever needed; Self-audit 17 |
| A3 | Task 3 too large | split into **3a** (stars, pre-draw clip, 14-star group 0xe; 7 tests) and **3b** (air bubbles, points, splats; 9 tests) |
| A4 | `testJewelWalkWidensAfter500` needed a no-files factory that arrived only in Task 5, and 3 jewels to terminate | factory contract `GameState.testWorld(maze:level:seed:jewelCount:…)` moved to Task 4 (`Sim/TestWorld.swift`, zero RNG draws); the test uses `jewelCount: 3` (4 would loop forever), expects 6 draws |
| A5 | G3 gave no numbers | G3: **100** synthetic pass / **19** data-gated skip (100 / 18 before the golden), recounted after the splits and the two added tests; per-task breakdown in Self-audit 16 |
| A6 | G2 "end = count" vs Invariant 14's "count,level" on the final frame | made consistent via R2 (G2, Invariant 14, Task 11) |
| A7 | `testStarsPrefOffOnlyBlastGroups` group 0x10 could clip | Task 3a.2: both blast groups at (300, 200); 0x10 needs x ∈ 79…521, y ∈ 79…321 (kind 7, ±80 offsets — verified in `_NewStarGroup @ 000035b5` case 0x10) |
| A8 | list the harmless draw-pass side effects | Research note 19: hurt-block entries cleared by `_DrawHurtBlocksToComp @ 0001b8b1`, rect → prevRect copies, offscreen balloons lose `visible` in `_Balloons_DrawToComp @ 00024280`; none uses the RNG (verified) |
| A9 | "LEVL w1 912 is a ppat id, not a PICT" | **Verified the other way and recorded:** `PICT 912` exists in `Bubble Trouble X.rsrc` (457,926 B; census extract), and `_DrawAndCentrePict @ 0000bd14` asks `GetPicture` (PICT only) — the bank (data-formats §7) is right. Research note 9's w1 row now says where each PICT lives and that the same ids also exist as `ppat` in `BT Levels.rsrc` but are not what the level shows. No bank correction |
| A10 | flag "level completed in the last 70 frames" for Ben | R2 above |
| A11 | freeze total RNG draws per FILM | Task 11: `totalDraws` in `FilmReplayResult`, a `draws` column in the table, and in `testGoldenReplayNumbers` (with the end string); FILM-oracle (c)/(d); Known delta 4 |
| A12 | HectorKit head is `8287ddb` | Tech stack + Task 0.1: `v0.1.0-2-g8287ddb`; the two post-tag commits are HectorShell-only; cited APIs re-checked at that head (lines unchanged) |

**Reviewer B**
| # | finding | resolution / where |
|---|---|---|
| B1 | jewel helpers needed by Task 6 had no owner | Task 5a: `Sim/JewelQueries.swift` with `isTargetJewelFound` (`@ 0001c9b9`), `isJewelTheTarget` (`@ 0001c8fb`), `isJewelTheDistantTarget` (`@ 0001c95a`) — semantics from the decompile — and new test `testJewelTargetHelpers`; Task 6.1 points at them |
| B2 | `GameState.testWorld` not in any file/commit list | named `Sim/TestWorld.swift`, in Task 4's file list and commit |
| B3 | Task 9 too large; Tasks 5 and 7 large | Task 9 → **9a** (spawn/eggs/`_ProcessEnemies`/animation; 4 tests), **9b** (AI/move/random walk/homing; 6), **9c** (actions; 3) with an explicit seam rule (`preconditionFailure("Task 9b/9c")`, never silent stubs; 9c greps them gone). Task 5 → **5a** (queries/scoring/catches; 5) + **5b** (mutations/blocks/dynamite; 11). Task 7 divides naturally → **7a** (balloons; 6) + **7b** (bonus/EXTRA/time bonus/regenerate; 6) |
| B4 | `testSquishScoreTable` ambiguous (n = 3 steps the multiplier) | Task 5b.2: each case on a fresh `testWorld`; expected multipliers afterwards 1, 1, 2, 3, 4, 5 (from `_Bonus_SetNumEnemySquishes @ 0001a818`) |
| B5 | `testMultiplierStepTable` understated the award | Task 5a.2: `_AddToScore(v, 1)` at multiplier 5 → **+10000** (level 8) / **+20000** (level 9) — verified |
| B6 | `_HeroCaught(2)` "hero invisible" is `+0x4a` visible = 0 | Research notes 23/27 (decompile `puVar1[0x4a] = 0`; death bubbles need `+0x4a` — verified in `_ProcessHero` state 4); `testHeroCaughtKind2`, `testDeathAnimationBubblesOnce`; Diagnosis suspect 2 |
| B7 | `_WasEnemySquished` skips the dead flag | Invariant 7 (second paragraph); Research note 34; Task 5b contract + `testWasEnemySquishedPopsHeldBalloon`; Task 8 `testSquishCountChains` (second block in the same frame); Diagnosis suspect 7 |
| B8 | Note 33: enemy push conditions | Research note 33: edge limits, normal (10) adjacent, beyond 0 or 'F' (verified in `_TryEnemyPushBlock @ 000131fd`); new test `testEnemyPushNeedsNormalThenEmptyOrF` (Task 9c) |
| B9 | Note 32: `_MoveEnemyRandomly` repeats the pending-action dispatch, has the stuck/`_ToastBubble` fallback | Research note 32 rewritten from `enemies-ai.md` §4c; Task 9b contract |
| B10 | hero balloon's `_ReleaseEnemyFromBalloon(-1)` unreachable | **Applied, refined:** new bank correction **C12** (next to NR-6) and Research note 40. Verified that the trap-release frame h+91 pops the balloon via `_PopEnemy(-1)` first; one residual path exists (enemy catch in `_ProcessEnemies` on exactly h+91 at a w16 = 120 level, L16–50 → release at h+121, one frame before `_Balloons_PopAll`), labelled MED; unreachable for levels 1–4; both calls are no-ops in the replica. Task 12 now appends C1–C12 (≥ 12) |
| B11 | `testBounceCounts` wording | Task 8.2: blue retires when bounces reaches 2, purple at 3 (verified in `_MoveBlock @ 0001cccb`) |
| B12 | pin down five tests | `testSmallBlastRect` slots 0/1/2 + score 600 (5b); `testNewEnemyScanAndDraws` k = rejected `(0,5)` draws, seed 42 → 5 draws, egg at (0,10) (9a, Python-computed); `testMoveEnemyRandomlyDraws16` seed 1 → roll 10, order [2,4,3,1], dir 2, 17 draws (9b, Python-computed); `testBonusRewardTable` 3500 / 99950 cap / 2 and 12 draws (7b); `testRegenerateBlocks` 0 star draws of its own, +4 with a squish → 16 (7b) |
| B13 | cite `_DoFXSuitabilityCheck @ 0000f760` for Invariant 11 | Invariant 11: `SetBooleanPref(0x35,1); SetBooleanPref(0x36,1)` (disasm), tail-jumped from `_AlexPrefsGameInit @ 0000fa24` |
| B14 | make the two draw-order statements unambiguous | Research note 30 ("squish-on-entry runs before the catch test"), note 23 ("the push check runs before `_MoveHeroAligned` and its turn draw; only a 0 result falls through" — verified), Task 9a.1, Diagnosis suspect 7 |

**Final shape:** 18 tasks (T0, T1, T2, T3a, T3b, T4, T5a, T5b, T6, T7a, T7b, T8, T9a, T9b, T9c, T10, T11, T12), 15
MAJOR; 119 tests (100 synthetic, 19 data-gated); 12 bank corrections.
