# STATE — Ambrosia Classics — 2026-10-06 (BTX playable with sound; Ben playtesting; BTX for Windows staged)

> Live state only. Dated; re-verify before acting. Narrative goes in handoffs, forks in DECISIONS.

## Where we are

- **Phase 0 DONE (2026-10-03).** HectorKit **v0.1.0** (`~/Developer/HectorKit`, tag on f578925): HectorResources /
  HectorGraphics / HectorAudio lifted from EV e23122f + the new banded-QuickTime decoder; machine gate
  `tools/check-zero-skip.sh` PASS at **floor 119** (0 skips with the three `HECTORKIT_DATA_*` vars; EV Override
  forks + Aki 1.1 data). Classics: `Aki/Core` (AkiCore + `aki-census` + 6 data-gated tests, 6/6) and
  `docs/aki/data-census.md` (tool output: 82 PICT = 71 QuickTime + 11 raw, all decode to frame; 50 PNG; 14 + 15
  audio files open; 0 `snd `). Plan: `docs/plans/2026-10-03-phase0-hectorkit-lift.md` (DONE).
- **Replica target is 1.2.0** (Ben's ruling 2026-10-03, recorded by the RE lane in `docs/aki/INDEX.md`; all
  1.1↔1.2 deltas resolve to 1.2). Art therefore comes from the 1.2.0 PNGs (same native sizes as the 1.1 PICTs;
  `data-census.md` §3 maps them); the PICT path stays as oracle and for Bubble Trouble.
- **RE-bank lane COMPLETE (2026-10-03, head 01cb120):** `docs/aki/`, `docs/bubble-trouble/`, `docs/cythera/`,
  `docs/deimos/`, `docs/ferazel/` — each Opus-built, Fable-reviewed (all ACCEPT_WITH_FIXES), fix-passed;
  handoff `docs/handoff-2026-10-03-re-bank.md`; optional deepening = RESUME Trigger A2.
- **Deimos RE deepening, wave 1 landed (2026-10-03 night):** nine gameplay files in `docs/deimos/` (movement, spawn sets, weapons, damage, player, scoring, unit-def structs, bosses, level/scroll), Fable-reviewed ACCEPT_WITH_FIXES + fix-passed; role table 293→510 rows (240 HIGH / 256 MED / 14 LOW); INDEX closes #7 #17 #19 #20 #22 #24 #25 #26 #28. Wave 2 (sprite geometry, particles/RNG, timing, HUD, messages, loose ends, sound, front end) committed on branch `claude/modest-chandrasekhar-868895` c79d5e2 — synthesis/review/fix pass UNFINISHED (usage limit); see `docs/handoff-2026-10-03-deimos-re.md`.
- **Originals:** Aki 1.1.0 + 1.2.0 UB (symlinked as git-ignored `Resources/Aki/1.1.0.app`, `1.2.0.app`);
  Bubble Trouble X 1.1 UB; Ferazel's Wand 1.0.3, Deimos Rising 1.0.6, Cythera 1.0.4 (PEF).
  Archive map: `~/Developer/Ambrosia/docs/ARCHIVE-INDEX.md`.
- **Local-path dependency:** `Aki/Core` → `../../../HectorKit`; a worktree needs the untracked symlink
  `.claude/worktrees/HectorKit → ~/Developer/HectorKit` (Classics DECISIONS D1).

- **Aki Phase 1 DONE — Ben's verdict 2026-10-04: "yes it absolutely is Aki"** (splash + map gate passed). Plan
  `docs/plans/2026-10-03-aki-phases-1-3.md` (contracts not code). P1.2–P1.13 all reviewed MERGEABLE (Opus
  implementers, Opus/Fable reviews; fix round for P1.9/P1.10 at 5da2bf0); merged to main this session. AkiCore 31
  tests / 0 skips; `xcodegen generate && xcodebuild -scheme Aki build` BUILD SUCCEEDED; `tools/stage-aki.sh` →
  `out/Aki/Aki.app` (50 PNG + bundled `Fonts/OsakaMono.ttf`). HectorShell is the HectorKit session's (main
  5a33384+, floor 167 at the gate). Rulings this session: DECISIONS D4. Handoff `docs/handoff-2026-10-04-aki-phase1-done.md`.
