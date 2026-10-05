// What the play session (`Session/GameSession.swift`, plan 2026-10-04 btx-playable C4) reads from and does to the
// simulation around `stepFrame`: additive accessors only — no stored state, no RNG draw, no change to any existing
// method. Everything here is either a read of the state as `_PlayGame @ 00018247` would see it, a transcription of a
// non-frame routine that mutates game globals (`_TimeBonus_CountDown`'s arithmetic, `_AdvanceFrameCounter`), or a
// placeholder seam that C3 fills.

/// A `_PlayGame` hero-state-machine transition about to happen at the top of the next frame (Research note 20,
/// 000187a7–000189a3). The state machine is the first thing a frame runs, so the pre-frame state decides it exactly.
public enum HeroTransition: Equatable, Sendable {
    /// State 1 → 2 (lives ≥ 1): `_PrepareNotice(0)` (not demo), `_StartMusic`, snd 8 + 27 (C2).
    case appear
    /// State 3 → 4: `_StopMusicWithoutFade`, snd 34 (C2).
    case death
    /// State 4 → 1 in play: `livesLeft < 1` → notice 2 (FIN!) + snd 3; else, unless `endOfLevel`, snd 2 + notice 1
    /// (GET READY!).
    case respawn(livesLeft: Int16, endOfLevel: Bool)
}

extension GameState {
    // MARK: Reads

    /// The transition the next `stepFrame` will make at its top, or nil. Mirrors `runHeroStateMachine` with the frame
    /// it will run at (`frame &+ 1`, Invariant 9); a frame that will not run (`playing` false or a stop pending) → nil.
    public var upcomingHeroTransition: HeroTransition? {
        guard playing, pendingStops.isEmpty else { return nil }
        let next = Int(frame &+ 1)
        switch hero.state {
        case 1:
            let delay = lives < 1 ? 0x5f : (firstAppearance ? 0x46 : 0x3c)
            return Int(hero.stateStart) + delay < next && lives >= 1 ? .appear : nil
        case 3:
            return Int(hero.stateStart) + 0x1e < next ? .death : nil
        case 4:
            guard Int(hero.stateStart) + 0x41 < next, mode == .play else { return nil }
            return .respawn(livesLeft: lives, endOfLevel: isEndOfLevel)
        default:
            return nil
        }
    }

    /// The LEVL id `_LoadLevel @ 00002ef7` will load for level `requested`: itself below 51, else the
    /// `GetRandomFast(0x15,0x32)` it is about to draw — computed on a COPY of the stream (no draw is made here).
    public func levelIDToLoad(_ requested: Int) -> Int {
        guard requested >= 0x33 else { return requested }
        var probe = rng
        return probe.fast(0x15, 0x32)
    }

    /// `_LoadMusic(1) @ 0001b23c`'s set: "Level set " + `level.w2` + " music" (LEVL word 2 of the loaded record).
    public var levelMusicSet: Int { Int(levelRecord.words[2]) }

    // MARK: Non-frame mutations (`_TimeBonus_CountDown @ 00006dcb`, `_AdvanceFrameCounter @ 00016e21`)

    /// `_AdvanceFrameCounter @ 00016e21`: `gFrameCounter++` (u16, wraps) — called once per countdown chunk.
    mutating func advanceFrameCounter() {
        frame &+= 1
    }

    /// `_TimeBonus_CountDown`'s multiplier step: `bonus = mult × bonus`, 0x1866e (99950) when the product exceeds
    /// it (`iVar1 < 0x1866f` keeps it); then flash on, flash timer = `_GetFrameCounter()`.
    mutating func countdownApplyMultiplier() {
        let product = Int32(multiplier) &* timeBonus
        timeBonus = product < 0x1866f ? product : 0x1866e
        timeBonusFlash = true
        timeBonusFlashTimer = frame
    }

    /// One countdown chunk: 500 / 200 / 100 / 50 for bonus ≥ 50000 / ≥ 10000 / ≥ 5000 / else; bonus −= chunk;
    /// `_AddToScore(chunk, 0)` (no multiply; may award a life). Returns the chunk.
    @discardableResult
    mutating func countdownTransferChunk() -> Int32 {
        let chunk: Int32
        if timeBonus < 50000 {
            if timeBonus < 10000 {
                chunk = timeBonus < 5000 ? 0x32 : 100
            } else {
                chunk = 200
            }
        } else {
            chunk = 500
        }
        timeBonus &-= chunk
        addToScore(chunk, multiply: false)
        return chunk
    }

    /// Drains the sim's `_PlayMySnd` buffer (`soundsThisFrame`, C2) — for sim code the session calls OUTSIDE
    /// `stepFrame` (which clears the buffer at its top): e.g. `_AddToScore` in the count-down awarding a life
    /// (`_AddHero`'s two snd 13). Returns the cues in call order and empties the buffer.
    mutating func takeSounds() -> [SoundCue] {
        defer { soundsThisFrame = [] }
        return soundsThisFrame
    }

    /// `_Multiplier_Flash @ 00019d23` sets `gBonusMultiplier` to 1 and back around each draw (display only).
    mutating func setMultiplierForFlash(_ value: Int16) {
        multiplier = value
    }
}
