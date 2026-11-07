import Foundation

/// The geysers 1440…1449 (GY; geysers.md, design §9 (b)): the Box geyser bases 0x5a0 (single) / 0x5a5 (triple), the
/// head 0x5a9 (a Box made by the column) and the segments 0x5a0 (Effect-class pieces with their own empty Handle).
/// - `.SetupBoxSprite`'s geyser arm (M l. 59116–59185, raw `1006bbdc..1006bde8`) — `setup`; its head arm (M l.
///   59107–59115) is `BoxSprite.setup`'s;
/// - `.HandleBoxSprite`'s eruption arm (`LAB_1006df20`, M l. 60379–60483, raw `1006df20..1006e274`) — `erupt`, with the
///   triple's re-targeting (`retarget`);
/// - `.HandleGeyserColumn @ 1006cf7c` (M l. 59731–59917) — `column`;
/// - `.HandleGeyserSegSprite @ 10060cd8` (M l. 53891–53897, empty) — `handleSegment`;
/// - `.KillBox`'s cleanup of the block (M l. 61502–61517) — `BoxSprite.killBox`.
/// The segment's Effect-Setup arm is `EffectSprite.setup`'s; the hurts are `HitPlayerSprite`'s (the head in the Box arm,
/// the segment in the Effect test). No sound: the only audio-shaped call, `CalcStereoVolume` at eruption start, has its
/// result discarded (§6).
/// §9 (b) as read: NR 2 — `.IdleToActiveSprite` runs no Setup and `.MTKillSprite` frees nothing, so the block idles with
/// the record (`IdleSprites` keeps the slot whole); NR 3 — kinds 3 / 4 are built as read, their base face indexing past
/// the 12-face cache draws nothing (◇, unplaced); NR 4 — p4 is stored to `+0xa6` and overwritten by the phase before any
/// read.
public enum Geyser {
    /// The runtime base / segment type, the triple's, the head's.
    public static let base: Int16 = 0x5a0
    public static let triple: Int16 = 0x5a5
    public static let head: Int16 = 0x5a9
    /// The placed bases 1440…1448 (1449 takes the head arm, tested first).
    public static let placed: ClosedRange<Int16> = 0x5a0...0x5a8
    /// The three cache sets of `.InitBoxSprite` (M l. 58813–58815): the base 1440 (`_DAT_100a0a1c`, 12 × 24×16, 4 per
    /// row), the head 1441 (`_DAT_100a0a18`, 6 × 48×32), the segment 1442 (`_DAT_100a0a14`, 6 × 20×32).
    public static let baseSet: Int16 = 0x5a0
    public static let headSet: Int16 = 0x5a1
    public static let segmentSet: Int16 = 0x5a2
    /// The eruption factor, the double at `0x100a1ae0`; the triple's floor and share, `0x100a1ad0` / `0x100a1ad8`.
    static let rate = 0.12, floorHeight = 50.0, share = 0.33

    @inline(__always) static func h(_ v: Int) -> Int { Int(Int16(truncatingIfNeeded: v)) }

