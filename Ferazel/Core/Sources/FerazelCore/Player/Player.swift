import Foundation

/// The player sprite (plan S2, P1a): `.SetupPlayerSprite @ 1004aefc` (`spawn`) and `.HandlePlayerSprite @ 1004d5fc`
/// (`handle`, decompile l. 44396–46650) as 42 rows in the binary's order. Rows that belong to later tasks are named
/// no-ops (`// later: <task>`, plan Invariant 6) — their flags stay 0 because their writers do not exist yet.
///
/// The row list (derived from the dump and player-states §1; the planner's digest A §1.2 was not available — the
/// plan's row numbers map as: plan row 13 = row 19, 22 = 27, 35 = 40 (the end pass), 36 = 40 (the draw offsets);
/// plan P1a "⚑ As executed"):
///  1 entry: ridden copy, last facing, turn flag          22 quicksand vy × 0.65
///  2 looped ambient sound (later: S1)                     23 gravity add, terminal 12000, vy 0 → 1
///  3 riding: carpet, camera latch, 0x6a4 ride-on cue     24 air drag / ground deceleration
///  4 kill / Handle-skip returns                           25 `+0xce = +0xcf = 0`; inventory repair (later: Phase 3)
///  5 max speeds (quicksand, Double Speed)                 26 climb pre-move
///  6 idle +1, `+0x18c`, `+0x8a`, rope latch               27 latches cleared, `.ApplySpeedAndSeparateFromTiles`
///                                                            (plan row 22)
///  7 `.RopeCollide` (later: W3)                           28 surface material: damage (P4), ice
///  8 gravity selection, submerged brake, swim entry       29 lost the wall → v = 0
///  9 jump base J, High Jump, Feather Fall                 30 `.HandleBreathing` (P3)
/// 10 `.StandardSpriteHandles`                             31 held-item face 0 (P3); cast / wand (later: Phase 4)
/// 11 Shadow Double (later: Phase 4)                       32 potion drink (later: Phase 4)
/// 12 crunch-capable `+0xeb`                               33 state / face selection (`PlayerStates`, P3)
/// 13 countdown timers                                     34 pull-up reset, facing `+0x17e`
/// 14 power-up `.TickTock`s (later: Phase 4); 0610/0614   35 oxygen, drowning, bubbles (P4)
/// 15 `+0x116` copy, water-pass flag, near-surface         36 teleporter charge, blink, power-up tint (P3)
/// 16 spirit form (later: Phase 4)                         37 level side push hdr+0x272c
/// 17 liquid damage / heal (P4)                           38 `.PlayerConstraints` (map, glider; arena later)
/// 18 countdowns 06d8 / 06cc, see-saw flag                 39 pixel / centre positions; look-ahead + `.PlayerScroll`
/// 19 pre-move `.SeparateFromTiles2` (plan row 13)            (`PlayerScroll`, P5)
/// 20 hot rect, ground latch, catapult, impact            40 end `.SeparateFromTiles2` (water pass; plan row 35),
///                                                            draw offsets (plan row 36)
/// 21 `.HandleKeys` (door transit: input cleared)          41 death trigger, breath refill (P4); liquid tint
///                                                            (later: no seam)
///                                                         42 tail: copies, below-map, stillness, ride ramps, trail
///                                                            ring (later: Phase 4), `.StandardSpriteCleanup`,
///                                                            counters, tint overrides
public enum Player {
    /// `.SetupPlayerSprite`'s layer `+0x80` and type `+4`.
    public static let layer: Int16 = 10
    public static let spriteType: Int16 = 0x45
    /// The held-item sprite's type (`.SetupHeldItemSprite`) and the trail sprites' (`.SetupPlayerSprite`'s loop).
    public static let heldItemType: Int16 = 100
    public static let trailType: Int16 = 1
    /// Gravity `+0x110`: normal 0x1b8, swimming / submerged 0x50, spin in water 0x118, Feather Fall 0x40, rope 0.
    public static let gravity: Int16 = 0x1b8
    public static let swimGravity: Int16 = 0x50
    public static let waterSpinGravity: Int16 = 0x118
    public static let featherFallGravity: Int16 = 0x40
    /// The terminal fall speed (row 23).
    public static let terminalVY: Int32 = 12000
    /// 0.65 (f64 `dRam100a1a30` = `0x3fe4cccccccccccd`): the quicksand vy factor (row 22).
    static let quicksandFactor = Double(bitPattern: 0x3fe4_cccc_cccc_cccd)

