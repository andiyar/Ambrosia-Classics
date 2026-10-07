import Foundation
import FerazelCore
import HectorResources
import HectorGraphics
import HectorAudio

/// `ferazel-census` — the Phase 0 data census of Ferazel's Wand 1.0.3 (plan docs/plans/2026-10-06-ferazel-phase1.md,
/// Task C6; DECISIONS D26). Framework-free: the executable (`Sources/ferazel-census`) is a thin `main` that prints
/// `render(dataDirectory:)` and, for `--render`, writes `renderFrames(dataDirectory:)` as PNGs (plan invariant 1).
///
///     ferazel-census <Resources/Ferazel dir> [--render <out dir>]
///
/// Markdown on stdout (`docs/ferazel/data-census.md` is this output verbatim below its rule), file and resource
/// NAMES only, never machine paths. Exit 0 when everything decoded, 1 on any failure (each named on its line),
/// 2 on bad arguments.
public enum FerazelCensus {

    // MARK: - Arguments

    /// The command line, parsed (`main` exits 2 when this is nil or the data directory is not a directory).
    public struct Arguments: Equatable, Sendable {
        public var dataDirectory: String
        public var renderDirectory: String?

        public init(dataDirectory: String, renderDirectory: String?) {
            self.dataDirectory = dataDirectory
            self.renderDirectory = renderDirectory
        }

        /// `<dir>` or `<dir> --render <out dir>`; anything else is nil.
        public init?(parsing args: [String]) {
            if args.count == 1, !args[0].isEmpty {
                self.init(dataDirectory: args[0], renderDirectory: nil)
            } else if args.count == 3, !args[0].isEmpty, args[1] == "--render", !args[2].isEmpty {
                self.init(dataDirectory: args[0], renderDirectory: args[2])
            } else {
                return nil
            }
        }
    }

    public static let usage = "usage: ferazel-census <Resources/Ferazel dir> [--render <out dir>]\n"

    // MARK: - The census

    /// The six resource files in census order: (short name, file name).
    static let files: [(short: String, name: String)] = [
        ("app", FerazelData.appFile), ("World Data", FerazelData.worldFile),
        ("Backgrounds", FerazelData.backgroundsFile), ("Sprites", FerazelData.spritesFile),
        ("Sounds", FerazelData.soundsFile), ("Titles", FerazelData.titlesFile),
    ]

    /// The music tracks are numbered 01..30 (world-data §1; 21 and 27 are absent from the shipped game).
    static let musicRange = 1...30

