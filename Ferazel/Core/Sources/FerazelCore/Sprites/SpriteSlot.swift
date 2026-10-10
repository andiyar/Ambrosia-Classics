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

    /// The occluder rect `+0x1be` xmin / `+0x1c0` xmax / `+0x1c2` ymax / `+0x1c4` ymin in world px (`.InitSprite`
    /// 32000 each; physics §0.1, adjudication A11), consumed by `.StandardSpriteCleanup`'s horizontal clip.
    public struct Occluder: Equatable, Sendable {
        public var left: Int16
        public var right: Int16
        public var bottom: Int16
        public var top: Int16

        public init(left: Int16 = 32000, right: Int16 = 32000, bottom: Int16 = 32000, top: Int16 = 32000) {
            self.left = left; self.right = right; self.bottom = bottom; self.top = top
        }
    }

    /// A point (`+0x10` x / `+0xe` y for the hot-rect centre).
    public struct Point: Equatable, Sendable {
        public var x: Int
        public var y: Int

        public init(x: Int = 0, y: Int = 0) { self.x = x; self.y = y }
    }

    /// The linked sprites `+0x1d4` / `+0x1d8` (`ActiveList` ids; nil = 0). `.StandardSpriteHandles` carries both with
    /// a ridden sprite's dx.
    public struct Siblings: Equatable, Sendable {
        public var first: Int?
        public var second: Int?

        public init(first: Int? = nil, second: Int? = nil) { self.first = first; self.second = second }
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

    // MARK: The physics record (plan S2, F2). Defaults are `.MTNewSprite`'s `MemoryClear` + `.InitSprite`.

    /// `+0x4c` the Handle (`.MTHandleSprites` calls it) — every class Setup installs one (plan S2 `SpriteHandler`).
    public var handler: SpriteHandler
    /// `+0x5c` ≠ 0: the sprite has a hit callback (`.MTCollideSprites` outer gate, `C.hit` in the player pass). No
    /// Phase-2 Setup before W1 sets it. // later: W1 platform, W2a/W2b background, W3 box/rope
    public var hasHit = false
    /// `+0x14` / `+0x1c`: x / y in 24.8 fixed point (`.MTNewSprite`: `x << 8`, `y << 8`).
    public var x256: Int32
    public var y256: Int32
    /// `+0x24` / `+0x2c`: vx / vy in 1/256 px per frame.
    public var vx: Int32 = 0
    public var vy: Int32 = 0
    /// `+0x110` (i16): gravity per frame.
    public var gravity: Int16 = 0
    /// `+0x34` (QuickDraw top, left, bottom, right in face-local px): the hot rect.
    public var hotRect = IdleSprites.Rect(top: 0, left: 0, bottom: 0, right: 0)
    /// `+0x3c..+0x42`: the hot rect offset by (x, y), built by `.CalcHotRect @ 10032614` during `.MTCollideSprites`.
    public var hotRectWorld = IdleSprites.Rect(top: 0, left: 0, bottom: 0, right: 0)
    /// `+0x44`: `+0x3c` built this collision pass (cleared for every sprite at the pass start).
    public var hotRectBuilt = false
    /// `+0x10` / `+0xe`: the hot-rect centre in world px (`.CalcCenterPos`, `.StandardSpriteCleanup`).
    public var centre = Point()
    /// `+0xcd` (u8): `.StandardSpriteHandles` copies `+0xce` into it; `.PlatformBounce` sets 1 on a landing.
    public var onSprite: UInt8 = 0
    /// `+0xce` (u8): the ground / surface kind under the sprite this frame (0 airborne, 3 = a sprite).
    public var groundKind: UInt8 = 0
    /// `+0xcf` (u8): ceiling hit (`.PlatformBounce` return 2).
    public var ceilingHit = false
    /// `+0xd0` (u8): landed on a one-way top.
    public var oneWayLanded = false
    /// `+0xd2` / `+0xd4` (i16): the left / right surface heights of a sloped top (`.InitSprite` −1000 each = flat).
    public var surfaceLeft: Int16 = -1000
    public var surfaceRight: Int16 = -1000
    /// `+0xd6` (i16): the slope of the top the sprite stands on (`.RectBounce`, `.PlatformBounce`; cleared by
    /// `.StandardSpriteCleanup`).
    public var slope: Int16 = 0
    /// `+0xd8` (i16): surface material (FG kind / 100), zeroed by `.StandardSpriteHandles`.
    public var material: Int16 = 0
    /// `+0xdc`: the sprite being ridden (an `ActiveList` id; nil = 0).
    public var ridden: Int?
    /// `+0xe0`: the rider (an `ActiveList` id; nil = 0).
    public var rider: Int?
    /// `+0x186` (u8): ridden this frame (`.PlatformBounce`, `.RopeCollide`; cleared by the owner's Handle).
    public var ridingLatch = false
    /// `+0x185` (u8): one-way top.
    public var oneWay = false
    /// `+0x138` (i16): push mass; `+0x13a` (i16): landing sag; `+0x13c` (i16): pusher factor (`.RectBounce`).
    public var pushMass: Int16 = 0
    public var sag: Int16 = 0
    public var pushForce: Int16 = 0
    /// `+0x120` (i32): last frame's water contact (`+0x11c` copied by `.StandardSpriteHandles`).
    public var lastWater: Int32 = 0
    /// `+0x128` (i16): water kind (BG kind − 200).
    public var waterKind: Int16 = 0
    /// `+0x118` (i16): the water-reset gate (`< 0x1d` → `.StandardSpriteHandles` runs the current and the
    /// `+0x11c` reset). Every writer stores 0 (enemies-water-cave §0.1).
    public var waterGate: Int16 = 0
    /// `+0x8a` (u8): the water current applies (`.InitSprite` 1; the player clears it while clinging).
    public var currentApplies = true
    /// `+0x94` (i16): the water-current ramp counter (0 … 33).
    public var currentRamp: Int16 = 0
    /// `+0x90` (i16): wind scale /256 (≤ 0 immune). `+0x92` (u8): in wind this frame. `+0x96` / `+0x98` (i16): the
    /// wind ramp counter / last impulse x.
    public var windScale: Int16 = 0
    public var inWind = false
    public var windRamp: Int16 = 0
    public var windLast: Int16 = 0
    /// `+0x140` (u8): water handled this frame.
    public var underwaterDone = false
    /// `+0x144` (i32): quicksand depth (`.HandleFlotation` kind 5); zeroed on leaving the water.
    public var quicksandDepth: Int32 = 0
    /// `+0x116` (i16): invulnerability frames.
    public var invulnerable: Int16 = 0
    /// `+0xaa` (i16): hurt-flash frames.
    public var flash: Int16 = 0
    /// `+0x1b4` (u8): the hurt flash uses mode 4 instead of 3.
    public var flashTable: UInt8 = 0
    /// `+0xa4` (i16): hit points.
    public var hp: Int16 = 0
    /// `+0x19e` / `+0x1a0` (i16): buoyancy / float-line offset (`.HandleFlotation`).
    public var buoyancy: Int16 = 0
    public var floatOffset: Int16 = 0
    /// `+0x130` (i32): cannon hold timer; negative = re-entry block, counted up by `.StandardSpriteHandles`.
    public var reentry: Int32 = 0
    /// `+0x180` (u8): radial wall-bounce latch, cleared every frame by `.StandardSpriteHandles`.
    public var radialLatch = false
    /// `+0x184` (u8): no collision with sprites of the same handler (`.MTCollideSprites`).
    public var sameHandlerExempt = false
    /// `+0x1b2` (u8): Handle skip — never the outer sprite of `.MTCollideSprites`.
    public var handleSkip = false
    /// `+0x1a2` (i16): burn-away row (≠ 0 → `.HandleBurn` from `.StandardSpriteCleanup`).
    public var burnRow: Int16 = 0
    /// `+0x1a6` / `+0x1a8` (i16): glow particle kind / glow chance (`.ParticleGlow` from `.StandardSpriteCleanup`).
    public var glowKind: Int16 = 0
    public var glowChance: Int16 = 0
    /// `+0x1be..+0x1c4`.
    public var occluder = Occluder()
    /// `+0x1d4` / `+0x1d8`.
    public var siblings = Siblings()
    // later: W1 — `radial: Radial?` (the `+0x198` block, `+0x187` has-radial); `Radial` is W1's type (plan S2).
    // later: W3 — `+0x1e8` the surface-height function (ropes, rope bridge); `.PlatformBounce` takes it as an argument.
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
        x256 = Int32(truncatingIfNeeded: x) << 8
        y256 = Int32(truncatingIfNeeded: y) << 8
        handler = SpriteHandler.forClass(type: type)
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

/// The Handle a sprite's `+0x4c` names (plan S2, LOCKED). `inert` = the Phase 4/5 classes (Bonus, enemies, buttons):
/// no Phase-2 Handle and no hit callback; still drawn, idled and erased. (The Bonus item-light twinkle Phase 1
/// built, `BonusHandle`, is the one piece of an inert Handle that runs — at the sprite's place in the handle pass.)
public enum SpriteHandler: Equatable, Hashable, Sendable {
    case player, platform, chain, background, box, effect, rope, ropeSegment, inert

    /// The Handle the class Setup `.GenerateSprite` selects for `type` installs (`SpriteClassTable`). The player
    /// (`.SetupPlayerSprite`), chain spokes (`.SetupChainSprite`, W1) and rope segments (W3) are set by their makers.
    public static func forClass(type: Int16) -> SpriteHandler {
        switch SpriteClassTable.classify(type: type, p1Negative: false)?.0 {
        case .platform: return .platform
        case .box: return .box
        case .background: return .background
        case .effect: return .effect
        case .rope: return .rope
        default: return .inert
        }
    }
}
