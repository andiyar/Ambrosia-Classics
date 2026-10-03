import Foundation
import HectorAudio
import HectorGraphics
import HectorResources

/// btx-census — data census of Bubble Trouble X 1.1 through HectorKit's decoders.
///
///     btx-census <Bubble Trouble X.app/Contents/Resources>
///
/// Reads the game's five data-fork resource files and decodes every `cicn` (`CIcon`), `ppat` (`PixelPattern`),
/// `PICT` (`PICT(data:)`, then `PICT.decodeQuickTime` on 0x8200) and `snd ` (`SndSound`). Prints Markdown on
/// stdout — docs/bubble-trouble/data-census.md is this output verbatim under a header — ending in a Totals
/// line. Exit 0 = no failures, 1 = any failure, 2 = bad arguments. Prints file NAMES only, never paths.
///
/// The masked PICTs (0x0099 PackBitsRgn, 0x8201 QuickTime 'rle ' matte) are NAMED DEFERRALS, not failures,
/// until the kit decodes them (plan docs/plans/2026-10-03-hectorkit-btx-decoders.md Tasks 4a/4b/4c).
@main
enum BTXCensus {
    /// The five resource files of Bubble Trouble X 1.1 `Contents/Resources` (bank INDEX.md "Resource census").
    static let fileNames = ["BT Levels.rsrc", "BT Sounds.rsrc", "BT Sprites.rsrc", "BT Titles.rsrc",
                            "Bubble Trouble X.rsrc"]

    static func main() {
        let args = CommandLine.arguments
        var isDirectory: ObjCBool = false
        guard args.count == 2,
              FileManager.default.fileExists(atPath: args[1], isDirectory: &isDirectory), isDirectory.boolValue else {
            FileHandle.standardError.write(Data("usage: btx-census <Bubble Trouble X.app/Contents/Resources>\n".utf8))
            exit(2)
        }
        let census = render(resourcesDirectory: URL(fileURLWithPath: args[1]))
        FileHandle.standardOutput.write(Data(census.stdout.utf8))
        exit(census.failures == 0 ? 0 : 1)
    }

    // MARK: - Render

    /// The whole census as Markdown (ends with the Totals line + newline) and the failure count.
    static func render(resourcesDirectory: URL) -> (stdout: String, failures: Int) {
        var out = Output()
        var failures = 0

        out("# Bubble Trouble X 1.1 — data census")
        out()
        out("Every `cicn`, `ppat`, `PICT` and `snd ` in the five resource files, decoded through HectorKit")
        out("(`CIcon`, `PixelPattern`, `PICT`, `SndSound`). A summary line closes each section.")
        out()

        // 1. Files.
        var files: [(name: String, collection: ResourceCollection)] = []
        out("## 1. Files — resource types per file")
        out()
        out(row(["file", "resources", "types (map order)"])); out(row(["---", "---:", "---"]))
        for name in fileNames {
            do {
                guard let collection = try ResourceReader.read(fileAt: resourcesDirectory.appendingPathComponent(name))
                else { throw CensusError.notAResourceFile }
                files.append((name, collection))
                let types = collection.counts().map { "`\($0.type)` \($0.count)" }.joined(separator: " · ")
                out(row(["`\(name)`", "\(collection.count)", types]))
            } catch {
                out(row(["`\(name)`", "—", "FAIL: \(error)"])); failures += 1
            }
        }
        out()
        let resourceTotal = files.reduce(0) { $0 + $1.collection.count }
        let perFile = files.map { "\($0.name) \($0.collection.count)" }.joined(separator: " · ")
        out("files \(files.count) · resources \(resourceTotal) (\(perFile))")
        out()

        // 2. cicn.
        let cicn = cicnSection(files, &out)
        failures += cicn.failures
        // 3. ppat.
        let ppat = ppatSection(files, &out)
        failures += ppat.failures
        // 4. PICT.
        let pict = pictSection(files, &out)
        failures += pict.failures
        // 5. snd.
        let snd = sndSection(files, &out)
        failures += snd.failures

        out("## Totals")
        out()
        out("Totals: cicn \(cicn.totals), ppat \(ppat.totals), PICT \(pict.totals), snd \(snd.totals), failures \(failures)")
        return (out.text, failures)
    }

    // MARK: - 2. cicn

