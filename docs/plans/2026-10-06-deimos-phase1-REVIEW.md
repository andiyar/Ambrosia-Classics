# Fable review — Deimos design + Phase 1 plan (2026-10-06)

Reviewer: Claude Fable 5.1, read-only. Documents: `docs/plans/2026-10-06-deimos-design.md`,
`docs/plans/2026-10-06-deimos-phase1.md` (branch `deimos-phase1`, worktree admiring-liskov, de01eb1).
Oracles used: the bank (`docs/deimos/`), the raw listing `ghidra/deimos-proj/disasm-review3-all.txt`, the memory
images, the decoded data under `ghidra/deimos-proj/data/Game/`, the committed paks (Python zipfile/TGA probes), HectorKit
main at review time, and float32 probes (numpy) for RNG / alpha tables.

## Verdict: **ACCEPT_WITH_FIXES**

Counts: **0 Critical · 4 Important · 9 Minor**; **61 claims checked PASS** (list at the end). Every number a test
will pin that I could reach checks out except the float-RandomRange triple (I3); all three "Bank corrections" are
confirmed against the listing; the frame order and the level-start order match the listing; nothing the gate needs
is missing or mis-scoped. The fixes are bookkeeping that would otherwise trip STOP rules on day one (K1, D-number,
floor) plus one transcription omission in the init op list and one wrong test value.

---

## Important

**I1 — K1 is already on HectorKit main; the plan's K1 is stale and its gate numbers would STOP the first task.**
Plan lines 30, 38–39, 52, 65, 249–264, 512, 594–597. HectorKit main (`~/Developer/HectorKit`, `git log -1`) is now
`522feb8 HectorShell: ShellView.scalingPolicy on macOS (.aspectFit default, .integerFit); floor 316`, on
`origin/main` (`git merge-base --is-ancestor` → yes), decision **HectorKit D13** (not D12 — D12 is PICT.decodePixels),
`tools/check-zero-skip.sh` `FLOOR=316`. `Sources/HectorShell/ShellView.swift` has `public var scalingPolicy:
ShellScalingPolicy = .aspectFit { didSet { relayout() } }` and `relayout()` calls `ShellScaling.layout(policy:…)`;
`ShellWindowController.init(title:logicalWidth:logicalHeight:styleMask:scalingPolicy: = .aspectFit)` sets it on the
view. The `HectorKit-worktrees/deimos-k1` worktree is at the same commit. (`ShellScalingPolicy`, `ShellScaling.layout(policy:)`
and `ShellScaling.integerFit` pre-date it — D7.) *Fix:* mark K1 **DONE (HK 522feb8, D13, floor 316)**; G1 expected line →
`executed 316 == floor 316`; delete "301 + K1's 3"; plan line 38 → `HK main 522feb8, FLOOR 316`; self-audit 2 "K1 3 → 304" →
"K1 landed, 316"; A1's precondition "needs K1 on HK main" is satisfied. Verify the three K1 test numbers are covered by the
landed tests (`Tests/HectorShellTests/ShellViewScalingPolicyTests.swift` or equivalent) rather than re-adding them.

**I2 — D28 is taken: Phase 1's ruling must be D29.** Plan lines 102, 266, 273–276, 284. `origin/main:docs/DECISIONS.md`
already has `## D28 — Cythera build: Ben's brainstorm rulings …` (line 627; also present in this worktree's DECISIONS). Landmine
(d) anticipates it, but C1's commit message, test file and the self-audit all say D28. *Fix:* renumber to **D29** now (and re-check
on `main` at C1 commit — Ferazel sessions are active).

**I3 — C2 `testFloatRange` pins values that only hold with a fresh `srand(1)` before each call.** Plan line 297. As written
("after `srand(1)`: `range(1.0, 2.0)` = 1.5138707; `range(2.0, 1.0)` = 0.48612934; `range(0.8, 1.2)` = 1.0055482") a sequential test
fails on values 2 and 3. Probe (float32, bank engine-loop §9 formula `min + (hi−lo)·rand/32767.0f`, draws 16838, 5758, 10113):
sequential = **1.5138707, 0.8242744, 0.9234535**; the plan's 0.48612934 = `1 + (−1)·16838/32767` and 1.0055482 =
`0.8 + 0.4·16838/32767`, i.e. each after its own `srand(1)`. *Fix:* either state "each after a fresh `srand(1)`" or pin the
sequential triple. (The `range(1.5, 1.5)` no-draw clause and `testIntRange` 1446 / 5-no-draw are right.)

