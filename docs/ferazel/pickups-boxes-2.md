# Ferazel's Wand 1.0.3 — pickups and boxes, part 2 (wave 2 loose ends; decoration rows)

Code readings only; nothing behaviour-verified. Date 2026-10-04.
Sources: `ghidra/Ferazel_pef.disasm.txt` (raw addresses for every HIGH), the main and handler dumps (orientation), `tools/const.py` / `tocrefs.py` / `pef.py`, `snd ` and `PICT` resources of `Ferazel's Wand Sounds.rsrc` / `Sprites.rsrc` (own PICT v2 decoder for the faces), `Mcnv` and `Mlvl` of `Ferazel's Wand World Data.rsrc` (placement census over all 24 levels, world-data §3.4 layout).
Continues `pickups-boxes.md` (§1–§3 there); NOT-RESOLVED rows 1–9 of that file are closed or narrowed
here. Labels per INDEX.md. `pN` = placement param N; `G` = game globals (`_DAT_1009ffc0`).

## 1. `snd ` ids behind the TOC sound handles  [HIGH]

### 1.1 How a handle gets its sound
`.InitSounds @ 10045838` (when the Sound flag `0x100a5105` is set) repeats
`li r3,id; bl 0x10091748; lwz r4,slot(r2); stw r3,0(r4)` (first at 10045860–10045870). The callee
`@10091748` builds `'snd '` (`lis r3,0x736e; addi r3,r3,0x6420` 1009175c/10091764), moves the id to r4
and calls the `GetResource` glue (`bl 0x1009ee64` 10091768), then locks/detaches the handle. Three
handle arrays are filled by loops: `0x100a0304[0..2]` = 486..488 (`addi r3,r30,0x1e6` 10045f04),
`0x100a0300[0..2]` = 489..491 (`addi r3,r30,0x1e9` 10045f34), `0x100a025c[0..3]` = 410..413
(`addi r3,r30,0x19a` 10046338). `.LoadLevelSounds @ 100033d4` re-runs `.InitSounds` with the World
Data file first in the chain when `hdr+0x26d0 ≠ 0`; World Data (and the application fork) hold **no
`snd ` resources** (resource-map walk this session), so every id resolves in `Ferazel's Wand Sounds`.
A play call passes `*slot` (e.g. `lwz r3,-0x756c(r2); lwz r3,0(r3)`); the routines are
`.STPlayRegSound` 10047580, `.STPlay3DSound` 10047ac0, `…Pitched` 10047b8c, `…Rand` 10047d44.

