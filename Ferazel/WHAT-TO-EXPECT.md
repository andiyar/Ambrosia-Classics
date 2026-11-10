# Ferazel's Wand — what to expect (Phase 5 gate build: the enemies, levels 1–5 through the first boss door)

**Status: machine gates green; Ben's gate pending.**

**Windows:** the same build for Windows 10/11 has its own card, `Ferazel/WINDOWS-WHAT-TO-EXPECT.md`.

This build of our Ferazel's Wand 1.0.3 replica brings **the enemies to life** and opens **level 5, "Manditraki
Warrior"**, up to the first boss's door. Every enemy on levels 1–4 now walks, flies, hops, throws, blocks, hurts you and
can be hurt and killed; a hit knocks you back and can cost you coins; the stage-complete panel counts what you
defeated. Level 5 opens with its moving sky, and walking left locks you into the Warrior's arena. Everything from
Phases 2 to 4 (movement, front end, saves, map, spells, items, pickups) is unchanged underneath. Every picture, sound
and dialog still comes from the original game files, unchanged.

The question for you: **do levels 1 to 5 play like the original with the enemies alive, up to the Warrior's arena?**
Play it side by side with your Let's Play (https://www.youtube.com/watch?v=ESuyxMUEzDw) and the longplays.

## What this build is, and what it is not
- **It is** every enemy placed on levels 1–4 (goblins, crawlers, roaches, bats, frogs, blobs), their shots, getting hurt
  and hurting them, the Statue spell on enemies, level 4's boulder spouts, the underwater tint, and level 5 up to the
  Warrior's arena. Shield blocking is built and machine-tested too, but no shield can be reached yet (card step 8).
- **It is not** the Warrior fight. The Warrior stands still in the arena and the gate beyond it stays shut (Phase 6).
  Level 10 and everything after it are not built yet. You can't reach them in normal play: the only way on to level 10
  is level 5's far exit, beyond the Warrior's shut gate. Only an original saved game from a later level would show the
  "not built yet (Phase 6)" message.

## Opening it
- Double-click `Ferazel's Wand.app` on your Desktop. Start a New Game, or Resume a saved game from the Phase 4 build:
  it still opens.
- **To make New Game start on any level from 1 to 5** (the hidden test switch), quit the game, open Terminal and
  paste (here for level 5):

  `cd ~/Desktop && open -n "Ferazel's Wand.app" --args -FerazelLevel 5`

  The game still opens on the title and menu; New Game then goes straight to that level, for that one launch.
  `defaults write com.ambrosiaclassics.ferazel FerazelLevel 5` makes it stick, and
  `defaults delete com.ambrosiaclassics.ferazel FerazelLevel` goes back. Any number other than 1 to 5 means level 1.
- Everything else about opening it, the keys and the hidden picture settings is as in the Phase 4 card below.

## The gate card: what to check

Each line says what the build does, read from the original's code. **MED** = fairly sure. Unmarked lines are read
straight from the code.

1. **Goblins (level 1 onwards).** The axe throwers walk into range and throw axes in arcs; the ones that never walk
   stay put. The spear guards turn to face you, block your shots with a metal clang and thrust. The boulder goblin on
   levels 1 and 4 throws boulders that bounce a few times and burst into shards (the dark ones explode). Goblins growl
   and taunt now and then, and cry out when hit.
2. **Crawlers and roaches.** Crawlers hop; roaches scuttle back and forth. A falling crate or boulder crushes them.
3. **Bats (levels 2–4).** Sleeping bats wake when shot or approached, and chase you; level 3's path bat flies its
   route. Bats burst into blood and drop coins.
4. **Frogs (levels 2–4) and blobs (levels 3–4).** Frogs leap and spit; blobs ooze and attack.
5. **Getting hurt.** Touching an enemy or its shot knocks you back by its speed, splashes blood and sometimes knocks
   coins out of you (they fly out and blink). A big hit makes the big "ouch". Dead enemies never hurt.
6. **Hurting them.** Every spell, the dagger and the other held weapons, crushing boxes, the big explosion and the Ring
   of Smiting all work on enemies. Goblins die with their death frames and burn away; a goblin dying in water leaves a
   body that floats and can be stood on. Scores add up (goblins 400 to 600: the boulder goblin 400, the axe thrower
   500, the spear guard 600; crawler 500, roach 600, bat 600), and the stage-complete panel counts the enemies defeated.
