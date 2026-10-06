# Deimos Rising — data census (Phase 0)

> Generated 2026-10-06 by `deimos-census` (`Deimos/Core`, plan `docs/plans/2026-10-06-deimos-phase0-data.md`
> Task C7) through HectorKit `13c8f9b` (tag `v0.3.0`), on Classics branch `deimos-phase0` at `fd6b2c9` + the C7
> commit (the tool and this file). Everything below the rule is the tool's stdout, verbatim
> (`DeimosCensusTests.testStdoutEqualsCommittedCensus` keeps it so). Re-run from the repo root:
>
>     swift build --package-path Deimos/Core -c release
>     "$(swift build --package-path Deimos/Core -c release --show-bin-path)/deimos-census" "$PWD/Resources/Deimos/Data"
>
> Add `--render out/deimos-render` to also write `menu.png`, `background.png`, `canyon1-map.png` (top-down),
> `bocr-frames.png`, `tesm-plate.png` (ImageIO; `out/` is git-ignored) — `menu.png` is Ben's INDEX #10 look.
> The data is the committed copy `Resources/Deimos/Data` (DECISIONS D24): the four paks + the Local
> `Last Film`. "Decoded" means decodes to the census — not "looks/sounds right".

## Spec-vs-data deltas

1. **`Music 3[mu03].aif`'s FORM size is 76 bytes short of the file** (a QuickTime `wave` chunk was added
   without updating it). Readers walk chunks to the end of the data; section 7 lists it.
2. **`Music.pak:Ambient Music Loop[ammu].IMA` has general-purpose flag bit 1 set** (version-needed 10).
   Meaningless for STORED; ignored (the game never reads flags). Listed under section 2.
3. **18 of 45 TGAs carry colour-map-spec byte 7 (entry size) = `0x18` with colour-map type 0** — ignored per
   TGA; 14 TGAs carry the 26-byte TGA 2.0 footer (`TRUEVISION-XFILE.`), also ignored.
4. **The `GLOW` alpha plate scans to different frame rects on 8-bit system-CLUT indices than on RGB**: fill
   (8,0,255) and the body's (0,0,255) share CLUT index 210. The 8-bit result (the original's) is used; 5 of 12 differ.
5. **`plde` writes three `_INT` keys as `100.000000` / `15.000000`**; `sscanf("%i")` reads the leading integer
   (100, 15), as the original does.
6. **Every `tefo` carries `#Size_INT`, which the engine never reads** (bank data-tags §5); not parsed.
7. **Bank pak-format §3 says "some files use CR LF": none do** — CR in stli/flli/idli/reli/tefo, LF in
   leve/plde/unde/wede, no line end in coli.
8. **(Research note 15, MED)** Colour conversion follows QuickDraw's documented rules, not read in this binary:
   24→16 keeps the high 5 bits (`c >> 3`); the 8-bit draw maps through a 4-bit inverse table to the system CLUT.
9. **(Research note 21, MED)** Sound PCM here is the kit's decode (= CoreAudio `ima4`, sample-exact vs
   `afconvert`); the game's own effect mixer decodes one continuous nibble stream — Phase 1's job.

Plan literals the bytes corrected (each pinned by a test; the tool output below is authoritative):

10. Token values: **BOOL TRUE 4,201 / FALSE 64,203**, not 4,149 / 63,723 — the planner's probe skipped the one
    key with an apostrophe, `#stateSpawnSetDon'tSpawnOffscreen_BOOL` (532 items: 52 TRUE + 480 FALSE).
11. The one `stli` with Mac Roman bytes ≥ 0x80 is **`edit`**, not `cred` (note 11).
12. The one stray media-mask pixel (`0x256b`) is in **`int3`** (Industrial 3 Media), not `ist3` (note 19).
13. GIF global colour tables are **8–256 entries** (8: 5 files · 16: 4 · 32: 3 · 64: 3 · 256: 235), not "2–256".
14. `leve` index (master-list) order is **le01–le08, le11, le12, le09, le10** (Game.pak central-directory
    order; le09/le10 were added last) — the play order comes from the level-order table, not this list.
15. The `Interface.pak:decr` TGA header's byte 7 is `0x18` (delta 3), not the plan's `00`.
16. `idli gaso` (24 slots) holds **3 `none` slots** (indices 9, 17, 19): 21 name a `soun` tag. Of the 1,553 unit
    sprite faces 675 are `none` (878 name a group); of the 2,711 unit sound IDs 2,320 are `none` (391 name a tag).
17. Pak entry counts in the files line are FILE entries (871); the central directories hold 886 (15 folders).

---

# Deimos Rising 1.0.6 — data census

## Summary

```
files 5 · paks 4 (Audio.pak 96 · Game.pak 763 · Interface.pak 9 · Music.pak 3) · local 1 · CRC ok 871
tags 872 · coli 1 · film 5 · flli 1 · idli 6 · im08 250 · im16 45 · leve 12 · plde 2 · reli 1 · soun 99 · stli 5 · tefo 54 · unde 386 · wede 5 · overridden 0 · alerts 0
im08 250 · sprite groups 125 · frames 2554 (alpha maps 2553) · pixels 3,129,511 · encoded bytes 12,579,236 · max frame 218×110
im16 45 · 480×3600 12 · 96×720 12 · 146×306 12 · 640×480 5 · other 4 · water px 117,194
soun 99 · effects 96 mono ima4 44100 Hz (frames 3,133,376) · music 3 stereo ima4 (packets 134,892 · 23,966 · 41,153)
text 473 · stli 173 lines · flli 220 · idli 130 · reli 22 · coli 1 · tefo 54 · plde 2 · wede 5 (spawns 15) · leve 12 (objects 565) · unde 386 (states 1,167) · token errors 0
film 5 · version 10005 · de01 le07 4809 · de02 le06 8357 · de03 le02 10058 · de04 le08 5649 · last le07 4809
```

## 1. Files

| file | bytes | SHA-256 |
| --- | ---: | --- |
| `Paks/Audio.pak` | 1,702,614 | `b46ce0711faca7ce0cd33c850c41e88bd3be7f7289eee9d80fe03c7013bb1039` |
| `Paks/Game.pak` | 54,956,985 | `3ae865a9ee3b005dc10368de847e4a3dea402dc1a911bbd09f0728153aceee09` |
| `Paks/Interface.pak` | 2,849,896 | `de7d2dd349f208f72eae156820c48c791f06e46b24ec5816e1a1bed0dfea0d93` |
| `Paks/Music.pak` | 13,601,894 | `3ee906a6f885ba466645ea53bab6aebba54840d756a63212f895364cebadc455` |
| `Local/film/Last Film[last].film` | 40,296 | `cf5f42cc475c011e750d3fe268e06f890ee0aac4b1678d79bcf2dca5b3e1b897` |

## 2. Paks (STORED zip: central directory, CRC-32 of every file entry)

| pak | CD entries | files | folders | CRC ok |
| --- | ---: | ---: | ---: | ---: |
| `Audio.pak` | 96 | 96 | 0 | 96 |
| `Game.pak` | 776 | 763 | 13 | 763 |
| `Interface.pak` | 11 | 9 | 2 | 9 |
| `Music.pak` | 3 | 3 | 0 | 3 |

- `Music.pak:Ambient Music Loop[ammu].IMA`: general-purpose flags 2 (STORED: ignored)

## 3. Tag index (Local, then the paks in name order)

| type | records | local |
| --- | ---: | ---: |
| im08 | 250 | 0 |
| im16 | 45 | 0 |
| soun | 99 | 0 |
| stli | 5 | 0 |
| flli | 1 | 0 |
| wede | 5 | 0 |
| reli | 1 | 0 |
| idli | 6 | 0 |
| coli | 1 | 0 |
| tefo | 54 | 0 |
| plde | 2 | 0 |
| pref | 0 | 0 |
| film | 5 | 1 |
| unde | 386 | 0 |
| leve | 12 | 0 |
| **total** | **872** | **1** |

Overridden pak records: 0. Alerts: 0.

## 4. Every entry (index order)

