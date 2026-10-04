import BubbleTroubleCore
import Foundation
import HectorGraphics

/// Every picture the game draws, decoded from the original resources to `RGBAImage` once, lazily, on first use:
/// `cicn` sprites (`CIcon(data:)`, mask → alpha) and `PICT`s (`PICT.decodeAny`: plain rasters forced opaque, the
/// 0x0099 region / 0x8201 matte pictures keep their mask as alpha). Lookups search all five resource files
/// through `BTXGameData` (amendment R9: cicn 128/1000–1002 live in `Bubble Trouble X.rsrc`).
///
/// Not `Sendable`: it holds the non-Sendable `BTXGameData` and a cache; use it from one isolation domain (the
/// App's main actor), like the data it wraps.
public final class ArtBank {
    public enum ArtError: Error, Equatable {
        case missing(type: String, id: Int)
        case undecodable(type: String, id: Int, reason: String)
    }

    private let data: BTXGameData
    private var cicns: [Int: RGBAImage] = [:]
    private var picts: [Int: RGBAImage] = [:]

    /// The original's flat loaded-sprite array of data set 0 (`_InitCompiledSprites @ 00015784` +
    /// `_LoadSprites @ 00015a32`): every set's frames in set order, `flatCICN[setOffset[s − 1] + k]` =
    /// `cicn start[s − 1] + k`.
    public let flatCICN: [Int]
    /// `setOffset[s − 1]` = the flat index of frame 1 of set `s` (the running sum of the frame counts). The
    /// original keeps 100 such shorts and zero-fills the ones past the set count, so sets 53…100 read offset 0.
    public let setOffset: [Int]

    public init(data: BTXGameData) {
        self.data = data
        var flat: [Int] = [], offsets: [Int] = []
        for entry in data.sprites.dataSets.first ?? [] {
            offsets.append(flat.count)
            for k in 0..<max(entry.frameCount, 0) { flat.append(entry.startID + k) }
        }
        flatCICN = flat
        setOffset = offsets
    }

    // MARK: - Sprite addressing

    /// The `cicn` id `_SpriteToComp(0, h, v, set, frame) @ 00015398` plots, or nil where the original would read
    /// outside its tables (we then draw nothing — the original read a wild pointer).
    ///
    /// Transcribed: `if (0 < f) f = f − 1` — so frame 0 (and only 0 of the non-positive frames) draws frame 1,
    /// a negative frame indexes BACK from the set's first frame; then `flat[offset[set − 1] + f]` with no range
    /// check — a frame past the set's count draws the next set's frames (the flat array), as the original did.
    /// `set` 53…100 reads the zero-filled tail of the 100-entry offset table → offset 0 (set 1's frames).
    /// `set` ≤ 0 or > 100, or a flat index outside the loaded array → nil (skip; documented deviation: the
    /// original dereferenced garbage there and, when it read NULL, stopped with `_LocationErrorInt(0x7d2, 10)`).
    public func spriteCICNID(set: Int, frame: Int) -> Int? {
        guard set >= 1, set <= 100 else { return nil }
        let offset = set <= setOffset.count ? setOffset[set - 1] : 0
        let f = frame > 0 ? frame - 1 : frame
        let index = offset + f
        guard index >= 0, index < flatCICN.count else { return nil }
        return flatCICN[index]
    }

    /// The decoded sprite for `_SpriteToComp(0, h, v, set, frame)`, nil per `spriteCICNID`.
    public func sprite(set: Int, frame: Int) -> RGBAImage? {
        guard let id = spriteCICNID(set: set, frame: frame) else { return nil }
        return try? cicn(id)
    }

    // MARK: - Decoders (lazy, cached)

    /// Every `cicn` id across the five files.
    public var cicnIDs: [Int] { data.ids(of: "cicn") }

    public func cicn(_ id: Int) throws -> RGBAImage {
        if let cached = cicns[id] { return cached }
        guard let bytes = data.data(type: "cicn", id: id) else { throw ArtError.missing(type: "cicn", id: id) }
        let icon: CIcon
        do { icon = try CIcon(data: bytes) } catch {
            throw ArtError.undecodable(type: "cicn", id: id, reason: "\(error)")
        }
        let image = RGBAImage(width: icon.width, height: icon.height, rgba: icon.rgba)
        cicns[id] = image
        return image
    }

    /// A `PICT` as `DrawPicture` would draw it: plain raster / QuickTime pictures opaque; region (0x0099) and
    /// matte (0x8201) pictures with their mask as straight alpha.
    public func pict(_ id: Int) throws -> RGBAImage {
        if let cached = picts[id] { return cached }
        guard let bytes = data.data(type: "PICT", id: id) else { throw ArtError.missing(type: "PICT", id: id) }
        let decoded: (pict: PICT, path: PICT.DecodePath)
        do { decoded = try PICT.decodeAny(data: bytes) } catch {
            throw ArtError.undecodable(type: "PICT", id: id, reason: "\(error)")
        }
        let masked = decoded.path == .packBitsRegion || decoded.path == .quickTimeMatte
        let image = RGBAImage(width: decoded.pict.width, height: decoded.pict.height, rgba: decoded.pict.rgba,
                              forceOpaque: !masked)
        picts[id] = image
        return image
    }

    /// Which decoder path `PICT.decodeAny` takes for `id` (tests and diagnostics).
    public func pictDecodePath(_ id: Int) throws -> PICT.DecodePath {
        guard let bytes = data.data(type: "PICT", id: id) else { throw ArtError.missing(type: "PICT", id: id) }
        return try PICT.decodeAny(data: bytes).path
    }

    /// Every `PICT` id across the five files.
    public var pictIDs: [Int] { data.ids(of: "PICT") }
}
