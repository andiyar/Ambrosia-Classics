# P3.1 / P3.2 grounding — level transition + carry/reset (read-only research, 2026-11-15)
Sources: listing `~/Developer/Ghidra/deimos/proj/disasm-review3-all.txt` (L), dump `ghidra/deimos/Deimos_pef.decompiled.c` (D),
bank `docs/deimos/level-scroll-objects.md` §8 (B8), `loose-ends-session.md` §6–7, decoded data `~/Developer/Ghidra/deimos/proj/data/Game/`.
HIGH = read in L; MED = D only / inferred. Swift paths relative to `Deimos/Core/Sources/`.

## 1. The original's sequence: end of level → first tick of the next

### 1a. Pass T (the tick the tallies finish) — all inside one `FUN_100051a0` loop iteration
1. `FUN_10006b50` (100059cc) → level-end branch: the coin tallies all report done → **G+0x09 = 1 at 10007020**. This is where
   the Sector Secured tallies end (already built: `levelEndStep`, Game/LevelEnd.swift:73). HIGH
2. `FUN_10007170(ctrl, film, info)` (call 100059dc; r3 = r1+0xc0 controller, r4 = r21 film, r5 = r1+0x280 info). HIGH
   - 10007194..1000719c G+0x09 clear → return.
   - 100071a0..100071e4 first in-game player (`FUN_10026c10`) none → 10007264 G+0x08 = 0 (game over end).
   - 100071e8..100071f8 film → G+0x08 = 0, return (no stop, no tran, no reset; G+0x09/+0x39 stay set).
   - 10007200..10007204 `FUN_10048120(0)` music stop (the `bne` at 100071fc reuses cr0 of 100071e8: never taken).
   - 1000720c..10007224 `tran` = PermSoundID 3, `FUN_10047670(id, prio 0x4b, vol 0x64, multiple 1)` — no RNG draw (`SoundPlay.perm`).
   - 1000722c..10007234 **`FUN_1000b9a0(display, 1)` fade to black**: 33 steps a = 32→0, scales back buffer display+0x68 in
     place (`FUN_1001ec80`), per step `FUN_1000c2a0` + mode 1 → `FUN_1000bd80` (= `PresentKind.gameLayout`), ≥ 1 TickCount per
     step (1000ba34..1000ba44). Real time ≈ 33 ticks / 0.55 s. Swift seam already exists: `.fade(.toBlack, .gameLayout)`
     (Seams/RenderOp.swift:52; renderer DeimosRender/Fades.swift, driver DeimosDriver.swift:229, headless HeadlessRunner.swift:120). HIGH
   - 1000723c..10007240 G+0x09 = 0; 10007248 G+0x39 = 0. HIGH
   - 1000724c `FUN_100302e0(ctrl)`: 100302f4 `FUN_100189f0` clear layers · 100302fc messages reset `FUN_1002db50` ·
     10030308 console reset `FUN_1002d040(ctrl+8)` · 10030314 FPS init `FUN_100305e0` · 10030320 divider reset `FUN_10030790` ·
     10030328 FlushEvents `FUN_10048e30`. Controller NOT zeroed (frames presented, limiter stamp +0x1c, latches carry). HIGH
   - 10007254..1000725c `FUN_100064d0(r25 = film flag, known 0 here, info)` — B8 writes "(0, info)": same value. HIGH
