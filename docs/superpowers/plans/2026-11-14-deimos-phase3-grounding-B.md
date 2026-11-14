# P3 grounding B — two players, finale, levels 2–12 readiness, sweep check, app (2026-11-15, read-only)

Sources: worktree zen-cohen-186522 (code = local main after wave 3); listing `~/Developer/Ghidra/deimos/proj/disasm-review3-all.txt`;
decoded data `~/Developer/Ghidra/deimos/proj/data/Game/{unde,leve,wede,idli}`; data sweep script
`<scratchpad>/sweep.py` (`python3 -I sweep.py x`; closure over every `*_ID` that names a unit, per sector, weapons by
min/max level, PermObjects + plde refs as "common"). Film traces read: `<scratchpad>/h3rev/all-de0N.csv` (H3 review leg's
`deimos-replay --all --trace`, wave-3 code). Labels: HIGH = listing/data read; MED = bank/dump only or inference.

## 1. Two players

### 1a. The original (addresses)
| item | reading | label |
|---|---|---|
| start | menu button 2 `FUN_10024db0` → `FUN_100234d0(0, 2)`; key `2` (front-end §2.7–2.8); level select next (sector ≤ int pref 3; Phase 4); start record +4 = players (`stb r19,0x40(r1)`) | HIGH |
| set-up | `FUN_100051a0`: G+0x21 = players (`10005770`); `FUN_10026410` P1 then P2 (`10005860..10005888`): +0xcd = players, +0xcc = index; **both in game when players ≠ 1** (`10026820..10026878`); lives 3 at sector 1 else 1 (each); P2 plde `pl02` | HIGH |
| stand-in must set | only `SessionStart(sector: 1, players: 2, film: nil)` — everything else follows from set-up | HIGH |
| key table | prefs +0x14b8…+0x14ec, 14 ints (`1000515c..10005194`). P1: 0x7E ↑, 0x7B ←, 0x7C →, 0x7D ↓, 0x37 ⌘, 0x3A ⌥, 0x31 Space. **P2: 0x5B kp8 (up), 0x56 kp4 (left), 0x58 kp6 (right), 0x57 kp5 (down), 0x77 End (fire air), 0x75 Fwd-Delete (fire ground), 0x79 Page Down (select)**. Slot meanings 4/5/6 pinned from the guide (timing-frame §6 note #5) | HIGH values; LOW consumer (INDEX #14: no reader of 0x14b8 in the PEF beyond defaults + prefs copies; the OS X path may live in the shipped `HID.bundle`, never decompiled — MED guess) |
| ISp path | `FUN_1004abd0`: 10 needs, 5 per player; `FUN_1004afa0` poll fills P1 bytes 0–6, **P2 at +7..+13** (engine-loop §8) | HIGH |
| per-player read | `FUN_10006b50` `10006b94` (`FUN_1004aa90`) both players' bytes; `FUN_1002a3a0` per player only in life state 4 → +0x1fc (film read or record) | HIGH |
| start pos | `FUN_10026b10`/`FUN_10029cc0` `10029d00..10029da0`: +0xcd == 1 → solo (208, 330); else multi P1 (104, 330), P2 (312, 330). +0xcd never changes in a session, so a duo survivor still respawns at its multi start | HIGH |
| view shift | `10029504..10029524`: left → `FUN_100100b0(0)`, else right → `(1)`; called inside each player's update, P1 then P2 → **same direction moves 2 px/tick, opposite cancel**; clamp [−32, 31] per call (engine-loop §5) | HIGH |
| respawn / out | `FUN_1002a150`: state 3 past dying time → lives −1 (gate = P1 first reached state 4, `10006b9c..10006bc4`, never reset) → `FUN_10029cc0` respawn, or state 1 → past `gameOverTime` → +0xc4 = 0 (`1002a264`). Out stays out: `FUN_100269a0` returns when not in game; game continues while either in (`10006c3c..10006c7c`); `nogo` + 111 ticks when none (`10006c80..10006d98`) | HIGH |
| score bar | hud §8: P2 record +0x14c, reli R8–R15, flli 114/115, 118/119, 124/125, 134–139, tefo `sbs2`/`sbl2`/`sll2`; block ≈235 px lower (data quirks: P2 Life Count +244, Score bottom +238; `sbl2` x 498). Solo: P2 drawn once dimmed, never updated; a player out of lives dims + freezes the same way | HIGH (data) |
| coin tally | P2's counter `p2mc` stacked y + int(flli 181) = 70 (`10006f78..10006fb4`, scoring §6.5) | HIGH |
| RNG order that depends on P2 | (1) `FUN_100269a0` P1 then P2 (`10006798..100067b8`): one `R(400,2000)` per **in-game** player (`10026a9c`) — P2 out ⇒ one draw fewer per level start; (2) player updates P1 then P2 (`10006bf0..10006c28`): weapon fire, spawn-on-hit, overload sounds with pitch draws; (3) coin-tally set-up spawns `p1mc` then `p2mc`; (4) entity rules "nearest player" read both. Integrity check is P1-only (+0x23c set for P1 only) | HIGH (1–3), MED (4) |
| Phase 4 parts | high-score insertion with the two two-player quirks (loose-ends-session §3.1), name entry P1 then P2, Last Film holds both streams | HIGH (bank) |

### 1b. What the Swift code already does for index 1
- Session: `SessionStart.players` `DeimosSession.swift:9`; used `:150-153`; G+0x21 `:164`; `setupPlayer` both `:178-180`;
  level start P1, P2 `:210-212`; draw P1, P2 `:405-409`. Player set-up both-in-game rule `Player.swift:258-273`; solo vs
  multi start `Player.swift:374-377`; level start draw `Player.swift:300-318`; life states + respawn
  `PlayerLife.swift:49-117`.
- Input: `KeyTable.swift:13-39` maps P2's seven slots; defaults `DeimosPrefs.swift:54-55`; `UpdateWorld.swift:80` hands
  both players' inputs over, `:98` updates P1 then P2.
- Score bar per player: `ScoreBarState.swift:75, 94-123`; `ScoreBarDraw` loops P1, P2. Level end / tallies per player:
  `LevelEnd.swift:89, 105-112`; `Tallies.swift:180` (bonus step), `:224` (mission) `for p in 0..<2` (addScore skips out
  players, `PlayerScoring.swift:20`).
- Host: `DeimosDriver.swift:344-345` restarts keep `start.players`. HeadlessRunner takes any `SessionStart`.
- Tests already: `DeimosSessionTests.swift:247` `testPlayerTwoKeySlots`, `:197` `testDeterministicReplay` (2P);
  `PlayerPhase1Tests.swift:57-66` duo start (104/312, 330, `pl2o`); `LevelEndTests.swift:291-334` two-player tally order
  + stacked P2 coin text; `ScoreBarDrawTests`/`ScoreBarStateTests` only the SOLO P2 (dimmed).
- **Missing:** (a) any way to start 2P in the app — `DeimosController.swift:95` hard-codes `players: film?.playerCount ?? 1`,
  `LaunchOptions` (`DeimosMain.swift:19-50`) has only `-film` / `-debugCapsLock`; (b) tests: duo view shift (double /
  cancel / clamp), duo respawn at multi start with partner out, one player out ⇒ game continues + no `nogo`, both out ⇒
  `nogo` + 111, level-start draw count 2 vs 1 when P2 out, two-player score bar ACTIVE draw (P2 rects, icons), mission
  bonus paid to both; (c) app keys: P2 codes reach `HeldKeys` via HectorShell's `held` set (plausible — keyCodes, no
  filter seen), unverified; hazard: keys pressed while P1 holds ⌘ get no AppKit key-up (HectorShell's ⌘ monitor
  `ShellView.swift:288-290` is meant to cover it) — Ben's hands decide.

