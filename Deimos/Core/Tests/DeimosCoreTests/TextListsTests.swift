import XCTest
import HectorResources
@testable import DeimosCore

/// The six small text types over the shipped data (bank data-tags.md §2–§5, hud-scorebar.md §9).
final class TextListsTests: XCTestCase {
    private func raw(_ type: String, _ id: String) throws -> Data {
        let index = try RealData.index()
        let record = try XCTUnwrap(index.record(type: FourCC(type)!, id: FourCC(id)!), "\(type)/\(id)")
        return try index.data(for: record)
    }

    /// Encodes plain text the way the shipped files are (the de-obfuscation is an involution).
    private func encoded(_ s: String) -> Data { Data(DeimosText.decode(Array(s.utf8))) }

    func testStringListsLineCounts() throws {
        let expected = ["cred": 102, "edit": 5, "inte": 28, "pali": 1, "pgsl": 37]
        var total = 0
        for (id, count) in expected {
            let list = StringList(data: try raw("stli", id))
            XCTAssertEqual(list.lines.count, count, id)
            total += list.lines.count
        }
        XCTAssertEqual(total, 173)
        XCTAssertEqual(try RealData.index().records(ofType: FourCC("stli")!).count, 5)
        let inte = StringList(data: try raw("stli", "inte"))
        XCTAssertEqual(inte.string(at: 6), "Loading Permanent Image:  ")
        let pgsl = StringList(data: try raw("stli", "pgsl"))
        XCTAssertEqual(pgsl.string(at: 0), "Press Caps Lock")
        XCTAssertEqual(pgsl.string(at: 9), "REPLAY")
        XCTAssertNil(pgsl.string(at: 37))
        XCTAssertEqual(StringList(data: try raw("stli", "pali")).string(at: 0), "1")
        // CR-split rule: +1 line when the file does not end in CR.
        XCTAssertEqual(StringList(data: encoded("a\rb\r")).lines.count, 2)
        XCTAssertEqual(StringList(data: encoded("a\rb")).lines.count, 2)
        XCTAssertEqual(StringList(data: encoded("a\r\rb")).lines.map { $0.count }, [1, 0, 1])
        XCTAssertEqual(StringList(data: Data()).lines.count, 0)
    }

    func testFloatList220() throws {
        let list = try FloatList(data: try raw("flli", "gafl"))
        XCTAssertEqual(list.values.count, 220)
        XCTAssertEqual(list.values[32], 30)
        XCTAssertEqual(list.values[37], 204_800)
        XCTAssertEqual(list.values[38], 8)
        XCTAssertEqual(list.values[54], 416)
        XCTAssertEqual(list.values[55], 480)
        XCTAssertEqual(list.values[144], Float(0.96))
        XCTAssertEqual(list.values[219], 3)
        XCTAssertEqual(list.values[13], 110)
        XCTAssertEqual(Array(list.values[14...17]), [-1000, 2000, -1000, 2000])
        XCTAssertEqual(Array(list.values[209...217]), [70, 78, 82, 84, 87, 91, 95, 98, 100])
        XCTAssertEqual(list.keys[54], "VisibleGameWidth")
    }

    func testIDLists() throws {
        let counts = ["edit": 1, "gaob": 40, "gaso": 24, "gasp": 8, "gate": 54, "tesp": 3]
        var total = 0
        for (id, count) in counts {
            XCTAssertEqual(try IDList(data: try raw("idli", id)).items.count, count, id)
            total += count
        }
        XCTAssertEqual(total, 130)
        let gaso = try IDList(data: try raw("idli", "gaso"))
        XCTAssertEqual(gaso.items[0].id, FourCC("clic"))
        XCTAssertEqual(gaso.items[20].id, FourCC("moco"))
        XCTAssertEqual(gaso.items[22].id, FourCC("acbo"))
        XCTAssertEqual(gaso.items[23].id, FourCC("miac"))
        XCTAssertEqual(try IDList(data: try raw("idli", "gasp")).items.map(\.id.description),
                       ["vigr", "edut", "pl1o", "mebu", "mebh", "galo", "mebu", "mebh"])
        XCTAssertEqual(try IDList(data: try raw("idli", "tesp")).items.map(\.id.description), ["tesm", "tesm", "tesm"])
        let gaob = try IDList(data: try raw("idli", "gaob"))
        XCTAssertEqual(gaob.items[0].id, FourCC("pl01"))
        XCTAssertEqual(gaob.items[1].id, FourCC("pl02"))
    }