- **Bubble Trouble X PLAYABLE WITH SOUND (2026-10-04/06, Opus 5.5 orchestrators, plan `docs/plans/2026-10-04-btx-playable.md`,
  DECISIONS D12/D13/D14):** every plan task merged and Opus-reviewed (T0, C1–C8, R1, A1–A4), then 2026-10-06: K3
  `ShellMixer` merged to HectorKit main d9fdfa4 (kit gate floor **222**, zero skips; C1 off-main-thread regression test
  proven to trap pre-fix), A5 wires it in (4 effect voices + music, silent fallback without a device), A6 effects at the
  Sound Tool's 0x80-unity law + `_StartMusic` carries on (sound audit `docs/bubble-trouble/sound-audit-2026-10-06.md`: all
  146 registered effect sites and music per level set match the original). Gates at Classics main (seat-run): core
  **258 / 0 / 0**; BubbleTroubleX + Aki BUILD SUCCEEDED, 0 warnings in our code; FILM replay traces 1–4 = baseline.
  Staged **~/Desktop/Bubble Trouble X.app** (Release, with sound) — Ben: "feels so close", speed right; he is playtesting
  "for a while"; unsure about music per set / missing effects (audit says both right; effects were half as loud — fixed
  in the restaged build). Prefs domain `com.ambrosiaclassics.bubbletroublex` holds his play since Oct 5 — never clear it.

