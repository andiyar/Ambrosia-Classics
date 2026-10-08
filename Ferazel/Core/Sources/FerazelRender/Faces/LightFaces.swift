import Foundation
import FerazelCore

public enum LightFaceError: Error, Equatable {
    /// `DrawPicture` into the port rect would scale the picture (its frame is not `width × height`); the scaling is
    /// not built — no shipped call site asks for it (plan invariant 6).
    case scaled(pict: Int16, frameWidth: Int, frameHeight: Int, width: Int, height: Int)
}

/// A light face: `.Load1LightFaceFromPICT @ 1002ff1c` (pict, w, h) = `.Load1PlainFaceFromPICT @ 1002fe68` with the
/// conversion CLUT `*_DAT_1009ff94` switched to clut 801 "System CLUT" (`_DAT_100a0038`) and restored around the call
/// (decompile l. 28658–28676; lighting-tables §1.1, §7.4). `.Load1PlainFaceFromPICT` makes an 8-bit blit port of
/// w × h under that CLUT (`.NewBlitPort @ 1003437c`: `+0x50` w, `+0x54` h, `+0x58` rect (0, 0, h, w), `+0x60` row
/// table) and `DrawPicture`s the PICT into the rect (`.DrawPicInGWorld @ 100341d8`) — the `ConvertedPicture` path.
///
/// The light PICTs are authored in the System palette's grey ramp: 0 = no light, 0xf5..0xff = intensity k = p − 0xf5
/// (lighting-tables §7.4); `.BlitLightOverFaceClip` reads the pixel as that intensity.
public struct LightFace: Sendable, Equatable {
    /// The PICT the face was drawn from.
    public let pict: Int16
    /// `+0x50`.
    public let width: Int
    /// `+0x54`.
    public let height: Int
    /// `width × height` indices under clut 801, row-major (the port's rows, `+0x60`).
    public let pixels: [UInt8]

    /// The twelve `.Load1LightFaceFromPICT` call sites (pict, w, h): `.InitPlayerShotSprite` (l. 50257, 50259),
    /// `.InitBonusSprite` (l. 52302–52306), `.InitEffectSprite` (l. 53662–53670), `.InitCrawlerSprite`
    /// (l. 56145–56147). All but (806, 84, 84) match their PICT's frame; 806 is 192×192 and is shrunk by
    /// `DrawPicture` there — refused by `load` (`LightFaceError.scaled`).
    public static let callSites: [(pict: Int16, width: Int, height: Int)] = [
        (0x32a, 0x48, 0x48), (0x336, 0x34, 0x34),
        (0x321, 0xc0, 0xc0), (0x322, 0xc0, 0xc0), (0x326, 0x54, 0x54),
        (0x32a, 0x48, 0x48), (0x32b, 0x48, 0x48), (0x32c, 0x48, 0x48), (0x32d, 0x48, 0x48), (0x33e, 0x40, 0x10),
        (0x334, 0x80, 0x80), (0x335, 0x80, 0x80),
    ]

    public init(pict: Int16, width: Int, height: Int, pixels: [UInt8]) {
        precondition(width >= 0 && height >= 0 && pixels.count == width * height, "LightFace \(width)×\(height)")
        self.pict = pict
        self.width = width
        self.height = height
        self.pixels = pixels
    }

    /// `+0x58`: the port rect (0, 0, h, w).
    public var rect: EncodedFace.Rect {
        EncodedFace.Rect(top: 0, left: 0, bottom: Int16(clamping: height), right: Int16(clamping: width))
    }

    /// The pixel at (row, col), both inside the face.
    @inline(__always) func pixel(row: Int, col: Int) -> UInt8 { pixels[row * width + col] }

    /// `.Load1LightFaceFromPICT(pict, width, height)`: the PICT (level chain — the Init*Sprite callers run during
    /// level setup) converted under clut 801.
    /// - Throws: `LightFaceError.scaled` when the PICT's frame is not `width × height`.
    public static func load(pict: Int16, width: Int, height: Int, from resources: FerazelResources,
                            search: ColorSearch, dither: DitherModel = .errorDiffusion) throws -> LightFace {
        let clut = try ColorLUT.load(id: 801, from: resources, chain: .frontEnd)
        let source = try PictureSource.load(id: pict, from: resources, chain: .level)
        guard source.width == width, source.height == height else {
            throw LightFaceError.scaled(pict: pict, frameWidth: source.width, frameHeight: source.height,
                                        width: width, height: height)
        }
        let picture = try ConvertedPicture(source: source, clut: clut, search: search, dither: dither)
        return LightFace(pict: pict, width: width, height: height, pixels: picture.pixels)
    }
}
