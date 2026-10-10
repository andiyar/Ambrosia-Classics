import Foundation

/// The fields of one 0x1fc-byte sprite record (`.MTNewSprite @ 10033060` table at `_DAT_100a01dc`, 700 entries) that
/// Phase 1 reads: what the class Setup leaves (`SetupFaces`) and what `.WrapDrawSprites @ 100144c8` reads per sprite
/// (draw-effects §1.1; physics §0 / §0.1 for the offsets). Defaults are `.MTNewSprite`'s `MemoryClear` + `.InitSprite
/// @ 1003d3bc` (decompile l. 35566–35688): `+0x88 = 1`, `+0x1c6 = 1`, clips 0 / 32000 / 32000 / 0, scale `+0x1ae =
/// 0x100` (and its last-frame copy `+0x1b0`), everything else 0. The still counter `+0x19c` (`.WrapDrawSprites`
/// `100145cc..100145f4`) has no reader among the routines Phase 1 builds and is not kept.
public struct SpriteSlot: Equatable, Sendable {
    /// The idle-test margins `+0x1c8` left, `+0x1ca` right, `+0x1cc` top, `+0x1ce` bottom (triggers-background-2 §8.3).
    public struct Margins: Equatable, Sendable {
        public var left: Int
        public var right: Int
        public var top: Int
        public var bottom: Int

        public init(left: Int = 0, right: Int = 0, top: Int = 0, bottom: Int = 0) {
            self.left = left; self.right = right; self.top = top; self.bottom = bottom
        }
    }

    /// Identity in the `ActiveList` (the original's record pointer); assigned by `ActiveList.insert`.
    public internal(set) var id: Int = 0
    /// `+0x04`.
    public var type: Int16
    /// `+0x0c` / `+0x0a`: the face cell's top-left in world px.
    public var x: Int
    public var y: Int
    /// `+0x48`: the placement record (−1 = none).
    public var recordIndex: Int16
    /// `+0x80`: the active-list sort key (read at insertion only; physics §0).
    public var layer: Int32
    /// `+0xc0`: the face (nil = 0, not drawn).
    public var face: FaceRef?
    /// `+0xb8`: the draw-effect word `mode << 16 | sub`.
    public var mode: UInt32 = 0
    /// `+0x17e`: the blitter's horizontal mirror.
    public var mirrored = false
    /// `+0x88`: the light-overlay pass gate.
    public var lightOverlay = true
    /// `+0x89`: dynamic lighting (`.WrapDrawSprites` rewrites `+0xb8` from the light map).
    public var dynamicLight = false
    /// `+0x1c6`: may go idle off-screen.
    public var mayIdle = true
    /// `+0x9a`: the light slot the Setup's `.AddLight` returned (`.InitSprite`'s 0xffff = −1, none); the Handles'
    /// `.ChangeLightFace` target.
    public var light: Int16 = -1
    /// `+0x46`: the Handle's animation counter.
    public var phase: Int16 = 0
    /// The Setups' `FastRand` draws (F1; plan "F1 ⚑ FastRand sites"), kept though no Phase-2 routine reads them yet.
    /// `+0x112` (i16): "slipperiness" / the `.WallBounce` kick (pickups-boxes field table).
    public var slip: Int16 = 0
    /// `+0x114` (i16): friction — a Bonus's vx decays by it per frame (pickups-boxes field table).
    public var friction: Int16 = 0
    /// `+0x14c` (i32): the class word — Bonus light-flicker timer (pickups-boxes §1.1), Walker decision distance
    /// (enemies-ground §3.1).
    public var classTimer: Int32 = 0
    /// `+0x154` (i32): Walker `1000 + FastRand(400)` (enemies-ground §3.1: no reader in Walker code).
    public var classWord154: Int32 = 0
    /// `+0xf0` (i32): Walker (goblin) voice pitch `2·FastRand(0x5fff) + 0xbfff` (enemies-ground §3).
    public var voicePitch: Int32 = 0
    /// `+0x1c8..+0x1ce`.
    public var margins = Margins()
    /// `+0x1b6` left / `+0x1b8` right / `+0x1ba` bottom / `+0x1bc` top.
    public var clip = SpriteClip(left: 0, right: 32000, bottom: 32000, top: 0)
    /// `+0x1aa` rotation (degrees) / `+0x1ae` scale (0x100 = 1.0).
    public var rotation: Int16 = 0
    public var scale: Int16 = 0x100
    /// `+0x11c` water contact (0 in Phase 1).
    public var waterRow: Int32 = 0
    /// `+0xe9` kill request.
    public var dead = false
    /// `+0x1b3` burning (read by `.WrapEraseSprites`).
    public var burning = false
    /// Last frame's copies `.WrapDrawSprites` writes after each sprite (`+0xc8` face, `+0xc6`/`+0xc4` x/y, `+0x17f`,
    /// `+0xbc` mode, `+0x1ac`/`+0x1b0` rotation/scale, `+0x124` water row) — read by `.WrapEraseSprites`.
    public var previous: SpriteDraw?
    public var previousRotation: Int16 = 0
    public var previousScale: Int16 = 0x100
    public var previousWaterRow: Int32 = 0