    /// `.GameLoop`'s `MTNewSprite(0, x, y, 10, −1, .SetupPlayerSprite)` (decompile l. 5181) with the globals it
    /// writes first (`fe68 = x`, `fe64 = y`, `fd94 = x + 0x32`, `fd90 = y + 0x3b`; l. 5145–5150). x, y = the header
    /// start − 0x20 (`.NewGame` l. 5823). `.SetupPlayerSprite` (l. 42781–42983): `.InitSprite`, `.ClearPlayerVars`
    /// (`PlayerState()`), melee item −1, ridden 0, look-ahead 0, dying 0, type 0x45, v 0, layer 10, HP `+0xa4 = G+4`,
    /// gravity 0x1b8, the player Handle, hit callback 0, the tile callback; `fd44 = fe68 = +8`, `fd40 = fe64 = +6`,
    /// 24.8 from `+8`/`+6`; face 0; hot rect `(0x26, 0x22, 0x3e, 0x55)`; exertion 0; `+0x13c = 0x100`;
    /// `+0x90 = 0x100`; facing from `G+0x16` (0 → F 2 and `+0x17e = 0`, else F 1 and `+0x17e = 1`; both
    /// `5f5a`/`5f5c`). Inside the Setup, before the player's own `.MTInsertSprite` (P3, the P1a carry): the held-item
    /// sprite `MTNewSprite(100, 0, 0, 0x14, 0x1ff, .SetupHeldItemSprite)` into `_DAT_100a065c` (l. 42846), then the
    /// five trail sprites `MTNewSprite(1, −1, −1, +0x80 − 1 = 9, 0x1ff, .SetupTrailSprite)` into `PTR_DAT_100a051c`
    /// (l. 42898–42907) — both `.inert` here: `.HandleHeldItemSprite @ 1004be74` only re-pins a faceless sprite
    /// (// later: Phase 4, held items) and `.HandleTrailSprite @ 1004b354` is `.StandardSpriteHandles` +
    /// `.StandardSpriteCleanup` of a faceless sprite (// later: Phase 4, `.DoubleSpeedTrail` gives them faces);
    /// neither Setup nor Handle draws `FastRand` (plan Invariant 4). Not built: the Shadow-Double ring, the Pentashield
    /// slots and `+0xe4 = 1` (the dead second loop's gate) — // later: Phase 4.
    /// `PTR_DAT_100a0530` (the global copy of the hot rect, `SetRect` at l. 42818–42820) is not kept: its one TOC
    /// load is that store (raw `1004af68 lwz r3,-0x7310(r2)`) — write-only.
    ///
    /// When `.MTNewSprite` finds no free record it returns 0 after `.ReportError` (l. 30689–30701) without running the
    /// Setup, and `.GameLoop` stores `*_DAT_1009fdd8 = 0`: no player — here nil, `playerID` nil and `PlayerState`
    /// untouched.
    @discardableResult
    public static func spawn(world w: SpriteWorld, x: Int, y: Int) -> Int? {
        var p = PlayerState()
        // Not `.ClearPlayerVars`' globals, so the Setup leaves them: the crunch-overlay table (cleared by
        // `.ClearCrunchSprites` from `.GameLoop`, l. 5160, before `.SetupLevel`) and the water-effects cache flag
        // `*_DAT_100a00f4` (written only by `.FillCachedTileArray` l. 8568 and `.DestroyCrunchTile` l. 39072).
        p.crunchSprites = w.player.crunchSprites
        p.tileCacheValid = w.player.tileCacheValid
        p.pixelX = Int16(truncatingIfNeeded: x)
        p.pixelY = Int16(truncatingIfNeeded: y)
        p.centreX = Int16(truncatingIfNeeded: x + 0x32)
        p.centreY = Int16(truncatingIfNeeded: y + 0x3b)
        let hp = w.globals.health
        let left = w.globals.startFacing != 0
        var held: Int?
        var trail: [Int?] = []
        let id = w.newSprite(type: 0, x: x, y: y, layer: layer, handler: .player) { s in
            s.type = spriteType
            s.vy = 0
            s.vx = 0
            s.layer = Int32(layer)
            s.hp = hp
            s.gravity = gravity
            s.hasHit = false
            p.focusX = Int16(truncatingIfNeeded: s.oldPosition.x)
            p.focusY = Int16(truncatingIfNeeded: s.oldPosition.y)
            p.pixelX = p.focusX
            p.pixelY = p.focusY
            s.x256 = Int32(p.focusX) << 8
            s.y256 = Int32(p.focusY) << 8
            s.face = nil
            s.hotRect = HandleKeys.standardHotRect
            held = w.newSprite(type: heldItemType, x: 0, y: 0, layer: 0x14, handler: .inert, record: 0x1ff) { h in
                // `.SetupHeldItemSprite @ 1004bdd0` (l. 43406–43425).
                h.type = heldItemType
                h.face = nil
                h.y = 0
                h.x = 0
                h.layer = 0x14
                h.hasHit = false
                h.hotRect = IdleSprites.Rect(top: 2, left: -2, bottom: 0x16, right: 0x1a)
            }
            let trailLayer = Int16(truncatingIfNeeded: s.layer - 1)
            for _ in 0..<5 {
                // `.SetupTrailSprite @ 1004b3b4`: `.InitSprite` and the Handle.
                trail.append(w.newSprite(type: trailType, x: -1, y: -1, layer: trailLayer, handler: .inert,
                                         record: 0x1ff))
            }
            s.pushForce = 0x100
            s.windScale = 0x100
            s.mirrored = left
        }
        guard let id else {
            w.playerID = nil
            return nil
        }
        p.facing = left ? 1 : 2
        p.lastFacing = p.facing
        p.heldItem = held
        p.trail = trail
        w.player = p
        w.playerID = id
        return id
    }

