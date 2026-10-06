@testable import BubbleTroubleCore
import Foundation
import XCTest

/// C8 — the pause-screen cheats (plan 2026-10-04 btx-playable §C8; FI §3h), against `_PauseGame @ 0001767b` (event
/// kind 3, 000178df…0001801f), `_PlayGame @ 00018247` (flag resets 000182a3…, frame-limit wait 00018f5d…, FPS
/// 00019129…) and the callees each cheat reaches. Data-gated on `HECTORKIT_DATA_BTX` (always set under G1).
///
/// The five-letter strings below are test vectors: strings whose hash (the formula at 00017908) equals each constant
/// the original compares. Every constant has hundreds of printable preimages; these are simply readable ones.
final class CheatTests: XCTestCase {

    // MARK: Helpers

    private func pausedSession(now: inout UInt32, prefs: BTXPrefs = .defaults) throws -> GameSession {
        let data = try BTXGameData(resourcesDirectory: BTXTestData.resourcesDirectory())
        let session = try GameSession(data: data, prefs: prefs, mode: .play, startLevel: 1, seed: 0x1234, film: nil)
        while session.phase == .wipe {
            _ = session.tick(now: now, keys: HeldKeys())
            now += 1
        }
        _ = session.frame(keys: HeldKeys(), now: now)
        _ = session.frame(keys: HeldKeys(capsLock: true), now: now)
        XCTAssertEqual(session.phase, .paused)
        return session
    }

    @discardableResult
    private func type(_ text: String, into session: GameSession) -> SessionOutput {
        var out = SessionOutput()
        for c in text.utf8 { out.append(session.pauseKeyTyped(c)) }
        return out
    }

    private func cue(_ slot: Int, _ priority: Int = 0x1e) -> SoundCue {
        SoundCue(slot: slot, priority: priority, delayFrames: 0)
    }

    /// Unpauses (Caps Lock off) with ticks, returning everything emitted on the way.
    @discardableResult
    private func resume(_ session: GameSession, now: inout UInt32) -> SessionOutput {
        var out = SessionOutput()
        var n = 0
        while session.phase == .paused && n < 2000 {
            out.append(session.tick(now: now, keys: HeldKeys()))
            now += 1
            n += 1
        }
        XCTAssertEqual(session.phase, .playing)
        return out
    }

    private func isSprite(_ op: DrawOp) -> Bool {
        if case .sprite = op { return true }
        return false
    }

    // MARK: Plan tests

    func testBufferSeedOOGLE() throws {
        XCTAssertEqual(Cheats.bufferSeed, Array("OOGLE".utf8))
        var now: UInt32 = 100
        let session = try pausedSession(now: &now)
        XCTAssertEqual(session.cheatBuffer, Array("OOGLE".utf8), "seeded at _PauseGame entry")
        type("AB", into: session)
        XCTAssertEqual(session.cheatBuffer, Array("GLEAB".utf8), "shift left, new char last")
        // 000178e8: a key-down with ⌘ held (modifiers bit 8) is not shifted in.
        XCTAssertEqual(session.pauseKeyTyped(UInt8(ascii: "Z"), command: true), SessionOutput())
        XCTAssertEqual(session.cheatBuffer, Array("GLEAB".utf8))
        // Each `_PauseGame` call starts from "OOGLE" again.
        resume(session, now: &now)
        XCTAssertNil(session.cheatBuffer)
        _ = session.frame(keys: HeldKeys(capsLock: true), now: now)
        XCTAssertEqual(session.phase, .paused)
        XCTAssertEqual(session.cheatBuffer, Array("OOGLE".utf8))
        // Outside the pause, typing does nothing.
        let playing = try pausedSession(now: &now)
        resume(playing, now: &now)
        XCTAssertEqual(playing.pauseKeyTyped(UInt8(ascii: "A")), SessionOutput())
    }

    func testHashFormula() {
        // (c0+410)(c1+106)(c2+333) + 3 + (c3+280)(c4+560), chars sign-extended (`movsbl`), 32-bit products.
        let oogleProduct: Int32 = 489 * 185 * 404                        // O O G: (79+410)(79+106)(71+333)
        let oogle: Int32 = oogleProduct + 3 + 356 * 629                  // L E: (76+280)(69+560)
        XCTAssertEqual(oogle, 0x23117cb)
        XCTAssertEqual(Cheats.hash(Array("OOGLE".utf8)), oogle)
        // A Mac Roman high character is negative: 0xC0 → −64.
        let highProduct: Int32 = 346 * 171 * 398                         // (−64+410)(65+106)(65+333)
        XCTAssertEqual(Cheats.hash([0xc0, 0x41, 0x41, 0x41, 0x41]), highProduct + 3 + 345 * 625)
        XCTAssertEqual(Cheats.hash(Array("FRAME".utf8)), 0x227742c)
        XCTAssertEqual(Cheats.effect(forHash: 0x227742c), .toggleFPS)
        XCTAssertNil(Cheats.effect(forHash: oogle))
        // The compare chain: 25 effect constants (FI §3h lists 24 — 0x239b951, one snd 46, was missing), plus
        // 0x5792ca4, the one value that skips `_SetHacked(1)`.
        XCTAssertEqual(Cheats.table.count, 25)
        XCTAssertEqual(Cheats.effect(forHash: 0x239b951), .dogBark)
        XCTAssertNil(Cheats.effect(forHash: Cheats.noHackHash))
        XCTAssertEqual(Cheats.noHackHash, 0x5792ca4)
    }