    private static func cicnSection(_ files: [(name: String, collection: ResourceCollection)],
                                    _ out: inout Output) -> (totals: String, failures: Int) {
        out("## 2. `cicn` — every colour icon through `CIcon(data:)`")
        out()
        out("opaque px = mask-on pixels (A = 255); RGB sum = Σ(R+G+B) over every pixel (RGB is 0 where masked);")
        out("blank = no opaque pixel.")
        out()
        struct Icon { let file: String; let id: Int; let name: String?; let icon: CIcon; let opaque: Int; let rgb: Int }
        var icons: [Icon] = [], failed: [String] = []
        var perFileCount: [(String, Int)] = []
        for (name, collection) in files {
            let resources = collection.resources(of: "cicn").sorted { $0.id < $1.id }
            guard !resources.isEmpty else { continue }
            perFileCount.append((name, resources.count))
            for res in resources {
                do {
                    let icon = try CIcon(data: res.data)
                    let stats = pixelStats(icon.rgba)
                    icons.append(Icon(file: name, id: Int(res.id), name: res.name, icon: icon,
                                      opaque: stats.alpha255, rgb: stats.rgbSum))
                } catch {
                    failed.append("`\(name)` cicn \(res.id): \(error)")
                }
            }
        }

        out(row(["file", "cicn", "opaque px", "RGB sum", "blank"])); out(row(["---", "---:", "---:", "---:", "---:"]))
        for (name, count) in perFileCount {
            let mine = icons.filter { $0.file == name }
            out(row(["`\(name)`", "\(count)", grouped(mine.reduce(0) { $0 + $1.opaque }),
                     grouped(mine.reduce(0) { $0 + $1.rgb }), "\(mine.filter { $0.opaque == 0 }.count)"]))
        }
        out()

        let depths = [1, 2, 4, 8]
        var bySize: [[Int]: [Int: Int]] = [:]
        for i in icons { bySize[[i.icon.width, i.icon.height], default: [:]][i.icon.pixelDepth, default: 0] += 1 }
        out("Size × depth (all files):")
        out()
        out(row(["size"] + depths.map { "\($0)-bit" } + ["total"]))
        out(row(["---"] + depths.map { _ in "---:" } + ["---:"]))
        for size in bySize.keys.sorted(by: { $0.lexicographicallyPrecedes($1) }) {
            let cells = bySize[size]!
            out(row(["\(size[0])×\(size[1])"] + depths.map { cells[$0].map(String.init) ?? "—" }
                    + ["\(cells.values.reduce(0, +))"]))
        }
        out()

        // Per-icon rows for the small files (the app's 4); the sprite file is summarised above.
        let listed = icons.filter { icon in (perFileCount.first { $0.0 == icon.file }?.1 ?? 0) <= 16 }
        if !listed.isEmpty {
            out(row(["file", "id", "name", "size", "depth", "colours", "opaque px", "RGB sum"]))
            out(row(["---", "---:", "---", "---", "---:", "---:", "---:", "---:"]))
            for i in listed {
                out(row(["`\(i.file)`", "\(i.id)", cell(i.name), "\(i.icon.width)×\(i.icon.height)",
                         "\(i.icon.pixelDepth)", "\(i.icon.colorCount)", grouped(i.opaque), grouped(i.rgb)]))
            }
            out()
        }
        failed.forEach { out("- FAIL: \($0)") }
        if !failed.isEmpty { out() }

        let total = perFileCount.reduce(0) { $0 + $1.1 }
        let split = perFileCount.map { "\($0.1)" }.joined(separator: " + ")
        var depthCounts: [Int: Int] = [:]
        icons.forEach { depthCounts[$0.icon.pixelDepth, default: 0] += 1 }
        let depthText = depthCounts.keys.sorted().map { "\($0): \(depthCounts[$0]!)" }.joined(separator: ", ")
        let blanks = icons.filter { $0.opaque == 0 }.map(\.id).sorted()
        out("cicn \(total) (\(split)) · depth {\(depthText)} · opaque px \(grouped(icons.reduce(0) { $0 + $1.opaque }))"
            + " · RGB sum \(grouped(icons.reduce(0) { $0 + $1.rgb }))"
            + " · blank \(blanks.count): \(blanks.map(String.init).joined(separator: " "))")
        out()
        return ("\(total) (\(split))", failed.count)
    }

    // MARK: - 3. ppat