| pak | type | ID | name | bytes | result |
| --- | --- | --- | --- | ---: | --- |
| Local | film | `last` | `film/Last Film[last].film` | 40,296 | film le07 · 4809 ticks · score 25050 |
| Audio.pak | soun | `acbo` | `Accuracy Bonus[acbo].IMA` | 15,060 | AIFC ima4 · 1 ch · 436 packets · 27,904 frames |
| Audio.pak | soun | `bash` | `Baccula Shields[bash].IMA` | 6,084 | AIFC ima4 · 1 ch · 172 packets · 11,008 frames |
| Audio.pak | soun | `bgbu` | `Bacta Gun - Bullet[bgbu].IMA` | 9,008 | AIFC ima4 · 1 ch · 258 packets · 16,512 frames |
| Audio.pak | soun | `balh` | `Bang - Loud Hollow[balh].IMA` | 17,508 | AIFC ima4 · 1 ch · 508 packets · 32,512 frames |
| Audio.pak | soun | `bass` | `Bang - Soft Short[bass].IMA` | 13,388 | AIFC ima4 · 1 ch · 387 packets · 24,768 frames |
| Audio.pak | soun | `baso` | `Bang - Soft[baso].IMA` | 16,992 | AIFC ima4 · 1 ch · 493 packets · 31,552 frames |
| Audio.pak | soun | `bocr` | `Bomb Crater[bocr].IMA` | 6,798 | AIFC ima4 · 1 ch · 193 packets · 12,352 frames |
| Audio.pak | soun | `bop ` | `Bop[bop ].IMA` | 5,364 | AIFC ima4 · 1 ch · 151 packets · 9,664 frames |
| Audio.pak | soun | `cabo` | `Cash Bonus[cabo].IMA` | 20,058 | AIFC ima4 · 1 ch · 583 packets · 37,312 frames |
| Audio.pak | soun | `cash` | `Cash[cash].IMA` | 5,922 | AIFC ima4 · 1 ch · 166 packets · 10,624 frames |
| Audio.pak | soun | `clic` | `Click[clic].IMA` | 788 | AIFC ima4 · 1 ch · 15 packets · 960 frames |
| Audio.pak | soun | `cohi` | `Coin Hit[cohi].IMA` | 5,616 | AIFC ima4 · 1 ch · 157 packets · 10,048 frames |
| Audio.pak | soun | `cbba` | `Cyclo Bomber Bang[cbba].IMA` | 31,788 | AIFC ima4 · 1 ch · 928 packets · 59,392 frames |
| Audio.pak | soun | `cbgu` | `Cyclo Bomber Gun[cbgu].IMA` | 28,320 | AIFC ima4 · 1 ch · 826 packets · 52,864 frames |
| Audio.pak | soun | `cbla` | `Cyclo Bomber Launch[cbla].IMA` | 40,900 | AIFC ima4 · 1 ch · 1,196 packets · 76,544 frames |
| Audio.pak | soun | `cbsh` | `CycloBomber Shields[cbsh].IMA` | 7,758 | AIFC ima4 · 1 ch · 220 packets · 14,080 frames |
| Audio.pak | soun | `elst` | `Electric Steel[elst].IMA` | 7,614 | AIFC ima4 · 1 ch · 217 packets · 13,888 frames |
| Audio.pak | soun | `elri` | `Electro Ripple[elri].IMA` | 15,536 | AIFC ima4 · 1 ch · 450 packets · 28,800 frames |
| Audio.pak | soun | `ex2s` | `Ex - 2 Stage[ex2s].IMA` | 39,426 | AIFC ima4 · 1 ch · 1,153 packets · 73,792 frames |
| Audio.pak | soun | `exae` | `Ex - Abrupt Echo[exae].IMA` | 17,576 | AIFC ima4 · 1 ch · 510 packets · 32,640 frames |
| Audio.pak | soun | `exal` | `Ex - Abrupt Loud[exal].IMA` | 13,904 | AIFC ima4 · 1 ch · 402 packets · 25,728 frames |
| Audio.pak | soun | `exll` | `Ex - Long Loud[exll].IMA` | 49,734 | AIFC ima4 · 1 ch · 1,456 packets · 93,184 frames |
| Audio.pak | soun | `exlo` | `Ex - Long[exlo].IMA` | 68,780 | AIFC ima4 · 1 ch · 2,016 packets · 129,024 frames |
| Audio.pak | soun | `exsd` | `Ex - Short Dull[exsd].IMA` | 29,884 | AIFC ima4 · 1 ch · 872 packets · 55,808 frames |
| Audio.pak | soun | `exse` | `Ex - Short Echo[exse].IMA` | 20,296 | AIFC ima4 · 1 ch · 590 packets · 37,760 frames |
| Audio.pak | soun | `esle` | `Ex - Short Loud Echo[esle].IMA` | 20,058 | AIFC ima4 · 1 ch · 583 packets · 37,312 frames |
| Audio.pak | soun | `exsl` | `Ex - Short Loud[exsl].IMA` | 20,092 | AIFC ima4 · 1 ch · 584 packets · 37,376 frames |
| Audio.pak | soun | `exsw` | `Ex - Short Warp Echo[exsw].IMA` | 22,336 | AIFC ima4 · 1 ch · 650 packets · 41,600 frames |
| Audio.pak | soun | `exli` | `Extra Life[exli].IMA` | 13,428 | AIFC ima4 · 1 ch · 388 packets · 24,832 frames |
| Audio.pak | soun | `gaov` | `Game Over[gaov].IMA` | 34,032 | AIFC ima4 · 1 ch · 994 packets · 63,616 frames |
| Audio.pak | soun | `grca` | `Grab Cash[grca].IMA` | 21,962 | AIFC ima4 · 1 ch · 639 packets · 40,896 frames |
| Audio.pak | soun | `ha01` | `Hatch 1[ha01].IMA` | 21,928 | AIFC ima4 · 1 ch · 638 packets · 40,832 frames |
| Audio.pak | soun | `ha02` | `Hatch 2[ha02].IMA` | 39,812 | AIFC ima4 · 1 ch · 1,164 packets · 74,496 frames |
| Audio.pak | soun | `inte` | `Interface Button[inte].IMA` | 3,704 | AIFC ima4 · 1 ch · 102 packets · 6,528 frames |
| Audio.pak | soun | `incl` | `Interface Click[incl].IMA` | 3,908 | AIFC ima4 · 1 ch · 108 packets · 6,912 frames |
| Audio.pak | soun | `icbu` | `Ion Cannon Bullet[icbu].IMA` | 8,362 | AIFC ima4 · 1 ch · 239 packets · 15,296 frames |
| Audio.pak | soun | `icpo` | `Ion Cannon Powerup[icpo].IMA` | 26,824 | AIFC ima4 · 1 ch · 782 packets · 50,048 frames |
| Audio.pak | soun | `icre` | `Ion Cannon Release[icre].IMA` | 27,968 | AIFC ima4 · 1 ch · 816 packets · 52,224 frames |
| Audio.pak | soun | `lacr` | `Laser - Crystal[lacr].IMA` | 11,898 | AIFC ima4 · 1 ch · 343 packets · 21,952 frames |
| Audio.pak | soun | `laec` | `Laser - Echo[laec].IMA` | 13,462 | AIFC ima4 · 1 ch · 389 packets · 24,896 frames |
| Audio.pak | soun | `lalo` | `Laser - Long[lalo].IMA` | 17,032 | AIFC ima4 · 1 ch · 494 packets · 31,616 frames |
| Audio.pak | soun | `lari` | `Laser - Ripple[lari].IMA` | 6,146 | AIFC ima4 · 1 ch · 174 packets · 11,136 frames |
| Audio.pak | soun | `laso` | `Laser - Soft[laso].IMA` | 7,784 | AIFC ima4 · 1 ch · 222 packets · 14,208 frames |
| Audio.pak | soun | `lgbu` | `Lateral Gun[lgbu].IMA` | 5,098 | AIFC ima4 · 1 ch · 143 packets · 9,152 frames |
| Audio.pak | soun | `lsch` | `Lev Sel Change[lsch].IMA` | 11,274 | AIFC ima4 · 1 ch · 325 packets · 20,800 frames |
| Audio.pak | soun | `lsna` | `Lev Sel No Access[lsna].IMA` | 5,268 | AIFC ima4 · 1 ch · 148 packets · 9,472 frames |
| Audio.pak | soun | `lsse` | `Lev Sel Select[lsse].IMA` | 14,550 | AIFC ima4 · 1 ch · 421 packets · 26,944 frames |
| Audio.pak | soun | `leen` | `Level End[leen].IMA` | 45,082 | AIFC ima4 · 1 ch · 1,319 packets · 84,416 frames |
| Audio.pak | soun | `lest` | `Level Start[lest].IMA` | 43,484 | AIFC ima4 · 1 ch · 1,272 packets · 81,408 frames |
| Audio.pak | soun | `mbro` | `Menu Button Rollover[mbro].IMA` | 4,146 | AIFC ima4 · 1 ch · 115 packets · 7,360 frames |
| Audio.pak | soun | `mehi` | `Metal - Hit[mehi].IMA` | 3,738 | AIFC ima4 · 1 ch · 103 packets · 6,592 frames |
| Audio.pak | soun | `mepo` | `Metal - Pop[mepo].IMA` | 4,316 | AIFC ima4 · 1 ch · 120 packets · 7,680 frames |
| Audio.pak | soun | `mlms` | `Mine Layer Mine Sh[mlms].IMA` | 7,716 | AIFC ima4 · 1 ch · 220 packets · 14,080 frames |
| Audio.pak | soun | `mlsh` | `Mine Layer Shields[mlsh].IMA` | 11,422 | AIFC ima4 · 1 ch · 329 packets · 21,056 frames |
| Audio.pak | soun | `milm` | `Missile Launch Mid[milm].IMA` | 20,466 | AIFC ima4 · 1 ch · 595 packets · 38,080 frames |
| Audio.pak | soun | `miss` | `Missile[miss].IMA` | 17,468 | AIFC ima4 · 1 ch · 507 packets · 32,448 frames |
| Audio.pak | soun | `moco` | `Money Count[moco].IMA` | 1,426 | AIFC ima4 · 1 ch · 35 packets · 2,240 frames |
| Audio.pak | soun | `moha` | `Motor Hatch[moha].IMA` | 9,620 | AIFC ima4 · 1 ch · 276 packets · 17,664 frames |
| Audio.pak | soun | `nobo` | `No Bonus[nobo].IMA` | 10,300 | AIFC ima4 · 1 ch · 296 packets · 18,944 frames |
| Audio.pak | soun | `ppen` | `Phase Pod Entry[ppen].IMA` | 27,696 | AIFC ima4 · 1 ch · 808 packets · 51,712 frames |
| Audio.pak | soun | `ppre` | `Phase Pod Retreat[ppre].IMA` | 25,294 | AIFC ima4 · 1 ch · 737 packets · 47,168 frames |
| Audio.pak | soun | `ppsh` | `Phase Pod Shield[ppsh].IMA` | 5,914 | AIFC ima4 · 1 ch · 167 packets · 10,688 frames |
| Audio.pak | soun | `plbo` | `Plasma Bomb[plbo].IMA` | 9,484 | AIFC ima4 · 1 ch · 272 packets · 17,408 frames |
| Audio.pak | soun | `plen` | `Player Entry[plen].IMA` | 37,194 | AIFC ima4 · 1 ch · 1,087 packets · 69,568 frames |
| Audio.pak | soun | `plsh` | `Player Shields[plsh].IMA` | 13,768 | AIFC ima4 · 1 ch · 398 packets · 25,472 frames |
| Audio.pak | soun | `pdab` | `Power Down - Abrupt[pdab].IMA` | 27,912 | AIFC ima4 · 1 ch · 814 packets · 52,096 frames |
| Audio.pak | soun | `podo` | `Power Down[podo].IMA` | 25,322 | AIFC ima4 · 1 ch · 738 packets · 47,232 frames |
| Audio.pak | soun | `powe` | `Powerup[powe].IMA` | 11,592 | AIFC ima4 · 1 ch · 334 packets · 21,376 frames |
| Audio.pak | soun | `publ` | `Publisher[publ].IMA` | 125,492 | AIFC ima4 · 1 ch · 3,684 packets · 235,776 frames |
| Audio.pak | soun | `punc` | `Punch Shot[punc].IMA` | 6,730 | AIFC ima4 · 1 ch · 191 packets · 12,224 frames |
| Audio.pak | soun | `shat` | `Shatter[shat].IMA` | 12,238 | AIFC ima4 · 1 ch · 353 packets · 22,592 frames |
| Audio.pak | soun | `shab` | `Shield - Abrupt[shab].IMA` | 7,302 | AIFC ima4 · 1 ch · 208 packets · 13,312 frames |
| Audio.pak | soun | `shwa` | `Shield Warning[shwa].IMA` | 4,316 | AIFC ima4 · 1 ch · 120 packets · 7,680 frames |
| Audio.pak | soun | `snlo` | `Snap - Loud[snlo].IMA` | 18,902 | AIFC ima4 · 1 ch · 549 packets · 35,136 frames |
| Audio.pak | soun | `snse` | `Snap - Short Echo[snse].IMA` | 9,744 | AIFC ima4 · 1 ch · 280 packets · 17,920 frames |
| Audio.pak | soun | `snsh` | `Snap - Short[snsh].IMA` | 14,584 | AIFC ima4 · 1 ch · 422 packets · 27,008 frames |
| Audio.pak | soun | `snvs` | `Snap - Very Short[snvs].IMA` | 9,654 | AIFC ima4 · 1 ch · 277 packets · 17,728 frames |
| Audio.pak | soun | `spgu` | `Sparta Gun[spgu].IMA` | 6,492 | AIFC ima4 · 1 ch · 184 packets · 11,776 frames |
| Audio.pak | soun | `spla` | `Splash[spla].IMA` | 11,048 | AIFC ima4 · 1 ch · 318 packets · 20,352 frames |
| Audio.pak | soun | `stee` | `Steel[stee].IMA` | 5,710 | AIFC ima4 · 1 ch · 161 packets · 10,304 frames |
| Audio.pak | soun | `sspr` | `StunShip Proj[sspr].IMA` | 5,064 | AIFC ima4 · 1 ch · 142 packets · 9,088 frames |
| Audio.pak | soun | `sssh` | `StunShip Shields[sssh].IMA` | 6,628 | AIFC ima4 · 1 ch · 188 packets · 12,032 frames |
| Audio.pak | soun | `tran` | `Transition[tran].IMA` | 34,278 | AIFC ima4 · 1 ch · 1,000 packets · 64,000 frames |
| Audio.pak | soun | `trap` | `Trapdoor Open[trap].IMA` | 5,874 | AIFC ima4 · 1 ch · 166 packets · 10,624 frames |
| Audio.pak | soun | `turr` | `Turret Shot[turr].IMA` | 3,128 | AIFC ima4 · 1 ch · 84 packets · 5,376 frames |
| Audio.pak | soun | `wesw` | `Weapon Switch[wesw].IMA` | 11,484 | AIFC ima4 · 1 ch · 331 packets · 21,184 frames |
| Audio.pak | soun | `wewa` | `Weapon Warning[wewa].IMA` | 2,412 | AIFC ima4 · 1 ch · 64 packets · 4,096 frames |
| Audio.pak | soun | `wesc` | `Wep Select Cancel[wesc].IMA` | 3,678 | AIFC ima4 · 1 ch · 100 packets · 6,400 frames |
| Audio.pak | soun | `wesf` | `Wep Select Fail[wesf].IMA` | 1,936 | AIFC ima4 · 1 ch · 50 packets · 3,200 frames |
| Audio.pak | soun | `meta` | `Metal[meta].IMA` | 3,976 | AIFC ima4 · 1 ch · 110 packets · 7,040 frames |
| Audio.pak | soun | `miwa` | `Mine Warning[miwa].IMA` | 12,442 | AIFC ima4 · 1 ch · 359 packets · 22,976 frames |
| Audio.pak | soun | `shop` | `Shuriken Open[shop].IMA` | 14,006 | AIFC ima4 · 1 ch · 405 packets · 25,920 frames |
| Audio.pak | soun | `phbh` | `Photon Beam Hum[phbh].IMA` | 30,972 | AIFC ima4 · 1 ch · 904 packets · 57,856 frames |
| Audio.pak | soun | `shch` | `Shield Charge[shch].IMA` | 19,072 | AIFC ima4 · 1 ch · 554 packets · 35,456 frames |
| Audio.pak | soun | `mult` | `Multiplier[mult].IMA` | 17,984 | AIFC ima4 · 1 ch · 522 packets · 33,408 frames |
| Audio.pak | soun | `miac` | `Mission Accuracy[miac].IMA` | 67,896 | AIFC ima4 · 1 ch · 1,990 packets · 127,360 frames |
| Game.pak | im08 | `EXSR` | `im08/Expl Small Red IA[EXSR].gif` | 3,319 | GIF 398×35 · alpha plate |
| Game.pak | im08 | `exsr` | `im08/Expl Small Red IC[exsr].gif` | 3,981 | GIF 398×35 · colour plate |
| Game.pak | im08 | `BOCR` | `im08/Bomb Crater IA[BOCR].gif` | 476 | GIF 55×21 · alpha plate |
| Game.pak | im08 | `bocr` | `im08/Bomb Crater IC[bocr].gif` | 305 | GIF 55×21 · colour plate |
| Game.pak | im08 | `BASH` | `im08/Baccula Shields IA[BASH].gif` | 5,637 | GIF 1278×90 · alpha plate |
| Game.pak | im08 | `bash` | `im08/Baccula Shields IC[bash].gif` | 37,074 | GIF 1278×90 · colour plate |
| Game.pak | im08 | `BGBU` | `im08/Bacta Gun Bullet IA[BGBU].gif` | 4,370 | GIF 830×25 · alpha plate |
| Game.pak | im08 | `bgbu` | `im08/Bacta Gun Bullet IC[bgbu].gif` | 6,035 | GIF 830×25 · colour plate |
| Game.pak | im08 | `BAGU` | `im08/Bacta Gun IA[BAGU].gif` | 4,506 | GIF 235×75 · alpha plate |
| Game.pak | im08 | `bagu` | `im08/Bacta Gun IC[bagu].gif` | 6,553 | GIF 235×75 · colour plate |
| Game.pak | im08 | `BURS` | `im08/Burst IA[BURS].gif` | 15,903 | GIF 533×123 · alpha plate |
| Game.pak | im08 | `burs` | `im08/Burst IC[burs].gif` | 2,554 | GIF 533×123 · colour plate |
| Game.pak | im08 | `BUZZ` | `im08/Buzzsaw IA[BUZZ].gif` | 4,264 | GIF 378×49 · alpha plate |
| Game.pak | im08 | `buzz` | `im08/Buzzsaw IC[buzz].gif` | 8,459 | GIF 378×49 · colour plate |
| Game.pak | im08 | `EDUT` | `im08/Editor Utility IA[EDUT].gif` | 878 | GIF 330×37 · alpha plate |
| Game.pak | im08 | `edut` | `im08/Editor Utility IC[edut].gif` | 1,241 | GIF 330×37 · colour plate |
| Game.pak | im08 | `GALO` | `im08/Game Logo IA[GALO].gif` | 1,351 | GIF 163×114 · alpha plate |
| Game.pak | im08 | `galo` | `im08/Game Logo IC[galo].gif` | 10,403 | GIF 163×114 · colour plate |
| Game.pak | im08 | `ICBU` | `im08/Ion Cannon Bullet IA[ICBU].gif` | 4,843 | GIF 830×25 · alpha plate |
| Game.pak | im08 | `icbu` | `im08/Ion Cannon Bullet IC[icbu].gif` | 4,858 | GIF 830×25 · colour plate |
| Game.pak | im08 | `IOCA` | `im08/Ion Cannon IA[IOCA].gif` | 4,518 | GIF 235×75 · alpha plate |
| Game.pak | im08 | `ioca` | `im08/Ion Cannon IC[ioca].gif` | 6,275 | GIF 235×75 · colour plate |
| Game.pak | im08 | `LAGU` | `im08/Lateral Gun IA[LAGU].gif` | 4,574 | GIF 235×75 · alpha plate |
| Game.pak | im08 | `lagu` | `im08/Lateral Gun IC[lagu].gif` | 6,066 | GIF 235×75 · colour plate |
| Game.pak | im08 | `MINE` | `im08/Mine IA[MINE].gif` | 13,217 | GIF 1249×88 · alpha plate |
| Game.pak | im08 | `mine` | `im08/Mine IC[mine].gif` | 30,802 | GIF 1249×88 · colour plate |
| Game.pak | im08 | `MUXX` | `im08/Multiplier x10 IA[MUXX].gif` | 4,144 | GIF 1052×19 · alpha plate |
| Game.pak | im08 | `muxx` | `im08/Multiplier x10 IC[muxx].gif` | 7,829 | GIF 1052×19 · colour plate |
| Game.pak | im08 | `MUX2` | `im08/Multiplier x2 IA[MUX2].gif` | 4,009 | GIF 1052×21 · alpha plate |
| Game.pak | im08 | `mux2` | `im08/Multiplier x2 IC[mux2].gif` | 8,149 | GIF 1052×21 · colour plate |
| Game.pak | im08 | `MUX3` | `im08/Multiplier x3 IA[MUX3].gif` | 4,205 | GIF 1052×21 · alpha plate |
| Game.pak | im08 | `mux3` | `im08/Multiplier x3 IC[mux3].gif` | 8,732 | GIF 1052×21 · colour plate |
| Game.pak | im08 | `MUX4` | `im08/Multiplier x4 IA[MUX4].gif` | 3,936 | GIF 1052×21 · alpha plate |
| Game.pak | im08 | `mux4` | `im08/Multiplier x4 IC[mux4].gif` | 7,980 | GIF 1052×21 · colour plate |
| Game.pak | im08 | `MUX5` | `im08/Multiplier x5 IA[MUX5].gif` | 4,127 | GIF 1052×21 · alpha plate |
| Game.pak | im08 | `mux5` | `im08/Multiplier x5 IC[mux5].gif` | 8,662 | GIF 1052×21 · colour plate |
| Game.pak | im08 | `PBBU` | `im08/Photon Beam Bullet IA[PBBU].gif` | 4,888 | GIF 830×25 · alpha plate |
| Game.pak | im08 | `pbbu` | `im08/Photon Beam Bullet IC[pbbu].gif` | 4,599 | GIF 830×25 · colour plate |
| Game.pak | im08 | `PHBE` | `im08/Photon Beam IA[PHBE].gif` | 4,436 | GIF 235×75 · alpha plate |
| Game.pak | im08 | `phbe` | `im08/Photon Beam IC[phbe].gif` | 7,673 | GIF 235×75 · colour plate |
| Game.pak | im08 | `PDBU` | `im08/Plasma Drone Bull IA[PDBU].gif` | 5,042 | GIF 866×26 · alpha plate |
| Game.pak | im08 | `pdbu` | `im08/Plasma Drone Bull IC[pdbu].gif` | 8,901 | GIF 866×26 · colour plate |
| Game.pak | im08 | `PDLI` | `im08/Plasma Drone Light IA[PDLI].gif` | 3,527 | GIF 172×75 · alpha plate |
| Game.pak | im08 | `pdli` | `im08/Plasma Drone LIght IC[pdli].gif` | 6,363 | GIF 172×75 · colour plate |
| Game.pak | im08 | `PLSH` | `im08/Player Shields IA[PLSH].gif` | 11,928 | GIF 666×85 · alpha plate |
| Game.pak | im08 | `plsh` | `im08/Player Shields IC[plsh].gif` | 36,230 | GIF 666×85 · colour plate |
| Game.pak | im08 | `PTBU` | `im08/Pulse Tank Bullet IA[PTBU].gif` | 4,452 | GIF 830×25 · alpha plate |
| Game.pak | im08 | `ptbu` | `im08/Pulse Tank Bullet IC[ptbu].gif` | 4,782 | GIF 830×25 · colour plate |
| Game.pak | im08 | `PTLI` | `im08/Pulse Tank Lightin IA[PTLI].gif` | 3,187 | GIF 300×75 · alpha plate |
| Game.pak | im08 | `ptli` | `im08/Pulse Tank Lightin IC[ptli].gif` | 3,084 | GIF 300×75 · colour plate |
| Game.pak | im08 | `SPLA` | `im08/Splash IA[SPLA].gif` | 2,680 | GIF 172×36 · alpha plate |
| Game.pak | im08 | `spla` | `im08/Splash IC[spla].gif` | 746 | GIF 172×36 · colour plate |
| Game.pak | im08 | `TURA` | `im08/Turret - Radar IA[TURA].gif` | 4,912 | GIF 1082×32 · alpha plate |
| Game.pak | im08 | `tura` | `im08/Turret - Radar IC[tura].gif` | 15,393 | GIF 1082×32 · colour plate |
| Game.pak | im08 | `VIGR` | `im08/Video Grid IA[VIGR].gif` | 8,005 | GIF 302×92 · alpha plate |
| Game.pak | im08 | `vigr` | `im08/Video Grid IC[vigr].gif` | 1,490 | GIF 302×92 · colour plate |
| Game.pak | im08 | `ZBBL` | `im08/Zapper Bullet Blue IA[ZBBL].gif` | 4,903 | GIF 830×25 · alpha plate |
| Game.pak | im08 | `zbbl` | `im08/Zapper Bullet Blue IC[zbbl].gif` | 5,695 | GIF 830×25 · colour plate |
| Game.pak | im08 | `ZBLI` | `im08/Zapper Bullet Ligh IA[ZBLI].gif` | 3,040 | GIF 300×75 · alpha plate |
| Game.pak | im08 | `zbli` | `im08/Zapper Bullet Ligh IC[zbli].gif` | 4,940 | GIF 300×75 · colour plate |
| Game.pak | im08 | `EDBU` | `im08/Editor Buttons IA[EDBU].gif` | 834 | GIF 400×27 · alpha plate |
| Game.pak | im08 | `edbu` | `im08/Editor Buttons IC[edbu].gif` | 2,996 | GIF 400×27 · colour plate |
| Game.pak | im16 | `jup2` | `im16/Jungle 2 Preview[jup2].TGA` | 89,396 | TGA 146×306 |
| Game.pak | im16 | `lese` | `im16/Level Selection[lese].TGA` | 614,418 | TGA 640×480 |
| Game.pak | im16 | `scor` | `im16/Scorebar[scor].TGA` | 153,618 | TGA 160×480 |
| Game.pak | im08 | `BASE` | `im08/Base IA[BASE].gif` | 9,090 | GIF 1119×131 · alpha plate |
| Game.pak | im08 | `base` | `im08/Base IC[base].gif` | 71,650 | GIF 1119×131 · colour plate |
| Game.pak | im08 | `CAIR` | `im08/Cap - Iris IA[CAIR].gif` | 2,466 | GIF 321×31 · alpha plate |
| Game.pak | im08 | `cair` | `im08/Cap - Iris IC[cair].gif` | 5,303 | GIF 321×31 · colour plate |
| Game.pak | im08 | `CASL` | `im08/Cash - Silver Larg IA[CASL].gif` | 3,614 | GIF 752×27 · alpha plate |
| Game.pak | im08 | `casl` | `im08/Cash - Silver Larg IC[casl].gif` | 11,697 | GIF 752×27 · colour plate |
| Game.pak | im08 | `CASS` | `im08/Cash - Silver Smal IA[CASS].gif` | 2,801 | GIF 572×21 · alpha plate |
| Game.pak | im08 | `cass` | `im08/Cash - Silver Smal IC[cass].gif` | 7,158 | GIF 572×21 · colour plate |
| Game.pak | im08 | `CYCL` | `im08/Cyclops IA[CYCL].gif` | 4,869 | GIF 1190×35 · alpha plate |
| Game.pak | im08 | `cycl` | `im08/Cyclops IC[cycl].gif` | 24,744 | GIF 1190×35 · colour plate |
| Game.pak | im08 | `EXLG` | `im08/Explosion - Large IA[EXLG].gif` | 11,651 | GIF 758×90 · alpha plate |
| Game.pak | im08 | `exlg` | `im08/Explosion - Large IC[exlg].gif` | 28,189 | GIF 758×90 · colour plate |
| Game.pak | im08 | `FLUP` | `im08/Flipper Flip Up IA[FLUP].gif` | 5,466 | GIF 1202×34 · alpha plate |
| Game.pak | im08 | `flup` | `im08/Flipper Flip Up IC[flup].gif` | 20,224 | GIF 1202×34 · colour plate |
| Game.pak | im08 | `FLNO` | `im08/Flipper North IA[FLNO].gif` | 9,275 | GIF 1282×66 · alpha plate |
| Game.pak | im08 | `flno` | `im08/Flipper North IC[flno].gif` | 31,949 | GIF 1282×66 · colour plate |
| Game.pak | im08 | `FLSO` | `im08/Flipper South IA[FLSO].gif` | 7,891 | GIF 1282×66 · alpha plate |
| Game.pak | im08 | `flso` | `im08/Flipper South IC[flso].gif` | 24,578 | GIF 1282×66 · colour plate |
| Game.pak | im08 | `GLOW` | `im08/Glows IA[GLOW].gif` | 16,197 | GIF 850×102 · alpha plate |
| Game.pak | im08 | `glow` | `im08/Glows IC[glow].gif` | 15,380 | GIF 850×102 · colour plate |
| Game.pak | im08 | `JGBU` | `im08/Juno Gun - Bullet IA[JGBU].gif` | 4,771 | GIF 866×26 · alpha plate |
| Game.pak | im08 | `jgbu` | `im08/Juno Gun - Bullet IC[jgbu].gif` | 4,580 | GIF 866×26 · colour plate |
| Game.pak | im08 | `JGLI` | `im08/Juno Gun - Light IA[JGLI].gif` | 2,082 | GIF 80×75 · alpha plate |
| Game.pak | im08 | `jgli` | `im08/Juno Gun - Light IC[jgli].gif` | 2,138 | GIF 80×75 · colour plate |
| Game.pak | im08 | `LAPB` | `im08/Laser Plat - Bull IA[LAPB].gif` | 5,934 | GIF 1010×30 · alpha plate |
| Game.pak | im08 | `lapb` | `im08/Laser Plat - Bull IC[lapb].gif` | 7,161 | GIF 1010×30 · colour plate |
| Game.pak | im08 | `MEBH` | `im08/Menu Buttons Hilit IA[MEBH].gif` | 11,299 | GIF 1400×30 · alpha plate |
| Game.pak | im08 | `mebh` | `im08/Menu Buttons Hilit IC[mebh].gif` | 19,149 | GIF 1400×30 · colour plate |
| Game.pak | im08 | `MEBU` | `im08/Menu Buttons IA[MEBU].gif` | 5,884 | GIF 667×58 · alpha plate |
| Game.pak | im08 | `mebu` | `im08/Menu Buttons IC[mebu].gif` | 19,430 | GIF 667×58 · colour plate |
| Game.pak | im08 | `PILI` | `im08/Pickup - Life IA[PILI].gif` | 17,543 | GIF 1249×88 · alpha plate |
| Game.pak | im08 | `pili` | `im08/Pickup - Life IC[pili].gif` | 44,914 | GIF 1249×88 · colour plate |
| Game.pak | im08 | `PIMU` | `im08/Pickup - Multiplie IA[PIMU].gif` | 15,033 | GIF 1249×88 · alpha plate |
| Game.pak | im08 | `pimu` | `im08/Pickup - Multiplie IC[pimu].gif` | 37,742 | GIF 1249×88 · colour plate |
| Game.pak | im08 | `PISH` | `im08/Pickup - Shields IA[PISH].gif` | 15,658 | GIF 1249×88 · alpha plate |
| Game.pak | im08 | `pish` | `im08/Pickup - Shields IC[pish].gif` | 38,125 | GIF 1249×88 · colour plate |
| Game.pak | im08 | `PBHF` | `im08/Plasma Bomb Hit FX IA[PBHF].gif` | 2,110 | GIF 235×75 · alpha plate |
| Game.pak | im08 | `pbhf` | `im08/Plasma Bomb Hit FX IC[pbhf].gif` | 3,466 | GIF 235×75 · colour plate |
| Game.pak | im08 | `PBTA` | `im08/Plasma Bomb Target IA[PBTA].gif` | 1,080 | GIF 51×18 · alpha plate |
| Game.pak | im08 | `pbta` | `im08/Plasma Bomb Target IC[pbta].gif` | 1,028 | GIF 51×18 · colour plate |
| Game.pak | im08 | `PLGU` | `im08/Platform Gun IA[PLGU].gif` | 8,968 | GIF 1249×88 · alpha plate |
| Game.pak | im08 | `plgu` | `im08/Platform Gun IC[plgu].gif` | 33,117 | GIF 1249×88 · colour plate |
| Game.pak | im08 | `PLAT` | `im08/Platform IA[PLAT].gif` | 8,712 | GIF 1170×126 · alpha plate |
| Game.pak | im08 | `plat` | `im08/Platform IC[plat].gif` | 61,643 | GIF 1170×126 · colour plate |
| Game.pak | im08 | `PL1B` | `im08/Player 1 Blue IA[PL1B].gif` | 3,636 | GIF 394×48 · alpha plate |
| Game.pak | im08 | `pl1b` | `im08/Player 1 Blue IC[pl1b].gif` | 12,161 | GIF 394×48 · colour plate |
| Game.pak | im08 | `PL1C` | `im08/Player 1 Cyan IA[PL1C].gif` | 3,493 | GIF 394×48 · alpha plate |
| Game.pak | im08 | `pl1c` | `im08/Player 1 Cyan IC[pl1c].gif` | 11,648 | GIF 394×48 · colour plate |
| Game.pak | im08 | `PL1G` | `im08/Player 1 Green IA[PL1G].gif` | 3,485 | GIF 394×48 · alpha plate |
| Game.pak | im08 | `pl1g` | `im08/Player 1 Green IC[pl1g].gif` | 11,502 | GIF 394×48 · colour plate |
| Game.pak | im08 | `PL1O` | `im08/Player 1 Orange IA[PL1O].gif` | 3,482 | GIF 394×48 · alpha plate |
| Game.pak | im08 | `pl1o` | `im08/Player 1 Orange IC[pl1o].gif` | 11,418 | GIF 394×48 · colour plate |
| Game.pak | im08 | `PL2B` | `im08/Player 2 Blue IA[PL2B].gif` | 3,559 | GIF 394×48 · alpha plate |
| Game.pak | im08 | `pl2b` | `im08/Player 2 Blue IC[pl2b].gif` | 11,374 | GIF 394×48 · colour plate |
| Game.pak | im08 | `PL2C` | `im08/Player 2 Cyan IA[PL2C].gif` | 3,487 | GIF 394×48 · alpha plate |
| Game.pak | im08 | `pl2c` | `im08/Player 2 Cyan IC[pl2c].gif` | 10,963 | GIF 394×48 · colour plate |
| Game.pak | im08 | `PL2G` | `im08/Player 2 Green IA[PL2G].gif` | 3,491 | GIF 394×48 · alpha plate |
| Game.pak | im08 | `pl2g` | `im08/Player 2 Green IC[pl2g].gif` | 11,094 | GIF 394×48 · colour plate |
| Game.pak | im08 | `PL2O` | `im08/Player 2 Orange IA[PL2O].gif` | 3,470 | GIF 394×48 · alpha plate |
| Game.pak | im08 | `pl2o` | `im08/Player 2 Orange IC[pl2o].gif` | 11,129 | GIF 394×48 · colour plate |
| Game.pak | im08 | `PLAY` | `im08/Players IA[PLAY].gif` | 1,911 | GIF 84×44 · alpha plate |
| Game.pak | im08 | `POLB` | `im08/Popup - Large Bull IA[POLB].gif` | 8,137 | GIF 1190×35 · alpha plate |
| Game.pak | im08 | `polb` | `im08/Popup - Large Bull IC[polb].gif` | 12,646 | GIF 1190×35 · colour plate |
| Game.pak | im08 | `PLLI` | `im08/Popup - Large Ligh IA[PLLI].gif` | 2,226 | GIF 80×75 · alpha plate |
| Game.pak | im08 | `plli` | `im08/Popup - Large Ligh IC[plli].gif` | 2,484 | GIF 80×75 · colour plate |
| Game.pak | im08 | `PLBA` | `im08/Popup Large - Base IA[PLBA].gif` | 1,189 | GIF 50×50 · alpha plate |
| Game.pak | im08 | `plba` | `im08/Popup Large - Base IC[plba].gif` | 2,241 | GIF 50×50 · colour plate |
| Game.pak | im08 | `POLO` | `im08/Popup Large - Open IA[POLO].gif` | 6,033 | GIF 1154×50 · alpha plate |
| Game.pak | im08 | `polo` | `im08/Popup Large - Open IC[polo].gif` | 21,089 | GIF 1154×50 · colour plate |
| Game.pak | im08 | `POLR` | `im08/Popup Large - Rot IA[POLR].gif` | 9,025 | GIF 1250×98 · alpha plate |
| Game.pak | im08 | `polr` | `im08/Popup Large - Rot IC[polr].gif` | 32,165 | GIF 1250×98 · colour plate |
| Game.pak | im08 | `SHME` | `im08/Shield Meter IA[SHME].gif` | 1,006 | GIF 300×20 · alpha plate |
| Game.pak | im08 | `SUTA` | `im08/Super Tank IA[SUTA].gif` | 7,364 | GIF 1190×55 · alpha plate |
| Game.pak | im08 | `SGBU` | `im08/Swivel Gun - Bulle IA[SGBU].gif` | 5,675 | GIF 974×29 · alpha plate |
| Game.pak | im08 | `sgbu` | `im08/Swivel Gun - Bulle IC[sgbu].gif` | 6,875 | GIF 974×29 · colour plate |
| Game.pak | im08 | `SGPL` | `im08/Swivel Gun - Plat IA[SGPL].gif` | 1,180 | GIF 50×50 · alpha plate |
| Game.pak | im08 | `sgpl` | `im08/Swivel Gun - Plat IC[sgpl].gif` | 2,326 | GIF 50×50 · colour plate |
| Game.pak | im08 | `SWGU` | `im08/Swivel Gun IA[SWGU].gif` | 9,207 | GIF 1250×98 · alpha plate |
| Game.pak | im08 | `swgu` | `im08/Swivel Gun IC[swgu].gif` | 33,930 | GIF 1250×98 · colour plate |
| Game.pak | im08 | `TUIC` | `im08/Turret - Ion Cann IA[TUIC].gif` | 7,562 | GIF 1256×78 · alpha plate |
| Game.pak | im08 | `tuic` | `im08/Turret - Ion Cann IC[tuic].gif` | 23,654 | GIF 1256×78 · colour plate |
| Game.pak | im08 | `TULA` | `im08/Turret - Laser IA[TULA].gif` | 8,002 | GIF 1256×78 · alpha plate |
| Game.pak | im08 | `tula` | `im08/Turret - Laser IC[tula].gif` | 28,612 | GIF 1256×78 · colour plate |
| Game.pak | im08 | `WESY` | `im08/Weapon Symbols IA[WESY].gif` | 2,083 | GIF 300×31 · alpha plate |
| Game.pak | im08 | `wesy` | `im08/Weapon Symbols IC[wesy].gif` | 4,840 | GIF 300×31 · colour plate |
| Game.pak | im08 | `ZACA` | `im08/Zapper - Caps IA[ZACA].gif` | 1,137 | GIF 116×16 · alpha plate |
| Game.pak | im08 | `zaca` | `im08/Zapper - Caps IC[zaca].gif` | 1,272 | GIF 116×16 · colour plate |
| Game.pak | im08 | `play` | `im08/Players IC[play].gif` | 3,273 | GIF 84×44 · colour plate |
| Game.pak | im08 | `shme` | `im08/Shield Meter IC[shme].gif` | 3,072 | GIF 300×20 · colour plate |
| Game.pak | im08 | `suta` | `im08/Super Tank IC[suta].gif` | 42,981 | GIF 1190×55 · colour plate |
| Game.pak | im08 | `BHRO` | `im08/BlackHawk Rotate IA[BHRO].gif` | 10,984 | GIF 1262×92 · alpha plate |
| Game.pak | im08 | `bhro` | `im08/BlackHawk Rotate IC[bhro].gif` | 30,633 | GIF 1262×92 · colour plate |
| Game.pak | im08 | `BSBA` | `im08/Bonus Station - Ba IA[BSBA].gif` | 6,192 | GIF 1202×52 · alpha plate |
| Game.pak | im08 | `bsba` | `im08/Bonus Station - Ba IC[bsba].gif` | 32,879 | GIF 1202×52 · colour plate |
| Game.pak | im08 | `BSBU` | `im08/Bonus Station - Bu IA[BSBU].gif` | 2,698 | GIF 482×32 · alpha plate |
| Game.pak | im08 | `bsbu` | `im08/Bonus Station - Bu IC[bsbu].gif` | 10,490 | GIF 482×32 · colour plate |
| Game.pak | im08 | `CAME` | `im08/Cap - Metal IA[CAME].gif` | 1,567 | GIF 300×31 · alpha plate |
| Game.pak | im08 | `came` | `im08/Cap - Metal IC[came].gif` | 3,324 | GIF 300×31 · colour plate |
| Game.pak | im08 | `CAGL` | `im08/Cash - Gold Large IA[CAGL].gif` | 6,333 | GIF 992×35 · alpha plate |
| Game.pak | im08 | `cagl` | `im08/Cash - Gold Large IC[cagl].gif` | 22,995 | GIF 992×35 · colour plate |
| Game.pak | im08 | `CAGS` | `im08/Cash - Gold Small IA[CAGS].gif` | 4,955 | GIF 812×29 · alpha plate |
| Game.pak | im08 | `cags` | `im08/Cash - Gold Small IC[cags].gif` | 16,573 | GIF 812×29 · colour plate |
| Game.pak | im08 | `ROTO` | `im08/Rotor IA[ROTO].gif` | 2,476 | GIF 146×74 · alpha plate |
| Game.pak | im08 | `roto` | `im08/Rotor IC[roto].gif` | 3,073 | GIF 146×74 · colour plate |
| Game.pak | im08 | `SCSO` | `im08/Screw South IA[SCSO].gif` | 8,159 | GIF 1190×45 · alpha plate |
| Game.pak | im08 | `scso` | `im08/Screw South IC[scso].gif` | 23,070 | GIF 1190×45 · colour plate |
| Game.pak | im08 | `SHST` | `im08/Shield Station IA[SHST].gif` | 2,698 | GIF 482×32 · alpha plate |
| Game.pak | im08 | `shst` | `im08/Shield Station IC[shst].gif` | 9,769 | GIF 482×32 · colour plate |
| Game.pak | im08 | `SHRL` | `im08/Shuriken Rot Large IA[SHRL].gif` | 2,573 | GIF 272×47 · alpha plate |
| Game.pak | im08 | `shrl` | `im08/Shuriken Rot Large IC[shrl].gif` | 5,810 | GIF 272×47 · colour plate |
| Game.pak | im08 | `SHRO` | `im08/Shuriken Rotation IA[SHRO].gif` | 2,041 | GIF 200×37 · alpha plate |
| Game.pak | im08 | `shro` | `im08/Shuriken Rotation IC[shro].gif` | 4,478 | GIF 200×37 · colour plate |
| Game.pak | im08 | `TUFL` | `im08/Turret - Flare IA[TUFL].gif` | 9,862 | GIF 1271×96 · alpha plate |
| Game.pak | im08 | `tufl` | `im08/Turret - Flare IC[tufl].gif` | 44,679 | GIF 1271×96 · colour plate |
| Game.pak | im08 | `TUTW` | `im08/Turret - Twin IA[TUTW].gif` | 9,960 | GIF 1271×96 · alpha plate |
| Game.pak | im08 | `tutw` | `im08/Turret - Twin IC[tutw].gif` | 41,462 | GIF 1271×96 · colour plate |
| Game.pak | im16 | `cam3` | `im16/Canyon 3 Map[cam3].TGA` | 3,456,018 | TGA 480×3600 |
| Game.pak | im16 | `cap3` | `im16/Canyon 3 Preview[cap3].TGA` | 89,396 | TGA 146×306 |
| Game.pak | im16 | `cat3` | `im16/Canyon 3 Media[cat3].TGA` | 138,258 | TGA 96×720 |
| Game.pak | im16 | `ism3` | `im16/Island 3 Map[ism3].TGA` | 3,456,018 | TGA 480×3600 |
| Game.pak | im16 | `ist3` | `im16/Island 3 Media[ist3].TGA` | 138,258 | TGA 96×720 |
| Game.pak | im16 | `isp3` | `im16/Island 3 Preview[isp3].TGA` | 89,396 | TGA 146×306 |
| Game.pak | im16 | `jum1` | `im16/Jungle 1 Map[jum1].TGA` | 3,456,018 | TGA 480×3600 |
| Game.pak | im16 | `jut1` | `im16/Jungle 1 Media[jut1].TGA` | 138,258 | TGA 96×720 |
| Game.pak | im16 | `jup1` | `im16/Jungle 1 Preview[jup1].TGA` | 89,396 | TGA 146×306 |
| Game.pak | im08 | `CAST` | `im08/Cash Station IA[CAST].gif` | 2,698 | GIF 482×32 · alpha plate |
| Game.pak | im08 | `cast` | `im08/Cash Station IC[cast].gif` | 9,347 | GIF 482×32 · colour plate |
| Game.pak | im08 | `ELST` | `im08/Extra Life Station IA[ELST].gif` | 2,695 | GIF 466×31 · alpha plate |
| Game.pak | im08 | `elst` | `im08/Extra Life Station IC[elst].gif` | 9,486 | GIF 466×31 · colour plate |
| Game.pak | im08 | `FLAS` | `im08/Flash IA[FLAS].gif` | 5,139 | GIF 452×47 · alpha plate |
| Game.pak | im08 | `flas` | `im08/Flash IC[flas].gif` | 6,875 | GIF 452×47 · colour plate |
| Game.pak | im08 | `NOTI` | `im08/Notices IA[NOTI].gif` | 4,779 | GIF 1200×37 · alpha plate |
| Game.pak | im08 | `noti` | `im08/Notices IC[noti].gif` | 19,201 | GIF 1200×37 · colour plate |
| Game.pak | im08 | `NGBU` | `im08/Nuke Gun Bullet IA[NGBU].gif` | 13,320 | GIF 1273×84 · alpha plate |
| Game.pak | im08 | `ngbu` | `im08/Nuke Gun Bullet IC[ngbu].gif` | 13,313 | GIF 1273×84 · colour plate |
| Game.pak | im08 | `NGLI` | `im08/Nuke Gun Lighting IA[NGLI].gif` | 3,388 | GIF 172×75 · alpha plate |
| Game.pak | im08 | `ngli` | `im08/Nuke Gun Lighting IC[ngli].gif` | 5,015 | GIF 172×75 · colour plate |
| Game.pak | im08 | `NGSH` | `im08/Nuke Gun Shields IA[NGSH].gif` | 5,563 | GIF 818×53 · alpha plate |
| Game.pak | im08 | `ngsh` | `im08/Nuke Gun Shields IC[ngsh].gif` | 18,836 | GIF 818×53 · colour plate |
| Game.pak | im08 | `NSBA` | `im08/Nuke Station Back IA[NSBA].gif` | 1,456 | GIF 626×41 · alpha plate |
| Game.pak | im08 | `nsba` | `im08/Nuke Station Back IC[nsba].gif` | 2,039 | GIF 626×41 · colour plate |
| Game.pak | im08 | `NUST` | `im08/Nuke Station IA[NUST].gif` | 2,756 | GIF 434×29 · alpha plate |
| Game.pak | im08 | `nust` | `im08/Nuke Station IC[nust].gif` | 7,744 | GIF 434×29 · colour plate |
| Game.pak | im08 | `PANZ` | `im08/Panzer IA[PANZ].gif` | 9,960 | GIF 1256×116 · alpha plate |
| Game.pak | im08 | `panz` | `im08/Panzer IC[panz].gif` | 44,864 | GIF 1256×116 · colour plate |
| Game.pak | im08 | `PI1K` | `im08/Pickup - 1000 IA[PI1K].gif` | 5,270 | GIF 1262×36 · alpha plate |
| Game.pak | im08 | `pi1k` | `im08/Pickup - 1000 IC[pi1k].gif` | 13,661 | GIF 1262×36 · colour plate |
| Game.pak | im08 | `PI2K` | `im08/Pickup - 2000 IA[PI2K].gif` | 5,583 | GIF 1274×38 · alpha plate |
| Game.pak | im08 | `pi2k` | `im08/Pickup - 2000 IC[pi2k].gif` | 16,551 | GIF 1274×38 · colour plate |
| Game.pak | im08 | `P500` | `im08/Pickup - 500 IA[P500].gif` | 4,401 | GIF 1172×20 · alpha plate |
| Game.pak | im08 | `p500` | `im08/Pickup - 500 IC[p500].gif` | 12,262 | GIF 1172×20 · colour plate |
| Game.pak | im08 | `PI5K` | `im08/Pickup - 5000 IA[PI5K].gif` | 6,804 | GIF 1262×44 · alpha plate |
| Game.pak | im08 | `pi5k` | `im08/Pickup - 5000 IC[pi5k].gif` | 22,327 | GIF 1262×44 · colour plate |
| Game.pak | im08 | `PSBA` | `im08/Popup Small - Base IA[PSBA].gif` | 1,057 | GIF 34×34 · alpha plate |
| Game.pak | im08 | `psba` | `im08/Popup Small - Base IC[psba].gif` | 1,647 | GIF 34×34 · colour plate |
| Game.pak | im08 | `SMOP` | `im08/Popup Small - Open IA[SMOP].gif` | 3,901 | GIF 770×34 · alpha plate |
| Game.pak | im08 | `smop` | `im08/Popup Small - Open IC[smop].gif` | 12,487 | GIF 770×34 · colour plate |
| Game.pak | im08 | `PSRO` | `im08/Popup Small - Rot IA[PSRO].gif` | 4,759 | GIF 1154×34 · alpha plate |
| Game.pak | im08 | `psro` | `im08/Popup Small - Rot IC[psro].gif` | 20,258 | GIF 1154×34 · colour plate |
| Game.pak | im08 | `RARO` | `im08/Raider Rotate IA[RARO].gif` | 10,332 | GIF 1273×84 · alpha plate |
| Game.pak | im08 | `raro` | `im08/Raider Rotate IC[raro].gif` | 27,728 | GIF 1273×84 · colour plate |
| Game.pak | im08 | `RASO` | `im08/Raider South IA[RASO].gif` | 9,055 | GIF 1273×84 · alpha plate |
| Game.pak | im08 | `raso` | `im08/Raider South IC[raso].gif` | 24,479 | GIF 1273×84 · colour plate |
| Game.pak | im08 | `RGDR` | `im08/Rear Gun Drone IA[RGDR].gif` | 2,440 | GIF 338×23 · alpha plate |
| Game.pak | im08 | `rgdr` | `im08/Rear Gun Drone IC[rgdr].gif` | 5,047 | GIF 338×23 · colour plate |
| Game.pak | im08 | `REGU` | `im08/Rear Gun IA[REGU].gif` | 4,601 | GIF 218×75 · alpha plate |
| Game.pak | im08 | `regu` | `im08/Rear Gun IC[regu].gif` | 7,430 | GIF 218×75 · colour plate |
| Game.pak | im08 | `SCBU` | `im08/Scatter Bullet IA[SCBU].gif` | 5,747 | GIF 1010×30 · alpha plate |
| Game.pak | im08 | `scbu` | `im08/Scatter Bullet IC[scbu].gif` | 7,534 | GIF 1010×30 · colour plate |
| Game.pak | im08 | `SCDR` | `im08/Screw Drone IA[SCDR].gif` | 2,407 | GIF 338×23 · alpha plate |
| Game.pak | im08 | `scdr` | `im08/Screw Drone IC[scdr].gif` | 4,219 | GIF 338×23 · colour plate |
| Game.pak | im08 | `SMBU` | `im08/Screw Maul Bullet IA[SMBU].gif` | 3,846 | GIF 686×21 · alpha plate |
| Game.pak | im08 | `smbu` | `im08/Screw Maul Bullet IC[smbu].gif` | 3,797 | GIF 686×21 · colour plate |
| Game.pak | im08 | `SC02` | `im08/Screw Mk 2 IA[SC02].gif` | 9,587 | GIF 1226×50 · alpha plate |
| Game.pak | im08 | `sc02` | `im08/Screw Mk 2 IC[sc02].gif` | 26,255 | GIF 1226×50 · colour plate |
| Game.pak | im08 | `SC03` | `im08/Screw Mk 3 IA[SC03].gif` | 8,960 | GIF 1226×48 · alpha plate |
| Game.pak | im08 | `sc03` | `im08/Screw Mk 3 IC[sc03].gif` | 23,738 | GIF 1226×48 · colour plate |
| Game.pak | im08 | `TUSC` | `im08/Turret - Scatter IA[TUSC].gif` | 8,520 | GIF 1250×80 · alpha plate |
| Game.pak | im08 | `tusc` | `im08/Turret - Scatter IC[tusc].gif` | 32,624 | GIF 1250×80 · colour plate |
| Game.pak | im16 | `inm1` | `im16/Industrial 1 Map[inm1].TGA` | 3,456,018 | TGA 480×3600 |
| Game.pak | im16 | `int1` | `im16/Industrial 1 Media[int1].TGA` | 138,258 | TGA 96×720 |
| Game.pak | im16 | `inp1` | `im16/Industrial 1 Preview[inp1].TGA` | 89,396 | TGA 146×306 |
| Game.pak | im16 | `ism1` | `im16/Island 1 Map[ism1].TGA` | 3,456,018 | TGA 480×3600 |
| Game.pak | im16 | `ist1` | `im16/Island 1 Media[ist1].TGA` | 138,258 | TGA 96×720 |
| Game.pak | im16 | `isp1` | `im16/Island 1 Preview[isp1].TGA` | 89,396 | TGA 146×306 |
| Game.pak | im16 | `jum3` | `im16/Jungle 3 Map[jum3].TGA` | 3,456,018 | TGA 480×3600 |
| Game.pak | im16 | `jut3` | `im16/Jungle 3 Media[jut3].TGA` | 138,258 | TGA 96×720 |
| Game.pak | im16 | `jup3` | `im16/Jungle 3 Preview[jup3].TGA` | 89,396 | TGA 146×306 |
| Game.pak | im16 | `cam2` | `im16/Canyon 2 Map[cam2].TGA` | 3,456,018 | TGA 480×3600 |
| Game.pak | im16 | `cap2` | `im16/Canyon 2 Preview[cap2].TGA` | 89,396 | TGA 146×306 |
| Game.pak | im16 | `cat2` | `im16/Canyon 2 Media[cat2].TGA` | 138,258 | TGA 96×720 |
| Game.pak | coli | `gaco` | `coli/Colors[gaco].coli` | 30 | 1 colours |
| Game.pak | flli | `gafl` | `flli/Game[gafl].flli` | 8,229 | 220 floats |
| Game.pak | idli | `edit` | `idli/Editor[edit].idli` | 37 | 1 IDs |
| Game.pak | idli | `tesp` | `idli/Fonts[tesp].idli` | 37 | 3 IDs |
| Game.pak | idli | `gate` | `idli/Formats[gate].idli` | 1,729 | 54 IDs |
| Game.pak | idli | `gaob` | `idli/Objects[gaob].idli` | 1,191 | 40 IDs |
| Game.pak | idli | `gaso` | `idli/Sounds[gaso].idli` | 695 | 24 IDs |
| Game.pak | idli | `gasp` | `idli/Sprites[gasp].idli` | 250 | 8 IDs |
| Game.pak | im08 | `BEBU` | `im08/Beamer Bullet IA[BEBU].gif` | 2,402 | GIF 338×23 · alpha plate |
| Game.pak | im08 | `bebu` | `im08/Beamer Bullet IC[bebu].gif` | 4,255 | GIF 338×23 · colour plate |
| Game.pak | im08 | `BELI` | `im08/Beamer Light IA[BELI].gif` | 1,476 | GIF 45×45 · alpha plate |
| Game.pak | im08 | `beli` | `im08/Beamer Light IC[beli].gif` | 1,758 | GIF 45×45 · colour plate |
| Game.pak | im08 | `CS02` | `im08/Cash Station 2 IA[CS02].gif` | 2,691 | GIF 482×32 · alpha plate |
| Game.pak | im08 | `cs02` | `im08/Cash Station 2 IC[cs02].gif` | 11,070 | GIF 482×32 · colour plate |
| Game.pak | im08 | `EDPR` | `im08/Editor Previews IA[EDPR].gif` | 5,120 | GIF 1000×37 · alpha plate |
| Game.pak | im08 | `edpr` | `im08/Editor Previews IC[edpr].gif` | 18,227 | GIF 1000×37 · colour plate |
| Game.pak | im08 | `LENA` | `im08/Level Names IA[LENA].gif` | 8,281 | GIF 1068×56 · alpha plate |
| Game.pak | im08 | `lena` | `im08/Level Names IC[lena].gif` | 33,903 | GIF 1068×56 · colour plate |
| Game.pak | im08 | `NOMC` | `im08/Notice - Mission IA[NOMC].gif` | 4,078 | GIF 188×92 · alpha plate |
| Game.pak | im08 | `nomc` | `im08/Notice - Mission IC[nomc].gif` | 9,756 | GIF 188×92 · colour plate |
| Game.pak | im08 | `TUBE` | `im08/Turret - Beamer IA[TUBE].gif` | 10,207 | GIF 1271×96 · alpha plate |
| Game.pak | im08 | `tube` | `im08/Turret - Beamer IC[tube].gif` | 42,975 | GIF 1271×96 · colour plate |
| Game.pak | im08 | `TUSH` | `im08/Turret - Shredder IA[TUSH].gif` | 8,247 | GIF 1250×80 · alpha plate |
| Game.pak | im08 | `tush` | `im08/Turret - Shredder IC[tush].gif` | 32,828 | GIF 1250×80 · colour plate |
| Game.pak | im16 | `cam1` | `im16/Canyon 1 Map[cam1].TGA` | 3,456,018 | TGA 480×3600 |
| Game.pak | im16 | `cap1` | `im16/Canyon 1 Preview[cap1].TGA` | 89,396 | TGA 146×306 |
| Game.pak | im16 | `inm2` | `im16/Industrial 2 Map[inm2].TGA` | 3,456,018 | TGA 480×3600 |
| Game.pak | im16 | `int2` | `im16/Industrial 2 Media[int2].TGA` | 138,258 | TGA 96×720 |
| Game.pak | im16 | `inp2` | `im16/Industrial 2 Preview[inp2].TGA` | 89,396 | TGA 146×306 |
| Game.pak | im16 | `inm3` | `im16/Industrial 3 Map[inm3].TGA` | 3,456,018 | TGA 480×3600 |
| Game.pak | im16 | `int3` | `im16/Industrial 3 Media[int3].TGA` | 138,258 | TGA 96×720 |
| Game.pak | im16 | `inp3` | `im16/Industrial 3 Preview[inp3].TGA` | 89,396 | TGA 146×306 |
| Game.pak | im16 | `jum2` | `im16/Jungle 2 Map[jum2].TGA` | 3,456,018 | TGA 480×3600 |
| Game.pak | im16 | `jut2` | `im16/Jungle 2 Media[jut2].TGA` | 138,258 | TGA 96×720 |
| Game.pak | leve | `le01` | `leve/Level 01[le01].leve` | 7,268 | level "Kepler Massif" · 46 objects |
| Game.pak | leve | `le02` | `leve/Level 02[le02].leve` | 6,958 | level "Darius" · 44 objects |
| Game.pak | leve | `le03` | `leve/Level 03[le03].leve` | 6,974 | level "Ticonderoga" · 44 objects |
| Game.pak | leve | `le04` | `leve/Level 04[le04].leve` | 6,807 | level "Bellerephon" · 43 objects |
| Game.pak | leve | `le05` | `leve/Level 05[le05].leve` | 8,016 | level "Yucatan Rift" · 51 objects |
| Game.pak | leve | `le06` | `leve/Level 06[le06].leve` | 6,818 | level "Cydonia Plateau" · 43 objects |
| Game.pak | leve | `le07` | `leve/Level 07[le07].leve` | 6,116 | level "Mariner Valley" · 38 objects |
| Game.pak | leve | `le08` | `leve/Level 08[le08].leve` | 7,736 | level "Neo Kowloon" · 49 objects |
| Game.pak | leve | `le11` | `leve/Level 11[le11].leve` | 6,366 | level "Heart of Darkness" · 40 objects |
| Game.pak | leve | `le12` | `leve/Level 12[le12].leve` | 6,364 | level "Greater Babylon" · 40 objects |
| Game.pak | plde | `pl01` | `plde/Player 1[pl01].plde` | 1,901 | player "Player 1" · 57 keys |
| Game.pak | plde | `pl02` | `plde/Player 2[pl02].plde` | 1,901 | player "Player 2" · 57 keys |
| Game.pak | reli | `inre` | `reli/Rects[inre].reli` | 1,083 | 22 rects |
| Game.pak | stli | `edit` | `stli/Editor[edit].stli` | 74 | 5 lines |
| Game.pak | tefo | `brno` | `tefo/Briefing Normal[brno].tefo` | 579 | format LEFT · loc 120,130 |
| Game.pak | tefo | `brpr` | `tefo/Briefing Preview[brpr].tefo` | 577 | format LEFT · loc 416,87 |
| Game.pak | tefo | `brti` | `tefo/Briefing Title[brti].tefo` | 578 | format LEFT · loc 120,130 |
| Game.pak | tefo | `copr` | `tefo/Console Prompt[copr].tefo` | 578 | format LEFT · loc 30,448 |
| Game.pak | tefo | `cote` | `tefo/Console Text[cote].tefo` | 577 | format LEFT · loc 42,448 |
| Game.pak | tefo | `crno` | `tefo/Credit Normal[crno].tefo` | 579 | format LEFT · loc 120,130 |
| Game.pak | tefo | `crti` | `tefo/Credit Title[crti].tefo` | 578 | format LEFT · loc 120,130 |
| Game.pak | tefo | `gfrs` | `tefo/Game Frame Rate Slow[gfrs].tefo` | 597 | format LEFT · loc 8,10 |
| Game.pak | tefo | `gafr` | `tefo/Game Frame Rate[gafr].tefo` | 599 | format LEFT · loc 8,10 |
| Game.pak | tefo | `gano` | `tefo/Game Notice[gano].tefo` | 650 | format CEGA · loc 0,220 |
| Game.pak | tefo | `gare` | `tefo/Game Replay[gare].tefo` | 634 | format CEGA · loc 0,426 |
| Game.pak | tefo | `gaco` | `tefo/Ground Accuracy Coun[gaco].tefo` | 606 | format LEFT · loc 100,240 |
| Game.pak | tefo | `inch` | `tefo/Int Copyright Hilite[inch].tefo` | 634 | format CEBU · loc 0,447 |
| Game.pak | tefo | `inwh` | `tefo/Int Web URL Hilited[inwh].tefo` | 634 | format CEBU · loc 0,426 |
| Game.pak | tefo | `inwe` | `tefo/Int Web URL[inwe].tefo` | 636 | format CEBU · loc 0,426 |
| Game.pak | tefo | `inbh` | `tefo/Interface Btns Hilit[inbh].tefo` | 673 | format CEBU · loc 0,0 |
| Game.pak | tefo | `inbn` | `tefo/Interface Btns Norm[inbn].tefo` | 657 | format CEBU · loc 0,0 |
| Game.pak | tefo | `inco` | `tefo/Interface Copyright[inco].tefo` | 636 | format CEBU · loc 0,447 |
| Game.pak | tefo | `ingl` | `tefo/Interface Game Logo[ingl].tefo` | 635 | format CEBU · loc 0,101 |
| Game.pak | tefo | `lsbo` | `tefo/Level Select Border[lsbo].tefo` | 596 | format LEFT · loc -1,-1 |
| Game.pak | tefo | `lsca` | `tefo/LevSel Color Accept[lsca].tefo` | 688 | format LEFT · loc 0,0 |
| Game.pak | tefo | `lscf` | `tefo/LevSel Color Failure[lscf].tefo` | 688 | format LEFT · loc 0,0 |
| Game.pak | tefo | `lsde` | `tefo/LevSel Description[lsde].tefo` | 617 | format CEBU · loc 0,407 |
| Game.pak | tefo | `lsfa` | `tefo/LevSel Failure[lsfa].tefo` | 590 | format CEBU · loc 96,407 |
| Game.pak | tefo | `lsna` | `tefo/LevSel No Access[lsna].tefo` | 619 | format CEBU · loc 96,407 |
| Game.pak | tefo | `lsnn` | `tefo/LevSel Number No Acc[lsnn].tefo` | 635 | format CEBU · loc 0,38 |
| Game.pak | tefo | `lsnu` | `tefo/LevSel Number[lsnu].tefo` | 635 | format CEBU · loc 0,38 |
| Game.pak | tefo | `meer` | `tefo/Message Error[meer].tefo` | 577 | format LEFT · loc 30,10 |
| Game.pak | tefo | `meno` | `tefo/Message Normal[meno].tefo` | 578 | format LEFT · loc 30,10 |
| Game.pak | tefo | `mest` | `tefo/Message Status[mest].tefo` | 577 | format LEFT · loc 30,10 |
| Game.pak | tefo | `plmc` | `tefo/Player Money Count[plmc].tefo` | 578 | format LEFT · loc 136,240 |
| Game.pak | tefo | `prog` | `tefo/Progress[prog].tefo` | 647 | format LEFT · loc 50,100 |
| Game.pak | tefo | `scnt` | `tefo/Score Name Title[scnt].tefo` | 577 | format LEFT · loc 110,83 |
| Game.pak | tefo | `spnd` | `tefo/Score Player Name Di[spnd].tefo` | 579 | format LEFT · loc 110,107 |
| Game.pak | tefo | `scph` | `tefo/Score Player Name H[scph].tefo` | 578 | format LEFT · loc 110,107 |
| Game.pak | tefo | `scpn` | `tefo/Score Player Name[scpn].tefo` | 579 | format LEFT · loc 110,107 |
| Game.pak | tefo | `scsc` | `tefo/Score Score [scsc].tefo` | 579 | format RIGH · loc 377,107 |
| Game.pak | tefo | `sscd` | `tefo/Score Score Dim[sscd].tefo` | 579 | format RIGH · loc 377,107 |
| Game.pak | tefo | `scsh` | `tefo/Score Score H[scsh].tefo` | 578 | format RIGH · loc 377,107 |
| Game.pak | tefo | `scst` | `tefo/Score Score Title[scst].tefo` | 578 | format RIGH · loc 377,83 |
| Game.pak | tefo | `ssed` | `tefo/Score Sector Dim[ssed].tefo` | 579 | format LEFT · loc 463,107 |
| Game.pak | tefo | `sseh` | `tefo/Score Sector H[sseh].tefo` | 578 | format LEFT · loc 463,107 |
| Game.pak | tefo | `sset` | `tefo/Score Sector Title[sset].tefo` | 577 | format LEFT · loc 463,83 |
| Game.pak | tefo | `scse` | `tefo/Score Sector[scse].tefo` | 579 | format LEFT · loc 463,107 |
| Game.pak | tefo | `sbl1` | `tefo/ScoreBar Lives Cou 1[sbl1].tefo` | 634 | format CENT · loc 499,50 |
| Game.pak | tefo | `sbl2` | `tefo/ScoreBar Lives Cou 2[sbl2].tefo` | 635 | format CENT · loc 498,285 |
| Game.pak | tefo | `sll1` | `tefo/ScoreBar Lives Las 1[sll1].tefo` | 634 | format CENT · loc 499,50 |
| Game.pak | tefo | `sll2` | `tefo/ScoreBar Lives Las 2[sll2].tefo` | 635 | format CENT · loc 498,285 |
| Game.pak | tefo | `sbpm` | `tefo/ScoreBar Power Meter[sbpm].tefo` | 635 | format LEFT · loc 0,0 |
| Game.pak | tefo | `sbs1` | `tefo/ScoreBar Score 1[sbs1].tefo` | 634 | format CENT · loc 494,83 |
| Game.pak | tefo | `sbs2` | `tefo/ScoreBar Score 2[sbs2].tefo` | 635 | format CENT · loc 494,318 |
| Game.pak | tefo | `sbsh` | `tefo/ScoreBar Shield[sbsh].tefo` | 635 | format LEFT · loc 0,0 |
| Game.pak | tefo | `weac` | `tefo/Wep Ammo Counter[weac].tefo` | 688 | format CENT · loc 0,-51 |
| Game.pak | tefo | `weaw` | `tefo/Wep Ammo Warning[weaw].tefo` | 689 | format CENT · loc 0,-51 |
| Game.pak | unde | `NULL` | `unde/ NULL[NULL].unde` | 7,687 | unit "NULL" · 1 states |
| Game.pak | unde | `aieg` | `unde/Air Explosion Group[aieg].unde` | 13,595 | unit "Air Explosion Group" · 2 states |
| Game.pak | unde | `aerg` | `unde/Air Explosion Red - [aerg].unde` | 12,620 | unit "Air Explosion Red - Glow" · 2 states |
| Game.pak | unde | `aere` | `unde/Air Explosion Red[aere].unde` | 13,585 | unit "Air Explosion Red" · 2 states |
| Game.pak | unde | `bacc` | `unde/Baccula[bacc].unde` | 7,689 | unit "Baccula" · 1 states |
| Game.pak | unde | `bagb` | `unde/Bacta Gun - Bullet[bagb].unde` | 12,831 | unit "Bacta Gun - Bullet" · 2 states |
| Game.pak | unde | `bagf` | `unde/Bacta Gun - Flash[bagf].unde` | 12,753 | unit "Bacta Gun - Glow" · 2 states |
| Game.pak | unde | `bagh` | `unde/Bacta Gun - Hit FX[bagh].unde` | 12,709 | unit "Bacta Gun - Hit FX" · 2 states |
| Game.pak | unde | `bagl` | `unde/Bacta Gun - Launch F[bagl].unde` | 12,628 | unit "Bacta Gun - Launch Flash" · 2 states |
| Game.pak | unde | `bgpb` | `unde/Bacta Gun - Powerup [bgpb].unde` | 13,890 | unit "Bacta Gun - Powerup Bullet" · 2 states |
| Game.pak | unde | `bgpp` | `unde/Bacta Gun - Powerup [bgpp].unde` | 13,026 | unit "Bacta Gun - Powerup Particles" · 2 states |
| Game.pak | unde | `bgpo` | `unde/Bacta Gun - Powerup[bgpo].unde` | 17,940 | unit "Bacta Gun - Powerup" · 3 states |
| Game.pak | unde | `bala` | `unde/Base - Laser[bala].unde` | 10,264 | unit "Base - Laser" · 1 states |
| Game.pak | unde | `bebf` | `unde/Beamer - Bullet Flas[bebf].unde` | 11,653 | unit "Beamer - Bullet Flash" · 2 states |
| Game.pak | unde | `bebh` | `unde/Beamer - Bullet Hit [bebh].unde` | 11,659 | unit "Beamer - Bullet Hit FX" · 2 states |
| Game.pak | unde | `bebu` | `unde/Beamer - Bullet[bebu].unde` | 11,858 | unit "Beamer - Bullet" · 2 states |
| Game.pak | unde | `bede` | `unde/Beamer - Destruction[bede].unde` | 24,678 | unit "Beamer - Destruction" · 4 states |
| Game.pak | unde | `betu` | `unde/Beamer - Turret[betu].unde` | 38,373 | unit "Beamer - Turret" · 7 states |
| Game.pak | unde | `bhrc` | `unde/BlackHawk - Rotor Ch[bhrc].unde` | 8,256 | unit "BlackHawk - Rotor Child" · 1 states |
| Game.pak | unde | `bh02` | `unde/BlackHawk Mk 2[bh02].unde` | 33,999 | unit "BlackHawk Mk 2" · 7 states |
| Game.pak | unde | `blha` | `unde/BlackHawk[blha].unde` | 33,982 | unit "BlackHawk" · 7 states |
| Game.pak | unde | `bocr` | `unde/Bomb Crater[bocr].unde` | 8,375 | unit "Bomb Crater" · 1 states |
| Game.pak | unde | `bsat` | `unde/Bonus Station - All [bsat].unde` | 9,370 | unit "Bonus Station - All Terrain" · 1 states |
| Game.pak | unde | `bsbu` | `unde/Bonus Station - Bubb[bsbu].unde` | 8,394 | unit "Bonus Station - Bubble" · 1 states |
| Game.pak | unde | `bsde` | `unde/Bonus Station - Dese[bsde].unde` | 9,366 | unit "Bonus Station - Desert" · 1 states |
| Game.pak | unde | `bsdt` | `unde/Bonus Station - Dest[bsdt].unde` | 25,177 | unit "Bonus Station - Destruction" · 4 states |
| Game.pak | unde | `bsgr` | `unde/Bonus Station - Gras[bsgr].unde` | 9,364 | unit "Bonus Station - Grass" · 1 states |
| Game.pak | unde | `bude` | `unde/Buzzsaw - Destructio[bude].unde` | 8,279 | unit "Buzzsaw - Destruction" · 1 states |
| Game.pak | unde | `bu01` | `unde/Buzzsaw Mk 1[bu01].unde` | 18,138 | unit "Buzzsaw Mk 1" · 3 states |
| Game.pak | unde | `b2gl` | `unde/Buzzsaw Mk 2 - Glow[b2gl].unde` | 8,466 | unit "Buzzsaw Mk 2 - Glow" · 1 states |
| Game.pak | unde | `bu02` | `unde/Buzzsaw Mk 2[bu02].unde` | 16,931 | unit "Buzzsaw Mk 2" · 3 states |
| Game.pak | unde | `b1gl` | `unde/Buzzsaw Mk1 - Glow[b1gl].unde` | 8,466 | unit "Buzzsaw Mk 1 - Glow" · 1 states |
| Game.pak | unde | `cird` | `unde/Cap - Iris Radar 2 D[cird].unde` | 23,252 | unit "Cap - Iris Radar 2 Detector" · 4 states |
| Game.pak | unde | `cair` | `unde/Cap - Iris[cair].unde` | 22,713 | unit "Cap - Iris" · 4 states |
| Game.pak | unde | `camb` | `unde/Cap - Metal Backgrou[camb].unde` | 8,310 | unit "Cap - Metal Background" · 1 states |
| Game.pak | unde | `came` | `unde/Cap - Metal[came].unde` | 9,347 | unit "Cap - Metal" · 1 states |
| Game.pak | unde | `carf` | `unde/Cap - Radar Flag[carf].unde` | 8,414 | unit "Cap - Radar Flag" · 1 states |
| Game.pak | unde | `car2` | `unde/Cap - Radar Mk 2[car2].unde` | 9,567 | unit "Cap - Radar Mk 2" · 1 states |
| Game.pak | unde | `cart` | `unde/Cap - Radar Turret[cart].unde` | 13,705 | unit "Cap - Radar Turret" · 2 states |
| Game.pak | unde | `cara` | `unde/Cap - Radar[cara].unde` | 10,259 | unit "Cap - Radar" · 1 states |
| Game.pak | unde | `csht` | `unde/Cap - Shield Station[csht].unde` | 9,370 | unit "Cap - Shield Station" · 1 states |
| Game.pak | unde | `casb` | `unde/Cap - Silver Backgro[casb].unde` | 8,327 | unit "Cap - Silver Background" · 1 states |
| Game.pak | unde | `casi` | `unde/Cap - Silver[casi].unde` | 9,349 | unit "Cap - Silver" · 1 states |
| Game.pak | unde | `cale` | `unde/Cash - Large Explosi[cale].unde` | 8,344 | unit "Cash - Large Explosion" · 1 states |
| Game.pak | unde | `calg` | `unde/Cash - Large Gold[calg].unde` | 21,329 | unit "Cash - Large Gold" · 4 states |
| Game.pak | unde | `cals` | `unde/Cash - Large Silver[cals].unde` | 21,331 | unit "Cash - Large Silver" · 4 states |
| Game.pak | unde | `casg` | `unde/Cash - Small Gold[casg].unde` | 21,322 | unit "Cash - Small Gold" · 4 states |
| Game.pak | unde | `cass` | `unde/Cash - Small Silver[cass].unde` | 21,332 | unit "Cash - Small Silver" · 4 states |
| Game.pak | unde | `csat` | `unde/Cash Station - All T[csat].unde` | 9,354 | unit "Cash Station - All Terrain" · 1 states |
| Game.pak | unde | `csbu` | `unde/Cash Station - Bubbl[csbu].unde` | 8,391 | unit "Cash Station - Bubble" · 1 states |
| Game.pak | unde | `cscr` | `unde/Cash Station - Cash [cscr].unde` | 18,033 | unit "Cash Station - Cash Release" · 3 states |
| Game.pak | unde | `csdt` | `unde/Cash Station - Deser[csdt].unde` | 9,343 | unit "Cash Station - Desert" · 1 states |
| Game.pak | unde | `csde` | `unde/Cash Station - Destr[csde].unde` | 10,290 | unit "Cash Station - Destruction" · 1 states |
| Game.pak | unde | `csgr` | `unde/Cash Station - Grass[csgr].unde` | 9,355 | unit "Cash Station - Grass" · 1 states |
| Game.pak | unde | `cs2a` | `unde/Cash Station 2 - All[cs2a].unde` | 8,628 | unit "Cash Station 2 - All Terrain" · 1 states |
| Game.pak | unde | `cs2b` | `unde/Cash Station 2 - Bub[cs2b].unde` | 7,666 | unit "Cash Station 2 - Bubble" · 1 states |
| Game.pak | unde | `cs2r` | `unde/Cash Station 2 - Cas[cs2r].unde` | 18,035 | unit "Cash Station 2 - Cash Release" · 3 states |
| Game.pak | unde | `cs2d` | `unde/Cash Station 2 - Des[cs2d].unde` | 9,563 | unit "Cash Station 2 - Destruction" · 1 states |
| Game.pak | unde | `fgbf` | `unde/Flare Gun - Bullet F[fgbf].unde` | 12,617 | unit "Flare Gun - Bullet Flash" · 2 states |
| Game.pak | unde | `fgbh` | `unde/Flare Gun - Bullet H[fgbh].unde` | 12,626 | unit "Flare Gun - Bullet Hit FX" · 2 states |
| Game.pak | unde | `fgbu` | `unde/Flare Gun - Bullet[fgbu].unde` | 8,351 | unit "Flare Gun - Bullet" · 1 states |
| Game.pak | unde | `fgde` | `unde/Flare Gun - Destruct[fgde].unde` | 26,119 | unit "Flare Gun - Destruction" · 4 states |
| Game.pak | unde | `fg02` | `unde/Flare Gun Mk 2[fg02].unde` | 35,169 | unit "Flare Gun Mk 2" · 6 states |
| Game.pak | unde | `fgnt` | `unde/Flare Gun Nuke - Tur[fgnt].unde` | 32,300 | unit "Flare Gun Nuke - Turret" · 6 states |
| Game.pak | unde | `fgnu` | `unde/Flare Gun Nuke[fgnu].unde` | 13,884 | unit "Flare Gun Nuke" · 2 states |
| Game.pak | unde | `flgu` | `unde/Flare Gun[flgu].unde` | 34,198 | unit "Flare Gun" · 6 states |
| Game.pak | unde | `flfl` | `unde/Flipper - Flame[flfl].unde` | 12,860 | unit "Flipper - Flame" · 2 states |
| Game.pak | unde | `fl02` | `unde/Flipper Mk 2[fl02].unde` | 31,675 | unit "Flipper Mk 2" · 6 states |
| Game.pak | unde | `flip` | `unde/Flipper[flip].unde` | 18,267 | unit "Flipper" · 3 states |
| Game.pak | unde | `gbd2` | `unde/Geyser - Bonus Detec[gbd2].unde` | 14,801 | unit "Geyser - Bonus Detector 2" · 2 states |
| Game.pak | unde | `gebd` | `unde/Geyser - Bonus Detec[gebd].unde` | 14,799 | unit "Geyser - Bonus Detector" · 2 states |
| Game.pak | unde | `gedf` | `unde/Geyser - Destruction[gedf].unde` | 8,419 | unit "Geyser - Destruction Flag" · 1 states |
| Game.pak | unde | `geno` | `unde/Geyser - Notice[geno].unde` | 16,931 | unit "Geyser - Notice" · 3 states |
| Game.pak | unde | `gesm` | `unde/Geyser Smoke[gesm].unde` | 16,944 | unit "Geyser - Smoke" · 3 states |
| Game.pak | unde | `geys` | `unde/Geyser[geys].unde` | 9,272 | unit "Geyser" · 1 states |
| Game.pak | unde | `gkme` | `unde/Ground Kill - Med[gkme].unde` | 24,159 | unit "Ground Kill - Med" · 4 states |
| Game.pak | unde | `gkmx` | `unde/Ground Kill - Medium[gkmx].unde` | 8,302 | unit "Ground Kill - Medium Explosion" · 1 states |
| Game.pak | unde | `gksx` | `unde/Ground Kill - Small [gksx].unde` | 9,309 | unit "Ground Kill - Small Explosions" · 1 states |
| Game.pak | unde | `grob` | `unde/Ground Obstacle[grob].unde` | 8,415 | unit "Ground Obstacle" · 1 states |
| Game.pak | unde | `hode` | `unde/Hospital - Destructi[hode].unde` | 25,172 | unit "Hospital - Destruction" · 4 states |
| Game.pak | unde | `hosp` | `unde/Hospital[hosp].unde` | 8,382 | unit "Hospital" · 1 states |
| Game.pak | unde | `icpb` | `unde/Ion Cannon - Powerup[icpb].unde` | 8,448 | unit "Ion Cannon - Powerup Bullet" · 1 states |
| Game.pak | unde | `icpo` | `unde/Ion Cannon - Powerup[icpo].unde` | 16,809 | unit "Ion Cannon - Powerup" · 3 states |
| Game.pak | unde | `icpp` | `unde/Ion Cannon - Powerup[icpp].unde` | 13,028 | unit "Ion Cannon - Powerup Particles" · 2 states |
| Game.pak | unde | `icps` | `unde/Ion Cannon - Powerup[icps].unde` | 13,566 | unit "Ion Cannon - Powerup Spawner" · 2 states |
| Game.pak | unde | `icbf` | `unde/Ion Cannon Bullet - [icbf].unde` | 12,601 | unit "Ion Cannon Bullet - Flash" · 2 states |
| Game.pak | unde | `icbh` | `unde/Ion Cannon Bullet - [icbh].unde` | 12,716 | unit "Ion Cannon Bullet - Hit FX" · 2 states |
| Game.pak | unde | `icb ` | `unde/Ion Cannon Bullet[icb ].unde` | 8,425 | unit "Ion Cannon Bullet" · 1 states |
| Game.pak | unde | `igcf` | `unde/Iris - Gold Coin Fla[igcf].unde` | 7,673 | unit "Iris - Gold Coin Flag" · 1 states |
| Game.pak | unde | `igcs` | `unde/Iris - Gold Coin Sto[igcs].unde` | 18,031 | unit "Iris - Gold Coin Storm" · 3 states |
| Game.pak | unde | `irgc` | `unde/Iris - Gold Coin[irgc].unde` | 21,352 | unit "Iris - Gold Coin" · 4 states |
| Game.pak | unde | `ilof` | `unde/Iris - Life Open Fla[ilof].unde` | 7,674 | unit "Iris - Life Open Flag" · 1 states |
| Game.pak | unde | `irli` | `unde/Iris - Life[irli].unde` | 21,329 | unit "Iris - Life" · 4 states |
| Game.pak | unde | `irm2` | `unde/Iris - Mine 2[irm2].unde` | 29,739 | unit "Iris - Mine 2" · 6 states |
| Game.pak | unde | `imof` | `unde/Iris - Mine Open Fla[imof].unde` | 7,675 | unit "Iris - Mine Open Flag" · 1 states |
| Game.pak | unde | `irmi` | `unde/Iris - Mine[irmi].unde` | 29,706 | unit "Iris - Mine" · 6 states |
| Game.pak | unde | `irsc` | `unde/Iris - Score[irsc].unde` | 22,746 | unit "Iris - Score" · 4 states |
| Game.pak | unde | `irsm` | `unde/Iris - Shield Major[irsm].unde` | 21,353 | unit "Iris - Shield Major" · 4 states |
| Game.pak | unde | `isof` | `unde/Iris - Shield Open F[isof].unde` | 7,672 | unit "Iris - Shield Open Flag" · 1 states |
| Game.pak | unde | `jgbf` | `unde/Juno Gun - Bullet Fl[jgbf].unde` | 12,598 | unit "Juno Gun - Bullet Flash" · 2 states |
| Game.pak | unde | `jgbh` | `unde/Juno Gun - Bullet Hi[jgbh].unde` | 12,603 | unit "Juno Gun - Bullet Hit FX" · 2 states |
| Game.pak | unde | `jgbu` | `unde/Juno Gun - Bullet[jgbu].unde` | 9,338 | unit "Juno Gun - Bullet" · 1 states |
| Game.pak | unde | `jgde` | `unde/Juno Gun - Destructi[jgde].unde` | 25,172 | unit "Juno Gun - Destruction" · 4 states |
| Game.pak | unde | `jg2d` | `unde/Juno Gun 2 - Destruc[jg2d].unde` | 26,092 | unit "Juno Gun 2 - Destruction" · 4 states |
| Game.pak | unde | `jg02` | `unde/Juno Gun 2[jg02].unde` | 27,766 | unit "Juno Gun 2" · 5 states |
| Game.pak | unde | `jugu` | `unde/Juno Gun[jugu].unde` | 20,996 | unit "Juno Gun" · 4 states |
| Game.pak | unde | `01b1` | `unde/Level 1 - Bridge[01b1].unde` | 18,153 | unit "Level 1 - Bridge" · 3 states |
| Game.pak | unde | `01m1` | `unde/Level 1 - Mid[01m1].unde` | 12,930 | unit "Level 1 - Mid" · 2 states |
| Game.pak | unde | `10e1` | `unde/Level 10 - End 1[10e1].unde` | 55,774 | unit "Level 10 - End 1" · 12 states |
| Game.pak | unde | `10m1` | `unde/Level 10 - Mid 1[10m1].unde` | 64,994 | unit "Level 10 - Mid 1" · 13 states |
| Game.pak | unde | `10s1` | `unde/Level 10 - Start 1[10s1].unde` | 61,005 | unit "Level 10 - Start 1" · 12 states |
| Game.pak | unde | `10s2` | `unde/Level 10 - Start 2[10s2].unde` | 23,336 | unit "Level 10 - Start 2" · 4 states |
| Game.pak | unde | `11e1` | `unde/Level 11 - End 1[11e1].unde` | 50,747 | unit "Level 11 - End 1" · 9 states |
| Game.pak | unde | `11m2` | `unde/Level 11 - Mid 2[11m2].unde` | 25,360 | unit "Level 11 - Mid 2" · 5 states |
| Game.pak | unde | `11m3` | `unde/Level 11 - Mid 3[11m3].unde` | 40,850 | unit "Level 11 - Mid 3" · 8 states |
| Game.pak | unde | `11rb` | `unde/Level 11 - Radar Bon[11rb].unde` | 11,937 | unit "Level 11 - Radar Bonus" · 2 states |
| Game.pak | unde | `11s1` | `unde/Level 11 - Start 1[11s1].unde` | 59,770 | unit "Level 11 - Start 1" · 12 states |
| Game.pak | unde | `12gc` | `unde/Level 12 - Game Comp[12gc].unde` | 29,062 | unit "Level 12 - Game Completion" · 4 states |
| Game.pak | unde | `12m1` | `unde/Level 12 - Mid 1[12m1].unde` | 27,423 | unit "Level 12 - Mid 1" · 5 states |
| Game.pak | unde | `12m2` | `unde/Level 12 - Mid 2[12m2].unde` | 30,282 | unit "Level 12 - Mid 2" · 5 states |
| Game.pak | unde | `12m3` | `unde/Level 12 - Mid 3[12m3].unde` | 49,525 | unit "Level 12 - Mid 3" · 10 states |
| Game.pak | unde | `12s1` | `unde/Level 12 - Start 1[12s1].unde` | 25,490 | unit "Level 12 - Start 1" · 5 states |
| Game.pak | unde | `02b1` | `unde/Level 2 - Bridge 1[02b1].unde` | 26,137 | unit "Level 2 - Bridge 1" · 5 states |
| Game.pak | unde | `02e1` | `unde/Level 2 - End 1[02e1].unde` | 27,070 | unit "Level 2 - End 1" · 5 states |
| Game.pak | unde | `02e2` | `unde/Level 2 - End 2[02e2].unde` | 32,311 | unit "Level 2 - End 2" · 6 states |
| Game.pak | unde | `02m2` | `unde/Level 2 - Mid 2[02m2].unde` | 22,294 | unit "Level 2 - Mid 2" · 4 states |
| Game.pak | unde | `02m1` | `unde/Level 2 - Mid[02m1].unde` | 12,914 | unit "Level 2 - Mid" · 2 states |
| Game.pak | unde | `02s2` | `unde/Level 2 - Start 2[02s2].unde` | 26,550 | unit "Level 2 - Start 2" · 5 states |
| Game.pak | unde | `02s1` | `unde/Level 2 - Start[02s1].unde` | 12,848 | unit "Level 2 - Start 1" · 2 states |
| Game.pak | unde | `03b1` | `unde/Level 3 - Bridge 1[03b1].unde` | 31,765 | unit "Level 3 - Bridge 1" · 6 states |
| Game.pak | unde | `03e1` | `unde/Level 3 - End[03e1].unde` | 41,447 | unit "Level 3 - End" · 8 states |
| Game.pak | unde | `03m2` | `unde/Level 3 - Mid 2[03m2].unde` | 32,737 | unit "Level 3 - Mid 2" · 6 states |
| Game.pak | unde | `03p1` | `unde/Level 3 - Pause 1[03p1].unde` | 27,088 | unit "Level 3 - Pause 1" · 5 states |
| Game.pak | unde | `03p2` | `unde/Level 3 - Pause 2[03p2].unde` | 16,887 | unit "Level 3 - Pause 2" · 3 states |
| Game.pak | unde | `04e1` | `unde/Level 4 - End [04e1].unde` | 30,954 | unit "Level 4 - End " · 6 states |
| Game.pak | unde | `04m1` | `unde/Level 4 - Mid 1[04m1].unde` | 30,453 | unit "Level 4 - Mid 1" · 6 states |
| Game.pak | unde | `04m2` | `unde/Level 4 - Mid 2[04m2].unde` | 30,455 | unit "Level 4 - Mid 2" · 6 states |
| Game.pak | unde | `04p1` | `unde/Level 4 - Pause 1[04p1].unde` | 20,987 | unit "Level 4 - Pause 1" · 4 states |
| Game.pak | unde | `05gb` | `unde/Level 5 - Geyser Bon[05gb].unde` | 15,758 | unit "Level 5 - Geyser Bonus Detector" · 2 states |
| Game.pak | unde | `05gd` | `unde/Level 5 - Geyser Det[05gd].unde` | 13,818 | unit "Level 5 - Geyser Detector" · 2 states |
| Game.pak | unde | `05m1` | `unde/Level 5 - Mid 1[05m1].unde` | 30,456 | unit "Level 5 - Mid 1" · 6 states |
| Game.pak | unde | `05m2` | `unde/Level 5 - Mid 2[05m2].unde` | 31,436 | unit "Level 5 - Mid 2" · 6 states |
| Game.pak | unde | `05s1` | `unde/Level 5 - Start 1[05s1].unde` | 21,955 | unit "Level 5 - Start 1" · 4 states |
| Game.pak | unde | `06e1` | `unde/Level 6 - End[06e1].unde` | 64,165 | unit "Level 6 - End" · 12 states |
| Game.pak | unde | `06m1` | `unde/Level 6 - Mid 1[06m1].unde` | 30,581 | unit "Level 6 - Mid 1" · 6 states |
| Game.pak | unde | `06s1` | `unde/Level 6 - Start 1[06s1].unde` | 31,093 | unit "Level 6 - Start 1" · 6 states |
| Game.pak | unde | `07m1` | `unde/Level 7 - Mid 1[07m1].unde` | 30,565 | unit "Level 7 - Mid 1" · 6 states |
| Game.pak | unde | `07m2` | `unde/Level 7 - Mid 2[07m2].unde` | 41,310 | unit "Level 7 - Mid 2" · 8 states |
| Game.pak | unde | `07s1` | `unde/Level 7 - Start 1[07s1].unde` | 30,131 | unit "Level 7 - Start 1" · 6 states |
| Game.pak | unde | `08e1` | `unde/Level 8 - End 1[08e1].unde` | 46,728 | unit "Level 8 - End 1" · 9 states |
| Game.pak | unde | `08m2` | `unde/Level 8 - Mid 2[08m2].unde` | 45,455 | unit "Level 8 - Mid 2" · 9 states |
| Game.pak | unde | `08s1` | `unde/Level 8 - Start 1[08s1].unde` | 46,348 | unit "Level 8 - Start 1" · 9 states |
| Game.pak | unde | `09e1` | `unde/Level 9 - End 1[09e1].unde` | 58,705 | unit "Level 9 - End 1" · 12 states |
| Game.pak | unde | `09m1` | `unde/Level 9 - Mid 1[09m1].unde` | 44,604 | unit "Level 9 - Mid 1" · 9 states |
| Game.pak | unde | `09m2` | `unde/Level 9 - Mid 2[09m2].unde` | 39,333 | unit "Level 9 - Mid 2" · 8 states |
| Game.pak | unde | `09s1` | `unde/Level 9 - Start 1[09s1].unde` | 41,153 | unit "Level 9 - Start 1" · 8 states |
| Game.pak | unde | `lsat` | `unde/Life Station - All T[lsat].unde` | 9,365 | unit "Life Station - All Terrain" · 1 states |
| Game.pak | unde | `lsbu` | `unde/Life Station - Bubbl[lsbu].unde` | 8,391 | unit "Life Station - Bubble" · 1 states |
| Game.pak | unde | `lsdt` | `unde/Life Station - Deser[lsdt].unde` | 9,361 | unit "Life Station - Desert" · 1 states |
| Game.pak | unde | `lsde` | `unde/Life Station - Destr[lsde].unde` | 10,303 | unit "Life Station - Destruction" · 1 states |
| Game.pak | unde | `lsgr` | `unde/Life Station - Grass[lsgr].unde` | 9,359 | unit "Life Station - Grass" · 1 states |
| Game.pak | unde | `mine` | `unde/Mine[mine].unde` | 12,718 | unit "Mine" · 2 states |
| Game.pak | unde | `miac` | `unde/Mission Iris - All C[miac].unde` | 25,603 | unit "Mission Iris - All Coins" · 5 states |
| Game.pak | unde | `mias` | `unde/Mission Iris - All C[mias].unde` | 18,035 | unit "Mission Iris - All Coin Storm" · 3 states |
| Game.pak | unde | `migc` | `unde/Mission Iris - Gold [migc].unde` | 25,598 | unit "Mission Iris - Gold Coins" · 5 states |
| Game.pak | unde | `migs` | `unde/Mission Iris - Gold [migs].unde` | 18,035 | unit "Mission Iris - Gold Coin Storm" · 3 states |
| Game.pak | unde | `mimu` | `unde/Mission Iris - Multi[mimu].unde` | 25,608 | unit "Mission Iris - Multiplier" · 5 states |
| Game.pak | unde | `miof` | `unde/Mission Iris - Open [miof].unde` | 7,711 | unit "Mission Iris - Open Flag" · 1 states |
| Game.pak | unde | `mipo` | `unde/Mission Iris - Point[mipo].unde` | 25,591 | unit "Mission Iris - Points" · 5 states |
| Game.pak | unde | `mips` | `unde/Mission Iris - Point[mips].unde` | 18,970 | unit "Mission Iris - Points Storm" · 3 states |
| Game.pak | unde | `mux3` | `unde/Multipler - x3[mux3].unde` | 8,260 | unit "Multiplier - x3" · 1 states |
| Game.pak | unde | `muxx` | `unde/Multiplier - x10[muxx].unde` | 8,263 | unit "Multiplier - x10" · 1 states |
| Game.pak | unde | `mux2` | `unde/Multiplier - x2[mux2].unde` | 8,260 | unit "Multiplier - x2" · 1 states |
| Game.pak | unde | `mux4` | `unde/Multiplier - x4[mux4].unde` | 8,260 | unit "Multiplier - x4" · 1 states |
| Game.pak | unde | `mux5` | `unde/Multiplier - x5[mux5].unde` | 8,261 | unit "Multiplier - x5" · 1 states |
| Game.pak | unde | `noal` | `unde/Notice - All Levels[noal].unde` | 33,161 | unit "Notice - All Levels Completed" · 7 states |
| Game.pak | unde | `nodb` | `unde/Notice - Defence Bon[nodb].unde` | 21,266 | unit "Notice - Defence Bonus" · 4 states |
| Game.pak | unde | `noel` | `unde/Notice - Extra Life[noel].unde` | 16,933 | unit "Notice - Extra Life" · 3 states |
| Game.pak | unde | `nogo` | `unde/Notice - Game Over[nogo].unde` | 21,222 | unit "Notice - Game Over" · 4 states |
| Game.pak | unde | `no01` | `unde/Notice - Level 01[no01].unde` | 19,814 | unit "Notice - Level 01" · 4 states |
| Game.pak | unde | `no02` | `unde/Notice - Level 02[no02].unde` | 19,814 | unit "Notice - Level 02" · 4 states |
| Game.pak | unde | `no03` | `unde/Notice - Level 03[no03].unde` | 19,814 | unit "Notice - Level 03" · 4 states |
| Game.pak | unde | `no04` | `unde/Notice - Level 04[no04].unde` | 19,814 | unit "Notice - Level 04" · 4 states |
| Game.pak | unde | `no05` | `unde/Notice - Level 05[no05].unde` | 19,814 | unit "Notice - Level 05" · 4 states |
| Game.pak | unde | `no06` | `unde/Notice - Level 06[no06].unde` | 19,814 | unit "Notice - Level 06" · 4 states |
| Game.pak | unde | `no07` | `unde/Notice - Level 07[no07].unde` | 19,814 | unit "Notice - Level 07" · 4 states |
| Game.pak | unde | `no08` | `unde/Notice - Level 08[no08].unde` | 19,814 | unit "Notice - Level 08" · 4 states |
| Game.pak | unde | `no09` | `unde/Notice - Level 09[no09].unde` | 19,814 | unit "Notice - Level 09" · 4 states |
| Game.pak | unde | `no10` | `unde/Notice - Level 10[no10].unde` | 19,814 | unit "Notice - Level 10" · 4 states |
| Game.pak | unde | `no11` | `unde/Notice - Level 11[no11].unde` | 19,822 | unit "Notice - Level 11" · 4 states |
| Game.pak | unde | `no12` | `unde/Notice - Level 12[no12].unde` | 19,822 | unit "Notice - Level 12" · 4 states |
| Game.pak | unde | `nole` | `unde/Notice - Level End[nole].unde` | 21,259 | unit "Notice - Level End" · 4 states |
| Game.pak | unde | `nosw` | `unde/Notice - Shield Warn[nosw].unde` | 16,935 | unit "Notice - Shield Warning" · 3 states |
| Game.pak | unde | `nowc` | `unde/Notice - War Crime[nowc].unde` | 16,950 | unit "Notice - War Crime" · 3 states |
| Game.pak | unde | `ngbf` | `unde/Nuke Gun - Bullet Fl[ngbf].unde` | 12,618 | unit "Nuke Gun - Bullet Flash" · 2 states |
| Game.pak | unde | `ngbh` | `unde/Nuke Gun - Bullet Hi[ngbh].unde` | 12,623 | unit "Nuke Gun - Bullet Hit FX" · 2 states |
| Game.pak | unde | `ngbu` | `unde/Nuke Gun - Bullet[ngbu].unde` | 8,381 | unit "Nuke Gun - Bullet" · 1 states |
| Game.pak | unde | `ngde` | `unde/Nuke Gun - Destructi[ngde].unde` | 26,105 | unit "Nuke Gun - Destruction" · 4 states |
| Game.pak | unde | `ngsh` | `unde/Nuke Gun - Shields[ngsh].unde` | 15,759 | unit "Nuke Gun - Shields" · 3 states |
| Game.pak | unde | `ngtu` | `unde/Nuke Gun - Turret[ngtu].unde` | 42,735 | unit "Nuke Gun - Turret" · 7 states |
| Game.pak | unde | `ng2d` | `unde/Nuke Gun 2 - Destruc[ng2d].unde` | 25,162 | unit "Nuke Gun Mk 2 - Destruction" · 4 states |
| Game.pak | unde | `ng02` | `unde/Nuke Gun Mk 2[ng02].unde` | 14,832 | unit "Nuke Gun Mk 2" · 2 states |
| Game.pak | unde | `nugu` | `unde/Nuke Gun[nugu].unde` | 14,800 | unit "Nuke Gun" · 2 states |
| Game.pak | unde | `nsbu` | `unde/Nuke Station - Bubbl[nsbu].unde` | 8,391 | unit "Nuke Station - Bubble" · 1 states |
| Game.pak | unde | `nsde` | `unde/Nuke Station - Destr[nsde].unde` | 26,125 | unit "Nuke Station - Destruction" · 4 states |
| Game.pak | unde | `nsdf` | `unde/Nuke Station - Destr[nsdf].unde` | 8,434 | unit "Nuke Station - Destruction Flag" · 1 states |
| Game.pak | unde | `ns02` | `unde/Nuke Station Mk 2[ns02].unde` | 8,634 | unit "Nuke Station Mk 2" · 1 states |
| Game.pak | unde | `nust` | `unde/Nuke Station[nust].unde` | 9,308 | unit "Nuke Station" · 1 states |
| Game.pak | unde | `ppbf` | `unde/Panzer - Pulse Bulle[ppbf].unde` | 11,669 | unit "Panzer - Pulse Bullet Flash" · 2 states |
| Game.pak | unde | `ppbh` | `unde/Panzer - Pulse Bulle[ppbh].unde` | 11,660 | unit "Panzer - Pulse Bullet Hit FX" · 2 states |
| Game.pak | unde | `ppbu` | `unde/Panzer - Pulse Bulle[ppbu].unde` | 7,629 | unit "Panzer - Pulse Bullet" · 1 states |
| Game.pak | unde | `ppcl` | `unde/Panzer - Pulse Cap L[ppcl].unde` | 16,214 | unit "Panzer - Pulse Cap Light" · 3 states |
| Game.pak | unde | `ppca` | `unde/Panzer - Pulse Cap[ppca].unde` | 12,947 | unit "Panzer - Pulse Cap" · 2 states |
| Game.pak | unde | `ppde` | `unde/Panzer - Pulse Destr[ppde].unde` | 23,762 | unit "Panzer - Pulse Destruction" · 4 states |
| Game.pak | unde | `pptf` | `unde/Panzer - Pulse Track[pptf].unde` | 7,734 | unit "Panzer - Pulse Track Flag" · 1 states |
| Game.pak | unde | `pptu` | `unde/Panzer - Pulse Turre[pptu].unde` | 36,986 | unit "Panzer - Pulse Turret" · 6 states |
| Game.pak | unde | `papu` | `unde/Panzer - Pulse[papu].unde` | 11,471 | unit "Panzer - Pulse" · 1 states |
| Game.pak | unde | `psbf` | `unde/Panzer - Scatter Bul[psbf].unde` | 12,634 | unit "Panzer - Scatter Bullet Flash" · 2 states |
| Game.pak | unde | `psbh` | `unde/Panzer - Scatter Bul[psbh].unde` | 12,625 | unit "Panzer - Scatter Bullet Hit FX" · 2 states |
| Game.pak | unde | `psbu` | `unde/Panzer - Scatter Bul[psbu].unde` | 8,359 | unit "Panzer - Scatter Bullet" · 1 states |
| Game.pak | unde | `psca` | `unde/Panzer - Scatter Cap[psca].unde` | 13,915 | unit "Panzer - Scatter Cap" · 2 states |
| Game.pak | unde | `pscl` | `unde/Panzer - Scatter Cap[pscl].unde` | 17,408 | unit "Panzer - Scatter Cap Light" · 3 states |
| Game.pak | unde | `pstf` | `unde/Panzer - Scatter Tra[pstf].unde` | 8,468 | unit "Panzer - Scatter Track Flag" · 1 states |
| Game.pak | unde | `pstu` | `unde/Panzer - Scatter Tur[pstu].unde` | 24,415 | unit "Panzer - Scatter Turret" · 4 states |
| Game.pak | unde | `pasc` | `unde/Panzer - Scatter[pasc].unde` | 11,478 | unit "Panzer - Scatter" · 1 states |
| Game.pak | unde | `pa10` | `unde/Pause - 10 Seconds[pa10].unde` | 12,841 | unit "Pause - 10 Seconds" · 2 states |
| Game.pak | unde | `pa15` | `unde/Pause - 15 Seconds[pa15].unde` | 12,841 | unit "Pause - 15 Seconds" · 2 states |
| Game.pak | unde | `pa20` | `unde/Pause - 20 Seconds[pa20].unde` | 12,841 | unit "Pause - 20 Seconds" · 2 states |
| Game.pak | unde | `pa30` | `unde/Pause - 30 Seconds[pa30].unde` | 12,841 | unit "Pause - 30 Seconds" · 2 states |
| Game.pak | unde | `pbbl` | `unde/Photon Beam - Beam L[pbbl].unde` | 8,461 | unit "Photon Beam - Powerup Bullet" · 1 states |
| Game.pak | unde | `pbbf` | `unde/Photon Beam - Bullet[pbbf].unde` | 12,620 | unit "Photon Beam - Bullet Flash" · 2 states |
| Game.pak | unde | `pbbh` | `unde/Photon Beam - Bullet[pbbh].unde` | 12,715 | unit "Photon Beam - Bullet Hit FX" · 2 states |
| Game.pak | unde | `pbbu` | `unde/Photon Beam - Bullet[pbbu].unde` | 8,465 | unit "Photon Beam - Bullet" · 1 states |
| Game.pak | unde | `pbpo` | `unde/Photon Beam - Poweru[pbpo].unde` | 21,859 | unit "Photon Beam - Powerup" · 4 states |
| Game.pak | unde | `pbpp` | `unde/Photon Beam - Poweru[pbpp].unde` | 12,944 | unit "Photon Beam - Powerup Particles" · 2 states |
| Game.pak | unde | `pbps` | `unde/Photon Beam - Poweru[pbps].unde` | 12,268 | unit "Photon Beam - Powerup Spawner" · 1 states |
| Game.pak | unde | `pb  ` | `unde/Photon Beam[pb  ].unde` | 12,247 | unit "Photon Beam" · 1 states |
| Game.pak | unde | `pi1k` | `unde/Pickup - 1000[pi1k].unde` | 21,295 | unit "Pickup - 1000" · 4 states |
| Game.pak | unde | `pi2k` | `unde/Pickup - 2000[pi2k].unde` | 21,295 | unit "Pickup - 2000" · 4 states |
| Game.pak | unde | `pi5k` | `unde/Pickup - 5000[pi5k].unde` | 21,295 | unit "Pickup - 5000" · 4 states |
| Game.pak | unde | `p500` | `unde/Pickup - 500[p500].unde` | 21,292 | unit "Pickup - 500" · 4 states |
| Game.pak | unde | `piel` | `unde/Pickup - Extra Life[piel].unde` | 12,666 | unit "Pickup - Extra Life" · 2 states |
| Game.pak | unde | `pimu` | `unde/Pickup - Multiplier[pimu].unde` | 12,650 | unit "Pickup - Multiplier" · 2 states |
| Game.pak | unde | `pism` | `unde/Pickup - Shields Min[pism].unde` | 11,700 | unit "Pickup - Shields Mini" · 2 states |
| Game.pak | unde | `pish` | `unde/Pickup - Shields[pish].unde` | 11,700 | unit "Pickup - Shields" · 2 states |
| Game.pak | unde | `pbgl` | `unde/Plasma Bomb - Glow[pbgl].unde` | 12,654 | unit "Plasma Bomb - Glow" · 2 states |
| Game.pak | unde | `pbhf` | `unde/Plasma Bomb - Hit FX[pbhf].unde` | 9,232 | unit "Plasma Bomb - Hit FX" · 1 states |
| Game.pak | unde | `pblf` | `unde/Plasma Bomb - Launch[pblf].unde` | 12,603 | unit "Plasma Bomb - Launch Flash" · 2 states |
| Game.pak | unde | `plbo` | `unde/Plasma Bomb[plbo].unde` | 18,231 | unit "Plasma Bomb" · 3 states |
| Game.pak | unde | `plbf` | `unde/Platform - Laser Bul[plbf].unde` | 12,632 | unit "Platform - Laser Bullet Flash" · 2 states |
| Game.pak | unde | `plbh` | `unde/Platform - Laser Bul[plbh].unde` | 12,730 | unit "Platform - Laser Bullet Hit FX" · 2 states |
| Game.pak | unde | `pllb` | `unde/Platform - Laser Bul[pllb].unde` | 9,380 | unit "Platform - Laser Bullet" · 1 states |
| Game.pak | unde | `plcl` | `unde/Platform - Laser Cap[plcl].unde` | 17,573 | unit "Platform - Laser Cap Light" · 3 states |
| Game.pak | unde | `pllc` | `unde/Platform - Laser Cap[pllc].unde` | 13,923 | unit "Platform - Laser Cap" · 2 states |
| Game.pak | unde | `plld` | `unde/Platform - Laser Des[plld].unde` | 25,190 | unit "Platform - Laser Destruction" · 4 states |
| Game.pak | unde | `pltf` | `unde/Platform - Laser Tra[pltf].unde` | 8,508 | unit "Platform - Laser Track Flag" · 1 states |
| Game.pak | unde | `pllt` | `unde/Platform - Laser Tur[pllt].unde` | 23,604 | unit "Platform - Laser Turret" · 4 states |
| Game.pak | unde | `plla` | `unde/Platform - Laser[plla].unde` | 10,274 | unit "Platform - Laser" · 1 states |
| Game.pak | unde | `pdex` | `unde/Player - Destruction[pdex].unde` | 12,638 | unit "Player - Destruction Explosions" · 2 states |
| Game.pak | unde | `plde` | `unde/Player - Destruction[plde].unde` | 10,459 | unit "Player - Destruction" · 1 states |
| Game.pak | unde | `plen` | `unde/Player - Entry[plen].unde` | 16,886 | unit "Player - Entry" · 3 states |
| Game.pak | unde | `pler` | `unde/Player - Explosion R[pler].unde` | 12,598 | unit "Player - Explosion Ring" · 2 states |
| Game.pak | unde | `plle` | `unde/Player - Large Explo[plle].unde` | 8,311 | unit "Player - Large Explosion Group" · 1 states |
| Game.pak | unde | `p1mc` | `unde/Player 1 - Money Cou[p1mc].unde` | 21,231 | unit "Player 1 - Money Counter" · 4 states |
| Game.pak | unde | `p2mc` | `unde/Player 2 - Money Cou[p2mc].unde` | 21,231 | unit "Player 2 - Money Counter" · 4 states |
| Game.pak | unde | `plsh` | `unde/Player Shields[plsh].unde` | 17,075 | unit "Player - Shields" · 3 states |
| Game.pak | unde | `poaf` | `unde/Popup - Activation F[poaf].unde` | 8,392 | unit "Popup - Activation Flag" · 1 states |
| Game.pak | unde | `poba` | `unde/Popup - Background[poba].unde` | 8,317 | unit "Popup - Background" · 1 states |
| Game.pak | unde | `pode` | `unde/Popup - Destruction[pode].unde` | 25,163 | unit "Popup - Destruction" · 4 states |
| Game.pak | unde | `plaf` | `unde/Popup - Large Activa[plaf].unde` | 8,410 | unit "Popup - Large Activate Flag" · 1 states |
| Game.pak | unde | `polb` | `unde/Popup - Large Backgr[polb].unde` | 8,316 | unit "Popup - Large Background" · 1 states |
| Game.pak | unde | `pldf` | `unde/Popup - Large Destru[pldf].unde` | 7,740 | unit "Popup - Large Destruct Flag" · 1 states |
| Game.pak | unde | `pold` | `unde/Popup - Large Destru[pold].unde` | 15,710 | unit "Popup - Large Destruction" · 2 states |
| Game.pak | unde | `plph` | `unde/Popup - Large Proj H[plph].unde` | 12,610 | unit "Popup - Large Proj Hit FX" · 2 states |
| Game.pak | unde | `plpf` | `unde/Popup - Large Projec[plpf].unde` | 12,610 | unit "Popup - Large Projectile Flash" · 2 states |
| Game.pak | unde | `polp` | `unde/Popup - Large Projec[polp].unde` | 9,361 | unit "Popup - Large Projectile" · 1 states |
| Game.pak | unde | `pola` | `unde/Popup - Large[pola].unde` | 43,068 | unit "Popup - Large" · 9 states |
| Game.pak | unde | `popf` | `unde/Popup - Projectile F[popf].unde` | 12,616 | unit "Popup - Projectile Flash" · 2 states |
| Game.pak | unde | `poph` | `unde/Popup - Projectile H[poph].unde` | 12,622 | unit "Popup - Projectile Hit FX" · 2 states |
| Game.pak | unde | `popr` | `unde/Popup - Projectile[popr].unde` | 9,340 | unit "Popup - Projectile" · 1 states |
| Game.pak | unde | `posf` | `unde/Popup - Shutdown Fla[posf].unde` | 8,395 | unit "Popup - Shutdown Flag" · 1 states |
| Game.pak | unde | `pop2` | `unde/Popup 2[pop2].unde` | 51,429 | unit "Popup 2" · 11 states |
| Game.pak | unde | `plsf` | `unde/Popup Large - Shutdo[plsf].unde` | 8,416 | unit "Popup Large - Shutdown Flag" · 1 states |
| Game.pak | unde | `popu` | `unde/Popup[popu].unde` | 47,215 | unit "Popup" · 10 states |
| Game.pak | unde | `rb10` | `unde/Random Bonus - 10[rb10].unde` | 8,345 | unit "Random Bonus - 10" · 1 states |
| Game.pak | unde | `rb01` | `unde/Random Bonus - 1[rb01].unde` | 9,284 | unit "Random Bonus - 1" · 1 states |
| Game.pak | unde | `rb02` | `unde/Random Bonus - 2[rb02].unde` | 9,296 | unit "Random Bonus - 2" · 1 states |
| Game.pak | unde | `rb03` | `unde/Random Bonus - 3[rb03].unde` | 9,296 | unit "Random Bonus - 3" · 1 states |
| Game.pak | unde | `rb04` | `unde/Random Bonus - 4[rb04].unde` | 9,296 | unit "Random Bonus - 4" · 1 states |
| Game.pak | unde | `rb05` | `unde/Random Bonus - 5[rb05].unde` | 10,254 | unit "Random Bonus - 5" · 1 states |
| Game.pak | unde | `rb06` | `unde/Random Bonus - 6[rb06].unde` | 9,302 | unit "Random Bonus - 6" · 1 states |
| Game.pak | unde | `rb07` | `unde/Random Bonus - 7[rb07].unde` | 9,299 | unit "Random Bonus - 7" · 1 states |
| Game.pak | unde | `rb08` | `unde/Random Bonus - 8[rb08].unde` | 9,302 | unit "Random Bonus - 8" · 1 states |
| Game.pak | unde | `rb09` | `unde/Random Bonus - 9[rb09].unde` | 9,299 | unit "Random Bonus - 9" · 1 states |
| Game.pak | unde | `rbes` | `unde/Random Bonus - Enemy[rbes].unde` | 8,412 | unit "Random Bonus - Enemy Sound" · 1 states |
| Game.pak | unde | `rgbf` | `unde/Rear Gun - Bullet Fl[rgbf].unde` | 12,597 | unit "Rear Gun - Bullet Flash" · 2 states |
| Game.pak | unde | `rgbh` | `unde/Rear Gun - Bullet Hi[rgbh].unde` | 12,599 | unit "Rear Gun - Bullet Hit FX" · 2 states |
| Game.pak | unde | `rgbs` | `unde/Rear Gun - Bullet Sp[rgbs].unde` | 14,050 | unit "Rear Gun - Bullet Spawner" · 1 states |
| Game.pak | unde | `rgbu` | `unde/Rear Gun - Bullet[rgbu].unde` | 8,430 | unit "Rear Gun - Bullet" · 1 states |
| Game.pak | unde | `rgpb` | `unde/Rear Gun - Powerup B[rgpb].unde` | 17,294 | unit "Rear Gun - Powerup Bullet" · 3 states |
| Game.pak | unde | `rgpp` | `unde/Rear Gun - Powerup P[rgpp].unde` | 12,915 | unit "Rear Gun - Powerup Particles" · 2 states |
| Game.pak | unde | `rgpo` | `unde/Rear Gun - Powerup[rgpo].unde` | 17,963 | unit "Rear Gun - Powerup" · 3 states |
| Game.pak | unde | `scbu` | `unde/Screw - Bullet[scbu].unde` | 8,361 | unit "Screw - Bullet" · 1 states |
| Game.pak | unde | `scli` | `unde/Screw - Lighting[scli].unde` | 12,639 | unit "Screw - Lighting" · 2 states |
| Game.pak | unde | `s2bh` | `unde/Screw Mk 2 - Bullet [s2bh].unde` | 12,624 | unit "Screw Mk 2 - Bullet Hit FX" · 2 states |
| Game.pak | unde | `s2bu` | `unde/Screw Mk 2 - Bullet[s2bu].unde` | 8,371 | unit "Screw Mk 2 - Bullet" · 1 states |
| Game.pak | unde | `s2f1` | `unde/Screw Mk 2 - Formati[s2f1].unde` | 14,285 | unit "Screw Mk 2 - Formation 1" · 1 states |
| Game.pak | unde | `s2li` | `unde/Screw Mk 2 - Lightin[s2li].unde` | 12,644 | unit "Screw Mk 2 - Lighting" · 2 states |
| Game.pak | unde | `scl2` | `unde/Screw Mk 2 - Loner[scl2].unde` | 45,981 | unit "Screw Mk 2 - Loner" · 8 states |
| Game.pak | unde | `sc02` | `unde/Screw Mk 2[sc02].unde` | 48,342 | unit "Screw Mk 2" · 8 states |
| Game.pak | unde | `s3bu` | `unde/Screw Mk 3 - Bullet[s3bu].unde` | 18,066 | unit "Screw Mk 3 - Bullet" · 3 states |
| Game.pak | unde | `s3cl` | `unde/Screw Mk 3 - Cluster[s3cl].unde` | 8,473 | unit "Screw Mk 3 - Cluster" · 1 states |
| Game.pak | unde | `s3f1` | `unde/Screw Mk 3 - Formati[s3f1].unde` | 14,273 | unit "Screw Mk 3 - Formation 1" · 1 states |
| Game.pak | unde | `s3li` | `unde/Screw Mk 3 - Light[s3li].unde` | 12,637 | unit "Screw Mk 3 - Light" · 2 states |
| Game.pak | unde | `sc3l` | `unde/Screw Mk 3 - Loner[sc3l].unde` | 26,570 | unit "Screw Mk 3 - Loner" · 5 states |
| Game.pak | unde | `sc03` | `unde/Screw Mk 3[sc03].unde` | 26,541 | unit "Screw Mk 3" · 5 states |
| Game.pak | unde | `scre` | `unde/Screw[scre].unde` | 29,164 | unit "Screw" · 5 states |
| Game.pak | unde | `se50` | `unde/Secret - 500[se50].unde` | 7,539 | unit "Secret - 500" · 1 states |
| Game.pak | unde | `sels` | `unde/Secret - Large Silve[sels].unde` | 8,278 | unit "Secret - Large Silver" · 1 states |
| Game.pak | unde | `sess` | `unde/Secret - Small Shiel[sess].unde` | 8,281 | unit "Secret - Small Shields" · 1 states |
| Game.pak | unde | `ssat` | `unde/Shield Station - All[ssat].unde` | 9,368 | unit "Shield Station - All Terrain" · 1 states |
| Game.pak | unde | `shsb` | `unde/Shield Station - Bub[shsb].unde` | 8,397 | unit "Shield Station - Bubble" · 1 states |
| Game.pak | unde | `ssde` | `unde/Shield Station - Des[ssde].unde` | 11,253 | unit "Shield Station - Destruction" · 1 states |
| Game.pak | unde | `shde` | `unde/Shuriken - Destructi[shde].unde` | 8,283 | unit "Shuriken - Destruction" · 1 states |
| Game.pak | unde | `sh02` | `unde/Shuriken Mk 2[sh02].unde` | 35,138 | unit "Shuriken Mk 2" · 7 states |
| Game.pak | unde | `sh03` | `unde/Shuriken Mk 3[sh03].unde` | 33,028 | unit "Shuriken Mk 3" · 7 states |
| Game.pak | unde | `shur` | `unde/Shuriken[shur].unde` | 35,103 | unit "Shuriken" · 7 states |
| Game.pak | unde | `smbl` | `unde/Smoke - Black[smbl].unde` | 16,948 | unit "Smoke - Black" · 3 states |
| Game.pak | unde | `smcy` | `unde/Smoke - Cyan[smcy].unde` | 16,945 | unit "Smoke - Cyan" · 3 states |
| Game.pak | unde | `smgr` | `unde/Smoke - Green[smgr].unde` | 16,947 | unit "Smoke - Green" · 3 states |
| Game.pak | unde | `smor` | `unde/Smoke - Orange[smor].unde` | 16,950 | unit "Smoke - Orange" · 3 states |
| Game.pak | unde | `spla` | `unde/Splash - Large[spla].unde` | 14,498 | unit "Splash - Large" · 2 states |
| Game.pak | unde | `spmr` | `unde/Splash - Medium Ripp[spmr].unde` | 12,830 | unit "Splash - Medium Ripple" · 2 states |
| Game.pak | unde | `spme` | `unde/Splash - Medium[spme].unde` | 14,497 | unit "Splash - Medium" · 2 states |
| Game.pak | unde | `spsm` | `unde/Splash - Small[spsm].unde` | 13,536 | unit "Splash - Small" · 2 states |
| Game.pak | unde | `sptg` | `unde/Splash - Tiny Group[sptg].unde` | 12,631 | unit "Splash - Tiny Random Location" · 2 states |
| Game.pak | unde | `spti` | `unde/Splash - Tiny[spti].unde` | 12,575 | unit "Splash - Tiny" · 2 states |
| Game.pak | unde | `sgbg` | `unde/Swivel Gun - Back Gr[sgbg].unde` | 8,329 | unit "Swivel Gun - Back Green" · 1 states |
| Game.pak | unde | `sgba` | `unde/Swivel Gun - Backgro[sgba].unde` | 8,330 | unit "Swivel Gun - Background" · 1 states |
| Game.pak | unde | `sgbf` | `unde/Swivel Gun - Bullet [sgbf].unde` | 12,622 | unit "Swivel Gun - Bullet Flash" · 2 states |
| Game.pak | unde | `sgbh` | `unde/Swivel Gun - Bullet [sgbh].unde` | 12,619 | unit "Swivel Gun - Bullet Hit FX" · 2 states |
| Game.pak | unde | `sgbu` | `unde/Swivel Gun - Bullet[sgbu].unde` | 9,357 | unit "Swivel Gun - Bullet" · 1 states |
| Game.pak | unde | `sggr` | `unde/Swivel Gun - Green[sggr].unde` | 23,540 | unit "Swivel Gun - Green" · 4 states |
| Game.pak | unde | `swgu` | `unde/Swivel Gun[swgu].unde` | 23,536 | unit "Swivel Gun" · 4 states |
| Game.pak | unde | `tlbf` | `unde/Tank - Laser Bullet [tlbf].unde` | 12,621 | unit "Tank - Laser Bullet Flash" · 2 states |
| Game.pak | unde | `tlbh` | `unde/Tank - Laser Bullet [tlbh].unde` | 12,718 | unit "Tank - Laser Bullet Hit FX" · 2 states |
| Game.pak | unde | `talb` | `unde/Tank - Laser Bullet[talb].unde` | 8,403 | unit "Tank - Laser Bullet" · 1 states |
| Game.pak | unde | `tlcl` | `unde/Tank - Laser Cap Lig[tlcl].unde` | 17,561 | unit "Tank - Laser Cap Light" · 3 states |
| Game.pak | unde | `talc` | `unde/Tank - Laser Cap[talc].unde` | 13,907 | unit "Tank - Laser Cap" · 2 states |
| Game.pak | unde | `tltf` | `unde/Tank - Laser Track F[tltf].unde` | 8,453 | unit "Tank - Laser Track Flag" · 1 states |
| Game.pak | unde | `talt` | `unde/Tank - Laser Turret[talt].unde` | 24,408 | unit "Tank - Laser Turret" · 4 states |
| Game.pak | unde | `tala` | `unde/Tank - Laser[tala].unde` | 12,191 | unit "Tank - Laser" · 1 states |
| Game.pak | unde | `tpbf` | `unde/Tank - Pulse Bullet [tpbf].unde` | 12,709 | unit "Tank - Pulse Bullet Flash" · 2 states |
| Game.pak | unde | `tpbh` | `unde/Tank - Pulse Bullet [tpbh].unde` | 12,716 | unit "Tank - Pulse Bullet Hit FX" · 2 states |
| Game.pak | unde | `tapb` | `unde/Tank - Pulse Bullet[tapb].unde` | 8,641 | unit "Tank - Pulse Bullet" · 1 states |
| Game.pak | unde | `tpcl` | `unde/Tank - Pulse Cap Lig[tpcl].unde` | 17,561 | unit "Tank - Pulse Cap Light" · 3 states |
| Game.pak | unde | `tapc` | `unde/Tank - Pulse Cap[tapc].unde` | 13,907 | unit "Tank - Pulse Cap" · 2 states |
| Game.pak | unde | `tptf` | `unde/Tank - Pulse Track F[tptf].unde` | 8,450 | unit "Tank - Pulse Track Flag" · 1 states |
| Game.pak | unde | `tapt` | `unde/Tank - Pulse Turret[tapt].unde` | 22,044 | unit "Tank - Pulse Turret" · 4 states |
| Game.pak | unde | `tapu` | `unde/Tank - Pulse[tapu].unde` | 12,196 | unit "Tank - Pulse" · 1 states |
| Game.pak | unde | `tatr` | `unde/Tank - Tracks[tatr].unde` | 8,450 | unit "Tank - Tracks" · 1 states |
| Game.pak | unde | `tdes` | `unde/Tank Destruct[tdes].unde` | 24,213 | unit "Tank FX - Destruction" · 4 states |
| Game.pak | unde | `tfte` | `unde/Tank FX - Turret Exp[tfte].unde` | 8,302 | unit "Tank FX - Turret Explosion" · 1 states |
| Game.pak | unde | `tale` | `unde/Tank Large Explosion[tale].unde` | 8,272 | unit "Tank FX - Large Explosion" · 1 states |
| Game.pak | unde | `tase` | `unde/Tank Small Explosion[tase].unde` | 9,233 | unit "Tank FX - Small Explosion" · 1 states |
| Game.pak | unde | `test` | `unde/Test[test].unde` | 33,989 | unit "Test" · 7 states |
| Game.pak | unde | `tgbf` | `unde/Twin Gun - Bullet Fl[tgbf].unde` | 8,286 | unit "Twin Gun - Bullet Flash" · 1 states |
| Game.pak | unde | `tgbh` | `unde/Twin Gun - Bullet Hi[tgbh].unde` | 12,617 | unit "Twin Gun - Bullet Hit FX" · 2 states |
| Game.pak | unde | `tgbu` | `unde/Twin Gun - Bullet[tgbu].unde` | 8,379 | unit "Twin Gun - Bullet" · 1 states |
| Game.pak | unde | `tgcl` | `unde/Twin Gun - Cap Light[tgcl].unde` | 17,415 | unit "Twin Gun - Cap Light" · 3 states |
| Game.pak | unde | `tgca` | `unde/Twin Gun - Cap[tgca].unde` | 13,892 | unit "Twin Gun - Cap" · 2 states |
| Game.pak | unde | `tgde` | `unde/Twin Gun - Destructi[tgde].unde` | 25,163 | unit "Twin Gun - Destruction" · 4 states |
| Game.pak | unde | `tgle` | `unde/Twin Gun - Large Exp[tgle].unde` | 8,271 | unit "Twin Gun - Large Explosion" · 1 states |
| Game.pak | unde | `tgse` | `unde/Twin Gun - Small Exp[tgse].unde` | 9,265 | unit "Twin Gun - Small Explosions" · 1 states |
| Game.pak | unde | `tgtf` | `unde/Twin Gun - Track Fla[tgtf].unde` | 8,450 | unit "Twin Gun - Track Flag" · 1 states |
| Game.pak | unde | `tgtu` | `unde/Twin Gun - Turret[tgtu].unde` | 30,980 | unit "Twin Gun - Turret" · 5 states |
| Game.pak | unde | `twgu` | `unde/Twin Gun[twgu].unde` | 10,258 | unit "Twin Gun" · 1 states |
| Game.pak | wede | `aibg` | `wede/Air - Bacta Gun[aibg].wede` | 3,035 | weapon "Air - Bacta Gun" · 8 spawns |
| Game.pak | wede | `aiic` | `wede/Air - Ion Cannon[aiic].wede` | 2,236 | weapon "Air - Ion Cannon" · 3 spawns |
| Game.pak | wede | `aipb` | `wede/Air - Photon Beam[aipb].wede` | 1,903 | weapon "Air - Photon Beam" · 1 spawns |
| Game.pak | wede | `airg` | `wede/Air - Rear Gun[airg].wede` | 1,945 | weapon "Air - Rear Gun" · 1 spawns |
| Game.pak | wede | `plbo` | `wede/Ground - Plasma Bomb[plbo].wede` | 2,169 | weapon "Ground - Plasma Bomb" · 2 spawns |
| Game.pak | im16 | `cat1` | `im16/Canyon 1 Media[cat1].TGA` | 138,258 | TGA 96×720 |
| Game.pak | im16 | `isp2` | `im16/Island 2 Preview[isp2].TGA` | 89,396 | TGA 146×306 |
| Game.pak | im16 | `ism2` | `im16/Island 2 Map[ism2].TGA` | 3,456,018 | TGA 480×3600 |
| Game.pak | im16 | `ist2` | `im16/Island 2 Media[ist2].TGA` | 138,258 | TGA 96×720 |
| Game.pak | unde | `05e1` | `unde/Level 5 - End[05e1].unde` | 71,867 | unit "Level 5 - End" · 14 states |
| Game.pak | leve | `le09` | `leve/Level 09[le09].leve` | 10,447 | level "Carthage" · 67 objects |
| Game.pak | leve | `le10` | `leve/Level 10[le10].leve` | 9,396 | level "Thermopylae" · 60 objects |
| Game.pak | unde | `be01` | `unde/Beamer Mk 1[be01].unde` | 13,870 | unit "Beamer Mk 1" · 2 states |
| Game.pak | unde | `be02` | `unde/Beamer Mk 2[be02].unde` | 13,870 | unit "Beamer Mk 2" · 2 states |
| Game.pak | unde | `irmp` | `unde/Iris - Mine Projecti[irmp].unde` | 16,072 | unit "Iris - Mine Projectile" · 3 states |
| Game.pak | unde | `11m1` | `unde/Level 11 - Mid 1[11m1].unde` | 25,360 | unit "Level 11 - Mid 1" · 5 states |
| Game.pak | unde | `12e1` | `unde/Level 12 - End 1[12e1].unde` | 34,743 | unit "Level 12 - End 1" · 7 states |
| Game.pak | unde | `07e1` | `unde/Level 7 - End[07e1].unde` | 42,365 | unit "Level 7 - End" · 8 states |
| Game.pak | unde | `mide` | `unde/Mine - Destruction[mide].unde` | 14,536 | unit "Mine - Destruction" · 2 states |
| Game.pak | unde | `rben` | `unde/Random Bonus - Enemy[rben].unde` | 16,992 | unit "Random Bonus - Enemy" · 3 states |
| Game.pak | film | `de01` | `film/Demo 01[de01].film` | 40,296 | film le07 · 4809 ticks · score 25050 |
| Game.pak | film | `de02` | `film/Demo 02[de02].film` | 40,296 | film le06 · 8357 ticks · score 116180 |
| Game.pak | film | `de03` | `film/Demo 03[de03].film` | 40,296 | film le02 · 10058 ticks · score 57520 |
| Game.pak | film | `de04` | `film/Demo 04[de04].film` | 40,296 | film le08 · 5649 ticks · score 24670 |
| Game.pak | stli | `inte` | `stli/Interface[inte].stli` | 1,013 | 28 lines |
| Game.pak | stli | `pgsl` | `stli/Game[pgsl].stli` | 808 | 37 lines |
| Game.pak | stli | `pali` | `stli/Parse List[pali].stli` | 2 | 1 lines |
| Game.pak | stli | `cred` | `stli/Attributions[cred].stli` | 1,513 | 102 lines |
| Interface.pak | im16 | `decr` | `im16/Developer Credit[decr].TGA` | 614,418 | TGA 640×480 |
| Interface.pak | im16 | `edpa` | `im16/Editor Panel[edpa].TGA` | 107,538 | TGA 112×480 |
| Interface.pak | im16 | `pucr` | `im16/Publisher Credit[pucr].TGA` | 177,858 | TGA 260×342 |
| Interface.pak | im08 | `TESM` | `im08/Text - Small IA[TESM].gif` | 4,744 | GIF 852×18 · alpha plate |
| Interface.pak | im08 | `tesm` | `im08/Text - Small IC[tesm].gif` | 1,972 | GIF 852×18 · colour plate |
| Interface.pak | im16 | `back` | `im16/Background[back].TGA` | 614,444 | TGA 640×480 |
| Interface.pak | im16 | `menu` | `im16/Menu[menu].TGA` | 614,444 | TGA 640×480 |
| Interface.pak | im16 | `BIGR` | `im16/Editor Background[BIGR].TGA` | 98,282 | TGA 284×173 |
| Interface.pak | im16 | `adve` | `im16/Advertisment[adve].TGA` | 614,418 | TGA 640×480 |
| Music.pak | soun | `mu03` | `Music 3[mu03].aif` | 9,172,810 | AIFC ima4 · 2 ch · 134,892 packets · 8,633,088 frames · music |
| Music.pak | soun | `ammu` | `Ambient Music Loop[ammu].IMA` | 1,629,918 | AIFC ima4 · 2 ch · 23,966 packets · 1,533,824 frames · music |
| Music.pak | soun | `inmu` | `Interface Music Loop[inmu].IMA` | 2,798,658 | AIFC ima4 · 2 ch · 41,153 packets · 2,633,792 frames · music |

