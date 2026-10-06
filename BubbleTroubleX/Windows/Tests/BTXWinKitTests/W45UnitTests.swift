@testable import BTXWinKit
import BubbleTroubleCore
import BubbleTroubleRender
import Foundation
import XCTest

/// W4.5 units: key/text pairing and the script's new commands.
final class W45UnitTests: XCTestCase {
    private func key(_ code: UInt16, _ chars: String = "") -> WinEvent {
        .keyDown(keyCode: code, characters: chars, modifiers: [], isRepeat: false)
    }

    func testTypedTextPairsWithTheKeyBeforeIt() {
        let events: [WinEvent] = [
            key(0x00, "a"), .textInput("é"),            // paired
            key(0x0B, "b"),                             // nothing typed (the next text is after another key)
            key(0x0C, "q"), .keyUp(keyCode: 0x0C, modifiers: []), .textInput("@"),   // a key-up between: still paired
            .textInput("ü"),                            // no key before it: alone
            .mouseMoved(x: 1, y: 2),
        ]
        let paired = WinGameDriver.pairTypedText(events)
        XCTAssertEqual(paired.map(\.0), [key(0x00, "a"), key(0x0B, "b"), key(0x0C, "q"),
                                         .keyUp(keyCode: 0x0C, modifiers: []), .textInput("ü"), .mouseMoved(x: 1, y: 2)])
        XCTAssertEqual(paired.map(\.1), ["é", nil, "@", nil, nil, nil])
    }

    func testScriptMoveAndText() throws {
        let s = try WinKeyScript(text: "5 move 10 20\n6 press a\n6 text é ü\n")
        XCTAssertEqual(s.actions(at: 5), [.event(.mouseMoved(x: 10, y: 20))])
        XCTAssertEqual(s.actions(at: 6), [.event(.keyDown(keyCode: 0x00, characters: "a", modifiers: [],
                                                          isRepeat: false)),
                                          .event(.textInput("é ü"))])
        XCTAssertThrowsError(try WinKeyScript(text: "1 text"))
        XCTAssertThrowsError(try WinKeyScript(text: "1 move 3"))
    }
}
