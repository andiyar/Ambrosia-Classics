import XCTest
@testable import DeimosCore

/// Phase 4 SK-a — the seam additions (plan S1a; grounding B §5, A §7, D Part 2 §3): every addition defaults to what the
/// game saw before it, and the session start's "music already playing" flag drives the level start's music branch
/// (`10006754..100067c8`).
final class SeamsTests: XCTestCase {
    private func assets() throws -> DeimosAssets { try TestAssets.loaded.get() }

    /// A `HeldKeys` built as every earlier shell and test builds it (held keys, Caps Lock, typed) has no mouse to
    /// report, the button up and no mouse, key or shell events: the session sees what it saw before Phase 4.
    func testHeldKeysMouseDefaultsUp() {
        let bare = HeldKeys()
        XCTAssertNil(bare.mouse)
        XCTAssertFalse(bare.mouseButton)
        XCTAssertEqual(bare.mouseDowns, [])
        XCTAssertEqual(bare.keyEvents, [])
        XCTAssertEqual(bare.events, [])

        let old = HeldKeys(held: [0x7B, 0x31], capsLock: true, typed: [0x61])
        XCTAssertEqual(old.held, [0x7B, 0x31])
        XCTAssertTrue(old.capsLock)
        XCTAssertEqual(old.typed, [0x61], "typed keeps its type and meaning: keyDown charCodes, no auto-repeat")
        XCTAssertNil(old.mouse)
        XCTAssertFalse(old.mouseButton)
        XCTAssertEqual(old.mouseDowns, [])
        XCTAssertEqual(old.keyEvents, [])
        XCTAssertEqual(old.events, [])
        XCTAssertEqual(old, HeldKeys(held: [0x31, 0x7B], capsLock: true, typed: [0x61], mouse: nil, mouseButton: false,
                                     mouseDowns: [], keyEvents: [], events: []))

        // The new fields hold what a shell puts in them, and an auto-repeat is marked.
        let full = HeldKeys(typed: [0x61], mouse: MousePoint(h: 320, v: 240), mouseButton: true,
                            mouseDowns: [MousePoint(h: 10, v: 20)],
                            keyEvents: [KeyEvent(charCode: 0x61, keyCode: 0x00),
                                        KeyEvent(charCode: 0x61, keyCode: 0x00, autoRepeat: true)],
                            events: [.aboutChosen, .answer(.second)])
        XCTAssertEqual(full.mouse, MousePoint(h: 320, v: 240))
        XCTAssertTrue(full.mouseButton)
        XCTAssertEqual(full.keyEvents.map(\.autoRepeat), [false, true])
        XCTAssertNotEqual(full, HeldKeys(typed: [0x61]))
    }

    /// Plan Phase 4 correction ("music already playing"): the level start runs `FUN_10048120(0)` + `FUN_10047f90(
    /// 'ammu', 1, 0)` only when not a film AND `FUN_10047f80()` (the music-playing byte `DAT_100e02a0`) is 0
    /// (`10006754..1000678c`: `bne 0x10006790` on each), then — not a film — `FUN_10048120(0)` (`100067bc..100067c8`).
    /// With the flag the first level start's music is the stop alone, then the engine level; by default (no music
    /// playing) it is `ammu` then the stop, as before. Bound: one pass each.
    func testMusicAlreadyPlayingOnlyStops() throws {
        let a = try assets()
        let ammu = MusicCue.play(FourCC("ammu")!, loop: true)
        let level = MusicCue.level(DeimosPrefs.fresh.intPrefs[1])

        XCTAssertFalse(SessionStart(sector: 1, players: 1, film: nil).musicAlreadyPlaying, "default: no music playing")

        var playing = try DeimosSession(assets: a, prefs: .fresh,
                                        start: SessionStart(sector: 1, players: 1, film: nil, musicAlreadyPlaying: true),
                                        seed: 0x469c2)
        let p = playing.pass(keys: HeldKeys(), ticks: 0)
        XCTAssertEqual(Array(p.music.prefix(2)), [.stop, level])
        XCTAssertFalse(p.music.contains(ammu), "the music is playing: no stop-and-play of ammu")

        var silent = try DeimosSession(assets: a, prefs: .fresh, start: SessionStart(sector: 1, players: 1, film: nil),
                                       seed: 0x469c2)
        let q = silent.pass(keys: HeldKeys(), ticks: 0)
        XCTAssertEqual(Array(q.music.prefix(3)), [ammu, .stop, level])

        // The flag touches the music only: the same ops and the same game.
        XCTAssertEqual(p.ops, q.ops)
        XCTAssertEqual(p.sounds, q.sounds)
        XCTAssertEqual(playing.rng, silent.rng)
        XCTAssertEqual(Array(p.music.dropFirst(2)), Array(q.music.dropFirst(3)))
    }
}
