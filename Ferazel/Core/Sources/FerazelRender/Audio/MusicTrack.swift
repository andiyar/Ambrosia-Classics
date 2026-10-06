import Foundation
import HectorAudio

public enum MusicTrackError: Error, Equatable {
    /// No track file at this path.
    case missing(String)
    /// The track is not `ima4`-compressed AIFC (every shipped one is; plan invariant 6).
    case notIMA4(String)
}

/// One music track: the AIFC file `NN` in `Ferazel's Wand Music` (world-data §1), opened through HectorAudio's
/// `AIFFAudio` and decoded from `ima4` by the kit (design §7.7). Opening reads the file; `decode()` makes the
/// PCM on demand, so a caller can hold one decoded track at a time.
public struct MusicTrack: Sendable {
    public let number: Int
    public let url: URL
    public let audio: AIFFAudio

    /// Opens track `number` (file name two digits, e.g. `01`) in `directory`.
    public init(number: Int, in directory: URL) throws {
        let url = directory.resolvingSymlinksInPath().appendingPathComponent(Self.fileName(number))
        guard FileManager.default.fileExists(atPath: url.path) else { throw MusicTrackError.missing(url.path) }
        let audio = try AIFFAudio(data: try Data(contentsOf: url))
        guard audio.encoding == .ima4 else { throw MusicTrackError.notIMA4(url.path) }
        self.number = number
        self.url = url
        self.audio = audio
    }

    public static func fileName(_ number: Int) -> String {
        number < 10 ? "0\(number)" : "\(number)"
    }

    /// The track numbers present in `directory` (files named by digits only), ascending.
    public static func trackNumbers(in directory: URL) throws -> [Int] {
        let dir = directory.resolvingSymlinksInPath()
        return try FileManager.default.contentsOfDirectory(atPath: dir.path)
            .filter { !$0.isEmpty && $0.allSatisfy(\.isASCII) && $0.allSatisfy(\.isNumber) }
            .compactMap { Int($0) }
            .sorted()
    }

    public var channels: Int { audio.channels }
    public var sampleRate: Double { audio.sampleRate }
    public var encoding: AIFFAudio.Encoding { audio.encoding }
    /// COMM `numSampleFrames`, which for `ima4` counts packets (64 frames each).
    public var packetCount: Int { audio.frameCount }

    /// Interleaved Int16 PCM at `sampleRate` (frames = packets × 64).
    public func decode() throws -> SndPCM { try audio.linearPCM() }
}
