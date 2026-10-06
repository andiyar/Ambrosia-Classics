import DeimosCore
import Foundation
import HectorAudio
import HectorResources
#if canImport(ImageIO)
import CoreGraphics
import ImageIO
#endif

/// deimos-census — Phase 0 data census of Deimos Rising 1.0.6 (plan
/// docs/plans/2026-10-06-deimos-phase0-data.md, Task C7).
///
///     deimos-census <Data dir> [--render <out dir>]
///
/// Prints Markdown on stdout (docs/deimos/data-census.md is this output verbatim below its rule) and
/// exits 0 when every entry decoded, 1 on any failure, 2 on bad arguments. Prints entry NAMES only,
/// never machine paths. `--render` additionally writes five PNGs for eyes-only checks (ImageIO, the
/// only Apple framework here, census-only — plan invariant 2).
@main
enum DeimosCensus {
    static func main() {
        let args = Array(CommandLine.arguments.dropFirst())
        let usage = "usage: deimos-census <Data dir> [--render <out dir>]\n"
        var isDirectory: ObjCBool = false
        guard args.count == 1 || (args.count == 3 && args[1] == "--render"),
              FileManager.default.fileExists(atPath: args[0], isDirectory: &isDirectory), isDirectory.boolValue else {
            FileHandle.standardError.write(Data(usage.utf8))
            exit(2)
        }
        let dataDirectory = URL(fileURLWithPath: args[0], isDirectory: true)
        let census = render(dataDirectory: dataDirectory)
        FileHandle.standardOutput.write(Data(census.stdout.utf8))
        var failed = census.failures > 0
        if args.count == 3 {
            #if canImport(ImageIO)
            do {
                _ = try renderImages(dataDirectory: dataDirectory, to: URL(fileURLWithPath: args[2], isDirectory: true))
            } catch {
                FileHandle.standardError.write(Data("deimos-census: --render failed: \(error)\n".utf8))
                failed = true
            }
            #else
            FileHandle.standardError.write(Data("deimos-census: --render needs ImageIO (macOS)\n".utf8))
            failed = true
            #endif
        }
        exit(failed ? 1 : 0)
    }

    // MARK: - The census

    static let im08 = FourCC("im08")!, im16 = FourCC("im16")!, soun = FourCC("soun")!, film = FourCC("film")!
    static let unde = FourCC("unde")!, plde = FourCC("plde")!, wede = FourCC("wede")!, leve = FourCC("leve")!
    static let stli = FourCC("stli")!, flli = FourCC("flli")!, idli = FourCC("idli")!, reli = FourCC("reli")!
    static let coli = FourCC("coli")!, tefo = FourCC("tefo")!
    static let textTypes: Set<FourCC> = [stli, flli, idli, reli, coli, tefo, plde, unde, leve, wede]

