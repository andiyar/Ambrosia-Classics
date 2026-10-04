import BubbleTroubleCore
import Foundation
import HectorAudio

/// The game's sounds as linear PCM (K2 `SndSound.linearPCM()` → `SndPCM`): the effects `snd 9000…9047`
/// (`_LoadSounds @ 00026a20`: slot n = `snd 9000 + n`; 9047 lives in `Bubble Trouble X.rsrc`, R9) and the four
/// music sets `snd 11001…11004` (`_LoadMusic`). Decoded once, lazily, cached. Not `Sendable` (wraps
/// `BTXGameData`); the decoded `SndPCM` values are, so the App may hand them to its mixer freely.
public final class SoundBankPCM {
    public enum SoundError: Error, Equatable {
        case missing(id: Int)
        case unparseable(id: Int)
        case undecodable(id: Int, reason: String)
    }

    public static let effectIDs = Array(9000...9047)
    public static let musicIDs = Array(11001...11004)
    public static let allIDs = effectIDs + musicIDs

    private let data: BTXGameData
    private var cache: [Int: SndPCM] = [:]

    public init(data: BTXGameData) {
        self.data = data
    }

    /// `snd ` `id` as PCM.
    public func pcm(_ id: Int) throws -> SndPCM {
        if let cached = cache[id] { return cached }
        guard let bytes = data.data(type: "snd ", id: id) else { throw SoundError.missing(id: id) }
        guard let snd = SndSound(data: bytes) else { throw SoundError.unparseable(id: id) }
        let pcm: SndPCM
        do { pcm = try snd.linearPCM() } catch { throw SoundError.undecodable(id: id, reason: "\(error)") }
        cache[id] = pcm
        return pcm
    }

    /// The effect a `SoundCue` names: slot 0…47 → `snd 9000 + slot`.
    public func effect(slot: Int) throws -> SndPCM {
        try pcm(9000 + slot)
    }
}
