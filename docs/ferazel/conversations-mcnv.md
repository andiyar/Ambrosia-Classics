# Ferazel's Wand 1.0.3 — conversations (`Mcnv`), the conversation interpreter and its screen

Code readings only; nothing behaviour-verified. Date 2026-10-04.
Sources: raw listing `ghidra/Ferazel_pef.disasm.txt` (addresses), main and handler decompiles, TOC/data
words via `tools/pef.py` / `tools/const.py` / `tools/tocrefs.py`; all 29 `Mcnv` resources and all 24
`Mlvl` placement blocks decoded in Python from `Ferazel's Wand World Data.rsrc` (walker modelled on
`tools/rsrc_census.py`); PICT/`clut`/`snd ` names from `Sprites.rsrc`, `Backgrounds.rsrc`, `Sounds.rsrc`.

Scope: `.Conversation @ 1007a7e8`, `.HandleConvLine @ 1007a624`, `.HandleLineResponses @ 10079c60`,
`.HandleLineActions @ 1007a0fc`, `.OpenDefaultWorldConv @ 100487d4`, `.InitConversation @ 10078bd0`,
`.DrawConvPic @ 10078ee4`, `.DrawConvPicToScreen @ 10078f34`, `.DrawConvNameString @ 10078fc8`,
`.CharByCharDelay @ 10079094`, `.DrawStringCharByCharOrig @ 1007912c`, `.DrawStringCharByChar @ 10079210`,
`.DrawConvTextString @ 1007940c`, `.CopyConvToScreen @ 100797e4`, `.EraseConvNameAndText @ 100798cc`,
`.SimpleConv @ 10079a30`, `.ConvPressAnyKeyDeadTime @ 10078b14` — every routine named Conv/Talk/Dialog-for-
conversation in `tools/fer_names.txt`; the range 10078b14..1007aa88 holds exactly these. Callers: the
talker/sign arms of `.HitPlayerSprite` (handler dump l. 3910–4012), `.HandleXichraSprite`, `.HandleKeys`.

Conventions. "Line #n" is the **1-based** line number the data's targets use; the code's line index
is `i = n − 1` (0..19). `Mcnv` = the locked resource handle `*(*0x100a0440)` (TOC slot `-0x7400(r2)`).
Record `r` of the current level = `hdr + 4 + 16·r` (world-data §3.4), so the code's
`*hdl(100a0058) + 16·r + 8 + 2·k` is param `p(k+1)`. `G` = `_DAT_1009ffc0` (engine §9).

## 1. Who starts a conversation

### 1.1 Call sites  [HIGH]
| caller | raw | arguments `Conversation(id, recIdx, sprite)` | gate |
|---|---|---|---|
| NPC types 2951..2969, Box arm of `.HitPlayerSprite` | `10056d14..10056d68` | `p1` of the NPC's record, `sprite+0x48`, the NPC | `sprite+0xb0 == 0` and cooldown `*0x100a06cc == 0`; sets cooldown **150** (`li r0,0x96` `10056d44`). No `p1 > 100` test |
| signs/books 2903..2909 except 2907, graves 2833..2836 | `10057040..10057130` | `p1`, `sprite+0x48`, the sprite | UP (input 2) or `p4 == 0`; `p1 ≠ 0`; cooldown 0 → cooldown **90** (`li r0,0x5a` `10057070`), `p4 = 1` written **before** the call (`1005708c`); Conversation only if `p1 > 100` (`cmpwi r3,0x64` `10057124`) |
| `.HandleXichraSprite` | `1008e74c`, `1008ec5c`, `1008f704` | 251, 250, 252 | boss phases (bosses-2 §6) |

The cooldown counts down 1 per frame in `.HandlePlayerSprite` (`1004e560..1004e578`) [HIGH]; nothing
else stops an NPC from re-triggering, so a player who stays in contact replays the conversation every
150 frames [MED: contact persistence not traced].

`.SimpleConv(pict, name, text)` (one page, no menu, no actions) is used by the 2902 sign (`PICT 4020`,
"Wooden Sign", `STR# 500` string `p1`, `10057100`) and by three USE-item hints in `.HandleKeys`
(`100534a0..100534d8`, `PICT 4001`, "Ferazel" `0x100a60a0`): item 1/2/3 (keys) → string `0x100a616f`
("You don't need to select keys…"), item 0xe/0xf (shields) → `0x100a60e7`, item 0x16 (Red Xichron) →
`0x100a60a8` [HIGH: raw + data bytes].

