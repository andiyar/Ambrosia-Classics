# Handoff — Aki Phase 2, tasks P2.1–P2.4 (AkiCore model, deal, clock) — 2026-10-04

Fable 5.1 orchestrator (seat), Opus implementers + Opus reviewers (one leg each, spec then quality),
house method `~/Developer/Toolkits/fable-kit/orchestrator.md` over `superpowers:subagent-driven-development`.
Plan: `docs/plans/2026-10-03-aki-phases-1-3.md` P2.1–P2.4. Previous session (cut short): `docs/STATE.md` item 1 at d73e398.

## What landed (all on `main`)

| task | commit | AkiCore M1 | review |
|---|---|---|---|
| hygiene: path-named defaults suite for the store test | 0e25b6f | 31 / 0 | (prior session) |
| P2.1 — 12 layouts generated from `levels-layouts.md` + face multiset | e36de83 | 44 / 0 | MERGEABLE, 3 Minor |
| P2.2 — `Tile`, `Board`, visibility, open test, match, hit box | d029b7d | 53 / 0 | MERGEABLE, 4 Minor |
| P2.3 — deal/reshuffle by rejection sampling, `_CountOpenPairs` formula | bbffd38 | 59 / 0 | MERGEABLE, 4 Minor |
| P2.4 — `GameClock` (150 s limit, 300 s cap, tables, freeze/thaw, bar) | 6d86638 | 67 / 0 | MERGEABLE, 5 Minor |

Gates from the merge head, run by the seat: M1 **67 / 0** (zero skips, 0 `aki-*` plists), M2 `** BUILD SUCCEEDED **`,
M3 HectorKit `PASS … executed 167 == floor 167` (read-only; HectorKit is Ben's other session's).

## Rulings this session (seat, under invariant 1 — recorded in the plan text, not DECISIONS)
- **P2.2 `testCounts`: 22 → 25.** The plan's "remove two open tiles + recompute → 22" was no-recompute arithmetic.
  Removing the z 5 tiles at x2 10 and 14 of row y2 16 on fresh Layout 1 frees the neighbour at x2 12 and uncovers the
  two z 4 tiles beneath: 24 − 2 + 1 + 2 = 25. Derived by the seat, confirmed independently by the P2.2 reviewer's own
  script over the markdown tables; plan line corrected with a ⚑ note. The implementer stopped on invariant 17 — correct.
- **Reviewer exports need the data env vars.** A `git archive` export has no `Resources/Aki/*` symlinks, so the ten
  data-gated census/nib tests skip unless `AKI_DATA_11` / `AKI_DATA_12` point at the originals' `Contents/Resources`.
  The P2.1 reviewer caught this; `review-task.md` now sets both. Future review briefs must too.
- **Session-hook conflict (for Ben).** A PreToolUse hook refuses the Write/Edit tools outside the session's own worktree.
  The chip resumed the lane in `friendly-almeida-c02139` while the session ran in `affectionate-franklin-5569c5`; the P2.2
  and P2.3 implementers wrote there through Bash (the mode's file path), the P2.4 implementer refused to and was right
  to. The seat moved the lane into the session's worktree (merge fae9ec8) and finished there. **Chips should spawn the
  session IN the lane worktree, or say "continue on a fresh branch from origin/main".**

## What review caught (carried, not fixed — all Minor, all within "may settle alone")
- P2.1: Swift test parser doesn't close a section on a later `## ` heading (Python does); Python tuple regex skips a
  malformed tuple where Swift throws; a redundant first-mismatch block in `LayoutTests.check`.
- P2.2: no test asserts a removed tile still gets `isVisible` written; "every other field to 0" doc comment (the original
  never writes `face` in `_AddTile`); C 16-bit wraps in the season test / pixel casts not mirrored (unreachable).
- P2.3: the no-hint/no-selected assertion after a fresh deal cannot fail (flags start false); `reuse: false` ignoring
  current faces only indirectly tested; "unreproducible" doc wording (true of the original, not of a seeded replica);
  `deal` loops forever on a 0/1-open board — faithful (rules §5, §8 step 7).
- P2.4: 32-bit C wrap of the bar arithmetic not mirrored (differs only after ~22 h); `init` zeroes `frozenRemaining` where the original never resets bc (plan-stated, no effect); two statics lack an address in their doc comment; thaw test freezes before the start tick (arithmetic still valid); the no-more-pairs test never asserts `remaining` unchanged.
- HectorKit build warning `ContainerBackend.swift:20` (`backends` not concurrency-safe) — Ben's HectorKit session's.

## Machine lessons
- `aki-settings-test-<UUID>.plist` reappears if ANY checkout older than 0e25b6f runs `swift test` (cfprefsd flushes the
  empty plist ~1 min after exit). It did once this session from a pre-merge run; deleted. Always count after a wait.
- Two implementers never commit to the same worktree concurrently; reviewer (export) + implementer in parallel is fine.
- `=foo` in zsh is a command lookup: never `echo ====` as a separator in Bash tool calls.

## Next (chip spawned): P2.5–P2.8
P2.5 and P2.6 are ⚑ MAJOR (the `AkiGame` state machine mirrors `_SelectCGTile`, `_RedrawMatchedTiles`,
`_ShowNextCGHint`, `_ReshuffleCustomTiles`, `_UndoLastCGMove`, `_PauseGame`, `_CustomGameScreen`): two review legs each.
Then P2.7 (stats, levels 13–17), P2.8 (`AkiGameArt` rects). Totals 67 → … → 107 after P2.8. Then P2.9–P2.12 and
the P2.12 gate: Ben plays a level start to finish on each difficulty — "it plays like Aki". Ben's eyes only.
