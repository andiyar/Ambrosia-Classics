# Deimos Rising 1.0.6: in-game messages, notices and the console (cheats)

Scope: the 21 functions at `0x1002cef0–0x1002e300` (G_Console.cc + G_Message.cc; `FUN_1002e310` is
level selection and is OUT), the notice functions `FUN_10018070…FUN_100184b0` plus their raw-only
neighbours (`0x10018580` NOTICE handler, `FUN_10018670` static init), and the code range at
`0x10007d60–0x1000922c`. Ghidra made only `FUN_10007d60`, `FUN_10008820` and `FUN_10009230` there;
the rest is 18 console-command handlers that are reached only through transition vectors (TVs).
I disassembled that range raw with a range post-script (`RangeDisasm.java`, scratchpad copy of
`DisasmFuncs.java` that calls `disassemble()` on undefined bytes, run read-only against
`$W/work-w2s5`, output `$W/disasm-w2s5.txt`, `-b.txt`, `-c.txt`). OUT of scope: the text renderer
(`FUN_1000d380`/`FUN_1000e270`), the player/score effects the cheats call (owned by
scoring-bonuses.md and player-physics.md), entity "Notice" units (`noel`, `nole`, …), which are sprite
units handled by the entity engine, and registration (`M_Registration.cc`).
Conventions follow engine-loop.md: `PermFloat(n)` = flli n, `GameString(n)` = pgsl line n,
`gaso[n]` = PermSoundID n, `G` = game struct `*(r2−0x7360)` = `0x100fb198`, `fc` = frame controller.
In listings, r2 = `0x100e6330`, and `subi rX,r2,0x2634` = `0x100e3cfc`, the base of the G_Game string block.

## 1. Modules, lifecycle, timebases

| function | role | label / evidence |
|---|---|---|
| `FUN_1002cef0 @ 1002cef0` | Console module init: register module name "Console" (`FUN_1003a870`), flag `DAT_100e01f2=1`, reset (`FUN_1002d040(0)`), free and recreate the command list `_DAT_100e01ec`, register HELP/COMMANDS/? (debug-only, so not actually added, §5.2). Caller `FUN_100000e0` (app init) | HIGH: listing `1002cef0..1002cfec` |
| `FUN_1002cff0` / `FUN_1002d5d0` | Console teardown / free the command list (entries carry magic `0x499602D2`) | HIGH: listing |
| `FUN_1002d040(t)` | console reset: open=0, visible=0, fade=0, last-key time = t, clear the 32-byte line buffer. Callers: init, `FUN_10030210` (frame-controller init), `FUN_100302e0` (between levels), `FUN_10030870` (after pause) | HIGH: listing `1002d040..1002d07c` |
| `FUN_1002dac0` / `FUN_1002db00` | Message module init ("Message") / teardown | HIGH: listing |
| `FUN_1002db50` | message-queue reset: free list, new list `_DAT_100e01f8`, message clock `_DAT_100e01f4 = 0`. Callers: level start `FUN_100064d0` (`100067d0`), `FUN_10030210`, `FUN_100302e0`, `FUN_1002dac0` | HIGH: listing + call sites |
| `FUN_1002e190` | free the message list | HIGH: listing |
| `FUN_10018070` / `FUN_100180e0` | Notice module init ("Notice"; registers the debug-only NOTICE command, so it is not added) / teardown | HIGH: listing `10018070..` |
| `FUN_10018130` | notice reset (§4.1). Callers: init, level start `FUN_100064d0` (`1000681c`), level select | HIGH |
| `FUN_1002da40`, `FUN_1002e280`, `FUN_10018670` | static initialisers: copy constant records (`'none'` sound blocks etc.) into module statics | LOW: listing shape only |

Timebases [HIGH]:
- Messages and the console count **presented frames**. They use the frame-controller counter `fc+0x8`, which is
  incremented once per loop pass in end frame (engine-loop.md §4). Begin frame `FUN_10030360` passes
  `lwz r3,0x8(r28)` to `FUN_1002d230`/`FUN_1002d1a0` (`100303a0`, `100303c4`) and to the message ager
  (`100303d0 lwz r3,0x8(r28); bl 0x1002dd90`). The frame limiter is on by default, so that is 30 frames/s.
- Notices count **logic ticks**. `FUN_10006b50` passes game time `G+0x1c`
  (`10006bcc lwz r3,0x1c(r31); bl 0x10018320`).
- Draw order: world draw `FUN_10007070` draws the accuracy-tally text (`FUN_10007d60`) and then the
  notice (`FUN_100184b0`). End frame `FUN_10030bc0` then draws messages (`1002dea0`), the FPS counter
  (pref 9) and the console (`1002d410`) before the render layers and present (listing `10030bec`, `10030c98`).
  So messages and the console sit on top of everything.

## 2. The message queue (G_Message.cc)

### 2.1 Message record (0x58 bytes, `FUN_1004d320(0x58)`) [HIGH: listing `1002dcd0..1002dd70`]
| off | type | meaning | evidence |
|---|---|---|---|
| +0x00 | u32 | magic `0x499602D2` | `1002dcd0 lis r3,0x4996; addi r0,r3,0x2d2; stw r0,0(r25)` |
| +0x04 | u32 | post time = message clock `_DAT_100e01f4` (the frame count passed to the last aging call) | `1002dce4 lwz r6,-0x613c(r2); 1002dcf0 stw r6,4(r25)` |
| +0x08 | u32 | fade 0…32 (0 = opaque, 32 = gone) | `1002dcf4 stw r0,8(r25)` (0) |
| +0x0c | char[64] | text, copy ≤ 0x3f chars (`FUN_10046510`) | `1002dce8 addi r3,r25,0xc; li r5,0x3f` |
| +0x4c | u8 | uppercase flag (arg 3) → `FUN_100463b0` toupper | `1002dcfc stb r30,0x4c(r25)` |
| +0x4d | u8 | sticky readout = (arg 4 ≠ 0) | `1002dd10..1002dd2c` |
| +0x50 | ptr | readout TV (arg 4); the draw calls it and prints `"%s%i"` | `1002dd0c stw r31,0x50(r25)` |
| +0x54 | u8 | type (arg 2): 0 normal, 1 error, 2 status | `1002dd00 stb r29,0x54(r25)` |

### 2.2 Post `FUN_1002dbd0 @ 1002dbd0 (text, type, upper, readout)` [HIGH: listing]
1. Does nothing unless the module flag (`lbz -0x6134(r2)`) is set and the list exists.
2. If `readout ≠ 0`, search the list for an entry whose `+0x50 == readout`. If one is found, clear its sticky
   flag (`1002dc60 stb r0,0x4d(r3)`) and return. Posting the same readout again therefore turns it into a normal message that ages out.