## 2. The finale

### 2a. Chain (data decoded this session; matches loose-ends-session §5.1–5.2)
- Trigger `10006dd4..10006e04`: sector == 12 and levels started == 12 → G+0x0d = 1; PermObject 23 `noal` instead of 22
  `nole` at (208, 240) → placed at (208, 150) (yOffset −90). Built: `LevelEnd.swift:80-86`; tested
  `LevelEndTests.swift:360` `testAllLevelsNoticeAtSectorTwelve`.
- `noal` (7 states, file order S0 Flash On t3 / counter 16 → S6; S1 Flash Off t3; S2 Fade Out, Delete; S3 Hold; S4 Scale In
  t10 → S5, sound `leen` RepeatOnStateChange FALSE; S5 Scale Out t10 → S4; S6 Spawn Game Completion t2 → S5, spawn set
  `12gc` ×1 delay 0). `acbo` on S0 entries 1–15 (RepeatOnStateChange TRUE).
- `12gc` (4 states: S0 Wait t5 → S2; S1 Spawn Flags t280 → itself, counter 3 → Delete, 4 × `miof` at (−126,−25), (2,−43),
  (104,−11), (188,42), delays 0/70/140/210; S2 Explosions t300 → S1, spawn set `aieg` ×1; S3 unreachable (4 × `miof`
  delays 0/90/180/270)). All rule units `none` → skipped.
