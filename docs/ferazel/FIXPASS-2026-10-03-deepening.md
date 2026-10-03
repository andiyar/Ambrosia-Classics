# Ferazel RE bank — fix passes for the deepening reviews (2026-10-03)

Register: code readings only; nothing behaviour-verified (meta file of the RE bank).
Reviews: `REVIEW-2026-10-03-deepening.md` (legs 1a, 1b, 1c + the synthesis ledger as appendix).
Each fix is marked in place `⚑ corrected (review 1x, 2026-10-03) #n` or `… (adjudication An/Bn)`,
with the raw addresses. Fix-1a and fix-1b edited the new files; the consolidated pass applied leg 1c,
the deferred touches to the existing files, and the bank side of every settled ledger row.

## Leg 1a (0 C / 4 I / 6 M)
- #1 dead attackers do not hurt → enemies-flyers §1.3 (fix-1a); physics §5.1 `.HurtPlayer` bullet.
- #2 water gravity unreachable on a first call → enemies-water-cave §0.1/§1.2/§2.2 (fix-1a); physics §2.
- #3/#9 save point = Box-arm landing → save-continue §2.1, pickups §2.4.8 (fix-1a).
- #4 geysers uncovered → new `geysers.md`; pickups §2.2 row + NR 4 closed; coverage, INDEX.
- #5 Bat 500/100/200, Statue no `+0x185`, Floater 1780 rect → physics §7 rows (raw cited).
- #6 PICT 700/702 captions → spells-detail §1 / pickups §1.8 (fix-1a); spells-items §2.1 note, §4 keys
  (1 Steel Key, 2 Gold Key, 3 Plat. Key).
- #7, #8 → enemies-flyers §3.4, §5.3 (fix-1a). #10 → save-continue §8.1 note (label unchanged).
- Adjudication B18 (continue re-reads the file) → engine §6, save-continue corr. row.

## Leg 1b (1 C / 3 I / 9 M)
- #1 Critical, `0x100a0718` = air animation counter → platforms §4, NR 5, corr. 9/13 (fix-1b);
  physics-sprites §8.3/§8.4 (fourth zero store `10050250`; FootPressure skipped only airborne/first landing).
- #2 2941 destructible, not a switch gate → triggers-background §1 (fix-1b); INDEX NR 22.
- #3 wall jump −3637 → player-states §5.5, player-states-2 corr. (fix-1b); physics §4 (with 1c #1).
- #4 boss music hdr+0x2724 gate → bosses §1.4, bosses-2 corr. 3 (fix-1b); engine §4.
- #5–#12 → triggers census, player-states §3.9/§5.1, bosses §1.2, triggers-2 see-saw, pointers (fix-1b).
- #11 held item / shadow / trail uncovered → new `held-item-melee.md`; coverage rows; INDEX.
- #13 0x26c8 raw → world-data-format §3.2 row (`1000b3d8`/`1000d684` → `1004b2b0`).

## Leg 1c (0 C / 4 I / 11 M)
- #1 −3637 → physics §4 wall-jump row. #8 jump-hold refill rule → physics §4.
- #2 any 300-damage player shot breaks 2941 → spells-items §4 row 0x12; pickups corr. 2; melee NR 5.
- #3 / A12 `+0x1a2` = burn row; reflected shots burn → physics §0.1; enemy-shots §3.6, NR 4, §0, corr. 7.
- #4 / B4 tail Gremlin water block dead → enemies-flyers §4.2; physics §0 `+0x11c`; Bat copy (flyers
  §3.5), Walker lag (enemies-ground §3), Platform lag (physics-sprites §8.9 mode 3).
- #5 / A8 `+0x88` light-overlay gate → physics §0.1; player-states-2 §0; triggers-2 NR 11; bosses-2
  NR 8 + §0; enemy-shots §0.
- #6 / A10 clip edges → physics §0.1; triggers-2 §6; spells-detail NR 2. #7 / A11 order → physics
  §0.1; triggers-2 §6.
- #9 `+0x185` writers → physics §0. #10 indexing → INDEX table + NR 19/21, coverage, bosses §1.5,
  bosses-2 NR 4, pickups §3.1/NR 4 (NR 15 carries #5, NR 27 #3/#4/#6/#7 — ⚑ corrected (review 1d,
  2026-10-03) #3).
- #11 / #12 → geysers §1 (1445..1448), §3 counting note. #13 → held-item-melee §1.7 (`+0x116 ≠ 0`).
- #14 → physics §5.1 (MED here + spot-check addresses); engine.md carries no such sentence.
- #15 → physics §4 drag and §5.1 Fire Charm marked "not re-derived by 1c".
- Adjudications: A2 → triggers-2 §2.2 + corr. row, enemy-shots §3.4, physics §5.1 (HIGH, raw);
  A4 → platforms §4, triggers §2.3; B16 → engine §4, bosses-2 corr. 3; B17 → engine §6, bosses-2
  corr. 4; B19 → engine §9, save-continue; B20 → world-data §4.1 + Mwld row, save-continue;
  B21/B22 → spells-items §2 items 6/7, spells-detail C5/C6; B23 → physics-sprites §8.9, platforms §2;
  B24 → physics §4 spin-gravity row (marker added by 1d #3); B25 → physics §7.

## Ledger rows settled by the synthesis pass (bank side checked)
A1, A3, A5 (`+0xcd` in enemies-ground/water-cave §0, bosses-2 NR 6, spells-detail NR 3), B1–B15:
already in the bank or carried now. Gap-file corrections applied: geysers corr. (pickups §2.2 p4
inert, §2.4.10 head HIGH, "pool" wording in enemy-shots/enemies-ground); held-item-melee corr. 1, 5
(spells-detail §3.7, player-states §8).

## Leg 1d (0 C / 0 I / 6 M + carries) — spot-review of this pass
- #1 B18 marker relabelled "review 1a adjudication 6 / B18" → engine §6, save-continue corr. row.
- #2 INDEX NOT RESOLVED intro "items 15–27" → "15–29" (items 28 geysers, 29 held-item-melee).
- #3 this record: #10 line (NR 19/21 only) and B24 line; `(adjudication B24)` added to physics §4
  spin-gravity row (it states B24's conclusion, raw `1004da90..1004dacc`).
- #4 physics §7 statue text: 1a #5 marker + raw (`1004316c`/`10043194` `+0x130 = 0x78`,
  `10043198–1004319c`, thaw `1006656c–10066574`; no `+0x185` store in either range, re-scanned).
- #5 physics-sprites §8.9 modes 3 and 4: shared gravity branch (`1006496c`/`10064974`/`10064980` →
  `10064988`, test `100649c4`) [HIGH]; platforms §2.5 pointer sentence.
- #6 bosses §1.5: `.CastSpell` 10051d1c–10052960 and `.SetupPlayerShotSprite` 1005925c–10059700
  scanned; only `100592dc sth r31,0xa6` (r31 = 0) → [HIGH] kept.
- Carries of held-item-melee corrections: 3, 4 → pickups §3.1 (#C3 rect/not mirrored [MED], #C4
  no carry HIGH for the item path); 6 → enemy-shots §2.4 (#C6); 7 → enemy-shots §2.3 (#C7); 8 → no
  bank target, the cave-wall claim is only in HM itself; HM row 8 cell corrected (#C8).
  Rows 1, 2, 5 already landed; row 9 consistent — not touched.

## Not applied
INDEX carries no label-count line, so none was added. Register line added to the three
first-review meta files.