    func testExtraLetterCheats() throws {
        var now: UInt32 = 0
        let session = try pausedSession(now: &now)
        XCTAssertEqual(Cheats.hash(Array("OZZYE".utf8)), 0x26e29e4)
        let e = type("OZZYE", into: session)
        XCTAssertEqual(e.sounds, [cue(0)])
        XCTAssertEqual(session.state.extraLetters, [true, false, false, false, false])
        XCTAssertTrue(e.drawOps.contains(.scoreToComp(GameState.extraRect)), "_EXTRA_Draw runs at once")
        XCTAssertTrue(session.playerIsCheating)
        XCTAssertTrue(session.hacked)
        type("OZZYX", into: session)
        type("OZZYT", into: session)
        type("OZZYR", into: session)
        XCTAssertEqual(session.state.extraLetters, [true, true, true, true, false])
        let lives = session.state.lives
        let a = type("OZZYA", into: session)
        // All five: cleared, `_AddHero` (13 ×2), +10000 — which reaches gNextExtraLifeScore (10000) from 0, so a
        // second `_AddHero` (13 ×2) — then `_Balloons_CaptureAllEnemies` (15).
        XCTAssertEqual(session.state.extraLetters, [false, false, false, false, false])
        XCTAssertTrue(session.state.extraAnimating)
        XCTAssertEqual(session.state.lives, lives + 2)
        XCTAssertEqual(session.state.score, 10000)
        XCTAssertEqual(session.state.nextExtraLifeScore, 40000)
        XCTAssertEqual(a.sounds, [cue(0)] + Array(repeating: cue(0xd, 0x14), count: 4) + [cue(0xf, 10)])
    }

    func testMultiplierCheats() throws {
        var now: UInt32 = 0
        let session = try pausedSession(now: &now)
        for v in 2...5 {
            let out = type("HONK\(v)", into: session)
            XCTAssertEqual(session.state.multiplier, Int16(v))
            XCTAssertTrue(session.state.multiplierAnimating)
            XCTAssertEqual(out.sounds, [cue(0)])
            XCTAssertTrue(out.drawOps.contains(.compToScreen(GameState.multiplierRect)), "_Multiplier_Draw at once")
        }
        XCTAssertTrue(session.playerIsCheating)
    }

    func testCheatSetsCheatingFlag() throws {
        var now: UInt32 = 0
        // gPlayerIsCheating (no high score): set by these …
        for code in ["SNAIL", "BOING", "SHEBA", "EXTRA", "SCORE", "INVIS", "CATCH", "OZZYE", "HONK2"] {
            let session = try pausedSession(now: &now)
            XCTAssertFalse(session.playerIsCheating)
            XCTAssertNotNil(Cheats.effect(forHash: Cheats.hash(Array(code.utf8))), code)
            type(code, into: session)
            XCTAssertTrue(session.playerIsCheating, code)
            XCTAssertTrue(session.hacked, code)
        }
        // … and not by these (gHacked only).
        for code in ["FRAME", "GATES", "FUNKY", "ALBOY", "NONNY", "ZOOOM", "DAVID", "GHOST", "BONGO"] {
            let session = try pausedSession(now: &now)
            XCTAssertNotNil(Cheats.effect(forHash: Cheats.hash(Array(code.utf8))), code)
            type(code, into: session)
            XCTAssertFalse(session.playerIsCheating, code)
            XCTAssertTrue(session.hacked, code)
        }
        // +9000 is `_AddToScore(9000, 0)`: never multiplied; +1 life is `_AddHero(1, 1)` with its two cues.
        let session = try pausedSession(now: &now)
        type("HONK3", into: session)
        let score = type("SCORE", into: session)
        XCTAssertEqual(session.state.score, 9000)
        XCTAssertEqual(score.sounds, [cue(0)])
        let lives = session.state.lives
        let life = type("EXTRA", into: session)
        XCTAssertEqual(session.state.lives, lives + 1)
        XCTAssertEqual(life.sounds, [cue(0), cue(0xd, 0x14), cue(0xd, 0x14)])
        // Score reset: `_ResetScore(0)` — score 0, next extra life 10000, the score rect collapsed (snd 3).
        let reset = type("GATES", into: session)
        XCTAssertEqual(reset.sounds, [cue(3)])
        XCTAssertEqual(session.state.score, 0)
        XCTAssertEqual(session.state.nextExtraLifeScore, 10000)
        XCTAssertEqual(session.state.presentation.scoreRect, QDRect(top: 0x1be, left: 0x84, bottom: 0x1dc, right: 0x84))
        XCTAssertTrue(session.state.presentation.scoreHasChanged)
        // Invisibility.
        type("INVIS", into: session)
        XCTAssertTrue(session.state.hero.invisible)
    }