3. Empty text is ignored (`1002dc7c lbz r0,0(r28); beq`).
4. **Max entries = Message_MaxNum (flli 24 = 20).** If `count ≥ 20` (`1002dca0 cmpw r27,r0; bge exit`), the
   **new message is dropped**. Nothing is evicted.
5. Sticky messages are inserted at the list head (`FUN_10000910`, U_LinkedList prepend). Normal messages are
   appended (`FUN_100009e0`).

### 2.3 Aging `FUN_1002dd90 @ 1002dd90 (frame)`, every begin frame [HIGH: listing `1002dd90..1002de9c`]
```
clock = frame
for each message m in list order, sticky ones skipped:
    if clock > m.post + Message_Duration (flli 25 = 60)        ; 1002de30 add; cmplw; ble skip (unsigned)
        m.fade += Message_FadeOutRate (flli 26 = 1)             ; 1002de40
        if m.fade >= 32: unlink + free m, RETURN                ; 1002de4c cmplwi 0x20; blt …; 1002de7c b exit
```
A message is therefore opaque for 60 frames, then fades by 1/32 per frame, and is deleted on the frame its fade
reaches 32. That is 92 frames in all, ≈ 3.07 s at the 30-fps limiter. Quirk: at most one message is
deleted per frame, and the walk stops there, so expired messages after the deleted one skip that frame's fade step.

### 2.4 Draw `FUN_1002dea0 @ 1002dea0`, every end frame [HIGH: listing `1002dea0..1002e18c`]
Format by type: 0 → format 35 `Message_Normal` (`meno`), 1 → 36 `Message_Error` (`meer`), 2 → 37
`Message_Status` (`mest`). Type ≥ 3 aborts the whole draw (`1002df90 cmpwi r0,3; bge exit`).
Gap = Message_VerticalGap (flli 27 = 20). `FUN_1000d130(i, buf)` copies text format i (0x148-byte
records at `_DAT_100df03c`) into a 256-byte text buffer followed by the format fields.
- Pass 1, sticky entries (list head): text = `"%s%i"` (label, readout()). Then `Loc_Y += k·20`, k = 0,1,…
  (`1002dff0 mullw r0,r27,r26; lwz r3,0x30c(r1); add`).
- Pass 2, normal entries in list (post) order, j = 0,1,…: `Loc_Y += 20·(count − j − 1)`. Here count is
  all entries, sticky ones included (`1002e110 subf r3,r27,r31; subi r0,r3,1; mullw r0,r26,r0`).
  ⇒ **the newest message sits at the top, directly below any sticky lines, and older ones are pushed down
  20 px per newer message.** The oldest of n normal messages (no sticky) is at Loc_Y + 20·(n−1).
- Per entry: field +0x114 (BlendAmount) = m.fade (`1002e138 lwz r4,8(r28); stw r4,0x1d4(r1)`, buffer at
  r1+0xc0). This replaces the tefo value. The colour-strip blend (+0x138) is set to fade + 16, and the strip is switched off
  (+0x12c = 0) once that exceeds 32. +0x10d = 1, +0x110 = 0, +0x10c = 0x0f (meaning NOT RESOLVED, §NR 3).
Field names come from the `tefo` parser `FUN_1000ef90`: sscanf targets in the decompile, plus stores
`1000f650 stw 0x100`, `f658 0x104`, `f690 0x114`, `f6f0 0x138` in its listing [MED for names].

Formats (`Game/tefo/*.tefo`, decoded; index = line in `idli/Formats[gate]`) [HIGH: file bytes]:
| idx | ID | Loc X,Y | align | colourise | strip (do, offs, blend, min W) | BlendAmount |
|---|---|---|---|---|---|---|
| 33 | `copr` Console_Prompt | 30, 448 | LEFT | 00ff00 | yes, 3/3, 16, 336 | 0 |
| 34 | `cote` Console_Text | 42, 448 | LEFT | 00ff00 | no | 0 |
| 35 | `meno` Message_Normal | 30, 10 | LEFT | none (glyph colour) | yes, 3/3, 16, 126 | 4 (overridden → 0) |
| 36 | `meer` Message_Error | 30, 10 | LEFT | ff0000 | yes, 3/3, 16, 126 | 4 (overridden) |
| 37 | `mest` Message_Status | 30, 10 | LEFT | 31ff63 | yes, 3/3, 16, 126 | 4 (overridden) |
| 49 | `gano` Game_Notice | 0, 220 | `4` (CEGA; overridden per notice) | ffffff, char gap 1 | yes, 6/3, 16, 0 | 0 (overridden) |
| 53 | `gaco` GroundAccuracyCount | 100, 240 | LEFT | ffffff | no | 0 (overridden by tally alpha) |
Font: all draws go through `FUN_1000d380`, which uses the single sprite font `_DAT_100e0120` (the
`tesm` "Text – Small" glyph order, data-tags.md §5) [MED: renderer not read]. Whether Loc is
screen-absolute (640-wide) or game-area-relative is NOT RESOLVED (§NR 2). Screen-absolute is likely,
because one format option is "centre in game area".

### 2.5 Every poster of `FUN_1002dbd0` (decompile census + raw call scan) [HIGH]
| poster | text | type | reachable in 1.0.6? |
|---|---|---|---|
| `FUN_10030910` F6 key (0x61) | GameString 17 `Interlacing      ON` if pref 5 was 0, else 18 `…OFF`; then toggles pref 5; sound `gaso[7]` | 0 | yes |
| `FUN_10030910` `-` (0x1B) / `=` (0x18) | volume −10/+10 in int pref 0, clamped 0–100 (`FUN_10047990`/`FUN_10047a30`). Text: `vol < 1` → GameString 21 `Sound Volume     OFF`, else `"%s%i%s"` (22 `Sound Volume     `, vol, 23 `%`), e.g. `Sound Volume     60%`; sound `gaso[7]`. **Skipped entirely on Mac OS X** (`FUN_100461b0` = Gestalt 'sysv' ≥ 0x0A00), though the pref still changes | 0 | yes (OS 9 only) |
| `FUN_10030640` auto-interlace (FPS monitor, engine-loop.md §4) | GameString 17 `Interlacing      ON` | 0 | yes |
| `FUN_1002d770` console | `Unknown Command` | 1 | yes |
| console handlers (§5) | cheat / FPS / VERSION texts | 0/1 | the registered ones |
| `FUN_10009230` | de-obfuscated `Please Register Deimos Rising!` (`0x100e447c`, `~rotl4` via `FUN_10046470`) | 1 | unregistered copies only |
| `FUN_10033220` | `Reached Entity Limit` (uppercased) | 1 | yes, on overflow |
| `FUN_10046eb0`, `FUN_100477d0`, `FUN_10047bf0` | audio-channel and sound error texts (from data blocks) | 1 | errors only |
| `FUN_100044b0`, `FUN_10010570`, `FUN_10010860`, `FUN_10019ca0`, `FUN_10019fc0`, `FUN_1001a2a0`, `FUN_100355b0`, `FUN_100377f0`, `FUN_1003f280`, `FUN_10008820` | debug-command and integrity texts (LOGTAGS, REVERSE/SCROLL, LEVELSPAWNS, sprite log, "… Integrity FAILURE", "Tracked Entity Spawned", GAMETIME) | 0/1/2 | no (debug-only commands, §5.2) |
**No gameplay event posts a message**: extra life, level start/end, bonuses, multipliers and
weapon pickups produce none. A raw bl-scan of the code image finds 113 `bl 0x1002dbd0` sites. Every site outside
the rows above lies in a debug handler (LOGSPRITE `1001af10`, sprite FX `1001afc0`, ALPHA `1001f040`,
LOGUNUSEDSPRITES/SOUNDS `100206a0…`, NUMDEBRIS `1002aa30`, unit-manager logs `10041a40…`, `10044870`,
`10047120`: all TVs of r7 = 1 registrations), and none is in the player, weapon, score or level code. Those
events show **sprite "Notice" units** (§4.4).