### 1.2 Complete slot → id map (all 144 handles; slot `a0xxx` = TOC 0x100a0xxx, `9fxxx` = 0x1009fxxx)
300 `a0424` · 301 `a0420` · 302 `a01fc` · 303 `a041c` · 304 `a0418` · 401 `a0414` · 402 `a0410` ·
403 `a040c` · 404 `a0408` · 405 `a020c` · 406 `a0208` · 407 `a0404` · 408 `a0400` · 409 `a03fc` ·
410..413 `a025c[0..3]` · 414 `a03f8` · 415 `a03f4` · 416 `a03f0` · 417 `a03ec` · 418 `a03e8` ·
419 `a03e4` · 420 `a03e0` · 421 `a03dc` · 422 `a03d8` · 423 `a01e4` · 424 `a01e0` · 425 `a03d4` ·
426 `a03d0` · 427 `a03cc` · 428 `a03c8` · 429 `a03c4` · 430 `a03c0` · 431 `a03bc` · 432 `a03b8` ·
433 `a03b4` · 434 `a03b0` · 435 `9fdec` · 436 `a03ac` · 437 `a03a8` · 438 `a03a4` · 439 `a03a0` ·
440 `a039c` · 441 `a0398` · 442 `9fdb4` · 443 `a0394` · 444 `a0390` · 445 `a038c` · 446 `a0388` ·
447 `a0384` · 448 `a0380` · 449 `9fde4` · 450 `a02dc` · 451 `a037c` · 452 `9fe24` · 453 `9fd68` ·
454 `a0378` · 455 `a0374` · 456 `a0370` · 457 `a036c` · 458 `a0368` · 459 `a0364` · 460 `a0360` ·
461 `a035c` · 462 `a01ec` · 463 `a0358` · 464 `a0354` · 465 `a0350` · 466 `a034c` · 467 `a0348` ·
468 `a0344` · 469 `a0340` · 470 `a033c` · 471 `a0338` · 472 `a0334` · 473 `a0330` · 474 `a032c` ·
475 `a0328` · 476 `a0324` · 477..479 `a0320[0..2]` · 480 `a031c` · 481 `a0318` · 482 `a0314` ·
483 `a0310` · 484 `a030c` · 485 `a0308` · 486..488 `a0304[0..2]` · 489..491 `a0300[0..2]` ·
492 `a02fc` · 493 `a02f8` · 494 `a02f4` · 495 `a02f0` · 496 `a02ec` · 497 `a02e8` · 498 `a02e4` ·
499 `a02e0` · 500 `a02d8` · 501 `a02d4` · 502 `a02d0` · 503 `a02cc` · 504 `a02c8` · 505 `a02c4` ·
506 `a02c0` · 507 `a02bc` · 508 `a02b8` · 509 `a02b4` · 510 `a02b0` · 511 `9fe20` · 600 `a0288` ·
601 `a0284` · 603 `a0280` · 604 `a027c` · 605 `a0204` · 606 `9fdf0` · 607 `a02ac` · 608 `a02a8` ·
609 `a02a4` · 610 `a02a0` · 611 `a029c` · 612 `a0298` · 613 `a0294` · 614 `a0290` · 615 `a028c` ·
700 `a0278` · 701 `a0274` · 702 `a0270` · 703 `a026c` · 704 `a0268` · 800 `9fe54` · 801 `9fe50` ·
802 `9fe4c` · 803 `9fe5c` · 804 `9fe58` · 805 `9fe48` · 4704 `a0264` · 4705 `a0260`.
(Script over the raw `li r3 / lwz r4,slot(r2) / stw r3,0(r4)` triples of 10045838–10046374. The only
other `bl 0x10091748` sites are `.InitAppGlobals` 10000b14–10000b58: 198 'pause', 4801, 4803, 4804; ids
602, 705 and the "old" variants are loaded by nobody.) Names: `snd ` resource names (sprites-backgrounds-sounds.md §6 — ⚑ corrected (review 2h, 2026-10-04) #6).

### 1.3 The sounds of pickups and boxes (raw call site → handle → id 'name')
Volume = arg 3 (0x100 full); "pitched" = rate arg. Handles held in prologue registers were followed
(`.HitPlayerSprite` prologue 10055704–10055774: r23 = `a02d4`, r8 = `a02d0`, r9 = `a02d8`, r10 =
`a0384`; live to the uses per the decompile's data flow).

| object / event | raw call | id 'name' |
|---|---|---|
| Mist body re-entry (69) | 100558b8 | 420 'teleport in' |
| Xichron 1055 (vol 0x55) | 10055948 | 501 'coin bonus' |
| big Xichron 1056 | 10055998, 100559c8 (rates 40000+R(10000), 30000+R) + 100559dc | 489 'chaincreak1' ×2, 501 |
| 100th Xichron | 10055ae0, 10055af8; red Xichron item 10055bac | 451 'majorbonus new', 445 'bonus 2'; 501 |
| secret trigger 1059 (p1 ≠ 0) | 10055c58 | 505 'puzzleunlock' |
| big magic / health crystal 1290 / 1291 | 10055c88 (r9) / 10055cd8 (r8) | 500 'magic bonus' / 502 'health bonus' |
| small moneybag 1292 | 10055d68 + 10055d9c | 501 + 489 pitched 40000+R |
| big moneybag 1293 | 10055dd4 (r23) + 10055e08, 10055e38 | 501 + 489 ×2 |
| magic / health crystal 1300 / 1301 | 10055e78 (vol 0xab) / 10055ec8 | 500 / 502 |
| coins 1302, 1305, 1306 (vol 0xab) | 10055f44, 10055f7c, 10055fb4 | 501 |
| upgrades 1340/1341 (vol 0xab) | 10055ff0 | 451 'majorbonus new' |
| air bubble 1350 | 100563b0 | 456 'bubblebreathe' |
| scroll / item | 10056550 / 100566a0 | 503 'newspell' / 506 'itemfind' |
| spheres 1330, 1331..1333, 1334, 1335, 1336, 1337, 1338, 1339 | 10056740 (r10), 10056790, 100567d0, 10056828, 10056868, 100568a4 (r10), 1005699c, 100569c0 | 447 'bonus 4', 444 'bonus 1', 449 'bonus 6', 446 'bonus 3', 445 'bonus 2', 447, 444, 450 'Big ouch' |
| moneybag landing (`.HitBonusTileSprite`, vol 0x55) | 10060278 | 489 rand-pitch |
| door unlock / door open | 10056e34 / 10056e50 | 437 'Door unlock open' / 438 'Door open' |
| chest opening | 10056f60 | 439 'chest unlock' |
| 2907 timer trigger | 10056fac (rate 44000) | 442 'drown warning' |
| trampoline | 10057308 | 604 'spring up' |
| crate stomp / spin kept | 100573cc / 10057418 (vol 0xba) | 423 'rock crack' / 427 'player magic spin' |
| teleporter out / in | 10057514 / 100576d4 | 421 'teleport out' / 420 'teleport in' |
| save point success | 100577d4, 100577ec | 420, 421 |
| enemy pipe child at frame 3 | 1006eed0 | 459 'enemygenerate' |
| gate 2940 rising / sinking | 1006f64c, 1006f6b8 (r20 = `a0360` 1006d888) | 460 'rock barrier move' |
| ice wall 2941 hit / shatter | 1005abb8 / 1006f5d8 | 419 'dagger hit' / 424 'rock crush' |
| crate break / explosive crate | 1006fafc / 1006fd18 | 492 'cratesmash' / 435 'explosion' |
| `.KillBox` (rocks, trunks) | 10070644 | 424 'rock crush' |
| boulder/rock hard landing (types 0x42e..0x437) | 10070920, 10070bd4 (vol 0x55) | 436 'Object Hit' |
| spiked ball bounce (0x5c3/0x5c4) | 10070994, 10070aec (vol 0xab) | 303 'metal hit' |
| conversation item grant (§8) | `.HandleLineActions` | 501 |

## 2. Bonus `+0x168` (= p4) has one reader: the cannon  [HIGH]
`.SetupBonusSprite` copies p4 to `+0x168`. The only reader for a Bonus is `.TurnIntoCannoned`:
`lwz r3,0x4c(s); cmplw` against the Bonus handler (TOC 0x100a047c) → `lwz r0,0x168(s); cmpwi 1; beq`
→ refuse (100585e0–100585f8). So **p4 = 1 makes a pickup immune to being swallowed by a cannon**.
The five 1291 with p4 = 1 are L40 records 225..229 at x 5718..6621, y 788..1490 — inside L40's
densest cannon field (records 102..130: 12 cannons at x 5170..6561, y 459..1415) [HIGH census; intent
MED]. For containers 1307/3100..3109 the same p4 is the "spent" flag (part 1 §1.5), so spent lights
also refuse cannons. (Other `+0x168` readers belong to other classes: player shots, Box 1466, bosses.)

## 3. The three gate globals  [HIGH]
- **Byte `0x100a53d6` = "no asynchronous gamma fade running".** Initial value 1 (data byte at
  0x100a53d6, `const.py 100a53d4` → `5d c0 01 00`). `.GammaFadeOutAsync` / `.GammaFadeInAsync` store
  0 when they start a fade (10035710–10035714, 10035680–10035688), `.HandleAsyncGammaFade` stores 1
  when a fade completes (`li r29,1; stb r29,0(r30)` 10035820–10035824 for fade-out, 1003589c–100358a0 for fade-in), `.FinalGammaFadeIn` and
  `.GammaFadeOut` store 1 (10035978–10035980, 100353e8/10035408). Readers: save point
  (`subi r3,r2,0x246a` 1005771c–10057728), `.Pause` (10006088), `.CheckGameLoopKeys` (100076c4–100076d0),
  `.GenericMessage`. So a save point does nothing while a gamma flash/fade is in progress (e.g. the
  1340/1341 or save-success flash).
- **`_DAT_100a069c` = the player's dying counter** (player-states §2; set to 1 on death,
  enemy-shots §3.8): `.HitPlayerSprite` returns at once while it is > 0 (10055700, 10055764–1005577c).
- **`PTR_DAT_100a0708` = teleport-fire pulse, not UP.** `.HandlePlayerSprite` zeroes it every frame
  (10050fdc–10050fe4) and sets it to 1 only on the frame the teleporter charge `PTR_DAT_100a0700` is
  exactly 80 (`cmpwi r0,0x50; bne` 10051124–10051134; 60..79 are first snapped to 79, 1005110c–1005111c).
  The teleporter arm (100574dc–10057500) marks contact (`PTR_DAT_100a070c = 1`) and teleports only
  when the pulse is set; afterwards it clears it and sets the charge to −59 (100576f8–1005770c). No key
  is involved — standing on a teleporter for about a second fires it (player-states §3.6).

## 4. Faces and purposes  [HIGH code; MED names from the decoded art]

### 4.1 Spiked balls 1475/1476 use PICT 1487
`.InitBackgroundSprite` caches PICT `0x5c8 + i` into 16-byte entries of `PTR_DAT_100a09f4`, i = 0..9
(`addi r4,r27,0x5c8` 10071654, loop to 10 at 10071678). `.SetupBoxSprite` marks entry 7 used
(`stb r18,0x71(r17)`, r17 = that cache, 1006c014 / 1006c054) and `.HandleBoxSprite` sets the face
`lwz r0,0x74(r17)` (1006eb74 / 1006eb94): **PICT 1487** (0x5cf, 100×100), decoded: a red spiked ball.
The same cache gives Background 1480..1489 their faces (1482 a crescent pendulum blade, 1485 grey and
1486 white spiked balls, 1487 red).

### 4.2 2932/2933 = stalactites; they never hurt the player
PICT 2932 (12 × 32×20) and 2933 (24 × 32×54) decode as stalactite stubs and bodies in 12 rock/ice
colours. The placed sprite (type 2932) takes **body** face `PICT 2933[p1]` (TOC 0x100a0a58 =
PICT 0xb75, 1006aeb0/1006aed4 → 1006c5a4) and spawns a record-less child of the same type (layer parent − 1; its own Setup pass sets 1),
with **stub** face `PICT 2932[p1]` (0x100a0a5c = PICT 0xb74, 1006ae78/1006aea0 → 1006c680); a child
(`+0x48 == −1`) gets gravity 0 and no callbacks, so the stub stays on the ceiling. Body: rect
9,10,0x18,0x2a, one-way, HP p2 (0 → 150), home x `+0x154`. A player shot (`+0xa6 == 0`) subtracts its
damage and sets shake frames `d/20 + R(d/40)` (`.HitBoxSprite` 1007012c…); while shaking and HP > −250
x jitters ± max(frames/4, 1) about home by frame parity (1006f43c–1006f4bc); when the shake is over
(or at once if HP ≤ −250) and HP < 1, gravity becomes 0xfa (1006f4c0–1006f4d0) and it falls as an
ordinary Box. **No 0xb74/0xb75 test exists in `.HitPlayerSprite`** (type compares 1006b5fc,
1006d9b8, 1007012c only), so a falling stalactite only lands on the player like any one-way box.
p3/p4 (`+0x14c`, `+0x150`, defaults 0x40/100) have no reader in the 0xb74 arms. Census: 2932 ×3, L2,
all params 0.

### 4.3 1080/1081 is the magic carpet; the 1-px rect is its trigger strip
PICT 1080 (6 × 113×24) decodes as a blue flying carpet (frame 0 flat, 1..5 rippling); 0x438/0x439 is
the ridden "magic carpet" of physics §4 and player-states §3 (steering in `.HandleKeys`). Dormant 1080:
`SetRect(+0x34, 0x34, 4, 0x35, 0xc)` (1006b970–1006b988) = a 1×8-px strip at the carpet's centre
column, one-way. `.HitBoxSprite(carpet, player)` (10070558–10070570) turns it into 1081 (`+0x46 = 2`,
tile callback on, `+0x15c = 30`, `+0x185 = 0`). So the carpet wakes only when Ferazel's hot rect
reaches its middle column (walking onto/through its centre), not when he brushes an end [HIGH
arithmetic; MED intent]. Part 1 §2.4.6's "crumbling ledge" is this carpet (its lifetime is p2·30 frames,
p2 = 0 → endless; the only placement, L22, has p2 = 0).