    public init(type: Int16, x: Int, y: Int, recordIndex: Int16 = -1, layer: Int32 = 0, face: FaceRef? = nil) {
        self.type = type
        self.x = x
        self.y = y
        self.recordIndex = recordIndex
        self.layer = layer
        self.face = face
    }

    /// `.WrapDrawSprites` step 4's `+0x89` arm (raw `1001472c..100147bc`): with dynamic light and a face,
    /// L = `.GetLightTile(cx >> 5, cy >> 5)` (cx/cy = the hot-rect centre `+0x10`/`+0xe`) and F = `.GetFakeLight`;
    /// both < 1 → `+0xb8 = 0`, else `+0xb8 = 0xc0000 + L·0x100 + F` (`rlwinm 8; addis 0xc` — L = −1 with F ≥ 1 gives
    /// `0xbff00 + F`, mode 0xb). The result is written back to `+0xb8` and returned; without `+0x89` the stored word.
    public mutating func applyDynamicLight(lightTile L: Int, fakeLight F: Int) -> UInt32 {
        guard dynamicLight, face != nil else { return mode }
        if L < 1 && F < 1 {
            mode = 0
        } else {
            mode = UInt32(truncatingIfNeeded: L * 0x100 + 0xc0000 + F)
        }
        return mode
    }

    /// `.WrapDrawSprites`' tail for every sprite on the list, drawn or not (`100149a4..10014a14`): `+0xc8 ← +0xc0`,
    /// `+0xc6`/`+0xc4 ← +0xc`/`+0xa`, `+0xbc ← +0xb8`, `+0x1ac ← +0x1aa`, `+0x1b0 ← +0x1ae`, `+0x124 ← +0x11c`,
    /// `+0x17f ← +0x17e` (the fixed-point and velocity copies are not kept).
    public mutating func recordDrawn() {
        previous = face.map { SpriteDraw(face: $0, x: x, y: y, mode: mode, mirrored: mirrored, clip: clip,
                                         lightOverlay: lightOverlay, waterRow: Int(waterRow)) }
        previousRotation = rotation
        previousScale = scale
        previousWaterRow = waterRow
    }

    /// What `.WrapDrawSprites` hands the blitters for this sprite: nil when `+0xe9` is set or `+0xc0` is 0 (step 1,
    /// `1001452c`, `10014538`). The effective mode is the stored `+0xb8` (call `applyDynamicLight` first for a `+0x89`
    /// sprite). The hurt flash (`+0xaa`, `+0x1b4`), the water kind `+0x128` and `+0x18c` are not kept: no Phase-1
    /// routine sets them (a flash would reach the blitter as mode 3 / 4, which it refuses).
    public var draw: SpriteDraw? {
        guard !dead, let face else { return nil }
        return SpriteDraw(face: face, x: x, y: y, mode: mode, mirrored: mirrored, clip: clip, lightOverlay: lightOverlay,
                          waterRow: Int(waterRow))
    }
}
