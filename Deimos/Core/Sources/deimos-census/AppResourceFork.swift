import Foundation
import HectorGraphics
import HectorResources

/// Census section 9 (plan Task C8): the application's resource fork, committed as the data-fork file
/// `Resources/Deimos/Deimos Rising.rsrc` (forks do not survive git — HectorKit D6.5), i.e. next to the
/// `Data` folder. Read with HectorKit's `ResourceReader.read(fileAt:)`; every `PICT` through
/// `PICT.decodeAny` and every `DITL` through `Ditl.decode`. A missing file prints "absent" and is not a
/// failure (a synthetic `Data` folder has none); a file that is present but unreadable, or a PICT/DITL
/// that does not decode, is a failure line.
enum AppResourceFork {
    static let fileName = "Deimos Rising.rsrc"

    static func census(dataDirectory: URL) -> (summaryLine: String, section: [String], failures: Int) {
        let url = dataDirectory.deletingLastPathComponent().appendingPathComponent(fileName)
        guard let bytes = try? Data(contentsOf: url) else {
            return ("rsrc absent", ["`\(fileName)`: absent."], 0)
        }
        var failures = 0
        var lines: [String] = []
        let collection: ResourceCollection
        do {
            guard let c = try ResourceReader.read(fileAt: url) else {
                return ("rsrc FAIL: not a resource map", ["- FAIL: `\(fileName)` is not a resource map"], 1)
            }
            collection = c
        } catch {
            return ("rsrc FAIL: \(error)", ["- FAIL: `\(fileName)`: \(error)"], 1)
        }
        lines.append("`\(fileName)` · \(DeimosCensus.grouped(bytes.count)) bytes · SHA-256 `\(SHA256.hex(bytes))` · "
                     + "\(collection.types().count) types · \(collection.count) resources")
        lines.append("")
        lines.append(DeimosCensus.row(["type", "count", "IDs"]))
        lines.append(DeimosCensus.row(["---", "---:", "---"]))
        for (type, n) in collection.counts() {
            let ids = collection.resources(of: type).map { String($0.id) }.joined(separator: " ")
            lines.append(DeimosCensus.row(["`\(type)`", "\(n)", ids]))
        }

        lines.append("")
        lines.append(DeimosCensus.row(["PICT", "name", "bytes", "size", "decode path", "dropped paint ops"]))
        lines.append(DeimosCensus.row(["---:", "---", "---:", "---", "---", "---"]))
        var pictOK = 0
        let picts = collection.resources(of: "PICT")
        for r in picts {
            do {
                let (p, path) = try PICT.decodeAny(data: r.data)
                pictOK += 1
                lines.append(DeimosCensus.row(["\(r.id)", r.name ?? "", "\(r.data.count)", "\(p.width)×\(p.height)",
                                               path.rawValue, p.droppedPaintOps.isEmpty ? "—" : "\(p.droppedPaintOps)"]))
            } catch {
                failures += 1
                lines.append(DeimosCensus.row(["\(r.id)", r.name ?? "", "\(r.data.count)", "FAIL: \(error)", "", ""]))
            }
        }

        lines.append("")
        lines.append(DeimosCensus.row(["DITL", "name", "items", "item types", "bounds (t,l,b,r)"]))
        lines.append(DeimosCensus.row(["---:", "---", "---:", "---", "---"]))
        var ditlOK = 0, ditlItems = 0
        let ditls = collection.resources(of: "DITL")
        for r in ditls {
            guard let items = Ditl.decode(r.data) else {
                failures += 1
                lines.append(DeimosCensus.row(["\(r.id)", r.name ?? "", "FAIL: does not decode", "", ""]))
                continue
            }
            ditlOK += 1
            ditlItems += items.count
            let types = items.map { String(format: "%02x", $0.type) }.joined(separator: " ")
            let bounds = items.isEmpty ? "—" : {
                let u = items.dropFirst().reduce(items[0].rect) { $0.union($1.rect) }
                return "\(Int(u.minY)),\(Int(u.minX)),\(Int(u.maxY)),\(Int(u.maxX))"
            }()
            lines.append(DeimosCensus.row(["\(r.id)", r.name ?? "", "\(items.count)", types, bounds]))
        }

        let summary = "rsrc \(collection.types().count) types · \(collection.count) resources · "
            + "PICT \(picts.count) (decoded \(pictOK)) · DITL \(ditls.count) (decoded \(ditlOK), items \(ditlItems))"
        return (summary, lines, failures)
    }
}
