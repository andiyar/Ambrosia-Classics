import Foundation

public enum FilmError: Error, Equatable, Sendable {
    /// Not exactly 0x9d68 bytes.
    case wrongSize(Int)
    /// "FILM FAILURE:  A film could not be played as it was out of date.  (Film version: %i)."
    case outOfDate(Int)
    /// A player block claims more than 20,000 recorded ticks (the recorder's `< 20000` guard).
    case tooManyFrames(player: Int, frames: Int)
}

/// A `film` replay (bank engine-loop.md §7): the 0x9d68-byte image the game saves (`FUN_100095b0`),
/// big-endian. Header: version 0x2715 · RNG seed · level 4CC · player count u8 (at 0x0c). Two player
/// blocks of 0x4eac bytes at 0x10 and 0x4ebc: frames u32 · score + 0xb3ac2 u32 · level 4CC · one input
/// byte per tick from +0xc (bits 0–6 = `Input`).
public struct Film: Sendable, Equatable {
    public static let size = 0x9d68
    public static let version: UInt32 = 0x2715
    public static let blockOffsets = [0x10, 0x4ebc]
    public static let blockSize = 0x4eac
    public static let maxFrames = 20_000
    /// Added to the score before it is stored.
    public static let scoreBias: UInt32 = 0xb3ac2

    public struct Input: OptionSet, Sendable, Hashable {
        public let rawValue: UInt8
        public init(rawValue: UInt8) { self.rawValue = rawValue }
        public static let left = Input(rawValue: 1 << 0)
        public static let right = Input(rawValue: 1 << 1)
        public static let up = Input(rawValue: 1 << 2)
        public static let down = Input(rawValue: 1 << 3)
        public static let fireGround = Input(rawValue: 1 << 4)
        public static let fireAir = Input(rawValue: 1 << 5)
        public static let selectWeapon = Input(rawValue: 1 << 6)
    }

    public struct Block: Sendable, Equatable {
        public let frames: Int
        /// The stored value − 0xb3ac2 (the score at the last recorded tick).
        public let score: Int32
        public let level: FourCC
        /// `frames` input bytes.
        public let inputs: [UInt8]
        public func input(at tick: Int) -> Input { Input(rawValue: inputs[tick]) }
    }

    public let version: UInt32
    public let seed: UInt32
    public let level: FourCC
    public let playerCount: Int
    /// Always two blocks (the second is empty in a one-player film).
    public let players: [Block]
    /// Every byte of each block past its last recorded input is zero (census property; not required).
    public let trailingBytesAreZero: Bool

    public init(data: Data) throws {
        let b = Array(data)
        guard b.count == Self.size else { throw FilmError.wrongSize(b.count) }
        func u32(_ at: Int) -> UInt32 { UInt32(b[at]) << 24 | UInt32(b[at + 1]) << 16 | UInt32(b[at + 2]) << 8 | UInt32(b[at + 3]) }
        version = u32(0)
        guard version == Self.version else { throw FilmError.outOfDate(Int(version)) }
        seed = u32(4)
        level = FourCC(rawValue: u32(8))
        playerCount = Int(b[0x0c])
        var players: [Block] = []
        var zero = true
        for (p, base) in Self.blockOffsets.enumerated() {
            let frames = Int(u32(base))
            guard frames <= Self.maxFrames else { throw FilmError.tooManyFrames(player: p, frames: frames) }
            let inputStart = base + 0xc
            players.append(Block(frames: frames, score: Int32(bitPattern: u32(base + 4) &- Self.scoreBias),
                                 level: FourCC(rawValue: u32(base + 8)),
                                 inputs: Array(b[inputStart..<(inputStart + frames)])))
            if b[(inputStart + frames)..<(base + Self.blockSize)].contains(where: { $0 != 0 }) { zero = false }
        }
        self.players = players
        trailingBytesAreZero = zero
    }
}
