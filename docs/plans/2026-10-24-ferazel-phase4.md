# Plan — Ferazel's Wand Phase 4 "Spells + items": casting, the spells and player shots, items and the inventory HUD, pickups, power-ups, boxes (crates, chests, doors, keys, switches, teleporters), the held weapon — 2026-10-24

> Status: **READY TO EXECUTE — planner Opus 5.5, loop run 18 (2026-10-24); two Opus legs (SOUND WITH FIXES) and the
> FABLE-GRADE plan leg (PASS WITH FIXES) done, both fix rounds applied (see "Review ledger")**. Implements `docs/plans/2026-10-06-ferazel-design.md` (APPROVED) **§8 row 4 only** (+ §9 (c)),
> written against what Phases 1–3 landed (Classics main b5bfb62: D26 as built, D32, D33 as built, D35 as built through
> loop run 17, D37; `Ferazel/Core` 349/0; HectorKit 35a85ba, floor 361).
> **Format (Ben, 2026-10-03): CONTRACTS, not code.** Files, public names (signatures only where they pin a seam),
> behaviour with bank + dump anchors, test names with the number each checks and where it came from, gate commands,
> commit messages. No implementations.
> **Grounding.** Phase 3's research digests A–F were **never committed**; this plan is grounded on the bank
> (`docs/ferazel/`), the committed dump (`ghidra/ferazel/Ferazel_pef.decompiled.c`, 88,106 lines, cited "M l. N";
> `Ferazel_pef.disasm.txt`, cited "raw XXXXXXXX"), the original data (the planner's census scripts over
> `Resources/Ferazel/`, results inline in "Research notes"; scripts not committed) and the current code. Every M line
> here was re-read in the committed dump on 2026-10-24 (function spans from its `// ==== name @ addr ====` headers).
> Where the dump disagrees with the bank, **the dump wins** (Ben 2026-10-07, "follow the binary") and "Bank
> corrections to append" says so. ⚠️ The bank's "handler l. N" / "main l. N" citations come from older dumps; **use the
> M lines in this plan, and re-read the dump before coding** — the plan is wrong against the dump about once per task
> (NEXT lesson 2); the dump wins and the task's "As executed" note records it.

**Goal.** Ferazel fights and gathers the original's way on the first four levels: Fireball from the start and every
spell a scroll teaches (the wand raise, the cast frame, the shots with their arcs, trails, lights, followers and
impacts, Boomerang homing, V Blade, Ice Wall floes and ledges, Tree Trunk, Statue), the dagger stab and the other held
weapons, thrown seeds, potions, rings, the shields' raise, the Mist potion, the Resurrection Necklace, the hang glider;
every pickup (Xichrons and the red Xichron at 100, crystals, coins and money bags, upgrades with their 2-second
animation, air bubbles, scrolls, items, the triggers and secret counters) and every power-up sphere (Shadow Double,
solid water/acid/lava, High Jump, Invincibility, Featherfall, Double Speed with its trail, Pentashield, Death); the
inventory in the status bar from the game globals (27 slots, the selection keys 7/9, counts, the pickup flashes); the
boxes on levels 1–4 (crates and their drops and explosions, chests and keys, doors, the thought balloons, boulders,
mine carts, stalactites, teleporters with the mosaic, Buttons, gates, switch blocks, boulder spouts); and levels 3 and
4 become enterable from the map. **Ben's gate: "first levels as the original allows"** (= levels 1–4 everything but
the enemies, which stand still until Phase 5 — Ruling 2).

**Scope rulings (D38, recorded at merge; the orchestrator copies the "Rulings" section at the end):**
- **In:** design §8 row 4 in full for the player's side — **every** spell 0–7 and player shot (ids 0–7, 0x3c, 0x50,
  0x5a, the type-100 stab), **every** item use 0–26, **every** Bonus type, **every** power-up, the glider (only placed
  on level 20, but its rows, steering and pickup are the player's — Phase 2 named them Phase 4), the HUD from G;
  design §9 (c) (copied as the code permits it); the Box mechanisms placed on levels 1–4 plus the design row's named
  set (crates, chests, doors, keys, switches, teleporters); the Effect ids these spawn; the Phase 2 / Phase 3 carries
  under "Carries owned".
- **Out (later phases, named):** enemy Handles, Hits and Kills (**Phase 5**: shots, the stab, Statue, Smiting and the
  big explosion pass through or ignore enemies until then — their damage is applied by the enemy's own Hit routine),
  enemy shots (Phase 5: the boulder spouts' 0x6e1/0x6e2, the shields' `.ShieldBlock` reflections, the Pentashield's
  enemy-shot kills), geysers (Phase 5, design §9 (b)), bosses and `.Victory` (Phase 6: gates with p1 = −1, falling
  rocks 1075/1076, track 30), Box/Background types first placed on a level ≥ 5 (the phase that widens `BuiltLevels`
  past 4 — Phase 6; listed in "Stand-ins kept"), the debug "give items" kit (bank out-of-scope).
- **`BuiltLevels` widens to 1...3 at LV3 and 1...4 at LV4** (Ruling 2): level 5 (Manditraki Warrior, a boss) stays
  refused with the D35 report; levels 10+ are reachable only through level 5's exit.

**Architecture (design §3, unchanged in shape).** `FerazelCore` gains the sprite classes this phase owns as Swift
transcriptions beside Phase 2's movers (`World/Movers/{BonusSprite,ButtonSprite,StatueSprite}.swift`, the Box arms in
`BoxSprite.swift`, the Effect ids in `Player/GroundCeilingEffects.swift`'s `EffectSprite`), the player-shot class
(`Shots/`), the inventory and item use (`Items/`), the light table (`Lights/LightTable.swift` — moved into Core: it is
game state the `+0x89` sprite light and every Handle read and write), `.UpdateSprites` in full, a live-voice query
(`Sound/SoundVoices.swift`) and three new modal moments inside the frame (the upgrade animation, the teleport, the USE
hints). `FerazelRender` gains the HUD from G (`StatusBar`), the mask-port flash, the mosaic and executes the new
`DrawOp`s. `Ferazel/App` passes the mixer's playing set (`CoreTextRasterizer` already maps font 3 to Geneva — no font
change). **HectorKit:
untouched this phase** (Ruling 10).

**Tech:** Swift 6.4 / Xcode 27 beta, SwiftPM tools 6.0, XCTest, macOS 15, xcodegen.

**Paths:**
```
WT      = /Users/andiyar/Developer/Ambrosia-Classics/.claude/worktrees/<lane worktree>   (branched from Classics main)
HK      = /Users/andiyar/Developer/HectorKit   (main 35a85ba, zero-skip FLOOR 361; read-only this phase)
SCRATCH = the executing session's scratchpad directory (mktemp -d)
DUMPS   = $WT/ghidra/ferazel/Ferazel_pef.decompiled.c ("M l. N"), Ferazel_handlers.decompiled.c,
          Ferazel_pef.disasm.txt ("raw XXXXXXXX") — committed; never regenerated in this phase.
          Function finder: python3 $WT/ghidra/find_func.py '<regex>' --file <dump>   (--func <exact name> prints one)
          Bank tools: FZ_PEF=$WT/ghidra/ferazel/Ferazel_pef python3 $WT/docs/ferazel/tools/{const,pef,tocrefs,rsrc_census}.py
CORE    = $WT/Ferazel/Core/Sources/FerazelCore      RENDER = $WT/Ferazel/Core/Sources/FerazelRender
TESTS   = $WT/Ferazel/Core/Tests/{FerazelCoreTests,FerazelRenderTests}      APP = $WT/Ferazel/App
```
(Files lists below are relative to `Ferazel/Core/` unless they start with `Ferazel/App/` or `docs/`.)

---

## Verification model (read first)

**Machine gates — executors close these alone** (copy the fenced commands literally):

| # | gate | expected |
|---|---|---|
| G1 | HectorKit | clean at `35a85ba`, floor 361, **untouched by every task** (no HK change this phase; no HK D-number) |
| G2 | `Ferazel/Core` suite | the task's ladder total, then `0` |
| G3 | census unchanged | `0`, `Totals: items 1,108 decoded, failures 0` (once per wave end) |
| G5 | app builds | `** BUILD SUCCEEDED **` — the `Ferazel` scheme in every task touching `Ferazel/App` or `project.yml`, and every wave end. No task changes `project.yml` or HectorKit, so no other app is rebuilt (Ben 2026-10-09) |
| G6 | scope fence | ⊆ the task's **Files** (+ `docs/DECISIONS.md` / the bank file the task's BC names) |
| G7 | layering | both greps empty (`Sources/ferazel-census` excluded); **G7b:** no `UserDefaults`, `NSSavePanel`, `NSOpenPanel` in `Ferazel/Core/Sources` |
| G8 | file hygiene | `git -C "$WT" status --porcelain --ignored -- Resources ghidra` prints nothing new; tests write files only under `FileManager.default.temporaryDirectory` |
| G9 | staged app boots (A4 only) | Phase 3's G9 (pid line after 5 s, a clean quit, no new crash report) |
| G10 | clean tree per commit | empty |

```sh
WT=$PWD; SCRATCH=$(mktemp -d)
# G1 HectorKit untouched (no Phase-4 task changes it)
git -C ~/Developer/HectorKit status --porcelain; git -C ~/Developer/HectorKit log --oneline -1      # empty; 35a85ba
# G2 suite: first number = the ladder total (table below), second = 0
cd "$WT/Ferazel/Core" && swift test > "$SCRATCH/fz.log" 2>&1; grep -cE "^Test Case '.*' (passed|failed|skipped) \(" "$SCRATCH/fz.log"; grep -cE "^Test Case '.*' (failed|skipped) \(" "$SCRATCH/fz.log"
# G3 census (once per wave end, and whenever Resources/ or a decoder changes): 0 and the Totals line
cd "$WT/Ferazel/Core" && swift build -c release --product ferazel-census > /dev/null && "$(swift build -c release --show-bin-path)/ferazel-census" "$WT/Resources/Ferazel" > "$SCRATCH/census.md"; echo $?; tail -n 1 "$SCRATCH/census.md"   # 0 / Totals: items 1,108 decoded, failures 0
# G5 app builds (every task that touches Ferazel/App or project.yml; always at a wave end): ** BUILD SUCCEEDED **
cd "$WT" && xcodegen generate --quiet && xcodebuild -scheme Ferazel -derivedDataPath "$SCRATCH/dd" build 2>&1 | grep -E "BUILD (SUCCEEDED|FAILED)"   # tail -n 1 prints a blank line
# G6 scope fence: ⊆ the task's Files (+ the DECISIONS / bank file it names)
git -C "$WT" diff --name-only "$TASK_BASE"..HEAD        # TASK_BASE = the commit the task started from
# G7 layering + G7b: all three greps empty (Sources/ferazel-census excluded)
grep -rlE '^import (AppKit|CoreGraphics|AVFoundation|Metal|QuartzCore|SwiftUI|UIKit)' "$WT/Ferazel/Core/Sources" | grep -v ferazel-census
grep -rnE 'UserDefaults|NSSavePanel|NSOpenPanel' "$WT/Ferazel/Core/Sources"
# G8 file hygiene: nothing new
git -C "$WT" status --porcelain --ignored -- Resources ghidra
# G10 clean tree after every commit: empty
git -C "$WT" status --porcelain | grep -v '^??'
# G9 staged app boots (A4 only; D34 authorizes the launch). First `bash tools/stage-ferazel.sh` (Release build,
# data copied in, ad-hoc signed → "$WT/out/Ferazel/Ferazel's Wand.app", also ditto'd to ~/Desktop); then: pid line printed
# after 5 s, the second pgrep prints nothing (clean quit), and no new "Ferazel" crash log in the listing
APP="$WT/out/Ferazel/Ferazel's Wand.app"; open -n "$APP"; sleep 5; pgrep -fl "Ferazel's Wand" | cut -c1-100; osascript -e 'tell application "Ferazel'"'"'s Wand" to quit'; sleep 2; pgrep -fl "Ferazel's Wand"; ls -t ~/Library/Logs/DiagnosticReports | head -n 3
```

**Expected G2 at each wave end** (the run boundaries, "Execution order"): 4.0 **357** · 4.1 **374** · 4.2 **390** ·
4.3 **406** · 4.4 **425** · 4.5 **438** · 4.6 **451** · 4.7 **467** · 4.8 **481** · 4.9 (phase end) **481**.

**Test ladder (`Ferazel/Core`, cumulative; canonical order = execution order; STOP if different):** base **349** →
X1 **349** → VS **352** → LT **357** → US **362** → IV **368** → HU **374** → BN **382** → PK **390** → EF **397** → CS
**406** → SH **414** → GL **419** → PU **425** → IU **433** → MS **438** → SD **443** → BX1 **451** → BX2 **457** → BT
**463** → TP **467** → SW **473** → LV3 **477** → LV4 **481** (A4: no tests; fix round A+B: SW after BX1, GL/PU into 4.4,
SD into 4.6, CS +1, TP −1, LV4 +1; Fable round: LV3 back to ⚑, TP into 4.7, SW into 4.8). Merged in another order: previous total
+ the task's N. Review fix rounds add asserts, not tests, unless the orchestrator rules otherwise (recorded "As
executed").

**Goldens (◈).** Phase 1–3 goldens (STATE: `9db8f32f7e3d88b4`, `b80b0efd384ffdb9`, pan `172596fa2f3b6c58` /
`cc9786ba763d383a` / chain `b4230ba5a643c5b5`; L2 `565e867a02736c18` / `df22325e851e782d`, jump `e4f4bf977dd98eaa`,
swim `95ff5176412df650`, 600-frame `9532d65a42d39666` / cues `a875a96c2801dbe9`; FE0 `ed142fed9e3bdce7`, map
`38563faaa2276f05`, map RNG `0x7b052a62`, sign frame `c8e41941c1e4d6da`). **Only the tasks marked ◈ may move a golden,
and only for the cause they name**: BN (the Bonus Handles start running on levels 1–2: Xichron, torch, crystal,
coin and sphere faces animate, their lights flicker, the torch's spark `FastRand` draws enter the stream), PK (a
scripted golden that walks through a pickup now collects it), BX1 (the Box common tail runs: crates and the boulder
settle under gravity 0x100 and friction), BX2 (chest lids and the key balloons near a locked chest or door). Each ◈
task lists every golden's old → new value in its commit body and its "As executed" note, and its reviewer re-derives
each new value twice and confirms the cause (the moved frames differ only where the named sprites draw, or the RNG
shift starts at the named draw). Every other task — and a ◈ task for any other golden — **must not move a golden or a
count** (Invariant 10: STOP, reconcile, record). Expected to hold through the whole phase: FE0 `ed142fed9e3bdce7` and
the map first frame `38563faaa2276f05` (no level frame in them); the rest are checked at each ◈ task.

**Honesty gate (Ben only):** the Phase 4 gate card ("first levels as the original allows"). Completion is phrased
"machine gates green; Ben's gate pending".

**What the machine does NOT prove:** the colourised `CopyBits` of the item flash and the pickup bar flashes
(QuickDraw's colourise of an indexed copy, MED), Geneva 9/8 drawn by CoreText, the feel of casting and the glider,
the mosaic's look (MED: `.MosaicScreenBlit`'s block averaging), the timing of the 2-second upgrade animation and the
teleport mosaics at 60 Hz; agents cannot screenshot on this machine.

---

## Non-negotiable invariants

1. **Layering** (Phase 3 Invariant 1 + G7b). Core: Foundation + HectorResources (+ HectorInput for the pad layout)
   only. The light table, the inventory, the voice query are Core state; pixels, fonts, the mosaic and the flash
   copies are Render's; the App only presents, plays and passes the mixer's playing set.
2. **Transcribe, don't reinvent.** Every behaviour cites its bank section and the dump. A contract here never
   overrides the dump: if they disagree, STOP and report; the orchestrator rules under "follow the binary" and
   records a bank correction.
3. **Frame order is the binary's** (design §3.2; platforms-ropes-radial-2 §8): sprites created inside a Handle are
   handled this frame only if inserted after the saved `next` (`.MTHandleSprites`, raw `100325b8..100325d4`;
   spells-detail-2 §4); a Setup runs inside `.MTNewSprite` before `.MTInsertSprite` (raw `10033210..1003322c`), so a
   Setup's own `FastRand` draws and its followers precede the caller's next draw.
4. **One RNG stream** (Phase 2 Invariant 4, Phase 3 Invariant 5): every `FastRand` at its call site in the binary's
   order — a Setup's draws inside `MTNewSprite`, `STPlay3DSoundRand`'s `FastRand(10000)` even with sound off. **An
   idle-only call** (`if (!FUN_100916dc(snd)) STPlay3DSoundRand(…)`) draws only when the call is made, decided by
   `SoundVoices` (VS, Ruling 5) — never "always" or "never".
5. **Modal moments happen where the original has them** (Phase 3 Invariant 6): the upgrade animation (1340/1341)
   and the teleport run **inside** the special collision pass; the USE hints (`.SimpleConv(4001, "Ferazel", …)`) run
   **inside** the player's Handle at `.HandleKeys`' item switch. The session suspends at that point
   (`FrameSuspension`), the flow runs the modal over ticks, and `resume` finishes the **same** frame (Ruling 6).
6. **Stubs are named** (`// later: <phase>`), never simplified away. This phase's ◇ are listed in "Stand-ins kept";
   each keeps the original's surrounding draws and state (e.g. a spout's timer runs and its velocity draws are made
   even though its boulder is not spawned).
7. **No modern affordances.** No auto-select of a new spell beyond the original's highlight, no casting while the
   original swallows the press, no ammo display the original lacks, no pickup magnet, no "you got X" text beyond the
   original's. Deviations forced by the platform are in "Known deviations" and nowhere else.
8. **Persistence is the original's.** Records change only through `.UpdateSprites`' write-back and the writers the
   binary has (record p1/p4 stores of doors, chests, containers, Buttons, the save point); the save block snapshots
   them (SV1) — so a collected pickup or an opened door is gone/open after a save-point resume exactly as the original.
9. **Seam types are LOCKED** (design §3): cases and fields may be **added**, never renamed or retyped. This phase adds
   exactly the S3 list. `SpriteSlot.dead` keeps its name and type (computed over the new `+0xe9` count, US).
10. **STOP on any unexpected number** — test totals, hashes, census lines, the numbers in this plan. Report; never
    edit an expectation or the code to make them agree.
11. **Commits.** Explicit paths only; never `git add -A`/`.`; never `git stash`; verify `git branch --show-current`
    before every commit; trailer `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. G10 after each commit.
12. ⚠️ **Landmines** (Phase 2 Invariant 12 (a)–(g), Phase 3 Invariant 14 still apply). (h) D-number: this plan's
    rulings are **D38** — confirm it is free at commit time, renumber in the same commit if taken. (i)
    `Ferazel/FerazelCore` is a symlink to `Core`; the app name has an apostrophe — quote every path. (j) Swift `>>`
    binds tighter than `&*` / `&+` (F2 review bug). (k) A `SpriteSlot` copy held across a call that can create or move
    sprites and written back loses their writes (`SpriteWorld.swift` rule 2) — Bonus/Box/shot Handles create sprites.

### Hazards for every implementer (read before any dump reading)
Phase 1–3 hazards apply verbatim (`lwzu/stwu` +8 copy loops; a TOC-load count is not a write count; SSH zeroes
per-frame fields; the signed-compare idiom; live key reads; globals vs fields; nested blocking loops become explicit
states). Added for Phase 4:
- **Sound handles are TOC slots, not ids.** `*_DAT_100a0424` is `snd 300`; the complete slot → id map is
  pickups-boxes-2 §1.2 (e.g. `a03dc` = 421, `a03e0` = 420, `a02d4` = 501, `a037c` = 451, `9fdec` = 435). Cite both.
- **The cast sound comes first.** In each `.CastSpell` case the `STPlay3DSoundRand(snd 300)` precedes `MTNewSprite`
  (M l. 46727 for case 0), so its `FastRand(10000)` precedes the shot Setup's `FastRand(5)`.
- **`+0x04` vs `+0x170`.** `.SetupPlayerShotSprite` splits the composite spawn type: `+0x170 = type & 0xff` (power),
  `+4 = (char)(type >> 8)` (spell id) — every reader after Setup sees the id (spells-items §2 item 3).
- **Handles that store `+0x80` directly do not re-sort** the list; only `.MTChangeSpriteLayer` does (spells-detail-2
  §4) — reuse `SpriteWorld.changeLayer` only where the binary calls it.
- **Colourised copies.** `RGBForeColor(c)` before an indexed `CopyBits` colourises it (QuickDraw srcCopy with a
  non-black foreground) — the item flash and the bar flashes [MED]; QuickDraw's `ForeColor(0x21)` = black, `0x1e` =
  white (classic colour constants).
- **The mask port.** `_DAT_100a0008` is the 640×416 mask port (`FramePorts.mask`: 0xFF where the parallax shows); the
  `_DAT_100a00fc` flash copies it to the screen on alternate frames (M l. 9437–9447) — not a screen shake.
- **No free record (Ruling 16).** `.MTNewSprite` returns 0 without running the Setup when all 700 records are in use;
  `.CastSpell`, `.SmiteEnemies`, `.KillCrate` (and the other spawners) then store through the null pointer unguarded.
  The replica: `newSprite` returns nil, no Setup runs (none of its draws), every store meant for that sprite is
  dropped, and the caller's own later draws are still made — as BC46 rules for the hurt coins.
- **Record index 0x200.** Sprites spawned by code with record 0x200 read their "record" at `hdr + 0x2008..` (zero in
  every level, pickups-boxes §2.4.1) — a crate's sphere drop falls (p1 0) and an Invincibility sphere from a crate
  hides 32000 frames. Model the read as zeros for indices ≥ 0x1ff, never an out-of-range trap.

---

## Shared architecture (LOCKED — every task codes against these names)

### S1. Package `Ferazel/Core` — unchanged targets
New folders: `Sources/FerazelCore/{Lights,Items,Shots}/`; new files named per task. No new target, no
`Package.swift` change.

### S2. FerazelCore additions (★ LOCKED after Phase 4; ◇ = Phase-4 stub, replaced later)
- ★ `LightTable` (LT, `Lights/LightTable.swift`) — the 200 slots at `_DAT_100a0128` (0x30 B each; lighting-tables
  §7.4) as Core state: per slot `active` +0, `isNew` +1, `removing` +2, `face: LightFaceRef?` +4 (pict, width, height),
  `previousFace` +8, point `y` +0xc / `x` +0xe, previous point +0x10/+0x12, `radius` +0x14, previous +0x16, `colour`
  +0x18, previous +0x1a, fixed `x256` +0x1c / `y256` +0x20, speed `vx` +0x24 / `vy` +0x28, `accelY` +0x2c; the count
  `_DAT_100a0124`; the row-redraw countdown `_DAT_100a012c` stays Render's. Operations (M l. 14275–14556):
  `mutating func add(face:x:y:vx:vy:accelY:colour:) -> Int16` (`.AddLight`: the loop stores `iVar5 = i` and jumps
  to 200 at the first `+0 == 0`, so the **first** free slot — a slot whose removal is pending (`+2 = 1`, `+0` still 1
  until the next `handleLights`) is not free; nothing stored when full or the face is nil — the original's
  `ReportError(…, 200)` — and the return is the loop's index either way: −1 when full, the first free slot when only
  the face is nil (raw `1001bc58..1001bd08`, both paths end at `or r3,r31,r31`) (corrected, LT as executed); stores `+0 = 1`, `+1 = 1`, `+2 = 0`, `+8 = nil`, radius = face width >> 1, count + 1),
  `remove(_ slot: inout Int16)`
  (`.RemoveLight`: in range → `+2 = 1`, face nil, radius 0, count − 1; always `slot = −1`), `changeFace`, `setPos`,
  `changeSpeed`, `changeColor` (each ignores a slot outside 0…199), `handleLights()` (the slot loop of
  `.HandleLights`, M l. 14488–14520: `removing` → `active = false`; else `isNew = false`, previous ← current,
  `x256 += vx`, `y256 += vy`, `vy += accelY`, the point from `x256 >> 8` / `y256 >> 8`), `removeAll()`.
  `FerazelSession.lights` (the Setup list) stays; the Setup lights are added through the table in `.SetupLevel` order.
- ★ `SoundVoices` (VS, `Sound/SoundVoices.swift`) — the answer to `FUN_100916dc(snd)` at a call site: the playing set
  the shell passed for this iteration ∪ the cues emitted earlier in the iteration − the sounds stopped earlier in it.
  `FerazelSession.step(keys:capsLock:playing:)` (`playing: Set<Int16> = []`, so every existing caller and test is unchanged);
  `FrontInput.playing: Set<Int16>` (default empty) carried by `LevelRun` into the step.
- ★ `SpriteSlot` fields added (US unless noted; Invariant 9): `killCount: UInt8` (`+0xe9`; `dead` becomes computed:
  get `killCount != 0`, set true → `max(killCount, 1)`, false → 0), `killedForGood` `+0xea`, `keepRecord` `+0x188`,
  `noWriteBack189` `+0x189`, `noWriteBack18a` `+0x18a`, `keepRecordAtKill` `+0x18b`, `countedInTotals` `+0x1b5`,
  `idleEntry: Int16` `+0xa8` (−1 none); later tasks add theirs under their offsets (BN `pickupDelay` `+0xb0`,
  `bonusP4` `+0x168`, CS `shotAge` `+0x14c` reuse, `power` `+0x170`, `followers` `+0x1d4..+0x1e0`, …) — every field
  documented with its offset; no field reused for two offsets.
- ★ `Inventory` (IV, `Items/Inventory.swift`) — `extension GameGlobals`: `hasItem(_ id: Int16) -> Bool` (`.HasItem`
  / `.HaveItem`, identical bodies M l. 43534–43557 / 39710–39733), `hasItemWhichSlot(_:) -> Int?` (M l. 43558–43582),
  `mutating removeItem(_:) -> Bool` (`.RemoveItem`, M l. 39602–39663; true = found, the caller then emits the
  `.UpdateItemStat`), `mutating moveSelectedItemToFront() -> Bool` (M l. 39664–39709; true = moved, the caller emits
  `.UpdateStatusBar(1,1,0)`), `mutating addItem(_ id: Int16, count: Int16)` and `mutating learnSpell(_ id: Int16) ->
  Int` (the pickup arms' slot search, PK), `mutating stepSelection(next:previous:repeat:) -> Bool` (`.UpdateStatusBar`'s
  key block, M l. 4885–4912). `ConvActions.removeItem` becomes a call to it.
- ★ `StatusBarState` fields added (HU): `inventory: [InventorySlot]` (27), `maxHealth`, `maxMagic`, `suffocation`,
  `healthFlash` (`PTR_DAT_1009fdbc`), `magicFlash` (`_DAT_1009fdb8`), `itemFlash` (`PTR_DAT_1009fda8`),
  `itemFlashSlot` (`_DAT_1009fda4`), `itemFlashMode` (`_DAT_1009fda0`), and `call: StatusBarCall` = `{ partial: Bool
  /*param_1*/, forceItems: Bool /*param_2*/, forceBars: Bool /*param_3*/, itemsOnly: Bool /*a direct .UpdateItemStat*/,
  textOnly: Bool /*a direct .UpdateTextStats(0)*/, stepped: Bool /*the key block stepped this call*/ }` — every field
  defaulted so `StatusBarState(...)` call sites compile unchanged. `GameGlobals.statusBar(levelName:)` fills them.
- ★ `SpriteHandler` cases added: `.bonus` (BN), `.playerShot` (CS), `.heldItem` (IU), `.statue` (SW), `.button`
  (BT), `.shadow` (SD), `.trail` (PU). `forClass(type:)` returns `.bonus` / `.button` for those classes from their tasks.
- ★ `FrameSuspension` cases added: `.upgrade(type: Int16)` (PK), `.hint(text: [UInt8])` (IU), `.teleport(record:
  Int, stage: Int)` (TP; stage 1 = the out-mosaic, 2 = the in-mosaic); `Outcome` cases `.upgrade`, `.hint(keys: KeyState, capsLock: Bool)`, `.teleport`.
- ★ `ScreenFlash` (EF, `Particles/ScreenFlash.swift`) — `_DAT_100a00fc` (count) and `_DAT_100a00cc` (toggle), stepped
  in `.PaintFrameWrap` (M l. 9437–9443); `Camera` gains the shake counter `_DAT_1009ffa0` (engine §5).
- ◇ `BuiltLevels.range` — `1...3` (LV3), `1...4` (LV4); the not-built report names "(Phases 5-6)" from LV4 (Ruling 2).

### S3. Seam additions (cases/fields ADDED only; Invariant 9)
```swift
// DrawOp — new cases
case lightTable(LightTable)          // LT: Core's table as `.DrawLightsOntoTiles` reads it (emitted before that op
                                     //     every drawn iteration, also when Effects == 3 skips the op)
                                     //     (corrected, LT as executed: emitted before .redrawScrollGrid — the strip's
                                     //     tile lights read it — on every .PaintFrameWrap)
