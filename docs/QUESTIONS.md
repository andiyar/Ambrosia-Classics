# QUESTIONS — Ben's queue for the unattended loop

> The loop (`.looper/config.sh`, chip `docs/NEXT.md`, ledger `docs/LOOP-LOG.md`; rulings D34) cannot ask questions
> while it runs. Anything only Ben can decide lands here; the loop takes the recommendation's default only where the
> item says so, and otherwise carries on with whatever is not blocked. **Ben answers by writing under `Answer:` and
> committing to local `main`** (from any session, phone included); the next run reads this file first, applies the
> answer as an authorization for exactly what it says, records it in DECISIONS, and moves the item to "Answered".
> Nothing here blocks the loop unless the item's `Blocks:` says everything does — then `docs/NEXT.md` carries
> `STATUS: BLOCKED` and the loop stops until he answers.

**How to answer (Ben):** write on the `Answer:` line (a letter is enough, a sentence is better), save on local `main` —
`/Users/andiyar/Developer/Ambrosia-Classics/docs/QUESTIONS.md` — and commit. If the loop stopped with `STATUS: BLOCKED`,
change the first line of `docs/NEXT.md` to `STATUS: CONTINUE`, `rm STOP` if it exists, and start the loop again
(`.looper/config.sh` header has the command).

Item shape (the kit's standing prompt; the loop writes these, numbered in order):

```
### Q<n> — <date> — <one-line question>
Context: <two or three plain-English sentences; paths, SHAs, the gate card or what "pass" looks like>
Options: (a) … (b) … (c) …
Recommendation: <letter> — <why>
Blocks: <what cannot proceed until answered; what can>
Answer:
```

Standing kinds of item: a phase's gate card ("play the staged build at ~/Desktop/Ferazel's Wand.app"; the gate card
itself lives in `Ferazel/WHAT-TO-EXPECT.md`), a visual or feel verdict a MED/LOW reading needs, a new phase plan (for
his later read — execution does not wait, D34), two Opus review legs contradicting each other on a MAJOR point that a
Fable tie-break could not settle, anything that needs an install, a credential, a notarized build, a remote, or his
brother's Windows machine.

## Open