    /// `.HandlePlayerSprite(s)`: one frame of the player.
    /// - Parameter keys: this frame's `.IsInputKeyPressed` snapshot.
    /// - Parameter solver: the tile solver over `world` (built once per level by the caller; one is made if nil).
    /// - Parameter tileHit: the player's tile callback `+0x1f8`; nil (the default, the locked S2 call
    ///   `Player.handle(world:keys:)`) = `.HitPlayerTileSprite` with this frame's keys (`PlayerTiles.hit`, P2). A test
    ///   may pass a double.
    /// - Parameter faceWidth: the width of a face (face `+6`) for `.StandardSpriteCleanup`'s occluder clip — Core has
    ///   no face records: the cell width of the player's set (`PlayerStates.faceWidth`).
    public static func handle(world w: SpriteWorld, keys: InputActions, solver: TileSolver? = nil,
                              tileHit: TileHit? = nil, faceWidth: (FaceRef) -> Int = PlayerStates.faceWidth) {
        guard let id = w.playerID, w.active.record(id: id) != nil else { return }
        let solver = solver ?? TileSolver(world: w)
        let tileHit = tileHit ?? PlayerTiles.hit(keys: keys)
        func s() -> SpriteSlot { w.active.record(id: id)! }
        func set(_ body: (inout SpriteSlot) -> Void) { w.active.update(id: id, body) }

        // 1 (l. 44486–44488): ridden copy, last facing, turn flag.
        w.player.ridden = s().ridden
        w.player.lastFacing = w.player.facing
        w.player.turnMirror = false
        // 2 (l. 44489–44531): the looped ambient sound of level modes 2/4 (`*_DAT_1009fec4`, `.STPlayLoopedSound`,
        // re-panned by the player's distance). // later: auto-scroll levels (not L1/L2)
        // 3 (l. 44532–44552).
        riding(w, id: id)
        // 4 (l. 44553–44558).
        if s().dead || s().handleSkip { return }
        // 5 (l. 44559–44588).
        maxSpeeds(w, id: id)
        // 6 (l. 44589–44594).
        w.player.idle &+= 1
        let notClimbing = w.player.climb == 0
        set { p in
            p.noWaterSplit = false
            p.currentApplies = notClimbing
        }
        w.player.lastRope = w.player.rope
        w.player.rope = false
        // 7: `if dying < 1: .RopeCollide(s)` (l. 44595–44597; W3).
        if w.player.dying < 1 { RopeSprite.collide(w, player: id, keys: keys) }
        // 8 (l. 44598–44658).
        selectGravity(world: w, id: id)
        // 9 (l. 44659–44672).
        if (s().groundKind != 0 || w.player.climb != 0) && w.player.ridden == nil { w.player.jumpBase = 0 }
        if w.player.highJump { w.player.jumpBase = -0x898 }
        if w.player.featherFall {
            set { p in
                if 0 < p.vy { p.gravity = featherFallGravity }
                if 0x352 < p.vy { p.vy = 0x352 }
            }
        }
        // 10 (l. 44673).
        w.standardSpriteHandles(id)
        // 11 (l. 44674–44685): the Shadow Double sprite 0x1b39 (`PTR_DAT_100a0654`/`_DAT_100a0658`). // later: Phase 4
        // 12 (l. 44686–44691).
        let crunch: UInt8 = (w.player.spin || s().groundKind != 0) ? 1 : 0
        set { $0.crunches = crunch }
        // 13 (l. 44692–44747).
        countdowns(w, id: id)
        // 14 (l. 44748–44814): `.TickTock` of the power-up timers 0650/064c/0640/0630/0624/0618 and their
        // active/blink flags (0654, 0648/0644, 0638/0634, 062c/0628, 0620/061c). // later: Phase 4 (no Phase-2 writer
        // of the timers; the flags stay 0). Then 0610 −1 (no floor) and 0614 = (0610 ≥ 1):
        w.player.countdown0610 &-= 1
        w.player.flag0614 = w.player.countdown0610 >= 1
        // 15 (l. 44815–44826).
        w.player.lastInvulnerable = s().invulnerable
        w.player.waterPass = false
        let last = s().lastWater
        if last < 1 || 0x15 < last || s().waterKind == 5 {
            if s().groundKind != 0 || 0x2b < last || s().lastWater == 0 { w.player.nearSurface = false }
        } else {
            w.player.nearSurface = true
        }
        // 16 (l. 44827–44855): spirit form (`_DAT_100a0578 > 0`, `.TickTockLong`). // later: Phase 4
        // 17 (l. 44856–44908): liquid damage / heal (`PTR_DAT_100a0538`, kinds 0/1/2/3; P4).
        PlayerLiquids.liquidDamage(w, id: id)
        // 18 (l. 44909–44915).
        if 0 < w.player.countdown06d8 { w.player.countdown06d8 -= 1 }
        if 0 < w.player.countdown06cc { w.player.countdown06cc -= 1 }
        w.player.seeSawTouch = false
        // 19 (l. 44916; plan row 13): the pre-move contact pass.
        solver.separateFromTiles(id, pass: tileHit)
        // 20 (l. 44917–44941).
        if w.player.dying == 0 { set { $0.hotRect = HandleKeys.standardHotRect } }   // both arms identical
        if w.player.ridden == nil {
            w.player.groundLast = s().groundKind
        } else {
            set { $0.groundKind = 3 }
            w.player.groundLast = 3
        }
        if s().classTimer == 1 {                                          // `+0x14c`: the catapult request
            w.player.airCounter = 8
            w.player.groundLast = 0
            set { p in
                p.groundKind = 0
                p.classTimer = 0
            }
        }
        w.player.impact = s().vy
        // 21 (l. 44942–44950).
        if w.player.doorTransit == 0 {
            HandleKeys.run(world: w, keys: keys, ridden: w.player.ridden)
        } else {
            w.player.walkRight = false
            w.player.walkLeft = false
            set { p in
                p.vy = 0
                p.vx = 0
            }
        }
        // 22 (l. 44951–44957): quicksand.
        if (s().waterRow != 0 || s().lastWater != 0) && s().waterKind == 5 {
            set { $0.vy = TileSolver.fctiwz(Double($0.vy) * quicksandFactor) }
        }
        // 23 (l. 44958–44968): not while clinging; no gravity while floating (`+0x120 ≠ 0 ∧ +0x19e ≠ 0`).
        if w.player.climb == 0 {
            set { p in
                if p.lastWater == 0 || p.buoyancy == 0 { p.vy &+= Int32(p.gravity) }
                if terminalVY < p.vy { p.vy = terminalVY }
                if p.vy == 0 { p.vy = 1 }
            }
        }
        // 24 (l. 44969–45053).
        dragAndDeceleration(w, id: id)
        // 25 (l. 45054–45063).
        set { p in
            p.groundKind = 0
            p.ceilingHit = 0
        }
        // The selected-slot repair (`G+0x172`, the item at `G+0x24 + 10·slot`). // later: Phase 3 (inventory)
        // 26 (l. 45064–45100).
        climbPreMove(w, id: id)
        // 27 (l. 45101–45105; plan row 22): the move.
        w.player.bumpedLatch = false                                      // `_DAT_100a0720`
        w.player.landedLatch = false                                      // `_DAT_100a0724`
        let moved = solver.applySpeedAndSeparate(id, climb: { w.player.climb }, pass: tileHit)
        if moved.zeroJumpCounter { w.player.jumpCounter = 0 }
        w.player.pixelX = moved.playerX
        w.player.pixelY = moved.playerY
        // 28 (l. 45106–45135).
        surfaceMaterial(w, id: id)
        // 29 (l. 45136–45139): lost the wall this frame.
        if w.player.lastClimb != 0 && w.player.climb == 0 {
            set { p in
                p.vy = 0
                p.vx = 0
            }
        }
        // 30 (l. 45140): `.HandleBreathing @ 1004bb44` (physics-sprites §8.8).
        Breathing.handle(world: w, id: id)
        // 31 (l. 45141–45176): the held item's face `*(_DAT_100a065c + 0xc0) = 0`; then the cast / wand phase machine,
        // `.CastSpell` // later: Phase 4 (spells, held items).
        if let h = w.player.heldItem { w.active.update(id: h) { $0.face = nil } }
        // 32 (l. 45177–45218): the potion drink. // later: Phase 4
        // 33 (l. 45219–46196, `goto LAB_10050e6c`): the state / face selection — glider, dying, spirit, boss grab,
        // hurt-stun, `05f8`, rope, swim, cling / climb / pull-up, melee, grounded (walk sounds, fidgets: FastRand),
        // airborne (`_DAT_100a0718`); first match wins (`PlayerStates.select`, P3).
        let tumbleDrawn = PlayerStates.select(world: w, id: id)           // `cStack_6b`
        // 34 (l. 46197–46203).
        if w.player.climb == 0 { w.player.pullUp = 0 }
        if !tumbleDrawn {
            let mirror = w.player.facing != 2, turn = w.player.turnMirror
            set { $0.mirrored = turn ? !mirror : mirror }
        }
        // 35 (l. 46204–46241): `.ShouldEmitBubbles` — oxygen, drowning damage, `.EmitBubble`, the bubble timer
        // (`FastRand(0x96)`; P4).
        PlayerLiquids.bubbles(w, id: id)
        // 36 (l. 46242–46346): teleporter charge (`FastRand(6)` sparkle), the invulnerability blink on the parity frames,
        // the power-up tints (`PlayerStates.tint`, P3; teleporters Phase 3, power-ups Phase 4 have no Phase-2 writer).
        PlayerStates.tint(w, id: id)
        // 37 (l. 46347–46365).
        sidePush(w, id: id)
        // 38 (l. 46366, raw `bl` at `100513b0`): `.PlayerConstraints @ 1004cb4c`.
        constraints(w, id: id)
        // 39 (l. 46367–46392).
        positions(w, id: id)
        // The camera look-ahead `_DAT_100a0680` and `uRam100a5114` (l. 46393–46422), then `.PlayerScroll @ 1004c528`
        // (l. 46423, raw `bl` at `10051594`; P5).
        PlayerScroll.handle(world: w, id: id)
        // 40 (l. 46424–46437; plan rows 35 and 36): the end pass (plan row 35) — the only one that processes water
        // (P2/P4) — then the draw offsets (plan row 36).
        w.player.flag05a0 = false
        w.player.waterPass = true
        solver.separateFromTiles(id, pass: tileHit)
        if w.player.pullUp == 0 {
            if (0 < w.player.dying || w.player.flag055c) && s().mirrored { set { $0.x &-= 0x32 } }
        } else if s().mirrored {
            set { $0.x &-= 0x14 }
        }
        w.player.flag055c = false
        // 41 (l. 46438–46488): the death trigger (HP < 1), the liquid screen tint (// later: no Phase-2 seam), the
        // breath refill (P4).
        PlayerLiquids.deathAndRefill(w, id: id)
        // 42 (l. 46489–46649).
        tail(w, id: id, faceWidth: faceWidth)
    }

