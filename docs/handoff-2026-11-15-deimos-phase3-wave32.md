# Handoff — 2026-11-15 — Deimos Rising: Phase 3 wave 3.2 closed (carry-over, two players, the finale); next = wave 3.3 (the sweep, then the app's two launch arguments)

Wave 3.2 is complete: CR, TP and FN are all merged to local main. Nothing of wave 3.2 remains.

## Brief for the next session

Everything below this brief is the record. The live state is `docs/STATE.md` (the Deimos block).

```
You are the ORCHESTRATOR for Deimos Rising (Ambrosia Classics), Phase 3 (the campaign), wave 3.3: task CS (the
campaign sweep), then task AP (the app's two launch arguments). Do not begin ST (staging) — it has its own session.
Repo "/Users/andiyar/Developer/Ambrosia-Classics". Method ~/Developer/Toolkits/fable-kit/orchestrator.md (§0, §2
loop, §3a under a Coordinator, §5 cap, §6 model policy). Say which model you are in your first message, echo the
mission in one sentence, say what you do first, start. If a Coordinator session started you, its overrides win
over this brief (it names your handoff file and starts the next session; you do neither on your own).

AUTHORITY: docs/superpowers/plans/2026-11-14-deimos-phase3.md on main (D50) — read it whole (300 lines): the gates
table, the rulings, "Corrections to the appendices" (it WINS over the appendices), the CS and AP cards. Its
grounding appendix B (same folder, `…-grounding-B.md`) §4 is the sweep's design and §5 the app; hand those sections
to agents, read them yourself only where a ruling needs it. From docs/superpowers/plans/2026-11-05-deimos-remainder.md
read only "Standing rules for every implementer" and the gates code block above it.

READ FIRST: CLAUDE.md; docs/STATE.md (grep -n -i deimos); this brief; the plan; the two "As built — Phase 3"
entries in docs/DECISIONS.md (grep -n "As built — Phase 3").

WHERE: your own session worktree, cut from LOCAL main (confirm `git merge-base --is-ancestor <main tip> HEAD`; if
behind, `git merge --ff-only main` in the worktree). An edit hook refuses writes to the main checkout: edit in your
worktree, merge with `git -C /Users/andiyar/Developer/Ambrosia-Classics merge --no-ff <branch>` at each task close,
then `git merge --ff-only main` in the worktree, and re-run the gates at the merge head. Never push.

TASKS (per task: one fk-implementer, then TWO fk-reviewer legs — spec, then quality, the second told what the first
found — then ONE fix-round implementer for what they list; CS before AP, never in parallel):
 CS -> Deimos/Core stays 372/0 (G2); the new bundle DeimosCampaignTests is 3/0 (G8); films 4/0 (G4).
       It changes Package.swift, a locked seam file (TickTrace.swift, additively), DeimosHost, three film-lookup
       users, and one existing CSV-header test (count unchanged). An unreached level end or a spawn outside a
       level's closure is a FINDING to report with the trace, never a relaxed assertion: you rule or ask.
 AP -> no new tests; G2 372/0; Deimos builds Debug and Release (G5). It also changes the driver's restart (today
       always sector 1, DeimosDriver.swift near line 231) to restart at the launch's sector, and re-specifies the
       existing restart tests (same names, same count). No launch.

GATES, as measured on 2026-11-15 at main 5c2876f (after FN):
 G1 HectorKit zero-skip at ef2c341: 370 executed (366 passed + 4 Aki 1.1 skips — record, never fix here).
 G2 Deimos/Core `--skip DeimosReplayTests --skip DeimosCampaignTests`: 372 / 0.
 G4 `--filter DeimosReplayTests` 4 / 0, and `swift run deimos-replay --all` four PASS lines, exit 0 — any change is
    a STOP.  G8 (from CS) `--filter DeimosCampaignTests` 3 / 0.
 G3 census body unchanged; G5 Deimos, Aki, BubbleTroubleX build (CS touches Package.swift and AP the app, so run
    all three at the wave's end; wave 3.2 added test files only and did not re-run them); G7 layering grep empty
    (incl. deimos-replay); G10 clean tree; G11 every test loop names a bound and fails on it.
 Every swift command needs HECTORKIT_PATH=/Users/andiyar/Developer/HectorKit in a worktree (the package's relative
 path to the kit resolves only from the main checkout). Count `^Test Case` lines; swift test prints no total.

WHAT WAVE 3.2 LEFT FOR CS TO KNOW:
 - The finale tests (FinaleTests.swift) reach the finale by placing the scroll 250 rows from sector 12's end. That
   skips the end fight: unit 12e1 (row 377) holds the scroll until the Beamer be02 (row 335) is destroyed, and
   three fl02 (rows 204, 208, 436) never spawn. So NO test yet reaches the finale the way a player does.
   CS's `testCampaignOneToTwelve` and the sector-12 case of `testEverySectorReachesItsEnd` are that check: tell the
   implementer the scripted pilot must actually destroy the Beamer, and that a scroll that never resumes is the
   likeliest finding. Sector 12's final pause alone is about 2,750–2,905 ticks (appendix B §4).
 - Finale ticks relative to the "all levels" notice (T0), pinned by tests and available to CS's campaign run as a
   cross-check: fifteen `acbo` at T0 and T0+7 … T0+85; `leen` T0+103; `12gc` T0+90, deleted T0+955; tally from
   T0+1201; with no money and 0 % accuracy the session ends at T0+1476; with twelve perfect levels at T0+1567.
 - Test helpers for crossing a real level end, god mode, two-player set-up and replaying a random-number snapshot
   are duplicated (LevelTransitionTests, CarryResetTests, TwoPlayerTests and FinaleTests each carry their own).
   CS's bundle is a separate target with its own data locator, so it writes its own; do not move the others.
 - A session copy is a plain value copy (the level set and a sprite cache are the only shared references, both
   read-only): copying a session mid-run to branch a variant is sound and cheap.
 - The listing is at ~/Developer/Ghidra/deimos/proj/disasm-review3-all.txt (outside the repo, read-only), NOT under
   ghidra/deimos-proj/ as the remainder plan says; the decompile is ghidra/deimos/Deimos_pef.decompiled.c in the repo.
 - Tidy-ups still open from LT (fold into CS only if cheap and inside its Files): `levelStart` and `LevelSet` could
   move to their own file; `fadeToBlackCues` would sit better with the cue buffer (a locked file).

HOW THE REVIEWS WENT IN WAVE 3.2 (so you brief for it): first-draft tests passed both legs every time, but about
a third of the reviewers' deliberate source bugs slipped past them — assertions on values that would be right
anyway, values copied from the result being checked, ranges where an exact replay was owed. Put these in the
implementer's prompt up front: poke a non-default value first; compare against a control copy that does not take
the path; pin literals verified against the data, not produced by the code under test; replay random draws exactly;
a search over a pass's ops must fail, not trap, on a short list; prove each test red with a SOURCE mutant in a
private `cp -R` copy. Reviewers: private copy, own scratch path, at least one mutant per test, name the survivors,
and end with a "For the fix round" list.

BINDING RULES (each has bitten on this repo):
 - Every subagent is fk-implementer / fk-reviewer with NO `model` param.
 - Cap: 300k of your own context unless Ben sets another figure IN YOUR SESSION — and if he does, work up to it.
   Read `get_usage` before each dispatch and at the close and say the figure. Wave 3.2 cost the seat about 135k
   before its first dispatch and about 25k per task after that (short reports, shared brief files in the scratchpad).
 - Machine load: at most four heavy processes in total; count with
   `pgrep -x "swift-test|swift-build|xcodebuild" | wc -l` (never `pgrep -fl`). Other sessions (Ferazel, Cythera)
   are usually running two or three. Tell every agent it is a hard rule: one heavy process each, foreground.
 - Tell every agent: fix rounds strengthen existing tests and keep the count; an unexpected number is a STOP, never
   an edited expectation; a disagreement between game code and listing is a STOP with the address.
 - Never push. Never git stash / reset / switch branches; never git add -A; explicit paths; trailer on commits.
 - No app launches. ST's boot check opens a window and sound: Ben's say-so only (muted, daytime).
 - Never patch HectorKit, Cythera, Ferazel, Aki or Bubble Trouble. Other sessions write docs/STATE.md,
   docs/NEXT.md and docs/DECISIONS.md on main: edit only Deimos's block and entries, never NEXT.md; merge main in
   before you edit them.
 - Research data and dumps are read-only; ST's bank notes are seat-run.
 - Messages to Ben in plain English: what happened before part names; numbers in a short table. Pass counts
   convert to seconds at 30 a second.

IF BEN'S PHASE 2 VERDICT HAS ARRIVED (STATE, DECISIONS, or a message): read it first; his notes become a fix wave
before CS, under the Phase 2 cards' Files.

CLOSE: STATE (the Deimos block), a DECISIONS as-built entry under "As built — Phase 3", a handoff built the same
way for ST (stage, the gate-3 card, the late bank notes — the plan's ST card lists them; add to its bank notes the
listing-path correction and the facts in the wave 3.2 as-built entry), your worktree removed. Hard stops: a
question only Ben can answer; ST's boot check; his gates.
```

