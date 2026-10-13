import Foundation

/// The rope block `+0x9c` (`.SetupRopeSegArray` M l. 71245–71455: `.AllocateGameMem(0x4130)`, platforms-ropes-radial
/// §3.2). Its presence also stands for `+0x1e8 = .GetRopeHeight` (TOC `_DAT_100a0ce4`), which the same routine stores:
/// a rope whose first Handle has not run has neither.
public struct RopeBlock: Equatable, Sendable {
    /// `+0x00..+0xff`: the segment sprites, one per seg (`.MakeRopeSegSprites`; nil where `.MTNewSprite` found no
    /// record). `+0x100` / `+0x104`: the two end sprites, never given a face.
    public var segments: [Int?] = []
    public var ends: [Int?] = [nil, nil]
    /// `+0x108` base (static) and `+0x2108` dyn (dynamic) sag samples, i32 in 1/256 px, 0x800 each.
    public var base = [Int32](repeating: 0, count: RopeBlock.samples)
    public var dyn = [Int32](repeating: 0, count: RopeBlock.samples)
    /// `+0x4108` the left end height (always 0), `+0x410a` dy = p4 − p2, `+0x410c` seg.
    public var h1: Int16 = 0
    public var dy: Int16 = 0
    public var seg: Int16 = 0
    /// `+0x4114` rest sag, `+0x4118` ridden max (i32, 1/256 px).
    public var restSag: Int32 = 0
    public var riddenMax: Int32 = 0
    /// `+0x411c` the ridden curve's exponent, `+0x4120` the decay, `+0x4124` the ease (f32).
    public var exponent: Float = 0
    public var decay: Float = 0
    public var ease: Float = 0
    /// `+0x4128`: the segment face set (PICT 0x28a / 0x28c / 0x292, 30 faces). `+0x410e`, `+0x4110` and the second face
    /// `+0x412c` are write-only (platforms-ropes-radial §3.2) and not kept.
    public var faces: Int16 = 0

    public static let samples = 0x800

    /// A sample store as the original makes it; an index outside the block (a reversed rope's negative `+0x46` and
    /// span, platforms-ropes-radial §3.6 — heap writes before the block in the original) is dropped.
    mutating func set(_ a: WritableKeyPath<RopeBlock, [Int32]>, _ i: Int32, _ v: Int32) {
        guard 0 <= i, Int(i) < Self.samples else { return }
        self[keyPath: a][Int(i)] = v
    }

    func get(_ a: KeyPath<RopeBlock, [Int32]>, _ i: Int32) -> Int32 {
        guard 0 <= i, Int(i) < Self.samples else { return 0 }
        return self[keyPath: a][Int(i)]
    }
}

/// The Rope class, types 3020…3022 (W3; physics-sprites §8.2, platforms-ropes-radial §3): `.SetupRopeSprite @ 10083f20`,
/// `.SetupRopeSegArray @ 100843ac` (the first Handle), `.GetRopeHeight @ 10084264`, `.HandleRopeSprite @ 10084c1c`, the
/// segments (`.SetupRopeSegSprite`, `.HandleRopeSegSprite`, `.MakeRopeSegSprites`), the idle callbacks (`.RopeIdleize`,
/// `.RopeDeIdleize`) and `.RopeCollide @ 1004c82c` from the player's Handle. No rope is placed on levels 1–2 (census:
/// levels 3, 10, 11, 21, 22, 50–52, 70). Fields: span `+0x14c` = `classTimer`, nSeg `+0x150` = `classWord150`, the sag
/// `+0x154` = `classWord154`, animating `+0x170` = `classWord170`, the array built `+0x17c` = `setupDone`, the rider
/// offset `+0x46` = `phase`, ridden this frame `+0x186` = `ridingLatch`.
public enum RopeSprite {
    /// The segment sprite type (`.MakeRopeSegSprites` `MTNewSprite(600, …)`).
    public static let segmentType: Int16 = 600
    /// The types with a `.SetupRopeSegArray` arm (3023…3039 have none — seg 0 divides by zero at 100845f8; none is
    /// placed; `SetupFaces` refuses them).
    public static let types: ClosedRange<Int16> = 0xbcc...0xbce

