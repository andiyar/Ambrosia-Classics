# Ferazel's Wand — what to expect (Phase 2 gate build: feel on levels 1–2)

**Status: machine gates green; Ben's gate pending.**

This build of the Ferazel's Wand 1.0.3 replica makes **Ferazel move.** You can play levels 1 and 2 with the original
keys: walk, run, jump, spin, cling and climb walls, swim, ride the platforms, get hurt, die and start again, and walk
out of level 1 into level 2. The sound effects play through a copy of the original's own sound mixer. Every picture and
sound still comes from the original game files, unchanged.

The question for you: **does he move and feel like Ferazel on levels 1 and 2?** Play it side by side with your Let's
Play (https://www.youtube.com/watch?v=ESuyxMUEzDw) and the longplays.

## What this build is, and what it is not
- **It is** the player's whole movement on levels 1 and 2, the camera that follows him, water, acid, damaging floors,
  healing brine, drowning, platforms of every kind on these two levels, the spiked pendulums, cannons, trampolines,
  bridges, passages, dying and restarting, the exit from level 1 into level 2, the splashes, bubbles and particles, and
  the sound effects. Phase 1's look is unchanged underneath.
- **It is not** the rest of the game yet. Enemies stand still and do no harm (Phase 5). Coins, potions, chests, doors,
  teleporters, save points, signs and the people you meet are only solid things to stand on or bump into (Phases 3–4).
  Crates and the boulder can't be pushed yet (Phase 4). No title screen, no menus, no world map, no stage-complete
  screen (Phase 3).

## Opening it
- Double-click `Ferazel's Wand.app` on your Desktop. It opens on level 1.
- If macOS says it can't check the app: right-click it, choose Open, then Open again.
- **To start on level 2**, quit the game, open Terminal and paste:

  `cd ~/Desktop && open -n "Ferazel's Wand.app" --args -FerazelLevel 2`

  That counts for that one launch. To make it stick, paste
  `defaults write com.ambrosiaclassics.ferazel FerazelLevel 2` instead, and
  `defaults delete com.ambrosiaclassics.ferazel FerazelLevel` to go back to level 1. Any number other than 1 or 2
  starts level 1. You can also just reach level 2 through level 1's exit.
- The window is the game's 640×480 screen scaled ×2 or ×3, whichever fits your screen whole. ⌃⌘F gives full screen.
- This is a Release build, so it holds the original's speed (about 30 frames a second).
- The hidden settings below all live in the `com.ambrosiaclassics.ferazel` preferences domain.

## Keys (the original's defaults; there is no key setup screen yet)
- **keypad 4 / 6** — walk left / right. **Shift** — run.
- **keypad 8** — up: climb a wall, enter a passage or a cannon. **keypad 5** — down: crouch, climb down.
- **Option** — jump. **keypad 5 + Option** — spin.
- **⌘, keypad 7 and keypad 9** are mapped as in the original; nothing on levels 1–2 uses them yet.
- The arrow keys do nothing now. Phase 1's arrow-key camera is gone.
- **⌃⌘F** — full screen on and off. **⌘Q** — quit at once. The original asked "are you sure?" first; that dialog
  comes later. ⌘W does nothing.
- **Caps Lock** (pause) and **Esc** (the "abort game?" dialog) do nothing until Phase 3.

## How to get to water on level 1
Walking right from the start does **not** reach water. Walk right from the start and you drop at once into a little
pit and cling to its wall. That is the original. The start rooms are closed in by **breakable walls**. The way out:
drop into the lower room and **spin-jump down onto the wall** a few blocks to the right (about x 770, column 24; spin
= keypad 5 + Option while you fall from above). The wall breaks. Then run right along the lower passage and you drop
into the first pool (x ≈ 1800–2600). The machine test plays exactly this route.

That first pool is only wading-deep, so jumping there is an ordinary jump and **swimming is not covered by any machine
test.** To swim, go on to the **deep pool**: columns 146–156, rows 23–26 (x ≈ 4670–5020, about y 740–860, a bit
under halfway across level 1).

## The gate card: what to check

Each line says what the build does, copied from the original's code ("built as the binary"), and where we have one,
what "wrong" would look like. **MED** = fairly sure. Unmarked lines are read straight from the code.

1. **Walk and run.** Speed, how fast he gets going and how fast he stops. Built as the binary: **right reaches full
   walking speed in 4 frames, left in 8** (an extra push to the right only), and running right overshoots full speed
   for one frame. Wrong would look like: left and right feeling the same, or a slide when you let go.
2. **Jump.** Built as the binary: a full jump is about 100 px high, a tap about 44 px; a full jump is back on the
   ground in about 0.8 s. No grace jump after you walk off a ledge, no jump that remembers an early press, and holding
   Option does not jump again. On the take-off frame he still looks like he is standing.
3. **Spin (keypad 5 + Option).** Built as the binary: only from the ground, a wall or the water. It does **not** make a
   jump longer in mid-air. (Our notes said it did; the code says no.)
4. **Walls.** Clinging, climbing up and down (keypad 8 / 5), the wall jump, pulling himself up over a ledge.
5. **Slopes and ledges.** Built as the binary: he climbs a slope faster going right than going left. He drops when
   there is nothing under him, and lands on one-way ledges from above only.
6. **Camera.** Built as the binary: when he jumps from flat ground the view does **not** follow him up. When he falls
   below where he stood it eases down; when he lands higher it eases up. It looks up to 80 px ahead in the direction he
   walks and keeps that when he stops.
7. **Water.** Level 1 has five pools; the first is described above. Built as the binary: a splash going in and coming
   out, swimming strokes (deep pool only), the current pushing him along (level 1 only), bubbles, and his breath
   running out. Once it is gone he takes a hit about every 2.3 s.
8. **Acid and damaging floors.** Level 1 has the acid pool at the far right and 18 damaging floor cells; level 2 has
   four acid pools (74 cells). Built as the binary: the hurt flash, a groan or "ouch", and the knock-back stun.
9. **Healing brine** (level 2, 12 cells). His health and magic fill up, with the fill-up sound.
10. **Platforms.** Built as the binary:
    - Level 1's three sliding platforms dip when you land on them and spring back.
    - The rotor pair and the swinging platform are near x 2300 and x 3200, and the three-wheel is near x 1850.
    - On level 2 the rafts float and tilt under you, and the wheels turn when you ride them.
    - A platform never shows on the very first frame of a level, as in the original.
    - Level 1's wheel bumps itself on its first frame, out of view, so early in level 1 it has already turned about 28°
      and moved about 28 px left. That is the original's own quirk.
11. **Spiked pendulums** (level 1, x ≈ 2660 and 2760). Built as the binary: they hurt only in a narrow band just in
    front of the bottom of the swing. (Our notes had the band the wrong way round.) The coins you would lose are not
    dropped yet (Phase 4).
12. **Cannons** (level 1, three). Climb in with keypad 8 and you are fired straight up, with a puff of smoke.
13. **Crates, the boulder (level 2), trampolines (level 2), bridges.** Crates and the boulder stand still as solid
    blocks (pushing is Phase 4). Trampolines bounce you, and bridges are solid both ways. **MED:** the original lets
    crates settle under gravity, which is Phase 4's, so level 1's crates sit 2–6 px lower than the original would
    settle them, one crate stacked on another sits 2 px high, and level 2's boulder sits 2 px low.
14. **Passages** (level 2, three pairs). Press keypad 8 at one: the screen fades to black, you come out at its
    partner, and it fades back in.
15. **Death.** The dying animation, then the original's border wipe, then the level starts again from the beginning
    with fresh health, magic and score. That restart stands in for Phase 3's menu / Continue. **Not built:** the
    original fades the restarted level in from black; here it appears at full brightness at once.
16. **Level 1 → 2.** Touching level 1's exit loads level 2 at once. That stands in for Phase 3's stats screen and world
    map. What happens:
    - The exit sound plays out. Nothing silences it when the new level loads; the original does not either.
    - The music fades out, and the screen holds still for about 0.8 s while it does. The original holds still too.
    - Then level 2 appears straight away. **Not built:** the original's stage-complete effect, its fade to black and
      its end-of-level stats update. The music starts again at full volume, with no fade-in.
    - Your score, health, magic and coins carry into level 2, as in the original. Level 2's own exits lead to levels 3
      and 4, which aren't built, so they restart level 2.
17. **Sound.** Footsteps, jump, soft and hard landings, head bonk, splash, swim, groan or "ouch", the drowning choke,
    fill-up, cannon, trampoline. Built as the binary: the original's Sound Tool mixer, 8-bit at 22,050 Hz with
    8 voices at most, so a little gritty on purpose. Wrong would look like: sounds cut off oddly, coming from the wrong
    side in stereo, or too loud or quiet next to the music.
18. **Water look (MED).** On level 1 the water now shows drifting motes, the acid bubbles, and the ground under water
    shimmers every other frame. These are the original's "Enhanced" water effects, which Phase 1 didn't draw.
19. **Breathing (MED).** When he has stood still a while, his chest stops moving. The original holds the calm breath on
    one picture.
20. **Things you can't see but may feel (MED).** All read from the code but not provable on screen:
    - the keys are read live, within a frame;
    - how he catches on the seams between tiles;
    - exactly where the water surface starts to count as water;
    - where the wheels start on their first frame (off-screen);
    - when a bubble is allowed to rise.
21. **Every run is different.** Random numbers start from the clock at launch, as the original's did, so no two runs
    play out exactly the same (splashes, particles, sound pitches).

## Still true from Phase 1 (the look)
- **Colours** go through the exact nearest-colour search (you ruled it 2026-10-10 against your Let's Play). The
  duplicate-black tie-break is **highest** (your ruling, Let's Play 02:12). To look at **lowest**, quit and paste
  `defaults write com.ambrosiaclassics.ferazel ColorTieBreak lowest`, then open the game again;
  `defaults delete com.ambrosiaclassics.ferazel ColorTieBreak` goes back.
- **The hidden Mac gamma switch is built**, and off by default. The picture looks a little darker than your Let's Play
  because the original ran on a classic Mac screen (gamma 1.8) and modern screens use 2.2. To see it as a classic Mac
  showed it, quit and paste `defaults write com.ambrosiaclassics.ferazel MacGamma -bool true` (or launch with
  `--args -MacGamma YES` for one run), then open the game again; `defaults delete com.ambrosiaclassics.ferazel MacGamma`
  turns it off.
- **The glow behind the table next to the potion is fixed.** The potion's light twinkles, as in the original. **MED:**
  every item light twinkles in step, where the original starts each one at a random point. The torch flicker isn't
  built yet.
- **The black border** around the play view is the original's own screen picture, not a bug.
- **The music** is track 1 of the original files, played by our own player. It starts at full volume; the original
  fades it in at the start of a level, and that isn't built yet. The loop point may sound a hair different from
  QuickTime's.
- **The placed sprites** that aren't built yet (enemies, items, people) still show their first picture only.
- On the very first frame of a level Ferazel isn't drawn. That one-frame blink is the original's.

## Known stand-ins and differences
- **Enemies** stand still and do no harm (Phase 5). **Pickups, chests, doors, teleporters, save points, signs and
  people** are only solid (Phases 3–4).
- **Death restarts the level** and **the exit loads level 2 at once.** These are stand-ins for Phase 3's menu, stats
  screen and world map. Not built: the fade-in after a restart, the stage-complete effect, the fade to black at the
  exit, and the end-of-level stats update.
- **Only levels 1 and 2 load.** Level 2's exits restart level 2.
- **No music fade-in**, at a level's start or after the exit.
- **⌘Q quits without asking**, and ⌘W does nothing.
- **Caps Lock and Esc** do nothing until Phase 3.
- **Ropes and springs are built**, but levels 1 and 2 have none. The first rope is on level 3 and the first spring on
  level 15.
- **No screen switching, no CD check, no installer check, no birthday dialog, no InputSprocket.** The game runs in a
  window and does the 256-colour palette itself, and the keys come straight from the original's key table.

## What to tell us
Plain yes or no to "does he move and feel like Ferazel on levels 1 and 2?". Then anything that felt or looked wrong,
by card number if you can.
