# STATE history — Ambrosia Classics

> Settled history, moved out of `docs/STATE.md` on 2026-11-08 (Ben's ruling that day: STATE holds the current state
> only). Nothing current reads this file; the live state is `docs/STATE.md`. Each later close that settles something
> adds a dated section at the top, newest first. The two snapshots below are verbatim (headings demoted only).

## Settled at run 52's close (2026-11-14)

- **Run 51's Ferazel block** (main 0769aef): 6A-BL, 6A-CF, 6A-FR merged, Core 633. Run 52 replaced it: 6A-W1 and
  6A-W2 merged (the Warrior is a real boss), Core 633 → 642 → 650, wave 6A.1 built and cross-checked.
- **How run 52 went:** each task had one implementer, two Opus review legs and a fix round. W1: both legs MERGEABLE
  AFTER FIXES, no blockers; 156 mutations, 22 survivors, all killed by the fix round (tests only). W2: the
  implementer stopped because the contract's fight script could not win; the seat ruled (D49.1) and the build found
  the real win (pushing crates off the ledge); legs MERGEABLE / MERGEABLE AFTER FIXES, no blockers; 84 mutations, 10
  survivors, all killed. Only level 5's two frame pins moved (W1, the crates). The seat's Fable cross-check of the
  whole wave (6a196f2..e67ffb8, the Sources and tools diff read in full, plus 833506a and 8c93e9e): pass, no fixes.
- **Carries closed by run 52:** the Warrior's pre-lock rocks and shot-absorbing Hit; the kill arm that would not open
  the gate; the boss-music test with music off; type 0x434's missing class row (the dump has none — a comment says
  so); the `classWord160` comment; the two unreviewed run-51 commits (read in the cross-check; the ledger check
  passes and its generated blocks were regenerated again after W1 / W2 moved code lines).
- **Ben raised this session's context cap to 500k** (in chat); the run closed at about 290k.

## Settled at run 51's close (2026-11-13)

- **Run 50's Ferazel block** (main 6a196f2): the 6A plan written and reviewed, the launch checks done, nothing owed.
  Run 51 replaced it: the first three 6A tasks merged (6A-BL, 6A-CF ⚑, 6A-FR), Core 620 → 633.
- **How run 51 went:** each task had one implementer, two Opus review legs and a fix round. Verdicts: BL MERGEABLE /
  MERGEABLE WITH FIXES (0 critical, 0 important); CF MERGEABLE WITH FIXES twice (0 critical, 2 important: the Windows
  proof run did not copy the ledger the new test reads; most of CF's own missing marks were unpinned — both fixed); FR
  MERGEABLE twice. The app restarted mid-run: CF's quality leg and the seat's suite runs were lost and run again. CF
  broke the ledger's check script (it parsed the old list shape): repaired and regenerated the same run (D48.5).
- **The seat's suite runs:** 620 at 6a196f2 (the head), 633 at 8919326 and again at 8c93e9e (the final code head) —
  0 failed, the two opt-in skips by name each time. The 622 and 628 points were not run separately (lost in the
  restart; the final total is the ladder's).

## Settled at run 50's close (2026-11-11)

- **Run 49's Ferazel block** (main efeb66f): the Phase 6 research done, the 6A plan and the four launch checks owed.
  Run 50 replaced it: the launch checks done by day (all pass; Proof B 617 / 0 / 3 / 0 of 620), the 6A plan written
  into the one plan file, reviewed by two Opus legs and a Fable reviewer, fixed twice (D47, Q19).
- **How the plan changed under review:** the first draft had 27 build tasks and 812 tests; the reviews split out the
  pipes' level spawn (6A-PS) and the level fixture (6A-FX), made the picture-cache task major, moved the plants ahead
  of the rain, and added a 13th run: 29 build tasks, Core 814, WinKit 90, runs 51–63.

## Settled at run 49's close (2026-11-11)

- **Run 48's Ferazel block** (main 2f25cf6): Phase 5 machine-closed, Core 620, both builds staged at e9183ce, Q18 with
  Ben, launch checks owed, run 49 = the Phase 6 planning run. Run 49 replaced it: the three research documents (LL, BOS,
  ENG) written and reviewed, the 6A plan left for run 50, the launch checks still owed.
- **What the research overturned in the plan's cards** (each document's closing section has the full list): 39 boss
  routines, not 52; wind on levels 10 and 20; the horizon strip on six levels; the submerged tint and the side push
  already built; the Bonus / Platform / Rope card of levels 10–22 empty; the ripple routine named by the plan never
  runs in the original (the effect is inline in the frame painter); the rotating cannon belongs to 6A.

## Settled at run 48's close (2026-11-10)

- **Run 47's Ferazel block** (main bc31efa / 8aa4db5): Phase 5 one task from its machine end; Core 619 = 486 + 133;
  WinKit 82; Proof B 616 / 0 / 3 / 0 of 619; nothing staged since Phase 4. Run 48 replaced it: A5 and the Phase 5 Fable
  cross-check done, Core 620, both builds staged at e9183ce, the gate card to Ben as Q18, launch checks owed by day.
- **The relabel sweep is done:** no `later: Phase 5` is left in `Ferazel/Core/Sources`; the gap ledger marks the enemy
  classes, shots, geysers, the Dillo, the boulder spouts, the underwater tint and level 5 as built.
- **Carries closed by run 48:** "the gap ledger's tint lines still call the tint unbuilt" (fixed); the Windows smoke
  references living in two copies (the script reads the test file).

## Settled at run 47's close (2026-11-08)

- **Run 46's Ferazel block** (main c8d9cf5 → repaired 2d82e7e): waves 5.0–5.4 done, levels 1–4 enterable, level 5 not;
  Core 607 = 479 + 128; Proof B 604 / 0 / 3 / 0 of 607; visit sweep 3,360 visits / 0, bot 86,400 steps / 0 on levels 1–4;
  GE core-only. Run 47 replaced it: level 5 enterable, Core 619 = 486 + 133, GE on levels 1–5 both shells.
- **Wave 5.4's missing Fable cross-check** (runs 44–46 reviewed under the one-Opus-leg rule) was made good in run 47:
  MERGEABLE, no divergence from the dump; one tests-only fix round (608).
- The run-44/45 worktree note moved to the live block as a Ben action (the app refused the removal).

## 2026-11-08 — Snapshot A: `docs/STATE.md` as it stood at run 46's close (main c8d9cf5), before the split

Everything here was the whole live-state file: the release history of Aki and Bubble Trouble X, every finished Ferazel
phase and run narrative (in the one long Ferazel bullet), the RE-bank lanes, Deimos and Cythera to their 2026-11-05
re-plans, and the carried items as they were then. What is still live was rewritten, current-only, into `docs/STATE.md`.

#### STATE — Ambrosia Classics — 2026-11-07 night (Ferazel: re-planned 2026-11-04 (remainder spec/plan/audit under `docs/superpowers/`), Ben's answers D45 2026-11-07 — Phase 4 + Windows gates PASSED (Q11 Fireball-only, Q14 on Andrew's word), HectorKit follows kit main (ef2c341, floor 370), Phase 6 = three gates, release = one `ferazel-1.0`; **attended run 46 (Fable seat, 2026-11-08) closed wave 5.4: the enemy pipes + the renderer's traps as refusals — Core 607 = 605 + 2 opt-in skips, WinKit 81, Proof B 604/0/3/0**; next = run 47 (level 5's ogre + level 5), started by the re-plan repair session from its rebuilt chip — NOT chained by run 46 (Ben 2026-11-08); the loop stays stopped; BTX 1.1 gamepad; Cythera + Deimos re-planned 2026-11-05 (await Ben's go); Aki 1.0 + BTX 1.0 released)

> Live state only. Dated; re-verify before acting. Narrative goes in handoffs, forks in DECISIONS.

#### Where we are

- **Bubble Trouble X gamepad — DONE, merged to local main, NOT pushed / not released (2026-10-22, D36, HectorKit D16).**
  A controller (Switch Pro first; Xbox / PlayStation / Joy-Con) acts as BTX's original keys, Mac and Windows: layout
  `BubbleTroubleX/Shared/BTXPadLayout.swift` (current key set in play, every face button pushes, + pauses via a Caps
  Lock latch, − held 1 s = Esc; outside play face/+ = Return, − = Esc, d-pad = arrows), user notes
  `BubbleTroubleX/GAMEPAD.md`. Kit: new Foundation-only `HectorInput` (translator, re-exported by HectorShell),
  `ShellGamepad` (GameController), `ShellView.padMapping` (nil default — Aki/Deimos/Ferazel unchanged), HectorSDL
  gamepads; HK floor **361** (was 328), HectorSDL 48/0. Classics: BTX core 261/0/0 (Core untouched), Windows package
  126/0/0, cross-build OK; BubbleTroubleX/Aki/AkiPad/Deimos/Ferazel build. Every task Opus-implemented + Opus-reviewed;
  Fable plan review + phase-end review (READY_TO_STAGE). Staged `~/Desktop/Bubble Trouble X.app` + GAMEPAD notes.
  **Ben's real-controller check 2026-10-23 (Mac build): GAMEPAD.md steps 1–5 PASS** (title start, d-pad + stick,
  push with all four face buttons, + pause/resume, hold-− to end). Step 6 (high-score dialog OK) untried, not failed.
  **BTX 1.1 release (Ben's go, 2026-10-23): main + HectorKit PUSHED; GitHub release `btx-1.1` is a DRAFT** (target
  8f804cc, HK 35a85ba): notarized+stapled universal `BubbleTroubleX-1.1.dmg` (sha 81c20fa3…) + `BubbleTroubleX-1.1-Windows.zip`
  (sha cd83afb9…); downloads re-verified; copies in `releases/btx-1.1/`; notes `docs/release/btx-1.1.md`.
  **Owed:** Ben tries the browser-downloaded DMG → publish → then update README's BTX download link/badge to 1.1.
  The Windows pad path is still untested on hardware (his brother). Ferazel adopts via its own
  plan (set `padMapping`, implement `padKeyDown`). Plan `docs/plans/2026-10-22-gamepad.md`.
