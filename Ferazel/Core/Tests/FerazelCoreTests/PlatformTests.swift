import XCTest
@testable import FerazelCore

/// W1 (docs/plans/2026-10-10-ferazel-phase2.md): the Platform class (`.SetupPlatformSprite @ 10061f94`,
/// `.DoSetupPlatformSprite @ 10062098`, `.HandlePlatformSprite @ 100635b4`, `.HitPlatformSprite`,
/// `.HitPlatformTileSprite`), the radial geometry (`.MakeRadialTables`, `.UpdateRadialPos`, `.RadialWheelStep`,
/// `.BounceRadial`, `.UpdateRadiusSprites`) and the chain spokes, against the committed `Resources/Ferazel` (D26).
/// Platforms-ropes-radial §1–§2, -2 §8–§9; physics-sprites §8.9. A missing data file is a FAILURE, never a skip.
final class PlatformTests: XCTestCase {

    private func resources() throws -> FerazelResources { try FerazelData.open(try FerazelData.dataDirectory()) }

    private func session() throws -> FerazelSession {
        try FerazelSession(resources: try resources(), prefs: FerazelPrefs(), level: 1)
    }

    /// The record platform of `record` (not a sibling, not a spoke).
    private func platform(_ s: FerazelSession, record: Int16) throws -> Int {
        try XCTUnwrap(s.active.sprites.first { $0.recordIndex == record && $0.handler == .platform }).id
    }

    /// A world on `level` holding only the record platform `record` (its Setup as `.MTNewSprite` runs it).
    private func world(level: Int16, records: [Int]) throws -> (SpriteWorld, TileSolver, [Int]) {
        let L = try LevelFile.load(from: try resources(), level: level)
        let w = SpriteWorld(level: L)
        var ids: [Int] = []
        for r in records {
            let p = L.placements[r]
            ids.append(try XCTUnwrap(w.newSprite(type: p.type, x: Int(p.x), y: Int(p.y), layer: -1, handler: .platform,
                                                 record: Int16(r)) { PlatformSprite.setup(&$0) }))
        }
        return (w, TileSolver(world: w), ids)
    }

    // MARK: -

    func testRadialTablesMatchBinary() throws {
        // `.MakeRadialTables` (l. 35693–35731): (int)(float)(256·cos θ·256), −(int)(float)(256·sin θ·256), π = 3.1415926535.
        XCTAssertEqual(RadialTables.cosT.count, 360)
        XCTAssertEqual(RadialTables.sinT.count, 360)
        XCTAssertEqual(RadialTables.cosT[0], 65536)
        XCTAssertEqual(RadialTables.cosT[1], 65526)
        XCTAssertEqual(RadialTables.cosT[60], 32768)
        XCTAssertEqual(RadialTables.sinT[90], -65536)
        XCTAssertEqual(RadialTables.sinT[0], 0)
        XCTAssertEqual(RadialTables.sinT[1], -1143)                    // sinT is negated: "up" is positive
        XCTAssertEqual(RadialTables.sinT[270], 65536)
        XCTAssertEqual(RadialTables.cosT[180], -65536)
        XCTAssertEqual(RadialTables.cosT[359], 65526)
        XCTAssertEqual(RadialTables.sinT[359], 1143)
        // The `frsp` before `fctiwz`: 32767.99999… rounds to the float 32768 first (a double truncation gives 32767).
        XCTAssertEqual(RadialTables.sinT[30], -32768)
        XCTAssertEqual(RadialTables.cosT[120], -32768)
        XCTAssertEqual(RadialTables.sinT[210], 32768)
        XCTAssertEqual(RadialTables.cosT[300], 32768)
        XCTAssertEqual(RadialTables.cosT[45], 46340)
        XCTAssertEqual(RadialTables.pi, 3.1415926535)

        // `.FindRadWheelStepSpeedMod` (l. 36163–36191): a − 90 below 180, 270 − a from 180, folded into 0 … 359.
        let mods = [0, 89, 90, 179, 180, 270, 271, 359, 360, -1, 719].map { RadialMotion.wheelStepMod(Int16($0)) }
        XCTAssertEqual(mods, [-90, -1, 0, 89, 90, 0, -1, -89, -90, -89, -89])
        // `.FindUpdatedRadialSpeed` (l. 35981–36016): +g for 90 ≤ a ≤ 270, −g otherwise; damping only when > 0 and not
        // suppressed; the wheel term only on request.
        var b = Radial()
        b.gravity = 0x1e
        let pulls = [0, 89, 90, 180, 270, 271, 359].map { RadialMotion.updatedSpeed(b, angle: Int32($0) << 8, speed: 0) }
        XCTAssertEqual(pulls, [-30, -30, 30, 30, 30, -30, -30])
        XCTAssertEqual(RadialMotion.updatedSpeed(b, angle: (90 << 8) - 1, speed: 0), -30)   // a = 89 (angle >> 8)
        b.gravity = 0
        b.damp = 0xf7
        XCTAssertEqual(RadialMotion.updatedSpeed(b, angle: 0, speed: -90), -87)            // −22230 >> 8 (srawi)
        XCTAssertEqual(RadialMotion.updatedSpeed(b, angle: 0, speed: 90), 86)
        XCTAssertEqual(RadialMotion.updatedSpeed(b, angle: 0, speed: -90, noDamp: true), -90)
        XCTAssertEqual(RadialMotion.updatedSpeed(b, angle: 180 << 8, speed: 0, wheel: true, noDamp: true), 90)
        b.damp = -5
        XCTAssertEqual(RadialMotion.updatedSpeed(b, angle: 0, speed: -90), -90)

        // `.UpdateRadialPos`' angle limits (raw `1003dffc..1003e0d4`), a see-saw arm's: max 45 / min 315 (max ≤ min:
        // the test side by angle > 180°) and its sibling's max 225 / min 135 (max > min: by angle ≤ 180°); a clamp
        // reflects the speed by `+0x30` = 0x60. The hub wrapped speed/angle as written; one sprite on level 1.
        let w = SpriteWorld(level: try LevelFile.load(from: try resources(), level: 1))
        let id = try XCTUnwrap(w.newSprite(type: 1, x: 0, y: 0, layer: 0, handler: .inert))
        func limited(max: Int16, min: Int16, angle: Int32, speed: Int32) -> [Int32] {
            var r = Radial()
            r.maxDegrees = max
            r.minDegrees = min
            r.limitBounce = 0x60
            r.angle = angle
            r.speed = speed
            r.radius = 10 << 8
            w.active.update(id: id) { $0.radial = r }
            RadialMotion.updatePosition(w, id: id)
            let o = w.active.sprite(id: id)!.radial!
            return [o.angle, o.speed]
        }
        XCTAssertEqual(limited(max: 45, min: 315, angle: 44 << 8, speed: 0x200), [45 << 8, -0xc0])
        XCTAssertEqual(limited(max: 45, min: 315, angle: 44 << 8, speed: 0x100), [45 << 8, 0x100])   // exactly 45
        XCTAssertEqual(limited(max: 45, min: 315, angle: 316 << 8, speed: -0x200), [315 << 8, 0xc0])
        XCTAssertEqual(limited(max: 45, min: 315, angle: (179 << 8) - 1, speed: 0x100), [45 << 8, -0x60]) // 0xb2ff
        XCTAssertEqual(limited(max: 45, min: 315, angle: 179 << 8, speed: 0x100), [315 << 8, -0x60]) // 0xb400: min
        XCTAssertEqual(limited(max: 225, min: 135, angle: 136 << 8, speed: -0x200), [135 << 8, 0xc0])
        XCTAssertEqual(limited(max: 225, min: 135, angle: 224 << 8, speed: 0x200), [225 << 8, -0xc0])
        XCTAssertEqual(limited(max: 225, min: 135, angle: (180 << 8) - 1, speed: 2), [(180 << 8) + 1, 2]) // ≤ 0xb400: min side
        XCTAssertEqual(limited(max: 0, min: 0, angle: 359 << 8, speed: 0x200), [(1 << 8), 0x200])  // no limits; wrapped
        XCTAssertEqual(limited(max: 0, min: 0, angle: 0, speed: -1), [0x16800 - 1, -1])
        // persp 0: the position = hub + d − (stored centre − pixel copy); 24.8 from the pixel copy.
        w.active.update(id: id) { c in
            c.x = 5
            c.y = 7
            c.centre = SpriteSlot.Point(x: 15, y: 10)
            var r = Radial()
            r.hubX = (100 << 8) + 0xff
            r.hubY = 200 << 8
            r.radius = 60 << 8
            r.angle = 90 << 8
            c.radial = r
        }
        RadialMotion.updatePosition(w, id: id)
        let q = try XCTUnwrap(w.active.sprite(id: id))
        XCTAssertEqual([q.x, q.y], [100 + 0 - 10, 200 - 60 - 3])          // a = 90: dx 0, dy −60
        XCTAssertEqual([q.x256, q.y256], [90 << 8, 137 << 8])
        // The hub damping (`+0x10 > 0`): hvx·d >> 8 (srawi), 0 when unchanged — −1·0xf7 >> 8 = −1 → 0; hvy damped
        // with no such test: 1000·0xf7 >> 8 = 964.
        w.active.update(id: id) { c in
            var r = Radial()
            r.hubDamp = 0xf7
            r.hubVX = -1
            r.hubVY = 1000
            c.radial = r
        }
        RadialMotion.updatePosition(w, id: id)
        XCTAssertEqual(w.active.sprite(id: id)?.radial.map { [$0.hubVX, $0.hubVY] }, [0, 964])
        // `.RadialWheelStep(s, k)`: speed += (mod(a)·k) >> 8 (srawi: −90·0x81 = −11610 → −46); hub vx = −speed only
        // when `+0x10 < 0x100`.
        func stepped(k: Int32, hubDamp: Int32) -> [Int32]? {
            w.active.update(id: id) { c in
                var r = Radial()
                r.hubDamp = hubDamp
                r.hubVX = 77
                c.radial = r
            }
            RadialMotion.wheelStep(w, id: id, k: k)
            return w.active.sprite(id: id)?.radial.map { [$0.speed, $0.hubVX] }
        }
        XCTAssertEqual(stepped(k: 0x81, hubDamp: 0), [-46, 46])
        XCTAssertEqual(stepped(k: 0x100, hubDamp: 0xff), [-90, 90])
        XCTAssertEqual(stepped(k: 0x100, hubDamp: 0x100), [-90, 77])     // `+0x10` = 0x100: the hub vx kept
    }

