import Foundation
import DeimosCore

/// The one lookup of a shipped demo film by its tag (plan CS): the `film` record `tag` (de01–de04) in the data's tag
/// index, decoded. Used by the replay tool, the test bundles and the app's `-film`.
public enum FilmLookup {
    /// No `film` record with this tag in the data (an unknown tag, or one that is not four Mac Roman characters).
    public struct NoSuchFilm: Error, Equatable, CustomStringConvertible {
        public let tag: String
        public init(tag: String) { self.tag = tag }
        public var description: String { "no film record \"\(tag)\" in the data" }
    }

    /// The shipped `film` record `tag`, decoded; `NoSuchFilm` when there is none, the decoder's error when its data
    /// is not a film.
    public static func film(_ tag: String, in assets: DeimosAssets) throws -> Film {
        guard let type = FourCC("film"), let id = FourCC(tag),
              let record = assets.index.record(type: type, id: id) else { throw NoSuchFilm(tag: tag) }
        return try Film(data: assets.index.data(for: record))
    }
}