7. **The Statue spell on an enemy.** It turns to stone for about 4 seconds; you can stand on it; it thaws 200 health
   points weaker.
8. **Shields: nothing to test yet.** Blocking (a raised shield stops shots from the front with a clang) and the
   Magical Shield's reflection (darts and spines bounce back and burn away; it has its own crouch picture) are built
   and machine-tested, but no shield can be reached: none lies on levels 1–4, level 5's Wooden Shield lies beyond the
   Warrior's shut gate, and the Magical Shield is first found on a much later level. They open up in Phase 6, once the
   Warrior can be beaten.
9. **Level 4's boulder spouts** fire boulders when their button is pressed.
10. **Under water** the screen takes a blue tint, and clears when you surface. In acid (levels 1–3) it is green. Lava,
    whose tint is red, is on none of levels 1–5, so the red tint can't be seen yet. In the healing-brine pools (levels
    2–5) the screen instead dims slightly, a little toward black, as the original does.
11. **Level 5, "Manditraki Warrior".** The sky behind the level moves. The level plays its own music from the start;
    the boss music comes only once the Warrior is beaten (Phase 6), so the arena locking does not change the music.
    You start at the right edge facing left. Walk left: the camera pans and the arena locks behind you, the gate ahead
    stays shut, and the Warrior stands there and hurts you if you touch it. Leave with Esc (abort) or ⌘W.
    Before the arena locks, walking back right leaves level 5 through its own exit to the map (the stage-complete
    panel shows 0 of 1 enemies defeated). A save point can be reached before the lock, too.
    **Expected missing until Phase 6:**
    - the real Warrior keeps three rocks dropping into its arena from 400 to 500 pixels up, spread across it; a rock
      breaks when it lands hard (and hurts you if it lands on you), and the broken ones are replaced together about
      half a second later. None fall here;
    - your shots do nothing special to it (the real one swallows them with a sound);
    - no spell, weapon or the Ring of Smiting harms the Warrior in this build: it stays standing, it keeps hurting you
      on contact, and the gate stays shut until Phase 6.
12. **Things you can't see but may feel (MED).** All read from the code but not provable on screen:
    - the colours of the tinted enemies, the frozen statues and the underwater tint;
    - the burn-away of a dying enemy;
    - the look of level 5's moving sky;
    - how much the goblins' voices vary in pitch.

## Machine checks run for this card
- **Visit sweep** (a script that takes Ferazel to every object on every level and draws it) on levels 1–5, through the
  Mac game path: <<SEAT:SWEEP-CORE>>
- The same sweep through the Windows game path: <<SEAT:SWEEP-WINDOWS>>
- **Random-play bot** (plays every level with random keys, several runs of a few minutes each) on levels 1–5, Mac game
  path: <<SEAT:BOT-CORE>>
- The same bot through the Windows game path: <<SEAT:BOT-WINDOWS>>
- **The test suites**, including the tests that load every picture each level uses and the check that every way of
  drawing the game can ask for is one the replica draws: <<SEAT:SUITES>>
- **Launch checks** (muted): <<SEAT:LAUNCH-CHECKS>>

## Known stand-ins (until Phase 6)
- **The Warrior** stands in its first picture, hurts on contact, never fights, never dies, and the gate stays shut
  while it lives (card step 11).
- **Level 10 and later** can't be entered yet: "Level n is not built yet (Phase 6)." (the only text in the game we
  wrote ourselves), then back to the map. Normal play can't reach it (the only way on is level 5's far exit, beyond
  the shut gate); only an original saved game from a later level would show it.
- **Enemies first placed after level 5** (the armadillo, the gremlin, the wraith, the salamander, the crab, the enemy
  pipes and the geysers) are built and machine-tested but can't be reached yet.
- **The other bosses** and the drawing features only later levels use (rain and other moving skies, the horizon strip,
  the fire and rippling backdrops) are not built; no level you can enter uses them.
- Everything in the Phase 4 card's "Known stand-ins and differences" below still holds, except the lines this build
  replaces: the enemies, the boulder spouts, the underwater tint, the Magical Shield's crouch and level 5.

