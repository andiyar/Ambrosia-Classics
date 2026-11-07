STATUS: CONTINUE

# NEXT — Ferazel's Wand, run 47: level 5's moving sky, then level 5 itself

You are the seat for **Ferazel's Wand** in Ambrosia Classics, repo `/Users/andiyar/Developer/Ambrosia-Classics`
(`$REPO`). Method: `~/Developer/Toolkits/fable-kit/orchestrator.md`. You run this one wave, close it, and start the next
session. In your first message say which model you are and, in one sentence, what you will do first; then start.

**Authority:** `docs/superpowers/plans/2026-11-04-ferazel-remainder.md` — the one plan. This wave's cards are under its
heading "Wave 3 — run 47: OX → LV5": `#### OX` and `#### LV5`. Read also its "0. The verification model", "Invariants
and hazards" and "Shared architecture for the remaining waves". Nothing else is a plan.

## Read first
1. `CLAUDE.md` (repo root).
2. `docs/STATE.md` — the Ferazel block: the live state (counts, HectorKit SHA, goldens, open carries). This chip holds
   no state.
3. `docs/QUESTIONS.md`, section "Open", only for what waits on Ben — act first on any new text under an `Answer:` and
   record it in `docs/DECISIONS.md`.
4. The plan's headings named above.
5. The research notes the two cards mirror, by heading: `docs/ferazel/rendering-omnipx-titles.md` "3. OmniPx" (§3.1–§3.5)
   and "1. The backdrop compositor"; `docs/ferazel/bosses.md` "1. Shared boss framework" (§1.1–§1.4);
   `docs/ferazel/world-data-format.md` "3.2 Header field table".

## Reconcile first
- `git -C "$REPO" worktree list`, `git -C "$REPO" log --oneline -8 main`: main must be at or past run 46's close
  (c8d9cf5) and this chip's rebuild. Run 46 merged PI and PT; its worktrees `ferazel-run-44-7428b3` and
  `ferazel-run-45-f94cf1` are finished — remove them if clean.
- G1 HectorKit per the plan's gate table (follow kit main; a new SHA and its zero-skip count go into STATE and LOOP-LOG).
- G2 once at the head: **607** total = 605 passed + the 2 opt-in skips by name, 0 failed (479 + 128). Any other number:
  STOP, reconcile, record.

