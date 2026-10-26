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
Answer:

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

## Answered

_(moved here by the run that acted on the answer, with what it did)_

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
