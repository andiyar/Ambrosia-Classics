import Foundation
import HectorResources
import HectorAudio

public enum SoundBankError: Error, Equatable {
    /// HectorAudio's `SndSound(data:)` could not parse the resource.
    case unparsable(id: Int16)
    /// A shape outside the census (plan invariant 6): every shipped `snd ` is format 1 with one modifier
    /// and one command.
    case unexpectedFormat(id: Int16, format: Int)
    case unexpectedModifierCount(id: Int16, count: Int)
    case unexpectedCommandCount(id: Int16, count: Int)
    /// The sound header is not 8-bit offset binary (encode 0).
    case notOffsetBinary(id: Int16)
}

/// Every `snd ` of the Sounds file decoded to linear PCM through HectorAudio (sprites-backgrounds §6.1:
/// format 1, one modifier, one `bufferCmd` 0x8051, an 8-bit offset-binary sampled-sound header, encode 0;
/// `SndSound.linearPCM()` gives `(s − 128) << 8` at the exact 16.16 rate). The Sound Tool's own `−0x80`
/// load path (§6.2) belongs to the Phase-2 mixer, not here.
public struct SoundBank: Sendable {
    public struct Sound: Sendable, Equatable {
        public let id: Int16
        public let name: String?
        /// The `snd ` format word (1 for every shipped sound).
        public let format: Int
        public let pcm: SndPCM
    }

    /// In resource-map order.
    public let sounds: [Sound]
    private let byId: [Int16: Int]

    public init(sounds collection: ResourceCollection) throws {
        let decoded = try collection.resources(of: "snd ").map(Self.decode)
        sounds = decoded
        var index: [Int16: Int] = [:]
        for (i, s) in decoded.enumerated() where index[s.id] == nil { index[s.id] = i }
        byId = index
    }

    public func sound(id: Int16) -> Sound? { byId[id].map { sounds[$0] } }

    public static func decode(_ resource: Resource) throws -> Sound {
        let id = resource.id
        guard let snd = SndSound(data: resource.data) else { throw SoundBankError.unparsable(id: id) }
        guard snd.format == 1 else { throw SoundBankError.unexpectedFormat(id: id, format: snd.format) }
        let modifiers = modifierCount(format1: resource.data)
        guard modifiers == 1 else { throw SoundBankError.unexpectedModifierCount(id: id, count: modifiers) }
        let commands = commandCount(format1: resource.data)
        guard commands == 1 else { throw SoundBankError.unexpectedCommandCount(id: id, count: commands) }
        guard case .pcm8 = snd.payload else { throw SoundBankError.notOffsetBinary(id: id) }
        return Sound(id: id, name: resource.name, format: snd.format, pcm: try snd.linearPCM())
    }

    /// Format 1 `modCount` (u16 at offset 2); −1 if the resource is too short.
    private static func modifierCount(format1 data: Data) -> Int {
        let b = [UInt8](data.prefix(4))
        return b.count == 4 ? Int(b[2]) << 8 | Int(b[3]) : -1
    }

    /// Format 1 layout: [u16 format][u16 modCount][modCount × 6 B][u16 cmdCount] (SndSound parsed it already).
    private static func commandCount(format1 data: Data) -> Int {
        let b = [UInt8](data.prefix(64))
        func u16(_ o: Int) -> Int { o + 1 < b.count ? Int(b[o]) << 8 | Int(b[o + 1]) : -1 }
        let mods = u16(2)
        return mods < 0 ? -1 : u16(4 + mods * 6)
    }
}