**I4 — The init op list omits the level-start black fill of the back buffer, and the LOCKED `RenderOp` has no case for it.**
Plan lines 169–180 (S3), 405–408 (C6 init), 420 (`testInitOps` "the exact op list"). Listing `FUN_100064d0`
`100068f4 bl 0x10033220` (notice spawn) → `100068fc lwz r5,-0x73c0(r2); 10006900 lwz r3,0x68(r29); … 1000690c bl 0x10009f00`
= `FUN_10009f00(D+0x68, colour)` with the slot `0x100def70 → 0x100d630c` = `{0, 0}` (memory image) — **fill the back buffer
black** — then `10006918 FUN_10031ad0(0)` → `10006928 FUN_10031400` → `10006934 FUN_10031ad0(1)` → the pref-5 dance → `10006974
FUN_10010120` (first terrain draw) → `10006980 FUN_1000c2a0` (make window current). function-roles.md row `FUN_10009f00` = "fill with
RGBColor (PaintRect portRect)" HIGH. No pixel difference in Phase 1 (buffers are born black, R1), but `testInitOps` pins the exact
list, the seam is LOCKED after Phase 1, and Phase 3's level transitions (fade-out → next level start) depend on this fill.
*Fix:* add `case fill(BufferID, colour: UInt16)` to `RenderOp` (S3, C1), emit `.fill(.back, 0)` in `DeimosSession.init` between the
(absent) notice spawn and the score-bar level-start ops, apply it in R3 `DeimosRenderer.apply`, and list it in `testInitOps`.

## Minor

**M1 — Esc pass semantics.** Plan line 410 ("quit → `sessionEnded`, no further ops"). `FUN_100064c0` (`100064c0..100064cc`) only
stores `game+0x08 = 0`; the Esc pass still runs its tick, draw world and end frame (present) — the `while` exits on the next
iteration (`100058f8..10005aa4`). One frame; invisible in Phase 1 (H1 restarts at once). Either transcribe it (pass completes, then
`sessionEnded`) or disclose the deviation in the `pass` doc comment.

**M2 — R1 pins the `FUN_1001ec80` kernel (fade to black / `COST`) before R2's precondition reads it.** Plan lines 437–439,
443, 448–449. The routine is MED in the bank (function-roles row: "body not listing-read"); fade-to-black is never exercised in
Phase 1. Move `Fades.toBlack` + `testFadeToBlackCompounds` to R2 (after the reading) or mark the R1 test provisional, re-derived by
R2's reviewer. (Fade from black and `Blend555` are HIGH and fine.)

**M3 — Level-start interlace dance not mentioned.** `1000693c..10006970`: if byte pref 5 is set at level start, `game+0xf = 1` and
pref 5 is cleared; restored at appear time (`10005990..100059b0`). Moot with fresh prefs (pref 5 = 0) — note it in C6's doc comment
so Phase 2 (prefs file) does not miss it. Likewise `FUN_100189f0` (clear layer lists) is called at level start (`10006824`) — a no-op
at init, worth one line.

**M4 — `DrawCommand` field comment is garbled** (line 162): `// centre (+0x0c/+0x10, +0x04/+0x08)` — x/y are **+0x04/+0x08**, face/frame
**+0x0c/+0x10** (sprite-geometry-draw §3.1).

**M5 — Stale HectorKit facts in K1's file list** (line 252: "fix its stale 'floor 300'") — HK `docs/STATE.md` already says 313/316.
Moot once I1 is applied.

**M6 — Design §3 puts the Phase-2 PCM mixer in `DeimosRender` ("every pixel and every PCM sample").** Layering-legal under D6
(Foundation + HectorAudio), but a "Render" library owning audio is a naming trap for the Windows shell session; consider a
`DeimosAudio` target in the Phase 2 plan (no change now).

**M7 — Design §2 / plan Hazards say no decompile exists, but hud-scorebar.md's header cites `ghidra/Deimos_pef.decompiled.c` and several
bank sections quote "the dump".** Not the plan's error; worth a one-line caveat that dump-derived bank lines are the ones to re-read in
the listing when they matter (the plan already does this for its preconditions).

