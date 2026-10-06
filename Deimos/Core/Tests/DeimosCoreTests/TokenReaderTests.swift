import XCTest
import HectorResources
@testable import DeimosCore

/// The U_Token grammar (bank data-tags.md §1, unit-def-struct.md §2) and the text de-obfuscation
/// (pak-format.md §3).
final class TokenReaderTests: XCTestCase {
    private func reader(_ s: String) -> TokenReader { TokenReader(Array(s.utf8)) }

    func testForwardOnlyCursor() {
        var r = reader("#b_INT <2>\r#a_INT <1>\r")
        XCTAssertEqual(r.int("#b_INT"), 2)
        XCTAssertEqual(r.cursor, 9, "cursor := position of '>'")
        XCTAssertEqual(r.int("#a_INT"), 1)
        let before = r.cursor
        XCTAssertNil(r.int("#b_INT"), "a key before the cursor is not found")
        XCTAssertEqual(r.cursor, before, "a miss leaves the cursor")
        XCTAssertEqual(r.errorCount, 1)
        XCTAssertEqual(r.errors, ["#b_INT"])
    }

    func testStringMissingIsSilentAndTruncatesToMaxMinusOne() {
        var r = reader("#name_STR <abcdef> #empty_STR <> #hi_STR <\u{A5}x>")
        XCTAssertEqual(r.string("#name_STR", maxLength: 4), "abc")
        XCTAssertEqual(r.string("#empty_STR", maxLength: 0x40), "")
        XCTAssertNil(r.string("#missing_STR", maxLength: 0x40))
        XCTAssertEqual(r.errorCount, 0, "a missing STR key is silent")
        // Mac Roman: the UTF-8 bytes of ¥ are two Mac Roman characters; feed a real Mac Roman byte instead.
        var m = TokenReader(Array("#hi_STR <".utf8) + [0xA5] + Array(">".utf8))
        XCTAssertEqual(m.string("#hi_STR", maxLength: 0x40), "•")
    }

    func testIdMustBeFourChars() {
        var r = reader("#a_ID <bocr> #b_ID <bop > #c_ID <abc> #d_ID <abcde> #e_ID <none>")
        XCTAssertEqual(r.id("#a_ID"), FourCC("bocr"))
        XCTAssertEqual(r.id("#b_ID"), FourCC("bop "))
        XCTAssertNil(r.id("#c_ID"))
        XCTAssertNil(r.id("#d_ID"))
        XCTAssertEqual(r.id("#e_ID"), FourCC.none)
        XCTAssertEqual(r.errors, ["#c_ID", "#d_ID"])
    }

    func testIntUsesPercentI() {
        var r = reader("#a <100.000000> #b <0x10> #c <010> #d <-1000> #e < +7> #f <> #g <abc> #h <15.000000> #i <0XfF>")
        XCTAssertEqual(r.int("#a"), 100)
        XCTAssertEqual(r.int("#b"), 16)
        XCTAssertEqual(r.int("#c"), 8, "leading 0 = octal")
        XCTAssertEqual(r.int("#d"), -1000)
        XCTAssertEqual(r.int("#e"), 7, "leading white space skipped, '+' accepted")
        XCTAssertNil(r.int("#f"), "length 0 is an error")
        XCTAssertNil(r.int("#g"), "no digits: not stored, but NOT an error (sscanf return unchecked)")
        XCTAssertEqual(r.int("#h"), 15)
        XCTAssertEqual(r.int("#i"), 255)
        XCTAssertNil(r.int("#zzz"), "missing key")
        XCTAssertEqual(r.errors, ["#f", "#zzz"])
        XCTAssertEqual(TokenReader.scanInt(Array("09".utf8)), 0, "%i octal stops at 9")
        XCTAssertEqual(TokenReader.scanInt(Array("0x".utf8)), 0, "bare 0x reads the 0")
    }

    func testFloatAndBool() {
        var r = reader("#f <0.96> #g <-1000> #h <1.5e2> #a <TRUE> #b <True> #c < TRUE> #d <FALSE> #e <x> #k <>")
        XCTAssertEqual(r.float("#f"), Float(0.96))
        XCTAssertEqual(r.float("#g"), -1000)
        XCTAssertEqual(r.float("#h"), 150)
        XCTAssertEqual(r.bool("#a"), true)
        XCTAssertEqual(r.bool("#b"), false)
        XCTAssertEqual(r.bool("#c"), false, "exact strcmp, no trimming")
        XCTAssertEqual(r.bool("#d"), false)
        XCTAssertEqual(r.float("#e"), nil, "no digits: not stored, no error")
        XCTAssertNil(r.float("#k"), "length 0 is an error")
        XCTAssertNil(r.bool("#zzz"))
        XCTAssertEqual(r.errors, ["#k", "#zzz"])
    }

    func testColorPacksHighFiveBits() {
        var r = reader("#a <52c594> #b <0> #c <52c59> #d <FFFFFF> #e <000000>")
        XCTAssertEqual(r.color("#a"), 0x2B12)
        XCTAssertNil(r.color("#b"), "\"0\" is an error (FUN_10010990 returns false)")
        XCTAssertNil(r.color("#c"))
        XCTAssertEqual(r.color("#d"), 0x7FFF)
        XCTAssertEqual(r.color("#e"), 0)
        XCTAssertEqual(r.errors, ["#b", "#c"])
        // trunc(65535·c/255) >> 11 ≡ c >> 3 for every c (INDEX #40).
        for c in 0...255 { XCTAssertEqual((65535 * c / 255) >> 11, c >> 3) }
    }

