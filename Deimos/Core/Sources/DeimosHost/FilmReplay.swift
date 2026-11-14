import Foundation
import DeimosCore

/// A demo film replayed headless (plan H2, for the replay gate G4): `HeadlessRunner(assets:film:)` — seed, sector
/// and players from the film, fresh prefs, logic only — run until the session ends or `maxPasses`.
public struct FilmReplay {
    /// Replay `film`; `trace` records a `ReplayTrace` row per ticked pass into the result.
    public static func run(film: Film, assets: DeimosAssets, trace: Bool = false,
                           maxPasses: Int) throws -> ReplayResult {
        var runner = try HeadlessRunner(assets: assets, film: film)
        if trace { runner.trace = ReplayTrace() }
        return runner.run(maxPasses: maxPasses)
    }
}
