import XCTest
import HectorResources
@testable import DeimosHost
@testable import DeimosCore

/// The Last Film store on disk (Phase 4 S5 FR; plan ruling 7; grounding B §4b): `FUN_100095b0(film, 'last')` saves
/// the image as `Local:film:Last Film[last].film`, and the next tag index finds it ahead of the shipped copy. The
/// store's root is a temporary folder here — never the real Application Support folder.
final class LastFilmStoreTests: XCTestCase {
    private var root: URL!

    override func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("LastFilmStoreTests-\(UUID().uuidString)", isDirectory: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: root)
    }

    /// Store → second Local root → `last` resolves to the stored film, not the shipped de01 copy; without the second
    /// root (the default) the shipped copy is still found.
    func testLastFilmOverridesShippedCopy() throws {
        let dataDirectory = try DeimosData.dataDirectory()
        let shipped = try TagIndex(dataDirectory: dataDirectory)
        let film = FourCC("film")!, last = FourCC("last")!
        let de02 = [UInt8](try shipped.data(for: XCTUnwrap(shipped.record(type: film, id: FourCC("de02")!))))
        let shippedLast = [UInt8](try shipped.data(for: XCTUnwrap(shipped.record(type: film, id: last))))
        XCTAssertNotEqual(de02, shippedLast)

        let store = LastFilmFileStore(root: root)
        XCTAssertNil(try store.load(), "nothing saved yet")
        try store.save(de02)
        let path = root.appendingPathComponent("Local/film/Last Film[last].film")
        XCTAssertEqual([UInt8](try Data(contentsOf: path)), de02)
        XCTAssertEqual(try store.load(), de02)
        XCTAssertEqual(store.localRoot.path, root.appendingPathComponent("Local").path)

        let overlaid = try TagIndex(dataDirectory: dataDirectory, secondLocalRoot: store.localRoot)
        let record = try XCTUnwrap(overlaid.record(type: film, id: last))
        XCTAssertTrue(record.isLocal)
        XCTAssertEqual(record.displayName, "Last Film")
        XCTAssertEqual([UInt8](try overlaid.data(for: record)), de02)
        XCTAssertEqual(overlaid.records.count, shipped.records.count, "the stored file replaces the shipped one")
        XCTAssertEqual(overlaid.alerts, [])
        XCTAssertEqual(overlaid.records(ofType: film).map(\.id.description), ["last", "de01", "de02", "de03", "de04"])

        let assets = try DeimosAssets.load(dataDirectory: dataDirectory, secondLocalRoot: store.localRoot)
        let viaAssets = try XCTUnwrap(assets.index.record(type: film, id: last))
        XCTAssertEqual([UInt8](try assets.index.data(for: viaAssets)), de02)

        // A second save replaces the first.
        try store.save(shippedLast)
        XCTAssertEqual(try store.load(), shippedLast)
    }
}
