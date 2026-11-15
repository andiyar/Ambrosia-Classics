import Foundation
import DeimosCore
import DeimosHost

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

    /// The shipped film `tag` (a `film` record in the data's tag index), through the one lookup (`FilmLookup`).
    static func film(_ tag: String) throws -> Film {
        let assets = try getAssets()
        do { return try FilmLookup.film(tag, in: assets) } catch is FilmLookup.NoSuchFilm {
            throw Missing(description: "no film '\(tag)' in \(try directory.get().path)")
        }
    }
}