3. `FUN_100064d0`, later-level path (step by step, HIGH unless marked):
   - 10006500 G+0x1c game time = 0 · 10006504 G+0x29 = 0 · 1000650c G+0x2c = 0 · 10006510 G+0x38 appeared = 0.
   - 10006514 `FUN_10007130` cheat counters 0 (EVERY level, not only game start) · 10006518 `FUN_10007150` ground created/destroyed 0
     · 1000651c `FUN_10007280` accuracy tally reset (TallyState.reset).
   - 10006524..10006544 G+0x0c reward armed = G+0x0b (perfect last level), G+0x0b = 0.
   - 10006548 `FUN_1003e510` loaded-unit list reset (no model) · 10006554 `FUN_10000890(list)` ctor · 10006560 G+0x10 != 0 → later branch 10006594: s = `FUN_10011e30(G+0x18)` (tag→sector, 0 if absent) **+ 1** (100065a8);
     `FUN_10011de0()` = order-list length = 12 (100065ac); **s > 12 → G+0x18 = 'none' (10006620..10006628)**; else
     G+0x18 = `FUN_10011f00(s)` (sector→tag, 100065cc) and `FUN_10011fd0(s, info, list)` (100065dc) **reloads the SAME info
     struct the session holds** (r4 = r23 = param_2) — so the appear's music (info+0x27c) follows the new level.
     Then the unregistered gate (100065e4..1000661c; `FUN_10010f90` registered → skipped). Registered game: ignore.
   - **1000667c..10006684 G+0x10 levels started += 1 — before the none test** (so 13 after sector 12).
   - 10006688..100066c8 tag 'none': **`FUN_10048220(0)` = music RESUME** (pause/resume fn, 0 = resume; NOT "stop" as B8 says);
     +0x0e = 1 only if unregistered; G+0x08 = 0; → 10006988 (`FUN_100008b0` list dtor), return. Nothing else reset.
   - (1000663c..10006678, 100066cc: unregistered cut-off — skipped in the registered game.)
   - 100066e8 **G+0x14 = s** (before the players: `FUN_1003af90` reads it via `FUN_10005cd0` at 1003b0dc).
   - 100066f0 `FUN_1002b3a0(s)` = resource preload only (see §4) · 100066f8..1000674c `FUN_10009d70` terrain buffer (superseded).
   - 10006754..10006788 film==0 and music not paused (`FUN_10047f80`) → `FUN_10048120(0)` stop + `FUN_10047f90('ammu',1,0)`.
   - 10006798..100067b8 `FUN_100269a0(P, G+0x18, G+0x1c=0)` P1 then P2 (§2) — the only RNG draws before the spawns.
   - 100067c4..100067c8 film==0 → `FUN_10048120(0)` stop (net: ammu silent, ◇ stand-in 4 shape).
   - 100067d0 messages reset · 100067d8 debris `FUN_1002a660` · 100067e0 particles `FUN_100432d0` · 100067ec scroll `FUN_1000fa90(info)`
     (incl. map + mask load `FUN_1000fbc0`) · 100067f8 `FUN_10032e60(list)` entity world reset + pending list · 10006804 free list ·
     1000680c blurs `FUN_100467c0` · 10006814 input reset `FUN_1004a950` (no op) · 1000681c notice reset `FUN_10018130` ·
     10006824 `FUN_100189f0` clear layers · 1000682c load pass `FUN_1000fa10` (rows 3600..3056) · 1000683c..100068f4 Notice_Level_NN =
     PermObjectID s+9 at (208, 240) (gaob idx 10..21 = no01..no12) · 1000690c back ← black · 10006914..10006934 score bar level
     start (blits off) · 1000693c..10006970 pref-5 dance (+0x0f) · 10006974 first terrain blit · 10006980 `FUN_1000c2a0` window.
   - Identical to the level-1 path (DeimosSession.swift:188) from 100066e8 on; only the branch at 10006560 and the none exit differ.
4. Back in the loop: **100059e0..100059f0 G+0x1c += 1 unconditionally → game time = 1 when pass T ends.** HIGH
5. 10005a18 draw world draws the NEW level (load-pass units, the no0N notice, score bar with screen blits off: appeared = 0);
   end frame: **no present** (10030d90 tests G+0x38, cleared at 10006510). The screen stays black. HIGH

### 1b. Passes T+1, T+2
- T+1: appear test (game time 1 ≠ fctiwz(flli 18) = 2) no; **first tick of the new level at game time 1** (scroll tick k = 1
  spawns row 3055); time → 2.
- T+2: appear at game time 2: `.play(info.music = mu03, loop)`, `.fade(.fromBlack, .gameLayout)` (9 steps), pref 5 restore,
  appeared = 1; world update at time 2.
- ⇒ **Every level after the first runs its world one game-time unit later than level 1**: level 1 ticks at 0,1,2…, later levels
  at 1,2,3…; a placement at yLoc Y < 3056 spawns at game time **3056 − Y** (B8 §3 "3055 − Y" holds for the first level only);
  the level appears on its 2nd tick (level 1: 3rd). Player state-2 entry time is 0 in both (FUN_100269a0 gets game time 0). HIGH

### 1c. RNG, counters, film
- **No re-seed between levels**: `srand` (`FUN_10055400`) is called only at 100057d4 (session, TickCount) and 10006b28 (film).
  None in 100064d0..10006988 (full call list checked). HIGH
