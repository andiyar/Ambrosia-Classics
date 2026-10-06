import XCTest
import HectorResources
@testable import DeimosCore

/// The tag index over synthetic `Data` folders (bank pak-format.md §2.3, app-pak-music-library.md §2,
/// loose-ends-session.md §8.7). Zips are built in-test (STORED, the shipped shape).
final class TagIndexTests: XCTestCase {
    private var root: URL!

    override func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("DeimosTagIndexTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let root { try? FileManager.default.removeItem(at: root) }
    }

    // MARK: helpers

    private func writeLocal(_ folder: String, _ name: String, _ bytes: [UInt8]) throws {
        let dir = root.appendingPathComponent("Local/\(folder)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try Data(bytes).write(to: dir.appendingPathComponent(name))
    }

    private func writePak(_ name: String, _ entries: [(String, [UInt8])], compressed: Set<String> = []) throws {
        let dir = root.appendingPathComponent("Paks", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try StoredZip.build(entries, compressed: compressed).write(to: dir.appendingPathComponent(name))
    }

    private func writeRaw(_ relative: String, _ bytes: [UInt8]) throws {
        let url = root.appendingPathComponent(relative)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(bytes).write(to: url)
    }

    private let film = FourCC("film")!

    // MARK: tests

    func testLocalScannedBeforePaks() throws {
        try writePak("A.pak", [("film/", []), ("film/Pak One[pak1].film", [1, 2, 3])])
        try writeLocal("film", "Local One[loc1].film", [9, 9])
        try writeLocal("coli", "Local Colours[loco].coli", [7])
        let index = try TagIndex(dataDirectory: root)
        // Local first, its folders in type-table order (coli is table slot 8, film slot 12), then paks.
        XCTAssertEqual(index.records.map(\.id.description), ["loco", "loc1", "pak1"])
        XCTAssertEqual(index.records.map(\.isLocal), [true, true, false])
        XCTAssertEqual(index.records[2].displayName, "Pak One")
        XCTAssertEqual(index.records[2].size, 3)
        XCTAssertEqual(Array(try index.data(for: index.records[2])), [1, 2, 3])
        XCTAssertEqual(Array(try index.data(for: index.records[1])), [9, 9])
        XCTAssertEqual(try index.data(for: index.records[2]).startIndex, 0, "entry bytes are rebased")
        if case .local(let url) = index.records[1].source {
            XCTAssertEqual(url.lastPathComponent, "Local One[loc1].film")
        } else { XCTFail("Local record must have a .local source") }
        if case .pak(let archiveIndex, let entry) = index.records[2].source {
            XCTAssertEqual(archiveIndex, 0)
            XCTAssertEqual(entry.name, "film/Pak One[pak1].film")
        } else { XCTFail("pak record must have a .pak source") }
        XCTAssertEqual(index.paks.map(\.lastPathComponent), ["A.pak"])
    }

    func testLocalOverridesEveryPakCopy() throws {
        try writePak("A.pak", [("film/Dupe A[dupe].film", [1]), ("film/Other[othr].film", [2])])
        try writePak("B.pak", [("film/Dupe B[dupe].film", [3])])
        try writeLocal("film", "Dupe Local[dupe].film", [4, 4])
        let index = try TagIndex(dataDirectory: root)
        XCTAssertEqual(index.records.map(\.id.description), ["dupe", "othr"])
        let dupe = try XCTUnwrap(index.record(type: film, id: FourCC("dupe")!))
        XCTAssertTrue(dupe.isLocal)
        XCTAssertEqual(dupe.displayName, "Dupe Local")
        XCTAssertEqual(Array(try index.data(for: dupe)), [4, 4])
        XCTAssertEqual(index.alerts.filter { $0.hasPrefix("    Tag Overridden:  ") }.count, 2, "\(index.alerts)")
        // Duplicates are counted per Local flag before the override pass: the two pak copies are a
        // pair (each logs "(2)"); the Local copy is not a duplicate of them.
        let dupes = index.alerts.filter { $0.hasPrefix("Pak Error (non fatal): Duplicate (") }
        XCTAssertEqual(dupes.count, 2, "\(index.alerts)")
        XCTAssertTrue(dupes.allSatisfy { $0.hasPrefix("Pak Error (non fatal): Duplicate (2) tags found. Path: \"") })
        XCTAssertTrue(dupes[0].contains("A.pak\", Tag ID: 'dupe', Tag Type: 'film'"), dupes[0])
        XCTAssertTrue(dupes[1].contains("B.pak\", Tag ID: 'dupe', Tag Type: 'film'"), dupes[1])
        XCTAssertTrue(index.alerts.firstIndex { $0.contains("Duplicate") }!
                      < index.alerts.firstIndex { $0.contains("Tag Overridden") }!, "duplicates are logged first")
        XCTAssertTrue(index.alerts.contains("    Tag Overridden:  \"\(root.path)/Paks/A.pak:Dupe A[dupe].film\""),
                      "\(index.alerts)")
    }

    func testPakDuplicatesFirstWins() throws {
        try writePak("A.pak", [("film/Dupe A[dupe].film", [1])])
        try writePak("B.pak", [("film/Dupe B[dupe].film", [3])])
        let index = try TagIndex(dataDirectory: root)
        XCTAssertEqual(index.records.count, 2, "pak duplicates are kept")
        XCTAssertEqual(index.records(ofType: film).map(\.displayName), ["Dupe A", "Dupe B"])
        XCTAssertEqual(index.record(type: film, id: FourCC("dupe")!)?.displayName, "Dupe A")
        let pakPath = root.appendingPathComponent("Paks").path
        XCTAssertEqual(index.alerts, [
            "Pak Error (non fatal): Duplicate (2) tags found. Path: \"\(pakPath)/A.pak\", Tag ID: 'dupe', Tag Type: 'film'",
            "Pak Error (non fatal): Duplicate (2) tags found. Path: \"\(pakPath)/B.pak\", Tag ID: 'dupe', Tag Type: 'film'",
            "\n    Tag Index Incomplete!  Aborting.",
        ])
        XCTAssertFalse(index.alerts.contains { $0.contains("Tag Overridden") })
    }

    func testWrongFolderStillAddedWithAlert() throws {
        try writeLocal("im08", "Lost Film[lost].film", [5])
        let index = try TagIndex(dataDirectory: root)
        let lost = try XCTUnwrap(index.record(type: film, id: FourCC("lost")!))
        XCTAssertTrue(lost.isLocal)
        XCTAssertEqual(lost.type, film, "typed by its SUFFIX, not its folder")
        let path = root.appendingPathComponent("Local/im08/Lost Film[lost].film").path
        XCTAssertEqual(Array(index.alerts.prefix(2)), [
            "\nFILE ALERT. Incorrect file location.  The file should be placed in the \"film\" folder!\n"
                + "Offending File: \"\(path)\"\n",
            "\n\nFILE ERROR: Failed operation:  FALSE\nIn file:    U_Pak.cc\nAt line:  402",
        ])
    }

    func testZeroSizeAndNonZipSkipped() throws {
        // The compressed entry ENDS A.pak's enumeration (FUN_10049ca0 returns false): "After" is never indexed.
        try writePak("A.pak", [("film/", []), ("film/Empty[empt].film", []), ("film/Good[good].film", [1]),
                               ("film/No Id.film", [1]), ("film/Short[abc].film", [1]), ("film/Bad Suffix[bads].xyz", [1]),
                               ("film/Nested.zip[nest].film", [1]),
                               ("film/Squashed[sqsh].film", [1, 2, 3]), ("film/After[aftr].film", [1])],
                     compressed: ["film/Squashed[sqsh].film"])
        try writeRaw("Paks/Readme.txt", [1, 2, 3])
        try writeRaw("Paks/.DS_Store", [1])
        try writeRaw("Paks/Broken.zip", [0x50, 0x4B, 0, 0])
        try writeLocal("film", "Zero[zero].film", [])
        try writeLocal("film", "Icon\r", [])
        try writeLocal("film", ".DS_Store", [1, 2])
        try writeLocal("film", "Local Pak.zip", [1, 2])
        try writeLocal("film", "Header[head].film.tag", [1, 2])
        try writeLocal("film", "Some icon.film", [1])
        let index = try TagIndex(dataDirectory: root)
        XCTAssertEqual(index.records.map(\.id.description), ["good"])
        XCTAssertEqual(index.paks.map(\.lastPathComponent), ["A.pak", "Broken.zip"])
        let paks = root.appendingPathComponent("Paks").path
        let expected = [
            "FILE ALERT.  Skipping file.  (.tag header files are not supported)",
            "\nFILE ALERT.  Skipping file.  (Zip files are not supported in the Local directory)\n"
                + "Offending file:  \"Local Pak.zip\"\n",
            "\nFILE ALERT.  Skipping file, as no valid information was found in filename:  \"No Id.film\"",
            "\nFILE ALERT.  Could not find Tag ID in file:  Short[abc].film",
            "\nFILE ALERT.  Could not find a valid suffix in file:  Bad Suffix[bads].xyz",
            "\nFILE ALERT.  Skipping file.  (Zip files are not supported in the Local directory)\n"
                + "Offending file:  \"Nested.zip[nest].film\"\n",
            "\nFILE ERROR: Compressed Zip files are not supported!\n(NOTE: All files must be archived using the "
                + "Stored method only)\nOffending Zip Entry:  'film/Squashed[sqsh].film'\nOffending File:       '\(paks)/A.pak'",
            "\n\nFILE ERROR: Failed operation:  FALSE\nIn file:    unzip.c\nAt line:  216",
            "\nFILE ALERT.  Skipping a file, as it could not be opened.  It may be an empty Zip file.  (Only Zip files "
                + "are supported in the Paks directory)\nOffending File:  \"Broken.zip\"\n",
            "\nFILE ALERT.  Skipping file.  (Only Zip files are supported in the Paks directory)\n"
                + "Offending File:  \"Readme.txt\"\nPath:  \"\(paks)/Readme.txt\"",
            "\n    Tag Index Incomplete!  Aborting.",
        ]
        XCTAssertEqual(index.alerts, expected)
    }

    func testZipNamesAreCaseInsensitiveSubstrings() throws {
        // FUN_100040c0 lower-cases, then strstr(".zip") / strstr(".pak"): GAME.PAK is a pak.
        try writePak("GAME.PAK", [("film/Pak One[pak1].film", [1])])
        try writeLocal("film", "Thing.ZIP", [1, 2])
        let index = try TagIndex(dataDirectory: root)
        XCTAssertEqual(index.records.map(\.id.description), ["pak1"])
        XCTAssertEqual(index.paks.map(\.lastPathComponent), ["GAME.PAK"])
        XCTAssertEqual(index.alerts.first,
                       "\nFILE ALERT.  Skipping file.  (Zip files are not supported in the Local directory)\n"
                       + "Offending file:  \"Thing.ZIP\"\n")
        XCTAssertTrue(TagName.isZipName("my.pak.backup"))
        XCTAssertTrue(TagName.isZipName("X.Zip"))
        XCTAssertFalse(TagName.isZipName("Zip.film"))
    }

    func testIncompleteIndexAlertBelow100() throws {
        let incomplete = "\n    Tag Index Incomplete!  Aborting."
        try writePak("A.pak", (0..<99).map { (String(format: "film/F%02d[f%03d].film", $0, $0), [UInt8(1)]) })
        let ninetyNine = try TagIndex(dataDirectory: root)
        XCTAssertEqual(ninetyNine.records.count, 99)
        XCTAssertEqual(ninetyNine.alerts, [incomplete])
        try writeLocal("film", "Hundredth[h100].film", [1])
        let hundred = try TagIndex(dataDirectory: root)
        XCTAssertEqual(hundred.records.count, 100)
        XCTAssertEqual(hundred.alerts, [])
    }
}

/// Builds a STORED zip the way ZipIt did (local header, data, central directory, EOCD).
enum StoredZip {
    static func build(_ entries: [(String, [UInt8])], compressed: Set<String> = []) -> Data {
        var out: [UInt8] = []
        var central: [UInt8] = []
        func u16(_ v: Int, _ a: inout [UInt8]) { a += [UInt8(v & 0xFF), UInt8(v >> 8 & 0xFF)] }
        func u32(_ v: UInt32, _ a: inout [UInt8]) { for s in stride(from: 0, to: 32, by: 8) { a.append(UInt8(v >> UInt32(s) & 0xFF)) } }
        for (name, bytes) in entries {
            let nameBytes = Array(name.utf8)
            let method = compressed.contains(name) ? 8 : 0
            let crc = CRC32.checksum(bytes)
            let lho = out.count
            u32(0x0403_4b50, &out); u16(20, &out); u16(0, &out); u16(method, &out); u16(0, &out); u16(0, &out)
            u32(crc, &out); u32(UInt32(bytes.count), &out); u32(UInt32(bytes.count), &out)
            u16(nameBytes.count, &out); u16(0, &out); out += nameBytes; out += bytes
            u32(0x0201_4b50, &central); u16(0x0714, &central); u16(20, &central); u16(0, &central)
            u16(method, &central); u16(0, &central); u16(0, &central)
            u32(crc, &central); u32(UInt32(bytes.count), &central); u32(UInt32(bytes.count), &central)
            u16(nameBytes.count, &central); u16(0, &central); u16(0, &central); u16(0, &central); u16(0, &central)
            u32(0, &central); u32(UInt32(lho), &central); central += nameBytes
        }
        let cdOffset = out.count
        out += central
        u32(0x0605_4b50, &out); u16(0, &out); u16(0, &out); u16(entries.count, &out); u16(entries.count, &out)
        u32(UInt32(central.count), &out); u32(UInt32(cdOffset), &out); u16(0, &out)
        return Data(out)
    }
}