## 3. GameString call sites (all of them) [HIGH]
Raw scan for every `bl 0x10020260` in the code image with the preceding `li r3,N` (37 sites,
identical to the decompile census). A scan for any other load of the table slot `r2−0x712c` finds only the
loader `1001fe6c` and the accessor `10020260`.
| line | text | site(s) | event / surface |
|---|---|---|---|
| 0 | `Press Caps Lock` | `10030480` (`FUN_10030360`) | pause **notice** (§4.3) |
| 4 / 5 | `Sector Not Reached` / `Registration Required` | `1002ecc4` / `1002eca4` (`FUN_1002e310`) | level-select info line (own format 26) |
| 7 | `_` | `100221f4` (`FUN_10021bd0`, G_Scores) | name-entry cursor (LOW: caller context) |
| 9 | `REPLAY` | `10005a64` (`FUN_100051a0`) | film-playback banner |
| 10 | `    All Mission Targets Destroyed!!!` | `10007ba0`, `10007d1c` (`FUN_100075e0`) | accuracy tally (scoring-bonuses.md §6.4) |
| 11 / 12 / 13 | `Ground Accuracy:   ` / `   Bonus:  ` / `None!` | `100075a0` … `10007a7c` | accuracy tally text `G+0x60`, drawn by `FUN_10007d60` (format 53) |
| 14 / 15 / 16 | `Coin Bonus:   ` / `  x  ` / `  =  ` | `100276b0` … `10027cec` | coin tally text (player +0xec) |
| 17 / 18 | `Interlacing      ON` / `OFF` | `10030740`, `10030b08` / `10030ae4` | message (§2.5) |
| 21 / 22 / 23 | `Sound Volume     OFF` / `Sound Volume     ` / `%` | `10030a30` / `10030a64` / `10030a54` | message (§2.5) |
| 33 / 34 / 35 | registration banners | `10010ecc`, `10010f34`, `10010f5c` | out of scope |
**Never referenced:** lines 1–3, 6, 8 (`PLAYING FILM:`), 19/20 (`Auto Interlacing ON/OFF`),
24–30 (`Game Speed …`), 31/32 (key-assignment alert, presumably used by the OS X controls UI), 36.

## 4. Notices (the single centred text slot)

### 4.1 Notice state `N` = `*(r2−0x71d0)` = `0x100ffc78` [HIGH: listing `10018130..100181dc`, `100181e0..`]
| off | meaning | reset value (`FUN_10018130`) |
|---|---|---|
| +0 | active | 0 |
| +1 | hold (never auto-clears; also blocks new posts and clears) | 0 |
| +2 | fading in | 0 |
| +3 | fading out | 0 |
| +4 | alpha 0…32 (32 = invisible) | 32 |
| +8 | start time (game time) | 0 |
| +0xc | text[64] | "" |
| +0x4c | delay ticks before showing | 0 |
| +0x50…+0x64 | sound block (ID, MinVol, MaxVol, Priority, MinPitch, MaxPitch) | `'none'`,100,100,100,1.0,1.0 (`0x100d6cc4`, code image) |
| +0x68 | alignment 4CC passed to the draw | `'CEGA'` |
| `_DAT_100e015c` | last tick time (once-per-tick guard) | 0 |
Post record (0x28 bytes, argument of `FUN_100181e0`): +0 text ptr, +4 hold, +5 fade-in, +8 delay,
+0xc…+0x20 sound block, +0x24 alignment.

### 4.2 Post / clear `FUN_100181e0 @ 100181e0 (rec, now)` [HIGH: listing]
- **Clear** (`rec == NULL` or `rec->text == NULL`). Applies only if active and not hold. If it is still fading in, it switches off
  at once (`10018230 stb r0,0(r31)`). Otherwise it starts a fade-out (`+3 = 1`).
- **Post.** Ignored while `hold` is set (`1001825c lbz r0,1(r31); bne exit`). Otherwise: active = 1, hold = rec+4,
  start = now, copy text (≤ 63), delay, sound and alignment. If rec+5 (fade-in) is set: alpha = 32,
  fading-in = 1. If not: alpha = 0 (instantly opaque). Fading-out = 0. A post **replaces** the current
  notice; there is no queue.

### 4.3 Tick `FUN_10018320 @ 10018320 (gameTime)` [HIGH: listing `10018320..100184ac`]
Runs once per new game-time value (`10018344 cmpw r29,r0; ble exit`), and only while active:
```
if delay == 0: start = now; play sound block unless ID == 'none' (FUN_100475e0(&N+0x50,1))
delay -= 1
if delay <= 0:
    if !hold and now > start + Notice_AppearanceGameTime (flli 71 = 60): Clear   ; 100183d4 cmpw; ble
    if fadingIn:  if alpha < FadeIn (flli 72 = 2): alpha = 0, fadingIn = fadingOut = 0
                  else alpha -= 2                                                ; 10018420 cmplw; blt
    if fadingOut: alpha += FadeOut (flli 73 = 4); if alpha >= 32: alpha = 32, active = 0
```
So a fade-in takes 16 ticks (32 → 0 in steps of 2, plus one tick to clear the flag). The notice is then held
until 60 ticks after its start, and fades out over 8 ticks (0 → 32 in steps of 4).
Notice_StandardYLoc (flli 70 = 220) has **no code consumer**: a raw scan for `li r3,0x46; bl 0x10020250` finds
none. The 220 that is used comes from the `gano` tefo Loc_Y.