    // MARK: - rows

    /// Row 3 (l. 44532–44552): no ridden sprite → carpet 0; else carpet = (type 0x438 / 0x439), the camera latch
    /// `*_DAT_1009fd34 = 1`, idle 0, and on a change from no ridden sprite onto a 0x6a4: `.STPlay3DSoundRand(509,
    /// 1, 0xbf, ridden+0xe)` — its rate drawn here (plan Invariant 4). Then `0554 = 0558`; carpet → vx 0.
    static func riding(_ w: SpriteWorld, id: Int) {
        if let r = w.player.ridden, let solid = w.active.record(id: r) {
            w.player.carpet = solid.type == 0x438 || solid.type == 0x439
            w.player.cameraSnapVeto = true
            w.player.idle = 0
            if w.player.lastRidden == nil && solid.type == 0x6a4 {
                let rate = w.rng.soundRate()
                w.player.cue(PlayerCue(call: .threeDRand, snd: 509, priority: 1, volume: 0xbf,
                                       position: solid.centre, rate: rate))   // `_DAT_100a02b4`
            }
        } else {
            w.player.carpet = false
        }
        w.player.lastRidden = w.player.ridden
        if w.player.carpet { w.active.update(id: id) { $0.vx = 0 } }
    }

    /// Row 5 (l. 44559–44588; raw `1004d904..1004da24`): Double Speed → idle 0 and 0xd82 / 0x15e0; in quicksand
    /// (`+0x11c ∨ +0x120`, kind 5): f = ((b − t) − min(+0x120 − t, b)) · 256 / (b − t) (`divw`), max = 0x76c −
    /// (f·0x3b6 >> 8), 0xc80 − (f·0x640 >> 8) (`srawi`); else 0x76c / 0xc80.
    static func maxSpeeds(_ w: SpriteWorld, id: Int) {
        guard let s = w.active.record(id: id) else { return }
        if w.player.doubleSpeed {
            w.player.idle = 0
            w.player.maxWalk = 0xd82
            w.player.maxRun = 0x15e0
            w.player.airWalk = 0xd82
            w.player.airRun = 0x15e0
        } else if (s.waterRow != 0 || s.lastWater != 0) && s.waterKind == 5 {
            let top = Int32(s.hotRect.top), bottom = Int32(s.hotRect.bottom)
            var depth = s.lastWater &- top
            if !(depth < bottom) { depth = bottom }
            let height = bottom &- top
            let f = SpriteSlot.divw((height &- depth) << 8, height)
            let walk = Int16(truncatingIfNeeded: 0x76c &- ((0x3b6 &* f) >> 8))
            let run = Int16(truncatingIfNeeded: 0xc80 &- ((0x640 &* f) >> 8))
            w.player.maxWalk = walk
            w.player.maxRun = run
            w.player.airWalk = walk
            w.player.airRun = run
        } else {
            w.player.maxWalk = 0x76c
            w.player.maxRun = 0xc80
            w.player.airWalk = 0x76c
            w.player.airRun = 0xc80
        }
    }