    @inline(__always) static func h(_ v: Int) -> Int { Int(Int16(truncatingIfNeeded: v)) }
    @inline(__always) static func h32(_ v: Int32) -> Int32 { Int32(Int16(truncatingIfNeeded: v)) }
    /// C `/ 2` (`srawi 1; addze`): toward zero.
    @inline(__always) static func half(_ v: Int32) -> Int32 { v / 2 }

    /// `.SetupRopeSprite` (M l. 71078–71125): `.InitSprite`, `+0x84 = +0x86 = 0`, layer `+0x80 = 1`, the rope Handle,
    /// `+0x5c = 0`, `+0x1f8 = 0`, `+0xa6 = 3` then 4, HP 6, `+0x8a = 0`, `+0x188 = 1` (the record write-back flag — no
    /// Phase-2 reader, not kept), the position from the spawn copy, `+0x46 = 0`, idle margins `+0x1c8 = +0x1ca =
    /// (i16)(p3 − p1) / 2`, `+0x1ce = 0x40` (`+0x1d0 = 0x3c` has no reader, not kept), the idle callbacks `+0x54 =
    /// .RopeIdleize`, `+0x58 = .RopeDeIdleize` (`idleize` / `deIdleize`, dispatched on the rope Handle), `+0x17c = 0`.
    /// No face, no `FastRand`.
    public static func setup(_ s: inout SpriteSlot, record p: Placement) {
        s.layer = 1
        s.handler = .rope
        s.hasHit = false
        s.hasTileHit = false
        s.counterA6 = 4
        s.hp = 6
        s.currentApplies = false
        s.x256 = Int32(truncatingIfNeeded: s.x) << 8
        s.y256 = Int32(truncatingIfNeeded: s.y) << 8
        s.phase = 0
        let m = Int(Int16(truncatingIfNeeded: Int(p.p3) - Int(p.p1)) / 2)
        s.margins.left = m
        s.margins.right = m
        s.margins.bottom = 0x40
        s.setupDone = false
    }

