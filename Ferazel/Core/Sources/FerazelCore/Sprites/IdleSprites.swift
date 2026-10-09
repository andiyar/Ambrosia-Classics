import Foundation

/// The idle-sprite table at `0x100ac02c` (`r2 + 0x47ec`): 512 entries of 0x220 bytes (triggers-background-2 §8.3).
///
/// - `.AddIdleSprite @ 10007d8c` (decompile l. 4097): the first free entry of 512; the sprite is made with
///   `MTNewSprite(type, x, y, layer 1, record, setup)` — the class Setup runs — then `.ActiveToIdleSprite(i, 0)` saves
///   it and it is killed (`MTKillSprite`). Entry: `+0` used, `+4` the live sprite (0 = idle), `+8`/`+0xa`/`+0xc`
///   type/x/y, `+0xe` record, `+0x10..+0x17` the face rect, `+0x24..` the saved sprite bytes (`saved`).
/// - `.ActiveToIdleSprite @ 10007ed4` (l. 4162): face rect = face `+8..+0xf` (the opaque bounds) when `+0xc0` ≠ 0,
///   else `SetRect(0, 0, 0x40, 0x40)`; type/x/y from the live sprite; the sprite unlinked.
/// - `.IdleToActiveSprite @ 1000803c` (l. 4217): `MTNewSprite(type, x, y, saved +0x80, saved +0x48, setup 0)` — no
///   Setup runs — then the saved bytes are copied back (links kept); x/y from the entry.
/// - `.HandleIdleSprites @ 100081ac` (l. 4276): window = `SetRect(h − 24, v − 24, h + 632, v + 408)` ∪ the player's
///   hot rect (`+0x34` offset by its x/y), outset by 0x60 on every side; entries 0 … 510 (`100083e8 cmpwi r30,0x1ff` —
///   entry 511 is never scanned). An idle entry with type `+8` ≠ 0 activates when its test rect meets the window
///   (`SectRectFast`); an active one whose live sprite has `+0x1c6` ≠ 0 goes idle when its rect misses it. Test rect
///   = (x + face.left − m.left, y + face.top − m.top, x + face.right + m.right, y + face.bottom + m.bottom), margins
///   `+0x1c8..+0x1ce` (from the saved copy when idle, the live sprite when active): one rule both ways.
public struct IdleSprites: Equatable, Sendable {
    /// A QuickDraw rect in world px (top, left, bottom, right; half-open).
    public struct Rect: Equatable, Sendable {
        public var top: Int
        public var left: Int
        public var bottom: Int
        public var right: Int

        public init(top: Int, left: Int, bottom: Int, right: Int) {
            self.top = top; self.left = left; self.bottom = bottom; self.right = right
        }

        /// `SetRect(r, 0, 0, 0x40, 0x40)`: `.ActiveToIdleSprite`'s rect for a sprite without a face.
        public static let noFace = Rect(top: 0, left: 0, bottom: 0x40, right: 0x40)

        /// `SectRectFast` / `SectRect`: true when the intersection is not empty.
        public func intersects(_ o: Rect) -> Bool {
            max(top, o.top) < min(bottom, o.bottom) && max(left, o.left) < min(right, o.right)
        }

        /// `UnionRect`.
        public func union(_ o: Rect) -> Rect {
            Rect(top: min(top, o.top), left: min(left, o.left), bottom: max(bottom, o.bottom), right: max(right, o.right))
        }
    }

    public struct Entry: Equatable, Sendable {
        /// `+0x24..+0x21f`: the sprite as saved (type, x, y and record are the entry's `+8..+0xe`).
        public var saved: SpriteSlot
        /// `+0x10..+0x17`.
        public var faceRect: Rect
        /// `+4`: the live sprite's `ActiveList` id, nil while idle.
        public var activeID: Int?
    }

    public static let capacity = 0x200
    /// `.HandleIdleSprites` scans entries 0 ..< 0x1ff.
    public static let scanned = 0x1ff

    public private(set) var entries: [Entry?] = Array(repeating: nil, count: IdleSprites.capacity)

    public init() {}

    /// `.AddIdleSprite`'s table part, for a sprite whose Setup already ran (`SetupFaces`): the first free entry, or nil
    /// when all 512 are used (the original's `ReportDialog`).
    @discardableResult
    public mutating func add(_ sprite: SpriteSlot, faceRect: Rect) -> Int? {
        guard let k = entries.firstIndex(where: { $0 == nil }) else { return nil }
        var s = sprite
        s.id = 0
        entries[k] = Entry(saved: s, faceRect: faceRect, activeID: nil)
        return k
    }

    /// The `.HandleIdleSprites` window for view origin (h, v) (`PTR_DAT_1009fe78`).
    public static func window(h: Int, v: Int, playerHotRect: Rect?) -> Rect {
        var w = Rect(top: v - 0x18, left: h - 0x18, bottom: v + 0x198, right: h + 0x278)
        if let p = playerHotRect { w = w.union(p) }
        return Rect(top: w.top - 0x60, left: w.left - 0x60, bottom: w.bottom + 0x60, right: w.right + 0x60)
    }

    /// The test rect of a sprite at (x, y) with face rect `f` and margins `m`.
    public static func testRect(x: Int, y: Int, face f: Rect, margins m: SpriteSlot.Margins) -> Rect {
        Rect(top: y + f.top - m.top, left: x + f.left - m.left, bottom: y + f.bottom + m.bottom,
             right: x + f.right + m.right)
    }

    /// One `.HandleIdleSprites` pass. `faceRect` answers `.ActiveToIdleSprite`'s face-rect read for a live sprite
    /// going idle (its face's opaque bounds; nil face → `Rect.noFace` is applied here). Returns the entries activated
    /// and deactivated, in scan order.
    @discardableResult
    public mutating func handle(h: Int, v: Int, playerHotRect: Rect?, active: inout ActiveList,
                                faceRect: (FaceRef) -> Rect) -> (activated: [Int], deactivated: [Int]) {
        let window = Self.window(h: h, v: v, playerHotRect: playerHotRect)
        var on: [Int] = [], off: [Int] = []
        for i in 0..<Self.scanned {
            guard var e = entries[i] else { continue }
            if let id = e.activeID {
                guard let live = active.sprite(id: id) else { continue }
                guard live.mayIdle else { continue }
                let r = Self.testRect(x: live.x, y: live.y, face: e.faceRect, margins: live.margins)
                if !r.intersects(window) {
                    // `.ActiveToIdleSprite(i, 1)`.
                    e.faceRect = live.face.map(faceRect) ?? .noFace
                    var s = live
                    s.id = 0
                    e.saved = s
                    e.activeID = nil
                    active.remove(id: id)
                    entries[i] = e
                    off.append(i)
                }
            } else {
                guard e.saved.type != 0 else { continue }
                let r = Self.testRect(x: e.saved.x, y: e.saved.y, face: e.faceRect, margins: e.saved.margins)
                if r.intersects(window) {
                    // `.IdleToActiveSprite(i)`.
                    e.activeID = active.insert(e.saved)
                    entries[i] = e
                    on.append(i)
                }
            }
        }
        return (on, off)
    }
}