    /// The whole census as Markdown, and the number of failures (0 = every file opened, every CRC
    /// matched, every entry decoded, every sprite group built). Never throws: a failure is a line.
    static func render(dataDirectory: URL) -> (stdout: String, failures: Int) {
        var out = Output()
        var failures = 0
        out.line("# Deimos Rising 1.0.6 — data census")
        out.line("")

        // 1. Files.
        let paksDir = dataDirectory.appendingPathComponent("Paks", isDirectory: true)
        let localDir = dataDirectory.appendingPathComponent("Local", isDirectory: true)
        let pakNames = sortedNames(paksDir).filter { $0.hasSuffix(".pak") || $0.hasSuffix(".zip") }
        var localFiles: [String] = []
        for folder in sortedNames(localDir) {
            for name in sortedNames(localDir.appendingPathComponent(folder)) where !name.contains(".DS_Store") {
                if let size = fileSize(localDir.appendingPathComponent(folder).appendingPathComponent(name)), size > 0 {
                    localFiles.append("\(folder)/\(name)")
                }
            }
        }
        var fileRows: [String] = []
        for rel in pakNames.map({ "Paks/\($0)" }) + localFiles.map({ "Local/\($0)" }) {
            let url = dataDirectory.appendingPathComponent(rel)
            if let data = try? Data(contentsOf: url, options: .mappedIfSafe) {
                fileRows.append(row(["`\(rel)`", grouped(data.count), "`\(SHA256.hex(data))`"]))
            } else {
                fileRows.append(row(["`\(rel)`", "—", "FAIL: unreadable"])); failures += 1
            }
        }

        // 2. Paks: central directory, CRC-32 of every stored entry.
        var pakRows: [String] = [], pakNotes: [String] = [], pakFileCounts: [String] = []
        var crcOK = 0
        for name in pakNames {
            guard let archive = try? StoredZipArchive(contentsOf: paksDir.appendingPathComponent(name)) else {
                pakRows.append(row(["`\(name)`", "FAIL: not a readable stored zip", "", "", ""])); failures += 1
                continue
            }
            let files = archive.entries.filter { !$0.isDirectory }
            var ok = 0
            for e in files {
                guard let bytes = try? archive.data(for: e) else {
                    pakNotes.append("- FAIL: `\(name):\(e.name)` cannot be read (method \(e.method))"); failures += 1
                    continue
                }
                if CRC32.checksum(bytes) == e.crc32 {
                    ok += 1
                } else {
                    pakNotes.append("- FAIL: `\(name):\(e.name)` CRC-32 mismatch"); failures += 1
                }
                if e.flags != 0 { pakNotes.append("- `\(name):\(e.name)`: general-purpose flags \(e.flags) (STORED: ignored)") }
            }
            crcOK += ok
            pakFileCounts.append("\(name) \(files.count)")
            pakRows.append(row(["`\(name)`", "\(archive.entries.count)", "\(files.count)",
                                "\(archive.entries.count - files.count)", "\(ok)"]))
        }
        let filesLine = "files \(fileRows.count) · paks \(pakNames.count) (\(pakFileCounts.joined(separator: " · "))) · "
            + "local \(localFiles.count) · CRC ok \(crcOK)"

        // 3. The tag index.
        let index: TagIndex
        do {
            index = try TagIndex(dataDirectory: dataDirectory)
        } catch {
            out.line(filesLine)
            out.line("")
            out.line("FAIL: the tag index could not be built: \(error)")
            failures += 1
            out.line("")
            out.line("Totals: entries 0 (pak 0 + local 0), decoded 0, failures \(failures)")
            return (out.text, failures)
        }
        var byType: [FourCC: Int] = [:]
        for r in index.records { byType[r.type, default: 0] += 1 }
        let overridden = index.alerts.filter { $0.contains("Tag Overridden") }.count
        // An empty index, or the original's "Tag Index Incomplete!" (fewer than 100 tags), is a failed census.
        var indexFailure: String? = nil
        if index.records.isEmpty || index.alerts.contains(where: { $0.contains("Tag Index Incomplete!") }) {
            indexFailure = "FAIL: the tag index is incomplete (\(index.records.count) records, the original needs "
                + "\(TagIndex.minimumTagCount))"
            failures += 1
        }
        let tagsLine = "tags \(index.records.count) · "
            + byType.sorted { $0.key.description < $1.key.description }.map { "\($0.key) \($0.value)" }
                .joined(separator: " · ")
            + " · overridden \(overridden) · alerts \(index.alerts.count)"

        // 4. Every entry. Decode everything once; the later sections summarise what was decoded here.
        let spriteExists: (FourCC) -> Bool = { index.record(type: im08, id: $0) != nil }
        let unitExists: (FourCC) -> Bool = { index.record(type: unde, id: $0) != nil }
        var entryRows: [String] = []
        var decoded = 0
        var gifs: [FourCC: GIFImage] = [:]
        var tgaSizes: [String: Int] = [:]
        var water = 0
        var effects = (count: 0, mono: 0, packets: 0, frames: 0, rates: Set<Double>(), ima4: 0)
        var music: [(id: FourCC, channels: Int, packets: Int, frames: Int, ima4: Bool)] = []
        var formDeltas: [String] = []
        var text = TextCensus()
        var films: [(id: FourCC, film: Film, isLocal: Bool)] = []
        for r in index.records {
            let pak: String
            switch r.source {
            case .local: pak = "Local"
            case .pak(let a, _): pak = index.paks[a].lastPathComponent
            }
            let name: String
            switch r.source {
            case .local(let url): name = url.deletingLastPathComponent().lastPathComponent + "/" + url.lastPathComponent
            case .pak(_, let entry): name = entry.name
            }
            var result: String
            do {
                let data = try index.data(for: r)
                switch r.type {
                case im08:
                    let gif = try GIFImage(data: data)
                    gifs[r.id] = gif
                    result = "GIF \(gif.width)×\(gif.height)"
                        + (SpriteGroup.alphaPlateID(for: r.id) == r.id ? " · alpha plate" : " · colour plate")
                case im16:
                    let tga = try TGAImage(data: data)
                    tgaSizes["\(tga.width)×\(tga.height)", default: 0] += 1
                    if r.displayName.hasSuffix(" Media") { water += tga.pixels.filter { $0 == 0x001F }.count }
                    result = "TGA \(tga.width)×\(tga.height)"
                case soun:
                    // The game's gate first (`DeimosSound`, which dispatches on the signature: an effect
                    // may be AIFF/AIFC or RIFF/WAVE, music AIFF/AIFC only); the header line after it.
                    let isMusic = pak == "Music.pak"
                    let pcm = try isMusic ? DeimosSound.musicInfo(data).linearPCM() : DeimosSound.effectPCM(data)
                    let packets: Int
                    if !isMusic && DeimosSound.isRIFFWAVE(data) {
                        let wave = try WAVEAudio(data: data)
                        packets = wave.frameCount
                        result = "WAVE PCM \(wave.bitsPerSample)-bit · \(wave.channels) ch · "
                            + "\(grouped(wave.frameCount)) packets · \(grouped(pcm.frames)) frames"
                    } else {
                        let header = try AIFFAudio(data: data)
                        let fileDelta = (data.count - 8) - header.declaredFormSize
                        if fileDelta != 0 { formDeltas.append("`\(r.id)` FORM size \(fileDelta) bytes short of the file") }
                        packets = header.frameCount
                        if isMusic {
                            music.append((r.id, header.channels, header.frameCount, pcm.frames, header.encoding == .ima4))
                        } else if header.encoding == .ima4 {
                            effects.ima4 += 1
                        }
                        result = "\(header.form == .aifc ? "AIFC" : "AIFF") \(encodingName(header.encoding)) · "
                            + "\(header.channels) ch · \(grouped(header.frameCount)) packets · \(grouped(pcm.frames)) frames"
                            + (isMusic ? " · music" : "")
                    }
                    if !isMusic {
                        effects.count += 1
                        if pcm.channels == 1 { effects.mono += 1 }
                        effects.packets += packets
                        effects.frames += pcm.frames
                        effects.rates.insert(pcm.sampleRate)
                    }
                case film:
                    let f = try Film(data: data)
                    films.append((r.id, f, r.isLocal))
                    result = "film \(f.level) · \(f.players[0].frames) ticks · score \(f.players[0].score)"
                default:
                    guard textTypes.contains(r.type) else { throw CensusError.unknownType }
                    result = try text.add(r, raw: [UInt8](data), spriteExists: spriteExists, unitExists: unitExists)
                }
                decoded += 1
            } catch {
                result = "FAIL: \(error)"
                failures += 1
            }
            entryRows.append(row([pak, "\(r.type)", "`\(r.id)`", "`\(name)`", grouped(r.size), result]))
        }

        // 5. Sprite groups: every colour plate with its alpha plate, the original's way.
        var groupRows: [String] = []
        var groupCount = 0, frameCount = 0, mapCount = 0, pixels = 0, blockBytes = 0, maxW = 0, maxH = 0
        for r in index.records(ofType: im08) where SpriteGroup.alphaPlateID(for: r.id) != r.id {
            guard let colour = gifs[r.id] else { continue }        // its decode failure is already counted
            let alphaID = SpriteGroup.alphaPlateID(for: r.id)
            do {
                guard let alpha = gifs[alphaID] else { throw SpriteGroupError.missingPlate(alphaID) }
                let g = try SpriteGroup(colour: colour, alpha: alpha, id: r.id)
                groupCount += 1
                frameCount += g.frames.count
                let maps = g.frames.filter { $0.alphaMap != nil }.count
                mapCount += maps
                pixels += g.frames.reduce(0) { $0 + $1.width * $1.height }
                let bytes = g.frames.reduce(0) { $0 + $1.blockSize }
                blockBytes += bytes
                maxW = max(maxW, g.frames.map(\.width).max() ?? 0)
                maxH = max(maxH, g.frames.map(\.height).max() ?? 0)
                groupRows.append(row(["`\(r.id)`", "\(colour.width)×\(colour.height)", "\(g.frames.count)", "\(maps)",
                                      grouped(bytes)]))
            } catch {
                groupRows.append(row(["`\(r.id)`", "\(colour.width)×\(colour.height)", "FAIL: \(error)", "", ""]))
                failures += 1
            }
        }
        let im08Line = "im08 \(byType[im08] ?? 0) · sprite groups \(groupCount) · frames \(frameCount) "
            + "(alpha maps \(mapCount)) · pixels \(grouped(pixels)) · encoded bytes \(grouped(blockBytes)) · "
            + "max frame \(maxW)×\(maxH)"

        let named = ["480×3600", "96×720", "146×306", "640×480"]
        let otherTGAs = tgaSizes.filter { !named.contains($0.key) }.reduce(0) { $0 + $1.value }
        let im16Line = "im16 \(byType[im16] ?? 0) · " + named.map { "\($0) \(tgaSizes[$0] ?? 0)" }.joined(separator: " · ")
            + " · other \(otherTGAs) · water px \(grouped(water))"

        let rates = effects.rates.sorted().map { $0 == $0.rounded() ? "\(Int($0))" : "\($0)" }.joined(separator: "/")
        let musicChannels = Set(music.map(\.channels))
        let sounLine = "soun \(byType[soun] ?? 0) · effects \(effects.count) "
            + "\(effects.mono == effects.count ? "mono" : "\(effects.mono) mono") "
            + "\(effects.ima4 == effects.count ? "ima4" : "\(effects.ima4) ima4") \(rates) Hz "
            + "(frames \(grouped(effects.frames))) · music \(music.count) "
            + "\(musicChannels == [2] ? "stereo" : "channels \(musicChannels.sorted())") "
            + "\(music.allSatisfy(\.ima4) ? "ima4" : "mixed") "
            + "(packets \(music.map { grouped($0.packets) }.joined(separator: " · ")))"

        let textLine = text.summaryLine(entries: index.records.filter { textTypes.contains($0.type) }.count)

        // The pak demos first, then the Local film (the save slot), each group in index order.
        films = films.filter { !$0.isLocal } + films.filter(\.isLocal)
        let filmLine = "film \(films.count) · version "
            + Set(films.map { Int($0.film.version) }).sorted().map(String.init).joined(separator: "/") + " · "
            + films.map { "\($0.id) \($0.film.level) \($0.film.players[0].frames)" }.joined(separator: " · ")

        // Print.
        out.line("## Summary")
        out.line("")
        out.line("```")
        for l in [filesLine, tagsLine, im08Line, im16Line, sounLine, textLine, filmLine] { out.line(l) }
        out.line("```")
        out.line("")

        out.line("## 1. Files")
        out.line("")
        out.line(row(["file", "bytes", "SHA-256"])); out.line(row(["---", "---:", "---"]))
        fileRows.forEach { out.line($0) }
        out.line("")

        out.line("## 2. Paks (STORED zip: central directory, CRC-32 of every file entry)")
        out.line("")
        out.line(row(["pak", "CD entries", "files", "folders", "CRC ok"])); out.line(row(["---", "---:", "---:", "---:", "---:"]))
        pakRows.forEach { out.line($0) }
        if !pakNotes.isEmpty { out.line(""); pakNotes.forEach { out.line($0) } }
        out.line("")

        out.line("## 3. Tag index (Local, then the paks in name order)")
        out.line("")
        out.line(row(["type", "records", "local"])); out.line(row(["---", "---:", "---:"]))
        for t in TagName.typeOrder {
            let rs = index.records(ofType: t)
            out.line(row(["\(t)", "\(rs.count)", "\(rs.filter(\.isLocal).count)"]))
        }
        out.line(row(["**total**", "**\(index.records.count)**", "**\(index.records.filter(\.isLocal).count)**"]))
        out.line("")
        out.line("Overridden pak records: \(overridden). Alerts: \(index.alerts.count).")
        for a in index.alerts { out.line("- `\(a.trimmingCharacters(in: .whitespacesAndNewlines))`") }
        if let indexFailure { out.line(""); out.line(indexFailure) }
        out.line("")

        out.line("## 4. Every entry (index order)")
        out.line("")
        out.line(row(["pak", "type", "ID", "name", "bytes", "result"]))
        out.line(row(["---", "---", "---", "---", "---:", "---"]))
        entryRows.forEach { out.line($0) }
        out.line("")

        out.line("## 5. Sprite groups (alpha plate scanned on 8-bit system-CLUT indices; frames encoded)")
        out.line("")
        out.line(row(["group", "plate", "frames", "alpha maps", "encoded bytes"]))
        out.line(row(["---", "---", "---:", "---:", "---:"]))
        groupRows.forEach { out.line($0) }
        out.line("")

        out.line("## 6. Text")
        out.line("")
        text.section().forEach { out.line($0) }
        out.line("")

        out.line("## 7. Sound")
        out.line("")
        out.line("- Effects: \(effects.count) (mono \(effects.mono), ima4 \(effects.ima4), \(rates) Hz) · packets "
                 + "\(grouped(effects.packets)) · frames \(grouped(effects.frames)) (the kit's CoreAudio-identical decode)")
        for m in music {
            out.line("- Music `\(m.id)`: \(m.channels) ch · \(grouped(m.packets)) packets · \(grouped(m.frames)) frames")
        }
        out.line("- FORM size ≠ file − 8: " + (formDeltas.isEmpty ? "none" : formDeltas.joined(separator: "; ")))
        out.line("")

        out.line("## 8. Films")
        out.line("")
        out.line(row(["film", "version", "seed", "level", "players", "P1 ticks", "P1 score", "max input", "P2 level",
                      "zero tail"]))
        out.line(row(["---", "---:", "---", "---", "---:", "---:", "---:", "---", "---", "---"]))
        for (id, f, _) in films {
            let maxInput = f.players[0].inputs.max() ?? 0
            out.line(row(["`\(id)`", "\(f.version)", "0x" + String(f.seed, radix: 16), "`\(f.level)`", "\(f.playerCount)",
                          "\(f.players[0].frames)", "\(f.players[0].score)", "0x" + String(maxInput, radix: 16),
                          "`\(f.players[1].level)`", f.trailingBytesAreZero ? "yes" : "no"]))
        }
        out.line("")

        let local = index.records.filter(\.isLocal).count
        out.line("Totals: entries \(index.records.count) (pak \(index.records.count - local) + local \(local)), "
                 + "decoded \(decoded), failures \(failures)")
        return (out.text, failures)
    }

