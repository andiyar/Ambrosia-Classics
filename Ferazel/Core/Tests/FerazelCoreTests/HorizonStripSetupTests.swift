import XCTest
import HectorResources
@testable import FerazelCore

/// 6A-S8 (docs/superpowers/plans/2026-11-04-ferazel-remainder.md `#### 6A-S8`; docs/ferazel/phase6-engine-contracts.md
/// §2.1): the horizon strip's sprites as Core records, made by `.SetupLevel` (`PxSprites.create`) after
/// `.KillAllSprites` and before `.SetupLevelSprites`. Level 10 on the level fixture (6A-FX), headless — the strip
/// sprites need no pixels. A missing data file is a FAILURE, never a skip.
final class HorizonStripSetupTests: XCTestCase {

    /// Level 10's leave-out list (6A-S8; LL §4 "Level 10", ENG §7.2): its 31 refused records. A literal list, never
    /// computed from what the port refuses today — 6A-WD reuses it unchanged; 6A-RC and 6A-TR write their own.
    static let level10: [LevelFixture.LeaveOut] = [
        // The trees (6A-TR): 3080 ×2, 3081 ×4, 3082 ×4, 3083 ×3.
        .type(3080), .type(3081), .type(3082), .type(3083),
        // The Box scenery (6A-BX1a): 2816 ×5, 2817, 2837 ×3, 2846 ×2, 2847 ×2, 2861.
        .type(2816), .type(2817), .type(2837), .type(2846), .type(2847), .type(2861),
        // The rotating cannons (6A-RC): 1097 ×1, and the three 1090 records with p1 101 / 103 (read once from the
        // level file: placements 89 p1 101, 200 p1 103, 250 p1 103; 251–253 have p1 0 and set up today).
        .type(1097), .record(89), .record(200), .record(250),
    ]

    private struct Stuck: Error {}

    /// Ticks `run` from `now` until its session exists (`.SetupLevel` ran); returns the merged draws of those ticks.
    private func setUpLevel(_ run: LevelRun, from now: UInt32 = 0) throws -> [DrawOp] {
        var t = now, draws: [DrawOp] = []
        while run.session == nil {
            draws += try run.tick(now: t, input: FrontInput()).merged.draws
            t += 1
            guard t < now + 2000 else { throw Stuck() }
        }
        return draws
    }

    /// The load bars' fills (`StageScreens.updateStageLoad`, the bar at top 0xd5).
    private func bars(_ draws: [DrawOp]) -> [DrawOp] {
        draws.filter { if case .fillRect(_, let top, _, _, _) = $0 { return top == 0xd5 }; return false }
    }

