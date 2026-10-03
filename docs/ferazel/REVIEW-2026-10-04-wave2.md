# Ferazel RE bank — wave 2 Fable reviews (2026-10-04)

Register: code readings only; nothing behaviour-verified (meta file). Legs A–D reported; legs E–H were cut off by the usage limit and must be re-run (see docs/handoff-2026-10-04-ferazel-wave2.md). Fix pass: owed.

---

# Review leg A (wave 2) — draw-effects.md / particles.md / conversations-mcnv.md

Verdicts: draw-effects **ACCEPT_WITH_FIXES**; particles **ACCEPT_WITH_FIXES**; conversations-mcnv **ACCEPT_WITH_FIXES** (all fixes minor; no replica-breaking error found; each commit touched only its own file).

Findings
- Important · draw-effects §2.1 row 8 — "d = s only where mask ≠ 0 [HIGH rule]" — raw is `and r9,r9,r24; add r23,r23,r9` (10026be4..bec): a word add, identity to copy needs dest = 0 under 0xff mask (lane's own NR 4/§2.5 MED). Table label must be MED. conf high.
- Important · particles §4.3 — "4-/5-bit model gives the same index except where noted" — code calls Color Manager `Color2Index` (import glue 1009f1ac), inverse-table result not derivable from the binary; my nearest-RGB rerun reproduces every sampled index (k1→1/2, k4→151, k2→76/221, k200→29/59/69, k202 on 220→194/24/198/199/106, on 214→135/24/105/106), but a naive 4-bit model differs in more cells (k200 e0x78→26, k202 a20→175). Say "model; several steps may differ". conf med.
- Minor · particles §4.4 — "e 0xeb + 10000" — b=61166 ≥ 55000, nothing added; requested RGB is (0,0,61166). conf high.
- Minor · draw-effects §1.1/§2.1 — "L = signed high byte" — writer `rlwinm 8; addis 0xc` (100147a4..b0) turns L<0 into a non-0xc mode word; negative L never reaches the 0xc blitter from this writer. conf med.
- Minor · draw-effects §2.7 — unmentioned `li r15,0xd; stb` to 0x100a39b6 at TransClip entry (10027d0c/d74). conf high.
- Minor · conversations §6.2 — "delay 2" rests on r24 = caller's r6 (10079228); caller value not shown raw. conf med.
- Minor · conversations corr #8 — cites TB "l. 418"; sentence is l. 446. conf high.
- Minor · conversations §4.3 — item 17/18 names labelled via PB §1.8 [MED]; response strings "Buy Ice Pick (500 coins)"/"Buy Escape Ring (80 coins)" make them HIGH. conf high.
- Minor · structure — NR items without "what I tried": draw-effects 3/5/6/7, particles 2–5, conversations 2–4.
- Minor · synthesis — L8 (104c48e) already struck PB §1.8 "conversations not checked"; L5 corr #4/#5 overlap it.

INDEX scorecard: 3 → closed (replica-implementable: format §2.2, targets §2.3, interpreter §3, screen §6). 15 → narrowed: draw part + burn + NewParticle args closed; colours → L1 (not reviewed). 28 → narrowed, not closed: particles closes geysers NR 1 only; NR 2–4 untouched and unstated. 29 → conversation half closed (Ice Pick/Elber; no Dirk/Hammer/spell).

Re-derivations (✓ unless marked): mode-8 add 10026bd0..c54 ✓; BurnFaceRow no stores/shape thresholds/args 100438c4..100439ec ✓; HandleBurn sound/clamp/loop/kill 10043d00..10043ed0 ✓; +0x1bc=+0x1a2 10043e64 ✓; hurt flash 0x3/0x4 100146f0..728 ✓; +0x89 overwrite 1001472c..7bc ✓; water split +0x128/0xe/+0x18c 100147c0..1001491c ✓; light gate 1001493c..9c ✓; erase 0xb/5 10014d08..1c ✓; Special jump table 0x100a3d64 + slots −0x7700/−0x76d0/−0x7710/−0x770c/−0x76c8/−0x76cc ✓; mode 0xa acc 100271f0, 10027614..30 ✓; blend row=sprite 10027fe0..054, slots a=0..5 ✓; diffuse 0x99+R(6) 10029b60..94 ✓; sine consts 100a1730/1728, 35 entries ✓(recomputed); ripple srawi 8/mulli 0x23 1002a250..278, phase +0x100 100127f0 ✓; 241 stw 0xb8 (11 r1) ✓; Walker 0x10010..15 ✓; SetupPx 0x80000/+0x88=0 ✓; player clears +0x88 100512dc ✓; NewParticle fields 10031ed0..f38 ✓; pool/row TOC 0x1024b564/0x1025af64 ✓; double decrement 10031ba8/bc8 → r27=100a019c ✓; InitParticles no counter reset ✓; tocrefs 019c/01a0/01a4 ✓; collision 1/2, age 120 ✓; shape table 100a38d4, case 4 1×2 ✓; clip 0x27e/0x19e ✓; 0.4/0.75/1.5 consts ✓; kind-1 entries ✓; BloodSpray fneg 10042738, sectors (thresholds tan −85°..−5°, FUN_100417bc 0=left/9=down/18=right/27=up ⇒ dir = arg2→arg1) ✓ all quadrants; callers 40/400|500/150/2, Blob 0xc9, Walker 50n+350 ✓; Splash/Glow/saddle/geyser/Crawler/Bat consts ✓; count gates 1000/0x5dc ✓; 16 level CLUTs → entries 0..159+255 identical ✓; cond type 3 → false 1007a154..160 ✓; jump table 0x100a6cd0 (3→a438 RemoveItem) ✓; signed-≥ idiom type 1 ✓; targets 20→999/±1 ✓; menu skips actions 1007a770..788 ✓; entry 0x13 1007a888 ✓; Mcnv 207/200/209 decoded = table; totals 8/5/4/9/8 and 9/11/8/12/5/2/1/1 exact ✓; call sites 0x96/0x5a/0x64, Xichra 0xfb/fa/fc ✓; menu keys/0xfa1/0xd6 ✓; geometry 0x183, (0x18,0x31,0x78,0x91), (0x2e,0x7e) ✓; RGB 0x5555, pstr "Ferazel" ✓; Mlvl records L1/12, L30/255, L11/283 flag 99, L4/88, L62/0, L2/228 ✓.

---

# Review leg B (wave 2) — L6 commit 22211f6

**Verdicts:** `bosses-3.md` ACCEPT_WITH_FIXES (minor only); `bosses.md` ACCEPT; `bosses-2.md` ACCEPT_WITH_FIXES (W3 row).

**Findings** (none Critical)
- Important: bosses-2 W3 / bosses-3 §8.3 — type 90 closure duplicates `triggers-background-2.md` §8.1 (another wave-2 lane, same answer, l. 183–188) and `triggers-background.md` l. 225–226 already carries a ⚑ wave 2 edit in the tree; W3's "old" column is stale → synthesis must merge, not apply. HIGH.
- Minor: §8.3 omits the capture gate `+0x130 ≥ 0` (handler l. 15324; physics §0: negative = post-launch block) — a just-fired seed cannot be re-captured at once. HIGH.
- Minor: "Proposed additions" cites `triggers-background-2 §0` — no such section; the field rows are tb-2 §6 (l. 399ff). HIGH.
- Minor: §8.2 pause-end sound is `.STPlay3DSoundRand` (bl 10047d44, rate 60535+FastRand(10000)), not stated. MED.
- Minor: §9.3 "R = B, G = 0" — entry 240 is (0xdeb0, 0x0001, 0xdeb7). LOW.
- Note: §9.3 [MED] can be raised — loader is `NewGWorld(8-bit, ctab = level CLUT)` + `DrawPicture` (main l. 28571–28593); CLUT 247 has no duplicate of any ramp colour and all 15 differ in top-5 bits → exact indices; census hit exactly 241..253. MED.
- Note: §8.5 p4-writer list is decompile-grep only (lane says MED); my grep over both dumps matches (main l. 49287/53487/60866/61805/61808); no raw scan by either.

**INDEX 19:** closed — all six sub-items replica-implementable (cannon values/rotation/launch; CLUT formula per mode; minions = tier-4 Ax goblins; vestigial fields proven unread, intent undeterminable; L55 clamp; Demon write no-op). Structure: line 3 register ✓, §8–§12 ✓, NR with "tried" ✓, 379/371/358 lines ✓, markers ✓, only 3 files ✓.

**Re-derivations (41, all ✓):** 1 0x2730..6 loads 10011850..60; 2 count=0 return 10011864; 3 0.8/0.6/0.3/1.28 @ 100a1620/18/10/08; 4 timer 100a00e8 sole user; 5 effect gate 10011968..a4; 6 loop 255−count..254 100119a8/10011c8c; 7 θ 10011a18..20; 8 w>>16 10011a74..80; 9 modes 1..7 10011a84..bec, 0.7/2.1/0.5/2.5 @ 100a1600/15f8/15f0/15e8, +7000 10011b64, ÷3, FastRand(4000); 10 clamp+SetEntries(0,255) 10011c94..ca8; 11 −sin·256² 1003d684..a8, bl sin, 256.0 @ 100a18f0; 12 callers GameLoop/PaintFrameWrap; 13 Mlvl 0x2730 words L50/51/67, 21 zero (Python); 14 L67 header 28×19, (467,620), 247/248/387/385/380, 0x26cc=0; 15 L67 recs 0..14, 400/401/500 zero; 16 no type-90 record; 17 CLUTs 247/248/200/220 values; 18 PICT 387 87,020 (14.75 %), 385 60@251, 380 0; 19 UpdateXichraCannons 14 stores 1008e264..354; 20 cannon spawns 1008df88..dfd4; 21 minions 1008ec7c..ece8; 22 slot 1009ff24 0x6d6..0x6e9; 23 Walker tier-4 arm 100676b0..e8 (HP 0x7d0, 0x10013, +0x100); 24 rotate arm 10073c7c..d0c, no type read in arm; 25 HitBg 0x442/0x44c/0x69/0x6a 10075194..752d0, bl TurnIntoCannoned 1007534c; 26 0x5a→0x15e 10058da8..db4; 27 0x5a01 spawns l. 44265/47036; 28 PlayerConstraints 1004cb54..cbb4; 29 L55 w 64, 16000/−448, recs 3/4/7/12, start 786; 30 type idiom ×3; 31 lis 0x1 10047af0/afc, 10047bc4, FixDiv/FixMul; 32 1003c86c..74; 33 Wizard 1008c940/58, 1008cabc, 1008cbf8/cc00, Setup-only +0x14c..+0x168; 34 state-11 stores complete (raw scan, 4 sites); 35 Chief 1008bfd4..c024, writers 1008b664/1008c178; 36 p2=150 ×3, Dillo bounds; 37 WarriorLayEgg ≡ DilloLayEgg, +0x154 stores only, 10086dc0 reader; 38 p2 reads 73+37=110; 39 0x2730 writer values 3/3/4/5/6/7; 40 PaintFrameWrap toggles 1009fd30 (10012710..2c); 41 Setup p1≥1 arm +0x164 = p4→9000 (l. 14103–07).

---

# Leg C — `docs/ferazel/lighting-tables.md` (90210bb): ACCEPT_WITH_FIXES

**Critical**
- §4 + NR 4 — "entries 0..0xfe only (`cmpwi 0xff; blt`)… entry 0xff never written → index 0 white" — all five water loops are `ble` (100204bc, 10020698, 10020778, 10020848, 10020a08): 0..0xff written; clut[0xff]=000000 → table 0 maps 0xff→0x60 black, not white. HIGH. (Table-4-unwritten stands.)
- §2.1 row 0xa, NR 9, proposed physics `+0xb8` row — "SpecialClipX has no case 10… undeterminable" — explicit `sVar9==10` arms: `100275d4 cmpwi r25,0xa`, acc `li r6,0x100` 100271f0, `10027614..10027630` (+q, advance dest row when ≥0x100), pixels copied raw. L2 §2.6 (vertical squash) is right; L1 must defer. HIGH.

**Important**
- §7.5 spill stated for colour 0 only; colour 99 (`li r8,0x63` 1005dea4/1005e50c/1005e5b4) with v=11 → t=110 = next D slab group 0 k0 (ambient D+1); D=15 → slab 16 = `_DAT_100a0130` start (100fbd6c+0x6e000=10169d6c), not undefined. MED-HIGH.
- §1.2 vs particles §4.3: same Color2Index uncertainty, L1 LOW/4-bit vs L3 MED/exact-nearest. Recompute: tint1@06→4c, 0xc@2a→87, 3@61→32 agree under both; water0@9e → 49 (4-bit, as L1) vs 84 (exact). Bank needs one model + one label (suggest 4-bit, LOW, both indices where they differ).

**Minor**
- NR 6/7/8/10 lack "what I tried".
- §2.1 "only stored mode without a table" falls with 0xa.

**Confirmed attacks**: D=−1→0xb ✓ (1003c328/40; 100147a4/a8; gate 10014788..98); core wrap ✓ (k=10 passed as L, decompile l.78; fctiwz→sth 1001ac24/44; white D5 → 0x7fe+19000=0x5236); gamma compounding MED honest (CloneGamma of +0x38 → start +0x44).

**Corrections 1–8**: all right; row 6 agrees with L6 W1/W2 (Mlvl L50 1,48,180,12000; L51 1,48,56,12000; L67 3,16,75,12000 re-decoded). Row 2 "no reader": single TOC load each (1001fcc8, 1001fdbc, 1002147c, 10022a44) — acceptable.

**Scorecard**: item 10 closed (after fixes); item 15-colour narrowed, not closed (index LOW; 0xa re-ruled to L2).

**Re-derivations** (✓ unless ✗): GetLightTile rlwinm/subi 1003c328/40 ✓; WrapDraw rlwinm 8/addis 0xc ✓; GetFakeLight mulli 0xb/divw/subfic, accept 0..11, radius>0x20 1001d81c..80 ✓; darken consts 1.0/10/0.0625 @100a1670/74/78 ✓; AnimateCLUT lha 0x2730..36 10011850..60, consts 0.8/0.6/0.3/1.28/0.7/2.1/0.5/2.5, `addi 0x1b58`, `li 0xfa0` ✓; water loops ✗ (ble×5); tint loops blt k1–5,8–c / ble 6,7,0x16 ✓; identity fill 100213e0..74 ✓; 0x2710/0x3e80/0x7d00/0x4000, srawi 0xb (0x4e407f29=/6700) ✓; Redden A 1001ffac, 0xff force 10020008, B 100200b4..cc ✓; Trans picker 10027d3c..df8 + stb 100a39b6 ✓; blend weights 1002a71c..7c, tables 0154/015c/0158 1002a868..74 ✓; light mulli 0x76c/898/44c/1f4/3e8/bb8/12c/4e2/9c4/5dc/7d0/fa0, group-6 ble 1001b690 ✓; compositing p−0xf5 1001db64..90 ✓; ClipX cases 1/3/4/6,9/0xc, NoClipX cmplwi 0xc jt 100a3d98 ✓; mode 0xa ✗; TOC slots (10 resolved via pef.py) ✓; sources −0x78b4/−0x79ac ✓; ChangeBlitPortClut 10034a38..4c, CopyScreenClut ✓; gamma consts 2.3/0.7, FadeCustom(0,100,·,·,3) ✓; clut 202 12 entries + 0..9f≡200 in 24 cluts ✓; Mlvl 0x2706/0x285e/0x271c/0x2722 ✓; InitLighting 2×11×0x100 ✓; MakeITable(c,0,0) ✓; GetAmbDarkVal enable ✓; +0xb8 constant census 1/8/9/0xb ✓; sel indices + FastRand(5000) ✓.

---

# Review leg D (wave 2, L7 commit 83f4554)

Verdicts: enemies-ground-2.md ACCEPT · enemies-ground.md ACCEPT · enemies-flyers.md ACCEPT_WITH_FIXES (minor) · enemies-water-cave.md ACCEPT_WITH_FIXES (minor; 608 lines, under the ~650 cap but the longest file).

Findings (no Critical, no Important):
- flyers §7.5 l.128 — activity rect = view grown 0x60 — raw also unions the player's hot rect before growing (m. l. 4304–4309); conclusion unchanged — HIGH, Minor.
- flyers §1.1 edit — children "sit ≥ 120 px outside the view" — 120 px is the centre's margin; members orbit tens of px from it (lane's own §7.5 MED); soften to "≈" — Minor.
- flyers §7.1 — "two remaining stores are globals" — misses `.DrawBlackLines 1001fb60` (stw −1 into a local struct, harmless) — Minor.
- flyers §7.1 — `.RectBounceFake2` rescales "when non-zero" — raw gates on `> 0` (`1003edf4 ble`, `1003ee3c ble`); 0 stays 0 either way — wording, Minor.
- flyers §7.5 — "no routine stores `+0x54` but `.SetupRopeSprite`" — `.HandleXichraSprite 1008eedc..1008f004` also stores `+0x54` (r31 identity not checked) — LOW confidence, Minor.
- flyers §7.4 — pipe `+0x154 = length/3+4` — two of four arms use the far edge coordinate (`+0x38/3+4`, `+0x3a/3+4`), not the height/width (h. l. 12875, 12904) — Minor.
- water-cave §7.3 — "30/45/58 cells away" — Manhattan metric, unstated; Chebyshev 23/23/36; conclusion unchanged — Minor.
- water-cave §7.4 — "r2-relative offsets masked" yet 1 diff reported; with full masking I get 0 diffs for all seven routines — wording, Minor.
- ground-2 §1.2 step 5 — Walker gravity "stores `100673dc/100684e4/10069140`" are the `li 0x151` lines; `sth` at +4 — Trivial.
- Corrections tables: 14 rows (5+6+3), 3 of them INDEX rows; every row checked against its target text — all accurate.

