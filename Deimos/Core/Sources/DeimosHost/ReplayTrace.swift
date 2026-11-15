import Foundation
import DeimosCore

/// The replay trace (plan G4.3, H2): one `TickTrace.Row` per ticked pass, read from the session's public state after
/// the pass, and a CSV writer with a fixed header (the row's fields in declaration order). The triage tool for the
/// replay gate: the first tick at which a row cannot be justified from the bank or listing is the divergence.
public struct ReplayTrace: Equatable, Sendable {
    /// The rows, in pass order.
    public private(set) var table = TickTrace()

    public init() {}

    public var rows: [TickTrace.Row] { table.rows }

    /// The CSV header: `TickTrace.Row`'s fields, in order.
    public static let csvHeader = "gameTime,cursor,p1State,p1Score,p1Lives,p1Shield,p1Money,p1Multiplier,draws,"
        + "entities,groups,scrollTop,paused,levelEnding,sector"

    /// The row for the session's state now: game time (G+0x1c), P1's film cursor (−1 without a film), P1's life
    /// state / decoded score / lives / decoded shield / money / multiplier, `rand()` calls since `srand`, pool
    /// entities in use, active groups (PERM included), the scroll window's top row, the scroll paused (speed 0),
    /// G+0x39, the sector G+0x14 (plan CS).
    public static func row(_ s: DeimosSession) -> TickTrace.Row {
        let p = s.players[0]
        return TickTrace.Row(gameTime: s.gameTime, cursor: s.game.film?.cursors[0] ?? -1, p1State: p.lifeState,
                             p1Score: p.score, p1Lives: p.lives, p1Shield: p.shield, p1Money: p.money,
                             p1Multiplier: p.multiplier, draws: s.rng.draws, entities: s.game.world.liveCount,
                             groups: s.game.world.groups.count, scrollTop: s.scroll.window.top,
                             paused: s.scroll.speed == 0, levelEnding: s.game.flags.levelEnding,
                             sector: s.game.flags.sector)
    }

    /// Append the session's row (call after a ticked pass).
    public mutating func record(_ s: DeimosSession) {
        table.rows.append(Self.row(s))
    }

    /// One CSV line (no newline): integers in decimal, the shield as Swift's shortest round-trip `Float` text,
    /// Booleans as 0 / 1.
    public static func csvLine(_ r: TickTrace.Row) -> String {
        [String(r.gameTime), String(r.cursor), String(r.p1State), String(r.p1Score), String(r.p1Lives),
         "\(r.p1Shield)", String(r.p1Money), String(r.p1Multiplier), String(r.draws), String(r.entities),
         String(r.groups), String(r.scrollTop), r.paused ? "1" : "0", r.levelEnding ? "1" : "0", String(r.sector)]
            .joined(separator: ",")
    }

    /// The header and every row, each line `\n`-terminated.
    public func csv() -> String {
        var out = Self.csvHeader + "\n"
        for r in rows { out += Self.csvLine(r) + "\n" }
        return out
    }

    /// `csv()` as UTF-8 at `url` (replaced if present).
    public func write(to url: URL) throws {
        try Data(csv().utf8).write(to: url, options: .atomic)
    }
}
