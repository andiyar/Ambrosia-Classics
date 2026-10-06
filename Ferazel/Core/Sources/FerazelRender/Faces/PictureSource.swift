import Foundation
import FerazelCore
import HectorResources
import HectorGraphics

public enum PictureSourceError: Error, Equatable {
    /// No `PICT` with this id on the chain searched.
    case missing(id: Int16)
    /// K1's `PICT.decodePixels` refused or could not parse the picture (its error, described).
    case undecodable(id: Int16, String)
    /// A shape the census has not shown (plan invariant 6, Research notes 4–5): an indexed v2 PixMap with a
    /// transfer mode ≠ 0 or no colour table, a v1 picture that is not a 1-bit BitMap, a DirectBits mode ≠ 64.
    case unsupported(id: Int16, String)
}

/// A `PICT` resource's pixels as stored, through HectorKit K1 `PICT.decodePixels` (sprites-backgrounds §1:
/// every tile set, sprite sheet and title is a plain `PICT`). K1 already accepts exactly one bits opcode of
/// the census forms; this adds the census checks K1 leaves to the game: indexed v2 = mode 0 with a colour
/// table (439 ×), v1 = a 1-bit BitMap, mode 0 (Sprites 183, Backgrounds 319/329/339/350 — plan bank correction 3),
/// DirectBits = mode 64 ditherCopy (326 ×, bank correction 2).
public struct PictureSource: Sendable, Equatable {
    public let id: Int16
    public let pixels: PICTPixels
    /// The picFrame's top-left as stored (`*(pic + 2)`): every shipped sheet's is (0, 0); `.Load1EncFaceFromPICT`
    /// keeps it unshifted, so `FaceSheet`'s `.single` path checks it.
    public let frameTop: Int16
    public let frameLeft: Int16

    public init(id: Int16, data: Data) throws {
        let decoded: PICTPixels
        do {
            decoded = try PICT.decodePixels(data: data)
        } catch {
            throw PictureSourceError.undecodable(id: id, String(describing: error))
        }
        try Self.check(decoded, id: id)
        self.id = id
        pixels = decoded
        let b = [UInt8](data.prefix(6))   // decodePixels has read the frame, so 6 bytes are there
        frameTop = Int16(bitPattern: UInt16(b[2]) << 8 | UInt16(b[3]))
        frameLeft = Int16(bitPattern: UInt16(b[4]) << 8 | UInt16(b[5]))
    }

    /// The census checks over K1's decoded form (invariant 6). K1 itself refuses these shapes from data today
    /// (as `.undecodable`); the checks pin the game's contract should K1 ever widen.
    static func check(_ decoded: PICTPixels, id: Int16) throws {
        switch decoded {
        case .indexed(let p):
            if p.version == 1 {
                guard p.depth == 1, p.colorTable == nil, p.transferMode == 0 else {
                    throw PictureSourceError.unsupported(id: id, "v1 depth \(p.depth) mode \(p.transferMode)")
                }
            } else {
                guard p.colorTable != nil else { throw PictureSourceError.unsupported(id: id, "PixMap without a colour table") }
                guard p.transferMode == 0 else { throw PictureSourceError.unsupported(id: id, "indexed mode \(p.transferMode)") }
            }
        case .direct(let p):
            guard p.transferMode == 64 else { throw PictureSourceError.unsupported(id: id, "DirectBits mode \(p.transferMode)") }
        }
    }

    public init(resource: Resource) throws {
        try self.init(id: resource.id, data: resource.data)
    }

    /// `GetPicture(id)` along `chain` (the first file holding it).
    public static func load(id: Int16, from resources: FerazelResources, chain: ResourceChain) throws -> PictureSource {
        guard let r = resources.resource(type: "PICT", id: id, chain: chain) else { throw PictureSourceError.missing(id: id) }
        return try PictureSource(resource: r)
    }

    /// The picFrame's width.
    public var width: Int {
        switch pixels {
        case .indexed(let p): return p.width
        case .direct(let p): return p.width
        }
    }

    /// The picFrame's height.
    public var height: Int {
        switch pixels {
        case .indexed(let p): return p.height
        case .direct(let p): return p.height
        }
    }

    /// True for a v1 1-bit BitMap (no colour table): the conversion bypasses `ColorSearch` for it.
    public var isBitMap: Bool {
        if case .indexed(let p) = pixels { return p.colorTable == nil }
        return false
    }
}
