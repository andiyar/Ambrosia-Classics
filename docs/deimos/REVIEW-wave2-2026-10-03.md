# Wave 2 review — docs/deimos/ nine topical files (commit c79d5e2)

Reviewer: Fable, 2026-10-03. Method per `review.md`: own project copies `$W/work-review2` (DisasmFuncs, 180 functions → `$W/disasm-review2.txt`) and `$W/work-review2b` (DisasmRange over the handler ranges → `$W/disasm-review2-range.txt`); memory images; decoded `$W/data`; resource fork (DITL/DLOG/MENU); plate scan; float32 and MSL-LCG replays. Read-only.

## Verdicts
| file | verdict |
|---|---|
| sprite-geometry-draw.md | ACCEPT (label audit only) |
| particles-debris-blur.md | ACCEPT |
| timing-frame.md | ACCEPT_WITH_FIXES (one Important sentence) |
| hud-scorebar.md | ACCEPT |
| messages-notices-console.md | ACCEPT (one Minor) |
| loose-ends-combat.md | ACCEPT (one Minor count) |
| loose-ends-session.md | ACCEPT_WITH_FIXES (minor: compare polarity ×2) |
| sound-music.md | ACCEPT_WITH_FIXES (label audit + scope census) |
| front-end.md | ACCEPT |
| **overall** | **ACCEPT_WITH_FIXES** |

Every claim on the orchestrator's priority list was re-derived from my own listing or the data bytes and **confirmed** unless listed under Findings. Timing: limiter `10030ce4 li r3,0xa … 10030cf8 li r3,0x21 … 10030d20 cmplw r3,r28; blt`, divider `10030d4c–10030d88`, present by `+4` `10030d94–10030dc4`; `+0x2c` stored only at `10030794`/`10030e4c` (0); the only 999 in both images is `cmpwi` `10030d78`; `FUN_1002d080` `1002d0a4 rlwinm. r0,r7; bne`, 64 sites, 10 with `li r7,0` (FPS, VERSION, VERS, cheat word, six cheats — names at `0x100e3cfc+…`); Esc `10030834 cmpw; ble` with calls at `100304f4` and `10030590` → 16 frames; `100097bc cmpw r4,r0; bgtlr`; all four demos have byte[0x1c+count] = 0; DITL 190 items 1–20 and the `FUN_10011590` item↔pref map (8/9/10/0x11 ↔ bytes 4/5/7/8, 0xc/0xf ↔ ints 0/1) as stated. Sprites: `10019e84–10019e98 fsubs/fmuls/fctiwz`; `1001297c lfs f1,0x84(r31)`; `0x100d6d04 = {300,256}`, `100191b0 cmpw; ble`, shipped maxima 218×110; centring `100196c0–100196dc`, `1001a7ac fnmsubs` (0.5); shadow layers `100135f0/1001374c/10013c20/10013ccc/10013d78` = 6/2/2/4/6, offsets flli 48–51 × (0.5 or 0.5·s) `10013614–10013748`, alpha `100134f8 li r3,0x14`, `100135a0 cmplwi 0x14; bge`; mode-2 `1001ddb4–1001ddd0` = dst·a>>5; frame sizes 53×43 / 38×38 / 38×45 / 18×18 and the float32 scale walk (8 ticks) reproduce. Particles: `1004378c bl 0x10046580` (`li r3,0; li r4,4`) inside `cmpw r23,r0(+0x46c); bge`; switch `10043388–10043478`; `100431f8–10043244` = table then two R(0,99); `100446d0–10044818` with 0.85/0.70/0.55; the MSL LCG from image seed 1 replays (158,467,1),(1,267,3),(75,204,0), indices **50/79**, entries 50–54 exactly; blur gate `10034340–1003435c` draws before the compare; 27 states/24 units all 0/0; drag `10043a0c` = flli 144; debris `1002a8a4–1002a8e0` inclusive, no RNG. HUD: `1000b258 stw r4,0x40` = 416, `1000b2ac` = game right 448, F60 unread; followers `0x79/0x78/0x7f/0x7e` with `FUN_10026c60(p,4)` on the rise; setters from `10027f4c/5c`, `1002a1dc`, `1002a278/88`; fill `1003243c fdivs … 10032498 fctiwz`; lives `10032058 subic.`, cap `0x8f`, red `0x2f`; `%0.7i` at `0x100eb411`; digit cache `1000d434 ble/1000d438 addi 0x30`, tesm 52–61 widths 5,6,7,7,7,6,7,7,7,7 → 6-px cell; `1000edb8 cmpwi 0x36` and 54 lines in `Formats[gate]`. Console: `1002dca0 cmpw; bge` (20), `1002de34 cmplw; ble`, delete at 32 then exit; `1002d280` (120), `1002d2bc cmplwi 0x1e`; cheat bytes → "supermunki", `100089a8 li r3,0xb; li r4,1`; limits 1/∞/3/2/1/1 on `G+0x16c…0x17c` (zeroed only `10007138–48`); TVs `0x100def84→0x100e07e0→0x100090d0`; begin frame `10030390–100303d4`. Combat: game-struct `stb …,0x39` only at `10005524/10005828/10006db4/10007248`; readers `10026f6c/1002914c/1002a1f4/100332f4` + `10006c10`; 46 units; `'spec'` `1003761c–1003762c` both arms → exit; `+0xcf` only via `10008518 li r5,1`; `FUN_10036120` has no `+0xcb` test, 7 sites; `10037c00 li r3,0x36 … bl 0x10005ed0` = ref (208,0); `1003bf14/1003bf38` = min(sector+F151−1, F152); `+0x120` only at `1003b9ec` (`li r4,1`); `+0x128`/`+0x368` unread. Session: `FUN_100214c0` `10021520 ble`, `100216a4 ble`, `100216cc blt`, shifts from the pristine copy — my simulation reproduces all four table rows; gates `10023674–10023750`; `10000730 → 100484c0 bl 0x100d4464` = `ExitToShell` glue; `10000fdc li r4,0`; fades 33/9; game over 111 ticks; no plde fly-in reader in the player/game modules. Sound: `10047dcc fdivs/10047de0 fmuls/fctiwz` both `sth`; `10047620` MinVolume; prio ≤100; insertion `100d1978 cmplw; blt / 100d1998 cmpw; blt`, refuse/evict `100d19cc–100d19f8`; `100d21f0 cmpw r26,numChannels; bge` NULL-dest; `100d16f0 cmplwi 0x100 … +0x80 >>8`; boot `10000340/10000348`; three stores to `0x100e0730`; fade=1 only at `10022e88/10047f20`; icbu 239 packets; state-sound handler `10033b64–10033c54`. Front end: `10025574 li r3,0x34 … srawi 1` (320), `y = r29 + r27·r28`; list fades 32; key tree `10023b14–10023c14` ('3'/'T' are pivots); `FUN_10025920` −0x63/−0x76; `10022110 cmplwi 0x14`; `10025d4c li r3,0x3c`; `<page 200/210/120/120>`; MENU 128 "About Deimos Rising…", MENU 2000 File ▸ Quit.