### 1.2 Placement census (all 24 levels; talker types read by the arms above)  [HIGH]
| Mcnv | level / record | type (PICT name) | rec flag / params |
|---|---|---|---|
| 200 | L1 rec 12 | 2952 'merchant' | 1, p 200,0,0,0 |
| 201 | L1 rec 157 | 2951 'Geroditus' | 1 |
| 202 | L70 rec 68 | 2956 'Dimbo' | 1 |
| 203 | L2 rec 188 | 2954 'Sitting Habnabit' | 1 |
| 204 | **not placed** | — | — |
| 205 | L3 rec 181 | 2954 'Sitting Habnabit' | 1 |
| 206 | L11 rec 135 | 2955 'Nimbo' | 1 |
| 207 | L30 rec 255 | 2952 'merchant' | 1 |
| 208 | L40 rec 1 | 2953 'Limping Habnabit' | 1 |
| 209 | L62 rec 1 | 2957 'Hooded Figure' | 1 |
| 210 | L45 rec 249 | 2954 'Sitting Habnabit' | 1 |
| 211 | L31 rec 304 | 2965 'Left Bluebrown merchant' | 1 |
| 212 / 213 / 214 / 401 | L70 rec 67 / 66 / 88 / 72 | 2952 / 2963 'Gray-Robed Short Hooded' / 2957 (p3 = 1) / 2964 'Hooded Bluegray Merchant' | 1 |
| 220 | L11 rec 283 | 2956 'Dimbo' | **99** (dormant; activated by Mcnv 221, §4) |
| 221 | L22 rec 405 | 2956 'Dimbo' | 1 |
| 250 / 251 / 252 | — (code constants) | Xichra | — |
| 260 / 261 | L21 rec 207 / 89 | 2833 '*Grave 1' / 2834 '*Grave 2' | 1 |
| 280..283 | L70 rec 2 / 69 / 70 / 71 | 2906 'Steel Plaque' | 1 |
| 300 | L21 rec 318 | 2962 'Gray-Robed Sitting Habnabit' | 1 |
| 400 | L4 rec 214 | 2952 'merchant' | 1 |

Also: L4 rec 88 is a 2952 with flag 0 and `p1 = 0` (never spawned; if it were, `Conversation(0)` would
fail and report the error string at `0x100a6cfc`); L21 rec 90 is a 2836 grave with `p1 = 1` (≤ 100:
touching it only sets the cooldown and `p4`). Every placement has `p2..p4 = 0` except 214's `p3 = 1`.

## 2. `Mcnv` record format

### 2.1 Resource and loading  [HIGH]
29 resources, ids 200–214, 220, 221, 250–252, 260, 261, 280–283, 300, 400, 401; every one is exactly
**36,936 B = 0x100 + 20 × 0x72a**. `.OpenDefaultWorldConv(id)` opens the world file, `GetResource('Mcnv', id)`
(`0x4d636e76`), `DetachResource`, closes the file, `HLock`; the previous conversation's handle is
disposed first. `.Conversation` turns a negative id positive (`1007a814..1007a83c`). On failure it
reports "Error attempting to load the conversation resource!…" (`0x100a6cfc`) and returns.

Header `+0x00..+0xff`: a pstr equal to the resource name ("Rojinko Conv", …) then zeros, in all 29.
**No code reads it**: the five TOC loads of the handle slot (`tocrefs 100a0440`: OpenDefaultWorldConv,
HandleLineResponses, HandleLineActions, HandleConvLine, Conversation) all address `i·0x72a + ≥ 0x100`.

### 2.2 Line record (20 per resource; line `i` at `Mcnv + 0x100 + i·0x72a`, 0x72a bytes)  [HIGH]
The code adds its field offsets to `Mcnv + i·0x72a` (`mulli rX,rY,0x72a`), so code offset = record
offset + 0x100. This confirms the reviewer's framing of world-data §5 (corr. #10).

| rec off | code off | type | meaning | raw |
|---|---|---|---|---|
| +0x000 | +0x100 | pstr[256] | **text** (spoken; typed out char by char) | `1007a714` |
| +0x100 | +0x200 | pstr[256] | **speaker name** | `1007a6e8` |
| +0x200 + 0x100·k | +0x300 + 0x100·k | pstr[256] × 5 | **response k** text (k = 0..4) | `10079d60`, `10079e44`, `10079ecc` |
| +0x700 + 2·k | +0x800 + 2·k | i16 × 5 | **response k target**; 0 = no response k. Slot 0 = 0 ⇒ the line has no menu | `10079cf8`, `10079d48`, `1007a078` |
| +0x70a | +0x80a | i16 | **portrait** PICT id; 0 = the line is never displayed (logic node) | `1007a6b4`, `1007a6dc`, `1007a86c` |
| +0x70c | +0x80c | i16 | **condition type** (§3.3) | `1007a148` |
| +0x70e / +0x710 | +0x80e / +0x810 | i16, i16 | condition args A / B | `1007a18c`, `1007a158` |
| +0x712 | +0x812 | i16 | target when the condition is true | `1007a264` |
| +0x714..+0x71b | +0x814..+0x81b | 8 B | **unread**; zero in all 580 lines | (no code offset in 0x814..0x81b) |
| +0x71c / +0x71e / +0x720 | +0x81c..+0x820 | i16 × 3 | **action 1**: type, A, B (§3.4) | `1007a2dc..1007a2e4` |
| +0x722 / +0x724 / +0x726 | +0x822..+0x826 | i16 × 3 | **action 2**: type, A, B | `1007a300..1007a308` |
| +0x728 | +0x828 | i16 | **next** target; 0 = sequential | `1007a580` |