- **Ferazel's Wand is on the unattended session loop (2026-10-13, D34).** Live Ferazel state now lives in
  `docs/NEXT.md` (the loop's chip; first line `STATUS: …`), `docs/LOOP-LOG.md` (one line per run) and
  `docs/QUESTIONS.md` (what only Ben can answer — his phase gate cards queue there; he is away in Fiji). Each run
  updates the Ferazel bullet below at its close. **Latest (attended run 46, 2026-11-08, Fable seat — D45.7 chain): the enemy pipes alive (`World/Movers/BoxSprite.swift` pipe arm; the shared run-time spawn now makes Walkers and Blobs as well as bats; a pipe waits for its child to die before the next — dump over card) → 607; the renderer's 18 traps → 7 refusals + 11 census-pinned traps, two level-header refusals at open (OmniPx rain/interlace, horizon strip) → 607; **wave 5.4 CLOSED**: G2 607 = 479 + 128 / 0 / 2 skips by name, G3 1,108/0, GE core 3,360/0 + 86,400/0, Proof B 604/0/3/0 of 607, GW4R identical, GW1–GW4 + G5 green, G1 ef2c341/370. **Method (Ben 2026-11-08, D44 as-built run 46):** STATE/NEXT hold only the current run (history moves out at close); the re-plan becomes one self-contained plan + a small chip (the repair session owns it); the seat never pre-reads source; sweep + bot only after level tasks and at phase ends. **Next: run 47 [OX LV5]** — started by the repair session, not chained here. Previous (attended run 45, 2026-11-07): the Dillo alive (`World/Enemies/Dillo.swift`: idles, walks its patrol band, curls and fires 5- or 7-spine volleys, lays egg bombs, jumps, rolls when a level asks; armour turns every shot from behind or while curled, Statue spell included; retaliates after a landed hit; the unplaced types 1872–1879 refused at Setup, ◇) → 596; geysers alive (`World/Movers/Geyser.swift`: the water / acid / lava column rises and falls on the level clock, its head and segments hurt by kind, spray particles in the binary's draw order, no sound as the original; §9 (b) NR 2–4 as settled; dump over bank: the head sorts at layer 2 and only the segments hurt enemies) → Core **603** = 601 + 2 opt-in skips (475 rules + 128 render), WinKit 81 = 79 + 2, Windows gates GW1–GW4 green, G5 green; ◈ none (no built level places either). HectorKit main ef2c341, zero-skip 370. **Next: run 46 [PI PT]** — the enemy pipes, then the renderer's traps into the refusal census; PT closes wave 5.4 (G3, GE core on levels 1–4, GWB by day). Previous (attended run 44, 2026-11-07): Blobs and Crabs alive (`World/Enemies/BlobCrab.swift`; the Multi Crystal is not lost to a Blob's touch; the Kill-proc arms for Crawler / Roach / Bat / Blob dropped per audit 4) → 584, wave 5.3 closed (census 1,108/0, visit sweep 3,360/0, bot 86,400 steps/0, Proof B 581/0/3/0 of 584, Mac SDL smoke identical); Gremlins (body + rider, radial paths admitted — `ProgrammedPath.makeRadial`'s first caller) and Wraiths alive (`World/Enemies/GremlinFloater.swift`; the unplaced Wraith variant 0x6fe–0x707 refused at Setup, ◇) → Core **591** = 589 + 2 opt-in skips (463 rules + 128 render), WinKit 81 = 79 + 2, Windows gates GW1–GW4 green; ◈ none (one BootFaces level-3 pin moved for the Blob turning on, switch-off held). HectorKit main ef2c341, zero-skip 370. **Next: run 45 [DL GY]** (NEXT.md re-seeded; the next attended session started at this close per D45.7). Previous (attended run 43, 2026-11-07): the Bat's fix round → 569; Frogs and Salamanders → 577 (the Frog's aim reads player X, bank §1.3 corrected); D45 Ben's answers. Previous: (loop run 41, 2026-10-31, 09:09 → day): CR ⚑◈ (Crawlers and Roaches alive) + WK2 ⚑◈ (the boulder-throwing goblin 1760 and the Ax goblin 1750) merged, wave 5.2 closed — Core 560 = 558 + 2 opt-in skips, WinKit 81 = 79 + 2, census 1,108/0; wave-end visit sweep (3,360 visits, 0 failures) and random-play bot (levels 1–4, 0 failures) clean, Proof B 557/0/3/0 of 560 and the Windows dev-build smoke clean by day (16:xx, muted); D44 "As built — run 41"; next run 42 = BA ⚑◈ → FR ⚑◈.** Start/stop: `.looper/config.sh` header. History per run: `docs/LOOP-LOG.md`. **Phase 2 "Ferazel moves"** machine-closed (loop run 7), staged d5586fb at `~/Desktop/Ferazel's Wand.app`, Ben's gate pending (QUESTIONS Q2). **Phase 3 "Front end + saves"** planned (loop run 8, `docs/plans/2026-10-14-ferazel-phase3.md`, D35; ladder 256 → 345, Q3 = Ben's four non-blocking choices). Waves 3.0–3.1 (runs 9–10: carry sweep, dialog parsers, G image + save block, prefs/saved-game files, front-end seam, fades, Options model) → 284/0. **Loop run 11 built L2 L1** (wave 3.2 closed: chapter card, stage-load popup + bar, stage-complete panel; `LevelRun` — level entry, 2-tick cadence, death/complete/abort exits — with tagged `.level`/`.screen` op segments for A1a) → 297/0. **Loop run 12 built RX M1 M2** (wave 3.3: Roach write-back, `WorldMapRun`, `MapRenderer`) → 308/0. **Loop run 13 (2026-10-24, after the pause 10-14 → 10-24)** applied Ben's answers (Q4 → D37: Ferazel gets controller support as Phase 3 task GP, ladder 345 → 349; Q3 defaults recorded in D35) and built **F1a D1 F1b** (wave 3.4 closed: `GameFlow` — boot logo + load bar, main menu, Quit, Credits, Options; the death screen; New Game ⇄ world map ⇄ level, Continue from a save, death → Continue/Abort) → Ferazel/Core **323/0**, census 1,108/0, Ferazel builds. **HectorKit pinned at 35a85ba, zero-skip floor 361** (moved by the BTX gamepad work; no Phase 3 task changes it). **Loop run 14 built S1 P1** (wave 3.5 closed: the resumable frame and the save point — hold, save prompt/reuse, success flash, statue faces, GameFlow carries the save state; `.CheckGameLoopKeys` ⌘Q/⌘W/⌘P/Esc and the Caps Lock `.Pause`; graphics-mode-3 black lines) → Ferazel/Core **335/0**, census 1,108/0, Ferazel builds. **Loop run 15 built EC C1 C2** (wave 3.6 closed: every save-error report carries its code; conversations and signs inside the suspended frame — NPC/sign arms, the Mcnv interpreter; `ConversationRenderer` with the boot-time system-clut frame) → Ferazel/Core **345/0**, census 1,108/0, Ferazel builds. **Loop run 16 built A1a A1b** (wave 3.7 closed: the app runs on `GameFlow` — title, menu, world map, levels, save points, conversations, death screen, saved-game files, Finder open — with the original's dialogs (confirm, reports, Options with key remapping, Credits) and MBAR 128 menus, live only at the main menu and in the pause) → Ferazel/Core **345/0** (unchanged by design), census 1,108/0, Ferazel builds. **Loop run 17 closed Phase 3 on the machine side:** GP (a game controller acts as the original keys, D37; − is a 1 s hold in a level, on the map and on the death screen) → Ferazel/Core **349/0**; A2 staged build 3553392 at `~/Desktop/Ferazel's Wand.app` + WHAT-TO-EXPECT (the Phase 3 gate card) — two clean boots (first launch of the new front end: reaches the main menu, quits clean), Fable phase-end review "stage as is" after doc fixes. **Ben's gate: QUESTIONS Q6** (and Q2 for Phase 2, Q5 the quit-wait). **Loop run 18 planned Phase 4 "Spells + items"** (`docs/plans/2026-10-24-ferazel-phase4.md`, D38: 24 tasks + phase end, 12 ⚑ MAJOR, ladder 349 → 481, levels 1–4 enterable at its end, no HectorKit change; two Opus legs + FABLE-GRADE leg, both fix rounds applied; Q7 = Ben's three non-blocking choices). **Loop run 19 built wave 4.0 [X1 VS LT]** (carry sweep; `SoundVoices` — the original's "is this sound playing?" query, fed by the app's mixer each tick; the light table moved into Core as `LightTable` + `DrawOp.lightTable`, no golden moved) → 357/0. **Loop run 20 built wave 4.1 [US IV HU]** (dying sprites cleared after four passes and positions saved back to the level's records as the original; the inventory operations; the status bar drawn from the live game state — inventory, counts, maxima, flashes, the selection step at every bar call, the health-bar clamps and the suffocation tick; no golden moved) → Ferazel/Core **374/0**, census 1,108/0, Ferazel builds, HK 35a85ba untouched. **Loop run 21 built wave 4.2 [TB BN PK]** (TB inserted by the seat: translucent sprites (draw mode 0xb) — the spheres need it once the Bonus sprites run; the Bonus sprites animate, glint, flicker and fall; touching a pickup collects it — Xichrons, crystals, coins, scrolls, items, upgrades with their 2-second animation; hurt coins fly out; goldens moved for those causes only, each confirmed) → Ferazel/Core **393/0**, census 1,108/0, Ferazel builds, HK 35a85ba untouched. **Ben 2026-10-25 passed Phases 2 and 3 with notes (Q2, Q6 → D39) and ruled that Apple system fonts may ship (Q8).** **Loop run 22 built wave 4.2F from his notes:** TX — text drawn smoothed as Mac OS 9 drew it (conversation text; sizes under 14 pt stay crisp as in the Let's Play) → Ferazel/Core **396/0**; SP — speed measured, no change: the port runs at the original's own cap (30 game steps a second), the Let's Play ~20 % slower because the emulator could not keep up → Ben decides in **Q9**. **Loop run 23 built wave 4.3 [EF CS]:** explosions and their lights, the big explosion's hurt, crate debris, the alternate-frame mask flash and the camera shake (carried across levels as the original; the shake zeroed only by New Game / Continue); casting — the USE gate, the wand animation, every spell's `.CastSpell` — and the shots in flight (followers, lights, the Boomerang homing, V Blade, fizzling in liquid); plus the original's shot-death routine (built early: springs kill shots through it) → Ferazel/Core **412/0**, census 1,108/0, Ferazel builds, no golden moved, HK 35a85ba untouched. Shots pass through walls until the next wave. **Loop run 24 built wave 4.4 [SH GL PU]:** shots now hit things — walls, crunchable cells, water, torches and rock piles that open (crystals fly out), the ice wall, the stalactite, the Boomerang caught back for magic, seeds that bounce then explode; the hang glider (deploy, glide with pitch and wind, steer, dive, land and stow); power-up timers that warn with ticks and a blink and then run out (Featherfall, High Jump, Double Speed with its trail, walk-on-liquid, Invincibility) → Ferazel/Core **431/0**, census 1,108/0, Ferazel builds, no golden moved, HK 35a85ba untouched. **Loop run 25 built wave 4.5 [IU MS]:** using an item — the dagger, Ice Pick and Vorpal Dirk stab, seeds are thrown, health and magic potions are drunk, the Smiting Ring strikes every enemy on screen, the Escape Ring leaves the level, and selecting a key, shield or Red Xichron makes Ferazel say why you don't need to (the hint talks inside the frame, also during a pause); the shield now needs a shield; the Mist potion turns Ferazel into a spirit that floats through walls and must get back to his body, the Resurrection Necklace revives him once, the Fire Charm blocks fire, a Multi Crystal is lost after being hurt → Ferazel/Core **444/0**, census 1,108/0, Ferazel builds, no golden moved, HK 35a85ba untouched. Ben answered Q9 (keep the original's speed; D39 addendum). **Loop run 26 built wave 4.6 [SD BX1]:** the Shadow Double (a ghost of Ferazel that copies his moves 14 frames behind and copies his spells) and the Pentashield orbs that circle him and break on things; crates that fall, settle, can be pushed and smashed (dropping their pickups, the explosive crate blowing up), the spin stomp that breaks crates, rolling boulders, mine carts and falling stalactites → Ferazel/Core **457/0**, census 1,108/0, Ferazel builds, no golden moved, HK 35a85ba untouched. Ben answered Q5 (a Dock/app-menu Quit during a level now shows the game's quit box at once; logout quits at once — a deliberate departure, D40) and Q7 (defaults stand). **Loop run 27 built QT + BX2 + BT:** a Dock or app-menu Quit during a level now shows the game's own quit box (also when pressed during the level's opening screens), a logout quits at once (D40); chests open (locked ones need their key, and drop their contents one every four frames), doors unlock with keys and open when walked into from the right side, thought balloons show the needed key near a locked chest or door; Buttons (momentary and latching, pressed by Ferazel, boxes or shots), gates that rise, switch blocks that appear and vanish, boulder spouts (their boulders come in Phase 5) → Ferazel/Core **472/0**, census 1,108/0, Ferazel builds, no golden moved, HK 35a85ba untouched. Ben answered Q10 (D41): a Ferazel Windows build straight after Phase 4, before Phase 5, then the Windows twin kept in lockstep. **Loop run 28 built TP + SW:** teleporters (stand on one until it charges, the screen breaks into a mosaic, Ferazel reappears at the partner teleporter, the mosaic clears) — wave 4.7 closed; the spells now change the world: the Ice Wall makes ice floes on water and ledges on walls, the Tree Trunk plants a trunk that grows when hit again and blinks out, the Statue spell freezes a moving platform for a few seconds (Ferazel can stand on it) → Ferazel/Core **482/0**, census 1,108/0, Ferazel builds, no golden moved, HK 35a85ba untouched. **Loop run 29 built LV3 + LV4:** levels 3 "Western Reaches" and 4 "Eastern Reaches" can now be entered from the map — every placed thing sets up, the retracting spikes stab and hurt, the level-load bar counts each level's pictures as the original, level 5 shows "not built yet (Phases 5-6)" — wave 4.8 closed → Ferazel/Core **490/0**, census 1,108/0, Ferazel builds, no golden moved, HK 35a85ba untouched. **Loop run 30 closed Phase 4 on the machine side:** the gate card `Ferazel/WHAT-TO-EXPECT.md` rewritten as built, staged at `~/Desktop/Ferazel's Wand.app` (build 4bca4bd; two clean boots), Fable phase review passed with card-only fixes (no code divergence from the original) → Ferazel/Core **490/0**, census 1,108/0, Ferazel builds, HK 35a85ba untouched. **Ben's gate: QUESTIONS Q11.** Two gaps handed to Phase 5: the underwater screen tint (missing since Phase 2) and the Magical Shield's crouch picture. **Ben's Q12 (2026-10-26, D42):** the loop launches a build only muted (a tested mute switch) and never 21:00–09:00. **Loop run 31 planned Phase W, the Windows twin** (`docs/plans/2026-10-26-ferazel-windows.md`, D43: WF0–WF6, 3 ⚑, Ferazel/Core stays 490, a new `Ferazel/Windows` package 0 → 77 macOS-hosted tests, Proof B 490 in CrossOver muted by day; no HectorKit change; two Opus legs + FABLE-GRADE leg, both rounds applied; Ben's six choices Q13, defaults (a)). **Loop run 32 (2026-10-26/27) built WF0 + WF1:** the game's core and its whole test suite now cross-build for Windows (the Windows-only differences removed — environment, links, the census tool's location, line endings, a text-replace trap; new `tools/windows/proof-b-ferazel.sh`, which refuses by night and forces no-sound); the Mac app's platform-neutral half moved to `Ferazel/Shared/` (`FerazelDriver`, `FerazelAudio`) unchanged in behaviour, with the mute switch `-FerazelMute YES` / `FERAZEL_MUTE=1` (no audio output, no beeps) and a silent stand-in mixer for headless frame runs; the new `Ferazel/Windows` package (FerazelWinKit, symlinked shared files) has **17/0** macOS-hosted tests → Ferazel/Core **490/0**, census 1,108/0, all five apps build, HK 35a85ba untouched. **Loop run 33 (2026-10-27, 01:34–06:xx, all night) built WF2 + WF3:** Windows draws the game's text from five baked font files (`Ferazel/Windows/Resources/Fonts/`), equal byte for byte to the Mac's text on every character, level name, score, item count and two whole routes; `FerazelWin`, the Windows game executable on HectorSDL (loop, keys, Ctrl shortcuts from the menus, pad, quit confirm, files, hidden switches, `--mute`, headless `--frames/--dump/--keys/--seed` with pinned seed and clock), cross-builds and links for Windows (GW3) and builds as a Mac SDL development build (GW4); `Ferazel/Shared/FerazelMenuRules.swift` holds the menu rules both shells use (Mac unchanged); `tools/windows/smoke-ferazel-win.sh --mac-only` written (refuses by night) → FerazelWinKit **46/0**, Ferazel/Core **490/0**, census 1,108/0, Ferazel app builds, HK 35a85ba untouched. **Loop run 34 (2026-10-27, 06:16–11:xx) built WF5, WF4a, WF4b ⚑ and a Proof B parity fix (WF0b):** saved games on Windows through the native Open / Save dialogs (compiled and linked, never run); the original's confirm and report dialogs, Options and Credits drawn inside the Windows game window, behaving as the original (Esc does nothing on the confirm; the Options keys follow the original's filter); the dialog font equals the Mac's exactly. **First daytime launch checks done:** the Mac SDL development build boots muted to a main menu identical to the reference; **Proof B (the whole core suite run in CrossOver, muted) = 489 passed / 0 failed / 1 skipped / 0 crashed (of 490), ~4 min 40 s** — CrossOver's Wine lacks one Windows function Foundation uses, so file sizes are read another way on Windows and the one test that launches the census tool skips under Wine only (it runs on a real PC) → FerazelWinKit **77/0** (the phase ladder's top), Ferazel/Core **490/0**, census 1,108/0, Ferazel app builds, HK 35a85ba untouched. **Loop run 35 (2026-10-27, by day) closed Phase W on the machine side:** a Windows stage script and a CrossOver smoke that checks three pictures (menu, level 1, level 1's text at full brightness) against the Mac's; both builds staged on the Desktop (`Ferazel's Wand.app`, `Ferazel's Wand (Windows).zip` + folder); booted muted by day — the Mac app quits clean, the Windows zip draws all three pictures identically in CrossOver, Proof B 489/0/1/0; Fable phase review passed with small script/card fixes. **Ben's and Andrew's Windows gate: QUESTIONS Q14** (card `Ferazel/WINDOWS-WHAT-TO-EXPECT.md`; please try a real save and restore). Next: the Phase 5 plan (enemies), lockstep Mac + Windows from its first task. **Ben's attended sessions (2026-10-27 → 10-30, not loop runs):** Andrew's Windows tests found the teleporter sparkle (draw mode 5) refused → the game quit on both shells; fixed (0fd056e, + mode 0xa), then the teleport/passage re-seat (78e81c3), the level-2 light shrink and level-3 rope faces (48a0620), every boot face loaded as the original (b535527), Continue refuses unbuilt-level saves (e9fa8b0); the port gap ledger `docs/ferazel/port-gap-ledger.md` (nothing game-ending left in levels 1–4; watch list for 5+) and the visit-every-object sweep `tools/ferazel-visit-sweep.sh` (opt-in test, skips in a normal run) → Ferazel/Core **502 = 501 passed + 1 opt-in skip**, FerazelWinKit **79 = 78 + 1**; Windows test builds 1–4 published; Andrew confirmed save, restore and level 1 → map → level 2 on a real PC; follow-ups = QUESTIONS Q15. **Loop run 36 (2026-10-30) planned Phase 5 "Enemies"** (`docs/plans/2026-10-30-ferazel-phase5.md`, D44): Q15's follow-ups first (Proof B fixed for the opt-in skips, sparkle scroll, draw-mode audit, random-play bot), then every enemy class, enemy shots, damage, pipes and geysers, the underwater tint and the shield crouch face, and level 5 open up to the Warrior's arena (the Warrior a stand-in until Phase 6); 22 tasks + phase end, 13 ⚑, ladder Core 502 → 617, WinKit 79 → 81, no HectorKit change; two Opus legs + FABLE-GRADE leg, all findings applied; Ben's five choices Q16. Next: run 37 = PB → SP → RV. **Loop run 37** built PB SP RV (509). **Loop run 38** built DK UT DA (516): a lit sprite at full darkness under the brightest light no longer quits the game; the screen tints under water as the original; a standing audit test proves no picture the port refuses can be reached in levels 1–4. **Loop run 39** built RB EC (526): a random-play bot plays every built level for minutes through both shells' real paths and fails on any quit, refusal, error box, freeze or crash (`tools/ferazel-random-play.sh`, with Ben's memory limits); the enemy foundation every enemy class will plug into — still switched off until each class's own task. **Loop run 40** built ES WK1 (546): enemies' shots exist — thrown axes, boulders that bounce and split, spit, the Wraith's homing shot — the shield blocks and reflects them (the Magical Shield turns a Wraith shot back), the boulder spouts on level 4 fire; the goblin Walkers (axe throwers and spear guards) now walk, throw, block, thrust, get hurt, die, drop coins and leave a corpse that floats as a raft. **Loop run 41** built CR WK2 (560): Crawlers drop from ceilings, wind up and leap, Roaches patrol, both flee, get crushed, hurt and killed; the level-4 goblin throws boulders (or bombs) and the Ax goblin (first placed on level 10) swings, jumps and lands — wave 5.2 closed; two level-1 golden pictures moved because a Crawler wakes on those routes.

- **Phase 0 DONE (2026-10-03).** HectorKit **v0.1.0** (`~/Developer/HectorKit`, tag on f578925): HectorResources /
  HectorGraphics / HectorAudio lifted from EV e23122f + the new banded-QuickTime decoder; machine gate
  `tools/check-zero-skip.sh` PASS at **floor 119** (0 skips with the three `HECTORKIT_DATA_*` vars; EV Override
  forks + Aki 1.1 data). Classics: `Aki/Core` (AkiCore + `aki-census` + 6 data-gated tests, 6/6) and
  `docs/aki/data-census.md` (tool output: 82 PICT = 71 QuickTime + 11 raw, all decode to frame; 50 PNG; 14 + 15
  audio files open; 0 `snd `). Plan: `docs/plans/2026-10-03-phase0-hectorkit-lift.md` (DONE).
- **Replica target is 1.2.0** (Ben's ruling 2026-10-03, recorded by the RE lane in `docs/aki/INDEX.md`; all
  1.1↔1.2 deltas resolve to 1.2). Art therefore comes from the 1.2.0 PNGs (same native sizes as the 1.1 PICTs;
  `data-census.md` §3 maps them); the PICT path stays as oracle and for Bubble Trouble.
- **RE-bank lane COMPLETE (2026-10-03, head 01cb120):** `docs/aki/`, `docs/bubble-trouble/`, `docs/cythera/`,
  `docs/deimos/`, `docs/ferazel/` — each Opus-built, Fable-reviewed (all ACCEPT_WITH_FIXES), fix-passed;
  handoff `docs/handoff-2026-10-03-re-bank.md`; optional deepening = RESUME Trigger A2.
- **Deimos RE deepening CLOSED (2026-10-06):** waves 1–4 on main — 100 % of game code read (0 unread by census). Wave 3+4 fix pass (`docs/deimos/FIXPASS-wave3-2026-10-06.md`: review I1/M1–M7, critic C1–C9, stale NRs, label audit; one reversal seat-verified) + critic §6 micro-wave (`docs/deimos/micro-wave-2026-10-06.md`, every claim spot-checked HIGH) folded in: role table **938 rows = 716 HIGH / 222 MED / 0 LOW**; INDEX #40 #47 #48 #54 #58 #60 closed, #62–#64 new. Still open: #13, #59 residue, #62–#64, the 134 cross-file HIGH/MED label mismatches (critic), Ben's ear/eye items (handoff 2026-10-04-deimos-re-wave34 "Owed by Ben").
- **Deimos Rising build (D27, Ben 2026-10-06): design + Phase 1 plan written** on branch `deimos-phase1` (5106149, unreviewed, not executed) — Phase 1 = gate 1 "level 1 look". Handoff `docs/handoff-2026-10-06-deimos-phase1.md`.
- **Deimos Rising Phase 0 DONE (2026-10-06, on main; plan `docs/plans/2026-10-06-deimos-phase0-data.md`,
  DECISIONS D22/D24):** original data in git (`Resources/Deimos/Data` four paks + Local film; app fork as
  `Resources/Deimos/Deimos Rising.rsrc`); HectorKit `StoredZipArchive`/`AIFFAudio`/`WAVEAudio`/`SoundFile` + PICT 0x009B
  (main `33d4dee`, floor 301); `Deimos/Core` 104/0/0; `deimos-census` 872 entries decoded, 0 failures, PICT 12/12,
  DITL 6/6 (`docs/deimos/data-census.md`). **Phase 1 (the build plan) needs:** the game's continuous-IMA effect decode +
  16-voice/8-audible mixer, music streamed from the pak range, the glyph map over `tesm`, the MED colour rules (plan
  notes 15/21). **Ben's eyes:** INDEX #10 — `deimos-census --render out/deimos-render`, is `menu.png` upright?
- **Deimos Rising Phase 1 — level 1 look: GATE 1 PASSED (Ben, 2026-10-07: "it looks okay!"; D30 — runs at OS X's
  60 Hz tick, Ben played on OS X) (2026-10-07, Opus 5.5 orchestrator,
  Opus implementers / Fable reviewers; plan `docs/plans/2026-10-06-deimos-phase1.md` + review record `…-phase1-REVIEW.md`;
  DECISIONS D29 + as-built addendum):** K1 `ShellView.scalingPolicy` on HectorKit main 522feb8 (HK D13, floor **316**);
  `Deimos/Core` grew DeimosRender + DeimosHost — suite **189/0/0** (plan ladder 177 + 13 from three review fix passes − 1
  KeyTable moved to Core); census unchanged; Deimos + Aki + BubbleTroubleX BUILD SUCCEEDED. Every task Fable-reviewed
  (MAJOR tasks two legs); one Critical found and fixed (held Esc hung the driver). Frame goldens independently re-derived
  in Python. Staged **~/Desktop/Deimos Rising.app** + WHAT-TO-EXPECT (gate card). Q1 ruled 60 Hz (D30), restaged.
  Next: the Phase 2 plan (level 1 plays; de01 film replay gate). Carries for Phase 2: `DeimosAudio`
  target (design M6), `playerOps` return type, `HeadlessRun` film params, Phase-4 prefs file widening (C1 review m3).
- **Deimos Rising Phase 2 — level 1 plays: RE-PLANNED (2026-11-05, Fable re-planning pass, `replan.md`; D45).** Branch
  `deimos-phase2` (44 commits, pushed, unmerged; worktree `.claude/worktrees/inspiring-cannon-e97ccd`): waves 2.0–2.5
  reviewed, 2.6 built; suite **313/0/0** against both HectorKit e595472 and current main ef2c341. Audit of the branch
  (`docs/superpowers/audits/2026-11-05-deimos-phase2-audit.md`): 0 rules wrong, 0 redo, 23 change, 12 missing; the three
  owed legs discharged. Spec `docs/superpowers/specs/2026-11-05-deimos-remainder-design.md`; plan
  `docs/superpowers/plans/2026-11-05-deimos-remainder.md` (wave 2a: audit fix round → 318, merge to main, bank
  corrections; wave 2b: C12 → 327, C18a → 335; then cards). Handoff `docs/handoff-2026-11-05-deimos-replan.md`.
  **Waits for Ben's go.**
- **Originals:** Aki 1.1.0 + 1.2.0 UB (symlinked as git-ignored `Resources/Aki/1.1.0.app`, `1.2.0.app`);
  Bubble Trouble X 1.1 UB; Ferazel's Wand 1.0.3, Deimos Rising 1.0.6, Cythera 1.0.4 (PEF).
  Archive map: `~/Developer/Ambrosia/docs/ARCHIVE-INDEX.md`.
- **Local-path dependency:** `Aki/Core` → `../../../HectorKit`; a worktree needs the untracked symlink
  `.claude/worktrees/HectorKit → ~/Developer/HectorKit` (Classics DECISIONS D1).

- **Aki Phase 1 DONE — Ben's verdict 2026-10-04: "yes it absolutely is Aki"** (splash + map gate passed). Plan
  `docs/plans/2026-10-03-aki-phases-1-3.md` (contracts not code). P1.2–P1.13 all reviewed MERGEABLE (Opus
  implementers, Opus/Fable reviews; fix round for P1.9/P1.10 at 5da2bf0); merged to main this session. AkiCore 31
  tests / 0 skips; `xcodegen generate && xcodebuild -scheme Aki build` BUILD SUCCEEDED; `tools/stage-aki.sh` →
  `out/Aki/Aki.app` (50 PNG + bundled `Fonts/OsakaMono.ttf`). HectorShell is the HectorKit session's (main
  5a33384+, floor 167 at the gate). Rulings this session: DECISIONS D4. Handoff `docs/handoff-2026-10-04-aki-phase1-done.md`.
- **Bubble Trouble X 1.0 — RELEASED 2026-10-06 (Ben tried the downloaded DMG, said "publish"; DECISIONS D25):** GitHub release `btx-1.0`
  (tag on 47d7c98) carries `BubbleTroubleX-1.0.dmg` (12.6 MB, Developer ID + notarized + stapled, universal, built by
  `tools/package-btx-release.sh`) and `BubbleTroubleX-1.0-Windows.zip` (36.9 MB, stamp 6832da1, unsigned) + .sha256s;
  README + `docs/release/btx-1.0.md`. Next releases: bump `CFBundleVersion` in BubbleTroubleX/App/Info.plist, then
  `tools/package-btx-release.sh --version X.Y --sign "Developer ID Application: Benjamin Thomas (5W72UJL332)" --notarize oniarm64-notarize`.
- **Bubble Trouble X PLAYABLE WITH SOUND (2026-10-04/06, Opus 5.5 orchestrators, plan `docs/plans/2026-10-04-btx-playable.md`,
  DECISIONS D12/D13/D14):** every plan task merged and Opus-reviewed (T0, C1–C8, R1, A1–A4), then 2026-10-06: K3
  `ShellMixer` merged to HectorKit main d9fdfa4 (kit gate floor **222**, zero skips; C1 off-main-thread regression test
  proven to trap pre-fix), A5 wires it in (4 effect voices + music, silent fallback without a device), A6 effects at the
  Sound Tool's 0x80-unity law + `_StartMusic` carries on (sound audit `docs/bubble-trouble/sound-audit-2026-10-06.md`: all
  146 registered effect sites and music per level set match the original). Gates at Classics main (seat-run): core
  **258 / 0 / 0**; BubbleTroubleX + Aki BUILD SUCCEEDED, 0 warnings in our code; FILM replay traces 1–4 = baseline.
  Staged **~/Desktop/Bubble Trouble X.app** (Release, with sound) — Ben: "feels so close", speed right; he is playtesting
  "for a while"; unsure about music per set / missing effects (audit says both right; effects were half as loud — fixed
  in the restaged build). Prefs domain `com.ambrosiaclassics.bubbletroublex` holds his play since Oct 5 — never clear it.

- **Bubble Trouble X on Windows — PLAYABLE, STAGED FOR TESTING (2026-10-06, Opus 5.5 orchestrator; plan
  `docs/plans/2026-10-06-btx-windows.md` W0–W7 all done; DECISIONS D15/D16/D18/D19/D21).** Cross-compiled on this Mac
  (`tools/windows/`, cache `~/Developer/Toolchains/windows-cross`), Mac app untouched. `BubbleTroubleX/Windows`:
  BTXWinKit (driver port, baked fonts, in-window Carbon dialogs, prefs file under `%APPDATA%\Ambrosia
  Classics\Bubble Trouble X\`) + `BubbleTroubleXWin` on HectorKit `SDL/` (HectorSDL). Tests: Windows package 113/0/0;
  BTX core 261/0/0 on the Mac and 260/0/0 in CrossOver; HectorSDL 38/0; kit floor 252. **Staged:**
  `~/Desktop/Bubble Trouble X (Windows)/` + `.zip` (37 MB; `tools/windows/stage-btx.sh`; stamp 83febbe) — Ben sends it
  to his brother — **public link: GitHub pre-release `btx-windows-test-1` (repo now PUBLIC, D20)**; Ben heard it play with sound in CrossOver; fresh CrossOver bottle reaches the menu, level 1 and every dialog, dumps = the Mac SDL build. **Real PC verified 2026-10-06 by Ben's brother** (played to level 20, high-score entry, idle attract demo all work). Sound fine on the real PC (Ben, 2026-10-06). Esc ends the game with no "are you sure?" — original behaviour, kept. **Automation: `HECTOR_SDL_AUDIO_DRIVER=dummy`
  (CrossOver strips `SDL_*`).** **D21 (Ben): no menu bar — game-only 640×480 window (2× on 1080p), Ctrl shortcuts kept, About gone; merged f482270, restaged and the release asset replaced in place.** Next: any fixes from the brother's play; then Aki on Windows.

- **Ferazel's Wand — DESIGNED AND PLANNED (2026-10-06, Fable orchestrator; DECISIONS D26):** Ben's brainstorm rulings
  (whole game + Windows; first gate = level 1 look-and-feel; front end early; 640×480 integer scale; longplays + his
  Let's Play link as the feel oracle). Design `docs/plans/2026-10-06-ferazel-design.md` (APPROVED); plan
  `docs/plans/2026-10-06-ferazel-phase1.md` (Phases 0 + 1, 15 tasks K1/C0–C6/R1–R6/A1–A2, 7+1 ⚑ MAJOR; Opus planner,
  Fable review ACCEPT_WITH_FIXES 3 Important / 12 Minor, all applied; ladder Ferazel/Core 6 → 100 tests, HectorKit floor
  289 → 301). Planner probes found two bank gaps now in the plan's "Bank corrections": face pixels go through
  Color2Index at load (sheets carry their own palettes) and 326 PICTs are 32-bit `ditherCopy` — both LOW, both on the
  gate card. **Phase 0 K1 + C0 + C1 DONE (2026-10-06, Opus orchestrator):** HectorKit `PICT.decodePixels` (indices + public 16-bit `ColorTable`, v1 BitMaps, DirectBits RGB + mode; HK D12; HK main d38a541, **floor 313** — the plan said 301, Deimos had already added 12); data in git `Resources/Ferazel/` (6 `.rsrc` + 28 AIFC, `cmp`-identical; D26 as-built); `Ferazel/Core` package + `FerazelData`/`FerazelResources`/`ResourceChain`, **6/0** tests. **C2–C5 DONE (2026-10-07, Opus orchestrator; two Opus review legs per MAJOR):** world parsers
  (Mlvl/Mwld/Mmap/Mcnv/STR#, placements, sprite class table) · ColorLUT / SoundBank / MusicTrack · TableRequests +
  ColorSearch (`.ruled` default, `Prepared` fast path) + the Color2Index measurement · faces (PICT → indices, ditherCopy
  model, 1-bit bypass, EncodeRect RLE, face/plain/water/blend sheets, tile sets); ladder 6 → 21 → 28 → 43 → **56/0**.
  **Ben 2026-10-07: follow the binary** where plan/bank disagree with the PPC code — C4 water 1 / glow 014c / grey-pull
  0144 keep the original's 32-bit overflow (Color2Index all-sixteen 1,178,146, not the plan's 1,178,143); C5 FG/FG-water
  convert under the level CLUT (201 on L1), fixed sets 183/185 under clut 199 (D26 as-built C4 + C5; bank ⚑ Corrections in
  lighting-tables and sprites-backgrounds-sounds). HectorKit untouched (main 522feb8, floor 316 — Deimos's
  `ShellView.scalingPolicy` `.integerFit` is there; Ferazel A1 reuses it).
  **C6 + R1 DONE (2026-10-07, Opus orchestrator; Opus-only legs):** `ferazel-census` + `docs/ferazel/data-census.md`
  (1,108 items, 0 failures; **Phase 0 complete**) → **60/0**; R1 LOCKED seams (+ case `redrawEntireScrollGrid`), prefs,
  LevelTables, ports, strip-incremental `.RedrawScrollGrid` into port 0004 (follow the binary; blend cells 1,560) → **69/0**.
  **Ben 2026-10-07:** the duplicate-black tie-break (FG black → index 1 = light yellow under clut 202) is decided at the
  Phase 1 gate — build lowest and highest selectable (D26). HectorKit untouched (main 4ca2e18 after Cythera K1).
  **R2 + R3 DONE (2026-10-09, Opus orchestrator; Opus-only legs):** darkness on tiles inside `.RedrawScrollGrid`
  (`LightAny*Tile`, Effects ≠ 3), light faces, `.DrawLightsOntoTiles` → **74/0**; parallax as written
  (`.DoubleBlitPPCParallaxOneLayer`, ring split, row state machine) + `PxSprites` (N + 1 copies, follow the binary) →
  **81/0**; Fire (52/55) and ripple (11/18) levels refused by name (D26 as-built R2 + R3).
  **R4 DONE (2026-10-09, Opus orchestrator; two Opus legs + re-review):** placed sprites in their Setup faces (42
  level-1 types), active list, idle activation (13 at the start window), `.WrapDrawSprites` + `.WrapEraseSprites` +
  sprite light pass → **88/0**; level-1 Setups add 68 lights (exposed, not wired; R2's premise wrong); mode 0xb refused,
  table 0148 still unbuilt (D26 as-built R4). **R5 DONE (2026-10-10, Opus orchestrator; one Opus leg + fix round):** `FerazelSession.step` in `.GameLoop` /
  `.PaintFrameWrap` order, `Camera` = `.FindUpperLeftCorner`, Phase-1 pose + focus stubs, `DrawOp.wrapEraseSprites`.
  Following the binary: level 1 opens at scroll **(0, 0)** and pans in (not the plan's (0, 10)), and a skipped
  reduced-frame-rate iteration drops only the screen copy (D26 as-built R5). **94/0**. **R6 DONE (2026-10-10):**
  status bar (magic bar at x 419 per the binary, not 214), Game Screen frame, FrameRenderer (68 Setup lights wired),
  CLUT → RGBA, level-1 goldens (D26 as-built R6). **100/0, Phase 1 core complete.** **A1 DONE (2026-10-10, two Opus
  legs + fix round):** `Ferazel's Wand` app on HectorShell (whole-number window scale, 240 Hz timer / 2-tick step clock
  per `.GameLoop`, arrows + keypad, looped music via `.SetAIFFMusic` rules, CoreText status text, icon from `icl8` 128),
  project.yml target via the `Ferazel/FerazelCore` symlink; duplicate-black tie-break built (hidden `ColorTieBreak`
  default, Ben's ruling) (D26 as-built A1). **102/0**; all four app schemes build. Ben saw level 1 and heard the music.
  Let's Play = https://www.youtube.com/watch?v=ESuyxMUEzDw (design §2, Ben 2026-10-10). At 02:12 its level-1 FG rock edges
  show no yellow specks, so **Ben ruled the app tie-break default `highest`** (`ColorTieBreak lowest` selects the other).
  **A2 DONE (2026-10-10, one Opus leg MERGEABLE + two fix rounds):** `tools/stage-ferazel.sh` (Release, data into
  `Contents/Resources/Ferazel/`, ad-hoc sign, build stamp in the staged notes, Icon Composer previews) and
  `Ferazel/WHAT-TO-EXPECT.md` with the corrected 16-line gate card (D26 as-built A2). Staged `out/Ferazel/` + `~/Desktop/Ferazel's Wand.app`.
  **Ben's Phase 1 gate PASSED 2026-10-10 ("it looks good", D32).** Icon: Default render kept. Open: hidden gamma toggle, light-24 table
  over-light [MED], music fade-in [LOW]. **Phase 2 "Ferazel moves" PLANNED (2026-10-10, Opus planner, two Opus review legs, fixes applied; D33):** `docs/plans/2026-10-10-ferazel-phase2.md` — 22 tasks (F1–F3 foundations, S2 Sound Tool mixer, E2 draw modes, P1a–P5 player + camera, W1–W4 platforms/radial/cannons/passages/boxes/ropes/level 2, E1a–E1b particles + water effects, S1 cues, GD goldens, A3 app, A4 stage), 13 ⚑ MAJOR, ladder 102 → **238**, HectorKit untouched. Ben ruled: exit loads level 2 + hidden `FerazelLevel` switch; death → wipe → restart level. **Ben approved the plan 2026-10-10.**
  **Wave 2.0 DONE (2026-10-10, Opus orchestrator; all-Opus legs; D33 as built):** F1 `FastRand` + the 256 level-1 Setup draws
  (item twinkle phase now drawn → three pan goldens re-measured), F2 `SpriteWorld` physics world (rider/carry, layer guard,
  O(1) list), F3 `TileSolver` → `Ferazel/Core` **140/0** (base was 104, not 102); census 1,108/0; Ferazel app builds;
  HectorKit untouched. Nothing visible changes in the app yet. Next: **[S2 E2]** (Sound Tool mixer; draw additions + the
  carried level-start RNG draws: tint 0xa 510 + diffuse), ladder S2 → 145, E2 → 153.
  **Wave 2.1 DONE (2026-10-11, Opus orchestrator; all-Opus legs; D33 as built wave 2.1):** S2 Sound Tool mixer
  (8 audible of 16, ±127 clip, 22,050 Hz; every sound loses its first sample, as the original), E2 draw modes
  (hurt flash, water split/ripple, scale, rotation), death wipe, screen gamma; tint table 0xa now drawn from the
  session stream (level start = 766 draws on L1; the diffuse passes draw 0) → `Ferazel/Core` **154/0**, census
  1,108/0, Ferazel builds, no golden moved. Nothing visible changes in the app yet. Next: **[P1a P1b P2]** (P1a → 160).
  **Wave 2.2 first half DONE (2026-10-13, Opus orchestrator; all-Opus legs; D33 as built wave 2.2): P1a P1b P2 P3** —
  the real player: jump/gravity, walk/run/turn/air, landing + ceiling effects, cling, pull-up, crumbling tiles
  (`DrawOp.setTile`), dust, states/faces, breathing, footsteps; `PlayerPose` gone → `Ferazel/Core` **185/0**, census
  1,108/0, Ferazel builds. **Wave 2.2 DONE (2026-10-13, loop run 2): P4 P5** — liquids/acid/healing/drowning,
  damaging surfaces, below-map death, the death trigger, underwater light; `.PlayerScroll` replaces the focus driver
  (the camera follows Ferazel; arrow-key pan gone) → `Ferazel/Core` **203/0**. **Wave 2.3 W1 W2a DONE (2026-10-13,
  loop run 3; D33 as built wave 2.3 first part):** platforms in every mode (shuttles, rafts, rotors, pendulums, wheels +
  siblings, chain spokes), spiked pendulums 1480–1489 + mace chains, `.HurtPlayer` → `Ferazel/Core` **215/0**, census
  1,108/0, Ferazel builds, no golden moved. Mode-0xb finding (W1 precondition): not reachable through the L2 raft light
  path (rafts → mode 0xc). No sound until A3. Next: **[W2b W3 (+W4)]** (→ 220, 228, 234).
  **Colour MEASURED against the Let's Play (2026-10-10, Opus leg; `docs/ferazel/colour-measurement-2026-10-10.md`):** 7 level-1
  frames, 48 combos each. Tie-break `highest`, error-diffusion dither and Effects 1 match. `.exactNearest` beats `.ruled` in 7/7 frames, so **Ben
  ruled the app default model `.exactNearest`** (applied; G2 102/0, Ferazel builds). The video is about γ 0.76 brighter (classic Mac display gamma):
  hidden toggle `MacGamma` BUILT (off by default, γ 1.8/2.2 on the palette, app shell only; D26).
  **Light-24 table glow CLOSED (2026-10-10, Opus seat + one Opus review leg; D26 "As built (light-24 table glow)"):** the sprite light pass
  was right. `.HandleBonusSprite` twinkles an item's light through faces 0x32a–0x32d, and the replica held the brightest. Built as
  `BonusHandle` + seam case `DrawOp.changeLightFace`. The table's ΔE at 02:12 went from 21.6 to 6.9 on the matching phase, and the other
  six LP frames are unchanged. Pan goldens re-measured (frame 1 unchanged); `Ferazel/Core` **104/0**. Carried: torch flicker, sphere cycles.

#### Open, ordered
- **Cythera RE wave 1 DONE (2026-10-04):** eight rules banks Fable-reviewed ACCEPT_WITH_FIXES (1 Critical/2 Major/6 Minor, all fixed) and merged; binary decompiled to 100 % of traceback-named functions (1,994 across three git-ignored dumps, `tools/missing-addrs.txt`); open: `docs/cythera/INDEX.md` NOT RESOLVED 5/6/10/16/21–25 — handoff `docs/handoff-2026-10-04-cythera-re.md`.
- **Cythera RE wave 2 DONE (2026-10-06, Opus 5.5 seat):** all 840 newly decompiled bodies read or identified into `docs/cythera/` (census + six new banks: ui-play, dialogue-ui, scripted-windows, app-shell, ui-toolkit, open-items-2026-10-06; appends to ten banks; the 95 builtins now carry their real names). Review ACCEPT_WITH_FIXES (0 Critical/3 Major/13 Minor, 82/84 claims pass; ran on Opus 5.5, so a Fable revision pass is owed), all fixed. NOT RESOLVED 5/6/10/14/19/21–25 closed (22: wave 1 had the ending branch inverted — crystal quality 1 = saved ending); still open: `Render__7TViewer` layer order (16) and small carried sub-points — handoff `docs/handoff-2026-10-06-cythera-re.md`.
- **Cythera RE wave 3 DONE (2026-10-06, Opus 5.5 seat, Fable reviewer):** `docs/cythera/render.md` closes NOT RESOLVED 16 (draw order ground → passes 0/1/3 by tile flag → creatures → missiles → pass 5 → backdrops → roofs → filter/lighting; pass 2 never draws); open-items recipes banked as six tools. **Fable revision review** over wave 2 + 3: ACCEPT_WITH_FIXES (0 Critical/1 Major/11 Minor; 113/116 claims pass; every wave-2 closure and both wave-1 overturns hold), all 12 fixed. Still open (small): THood order within a pass, QTMA music events, over-encumbrance, 0x03/0x05 words, 0x0210 — handoff `docs/handoff-2026-10-06-cythera-re-wave3.md`.
- **Cythera — DESIGNED AND PLANNED (2026-10-06, Opus 5.5 orchestrator; DECISIONS D28):** whole game Mac + Windows;
  first gate = walking Catamarca; screen like the original (backdrop + floating game windows, 1 px = 1 pt); saves in the
  original format; cheats + Documentation viewer IN; music via Apple's GM synth (recorded for Windows). Design
  `docs/plans/2026-10-06-cythera-design.md` (APPROVED); Phase 0 plan `docs/plans/2026-10-06-cythera-phase0.md` (Fable
  planner, 14 tasks K1/C0–C12, ladder Cythera/Core → 84 tests, HK floor 313 → 319, census `failures 0`). **Nothing
  built.** Next: Phase 0 (chip issued).
  **Phase 0 tranche 1 DONE (2026-10-07, Opus 5.5 orchestrator, all-Opus implementers + reviewers): K1 + C0 + C1 + C2.**
  K1 on HectorKit main **4ca2e18** (HK D14; `decodePixels` takes 0x0099/0x009B regions as `maskRegion` + 16-bit DirectBits;
  direct modes {0, 36, 64} as stored — plan's "mode 64" was wrong; floor **322**, plan said 319 from a stale 313 base).
  Classics: `Resources/Cythera/` 20 files (D28 as-built), `Cythera/Core` CytheraData/CytheraResources + SegmentFile/
  Cipher/Overlay, suite **14/0/0** (ladder on track). Handoff `docs/handoff-2026-10-07-cythera-phase0-t1.md`.
  **Tranche 2 DONE (2026-10-07, same model policy): C3 LZ + C4 World records + C5 CytheraRender pixels** → suite
  **44/0/0** (ladder exact); HectorKit untouched (4ca2e18, floor 322). C4 STOPPED once (Invariant 10): plan had map
  0x8002 chunk 0 and the 0xF001 tail wrong — seat re-measured and ruled (D28 as-built tranche 2; plan "Tranche 2
  corrections"). Next: C8 ⚑ → C9 ⚑ (script decoder + parity), then wave C (C6, C7 ⚑, C10) — chip. Handoff
  `docs/handoff-2026-10-07-cythera-phase0-t2.md`.
  **RE-PLANNED (2026-11-05, Fable seat, replan.md; DECISIONS D45):** spec `docs/superpowers/specs/2026-11-05-cythera-remainder-design.md`,
  plan `docs/superpowers/plans/2026-11-05-cythera-remainder.md` (wave 1 = Phase 0b bite-sized: C8 → C9 · C6 ∥ C7 ∥ C10 ·
  C13 → C11 → C12, ladder 44 → 91; wave 2 = R1 Phase 1 research; Phases 1–8 as cards), audit
  `docs/superpowers/audits/2026-11-05-cythera-phase0-audit.md` (15 rulings, 0 redo). Seat's runs: Core **44/0/0** on
  HectorKit **ef2c341** (new pin, floor 370; the gate needs `HECTORKIT_DATA_AKI11` overridden — stale default path).
  Ben accepted all five questions (re-base, baked glyph sheets, three Opus sessions, "the player walks", gate split
  1a/1b). Nothing built. **Next: wave 1 session A (C8 → C9) — chip in `docs/handoff-2026-11-05-cythera-plan.md`; waits for Ben's go.**

1. **Aki Phase 2 — DONE, Ben's gate PASSED 2026-10-04 (DECISIONS D9): "the game works fine"; pairs fade.** P2.1–P2.12
   as before (AkiCore 107 tests). Q24 fix 6603e55: `runFade` waits one full tick (1/60 s) after each of its two presents
   per frame (plan Q24 ⚑; ~22/60 s fade). Gates from main (seat-run): M1 **107 / 0**, M2 BUILD SUCCEEDED (0 our
   warnings), M3 floor **167**. Staged build on **~/Desktop/Aki.app** (+ WHAT-TO-EXPECT.md) — Ben plays that copy; never
   delete prefs domain `com.ambrosiaclassics.aki`. Handoff `docs/handoff-2026-10-04-aki-q24-gate.md`.
   **Aki on iPad + Remaster mode — both on main 2026-10-06** (Ben: iPad first, then Remaster). iPad (plan
   `docs/plans/2026-10-04-aki-ipad.md`, rulings D7; AkiPad target, Aki/App split shared/Mac/iOS) merged 5e6755d; no formal
   iPad gate is recorded in DECISIONS — Ben has been playing it on his iPad mini. **Remaster (D11, gate PASSED D17)** merged
   on top. Toggle: Aki ▸ Remastered Art (⌘G, works in fullscreen) + Preferences checkbox; Mac + iPad. Art: regenerate
   `Resources/Aki/hd-4x/` per worktree with `python3 tools/upscale-aki-art.py` (~2.5 min cold, Upscayl; then `--check`;
   207 MB, git-ignored) — without it Remastered Art shows disabled. Gates from main (seat-run): AkiCore **123/0/0**; Aki,
   AkiPad (sim), BubbleTroubleX BUILD SUCCEEDED, 0 our warnings; HectorKit floor **252**. Staged copies (~/Desktop/Aki.app,
   Ben's mini) are the 2026-10-06 Remaster builds.
   **Aki 1.0 RELEASED 2026-10-06 (D23)** — public GitHub release `aki-1.0` (tag on b5dd97a, HectorKit 0467025):
   https://github.com/andiyar/Ambrosia-Classics/releases/tag/aki-1.0 — `Aki-1.0.dmg` 242 MB, sha256 `bd12e9d4…a6b5`,
   Developer ID + notarized + stapled (app and DMG), universal, Remaster art in, no Osaka-Mono, About "1.2.0 (1.0)", new
   macOS 26+ icon (`Aki/App/Mac/AppIcon.icon`, green felt). Next releases: `tools/package-aki-release.sh --version X.Y
   --sign "Developer ID Application: Benjamin Thomas (5W72UJL332)" --notarize oniarm64-notarize` (bump `CFBundleVersion`
   in `Aki/App/Mac/Info.plist` first; the script asserts it). Ben verified the notarized DMG 2026-10-06: sound, music, ⌘G all work. Untested: Intel, macOS 15/26. **Next: Aki Phase 3** (editor, `.aki`).
2. **Bubble Trouble X — Ben's play gate (sound is in):** Ben 2026-10-06 played 3 levels: sound + music right, Q1/Q3/Q4/Q5/Q8/Q12/Q16/Q18 + text all yes (D14 addendum); NR-10 waived ("who cares about demos?"). Still open: his longer playtest; Q2 cheat memories, Q9/Q13/Q15 if he notices anything. Carried minors: core `musicPlaying` flag vs channel status (D14.5); deactivation during a carried-over pause; an event during the very first wipe acts one frame early; app activate/deactivate during dialogs (docs/bubble-trouble/review-carries-2026-10-04.md).
3. RE chains: Deimos CLOSED; Ferazel wave 2 CLOSED (build planning session running 2026-10-06); Cythera waves 2–3 DONE 2026-10-06 (Fable revision pass + Render layer order landed), only small sub-points remain. Deimos Phase 0 on branch `deimos-phase0` (HectorKit v0.3.0 format layer landed; DeimosCore census in progress, unmerged).
4. **Windows port** (Ben 2026-10-06) — BTX staged for his brother (above); await his report.
5. Phase 3 Aki, then Bubble Trouble X shell on HectorShell (design §6). EV's adoption of HectorKit: separate task.

#### Carried (not blockers)

- Design doc §4 says 70 QuickTime / 12 raw PICTs; the data says 71 / 11 (PICT 135 is 32-bit cmpCount 4 — a
  real alpha plane). Fix the design doc when it is next edited.
- HectorKit carries EV-engine arithmetic in `SndSound` (`loadSoundsTicks`, `playbackDurationFrames`) by the
  "rename prefixes only" rule; trim only with a ruling. Only data-gated tests cover `snd` format 1.
- `quickTimeBands` returns a tuple, not a struct (API polish for v0.2). No dimension cap on codec images.
- Ambrosia's 1996 installer format unreversed. HD-art packs late polish. Licence at the very end (EV D65).
- **Aki, for Ben's HectorKit session:** (a) `ShellSoundBank.start` on a track at its end replays from 0; QuickTime left
  `IsMovieDone` true for `_LoopMusic` — Phase-2 effect only (theme alternation window); (b) quitting from fullscreen:
  `exitFullscreen()` re-shows the windowed window, so `windowDidBecomeMain` → `unpause` fires at quit — the original's
  deferred step never ran; HectorShell needs an exit that only orders out (P1.12 review Minor 1); (c)
  `ShellFullscreenWindow.canBecomeMain` true where the original allowed key only (no visible effect yet).
- **Aki carried from Phase 1 reviews (not blockers):** Release Notes — Ben wants the replica's own notes at the very
  end (with the licence); ASWAboutBox/ASWTextViewer-faithful windows after P3 (Q10); the Carbon dialog centres on the
  MAIN display, not the game window's display (as the Carbon code did — Q6, multi-display);  one `fullscreen` accessor (ivar vs `shell.isFullscreen`); the Osaka-Mono guard's Menlo branch is only provable offline on this Mac
  (the font is now installed system-wide); bundling Apple's font is for Ben's machine only (licence).
- **Ferazel RE wave 2 (2026-10-04, CLOSED 2026-10-06, Fable orchestrator, cap waived by Ben):** Ben's "decompiled to 100 %" wave — ten Opus reader lanes wrote 11 new `docs/ferazel/` files (lighting-tables, draw-effects, particles, rendering-omnipx-titles, conversations-mcnv, bosses-3, enemies-ground-2, spells-detail-2, platforms-ropes-radial-2, enemy-shots-and-damage-2, pickups-boxes-2) + 17 in-place edits; eight Fable review legs A–H (`REVIEW-2026-10-04-wave2.md`; leg C 2 Critical: water-tint loops `ble` so entry 0xff is written → black, mode 0xa is a vertical squash) + spot-review 2i (0 C / 0 I / 5 M, all landed); two fix rounds + INDEX/coverage synthesis (`FIXPASS-2026-10-04-wave2.md`; 110 review markers, 100 corrections markers; labels HIGH 1100 / MED 291 / LOW 41; coverage 141/1/12). INDEX NOT-RESOLVED 2–29: all closed, UNDETERMINABLE with evidence, or narrowed; **still genuinely open:** palette-index choice of Color Manager `Color2Index` (LOW on every "→ idx"), geysers NR 2–4, follower slot-reuse frequency and whether enemy drops give items 8/21, the nil level-handle outcome in ContinueGame, and intent-only questions (music 21/27, vestigial boss fields, 2940 p1 = 0, tile oddities). Merged to main `--no-ff`. Nothing needs Ben's play check. Worktree `ferazel-wave2` still locked by the Oct-4 session (pid 42564) — remove it and the branch when that session closes.
- **Ferazel RE deepening (2026-10-03, CLOSED 2026-10-04):** 11 Opus readers + 2 gap readers wrote 17 new `docs/ferazel/` files (~6,400 lines: enemies ×3, bosses ×2, enemy-shots-and-damage, pickups-boxes, triggers-background ×2, spells-detail, save-continue, platforms-ropes-radial, player-states ×2, geysers, held-item-melee, coverage, physics-sprites); three Fable review legs all ACCEPT_WITH_FIXES (1a 0/4/6, 1b 1 Critical/3/9, 1c 0/4/11; `REVIEW-2026-10-03-deepening.md`); fix passes 1a/1b landed; consolidated fix pass landed (`FIXPASS-2026-10-03-deepening.md`; labels HIGH 727 / MED 228 / LOW 27); merged to main at 5b15177. Fable spot-review 1d of the fix-pass diff (2026-10-04): ACCEPT_WITH_FIXES, 0 Critical / 0 Important / 6 Minor, 66/66 markers + 76 raw addresses confirmed; fixes + the held-item-melee carries (rows 3, 4, 6–8) landed at 02f29cc. Worktree and branch `recursing-rhodes-932ac0` removed. Still open in the bank: INDEX NOT-RESOLVED items 15–29 (`+0xb8` draw modes, tint/remap colours, NewParticle args, Xichra cannons, OmniPx/PxMid, Mcnv item 3, lighting item 10, Titles item 12). Nothing needs Ben's play check. Handoff `docs/handoff-2026-10-03-ferazel-re.md`.

## 2026-11-08 — Snapshot B: the Ferazel live-state block of `docs/NEXT.md` (written at run 45's close, 2026-11-07)

Until 2026-11-08 the Ferazel chip carried its own live state (runs 22–45: counts, carries, goldens, process notes and
lessons). It was dropped when the chip was rebuilt from nothing; its current values moved into `docs/STATE.md`'s
Ferazel bullet. Kept here verbatim.

#### STATE (live, 2026-11-07, written by the ATTENDED run 45 (Fable seat, D45.7 chain) at its close; head of `main` = run 45's docs-close commit on top of 3bdc5fa — read `git log -20 main`)
- **Current numbers (supersede every older count below):** Ferazel/Core **603 test cases = 601 passed + 2 skipped** (475
  rules + 128 render; the opt-in `FerazelRenderTests.VisitSweepTests.testVisitEveryObject` and
  `FerazelRenderTests.RandomPlayTests.testRandomPlay`); census 1,108/0 (run 44; not re-run — no decoder or data change);
  FerazelWinKit **81 = 79 passed + 2 opt-in skips** (`WinVisitSweepTests`, `WinRandomPlayTests`); **HectorKit main ef2c341,
  zero-skip 370 / 0 failed (D45.2)**; the Dillo and the geysers merged on top of Blobs, Crabs, Gremlins and Wraiths; wave 5.4
  is open (GF, DL, GY done; PI + PT close it in run 46: G3, GE core on levels 1–4, GWB by day); **no launch gate is owed**
  (neither DL nor GY moved a Windows reference; no built level places either).
- **Attended run 45 (2026-11-07, Fable seat, D45.7 chain — remainder plan wave 2, run 45):** **DL** (the Dillo —
  `World/Enemies/Dillo.swift`, 5 tests; one Opus leg MERGEABLE WITH FIXES, 67 mutants / 3 gaps → 2 pinned by the tests-only
  fix round 8431831; **seat ruling:** the unplaced types 1872–1879 (HP 0 / max 0, a divide by max HP in the idle decision when
  the timer starts at 0 or 1, raw 10086a48) are refused at Setup, ◇ — bank `enemies-ground.md` item 12) → **596** (8fd9fe8,
  merged + pushed mid-run); **GY ⚑** (geysers — `World/Movers/Geyser.swift`, 7 tests; the head 0x5a9 and segments 0x5a0,
  the eruption cycle, the spray, the head / segment hurt rows, §9 (b) NR 2–4 as settled; two Opus legs MERGEABLE WITH FIXES,
  305 mutants / 34 real gaps → all pinned by 4639d9a, re-review on a clean copy; **dump over bank:** the head sorts at layer
  **2** (not 11), only the **segments** hurt enemies (never the base), the collapse keeps the head's face — `geysers.md`
  "Run-45 corrections") → **603** (4639d9a). Neither ◈: no golden or BootFaces value moved. All merged `--ff-only` and
  pushed by the seat. **Process notes (run 45):** (32) two review legs must each use their own `mktemp` copy — leg 1 and
  leg 2 collided in a shared scratchpad folder (leg 1's reverts ran under leg 2's mutation harness; the re-review re-ran the
  table on a clean copy) — say "your own mktemp copy, not the scratchpad" in every leg brief; (33) a leg-2 mutation harness
  (`gen.py` + `results.tsv`) is worth handing to the fix-round implementer and the re-review leg by path — both re-ran it;
  (34) a minor task's single leg can carry a light mutation table (DL: 67 mutants) — ask for it in the brief.
- **Attended run 44 (2026-11-07, Fable seat, D45.7 chain — remainder plan wave 2 part 1):** **BL ⚑** (Blobs and Crabs —
  `World/Enemies/BlobCrab.swift`, 7 tests; the Multi Crystal's Blob exception; audit 4 — `killProc` has no Crawler / Roach /
  Bat / Blob arm — and audit 20's cites; two legs → tests-only fix round + one re-review row (the strike's y truncation pinned
  at angle 50: the binary's table stores sin 70° as exactly 0.94); **seat ruling: a moved pin** — `BootFacesTests` level 3
  f30 `0x07212368c70e3f4a` → `0x56a7ccb0dd544488`, f120 `0x521fd141e046a4d6` → `0xc43bacea46d2ff94`, the level-3 Blob
  rec 15 runs one Handle at start then idles, switch-off held twice; no golden moved) → **584**; **GF ⚑** (Gremlins and Wraiths —
  `World/Enemies/GremlinFloater.swift`, 7 tests; **path modes 10/11 admitted for the Gremlin**, `ProgrammedPath.makeRadial`'s
  first caller — audit ruling 3 closed; the unplaced Wraith variant 0x6fe–0x707 refused at Setup, ◇; two legs → fix round,
  30 of 33 gaps pinned, re-review MERGEABLE) → **591**. Both merged `--ff-only` and pushed by the seat (a515415, b6afbc6).
  **Process notes (run 44):** (28) a class turning on may move a `BootFacesTests` 120-frame pin even when no golden moves —
  the switch-off check decides, the test comment records old/new/cause; (29) a leg that stops "waiting on its own background
  work" needs one resume message — budget for it; (30) the seat's gate scripts (`seat-g2.sh`, `seat-gw.sh`, `seat-wave.sh`,
  archive copies with `HECTORKIT_PATH`) ran beside one implementer or two legs without memory trouble; (31) the implementer
  may find a plan item the dump contradicts (GF's grounded-rider halving) — it skips it, says why, and the re-review rules.
- **Attended run 43 (2026-11-07, Fable seat, D45 — the remainder plan `docs/superpowers/plans/2026-11-04-ferazel-remainder.md`
  is the authority from here; the Phase 5 plan keeps the task cards):** RC (HectorKit reconciled, run 42's Bat
  cherry-picked, D45 Ben's answers: Q11 + Q14 passed, Q16 defaults stand), **BAf** (the Bat's fix round — asserts only,
  `ProgrammedPath` moved to `World/Movers/ProgrammedPath.swift` with the mode-10/11 Handle body; **the 1xx path form zeroes
  the swing SPEED, not the radius** — the audit's ruling 3 corrected; re-review MERGEABLE 26/26 mutants killed; ◈ none
  moved) → **569**; **FR** (Frogs and Salamanders — `World/Enemies/FrogSalamander.swift`, 8 tests; two legs → fix round:
  **the Frog's launch aim reads playerX against cy − 0x28 as the binary does** (M l. 70358, raw 100824bc; bank §1.3
  corrected ⚑), 24 survivors pinned; ◈ none moved — the level-2 Frogs start idled) → **577**. Run 42's worktree and branch
  removed. **Ben's D45.7: sessions chain automatically** — this close starts the next ATTENDED session (same seat, fresh context); the loop stays stopped unless Ben says "start the loop" (CLAUDE.md "Workflow").
  **Process notes (run 43):** (24) a line-anchored audit (`DrawModeAuditTests` writer rows) moves with every comment an
  implementer adds — every class brief says "run `--filter DrawModeAuditTests` and re-anchor"; (25) when two legs contradict
  on a dump reading, the seat reads the M lines AND the raw (`Ferazel_pef.disasm.txt`: which TOC slot a pointer global comes
  from) and rules — both FR legs' disagreement and the audit's "radius" error were settled that way; (26) the seat's G2 is
  two commands from a `git archive` copy (`seat-g2.sh` pattern: core ~1 min, render ~12 min); (27) implementers still end
  turns "waiting on a background run" — one SendMessage resume finishes them; stop the agent once its report is in.
- **Loop run 41 built CR ⚑◈ + WK2 ⚑◈** (D44 "As built — run 41"; plan "As executed" under each task; merged a0b0401 +
  7c2b880 CR, 2627d80 + 891811e WK2): `World/Enemies/CrawlerRoach.swift` (both classes complete; the run-29 Roach carry
  closed) and `World/Enemies/AxGoblin.swift` + the 1750 / 1760 arms in `Walker.swift` (no `// later: WK2` left). **◈:**
  CR moved two level-1 goldens — swim `[67, 321]` / `c1dd428a3f146d77` → **`[67, 322]` / `3e99f74fa10e87e2`**; 600-frame
  `a8dda9cf3e448016` / 3114 / `28a48762cfff1b2b` / seed 1574122804 / 156 → **`0cce4b0446e2a48e` / 3160 /
  `1b06b8a4117cf9dc` / 1361095401 / 150** (Crawler records 39 and 9 wake; no Roach on any golden route; nothing on
  level 2); WK2 moved none. Windows references unchanged. Both tasks: two Opus legs MERGEABLE (leg 1) / WITH FIXES (leg
  2's mutation tables: CR ~21, WK2 22 real survivors — the implementers had claimed ≤ 9) → tests-only fix rounds,
  seat-read. Carried [LOW]: `EnemyCommon.killProc`'s Crawler / Roach arm is unreachable (no Kill proc stored by the
  dump's Setups); the ceiling Crawler keeps the stand-in face 0x6b0 from Setup (idled at spawn, never drawn before its
  Handle); the shot-kill light slot read before `.KillPlayerShot`'s cleanup in both CR Hits; the `+0x160` audit row
  excludes `AxGoblin.swift` by file; the Walker Hit's shot-kill light recolour may belong to the Walker's own light
  (CR implementer, low confidence, pre-existing).
- **Run 41 process notes:** the CR implementer ended its turn "holding for a monitor" with its work uncommitted — a
  SendMessage resume finished it in 9 min (resumes run in the background: the seat waited with a foreground `until`
  loop on `git rev-list --count`); the seat ran every non-launch gate through `/tmp`-style `git archive` copies
  (`seatgates.sh` pattern: HectorKit symlinked at `$T/HectorKit`, own `WIN_BUILD_ROOT`) beside one implementer —
  memory fine.
- **⚠ The Core suite now takes ~15 min (cold build ~25):** a foreground Bash call is capped at 10 min. The seat runs G2
  in a background Bash with a long timeout (or the `git archive` gate-script pattern below); **every brief must tell
  subagents to batch the suite by `--filter` (covering every class — check against `swift test list`) and never to end
  their turn while anything runs** — run 40's WK1 implementer ended its turn "waiting for the suite" and had to be resumed.
- **Loop run 40 built ES ⚑ + WK1 ⚑◈** (D44 "As built — run 40"; plan "As executed" under each task; merged 067d570 +
  8bc8cf7 ES, 0efe8e2 + b8d56c5 WK1): `World/Enemies/EnemyShot.swift` (every shot type, the step-7 shot rows,
  `.ShieldBlock`, the Wraith reflection, the crouch face, spouts fire on level 4, dart traps as read) and
  `World/Enemies/Walker.swift` (1700/1705 complete; 1750/1760 arms `// later: WK2`; corpse raft under the Platform
  Handle via `SpriteSlot.walkerCallbacks`; Walker sheets via `CachedFaces.handleSets` + `sheets(markedBy:)`). **◈:** one
  golden moved — Phase 2 L2 iteration-2 `df22325e851e782d` → **`b310ef334de49c00`**; no Walker wakes on the level-1
  golden routes (the plan's "every level-1/2 golden" was wrong); Windows references unchanged. Dump over plan: cannons
  never capture enemy shots; Wraith homing 19 frames; Warrior shot mirrors when vx > 0. Both tasks: two Opus legs
  MERGEABLE, then a mutation-table fix round inside existing tests (ES 33 survivors → 4 equivalents, WK1 42 → 4).
  Carried [LOW]: 0x46a ×3 records keyed as one PICT (latent until Phase 6); the egg's 0.9 / −0.15 constants unchecked
  against the data section; the Setup-face fallback width for 0x6a5/0x6a6 is the whole picture; the airborne face's
  `onSprite` term unpinned.
- **Loop run 39 built RB ⚑ + EC ⚑** (D44 "As built — run 39"; plan "As executed" under each task; merged f5fb48e +
  34290ad + fe7b20c RB, 8180742 + a2d1fa9 EC, on top of Ben's 8f7746f): the random-play bot (`tools/ferazel-random-play.sh
  core|windows|both`, opt-in `FERAZEL_BOT=1`; after the first level end → map → re-enter, later level ends start a fresh
  New Game — seat ruling; Ben's memory limits copied: 4 workers, 6 max, `-j 4`, 30 %-free wait) — wave 5.0 closed; enemy
  common (`World/Enemies/EnemyCommon.swift`, `Particles/Burn.swift`; all S2 handler cases as named no-ops; the counting
  window — the run-29 carry fixed, level-1 total 0xf unchanged; the Kill idiom; contact damage rows keyed on handler cases,
  dormant until each class task maps its `forClass` row; goblin voices; statue wrapper; hazards/liquids; Smite at the
  stored centre). **Both EC legs caught the implementer's Gremlin Kill backwards** (dump: returns when `+0xe9 ≠ 0`) and
  the burn's Kill on a held slot copy — fixed. **Visible:** the Ring of Smiting hits nothing on levels 1–4 until the class
  tasks map their handlers. Carried [LOW]: Dillo coin count asserted as a range; the bot saves once per 16 runs.
- **⚠ Ben's 8f7746f (2026-10-30 20:55):** his Mac panicked out of RAM when the visit sweep's 14 workers ran beside
  builds — never run two heavy suites/sweeps at once on this machine; the sweep and the bot now cap at 4 workers.
- **Loop run 38 built wave 5.0 part 2** (D44 "As built — run 38"; merged e65087c DK, c49bbd4 + e573236 UT, 991f924 +
  fe2d9d9 + 78f9231 DA): a dynamic-lit sprite at full darkness reads the ambient table that follows the light table (F max
  110 over the built levels; ≥ 0x6f000 still refused); the underwater tint (row 41, existing `.fadeToColor` ops; no golden
  moved — no golden route is fully submerged and the goldens ignore gamma ops); `DrawModeAuditTests` (99 renderer throws
  in 47 rows, each with a code-checked reason; no refusal reachable in levels 1–4; ~120 s of the suite). **The seat's
  Proof B caught the audit crashing the whole Windows test process: `String.contains(String)` on Windows is Foundation's
  and traps under Wine** — fixed in plain Swift; rule: Proof-B tests avoid Foundation string search/trim too. Q15 item 7
  ruled into DA (D44 seat ruling, ladder unchanged). Carried [LOW]: `try!` at `PlayerStates.swift:291`; gap ledger l. 38
  and its l. 170 count still name the tint unbuilt; orb argument checks Shots/ only.
- **Loop run 37 built wave 5.0 part 1** (D44 "As built — run 37"; merged 09cccce…3bf6882 PB, 7be824a SP, 0b02d31 RV):
  Proof B accepts the opt-in skips and clears the opt-in switches; the three Windows smoke reference frames are pinned
  in-process (`WinReferenceFramesTests`, through the exe's own shared `WinGame.runFrames`); two Wine gaps in Ben's
  2026-10-29 tests fixed (a `@MainActor` test class crashes Windows XCTest's listing; `FileManager.enumerator` /
  `NSRegularExpression` find nothing under Wine); the sparkle's random walk uses the renderer's own scroll (the drift the
  plan named was not actually happening — now it cannot); the empty item box draws what the original reads; computed face
  ids checked; hot rects/emitters pinned across the boot faces.
- **⚠ Ladder +1 vs the plan's table:** Ben's attended commit 3cf72df (world-map status bar in clut 700, 2026-10-30 12:28)
  added one Core test mid-run. Every later Core total = the plan's + 1: **DK 511, UT 514, DA 516, RB 518, EC 526, ES 537,
  WK1 546, CR 554, WK2 560 (both reached, run 41), BA 569, FR 577, BL 584, GF 591, DL 596, GY 603, PI 607, OX 612, LV5 618, A5 618**; Proof B at
  the phase end 615/0/3/0 of 618. WinKit unchanged (80, RB → 81). Ben may land more — re-derive at reconcile (G2).
- **Ben's Q15 item 7:** carried by run 38 (D44 seat ruling): comment verified + independent map pins in DA; the
  map-text clut-700 colours and the Let's-Play comparison idea stay with Ben (Q15), no task.
- **Loop run 36 planned Phase 5 "Enemies"** (D44): 22 tasks + phase end A5, 13 ⚑, ten runs; levels 1–5 (level 5 up to
  the Warrior's arena, Warrior a stand-in until Phase 6); no HectorKit change. Commits 8b4e63a, 1dfffd0, 1911e48.
- **Older state (runs ≤ 35), kept for reference:**
- **Ben's attended sessions 2026-10-27 → 10-30 (not loop runs; 19 commits 0bb92b9…6a70bce on main):** Windows test builds
  1–4 published for Andrew (`releases/ferazel-windows-test-*` in the main checkout); the teleporter sparkle (draw mode 5)
  was refused → both shells quit (a draw refusal = game quit) — fixed 0fd056e (+ mode 0xa); teleport/passage re-seat
  78e81c3; light PICT 806 shrink (level 2) + rope faces (level 3) 48a0620; every boot face loaded as `.InitSprites`
  (`Core/Sprites/BootFaces.swift`) b535527; Continue refuses an unbuilt-level save e9fa8b0; the port gap ledger
  (`docs/ferazel/port-gap-ledger.md` + `docs/ferazel/gap-ledger/`, scripts `tools/ferazel/gap-*`); the visit-every-object
  sweep `tools/ferazel-visit-sweep.sh` (core + windows, ~12 min, 3,360 visits × 2, 0 failures at 6a70bce). Follow-ups → Q15.
- **Phases 2 and 3 PASSED WITH NOTES by Ben (2026-10-25, D39).** Q9 (keep the speed), Q5 + Q7 (D40), Q10 (D41), Q12 (D42) answered.
- **Phase 4 "Spells + items" CLOSED on the machine side** (loop run 30; D38 "As built — Phase 4 end"): ladder 349 → **490**.
  Staged build **4bca4bd** at `~/Desktop/Ferazel's Wand.app` + `~/Desktop/Ferazel's Wand — WHAT-TO-EXPECT.md`. **Ben's gate: Q11.**
- **Phase W "Windows twin" CLOSED on the machine side (loop run 35, D43 "As built — WF6 + Phase W END").** Both builds staged on
  the Desktop: `~/Desktop/Ferazel's Wand.app` (+ `Ferazel's Wand — WHAT-TO-EXPECT.md`, icon previews; Mac stage of 589a900's
  code = runs 32–34's app + mute switch) and `~/Desktop/Ferazel's Wand (Windows).zip` + unzipped folder (stamp 589a900, HK
  35a85ba; zip ≈ 92 MB, 60 files + MANIFEST, 19 DLLs). Launch gates by day, muted (11:5x–13:1x): G9M clean (quit answers
  "User cancelled" by design), Proof B **489/0/1/0** (4 min 48 s), GW6 `main menu` / `new game` / `level 1 text: identical`
  (C = step 959, 3,833 wakes, `0xfbb2dd7a1d289726`, full brightness — the Fable leg found step 881 nearly black). New scripts:
  `tools/windows/stage-ferazel-win.sh` (refuses uncommitted content, fixed folders `$WIN_CROSS/{work,build}/stage-ferazel`),
  `tools/windows/smoke-ferazel-win.sh` (no argument = GW6; refuses a zip not stamped with HEAD — re-stage after every commit).
  **Ben's and Andrew's Windows gate: Q14.**
- **Phase W history** (loop run 31; `docs/plans/2026-10-26-ferazel-windows.md`, D43): WF0, WF1 ⚑, WF2,
  WF3 ⚑, WF5, WF4a, WF4b ⚑, WF6 phase end. Ladder: Ferazel/Core stays **490**; the new `Ferazel/Windows` package's
  macOS-hosted tests (GW2) 0 → 17 (WF1) → 27 → 46 → 54 → 65 → **77**; Proof B (GWB, CrossOver, muted, by day) **489/0/1/0** (WF0b skip rule).
  Execution: run 32 = WF0 + WF1 (**done**), 33 = WF2 + WF3 (**done**), 34 = WF5 + WF4a + WF4b ⚑ + WF0b (**done**), 35 = **WF6 phase end**, then the Phase 5 plan.
  Reviews done: two Opus legs + FABLE-GRADE leg, both rounds applied (plan commits f00efc4, 5bfc50a, f5b0bf7).
- **Run 32 built WF0 + WF1** (merged; WF0 4b5937e, WF1 59047f4): Core + tests cross-build for Windows (GW1 0 / 2, ~20 s);
  `tools/windows/proof-b-ferazel.sh` written + guard-checked; `Ferazel/Shared/{FerazelDriver,FerazelAudio}.swift` (the Mac's
  neutral shell half, a move — Mac behaviour unchanged), symlinked into `Ferazel/Windows/Sources/FerazelWinKit/`; the Mac mute
  switch `-FerazelMute YES` / `FERAZEL_MUTE=1` (no `ShellMixer`, no beeps); the driver's `headless:` init option (Ruling
  20's frames mode) always installs `FerazelSilentMixer` and never calls the mixer factory, muted or not. GW2 **17/0**
  (~85 s). Pinned with `StubGlyphRasterizer`: boot → main menu 360 ticks FNV `0xae2b1ee08c089b2a`; New Game (N held) →
  level 1 first frame 107 ticks FNV `0xc99ce8e85b4bd8f7` — **WF2 re-measures both with real (baked) glyphs** and those
  become WF3's reference. UserDefaults' argument domain (measured): "2abc" → **0**, "y"/"t" → false, only yes/true (any
  case) or exact "1" true, **a value starting with "-" is a new key** (`-FerazelLevel -1` leaves it unset) — WF3's
  `WinArgs` must copy that. `FerazelDriver` and `FerazelSettings` are `internal` — WF3's executable (another module)
  needs a public surface (wrap it, BTX-style, or open it). The `ShellMixer: FerazelMixer` adapter is in
  `FerazelController.swift`.
- **Run 33 built WF2 + WF3** (merged; WF2 7a05d1d + b992809, WF3 35d291b + 244138e + 680a383; notes in the plan's "As executed" and D43): five baked faces in `Ferazel/Windows/Resources/Fonts/<font>-<size>-<face>.fzfont` (Times 12 bold, Geneva 9, Geneva 8 bold, Times 18, **and the dialog face font 0 face 1 12 pt, already baked for WF4a**), equal byte for byte to `CoreTextRasterizer` (now `Ferazel/Shared`, Mac-only, public); **ligatures longer than two characters are not modelled — WF4a must test its dialog strings as a closed set against CoreText** ("12:30" in the dialog font would miss). Reference frames (headless, muted, WF1's seed, N held): main menu 360 ticks `0xae2b1ee08c089b2a` (no text), level 1 first frame +107 `0xc99ce8e85b4bd8f7` (no text), **first presented text frame +414 `0x908483fb603623e8`**. `FerazelWin` executable + FerazelWinKit `WinGame` (public wrapper of the internal driver), `WinInput`, `WinShortcuts`, `WinFiles`, `WinArgs`, `WinStartup`, `WinKeyScript`, `WinAudioDriver`, and the protocols **`WinDialogs` / `WinFilePanels` with stub answers — WF4a/WF4b/WF5 replace the stubs**; `Ferazel/Shared/FerazelMenuRules.swift`. Fonts at run time: `--fonts DIR` else `<data>/Fonts`. Launch line prints SDL's real drivers → headless `video=dummy audio=none`. `--frames` runs use prefs/saves only from `--prefs`/`--saves`. The `.exe` is console subsystem (3) — WF6's stage makes it GUI. FerazelWinKit suite ~9 min.
- **Run 34 built WF5 + WF4a + WF4b ⚑ + WF0b** (merged; WF5 a11e39b + 034a283, WF4a a21dc30 + 38239c0, WF4b 689c551 + f8b36d0 + b62f1a8,
  WF0b dc52e5e + 1d75574; notes in the plan's "As executed" and D43): the native Open / Save dialogs (comdlg32, compiled + linked,
  **never run** — WF6's GW6 boots only to the menu, so the gate card must ask Ben/Andrew to try a save); DLOG 202/200, Options
  6900 and Credits 600 drawn in-window (dialog face = the Mac's pick exactly — ◇W13 not kept). Seat rulings ("follow the
  binary"): **Esc does nothing on DLOG 202**; the Options filter is the original's (Esc / Ctrl+. → Cancel, Return / Enter → OK
  at once; captured on Controls); Credits read the live button; Alt+Return cannot be bound (◇ note). **Launch gates done by
  day (first time):** GW4R exit 0, `video=dummy audio=none`, main menu FNV `0xae2b1ee08c089b2a` identical (twice);
  **Proof B = `489 passed / 0 failed / 1 skipped / 0 crashed (of 490)`, ~4 min 40 s** — Wine lacks
  `ADVAPI32.SaferiIsExecutableFileType` (Foundation's attributesOfItem / isExecutableFile / Process.run): file sizes via
  FileHandle on Windows, pure-Swift search in CensusTests on Windows, **skip rule: `CensusTests.testExitCodes` skips under
  Wine only** (the script accepts only that named skip; a leg's view: `CreateProcessW` directly would remove the skip — a
  later option). New stand-in notes for WF6's card: the Open dialog may open in Windows' last-used folder; dialog text
  below 14 pt is cut to two levels (the Mac's dialog windows smooth it, ◇W10); the popup menu is a drawn classic stand-in;
  right-click outside a dialog does not beep. Mac carries [LOW]: the Mac key field's 4 px click outset (the binary uses
  the exact rect); the original's null-event pause while a button is held (Windows models it, the Mac app does not).
- **Handed to Phase 5 by seat ruling (run 30):** the underwater screen tint (`.TintScreen`, row 41 M 46450–46474; stubs
  `Player.swift` ~360, `PlayerLiquids.swift` ~139) → a **named task** in the Phase 5 plan; the Magical Shield crouch face
  (`PlayerStates.swift` ~555) → Phase 5 with `.ShieldBlock`. The Phase 5 plan is written lockstep (D41, plan Ruling 16).
- `Ferazel/Core` suite: **490 passed, 0 failed/skipped** (run 33 seat at the merge head). Census `Totals: items 1,108 decoded,
  failures 0` (stdout byte-identical to before WF0). Ferazel, Aki, AkiPad, BubbleTroubleX, Deimos BUILD SUCCEEDED (run 32 —
  project.yml gained `Ferazel/Shared`; AkiPad in a worktree needs `AKI_DATA_12=$REPO/Resources/Aki/1.2.0.app/Contents/Resources`
  and `-destination 'generic/platform=iOS Simulator'`). GW1 0 / 2. **GW2 77/0** (run 34, seat). **GW3 0 / 1. GW4 Build complete!** GW4R identical. **GWB 489/0/1/0.** G-MUTE 1 / 1. G7/G7W/GW-symlinks empty. G5 BUILD SUCCEEDED (run 34).
  HectorKit `~/Developer/HectorKit` main **35a85ba**, clean, floor **361** — Phase W changes no HectorKit (Ruling 17).
- Worktrees: `inspiring-cannon-e97ccd` (deimos-phase2) and `~/Developer/gamepad-wt/Ambrosia-Classics` (branch
  `gamepad`, merged) are Ben's — never touch. Earlier runs' worktrees are the looper's to remove.
- **Goldens (current, after run 41 — run 40's WK1 moved L2 `df22325e851e782d` → `b310ef334de49c00`; run 41's CR moved swim and 600-frame, below):** Phase 1 `9db8f32f7e3d88b4` / `b80b0efd384ffdb9` / pan 30 `b1f4efcf3c34735f` / pan 60
  `80d88efdc8fac27c` / chain `aaab15c0710cbcf7`; Phase 2 L2 `565e867a02736c18` / `b310ef334de49c00` (was `df22325e851e782d` before WK1), jump `deb577ecdeb64c58`,
  swim `3e99f74fa10e87e2` (particles [67,322]; was `c1dd428a3f146d77` / [67,321] before CR), 600-frame `0cce4b0446e2a48e` / cues `1b06b8a4117cf9dc` (cue words 3160, seed
  1361095401, particles 150; was `a8dda9cf3e448016` / `28a48762cfff1b2b` / 3114 / 1574122804 / 156 before CR); Phase 3 FE0 `ed142fed9e3bdce7`, map first frame `38563faaa2276f05`, map RNG `0x7b052a62`, sign
  frame `c8e41941c1e4d6da`. A ◈ task may move a golden only for its class turning on, with the switch-off check; any other moved Core value is Invariant 10 — STOP, reconcile, record.
- **Run 31 notes:** Ben amended Q12 twice while the planner worked (first "never launch", then "muted only", then the night
  rule) — the plan follows the final form; a reviewer measured the BTX game cross-build at ~10 s and GW1 at ~19–24 s; brew
  SDL3 is 3.4.18, the Windows pin 3.4.16 (the Mac SDL dev build uses brew's).
- **Run 30 notes:** the G9 quit Apple event answers "User cancelled (-128)" by design (D40: the flow queues the quit and
  the main menu's pass quits; the process is gone 3 s later) — not a failure; the Windows toolchain is already on this
  machine (`~/Developer/Toolchains/windows-cross/` with Swift 6.4.0, SDL3 3.4.16, winsysroot; `/Applications/CrossOver.app`)
  — no install is needed to plan, and building only needs what is there.
- **Run 29 carries:** the enemy stubs set counted-in-totals (`+0x1b5`) unconditionally where the dump gates it on
  `_DAT_1009fe8c` (matters once Phase 5 spawns enemies through Setup at run time) [MED]; the Bat's cache marks cover
  0x6cc/0x6cd of the dump's 0x6cc–0x6d5; the Roach Setup's `+0x154 = x` and speed 0x4b0 (M l. 64945–64946) unset (Phase 5);
  the Bat's path mode lives in the `voicePitch` slot (documented); the replica loads chest/crate drop faces per level where
  the original loads every Bonus face at boot (a seam, test pins it per level); the plan's LV3 test text had the spike frames
  backwards (frame 0 = out) and LV4's "node 5's neighbour" is node 5 itself (D35); `testEverySpawnableTypeHasSheet` ~15 s.
- **Run 28 carries:** the mosaic's cell-20 out-frame is never presented (last out-blit and first in-blit share a tick)
  [LOW]; the copy-before-`.mosaic` routing in `FrameRenderer.swift:~379` is an unstated coupling [LOW]; a teleporter
  with a missing record falls back to partner 0 [LOW]; the gamepad treats a teleport / upgrade as normal play [LOW]; a
  statue platform's own pair latch is never cleared while frozen (built as written); the trunk growth walk returns on a
  dead link (unreachable) [LOW]; the floe x not re-truncated to 16 bits [LOW]; light face 820 load unchecked in the app;
  the enemies' 11 statue sites ◇ Phase 5; the plan's own task headings still carry the pre-shift ladder numbers ("→ 477")
  — the shifted totals in this file and l. ~119 rule.
- **Run 27 carries:** a level that fails to load while a system Quit is held loses the quit [LOW]; QT's "already
  pending" guard untested (harmless); a chest dropping 0xc25 still throws (none in the census) [LOW]; BX2's timer test
  checks the sound position only at (0,0); `BonusSprite.swift:87–89` doc predates the chest-drop flag; the goldens are
  blind to chests/doors (forcing them open moved none); a firing spout skips the spawned shot's Setup draws (◇ Phase 5 —
  level 4's RNG shifts when it lands); a record-less sprite (index −1) reads record 0 in the gate/spout arms [LOW];
  `LevelRun.swift:508` hard-codes "boss alive" though `world.bossFlag` exists [LOW, Phase 6].
- **Carried minor follow-ups (not adopted, D38 Ruling 15 — left to Ben's Q6 verdict):** report fade-in when faded (M l. 35448)
  unbuilt; a second queued main-menu pick dropped; boot bar jumps; music decoded on play; `.savePoint(saved:)` carries no
  polled input after the save dialog; `SavedGameFile.writeErrorReport` code typed optional; `CoreTextRasterizer` widths
  untested; `FerazelController.fail()` exits with only an NSLog; the save panel's field label repeats the prompt. **Runs
  19–20 carries:** `SeparateFromTiles.swift:109` names landed tasks (relabel when touched); the app's `SoundTool` "unloaded"
  rule + `isPlaying`/`playingSounds` lack the nil-handle-counts-all rule; `GroundCeilingEffects.swift:207` builds a lookup
  per smoke frame; `SpriteWorld.valid()` extra bound; the Px strip `+0xea`; conversation action 2's `0bf4`/`0bf0` stores
  unwired; the status bar's source-clip model untested [MED]; Render's text caches per renderer. **Run 21 carries:** TB's
  test fixture uses one face in every parallax cell slot and assumes rowBytes 128; several `BonusSprite.swift` cites run ~20
  lines short of the dump; a Core-only session with no faces skips the Xichron burst's draws quietly; a 1058 with p1 out of
  range is dropped where the binary writes past the end; `BonusSprite` 0xc25 and 0xc9b…0xcb0 still `notTranscribed` —
  **recheck at LV3/LV4**.
- **Run 23 carries:** the Continue route's level carry is untested; the 1090 cannon smoke's Setup exists twice
  (`BackgroundSprite.swift:~737` and `EffectSprite`); Core never reuses sprite records (followers never alias a reused record);
  the "no free record" error report is not modelled; `noCastBegan`/`wandHeld` are the plan's `castBegan`/`wandHold`;
  `rideRamp` doubles as the Shadow Double history index (SD).
- **Run 24 carries:** a shot whose side of a torch contact runs first is killed twice (two sounds, two effects — the
  binary's collide loop has no dead check, built as written); the stale r29 at the sprite-hit and tile-hit sites changes no
  light [LOW]; the crunch strength is passed as 8 bits where the binary passes 16 (always 1) [LOW]; the dump clears the
  Shadow Double flag in two state-selection branches (M l. 45410, 45478) — **SD's**; the trail's 0xb000x tints are not
  checked by eye; SW owns the Statue arm of `.HitPlayerShotSprite` and BX1 the crate arm's r29 (seat notes in their plan sections).
- **Run 25 carries:** the Magical Shield's crouch face is still a stub that treats the shield as absent; with slot −1 (empty
  inventory) the binary's move-to-front copies the empty slot's raw words into slot 0 — not modelled [LOW]; two
  health-potion loops in `ItemUseTests` are unbounded; the resumed player's map-redraw ops are unpinned (the next Handle's
  cleanup flushes them); Smite computes the inert Phase-1 enemies' centre from the hot rect (`// later: Phase 5`); MS: the
  Blob-attacker exception of the crystal shards is Phase 5's; the forced-death flag `0568` is always 0.
- **Run 26 carries (BX2/BT items now done):** a New Game builds a fresh `LevelCarry`, so the Shadow Double ring's mirror bytes reset there where the
  original keeps them until the app quits [LOW]; the Bat 0x6cc crate-drop arm is unreachable until Phase 5 builds non-Bonus
  drops; unbuilt Box arms skip `.StandardSpriteHandles` until their tasks (BX2/BT/SW); a stomped switch block only loses HP
  until BT builds its Handle (done, run 27); stale `// later: Phase 4` at `HitPlayerSprite.swift` ~l. 180, 815, 851, 889 (A4's sweep); a
  crate with no placement record reads p4 as 0 [LOW]; `BonusSprite` 0xc25 / 0xc9b…0xcb0 still `notTranscribed` (no crate
  on levels 1–4 drops them — recheck at LV3/LV4); `BonusSprite.sheets` names PICTs 3109/3200 the data lacks (not drawn).
- **Run 22 carries:** the smoothing mix is linear with no gamma and the 14 pt threshold is read from the LP, both [MED];
  the LP's Times still looks a little heavier and ~5 % wider than today's system Times (D39 allows bundling classic Times if
  Ben asks); SP left the level-start pan, the load bar and walk distance per step unmeasured [LOW].
- **Lessons (runs 9–21, 22):** (1) ground on the bank + the dump; (2) the plan is wrong against the dump about once per task —
  the dump wins, the as-executed bullet records it; (3) run the seat's own gates from the worktree once no agent is
  building; (4) foreground `Agent` calls return the report directly — two review legs in one message run in parallel in
  `git archive` temp copies; (5) a fix round that changes behaviour gets a re-review; a tests-only or tiny round the seat
  reads itself; (6) reviewers' mutation runs are the best signal — strengthen inside existing test functions so the ladder
  holds; (7) check `FerazelSession.swift`'s switch, `SessionTests.swift`, `ScreenRenderer.swift` and the FrameRenderer sheet
  table whenever a task adds a case or a spawnable type; (8) merge each green task to main before starting the next; (9)
  AppKit: never leave a `.terminateLater` pending across play; (10) tell Fable reviewers "no background agents"; (11) read
  each layout/flow table against its ruling's why; (12) a resumed subagent (SendMessage) runs in the background — stay in
  the turn until its notice arrives; (13) **reviewers keep making the `~/Developer/HectorKit/HectorKit` self-link (again in
  run 21, mtime during the run) — check G1 with `git -C ~/Developer/HectorKit status --porcelain` at the close and `rm` only
  that symlink (`[ -L … ]`) if this run's agents made it**; (14) fix rounds driven by a mutation table work well; (15)
  audit the dump for every writer of a newly-read field; (16) accept a whole-struct expectation edit only after reading the
  diff; (17) check each "not built" item against the task's M lines; (18) **run 21: when an implementer is BLOCKED by a gap
  no task owns (mode 0xb), park its work as a WIP commit on a side branch, rewind, insert a small task for the gap first,
  then cherry-pick the parked work and have a fresh implementer finish — history stays task-by-task; the ladder shift is
  recorded in the plan and D38;** (19) the golden "switch the new behaviour off → old values return" check is what makes a
  ◈ move acceptable — ask both implementer and reviewer to do it; (20) **run 22: a "measure first" task runs well as a read-only
  investigator in parallel with the other task's implementer, then a reviewer who re-measures independently; wait on a
  background agent by `stat -L` on its transcript (the task file is a symlink).** (21) **run 23: a stub that skips a routine's
  sound or spawn draws desynchronises the RNG — when built code reaches a later task's routine (the spring → `.KillPlayerShot`),
  build the routine faithfully now and tell the owning task; run the wave-end gates in a background Bash while a
  foreground reviewer works.** (23) **run 25: when an implementer STOPS on an existing test the dump contradicts, read the cited M lines yourself, then rule and record it in the commit body + D38 (it took one SendMessage); a new suspension case can break the app's exhaustive switches — run G5 before merging even a Core-only task that touches `FrameSuspension`; Ben's attended session may commit to main mid-run (Q9) — rebase before the merge.** (24) **run 26: an implementer that STOPS on an old test pinning a named stub ("pushing is the Phase-4 tail") gets the seat ruling by SendMessage with a condition — re-derive the new value from the dump and explain every pixel, else STOP again; both review legs then re-derive it. A ◈ task may legitimately move no golden — have a reviewer probe why (which sprites wake on the golden routes).** (22) **run 24: a test that pinned a named stub's placeholder (GL's steering row) may take the dump's value by seat ruling, recorded in the commit body + D-number; the implementer must STOP and report first (it did); mislabelled `// later:` owners are worth a check (the Statue arm is SW's, not Phase 5).** (25) **run 27: Ben may commit to main mid-run (Q10 arrived during QT) — `merge --ff-only` fails, rebase, re-run G2, merge; a reviewer's mutation that survives on a fallback line is worth a seat ruling when it exposes a hole in Ben's intent (a Dock Quit lost during the opening screens); an implementer's "plan says one press, dump says two" claim gets its reviewer pointed at both call sites.** (26) **run 28: implementers and resumed agents always run in the background here — wait with a `stat -L` mtime loop on the task output (idle > 500 s, or the notification); reviewers' mutation tables keep finding arms the whole suite does not pin (TP: unpinned centre/scroll; SW: four Statue arms) — a tests-only round inside existing functions, seat-read, is the standard fix; an agent made the HK self-link again (removed at close).** (27) **run 29: a level's "enterable" task also owns its level-load picture cache (`CachedFaces` in `Front/LevelRun.swift`) — every Setup's cache marks, pinned by the bar step count; a reviewer leg that runs the real level load finds it; the census test's "nothing refused" is not the whole job.** (29) **run 32: a run that spans 21:00 skips its launch gates — the owed gate goes FIRST in the next daytime run; the review legs' sharpest find was a plan-internal conflict (mute vs Ruling 20's silent mixer) — ask legs to read rulings against each other; a resumed implementer's fix round runs ~10–50 min — wait with a `git rev-list --count` loop on the branch.** (30) **run 33: a reference frame must be checked for what it shows — WF1's two pinned frames drew no text, so a reviewer's recording rasterizer found the first text-bearing frame (+414) for WF3; a log line that prints a constant proves nothing — ask legs to probe each gate's line for whether it can fail; implementers and resumed agents ran ~25–45 min each, GW2 now ~9 min.** (31) **run 34: the first daytime Proof B crashed after 3 tests on a Wine gap — run the owed launch gates the moment the guard opens (a timer job waiting for 09:00 worked), and expect CrossOver-only gaps; a fix that changes a gate's bar is a named small task (WF0b) with its own leg; reviewers that background their mutation loops stall — tell legs "foreground only"; a reviewer copy at `$T/repo` + `ln -s ~/Developer/HectorKit $T/HectorKit` satisfies `../../../HectorKit`.** (32) **run 35: a reference frame must be checked for what it shows (again) — the "first text frame" was the first fade-in step, nearly black; the Fable leg caught it by counting colours; implementers and legs ran 11–30 min each; the stage script's fixed folders mean stages never run side by side.** (33) **run 36: Ben's attended sessions can land many commits between runs (19 here) — re-derive counts by running G2/GW2 at reconcile, not from this file; an opt-in test that skips by design changes every "0 skipped" bar (G2, GW2, Proof B) — rule the named-skip bar in the plan; a resumed subagent runs in the background, so a fresh foreground implementer with the findings verbatim is the safer fix round in this headless loop; check a fix round's "partly rejected" item against the dump yourself (it was right: shake, not music).** (34) **run 37: the first real Proof B after Ben's attended tests found two Wine gaps no Mac gate can see (a `@MainActor` XCTestCase crashes Windows XCTest's listing; `FileManager.enumerator`/`NSRegularExpression` find nothing under Wine) — run GWB early in a run that touches tests, and tell implementers a Proof-B test must avoid Foundation's enumerator, regex and attribute calls and actor isolation; reviewers who export a variable before testing an `unset` miss the empty case — the seat runs the real script; Ben landed a test mid-run → the ladder shifts +1, merge each task by SHA (`merge --ff-only <sha>`) while the next task's implementer works on the branch.** (35) **run 38: the seat's Proof B is the only gate that sees Wine traps — a new audit test crashed the whole Windows test process (Foundation's `String.contains(String)`), found by symbolizing the crash and a `--class` re-run in a scratch archive; a reviewer's mutation found the audit's draw check empty (culled coordinates, zero clip) — ask audit legs to break the thing under test and confirm the check fails; a ◈ task may move nothing — have the leg probe the band (UT: no golden route goes fully under).** (36) **run 40: the Core suite outgrew a 10-min foreground call — background the seat's G2 and tell agents to batch by `--filter`; a seat gate script running every non-launch gate in a `git archive` copy (HectorKit symlinked at `$T/HectorKit`, its own `WIN_BUILD_ROOT`) let the next implementer work at the same time; for a ◈ task, ask a leg to log which enemies are awake on each golden route — the plan's "every golden moves" was wrong because no Walker wakes on level 1's routes.** (28) **run 31: when Ben changes a ruling while a subagent works, record it, then tell the next legs "known pending change — not a finding, say what it needs" and fold it into the one fix round; Ben's rulings can arrive as commits to `main` minutes apart — re-read QUESTIONS before writing D-numbers.**