- Draws between "levelComplete set" and the new level's first tick, in order: none in FUN_10007170 / FUN_100302e0;
  in FUN_100064d0: P1 `R(400,2000)` (10026a9c, kept in +0x234), P2's if in game (discarded), then the load-pass spawns
  (FUN_1000fa10 → FUN_10033220 per placement, FUN_10035cd0 member order) and the Notice_Level spawn. HIGH order; draws inside
  spawns are C12's contracts.
- Frame controller: frames presented / limiter stamp carry; FPS window and divider re-init; console reset. HIGH
- Film: a film session never transitions (100071e8). `FUN_100064d0` never resets film cursors (loose-ends-session §7, HIGH).
  The recorder (`FUN_10009830`, state-4 ticks only) keeps appending across levels into one stream (block +0x18 = current level
  each tick via `FUN_10005cc0`, header level = start level); replay loads the header level and stops at its level complete —
  "Last Film" replays only the start level. Recording is unmodelled (Phase 4). HIGH (bank) / MED (block +0x18 detail, D).

## 2. Carry / reset table (per-level `FUN_100269a0` 100269c4..10026af0 acts only if +0xc4; session `FUN_10026410`)
| field | across a transition | where (address) | conf |
|---|---|---|---|
| lives +0x98 | carried (set only by setup `FUN_10026cc0`: callers 10026850/10026874) | xref | HIGH |
| score +0xb0 | carried (`FUN_100299c0` callers 10026354 ctor, 1002688c setup) | xref | HIGH |
| extra-life threshold +0x9c / step +0xa0 | carried (setup 10026d10 only) | L | HIGH |
| money +0xac | reset 0 `FUN_10027580` (10026a3c) — after the coin bonus was paid to score | L | HIGH |
| money counter (coin tally, +0xd8…+0x1f8) | reset `FUN_10027630` (10026a48), alpha 0x20 | L | HIGH |
| multiplier +0xb4 | **carried** (`FUN_10029fd0` resets only at 10026898 setup, 10028150 death) — B8 omits | xref | HIGH |
| multiplier indicator serial +0xb8 | **carried stale**; entity serials restart per level (EntityWorld.levelReset) → first respawn's `showMultiplierIndicator` removes serial X of the NEW level (1002a094 `FUN_10034de0`) if multiplier ≥ 2 | L + Swift | HIGH (quirk) |
| shield +0xa8 | refilled to `defaultShieldPercentage` 100 `FUN_10027400(p,1)` (10026a58); hit timers, +0xd1 warn = 0 | L | HIGH |
| invulnerable +0xce / sticky +0xcf | **set non-sticky at level end (10006f28)**; not touched by 100269a0, respawn 10029cc0 (writers of +0xce: 10026320 ctor, 10027e08/28/38 setter, 10028124 death, 1002a238 state-4 clear) → next level's first state 4 is invulnerable until first tick with now > enter + entry_InvulnerabilityTime (60) and G+0x39 clear. Level 1's first spawn: NOT invulnerable. | L | HIGH |
| life state +0xc6/+0xc8 | state 2 at game time 0 (10026a20); respawn when now > 55 (entry_InitialDelay) | L | HIGH |
| in game +0xc4 (dead player) | stays out: 100269c4..100269cc return → no draw, no reset, score-bar record drawActive = false | L | HIGH |
| +0xd0 hit/defence latch, +0xc5 appearing, +0xc0 levelRef | 0 (100269d4), 0, = new tag (100269f4) | L | HIGH |
| position, velocity, crosshair adjust, overload | reset `FUN_10026b10` / `FUN_10026ea0`; ship sprite `FUN_10029f10`; size `FUN_10012940`; glow off `FUN_10012c00`; appear fade flli 163–165 | L | HIGH |
| input bytes +0x1fc, maxSpeed +0xa4, cheated +0xbd | carried (setup only; input read only in state 4 after a clear) | D | MED |
| integrity tick +0x234/+0x238 (P1) | 0 + R(400,2000), 0 | L | HIGH |
| weapons (handler +0x240) `FUN_1003af90(h,1)` | x,y 0; prev buttons 0; icons dirty; salvo/bomb timers 0, bombs pending 0; air launch time/count 0; aux times/counts 0 (aux unreachable); **both power-up blocks idle (serial −1, level 0, percent 0)** (1003b054..1003b0a8); pending PEAG applied (1003b0ac..1003b0d0); **PEAA with min == sector equipped + pending air dropped (1003b0dc..1003b108); no match → pending air KEPT, not applied (1003b0ec beq 1003b138)**; crosshair lock off, vis 0 → 100. Current air/ground weapon otherwise carried. | L | HIGH |
| G+0x0c reward armed | = G+0x0b (100% ground accuracy last level), +0x0b = 0 — affects the random-bonus ladder (Destruction.swift:135) | L | HIGH |
| G+0x44 perfect levels | carried (mission bonus needs 12) | L | HIGH |
| tally G+0x48…, ground counts, cheat counters, G+0x29/+0x2c/+0x38/+0x39/+0x09 | reset (1000651c, 10006518, 10006514; 10006504..10006510; 1000723c..10007248) | L | HIGH |
| G+0x0a, gameOverNoticed, p1Active | not reset (a transition needs someone alive; p1Active never reset in session) | L | HIGH |
| score bar (FUN_10031400) | all dirty, shown shield/power followers 0.0, last score/lives = current, +0x12e/+0x12f = in game, icons by new sector | Swift ScoreBarState.swift:94 | HIGH |
| entity pool / groups / pending / noticesShown / serials / group IDs | reset (`FUN_10032e60` → EntityWorld.levelReset, PERM re-made), entity-limit latch 0 | Swift | HIGH |
| messages; notice, debris, particles, blurs | reset (100302fc + 100067d0; 1000681c, 100067d8, 100067e0, 1000680c) | L | HIGH |
| scroll, map, mask | speed 1, level-end 0, offset 0, top 3120, progress 481 (`FUN_1000fa90`); map+mask reloaded (`FUN_1000fbc0`) | B §2/§9 | HIGH |
| music | stop (10007204) → [ammu play, stop] (not film) → mu03 at the appear tick | L | HIGH |
| RNG; frame controller; console | carried, no srand; not zeroed (FPS/divider re-init); reset | L | HIGH |