    /// Row 8 (l. 44598–44658; raw `1004da74..1004dc4c`): not gliding → gravity 0x1b8. Airborne (`+0xce == 0`):
    /// swimming or fully submerged (`+0x11c == 1`, last frame's water pass) → 0x50, spinning → 0x118; fully
    /// submerged: **vy −= 0x200 when vy > 0x6a4** (> 3000 spinning) (raw `1004daec..1004db10`; Bank correction
    /// A4), and not spinning, not swimming, liquid ≠ 5 → swim 1; on a rope → 0; the glider's pitch gravity
    /// (`_DAT_100a05d8`, wind scale `+0x90`) // later: Phase 4. Grounded → 0x1b8.
    static func selectGravity(world w: SpriteWorld, id: Int) {
        guard var s = w.active.record(id: id) else { return }
        if !w.player.glider { s.gravity = gravity }
        if s.groundKind == 0 {
            if w.player.swim != 0 || s.waterRow == 1 {
                s.gravity = swimGravity
                if w.player.spin { s.gravity = waterSpinGravity }
            }
            if s.waterRow == 1 {
                if !w.player.spin {
                    if 0x6a4 < s.vy { s.vy &-= 0x200 }
                } else if 3000 < s.vy {
                    s.vy &-= 0x200
                }
                if !w.player.spin && w.player.swim == 0 && s.waterKind != 5 { w.player.swim = 1 }
            }
            if w.player.rope { s.gravity = 0 }
            if w.player.glider && w.player.gliderExit == 0 {
                // later: Phase 4 — the glider's pitch gravity and wind scale (l. 44622–44655).
            }
        } else {
            s.gravity = gravity
        }
        let out = s
        w.active.update(id: id) { $0 = out }
    }

