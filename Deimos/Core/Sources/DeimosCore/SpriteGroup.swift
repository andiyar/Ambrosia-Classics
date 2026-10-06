import Foundation

/// Why a sprite group could not be built (the group loader's data errors and asserts,
/// `FUN_10018d20`, U_Sprite.cc; sprite-sound-containers.md §2.1, sprite-geometry-draw.md §1.1).
public enum SpriteGroupError: Error, Equatable, Sendable {
    /// No `im08` tag with this ID (the colour plate `abcd` or the alpha plate `ABCD`).
    case missingPlate(FourCC)
    /// "DATA ERROR: Sprite color and alpha plates are not equal size for Sprite ID '%s'."
    case platesNotEqualSize(colourWidth: Int, colourHeight: Int, alphaWidth: Int, alphaHeight: Int)
    /// "spriteWidth > 0 and spriteWidth <= kU_Sprite_MaxDimensions.width" /
    /// "spriteHeight > 0 and spriteHeight <= kU_Sprite_MaxDimensions.height" (300 × 256).
    case frameSize(frame: Int, width: Int, height: Int)
    /// "numBitmapsInList > 0 and numBitmapsInList < 0xFFFF".
    case frameCount(Int)
}

/// One encoded sprite frame — the block `FUN_1001d780(w, h, key)` builds (sprite-sound-containers.md
/// §2.3a, sprite-manager-resource-image.md §4.2): a 0x18-byte header {magic 0x499602d2, w, h, 16,
/// key u16, hasAlpha u8, stale u8, alphaOffset u32}, `w·h` RGB555 pixels, and an optional `w·h` u16
/// alpha map. The header's fields are the stored properties; the stale byte `+0x13` (an undefined
/// register value in the original) is not modelled.
public struct SpriteFrame: Sendable, Equatable {
    /// The frame's rect in plate coordinates (top, left, bottom, right), from the plate scan.
    public let rect: MacRect
    public let width: Int
    public let height: Int
    /// The colour key: the colour plate's 16-bit pixel at (2,0).
    public let key: UInt16
    /// `width × height` RGB555 from the 16-bit colour plate, row-major.
    public let pixels: [UInt16]
    /// `width × height` alpha values from the 16-bit alpha plate (`FUN_1001eec0`): 0…30 = the red
    /// 5-bit channel (0 opaque … 30 nearly transparent), `0x20` = skip (pixel == key, or red 31), and
    /// `1000` in the first entry of a row with no visible pixel. `nil` when no pixel is visible
    /// (colour-key-only frame).
    public let alphaMap: [UInt16]?

    /// The encoded block's byte size: `0x18 + 2·w·h`, plus `2·w·h` with an alpha map.
    public var blockSize: Int { 0x18 + 2 * width * height + (alphaMap == nil ? 0 : 2 * width * height) }
}

/// A sprite group, loaded the original's way (`FUN_10018d20`; sprite-sound-containers.md §2.1–§2.3a;
/// plan Research notes 15–18):
/// 1. the alpha plate (`ABCD`) drawn into an **8-bit** GWorld → system-CLUT indices → `SpritePlate`
///    scan → frame rects;
/// 2. the colour plate (`abcd`) and the alpha plate again drawn into **16-bit** GWorlds
///    (`QuickDrawColor.rgb555`, `c >> 3`);
/// 3. key = the 16-bit colour-plate pixel at (2,0); per rect, the frame's RGB555 pixels come from the
///    colour plate and its alpha map from the 16-bit alpha plate: `p == key → 0x20`; else
///    `r5 = (p >> 10) & 31`, visible if `r5 < 31`, else `0x20`; an all-invisible row's first entry is
///    `1000`; a frame with no visible pixel has no map.
///
/// Frame size must be 1…300 × 1…256 (`kU_Sprite_MaxDimensions`, inclusive) and the frame count
/// below 0xFFFF.
public struct SpriteGroup: Sendable {
    public let id: FourCC
    public let frames: [SpriteFrame]

