# Ferazel's Wand for Windows — what to expect (Phase W gate build: the Phase 4 game on Windows)

**Status: machine gates green; Ben's and Andrew's gate pending.**

Ferazel's Wand 1.0.3 for Windows: Ambrosia's Ferazel's Wand (1997), rebuilt to run on Windows 10 and 11 (64-bit) from
the original game's own data. Unofficial, non-commercial preservation. It is the same game as the Mac Phase 4 build —
levels 1 to 4, the spells and items, enemies that stand still — in lockstep with it: the Mac card
(`Ferazel/WHAT-TO-EXPECT.md`) and its list of stand-ins hold here too.

The question for you: **does the Windows build behave like the Mac build — sound by ear, dialogs by eye?**

**Boot results (loop run 35, 2026-10-27, by day, all muted):** the Mac staged app started and quit cleanly with no crash report; the staged Windows zip, in a clean CrossOver bottle, drew the main menu, level 1's first frame and the first frame with text exactly as the Mac development build does; the game's own test suite run under CrossOver: 489 passed, 0 failed, 1 skipped (the CrossOver-only skip), 0 crashed.

Nobody has heard it yet: every run the loop made was muted, and in CrossOver on this Mac, never on a real PC.

## Starting it
1. Unzip "Ferazel's Wand (Windows).zip" anywhere (the Desktop is fine): right-click it, Extract All. Do not run the
   game from inside the zip; it needs the whole folder.
2. Open the folder "Ferazel's Wand (Windows)" and double-click **Ferazel's Wand.exe**. Keep the "Data" folder and the
   .dll files next to it.
3. Windows will probably say **"Windows protected your PC"** (this build is not code-signed for Windows). Click
   **More info**, then **Run anyway**. Once is enough.

Your saved games and the settings file live in `%APPDATA%\Ambrosia Classics\Ferazel's Wand\` (paste that into
Explorer's address bar). A log of the last launch, "Ferazel's Wand.log", sits there too; if the game will not start, a
message box says why and the log has the details.

## On this Mac first (optional, daytime) — for Ben on the Mac where it was built; skip this on a PC
Both scripts force the no-sound driver and refuse to run between 21:00 and 09:00.
1. `tools/windows/proof-b-ferazel.sh` → last line `proof-b: 489 passed / 0 failed / 1 skipped / 0 crashed (of 490)`
   (the one skip is a test that cannot run under CrossOver; about 5 minutes).
2. `tools/windows/smoke-ferazel-win.sh` → `main menu: identical`, `new game: identical`, `level 1 text: identical`,
   exit 0 (the staged zip's game, in a clean CrossOver bottle, draws the same pictures as the Mac's development
   build: the main menu, level 1's first frame, and level 1 at full brightness with its status bar text). It needs a
   fresh stage first: `tools/windows/stage-ferazel-win.sh --no-desktop`, which refuses while the checkout has
   uncommitted changes; the smoke refuses a stage made before the latest commit.

## The gate card: what to check (a Windows 10/11 PC, or CrossOver)
3. **First launch** (SmartScreen: More info → Run anyway): logo, title music, main menu — no console window, no error
   box.
4. **Keyboard:** keypad 4 / 6 / 8 / 5 move with Num Lock on **and** off; Shift / Alt / Ctrl act as the Mac's Shift /
   Option / ⌘; Caps Lock pauses; Esc asks to abort; Ctrl+P opens Options (drawn inside the window); Alt+Enter full
   screen and back.
5. **New Game** → level 1 plays as on the Mac: music, effects, the status bar text, a sign's text smoothed like the
   Mac's.
6. **A real save and restore — please do this one.** The Windows Save and Open dialogs have been built but **never
   run anywhere yet** (the loop's runs answer them from a script). At a save point the Windows Save dialog should open
   in `%APPDATA%\Ambrosia Classics\Ferazel's Wand\` with the game's name filled in; save. Then Restore Game (Ctrl+O at
   the main menu, or Continue) should open that file again and the level should resume where you saved. Tell me if
   either dialog fails to appear, opens somewhere odd, or the restored game is wrong.