    /// The whole census as Markdown, and the number of failures (0 = every file opened, every item decoded, every
    /// measurement made). Never throws: a failure is a line.
    public static func render(dataDirectory: URL) -> (stdout: String, failures: Int) {
        var out = Output()
        var failures = 0
        let dir = dataDirectory.resolvingSymlinksInPath()
        func describe(_ error: Error) -> String {
            String(describing: error).replacingOccurrences(of: dir.path, with: "…").replacingOccurrences(of: "|", with: "\\|")
        }
        out.line("# Ferazel's Wand 1.0.3 — data census")
        out.line("")

        // 1. Files.
        let musicDir = dir.appendingPathComponent(FerazelData.musicFolder, isDirectory: true).resolvingSymlinksInPath()
        let tracks = (try? MusicTrack.trackNumbers(in: musicDir)) ?? []
        var fileRows: [String] = []
        var bytes = 0, present = 0, rsrcPresent = 0
        var collections: [ResourceCollection] = []
        for f in files {
            let url = dir.appendingPathComponent(f.name).resolvingSymlinksInPath()
            guard let size = fileSize(url) else {
                fileRows.append(row([f.name, "–", "FAIL: missing"]))
                failures += 1
                collections.append(ResourceCollection())
                continue
            }
            bytes += size
            present += 1
            rsrcPresent += 1
            do {
                let data = try Data(contentsOf: url)
                guard ClassicResourceMap.sniff(data) else { throw FerazelDataError.missing("\(f.name) (not a resource map)") }
                collections.append(try ClassicResourceMap.parse(data))
                fileRows.append(row([f.name, grouped(size), "ok"]))
            } catch {
                collections.append(ResourceCollection())
                fileRows.append(row([f.name, grouped(size), "FAIL: \(describe(error))"]))
                failures += 1
            }
        }
        if !isDirectory(musicDir) {
            fileRows.append(row([FerazelData.musicFolder, "–", "FAIL: missing"]))
            failures += 1
        }
        for n in tracks {
            let name = MusicTrack.fileName(n)
            let size = fileSize(musicDir.appendingPathComponent(name)) ?? 0
            bytes += size
            present += 1
            fileRows.append(row(["\(FerazelData.musicFolder)/\(name)", grouped(size), "ok"]))
        }
        let absent = musicRange.filter { !tracks.contains($0) }.map(MusicTrack.fileName)
        out.line("## 1. Files")
        out.line("")
        out.line("files \(present) · resource files \(rsrcPresent)"
                 + " · music \(tracks.count) of \(musicRange.count)"
                 + (absent.isEmpty ? "" : " (\(absent.joined(separator: ", ")) absent)") + " · bytes \(grouped(bytes))")
        out.line("")
        out.line(row(["file", "bytes", "result"]))
        out.line("|---|---:|---|")
        fileRows.forEach { out.line($0) }
        out.line("")

        let resources = FerazelResources(app: collections[0], world: collections[1], backgrounds: collections[2],
                                         sprites: collections[3], sounds: collections[4], titles: collections[5],
                                         musicDirectory: musicDir)

        // 2. Resources per file.
        out.line("## 2. Resources per file")
        out.line("")
        out.line("resources " + files.indices.map { "\(files[$0].short) \(collections[$0].count)/\(collections[$0].types().count)" }
            .joined(separator: " · "))
        out.line("")
        out.line(row(["file", "type", "count", "ids"]))
        out.line("|---|---|---:|---|")
        for (i, c) in collections.enumerated() {
            for type in c.types().sorted() {
                let ids = c.resources(of: type).map(\.id)
                out.line(row([files[i].short, cell(type), "\(ids.count)", "\(ids.min()!)..\(ids.max()!)"]))
            }
        }
        out.line("")

        // 3. Items: one line per decoded item; the per-kind summaries first.
        var items: [String] = []
        var itemFailures = 0
        func item(_ kind: String, _ file: String, _ id: String, _ name: String?, _ body: () throws -> String) {
            do {
                items.append(row([kind, file, id, cell(name), try body(), "ok"]))
            } catch {
                items.append(row([kind, file, id, cell(name), "–", "FAIL: \(describe(error))"]))
                itemFailures += 1
            }
        }
        var summaries: [String] = []

        // PICT.
        var pictDims: [String: [Int16: (Int, Int)]] = [:]
        var indexedDepths: [Int: Int] = [:], directKinds: [[Int]: Int] = [:], v1Depths: [Int: Int] = [:]
        var v2 = 0, pictCount = 0, pictFailures = 0
        for (i, c) in collections.enumerated() {
            for r in c.resources(of: "PICT").sorted(by: { $0.id < $1.id }) {
                pictCount += 1
                let before = itemFailures
                item("PICT", files[i].short, "\(r.id)", r.name) {
                    let p = try PictureSource(resource: r)
                    pictDims[files[i].short, default: [:]][r.id] = (p.width, p.height)
                    let kind: String
                    switch p.pixels {
                    case .indexed(let x) where x.version == 1:
                        v1Depths[x.depth, default: 0] += 1
                        kind = "v1 \(x.depth)-bit"
                    case .indexed(let x):
                        v2 += 1
                        indexedDepths[x.depth, default: 0] += 1
                        kind = "v2 indexed \(x.depth)-bit"
                    case .direct(let x):
                        v2 += 1
                        directKinds[[x.depth, x.transferMode], default: 0] += 1
                        kind = "v2 direct \(x.depth)-bit mode \(x.transferMode)"
                    }
                    return "\(p.width)×\(p.height) · \(kind)"
                }
                pictFailures += itemFailures - before
            }
        }
        let indexedPart = indexedDepths.keys.sorted(by: >).enumerated().map { n, d in
            (n == 0 ? "indexed " : "") + "\(d)-bit \(indexedDepths[d]!)"
        }
        let directPart = directKinds.keys.sorted { $0.lexicographicallyPrecedes($1) }
            .map { "direct \($0[0])-bit \(directKinds[$0]!) mode \($0[1])" }
        let v1Part = v1Depths.keys.sorted(by: >).map { "v1 \($0)-bit \(v1Depths[$0]!)" }
        summaries.append((["PICT \(pictCount)", "v2 \(v2) (" + (indexedPart + directPart).joined(separator: " · ") + ")"]
                          + v1Part + ["failures \(pictFailures)"]).joined(separator: " · "))

        // clut.
        var clutsById: [Int16: [Data]] = [:]
        var clutPerFile: [(String, Int)] = []
        var clutCount = 0, clutEntriesOK = true
        let base200 = try? ColorLUT.load(id: 200, from: resources, chain: .level)
        var plusBase = Set<Int16>()
        for (i, c) in collections.enumerated() {
            let list = c.resources(of: "clut").sorted(by: { $0.id < $1.id })
            if !list.isEmpty { clutPerFile.append((files[i].short, list.count)) }
            for r in list {
                clutCount += 1
                clutsById[r.id, default: []].append(r.data)
                item("clut", files[i].short, "\(r.id)", r.name) {
                    let lut = try ColorLUT(resource: r)
                    if lut.entries.count != ColorLUT.entryCount { clutEntriesOK = false }
                    var detail = "\(lut.entries.count) entries"
                    if let b = base200, r.id != 200, lut.entries[0...0x9f].elementsEqual(b.entries[0...0x9f]) {
                        plusBase.insert(r.id)
                        detail += " · 0x00..0x9f = clut 200"
                    }
                    return detail
                }
            }
        }
        let dups = clutsById.values.filter { $0.count > 1 }
        let dupIdentical = dups.filter { Set($0).count == 1 }.count
        summaries.append((["clut \(clutCount)"] + clutPerFile.map { "\($0.0) \($0.1)" }
                          + [clutEntriesOK ? "256 entries each" : "entry counts vary",
                             "duplicate ids identical \(dupIdentical)" + (dupIdentical == dups.count ? "" : " (differing \(dups.count - dupIdentical))"),
                             "+ base \(plusBase.count) (0x00..0x9f = clut 200)"]).joined(separator: " · "))

        // snd.
        var sndCount = 0, sndSamples = 0
        var sndFormats: [Int: Int] = [:], sndRates: [Double: Int] = [:]
        for (i, c) in collections.enumerated() {
            for r in c.resources(of: "snd ").sorted(by: { $0.id < $1.id }) {
                sndCount += 1
                item("snd", files[i].short, "\(r.id)", r.name) {
                    let s = try SoundBank.decode(r)
                    sndFormats[s.format, default: 0] += 1
                    sndRates[s.pcm.sampleRate, default: 0] += 1
                    sndSamples += s.pcm.frames * s.pcm.channels
                    return "format \(s.format) · \(rate(s.pcm.sampleRate)) Hz · \(grouped(s.pcm.frames)) frames"
                }
            }
        }
        summaries.append((["snd \(sndCount)"] + sndFormats.keys.sorted().map { "format \($0)" + (sndFormats.count > 1 ? " \(sndFormats[$0]!)" : "") }
                          + sndRates.keys.sorted { sndRates[$0]! != sndRates[$1]! ? sndRates[$0]! > sndRates[$1]! : $0 < $1 }
                            .map { "\(rate($0)) Hz \(sndRates[$0]!)" }
                          + ["samples \(grouped(sndSamples))"]).joined(separator: " · "))

        // Music.
        var musicKinds: [String: Int] = [:]
        var packets = 0, frames = 0
        for n in tracks {
            item("music", FerazelData.musicFolder, MusicTrack.fileName(n), nil) {
                let t = try MusicTrack(number: n, in: musicDir)
                let pcm = try t.decode()
                let kind = "\(t.audio.form.rawValue) \(encodingName(t.encoding)) \(channelName(t.channels)) \(rate(t.sampleRate)) Hz"
                musicKinds[kind, default: 0] += 1
                packets += t.packetCount
                frames += pcm.frames
                return "\(kind) · packets \(grouped(t.packetCount)) · frames \(grouped(pcm.frames))"
            }
        }
        summaries.append((["music \(tracks.count)"]
                          + musicKinds.keys.sorted().map { musicKinds.count > 1 ? "\($0) \(musicKinds[$0]!)" : $0 }
                          + ["packets \(grouped(packets))", "frames \(grouped(frames))"]).joined(separator: " · "))

        // Mlvl.
        var levels: [LevelFile] = []
        var active = 0, flag0Typed = 0
        var types = Set<Int16>(), unmapped = Set<Int16>()
        var otherFlags: [UInt8: Int] = [:], classes: [String: Int] = [:]
        for r in resources.world.resources(of: "Mlvl").sorted(by: { $0.id < $1.id }) {
            item("Mlvl", "World Data", "\(r.id)", r.name) {
                let l = try LevelFile(resource: r)
                levels.append(l)
                for p in l.placements {
                    switch p.flag {
                    case 1:
                        active += 1
                        types.insert(p.type)
                        if let found = SpriteClassTable.classify(type: p.type, p1Negative: p.p1 < 0) {
                            let raw = found.0.rawValue
                            classes[raw.prefix(1).uppercased() + raw.dropFirst(), default: 0] += 1
                        } else {
                            unmapped.insert(p.type)
                        }
                    case 0:
                        if p.type != 0 { flag0Typed += 1 }
                    default:
                        otherFlags[p.flag, default: 0] += 1
                    }
                }
                return "\(l.header.gridWidth)×\(l.header.gridHeight) · active \(l.activePlacements.count) · "
                    + "CLUT \(TileSets.levelClutId(l.header))/\(ColorLUT.screenClutId(l.header))"
            }
        }
        summaries.append((["Mlvl \(levels.count)", "active records \(grouped(active))", "placed types \(types.count)",
                           "flag-0 typed \(flag0Typed)"]
                          + (otherFlags.isEmpty ? ["other flags 0"] : otherFlags.keys.sorted().map { "flag \($0) \(otherFlags[$0]!)" })
                          + ["unmapped types \(unmapped.count)"]).joined(separator: " · "))
        summaries.append("classes " + classes.keys.sorted { classes[$0]! != classes[$1]! ? classes[$0]! > classes[$1]! : $0 < $1 }
            .map { "\($0) \(classes[$0]!)" }.joined(separator: " · "))

        // Mcnv.
        var convs = 0, convLines = 0, convText = 0, convPortrait = 0
        for r in resources.world.resources(of: "Mcnv").sorted(by: { $0.id < $1.id }) {
            item("Mcnv", "World Data", "\(r.id)", r.name) {
                let c = try Conversation(id: r.id, data: r.data)
                convs += 1
                convLines += c.lines.count
                let text = c.lines.filter { !$0.text.isEmpty }.count, portrait = c.lines.filter { $0.portrait != 0 }.count
                convText += text
                convPortrait += portrait
                return "lines \(c.lines.count) · text \(text) · portrait \(portrait)"
            }
        }

        // Mwld, Mmap.
        var worldName = "?", worldStamp = "?", mapNodes = "?"
        let mwld = resources.world.resources(of: "Mwld").sorted(by: { $0.id < $1.id })
        if mwld.isEmpty { item("Mwld", "World Data", "0", nil) { throw WorldDataError.missing(type: "Mwld", id: 0) } }
        for r in mwld {
            item("Mwld", "World Data", "\(r.id)", r.name) {
                let w = try WorldFile(id: r.id, data: r.data)
                if r.id == 0 { worldName = w.name; worldStamp = hex32(w.stamp) }
                return "\(w.name) · stamp \(hex32(w.stamp)) · start level \(w.startLevel)"
            }
        }
        let mmap = resources.world.resources(of: "Mmap").sorted(by: { $0.id < $1.id })
        if mmap.isEmpty { item("Mmap", "World Data", "200", nil) { throw WorldDataError.missing(type: "Mmap", id: 200) } }
        for r in mmap {
            item("Mmap", "World Data", "\(r.id)", r.name) {
                let m = try WorldMap(id: r.id, data: r.data)
                if r.id == 200 { mapNodes = "\(m.nodes.count)" }
                return "nodes \(m.nodes.count)"
            }
        }

        // STR#.
        var worldStrings: [(Int16, Int)] = []
        for (i, c) in collections.enumerated() {
            for r in c.resources(of: "STR#").sorted(by: { $0.id < $1.id }) {
                item("STR#", files[i].short, "\(r.id)", r.name) {
                    let s = try StringList(id: r.id, data: r.data)
                    if i == 1 { worldStrings.append((r.id, s.strings.count)) }
                    return "strings \(s.strings.count)"
                }
            }
        }
        summaries.append((["world Mwld \(worldName) \(worldStamp)", "Mmap nodes \(mapNodes)",
                           "Mcnv \(convs) (lines \(convLines), text \(convText), portrait \(convPortrait))"]
                          + worldStrings.sorted { $0.0 > $1.0 }.map { "STR# \($0.0) \($0.1)" }).joined(separator: " · "))

        failures += itemFailures
        out.line("## 3. Items (one line each)")
        out.line("")
        summaries.forEach { out.line($0) }
        out.line("")
        out.line(row(["type", "file", "id", "name", "decoded", "result"]))
        out.line("|---|---|---:|---|---|---|")
        items.forEach { out.line($0) }
        out.line("")

        // 4. Color2Index per level CLUT.
        out.line("## 4. Color2Index: ruled vs exact-nearest per level CLUT")
        out.line("")
        do {
            let ids = Array(Set(levels.map { ColorLUT.screenClutId($0.header) })).sorted()
            guard !ids.isEmpty else { throw FerazelDataError.missing("Mlvl (no level names a CLUT)") }
            let exact = ColorSearch(model: .exactNearest), ruled = ColorSearch(model: .ruled)
            var rows: [String] = [], c202: String?
            var totalDiffer = 0, totalRequests = 0
            for id in ids {
                let c = try ColorLUT.load(id: id, from: resources, chain: .level)
                var parts: [String] = []
                var d = 0, n = 0
                for (name, tables) in censusGroups(c) {
                    let rq = tables.flatMap { $0 }
                    let gd = zip(exact.indices(of: rq, in: c), ruled.indices(of: rq, in: c)).filter { $0 != $1 }.count
                    parts.append("\(name) \(gd)/\(rq.count)")
                    d += gd
                    n += rq.count
                }
                rows.append(row(["\(id)", cell(c.name), grouped(d), grouped(n)]))
                if id == 202 { c202 = "color2index CLUT 202 ruled vs exact: " + parts.joined(separator: " · ") + " · total \(d)/\(n)" }
                totalDiffer += d
                totalRequests += n
            }
            out.line(row(["clut", "name", "ruled ≠ exact", "requests"]))
            out.line("|---:|---|---:|---:|")
            rows.forEach { out.line($0) }
            out.line("")
            if let c202 { out.line(c202) } else { out.line("color2index CLUT 202: FAIL — no level uses it"); failures += 1 }
            out.line("color2index \(ids.count) level CLUTs: \(grouped(totalDiffer)) of \(grouped(totalRequests)) requests differ")
        } catch {
            out.line("color2index: FAIL — \(describe(error))")
            failures += 1
        }
        out.line("")

        // 5. Phase-1 face conversion exposure + short sheets.
        out.line("## 5. Phase-1 face conversion exposure (level 1, ruled vs exact-nearest)")
        out.line("")
        do {
            guard let l1 = levels.first(where: { $0.id == 1 }) else { throw WorldDataError.missing(type: "Mlvl", id: 1) }
            let cl = TileSets.ConversionCLUTs.forLevel(l1.header), ids = TileSets.Ids.forLevel(l1.header)
            let sheets: [(String, Int16, Int16, ResourceChain)] = [
                ("FG", ids.fg, cl.fg, .level), ("BG", ids.bg, cl.bg, .level), ("pattern", ids.pattern, cl.pattern, .level),
                ("PxBack", ids.pxBack, cl.pxBack, .level), ("walk", 1020, 200, .frontEnd),
            ]
            var parts: [String] = []
            out.line(row(["sheet", "PICT", "conversion clut", "colours", "exact in clut", "ruled ≠ exact", "pixels"]))
            out.line("|---|---:|---:|---:|---:|---:|---:|")
            for (label, pict, clutId, chain) in sheets {
                let c = try ColorLUT.load(id: clutId, from: resources, chain: .level)
                let source = try PictureSource.load(id: pict, from: resources, chain: chain)
                guard let colours = try ConvertedPicture.sourceColors(source) else {
                    throw PictureSourceError.unsupported(id: pict, "1-bit BitMap has no colours to search")
                }
                let exactSet = Set(c.entries.map(RGB16.init))
                let ruled = ColorSearch(model: .ruled).prepared(for: c), exact = ColorSearch(model: .exactNearest).prepared(for: c)
                let differing = colours.filter { ruled.index(of: $0.key) != exact.index(of: $0.key) }
                let px = differing.values.reduce(0, +)
                out.line(row([label, "\(pict)", "\(clutId)", "\(colours.count)", "\(colours.keys.filter(exactSet.contains).count)",
                               "\(differing.count)", grouped(px)]))
                parts.append("\(label) \(pict) \(differing.count)/\(colours.count)" + (label == "FG" ? " colours" : "")
                             + (px > 0 ? " \(grouped(px)) px" : ""))
            }
            out.line("")
            out.line("faces level 1 ruled vs exact: " + parts.joined(separator: " · "))
        } catch {
            out.line("faces: FAIL — \(describe(error))")
            failures += 1
        }
        for line in shortSheets(levels: levels, collections: collections, pictDims: pictDims) { out.line(line) }
        out.line("")

        // 6. Totals.
        out.line("## 6. Totals")
        out.line("")
        out.line("Totals: items \(grouped(items.count - itemFailures)) decoded, failures \(failures)")
        return (out.text, failures)
    }