    enum CensusError: Error { case unknownType }

    // MARK: - Text

    /// Per-type text numbers (plan Research note 13) and the token value census (note 12).
    struct TextCensus {
        var stli: [(FourCC, Int)] = [], idli: [(FourCC, Int)] = [], reli: [(FourCC, Int)] = []
        var coli: [(FourCC, [UInt16])] = [], flli: [(FourCC, Int)] = []
        var tefoFormats: [String: Int] = [:], tefoCount = 0
        var plde: [(FourCC, Int)] = [], wede: [(FourCC, Int)] = [], leve: [(FourCC, Int)] = []
        var unde: [UnitDefinition] = []
        var errors = 0
        var ints = 0, floats = 0, boolTrue = 0, boolFalse = 0, colors = 0

        mutating func add(_ r: TagIndex.Record, raw: [UInt8], spriteExists: (FourCC) -> Bool,
                          unitExists: (FourCC) -> Bool) throws -> String {
            let data = Data(raw)
            var errs: [String] = []
            let summary: String
            switch r.type {
            case DeimosCensus.stli:
                let n = StringList(data: data).lines.count; stli.append((r.id, n)); summary = "\(n) lines"
            case DeimosCensus.flli:
                let n = try FloatList(data: data).values.count; flli.append((r.id, n)); summary = "\(n) floats"
            case DeimosCensus.idli:
                let n = try IDList(data: data).items.count; idli.append((r.id, n)); summary = "\(n) IDs"
            case DeimosCensus.reli:
                let n = try RectList(data: data).items.count; reli.append((r.id, n)); summary = "\(n) rects"
            case DeimosCensus.coli:
                let c = try ColorList(data: data).items.map(\.color); coli.append((r.id, c)); summary = "\(c.count) colours"
            case DeimosCensus.tefo:
                let f = TextFormat(data: data, tagName: r.displayName)
                errs = f.errors + f.alerts
                tefoFormats[f.format.rawValue, default: 0] += 1; tefoCount += 1
                summary = "format \(f.format.rawValue) · loc \(f.locX),\(f.locY)"
            case DeimosCensus.plde:
                let (p, e) = PlayerDefinition.parse(id: r.id, text: raw, spriteExists: spriteExists)
                errs = e
                let keys = TokenReader.items(DeimosText.decode(raw)).count
                plde.append((r.id, keys)); summary = "player \"\(p.name)\" · \(keys) keys"
            case DeimosCensus.wede:
                let (w, e) = WeaponDefinition.parse(id: r.id, text: raw, spriteExists: spriteExists)
                errs = e
                wede.append((r.id, w.spawns.count)); summary = "weapon \"\(w.name)\" · \(w.spawns.count) spawns"
            case DeimosCensus.leve:
                let (l, e) = LevelDefinition.parse(id: r.id, text: raw, unitExists: unitExists)
                errs = e
                leve.append((r.id, l.objects.count)); summary = "level \"\(l.name)\" · \(l.objects.count) objects"
            default: // unde
                let (u, e) = UnitDefinition.parse(id: r.id, text: raw, spriteExists: spriteExists, tagName: r.tagName)
                errs = e
                unde.append(u)
                summary = "unit \"\(u.name)\" · \(u.states.count) states"
            }
            valueCensus(r.type, raw)
            errors += errs.count
            if !errs.isEmpty { throw TextError(errors: errs) }
            return summary
        }

