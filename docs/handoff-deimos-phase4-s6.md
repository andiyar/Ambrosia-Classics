# Handoff — Deimos Rising Phase 4, section S6: boot; the configuration window (closed 2026-11-20)

Seat: Claude Fable 5.2. Helpers: Opus 5.5 (`fk-implementer`, `fk-reviewer`), foreground. Section S6 of
`docs/superpowers/plans/2026-11-20-deimos-phase4.md` is done and on main. **S7 may start.**

## What a player would notice
Nothing yet: the app still uses the direct start until S8a wires the front end in. Underneath, starting the front
end now runs the original's start-up (loading screen, the two logos, the fades) and the settings window exists,
drawn by the game itself in the classic grey Mac look.

## What landed

| Commit | What |
|---|---|
| `b74e8bc`, `51d654f` | BT: the boot, and its fix round |
| `8c81688`, `12722dd` | DG: the configuration window; Apple's real Geneva 9 bitmap font |
| `63a8e56`, `a7c32c4`, `d2d0a0f` | DG fix rounds: music level re-applied, the shared window code lifted out for S7, key hand-back, slider thumb, Revert timing, flush |
| `d6efbca`, `f88ca2f`, `d085d83` | older tests' set-up reaches the menu through the real boot (see "Outside the file list") |

Reviews: BT one implementer, two Opus legs (spec, quality), one fix round. DG one implementer, two Opus legs, fix
rounds, and one Opus re-review leg over every fix round up to `a7c32c4` plus the older-test changes (MERGEABLE).
**The last commit, `d2d0a0f`, had no review leg of its own** (the seat reached its cap); the seat re-ran the gates
over it. The seat's cross-check: gates re-run from the merged head, the scope audit, and the window's picture read
by eye.

## Gates, measured by the seat at the merged head (S5 and S3b merged in)

| Gate | Result |
|---|---|
| G2 `Deimos/Core` without the replay and campaign bundles | **454 / 0 / 0** (main 441 + BT 4 + DG 9) |
| G4 `DeimosReplayTests`; `deimos-replay --all` | **4 / 0**; four PASS lines, exit 0 |
| G5 Deimos Debug and Release, Aki, BubbleTroubleX | all four `** BUILD SUCCEEDED **` |
| G12 the direct start | passes (inside G2) |
| G3 census, G7 layering, G10 clean tree | empty diff; prints nothing; clean |
| G6 scope | inside the fence, plus four older test files (below) |
| G1, G8 | not run (no kit change; G8 is not due at S6) |

**G2 base for the next sections: 454.**

## The boot (`FrontEnd/Boot.swift`)
- With fresh settings the menu is up on the **sixth** front-end pass (the configuration window is called inside
  pass 1 when settings byte 2 is 0 or Option is held, always with `firstLaunch: true`, X 10000214).
- Loading lines: 21 sound lines (three of the 24 ids are "none"), 386 units, 5 weapons, 2 players: 432 loading
  updates with sound, 412 without. "Unpacking Unit:  " has two spaces. The closing fade is 16 passes (X).
- The publisher logo holds until its sound ends, with no time limit (ruling 15). **For S8a:** a host whose mixer
  never ends that voice (a muted launch, a headless mixer) would hold there for ever; the gate-9 muted launch must
  still run the voice to its end. Nothing shows the cursor at boot for the settings window either: S8a.
- `Resources/Deimos/Deimos Rising.rsrc` is copied into the app at `Contents/Resources/Deimos/Deimos Rising.rsrc`
  by a `project.yml` build step; `tools/stage-deimos.sh` refuses to stage without it. **Nothing fills
  `FrontEndState.shellResources` yet: S8a reads that file and hands its resources in** (`DialogResources.readFork`
  gives them by type and id).

## The configuration window (`FrontEnd/ConfigDialog.swift`)
- Twenty items from DITL 190; each item's setting, Defaults (resets bytes 4–8, ints 0–2 and both key sets; leaves
  bytes 9–11), Revert (grey until a change), Cancel (restores everything, keys included; absent on a first launch),
  Save. Greying follows the OS X build (Bypass System Volume and the sound slider). Finishes `true` after Save.
- The music level is re-sent (`MusicCue.level`) on slider release, Revert and close, not on Defaults (X 10048c20).
- "Set Controls…" calls `ControlsDialog()` (after flushing waiting input). "Set Gamepad Controls…" is hidden.
- With its resources missing the window finishes `false` at once and draws nothing (so headless tests that hand
  in no resources still pass straight through it).
- Behind it at boot: black, and black again when it closes.

## The drawn-control helpers S7 reuses (`FrontEnd/DialogDraw.swift`, `Resources/DialogResources.swift`)
**Read the doc comment above `ModalDialogRunner` first: it is the contract.** Both files are closed to S7.