    func testUnknownStringNoEffect() throws {
        var now: UInt32 = 0
        let session = try pausedSession(now: &now)
        let s = session.state
        XCTAssertFalse(session.hacked, "_PlayGame entry: _SetHacked(0)")
        let out = type("HELLO", into: session)
        XCTAssertEqual(out, SessionOutput())
        XCTAssertEqual(session.state.score, s.score)
        XCTAssertEqual(session.state.lives, s.lives)
        XCTAssertEqual(session.state.multiplier, s.multiplier)
        XCTAssertEqual(session.state.extraLetters, s.extraLetters)
        XCTAssertEqual(session.state.rng.drawCount, s.rng.drawCount)
        XCTAssertEqual(session.state.stars.activeCount, s.stars.activeCount)
        XCTAssertFalse(session.state.isEndOfLevel)
        XCTAssertFalse(session.playerIsCheating)
        XCTAssertFalse(session.showFPS)
        XCTAssertTrue(session.limitFrames)
        XCTAssertFalse(session.daddyMode)
        // As compiled, every hash that is no cheat falls through the chain to `_SetHacked(1)` (00017e85 → 00017ec8);
        // only 0x5792ca4 skips it. gHacked is read by nothing (`_IsHacked` has no caller).
        XCTAssertTrue(session.hacked)
        XCTAssertEqual(session.phase, .paused)
    }

    // MARK: Further cheats

    /// `_Delay` blocks `_PauseGame`: the following sounds come on later ticks, and events queued meanwhile (typed
    /// characters, the Caps-Lock-off null event) are handled only once the delays are over.
    func testDelayedSoundScripts() throws {
        var now: UInt32 = 500
        let session = try pausedSession(now: &now)
        _ = session.tick(now: now, keys: HeldKeys(capsLock: true))
        let start = now
        let first = type("BONGO", into: session)
        XCTAssertEqual(first.sounds, [cue(0x2f)])
        // Typed during the delays: kept for later.
        XCTAssertEqual(type("SCORE", into: session), SessionOutput())
        var times: [UInt32] = []
        var later = SessionOutput()
        // Caps Lock already off: the pause must not end before the script and the backlog are done.
        for t in (start + 1)...(start + 60) {
            let o = session.tick(now: t, keys: HeldKeys())
            if o.sounds.contains(cue(0x2f)) { times.append(t) }
            later.append(o)
            if session.phase != .paused { break }
        }
        XCTAssertEqual(times, [start + 25, start + 50], "_Delay(25) twice")
        XCTAssertTrue(later.sounds.contains(cue(0)), "the queued SCORE ran after the delays")
        XCTAssertEqual(session.state.score, 9000)
        XCTAssertEqual(session.phase, .playing)

        // 48 sounds, `_Delay(10)` after each.
        var t2: UInt32 = 0
        let all = try pausedSession(now: &t2)
        _ = all.tick(now: t2, keys: HeldKeys(capsLock: true))
        var heard = type("FUNKY", into: all).sounds
        for t in (t2 + 1)...(t2 + 500) { heard += all.tick(now: t, keys: HeldKeys(capsLock: true)).sounds }
        XCTAssertEqual(heard, (0..<48).map { cue($0) })

        // Three squishes, `_Delay(20)` after each; then one bark ("Non the dog") typed meanwhile.
        let sq = try pausedSession(now: &t2)
        _ = sq.tick(now: t2, keys: HeldKeys(capsLock: true))
        XCTAssertEqual(type("DAVID", into: sq).sounds, [cue(0)])
        XCTAssertEqual(type("NONNY", into: sq).sounds, [], "still inside DAVID's delays")
        var rest: [SoundCue] = []
        for t in (t2 + 1)...(t2 + 100) { rest += sq.tick(now: t, keys: HeldKeys(capsLock: true)).sounds }
        XCTAssertEqual(rest, [cue(0), cue(0), cue(0x2e)])
    }

