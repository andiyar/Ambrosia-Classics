# BTX sound & music audit — original 1.1 (BTX_i386) vs main 002d9d0

Read-only audit, 2026-10-06. Oracle: `~/Developer/Ambrosia/ghidra/BTX_i386.decompiled.c` + `otool -tV BTX_i386`
(args recovered from the disassembly for every call, see `sites-table.tsv`), and — new — the bundled
`Contents/Frameworks/AmbrosiaTools.framework` (i386 slice, `otool -tV` → `at.txt`), which holds the Sound Tool itself.

## Counts
- `_PlayMySnd` call sites in the binary: **151** (149 `calll` + 2 tail `jmp`: `_Bubbles_NewGroup` 000166bc, `_PushBlock` 0001be36).
  Matched (same slot, priority, delay, condition): **146**. Not built by ruling (Known delta 1, unregistered paths): **5**
  (`_ResumeGame` 0000a32d, `_RegisterButton` 0000a378, `_Interface` R key 0000bc80, `_CheckHiScore` nag 00024c75/00024d22).
  Missing: **0**. Wrong id: **0**. Wrong condition: **0** found. Extra (ours plays, original doesn't): **0**.
- Other direct `ST_PlaySound`: `_PlayIntroSound` (snd 9027, prio 0x14, SFX-pref gated) → `FrontEnd/Splash.swift:93-94` MATCH.
- Delayed queue `_Sounds_Init/CheckDelayedSounds` → `Sim/Sounds.swift`, called `LevelBuild.swift:93`, `FrameStep.swift:145` MATCH.
- `ST_HaltSound(0)`: `_PauseGame` → `Pause.swift:40`; `_PlayGame` exit (not demo) → `GameSession.swift:473` MATCH.
- `SysBeep`: 6 sites. `_DoLevelSelect` d556 → `.beep` (Attract.swift:362); `_LevelSelectFilter` dd7e → BTXDialogs.swift:163;
  `_SetPrefsKey` deca → BTXPrefsWindow.swift:428; `_HiScoreNameFilter` 24956 → BTXDialogs.swift:198 — MATCH.
  `_numberFilter` d74b: function unreferenced (dead). `_PlayGame` 1926c: mode-2 recording save (Known delta 5) — N/A.

## Defects / discrepancies
1. **SFX volume law is half the original (−6 dB) at the default pref.** [confidence 0.8]
   `ST_PlaySound(snd, prio, vol)` (AmbrosiaTools 000e5852) builds a param block with L = R = vol; `ST_PlaySoundParam`
   (000e5598) clamps each side to **0x80** (000e55e7…000e5600) and the mixer `ADPCM_Mixer` (000e8683) applies
   `sample * vol >> 7` (000e8843…000e8859) — so 0x80 is unity. `_PlayMySnd`'s 0x10 / 0x40 / 0x100 (pref 2/3/4) therefore
   play at 0.125 / **0.5** / 1.0 (0x100 clamped). Ours: `BTXAudio.sfxVolume` (BubbleTroubleX/App/BTXAudio.swift:81-88) passes
   0x10/0x40/0x100 to `ShellMixer`, whose gain is `volume/256` (HectorKit ShellMixer.swift:289) → 0.0625 / **0.25** / 1.0.
   Music is right (Sound Manager volumeCmd, 0x100 = unity: 0x40/0x80/0x100 → 0.25/0.5/1.0).
   At defaults (SFX 3, music 4) the original mix is effects 0.5 : music 1.0; ours is 0.25 : 1.0 — effects masked by music,
   which fits "some sound effects are missing". Fix shape: SFX gain = min(vol, 0x80)/0x80 (i.e. pass 0x20/0x80/0x100).
   Residual uncertainty: relative loudness of the ST's own CoreAudio output vs the Sound Manager channel on OS X (assumed both unity;
   `_ST_SetAppVolume` is never called by BTX; `ST_SetVolume(ST_GetSysVolume())` at `_InitMac` is a system-volume no-op).
