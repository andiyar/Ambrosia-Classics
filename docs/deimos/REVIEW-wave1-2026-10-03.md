# Wave 1 review — docs/deimos/ nine topical files (commit a57c0fd)

Reviewer: Fable, 2026-10-03. Method per `review.md`: raw listings (`$W/disasm-*.txt`, merged), memory images, decoded `$W/data/Game`, float32 replays in numpy. Read-only.

## Verdicts
| file | verdict |
|---|---|
| units-movement.md | ACCEPT |
| spawn-and-waves.md | ACCEPT_WITH_FIXES (minor) |
| weapons-projectiles.md | ACCEPT (label audit only) |
| damage-health-death.md | ACCEPT_WITH_FIXES (minor) |
| player-physics.md | ACCEPT |
| scoring-bonuses.md | ACCEPT |
| unit-def-struct.md | ACCEPT (label audit only) |
| bosses.md | ACCEPT_WITH_FIXES (one Important) |
| level-scroll-objects.md | ACCEPT |
| **overall** | **ACCEPT_WITH_FIXES** |

Every claim in the orchestrator's priority list re-derived from the listing/data and **confirmed**: `FUN_10015b40` executor (gates `10015bf0–10015c28`, offscreen `10015c2c–10015c6c`, issue `10015c70–10015cc4`, re-arm draws delay→volley→rate `10015d00/d14/d30`, no issue on re-arm); `FUN_10017cb0` rate→volley→delay `10017d64/d7c/dbc`; `FUN_10036cf0` candidate rules `10036e18–10036ebc`, inclusive AABB `10036ef8–10036f34`, radii `(b−t)/2` `10036f60–10036f8c`, B-side owner bug `10037064 lbz 0x32b(r3=B.state) … 10037074/100370b4 lwz …,0x140(r17=A)`; `FUN_10042f80` strict `fcmpo; rlwinm r3,r0,1,31,31` (LT); hit delay `10014f70 cmpw r28,r0; ble` (>); ram `1003425c li r3,0xa1`; player hit `10027148 blt` (≥), ×`+0x50`, death `100271cc bge`; shield bias `0x100d6fc8+8 = 1324366.0`; motion `100291f4–100292f8` (±1.6, cap 7.8, no normalisation); lives `10026838 subfic/cntlzw` (sector==1), `1002a29c cmpwi r4,1`→`+0x88`, else `+0x84` (plde 40/80); invulnerability clear `1002a214` (state 4 only); `100269a0 li r3,0x190; li r4,0x7d0`; headings `FUN_10043040`, `FUN_10042b80` (sin slot −0x6e34 = r25→r31 store `10042a64`, cos −0x6e30); cyclic two draws `10017024/10017054`; scroll `1000fb38` top=3120, `1001003c–1001004c` end at progress≥3600 (top 1), `1000fa48 subi r3,r3,0x41` load band, `100100dc/100100fc` clamp [−32,31], `10035abc` shift keyed on unit+8; weapons `1003c154 blt` (held≥15), `1003c278 ble` (+1 level every TBPLC+1), `1003c244 ble` overload (data 180 → T0+181), `1003c374` release, `1003bf14–1003bf3c` min(sector,8); scoring `10029a70 ble` (strict >), biases `0x05532A3E/0xB2CCE/0x1524DCEF`, coin step `100277ac–100277e0`, tiers `10007370–100074d0`, overshoot loop `100079e4–10007a04`, mission `10007b74/10007cc0 li r5,1`, random-bonus ladder `10016528–100167b8`; sizes `1003fca8 0x7a60`, `10040924 0x5e0`, `100417a4 0x88`, `10041118 0x5c`, `10039d40 0x108`; fatal chain `FUN_1000ced0` param_3≠0 → `FUN_10000630`; cache writer/reader by callees (`FUN_100426e0` vs `FUN_10044ce0/FUN_10048610`); bosses: `0x325/0x326` loaded only at `10040ea4/10040ed0`, float32 hits (12.0→31, 2.0→6, 2.6→7, 1.5→4, 3.9000001→10 …) reproduce. All flli/plde/wede/unde/leve values quoted in the nine files match the decoded data; all censuses (27 increment units all ground; 292 pause states/53 units; 16 passHits units; 532 sets with 144/73/218/52/78/2/16/0/0; flee 1150/5/4/3/3/1/1; 565 placements, 13 in the load band) reproduce. Cross-file offsets (unit, state, rule, spawn set, plde, handler, request) agree everywhere; no struct conflict with unit-def-struct.md.

## Findings