    // MARK: - Measurements

    /// The C4 measurement groups (plan Research note 9, p14): the 16 computed tints, 5 computed waters, 24 redden,
    /// 16 ambient, the pairs 0154/015c/0158 — as `ColorSearchTests` measures them.
    static func censusGroups(_ c: ColorLUT) -> [(String, [[RGB16]])] {
        let noRandom: (Int16) -> UInt16 = { _ in 0 }
        return [
            ("tint", TableRequests.computedTints.map { TableRequests.tint($0, clut: c, random: noRandom).compactMap(\.request) }),
            ("water", TableRequests.computedWaters.map { TableRequests.water($0, clut: c).compactMap(\.request) }),
            ("redden", (0..<8).map { TableRequests.reddenA($0, clut: c).compactMap(\.request) }
                + (0..<16).map { TableRequests.reddenB($0, clut: c).compactMap(\.request) }),
            ("ambient", (0..<TableRequests.darknessLevels).map { TableRequests.ambient(darkness: $0, clut: c) }),
            ("pairs", [TableRequests.Pair.quarterSprite, .average, .threeQuarterSprite].map { TableRequests.pair($0, clut: c) }),
        ]
    }

    /// Every sheet a loader cuts with cells past its picture frame (design §11): the 24 levels' tile sets (PxBack,
    /// PxMid image + mask, BG, FG, pattern), the fixed sets 183/185 and the 29 player sheets.
    static func shortSheets(levels: [LevelFile], collections: [ResourceCollection],
                            pictDims: [String: [Int16: (Int, Int)]]) -> [String] {
        var grids: [FaceSheet.Arguments] = [TileSets.Fixed.waterMaskArguments, TileSets.Fixed.blendArguments]
        for case .set(let a) in FaceSheet.playerSheets { grids.append(a) }
        for l in levels {
            let ids = TileSets.Ids.forLevel(l.header)
            grids.append(TileSets.pxBackArguments(pict: ids.pxBack))
            if ids.pxMid != 0 {
                grids.append(TileSets.pxMidArguments(pict: ids.pxMid))
                grids.append(TileSets.pxMidArguments(pict: ids.pxMid + 1))
            }
            grids += [TileSets.tileArguments(pict: ids.bg), TileSets.tileArguments(pict: ids.fg),
                      TileSets.patternArguments(pict: ids.pattern)]
        }
        var seen = Set<FaceSheet.Arguments>(), lines: [String] = []
        for a in grids where seen.insert(a).inserted {
            // The `.level` search order: World, Backgrounds, Sprites, Sounds, Titles, app (`ResourceChain`).
            guard let holder = [1, 2, 3, 4, 5, 0].first(where: { collections[$0].resource(type: "PICT", id: a.pict) != nil }),
                  let dims = pictDims[files[holder].short]?[a.pict] else { continue }
            let (w, h) = dims
            var short: [(Int, Int)] = []
            for i in 0..<a.count {
                let r = a.rect(ofCell: i)
                let rows = max(0, Int(r.bottom) - max(h, Int(r.top)))
                if rows > 0 { short.append((i, rows)) }
            }
            guard let first = short.first, let last = short.last else { continue }
            let cells = short.count == last.0 - first.0 + 1 ? "\(first.0)..\(last.0)" : short.map { "\($0.0)" }.joined(separator: ",")
            let rows = Set(short.map(\.1)).sorted().map(String.init).joined(separator: "/")
            lines.append("short sheet PICT \(a.pict) \(w)×\(h) (cells \(cells), \(rows) rows)")
        }
        return lines
    }

