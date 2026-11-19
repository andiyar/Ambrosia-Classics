# P4 grounding B — starting a game, coming back, scores, films (2026-11-20, read-only)

Sources: worktree focused-tharp-5561f7 (code = local main 68b93b6, Phase 3 closed). Listing
`~/Developer/Ghidra/deimos/proj/disasm-review3-all.txt` (wins over the dump); dump `ghidra/deimos/Deimos_pef.decompiled.c`; bank
`front-end.md` §1–§4, §10; `loose-ends-session.md` §2, §3, §7; `engine-loop.md` §2, §3, §6, §7, prefs table; `timing-frame.md` §2.5, §7;
`app-pak-music-library.md` input rows; data `Resources/Deimos/Data/{Paks/Game.pak,Paks/Interface.pak,Local/film}`. Labels: HIGH = listing or
data read this session or listing-quoted in the bank; MED = dump/bank only or inference; LOW = guess. Times: Mac ticks (TickCount, 60.15 Hz)
for front-end waits, game ticks (30.07 Hz) inside the session.

## 0. Premise checks (the brief vs the listing)
- **There is no idle-started attract mode.** `FUN_10024de0` (demo) has exactly two callers: the DEMOS button dispatch `10022d8c` and the `D`
  key `10023cec`; `FUN_100234d0` has six (`10024d94/dc4/df4/e24` buttons+keys, `10024eb0` scores `N`, `100250a8` credits `N`). The menu idle
  loop has one timer, the copyright flip (F68 = 240). `G+0x24` is the **demo cycle counter**, not an idle counter. [HIGH — call census]
- **There is no replay button.** "Last Film" is the undocumented `F`/`f` key only (`10023d14 bl 0x10024e10` → `FUN_100234d0(1,1)`), no
  button flash (front-end §2.8). [HIGH]

## 1. Start a game and return to the menu — `FUN_100234d0(mode, players)` (listing `100234d0..10023af8`)
mode 0 = play (players 1/2), 1 = Last Film (`last`), 2 = Demo. `r27` = film (mode ≠ 0), `r25` = started later (sector > 1), `r26` = a game
runs, `r24` = quit flag, `r23` = someone qualifies for the table.

### 1a. Menu → session [HIGH unless noted]
| # | address | step |
|---|---|---|
| 0 | `10022d50` / `10022e20` | the menu resets its flip timer t0 **before** a click's action but **after** a key's action returns (see §3 note) |
| 1 | `100234f8..10023524` | zero the 8-byte request; +5 = mode; mode 0: +4 = players, **pause** music `FUN_10048220(1)` (`inmu`) |
| 2 | `1002352c..10023550` | window current; About off `FUN_10049320(0)`; present full screen `FUN_1000bc60`; hide cursor `FUN_1000b6e0` (MED role) |
| 3 | `10023558` | menu element fade-out `FUN_10025890`: 32 steps × F160 (1) ≈ 32 ticks |
| 4 | `1002355c..10023574` | `tran` gaso 3 (priority 0x4b, volume 100, multiple 1) — **every mode** |
| 5 | `1002357c..10023584` | fade to black `FUN_1000b9a0(scr, 0)` ≈ 33 ticks (full-screen presents) |
| 6 | `1002359c..100235b8` | mode 0 only: music stop `FUN_10048120(0)`, `ammu` looped |
| 7 | `100235c4..10023604` | mode 0 only: ISp resume, mouse off `FUN_1004a990(0)`; level select `FUN_1002e310(&sector)` (other appendix); `none` (Esc) → r26 = 0; sector > 1 → r25 |
| 8 | `10023608` | ISp suspend `FUN_1004a9c0` (app-pak-music-library input rows; replica: nothing) |
| 9 | `10023610..10023638` | zero the 0x18-byte result; if r26: `FUN_100051a0(&request, &result)` — the session |
Session start inside `FUN_100051a0` (built, Phase 1–3): film → `FUN_100069b0` (`100056d0`), **load failure → `FUN_100064c0` and return with
the result still zero** (`100056dc..100056f0`, no loop, no Last Film); else `srand(TickCount)` + recorder header (`100057c8..100057ec`).
Dead time click → level select live ≈ 32 + 33 + 9 = 74 ticks (front-end worked example). Films skip 6–7 and go straight to the session.