## 5. Sprite groups (alpha plate scanned on 8-bit system-CLUT indices; frames encoded)

| group | plate | frames | alpha maps | encoded bytes |
| --- | --- | ---: | ---: | ---: |
| `exsr` | 398×35 | 12 | 12 | 43,488 |
| `bocr` | 55×21 | 3 | 3 | 2,680 |
| `bash` | 1278×90 | 36 | 36 | 182,576 |
| `bgbu` | 830×25 | 36 | 36 | 58,464 |
| `bagu` | 235×75 | 5 | 5 | 42,716 |
| `burs` | 533×123 | 5 | 5 | 211,536 |
| `buzz` | 378×49 | 8 | 8 | 62,144 |
| `edut` | 330×37 | 3 | 3 | 4,816 |
| `galo` | 163×114 | 1 | 1 | 68,912 |
| `icbu` | 830×25 | 36 | 36 | 58,464 |
| `ioca` | 235×75 | 5 | 5 | 42,716 |
| `lagu` | 235×75 | 5 | 5 | 42,716 |
| `mine` | 1249×88 | 36 | 36 | 231,264 |
| `muxx` | 1052×19 | 30 | 30 | 54,480 |
| `mux2` | 1052×21 | 30 | 30 | 62,160 |
| `mux3` | 1052×21 | 30 | 30 | 62,160 |
| `mux4` | 1052×21 | 30 | 30 | 62,160 |
| `mux5` | 1052×21 | 30 | 30 | 62,160 |
| `pbbu` | 830×25 | 36 | 36 | 58,464 |
| `phbe` | 235×75 | 4 | 4 | 42,756 |
| `pdbu` | 866×26 | 36 | 36 | 64,368 |
| `pdli` | 172×75 | 3 | 3 | 36,332 |
| `plsh` | 666×85 | 8 | 8 | 204,992 |
| `ptbu` | 830×25 | 36 | 36 | 58,464 |
| `ptli` | 300×75 | 2 | 2 | 21,504 |
| `spla` | 172×36 | 5 | 5 | 19,340 |
| `tura` | 1082×32 | 36 | 36 | 105,840 |
| `vigr` | 302×92 | 2 | 2 | 102,360 |
| `zbbl` | 830×25 | 36 | 36 | 58,464 |
| `zbli` | 300×75 | 3 | 3 | 21,240 |
| `edbu` | 400×27 | 14 | 14 | 24,328 |
| `base` | 1119×131 | 24 | 24 | 336,520 |
| `cair` | 321×31 | 11 | 11 | 30,008 |
| `casl` | 752×27 | 30 | 30 | 58,800 |
| `cass` | 572×21 | 30 | 30 | 31,440 |
| `cycl` | 1190×35 | 36 | 36 | 130,464 |
| `exlg` | 758×90 | 12 | 12 | 178,392 |
| `flup` | 1202×34 | 30 | 30 | 129,480 |
| `flno` | 1282×66 | 48 | 48 | 207,168 |
| `flso` | 1282×66 | 36 | 36 | 155,376 |
| `glow` | 850×102 | 12 | 12 | 196,900 |
| `jgbu` | 866×26 | 36 | 36 | 64,368 |
| `jgli` | 80×75 | 2 | 2 | 10,704 |
| `lapb` | 1010×30 | 36 | 36 | 90,864 |
| `mebh` | 1400×30 | 14 | 14 | 126,408 |
| `mebu` | 667×58 | 14 | 14 | 115,992 |
| `pili` | 1249×88 | 30 | 30 | 192,720 |
| `pimu` | 1249×88 | 30 | 30 | 192,720 |
| `pish` | 1249×88 | 30 | 30 | 192,720 |
| `pbhf` | 235×75 | 1 | 1 | 10,024 |
| `pbta` | 51×18 | 3 | 3 | 2,152 |
| `plgu` | 1249×88 | 36 | 36 | 231,264 |
| `plat` | 1170×126 | 24 | 24 | 301,328 |
| `pl1b` | 394×48 | 7 | 7 | 63,980 |
| `pl1c` | 394×48 | 7 | 7 | 63,980 |
| `pl1g` | 394×48 | 7 | 7 | 63,980 |
| `pl1o` | 394×48 | 7 | 7 | 63,980 |
| `pl2b` | 394×48 | 7 | 7 | 63,980 |
| `pl2c` | 394×48 | 7 | 7 | 63,980 |
| `pl2g` | 394×48 | 7 | 7 | 63,980 |
| `pl2o` | 394×48 | 7 | 7 | 63,980 |
| `polb` | 1190×35 | 36 | 36 | 130,464 |
| `plli` | 80×75 | 2 | 2 | 10,704 |
| `plba` | 50×50 | 1 | 1 | 8,124 |
| `polo` | 1154×50 | 24 | 24 | 194,976 |
| `polr` | 1250×98 | 36 | 36 | 292,464 |
| `sgbu` | 974×29 | 36 | 36 | 83,808 |
| `sgpl` | 50×50 | 1 | 1 | 8,124 |
| `swgu` | 1250×98 | 36 | 36 | 292,464 |
| `tuic` | 1256×78 | 36 | 36 | 177,264 |
| `tula` | 1256×78 | 36 | 36 | 177,264 |
| `wesy` | 300×31 | 6 | 6 | 16,368 |
| `zaca` | 116×16 | 3 | 3 | 1,356 |
| `play` | 84×44 | 2 | 2 | 11,600 |
| `shme` | 300×20 | 2 | 2 | 10,032 |
| `suta` | 1190×55 | 24 | 24 | 208,640 |
| `bhro` | 1262×92 | 36 | 36 | 254,880 |
| `bsba` | 1202×52 | 24 | 24 | 212,640 |
| `bsbu` | 482×32 | 16 | 16 | 47,040 |
| `came` | 300×31 | 4 | 4 | 10,912 |
| `cagl` | 992×35 | 30 | 30 | 108,720 |
| `cags` | 812×29 | 30 | 30 | 69,840 |
| `roto` | 146×74 | 2 | 2 | 38,136 |
| `scso` | 1190×45 | 36 | 36 | 173,664 |
| `shst` | 482×32 | 16 | 16 | 47,040 |
| `shrl` | 272×47 | 6 | 6 | 42,480 |
| `shro` | 200×37 | 6 | 6 | 23,184 |
| `tufl` | 1271×96 | 36 | 36 | 279,648 |
| `tutw` | 1271×96 | 36 | 36 | 279,648 |
| `cast` | 482×32 | 16 | 16 | 47,040 |
| `elst` | 466×31 | 16 | 16 | 43,648 |
| `flas` | 452×47 | 10 | 10 | 70,800 |
| `noti` | 1200×37 | 8 | 8 | 98,736 |
| `ngbu` | 1273×84 | 36 | 36 | 208,800 |
| `ngli` | 172×75 | 3 | 3 | 36,332 |
| `ngsh` | 818×53 | 16 | 16 | 147,840 |
| `nsba` | 626×41 | 1 | 1 | 4,648 |
| `nust` | 434×29 | 16 | 16 | 37,248 |
| `panz` | 1256×116 | 24 | 24 | 280,512 |
| `pi1k` | 1262×36 | 30 | 30 | 71,280 |
| `pi2k` | 1274×38 | 30 | 30 | 90,720 |
| `p500` | 1172×20 | 30 | 30 | 65,520 |
| `pi5k` | 1262×44 | 30 | 30 | 130,320 |
| `psba` | 34×34 | 1 | 1 | 3,388 |
| `smop` | 770×34 | 24 | 24 | 81,312 |
| `psro` | 1154×34 | 36 | 36 | 121,968 |
| `raro` | 1273×84 | 36 | 36 | 208,800 |
| `raso` | 1273×84 | 36 | 36 | 208,800 |
| `rgdr` | 338×23 | 16 | 16 | 21,120 |
| `regu` | 218×75 | 5 | 5 | 39,508 |
| `scbu` | 1010×30 | 36 | 36 | 90,864 |
| `scdr` | 338×23 | 16 | 16 | 21,120 |
| `smbu` | 686×21 | 36 | 36 | 37,728 |
| `sc02` | 1226×50 | 36 | 36 | 201,744 |
| `sc03` | 1226×48 | 36 | 36 | 192,816 |
| `tusc` | 1250×80 | 36 | 36 | 187,488 |
| `bebu` | 338×23 | 16 | 16 | 21,120 |
| `beli` | 45×45 | 1 | 1 | 6,424 |
| `cs02` | 482×32 | 16 | 16 | 47,040 |
| `edpr` | 1000×37 | 27 | 27 | 111,240 |
| `lena` | 1068×56 | 12 | 12 | 197,184 |
| `nomc` | 188×92 | 1 | 1 | 63,708 |
| `tube` | 1271×96 | 36 | 36 | 279,648 |
| `tush` | 1250×80 | 36 | 36 | 187,488 |
| `tesm` | 852×18 | 91 | 90 | 32,084 |

