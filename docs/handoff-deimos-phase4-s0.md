# Handoff — Deimos Rising Phase 4, section S0: the OS X build on file; bank corrections (2026-11-20)

Seat: Claude Opus 5.5 (S0 is tagged for an Opus seat). Docs and Ghidra outputs only; no Swift, no test, no build changed,
so G1–G5 and G8 are untouched (G2 stays at main's count, 372).

## What is on main

| Task | Commits | What |
|---|---|---|
| OX | 622c917, 029edbc | The OS X build ("Deimos Rising.OSX", data-fork offset 0xf67c0, 1,035,460 bytes) extracted and disassembled headless; committed under `ghidra/deimos/` |
| CMP | 39266f4, e78b267 | `docs/deimos/osx-build.md`: the front end, OS 9 build (L) against OS X build (X) |
| BK | f968990 | Bank corrections (grounding A §11, B §9, C §8, the plan handoff's list); INDEX #14 and #62 closed |

Reviews: OX and CMP each had one implementer and two Opus review legs (spec, then quality) and one fix round. The CMP
legs re-derived six rows between them from the listings (D1, D4, D5, D6, D7/D9, D11, D12/D13) and agreed with all of
them. The seat checked the OX fix round itself: a fresh re-run left the tree clean and the listing unchanged. BK was
run by the seat, as the plan says, and every note cites its address.

## The OS X build on file (for every later task that cites "X 1xxxxxxx")

- `ghidra/deimos/Deimos_osx_pef`: the fragment.
- `Deimos_osx.disasm.txt`: the listing, 235,769 lines.
- `Deimos_osx.functions.txt`: 2,676 functions, with Ghidra's body size and the span to the next entry. Body sizes
  undercount where there are switch tables, because the installed Ghidra has no decompiler, so compare spans.
- `Deimos_osx.data.txt`: every data word with its offset from r2, which resolves TOC loads (r2 = 100eba10).
- `analyze-Deimos_osx.log`: the Ghidra log, cleaned of timings and home paths.
- Recipe: `bash ghidra/regen-deimos-osx.sh` (about 15 s). It is idempotent and leaves the tree clean. Its working copy
  is in `~/Developer/Ghidra/deimos/` (project `proj-osx/`). Notes are in `ghidra/README.md`.
- There is no C for X, only the listing. The OS 9 listing the bank cites is still only at
  `~/Developer/Ghidra/deimos/proj/disasm-review3-all.txt`, outside git (see follow-ups).

## What the comparison found: 14 differences change what Phase 4 builds

Each screen task reads `docs/deimos/osx-build.md` §3 first, under ruling 5 (follow X). In short:

1. **Menu fades run twice as fast.** The element fades take 16 passes, not 32, so the dead time on starting a game is
   about 58 ticks, not 74 (D1).
2. **The configuration window greys different items.** X greys Bypass System Volume and the sound slider; Full Screen
   stays live. X also sets no Geneva 9 font (D2, D3).
3. **Set Controls… opens the game's own controls window,** not Apple's panel (D4).
4. **Set Gamepad Controls… is always shown in X,** because X quits at start-up with an "Input Error" alert when its
   gamepad layer is missing (D5).
5. **Full Screen works (ruling 13 answered).** Unticked, the next launch runs in a 640×480 window; ticked, full
   screen (D6). The window size is MED.
6. **The menu bar differs.** It is built once. The app menu has Preferences…, which opens the configuration window.
   There is no File menu, Edit is greyed, and About is never greyed (D7, D8, D9).
7. **App switching and Quit.** The pause and the level select listen for app switches and Quit. Leaving the app
   pauses the game, with the pause sound. Quit from the Dock in the level select waits until a sector is chosen
   (D10, D11; the level-select race is MED).
8. **The cursor shows while paused in a game and stays visible during films,** until an app switch hides it (D12,
   D13; the film case is MED).
9. **Coming back to the app does not redraw the screen at once** (D15).

D16–D24 are plumbing (event waiting, Carbon accessors, the input layer), marked "no change" for what the player sees.
Boot, scores, name entry, credits, demo choice, film record and save, screen fades, the level-select drawing and the
prefs functions are the same in both builds, apart from shifted addresses.

## Where the plan and the appendices are wrong for X (the Coordinator decides; S0 changed none of them)

- **Ruling 12** says About is greyed during a game and gives no Preferences item. In X, About is never greyed and
  Preferences… is in the app menu (D7–D9).
- **Ruling 17** gives a different reason for hiding "Set Gamepad Controls…". X shows it always, because X will not
  run without its gamepad layer (D5).
- **Grounding A §5.2 and B §1a fade timings:** X runs 16 passes, so the dead time is about 58 ticks, not 74 (D1).
- **A §5.3 (the pause) and B §1a step 2 / B §1b step 11** (the menu bar and the cursor): X differs (D7, D12).
- **Grounding C §1b:** X's prefs write is at 10004640, not 10005150.

These matter first to S2 (menu, credits, fades), S6 (boot, the configuration window), S7 (the controls window) and
S8a (the app's menu bar, app switching, the cursor).

## Not done here (outside S0's files)

- **Two Swift comments** call the key-slot meanings LOW, and they are HIGH: `DeimosPrefs.swift:15` and
  `KeyTable.swift:8` (handoff list item 4; grounding C §3b). Whichever section next owns those files should fix them.
- **The remainder plan's stand-in 4** (level-1 music) is the original's own "no music playing" branch (handoff list
  item 3). The Phase 4 plan's corrections section already says so; the remainder plan itself was not edited.
- **The regen script sits at `ghidra/regen-deimos-osx.sh`,** beside the other games' regen scripts, which is one path
  outside the plan's S0 list (`ghidra/deimos/**`, `ghidra/README.md`).

## Follow-ups (not Phase 4)

- **The whole-game comparison of the two builds** (Ben's question 1). The files above make it possible.
- **The OS 9 listing is not committed.** The house rule says it should be under `ghidra/deimos/`.
- **The README and the other regen scripts still name Ghidra 12.1.3,** which is no longer installed (12.2 is):
  `ghidra/README.md` Tool section, `regen-ferazel.sh`, `regen-cythera.sh`, `decompile.sh`.
- **Committed Ghidra logs for the other games** (and the OS 9 Deimos log) carry `/Users/…` paths, and the repo is
  public.
- **Two small notes from the CMP review:** pausing flushes events, and it is unsettled whether that drops a waiting
  suspend event (LOW). Activate events can pause the game in windowed mode (LOW).
