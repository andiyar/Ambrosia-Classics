# Handoff — 2026-10-07 — Deimos Rising Phase 2: plan reviewed, waves 2.0–2.5 done, 2.6 built (review pending)

**TL;DR.** The Phase 2 plan (`docs/plans/2026-10-07-deimos-phase2.md`) was written by an Opus planner, reviewed by two Opus
legs (`…-phase2-REVIEW.md`), and fixed. Then waves 2.0–2.5 were executed, Opus-reviewed and fixed. Wave 2.6 (C11b, C17) is
**implemented but not fully reviewed**. Branch `deimos-phase2` is pushed and **not merged**. HectorKit main **e595472** (K2:
`PCMPullSource` + ShellMixer stream voice + `SDLAudioOut(source:)`, HK D15, floor **328**). Rulings: **D31 + addendum**.
**Ben (2026-10-07): Opus 5.5 only, no Fable**; ask him about a Fable leg only if two Opus legs contradict AND find major
errors. That never happened this session.

## Done (each implemented by fk-implementer, reviewed by fk-reviewer, then one fix pass)
| task | commit(s) | notes |
|---|---|---|
| K2 (HectorKit) | eb97d9b + e595472 on HK main | two legs; AkiPad/Aki/BTX/Deimos build against it |
| C0 seams + D31 | df0ee09, c476e8f | |
| A1 effects mixer | 10c439d, 617f8c2 | sample-exact vs an independent Python model over 217k samples |
| A2 music + engine | 73a72fd, daeba54 | 0 allocations in render; decoder matches kit IMA4 on every packet |
| R4 particle stamps | 9fb0fd5, 0612f51 | |
| C13 particles/debris/blur | 11af298, 1fbff92 | |
| C16 notices/messages | 4762e77, 07a4211 | Mac Roman toupper map |
| C7 GameState/trig/world | 185a657, 0b2093a | trig tables bit-exact vs a 200-bit rebuild; per-read film scores |
| C8 spawning | 8c23f63, e0736fc | all 386 units × 2 seeds + le07 to 1700 bit-exact vs model |
| C9 motion/animation | de311e0, 2955a88 | 900/900 rows bit-exact |
| C10 state machine | a40d986, f1366d5 | executor 1200 ticks, 0 mismatches |
| C14 player | 5d493bd, 6ccd10e | de01 player physics bit-exact for 5000 ticks |
| C11a collisions/damage | 3db23c7, f906405 | |
| C15 weapons | cc90f1c, e715efb | Ion Cannon 200 ticks exact; idle at r+39 |
| C19 keys/console | 894581e, fd66d50 | pause music resumes after the wait |
| **C11b destruction/removal** | **04ce9ac** | **two review legs owed** (stopped at session end) |
| **C17 end of level** | **f22a2a0** | leg 1 MERGEABLE (tally timeline tick-exact); **leg 2 owed**; leg 1 minor: nothing calls `TallyState.reset()` (C18a), `tallyTextRequest`/notice spawn positions untested, unused flli 173 read |

The plan was amended in place after the wave-2.4/2.5 reviews (C11b, C15, C18a, C12, H2 "⚑ Amendment" lines). Read them before
briefing C12/C18a/H2.

## Next session
1. Run C11b's two Opus legs and C17's second leg against 04ce9ac / f22a2a0 (archive copies; one listing/RNG leg and one
   spec/tests/seams leg each — the briefs in this session's pattern), then one fix pass each. C11b's open question: the
   missing GameObject +0x90 "last stamp time" field (C11b treats the sweep's stamp test as always true; if any path can
   make it false, C12, which is alone in its wave, must add the field). C11b also edited C11a's `CombatTests.swift` (7
   lines) outside its fence; judge it.
2. Wave 2.7 C12 (alone) → 2.8 C18a → 2.9 C18b ∥ H2 → 2.10 H3 ∥ A3 → (F1 if G4 is red) → 2.11 A4 stage for Ben → 2.12 B1.
3. Before merging to main: the full gate (G2 all, G5 Deimos/Aki/BTX builds, G7) at the branch tip; update STATE.

## Bank corrections collected for B1 (orchestrator-run, end of phase; no implementer edits the bank)