    func testRectList22() throws {
        let list = try RectList(data: try raw("reli", "inre"))
        XCTAssertEqual(list.items.count, 22)
        XCTAssertEqual(list.items[0].rect, MacRect(top: 81, left: 25, bottom: 95, right: 135))
        XCTAssertEqual(list.items[0].key, "Scorebar Player 1 Score")
    }

    func testColorList() throws {
        let list = try ColorList(data: try raw("coli", "gaco"))
        XCTAssertEqual(list.items.count, 1)
        XCTAssertEqual(list.items[0].key, "scoreBar_Digit")
        XCTAssertEqual(list.items[0].color, 0x2B12)
    }

    func testFiftyFourTextFormats() throws {
        let index = try RealData.index()
        let records = index.records(ofType: FourCC("tefo")!)
        XCTAssertEqual(records.count, 54)
        var histogram: [TextFormat.Alignment: Int] = [:]
        for r in records {
            let f = TextFormat(data: try index.data(for: r))
            XCTAssertEqual(f.errors, [], "\(r.id)")
            XCTAssertTrue((0...32).contains(f.blendAmount), "\(r.id)")
            XCTAssertTrue((0...32).contains(f.colorStripBlendAmount), "\(r.id)")
            XCTAssertGreaterThanOrEqual(f.spaceBetweenChars, 0, "\(r.id)")
            histogram[f.format, default: 0] += 1
        }
        XCTAssertEqual(histogram, [.left: 28, .center: 8, .right: 4, .centerInBuffer: 12, .centerInGameArea: 2])
        // HUD score format (gate item 43 = sbs1): 494,83 CENT mono spacing 4, strip colour 94dee6.
        let gate = try IDList(data: try index.data(for: XCTUnwrap(index.record(type: FourCC("idli")!, id: FourCC("gate")!))))
        XCTAssertEqual(gate.items[43].id, FourCC("sbs1"))
        let sbs1 = TextFormat(data: try index.data(for: XCTUnwrap(index.record(type: FourCC("tefo")!, id: FourCC("sbs1")!))))
        XCTAssertEqual(sbs1.locX, 494)
        XCTAssertEqual(sbs1.locY, 83)
        XCTAssertEqual(sbs1.format, .center)
        XCTAssertTrue(sbs1.monospaced)
        XCTAssertEqual(sbs1.spaceBetweenChars, 4)
    }

    func testEveryTextEntryDecodesWithoutNUL() throws {
        let index = try RealData.index()
        let textTypes = ["stli", "flli", "idli", "reli", "coli", "tefo", "plde", "unde", "leve", "wede"].map { FourCC($0)! }
        var files = 0
        var highByteFiles: [String: Int] = [:]
        for record in index.records where textTypes.contains(record.type) {
            files += 1
            let text = DeimosText.decode(Array(try index.data(for: record)))
            XCTAssertFalse(text.contains(0), "\(record.type)/\(record.id)")
            if text.contains(where: { $0 >= 0x80 }) { highByteFiles[record.type.description, default: 0] += 1 }
        }
        XCTAssertEqual(files, 473)
        XCTAssertEqual(highByteFiles, ["leve": 6, "unde": 79, "stli": 1])
        // The one stli with Mac Roman bytes is `edit` (plan note 11 names `cred`; python over the paks
        // finds only `stli/Editor[edit].stli`).
        XCTAssertTrue(DeimosText.decode(Array(try raw("stli", "edit"))).contains(where: { $0 >= 0x80 }))
        XCTAssertFalse(DeimosText.decode(Array(try raw("stli", "cred"))).contains(where: { $0 >= 0x80 }))
    }

