import XCTest
@testable import AkiCore

/// P1.4 — the map screen's rules and art rects (`_MapScreen` DC:2355, `_RedrawMapScreen` DC:2606,
/// `_SelectMapArea` DC:2782, `_SelectMenuOptions` DC:2949; docs/aki/levels.md §4–5).
final class AkiMapTests: XCTestCase {

    private func settings(unlocked indices: [Int], difficulty: Int16 = 1) -> GameSettings {
        var s = GameSettings.defaults
        s.unlocked = (0..<12).map { indices.contains($0) ? 1 : 0 }
        s.difficultyRaw = difficulty
        return s
    }
    private func centre(_ i: Int) -> (h: Int, v: Int) { (AkiMap.lanterns[i].left + 37, AkiMap.lanterns[i].top + 35) }

    func testLanternTableIsTheDecompiledOne() {
        XCTAssertEqual(AkiMap.lanterns.map(\.left), [713, 403, 231, 89, 12, 234, 326, 355, 547, 434, 374, 405])
        XCTAssertEqual(AkiMap.lanterns.map(\.top), [310, 176, 115, 45, 269, 356, 281, 294, 315, 223, 216, 244])
    }

    func testLanternBoxIsInclusiveOnAllFourEdges() {
        XCTAssertTrue(AkiMap.lanternContains(0, h: 736, v: 327))
        XCTAssertTrue(AkiMap.lanternContains(0, h: 765, v: 364))
        XCTAssertFalse(AkiMap.lanternContains(0, h: 735, v: 340))
        XCTAssertFalse(AkiMap.lanternContains(0, h: 766, v: 340))
        XCTAssertFalse(AkiMap.lanternContains(0, h: 750, v: 326))
        XCTAssertFalse(AkiMap.lanternContains(0, h: 750, v: 365))
    }

    func testHoverIndexPicksTheLastOverlappingLantern() {
        for i in 0..<12 {
            let c = centre(i)
            XCTAssertEqual(AkiMap.hoverIndex(h: c.h, v: c.v), i, "lantern \(i)")
        }
        XCTAssertEqual(AkiMap.hoverIndex(h: 378, v: 320), 7)
        XCTAssertNil(AkiMap.hoverIndex(h: 0, v: 0))
    }

    func testBarClickRowAndActionRanges() {
        XCTAssertEqual([558, 559, 588, 589].map(AkiMap.isBarClick), [false, true, true, false])
        XCTAssertEqual([31, 32, 189, 190].map(AkiMap.barAction), [nil, .preferences, .preferences, nil])
        XCTAssertEqual([283, 284, 315, 316, 319].map(AkiMap.barAction), [nil, .difficultyNext, .difficultyNext, nil, nil])
        XCTAssertEqual([320, 515, 516].map(AkiMap.barAction), [.difficultyPrevious, .difficultyPrevious, nil])
        XCTAssertEqual([597, 598, 765, 766, -5].map(AkiMap.barAction), [nil, .quit, .quit, nil, nil])
        XCTAssertEqual(AkiMap.cycleDifficulty(0, up: true), 1)
        XCTAssertEqual(AkiMap.cycleDifficulty(3, up: true), 0)
        XCTAssertEqual(AkiMap.cycleDifficulty(0, up: false), 3)
        XCTAssertEqual(AkiMap.cycleDifficulty(7, up: true), 0)
        XCTAssertEqual(AkiMap.cycleDifficulty(7, up: false), 6)
    }

    func testSelectRespectsLocksAndOption() {
        let first = settings(unlocked: [0])
        let level2 = centre(1), level1 = centre(0)
        XCTAssertEqual(AkiMap.select(h: level2.h, v: level2.v, optionDown: false, settings: first),
                       AkiMap.Selection(unavailableDialogs: 1, chosen: nil))
        XCTAssertEqual(AkiMap.select(h: level2.h, v: level2.v, optionDown: true, settings: first),
                       AkiMap.Selection(unavailableDialogs: 0, chosen: 1))
        XCTAssertEqual(AkiMap.select(h: level1.h, v: level1.v, optionDown: false, settings: first),
                       AkiMap.Selection(unavailableDialogs: 0, chosen: 0))
        XCTAssertEqual(AkiMap.select(h: 5, v: 5, optionDown: false, settings: first),
                       AkiMap.Selection(unavailableDialogs: 0, chosen: nil))
        XCTAssertEqual(AkiMap.select(h: 378, v: 320, optionDown: false, settings: settings(unlocked: [0, 6])),
                       AkiMap.Selection(unavailableDialogs: 1, chosen: 6))
    }