**Bank (B8) vs listing — disagreements / omissions (listing wins):**
1. B8 "Tag `none` → stop music": L 10006698..1000669c is `FUN_10048220(0)` = **resume** (music already stopped at 10007204; MusicEngine: resume after stop does nothing).
2. B8 "game time reset to 0 at every level start" — true, but the new level's first tick is at game time **1** (100059e0); B8 §3 "game time 3055 − Y" is level-1-only.
3. B8 table omits: multiplier carried; shield refilled to 100; money counter reset; invulnerability carried from the level end; power-ups idled; pending PEAA kept when no sector match; +0xd0/+0xc5 cleared; levelRef updated; reward armed / perfect levels.
4. B8 "`FUN_1002b3a0` per-sector setup … not read": now read (§4) — resource preload only.
5. B8 step 4 "`FUN_100064d0(0, info)`": L passes r25 (film flag), 0 on that path — equivalent, wording only.
6. Swift doc nit: GameFlags.swift:59-60 "cheat uses … zeroed at game start by FUN_10007130" — every level start (10006514).

## 3. What exists in Swift (and what P3.1/P3.2 must change)
- `DeimosCore/Game/LevelEnd.swift:125` `levelCompleteStep` — film/no-player branches right; non-film: stop, tran, clears, `FrameKeys.levelTransitionReset`, then **◇ S9.1 `running = false` (:142-143)**; fade omitted (:138). P3.1: emit `.fade(.toBlack, .gameLayout)` and start sector+1; remove the S9.1 end. It is a `GameState` method — it cannot reach `DeimosSession.levelStart`, `levelInfo`, `scoreBarDraw` (session-owned) → either return a "next level" signal to `DeimosSession.tick` or move the level start's state part into GameState and leave the score-bar ops to the session.
- `DeimosCore/Game/LevelEnd.swift:73` `levelEndStep`, `:83` allLevels test (sector == 12 ∧ levelsStarted == 12) — unchanged.
- `DeimosCore/Game/FrameKeys.swift:89` `levelTransitionReset` — complete except the layer clear (100302f4) which no op carries (comment "the renderer's"); P3.1: emit `.clearLayers` or record why it is a no-op.
- `DeimosCore/Game/DeimosSession.swift:188` `levelStart(_:)` private, level-1 only (doc :51 "next-level branch … is Phase 3", :53 "level none → Phase 3"); `throws` (loadMask :221) but `pass` is non-throwing → P3.1: validate all 12 levels' defs + masks at init (throw early) or trap. Add the 10006594 branch, the none exit (`.resume`, running = 0, return before players), `levelsStarted` += 1 before the none test, `flags.sector` before `playerLevelStart` (:210).
- `DeimosSession.swift:82` `public let levelInfo` — must become mutable (FUN_10011fd0 reloads it; appear reads `.music` at :385). Keep the public name (rule 7).
- `DeimosSession.swift:382-397` `tick`: `levelCompleteStep` (:395) then `gameTime += 1` (:396) — already the original order (gives the +1). `:338` `ops += game.tickOps` runs AFTER the tick: **transition-tick terrain stamps must be drained before the fade/`.loadTerrain`**, else they land on the new map.
- `DeimosSession.swift:5` `SessionStart` — no change for P3.1/P3.2.
- Reusable as is (P3.2 needs no new rule code, only tests): `Player/Player.swift:300` `levelStart` = FUN_100269a0;
  `Player/PlayerLife.swift:31` `playerLevelStart` (+ money counter), `:23` `setupPlayer`; `Weapons/WeaponHandler.swift:202`
  `resetHandler` = FUN_1003af90 (matches L incl. pending-air keep); `ScoreBar/ScoreBarState.swift:94`, `ScoreBarDraw.swift:58`;
  `Game/ScrollState.swift:38`; `Units/LevelObjects.swift:25`; `Game/GameFlags.swift:26/28/30` levelsStarted / sector / level.