## Findings

### Important
**I1. timing-frame.md §2.6 (also §4 "Limiter off … the FPS monitor is disabled" and the `FUN_10030640` role row "if limiter on…").** Claim: "The monitor does nothing at all when the limiter is off (whole body gated by pref 10)." Listing: `10030680 cmplw r3,r0; ble exit` → `10030688 lwz r0,0x20(r30); 10030690 stw r0,0x24(r30)` (publish the count) **before** `10030694 bl 0x10004ef0(10)`; the pref-10 `beq 1003075c` skips only the clamp/deficit/auto-interlace block and lands on the window reset (`+0x20 = 0`, `+0x18 = now`). So with pref 10 off the FPS readout still updates every >60-tick window; only the deficiency logic is gated. Fix: rewrite the sentence; §4 bullet → "the deficit/auto-interlace logic is disabled; the counter still publishes". Consequence small (pref 10 cannot be cleared in a stock build). Confidence **High**.

### Minor
**M1. loose-ends-session.md §7, role row `FUN_10009750`, and §2.2 (`FUN_10021470` "signed strict").** Both functions use `xor; srawi 1; and; subf; rlwinm r3,r0,1,31,31`, which is the branchless **unsigned** `a > b` (evaluated: (0x80000000,1) → 0, (1,0x80000000) → 1); timing-frame.md §7 has it right. No practical difference for small non-negative values; fix the two words. High.
**M2. loose-ends-combat.md §4.4** "Of the 32 `bl 0x10033220` sites" — the code image has 34; the two extra (`0x10038ce4`, `0x10038ed8`) lie in the undecompiled G_EntityGroup debug-command handlers after `FUN_10038810` (unreachable, §5.2 of messages-notices-console.md). State the exclusion. High (count), Low (consequence).
**M3. Label audit (brief §2).** HIGH rows on dump/read-only evidence that carry arithmetic or structure: sprite `FUN_1001dd20`, `FUN_1001df00` (blend formulas — my listing `1001ddb4–1001ddd0`, `1001df8c–1001dfc0` confirms them: cite and keep HIGH), `FUN_1001a450/a650/a290`, `FUN_10019c00`; sound `FUN_100d1d90` (header drop + nibble swap), `FUN_10048120` (1000 ms / 600-tick guard), `FUN_100cfe64`, `FUN_100d0250`, `FUN_100d2c30`, `FUN_100d1780`, `FUN_10047330`, `FUN_10047e40`; session `FUN_10004300/100043c0`, `FUN_10009750`; hud `FUN_10032a70`, `FUN_10031ad0`, `FUN_1000d130`; timing `FUN_10010120`; particles `FUN_1002a660`; six front-end "read" role rows (trivial). Relabel MED or add the listing line. Low.
**M4. messages-notices-console.md §5.1** "`` ` `` / `~` → ignored": `1002d354 li r0,1; stb r0,-0x6140(r2)` sets `DAT_100e01f0`, which the console also sets at reset (`1002d060`) and open (`1002d1f4`) and reads/clears in the draw (`1002d434`, `1002d4d4`, `1002d4dc`) — a redraw flag by usage. Say "not appended; sets the draw flag". Low.
**M5. sound-music.md scope census.** 12 functions inside the declared `0x100cfc90–0x100d3530` have neither a row nor a "not read" mark: `FUN_100d0394`, `100d05a8`, `100d0bd8` (22 lines), `100d0c64` (21), `100d1284` (20), `100d12f8`, `100d2360` (33), `100d26d0` (29), `100d2da0` (27), `100d2e30` (37), `100d3020`, `100d3060` (27). Add a "not read" line. The other five range-scoped files are complete. High.
**M6. timing-frame.md §6 / hud-scorebar.md** "DITL 190 'Game - Preferences'": that is the resource *name* (DITL and DLOG 190 are both named so); the DLOG 190 title pstring is empty. Cosmetic. High.
**M7. Cross-file closures for the fix pass.** (a) sprite NR 4 is closed by console §5.5: `0x100e0868` is the TV of `0x10007e00` (SHADOWS), which toggles `G+0x28` = the byte `FUN_10006220` reads (`1000622c lwz r3,-0x7360(r2); lbz r3,0x28(r3)`); SHADOWS is unregistered, so the flag is 1 all session — sprite §3.2/§5.1 should say so. (b) front-end §5.1 "direction MED" is settled HIGH by session §6. (c) session §3.2's "two more easter eggs" are front-end's BIKI/FISJ. (d) front-end NR 8: MENU 128 "About Deimos Rising…", MENU 2000 File/Quit. Low.
**M8. timing-frame.md §4** "the 18 callers of `FUN_100497f0` are boot, menus, scores, credits, fades, music fade, the seed, the three controller functions" — callers.txt also has `FUN_1000d6d0`, `FUN_10023040`, `FUN_10025330` (text/progress-line timing); the conclusion (no gameplay reader) stands. Cosmetic. High.