    func testPracticeAlertAndGuide() {
        XCTAssertTrue(AkiMap.needsPracticeAlert(level: 0, settings: settings(unlocked: [0], difficulty: 3)))
        XCTAssertFalse(AkiMap.needsPracticeAlert(level: 0, settings: settings(unlocked: [0, 1], difficulty: 3)))
        XCTAssertFalse(AkiMap.needsPracticeAlert(level: 0, settings: settings(unlocked: [0], difficulty: 2)))
        XCTAssertFalse(AkiMap.needsPracticeAlert(level: 11, settings: settings(unlocked: Array(0..<12), difficulty: 3)))
        XCTAssertTrue(AkiMap.showsGuide(settings: settings(unlocked: [0]), guideFlag: true))
        XCTAssertFalse(AkiMap.showsGuide(settings: settings(unlocked: [0]), guideFlag: false))
        XCTAssertFalse(AkiMap.showsGuide(settings: settings(unlocked: [0, 1]), guideFlag: true))
    }

    func testBlinkingAndLitLanterns() {
        let cases: [(unlocked: [Int], lit: Int, blink: Int)] = [
            ([0], 0, 0), (Array(0...3), 3, 3), (Array(0..<12), 11, 11), ([], 12, 0),
        ]
        for c in cases {
            let s = settings(unlocked: c.unlocked)
            XCTAssertEqual(AkiMap.litLanternCount(settings: s), c.lit, "\(c.unlocked)")
            XCTAssertEqual(AkiMap.blinkingLantern(settings: s), c.blink, "\(c.unlocked)")
        }
    }

    func testTickGateAndBlinkSequence() {
        XCTAssertFalse(AkiMap.tickDue(now: 106, last: 100))
        XCTAssertTrue(AkiMap.tickDue(now: 107, last: 100))
        var blink = AkiMap.Blink()
        XCTAssertEqual([blink.phase, blink.rising ? 1 : 0], [0, 1])
        var phases: [Int] = []
        for _ in 0..<12 { blink.step(); phases.append(blink.phase) }
        XCTAssertEqual(phases, [1, 2, 3, 2, 1, 0, 1, 2, 3, 2, 1, 0])
    }

