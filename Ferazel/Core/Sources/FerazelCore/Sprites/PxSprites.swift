import Foundation

/// The parallax horizon strip (triggers-background-2 §4): one Backgrounds PICT (768 wide) repeated as sprites that
/// move at fx/256 and fy/256 of the camera. Not a pixel effect — drawn by `.WrapDrawSprites` like any sprite (the
/// drawing is R4's; this type holds what `.MTAddPxSprite` creates and what `.HandlePxSprite` computes).
///
/// `.SetupLevel` (decompile l. 2252–2268 / 2346–2354) calls `.MTKillPxSprites` and then, when header `0x2716 ≠ 0`,
/// `.MTAddPxSprite(0x2716 PICT, 0x2718 x factor, 0x271a y)` with Backgrounds open.
///
/// `.MTAddPxSprite @ 1003359c` (raw): `N = ⌊((fx·(W << 5)) >> 8) / 768⌋ + 1` (`100335ec..1003360c`, W = header `0xb280`,
/// `mulhw 0x2aaaaaab` + `srawi 7` = truncating /768); one face (`.Load1EncFaceFromPICT`, `1003363c`; under the
/// level+base CLUT `*1009ff8c` when header `0x26cc ≠ 0`, `10033614..10033628`); then the loop `k = 0, 1, …` while
/// `k ≤ min(N, 31 − count)` (`10033724..10033740`, `ble`), `count += 1` each pass — so **N + 1 copies** (k = 0...N,
/// at most 16 because the count grows with k), each `.MTNewSprite(0, 0, 0, layer −500, −1, .SetupPxSprite)`
/// (`10033670..10033688`) with `+0x14c = 0x300·k`, `+0x150 = y`, `+0x154 = fx`, `+0x158 = header 0xb26c` (the
/// PxBack y factor). As written the slot index is `count + k` read after `count` already grew by k (`1003368c..
/// 1003369c`), so the copies sit in slots 0, 2, 4, … of the 32-entry table — invisible to drawing.
///
/// `.SetupPxSprite @ 10033418`: empty rect, `+0x48 = 0x1ff`, `+0xea = 1`, type `+4 = 1`, `+0x88 = 0` (no light
/// overlay), `+0x5c = 0`, `+0x1f8 = 0`, handler `.HandlePxSprite`, draw mode `+0xb8 = 0x80000` (behind tiles,
/// draw-effects §2.5: word add through the mask port).
public struct PxSprites: Equatable, Sendable {
    /// `.MTNewSprite` layer argument (`10033680 li r6,-0x1f4`).
    public static let layer = -500
    /// `+0xb8` (`.SetupPxSprite`).
    public static let drawMode: UInt32 = 0x80000
    /// The x step between copies, `+0x14c = 0x300·k` (`10033714`).
    public static let copySpacing = 0x300
    /// `.HandlePxSprite`'s fixed y term (`100333e4 addi r0,r4,0xe8`).
    public static let yOffset = 0xe8
    /// The sprite table holds 31 strip sprites at most (`10033728 subfic r0,r0,0x1f`).
    public static let maxSprites = 0x1f

    /// One strip sprite's fields.
    public struct Sprite: Equatable, Sendable {
        /// `+0x14c` = 768·k.
        public let x0: Int
        /// `+0x150` = header `0x271a`.
        public let y0: Int
        /// `+0x154` = header `0x2718`.
        public let fx: Int
        /// `+0x158` = header `0xb26c`.
        public let fy: Int

        public init(x0: Int, y0: Int, fx: Int, fy: Int) {
            self.x0 = x0; self.y0 = y0; self.fx = fx; self.fy = fy
        }

        /// `.HandlePxSprite @ 10033378` for scroll (h, v) (`PTR_DAT_1009fe78`: v at +0, h at +2):
        /// `+0xc = int16(int16(x0 − (h·fx >> 8)) + h)` (`10033398..100333d8`, srawi), `+0xa = int16(y0 − (v·fy >> 8) +
        /// v + 232)` (`100333b0..100333ec`).
        public func position(h: Int, v: Int) -> (x: Int, y: Int) {
            let x = Int(Int16(truncatingIfNeeded: Int(Int16(truncatingIfNeeded: x0 - ((h * Int(Int16(truncatingIfNeeded: fx))) >> 8))) + h))
            let y = Int(Int16(truncatingIfNeeded: y0 - ((v * Int(Int16(truncatingIfNeeded: fy))) >> 8) + v + PxSprites.yOffset))
            return (x, y)
        }
    }

    /// Header `0x2716` (Backgrounds PICT).
    public let pict: Int16
    /// Header `0x26cc ≠ 0`: the face converts under the level+base CLUT `0x285e`. Otherwise under whatever
    /// `*1009ff94` holds at `.SetupLevel` time (not traced here; R4 reads it when it draws the strip).
    public let usesLevelBaseClut: Bool
    /// The formula value `N = ⌊((fx·W·32) >> 8) / 768⌋ + 1`.
    public let n: Int
    /// The copies in creation order (k = 0...min(N, 15)).
    public let sprites: [Sprite]

    /// `.MTAddPxSprite` for a freshly killed strip table (`.MTKillPxSprites` first, count 0); nil when the level has
    /// no strip (header `0x2716 == 0`, every level but 10, 30, 40, 45, 62, 67).
    public init?(header: LevelHeader) {
        guard header.stripPict != 0 else { return nil }
        let fx = Int(header.stripFactor)
        let product = Int(Int32(truncatingIfNeeded: fx * (Int(header.gridWidth) << 5)))
        let n = Int(Int32(truncatingIfNeeded: (product >> 8) / 0x300)) + 1
        var sprites: [Sprite] = []
        var count = 0
        var k = 0
        while k <= min(n, Self.maxSprites - count) {
            sprites.append(Sprite(x0: Self.copySpacing * k, y0: Int(header.stripBaseY), fx: fx,
                                  fy: Int(header.pxBackYFactor)))
            count += 1
            k += 1
        }
        pict = header.stripPict
        usesLevelBaseClut = header.pxUsesLevelBaseClut != 0
        self.n = n
        self.sprites = sprites
    }
}