    func testShuttleL1Rec25() throws {
        // L1 record 25: type 1400, p1 2 (horizontal), p2 300, p3 1280, p4 0, at (292, 972).
        let s = try session()
        let id = try platform(s, record: 25)
        XCTAssertNil(s.active.sprite(id: id)?.face)                     // `.SetupPlatformSprite` `+0xc0 = 0`
        var xs: [Int] = []
        for _ in 0..<400 {
            _ = s.step(keys: KeyState())
            xs.append(try XCTUnwrap(s.active.sprite(id: id)).x)
        }
        let p = try XCTUnwrap(s.active.sprite(id: id))
        // `.DoSetupPlatformSprite` (l. 54665–54677): bounds x256 ± 8·speed, x256 + 256·p2 − 8·speed; vx = speed.
        XCTAssertEqual(p.classWord150, 292 * 256 + 1280 * 8)
        XCTAssertEqual(p.classWord154, 292 * 256 + 300 * 256 - 1280 * 8)
        XCTAssertEqual(p.classTimer, 1280)
        XCTAssertEqual(p.face, FaceRef(pict: 1400, index: 0, set: .encoded))
        XCTAssertEqual(p.hotRect, IdleSprites.Rect(top: 6, left: 0x10, bottom: 0x1e, right: 0x3d))
        XCTAssertTrue(p.setupDone)
        XCTAssertEqual(p.sag, 0x50)                                     // mode 2 keeps the Setup's sag
        XCTAssertEqual(Array(xs.prefix(3)), [297, 302, 307])
        XCTAssertEqual(xs.min(), 284)
        XCTAssertEqual(xs.max(), 599)
        // The turning points (a maximum every 158 frames).
        var tops: [Int] = []
        for i in 1..<(xs.count - 1) where xs[i] > xs[i - 1] && xs[i] >= xs[i + 1] { tops.append(i + 1) }
        XCTAssertEqual(tops, [68, 226, 384])
        XCTAssertEqual(tops[1] - tops[0], 158)
        var bottoms: [Int] = []
        for i in 1..<(xs.count - 1) where xs[i] < xs[i - 1] && xs[i] <= xs[i + 1] { bottoms.append(i + 1) }
        XCTAssertEqual(bottoms, [147, 305])
        // The reversal: past `+0x154` the direction `+0xa6` turns −1 and vx eases by speed >> 4 = 80 per frame.
        XCTAssertEqual(p.vy, 0)

        // In the session: the player dropped onto it lands in the player pass, rides it from the next frame (row 3
        // copies `+0xdc`, raises the camera's snap veto `_DAT_1009fd34`) and is carried by its moves.
        let player = s.playerID
        let top = try XCTUnwrap(s.active.sprite(id: id))
        s.world.active.update(id: player) { c in
            c.x = top.x
            c.y = top.y + 6 - 85 - 2
            c.x256 = Int32(c.x) << 8
            c.y256 = Int32(c.y) << 8
            c.vx = 0
            c.vy = 0x300
        }
        _ = s.step(keys: KeyState())
        XCTAssertEqual(s.active.sprite(id: player)?.ridden, id)
        XCTAssertEqual(s.active.sprite(id: id)?.rider, player)
        let x0 = try XCTUnwrap(s.active.sprite(id: player)).x
        let px0 = try XCTUnwrap(s.active.sprite(id: id)).x
        _ = s.step(keys: KeyState())
        XCTAssertEqual(s.player.ridden, id)                               // `PTR_DAT_100a0558` (row 3)
        XCTAssertTrue(s.player.cameraSnapVeto)                            // `*_DAT_1009fd34 = 1`
        XCTAssertEqual(s.active.sprite(id: player)?.ridden, id)           // still on it after this frame's pass
        let dx = try XCTUnwrap(s.active.sprite(id: id)).x - px0
        XCTAssertNotEqual(dx, 0)
        XCTAssertEqual(try XCTUnwrap(s.active.sprite(id: player)).x - x0, dx)   // carried by the platform's move
        // The session's `.MTCollideSprites` runs the Platform hit callback `+0x5c` (`.HitPlatformSprite`): a mode-0
        // platform made beside the player, falling onto record 25's top, lands on it in the step (the platform the
        // mover).
        let low = try XCTUnwrap(s.active.sprite(id: id))
        let upper = try XCTUnwrap(s.world.newSprite(type: 1400, x: low.x - 30, y: low.y - 0x18 + 1, layer: -1,
                                                    handler: .platform, record: 25) { PlatformSprite.setup(&$0) })
        s.world.active.update(id: upper) { c in
            c.setupDone = true
            c.subtype = 0
            c.hotRect = PlatformSprite.defaultRect
            c.vy = 0x100
        }
        _ = s.step(keys: KeyState())
        XCTAssertEqual(s.active.sprite(id: upper)?.ridden, id)
        XCTAssertEqual(s.active.sprite(id: upper).map { [$0.groundKind, $0.onSprite] }, [3, 1])
        XCTAssertEqual(s.active.sprite(id: id)?.rider, player)           // the player pass lands after, on `+0xe0`
        // An idled record (`.ActiveToIdleSprite`: `+0x4c = 0`, `SpriteSlot.handleCleared`) stays listed until the
        // step's `.UpdateSprites`: `.MTHandleSprites` skips it, the player pass skips it, then it is killed (the
        // record stays readable).
        s.world.active.update(id: id) { $0.handleCleared = true }
        var handled: [Int] = []
        s.world.handleSprites { _, h in handled.append(h) }
        XCTAssertFalse(handled.contains(id))
        XCTAssertTrue(handled.contains(upper))
        let me0 = try XCTUnwrap(s.active.sprite(id: player))
        let plat0 = try XCTUnwrap(s.active.sprite(id: id))
        s.world.active.update(id: player) { c in                         // the player's rect well inside its rect
            c.x = plat0.x
            c.y = plat0.y + 6 - 85 + 8
        }
        var touched: [Int] = []
        s.world.collideSpecial(hitPlayer: { _, _, c in touched.append(c) }, hit: { _, _, _ in })
        XCTAssertFalse(touched.contains(id))
        s.world.active.update(id: id) { $0.handleCleared = false }
        touched = []
        s.world.collideSpecial(hitPlayer: { _, _, c in touched.append(c) }, hit: { _, _, _ in })
        XCTAssertTrue(touched.contains(id))                              // the same contact, not idled
        s.world.active.update(id: id) { $0.handleCleared = true }
        s.world.active.update(id: player) { $0 = me0 }
        _ = s.step(keys: KeyState())
        XCTAssertFalse(s.active.sprites.contains { $0.id == id })         // `.UpdateSprites` killed it
        let gone = try XCTUnwrap(s.active.record(id: id))
        XCTAssertEqual([gone.x, gone.y, Int(gone.x256)], [plat0.x, plat0.y, Int(plat0.x256)])   // not handled
        XCTAssertTrue(s.active.sprites.contains { $0.id == upper })

        // The Platform arm of `.HitPlayerSprite` (l. 49124–49147) on this shuttle, in a world of its own: the player
        // falling onto its top lands (`.PlatformBounce(player, platform, centre, 0, rect, 0)`).
        let (w, solver, ids) = try world(level: 1, records: [25])
        let pid = ids[0]
        PlatformSprite.handle(world: w, id: pid, solver: solver)
        let pl = try XCTUnwrap(Player.spawn(world: w, x: 0, y: 0))
        func drop(onto plat: Int, vy: Int32) throws {
            let q = try XCTUnwrap(w.active.sprite(id: plat))
            // The player's hot rect (top 34, left 38, bottom 85, right 62): bottom 2 px into the platform's top
            // (y + 6), 4 px above it the frame before.
            w.active.update(id: pl) { c in
                c.x = q.x
                c.y = q.y + 6 - 85 + 2
                c.x256 = Int32(c.x) << 8
                c.y256 = Int32(c.y) << 8
                c.vy = vy
                c.vx = 0
                c.ridden = nil
                c.groundKind = 0
                c.invulnerable = 0
                c.hp = 0x230
            }
            w.active.update(id: plat) { c in
                c.rider = nil
                c.ridingLatch = false
                c.vy = 0
            }
            w.player.landedLatch = true
            w.player.bumpedLatch = true
            w.player.cues = []
        }
        try drop(onto: pid, vy: 0x600)
        w.player.groundLast = 0
        w.player.impact = 0x600
        HitPlayerSprite.hit(w, player: pl, other: pid)
        var me = try XCTUnwrap(w.active.sprite(id: pl))
        var q = try XCTUnwrap(w.active.sprite(id: pid))
        XCTAssertEqual(me.ridden, pid)
        XCTAssertEqual([me.groundKind, me.onSprite], [3, 1])
        XCTAssertTrue(me.oneWayLanded)
        XCTAssertEqual(me.vy, 0)
        XCTAssertEqual(me.y, q.y + 6 - 85)
        XCTAssertEqual(q.rider, pl)
        XCTAssertTrue(q.ridingLatch)
        XCTAssertEqual(q.vy, (0x600 * 0x50) >> 8)                         // the sag: entry vy > 0x200
        XCTAssertTrue(w.player.landedLatch)                              // cleared, then `.CheckGroundCeilingHitEffects`
        XCTAssertFalse(w.player.bumpedLatch)
        XCTAssertEqual(w.player.cues.last?.snd, 601)                     // v = 0x600 >> 7 = 12 < 0x30 → 0; > 700, dry
        // Dying, or in spirit form: nothing.
        for gate in 0..<2 {
            try drop(onto: pid, vy: 0x600)
            if gate == 0 { w.player.dying = 1 } else { w.player.spiritTimer = 1 }
            HitPlayerSprite.hit(w, player: pl, other: pid)
            XCTAssertNil(w.active.sprite(id: pl)?.ridden)
            XCTAssertFalse(w.active.sprite(id: pid)?.ridingLatch ?? true)
            w.player.dying = 0
            w.player.spiritTimer = 0
        }
        // Rising into it from below: one-way, no contact, no cue but the latches cleared.
        try drop(onto: pid, vy: -0x300)
        HitPlayerSprite.hit(w, player: pl, other: pid)
        XCTAssertNil(w.active.sprite(id: pl)?.ridden)
        XCTAssertFalse(w.player.landedLatch)
        // A catapult whose record p1 is 2 (record 25's p1 is 2) is walk-through: return before the bounce.
        w.active.update(id: pid) { $0.type = 0x582 }
        try drop(onto: pid, vy: 0x600)
        HitPlayerSprite.hit(w, player: pl, other: pid)
        XCTAssertNil(w.active.sprite(id: pl)?.ridden)
        // The spiked underside 0x57d: hurt when not riding it and (centre y at or below its centre, or vy < −0x200),
        // not invulnerable → 450, HP −0x70, invulnerable 0x3c, flash 0xc.
        w.active.update(id: pid) { $0.type = PlatformSprite.spiked }
        try drop(onto: pid, vy: -0x201)
        HitPlayerSprite.hit(w, player: pl, other: pid)
        me = try XCTUnwrap(w.active.sprite(id: pl))
        XCTAssertEqual([me.hp, me.invulnerable, me.flash], [0x230 - 0x70, 0x3c, 0xc])
        XCTAssertEqual(w.player.cues.map(\.snd), [450])
        try drop(onto: pid, vy: -0x200)                                   // not < −0x200, centre above: no hurt
        HitPlayerSprite.hit(w, player: pl, other: pid)
        XCTAssertEqual(w.active.sprite(id: pl)?.hp, 0x230)
        try drop(onto: pid, vy: 0x600)                                    // landed on it: riding it, no hurt
        HitPlayerSprite.hit(w, player: pl, other: pid)
        XCTAssertEqual(w.active.sprite(id: pl)?.hp, 0x230)
        XCTAssertEqual(w.active.sprite(id: pl)?.ridden, pid)
        try drop(onto: pid, vy: -0x300)                                   // invulnerable: no hurt
        w.active.update(id: pl) { $0.invulnerable = 1 }
        HitPlayerSprite.hit(w, player: pl, other: pid)
        XCTAssertEqual(w.active.sprite(id: pl)?.hp, 0x230)
        // Centre at or below the platform's: hurt (the player's centre y set to the platform's).
        try drop(onto: pid, vy: 0)
        q = try XCTUnwrap(w.active.sprite(id: pid))
        w.active.update(id: pl) { $0.centre.y = q.centre.y }
        HitPlayerSprite.hit(w, player: pl, other: pid)
        XCTAssertEqual(w.active.sprite(id: pl)?.hp, 0x230 - 0x70)
        w.active.update(id: pl) { $0.centre.y = q.centre.y - 1 }
        try drop(onto: pid, vy: 0)
        HitPlayerSprite.hit(w, player: pl, other: pid)
        XCTAssertEqual(w.active.sprite(id: pl)?.hp, 0x230)
        // Centre at or below, riding it (`+0xdc` == the platform): no hurt; the same contact not riding it hurts.
        for riding in [true, false] {
            try drop(onto: pid, vy: 0)
            w.active.update(id: pl) { c in
                c.centre.y = q.centre.y
                c.ridden = riding ? pid : nil
            }
            HitPlayerSprite.hit(w, player: pl, other: pid)
            XCTAssertEqual(w.active.sprite(id: pl)?.hp, riding ? 0x230 : 0x230 - 0x70, "riding \(riding)")
        }
        // An idled record (`+0x4c = 0`) is no Platform: nothing, the latches not even cleared.
        w.active.update(id: pid) { $0.type = 1400 }
        try drop(onto: pid, vy: 0x600)
        w.active.update(id: pid) { $0.handleCleared = true }
        HitPlayerSprite.hit(w, player: pl, other: pid)
        XCTAssertNil(w.active.sprite(id: pl)?.ridden)
        XCTAssertTrue(w.player.landedLatch && w.player.bumpedLatch)
        w.active.update(id: pid) { $0.handleCleared = false }
        // Mode 2 (horizontal) with no clamp after the step: vx 1279 < 1280 steps by 1280 >> 4 = 80 to 1359.
        w.active.update(id: pid) { c in
            c.vx = 1279
            c.counterA6 = 1
            c.x256 = c.classWord154
        }
        PlatformSprite.shuttle(w, id: pid, vertical: false)
        XCTAssertEqual(w.active.sprite(id: pid).map { [$0.vx, Int32($0.counterA6)] }, [1359, 1])
    }

