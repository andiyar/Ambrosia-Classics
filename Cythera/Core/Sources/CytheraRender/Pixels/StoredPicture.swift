import Foundation
import HectorGraphics

/// A PICT's pixels as stored, through HectorKit's `PICT.decodePixels(data:)` (K1, HectorKit D12/D14) — no colour
/// conversion, no clipping. Corpus (plan Research note 11, p14; HectorKit `CytheraPICTCensusTests`): 11 indexed
/// 0x0098 pictures, 3 indexed 0x0099 PackBitsRgn with device-relative tables (ctFlags 0x8000; by-position
/// indices), 1 16-bit 0x009B (PICT 129, the paper doll, 80×130) and 6 32-bit 0x009B (133–138, the start-screen
/// frames, 88×155). **Direct transfer modes are kept as stored, {0, 36, 64}** (129 = 36, 133–138 = 0; plan
/// Execution corrections). How the original colour-searched the direct pictures into the 8-bit screen is a
/// Phase 1/4 question (Hazard 10); the mask region of a Rgn opcode is returned, unapplied (the consumer clips).
public struct StoredPicture: Equatable, Sendable {
    /// The pixels, by the plan's S3 cases.
    public enum Pixels: Equatable, Sendable {
        /// One byte per frame pixel (rowBytes = width) and the stored colour table.
        case indexed(IndexedImage, ColorTable?)
        /// One A1R5G5B5 word per frame pixel, bit 15 kept, row-major.
        case direct16([UInt16])
        /// 8-bit R, G, B per frame pixel, row-major.
        case direct32([UInt8])
    }

    /// What `record(_:)` makes of a picture: its pixels, or the reason they are not decoded.
    public enum Outcome: Equatable, Sendable {
        case stored(StoredPicture)
        case refused(String)
    }

    /// The picFrame's size.
    public let width: Int
    public let height: Int
    public let pixels: Pixels
    /// The bits opcode's transfer mode as stored.
    public let transferMode: Int
    /// The 0x0099 / 0x009B mask region as stored; nil for the Rect opcodes.
    public let maskRegion: PICTMaskRegion?

    /// Decodes a PICT resource's bytes; throws `PICT.DecodeError` (or the kit's region errors) for a shape
    /// outside the census (HectorKit D2/D5).
    public static func decode(_ data: Data) throws -> StoredPicture {
        switch try PICT.decodePixels(data: data) {
        case .indexed(let p):
            let image = try IndexedImage(width: p.width, height: p.height, rowBytes: p.width, pixels: p.pixels)
            return StoredPicture(width: p.width, height: p.height, pixels: .indexed(image, p.colorTable),
                                 transferMode: p.transferMode, maskRegion: p.maskRegion)
        case .direct(let p):
            let pixels: Pixels
            switch p.depth {
            case 16:
                guard p.pixels16.count == p.width * p.height else { throw PixelError.image("direct16 buffer") }
                pixels = .direct16(p.pixels16)
            case 32:
                guard p.rgb.count == 3 * p.width * p.height else { throw PixelError.image("direct32 buffer") }
                pixels = .direct32(p.rgb)
            default:
                throw PixelError.image("direct depth \(p.depth)")
            }
            return StoredPicture(width: p.width, height: p.height, pixels: pixels,
                                 transferMode: p.transferMode, maskRegion: p.maskRegion)
        }
    }

    /// The census form: never throws. `headerBytes` skips a file header (the `* screenshot.pict` files carry
    /// 512). A QuickTime-compressed picture (opcode 0x8200 — `Land King Hall screenshot.pict`, an oracle file,
    /// never a census failure: Hazard 13) is `.refused("0x8200 QuickTime")`; any other refusal names the error.
    public static func record(_ data: Data, headerBytes: Int = 0) -> Outcome {
        guard headerBytes >= 0, data.count >= headerBytes else { return .refused("shorter than its header") }
        let picture = data.dropFirst(headerBytes)
        do {
            return .stored(try decode(picture))
        } catch {
            if bitsOpcode(picture) == 0x8200 { return .refused("0x8200 QuickTime") }
            return .refused(String(describing: error))
        }
    }

    /// The first bits-carrying opcode of a version-2 picture (0x0098…0x009B or 0x8200 CompressedQuickTime),
    /// walking only the state and rect ops the census shows ahead of it (VersionOp, HeaderOp, Clip, PnSize
    /// 0x0007, DefHilite, OpColor, rect ops 0x0030–0x0034, Short/LongComment; Research note 11 — Land King
    /// Hall carries 0x0032 / 0x001F / 0x0007 ops, and the kit stops at its 0x0032 first). nil for any other opcode or a truncated walk.
    /// Used only to name a refusal; decoding is the kit's.
    static func bitsOpcode(_ data: Data) -> Int? {
        let b = [UInt8](data)
        func u16(_ at: Int) -> Int? { at >= 0 && at + 1 < b.count ? Int(b[at]) << 8 | Int(b[at + 1]) : nil }
        var i = 10
        while let op = u16(i + (i & 1)) {
            i += (i & 1) + 2
            switch op {
            case 0x0011, 0x00A0: i += 2
            case 0x0C00: i += 24
            case 0x0001:
                guard let size = u16(i), size >= 2 else { return nil }
                i += size
            case 0x001E: break
            case 0x001F: i += 6
            case 0x0007: i += 4
            case 0x0030...0x0034: i += 8
            case 0x00A1:
                guard let size = u16(i + 2) else { return nil }
                i += 4 + size
            case 0x0098...0x009B, 0x8200: return op
            default: return nil
            }
        }
        return nil
    }
}