- `DeimosHost/HeadlessRunner.swift:106` `reason()` — `:111` (`levelEndingBefore && !levelEnding` → `.levelComplete`) will now fire only for the sector-12→none end; suggest a new `EndReason` (e.g. `.campaignEnd`, test `flags.level == .none`) and update the `.levelComplete` doc (:10). `:113` traps on anything else — a mid-run transition does not end the session, so no trap.
- `DeimosHost/DeimosDriver.swift:43-50` doc, `:214` `newSession(seed:sector: 1)` — ◇ restart stays for campaign end / game over (Phase 4); no code change needed for the fade (generic `.fade` handling at :229). Minor: keys typed during the fade are flushed in the original (FlushEvents after the fade); the driver's `typedQueue` would deliver them to the next pass.
- Tests asserting stand-in 1 (must be re-specified, not deleted): `Tests/DeimosCoreTests/LevelEndTests.swift:417` `testLevelCompleteClearsRunningInFilm` (its non-film `w` case asserts `running == false` :460-461); `Tests/DeimosHostTests/ReplayHarnessTests.swift:~92-98` (non-film `n` case expects `.levelComplete`). `FilmPlaybackTests.swift:294` `testLevelCompleteEndsFilmSession` stays valid.

## 4. Data facts
| sector | ident | level | name | bg / mask | music | objects | load-pass placements (yLoc ≥ 3056) |
|---|---|---|---|---|---|---|---|
| 1 | Lucena | le07 | Mariner Valley | jum2/jut2 | mu03 | 38 | 0 |
| 2 | Yippe | le06 | Cydonia Plateau | inm3/int3 | mu03 | 43 | 0 |
| 3 | Vista | le02 | Darius | cam2/cat2 | mu03 | 44 | 1 (bu02@3082) |
| 4 | Swoop | le08 | Neo Kowloon | ism3/ist3 | mu03 | 49 | 0 |
| 5 | Conrad | le11 | Heart of Darkness | jum1/jut1 | mu03 | 40 | 0 |
| 6 | Delos | le04 | Bellerephon | cam3/cat3 | mu03 | 43 | 1 (bsde@3102) |
| 7 | Sparta | le12 | Greater Babylon | inm1/int1 | mu03 | 40 | 1 (shur@3118) |
| 8 | Saratoga | le03 | Ticonderoga | ism1/ist1 | mu03 | 44 | 2 (flip@3068, csgr@3145) |
| 9 | Hannibal | le05 | Yucatan Rift | jum3/jut3 | mu03 | 51 | 3 (shur@3079, shur@3162, bsat@3247) |
| 10 | Leonidas | le01 | Kepler Massif | cam1/cat1 | mu03 | 46 | 2 (bsde@3309, bsde@3129) |
| 11 | Thebes | le10 | Thermopylae | inm2/int2 | mu03 | 60 | 1 (cs2a@3123) |
| 12 | Yamato | le09 | Carthage | ism2/ist2 | mu03 | 67 | 2 (car2@3191, car2@3069) |
All 12: `#background_RECT <0, 0, 480, 3600>`, `#briefing_ID <none>`, music mu03 (so the appear music is the same every level).
Notice_Level_NN: gaob item sector+9 = no01…no12 (no `none`).
- `FUN_1002b3a0(s)` (D): `FUN_1002b6d0` for 'PEAA', 'PEAG', 'SPEC': every wede whose type matches and +0x13c ≤ s ≤ +0x140 →
  `FUN_1002b790` loads its sprite groups (`FUN_1001f950`) and unit resources (`FUN_1003e580`). Resource loading only; no game
  state; no wede has type SPEC. MED (dump). → no model (as today).
