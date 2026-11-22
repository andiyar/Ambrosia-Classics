import XCTest
@testable import DeimosHost

/// Ben's first playtest (2026-11-22): in full screen another app's hidden panel took the keyboard without making the
/// game inactive, and the arrows went dead. `KeyboardFocus.shouldReclaim` decides when the app takes it back.
final class KeyboardFocusTests: XCTestCase {

    /// Ben's state by default: active, full screen, not suspended, no question up, the window not key, the view
    /// still first responder, no earlier attempt since the window was last key.
    private func reclaim(appActive: Bool = true, fullScreen: Bool = true, suspended: Bool = false,
                         questionUp: Bool = false, windowIsKey: Bool = false, firstResponderIsView: Bool = true,
                         ticksSinceLastAttempt: UInt32? = nil, attemptsSinceKey: Int = 0) -> Bool {
        KeyboardFocus.shouldReclaim(appActive: appActive, fullScreen: fullScreen, suspended: suspended,
                                    questionUp: questionUp, windowIsKey: windowIsKey,
                                    firstResponderIsView: firstResponderIsView,
                                    ticksSinceLastAttempt: ticksSinceLastAttempt, attemptsSinceKey: attemptsSinceKey)
    }

    func testFullScreenWindowThatLostTheKeyboardWhileActiveReclaimsIt() {
        XCTAssertTrue(reclaim())
    }

    func testWindowedModeIsLeftAlone() {
        XCTAssertFalse(reclaim(fullScreen: false))
    }

    func testInactiveAppIsLeftAlone() {
        XCTAssertFalse(reclaim(appActive: false))
    }

    func testSuspendedAppIsLeftAlone() {
        XCTAssertFalse(reclaim(suspended: true))
    }

    func testNothingIsReclaimedWhileAQuestionIsUp() {
        XCTAssertFalse(reclaim(questionUp: true))
    }

    func testKeyWindowWithTheViewFirstResponderNeedsNothing() {
        XCTAssertFalse(reclaim(windowIsKey: true, firstResponderIsView: true))
    }

    func testKeyWindowWhoseFirstResponderIsNotTheViewReclaims() {
        XCTAssertTrue(reclaim(windowIsKey: true, firstResponderIsView: false))
    }

    func testRetryWaitsAQuarterSecondAfterTheLastAttempt() {
        XCTAssertEqual(KeyboardFocus.retryTicks, 15)
        XCTAssertFalse(reclaim(ticksSinceLastAttempt: 0))
        XCTAssertFalse(reclaim(ticksSinceLastAttempt: 14))
        XCTAssertTrue(reclaim(ticksSinceLastAttempt: 15))
        XCTAssertTrue(reclaim(ticksSinceLastAttempt: 600))
    }

    func testWindowNotKeyAndViewNotFirstResponderReclaims() {
        XCTAssertTrue(reclaim(windowIsKey: false, firstResponderIsView: false))
    }

    func testReclaimGivesUpAfterMaxAttempts() {
        XCTAssertEqual(KeyboardFocus.maxAttempts, 8)
        XCTAssertTrue(reclaim(ticksSinceLastAttempt: 15, attemptsSinceKey: 7))
        XCTAssertFalse(reclaim(ticksSinceLastAttempt: 15, attemptsSinceKey: 8))
        XCTAssertFalse(reclaim(ticksSinceLastAttempt: 15, attemptsSinceKey: 9))
    }

    // MARK: Held keys across the steal

    func testRecoveryWindowIsTwoSecondsAfterTheLastAttempt() {
        XCTAssertEqual(KeyboardFocus.recoveryTicks, 120)
        XCTAssertFalse(KeyboardFocus.inRecovery(ticksSinceLastAttempt: nil))
        XCTAssertTrue(KeyboardFocus.inRecovery(ticksSinceLastAttempt: 0))
        XCTAssertTrue(KeyboardFocus.inRecovery(ticksSinceLastAttempt: 119))
        XCTAssertFalse(KeyboardFocus.inRecovery(ticksSinceLastAttempt: 120))
    }