    func testSyntheticWrongFloatCount() throws {
        func floats(_ n: Int) -> Data { encoded((0..<n).map { "#F\($0)\t<\($0).5>\r" }.joined()) }
        XCTAssertThrowsError(try FloatList(data: floats(219))) {
            XCTAssertEqual($0 as? TextDataError, .wrongCount(expected: 220, actual: 219))
        }
        XCTAssertThrowsError(try FloatList(data: Data())) {
            XCTAssertEqual($0 as? TextDataError, .wrongCount(expected: 220, actual: 0))
        }
        // The loader stops after 220 items (do … while i < 220): a 221st is never read.
        let list = try FloatList(data: floats(221))
        XCTAssertEqual(list.values.count, 220)
        XCTAssertEqual(list.values[219], 219.5)
    }

    func testSyntheticRectAndIdErrors() {
        XCTAssertThrowsError(try IDList(data: encoded("#a <abcd>\r#b <abc>\r"))) {
            XCTAssertEqual($0 as? TextDataError, .badID(index: 1, value: "abc"))
        }
        XCTAssertThrowsError(try RectList(data: encoded("#a <1, 2, 3, 4>\r#b <1, 2>\r"))) {
            XCTAssertEqual($0 as? TextDataError, .badRect(index: 1, value: "1, 2"))
        }
        XCTAssertThrowsError(try ColorList(data: encoded("#a <12345g>\r"))) {
            XCTAssertEqual($0 as? TextDataError, .badColor(index: 0, value: "12345g"))
        }
        XCTAssertEqual(try IDList(data: encoded("#a <abcd>\r#b\t<none>\r")).items.map(\.key), ["a", "b"])
    }

    func testFormatIdUnknownFallsBackToLeft() {
        func format(_ v: String) -> TextFormat.Alignment { TextFormat(data: encoded("#Format_ID <\(v)>")).format }
        XCTAssertEqual(format("LEFT"), .left)
        XCTAssertEqual(format("CENT"), .center)
        XCTAssertEqual(format("RIGHT"), .right, "first 4 chars: RIGH")
        XCTAssertEqual(format("CEBU"), .centerInBuffer)
        XCTAssertEqual(format("CEGA"), .centerInGameArea)
        XCTAssertEqual(format("0"), .left)
        XCTAssertEqual(format("1"), .center)
        XCTAssertEqual(format("2"), .right)
        XCTAssertEqual(format("3"), .centerInBuffer)
        XCTAssertEqual(format("4"), .centerInGameArea)
        XCTAssertEqual(format("5"), .left)
        XCTAssertEqual(format("MIDDLE"), .left)
        XCTAssertEqual(format("XY"), .left)
        let unknown = TextFormat(data: encoded("#Format_ID <MIDDLE>"))
        XCTAssertTrue(unknown.alerts.contains { $0.hasPrefix("FILE DATA ERROR: Unknown Text Format Flag (MIDD)") },
                      "\(unknown.alerts)")
        // Order-independent: keys in any order; #Size_INT is never read.
        let f = TextFormat(data: encoded("#Size_INT <9>\r#Loc_Y_INT <3>\r#Loc_X_INT <2>\r#Format_ID <CENT>"))
        XCTAssertEqual(f.locX, 2)
        XCTAssertEqual(f.locY, 3)
        XCTAssertEqual(f.format, .center)
        XCTAssertFalse(f.errors.contains("#Size_INT"))
        XCTAssertTrue(f.errors.contains("#Monospaced_BOOL"), "missing keys are errors")
    }
}