    // MARK: - --render (indexed frames; the executable writes them as PNGs)

    /// One picture for `--render`: indices and the CLUT to show them through.
    public struct Frame: Sendable {
        public let name: String
        public let width: Int
        public let height: Int
        public let indices: [UInt8]
        public let clut: ColorLUT
    }

    /// `level1-start.png` — what Phase 0 can draw of the level-1 start window: the 640×416 play area at scroll
    /// (0, 10) (plan Research note 16, the converged target [MED]), BG then FG tile faces placed by cell (index 0
    /// transparent, as the encoded faces skip it), shown through the level+base CLUT 202. No pattern cells, blend, overlay, parallax, lighting,
    /// water or sprites (R1–R6); empty pixels show index 0xff. `pict-1020.png` — the walk sheet under the sprite
    /// CLUT 200; `pict-207.png` — PxBack 207 under the level CLUT 201. All `.ruled`, `.errorDiffusion`.
    public static func renderFrames(dataDirectory: URL) throws -> [Frame] {
        let r = try FerazelData.open(dataDirectory)
        let search = ColorSearch(model: .ruled)
        func convert(_ id: Int16, _ clutId: Int16, _ chain: ResourceChain) throws -> (ConvertedPicture, ColorLUT) {
            let c = try ColorLUT.load(id: clutId, from: r, chain: .level)
            return (try ConvertedPicture(source: try PictureSource.load(id: id, from: r, chain: chain), clut: c, search: search), c)
        }
        let l1 = try LevelFile.load(from: r, level: 1)
        let ids = TileSets.Ids.forLevel(l1.header), cl = TileSets.ConversionCLUTs.forLevel(l1.header)
        let (bg, _) = try convert(ids.bg, cl.bg, .level)
        let (fg, _) = try convert(ids.fg, cl.fg, .level)
        let screen = try ColorLUT.load(id: ColorLUT.screenClutId(l1.header), from: r, chain: .level)
        let (w, h, scrollX, scrollY) = (640, 416, 0, 10)
        var px = [UInt8](repeating: 0xff, count: w * h)
        for y in 0..<h {
            for x in 0..<w {
                let wx = x + scrollX, wy = y + scrollY
                let col = wx / 32, row = wy / 32
                func tilePixel(_ sheet: ConvertedPicture, _ tile: Int) -> UInt8 {
                    sheet.pixel(x: (tile % 8) * 32 + wx % 32, y: (tile / 8) * 32 + wy % 32)
                }
                let b = l1.bgTile(col: col, row: row)
                if b >= 0 {
                    let v = tilePixel(bg, b)
                    if v != 0 { px[y * w + x] = v }
                }
                let f = l1.fgTile(col: col, row: row)
                if f >= 0, f < 95 {
                    let v = tilePixel(fg, f)
                    if v != 0 { px[y * w + x] = v }
                }
            }
        }
        let (walk, c200) = try convert(1020, 200, .frontEnd)
        let (pxBack, c201) = try convert(207, 201, .level)
        return [
            Frame(name: "level1-start.png", width: w, height: h, indices: px, clut: screen),
            Frame(name: "pict-1020.png", width: walk.width, height: walk.height, indices: walk.pixels, clut: c200),
            Frame(name: "pict-207.png", width: pxBack.width, height: pxBack.height, indices: pxBack.pixels, clut: c201),
        ]
    }

