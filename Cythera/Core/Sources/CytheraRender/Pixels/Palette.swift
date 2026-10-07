import Foundation
import CytheraCore

/// The 256-colour screen palette, from a `clut` (`ColorTableRecord`), naming which `clut 256` it came from:
/// two different ones ship (plan Research note 12, Landmine (f)) and which one the original's resource chain
/// returned is MED — the data file is opened after the application, so `GetResource` finds its copy first
/// (app-shell.md §1.3). Index i → the high bytes of entry i (by position = value in both tables).
/// Index 0 is opaque here; transparency is a blitter rule of Phase 1 (engine-classes §5).
public struct Palette: Equatable, Sendable {
    /// Which file's `clut 256` this palette is.
    public enum Origin: String, Sendable {
        /// `Cythera Data.rsrc` — what `CytheraResources.resource(type:id:)` returns (data file first).
        case dataFile = "Cythera Data.rsrc clut 256"
        /// `Cythera.rsrc` — kept for the census diff (entries 0, 16, 252, 253 differ).
        case appFile = "Cythera.rsrc clut 256"
    }

    public let origin: Origin
    /// 256 colours as 0xAARRGGBB, alpha 0xFF; indices past the table are opaque black.
    public let argb: [UInt32]

    public init(_ record: ColorTableRecord, origin: Origin) {
        self.origin = origin
        argb = (0..<256).map { i in
            guard let c = record.rgb8(i) else { return 0xFF00_0000 }
            return 0xFF00_0000 | UInt32(c.r) << 16 | UInt32(c.g) << 8 | UInt32(c.b)
        }
    }

    /// `clut 256` from the named file (default: the data file, the lookup order's answer).
    public static func clut256(_ resources: CytheraResources, from origin: Origin = .dataFile) throws -> Palette {
        let collection = origin == .dataFile ? resources.data : resources.app
        guard let res = collection.resource(type: "clut", id: 256) else {
            throw PixelError.missingResource(origin.rawValue)
        }
        return Palette(try ColorTableRecord(data: res.data), origin: origin)
    }

    /// The image as width × height 0xAARRGGBB pixels, row-major (row padding dropped).
    public func rgba(_ image: IndexedImage) -> [UInt32] {
        var out: [UInt32] = []
        out.reserveCapacity(image.width * image.height)
        for y in 0..<image.height {
            let row = y * image.rowBytes
            for x in 0..<image.width { out.append(argb[Int(image.pixels[row + x])]) }
        }
        return out
    }
}
