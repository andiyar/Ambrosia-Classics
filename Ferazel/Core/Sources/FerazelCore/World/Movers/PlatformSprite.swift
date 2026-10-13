import Foundation

/// The Platform class, types 0x578…0x595 (physics-sprites §8.9, platforms-ropes-radial §2, -2 §8–§9; plan W1):
/// `.SetupPlatformSprite @ 10061f94`, the first Handle frame's `.DoSetupPlatformSprite @ 10062098`,
/// `.HandlePlatformSprite @ 100635b4`, `.HitPlatformSprite @ 10064d94` and `.HitPlatformTileSprite @ 10064f04`
/// (decompile l. 54501–55942). Every mode is transcribed as read; levels 1–2 place modes 1, 2, 3, 10, 11 and 20.
public enum PlatformSprite {
    /// The platform face set `LoadEncFaceSetFromPICT(0x578, 10, 0x50, 0x29, 10)` (`.InitPlatformSprite`, l. 54480).
    public static let faceSet: Int16 = 0x578
    /// The floe / wall-ice set 0x2c7 (3 × 40×24), the catapult set 0x582 (7 × 216×200), the springboard singles.
    public static let iceSet: Int16 = 0x2c7
    public static let catapultSet: Int16 = 0x582
    public static let springboard: Int16 = 0x58c
    public static let springboardBase: Int16 = 0x58d
    public static let springboardGauge: Int16 = 0x58e
    /// The spiked-underside type 0x57d and the camera-veto type 0x57a (`Camera.snapVetoRiddenType`).
    public static let spiked: Int16 = 0x57d

    /// The catapult face script `PTR_DAT_100a098c` (`.InitPlatformSprite`, l. 54414–54476): `[0] = 0x13` (the count,
    /// `*(short *)puVar2 = 0x13`), entries 0 … 19 copied from the data at `0x100a6314` (`tools/const.py`).
    static let catapultScriptCount: Int16 = 0x13
    static let catapultScript: [Int16] = [0, 1, 1, 2, 2, 1, 0, 3, 4, 5, 6, 6, 5, 5, 4, 4, 3, 3, 0, 0]

    /// 0.4 (f64 `dRam100a1a70`): the 5/6 and 7/8 shuttles' coast factor.
    static let coast = Double(bitPattern: 0x3fd9_9999_9999_999a)

    /// The default hot rect `SetRect(0x10, 6, 0x3d, 0x1e)`.
    static let defaultRect = IdleSprites.Rect(top: 6, left: 0x10, bottom: 0x1e, right: 0x3d)
    static let emptyRect = IdleSprites.Rect(top: 0, left: 0, bottom: 0, right: 0)

    @inline(__always) static func h(_ v: Int) -> Int { Int(Int16(truncatingIfNeeded: v)) }

    // MARK: - Setup

    /// `.SetupPlatformSprite @ 10061f94` (decompile l. 54501–54537): `.InitSprite`; the Platform Handle, hit
    /// (`.HitPlatformSprite`) and tile (`.HitPlatformTileSprite`) callbacks; `+0x80 = −1`; `+0xc0 = 0` (so the
    /// level-start frame draws **no** platform — the face is `.DoSetupPlatformSprite`'s, on the first Handle frame);
    /// position from the spawn copy (`+0xc ← +8`, `+0xa ← +6`; 24.8 from them); one-way `+0x185 = 1`; `+0x190 = 0`
    /// (dead field, not kept); gravity 0; sag `+0x13a = 0x50`; `+0xa6 = 1` unless type 0x6a4; `+0x188 = 1` (no record
    /// write-back; Core has none); `+0x17c = 0`; empty hot rect. `+0x84`/`+0x86 = 0` have no reader (not kept).
    public static func setup(_ s: inout SpriteSlot) {
        s.handler = .platform
        s.hasHit = true
        s.hasTileHit = true
        s.layer = -1
        s.face = nil
        s.x = s.oldPosition.x
        s.y = s.oldPosition.y
        s.x256 = Int32(Int16(truncatingIfNeeded: s.x)) << 8
        s.y256 = Int32(Int16(truncatingIfNeeded: s.y)) << 8
        s.oneWay = true
        s.gravity = 0
        s.sag = 0x50
        if s.type != 0x6a4 { s.counterA6 = 1 }
        s.setupDone = false
        s.hotRect = emptyRect
    }

    /// The placement record `+0x48` (nil for −1 or outside the table).
    static func record(_ w: SpriteWorld, _ s: SpriteSlot) -> Placement? {
        let i = Int(s.recordIndex)
        guard i >= 0, i < w.level.placements.count else { return nil }
        return w.level.placements[i]
    }

    /// `MTNewSprite(type, x, y, layer, −1, .SetupPlatformSprite)` — a sibling or child.
    @discardableResult
    static func newPlatform(_ w: SpriteWorld, type: Int16, x: Int, y: Int, layer: Int16) -> Int? {
        w.newSprite(type: type, x: x, y: y, layer: layer, handler: .platform) { setup(&$0) }
    }