case copyMaskToScreen(h: Int, v: Int, graphicsMode: Int, backdrop: Bool)
                                     // EF: `.WrapCopyToScreen(*_DAT_100a0008, …)` while the flash toggle is on
case mosaic(cell: Int, graphicsMode3: Bool)
                                     // TP: one `.MosaicScreenBlit(cell, mode == 3)` of the last copied frame
// StatusBarState — fields in S2 (HU); DrawOp.statusBar unchanged
// FrameSuspension — .upgrade(type:), .hint(text:), .teleport(record:stage:); Outcome .upgrade, .hint(keys:capsLock:), .teleport
// FrontInput — playing: Set<Int16> = []   (VS)
// SpriteHandler — .bonus, .playerShot, .heldItem, .statue, .button, .shadow, .trail
// SoundCue, MusicCue, ShellRequest, FrameOps — unchanged
```

### S4. FerazelRender additions
- `FrameRenderer` executes `.lightTable` (its `LightRenderer` slots replaced by Core's values, faces from its cache;
  its `.HandleLights` slot step calls `LightTable.handleLights()` on that copy — one implementation), `.copyMaskToScreen`
  (the mask port through the screen copy, parallax/graphics as `.copyToScreen`), `.mosaic`.
- `StatusBar` draws from `StatusBarState`: G's inventory (not `startInventory`, which is deleted), G's maxima, the
  counts, the flashes, the `call` flags (HU).
- `Frame/Mosaic.swift` — `.MosaicScreenBlit(cell, mode3)` (M l. 12854–12943) over the screen's 608×384 view (TP).

### S5. App
`FerazelController` passes `SoundTool`'s playing set (`isPlaying(snd:)` over the ids it has started — a
`playingSounds() -> Set<Int16>` accessor added to `SoundTool`, Render) into `FrontInput.playing` each tick (VS);
`CoreTextRasterizer` already maps font id 3 to Geneva (`CoreTextRasterizer.swift:16`) — HU changes no App file. Nothing else: suspensions present through the existing
`present: true` path.

---

## Tasks

Legend as Phase 3: ⚑ MAJOR = **two Opus review legs** (spec/fidelity, then quality/mutation); minor = one Opus leg;
◈ = may move a golden (Verification model). "→ N" = ladder total after the task. Sections are in the canonical order,
which is the execution order. Every task: G2, G6, G7(+b), G8, G10; G3 once at each wave end; G5 in every task that
touches `Ferazel/App`, and at every wave end. **All implementers and reviewers are Opus 5.5 (D34).** Each task's
precondition: read the named bank sections, then **re-read the named dump ranges** before writing code (the digests
A–F of Phase 3 do not exist; the plan's numbers are the planner's reading of the bank + dump, not a substitute).
**Faces of run-time-spawned sprites (fix round B5):** `FrameRenderer` loads sheets only for the placed records plus
fixed lists, and a sprite whose face is not loaded draws nothing, silently. Every task that spawns a type at run time
(drops, debris, keys, balloons, trunks, floes, Effect ids, shots, orbs, held items, the Mist body, the trail, the double)
adds that type's sheet to the renderer's sheet table (`FrameRenderer.swift` / `FaceSheet.swift`, and `SetupFaces`'
sheet list where the face is a Setup's) and names the additions in its "As executed" note; LV4's
`testEverySpawnableTypeHasSheet` pins the whole set at the end.
**Files lists name every flow / App / renderer seam the task touches** (NEXT lesson 7); a file found missing during
the task is added and recorded in "As executed" (G6 then reads the amended list).

### Wave 4.0 — foundations (nothing visible changes)

#### X1 — minor — carry sweep (→ 349)
- **Files:** `Sources/FerazelCore/Sprites/SpriteSlot.swift` (l. 135), `Sources/FerazelCore/Session/SpriteWorld.swift`
  (l. 57, 297), `Sources/FerazelCore/Player/Player.swift` (l. 17), `Sources/FerazelCore/Physics/RectBounce.swift`
  (l. 155), `Sources/FerazelCore/World/Movers/BoxSprite.swift` (l. 36), `Sources/FerazelCore/World/Movers/BackgroundSprite.swift`
  (l. 25), `Sources/FerazelCore/Physics/TileHotRects.swift` (M7).
- **Contract:** no behaviour change. (1) The stale "later: W1/W3/W4/P2" comments (Phase 2 task names; STATE "Carried
  minor follow-ups") are relabelled to what they are now: built (cite the Phase 2 task) or the Phase-4/5/6 task of
  this plan that owns the rest (e.g. `BoxSprite.swift:36` → BX1/BX2/BT/TP; `BackgroundSprite.swift:25` → built W2b).
  (2) **M7** (D33 carry): `TileHotRects.init(level:)` reads the file's FG kinds beside the runtime grid; its only
  production builder is `SeparateFromTiles.swift:80` (`TileHotRects(fgKind: kinds.fgKind(tile:))`). The implementer
  greps `Tests/` — no caller → delete it; a test caller → keep it documented as the file-table convenience for tests
  ("never the runtime table"). Recorded in the commit body.
- **Tests (0).** **Gate:** G2 = 349, G6, G7(+b), G8, G10. **Commit:** `Phase 4 carry sweep: stale Phase-2 later-stubs relabelled, TileHotRects(level:) (M7)`.
- ⚑ **As executed (X1, loop run 19, 2026-10-24; ad91474, seat-read diff):** G2 349/0. Seven stale stubs relabelled to built (W1/W2b/W3/W4/L1, cited) or to their owners (BoxSprite arms → SW, BX1, BT, SH/BX1 (0xb7d is the ice wall 2941, not a gate), Phase 5, Phase 6; `RectBounce` surface → Phase 6 rope bridge; `HitPlayerSprite`'s comment said P2 — the arms are W1/W2a/W2b/W3/S1/C1). M7: no caller of `TileHotRects.init(level:)` → deleted. Left: `SeparateFromTiles.swift:109` still names landed P2/W1–W3 (outside the Files list; carried).

#### VS — minor — the live voice query (→ 352)
- **Files:** `Sources/FerazelCore/Sound/SoundVoices.swift` (new), `Sources/FerazelCore/Session/FerazelSession.swift`
  (`step(keys:capsLock:playing:)`), `Sources/FerazelCore/Front/FrontIO.swift` (`FrontInput.playing`),
  `Sources/FerazelCore/Front/LevelRun.swift` (passes it to every `step`), `Sources/FerazelRender/Sound/SoundTool.swift`
  (`playingSounds() -> Set<Int16>`, under its lock), `Ferazel/App/FerazelAudio.swift` (owns the private `SoundTool`,
  `FerazelAudio.swift:31`; exposes its playing set), `Ferazel/App/FerazelController.swift` (fills `FrontInput.playing`
  from `SoundTool` each tick), `Tests/FerazelCoreTests/SoundVoicesTests.swift` (new).
- **Contract:** S2 `SoundVoices`. `FUN_100916dc(snd)` (the Sound Tool's count of voices playing `snd`; SoundTool
  `isPlaying(snd:)`, `SoundTool.swift:214`) is read at its call site as: in the shell's set at the iteration's start,
  or played earlier in this iteration and not stopped after (the `FrameOps.soundStopAt` interleave, S1 Phase 3), and
  not stopped earlier in this iteration after its last play. `SoundVoices.isPlaying(_:)` is the one query every
  idle-only site uses from now on (BT: the gate 2940, M l. 61047/61056; LV3: spikes 0x732/0x733, M l. 63199–63257);
  Which set a later pass uses: a `resume(_:)` takes the set of the tick that resumes it (a defaulted `playing:`
  parameter, `resume(_:playing:)`); the nested `.PaintFrameWrap` passes of pause and `.CheckGameLoopKeys`
  (`FerazelSession.swift:589–592`) use the set of the frame they run in, plus their own cues. The existing `SoundCue.onlyIfIdle` cues (`.CrunchTile`'s 423, `PlayerTiles.swift:282`) stay as they are (no draw
  behind them, so the shell's later decision is equivalent — recorded). The cannon site M l. 62997 (cannons with
  p1 ≠ 0, first placed on level 10) stays refused at Setup → carried to Phase 6 (Ruling 13).
- **Tests (3; numbers from the contract):** `testIdleQueryReadsShellSet` (snd 493 in `playing` → `isPlaying(493)`
  true, 494 false) · `testFrameCuesAndStopsCount` (a cue of 489 played earlier in the iteration → true; then a stop
  of 489 → false; a stop then a play → true; ordering by `soundStopAt`) · `testLevelRunPassesPlayingSet`
  (`FrontInput(playing: [421])` → the hosted session's `SoundVoices` sees 421 during that tick's step, empty on the
  next tick with an empty set).
- **Gate:** G2 = 352, G5 (touches the App), G6, G7(+b), G8, G10. **Commit:** `FerazelCore: the live voice query (SoundVoices; FrontInput.playing from the Sound Tool) for idle-only sound calls; 3 tests`.
- ⚑ **As executed (VS, loop run 19; 1b92b6b + fix round 63ce6af):** G2 352/0, G5 SUCCEEDED. Files added: `Session/SpriteWorld.swift` (the world carries the voice query — the Handles that will ask see only the world), `Tests/FerazelRenderTests/SoundToolTests.swift` (fix-round assert). Following the binary (M l. 78217, 78323–78378): a play with sound off or a nil handle takes no voice; a query or stop of an unloaded sound (nil handle, `param_1 == 0`) counts / stops every voice — Core and Render `SoundTool.stop` both (fix round; M l. 78341). A play refused because all 16 voices outrank it takes no voice (M l. 78265/78312) but counts in Core's query until the next tick's shell set (documented). `LevelRun` applies a tick's earlier plays/stops to the set a later resume or second iteration reads (faithful: in the original they are already on voices). One Opus leg MERGEABLE WITH FIXES (4/11 mutations survived) → asserts strengthened inside the 3 tests, every mutation now caught; seat read the behaviour change. Carried: the app's stop of a sound in the bank but never given a handle (602) or skipped by the F1 boot load stops only itself; `SoundTool.isPlaying`/`playingSounds` lack the nil-handle-counts-all rule.

#### LT — ⚑ MAJOR — the light table moves into Core (→ 357)
- **Files:** `Sources/FerazelCore/Lights/LightTable.swift` (new), `Sources/FerazelCore/Seams/DrawOp.swift`
  (`.lightTable`), `Sources/FerazelCore/Session/FerazelSession.swift` (owns the table; Setup lights added through it;
  emits `.lightTable` before `.drawLightsOntoTiles`; `dynamicLight` / `.GetFakeLight` read the table, `FerazelSession.swift:794–830`),
  `Sources/FerazelCore/Sprites/SetupFaces.swift` (`Light` → the table's `add`), `Sources/FerazelCore/Sprites/BonusHandle.swift`
  (the twinkle's `changeLightFace` also applied to the table), `Sources/FerazelRender/Frame/FrameRenderer.swift`,
  `Sources/FerazelRender/Frame/LightRenderer.swift` (its `LightSlot` table filled from the op; its slot step =
  `LightTable.handleLights()`), `Sources/FerazelRender/Frame/SpriteBlitter.swift` (only if it reads the slots
  directly), `Sources/FerazelRender/Screens/ScreenRenderer.swift` (the new case refused off a level, as `statusBar`),
  `Tests/FerazelCoreTests/LightTableTests.swift` (new), `Tests/FerazelRenderTests/LightingTests.swift` (one test added),
  every exhaustive `switch` over `DrawOp` (`FrameRenderer.swift`, `ScreenRenderer.swift`, `SessionTests.swift:288`).
- **Contract:** S2 `LightTable`, S3 `.lightTable`. lighting-tables §7.4–§7.5; M l. 14275–14556 (`.AddLight`,
  `.RemoveLight`, `.ChangeLightFace`, `.SetLightPos`, `.ChangeLightSpeed`, `.ChangeLightColor`, `.RemoveAllLights`,
  `.HandleLights`); `.PaintFrameWrap` order M l. 9196–9202 (`.SetScrollLocation`, `.DrawLightsOntoTiles` unless prefs+6
  == 3, `.HandleLights`, `.WrapDrawWaterEffects`, `.WrapDrawSprites`). The table is the single source of truth: Core
  mutates it at every call site (Setups, Handles, kills) in call order; the renderer receives the table **as it stands
  before this frame's `.HandleLights`** (`.lightTable`, emitted right before `.redrawScrollGrid` (corrected, LT as
  executed: the strip's tile lights read it) and so before `.drawLightsOntoTiles` — also emitted when Effects == 3 omits that op, since the sprite light pass reads it), runs the
  same `handleLights()` on its copy at its existing place (inside the `wrapDrawWaterEffects` arm), and draws; Core runs
  its own `handleLights()` at the same point of its frame. The `changeLightFace` op stays (Phase 1; the renderer applies
  it to its copy for the redrawn cell's light pass in the same frame, then the next `.lightTable` agrees). `.RemoveAllLights`
  at level start (`.SetupLevel`) = a fresh table. `LevelServices.attach(lights:)` and `FrameRenderer.addLights` stay
  (locked; now the same lights arrive twice in the same order — the renderer's `addLights` path must produce the
  table the first `.lightTable` op then confirms; a mismatch is a precondition failure in Debug).
- **◈ none — every golden and count must hold** (the same lights, the same order, the same steps): G2 = 357 with every
  Phase 1–3 golden test unchanged.
- **Tests (5; numbers from M l. 14275–14556):** `testAddTakesFirstFreeSlot` (slots 0, 1 active; remove 0 → slot 0
  still active with `removing`; the next add takes slot 2; after `handleLights()` slot 0 is free and the next add
  takes it; the count `_DAT_100a0124` follows +1/−1) · `testAddFullOrNilFace` (200 active → −1, nothing stored; a nil
  face with a free slot → that slot's index, nothing stored, the count unchanged (corrected, LT as executed: raw
  `1001bc58..1001bd08`)) · `testHandleLightsIntegratesSpeed` (point (100, 50), speed (0x180, −0x100), accel 0x20: after one step
  x256 = 100·256 + 0x180, the point x 101, y 49; previous fields = the old values; `isNew` false) ·
  `testSetupLightsGoThroughTable` (level 1, Effects 1: the session's table holds the 68 Setup lights (D26 R4) in
  slots 0…67 in `.SetupLevel` order with the faces/colours of `FerazelSession.lights`) · Render
  `testLightTableOpMatchesAddLights` (level 1: the renderer's slots after the first `.lightTable` equal those
  `addLights` built — face, point, radius, colour per slot).
- **Gate:** G2 = 357, G5 (wave 4.0 end), G6, G7(+b), G8, G10; wave end: G3. **Commit:** `FerazelCore: the light table (AddLight/RemoveLight/HandleLights) moves into Core; DrawOp.lightTable; 5 tests`.
- ⚑ **As executed (LT, loop run 19; f2416e9 + fix round 8925bba + 18e00de):** G2 357/0, G3 1,108/0, G5 SUCCEEDED; **no golden hash or count moved**. Following the binary: an add with a nil face and a free slot returns the slot and stores nothing (raw `1001bc58..1001bd08`; bank correction "BC (LT, loop run 19)" in `lighting-tables.md`; S2 text corrected); `.RemoveAllLights` clears four fields + the count. **Seat ruling (fix round):** `.lightTable` is emitted immediately **before** `.redrawScrollGrid` (not after) — the renderer draws the strip's tile lights inside that op and must read the current table; nothing between them mutates lights. The renderer's slot step is now `LightTable.handleLights()` (one implementation); the op is not logged in its executed-op list (hands over state, draws nothing). Files added: `Front/LevelRun.swift` (exhaustive switch; first-op order assert), `World/Movers/BackgroundSprite.swift` + `Particles/GroundCeilingEffects.swift` (light calls routed through the table: `.TurnIntoCannoned`'s `_RemoveLight` M l. 49966, the bubble's remove, the cannon smoke's faces + remove, the launch smokes' colour — no-ops on built levels, no Setup gives them a light), tests `SessionTests`, `LevelRunTests`, `PlatformTests`, `BackgroundMoverTests`, `FrameGoldenTests` (order filters and the "0x32a held" re-force after `.lightTable` — no expected value changed; both review legs judged them harness adaptations). `FerazelSession.lightTable` is `internal(set)` for tests. Two Opus legs MERGEABLE WITH FIXES (2 surviving mutations: renderer ignoring the op, sprite light reading the old list) → fixed; re-review MERGEABLE. Carried minors: `GroundCeilingEffects.swift:207` builds a small lookup per smoke frame; the list-form light helpers stay for PlatformTests.

### Wave 4.1 — sprites die, the inventory, the HUD

#### US — ⚑ MAJOR — `.UpdateSprites` in full (→ 362)
- **Files:** `Sources/FerazelCore/Session/SpriteWorld.swift` (`updateSprites`), `Sources/FerazelCore/Sprites/SpriteSlot.swift`
  (the S2 fields; `dead` computed), `Sources/FerazelCore/Sprites/ActiveList.swift` (unlink + slot free),
  `Sources/FerazelCore/Sprites/IdleSprites.swift` (the idle entry `+0xa8` cleared at the final kill),
  `Sources/FerazelCore/Session/FerazelSession.swift` (call site unchanged; the light removal through LT's table),
  `Sources/FerazelCore/World/Movers/BackgroundSprite.swift` (modes 10…14 set `keepRecord`, the "Core has no write-back"
  stub at l. 44 retired), `Tests/FerazelCoreTests/UpdateSpritesTests.swift` (new).
- **Contract:** `.UpdateSprites @ 1000982c` (M l. 4934–5037; spells-detail-2 §5; pickups-boxes §1.10), at its place
  after `.CheckGameLoopKeys` (unchanged). Walk from the head: (1) type 0x6ea → 0x6eb then −1 (a no-op as written:
  stays 0x6ea); (2) unless `+0x188`, `+0x18a` or `+0x189`, and 0 ≤ `+0x48` < 0x1ff: the record's type (`+6`), x
  (`+0x12` ← `+0xc`), y (`+0x10` ← `+0xa`) written back — `SpriteWorld.records`; (3) `+0xe9` < 4 and the Handle set:
  `+0xe9` == 0 → if `+0xea` (killed for good) and not `+0x188` and the index valid → record `+4 = 0` (inactive), next;
  else (1…3) → `+0xe9` += 1, hit/tile callbacks cleared, type = −|type|, face nil, light removed (`LightTable.remove`
  when `+0x9a` ≠ −1), record `+4 = 0` unless `+0x188`, next; (4) otherwise (`+0xe9` == 4, or the Handle 0 — an idled
  record): if `+0xe9` ≠ 0 → the light removed, a type that is ±0x41f restored to 0x41f, record `+4 = 0` unless
  `+0x18b`, the idle entry `+0xa8` (0…0x1ff) cleared; then `.MTKillSprite` and the walk **restarts from the head**. So
  a kill request survives three passes listed (Handles return at once on `+0xe9`) and is unlinked on the fourth. The
  record `+4` byte is `Placement`'s active flag; `SpriteWorld.records` is what SV1's snapshot saves (Invariant 8).
- **◈ none expected** — on levels 1–2 the only `+0xe9` writers are effects (1201 dust, 1210 crumble, rope parts,
  `ConvActions` action 9, `PlatformSprite.swift:940`), which draw nothing once dead; their unlinking changes no pixel or
  cue. **If any golden or count moves, STOP** (Invariant 10) and report which sprite's pass changed it.
- **Tests (5; numbers from M l. 4934–5037):** `testKillRequestUnlinksOnFourthPass` (a sprite with `+0xe9 = 1`:
  after passes 1, 2, 3 it is listed with `+0xe9` 2, 3, 4, type −t, face nil, callbacks cleared; after pass 4 gone and
  its slot free for `newSprite`) · `testRecordWriteBack` (a sprite moved to (300, 120) with record 7 → record 7 x 300,
  y 120, type t; with `+0x188` or `+0x189` or `+0x18a` set → record unchanged; record index 0x1ff → no write) ·
  `testKilledForGoodClearsRecord` (`+0xea` with `+0xe9` 0 → record `+4 = 0` the same pass, sprite still listed) ·
  `testKeepRecordFlags` (`+0x188`: count-up passes leave `+4 = 1`; `+0x18b`: the final pass leaves `+4 = 1`; idle
  entry 12 cleared at the final pass) · `testXichronTypeRestoredAndIdledRecordKilled` (a dying 0x41f is 0x41f, not
  −0x41f, when unlinked; an idled record (`handleCleared`) is unlinked on the first pass as today; type 0x6ea stays
  0x6ea).
- **Gate:** G2 = 362, G6, G7(+b), G8, G10. **Commit:** `FerazelCore: .UpdateSprites in full (kill passes, record write-back, keep-record flags); 5 tests`.

#### IV — minor — the inventory operations (→ 368)
- **Files:** `Sources/FerazelCore/Items/Inventory.swift` (new), `Sources/FerazelCore/Talk/ConvActions.swift`
  (`removeItem` → `Inventory`; action 2's slot search → `addItem`), `Sources/FerazelCore/Player/Player.swift` (row 25:
  the selected-slot repair, `Player.swift:268`), `Tests/FerazelCoreTests/InventoryTests.swift` (new).
- **Contract:** S2 `Inventory`; spells-items §1 (+ BC37). `.HasItem` / `.HaveItem` (M l. 43534–43557, 39710–39733):
  the first of 27 slots with id == A and `+8 == 0` (items only). `.HasItemWhichSlot` (M l. 43558–43582): that slot.
  `.RemoveItem(A)` (M l. 39602–39663): the first such slot's count − 1; below 1: the selection −1 (≥ 0) **only if it is
  that slot**, the slot emptied and slots after it moved down one (10 bytes each), the last slot (26) set to id −1,
  count 0, `+4` −1, `+6` 0 with its `+8` byte left as it was; then `.UpdateItemStat` (the caller's op, HU) — nothing at
  all when not found. `.MoveSelectedItemToFront` (M l. 39664–39709): selection ≠ 0 → that slot moved to slot 0, slots
  0…sel−1 down one, selection 0, then `.UpdateStatusBar(1,1,0)`. `stepSelection` (M l. 4885–4912): neither key 8 nor 7
  → the repeat counter `*_DAT_1009fd9c` = 0; else counter 0 → counter 12, selection +1 (key 8 held) or −1 (only 7);
  < 0 → 0x1a then down while that slot's id == −1; > 0x1a or an empty slot → 0; returns "stepped"; counter > 0 → −1.
  Row 25's repair (the slot's id −1 → the selection's fix as the dump reads at `Player.swift:268`'s cite). Action 2
  keeps its own search (conversations-mcnv §3.4: first slot empty **or** holding A with flag 0; count += B, cap 99).
- **Tests (6; numbers from the M lines above):** `testHasItemIgnoresSpells` (spell 1 in slot 0 → `hasItem(1)` false;
  item 1 in slot 3 → true, slot 3) · `testRemoveItemShiftsAndKeepsFlag` (slots [spell 0, item 0, item 1, item 4];
  remove 1 → [spell 0, item 0, item 4, −1…]; slot 26 `+4` −1, `+8` keeps its byte; selection 3 → stays 3; selection 2
  → 1) · `testRemoveItemCountAndMissing` (item 6 count 3 → 2, no shift; removing an absent id changes nothing and
  returns false) · `testMoveSelectedToFront` (selection 3 of [s0, i0, i1, i4] → [i4, s0, i0, i1], selection 0, true;
  selection 0 → false) · `testStepSelectionRepeat` (next held 14 calls from slot 0 of 3 filled slots: the counter goes
  12, 11 … 0, so it steps on calls 1 and 14 only; released for one call → counter 0, the next press steps at once) · `testStepSelectionWraps` (previous from 0 → 0x1a → down to the last
  filled slot 2; next from 2 → slot 3 empty → 0).
- **Gate:** G2 = 368, G6, G7(+b), G8, G10. **Commit:** `FerazelCore: the inventory (HasItem, RemoveItem, MoveSelectedItemToFront, the 7/8 selection step); 6 tests`.

#### HU — minor — the status bar from the game globals (→ 374)
- **Files:** `Sources/FerazelCore/Seams/StatusBarState.swift` (S2 fields), `Sources/FerazelCore/Session/GameGlobals.swift`
  (`statusBar(levelName:)` fills them), `Sources/FerazelCore/Items/StatusBarCalls.swift` (new: one Core function per
  `.UpdateStatusBar(p1, p2, p3)` call that runs the key step and builds the op), `Sources/FerazelCore/Session/FerazelSession.swift`
  (the in-level call sites M l. 5216, 5280), `Sources/FerazelCore/Front/{LevelRun,WorldMapRun,StageScreens,SaveGame}.swift`
  (their `.statusBar` sites: the map's M l. 67505, 67539, 67579, 67585 step the selection too — BC39),
  `Sources/FerazelCore/Talk/ConvActions.swift` (the direct `.UpdateTextStats(0)` / `.UpdateItemStat()` of M l. 66284,
  66311, 66325 → `textOnly` / `itemsOnly` ops; the ◇ "later: Phase 4 — UpdateItemStat" retired),
  `Sources/FerazelRender/Frame/StatusBar.swift` (G's inventory, maxima, counts, flashes; `startInventory` deleted),
  `Sources/FerazelRender/Frame/FrameRenderer.swift` (`full` = `!call.partial`, not "after a `setScreenClut`"),
  `Sources/FerazelRender/Screens/MapRenderer.swift` (the map's `.statusBar` ops, `MapRenderer.swift:143–150`: today
  always `full: true` — now `!call.partial`), `Tests/FerazelCoreTests/StatusBarCallTests.swift`
  (new), `Tests/FerazelRenderTests/StatusBarTests.swift` (three added).
- **Contract:** spells-items §6 + its "⚑ Phase-1 note (R6)"; `.UpdateStatusBar` M l. 4842–4921: param_1 == 0 → the
  whole 640×88 port copied (CT); `.UpdateHealthMagic(param_3 ? 1 : param_1)`; `.UpdateTextStats(param_1)`; the key
  step (IV); `.UpdateItemStat` unless (not stepped ∧ param_1 ≠ 0 ∧ param_2 == 0 ∧ `PTR_DAT_1009fda8` < 1).
  `.UpdateItemStat` M l. 4674–4841: the big icon of the selected slot (700 for a spell, 702 for an item) at
  (0xd7, 0x1e); a count > 1 → `NumToString`, Geneva (font 3) **plain 9 pt**, white (`ForeColor(0x1e)`): "x" (pstr
  0x100a1531) at (0xf5, 0x3e) then the number at (0xfb, 0x3e) for counts < 10, else (0xf2, 0x3e) / (0xf8, 0x3e); for
  each slot (the `== 2 ∧ +8` → 3 store is a **G write**, IV's `GameGlobals` — Core performs it when it builds the op)
  the small icon (rows 23…46, or 0…23 when selected) into box (0x10a + 23·(i mod 15), 0x1f + 23·(i / 15)), colourised
  while `PTR_DAT_1009fda8 > 0` for slot `_DAT_1009fda4`: s = flash − 1 (≥ 0), mode `_DAT_1009fda0` 0 →
  `RGBForeColor(s·0x5dc, s·0x5dc, s·0x5dc)`, 1 → `(s·3000, 0, 0)` [MED: QuickDraw colourise], then a count > 1 in
  Geneva **bold 8 pt** white: "x" at (left + 0xe, bottom) / number at (left + 0x12, bottom) for < 10, else (+9, +0xc);
  then only the **first** empty slot's box painted black (the loop's `sVar11 = 0x1b` break); the two copies to the
  screen. `.UpdateHealthMagic` M l. 4361–4580: G's maxima (not 0x230 constants), the flash counters and the
  suffocation tick as read (its colourised copies [MED]). The flashes' counters are decremented in row 13 (M l.
  44731–44736, `Player.swift`, already built) — HU only carries them into the state. The 12-call repeat counter
  `*_DAT_1009fd9c` is HU's: Core state in `StatusBarCalls`, stepped by every call (IV's `stepSelection` takes it
  inout). The nested-pass status-bar sites of the session (`FerazelSession.swift:558, 569, 612, 620, 673`) are named
  call sites with their own parameters. Font 3 is already Geneva in the App (`CoreTextRasterizer.swift:16`) — no App
  change. Replaces the Phase 3 ◇ "HUD
  shows `StatusBar.startInventory`" (C1).
- **◈ none** — at a new game G's inventory is the start inventory, so every golden's bar is the same pixels.
- **Tests (6; numbers from M l. 4674–4921):** `testCallSiteParams` (the level start's call is (0,0,0) → `partial`
  false; the per-iteration call (1,0,0); `moveSelectedItemToFront` → (1,1,0); a direct `.UpdateItemStat` →
  `itemsOnly`) · `testEveryCallStepsSelection` (next held on the map: `WorldMapRun`'s M l. 67579 call steps the
  selection 0 → 1 of [s0, i0]; held, the next 12 calls do not) · `testItemStatGate` (param (1,0,0), not stepped, no
  flash → no item redraw; flash 3 → redraw) · Render `testCountsDrawn` (slot 1 = item 6 count 3: the small icon box
  (0x121, 0x1f) gets the bold "x3" pixels at (0x121 + 0xe, 0x36) / (0x121 + 0x12, 0x36) from the test rasterizer; the
  selected slot 1's big count at (0xf5, 0x3e) / (0xfb, 0x3e); count 12 at (0xf2…) / (0xf8…)) · Render
  `testFirstEmptyBoxOnly` (3 filled slots → box 3 black, boxes 4…29 keep their old pixels) · Render
  `testMaximaFromGlobals` (max health 0x2a0 → the past-max segment starts at x 0xd6 + 0x54 = 0x12a, not 0x11c).
- **Gate:** G2 = 374, G5 (wave 4.1 end), G6, G7(+b), G8, G10; wave end: G3. **Commit:** `Status bar from the game globals: inventory, counts (Geneva 9/8), maxima, flashes, the 7/8 selection step at every .UpdateStatusBar call; 6 tests`.

### Wave 4.2 — pickups

#### BN — ⚑ MAJOR ◈ — the Bonus class (Setup, Handle, Hit, HitTile, Kill) (→ 382)
- **Files:** `Sources/FerazelCore/World/Movers/BonusSprite.swift` (new; absorbs `Sprites/BonusHandle.swift`'s twinkle,
  which stays as a thin forward so its existing tests keep passing), `Sources/FerazelCore/Sprites/SetupFaces.swift`
  (the `.bonus` arm calls `BonusSprite.setup` for every type 0x41f…0xcb0 the class owns — the Phase-1 per-type face
  table becomes the Setup's faces; the 1350 and 2000…2049 arms added; `notTranscribed` remains only for types no Bonus
  arm handles), `Sources/FerazelCore/Sprites/SpriteSlot.swift` (`SpriteHandler.bonus`; fields `pickupDelay` `+0xb0`,
  `bonusP4` `+0x168`, `coinLife` `+0x16c`, `inWaterAtSpawn` `+0x15c`, `lightTimer` `+0x14c` — reuse of an existing
  `+0x14c` / `+0x15c` / `+0x16c` field only where `SpriteSlot` already names that offset), `Sources/FerazelCore/Session/FerazelSession.swift`
  (the handle pass dispatches `.bonus`; **M6**: the guard at `FerazelSession.swift:403` — `classify(type:,p1Negative:
  false) == .bonus` — becomes `handler == .bonus`), `Sources/FerazelCore/Session/SpriteWorld.swift` (the collide pass
  calls `.HitBonusSprite`; the tile callback `.HitBonusTileSprite`), `Sources/FerazelCore/Physics/SeparateFromTiles.swift`
  (the Bonus tile-callback route, if the dispatch lives there), `Sources/FerazelCore/World/Movers/BackgroundSprite.swift`
  (the cannon capture refuses a Bonus with `+0x168 == 1`, `BackgroundSprite.swift:495` — A7),
  `Tests/FerazelCoreTests/BonusSpriteTests.swift` (new).
- **Contract:** pickups-boxes §1.1–§1.4, §1.9 (the coin lifetime), §1.10–§1.11; pickups-boxes-2 §1–§2, §4. Dump:
  `.InitBonusSprite` M l. 52261–52337 (faces), `.SetupBonusSprite` M l. 52338–52804 (every type arm, the `FastRand`
  draws in the order the planner-probe note in pickups-boxes §1.1 lists, raw `1005db3c…1005e8c0`, ending with the shared
  tail `+0x14c = FastRand(60)`), `.HandleBonusSprite` M l. 52805–53443 (returns on `+0xe9` or `+0x1b2`;
  `.StandardSpriteHandles`; a negative `+0xa6` counts up; every type arm: the Xichron cycle `+0x46` 0…19 face
  `+0x46 >> 1` of set 1057 and 1056's `+0xb8 = 0x10001`; the 11-step crystal glint; the 41-step money-bag glint; the
  coins' 18-step cycle; 1300/1301 zero `+0xa6`/`+0xb0` every frame; the dropped coin's `+0x16c` count-up from −240,
  blinking `+0xb8 = 0xb0000` on frames where `_DAT_1009fd30` ≠ 0 from −44 (`−0x2d < +0x16c`), KillBonus at 0, and the coin types killed
  below the level (`hdr+0xb282 · 32`); the spheres' hide (face nil, light off) while `+0xa6 > 0` counting down and the
  6-step `+0xb8`/light cycle while visible; the upgrades' ping-pong; the torch 0x51b and candelabras 3100…3109
  (`LAB_1005f00c`, M l. 53108ff: one `FastRand(100)` per Handle call and their spark/flame particles as written —
  prefs+6 gating), the torch light flicker `ChangeLightFace` 0x321 ↔ 0x322; the item twinkle (Phase 1); 1350's
  `+0x11c = 1`; the tail: friction `+0x114`, `ApplyGravityAndSeparateFromTiles` when gravity > 0 and the type is not
  0x517/0x41f/0x420, `.StandardSpriteCleanup`, the light following the centre (`SetLightPos`, LT) except 0x51b and
  0xc1c…0xc25), `.HitBonusSprite` M l. 53444–53536 (type 0x4bf returns at once, M l. 53468) **except** the player-shot container arm (`LAB_1005fd94`, SH builds
  it): the non-container rest on a Platform or Box (not the player, not a chest 0x51c, types < 2000 or > 0xc80) →
  `.PlatformBounce(bonus, other, own rect centre, f, rect, last)` with f = 0x80 and last = 1, or f = 0 and last = 0 when
  `vy < 0x180` (raw `1005ffb8..1005ffd0`: `(f == 0) − (~f >> 31) & 1`);
  `.HitBonusTileSprite` M l. 53571–53638 (the debug no-clip skip not built; FG → `.WallBounce` with 0x80 / 0x40 for
  0x50c/0x50d / 0xe0 for 0x4bf…0x4c1, FG kind 0x67 passed while `vy < 0`; the money bag's landing sound at `|vy| >
  0x100` (`_DAT_100a0300`, vol 0x55, `STPlay3DSoundRand`); BG < 100 `.WallBounce`, 100…199 `.WallBounceBG`, ≥ 200
  water → `.HandleUnderWater` unless `+0x140`; `param_4 == 2` clears `+0x118`), `.KillBonus` M l. 53537–53570 (not
  dying and `+0x1b5`: 0x41f/0x420 → `_DAT_1009ffb0` − 1 and `G+0x3ce+2L` + 1; 0x423 → `_DAT_1009ffac` − 1 and
  `G+0x496+2L` + 1; then `+0xe9 = 1` if 0; `RemoveLight(+0x9a)`). `.SetupLevelSprites` sets `+0x1b5` and the pending
  counts while `*_DAT_1009fe8c = 1` (pickups-boxes §1.10; `LevelRun`'s first-visit copy into `G+0x7b6`/`+0x87e`
  already exists — the implementer confirms it reads the Setups' counts).
- **◈ goldens** (Verification model): the Bonus Handles run from iteration 1 on levels 1–2 — expected to move: every
  golden of a level frame after iteration 0 where a Bonus sprite is active, and every golden downstream of a torch's
  `FastRand(100)` draw. Each recorded old → new with the cause; FE0 and the map first frame must hold.
- **Tests (8; numbers from the M lines above and pickups-boxes §1.3):** `testSetupDrawOrder` (0x516: R(9) → `+0x46`,
  R(6)+0x1c → `+0x112`, R(3)+2 → `+0x114`, R(60) → `+0x14c`; 0x50c: −R(10)−5 → `+0x46`; gravity 0x151, 1290 with p1 ≠ 0
  → 0) · `testXichronCycle` (1055 from `+0x46` 18: frames show cells 9, 9, 0 (20 → 0), 0; 1056 `+0xb8` = 0x10001 every
  frame; gravity never applied) · `testTorchDrawsWhileUnspent` (0x51b with `+0xb0 = 1`: one `FastRand(100)` per Handle
  call before its particle draws; with `+0xb0 = 0` the count of draws the dump makes for a spent torch — re-derived from
  M l. 53108ff and recorded) · `testDroppedCoinLife` (`+0x16c = −240`: no blink through −45; from −44 `+0xb8 = 0xb0000`
  on parity frames only; at 0 `+0xe9 = 1`; a coin below `hdr+0xb282·32` killed at once) · `testSphereHidesAndReturns`
  (1335 `+0xa6 = 450`: face nil and light off for 450 frames, visible again on the 451st) · `testRestsOnBoxes` (0x516
  falling at vy 0x200 onto a crate → `.PlatformBounce` factor 0x80; at vy 0x100 factor 0; onto a chest 0x51c → no
  bounce; a scroll 2000 → no bounce) · `testTileBounceFactors` (money bag 0x40; shard 0x4bf 0xe0; coin 0x80; FG kind
  0x67 passed while vy < 0) · `testKillBonusCounts` (a counted 1055 on level 2 → `G+0x3ce+4` + 1 and the pending count
  − 1; a counted 1059 → `G+0x496+4` + 1; a second KillBonus while dying counts nothing; the light slot freed).
- **Gate:** G2 = 382, G6, G7(+b), G8, G10. **Commit:** `FerazelCore: the Bonus class (Setup, Handle, rest on boxes, tile bounce, KillBonus totals); M6; goldens moved as recorded; 8 tests`.

#### PK — ⚑ MAJOR ◈ — the pickup arm of `.HitPlayerSprite`, the upgrade animation, the hurt drops (→ 390)
- **Files:** `Sources/FerazelCore/Player/HitPlayerSprite.swift` (the Bonus arm; the spirit-form gate's `.bonus` pass;
  `HurtPlayer.hurt`'s coin spawn), `Sources/FerazelCore/World/Movers/BonusSprite.swift` (shared helpers),
  `Sources/FerazelCore/Items/Inventory.swift` (`addItem`, `learnSpell`), `Sources/FerazelCore/Items/StatusBarCalls.swift`
  (the pickup refresh calls), `Sources/FerazelCore/Seams/FrameSuspension.swift` (`.upgrade`, `Outcome.upgrade`),
  `Sources/FerazelCore/Session/FerazelSession.swift` (suspend in the special pass; `resume(.upgrade)`),
  `Sources/FerazelCore/Front/LevelRun.swift` (runs the 120-tick animation), `Sources/FerazelCore/Player/PlayerState.swift`
  (the glider / mist / sphere state the arms write — fields only; their rows are GL, MS, PU, SD),
  `Tests/FerazelRenderTests/{FrameGoldenTests,Phase2GoldenTests}.swift` (their drivers return early on any
  non-conversation suspension — they resume `.upgrade`; counts unchanged), `Tests/FerazelCoreTests/PickupTests.swift` (new).
- **Contract:** pickups-boxes §1.2, §1.3 (touch effects), §1.6 (the sphere arm), §1.7, §1.8, §1.9; spells-items §3;
  pickups-boxes-2 §1.3 (every sound id). Dump: `.HitPlayerSprite` M l. 48445–49929 — the entry gates (dying
  `_DAT_100a069c > 0`; spirit form passes only the Bonus handler), the Bonus arm (`+0xa6 == 0 ∧ +0xb0 == 0`): 69 the
  Mist body (state for MS), 1055/1056 (score, `G+0x14`, the 100 rule **sets 0** — `10055ac4..acc` — and adds red
  Xichron 0x16 ≤ 99 to the first slot empty or holding 0x16, sounds 501 / 489 ×2 pitched / 451 / 445 / 501 vol 0x100, the
  `ExplodeFaceIntoParticles` burst by prefs+6, KillBonus through `+0x50`), 1058 (`G+0xad8 + 2·p1 = p2` or 1, KillBonus —
  **replaces the Phase 3 ◇ "1058 world flag never set"**), 1059 (p1 ≠ 0 → snd 505; KillBonus), 1290/1291/1292/1293,
  1300/1301/1302/1305/1306, 1340/1341 (below), 1350 (breath +0x230 ≤ HP, snd 456), scrolls 2000…2049 (spell = p1 for
  2000 else type − 2000; the first slot empty or holding that spell — compared **before** the remap; then id 2 → 3; flag 1; count untouched; snd 503;
  `PTR_DAT_1009fda8 = 0x20`, `_DAT_1009fda4` = the slot and the flash mode `_DAT_1009fda0 = 0`; `.UpdateStatusBar(1,1,0)`;
  with no empty or matching slot the arm returns at once — no sound, the scroll not killed, M l. 48956–48962), items 3200…3248 (3221 first
  `RemoveItem(0)`, 3215 first `RemoveItem(0xe)`; +3 for 3206 else +1, cap 99; snd 506; the same highlight), 3050 (the
  glider pickup's state writes: cooldown `PTR_DAT_100a05c4 == 0` → `_DAT_100a05e0 = 1`, `_DAT_100a05d4 = 1`,
  `PTR_DAT_100a05c8 = 0`, the player snapped to the pickup, face/rect (0x37,0x3e,99,0x6e)), the spheres 1330…1339
  (M l. 49024–49123: the timers 600 / 600 + `PTR_DAT_100a063c = type − 0x533` / 600 / player `+0x116 = 0x1c2` / 900 /
  600, then `sphere+0xa6 = duration` — 32000 for 1335 with p2 = 0 and for 1338; 1339 HP −0x380, 30 invulnerable /
  flash frames, killed). **The upgrade (1340/1341, M l. 48810–48905)** is a modal moment (Invariant 5): the arm plays
  snd 451 vol 0xab, score += 2000, `+0xe9 = 1`, `GammaFadeOutAsync(2, rgb, 0xc, 0x10)` (1341 colour `_DAT_100a07f0`,
  1340 `_DAT_100a07f4`), then the session suspends (`.upgrade(type)`); `LevelRun` runs the six tick loops — 5 × (wait
  2 ticks, `.HandleAsyncGammaFade`); `GammaFadeInAsync(0x28)`; 10 × (`.HandleAsyncGammaFade`, wait 1); flash = 11 then
  11 × (flash − 1, `.UpdateStatusBar(1,0,1)`, async step, wait 2); the refill (1340: breath = HP = max, `G+8 = 8`; 1341:
  magic = max); 14 × (max += 8, bar, step, wait 2); 14 × (1340: HP += 8, breath += 8, player `+0xa4` = HP; 1341: magic
  += 8; bar, step, wait 2); flash = 11 and 11 × (flash − 1, bar, step, wait 2) — **120 ticks** in all (BC35) — then
  resumes the same frame. The flash counter is `PTR_DAT_1009fdbc` (1340) / `_DAT_1009fdb8` (1341). **The hurt drops
  (Phase 2 carry):** `.HurtPlayer`'s lost coins (M l. 48088–48104) are now spawned (`MTNewSprite(0x516, …,
  .SetupBonusSprite)`: layer 0x14, `+0xb0 = 12`, `vx = ±(600 + R(0x640))`, `vy = −2000 − R(0xdac)`, `+0x16c = −240`);
  when `.MTNewSprite` finds no free record (700 in use) it returns 0 **without running the Setup**: that coin makes
  only the caller's draws (R(8), R(8), R(0x640), R(100), R(0xdac) — five, not nine) and its field stores go nowhere.
- **◈ goldens:** only a scripted golden whose path touches a pickup (the 600-frame chain on level 2 walks through
  Xichrons) may move; recorded old → new.
- **Tests (8; numbers from the M lines above):** `testPickupGate` (`+0xb0 = 12` → no pickup; `+0xa6 = 3` → none;
  dying → none; spirit form → a Bonus still picked) · `testXichronHundred` (G+0x14 99 + a 1055 → 0, item 0x16 count
  1 in the first empty slot, score +10; sounds 501 (vol 0x55), 451, 445, 501 (vol 0x100) in that order; a 1056 at 99 → 0, score +1000) ·
  `testCrystalsMoneyCoins` (1290 at magic 0x200 of max 0x230 → 0x230, score +100; 1291 → HP/breath +0x2a0 clamped,
  player `+0xa4` +0xe0; 1293 coins +25 score +100; 1306 coins +100 score +5) · `testScrollLearns` (2000 p1 2 on an
  inventory [s0, i0] → slot 2 = spell 3, flag 1, count left at the empty slot's 0; `fda8` = 0x20, `fda4` = 2;
  snd 503; a second 2000 p1 2 → the **next** empty slot: the search compares the unmapped id 2 with the slot's 3
  (M l. ~48946, as written)) · `testItemsStack` (3206 → item 6 count 3; ×33 more → 99; 3221 with
  one dagger → dagger removed, item 0x15 count 1) · `testWorldFlagTrigger` (level 2 record 228: p1 1, p2 0 → `G+0xad8
  + 2` = 1 after the touch, the trigger killed; saved in G) · `testUpgradeRuns120Ticks` (1341 at magic 0x230/0x230:
  the suspension `.upgrade(1341)`; `LevelRun` emits the first status-bar op at tick 20 (after 10 + 10 ticks), ends at tick 120 after the arm with
  max magic 0x2a0, magic 0x2a0, score +2000, then the frame's rest) · `testHurtCoinsSpawned` (3 coins lost: three 0x516
  sprites, layer 0x14, `+0xb0` 12, `+0x16c` −240, nine draws each; with 700 records in use → no sprite, five draws
  each).
- **Gate:** G2 = 390, G6, G7(+b), G8, G10; wave 4.2 end: G3, G5. **Commit:** `FerazelCore: pickups (Xichrons, crystals, coins, upgrades with their 120-tick animation, scrolls, items, triggers 1058/1059, spheres' timers, glider pickup), hurt coins spawned; 8 tests`.

### Wave 4.3 — effects, casting

#### EF — ⚑ MAJOR — the Effect ids, the explosion package, the flash and the shake (→ 397)
- **Files:** `Sources/FerazelCore/Player/GroundCeilingEffects.swift` (`EffectSprite`: Setup arms + Handle arms for
  ids 0…15, 0x442, 0x4b6, 0x4b7, 0xc1b, 0xc81, 0xcb2…), `Sources/FerazelCore/Particles/ScreenFlash.swift` (new),
  `Sources/FerazelCore/Camera/Camera.swift` (the shake `_DAT_1009ffa0`, M l. 6147–6162), `Sources/FerazelCore/Session/FerazelSession.swift`
  (the flash step and `.copyMaskToScreen` in `.PaintFrameWrap`'s copy, M l. 9437–9447),
  `Sources/FerazelCore/Player/HitPlayerSprite.swift` (the Effect arm: 1207 hurts while `+0x46 ≤ 7`),
  `Sources/FerazelCore/Seams/DrawOp.swift` (`.copyMaskToScreen`), `Sources/FerazelRender/Frame/FrameRenderer.swift`
  (executes it), `Sources/FerazelRender/Screens/ScreenRenderer.swift` (refuses it off a level),
  `Tests/FerazelCoreTests/SessionTests.swift` (the exhaustive `DrawOp` switch, l. 288),
  `Sources/FerazelRender/Effects/ParticleRenderer.swift` (only if a new particle kind needs a face),
  `Tests/FerazelCoreTests/EffectTests.swift` (new), `Tests/FerazelRenderTests/DrawEffectTests.swift` (one added).
- **Contract:** triggers-background-2 §2.1–§2.2 (the table, the explosion package, the light schedule, the effect
  damage); pickups-boxes-2 §7 (0x4b7 vs crates −10 on any frame; vs Crawler/Walker/Roach/Frog → Phase 5 ◇). Dump:
  `.InitEffectSprite` M l. 53639–53687, `.SetupEffectSprite` M l. 53688–53863, `.HandleEffectSprite` M l. 54024–54286,
  `.HitEffectTileSprite` (after it; class 1 and 3099 → `.WallBounce(…, 0x80, …, 0x80)` with `+0x16c` += 1 per bounce;
  class 0 water → `.HandleUnderWater`; class 2 with `+0xeb` → `.CrunchTile`). The package: every id except 1201…1206,
  1220, 1040, 1430, 1251, 1210, 3099, 1440, 1435, 1830, ≥ 3200: 45 × `NewParticle(kind, 150, centre, 1 + R(2),
  R(2000) − 1000, R(2000) − 1000, 0, 1)` (kind 4 for 5 and 1090, 9 for 2, else 1; centre (x+16, y+24), big (x+32, y+48));
  a plume 1206 90 px above when prefs+6 == 1 and fewer than 3 plumes (not for 1207, 1090, −1); a light (PICT 813,
  colour 0x16) unless 1090; the light schedule 813 → 812 at frame 2, 811 at 4, 810 at 6, 811 at 14, 812 at 17, 813 at
  20, removed at 23, the effect killed at 26 (ids 0…15, 0x442, 0x4b7). 3099 debris: 8-frame loop (row 2 when `+0x14c`),
  gravity 0x5a + tile gravity, killed after 4 bounces, prefs+6 == 1 fades 0 → none, 1 → 0xb0001, 2 → 0xb0000, ≥ 3 →
  0xb0002. 3201 as id 0 without particles/light. 3250 / 3250+n balloons: no branch (static), layers 100 / 101 (made by
  BX2's `.CreateBalloonSprite`). **1207 hurts the player** (`.HitPlayerSprite` Effect arm, triggers-background-2 §2.2
  (a); enemy-shots-and-damage §3.4 for the `HurtPlayer` arguments — re-read at the arm) while `+0x46 ≤ 7`.
  `ScreenFlash`: each drawn `.PaintFrameWrap`, count < 1 → toggle 0, else toggle = !toggle and count − 1; toggle on →
  the copy reads the mask port (`.copyMaskToScreen`, BC36). Writers this phase: Smiting (IU), the seed explosion (SH).
  The shake: `FindUpperLeftCorner` M l. 6147–6162 — while > 0: `v −= shake >> 1` when (counter & 1, or & 3 with
  prefs+0 ≠ 0) == 0, else `+=`; shake − 1; then the graphics-2/3 even-v rule. Writer this phase: the seed explosion
  (0x14).
- **Tests (7):** `testExplosionPackageDraws` (id 0 at prefs+6 1 with 0 plumes: 45 particles kind 1 at (x+16, y+24) —
  135 draws in the raw's argument order, recorded — then one 1206 plume and the light 813 colour 0x16; id 1090: kind 4,
  no plume, no light) · `testExplosionLightSchedule` (faces 813, 813, 812 @2, 812, 811 @4, 811, 810 @6 … 811 @14, 812
  @17, 813 @20, removed @23, killed @26) · `testBigExplosionHurtsEarly` (a 1207 overlapping the player: hurt on frames
  0…7, none on 8; its rect (8,8,88,88); `+0xeb = 2` passes crunch strength 2 to `.CrunchTile`) · `testDebrisBounces`
  (3099 killed on its 4th tile bounce; fade states 0xb0001 / 0xb0000 / 0xb0002 after 1 / 2 / 3 bounces at prefs+6 1) ·
  `testFlashAlternates` (count 3 → the copies are mask, frame, mask, frame; count then 0) · `testCameraShake` (shake
  0x14, prefs+0 0: v −10 then +9 (shake 0x13 >> 1) alternating by the counter's bit 0, shake 0x13, 0x12 …; graphics 3 rounds v even) ·
  Render `testCopyMaskToScreen` (the mask port's 0x00/0xFF through the screen copy at (16, 8), parallax off).
- **Gate:** G2 = 397, G6, G7(+b), G8, G10. **Commit:** `FerazelCore: the Effect ids (explosion package, light schedule, big explosion hurt, debris), the mask flash and the camera shake; 7 tests`.

#### CS — ⚑ MAJOR — casting and the player shots in flight (→ 406)
- **Files:** `Sources/FerazelCore/Shots/PlayerShot.swift` (new: `.InitPlayerShotSprite`, `.SetupPlayerShotSprite`,
  `.HandlePlayerShotSprite`), `Sources/FerazelCore/Shots/CastSpell.swift` (new), `Sources/FerazelCore/Player/HandleKeys.swift`
  (the USE spell gate, M l. 47311–47352), `Sources/FerazelCore/Player/Player.swift` (row 31: the wand animation, M l.
  45140–45172), `Sources/FerazelCore/Player/PlayerStates.swift` (the cast faces 1014 / 1032 / 1031 / 1016 / 1053),
  `Sources/FerazelCore/Player/PlayerState.swift` (`wandPhase`, `wandHold`, `castFlag` `_DAT_100a06ec`, `castBegan`
  `PTR_DAT_100a06e0`, `vBladeCast` `_DAT_100a0768`, `exertion` +0x19 — the existing fields kept), `Sources/FerazelCore/Sprites/SpriteSlot.swift`
  (`SpriteHandler.playerShot`; shot fields), `Sources/FerazelCore/Session/{FerazelSession,SpriteWorld}.swift` (dispatch;
  the shot faces in the face bounds), `Sources/FerazelCore/Sprites/SetupFaces.swift` (only if the shot sheets join the
  boot-loaded table), `Sources/FerazelRender/Frame/FrameRenderer.swift` + `Sources/FerazelRender/Faces/FaceSheet.swift`
  (load PICTs 1100–1105, 1113–1118, 822 if not already loaded), `Sources/FerazelCore/World/Movers/BackgroundSprite.swift`
  (a cannon-captured player shot's light removed, `BackgroundSprite.swift:497–499` — A7, through LT's table),
  `Tests/FerazelCoreTests/PauseKeysTests.swift` (l. 584–680 hold ⌘ in a level: with casting built a held ⌘ casts —
  the tests' asserted values must not change; if one does, STOP and report; the fix is to run them with no spell
  selected, recorded), `Tests/FerazelCoreTests/CastTests.swift` (new).
- **Contract:** spells-items §2, §2.1; spells-detail §2.1–§2.4, §3.1, §3.2 (flight, per-id table, liquids), §3.8;
  spells-detail-2 §1–§5. Dump: `.HandleKeys` M l. 47047–47884 (the USE gate: USE up, or the selected slot not a spell,
  or the shield raised → latch `_DAT_100a0760` cleared; else idle counters 0, and with the latch clear and no mist
  states: magic `G+0xe < 1` → selection to the first slot holding item 0 or 0x15, `.MoveSelectedItemToFront` (which
  itself calls `.UpdateStatusBar(1,1,0)` when it moves, M l. 39705), then `.UpdateStatusBar(1,1,0)` again (M l. 47336)
  — two calls, two key steps; the same call's item gate then sees the dagger selected and USE down and starts the stab
  (IU's switch, snd 418); else (M l. 47339–47350) the item latch `_DAT_100a075c = 1` and the cast latch `0760 = 1`, wand
  step 0 → cast flag 1 + step 3 + `06e0 = 0`; step 3 → cast flag 1; steps 1, 2, 4, 5, 6 swallow; then
  `.MoveSelectedItemToFront` (the cast spell's slot to the front, with its own (1,1,0) call when it moves); the item
  block later in the same call clears `075c` again because the selected slot is a spell (spells-detail-2 §1 — the write
  is dead as observed, built as written)), row 31 M l. 45140–45172 (flag set: step + 1; 4 → `.CastSpell` if magic > 0;
  > 6 → flag 0, step 3; step 3: hold + 1, 18 → step 2; 2 → 1 → 0 with hold 18; else hold 0; the dead arming path
  `PTR_DAT_100a06e8` kept as written), `.CastSpell` M l. 46653–46980 (per case: snd 300 `STPlay3DSoundRand` first, the
  cost without a floor, `MTNewSprite(id·256 + power, …)` at the case's offsets, `R(100)` speed (V Blade `R(256)` × 2,
  lower half `0x3c00 + power`, its vx `R(256) − 0x80` never flipped by facing, no UP / arc / jitter), then for the first shot UP → `vy −= 0x5dc, vx −= 0x2ee`, ids 0/1/3/4 → `vy −= 0x5dc`
  (crouching −1000), `vy += R(0x4b) − 0x28`, facing flips (wall climb sides 1/2 invert), the Shadow Double copy
  (SD builds the double; CS builds the copy's spawn against `_DAT_100a0658 ≠ 0`; the copy's type is `id·256 + 1` — for
  V Blade 0x601 for both copies, the lower half's copy included, M l. 46900–46944), power = 1 + count(0x13), but **=
  count** while the loss timer `_DAT_100a073c > 1`, the magic-carpet carried speed, glider (0x1e, 0x23) / rope (gy 8) offsets, exertion
  `_DAT_100a06a4 += 0x19`), `.InitPlayerShotSprite` M l. 50226–50264, `.SetupPlayerShotSprite` M l. 50265–50430 (`+0xeb
  = 1`, `+0x46 = R(5)`, layer 0xb, callbacks, `+0xa6 = 0`, `+0x90 = 0x100`, `+0x158 = 1`, rect (8,3,15,12), the
  id/power split, per-id rects and gravities (spells-detail §3.1 table), power ≥ 2 → power − 1 followers (≤ 4) of type
  `id << 8` (power 0, no callbacks, gravity 0), `+0xe4 = 1`, `+0x14c = −1`), `.HandlePlayerShotSprite` M l. 50431–50946
  (dying return; `.StandardSpriteHandles`; un-shift; age + 1 to 200; per-id branch from age ≥ 1 — the particles of ids
  2/3/4, the Boomerang's steering after age 12 (`FUN_1003f218(shot, dir, 800)` + `.EnforceMaxSpeed(0x1450)`,
  spells-detail-2 §3), V Blade's ±500 px rule; age 1 (power > 0): `+0xa4 ×= power`, the light (`AddLight` with the
  per-id colour unless hidden in a wall tunnel, spells-detail-2 §2); `vy += gravity; x += vx; y += vy`;
  `.ChangeLightSpeed`; `.SeparateFromTiles2` (ids < 100); the liquid rule (ids < 100 ≠ 6 in liquid → effect 5 at (x−8,
  y−12) with its light off, kill flag, followers killed; id 3 in water → the floe, SW); the level-bottom rule; the draw
  angle `+0x1aa`; the followers placed; the end-of-call tunnel test removing the light). The impact routines (Hit,
  HitTile, Kill) are SH's; until SH lands a shot dies only by the liquid and level-bottom rules (an interim state, not a
  ◇ — SH is the next task).
- **Tests (9; numbers from the M lines above):** `testCastOnPressFrame` (Fireball at magic 560: the press frame emits
  the shot; magic 552; wand steps 3, 4 (cast), 5, 6, 3 …; a held USE never re-casts; released one frame, a fresh press
  at step 3 casts **on that same frame** (flag set → step 4 → `.CastSpell`)) · `testCastDrawOrder` (Fireball, power 1: R(10000) (snd 300), R(5) (Setup), R(100), R(0x4b) in
  that order; power 3 (two Multi Crystals): two follower Setups' R(5) between) · `testCastSpeeds` (player vx 0x400,
  facing right: vx = 0x200 + R(100) + 0xd2f, vy = pvy/2 − 0x5dc + R(0x4b) − 0x28; UP held: a further −0x5dc / −0x2ee;
  facing left: vx negated) · `testMagicBelowOneSelectsDagger` (magic 0 with spell 0 selected: no cast, the selection
  moves to the dagger's slot and to the front, two `.UpdateStatusBar(1,1,0)` calls — the same-frame stab is IU's
  assertion, the item switch being IU's) · `testCastPressMovesSpellToFront` (spell 0 in slot 3 selected, magic 560:
  the press casts, slot 3 moves to slot 0 and the selection is 0 (one (1,1,0) call); `075c` set by the press — its
  clear by the item gate is IU's assertion) · `testCostWithoutFloor` (Statue at magic 1
  → magic −31) · `testPowerMultipliesOnAgeOne` (power 3 Fireball: `+0xa4` 100 at age 0, 300 at age 1; followers'
  `+0xa4` 0, placed at the main's stack offsets (0, 6·k)) · `testBoomerangHomes` (id 5: straight for 12 frames, then
  an 800 impulse toward the player's centre − 4 px each frame, |vx|, |vy| ≤ 0x1450) · `testShotFizzlesInLiquid` (a
  Fireball entering water → effect 5 at (x−8, y−12), the shot and its followers `+0xe9 = 1`; an upper V Blade passes
  through).
- **Gate:** G2 = 406, G5 (wave 4.3 end), G6, G7(+b), G8, G10; wave end: G3. **Commit:** `FerazelCore: casting (the USE gate, the wand steps, .CastSpell) and the player shots in flight (followers, lights, Boomerang, V Blade, liquids); 9 tests`.

### Wave 4.4 — impacts, the glider, power-ups

#### SH — ⚑ MAJOR — shot impacts: sprite hits, tile hits, kills, containers (→ 414)
- **Files:** `Sources/FerazelCore/Shots/PlayerShotHits.swift` (new: `.HitPlayerShotSprite`, `.HitPlayerShotTileSprite`,
  `.KillPlayerShot`), `Sources/FerazelCore/World/Movers/BonusSprite.swift` (the container arm `LAB_1005fd94` of
  `.HitBonusSprite`), `Sources/FerazelCore/World/Movers/BoxSprite.swift` (the stalactite 2932's shot damage and fall
  trigger; the 2941 shot arm lives in `.HitPlayerShotSprite`), `Sources/FerazelCore/Player/PlayerTiles.swift` (only if
  `.CrunchTile`'s strength argument needs a new caller seam), `Sources/FerazelCore/Session/{FerazelSession,SpriteWorld}.swift`
  (collide / tile-callback dispatch for `.playerShot`), `Sources/FerazelCore/Particles/ScreenFlash.swift` +
  `Sources/FerazelCore/Camera/Camera.swift` (the 0x5a writers), `Tests/FerazelCoreTests/ShotHitTests.swift` (new).
- **Contract:** spells-detail §3.3, §3.7; spells-detail-2 §2, §5; pickups-boxes §1.5, §2.2 (2932, 2941), §2.4.4,
  §3.2; pickups-boxes-2 §4.2. Dump: `.HitPlayerShotSprite` M l. 50947–51071 (in order: the player and id 5 at age > 10
  → caught: kill + followers, **magic += 8, no clamp**; enemy shot 0x77b → snd 303 vol 0xab, `KillPlayerShot(s,0,1)`;
  0x50 vs an enemy shot → snd 303 vol 0x55, kill both (built as read; no enemy shot exists until Phase 5); 0x50 vs 0xb7c
  nothing; Box 0x2c8/0x2c9 → id 4 grows a trunk (SW), others nothing; the Effect class → nothing; Bonus 0x517/0x51b with
  `+0xb0 ≠ 0` and id ≠ 0x50 → `KillPlayerShot(s,1,1)`; a Statue or Box with no one-way top and no surface function →
  the 2941 test (type 0xb7d, `+0x116 < 1`, `s+0xa4 == 300` → HP −0x50, `+0xaa = 10`, `+0x116 = 10`, snd 419 pitched
  35000 — `cmpwi r0,0x12c` raw `1005ab7c`) then `KillPlayerShot(s,1,1)`; with a one-way top or surface function →
  `.PlatformBounce`, contact → kill; the Crawler → `KillPlayerShot(s,0,0)` (built as read but **cannot match** on levels 1–4: the Phase-1 Crawler stand-in is
  `.inert`, not the Crawler Handle — Phase 5; the Crawler's own Hit is
  Phase 5)); `.HitPlayerShotTileSprite` M l. 51219–51392 (ids 6/0x3c only crunch cells; FG → `.WallBounce` (0xa0 bounce
  for 0x5a), contact: id 3 → ledge (SW), id 4 grounded → trunk (SW), seeds bounce and die only at `|vy| < 0x200`, else
  `KillPlayerShot(s,1,1)`; BG < 100 the same; BG 100…199 `.WallBounceBG(kind−100)`, contact: id 4 grounded → trunk
  bottom (SW), then kill; BG ≥ 200 water → `.HandleUnderWater` unless `+0x140`; crunch → `.CrunchTile(pos, +0x158)`,
  processed → kill (not 6/0x3c)); `.KillPlayerShot(s, sound, effect)` M l. 51072–51218 (type 100 returns at once; then `.StandardSpriteCleanup` first
  (the tunnel fields the effect test reads); when the effect is suppressed the ids 1–7 / 0x3c arm still recolours the
  light with a register the suppressed path never set — `unaff_r29`, which on that path is the **caller's** r29 (M l.
  51090, 51190–51195) — **follow the binary**: the implementer traces r29 at each **call site** of `.KillPlayerShot`
  (the sprite hits, the tile hits, the liquid / orb paths) in the raw and transcribes what it holds there (a light slot
  read through it, or a no-op when it is no sprite), recorded in "As executed";
  followers `+0xe9 = 1`; the wall-tunnel test suppressing the effect (spells-detail-2 §2); id 0: snd 301 Rand, effect 0
  at (x−8, y−12); ids 1–7, 0x3c: snd 301, effect 5 (2 for id 4) at (x−5, y−12) with light colour 0x21 (1, 2), 0x4d (3),
  0x42 (4); 0x50: hits `+0x168` − 1, at < 1 snd 424 + `.ExplodeFaceIntoParticles(face, pos, 2,1,7,0x50,0x65)` +
  `+0xe9 = 1`, else snd 423 (both `STPlay3DSoundRand` when sound ≠ 0); 0x5a: snd 435, `ScreenFlash` 3, shake 0x14
  (BC36), 0x4b7 at (x−0x2a, y−0x2a) layer 0xc (`+0xb8 = 0x10004` with `+0xf4`), and unless `+0xf0`: 8 × 0x442 from the
  4×4 grid's cells 0, 2, 4 … (the countdown `sVar9`), each `FUN_1003f218(frag, dir, R(0x96) + 400)` toward the cell
  from the centre and `+0x46 = R(7)`); the container arm of `.HitBonusSprite` M l. 53452–53486 (a player shot, not id
  0x50, `+0xa6 == 0`: 1307 / 3100…3109 spent (`+0xb0 == 0`) → nothing, else `+0xb0 = 0`, rect zeroed, **record p4 = 1**;
  1303 → KillBonus; then `KillPlayerShot(shot,1,1)`, score + 150, `MTNewSprite(0x514 if (magic<<8)/maxMagic <
  (HP<<8)/maxHP ∧ HP > 0x25 else 0x515, centre − 9, layer 2)` with `vy = −2000 − R(1000)` after its Setup's draws).
  The stalactite 2932 (pickups-boxes-2 §4.2: a shot subtracts its damage and shakes it `+0xa6 = d/20 + R(d/40)` frames;
  HP < 1 → gravity 0xfa) — its hit is in `.HitBoxSprite` (M l. 61328–61482): built here for the shot case only (BX1
  builds the rest of `.HitBoxSprite`). Crates' shot damage is `.HitBoxSprite`'s too → BX1.
- **Tests (8; numbers from the M lines above):** `testFireballImpactOnWall` (a Fireball into an FG wall: snd 301
  (one R(10000)), effect 0 at (x−8, y−12), the shot and its followers `+0xe9 = 1`) · `testSeedsBounceThenExplode`
  (a 0x5a falling: bounces at 0.625 while `|vy| ≥ 0x200`; then snd 435, flash 3, shake 0x14, one 0x4b7 at (x−42, y−42)
  layer 0xc, eight 0x442 with `+0x46` = R(7)) · `testZiridiumTint` (`+0xf4 = 1` → the 0x4b7's `+0xb8` 0x10004; `+0xf0
  = 1` → no fragments) · `testBoomerangCaughtRefund` (id 5 at age 11 touching the player: killed, magic 552 → 560, and
  at magic 560 of 560 → 568 (no clamp); at age 10 not caught) · `testContainerOpens` (a Fireball into torch 1307 with
  `+0xb0 = 1` at HP 0x230/0x230, magic 0x100/0x230: record p4 = 1, `+0xb0 = 0`, score + 150, a 0x514 spawned (magic% <
  health%) with vy −2000 − R(1000); a second shot passes (nothing, not consumed); an orb 0x50 opens nothing) ·
  `testRockPileDestroyed` (1303 → KillBonus, a 0x515 when HP ≤ 0x25) · `testIceWall2941Needs300` (a shot with `+0xa4`
  300 → the 2941's HP 300 → 220, `+0x116 = 10`; 600 (power 2) → nothing; four hits from 300 → HP < 1) · `testCrunchKills`
  (a Fireball into a crunch cell: `.CrunchTile` strength 1 called once, the shot killed; a V Blade passes through and
  crunches).
- **Gate:** G2 = 414, G6, G7(+b), G8, G10. **Commit:** `FerazelCore: player-shot impacts (sprite and tile hits, KillPlayerShot effects, seed explosions, containers, 2941, stalactites); 8 tests`.

#### GL — minor — the hang glider (→ 419)
- **Files:** `Sources/FerazelCore/Player/Player.swift` (rows 8, 9, 23, 24 and the glider block, M l. 44622–44655,
  45219–45518), `Sources/FerazelCore/Player/PlayerStates.swift` (the glider state and faces, `PlayerStates.swift:57`),
  `Sources/FerazelCore/Player/HandleKeys.swift` (steering, M l. 47494–47541; `HandleKeys.swift:62`),
  `Sources/FerazelCore/Player/PlayerState.swift` (the glider globals `05c4…05e0`), `Sources/FerazelCore/Camera/PlayerScroll.swift`
  (the glider as a jump/rope state, M l. 43151–43166 per spells-detail §5.4 — re-read), `Sources/FerazelRender/Faces/FaceSheet.swift`
  (PICTs 1050–1053, 160×160 cells, if not loaded), `Sources/FerazelCore/World/Movers/BonusSprite.swift` (the stow's
  dropped 0xbea through `.SetupBonusSprite`), `Tests/FerazelCoreTests/GliderTests.swift` (new).
- **Contract:** spells-detail §5.1–§5.4; spells-detail-2 §1 (`PTR_DAT_100a04cc`). The pickup's state writes are PK's.
  Deploy: phase 1 → vy 0, gravity 0; phases 1…23 vx 0, face 1050[phase >> 2], gravity −0x78 once phase > 16; phase 24:
  gravity += 0x1e while < 100, then phase 0. Gliding: pitch gravity 20/40/47/50/52 (−5…−1), 60 (0), 72/75/80/90/120
  (+1…+5) and wind scale 506/381/339/318/306, 256, 212/201/183/146/36; vy ≤ 2000; the −0x9c4 floor (`.PlayerConstraints`,
  built); drag 0x14; dive / pull-up (`vy += trunc(−0x640·c/30)`) only when no turn runs and the wand step < 3; steering
  ±0x96 to ±0xc80, the turn counter ±12 past |vx| > 0x300, UP/DOWN pitch ±1 (decay to 0); landing count > 12 → phase
  −23; stow: face 1050[|phase| >> 2], vx 0, gravity 0, vy 0x100, y −= 2 while phase < −16; at 0 a 0xbea pickup at the
  player (`.SetupBonusSprite`, layer 2), cooldown 180, glider off, gravity 0x1b8, x += 30, y += 32 (10 while
  `PTR_DAT_100a04cc`), the standard face and rect; death on the glider skips the necklace (`5106 = 1`).
- **Tests (5; numbers from spells-detail §5 — HIGH with raw):** `testDeployTimeline` (16 still frames, then 7 rising
  at gravity −120, 8 ramp frames at +30, gliding with vy ≈ −720 — the exact vy recorded) · `testPitchTable` (each pitch
  −5…+5 → the gravity and wind-scale pairs above) · `testSteerAndTurn` (RIGHT from vx 0: +0x96 per frame to 0xc80; LEFT
  facing right past −0x300 → turn counter 12) · `testLandAndStow` (13 grounded frames → phase −23; 23 stow frames; a
  0xbea at the player, cooldown 180, x + 30, y + 32; with `04cc` set y + 10) · `testCooldownBlocksRepickup` (the dropped
  glider touched within 180 frames → nothing; at 0 → deploy again).
- **Gate:** G2 = 419, G6, G7(+b), G8, G10. **Commit:** `FerazelCore: the hang glider (deploy, pitch gravity and wind, steering, dive, landing, stow); 5 tests`.

#### PU — minor — the power-up timers and their effects (→ 425)
- **Files:** `Sources/FerazelCore/World/Movers/BackgroundSprite.swift` (the cannon capture's `.DoubleSpeedTrail`
  stub, `BackgroundSprite.swift:535/564` — A7), `Sources/FerazelCore/Session/FerazelSession.swift` (the handle-pass
  switch gains `.trail`, l. 389–429 has no default — B4), `Sources/FerazelCore/Player/Player.swift` (row 14's `.TickTock`s, M l. 44748–44800; rows 5, 8, 9, 23,
  36 read the flags), `Sources/FerazelCore/Player/PowerUps.swift` (new: `.TickTock` M l. 43583–43663, `.DoubleSpeedTrail`
  M l. 44302–44395), `Sources/FerazelCore/Player/PlayerState.swift` (the timers `0650`, `064c`, `0640`, `063c`,
  `0630`, `0624`, `0618` and the visible flag `cRam100a5fd4`, `PlayerState.swift:132`, `:326`, `:334`),
  `Sources/FerazelCore/Player/PlayerLiquids.swift` (solid liquids `PTR_DAT_100a063c` 0/1/2 as floor),
  `Sources/FerazelCore/Sprites/SpriteSlot.swift` (`SpriteHandler.trail`), `Tests/FerazelCoreTests/PowerUpTests.swift` (new).
- **Contract:** spells-items §5; pickups-boxes §1.6; physics §4 (High Jump J −2200, Featherfall gravity 64 and fall cap
  850, Double Speed 3458/5600), §5.1 (solid liquids); held-item-melee §3 (the Double-Speed trail). `.TickTock(t)`:
  `t > 0` → − 1, reaching 0 → `STPlay3DSoundPitched(428, 0x14, 0x100, …, 32000)` and the visible flag set; then 14
  warning marks every 15 frames from 210 down (M l. 43583–43663): at 210, 180, 150, 120, 90, 60, 30 left → snd 428
  (`_DAT_100a03c8`, `STPlayRegSound`) and the flag toggled; at 195, 165, 135, 105, 75, 45, 15 → snd 429 (`_DAT_100a03c4`)
  and the flag toggled (the warning blink). The Pentashield and the Shadow Double are SD's.
- **Tests (6):** `testTickTockWarnings` (a 600 timer: snd 428 at 210/180/…/30 left, snd 429 at 195/165/…/15, the flag toggling
  14 times, the pitched snd 428 at 0) ·
  `testSolidLiquid` (1331 → `063c = 0`: water is floor for 600 frames; 1332 acid, 1333 lava) · `testHighJump` (1334: the
  jump base −2200 for 600 frames) · `testFeatherfall` (1336: gravity 0x40, vy ≤ 0x352 when falling, 900 frames) ·
  `testDoubleSpeedTrail` (1337: max walk/run 3458/5600; the trail sprites take the player's faces by the pose ring) ·
  `testInvincibilityAndDeath` (1335: player `+0x116 = 0x1c2`, the sphere hidden 32000 with p2 0 / 450 with p2 ≠ 0;
  1339: HP −0x380, 30 frames invulnerable, the sphere killed).
- **Gate:** G2 = 425, G5 (wave 4.4 end), G6, G7(+b), G8, G10; wave end: G3. **Commit:** `FerazelCore: power-ups (.TickTock warnings, solid liquids, High Jump, Featherfall, Double Speed with its trail, Invincibility, Death); 6 tests`.

### Wave 4.5 — items in use, the passive items

#### IU — ⚑ MAJOR — the USE item switch, the held weapon, thrown seeds, potions, rings, the hints (→ 433)
- **Files:** `Sources/FerazelCore/Player/HandleKeys.swift` (the item gate and switch, M l. 47353–47357 and
  47541–47610; `HandleKeys.swift:44–65`; the shield's `HasItem(0xe) ∨ HasItem(0xf)`, `HandleKeys.swift:430`),
  `Sources/FerazelCore/Items/HeldItem.swift` (new: `.SetupHeldItemSprite`, `.HandleHeldItemSprite`, `.SetHeldItemPos`,
  `.HandleItemUse`), `Sources/FerazelCore/Items/Smite.swift` (new: `.SmiteEnemies`), `Sources/FerazelCore/Player/Player.swift`
  (row 31's held-item face 0; row 32 the potion drink, M l. 45176–45218; the `.HandleItemUse` calls M l. 45728, 45819),
  `Sources/FerazelCore/Player/PlayerStates.swift` (melee faces 1007/`_DAT_100a07cc` and crouch `_DAT_100a078c`; the melee
  state, `PlayerStates.swift:176`, `:195`), `Sources/FerazelCore/Sprites/SpriteSlot.swift` (`SpriteHandler.heldItem`),
  `Sources/FerazelCore/Seams/FrameSuspension.swift` (`.hint`, `Outcome.hint`), `Sources/FerazelCore/Session/FerazelSession.swift`
  (**the resumable player Handle** — today `resume(_:)` always continues the special pass, `FerazelSession.swift:447–471`;
  IU adds a second resume point: a suspension raised inside `Player.handle` at the item switch returns the ops so far,
  and `resume(.hint)` continues `.HandleKeys` after the switch, the player's remaining rows, then the handle pass from
  the player's saved `next`, then the rest of the frame), `Sources/FerazelCore/Session/SpriteWorld.swift` (the
  handle-pass walk `handleSprites`, `SpriteWorld.swift:189ff`, becomes resumable: a saved cursor like the special pass's
  `SpecialPass`), `Sources/FerazelCore/Player/HandleKeys.swift` (split at the switch), `Tests/FerazelCoreTests/PauseKeysTests.swift`
  and `Tests/FerazelRenderTests/{FrameGoldenTests,Phase2GoldenTests}.swift` (their drivers return early on any
  non-conversation suspension — they resume `.hint` as they resume `.conversation`; counts unchanged), `Sources/FerazelCore/Front/LevelRun.swift` (runs `.SimpleConv(4001, "Ferazel", text)` through
  `ConversationRun`; the Escape Ring's `fd64`), `Sources/FerazelCore/Talk/ConversationRun.swift` (only if `.SimpleConv`
  needs the portrait/name parameters it does not yet take), `Tests/FerazelCoreTests/ItemUseTests.swift` (new).
- **Contract:** spells-items §4; pickups-boxes §3.1–§3.3; held-item-melee §1, §4; spells-detail-2 §1 (the item latch).
  Dump: the item gate (USE ∧ an item selected ∧ shield < 1 ∧ climb 0 ∧ rope 0 → the switch instead of the L/R and
  glider blocks; latch `_DAT_100a075c` → one action per press), the switch M l. 47541–47610: 0/0x12/0x15 (no melee
  running, no mist states) → snd 418 vol 0x55, `_DAT_100a0698 = 1`, `PTR_DAT_100a04f4` = facing left
  (`_DAT_100a5f5a == 1`), the in-use item `_DAT_100a5fd8`, `.MoveSelectedItemToFront`; 1/2/3 → `.SimpleConv(0xfa1,
  "Ferazel", 0x100a616f)`; 4/5/0x19 (no mist states) → drink counter `_DAT_100a05b0 = 1`, `_DAT_100a5fd6 = id`; 6/0x1a →
  snd 704 vol 0x55, melee counter 1, facing, in-use, front, `.RemoveItem(id)`; 0xe/0xf → `.SimpleConv(…, 0x100a60e7)`;
  0x10 → `.RemoveItem`, `ScreenFlash` 3, snd 421, `.SmiteEnemies`; 0x11 → `.RemoveItem`, snd 421, exit `uRam100a5116 =
  −1`, level complete `*_DAT_100a0088 = 1`, `fd64 = 1` (**replaces the Phase 3 ◇ "Escape Ring unreachable"** — `LevelRun`
  already skips the stage panel on `fd64`, L1); 0x16 → `.SimpleConv(…, 0x100a60a8)`. The three texts (pstrs, verified):
  "You don't need to select keys from the inventory. Just walk into the door that requires it and I'll use the key."
  (112 B), "You don't need to select the shield from the inventory. Crouch and press the direction opposite to the one
  I'm facing, and I'll use it!" (135 B), "You don't need to select the Red Xichrons from the inventory. " (62 B, trailing
  space) — **replaces the Phase 3 ◇ "USE-item hint conversations not built"**. `.HandleItemUse` M l. 44197–44301 (the
  player face = melee frame |c| − 1 from `_DAT_100a07cc` or the crouch set `_DAT_100a078c`; the held face = item
  `_DAT_100a5fd8`'s face (table `0x100a5f68`) or none; `+0x158 = −1`, `+0xeb = 0`; **c ∈ {3, 4, 5} → the held sprite
  carries the player-shot Handle/Hit/Tile, else the held Handle and no hit**; `.SetHeldItemPos`; damage 0 → 100, 0x12 →
  300 + `+0x158 = 4` + `+0xeb = 1`, 0x15 → 200 + `+0x158 = 1` + `+0xeb = 1`; seeds at c == 5 → `MTNewSprite(0x5a01,
  held centre, centre y − 4, 0xb)`, `+0xf4 = 1` for 0x1a, vx 0x60e (left: −, x256 + 0xc00), vy −0x60e, + player vx, +
  player vy when > 0, in-use = −1; c + 1, 6 → −5 — so 1…5, −5…−1, 0), `.SetHeldItemPos` M l. 43460–43533 (offsets
  (0x2d, 0x1e), (0x35, 0x1c), (0x42, 0x18), (0x47, 0x16), (0x54, 0x11) for |c| 1…5 — |c| 0 falls to (0x54, 0x11) —
  +0xc y crouching, + 0x16 y; the x mirror `100 − off` follows `PTR_DAT_100a04f4` (the facing **at the press**) while
  the −0x20 follows the player's **current** `+0x17e` (copied into the held sprite) — two sources, as written; the
  water contact `+0x11c` copied, ≥ 1), `.SetupHeldItemSprite` /
  `.HandleHeldItemSprite` M l. 43406–43459 (type 100, layer 0x14, rect = the face's opaque bounds +1/−1 horizontally,
  not mirrored), `.SmiteEnemies` M l. 46981–47046 (for the first 16 listed sprites whose Handle is one of the 15 at TOC
  0x100a048c…0x100a04c4 — the implementer resolves them with `pef.py` to `SpriteClass` cases and records the list; the
  inert Phase-1 enemies match by their class, Ruling 3 — `MTNewSprite(0x5a01, centre − 4, centre − 4, 0xb)`, `+0xf0 =
  0`, `+0xa6 = 0`), the potion drink row 32 M l. 45176–45218 (counter + 1; at 20: health 5 → HP = breath = player
  `+0xa4` = max, snds 502 + 415, `.RemoveItem`, `PTR_DAT_100a05a8 = 6`, health flash 0xb; magic 4 → magic = max, snds
  500 + 415, remove, `05a8 = 6`, magic flash 0xb; mist 0x19 → snd 415, remove, `05a8 = 6`; at 40 mist → the spirit
  trigger (MS); > 40 → 0). The hint is a modal moment inside the player's Handle (Invariant 5; Ruling 6). A hint raised inside a **nested**
  pass (the pause loop's or `.CheckGameLoopKeys`' redraws, `FerazelSession.swift:589–592`) **does arise**: `.PaintFrameWrap`
  runs `.HandleSprites` (M l. 9453) off the map, so a held USE on a key / shield / red Xichron during a nested pass
  reaches the switch. The nested pass suspends the same way (`.hint` with a nested flag), `LevelRun` runs the hint
  inside the outer modal (pause / confirm), and `resume(.hint)` finishes the nested pass, then hands control back to
  the outer modal's state machine; `testHintSuspendsInsidePlayerHandle` covers the top-level case and gains an assert
  for one nested case (a pause redraw with USE held on the Steel Key).
- **Tests (8):** `testDaggerStab` (USE with the dagger: snd 418; counter 1, 2, 3, 4, 5, −5 … −1, 0 over 10 frames; the
  held sprite `.playerShot` only at c 3, 4, 5, damage 100; Ice Pick 300 / strength 4; Vorpal Dirk 200; with magic 0
  and the Fireball selected the press moves the dagger to the front (CS) and the **same frame** stabs — snd 418,
  counter 1; after a cast press `075c` is 0 at the end of the call — the gate's clear, M l. 47353ff) ·
  `testHeldItemPositions` (c 1 facing right: (x + 0x2d, y + 0x1e + 0x16); c 5 crouching: (x + 0x54, y + 0x11 + 0xc +
  0x16); pressed facing left, c 3: x + (100 − 0x42) − 0x20; pressed facing left then turned right mid-swing: x + (100 −
  off) with no −0x20) · `testSeedsThrown` (fire seeds count 2 → 1 at the press; at c == 5 a
  0x5a01 with vx 0x60e + player vx, vy −0x60e; facing left vx −0x60e + pvx and x256 + 0xc00; Ziridium `+0xf4 = 1`) ·
  `testPotionsDrink` (health potion at HP 0x100: frame 20 → HP = breath = 0x230, snds 502, 415, count − 1, health flash
  0xb; the counter 0 after frame 41; magic potion → magic = max, magic flash 0xb) · `testEscapeRing` (USE → snd 421,
  exit −1, level complete; `LevelRun` skips the stage-complete panel and `WorldMapRun` unlocks nothing; the ring
  removed) · `testSmitingRing` (level 1 with three active enemies: three 0x5a01 at their centres − 4, flash 3, snd 421,
  the ring removed) · `testHintSuspendsInsidePlayerHandle` (the Steel Key selected + USE → `.hint(text:)` with the
  112-byte text raised from the player's Handle; resumed with UP held → the climb/down blocks and the jump arm read the
  resumed keys; the sprites after the player in the list handled once that frame) · `testShieldRaiseNeedsShield`
  (crouch + push away from facing with no shield → no raise; with item 0xe → the raise as P2's `downBlock` builds it).
- **Gate:** G2 = 433, G6, G7(+b), G8, G10. **Commit:** `FerazelCore: USE with an item (held weapon, thrown seeds, potions, rings, the hint conversations inside the player's Handle), the shield needs a shield; 8 tests`.

#### MS — minor — the Mist potion, the Resurrection Necklace, the Fire Charm, the Multi Crystal (→ 438)
- **Files:** `Sources/FerazelCore/Player/Player.swift` (row 16 spirit form, M l. 44827–44855; row 13's crystal loss,
  M l. 44743–44747; row 41's necklace), `Sources/FerazelCore/Player/PlayerStates.swift` (the spirit transition
  `_DAT_100a0574`, M l. 45590–45624; the necklace revive, `PlayerStates.swift:87–92`), `Sources/FerazelCore/Player/HitPlayerSprite.swift`
  (the Mist body 69's arm — PK wrote its state — and the spirit gate; `HurtPlayer`'s item-0x13 arm,
  `HitPlayerSprite.swift:394–421`; the Background fire arm's `HasItem(0x18)`, `HitPlayerSprite.swift:71`),
  `Sources/FerazelCore/Player/PlayerLiquids.swift` (the lava immunity with the Fire Charm, if read there),
  `Tests/FerazelCoreTests/PassiveItemTests.swift` (new).
- **Contract:** spells-items §4 (0x13, 0x17, 0x18, 0x19); pickups-boxes §1.3 row 69; enemy-shots-and-damage §3.5 (the
  0x13 arm: `_DAT_100a073c` loss timer, the 4 shards 0x4bf…0x4c2, not for Blob attackers nor Background 0x730…0x733);
  physics §5.2 (the necklace); player-states §3 (spirit, revive). Dump rows as cited. Mist: the drink's frame 40 starts
  the spirit transition (`_DAT_100a0574`), the body sprite 69 left at the player, `_DAT_100a0578 = 600` frames; the body
  touched with the timer ≤ 0x167 → back in the body (PK's arm: `0578 = −1`, `0574 = 0xe`, `05a8 = 6`, snd 420, the body
  killed, teleported to the stored x/y, v 0). Necklace:
  `.HasItemWhichSlot(0x17)` at death (not on the glider) → the revive (faces 1022[(30 − r)/3], HP/breath refilled,
  `.RemoveItem(0x17)`). Crystal loss: `_DAT_100a073c` − 1 → at 0 with item 0x13 → `.RemoveItem(0x13)` +
  `.UpdateStatusBar(1,1,0)` (M l. 44743–44747).
- **Tests (5):** `testMistSpiritForm` (drink the Mist potion: spirit at frame 40, body 69 at the player, 600-frame
  timer; only Bonus contacts reach `.HitPlayerSprite`) · `testMistBodyReturn` (spirit timer ≤ 0x167 touching the body
  → snd 420, the player at the body's x/y, v 0, body killed) · `testNecklaceRevives` (HP < 1 with item 0x17: the revive
  sequence, the necklace removed; on the glider → no revive) · `testFireCharmImmunity` (a fire Background 0x4b8 with
  item 0x18 → no hurt; without → `HurtPlayer(0xe0, 1, 0x3c, 0)`) · `testCrystalLostAfterHurt` (two Multi Crystals:
  hurt → `073c` set, four shards; at 0 one crystal removed, count 1, the status bar call (1,1,0)).
- **Gate:** G2 = 438, G5 (wave 4.5 end), G6, G7(+b), G8, G10; wave end: G3. **Commit:** `FerazelCore: Mist potion spirit form, Resurrection Necklace, Fire Charm, Multi Crystal loss; 5 tests`.

### Wave 4.6 — the Shadow Double and the Pentashield, the Box class

#### SD — ⚑ MAJOR — the Shadow Double and the Pentashield (→ 443)
- **Files:** `Sources/FerazelCore/Player/ShadowDouble.swift` (new: `.SetupShadowSprite` M l. 43167–43182,
  `.HandleShadowSprite` M l. 43052–43166, the pose ring `PTR_DAT_100a0520` (14 × 16 B) written by row 42),
  `Sources/FerazelCore/Player/Pentashield.swift` (new: `.UpdatePentSprites` M l. 44127–44196), `Sources/FerazelCore/Player/Player.swift`
  (row 11 the double, M l. 44674–44685; row 42 the ring and `.UpdatePentSprites`, M l. 46648), `Sources/FerazelCore/Shots/CastSpell.swift`
  (the double's copy — CS built the spawn; SD gives it the double's pose), `Sources/FerazelCore/Sprites/SpriteSlot.swift`
  (`SpriteHandler.shadow`), `Sources/FerazelCore/Player/PlayerStates.swift` (`PlayerStates.swift:67`'s "Shadow Double off"),
  `Sources/FerazelCore/Session/FerazelSession.swift` (the handle-pass switch gains `.shadow`, l. 389–429),
  `Tests/FerazelCoreTests/ShadowPentaTests.swift` (new).
- **Contract:** held-item-melee §2 (Shadow Double 0x1b39); spells-items §2 item 6, §5; spells-detail §2.3 (the copy:
  type id·256 + 1, 0 damage, vx sign by the double's facing, vy −0x44c when the replayed frame is grounded and the shot
  has gravity); spells-detail §3.8 + pickups-boxes §3.3 (the orbs 0x5001: layer player + 1, record 0x1ff, `+0x164 =
  −10`, angle += speed mod 0x16800, radius `+0xc` of the slot around the centre (−10, −10); +5 per sphere, max 8, 360°/n,
  radius 0x30; 3 hits; no tiles; destroys enemy shots (Phase 5)).
- **Tests (5):** `testShadowReplaysPoses` (1330: the double follows the player's pose ring 14 entries behind (or the
  dump's lag), its face and position from the ring) · `testShadowCopiesCast` (a Fireball with the double active: a second
  shot of type 0x0001 (power 1); a V Blade → two copies, both type 0x601 at the double's offset, `+0xa4` 0 after age 1, vx negated when the double faces left) ·
  `testShadowEndsWithTimer` (600 frames → the double removed, `PTR_DAT_100a0654 = 0`) · `testPentashieldOrbs` (1338: 5
  orbs 0x50 at 72° spacing, radius 0x30, `+0x164` −10 counting up; a second sphere → 8, not 10) · `testOrbHitsAndPops`
  (an orb into a crate: hits 3 → 2, snd 423; at 0 snd 424 and the burst; orbs open no containers).
- **Gate:** G2 = 443, G6, G7(+b), G8, G10. **Commit:** `FerazelCore: the Shadow Double (pose ring, cast copies) and the Pentashield orbs; 5 tests`.

#### BX1 — ⚑ MAJOR ◈ — the Box class tail, crates and their drops, boulders, mine carts, stalactites (→ 451)
- **Files:** `Sources/FerazelCore/World/Movers/BoxSprite.swift` (the common Handle tail, `.HitBoxSprite`,
  `.HitBoxTileSprite`, `.KillBox`, `.KillCrate`, the crate / boulder 1070…1072 / mine cart 2930…2931 / stalactite 2932
  arms; `BoxSprite.swift:8`, `:269–:290`'s "not built" list retired), `Sources/FerazelCore/Sprites/SetupFaces.swift`
  (the crate, mine-cart and boulder Setup arms complete — mass `+0x138`, friction `+0x114`, `+0x112`, gravity, `+0x90`,
  `+0x1c8…+0x1ce`, rects; the mine cart's children 0xb72 / 0xb73), `Sources/FerazelCore/Player/HitPlayerSprite.swift`
  (the Box arm's spin stomp on crates and switch blocks, M l. 49364–49406), `Sources/FerazelCore/Player/HandleKeys.swift`
  (`footPressure` is already shared, `HandleKeys.swift:245` — no change unless the Box caller needs a seam),
  `Sources/FerazelCore/Session/{FerazelSession,SpriteWorld}.swift` (Box collide/tile dispatch, mine-cart children
  following), `Tests/FerazelCoreTests/BoxMechanismTests.swift` (new).
- **Contract:** pickups-boxes §2.1 (defaults and tail), §2.2 rows 1070…1072, 2930/2931, 2932, 3090…3092, §2.4.1;
  pickups-boxes-2 §4.2, §7; physics §8.1 (pushing). Dump: `.SetupBoxSprite` M l. 58892–59730 (`+0xa6 = 3`, gravity
  0x151, HP 600, the arms, the tail `+0x13c = 0x80`), `.HandleBoxSprite` M l. 60030–61180 (returns on dying /
  `+0x1b2`; `.StandardSpriteHandles`; `+0x182 = 0`; the arm; the tail: `ApplyFriction(+0x114)`, `.FootPressure` when
  grounded last frame (`+0xcd`, not 0x438/0x439), `EnforceMaxSpeed(0x1838)`, `y += vy`, gravity ≠ 0 →
  `ApplyGravityAndSeparateFromTiles`, the mine cart's children, `BoxCleanUp` (`.BoxUW` splash, `.BoxClean`)), the boulder
  roll (`+0x46 += distance·360/0x6900`, `+0x1aa`; a tile hit at `|vy| > 0x1ff` bounces 0x3c with a thud past 0x300),
  the mine cart (face by the ground kind under it, the wheel frame by `vx >> 9`), the crate's death from the Handle at
  HP ≤ 0, `.HitBoxSprite` M l. 61328–61482 (Box vs Box/Statue/Platform: the mutual `.PlatformBounce` ordered by the
  grounded flags, then height, then speed, `+0x182` latched; NPCs 0xb87…0xbb7 and blocks 0x4e2…0x4ff ignore contacts;
  a crate hit by a player shot with `+0xa6 == 0` loses the shot's `+0xa4` and the shot is killed; by an Effect 0x4b7 −10;
  the stalactite's shot case is SH's; the 2941's death arm — HP < 1 → `.ExplodeFaceIntoParticles` + `+0xe9 = 1`, raw
  `1006f564..1006f5b0` — is BX1's, though no 2941 is placed before level 30), `.HitBoxTileSprite` M l. 61521–61683, `.KillBox` M l. 61483–61520, `.KillCrate`
  M l. 61181–61327 (nothing unless HP ≤ 0; `+0xea = +0xe9 = 1`; snd 492 pri 100 vol 0x100 `STPlay3DSoundRand`; 16
  debris 0xc1b from a 4×4 grid (R(0x96), R(600) per piece) and 16 × 0xc81 (R(200), R(5)) for 3092 or 8 × 0x442 dust
  (R(0x96), R(7)) otherwise; p1 = 2 → snd 435 and a 0x4b7 at (cx − 0x30, cy − 0x36) layer 0xc, no drop; p1 ∈ {0, 1} →
  p2 × p3 drops (p3 0 written back as 1): Bonus types 1290…1293, 1055, 1300, 1301, 1302, 1305, 1306, 1340, 1341 →
  `MTNewSprite(p2, x + 0x16, y + 0x15, 0x14, .SetupBonusSprite)` re-centred, `vy = −2000 − R(1000)`, `vx = R(800) − 400`
  unless p3 == 1, `+0xb0 = 12`; any other p2 > 0 → `.GenerateSprite(p2, …, rec 0x200, now, layer + 1)` re-centred (items
  ≥ 3200 gravity 0x151, the same velocities; a Bat 0x6cc drop gets its random velocity and `+0xa6` — the arm after
  `.GenerateSprite`, M l. 61312–61320, transcribed as read); other p1 → nothing). The spin stomp (M l. 49364–49406): spinning
  `PTR_DAT_100a0668`, HP > 0, a block 0x4e2…0x4ff or crate 0xc12…0xc1b, cooldown `PTR_DAT_100a060c == 0`, entry vy >
  0x9c4, record p4 ≠ 1 → crate HP −100 (block −1 with an `STPlay3DSoundRand`), the player rebounds `vy = −|0.9·vy|`
  (keeps spinning with DOWN held, snd 427 vol 0xba; else the spin sound stopped if playing — `SoundVoices` not needed:
  a stop), cooldown 5, airborne. Census on levels 1–4 (Research note 3): crates L1 recs 31 (3219 × 1), 32 (1291 × 3), 65
  (1293 × 0 → 1), 130 (3092 explosive); boulders L2 rec 21, L3 rec 28; mine carts L3 recs 25, 67; stalactites L2 recs
  158–160.
- **◈ goldens:** the tail now runs for every Box on levels 1–2 (crates settle under gravity 0x100 and friction; the
  boulder rolls) — the in-level goldens may move; recorded old → new with the cause.
- **Tests (8):** `testCrateDropsBonus` (level 1 rec 32: a crate p2 1291, p3 3 at HP 5 hit by a Fireball (100) → KillCrate:
  three 0x50b drops at (x + 0x16, y + 0x15) re-centred, vy −2000 − R(1000), vx R(800) − 400, `+0xb0` 12; the record
  inactive) · `testCrateP3One` (p3 1 → one drop with vx 0) · `testExplosiveCrate` (level 1 rec 130 (3092, p1 2): snd
  492 then 435, 16 × 0xc1b, 16 × 0xc81, one 0x4b7 at (cx − 0x30, cy − 0x36), no drop) · `testCrateDropsItemViaGenerate`
  (p2 3219 → `.GenerateSprite` with record 0x200: the item falls (its record reads as zeros, Hazards)) ·
  `testSpinStompCrate` (spin landing at vy 0xa00 on a crate: HP 5 → −95 → KillCrate; the player vy −|0.9·0xa00|
  truncated, cooldown 5; at vy 0x9c4 no stomp) · `testBoxFallsAndSettles` (a crate placed 40 px above the floor: gravity
  0x100 per frame, lands, friction 0x5a stops a push) · `testBoulderRolls` (pushed 0x6900/360 px → `+0x46` + 1; a fall
  landing at vy 0x320 → bounce factor 0x3c and the thud) · `testStalactiteFalls` (level 2 rec 158 HP 150: a Fireball →
  HP 50 and a shake of 5 + R(2) frames; a second → HP < 1 → gravity 0xfa).
- **Gate:** G2 = 451, G5 (wave 4.6 end), G6, G7(+b), G8, G10; wave end: G3. **Commit:** `FerazelCore: the Box class tail, crates (KillCrate drops and explosions, spin stomp), boulders, mine carts, stalactites; goldens moved as recorded; 8 tests`.

### Wave 4.7 — chests and doors, switches, teleporters

#### BX2 — minor ◈ — chests, doors and keys, the thought balloons (→ 457)
- **Files:** `Sources/FerazelCore/World/Movers/BoxSprite.swift` (the chest 0x51c and door 0xb5e/0xb5f Handle arms;
  `.CreateBalloonSprite`), `Sources/FerazelCore/Player/HitPlayerSprite.swift` (the Box arm's door / chest / timer
  0xb5b branches, M l. 49211–49286 — replacing `HitPlayerSprite.swift:159`'s `// later`), `Sources/FerazelCore/Player/GroundCeilingEffects.swift`
  (the balloon effects 3250 / 3250 + n are EF's ids; their creation here), `Sources/FerazelCore/Items/Inventory.swift`
  (`hasItem` / `removeItem` — used, not changed), `Tests/FerazelCoreTests/ChestDoorTests.swift` (new).
- **Contract:** pickups-boxes §2.4.2 (chests), §2.4.3 (doors and keys); spells-items §4 (keys are global inventory).
  Dump: the Box arm M l. 49211–49286 (door: key `|p1|`; needed and not held → nothing; held → `.RemoveItem(key)`, record
  p1 = 0, snd 437; already unlocked → snd 438; then 2910 opens (`+0x46 = 1`) only when the player's vx > 0, 2911 only
  when vx < 0; chest: any contact while `+0x46 == 0`, unlocked or `.HaveItem(|p1|)`, **and p3 > 0** → `.RemoveItem` if
  locked (record p1 kept), snd 439, `+0x46 = 1`; the 2907 timer: `+0xa6 == 0` → `+0xa6 = 100`, pitched sound 44000,
  `iRam100a5110 = p1·30 − 1` (built as read; no 2907 on levels 1–4)), `.HandleBoxSprite`'s chest arm (lid `+0x46 / 3`
  to 11; `+0xa6` − 1; at 0 with p3 > 0 → one `MTNewSprite(p2, x + 0x10, y + 0xd, player layer + 1, .SetupBonusSprite)`
  — **always the Bonus Setup**; the drop's layer set to the player layer + 1 through `.MTChangeSpriteLayer` (a re-sort of
  the list, `SpriteWorld.changeLayer`) — re-centred, light removed if p3 > 2, `vy = −2000 − R(1000)`, `vx = R(800) − 400`,
  gravity 0x151 if 0, `+0xb0 = 12`; `+0xa6 = 4`; record p3 − 1 (raw `1006e7a4..1006e7d0`); closed face while p3 > 0,
  open frame 3 at p3 0; locked and closed → the balloon within 0x4b px on both axes) and door arm (face `|+0x46| >> 1`;
  closed and locked → the balloon; `+0x46` + 1 per frame once opened; at 7 the rect zeroed; ≥ 11 → 10 and record p4 =
  1; p4 = 1 at load → open at once), `.CreateBalloonSprite` M l. 59921–59966 (0xcb2 + the key's item face, ids 1…26
  only; layers 100 / 101). Levels 1–4 (Research note 3): L1 chest 23 (Steel Key) → locked chest 38 (key 1; Gold Key) →
  door 55 (key 2); L2 doors 97 (key 2) and 212 (2911, key 1) with chests 51 (Gold Key) and 52 (Steel Key); L3 door 68
  (2911, key 3 — the Platinum Key from `Mcnv 205`, the Wounded Habnabit); L4 door 56 (key 1) and chest 55.
- **◈ goldens:** a scripted path near a locked chest or door now shows its balloon; recorded old → new.
- **Tests (6):** `testLevel1KeyChain` (level 1: chest 23 opened → a 3201 Steel Key every 4 frames until p3 0 (one); the
  locked chest 38 with the Steel Key → the key removed, a 3202; door 55 with the Gold Key while moving right → opens over
  11 frames, rect zeroed at 7, record p4 = 1, p1 = 0) · `testDoorNeedsKeyAndDirection` (no key → nothing; with key moving
  left into a 2910 → unlocked (p1 0, snd 437) but not opened; next contact moving right → snd 438, opens) ·
  `testChestDropsEveryFourFrames` (level 1 chest 72 (1302 × 20): one coin each time `+0xa6` (4 at Setup, 4 after
  each drop) reaches 0 — 20 coins, record p3 20 → 0, then the open face frame 3)
  · `testChestAlwaysBonusSetup` (a chest with p2 1730 (an enemy type) spawns it through the Bonus Setup — the as-written
  quirk, no `.GenerateSprite`) · `testBalloonNearLockedChest` (within 0x4b px on both axes: a 0xcb2 balloon with the key
  face; at 0x4c px none; an unlocked chest none) · `testOpenDoorPersists` (a save-point resume after opening door 55 →
  the door Setup with p4 1 opens at once; the key stays spent).
- **Gate:** G2 = 457, G6, G7(+b), G8, G10. **Commit:** `FerazelCore: chests, doors and keys, the thought balloons; 6 tests`.

#### BT — minor — Buttons, gates, switch blocks, boulder spouts (→ 463)
- **Files:** `Sources/FerazelCore/World/Movers/ButtonSprite.swift` (new: `.InitButtonSprite`, `.SetupButtonSprite`,
  `.HandleButtonSprite`, `.HitButtonSprite`), `Sources/FerazelCore/World/Movers/BoxSprite.swift` (gate 2940, switch blocks
  1250…1279, spouts 1450…1453 arms + Setups), `Sources/FerazelCore/Sprites/SetupFaces.swift` (the `.button` class arm;
  the Box arms for 1250 / 1450…1453 / 2940), `Sources/FerazelCore/Sprites/SpriteSlot.swift` (`SpriteHandler.button`),
  `Sources/FerazelCore/World/Movers/BackgroundSprite.swift` (the Button exclusion at `BackgroundSprite.swift:432` now
  `handler == .button`), `Sources/FerazelCore/Session/{FerazelSession,SpriteWorld}.swift` (dispatch), `Sources/FerazelCore/Sound/SoundVoices.swift`
  (used by the gate's idle-only sounds), `Tests/FerazelCoreTests/ButtonGateTests.swift` (new).
- **Contract:** triggers-background §1 (Buttons, the linkage, the census); triggers-background-2 §8.5; pickups-boxes
  §2.2 rows 1250…1279, 1450…1453, 2940; §2.4.4, §2.4.5. Dump: `.InitButtonSprite` / `.SetupButtonSprite` /
  `.HandleButtonSprite` / `.HitButtonSprite` M l. 61684–61845 (faces 1320 / 1321 (6 cells 14×12), 1322 (8 cells 32×21);
  rects 1320 (0,−20,20,12), 1321 (−4,0,16,12), 1322 (8,4,24,20); layer 1; first Handle: record p4 ≠ 0 → level 10;
  each frame unless (level ≥ 9 ∧ p1 == 1) level − 1, clamp 0…11 (1322 ≤ 9); snd 4705 vol 0x100 pri 10 positional when it
  drops below the previous value and the previous was 5; record p4 = (level ≥ 9); faces 1320/1321 `level >> 1`, 1322
  `clamp(level − 2, 0, 7)`; pressed by the player / a Platform / a Box / a Statue: level 0 → snd 4704, level + 8; by a
  player shot (or an enemy shot): snd 4704, level 11), the gate 2940 (`.HandleBoxSprite`: p1 ≥ 0 → open ⇔ record[p1].p4
  == 1; p1 −1 / −2 as read (bosses / the 2907 timer — none on levels 1–4); open: rise 2 px/frame (`+0x1c` − 0x200) to
  100 px above `+0x158`, closed: back down; the moving sounds at M l. 61040–61057 are **idle-only** and made only when the new y differs from `+0xc4` (the
  previous y) —
  `if (!FUN_100916dc(snd)) STPlay3DSoundRand(snd, 1, 0x100, …)` — decided by `SoundVoices` (VS; the Phase 2 carry,
  Ruling 5), the draw made only when the call is; the clip `+0x1bc = start − y + 7` (+0x20 if p2)), the switch block
  (p1 == 2: solid + visible ⇔ record[p2].p4 == 1, else rect empty and the PICT 1252 outline face; snapped to 8 px;
  layer −(2y + x); 1270 animated), the spout (M l. 60488–60547: `+0xa6` > 0 → − 1; at 0, when record[p1].p4 == 1 ∨
  record[p2].p4 == 1 → **◇ Phase 5: the enemy shot `0x6e1 + own p4` is not spawned** (no EnemyShot Setup yet); the
  spout still makes the two velocity draws its type makes after a successful spawn (1450 R(300), R(400); 1451 R(300),
  R(300); 1452 R(600), R(700); 1453 R(600), R(700)) and `+0xa6 = R(30) + 50`; neither pressed → the timer stays 0 and
  re-tests every frame). Levels 3–4: L3 gate 72 ← Button 90 (1322, latching p1 1); L4 blocks 53/58/59/60/61 ← Button 57
  (1322 latching), 62/64/65/66 ← Button 63 (1320 latching), spouts 28 (← 30, 31; p4 1 → 0x6e2), 67/70 (← 63), 68 (← 57),
  183 (record 0 twice: never fires).
- **Tests (6):** `testMomentaryButton` (1322 p1 0 stood on from frame 1: the Handle runs before the press each frame, so
  the level after frame 1 is 8 (snd 4704), after frame 2 15, and frame 3's Handle clamps 14 → 9 and writes record p4 =
  1 (0 on frames 1–2); stepping off: the first Handle yields 9 (p4 still 1), then 8 (p4 0), 7, 6, 5,
  and 4 plays snd 4705) · `testLatchingButton` (p1 1: once ≥ 9 it stays; p4
  1 survives a save-point resume via the record — the first Handle's level 10) · `testShotPressesButton` (a Fireball →
  level 11, p4 1) · `testGateRisesWithButton` (level 3 gate 72: Button 90 pressed → the gate rises 2 px/frame for 50
  frames (100 px) then stops; the idle-only sound: with its snd in `playing` → no cue and no draw; idle → a cue and one
  R(10000)) · `testSwitchBlocksFollowButton` (level 4 block 53: solid with rect (1,1,0x23,0x23) only while record 57's
  p4 == 1, else the outline face and an empty rect) · `testSpoutTimerAndDraws` (level 4 spout 28 with Button 30 pressed:
  at `+0xa6` 0 → no sprite, R(300), R(400), then R(30) → `+0xa6` = 50 + it; unpressed → no draws).
- **Gate:** G2 = 463, G6, G7(+b), G8, G10. **Commit:** `FerazelCore: Buttons, gates (idle-only sounds via SoundVoices), switch blocks, boulder spouts (shots in Phase 5); 6 tests`.

#### TP — ⚑ MAJOR — teleporters and the mosaic (→ 467)
- **Files:** `Sources/FerazelCore/Player/HitPlayerSprite.swift` (the teleporter branch of the Box arm, M l.
  49407–49470), `Sources/FerazelCore/Player/PlayerStates.swift` (row 36's fire pulse `0708` at charge 80,
  `PlayerStates.swift:525`; the `070c` writer, `PlayerState.swift:322`), `Sources/FerazelCore/Seams/FrameSuspension.swift`
  (`.teleport(record:stage:)`, `Outcome.teleport`), `Sources/FerazelCore/Seams/DrawOp.swift` (`.mosaic`),
  `Sources/FerazelCore/Session/FerazelSession.swift` (suspend in the special pass twice; `resume(.teleport)` per stage),
  `Sources/FerazelCore/Front/LevelRun.swift` (the two 57-tick mosaics), `Sources/FerazelCore/Camera/Camera.swift` (120
  `.FindUpperLeftCorner` passes with the ease flag cleared), `Sources/FerazelCore/Sprites/IdleSprites.swift` (the entry
  search by record index over **in-use** entries — `activeID` entries included), `Sources/FerazelRender/Frame/Mosaic.swift`
  (new), `Sources/FerazelRender/Frame/FrameRenderer.swift` (executes `.mosaic`), `Sources/FerazelRender/Screens/ScreenRenderer.swift`
  (refuses `.mosaic` off a level), `Tests/FerazelCoreTests/SessionTests.swift` (the exhaustive `DrawOp` switch, l. 288),
  `Tests/FerazelRenderTests/{FrameGoldenTests,Phase2GoldenTests}.swift` (the drivers resume `.teleport`; counts
  unchanged), `Tests/FerazelCoreTests/TeleporterTests.swift` (new), `Tests/FerazelRenderTests/ScreenTests.swift` (one added).
- **Contract:** pickups-boxes §2.4.7 (+ BC40). Dump M l. 49407–49470: on a landing on 0x424…0x426: `PTR_DAT_100a070c =
  1`, `*_DAT_100a068c = 0` (the idle counter; `puVar11` holds `_DAT_100a068c` from M l. 49341, stored at M l. 49410);
  the fire pulse `PTR_DAT_100a0708` clear → return; else snd 421 and **stage 1**: the session
  suspends `.teleport(record:, stage: 1)` for `.MosaicTransition(1, 3, 0x14)` (`LevelRun` emits 20 `.mosaic` blits —
  cells 1…20 — with a 3-tick wait between, 57 ticks). At the stage-1 resume: d = player − teleporter (x, y); **every**
  idle-table entry (`DAT_100ac02c`, 0x1ff entries × 0x220) whose in-use byte is set (M l. 48564, 49416 — the dump tests
  only that byte, not whether the sprite is currently active; Core's `IdleSprites` keeps an entry while its sprite is
  active, `activeID`) and whose record index (`+0xe`) == this teleporter's p1 → the player at entry (x, y) + d, the
  centre and the globals `fd94`/`fd90`/`fe68`/`fe64` as the dump stores them, 24.8 copies, `+0xdc = 0`, the scroll point
  (x − 0x142, y − 0xc0), the ease flag cleared, 120 `.FindUpperLeftCorner` calls, the flag restored, the scroll copies,
  `.RedrawEntireScrollGrid` (a later match moves again — last wins); then `.HandleIdleSprites`, `.WrapDrawSprites`, snd
  420 and **stage 2**: the session suspends `.teleport(record:, stage: 2)` for `.MosaicTransition(0, 3, 0x14)` (cells
  20…1, 57 ticks). At the stage-2 resume: `.RedrawEntireScrollGrid`, `0708 = 0`, charge `PTR_DAT_100a0700 = −59`
  (0xffc5), then the rest of the frame. Teleporters spawn idle (box idle, `SpriteClassTable`), so a partner always has an
  in-use entry; a p1 naming a non-teleporter idle record moves the player to it. `.MosaicTransition` M l. 12944–13018
  (graphics mode 3 is demoted to 2 **before** the blits, so `.MosaicScreenBlit`'s mode-3 argument is always false —
  `.mosaic(graphicsMode3:)` carries false; `.WrapDrawSprites` + `.WrapCopyToScreen` first, the blits, mode 3 restored
  with `.DrawBlackLines`), `.MosaicScreenBlit` M l. 12854–12943 (Render). Levels 1–4 (Research note 3): L1 148 ↔ 149, 126
  → record 0 (a type-2922 piece of furniture at (5455, 666), idle-spawned — the player is moved there); L2 13 ↔ 75 (85,
  209 → 75 / 13); L3 63 ↔ 64; L4 41 ↔ 42 (69, 72, 73 → 42).
- **Tests (4):** `testTeleportPair` (level 1 record 148 with 149 in the idle table: charge to 80 → the fire pulse → snd
  421, stage 1; after it the player at 149's (x, y) + d; snd 420, stage 2; after it charge −59, `0708` 0; the same also
  when 149's sprite is active) · `testMosaicTicks` (`LevelRun`: 20 out-blits over 57 ticks, the move, 20 in-blits over 57
  ticks, the same frame resumed; every `.mosaic` with `graphicsMode3` false at prefs+2 = 3) · `testTeleporterToRecordZero`
  (level 1 record 126 (p1 0) → the player at record 0's 2922 entry (5455, 666) + d) · Render `testMosaicBlit` (cell 4
  on a 608×384 view: every 4×4 block one index, the block pixel the dump picks — recorded).
- **Gate:** G2 = 467, G5 (wave 4.7 end), G6, G7(+b), G8, G10; wave end: G3. **Commit:** `FerazelCore: teleporters (the charge pulse, the in-use idle-entry search, the camera re-seat) with the two-stage mosaic inside the frame; 4 tests`.

### Wave 4.8 — the spells' world effects, levels 3 and 4

#### SW — minor — the spells' world effects: Ice Wall floes and ledges, Tree Trunk, Statue (→ 473)
- **Files:** `Sources/FerazelCore/Shots/PlayerShot.swift`, `Sources/FerazelCore/Shots/PlayerShotHits.swift` (the floe,
  ledge and trunk spawns), `Sources/FerazelCore/World/Movers/BoxSprite.swift` (trunks 712/713: Setup arms, Handle
  lifetime/blink, `.HitBoxTileSprite`'s 713 → 712), `Sources/FerazelCore/World/Movers/StatueSprite.swift` (new:
  `.TurnIntoStatue`, `.HandleStatueSprite`), `Sources/FerazelCore/World/Movers/PlatformSprite.swift` (the Statue site of
  `.HitPlatformSprite`, M l. 55798–55803, replacing its `// later: Phase 4`), `Sources/FerazelCore/Sprites/SpriteSlot.swift`
  (`SpriteHandler.statue`; saved Handle `+0x1ec`, hit `+0x1f0`, tile `+0x1f4`, timer `+0x130`, saved `+0xb8` `+0x134`),
  `Sources/FerazelCore/Session/FerazelSession.swift` (the handle-pass switch, l. 389–429, has no default — `.statue`),
  `Sources/FerazelCore/World/Movers/BackgroundSprite.swift` (the cannon capture excludes the Statue Handle,
  `BackgroundSprite.swift:400–436` — A7), `Tests/FerazelCoreTests/SpellWorldTests.swift` (new).
- **Contract:** spells-detail §3.4 (floes, ledges: the shot writes `+0xb0 = 4`, `+0xa6 = 0xb4`, `+0x16c` 0 / 1 / 2;
  physics §8.9 mode 4 — PlatformSprite's mode 4 is built, W1), §3.5 (trunks), §3.6; pickups-boxes §2.4.9; Dump:
  `.TurnIntoStatue` M l. 38244–38272 (snd 302 `STPlay3DSound` vol 0x32 — no draw; saves `+0x4c`/`+0x5c`/`+0x1f8` into
  `+0x1ec`/`+0x1f0`/`+0x1f4`; `+0x130 = 0x78`; `+0x134 = +0xb8`; the Statue Handle/Hit/Tile callbacks; v = 0),
  `.HandleStatueSprite` M l. 56521–56555 (no light → `AddLight(face _DAT_100a099c, centre, …, 0x21)`; `+0xb8 =
  0x1000b`; timer − 1; v = 0; `+0x80 = 2` stored directly (no re-sort); timer < 20 and odd → `+0xb8 = 0`; < 1 → the
  saved callbacks and `+0xb8` restored, **HP −200**, light removed), the Platform site M l. 55798–55803 (a player shot
  with `+4 == 1` → shot `+0xe9 = 1`, platform `+0x190 = 0`, `.TurnIntoStatue(platform)`). Enemies' 11 statue sites are
  Phase 5 (◇). Trunks: 712 at (cx−8, cy−6) layer 2 with `+0xa6 = parity + 120`, effect 2 at (x−6, y−9) `+0x46 = 8`
  light 0x42, snd 302, the shot's kill flag set directly (followers orphaned — spells-detail-2 §5); growth: walk
  `+0x1d4` to the top, 713 at (top.x, top.y − 16), lifetime parity + 120, old top ≥ 35; Handle: −1 per frame, blink
  0xb0001 (< 23), 0xb0000 (< 21), 0xb0002 (< 11), killed < 1; 712 gravity 0x15e rect (3,4,0x1d,0x18), 713 gravity 0 rect
  (3,3,0x1d,0x15); a landing 713 → 712 with gravity 0.
- **Tests (6):** `testIceWallFloe` (an Ice Wall shot into water: a 0x57c at (x−10, cy−4) with `+0xb0 = 4`, `+0x16c = 0`,
  `+0xa6 = 0xb4`; the shot killed) · `testIceWallLedge` (into an FG kind-2 wall: a ledge at (tileX − 0x17, cy) variant 1;
  kind 0: (tileX + 0xf, cy) variant 2; a floor contact makes nothing; spell 7 makes neither) · `testTrunkPlanted` (a
  Tree Trunk shot landing: 712 at (cx−8, cy−6), lifetime 120 or 121 by `_DAT_1009fd30`, effect 2, snd 302; its
  followers stay alive) · `testTrunkGrows` (a second shot into the trunk: 713 at (x, y−16) linked as `+0x1d4`; the old
  top's lifetime raised to 35 when below) · `testStatueFreezesPlatform` (a Statue shot into a moving platform: the
  shot `+0xe9 = 1`, the platform's Handle the Statue's for 120 frames with v 0, `+0xb8 0x1000b` (0 on odd frames below
  20), then its callbacks back and HP −200) · `testFollowerPetrifies` (a power-0 follower of id 1 touching the platform
  petrifies it too — the site tests only `+4 == 1`).
- **Gate:** G2 = 473, G6, G7(+b), G8, G10. **Commit:** `FerazelCore: Ice Wall floes and ledges, Tree Trunk segments, Statue (.TurnIntoStatue on platforms); 6 tests`.

#### LV3 — ⚑ MAJOR — level 3 "Western Reaches" enterable (→ 477)
- **Files:** `Sources/FerazelCore/Front/BuiltLevels.swift` (`1...3`), `Sources/FerazelCore/Sprites/SetupFaces.swift`
  (the level-3 types no task covered: the enemy face stubs Bat 1741 (0x6cd, p1 2) and Blob 1730 (0x6c2) — the Phase-1 ◇
  shape, Ruling 3; the Blob Setup counts itself as an enemy — `+0x1b5` and `_DAT_1009ffb4` — so the totals tally at
  `SetupFaces.swift:575–580` gains a Blob arm (A9); the decorations 2812, 2813, 2820, 2821, 2832, 2843, 2868, 2869, 2884,
  refused today because their face sheets are outside the table — their per-type rows, pickups-boxes-2 §9, and sheets
  added (B9); anything else the census test below finds), `Sources/FerazelCore/World/Movers/BackgroundSprite.swift` (the
  retracting spikes 1840…1843: Setup (now-spawned), Handle — the idle-only sounds of 0x732 / 0x733 at M l. 63199–63257
  through `SoundVoices` (Phase 2 carry, Ruling 5) — and their hit arm in `.HitPlayerSprite`), `Sources/FerazelCore/Player/HitPlayerSprite.swift`
  (the spike arm, raw `100583c8..10058404`), `Tests/FerazelCoreTests/LevelThreeTests.swift` (new),
  `Tests/FerazelCoreTests/GameFlowGameTests.swift` (l. 249's `1...2` → `1...3`; l. 250's `(3, false, 1)` → `(3, false,
  3), (4, false, 1)`; the "not built" walk at l. 443–453 retargeted from node 3 to node 4 — count unchanged).
- **Contract:** triggers-background §2.6 (spikes: faces 1840/1841 PICT 1840 12 × 24×128, 1841 mirrored; 1842/1843 their
  sheet; initial frame 0 if p4 < p2 else 11; dangerous only in the two most-extended frames; static when p2 = 0);
  enemy-shots-and-damage §3.4 (the hurt: player `+0x116 == 0` → climb 0, `PTR_DAT_100a05f0 = 3`, `HurtPlayer(0x70,
  blood, 60, 0)`, `+0x116 = 30`). The level-3 census (Research note 3): 216 records, 45 types, classes Background,
  Bat, Blob, Bonus, Box, Button, Crawler, Frog, Platform, Rope, Walker. Every record must set up (`SetupFaces` refuses
  none).
- **Tests (4):** `testLevel3SetsUpEveryRecord` (216 records → 216 sprites spawned or queued idle, no
  `notTranscribed`; the level's enemy total includes the four Blobs) · `testStaticSpikeHurts` (L3 rec 160 (1842, p2 0): frame 11 (extended) → touching it hurts 0x70,
  invulnerable 30, the no-cling timer 3) · `testSpikeIdleOnlySound` (a timed 0x732 at `+0x46 == 0xb` with its snd
  playing → no cue, no draw; idle → cue + R(10000)) · `testMapEntersLevel3` (the map at node 3 → level 3 runs; node 4 →
  the not-built report).
- **Gate:** G2 = 477, G6, G7(+b), G8, G10. **Commit:** `Level 3 enterable: every record sets up (spikes, enemy face stubs), BuiltLevels 1...3; 4 tests`.

#### LV4 — minor — level 4 "Eastern Reaches" enterable (→ 481)
- **Files:** `Sources/FerazelCore/Front/BuiltLevels.swift` (`1...4`; the report text "Level n is not built yet
  (Phases 5-6)." — Ruling 2), `Sources/FerazelCore/Sprites/SetupFaces.swift` (whatever the census finds — the Walker
  1760 with p1 1 is already accepted today), `Sources/FerazelRender/Frame/FrameRenderer.swift` (the sheet table, B5),
  `Tests/FerazelCoreTests/LevelFourTests.swift` (new), `Tests/FerazelRenderTests/FaceTests.swift` (one added),
  `Tests/FerazelCoreTests/GameFlowGameTests.swift` (`1...3` → `1...4`; l. 250's tuples → `(4, false, 4), (5, false, 1)`;
  the not-built walk retargeted to node 5 via level 4's exit p1 1; the report text), `Ferazel/App/FerazelController.swift` (the `FerazelLevel` comment's range — the code
  reads `BuiltLevels.range`; G5 confirms).
- **Contract:** the level-4 census (Research note 3): 250 records, 33 types; Buttons/blocks/spouts (BT), teleporters
  (TP), chests/door (BX2), the gold ring 3216 (IU), the upgrade 1340 (PK). Level 5 (Manditraki Warrior) is a boss →
  refused (Phase 6). The hidden `-FerazelLevel N` accepts 1…4.
- **Tests (4):** `testLevel4SetsUpEveryRecord` (250 records, no `notTranscribed`) · `testBuiltLevelsFour` (`1...4`;
  choosing node 5 → "Level 5 is not built yet (Phases 5-6)." and the map again at node 5's neighbour as F1b) ·
  `testStartLevelSwitch` (a flow built with the `startLevel` property 4 — `GameFlow.swift:170`, the test rig's
  `Rig(r, startLevel:)` — → New Game at level 4; 5 → level 1, the clamp in `NewGame.swift:64`; the App's own clamp,
  `FerazelController.swift:176`, unchanged) · Render `testEverySpawnableTypeHasSheet` (every type Phase 4 spawns at run
  time — the drops of every chest/crate on levels 1–4, debris 0xc1b/0xc81, 0x442, 0x4b6, 0x4b7, Effect ids 0/2/5,
  balloons 0xcb2 + key faces, trunks 712/713, the floe 0x57c, shots (ids 0–7, 0x3c, 0x50, 0x5a, followers), the held
  item faces, the Mist body 69, the trail and the double, the dropped glider 0xbea, the container crystals 0x514/0x515,
  the hurt coin 0x516 — resolves to a loaded sheet in a level-1 `FrameRenderer`; B5).
- **Gate:** G2 = 481, G5 (touches the App; wave 4.8 end), G6, G7(+b), G8, G10; wave end: G3. **Commit:** `Level 4 enterable: BuiltLevels 1...4, the not-built report names Phases 5-6, every spawnable face loaded; 4 tests`.

### Wave 4.9 — phase end

#### A4 — minor — Stage + WHAT-TO-EXPECT + the Phase 4 gate card
- **Files:** `Ferazel/WHAT-TO-EXPECT.md` (rewritten for Phase 4), `tools/stage-ferazel.sh` (only if needed), any
  `Ferazel/Core/Sources` file with a leftover `// later: Phase 4` (comment-only relabels).
- **Contract (A8):** the tree had 104 `// later: Phase 4` stubs at plan time. Each task removes the ones it builds; A4
  greps the rest and relabels each with its real owner — no behaviour change. Named owners now:
  `HitPlayerSprite.swift:120` (falling rocks, spiked balls → Phase 6; doors/chest/timer → BX2), `:135` (the geyser head
  → Phase 5), `:356` (a passage's p2 darkness — every passage on levels 1–4 has p2 0 → Phase 6), `:392` / `:418` (the
  EnemyShot Handle in `.HurtPlayer` → Phase 5), `BoxSprite.swift:91` (bridge 1466's surface function, unplaced → Phase
  6), `SetupFaces.swift:265` (Background paths with no Setup, unplaced on 1–4 → Phase 6), `FerazelSession.swift:291`
  (the countdown digits' Handle `.UpdateDigits` — the 2907 timer, level 40 → Phase 6). Gate addition: `grep -rn
  'later: Phase 4' "$WT/Ferazel/Core/Sources"` prints nothing.
- **Gate:** G1 (HK still 35a85ba, floor 361), G2 = 481/0, G3, G5, G7, G9, G10. Then the FABLE-GRADE phase review over
  the phase diff + the card (D34; told: no background agents), its fixes, re-stage. **STOP for Ben** (QUESTIONS item).
- **Commit:** `WHAT-TO-EXPECT: Phase 4 gate card (first levels as the original allows)`.

---

## What Ben checks — the Phase 4 gate card ("first levels as the original allows")

Play `~/Desktop/Ferazel's Wand.app` (New Game, or Resume a Phase 3 save), keypad as before (4/6 walk, 8 up, 5 down,
Shift run, Option jump, **⌘ use**, **keypad 7 / 9 previous / next item**), side by side with the Let's Play
(https://www.youtube.com/watch?v=ESuyxMUEzDw) and longplays. **Levels 1–4 can be entered; enemies stand still and take
no hits until Phase 5; level 5 (the first boss) shows "Level 5 is not built yet (Phases 5-6)."**
1. **The status bar** — the Fireball and the dagger in the inventory strip, the selected one big at the left; 7 / 9
   step the selection (hold: one step, then one every 13 frames); counts above 1 show as "x3" in small Geneva.
2. **Fireball** — ⌘ with the Fireball selected: the wand comes up and the shot leaves on the same frame, arcs, glows,
   costs 8 magic of 560 (the blue bar shrinks); holding ⌘ does not repeat; the wand drops after about half a second.
   With magic gone, ⌘ switches to the dagger. Shots fizzle in water; a shot into a wall puffs.
3. **The dagger** — ⌘ with the dagger: the 10-frame stab (the dagger cannot break crunchable rock — its crunch
   strength is −1, M l. 44233; only the Vorpal Dirk and the Ice Pick crunch, as the original).
4. **Shoot the torches and rock piles** — each torch / candelabra / rock pile gives one crystal (magic if your magic is
   lower than your health, else health) and +150; a spent torch stays dark after a save-point resume.
5. **Xichrons and coins** — the spinning gold Xichrons count in the score; at 100 the counter resets and a red Xichron
   appears in the inventory; coins and money bags add to the coin count. Getting hurt scatters coins that blink and
   vanish after a few seconds unless picked up.
6. **Level 1's key chain** — the chest near the start gives a Steel Key; the locked chest (a thought balloon shows its
   key when you stand near) opens with it and gives a Gold Key; the door (rec 55) opens with the Gold Key when you walk
   into it to the right. Selecting a key and pressing ⌘: Ferazel says you don't need to select keys.
7. **Crates** — shoot or spin-jump them: they burst into debris and drop what they hold; the crate near x 3838 on
   level 1 explodes.
8. **Teleporters** — stand on one until it sparkles: the screen breaks into blocks, you come out at its partner, the
   view re-centres. (One level-1 teleporter, near x 5982, names record 0 — a piece of furniture near x 5455: it sends
   you there, as the original.)
9. **Power-up spheres** — level 1's Invincibility (flashing), level 2's Solid Acid (walk on the acid), level 3's High
   Jump, level 4's Solid Water: each lasts about 20 s (Invincibility 15 s) and ticks a warning in its last 7 s
   (Featherfall, 30 s, is not placed on levels 1–4); a taken sphere hides and comes back later (an Invincibility sphere with no second parameter only
   after about 18 minutes — as written).
10. **Upgrades** — level 2's max-magic crystal (and level 4's max-health): the screen flashes, the bar grows over about
    2 seconds while the game holds, then play resumes.
11. **Potions** — level 1's magic potion (floating) and level 2's health potion: ⌘ with one selected → Ferazel drinks;
    the bar refills at the end of the drink.
12. **Level 2's trigger** — the world flag at the far left edge is set (invisible; proves only in the save file).
13. **Level 3 "Western Reaches"** — the Statue scroll near the start teaches the Statue spell (its new slot flashes; the selection does not move — select it with 7 / 9);
    cast it on a moving platform: it stops, tinted, for 4 s. The Wounded Habnabit's conversation gives the Platinum Key
    for a Health Potion; the door it opens. The button that raises the gate (it latches); mine carts to push; the air
    bubble refills breath; the spikes near the end hurt.
14. **Level 4 "Eastern Reaches"** — the buttons make the switch blocks appear; the gold ring (Ring of Smiting): ⌘ with it
    → the screen flashes and each enemy on or near the screen (up to 16) gets an explosion (they do not die yet —
    Phase 5); the boulder spouts
    stay quiet until Phase 5.
15. **Readings Ben can't see but may feel (MED):** the colourised item / bar flashes, the mosaic's blocks, the
    2-second upgrade at 60 Hz, Geneva drawn by CoreText.
Known stand-ins/deviations: enemies stand still and ignore every attack (Phase 5); the boulder spouts fire nothing
(Phase 5); levels 5+ are not built (Phase 6); the spells, items and the glider first found on later levels (Boomerang,
Ice Wall, Tree Trunk, V Blade, the Ice Pick, the glider, the shields, the Mist potion, the necklace …) are built and
machine-tested but cannot be reached yet.

---

## Execution order

The canonical order is the execution order (each task starts from the previous task's merge):

| wave | tasks, in order | review legs (all Opus) | run (2 tasks, 3 when ≤ 1 ⚑) |
|---|---|---|---|
| 4.0 | X1 → VS → LT ⚑ | X1, VS one; LT two | run 1: [X1 VS LT] |
| 4.1 | US ⚑ → IV → HU | US two; IV, HU one | run 2: [US IV HU] |
| 4.2 | BN ⚑◈ → PK ⚑◈ | two each | run 3: [BN PK] |
| 4.3 | EF ⚑ → CS ⚑ | two each | run 4: [EF CS] |
| 4.4 | SH ⚑ → GL → PU | SH two; GL, PU one | run 5: [SH GL PU] |
| 4.5 | IU ⚑ → MS | IU two; MS one | run 6: [IU MS] |
| 4.6 | SD ⚑ → BX1 ⚑◈ | two each | run 7: [SD BX1] |
| 4.7 | BX2 ◈ → BT → TP ⚑ | BX2, BT one; TP two | run 8: [BX2 BT TP] |
| 4.8 | SW → LV3 ⚑ → LV4 | SW, LV4 one; LV3 two | run 9: [SW LV3 LV4] |
| 4.9 | A4 (+ FABLE-GRADE phase review + fixes) | one + Fable | run 10: phase end |

G3 runs at each **wave** end. No HectorKit task: G1 = HK `35a85ba` untouched for the whole phase.

- **Dependencies:** US after LT (light removal); HU after IV; BN after US + LT; PK after BN + HU + IV; EF after LT + US;
  CS after IV + LT + US (+ EF for the liquid rule's effect 5); SH after CS + EF + BN; SW after SH + **BX1** (the trunk landing 713 → 712 needs the Box tail and the
  `.HitBoxTileSprite` dispatch — fix round B7; SW runs in wave 4.8); GL after PK; IU after
  CS + SH (+ HU); MS after IU + PK; PU after PK; BX1 after US + SH + EF + PK; BX2 after BX1 + EF; BT after BX1 + VS; TP
  after BX1; SD after PU + CS + SH; LV3 after BT + BX1 (mine carts, the gate) + TP (level 3's teleporters 63 ↔ 64) + VS; LV4 after LV3 + BT + TP + BX2; A4
  after all.
- **File overlaps that force order:** `FerazelSession.swift` (VS, LT, US, HU, BN, PK, EF, CS, SH, IU, TP),
  `SpriteSlot.swift` (US, BN, CS, SW, IU, BT, SD, PU), `HitPlayerSprite.swift` (PK, EF, BX1, BX2, MS, TP, LV3),
  `HandleKeys.swift` (CS, GL, IU), `Player.swift` (IV, CS, GL, IU, MS, PU, SD), `PlayerStates.swift` (CS, GL, IU, MS, TP,
  SD), `BoxSprite.swift` (X1, SH, SW, BX1, BX2, BT), `BonusSprite.swift` (BN, PK, SH), `SetupFaces.swift` (LT, BN, CS?,
  BX1, BT, LV3, LV4), `LevelRun.swift` (VS, HU, PK, IU, TP), `FrameSuspension.swift` (PK, IU, TP), `DrawOp.swift` (LT,
  EF, TP), `FrameRenderer.swift` (LT, HU, EF, CS, TP), `StatusBar.swift` (HU), `GameFlowGameTests.swift` (LV3, LV4),
  `FerazelController.swift` (VS, LV4), `FerazelAudio.swift` (VS), `BackgroundSprite.swift` (X1, US, BN, CS, PU, SW, BT,
  LV3), `SpriteWorld.swift` (US, BN, CS, SH, IU), `SessionTests.swift` (LT, EF, TP), `PauseKeysTests.swift` (CS, IU),
  `FrameGoldenTests.swift` / `Phase2GoldenTests.swift` (PK, IU, TP).
- A task merged out of order rebases; the orchestrator adjusts the ladder by N.

---

## Stand-ins kept (◇, named) and the phase that replaces them

| ◇ | where | replaced by |
|---|---|---|
| Enemies are the Phase-1 Setup-face stub (drawn, no Handle, no Hit) on levels 1–4 — shots, the stab, Statue, Smiting's blasts and the 1207 explosion pass through or do nothing to them | SetupFaces (Phase 1), LV3 (1730, 1741) | Phase 5 |
| The boulder spouts 1450…1453 spawn no enemy shot (timer and own draws as read) | BT | Phase 5 (EnemyShot 0x6e1/0x6e2) |
| `.ShieldBlock` (a raised shield reflects / destroys enemy shots), the Pentashield's enemy-shot kills, the 0x77b metal-hit arm | IU, SD, SH (built as read where they sit; no enemy shot exists) | Phase 5 |
| Enemy drops (design §9 (c): items 8/21 from enemies' Kill routines) | — | Phase 5 |
| `BuiltLevels = 1...4` + the not-built report "(Phases 5-6)" | LV4 | Phase 6 (levels 5+; Phase 5's plan may widen if it rules so) |
| Box/Background types first placed on levels ≥ 5: magic carpet 1080/1081 (L22), snowball 3070, spiked balls 1475/1476, falling rocks 1075/1076 (bosses), enemy pipes 1490…1493 (L21), geysers 1440…1449 (§9 (b)), the 2907 timer + gate p1 −2 (L40), gate p1 −1 (bosses), cannons with p1 ≠ 0 and their idle-only sound M l. 62997 (L10+), bridge 1466's surface function (unplaced), 2929 table parts | `SetupFaces` refuses them | Phase 5 (pipes, geysers) / Phase 6 (the rest) |
| `.Victory` after the loop | F1b (Phase 3) | Phase 6 |
| `FerazelLevel` hidden switch = New Game at level N ∈ 1...4 | LV4 | kept (D35); widens with `BuiltLevels` |

## Carries owned (Phase 2 D33 / Phase 3 D35 / STATE)

| carry | owner |
|---|---|
| HUD shows `StatusBar.startInventory` (Phase 3 ◇, C1) | HU |
| USE-item hint `.SimpleConv`s (Phase 3 ◇) | IU |
| Escape Ring built as read, unreachable (Phase 3 ◇, L1) | IU |
| 1058 world-flag trigger never set (Phase 3 ◇, SV1) | PK |
| `BuiltLevels` widening (Phase 3 ◇, F1b) | LV3, LV4 |
| M6 (Bonus guard `p1Negative: false`, D33) | BN |
| M7 (`TileHotRects.init(level:)`, D33) | X1 |
| lost coins drawing when `.MTNewSprite` finds no record (D33) | PK |
| 3DSoundRand idle-only sites: M l. 61047–61057 (gate 2940) / 63199–63257 (spikes 0x732/0x733) / 62997 (cannons p1 ≠ 0) | BT / LV3 / → Phase 6 (no placement before level 10) — the mechanism is VS |
| stale "later: W1/W3/W4/P2" comments (STATE follow-ups) | X1 |
| `ParticleLife` vs CLUT 222 rows (levels 52/55) | stays carried → the phase that loads 52/55 |
| the other STATE follow-ups (report fade-in when faded, a second queued menu pick, boot bar jumps, music decoded on play, `.savePoint(saved:)` polled input, `writeErrorReport` optional, `CoreTextRasterizer` widths untested, `fail()` NSLog only, the save panel's label) | **not adopted** — Phase 3 front-end polish, left to Ben's Q6 verdict (Ruling 15); HU touches `CoreTextRasterizer` only for font 3 |

## Known deviations (forced by the platform; recorded in D38)

1. **Fonts:** Geneva 9 plain / 8 bold for the item counts come from CoreText (`CoreTextRasterizer`; the game ships no
   bitmap fonts) — as Times in Phase 3.
2. **The voice query** reads the shell's playing set at the start of the iteration plus the iteration's own cues and
   stops; a sound that ends inside the iteration counts as playing until the next tick (the original's Sound Tool
   interrupt could free it mid-frame) [MED].
3. **Colourised `CopyBits`** (the item flash, the bar flashes) are computed by the replica's reading of QuickDraw's
   colourise for an indexed copy [MED].
4. **Tick:** the 120-tick upgrade, the 57-tick mosaics, the potion and wand counts run at 60 Hz ticks / the 30 Hz step
   as Phase 3 (D30).
5. Never-initialised bytes stay 0 (Phase 3 Invariant 7) — e.g. a learned spell's count is the empty slot's 0.

---

## Pre-execution self-audit

1. **Design §8 row 4 coverage.** casting (CS) ✅; the spells and player shots (CS, SH, SW, SD's orbs, IU's seeds/stab)
   ✅; items / inventory / HUD (IV, HU, IU, MS) ✅; pickups (BN, PK, PU) ✅; boxes — crates (BX1), chests (BX2), doors (BX2),
   keys (BX2, IV), switches (BT), teleporters (TP) ✅; held weapon (IU) ✅; design §9 (c) (Ruling 9) ✅; "first levels as the
   original allows" → LV3, LV4 + the card's 14 steps ✅.
2. **Numbers sourced.** Every number cites an M line / raw address / bank § with raw; self-derived numbers are named
   ("recorded": the explosion package's 135-draw order, the spent torch's draw count, the deploy vy, the mosaic block
   choice, the TickTock marks) and re-derived by the reviewer. Function spans re-read in the committed dump: `.InitGameGlobals`
   582, `.UpdateHealthMagic` 4361, `.UpdateTextStats` 4594, `.UpdateItemStat` 4674, `.UpdateStatusBar` 4842, `.UpdateSprites`
   4934, `.FindUpperLeftCorner` 5882, `.PaintFrameWrap` 9104, `.MosaicScreenBlit` 12854, `.MosaicTransition` 12944, lights
   14275–14556, `.TurnIntoStatue` 38244, `.RemoveItem` 39602, `.MoveSelectedItemToFront` 39664, `.HaveItem` 39710,
   `.SetupHeldItemSprite` 43406, `.SetHeldItemPos` 43460, `.HasItem` 43534, `.TickTock` 43583, `.UpdatePentSprites` 44127,
   `.HandleItemUse` 44197, `.DoubleSpeedTrail` 44302, `.HandlePlayerSprite` 44396, `.CastSpell` 46653, `.SmiteEnemies`
   46981, `.HandleKeys` 47047, `.HurtPlayer` 47955, `.ShieldBlock` 48359, `.HitPlayerSprite` 48445, player shots
   50226–51392, Bonus 52261–53638, Effects 53639–54286, `.HandleStatueSprite` 56521, Box 58697–61683, Buttons 61684–61845.
3. **Names checked against the code.** `FerazelSession.step(keys:capsLock:)`, `FrontInput` (FrontIO.swift),
   `SpriteHandler` cases (SpriteSlot.swift:359ff), `SpriteSlot.dead`, `SpriteWorld.updateSprites` (l. 168), `BonusHandle`,
   `SetupFaces.Error.notTranscribed`, `StatusBar.startInventory`, `StatusBarState` (7 fields), `GameGlobals.statusBar(levelName:)`
   (GameGlobals.swift:280), `InventorySlot`, `ConvActions.removeItem`, `FrameSuspension` (4 cases), `DrawOp` (23 cases),
   `MapRenderer.swift:143`, `ScreenRenderer.swift:115`, `FrameRenderer.addLights`, `LightRenderer`/`LightSlot`,
   `SoundTool.isPlaying(snd:)` (SoundTool.swift:214), `RopeSprite.types` 0xbcc…0xbce, `PlatformSprite` mode 4,
   `BuiltLevels.range`/`notBuiltReport`, `GameFlowGameTests.swift:249/453`, `FerazelController.swift:173–176`,
   `TileHotRects.init(level:)` (no production caller; `SeparateFromTiles.swift:80`), the stale-comment lines of X1.
4. **Ladder arithmetic (fix round A+B).** Canonical order X1, VS, LT, US, IV, HU, BN, PK, EF, CS, SH, GL, PU, IU, MS, SD,
   BX1, BX2, BT, TP, SW, LV3, LV4: 349 + (0 + 3 + 5 + 5 + 6 + 6 + 8 + 8 + 7 + 9 + 8 + 5 + 6 + 8 + 5 + 5 + 8 + 6 + 6 + 4 +
   6 + 4 + 4 = 132) = **481** ✅; cumulative 349, 352, 357, 362, 368, 374, 382, 390, 397, 406, 414, 419, 425, 433, 438, 443,
   451, 457, 463, 467, 473, 477, 481 ✅ (each task's "Tests (N)" equals the names it lists — re-counted by script). Wave
   ends 357, 374, 390, 406, 425, 438, 451, 467, 481 ✅. ⚑ MAJOR: LT, US, BN, PK, EF, CS, SH, IU, SD, BX1, TP, LV3 = **12**;
   every run is 2 tasks, or 3 with at most one ⚑ (Fable round, seat ruling).
5. **Layering.** Core gains no AppKit/CoreGraphics; `LightTable` holds face *references* (pict, width, height), not
   pixels; the mosaic and the mask copy are Render's; the App adds two lines of plumbing. No HectorKit change.
6. **Risk.** Biggest: the resumable player Handle (IU) — the frame must continue at `.HandleKeys`' item switch with
   identical state; `testHintSuspendsInsidePlayerHandle` pins it. Second: the light table move (LT) — every golden must
   hold; a Render test pins slot equality. Third: the ◈ tasks (BN, PK, BX1, BX2) — the cause of each moved golden must
   be shown, not assumed. Fourth: `.UpdateSprites` (US) — the four-pass kill changes list membership; dead sprites must
   stay invisible.

---

## Open questions for Ben (non-blocking; execution does not wait — D34)

1. **Levels 3 and 4 open now with the enemies standing still** (and the boulder spouts silent) — fine as Phase 4's
   gate, or would you rather they stay closed until Phase 5? Default: open (Ruling 2).
2. **Spells and items first found on later levels** (Boomerang, Ice Wall, Tree Trunk, V Blade, the glider, the Ice
   Pick, the shields, the Mist potion, the necklace) are built and machine-tested now but you cannot reach them before
   Phase 6 opens their levels — fine? Default: yes (Ruling 11).
3. **Item counts in Geneva drawn by the Mac's CoreText** (Known deviation 1) — fine? Default: yes.

---

## Bank corrections to append (each as a ⚑ planner note in the named file, by the task named)

BC35 `pickups-boxes.md` §1.3 rows 1340/1341 (and `spells-items.md` §3) — the upgrade blocks the game for **120 ticks**,
not "~0.5 s": `GammaFadeOutAsync(2, rgb, 0xc, 0x10)`; 5 × (2-tick wait, async step); `GammaFadeInAsync(0x28)`; 10 ×
(step, 1 tick); flash 11 × (−1, bar, step, 2 ticks); the refill; 14 × (max + 8, …, 2 ticks); 14 × (value + 8, …, 2
ticks); flash 11 × (…, 2 ticks) (M l. 48810–48905) (PK).
BC36 `spells-detail.md` §3.7 and `pickups-boxes.md` §3.2 — the seed explosion's `_DAT_1009ffa0 = 0x14` is the camera
shake counter (`.FindUpperLeftCorner` M l. 6147–6162: v ∓ shake >> 1 alternating, shake − 1) and `_DAT_100a00fc = 3`
is the **mask-port flash** (`.PaintFrameWrap` M l. 9437–9447 copies `_DAT_100a0008` on alternate frames), not "screen
shake 3 px × 20 frames [LOW]"; the same flash is set by the Ring of Smiting (M l. 47593) and the rain's lightning (M l.
8458) (SH; EF).
BC37 `spells-items.md` §1 — `.RemoveItem` adjusts the selection only when the removed slot **is** the selected one
(−1, ≥ 0); the vacated slot 26 gets id −1, count 0, +4 −1, +6 0 and keeps its +8 byte; `.UpdateItemStat` only when
found (M l. 39602–39663) (IV).
BC38 `spells-detail.md` §2.3 — in every `.CastSpell` case the `snd 300` `STPlay3DSoundRand` is the **first** call,
before `MTNewSprite` (M l. 46727 for case 0), so its R(10000) precedes the shot Setup's R(5) and the case's speed draw;
the common R(0x4b) jitter follows for the first shot of every id, the upper V Blade included (CS).
BC39 `spells-items.md` §6 — `.UpdateStatusBar` steps the selection on **every** call (keys 8 / 7, the 12-frame repeat
`*_DAT_1009fd9c`), the mid-frame (1,1,0) / (1,0,1) calls and the world map's four calls included (M l. 4885–4912; 67505,
67539, 67579, 67585); the item flash colourises the slot's small icon with `RGBForeColor(s·0x5dc, s·0x5dc, s·0x5dc)`
(mode 0) or `(s·3000, 0, 0)` (mode 1), s = flash − 1; counts: the big icon's in Geneva **plain 9** ("x" at 0xf5 / 0xf2,
the number at 0xfb / 0xf8, v 0x3e), the strip's in Geneva **bold 8** ("x" at left + 0xe / + 9, the number at left + 0x12
/ + 0xc, v = the box bottom) (M l. 4674–4841) (HU).
BC40 `pickups-boxes.md` §2.4.7 — the teleport: snd 421, `.MosaicTransition(1, 3, 0x14)` (20 blits, 3-tick waits, 57
ticks), `068c = 0`, the move to every in-use idle-table entry whose record index is the teleporter's p1 (active
partners included — BC50), 120 `.FindUpperLeftCorner` with the ease flag cleared, `.HandleIdleSprites`,
`.WrapDrawSprites`, snd 420, the in-mosaic, `.RedrawEntireScrollGrid`, `0708 = 0`, charge −59 (M l. 49407–49470) (TP).
BC41 `pickups-boxes.md` §3.1 — `.SetHeldItemPos`: |c| 0 takes (0x54, 0x11); the `100 − off` mirror follows
`PTR_DAT_100a04f4` (the facing at the press), the −0x20 the player's current `+0x17e` (M l. 43460–43533) (IU).
BC42 `triggers-background.md` §1 — a Button's record p4 is written by its Handle, which runs before the press in the
frame: a stood-on momentary 1322 writes p4 = 1 on the **third** contact frame (the bank's "≥ 9 on the second contact
frame" is the level, not the output) (BT).
BC43 `spells-items.md` §4 row 0x10 — `.SmiteEnemies` spawns at the target's centre − (4, 4) with `+0xf0 = 0` and `+0xa6
= 0`, for the first 16 listed sprites whose Handle is one of the **15** enemy Handles at TOC 0x100a048c…0x100a04c4 (M l.
46981–47046) (IU).
BC44 `pickups-boxes.md` §2.2 rows 1450…1453 — the two velocity draws are made only when `MTNewSprite` succeeded, then
`+0xa6 = R(30) + 50`; with neither Button pressed the timer stays 0 and re-tests every frame (M l. 60488–60547) (BT).
BC45 `spells-items.md` §4 rows 4/5/0x19 — the drink at frame 20: health → snds 502 + 415 and the health flash
`PTR_DAT_1009fdbc = 0xb`; magic → 500 + 415 and `_DAT_1009fdb8 = 0xb`; mist → 415 only; all `PTR_DAT_100a05a8 = 6`;
frame 40 → the Mist's spirit trigger; > 40 → counter 0 (M l. 45176–45218) (IU).
BC46 `pickups-boxes.md` §1.9 (+ its Phase 2 phase-end correction) — a lost coin for which `.MTNewSprite` finds no free
record runs no Setup: **five** draws (R(8), R(8), R(0x640), R(100), R(0xdac)), not nine (PK).


*Added by the review fix round (Opus legs A + B, 2026-10-24):*

BC47 `spells-items.md` §5 — `.TickTock` warns at **14** marks every 15 frames from 210 down: snd 428 at 210, 180 … 30
and snd 429 at 195, 165 … 15, the blink flag toggled at each; the pitched 428 at 0 (M l. 43583–43663) (PU).
BC48 `pickups-boxes.md` §1.7 — the scroll's slot search compares the **unmapped** spell id (2) before the 2 → 3 remap, so a
second 2-scroll takes a new empty slot rather than the Ice Wall slot (M l. ~48946) (PK).
BC49 `pickups-boxes.md` §1.1 — `.HitBonusSprite`'s `.PlatformBounce` last argument is 1 when f = 0x80 and 0 when f = 0
(raw `1005ffb8..1005ffd0`), the opposite of "f == 0" (BN).
BC50 `pickups-boxes.md` §2.4.7 (supersedes BC40's partner sentence) — the teleporter's search tests only the idle-table
entry's in-use byte (M l. 48564, 49416), so an active partner still matches; level 1 record 126 (p1 0) sends the player
to record 0, a type-2922 furniture piece at (5455, 666) (TP).

*Added by the LT review fix round (loop run 19, 2026-10-25):*

BC (LT, loop run 19) `lighting-tables.md` §7.4 — `.AddLight` with a nil face and a free slot stores nothing but
returns that slot's index (raw `1001bc58..1001bd08`: both the store and the `ReportError` path end at `1001bd08
or r3,r31,r31`); −1 only when all 200 slots are in use (LT).

---

## Research notes (where every number came from)

No digest files: the planner (Opus 5.5, 2026-10-24) read the bank files named per task, re-read every cited dump span
in the committed `Ferazel_pef.decompiled.c`, decoded the pstrs with `pef.py`, and ran two throwaway census scripts
(not committed) over `Resources/Ferazel/Ferazel's Wand World Data.rsrc` with the bank's `rsrc_census.parse` and
`gensprite_map.gen`:
1. **Level types (active records):** L1 162 records / 42 types; L2 212 / 40; L3 216 / 45; L4 250 / 33. New on L3 (vs
   L1 ∪ L2): Background 1841, 1842 (spikes); Bat 1741 (p 2, 340, 800); Blob 1730 ×4; Bonus 1334, 1350, 2000 (p1 1);
   Box 2812, 2813, 2820, 2821, 2832, 2843, 2868, 2869, 2884, 2930 ×2, 2940 (p1 90); Button 1322 (rec 90, p1 1); Platform
   1420 ×2, 1425 ×2 (0x591, a see-saw arm); Rope 3022 ×4. New on L4: Bonus 1331, 1340, 3216; Box 1250 ×9, 1450 ×3, 1453
   ×2; Button 1320, 1322 ×3; Platform 1410; Walker 1760 p1 1 ×1.
2. **The map graph (Mmap 200) and exits (type 3249 p1, p2):** 1 → [2] exits (0,0); 2 → [1, 3, 4] (−1,0) (1,0) (2,0);
   3 → [2] (−1,0) ×2; 4 → [2, 5] (−1,0) (1,0); 5 Manditraki Warrior (boss face) → [4, 10]. So levels 1–4 are the
   chapter before the first boss; 10+ only through 5.
3. **Mechanism records on levels 1–4:** L1 chests 23 (0, 3201, 1), 38 (1, 3202, 1), 43 (0, 1305, 6), 51 (0, 1305, 4),
   72 (0, 1302, 20); door 55 (2910, p1 2); crates 31 (0, 3219, 1), 32 (0, 1291, 3), 65 (0, 1293, 0), 130 (3092, p1 2);
   teleporters 126 (p1 0), 148 ↔ 149; save points 24, 70; 1335 rec 2; 3204 rec 68 (p1 1); cannons 41, 150, 156 (p1 0).
   L2 chests 11, 16, 51 (3202), 52 (3201), 80, 90, 92, 184; doors 97 (2910 p1 2), 212 (2911 p1 1); teleporters 13 ↔ 75,
   85 → 75, 209 → 13; stalactites 158–160; boulder 21; 1058 rec 228 (p1 1, x −7); 1332 rec 206; 1335 rec 147 (p1 1);
   1341 rec 187; 3205 rec 78. L3 door 68 (2911 p1 3); gate 72 (p1 90) ← Button 90; mine carts 25, 67; boulder 28;
   teleporters 63 ↔ 64; scroll 146 (p1 1); 1334 rec 129; 1335 rec 97; 1350 rec 142; spikes 160 (1842), 217 (1841), p 0.
   L4 blocks 53, 58–61 (p2 57), 62, 64–66 (p2 63); Buttons 30, 31, 57 (1322 p1 1), 63 (1320 p1 1); spouts 28 (p1 30, p2 31,
   p4 1), 67, 70 (p1 63), 68 (1453 p1 57), 183 (all 0); door 56 (p1 1); chests 55 (3201), 112, 179; teleporters 41 ↔ 42,
   69, 72, 73 → 42; 1331 rec 39; 1334 rec 74; 1340 rec 32; 3216 rec 161. Cannons with p1 ≠ 0 first on level 10.
4. **Sound ids:** pickups-boxes-2 §1.2 (the 144-handle map) — e.g. 300 `a0424`, 301 `a0420`, 302 `a01fc`, 415 `a03f4`,
   418 `a03e8`, 420 `a03e0`, 421 `a03dc`, 428 `a03c8`, 429 `a03c4`, 435 `9fdec`, 437–439 `a03a8`/`a03a4`/`a03a0`, 451
   `a037c`, 456 `a0370`, 492 `a02fc`, 500–503 `a02d8`/`a02d4`/`a02d0`/`a02cc`, 506 `a02c0`, 704 `a0268`.
5. **Hint texts:** pstrs 0x100a60a0 "Ferazel" (7), 0x100a616f (112), 0x100a60e7 (135), 0x100a60a8 (62); "x" 0x100a1531.
6. **How Phases 1–3 treat untranscribed classes:** `SetupFaces.spawnLevelSprites` (`SetupFaces.swift:601ff`) throws
   `notTranscribed` for any record whose type has no arm, so a level with one such record cannot load — which is why `BuiltLevels`
   widens only with a level's every-record census test (LV3, LV4). The enemies on levels 1–2 (Walker 1700/1705/1760,
   Crawler 1712, Roach 1720, Frog 1800, Bat 1740) have Setup-face arms only — drawn, `.inert`, no Handle, no Hit.

---

## Rulings (→ DECISIONS D38, copied by the orchestrator)

1. **Scope:** design §8 row 4 + §9 (c): every spell, player shot, item use, Bonus type and power-up, the glider, the HUD
   from G, the Box mechanisms on levels 1–4 and the design row's set, the Effect ids they spawn. Out: enemy
   Handles/Hits/Kills and enemy shots (Phase 5), geysers (Phase 5), bosses + `.Victory` (Phase 6), Box/Background types
   first placed on levels ≥ 5 (the phase that widens past 4), the debug kit.
2. **`BuiltLevels` → 1...3 (LV3), 1...4 (LV4); level 5 stays refused.** "First levels as the original allows" = the
   four levels before the first boss: everything on them but the enemies works in Phase 4; level 5 is a boss (Phase 6)
   and 10+ are reached only through it. The report text becomes "Level n is not built yet (Phases 5-6)."
3. **Enemies on levels 3–4 get the Phase-1 Setup-face stub** (as on 1–2): drawn, inert, no hit callback — so shots,
   the stab, Statue, Smiting and the big explosion do nothing to them until Phase 5; `.SmiteEnemies` still finds them
   by their class (the 15 enemy Handles resolved to `SpriteClass`).
4. **The light table moves into Core** (`LightTable`, single source of truth); the renderer receives it per frame
   (`DrawOp.lightTable`) and its slot step calls Core's `handleLights()`.
5. **Idle-only sound calls** (`if (!FUN_100916dc(snd))`) are decided in Core by `SoundVoices` from the shell's playing
   set plus the iteration's own cues and stops; the RNG draw follows the decision. Owned: the gate (BT), the spikes
   (LV3); the cannon site M l. 62997 → Phase 6. Phase 3's `onlyIfIdle` cues stay shell-decided (no draw behind them).
6. **Three new modal moments run inside the frame** (Phase 3 Ruling 4 extended): the upgrade animation and the teleport
   in the special pass, the USE hints inside the player's Handle (a resumable player Handle).
7. **`.UpdateSprites` in full** (the four-pass kill, the record write-back, the keep-record flags): saves now persist
   collected pickups, opened doors and chests, spent torches and pressed latches as the original.
8. **The boulder spouts' boulders are a ◇ until Phase 5** (EnemyShot); their timers and own velocity draws run as read.
9. **Design §9 (c):** follower slot reuse is copied (the next-fit allocator and the orphan rules of spells-detail-2 §5,
   no special handling); enemy drops of items 8/21 belong to the enemies' Kill routines (Phase 5); chests, crates and
   containers on all levels drop neither (pickups-boxes §1.8–§1.9).
10. **No HectorKit change:** fonts through CoreText, the mosaic and the mask flash in Render, the playing set from the
    Render `SoundTool`. HK stays 35a85ba, floor 361, no HK D-number, no other app rebuilt.
11. **Build the unreachable player systems now** (spells 2–7, items, the glider, the Mist potion, the necklace …): they
    are the player's, no later phase owns them, and they are pinned by tests on synthetic placements.
12. **Box/Background types first placed on levels ≥ 5** are transcribed by the phase that widens `BuiltLevels` past 4,
    except arms inside routines Phase 4 transcribes whole (`.HitPlayerShotSprite`'s 2941 test, `.KillCrate`'s p1 = 2),
    which are built where they sit.
13. **The status bar's call parameters come from Core** (`StatusBarCall`), replacing the renderer's "full after a
    `setScreenClut`" rule; the HUD shows G's inventory and maxima.
14. **The Effect class gains every id Phase 4 spawns** (0…15, 0x442, 0x4b6, 0x4b7, 0xc1b, 0xc81, the balloons) with the
    explosion package; the 1207 explosion hurts the player (its enemy damage is Phase 5's).
15. **Carried follow-ups:** adopted — the stale later-stubs and M7 (X1); not adopted — the Phase 3 front-end polish
    items (left to Ben's Q6 verdict).
16. **No free record:** a spawn that finds all 700 records in use runs no Setup and makes none of its draws; the
    caller's stores to it are dropped and its own later draws still made (BC46's rule, for every spawner).

---

## Review ledger

- **Opus leg A — plan vs dump + bank: SOUND WITH FIXES.** A1 cast press also sets `075c` and calls
  `.MoveSelectedItemToFront` (M l. 47339–47350) → CS contract + `testCastPressMovesSpellToFront` (**fixed**; the `075c`
  write is cleared again in the same call — spells-detail-2 §1 — stated). A2 magic < 1 → dagger to the front and the same
  frame's stab (snd 418) → asserted in `testMagicBelowOneSelectsDagger` (**fixed**). A3 TickTock: 14 marks from 210,
  428 on multiples of 30, 429 on 195…15 — verified M l. 43583–43663 → PU, card "7 s", BC47 (**fixed**). A4 scroll search
  compares the unmapped id → PK test + BC48 (**fixed**, M l. ~48946 per the leg). A5 `.PlatformBounce` last argument 1
  when f = 0x80 — verified the expression → BN + BC49 (**fixed**). A6 the dagger cannot crunch (`+0x158 = −1`, M l.
  44233 verified) → card step 3 (**fixed**). A7 the cannon capture's Phase 4 stubs (`BackgroundSprite.swift:400–564`) →
  owned by SW (Statue excluded), BN (`+0x168 == 1`), CS (the captured shot's light), PU (`.DoubleSpeedTrail`)
  (**fixed**). A8 104 `// later: Phase 4` stubs → each task removes its own, A4 relabels the rest with the named owners
  and greps it empty (**fixed**; the passage p2 darkness checked: every passage on levels 1–4 has p2 0 → Phase 6). A9
  Blob counts itself as an enemy → LV3's totals arm (**fixed**). A10 the fourth Xichron sound 501 vol 0x100 → PK
  (**fixed**).
- **Opus leg B — plan vs the code that exists: SOUND WITH FIXES.** B1 (CRITICAL) the teleporter search tests only the
  in-use byte (M l. 48564, 49416 verified; `IdleSprites.activeID` keeps the entry; level 1 record 0 = type 2922 at
  (5455, 666) verified by census) → TP rewritten, `testActivePartnerNoMove` dropped, `testTeleporterToRecordZero` added,
  BC40 corrected + BC50, card step 8 (**fixed**; TP 5 → 4 tests). B2 two stages (out-mosaic before the move, in-mosaic
  after snd 420, then the redraw / `0708` / the frame) → `.teleport(record:stage:)` (**fixed**). B3 the resumable player
  Handle had no seam → IU names `FerazelSession.swift:447–471`, `SpriteWorld.handleSprites` and the nested-pass case
  (**fixed**). B4 missing files (FerazelSession switch for SW/SD/PU, ScreenRenderer + SessionTests for EF, SessionTests for
  TP, `FerazelAudio.swift` for VS) (**fixed**). B5 run-time faces → the Tasks-preamble rule + LV4's
  `testEverySpawnableTypeHasSheet` (**fixed**; LV4 3 → 4 tests). B6 = A1. B7 SW needs BX1 → SW moved to wave 4.7 after
  BX1 (**fixed**; waves re-cut: 4.4 [SH GL PU], 4.5 [IU MS], 4.6 [SD BX1], 4.7 [SW BX2 BT], 4.8 [TP LV3 LV4]; LV3 demoted
  to minor so 4.8 holds one ⚑). B8 = A3. B9 level-3 decorations refused (sheets outside the table) → LV3; "Walker 1760"
  already accepted → LV4 text (**fixed**). B10 card: no selection jump on a new spell, 13-frame repeat, Featherfall not
  placed on 1–4 (**fixed**).
- **Minor findings (both legs), all fixed:** EF shake second step +9; PK first status-bar op at tick 20; CS a press at
  step 3 casts the same frame; KillCrate's Bat 0x6cc arm (M l. 61312–61320); KillPlayerShot's `.StandardSpriteCleanup`
  first and the stale-register recolour ruled "follow the binary — trace the raw, record"; `068c = 0` in the teleport
  (verified M l. 49341/49410); the mosaic's mode-3 flag always false; the gate sound's y ≠ `+0xc4` precondition; the chest
  drop's layer change re-sorts; MS body return `0578 = −1`, `0574 = 0xe`, `05a8 = 6`; power = count while the loss timer
  runs; the lower V Blade never flipped and the double's copies typed 0x601; "13 calls" on the card; coin blink from −44;
  SH's Crawler arm cannot match the inert stand-in; the 2941 death arm → BX1; `.HitBonusSprite`'s 0x4bf return; the
  SoundTool cite is l. 214 everywhere; HU: Geneva already font 3 (no App change), the repeat counter owned by HU, the
  nested status-bar sites named; VS: which playing set a resumed / nested pass uses; LV4: `startLevel` is a property, the
  5 → 1 clamp is `NewGame.swift:64` (and the App's); LV3 changes `GameFlowGameTests` l. 250; `PauseKeysTests` (CS, IU)
  and the golden drivers (PK, IU, TP) listed.
- **Rejected / kept differently:** none rejected. (LV3 was demoted to minor in this round — 11 ⚑; the Fable round
  restored it — 12 ⚑, below.)
- **Fix round result:** ladder 349 → **481** (CS +1, TP −1, LV4 +1); waves 10 (4.0–4.9).
- **FABLE-GRADE plan leg: PASS WITH FIXES** (G2 349/0 re-run in an archive copy; ~25 independent dump samples agree; no
  scope dropped). Findings and dispositions (all verified against the dump, all fixed): (1, IMPORTANT) CS's
  `testMagicBelowOneSelectsDagger` asserted the same-frame stab and the `075c` clear, both IU's (the item switch, wave
  4.5) → CS keeps the selection + the two (1,1,0) calls; IU's `testDaggerStab` gains the stab and the clear. (2) the
  scroll arm also stores `_DAT_1009fda0 = 0` and returns silently with no free slot (M l. 48956–48962 verified) → PK.
  (3) the stale register is `unaff_r29`, the caller's r29 (M l. 51090, 51190–51195 verified) → traced per call site
  of `.KillPlayerShot` → SH. (4) unguarded `MTNewSprite` results in `.CastSpell`, `.SmiteEnemies`, `.KillCrate` → one
  ruling for every spawner (Ruling 16, Hazards). (5) the Geneva claim reconciled: no App change (l. 56, S5). (6) the
  1322 release starts at 9 (p4 still 1) → BT test. (7) the 0x4bf return is M l. 53468 (verified) → BN. (8) the nested
  hint case does arise — `.HandleSprites` runs inside `.PaintFrameWrap` (M l. 9453 verified) → IU specifies the nested
  suspension and its resume. (9) seat ruling on the leg's judgement note: LV3 back to ⚑ MAJOR; waves re-cut so every run
  is 2 tasks or 3 with at most one ⚑: 4.7 [BX2 BT TP], 4.8 [SW LV3 LV4]; ⚑ MAJOR = 12. Rejected: none.
- **Final:** ladder 349 → **481**; runs 4.0 [X1 VS LT] 357 · 4.1 [US IV HU] 374 · 4.2 [BN PK] 390 · 4.3 [EF CS] 406 ·
  4.4 [SH GL PU] 425 · 4.5 [IU MS] 438 · 4.6 [SD BX1] 451 · 4.7 [BX2 BT TP] 467 · 4.8 [SW LV3 LV4] 481 · 4.9 [A4] 481.
