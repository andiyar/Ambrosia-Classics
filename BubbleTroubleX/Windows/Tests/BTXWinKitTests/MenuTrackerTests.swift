@testable import BTXWinKit
import BubbleTroubleCore
import Foundation
import XCTest

/// W5: geometry hit-testing and the press-drag-release / sticky tracking state machine.
final class MenuTrackerTests: XCTestCase {
    var view: MenuBarView!
    var bar = MenuBar()
    var g: MenuGeometry!
    var t = MenuTracker()

    override func setUpWithError() throws {
        view = MenuBarView(text: try BitmapFontRasterizer(fontsDirectory: fontsDirectory))
        var p = BTXPrefs.defaults
        p.keySetCount = 3
        for n in 2...3 { var k = p.keySet(n); k.name = "Set \(n)"; p.setKeySet(n, k) }
        p.currentKeySetIndex = 1
        bar.resetOptionsMenu(p)
        relayout()
    }

    func relayout() { g = view.geometry(for: bar, width: 640, height: 500) }

    // Menu indices and points.
    let app = 0, edit = 1, options = 2, window = 3
    func title(_ m: Int) -> (Int, Int) { (g.titles[m].x + g.titles[m].width / 2, 10) }
    func row(_ m: Int, _ e: Int) -> (Int, Int) {
        let f = g.dropdowns[m].rows[e].frame
        return (f.x + f.width / 2, f.y + f.height / 2)
    }
    func subRow(_ e: Int) -> (Int, Int) {
        let f = g.dropdowns[options].submenus[5]!.rows[e].frame
        return (f.x + f.width / 2, f.y + f.height / 2)
    }

    @discardableResult func down(_ p: (Int, Int), _ m: MenuModifiers = []) -> Bool {
        t.mouseDown(x: p.0, y: p.1, modifiers: m, bar: bar, geometry: g)
    }
    func move(_ p: (Int, Int), _ m: MenuModifiers = []) { t.mouseMoved(x: p.0, y: p.1, modifiers: m, bar: bar, geometry: g) }
    func up(_ p: (Int, Int), _ m: MenuModifiers = []) -> MenuCommand? {
        t.mouseUp(x: p.0, y: p.1, modifiers: m, bar: bar, geometry: g)
    }

    // MARK: Geometry

    func testTitlesLaidOutLeftToRightInTheStrip() {
        XCTAssertEqual(g.titles.count, 4)
        XCTAssertEqual(g.titles[0].x, 10)
        for i in 1..<4 { XCTAssertEqual(g.titles[i].x, g.titles[i - 1].maxX) }
        for r in g.titles { XCTAssertEqual(r.y, 0); XCTAssertEqual(r.height, 20) }
        XCTAssertEqual(g.title(at: 5, 10), nil)
        XCTAssertEqual(g.title(at: title(options).0, 10), options)
        XCTAssertEqual(g.title(at: title(options).0, 20), nil, "below the strip")
    }

    func testDropdownsHangUnderTheirTitles() {
        for m in 0..<4 {
            let d = g.dropdowns[m]
            XCTAssertEqual(d.frame.x, g.titles[m].x)
            XCTAssertEqual(d.frame.y, 20)
            XCTAssertEqual(d.rows.count, bar.menus[m].entries.count)
            XCTAssertEqual(d.rows.last!.frame.maxY + MenuBarView.bottomPad, d.frame.maxY)
        }
        let o = g.dropdowns[options]
        XCTAssertEqual(o.rows.map(\.frame.height), [20, 9, 20, 20, 9, 20])
        XCTAssertEqual(o.rows.map(\.isSeparator), [false, true, false, false, true, false])
        XCTAssertEqual(o.row(at: row(options, 2).0, row(options, 2).1)?.entry, 2)
        XCTAssertNil(o.row(at: o.frame.x + 3, o.frame.y + 1), "top padding")
        let sub = o.submenus[5]!
        XCTAssertEqual(sub.rows.count, 4)
        XCTAssertEqual(sub.rows[0].frame.y, o.rows[5].frame.y, "first submenu row level with Key Sets")
        XCTAssertGreaterThan(sub.frame.x, o.frame.x)
    }

    func testDropdownWidthFitsTitlesAndShortcuts() {
        let o = g.dropdowns[options]
        let need = MenuBarView.checkColumn + view.text.width("Sound Effects", font: "System", size: 12)
            + MenuBarView.shortcutGap + view.text.width("Ctrl+Shift+A", font: "System", size: 12)
            + MenuBarView.rightPad + MenuBarView.arrowColumn
        XCTAssertEqual(o.frame.width, need)
    }

    func testMenusStayInsideTheWindow() {
        var p = BTXPrefs.defaults
        p.keySetCount = 20
        bar.resetOptionsMenu(p)
        let narrow = view.geometry(for: bar, width: 320, height: 300)
        let sub = narrow.dropdowns[options].submenus[5]!
        XCTAssertGreaterThanOrEqual(sub.frame.x, 0)
        XCTAssertLessThanOrEqual(sub.frame.maxX, 320)
        XCTAssertGreaterThanOrEqual(sub.frame.y, 20)
        XCTAssertLessThanOrEqual(narrow.dropdowns[window].frame.maxX, 320)
    }

    // MARK: Press-drag-release

    func testPressDragReleaseChoosesAnItem() {
        XCTAssertTrue(down(title(options)))
        XCTAssertEqual(t.openMenu, options)
        XCTAssertEqual(t.mode, .pressed)
        move(row(options, 3))
        XCTAssertEqual(t.highlighted, 3)
        XCTAssertEqual(up(row(options, 3)), .music)
        XCTAssertFalse(t.isOpen)
    }

