@testable import BTXWinKit
import BubbleTroubleCore
import BubbleTroubleRender
import Foundation
import XCTest

/// W5: the drawn bar. The golden is the 640 × 500 window with the Options menu open over a mid-grey canvas, written
/// once (`BTX_RECORD_GOLDENS=1`) and compared byte-exact after; a PNG copy goes to `/private/tmp/claude-504/w5/` for
/// eyes. Goldens live in `Tests/Goldens/` (outside the test target, so SwiftPM needs no resource declaration).
final class MenuBarViewTests: XCTestCase {
    static let goldens = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Goldens", isDirectory: true)

    var view: MenuBarView!

    override func setUpWithError() throws {
        view = MenuBarView(text: try BitmapFontRasterizer(fontsDirectory: fontsDirectory))
    }

    func canvas() -> RGBAImage { RGBAImage(width: 640, height: 500, fill: 0xFF80_8080) }

    /// The Options menu as at launch with default prefs (sound and music on), three key sets, pointer on Music.
    func optionsOpen() -> (MenuBar, MenuTracker, MenuGeometry) {
        var bar = MenuBar()
        var p = BTXPrefs.defaults
        p.keySetCount = 3
        for n in 2...3 { var k = p.keySet(n); k.name = "Set \(n)"; p.setKeySet(n, k) }
        p.currentKeySetIndex = 2
        p.sfxVolume = 3; p.musicVolume = 3; p.fullScreen = false
        bar.resetOptionsMenu(p)
        let g = view.geometry(for: bar, width: 640, height: 500)
        var t = MenuTracker()
        let title = g.titles[2]
        _ = t.mouseDown(x: title.x + 5, y: 10, bar: bar, geometry: g)
        let music = g.dropdowns[2].rows[3].frame
        t.mouseMoved(x: music.x + 20, y: music.y + 10, bar: bar, geometry: g)
        return (bar, t, g)
    }

    func testClosedBarDrawsOnlyTheStrip() {
        var image = canvas()
        view.draw(MenuBar(), tracker: MenuTracker(), into: &image)
        XCTAssertEqual(image[0, 0], 0xFF00_0000 | MenuBarView.barColor)
        XCTAssertEqual(image[639, 19], 0xFF00_0000 | MenuBarView.barLine)
        for y in 20..<500 { for x in stride(from: 0, to: 640, by: 7) { XCTAssertEqual(image[x, y], 0xFF80_8080) } }
        // Titles are inked (some dark pixel inside each title cell).
        let g = view.geometry(for: MenuBar(), width: 640, height: 500)
        for r in g.titles {
            let dark = (r.x..<r.maxX).contains { x in (2..<18).contains { y in image[x, y] & 0xFF < 0x40 } }
            XCTAssertTrue(dark)
        }
        XCTAssertTrue(image.pixels.allSatisfy { $0 >> 24 == 0xFF }, "every pixel opaque")
    }

    func testOpenOptionsMenuLooks() {
        let (bar, t, g) = optionsOpen()
        var image = canvas()
        view.draw(bar, tracker: t, into: &image)
        let d = g.dropdowns[2]
        // The panel's inside is the panel colour; the highlighted row (Music) blue; the title pill grey.
        XCTAssertEqual(image[d.frame.x + 3, d.rows[0].frame.y + 1], 0xFF00_0000 | MenuBarView.panelColor)
        let music = d.rows[3].frame
        XCTAssertEqual(image[music.x + 8, music.y + 1], 0xFF00_0000 | MenuBarView.highlight)
        XCTAssertEqual(image[g.titles[2].x + 2, 10], 0xFF00_0000 | MenuBarView.titlePill)
        // The shadow darkens the canvas just below the panel.
        XCTAssertLessThan(image[d.frame.x + 20, d.frame.maxY + 2] & 0xFF, 0x80)
        XCTAssertTrue(image.pixels.allSatisfy { $0 >> 24 == 0xFF })
    }

