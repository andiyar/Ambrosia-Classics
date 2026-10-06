import BubbleTroubleCore
import Foundation
import HectorGraphics
import HectorResources

/// The QuickTime-JPEG pictures of Bubble Trouble X, decoded ONCE on the Mac and shipped as exact RGBA (plan W0.5,
/// DECISIONS D16.1). Windows has no ImageIO, so `CodecImage.decode` there answers from the `<key>.rgba` files this
/// writes (`CodecImage.registerPrecomputed(directory:)`, staged as `Data/Decoded/`).
///
/// Foundation-only like the rest of BTXWinKit: the walk is portable, and the decode is `CodecImage.decode` — on the
/// Mac that is ImageIO (the real decode); off Apple it would only find what is already registered. The `btx-predecode`
/// executable is the Mac-only driver.
public enum BTXPredecode {
    /// One banded QuickTime PICT: the resource file it lives in, its id, and its bands' undecoded payloads in
    /// stream order.
    public struct Picture: Sendable {
        public let file: String
        public let id: Int16
        public let payloads: [Data]
    }

    /// One written picture: the keys (`CodecImage.precomputedKey`) of its bands, in stream order.
    public struct Written: Sendable {
        public let file: String
        public let id: Int16
        public let keys: [String]
    }

    public enum Failure: Error, CustomStringConvertible {
        case notAResourceFile(String)
        /// A PICT that is (or may be) a CompressedQuickTime picture but whose band walk threw: never skipped
        /// silently, or Windows would lack that picture's decode.
        case quickTimeWalkFailed(file: String, id: Int16, error: Error)
        public var description: String {
            switch self {
            case .notAResourceFile(let name): "\(name) is not a resource file"
            case let .quickTimeWalkFailed(file, id, error): "\(file) PICT \(id): QuickTime band walk failed: \(error)"
            }
        }
    }

    /// Every `PICT` in the game's five resource files (`BTXGameData.allFileNames`) whose stream is a banded
    /// CompressedQuickTime picture — `PICT.quickTimeBands(data:)` walks it with at least one band — sorted by id (ids
    /// are unique across the five files). Throws `quickTimeWalkFailed` for a PICT the walk refuses unless it is
    /// plainly not a QuickTime picture (`picture(file:id:data:)`).
    public static func quickTimePictures(resourcesDirectory: URL) throws -> [Picture] {
        var pictures: [Picture] = []
        for name in BTXGameData.allFileNames {
            guard let collection = try ResourceReader.read(fileAt: resourcesDirectory.appendingPathComponent(name))
            else { throw Failure.notAResourceFile(name) }
            for resource in collection.resources(of: "PICT") {
                if let picture = try picture(file: name, id: resource.id, data: resource.data) {
                    pictures.append(picture)
                }
            }
        }
        return pictures.sorted { $0.id < $1.id }
    }

    /// One PICT classified: its bands if `PICT.quickTimeBands` walks it with at least one band; nil if the walk ends
    /// with no band, or if the stream is plainly not a QuickTime picture — the plain opcode walk to the first 0x8200
    /// (`PICT.compressedQuickTimePayload`) stops at another, unsupported opcode first (raster, region, text, … PICTs).
    /// Anything else the walk refuses throws `Failure.quickTimeWalkFailed` naming the file and id.
    public static func picture(file: String, id: Int16, data: Data) throws -> Picture? {
        do {
            let walk = try PICT.quickTimeBands(data: data)
            return walk.bands.isEmpty ? nil : Picture(file: file, id: id, payloads: walk.bands.map(\.payload))
        } catch let walkError {
            do {
                _ = try PICT.compressedQuickTimePayload(data: data)
            } catch PICT.DecodeError.unsupportedOpcode(let op) where op != 0x8200 {
                return nil
            } catch {}
            throw Failure.quickTimeWalkFailed(file: file, id: id, error: walkError)
        }
    }

    /// Decode every band of every `quickTimePictures` picture with `CodecImage.decode` and write it to
    /// `outputDirectory` with `CodecImage.writePrecomputed` (created if missing). Idempotent: every existing `*.rgba`
    /// in `outputDirectory` is removed first, so the directory holds exactly this data's results; other files are left.
    public static func run(resourcesDirectory: URL, outputDirectory: URL) throws -> [Written] {
        let pictures = try quickTimePictures(resourcesDirectory: resourcesDirectory)
        let fm = FileManager.default
        try fm.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
        for name in try fm.contentsOfDirectory(atPath: outputDirectory.path) where name.hasSuffix(".rgba") {
            try fm.removeItem(at: outputDirectory.appendingPathComponent(name))
        }
        return try pictures.map { picture in
            let keys = try picture.payloads.map { payload in
                let key = CodecImage.precomputedKey(payload)
                try CodecImage.writePrecomputed(CodecImage.decode(payload), key: key, to: outputDirectory)
                return key
            }
            return Written(file: picture.file, id: picture.id, keys: keys)
        }
    }
}
