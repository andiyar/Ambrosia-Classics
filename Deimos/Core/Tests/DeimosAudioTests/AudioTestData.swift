import Foundation
import XCTest
@testable import DeimosAudio
import DeimosCore

/// DeimosAudioTests' own data locator (plan invariant 5): the committed `Resources/Deimos` (D24 — never skips;
/// a missing file FAILS naming the path). Sounds are converted once per test process.
enum AudioTestData {
    static let loaded: Result<TagIndex, Error> = Result {
        try TagIndex(dataDirectory: DeimosData.dataDirectory())
    }
    static func index() throws -> TagIndex { try loaded.get() }

    /// A `soun` tag's file bytes.
    static func soundFile(_ tag: String) throws -> Data {
        let index = try index()
        let soun = FourCC("soun")!
        guard let id = FourCC(tag), let record = index.record(type: soun, id: id) else {
            throw NSError(domain: "AudioTestData", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "soun '\(tag)' missing from \(try DeimosData.dataDirectory().path)"])
        }
        return try index.data(for: record)
    }

    private static let cacheLock = NSLock()
    nonisolated(unsafe) private static var cache: [String: IMAContinuous] = [:]

    /// A real effect through the original's load conversion, decoded once.
    static func sound(_ tag: String) throws -> IMAContinuous {
        cacheLock.lock(); defer { cacheLock.unlock() }
        if let s = cache[tag] { return s }
        let s = try IMAContinuous(soundFile: soundFile(tag))
        cache[tag] = s
        return s
    }

    /// A mixer with real effects registered under their tags.
    static func mixer(_ tags: [String], numChannels: Int = 8) throws -> EffectMixer {
        var m = EffectMixer(numChannels: numChannels)
        for t in tags { m.register(FourCC(t)!, try sound(t)) }
        return m
    }

    /// A synthetic continuous stream of `count` samples from a nibble pattern (repeated), high nibble first.
    static func synthetic(_ pattern: [UInt8], count: Int) -> IMAContinuous {
        var bytes = [UInt8](repeating: 0, count: (count + 1) / 2)
        for p in 0..<count {
            let nib = pattern[p % pattern.count] & 0xF
            bytes[p / 2] |= p % 2 == 0 ? nib << 4 : nib
        }
        return IMAContinuous(nibbleBytes: bytes, sampleCount: UInt32(count))
    }

    static func cue(_ tag: String, priority: Int32 = 50, volume: Int32 = 100, pitch: Float = 1,
                    allowMultiple: Bool = true) -> SoundCue {
        SoundCue(id: FourCC(tag)!, priority: priority, volume: volume, pitch: pitch, allowMultiple: allowMultiple)
    }
}

extension EffectMixer {
    /// The live voice ids, top first.
    var voiceIDs: [UInt32] { (0..<voiceCount).map { voice(at: $0).id } }

    /// Mix blocks until no voice is left; XCTFails at `maxBlocks` (plan G11). Returns every block, concatenated.
    mutating func drain(maxBlocks: Int, file: StaticString = #filePath, line: UInt = #line) -> [Int16] {
        var all: [Int16] = []
        var blocks = 0
        while voiceCount > 0 {
            guard blocks < maxBlocks else {
                XCTFail("mixer still has \(voiceCount) voices after \(maxBlocks) blocks", file: file, line: line)
                break
            }
            mixBlock()
            all += block
            blocks += 1
        }
        return all
    }
}