- wede ranges: aiic PEAA 1–3 (DEAA), aibg PEAA 2–∞, airg PEAA 3–∞, aipb PEAA 5–∞, plbo PEAG 0–∞ (DEAG).
  Start weapon (session, `FUN_1003cdb0` largest min in range): s1 aiic, s2 aibg, s3–4 airg, s5+ aipb.
  **Level-start forced swap (min == sector): entering s2 → aibg, s3 → airg, s5 → aipb**; s4, s6–12 keep the current air weapon.
  A campaign player therefore holds airg in s4 like a direct start, but whatever they picked up in s6+.
- Per-sector rules already reading G+0x14 (one source): Notice no0N; defence bonus 2000 × s (PlayerScoring.swift:115); accuracy
  tier × s (Tallies.swift:117); coin value × s only if flli 170 ≠ 0 (it is 0.0 → not scaled); bombs = s + 1 − 1 capped 8
  (Launchers.swift:56); unit shields + increment × (s − 1) (Spawn.swift:228); random-bonus top rung needs s ≥ flli 219 = 3
  (Destruction.swift:148); weapon pickup ranges (WeaponTick.swift:66, StateEntry.swift:107); score-bar icons; allLevels at 12.
- plde: lives 3 (1 if start sector ≠ 1), extra life 10000 then +30000, max 10; InitialDelay 55, InvulnerabilityTime 60,
  dyingTime 80, finalDyingTime 40, gameOverTime 20, default shield 100.

## 5. Open questions and risks
1. **Films cannot witness a transition** (every film session ends at level complete, 100071e8). P3.1/P3.2 are proved by tests +
   Ben's play only; P3.5's replays are untouched by them.
2. **The +1 game-time shift** of later levels (§1b) is easy to "fix" wrongly (calling level start after `gameTime += 1`, or
   resetting to 0 after the tick). Pin it in a test: after the transition pass `gameTime == 1`; the new level's first tick runs at 1.
3. **Op order in the transition pass**: tick stamps → fade to black → [clear layers] → level-start ops (`.loadTerrain`, mask,
   fill back, score-bar level-start ops, terrain blit) → draw world → end frame with no present. Stamps after `.loadTerrain`
   would corrupt the new map. The fade is a host op mid-pass; the driver sends all the pass's cues at pass begin, so `tran`, the
   music stop AND the new level's ammu play/stop reach the sink before the fade starts (original: stop + tran before, ammu after
   the 0.55 s fade). Net audible difference nil (ammu play+stop is silent) — but it breaks the driver's "at most one frame early"
   claim; record it on the gate card.
