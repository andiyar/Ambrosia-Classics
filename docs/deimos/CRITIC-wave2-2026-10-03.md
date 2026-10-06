# Deimos Rising RE bank: wave 2 completeness critic (2026-10-03)

This is a read-only critic. **Inputs:** every `docs/deimos/*.md` at `c79d5e2`, except the REVIEW/CRITIC/FIXPASS/REPORT records. That is the old bank, wave 1 (fix-passed, `ecf565d`) and the nine wave-2 files. I also used `$W/sizes.txt`, `callers.txt`, `profile.txt`, `inventory.txt`, the decompile dump and the memory images.

**Method:** the same as the predecessor's. A script reads every Markdown table row whose first cell names a `FUN_` and that carries a HIGH/MED/LOW. Multi-function rows count for each function. Where files disagree, the best label wins; worst-label totals are also given. "Before" means all files except the nine wave-2 files, which were the only files that changed. Labels given only in prose are not counted.

Known artefacts:
- `FUN_10018670` is counted HIGH from a combined "HIGH / LOW" row. Its true label is LOW.
- `FUN_1000db90`/`FUN_1000df00` are MED in front-end.md §5.2 prose, but count as none.

Scratch script: `census.py` in the session scratchpad.

## 1. Label counts

| scope | fns / lines | | HIGH | MED | LOW | none | coverage, lines: H+M / any |
|---|---|---|---|---|---|---|---|
| gameplay 0x10011000–0x10044000 | 563 / 29 937 | before w2 | 197 | 186 | 20 | 160 | 75.5 % / 76.9 % |
| | | **after w2** | **335** | 146 | 28 | **54** | **88.7 % / 92.7 %** |
| | | after, worst label | 251 | 221 | 37 | 54 | |
| gameplay, ≥ 40 lines | 230 | before / after | 93 → 155 | 78 → 43 | 3 → 11 | 56 → 21 | 79.6 → 89.9 % / 80.2 → 93.8 % |
| game code 0x10000000–0x1004b400 | 979 / 44 851 | before w2 | 260 | 278 | 26 | 415 | 66.2 % / 67.6 % |
| | | **after w2** | **459** | 247 | 29 | **244** | **81.3 % / 84.1 %** |
| | | after, worst label | 357 | 334 | 44 | 244 | |
| game code, ≥ 40 lines | 330 | before / after | 121 → 201 | 102 → 70 | 4 → 11 | 103 → 48 | 73.4 → 86.3 % / 74.0 → 89.1 % |

"Before" HIGH is 197, not the wave-1 critic's 255, because the review-wave-1 label audit moved 68 HIGH to MED. Unread lines (none + LOW, all sizes) after wave 2: gameplay 3 394 (11.3 %), game code 8 376 (18.7 %).

Per family (H/M/L/–). "Unread" = none+LOW lines, before → after:

