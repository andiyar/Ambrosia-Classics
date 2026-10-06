@testable import BTXWinKit
import BubbleTroubleCore
import Foundation
import HectorResources
import XCTest

/// W7 review: `replacingEvery`, the pure-Swift stand-in for Foundation's `replacingOccurrences(of:with:)` (which traps
/// on Windows for non-ASCII text). On the Mac every case is also checked against Foundation, the reference.
final class TextReplaceTests: XCTestCase {
    private func check(_ s: String, _ target: String, _ replacement: String, _ expected: String,
                       file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(s.replacingEvery(target, with: replacement), expected, file: file, line: line)
        #if canImport(Darwin)
        XCTAssertEqual(s.replacingOccurrences(of: target, with: replacement), expected, "Foundation", file: file,
                       line: line)
        #endif
    }

    func testBasics() {
        check("", "\r", "\n", "")
        check("abc", "\r", "\n", "abc")
        check("a\rb\r", "\r", "\n", "a\nb\n")
        check("\r\r\r", "\r", "\n", "\n\n\n")
        check("aaaa", "aa", "b", "bb")                           // left to right, non-overlapping
        check("aaa", "aa", "b", "ba")
        check("x^0y^1z^0", "^0", "Ben", "xBeny^1zBen")
        check("^0", "^0", "", "")
        check("é\n\né\n\n", "\n\n", "—", "é—é—")
        check("short", "longer than it", "x", "short")
        XCTAssertEqual("abc".replacingEvery("", with: "x"), "abc")
    }

    /// "\r\n" is one `Character`; the CR inside it is still found (scalar matching, as Foundation's UTF-16 search).
    func testCRInsideCRLF() {
        check("a\r\nb", "\r", "\n", "a\n\nb")
    }

    /// The probe's trapping shapes (non-ASCII, ≳64 UTF-8 bytes) at lengths up to 300 repeats.
    func testLongNonASCIIStrings() {
        for k in [1, 10, 22, 64, 300] {
            let s = String(repeating: "é\r", count: k)
            XCTAssertEqual(s.replacingEvery("\r", with: "\n"), String(repeating: "é\n", count: k))
            let c = String(repeating: "é^0 ", count: k)
            XCTAssertEqual(c.replacingEvery("^0", with: "10"), String(repeating: "é10 ", count: k))
        }
    }

    /// A long MacRoman static text with "©" and CRs (the shape of ALRT 132's) — decoded with CR → LF.
    func testMacRomanParagraphWithCopyright() {
        var bytes = Array("Bubble Trouble X \u{A9}".utf8.filter { $0 < 0x80 })
        bytes.append(0xA9)                                       // MacRoman ©
        while bytes.count < 193 { bytes.append(contentsOf: Array("\rline of text".utf8)) }
        bytes = Array(bytes.prefix(193)) + [0x0D]
        XCTAssertEqual(bytes.count, 194)
        let text = DialogResources.macRoman(bytes)
        XCTAssertFalse(text.unicodeScalars.contains("\r"))
        XCTAssertEqual(text.unicodeScalars.filter { $0 == "\n" }.count, bytes.filter { $0 == 0x0D }.count)
        XCTAssertTrue(text.contains("©"))
        XCTAssertEqual(text, MacRoman.decode(bytes.map { $0 == 0x0D ? 0x0A : $0 }))
    }

    /// The real ALRT 132 text ("©"; 193 MacRoman bytes = 194 UTF-8 bytes, the size that trapped Foundation on
    /// Windows), through `DialogResources.alert` (data-gated).
    func testRealAlert132() throws {
        let (data, _) = try DialogFixture.data()
        let alert = try XCTUnwrap(DialogResources.alert(132, data: data))
        let item = try XCTUnwrap(alert.items.first { $0.text.contains("©") })
        XCTAssertEqual(DialogResources.byteLength(item.text), 193)
        XCTAssertEqual(item.text.utf8.count, 194)
        XCTAssertFalse(item.text.unicodeScalars.contains("\r"))
        XCTAssertEqual(DialogResources.macRoman(Array(try XCTUnwrap(MacRoman.encode(item.text, lossy: false)))),
                       item.text)
    }
}