## 5. Falling boulders 1075/1076: the `+0x160 < 0` setter  [HIGH]
`.HandleWizardSprite` creates `MTNewSprite(0x434, cx−16, cy−16, 9, −1, SetupBox)` (1008d038–1008d054)
and stores `+0x160 = −52` (`li r4,-0x34; stw r4,0x160(r3)` 1008d060–1008d06c): the boulder hovers,
blinking, for 52 frames, then drops (`.HandleBoxSprite` counts it up, the only other `+0x160` store in
Box code). Xichra's 0x434 (1008f184–1008f190) gets no such store → falls at once. Warrior's 0x433 crates:
bosses §2. Face PICT 1070 (decoded: a grey boulder). `.GenerateSprite` routes 0x433 (1075) to Box but
not 0x434; neither is placed (census).

## 6. Door `+0xa0` is a dead write  [HIGH]
`.HitBoxSprite` zeroes a door's `+0xa0` for non-pickup contacts (`stw r0,0xa0(r28)` 100705ac). Every
non-stack `0xa0(` access in the code: that store, `.HandleButtonSprite` (its own `+0xa0`, 10070f3c /
100710a0), and unrelated structs (`.DrawBlackLines`, `.InitParticles`, `.ConvertKeyName`). No door
code reads it.

## 7. Explosion 0x4b7 against enemies and boxes  [HIGH]
The Effect handler slot (TOC 0x100a0460) is loaded only by `.HitPlayerSprite`, `.HitBoxSprite`,
`.HitBackgroundSprite`, `.HitPlayerShotSprite`, `.SetupEffectSprite` and, among enemies, `.HitCrawlerSprite`,
`.HitWalkerSprite`, `.HitRoachSprite`, `.HitFrogSprite` (`tocrefs.py 100a0460`; the `cmpwi 0x4b7` scan
gives the same four enemy sites). Bat, Gremlin, Floater, Blob, Salamander, Dillo, Crab, Swarm and all
bosses are therefore immune to explosions.