| family | span | fns | before | after | unread |
|---|---|---|---|---|---|
| boot/app/errors/list | 00000–016c0 | 38 | 1/13/0/24 | 3/11/0/24 | 510 → 510 |
| U_Pak | 016c0–04640 | 35 | 6/16/0/13 | 8/17/0/10 | 330 → 246 |
| U_Prefs | 04640–051a0 | 12 | 8/1/0/3 | 9/2/0/1 | 202 → 12 |
| G_Game | 051a0–095b0 | 35 | 12/12/2/9 | 23/10/0/2 | 388 → 82 |
| G_Film | 095b0–09ac0 | 14 | 8/2/0/4 | same | 57 |
| PixelBuffer/Window | 09ac0–0ad90 | 33 | 1/2/0/30 | 1/4/0/28 | 653 → 603 |
| M_Display | 0ad90–0d010 | 43 | 0/6/0/37 | 2/8/0/33 | 941 → 765 |
| G_Text | 0d010–0fbc0 | 26 | 5/4/0/17 | 9/6/0/11 | 1284 → 736 |
| G_Background | 0fbc0–10cf0 | 21 | 6/10/0/5 | 7/10/0/4 | 72 → 55 |
| Registration/Config | 10cf0–11000 | 7 | 0/4/0/3 | 1/3/0/3 | 41 |
| Level/GameObject/Entity | 11000–18740 | 80 | 31/45/3/1 | 45/33/2/0 | 121 → 36 |
| **Sprite + Blit** | 18740–1f7c0 | 72 | 12/1/0/59 | 29/1/9/33 | **3262 → 2421** |
| Resource/Image | 1f7c0–21190 | 23 | 9/3/0/11 | untouched | 323 |
| Scores | 21190–23040 | 13 | 2/6/0/5 | 12/0/1/0 | 75 → 31 |
| Interface/Credits | 23040–26100 | 43 | 0/6/0/37 | 35/6/1/1 | 1163 → 35 |
| Player | 26100–2a660 | 60 | 39/17/4/0 | 42/14/4/0 | 71 |
| Debris | 2a660–2ab20 | 9 | 0/2/0/7 | 4/3/2/0 | 140 → 25 |
| WeaponDefs, PlayerDefs, WeaponHandler, UnitDefs | — | 111 | — | ≥ 97 % H/M | 0 |
| Console/Message | 2cef0–2e310 | 21 | 0/6/0/15 | 18/1/2/0 | 537 → 46 |
| LevelSelection | 2e310–31400 | 32 | 7/18/7/0 | 16/13/3/0 | 148 → 92 |
| ScoreBar | 31400–32e60 | 16 | 0/2/0/14 | 13/3/0/0 | 898 → 0 |
| EntityGroup | 32e60–39280 | 50 | 24/23/3/0 | 30/17/3/0 | 73 |
| U_Manager | 3a780–3ade0 | 10 | 0/1/0/9 | untouched | 220 |
| Math/collision | 42100–432d0 | 19 | 13/3/3/0 | 16/2/1/0 | 57 → 21 |
| Particle | 432d0–44000 | 4 | 0/2/0/2 | 4/0/0/0 | 249 → 0 |
| particle tail / file / PICT utilities | 44000–467c0 | 48 | 3/1/0/44 | 7/4/0/37 | 1446 → 1067 |
| MotionBlur + RNG | 467c0–47160 | 11 | 0/0/1/10 | 6/4/1/0 | 428 → 12 |
| M_Sound | 47160–47e40 | 18 | 1/5/2/10 | 15/3/0/0 | 297 → 0 |
| M_Music + streamer | 47e40–491d0 | 27 | 3/6/1/17 | 14/7/0/6 | 570 → 286 |
| M_Application | 491d0–49ca0 | 16 | 1/3/0/12 | 3/3/0/10 | 283 → 197 |
| unzip.c (library) [⚑ corrected (wave 3+4, 2026-10-04): custom zip reader `49ca0–4a8a0` (module string "unzip.c", not Gilles Vollant's minizip) + Input/InputSprocket module `4a8b0–4b2a0` + MW registrar `4b2b0`; app-pak-music-library.md §5] | 49ca0–4b400 | 32 | 8/7/0/17 | untouched | 313 |

Library callees reached directly from gameplay: 34 functions, 9 labelled. The other 25 are trivial or out of scope by ruling:
- `FUN_1004ee30` = abs, already named in units-movement.md prose.
- `FUN_1004d3b0` = delete wrapper (45 callers).
- `FUN_1004d648`/`d698` = empty stubs.
- `FUN_100d6040` = glue jump.
- 14 registration-integrity functions, called from `FUN_10028170`, `FUN_10026410` and `FUN_100269a0`.

**Verdict [HIGH, counts]:** wave 2 closed presentation as well. HUD, messages, console, front end, particles, sound and the motion blur are now ≥ 95 % labelled. The two largest unread blocks are the sprite blitter's pixel loops and the Mac/DrawSprocket/file plumbing.

## 2. Unread functions ≥ 40 lines (none or LOW after wave 2): 59 functions, 4 366 lines

| family | functions (lines; label) | callers | hypothesis [conf] |
|---|---|---|---|
| **B1: unscaled blit modes** | `FUN_1001db50`(89), `FUN_1001e0d0`(93), `FUN_1001e2b0`(101), `FUN_1001e4f0`(90), `FUN_1001e770`(97) | `FUN_10019570` | The dispatcher maps flags to modes: 1 → 1, 2 → 2, 4 → 3, else 0 (dump lines 109–169). `db50` is **mode 1 (fade) unclipped**. `e0d0`/`e2b0`/`e4f0`/`e770` are clipped modes 0/1/2/3, the twins of `d9f0`/`db50`/`dd20`/`df00` (all HIGH) [HIGH for the mapping, from dump branches]. My read of the `db50` decompile [MED]: colour key without an alpha plate; with a plate, alpha `p == 32` skips, `p == 0` gives global α, else α = global + p and the pixel is skipped if α ≥ 32 (alpha transparency is **additive**). A row marker of 1000 skips the row. Every fading entity (+0x68 ≠ 100) goes through it. |
| **B2: scaled leaves** | LOW: `FUN_1001b7d0`(95), `FUN_1001ba40`(100), `FUN_1001bcf0`(105), `FUN_1001bfd0`(102), `FUN_1001c270`(86), `FUN_1001c480`(88), `FUN_1001c6c0`(86), `FUN_1001c8f0`(88). none: `FUN_1001cb40`(50), `FUN_1001cc60`(58), `FUN_1001cdc0`(51), `FUN_1001cf80`(58), `FUN_1001d270`(44), `FUN_1001d460`(40), plus `1d0e0`/`1d1b0`/`1d370` (< 40) | `FUN_1001a6f0` / `FUN_1001aa90` | 4 modes × {alpha plate, colour key}, unclipped and clipped [MED, call shape]. From the `b7d0` decompile [MED]: **nearest neighbour**, src x = (srcW·(dx − left)) / dstW in integer C division, precomputed per column; src y likewise. The unclipped path clamps to hard constants 416 × 480 (`0x1a0`, `0x1e0`). This settles sprite NR6 if a listing confirms it. |
| S: sprite manager | `FUN_10018740`(58), `FUN_100188d0`(47), `FUN_10018bf0`(47), `FUN_100193f0`(49), `FUN_10019ee0`(42 LOW), `FUN_10019fc0`(76), `FUN_1001b040`(123), `FUN_1001b390`(79), `FUN_1001b590`(53) | `FUN_100000e0`, `FUN_10000630`, `FUN_10019ca0`, `FUN_1001faf0` | init and console registration (debug-only), teardown, the "Sprite Groups Cache" file I/O, the LOGSPRITE dump (no caller). Replica-neutral [MED, strings] |
| R: resource/image | `FUN_10020270`(44, no caller, logs Sprites/Sounds), `FUN_10020f00`(83, QuickTime TGA import) | `FUN_10020e60` | debug log; the TGA decoder. The replica decodes TGA itself. Only INDEX #10 depends on it, and that is a data check [MED] |
| T: G_Text element lists | `FUN_1000d6d0`(64), `FUN_1000d7f0`(112, draw list), `FUN_1000da50`(47, button hit rects), `FUN_1000db90`(190, fade in), `FUN_1000df00`(190, fade out) | `FUN_10023040`, `FUN_10021950`, `FUN_10021bd0`, `FUN_100258e0`, `FUN_10025420`, `FUN_10025840/890`, `FUN_10025b90`, `FUN_100232d0` | front-end.md uses all five in prose (32-step fades, MED). Visible on menus and score screens. Needs a listing to become HIGH [MED] |
| D: display/DrawSprocket | `FUN_1000c470`(164, DSp setup), `FUN_1000c8d0`(50, DSp shutdown), `FUN_1000a840`(45, collapse window), `FUN_1000b530`(41, display teardown), `FUN_1000bd80`(50, present mode 1), `FUN_1000a190`(75, debug pixel-buffer set, no caller), `FUN_10045f70`(95, direct screen base) | `FUN_1000ae20`, `FUN_10000630`, `FUN_1000b9a0/ba70`, `FUN_1000c3f0` | OS display plumbing. Replica-neutral, apart from the present path under interlacing [MED, imports] |
| I: static initialisers | `FUN_10000000`(41, the dispatcher: 32 calls), `FUN_10000750`(41), `FUN_100092a0`(47), `FUN_100448b0`(45), `FUN_10030e70`(43 LOW), `FUN_10039100`(47 LOW) | `entry` / `FUN_10000000` | They copy constant records into module templates **before main**. They are not replica-neutral: see §5 C1 [HIGH for C1] |
| F: file/process I/O | `FUN_10001200`(56), `FUN_10044930`(49), `FUN_10044a60`(47), `FUN_10044ce0`(59, FSMakeFSSpec), `FUN_10048610`(102), `FUN_10048810`(96, PBGetCatInfoSync), `FUN_10049400`(43, log file) | pak, units cache, `FUN_100000e0` | app-folder lookup, cache files, logging. Replica-neutral [MED] |
| M: misc Mac | `FUN_10045ab0`(85, PICT alert), `FUN_10045c60`(108, alert), `FUN_10049600`(42, ICLaunchURL), `FUN_1004b2b0`(70, entry, Gestalt 'ppcf') | `FUN_1000ced0`, `FUN_10048330`, `FUN_10025270`, entry | error alerts, the website link (out of scope), CFM/MSL startup [MED] |

## 3. Still NOT RESOLVED across the 18 files, de-duplicated

The nine wave-2 files hold 67 NR items. "Stale" means another wave-2 file already settles it (see §5).

| # | item (sources) | replica-critical? |
|---|---|---|
| O1 | MathLib `atan` ulp: the headings that lose 1° per round trip (combat NR1) | **yes, replay**: motion must be bit-exact |
| O2 | finale same-tick order, `aieg` group delay (session NR3) | yes, ±1 tick |
| O3 | rule-2 distance (session NR4 = bosses NR1). `FUN_10042e90` is already HIGH in damage-health-death.md: the fix pass should check whether this is closed | yes, if open |
| O4 | `req+0x28` register sources in `FUN_1003c7a0`/`FUN_1003c940` (combat NR4, MED) | yes: projectile speed |
| O5 | scale-tolerance `R()` arguments dropped by the decompiler (spawn NR5 residue; no wave-2 file touches it) | yes for RNG ranges, if any shipped unit has tolerance ≠ 0 (census needed) |
| O6 | orphaned orbiter (combat NR2); no-player fall-through (units NR3) | in principle; no shipped case |
| O7 | open wave-1 items wave 2 never touched: `FUN_1000fee0` codes other than 0/1 (damage NR6); ground-accuracy rect bound listing (damage NR5); hit factor f1 (player NR7); spawn-countdown entities vs scroll pause (level NR8); destroy-action census (scoring NR6) | yes (water test, scoring, scroll) |
| O8 | INDEX #10 TGA row orientation | yes: media-mask lookup. A data check (TGA descriptor bit 5) |
| O9 | blit pixel rules: mode 1 fade, scaled sampling, clipped twins, `FUN_1001dd20` partial alpha (sprite NR6, NR7) | **yes, visual**: every fading or scaled sprite |
| O10 | `DAT_100e0171/0172/0181` writers (sprite NR3, INDEX #9). Hypothesis [MED-LOW]: only the debug sprite-FX commands of `FUN_10018740` write them, and those are never registered (messages §5.2), so they stay at 1 | visual |
| O11 | render-list reset for layers 2..15 (sprite NR2); entity `+0x1a` writer (sprite NR5) | visual (shadow offset) |
| O12 | text: `+0x10c/+0x10d/+0x110` (messages NR1, hud NR3); space advance (#6, hud NR6); `tesm` cell widths (hud NR5); tally fades (scoring NR4) | visual, every string |
| O13 | particle colour `>>3` (particles NR1); `+0x131` circular burst (particles NR7); LCG = 1 at boot (particles NR3) | visual |
| O14 | present/copy `FUN_1000bbd0`/`FUN_10009fd0`/`FUN_1000beb0`, double CopyBits (hud NR4, timing NR4/NR6) | visual only under interlacing |
| O15 | menu hover rect, level-select flash durations, developer logo, `noel` 5th flash (front NR2/NR9/NR6, messages NR4) | visual |
| O16 | pitch direction, `ampCmd` scale, non-preloaded sound, stream wrap, music after demo (sound NR1/2/4/6, front NR4) | **audible**; NR1 is for Ben's ear |
| O17 | default key table and its consumer (#14, timing NR2); menu volume keys (front NR1); replay-abort keys (session NR6); int pref 2 (timing NR1) | input |
| O18 | in-game quit route (session NR1, narrowed by front §2.5); alert quit (session NR2); `DAT_100e01b5/b6` writers (sound NR5) | flow; error paths |
| O19 | TickCount 60.15 vs 60 Hz (timing NR5); OS X volume path (messages NR6) | feel; a ruling for Ben |
| O20 | DITL/MENU labels (#13, sound NR3, front NR8) | UI text. Needs a resource-fork parse, not code |
| N | debug-only: GOD/PLAYERACTIVESPAWNS (combat NR3), ISp suspend (messages NR8), unit-def NR6, NUMDEBRIS/NUMBLURS (particles NR6), SHADOWS pointer (sprite NR4); mod-only: #31, #35, weapons NR9, unit-def NR1/2, bosses NR2, sprite NR9, session NR7; registration (player NR3) | no |

**Stale NRs to strike:**

| stale NR | settled by |
|---|---|
| sprite NR1 | particles §2.9 |
| sprite NR8 | messages row `FUN_10005ce0` |
| particles NR2 | combat §4.5 |
| particles NR4 | sprite §4.1 |
| particles NR5 | sprite §6 |
| timing NR3 | sprite §6 step 1 |
| hud NR1 | sprite §4.1 |
| hud NR2 | sprite §3.3 |
| messages NR3, front NR5, weapons NR4 | sound §2.3 |
| messages NR7 | front §8 |
| front NR3 | session §6 |
| front NR7 | session §3.2 |
| session NR4, −32 half | combat §5.1 |
| session NR5 | front §4.3 |

## 4. INDEX NOT-RESOLVED after wave 2

| # | status | by / residual |
|---|---|---|
| 1, 3, 10, 31, 35 | **open, untouched** | #1 still holds "Local first" order at MED (session §8.7) |
| 2 | closed | session §8.7 |
| 4 | closed | session §8.2 (`FUN_10000630` → ExitToShell); ⚑ pak-format §2.3: `FUN_10000fd0` is non-fatal |
| 5 | closed (MED) | hud §9 |
| 6 | narrowed | hud §9/NR6: cache `0x100df024`; filler `FUN_1000ed10` unread |
| 8 | closed | sprite §1.1 (300 × 256) |
| 9 | narrowed | sprite §4.4; writers open (O10) |
| 11 | closed | sound §2.3, §3 |
| 12 | closed | timing §3 (messages still says "writer open") |
| 13 | narrowed | timing §6, messages, sound §4.2; int pref 2, rest of the block, three dialog labels |
| 14 | narrowed | timing §6; consumer not found |
| 20 residual | closed | combat §5.1 |
| 27 | closed | session §5; ±1-tick residual = O2 |
| 29, 32 | closed | combat §4.1, §4.3 |
| 30 | closed **twice** | combat §2 and session §8.8 (they agree; merge as one) |
| 33 | closed | particles §1 |
| 7, 15–19, 21–26, 28, 34 | closed earlier | — |

Proposed new items: blit rules (O9), render-list reset (O11), the front-end items (a)–(d), int pref 2, atan ulp (O1).

## 5. Cross-wave contradictions for the fix pass

**C1 [HIGH, new].** sprite-geometry.md §3.1 reads the draw template `0x100e63e4` from the data image. But the static initialiser `FUN_10014120` (LOW, "static init") writes into it before main:
- +0x04/+0x08 ← 0 (from `0x100d6778`);
- clip +0x20..+0x2c ← **{0, 0, 480, 416}**, the game-area rect (from `0x100d6788`, code image bytes `…000001e0 000001a0`);
- +0x38..+0x44 ← 0 (from `0x100d6798`).

So at runtime the template clip is the game area, not 0. Entity draws overwrite the clip from entity +0x3c, but any builder that keeps the template clip lands on the unclipped scaled path. The same risk applies to every "template from image" claim. Known writers:
- `FUN_10032b20` → `0x100eb228`/`374`/`3c8`; hud NR7 used the image bytes;
- `FUN_10030e70` → `0x100eb03c`/`184`/`1d8`;
- `FUN_10039100` → `0x100eb420…` (the spawn files already know this one);
- `FUN_100228d0` → `0x100e8964`;
- `FUN_1002a4f0` → `0x100e9178…`.

**C2.** front-end.md row `FUN_10030df0`: "+4 interlace". timing §1 and messages §4.4: +4 = game-screen layout flag, not interlace. front §5.1 and §3 step 4 also call the second argument of `FUN_1000b9a0`/`FUN_1000ba70` "interlaced". Session §6: that argument picks the present routine (0 `FUN_1000bc60`, 1 `FUN_1000bd80`).

**C3.** Shadow layer:
- timing NR3 and §2.3 keep "layer 1 = shadows" from engine-loop §5;
- sprite §6: shadows are on layers 2/4/6 (0 for stamps), and layer 1 is the stamp sprite.

**C4.** particles §2.9 says the particle draw runs "every frame". The listing gates it on the end-frame byte argument `r28` (`10030cc8 rlwinm. r0,r28; beq 0x10030cd8`), as timing §2.3 shows.

**C5.** Role and label disagreements:

| function | one reading | the other reading |
|---|---|---|
| `FUN_10005ce0` | sprite §3.2: LOW "last-present tick" | messages: HIGH "game time getter G+0x1c" |
| `FUN_10043ba0` | sprite: LOW "not read" | particles: HIGH |
| `FUN_1001ec80` | function-roles: HIGH "translucent COST rect" | session: MED "blend buffer toward colour" (compatible; reconcile wording) |
| `FUN_100009e0` | session row: MED | combat §4.5: HIGH (append-at-tail) |

**C6.** sprite §3.2 says console setup "registers SHADOWS/SHADOW". messages §5.2 says debug-only commands are never added, so the SHADOWS byte stays 1 and shadows are always on.

**C7.** front §4.3 step 4 says "save prefs `FUN_100047f0`". session §3.2 says that call only copies into the live prefs; the disk write happens at quit (`FUN_10000630 → FUN_100045f0`).

**C8.** front §4.3 says "a tie-shift moves the lower-placed entry down" (from scoring §9.2). session §3.1 adds two two-player quirks: a row is lost or duplicated, and P1 is placed first. Use session.

**C9.** session NR5: two easter-egg strings undecoded, ctype table `_DAT_100dea48`. front §4.3: BIKI → "Filthy Communist", FISJ → "Daikajinn!!", ctype table `0x100f0f94` checked.

**C10.** session §2.3: "event code 8: jump table not recovered; aevt link LOW". front §2.5: code 8 = Quit AppleEvent at `100490ec` [HIGH].

**C11.** messages "#12 divider writer still open" vs timing "#12 closed". hud/messages/front NRs on sound arguments vs sound §2.3.

**C12.** TickCount: session 60 Hz vs timing 60.15 Hz.

Already flagged by the wave-2 files themselves (carry into the fix pass):
- engine-loop §3, §4 (a–d), §5 (shadows, score-bar x), §9 (302 draws), §10 (0x129c dead);
- data-tags §4/§5;
- sprite-sound-containers §4;
- level-scroll §8 `tran`;
- pak-format §2.3;
- scoring §11 ALLLEVELS, scoring NR2 `b8`;
- damage `FUN_10017150`;
- spawn §3.3;
- player-physics §2.6, §4.4;
- the `FUN_10029c00` caller;
- `FUN_10009750` polarity.

## 6. Recommendation

The simulation core was done after wave 1. Wave 2 did presentation, and it fixed four real replay facts:
- 302 boot draws;
- `R(0,4)` per particle;
- the speed divider is never set;
- the motion blur never draws.

What remains does not justify a full nine-reader wave. **Run a small wave 3 (three readers), ordered by replica value:**

1. **`blit-pixel-rules`** (visual, every fading or scaled sprite). Read B1 and B2 in full by listing: `FUN_1001db50` `FUN_1001e0d0` `FUN_1001e2b0` `FUN_1001e4f0` `FUN_1001e770` `FUN_1001b7d0` `FUN_1001ba40` `FUN_1001bcf0` `FUN_1001bfd0` `FUN_1001c270` `FUN_1001c480` `FUN_1001c6c0` `FUN_1001c8f0` `FUN_1001cb40` `FUN_1001cc60` `FUN_1001cdc0` `FUN_1001cf80` `FUN_1001d0e0` `FUN_1001d1b0` `FUN_1001d270` `FUN_1001d370` `FUN_1001d460`, plus the `FUN_1001dd20` partial branch. Then do an instruction diff of each twin against its HIGH sibling, and a raw `stb` scan for `-0x61bf/-0x61af/-0x61ae(r2)` (O10).
   - Must answer: the mode-1 alpha combination; the scaled sampling rule; the clamps; that the twins equal the unclipped forms.
2. **`static-init-audit`** (correctness of image-derived constants). List all 32 callees of `FUN_10000000` (866 lines): `10000750 10004520 100092a0 1000ca10 1000f720 100108e0 100125b0 10014120 10017f80 10018670 1001b760 1001d570 1001f0d0 1001f750 10020cf0 100228d0 10025b00 10026100 1002a4f0 1002aa70 1002da40 1002e280 10030020 10030e70 10032b20 10039100 1003ce60 100428b0 100448b0 10046680 10061b30 100623e0`.
   - Output: a destination ← source table, then a sweep of every bank claim that reads a template or global from `100de330.bin` (C1).
3. **`text-metrics-and-lists`** (visual, every string and menu). `FUN_1000ed10` + its filler (#6), `FUN_1000ebd0`, the `+0x10c/+0x10d/+0x110` use in `FUN_1000d380`/`FUN_1000e270`, and `FUN_1000d6d0` `FUN_1000d7f0` `FUN_1000da50` `FUN_1000db90` `FUN_1000df00` to HIGH. Also the tefo Loc frame (messages NR2). [Optional: O7 listing checks `FUN_1003bab0`, `FUN_1000fee0`, `FUN_10033850` near `LAB_10033d70`, and O4.]

**Outside code reading:**
- O1 needs a MathLib atan emulation, or a run of the original.
- O8: read the TGA descriptor bytes in the paks.
- O16 pitch and O19: Ben's ear and a ruling.
- O20: a resource-fork DITL/MENU/STR# parse.

**Do not read** families S, R, D, F and M, or U_Manager and unzip (≈ 2 900 unread lines) [MED]. Evidence:
- imports and strings: DrawSprocket, FSSpec/PBGetCatInfo, StandardAlert, ICLaunchURL, cache files, logs;
- their callers are boot/shutdown or the debug console only (callers.txt);
- no gameplay function reads state they write, except the display rects `FUN_1000ae20` already read by hud §1;
- a native replica replaces them with its own display, file and alert code.