    func testShuttleNoClampOvershoot() throws {
        // L2 record 3: type 1400, p1 1 (vertical), p2 200, p3 1400 at (1338, 202). Speed 1400 is no multiple of
        // 16 (>> 4 = 87): vy steps past ±1400 with no clamp after the step (Invariant 7).
        let (w, solver, ids) = try world(level: 2, records: [3])
        let id = ids[0]
        var vys: [Int32] = []
        var dirs: [Int16] = []
        for _ in 0..<500 {
            PlatformSprite.handle(world: w, id: id, solver: solver)
            let p = try XCTUnwrap(w.active.sprite(id: id))
            vys.append(p.vy)
            dirs.append(p.counterA6)
        }
        let p = try XCTUnwrap(w.active.sprite(id: id))
        XCTAssertEqual(p.classWord150, 202 * 256 + 1400 * 8)
        XCTAssertEqual(p.classWord154, 202 * 256 + 200 * 256 - 1400 * 8)
        XCTAssertEqual(p.sag, 0)                                        // mode 1 clears the sag
        XCTAssertEqual(vys.first, 1400)
        XCTAssertEqual(vys.min(), -1471)                                // 1400 − 33·87: −1384 > −1400 steps once more
        XCTAssertEqual(vys.max(), 1400)                                 // −1471 + 33·87
        XCTAssertTrue(vys.contains(-1384))
        XCTAssertEqual(Set(dirs), [1, -1])
        XCTAssertEqual(p.vx, 0)

        // The raft (mode 3; L2 record 4: type 1408 at (1776, 533)): rect (6, 5, 0x4c, 0x1e), buoyancy 0x50,
        // gravity 0x15e only when dry last frame, sag 0x2d, mass 0x3c; `+0x88 = 0`, `+0x89 = 1`; friction 100.
        let (rw, rs, rids) = try world(level: 2, records: [4])
        let raft = rids[0]
        PlatformSprite.handle(world: rw, id: raft, solver: rs)
        var r = try XCTUnwrap(rw.active.sprite(id: raft))
        XCTAssertEqual(r.hotRect, IdleSprites.Rect(top: 5, left: 6, bottom: 0x1e, right: 0x4c))
        XCTAssertEqual([r.buoyancy, r.gravity, r.sag, r.pushMass, r.counterA6], [0x50, 0x15e, 0x2d, 0x3c, 0])
        XCTAssertFalse(r.lightOverlay)
        XCTAssertTrue(r.dynamicLight)
        XCTAssertEqual(r.face, FaceRef(pict: 1400, index: 8, set: .encoded))
        // Dry last frame: vy += 0x15e (350); the tile pass finds the pool (row 17, surface 544) and floats it:
        // target 527 above y 534 → buoyancy −0x50 → 270, rising → (int)(270·0.93) = 251.
        XCTAssertEqual(r.vy, 251)
        XCTAssertEqual(r.waterRow, 544 - 534)
        // Tilt toward a rider 30 px right of the centre: target −6, eased by 2 per frame (−2, −4, −6, −6).
        let rider = try XCTUnwrap(rw.newSprite(type: 1, x: 0, y: 0, layer: 10, handler: .inert))
        var rot: [Int16] = []
        for _ in 0..<4 {
            let cx = try XCTUnwrap(rw.active.sprite(id: raft)).centre.x
            rw.active.update(id: rider) { $0.centre.x = cx + 30 }
            rw.active.update(id: raft) { c in
                c.ridingLatch = true
                c.rider = rider
            }
            PlatformSprite.handle(world: rw, id: raft, solver: rs)
            r = try XCTUnwrap(rw.active.sprite(id: raft))
            rot.append(r.rotation)
            XCTAssertFalse(r.ridingLatch)                               // cleared with a rider
        }
        XCTAssertEqual(rot, [358, 356, 354, 354])
        // Back without a rider: the target 0, −6 → −4 → −2 → 0 → 0.
        for want: Int16 in [356, 358, 0, 0] {
            PlatformSprite.handle(world: rw, id: raft, solver: rs)
            XCTAssertEqual(try XCTUnwrap(rw.active.sprite(id: raft)).rotation, want)
        }
        // Afloat: `.HandleUnderWater` → `.HandleFlotation` through `.HitPlatformTileSprite`, no gravity in water.
        for _ in 0..<300 { PlatformSprite.handle(world: rw, id: raft, solver: rs) }
        r = try XCTUnwrap(rw.active.sprite(id: raft))
        XCTAssertNotEqual(r.lastWater, 0)
        XCTAssertEqual(r.y, 544 - 17)                                   // surface 544 − (5 + (0x1e − 5) >> 1)

        // The mode-0xb question (W1 precondition): the raft pools' light bytes. `.GetLightTile` at the floating
        // raft's centre is 0 (BG high byte 1), never −1, so `+0xb8 = 0xc0000 + 0·0x100 + F` — mode 0xc, not 0xb.
        let L2 = rw.level
        XCTAssertEqual(L2.lightByte(col: (1776 + 41) >> 5, row: 544 >> 5), 0)
        XCTAssertEqual(L2.lightByte(col: (1580 + 41) >> 5, row: 544 >> 5), 0)
        XCTAssertEqual(L2.lightByte(col: (3562 + 41) >> 5, row: 1504 >> 5), 0)
        // `.GetFakeLight`: the sphere 1335 (record 147, light 810 72×72 at (3603, 1481), colour 99) over the raft of
        // record 154 afloat at (3562, 1487), face bounds (0, 0, 41, 80): v = 11 − (26·11)/36 = 4 → 103.
        let sphere = SetupFaces.Light(pict: 810, width: 72, height: 72, x: 3603, y: 1481, colour: 99)
        let bounds = IdleSprites.Rect(top: 0, left: 0, bottom: 41, right: 80)
        func F(_ x: Int, _ y: Int, _ l: [SetupFaces.Light] = [sphere]) -> Int {
            FerazelSession.fakeLight(x: x, y: y, width: 80, height: 41, faceBounds: bounds, lights: l)
        }
        XCTAssertEqual(F(3562, 1487), 103)
        XCTAssertEqual(F(3562, 1496), 103 - 3)                          // py 1516 (last row in): d 35 → v 1
        XCTAssertEqual(F(3562, 1497), 0)                                // py 1517: outside (half-open)
        XCTAssertEqual(F(3563, 1461), 110)                              // the centre: v = 11 → the next slab
        XCTAssertEqual(F(3527, 1425), 0)                                // corner (3567, 1445): v = 11 − 14 < 0
        XCTAssertEqual(F(3526, 1461), 0)                                // px 3566: left of the rect
        let small = SetupFaces.Light(pict: 822, width: 64, height: 64, x: 3603, y: 1481, colour: 99)
        XCTAssertEqual(F(3562, 1487, [small]), 0)                       // radius 32: not > 0x20
        XCTAssertEqual(F(3562, 1487, [small, sphere]), 103)             // the first light that passes, in slot order
        var slot = SpriteSlot(type: 1408, x: 3562, y: 1487, face: FaceRef(pict: 1400, index: 8, set: .encoded))
        slot.centre = SpriteSlot.Point(x: 3603, y: 1504)
        slot.dynamicLight = true
        let lit = FerazelSession.dynamicLight(slot, level: L2, lights: [sphere], bounds: { _ in bounds },
                                              frame: { _ in bounds })
        XCTAssertEqual(lit.lightTile, 0)
        XCTAssertEqual(lit.fakeLight, 103)
        XCTAssertEqual(slot.applyDynamicLight(lightTile: lit.lightTile, fakeLight: lit.fakeLight), 0xc0067)
        XCTAssertEqual(FerazelSession.peDistance(-26, 1), 26)
        XCTAssertEqual(FerazelSession.peDistance(9, -12), 15)           // 12 + 9/3
        // Through the session's `.WrapDrawSprites` light closure (no level-2 session yet): on level 1 a platform given
        // the raft's `+0x89` and face 1400 [8], set against level 1's sphere 1335 (light 810 at (1969, 774), colour 99)
        // as record 154's raft lies against level 2's (offset (−1634, −707)): F = 103, L = BG (61, 24)'s light byte 9.
        let s1 = try session()
        _ = s1.step(keys: KeyState())
        let lit1 = try platform(s1, record: 25)
        s1.world.active.update(id: lit1) { c in
            c.face = FaceRef(pict: 1400, index: 8, set: .encoded)
            c.dynamicLight = true
            c.x = 3562 - 1634
            c.y = 1487 - 707
            c.centre = SpriteSlot.Point(x: 3603 - 1634, y: 1504 - 707)
            c.mode = 0
        }
        XCTAssertEqual(s1.lights.first { $0.pict == 810 }, SetupFaces.Light(pict: 810, width: 72, height: 72, x: 1969,
                                                                           y: 774, colour: 99))
        let L1 = s1.level.lightByte(col: (3603 - 1634) >> 5, row: (1504 - 707) >> 5)
        _ = s1.step(keys: KeyState())
        XCTAssertEqual(L1, 9)
        XCTAssertEqual(s1.active.record(id: lit1)?.mode, 0xc0967)           // 0xc0000 + 9·0x100 + 103
    }