2. **Q6/U5 recovered — our default is the original rule.** [0.85] `ST_PlaySoundParam`: ST_Open(4,0) → 4 entries in a list kept
   sorted by priority (then L+R volume); a new sound is inserted before the first entry with prio ≤ new (and vol ≤ new); if the
   list is full the LAST entry (lowest priority, oldest of equals) is cut (its callback gets 3); no qualifying entry → dropped;
   priority 0 is raised to 1. `BTXAudio.chooseVoice` (BTXAudio.swift:103) is equivalent while all effects share one volume (true
   except the prefs Music-popup snd 13). Known delta 8 can be closed as transcribed.
3. **`_StartMusic` on an already-playing channel queues, ours restarts.** [0.6] Original `_StartMusic` (0001ad8c) only
   `SndPlay(async)`s 50 more segments — on a busy channel they queue behind the current one (no flush). Ours `.start`
   (BTXAudio.swift:153-156) calls `output.play`, which cuts and restarts. Only reachable when music is already playing at a
   hero appearance: e.g. pause during the 70-frame "Get Ready" window or during the death→respawn wait (`_PauseGame` exit
   `_ResumeMusic` starts it), then the hero appears → original continues seamlessly, ours restarts the track. Rare; ear-level.
4. **Q14 wording is wrong for snd 29** (harmless). [0.95] snd 9029 "More Bubbles" is played by `_Bubbles_NewGroup` group 7
   (0001676a: slot 0x1d, prio 1), and groups 0–8 come from `_gBubbles_RandGroupsTable` — reachable whenever air bubbles are on.
   Ours already plays it (AirBubblePool.swift:187). snd 9012 "Warble" is only reached by the play-all-sounds pause cheat
   (0x242795e, slots 0…47) — ours does that too (Cheats.swift:100). So nothing is unused-and-unplayed; fix the ruling text.
5. Checked, MATCH: `_Interface` treats autoKey (event 5) like keyDown (held B/W repeat the squeak/bark); ours queues repeats
   to the menu loop too (FrontEnd.swift:258-276); screens drop them as the 0x800a mask does.

## Music
Choice: `_NewLevel` (0001735f) → `_LoadMusic(1)` (not demo) → STR# 131 [3] "Level set " + `NumToString(level+4)` + [4] " music" + ".1"
→ `GetNamedResource('snd ')`; `level+4` = LEVL word 2 (copied verbatim in `_LoadLevel`). One segment, looped by queueing it 50×.
`_LoadMusic(0)` (title) = "Title music" → replaced by literal "Level set 3 music". `_LoadMusic` is a no-op while loaded;
`_UnloadMusic` after every count-down (not demo) and at game exit. Ours: `GameSession.swift:425` `.load(set: levelMusicSet)` =
`levelRecord.words[2]` (GameState+Session.swift:50) → `BTXGameData.musicName` (BTXGameData.swift:129) → same named resource;
unload at GameSession.swift:383 / 469; title = set 3 (FrontEnd.swift:514). **MATCH for every level.**

| levels (LEVL w2 from BT Levels.rsrc) | original resource | ours |
|---|---|---|
| 1–3, 13–15, 25–27, 37–39, 50 | snd 11001 "Level set 1 music.1" | 11001 |
| 4–6, 16–18, 28–30, 40–42 | snd 11002 "Level set 2 music.1" | 11002 |
| 7–9, 19–21, 31–33, 43–45 | snd 11003 "Level set 3 music.1" | 11003 |
| 10–12, 22–24, 34–36, 46–49 | snd 11004 "Level set 4 music.1" | 11004 |
| > 50 (`_LoadLevel`: random LEVL 21…50) | that LEVL's w2 | same |
| title / menu (and continuing into demos) | 11003 | 11003 |

Start/stop sites all matched: title load+start (`_Interface` → Splash.swift:156/168), restart when idle (Attract.swift:76),
resume when paused+foreground (Attract.swift:77); New Game / level select: fade, unload, game, reload, start (Attract.swift:257-268,
370-378); hero appears → start (play only; GameSession.swift:165-169); death → stop no fade (172; demo: FrontEnd.swift:240-246);
level end → fade (`_StopMusic`, GameSession.swift:321); pause → pause/resume(+start if idle) (Pause.swift:41/54-55);
suspend/resume (FrontEnd.swift:569-591); quote (Attract.swift:339); quit (Attract.swift:330); music menu/prefs →
`_UpdateMusicVolume` (BTXAudio.swift:174). Volume law 0/0x40/0x80/0x100 and the −5/tick fade from 0x40/0x80/0x100: MATCH.