| class | condition | effect | raw |
|---|---|---|---|
| Crawler | effect frame `+0x46 < 8` (or a 0x5a0 lava/acid geyser segment) | `HurtSprite(100, kvx = 0.65·effect vx, kvy −1000, invul 4, flash 10)` | 10066850–100668d0 (0.65 at 0x100a1a90) |
| Walker | same | `.HurtGoblin(…, 100, 0, −1000, 4, 8)` | 1006a590–1006a5e0 |
| Roach | same | `HurtSprite(100, effect vx >> 1, −1000, 4, 8)` + blood | 100781e8–1007823c |
| Frog | same | `HurtSprite(100, effect vx >> 3, effect vy >> 3, 8, 8)` | 10082ad4–10082b34 |
| crate 3090..3099 | **any frame** (no `+0x46` test) | HP −10 (crate HP 5 → `.KillCrate`), then `KillPlayerShot(explosion, 1, 0)` | 10070198–100701e8 |
With invulnerability 4 and damage while frame ≤ 7, an enemy can take the 100 twice from one blast if
the effect is still at frame ≤ 7 when the 4 frames lapse [MED: effect frame rate, triggers-background-2
§2]. The crate arm passes the Effect to `.KillPlayerShot`, whose branch for ids ≥ 100 (≠ 0x5a) only
plays 419 'dagger hit' if the effect's `+0xa6 == 0` and sets its `+0xa6 = −6` (`.KillPlayerShot`
tail, main dump) — the explosion is not removed [HIGH call; MED for what `+0xa6` does to an Effect].