### Q16 — 2026-10-30 — Phase 5 plan (enemies): five small choices, for your later read
Context: Loop run 36 wrote the plan for Phase 5 (`docs/plans/2026-10-30-ferazel-phase5.md`, D44): 22 tasks over about
ten runs, Mac and Windows together. It starts with your Q15 follow-ups (the sparkle fix, the draw-mode audit, the
random-play bot), then brings every enemy on levels 1–4 to life and opens level 5 up to the Warrior's arena. Reviewed
by two Opus legs and one Fable leg; all findings fixed. The loop builds with the defaults below unless you say otherwise.
Options: (1) "Through the first boss door": (a) levels 1–4 with live enemies + level 5 up to the Warrior's arena (the
arena locks, the Warrior stands still until Phase 6) (b) keep level 5 closed until Phase 6. (2) A picture the port
cannot draw: (a) keep quitting the game (loud; the new checks make it unreachable) (b) draw nothing and log it.
(3) The picture-shrink rule (stage screens, map, level 2's big light): a capture from your Mac OS 9 VM of a stage screen
or that light, or a Let's Play time, settles it — no task until then. (4) The empty item box: the port now draws what the
original reads there; if you ever see the original with an empty inventory, say what the box shows. (5) Enemies first
placed after level 5 (Dillo, Gremlin, Wraith, Salamander, Crab, pipes, geysers) are built and tested now though not
reachable until Phase 6: (a) yes (b) wait.
Recommendation: (1a), (2a), (5a); (3) and (4) only when convenient.
Blocks: nothing (D34: execution does not wait).
Answer:

### Q15 — 2026-10-29 — Andrew's Windows test: the teleporter quit the game (fixed); four follow-ups for the loop (written by Ben's attended session)
Context: Andrew (Windows beta tester) found the game closes when Ferazel uses the level-1 teleporter (the urn). Test
build 2 (commit 0bb92b9: the Windows log keeps the previous launch, a crash filter, stderr in the log, "where:" lines)
showed it was not a crash: "the screen could not be drawn: mode(327683)" — draw mode 5 (teleporter-charge sparkle) was
still refused by `SpriteBlitter`, and both shells end the game on any draw failure. Mac affected identically (Ben had
never used a teleporter). Fixed in 0fd056e (Opus implementer + Opus reviewer PASS WITH FIXES): modes 5 (Diffuse, game
FastRand threaded via per-draw seeds + a Core walk) and 0xa (springboard gauge squash, level 3); Core 490 → 495/0,
Windows 77/0. Test build 3 published for Andrew. Andrew's log also shows both his saves brought up the Windows
"name your saved game" dialog (saving works on real Windows; restore still unconfirmed — Q14).
Follow-ups for the loop (default: plan them as one small task at the start of Phase 5 planning; none blocks):
(1) the renderer draws the sparkle at the last grid-redraw scroll (`FrameRenderer.swift:394`) while Core walks at the
camera scroll — passage-jump / teleport-mosaic frames can drift the RNG (visual only); (2) still-refused combos
(rotated/scaled mode 5, flipped 0xa, and every other refused mode) quit the game if ever reached — audit every mode
the Core writes against what the blitter draws, in all levels of the phase, as a standing phase-end check; (3)
`docs/ferazel/draw-effects.md` §2.6 lacks the colour-pass row guard the code follows; (4) a teleporter test through
`LevelRun` (mosaic + after-arrival sparkle, `HitPlayerSprite.swift:456`).
(5) Ben 2026-10-29 ("yes"): a random-play bot — headless, per level in scope, a few minutes of random/mashed input
through the real render path on both the Core and Windows-shell paths, failing on any refusal/throw/trap — built as a
loop task and run at every phase end beside the visit-every-object sweep (`tools/ferazel-visit-sweep.sh`, being built
2026-10-29 by Ben's attended session) and the load-every-face test. A phase cannot close while any of the three fails.
(6) 2026-10-29 fixes 78e81c3 (teleport/passage re-seat), 48a0620 (PICT 806 light shrink → level 2 quit; rope faces →
level 3 quit), b535527 (every boot face loaded as `.InitSprites` does). Reviewer open items: the QuickDraw shrink rule
(`ScreenRenderer.sampleRows`, floor `y·src/dst`, also used by the stage screens and map) has never been measured —
~50% it should be centre-sampled; settle it from a capture of the original (Ben has a Mac OS 9 VM, the Let's Play);
`LightFaces.swift:69` comment (light faces load at boot, not level setup); newly loaded faces may change box hot-rects
/ particle emitters (closer to the original, untested); `BootFacesTests` source scan misses computed pict ids.
(7) 2026-10-29/30 attended fixes since: e9fa8b0 (Continue refuses unbuilt-level saves), the visit sweep
(`tools/ferazel-visit-sweep.sh`), the gap ledger (`docs/ferazel/port-gap-ledger.md`), 3cf72df (world-map status bar:
colour-translated from clut 200 into clut 700 as `.CopyBitsCT`'s seed rule makes QuickDraw do — Andrew saw it blue).
Its reviewer's open items: `.UpdateTextStats` draws via SetPort (screen device, clut 700 on the map) — text smoothing and
flash colours may need matching in 700 then reading back through 200 (latent: map text is pure black/white; the icons
contradict the strict reading — settle from a capture); StatusBar.swift:35 comment (black is index 96 in clut 200 under
the lowest tie-break); MapRenderTests reference rebuilds with the fix's own model. Also: a screen-vs-Let's-Play
comparison check would catch wrong-picture bugs the crash checks can't (Ben's Andrew found this one by eye).
Options: (a) as default; (b) Ben says otherwise.
Recommendation: a.
Blocks: nothing.
Answer:
_Loop run 36 (2026-10-30): planned per the item's default (a) as Phase 5 wave 5.0 (tasks PB, SP, RV, DK, UT, DA, RB — D44); item 6's shrink rule became Q16 (3). Left open for Ben's word._
_Loop run 37 (2026-10-30): PB, SP, RV built and merged (0b02d31). Item 1: the drift was not actually happening at 6a70bce (every sprite pass follows a grid redraw at the camera) — the walk now uses the renderer's own scroll, so it cannot start. Items 3, 4 and 6's code items done; Proof B passes again (507/0/2/0 of 509) after two Windows-only test fixes. Item 7 (your 13:01 addition) is handed to run 38 to carry. Left open for Ben's word._

### Q14 — 2026-10-27 — Windows gate: does Ferazel's Wand on Windows behave like the Mac build?
Context: The Windows build of Ferazel's Wand (the same game as the Phase 4 Mac build: levels 1–4, spells, items, saves,
map, controller) is finished on the machine side (loop run 35). The loop checked it muted, by day: in a clean CrossOver
bottle it draws the main menu, level 1 and level 1's text exactly as the Mac does, and the game's 490 core tests run
under CrossOver with 489 passed, 0 failed, 1 skipped (a test CrossOver cannot run). Nobody has heard it or run it on a real
PC. The zip is `~/Desktop/Ferazel's Wand (Windows).zip` (also `out/Windows/` in the loop's tree; never published); the
checklist is `WHAT-TO-EXPECT.txt` inside it (repo: `Ferazel/WINDOWS-WHAT-TO-EXPECT.md`) — for you or Andrew on a Windows
10/11 PC. **Please try a real save at a save point and a restore**: the Windows Open/Save dialog code has never been run.
Pass looks like: the Mac build's behaviour on Windows — sound by ear, dialogs by eye, keys, controller, Options kept
after a relaunch, the close button asking before quitting a level.
Options: (a) pass; (b) pass with notes (write them — each becomes a task); (c) fail (say what is wrong).
Recommendation: a or b — every picture the machine can compare matches the Mac; only a person can judge sound and a real PC.
Blocks: nothing (gates queue, D34). The loop plans Phase 5 (enemies) next, Mac and Windows together.
Answer:

### Q13 — 2026-10-26 — Windows plan (Phase W): six small choices, for your later read
Context: Loop run 31 wrote the plan for Ferazel's Windows build (`docs/plans/2026-10-26-ferazel-windows.md`, D43): seven
tasks over about four runs, reusing Bubble Trouble X's Windows parts, the zip staged under `out/` (never published).
Launches follow your Q12 rule (muted, never 21:00–09:00). The loop builds with the defaults below unless you say otherwise.
Options: WQ2 saved-game files: (a) native Windows Open/Save boxes (b) the original's file box drawn in the window
(c) a fixed saves folder with an in-window list. WQ3 full-screen key: (a) Alt+Enter (b) F11 (c) both. WQ4 window:
(a) resizable, whole-number scaling on black (b) fixed like the Mac. WQ5 key names in Options: (a) US-layout names
(b) the PC's own layout. WQ6 saved-game names: (a) no extension, as the Mac (b) add `.fwsg`. WQ7 dialogs: (a) inside
the window, enlarged with the game (as Bubble Trouble X) (b) inside, always original size (c) separate windows.
Recommendation: (a) for all six — closest to the Mac app and to what Bubble Trouble X's Windows build already does.
Blocks: nothing (D34: execution does not wait).
Answer:

### Q11 — 2026-10-26 — Phase 4 gate: do the spells, items and levels 1–4 feel like Ferazel's?
Context: Phase 4 "Spells + items" is finished on the machine side (loop run 30): all 490 core tests pass, the original
data decodes cleanly, the app builds, the staged build starts and quits cleanly, and the Fable review over the whole
phase found nothing wrong in the game code (only the checklist wording, now fixed). Play `~/Desktop/Ferazel's Wand.app`
(build 4bca4bd; replaced on 2026-10-27 by loop run 35's build — the same game, plus a hidden mute switch), New Game or Resume a Phase 3 save, beside the Let's Play; the checklist is
`~/Desktop/Ferazel's Wand — WHAT-TO-EXPECT.md` (repo: `Ferazel/WHAT-TO-EXPECT.md`). Jump straight to a level with
`open -n ~/Desktop/Ferazel\'s\ Wand.app --args -FerazelLevel 3` (1 to 4). Pass looks like: the item bar and stepping
through items, the Fireball and the dagger, torches and rock piles giving crystals, Xichrons and coins, level 1's chests,
keys and door, crates, teleporters, power-up spheres, the magic and health upgrades, potions, level 3 (the Statue spell,
the wounded Habnabit's key, the gate button, mine carts) and level 4 (buttons and switch blocks, the Ring of Smiting) all
behave and sound like the original. Still missing on purpose: enemies stand still and ignore attacks, the boulder spouts
fire nothing (Phase 5); level 5 and later say "not built yet"; the screen does not tint under water yet (Phase 5 will
add it).
Options: (a) pass; (b) pass with notes (write them — each becomes a task); (c) fail (say what feels wrong).
Recommendation: a or b — every point the machine can check matches the original; only your hands and eyes can judge feel.
Blocks: nothing (D34: gates queue). The loop plans the Windows build next (your Q10 answer), then Phase 5.
Answer:

## Answered

_(moved here by the run that acted on the answer, with what it did)_

### Q12 — 2026-10-26 — NEVER launch the game (Ben's ruling, written by his attended session) — overrides D34's G9 boot permission
Context: The Phase 4 end run's boot check opened the staged app four times at ~22:00 with sound; it woke Ben's wife.
Ben is angry about it. This withdraws the loop's permission to launch any app.
Options: (a) no app launches by the loop, ever: no boot checks, no smoke runs, no `open`, no CrossOver/Wine runs of the
Windows build, no audio. Ben launches builds himself.
Recommendation: a — Ben's word.
Blocks: nothing. Gate cards say "not launched by the loop; Ben's first launch is the boot check".
Answer: (a) — Ben, 2026-10-26. Effective immediately for every run, including the Windows runs. Record in DECISIONS
superseding the launch part of D34 (G9); remove app launches from NEXT.md and every plan's gates; staging (copying the
build to ~/Desktop or out/) stays allowed. Headless tests that make no sound and open no window are fine.
Amended — Ben, 2026-10-26, a few minutes later: "Muted launches is fine to test." So: launching a build IS allowed again
for boot checks, but ONLY with the game's sound fully off. Before any launch, the loop adds (and tests headlessly) a
mute switch the launch uses — e.g. a launch argument or environment variable that stops the app opening any audio
output (Mac); for the Windows build in CrossOver use a no-sound audio driver through the HECTOR_SDL_* passthrough
(CrossOver strips SDL_*). No launch without that switch. Keep launches few and short. The attended monitoring session
warns Ben in its hourly note before a phase-end run that will launch.
Night rule — Ben, 2026-10-26 22:10, going to sleep: "don't want it to wake anyone up". NO launches of any kind, muted
or not, between 21:00 and 09:00 Mac local time (check `date` right before any launch). A run that reaches a launch step
in those hours skips it, stages only, and writes "boot check owed (night rule)" in its LOOP-LOG line and the gate card;
the first daytime run does it, muted.
Acted on (loop run 31, 2026-10-26): recorded as D42 (all three parts); the Windows plan (D43) and NEXT.md carry the
mute switches (Mac `-FerazelMute YES`, Windows `--mute` / `HECTOR_SDL_AUDIO_DRIVER=dummy`) and the 09–20 launch guard.

### Q10 — 2026-10-26 — A Windows build before Phase 5 (Ben's ruling, written by his attended session)
Context: Ben wants a friend (Andrew, on Windows) to beta-test playable levels soon. The design puts the Windows twin in
Phase 7; Ben, 2026-10-26: "Could do a windows build pre phase 5." Bubble Trouble X's Windows port (the SDL shell,
HectorSDL) took about an hour and a half of loop time, so it is cheap to pull forward. Ferazel's extra Mac-only App
parts (menus, dialogs, text drawing) need Windows counterparts; Q8 lets the classic Apple fonts ship, which helps text.
Options: (a) after Phase 4's end (stage + gate card), plan and build the Windows twin as its own short phase before
the Phase 5 plan, staged as a zip in out/ like BTX's (no release, no upload — Ben hands it over); (b) leave it in Phase 7.
Recommendation: a — Ben's word.
Blocks: nothing now; the next phase-end run picks it up.
Answer: (a) — Ben, 2026-10-26. Windows build straight after Phase 4, before Phase 5. Record in DECISIONS; stage only,
never publish (D34 still holds: no releases or uploads without Ben). Then, Ben 2026-10-26: "Then we do a windows build in lockstep
with the Mac build." From then on the Windows twin is kept in step: every task that changes what the Mac app shows or
does carries its Windows side in the same task, and every phase end stages both builds (Mac app + Windows zip) with one
gate card. The Phase 5+ plans are written that way. Recorded as D41 by loop run 27.

### Q5 — 2026-10-24 — Quitting Ferazel from the Dock or at logout during a level: keep the original's "wait"?
Context: The original game only listens for the system's "quit" message at the main menu and in its pause screen; during
play it holds it (or, with "Allow background tasks" on, throws it away). Loop run 16 copied that (D35 as built, run 16):
Quit from the Dock, the app menu, or a logout while a level runs does nothing until you pause or return to the menu —
then the game's own quit sequence runs. macOS shows that as "Ferazel's Wand cancelled logout". File ▸ Quit (⌘Q) in the
pause works normally.
Options: (a) keep the original's behaviour; (b) quit at once from anywhere (a modern affordance); (c) at once only for
logout/shutdown, original behaviour for Dock/app-menu Quit.
Recommendation: a — the standing 100 % rule (replicate the original, no modern affordances).
Blocks: nothing (built as (a); (b)/(c) would be a small App change).
Answer: Ben, 2026-10-26: "quit from dock should always behave." then "or it can trigger the game quit dialogue". Build: Quit from the Dock or the app menu during a level does exactly what ⌘Q does in a level: the game's own "do you want to quit?" box, at once, instead of waiting for a pause; a logout or shutdown quits at once without a dialog, so it is never cancelled. A deliberate departure from the original's wait, Ben's call (read by his attended session; he will say if he wants it otherwise).
Acted on (loop run 26, 2026-10-26): recorded in DECISIONS D40; planned as task QT (Phase 4 plan, wave 4.6Q, +3 tests) — built by the next run first.

### Q7 — 2026-10-24 — Phase 4 plan (spells + items): three small choices, for your later read
Context: Loop run 18 wrote and reviewed the Phase 4 plan (`docs/plans/2026-10-24-ferazel-phase4.md`, rulings in
DECISIONS D38): casting and every spell, items and the inventory display, pickups and power-ups, crates, chests, doors,
keys, switches, teleporters, the held weapon. At the end of Phase 4 levels 1–4 can be entered (level 5 is the first boss).
Execution starts next run without waiting (D34). Three choices in it are yours; each has a default the loop builds.
Options: (1) levels 3 and 4 open in Phase 4 with their enemies standing still (they come alive in Phase 5) — default
open; or keep them closed until Phase 5; (2) spells and items first found on later levels (Boomerang, Ice Wall, the
glider, the shields …) are built and machine-tested now though you cannot reach them before Phase 6 — default yes;
(3) item counts drawn in Geneva by the Mac's own font engine — default yes.
Recommendation: the defaults — more of the game to try sooner, and no behaviour changes.
Blocks: nothing (D34). A different answer becomes a small task in the phase.
Answer: the defaults — Ben, 2026-10-26: "levels don't care. spells yes. item counts yes." (1) levels 3–4: no preference, so the default stands (open in Phase 4, enemies still until Phase 5); (2) build and test the later-level spells and items now: yes; (3) item counts in Geneva by the Mac's font engine: yes.
Acted on (loop run 26, 2026-10-26): recorded in DECISIONS D40; the plan stands unchanged.

### Q9 — 2026-10-25 — Game speed: keep the original's top speed, or slow it to the Let's Play's pace?
Context: Your Phase 3 note "it runs very fast" was measured (loop run 22, two independent checks). The port runs exactly
as fast as the original's own code allows: one game step every two sixtieths of a second, 30 steps a second, the same
cap the 1999 game has. The Let's Play is slower because SheepShaver could not keep up: its text appears at the true
speed (30 letters a second, same as the port), but during play only about 25 new game steps a second reach the screen
(20 to 29, varying). So the port plays about 20 % faster than that video. A 1999 Mac fast enough to hit the cap would
play at the port's speed; slower Macs played slower (the game has a frame-rate readout and a "reduce frame rate" option,
which only skips drawing, not game steps).
Options: (a) keep the original's top speed (faithful; no change); (b) add a hidden setting (like the gamma toggle) that
caps the game at a slower pace, off by default; (c) make a slower pace the default — say how much (the video's ~25 steps a
second, or another number).
Recommendation: a — it is what the binary does; if the video's pace is what you remember, (b) gives it to you without
changing the faithful default.
Blocks: nothing. (b) or (c) becomes a small App task.
Answer: (a) keep the original's top speed, for now — Ben, 2026-10-26. Ben's attended session measured the running app on his Mac (a screen recording of level-1 play): a steady 30 new frames a second, never more, so the port matches the binary's cap. Ben: "huh. let's keep it for now." No code change; he may revisit (b) later.
Acted on (loop run 25, 2026-10-26): recorded as an addendum to DECISIONS D39; nothing changes in code.

### Q8 — 2026-10-25 — Apple system fonts may ship (Ben's ruling, written by his attended session)
Context: The project had a standing rule (Aki D23, carried into the BTX release script) against shipping Apple's system
fonts. Ben, 2026-10-25: "I didn't make that rule. happy to override it." For Ferazel's text fix (Q6 note 1), the faithful
font is Mac OS 9's Times (and Geneva for the status bar), which today's macOS ships in different versions.
Options: (a) ship Apple fonts where the faithful version needs them; (b) keep the old rule.
Recommendation: a — Ben's word.
Blocks: nothing.
Answer: (a) — Ben, 2026-10-25. Record as a new DECISIONS entry superseding the font part of D23. Approach for Ferazel:
first smooth the modern Times/Geneva (Q6 note 1); if it still looks off against the Let's Play, source the classic fonts
from Ben's Mac OS 9 setup, or from the collection Ben pointed to (https://github.com/pjobson/Apple-Fonts), and bundle them. Release scripts that assert "no fonts bundled" (package-*-release.sh) need
updating only when a font is actually shipped.
Acted on (loop run 22): recorded as D39 item 2 (supersedes the font part of D23). No font bundled yet — the smoothed system Times is in; the Let's Play glyphs still look a little heavier and ~5 % wider (the font, not the smoothing): bundling classic Times is the next step if you still see a mismatch.

### Q6 — 2026-10-24 — Phase 3 gate: title → level 2 and back — does the front end feel like Ferazel's?
Context: Phase 3 ("Front end + saves", plus controller support) is built and machine-checked (Ferazel/Core 349/0,
census 1,108/0, app builds; the staged build boots to the main menu and quits clean, twice; the Fable phase-end review
found no code problems, only wording fixes, now applied — D35 as built, loop run 17). Play `~/Desktop/Ferazel's
Wand.app` (build 3553392) from a cold start, keypad or a game controller, beside the Let's Play. The checklist is
`~/Desktop/Ferazel's Wand — WHAT-TO-EXPECT.md` (repo: `Ferazel/WHAT-TO-EXPECT.md`): title and loading screen, main
menu, Options (key remapping), Credits, New Game, talking and signs, the save point, Caps Lock pause, the stage-complete
panel, the world map, level 2, aborting back to the menu, Resume from a save, death with and without a save, and the
Controller step (a kid can play levels 1–2 with only the pad; a stray − tap never aborts). This is the first time
anyone has played through the new front end — a crash or hang anywhere is the most likely failure. Known stand-ins
are listed at the card's end (only levels 1–2, HUD shows the start inventory, enemies stand still).
Options: (a) pass; (b) pass with notes (write them — each becomes a task); (c) fail (say what is wrong).
Recommendation: a or b — every front-end and save-file behaviour checked matches the original's code; only your
hands and eyes can judge the feel, and only real play can find a crash the boot check can't reach.
Blocks: nothing (D34: gates queue). The loop plans and builds Phase 4 meanwhile; (b)/(c) notes become Phase 3 fix
tasks, planned first.
Answer: (b) pass with notes — Ben, 2026-10-25, played the Phase 3 build (3553392) with keypad and controller: no crash or hang; movement, damage, drowning and breaking the environment work. Notes (each a fix task, planned first): (1) TEXT IS HARD TO READ — vs the Let's Play (SheepShaver, Mac OS 9) the conversation/sign text and the status-bar stage name are ragged and broken; cause found by his attended session: Ferazel/App/CoreTextRasterizer.swift thresholds CoreText coverage at 50% (`$0 >= 0x80`), dropping Times' thin strokes; Mac OS 9 smoothed screen text, so keep the antialiased coverage and blend it into the palette as the original OS did; Ben's screenshots (LP vs port) are the reference. (2) IT RUNS VERY FAST — timing code matches the binary (2-tick cadence), so measure Ferazel's speed across a known stretch of level 1 in the Let's Play vs the port before changing anything; the LP was recorded in SheepShaver. Spells / interaction missing is expected (Phase 4).
Acted on (loop run 22): D39; wave 4.2F planned first in the Phase 4 plan. Note 1 → TX: text drawn smoothed as Mac OS 9 drew it (coverage blended into the palette; sizes under 14 pt stay crisp, as the Let's Play shows) — Ferazel/Core 396/0. Note 2 → SP: measured, the port runs at the binary's own cap; the Let's Play is ~20 % slower (emulator CPU-bound) → your call in Q9.

### Q2 — 2026-10-14 — Phase 2 gate: does Ferazel move like Ferazel on levels 1–2?
Context: Phase 2 ("Ferazel moves") is built and its machine gates are green (Ferazel/Core 256/0, census 1,108/0, app
builds, staged build boots and quits clean; Fable phase review passed after fixes — D33 as built, loop run 7). Ben's
gate is pending. Play `~/Desktop/Ferazel's Wand.app` (build d5586fb) with the keypad, beside the Let's Play; the
checklist is `~/Desktop/Ferazel's Wand — WHAT-TO-EXPECT.md` (repo: `Ferazel/WHAT-TO-EXPECT.md`). Level 2 directly:
`open -n ~/Desktop/Ferazel\'s\ Wand.app --args -FerazelLevel 2`. Pass looks like: walking, running, jumping, spinning,
wall clinging, slopes, the camera, water, acid, platforms, pendulums, cannons, passages, death → wipe → restart and the
level 1 → 2 exit all feel like the original; sounds land where and when they should. Known stand-ins are listed at the
card's end (enemies stand still, no pickups, no title/menu, no fade-in after a restart).
Options: (a) pass; (b) pass with notes (write them — each becomes a task); (c) fail (say what feels wrong).
Recommendation: a or b — the machine reads match the binary on every point checked; only your hands can judge feel.
Blocks: nothing (D34: gates queue). The loop plans and builds Phase 3 meanwhile; a fail re-opens Phase 2 as tasks.
Answer: (b) pass with notes — Ben, 2026-10-25, covered by his Phase 3 play test (Q6): movement, damage, drowning and breaking things all work; the speed note in Q6 applies here too.
Acted on (loop run 22): recorded in D39; Phase 2 counted passed with notes (the speed note is Q6 note 2 → Q9).

### Q4 — 2026-10-24 — Ferazel gets game-controller support (Ben's ruling, written by his attended session)
Context: While the loop was paused (STOP 2026-10-14 → 2026-10-24), an attended side session added controller support
to Bubble Trouble X (Classics D36, HectorKit D16: new Foundation-only `HectorInput` translator, `ShellGamepad`,
`ShellView.padMapping` — nil by default, so Ferazel is unchanged until it opts in). **HectorKit main moved 0c65dcb →
35a85ba, zero-skip floor 328 → 361**; checked on 2026-10-24: Ferazel/Core is still **308/0** against it. Classics main
also gained the gamepad commits and the BTX 1.1 release record, and **main was pushed to GitHub** (Ben chose "push
everything"); the loop itself still never pushes. Ben's real-controller check of BTX passed (D36 STATE entry).
Ben wants the same for Ferazel: his kids play on the Switch and the keyboard (keypad-only defaults) is hard.
Options: (a) add a Ferazel controller task to the Phase 3 plan, adopting `HectorInput` exactly as BTX does (the
controller presses the keys named in `FerazelPrefs.keys`, so remapping a key remaps the button; d-pad/left stick =
the four move keys; face buttons and shoulders mapped to the remaining actions with a documented default layout),
built and reviewed like any task, landed before the Phase 3 gate build so Ben's next play test can use a pad;
(b) defer to Phase 7.
Recommendation: a — the game behaviour stays original (the pad only presses the original keys), same class as Q3.
Blocks: nothing.
Answer: (a) — Ben, 2026-10-24 ("let's go" after BTX's pad passed). Plan it as a named Phase 3 task before the gate
build, record the ruling in DECISIONS (next free D-number), and pin the new HectorKit SHA/floor in STATE.
Acted (loop run 13, 2026-10-24): DECISIONS D37 (with the default button layout the loop chose under your
delegation); new plan task GP in `docs/plans/2026-10-14-ferazel-phase3.md` (after A1b, before the gate build; ladder
345 → 349); STATE and the loop chip pin HectorKit 35a85ba, floor 361. Your pad play at the Phase 3 gate is the check.

### Q3 — 2026-10-14 — Phase 3 plan (front end + saves): four small choices, for your later read
Context: Loop run 8 wrote and reviewed the Phase 3 plan (`docs/plans/2026-10-14-ferazel-phase3.md`, rulings in
DECISIONS D35): title, menu, options, world map, chapter and stats screens, save points, Continue, death screen,
conversations, pause. Execution starts next run without waiting (D34). Four choices in it are yours; each has a default
the loop builds unless you say otherwise.
Options: (1) saved games written in the data fork (portable; reads original saves too) vs a real resource fork
(original-readable, stripped by zip/Windows) — default data fork; (2) macOS save/open panels instead of 1997 Standard
File dialogs — default yes; (3) in a window the macOS menu bar stays visible during play (full screen hides it, as
design §7.4) — default visible; (4) keep the hidden `-FerazelLevel N` test switch — default keep.
Recommendation: the defaults — each keeps the game's behaviour and only touches the Mac around it.
Blocks: nothing (D34). A different answer becomes a small task in the phase.
Answer: the defaults, all four — (1) data fork; (2) modern macOS save/open panels; (3) menu bar visible in a window, hidden in full screen; (4) keep the -FerazelLevel switch for now ("probably" — Ben may revisit).
Acted (loop run 13, 2026-10-24): recorded as an addendum to DECISIONS D35; the plan already builds the defaults.

### Q1 — 2026-10-13 — Remove the leftover loop-1 worktree and branch?
Context: Loop run 1 ended its turn while a background implementer was still working. In the looper's headless mode
that exits the session and kills the agent, so run 1 merged nothing. It left uncommitted, superseded partial P4 edits
in `.claude/worktrees/loop-1-20261013-180951` (branch `loop/1-20261013-180951`, at 17f5b04). Run 2 rebuilt P4 + P5
from scratch and merged them, and later runs now dispatch subagents in the foreground. The loop never deletes what it
did not create.
Options: (a) delete it: `git worktree remove --force .claude/worktrees/loop-1-20261013-180951 && git branch -D
loop/1-20261013-180951`; (b) keep it.
Recommendation: a. Nothing in it is needed; everything was rebuilt, reviewed and merged.
Blocks: nothing.
Answer: (a) yes — done 2026-10-15 by Ben's attended session: worktree removed, its partial work was archived as 51c9532 on loop/1-20261013-180951, then that branch was deleted too.
Acted (loop run 13, 2026-10-24): nothing left to do — Ben's session removed both.