    func testArtRectsAreTheDecompiledOnes() {
        XCTAssertEqual(AkiMap.difficultyWord(3), QDRect(left: 296, top: 310, right: 379, bottom: 333))
        XCTAssertEqual(AkiMap.difficultyWordMask(0), QDRect(left: 379, top: 241, right: 462, bottom: 264))
        XCTAssertEqual(AkiMap.previewStrip(11), QDRect(left: 0, top: 1991, right: 236, bottom: 2171))
        XCTAssertEqual(AkiMap.litLanternDestination(0), QDRect(left: 713, top: 310, right: 787, bottom: 382))
        XCTAssertEqual(AkiMap.blinkDestination(0), QDRect(left: 713, top: 310, right: 788, bottom: 383))
        XCTAssertEqual(AkiMap.blinkMasks, [QDRect(left: 280, top: 336, right: 355, bottom: 409),
                                           QDRect(left: 355, top: 336, right: 430, bottom: 409),
                                           QDRect(left: 281, top: 149, right: 356, bottom: 222),
                                           QDRect(left: 356, top: 149, right: 431, bottom: 222)])

        // Every remaining rect, from the decompile's own literals (DC = Aki12_i386.decompiled.c).
        // The lantern table: `local_68` (left) / `local_98` (top) in `_MapScreen` DC:2383–2406,
        // the same values in `_RedrawMapScreen`'s `local_94` DC:2624–2671.
        let lefts = [0x2c9, 0x193, 0xe7, 0x59, 0xc, 0xea, 0x146, 0x163, 0x223, 0x1b2, 0x176, 0x195]
        let tops = [0x136, 0xb0, 0x73, 0x2d, 0x10d, 0x164, 0x119, 0x126, 0x13b, 0xdf, 0xd8, 0xf4]
        // Lantern sprite + static mask: `_RedrawMapScreen` DC:2726/2730 (sprite also `_MapScreen` DC:2474).
        XCTAssertEqual(AkiMap.lanternSprite, QDRect(left: 0xcd, top: 0x150, right: 0x118, bottom: 0x199))
        XCTAssertEqual(AkiMap.lanternStaticMask, QDRect(left: 0x118, top: 0x150, right: 0x163, bottom: 0x199))
        for i in 0..<12 {
            // Static lit lantern: `_RedrawMapScreen` DC:2727–2729 (left, top, left+0x4a, top+0x48).
            XCTAssertEqual(AkiMap.litLanternDestination(i),
                           QDRect(left: lefts[i], top: tops[i], right: lefts[i] + 0x4a, bottom: tops[i] + 0x48), "lit \(i)")
            // Blink (and restore): `_MapScreen` DC:2465–2471 (left, top, left+0x4b, top+0x49).
            XCTAssertEqual(AkiMap.blinkDestination(i),
                           QDRect(left: lefts[i], top: tops[i], right: lefts[i] + 0x4b, bottom: tops[i] + 0x49), "blink \(i)")
            // Preview strip: `_MapScreen` DC:2577 (0, s*0xb5, 0xec, s*0xb5+0xb4).
            XCTAssertEqual(AkiMap.previewStrip(i), QDRect(left: 0, top: i * 0xb5, right: 0xec, bottom: i * 0xb5 + 0xb4), "preview \(i)")
        }
        for d in 0...3 {
            // Difficulty word + mask: `_RedrawMapScreen` DC:2753–2757 (top d*0x17+0xf1, bottom d*0x17+0x108).
            XCTAssertEqual(AkiMap.difficultyWord(d), QDRect(left: 0x128, top: d * 0x17 + 0xf1, right: 0x17b, bottom: d * 0x17 + 0x108), "word \(d)")
            XCTAssertEqual(AkiMap.difficultyWordMask(d), QDRect(left: 0x17b, top: d * 0x17 + 0xf1, right: 0x1ce, bottom: d * 0x17 + 0x108), "mask \(d)")
        }
        XCTAssertEqual(AkiMap.difficultyWordDestination, QDRect(left: 0x163, top: 0x235, right: 0x1b6, bottom: 0x24c))
        // Arrows: rest = `_RedrawMapScreen` DC:2678–2684 (word dest DC:2755); pressed = `_SelectMenuOptions` DC:3007/2984.
        XCTAssertEqual(AkiMap.leftArrowSprite, QDRect(left: 0, top: 0x55, right: 0x21, bottom: 0x71))
        XCTAssertEqual(AkiMap.leftArrowMask, QDRect(left: 0, top: 0x71, right: 0x21, bottom: 0x8d))
        XCTAssertEqual(AkiMap.leftArrowRest, QDRect(left: 0x118, top: 0x232, right: 0x139, bottom: 0x24e))
        XCTAssertEqual(AkiMap.leftArrowPressed, QDRect(left: 0x11a, top: 0x234, right: 0x13b, bottom: 0x250))
        XCTAssertEqual(AkiMap.rightArrowSprite, QDRect(left: 0x21, top: 0x55, right: 0x42, bottom: 0x71))
        XCTAssertEqual(AkiMap.rightArrowMask, QDRect(left: 0x21, top: 0x71, right: 0x42, bottom: 0x8d))
        XCTAssertEqual(AkiMap.rightArrowRest, QDRect(left: 0x1df, top: 0x232, right: 0x200, bottom: 0x24e))
        XCTAssertEqual(AkiMap.rightArrowPressed, QDRect(left: 0x1e1, top: 0x234, right: 0x202, bottom: 0x250))
        // Preview destination / restore: `_MapScreen` DC:2578 / DC:2564–2565.
        XCTAssertEqual(AkiMap.previewDestination, QDRect(left: 0x207, top: 0x2b, right: 0x2f2, bottom: 0xde))
        XCTAssertEqual(AkiMap.previewRestore, QDRect(left: 0x207, top: 0x2b, right: 0x2f3, bottom: 0xdf))
        // Locked overlay, its mask and destination: `_MapScreen` DC:2584 / DC:2592 / DC:2591.
        XCTAssertEqual(AkiMap.lockedOverlay, QDRect(left: 0, top: 100, right: 0xf0, bottom: 0x96))
        XCTAssertEqual(AkiMap.lockedOverlayMask, QDRect(left: 0, top: 0x32, right: 0xf0, bottom: 100))
        XCTAssertEqual(AkiMap.lockedOverlayDestination, QDRect(left: 0x206, top: 0x6e, right: 0x2f6, bottom: 0xa0))
    }
}