    func testMode2SpringBackTrace() throws {
        // Mode 2's vertical spring-back to the record y (raw `10064bb8..10064c50`): (y256 − home·256, vy) per frame
        // from vy 320 at home — below: vy > 0 halves (≤ 0x80 → −0x80), else −0x40 down to −0x180; equal: nothing;
        // above: y snapped home with vy kept.
        let (w, solver, ids) = try world(level: 1, records: [25])
        let id = ids[0]
        PlatformSprite.handle(world: w, id: id, solver: solver)
        let home = Int32(972) << 8
        w.active.update(id: id) { c in
            c.y256 = home
            c.vy = 320
        }
        var trace: [[Int32]] = []
        for _ in 0..<6 {
            PlatformSprite.handle(world: w, id: id, solver: solver)
            let p = try XCTUnwrap(w.active.sprite(id: id))
            trace.append([p.y256 - home, p.vy])
        }
        XCTAssertEqual(trace, [[320, 160], [480, -128], [352, -192], [160, -192], [0, -192], [0, -192]])
        // From the rest: vy −0x17f steps to −0x1bf (> −0x180 → −0x40), −0x180 stays (not > −0x180).
        for (v0, v1) in [(Int32(-0x17f), Int32(-0x1bf)), (-0x180, -0x180), (0x81, -0x80), (0x100, -0x80), (0x102, 0x81)] {
            w.active.update(id: id) { c in
                c.y256 = home + 0x100 - v0
                c.vy = v0
            }
            PlatformSprite.handle(world: w, id: id, solver: solver)
            let p = try XCTUnwrap(w.active.sprite(id: id))
            XCTAssertEqual(p.vy, v1, "vy \(v0)")
            XCTAssertEqual(p.y256, home + 0x100)
        }

        // The other record-driven modes, transcribed as read (none on levels 1–2), on a second platform set up by hand
        // beside record 25 (`+0x17c` set, so no `.DoSetupPlatformSprite`).
        let base = try XCTUnwrap(w.active.sprite(id: id))
        func make(_ mode: Int16, _ body: (inout SpriteSlot) -> Void) throws -> Int {
            let n = try XCTUnwrap(w.newSprite(type: 1400, x: base.x, y: base.y - 200, layer: -1, handler: .platform,
                                              record: 25) { PlatformSprite.setup(&$0) })
            w.active.update(id: n) { c in
                c.setupDone = true
                c.subtype = mode
                c.hotRect = PlatformSprite.defaultRect
                body(&c)
            }
            return n
        }
        // Mode 52, blinking (on-time 3, cycle 40, from phase 0): `+0x46` stays 0 while `+0xa6` < 3, then climbs to 0x14.
        let blink = try make(0x34) { c in
            c.counterA6 = 0                                              // `+0xa6 = p4` (the phase)
            c.classWord150 = 3
            c.classWord154 = 40
        }
        var stages: [[Int]] = []
        for _ in 0..<44 {
            PlatformSprite.handle(world: w, id: blink, solver: solver)
            let c = try XCTUnwrap(w.active.sprite(id: blink))
            stages.append([Int(c.counterA6), Int(c.phase), Int(c.mode), c.lightOverlay ? 1 : 0, c.clip.bottom,
                           c.hotRect.right])
        }
        XCTAssertEqual(stages[1], [2, 0, 0, 1, 32000, 0x3d])
        XCTAssertEqual(stages[2], [3, 1, 0, 1, 32000, 0x3d])
        XCTAssertEqual(stages[4], [5, 3, 0, 1, 32000, 0x3d])            // > 2: effect 0, overlay
        XCTAssertEqual(stages[8], [9, 7, 0xb0001, 0, 32000, 0x3d])     // > 6
        XCTAssertEqual(stages[12], [13, 11, 0xb0000, 0, 32000, 0x3d])  // > 10
        XCTAssertEqual(stages[16], [17, 15, 0xb0002, 0, 32000, 0x3d])  // > 14
        XCTAssertEqual(stages[19], [20, 18, 0xb0002, 0, 32000, 0x3d])
        XCTAssertEqual(stages[20], [21, 19, 0xb0002, 0, 0, 0])          // ≥ 0x13: intangible, clipped away
        XCTAssertEqual(stages[22], [23, 20, 0xb0002, 0, 0, 0])
        XCTAssertEqual(stages[39], [40, 20, 0xb0002, 0, 0, 0])
        XCTAssertEqual(stages[40], [0, 19, 0xb0002, 0, 0, 0])           // past the cycle: `+0xa6` 0, falling
        XCTAssertEqual(stages[41], [1, 18, 0xb0002, 0, 32000, 0x3d])
        // Mode 51, crumbling (2 ridden frames, gone time 0x2d, record 25's p4 = 0 → `.STPlay3DSoundRand`).
        let crumble = try make(0x33) { c in
            c.subState = 10
            c.counterA6 = 2
            c.classTimer = 2
            c.classWord150 = 0x2d
        }
        w.player.cues = []
        var seen: [[Int]] = []
        for k in 0..<70 {
            if k < 2 { w.active.update(id: crumble) { $0.ridingLatch = true } }
            PlatformSprite.handle(world: w, id: crumble, solver: solver)
            let c = try XCTUnwrap(w.active.sprite(id: crumble))
            seen.append([Int(c.subState), Int(c.counterA6), Int(c.phase), Int(c.mode), c.lightOverlay ? 1 : 0,
                         c.clip.bottom, c.hotRect.right])
        }
        XCTAssertEqual(seen[0], [10, 1, 0, 0, 1, 32000, 0x3d])
        XCTAssertEqual(seen[1], [10, 0, 1, 0, 1, 32000, 0x3d])          // the break-up starts: the sound
        XCTAssertEqual(w.player.cues.map(\.snd), [461])
        XCTAssertEqual(w.player.cues.first?.call, .threeDRand)
        XCTAssertEqual(w.player.cues.first?.volume, 0xab)
        XCTAssertNotNil(w.player.cues.first?.rate)
        XCTAssertEqual(seen[3], [10, 0, 3, 0, 0, 32000, 0x3d])          // > 2: no overlay
        XCTAssertEqual(seen[7], [10, 0, 7, 0xb0001, 0, 32000, 0x3d])
        XCTAssertEqual(seen[11], [10, 0, 11, 0xb0000, 0, 32000, 0x3d])
        XCTAssertEqual(seen[15], [10, 0, 15, 0xb0002, 0, 32000, 0x3d])
        XCTAssertEqual(seen[18], [10, 0, 18, 0xb0002, 0, 32000, 0x3d])
        XCTAssertEqual(seen[19], [10, 0, 19, 0xb0002, 0, 0, 0])          // > 0x12: gone
        XCTAssertEqual(seen[45], [10, 0, 45, 0xb0002, 0, 0, 0])
        XCTAssertEqual(seen[46], [0xb, 0, 0, 0xb0002, 0, 0, 0])          // past the gone time (> 0x2d): re-form
        XCTAssertEqual(seen[47], [0xb, 0, 1, 0xb0002, 0, 32000, 0x3d])
        XCTAssertEqual(seen[51], [0xb, 0, 5, 0xb0002, 0, 32000, 0x3d])
        XCTAssertEqual(seen[55], [0xb, 0, 9, 0xb0000, 0, 32000, 0x3d])
        XCTAssertEqual(seen[59], [10, 2, 0, 0, 1, 32000, 0x3d])           // > 0xc: re-armed with `+0x14c`
        // Mode 50, sinking (2 ridden frames, depth 3 px below home): gravity ramps +0x1e, the return at −0x32 / frame.
        let sink = try make(0x32) { c in
            c.subState = 10
            c.counterA6 = 2
            c.classTimer = 2
            c.classWord150 = 3
            c.classWord15c = Int32(c.y)
        }
        let top = try XCTUnwrap(w.active.sprite(id: sink)).y
        var g: [[Int]] = []
        for k in 0..<40 {
            if k < 2 { w.active.update(id: sink) { $0.ridingLatch = true } }
            PlatformSprite.handle(world: w, id: sink, solver: solver)
            let c = try XCTUnwrap(w.active.sprite(id: sink))
            g.append([Int(c.subState), Int(c.counterA6), Int(c.gravity), Int(c.vy), c.y - top])
        }
        XCTAssertEqual(g[0], [10, 1, 0, 0, 0])
        XCTAssertEqual(Array(g[1...3].map { $0[2] }), [0x1e, 0x3c, 0x5a])
        let back = try XCTUnwrap(g.firstIndex { $0[0] == 0xb })
        XCTAssertGreaterThan(g[back][4], 3)
        XCTAssertEqual(g[back + 1][2], 0)
        let rearmed = try XCTUnwrap(g.indices.first { $0 > back && g[$0][0] == 10 })
        XCTAssertEqual(g[rearmed][1], 2)
        XCTAssertEqual(Array(g[rearmed][2...3]), [0, 0])
        XCTAssertLessThanOrEqual(g[rearmed][4], 0)

        // Mode 4, a spell floe's lifetime (`+0xa6`, l. 55738–55760): counts down; below 0x2d the ice face with effect 0
        // or 0xb0000 by the frame parity `_DAT_1009fd30`; at 0 `+0xe9` (and `.ExplodeFaceIntoParticles`, E1a — no face provider here, so no particles).
        let floe = try make(4) { c in
            c.counterA6 = 0x2e
            c.mode = 0x10018
        }
        var life: [[Int]] = []
        for k in 0..<4 {
            w.parity = k % 2 == 1
            PlatformSprite.handle(world: w, id: floe, solver: solver)
            let c = try XCTUnwrap(w.active.sprite(id: floe))
            life.append([Int(c.counterA6), Int(c.mode), c.face?.pict == 0x2c7 ? 1 : 0, c.dead ? 1 : 0])
        }
        XCTAssertEqual(life, [[0x2d, 0x10018, 0, 0], [0x2c, 0xb0000, 1, 0], [0x2b, 0, 1, 0], [0x2a, 0xb0000, 1, 0]])
        w.active.update(id: floe) { $0.counterA6 = 1 }
        PlatformSprite.handle(world: w, id: floe, solver: solver)
        XCTAssertTrue(try XCTUnwrap(w.active.record(id: floe)).dead)
        PlatformSprite.handle(world: w, id: floe, solver: solver)          // `+0xe9`: the Handle returns at once
        XCTAssertEqual(w.active.record(id: floe)?.counterA6, 0)
        w.parity = false

        // `.HitPlatformSprite` (l. 55790–55838): a Platform-handled other → `.PlatformBounce(self, other, own centre,
        // 0, own rect, 0)`, the platform the mover — but not two rafts/floes, nor two catapult parts; anything else nil.
        let lower = try make(2) { $0.counterA6 = 1 }
        let upper = try make(2) { $0.counterA6 = 1 }
        func stack(_ vy: Int32) {
            let lo = w.active.sprite(id: lower)!
            w.active.update(id: upper) { c in
                c.x = lo.x
                c.y = lo.y - 0x18 + 2
                c.x256 = Int32(c.x) << 8
                c.y256 = Int32(c.y) << 8
                c.vy = vy
                c.ridden = nil
                c.classWord154 = 0
            }
            w.active.update(id: lower) { c in
                c.rider = nil
                c.ridingLatch = false
            }
        }
        stack(0x100)
        PlatformSprite.hit(w, id: upper, other: lower)
        XCTAssertEqual(w.active.sprite(id: upper)?.ridden, lower)
        XCTAssertEqual(w.active.sprite(id: lower)?.rider, upper)
        XCTAssertEqual(w.active.sprite(id: upper)?.vy, 0)
        for (a, b) in [(Int16(3), Int16(4)), (4, 3), (0x582, 0x585), (0x584, 0x583)] {
            stack(0x100)
            w.active.update(id: upper) { $0.subtype = a }
            w.active.update(id: lower) { $0.subtype = b }
            PlatformSprite.hit(w, id: upper, other: lower)
            XCTAssertNil(w.active.sprite(id: upper)?.ridden, "\(a) on \(b)")
        }
        stack(0x100)
        w.active.update(id: upper) { $0.subtype = 3 }
        w.active.update(id: lower) { $0.subtype = 2 }
        PlatformSprite.hit(w, id: upper, other: lower)
        XCTAssertEqual(w.active.sprite(id: upper)?.ridden, lower)       // a raft on a shuttle bounces
        // A springboard bounces with `+0x154` as its vy, swapped back after.
        stack(7)
        w.active.update(id: upper) { c in
            c.subtype = PlatformSprite.springboard
            c.classWord154 = 0x100
        }
        PlatformSprite.hit(w, id: upper, other: lower)
        XCTAssertEqual(w.active.sprite(id: upper)?.ridden, lower)
        XCTAssertEqual(w.active.sprite(id: upper)?.vy, 7)
        XCTAssertEqual(w.active.sprite(id: upper)?.classWord154, 0)
        stack(0x100)
        w.active.update(id: upper) { $0.subtype = 2 }
        w.active.update(id: lower) { $0.handler = .box }
        PlatformSprite.hit(w, id: upper, other: lower)
        XCTAssertNil(w.active.sprite(id: upper)?.ridden)                 // not a Platform: nothing
        w.active.update(id: lower) { $0.handler = .platform; $0.handleCleared = true }
        PlatformSprite.hit(w, id: upper, other: lower)
        XCTAssertNil(w.active.sprite(id: upper)?.ridden)                 // an idled record has `+0x4c = 0`
    }