## sound-music.md (A1, confirmed by A1 review leg 1 independent model)
- Predictor and mix clamp −32768…32767 (not ±32767) — 100d33b4, 100d3440, 100d3470.
- IMA difference = (16m+8)·step>>6 = ⌊(2m+1)·step/8⌋, not the reference shift-sum (nibble 7 @ step 7 → 13 not 11).
- Mixer position acc/prev reset to 0 at every 1024-frame block (100d32e4/ec): fraction lost; early exit on buffer full leaves `last` stale.
- FixMul/FixDiv truncate, overflow → 0xFFFFFFFF; voice-id counter starts at 1 (100d1520); divisions unsigned (divwu).
- bytes = SSND size − 8 − offset (100d2674), not COMM packets; drop k%17; nibble swap 0xF0F0/0x0F0F; ima gate also requires COMM sampleSize 16 (100d1db4).
- insertion: priority compare unsigned, gain sum signed; full list drops 16th.

## messages-notices-console.md (C16)
- §4.3: with delay>0 the notice is drawable on the tick its delay hits 0 but start reset + sound come one tick later (10018360) — dead in shipped data.
- §2.4: pass 2 j counts normal entries only (1002e134); strip blend fade+16 for messages vs notice alpha added to template value.
- §2.2: uppercase = MSL toupper; ≥0x80 behaviour MED.

## particles-debris-blur.md (C13)
- §4.4 blur 50/10: in list 6 draw passes, 5 visible (6th visibility 0.0 skipped by FUN_10012f20 ≤0 test, 10012f40..48).
- Motion-blur limit (10046ef4) posts "Reached Motion Blur Limit" type 1 — not in §4.2.
- FUN_10046d30 clears all 1000 slots (25×40) — bank cites decompile only.
- §2.9 stamp offsets +2 core / +4 fringe are relative to r6 = particle slot +4 (10043c80).