## 8. Conversations grant items, never spells (narrows part 1 NR 7 / INDEX 3)  [HIGH code; MED reachability]
`.HandleLineActions @ 1007a0fc` reads two action triples (code, a, b) per line at line base
`*(Mcnv) + line·0x72a` + 0x81c / + 0x822 (`mulli 0x72a` 1007a2d0/1007a2f4; `lha 0x81c` 1007a2dc,
`lha 0x822` 1007a300) and dispatches codes 0..10 through the table at 0x100a6cd0
(`cmplwi 0xa; … bctr` 1007a318–1007a330; entries 0, 7, 8 = no-op 1007a55c). Code 1: coins `G+0x10`
−= a (≥ 0); **2: give item a, count b (0 → 1), cap 99, slot flag 0 (item), sound 501**; 3: remove item
a, b times; 4 / 6: set a placement-param word to 1 (own record / record a param b); 5: `G+0xad8+2a = b`;
9: kill a sprite; 10: set a per-level byte. No code writes a spell slot (flag 1). Decoding all 29 `Mcnv`
(36,936 B = 0x100 + 20·0x72a) with these offsets gives action-2 grants: Mcnv 200 (L1 merchant 2952):
items 4, 5 · 205 (L3 'Sitting Habnabit' 2954): **item 3, Platinum Key** · 206 (L11 'Nimbo' 2955): 6 ×99,
26 ×99 · 207 (L30 merchant 2952): **18 Ice Pick**, 17 Green Ring · 211 (L31 2965): 6 ×5 / ×20 · 204
(no NPC, sign or grave placement has p1 = 204): 6 ×3 / ×10. ~~Whether each line is reached depends on the condition and
response encoding (INDEX item 3).~~ Reachability is decoded in conversations-mcnv §4.2–§4.3 (review 2h ruling 3, ⚑ corrected
(review 2h, 2026-10-04) ruling 3): 205 #8 gives the Platinum Key and #5 removes a Health Potion (not a key); 207 #7 sells
the Ice Pick (500 coins) and #9 removes a Steel Key (#n 1-based = 0-based line n−1; table `0x100a6cd0` [2] = `1007a364`,
[3] = `1007a438`).