    func testDisabledItemsDrawGrey() {
        var bar = MenuBar()
        bar.setEnabled(menusEnabled: false)
        let g = view.geometry(for: bar, width: 640, height: 500)
        var t = MenuTracker()
        _ = t.mouseDown(x: g.titles[2].x + 5, y: 10, bar: bar, geometry: g)
        var image = canvas()
        view.draw(bar, tracker: t, into: &image)
        let full = g.dropdowns[2].rows[0].frame
        let inks = (full.x..<full.maxX).flatMap { x in (full.y..<full.maxY).map { image[x, $0] & 0xFF } }
        XCTAssertGreaterThanOrEqual(inks.min()!, 0xA8, "Full Screen is grey, nothing darker")
        let sound = g.dropdowns[2].rows[2].frame
        let soundInks = (sound.x..<sound.maxX).flatMap { x in (sound.y..<sound.maxY).map { image[x, $0] & 0xFF } }
        XCTAssertEqual(soundInks.min()!, 0, "Sound Effects is black")
    }

    func testOptionsMenuGolden() throws {
        let (bar, t, _) = optionsOpen()
        var image = canvas()
        view.draw(bar, tracker: t, into: &image)
        let ppm = Self.ppm(image)
        let out = URL(fileURLWithPath: "/private/tmp/claude-504/w5")
        try? FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)
        try? Self.png(image).write(to: out.appendingPathComponent("options-menu.png"))
        let golden = Self.goldens.appendingPathComponent("Menu-Options.ppm")
        if ProcessInfo.processInfo.environment["BTX_RECORD_GOLDENS"] == "1" {
            try FileManager.default.createDirectory(at: Self.goldens, withIntermediateDirectories: true)
            try ppm.write(to: golden)
            return
        }
        let expected = try Data(contentsOf: golden)
        XCTAssertEqual(ppm, expected, "differs from \(golden.path) — re-record with BTX_RECORD_GOLDENS=1 if intended")
    }

    // MARK: Image files

    static func ppm(_ image: RGBAImage) -> Data {
        var d = Data("P6\n\(image.width) \(image.height)\n255\n".utf8)
        d.reserveCapacity(d.count + image.pixels.count * 3)
        for p in image.pixels { d.append(contentsOf: [UInt8(p >> 16 & 0xFF), UInt8(p >> 8 & 0xFF), UInt8(p & 0xFF)]) }
        return d
    }

    /// A minimal PNG (8-bit RGB, zlib stored blocks) — Foundation only.
    static func png(_ image: RGBAImage) -> Data {
        var raw: [UInt8] = []
        raw.reserveCapacity((image.width * 3 + 1) * image.height)
        for y in 0..<image.height {
            raw.append(0)
            for x in 0..<image.width {
                let p = image[x, y]
                raw += [UInt8(p >> 16 & 0xFF), UInt8(p >> 8 & 0xFF), UInt8(p & 0xFF)]
            }
        }
        var z: [UInt8] = [0x78, 0x01]
        var i = 0
        while i < raw.count {
            let n = min(65535, raw.count - i)
            z.append(i + n == raw.count ? 1 : 0)
            z += [UInt8(n & 0xFF), UInt8(n >> 8), UInt8(~n & 0xFF), UInt8((~n >> 8) & 0xFF)]
            z += raw[i..<(i + n)]
            i += n
        }
        var a: UInt32 = 1, b: UInt32 = 0
        for byte in raw { a = (a + UInt32(byte)) % 65521; b = (b + a) % 65521 }
        z += be32(b << 16 | a)
        var out: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
        out += chunk("IHDR", be32(UInt32(image.width)) + be32(UInt32(image.height)) + [8, 2, 0, 0, 0])
        out += chunk("IDAT", z)
        out += chunk("IEND", [])
        return Data(out)
    }

    static func be32(_ v: UInt32) -> [UInt8] { [UInt8(v >> 24), UInt8(v >> 16 & 0xFF), UInt8(v >> 8 & 0xFF), UInt8(v & 0xFF)] }

    static func chunk(_ type: String, _ body: [UInt8]) -> [UInt8] {
        let t = Array(type.utf8)
        var crc: UInt32 = 0xFFFF_FFFF
        for byte in t + body {
            crc ^= UInt32(byte)
            for _ in 0..<8 { crc = crc & 1 != 0 ? 0xEDB8_8320 ^ (crc >> 1) : crc >> 1 }
        }
        return be32(UInt32(body.count)) + t + body + be32(~crc)
    }
}