- **Bubble Trouble X on Windows — PLAYABLE, STAGED FOR TESTING (2026-10-06, Opus 5.5 orchestrator; plan
  `docs/plans/2026-10-06-btx-windows.md` W0–W7 all done; DECISIONS D15/D16/D18/D19).** Cross-compiled on this Mac
  (`tools/windows/`, cache `~/Developer/Toolchains/windows-cross`), Mac app untouched. `BubbleTroubleX/Windows`:
  BTXWinKit (driver port, baked fonts, in-window menu bar + Carbon dialogs, prefs file under `%APPDATA%\Ambrosia
  Classics\Bubble Trouble X\`) + `BubbleTroubleXWin` on HectorKit `SDL/` (HectorSDL). Tests: Windows package 144/0/0;
  BTX core 261/0/0 on the Mac and 260/0/0 in CrossOver; HectorSDL 38/0; kit floor 252. **Staged:**
  `~/Desktop/Bubble Trouble X (Windows)/` + `.zip` (37 MB; `tools/windows/stage-btx.sh`; stamp 83febbe) — Ben sends it
  to his brother — **public link: GitHub pre-release `btx-windows-test-1` (repo now PUBLIC, D20)**; Ben heard it play with sound in CrossOver; fresh CrossOver bottle reaches the menu, level 1 and every dialog, dumps = the Mac SDL build. Never
  verified: a real PC's display/DPI/SmartScreen. **Automation: `HECTOR_SDL_AUDIO_DRIVER=dummy`
  (CrossOver strips `SDL_*`).** Next: the brother's report → fixes; then Aki on Windows.

## Open, ordered
- **Cythera RE wave 1 DONE (2026-10-04):** eight rules banks Fable-reviewed ACCEPT_WITH_FIXES (1 Critical/2 Major/6 Minor, all fixed) and merged; binary decompiled to 100 % of traceback-named functions (1,994 across three git-ignored dumps, `tools/missing-addrs.txt`); open: `docs/cythera/INDEX.md` NOT RESOLVED 5/6/10/16/21–25 — handoff `docs/handoff-2026-10-04-cythera-re.md`.

1. **Aki Phase 2 — DONE, Ben's gate PASSED 2026-10-04 (DECISIONS D9): "the game works fine"; pairs fade.** P2.1–P2.12
   as before (AkiCore 107 tests). Q24 fix 6603e55: `runFade` waits one full tick (1/60 s) after each of its two presents
   per frame (plan Q24 ⚑; ~22/60 s fade). Gates from main (seat-run): M1 **107 / 0**, M2 BUILD SUCCEEDED (0 our
   warnings), M3 floor **167**. Staged build on **~/Desktop/Aki.app** (+ WHAT-TO-EXPECT.md) — Ben plays that copy; never
   delete prefs domain `com.ambrosiaclassics.aki`. Handoff `docs/handoff-2026-10-04-aki-q24-gate.md`.
   **Aki on iPad + Remaster mode — both on main 2026-10-06** (Ben: iPad first, then Remaster). iPad (plan
   `docs/plans/2026-10-04-aki-ipad.md`, rulings D7; AkiPad target, Aki/App split shared/Mac/iOS) merged 5e6755d; no formal
   iPad gate is recorded in DECISIONS — Ben has been playing it on his iPad mini. **Remaster (D11, gate PASSED D17)** merged
   on top. Toggle: Aki ▸ Remastered Art (⌘G, works in fullscreen) + Preferences checkbox; Mac + iPad. Art: regenerate
   `Resources/Aki/hd-4x/` per worktree with `python3 tools/upscale-aki-art.py` (~2.5 min cold, Upscayl; then `--check`;
   207 MB, git-ignored) — without it Remastered Art shows disabled. Gates from main (seat-run): AkiCore **123/0/0**; Aki,
   AkiPad (sim), BubbleTroubleX BUILD SUCCEEDED, 0 our warnings; HectorKit floor **252**. Staged copies (~/Desktop/Aki.app,
   Ben's mini) are the 2026-10-06 Remaster builds. **Next: Aki Phase 3** (editor, `.aki`).
2. **Bubble Trouble X — Ben's play gate (sound is in):** take his playtest verdicts; then the rest of his gates: "plays like Bubble Trouble X", plan Questions Q1–Q18, NR-10 (watch the ORIGINAL's demo 4: hero caught ~15 s in? yes → goldens freeze, core Task 11.5), FILM 1 flag. Carried minors: core `musicPlaying` flag vs channel status (D14.5); deactivation during a carried-over pause; an event during the very first wipe acts one frame early; app activate/deactivate during dialogs (docs/bubble-trouble/review-carries-2026-10-04.md).
3. RE deepening chains (Deimos wave 2 fix pass landed; Cythera wave 1 review owed) — separate chips.
4. **Windows port** (Ben 2026-10-06) — BTX staged for his brother (above); await his report.
5. Phase 3 Aki, then Bubble Trouble X shell on HectorShell (design §6). EV's adoption of HectorKit: separate task.

## Carried (not blockers)

- Design doc §4 says 70 QuickTime / 12 raw PICTs; the data says 71 / 11 (PICT 135 is 32-bit cmpCount 4 — a
  real alpha plane). Fix the design doc when it is next edited.
- HectorKit carries EV-engine arithmetic in `SndSound` (`loadSoundsTicks`, `playbackDurationFrames`) by the
  "rename prefixes only" rule; trim only with a ruling. Only data-gated tests cover `snd` format 1.
- `quickTimeBands` returns a tuple, not a struct (API polish for v0.2). No dimension cap on codec images.
- Ambrosia's 1996 installer format unreversed. HD-art packs late polish. Licence at the very end (EV D65).
- **Aki, for Ben's HectorKit session:** (a) `ShellSoundBank.start` on a track at its end replays from 0; QuickTime left
  `IsMovieDone` true for `_LoopMusic` — Phase-2 effect only (theme alternation window); (b) quitting from fullscreen:
  `exitFullscreen()` re-shows the windowed window, so `windowDidBecomeMain` → `unpause` fires at quit — the original's
  deferred step never ran; HectorShell needs an exit that only orders out (P1.12 review Minor 1); (c)
  `ShellFullscreenWindow.canBecomeMain` true where the original allowed key only (no visible effect yet).
- **Aki carried from Phase 1 reviews (not blockers):** Release Notes — Ben wants the replica's own notes at the very
  end (with the licence); ASWAboutBox/ASWTextViewer-faithful windows after P3 (Q10); the Carbon dialog centres on the
  MAIN display, not the game window's display (as the Carbon code did — Q6, multi-display);  one `fullscreen` accessor (ivar vs `shell.isFullscreen`); the Osaka-Mono guard's Menlo branch is only provable offline on this Mac
  (the font is now installed system-wide); bundling Apple's font is for Ben's machine only (licence).
- **Ferazel RE deepening (2026-10-03, CLOSED 2026-10-04):** 11 Opus readers + 2 gap readers wrote 17 new `docs/ferazel/` files (~6,400 lines: enemies ×3, bosses ×2, enemy-shots-and-damage, pickups-boxes, triggers-background ×2, spells-detail, save-continue, platforms-ropes-radial, player-states ×2, geysers, held-item-melee, coverage, physics-sprites); three Fable review legs all ACCEPT_WITH_FIXES (1a 0/4/6, 1b 1 Critical/3/9, 1c 0/4/11; `REVIEW-2026-10-03-deepening.md`); fix passes 1a/1b landed; consolidated fix pass landed (`FIXPASS-2026-10-03-deepening.md`; labels HIGH 727 / MED 228 / LOW 27); merged to main at 5b15177. Fable spot-review 1d of the fix-pass diff (2026-10-04): ACCEPT_WITH_FIXES, 0 Critical / 0 Important / 6 Minor, 66/66 markers + 76 raw addresses confirmed; fixes + the held-item-melee carries (rows 3, 4, 6–8) landed at 02f29cc. Worktree and branch `recursing-rhodes-932ac0` removed. Still open in the bank: INDEX NOT-RESOLVED items 15–29 (`+0xb8` draw modes, tint/remap colours, NewParticle args, Xichra cannons, OmniPx/PxMid, Mcnv item 3, lighting item 10, Titles item 12). Nothing needs Ben's play check. Handoff `docs/handoff-2026-10-03-ferazel-re.md`.