Draw `FUN_100184b0` (world draw): if active, text non-empty and `delay < 1`, load format 49, then BlendAmount =
alpha, strip blend += alpha (strip off above 32), alignment = `N+0x68` (`10018540 lwz r0,0x68(r31);
10018554 stw r0,0x140(r1)`, buffer r1+0x38 so field +0x108). [HIGH]

### 4.4 Who posts notices, and what a player can actually see [HIGH]
All seven `bl 0x100181e0` sites (raw bl-scan) were read (`100164d0`, `100183ec`, `100304dc`, `100308d0`,
`10038200`, `10018630`, `1002e908`):
| poster | record | shipped-data effect |
|---|---|---|
| `FUN_10030360` begin frame, **Caps Lock (0x39) held** and not already paused: sets `fc+0` (paused), posts GameString 0 `Press Caps Lock` from template `0x100eb1cc` with fade-in forced off (`10030490 stb r0,0x45(r1)`), hold 0, delay 0, sound `'none'` (static init from `0x100d70f4`). Alignment `'CEBU'` if `fc+4 == 0`, `'CEGA'` if `fc+4 == 1` | **the only text notice in normal play** |
| `FUN_10030870` (end frame, via `FUN_10030570`) while paused: console reset, modal pause screen `FUN_10022ef0(fc+4)` (plays `gaso[8]` Paused, pauses music, loops until Caps Lock is released; returns 1 on quit, which then sets `fc+2`). Then **Clear** and `fc+0 = 0` | the pause notice fades out over 8 ticks after resume |
| `FUN_1002e310` level select: Clear whenever not paused | same pause notice on the level-select screen |
| `FUN_100380e0` entry notice (caller `FUN_10033220` only when `entryNotice_STR` is non-empty) from unit+0x18: text, hold 0, fade-in 1, delay = `entryNoticeDelay_INT`, sound = `entryNoticeSound_*` | never: all 386 `unde` files have `entryNotice_STR <>` (census below) |
| `FUN_10016300` destruct notice (`destructNotice_STR` non-empty and ≠ "none"), hold 0, fade-in 0, other record fields are uninitialised stack | never: all 386 files empty |
| `FUN_10018320` itself: the 60-tick auto-clear | n/a |
| `0x10018580` NOTICE debug command | unreachable (§5.2) |
No caller sets hold = 1, so the hold path is dead in 1.0.6. Census: `python3` regex over
`$W/data/**/*.txt` → `destructNotice_STR ''` ×386, `entryNotice_STR ''` ×386 (also unit-def-struct.md §10).
`fc+4` is the third argument of `FUN_10030210`: 1 for the game loop (`FUN_100051a0`: `(fc,bVar2,1,1)`),
0 for level select (`(fc,0,0,0)`). ⚑ conflict with engine-loop.md §4, which calls `+4` "interlaced".
The pause notice is therefore centred in the game area during play and centred in the screen buffer on level select. [MED for the alignment semantics]

The perm objects `Notice_Level_01…12`, `Notice_LevelEnd`, `Notice_AllLevelsCompleted`,
`Notice_GameOver` (gaob 10–24) and the plde `life_Spawn_ID 'noel'` are **units** (`unde` "Notice – …"
files, family/drawLayer data), spawned by level-scroll-objects.md §8 / engine-loop.md §3 /
scoring-bonuses.md §3.3. They never touch `N`. [HIGH: they are `FUN_100201f0` object IDs passed to the
spawn request, not `FUN_100181e0`]

## 5. The console (G_Console.cc) and the cheat commands