        struct TextError: Error, CustomStringConvertible {
            let errors: [String]
            var description: String { "token errors \(errors.joined(separator: ", "))" }
        }

        /// Every `#…_TYPE <…>` item read with its suffix's reader, in file order (the value census).
        mutating func valueCensus(_ type: FourCC, _ raw: [UInt8]) {
            let decoded = (type == DeimosCensus.unde && contains(raw, "#name_STR"))
                || (type == DeimosCensus.wede && contains(raw, "#type_ID")) ? raw : DeimosText.decode(raw)
            var r = TokenReader(decoded)
            for key in TokenReader.itemKeys(decoded) {
                if key.hasSuffix("_INT") {
                    if r.int(key) != nil { ints += 1 }
                } else if key.hasSuffix("_FLOAT") {
                    if r.float(key) != nil { floats += 1 }
                } else if key.hasSuffix("_BOOL") {
                    if let b = r.bool(key) { if b { boolTrue += 1 } else { boolFalse += 1 } }
                } else if key.hasSuffix("_COLOR") || key.hasSuffix("_RGB") {
                    if r.color(key) != nil { colors += 1 }
                } else {
                    _ = r.string(key, maxLength: 0x10000)
                }
            }
        }

        private func contains(_ raw: [UInt8], _ s: String) -> Bool {
            let n = Array(s.utf8)
            guard raw.count >= n.count else { return false }
            return (0...(raw.count - n.count)).contains { i in raw[i..<(i + n.count)].elementsEqual(n) }
        }

