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
        XCTAssertEqual(TagName.parse("im08/.DS_Store"), .failure(.ignored))
        XCTAssertEqual(TagName.parse("im08/Bomb Crater.gif"), .failure(.noValidInformation))   // no '['
        XCTAssertEqual(TagName.parse("im08/Bomb[BOC].gif"), .failure(.noTagID))
        XCTAssertEqual(TagName.parse("im08/Bomb[BOCR].xyz"), .failure(.noValidSuffix))
        XCTAssertEqual(TagName.parse("im08/Bomb[BOCR].PAK"), .failure(.zipFile))
        XCTAssertNil(TagName(entryName: "im08/Bomb[BOC].gif"))          // 3-char ID
        XCTAssertNil(TagName(entryName: "im08/Bomb[BOCRX].gif"))        // 5-char ID
        XCTAssertNil(TagName(entryName: "im08/Bomb[BOCR.gif"))          // no ']'
        XCTAssertNil(TagName(entryName: "im08/Bomb[BOCR]"))             // no suffix
        XCTAssertNil(TagName(entryName: "im08/"))                       // folder
    }

    /// `.DS_Store` / `icon` (case-sensitive) are silent only when the name has no `[`
    /// (`10002264–1000229c`); `strtok` ID parse (`10003a8c–10003ac4`).
    func testSilentWordsAndStrtokID() throws {
        XCTAssertEqual(TagName.parse("Some icon.gif"), .failure(.ignored))
        XCTAssertEqual(TagName.parse("Icon.gif"), .failure(.noValidInformation), "strstr is case-sensitive")
        let icon = try XCTUnwrap(TagName(entryName: "im08/Big icon[icon].gif"))
        XCTAssertEqual(icon.id, FourCC("icon"))
        XCTAssertEqual(icon.displayName, "Big icon")
        // With a '[', .DS_Store is not silent: the first '.' starts the suffix ".DS_Store[abcd]".
        XCTAssertEqual(TagName.parse(".DS_Store[abcd].gif"), .failure(.noValidSuffix))
        // strtok skips leading delimiters.
        XCTAssertEqual(TagName.parse("[abcd].gif"), .failure(.noTagID))
        let skip = try XCTUnwrap(TagName(entryName: "X[]abcd].gif"))
        XCTAssertEqual(skip.id, FourCC("abcd"))
        XCTAssertEqual(skip.displayName, "X")
        XCTAssertEqual(TagName.parse("X[[abcd].gif"), .failure(.noTagID))   // second token "[abcd"
        XCTAssertEqual(TagName.strtokID("Name[abcd"), "abcd")
    }
}