    func testMode10RotorL1Rec57() throws {
        // L1 record 57: type 1401, p1 10, p2 60 (radius), p3 500 (speed), p4 0 at (2288, 1035): hub (2328, 1055).
        let s = try session()
        let id = try platform(s, record: 57)
        var pos: [[Int]] = []
        var angles: [Int32] = []
        for _ in 0..<185 {
            _ = s.step(keys: KeyState())
            let p = try XCTUnwrap(s.active.sprite(id: id))
            pos.append([p.x, p.y])
            angles.append(try XCTUnwrap(p.radial).angle)
            if pos.count == 2 {
                // The spokes after frame 2 (a = 3: dx 59, dy −4; n = 60/14 = 4, size 16): entry j at the hub +
                // (d·j)/4 − 8; each faced 1433 [a/6] by its own Handle the next frame.
                let b = try XCTUnwrap(p.radial)
                XCTAssertEqual(b.spokeCount, 4)
                let at = try b.spokes.map { sp -> [Int] in
                    let c = try XCTUnwrap(s.active.sprite(id: try XCTUnwrap(sp)))
                    return [c.x, c.y, Int(c.subtype), Int(c.layer)]
                }
                XCTAssertEqual(at, [[2320, 1047, 3, -2], [2334, 1046, 3, -2], [2349, 1045, 3, -2], [2364, 1044, 3, -2]])
            }
        }
        // Frame 1 places it against the `.InitSprite` centre (0, 0): the first-frame radial position (Invariant 7).
        XCTAssertEqual(pos[0], [2328 + 59 + 2288, 1055 - 2 + 1035])
        XCTAssertEqual(Array(pos[1...3]), [[2349, 1033], [2349, 1031], [2349, 1029]])
        let p = try XCTUnwrap(s.active.sprite(id: id))
        let b = try XCTUnwrap(p.radial)
        XCTAssertEqual([b.hubX, b.hubY, b.radius, b.speed], [2328 << 8, 1055 << 8, 60 << 8, 500])
        XCTAssertEqual([b.gravity, b.damp, Int16(b.hubDamp)], [0, 0, 0])
        XCTAssertFalse(p.hasTileHit)                                     // `+0x1f8 = 0`
        XCTAssertEqual([p.vx, p.vy], [0, 0])
        // 0x16800 / 500 = 184.3 frames per turn: the angle wraps on frame 185.
        XCTAssertEqual(angles[183], 184 * 500)
        XCTAssertEqual(angles[184], 185 * 500 - 0x16800)
        XCTAssertEqual(Double(0x16800) / 500, 184.32)
        // The chain Handle faced each spoke from its angle (frame 185's Handles saw frame 184's a = 359 → 1433 [59]).
        let sp = try XCTUnwrap(s.active.sprite(id: try XCTUnwrap(b.spokes[0])))
        XCTAssertEqual(sp.face, FaceRef(pict: 0x599, index: 59, set: .encoded))
        XCTAssertTrue(sp.lightOverlay)
        // `.HandleChainSprite`'s face index (signed /6; < 0 → 59, ≥ 60 → 0).
        let w = s.world
        for (angle, index) in [(Int16(0), 0), (5, 0), (6, 1), (359, 59), (360, 0), (-1, 0), (-6, 59)] {
            w.active.update(id: sp.id) { $0.subtype = angle }
            ChainSprite.handle(world: w, id: sp.id)
            XCTAssertEqual(w.active.sprite(id: sp.id)?.face?.index, index, "angle \(angle)")
        }
    }