## 6. Text

- `stli` lines: `edit` 5 · `inte` 28 · `pgsl` 37 · `pali` 1 · `cred` 102
- `flli` floats: `gafl` 220
- `idli` IDs: `edit` 1 · `tesp` 3 · `gate` 54 · `gaob` 40 · `gaso` 24 · `gasp` 8
- `reli` rects: `inre` 22
- `coli` colours: `gaco` 0x2B12
- `tefo` 54, `#Format_ID`: LEFT 28 · CENT 8 · RIGH 4 · CEBU 12 · CEGA 2
- `plde` keys: `pl01` 57 · `pl02` 57
- `wede` spawns (index order): `aibg` 8 · `aiic` 3 · `aipb` 1 · `airg` 1 · `plbo` 2
- `leve` objects (index order): `le01` 46 · `le02` 44 · `le03` 44 · `le04` 43 · `le05` 51 · `le06` 43 · `le07` 38 · `le08` 49 · `le11` 40 · `le12` 40 · `le09` 67 · `le10` 60
- `unde` 386 units · 1,167 states · numStates {1: 128, 2: 91, 3: 37, 4: 59, 5: 18, 6: 19, 7: 10, 8: 8, 9: 6, 10: 2, 11: 1, 12: 5, 13: 1, 14: 1} · numRules {5: 1167} · spawn sets per state {0: 788, 1: 285, 2: 64, 3: 11, 4: 15, 6: 2, 7: 2}
- Token values over all 473 text entries: INT 57,140 · FLOAT 19,815 · BOOL TRUE 4,201 / FALSE 64,203 · COLOR 3,223 · token errors 0