    /// `.SetupRopeSegArray` (M l. 71245–71455), from the first Handle: `+0x17c = 1`; span `+0x14c` = p3 − p1; the type
    /// arm (seg / rest / ridden max / exponent / decay / ease / faces — 3020: 20, 0xe00, 0x1a00, 1.0, 0.4, 0.4, 0x28a;
    /// 3021: 20, 0xa00, 0x2c00, 1.4, …, 0x28c; 3022: 24, 0xc00, 0x1800, 1.4, …, 0x292); h1 0, dy = p4 − p2; nSeg = (span +
    /// seg/2) / seg, span = nSeg·seg (C division); `+0x154 = 0`; rect `SetRect(0, 0, span, dy)`, a negative bottom
    /// becomes the top, then top − 16, bottom + 40; `+0x1e8`; x += (span₀ − span)/2 − span/2, y −= dy/2, 24.8 from them;
    /// `.MakeRopeSegSprites`; base = h1 / dyn = 0 for j < (span + seg + 1)/2, base = dy (not shifted) / dyn = 0 for
    /// (span + seg)/2 ≤ j ≤ span + seg; m = `+0x46` = span/2; `+0x154` = rest·(m² − 0)/m² = base[m]; the static curve
    /// `(int)(sag·(1 − (|m − j|/side)^2.0) + h1·256·(span − j)/span + dy·256·j/span)` in f32 with a double `pow`
    /// (raw 10084840 `lfd f2` 2.0); base[span] = base[span + 1] = dy·256; `+0x46 = 0`; `+0x170 = 1`.
    static func setupSegArray(_ w: SpriteWorld, id: Int) {
        guard var s = w.active.record(id: id) else { return }
        let i = Int(s.recordIndex)
        guard w.records.indices.contains(i) else { return }
        let p = w.records[i]
        s.setupDone = true
        var span = Int32(p.p3) - Int32(p.p1)
        var b = RopeBlock()
        switch s.type {
        case 0xbcd: (b.restSag, b.riddenMax, b.exponent, b.faces, b.seg) = (0xa00, 0x2c00, 1.4, 0x28c, 0x14)
        case 0xbcc: (b.restSag, b.riddenMax, b.exponent, b.faces, b.seg) = (0xe00, 0x1a00, 1.0, 0x28a, 0x14)
        default: (b.restSag, b.riddenMax, b.exponent, b.faces, b.seg) = (0xc00, 0x1800, 1.4, 0x292, 0x18)
        }
        b.decay = 0.4
        b.ease = 0.4
        let seg = Int32(b.seg)
        b.h1 = 0
        b.dy = Int16(truncatingIfNeeded: Int(p.p4) - Int(p.p2))
        let nSeg = (span + seg / 2) / seg
        let span0 = span
        span = nSeg &* seg
        s.classWord150 = nSeg
        s.classTimer = span
        s.classWord154 = 0
        var r = IdleSprites.Rect(top: 0, left: 0, bottom: Int(b.dy), right: h(Int(span)))
        if r.bottom < 0 {
            r.top = r.bottom
            r.bottom = 0
        }
        r.top = h(r.top - 0x10)
        r.bottom = h(r.bottom + 0x28)
        s.hotRect = r
        s.x = h(h(s.x + Int(half(span0 &- span))) - Int(Int16(truncatingIfNeeded: half(span))))
        s.y = h(s.y - Int(half(Int32(b.dy))))
        s.x256 = Int32(s.x) << 8
        s.y256 = Int32(s.y) << 8
        s.rope = b
        w.active.update(id: id) { $0 = s }
        makeSegments(&w.active, ropeID: id)
        guard var t = w.active.record(id: id), var c = t.rope else { return }
        var j: Int32 = 0
        while Int32(Int16(truncatingIfNeeded: j)) < half(span &+ seg &+ 1) {
            c.set(\.dyn, j, 0)
            c.set(\.base, j, Int32(c.h1))
            j += 1
        }
        j = h32(half(span &+ seg))
        while j < span &+ seg &+ 1 {
            c.set(\.dyn, j, 0)
            c.set(\.base, j, Int32(c.dy))
            j += 1
        }
        let m = half(span)
        t.phase = Int16(truncatingIfNeeded: m)
        let d = abs(m - Int32(t.phase))
        let sag = SpriteSlot.divw(c.restSag &* (m &* m &- d &* d), m &* m)
        t.classWord154 = sag
        let mu = Int32(t.phase)
        let spanS = h32(span)
        c.set(\.base, mu, sag)
        let sag16 = Float(Int16(truncatingIfNeeded: sag))
        func curve(_ j: Int32, ratio: Float) -> Int32 {
            let pw = Float(pow(Double(ratio), 2.0))
            let left = Float(Int32(c.h1) << 8) * Float(spanS - j) / Float(spanS)
            let right = Float(Int32(c.dy) << 8) * Float(j) / Float(spanS)
            return Int32(sag16 * Float(1.0 - Double(pw)) + left + right)
        }
        var k: Int32 = 0
        while k < mu {
            c.set(\.base, k, curve(k, ratio: Float(mu - k) / Float(mu)))
            k += 1
        }
        k = mu
        while k < spanS {
            c.set(\.base, k, curve(k, ratio: Float(k - mu) / Float(spanS - mu)))
            k += 1
        }
        c.set(\.base, spanS, Int32(c.dy) << 8)
        c.set(\.base, spanS &+ 1, Int32(c.dy) << 8)
        t.phase = 0
        t.classWord170 = 1
        t.rope = c
        w.active.update(id: id) { $0 = t }
    }