        func summaryLine(entries: Int) -> String {
            let states = unde.reduce(0) { $0 + $1.states.count }
            return "text \(entries) · stli \(stli.reduce(0) { $0 + $1.1 }) lines · flli \(flli.reduce(0) { $0 + $1.1 }) · "
                + "idli \(idli.reduce(0) { $0 + $1.1 }) · reli \(reli.reduce(0) { $0 + $1.1 }) · "
                + "coli \(coli.reduce(0) { $0 + $1.1.count }) · tefo \(tefoCount) · plde \(plde.count) · "
                + "wede \(wede.count) (spawns \(wede.reduce(0) { $0 + $1.1 })) · "
                + "leve \(leve.count) (objects \(leve.reduce(0) { $0 + $1.1 })) · "
                + "unde \(unde.count) (states \(grouped(states))) · token errors \(errors)"
        }

        func section() -> [String] {
            func list(_ xs: [(FourCC, Int)]) -> String { xs.map { "`\($0.0)` \($0.1)" }.joined(separator: " · ") }
            func histogram(_ h: [Int: Int]) -> String {
                h.sorted { $0.key < $1.key }.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
            }
            let states = unde.flatMap(\.states)
            var numStates: [Int: Int] = [:], rules: [Int: Int] = [:], spawnSets: [Int: Int] = [:]
            for u in unde { numStates[Int(u.numStates), default: 0] += 1 }
            for s in states { rules[Int(s.numRules), default: 0] += 1; spawnSets[s.spawnSets.count, default: 0] += 1 }
            let order = ["LEFT", "CENT", "RIGH", "CEBU", "CEGA"]
            return [
                "- `stli` lines: " + list(stli),
                "- `flli` floats: " + list(flli),
                "- `idli` IDs: " + list(idli),
                "- `reli` rects: " + list(reli),
                "- `coli` colours: " + coli.map { "`\($0.0)` " + $0.1.map { "0x" + String($0, radix: 16, uppercase: true) }
                    .joined(separator: " ") }.joined(separator: " · "),
                "- `tefo` \(tefoCount), `#Format_ID`: " + order.map { "\($0) \(tefoFormats[$0] ?? 0)" }.joined(separator: " · "),
                "- `plde` keys: " + list(plde),
                "- `wede` spawns (index order): " + list(wede),
                "- `leve` objects (index order): " + list(leve),
                "- `unde` \(unde.count) units · \(grouped(states.count)) states · numStates {\(histogram(numStates))} · "
                    + "numRules {\(histogram(rules))} · spawn sets per state {\(histogram(spawnSets))}",
                "- Token values over all \(stli.count + flli.count + idli.count + reli.count + coli.count + tefoCount + plde.count + wede.count + leve.count + unde.count) "
                    + "text entries: INT \(grouped(ints)) · FLOAT \(grouped(floats)) · BOOL TRUE \(grouped(boolTrue)) / "
                    + "FALSE \(grouped(boolFalse)) · COLOR \(grouped(colors)) · token errors \(errors)",
            ]
        }
    }