    /// `.DoSetupPlatformSprite @ 10062098` (decompile l. 54541–55025; platforms-ropes-radial §2.2), the first Handle
    /// frame (`+0x17c == 0`):
    /// - mode `+0xb0` = type for 0x58c, 0x582…0x585; else the record's p1 (record −1: the mode the spawner stored),
    ///   100…199 → −100 with the "full" flag cleared (the radial speed / the wheel hub roll are dropped); face = set
    ///   0x578 index type − 0x578; `+0x14c = p3`.
    /// - rect (0x10, 6, 0x3d, 0x1e); modes 5/6 → 1/2 with sag 0, `+0x15c = 1`; 7/8 → 1/2 with `+0x158 = 1` too.
    /// - the mode arms, as the dump (see each).
    static func doSetup(_ w: SpriteWorld, id: Int) {
        guard var s = w.active.record(id: id) else { return }
        let rec = record(w, s)
        var full = true                                               // `bVar2`
        let t = s.type
        if t == springboard || (0x582...0x585).contains(t) {
            s.subtype = t
        } else {
            if let r = rec { s.subtype = r.p1 }
            if 99 < s.subtype && s.subtype < 200 {
                s.subtype -= 100
                full = false
            }
            s.face = FaceRef(pict: faceSet, index: Int(t) - Int(faceSet), set: .encoded)
            if let r = rec { s.classTimer = Int32(r.p3) }
        }
        s.hotRect = defaultRect
        if s.subtype == 5 || s.subtype == 6 {
            s.sag = 0
            s.classWord15c = 1
            s.subtype -= 4
        }
        if s.subtype == 7 || s.subtype == 8 {
            s.sag = 0
            s.classWord15c = 1
            s.classWord158 = 1
            s.subtype -= 6
        }
        let mode = s.subtype
        let p2 = rec?.p2 ?? 0, p3 = rec?.p3 ?? 0, p4 = rec?.p4 ?? 0
        let cx = Int16(truncatingIfNeeded: s.x + 0x28), cy = Int16(truncatingIfNeeded: s.y + 0x14)
        let put = { (v: SpriteSlot) in w.active.update(id: id) { $0 = v } }

        /// The spokes of a radial member: `p2 / divisor` (C division) × type at `layer`.
        func chains(_ member: Int, _ divisor: Int16) {
            RadialMotion.makeSpokes(w, id: member, count: p2 / divisor, layer: -2, type: ChainSprite.link, size: 0x10,
                                    handler: .chain, setup: ChainSprite.setup)
        }
        func iceEffect(_ members: [Int]) {
            guard t == 0x57c else { return }
            for m in members { RadialMotion.setSpokesEffect(w, id: m, 0x10018) }
        }
        /// `MTNewSprite(type, +0xc, +0xa, 1, −1, Platform)` with `+0xb0` = the mode.
        func sibling() -> Int? {
            let cur = w.active.record(id: id) ?? s
            let n = newPlatform(w, type: t, x: cur.x, y: cur.y, layer: 1)
            if let n { w.active.update(id: n) { $0.subtype = mode } }
            return n
        }

        switch mode {
        case 0x1e:
            // See-saw (l. 54594–54639): a record arm makes the sibling, both radials, the segments 0x59b (layer 0,
            // p2/16, size 0x18), the lever 0 and the limits; the sibling's own first frame sets its limits.
            if rec == nil {
                s.hotRect = emptyRect
                if s.radial != nil {
                    s.radial!.maxDegrees = 0xe1
                    s.radial!.minDegrees = 0x87
                    s.radial!.limitBounce = 0x60
                }
                put(s)
            } else {
                s.counterA6 = 0
                put(s)
                let sib = sibling()
                w.active.update(id: id) { $0.siblings.first = sib }
                if let sib { w.active.update(id: sib) { $0.siblings.first = id } }
                RadialMotion.make(w, id: id, cx: cx, cy: cy, radius: p2, speed: 0, angle: 0, gravity: 0, damp: 0xf7,
                                  hubDamp: 0x100, persp: 0)
                if let sib {
                    RadialMotion.make(w, id: sib, cx: cx, cy: cy, radius: p2, speed: 0, angle: 0xb4, gravity: 0,
                                      damp: 0xf7, hubDamp: 0x100, persp: 0)
                }
                for m in [id] + (sib.map { [$0] } ?? []) {
                    RadialMotion.makeSpokes(w, id: m, count: p2 / 16, layer: 0, type: ChainSprite.seeSawSegment,
                                            size: 0x18, handler: .seeSawSegment,
                                            setup: ChainSprite.setupSeeSawSegment)
                }
                iceEffect([id] + (sib.map { [$0] } ?? []))
                w.active.update(id: id) { c in
                    c.classTimer = Int32(p2)
                    c.classWord150 = 0
                    c.hotRect = emptyRect
                    c.radial?.maxDegrees = 0x2d
                    c.radial?.minDegrees = 0x13b
                    c.radial?.limitBounce = 0x60
                }
            }
        case 3:
            // Raft (l. 54642–54649).
            s.hotRect = IdleSprites.Rect(top: 5, left: 6, bottom: 0x1e, right: 0x4c)
            s.buoyancy = 0x50
            s.gravity = 0x15e
            s.sag = 0x2d
            s.pushMass = 0x3c
            s.counterA6 = 0
            put(s)
        case 1:
            // Vertical shuttle (l. 54652–54664): bounds `+0x150 = y + 8·speed`, `+0x154 = y + 256·p2 − 8·speed`
            // (record only), y += 256·p4, vy = speed, vx = 0, sag 0.
            if rec != nil {
                s.classWord150 = s.y256 &+ s.classTimer &* 8
                s.classWord154 = s.y256 &+ Int32(p2) &* 0x100 &+ s.classTimer &* -8
            }
            s.y256 &+= Int32(p4) &* 0x100
            s.vy = s.classTimer
            s.vx = 0
            s.sag = 0
            put(s)
        case 2:
            // Horizontal shuttle (l. 54665–54677): the same on x; the sag stays 0x50.
            if rec != nil {
                s.classWord150 = s.x256 &+ s.classTimer &* 8
                s.classWord154 = s.x256 &+ Int32(p2) &* 0x100 &+ s.classTimer &* -8
            }
            s.x256 &+= Int32(p4) &* 0x100
            s.vx = s.classTimer
            s.vy = 0
            put(s)
        case 4:
            // Floe / wall ice (l. 54679–54695).
            s.face = FaceRef(pict: iceSet, index: Int(s.classWord16c), set: .encoded)
            if s.classWord16c == 0 {
                s.hotRect = IdleSprites.Rect(top: 0, left: 0, bottom: 0x31, right: 0x28)
                s.gravity = 0x15e
                s.sag = 0x16
                s.buoyancy = 0x3c
                s.floatOffset = 10
            } else {
                s.hotRect = IdleSprites.Rect(top: 3, left: 0, bottom: 0x18, right: 0x28)
                s.gravity = 0
                s.sag = 0
            }
            s.pushMass = 0x3c
            put(s)
        case 10, 11:
            // Single radial platform (l. 54748–54775): record only; `+0xa6 = 0`, no tile callback; speed p3 (0 in the
            // 1xx form), angle p4, pull 0 / 0x1e; chain spokes p2/14.
            put(s)
            guard rec != nil else { break }
            w.active.update(id: id) { c in
                c.counterA6 = 0
                c.hasTileHit = false
            }
            let speed: Int16 = full ? p3 : 0
            RadialMotion.make(w, id: id, cx: cx, cy: cy, radius: p2, speed: speed, angle: p4,
                              gravity: mode == 10 ? 0 : 0x1e, damp: 0, hubDamp: 0, persp: 0)
            chains(id, 14)
            iceEffect([id])
        case 20, 21, 22:
            // Wheels (l. 54697–54746, 54777–54839, 54840–54921): record only; `+0xa6 = 0`; one / two / three
            // siblings (created in order, then linked), the radials at 0/120/240, 0/180, 0/90/180/270 with damping
            // 0xf7 and hub damping 0xf7 (0x100 in the 1xx form: the hub never rolls); chain spokes p2/12 (20) or p2/14.
            put(s)
            guard rec != nil else { break }
            let hubDamp: Int16 = full ? 0xf7 : 0x100
            w.active.update(id: id) { $0.counterA6 = 0 }
            let count = mode == 20 ? 2 : (mode == 21 ? 1 : 3)
            var sibs: [Int?] = []
            for _ in 0..<count { sibs.append(sibling()) }
            let members: [Int?] = [id] + sibs
            func link(_ m: Int?, _ a: Int?, _ b: Int? = nil, _ c: Int? = nil) {
                guard let m else { return }
                w.active.update(id: m) { x in
                    x.siblings.first = a
                    if mode != 21 { x.siblings.second = b }
                    if mode == 22 { x.siblings.third = c }
                }
            }
            switch mode {
            case 21:
                link(id, sibs[0])
                link(sibs[0], id)
            case 20:
                link(id, sibs[0], sibs[1])
                link(sibs[0], sibs[1], id)
                link(sibs[1], id, sibs[0])
            default:
                link(id, sibs[0], sibs[1], sibs[2])
                link(sibs[0], sibs[1], sibs[2], id)
                link(sibs[1], sibs[2], id, sibs[0])
                link(sibs[2], id, sibs[0], sibs[1])
            }
            let angles: [Int16] = mode == 21 ? [0, 0xb4] : (mode == 20 ? [0, 0x78, 0xf0] : [0, 0x5a, 0xb4, 0x10e])
            for (m, a) in zip(members, angles) {
                guard let m else { continue }
                RadialMotion.make(w, id: m, cx: cx, cy: cy, radius: p2, speed: 0, angle: a, gravity: 0, damp: 0xf7,
                                  hubDamp: hubDamp, persp: 0)
            }
            for case let m? in members { chains(m, mode == 20 ? 12 : 14) }
            iceEffect(members.compactMap { $0 })
        case 0x584:
            // Catapult seat (l. 54924–54929): one-way, rect (0, 0, 0x18, 0x18), no face, no hit callback.
            s.oneWay = true
            s.hotRect = IdleSprites.Rect(top: 0, left: 0, bottom: 0x18, right: 0x18)
            s.face = nil
            s.hasHit = false
            put(s)
        case 0x34:
            // Blinking (l. 54931–54948): `+0x14c = p1`, `+0x150 = p2` (0 → 32000), `+0x154 = p3`, `+0xa6 = p4`,
            // `+0x46` 0 inside the on-time else 0x14.
            s.classTimer = Int32(rec?.p1 ?? 0)
            s.classWord150 = Int32(p2)
            if s.classWord150 == 0 { s.classWord150 = 32000 }
            s.classWord154 = Int32(p3)
            s.counterA6 = p4
            s.phase = Int32(s.counterA6) < s.classWord150 ? 0 : 0x14
            put(s)
        case 0x32:
            // Sinking (l. 54950–54964): sag 0; `+0x14c = p2` (0 → 2), `+0x150 = p3` (0 → 2000), home `+0x15c = y`,
            // `+0xa6 = +0x14c`, `+0xb2 = 10`.
            s.sag = 0
            s.classTimer = Int32(p2)
            if s.classTimer == 0 { s.classTimer = 2 }
            s.classWord150 = Int32(p3)
            if s.classWord150 == 0 { s.classWord150 = 2000 }
            s.classWord15c = Int32(Int16(truncatingIfNeeded: s.y))
            s.counterA6 = Int16(truncatingIfNeeded: s.classTimer)
            s.subState = 10
            put(s)
        case 0x33:
            // Crumbling (l. 54965–54979): `+0x14c = p2` (0 → 2), `+0x150 = p3` (0 → 0x2d), `+0xa6 = +0x14c`,
            // `+0x15c = +0x150`, `+0xb2 = 10`.
            s.classTimer = Int32(p2)
            s.classWord150 = Int32(p3)
            if s.classTimer == 0 { s.classTimer = 2 }
            if s.classWord150 == 0 { s.classWord150 = 0x2d }
            s.counterA6 = Int16(truncatingIfNeeded: s.classTimer)
            s.classWord15c = s.classWord150
            s.subState = 10
            put(s)
        case 0x582, 0x583:
            // Catapult (l. 54981–55003): mass 0x8c, sag 0, friction 0x3c, 0x583 mirrored, `+0x80 = 0` (a direct store:
            // the list position is unchanged), `+0x46 = 0`, the seat 0x584 (`MTNewSprite(0x584, x, y, 0, −1,
            // Platform)`), gravity 300, not one-way, rect (0x20, 0x9c, 0xa6, 0xb8) flipped about 0xd8 when mirrored,
            // face set 0x582 [0], `+0x1d4` = seat, `+0x1d8 = 0`. (`.FlipHCoord(0x74, 0xd8)`'s result is dropped.)
            s.pushMass = 0x8c
            s.sag = 0
            s.friction = 0x3c
            if t == 0x583 { s.mirrored = true }
            s.layer = 0
            s.phase = 0
            put(s)
            let seat = newPlatform(w, type: 0x584, x: s.x, y: s.y, layer: 0)
            w.active.update(id: id) { c in
                c.gravity = 300
                c.oneWay = false
                var r = IdleSprites.Rect(top: 0x9c, left: 0x20, bottom: 0xb8, right: 0xa6)
                if c.mirrored { r = flipH(r, 0xd8) }
                c.hotRect = r
                c.face = FaceRef(pict: catapultSet, index: 0, set: .encoded)
                c.siblings.first = seat
                c.siblings.second = nil
            }
        case 0x58d:
            // Springboard base (l. 55004–55009).
            s.face = FaceRef(pict: springboardBase, index: 0, set: .encoded)
            s.gravity = 0
            s.hasHit = false
            s.hotRect = emptyRect
            put(s)
        case 0x585:
            // l. 55012–55019: no mass, no sag, solid, no hit callback, rect (0, 0, 0x2d, 0x5c), no face.
            s.pushMass = 0
            s.sag = 0
            s.oneWay = false
            s.hasHit = false
            s.hotRect = IdleSprites.Rect(top: 0, left: 0, bottom: 0x5c, right: 0x2d)
            s.face = nil
            put(s)
        case springboard:
            // Springboard (l. 55021–55046), record only: `+0x80 = 3` (direct store), y −= 0xf, the base 0x58d at
            // (x, y + 0x2d) layer 0 and the gauge 0x58e at (x + 0xe, y + 0xe) layer 1 (types and `+0xb0` restored after
            // their Setups), links, rect (5, 0, 0x2d, 0x32), buoyancy 0x168, gravity 100, sag 0x50, mass 0, `+0xa6 =
            // 0`, top `+0x14c = y`, rest line `+0x150 = y + 0xe`, y += 0xf (the pixel copy only), face 0x58c.
            guard rec != nil else { put(s); break }
            s.layer = 3
            s.y = h(s.y - 0xf)
            put(s)
            let base = newPlatform(w, type: springboardBase, x: s.x, y: h(s.y + 0x2d), layer: 0)
            if let base { w.active.update(id: base) { $0.type = springboardBase; $0.subtype = springboardBase } }
            let gauge = newPlatform(w, type: springboardGauge, x: h(s.x + 0xe), y: h(s.y + 0xe), layer: 1)
            if let gauge { w.active.update(id: gauge) { $0.type = springboardGauge; $0.subtype = springboardGauge } }
            w.active.update(id: id) { c in
                c.siblings.first = base
                c.siblings.second = gauge
            }
            if let base {
                w.active.update(id: base) { b in
                    b.siblings.first = id
                    b.siblings.second = gauge
                }
            }
            w.active.update(id: id) { c in
                c.hotRect = IdleSprites.Rect(top: 0, left: 5, bottom: 0x32, right: 0x2d)
                c.buoyancy = 0x168
                c.gravity = 100
                c.sag = 0x50
                c.pushMass = 0
                c.counterA6 = 0
                c.classTimer = Int32(Int16(truncatingIfNeeded: c.y))
                c.classWord150 = Int32(Int16(truncatingIfNeeded: c.y)) + 0xe
                c.y = h(c.y + 0xf)
                c.face = FaceRef(pict: springboard, index: 0, set: .encoded)
                c.hasHit = true
            }
        case 0x58e:
            // Springboard gauge (l. 55048–55053).
            s.face = FaceRef(pict: springboardGauge, index: 0, set: .encoded)
            s.gravity = 0
            s.hasHit = false
            s.lightOverlay = false
            s.hotRect = emptyRect
            put(s)
        default:
            put(s)
        }
    }

