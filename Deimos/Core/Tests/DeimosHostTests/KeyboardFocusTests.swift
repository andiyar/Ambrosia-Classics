import XCTest
@testable import DeimosHost

/// Ben's first playtest (2026-11-22): in full screen another app's hidden panel took the keyboard without making the
/// game inactive, and the arrows went dead. `KeyboardFocus.shouldReclaim` decides when the app takes it back.
final class KeyboardFocusTests: XCTestCase {

    /// Ben's state by default: active, full screen, not suspended, no question up, the window not key, the view
    /// still first responder, no earlier attempt.
    private func reclaim(appActive: Bool = true, fullScreen: Bool = true, suspended: Bool = false,
                         questionUp: Bool = false, windowIsKey: Bool = false, firstResponderIsView: Bool = true,
                         ticksSinceLastAttempt: UInt32? = nil) -> Bool {
        KeyboardFocus.shouldReclaim(appActive: appActive, fullScreen: fullScreen, suspended: suspended,
                                    questionUp: questionUp, windowIsKey: windowIsKey,
                                    firstResponderIsView: firstResponderIsView,
                                    ticksSinceLastAttempt: ticksSinceLastAttempt)
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
}