    private static func ppatSection(_ files: [(name: String, collection: ResourceCollection)],
                                    _ out: inout Output) -> (totals: String, failures: Int) {
        out("## 3. `ppat` — every pixel pattern through `PixelPattern(data:)`")
        out()
        out("colour table: device = ctFlags 0x8000 (looked up by position), value-indexed = ctFlags 0 (by entry")
        out("value); read from the resource's ColorTable for this label only. RGB sum = Σ(R+G+B), every pixel opaque.")
        out()
        out(row(["file", "id", "name", "size", "depth", "colours", "colour table", "RGB sum", "pixel (0,0)"]))
        out(row(["---", "---:", "---", "---", "---:", "---:", "---", "---:", "---"]))
        var total = 0, rgbTotal = 0, failed: [String] = []
        var shapes: [String: Int] = [:], shapeOrder: [String] = []
        var forms: [String: Int] = [:], formOrder: [String] = []
        for (name, collection) in files {
            for res in collection.resources(of: "ppat").sorted(by: { $0.id < $1.id }) {
                total += 1
                do {
                    let pattern = try PixelPattern(data: res.data)
                    let stats = pixelStats(pattern.rgba)
                    rgbTotal += stats.rgbSum
                    let shape = "\(pattern.width)×\(pattern.height) \(pattern.pixelDepth)-bit"
                    if shapes[shape] == nil { shapeOrder.append(shape) }
                    shapes[shape, default: 0] += 1
                    let form = colourTableForm(res.data)
                    if forms[form] == nil { formOrder.append(form) }
                    forms[form, default: 0] += 1
                    let p = [UInt8](pattern.rgba.prefix(3))
                    out(row(["`\(name)`", "\(res.id)", cell(res.name), "\(pattern.width)×\(pattern.height)",
                             "\(pattern.pixelDepth)", "\(pattern.colorCount)", form, grouped(stats.rgbSum),
                             "(\(p[0]), \(p[1]), \(p[2]))"]))
                } catch {
                    out(row(["`\(name)`", "\(res.id)", cell(res.name), "?", "?", "?", "?", "?", "FAIL: \(error)"]))
                    failed.append("\(res.id)")
                }
            }
        }
        out()
        let shapeText = shapeOrder.count == 1 ? shapeOrder[0]
            : shapeOrder.map { "\($0) \(shapes[$0]!)" }.joined(separator: " · ")
        let formText = formOrder.map { "\($0) colour table \(forms[$0]!)" }.joined(separator: " · ")
        var summary = "ppat \(total) · \(shapeText) · \(formText) · RGB sum \(grouped(rgbTotal))"
        if !failed.isEmpty { summary += " · failed \(failed.count) (\(failed.joined(separator: " ")))" }
        out(summary)
        out()
        return ("\(total)", failed.count)
    }

    /// "device" (ctFlags bit 15) or "value-indexed", from patMap (u32 @2) → pmTable (u32 @ patMap+42) →
    /// ctFlags (u16 @ pmTable+4); "?" if any offset is out of range. Census labelling only.
    static func colourTableForm(_ data: Data) -> String {
        let b = [UInt8](data)
        func u16(_ o: Int) -> Int? { o >= 0 && o + 1 < b.count ? Int(b[o]) << 8 | Int(b[o + 1]) : nil }
        func u32(_ o: Int) -> Int? { u16(o).flatMap { hi in u16(o + 2).map { hi << 16 | $0 } } }
        guard let patMap = u32(2), let pmTable = u32(patMap + 42), let ctFlags = u16(pmTable + 4) else { return "?" }
        return ctFlags & 0x8000 != 0 ? "device" : "value-indexed"
    }

    // MARK: - 4. PICT

    private enum PictPath: String, CaseIterable {
        case raw = "raw", quickTime = "quicktime", region = "deferred region", matte = "deferred matte"
    }