### Important
**I1. bosses.md §3.5 row "passHitsToOwner → projectile and ramming damage go to the owner; the turret's own shields never drop while the owner lives [HIGH]" is wrong for projectiles** (also colours §4 "bombs" narrative, §5 "turret (passHits)" and worked-example "one impact = one hit"). Listing: the B-side redirect in `FUN_10036cf0` tests and damages **A's** owner (`10037074 lwz r5,0x140(r17)`, `100370b4 lwz r3,0x140(r17)`, r17 = A). Player shots are always A (B needs `canBeHitByPlayerProjectile`; `icb `/`plbo` FALSE) and carry no owner (template `0x100ecd14` +0x20/+0x24 = 0; `FUN_1003c7a0` writes only `0x44/0x48/0x4d/0x50/0x54`), so the redirect never fires: the shot lands on the **turret's own shields** — which exist (`tapt` 3.0+0.4/sector, `pllt`/`talt`/`pptu` 3.0, `tgtu` 5.0, `betu`/`fgnt` 1.0; `nsbu` 0 → swallowed by `FUN_10014f10` step 6). Only ramming (`10034228–10034274`, tests the entity's own `+0x140`) passes to the owner. Fix: rewrite the row (ramming passes; projectile hits are absorbed by the turret, original bug — cite spawn §7 / damage §2.5); add turret shields to §4/§5 time-to-kill; damage-health-death.md §2.5 and spawn-and-waves.md §7 should state this consequence explicitly. Confidence **High**.

### Minor
**M1. damage-health-death.md §5.1** "`+0xce` … cleared in states 4/5" → state 4 only (`1002a1a8 cmpwi r0,5; bge exit`). Fix text. High.
**M2. bosses.md worked example** "`bu01` … 50, 1 coin": `destructCoin_ID none` → `100361d4–100361dc` skips per-kill coins; only the group-kill `cass`. High.
**M3. spawn-and-waves.md §1.1** level template "at `0x100eb420`" — `FUN_10033090` uses r2+0x50ec = `0x100eb41c` (bytes identical to `0x100e64b0`; level-scroll §6.3 has it right). High.
**M4. units-movement.md worked example step 2** "before update n the centre is at y = −100 + 6n": the range test precedes integration in the same update, so it is −100 + 6(n−1) unless the spawn tick itself runs an update (spawn NR 4 open); trigger tick shifts by one. Keep MED, fix wording. Med.
**M5. bosses.md §3.3/§3.4 wording**: "once per tick per on-screen entity" → per entity surviving the 128-px cull; "`FUN_10017150` holds firing" → holds rotation; "`FUN_10014f10(e, unit, player, now)`" — r4 is never read (unit reloaded `10014fb8 lwz r29,0x94(r26)`). High.
**M6. player-physics.md §1** "+0xa0 (cleared)" → it is the extra-life step increment (scoring §3.1); worked-example tick 9 prints 275.0 (float32 275.00006). Low.
**M7. Scope census.** scoring-bonuses.md: `FUN_10030570/5e0/640/790/7b0/7c0/870/910` (range 0x1002e310–0x10031400) appear only inside the "FUN_10030360–FUN_10030bc0 not re-read" line; `FUN_10030910` is 95 lines. level-scroll-objects.md: `FUN_10011bf0` (10) and `FUN_10011c00` (79, existing HIGH) have no row though the scope names 0x10011a70–0x100122f0. Add explicit "not re-read" rows. High.
**M8. Label audit (brief §2).** HIGH rows whose evidence is only "dump/read/strings": units-movement 19 (e.g. `FUN_10014670/FUN_10017e70` `+0x835/+0x836`, `FUN_100144a0` strings), weapons 19 (§1.1 loader rows "HIGH (read)", §1.2 key table "literal param_3+off" dump-only), unit-def-struct ~25 (`FUN_1003e680`, `FUN_1003ec70`, `FUN_100396c0`, cache writer/reader), level-scroll 25 (G_Level rows, `FUN_1000fec0/fee0`), player 7 (accessors), bosses 4 (`FUN_100353e0/352f0/351f0`), damage 2, spawn 1. Content spot-checked right (cache roles via callees, `FUN_1003cdb0`, accessors); relabel MED or add the listing line. Low.
**M9. Close two NOT-RESOLVED items.** scoring NR 3: `FUN_10037580` compares `'shie'` at `100375f4`→`100376ac` and `'spec'` at `1003761c`→`100376d8` (nothing) — damage §6 is right. level-scroll NR 6: `FUN_1003cdb0` `1003ce28 lwz r0,0x13c(r30); cmpw r0,r4; bge` replaces only when best.min < cand.min — weapons §1.3 is right. High.
**M10. Upgrade available.** spawn §3.2/§9 `FUN_100146f0` draw order (MED) is confirmed by the listing: `100148dc` timer → `100149f0` frame → `10014b14` scale tol → `10014d74 FUN_10033600` → `10014d90 FUN_10017510` → `10014dc0 FUN_10017cb0`. High.

## Sample table (HIGH claims re-derived)
| file | checked | confirmed | wrong | unverifiable |
|---|---|---|---|---|
| units-movement | 24 | 24 | 0 | 0 |
| spawn-and-waves | 22 | 21 | 1 (M3) | 0 |
| weapons-projectiles | 16 | 16 | 0 | 0 |
| damage-health-death | 22 | 21 | 1 (M1) | 0 |
| player-physics | 20 | 20 | 0 | 0 |
| scoring-bonuses | 16 | 16 | 0 | 0 |
| unit-def-struct | 18 | 18 | 0 | 0 |
| bosses | 15 | 13 | 2 (I1, M2) | 0 |
| level-scroll-objects | 17 | 17 | 0 | 0 |
Worked examples: all nine recomputed from the real data; numbers reproduce (player hold-up table, Flipper/Ion, tank-by-sector, scoring 300/17 000/k=14, 07s1 3 + 5-or-4 groups and 5/1296, sector-1 pause top 346/345 ticks, le01 k = 3056−Y, 03p1 struct) except the M4 wording.

## Unmentioned heavy functions (≥ 60 lines, in scope, no row)
`FUN_10030910` (95, scoring range, covered only by a range line); `FUN_10011c00` (79, level range).

## Open questions
1. Does an entity spawned inside `FUN_10033850` get its first update on the spawn tick (spawn NR 4)? Decides M4 and B's "first request on the entry tick".
2. Turret `damage_FLOAT` is 0.0 (`tapt pllt tgtu talt pptu`): a bomb overlapping turret and base takes 0 from the turret, survives, and the base is a separate victim (`B takes A.damage` is unconditional per pair) — so "one impact = one hit" (bosses MED) is doubtful; depends on group-list order of base vs child.
3. `FUN_10000630` process exit (unit-def NR 3) — chain to it confirmed, exit not.
