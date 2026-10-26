# Ferazel's Wand — what to expect (Phase 4 gate build: spells and items, levels 1–4)

**Status: machine gates green; Ben's gate pending.**

This build of our Ferazel's Wand 1.0.3 replica adds **the spells, the items and everything you can pick up, open, push
or switch**, and opens **levels 3 and 4**. The wand fires, the dagger stabs, the item bar at the bottom shows what you
really own and 7 / 9 choose from it. Xichrons, coins, crystals, potions, keys, power-up spheres and upgrades can be
picked up; chests, doors, crates, buttons, gates, switch blocks, mine carts and teleporters work. Everything from
Phases 2 and 3 (the movement, the title, menus, saves, pause, map, death screen and the controller) is unchanged
underneath. Every picture, sound and dialog still comes from the original game files, unchanged.

The question for you: **do the first four levels play like the original, as far as the original allows without
enemies?** Play it side by side with your Let's Play (https://www.youtube.com/watch?v=ESuyxMUEzDw) and the longplays.

## What this build is, and what it is not
- **It is** casting (the Fireball from the start, the Statue spell found on level 3), the dagger, the item bar and its
  selection, every pickup on levels 1–4, potions, the upgrades, the power-up spheres, the Ring of Smiting, chests, keys
  and doors, crates, buttons, gates, switch blocks, mine carts, teleporters, the spikes, and levels 3 and 4 from the map.
- **It is not** the enemies yet. They are drawn but stand still, do no harm, and take no hits (Phase 5). Level 5, the
  first boss, and everything after it are not built (Phases 5–6).

## Opening it
- Double-click `Ferazel's Wand.app` on your Desktop. It opens on the title screen, then the main menu. Start a New
  Game, or Resume a saved game from the Phase 3 build: it still opens.
- If macOS says it can't check the app: right-click it, choose Open, then Open again.
- The window is the game's 640×480 screen scaled ×3 if that whole window (title bar included) fits your screen's free
  area, menu bar and Dock left out; else ×2 if that fits; else ×1. ⌃⌘F gives full screen.
- This is a Release build, so it holds the original's top speed (30 game steps a second) — your Q9 ruling: kept for
  now, though it plays a little faster than the Let's Play, whose emulator couldn't keep up.
