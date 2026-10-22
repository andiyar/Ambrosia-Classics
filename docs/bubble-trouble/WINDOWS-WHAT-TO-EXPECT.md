# Bubble Trouble X for Windows — what to expect

Bubble Trouble X 1.0 for Windows: Ambrosia's Bubble Trouble X (2008), rebuilt to run on Windows 10 and 11 (64-bit)
from the original game's own data. Unofficial, non-commercial preservation.

## Starting it
1. Unzip "Bubble Trouble X (Windows).zip" anywhere (Desktop is fine). Right-click it, Extract All. Do not run the
   game from inside the zip: it needs the whole folder. (If you double-click the .exe inside the zip, Windows itself
   says it cannot find a .dll file or cannot find the program — that means: extract first.)
2. Open the folder "Bubble Trouble X (Windows)" and double-click **Bubble Trouble X.exe**. Keep the "Data" folder and
   the .dll files next to it.
3. Windows will probably say **"Windows protected your PC"** (this build is not code-signed for Windows).
   Click **More info**, then **Run anyway**. You only need to do this once.

You should see the Ambrosia logo, a loading screen, then the title screen. It looks like the 2008 Mac game on
purpose: the window is just the game, and the dialogs (preferences, high scores) are the original Mac ones.

## Window size
The game is 640×480. The window opens at the biggest whole-number multiple of that which fits your screen: on a
typical 1080p screen that is double size (1280×960); on a smaller 1366×768 laptop screen, or a laptop with Windows display scaling at 125–150 %, it may be the original size.
**Ctrl+F** switches to full screen with the biggest sharp picture that fits; Ctrl+F again goes back. The game
remembers which you used.

## Keys
- Title screen: **N** or **Enter** new game, **D** demo, **S** high scores, **P** preferences, **C** credits,
  **L** level select, **Q** quit.
- Playing: **arrow keys** move, **Space** pushes, **Caps Lock** pauses while it is on, **Esc** ends the game.
- There is no menu bar; the Mac menus' shortcuts work, with **Ctrl** for the Mac's ⌘ (Command) key:
  - **Ctrl+F** full screen on/off (not while playing)
  - **Ctrl+,** (comma) preferences (not while playing — pause with Caps Lock first, then Ctrl+,)
  - **Ctrl+M** music on/off
  - **Ctrl+Shift+A** sound effects on/off
  - **Ctrl+Q** quit (closing the window quits too)
- The Mac's Option key is **Alt** (for example Alt-click "Scores" on the title screen to erase the high scores).
- You can choose other keys in Preferences → Keys → New Set….
- **A game controller works too** (Xbox, PlayStation, Switch Pro — any pad Windows and SDL recognise; plug it in or pair
  it before or while the game runs). In a game: d-pad / left stick move, **any face button** pushes, **Start / Menu /
  +** pauses and un-pauses, hold **Back / View / −** for a second to end the game. On the title screen, scores and
  dialogs: any face button or Start = Enter (start, OK), Back = Esc (Cancel). Move and push follow the key set in
  Preferences. The controller only works while the game window has the focus.

## Sound
Sound effects and music play through your default sound device, at the original's levels (checked on a real
Windows PC). The Preferences volume settings and Ctrl+M / Ctrl+Shift+A apply.

## Where it keeps things
Preferences, high scores and a log file live in `%APPDATA%\Ambrosia Classics\Bubble Trouble X\`
(paste that into the File Explorer address bar). The log, **BubbleTroubleX.log**, is rewritten every time the
game starts. If the game cannot start it shows a message saying why.

## Something wrong?
Open an issue at https://github.com/andiyar/Ambrosia-Classics/issues with what you did just before, a screenshot
(Windows+Shift+S) and the BubbleTroubleX.log file.
