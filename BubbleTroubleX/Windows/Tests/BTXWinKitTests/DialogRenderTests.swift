@testable import BTXWinKit
import BubbleTroubleCore
import BubbleTroubleRender
import Foundation
import XCTest
#if canImport(ImageIO)
import CoreGraphics
import ImageIO
#endif

/// Goldens for DLOG 1000 and 190 drawn over the canvas (byte-exact after the first write, `Tests/Goldens/Dialog-*.ppm`),
/// plus PNG copies of every table dialog in `/private/tmp/claude-504/w6/` for the eye.
final class DialogRenderTests: XCTestCase {
    static let goldens = DialogFixture.packageDirectory.appendingPathComponent("Tests/Goldens")
    static let eyeDirectory = URL(fileURLWithPath: "/private/tmp/claude-504/w6")

    /// The 640×480 window canvas (D21: no menu strip) in a flat game-ish blue, the dialogs drawn over it. The pattern
    /// keeps the phase it had under the old 20 px strip (`y + 20`), so the goldens are unchanged.
    private func window(_ s: DialogSystem) -> RGBAImage {
        var img = RGBAImage(width: 640, height: 480)
        for y in 0..<480 { for x in 0..<640 { img[x, y] = 0xFF00_0000 | UInt32(0x10 + (x + y + 20) % 32) << 8 | 0x60 } }
        s.draw(into: &img, canvasX: 0, canvasY: 0)
        return img
    }

    /// The dialog's rect on the canvas plus a 24 px margin (shadow), clamped.
    private func crop(_ img: RGBAImage, around d: DialogWindow) -> RGBAImage {
        let x0 = max(0, d.originX - 24), y0 = max(0, d.originY - 24)
        let x1 = min(640, d.originX + d.template.width + 24), y1 = min(480, d.originY + d.template.height + 24)
        var out = RGBAImage(width: x1 - x0, height: y1 - y0)
        for y in 0..<out.height { for x in 0..<out.width { out[x, y] = img[x0 + x, y0 + y] } }
        return out
    }

    static func ppm(_ img: RGBAImage) -> Data {
        var d = Data("P6\n\(img.width) \(img.height)\n255\n".utf8)
        d.reserveCapacity(d.count + img.width * img.height * 3)
        for p in img.pixels { d.append(contentsOf: [UInt8(p >> 16 & 0xFF), UInt8(p >> 8 & 0xFF), UInt8(p & 0xFF)]) }
        return d
    }

    static func writePNG(_ img: RGBAImage, _ name: String) {
        #if canImport(ImageIO)
        try? FileManager.default.createDirectory(at: eyeDirectory, withIntermediateDirectories: true)
        var bytes = [UInt8](repeating: 0, count: img.width * img.height * 4)
        for (i, p) in img.pixels.enumerated() {
            bytes[4 * i] = UInt8(p >> 16 & 0xFF); bytes[4 * i + 1] = UInt8(p >> 8 & 0xFF)
            bytes[4 * i + 2] = UInt8(p & 0xFF); bytes[4 * i + 3] = 0xFF
        }
        guard let provider = CGDataProvider(data: Data(bytes) as CFData),
              let cg = CGImage(width: img.width, height: img.height, bitsPerComponent: 8, bitsPerPixel: 32,
                               bytesPerRow: img.width * 4, space: CGColorSpaceCreateDeviceRGB(),
                               bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
                               provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent),
              let dest = CGImageDestinationCreateWithURL(eyeDirectory.appendingPathComponent(name) as CFURL,
                                                         "public.png" as CFString, 1, nil) else { return }
        CGImageDestinationAddImage(dest, cg, nil)
        CGImageDestinationFinalize(dest)
        #endif
    }

    /// Byte-exact against `Tests/Goldens/<name>.ppm`; the first run writes it.
    private func assertGolden(_ img: RGBAImage, _ name: String, file: StaticString = #filePath, line: UInt = #line) throws {
        let url = Self.goldens.appendingPathComponent("\(name).ppm")
        let bytes = Self.ppm(img)
        guard let golden = try? Data(contentsOf: url) else {
            try FileManager.default.createDirectory(at: Self.goldens, withIntermediateDirectories: true)
            try bytes.write(to: url)
            print("wrote golden \(url.path)")
            return
        }
        if golden != bytes {
            try? bytes.write(to: Self.eyeDirectory.appendingPathComponent("\(name)-actual.ppm"))
            XCTFail("\(name) differs from its golden (actual in \(Self.eyeDirectory.path))", file: file, line: line)
        }
    }