    private static func pictSection(_ files: [(name: String, collection: ResourceCollection)],
                                    _ out: inout Output) -> (totals: String, failures: Int) {
        out("## 4. `PICT` — every picture through HectorKit")
        out()
        out("path: raw = `PICT(data:)`; quicktime = banded 0x8200 JPEG via `PICT.decodeQuickTime(data:)`;")
        out("deferred region = 0x0099 PackBitsRgn and deferred matte = 0x8201 QuickTime 'rle ' matte — both throw")
        out("`unsupportedOpcode` today and are named deferrals (not failures) until the kit decodes them.")
        out("frame = picFrame; a decode must match it. alpha: opaque = every A 255, else counts of A 255 / 0 / partial.")
        out()
        out(row(["file", "id", "name", "frame", "path", "alpha"])); out(row(["---", "---:", "---", "---", "---", "---"]))
        var byPath: [PictPath: [Int]] = [:], failed: [Int] = [], total = 0
        for (name, collection) in files {
            for res in collection.resources(of: "PICT").sorted(by: { $0.id < $1.id }) {
                total += 1
                let id = Int(res.id)
                let frame = picFrame(res.data)
                let frameText = frame.map { "\($0.width)×\($0.height)" } ?? "?"
                func line(_ path: String, _ alpha: String) {
                    out(row(["`\(name)`", "\(id)", cell(res.name), frameText, path, alpha]))
                }
                func decoded(_ pict: PICT, _ path: PictPath, _ label: String) {
                    guard let frame, pict.width == frame.width, pict.height == frame.height else {
                        line(label, "FAIL: decoded \(pict.width)×\(pict.height) ≠ frame"); failed.append(id); return
                    }
                    let s = pixelStats(pict.rgba)
                    line(label, s.alpha255 == pict.width * pict.height ? "opaque"
                         : "α255 \(grouped(s.alpha255)) · α0 \(grouped(s.alpha0)) · partial \(grouped(s.partial))")
                    byPath[path, default: []].append(id)
                }
                do {
                    decoded(try PICT(data: res.data), .raw, PictPath.raw.rawValue)
                } catch PICT.DecodeError.unsupportedOpcode(let op) where op == 0x8200 {
                    do {
                        let bands = try PICT.quickTimeBands(data: res.data).bands.count
                        decoded(try PICT.decodeQuickTime(data: res.data), .quickTime,
                                "quicktime · \(bands) band\(bands == 1 ? "" : "s")")
                    } catch {
                        line("quicktime", "FAIL: \(error)"); failed.append(id)
                    }
                } catch PICT.DecodeError.unsupportedOpcode(let op) where op == 0x0099 {
                    line(PictPath.region.rawValue, "—"); byPath[.region, default: []].append(id)
                } catch PICT.DecodeError.unsupportedOpcode(let op) where op == 0x8201 {
                    line(PictPath.matte.rawValue, "—"); byPath[.matte, default: []].append(id)
                } catch {
                    line("?", "FAIL: \(error)"); failed.append(id)
                }
            }
        }
        out()
        let present = PictPath.allCases.filter { byPath[$0] != nil }
        func ids(_ list: [Int]) -> String { list.sorted().map(String.init).joined(separator: " ") }
        var parts = present.map { path -> String in
            let list = byPath[path]!
            switch path {
            case .raw, .quickTime: return "\(path.rawValue) \(list.count)"
            case .region, .matte: return "\(path.rawValue) \(list.count) (\(ids(list)))"
            }
        }
        if !failed.isEmpty { parts.append("failed \(failed.count) (\(ids(failed)))") }
        out((["PICT \(total)"] + parts).joined(separator: " · "))
        out()
        var totalsParts = present.map { "\($0.rawValue) \(byPath[$0]!.count)" }
        if !failed.isEmpty { totalsParts.append("failed \(failed.count)") }
        return ("\(total) (\(totalsParts.joined(separator: " · ")))", failed.count)
    }

    /// picFrame (top, left, bottom, right i16 @2) as width × height; nil if short or empty.
    static func picFrame(_ data: Data) -> (width: Int, height: Int)? {
        let b = [UInt8](data.prefix(10))
        guard b.count == 10 else { return nil }
        func i16(_ o: Int) -> Int { Int(Int16(bitPattern: UInt16(b[o]) << 8 | UInt16(b[o + 1]))) }
        let w = i16(8) - i16(4), h = i16(6) - i16(2)
        return w > 0 && h > 0 ? (w, h) : nil
    }

    // MARK: - 5. snd