    /// `kU_Sprite_MaxDimensions` = {width 300, height 256} (sprite-geometry-draw.md §1.1).
    public static let maxFrameWidth = 300
    public static let maxFrameHeight = 256

    public init(colour: GIFImage, alpha: GIFImage, id: FourCC) throws {
        guard colour.width == alpha.width, colour.height == alpha.height else {
            throw SpriteGroupError.platesNotEqualSize(colourWidth: colour.width, colourHeight: colour.height,
                                                      alphaWidth: alpha.width, alphaHeight: alpha.height)
        }
        let w = colour.width

        // 8-bit draw of the alpha plate, then the scan.
        let alphaToIndex = alpha.palette.map { QuickDrawColor.systemIndex($0.r, $0.g, $0.b) }
        let rects = try SpritePlate.frameRects(alphaIndices: alpha.indices.map { alphaToIndex[Int($0)] },
                                               width: w, height: alpha.height)
        guard rects.count < 0xFFFF else { throw SpriteGroupError.frameCount(rects.count) }

        // 16-bit draws of both plates (per palette entry, then per pixel through the index).
        let colour16 = colour.palette.map { QuickDrawColor.rgb555($0.r, $0.g, $0.b) }
        let alpha16 = alpha.palette.map { QuickDrawColor.rgb555($0.r, $0.g, $0.b) }
        let key = colour16[Int(colour.indices[2])]

        var frames: [SpriteFrame] = []
        frames.reserveCapacity(rects.count)
        for (n, r) in rects.enumerated() {
            let fw = Int(r.right - r.left), fh = Int(r.bottom - r.top)
            guard fw > 0, fw <= Self.maxFrameWidth, fh > 0, fh <= Self.maxFrameHeight else {
                throw SpriteGroupError.frameSize(frame: n, width: fw, height: fh)
            }
            let top = Int(r.top), left = Int(r.left)
            var pixels = [UInt16](repeating: 0, count: fw * fh)
            var map = [UInt16](repeating: 0, count: fw * fh)
            var anyVisible = false
            for y in 0..<fh {
                var rowVisible = false
                let src = (top + y) * w + left
                for x in 0..<fw {
                    pixels[y * fw + x] = colour16[Int(colour.indices[src + x])]
                    let p = alpha16[Int(alpha.indices[src + x])]
                    var a: UInt16 = 0x20
                    if p != key {
                        let r5 = (p >> 10) & 0x1F
                        if r5 < 0x1F { a = r5; rowVisible = true }
                    }
                    map[y * fw + x] = a
                }
                if rowVisible { anyVisible = true } else { map[y * fw] = 1000 }
            }
            frames.append(SpriteFrame(rect: r, width: fw, height: fh, key: key, pixels: pixels,
                                      alphaMap: anyVisible ? map : nil))
        }
        self.id = id
        self.frames = frames
    }

    /// Loads group `id` from the index: colour plate `im08` `id`, alpha plate `im08` `upper(id)`
    /// (`FUN_100463b0`, a ctype toupper — ASCII a–z here, bank MED).
    public static func load(id: FourCC, index: TagIndex) throws -> SpriteGroup {
        let im08 = FourCC(rawValue: 0x696d_3038)
        let alphaID = alphaPlateID(for: id)
        guard let colourRecord = index.record(type: im08, id: id) else { throw SpriteGroupError.missingPlate(id) }
        guard let alphaRecord = index.record(type: im08, id: alphaID) else {
            throw SpriteGroupError.missingPlate(alphaID)
        }
        let colour = try GIFImage(data: index.data(for: colourRecord))
        let alpha = try GIFImage(data: index.data(for: alphaRecord))
        return try SpriteGroup(colour: colour, alpha: alpha, id: id)
    }

    /// The alpha plate's ID: the group ID with ASCII a–z upper-cased.
    public static func alphaPlateID(for id: FourCC) -> FourCC {
        FourCC(bytes: id.bytes.map { (0x61...0x7A).contains($0) ? $0 - 0x20 : $0 })
    }
}
