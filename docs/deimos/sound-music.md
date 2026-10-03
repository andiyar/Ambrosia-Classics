# Deimos Rising 1.0.6 — sound effects, mixer, master volume and music (wave 2, reader 8)

Scope: M_Sound.cpp / M_Music.cpp `0x10047160–0x10047fa0` (23 functions) plus the rest of the
M_Music group up to the Toolbox init (`FUN_10048120 … FUN_100482c0`), the statically linked
sound library they drive (`0x100cfc90–0x100d3530`: a 16-voice software mixer and a double-buffer
music streamer, both on top of SoundLib), the state-sound handler inside `FUN_10033850`
(`10033b64–10033c54`), the volume-key handler `FUN_10030910`, the configuration-dialog volume
items, and every literal call site of the sound API (found by scanning the code image for `bl`
to each entry point). OUT: the AIFF/WAVE/ima4 parsers beyond their accept/reject gates
(`FUN_100d2400`, `FUN_100d2750`, `FUN_100d0ef8`, `FUN_100d0cf0`), the IMA encoder `FUN_100d3170`
(never reached by shipped data), the list primitives `FUN_100009e0/0c00/0ce0/0e10` (U_List,
used by name only), and `FUN_100470f0` (sits before the range; a motion-blur slot helper, not
sound). ⚑ corrected (review wave 2, 2026-10-03) #M5 — **not read** (in the declared `0x100cfc90–0x100d3530` range but no row and
no mention): `FUN_100d0394`, `FUN_100d05a8`, `FUN_100d0bd8` (22 lines), `FUN_100d0c64` (21),
`FUN_100d1284` (20), `FUN_100d12f8`, `FUN_100d2360` (33), `FUN_100d26d0` (29), `FUN_100d2da0` (27),
`FUN_100d2e30` (37), `FUN_100d3020`, `FUN_100d3060` (27) — all small (≤ 37 lines; sizes from the
review's census). Evidence files: `$W/disasm-w2s8.txt`, `$W/disasm-w2s8b.txt` (raw PPC), dump lines cited
as `dump:N`. Constants resolved from `$W/mem/10000000.bin` (code image: TOC float tables live
there, not in the data section) with the Python one-liners quoted in place.

## 1. Architecture in one paragraph

Sound effects never touch a Sound Manager channel per sound. `FUN_10047160` starts a private
software mixer (`FUN_100d1400(numChannels=8, 44100.0 Fixed)`) that owns ONE stereo 16-bit
44.1 kHz `SndPlayDoubleBuffer` channel and a sorted list of up to 16 "voices"; every played sound
is a voice in that list, and only the first `numChannels` voices are heard. All sounds are held
in memory as headerless IMA-ADPCM (`'asnd'`/`'mIMA'`) and decoded, resampled and mixed in the
double-buffer callback. Music is a second, independent `SndPlayDoubleBuffer` channel fed by
asynchronous `PBReadAsync` from the stored (uncompressed) ZIP entry inside `Music.pak`.
The master "Sound Volume" changes the **Mac's default output volume** (`SetDefaultOutputVolume`),
so it scales effects and music together; music has its own level via `ampCmd`. [HIGH — §2–§6]

## 2. Sound effects: load, records, play API

### 2.1 Functions (M_Sound.cpp)
| function | role | label | evidence |
|---|---|---|---|
| `FUN_10047160 @ 10047160` | sound init(numChannels): logs "    Sound Channels: %i"; warns (non-fatal assert `numChannels > 0 and numChannels <kPriv_MaxChannels`, i.e. 1..98) if out of range; `FUN_100d1400(n & 0xffff, 0xAC440000)`; on success saves the user's device volume (`FUN_100d1730`) in `DAT_100e028c`, sets `DAT_100e0290` (sound available) = `DAT_100e0291` (effects enabled) = 1, applies prefs `FUN_10047920`, allocates the record list `DAT_100e0294` (12 bytes); on failure logs "NON FATAL TOOL ERROR: (%i) Sound not available." and sound stays off | HIGH | `1004719c cmpwi r30,0x0; ble; cmpwi r30,0x63; blt` · `100471e8 lis r4,-0x53bc` (=0xAC44<<16) · `10047228 stb r0,-0x60a0(r2)` · `10047230 stb r0,-0x609f(r2)`; strings `0x100f0038+0x15/+0x2c/+0x6b`; caller `FUN_100000e0` with PermFloat 38 `SoundNumChannels` = 8 |
| `FUN_10047290 @ 10047290` | sound shutdown: free all records (`FUN_10047460`), stop mixer (`FUN_100d1630`, restores the user's device volume), free list | MED (read) ⚑ label audit (review wave 2) | caller `FUN_10000630` |
| `FUN_10047330 @ 10047330` | load sound tag `('soun', id)` → convert with `FUN_100d1780` → record `{+0 magic 0x499602D2, +4 id, +8 asnd*, +0xC lastVoice = −1}` appended to the list; frees the original tag handle | MED ⚑ label audit (review wave 2) | dump:42205–42239; error string `+0xd5` "couldn't convert an AIFF sound to the internal format" |
| `FUN_10047460 @ 10047460` | delete every record | MED (read) | caller `FUN_10047290` |
| `FUN_10047510 @ 10047510` | delete the record of one id (does **not** stop its voices) | MED (read) | callers boot (`publ`), `FUN_1001faf0` |
| `FUN_100475e0 @ 100475e0` | play from a 0x18 sound record (unit/player/weapon `*Sound_*` blocks) — §2.3 | HIGH | listing `10047600–1004764c` |
| `FUN_10047670 @ 10047670` | `play(id, priority, volume, allowMultiple)` at pitch 1.0 — §2.3 | HIGH | listing `10047674 lwz r8,-0x6dbc(r2); 1004767c or r7,r6,r6; 10047680 lfs f1,0x0(r8)` (= 1.0) |
| `FUN_100476a0 @ 100476a0` | stop ALL effect voices now (`FUN_100d1be0(0)`) | HIGH | `100476b8 li r3,0x0; bl 0x100d1be0`; callers game end `10005ad8`, pause `FUN_10022ef0` |
| `FUN_100476e0 @ 100476e0` | is-playing(id): true iff the record's **last started voice** is still in the voice list | HIGH | §2.4 |
| `FUN_100477d0 @ 100477d0` | integrity check of every record ("Sound Manager Integrity FAILURE") | MED | **no caller** (callers.txt) |
| `FUN_10047910 @ 10047910` | return `DAT_100e0290` (sound available) | HIGH | 1 instruction; callers boot, `FUN_1001fe60`, `FUN_100417d0` |
| `FUN_10047bf0 @ 10047bf0` | the play primitive — §2.3 | HIGH | listing `10047bf0–10047e34` |

### 2.2 Load-time format conversion (what is actually played)
`FUN_100d1780` accepts AIFF/AIFC or RIFF/WAVE, compression `NONE`/`ima4`, channels < 2
(sprite-sound-containers.md §4). `FUN_100d1d90` turns an Apple `ima4` sound into one continuous
IMA nibble stream: it walks the 34-byte packets as 16-bit words, **drops word 0 of every 17**
(the per-packet predictor/step-index header) and swaps the two nibbles of every byte
(`(w & 0x0f0f)<<4 | (w>>4) & 0x0f0f`); header = `{'asnd', sampleCount, rate, 'mIMA'}`.
8/16-bit PCM is re-encoded to IMA (`FUN_100d3170`); every shipped effect is already ima4.
[MED for the drop/swap (dump:106741–106752; ⚑ label audit (review wave 2): was HIGH on the dump only); MED for the
consequences below]
- The decoder never re-syncs to the dropped packet headers; it carries predictor/index across
  packets. Differences from a reference ima4 decode are rounding-level. [MED]
- `sampleCount = (bytes − bytes/34) × 2` = 66·P for P packets, but only 64·P real samples exist:
  the last 2·P samples decode zero nibbles from the zeroed tail of the buffer (a held, slowly
  decaying DC level). `icbu` (P = 239): 478 extra samples ≈ 10.8 ms. [MED — arithmetic from the
  decompile `uVar10 = (uVar10 - uVar10/0x22) * 2`; inaudible in practice]

### 2.3 Play parameters (closes INDEX #11)
Signature, from the listings:
```
FUN_10047bf0(r3 id, r4 priority (low byte), r5 volume (int), r6 unused, r7 allowMultiple (low byte), f1 pitch)
FUN_10047670(id, priority, volume, allowMultiple)          → bf0 with r7 = r6, f1 = 1.0
FUN_100475e0(record*, allowMultiple)                        → bf0(rec+0, rec+0xC & 0xFF,
                                                                RandomRange(rec+4, rec+4), –, allowMultiple,
                                                                f1 = RandomRangeF(rec+0x10, rec+0x14))
```
`FUN_10047bf0` steps (listing):
1. Return if `id == 'none'`, or sound unavailable (`-0x60a0(r2)`), or effects disabled
   (`-0x609f(r2)`, never cleared anywhere — the only store is `10047230`; code-image scan). [HIGH]
2. If `allowMultiple == 0` and `FUN_100476e0(id)` → return (no restart while the last instance
   lives). `10047c40 rlwinm. r0,r7,…; bne; bl 0x100476e0; …; bne 0x10047e20`. [HIGH]
3. `priority = min(priority & 0xFF, 100)` (`10047c54 rlwinm r0,r27,0,24,31; cmplwi r0,0x64; ble;
   li r27,0x64`). [HIGH]
4. Find the record by id (linear walk). Not found → `FUN_1001f950(0,id,2)` loads it on demand and
   prints "RESOURCE: Sound '%s' loaded." (or "…not found.") on the console. ⚑ bug: after an
   on-demand load the code plays `r29` = the **last record visited by the walk** (the previously
   last-loaded sound), not the new one, and stores the voice id there (`10047d80` tests `r24`
   from the loader; `r29` is untouched since `10047cb0`). Reachable only for a sound that was not
   preloaded. [HIGH reading; MED that shipped data never reaches it — every sound is preloaded
   by `FUN_1001fe60`/`FUN_1003e680`/`FUN_1002b790` or explicitly (`publ`)]
5. Build the mixer request and call `FUN_100d18d0`; store the returned voice id in record `+0xC`
   (`10047e1c stw r3,0xc(r29)`, also when it returns 0). [HIGH]

Mixer request (stack `r1+0x48`), listing `10047d88–10047e10`, table `T = *(r2−0x6dbc)` =
`0x100d7414` = {1.0, 128.0, 100.0, 0.0, 65536.0} (command:
`struct.unpack('>5f', code[0xd7414:0xd7428])` on `mem/10000000.bin`):
| req off | value | meaning | evidence |
|---|---|---|---|
| +0x00 | record+8 | asnd data | `10047dc0 lwz r0,0x8(r29); stw r0,0x48(r1)` |
| +0x04 | 0 | voice id → mixer assigns (odd counter, +2 per voice) | `10047ddc stw r6,0x4c(r1)`; `100d1ae0–1aec` |
| +0x08 | `(int)(65536.0f × pitch)` | rate multiplier, 16.16 | `10047d98 lfs f0,0x10(r30); 10047db0 fmuls f0,f0,f31; fctiwz` |
| +0x0C, +0x10 | 0, 0 | completion callback / its refcon → none (no loop, no callback) | `10047de8`, `10047df0` |
| +0x14 (h) | priority 0..100 | ranking key 1 | `10047e04 sth r5,0x5c(r1)` |
| +0x16, +0x18 (h) | `(int)(128.0f × (float)volume / 100.0f)` both | left = right gain /128 → **always centre, no pan** | `10047dcc fdivs; 10047de0 fmuls; fctiwz; 10047e08/0c sth` |
| +0x1A | 0 | – | `10047e10` |
So: volume 100 → 128 (unity), 90 → 115, 80 → 102, 75 → 96, 70 → 89, 50 → 64 (single-precision,
truncated). From a record the volume is **MinVolume only** (MaxVolume is never read;
`10047620 lwz r3,0x4(r30); or r4,r3,r3`) and the priority is `Priority_INT & 0xFF`. [HIGH]
Sound Manager commands used for effects: none per sound — `SndNewChannel(sampledSynth=5,
initStereo 0xC0)` + `SndPlayDoubleBuffer` once at init (`FUN_100d2c30`); no `volumeCmd`/`rateCmd`/
`ampCmd` on the effects channel. Volume, pitch and mixing are the library's own arithmetic. [HIGH]

### 2.4 Is-playing
`FUN_100476e0(id)`: 0 if sound unavailable or `id == 'none'`; else find the record and return
`FUN_100d1b30(record+0xC) != 0` (`1004777c rlwinm r3,r3,0,16,31; neg; or; rlwinm …,1,31,31`).
`FUN_100d1b30(x)` counts voices whose id == x **or** data pointer == x **or x == 0**
(`100d1b88–100d1ba8`). Consequences [HIGH]:
- "Playing" means the *most recently started* instance of that sound is still in the voice list
  (audible or not, §3). Older overlapping instances are invisible to it.
- If the last start was refused by a full mixer, `+0xC` = 0 and is-playing returns true while
  **any** voice exists (bug; only with 16 voices live).
- A never-played record has `+0xC = −1` → false.

## 3. The voice list — channel model, priority, stealing

Mixer globals (TOC slots → addresses): count `0x100dee6c`, voices `0x100dee68` (16 × 0x38,
memset 0x380), audible limit `0x100dee74` = numChannels capped at 16 (`100d14f8 cmpwi r0,0x10`),
rate `0x100dee5c` = 44100.0, 16-bit (`0x100dee64`=16), 2 channels (`0x100dee60`=2), 1024-frame
buffers (`100d1574 li r5,0x400`). [HIGH — listing `100d1400–100d1630`]

Voice struct (0x38), from `FUN_100d18d0` stores (`100d1a30–100d1ac8`):
| off | meaning |
|---|---|
| +0x00 | voice id | 
| +0x04 | asnd pointer |
| +0x08 | step = `FixMul(+0x0C, pitch)` (`FUN_1006e250`) |
| +0x0C | `FixDiv(outRate, soundRate)` (`FUN_1006e2b0`) = 1.0 for 44.1 kHz sounds |
| +0x10 / +0x2C | callback / refcon (0) |
| +0x14 | sample data (asnd+0x10) |
| +0x18 h / +0x1A h | IMA predictor / step index |
| +0x1C / +0x20 | position / total samples (asnd+4) |
| +0x24 / +0x28 | last left / right output (interpolation) |
| +0x30 h / +0x32 h | left / right gain (≤ 0x80) |
| +0x34 h | priority (0 → 1) |
| +0x36 b | finished flag |

### 3.1 Insertion (start) — `FUN_100d18d0`
```
clamp: priority 0 → 1 (100d191c), gains > 0x80 → 0x80 (100d1930, 100d1944)
i = 0
while voice[i].data != 0 and i < 16:
    if new.prio < voice[i].prio            (100d1978 cmplw; blt → next)
       or new.L+new.R < voice[i].L+voice[i].R   (100d1998 cmpw; blt → next):  i++
    else break                              -- insert here
if i == 16: return 0                        (100d19cc–19e4: refused, nothing evicted)
if count >= 16: count = 15                  (100d19ec–19f8: the 16th voice is overwritten)
BlockMoveData(voice[i] → voice[i+1], (count − i)·0x38); fill voice[i]; count++
```
[HIGH — listing]. So the list is ordered newest-first among equals, a new sound goes in front
of the first voice it equals-or-beats on **both** priority and gain sum, and when 16 voices are
live a new sound that ranks anywhere above the last one **evicts the last (lowest-ranked) voice**
silently; one that ranks below all 16 is refused. The order is fixed at insertion — it is never
re-sorted.

### 3.2 Mixing — `FUN_100d21a0` (double-buffer callback via `FUN_100d2340`)
Zero the stereo buffer; for each voice index `i < count`: if `i < numChannels` (8) decode-and-mix
into the buffer, else run the same decoder with a NULL destination (position advances, nothing
is heard) (`100d21e8 lwz r0,0x0(r28)` = `0x100dee74`; `100d21f0 cmpw r26,r0; bge 100d2228`;
`100d2244 li r4,0x0`). Finished voices are removed afterwards (`FUN_100d1cf0`), which shifts the
voices below them up. [HIGH]
⇒ **Channel model: 16 voice slots, the top 8 by insertion rank are audible; voices 9–16 keep
playing silently and become audible mid-sample when a voice above them finishes.** [HIGH]

`FUN_100d32d0` (per voice) [HIGH for the arithmetic, listing `100d32d0–100d3528`]:
- IMA decode one nibble per input sample (step index clamp 0..88 `cmpwi r18,0x58`, predictor
  clamp ±32767), gain `sample·g >> 7` per side (`100d33ec mullw; srawi r22,r9,0x7`).
- `acc += step>>4` per input sample; `n = (acc>>12) − (prev>>12)` output frames are written for
  that input sample by linear interpolation from the previous sample (`divwu r24,0x100,n`);
  `n = 0` drops the input sample (no filter). Each output is **saturating-added** into the
  buffer (±32767 clip, `100d3440–100d3488`).
- ⇒ `step` = output frames per input sample = `pitch` for a 44.1 kHz sound. **A pitch value p
  plays the sound at speed 1/p: p > 1 is longer and lower, p < 1 shorter and higher.**
  E.g. `exsl` (Ex – Short Loud) as a bullet's destruct sound at p ∈ [0.50, 0.55] plays ≈ 1.9×
  fast (a short high pop). [HIGH for the code; ⚑ this inverts the key's name — Ben's ear check,
  NR 1]
- Done when the input is exhausted (`100d34f8 li r0,-0x1; stb`).

`FUN_100d1be0(x)` stops voices matching id / data / all (x = 0) and compacts the list. [HIGH —
listing `100d1c30–100d1cc4`]

## 4. Master volume, sound off, device volume

### 4.1 Values
`FUN_10047b80(v)` = `clamp((int)(128.0 × v / 100.0), 0, 128)` (same table `0x100d7414`: +4 =
128.0, +8 = 100.0, +0xC = 0.0; listing `10047b80–10047be0`, `fcmpo; bge/ble` = inclusive clamp).
`FUN_100d16d0(u)` = `SetDefaultOutputVolume(w | w<<16)`, `w = (min(u,256)·scale + 0x80) >> 8`,
`scale` = `0x100dee44` = 256 after `GetDefaultOutputVolume` succeeded (`FUN_100d2f10`) → `w = u`.
[HIGH — listing `100d16ec–100d1718`, `FUN_100d2fc0` calls `SetDefaultOutputVolume`]
⇒ pref volume v (0..100) sets the **Mac's** output to `128·v/100` of 0x100 full scale: 100 % →
0x80 (half of hardware full scale), 50 % → 0x40, 10 % → 12, 0 → 0. This scales music too.
The user's original device volume (average of L/R, `FUN_100d1730`) is saved at init and put back
by `FUN_10047ad0` (suspend paths `FUN_10023da0/FUN_10025190/FUN_10025270`) and by the mixer
shutdown `FUN_100d1630` (restores the original L and R separately). [HIGH]

All device-volume writes are skipped when `FUN_100461b0()` is true = `Gestalt('sysv') ≥ 0x0A00`
(Mac OS X) (`100461b8 lis r3,0x7379; addi r3,0x7376` = 'sysv'; `100461e4 cmpwi r0,0xa00`). The
shipped binary imports InterfaceLib/SoundLib only (classic), so under OS 9 or Classic the gate is
false and the volume path is live. [HIGH gate; MED that it is always false in practice]

### 4.2 Prefs
| pref | default (`FUN_100050f0`) | meaning (from consumers) | evidence |
|---|---|---|---|
| int 0 (`+0x68`) | 50 | sound (master) volume 0..100 | `FUN_10047990/10047a30/10047920`; dialog slider item 0x0C |
| int 1 (`+0x6C`) | 100 | music volume 0..100 | `FUN_10048280`; dialog slider item 0x0F |
| int 2 (`+0x70`) | 50 | not a sound pref (no reader in scope) | – |
| byte 7 (`+0x0B`) | 0 | "apply sound volume" checkbox (item 10): enables slider 0x0C and lets `FUN_10047920`/`FUN_10047b10` push int 0 to the device | `FUN_10011590` (enable/disable item 0x0C on byte 7), `FUN_10010fc0` case 10 |
[HIGH for defaults (`FUN_100050f0`: `+0x68 = 0x32, +0x6c = 100, +0x70 = 0x32, +0xb = 0`);
MED for the labels — the DITL text is in the resource fork (INDEX #13)]

### 4.3 Key path (− / =) — `FUN_10030910` → `FUN_10047990` / `FUN_10047a30`
- Edge-triggered: a key acts on the tick it goes down (latches `+0x0E` for `-` 0x1B, `+0x0F` for
  `=` 0x18). [HIGH — dump]
- Down: if sound available and v > 0: `v = max(v − 10, 0)`; Up: if v < 100: `v = min(v + 10, 100)`;
  then device ← `FUN_10047b80(v)` (unless OS X) and store int pref 0. **Pref byte 7 is not
  consulted** — the keys always drive the device volume. [HIGH — listing `100479c0–10047a04`,
  `10047a60–10047aa8`]
- Feedback (unless OS X, on any press, even at a limit): play gaso 7 `GameInterfaceSoundChange`
  (`incl`) with `FUN_10047670(id, 100, 100, 1)` — priority 100, volume 100, pitch 1 — then the
  console line pgsl 21 "Sound Volume     OFF" if the result < 1, else
  "%s%i%s" = pgsl 22 "Sound Volume" + v + pgsl 23 "%". [HIGH — `10030a1c`, strings
  `0x100eb21f` = "%s%i%s"]
- The confirmation sound is started after the device change, so it is heard at the new level
  (silent at OFF).

**Sound off** = pref 0 → device volume 0: every sound and the music are inaudible but still
started, mixed and timed. There is no separate mute flag (`DAT_100e0291` is set once, never
cleared). With sound unavailable (init failed) every play call is a no-op and the keys do
nothing (both test `DAT_100e0290`). [HIGH]

### 4.4 When the device volume is (re)applied
| moment | code | effect | label |
|---|---|---|---|
| boot, right after the display opens | `FUN_100000e0` → `FUN_10047a30()` then `FUN_10047990()` | **always** pushes the pref to the device (byte 7 ignored), and quantises it: v ≤ 90 → unchanged (v+10−10); **100 → 90** (up is a no-op at 100, down applies); 95 → 90 | HIGH — `10000340`/`10000348`, listings above |
| sound init | `FUN_10047920` | device ← pref only if byte 7; then music level `FUN_10048280` | HIGH |
| config dialog slider moved / OK / close | `FUN_10010fc0` cases 0x0C/0x0F/4 and exit | `FUN_10047920` | HIGH (dump) |
| resume from suspend | `FUN_10047b10` (= same body as `FUN_10047920`) | device ← pref only if byte 7 | HIGH |
| suspend | `FUN_10047ad0` | device ← user's original | HIGH |

## 5. State sounds — `FUN_10033850` step 3 (`10033b64–10033c54`)
`r18` = state base, `r19` = entity, `r17` = game time. Per entity update:
```
if stateEntrySound_ID == 'none': skip                                   (10033b6c)
trigger = false
if stateSoundLoop (+0x18):                                               (10033b78)
    trigger = (entity.lastSoundTime(+0xE4) == 0) or now >= last + SoundLoopDelay(+0x1C)   (10033b98 cmpw; blt)
elif entity.enterCount[state](+0x14C + 4·state) == 1:                    (10033bb8)
    trigger = entity.soundCount(+0xE8) == 0                              -- first visit: once
elif RepeatOnStateChange (+0x1A):                                        (10033bd4)
    trigger = entity.soundCount == 0                                     -- later visits: once each
if trigger and AllowOnlyOneInstance (+0x19) and FUN_100476e0(soundID):   (10033bf8–10033c14)
    play = false   (else play = trigger)
if trigger:
    if play and (SoundMaxNumToPlay(+0x20) == 0 or soundCount < MaxNum):   (10033c24–10033c34 bge)
        FUN_100475e0(state, allowMultiple = 1)                           (10033c3c li r4,0x1)
    soundCount += 1; lastSoundTime = now                                  (10033c48–10033c54)
```
State entry (`FUN_100146f0`, dump:33584–33592) does `enterCount[state] += 1` and
`soundCount = 0`, but does **not** reset `lastSoundTime`. [HIGH for the handler (listing); MED
for the entry resets (decompile of an out-of-scope function)]

Exact semantics:
- **SoundLoopDelay** — retrigger when `now ≥ last + delay` (period = delay ticks; delay 0 = every
  tick). The first loop play is immediate if the entity never played (`last == 0`); after a state
  change the period continues from the previous state's last play. [HIGH]
- **SoundMaxNumToPlay** — 0 = unlimited; else at most N plays per state visit, counted in
  triggers: a trigger suppressed by AllowOnlyOneInstance or by the cap **still increments the
  count and restarts the delay**. Applies to non-loop states too (where it is moot: one trigger
  per visit). [HIGH]
- **AllowOnlyOneInstance** — skip the start while the most recent instance of the **same sound ID,
  from any entity**, is still a live voice (§2.4). Shipped data: TRUE in 6 states, all with sound
  `none` → never takes effect. [HIGH — handler + data census over `unde/*.txt`]
- **RepeatOnStateChange** — without it a state's entry sound plays only on the entity's first visit
  to that state (enterCount == 1). [HIGH]
- Every state sound is started with allowMultiple = 1, so overlapping instances are normal. [HIGH]
- Other record players (`FUN_10014f10` shield/unshielded hit, `FUN_10016300` destruct,
  `FUN_10018320` notice, `FUN_10026ee0` overload) also pass allowMultiple = 1
  (`10015140/10015164/100164f0/10018388/10027070 li r4,0x1`). [HIGH — call-site scan]

Data census (state blocks): Loop TRUE 11 (cash/iris `cabo` delay 6 max 10; Photon Beam `phbh`
delay 19; `miwa` delay 18 max 4; `lgbu` delay 3), RepeatOnStateChange TRUE 24, MaxNum ≠ 0 44.
Priorities in all sound records: 50 ×2359, 100 ×54, 70 ×73, 30–90 others. [HIGH — grep counts]

## 6. Music (M_Music.cpp + streamer)

### 6.1 Functions
| function | role | label | evidence |
|---|---|---|---|
| `FUN_10047e40 @ 10047e40` | music init(spoolBuffer = PermFloat 37 = 204800): "    Music Spool Buffer Size: %i"; `FUN_100cfc90` requires Sound Manager ≥ 3.2 (`version 3 && minor ≥ 0x20`); stores the size in `DAT_100e029c` | MED ⚑ label audit (review wave 2) | dump:42669–42694, strings `0x100f01ec+0x15/+0x5a` |
| `FUN_10047ef0 @ 10047ef0` | music shutdown: `FUN_10048120(1)`, `FUN_100cfe30` | MED ⚑ label audit (review wave 2) | caller `FUN_10000630` |
| `FUN_10047f50 @ 10047f50` | "music service" = `FUN_100cfdd4`: fires the stream's completion callback when flagged; the game always passes callback 0 → **no-op**; streaming is interrupt-driven | MED | `FUN_100cfe64` arg 5 = 0 (`_DAT_100e0764 = param_5`), `FUN_100cfdd4` tests it |
| `FUN_10047f80 @ 10047f80` | return `DAT_100e02a0` (music playing, not paused) | MED ⚑ label audit (review wave 2) | caller `FUN_100064d0` |
| `FUN_10047f90 @ 10047f90` | `playMusic(id, loop, startPaused)`: pause+stop the current stream; find the tag's pak PATH and byte range (`FUN_10002080('soun',…)`); `FUN_100cfe64(spec, off, len, 204800, 0, loop, startPaused)`; playing flag = !startPaused; errors "MUSIC ERROR …" (−43 has its own line) | HIGH | listing `10047f90–1004811c`; every caller passes loop 1, paused 0 |
| `FUN_10048120 @ 10048120` | `stopMusic(fade)`: if a stream exists and is playing and fade: `FUN_100d04d8(1000)` then **block** servicing until the fade ends or 600 ticks pass ("ALERT: Sound Spool infinite loop!"); pause; dispose (`FUN_100d0250`: `quietCmd`, close file, free buffers) | HIGH | ⚑ label audit (review wave 2): HIGH kept on the listing (`$W/disasm-review2.txt`) `10048134 bl 0x100481e0` (exists), `10048144 lbz r0,-0x6090(r2)` (playing), `10048150 rlwinm. r0,r31` (fade), `10048158 li r3,0x3e8; bl 0x100d04d8` (1000 ms), `1004819c addi r31,r3,0x258` (now + 600), `10048180 cmplw r3,r31; ble` (guard), `100481b0 li r3,0x1; bl 0x10048220` (pause), `100481bc bl 0x100d0250` (dispose); dump:42795–42816; fade=1 only from quit (`10022e88`) and shutdown (`10047f20`) |
| `FUN_100481e0 @ 100481e0` | stream exists (`DAT_100e077a`) | MED ⚑ label audit (review wave 2) | |
| `FUN_10048220 @ 10048220` | `p=1`: pause = `getRateCmd`(0x55) saved, `rateCmd`(0x52) 0; flag 0. `p=0`: if a stream exists: resume = `rateCmd` saved rate; flag 1 | HIGH | `FUN_100d039c` `100d03dc li r4,0x55`, `100d03ec li r4,0x52`; `FUN_100d040c` `100d0448 li r4,0x52; 100d044c lwz r6,-0x5bc0(r2)` |
| `FUN_10048280 @ 10048280` | music level ← int pref 1: `FUN_100d0470(FUN_100482c0(v))` | MED ⚑ label audit (review wave 2) | |
| `FUN_100482c0 @ 100482c0` | `clamp((int)(128.0·v/100.0), 0, 128)`; table `*(r2…) = 0x100d7430` = {128.0, 100.0, 0.0} | HIGH | `struct.unpack('>3f', code[0xd7430:0xd743c])` |

### 6.2 Level and fade arithmetic
`FUN_100d0470(m)` stores `m` (≤ 0x100) in `0x100e072e` and sends `ampCmd` (0x2B) with
`amp = min(255, (m · fade) >> 8)` (`FUN_100d136c`, `100d139c mullw; rlwinm …,24,8,31; cmplwi
r31,0xff`). `fade` (`0x100e0730`) starts at 0x100 (data image `00000100`). ⇒ music pref 100 →
`amp = 128`, i.e. ≈ half of ampCmd full scale (255), while an effect at volume 100 is mixed at
unity. [HIGH arithmetic; MED for ampCmd's scale on a sampled channel (Inside Macintosh: Sound,
0–255)]. If sound init fails `FUN_10048280` never runs and music plays at amp 255.
Fade: `FUN_100d04d8(ms)` sets a negative step so that the double-buffer callback
(`FUN_100d05d0`) lowers `fade` by 1 per |step| bytes consumed: 256 steps over `ms` (0x3E800 =
256 × 1000). Only fade-**out** exists: the code image has exactly three stores to `0x100e0730`
(`100d055c` = 0, `100d077c` −1, `100d07f8` +1 only for a positive step, which no caller makes) —
nothing resets it to 0x100, so music started after a fade would be silent; the only fade is at
quit, so this is never heard. [HIGH — TOC-displacement scan of the code image for `-0x5c00(r2)`]

### 6.3 Streaming and loop points
`FUN_100cfe64`: open the pak's data fork, seek to the entry, parse AIFC (`FUN_100d0ef8`) for the
SSND start/length, two half-buffers of `min(204800/2, ssndLen/2)` = 102400 bytes, new channel
`SndNewChannel(sampledSynth, initStereo)`, `ampCmd` with the current level, start
(`SndPlayDoubleBuffer`). The callback copies from the half-buffers and refills the drained half
with `PBReadAsync`; at the end of SSND with loop set it continues from the SSND start in the same
buffer (`FUN_100d0968`: `*(iVar1+0x2e) = ssndStart`), else it marks the last buffer.
⇒ **Loop point = whole sound data, seamless, no intro/loop markers.** Music is never resident.
[HIGH for the call chain (imports + decompile); MED for byte-exact wrap]

### 6.4 When which music plays [HIGH unless marked — call-site scan + listings]
| moment | code | music |
|---|---|---|
| boot, after the publisher logo (unless Command held) | `FUN_100000e0` `10000494` | `inmu` Interface Music Loop, looped; 240-tick wait |
| main menu, each pass after returning (`DAT_100e01b6`) | `FUN_100229a0` | stream gone → restart `inmu`; else resume |
| Start Game (not film) | `FUN_100234d0` `10023518–100235b8` | pause, `tran` sound (gaso 3, prio 75, vol 100), stop, `ammu` Ambient Music Loop looped → level select |
| level load (not film) | `FUN_100064d0` `1000675c–100067c8` | if nothing is playing (any level after the first) start `ammu`; after player setup **stop** (immediate) |
| game appears (`gameTime == PermFloat 18` = 2, not film) | `FUN_100051a0` `10005968–10005974` | the level's `#music_ID` (leve `+0x27c`; `mu03` in all 12) looped, **from the start every level** |
| level complete | `FUN_10007170` `10007204/10007224` | stop immediately; `tran` (prio 75, vol 100) |
| game end (not film) | `FUN_100051a0` `10005ad8–10005ae4` | stop all effects; stop music immediately |
| film playback | `FUN_100234d0` film branch skips pause/stop/`ammu`; `FUN_100064d0`/`FUN_100051a0` skip their music calls | the **menu `inmu` keeps playing** through the replay; no level music |
| quit from the menu | `FUN_100229a0` → `FUN_10048120(1)` | 1 s linear fade-out, blocking |
No `gaso`/`leve` key chooses interface or ambient music: `inmu`/`ammu` are literal 4CCs in code
(`lis r3,0x616d; addi 0x6d75` etc.). The `gaso` list holds effects only (§7).

### 6.5 Pause and suspend
- Caps Lock pause (`FUN_10030570` → `FUN_10030870` → `FUN_10022ef0`): **all effect voices are
  cut** (`FUN_100476a0`), gaso 8 `Paused` (`incl`) plays at prio 50 / vol 100, music is paused
  (`rateCmd 0`); on unpause music resumes at the same sample (`rateCmd` saved rate) unless the
  player quit; cut effects do not come back. [HIGH — dump of `FUN_10022ef0` + call-site args
  `10022f24–10022fb8`]
- Menu suspend (switch-out paths `FUN_10023da0`, `FUN_10025190`, `FUN_10025270`): pause music,
  restore the user's device volume; resume `FUN_10023e10`: re-apply the pref volume (byte 7),
  resume music unless inside the pause screen. [HIGH reading; MED for what triggers them]

## 7. `gaso` (permanent sound list, 24) and every literal call site
`gaso` (data-tags.md §4): 0 ButtonClick `clic`, 1 ConsoleActivate `clic`, 2 InterfaceClick
`incl`, 3 InterfaceTransition `tran`, 4 CommandConfirmation `incl`, 5 CommandFailure `lsna`,
6 EndGameFinale `leen`, 7 GameInterfaceSoundChange `incl`, 8 Paused `incl`, 9 HighScoreAchieved
`none`, 10 Registered `leen`, 11 InterfaceMenuButtonRollover `mbro`, 12 LevelSelectChoose `lsse`,
13 LevelSelectSelector `lsch`, 14 LevelSelectFailure `lsna`, 15 ScoreEntryFailure `shwa`,
16 HighScore `cabo`, 17 EditorAddObject `none`, 18 WepSelector_Switch `wesw`, 19 Briefing_Typing
`none`, 20 MoneyCount `moco`, 21 MoneyCount_NoBonus `nobo`, 22 GroundAccuracyCount_MaxBonus
`acbo`, 23 GroundAccuracyCount_MissionBonus `miac`. [HIGH — `Sounds[gaso].idli.txt`]
`FUN_10047670` literal calls (gaso index → priority, volume, allowMultiple), from scanning every
`bl 0x10047670` and the preceding `li` instructions [MED — the index is the `li r3` before the
`PermSoundID` call, matched by a heuristic; spot-checked at `1002355c–10023574`, `10030a1c`]:
| gaso | prio | vol | allowMulti | where |
|---|---|---|---|---|
| 0, 2, 4, 9, 15 | 50 | 100 | 1 | menu screens `FUN_10021950`…`FUN_10022164`, `FUN_10025fcc…` |
| 1 | 50 | 100 | 1 | console open `1002d1d4` |
| 2 | 75 | 100 | **0** | menu buttons `10023c30…10023d64`, `10024b44`, `10024fb8`, `10025aa8` |
| 3 `tran` | 75 / 50 | 100 | 1 | level complete `10007224`, start game `10023574` (75); `10023888`, `10023a20` (50) |
| 4 / 5 | 50 | 100 | 1 | console command OK / fail `1002d904/1002d928` |
| 5 / 22 | 50 | 100 | 1 | console cheats `10008b0c…10009208` |
| 7 | 100 | 100 | 1 | volume keys, F6 interlace `10030a1c/10030b60` |
| 8 | 50 | 100 | 1 | pause `10022f44` |
| 10 | 75 | 100 | 1 | registration `10023f90` |
| 11 | 75 | 100 | **0** | rollover `10024664`, `1002fff0` |
| 12/13/14 | 50 | 100 | 1 | level select `1002ec3c/1002edb8/1002ec7c` |
| 18 | 75 | 100 | 1 | weapon switch `1003b91c` |
| 20/21/22 | 50 | 100 | **0** | tallies `100076a0…10007a60`, `100279c4…10027cc0` |
| 23 | 100 | 100 | 0 | mission bonus `10007bd0` |
| `publ` | 50 | 100 | 1 | boot `10000390` |
No code plays gaso 6 `EndGameFinale` (agrees with INDEX #27).

## 8. What a 100 % replica must reproduce (audible) vs implementation detail
Must reproduce:
1. 16-slot ranked voice list, top 8 (`SoundNumChannels`) audible, the insertion rule of §3.1
   (both-keys comparison, newest-first among equals), silent advance of voices 9–16 and their
   mid-sample entry, eviction of the 16th, refusal below all 16.
2. Per-call gain `trunc(128·MinVolume/100)/128`, centre pan, priority `min(P & 0xFF, 100)` (0 → 1),
   one-shot (no loop); pitch p drawn by float `RandomRange(MinPitch, MaxPitch)` and applied as
   **speed 1/p** with linear-interpolation upsampling / sample dropping, saturating mix.
3. `allowMultiple = 0` calls (menu clicks, rollovers, tallies) do not restart while the last
   instance lives; the state-sound rules of §5 including counted suppressed triggers.
4. Master volume: 0..100 in steps of 10 on edge-triggered `-`/`=`, `incl` feedback at prio 100,
   the two console strings, scaling **everything including music**, gain `0.5·v/100` of full scale
   (or `v/100` relative — the absolute ×0.5 only matters against other apps), default 50, the boot
   quantisation (100 → 90 each launch), sound off = silence with timing unchanged.
5. Music: the §6.4 schedule (inmu/ammu/level music, restarts from 0 each level, immediate stops,
   film keeps menu music), whole-file seamless loops, pause = freeze-and-resume, pause cuts effects,
   1 s fade only at quit, music ≈ half amplitude of a full-volume effect at music pref 100.
6. RNG: the pitch draw happens on every `FUN_100475e0` call whose ID ≠ `none` and Min ≠ Max, **even
   when sound is unavailable or muted** (the only gate before the draw is the ID test,
   `10047600–10047618`). AllowOnlyOneInstance would make RNG depend on wall-clock audio state, but
   it is dead in shipped data.
Implementation detail (free to differ): the SoundLib plumbing (one double-buffer channel, 1024
frames, `SndDoImmediate` commands), IMA re-encoding and the dropped packet headers, the 2·P-sample
DC tail, streaming buffer sizes and async reads, changing the system output volume (a replica
should apply an app gain and must not touch the OS volume), restoring the original volume on
suspend/quit, the on-demand-load wrong-sound bug and the full-mixer is-playing bug (both need
conditions shipped play never meets), the OS X gate.

## Worked example — Ion Cannon release at power level 10 while two other sounds play
Setup (all values from the shipped files): a Cash Station `cscr` in "Spawn Large Coin" plays `cabo`
(state sound vol 100, prio 70, pitch 1.0); an enemy Panzer pulse bullet `ppbu` dies →
`destructSound exsl` (vol 100, prio 50, pitch 0.50–0.55). Voice list (count 2):
`[0] cabo (70, L+R 128+128=256)`, `[1] exsl (50, 256)` — `cabo` was inserted in front because
70 ≥ 50 and 256 ≥ 256.
1. Release at tick r (weapons-projectiles.md worked example 4a): `icpo` switches to
   "_Powerup Release, Dwindle & Del" → on its next update the state sound `icre` (vol 100 → gain
   128, prio 50, pitch 1.0/1.0 → `FUN_100465e0(1.0,1.0)`, step 65536) is started with
   allowMultiple 1. Insertion: vs `cabo` 50 < 70 → next; vs `exsl` 50 ≥ 50 and 256 ≥ 256 → slot 1.
   List: `[cabo, icre, exsl]`, all audible.
2. Level 10 → 10 `icps` spawners at r, r+2, …, r+18, each spawning one `icpb`; each `icpb` plays
   `icbu` on its first update: vol 90 → `(int)(128·0.9f)` = **115** both sides (sum 230), prio 45,
   pitch p ∈ [0.8, 1.2] (one float draw each), request rate `(int)(65536·p)`.
   First `icbu`: 45 < 70, 45 < 50, 45 < 50 → end of list (slot 3). Each later `icbu` equals the
   previous one (45, 230) → goes in front of it: `[cabo, icre, exsl, icbu_k, …, icbu_1]`.
3. Durations: `icbu` 239 packets → 15774 declared samples × p output frames → 0.29–0.43 s =
   8.6–12.9 ticks at 30 fps, so with one new `icbu` every 2 ticks 5–7 are live; `exsl` at
   p ≈ 0.52 lasts 38544 × 0.52 ≈ 20000 frames ≈ 0.45 s (≈ 14 ticks); `cabo` 0.87 s; `icre` 1.18 s.
   Peak ≈ 3 + 7 = 10 voices > 8: the two **oldest `icbu`** (the bottom of the list) are silent but
   keep advancing; when `exsl` finishes they move up and are heard from mid-sample. Nothing is
   evicted (eviction needs 16 live voices); nothing is refused.
4. Loudness: `cabo`, `icre`, `exsl` at unity, each `icbu` at 115/128 ≈ −0.9 dB, all centred,
   summed with ±32767 clipping; the whole mix and the `mu03` level music (amp 128 at music pref 100)
   then go through the device volume (pref 50 → 0x40/0x100).
Plain tap-fire for comparison: each shot spawns two `icb ` bullets whose state sound is `icbu`
vol 70 → gain 89, prio 40, pitch 0.8–1.2 → two instances per shot, the second (right) in front
of the first, both behind any prio ≥ 40 sound of equal-or-greater gain.

## NOT RESOLVED (this file)
1. Pitch direction by ear: the code makes `pitch` a duration multiplier (speed 1/p). Settle: Ben
   listens to a bullet impact (`exsl` at 0.5) or `icbu` in the original — short/high confirms.
2. `ampCmd` scale on a sampled-sound channel (255 or 256 = full?) — decides whether music at pref
   100 is −6 dB vs effects. Settle: Inside Macintosh: Sound / SM 3.x notes, or a capture.
3. Labels of the dialog items 10/0x0C/0x0F and slider ranges (resource-fork DITL/CNTL not
   parsed) — INDEX #13.
4. `FUN_1001f950(0,id,2)` (on-demand resource load) and whether any shipped path plays a sound
   that was not preloaded (would trigger the wrong-sound bug of §2.3 step 4).
5. Writers of `DAT_100e01b6`/`DAT_100e01b5` (menu "returned"/"in pause") and which UI events call
   the suspend helpers `FUN_10023da0/10025190/10025270` (browser launch? registration?).
6. `FUN_100d0ef8`/`FUN_100d0cf0` (stream header, frames-per-buffer) and the exact byte at which a
   looping stream wraps — not read.
7. Whether the mixer's 1024-frame buffer timing interacts with the 30-fps tick for
   AllowOnlyOneInstance (moot for shipped data).

## Role-table rows (for merge)
| `FUN_10047160` | M_Sound.cpp | sound init: mixer `FUN_100d1400(n,44100)`, n = flli 38 (8) (warn unless 1..98), save user device volume, flags 0290/0291, apply prefs, record list | HIGH | listing `1004719c–10047270` |
| `FUN_10047290` | M_Sound.cpp | sound shutdown: free records, mixer stop (restores device volume) | MED | read — ⚑ label audit (review wave 2): was HIGH on read only |
| `FUN_10047330` | M_Sound.cpp | load `soun` tag → asnd/mIMA record {magic, id, data, lastVoice −1} | MED | read — ⚑ label audit (review wave 2): was HIGH on read only |
| `FUN_10047460` | M_Sound.cpp | free all sound records | MED | read |
| `FUN_10047510` | M_Sound.cpp | free one sound record by id (voices not stopped) | MED | read |
| ⚑ corrected `FUN_100475e0` | M_Sound.cpp | play sound record: volume = MinVolume, prio = Priority&0xFF, pitch = RandomRangeF(Min,Max), (record, allowMultiple) (was "play sound from settings block" MED) | HIGH | listing `10047600–1004764c` |
| ⚑ corrected `FUN_10047670` | M_Sound.cpp | play(id, priority, volume, allowMultiple) at pitch 1.0 (was "play sound (id, volume…)" MED) | HIGH | listing `10047670–10047698` |
| `FUN_100476a0` | M_Sound.cpp | stop all effect voices | HIGH | listing |
| ⚑ corrected `FUN_100476e0` | M_Sound.cpp | is-playing: last started voice of the id still in the voice list (was MED "usage") | HIGH | listing `100476e0–100477c4`, `FUN_100d1b30` |
| `FUN_100477d0` | M_Sound.cpp | record-list integrity check (no caller) | MED | read |
| `FUN_10047910` | M_Sound.cpp | sound-available getter | HIGH | listing |
| `FUN_10047920` | M_Sound.cpp | apply prefs: device ← int pref 0 if byte 7 (not on OS X); music level ← int pref 1 | HIGH | listing `10047920–1004798c` |
| ⚑ corrected `FUN_10047990` | M_Sound.cpp | volume down: pref0 −10 (≥0) → device 128·v/100 (unless OS X) (was LOW) | HIGH | listing |
| ⚑ corrected `FUN_10047a30` | M_Sound.cpp | volume up: pref0 +10 (≤100) → device (was LOW) | HIGH | listing |
| `FUN_10047ad0` | M_Sound.cpp | restore the user's device volume (suspend) | HIGH | listing |
| `FUN_10047b10` | M_Sound.cpp | re-apply prefs (same body as `FUN_10047920`; resume) | HIGH | listing |
| `FUN_10047b80` | M_Sound.cpp | volume % → 0..128 (`clamp(128·v/100,0,128)`) | HIGH | listing + table `0x100d7414` |
| ⚑ corrected `FUN_10047bf0` | M_Sound.cpp | play primitive (id, prio≤100, vol→128·v/100 L=R, allowMultiple, f1 pitch→16.16) → mixer voice (was "play sound by ID" MED) | HIGH | listing `10047bf0–10047e34` |
| `FUN_10047e40` | M_Music.cpp | music init (spool buffer flli 37 = 204800; SM ≥ 3.2) | MED | read — ⚑ label audit (review wave 2): was HIGH on read only |
| `FUN_10047ef0` | M_Music.cpp | music shutdown (fade-stop, lib close) | MED | read — ⚑ label audit (review wave 2): was HIGH on read only |
| `FUN_10047f50` | M_Music.cpp | music service (completion callback; no-op as used) | MED | read |
| `FUN_10047f80` | M_Music.cpp | music-playing flag getter | MED | read — ⚑ label audit (review wave 2): was HIGH on read only |
| `FUN_10047f90` | M_Music.cpp | play music (id, loop, startPaused) streamed from pak | HIGH | listing |
| ⚑ corrected `FUN_10048120` | M_Music.cpp | stop music (fade=1: 1 s blocking fade-out, 600-tick guard) (was "stop/fade music" LOW) | HIGH | read + call args; ⚑ label audit (review wave 2): HIGH kept on the listing `10048158 li r3,0x3e8; bl 0x100d04d8`, `1004819c addi r31,r3,0x258`, `10048180 cmplw r3,r31; ble` (`$W/disasm-review2.txt`) |
| `FUN_100481e0` | M_Music.cpp | music stream exists | MED | read — ⚑ label audit (review wave 2): was HIGH on read only |
| `FUN_10048220` | M_Music.cpp | pause (1: getRate+rateCmd 0) / resume (0: rateCmd saved) music | HIGH | listings `FUN_100d039c/040c` |
| `FUN_10048280` | M_Music.cpp | music level ← int pref 1 | MED | read — ⚑ label audit (review wave 2): was HIGH on read only |
| `FUN_100482c0` | M_Music.cpp | music % → 0..128 | HIGH | table `0x100d7430` |
| `FUN_100d1400` | sound lib | mixer init (≤16 audible, 44.1k 16-bit stereo, 1024-frame double buffer, save device volume) | HIGH | listing |
| `FUN_100d1630` | sound lib | mixer shutdown, restore device L/R | MED | read — ⚑ label audit (review wave 2): was HIGH on read only |
| `FUN_100d16d0` | sound lib | SetDefaultOutputVolume(v) | HIGH | listing |
| `FUN_100d1730` | sound lib | saved device volume, avg L/R | HIGH | listing |
| `FUN_100d1780` | sound lib | convert AIFF/AIFC/WAVE (NONE/ima4, mono) → asnd | MED | read — ⚑ label audit (review wave 2): was HIGH on read only |
| `FUN_100d18d0` | sound lib | start voice: ranked insertion, evict 16th, refuse below all | HIGH | listing `100d18d0–100d1b20` |
| `FUN_100d1b30` | sound lib | count voices by id / data / all | HIGH | listing |
| `FUN_100d1be0` | sound lib | stop voices by id / data / all | HIGH | listing |
| `FUN_100d1cf0` | sound lib | remove voice i | MED | read |
| `FUN_100d1d90` | sound lib | build asnd/mIMA (strip ima4 packet headers, nibble swap; PCM → IMA) | MED | read — ⚑ label audit (review wave 2): was HIGH on read only |
| `FUN_100d21a0` | sound lib | mixer render: voices < numChannels mixed, rest advanced silently | HIGH | listing |
| `FUN_100d32d0` | sound lib | IMA decode + gain>>7 + linear-interp resample + saturating mix (one voice) | HIGH | listing |
| `FUN_100d2c30` | sound lib | open mixer output (SndNewChannel sampledSynth stereo, SndPlayDoubleBuffer) | MED | read — ⚑ label audit (review wave 2): was HIGH on read only |
| `FUN_100d136c` | sound lib | music ampCmd = min(255, vol·fade>>8) | HIGH | listing |
| `FUN_100cfe64` | sound lib | start music stream (FSpOpenDF, AIFC header, double buffer, loop flag) | MED | read — ⚑ label audit (review wave 2): was HIGH on read only |
| `FUN_100d0250` | sound lib | stop music stream (quietCmd, dispose, close) | MED | read — ⚑ label audit (review wave 2): was HIGH on read only |
| `FUN_100d04d8` | sound lib | start music fade-out over N ms | MED | read |
| `FUN_100d05d0` | sound lib | music double-buffer callback (fill, last-buffer, fade step) | MED | read |
| `FUN_100d0968` | sound lib | music buffer copy + PBReadAsync refill + loop wrap | MED | read |
| `FUN_100461b0` | | is Mac OS X (Gestalt sysv ≥ 0x0A00) | HIGH | listing |

## INDEX updates (for merge)
- **#11 closed** → §2.3 (signature, volume 128·v/100, priority ≤ 100, pitch 16.16 = speed 1/p,
  allowMultiple, no pan/loop) and §3 (priority = ranking in a 16-voice list, 8 audible).
- **#13 narrowed** → §4.2: int prefs 0/1 = sound/music volume (defaults 50/100), byte 7 = the
  checkbox that enables the sound slider and the init/resume device push. Labels still unparsed.
- **#27 supported** → §7: no literal call plays gaso 6 `EndGameFinale`.
- ⚑ conflict, sprite-sound-containers.md §4: "`FUN_10047670(id, vol, ?, ?)`" → `(id, priority,
  volume, allowMultiple)`; "`FUN_100475e0` picks a random volume/pitch" → volume = MinVolume, only
  pitch is random (already in engine-loop.md §9); "Sound Manager glue … identified, not read
  further" → it is a 16-voice software mixer + streamer (§1, §3, §6).
- ⚑ conflict, level-scroll-objects.md §8 step 4: "`tran` … vol 75/100" → priority 75, volume 100.
- ⚑ conflict, engine-loop.md §3 skeleton "music; fade in" at game appearance: there is no music
  fade-in in the code (§6.2); the call is `FUN_10047f90(levelMusic, 1, 0)` followed by
  `FUN_1000ba70(display, 1)` (a display call, not audio).
- New fact for engine-loop.md §4/§10: Caps-Lock pause cuts all effects and pauses music (§6.5);
  the volume keys and boot change the **system** output volume (§4).