    /// `.MakeRopeSegSprites` (M l. 71152–71193), from `setupSegArray` and `deIdleize`: with a block, for k < nSeg
    /// `MTNewSprite(600, x + k·seg, y, −1, −1, .SetupRopeSegSprite)` (`newRecord`), its `+0x1d4` = the rope; then the end
    /// sprites at (x − seg, y − seg/2) and (x + span, dy + y − seg/2), `+0x1d4` = the rope. `.SetupRopeSegSprite` (M l.
    /// 71128–71137): `.InitSprite`, the segment Handle, HP 400, `+0x188 = 1` (not kept). A full record table (700)
    /// leaves the slot nil (the original then stores through NULL).
    static func makeSegments(_ active: inout ActiveList, ropeID: Int) {
        guard let s = active.record(id: ropeID), var b = s.rope else { return }
        let seg = Int(b.seg)
        func make(_ x: Int, _ y: Int) -> Int? {
            guard active.sprites.count < SpriteWorld.recordCount else { return nil }
            var g = SpriteWorld.newRecord(type: segmentType, x: x, y: y, layer: -1, handler: .ropeSegment, record: -1) {
                $0.hp = 400
            }
            g.siblings.first = ropeID
            return active.insert(g)
        }
        let n = Int(s.classWord150)
        b.segments = n > 0 ? (0..<n).map { k in make(h(s.x) + k * seg, h(s.y)) } : []
        let up = Int(half(Int32(seg)))
        b.ends = [make(h(s.x) - seg, h(s.y) - up), make(h(s.x) + Int(s.classTimer), Int(b.dy) + (h(s.y) - up))]
        active.update(id: ropeID) { $0.rope = b }
    }

    /// `.GetRopeHeight(rope, i)` (M l. 71197–71241): i (i16) clamped to 0 … span − 1; at a multiple of seg
    /// `(i16)((dyn + base) >> 8)`, else the samples at ⌊i/seg⌋·seg and ⌈i/seg⌉·seg interpolated in f32 (`(1 − f)·lo +
    /// f·hi`, f = (i − lo)/seg), truncated, `>> 8`. 0 for a rope without a block (`+0x1e8` 0).
    public static func height(_ s: SpriteSlot, _ i: Int) -> Int16 {
        guard let b = s.rope else { return 0 }
        var v = Int32(Int16(truncatingIfNeeded: i))
        if v < 1 { v = 0 }
        let last = s.classTimer &- 1
        if last <= v { v = h32(last) }
        let seg = Int32(b.seg)
        guard seg != 0 else { return 0 }
        let lo = (v / seg) * seg
        let sumLo = b.get(\.dyn, lo) &+ b.get(\.base, lo)
        if v == lo { return Int16(truncatingIfNeeded: sumLo >> 8) }
        let hi = ((seg &+ v &- 1) / seg) * seg
        let sumHi = b.get(\.dyn, hi) &+ b.get(\.base, hi)
        let f = Float(v - lo) / Float(seg)
        return Int16(truncatingIfNeeded: Int32(Float(sumLo) * (1.0 - f) + Float(sumHi) * f) >> 8)
    }

    /// The segment table `.InitRopeSprite` builds (M l. 70982–71075): `_DAT_100a0d08[i] = (15 − i >> 1)·256` for
    /// i < 15, `_DAT_100a0d04[i] = (15 − (i − 14) >> 1)·256` for i ≥ 15 — the y offset of a segment with face index i
    /// is `−d08[i]` (i < 15) or `d04[i] − 0x1e00`.
    static func segmentOffset(_ i: Int) -> Int32 {
        i < 15 ? 0 &- Int32(15 - (i >> 1)) * 0x100 : Int32(15 - ((i - 14) >> 1)) * 0x100 - 0x1e00
    }