## Known differences (forced by the platform or ruled)
1. **Many sounds at once.** When all 16 sound channels are busy and a new sound pushes an old one out, the replica can
   be wrong for one tick about whether that old sound is still playing. Nothing is drawn wrong and nothing quits. Tell
   me if you ever hear a difference. **MED**
2. **Tint colours.** The colours of the tinted enemies and the frozen statues come through the replica's own colour
   search. **LOW**
3. **The underwater tint** is applied to the picture the game draws, not to the monitor's colour setting as the
   original did; it should look the same. A pause of about a thousandth of a second the original made when the tint
   changes is not copied (nothing is drawn in it). **MED**
4. **Speed.** Every timer runs at the original's top speed of 30 game steps a second (your ruling, 2026-10-25).

## What to tell me
A pass looks like: on levels 1 to 4 the enemies move, attack, hurt you and die as in the original, and level 5 opens,
pans and locks you in front of the Warrior as in the Let's Play — the Warrior fight itself aside.

Your answer goes in `docs/QUESTIONS.md`, under the Phase 5 gate item: a plain yes or no to "do levels 1 to 5 play like
the original with the enemies alive, up to the Warrior's arena?", then anything that felt or looked wrong, by card
number if you can.

---

## The Phase 4 card (gate build: spells and items, levels 1–4) — kept as written

Kept as it was written for the Phase 4 gate. Where it says the enemies stand still, the boulder spouts are quiet,
there is no underwater tint or level 5 is not built, the Phase 5 card above replaces it.

**Status: machine gates green; Ben's gate pending.**

**Windows:** the same build for Windows 10/11 has its own card, `Ferazel/WINDOWS-WHAT-TO-EXPECT.md`.

This build of our Ferazel's Wand 1.0.3 replica adds **the spells, the items and everything you can pick up, open, push
or switch**, and opens **levels 3 and 4**. The wand fires, the dagger stabs, the item bar at the bottom shows what you
really own and 7 / 9 choose from it. Xichrons, coins, crystals, potions, keys, power-up spheres and upgrades can be
picked up; chests, doors, crates, buttons, gates, switch blocks, mine carts and teleporters work. Everything from
Phases 2 and 3 (the movement, the title, menus, saves, pause, map, death screen and the controller) is unchanged
underneath. Every picture, sound and dialog still comes from the original game files, unchanged.

The question for you: **do the first four levels play like the original, as far as the original allows without
enemies?** Play it side by side with your Let's Play (https://www.youtube.com/watch?v=ESuyxMUEzDw) and the longplays.

### What this build is, and what it is not
- **It is** casting (the Fireball from the start, the Statue spell found on level 3), the dagger, the item bar and its
  selection, every pickup on levels 1–4, potions, the upgrades, the power-up spheres, the Ring of Smiting, chests, keys
  and doors, crates, buttons, gates, switch blocks, mine carts, teleporters, the spikes, and levels 3 and 4 from the map.
- **It is not** the enemies yet. They are drawn but stand still, do no harm, and take no hits (Phase 5). Level 5, the
  first boss, and everything after it are not built (Phases 5–6).

### Opening it
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

### Keys (the original's defaults; change them in Options ▸ Controls)
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

### The gate card: what to check

Each line says what the build does, read from the original's code. **MED** = fairly sure. Unmarked lines are read
straight from the code.

1. **The item bar.** The Fireball and the dagger sit in the strip at the bottom; the selected one is drawn big at the
   left. 7 / 9 step the selection (hold one: one step, then more at a steady pace). Counts above 1 show as
   "x3" in small Geneva type.