    /// `.FlipHRect(r, w) @ 10045258`: left = w − left, right = w − right, swapped when right < left.
    static func flipH(_ r: IdleSprites.Rect, _ w: Int) -> IdleSprites.Rect {
        var o = r
        o.left = h(w - r.left)
        o.right = h(w - r.right)
        if o.right < o.left { swap(&o.left, &o.right) }
        return o
    }

    // MARK: - Handle

    /// The face width a Cleanup reads (face `+6`): the sheet cells of the platform sets, else 0x80 [MED: Core has no
    /// face records; only the occluder clip reads it, and no platform has an occluder].
    public static func faceWidth(_ f: FaceRef) -> Int {
        SetupFaces.sheet(pict: f.pict).map { $0.single ? 0x80 : $0.cellWidth } ?? 0x80
    }

    /// The tile callback a platform's `+0x1f8` names (nil = 0).
    static func pass(_ s: SpriteSlot) -> TileHit? {
        guard s.hasTileHit else { return nil }
        return { solver, id, cell, kind, layer in hitTile(solver, id: id, pos: cell, kind: kind, layer: layer) }
    }

    /// `.HandlePlatformSprite @ 100635b4` (decompile l. 55029–55786): `+0xe9` / `+0x1b2` → return; the first frame's
    /// `.DoSetupPlatformSprite`; `.StandardSpriteHandles`; the mode arm; the tail (rafts / floes / the walker corpse;
    /// the integration of modes < 10 and ≥ 0x58c; mode 2's vertical spring-back; the tile pass);
    /// `.StandardSpriteCleanup`.
    public static func handle(world w: SpriteWorld, id: Int, solver: TileSolver,
                              faceWidth: (FaceRef) -> Int = PlatformSprite.faceWidth) {
        guard let s0 = w.active.record(id: id), !s0.dead, !s0.handleSkip else { return }
        if !s0.setupDone {
            doSetup(w, id: id)
            w.active.update(id: id) { $0.setupDone = true }
        }
        w.standardSpriteHandles(id)
        guard let s = w.active.record(id: id) else { return }
        let mode = s.subtype
        switch mode {
        case 0x1e: seeSaw(w, id: id)
        case 1, 2: shuttle(w, id: id, vertical: mode == 1)
        case 10, 11:
            w.active.update(id: id) { c in
                c.counterA6 = c.counterA6 < 0 ? c.counterA6 + 1 : 0
                c.vy = 0
                c.vx = 0
            }
            RadialMotion.updatePosition(w, id: id)
            RadialMotion.updateSpokes(w, id: id, slopeMode: false, base: 0)
            w.active.update(id: id) { $0.jumpBonus = 0 }
        case 20, 21, 22: wheel(w, id: id, mode: mode)
        case 0x33: crumble(w, id: id)
        case 0x32: sink(w, id: id, solver: solver)
        case 0x34: blink(w, id: id)
        case 0x582, 0x583: catapult(w, id: id)
        case springboard: springboardHandle(w, id: id, solver: solver)
        default: break
        }
        tail(w, id: id, solver: solver)
        w.standardSpriteCleanup(id, faceWidth: faceWidth)
    }

