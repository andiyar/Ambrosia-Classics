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
        public var description: String {
            switch self {
            case .notAResourceFile(let name): "\(name) is not a resource file"
            }
        }
    }

    /// Every `PICT` in the game's five resource files (`BTXGameData.allFileNames`) whose stream is a banded
    /// CompressedQuickTime picture — `PICT.quickTimeBands(data:)` walks it with at least one band (raster, region and
    /// matte pictures are refused by the walk) — sorted by id (ids are unique across the five files).
    public static func quickTimePictures(resourcesDirectory: URL) throws -> [Picture] {
        var pictures: [Picture] = []
        for name in BTXGameData.allFileNames {
            guard let collection = try ResourceReader.read(fileAt: resourcesDirectory.appendingPathComponent(name))
            else { throw Failure.notAResourceFile(name) }
            for resource in collection.resources(of: "PICT") {
                guard let walk = try? PICT.quickTimeBands(data: resource.data), !walk.bands.isEmpty else { continue }
                pictures.append(Picture(file: name, id: resource.id, payloads: walk.bands.map(\.payload)))
            }
        }
        return pictures.sorted { $0.id < $1.id }
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