### 5.1 Open, type, execute, fade [HIGH: listings `10030390..100303c8`, `1002d1a0..1002d5c8`, `1002d770..1002d940`]
- **Open.** In begin frame, if the console is closed and key 0x32 (`` ` ``/`~`, GetKeys) is down:
  `FUN_1002d1a0(frame)` runs FlushEvents (so the tilde keystroke is discarded) and plays `gaso[1]` ConsoleActivate
  (`clic`) via `FUN_10047670(id,0x32,100,1)`. It sets open = visible = 1, fade = 0, last-key = frame,
  clears the buffer, saves an InputSprocket state (`FUN_1004a9f0` → `DAT_100e01e2`) and calls `FUN_1004a9c0`.
- **The game does not pause.** Logic ticks continue, but the player-input read `FUN_1004aa90` is skipped while
  the console is open (`10030534 bl 0x1002d190; bne skip`, the same in `FUN_10006b50`), and inputs were cleared
  by `FUN_1004aa20`. The ships get no control input while the enemies keep acting.
- **Typing** `FUN_1002d230(frame)`, once per frame while open. It reads one event with `FUN_10048d70`
  (GetOSEvent: returns 2 + char for keyDown only, so auto-repeat is ignored [MED: Mac event codes]).
  - expired := `frame > lastKey + Console_ExpireTime` (flli 22 = **120 frames**, unsigned).
    `1002d280 cmplw r31,r0; ble`.
  - With no key and not expired, return. Otherwise lastKey = frame. len = strlen(buffer).
  - `len ≥ 30` or expired → the key is replaced by Return (`1002d2bc cmplwi r31,0x1e; blt`).
    ⇒ **at most 30 characters**, and after 4 s (120 frames at 30 fps) without a key the console closes and executes
    the line as typed.
  - 0x1E (up arrow) → copy the last executed line into the buffer.
  - 0x0A/0x0D → execute. 0x08 → delete the last char. `` ` `` / `~` → not appended; it sets the console draw flag
    `DAT_100e01f0` (`1002d354 li r0,0x1; 1002d358 stb r0,-0x6140(r2)`), which reset (`1002d060`)
    and open (`1002d1f4`) also set and the draw `FUN_1002d410` reads/clears: `1002d434 lbz
    r0,-0x6140(r2); 1002d43c beq 0x1002d5b0` (nothing drawn when 0), `1002d4d4 stb r3,-0x6140(r2)`
    (r3 = 0, once the closing slide offset `-0x6148(r2)` reaches 32), `1002d4dc lbz` (re-test) —
    confirmed from `$W/disasm-review2.txt`, so it is the console's visible/redraw flag. ~ does
    **not** close the console. ⚑ corrected (review wave 2, 2026-10-03) #M4: was "ignored".
    Anything else is appended (`1002d3e0 stbx r3,r30,r31`).
  - Execute: open = 0 (visible stays 1, so it fades), `FUN_1002d770(buffer)`, then restore InputSprocket:
    `FUN_1004a990(0)` if `FUN_1002e300()` (level-select flag `DAT_100e01fd`, written only in
    `FUN_1002e310`) else `FUN_1004a990(1)`.
- **Execute** `FUN_1002d770(line)`. Command name = the leading characters up to the first whitespace
  (`ctype & 6`, MSL motion|space [MED]), at most 31, uppercased. Exact strcmp against the command list.
  Not found → message `Unknown Command` (type 1, red), no sound. Found → call the handler TV with the **whole
  line** (`1002d8b4 lwz r12,4(r27); bl 0x100d6040`). Save the line as the "last command". If the command's
  `+0x128` flag is set: sound `gaso[4]` CommandConfirmation (`incl`) when the handler returns ≠ 0, else
  `gaso[5]` CommandFailure (`lsna`). Commands are case-insensitive, and text after the name is ignored by every
  player-reachable handler.
- **Draw** `FUN_1002d410`, every end frame while visible. Prompt = `Interface[inte]` line 16 `>` (loaded once,
  8 bytes). When closed: if fade < 32 − (4 − 1) then fade += Console_FadeOutRate (flli 23 = 4), and at ≥ 32
  visible = 0. So the fade-out lasts **8 frames**. Draw format 33 (`>` at 30,448, green, black strip min
  width 336), and format 34 (typed text at 42,448) if the buffer is non-empty. Both use BlendAmount = fade.

### 5.2 Command record and the registration gate [HIGH: listing `1002d080..1002d184`, all call sites]
`FUN_1002d080(name, help, handlerTV, resultSound, debugOnly, hidden)` builds a 300-byte record:
+0 magic `0x499602D2`, +4 TV, +8 name (≤31, uppercased; logs "ERROR: command was already in the
list!" on a duplicate), +0x28 help (≤255), +0x128 resultSound, +0x129 hidden-from-HELP.
**If `debugOnly ≠ 0` the function returns without creating anything**:
`1002d0a4 rlwinm. r0,r7,0,0x18,0x1f; 1002d0ac bne 0x1002d174`.
A raw bl-scan finds 64 registration call sites, and the `li r7,N` before each one was read back. All pass r7 = 1
**except the 10 in `FUN_100051a0` below** (`1000527c`, `100052dc`, `100052fc`, `10005434…100054f4`). So the shipped 1.0.6
console knows exactly these commands:
| typed | handler | r6 sound | r8 hidden | effect |
|---|---|---|---|---|
| `FPS` | `0x10007eb0` | 1 | 0 | toggle byte pref 9 (FPS counter); `Frame Rate Monitor Enabled` / `…Disabled` (type 0) |
| `VERSION`, `VERS` | `0x10008660` | 1 | 0 | `Version: 1.0.6, Jan  2 2004, 11:55:08` (type 0) |
| `SUPERMUNKI` | `0x10008990` | 1 | 1 | enable cheats (below) |
| `LIFE` `ACCURACY` `FUNDS` `SCORE` `SHIELDS` `MULT` | `0x100089f0` `…8b80` `…8c90` `…8df0` `…8f60` `…90d0` | 0 | 1 | cheats (§5.4) |
Everything else (HELP/COMMANDS/?, SHADOWS/SHADOW, LIMITFPS, PLAYER, INTEGRITY, MEMORY/MEM, LOGMEM, GAMETIME,
DISPLAYACCURACY, ALLLEVELS, NOTICE, NUMDEBRIS, LOGTAGS, ALPHA, LOGUNUSEDSPRITES/SOUNDS, LOGSPRITE and sprite FX (`FUN_10018740`), the 12 G_Background,
12 G_EntityGroup and 5 unit-manager commands, and those registered by `FUN_100431f0`, `FUN_100466e0`) is compiled
in but **unreachable**. Typing it gives `Unknown Command`.

### 5.3 The cheat word [HIGH]
`FUN_100051a0` copies 10 bytes from `0x100e3f98` (`c8 a8 f8 a9 d8 29 a8 19 49 69`), runs
`FUN_10046470` = per byte `((b>>4)|(b<<4)) ^ 0xFF` (rotate the nibbles, then invert; decompile quoted in
pak-format.md §3) and registers the result as the command name:
`python3 -c "print(bytes((~((x<<4|x>>4)&255))&255 for x in bytes.fromhex('c8a8f8a9d829a8194969')))"` →
**`supermunki`** (stored uppercased `SUPERMUNKI`). This matches the Player Guide "Cheats" page ("type
supermunki, and press Return … the game will remember that cheating has been enabled").
Handler `0x10008990`: if registered (`DAT_100e00fc`, set in `FUN_100051a0` at `100051f8` from the
registration check), set **byte pref 11 = 1** (`100089a8 li r3,0xb; li r4,1; bl 0x10004ab0`) and post
`Cheat Codes Allowed` (type 0). Otherwise `FUN_10009230` → `Please Register Deimos Rising!` (type 1). Returns 1
in both cases, so `gaso[4]` plays. Pref 11 lives in the saved prefs block (0 in fresh prefs:
engine-loop.md §10 `iVar1+0xf = 0`), so enabling persists.

### 5.4 Cheat handlers [HIGH: listings `100089f0..10009228`]
Common gate, in order: not registered → `Please Register Deimos Rising!`; film playing (`G+0x20 == 1`)
→ `Not During a Film, Buddy!` (type 1); byte pref 11 == 0 → **silently nothing**. FUNDS tests the film flag
before registration. Then: if the per-game use counter is below the limit, counter += 1, post the success text
(type 0) and play `gaso[22]` (`acbo`), and for each player whose life state `+0xc6 == 4` (`FUN_10026c60(p,4)`)
apply the effect and set cheated `FUN_10029bf0(p,1)` (+0xbd: no high score, scoring-bonuses.md §9).
Otherwise post the refusal (type 1) and play `gaso[5]`.
| code | counter | limit | effect per active player | success | refusal |
|---|---|---|---|---|---|
| `life` | `G+0x16c` | 1 | `FUN_10026d70(p, 0)`: +1 life (cap life_MaxNum), **no `noel` unit** (fx 0) | `Extra Life Awarded!` (posted only if ≥ 1 player was active; the counter is spent anyway) | `Tut tut!  What a greedy piggy!` |
| `accuracy` | none | ∞ | once: `G+0x3c = G+0x40 = 100` (units created = destroyed = 100) | `Ground Accuracy 100%` | n/a |
| `funds` | `G+0x170` | 3 | money += 20 (`10008d6c li r4,0x14; bl 0x100275b0`) | `Money Money Money!` | `Money Can't Buy You Love (Just a Porsche!)` |
| `score` | `G+0x174` | 2 | `FUN_10029a10(p, 10000, 0)`: not raw, so **× multiplier**, and it can award an extra life (scoring-bonuses.md §3.1) | `Points Points Points!` | `I Think Not, Young Kitty!` |
| `shields` | `G+0x178` | 1 | `FUN_10027490(p, 100.0)` (float `0x100d6360` = `42c80000`) | `Maximum Shields!` | `Use The Force, Luke!` |
| `mult` | `G+0x17c` | 1 | `FUN_10029b20(p)` next multiplier step | `Bonus Multiplier!` | `Play Bubble Trouble!` |
Counters are zeroed at every game start by `FUN_10007130`, the only writer (raw scan for `stw …,0x16c…0x17c`:
`10007138..48`), called from `FUN_100051a0`'s new-game branch. The very first game uses the 0x180-byte memset.
The guide's "all codes have usage limits" is true except for `accuracy`.

### 5.5 The raw range `0x10007d60–0x1000922c`, function by function (unreachable rows are debug only)
| addr | what | reachable | label |
|---|---|---|---|
| `FUN_10007d60` | draw the accuracy-tally text `G+0x60` with format 53 while tally state `G+0x48 ≠ 0` and alpha `G+0x50 < 32` (BlendAmount = alpha) | yes | HIGH (listing `10007d60..10007df8`) |
| `0x10007e00` | SHADOWS/SHADOW: toggle `G+0x28` (draw shadows), `Shadows Enabled/Disabled` | no | HIGH |
| `0x10007eb0` | FPS (registered) | yes | HIGH |
| `0x10007f50` | LIMITFPS: toggle byte pref 10, `Frame Rate Limited/Unlimited` | no | HIGH |
| `0x10007ff0` | PLAYER `<kw>` (strtok " "): LOGWEPS (`FUN_1003bd40(p+0x240)`); EXTRA/LIFE (+1 life, fx 0); EXTRAS/LIVES (10× add life); FUNDS (+10 money); SCORE (`FUN_10029a10(p,9000,0)` at `1000827c`); SHIELDS (100.0); DESTROY/DESTRUCT (`FUN_10027e50(p, G+0x1c)`, ship destroyed, at `10008380`); AIRWEP/AIR (`FUN_10029c00(p,'PEAA')`, `10008408`); GROUNDWEP/GROUND (`'PEAG'`, `10008490`); GOD (`FUN_10027de0(p, !inv, 1)`, `Player Invulnerability ON/OFF`); BONUS/MULT/MULTIPLIER (`FUN_10029b20`); else `Syntax Error - PLAYER keyword` (returns 0). No film, registration or pref-11 checks | no | HIGH |
| `0x10008660` | VERSION/VERS (registered) | yes | HIGH |
| `0x100086c0` | INTEGRITY: `FUN_1001a2a0`, `FUN_100477d0`, `FUN_1003f280`, `FUN_100355b0(0)` → `Data Integrity OK` / `…FAILURE` (type 1) | no | HIGH |
| `0x10008790` | MEMORY/MEM: sticky status readout `Free Mem:  ` + `FUN_1000cdf0()` (TV `0x100e0880`) | no | HIGH |
| `0x100087d0` | LOGMEM: `FUN_1000ce20("Console Command")`, `Memory Logged To File` | no | HIGH |
| `FUN_10008820` | GAMETIME: sticky status readout `Game Time:  ` + `FUN_10005ce0()` = `G+0x1c` (TV `0x100e07d8`) | no | HIGH |
| `0x10008860` | DISPLAYACCURACY: `"%i / %i  -  %i%%"` (destroyed G+0x40, created G+0x3c, trunc(destroyed/created·100.0)) or `No Targets Yet` | no | HIGH |
| `0x10008930` | ALLLEVELS: int pref 3 = `FUN_10011de0()` (level count), `Access All Areas ON`. No cheat checks, no +0xbd | no | HIGH |
| `0x10008990`…`0x100090d0` | cheat word + 6 cheats (§5.3–5.4) | yes | HIGH |
| `FUN_10009230` | post `Please Register Deimos Rising!` (type 1) | yes (unregistered) | HIGH |
Handler addresses come from the TVs: TOC slot → TV → code (e.g. `0x100def84 → 0x100e07e0 → 0x100090d0`),
using the Python data-image read shown in §NR 5. `0x1002d950` (HELP: posts `Consult Log File For Commands`,
logs `    Command:  "%s" - %s` for non-hidden commands) and `0x10018580` (NOTICE `"text"`: posts a notice
with hold 0, fade-in 1, `'CEGA'`, or `Syntax Error - NOTICE "Some Text"`) are likewise raw-only and
unreachable. [HIGH]

## 6. What a 100 % replica must carry
- **Carry:** the message queue (§2: 20 max, drop when full, 60 frames opaque + 32-frame fade, newest on top at
  (30,10) with a 20-px gap, three type colours, frame-counted). The interlace messages, and the volume messages on the
  classic-OS path (⚑ the original posts none on OS X; replicating the OS 9 behaviour is a ruling for Ben, §NR 6).
  The Caps Lock pause notice (§4.4: instantly opaque, centred at y 220, fades out over 8 ticks after resume). The
  console (§5.1: ~ opens while the game keeps running without player input, 30 chars, Return/Backspace/up-arrow
  recall, 120-frame auto-execute, 8-frame fade, sounds). `FPS`, `VERSION`/`VERS`, `supermunki` and the six cheats
  with their exact texts, limits, sounds and side effects (§5.3–5.4), plus the persisted pref 11.
- **Note only, do not carry:** the debug commands that are never registered (§5.2, §5.5), the NOTICE/HELP handlers,
  the sticky readouts, and `Please Register …` (the replica is the registered game).
- **Not text:** extra-life / level / game-over / bonus "notices" are units (carry them through the entity engine).

## Worked example: the player earns an extra life
**(a) By score** (the usual way; scoring-bonuses.md worked example: score 5300 → 10 060 on coin-tally tick
14). `FUN_10029a10` crosses the threshold and calls `FUN_10026d70(p, fx=1)`, which spawns plde
`life_Spawn_ID` **`noel`** at the ship. **No text is posted, to either the message queue or the notice
slot** (§2.5, §4.4: `noel` is a unit). From `Notice - Extra Life[noel].unde` (decoded): sprite face
`noti` frame 3, `drawLayer plui`, `yOffsetMin/Max −40` (40 px above the ship), `stateLockToOwnerLoc TRUE`,
`deleteExistingEntitiesOfThisTypeOwnedByPlayer TRUE` (a second life restarts the effect).
State "Flash On": 6 ticks, visibility 100 %, entry sound `exli`, `stateSoundRepeatOnStateChange TRUE`, then
"Flash Off". "Flash Off": 8 ticks, visibility delta 15 %, scale 90 %, then "Flash On". "Flash On" has
`stateOnCounter 5 → Delete`. Under the OnCounter rule (bosses.md §3.2: delete on the 5th entry) that gives
On 6 / Off 8 ×4 = **56 ticks ≈ 1.9 s**, with `exli` on each Flash On entry. [data HIGH; the timing semantics are
MED, taken from bosses.md; whether the 5th entry plays `exli` before deleting is §NR 4]
**(b) By the `life` cheat** (cheats enabled, first use this game, player 1 alive). The console line `life` ⏎ →
`0x100089f0` → `G+0x16c` 0→1, lives +1 with **no** `noel`, cheated flag set, message
**`Extra Life Awarded!`** type 0 → format `meno`. Its glyphs are white per the font (no colourise), with a black strip at blend 16
(min width 126, offset 3,3), drawn at **(30, 10)** if no other message is up. The newest message is always at y 10,
and older ones move to 30, 50, …. Sound `gaso[22]` `acbo` plays, and there is no console result sound (r6 = 0). Timeline in frames from the posting frame F (the
message clock is the frame value given to the aging call that frame): opaque while frame ≤ F + 60; fade 1…31 over
frames F+61…F+91 (strip off once fade > 16); deleted at F+92 (fade 32). At the default 30-fps limiter that is 2.0 s
solid + ~1.0 s fade. A second `life` this game → `Tut tut!  What a greedy piggy!` in red (`meer`) + `gaso[5]`.

## NOT RESOLVED (this file)
1. Text-buffer fields +0x10c (set to 0x0f by every overlay draw), +0x10d (= 1) and +0x110 (= 0): meaning is in
   the renderer `FUN_1000d380`/`FUN_1000e270` (out of scope). Settle by reading those listings.
2. Whether tefo `Loc_X/Y` are screen-absolute or game-area-relative (message x 30 vs the 32-px left border).
   Settle with `FUN_1000e270` (where Loc is consumed) or one screenshot of the original.
3. ~~`FUN_10047670(id, 0x32, 100, 1)` argument meanings (volume 50?) for the console and cheat sounds:
   INDEX #11.~~ → ⚑ corrected (review wave 2, 2026-10-03) #S: sound-music.md §2.3 — `(id, priority 0x32 = 50, volume 100,
   allowMultiple 1)`.
4. Whether `noel` plays `exli` on its 5th Flash On entry before the OnCounter delete, and what its 5 rules do
   ("Fade Out, Delete" state reachable?): `FUN_100146f0` order plus the rule rows of the `noel` file.
5. TV resolution command used for every handler: `python3` over `$W/mem/100de330.bin`, word at the TOC slot →
   TV → first word (output in §5.5). Not an open question; recorded so it can be reproduced.
6. Mac OS X volume path: `FUN_10047990/a30` skip the hardware call and the message under OS X
   (`FUN_100461b0`). The replica runs on macOS, so whether to reproduce the OS 9 messages is a ruling for Ben.
7. ~~`FUN_10022ef0` pause-screen loop internals (`FUN_10023030`, quit flag `DAT_100e01b8`) were read from the decompile only.~~
   → ⚑ corrected (review wave 2, 2026-10-03) #S: front-end.md §8 (pause screen).
8. `FUN_1004a9f0`/`FUN_1004a9c0`/`FUN_1004a990` (InputSprocket suspend/resume around the console): roles LOW.

## Role-table rows (for merge)
| `FUN_1002cef0` | G_Console.cc | console module init: name, reset, command list, HELP/COMMANDS/? (debug-only, not added) | HIGH | listing `1002cef0..1002cfec` |
| `FUN_1002cff0` | G_Console.cc | console teardown | HIGH | listing |
| `FUN_1002d040` | G_Console.cc | console reset (closed, invisible, fade 0, buffer cleared, last-key = arg) | HIGH | listing |
| ⚑ corrected `FUN_1002d080` | G_Console.cc | register command (name ≤31 upper, help, TV, +0x128 result sound, +0x129 hidden); **skipped entirely when debugOnly (r7) ≠ 0**, so only 10 commands exist in 1.0.6 | HIGH | listing `1002d0a4 rlwinm. r0,r7…; bne 0x1002d174`; was MED "register console command" |
| `FUN_1002d190` | G_Console.cc | console input-open flag getter | HIGH | listing `1002d190 lbz r3,-0x613f(r2)` |
| ⚑ corrected `FUN_1002d1a0` | G_Console.cc | open console: FlushEvents, gaso[1], open/visible, save + suspend ISp | HIGH | listing; was MED |
| `FUN_1002d230` | G_Console.cc | console typing: keyDown via GetOSEvent, 120-frame expiry (flli 22), 30-char cap, ⏎/⌫/↑ recall, execute + restore ISp | HIGH | listing `1002d230..1002d400` |
| `FUN_1002d410` | G_Console.cc | console draw + 8-frame fade (flli 23), formats 33/34, prompt = inte line 16 | HIGH | listing |
| `FUN_1002d5d0` | G_Console.cc | free command list | HIGH | listing |
| `FUN_1002d6c0` | G_Console.cc | find command by name | HIGH | listing |
| ⚑ corrected `FUN_1002d770` | G_Console.cc | execute console line: first token upper, lookup, "Unknown Command", call handler TV, save last line, gaso[4]/[5] by result if +0x128 | HIGH | listing `1002d770..1002d940`; was MED "console command result sound" |
| `FUN_1002da40` / `FUN_1002e280` | G_Console.cc / G_Message.cc | static initialisers | LOW | listing shape |
| `FUN_1002dac0` / `FUN_1002db00` | G_Message.cc | message module init / teardown | HIGH | listing |
| `FUN_1002db50` | G_Message.cc | message-queue reset (level start, frame-controller init/reset) | HIGH | listing + callers |
| ⚑ corrected `FUN_1002dbd0` | G_Message.cc | post message (text, type 0/1/2, upper, sticky readout TV); max flli 24 = 20, dropped when full; re-post of a readout un-sticks it | HIGH | listing `1002dbd0..1002dd88`; was MED "show game message" |
| ⚑ corrected `FUN_1002dd90` | G_Message.cc | age messages each frame: after flli 25 = 60 frames, fade += flli 26 = 1; delete at 32 (one per frame) | HIGH | listing; was MED |
| `FUN_1002dea0` | G_Message.cc | draw messages: sticky lines first, then newest-on-top stack, gap flli 27 = 20, formats 35/36/37 by type, alpha = fade | HIGH | listing `1002dea0..1002e18c` |
| `FUN_1002e190` | G_Message.cc | free message list | HIGH | listing |
| `FUN_1002e300` | G_Message.cc (span) | level-select-active flag getter (`DAT_100e01fd`, written only in `FUN_1002e310`) | MED | listing + raw writer scan |
| `0x1002d950` (no function) | G_Console.cc | HELP handler (debug, unreachable) | HIGH | raw listing |
| ⚑ corrected `FUN_10018070` | Notice | notice module init (registers NOTICE, debug-only, not added) | HIGH | listing; was the umbrella row "notice start/stop/reset/post/tick/draw" MED |
| `FUN_100180e0` | Notice | notice module teardown | HIGH | listing |
| `FUN_10018130` | Notice | notice reset (alpha 32, sound 'none', 'CEGA') | HIGH | listing |
| `FUN_100181e0` | Notice | post / clear the single notice slot (hold, fade-in, delay, sound, alignment) | HIGH | listing |
| `FUN_10018320` | Notice | notice tick per game tick: delay, sound, auto-clear after flli 71 = 60, fade-in −flli 72 = 2, fade-out +flli 73 = 4 | HIGH | listing `10018320..100184ac` |
| `FUN_100184b0` | Notice | draw notice with format 49, alpha, alignment N+0x68 | HIGH | listing |
| `0x10018580` (no function) / `FUN_10018670` | Notice | NOTICE debug handler (unreachable) / static init | HIGH / LOW | raw listing |
| `FUN_10007d60` | G_Game.cc (span) | draw accuracy-tally text (format 53, alpha G+0x50) | HIGH | listing `10007d60..10007df8` |
| `0x10007e00`…`0x100090d0` (no functions; `FUN_10008820` is GAMETIME) | G_Game.cc (span) | 18 console handlers (§5.5): FPS, VERSION, supermunki, 6 cheats reachable; the rest debug-only | HIGH | raw listing + TVs `0x100defc8…0x100def84` |
| ⚑ corrected `FUN_10009230` | G_Game.cc (span) | post "Please Register Deimos Rising!" (de-obfuscated `0x100e447c`), type 1 | HIGH | listing; was LOW "show decoded notice text" |
| `FUN_10007130` | G_Game.cc (span) | reset the 5 cheat-use counters G+0x16c…0x17c at game start | HIGH | decompile + raw writer scan |
| `FUN_10030870` | frame controller | after the paused frame: console reset, pause screen, clear notice, unpause, quit request | HIGH | listing `10030870..100308f0` |
| `FUN_10022ef0` | G_Scores (span) | modal pause screen: gaso[8], music pause, wait for Caps Lock release; returns quit | MED | decompile |
| `FUN_10005ce0` | G_Game.cc (span) | game time getter `G+0x1c` | HIGH | decompile one-liner + GAMETIME TV use |
| `FUN_10048d70` | ? | read one OS event: keyDown → 2 + char, autoKey → 3, mouseDown → 1 | MED | decompile |
| `FUN_100461b0` | ? | running on Mac OS X (Gestalt 'sysv' ≥ 0x0A00) | HIGH | decompile one-liner |
| ⚑ corrected `FUN_10029c00` | G_Player.cc | advance player to next weapon of type; **caller found**: the debug command `PLAYER AIRWEP\|AIR` / `PLAYER GROUNDWEP\|GROUND` (sub-keywords of the PLAYER handler `0x10007ff0`, §5.5), unregistered → unreachable in 1.0.6 | HIGH | raw listing `10008404 addi r4,r30,0x4141; 10008408 bl 0x10029c00` ('PEAA'), `1000848c addi r4,r30,0x4147; 10008490 bl 0x10029c00` ('PEAG'); strings `AIRWEP` `0x100e41fc`, `AIR` `0x100e4203`, `GROUNDWEP` `0x100e4207`, `GROUND` `0x100e4211` (data image); weapons-projectiles.md said "no caller" — ⚑ corrected (review wave 2, 2026-10-03) (`FUN_10029c00` conflict closed): was MED "PLAYER AIR/GROUND" |

## INDEX updates (for merge)
- **Out-of-scope note "Debug console commands …" refined:** only `FPS`, `VERSION`/`VERS`, `SUPERMUNKI`, `LIFE`,
  `ACCURACY`, `FUNDS`, `SCORE`, `SHIELDS`, `MULT` are registered. Every other command is gated out by
  `FUN_1002d080`'s debugOnly flag (§5.2). Cheat word = `supermunki` (§5.3). New topical row:
  `messages-notices-console.md`.
- **#12 narrowed:** GameString 24–30 (`Game Speed …`) and 19/20 (`Auto Interlacing …`) have no code reference
  at all (§3 raw scans). The game-speed feature posts no text in 1.0.6. ~~The divider writer is still open.~~
  ⚑ corrected (review wave 2, 2026-10-03) #C11: #12 is closed by timing-frame.md §3 (no code writes the divider).
- **#13 narrowed:** byte pref 9 = FPS counter (console `FPS` toggles it), **byte pref 11 = cheats enabled**
  (set by `supermunki`, 0 in fresh prefs), int pref 0 = sound volume 0–100 in steps of 10 (`-`/`=`), int pref 3 also
  written by the unreachable ALLLEVELS (§2.5, §5).
- **#11 touched:** console/cheat sounds use `FUN_10047670(id, 0x32, 100, 1)` (§NR 3, now settled by
  sound-music.md §2.3).
- **scoring-bonuses.md NR 7 closed:** `0x1000827c` = PLAYER SCORE (+9000) and `0x10008380` = PLAYER DESTROY.
  Both are debug-only and unreachable (§5.5).
- **weapons-projectiles.md NR (FUN_10029c00 "no caller"):** closed (§5.5; caller in raw code, unreachable).
- ⚑ conflict **scoring-bonuses.md §11**: ALLLEVELS is listed among cheats that "refuse during a film, need
  pref 11, set +0xbd". It does none of these and is not registered in 1.0.6 (§5.5).
- ⚑ conflict **engine-loop.md §3 skeleton** ("console commands registered once (SHADOWS, FPS, LIMITFPS,
  PLAYER, VERSION, … cheats)"): SHADOWS/LIMITFPS/PLAYER are not added (§5.2).
- ⚑ conflict **engine-loop.md §4** "`fc+4` == 1 interlaced": `fc+4` is the `FUN_10030210` init argument (1 in
  the game loop, 0 on level select), independent of the interlace pref 5 (§4.4).
- level-scroll-objects.md §9 / function-roles.md rows for the G_Background console handlers: the code readings stand,
  but every one of them is unreachable in the shipped build (§5.2).