    /// Row 13 (l. 44692–44747): the counters that tick toward 0.
    static func countdowns(_ w: SpriteWorld, id: Int) {
        let invul = w.active.record(id: id)?.invulnerable ?? 0
        var p = w.player
        if p.lastInvulnerable < invul && p.doorTransit == 0 { p.newHit = 3 }
        if 0 < p.newHit { p.newHit -= 1 }
        if 0 < p.postJumpGuard { p.postJumpGuard -= 1 }
        if 0 < p.strokeCooldown { p.strokeCooldown -= 1 }
        if 0 < p.spinCooldown { p.spinCooldown -= 1 }
        if 0 < p.crunchCooldown { p.crunchCooldown -= 1 }
        if 0 < p.countdown05c4 { p.countdown05c4 -= 1 }
        if p.savePointHold < 1 {
            if p.savePointHold < 0 { p.savePointHold += 1 }
        } else {
            p.savePointHold -= 1
        }
        if 0 < p.noCling { p.noCling -= 1 }
        if 0 < p.countdown05a8 { p.countdown05a8 -= 1 }
        if 0 < p.countdownFDBC { p.countdownFDBC -= 1 }
        if 0 < p.countdownFDB8 { p.countdownFDB8 -= 1 }
        if 0 < p.countdownFDA8 { p.countdownFDA8 -= 1 }
        if 0 < p.carpetLock { p.carpetLock -= 1 }
        if 0 < p.bossGrab { p.bossGrab -= 1 }
        if 0 < p.countdown073c {
            p.countdown073c -= 1
            // At 0 with item 0x13 held: `.RemoveItem(0x13)`, `.UpdateStatusBar(1, 1, 0)`. // later: Phase 4
        }
        w.player = p
    }

    /// Row 24 (l. 44969–45053): airborne or gliding — drag toward 0 every frame, input or not: 100 (600 on a rope,
    /// 0x14 on the glider), no overshoot. Grounded — swim 0; vx > 0 without RIGHT input (`0734`) / vx < 0 without
    /// LEFT input (`0730`): −800 (300 while stunned), or on ice (`0694 ≠ 0`) −0694 only when `+0xce` is 3, 4, 7 or
    /// `+0x112 == 0`; clamped at 0.
    static func dragAndDeceleration(_ w: SpriteWorld, id: Int) {
        guard var s = w.active.record(id: id) else { return }
        let p = w.player
        if s.groundKind == 0 || p.glider {
            let d: Int32 = p.glider ? 0x14 : (p.rope ? 600 : 100)
            if 0 < s.vx {
                s.vx &-= d
                if s.vx < 0 { s.vx = 0 }
            }
            if s.vx < 0 {
                s.vx &+= d
                if 0 < s.vx { s.vx = 0 }
            }
        } else {
            w.player.swim = 0
            let iceApplies = [3, 4, 7].contains(s.groundKind) || s.slip == 0
            if 0 < s.vx && !p.walkRight {
                if p.stun == 0 {
                    if p.ice == 0 {
                        s.vx &-= 800
                    } else if iceApplies {
                        s.vx &-= Int32(p.ice)
                    }
                } else {
                    s.vx &-= 300
                }
                if s.vx < 0 { s.vx = 0 }
            }
            if s.vx < 0 && !p.walkLeft {
                if p.stun == 0 {
                    if p.ice == 0 {
                        s.vx &+= 800
                    } else if iceApplies {
                        s.vx &+= Int32(p.ice)
                    }
                } else {
                    s.vx &+= 300
                }
                if 0 < s.vx { s.vx = 0 }
            }
        }
        let out = s
        w.active.update(id: id) { $0 = out }
    }

    /// Row 26 (l. 45064–45100; raw `1004ea18..1004eaf8`): `0754 = climb`; clinging → spin 0, stop snd 427 if it
    /// is playing, vy eased 100 toward 0 (rising: ≥ −4000; falling: ≤ 4000), vx = −0x800 (wall on the left) /
    /// +0x800 into the wall, and climb cleared (the tile callback re-asserts it during the move, P2).
    static func climbPreMove(_ w: SpriteWorld, id: Int) {
        w.player.lastClimb = w.player.climb
        guard w.player.climb != 0 else { return }
        w.player.spin = false
        w.player.cue(PlayerCue(call: .stopIfPlaying, snd: 427))   // `_DAT_100a03cc`
        let side = w.player.wallSide
        w.active.update(id: id) { p in
            if p.vy < 0 {
                p.vy &+= 100
                if p.vy < 1 {
                    if p.vy < -4000 { p.vy = -4000 }
                } else {
                    p.vy = 0
                }
            } else if 0 < p.vy {
                p.vy &-= 100
                if p.vy < 0 {
                    p.vy = 0
                } else if 4000 < p.vy {
                    p.vy = 4000
                }
            }
            p.vx = side == 1 ? -0x800 : 0x800
        }
        w.player.climb = 0
    }