    /// `.HandleRopeSprite` (M l. 71506–71741): `+0xe9` / `+0x1b2` → return; `.StandardSpriteHandles`; `+0x17c` 0 →
    /// `setupSegArray`. While `+0x170`:
    /// - not ridden (`+0x186` 0): every dyn sample at a multiple of seg below span = `(int)((f32)dyn·decay)`, 0 if
    ///   unchanged; `+0x154 = (int)((f32)+0x154·decay)`;
    /// - ridden at i = `+0x46`: h = span/2, d = |h − i|, T = max·(h² − d²)/h²; `+0x154` < T → `(int)((T − sag)·ease +
    ///   sag)`, > T → `(int)−((sag − T)·ease − sag)`, each snapping to T within 0x100; dyn[i] = (i16)sag; dyn[j] at the
    ///   multiples of seg = `(int)(sag·(1 − ((i − j)/i)^p))` left of i, `(1 − ((j − i)/(span − i))^p)` from i to span,
    ///   p = `+0x411c` (raw 10084f34 → `pow` 10084f54); the multiples of seg in span … span + seg + 1 → 0;
    /// - the segments (M l. 71671–71737): for k < nSeg, s = (i16)((i16)Δdyn + (i16)Δbase) >> 8 between samples (k+1)·seg
    ///   and k·seg; s' = clamp(s, −14, 14); face index s' ≥ 0 ? s' : 14 + |s'| (cap 0x1d); `+0xc0` = the set's face;
    ///   offset `segmentOffset`, + (s − 14)·256 when s > 14; `+0xc = x + k·seg`, `+0x1c = y·256 + base + dyn +
    ///   offset`, `+0x14 = +0xc << 8`, `+0xa = +0x1c >> 8`.
    /// Then `+0x186 = 0` and `.StandardSpriteCleanup` (the rope has no face: width 0x80).
    public static func handle(world w: SpriteWorld, id: Int) {
        guard let s0 = w.active.record(id: id), !s0.dead, !s0.handleSkip else { return }
        w.standardSpriteHandles(id)
        if !s0.setupDone { setupSegArray(w, id: id) }
        guard var s = w.active.record(id: id) else { return }
        if s.classWord170 != 0, var b = s.rope {
            let span = s.classTimer
            let seg = Int32(b.seg)
            func multiple(_ j: Int32) -> Bool { seg != 0 && j == (j / seg) * seg }
            if !s.ridingLatch {
                var j: Int32 = 0
                while j < span {
                    if multiple(j) {
                        let v = b.get(\.dyn, j)
                        let n = Int32(Float(v) * b.decay)
                        b.set(\.dyn, j, v == n ? 0 : n)
                    }
                    j += 1
                }
                s.classWord154 = Int32(Float(s.classWord154) * b.decay)
            } else {
                let hh = half(span)
                let d = abs(hh &- Int32(s.phase))
                let T = SpriteSlot.divw(b.riddenMax &* (hh &* hh &- d &* d), hh &* hh)
                var sag = s.classWord154
                if sag < T {
                    sag = Int32(Float(T &- sag) * b.ease + Float(sag))
                    if abs(sag &- T) < 0x100 { sag = T }
                }
                if T < sag {
                    sag = Int32(-(Float(sag &- T) * b.ease - Float(sag)))
                    if abs(sag &- T) < 0x100 { sag = T }
                }
                s.classWord154 = sag
                let i = Int32(s.phase)
                let sag16 = h32(sag)
                let spanS = h32(span)
                b.set(\.dyn, i, sag16)
                func value(_ ratio: Float) -> Int32 {
                    let pw = Float(pow(Double(ratio), Double(b.exponent)))
                    return Int32(Float(sag16) * Float(1.0 - Double(pw)))
                }
                var j: Int32 = 0
                while j < i {
                    if multiple(j) { b.set(\.dyn, j, value(Float(i - j) / Float(i))) }
                    j += 1
                }
                j = i
                while j < spanS {
                    if multiple(j) { b.set(\.dyn, j, value(Float(j - i) / Float(spanS - i))) }
                    j += 1
                }
                j = spanS
                while j <= spanS &+ seg &+ 1 {
                    if multiple(j) { b.set(\.dyn, j, 0) }
                    j += 1
                }
            }
            s.rope = b
            w.active.update(id: id) { $0 = s }
            var x = h(s.x)
            var lo: Int32 = 0
            var y = b.get(\.dyn, 0) &+ b.get(\.base, 0) &+ Int32(h(s.y)) &* 0x100
            var k: Int32 = 0
            while k < s.classWord150 {
                let hi = lo &+ seg
                func d16(_ a: KeyPath<RopeBlock, [Int32]>) -> Int { Int(h32(b.get(a, hi))) - Int(h32(b.get(a, lo))) }
                let sRaw = Int16(truncatingIfNeeded: d16(\.dyn) + d16(\.base)) >> 8
                let sc = min(max(sRaw, -14), 14)
                let index = sc < 0 ? min(Int(-sc) + 14, 0x1d) : Int(sc)
                var offset = segmentOffset(index)
                if 14 < sRaw { offset &+= Int32(sRaw - 14) &* 0x100 }
                if Int(k) < b.segments.count, let g = b.segments[Int(k)] {
                    let gx = x, gy = y &+ offset, faces = b.faces
                    w.active.update(id: g) { c in
                        c.face = FaceRef(pict: faces, index: index, set: .encoded)
                        c.x = gx
                        c.y256 = gy
                        c.x256 = Int32(gx) << 8
                        c.y = Int(Int16(truncatingIfNeeded: gy >> 8))
                    }
                }
                x = h(x + Int(seg))
                lo = hi
                y = Int32(h(s.y)) &* 0x100 &+ b.get(\.dyn, lo) &+ b.get(\.base, lo)
                k += 1
            }
        }
        w.active.update(id: id) { $0.ridingLatch = false }
        w.standardSpriteCleanup(id, faceWidth: { _ in 0x80 })
    }