## Decoding
`HECTORKIT_DATA_BTX=… swift test --filter testSoundBankDecodes52` (offline, no audio engine): PASS — all 48 effects
(9000–9047, 9047 from `Bubble Trouble X.rsrc`) + 4 music (11001–11004) decode, non-empty, sane rates. No silent ids.

## Full call-site table (PlayMySnd, binary order)
| # | function | call @ | slot | prio | delay | ours | verdict |
|---|---|---|---|---|---|---|---|
| 1 | _TimeBonus_Process | 00006a95 | 0x1e | 0x14 | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Sim/TimeBonus.swift:30 | MATCH |
| 2 | _TimeBonus_Process | 00006ab1 | 0x17 | 0x14 | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Sim/TimeBonus.swift:31 | MATCH |
| 3 | _TimeBonus_Process | 00006aee | 0x15 | 0x14 | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Sim/TimeBonus.swift:35 | MATCH |
| 4 | _TimeBonus_CountDown | 00006e16 | 0x9 | 0x1e | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Session/TimeBonusCountdown.swift:77 | MATCH |
| 5 | _TimeBonus_CountDown | 00006e8c | 0x29 | 0x1e | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Session/TimeBonusCountdown.swift:81/83 (0x2a if bonus 0, 0x29 if >=10001) | MATCH |
| 6 | _TimeBonus_CountDown | 00006f07 | 0x11 | 0x1e | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Session/TimeBonusCountdown.swift:96 | MATCH |
| 7 | _ResumeGame | 0000a32d | 0xd | 0x14 | 0 | N/A unregistered->registered transition (Known delta 1) | N/A (ruled) |
| 8 | _RegisterButton | 0000a378 | 0x13 | 0xa | 0 | N/A Register button (Known delta 1) | N/A (ruled) |
| 9 | _RequestGame | 0000abb5 | 0x13 | 0x14 | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/FrontEnd/Attract.swift:453 | MATCH |
| 10 | _NewGameButton | 0000aca8 | 0x24 | 0x14 | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/FrontEnd/Attract.swift:258 | MATCH |
| 11 | _CreditsButton | 0000af2b | 0x27 | 0x14 | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/FrontEnd/Attract.swift:296 (0x13/0x26/0x28/0x2c/0x27 by modifier) | MATCH |
| 12 | _HandleMSMouse | 0000b0a3 | 0 | 0xa | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/FrontEnd/Attract.swift:171 | MATCH |
| 13 | _HandleMSMouse | 0000b15b | 0x11 | 0xa | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/FrontEnd/Attract.swift:178 | MATCH |
| 14 | _HandleMSMouse | 0000b29b | 0x11 | 0xa | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/FrontEnd/Attract.swift:192 | MATCH |
| 15 | _HandleMSMouse | 0000b4a6 | 0x27 | 0xa | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/FrontEnd/Attract.swift:232 | MATCH |
| 16 | _HandleMSMouse | 0000b4c2 | 0x12 | 0xa | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/FrontEnd/Attract.swift:233 | MATCH |
| 17 | _Interface | 0000bad8 | 0x11 | 0xa | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/FrontEnd/Attract.swift:126/131 (N) | MATCH |
| 18 | _Interface | 0000bb10 | 0x16 | 0xa | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/FrontEnd/Attract.swift:139 (L) | MATCH |
| 19 | _Interface | 0000bb3c | 0x24 | 0x14 | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/FrontEnd/Attract.swift:368 | MATCH |
| 20 | _Interface | 0000bba5 | 0x11 | 0xa | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/FrontEnd/Attract.swift:126/135 (C) | MATCH |
| 21 | _Interface | 0000bbdd | 0x11 | 0xa | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/FrontEnd/Attract.swift:126/141 (P) | MATCH |
| 22 | _Interface | 0000bc3f | 0x11 | 0xa | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/FrontEnd/Attract.swift:126/143 (Q) | MATCH |
| 23 | _Interface | 0000bc80 | 0x11 | 0xa | 0 | N/A R key, unregistered only (Known delta 1) | N/A (ruled) |
| 24 | _Interface | 0000bcc6 | 0x2f | 0x1e | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/FrontEnd/Attract.swift:133 (B 0x2f) / 147 (W 0x2e) | MATCH |
| 25 | _DoLevelSelect | 0000d48d | 0x16 | 0xa | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/FrontEnd/Attract.swift:353 | MATCH |
| 26 | _SetPrefsKey | 0000e076 | 0x9 | 0xa | 0 | BubbleTroubleX/App/BTXPrefsWindow.swift:446/449 (0xd ALEX. / 9 DWARE eggs) | MATCH |
| 27 | _ChangeArea | 0000ea08 | 0x11 | 0xa | 0 | BubbleTroubleX/App/BTXPrefsWindow.swift:140 | MATCH |
| 28 | _PrefsDialog | 0000ec10 | 0x16 | 0xa | 0 | BubbleTroubleX/App/BTXPrefsWindow.swift:83 | MATCH |
| 29 | _PrefsDialog | 0000f4b2 | 0x12 | 0xa | 0 | BubbleTroubleX/App/BTXPrefsWindow.swift:257 | MATCH |
| 30 | _PrefsDialog | 0000f554 | 0xd | 0xa | 0 | BubbleTroubleX/App/BTXPrefsWindow.swift:262 (sfx level := music level) | MATCH |
| 31 | _PopEnemy | 0001129c | 0 | 0xa | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Sim/EnemyMutations.swift:77 | MATCH |
| 32 | _SquishEnemy | 0001139d | 0 | 0xa | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Sim/EnemyMutations.swift:21 | MATCH |
| 33 | _SquishEnemy | 00011541 | 0x26 | 0xa | 0xf | BubbleTrouble/Core/Sources/BubbleTroubleCore/Sim/EnemyMutations.swift:33 | MATCH |
| 34 | _CheckForBombKills | 000117ba | 0x2b | 0xa | 0x5 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Sim/Dynamite.swift:55 | MATCH |
| 35 | _Bubbles_NewGroup | 000166bc | per group | 1/10 | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Pools/AirBubblePool.swift:177-195 via Sim/FrameStep.swift:116 + Sim/Hero.swift:138 (grp 4-6,9,10 ->28/p1; 7 ->29/p1; 8 ->27/p1; 0xb ->27/p10) | MATCH |
| 36 | _NewLevel | 00017658 | 0x2 | 0x14 | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Session/GameSession.swift:427 | MATCH |
| 37 | _PauseGame | 00017712 | 0x16 | 0x1e | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Session/Pause.swift:42 | MATCH |
| 38 | _PauseGame | 00017963 | 0 | 0x1e | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Session/Cheats.swift:93-113 (Cheats.Effect.steps) | MATCH |
| 39 | _PauseGame | 000179a9 | 0x3 | 0x1e | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Session/Cheats.swift:93-113 (Cheats.Effect.steps) | MATCH |
| 40 | _PauseGame | 000179ee | 0..47 loop | 0x1e | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Session/Cheats.swift:93-113 (Cheats.Effect.steps) | MATCH |
| 41 | _PauseGame | 00017a3b | 0x2f | 0x1e | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Session/Cheats.swift:93-113 (Cheats.Effect.steps) | MATCH |
| 42 | _PauseGame | 00017a7a | 0 | 0x1e | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Session/Cheats.swift:93-113 (Cheats.Effect.steps) | MATCH |
| 43 | _PauseGame | 00017b0d | 0x29 | 0x1e | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Session/Cheats.swift:93-113 (Cheats.Effect.steps) | MATCH |
| 44 | _PauseGame | 00017b52 | 0 | 0x1e | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Session/Cheats.swift:93-113 (Cheats.Effect.steps) | MATCH |
| 45 | _PauseGame | 00017b94 | 0x1f | 0x14 | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Session/Cheats.swift:93-113 (Cheats.Effect.steps) | MATCH |
| 46 | _PauseGame | 00017bb0 | 0x4 | 0x14 | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Session/Cheats.swift:93-113 (Cheats.Effect.steps) | MATCH |
| 47 | _PauseGame | 00017bcc | 0xf | 0xa | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Session/Cheats.swift:93-113 (Cheats.Effect.steps) | MATCH |
| 48 | _PauseGame | 00017c00 | 0 | 0x1e | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Session/Cheats.swift:93-113 (Cheats.Effect.steps) | MATCH |
| 49 | _PauseGame | 00017c30 | 0x23 | 0x1e | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Session/Cheats.swift:93-113 (Cheats.Effect.steps) | MATCH |
| 50 | _PauseGame | 00017c5f | 0x29 | 0x14 | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Session/Cheats.swift:93-113 (Cheats.Effect.steps) | MATCH |
| 51 | _PauseGame | 00017ca0 | 0x2f | 0x1e | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Session/Cheats.swift:93-113 (Cheats.Effect.steps) | MATCH |
| 52 | _PauseGame | 00017ccf | 0x2f | 0x1e | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Session/Cheats.swift:93-113 (Cheats.Effect.steps) | MATCH |
| 53 | _PauseGame | 00017cfb | 0x2f | 0x1e | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Session/Cheats.swift:93-113 (Cheats.Effect.steps) | MATCH |
| 54 | _PauseGame | 00017d2a | 0 | 0x1e | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Session/Cheats.swift:93-113 (Cheats.Effect.steps) | MATCH |
| 55 | _PauseGame | 00017d6d | 0 | 0x1e | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Session/Cheats.swift:93-113 (Cheats.Effect.steps) | MATCH |
| 56 | _PauseGame | 00017dad | 0 | 0x1e | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Session/Cheats.swift:93-113 (Cheats.Effect.steps) | MATCH |
| 57 | _PauseGame | 00017de5 | 0 | 0x1e | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Session/Cheats.swift:93-113 (Cheats.Effect.steps) | MATCH |
| 58 | _PauseGame | 00017e21 | 0 | 0x1e | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Session/Cheats.swift:93-113 (Cheats.Effect.steps) | MATCH |
| 59 | _PauseGame | 00017e67 | 0 | 0x1e | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Session/Cheats.swift:93-113 (Cheats.Effect.steps) | MATCH |
| 60 | _PauseGame | 00017ea7 | 0 | 0x1e | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Session/Cheats.swift:93-113 (Cheats.Effect.steps) | MATCH |
| 61 | _PauseGame | 00017efd | 0 | 0x1e | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Session/Cheats.swift:93-113 (Cheats.Effect.steps) | MATCH |
| 62 | _PauseGame | 00017f32 | 0 | 0x1e | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Session/Cheats.swift:93-113 (Cheats.Effect.steps) | MATCH |
| 63 | _PauseGame | 00017f6a | 0 | 0x1e | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Session/Cheats.swift:93-113 (Cheats.Effect.steps) | MATCH |
| 64 | _PauseGame | 00017f97 | 0 | 0x1e | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Session/Cheats.swift:93-113 (Cheats.Effect.steps) | MATCH |
| 65 | _PauseGame | 00017fcc | 0 | 0x1e | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Session/Cheats.swift:93-113 (Cheats.Effect.steps) | MATCH |
| 66 | _PauseGame | 00018006 | 0 | 0x1e | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Session/Cheats.swift:93-113 (Cheats.Effect.steps) | MATCH |
| 67 | _PlayGame | 000188ef | 0x8 | 0x14 | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Sim/FrameStep.swift:219 | MATCH |
| 68 | _PlayGame | 0001890b | 0x1b | 0xa | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Sim/FrameStep.swift:221 | MATCH |
| 69 | _PlayGame | 0001898d | 0x22 | 0x14 | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Sim/FrameStep.swift:234 | MATCH |
| 70 | _PlayGame | 00018a3e | 0x2 | 0x14 | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Sim/FrameStep.swift:251 | MATCH |
| 71 | _PlayGame | 00018a74 | 0x3 | 0x1e | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Sim/FrameStep.swift:249 | MATCH |
| 72 | _PlayGame | 00018af5 | 0x21 | 0x14 | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Sim/FrameStep.swift:102 | MATCH |
| 73 | _PlayGame | 00018d19 | 0x23 | 0x1e | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Sim/FrameStep.swift:447 | MATCH |
| 74 | _PlayGame | 00018dc9 | 0x1b | 0x1e | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Session/GameSession.swift:381 | MATCH |
| 75 | _PlayGame | 00019304 | 0x1b | 0x1e | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Session/GameSession.swift:476 | MATCH |
| 76 | _Multiplier_Flash | 00019d90 | 0x20 | 0x1e | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Session/TimeBonusCountdown.swift:74 | MATCH |
| 77 | _Multiplier_Process | 00019e5d | 0x20 | 0x1e | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Sim/Bonus.swift:134 | MATCH |
| 78 | _Bonus_Reward | 0001a302 | 0xf | 0xa | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Sim/Bonus.swift:187-219 (_Bonus_Reward by type) | MATCH |
| 79 | _Bonus_Reward | 0001a328 | 0x1f | 0x14 | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Sim/Bonus.swift:187-219 (_Bonus_Reward by type) | MATCH |
| 80 | _Bonus_Reward | 0001a344 | 0x4 | 0x14 | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Sim/Bonus.swift:187-219 (_Bonus_Reward by type) | MATCH |
| 81 | _Bonus_Reward | 0001a360 | 0xf | 0xa | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Sim/Bonus.swift:187-219 (_Bonus_Reward by type) | MATCH |
| 82 | _Bonus_Reward | 0001a386 | 0x1f | 0x14 | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Sim/Bonus.swift:187-219 (_Bonus_Reward by type) | MATCH |
| 83 | _Bonus_Reward | 0001a3a2 | 0x4 | 0x14 | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Sim/Bonus.swift:187-219 (_Bonus_Reward by type) | MATCH |
| 84 | _Bonus_Reward | 0001a3cf | 0x2c | 0x14 | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Sim/Bonus.swift:187-219 (_Bonus_Reward by type) | MATCH |
| 85 | _Bonus_Reward | 0001a3f4 | 0x2c | 0x14 | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Sim/Bonus.swift:187-219 (_Bonus_Reward by type) | MATCH |
| 86 | _Bonus_Reward | 0001a421 | 0x2c | 0x14 | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Sim/Bonus.swift:187-219 (_Bonus_Reward by type) | MATCH |
| 87 | _Bonus_Reward | 0001a446 | 0x2c | 0x14 | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Sim/Bonus.swift:187-219 (_Bonus_Reward by type) | MATCH |
| 88 | _Bonus_Reward | 0001a46b | 0x1f | 0x14 | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Sim/Bonus.swift:187-219 (_Bonus_Reward by type) | MATCH |
| 89 | _Bonus_Reward | 0001a494 | 0x1f | 0x14 | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Sim/Bonus.swift:187-219 (_Bonus_Reward by type) | MATCH |
| 90 | _Bonus_Reward | 0001a4c5 | 0x1f | 0x14 | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Sim/Bonus.swift:187-219 (_Bonus_Reward by type) | MATCH |
| 91 | _Bonus_Reward | 0001a4ee | 0x1f | 0x14 | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Sim/Bonus.swift:187-219 (_Bonus_Reward by type) | MATCH |
| 92 | _Bonus_Reward | 0001a517 | 0x1f | 0x14 | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Sim/Bonus.swift:187-219 (_Bonus_Reward by type) | MATCH |
| 93 | _Bonus_Reward | 0001a543 | 0x1a | 0x14 | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Sim/Bonus.swift:187-219 (_Bonus_Reward by type) | MATCH |
| 94 | _Bonus_Reward | 0001a673 | 0x28 | 0x14 | 0x5 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Sim/Bonus.swift:187-219 (_Bonus_Reward by type) | MATCH |
| 95 | _Bonus_Reward | 0001a6aa | 0x28 | 0x14 | 0x5 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Sim/Bonus.swift:187-219 (_Bonus_Reward by type) | MATCH |
| 96 | _Bonus_Pop | 0001a71e | 0x6 | 0xa | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Sim/Bonus.swift:168 | MATCH |
| 97 | _Bonus_Pop | 0001a73a | 0x1a | 0x14 | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Sim/Bonus.swift:169 | MATCH |
| 98 | _Bonus_Process | 0001aa77 | 0x13 | 0xa | 0x5 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Sim/Bonus.swift:53 | MATCH |
| 99 | _Bonus_Process | 0001aad9 | 0x6 | 0xa | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Sim/Bonus.swift:106 (shared exit) | MATCH |
| 100 | _Bonus_Process | 0001ac1c | 0x6 | 0xa | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Sim/Bonus.swift:106 (shared exit) | MATCH |
| 101 | _CrushBlock | 0001bcda | 0x6 | 0xa | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Sim/BlockCreation.swift:117 | MATCH |
| 102 | _PushBlock | 0001be36 | 5 | 0xa | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Sim/BlockCreation.swift:99 (tail jmp 5,10,0) | MATCH |
| 103 | _KillEggBlock | 0001bf19 | 0x6 | 0x14 | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Sim/BlockCreation.swift:143 | MATCH |
| 104 | _KillEggBlock | 0001bf35 | 0 | 0x14 | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Sim/BlockCreation.swift:144 | MATCH |
| 105 | _ExplodeBombBlock | 0001c0a4 | 0x19 | 0x14 | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Sim/Dynamite.swift:18 | MATCH |
| 106 | _ActivateBombBlock | 0001c286 | 0x18 | 0xa | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Sim/BlockCreation.swift:181 | MATCH |
| 107 | _Jewels_GiveBonus | 0001c876 | 0x21 | 0x14 | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Sim/Jewels.swift:95 | MATCH |
| 108 | _CheckJewelMovement | 0001cae8 | 0x9 | 0x14 | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Sim/Jewels.swift:70 | MATCH |
| 109 | _CheckJewelMovement | 0001cbf6 | 0x9 | 0x14 | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Sim/Jewels.swift:70 | MATCH |
| 110 | _MoveBlock | 0001d002 | 0x14 | 0xa | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Sim/MoveBlock.swift:150 | MATCH |
| 111 | _MoveBlock | 0001d07e | 0x14 | 0xa | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Sim/MoveBlock.swift:135 | MATCH |
| 112 | _MoveBlock | 0001d103 | 0x14 | 0xa | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Sim/MoveBlock.swift:135 | MATCH |
| 113 | _MoveBlock | 0001d16a | 0x14 | 0xa | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Sim/MoveBlock.swift:135 | MATCH |
| 114 | _MoveBlock | 0001d211 | 0x14 | 0xa | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Sim/MoveBlock.swift:135 | MATCH |
| 115 | _ProcessBlocks | 0001d4c4 | 0x10 | 0xa | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Sim/ProcessBlocks.swift:102 | MATCH |
| 116 | _ProcessBlocks | 0001d6b9 | 0x14 | 0xa | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Sim/ProcessBlocks.swift:123 | MATCH |
| 117 | _DisplayCredits | 0002159b | 0x11 | 0xa | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/FrontEnd/HighScores.swift:159-163 via Credits.swift:420 | MATCH |
| 118 | _DisplayCredits | 000215be | 0x11 | 0xa | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/FrontEnd/HighScores.swift:159-163 via Credits.swift:420 | MATCH |
| 119 | _HeroCaught | 00021e80 | 0x25 | 0x14 | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Sim/Catch.swift:35 (0x25 or 10 by GetRandomFast) | MATCH |
| 120 | _HeroCaught | 00021ea1 | 0 | 0x14 | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Sim/Catch.swift:37 | MATCH |
| 121 | _HeroCaught | 00021eef | 0x2d | 0x14 | 0x5 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Sim/Catch.swift:39 (0x2d or 0xb, +5) | MATCH |
| 122 | _HeroPushCrushCheck | 00022285 | 0x7 | 0xa | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Sim/Hero.swift:320 | MATCH |
| 123 | _HeroPushCrushCheck | 00022367 | 0x7 | 0xa | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Sim/Hero.swift:297/311/315 | MATCH |
| 124 | _AddHero | 00022dab | 0xd | 0x14 | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Sim/Scoring.swift:37 | MATCH |
| 125 | _AddHero | 00022dc7 | 0xd | 0x14 | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Sim/Scoring.swift:38 | MATCH |
| 126 | _Balloons_New | 00023a63 | 0xe | 0xa | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Sim/Balloons.swift:68 | MATCH |
| 127 | _Balloons_PopBalloon | 00023add | 0x10 | 0xa | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Sim/EnemyMutations.swift:177 | MATCH |
| 128 | _Balloons_CaptureHero | 00023cf6 | 0xf | 0xa | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Sim/Balloons.swift:209 | MATCH |
| 129 | _Balloons_CaptureHero | 00023d12 | 0x27 | 0xa | 0x5 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Sim/Balloons.swift:210 | MATCH |
| 130 | _Balloons_CheckBalloonEnemyHit | 00024068 | 0xf | 0xa | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Sim/Balloons.swift:238 | MATCH |
| 131 | _Balloons_CaptureAllEnemies | 00024253 | 0xf | 0xa | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Sim/Balloons.swift:309 | MATCH |
| 132 | _HiScoreEraseDialog | 000246ae | 0x16 | 0xa | 0 | BubbleTroubleX/App/BTXDialogs.swift:222 | MATCH |
| 133 | _HiScoreNameFilter | 00024979 | 0x1 | 0x14 | 0 | BubbleTroubleX/App/BTXDialogs.swift:203 (1, or 6 for arrows/Delete) | MATCH |
| 134 | _CheckHiScore | 00024c75 | 0xd | 0xa | 0 | N/A unregistered nag DLOG 1002 (Known delta 1) | N/A (ruled) |
| 135 | _CheckHiScore | 00024d22 | 0x11 | 0xa | 0 | N/A unregistered nag (Known delta 1) | N/A (ruled) |
| 136 | _CheckHiScore | 00024e6b | 0xd | 0xa | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/FrontEnd/HighScores.swift:195 (open) | MATCH |
| 137 | _CheckHiScore | 00024f7c | 0xf | 0xa | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/FrontEnd/HighScores.swift:196 (OK) | MATCH |
| 138 | _CheckHiScore | 0002509d | 0xd | 0xa | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Prefs/HighScoreTable.swift:124-136 (joke names) via FrontEnd/HighScores.swift:229 | MATCH |
| 139 | _CheckHiScore | 000250f1 | 0xd | 0xa | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Prefs/HighScoreTable.swift:124-136 (joke names) via FrontEnd/HighScores.swift:229 | MATCH |
| 140 | _CheckHiScore | 0002514e | 0xd | 0xa | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Prefs/HighScoreTable.swift:124-136 (joke names) via FrontEnd/HighScores.swift:229 | MATCH |
| 141 | _CheckHiScore | 000251c4 | 0x2e | 0xa | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Prefs/HighScoreTable.swift:124-136 (joke names) via FrontEnd/HighScores.swift:229 | MATCH |
| 142 | _CheckHiScore | 00025215 | 0xd | 0xa | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Prefs/HighScoreTable.swift:124-136 (joke names) via FrontEnd/HighScores.swift:229 | MATCH |
| 143 | _CheckHiScore | 00025268 | 0xd | 0xa | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Prefs/HighScoreTable.swift:124-136 (joke names) via FrontEnd/HighScores.swift:229 | MATCH |
| 144 | _CheckHiScore | 000252bc | 0xd | 0xa | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Prefs/HighScoreTable.swift:124-136 (joke names) via FrontEnd/HighScores.swift:229 | MATCH |
| 145 | _CheckHiScore | 0002530d | 0xd | 0xa | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Prefs/HighScoreTable.swift:124-136 (joke names) via FrontEnd/HighScores.swift:229 | MATCH |
| 146 | _CheckHiScore | 00025361 | 0xd | 0xa | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Prefs/HighScoreTable.swift:124-136 (joke names) via FrontEnd/HighScores.swift:229 | MATCH |
| 147 | _CheckHiScore | 000253ab | 0xd | 0xa | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Prefs/HighScoreTable.swift:124-136 (joke names) via FrontEnd/HighScores.swift:229 | MATCH |
| 148 | _CheckHiScore | 000253f5 | 0xd | 0xa | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Prefs/HighScoreTable.swift:124-136 (joke names) via FrontEnd/HighScores.swift:229 | MATCH |
| 149 | _CheckHiScore | 0002544f | 0xd | 0xa | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/Prefs/HighScoreTable.swift:124-136 (joke names) via FrontEnd/HighScores.swift:229 | MATCH |
| 150 | _DisplayHiScores | 00025a71 | 0x11 | 0xa | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/FrontEnd/HighScores.swift:159-163 | MATCH |
| 151 | _DisplayHiScores | 00025a94 | 0x11 | 0xa | 0 | BubbleTrouble/Core/Sources/BubbleTroubleCore/FrontEnd/HighScores.swift:159-163 | MATCH |