    func testMode11PendulumL1Rec14() throws {
        // L1 record 14: type 1402, p1 11, p2 180, p3 0, p4 0 — the pull 0x1e toward 270°, undamped: a triangle wave.
        let s = try session()
        let id = try platform(s, record: 14)
        var speeds: [Int32] = []
        for _ in 0..<320 {
            _ = s.step(keys: KeyState())
            speeds.append(try XCTUnwrap(s.active.sprite(id: id)?.radial).speed)
        }
        XCTAssertEqual(Array(speeds.prefix(3)), [-30, -60, -90])
        // The sign bit of the speed changes on frames 78 (−30 → 0) and 157 (0 → −30); zero on 78 and 156.
        var flips: [Int] = []
        for i in 1..<speeds.count where (speeds[i] < 0) != (speeds[i - 1] < 0) { flips.append(i + 1) }
        XCTAssertEqual(Array(flips.prefix(2)), [78, 157])
        XCTAssertEqual(speeds[77], 0)
        XCTAssertEqual(speeds[155], 0)
        XCTAssertEqual(speeds.min(), -1170)                              // the bottom (270°) passed on frame 39
        XCTAssertEqual(speeds[38], -1170)
        XCTAssertEqual(speeds[39], -1140)
        let b = try XCTUnwrap(s.active.sprite(id: id)?.radial)
        XCTAssertEqual([b.gravity, b.damp], [0x1e, 0])
        XCTAssertEqual(b.spokeCount, 12)                                // 180 / 14
    }

