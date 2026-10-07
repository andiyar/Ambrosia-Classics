import Foundation
import FerazelCore

/// A level's computed colour tables as indices: `FerazelCore.TableRequests`' requests resolved through `ColorSearch`
/// (the `Color2Index` model, design §6, plan invariant 7), at the original's moment (lighting-tables §1.3):
///
/// - `.BuildTintTable @ 10020a5c` (+ `.BuildWaterTintTable`, the pair tables) and `.BuildReddenTable @ 1001ff1c` read
///   the **working copy** `1009fe94` of the level+base CLUT (`10020a8c`, `10020408`, `1001ff34` `lwz −0x79ac(r2)`),
///   built in `.GameLoop` once per level entry after one `.AnimateCLUT` step (decompile l. 5206–5208);
/// - `.CalcLightingTable @ 1001acc4` (ambient, light) reads the **unanimated** level+base CLUT `1009ff8c`
///   (`1001ad04 lwz −0x78b4(r2)`), in `.SetupLevel` after `.SetScreenClut(level+base)`;
/// - every `Color2Index` answers from the device's inverse table, which `.SetScreenClut` builds from the level+base
///   CLUT (`MakeITable`, lighting-tables §1.2) — the `screenClut` the search runs against.
///
/// For level 1 all three are CLUT 202. `forLevel` uses the unanimated level+base CLUT as the working copy, which is
/// exact for every level whose header `0x2732` (`.AnimateCLUT` count) is 0 — all but levels 50, 51 and 67, where the
/// one animation step before `.BuildTintTable` is not modelled here (pass `workingClut` for those).
///
/// Layouts are the original's: table k / w / n is `[k][i]`; the pair tables and grey-pull are `[row·0x100 + i]`
/// (row = sprite pixel, i = screen pixel); light is `[D·0x6e00 + (g·11 + k)·0x100 + i]`.
public struct LevelTables: Sendable, Equatable {
    /// The CLUT `ColorSearch` ran against (the screen CLUT, level+base).
    public let screenClutId: Int16
    public let model: ColorSearch.Model
    /// `_DAT_100a0140`: 25 tint tables (lighting-tables §3), table 0xa from the injected random source.
    public let tint: [[UInt8]]
    /// `_DAT_100a0170`: water tables w 0..5 (§4); table 4 is never written (all index 0).
    public let water: [[UInt8]]
    /// `_DAT_100a0178`: redden A, n 0..7 (§5; entry 0xff forced to 0xff).
    public let reddenA: [[UInt8]]
    /// `_DAT_100a0174`: redden B, n 0..15 (§5).
    public let reddenB: [[UInt8]]
    /// The §6.1 pair tables `0160`, `015c`, `0158`, `0154`, `0150`, `014c`, 65,536 entries each.
    public let pairs: [TableRequests.Pair: [UInt8]]
    /// `_DAT_100a0144` grey-pull, `[a·0x1000 + b·0x100 + i]` (§6.1).
    public let greyPull: [UInt8]
    /// `_DAT_100a0130` ambient, D 0..15 (§7.3).
    public let ambient: [[UInt8]]
    /// `_DAT_100a0134` light, 16 × 0x6e00 (§7.3).
    public let light: [UInt8]

    /// - Parameters:
    ///   - workingClut: the working copy the tint/water/redden/pair builders read.
    ///   - levelBaseClut: the unanimated level+base CLUT the lighting builder reads.
    ///   - screenClut: the CLUT `Color2Index` searches (the device CLUT after `.SetScreenClut`).
    ///   - random: `.FastRand(n)` for tint table 0xa.
    public init(workingClut: ColorLUT, levelBaseClut: ColorLUT, screenClut: ColorLUT, search: ColorSearch,
                random: (Int16) -> UInt16) {
        func resolve(_ entries: [TableRequests.Entry]) -> [UInt8] {
            let requested = entries.compactMap(\.request)
            var chosen = search.indices(of: requested, in: screenClut).makeIterator()
            return entries.map { e in
                switch e {
                case .request: return chosen.next()!
                case .overridden(_, let i): _ = chosen.next(); return i   // searched, then the store overwritten
                case .index(let i): return i
                }
            }
        }
        func resolve(_ requests: [RGB16]) -> [UInt8] { search.indices(of: requests, in: screenClut) }

        screenClutId = screenClut.id
        model = search.model
        tint = (0..<TableRequests.tintCount).map { resolve(TableRequests.tint($0, clut: workingClut, random: random)) }
        water = (0..<TableRequests.waterCount).map { resolve(TableRequests.water($0, clut: workingClut)) }
        reddenA = (0..<8).map { resolve(TableRequests.reddenA($0, clut: workingClut)) }
        reddenB = (0..<16).map { resolve(TableRequests.reddenB($0, clut: workingClut)) }
        var pairs: [TableRequests.Pair: [UInt8]] = [:]
        for p in TableRequests.Pair.allCases { pairs[p] = resolve(TableRequests.pair(p, clut: workingClut)) }
        self.pairs = pairs
        greyPull = resolve(TableRequests.greyPullTable(clut: workingClut))
        ambient = (0..<TableRequests.darknessLevels).map { resolve(TableRequests.ambient(darkness: $0, clut: levelBaseClut)) }
        var light: [RGB16] = []
        light.reserveCapacity(TableRequests.darknessLevels * TableRequests.lightGroups * TableRequests.lightIntensities * 256)
        for D in 0..<TableRequests.darknessLevels {
            for g in 0..<TableRequests.lightGroups {
                for k in 0..<TableRequests.lightIntensities {
                    light += TableRequests.light(group: g, intensity: k, darkness: D, clut: levelBaseClut)
                }
            }
        }
        self.light = resolve(light)
    }

    /// The tables for `header`'s level: working copy, lighting source and search CLUT all the level+base CLUT
    /// (`0x285e`, 0 → 202) — see the type doc for the `.AnimateCLUT` levels.
    public static func forLevel(_ header: LevelHeader, resources: FerazelResources, search: ColorSearch,
                                random: (Int16) -> UInt16) throws -> LevelTables {
        let base = try ColorLUT.load(id: ColorLUT.screenClutId(header), from: resources, chain: .level)
        return LevelTables(workingClut: base, levelBaseClut: base, screenClut: base, search: search, random: random)
    }

    /// `pairs[p]` (every case is built).
    public func pair(_ p: TableRequests.Pair) -> [UInt8] {
        pairs[p]!
    }
}
