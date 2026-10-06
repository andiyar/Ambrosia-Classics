// Input (plan §Task 6.1; Invariant 5; Research note 24), transcribed from `_CheckHeroMovement @ 00021f49` and the
// FILM getters `_GetUpRecording @ 000170a7` … (`FILM.x[gRecordingCounter]`).

/// Where `_CheckHeroMovement` gets its five held flags. A sample is read **only** by `checkHeroMovement` (Invariant 5):
/// `samplesConsumed` is the original's `gRecordingCounter`, so it advances once per state-2, unfrozen, untrapped
/// `_ProcessHero` call — never per frame.
public protocol InputSource {
    /// Returns the next sample and advances the pointer. Called ONLY from `checkHeroMovement` (Invariant 5).
    mutating func readSample() -> FilmSample
    /// `gRecordingCounter`.
    var samplesConsumed: Int { get }
    /// Demo: `FILM.count <= gRecordingCounter` (the `_PlayGame` end check); live input: false.
    var isExhausted: Bool { get }
    /// `_PauseKey() || local_ea` as `_PlayGame` tests it at 00018a7e (after the hero state machine): Caps Lock
    /// (`GameKeyDown(0x39)`) or the app deactivated. FILM / scripted input: false (demo never pauses).
    var pauseRequested: Bool { get }
}

extension InputSource {
    public var pauseRequested: Bool { false }
}

/// FILM playback (`gGameMode == 1`): `FILM.{up,down,left,right,push}[gRecordingCounter] != 0`, then the counter
/// increments.
public struct FilmInput: InputSource, Sendable {
    public let film: Film
    public private(set) var samplesConsumed = 0

    /// The original's arrays hold 2000 samples (`_RecordingCountOK`: `gRecordingCounter < 2000`), so a FILM's count
    /// cannot exceed 2000; playback stops once `count <= gRecordingCounter`, so no read reaches index 2000.
    public init(film: Film) {
        precondition(film.count >= 0 && film.count <= Film.capacity,
                     "FILM \(film.id) count \(film.count) exceeds the 2000-sample arrays")
        self.film = film
    }

    public mutating func readSample() -> FilmSample {
        let sample = film.sample(samplesConsumed)        // precondition index < 2000
        samplesConsumed += 1
        return sample
    }

    public var isExhausted: Bool { film.count <= samplesConsumed }
}

/// A synthetic sample list (tests). Reading past the end is a test bug (precondition).
public struct ScriptedInput: InputSource, Sendable {
    public let samples: [FilmSample]
    public private(set) var samplesConsumed = 0

    public init(samples: [FilmSample]) {
        self.samples = samples
    }

    public mutating func readSample() -> FilmSample {
        precondition(samplesConsumed < samples.count, "ScriptedInput exhausted after \(samples.count) samples")
        let sample = samples[samplesConsumed]
        samplesConsumed += 1
        return sample
    }

    public var isExhausted: Bool { samples.count <= samplesConsumed }
}

extension GameState {
    /// `gHero_MoveKeyDown`: `_CheckHeroMovement` zeroes it and sets it with each held direction, so it always equals
    /// "any of Up/Down/Left/Right held" in `heroKeys`.
    var heroMoveKeyDown: Bool {
        heroKeys.up || heroKeys.down || heroKeys.left || heroKeys.right
    }

    /// `_CheckHeroMovement @ 00021f49`: clears the six key globals, reads one sample (demo: the FILM arrays at
    /// `gRecordingCounter`, then `gRecordingCounter++`; live: `_UpKey` … `_PushKey`), and sets each held flag
    /// (plus `gHero_MoveKeyDown` for a direction). Mode 2 (recording) is not modelled. The ONLY caller of
    /// `readSample` (Invariant 5).
    mutating func checkHeroMovement<I: InputSource>(input: inout I) {
        heroKeys = input.readSample()
    }
}