7. **Options:** remap a key, toggle music (it acts at once), OK; quit and relaunch — the settings held.
8. **A controller** (Xbox / Switch Pro / PlayStation): the Mac's layout (Ferazel/GAMEPAD.md); + pauses, − held one
   second = Esc.
9. **The close button** (new on Windows — the Mac window has none) while a level runs → "Are you sure you want to
   quit?" (Cancel plays on); at the main menu it quits. Log off with the game running: Windows is not held up for
   long.
10. `"Ferazel's Wand.exe" -FerazelLevel 3` from a command prompt in the folder → New Game starts at level 3.

Pass looks like: the Mac build's behaviour on Windows, sound by ear, dialogs by eye. Notes become a named wave.

## Small differences found while building (expected, not bugs)
- **The Open dialog may open in the folder Windows last used** for this program, not the saves folder (Windows
  remembers it). The Save dialog is told the full path, so it should open in the saves folder.
- **The Save dialog shows no message line** (the Mac's panel shows the original's prompt; Windows' dialog has no place
  for it).
- **Dialog text under 14 points is drawn with two levels of smoothing**, like the game's own text; on the Mac the
  dialogs are separate windows with fully smoothed text.
- **The popup menus in Options** (Sound panel) are drawn inside the window in a classic Mac style; the Mac shows a
  system menu.
- **A right-click outside a dialog does not beep** (the Mac beeps on any click outside; here only the left button is
  seen).
- **Esc does nothing on the "Are you sure?" confirm dialog** — as the original (it takes only Return / Enter).
- **Alt+Return cannot be set as a key in Options** — it is Windows' full-screen key here.
- **Ctrl shortcuts follow the US key positions** on other keyboard layouts (e.g. Ctrl+Q is the key where Q sits on a US
  keyboard), and Options shows US key names.

## Known stand-ins on Windows
| | What Windows lacks | Why / who replaces it |
|---|---|---|
| ◇W1 | Options' key names are the US layout's, not your PC's layout | the window library cannot ask Windows for the layout; a later task if wanted |
| ◇W2 | The window is resizable (the game scales in whole steps, on black); the Mac's is fixed | the window library always opens resizable |
| ◇W3 | Windows' own Open / Save dialogs where the original had its 1997 ones | the Mac build does the same with macOS's |
| ◇W4 | No About item (Credits is on the main menu); no menu check marks | there is no menu bar on Windows |
| ◇W5 | Nobody has heard it or run it on a real PC yet; the loop ran it muted in CrossOver only | Ben's ears, Andrew's PC |
| ◇W6 | Every Mac stand-in of Phase 4: enemies stand still, levels 5 and on refused, no underwater tint, the shield crouch | Phases 5–6, in lockstep with the Mac |
| ◇W7 | No installer, no signing, no file association; SmartScreen's "Run anyway" | publishing is Ben's |
| ◇W9 | The Save dialog shows no message line | Windows' dialog has no message area |
| ◇W10 | Dialogs drawn inside the game picture and scaled with it (enlarged 1× text); the Mac's are separate sharp windows | as Bubble Trouble X on Windows |
| ◇W11 | The window has a close button (the Mac's has none); a Windows log-off ends the game without the quit question | nothing is lost: quitting writes nothing |
| ◇W12 | No single-instance guard: a second launch is a second game (the Mac opens the save in the running game) | — |
| ◇W14 | Ctrl shortcut letters are matched by US key position, not the typed letter | the same cause as ◇W1 |

(◇W8 and ◇W13 were not needed: the item counts and the dialog font came out exact.)

## What to tell me
Your answer goes in `docs/QUESTIONS.md` under the Windows gate item: yes or no to "does the Windows build behave like
the Mac build?", then anything that felt, sounded or looked wrong, by card number if you can — and especially how the
save and restore (step 6) went.