## 9. Decoration rows 2805..2889, per type (closes the remainder of INDEX item 1)  [HIGH]
All three ranges: no hit or tile callback, gravity 0, not pushable; re-faced every frame from a cache
(`.HandleBoxSprite` range tests 1006f810–1006f870). Cache faces: 2805..2849 → 16-byte entries at
0x100a644c, PICT 2805+i (`.InitBoxSprite` loop 0x2d); 2850..2869 → `_DAT_100a0a0c`, PICT 2850+i (0x14);
2870..2885 → `_DAT_100a0a08`, PICT 2870+i (**only 16**; 2886..2889 would read past the loaded entries;
unplaced).
- **2805..2849** (`.SetupBoxSprite` 1006cbb0–1006cd98): rect 0 (intangible) except 2827 (0xf,0xd,0x32,
  0x28, **not** one-way: a solid block) and 2832..2836 (one-way standable rects) via the table at
  `subi r0,r3,0xb0b; cmplwi 9` 1006cc28; layer −1 (behind every sprite), `+0x88 = 1`; **p1 ≠ 0** →
  mirrored (`+0x17e = 1`, `.FlipHRect`, 1006cd1c–1006cd3c); **p2 ≠ 0** → `+0xb8 = 0x10000 + p2`
  (1006cd58–1006cd68; remap table p2, INDEX 15); **p3 ≠ 0** → layer 10000 (in front of everything,
  1006cd80–1006cd90); p4 unread here (graves use it as the "read" flag, part 1 §2.3).
- **2850..2869** (1006cda0–1006ce70): layer 150, `+0x88 = 0`, rect 0x15,0x14,0x47,0x54 (a 50×64
  standable top 20 px below the face top), one-way; tint 0x10006 if `.GetAmbDarkVal` > 4, 0x10007 if
  > 7, 2856 always 0xb0005; **reads no placement param** (no `lha 0x48` in the arm). Faces decode as
  rock outcrops (100×100).
