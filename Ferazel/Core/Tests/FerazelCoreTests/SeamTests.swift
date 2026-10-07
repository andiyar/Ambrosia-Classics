import XCTest
import FerazelCore

/// R1 (docs/plans/2026-10-06-ferazel-phase1.md): the LOCKED seam types of plan S3 and the prefs record's `.InitPrefs`
/// defaults (engine §7.1, §8; save-continue §8.2; decompile `.InitPrefs @ 1000f180`).
final class SeamTests: XCTestCase {

    func testSeamTypesEquatableAndDefaults() {
        // FrameOps: the empty iteration.
        let empty = FrameOps()
        XCTAssertEqual(empty, FrameOps(draws: [], sounds: [], music: [], requests: [], drawn: true))
        XCTAssertTrue(empty.draws.isEmpty && empty.sounds.isEmpty && empty.music.isEmpty && empty.requests.isEmpty)
        XCTAssertTrue(empty.drawn)
        XCTAssertNotEqual(empty, FrameOps(drawn: false))

        // DrawOp / SpriteDraw / FaceRef / StatusBarState compare by value.
        let face = FaceRef(pict: 1020, index: 5, set: .encoded)
        XCTAssertEqual(face, FaceRef(pict: 1020, index: 5, set: .encoded))
        XCTAssertNotEqual(face, FaceRef(pict: 1020, index: 5, set: .flipped))
        let sprite = SpriteDraw(face: face, x: 83, y: 143, mode: 0x9_0000, mirrored: true,
                                clip: SpriteClip(left: 1, right: 2, bottom: 3, top: 4), lightOverlay: true, waterRow: 0)
        var other = SpriteDraw(face: FaceRef(pict: 1020, index: 5, set: .encoded), x: 83, y: 143, mode: 0x9_0000,
                               mirrored: true, clip: SpriteClip(left: 1, right: 2, bottom: 3, top: 4), lightOverlay: true,
                               waterRow: 0)
        XCTAssertEqual(sprite, other)
        other.clip.top = 5
        XCTAssertNotEqual(sprite, other)
        XCTAssertEqual(SpriteClip(), SpriteClip(left: 0, right: 0, bottom: 0, top: 0))
        func levelStart() -> [DrawOp] {
            [
                .setScreenClut(id: 202),
                .drawPicture(id: 129, chain: .frontEnd, h: 0, v: 0),
                .redrawEntireScrollGrid(h: 0, v: 10),
                .redrawScrollGrid(h: 0, v: 10),
                .drawLightsOntoTiles,
                .wrapDrawSprites([SpriteDraw(face: FaceRef(pict: 1020, index: 5, set: .encoded), x: 83, y: 143,
                                             mode: 0x9_0000, mirrored: true,
                                             clip: SpriteClip(left: 1, right: 2, bottom: 3, top: 4), lightOverlay: true,
                                             waterRow: 0)]),
                .copyToScreen(h: 0, v: 10, graphicsMode: 1, backdrop: true),
                .statusBar(StatusBarState(score: 0, coins: 0, health: 30, breath: 0, magic: 0,
                                          levelName: "A Scent Of Peril", selectedSlot: 0)),
            ]
        }
        let ops = levelStart()
        XCTAssertEqual(ops, levelStart())
        XCTAssertEqual(ops[5], .wrapDrawSprites([sprite]))
        XCTAssertNotEqual(DrawOp.redrawScrollGrid(h: 0, v: 10), .redrawScrollGrid(h: 0, v: 42))
        XCTAssertNotEqual(DrawOp.redrawEntireScrollGrid(h: 0, v: 10), .redrawScrollGrid(h: 0, v: 10))
        XCTAssertNotEqual(DrawOp.redrawEntireScrollGrid(h: 0, v: 10), .redrawEntireScrollGrid(h: 32, v: 10))
        XCTAssertNotEqual(DrawOp.drawPicture(id: 129, chain: .frontEnd, h: 0, v: 0),
                          .drawPicture(id: 129, chain: .level, h: 0, v: 0))
        XCTAssertEqual(StatusBarState(), StatusBarState(score: 0, coins: 0, health: 0, breath: 0, magic: 0, levelName: "",
                                                        selectedSlot: 0))
        XCTAssertEqual(SoundCue(snd: 128, priority: 1, left: 255, right: 255, rate: 0x5622_0000),
                       SoundCue(snd: 128, priority: 1, left: 255, right: 255, rate: 0x5622_0000))
        XCTAssertNotEqual(MusicCue.play(track: 1), .play(track: 2))
        XCTAssertNotEqual(MusicCue.stop, .volume(0))
        XCTAssertEqual(Set([ShellRequest.hideCursor, .showCursor, .hideMenuBar, .showMenuBar].map { "\($0)" }).count, 4)

        // FerazelPrefs: `.InitPrefs`' fresh record on a modern Mac (`cput` ≥ 0x108).
        let prefs = FerazelPrefs()
        XCTAssertEqual(prefs.reduceFrameRate, 0)
        XCTAssertEqual(prefs.reuseSavedGames, 0)
        XCTAssertEqual(prefs.graphics, 1)          // High Detail
        XCTAssertEqual(prefs.parallax, 2)          // Parallax
        XCTAssertEqual(prefs.effects, 1)           // Enhanced
        XCTAssertEqual(FerazelPrefs(processorType: 0x107).effects, 2)
        XCTAssertEqual(prefs.backgroundTasks, 0)
        XCTAssertEqual(prefs.plainCopy, 0)
        XCTAssertEqual(prefs.useInputSprocket, 0)
        XCTAssertEqual(prefs.soundOn, 1)
        XCTAssertEqual(prefs.musicOn, 1)
        XCTAssertEqual(prefs.soundVolume, 7)
        XCTAssertEqual(prefs.musicVolume, 9)
        XCTAssertEqual(prefs.keys, [0x56, 0x58, 0x5b, 0x57, 0x38, 0x3a, 0x37, 0x59, 0x5c])
        XCTAssertEqual(prefs.key2a, 0x30)
        XCTAssertEqual(prefs.key30, 0x4c)
        XCTAssertEqual(prefs.resolutionSwitch, 0)
        XCTAssertEqual(prefs.askResolution, 1)
        XCTAssertEqual(prefs.useSystemVolume, 0)
        XCTAssertEqual(FerazelPrefs(systemVolume: 0x100).systemVolumeBy28, 9)
        XCTAssertEqual(prefs.machineHash, -1)
        XCTAssertEqual([prefs.unread3c, prefs.unread3e, prefs.unread40], [0, 0, 0])
        XCTAssertEqual(prefs.savedGameName, "@@@@@")

        // KeyState / InputActions: `IsPressed(prefs[0x12 + 2i])`.
        XCTAssertEqual(InputActions(keys: KeyState(), prefs: prefs), [])
        let keys = KeyState(pressed: [0x56, 0x38, 0x5c, 0x7b])   // keypad 4, Shift, keypad 9, left arrow
        XCTAssertTrue(keys.isPressed(0x56))
        XCTAssertFalse(keys.isPressed(0x58))
        XCTAssertEqual(keys.bytes[10], 0x40)   // 0x56: byte 0x56 >> 3, bit 0x56 & 7
        XCTAssertEqual(InputActions(keys: keys, prefs: prefs), [.left, .run, .nextItem])
        XCTAssertEqual(InputActions.action(5), .jump)
        var released = keys
        released.release(0x38)
        XCTAssertEqual(InputActions(keys: released, prefs: prefs), [.left, .nextItem])
    }
}