    /// Row 28 (l. 45106–45135; raw `1004eb24..1004ec4c`): the surface material `+0xd8` the move left. 3 (ice) →
    /// `0694 = (i16)((0x100 − hdr 0x2710)·800 >> 8)` (srawi), at least 1, and `+0x112 = hdr 0x2710 >> 4`;
    /// neither 2 nor 3 → both 0. 2 (a damaging surface, hdr 0x270e or 0x70): `PlayerLiquids.damagingSurface` (P4) —
    /// the ice globals left unchanged as the binary leaves them on that arm.
    static func surfaceMaterial(_ w: SpriteWorld, id: Int) {
        guard let s = w.active.record(id: id) else { return }
        switch s.material {
        case 2:
            PlayerLiquids.damagingSurface(w, id: id)
        case 3:
            let slip = Int32(w.level.header.iceSlipperiness)
            var ice = Int16(truncatingIfNeeded: ((0x100 &- slip) &* 0x320) >> 8)
            if ice < 1 { ice = 1 }
            w.player.ice = ice
            w.active.update(id: id) { $0.slip = Int16(truncatingIfNeeded: slip >> 4) }
        default:
            w.player.ice = 0
            w.active.update(id: id) { $0.slip = 0 }
        }
    }

    /// Row 37 (l. 46347–46365): hdr+0x272c v ≠ 0 — airborne and not riding: vx += v while vx is short of 5v (in
    /// v's direction); else x += v >> 2 (srawi) and the camera latch `*_DAT_1009fd34 = 1`.
    static func sidePush(_ w: SpriteWorld, id: Int) {
        let v = Int32(w.level.header.sidePush)
        guard v != 0, let s = w.active.record(id: id) else { return }
        if s.groundKind == 0 && w.player.ridden == nil {
            w.active.update(id: id) { p in
                if v < 0 {
                    if v &* 5 < p.vx { p.vx &+= v }
                } else if p.vx < v &* 5 {
                    p.vx &+= v
                }
            }
        } else {
            w.active.update(id: id) { $0.x256 &+= v >> 2 }
            w.player.cameraSnapVeto = true
        }
    }

    /// Row 38: `.PlayerConstraints @ 1004cb4c` (main l. 43991–44123; raw `1004cb4c..1004ce60`), in its order:
    /// - x (`lha +0xc`, read once): x < −64 → x = −64; else x > 32·W − 32 (hdr `+0xb280`) → x = that (`extsh`);
    ///   either clamp stores `+0x14 = x << 8` (raw `1004cb54..1004cbb4`).
    /// - y: y < −128 → y = −128, `+0x1c = y << 8`, then vy < −0x100 → vy = 0 (raw `1004cbb8..1004cbe8`).
    /// - on the glider `*_DAT_100a05e0`: vy < −0x9c4 → vy = −0x9c4 (raw `1004cbec..1004cc0c`).
    /// - the boss-arena lock (hdr `+0x2724` ≠ 0 ∧ `*_DAT_1009fed0` "no boss alive" = 0; raw `1004cc10..1004cd8c`,
    ///   bosses §1.3: the lock line |v ± 60|, the pan counter `_DAT_1009ff9c = −40`, the lock `PTR_DAT_1009fed4`).
    ///   // later: Phase 6 (bosses) — `fed0`/`fed4`/`ff9c` have no writer or reader yet (no boss Setup clears
    ///   `fed0`, `.SetupLevelSprites` sets it 1, so the arm cannot fire), and `Camera` refuses hdr `0x2724` ≠ 0.
    /// - the auto-scroll death (`*_DAT_1009fec4` ∧ mode `_DAT_1009fec0` 1–4 with the player past the scroll point
    ///   `PTR_DAT_1009fe78` −0x40 / +0x2a0 / −100 / +0x1c0 → G+6 = G+4 = 0, `+0xa4` = 0, `*_DAT_100a0568` =
    ///   `*_DAT_100a0564` = 1; raw `1004cd90..1004ce60`). // later: auto-scroll levels — `Camera` refuses hdr
    ///   `0x272a` ≠ 0 and `fec4`/`fec0` are not modelled (no Phase-2 level scrolls).
    static func constraints(_ w: SpriteWorld, id: Int) {
        let gridWidth = Int32(w.level.header.gridWidth)
        let glider = w.player.glider
        w.active.update(id: id) { p in
            let x = Int32(Int16(truncatingIfNeeded: p.x))
            if x < -0x40 {
                p.x = -0x40
                p.x256 = Int32(-0x40) << 8
            } else {
                let right = gridWidth &* 0x20 &- 0x20
                if right < x {
                    let cx = Int16(truncatingIfNeeded: right)
                    p.x = Int(cx)
                    p.x256 = Int32(cx) << 8
                }
            }
            if Int16(truncatingIfNeeded: p.y) < -0x80 {
                p.y = -0x80
                p.y256 = Int32(-0x80) << 8
                if p.vy < -0x100 { p.vy = 0 }
            }
            if glider && p.vy < -0x9c4 { p.vy = -0x9c4 }
        }
        // The arena lock and the auto-scroll death: see above. // later: Phase 6 (arena), auto-scroll levels
    }

