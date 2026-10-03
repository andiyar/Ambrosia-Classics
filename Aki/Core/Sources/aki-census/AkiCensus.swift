import AVFoundation
import AkiCore
import Foundation
import HectorGraphics
import HectorResources

/// aki-census — Phase 0 data census of Aki - Mahjong Solitaire 1.1.0 + 1.2.0 through HectorKit.
///
///     aki-census <Aki 1.1.0 Contents/Resources> <Aki 1.2.0 Contents/Resources>
///
/// Prints Markdown on stdout (docs/aki/data-census.md is this output verbatim under a header) and
/// exits 1 if any PICT, PNG or audio file fails to decode/open, 2 on bad arguments. Prints file
/// NAMES only, never machine paths.
@main
struct AkiCensus {
    static func main() {
        let args = CommandLine.arguments
        guard args.count == 3 else {
            FileHandle.standardError.write(Data(
                "usage: aki-census <Aki 1.1.0 Contents/Resources> <Aki 1.2.0 Contents/Resources>\n".utf8))
            exit(2)
        }
        do {
            let failures = try run(v11: URL(fileURLWithPath: args[1]), v12: URL(fileURLWithPath: args[2]))
            exit(failures == 0 ? 0 : 1)
        } catch {
            FileHandle.standardError.write(Data("aki-census: \(error)\n".utf8))
            exit(1)
        }
    }

    static func row(_ cells: [String]) -> String { "| " + cells.joined(separator: " | ") + " |" }

    /// Returns the number of failures (0 = everything decoded/opened).
    static func run(v11 resources11: URL, v12 resources12: URL) throws -> Int {
        let v11 = try AkiBundle(resourcesURL: resources11)
        let v12 = try AkiBundle(resourcesURL: resources12)
        var failures = 0

        // 1. The 1.1.0 resource file.
        guard let rsrc = v11.resourceFile,
              let collection = try ResourceReader.read(fileAt: rsrc) else {
            FileHandle.standardError.write(Data("aki-census: FAIL: no readable .rsrc resource file in the 1.1.0 folder\n".utf8))
            return 1
        }
        print("## 1. Aki 1.1.0 resource file — `\(rsrc.lastPathComponent)`\n")
        print(row(["type", "count"])); print(row(["---", "---:"]))
        for (type, count) in collection.counts() { print(row(["`\(type)`", "\(count)"])) }
        print(row(["**total**", "**\(collection.count)**"]))
        print("\nThe 1.2.0 folder has \(v12.resourceFile == nil ? "no" : "a") `.rsrc` file.\n")

        // 2. Every PICT through the kit.
        print("## 2. PICT census (1.1.0) — every PICT through HectorKit\n")
        print("`kind`: raw16 / raw32 = DirectBitsRect via `PICT(data:)` (\"argb\" = cmpCount 4, a real alpha")
        print("plane); quicktime = banded 0x8200 JPEG via `PICT.decodeQuickTime(data:)`.\n")
        print(row(["id", "frame", "kind", "bands", "decode"])); print(row(["---:", "---", "---", "---:", "---"]))
        var rawCount = 0, quickTimeCount = 0
        var composites: [(id: Int16, width: Int, height: Int, rgba: [UInt8])] = []
        for res in collection.resources(of: "PICT") {
            do {
                let pict = try PICT(data: res.data)
                let depth = directBitsDepth(res.data)
                let kind = depth.map { "raw\($0.pixelSize)" + ($0.cmpCount == 4 ? " argb" : "") } ?? "raw"
                print(row(["\(res.id)", "\(pict.width)×\(pict.height)", kind, "—", "ok"]))
                rawCount += 1
            } catch PICT.DecodeError.unsupportedOpcode(let op) where op == 0x8200 {
                do {
                    let bands = try PICT.quickTimeBands(data: res.data).bands.count
                    let pict = try PICT.decodeQuickTime(data: res.data)
                    print(row(["\(res.id)", "\(pict.width)×\(pict.height)", "quicktime", "\(bands)", "ok"]))
                    composites.append((res.id, pict.width, pict.height, [UInt8](pict.rgba)))
                    quickTimeCount += 1
                } catch {
                    print(row(["\(res.id)", "?", "quicktime", "?", "FAIL: \(error)"])); failures += 1
                }
            } catch {
                print(row(["\(res.id)", "?", "?", "?", "FAIL: \(error)"])); failures += 1
            }
        }
        let pictTotal = collection.resources(of: "PICT").count

        // 3. The 1.2.0 PNGs.
        var pngs: [(name: String, width: Int, height: Int, rgba: [UInt8])] = []
        var pngFailures = 0
        var pngRows: [String] = []
        for url in v12.pngFiles {
            do {
                let image = try CodecImage.decode(Data(contentsOf: url))
                pngRows.append(row(["`\(url.lastPathComponent)`", "\(image.width)×\(image.height)", "ok"]))
                pngs.append((url.lastPathComponent, image.width, image.height, [UInt8](image.rgba)))
            } catch {
                pngRows.append(row(["`\(url.lastPathComponent)`", "?", "FAIL: \(error)"])); pngFailures += 1
            }
        }
        failures += pngFailures

        print("\n## 3. 1.1.0 QuickTime art ↔ 1.2.0 PNG\n")
        print("For each QuickTime PICT: the same-size 1.2.0 PNG with the smallest mean absolute RGB")
        print("difference (0–255 scale) from the decoded composite. A wrong band order/offset costs ≥ 10.\n")
        print(row(["PICT", "frame", "closest 1.2.0 PNG", "mean abs diff"])); print(row(["---:", "---", "---", "---:"]))
        for c in composites {
            let candidates = pngs.filter { $0.width == c.width && $0.height == c.height }
            let scored = candidates.map { (name: $0.name, diff: meanAbsRGBDiff(c.rgba, $0.rgba)) }
            if let best = scored.min(by: { $0.diff < $1.diff }) {
                print(row(["\(c.id)", "\(c.width)×\(c.height)", "`\(best.name)`", String(format: "%.2f", best.diff)]))
            } else {
                print(row(["\(c.id)", "\(c.width)×\(c.height)", "— (no same-size PNG)", "—"]))
            }
        }

        print("\n## 4. PNG census (1.2.0) — every PNG through `CodecImage`\n")
        print(row(["file", "size", "decode"])); print(row(["---", "---", "---"]))
        pngRows.forEach { print($0) }

        // 5. Audio, both versions.
        print("\n## 5. Audio — every AIFF/MP3 through `AVAudioFile(forReading:)`\n")
        var opened: [Int] = []
        for (label, bundle) in [("1.1.0", v11), ("1.2.0", v12)] {
            print("### \(label)\n")
            print(row(["file", "format", "sample rate", "channels", "length (frames)", "processing format"]))
            print(row(["---", "---", "---:", "---:", "---:", "---"]))
            var ok = 0
            for url in bundle.audioFiles {
                do {
                    let file = try AVAudioFile(forReading: url)
                    let format = file.fileFormat
                    let processing = file.processingFormat
                    print(row(["`\(url.lastPathComponent)`", fourCC(format.streamDescription.pointee.mFormatID),
                               "\(Int(format.sampleRate))", "\(format.channelCount)", "\(file.length)",
                               "\(commonFormatName(processing.commonFormat)) \(Int(processing.sampleRate)) Hz "
                               + "\(processing.channelCount) ch \(processing.isInterleaved ? "interleaved" : "non-interleaved")"]))
                    ok += 1
                } catch {
                    print(row(["`\(url.lastPathComponent)`", "FAIL: \(error)", "", "", "", ""])); failures += 1
                }
            }
            opened.append(ok)
            print("")
        }

        print("## Totals\n")
        print("- PICT: \(pictTotal) (raw \(rawCount), quicktime \(quickTimeCount), failed \(pictTotal - rawCount - quickTimeCount))")
        print("- PNG: \(v12.pngFiles.count) (failed \(pngFailures))")
        print("- Audio: 1.1.0 \(opened[0]) of \(v11.audioFiles.count) opened, 1.2.0 \(opened[1]) of \(v12.audioFiles.count) opened")
        print("- Failures: \(failures)")
        return failures
    }