    /// The controller measures ticks since the last attempt as `tick &- lastAttempt` (wrapping subtraction), so the
    /// Mac tick counter rolling over from 0xFFFFFFFF to 0 still gives the small true difference.
    func testRecoveryWindowHoldsAcrossATickCounterWrap() {
        let since = UInt32(3) &- (UInt32.max - 2)           // last attempt 3 ticks before the wrap, now 3 after it
        XCTAssertEqual(since, 6)
        XCTAssertTrue(KeyboardFocus.inRecovery(ticksSinceLastAttempt: since))
        XCTAssertFalse(KeyboardFocus.inRecovery(ticksSinceLastAttempt: UInt32(117) &- (UInt32.max - 2)))
    }

    /// P1's arrows and Command (0x37) bound; Space (0x31) not.
    private let bound: [UInt16] = [0x7E, 0x7B, 0x7C, 0x7D, 0x37]

    private func step(recovered: Set<UInt16> = [], viewHeld: Set<UInt16> = [], inRecovery: Bool = true,
                      isDown: (UInt16) -> Bool) -> Set<UInt16> {
        KeyboardFocus.stepRecovered(recovered: recovered, viewHeld: viewHeld, bound: bound, inRecovery: inRecovery,
                                    isDown: isDown)
    }

    func testStepRecoveredAddsABoundKeyTheHardwareReportsDownInRecovery() {
        XCTAssertEqual(step(isDown: { $0 == 0x7B || $0 == 0x37 }), [0x7B, 0x37])
    }

    func testStepRecoveredDoesNotAddAnUnboundKey() {
        XCTAssertEqual(step(isDown: { $0 == 0x31 }), [])
    }

    func testStepRecoveredDoesNotAddABoundKeyReportedUp() {
        XCTAssertEqual(step(isDown: { _ in false }), [])
    }

    /// Command held to fire across the steal: modifiers never auto-repeat and the view never gets Command's code
    /// back, so the recovered key must outlast the recovery window for as long as it is physically held.
    func testCommandHeldToFireStaysRecoveredAfterTheRecoveryWindowWhileHeld() {
        XCTAssertEqual(step(recovered: [0x37], inRecovery: false, isDown: { $0 == 0x37 }), [0x37])
    }

    func testRecoveredKeyLeavesOnTheStepTheHardwareReadsItUp() {
        XCTAssertEqual(step(recovered: [0x37, 0x7B], inRecovery: false, isDown: { $0 == 0x7B }), [0x7B])
        XCTAssertEqual(step(recovered: [0x37], inRecovery: true, isDown: { _ in false }), [])
    }

    /// A key the view holds again (an auto-repeat or a fresh press) leaves the recovered set: the view's own key-up
    /// then releases it.
    func testRecoveredKeyLeavesWhenTheViewHoldsItAgain() {
        XCTAssertEqual(step(recovered: [0x7B, 0x37], viewHeld: [0x7B], inRecovery: false, isDown: { _ in true }),
                       [0x37])
        XCTAssertEqual(step(recovered: [0x7B], viewHeld: [0x7B], inRecovery: true, isDown: { _ in true }),
                       [0x7E, 0x7C, 0x7D, 0x37])
    }

    func testStepRecoveredNeverAsksTheHardwareOutsideRecoveryWithNothingRecovered() {
        var asked = 0
        XCTAssertEqual(step(viewHeld: [0x7E], inRecovery: false, isDown: { _ in asked += 1; return true }), [])
        XCTAssertEqual(asked, 0)
    }

    func testStepRecoveredNeverAsksAboutACodeTheViewHolds() {
        var asked: [UInt16] = []
        let out = step(recovered: [0x7E, 0x7D], viewHeld: [0x7E, 0x37], isDown: { asked.append($0); return true })
        XCTAssertEqual(out, [0x7B, 0x7C, 0x7D])
        XCTAssertEqual(asked.sorted(), [0x7B, 0x7C, 0x7D])      // each once; never 0x7E or 0x37
    }
}
