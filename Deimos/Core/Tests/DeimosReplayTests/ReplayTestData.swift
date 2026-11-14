import Foundation
import DeimosCore

/// The replay bundle's own data locator and asset cache (plan standing rule 4): the committed
/// `Resources/Deimos/Data`, or `DEIMOS_DATA` when set. A missing directory or film is a failure that names the path —
/// never a skip. Assets are loaded once per test process.
enum ReplayTestData {
    struct Missing: Error, CustomStringConvertible {
        let description: String
    }

    static let directory: Result<URL, Error> = Result { try DeimosData.dataDirectory() }

    static let assets: Result<DeimosAssets, Error> = Result {
        try DeimosAssets.load(index: TagIndex(dataDirectory: directory.get()))
    }

    static func getAssets() throws -> DeimosAssets { try assets.get() }

    /// The shipped film `tag` (a `film` record in the data's tag index).
    static func film(_ tag: String) throws -> Film {
        let assets = try getAssets()
        guard let id = FourCC(tag), let record = assets.index.record(type: FourCC("film")!, id: id) else {
            throw Missing(description: "no film '\(tag)' in \(try directory.get().path)")
        }
        return try Film(data: assets.index.data(for: record))
    }
}