    func testStripSpritesAreTheFirstAllocations() throws {
        let base = try LevelFixture.base.get()
        let real = try LevelFile.load(from: base, level: 10)
        let out = try LevelFixture.leftOut(real, Self.level10)
        XCTAssertEqual(out.count, 31, "the 31 refused records")
        XCTAssertEqual(Self.level10.count, 14)
        var perType: [Int16: Int] = [:]
        for i in out { perType[real.placements[i].type, default: 0] += 1 }
        XCTAssertEqual(perType, [3080: 2, 3081: 4, 3082: 4, 3083: 3, 2816: 5, 2817: 1, 2837: 3, 2846: 2, 2847: 2,
                                 2861: 1, 1097: 1, 1090: 3])
        XCTAssertEqual([89, 200, 250].map { real.placements[$0].p1 }, [101, 103, 103])
        XCTAssertEqual(real.activePlacements.filter { $0.type == 1090 }.map(\.index), [89, 200, 250, 251, 252, 253])
        XCTAssertEqual([251, 252, 253].map { real.placements[$0].p1 }, [0, 0, 0])
        // The header that switches the strip on: PICT 265, x factor 128, y 222 (as read — `.BuildSineTable`'s clamp to
        // 100 never touches a loaded level), the PxBack y factor 56, W 360; `0x26cc` 0 (no level+base swap).
        let h = real.header
        XCTAssertEqual([h.stripPict, h.stripFactor, h.stripBaseY, h.pxBackYFactor, h.gridWidth], [265, 128, 222, 56, 360])
        XCTAssertEqual(h.pxUsesLevelBaseClut, 0)

        // The fixture opens through `LevelRun` (every active record set up, no refusal) on the long path.
        let run = try LevelFixture.open(level: 10, leaveOut: Self.level10)
        let longDraws = try setUpLevel(run)
        XCTAssertEqual(Array(bars(longDraws).prefix(2)), [StageScreens.updateStageLoad(0xf, of: 100).draws[0],
                                                          StageScreens.updateStageLoad(0x14, of: 100).draws[0]],
                       "the long path's bars")
        let s = try XCTUnwrap(run.session)
        let strip = s.horizonStrip
        let face = FaceRef(pict: 265, index: 0, set: .backgroundsSingle)

        // The strip sprites are the level's first nine allocations (ids 1…9), at the head of the list (layer −500).
        XCTAssertEqual(strip.ids, Array(1...9))
        XCTAssertEqual(s.world.active.sprites.prefix(9).map(\.id), Array(1...9))
        XCTAssertTrue(s.world.active.sprites.dropFirst(9).allSatisfy { $0.id > 9 })
        XCTAssertEqual(strip.outcome, .added(faceClut: 200), "converted under clut 200 (M l. 2273, 404–405)")
        XCTAssertEqual(strip.faceClut, 200)
        XCTAssertEqual(strip.clutAfter, 200, "`*_DAT_1009ff94` restored (M l. 30919)")
        // The table: ids at entries 0, 2, … 16 (count + k with the count advanced, M l. 30904), one face.
        XCTAssertEqual(strip.table.sprites, (0..<32).map { $0 % 2 == 0 && $0 <= 16 ? $0 / 2 + 1 : nil })
        XCTAssertEqual(strip.table.spriteCount, 9)
        XCTAssertEqual(strip.table.faceCount, 1)
        XCTAssertEqual(strip.table.faces, [face] + Array(repeating: nil, count: 31))
        for (k, id) in strip.ids.enumerated() {
            let r = try XCTUnwrap(s.world.active.record(id: id))
            // `.MTAddPxSprite`'s stores (M l. 30905–30913).
            XCTAssertEqual(r.face, face, "sprite \(k)")
            XCTAssertEqual(r.classTimer, Int32(768 * k), "+0x14c")
            XCTAssertEqual(r.classWord150, 222, "+0x150")
            XCTAssertEqual(r.classWord154, 128, "+0x154")
            XCTAssertEqual(r.classWord158, 56, "+0x158")
            XCTAssertEqual(r.layer, -500)
            // `.SetupPxSprite`'s stores, each one (M l. 30806–30815), and `.MTNewSprite`'s `+0x48` re-store −1.
            XCTAssertEqual(r.hotRect, IdleSprites.Rect(top: 0, left: 0, bottom: 0, right: 0), "empty rect")
            XCTAssertEqual(r.recordIndex, -1, "+0x48: `.MTNewSprite` re-stores its −1 after the Setup's 0x1ff")
            XCTAssertTrue(r.killedForGood, "+0xea = 1")
            XCTAssertEqual(r.type, 1)
            XCTAssertFalse(r.lightOverlay, "+0x88 = 0")
            XCTAssertFalse(r.hasHit, "+0x5c = 0")
            XCTAssertFalse(r.hasTileHit, "+0x1f8 = 0")
            XCTAssertEqual(r.handler, .pxSprite)
            XCTAssertEqual(r.mode, 0x80000)
            XCTAssertFalse(r.mirrored)
        }
        // The Setup alone stores `+0x48 = 0x1ff` (M l. 30808) over a record that held something else.
        var lone = SpriteSlot(type: 0, x: 0, y: 0, recordIndex: 5)
        lone.hotRect = IdleSprites.Rect(top: 1, left: 2, bottom: 3, right: 4)
        lone.lightOverlay = true
        lone.hasHit = true
        lone.hasTileHit = true
        PxSprites.setup(&lone)
        XCTAssertEqual(lone.recordIndex, 0x1ff)
        XCTAssertEqual(lone.hotRect, IdleSprites.Rect(top: 0, left: 0, bottom: 0, right: 0))
        XCTAssertEqual([lone.lightOverlay, lone.hasHit, lone.hasTileHit, !lone.killedForGood], [false, false, false, false])
        XCTAssertEqual(lone.type, 1)
        XCTAssertEqual(lone.mode, 0x80000)
        XCTAssertEqual(lone.handler, .pxSprite)
        // No write-back to any placement (`+0x48` = −1 live, 0x1ff from the Setup alone: both outside 0 … 0x1fe): a
        // world holding only the strip writes no record in `.UpdateSprites`, and keeps the strip.
        let bare = SpriteWorld(level: real)
        let made = PxSprites.create(header: h, backgrounds: base.backgrounds, clut: 200, world: bare)
        XCTAssertEqual(made.ids, Array(1...9))
        for id in made.ids { bare.active.update(id: id) { $0.x = 4000; $0.y = 300 } }
        var lights = LightTable()
        bare.updateSprites(lights: &lights)
        XCTAssertEqual(bare.records, real.placements)
        XCTAssertEqual(bare.active.sprites.map(\.id), Array(1...9))
        bare.active.update(id: 1) { $0.recordIndex = 0x1ff }
        bare.updateSprites(lights: &lights)
        XCTAssertEqual(bare.records, real.placements)

        // A death's restart takes the fast path (same level, tilesets kept: M l. 2252–2268) — the strip is made again,
        // nine sprites in the same slots, its face under the same table (no writer between the level's start and the
        // restart leaves `*_DAT_1009ff94` other than clut 200 on a strip level: `LevelRun.setupLevel`).
        let carry = run.carry
        XCTAssertEqual(carry.tilesetLevel, 10)
        XCTAssertFalse(carry.tilesetsDisposed)
        let again = try LevelFixture.open(level: 10, leaveOut: Self.level10, carry: carry)
        let fastDraws = try setUpLevel(again, from: 9000)
        XCTAssertEqual(Array(bars(fastDraws).prefix(2)), [StageScreens.updateStageLoad(0x19, of: 100).draws[0],
                                                          StageScreens.updateStageLoad(0x32, of: 100).draws[0]],
                       "the fast path's bars: 25 %, then 50 %")
        let s2 = try XCTUnwrap(again.session)
        XCTAssertEqual(s2.horizonStrip, strip)
        XCTAssertEqual(s2.horizonStrip.faceClut, 200)
        XCTAssertEqual(s2.world.active.sprites.prefix(9).map(\.id), Array(1...9))
        for id in s2.horizonStrip.ids {
            XCTAssertEqual(s2.world.active.record(id: id)?.handler, .pxSprite)
            XCTAssertEqual(s2.world.active.record(id: id)?.face, face)
        }
    }
}