    /// Modes 1 (vertical, `+0x1c`/`+0x2c`, raw `10063754..100637ac`) and 2 (horizontal, `+0x14`/`+0x24`, l. 55121–55145):
    /// a 5/6 / 7/8 shuttle (`+0x15c == 1`) not ridden coasts, v = (int)(v·0.4); otherwise (`+0x158 != 1` clears the
    /// ridden latch) direction `+0xa6 == 1`: past `+0x154` → −1, else while v < speed v += speed >> 4 — **no clamp
    /// after the step** (Invariant 7: the overshoot is behaviour); direction ≠ 1: before `+0x150` → 1, else while
    /// −speed < v v −= speed >> 4; `+0x194 = 0`.
    static func shuttle(_ w: SpriteWorld, id: Int, vertical: Bool) {
        w.active.update(id: id) { s in
            var v = vertical ? s.vy : s.vx
            let p = vertical ? s.y256 : s.x256
            let speed = s.classTimer
            if s.classWord15c == 1 && !s.ridingLatch {
                v = TileSolver.fctiwz(Double(v) * coast)
            } else {
                if s.classWord158 != 1 { s.ridingLatch = false }
                if s.counterA6 == 1 {
                    if s.classWord154 < p {
                        s.counterA6 = -1
                    } else if v < speed {
                        v &+= speed >> 4
                    }
                } else if p < s.classWord150 {
                    s.counterA6 = 1
                } else if 0 &- speed < v {
                    v &-= speed >> 4
                }
                s.jumpBonus = 0
            }
            if vertical { s.vy = v } else { s.vx = v }
        }
    }

    /// Modes 20 / 21 / 22 (l. 55165–55271): vx = vy = 0; cooldown `+0xa6` (< 0 → +1, else 0); ridden (`+0x186`) with
    /// `+0xa6 ≥ 0` → driver `+0xb2 = 1` and `.RadialWheelStep(s, 0x100)`; `.UpdateRadialPos`; spokes; `+0x186 = 0`;
    /// the driver writes every sibling `+0xb2 = 0`, angle = own + 0x7800 / 0xf000 (20), 0xb400 (21), 0x5a00 / 0xb400 /
    /// 0x10e00 (22) — not wrapped —, its speed and its hub **position** (not the hub velocity); `+0x194 = 0`.
    static func wheel(_ w: SpriteWorld, id: Int, mode: Int16) {
        w.active.update(id: id) { c in
            c.vy = 0
            c.vx = 0
            c.counterA6 = c.counterA6 < 0 ? c.counterA6 + 1 : 0
        }
        if let s = w.active.record(id: id), s.ridingLatch, -1 < s.counterA6 {
            w.active.update(id: id) { $0.subState = 1 }
            RadialMotion.wheelStep(w, id: id, k: 0x100)
        }
        RadialMotion.updatePosition(w, id: id)
        RadialMotion.updateSpokes(w, id: id, slopeMode: false, base: 0)
        w.active.update(id: id) { $0.ridingLatch = false }
        if let s = w.active.record(id: id), s.subState == 1, let b = s.radial {
            let links: [(Int?, Int32)]
            switch mode {
            case 21: links = [(s.siblings.first, 0xb400)]
            case 20: links = [(s.siblings.first, 0x7800), (s.siblings.second, 0xf000)]
            default: links = [(s.siblings.first, 0x5a00), (s.siblings.second, 0xb400), (s.siblings.third, 0x10e00)]
            }
            for (sib, _) in links { if let sib { w.active.update(id: sib) { $0.subState = 0 } } }
            for (sib, offset) in links { if let sib { w.active.update(id: sib) { $0.radial?.angle = b.angle &+ offset } } }
            for (sib, _) in links { if let sib { w.active.update(id: sib) { $0.radial?.speed = b.speed } } }
            for (sib, _) in links {
                if let sib {
                    w.active.update(id: sib) { c in
                        c.radial?.hubX = b.hubX
                        c.radial?.hubY = b.hubY
                    }
                }
            }
        }
        w.active.update(id: id) { $0.jumpBonus = 0 }
    }

