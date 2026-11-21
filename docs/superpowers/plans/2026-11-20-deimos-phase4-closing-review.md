# Deimos Rising — Phase 4, the front end — closing Review (2026-11-21)

The closing Review of `2026-11-20-deimos-phase4.md`, as `fable-kit/project-planning.md` §7 describes, in §3's
layout. Seat: Fable 5.2. Five Opus 5.5 review legs did the reading and the gate runs; the seat checked the two
findings that matter most against the code itself. Nothing was changed, the app was not launched, no sound played.

**How it was done.** Leg A read sections S0, S1a, S1b, S2, S4, S3a. Leg B read S5, S3b, S6, S7. Leg C read S8a and
S8b, the fix rounds that had no second review, Ben's answers and the known fault. Leg D read the gate-4 card and the
records. Leg E re-ran every gate from the merge head. Their full notes (tables, file and line for every finding) are
outside the repo, in the session group's notes folder, as `closing-review-leg-A.md` … `-E-gates.md`. This file
carries every finding that needs a decision or a fix; the fifteen or so smallest test and comment items are only in
the legs' notes.

**One honest limit.** The plan asked for a *Fable* read of the whole phase's diff (about 16,000 lines). That read
has now been done over the whole diff, but by three Opus legs split by section, with the seat reading only the code
behind the main findings. So the whole diff has had a fresh, cross-section read; it has not had a single Fable read
end to end.

---

## 1. Where it stands

**Built and on main** (merge head `7f5569b`; main has since moved only for Ferazel): all thirteen sections. The app
boots to the original's main menu and from there reaches a one- or two-player game through the level select, the
high scores and name entry, the demos, the last game's replay, the credits, both settings windows, a controller,
and Quit with everything saved.

**Gates, re-run by this Review at the merge head** (HectorKit at `ef2c341`, untouched):

| Gate | Expected | Measured |
|---|---|---|
| Core tests without replay and campaign | 491 / 0 / 0 | 491 run, 0 failed, 0 skipped |
| The direct start matches a bare session | passes | passes |
| Census file | unchanged | unchanged |
| Replay tests and the four demo films | 4 / 0, four PASS | 4 / 0, four PASS |
| Layering check | prints nothing | prints nothing |
| Deimos Debug and Release builds | succeed | both succeed |
| Campaign tests, one at a time | 3 / 0 | 3 / 0 (28 s, 455 s, 269 s) |
| Every test loop bounded | yes | yes |

Commands: the gate tables of the three Deimos plans, run as written; build products outside the repo.

**The test ladder:** 372 at the phase's base, 491 now: 119 added, none removed. Every test the plan names exists
under its name, bar the one owned rename (the right-hand hover test).

**Each section against its plan.** Every task meets its acceptance bar, or its handoff owns the change. The scope
fences hold apart from the older-test edits Ben allowed (answer A2). No section hid a deviation.

**The staged app** (`~/Desktop/Deimos Rising.app`, not launched by anyone): built after the last code commit,
universal, ad-hoc signed, signature verifies; its resource file and data match the repo; the two notes beside it
match the repo byte for byte. There is no Deimos settings folder and no crash report on this Mac, so **Ben's first
launch is a true first launch**: full screen, with the unit names on the loading screen.

**Ben's answers — all built as he said, each pinned by a test:**

| Answer | Built |
|---|---|
| Command-Q ignored in play | yes |
| Command-Q quits from the Caps Lock pause, saving settings and scores | yes; a Command-Q pressed in play does not fire at a later pause |
| A quit asked by macOS is remembered until the menu | yes (one gap: finding 3 below) |
| Unit names on the first launch only | yes; "first launch" is read before the fresh settings file is written |
| Erase-scores question from the menu, as a macOS alert | yes (Option + click on SCORES; also resets both names) |
| `-players` and `-sector` removed | yes, from the app and from what a player reads |
| Website line lights and does nothing; "AMBROSIA CLASSICS"; grey settings windows; pad layout | yes |

**The fix rounds S8b said had no second review** (four commits: the last S8a fix, the Command-Q-from-pause fix
round, the goldens fix round, the card fix round) have now been reviewed. Each does what its handoff says; none
introduced a fault. The three Command-Q behaviours pinned late are truly pinned: breaking any of them fails a test.
S6's last commit also had no review leg at the time; leg B's read of S6's files covers it.