    func testWheelRiddenStep() throws {
        // L1 record 21: type 1403, p1 20, p2 60: the three-wheel P, S1, S2 (0°, 120°, 240°), damping 0xf7, hub 0xf7.
        // On the real map the first Handle frame places each member against its `.InitSprite` centre (0, 0) — about
        // 1900 px right of the hub (the first-frame radial position, Invariant 7) — where P's tile pass meets a wall:
        // `.HitPlatformTileSprite` bounces the wheel at once (speed +0x100, the hub rolling −0x100, cooldown −5).
        let s = try session()
        let real = try platform(s, record: 21)
        _ = s.step(keys: KeyState())
        let r1 = try XCTUnwrap(s.active.sprite(id: real))
        XCTAssertEqual([r1.radial?.speed, r1.radial?.hubVX, r1.radial?.angle], [0x100, -0x100, 0])
        XCTAssertEqual([r1.counterA6, r1.subState], [-5, 1])
        XCTAssertTrue(r1.radialLatch)
        XCTAssertEqual([r1.x, r1.y], [(1849 + 0x28) + 60 + 1849, (519 + 0x14) + 0 + 519])
        let rs1 = try XCTUnwrap(s.active.sprite(id: try XCTUnwrap(r1.siblings.first)))
        XCTAssertEqual(rs1.radial?.speed, 247)                           // bounced 0 → +0x100, then damped
        XCTAssertEqual([rs1.counterA6, rs1.subState], [-4, 0])
        _ = s.step(keys: KeyState())
        let r2 = try XCTUnwrap(s.active.sprite(id: real))
        XCTAssertEqual([r2.x, r2.y], [1910, 521])                       // back on the circle (centre now stored)
        XCTAssertEqual([r2.radial?.speed, r2.radial?.angle], [247, 247])
        XCTAssertEqual(r2.counterA6, -4)

        // From rest (the same records on a map with no tiles, so no first-frame bounce): ridden (the latch the
        // previous collision pass set), the driver steps by mod(0°) = −90 and damps to −87.
        let (w, _, ids) = try world(level: 1, records: [21])
        let empty = TileMap(width: 200, height: 50, cells: Array(repeating: 0, count: 200 * 50))
        w.tiles = TileGrid(fg: empty, bg: empty, fgKinds: w.tiles.fgKinds, bgKinds: w.tiles.bgKinds)
        let solver = TileSolver(world: w)
        func frame() {
            w.handleSprites { w, id in
                switch w.active.record(id: id)?.handler {
                case .platform?: PlatformSprite.handle(world: w, id: id, solver: solver)
                case .chain?: ChainSprite.handle(world: w, id: id)
                default: break
                }
            }
        }
        let id = ids[0]
        frame()
        let p0 = try XCTUnwrap(w.active.sprite(id: id))
        let s1 = try XCTUnwrap(p0.siblings.first), s2 = try XCTUnwrap(p0.siblings.second)
        XCTAssertEqual(w.active.sprite(id: s1)?.siblings, SpriteSlot.Siblings(first: s2, second: id))
        XCTAssertEqual(w.active.sprite(id: s2)?.siblings, SpriteSlot.Siblings(first: id, second: s1))
        XCTAssertEqual(w.active.sprite(id: s1)?.radial?.angle, 120 << 8)
        XCTAssertEqual(w.active.sprite(id: s2)?.radial?.angle, 240 << 8)
        XCTAssertEqual(p0.radial?.speed, 0)
        XCTAssertEqual(p0.radial?.hubDamp, 0xf7)
        XCTAssertEqual(w.active.sprites.filter { $0.handler == .chain }.count, 15)   // 60/12 × 3
        let hub = (1849 + 0x28) << 8
        w.active.update(id: id) { $0.ridingLatch = true }
        frame()
        let p = try XCTUnwrap(w.active.sprite(id: id))
        let pb = try XCTUnwrap(p.radial)
        XCTAssertEqual(pb.speed, -87)
        XCTAssertEqual(pb.angle, 92073)                                 // 0 − 87 + 0x16800
        XCTAssertEqual(pb.hubVX, 86)                                    // −(−90) rolled, then ×0xf7 >> 8
        XCTAssertEqual(pb.hubX, Int32(hub + 90))
        XCTAssertEqual(p.subState, 1)
        XCTAssertFalse(p.ridingLatch)
        // S1 and S2 follow the driver in the list: slaved (angle + 0x7800 / 0xf000, speed, hub position), then their
        // own step on the copy — one frame ahead.
        let b1 = try XCTUnwrap(w.active.sprite(id: s1)?.radial), b2 = try XCTUnwrap(w.active.sprite(id: s2)?.radial)
        XCTAssertEqual(b1.angle, 30549)
        XCTAssertEqual(b2.angle, 61269)
        XCTAssertEqual([b1.speed, b2.speed], [-84, -84])
        XCTAssertEqual([b1.hubX, b2.hubX], [Int32(hub + 90), Int32(hub + 90)])
        XCTAssertEqual([b1.hubVX, b2.hubVX], [0, 0])                    // the hub velocity is not copied
        XCTAssertEqual(w.active.sprite(id: s1)?.subState, 0)
        // `.HitPlatformTileSprite` on a wall (FG, layer 1): position restored, the bounce once per frame, cooldown −5
        // on all three, and the `+0xb2 = 0` meant for S2 lands on `+0x1d4` = S1 (the source bug, kept).
        w.active.update(id: s2) { $0.subState = 1 }
        let before = try XCTUnwrap(w.active.sprite(id: id))
        let cell = TilePos(x: before.x + 16, y: before.y + 6)
        let kind = try XCTUnwrap((0..<0x30).first { k in
            var probe = cell
            let save = w.active.sprite(id: id)
            defer { if let save { w.active.update(id: id) { $0 = save } } }
            return solver.wallBounce(id, kind: k, tile: &probe, vCentre: 0, factor: 0x80, rect: before.hotRect,
                                     bounce: true)
        }, "a kind that hits")
        PlatformSprite.hitTile(solver, id: id, pos: cell, kind: kind, layer: .foreground)
        let h = try XCTUnwrap(w.active.sprite(id: id))
        XCTAssertEqual([h.x256, h.y256], [before.x256, before.y256])
        XCTAssertEqual([h.x, h.y], [before.x, before.y])
        XCTAssertTrue(h.radialLatch)
        XCTAssertEqual(h.counterA6, -5)
        XCTAssertEqual(h.subState, 1)
        XCTAssertEqual(w.active.sprite(id: s1)?.counterA6, -5)
        XCTAssertEqual(w.active.sprite(id: s2)?.counterA6, -5)
        XCTAssertEqual(w.active.sprite(id: s1)?.subState, 0)
        XCTAssertEqual(w.active.sprite(id: s2)?.subState, 1)            // never written: the bug
        // `.BounceRadial`: speed (int)(−87·−0.75) = 65 → raised to 0x100; hvx 86 → −64 → −0x100; the side by the
        // centre against the tile centre x (cell.x + 16).
        // P's centre (x + 38) is right of the tile centre (cell.x + 16 = x + 32): speed −|·|, hvx +|·|.
        XCTAssertEqual(before.centre.x, before.x + 38)
        XCTAssertEqual(h.radial?.speed, -0x100)
        XCTAssertEqual(h.radial?.hubVX, 0x100)
        // S1: in this one-platform world it was made after the walk's saved `next` (none), so its first Handle ran on
        // frame 2 and its stored centre is that frame's first-frame position (3708 + 38) — right of the tile centre:
        // −84 → 63 → 0x100 → −|·|; its hvx 0 → 0 → raised to +0x100 → +|·|.
        let s1c = try XCTUnwrap(w.active.sprite(id: s1))
        XCTAssertEqual(s1c.centre.x, (1849 + 0x28) - 30 + 1849 + 38)
        XCTAssertEqual(s1c.radial?.speed, -0x100)
        XCTAssertEqual(s1c.radial?.hubVX, 0x100)
        XCTAssertEqual(s1c.radial?.hubVY, 0)
        // The latch: a second wall this frame bounces nothing — with the cooldown cleared, so the latch alone holds.
        w.active.update(id: id) { $0.counterA6 = 0 }
        PlatformSprite.hitTile(solver, id: id, pos: cell, kind: kind, layer: .foreground)
        XCTAssertEqual(w.active.sprite(id: id)?.radial?.speed, h.radial?.speed)
        XCTAssertEqual(w.active.sprite(id: id)?.counterA6, 0)
        XCTAssertEqual(w.active.sprite(id: id)?.radial?.hubVX, h.radial?.hubVX)
        // The tile centre is pos.x + 0x10: with P's stored centre at pos.x + 8 (left of it) the bounce turns + (speed
        // −0x100 → 192 → +0x100).
        w.active.update(id: id) { c in
            c.radialLatch = false
            c.centre.x = cell.x + 8
        }
        PlatformSprite.hitTile(solver, id: id, pos: cell, kind: kind, layer: .foreground)
        XCTAssertEqual(w.active.sprite(id: id)?.radial?.speed, 0x100)
        XCTAssertEqual(w.active.sprite(id: id)?.counterA6, -5)
        // `.BounceRadial` arithmetic on literal values (l. 54333–54409).
        w.active.update(id: id) { c in
            c.radial?.speed = 1000
            c.radial?.hubVX = -1000
            c.radial?.hubVY = 1001
            c.centre.x = 100
        }
        RadialMotion.bounce(w, id: id, tileCentreX: 100)                // centre ≤ tile: speed +, hvx −
        XCTAssertEqual(w.active.sprite(id: id)?.radial.map { [$0.speed, $0.hubVX, $0.hubVY] }, [750, -750, -750])
        RadialMotion.bounce(w, id: id, tileCentreX: 99)                 // centre > tile: speed −, hvx +
        XCTAssertEqual(w.active.sprite(id: id)?.radial.map { [$0.speed, $0.hubVX, $0.hubVY] }, [-562, 562, 562])
        w.active.update(id: id) { $0.radial?.speed = 0 }
        RadialMotion.bounce(w, id: id, tileCentreX: 99)
        XCTAssertEqual(w.active.sprite(id: id)?.radial?.speed, -0x100)  // 0 → +0x100, then −|·|
        RadialMotion.bounce(w, id: nil, tileCentreX: 0)                 // s = 0: nothing
    }