- **2870..2889** (1006ce78–1006cebc): layer 120, rect 0, one-way flag set but intangible; reads no
  param. Faces decode as mushroom clusters (72×72).

| type | PICT name (decoded look) | placed | levels | params (count) |
|---|---|---|---|---|
| 2808 | (unnamed; leaning log) | 3 | 15, 50 | p1 0 ×2, 1 ×1 |
| 2809 | '*Ziridium Mine Stuff' | 3 | 62 | (0,0,1,0) ×2, (1,0,1,0) |
| 2811 | '*Metal Blocks' | 5 | 62 | (0,0,1,0) ×4, (1,0,1,0) |
| 2812 / 2813 | '*Red Ruins 1 / 2' | 3 / 4 | 3, 11 | p2 = 11 tint, p3 = 1 front; p1 1 ×1 / ×2 |
| 2816 / 2817 | '*Cattails' / '2' | 9 / 3 | 10, 11 | p3 = 1; p1 1 ×2 / ×1 |
| 2818 | '*Icicles & Stuff' | 4 | 30 | 0 |
| 2820 / 2821 / 2822 | '*Skeleton1' / '2' / '3' | 22 / 13 / 12 | 3, 5, 10, 11, 18, 21, 22, 25, 50, 55 | p1 flips; p2 10 or 11 tints (2820 ×7, 2821 ×3, 2822 ×4) |
| 2826 | '*Armored Body 1' | 2 | 5, 55 | p2 = 6 |
| 2827 | '*Armored Body 2' — solid | 1 | 21 | 0 |
| 2828 / 2829 / 2830 / 2831 | '*Armor Rubbish 1/2/3/3' | 2 / 10 / 1 / 8 | 5, 11, 21, 55, 70 | 2829 (1,0,1,0) ×2; 2831 p1 1 ×1 |
| 2832 | '*Pedestal' (standable) | 3 | 3, 10, 21 | 0 |
| 2833 / 2834 / 2836 | '*Grave 1 / 2 / 4' (standable, talk) | 1 each | 21 | p1 260 / 261 = `Mcnv` ids; 2836 p1 = 1 (≤ 100 on a non-2902 talker → nothing is shown, part 1 §2.3) |
| 2837 / 2838 / 2839 | '*Straw / Purply / Skull Rug' | 4 / 3 / 4 | 10, 11 / 62 / 51, 62 | 0 |
| 2840 | '*Manditraki Pillar' | 7 | 5, 62 | p3 1 ×4 |
| 2841 | '*Gray Pedestal' | 37 | 15 levels | 0 |
| 2842 | '*Book pile' | 3 | 1 | p3 1; one p2 = 22; one p1 = 1 |
| 2843 | '*Cobweb Chair' | 1 | 3 | 0 |
| 2846 / 2847 | '*Grassy (L/l)ightboulder' / '2' | 2 / 2 | 10 | 2847: p3 1 ×1, p1 1 ×1 |
| 2848 / 2849 | '*Scraggly Vines' / '2' | 11 / 1 | 2, 3, 10 / 2 | p3 1 ×7 / ×1; p1 1 ×1 |
| 2850, 2852, 2853, 2854, 2856, 2857, 2861, 2867, 2868, 2869 | rock outcrops | 1, 1, 3, 10, 2, 3, 1, 1, 1, 4 | 21; 15; 1, 15; 31; 62; 11, 50; 10; 50; 3; 3, 45 | non-zero params on 2852/2853/2854/2869 are **ignored** |
| 2870, 2871, 2872, 2873, 2874, 2875, 2876, 2883, 2884 | mushroom clusters | 14, 1, 6, 3, 1, 2, 3, 8, 1 | 1, 2 / 1 / 11 / 11 / 1 / 11 / 11 / 1, 3 / 3 | all 0 |
Unplaced: 2805..2807 (no PICT), 2810, 2814, 2815, 2819, 2823..2825, 2835, 2844, 2845, 2851, 2855,
2858..2860, 2862..2866, 2877..2882, 2885..2889. Record byte +1 is 0 in all of them.