    /// `.HandleRopeSegSprite` (M l. 71141–71148): `.StandardSpriteHandles`, `.StandardSpriteCleanup` — no guards.
    public static func handleSegment(world w: SpriteWorld, id: Int, faceWidth: (FaceRef) -> Int) {
        w.standardSpriteHandles(id)
        w.standardSpriteCleanup(id, faceWidth: faceWidth)
    }

    /// `.RopeIdleize` (M l. 71458–71489), `+0x54` called by `.ActiveToIdleSprite` before the record is saved: with
    /// `+0x17c` and a block, `+0xe9 = 1` on each of the nSeg segments and the two ends, `+0x170 = 0`. // later: the
    /// `+0xe9` count-up of `.UpdateSprites` (Phase 3–5) kills them; until then they stay listed, undrawn.
    static func idleize(_ active: inout ActiveList, id: Int) {
        guard let s = active.record(id: id), s.setupDone, let b = s.rope else { return }
        var k = 0
        while k < Int(s.classWord150) {
            if k < b.segments.count, let g = b.segments[k] { active.update(id: g) { $0.dead = true } }
            k += 1
        }
        for e in b.ends.compactMap({ $0 }) { active.update(id: e) { $0.dead = true } }
        active.update(id: id) { $0.classWord170 = 0 }
    }

    /// `.RopeDeIdleize` (M l. 71492–71503), `+0x58` called by `.IdleToActiveSprite` after the record is restored: with
    /// `+0x17c` and a block, `.MakeRopeSegSprites`, `+0x186 = 1`, `+0x170 = 1`.
    static func deIdleize(_ active: inout ActiveList, id: Int) {
        guard let s = active.record(id: id), s.setupDone, s.rope != nil else { return }
        makeSegments(&active, ropeID: id)
        active.update(id: id) { c in
            c.ridingLatch = true
            c.classWord170 = 1
        }
    }