    /// Mode 30, the see-saw arm (l. 55068–55118; raw free arm `10063db4..10063e44`): vy = vx = 0; cooldown; ridden with
    /// `+0xa6 ≥ 0` → driver, `.RadialWheelStep(s, +0x150)` (the lever the ridden segment wrote); `.UpdateRadialPos`;
    /// `.UpdateRadiusSprites(s, 1, 0x4b)` (sloped segment tops); the driver, when not ridden or with lever 0, drifts
    /// back to level — the sibling (record −1): angle < 0xb200 → speed + 0x18, > 0xb600 → − 0x18; the record arm:
    /// 0x200 < angle < 0xb400 → − 0x18, 0xb400 < angle < 0x16600 → + 0x18 — then slaves its sibling (`+0xb2 = 0`,
    /// angle + 0xb400, speed, hub position); `+0x186 = 0`, `+0x194 = 0`, face `+0xc0 = 0` (drawn by its segments only).
    static func seeSaw(_ w: SpriteWorld, id: Int) {
        w.active.update(id: id) { c in
            c.vy = 0
            c.vx = 0
            c.counterA6 = c.counterA6 < 0 ? c.counterA6 + 1 : 0
        }
        if let s = w.active.record(id: id), s.ridingLatch, -1 < s.counterA6 {
            w.active.update(id: id) { $0.subState = 1 }
            RadialMotion.wheelStep(w, id: id, k: s.classWord150)
        }
        RadialMotion.updatePosition(w, id: id)
        RadialMotion.updateSpokes(w, id: id, slopeMode: true, base: 0x4b)
        if let s = w.active.record(id: id), s.subState == 1 {
            if !s.ridingLatch || s.classWord150 == 0 {
                w.active.update(id: id) { c in
                    guard var b = c.radial else { return }
                    if c.recordIndex == -1 {
                        if b.angle < 0xb200 { b.speed &+= 0x18 } else if 0xb600 < b.angle { b.speed &-= 0x18 }
                    } else if b.angle < 0xb400 && 0x200 < b.angle {
                        b.speed &-= 0x18
                    } else if 0xb400 < b.angle && b.angle < 0x16600 {
                        b.speed &+= 0x18
                    }
                    c.radial = b
                }
            }
            if let sib = s.siblings.first, let b = w.active.record(id: id)?.radial {
                w.active.update(id: sib) { c in
                    c.subState = 0
                    c.radial?.angle = b.angle &+ 0xb400
                    c.radial?.speed = b.speed
                    c.radial?.hubX = b.hubX
                    c.radial?.hubY = b.hubY
                }
            }
        }
        w.active.update(id: id) { c in
            c.ridingLatch = false
            c.jumpBonus = 0
            c.face = nil
        }
    }

    /// Mode 51, crumbling (l. 55275–55354; platforms-ropes-radial §2.8): armed (`+0xb2 == 10`) — ridden frames count
    /// `+0xa6` down (the latch cleared); at < 1 the break-up counter `+0x46` runs: on 1 the sound 461 (`_DAT_100a035c`;
    /// p4 == 0 → `.STPlay3DSoundRand(461, 1, 0xab)` — its rate drawn here — else `.STPlay3DSoundPitched(461, 1, 0x100,
    /// p4·0xf3b + 0x10000)`), > 2 no light overlay, > 6 / 10 / 14 → 0xb0001 / 0xb0000 / 0xb0002, > 0x12 → (`+0x150 ==
    /// −1`: `+0x46 = 7`, re-form) else empty rect and bottom clip 0; else `+0x46 = 0`; past `+0x150` (> 0) → re-form.
    /// Re-forming: rect back, `+0x46 += 1`, > 4 → 0xb0002 with the clip back, > 8 → 0xb0000, > 0xc → effect 0, overlay,
    /// rect, `+0xa6 = +0x14c`, `+0x46 = 0`, re-armed.
    static func crumble(_ w: SpriteWorld, id: Int) {
        guard let s0 = w.active.record(id: id) else { return }
        if s0.subState == 10 {
            var sound = false
            w.active.update(id: id) { s in
                if s.ridingLatch { s.counterA6 -= 1 }
                s.ridingLatch = false
                if s.counterA6 < 1 {
                    s.phase += 1
                    if s.phase == 1 { sound = true }
                    if 2 < s.phase { s.lightOverlay = false }
                    if 6 < s.phase { s.mode = 0xb0001 }
                    if 10 < s.phase { s.mode = 0xb0000 }
                    if 0xe < s.phase { s.mode = 0xb0002 }
                    if 0x12 < s.phase {
                        if s.classWord150 == -1 {
                            s.phase = 7
                            s.subState = 0xb
                        } else {
                            s.hotRect = emptyRect
                            s.clip.bottom = 0
                        }
                    }
                } else {
                    s.phase = 0
                }
                if 0 < s.classWord150 && s.classWord150 < Int32(s.phase) {
                    s.subState = 0xb
                    s.phase = 0
                }
            }
            if sound {
                let pos = w.active.record(id: id)?.centre
                let p4 = record(w, s0)?.p4 ?? 0
                if p4 == 0 {
                    let rate = w.rng.soundRate()
                    w.player.cues.append(PlayerCue(call: .threeDRand, snd: 461, priority: 1, volume: 0xab,
                                                   position: pos, rate: rate))
                } else {
                    w.player.cues.append(PlayerCue(call: .threeDPitched, snd: 461, priority: 1, volume: 0x100,
                                                   position: pos, rate: Int32(p4) &* 0xf3b &+ 0x10000))
                }
            }
        } else {
            w.active.update(id: id) { s in
                s.hotRect = defaultRect
                s.phase += 1
                if 4 < s.phase {
                    s.mode = 0xb0002
                    s.clip.bottom = 32000
                }
                if 8 < s.phase { s.mode = 0xb0000 }
                if 0xc < s.phase {
                    s.mode = 0
                    s.lightOverlay = true
                    s.hotRect = defaultRect
                    s.counterA6 = Int16(truncatingIfNeeded: s.classTimer)
                    s.phase = 0
                    s.subState = 10
                }
            }
        }
    }

    /// Mode 50, sinking (l. 55357–55395): `.ApplyGravityAndSeparateFromTiles` first; armed — ridden frames count down,
    /// at < 1 gravity ramps +0x1e while < 400, else vy = gravity = 0; past home + depth → returning; returning —
    /// gravity 0, vy −= 0x32 floored at −0x200, at or above home → stopped and re-armed (`+0xa6 = +0x14c`).
    static func sink(_ w: SpriteWorld, id: Int, solver: TileSolver) {
        if let s = w.active.record(id: id) { solver.applyGravityAndSeparate(id, pass: pass(s)) }
        w.active.update(id: id) { s in
            if s.subState == 10 {
                if s.ridingLatch { s.counterA6 -= 1 }
                s.ridingLatch = false
                if s.counterA6 < 1 {
                    if s.gravity < 400 { s.gravity += 0x1e }
                } else {
                    s.vy = 0
                    s.gravity = 0
                }
                if s.classWord15c &+ s.classWord150 < Int32(Int16(truncatingIfNeeded: s.y)) { s.subState = 0xb }
            } else {
                s.gravity = 0
                s.vy &-= 0x32
                if s.vy < -0x200 { s.vy = -0x200 }
                if Int32(Int16(truncatingIfNeeded: s.y)) <= s.classWord15c {
                    s.vy = 0
                    s.gravity = 0
                    s.subState = 10
                    s.counterA6 = Int16(truncatingIfNeeded: s.classTimer)
                }
            }
        }
    }

    /// Mode 52, blinking (l. 55396–55452): `+0xa6` counts up and wraps past `+0x154`; inside the on-time `+0x46` falls
    /// to 0, else rises to 0x14; > 2 → effect 0, bottom clip 32000, overlay; > 6 → 0xb0001, no overlay; > 10 → 0xb0000;
    /// > 14 → 0xb0002; < 0x13 → rect, else empty rect and bottom clip 0.
    static func blink(_ w: SpriteWorld, id: Int) {
        w.active.update(id: id) { s in
            s.counterA6 += 1
            if s.classWord154 < Int32(s.counterA6) { s.counterA6 = 0 }
            if Int32(s.counterA6) < s.classWord150 {
                if s.phase < 1 { s.phase = 0 } else { s.phase -= 1 }
            } else if s.phase < 0x14 {
                s.phase += 1
            } else {
                s.phase = 0x14
            }
            if 2 < s.phase {
                s.mode = 0
                s.clip.bottom = 32000
                s.lightOverlay = true
            }
            if 6 < s.phase {
                s.mode = 0xb0001
                s.lightOverlay = false
            }
            if 10 < s.phase { s.mode = 0xb0000 }
            if 0xe < s.phase { s.mode = 0xb0002 }
            if s.phase < 0x13 {
                s.hotRect = defaultRect
            } else {
                s.hotRect = emptyRect
                s.clip.bottom = 0
            }
        }
    }