## Record (2026-11-15; Fable 5.2 in the seat, Opus 5.5 implementers and reviewers)

**What happened.** Three proof tasks, one at a time. Each wrote the tests its plan card names against the
original's listing; in all three the game already did what the original does, so no game code changed. Each then
went to two reviewers, who tried deliberate bugs in the game code to see whether the new tests would notice, and
one fix round tightened the tests where they did not.

1. **What a player keeps and loses between levels** (8 tests). Lives, score, the next-extra-life mark and the
   multiplier carry; coins, shield, power-ups and the per-level counters reset; sectors 2, 3 and 5 force their
   weapon and the others keep the last one selected; the two-second invulnerability carries in from the level end;
   a player who is out stays out; a player caught dying at the change is revived without losing the life.
2. **Two players** (7 tests). The shared view slides twice as fast when both steer the same way and not at all
   when they oppose; respawn positions; one out plays on, both out is game over; the second player's panel, lives
   count and icons; the mission bonus pays both.
3. **The finale** (5 tests). The whole timeline from the "all levels" notice on sector 12's real data, the session
   end after the tallies, the mission bonus with twelve perfect levels and without, and the hospital penalty. The
   plan's guess that the finale's sounds fall one tick later than the early research said was confirmed three
   times over from the listing.

| Check | Before wave 3.2 | After |
|---|---|---|
| Deimos core tests | 352 / 0 / 0 | 372 / 0 / 0 |
| Demo-film replay tests | 4 / 0 | 4 / 0; the replay tool prints four PASS lines |
| Deliberate bugs tried by reviewers | — | 71; 22 slipped past the first drafts; 2 after the fix rounds |
| Game source files changed | — | none |

The two that still slip past: the range within which an iris reacts (the test run's geometry cannot show it), and
"level complete looks only at player 2", which the carry-over tests catch rather than the two-player ones.

**Not independently confirmed.** Nothing has been launched; the staged app on the Desktop predates the level
transition. No test reaches the finale through sector 12's real end fight (the sweep, next, does). The three app
builds were not re-run this wave (only test files changed). The fix rounds were checked by their own implementers
re-running the reviewers' bugs, not by a third reviewer.

**Waiting on Ben (unchanged):** the muted boot check of the staged Phase 2 app, and his "level 1 plays" verdict.