- **INDEX #64 settled by data:** `12gc` S2's `aieg` spawn set has DelayBetweenEntities 0/0, Rate 0/0, NumInVolley 1/1,
  RepeatSpawns FALSE (`Level 12 - Game Comp[12gc].unde.txt` lines 483–495) ⇒ issued on S2 entry ⇒ **R = T0+95** [HIGH data;
  issue-at-entry rule spawn-and-waves §2.3 HIGH]. The finale's control flow does not depend on #64 — only the explosion
  timing does.
- `aieg`: 50 members, group delay R(5,6) cumulative (50 draws in member order), states Animate t5 → Fade Out t5 → Delete,
  spawns `aerg` + `icbh`. `miof`: 1 state, t1 → Delete. Irises in le09: `miac` (416,179), `mipo` (340,120), `mimu`
  (240,85), `migc` (132,103), each S0 rule "Is Active `miof` within 60" (rule #3, built `Rules.swift:84`).
- Accuracy tally state 1 wait = flli 196 = 1200 when G+0x0d (`1000763c..10007664`), strict → ends T0+1201. Built
  `Tallies.swift:130-138`.
- **Mission bonus** (`10007b68..10007d38`): at tally state 8, if G+0x44 (perfect-accuracy levels this session) ==
  `FUN_10011de0` (12) → `miac` sound (gaso 23, priority 100), then 10 payments (every flli 206 = 4 / 207 = 3 ticks) of
  int(flli 205) = 100,000 **raw** (no multiplier, no extra life) to P1 then P2 (each in game) ⇒ 1,000,000 per player.
  Reachable only on the 12th level of a session started at sector 1 with all 12 levels at 100 %. Built
  `Tallies.swift:198-232`; tested `LevelEndTests.swift:258` `testMissionBonusNeedsAllLevels`.
- **G+0x0d readers** (listing scan `lbz rX,0xd(rG)`): `10006e08` (choose `noal`), `1000763c` (1200 wait), `10005c08`
  (session result +0x14 → `FUN_100234d0` pref 3: best sector without the −1). No other reader [HIGH]. G+0x0d is never
  cleared inside a session (G zeroed at session start only); `10005c1c` clears G+0x0e, not 0x0d.

### 2b. End of the session after the tally (listing `100064d0..100066c8`, read this session)
G+9 → `FUN_10007170` same tick: music stop, `tran` (gaso 3, 75, 100, 1), fade to black `FUN_1000b9a0(display,1)`, G+9 =
G+0x39 = 0, `FUN_100302e0`, then `FUN_100064d0(0, info)`, which **before** its level test runs: game time = 0
(`10006500`), G+0x29 = 0, G+0x2c, **G+0x38 appeared = 0** (`10006510`), `FUN_10007130` cheat counters, `FUN_10007150`
ground counts, `FUN_10007280` tally reset, +0x0c/+0x0b, `FUN_1003e510`, `FUN_10000890`; next-level branch
(`10006594..10006620`): sector(G+0x18)+1 = 13 > 12 → level `none`; levels started += 1 → **13** (`1000667c..10006684`);
level `none` (`10006688..100066c8`): `FUN_10048220(0)` music resume (no-op: no stream after the stop, sound-music §6.1
`FUN_10048220` row), registration test (registered → G+0x0e stays 0), **G+8 = 0**, return. The pass then finishes: game
time + 1, draw world, end frame — **no present because appeared = 0, so the screen stays black** — loop exits, halt
effects + music stop (`10005ad8`, `10005ae4`), Last Film save, result (+0x14 = 1). [HIGH]
Front end after (`FUN_100234d0`, Phase 4): pref 3 = 12; fade to black again (33 ticks), `back`, fade in (9), high-score
check → name entry, menu. **No credits or special screen** follows the finale (credits only from the copyright button).
**Phase-3 stand-in boundary:** Phase 3 owns everything up to G+8 = 0 above (it is P3.1's transition code with level
`none`); then ◇ the driver starts a new game at sector 1 (as stand-in 2), replacing pref 3, the second fade, the scores
and the menu (Phase 4).

### 2c. §5.3 vs listing/data — disagreements
1. R = T0+95 is no longer conditional (#64 closed by data, above). 2. §5.3's last rows omit: `FUN_10007170`'s music stop +
`tran` before the fade; the level-start resets that run before the `none` test (levels started becomes 13, game time 0,
appeared 0 ⇒ the screen stays black); the music resume at `10006698`. 3. Otherwise every tick in §5.3 agrees with the data
(noal S0 entries T0+6k, 16th at T0+90; `12gc` S2 T0+95, S1 T0+395/675/955; flags at entry + max(d−1,0); `leen` T0+102;
tally T0+1201). Players' invulnerability holds to the end: the state-4 timeout is skipped while G+0x39 is set
(`1002a1e8..1002a200`, `PlayerLife.swift:62`).

## 3. Levels 2–12 readiness (data sweep + grep; no builds)
Order (identifier match): 1 le07 Lucena, 2 le06 Yippe, 3 le02 Vista, 4 le08 Swoop, 5 le11 Conrad, 6 le04 Delos, 7 le12
Sparta, 8 le03 Saratoga, 9 le05 Hannibal, 10 le01 Leonidas, 11 le10 Thebes, 12 le09 Yamato. Every map 480×3600, mask
96×720, music `mu03` (no new track), notices `no01..no12` all present (PermObjects 10–21).
Unit closure (excluding 75 common units) per sector: 48, 73, 74, 74, 109, 102, 115, 109, 107, 109, 120, 125; **159 units
are reachable only in sectors 5–12** (list: run sweep.py) — but they are data on the one generic unit machine.
Weapons (wede): `aiic` Ion Cannon 1–3, `aibg` Bacta Gun 2–∞, `airg` Rear Gun 3–∞, **`aipb` Photon Beam 5–∞**, `plbo` Plasma
Bomb (ground) 0–∞. Sector 1 has one air weapon ⇒ select cycles to itself; Photon Beam is the only weapon no film fires
(differences vs others: OverloadTime 0 — handled, `PowerUp.swift:69` tests `> 0`; MaxPowerLevel 22; release spawn `pbps`).

| feature | used by sectors | built? | film witness |
|---|---|---|---|
| every unit BOOL / placement option / pickup type used in 5–12 | also used in 1–4 except two | yes | partly (see films row) |
| `stateLinkToOwnerLoc` | 6,7,8,10,11,12 only | yes `OwnerLinks.swift:80`, test `MotionTests.swift:490` | no |
| `invulnerableUntilOwnerDestroyed` | 5,6,10,11,12 only | inert in 1.0.6 (bosses §3.5: parser-only reads) — Swift only sets unit +0x11 `UnitDefinition.swift:560` = faithful | n/a |
| rule #15 "Are Fewer of These Entities Active" | 10, 11 only | yes `Rules.swift:102`, `StateMachineTests` | no |
| rule "No Destroyable Air Entities Are Active" | 5, 6 only | yes `Rules.swift:86` | no |
| flee codes `cega`(not a code → flag only), `rave`, `soce` | 5–12 only | yes `FleePoint.swift:32-52` (+ default) | no |
| negative kill score (Hospital `hosp` −10000 × multiplier) | 7, 12 only | yes `PlayerScoring.swift:22-23`; `%0.7i` negative `ScoreBarDraw.swift:125` | no — needs a unit test |
| pickups coin/exli/mult/shie | all | yes `Pickups.swift:27-38` | yes (1–4) |
| Photon Beam + `pbpo`/`pbps` power-up | 5–12 | generic weapon path yes | no |
| end set pieces ("bosses" = Level-family controllers, no boss type) | all | generic machine yes; every final controller has a timer-only path to Delete (bosses §4) | 1–3 to the level end |
| Mission Irises + storms (`miac/mipo/mimu/migc`, `mias/mips/pimu/migs`) | 12 | generic yes; chain untested | no |
| finale trigger, 1200 wait, mission bonus | 12 | yes (above) | no |
| level transition (fade, `FUN_100064d0` sector+1, sector 13 → none) | 2–12, finale | **no** — ◇ `LevelEnd.swift:121-143` ends the session; `DeimosSession.levelStart` is private to the session and runs only from `init` (`DeimosSession.swift:184-188`), `levelInfo` is a `let` (`:82`) | no |
| fade to black op | transitions | renderer yes (`Fades.swift`, `FadeKind.toBlack`), driver/headless handle any `.fade`; Core never emits it (◇) | no |
| level-start music at a transition | 2–12 | the session's `[.play(ammu), .stop]` (`DeimosSession.swift:207-215`) is exactly the original's in-session sequence for levels 2+ (only level 1's is a stand-in) | no |
| markers in `Deimos/Core/Sources` | — | `HeadlessRunner.swift:113` preconditionFailure (unexplained end — P3.1 adds ends); `LevelEnd.swift:121,123,138,142` ◇ Phase 3; `DeimosSession.swift:51,53` "Phase 3" (next-level branch, level `none`); `Spawn.swift:122,197`, `DeimosRenderer.swift:78,103,118,148`, `Fades.swift:39`, `CopyBits.swift:105`, `RenderLists.swift:28`, `Pixmap555.swift:19` programmer-error traps (data-shape traps are census-guarded: 872/0) | — |
**Films:** all four end by `.filmEnd` (`ReplayGateTests.swift:28,60`) — none reaches level complete (G+9). Traces: de01
reaches the level-end point at game time 4243 (score 11,050 → 25,050 in the tallies), de02 at 7798 (59,480 → 116,180), de03
at 9495 (34,920 → 57,520); each ends ~620 ticks later mid coin tally (money still 40/39/26). de04 never reaches it (scroll
top 210 at the end; one death at 4663). So sectors 1–3's accuracy tier/tally and part of the coin tally are witnessed;
**no film witnesses** the coin tally's end, G+9, any transition, a start at sector 1 → 2, sectors 5–12, Photon Beam, two
players, the finale. de02–de04 start their sector directly (1 life, that sector's weapons).

## 4. Proposed machine check for sectors 5–12 (no films)
- **What exists:** `HeadlessRunner` (`HeadlessRunner.swift:48-136`) runs any `SessionStart` keyless, bounded
  (`run(maxPasses:)`), optional render, `ReplayTrace` rows (game time, P1 state/score/lives/shield/money/mult, `rand()`
  draws, entities, groups, scroll top, paused, levelEnding); end reasons filmEnd / levelComplete / gameOver / bound, traps
  on anything else. It has **no key source** (always `HeldKeys()`), no player poke, no spawn census.
- **Why keyless alone fails:** an idle ship dies (sector 1: out at 1084; sectors > 1 start with 1 life), long before a
  3,120-row scroll plus pauses (sector 12 final pause alone 2,750–2,905 ticks).
- **Proposal (test bundle, like `DeimosReplayTests`, excluded from G2 for run time):** a loop over `DeimosSession`
  directly in the test target (`@testable`; `game` is `public internal(set)`) — no production seam needed:
  1. **god mode** each tick before the pass: in-game players `invulnerable = invulnerableSticky = true` (blocks shield
     loss, `PlayerLife.swift:143`); a smoke check, not fidelity — say so in the test comment;
  2. **pilot**: (a) passive (empty keys) and (b) scripted deterministic keys (fire air + fire ground held, left/right
     sweep period ~90, select tap every ~600) — (b) exercises weapons, power-ups, pickups, kills, Photon Beam at ≥ 5;
  3. per sector 1…12 from `SessionStart(sector: s, players: 1)`, bound 16,000 passes, assert: no trap; G+0x39 rises;
     after P3.1 the transition to s+1 happens (levels started 2, sector s+1) or, for 12, the session ends with the new
     finale reason; record (not assert) the level-end tick and the tally length;
  4. **census:** collect every spawned unit ID; assert spawned ⊆ the level's data closure (closure computed in Swift from
     the definitions: placed units + `*_ID` references + weapons by sector + PermObjects); report closure − spawned as
     information only (rule branches not taken are legitimate);
  5. one **campaign run** 1 → 12 (scripted pilot, god mode, bound ≈ 150,000) asserting levels started 13, G+0x0d, the §2
     finale ticks relative to T0, then session end; and one **2P** sector-1 run (both scripted) with a P2-out variant.
  Expected cost: ~3.5× the replay bundle's ≈29k passes per full campaign; keep the per-sector runs logic-only (no render).

## 5. The app (P3.6)
- Today: `DeimosController.swift:94-96` builds one driver with `SessionStart(sector: 1, players: film?.playerCount ?? 1)`;
  every session end (level complete ◇1, game over ◇2, Esc ◇3) → `DeimosDriver.idle` restarts at sector 1 with the ended
  session's prefs, Esc latched (`DeimosDriver.swift:203-215, 344-365`); a film restarts the same film.
- Minimal Phase 3: nothing in the app for transitions — Core's `levelCompleteStep` continues in-session (P3.1) and the
  driver already plays any `.fade(.toBlack, …)` op step by step; game over / Esc / **after the finale** stay ◇ restarts at
  sector 1 (Phase 4). Update the driver comment `DeimosDriver.swift:43-51` and `HeadlessRunner.reason` (new end: level
  `none` after sector 12, e.g. `.campaignComplete`; level complete no longer ends a non-film session).
- **Starting 2P before the menu (for the seat to rule):** (A) recommended — a ◇ launch argument `-players 2` parsed in
  `LaunchOptions` beside `-film`, feeding `SessionStart(players: 2)`; restarts keep it (driver already does); on the gate
  card as a stand-in replaced by the main menu's 2 PLAYER button / `2` key in Phase 4. (B) Bring the menu's `2` key
  forward — not possible without the menu (Phase 4). (C) DEBUG-only flag — Ben plays Release builds, so no.
  Same question for a `-sector N` start (the level select's job): not needed by the plan; Ben can play through from 1
  (the original's cheat word + LIFE/SHIELDS exist in the console) — rule it explicitly either way.

## 6. Open questions and risks (gate-3 card / owner only)
1. Player 2's keys: keypad 8/4/6/5 + End/Fwd-Delete/Page Down are the prefs defaults, but the OS X 1.0.6 consumer is
   unread (INDEX #14) — does Ben remember the second player's keys? Laptop keyboards have no keypad/End/PgDn: P2 may be
   unplayable on a MacBook until Phase 4's controls window or controller mapping.
2. P1 holding ⌘ (fire air) while P2 presses keys: AppKit key-up loss — hands-on check.
3. Duo feel: the shared view shift doubling/cancelling (faithful but surprising).
4. Finale look and sound: `acbo` ×15, `leen` once, 50 explosions, four irises opening twice with coin/points/multiplier
   storms, ~40 s (1200 ticks at 30/s) before the tally, then black and (◇) a new game at sector 1.
5. Not witnessable by any test: the original's real 2P keyboard path; the audible mix during the explosions; a human
   playthrough's pacing across 12 sectors (~12 × 3–4 min); hospital "war crime" penalty feel (−10,000 × multiplier).
6. Risk: P3.1 must restructure `DeimosSession.levelStart` (private, init-only) so `levelCompleteStep` (a `GameState`
   extension) can run it mid-pass, and `levelInfo` must become mutable (the appear music reads it) — the finale's end
   rides on that.
7. Risk: entity pool pressure in the finale (50 explosions + 8 storms) and sector 11/12 set pieces — refused spawns are
   faithful, a trap is not; the sweep's census will show it.

## 7. Suggested tasks (one line each: what it asserts, from where)
- **2P-a Core tests** — `testDuoViewShiftDoublesAndCancels` (both left −2/tick, opposite 0, clamp −32 after 16 ticks;
  `10029504..10029524`, `FUN_100100b0`); `testDuoRespawnAtMultiStart` (P1 dies with P2 out → reappears at (104,330);
  `10029d00..10029da0`); `testDuoOneOutGameContinues` (P2 out, no `nogo`, running; `10006c3c..10006c7c`);
  `testDuoBothOutGameOver` (`nogo` once, running clears at +111); `testDuoLevelStartDrawsPerInGamePlayer` (`rand()` draws
  +2 vs +1 with P2 out; `10026a9c`); `testDuoScoreBarBothActive` (P2 record active, P2 elements at R8–R15/flli 114… rects,
  icons drawn; hud §8); `testDuoMissionBonusPaysBoth` (+1,000,000 each, raw; `10007c88..10007cd0`).
- **2P-b App/Host** — ◇ `-players 2` in `LaunchOptions` + `DeimosController` start; `testRestartKeepsPlayerCount` in
  `DriverTests` (newSession after game over has `players == 2`; `DeimosDriver.swift:345`). App untested (A3 precedent).
- **FIN-a** `testFinaleTimelineFromNoal` (le09 state, levels started 12, god mode, bound 3,000: `noal` T0; `acbo` at
  T0+6k k=0…14; `12gc` spawned T0+90; `noal` S5 T0+92; `aieg` requested T0+95, 50 members, 50 R(5,6) draws; `leen` once
  T0+102; `miof` at T0+395, 464, 534, 604, 675, 744, 814, 884; `12gc` deleted T0+955; each iris leaves S0 after its flag;
  tally state 1 → 2 at T0+1201) — §2 + data.
- **FIN-b** `testFinaleEndsSessionAfterTally` (after P3.1: G+9 → `.stop`, `tran`, `.fade(.toBlack, …)`, levels started 13,
  game time 0, appeared false, no `.present` after the fade, running false, music ends `.stop`; `100064d0..100066c8`);
  `testAllLevelsFlagSurvivesToSessionEnd` (G+0x0d still 1 at session end for the Phase-4 result, `10005c08`).
- **FIN-c** `testTwelveGcExplosionSetHasNoDelay` (data pin closing INDEX #64: S2 `aieg` delay/rate 0/0) + bank note.
- **NEG** `testHospitalKillSubtractsMultipliedScore` (−10,000 × mult, no extra-life change; scoring-bonuses §3.1,
  `10029a44..10029a60`) + score bar shows `-0…` (`ScoreBarDraw.swift:125`).
- **SWEEP** `testEverySectorReachesItsEnd` (12 runs × passive + scripted, god mode, bound 16,000, census ⊆ closure) and
  `testCampaignOneToTwelve` (one run, bound ≈150,000) in a separate bundle; `HeadlessRunner.reason` gains the finale end.
- **STAGE** gate-3 card: play 1 → 12 (cheats allowed), transitions (black ~0.55 s, `tran`, "Sector NN" notice), carry-over
  (P3.2), 2P via `-players 2`, the finale (items 4 above), ◇ list updated (1 replaced; 2, 3 + finale restart, 9 `-players`).