INDEX scorecard: 16 closed (replica-implementable: conversion block, ramp, flotation constants, permanence, Crawler cooldown table, Roach unreachability, voice-pool semantics). 17 closed (`+0x84/86` zero everywhere; Rand 60535..70534; guard never fires; `+0x1b2` full semantics; idle children HIGH code / honest MED geometry). 18 closed with §7.4 honestly UNDETERMINABLE beyond the demo.

Re-derived from raw (all ✓): 10068ad4/adc/ae8 conversion gates; 10068b38 TOC−0x7640=HandlePlatform; SetRect 10/0x35/0x42/0x47 10068b40..54; +0x1a0=−6 10068b60; 10063614 SSH; 10036994..a c `+0x120←+0x11c`; dispatch 1006361c..54→10064968; 1006496c/74/80 shared branch; ramp 10064994..c0 (<0x50, FastRand(2)==1); gravity gate 100649c4..d8; ApplyFriction 100 10064ac8; +0xa6≤0 10064ad0; +0x1f8 calls 1003cc24/68/c4; 1006a9ec IsWaterTile 200..209; HandleFlotation target surface−68, 0x15e cap, 0.86/0.93 (0x100a17f8/f0), |vy|<0x46 snap; Crawler 100659e0/10065a10/10065f34..5c/10065e98/10065fd8/10066068/100660c8; Roach 1007794c/1007798c, dispatch 10077b1c..40, 10077d70 sole state-3 writer; FUN_100916dc 100916dc..744; 10004da4/db0/db4/dc0; tocrefs 1009fe8c = 18 (16 Setups); pipe 1006ec9c/eca8/ecdc/f040/f048..60; MTCollide 10032744 outer-only, 1003276c, 1003285c..70; WrapDraw 1001452c/38; Rand 10047d60/d80/d90; Pitched no srawi, 0x80 centre, L+R<0x14; STPlay3DSound srawi 10047b3c/b48; all 23 Setup `+0x84/86` stores li 0; InitSprite 1003d494/9c; r26=*TOC−0x732c (1004af10), r30=*TOC−0x7880 (10052ad4); Bat 1007ea14..48; guard 1007f348 TOC−0x77c4=PICT 151 (m. l. 115, 73868ff.); face indices ≤10/≤9/≤8 vs sets 11/12/9; Hit idioms 1007f5c4, 10080df0, 100835ac; nine crush writes; +0x150 readers only Crawler/Roach/other-sprite 1006687c/10082b00 (0x5a0 gate); Salamander 10082fec/10083538, no Handle access; GetBGTile W/H/map hdr+0xb280/82/8c, (col,row); ConstrainXY; Crab 10089594..ac; AddIdleSprite r8 untouched 10007d8c..e08; idle rect −0x18/0x278/0x198 ± 0x60; TurnIntoStatue +0x5c=HitBoxSprite, type unchanged; HitBoxSprite 0xc12..0xc1b/0xb74; demo path exists, PEF 2000-03-21 12:57 vs 2000-03-13 12:41, vers 2 = 1.0.3, seven routines 471/283/329/120/157/96/103 words, 0 masked diffs; census: six level-21 pipes (types/p1/p2 match), level 62 360×60, 102 water cells rows 20..49, crabs (238,51)/(253,51)/(267,50) kind −1, swapped 495. Commit touched only the four owned files; markers 7/7/7; line-3 register line matches siblings.

---

