import XCTest
@testable import DeimosHost

/// Ben's first playtest (2026-11-22): in full screen another app's hidden panel took the keyboard without making the
/// game inactive, and the arrows went dead. `KeyboardFocus.shouldReclaim` decides when the app takes it back.
final class KeyboardFocusTests: XCTestCase {

    /// Ben's state by default: active, full screen, not suspended, no question up, the window not key, the view
    /// still first responder, no earlier attempt
    /// since the window was last key.
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
    }

    // MARK: Held keys across the steal

    func testRecoveryWindowIsTwoSecondsAfterTheLastAttempt() {
        XCTAssertEqual(KeyboardFocus.recoveryTicks, 120)
        XCTAssertFalse(KeyboardFocus.inRecovery(ticksSinceLastAttempt: nil))
        XCTAssertTrue(KeyboardFocus.inRecovery(ticksSinceLastAttempt: 0))
        XCTAssertTrue(KeyboardFocus.inRecovery(ticksSinceLastAttempt: 119))
        XCTAssertFalse(KeyboardFocus.inRecovery(ticksSinceLastAttempt: 120))
    }

    /// P1's arrows and Command (0x37) bound; Space (0x31) not.
    private let bound: [UInt16] = [0x7E, 0x7B, 0x7C, 0x7D, 0x37]

    func testRecoveredHeldAddsABoundKeyTheHardwareReportsDown() {
        let held = KeyboardFocus.recoveredHeld(held: [], bound: bound, isDown: { $0 == 0x7B || $0 == 0x37 })
        XCTAssertEqual(held, [0x7B, 0x37])
    }

    func testRecoveredHeldDoesNotAddAnUnboundKey() {
        let held = KeyboardFocus.recoveredHeld(held: [], bound: bound, isDown: { $0 == 0x31 })
        XCTAssertEqual(held, [])
    }

    func testRecoveredHeldDoesNotAddABoundKeyReportedUp() {
        let held = KeyboardFocus.recoveredHeld(held: [], bound: bound, isDown: { _ in false })
        XCTAssertEqual(held, [])
    }

    func testRecoveredHeldKeepsKeysAlreadyHeld() {
        let held = KeyboardFocus.recoveredHeld(held: [0x31, 0x7E], bound: bound, isDown: { _ in false })
        XCTAssertEqual(held, [0x31, 0x7E])
    }

    func testRecoveredHeldNeverAsksAboutACodeAlreadyHeld() {
        var asked: [UInt16] = []
        let held = KeyboardFocus.recoveredHeld(held: [0x7E, 0x37], bound: bound, isDown: { asked.append($0); return true })
        XCTAssertEqual(held, Set(bound))
        XCTAssertEqual(asked.sorted(), [0x7B, 0x7C, 0x7D])
    }
}
