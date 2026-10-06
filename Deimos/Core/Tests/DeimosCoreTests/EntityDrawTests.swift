import XCTest
import HectorResources
@testable import DeimosCore

/// Draw-command builders (sprite-geometry-draw.md §3–§6; micro-wave §3.9): `FUN_10010c20`, `FUN_10012f20`,
/// `FUN_10012fa0`, `FUN_10013460`, `FUN_100298c0`.
final class EntityDrawTests: XCTestCase {
    typealias World = TestWorld
    private func assets() throws -> DeimosAssets { try TestAssets.loaded.get() }
    static let gameArea = MacRect(top: 0, left: 0, bottom: 480, right: 416)

    /// A solo level-1 world after the tick at `t` (so the player has been updated at 0…t).
    private func world(after t: Int32) throws -> World {
        var w = try World(assets: try assets(), players: 1)
        w.run(to: t + 1)
        return w
    }

    func testVisibilityAlpha() throws {
        let cases: [(Int32, UInt32)] = [(100, 0), (50, 16), (6, 30), (2, 31), (1, 31), (96, 1), (97, 0), (150, 16), (0, 32)]
        for (v, a) in cases { XCTAssertEqual(EntityDraw.visibilityAlpha(v), a, "v \(v)") }
        // Visibility 0 → the entry draws nothing at all.
        var e = GameObject()
        e.face = FourCC("pl1o")!
        e.visibility = 0
        XCTAssertEqual(EntityDraw.entry(&e, hOffset: 0, floats: try assets().floats), [])
    }

    func testPlayerSpriteCommand() throws {
        var w = try world(after: 105)
        XCTAssertEqual(w.players[0].object.visibility, 100)
        let cmds = EntityDraw.spriteCommands(&w.players[0].object, hOffset: 0)
        XCTAssertEqual(cmds.count, 1)
        var expected = DrawCommand.template
        expected.face = FourCC("pl1o")!
        expected.frame = 0
        expected.x = 208
        expected.y = 330
        expected.layer = 10
        XCTAssertEqual(cmds[0], expected)
        XCTAssertEqual(cmds[0].flags, 0)
        XCTAssertEqual(cmds[0].scale, 1)
        XCTAssertEqual(cmds[0].alpha, 0)
        XCTAssertEqual(cmds[0].clip, Self.gameArea)
        XCTAssertFalse(cmds[0].drawNow)
    }

    func testPlayerShadowCommand() throws {
        let floats = try assets().floats
        var w = try world(after: 105)
        let s = EntityDraw.shadowCommand(&w.players[0].object, hOffset: 0, floats: floats)
        XCTAssertEqual(s.layer, 6)
        XCTAssertEqual(s.flags, 2)
        XCTAssertEqual(s.scale, 0.5)
        XCTAssertEqual(s.x, 184)
        XCTAssertEqual(s.y, 382)
        XCTAssertEqual(s.alpha, 20)
        XCTAssertEqual(s.face, FourCC("pl1o"))
        XCTAssertEqual(s.clip, Self.gameArea)
        XCTAssertFalse(s.drawNow)

        // Visibility 2 (the first active tick, t 56): shadow alpha max(20, 31) = 31; sprite flags 1, alpha 31.
        var w2 = try world(after: 56)
        XCTAssertEqual(w2.players[0].object.visibility, 2)
        let s2 = EntityDraw.shadowCommand(&w2.players[0].object, hOffset: 0, floats: floats)
        XCTAssertEqual(s2.alpha, 31)
        XCTAssertEqual(s2.flags, 2)
        let sp = EntityDraw.spriteCommands(&w2.players[0].object, hOffset: 0)
        XCTAssertEqual(sp.map(\.flags), [1])
        XCTAssertEqual(sp.map(\.alpha), [31])
    }

    func testPlayerDrawOrder() throws {
        let floats = try assets().floats
        // State 2 (t ≤ 55): nothing.
        var early = try world(after: 55)
        XCTAssertEqual(early.players[0].lifeState, 2)
        XCTAssertEqual(EntityDraw.playerOps(&early.players[0], hOffset: 0, floats: floats), [])

        var w = try world(after: 105)
        let p = w.players[0]
        let ops = EntityDraw.playerOps(&w.players[0], hOffset: 0, floats: floats)
        let cmds: [DrawCommand] = ops.compactMap { if case .draw(let c) = $0 { return c } else { return nil } }
        XCTAssertEqual(cmds.count, ops.count)
        XCTAssertEqual(cmds.count, 3)
        // 1. The crosshair: the ground weapon's face, layer plui 13, no shadow, centred at (208, 209), queued.
        XCTAssertEqual(cmds[0].face, p.handler.ground.crosshairFace)
        XCTAssertEqual(cmds[0].layer, 13)
        XCTAssertEqual(cmds[0].flags, 0)
        XCTAssertEqual(cmds[0].alpha, 0)
        XCTAssertEqual(cmds[0].x, 208)
        XCTAssertEqual(cmds[0].y, 209)
        XCTAssertFalse(cmds[0].drawNow)
        // 2. The ship's shadow, 3. the ship.
        XCTAssertEqual(cmds[1].flags, 2)
        XCTAssertEqual(cmds[1].layer, 6)
        XCTAssertEqual(cmds[2].flags, 0)
        XCTAssertEqual(cmds[2].layer, 10)
        XCTAssertEqual(cmds[2].face, FourCC("pl1o"))
        // +0x37 / +0x38 end as they started (both 1).
        XCTAssertTrue(w.players[0].object.drawSprite)
        XCTAssertTrue(w.players[0].object.drawShadow)
        // The crosshair still fading in (t 60: visibility 6·5 = 30): flags 1, alpha 22.
        var mid = try world(after: 60)
        let midCmds = EntityDraw.playerOps(&mid.players[0], hOffset: 0, floats: floats)
        guard case .draw(let ch) = midCmds.first else { return XCTFail("no crosshair") }
        XCTAssertEqual(mid.players[0].handler.crosshair.visibility, 30)
        XCTAssertEqual(ch.flags, 1)
        XCTAssertEqual(ch.alpha, 22)
    }

    func testHOffsetPans() throws {
        let floats = try assets().floats
        var w = try world(after: 105)
        let ops = EntityDraw.playerOps(&w.players[0], hOffset: -5, floats: floats)
        let cmds: [DrawCommand] = ops.compactMap { if case .draw(let c) = $0 { return c } else { return nil } }
        XCTAssertEqual(cmds[2].x, 213)
        XCTAssertEqual(cmds[1].x, 189)
        XCTAssertEqual(cmds[0].x, 213)       // the crosshair pans too (+0x18 = 1 from FUN_10012650)
        XCTAssertEqual(cmds[2].y, 330)
        XCTAssertEqual(cmds[1].y, 382)
    }
}
