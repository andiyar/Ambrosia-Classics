# Handoff — Deimos Rising Phase 4, section S7: the controls window; the controller (closed 2026-11-20)

Seat: Claude Opus 5.5. Helpers: Opus 5.5 (`fk-implementer`, `fk-reviewer`), foreground. Section S7 of
`docs/superpowers/plans/2026-11-20-deimos-phase4.md` is done and on main. **Every screen section is closed; S8a may
start.** Wave 3.4 (68b93b6) and S6 (4d9e147) were on main before the first dispatch.

## What a player would notice
Nothing yet: the app still uses the direct start until S8a wires the front end in. Underneath, "Set Controls…" in
the settings window now opens the original's controls window (both players' keys, drawn by the game in the classic
grey Mac look), and a controller layout exists for S8a to switch on.

## What landed

| Commit | What |
|---|---|
| `0596221` | CW: the controls window |
| `9e1d0c4` | CW fix round: Save and Cancel keep the pass's sounds (a beep in the same pass was lost); header comment corrected |
| `a9890d2` | GP: the controller layout; HectorInput added to DeimosCore (the phase's one Package change) |
| `c7c205d` | GP fix round: a pad button held from the level select into play no longer fires; plus pauses the level select |

Reviews: each task one implementer, two Opus legs (spec, then quality), one fix round. CW's fix round was a
three-line change the seat read itself. GP's fix round changed behaviour and had its own Opus re-review leg
(MERGEABLE, with probes).

## Gates, measured by the seat at the merged head (main had not moved: base 4d9e147)

| Gate | Result |
|---|---|
| G2 `Deimos/Core` without the replay and campaign bundles | **467 / 0 / 0** (main 454 + CW 8 + GP 5) |
| G4 `DeimosReplayTests`; `deimos-replay --all` | **4 / 0**; four PASS lines, exit 0 |
| G5 Deimos Debug and Release, Aki, BubbleTroubleX | all four `** BUILD SUCCEEDED **` |
| G3 census, G7 layering, G10 clean tree | empty diff; prints nothing; clean |
| G6 scope | exactly the plan's six S7 files |
| G1, G8 | not run (no kit change; G8 is not due at S7) |

**G2 base for S8a: 467.**

## The controls window (`FrontEnd/ControlsDialog.swift`)
- DITL 191's seventeen items; the Player 1 / Player 2 tab; seven key fields named from STR# 130 (codes 0x80 and up
  read "??", as X); every key press is bound and consumed, so Return, Esc, Tab and the arrows bind and never press
  Save or Cancel; modifier keys pressed alone bind only for left Control, Shift, Option and Command (Caps Lock and the
  right-hand modifiers never); a key already used by either player is refused with a flush and a beep unless the
  focused field already shows that key's name; focus moves 5 → 7 → … → 17 → 5; a click on a field focuses it; a tab
  switch refills the fields and focuses the first; Save writes both players' keys into the live settings and finishes
  true; Cancel changes nothing.
- It is nested inside the settings window, so it saves nothing under itself (S6's contract).
- **Pictures:** the seven arrow and button pictures (PICT 190–193, 195–197; DITL 191 uses no 194, so the plan's
  "eight pictures" is one too many) are drawn with the same picture command the boot uses for the developer logo,
  at each item's top-left, at the picture's own size. Nothing draws them until **S8a hands PICT 190–197 to Core**
  with the other shell pictures. With the resource file missing the window finishes false at once and draws nothing.

## The controller (`Input/DeimosPadLayout.swift`)
- `DeimosPadLayout.mapping(keySet:context:)` gives the kit's pad mapping for one of six contexts: playing, paused,
  level select, main menu, screens (scores, name entry, credits, dialogs), demo.
- Ben's answer, built as the plan's defaults: bottom = fire air, left = fire ground, top and right = select; d-pad and
  left stick = the four directions; one pad, player 1; plus = pause (the Caps Lock latch); minus = Esc, held one
  second in play, at once elsewhere. Shoulders and triggers unmapped. The face buttons sit in one table
  (`faceSlots`), so "we may need to work on button mapping" is a one-line change.
- The play layout reads player 1's live keys, so changing keys in the controls window moves the buttons too.
- **How "held across a change does not fire" is met:** the kit drops a held button only when its binding changes,
  and the app cannot tell it to drop held buttons (that call is private in the kit's view). So the level select
  binds its buttons as "key after a 0-second hold", which fires on the very first poll like a plain key but counts as
  a different binding, and the kit drops a button held from the level select into play (and back). The same is done
  for minus between the menu, the level select and a demo.

## For S8a (the app)
1. Hand PICT 190–197 from `Deimos Rising.rsrc` to Core with the other shell pictures.
2. Assign `DeimosPadLayout.mapping(keySet:context:)` before each poll, with the context of the screen on top. While
   the level select's pause is up, pass `.paused` (plus is the latch there too).
3. Do not make key-repeat events from held pad keys: an arrow held from the menu into a screen stays held (harmless
   today because screens read presses only).
4. The controls window under a pad: in the "screens" context a pad press is a key press, so a pad's Return or arrow
   could be captured as a key binding there. Decide whether the pad is switched off while that window is up.
5. Write `Deimos/GAMEPAD.md` from the section above.

## For the gate-4 card (the seat's rulings; Ben may overturn each)
1. **The tab control's look is invented:** no picture of the original exists; tabs 24 px tall, left-aligned, the
   Platinum focus ring and highlight colours.
2. **Clicking a field that already has focus keeps it highlighted;** X leaves a caret there.
3. **Modifier keys pressed alone are tracked per opening of the window;** X tracks them for the whole run, so a
   modifier held while the window opens binds in the replica and not in X.
4. **Plus pauses the level select**, as Caps Lock does in the original; the grounding's controller table said
   nothing there. Whether plus should pause a demo is unknown.
5. **Minus "at once" still respects the "Hold Escape" setting:** with it on, a tap of minus does nothing at the
   level select or in a demo (as the keyboard's Esc).
6. **Minus is Esc at the main menu,** where the menu ignores Esc (ruling 17 over the grounding table).
7. A low-confidence doubt from the quality leg: X's key filter consumes the key without naming an item; if the Mac's
   dialog routine then reported the last clicked item, X would pull the focus back to that field after each key.
   Ben's memory of the window is the check.

## Known and left (none blocks S8a)
- Key codes 0x80 and up are stored as 16-bit values, X stores 32-bit (unreachable with real keys).
- Within one pass the modifier check runs after the pass's key events; X checks between events.
- Untested: a left-modifier key arriving as a key event, auto-repeat, codes 0x80 and up; an arrow held from the
  menu into the level select (fixed, only minus pinned for that pair).
- The comment on the field-click function (ControlsDialog.swift near line 202) still says only "focused and selected".
- With the slot-count guard removed, a future face remap could reach player 2's slots (low risk).
- The commits themselves do not state that wave 3.4 and S6 were on main; this handoff does.

## Worktree
`.claude/worktrees/nostalgic-clarke-6946c5` (branch `claude/nostalgic-clarke-6946c5`), removed at the close; it held
this section's commits (all merged) and nothing else. Build products were in the session scratch folder.