**The gate-4 card** (`Deimos/WHAT-TO-EXPECT.md`): no false statement found in 18 spot checks against the code. All
of Ben's answers are on it. The corrections to plan rulings are on it and accurate: credits end on page ten; the
right-hand preview draws its hover outline (confirmed again from the listing); About is never greyed; the start-up
order (two logos, then loading, then the menu) is what the code does. The 16-step fades are on it, worded too
narrowly (section 3).

## 2. What is open

**Findings from this Review, most important first.** None stops Ben's gate; the first is the one to decide.

1. **Command-Q on the level select quietly spoils the next game.** (Two legs found it independently; the seat
   confirmed it in the code.) Press Command-Q on the level select and nothing visible happens. Choose a sector and
   play: that whole game earns no high score and opens no new sector, the first Caps Lock pause quits the app on
   the spot, and otherwise the app quits when you are back at the menu. The cause is one remembered "quit" flag
   that is never cleared when the game starts. It follows our reading of the OS X build, which is itself only
   medium confidence. The card's ruling 20 says the level still starts, not that its score is lost. No test covers
   it. A fix is a few lines, once Ben says which behaviour he wants.
2. **The controller's "paused" layout never switches on**, in a game as well as on the level select (S8b reported
   only the level select). The pause clears its own flag before the app looks at it. In the hand: plus still pauses
   and resumes; but a button or direction held through a pause acts the moment the pause ends, and minus held for
   a second during a pause leaves the game on resume. The keyboard behaves the same way, so it is not unfaithful;
   but the card's controller ruling 52 describes a layout that never applies, and one controller test pins
   behaviour the app never reaches.
3. **A log-out or Dock quit while paused on the level select with the app in the background** does not quit until
   the player comes back, and the log-out is refused. The card says a pause quits at once.
4. **No way out of a stuck start-up except Force Quit.** During the boot Command-Q and the close button do
   nothing and a Dock quit waits for the menu. The publisher logo waits for its sound to end; if the sound output
   disappears mid-logo it waits for good. On a first launch that is full screen. A muted launch is safe. The card
   names a stuck logo as a possible fault but not how to get out.
5. **A test went hollow.** After the real level select landed, the check that "a screen reached in the middle of a
   pass sees none of that pass's queued input" passes whatever the code does. S3b's handoff said no expectation
   was weakened; this one was, by accident.
6. **The scores screen ignores About from the menu bar**; the credits treat it as a click and leave, as the OS X
   build does.
7. **Two more untested paths:** Save in the controls window followed by Cancel in the settings window (the code
   reads right); a duplicate key can be bound when two keys have no name in the original's key list (as the OS X
   build).

**The "one narrow known fault" from S8a** (app switch while the erase question is up): real, harmless, and partly
misdescribed. The queued leave-and-return events do survive the scores screen and a later Quit does flash QUIT
first. But the "both suspended flags left set" part needs a macOS quit while the app is in the background, and
that same path is taken by every Dock quit at the menu in the background, erase question or not. In every case the
app still quits, saves once and keeps the scores; it cannot hang. Its test hands the events in an order the app
never produces, so its last check proves nothing. A fix is 3 to 20 lines in the menu, or it can be left.

**Carried from the handoffs, still open, none new:** the original's pause screen on leaving the app; the OS X
build's Preferences menu item and Edit menu; the pressed 1 PLAYER / 2 PLAYER button lit a pass or two too long;
the smaller items in S8b's "Left" list.

**Not provable without a launch:** clicks and their scaling, full screen, the alert above full screen, a real
controller, the background quit, and how everything looks and sounds.

## 3. What has drifted (plan against as-built)

