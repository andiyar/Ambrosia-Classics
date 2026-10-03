# Handoff — 2026-10-03 — Deimos Rising RE deepening (waves 1–2)

**TL;DR.** The Deimos gameplay code is read. Wave 1 (nine files: movement, spawn sets, weapons,
damage/death, player, scoring, unit-def structs, bosses, level/scroll) is Fable-reviewed
ACCEPT_WITH_FIXES, fix-passed and on `origin/main` (ecf565d). Wave 2 (nine files: sprite geometry,
particles/RNG, timing, HUD, messages/console, combat + session loose ends, sound, front end) is
committed on branch `claude/modest-chandrasekhar-868895` at c79d5e2 (pushed) — **its synthesis, Fable
review and fix pass were cut off by Ben's usage limit** and must be finished before it merges.
Session stopped by usage limit, not by the token cap (Ben lifted the cap in chat: "ignore cap").

## State of the bank (as of c79d5e2 on the branch)
- `docs/deimos/` now has 23 topical files. Role table after wave 1: 510 rows = 240 HIGH / 256 MED /
  14 LOW (verified by grep). Wave-2 synthesis landed on the branch after the cut-off: role table 678 rows = 392 HIGH /
  271 MED / 15 LOW (synthesis agent's count, not re-verified by the seat); INDEX #36–#55 added.
- Wave-2 critic (`/Users/andiyar/ghidra-proj-deimos/critic-wave2.md`, also to be copied into the repo
  as `docs/deimos/CRITIC-wave2-2026-10-03.md`): gameplay range 92.7 % labelled by lines, whole game
  code 84.1 %. What remains: 19 blitter pixel loops (fade blend, clipped/scaled variants), 6 static
  initialisers (one of them, `FUN_10014120`, overwrites a draw template sprite-geometry §3.1 read from
  the data image — contradiction C1, HIGH), 5 G_Text list/fade functions. Everything else unread is
  display/file/alert plumbing a native replica supplies itself.
- INDEX items closed by wave 1: #7 #17 #19 #20 #22 #24 #25 #26 #28. Claimed closed by wave 2 (pending
  review): #2 #4 #5 #8 #11 #12 #27 #29 #30 #32 #33; narrowed #6 #9 #13 #14; untouched #1 #3 #10 #31 #35.

## In flight when cut off (check before anything else)
1. **Wave-2 synthesis is committed** (branch head). Open conflicts it left for the reviewer:
   `FUN_10009750` (signed/unsigned compare), `FUN_10029c00` (command name), `FUN_10030df0` (+4 field).
2. **Wave-2 Fable review is DONE** — `docs/deimos/REVIEW-wave2-2026-10-03.md`: ACCEPT_WITH_FIXES,
   0 Critical / 1 Important / 8 Minor; 196 HIGH claims re-derived, 192 confirmed. Important: timing-frame
   §2.6/§4 "FPS monitor does nothing when the limiter is off" is wrong (count published before the
   pref-10 test). Also ~20 dump-only HIGH rows to lower, 12 sound-lib functions unmentioned,
   loose-ends-session's "signed" compares are unsigned. **Fix pass NOT run** — run it against this report exactly as wave 1 did (see `docs/deimos/FIXPASS-wave1-2026-10-03.md`
   and the review ledger in INDEX.md), plus the critic's contradictions C1–C10.
3. Then: commit, merge `origin/main`, push `HEAD:main`, remove the worktree, delete the branch.

## Evidence kit (regenerable; lives outside the repo)
`/Users/andiyar/ghidra-proj-deimos/`: `brief.md` (reader brief), `review.md` (reviewer brief),
`work/` (Ghidra project — copy before running post-scripts), `mem/` (memory image), `profile.txt`,
`callers.txt`, `sizes.txt`, `inventory.txt`, `data/` (all pak entries decoded), `disasm-*.txt`,
`review-wave1.md`, `critic-wave1.md`, `critic-wave2.md`. Recreate with `ghidra/README.md` +
`docs/deimos/tools/` if deleted. The decompile dump is `ghidra/Deimos_pef.decompiled.c` (git-ignored).

## Headline readings (all code readings; Ben's play is the oracle)
Spawn-set executor is `FUN_10015b40`, collision is `FUN_10036cf0` (circle test, same layer only,
owner copy-paste bug kept); heading = integer compass degrees 0 = up, speed px/tick; ship ±1.6/tick
to ±7.8; 30.07 logic ticks/s, one tick per frame, no speed setting exists; scroll 1 px/tick from
3120, level ends at top 1; no boss code — last controller unit pauses the scroll; power-up on 15th
held tick, overload 181 ticks later; bombs = min(sector, 8) salvo; extra life above 10,000 then
30k/40k/50k gaps; "Starting Bonus" strings never used; 16-voice mixer, 8 audible; only 10 live
console commands incl. the six "supermunki" cheats; particle bursts consume the replay RNG stream.

## Owed by Ben
- Pitch direction of the sound `pitch` key (sound-music.md NR 1) — needs his ear.
- Whether the start-of-level invulnerability carry-over (player-physics.md) matches his recall.
- Optional: a SheepShaver setup would let the ±1° atan rounding and finale ±1-tick questions be
  settled by running the original.