    // MARK: - Helpers

    struct Output {
        var text = ""
        mutating func line(_ s: String) { text += s; text += "\n" }
    }

    static func row(_ cells: [String]) -> String { "| " + cells.joined(separator: " | ") + " |" }

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

    static func encodingName(_ e: AIFFAudio.Encoding) -> String {
        switch e {
        case .ima4: return "ima4"
        case .pcm(let bits): return "PCM \(bits)-bit"
        }
    }

    /// Directory entries, case-insensitive then raw order (the TagIndex catalog-order stand-in).
    static func sortedNames(_ dir: URL) -> [String] {
        guard let names = try? FileManager.default.contentsOfDirectory(atPath: dir.path) else { return [] }
        return names.sorted { a, b in
            let la = a.lowercased(), lb = b.lowercased()
            return la != lb ? la < lb : a < b
        }
    }

    static func fileSize(_ url: URL) -> Int? {
        let resolved = url.resolvingSymlinksInPath()
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: resolved.path),
              attrs[.type] as? FileAttributeType == .typeRegular else { return nil }
        return (attrs[.size] as? NSNumber)?.intValue
    }
}

// MARK: - SHA-256 (FIPS 180-4), Foundation-only

enum SHA256 {
    private static let k: [UInt32] = [
        0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
        0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
        0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
        0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
        0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
        0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
        0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
        0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
    ]