    /// `.RopeCollide(player) @ 1004c82c` (M l. 43863–43986), row 7 of `.HandlePlayerSprite` while not dying. For every
    /// listed sprite with the rope Handle (`PTR_PTR_100a04f0`) and type 0xbcc…0xbdf, when the player's centre `+0x10` is
    /// strictly inside the rope's x + rect left … x + rect right: i = cx − x, +7 facing right (`+0x17e` 0) / −7 left;
    /// no `+0x1e8` (no block yet) → **return** (the scan stops); surf = (i16)(y + `.GetRopeHeight(i)`).
    /// - Not on a rope last frame (`_DAT_100a0584` 0): grab when surf ≤ y + 16 < surf + 0x40 and the previous
    ///   `y − (vy >> 8) + 16` < surf: the jump counter `_DAT_100a0764 = 0`, the landing sound `.STPlay3DSoundRand(snd,
    ///   1, vol, player +0xe)` — 3022: `_DAT_100a0300[FastRand(3)]` = chaincreak 489…491, vol 0x69; else
    ///   `_DAT_100a0304[FastRand(3)]` = ropecreak 486…488, vol 0x5f (the sound init, M l. 39916–39926: snd 0x1e6…0x1eb);
    ///   the rate drawn at the call (plan Invariant 4).
    /// - On this rope last frame (`_DAT_100a0580`): the jump counter = 6, attached (no window test).
    /// - DOWN (action 3) → not attached (the landing sound has played).
    /// - Attached: the air counter `_DAT_100a0718 = 0`, `_DAT_100a0580` = the rope, `_DAT_100a0588 = 1`, `+0xa = surf −
    ///   16`, `+0x1c` from it, the rope's `+0x46 = i` (i16), `+0x186 = 1`; the step sound when the rope-walk counter
    ///   `_DAT_100a058c` is 1 or 8 and this is not the grab — 3022 vol 0x4b, else 0x41, the same tables; vy = 0.
    public static func collide(_ w: SpriteWorld, player pID: Int, keys: InputActions) {
        var cursor = w.active.sprites.first?.id
        while let rid = cursor {
            defer { cursor = w.active.next(after: rid) }               // `+0x68` at the loop's end
            guard let r = w.active.sprite(id: rid), r.handler == .rope, !r.handleCleared, 0xbcb < r.type,
                  r.type < 0xbe0, let p = w.active.record(id: pID) else { continue }
            let left = h(h(r.x) + r.hotRect.left), right = h(h(r.x) + r.hotRect.right)
            let cx = h(p.centre.x)
            guard left < cx, cx < right else { continue }
            var attach = false, grab = false
            var i = cx - h(r.x)
            i += p.mirrored ? -7 : 7
            guard r.rope != nil else { return }                         // `+0x1e8 == 0` → return
            let surf = h(h(r.y) + Int(height(r, i)))
            func creak(_ vol3022: Int16, _ volOther: Int16) {
                let k = w.rng.next(3)
                let tableBase: Int16 = r.type == 0xbce ? 489 : 486
                let vol = r.type == 0xbce ? vol3022 : volOther
                let pos = w.active.record(id: pID)?.centre
                w.player.cue(PlayerCue(call: .threeDRand, snd: tableBase + k, priority: 1, volume: vol,
                                       position: pos, rate: w.rng.soundRate()))
            }
            if !w.player.lastRope || rid != w.player.currentRope {
                if !w.player.lastRope {
                    let feet = h(p.y) + 0x10
                    if surf <= feet && feet < surf + 0x40 && (h(p.y) - Int(p.vy >> 8)) + 0x10 < surf {
                        w.player.jumpCounter = 0
                        attach = true
                        grab = true
                        creak(0x69, 0x5f)
                    }
                }
            } else {
                w.player.jumpCounter = 6
                attach = true
            }
            if keys.contains(.down) { attach = false }
            guard attach else { continue }
            w.player.airCounter = 0
            w.player.currentRope = rid
            w.player.rope = true
            w.active.update(id: pID) { s in
                s.y = h(surf - 0x10)
                s.y256 = Int32(s.y) << 8
            }
            w.active.update(id: rid) { c in
                c.phase = Int16(truncatingIfNeeded: i)
                c.ridingLatch = true
            }
            if (w.player.ropeWalk == 1 || w.player.ropeWalk == 8) && !grab { creak(0x4b, 0x41) }
            w.active.update(id: pID) { $0.vy = 0 }
        }
    }
}
