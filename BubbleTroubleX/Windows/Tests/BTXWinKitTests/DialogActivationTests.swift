@testable import BTXWinKit
import BubbleTroubleCore
import BubbleTroubleRender
import Foundation
import XCTest

/// W6 review fixes: a dialog behind another draws inactive; edit-field clicks and hits as the Mac replica's.
final class DialogActivationTests: XCTestCase {
    func testDialogBehindAnotherDrawsInactive() throws {
        let (s, _) = try DialogFixture.system()
        s.present(.prefsDialog, prefs: .defaults) { _ in }
        let prefs = try XCTUnwrap(s.frontDialog)
        XCTAssertTrue(prefs.isFrontmost)
        let save = try XCTUnwrap(prefs.item(1)).rect                   // Save, the default button
        func centre(_ img: RGBAImage) -> UInt32 { img[save.x + 6, save.y + save.height / 2] & 0xFF_FFFF }
        XCTAssertEqual(centre(s.renderer.render(prefs)), DialogRenderer.accent, "front: the accent default button")
        s.alert(201)                                                   // ALRT 201 over DLOG 190
        XCTAssertFalse(prefs.isFrontmost)
        XCTAssertTrue(try XCTUnwrap(s.frontDialog).isFrontmost)
        XCTAssertEqual(centre(s.renderer.render(prefs)), DialogRenderer.buttonFill, "behind: an ordinary button")
        s.click(1)                                                     // the alert's OK
        XCTAssertTrue(prefs.isFrontmost)
        XCTAssertEqual(centre(s.renderer.render(prefs)), DialogRenderer.accent)
    }

    func testEditFieldHitsFollowTheMacReplica() throws {
        let item = DialogItem(number: 1, rect: DialogRect(x: 10, y: 10, width: 100, height: 16), kind: .editText,
                              enabled: false, text: "abc")
        let t = DialogTemplate(id: 1, width: 200, height: 100, position: 0, items: [item], alertStages: nil)
        let d = DialogWindow(template: t, data: nil, art: nil)
        var hits: [Int] = []
        d.itemHit = { hits.append($0) }
        // A DITL-disabled field still takes the click (focus, caret) but is not reported as hit.
        d.mouseDown(20, 15)
        d.mouseUp(20, 15)
        XCTAssertEqual(d.focusedEditItem, 1)
        XCTAssertEqual(hits, [])
        // A deactivated field takes no click at all.
        let other = DialogWindow(template: t, data: nil, art: nil)
        other.setActive(1, false)
        other.mouseDown(20, 15)
        other.mouseUp(20, 15)
        XCTAssertNil(other.focusedEditItem)
        // An enabled field is reported.
        let enabled = DialogItem(number: 1, rect: item.rect, kind: .editText, enabled: true, text: "")
        let e = DialogWindow(template: DialogTemplate(id: 2, width: 200, height: 100, position: 0, items: [enabled],
                                                      alertStages: nil), data: nil, art: nil)
        e.itemHit = { hits.append($0) }
        e.mouseDown(20, 15)
        e.mouseUp(20, 15)
        XCTAssertEqual(hits, [1])
    }
}