    func testGoldenDLOG1000() throws {
        let (s, _) = try DialogFixture.system()
        s.present(.highScoreNameDialog(defaultName: "Andrew"), prefs: .defaults) { _ in }
        let d = try XCTUnwrap(s.frontDialog)
        let img = window(s)
        Self.writePNG(img, "dlog1000-window.png")
        let c = crop(img, around: d)
        Self.writePNG(c, "dlog1000.png")
        try assertGolden(c, "Dialog-1000")
        // Spot checks that do not depend on the golden: white body, the accent default button, the edit field white.
        XCTAssertEqual(img[d.originX + 5, d.originY + 60] & 0xFF_FFFF, DialogRenderer.windowBackground)
        let ok = d.item(1)!.rect
        XCTAssertEqual(img[d.originX + ok.x + 4, d.originY + ok.y + 10] & 0xFF_FFFF, DialogRenderer.accent)
    }

    func testGoldenDLOG190() throws {
        let (s, _) = try DialogFixture.system()
        s.present(.prefsDialog, prefs: .defaults) { _ in }
        s.ticks(1)                                                       // the help line's "Welcome…"
        let d = try XCTUnwrap(s.frontDialog)
        let img = window(s)
        Self.writePNG(img, "dlog190-window.png")
        let c = crop(img, around: d)
        Self.writePNG(c, "dlog190.png")
        try assertGolden(c, "Dialog-190")
        // `_TouchUpPrefsDialog`'s grey frame on item 22.
        let r = d.item(22)!.rect
        XCTAssertEqual(img[d.originX + r.x + 10, d.originY + r.y] & 0xFF_FFFF, 0x7F7F7F)
    }

    /// Every other state for the eye (no golden): prefs areas, an open popup, DLOG 200 + ALRT 201, each table dialog.
    func testEyePNGsOfEveryDialog() throws {
        var (s, _) = try DialogFixture.system()
        s.present(.prefsDialog, prefs: .defaults) { _ in }
        s.ticks(1)
        s.click(6)
        Self.writePNG(window(s), "dlog190-keys-set1.png")
        let d = try XCTUnwrap(s.frontDialog)
        let b = d.popupButtonRect(d.item(33)!)
        s.mouseDown(x: d.originX + b.x + 10, y: d.originY + b.y + 10)
        s.mouseUp(x: d.originX + b.x + 10, y: d.originY + b.y + 10)
        if case .popup(let m) = d.tracking {
            let r = m.rows[3]
            s.mouseMoved(x: d.originX + r.x + 20, y: d.originY + r.y + 5)
        }
        Self.writePNG(window(s), "dlog190-keys-popup.png")
        s.mouseDown(x: 1, y: 1)                                          // closes the menu
        s.click(7)
        Self.writePNG(window(s), "dlog190-misc.png")
        s.click(6)
        s.click(31)
        Self.writePNG(window(s), "dlog200.png")
        s.type("Abcdefghijkl")
        s.press(DialogSystem.kReturn)
        s.ticks(8)
        Self.writePNG(window(s), "alrt201.png")

        for (name, request) in [("dlog160", ShellRequest.levelSelectDialog(max: 37)),
                                ("dlog1001", .hiScoreEraseDialog), ("dlog290", .modalDialog(id: 290)),
                                ("dlog291", .modalDialog(id: 291)), ("dlog3000", .modalDialog(id: 3000)),
                                ("dlog3001", .modalDialog(id: 3001))] {
            (s, _) = try DialogFixture.system()
            s.present(request, prefs: .defaults) { _ in }
            Self.writePNG(window(s), "\(name).png")
            XCTAssertTrue(s.isShowing, name)
        }
        (s, _) = try DialogFixture.system()
        s.alert(202)
        Self.writePNG(window(s), "alrt202.png")
        (s, _) = try DialogFixture.system()
        s.alert(9002, params: ["Couldn't find a resource.", "PICT", "128"])
        Self.writePNG(window(s), "alrt9002.png")
    }

    func testWrapAndCaretBlink() throws {
        let r = try DialogFixture.renderer()
        XCTAssertEqual(r.wrap("a\nb", width: 100), ["a", "b"])
        let lines = r.wrap("You made it into the High Scores!  Please enter your name:", width: 234)
        XCTAssertEqual(lines.count, 2)
        XCTAssertTrue(lines.allSatisfy { r.width($0) <= 234 })
        XCTAssertEqual(lines.joined(separator: " ").replacingOccurrences(of: "  ", with: " "),
                       "You made it into the High Scores! Please enter your name:")
        let (s, _) = try DialogFixture.system()
        s.present(.highScoreNameDialog(defaultName: "Andrew"), prefs: .defaults) { _ in }
        s.press(DialogSystem.kRight)                                     // collapse the selection: the caret shows
        let d = try XCTUnwrap(s.frontDialog)
        XCTAssertTrue(d.caretVisible)
        let on = window(s)
        s.ticks(DialogWindow.caretPeriod)
        XCTAssertFalse(d.caretVisible)
        XCTAssertTrue(window(s) != on, "the caret blinks off")
        s.ticks(DialogWindow.caretPeriod)
        XCTAssertTrue(window(s) == on, "and on again")
    }
}