### 1b. Session end → menu (tail `10005ab8..10005ca0`, then `10023640..10023ae8`) [HIGH]
| # | address | step |
|---|---|---|
| 1 | `10005ad0..10005ae4` | not a film: halt every effect `FUN_100476a0`, music stop `FUN_10048120(0)` (built: `DeimosSession.swift:319-322`) |
| 2 | `10005af0..10005af8` | end session (`FUN_100302b0` FlushEvents — MED role); ISp suspend |
| 3 | `10005b00..10005b18` | **G+0x20 == 0 (not a film) → `FUN_100095b0(film, 'last')`**: Last Film written to disk at once + tag index rebuilt (§4) |
| 4 | `10005b20..10005c18` | free the film; fill the result (§1c); G+0x0e cleared |
| 5 | `10005c20..10005c98` | `FUN_1000f990` (unread, G_Background residue); resize the terrain buffer D+0x6c to 640×480×16 (`FUN_10009d70`); log; controller dtor |
| 6 | `10023640..10023670` | ISp suspend; result +0x16 (unregistered cut) → fade (scr,1) + advert — **never in the registered build** |
| 7 | `10023674..10023764` | gates (§1d): pref 3 via `FUN_10004ac0(3, best)` into the **live** prefs |
| 8 | `10023768..10023774` | level select cancelled and mode 0 → music stop (`ammu`) |
| 9 | `1002377c..1002378c` | a game ran (r26) → fade to black `FUN_1000b9a0(scr, 1)` ≈ 33 ticks (game-layout presents) of the last game frame |
| 10 | `10023794..10023834` | TGA `back` into both buffers +0x68 / +0x6c, free; fade in `FUN_1000ba70(scr, 0)` ≈ 9 ticks |
| 11a | `1002383c..10023974` | **table path** (no cheat, !r25, !film, !quit, r23): `tran` (0x32, 100, 1); FlushEvents; About on; `FUN_100214c0` (§2); show cursor; menu bar `FUN_100491d0`; `back` again; unhilite all; element fade-in `FUN_10025840` ≈ 32 ticks; redraw; present; FlushEvents; `b6 = 1` |
| 11b | `10023978..10023ae4` | **otherwise**: `back` into both buffers; present; not a film → `tran` (0x32, 100, 1); menu bar; `back`; unhilite; element fade-in ≈ 32; redraw; About on; show cursor; not a film → `b6 = 1` |
| 12 | menu `10022b9c` | next menu pass: `b6` → t0 = now; stream still playing → resume, else `inmu` looped from the start |
Per end kind (all HIGH except where marked):
| end | inside the session | then |
|---|---|---|
| game over | `nogo` + 111 game ticks (loose-ends §4) | Last Film; gates; 33 + 9 fades; table if qualified; `inmu` restarts (stream was stopped); name entry is **silent** |
| Esc (pref 8 = 0: at once; = 1: 16 frames, timing-frame §2.5) | `FUN_100064c0` clears G+8; the pass still ticks and draws | **same as game over**: Esc does not set the quit flag, so pref 3 and the high-score table **do** run (gate reads `b8` only, `10023674`) |
| finale (G+0x0d) | screen already black (appeared 0, Phase 3 grounding B §2b) | best = 12 with no −1 → **pref 3 = 12** (only reachable from a sector-1 start); 33 ticks of black, `back` fade-in; table row's sector name = le09 "Carthage"; no credits |
| level select Esc | no session | no fade at step 9; `back` fade-in 9; 11b with `tran`; `inmu` restarts |
| film (demo or last) | ends by mouse button, Esc, P1 runs out, level complete, game over (§3) | no Last Film, no gates, no halt/stop; fades 33 + 9; 11b **without** `tran`, `b6` not set → `inmu` plays on uninterrupted (INDEX #54) |
| film load fails | result zero, no loop | fades 33 + 9 and the menu (a ~42-tick black flash); reachable only with no `Demo`/`last` record |

### 1c. What the session hands back (`10005b38..10005c18`) [HIGH]
| result | value | Swift source today |
|---|---|---|
| +0/+1 slot exists | `FUN_10026c90(p) != -1` — **1 for both players even in 1P** | always true |
| +4/+8 score | `FUN_100299f0` decoded, else 0 | `players[i].score` (decoded) |
| +0xc/+0x10 level | player +0xc0 (level at its last level start; out players keep the level they died in — `Player.swift:301` guard) else `none` | `players[i].levelRef` `Player.swift:191` |
| +0x14 all levels | G+0x0d | `game.flags.allLevels` `GameFlags.swift:22` |
| +0x15 cheated | any player +0xbd | `players[i].cheated` `Player.swift:189` |
| +0x16 unregistered cut | G+0x0e | always 0 (registered build) |
Also needed by the front end: the session's prefs (`DeimosSession.prefs`, stand-in 6) and the recorded film image (§4).

### 1d. Post-game gates (`10023674..10023764`, `1002383c..10023868`) [HIGH]
`best` = max over present slots with **score > 0** of sector(level); finale ? best : best − 1; at least 1; written iff not quit, not cheated,
not a film, start sector 1, best > pref 3. Qualifier = any present slot with `FUN_10021470(score)` (signed score > 15th entry); tested on every
slot regardless of score > 0. Table path additionally needs not quit / cheated / film / later start.

### 1e. Swift today / what a task must add
- Exists: one session at a time, ended → ◇ restart at the launch's sector with the ended session's prefs and an Esc latch
  (`DeimosDriver.swift:222-235`, `newSession` `:399`, latch `:196`, `:234`); launch args `-film/-players/-sector`
  (`DeimosMain.swift:19-36, 62-71`, `DeimosController.swift:76-106`); prefs always `.fresh` (`DeimosController.swift:105`); fades
  `.fade(FadeKind, PresentKind)` and `.loadImage` exist (`RenderOp.swift:24-56`), and the driver already runs a blocking fade step by step.
  No `SessionResult`; `HeadlessRunner.reason` derives the end kind after the fact (`HeadlessRunner.swift:110-118`).
- Add: `SessionResult` built at session end (table above); the start/return sequence as a resumable screen (steps 1a.1–9 and 1b.6–12) with
  new waits the driver lacks ("element-list fade 32 steps", "music pause/resume/stop with or without restart via b6"); the `b6` menu-music
  rule; mode 1/2 session starts from a `Film` chosen by §3/§4; remove ◇ restart, `-players`, `-sector` (and `-film`, design switch row).

## 2. High scores
### 2a. Storage and defaults [HIGH]
Prefs record (0x34f0, `_DAT_100def40`): names +0x10f8 (15 × 21, ≤ 20 chars), player names +0x1233 / +0x1248 (21 each, "Player %i"), scores
+0x1260 (15 × i32; disk = value + 0x024A8903), dead +0x129c (disk = value − 0x5969FBD0, never written), sector names +0x12d8 (15 × 32,
"New Atlantis"); int pref 3 at +0x74. Defaults `FUN_10004ae0`: 15000 … 1000 step 1000; Mars, Supercobra, Neurotik, El B, Dilvish, Sam,
Vodi, Fisj, Alex, h'biki, Goldenberry, Leadfeather, Troll, Thomas, Electrofryer. **Erase (Option-click SCORES) runs the same routine: it
also resets both player names to "Player 1/2"** (`FUN_10004ae0` first loop) — live prefs only, disk at quit. Disk write only at shutdown
(`FUN_10000630 → FUN_100045f0`); a crash loses the session's scores. Swift `DeimosPrefs.swift:17-25` holds every table field and
`.fresh` (`:46-61`) matches the defaults; no file I/O, no raw image of the unparsed ≈0x1000-byte key/ISp block.

### 2b. Insertion `FUN_100214c0(result)` (listing `100214c0..10021940`) [HIGH — bank §3.1, simulated]
Two prefs copies A, B. idx = first row with score > A[i] (strict; ties rank below). Both qualify: idx1 > idx2 → idx1 += 1; then idx2 ≥ idx1 →
idx2 += 1; ≥ 15 → −1. Shift for P1 from B, B = A, shift for P2 from B; write rows {score, name from A+0x1233/+0x1248, `FUN_100120f0`(level)
name}; name entry P1 then P2. Quirks to reproduce: (a) P2 above P1 in a different slot → the row just below P1's slot is lost, the next
duplicated; (b) both between the same two rows → P1 first even when lower. In 1P the P2 slot (score 0) is tested and never qualifies.

### 2c. Name entry `FUN_10021bd0(player, slot, prefsA, fromGame = 1)` [HIGH — bank §4.3 + dump re-read this session]
Clear to black, `back`, row name seeded with the remembered name (**edit buffer pre-filled, e.g. "Player 1"**), list (edit 1, dim 1, slot,
player; edited row cyan FMT 14/17/20 + the player's ship at (73, rowY + 7)), present, no fade; gaso 9 (`none`, silent). Loop: cursor `_`
(pgsl 7) blinks every F83 = 10 ticks once F82 = 30 ticks have passed since the last key; any key hides it. Events `FUN_10048c90`: **keyDown
and autoKey both count** (`0 < code < 4`) → held keys repeat into the name; Return 0x0d / 0x0a confirm; BS 0x08 delete (+ gaso 2 if
non-empty); ctype & 0xdc (MSL table `0x100f0f94`) → append if < 20 (gaso 0 `clic`) else gaso 15 `shwa`; Tab/Esc/Enter/arrows silent; clicks
ignored. Confirm: gaso 4; eggs tested on an uppercase copy, last match wins: BIKI → "Filthy Communist", DILVISH → "Just Ship It, Baby",
SUPERCOBRA → "Munkis Rool J00", PYTHOS → "Leonard Cohen Rules J00", FISJ → "Daikajinn!!"; empty → "Jar Jar Must Die"; otherwise the name
**as typed** (case kept); stored in the row and as the remembered name; rebuild without hilite/ship. Exit on any key/click or confirm +
F79 = 25 ticks; `FUN_100047f0(A)` copies A into live prefs; restore +0x6c → +0x68; present. No timeout and no way out before Return.

### 2d. Scores screen `FUN_10021950` (from SCORES / `S` `H`) [HIGH — bank §4.1]
Clear black, `back`, list (edit 0, dim 0), present, no fade; exit after F78 = 600 ticks, on a click (silent), or any key/autoKey; `N`/`n` →
gaso 2 and a 1P game via `FUN_100234d0(0,1)`. Then the caller redraws the menu with the 32-step element fade-in. Layout front-end §4.2.

### 2e. Swift today / what a task must add
Exists: the table fields and defaults. Add: `HighScoreTable.insert(result)` (pure, with both quirks), name-entry editor state machine
(blink clock, key codes incl. auto-repeat, eggs, 20-char rule), scores-screen state, the list layout (front-end §4.2), prefs file I/O at the
ruled Application Support path (design 2026-10-06 §7.5) with obfuscation, read at boot / written at quit.

## 3. Films from the menu (DEMOS / `D`)
| step | address | fact | label |
|---|---|---|---|
| choose | `FUN_100069b0` mode 2 (dump `4153`) | walk `film` tags in **tag-index order**, count those whose name contains "Demo" (`FUN_10057a30`, `_DAT_100e00f8`); take the one at position G+0x24, G+0x24 += 1; none found → G+0x24 = 0 and take the first, G+0x24 = 1 | HIGH |
| order | Game.pak zip order `film/Demo 01..04` (`zipinfo`); Local `Last Film` has no "Demo" | de01 le07 → de02 le06 → de03 le02 → de04 le08 → de01 … | HIGH |
| counter life | session reset `10005500..1000555c` stores G+0x08…+0x38, +0x44 — **not +0x24**; G zeroed once (`10005214`, first session) | persists across games for the app's life; first demo after launch = de01 | HIGH |
| load | `FUN_100094a0` (`FILM FAILURE` logs) → `FUN_10009680`: level, players → G+0x21, seed → `srand` | Swift `DeimosSession.swift:148-174` | HIGH |
| music | no stream call in film mode (#54); `tran` still plays at step 1a.4 | `inmu` runs under the fades, the film and back | HIGH |
| ends | per pass after the draw (`10005a1c..10005a48`): `FUN_10048e60` = `Button()` (`10048e6c`, any mouse button, live state, not an event) → `FUN_100064c0`; else P1 cursor > P1 frames (signed) → `FUN_100064c0`; Esc in the begin frame (`10005904`, not film-gated); level complete (`100071e8`); game over. **Keys other than Esc do nothing**; Caps Lock pause refused | HIGH |
| P2 | P2's frames never tested; a P1 that is out never reads again, so a 2P film whose P1 went out plays on until P2 runs dry and dies (game over) | MED (inference from §7 rules) |
| return | §1b "film" row; the mouse-down event is flushed by `FUN_100302b0` (MED), so no click leaks to the menu | MED |
| flip glitch | DEMOS by **click** reset t0 before the film; no `b6` after it → on the first menu pass t0 + 240 is long past → the copyright/banner flips at once. By `D` key t0 is reset after return → no flip | HIGH |
Swift today: films play only via ◇ `-film deNN` (`FilmLookup.swift:16-20`), restart the same film; the film end ignores the mouse
(`DeimosSession.swift:298-301`, ◇ stand-in 8); `GameFlags` does not keep +0x24 (`GameFlags.swift:8`). Add: the demo cycler over
`TagIndex.records` (pure, counter owned by the front end), a mouse-button field the session reads at `10005a24`, `inmu` alive across films.

## 4. Last Film — record, save, replay
### 4a. Record format (film object = 0x14 runtime header + 0x9d68 image; file = the image) [HIGH — dump `5005..5260`, engine-loop §7]
| file off | size | written by | value |
|---|---|---|---|
| 0x00 | 4 | ctor `FUN_10009390` (per session, image zeroed) | 0x2715 |
| 0x04 | 4 | `FUN_10009710` (`100057ec`) | seed = the session's `TickCount` |
| 0x08 | 4 | `FUN_10009710` | **start** level 4CC (request +0) |
| 0x0c | 1 | `FUN_10009710` | players (1/2); bytes 0x0d–0x0f zero |
| 0x10 / 0x4ebc | 4 | `FUN_10009710` = 0, then `FUN_10009830` each recorded tick | frames = cursor + 1 |
| +4 | 4 | `FUN_10009710` = **0 (raw, not biased)**, then each tick | decoded score + 0xb3ac2 at that tick |
| +8 | 4 | `FUN_10009710` = `none`, then each tick | `FUN_10005cc0` = G+0x18, the **current** level |
| +0xc… | 1/tick | `FUN_10009830` | bits 0 left, 1 right, 2 up, 3 down, 4 fire ground, 5 fire air, 6 select |
Recorded only in life state 4 (`FUN_1002a3a0` → `1002a42c`), cap 20000 ticks (unsigned `< 20000`, then frozen) ≈ 11 min; console open →
zeros recorded; not recorded: RNG, cheats (replay refuses them → a cheated game's Last Film desyncs), pause, speed. A multi-level game keeps
recording into one stream; the replay ends at the start level's completion (`100071e8`). An empty P2 block reads score raw 0 / level `none`
(matches the shipped Last Film = de01, byte-identical, data-census).
### 4b. Save and replay [HIGH]
`FUN_100095b0(film, 'last')`: copy 0x9d68 bytes; `FUN_100025b0('film','last', data, "Last Film", 1, 1)` → `Data:Local:film:Last
Film[last].film` (type/creator `Data`/`Deim`), **immediately**, then tag-index rebuild `FUN_100016c0(0,0)` so Local overrides. After every
non-film session (game over, Esc, finale); never after a film or a cancelled level select. Replay = `F` key → mode 1 → tag
`last`: header level + players + seed, fresh per-session set-up (1 life unless the level is sector 1). At first launch `last` is the
shipped de01 copy. A game Esc'd before P1 first reached state 4 saves frames 0 → its replay ends at P1's first state-4 tick (≈ 56 ticks).
### 4c. Swift today / what a task must add
`Film` is **read-only**: `init(data:)` only, `let` fields, `Block.inputs` holds exactly `frames` bytes (`Film.swift:37-78`); no recorder;
`readPlayerInput`'s live branch (`PlayerUpdate.swift:87-89`) is the recording point (`1002a40c..1002a42c`); `TagIndex(dataDirectory:)`
scans one `Local` root (`TagIndex.swift:94-118`) and `DeimosAssets.index` is built once. Add: a `FilmRecorder` (image + cursors) in
`GameState`, created at set-up when not a film, written in that branch with `players[i].score` and `flags.level`; `Film` encode (or a raw
image type both sides share); save to `…/Deimos Rising/Local/film/Last Film[last].film` (design §7.6) and an index overlay/rebuild so `last`
resolves to it; the F key path.

## 5. The quit flag `DAT_100e01b8` (r2−0x6178) and the mouse
| access | address | role | label |
|---|---|---|---|
| store 0 | `100229d8` | menu entry (once per app life) | HIGH |
| read | `10022ac0` | menu pass: set → QUIT flash `FUN_10024f90` (sets leave flag `b9`), then **store 0** `10022ad4` | HIGH |
| read | `10022bf4`, `10022d20` | hover and click handling only while clear | HIGH |
| store 1 | `10022ed4` (`FUN_10022ed0`, from `10022ce8` event 8 and the Quit AppleEvent handler `10049c70`), `10023368` (File ▸ Quit), `10023c7c` (`Q`) | setters — all reached only from the menu loop's event pump | HIGH |
| read | `10022ee0` getter, called at `100490f8` | event pump returns 8 when an AppleEvent set it | HIGH |
| read | `10022f8c` | Caps Lock wait: while Caps is down or the app is suspended, flag set → exit "quit" **skipping the music resume** (`10022fb0`) — dead, nothing sets it in play (no event pump there) | HIGH |
| read | `10023674` | post-game gate → **always clear in 1.0.6**; Esc never sets it | HIGH |
So in the original ⌘Q cannot quit during play, pause, name entry or the scores screen (`FUN_10048c90` drops event 23 — critic wave 3, MED);
a Quit AppleEvent waits for the menu. The replica's app menu has ⌘Q live everywhere (`DeimosController.swift:213-230`) — and ⌘ is P1's
fire-air key. Mouse: the session needs only `Button()` per pass (film end); the front end needs mouseDown events (scores, name entry exit,
credits, advert), the live position (hover, `GetMouse`) and `Button()`/`StillDown` (click tracking, level select `1002e998..1002eafc`).
`HeldKeys` (`HeldKeys.swift:7-19`, LOCKED, grows by addition) has none; built at `DeimosController.swift:282`.

## 6. Where a `FrontEnd` could sit (options, not chosen)
| option | shape | cost / risk |
|---|---|---|
| A — FrontEnd owns the session | `FrontEnd` (DeimosCore) is the driver's only client; a `.game(DeimosSession)` screen inside it; on `sessionEnded` it builds `SessionResult`, applies gates, moves on | driver becomes screen-agnostic; the ◇ restart code goes; session API unchanged; FrontEnd must forward pass outputs and the session's cue/fade split |
| B — siblings under the driver | driver holds `FrontEnd` and `DeimosSession?`, switches on a mode; FrontEnd gets `SessionResult` + prefs back | least change to `DeimosDriver`'s pass loop; two state owners for prefs (live vs session copy) to keep in step |
| C — FrontEnd in DeimosHost | screens with waits in the driver; Core keeps pure parts (table insert, name editor, demo cycler, recorder) | contradicts the design table (`FrontEnd` in DeimosCore); harder to unit-test headless |
All three: FrontEnd owns live prefs, G+0x24, `b6`/`b8`/`b9`, flip timer; the session gets a prefs copy at start and returns it.

## 7. Open questions and risks
(a) Facts still unread
1. `FUN_100025b0` / `FUN_10002640` save path: meaning of args (1, 1), failure behaviour (locked/full disk) — `0x100025b0..0x10002700`.
2. `FUN_100016c0(0,0)` rebuild side effects beyond the index (INDEX #1 jump table) — `0x100016c0..` + table.
3. MSL ctype bytes for 0x80–0xFF at `0x100f0f94` (which Mac Roman letters a name accepts; how to map modern typed Unicode).
4. `FUN_1000f990` at session end (`10005c20`) — G_Background residue `0x1000f990..0x1000f9c0`.
5. `FUN_100302b0` FlushEvents and whether a pending Quit AppleEvent survives a game (Toolbox: FlushEvents leaves high-level events — MED).
6. `FUN_1000b6e0` / `FUN_1000b780` cursor hide/show in the start/return path (display-window-present §, labels MED).
(b) QUESTIONS FOR BEN
1. ⌘Q: the original cannot quit during play, pause, name entry or the scores screen; the replica quits at once (⌘ is also fire-air). Keep ⌘Q live everywhere, or ignore it outside the menu as the original did?
2. High scores reach disk only when the app quits (a crash or force-quit loses that session's names). Faithful, or also save after each name entry?
3. Controller (Q-E): the original ends a film only by mouse or Esc — should a pad button end a demo?
Risks
1. Driver rework (§6) is the largest change: every front-end wait (32-step element fades, 600/25/10-tick waits, wait-for-event) must become a resumable yield like the existing fades.
2. Recorder fidelity: score must be taken at the read inside the player update (P2's after P1's update); the de01 re-record test below pins it.
3. Text input: name entry needs keyDown **and auto-repeat** charCodes; `HeldKeys.typed` is documented as no auto-repeat.
4. Tag index is immutable and single-root; the Last Film overlay from Application Support needs a second Local root or an override map.
5. Prefs file: `DeimosPrefs` drops the ≈0x1000-byte key/ISp block; a byte-exact round trip of an original prefs file needs the raw image kept.

## 8. Suggested tests (name — assertion — bound/source) and Ben-only checks
- **Start/return** — `testReturnAfterGameOverSequence` (op/cue order: halt, stop, Last Film saved, fade toBlack(gameLayout) 33, `back`, fromBlack(full) 9, `tran` 0x32, element fade-in, `inmu` play on the first menu pass; `1b` table); `testEscStillEntersHighScores` (Esc-ended game with 20,000 → name entry; `10023674`); `testFilmReturnKeepsMenuMusic` (no stop/play cue, no `tran` on return; #54); `testCancelledLevelSelectNoFadeOut` (no step-9 fade, `inmu` restarts); `testFinaleSetsPrefThree` (allLevels → pref 3 = 12; `10023710`); `testLaterStartNoPrefNoTable` (sector 3 start); `testCheatSkipsGates`; `testPrefThreeBestMinusOne` (P1 le02 12,500, P2 le06 600 → 2; loose-ends worked example).
- **Scores** — `testInsertTwoPlayerQuirks` (the four simulated rows of loose-ends §3.1); `testInsertTieRanksBelow`; `testNameEntryEggs` (each egg, last-match order, empty → Jar Jar, case kept otherwise); `testNameEntryTwentyCharsAndRepeat` (21st char → gaso 15; auto-repeat appends); `testNameEntryCursorBlink` (hidden < 30 ticks idle, toggles every 10); `testEraseResetsPlayerNames`; `testPrefsFileRoundTrip` (obfuscation ±0x024A8903 / −0x5969FBD0, version 0x2714, 13,552 bytes).
- **Attract** — `testDemoCycleOrderAndWrap` (de01…de04, de01; counter persists across a normal game); `testMouseButtonEndsFilm` (ends that pass, no `.stop`); `testKeysDoNotEndFilm`; `testEscEndsFilm`.
- **Last Film** — `testRecordReproducesDemo01` (non-film session, seed 0x469c2, sector 1, de01's 4,809 bytes fed as P1 keys, Esc on the next begin frame → recorded image == de01's 40,296 bytes; strongest pin); `testRecordRoundTrip` (scripted 3,000-pass 2P run recorded, replayed → same per-tick trace for the start level); `testFramesCapTwentyThousand`; `testNoRecordInFilm`; `testEmptyFilmEndsAtFirstAppear` (frames 0 → ends ≈ 56 ticks).
- **Quit/mouse** — `testHeldKeysMouseDefaultsUp` (seam addition compiles old call sites).
- Ben only: the feel of the 74-tick start and ~1.2 s return (fades, `tran` loudness, silence during name entry); typing a name (repeat rate, `_` blink); DEMOS cycling over a long idle; the copyright flip after a clicked demo; whether ⌘Q / pad behaviour matches his memory.

## 9. Corrections to docs/deimos found
1. front-end.md §2.7 (SCORES erase) — `FUN_10004ae0` also resets both player names to "Player %i" (dump `2842`, first loop).
2. front-end.md §8 — "the loop also ends if `b8` was already set" lacks the loose-ends §2.3 / INDEX #48 "dead in 1.0.6" note; that exit also skips the music resume (`10022fb0`).
3. loose-ends-session.md §2.1 — on a film-load failure `FUN_100051a0` returns before filling the result (`100056dc..100056f0` → `10005ca0`), so the caller sees all zeros.
4. front-end.md §2.6 — t0 is reset before a click's action (`10022d50`) but after a key's (`10022e20`); with no `b6` after a film this gives an immediate copyright flip after a clicked demo.
5. front-end.md §4.3 / loose-ends §3.2 — name entry accepts autoKey (event 3) as well as keyDown (`0 < code < 4`); the confirmed name keeps its case (eggs test an uppercase copy only).
6. engine-loop.md §2 — the post-game summary omits the quit-flag and film gates (superseded by loose-ends §2.2; MED there).

## 10. Sizes and shared code
| subject | size | shares |
|---|---|---|
| 1 start/return + `SessionResult` + FrontEnd placement | large | the screen/yield machinery all other screens use; gates feed 2 |
| 2 scores (insert, name entry, scores screen, prefs file) | medium–large | list layout with the scores screen; prefs file with config dialog (other appendix) |
| 3 demo films | small | mode-1/2 start path with 4; mouse seam with 5 |
| 4 Last Film (recorder, encode, save, index overlay, F key) | medium | `Film` image with 3; Application Support folder with the prefs file |
| 5 quit flag + mouse seam | small | `HeldKeys` addition used by 3 and the menu/level-select appendices |
