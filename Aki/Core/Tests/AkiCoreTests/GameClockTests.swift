import XCTest
@testable import AkiCore

/// P2.4 — the time state of `_g` (a8…c0): `_AnimationMapScreenToCustom` @ 0x10f5f, `_CustomGameScreen`
/// @ 0x12dbc, `_RedrawCustomTimeBar` @ 0xefa0, `_PauseGame` @ 0xd34b (docs/aki/rules.md §0, §10, §11, §13).
final class GameClockTests: XCTestCase {

    private let order: [Difficulty] = [.hard, .medium, .easy, .practice]

    func testStartState() {
        let clock = GameClock(start: 1000)
        XCTAssertEqual(clock.baseTick, 1000)
        XCTAssertEqual(clock.remaining, 150)
        XCTAssertEqual(clock.penalty, 0)
        XCTAssertEqual(clock.bonus, 0)
        XCTAssertEqual(clock.elapsed, 0)
        XCTAssertEqual(clock.frozenRemaining, 0)
        XCTAssertEqual(clock.freezeTick, 0)
        XCTAssertEqual(GameClock.limitSeconds, 150)
        XCTAssertEqual(GameClock.capSeconds, 300)
    }

    func testUpdateFormula() {
        var clock = GameClock(start: 0)
        clock.update(now: 600)
        XCTAssertEqual(clock.elapsed, 10)
        XCTAssertEqual(clock.remaining, 140)
        clock.penalty = 5
        clock.bonus = 12
        clock.update(now: 600)
        XCTAssertEqual(clock.remaining, 147)
        clock.update(now: 659)
        XCTAssertEqual(clock.elapsed, 10)
    }

    func testUpdateAcrossTickWrap() {
        var clock = GameClock(start: UInt32.max - 29)
        clock.update(now: 30)
        XCTAssertEqual(clock.elapsed, 1)
    }

    func testCapAndPracticeAdjustments() {
        // Cap: bonus 160 at elapsed 0 → remaining 310 → penalty += 10, remaining untouched until update.
        var clock = GameClock(start: 0)
        clock.bonus = 160
        clock.update(now: 0)
        XCTAssertEqual(clock.remaining, 310)
        clock.applyTimeBarAdjustments(now: 0, difficultyRaw: 1)
        XCTAssertEqual(clock.penalty, 10)
        XCTAssertEqual(clock.remaining, 310)
        clock.update(now: 0)
        XCTAssertEqual(clock.remaining, 300)

        // Practice (raw 3): a8 := now on every adjustment; any other raw leaves it.
        var practice = GameClock(start: 0)
        practice.applyTimeBarAdjustments(now: 5000, difficultyRaw: 3)
        XCTAssertEqual(practice.baseTick, 5000)
        var medium = GameClock(start: 0)
        medium.applyTimeBarAdjustments(now: 5000, difficultyRaw: 1)
        XCTAssertEqual(medium.baseTick, 0)
    }

    func testBonusAndPenaltyTables() {
        XCTAssertEqual(order.map { GameClock.matchBonus($0) }, [3, 6, 12, 0])
        XCTAssertEqual(order.map { GameClock.hintPenalty(remaining: 150, $0) }, [75, 37, 18, 0])
        XCTAssertEqual(order.map { GameClock.hintPenalty(remaining: -5, $0) }, [-2, -1, 0, 0])
        XCTAssertEqual(order.map { GameClock.reshufflePenalty(remaining: 150, $0) }, [112, 75, 37, 0])
        XCTAssertEqual(order.map { GameClock.reshufflePenalty(remaining: -7, $0) }, [-5, -3, -1, 0])
        XCTAssertEqual(order.map { GameClock.undoPenalty($0) }, [3, 6, 12, 0])
    }

    func testTimeBarLength() {
        var clock = GameClock(start: 0)
        XCTAssertEqual(clock.timeBarRaw(at: 0), 9000)
        XCTAssertEqual(clock.timeBarLength(now: 0), 225)
        clock.bonus = 200
        XCTAssertEqual(clock.timeBarLength(now: 0), 450)
        clock.bonus = 0
        XCTAssertEqual(clock.timeBarLength(now: 9000), 0)
        XCTAssertEqual(clock.timeBarRaw(at: 9060), -60)
        XCTAssertEqual(clock.timeBarLength(now: 9060), -1)
    }

    func testFreezeIsIdempotentAndThawShiftsBase() {
        var clock = GameClock(start: 1000)
        clock.freeze(now: 100)
        clock.freeze(now: 200)
        XCTAssertEqual(clock.freezeTick, 100)
        clock.thaw(now: 160)
        XCTAssertEqual(clock.baseTick, 1060)
        XCTAssertEqual(clock.freezeTick, 0)
    }

    func testEnterNoMorePairsKeepsRemaining() {
        var clock = GameClock(start: 0)
        clock.remaining = 77
        clock.enterNoMorePairs(now: 400)
        XCTAssertEqual(clock.frozenRemaining, 77)
        XCTAssertEqual(clock.freezeTick, 400)

        // Already frozen (e.g. paused first): the freeze tick is kept.
        var paused = GameClock(start: 0)
        paused.freeze(now: 300)
        paused.remaining = 77
        paused.enterNoMorePairs(now: 400)
        XCTAssertEqual(paused.frozenRemaining, 77)
        XCTAssertEqual(paused.freezeTick, 300)
    }
}