    static func hex(_ data: Data) -> String {
        digest(data).map { String(format: "%02x", $0) }.joined()
    }

    static func digest(_ data: Data) -> [UInt8] {
        var h: [UInt32] = [0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19]
        var tail = [UInt8](data.suffix(data.count % 64))
        let bitLength = UInt64(data.count) &* 8
        tail.append(0x80)
        while tail.count % 64 != 56 { tail.append(0) }
        for i in (0..<8).reversed() { tail.append(UInt8(truncatingIfNeeded: bitLength >> (UInt64(i) * 8))) }
        var w = [UInt32](repeating: 0, count: 64)
        func compress(_ p: UnsafeRawBufferPointer, _ at: Int) {
            for t in 0..<16 {
                let o = at + 4 * t
                w[t] = UInt32(p[o]) << 24 | UInt32(p[o + 1]) << 16 | UInt32(p[o + 2]) << 8 | UInt32(p[o + 3])
            }
            for t in 16..<64 {
                let s0 = rotr(w[t - 15], 7) ^ rotr(w[t - 15], 18) ^ (w[t - 15] >> 3)
                let s1 = rotr(w[t - 2], 17) ^ rotr(w[t - 2], 19) ^ (w[t - 2] >> 10)
                w[t] = w[t - 16] &+ s0 &+ w[t - 7] &+ s1
            }
            var a = h[0], b = h[1], c = h[2], d = h[3], e = h[4], f = h[5], g = h[6], hh = h[7]
            for t in 0..<64 {
                let t1 = hh &+ (rotr(e, 6) ^ rotr(e, 11) ^ rotr(e, 25)) &+ ((e & f) ^ (~e & g)) &+ k[t] &+ w[t]
                let t2 = (rotr(a, 2) ^ rotr(a, 13) ^ rotr(a, 22)) &+ ((a & b) ^ (a & c) ^ (b & c))
                hh = g; g = f; f = e; e = d &+ t1; d = c; c = b; b = a; a = t1 &+ t2
            }
            h[0] &+= a; h[1] &+= b; h[2] &+= c; h[3] &+= d; h[4] &+= e; h[5] &+= f; h[6] &+= g; h[7] &+= hh
        }
        let whole = data.count - data.count % 64
        data.withUnsafeBytes { p in
            var at = 0
            while at < whole { compress(p, at); at += 64 }
        }
        tail.withUnsafeBytes { p in
            var at = 0
            while at < p.count { compress(p, at); at += 64 }
        }
        return h.flatMap { v in (0..<4).map { UInt8(truncatingIfNeeded: v >> (24 - 8 * UInt32($0))) } }
    }