- **Your saved games and the game's settings file** live in `~/Library/Application Support/Ambrosia Classics/Ferazel's
  Wand/`. To start completely fresh, quit and delete that folder.
- **To make New Game start on level 2, 3 or 4** (a hidden test switch), quit the game, open Terminal and paste (here
  for level 3):

  `cd ~/Desktop && open -n "Ferazel's Wand.app" --args -FerazelLevel 3`

  The game still opens on the title and menu; New Game then goes straight to that level. That counts for that one
  launch. To make it stick, paste `defaults write com.ambrosiaclassics.ferazel FerazelLevel 3` instead, and
  `defaults delete com.ambrosiaclassics.ferazel FerazelLevel` to go back. Any number other than 1 to 4 means level 1.
- The hidden picture settings below also live in the `com.ambrosiaclassics.ferazel` preferences domain.

## Keys (the original's defaults; change them in Options ▸ Controls)
- **keypad 4 / 6** — walk left / right. **Shift** — run. **keypad 8** — up. **keypad 5** — down.
- **Option** — jump. **⌘** — use the selected item or spell. **keypad 7 / 9** — previous / next item.
- **Caps Lock** — pause: the game is paused while the Caps Lock light is on.
- **Esc** or **⌘W** in a level — "Are you sure you want to abort this game?". **⌘Q** — "Are you sure you want to
  quit?". **⌘P** — Options. These are read by the game itself, as in the original, so they don't act during a fade.
- At the main menu the letters act: **N** New Game, **O** or **R** Resume, **I** or **P** Options, **C** Credits,
  **Q** Quit, and **X** for a joke. ⌘ with those letters does the same thing.
- **⌃⌘F** — full screen on and off.
- **A game controller** works as in Phase 3 (pairing steps in `Ferazel/GAMEPAD.md`): the top button uses the item,
  L / R choose the previous / next item.

## The gate card: what to check

Each line says what the build does, read from the original's code. **MED** = fairly sure. Unmarked lines are read
straight from the code.

1. **The item bar.** The Fireball and the dagger sit in the strip at the bottom; the selected one is drawn big at the
   left. 7 / 9 step the selection (hold one: one step, then more at a steady pace). Counts above 1 show as
   "x3" in small Geneva type.
2. **The Fireball.** ⌘ with the Fireball selected: the wand comes up and the shot leaves on the same frame, arcs and
   glows, and the blue magic bar shrinks a little (8 of 560 per shot). Holding ⌘ does not repeat; the wand drops after
   about half a second. With no magic left, ⌘ switches to the dagger and stabs at once. Shots fizzle in water; a shot
   into a wall puffs.
3. **The dagger.** ⌘ with the dagger: a short stab. The dagger cannot break the crumbly rock — in the original only the
   Vorpal Dirk and the Ice Pick can, and so here.
4. **Shoot the torches and rock piles.** Each torch, candelabra or rock pile gives one crystal (magic if your magic is
   lower than your health, else health) and 150 points. A spent torch stays dark after you resume at a save point.
5. **Xichrons and coins.** The spinning gold Xichrons count in the score; at 100 the counter starts again and a red
   Xichron appears in the item bar. Coins and money bags add to the coin count, so Rojinko the merchant on level 1 now
   sells you potions, and they show in the item bar. Getting hit by level 1's spiked pendulums knocks up to 5 coins
   out of you; they blink and vanish after a few seconds unless you pick them up. (Spikes, fire and drowning hurt without
   costing coins, as in the original.)
6. **Level 1's key chain.** The chest near the start gives a Steel Key. The locked chest (stand near it and a thought
   balloon shows the key it wants) opens with it and gives a Gold Key. The locked door opens with the Gold Key when you
   walk into it from the left. Select a key and press ⌘: Ferazel tells you that you don't need to select keys. An
   unlocked door plays its sound every time you touch it, as in the original.
7. **Crates.** Shoot one or spin-jump onto it: it bursts into pieces and drops what it holds. One crate on level 1,
   about six screens in from the left edge, explodes — and the blast hurts you if you stand in it.
8. **Teleporters.** Stand on one until it sparkles: the screen breaks into blocks, you come out at its partner and the
   view re-centres. One of level 1's teleporters, about nine screens in, sends you to a piece of furniture a little to
   its left rather than to another teleporter. The original's level data says so; it is not a bug of ours.
9. **Power-up spheres.** Level 1's Invincibility (you flash), level 2's Solid Acid (walk on the acid), level 3's High
   Jump, level 4's Solid Water (walk on the water). Each lasts about 20 seconds (Invincibility 15) and ticks a warning in
   its last 7 seconds; Ferazel is tinted while one runs. A taken sphere hides and comes back later — one kind of
   Invincibility sphere only after about 18 minutes, as the original's data has it.
10. **Upgrades.** Level 2's maximum-magic crystal and level 4's maximum-health one: the screen flashes, the bar grows
    over about 2 seconds while the game holds still, then play resumes.
11. **Potions.** Level 1's floating magic potion and level 2's health potion: select one, press ⌘ and Ferazel drinks;
    the bar refills at the end of the drink.
12. **Level 3, "Western Reaches".** Enter it from the map (one of level 2's two exits leads there, the other to level 4).
    - The Statue scroll near the start teaches the Statue spell: its new slot in the item bar flashes, but the
      selection stays where it was — pick the spell with 7 / 9. Cast it on a moving platform: the platform stops,
      tinted, for about 4 seconds, and you can stand on it.
    - The Wounded Habnabit, in conversation, gives you the Platinum Key for a Health Potion; it opens a door.
    - A button raises a gate and stays pressed. The mine carts can be pushed. The air bubble refills your breath.
    - The spikes hurt while they are out. A spike that never moves still pulls in for a moment, with a sound, about
      every 18 minutes — the original's quirk.
13. **Level 4, "Eastern Reaches".** Enter it from level 2's other exit.
    - Standing on a button makes its switch blocks appear.
    - The gold ring is the Ring of Smiting: select it and press ⌘ — the screen flashes and every enemy on or near the
      screen (up to 16) gets an explosion. They don't die yet (Phase 5).
    - The boulder spouts stay quiet (Phase 5).
    - Level 4's exit leads to level 5 on the map; choosing it shows "Level 5 is not built yet (Phases 5-6)." and leaves
      you on the map at level 5's spot.
14. **Quitting from the Dock (your Q5 ruling).** Quit from the Dock or the app menu while a level runs: the game's own
    "Are you sure you want to quit?" box appears at once, exactly as ⌘Q does in a level (OK quits, Cancel plays on).
    During the level's opening (loading, chapter card, fades) the question waits until play starts. A logout, restart
    or shutdown quits at once without asking, so macOS never reports a cancelled logout.
15. **Things you can't see but may feel (MED).** All read from the code but not provable on screen:
    - the colours of the item and bar flashes;
    - the size of the teleporter's blocks;
    - the upgrade's 2 seconds, timed in 60ths of a second;
    - the item counts' Geneva, drawn by today's macOS;
    - level 2's hidden switch at its far left edge (it only shows in the saved game).

## Still true from Phases 1 to 3
- **The Phase 3 card** still describes the title, menus, Options, Credits, conversations, save points, pause, the
  stage-complete panel, the world map, Resume and the death screen. Nothing there has changed, except that the merchant
  now sells.
- **The feel card from Phase 2** still describes the movement: walking, jumping, spins, walls, water, platforms,
  cannons, passages.
- **Text** in conversations and signs is drawn smoothed, as Mac OS 9 drew it (your Phase 3 note); the small text in
  the status bar and the item counts stays crisp, as in the Let's Play.
- **Colours** go through the exact nearest-colour search (your ruling, 2026-10-10). The duplicate-black tie-break is
  **highest**. To look at **lowest**, quit and paste
  `defaults write com.ambrosiaclassics.ferazel ColorTieBreak lowest`, then open the game again;
  `defaults delete com.ambrosiaclassics.ferazel ColorTieBreak` goes back.
- **The hidden Mac gamma switch**, off by default. The picture looks a little darker than your Let's Play because the
  original ran on a classic Mac screen (gamma 1.8) and modern screens use 2.2. To see it as a classic Mac showed it,
  quit and paste `defaults write com.ambrosiaclassics.ferazel MacGamma -bool true` (or launch with
  `--args -MacGamma YES` for one run), then open the game again; `defaults delete com.ambrosiaclassics.ferazel MacGamma`
  turns it off.
- **The black border** around the play view is the original's own screen picture, not a bug.
- **Every run is different.** Random numbers start from the clock at launch, as the original's did.

## Known stand-ins and differences
- **Enemies** stand still, do no harm and ignore every attack — shots, the dagger, the Statue spell, the Ring of
  Smiting's blasts and exploding crates pass through or do nothing to them (Phase 5). So the stage-complete panel's
  enemy bar stays low, and nothing an enemy would drop appears.
- **The boulder spouts** on level 4 fire nothing (Phase 5).
- **Levels 5 and beyond** can't be entered: the map shows "Level 5 is not built yet (Phases 5-6)." (the only text in
  the game we wrote ourselves) and leaves you on the map (Phases 5–6).
- **Spells and items first found on later levels** — the Boomerang, Ice Wall, Tree Trunk and V Blade spells, the Ice
  Pick, the hang glider, the shields, the Mist potion, the necklace and the others — are built and machine-tested but
  can't be reached yet (your Q7 answer). One small piece of the Magical Shield (how Ferazel crouches behind it) still
  treats the shield as absent; it can't be seen until a level that has the shield.
- **Save and open windows** are macOS's own, not the 1997 ones; the original's prompt text is carried into them.
- **Saved games** are written so they survive zip, git and Windows. An original 1997 saved game opens here, but a save
  made here won't open in the original game on a classic Mac.
- **The settings file** lives in Application Support (above), not the classic System Folder.
- **The menu bar.** In a window the macOS menu bar stays visible; its items are greyed out during play and work only at
  the main menu and in the pause, where the original listened. In full screen it stays hidden, as the original: it
  shows during the pause, and at the main menu when the mouse is at the top edge of the game picture.
- **Quitting from the Dock** during a level asks at once (card step 14) — a deliberate change from the original, which
  waited for a pause. Your call (Q5).
- **A key still held when a dialog closes** isn't seen until you press it again (the original would read it at once).
- **The "set system volume" option** is remembered but never changes your Mac's volume.
- **Fonts:** the game ships no fonts yet, so Times and Geneva come from macOS.
- **The torch flicker** isn't built; item lights twinkle all in step (**MED**: the original starts each at a random
  point).
- **No screen switching, no CD check, no installer check, no birthday dialog, no InputSprocket.**

## What to tell me
A pass looks like: on levels 1 to 4 you can fire, stab, pick things up, open the chests and doors with their keys,
break the crates, ride the teleporters, take the spheres and upgrades, learn and cast the Statue spell, and it all feels
like the original — enemies aside.

Your answer goes in `docs/QUESTIONS.md`, under the Phase 4 gate item: a plain yes or no to "do the first four levels
play like the original, as far as the original allows without enemies?", then anything that felt or looked wrong, by
card number if you can.