Text encoding [HIGH data]: Pascal strings in Mac Roman (curly quotes, em dash, ellipsis), ≤ 247 chars
of text, ≤ 98 per response, ≤ 20 per name in the shipped data. Bytes after a pstr's length are stale
editor residue (120 fields carry older text there) and are never read: `.DrawConvTextString` copies
the pstr by its length byte (`_CopyPString`). Designer comments live in pic-0 lines' text
("[magic 30 coin check]", "[been here check]") and in a response slot whose target is 0 (Mcnv 200/204/
207/211 line #20 R4 "(if he's seen you before, use the second greeting)") — neither is ever drawn.

### 2.3 Target encoding (response targets, condition target, next)  [HIGH]
All three use one conversion (`1007a078..1007a0b4`, `1007a264..1007a2a4`, `1007a58c..1007a5c8`):
`t == 20 → 999`; then `t > 0 → t − 1`; `t < 0 → t + 1`; and `.HandleConvLine` turns a negative index
positive **and skips the display** (`1007a670..1007a684`, flag r27 = 0 → branch to `1007a770`).

| t | effect |
|---|---|
| 1..19 | go to line #t, display it |
| 20 or ≥ 21 | end (index ≥ 20 leaves the loop `cmpwi r0,0x14; bge` `1007a8a4`) |
| −2..−20 | go to line #\|t\| **without displaying its text/name/portrait**; its menu, condition and actions still run |
| −1 | becomes index 0 with no sign: line #1, displayed |
| ≤ −21 | index ≥ 20 without the end test in between: reads past the 20 lines (none in the data) |
| 0 in *next* | sequential: `i < 19 → i + 1`, `i = 19 → 0` (`1007a5d0..1007a5e8`) |

Shipped values [HIGH data]: response targets −17..17; next ∈ {−16, −11, −3, 0, 1..17, 20, 21, 100};
condition targets −5..18. The common idiom `next = −3` re-opens line #3's menu without repeating
its text; "−10/−11/−15/−17" jump silently into price/stock checks.

## 3. The interpreter

### 3.1 Conversation  [HIGH]
`.Conversation(id, recIdx, sprite)` (`1007a7e8`): store `sprite` at `*0x100a0bec` (`1007a81c`, for
action 9); `SetResWorldFile`; clear the abort flag `*0x100a0c14`; load; `DrawConvPic(line#1 pic)`
into the frame GWorld, `CopyConvToScreen`, `DrawConvPicToScreen(line#1 pic)`; **index = 19**
(`li r0,0x13` `1007a888`); `while index < 20 && !abort: HandleConvLine(&index, recIdx)`. Afterwards
erase name/text, restore the res file, reset the 10 fade slots, wait until no key is down, and
redraw the game view (`_WrapCopyToScreen`) [HIGH for the order; MED for the redraw's arguments].
So **line #20 is the entry node** of every conversation; when it is empty (pic 0, no menu, cond 0,
actions 0, next 0) it falls through to line #1 (`i = 19 → 0`).

### 3.2 One line: `.HandleConvLine(&index, recIdx)`  [HIGH]
1. Escape (`IsPressed(0x35)`) → index 21, abort (`1007a640..1007a66c`).
2. Negative index → negate, **skip 3–4**.
3. If `0 < i < 20` and the line's pic ≠ 0: `DrawConvPicToScreen(pic)` (r3 = pic, `1007a6b4..1007a6c0`) and
   erase name + text areas. (Index 0 does not redraw; Conversation drew line #1's portrait already.)
4. If pic ≠ 0: draw the name (`+0x200`), type the text (`+0x100`, animated, `r5 = 1` `1007a700`);
   Escape → abort; wait for all keys up; `.ConvPressAnyKeyDeadTime`; wait for all keys up.
5. `.HandleLineResponses`; only if it returns 0 (no menu) → `.HandleLineActions(&index, recIdx)`
   (`1007a770..1007a788`). **A line with a menu never evaluates its condition, actions or next.**
   (No shipped line has both: checked over all 580.)
6. Escape → abort.

### 3.3 Menu: `.HandleLineResponses`  [HIGH]
If response-0 target (`+0x800`) is 0 → return 0. Else: portrait **4001** (`li r3,0xfa1` `10079d0c`, the
Ferazel portrait), erase, name "Ferazel" (pstr at `0x100a6cc6`, `subi r3,r2,0xb7a` `10079d18`). Row
tops are `origin.v + 0x2b + Σ height` of the earlier responses, height from
`CalcWrappedStringInBoxHeight(text, 214 × 400 box)` (`li r6,0xd6; li r7,0x190` `10079cd8`). Loop: draw
every response with target ≠ 0 in RGB **(0x5555, 0x5555, 0x5555)** (`0x100a6cc0`), then the
selected one again in **black** (`0x100a6c40` = 0,0,0); Escape → abort (index 21); wait for all input
keys up; wait for one of input **3, 2, 6, 8, 7, 5**, **Return (0x24)** or **keypad Enter (0x4c)**
(`10079f38..10079fc8`); input 2 (up) → selection −1 if > 0; input 3 (down) → +1 if `sel < 5` and
response `sel+1` has a target (`+0x802 + 2·sel` `1007a02c`); anything else confirms. Selection starts
at 0 on every entry. On confirm: index = converted target of the selected slot (§2.3), return 1.
Responses must be contiguous from slot 0 (a hole stops the cursor; the data has none; max 4 used).
Latent: with 5 responses the down test at `sel = 4` reads `+0x80a` (the pic) as "response 5" and
can select slot 5, whose text would be `+0x800` (the target array) — no shipped line has 5.

### 3.4 Conditions and actions: `.HandleLineActions(&index, recIdx)`  [HIGH]
**Condition** (`1007a148..1007a258`, type `+0x80c`; result in r11): type 0 → skip.

| type | true when | raw | used |
|---|---|---|---|
| 1 | coins `G+0x10` ≥ A (signed) | `1007a188..1007a1a0` (`srawi/rlwinm/subfc/adde` = signed ≥) | 8 |
| 2 | some slot k < 27 holds **item** A (`G+0x24+10k == A`, spell flag `+0x2c == 0`) with count `+0x26` ≥ B | `1007a1a8..1007a1f8` | 5 |
| 3 | **never** — `beq 0x1007a258` with r11 = 0 (`1007a154..1007a160`) | | **4** (dead in code) |
| 4 | `0 ≤ recIdx ≤ 0x1ff` and own record param `p(A+1)` low byte ≠ 0 (`lha 0x8(rec+2A)`, `rlwinm …0x18,0x1f`) | `1007a200..1007a234` | 9 |
| 5 | world flag `G+0xad8+2A == B` | `1007a23c..1007a254` (`cntlzw`) | 8 |
| < 0 or > 5 | never | `1007a174`, `1007a180` | 0 |

If true: index = converted `+0x812` target and **return** — the line's two actions and its next are
skipped (`1007a260..1007a2a8`). Else the two actions run in order (`1007a2ac..1007a568`), dispatched by
`type` through the jump table at `r2 − 0xb70 = 0x100a6cd0` (11 words, `1007a320..1007a330`; `cmplwi 0xa;
bgt` → none):

| type | jump | effect | used |
|---|---|---|---|
| 0, 7, 8 | `1007a55c` | nothing | 7, 8: 0 |
| 1 | `1007a334` | coins `G+0x10 −= A`, floor 0; `UpdateTextStats(0)` | 9 |
| 2 | `1007a364` | **give item A × B** (B = 0 → 1): first slot that is empty (id −1) or holds item A with spell flag 0; id = A, flag = 0, count += B, cap 99; `STPlayRegSound(*0x100a02d4, 1, 0x100)` — the slot `.InitSounds` fills from `FUN_10091748(0x1f5)` = snd 501 'coin bonus' (`10046020..10046030`; the gold-Xichron pickup sound) [MED: loader unnamed]; `UpdateItemStat`; `*0x1024b4cc = slot`, `*0x1024b4ca = 30`. No free slot → nothing (coins already taken by an earlier action) | 11 |
| 3 | `1007a438` | `RemoveItem(A)` B times (B ≤ 0 → once); `UpdateItemStat`. `.RemoveItem` matches item slots only and is a no-op when A is not held | 8 |
| 4 | `1007a484` | `0 ≤ recIdx ≤ 0x1ff` → own record `p(A+1) = 1` (live level header) | 12 |
| 5 | `1007a4b8` | world flag `G+0xad8+2A = B` | 5 |
| 6 | `1007a4cc` | record **A** of the current level: `p(B+1) = 1` (no range check) | 2 |
| 9 | `1007a4f8` | if the conversation sprite ≠ 0: `sprite+0xe9 = 1` (kill request) and its record's spawn byte `hdr+4+16·(sprite+0x48) = 0` | 1 |
| 10 | `1007a530` | save block `+0x19998 + 0x2000·B + 16·A` = 1: the spawn byte of record A in **level B's snapshot** | 1 |

Then **next** (`1007a56c..1007a5e8`, §2.3). Action 2 never writes a spell slot (flag `+0x2c` is
stored 0, `stb r3,0x2c(r4)` with r3 = 0 at `1007a3e0`) — **conversations cannot teach spells** [HIGH].
The two words `0x1024b4ca/cc` (TOC slots `0x100a0bf0/bf4`) are written only here; no other TOC slot holds
those addresses (scan of all TOC words) and the item-pickup highlight is a different word
(`0x1024b502`, slot `0x1009fda8`), so the grant has **no selection flash** [MED: an offset access from
a lower base would defeat the scan; slot `0x1009ffa4` → `0x1024b4c8` is used only at `+0` by
`.InitGameGlobals`].

World flags [HIGH]: 1024 i16 at `G+0xad8` cleared by `.InitGameGlobals` (`10001744..10001764`, loop
0x400); writers: action 5 and Bonus trigger 1058 (`p1` = flag, `p2` = value or 1; `10055bf8/10055c10`);
readers: condition 5 only. Shipped use: flags 1..6 (§4.2).

Persistence [HIGH for the stores; MED for the consequences]: actions 4/6/9 write the **live** level
header, so they last for the visit and are carried into the level's save snapshot by a save point or
level end (save-continue §2); re-entering a level without a snapshot reloads the `Mlvl` and forgets
them. World flags and inventory live in `G` (saved). Action 10 is effective only if level B's
`G+0x176+2B` snapshot flag is set when it is re-entered (save-continue §2.3).

## 4. The 29 conversations, decoded

### 4.1 Summary table  [HIGH: data decode + code semantics of §3]
"Lines" = lines that carry content; "dead" = unreachable under the shipped code. Item names per
pickups-boxes §1.8 (ids 0..11 from PICT 702 captions [HIGH], higher ids PICT 3200+id names [MED];
items 17 and 18 are HIGH here: 207's own response strings read "Buy Escape Ring (80 coins)" / "Buy Ice
Pick (500 coins)" — ⚑ corrected (review 2a, 2026-10-04) #8).

| id (name) | lines / portraits | menu(s) | conditions | actions (decoded) |
|---|---|---|---|---|
| 200 Rojinko Conv (L1) | #1–#20, 4002 | #3 (4 replies), #5 shop (3), #12 (3) | #20 c4 own p3; #16 c3 (dead); #17 has ≥2 item 4; #15 has ≥1 item 5; #10 coins ≥30; #11 coins ≥50 | #7 coins −30, **give item 4 (Magic Potion) ×1**; #8 coins −50, **give item 5 (Health Potion) ×1**; #9 own p2 = 1; #13 **RemoveItem(2) Gold Key** |
| 201 Geroditus conv 1 (L1) | #1–#16, 4001/4007 | — | #20 c4 own p2 → #16 | #14, #15 own p2 = 1 |
| 202 Andrew (L70) | #1–#7, #10, 4001/4008 | — | #20 c3 (dead; meant → #10) | #7 **RemoveItem(1) Steel Key** |
| 203 Sernis magic crystal 1 (L2) | #1–#5, 4001/4006 | — | — | none (the crystal is the placed 1341 max-magic upgrade, L2 rec 187, 98 px to his right [MED association]) |
| 204 Unfriendly Fellow (unplaced) | #1–#16, 4002 | #3, #5 shop, #12 | #20, #16 c3 (dead); #10 coins ≥100; #11 coins ≥250 | #7 coins −40, give item 6 ×3; #8 coins −60, give item 6 ×10; #9 RemoveItem(1); #13 RemoveItem(2) |
| 205 Wounded Habnabit (L3) | #1–#15, 4001/4003 | #4 (2) | #20 c4 own p2 → #13; #13 c4 own p3 → #15; #3, #12 has item 5 → #4 | #20, #1 own p2 = 1; #5 **RemoveItem(5)** (the potion you give); #8 **give item 3 (Platinum Key) ×1**; #9 own p3 = 1 |
| 206 Nimbo conv (L11) | #1–#17, 4001/4013 | #12 (2) | #20 flag1 = 1 → #12; #9 flag6 = 1 → #10; #10 flag4 = 1 → #17; #16 c4 own p2 → #7 | #1, #3 own p2 = 1; #2 flag5 = 1; #13 coins −250, flag1 = 0; #17 **give item 6 (Fire Seeds) ×99, item 26 (Ziridium Seeds) ×99** |
| 207 Elber Ice Merchant (L30) | #1–#16, 4003 | #3, #5 shop, #12 | #20 c4 own p3 → #14; #16 c4 own p2 → #2; #10 coins ≥500; #11 coins ≥80 | #1 own p2 = 1; #7 coins −500, **give item 18 (Ice Pick) ×1**; #8 coins −80, **give item 17 (Escape/Green Ring) ×1**; #9 RemoveItem(1); #13 own p3 = 1 |
| 208 Korta conv (L40) | #1–#10, 4001/4005 | — | #20 flag3 = 1 → #10; #16 flag2 = 1 → #8 | #1 flag2 = 1 |
| 209 Hooded Figure (L62) | #1–#7, #14, 4001/4017 | #5 (2) | #20 flag4 = 1 → #14; #1 has ≥20 item 22 → −5 (#5 silently) | #6 **RemoveItem(22) ×20** (Red Xichrons), record 0 p4 = 1; #7 flag4 = 1; #14 record 0 p4 = 1 |
| 210 Babbling conv (L45) | #1–#4, 4006 | — | — | — |
| 211 Cedric Ice Merchant (L31) | #1–#18, 4003 | #3 (4), #5 shop, #12 (2) | #20 c4 own p3 → #14; #16 c4 own p2 → #2; #10 coins ≥30; #11 coins ≥100 | #1 own p2 = 1; #7 coins −30, give item 6 ×5; #8 coins −100, give item 6 ×20; #9 RemoveItem(1); #13 own p3 = 1 (dead line) |
| 212 Jason conv (L70) | #1–#8, 4001/4023 | — | #8 type 0 with a stray target 21 (ignored) | — |
| 213 Eric Conv (L70) | #1–#2, #10–#11, #13–#17, 4001/4030–4033 | #2 (3) | — | — |
| 214 AH conv (L70) | #1–#2, 4001/4015 | — | — | — |
| 220 Dimbo saved (L11, dormant) | #1, 4014 | — | — | — |
| 221 Dimbo (L22) | #1, #5–#9, 4001/4014 | — | #20 flag5 = 1 → #5 | #7 flag6 = 1; #8 **remove the talker** (action 9) and **L11 snapshot record 283 spawn = 1** (action 10) |
| 250 / 251 Xichra 1 / 2 | #1, 4016 | — | — | — |
| 252 Xichra 3 | #1–#3, 4001/4019 | — | — | — |
| 260 / 261 Grave 1 / 2 (L21) | #1, 4024 | — | — | — |
| 280–283 plaques (L70) | #1–#2, 4025 (+4001) | — | 283 #2 type 0 stray target 21 | — |
| 300 Obfusc Character (L21) | #1–#7, 4001/4022 | — | #4 flag5 = 1 → #5 | — |
| 400 Statue spell warn guy (L4) | #1–#3, 4001/4003 | — | — | — |
| 401 Ben conv (L70) | #1–#2, 4001/4009 | — | — | — |

Totals [HIGH data]: condition types used 1×8, 2×5, 3×4, 4×9, 5×8; action types used 1×9, 2×11, 3×8,
4×12, 5×5, 6×2, 9×1, 10×1; lines with a menu have no condition/action in all 29.

### 4.2 Flows with logic (code semantics)  [HIGH unless noted]
- **200 Rojinko** (L1): entry #20 tests own p3 (→ #14 "I hate you"), but nothing in 200 sets p3 (the
  insult line #13 carries action 3 = RemoveItem(Gold Key), not action 4), so #14 is dead; #16's
  "been here" test is type 3, so **the second greeting #2 is dead** and every visit starts at #1.
  Shop: Magic Potion refused if you hold ≥ 2 (#17 → #18), else needs ≥ 30 coins; Health Potion refused
  if you hold ≥ 1, else needs ≥ 50. "No thanks"/"I should be going" → #9 sets own p2 (read by nothing).
  #19 (duplicate of #18) is dead.
- **201 Geroditus** (L1): first talk plays #1..#15 (sets own p2); later talks #16 only.
- **202 Andrew Welch** (L70): entry test is type 3 → never #10 "Leave me in peace"; every visit replays
  #1..#7 and #7 removes one Steel Key if held.
- **204 Unfriendly Fellow** (unplaced): prices in the replies (100/250) are the coin *checks*; the
  amounts actually taken are **40/60**. Both "been here"/"insulted" tests are type 3 (dead).
- **205 Wounded Habnabit** (L3): needs a Health Potion in the inventory; giving it (#5) removes one,
  then #8 grants the **Platinum Key**, #9 sets own p3 → later visits #13 → #15 "Many thanks". Refusing
  ends at #14; no potion → #10/#11.
- **206 Nimbo** (L11): flag 1 (set by trigger 1058, L2 rec 228, p1 = 1) → "Thief!" menu: paying takes
  **250 coins with no balance check** (floor 0) and clears flag 1. Flag 6 (Dimbo met, §221) and flag 4
  (Hooded Figure paid) together → #17 gives 99 Fire Seeds + 99 Ziridium Seeds; nothing clears a
  flag afterwards, so **every later visit refills both to 99** [HIGH by the data; behaviour MED].
  Flag 6 without flag 4 → #11 "come back once you've found a way into the Mountains".
- **207 Elber** (L30): the only seller of the **Ice Pick (item 18, 500 coins)** and of the
  **Escape/Green Ring (item 17, 80 coins)**; repeat purchases allowed (count +1, cap 99). Leaving through
  "No thanks" / "I should really be going" (#9) removes a Steel Key if held. Insulting him (#13) sets own
  p3 → next visit greets with #14 "favorite little rat-faced buffoon".
- **208 Korta** (L40): flag 2 (met) → #8 "Make haste"; flag 3 (trigger 1058, L40 rec 223, p1 = 3,
  p2 = 1 — the gauntlet) → #10.
- **209 Hooded Figure** (L62): with ≥ 20 Red Xichrons (item 22) the menu "Yes/No" appears; Yes removes
  20, sets record 0's p4 = 1 — **L62 rec 0 is a 2940 gate with p1 = 0**, so the gate opens
  (pickups-boxes §2.4.4) — and sets flag 4. Later visits (#14) re-set the gate record.
- **211 Cedric** (L31): fire seeds 5 for 30 / 20 for 100; "ice walls" reply points to Elber; #13
  (would set p3) is reachable by no target, so #14 is dead.
- **221 Dimbo** (L22): only after flag 5 (Nimbo met, 206 #2): sets flag 6, removes the Dimbo sprite
  for good (record spawn byte 0) and arms **L11 rec 283** (Mcnv 220 "Dimbo saved", flag 99 in the
  shipped `Mlvl`) in the L11 snapshot.
- **300 Thedorus** (L21): flag 5 adds the "Dimbo?" exchange (#5, #6).

### 4.3 Item / spell grant answer (INDEX 3 second half, INDEX 29 conversation part)  [HIGH]
| item | given by | price / condition | removed by |
|---|---|---|---|
| 3 Platinum Key | 205 #8 (L3) | give a Health Potion | — |
| 4 Magic Potion | 200 #7 (L1) | 30 coins, hold < 2 | — |
| 5 Health Potion | 200 #8 (L1) | 50 coins, hold 0 | 205 #5 |
| 6 Fire Seeds | 211 #7/#8 (L31), 206 #17 (L11), [204 unplaced] | 30→5, 100→20; gift ×99 | — |
| 17 Green Ring (Escape) | 207 #8 (L30) | 80 coins | — |
| 18 **Ice Pick** | 207 #7 (L30) | 500 coins | — |
| 26 Ziridium Seeds | 206 #17 (L11) | gift ×99 | — |
| 1 Steel Key / 2 Gold Key | — | — | type-3 actions: 202 #7, 207 #9, 211 #9 (Steel); 200 #13 (Gold); [204 #9 Steel, #13 Gold] |
| 22 Red Xichron | — | — | 209 #6 (×20) |

**No conversation grants a spell, the Vorpal Dirk (21), the Hammer (8), keys 1/2, the Light Orb (20)
or items 7, 9–16, 19, 23–25.** Spell 2 and spell 7 therefore stay ungranted (pickups-boxes §1.7).

## 5. Implemented vs used
- Condition types implemented 1, 2, 4, 5; **type 3 is accepted and always false** — yet the data uses it
  4 times (200 #16, 202 #20, 204 #16, 204 #20), always shaped like the type-4 own-flag test (A = 1/2,
  B = 0) on "been here"/"insulted" nodes [HIGH code; LOW for intent].
- Action types implemented 1–6, 9, 10; **7 and 8 are no-ops** (jump to `1007a55c`), unused. Action 3 is
  used correctly twice (205 #5, 209 #6) and six times in the own-flag shape `[3, 1|2, 0]` on farewell/
  insult lines of 200, 202, 204, 207, 211, where it **removes a Steel/Gold Key** [HIGH code; LOW intent].
- Unused data: Mcnv 204 (no placement); line field `+0x714..+0x71b`; header pstr; condition target on
  type-0 lines (212 #8, 283 #2). Dead lines: 200 #2/#14/#19, 202 #10, 204 #2/#14, 211 #13/#14,
  213 #15 (no target reaches it), 203 #6 (empty).
- Portraits (Sprites.rsrc, all 96×96): used 4001–4003, 4005–4009, 4013–4017, 4019, 4022–4025, 4030–4033
  by `Mcnv`, 4020 by signs (`SimpleConv`); **never used: 3999, 4004, 4010 'Taryn', 4011 'Sara',
  4012 'Matriarch', 4018, 4021** (talker types 2958 'Taryn', 2959 'Sara', 2960 'Forest Nymph
  Matriarch', 2961 are never placed either) [HIGH data].

## 6. On-screen conversation

### 6.1 Geometry and resources  [HIGH]
`.InitConversation` (once, from `.InitTiles`): loads `clut` 4000 'dialogue palette' (`GetCTable(4000)`,
`10078cf4`) into `*0x100a0c0c` — **never used afterwards** (only TOC load of that slot is here); an
8-bit GWorld 387×308 (`li r6,0x183; li r7,0x134` `10078d34`) with the game's colour table, into which
**PICT 4000** (the 387×308 frame, Sprites.rsrc) is drawn (`10078e44`); a 1-bit 211×192 GWorld painted
white (`10078d98`, `ForeColor(0x1e)`), whose pixmap is fetched by `.DrawConvTextString` and never drawn
[MED: unused]; portrait rect (24, 49)–(120, 145) (`SetRect …0x18,0x31,0x78,0x91` `10078e68..78`);
origin `*0x100a0bfc` = (v 0x2e, h 0x7e) = **(46, 126) on screen** (`10078e80..8c`).

| element | frame-local position | raw |
|---|---|---|
| portrait (96×96) | (24, 49)–(120, 145) | `10078e68..78`, offset by origin in `.DrawConvPicToScreen` |
| speaker name | centred in 180 px: x = 0x13 + (180 − width)/2, baseline y = 0x114 (276); Times (font 20) 18 pt, black | `10078fec..1007903c` |
| text / responses | x = 0x9a (154), first baseline y = 0x1d + 0xe = 43, wrap width 0xd6 = 214 px, line step 0x12 = 18 | `.DrawConvTextString` |
| erase rects (copied back from the frame GWorld) | text (154, 29)–(372, 221); name (19, 260)–(199, 300) | `.EraseConvNameAndText` |

### 6.2 Text typing  [HIGH]
`.DrawConvTextString` appends a space, word-wraps at spaces when the running width exceeds 214 px,
and draws each wrapped chunk with `.DrawStringCharByChar` (spoken text, flag 1) or
`.DrawStringCharByCharOrig` (responses, flag 0: whole chunk at once in the given RGB). Both draw
characters 1..len−1 of the chunk (the trailing space is dropped). The typer keeps a 10-slot trail
(`*0x100a0c10`, 8 bytes each: char, x, y, age): each step puts the next character in a free slot
(age 0), redraws all slots in grey `(10 − age)·4000` (`subfic 0xa; mulli 0xfa0` `100792ec..f0`) but
only on **odd** ages and not for spaces (`10079314..10079328`), then ages every slot; a slot older than
9 is freed. A glyph is thus overdrawn at 36000, 28000, 20000, 12000, 4000 (of 65535) — it fades in
from light grey to near black. Per character `.CharByCharDelay(2, start)` waits **2 ticks**
(`addi r3,r24` = delay arg 2, `10079364..1007936c`; loop `100790d0..100790e8`; r24 = the caller's r6,
`10079228 addi r24,r6,0`, and both text callers pass `li r6,0x2` at `100795fc`/`100796f0`, the
10-space pass `li r6,0x0` at `10079784` — ⚑ corrected (review 2a, 2026-10-04) #6) ≈ 30 chars/s; while any
input key is held the delay ends at once (fast-forward). After the last chunk a 10-space pass with
delay 0 finishes the fade. A `DeadTime` follows each wrapped line. Escape aborts mid-text.

### 6.3 Keys and waits  [HIGH]
- After a spoken line: wait all-keys-up, then `.ConvPressAnyKeyDeadTime`: loop `DeadTime` until any
  input key (keyboard mode: **any key**, `.IsAnyInputKeyDown @ 1004a1d4` → `IsAnyKeyDown`; ISp mode:
  ISp elements 0..6) or the **mouse button**; Escape there sets the abort flag but the line's menu/
  actions still run before the loop exits [MED: depends on Escape not being held at the next test].
- Menu: up = input 2, down = input 3, confirm = input 5/6/7/8, Return, keypad Enter (§3.3).
- Escape (key code 0x35) at any test point ends the conversation; actions of the current line are
  skipped if it is seen before `.HandleLineActions`.
- No frame timer runs during a conversation (all loops are modal busy-waits with `DeadTime` =
  `Button(); CheckFlags(); MusicAIFFTickle()`, engine §4), so music keeps playing and the game is
  frozen; on exit the cooldown (§1.1) starts.

## NOT RESOLVED
1. Designer intent of condition/action type 3 in 200/202/204/207/211 (own-flag shape, but the code makes
   condition 3 always false and action 3 `RemoveItem`). Tried: jump table (`0x100a6cd0`), every branch
   of `1007a148..1007a258`; no other Mcnv reader exists. The code behaviour is certain; whether a prior
   build mapped 3 to the own-record flag cannot be settled from 1.0.3 → **CLOSED AS UNDETERMINABLE**
   (intent only).
2. Readers of `0x1024b4ca` / `0x1024b4cc` (written by action 2): none via any TOC slot; an offset
   access from another base is not excluded (§3.4). Tried: `tocrefs.py` over both slots and the
   writer at action 2 (§3.4). ⚑ corrected (review 2a, 2026-10-04) #9
3. Whether a talker that stays in contact really re-opens every 150 frames (contact/`+0xb0` handling
   of NPC sprites not traced here). Tried: the cooldown writer/decrement only (§1.1, `10056d44`,
   `1004e560..1004e578`). ⚑ corrected (review 2a, 2026-10-04) #9
4. The exact on-screen origin assumes a 640×480 screen port (`_MTSetPortScreen`); the redraw
   arguments of `_WrapCopyToScreen` on exit were not decoded. Tried: the geometry constants of §6.1
   only. ⚑ corrected (review 2a, 2026-10-04) #9

## Proposed additions to physics.md §0
None (sprite fields used here: `+0x48` record index, `+0xb0` talk gate, `+0xe9` kill request — all
already in the bank).

## Corrections to the existing bank
| # | file § | old | new | evidence |
|---|---|---|---|---|
| 1 | world-data-format.md §5 | "Response/action encoding: NOT RESOLVED"; record lists text/speaker/pic only | full line record (§2.2 here): responses `+0x200+0x100k` ×5, targets `+0x700+2k`, condition `+0x70c..+0x712`, actions `+0x71c`/`+0x722` (type, A, B), next `+0x728`, `+0x714..+0x71b` unread; header pstr unread; target encoding §2.3; entry node line #20 | raw `10079cf8`, `1007a148..1007a5e8`; decode of 29 resources |
| 2 | world-data-format.md §5 | "`.Conversation` starts at line index 0x13 and loops while the index is < 0x14" (unexplained) | index 19 = line #20 is the entry/logic node; empty #20 falls through to #1 (`i = 19 → 0`, `1007a5d0..e8`); the loop also stops on the abort flag `*0x100a0c14` | `1007a888..1007a8b4` |
| 3 | world-data-format.md §5 | `.HandleLineResponses` / `.HandleLineActions` "read `+0x81c..0x826` and the save-game block" | Responses read `+0x300..+0x80a` only; Actions read `+0x80c..+0x828`, `G` (coins, inventory, flags `+0xad8`), the live level header (`100a0058`) and the save block only for action 10 | §3.3–§3.4 |
| 4 | pickups-boxes.md NR 7, §1.7 last sentence, §1.8 last sentence | "Conversations (`Mcnv`) were not checked as a grant path"; "Items 7..13, 18, 20, 22 are not placed … (conversations not checked)" | Conversations grant items only, never spells; item **18 Ice Pick is sold by Elber (Mcnv 207, L30, 500 coins)**; items 7, 9–13, 20 and 22 are not granted by any conversation; NR 7 closed | §4.3 |
| 5 | pickups-boxes.md §1.8 | "Keys 3201..3203 are never placed loose: they come only from chests and crates" | the Platinum Key (item 3) is also given by Mcnv 205 (L3, Wounded Habnabit, for a Health Potion); conversations also **remove** Steel/Gold Keys (action 3, §5) | §4.2, `1007a364`/`1007a438` |
| 6 | held-item-melee.md §1.9 and NR 4 | Ice Pick/Vorpal Dirk "MED 'unobtainable': enemy drops and conversations not checked" | Ice Pick **obtainable** from Elber (Mcnv 207 #7, L30); no conversation grants the Vorpal Dirk (21) or the Hammer (8) — the conversation half of NR 4 is closed (drops remain) | §4.3 |
| 7 | spells-items.md §1 | slot `+8` "1 = spell slot" (writers listed: pickups) | add: conversation action 2 also fills item slots (flag 0, count cap 99) and `RemoveItem` is reachable from conversations | `1007a3e0..1007a408` |
| 8 | triggers-background.md §3 (l. 446; row cited l. 418 — ⚑ corrected (review 2a, 2026-10-04) #7) | "every talker/plaque p1 > 100 is an existing `Mcnv` id (… 2951..2965 ×20 …)" | 18 spawned NPC talkers + L11 rec 283 (flag 99, Mcnv 220) + L4 rec 88 (flag 0, p1 = 0 — would fail if spawned); Mcnv 204 is never placed | §1.2 census |