**M8 — Pre-seed RNG draw.** engine-loop §3's skeleton shows `FUN_10046580(400, 2000)` at session start **before** `srand` (the
unregistered cut-off). Irrelevant to the post-seed sequence and to Phase 1, but Invariant 6 / design §9.4 should name it so a Phase-2
replay implementer does not "fix" the order.

**M9 — Gate card item 6** says the crosshair's layer/shadow "are read in this phase (C5)". Fine; add that the crosshair's own
visibility fade is 0 → 100 at 6/tick from the first active tick (loose-ends-combat §6.2, verified at `1003b148..1003b15c`), so Ben
knows a ~0.6 s fade-in is expected, not a pop.

---

## Checked and PASS (61)

**Listing-verified (this review):**
1. Bank correction 1: `FUN_10012750` `10012750..10012838` — cur > req: −δ, floor 0.0 (double slot `r2−0x7248`), then raise to req;
   cur < req: +δ, cap req; cur == req: nothing; same for +0x58/+0x5c/+0x60. Matches C4's contract exactly.
2. Bank correction 2: `FUN_10007070` `1000708c…10007108` = `FUN_100345f0` → `FUN_10046ae0` → `FUN_100298c0` ×2 → `FUN_10007d60` →
   `FUN_100184b0` → (`FUN_10031ad0(0)` iff `game+0x38 == 0`) → `FUN_10031ae0` → (`FUN_10031ad0(1)`).
3. Bank correction 3: `FUN_1000ba70` — snapshot + black clone, `t0 = TickCount` (`1000bac4`), for a = 0, 4, …, 32 (`1000bb70/74/7c`):
   blend `FUN_1001e9d0(snapshot, black, back, bounds, a)`, present `bc60`/`bd80` by mode, spin until `TickCount ≥ t0+1`
   (`1000bb50..1000bb64`), `t0 = TickCount` (`1000bb68/78`). 9 steps. H1's fade rule is this.
4. Loop body `100058f8..10005aa4`: begin frame → quit → tick flag → appear check (`game+0x38 == 0 && gameTime == flli 18`) → music →
   `FUN_1000ba70(…,1)` → update world → `FUN_10007170` → gameTime++ → draw world → end frame. C6's order and `testFadeAtTick2` hold.
5. Level start `FUN_100064d0` call order (all `bl`s listed): … `FUN_1002b3a0` → music → `FUN_100269a0` per player → lists reset →
   `FUN_1000fa90` (map load inside) → groups → spawns → notice → [black fill, I4] → score bar bracketed 0/1 → first terrain draw.
6. `FUN_100269a0` draw at `10026a9c li r3,0x190; li r4,0x7d0; bl 0x10046580`, after the three flli 163–165 stores.
7. State-2 compare `1002a1b4..1002a1e4`: `cmpw now, enter + plde+0xb8; ble` → respawn when `now > enter + 55`; else
   `FUN_10031710(index, 0.0)`.
8. Crosshair reset `1003b148..1003b15c`: `+0xf4 = 0.0`, `+0xf8 = 100.0`, `+0xfc = handler+0x124` (= flli 149 = 6).
9. `FUN_1003bd00` = `if (handler+0x120) FUN_10012f20(handler+0x8c)`.
10. `FUN_100100b0`: step ±1, clamp −32 / 31, last-step global (0 when clamped).
11. `FUN_10031400`: image → back (`10031488`) before image → save (`100314c4`); C5's two `loadImage`s are in that order.
12. `FUN_100064c0` = `stb 0, 0x8(game)` (M1).

**Data-verified (decoded paks / `ghidra/deimos-proj/data`):**
13. flli: 18 = 2, 33 = 2, 54 = 416, 55 = 480, 59 = 32, 166 = 1, 183 = 13, 149/150 = 6/6, 163–165 = 0/100/2, 185–187 = 3/−4/80,
    112/113 = 534/41, 116/117 = 495/124, 121 = 3, 127 = 4, 128/129 = 467/199, 140/141 = 16/6, 142 = 0.7, 143 = 9 (220 items).