## Plan-review bank corrections (plan "Bank corrections" section, 6 items) — apply as listed there.
- (C13 review) plan C13 text "drawn on 6 updates" also wrong → 5 visible; fix plan wording at B1 too.
- (C16 review) MSL toupper uppercases Mac Roman (class table 0x100f0f94 bit 0x40, map 0x100f1194): 55 bytes change incl. 29 high bytes.
- (C16 fix) notice tick stores lastTick BEFORE the active test (stw 10018350, test 10018358).
## For C7's brief: replace ParticleSystem's private `root` copy with Trig.root (marker in ParticleSystem.swift).
## Carries for later tasks
- H2/A3: send MusicCue `.level(pref music volume)` at startup — engine starts at pref-100 level (A2 review m4).
- A2: Synchronization needs no Package.swift dependency (stdlib module).
## sound-music.md (A2)
- m starts 0x100 (0x100e072e), fade 0x100 — confirmed in data image.
- §6.3 loop: shipped tracks' SSND body = packets×68 exactly; carry vs reset identical for all 3 tracks (NOT RESOLVED #6 → no audible consequence).
## C7 (trig/world)
- trig build: sin/cos arg fl32(0x3c8efa35·i) → double → float; atan trunc(atan(0.01i)·57.2957795) truncated const → atan[100]=44, up-right heading 46; sqrt (float)sqrt((double)(float)n). All entries far from rounding edges.
- loose-ends §1.3 round-trip quirk count 34 not 30.
- pool reset free hint 0 not −1; PERM path overwrites PERM's position; headingTo same point → 270.
- FUN_100142f0 does NOT reset +0xb8, +0x100…+0x114, +0x134, +0x138 (units-movement §3 wrong about velocity copies).
- (C7 review) loose-ends-combat.md:97 30→34 quirks; units-movement.md:154 velocity copies NOT reset; loose-ends-combat §4.2 "zeroes +0xac…+0xda" too loose (see 100143c8..10014478).
- (C7 review) +0xd8,+0xd9,+0x118 sign-extended bytes; +0x134 float, +0x138 int, +0xdc float, +0xe0 int. PERM +0x9c/+0xa0 garbage until first request.
- S2 of the plan never listed +0xbd cheated — plan gap.
## C8 (spawning)
- byte at −0x611c is 1 in the data image (C7 EntityWorld doc said 0) — fix doc.
- FUN_10042bf0 unit-vector helper: x term trunc(dx)·dx (new).
- state entry at spawn reads "old state" from zeroed header (harmless); FUN_10033600 runs AFTER state entry at spawn.
- type-already-exists check counts deleted-but-unreaped members.
- C9 should reuse facing/heading→frame helpers in StateEntry.swift; FUN_10036be0 stub for C11b.
## C10
- spawn-and-waves §2.5: rotated offset uses facing + HeadingDegrees when SetHeading (10015f8c…10015fb4), not facing alone.
- C12 must call C9's rotation gate FUN_10017150 before runSpawnSets (starts 10015b6c). Rules.swift has private nearest-player copy (FUN_10005d40/FUN_10017ef0) — dedupe vs C9.
## C14
- overload flash ramps glow at +0x58, not +0x214 (+0x214 only ever 0.0).
- refused indicator spawn: original stores uninitialised stack at +0xb8; replica −1 (disclose).
- C11b must wire FUN_10034b90/FUN_10034de0 walkers in PlayerLife.swift (they call removeMemberStub) → real FUN_10036120 removal. Plan amendment needed: C11b Files += PlayerLife.swift.
- tickWeapons stub also runs Phase-1 crosshair update (1003b9ec..1003ba30) — C15 replaces.
## C9
- units-movement §5.7: right-edge bounce uses full scaled width +0x24 (10016e28), not half.
- lock/link/orbit (1003401c..54) gated on state read before the motion controller (r18 from 10033e08) → C12 passes pre-controller state into followOwner/copyFromOwner.
- random-frame draw at 10015a0c happens even when stopped flag set (if gate passes).
- no-player flee target stored (0,0).
## C11a
- FUN_10014f10 keeps old state pointer after on-hit state change (glow/sound/collision-spawn use pre-change state); FUN_10036cf0 reads counts once.
## C19 (messages-notices-console / timing-frame)
- FPS init writes 30 into frame counter too → first window shows 30+N not 31.
- console reset clears draw flag (bank says sets); unknown command not saved for recall; up-arrow keeps old bytes past end; FPS draw never sets keep-template-clip.
## C15
- weapons-projectiles.md:398 worked example 4a: release stream goes idle at r+39 (level≤0 test 1003c35c..64 precedes timing 1003c368), not r+40. Plan C15 test line also says r+40 — fix at B1.
- sector 1 select always plays wesw (gaso 0x12, 0x4b, 100, 1).
## C19 review
- plan "Unknown Command type 1, gaso 4/5" ambiguous — listing plays no sound for unknown command.
- HeldKeys.typed doc "C19 pins the codes" stale → fix (C0 file).
## Carries for C11b brief
- killPlayer must take `now` (listing passes r29 at 100271d8) — PlayerLife.swift (C11b owns deletion there; give it this too).
- C11a untestable with shipped data: m10 old state ptr (no OnHitChangeStateDelay), A-side owner redirect, snapshotted counts.
- C12: C11a exposes `collideWithPlayers(state:)`, `entityCollisionStep(_:state:now:)`.
## C17 (scoring-bonuses §6)
- tally waits `timer+N<now` → N+1 ticks; state 0 returns done; states 2/3 play moco on exit; state 6 pays on first tick (timer holds level-end time), nothing left → state 7 no wait; states 8/10 stay done; state 9 alpha 0, entering 10 alpha 32 + text "".
- C18a: call tally.reset() (FUN_10007280) at level start; level-complete stand-in ends session (no next-sector load, fade omitted).

## Machine notes
- Parallel implementers in one worktree: each tests on a `git archive HEAD` copy overlaid with its own files when siblings
  are mid-edit; explicit-path commits; own `--scratch-path` and log names (a shared `dm.log` got clobbered once).
- `grep`/`tail` can be shell functions in agent shells; use `/usr/bin/grep`. There is no `timeout` binary; use a perl alarm.
- Reviewers must run mutants in the FOREGROUND. One left a background loop that pinged for minutes.
- The AkiPad build in a worktree needs `AKI_DATA_12=<main checkout's Resources/Aki/1.2.0.app target>/Contents/Resources`.