    /// The catapult 0x582 / 0x583 (l. 55455–55551): while its seat (`+0x1d4`) is ridden at step 0, or the script runs
    /// (`+0x46 > 0`): sounds 440 at step 0 and 441 at step 6 (`.STPlay3DSoundRand`, rates drawn here), step + 1,
    /// wrapping past the count; face f = the script entry. Face 5 with a seat rider: the rider vx ± 6000 (by facing),
    /// vy − 0x9c4, the player rider `+0x14c = 1`. The seat's latch cleared; face set 0x582 [f]; the seat placed per face
    /// (mirrored: `.FlipHCoord(x, 0xd8) − 0x18`). Not on levels 1–2.
    static func catapult(_ w: SpriteWorld, id: Int) {
        guard let s = w.active.record(id: id) else { return }
        let seat = s.siblings.first
        let seatRidden = seat.flatMap { w.active.record(id: $0) }?.ridingLatch ?? false
        var f: Int16 = 0
        if (seatRidden && s.phase == 0) || 0 < s.phase {
            let pos = s.centre
            if s.phase == 0 {
                let rate = w.rng.soundRate()
                w.player.cues.append(PlayerCue(call: .threeDRand, snd: 440, priority: 1, volume: 0x100, position: pos,
                                               rate: rate))
            }
            if s.phase == 6 {
                let rate = w.rng.soundRate()
                w.player.cues.append(PlayerCue(call: .threeDRand, snd: 441, priority: 1, volume: 0x100, position: pos,
                                               rate: rate))
            }
            var phase = s.phase + 1
            if catapultScriptCount < phase { phase = 0 }
            w.active.update(id: id) { $0.phase = phase }
            f = Int(phase) < catapultScript.count ? catapultScript[Int(phase)] : 0
        }
        if f == 5, let seat, let rider = w.active.record(id: seat)?.rider {
            let push: Int32 = s.mirrored ? -6000 : 6000
            if rider == w.playerID { w.active.update(id: rider) { $0.classTimer = 1 } }
            w.active.update(id: rider) { r in
                r.vx &+= push
                r.vy &-= 0x9c4
            }
        }
        if let seat, w.active.record(id: seat)?.ridingLatch == true { w.active.update(id: seat) { $0.ridingLatch = false } }
        w.active.update(id: id) { $0.face = FaceRef(pict: catapultSet, index: Int(f), set: .encoded) }
        let table: [(Int, Int)] = [(2, 0x80), (3, 0x89), (5, 0x92), (0x23, 0x36), (0x78, 0x19), (0x96, 0x11), (0xc1, 0x15)]
        guard (0..<table.count).contains(Int(f)) else { return }        // `unaff_r27`/`r26`: no other face is scripted
        var (dx, dy) = table[Int(f)]
        if s.mirrored { dx = (0xd8 - dx) - 0x18 }
        let sx = s.mirrored ? (0xd8 - 0x74) - 0x2d : 0x74
        let cur = w.active.record(id: id) ?? s
        if let seat {
            w.active.update(id: seat) { c in
                c.x = h(cur.x + dx)
                c.y = h(cur.y + dy)
                c.x256 = Int32(Int16(truncatingIfNeeded: c.x)) << 8
                c.y256 = Int32(Int16(truncatingIfNeeded: c.y)) << 8
            }
        }
        if let second = cur.siblings.second {
            w.active.update(id: second) { c in
                c.x = h(cur.x + sx)
                c.y = h(cur.y + 0x68)
                c.x256 = Int32(Int16(truncatingIfNeeded: c.x)) << 8
                c.y256 = Int32(Int16(truncatingIfNeeded: c.y)) << 8
            }
        }
    }

    /// The springboard 0x58c (l. 55554–55697; raw `10064748..100647f8`): its own gravity pass on the rest-line
    /// copy (`+0x154` as vy), the move carried to both children, the spring toward the rest line (`(rest − y)·16`, or
    /// +600 above the top while rising), flotation between the rest line and top + 0x28 (`.HandleFlotation(s, rest)` —
    /// r4 still holds `+0x150` at the call, `1006474c` → `100647f8`; exactly at rest with |vy| < 0xdc → still), clamped
    /// deeper (vy reflected upward); the rider's jump bonus `+0x194 = −0x80·min(depression, 0x1c)`; the gauge child's
    /// position and fill face (q < 11 → none, else 0x58e with `0xa0000 + q` below 0xfb); the rect shortened by the
    /// depression. Not on levels 1–2.
    static func springboardHandle(_ w: SpriteWorld, id: Int, solver: TileSolver) {
        guard let s0 = w.active.record(id: id) else { return }
        let oldX = s0.x, oldY = s0.y                                   // `uVar6` (+0xa / +0xc)
        let oldVY = s0.vy                                              // `uVar15`
        let top0 = s0.classTimer                                       // `uVar7`
        w.active.update(id: id) { c in
            c.y = h(Int(Int16(truncatingIfNeeded: c.classTimer)))
            c.y256 = Int32(Int16(truncatingIfNeeded: c.y)) << 8
            c.hotRect = IdleSprites.Rect(top: 0, left: 5, bottom: 0x32, right: 0x2d)
            c.vy = c.classWord154
        }
        solver.applyGravityAndSeparate(id, pass: pass(s0))
        guard let s1 = w.active.record(id: id) else { return }
        let afterY = s1.y
        let dx = Int16(truncatingIfNeeded: s1.x - oldX)
        let dy = Int16(truncatingIfNeeded: s1.vy >> 8) &+ Int16(truncatingIfNeeded: afterY - Int(Int16(truncatingIfNeeded: top0)))
        let dx256 = Int32(dx) &* 0x100, dy256 = Int32(dy) &* 0x100
        w.active.update(id: id) { c in
            c.classWord154 = c.vy
            c.vy = oldVY
            c.x = oldX
            c.y = oldY
            c.x256 = Int32(Int16(truncatingIfNeeded: c.x)) << 8
            c.y256 = Int32(Int16(truncatingIfNeeded: c.y)) << 8
            c.classTimer &+= Int32(dy)
            c.classWord150 &+= Int32(dy)
            c.x = h(c.x + Int(dx))
            c.y = h(c.y + Int(dy))
            c.x256 &+= dx256
            c.y256 &+= dy256
        }
        for child in [s0.siblings.first, s0.siblings.second] {
            guard let child else { continue }
            w.active.update(id: child) { c in
                c.x = h(c.x + Int(dx))
                c.y = h(c.y + Int(dy))
                c.x256 &+= dx256
                c.y256 &+= dy256
            }
        }
        guard let s = w.active.record(id: id) else { return }
        let y = Int32(Int16(truncatingIfNeeded: s.y))
        let rest = s.classWord150
        var flotation = false
        w.active.update(id: id) { c in
            if y < rest {
                if y < c.classTimer && c.vy < 0 { c.vy &+= 600 } else { c.vy &+= (rest &- y) &* 0x10 }
            } else if y < c.classTimer &+ 0x29 {
                let m = c.vy < 1 ? 0 &- c.vy : c.vy
                if y == rest && m < 0xdc { c.vy = 0 } else { flotation = true }
            } else {
                c.y = h(Int(c.classTimer) + 0x28)
                if 0 < c.vy { c.vy = 0 &- c.vy }
            }
        }
        if flotation { Flotation.handle(world: w, id: id, surfaceY: rest) }
        guard let t = w.active.record(id: id) else { return }
        let ty = Int32(Int16(truncatingIfNeeded: t.y))
        w.active.update(id: id) { c in
            if c.ridingLatch && c.classWord150 < ty {
                var d = ty &- c.classWord150
                if 0x1c < d { d = 0x1c }
                c.jumpBonus = d &* -0x80
                if 0 < c.jumpBonus { c.jumpBonus = -1 }
            } else {
                c.jumpBonus = 0
            }
            if 0 < c.jumpBonus { c.jumpBonus = 0 }
        }
        let foot = Int16(truncatingIfNeeded: (t.y256 &+ t.vy) >> 8)
        if let gauge = t.siblings.second {
            let q32 = (Int32(Int16(truncatingIfNeeded: Int32(Int16(truncatingIfNeeded: t.classTimer)) &+ 0x2d
                                                        &- Int32(foot))) << 8) / 0x2d
            let q = Int32(Int16(truncatingIfNeeded: q32))
            w.active.update(id: gauge) { g in
                g.x = h(t.x + 0xe)
                g.y = h(Int(foot) + 10)
                g.y256 = Int32(Int16(truncatingIfNeeded: g.y)) << 8
                if q < 0xb {
                    g.face = nil
                    g.mode = 0
                } else {
                    g.mode = q < 0xfb ? UInt32(bitPattern: q &+ 0xa0000) : 0
                    g.face = FaceRef(pict: springboardGauge, index: 0, set: .encoded)
                }
            }
        }
        w.active.update(id: id) { c in
            c.hotRect = IdleSprites.Rect(top: 0, left: 5,
                                         bottom: h(0x32 - (Int(Int16(truncatingIfNeeded: c.y)) - Int(c.classTimer))),
                                         right: 0x2d)
        }
    }