## NOT RESOLVED
1. What `.KillPlayerShot`'s `+0xa6 = −6` does to an Effect 0x4b7 after it touches a crate (§7) —
   Effect-class reader. Tried: the `.KillPlayerShot` write only (§7). ⚑ corrected (review 2h, 2026-10-04) #6
2. ~~Reachability of the conversation item grants (§8) — the condition/response encoding is INDEX item 3.~~
   Tried: the action decode of §8 only. → closed by conversations-mcnv.md §4.2–§4.3 (wave 2, L5)
   ⚑ corrected (review 2h, 2026-10-04) #6
3. Whether an enemy can take two 100-point explosion hits (§7) depends on the Effect frame rate.
   Tried: the damage arms of §7; the Effect frame advance was not read. ⚑ corrected (review 2h, 2026-10-04) #6

## Proposed additions to physics.md §0
| off | type | meaning (this file) |
|---|---|---|
| +0x168 | i32 | Bonus: p4 copy = "no cannon" (`.TurnIntoCannoned` refuses `== 1`, 100585f0–100585f8); containers: spent |
| +0x154 | i32 | stalactite: home x for the shake (§4.2) |
| +0x160 | i32 | falling boulder hover counter (Wizard writes −52, §5) |
| +0xa0 | i32 | door: written 0 by `.HitBoxSprite`, never read (§6) |

## Corrections to the existing bank
| # | file § | old | new | evidence |
|---|---|---|---|---|
| P1 | pickups-boxes §1.11 (own; applied in place) | spheres "(all L45)" | only 1339 is L45-only; 1330 L10 · 1331 L4, 11 · 1332 L2, 22 · 1333 L50, 51 · 1334 L3, 4, 10, 15, 21, 22, 30, 50 · 1335 L1–3, 11, 20–22, 30, 31, 40, 45, 50–52, 62 · 1336 L52 · 1337 L22, 30, 31, 40, 52, 62 · 1338 L22, 30, 31, 70 | census this session |
| P2 | pickups-boxes §2.2 / §2.4.6 (own; in place) | 1080/1081 "crumbling ledge [MED purpose]" | magic carpet (dormant / flying) | §4.3 |
| P3 | pickups-boxes §2.2 (own; in place) | 2932 "child 0xb74 with a 0xb75 face" | the placed body has the 0xb75 (PICT 2933) face; the child has the 0xb74 (PICT 2932) stub | 1006c5a4 vs 1006c680 |
| P4 | pickups-boxes §2.4.7 (own; in place) | `PTR_DAT_100a0708` "presumably UP" | teleport-fire pulse at charge 80 | §3 |
| P5 | pickups-boxes §2.4.3 (own; in place) | key 3 sources "crate L62 only" | also Mcnv 205 (L3 Sitting Habnabit), action 2 [HIGH — raised with P6 / pickups-boxes §2.4.3; ⚑ corrected (review 2i, 2026-10-04) #3] | §8 |
| P6 | held-item-melee §1 "Ice Pick (3218) … never placed nor held … [MED unobtainable: … conversations not checked]" | unobtainable | Mcnv 207 (L30 merchant) line 6 (0-based; = #7) grants item 18 (Ice Pick) and line 7 (= #8) item 17 [~~MED~~ HIGH reachability, conversations-mcnv §4.2] — merged with CM #6 (fix pass) | §8 |
| P7 | physics §0 `+0xa0` "a door's `+0xa0` is cleared by `.HitBoxSprite` (PB NR 8)" | open | dead write, no reader | §6 |
| P8 | triggers-background-2 §2 effect table, 1207 (0x4b7) | hurts the player while frame ≤ 7 | add: hurts Crawler/Walker/Roach/Frog 100 (frame ≤ 7) and crates −10 on any frame; other classes immune | §7 |
| P9 | world-data §5 (`Mcnv`) | action encoding unresolved | action triples at line + 0x81c / + 0x822, codes 1..6, 9, 10 as §8 | 1007a2dc, 1007a300, 0x100a6cd0 |
