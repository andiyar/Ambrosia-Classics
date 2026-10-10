# STATE — Ambrosia Classics — 2026-10-10 (Cythera Phase 0 K1–C5 done; Deimos gate 1 passed; Ferazel Phase 0 done, Phase 1 machine-complete (102/0), staged, Ben's Phase 1 gate pending; Aki 1.0 released; Bubble Trouble X 1.0 released, Mac + Windows)

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
- **Deimos RE deepening CLOSED (2026-10-06):** waves 1–4 on main — 100 % of game code read (0 unread by census). Wave 3+4 fix pass (`docs/deimos/FIXPASS-wave3-2026-10-06.md`: review I1/M1–M7, critic C1–C9, stale NRs, label audit; one reversal seat-verified) + critic §6 micro-wave (`docs/deimos/micro-wave-2026-10-06.md`, every claim spot-checked HIGH) folded in: role table **938 rows = 716 HIGH / 222 MED / 0 LOW**; INDEX #40 #47 #48 #54 #58 #60 closed, #62–#64 new. Still open: #13, #59 residue, #62–#64, the 134 cross-file HIGH/MED label mismatches (critic), Ben's ear/eye items (handoff 2026-10-04-deimos-re-wave34 "Owed by Ben").
- **Deimos Rising build (D27, Ben 2026-10-06): design + Phase 1 plan written** on branch `deimos-phase1` (5106149, unreviewed, not executed) — Phase 1 = gate 1 "level 1 look". Handoff `docs/handoff-2026-10-06-deimos-phase1.md`.
- **Deimos Rising Phase 0 DONE (2026-10-06, on main; plan `docs/plans/2026-10-06-deimos-phase0-data.md`,
  DECISIONS D22/D24):** original data in git (`Resources/Deimos/Data` four paks + Local film; app fork as
  `Resources/Deimos/Deimos Rising.rsrc`); HectorKit `StoredZipArchive`/`AIFFAudio`/`WAVEAudio`/`SoundFile` + PICT 0x009B
  (main `33d4dee`, floor 301); `Deimos/Core` 104/0/0; `deimos-census` 872 entries decoded, 0 failures, PICT 12/12,
  DITL 6/6 (`docs/deimos/data-census.md`). **Phase 1 (the build plan) needs:** the game's continuous-IMA effect decode +
  16-voice/8-audible mixer, music streamed from the pak range, the glyph map over `tesm`, the MED colour rules (plan
  notes 15/21). **Ben's eyes:** INDEX #10 — `deimos-census --render out/deimos-render`, is `menu.png` upright?