    // MARK: - Helpers

    struct Output {
        var text = ""
        mutating func line(_ s: String) { text += s; text += "\n" }
    }

    static func row(_ cells: [String]) -> String { "| " + cells.joined(separator: " | ") + " |" }

    /// A Markdown-safe table cell (`—` for none).
    static func cell(_ s: String?) -> String {
        guard let s, !s.isEmpty else { return "—" }
        return s.replacingOccurrences(of: "|", with: "\\|").replacingOccurrences(of: "\r", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
    }

    /// `1234567` → `1,234,567` (locale-free).
    static func grouped(_ n: Int) -> String {
        let digits = String(abs(n))
        var out = ""
        for (i, c) in digits.enumerated() {
            if i > 0 && (digits.count - i) % 3 == 0 { out.append(",") }
            out.append(c)
        }
        return (n < 0 ? "-" : "") + out
    }

    /// Whole rates as integers, the rest to 3 decimals (locale-free).
    static func rate(_ r: Double) -> String {
        if r == r.rounded() { return String(Int(r)) }
        let milli = Int((r * 1000).rounded())
        let frac = String(milli % 1000)
        return "\(milli / 1000)." + String(repeating: "0", count: 3 - frac.count) + frac
    }

    static func hex32(_ v: UInt32) -> String {
        let s = String(v, radix: 16)
        return "0x" + String(repeating: "0", count: 8 - s.count) + s
    }

    static func encodingName(_ e: AIFFAudio.Encoding) -> String {
        switch e {
        case .ima4: return "ima4"
        case .pcm(let bits): return "PCM \(bits)-bit"
        }
    }

    static func channelName(_ n: Int) -> String {
        switch n {
        case 1: return "mono"
        case 2: return "stereo"
        default: return "\(n) channels"
        }
    }

    static func fileSize(_ url: URL) -> Int? {
        let resolved = url.resolvingSymlinksInPath()
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: resolved.path),
              attrs[.type] as? FileAttributeType == .typeRegular else { return nil }
        return (attrs[.size] as? NSNumber)?.intValue
    }

    static func isDirectory(_ url: URL) -> Bool {
        var isDir: ObjCBool = false
        return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) && isDir.boolValue
    }
}