4. **Invulnerability carry-over** (non-sticky, set at the level end) — Ben's eyes decide per the card; the machine fact is HIGH.
5. **Stale multiplier-indicator serial** (§2) can remove an unrelated new-level entity on the first respawn if serials collide —
   original behaviour; replicate, do not guard. Collision odds unknown (old serial is level-1's last indicator spawn).
6. **Dying or out-of-lives players at the transition**: a player in state 3 (dying) or state 1 (lives 0, < 20 ticks) still has
   +0xc4 = 1 → FUN_100269a0 revives it to state 2 without the life decrement (state 1 with 0 lives respawns and plays on).
   Reachable only if the death lands < ~100 ticks before the tallies finish (the level end makes in-game players invulnerable,
   so it needs a death begun before the level end). Replicate; low priority; Ben may never see it.
7. **Level start throws** (mask/definition) inside a non-throwing pass → validate the 12 levels at session init.
9. Trace: `ReplayTrace` has no sector/level column; a multi-level trace shows game time falling back to 1. Adding a column breaks
   `testReplayTraceCSVHeader` (rename-free change needs the header test updated in the same commit).
10. Keys typed during the fade (driver `typedQueue`) survive into the next pass; the original flushes them (10030328 after the
   fade). Console-only effect; record or fix in the driver.
11. Session started at sector N > 1: after sector 12 it shows `nole` (not `noal`), next start → none → session ends (levelsStarted
   ≠ 12). P3.4 owns the finale path; P3.1 must only make "none ends the session" true.
12. One-level assumptions (grep "Phase 3|◇|sector 1"): only those listed in §3; no other sector-1 hard-codes in Sources.

## 6. Suggested tests (all bounded; poke `session.game` via @testable; progress poke = `game.scroll.progress = 3599`)
P3.1 (≈ +6):
- `testTransitionPassStartsNextSector` — sector-1 session, poke progress, run ≤ 3,000 passes until levelsStarted == 2 (XCTFail at
  bound): same pass `sessionEnded == false`, `flags.sector == 2`, `flags.level == le06`, `levelInfo.id == le06`, `gameTime == 1`,
  appeared false, no `.present` op after the fade (10006510, 100059e0, 10030d90).
- `testTransitionOpOrder` — in that pass: `.fade(.toBlack, .gameLayout)` precedes `.loadTerrain(image: inm3)`, which precedes
  `.fill(.back, 0)`; any tick stamps precede the fade (10007234, 100067ec, 1000690c).
- `testTransitionCues` — music `[.stop, .play(ammu, loop), .stop, .level(pref 1)]` in that order, sounds end with
  `tran` prio 75 vol 100 multiple (10007204, 10007224, 10006788, 100067c8).
- `testNextLevelAppearsOnItsSecondTick` — pass T+1 ticks at game time 1 without music; pass T+2 emits `.play(mu03)` +
  `.fade(.fromBlack, .gameLayout)` (10005930..100059b8 with time 2).
- `testNoReseedBetweenLevels` — snapshot `game.rng` just before `levelCompleteStep` (direct call on a poked state); after,
  P1.integrityCheckTick == 0 + snapshot.range(400, 2000) (first draw, 10026a9c); no srand.
- `testSectorTwelveCompleteEndsSession` — sector-12 start, poke progress, run to end: `nole` requested (not `noal`), levelsStarted
  2, `flags.level == .none`, running false, music contains `.resume` after the transition `.stop` (1000669c), sector stays 12,
  players untouched; HeadlessRunner end reason = the new campaign-end case.
- Re-specify `testLevelCompleteClearsRunningInFilm` (non-film case now continues) and the ReplayHarness `n` case.
P3.2 (≈ +8; each pokes P1 before `levelCompleteStep`, asserts after):
- `testLivesScoreThresholdCarry` — lives 2, score 12,345, threshold 40,000 → unchanged.
- `testMoneyAndCounterReset` — money 77, coin tally state 3 → 0, alpha 0x20 (10026a3c, 10026a48).
- `testMultiplierCarriesAndIndicatorOnRespawn` — multiplier 3 → 3; at the respawn (game time 56) PermObjectID 36 spawns and the
  stale serial removal is attempted (1002a094).
- `testShieldRefilledPowerUpsIdle` — shield 37 → 100; airPower charging → state 0, serial −1, percent 0 (10026a58, 1003b054).
- `testAirWeaponForcedAtSectorsTwoThreeFive` — entering s2 aibg, s3 airg, s4 keeps, s5 aipb, s6 keeps; pending air kept when no
  match (1003b0dc..1003b134).
- `testInvulnerabilityCarriesIntoNextLevel` — after transition invulnerable && !sticky; respawn at 56 → state 4; cleared on the
  first tick with now > 56 + 60; a fresh level-1 session's first spawn is not invulnerable (10006f28, 1002a1e8..1002a238).
- `testDeadPlayerStaysOut` — 2-player, P2 out: P2 fields byte-equal before/after, only one R(400,2000) drawn, score-bar
  record 1 drawActive false (100269c4).
- `testPerLevelCountersReset` — perfectThisLevel → rewardArmed, perfectLevels kept, ground counts/cheat counters/tally 0,
  levelEndHandled false, scroll window top 3120 / progress 481, entity world = PERM + load pass, followers 0.0.