    /// For a raw PICT: pixelSize/cmpCount of its first DirectBitsRect (0x009A), found by stepping the
    /// state ops Aki's raw PICTs carry before it (0x0011 · 0x0C00 · 0x00A1 · 0x0001; 0x00A0 too).
    /// nil if the stream has any other opcode first. Census labelling only — decoding is the kit's.
    static func directBitsDepth(_ data: Data) -> (pixelSize: Int, cmpCount: Int)? {
        let b = [UInt8](data)
        func u16(_ o: Int) -> Int? { o >= 0 && o + 1 < b.count ? Int(b[o]) << 8 | Int(b[o + 1]) : nil }
        var pos = 10                                     // past picSize + picFrame
        while let op = u16(pos) {
            pos += 2
            switch op {
            case 0x0011: pos += 2
            case 0x0C00: pos += 24
            case 0x00A0: pos += 2
            case 0x00A1:
                guard let size = u16(pos + 2) else { return nil }
                pos += 4 + size
            case 0x0001:
                guard let size = u16(pos) else { return nil }
                pos += size
            case 0x009A:
                // baseAddr 4 · rowBytes 2 · bounds 8 · pmVersion 2 · packType 2 · packSize 4 ·
                // hRes 4 · vRes 4 · pixelType 2 → pixelSize @32, cmpCount @34 (after the opcode).
                guard let pixelSize = u16(pos + 32), let cmpCount = u16(pos + 34) else { return nil }
                return (pixelSize, cmpCount)
            default:
                return nil
            }
            if pos % 2 == 1 { pos += 1 }
        }
        return nil
    }

    /// Mean absolute difference over the R, G, B channels of two same-size RGBA8 buffers.
    static func meanAbsRGBDiff(_ a: [UInt8], _ b: [UInt8]) -> Double {
        precondition(a.count == b.count)
        var sum = 0
        var i = 0
        while i < a.count {
            sum += abs(Int(a[i]) - Int(b[i])) + abs(Int(a[i + 1]) - Int(b[i + 1])) + abs(Int(a[i + 2]) - Int(b[i + 2]))
            i += 4
        }
        return Double(sum) / Double(a.count / 4 * 3)
    }

    static func fourCC(_ v: UInt32) -> String {
        String([24, 16, 8, 0].map { Character(UnicodeScalar(UInt8(truncatingIfNeeded: v >> $0))) })
    }

    static func commonFormatName(_ f: AVAudioCommonFormat) -> String {
        switch f {
        case .pcmFormatFloat32: return "Float32"
        case .pcmFormatFloat64: return "Float64"
        case .pcmFormatInt16: return "Int16"
        case .pcmFormatInt32: return "Int32"
        case .otherFormat: return "other"
        @unknown default: return "unknown"
        }
    }
}