    /// The geyser arm of `.SetupBoxSprite` for a placed 1440…1448 (`SetupFaces` calls it for the class; the Box head and
    /// tail are `BoxSprite.setup`'s, which leaves the geyser fields alone): the three cache marks (`CachedFaces`),
    /// SetRect(0, 2, 0x18, 0x18), `+0x1f8 = 0`, one-way, gravity 0, layer 0, `+0x189 = 1`, `+0x150 = y`; the record's p1
    /// << 8 (0 → 0x6400) to `+0x154`, `+0xf4`, `+0x16c`; p2 → `+0x158` and p3 → `+0x15c` (0 → 60 each); p4 → `+0xa6`;
    /// `+0x164 = +0x168 = 0`; the idle pads `+0x1cc = (u32)+0x154 >> 8` (i16), `+0x1ca = +0x1c8 = 64`; `+0x46 = R(4)`; the
    /// block (`AllocateGameMem(0x44)`); then below 0x5a5 kind = type − 0x5a0, `+0x170 = 0`, type 0x5a0; else kind = type
    /// − 0x5a5, `+0x170 = 1`, type 0x5a5, `+0xac = −1` and the two children `MTNewSprite(0x5a0, x + 0x48 / x + 0x90, y,
    /// layer, rec index, .SetupBoxSprite)` → `+0x1d4` / `+0x1d8`, each `+0x188 = 1`, the second `+0xac = −1`. The record
    /// read is the live one at `+0x48` — the children's too (`.MTNewSprite` stores it before their Setup), so they read
    /// the parent's params but are kind 0 whatever its kind (as read).
    /// - Returns: the children (`SetupFaces.Entry.children`, inserted before the parent); the parent's `siblings` hold
    ///   their indices into it.
    public static func setup(_ s: inout SpriteSlot, record p: Placement, level: LevelFile,
                             rng: inout FastRand) -> [SpriteSlot] {
        BoxSprite.setup(&s, record: p, level: level)
        s.hotRect = BoxSprite.rect(0, 2, 0x18, 0x18)
        s.hasTileHit = false
        s.oneWay = true
        s.gravity = 0
        s.layer = 0
        s.noWriteBack189 = true
        s.geyserBaseY = Int32(Int16(truncatingIfNeeded: s.y))
        var target = Int32(p.p1) << 8
        if target == 0 { target = 0x6400 }
        s.geyserTarget = target
        s.geyserFall = target
        s.geyserBaseTarget = target
        s.geyserOn = p.p2 == 0 ? 0x3c : Int32(p.p2)
        s.geyserOff = p.p3 == 0 ? 0x3c : Int32(p.p3)
        s.counterA6 = p.p4
        s.geyserHeight = 0
        s.geyserVelocity = 0
        s.margins.top = Int(Int16(truncatingIfNeeded: UInt32(bitPattern: target) >> 8))
        s.margins.right = 0x40
        s.margins.left = 0x40
        s.phase = rng.next(4)
        s.geyserColumn = SpriteSlot.GeyserBlock()
        let t = s.type
        guard triple <= t else {
            s.geyserKind = Int32(t) - 0x5a0
            s.geyserTriple = 0
            s.type = base
            return []
        }
        s.geyserKind = Int32(t) - 0x5a5
        s.geyserTriple = 1
        s.type = triple
        s.classWordAC = -1
        func child(_ dx: Int) -> SpriteSlot {
            var k = SpriteSlot(type: base, x: h(s.x + dx), y: s.y, recordIndex: s.recordIndex, layer: s.layer)
            _ = setup(&k, record: p, level: level, rng: &rng)
            k.recordIndex = s.recordIndex                    // `.MTNewSprite` re-stores `+0x48` after the Setup
            return k
        }
        var first = child(0x48)
        first.keepRecord = true
        var second = child(0x90)
        second.keepRecord = true
        second.classWordAC = -1
        s.siblings.first = 0
        s.siblings.second = 1
        return [first, second]
    }

    /// `MTNewSprite(0x5a9, x, y, 0xb, −1, .SetupBoxSprite)` (M l. 59785): the Box head stores layer 2 before the insert,
    /// then the head arm (`BoxSprite.setup`). Nil with no free record (Ruling 16).
    static func newHead(_ w: SpriteWorld, x: Int, y: Int) -> Int? {
        let none = Placement(index: -1, flag: 0, byte1: 0, type: head, p1: 0, p2: 0, p3: 0, p4: 0, y: 0, x: 0)
        return w.newSprite(type: head, x: x, y: y, layer: 0xb, handler: .box) { s in
            s.x = s.oldPosition.x
            s.y = s.oldPosition.y
            BoxSprite.setup(&s, record: none, level: w.level)
        }
    }

    /// `.HandleGeyserSegSprite @ 10060cd8` (M l. 53891–53897): empty — the column moves and faces the segments.
    public static func handleSegment(world w: SpriteWorld, id: Int) {}

