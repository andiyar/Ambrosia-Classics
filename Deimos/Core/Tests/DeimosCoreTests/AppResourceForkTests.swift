import XCTest
#if canImport(CryptoKit)
import CryptoKit
#endif
import HectorGraphics
import HectorResources
@testable import DeimosCore

/// The application's resource fork (plan Task C8, Research note 3; DECISIONS D24 addendum), committed as
/// the data-fork file `Resources/Deimos/Deimos Rising.rsrc` next to `Data`. HectorGraphics is a test /
/// census dependency only — never DeimosCore's (HectorKit D6).
final class AppResourceForkTests: XCTestCase {
    private func fork() throws -> (bytes: Data, collection: ResourceCollection) {
        let url = try DeimosData.dataDirectory().deletingLastPathComponent()
            .appendingPathComponent("Deimos Rising.rsrc")
        let bytes = try Data(contentsOf: url)
        let collection = try XCTUnwrap(try ResourceReader.read(fileAt: url), "not a resource map")
        return (bytes, collection)
    }

    func testAppResourceForkTypeCounts() throws {
        let (bytes, c) = try fork()
        XCTAssertEqual(bytes.count, 151_602)
        #if canImport(CryptoKit)                    // oracle only (the census prints its own SHA-256 too)
        XCTAssertEqual(SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined(),
                       "9fb61088c4d97d1b35117c82a44a0f1f848fb78eb7561b6e3964df623410d3f5")
        #endif
        XCTAssertEqual(c.types().count, 39)
        XCTAssertEqual(c.count, 140)
        let counts = Dictionary(uniqueKeysWithValues: c.counts().map { ($0.type, $0.count) })
        // Research note 3's named counts.
        for (type, n) in [("PICT", 12), ("DITL", 6), ("DLOG", 5), ("MENU", 5), ("STR#", 5), ("crsr", 3),
                          ("cicn", 2), ("TEXT", 3)] {
            XCTAssertEqual(counts[type], n, type)
        }
        XCTAssertEqual(c.resources(of: "PICT").map { Int($0.id) }, [128, 130, 135, 190, 191, 192, 193, 195, 196, 197, 900, 1000])
        XCTAssertEqual(c.resources(of: "DITL").map { Int($0.id) }, [190, 191, 192, 193, 900, 901])
    }

    func testEveryPICTAndDITLDecodes() throws {
        let (_, c) = try fork()
        // PICT id → width×height. 130 135 190–193 195–197 are 0x009B DirectBitsRgn (HectorKit D11).
        let sizes: [Int: [Int]] = [128: [32, 32], 130: [317, 2], 135: [2, 20], 190: [13, 13], 191: [13, 13],
                                   192: [13, 13], 193: [13, 13], 195: [115, 16], 196: [115, 16], 197: [115, 16],
                                   900: [99, 151], 1000: [640, 480]]
        for r in c.resources(of: "PICT") {
            let (p, path) = try PICT.decodeAny(data: r.data)
            XCTAssertEqual([p.width, p.height], sizes[Int(r.id)], "PICT \(r.id)")
            XCTAssertEqual(path, .raster, "PICT \(r.id)")
            XCTAssertEqual(p.droppedPaintOps, [], "PICT \(r.id)")
        }
        // DITL id → item count (76 in all; DITL 190 = the config dialog).
        let items: [Int: Int] = [190: 20, 191: 17, 192: 17, 193: 13, 900: 6, 901: 3]
        for r in c.resources(of: "DITL") {
            XCTAssertEqual(try XCTUnwrap(Ditl.decode(r.data), "DITL \(r.id)").count, items[Int(r.id)], "DITL \(r.id)")
        }
    }
}