2. **The Fireball.** ⌘ with the Fireball selected: the wand comes up and the shot leaves on the same frame, arcs and
   glows, and the blue magic bar shrinks a little (8 of 560 per shot; the 560 grows
   when you take level 2's maximum-magic crystal). Holding ⌘ does not repeat; the wand drops after
   about two-thirds of a second. With no magic left, ⌘ switches to the dagger and stabs at once. Shots fizzle in water; a shot
   into a wall puffs.
3. **The dagger.** ⌘ with the dagger: a short stab. The dagger cannot break the crumbly rock — in the original only the
   Vorpal Dirk and the Ice Pick can, and so here.
4. **Shoot the torches and rock piles.** Each torch, candelabra or rock pile gives one crystal (magic if your magic bar is
   emptier than your health bar, each measured against its own full length, and your health is above 37 points; else
   health) and 150 points. A spent torch stays dark after you resume at a save point.
5. **Xichrons and coins.** The spinning gold Xichrons count in the score; at 100 the counter starts again and a red
   Xichron appears in the item bar. Coins and money bags add to the coin count, so Rojinko the merchant on level 1 now
   sells you potions, and they show in the item bar. Getting hit by level 1's spiked pendulums knocks 4 to 6 coins
   out of you (fewer if you hold fewer); they blink and vanish after a few seconds unless you pick them up. (Spikes, fire and drowning hurt without
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
9. **Power-up spheres.** As the levels place them:

   | level | spheres |
   |---|---|
   | 1 | Invincibility |
   | 2 | Invincibility, Solid Acid (walk on the acid) |
   | 3 | Invincibility, High Jump |
   | 4 | Solid Water (walk on the water), High Jump |

   Invincibility makes you flash and lasts about 15 seconds; the others last about 20 seconds and tint Ferazel while
   they run. Each ticks a warning in its last 7 seconds. A taken sphere hides and comes back later — an Invincibility
   sphere only after about 18 minutes, as the original's data has it.
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
    - The spikes hurt. Level 3's spikes never move: they stay out, and twitch in for a moment, with a sound, about
      every 18 minutes — the original's quirk.
13. **Level 4, "Eastern Reaches".** Enter it from level 2's other exit.
    - Standing on a button makes its switch blocks appear.
    - The gold ring is the Ring of Smiting: select it and press ⌘ — the screen flashes and every enemy on or near the
      screen (up to 16) gets an explosion. They don't die yet (Phase 5).
    - The boulder spouts stay quiet (Phase 5).
    - Level 4's exit leads to level 5 on the map; choosing it shows "Level 5 is not built yet (Phases 5-6)." and leaves
      you on the map at level 5's spot.
14. **Quitting from the Dock (your Q5 ruling).** Quit from the Dock while a level runs: the game's own "Are you sure
    you want to quit?" box appears at once, exactly as ⌘Q does in a level (OK quits, Cancel plays on). During the
    level's opening (loading, chapter card, fades) the question waits until play starts. During a conversation, an
    upgrade, a teleport, a save, a dialog or the pause it is handled as the original did: it waits, and the game quits
    without asking once you pause or reach the main menu — or, with the Options setting "Allow background tasks" on,
    play simply forgets it. A logout, restart or shutdown quits at once without asking, so macOS never reports a
    cancelled logout.
15. **Things you can't see but may feel (MED).** All read from the code but not provable on screen:
    - the colours of the item and bar flashes;
    - the size of the teleporter's blocks;
    - the upgrade's 2 seconds, timed in 60ths of a second;
    - the item counts' Geneva, drawn by today's macOS;
    - level 2's hidden switch at its far left edge (it only shows in the saved game).

### Still true from Phases 1 to 3
- **The front end is unchanged:** the title and loading screens, the main menu, Options (with key setup), Credits,
  New Game with the chapter card, conversations and signs, save points and Resume, the Caps Lock pause, the
  stage-complete panel, the world map and the death screen all work as in the last build. The one difference: the
  merchant now sells, since coins can be picked up.
- **The movement is unchanged:** walking, running, jumping, spins, walls, water, platforms, cannons and passages.
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

### Known stand-ins and differences
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
- **The screen does not tint under water yet** (the original colours the whole screen while you are under water, acid
  or lava).
- **No screen switching, no CD check, no installer check, no birthday dialog, no InputSprocket.**

### What to tell me
A pass looks like: on levels 1 to 4 you can fire, stab, pick things up, open the chests and doors with their keys,
break the crates, ride the teleporters, take the spheres and upgrades, learn and cast the Statue spell, and it all feels
like the original — enemies aside.

Your answer goes in `docs/QUESTIONS.md`, under the Phase 4 gate item: a plain yes or no to "do the first four levels
play like the original, as far as the original allows without enemies?", then anything that felt or looked wrong, by
card number if you can.