    /// The eruption arm (`LAB_1006df20`, M l. 60379–60483), for the runtime types 0x5a0 and 0x5a5:
    /// - `+0x46` + 1, past 7 → 0; face = cache 1440 entry (`+0x46 >> 1`) + 4·kind — past entry 11 (kinds 3 / 4) nothing
    ///   (◇ NR 3);
    /// - `+0xa6 = C mod (on + off + 1)` with C the level frame counter `*_DAT_1009fd98` (`divwu`, unsigned; i16 store) —
    ///   this discards p4 (NR 4);
    /// - rising (`+0xa6 < on`): v = trunc(0.12·(`+0x154` − h)), capped at 0x600, h += v, `+0xf4 = +0x154` (the
    ///   `CalcStereoVolume` at `+0xa6 == 0` with `+0xac ≠ −1` is dead: no sound); falling: v = trunc(0.12·(h − `+0xf4`)),
    ///   > −0x100 → −0x100, < −0x700 → −0x700, h += v; then h < 0 → 0;
    /// - the triple while rising: `retarget`; then `column`.
    /// A period of 0 (on + off = −1, no placement) would divide by zero (`divwu`, undefined): the quotient is taken as 0.
    static func erupt(_ w: SpriteWorld, id: Int, lights: inout LightTable, effects: Int16) {
        guard let s0 = w.active.record(id: id) else { return }
        let C = UInt32(bitPattern: w.frameCounter)
        let n = UInt32(bitPattern: s0.geyserOn &+ s0.geyserOff &+ 1)
        let q = n == 0 ? 0 : C / n
        var rising = false
        w.active.update(id: id) { s in
            s.phase &+= 1
            if 7 < s.phase { s.phase = 0 }
            let cell = Int(s.phase >> 1) + Int(s.geyserKind) * 4
            s.face = (0..<12).contains(cell) ? FaceRef(pict: baseSet, index: cell, set: .encoded) : nil
            s.counterA6 = Int16(truncatingIfNeeded: C) &- Int16(truncatingIfNeeded: q) &* Int16(truncatingIfNeeded: n)
            if Int32(s.counterA6) < s.geyserOn {
                rising = true
                let v = Int32(rate * Double(s.geyserTarget &- s.geyserHeight))
                s.geyserVelocity = min(v, 0x600)
                s.geyserHeight &+= s.geyserVelocity
                s.geyserFall = s.geyserTarget
            } else {
                var v = Int32(rate * Double(s.geyserHeight &- s.geyserFall))
                if -0x100 < v { v = -0x100 }
                if v < -0x700 { v = -0x700 }
                s.geyserVelocity = v
                s.geyserHeight &+= v
            }
            if s.geyserHeight < 0 { s.geyserHeight = 0 }
        }
        if s0.type == triple && rising { retarget(w, id: id) }
        column(w, id: id, lights: &lights, effects: effects)
    }

    /// The triple's re-targeting (M l. 60425–60481), rising only: for its own head and each child's (`+0x1d4`, `+0x1d8`
    /// → their block's head), ridden this frame (`+0x186`) by a rider (`+0xe0`) that is not the player
    /// (`*_DAT_1009fdd8`) → covered, the flag cleared; B = `+0x16c`, L = trunc(max(50.0, 0.33·B)), c = the covered count;
    /// each column's `+0x154` = L when covered, else B + c·(B − L). A missing child (no free record at Setup) is skipped
    /// (the original stores through 0).
    static func retarget(_ w: SpriteWorld, id: Int) {
        guard let s = w.active.record(id: id) else { return }
        func covered(_ headID: Int?) -> Bool {
            guard let hd = headID, let hs = w.active.record(id: hd), hs.ridingLatch, hs.rider != w.playerID
            else { return false }
            w.active.update(id: hd) { $0.ridingLatch = false }
            return true
        }
        let kids = [s.siblings.first, s.siblings.second]
        let own = covered(s.geyserColumn?.head)
        let cover = kids.map { k in covered(k.flatMap { w.active.record(id: $0) }?.geyserColumn?.head) }
        let c = Int32((own ? 1 : 0) + cover.filter { $0 }.count)
        let B = s.geyserBaseTarget
        let d = share * Double(B)
        let L = Int32(floorHeight < d ? d : floorHeight)
        let T = B &+ c &* (B &- L)
        w.active.update(id: id) { $0.geyserTarget = own ? L : T }
        for (k, isCovered) in zip(kids, cover) {
            guard let k else { continue }
            w.active.update(id: k) { $0.geyserTarget = isCovered ? L : T }
        }
    }