    /// The tail every mode reaches (`LAB_10064968`, l. 55700–55782; raw `10064968..10064d50`):
    /// - modes 3 / 4 and type 0x6a4: the corpse's buoyancy +1 when `FastRand(2) == 1` while < 0x50 (drawn only then);
    ///   gravity only when dry last frame (`+0x11c == 0 ∧ +0x120 == 0`, `100649c4`); the raft (3): tilt toward the
    ///   rider — target = ∓|rider.cx − cx| / 5 (rider right of the centre → negative), `+0x46` eases ±2 when off by
    ///   more than 1, `+0x1aa` = `+0x46` (+360 when negative), `+0x88 = 0`, `+0x89 = 1` (the latch cleared only with a
    ///   rider); `.ApplyFriction(100)`; a lifetime `+0xa6 > 0` counts down (at < 1 the particles // later: E1a and
    ///   `+0xe9`), below 0x2d the floe face with effect 0 / 0xb0000 by the frame parity `_DAT_1009fd30`.
    /// - modes < 10 and ≥ 0x58c: x += vx, y += vy.
    /// - mode 2: the vertical spring-back to the record y `+0x10` (raw `10064bb8..10064c50`): y > record → vy > 0 ?
    ///   vy >>= 1 (≤ 0x80 → −0x80) : (vy > −0x180 → vy −= 0x40); y < record → y256 = record << 8 (vy kept); equal →
    ///   the two write-only globals `_DAT_100a6312 = 0x100` and `*PTR_DAT_100a094c = 0` (no reader; not kept).
    /// - modes < 10: pixel copies, `.SeparateFromTiles2`, pixel copies; other modes below 0x58c except 30 and 50:
    ///   catapults `.ApplyFriction(+0x114)` + `.ApplyGravityAndSeparateFromTiles`, the rest `.SeparateFromTiles2`;
    ///   ≥ 0x58c: pixel copies.
    static func tail(_ w: SpriteWorld, id: Int, solver: TileSolver) {
        guard let s0 = w.active.record(id: id) else { return }
        let mode = s0.subtype
        if mode == 3 || mode == 4 || s0.type == 0x6a4 {
            if s0.type == 0x6a4 && s0.buoyancy < 0x50 && w.rng.next(2) == 1 {
                w.active.update(id: id) { $0.buoyancy += 1 }
            }
            w.active.update(id: id) { s in
                if s.waterRow == 0 && s.lastWater == 0 { s.vy &+= Int32(s.gravity) }
            }
            if mode == 3 {
                guard let s = w.active.record(id: id) else { return }
                var target: Int16 = 0
                var clearLatch = false
                if s.ridingLatch, let r = s.rider {
                    let rcx = Int16(truncatingIfNeeded: w.active.record(id: r)?.centre.x ?? 0)
                    let d = rcx &- Int16(truncatingIfNeeded: s.centre.x)
                    let m = d < 1 ? 0 &- d : d
                    target = m / 5
                    if 0 < d { target = 0 &- target }
                    clearLatch = true
                }
                w.active.update(id: id) { c in
                    if clearLatch { c.ridingLatch = false }
                    if Int32(c.phase) < Int32(target) - 1 {
                        c.phase += 2
                    } else if Int32(target) + 1 < Int32(c.phase) {
                        c.phase -= 2
                    }
                    var r = c.phase
                    if r < 0 { r += 0x168 }
                    c.rotation = r
                    c.lightOverlay = false
                    c.dynamicLight = true
                }
            }
            w.active.update(id: id) { $0.applyFriction(100) }
            if let s = w.active.record(id: id), 0 < s.counterA6 {
                let parity = w.parity
                w.active.update(id: id) { c in
                    c.counterA6 -= 1
                    if c.counterA6 < 1 {
                        // later: E1a — `.ExplodeFaceIntoParticles(+0xc0, pos, 1, 2, 4, 0x32, 100)` (its particles and
                        // their `FastRand` draws).
                        c.dead = true
                    }
                    if c.counterA6 < 0x2d {
                        c.lightOverlay = true
                        c.face = FaceRef(pict: iceSet, index: Int(c.classWord16c), set: .encoded)
                        c.mode = parity ? 0xb0000 : 0
                    }
                }
            }
        }
        if mode < 10 || 0x58b < mode {
            w.active.update(id: id) { s in
                s.x256 &+= s.vx
                s.y256 &+= s.vy
            }
        }
        if mode == 2, let r = record(w, s0) {
            w.active.update(id: id) { s in
                let home = Int32(r.y)
                let y = s.y256 >> 8
                if y == home {
                    // `_DAT_100a6312 = 0x100`, `*PTR_DAT_100a094c = 0`: write-only (no reader; their only references).
                } else if home < y {
                    if 0 < s.vy {
                        s.vy = s.vy >> 1
                        if s.vy < 0x81 { s.vy = -0x80 }
                    } else if -0x180 < s.vy {
                        s.vy = s.vy &- 0x40
                    }
                } else {
                    s.y256 = home << 8
                }
            }
        }
        func copies() {
            w.active.update(id: id) { s in
                let px = SpriteWorld.pixel(s.x256), py = SpriteWorld.pixel(s.y256)
                s.oldPosition = SpriteSlot.Point(x: px, y: py)
                s.x = px
                s.y = py
            }
        }
        guard let s1 = w.active.record(id: id) else { return }
        if mode < 10 {
            copies()
            solver.separateFromTiles(id, pass: pass(s1))
            copies()
        } else if mode < springboard && mode != 0x1e && mode != 0x32 {
            if s1.type == 0x582 || s1.type == 0x583 {
                w.active.update(id: id) { $0.applyFriction($0.friction) }
                solver.applyGravityAndSeparate(id, pass: pass(s1))
            } else {
                solver.separateFromTiles(id, pass: pass(s1))
            }
        } else if 0x58b < mode {
            copies()
        }
    }