    func testRectTextOrderToMacRect() {
        var r = reader("#Scorebar Player 1 Score <25, 81, 135, 95> #b <0, 0, 480, 3600> #c <1, 2, 3> #d <>")
        XCTAssertEqual(r.rect("#Scorebar Player 1 Score"), MacRect(top: 81, left: 25, bottom: 95, right: 135))
        XCTAssertEqual(r.rect("#b"), MacRect(top: 0, left: 0, bottom: 3600, right: 480))
        XCTAssertNil(r.rect("#c"))
        XCTAssertNil(r.rect("#d"))
        XCTAssertEqual(r.errors, ["#c", "#d"])
    }

    func testOrderIndependentSearch() {
        let text = Array("#Loc_Y_INT <5> #Loc_X_INT <7> #Format_ID <CENT>".utf8)
        XCTAssertEqual(TokenReader.findAnywhere(text, key: "#Loc_X_INT").map { String(decoding: $0, as: UTF8.self) }, "7")
        XCTAssertEqual(TokenReader.findAnywhere(text, key: "#Loc_Y_INT").map { String(decoding: $0, as: UTF8.self) }, "5")
        XCTAssertNil(TokenReader.findAnywhere(text, key: "#Size_INT"))
        var r = TokenReader(text)
        r.orderIndependent = true
        XCTAssertEqual(r.int("#Loc_X_INT"), 7)
        XCTAssertEqual(r.int("#Loc_Y_INT"), 5, "fresh search from 0 for every key")
        XCTAssertEqual(r.errorCount, 0)
    }

    func testStopsAtNUL() {
        var r = TokenReader(Array("#a_INT <1>".utf8) + [0] + Array("#b_INT <2>".utf8))
        XCTAssertEqual(r.int("#a_INT"), 1)
        XCTAssertNil(r.int("#b_INT"))
        XCTAssertEqual(r.errors, ["#b_INT"])
        XCTAssertNil(TokenReader.findAnywhere(Array("#a <1".utf8) + [0] + Array(">".utf8), key: "#a"))
    }

    func testDecodeIsInvolutionAndWorkedColi() throws {
        for b in 0...255 {
            XCTAssertEqual(DeimosText.decode(DeimosText.decode([UInt8(b)])), [UInt8(b)])
        }
        // pak-format.md §3 worked decode: Game.pak:coli/Colors[gaco].coli.
        let cipher: [UInt8] = [0xcd, 0xc8, 0xc9, 0x09, 0xd8, 0xa9, 0xdb, 0xe9, 0xd8, 0x0a, 0xbb, 0x69, 0x89, 0x69, 0xb8,
                               0x6f, 0x6f, 0x6f, 0x6f, 0x6f, 0x6f, 0x6f, 0x3c, 0xac, 0xdc, 0xc9, 0xac, 0x6c, 0xbc, 0x1c]
        let plain = "#scoreBar_Digit" + String(repeating: "\t", count: 7) + "<52c594>"
        XCTAssertEqual(DeimosText.decode(cipher), Array(plain.utf8))
        let index = try RealData.index()
        let gaco = try XCTUnwrap(index.record(type: FourCC("coli")!, id: FourCC("gaco")!))
        XCTAssertEqual(Array(try index.data(for: gaco)), cipher)
        XCTAssertEqual(DeimosText.decode([0x2f]), [0x0d], "CR")
    }

    func testValueCensusOverAllText() throws {
        let index = try RealData.index()
        let textTypes = ["stli", "flli", "idli", "reli", "coli", "tefo", "plde", "unde", "leve", "wede"].map { FourCC($0)! }
        var ints = 0, floats = 0, boolTrue = 0, boolFalse = 0, colors = 0, files = 0
        var errors: [String] = []
        for record in index.records where textTypes.contains(record.type) {
            files += 1
            let text = DeimosText.decode(Array(try index.data(for: record)))
            var r = TokenReader(text)
            for key in TokenReader.itemKeys(text) {
                if key.hasSuffix("_INT") {
                    if r.int(key) != nil { ints += 1 }
                } else if key.hasSuffix("_FLOAT") {
                    if r.float(key) != nil { floats += 1 }
                } else if key.hasSuffix("_BOOL") {
                    if let b = r.bool(key) { if b { boolTrue += 1 } else { boolFalse += 1 } }
                } else if key.hasSuffix("_COLOR") || key.hasSuffix("_RGB") {
                    if r.color(key) != nil { colors += 1 }
                } else {
                    _ = r.string(key, maxLength: 0x10000)   // keep the cursor in step
                }
            }
            errors += r.errors.map { "\(record.type)/\(record.id): \($0)" }
        }
        XCTAssertEqual(files, 473)
        XCTAssertEqual(errors, [])
        XCTAssertEqual(ints, 57_140)
        XCTAssertEqual(floats, 19_815)
        // Plan note 12 says TRUE 4,149 / FALSE 63,723: its probe's `\w+` key pattern skipped the one key
        // with an apostrophe, `#stateSpawnSetDon'tSpawnOffscreen_BOOL` (532 items: 52 TRUE + 480 FALSE,
        // one per spawn set; re-counted with python over the committed paks, 2026-10-06).
        XCTAssertEqual(boolTrue, 4_149 + 52)
        XCTAssertEqual(boolFalse, 63_723 + 480)
        XCTAssertEqual(colors, 3_223)
    }
}