    /// Row 39 (l. 46367–46392): `+8 = +0xc = fe68 = (i16)(x256 >> 8)`, `+6 = +0xa = fe64`; the centre
    /// `+0x10 = fd94 = x + l + ((r − l) >> 1)`, `+0xe = fd90 = y + t + ((b − t) >> 1)`; grounded, riding, clinging or
    /// `05a0` → `0740 = +0xe`.
    static func positions(_ w: SpriteWorld, id: Int) {
        guard var s = w.active.record(id: id) else { return }
        let px = SpriteWorld.pixel(s.x256), py = SpriteWorld.pixel(s.y256)
        s.oldPosition = SpriteSlot.Point(x: px, y: py)
        s.x = px
        s.y = py
        let r = s.hotRect
        s.centre.x = Int(Int16(truncatingIfNeeded: s.x + r.left + ((r.right - r.left) >> 1)))
        s.centre.y = Int(Int16(truncatingIfNeeded: s.y + r.top + ((r.bottom - r.top) >> 1)))
        let out = s
        w.active.update(id: id) { $0 = out }
        w.player.pixelX = Int16(truncatingIfNeeded: px)
        w.player.pixelY = Int16(truncatingIfNeeded: py)
        w.player.centreX = Int16(truncatingIfNeeded: s.centre.x)
        w.player.centreY = Int16(truncatingIfNeeded: s.centre.y)
        if s.groundKind != 0 || w.player.ridden != nil || w.player.climb != 0 || w.player.flag05a0 {
            w.player.groundCentreY = Int16(truncatingIfNeeded: s.centre.y)
        }
    }

    /// Row 42 (l. 46489–46649): `G+4 = HP`, `fd3c = vx`, `04c8 = vy`; below the map (y > hdr 0xb282·32 + 100) →
    /// HP 0; the stillness counter; the riding ramps; the Shadow-Double ring // later: Phase 4;
    /// `.DoubleSpeedTrail` // later: Phase 4; `.StandardSpriteCleanup`; `05ec` (0…0x1f) and `057c` (+2, 0…0x167);
    /// the tint overrides (05a8 → 0x10008 / 0x10009; spirit 0xb0001/0xb0005 // later: Phase 4; 0564 → 0x10007
    /// // later: Phase 4); `04cc` −1; `.UpdatePentSprites` // later: Phase 4.
    static func tail(_ w: SpriteWorld, id: Int, faceWidth: (FaceRef) -> Int) {
        guard let s = w.active.record(id: id) else { return }
        w.globals.health = s.hp
        w.player.lastVX = s.vx
        w.player.lastVY = s.vy
        if Int(w.level.header.gridHeight) * 0x20 + 100 < s.y { w.active.update(id: id) { $0.hp = 0 } }
        if s.x == s.drawnX && !w.player.flag05a0 && !w.player.glider && !s.inWind && s.y == s.drawnY
            && w.player.pullUp == 0 {
            if 0 < w.player.stillness { w.player.stillness -= 1 }
            w.player.standingStill = w.player.stillness == 0
        } else {
            w.player.stillness = 1
            w.player.standingStill = false
        }
        if w.player.ridden == nil {
            if 0 < w.player.rideRamp || 0 < w.player.rideRamp2 {
                w.player.rideRamp -= 2
                if w.player.rideRamp < 0 { w.player.rideRamp = 0 }
                if 0 < w.player.rideRamp2 { w.player.rideRamp2 -= 1 }
            }
        } else {
            if w.player.rideRamp < 0x1b {
                w.player.rideRamp += 2
                if 0x1b < w.player.rideRamp { w.player.rideRamp = 0x1b }
            }
            if w.player.rideRamp2 < 8 { w.player.rideRamp2 += 1 }
        }
        // The Shadow-Double pose ring `PTR_DAT_100a0520` (14 × 16 B) while not standing still. // later: Phase 4
        // `.DoubleSpeedTrail`. // later: Phase 4
        w.standardSpriteCleanup(id, faceWidth: faceWidth)
        w.player.counter05ec += 1
        if 0x1f < w.player.counter05ec { w.player.counter05ec = 0 }
        w.player.angle057c += 2
        if 0x167 < w.player.angle057c { w.player.angle057c -= 0x168 }
        if 0 < w.player.countdown05a8 {
            let m: UInt32 = w.player.countdown05a8 < 3 ? 0x10008 : 0x10009
            w.active.update(id: id) { $0.mode = m }
        }
        if w.player.oneWayTimer != 0 { w.player.oneWayTimer -= 1 }
    }
}
