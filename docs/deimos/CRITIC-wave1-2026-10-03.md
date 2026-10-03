# Deimos Rising RE bank: wave 1 completeness critic (2026-10-03)

Read-only critic. Inputs: old bank at `61022c0`, the nine wave-1 files at `a57c0fd`, `$W/inventory.txt` (563 `FUN_` in 0x10011000–0x10044000), `callers.txt`, `sizes.txt`, `profile.txt`.
Method: a script parsed every Markdown table row whose first cell names `FUN_` and holds a HIGH/MED/LOW cell (multi-function rows included), plus every `FUN_` mention and every line saying "not read". "Before" means the inventory label (the old §1 table). "After" means the best label any new file gives, falling back to the old one. Labels in prose that never reach a table are not counted, so counts may be slightly low. 12 in-range functions are mentioned in new files but carry no label.

## (a) Label counts, gameplay range (563 functions)

| | HIGH | MED | LOW | none |
|---|---|---|---|---|
| before wave 1 | 60 | 74 | 5 | 424 |
| after wave 1 (best label) | **255** | 127 | 20 | **161** |
| after wave 1 (worst label where files disagree) | 237 | 143 | 22 | 161 |
| ≥ 40 lines (230 fns): before | 31 | 53 | 2 | 144 |
| ≥ 40 lines: after | 112 | 59 | 3 | 56 |

Per family (after; "unread lines" = sum of decompiled lines of none + LOW):

| family (address span) | fns | before H/M/L/– | after H/M/L/– | unread lines |
|---|---|---|---|---|
| Level/GameObject/Entity 11000–18740 | 80 | 6/13/1/60 | 49/26/3/2 | 131 |
| **Sprite + Blit 18740–1f7c0** | 72 | 12/1/0/59 | 12/1/0/59 (untouched) | **3262** |
| Resource/Image 1f7c0–21190 | 23 | 9/3/0/11 | untouched | 323 |
| Scores 21190–23040 | 13 | 1/6/1/5 | 2/6/0/5 | 75 |
| **Interface/Credits 23040–26100** | 43 | 0/6/0/37 | untouched | **1163** |
| Player 26100–2a660 | 60 | 2/8/2/48 | 46/10/4/0 | 71 |
| Debris 2a660–2ab20 | 9 | 0/0/0/9 | 1/1/0/7 | 140 |
| WeaponDefs/Token 2ab20–2cef0 | 28 | 12/2/0/14 | 24/4/0/0 | 0 |
| **Console/Message 2cef0–2e310** | 21 | 0/6/0/15 | untouched | **537** |
| LevelSelection 2e310–31400 | 32 | 7/9/0/16 | 7/18/7/0 | 148 |
| **ScoreBar 31400–32e60** | 16 | 0/2/0/14 | untouched | **898** |
| EntityGroup 32e60–39280 | 50 | 8/5/1/36 | 27/20/3/0 | 73 |
| PlayerDefs 39280–3a780 | 11 | 0/0/0/11 | 8/3/0/0 | 0 |
| U_Manager 3a780–3ade0 | 10 | 0/0/0/10 | 0/1/0/9 | 220 |
| WeaponHandler 3ade0–3d0a0 | 28 | 0/6/0/22 | 23/5/0/0 | 0 |
| UnitDefs 3d0a0–42100 | 44 | 3/5/0/36 | 34/10/0/0 | 0 |
| Math/collision 42100–432d0 | 19 | 0/0/0/19 | 13/3/3/0 | 57 |
| **Particle 432d0–44000** | 4 | 0/2/0/2 | untouched | 249 (+420 MED-only) |

Verdict [HIGH, from the counts]: wave 1 closed the simulation core. Entity, player, weapons, spawn, unit-defs and collision are each at ≥ 97 % labelled. Everything still unread sits in **presentation**: sprite drawing, HUD, messages, menus, particles and debris.

**16 label disagreements between files**, for the merge: `FUN_100144a0`, `FUN_100146f0`, `FUN_100161c0`, `FUN_10017150`, `FUN_100172d0`, `FUN_10026c10`, `FUN_10027e50`, `FUN_10029c00`, `FUN_10034ce0`, `FUN_10035070`, `FUN_10036120`, `FUN_10036610`, `FUN_10036930`, `FUN_10037580`, `FUN_1003cf10`, `FUN_10010570`.
Two of them are role conflicts, not just label conflicts:
- `FUN_10017150`: damage-health-death.md "INDEX updates" calls it "the runtime spawn-set reader (LOW)". Three other files call it the rotation gate and name `FUN_10015b40` as the executor.
- `FUN_1003cf10`: bosses.md says LOW "console unit commands". unit-def-struct.md says HIGH "module init + cache".