No struct-offset conflict between the nine files, or with unit-def-struct.md / waves-and-enemies.md §2, was found (entity, state, unit, player, handler and game offsets agree everywhere). Every ⚑ conflict the nine raise against wave-1/engine-loop (Esc 16 frames; `+4` = layout; shadows on 2/4/6; 302 draws; score-bar back-buffer x; 54 tefo; `FUN_10047670` arg order; `tran` prio 75; `FUN_10017150` rotation gate; `FUN_10000fd0` non-fatal; `+0x39` writers) is correct on my re-derivation. Tick rate vs "1 px per tick" and the RNG consumer lists are mutually consistent.

## Sample table (HIGH claims re-derived)
| file | checked | confirmed | wrong | unverifiable |
|---|---|---|---|---|
| sprite-geometry-draw | 24 | 24 | 0 | 0 |
| particles-debris-blur | 18 | 18 | 0 | 0 |
| timing-frame | 27 | 26 | 1 (I1) | 0 |
| hud-scorebar | 20 | 20 | 0 | 0 |
| messages-notices-console | 23 | 23 | 0 | 0 |
| loose-ends-combat | 22 | 21 | 1 (M2, count) | 0 |
| loose-ends-session | 20 | 18 | 2 (M1) | 0 |
| sound-music | 23 | 23 | 0 | 0 |
| front-end | 19 | 19 | 0 | 0 |
Worked examples: all nine recomputed (scale walk/boxes; 20 draws in order + indices 50/79 + entries; 300 ticks and demo lengths; meter fills 60/33, score start 459, 13-tick transient; life-cheat timeline; pism 60→80; two-player table rows; icbu 239 packets, gain 115; 74-tick dead time) — numbers reproduce.

## Unmentioned heavy functions (≥ 60 lines, in scope, no row)
None. (The 12 sound-lib gaps of M5 are all ≤ 37 lines.)

## Open questions
1. `DAT_100e01f0` (M4): confirm it is the console redraw flag by reading `FUN_1002d410` `1002d434–1002d4dc`.
2. The high-score and film-end compares are unsigned (M1); irrelevant unless a score word can be ≥ 2³¹ (the +0x024A8903 bias keeps it far below).
3. `FUN_10030640` with pref 10 off (I1): only reachable by editing the prefs file; decide whether the replica models that state at all.