    // MARK: - Hit callbacks

    /// `.HitPlatformSprite(self, other) @ 10064d94` (decompile l. 55790–55838; platforms-ropes-radial §2.6): a player
    /// shot of id 1 (Statue) // later: Phase 4 (spells; `.TurnIntoStatue`). Another Platform-handled sprite: unless both
    /// are rafts/floes (modes 3/4) or both catapult parts (0x582…0x585), `.PlatformBounce(self, other, own rect centre,
    /// 0, own rect, 0)` — the platform is the mover; a springboard bounces with `+0x154` as its vy (swapped in and out).
    public static func hit(_ w: SpriteWorld, id: Int, other: Int) {
        guard let s = w.active.record(id: id), let o = w.active.record(id: other) else { return }
        guard o.handler == .platform, !o.handleCleared else { return }
        let a = s.subtype, b = o.subtype
        let bothFloat = (a == 3 || a == 4) && (b == 3 || b == 4)
        let bothCatapult = (0x582...0x585).contains(a) && (0x582...0x585).contains(b)
        guard !bothFloat, !bothCatapult else { return }
        let r = s.hotRect
        let centre = SpriteSlot.Point(x: h(r.left + h((r.right - r.left) >> 1)), y: h(r.top + h((r.bottom - r.top) >> 1)))
        let savedVY = s.vy
        if a == springboard { w.active.update(id: id) { $0.vy = $0.classWord154 } }
        w.platformBounce(mover: id, solid: other, centre: centre, factor: 0, rect: r, bounce: false)
        if a == springboard {
            w.active.update(id: id) { c in
                c.classWord154 = c.vy
                c.vy = savedVY
            }
        }
    }

    /// `.HitPlatformTileSprite(s, pos, kind, layer) @ 10064f04` (decompile l. 55842–55942; platforms-ropes-radial
    /// §2.7): mode 4 on FG → rect (0, −6, 0x28, 6) for the call (restored after). FG: `.WallBounce(…, factor, rect,
    /// bounce 1)`, factor 0x80 (0 for a 0x58c with |`+0x154`| < 0x200; 0x20 for mode 50); a hit — mode 50 → `+0xb2 =
    /// 0xb`, y −= 1; modes 10…0x1d → the pre-call 24.8 position restored (pixel and `+8`/`+6` copies), and when
    /// `+0xa6 == 0` and `+0x180` clear: driver `+0xb2 = 1`, every linked sibling (`+0x1d4…+0x1e0`) cooldown −5 — and
    /// the `+0xb2 = 0` meant for each lands on `+0x1d4` (source bug kept: raw `100650e4`, `10065108`, `1006512c`) —,
    /// own `+0xa6 = −5`, `.BounceRadial` on self and each link with tileCentreX = pos.x + 16; `+0x180 = 1` (at most one
    /// bounce per frame; `.StandardSpriteHandles` clears it). BG kinds < 100 → `.WallBounce(…, 0, …, 0)`, 100…199 →
    /// `.WallBounceBG(kind − 100, …)`, water → `.HandleUnderWater` unless `+0x140`.
    public static func hitTile(_ solver: TileSolver, id: Int, pos posIn: TilePos, kind: Int, layer: TileLayer) {
        let w = solver.world
        guard let s0 = w.active.record(id: id) else { return }
        var pos = posIn
        let savedRect = s0.hotRect
        let floeFG = layer == .foreground && s0.subtype == 4
        if floeFG { w.active.update(id: id) { $0.hotRect = IdleSprites.Rect(top: -6, left: 0, bottom: 6, right: 0x28) } }
        guard let s = w.active.record(id: id) else { return }
        let r = s.hotRect
        let vCentre = h(r.top + h((r.bottom - r.top) >> 1))
        if layer == .foreground {
            var factor: Int16 = 0x80
            let entryX = s.x256, entryY = s.y256
            if s.type == springboard {
                let m = s.classWord154 < 1 ? 0 &- s.classWord154 : s.classWord154
                if m < 0x200 { factor = 0 }
            }
            if s.subtype == 0x32 { factor = 0x20 }
            if solver.wallBounce(id, kind: kind, tile: &pos, vCentre: vCentre, factor: factor, rect: r, bounce: true) {
                let mode = w.active.record(id: id)?.subtype ?? s.subtype
                if mode < 10 || 0x1d < mode {
                    if mode == 0x32 {
                        w.active.update(id: id) { c in
                            c.subState = 0xb
                            c.y = h(c.y - 1)
                            c.y256 = Int32(Int16(truncatingIfNeeded: c.y)) << 8
                        }
                    }
                } else {
                    w.active.update(id: id) { c in
                        c.x256 = entryX
                        c.y256 = entryY
                        c.x = SpriteWorld.pixel(entryX)
                        c.y = SpriteWorld.pixel(entryY)
                        c.oldPosition = SpriteSlot.Point(x: c.x, y: c.y)
                    }
                    if let c = w.active.record(id: id), c.counterA6 == 0, !c.radialLatch {
                        let centreX = Int16(truncatingIfNeeded: posIn.x &+ 0x10)
                        let links = c.siblings
                        w.active.update(id: id) { $0.subState = 1 }
                        if let a = links.first {
                            w.active.update(id: a) { x in
                                x.subState = 0
                                x.counterA6 = -5
                            }
                        }
                        for other in [links.second, links.third, links.fourth] {
                            guard let o = other else { continue }
                            if let a = links.first { w.active.update(id: a) { $0.subState = 0 } }   // the `+0x1d4` bug
                            w.active.update(id: o) { $0.counterA6 = -5 }
                        }
                        w.active.update(id: id) { $0.counterA6 = -5 }
                        RadialMotion.bounce(w, id: id, tileCentreX: centreX)
                        RadialMotion.bounce(w, id: links.first, tileCentreX: centreX)
                        RadialMotion.bounce(w, id: links.second, tileCentreX: centreX)
                        RadialMotion.bounce(w, id: links.third, tileCentreX: centreX)
                        RadialMotion.bounce(w, id: links.fourth, tileCentreX: centreX)
                    }
                    w.active.update(id: id) { $0.radialLatch = true }
                }
            }
        } else if Int16(truncatingIfNeeded: kind) < 100 {
            solver.wallBounce(id, kind: kind, tile: &pos, vCentre: vCentre, factor: 0, rect: r, bounce: false)
        } else if Int16(truncatingIfNeeded: kind) < 200 {
            solver.wallBounceBG(id, kind: kind - 100, tile: &pos, vCentre: vCentre, factor: 0, rect: r, bounce: false)
        } else if UnderWater.isWaterTile(kind), w.active.record(id: id)?.underwaterDone == false {
            UnderWater.handle(world: w, id: id, pos: pos)
        }
        if floeFG { w.active.update(id: id) { $0.hotRect = savedRect } }
    }
}