14. tefo gate order 41 sbsh, 42 sbpm, 43 sbs1, 44 sbs2, 45 sbl1, 46 sbl2, 47 sll1, 48 sll2; sbs1 (494, 83) CENT mono spacing 4
    colourise 94dee6; sbs2 (494, 318); sbl1 (499, 50) spacing 0; sbl2 (498, 285); sll1/sll2 ff0000; sbsh/sbpm strip blend 8, 000000.
15. le07: Mariner Valley / Lucena / `jum2` / `jup2` / `mu03` / `jut2` / rect <0,0,480,3600>, 38 objects, 11 unit ids, max yLoc 2978 < 3056.
16. wede PEAA: aiic 1–3 (`pl1o`/`pl2o`, `wesy` 0), aibg 2–9999 (1), airg 3–9999 (3), aipb 5–9999 (2); plbo crosshair `pbta` 0 / locked 1,
    offset (0, −121). Sector-1 icon slots 1–2 = `none` follows.
17. `jum2` 480×3600, TGA type 2 bottom-up (desc 0x01): (32, 3120) = 0x1040, (447, 3599) = 0x22C4, (0, 0) = 0x314A; `jut2` 96×720;
    `scor` 160×480 (0, 0) = 0x0021.
18. `icns 128` = 63,938 B, 20 elements incl. `it32`/`t8mk`.
19. Level order le07 le06 le02 le08 le11 le04 le12 le03 le05 le01 le10 le09 (engine-loop §6).
20. Prefs defaults byte 2/4/5/6/7/8/9/10 = 0/1/0/0/0/0/0/1, int 0–3 = 50/100/50/1, 14-code key table; high-score defaults
    15000…1000, names Mars…Electrofryer, "New Atlantis".
21. Glyph map 'A' 0, 'a' 26, '1' 52, '0' 61, '(' '[' '{' 69, space/≥0x80 → 90; tesm widths 52–61 = 5 6 7 7 7 7 6 7 7 7 → cell 6.
22. `PlayerInput` bit order = film byte (left 0, right 1, up 2, down 3, fireGround 4, fireAir 5, select 6) — engine-loop §7.
23. Phase 0 baseline = 104 `func test` (G2 ladder base).

**Arithmetic re-derived (probes):**
24. MSL rand: seed 1 → 16838, 5758, 10113; seed 0x469c2 → 26662, 28174, 2951; `R(400, 2000)` = 1446; float `(1, 2)` = 1.5138707.
25. Visibility → alpha: 100→0, 50→16, 6→30, 2→31, 1→31, 96→1, 97→0, 150→16, 0→32 (float32).
26. Mode-2 α tables a = 20 (p 1…19) and a = 0 (p 1…31) — exact match with single-rounded `fmadds`.
27. Blend 0x7FFF @ a 16 with 0 = 0x3DEF; 0x94dee6 → 0x4B7C → 0xFF94DEE7 ((c<<3)|(c>>2), PICT.swift rule).
28. Shadow centre (184, 382); scaled 26×21 at (170, 371); ship rect 182..234 × 309..351; crosshair (208, 209), ch = 6.
29. Text starts 459 (glyph lefts 463 + 10i), 496, 495; dim blend 0 → 16.
30. Timing: state 4 at t 56; appear 2·(t−55), opaque 105, +0xc5 cleared 105; crosshair 6 at 56 → 100 at 72; shield follower
    2·(t−55), full 105; banking 1,2,3,3 at 56,58,60,62, right 2,1,0,4,5,6,6, left-from-4 → 3; pan −32 after 32 held ticks
    (pass 231 from 200); frame 3 from pass 204 (even-tick parity from 56).
31. Scroll: window (3120, 32, 3600, 448), progress 481, top 3120−k, end on k 3119 (top 1, progress 3600), pass t blits 3119−t
    then 1; terrain src (top, off+32, top+480, off+448) → dst (0,0,480,416); R3 oracle row 2919 at pass 200.
32. Esc: pref 8 = 0 → first pass; pref 8 = 1 → 16th held pass (counts 1,2|…|31). Limiter `≥ lastPresent + 2`, stamp after.
33. `MacTicks` 60.15: 1 s → 60, 10 s → 601, 100 s → 6015; 60: 10 s → 600.
34. K1 geometry: 640×480 in 3024×1964 → k 4 (232, 22, 2560, 1920); 1280×960 → k 2 whole view; aspect fit (202, 0, 2619, 1964).
35. Ladder 104 + 6+6+6+8+9+7 + 8+10+7 + 6 = 177; canonical merge totals 110/116/122/130/139/146/154/164/171/177.