## 7. Sound

- Effects: 96 (mono 96, ima4 96, 44100 Hz) · packets 48,959 · frames 3,133,376 (the kit's CoreAudio-identical decode)
- Music `mu03`: 2 ch · 134,892 packets · 8,633,088 frames
- Music `ammu`: 2 ch · 23,966 packets · 1,533,824 frames
- Music `inmu`: 2 ch · 41,153 packets · 2,633,792 frames
- FORM size ≠ file − 8: `mu03` FORM size 76 bytes short of the file

## 8. Films

| film | version | seed | level | players | P1 ticks | P1 score | max input | P2 level | zero tail |
| --- | ---: | --- | --- | ---: | ---: | ---: | --- | --- | --- |
| `de01` | 10005 | 0x469c2 | `le07` | 1 | 4809 | 25050 | 0x3a | `none` | yes |
| `de02` | 10005 | 0x4f655 | `le06` | 1 | 8357 | 116180 | 0x48 | `none` | yes |
| `de03` | 10005 | 0x54c83 | `le02` | 1 | 10058 | 57520 | 0x4a | `none` | yes |
| `de04` | 10005 | 0x5afed | `le08` | 1 | 5649 | 24670 | 0x48 | `none` | yes |
| `last` | 10005 | 0x469c2 | `le07` | 1 | 4809 | 25050 | 0x3a | `none` | yes |

Totals: entries 872 (pak 871 + local 1), decoded 872, failures 0