## Before OX — the Fable cross-check wave 5.4 never had (Ben's FYI, 2026-11-08)
Runs 44–46 (the Blobs, Crabs, Gremlins, Wraiths, Dillo, geysers, pipes and renderer traps) were reviewed under the older
rule: one Opus leg per task, no Fable pass over the wave. Open run 47 with one `fk-reviewer` dispatched with `model: "fable"`,
named "Fable cross-check, wave 5.4" in its brief, read-only, foreground: the whole diff `1c08a32..c8d9cf5` (run 43's
close to run 46's close), each class against its research note by heading, the gate numbers above, the 18 trap decisions
in PT's "As executed" note. Findings become ONE tests-only fix round (Opus implementer + one Opus leg), merged before OX
begins; a finding that needs a behaviour change is a ruling for the seat and is recorded in DECISIONS. Record the pass in
LOOP-LOG and the Phase 5 "As built" paragraph.

## This wave's tasks (full cards in the plan)
| task | what it must do | Core after |
|---|---|---|
| **OX** ⚑ MAJOR | OmniPx modes 2/4/5 — level 5's moving backdrop: a new `DrawOp.omniPx` emitted only while OmniPx is on (levels 1–4 unchanged, no golden moves), the counter + 1 per active face and carried across levels, 16-bit face wrap, `.TurnOnOmniPx` zeroes Core's header factors; modes 1/3/6/7/≥ 8 stay refused at level open; the audit's `omniPxMode == 0` assert narrows to {0, 2, 4, 5}; 5 tests | 612 |
| **LV5** ⚑ MAJOR | level 5 enterable: `BuiltLevels` `1...5` with the "(Phase 6)" report, the arena lock at x 1384 with the 40-frame camera pan and the camera bounds, the gate shut while the Warrior lives, the boss-music rule at both sites reading `noBossAlive` live (level 5 plays track 23 throughout), the Warrior's full Setup with a standing ◇ Handle, every range-pinned test retargeted and re-derived; 6 tests; closes wave 5.5 | 618 |

OX first (LV5 needs its backdrop for level 5's first frame). Each task: one implementer, then two Opus review legs (spec,
then quality with a mutation table, the second told what the first found), a tests-only fix round, a re-review if the
fix round was large. Brief each leg with the card, the dump / source line range and the test names; do not read source
yourself before a dispatch (a grep that a symbol exists is enough).

## Gates (commands are in the plan's "Machine gates"; numbers as of 2026-11-08)
| gate | expected |
|---|---|
| at the head (run 46's close) | G2 607 · GW2 81 · G3 1,108 / 0 · Proof B 604 / 0 / 3 / 0 (of 607) · HectorKit ef2c341, zero-skip 370 |
| G2 Core, two commands, skips by name | OX **612**, LV5 **618**; 0 failed; exactly the two opt-in names |
| GW2 WinKit | **81**; 0 failed; exactly the two Windows opt-in names |
| G1, G5, G6, G7, G8, G10, GW1, GW3, GW4, GW-symlinks, G-MUTE, G7W | as the plan's table (G5 is named for OX) |
| wave 5.5 end, at LV5 (a level task) | G3 `0` / `Totals: items 1,108 decoded, failures 0`; the full GE on levels 1–5 `both` (visit sweep + bot exit 0); GWB by day after the LAUNCH GUARD **615 / 0 / 3 / 0 (of 618)**; GW4R by day |
| ◈ | neither task is ◈: any moved golden or `BootFacesTests` pin on levels 1–4 is a STOP; level-5 pins are new |

## Binding rules (these have bitten on this project)
- Launch a build only **muted** (Mac `-FerazelMute YES`; CrossOver via the scripts), few and short, and **never 21:00–09:00**
  — run the LAUNCH GUARD first; by night skip and write "boot check owed (night rule)". Headless tests run any hour.
- Game data and dumps are read-only: never edit `Resources/Ferazel/` or `ghidra/ferazel/`.
- Subagents: `fk-implementer` / `fk-reviewer`, **no `model` parameter** (Opus 5.5); foreground. The Fable cross-check
  runs once per completed chunk (each closed wave, each phase plan, each phase end), never per task; this run's is above.
- Memory: never two heavy suites at once (Core, WinKit, sweep, bot); at most 4 test workers; one seat gate run in a
  `git archive` copy beside one working implementer, or two review legs alone. Each review leg builds in its own
  `mktemp` copy.
- Never wait silently (the watchdog kills a session after 45 quiet minutes): background long gates, poll with `stat -L`.
- Cap 300k of your own context: read the meter (`get_usage`) before each dispatch and at the close; at ~240k finish the
  task in flight and close.
- Never edit a golden or an expectation to make a number agree — STOP, reconcile, record. Dump beats bank beats plan.
- Explicit-path commits, no `git stash`, `git branch --show-current` before each commit. The unattended loop never
  pushes; an attended session pushes main at its close (CLAUDE.md).

## Close (in this order)
1. Merge each green task to local main `--ff-only` by SHA.
2. An "As executed" note under each card in the plan; the Phase 5 decision entry's "As built" paragraph in
   `docs/DECISIONS.md`; the bank corrections the tasks found, appended to the named bank file.
3. `docs/STATE.md`: replace the Ferazel block with today's state only (counts, HectorKit SHA, goldens, open carries,
   what is next); anything settled goes to the top of `docs/STATE-history.md`. One line in `docs/LOOP-LOG.md`. A short
   handoff `docs/handoff-<date>-ferazel-run47.md`. One memory note + index line.
4. Rebuild this file from nothing for run 48 from the plan's next item: **A5 + the Fable cross-check** (the Phase 5 end:
   GE both shells, the relabel sweep, both builds staged, the gate card to QUESTIONS, STOP for Ben's gate — the run after
   is the planning run, which does not wait for him). Same shape: no copy of STATE, the one plan named, a few KB.
5. Push main, then start the next attended session (`start_session`, fresh context, brief "read docs/NEXT.md and run
   it") — unless a question only Ben can answer blocks the next step: then `STATUS: BLOCKED`, the item in QUESTIONS with
   `Blocks: everything`, no new session, and name that question in your closing message.