| Planned | Built | Recorded |
|---|---|---|
| Fades of 32 steps | 16 steps, following the OS X build, on every element fade (the card says "the menu") | card, S1a |
| Ten credits pages and a blank eleventh | ten, no blank page (fits the data) | card, S2 |
| Right-hand preview never shows its hover outline | it does | card, S3b |
| About greyed during a game | never greyed, as the OS X build | card, S8a |
| Command-Q quits at once in a game | ignored in play, quits from the pause | card, mailbox |
| Unit names every launch | first launch only | card, mailbox |
| Card step 1: loading screen, then logos | logos, then loading screen | card, D58 |
| Ladder ends at 477 | 491 (S8a added 16 tests against a planned 3) | handoffs, STATE; not on the card (harmless) |
| A new drawing file for the level select | not made; an existing drawing step reused | S3b |
| One Fable cross-check over the whole phase | reduced at S8b; done by this Review as described at the top | S8b handoff only |
| S8b's "late bank notes" commit | never made | nowhere |

**Records that are now wrong and need a small docs commit** (the bank is what the next plan reads):
- `docs/deimos/INDEX.md` line 410 says the right-hand hover strip is never drawn.
- `docs/deimos/front-end.md` line 350 still has the blank last credits page; the bank gives 32-step fades with no
  OS X note.
- STATE and D58 do not say the cross-check was reduced or that fix rounds went unreviewed (both now made good here).
- The S6 and S8a handoffs and a comment at the top of `DeimosController.swift` give the start-up order the wrong
  way round.
- Stale comments: the pause-quit result "never set" (`SessionResult.swift`), About "disabled during a game"
  (`ShellRequest.swift`), a Quit during the credits "acts when they end" (`Credits.swift`), "every unit name is
  shown" (`Boot.swift`), the key-slot meanings marked low confidence (`DeimosPrefs.swift`).
- From S0, never picked up: the OS 9 listing is not committed under `ghidra/deimos`; committed Ghidra logs carry
  home-folder paths in a public repo; notes name an old Ghidra version.
- The campaign gate's counting pattern misses the longest test's "passed" line (it lands mid-line), so a script
  would read 2 / 0 for a true 3 / 0.

**For the Phase 5 (Windows) plan:** the remainder plan's one-line card is stale. Core already draws both settings
windows; what the Windows shell needs is to answer the erase question, show the two refusal alerts, decode the
app's pictures itself (the Mac code for that lives in the app), and map the Mac-only inputs (Option and Command at
launch, the two volume keys, About, quit, `-mute`, `-film`). The menu ignores hover in the top 22 pixels (the Mac
menu-bar height); that rule is in Core, so Windows inherits it unless ruled otherwise.

## 4. What only Ben can decide

1. **Command-Q on the level select** (finding 1): keep it as the OS X build seems to do, with the card saying the
   next game will not score; or drop a Command-Q there once a sector is chosen; or make it quit at once.
2. **The controller during a pause** (finding 2): leave it behaving like the keyboard, or make the paused layout
   real so held buttons do nothing on resume.
3. **A way out of start-up** (finding 4): keep the original's "nothing quits during the boot", or let Command-Q
   quit there.
4. **Gate 4 itself**, and gates 2 and 3 on the same app: only his eyes and ears prove any screen.
5. Whether findings 3, 5, 6, 7 and the narrow fault go into the fix wave that follows his gate notes (recommended:
   yes, as one small section, with the docs corrections of section 3).

## 5. Leftovers to clear

- **Phase 4's own worktrees and branches: none left.** All thirteen sections removed theirs; every `claude/` branch
  but this Review's is merged to main.
- **Other worktrees in the repo, not from this wave, left alone:**

  | Worktree | Branch | State |
  |---|---|---|
  | `zen-cohen-186522` | `claude/zen-cohen-186522` | Deimos Phase 3, on main, clean: passes the removal test |
  | `compassionate-leavitt-7ca958` | `claude/frosty-mclean-46d52e` | Ferazel run 53, on main, clean: passes |
  | `vigilant-williamson-6f3017` | `claude/gallant-brahmagupta-56ed81` | Ferazel run 52, on main, clean: passes |
  | `ferazel-run-44-7428b3` | `claude/ferazel-run-44-7428b3` | on main, one uncommitted file: fails, list for Ben |
  | `dazzling-hodgkin-f960ff` | `claude/dazzling-hodgkin-f960ff` | Ferazel, at main's head, twelve uncommitted files: likely in use, leave |

- **Sessions:** the thirteen Phase 4 section sessions and the Coordinator are idle and can be archived.
- **This Review's worktree** (`cool-lederberg-713f88`) is removed at its close; it held only this file.