    @inline(__always) private static func rotr(_ x: UInt32, _ n: UInt32) -> UInt32 { x >> n | x << (32 - n) }
}

// MARK: - --render (ImageIO, census-only)

#if canImport(ImageIO)
extension DeimosCensus {
    enum RenderError: Error { case missing(String), pngWriteFailed(String) }

    /// Writes `menu.png`, `background.png`, `canyon1-map.png` (top-down), `bocr-frames.png` and
    /// `tesm-plate.png` into `dir` (created if needed); returns the names written, in that order.
    static func renderImages(dataDirectory: URL, to dir: URL) throws -> [String] {
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let index = try TagIndex(dataDirectory: dataDirectory)
        func tga(_ id: String) throws -> TGAImage {
            guard let r = index.record(type: im16, id: FourCC(id)!) else { throw RenderError.missing("im16 \(id)") }
            return try TGAImage(data: index.data(for: r))
        }
        func rgba(_ px: [UInt16]) -> [UInt8] { px.flatMap { rgb8($0) + [255] } }
        var written: [String] = []
        for (name, id) in [("menu.png", "menu"), ("background.png", "back"), ("canyon1-map.png", "cam1")] {
            let t = try tga(id)
            try writePNG(rgba(t.pixels), width: t.width, height: t.height, to: dir.appendingPathComponent(name))
            written.append(name)
        }

        // bocr: the three frames side by side, alpha from the encoded alpha map (0 opaque … 31 invisible).
        let bocr = try SpriteGroup.load(id: FourCC("bocr")!, index: index)
        let w = bocr.frames.reduce(0) { $0 + $1.width + 1 } - 1, h = bocr.frames.map(\.height).max() ?? 0
        var canvas = [UInt8](repeating: 0, count: w * h * 4)
        var x0 = 0
        for f in bocr.frames {
            for y in 0..<f.height {
                let rowInvisible = f.alphaMap?[y * f.width] == 1000
                for x in 0..<f.width {
                    let i = y * f.width + x
                    let a: UInt8
                    if let map = f.alphaMap {
                        let v = rowInvisible ? 0x20 : map[i]
                        a = v < 31 ? UInt8((31 - Int(v)) * 255 / 31) : 0
                    } else {
                        a = f.pixels[i] == f.key ? 0 : 255
                    }
                    let o = (y * w + x0 + x) * 4
                    let c = rgb8(f.pixels[i])
                    canvas[o] = c[0]; canvas[o + 1] = c[1]; canvas[o + 2] = c[2]; canvas[o + 3] = a
                }
            }
            x0 += f.width + 1
        }
        try writePNG(canvas, width: w, height: h, to: dir.appendingPathComponent("bocr-frames.png"))
        written.append("bocr-frames.png")

        // tesm: the colour plate as the 16-bit GWorld holds it.
        guard let tesm = index.record(type: im08, id: FourCC("tesm")!) else { throw RenderError.missing("im08 tesm") }
        let plate = try GIFImage(data: index.data(for: tesm))
        let pal = plate.palette.map { QuickDrawColor.rgb555($0.r, $0.g, $0.b) }
        try writePNG(rgba(plate.indices.map { pal[Int($0)] }), width: plate.width, height: plate.height,
                     to: dir.appendingPathComponent("tesm-plate.png"))
        written.append("tesm-plate.png")
        return written
    }

    /// x1R5G5B5 → 8-bit RGB by bit replication.
    static func rgb8(_ p: UInt16) -> [UInt8] {
        [(p >> 10) & 31, (p >> 5) & 31, p & 31].map { UInt8($0 << 3 | $0 >> 2) }
    }

    static func writePNG(_ rgba: [UInt8], width: Int, height: Int, to url: URL) throws {
        guard let provider = CGDataProvider(data: Data(rgba) as CFData),
              let image = CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32,
                                  bytesPerRow: width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                  bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
                                  provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent),
              let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else {
            throw RenderError.pngWriteFailed(url.lastPathComponent)
        }
        CGImageDestinationAddImage(dest, image, nil)
        guard CGImageDestinationFinalize(dest) else { throw RenderError.pngWriteFailed(url.lastPathComponent) }
    }
}
#endif