    func testDragAcrossTitlesSwitchesMenus() {
        down(title(app))
        move(title(edit))
        XCTAssertEqual(t.openMenu, edit)
        move(title(options))
        move(row(options, 0))
        XCTAssertEqual(up(row(options, 0)), .fullScreen)
    }

    func testReleaseOverNothingCloses() {
        down(title(options))
        move(row(options, 1))
        XCTAssertNil(t.highlighted, "separators never highlight")
        XCTAssertNil(up(row(options, 1)))
        XCTAssertFalse(t.isOpen)
        down(title(options))
        XCTAssertNil(up((600, 400)))
        XCTAssertFalse(t.isOpen)
    }

    func testDisabledItemsAreInert() {
        bar.setEnabled(menusEnabled: false)
        down(title(options))
        move(row(options, 0))
        XCTAssertNil(t.highlighted, "disabled Full Screen does not highlight")
        XCTAssertNil(up(row(options, 0)))
        XCTAssertFalse(t.isOpen)
        down(title(edit))
        for e in [0, 1, 3, 4, 5, 6, 7] { move(row(edit, e)); XCTAssertNil(t.highlighted) }
        XCTAssertNil(up(row(edit, 4)))
        bar.dialogUp = true
        down(title(app))
        move(row(app, 4))
        XCTAssertNil(t.highlighted)
        XCTAssertNil(up(row(app, 4)), "a dialog disables Quit too")
    }

    func testSubmenuOpensAndChooses() {
        down(title(options))
        move(row(options, 5))
        XCTAssertEqual(t.highlighted, 5)
        XCTAssertEqual(t.openSubmenu, 5)
        move(subRow(2))
        XCTAssertEqual(t.subHighlighted, 2)
        XCTAssertEqual(t.highlighted, 5, "the parent stays lit")
        XCTAssertEqual(up(subRow(2)), .keySet(2))
        XCTAssertFalse(t.isOpen)
    }

    func testSubmenuClosesOnAnotherItem() {
        down(title(options))
        move(row(options, 5))
        move(row(options, 2))
        XCTAssertNil(t.openSubmenu)
        XCTAssertEqual(t.highlighted, 2)
    }

    // MARK: Sticky (click-release-click)

    func testClickReleaseOnTitleSticks() {
        down(title(options))
        XCTAssertNil(up(title(options)))
        XCTAssertTrue(t.isOpen)
        XCTAssertEqual(t.mode, .sticky)
        move(row(options, 2))                         // hover, no button
        XCTAssertEqual(t.highlighted, 2)
        move(title(window))
        XCTAssertEqual(t.openMenu, window, "hovering another title switches")
        move(title(options))
        down(row(options, 2))
        XCTAssertEqual(up(row(options, 2)), .soundEffects)
        XCTAssertFalse(t.isOpen)
    }

    func testStickyClickOnDisabledKeepsItOpen() {
        down(title(edit)); _ = up(title(edit))
        down(row(edit, 0))
        XCTAssertNil(up(row(edit, 0)))
        XCTAssertTrue(t.isOpen)
        XCTAssertEqual(t.mode, .sticky)
    }

    func testStickyClickOutsideOrOnTitleCloses() {
        down(title(options)); _ = up(title(options))
        XCTAssertTrue(down((500, 300)), "the dismissing click is consumed")
        XCTAssertFalse(t.isOpen)
        down(title(options)); _ = up(title(options))
        XCTAssertTrue(down(title(options)))
        XCTAssertFalse(t.isOpen)
        XCTAssertNil(up(title(options)), "the release after the closing click does nothing")
        XCTAssertFalse(t.isOpen)
    }

    func testReleaseOnSubmenuParentSticks() {
        down(title(options))
        move(row(options, 5))
        XCTAssertNil(up(row(options, 5)))
        XCTAssertEqual(t.mode, .sticky)
        move(subRow(3))
        down(subRow(3))
        XCTAssertEqual(up(subRow(3)), .keySet(3))
    }

    // MARK: Keys, Alt, consumption

    func testEscCloses() {
        XCTAssertFalse(t.keyDown(keyCode: 0x35), "nothing open: not consumed")
        down(title(app))
        XCTAssertTrue(t.keyDown(keyCode: 0x00), "keys go to the open menu")
        XCTAssertTrue(t.isOpen)
        XCTAssertTrue(t.keyDown(keyCode: 0x35))
        XCTAssertFalse(t.isOpen)
    }

    func testAltShowsTheAlternates() {
        down(title(window))
        move(row(window, 0))
        XCTAssertNil(t.highlighted, "Minimize is disabled")
        t.modifiersChanged(.option, bar: bar, geometry: g)
        XCTAssertEqual(t.highlighted, 0, "Minimize All is enabled")
        XCTAssertEqual(up(row(window, 0), .option), .minimizeAll)
        down(title(window))
        move(row(window, 3))
        XCTAssertEqual(up(row(window, 3)), .bringAllToFront)
        down(title(window))
        move(row(window, 3), .option)
        XCTAssertEqual(up(row(window, 3), .option), .arrangeInFront)
    }

    func testCanvasClicksPassThroughWhenClosed() {
        XCTAssertFalse(down((300, 200)))
        XCTAssertTrue(down((630, 10)), "the empty strip is still the bar's")
        XCTAssertFalse(t.isOpen)
    }
}