    private static func sndSection(_ files: [(name: String, collection: ResourceCollection)],
                                   _ out: inout Output) -> (totals: String, failures: Int) {
        out("## 5. `snd ` — every sound through `SndSound(data:)`")
        out()
        out("encode 0x00 = pcm8 (mono 8-bit offset PCM); 0xFE = compressed (codec named). rate = the header's")
        out("Fixed rate >> 16 (whole Hz). length: frames for pcm8, packets (header numFrames) for compressed.")
        out()
        out(row(["file", "id", "name", "format", "encode", "rate", "channels", "length"]))
        out(row(["---", "---:", "---", "---:", "---", "---:", "---:", "---:"]))
        var total = 0, failed: [String] = []
        var kinds: [String: Int] = [:], kindOrder: [String] = []
        var codecChannels: [String: Set<Int>] = [:]
        var rates: [Int: Int] = [:]
        for (name, collection) in files {
            for res in collection.resources(of: "snd ").sorted(by: { $0.id < $1.id }) {
                total += 1
                guard let sound = SndSound(data: res.data) else {
                    out(row(["`\(name)`", "\(res.id)", cell(res.name), "?", "?", "?", "?", "FAIL: SndSound rejected it"]))
                    failed.append("\(res.id)"); continue
                }
                let kind: String, encode: String, length: String
                switch sound.payload {
                case let .pcm8(samples):
                    kind = "pcm8"; encode = "0x00 pcm8"; length = "\(grouped(samples.count)) frames"
                case let .compressed(codec, _, packetCount):
                    kind = codec; encode = "0xFE \(codec)"; length = "\(grouped(packetCount)) packets"
                    codecChannels[codec, default: []].insert(sound.numChannels)
                }
                if kinds[kind] == nil { kindOrder.append(kind) }
                kinds[kind, default: 0] += 1
                rates[sound.sampleRateHz, default: 0] += 1
                out(row(["`\(name)`", "\(res.id)", cell(res.name), "\(sound.format)", encode,
                         "\(sound.sampleRateHz) Hz", "\(sound.numChannels)", length]))
            }
        }
        out()
        func channelNote(_ kind: String) -> String {
            guard let set = codecChannels[kind] else { return "" }
            return set == [2] ? " (stereo)" : set == [1] ? " (mono)" : " (mixed channels)"
        }
        let kindText = kindOrder.map { "\($0) \(kinds[$0]!)\(channelNote($0))" }.joined(separator: " · ")
        let rateText = rates.keys.sorted { (rates[$0]!, $0) > (rates[$1]!, $1) }
            .map { "\($0) Hz \(rates[$0]!)" }.joined(separator: " · ")
        var summary = "snd \(total) · \(kindText) · \(rateText)"
        if !failed.isEmpty { summary += " · failed \(failed.count) (\(failed.joined(separator: " ")))" }
        out(summary)
        out()
        var totalsParts = kindOrder.map { "\($0) \(kinds[$0]!)" }
        if !failed.isEmpty { totalsParts.append("failed \(failed.count)") }
        return ("\(total) (\(totalsParts.joined(separator: " · ")))", failed.count)
    }

    // MARK: - Helpers

    private enum CensusError: Error, CustomStringConvertible {
        case notAResourceFile
        var description: String { "not a readable resource file" }
    }

    /// Accumulates stdout text, one line per call.
    struct Output {
        private(set) var text = ""
        mutating func callAsFunction(_ line: String = "") { text += line + "\n" }
    }

    static func row(_ cells: [String]) -> String { "| " + cells.joined(separator: " | ") + " |" }

    /// A resource name as a table cell ("—" when unnamed; `|` escaped).
    static func cell(_ name: String?) -> String {
        guard let name, !name.isEmpty else { return "—" }
        return name.replacingOccurrences(of: "|", with: "\\|")
    }

    /// Thousands separated by commas, locale-independent: 236687 → "236,687".
    static func grouped(_ n: Int) -> String {
        let digits = String(n.magnitude)
        var result = ""
        for (i, ch) in digits.enumerated() {
            if i > 0 && (digits.count - i) % 3 == 0 { result.append(",") }
            result.append(ch)
        }
        return n < 0 ? "-" + result : result
    }

    /// Over an RGBA8 buffer: Σ(R+G+B) and the counts of A = 255, A = 0 and 0 < A < 255.
    static func pixelStats(_ rgba: Data) -> (rgbSum: Int, alpha255: Int, alpha0: Int, partial: Int) {
        rgba.withUnsafeBytes { (p: UnsafeRawBufferPointer) in
            var rgb = 0, a255 = 0, a0 = 0
            var i = 0
            let n = p.count - p.count % 4
            while i < n {
                rgb += Int(p[i]) + Int(p[i + 1]) + Int(p[i + 2])
                switch p[i + 3] { case 255: a255 += 1; case 0: a0 += 1; default: break }
                i += 4
            }
            return (rgb, a255, a0, n / 4 - a255 - a0)
        }
    }
}