    func testFrameLimitDaddyAndFPS() throws {
        var now: UInt32 = 1000
        let session = try pausedSession(now: &now)
        XCTAssertTrue(session.limitFrames, "_PlayGame entry: gLimitFrames = 1")
        XCTAssertEqual(type("ZOOOM", into: session).sounds, [cue(0x29)])
        XCTAssertFalse(session.limitFrames)
        type("ZOOOM", into: session)
        XCTAssertTrue(session.limitFrames)
        XCTAssertEqual(type("SNAIL", into: session).sounds, [cue(0x2f)])
        XCTAssertTrue(session.daddyMode, "flag only: the 15 fps wait is the non-OS X path")
        XCTAssertEqual(type("FRAME", into: session).sounds, [cue(0)])
        XCTAssertTrue(session.showFPS)
        resume(session, now: &now)
        // `_DrawFPS(count)` once TickCount passes the last draw + 60; the count restarts at 0 (first: 30 — local_e2).
        var fps: [Int] = []
        for _ in 0..<130 {
            now += 2
            for op in session.frame(keys: HeldKeys(), now: now).drawOps {
                if case let .fps(n) = op { fps.append(n) }
            }
        }
        XCTAssertGreaterThanOrEqual(fps.count, 2)
        XCTAssertEqual(fps.dropFirst().first, 30, "60 ticks at 2 ticks per frame → 30 frames counted")
        // gShowFPS is never reset by _PlayGame — the front end carries it to the next session.
        session.showFPS = false
        XCTAssertFalse(session.showFPS)
    }

    func testGhostIconsMarkSprites() throws {
        var now: UInt32 = 0
        let session = try pausedSession(now: &now)
        XCTAssertEqual(type("GHOST", into: session).sounds, [cue(0x29, 0x14)])
        XCTAssertTrue(session.ghostIcons)
        resume(session, now: &now)
        var sprites: [DrawOp] = []
        for _ in 0..<80 {
            now += 2
            sprites += session.frame(keys: HeldKeys(), now: now).drawOps.filter(isSprite)
        }
        XCTAssertTrue(sprites.contains { if case .sprite(_, _, _, _, .ghost, _) = $0 { true } else { false } })
        XCTAssertFalse(sprites.contains { if case .sprite(_, _, _, _, .normal, _) = $0 { true } else { false } },
                       "every _SpriteToComp plots as a ghost")
    }

    /// `_NewStarGroup(col·40, row·40, 10)`: six orbit stars whose `SPIN 1` offsets are read unswapped on Intel, so
    /// `_ProcessStars` moves them off the playfield before their first draw — nothing is drawn.
    func testStarBurstDrawsNothing() throws {
        var now: UInt32 = 0
        let session = try pausedSession(now: &now)
        let before = session.state.stars.activeCount
        XCTAssertEqual(type("ALBOY", into: session).sounds, [cue(0)])
        let orbit = session.state.stars.slots.filter { $0.active && $0.motion == 2 }
        XCTAssertEqual(orbit.count, 6)
        XCTAssertEqual(session.state.stars.activeCount, before + 6)
        XCTAssertEqual(orbit.map(\.orbitIndex), [0, 10, 20, 30, 40, 50])
        let h = Int16(session.state.hero.col) * 40 + 6, v = Int16(session.state.hero.row) * 40 + 6
        XCTAssertTrue(orbit.allSatisfy { $0.rect.left == h && $0.rect.top == v })
        // SPIN 1 read as i386 does: (37, 30) big-endian → 0x2500, 0x1e00.
        XCTAssertEqual(Array(session.state.stars.orbitTable.prefix(2)), [0x2500, 0x1e00])
        resume(session, now: &now)
        var starDraws = 0
        for _ in 0..<40 {
            now += 2
            let ops = session.frame(keys: HeldKeys(), now: now).drawOps
            starDraws += ops.filter { if case .sprite(0x28, _, _, _, _, _) = $0 { true } else { false } }.count
        }
        XCTAssertEqual(starDraws, 0)
        XCTAssertFalse(session.state.stars.slots.contains { $0.active && $0.motion == 2 }, "dead after frame 5")
    }

    func testEndLevelAndRegenerateCheats() throws {
        var now: UInt32 = 0
        let session = try pausedSession(now: &now)
        let end = type("SHEBA", into: session)
        XCTAssertEqual(end.sounds, [cue(0), cue(0x23)])
        XCTAssertTrue(session.state.isEndOfLevel)
        XCTAssertEqual(session.state.endOfLevelTime, session.state.frame)

        let regen = try pausedSession(now: &now)
        let draws = regen.state.rng.drawCount
        let out = type("BOING", into: regen)
        XCTAssertEqual(Array(out.sounds.prefix(3)), [cue(0x1f, 0x14), cue(4, 0x14), cue(0xf, 10)])
        XCTAssertGreaterThan(regen.state.rng.drawCount, draws, "_RegenerateBlocks draws its cells")
        XCTAssertTrue(regen.playerIsCheating)
    }
}
