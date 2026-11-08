import FerazelRender
@testable import FerazelWinKit
import Foundation
import XCTest

/// The hidden switches (Ruling 11, 20): `FerazelSettings.parse` over a command line's strings reads every value as the
/// Mac's `UserDefaults` argument domain reads it. The loose rows ("y", "t", "2abc", …) were measured on the Mac
/// (2026-10-26, `UserDefaults` argument domain, both a real `-K value` argv and a volatile argument domain): `bool` is
/// true only for "yes" / "true" in any case and the exact "1"; `integer` takes the whole string as an optionally
/// signed decimal after leading white space (anything after the digits → 0), clamped to Int32.
final class FerazelSettingsTests: XCTestCase {
    private func parse(_ values: [String: String], environment: [String: String] = [:]) -> FerazelSettings {
        FerazelSettings.parse(lookup: FerazelSettings.arguments(values), environment: environment)
    }

    func testParseTableAndMute() {
        // FerazelLevel: an integer in BuiltLevels.range (1…5), else 1.
        let levels: [(String?, Int)] = [(nil, 1), ("2", 2), ("4", 4), ("9", 1), ("0", 1), ("2abc", 1), (" 3", 3),
                                        ("-2", 1)]
        for (v, want) in levels {
            XCTAssertEqual(parse(v.map { [FerazelSettings.levelKey: $0] } ?? [:]).startLevel, want, "FerazelLevel \(v ?? "absent")")
        }
        // ColorTieBreak: exactly "lowest" → .lowest; anything else → .highest.
        let ties: [(String?, ColorSearch.TieBreak)] = [(nil, .highest), ("lowest", .lowest), ("LOWEST", .highest),
                                                       ("highest", .highest)]
        for (v, want) in ties {
            XCTAssertEqual(parse(v.map { [FerazelSettings.tieBreakKey: $0] } ?? [:]).tieBreak, want, "ColorTieBreak \(v ?? "absent")")
        }
        // MacGamma: the argument domain's bool.
        let bools: [(String?, Bool)] = [(nil, false), ("YES", true), ("yes", true), ("1", true), ("true", true),
                                        ("TRUE", true), ("NO", false), ("y", false), ("t", false), ("2abc", false),
                                        ("2", false), ("01", false), ("0", false)]
        for (v, want) in bools {
            XCTAssertEqual(parse(v.map { [FerazelSettings.macGammaKey: $0] } ?? [:]).macGamma, want, "MacGamma \(v ?? "absent")")
        }
        // The loose integer reads, measured.
        let ints: [(String, Int)] = [("2", 2), ("2abc", 0), ("y", 0), ("t", 0), ("lowest", 0), (" 4", 4), ("+5", 5),
                                     ("-3", -3), ("1.9", 0), ("1 ", 0), ("0x10", 0), ("", 0),
                                     ("99999999999", Int(Int32.max)), ("-2147483649", Int(Int32.min))]
        for (v, want) in ints {
            XCTAssertEqual(FerazelSettings.arguments(["K": v]).integer("K"), want, "integer \"\(v)\"")
        }
        let lookup = FerazelSettings.arguments(["K": "2abc"])
        XCTAssertEqual(lookup.string("K"), "2abc")
        XCTAssertNil(lookup.string("absent"))
        XCTAssertEqual(lookup.integer("absent"), 0)
        XCTAssertFalse(lookup.bool("absent"))
        #if os(macOS)
        // The emulation against the Mac's own argument domain, every row (the Mac oracle; never on Windows).
        let defaults = UserDefaults(suiteName: "ferazel.wf1.settings.\(getpid())")!
        for v in levels.compactMap(\.0) + ties.compactMap(\.0) + bools.compactMap(\.0) + ints.map(\.0) {
            defaults.setVolatileDomain(["K": v], forName: UserDefaults.argumentDomain)
            let mine = FerazelSettings.arguments(["K": v])
            XCTAssertEqual(mine.integer("K"), defaults.integer(forKey: "K"), "integer \"\(v)\" vs UserDefaults")
            XCTAssertEqual(mine.bool("K"), defaults.bool(forKey: "K"), "bool \"\(v)\" vs UserDefaults")
            XCTAssertEqual(mine.string("K"), defaults.string(forKey: "K"), "string \"\(v)\" vs UserDefaults")
        }
        defaults.removeVolatileDomain(forName: UserDefaults.argumentDomain)
        #endif

        // Mute (Ruling 20): `-FerazelMute` by the same bool, or FERAZEL_MUTE=1 in the environment.
        XCTAssertTrue(parse([FerazelSettings.muteKey: "YES"]).mute)
        XCTAssertFalse(parse([FerazelSettings.muteKey: "NO"]).mute)
        XCTAssertTrue(parse([:], environment: [FerazelSettings.muteEnvironment: "1"]).mute)
        XCTAssertFalse(parse([:], environment: [FerazelSettings.muteEnvironment: "0"]).mute)
        XCTAssertFalse(parse([:]).mute)
        XCTAssertTrue(parse([FerazelSettings.muteKey: "NO"], environment: [FerazelSettings.muteEnvironment: "1"]).mute)
        XCTAssertEqual(FerazelSettings.muteKey, "FerazelMute")
        XCTAssertEqual(FerazelSettings.muteEnvironment, "FERAZEL_MUTE")
        XCTAssertEqual([FerazelSettings.levelKey, FerazelSettings.tieBreakKey, FerazelSettings.macGammaKey],
                       ["FerazelLevel", "ColorTieBreak", "MacGamma"])
        XCTAssertEqual(parse([:]), FerazelSettings())
    }
}