    func testSpokeAndSiblingCounts() throws {
        let s = try session()
        // The level start: platforms faceless, no platform spokes yet (made by the first Handle frame). W2a: the 14
        // mace chains 0x59a of the two 1485 pendulums are already there (their Setup makes them) — filtered out below.
        XCTAssertEqual(s.active.sprites.filter { $0.handler == .chain && $0.type == 0x596 }.count, 0)
        XCTAssertEqual(s.active.sprites.filter { $0.handler == .chain && $0.type == 0x59a }.count, 14)
        XCTAssertTrue(s.active.sprites.filter { $0.handler == .platform }.allSatisfy { $0.face == nil })
        XCTAssertEqual(s.active.sprites.filter { $0.handler == .platform }.count, 7)
        _ = s.step(keys: KeyState())
        let list = s.active.sprites
        let chains = list.filter { $0.handler == .chain && $0.type != 0x59a }
        let platforms = list.filter { $0.handler == .platform }
        // 180/14 = 12 (record 14) + 3 × 60/12 = 15 (record 21's wheel) + 2 × 60/14 = 8 (records 57, 58).
        XCTAssertEqual(chains.count, 35)
        XCTAssertEqual(platforms.filter { $0.recordIndex == -1 }.count, 2)
        XCTAssertTrue(chains.allSatisfy { $0.layer == -2 && $0.type == 0x596 && !$0.hasHit })
        XCTAssertTrue(chains.allSatisfy { $0.hotRect == IdleSprites.Rect(top: 0, left: 0, bottom: 0x10, right: 0x10) })
        let lastChain = try XCTUnwrap(list.lastIndex { $0.handler == .chain && $0.type == 0x596 })
        let firstPlatform = try XCTUnwrap(list.firstIndex { $0.handler == .platform })
        XCTAssertLessThan(lastChain, firstPlatform)                      // layer −2 before every layer −1
        XCTAssertEqual(lastChain + 1, firstPlatform)
        // Within layer −1: the record platforms in record order, then the siblings at the tail of the group.
        XCTAssertEqual(platforms.map(\.recordIndex), [14, 21, 25, 40, 47, 57, 58, -1, -1])
        XCTAssertTrue(platforms.allSatisfy { $0.layer == -1 && $0.face != nil })
        // Each spoke links back to its platform (`+0x1d4`), with `+0x14c = k`, `+0x150 = n`, `+0x154 = R`.
        let rec14 = try platform(s, record: 14)
        let b = try XCTUnwrap(s.active.sprite(id: rec14)?.radial)
        XCTAssertEqual(b.spokes.count, 12)
        for (j, sp) in b.spokes.enumerated() {
            let c = try XCTUnwrap(s.active.sprite(id: try XCTUnwrap(sp)))
            XCTAssertEqual(c.siblings.first, rec14)
            XCTAssertEqual([c.classTimer, c.classWord150, c.classWord154], [Int32(12 - 1 - j), 12, 180])
            // The 24.8 position is `.MTNewSprite`'s (the platform's pixel copy at creation); the radial writes only
            // the pixel copies.
            XCTAssertEqual([c.x256, c.y256], [3159 << 8, 1021 << 8])
            XCTAssertEqual([c.oldPosition.x, c.oldPosition.y], [3159, 1021])
        }
        // `.MTNewSprite`'s pixel-copy quirk (raw `100331e4..f8`), on the spoke maker's call: `+0xc` = y, `+0xa` = 0
        // until the first writer (`.UpdateRadiusSprites`) repairs them; `+8`/`+6` and the 24.8 position are right.
        let raw = try XCTUnwrap(s.world.newSprite(type: 0x596, x: 2288, y: 1035, layer: -2, handler: .chain,
                                                  setup: ChainSprite.setup))
        let q = try XCTUnwrap(s.active.sprite(id: raw))
        XCTAssertEqual([q.x, q.y], [1035, 0])
        XCTAssertEqual([q.oldPosition.x, q.oldPosition.y], [2288, 1035])
        XCTAssertEqual([q.x256, q.y256], [2288 << 8, 1035 << 8])
        XCTAssertEqual(q.layer, -2)
        XCTAssertEqual(q.handler, .chain)
        XCTAssertNil(q.face)
    }
}