How it draws: every pixel is a solid rectangle through the existing draw seam (face `COST`, alpha 0, draw-now, the
clip set to the full 640×480 on every command), about 2,470 commands for a full redraw of window 190, so a window
redraws only when something changed.

| Helper | What it is |
|---|---|
| `DialogFont.geneva9` (`glyph`, `width`) | Apple's Geneva 9 bitmap (System 7.5.3), all 195 glyphs plus the "missing" box, baked as a literal |
| `rect`, `frame`, `roundRect` | solid shapes |
| `text`, `textBox`, `wrap` | a text run at a baseline; text in a box; word wrap. Grey text = the same runs in grey |
| `centred`, `frameRect`, `window` | place a DLOG's rectangle on the 640×480 picture; the window frame |
| `saveUnder`, `restoreUnder` | only the OUTERMOST window saves and restores what it covers; a nested window draws over its parent, and the parent calls `invalidate()` and redraws whole when the nested one returns. **S7's window must not save.** |
| `pushButton`, `checkBox`, `groupBox`, `slider`, `sliderThumb`, `sliderValue` | the controls window 190 uses |
| `offset`, `inset`, `contains`, `hit`, `Press` | geometry, hit-testing by item rectangle, press tracking |
| `ModalDialogRunner` | the modal loop a screen owns: `begin` each pass, then `next` until `turnsLeft` is spent, then `needsRedraw` / `draw(own:)`; also `invalidate`, `flush`, `close`, item states and labels |
| `DialogResources`: `readFork`, `data`, `DialogTemplate`, `DialogItemList` / `DialogItem`, `ControlTemplate`, `ResourceStringList`, `TabList` | Foundation-only reader of the resource file (DLOG, DITL, CNTL, STR#, `tab#`); survives cut-short and damaged data |

What S7 builds in its own file with these: the edit-text field, focus ring, tab control and picture items. Put
those items in the runner's `ownItems`; draw them from the `draw(own:)` closure (pictures with `.drawPicture`);
set `screenFiltersKeys` so every key, Return and Esc included, reaches the screen first; use `standardKey` for a
key the screen declines; call `flush()` where the original calls FlushEvents; read modifier keys pressed alone
from the pass's held keys.

## Outside the file list (each allowed in the mailbox)
The real boot takes six passes, and older tests made one pass and expected the menu. Changed, set-up only, no
expectation and no test name: `FrontEndSkeletonTests`, `StartReturnTests`, `MainMenuTests` (mailbox A2, Ben) and
`FilmsTests.testDemoCycleOrderAndWrap` (the same change after S5 merged; noted in the mailbox). One test was
re-specified under its name (mailbox A4): `FrontEndSkeletonTests.testStubScreensPassThrough` no longer lists the
boot among the placeholder screens (the comment near line 200; merged with S3b's removal of the level select).

## For the gate-4 card (the seat's rulings; Ben may overturn each)
1. **The unit names show on every launch.** The original lists them only when its units cache file is missing
   (in practice the first launch). Mailbox Q3 offers "first launch only"; no answer yet.
2. **The font is Apple's own Geneva 9**, taken from the copy committed in the Castles project (Ben's ruling of
   2026-10-25 allows Apple's classic fonts). The first attempt, cut from the outline font, lost every "i" and "l".
3. **The slider range is 0…100**: the original's two slider controls (CNTL 2000, 2001) are not in the shipped
   file, so their range cannot be read; 0…100 agrees with the volume keys.
4. **"Set Gamepad Controls…" is hidden** by plan ruling 17, although the OS X build always shows it.
5. Not built, as in doubt or minor: the button flash on Return / Esc (the original probably flashes); a slider
   thumb snapping back when released far away; the window redraws whole while a slider is dragged.

## Known and left (none blocks S7)
- A press held over from an earlier pass ignores a new mouse-down queued behind it (`DialogDraw.swift` near 686).
- A click dragged off its button and released inside one pass still counts; slider presses use the pass's last
  mouse position (documented limits of the seam).
- `standardKey` does not look at whether the default or cancel item is greyed.
- Nothing tests Esc with `screenFiltersKeys` on and a cancel item present.
- No test pins a glyph of the font; S8b's `testGoldenConfigWindow` will.
- `StartReturnTests` near line 306: the music check no longer sees the boot's own start of the menu music.
- Three helper comments in older tests call the resource-less configuration window a "stub".

## Worktree
`.claude/worktrees/inspiring-bartik-9922ee` (branch `claude/inspiring-bartik-9922ee`), removed at the close; it
held this section's commits (all merged) and nothing else. Build products were in the session scratch folder.