    /// `.HandleGeyserColumn(base) @ 1006cf7c` (M l. 59731–59917), with h = `+0x164`, v = `+0x168`, (x, y) = (`+0xc`,
    /// `+0xa`):
    /// - h < 1: the head (`+0xe9 = 1`) and every segment (`+0xe9 = 1`, face 0) killed, their slots cleared; `+0x1c6 = 1`;
    /// - else `+0x1c6 = 0`; n = (h_px + 31) >> 5; the head: absent → `MTNewSprite(0x5a9, x − 12, y, 0xb, −1,
    ///   .SetupBoxSprite)`, face 0; present → `+0x46` + 1 (past 11 → 0), face cache 1441 entry `+0x46 >> 1`; solid on all
    ///   sides (`+0x185 = 0`) when h ≤ 0x1000 ∧ v > 0, else one-way; at (x − 12, y − h_px − 4); kind copied; head y > y − 8
    ///   → face 0; tint `+0xb8`: kind 1 0x10017, 0 → 0, 2 → 0x1000c, other kinds unchanged; head face 0 (or no head) → n 0;
    /// - segments i = 0…15: i < n → R(3) drawn; absent → `MTNewSprite(0x5a0, x + 1, y, 1, −1, .SetupEffectSprite)`; y −
    ///   22 − 32·i, face cache 1442 entry (head `+0x46 >> 1`), kind and the head's tint copied, the top one `+0x1bc` = 32·n
    ///   − h_px (others 0); the spray while the column rect (x, y − h_px, x + 64, y) meets the view (h, v, h + 608, v +
    ///   384) (`PTR_DAT_1009fe78`): R(3) + 3 tries of r = R(32), r ≥ `+0x1bc` → R(100) < 0x33 ? (x + 10 − R(5), −40 −
    ///   R(100)) : (x + 14 + R(5), 40 + R(100)), vy = 200 − R(1000) − v, `.NewParticle(kind + 200, 0xbe, (seg y + r, px),
    ///   4, vx, vy, R(10), 1)`; i ≥ n → killed (`+0xe9 = 1`, face 0) and cleared;
    /// - the head's spray, every frame with a head: R(6) + 10 + head y, R(4) dropped, R(100) < 0x33 ? (x + 12 − R(12), −70
    ///   − R(170)) : (x + 12 + R(12), 70 + R(170)), vy = 250 − R(1300) − v, the same call.
    /// A piece `.MTNewSprite` could not make (no free record) is skipped past its draw (Ruling 16; the original writes
    /// through 0).
    static func column(_ w: SpriteWorld, id: Int, lights: inout LightTable, effects: Int16) {
        guard let s = w.active.record(id: id), var block = s.geyserColumn else { return }
        if s.geyserHeight < 1 {
            if let hd = block.head {
                w.active.update(id: hd) { $0.killCount = 1 }
                block.head = nil
            }
            for i in 0..<16 {
                guard let g = block.segments[i] else { continue }
                w.active.update(id: g) { c in
                    c.killCount = 1
                    c.face = nil
                }
                block.segments[i] = nil
            }
            w.active.update(id: id) { c in
                c.mayIdle = true
                c.geyserColumn = block
            }
            return
        }
        let x = h(s.x), y = h(s.y)
        let hpx = Int(s.geyserHeight >> 8)
        let v = s.geyserVelocity
        w.active.update(id: id) { $0.mayIdle = false }
        var n = Int(Int16(truncatingIfNeeded: (hpx + 0x1f) >> 5))
        // A head that left the active list while the block still held its id would not be re-made here (the original
        // writes through the stale pointer); nothing kills or idles a head but this routine and `.KillBox` — HP 600, not
        // in the idle table.
        if let hd = block.head {
            w.active.update(id: hd) { c in
                c.phase &+= 1
                if 0xb < c.phase { c.phase = 0 }
                c.face = FaceRef(pict: headSet, index: Int(c.phase >> 1), set: .encoded)
            }
        } else {
            block.head = newHead(w, x: h(x - 0xc), y: y)
            if let hd = block.head { w.active.update(id: hd) { $0.face = nil } }
        }
        if let hd = block.head {
            let kind = s.geyserKind
            w.active.update(id: hd) { c in
                c.oneWay = !(s.geyserHeight < 0x1001 && 0 < v)
                c.x = h(x - 0xc)
                c.y = h(y - Int(Int16(truncatingIfNeeded: UInt32(bitPattern: s.geyserHeight) >> 8)) - 4)
                c.geyserKind = kind
                if y - 8 < c.y { c.face = nil }
                if kind == 1 {
                    c.mode = 0x10017
                } else if kind < 1 {
                    if -1 < kind { c.mode = 0 }
                } else if kind < 3 {
                    c.mode = 0x1000c
                }
            }
        }
        let headSlot = block.head.flatMap { w.active.record(id: $0) }
        if headSlot?.face == nil { n = 0 }
        let view = IdleSprites.Rect(top: w.player.scrollV, left: w.player.scrollH, bottom: w.player.scrollV + 0x180,
                                    right: w.player.scrollH + 0x260)
        let span = IdleSprites.Rect(top: h(y - hpx), left: x, bottom: y, right: h(x + 0x40))
        for i in 0..<16 {
            guard i < n else {
                if let g = block.segments[i] {
                    w.active.update(id: g) { c in
                        c.killCount = 1
                        c.face = nil
                    }
                    block.segments[i] = nil
                }
                continue
            }
            let tries = Int(Int16(truncatingIfNeeded: Int(w.rng.next(3)) + 3))
            if block.segments[i] == nil {
                block.segments[i] = EffectSprite.spawn(w, type: base, x: h(x + 1), y: y, layer: 1, effects: effects,
                                                       lights: &lights)
            }
            guard let g = block.segments[i], let hs = headSlot else { continue }
            let clip = i == n - 1 ? Int(Int16(truncatingIfNeeded: (n << 5) - hpx)) : 0
            w.active.update(id: g) { c in
                c.y = h(y - 0x16 - 0x20 * i)
                c.face = FaceRef(pict: segmentSet, index: Int(hs.phase >> 1), set: .encoded)
                c.geyserKind = s.geyserKind
                c.mode = hs.mode
                c.clip.top = clip
            }
            guard span.intersects(view), let seg = w.active.record(id: g) else { continue }
            for _ in 0..<tries {
                let r = Int(w.rng.next(0x20))
                guard Int(Int16(truncatingIfNeeded: seg.clip.top)) <= r else { continue }
                let px: Int, vx: Int
                if w.rng.next(100) < 0x33 {
                    px = h(x + 10 - Int(w.rng.next(5)))
                    vx = -0x28 - Int(w.rng.next(100))
                } else {
                    px = h(x + Int(w.rng.next(5)) + 0xe)
                    vx = Int(w.rng.next(100)) + 0x28
                }
                let vy = Int(200 - Int32(w.rng.next(1000)) &- v)
                let delay = Int(w.rng.next(10))
                w.particles.newParticle(kind: Int(s.geyserKind) + 200, gravity: 0xbe, v: h(r + seg.y), h: px, shape: 4,
                                        vx: vx, vy: vy, delay: delay, mode: 1)
            }
        }
        if let hs = block.head.flatMap({ w.active.record(id: $0) }) {
            let a = Int(w.rng.next(6))
            _ = w.rng.next(4)
            let px: Int, vx: Int
            if w.rng.next(100) < 0x33 {
                px = h(x + 0xc - Int(w.rng.next(0xc)))
                vx = -0x46 - Int(w.rng.next(0xaa))
            } else {
                px = h(x + Int(w.rng.next(0xc)) + 0xc)
                vx = Int(w.rng.next(0xaa)) + 0x46
            }
            let vy = Int(0xfa - Int32(w.rng.next(0x514)) &- v)
            let delay = Int(w.rng.next(10))
            w.particles.newParticle(kind: Int(s.geyserKind) + 200, gravity: 0xbe, v: h(a + 10 + hs.y), h: px, shape: 4,
                                    vx: vx, vy: vy, delay: delay, mode: 1)
        }
        w.active.update(id: id) { $0.geyserColumn = block }
    }

    /// `.KillBox`'s geyser part (M l. 61502–61517), for a dying 0x5a0…0x5a8 with a block: each of the 16 segments
    /// `+0xe9 = 1` and its slot cleared, then the head likewise.
    static func killColumn(_ w: SpriteWorld, id: Int) {
        guard let s = w.active.record(id: id), (0x5a0..<0x5a9).contains(s.type), var block = s.geyserColumn else { return }
        for i in 0..<16 {
            guard let g = block.segments[i] else { continue }
            w.active.update(id: g) { $0.killCount = 1 }
            block.segments[i] = nil
        }
        if let hd = block.head {
            w.active.update(id: hd) { $0.killCount = 1 }
            block.head = nil
        }
        w.active.update(id: id) { $0.geyserColumn = block }
    }
}