- **Deimos Rising Phase 1 — level 1 look: GATE 1 PASSED (Ben, 2026-10-07: "it looks okay!"; D30 — runs at OS X's
  60 Hz tick, Ben played on OS X) (2026-10-07, Opus 5.5 orchestrator,
  Opus implementers / Fable reviewers; plan `docs/plans/2026-10-06-deimos-phase1.md` + review record `…-phase1-REVIEW.md`;
  DECISIONS D29 + as-built addendum):** K1 `ShellView.scalingPolicy` on HectorKit main 522feb8 (HK D13, floor **316**);
  `Deimos/Core` grew DeimosRender + DeimosHost — suite **189/0/0** (plan ladder 177 + 13 from three review fix passes − 1
  KeyTable moved to Core); census unchanged; Deimos + Aki + BubbleTroubleX BUILD SUCCEEDED. Every task Fable-reviewed
  (MAJOR tasks two legs); one Critical found and fixed (held Esc hung the driver). Frame goldens independently re-derived
  in Python. Staged **~/Desktop/Deimos Rising.app** + WHAT-TO-EXPECT (gate card). Q1 ruled 60 Hz (D30), restaged.
  Next: the Phase 2 plan (level 1 plays; de01 film replay gate). Carries for Phase 2: `DeimosAudio`
  target (design M6), `playerOps` return type, `HeadlessRun` film params, Phase-4 prefs file widening (C1 review m3).
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
- **Bubble Trouble X 1.0 — RELEASED 2026-10-06 (Ben tried the downloaded DMG, said "publish"; DECISIONS D25):** GitHub release `btx-1.0`
  (tag on 47d7c98) carries `BubbleTroubleX-1.0.dmg` (12.6 MB, Developer ID + notarized + stapled, universal, built by
  `tools/package-btx-release.sh`) and `BubbleTroubleX-1.0-Windows.zip` (36.9 MB, stamp 6832da1, unsigned) + .sha256s;
  README + `docs/release/btx-1.0.md`. Next releases: bump `CFBundleVersion` in BubbleTroubleX/App/Info.plist, then
  `tools/package-btx-release.sh --version X.Y --sign "Developer ID Application: Benjamin Thomas (5W72UJL332)" --notarize oniarm64-notarize`.
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
  `docs/plans/2026-10-06-btx-windows.md` W0–W7 all done; DECISIONS D15/D16/D18/D19/D21).** Cross-compiled on this Mac
  (`tools/windows/`, cache `~/Developer/Toolchains/windows-cross`), Mac app untouched. `BubbleTroubleX/Windows`:
  BTXWinKit (driver port, baked fonts, in-window Carbon dialogs, prefs file under `%APPDATA%\Ambrosia
  Classics\Bubble Trouble X\`) + `BubbleTroubleXWin` on HectorKit `SDL/` (HectorSDL). Tests: Windows package 113/0/0;
  BTX core 261/0/0 on the Mac and 260/0/0 in CrossOver; HectorSDL 38/0; kit floor 252. **Staged:**
  `~/Desktop/Bubble Trouble X (Windows)/` + `.zip` (37 MB; `tools/windows/stage-btx.sh`; stamp 83febbe) — Ben sends it
  to his brother — **public link: GitHub pre-release `btx-windows-test-1` (repo now PUBLIC, D20)**; Ben heard it play with sound in CrossOver; fresh CrossOver bottle reaches the menu, level 1 and every dialog, dumps = the Mac SDL build. **Real PC verified 2026-10-06 by Ben's brother** (played to level 20, high-score entry, idle attract demo all work). Sound fine on the real PC (Ben, 2026-10-06). Esc ends the game with no "are you sure?" — original behaviour, kept. **Automation: `HECTOR_SDL_AUDIO_DRIVER=dummy`
  (CrossOver strips `SDL_*`).** **D21 (Ben): no menu bar — game-only 640×480 window (2× on 1080p), Ctrl shortcuts kept, About gone; merged f482270, restaged and the release asset replaced in place.** Next: any fixes from the brother's play; then Aki on Windows.

- **Ferazel's Wand — DESIGNED AND PLANNED (2026-10-06, Fable orchestrator; DECISIONS D26):** Ben's brainstorm rulings
  (whole game + Windows; first gate = level 1 look-and-feel; front end early; 640×480 integer scale; longplays + his
  Let's Play link as the feel oracle). Design `docs/plans/2026-10-06-ferazel-design.md` (APPROVED); plan
  `docs/plans/2026-10-06-ferazel-phase1.md` (Phases 0 + 1, 15 tasks K1/C0–C6/R1–R6/A1–A2, 7+1 ⚑ MAJOR; Opus planner,
  Fable review ACCEPT_WITH_FIXES 3 Important / 12 Minor, all applied; ladder Ferazel/Core 6 → 100 tests, HectorKit floor
  289 → 301). Planner probes found two bank gaps now in the plan's "Bank corrections": face pixels go through
  Color2Index at load (sheets carry their own palettes) and 326 PICTs are 32-bit `ditherCopy` — both LOW, both on the
  gate card. **Phase 0 K1 + C0 + C1 DONE (2026-10-06, Opus orchestrator):** HectorKit `PICT.decodePixels` (indices + public 16-bit `ColorTable`, v1 BitMaps, DirectBits RGB + mode; HK D12; HK main d38a541, **floor 313** — the plan said 301, Deimos had already added 12); data in git `Resources/Ferazel/` (6 `.rsrc` + 28 AIFC, `cmp`-identical; D26 as-built); `Ferazel/Core` package + `FerazelData`/`FerazelResources`/`ResourceChain`, **6/0** tests. **C2–C5 DONE (2026-10-07, Opus orchestrator; two Opus review legs per MAJOR):** world parsers
  (Mlvl/Mwld/Mmap/Mcnv/STR#, placements, sprite class table) · ColorLUT / SoundBank / MusicTrack · TableRequests +
  ColorSearch (`.ruled` default, `Prepared` fast path) + the Color2Index measurement · faces (PICT → indices, ditherCopy
  model, 1-bit bypass, EncodeRect RLE, face/plain/water/blend sheets, tile sets); ladder 6 → 21 → 28 → 43 → **56/0**.
  **Ben 2026-10-07: follow the binary** where plan/bank disagree with the PPC code — C4 water 1 / glow 014c / grey-pull
  0144 keep the original's 32-bit overflow (Color2Index all-sixteen 1,178,146, not the plan's 1,178,143); C5 FG/FG-water
  convert under the level CLUT (201 on L1), fixed sets 183/185 under clut 199 (D26 as-built C4 + C5; bank ⚑ Corrections in
  lighting-tables and sprites-backgrounds-sounds). HectorKit untouched (main 522feb8, floor 316 — Deimos's
  `ShellView.scalingPolicy` `.integerFit` is there; Ferazel A1 reuses it).
  **C6 + R1 DONE (2026-10-07, Opus orchestrator; Opus-only legs):** `ferazel-census` + `docs/ferazel/data-census.md`
  (1,108 items, 0 failures; **Phase 0 complete**) → **60/0**; R1 LOCKED seams (+ case `redrawEntireScrollGrid`), prefs,
  LevelTables, ports, strip-incremental `.RedrawScrollGrid` into port 0004 (follow the binary; blend cells 1,560) → **69/0**.
  **Ben 2026-10-07:** the duplicate-black tie-break (FG black → index 1 = light yellow under clut 202) is decided at the
  Phase 1 gate — build lowest and highest selectable (D26). HectorKit untouched (main 4ca2e18 after Cythera K1).
  **R2 + R3 DONE (2026-10-09, Opus orchestrator; Opus-only legs):** darkness on tiles inside `.RedrawScrollGrid`
  (`LightAny*Tile`, Effects ≠ 3), light faces, `.DrawLightsOntoTiles` → **74/0**; parallax as written
  (`.DoubleBlitPPCParallaxOneLayer`, ring split, row state machine) + `PxSprites` (N + 1 copies, follow the binary) →
  **81/0**; Fire (52/55) and ripple (11/18) levels refused by name (D26 as-built R2 + R3).
  **R4 DONE (2026-10-09, Opus orchestrator; two Opus legs + re-review):** placed sprites in their Setup faces (42
  level-1 types), active list, idle activation (13 at the start window), `.WrapDrawSprites` + `.WrapEraseSprites` +
  sprite light pass → **88/0**; level-1 Setups add 68 lights (exposed, not wired; R2's premise wrong); mode 0xb refused,
  table 0148 still unbuilt (D26 as-built R4). **R5 DONE (2026-10-10, Opus orchestrator; one Opus leg + fix round):** `FerazelSession.step` in `.GameLoop` /
  `.PaintFrameWrap` order, `Camera` = `.FindUpperLeftCorner`, Phase-1 pose + focus stubs, `DrawOp.wrapEraseSprites`.
  Following the binary: level 1 opens at scroll **(0, 0)** and pans in (not the plan's (0, 10)), and a skipped
  reduced-frame-rate iteration drops only the screen copy (D26 as-built R5). **94/0**. **R6 DONE (2026-10-10):**
  status bar (magic bar at x 419 per the binary, not 214), Game Screen frame, FrameRenderer (68 Setup lights wired),
  CLUT → RGBA, level-1 goldens (D26 as-built R6). **100/0, Phase 1 core complete.** **A1 DONE (2026-10-10, two Opus
  legs + fix round):** `Ferazel's Wand` app on HectorShell (whole-number window scale, 240 Hz timer / 2-tick step clock
  per `.GameLoop`, arrows + keypad, looped music via `.SetAIFFMusic` rules, CoreText status text, icon from `icl8` 128),
  project.yml target via the `Ferazel/FerazelCore` symlink; duplicate-black tie-break built (hidden `ColorTieBreak`
  default, Ben's ruling) (D26 as-built A1). **102/0**; all four app schemes build. Ben saw level 1 and heard the music.
  Let's Play = https://www.youtube.com/watch?v=ESuyxMUEzDw (design §2, Ben 2026-10-10). At 02:12 its level-1 FG rock edges
  show no yellow specks, so **Ben ruled the app tie-break default `highest`** (`ColorTieBreak lowest` selects the other).
  **A2 DONE (2026-10-10, one Opus leg MERGEABLE + two fix rounds):** `tools/stage-ferazel.sh` (Release, data into
  `Contents/Resources/Ferazel/`, ad-hoc sign, build stamp in the staged notes, Icon Composer previews) and
  `Ferazel/WHAT-TO-EXPECT.md` with the corrected 16-line gate card (D26 as-built A2). Staged `out/Ferazel/` + `~/Desktop/Ferazel's Wand.app`.
  Machine gates green; **STOP: Ben's Phase 1 gate pending ("does it look like Ferazel")** + his icon pick.
  **Colour MEASURED against the Let's Play (2026-10-10, Opus leg; `docs/ferazel/colour-measurement-2026-10-10.md`):** 7 level-1
  frames, 48 combos each. Tie-break `highest`, error-diffusion dither and Effects 1 match. `.exactNearest` beats `.ruled` in 7/7 frames, so **Ben
  ruled the app default model `.exactNearest`** (applied; G2 102/0, Ferazel builds). The video is about γ 0.76 brighter (classic Mac display gamma):
  Ben wants a hidden toggle, off by default (unbuilt). Open: the potion light (light 24) over-lights the table sprite.

## Open, ordered
- **Cythera RE wave 1 DONE (2026-10-04):** eight rules banks Fable-reviewed ACCEPT_WITH_FIXES (1 Critical/2 Major/6 Minor, all fixed) and merged; binary decompiled to 100 % of traceback-named functions (1,994 across three git-ignored dumps, `tools/missing-addrs.txt`); open: `docs/cythera/INDEX.md` NOT RESOLVED 5/6/10/16/21–25 — handoff `docs/handoff-2026-10-04-cythera-re.md`.
- **Cythera RE wave 2 DONE (2026-10-06, Opus 5.5 seat):** all 840 newly decompiled bodies read or identified into `docs/cythera/` (census + six new banks: ui-play, dialogue-ui, scripted-windows, app-shell, ui-toolkit, open-items-2026-10-06; appends to ten banks; the 95 builtins now carry their real names). Review ACCEPT_WITH_FIXES (0 Critical/3 Major/13 Minor, 82/84 claims pass; ran on Opus 5.5, so a Fable revision pass is owed), all fixed. NOT RESOLVED 5/6/10/14/19/21–25 closed (22: wave 1 had the ending branch inverted — crystal quality 1 = saved ending); still open: `Render__7TViewer` layer order (16) and small carried sub-points — handoff `docs/handoff-2026-10-06-cythera-re.md`.
- **Cythera RE wave 3 DONE (2026-10-06, Opus 5.5 seat, Fable reviewer):** `docs/cythera/render.md` closes NOT RESOLVED 16 (draw order ground → passes 0/1/3 by tile flag → creatures → missiles → pass 5 → backdrops → roofs → filter/lighting; pass 2 never draws); open-items recipes banked as six tools. **Fable revision review** over wave 2 + 3: ACCEPT_WITH_FIXES (0 Critical/1 Major/11 Minor; 113/116 claims pass; every wave-2 closure and both wave-1 overturns hold), all 12 fixed. Still open (small): THood order within a pass, QTMA music events, over-encumbrance, 0x03/0x05 words, 0x0210 — handoff `docs/handoff-2026-10-06-cythera-re-wave3.md`.
- **Cythera — DESIGNED AND PLANNED (2026-10-06, Opus 5.5 orchestrator; DECISIONS D28):** whole game Mac + Windows;
  first gate = walking Catamarca; screen like the original (backdrop + floating game windows, 1 px = 1 pt); saves in the
  original format; cheats + Documentation viewer IN; music via Apple's GM synth (recorded for Windows). Design
  `docs/plans/2026-10-06-cythera-design.md` (APPROVED); Phase 0 plan `docs/plans/2026-10-06-cythera-phase0.md` (Fable
  planner, 14 tasks K1/C0–C12, ladder Cythera/Core → 84 tests, HK floor 313 → 319, census `failures 0`). **Nothing
  built.** Next: Phase 0 (chip issued).
  **Phase 0 tranche 1 DONE (2026-10-07, Opus 5.5 orchestrator, all-Opus implementers + reviewers): K1 + C0 + C1 + C2.**
  K1 on HectorKit main **4ca2e18** (HK D14; `decodePixels` takes 0x0099/0x009B regions as `maskRegion` + 16-bit DirectBits;
  direct modes {0, 36, 64} as stored — plan's "mode 64" was wrong; floor **322**, plan said 319 from a stale 313 base).
  Classics: `Resources/Cythera/` 20 files (D28 as-built), `Cythera/Core` CytheraData/CytheraResources + SegmentFile/
  Cipher/Overlay, suite **14/0/0** (ladder on track). Handoff `docs/handoff-2026-10-07-cythera-phase0-t1.md`.
  **Tranche 2 DONE (2026-10-07, same model policy): C3 LZ + C4 World records + C5 CytheraRender pixels** → suite
  **44/0/0** (ladder exact); HectorKit untouched (4ca2e18, floor 322). C4 STOPPED once (Invariant 10): plan had map
  0x8002 chunk 0 and the 0xF001 tail wrong — seat re-measured and ruled (D28 as-built tranche 2; plan "Tranche 2
  corrections"). Next: C8 ⚑ → C9 ⚑ (script decoder + parity), then wave C (C6, C7 ⚑, C10) — chip. Handoff
  `docs/handoff-2026-10-07-cythera-phase0-t2.md`.

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
   Ben's mini) are the 2026-10-06 Remaster builds.
   **Aki 1.0 RELEASED 2026-10-06 (D23)** — public GitHub release `aki-1.0` (tag on b5dd97a, HectorKit 0467025):
   https://github.com/andiyar/Ambrosia-Classics/releases/tag/aki-1.0 — `Aki-1.0.dmg` 242 MB, sha256 `bd12e9d4…a6b5`,
   Developer ID + notarized + stapled (app and DMG), universal, Remaster art in, no Osaka-Mono, About "1.2.0 (1.0)", new
   macOS 26+ icon (`Aki/App/Mac/AppIcon.icon`, green felt). Next releases: `tools/package-aki-release.sh --version X.Y
   --sign "Developer ID Application: Benjamin Thomas (5W72UJL332)" --notarize oniarm64-notarize` (bump `CFBundleVersion`
   in `Aki/App/Mac/Info.plist` first; the script asserts it). Ben verified the notarized DMG 2026-10-06: sound, music, ⌘G all work. Untested: Intel, macOS 15/26. **Next: Aki Phase 3** (editor, `.aki`).
2. **Bubble Trouble X — Ben's play gate (sound is in):** Ben 2026-10-06 played 3 levels: sound + music right, Q1/Q3/Q4/Q5/Q8/Q12/Q16/Q18 + text all yes (D14 addendum); NR-10 waived ("who cares about demos?"). Still open: his longer playtest; Q2 cheat memories, Q9/Q13/Q15 if he notices anything. Carried minors: core `musicPlaying` flag vs channel status (D14.5); deactivation during a carried-over pause; an event during the very first wipe acts one frame early; app activate/deactivate during dialogs (docs/bubble-trouble/review-carries-2026-10-04.md).
3. RE chains: Deimos CLOSED; Ferazel wave 2 CLOSED (build planning session running 2026-10-06); Cythera waves 2–3 DONE 2026-10-06 (Fable revision pass + Render layer order landed), only small sub-points remain. Deimos Phase 0 on branch `deimos-phase0` (HectorKit v0.3.0 format layer landed; DeimosCore census in progress, unmerged).
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
- **Ferazel RE wave 2 (2026-10-04, CLOSED 2026-10-06, Fable orchestrator, cap waived by Ben):** Ben's "decompiled to 100 %" wave — ten Opus reader lanes wrote 11 new `docs/ferazel/` files (lighting-tables, draw-effects, particles, rendering-omnipx-titles, conversations-mcnv, bosses-3, enemies-ground-2, spells-detail-2, platforms-ropes-radial-2, enemy-shots-and-damage-2, pickups-boxes-2) + 17 in-place edits; eight Fable review legs A–H (`REVIEW-2026-10-04-wave2.md`; leg C 2 Critical: water-tint loops `ble` so entry 0xff is written → black, mode 0xa is a vertical squash) + spot-review 2i (0 C / 0 I / 5 M, all landed); two fix rounds + INDEX/coverage synthesis (`FIXPASS-2026-10-04-wave2.md`; 110 review markers, 100 corrections markers; labels HIGH 1100 / MED 291 / LOW 41; coverage 141/1/12). INDEX NOT-RESOLVED 2–29: all closed, UNDETERMINABLE with evidence, or narrowed; **still genuinely open:** palette-index choice of Color Manager `Color2Index` (LOW on every "→ idx"), geysers NR 2–4, follower slot-reuse frequency and whether enemy drops give items 8/21, the nil level-handle outcome in ContinueGame, and intent-only questions (music 21/27, vestigial boss fields, 2940 p1 = 0, tile oddities). Merged to main `--no-ff`. Nothing needs Ben's play check. Worktree `ferazel-wave2` still locked by the Oct-4 session (pid 42564) — remove it and the branch when that session closes.
- **Ferazel RE deepening (2026-10-03, CLOSED 2026-10-04):** 11 Opus readers + 2 gap readers wrote 17 new `docs/ferazel/` files (~6,400 lines: enemies ×3, bosses ×2, enemy-shots-and-damage, pickups-boxes, triggers-background ×2, spells-detail, save-continue, platforms-ropes-radial, player-states ×2, geysers, held-item-melee, coverage, physics-sprites); three Fable review legs all ACCEPT_WITH_FIXES (1a 0/4/6, 1b 1 Critical/3/9, 1c 0/4/11; `REVIEW-2026-10-03-deepening.md`); fix passes 1a/1b landed; consolidated fix pass landed (`FIXPASS-2026-10-03-deepening.md`; labels HIGH 727 / MED 228 / LOW 27); merged to main at 5b15177. Fable spot-review 1d of the fix-pass diff (2026-10-04): ACCEPT_WITH_FIXES, 0 Critical / 0 Important / 6 Minor, 66/66 markers + 76 raw addresses confirmed; fixes + the held-item-melee carries (rows 3, 4, 6–8) landed at 02f29cc. Worktree and branch `recursing-rhodes-932ac0` removed. Still open in the bank: INDEX NOT-RESOLVED items 15–29 (`+0xb8` draw modes, tint/remap colours, NewParticle args, Xichra cannons, OmniPx/PxMid, Mcnv item 3, lighting item 10, Titles item 12). Nothing needs Ben's play check. Handoff `docs/handoff-2026-10-03-ferazel-re.md`.