## (b) Unread functions of ≥ 40 lines in range (56 with no label + 3 LOW), by family

| family | functions (lines) | callers | hypothesis [conf] |
|---|---|---|---|
| S1 sprite manager | `FUN_10018740`(58) init, `FUN_100188d0`(47) teardown, `FUN_10018bf0`(47) cache load, `FUN_100193f0`(49), `FUN_10019ee0`(42), `FUN_10019fc0`(76, no caller, "Information for Sprite Group"), `FUN_1001a2a0`(74, "Integrity FAILURE"), `FUN_1001a450`(66, render list grow), `FUN_1001b040`(123)/`FUN_1001b390`(79)/`FUN_1001b590`(53) Sprite Groups Cache | `FUN_100000e0`, `FUN_10000630`, `FUN_10019570` | lifecycle, debug and cache I/O. The replica needs none of it beyond identification [MED, strings] |
| S2 scaled-blit variants | `FUN_1001a6f0`(92) → `FUN_1001b7d0`(95) `FUN_1001ba40`(100) `FUN_1001bcf0`(105) `FUN_1001bfd0`(102) `FUN_1001c270`(86) `FUN_1001c480`(88) `FUN_1001c6c0`(86) `FUN_1001c8f0`(88); `FUN_1001aa90`(93) → `FUN_1001cb40`(50) `FUN_1001cc60`(58) `FUN_1001cdc0`(51) `FUN_1001cf80`(58) `FUN_1001d270`(44) `FUN_1001d460`(40) (+`FUN_1001d0e0`/`1d1b0`/`1d370` < 40) | `FUN_10019570` | 2 × 8 leaf pixel loops on the "command float +0x18 ≠ 1" path, i.e. scaled draws × {key, alpha, tint, glow…} [MED: old sprite-sound-containers.md §2.3 + shape] |
| S3 clipped/tinted blits | `FUN_1001db50`(89) `FUN_1001dd20`(77) `FUN_1001df00`(80) `FUN_1001e0d0`(93) `FUN_1001e2b0`(101) `FUN_1001e4f0`(90) `FUN_1001e770`(97); `FUN_1001e9d0`(101) | `FUN_10019570`; `FUN_1000ba70` | variants of the HIGH `FUN_1001d9f0`; `1001e9d0` = full-screen fade blit [LOW] |
| R resource/image | `FUN_10020270`(44, no caller, logs Sprites/Sounds), `FUN_10020f00`(83, QuickTime TGA import, pixel depth) | `FUN_10020e60` | loader. Replica-irrelevant except row orientation (INDEX #10) [MED] |
| I front end | `FUN_10023b00`(151) `FUN_10023e10`(54) `FUN_10024430`(40) `FUN_10024530`(62) `FUN_10024810`(40) `FUN_10024a50`(94) | `FUN_100229a0` (interface loop) | menu pages, button lists, rollover/click sounds (SND2/10/11) [MED, perm] |
| C console/messages | `FUN_1002d230`(82, F22 Console_ExpireTime), `FUN_1002d410`(60, F23 FadeOutRate), `FUN_1002dea0`(126, F27 Message_VerticalGap) | `FUN_10030360`, `FUN_10030bc0` | in-game message list: post, expire, fade, stack draw [MED, perm] |
| H score bar | `FUN_10031400`(112, 'scor' TGA), `FUN_10031ae0`(75) → `FUN_10031ea0`(85 lives symbol F112–115), `FUN_10032250`(141 shield meter F116–119, 'COST'), `FUN_10032500`(141 power meter F122–125), `FUN_100327b0`(114 weapon icons F130–142); `FUN_10032bd0`(42, entity debug cmds) | `FUN_100064d0`, `FUN_10007070` | the whole HUD [MED, perm] |
| P particles | `FUN_10043ba0`(224) | `FUN_10030bc0` (end frame, between render layers 1 and 2) | particle draw: RGB555 additive/alpha "glow" splats straight into the game buffer, clipped by flli 54/55 [MED, read the head] |
| misc | `FUN_10011590`(42, "%i%%") | `FUN_10010fc0` (config dialog) | slider label in the configuration dialog: game speed or volume? [LOW] |
| data as code | `FUN_10018670`(43 LOW), `FUN_10030e70`(43 LOW), `FUN_10039100`(47 LOW) | only `FUN_10000000` | static initialisers or literal pools ("CEGAnonenone") [LOW] |

Heavy in-range functions still **MED only from the old bank, never re-read**, that the replica needs: `FUN_10013460`(336, entity shadow draw), `FUN_10043340`(284, particle emit, **calls `FUN_10046580`, so it is a replay-order RNG consumer**), `FUN_100438c0`(136, particle update), `FUN_100317e0`(129, meter update), `FUN_10030f40`(135, score-bar rects), `FUN_10032050`(89, lives), `FUN_100345f0`(259, debug labels + castsShadow draw), `FUN_10019ca0`(66, sprite dimensions; flagged "not read" by two files), `FUN_100229a0`(227), `FUN_10021bd0`(225), `FUN_100222f0`(213), `FUN_10025b90`(185, credits).

## (c) Out-of-range helpers called by gameplay code, no role (86 of 154 out-of-range callees)

| group | functions (lines) | gameplay callers | note |
|---|---|---|---|
| G_Game accessors | `FUN_10005cf0`(9, game+0x39), `FUN_10005ed0`(90, closest active player), `FUN_10006090`(17, player position), `FUN_10006220`(12), `FUN_10005ce0`(9 LOW, game time) | entity, player, spawn | +0x39 writer unknown (weapons NR1) |
| text (G_Text) | `FUN_1000d130`(56), `FUN_1000d380`(157, format flags CEBU/CEGA/CENT/COST/LEFT/RIGG/RIGH), `FUN_1000e270`(163), `FUN_1000d260`(54) | notice `FUN_100184b0`, money `FUN_100298c0`, HUD, level select | every on-screen number and string |
| display / pixel buffer | `FUN_1000a530`(13, buffer bounds), `FUN_1000b9a0`(41)/`FUN_1000ba70`(59) fades, `FUN_1000c2a0`, `FUN_10009e40`, `FUN_1000bbd0`, `FUN_1000c320`/`c350` | HUD, level select, transitions | level-scroll NR9 |
| entity draw | `FUN_10010c20`(17), `FUN_1004d5c0`(29, memcpy?) | `FUN_10012fa0`, `FUN_10013460` | anchor question (level-scroll NR1) |
| particles | `FUN_10044630`(79, **two `RandomRange` per table entry at init**), `FUN_10044550`(34), `FUN_10044840`(12), `FUN_10010bd0`(9) | `FUN_100431f0`, `FUN_100438c0`, `FUN_10043340` | init-time RNG (damage NR7) |
| motion blur | `FUN_100467c0`(26) reset, `FUN_10046840`(70 LOW) emit, `FUN_10046a10`(34) update, `FUN_10046ae0`(28) draw, `FUN_10046ba0`/`46c70`/`46d30`/`46e20`/`46eb0`/`470f0` | level start, `FUN_10033850`, `FUN_10006b50`, `FUN_10007070` | RNG per entity per tick (damage NR8) |
| sound | `FUN_10047670`/`FUN_10047bf0`/`FUN_100475e0`/`FUN_100476e0` (MED, semantics open: INDEX #11), `FUN_10047910`(9), `FUN_10047f50`(10), `FUN_10047f80`(9), `FUN_100477d0`(50, no caller) | everywhere | `100475e0` = float-RNG pitch |
| units-cache file I/O | `FUN_100010f0`…`FUN_10001570`, `FUN_10044ce0`, `FUN_10044f00`, `FUN_10048560`, `FUN_10048610`(102), `FUN_10050140`/`50390`, `FUN_100461b0` | `FUN_100420f0`, `FUN_100426e0`, `FUN_10041e40` | identification only |
| list/memory runtime | `FUN_10000890`, `FUN_100008b0`, `FUN_10000cf0`(37), `FUN_10000d90`, `FUN_1000cc00`, `FUN_1004d3b0`, `FUN_1004d648`/`d698`, `FUN_10046510` | everywhere | label mechanically |
| registration integrity | `FUN_1006a620`…`FUN_10080370` (13 fns) | `FUN_10028170`, `FUN_10026410`, `FUN_100269a0` | out of scope by ruling |
| **un-functioned code** | 0x10007d60–0x10008820: no `FUN_` covers 0x1000827c / 0x10008380 (scoring NR7) | console | cheat handlers that players can reach. Needs a listing by address [MED] |

## (d) Mechanics the nine files leave open, de-duplicated

| # | group | items (source NR) |
|---|---|---|
| D1 | sprite geometry | frame w/h, scale, collision radii in px (damage 1, units 5); anchor = centre? (level 1); glow +0x58 / fade +0x68 / +0x84 at draw (player 8) |
| D2 | trig/heading | `FUN_10042cd0` listing (units 1, damage 9); cos/sin and axis convention (spawn 2, weapons 7, bosses 5) |
| D3 | timing | game-speed divider (units 6 = INDEX #12) |
| D4 | game flag +0x39 | writer (weapons 1), also gates the invulnerability clear and the spawn gate |
| D5 | pickups and player flags | 'shie'/'spec' switch mis-recovery (scoring 3), shield cap `FUN_10027490` (damage 4), +0xce/+0xcf via `FUN_10027de0`/`FUN_10027db0` (weapons 2, level 5) |
| D6 | unused-key consumers | `numAmmoInPack`, `ammoWarn*`, `shieldIncrease`, `livesIncrease`, `invulnerableForTime`, `maxAllowed`, glow colour (weapons 3); handler +0x6c/+0x6d (weapons 9); unit/state reserved regions, unit+0x11/+0x0c (unit-def 1, 2) |
| D7 | plde fly-in keys | waitingTime, intro times, entry velocities, death_Duration, MoneyCounterSpawn (player 1) |
| D8 | bookkeeping | double `FUN_10036120` (spawn 1); +0x13d/+0x13e (spawn 7, damage 3); +0xd8 for enemy spawns (damage 2); B-side passHitsToOwner (bosses 3, damage 10); req+0x28 (spawn 8); same-tick spawn (spawn 4) |
| D9 | spawn geometry | −32 shift for spawn-set children (bosses 4); orbit/lock use of +0x10/+0x14/+0xe0 (units 7, spawn 3) |
| D10 | weapon/crosshair | `FUN_1003b3c0` return codes, +0x360 lifecycle, flli 149/150 (player 2, 4); bVar17 (weapons 6); `FUN_1003af90`/`FUN_1003cdb0` carry-over (level 6); handler +0x08 (weapons 5); bomb count per press (bosses 6) |
| D11 | messages/notices | notice fade (units 8); console/message module; PLAYER console command (scoring 7) |
| D12 | session/finale | noal/12gc chain + EndGameFinale (scoring 5, bosses 8); lives-gate reset (player 6); high-score insertion and pref listing, `DAT_100e01b8` (scoring 1, 2); level-select bonus text (level 7); transitions `FUN_1000b9a0` (level 9) |
| D13 | RNG outside the §9 table | `FUN_100431f0`/`FUN_10044630` init draws (damage 7); motion blur (damage 8); particle emit `FUN_10043340` (this critic) |
| D14 | misc | `FUN_10029c00` pointer xref (player 5); `FUN_10000630` exit (unit-def 3); `FUN_100461b0` gate (unit-def 4); `FUN_1003d550` family (unit-def 5); `0x100e013c/0140` readers (level 2); `FUN_10012ca0` mode-1 bounds (level 3); tag-order after overrides (weapons 8 = INDEX #2) |

## (e) INDEX NOT-RESOLVED 1–28 after wave 1

| # | status | closer / residual |
|---|---|---|
| 1, 3, 5, 6, 10, 13, 14 | **open**, not touched (engine/pak) | — |
| 2 | open | weapons NR8 depends on it |
| 4 | narrowed | unit-def §2.1–2.2; residual `FUN_10000630` exit, other loaders |
| 7 | **closed, three times** | unit-def §9, player-physics rows, damage §5.1. Merge must diff the three tables |
| 8 | open | = D1 |
| 9 | open residual | `DAT_100e0181` writer |
| 11 | open | sound semantics |
| 12 | open | = D3, now the biggest timing gap |
| 15, 16, 18, 21, 23 | struck earlier | — |
| 17 | closed | level-scroll §2, §5; player §2.5 |
| 19 | closed | units-movement §1–§8; residual D2 |
| 20 | closed | spawn §2 (`FUN_10015b40`); the damage file's `FUN_10017150` wording conflicts |
| 22 | closed | spawn §6. bosses.md still says `FUN_10034ee0` "not read" and `FUN_10035070` MED: reconcile |
| 24 | closed | damage §2.1/§3/§5.2 |
| 25 | closed both halves | weapons §2–3, player §2–3, §6; residual D10 |
| 26 | closed | scoring §3, §6, §7; player §6.1 |
| 27 | narrowed | scoring §8, level-scroll §8; residual noal/12gc chain, EndGameFinale |
| 28 | closed (no bonus exists) | scoring §9.3/§10.3; residual: the level-select text |

## Wave 2 proposal (ordered by replica value)

| # | file | scope | must answer |
|---|---|---|---|
| 1 | `sprite-geometry-draw.md` | `FUN_10019ca0`(66) `FUN_10019c10`(26) `FUN_10019ad0`(39) `FUN_10019530`(12) `FUN_10019570`(179, scale path) `FUN_10012940`(27) `FUN_10012ad0` `FUN_10012f20`(24) `FUN_10012fa0`(191) `FUN_10013460`(336) `FUN_10010c20`(17) `FUN_100345f0` shadow part; `_DAT_100df180` | D1 in full; INDEX #8; collision radius in px for one real unit; shadow offset and darkness |
| 2 | `particles-debris-blur.md` | `0x100431f0–0x10044850` (`FUN_100431f0` `FUN_10043280` `FUN_100432d0` `FUN_10043340` `FUN_100438c0` `FUN_10043ba0` `FUN_10044550` `FUN_10044630` `FUN_10044840`); G_Debris `0x1002a4f0–0x1002ab20`; G_MotionBlur `0x100467c0–0x10047100` | RNG draw order per emit and per tick (replay); particle life, gravity, colour; glow blend arithmetic; init-table draws vs srand (D13); debris rules |
| 3 | `timing-frame.md` | `FUN_10030bc0`(85) and its caller, `FUN_10030360`(89), `FUN_10010fc0`(153), `FUN_10011590`(42), `FUN_100050f0`(36), `FUN_10004f80`, writer of frame-controller +0x2c | INDEX #12 values per label, ticks/s, FPS limiter (F33/F32); part of #13 |
| 4 | `hud-scorebar.md` | `0x10030f40`, `0x10031400–0x10032e60` (16 fns), `FUN_100317e0`, `FUN_1003bb40`; text `FUN_1000d130` `FUN_1000d260` `FUN_1000d380` `FUN_1000e270` | position of every element (flli 112–142), meter fill arithmetic, lives cap, weapon-icon states, number/align formats, two-player layout, handler +0x08 |
| 5 | `messages-notices.md` | `0x1002cef0–0x1002e310` (21 fns); notice `FUN_10018070` `FUN_100181e0` `FUN_10018320` `FUN_100184b0`; listing of 0x10007d60–0x10008820 | queue max/expire/fade/gap (F22–F27); which gameplay events post which text; notice fade; cheat-command handlers |
| 6 | `loose-ends-combat.md` | explicit list: `FUN_10042cd0`, `FUN_10042b30/b80/ee0/f00` tables, `FUN_10005cf0` + store scan for game+0x39, `FUN_10005ed0`, `FUN_10006090`, `FUN_10006110`, `FUN_10037580` listing, `FUN_10027490`, `FUN_10027de0`, `FUN_10027db0`, removers `FUN_100363c0` `FUN_100364f0` `FUN_10034b90` `FUN_10034de0` `FUN_10036be0`, `FUN_100142f0` +0x13e, `FUN_1003b3c0` codes | D2, D4, D5, D8, D9, D10 |
| 7 | `loose-ends-session.md` | raw scan for plde +0x74…+0xc4 loads; `FUN_100051a0` lives gate; `FUN_100214c0`(126) and `FUN_100234d0`(186) listings; noal/12gc data trace; `FUN_1000b9a0`/`FUN_1000ba70`/`FUN_1001e9d0`; data xref of `FUN_10029c00`; `FUN_10000630` tail | D7, D12, INDEX #27 residual |
| 8 | `sound-music.md` | `0x10047160–0x10047fa0` (≈24 fns) + the gaso settings block | INDEX #11: volume/pitch/priority/channel semantics, pan, per-level music choice, volume keys |
| 9 | `front-end.md` | G_Interface `0x10023040–0x10026100` (43), Scores screens `FUN_10021950` `FUN_10021bd0` `FUN_100222f0`, credits `FUN_10025b90`, level-select LOW tail `0x10030020–0x100313b0`, `FUN_10006240`(110) | menu tree, button layout, sounds, key handling, high-score screen flow |
| 10 | `sprite-engine-blit.md` (lowest) | rest of `0x10018740–0x1001f7c0` (S1–S3), G_Resource/U_Image, U_Manager `0x1003a780–0x1003ade0`, lifecycle stubs | blit-variant selection flags → colour maths (tint/glow/fade, scale filter), render-layer order; identify the rest |

Notes on carving [MED]:
- 1 → 2 → 3 come first because they change the simulation or replay: collision radii, RNG order and tick rate.
- 4 → 5 are what a player sees on every frame.
- 6 and 7 are explicit-list scopes, not address ranges. Give each its D-items as a checklist.
- Scope 2 must coordinate with engine-loop.md §9. Scope 6 must own the `FUN_10017150` wording fix.
