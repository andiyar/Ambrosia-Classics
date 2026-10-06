import XCTest
@testable import DeimosCore

/// The LOCKED seam types and the fresh prefs (plan C1; sprite-geometry-draw §3.1, timing-frame §6, engine-loop §10).
final class SeamTests: XCTestCase {
    /// The runtime draw-command template `0x100e63e4` after the static initialiser `FUN_10014120`
    /// (sprite-geometry-draw §3.1, INDEX #56): clip {0, 0, 480, 416}, layer 7, scale 1.0, colour 0x7fff.
    func testDrawCommandRuntimeTemplate() {
        let t = DrawCommand.template
        XCTAssertEqual(t.face, .none)
        XCTAssertEqual(t.frame, 0)
        XCTAssertEqual(t.x, 0)
        XCTAssertEqual(t.y, 0)
        XCTAssertEqual(t.flags, 0)
        XCTAssertEqual(t.scale, Float(1.0))
        XCTAssertEqual(t.alpha, 0)
        XCTAssertEqual(t.clip, MacRect(top: 0, left: 0, bottom: 480, right: 416))
        XCTAssertEqual(t.layer, 7)
        XCTAssertFalse(t.drawNow)
        XCTAssertEqual(t.colour, 0x7fff)
        XCTAssertNil(t.costRect)
        XCTAssertEqual(t.costColour, 0)
        // The default initialiser is the template.
        XCTAssertEqual(DrawCommand(), t)
    }

    /// `FUN_10004540` → `FUN_10004ae0` + `FUN_10004f20(1)`: timing-frame §6 table, engine-loop §10 defaults.
    func testFreshPrefs() {
        let p = DeimosPrefs.fresh
        XCTAssertEqual(p.version, 0x2714)
        let bytes: [Int: UInt8] = [2: 0, 4: 1, 5: 0, 6: 0, 7: 0, 8: 0, 9: 0, 10: 1]
        for (n, v) in bytes { XCTAssertEqual(p.bytePrefs[n], v, "byte pref \(n)") }
        XCTAssertEqual(p.intPrefs, [50, 100, 50, 1])
        XCTAssertEqual(p.keyTable, [0x7E, 0x7B, 0x7C, 0x7D, 0x37, 0x3A, 0x31,
                                    0x5B, 0x56, 0x58, 0x57, 0x77, 0x75, 0x79])
        XCTAssertEqual(p.highScores, stride(from: 15_000, through: 1_000, by: -1_000).map { Int32($0) })
        XCTAssertEqual(p.highScoreNames, ["Mars", "Supercobra", "Neurotik", "El B", "Dilvish", "Sam", "Vodi", "Fisj",
                                          "Alex", "h'biki", "Goldenberry", "Leadfeather", "Troll", "Thomas",
                                          "Electrofryer"])
        XCTAssertEqual(p.highScoreSectorNames, Array(repeating: "New Atlantis", count: 15))
        XCTAssertEqual(p.playerNames, ["Player 1", "Player 2"])
    }
}
