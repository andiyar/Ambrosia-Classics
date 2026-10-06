import XCTest
@testable import DeimosCore

/// Pak entry name → (display name, tag ID, type): bank pak-format.md §2.1–§2.2.
final class TagNameTests: XCTestCase {
    func testDisplayIdSuffix() throws {
        let t = try XCTUnwrap(TagName(entryName: "im08/Bomb Crater IA[BOCR].gif"))
        XCTAssertEqual(t.displayName, "Bomb Crater IA")
        XCTAssertEqual(t.id, FourCC("BOCR"))
        XCTAssertEqual(t.type, FourCC("im08"))
        XCTAssertEqual(t.id.description, "BOCR")
        XCTAssertEqual(FourCC("BOCR")?.rawValue, 0x424F_4352)
        // No folder: the whole name is parsed.
        XCTAssertEqual(TagName(entryName: "Last Film[last].film")?.type, FourCC("film"))
    }

    func testSpaceInIdAndCaseSensitivity() throws {
        let t = try XCTUnwrap(TagName(entryName: "soun/Bop[bop ].aif"))
        XCTAssertEqual(t.id, FourCC("bop "))
        XCTAssertEqual(t.type, FourCC("soun"))
        let lower = try XCTUnwrap(TagName(entryName: "im08/Bomb Crater IC[bocr].gif"))
        XCTAssertNotEqual(lower.id, FourCC("BOCR"))
        XCTAssertEqual(lower.id, FourCC("bocr"))
        XCTAssertEqual(FourCC.none, FourCC("none"))
        XCTAssertNil(FourCC("abc"))
        XCTAssertNil(FourCC("abcde"))
        XCTAssertNil(FourCC("ab😀"))
    }

    func testFirstDotSuffixAndTableOrder() {
        XCTAssertEqual(TagName(entryName: "Ambient Music Loop[ammu].IMA")?.type, FourCC("soun"))
        XCTAssertEqual(TagName(entryName: "x/Click[clic].aif")?.type, FourCC("soun"))
        XCTAssertEqual(TagName(entryName: "im16/Developer Credit[decr].TGA")?.type, FourCC("im16"))
        XCTAssertEqual(TagName(entryName: "leve/Level 1[le01].lvl")?.type, FourCC("leve"))
        XCTAssertEqual(TagName(entryName: "unde/Thing[thng].unit")?.type, FourCC("unde"))
        XCTAssertEqual(TagName(entryName: "Rects[inre].RectList")?.type, FourCC("reli"))
        // Unknown suffix → nil; the suffix runs from the FIRST '.', so a second '.' spoils it.
        XCTAssertNil(TagName(entryName: "x/Thing[thng].png"))
        XCTAssertNil(TagName(entryName: "x/Dr. Thing[thng].gif"))
        XCTAssertNil(TagName(entryName: "x/Thing[thng].gif.bak"))
        XCTAssertEqual(TagName.typeOrder.map(\.description),
                       ["im08", "im16", "soun", "stli", "flli", "wede", "reli", "idli", "coli",
                        "tefo", "plde", "pref", "film", "unde", "leve"])
    }

    func testRejects() {
        XCTAssertNil(TagName(entryName: "im08/.DS_Store"))
        XCTAssertNil(TagName(entryName: ".DS_Store[abcd].gif"))
        XCTAssertNil(TagName(entryName: "im08/Bomb Crater.gif"))        // no '['
        XCTAssertNil(TagName(entryName: "im08/Bomb[BOC].gif"))          // 3-char ID
        XCTAssertNil(TagName(entryName: "im08/Bomb[BOCRX].gif"))        // 5-char ID
        XCTAssertNil(TagName(entryName: "im08/Bomb[BOCR.gif"))          // no ']'
        XCTAssertNil(TagName(entryName: "im08/Bomb[BOCR]"))             // no suffix
        XCTAssertNil(TagName(entryName: "im08/"))                       // folder
    }
}