**Bank-consistent (read against the cited sections):**
36. `FUN_10006b50` order players → score bar → scroll step (engine-loop §3); 37. end-frame order flush 0–1 → terrain → 2–5 →
particles → 6–15 → limiter → present (timing-frame §2.3); 38. begin frame clears the 16 layer lists; tick flag always 1 (divider 0);
39. presents: game screen (borders (0,0,480,32)/(0,608,480,640), game area → (0,32,480,448), bar from back → (0,448,480,608)),
game layout (0..607 → 32..639), full 1:1 (display-window-present §5); 40. `FUN_10009fd0` rect defaults (dst → src bounds),
double CopyBits, interlace parity (§2.1); 41. buffers born black; 42. runtime draw template clip {0,0,480,416}, layer 7, 0x7fff,
drawNow 0; HUD template `0x100eb228`; 43. layers `play` 10 / shadow 6 / stamps 1, flush bands; 44. shadow (−24, +52), scale 0.5·s,
alpha max(20, α(v)); 45. sprite flags |1 + alpha when v ≠ 100; tint/hit passes; 46. `FUN_10012f20` gates (v ≤ 0 nothing; shadow if
+0x38; sprite if +0x37; SHADOWS always 1); 47. player draw order crosshair → shadow → sprite, state 4 only (micro-wave §3.9);
48. dispatcher mode priority 1 > 2 > 4, port by flag 8, inside/reject/clipped with strict `X+w < clipR`, scaled path selection by
clip == {0,0,480,416}, scaled clamps [0,416)×[0,480), sampling `(w·(dx−left)) div w′`; 49. per-mode pixel rules incl. mode 0
ignoring alpha and 1000 row markers; 50. score-bar state: six dirty flags, +0x12e/+0x12f, followers −3/+2 (rise in state 4) and
−4/+2 + 1/100 clamp, handler +0x08 stays 1 → icons every tick; 51. level-start score bar: all dirty, displayed 0, icons, dim P2 once;
52. elements: `%0.7i`, `play` 0/1 at F112–115, lives `max(n−1,0)` cap 9, red when active and 0, icons blend 6/16 scale 0.7,
meters + COST `fill = fctiwz(v/100·w)` blend 8; 53. dirty-rect screen blit = local rect + (0, 448), only when `DAT_100e01ff`;
54. text layout: W = Σ(spacing + width), CENT `fctiwz(X − 0.5W)`, cell = x + spacing, glyph centred (cell + w/2, Y + h/2), space 4
never drawn, colourise → flags 4 + colour, +0x10c/+0x10d/+0x110 meanings, strip always queued; 55. `Player.setup`: lives 3 at
sector 1 else 1, shield 100, state 2/1, solo = index 0; 56. `levelStart`: state 2 at now, (208, 330) solo / (104|312, 330), appear
(0, 100, 2), one draw per in-game player; 57. `FUN_10028170` order and the state-4-only block; input copied in state 4 only;
58. view shift driven by input, left wins, per active player; 59. crosshair flag set every handler tick, never cleared; adj 0 in
Phase 1; 60. seam/type names used consistently C1 → A1; file ownership disjoint (lane A `Sources/DeimosCore/**`, lane B
`Package.swift` + `Sources/DeimosRender/**`; H1 after R3); `project.yml` S7 merges into existing `packages/targets/schemes`
with the Aki/BTX bundle-id pattern; 61. design layering vs HectorKit D6 / Classics D12: Core Foundation + HectorResources/HectorAudio,
Render Foundation + Core, Host Foundation-only, AppKit only in `Deimos/App`; `ShellBitmap` is 0xAARRGGBB row 0 top; `ShellIdleTimer`,
`pollKeyState()` exist.

**Gate scope (question 3):** scrolling map (C3/C6/R1/R3), ship in place with shadow + crosshair (C4/C5/R2/R3), HUD/score bar
(C4/C5/R3), original frame order (C6), integer scale (K1 done / A1), staged app + card (A2) — all present; the excluded items
(level-name notice, `plen`, multiplier unit, music) are entities/audio, correctly Phase 2 and disclosed on the card. Nothing in the
plan contradicts the bank; the one transcription gap is I4.
