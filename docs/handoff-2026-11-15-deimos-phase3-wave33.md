# Handoff — 2026-11-15 — Deimos Rising: Phase 3 wave 3.3 closed (the twelve-sector sweep, the app's two launch arguments); next = wave 3.4 (the phase cross-check, staging, the gate-3 card, the late bank notes)

Wave 3.3 is complete: CS and AP are both merged to local main. Nothing of wave 3.3 remains. Every build task of
Phase 3 is done; what is left is task ST and Ben's gate 3.

## Brief for the next session

Everything below this brief is the record. The live state is `docs/STATE.md` (the Deimos block).

```
You are the ORCHESTRATOR for Deimos Rising (Ambrosia Classics), Phase 3 (the campaign), wave 3.4: task ST — the
seat's cross-check of the whole phase, then stage the app, write the gate-3 card, and add the late notes to the
research bank. It ends at Ben's gate 3. Repo "/Users/andiyar/Developer/Ambrosia-Classics". Method
~/Developer/Toolkits/fable-kit/orchestrator.md (§0, §2 loop incl. step 6 the cross-check, §3a under a Coordinator,
§5 cap, §6 model policy). Say which model you are in your first message, echo the mission in one sentence, say
what you do first, start. If a Coordinator session started you, its overrides win over this brief (it names your
handoff file and starts any next session; you do neither on your own; questions for Ben go to it).

AUTHORITY: docs/superpowers/plans/2026-11-14-deimos-phase3.md on main (D50), 301 lines — read the gates table
(lines 24–51), the rulings (53–70), "Corrections to the appendices" (72–89), and the ST card with the gate-3 card
(242–289). From docs/superpowers/plans/2026-11-05-deimos-remainder.md read only the gates code block (lines 54–78:
the commands) and the A4 card (grep -n "### A4"), which is how Phase 2 was staged.

READ FIRST: CLAUDE.md; docs/STATE.md (grep -n -i deimos); this brief; the plan sections above; the three
"As built — Phase 3" entries in docs/DECISIONS.md (grep -n "As built — Phase 3": LT; CR/TP/FN; CS/AP) — they carry
every fact the card and the bank notes need. Read `Deimos/WHAT-TO-EXPECT.md` (the Phase 2 card you are extending)
and `tools/stage-deimos.sh` before staging.

WHERE: your own session worktree, cut from LOCAL main (confirm `git merge-base --is-ancestor <main tip> HEAD`; if
behind, `git merge --ff-only main` in the worktree). An edit hook refuses writes to the main checkout: edit in your
worktree, merge with `git -C /Users/andiyar/Developer/Ambrosia-Classics merge --no-ff <branch>`, then
`git merge --ff-only main` in the worktree. Never push.

THE WORK, in this order:
 1. THE CROSS-CHECK (yours, the Fable seat's; the only Fable review of the phase — method §2 step 6). The whole
    phase's diff is `git diff 611347d..main -- Deimos` (611347d is the commit before LT;
    check: the parent of the first LT commit 6d4bee9); six tasks: LT, CR, TP, FN, CS, AP. Re-run the gates from
    the merge head yourself, check the work against the plan and the plan against the data, and read the two
    things no per-task review could see: how the pieces fit (the transition + the driver's cue split + the restart
    at the launch's sector + the two arguments), and whether the gate-3 card's eleven lines are each true of the
    code as merged. Findings that need code go to one fk-implementer fix round with two fk-reviewer legs, under
    the owning task's Files; findings that need Ben go on the card.
 2. THE BANK NOTES (seat-run, one commit `docs(deimos): Phase 3 bank corrections (<n> notes)`), in
    `docs/deimos/*.md` + `INDEX.md`:
    - `level-scroll-objects.md` §8: the six disagreements of appendix A §2 (the appendix's table is the reference).
    - `loose-ends-session.md` §5.3: appendix B §2c; and the finale sound ticks as CORRECTED (plan correction 1:
      `acbo` at T0 and T0+7 … T0+85, `leen` at T0+103 — never the uncorrected "T0 … T0+84").
    - INDEX #64 closed (the `12gc` explosion set has no delay — pinned by a test).
    - "3055 − Y holds for the first level only".
    - The listing lives at ~/Developer/Ghidra/deimos/proj/disasm-review3-all.txt, not under ghidra/deimos-proj/.
    - From the wave 3.2 as-built entry: items (2), (4), (5) (the explosion pass's 200 draws, the iris releases at
      flag + 19, the session-end ticks, the coin tally's final state, the score-bar copies, the view clamp, the
      mission bonus and the extra-life mark).
    - From the wave 3.3 as-built entry: sector 11's five pauses and their lengths; an overloaded weapon destroys
      even an invulnerable ship (addresses in the entry); sector 12's end fight ends on the controller's timer and
      the Beamer's death is only an early exit — this CORRECTS the wave 3.2 entry, which said the Beamer must die.
 3. THE CARD: `Deimos/WHAT-TO-EXPECT.md`, in Ben's plain English, per the ST card's Contract and the gate-3 card in
    the plan (you may tighten wording, not content), with these changes that wave 3.3 found:
    - Card line 10 and ruling 3 say a new game after the finale starts at sector 1. As built, a restart returns to
      the sector the game was LAUNCHED at (ruling 1 governs): sector 1 unless `-sector N` was given. Say that.
    - Add: holding fire too long overloads the weapon and destroys the ship, even in the two seconds of
      invulnerability — the original's rule, confirmed from its code; if Ben's memory differs he should say so.
    - Add under "not proved by the machine": no test wins sector 12's end fight by destroying the Beamer; the
      sweep outlasts it on a timer, which the data allows. Does Ben remember the level ending with the Beamer
      still alive?
    - The machine results to quote: four demo films replay to the original's scores; the sweep played every
      sector to its end and one whole campaign to the finale (128,469 game steps, about 71 minutes of play at 30 a
      second) — with an invulnerable ship and a scripted pilot, so it shows nothing gets stuck, not that it feels
      right. Sector 11 is the longest level (about 9½ minutes).
    - A bad `-players` / `-sector` value shows an alert and quits, like a bad `-film` tag.
    - The Phase 2 card's lines still apply (Ben has not yet ruled on Phase 2): keep them, and say so.
 4. STAGE: `tools/stage-deimos.sh` → `out/Deimos/` and the Desktop, as Phase 2 was (the A4 card). NOTE: this
    replaces `~/Desktop/Deimos Rising.app`, the Phase 2 build Ben has not yet judged. The Phase 3 build contains
    all of Phase 2, so one app serves both gates — say so at the top of the card. Staging builds; it does not
    launch.
 5. GATES at the merge head: G1 HectorKit zero-skip (370 executed at ef2c341: 366 passed + 4 Aki 1.1 skips —
    record, never fix here); G2 372 / 0; G3 census unchanged; G4 4 / 0 and four PASS lines; G5 three builds;
    G7 empty; G8 3 / 0; G10 clean tree.
 6. G9, THE BOOT CHECK, IS A HARD STOP: it opens a window and makes sound. Only on Ben's say-so, muted, by day
    (09:00–21:00). Ask through the Coordinator; do everything else first; if no answer comes, close with the
    check named as the one thing owed and the app staged un-launched.
 Commit for the stage: `Deimos: Phase 3 staged — WHAT-TO-EXPECT (gate 3 card)`. Then STOP for Ben's gate 3.

GATES, as measured by the wave 3.3 seat on 2026-11-15 at main ce77f57 (HectorKit ef2c341, clean):
 G2 `swift test --skip DeimosReplayTests --skip DeimosCampaignTests`: 372 / 0.
 G4 `--filter DeimosReplayTests` 4 / 0; `swift run deimos-replay --all` four PASS lines, exit 0. A change is a STOP.
 G8 the campaign bundle 3 / 0 — it takes about 13 minutes (per-sector 454 s, campaign 259 s, two-player 26 s),
    longer than one 10-minute tool call: run `--filter DeimosCampaignTests.CampaignSweepTests/testEverySectorReachesItsEnd`
    alone, then the other two together.
 G5 Deimos (Debug and Release), Aki, BubbleTroubleX all build. `xcodebuild … | tail -n 1` prints an empty line on
    this Mac: save the log and grep for `BUILD SUCCEEDED`.
 G7 layering grep empty. G1 was not re-run this wave (the kit is unchanged at ef2c341).
 Every swift command needs HECTORKIT_PATH=/Users/andiyar/Developer/HectorKit in a worktree. Count `^Test Case`
 lines; swift test prints no total. Use /usr/bin/grep and /usr/bin/tail.

BINDING RULES (each has bitten on this repo):
 - Every subagent is fk-implementer / fk-reviewer with NO `model` param. The bank notes, the card's content and the
   cross-check are the seat's own work; an implementer may draft the card from your notes, with two review legs.
 - Cap: 300k of your own context unless Ben sets another figure IN YOUR SESSION. Read `get_usage` before each
   dispatch and at the close and say the figure. Wave 3.3 stood at 166k before its first dispatch and 216k after
   both tasks (about 8k per dispatch: short reports, one shared brief file in the scratchpad).
 - Background runs are OFF in this repo (.claude/settings.json, 2026-11-15): a Bash call is cut off at its
   timeout (default 2 minutes) — pass a 600000 ms timeout for builds and test runs, and keep each under 10 minutes.
   Subagents run in the foreground: you wait for each one.
 - Machine load: at most four heavy processes in total; count with
   `pgrep -x "swift-test|swift-build|xcodebuild" | wc -l`. Tell every agent: one heavy process each, foreground.
 - An unexpected number is a STOP, never an edited expectation; a disagreement between game code and listing is a
   STOP with the address.
 - Never push. Never git stash / reset / switch branches; never git add -A; explicit paths; trailer on commits.
 - No app launches except G9 as above.
 - Never patch HectorKit, Cythera, Ferazel, Aki or Bubble Trouble. Other sessions write docs/STATE.md, docs/NEXT.md
   and docs/DECISIONS.md on main: edit only Deimos's block and entries, never NEXT.md; merge main in before you
   edit them. STATE: replace the Deimos block, move what is settled to the top of docs/STATE-history.md.
 - Messages to Ben in plain English: what happened before part names; numbers in a short table. Game steps
   convert to seconds at 30 a second.

IF BEN'S PHASE 2 VERDICT HAS ARRIVED (STATE, DECISIONS, or a message): read it first; his notes become a fix wave
before staging, under the Phase 2 cards' Files.

CLOSE: STATE (the Deimos block: Phase 3 staged, gate 3 waiting), a DECISIONS as-built entry under "As built —
Phase 3" for ST and the cross-check, the handoff the Coordinator names, your worktree removed. After gate 3 the
next work is Phase 4 (the front end: menu, high scores, level select, prefs on disk, the controls window) — it has
cards in the remainder plan but no plan of its own yet; do not start it.
```

## Record (2026-11-15; Fable 5.2 in the seat, Opus 5.5 implementers and reviewers)

**What happened.** Two tasks, one after the other, each with one implementer, two reviewers and one fix round.

1. **The sweep.** A new, separate set of three long tests plays the game by machine: every one of the twelve
   sectors from a direct start, twice (once doing nothing, once with a scripted pilot that steers and fires), with
   the ship made invulnerable; one whole campaign from sector 1 to the end of the finale; and a two-player start
   through the first level change. Every sector reaches its end and hands over to the next; nothing spawns that
   its level's data does not name; the finale's timings measured in wave 3.2 hold when it is reached by really
   playing through sector 12. No game rule needed changing.
2. **The launch arguments.** The app now accepts `-players 2` and `-sector N` (1 to 12), standing in for the
   original's menu until Phase 4. A bad value shows an alert and quits before any window or sound. A restart
   (Esc, game over, the end of the campaign) goes back to the sector and player count the game was launched with.

**What the work found.**
- Sector 11 is much longer than the plan guessed: about 17,200 game steps (9½ minutes) against a limit of 16,000.
  Nothing was stuck — the level has five long holds, each as long as the original's data says. The seat raised
  the limit to 20,000.
- Holding fire too long destroys the ship even while it is invulnerable. Two reviewers confirmed from the
  original's code that this is the original's rule, so the scripted pilot lets go of the button now and then.
- Sector 12's last fight ends on a timer; destroying the Beamer only ends it sooner. The earlier handoff had this
  the wrong way round. In the sweep the Beamer is still alive when the finale begins.

| Check | Before wave 3.3 | After |
|---|---|---|
| Deimos core tests | 372 / 0 / 0 | 372 / 0 / 0 |
| Demo-film replay tests | 4 / 0 | 4 / 0; four PASS lines |
| Campaign sweep tests | — | 3 / 0 (about 13 minutes) |
| App builds | last run after the level transition | Deimos Debug + Release, Aki, Bubble Trouble X all succeed |
| Deliberate bugs tried by reviewers | — | 18; 4 slipped past the first drafts; 0 after the fix rounds |

**Not independently confirmed.** Nothing has been launched; the app on the Desktop is still the Phase 2 build. The
launch arguments were checked by reading, building and a scratch copy of the parser, not by starting the app. The
sweep shows nothing gets stuck with an invulnerable ship; it says nothing about how sectors 5–12 feel. No test wins
sector 12's end fight by destroying the Beamer. The fix rounds were checked by their own implementers re-running
the reviewers' bugs, not by a third reviewer. The whole-phase cross-check has not been done: it opens wave 3.4.

**The seat's context:** 166k before the first dispatch, 216k with both tasks merged, of a 300k cap.

**Waiting on Ben (unchanged):** the muted boot check of the staged app, and his "level 1 plays" verdict.
