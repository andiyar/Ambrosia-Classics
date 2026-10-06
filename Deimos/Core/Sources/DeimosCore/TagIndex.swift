import Foundation
import HectorResources

/// The game's tag index ("Building Tag Index", `FUN_100016c0`; bank pak-format.md §2.3,
/// app-pak-music-library.md §2, loose-ends-session.md §8.7), built the original's way:
///
/// 1. **Local first.** For each of the 15 types in table order, enumerate `Data/Local/<type>/`:
///    files that cannot be opened or have size ≤ 0 are dropped silently (the shipped `Icon\r`s);
///    a name containing `.tag` is a 0x40-byte tag-header file — none ship, so this port refuses it
///    with an alert (the header's field meanings are unread, bank MED); the rest go through
///    `TagName` (`FUN_100021a0`: zip names refused, no-`[` names, ID, suffix — each with the
///    original's log line) and are added under their SUFFIX type, flagged Local. A file in the
///    wrong folder logs the original's "Incorrect file location" alert (plus the `FALSE` assert
///    line `FUN_10000f30` prints, `100019bc–100019c8`) and is still added.
/// 2. **Then every `.pak`/`.zip` in `Data/Paks`** (`TagName.isZipName`: lower-cased `strstr`) in name
///    order (the HFS catalog order the original enumerates; shipped: Audio, Game, Interface, Music),
///    entries in central-directory order. The zip reader (`FUN_10049ca0`) refuses an entry with
///    method ≠ 0 ("Compressed Zip files are not supported!") or compressed ≠ uncompressed size, logs
///    it with its `unzip.c` assert line, and returns false — which **ends that pak's enumeration**
///    (`10001d54`): later entries of the same pak are not indexed. Size-0 entries (folders) are then
///    skipped; names go through `FUN_10004150` (strip to the last `/`) and `TagName`. Non-zip files
///    log the original's alert (`.DS_Store` silently).
/// 3. **Duplicates** (`10001de8–10001e68`, `FUN_10003970`): after every record is in, and before the
///    override pass, each record r in list order counts the records with r's (type, ID) AND r's
///    Local flag; a count n > 1 logs "Duplicate (n) tags found" with r's path. So a duplicated pair
///    logs twice, both "(2)"; a Local record and a pak record with the same (type, ID) are not
///    duplicates of each other.
/// 4. **Overrides** (`FUN_10004300`/`FUN_100043c0`): each Local record removes every non-Local record
///    with the same (type, ID), logging "Tag Overridden" (the boot build logs it, `10001600`
///    `FUN_100016c0(1, 0)`). Pak duplicates are kept; the first in list order is the one found.
/// 5. Fewer than **100** records after the override pass → the non-fatal "Tag Index Incomplete!"
///    alert (threshold `_DAT_100e00ec` = 100).
///
/// `alerts` holds the original's log lines, each the 1.0.6 format string (data image `0x100e3266`…
/// `0x100e38f7`, `0x100f04d4`…`0x100f0588`) with its arguments filled in, in the order they would be
/// logged. Paths are this machine's (`URL.path`) where the original prints its relative
/// `: Data:…` path. The `.tag` refusal line is this port's own text.
///
/// Entry bytes: `data(for:)` returns a fresh `Data` per entry (`Data(slice)`, rebased so index 0 is
/// the entry's first byte — the archive itself stays memory-mapped and is never copied whole;
/// the largest entry is 5.4 MB).
public struct TagIndex: Sendable {
    public enum Source: Sendable, Equatable {
        case local(URL)
        case pak(archiveIndex: Int, entry: StoredZipArchive.Entry)
    }

    public struct Record: Sendable, Equatable {
        public let type: FourCC
        public let id: FourCC
        public let displayName: String
        public let isLocal: Bool
        public let source: Source
        public let size: Int

        /// The record's tag file name (record +0x110, what `FUN_10002420` returns for log lines): the
        /// Local file name, or the pak entry name after its last `/`.
        public var tagName: String {
            switch source {
            case .local(let url): return url.lastPathComponent
            case .pak(_, let entry): return TagIndex.lastComponent(entry.name)
            }
        }
    }

    public let records: [Record]
    public let alerts: [String]
    /// The archives opened from `Data/Paks`, in scan order (`Source.pak.archiveIndex` indexes this).
    public let paks: [URL]
    private let archives: [StoredZipArchive?]

    /// The tag-count threshold below which the "Tag Index Incomplete!" alert fires.
    public static let minimumTagCount = 100

    /// `FUN_10000f30`'s line (`0x100e2a7f`): the assert that follows several file alerts.
    static func failedOperation(_ file: String, line: Int) -> String {
        "\n\nFILE ERROR: Failed operation:  FALSE\nIn file:    \(file)\nAt line:  \(line)"
    }

    /// The original's log line for a refused name (`FUN_100021a0`); nil = silent.
    static func alertText(_ failure: TagName.Failure, _ name: String) -> String? {
        switch failure {
        case .ignored: return nil
        case .zipFile:
            return "\nFILE ALERT.  Skipping file.  (Zip files are not supported in the Local directory)\n"
                + "Offending file:  \"\(name)\"\n"
        case .noValidInformation:
            return "\nFILE ALERT.  Skipping file, as no valid information was found in filename:  \"\(name)\""
        case .noTagID: return "\nFILE ALERT.  Could not find Tag ID in file:  \(name)"
        case .noValidSuffix: return "\nFILE ALERT.  Could not find a valid suffix in file:  \(name)"
        }
    }

    public init(dataDirectory: URL) throws {
        let fm = FileManager.default
        var list: [(record: Record, path: String)] = []
        var alerts: [String] = []

        // 1. Local, folder by folder in type-table order.
        let local = dataDirectory.appendingPathComponent("Local", isDirectory: true)
        for folderType in TagName.typeOrder {
            let dir = local.appendingPathComponent(folderType.description, isDirectory: true)
            for name in Self.sortedNames(in: dir, fm) {
                let url = dir.appendingPathComponent(name)
                guard let size = Self.regularFileSize(url, fm), size > 0 else { continue }
                if name.lowercased().contains(".tag") {
                    alerts.append("FILE ALERT.  Skipping file.  (.tag header files are not supported)")
                    continue
                }
                switch TagName.parse(name) {
                case .failure(let f): if let a = Self.alertText(f, name) { alerts.append(a) }
                case .success(let tag):
                    if tag.type != folderType {
                        alerts.append("\nFILE ALERT. Incorrect file location.  The file should be placed in the "
                                      + "\"\(tag.type)\" folder!\nOffending File: \"\(url.path)\"\n")
                        alerts.append(Self.failedOperation("U_Pak.cc", line: 0x192))
                    }
                    list.append((Record(type: tag.type, id: tag.id, displayName: tag.displayName, isLocal: true,
                                        source: .local(url), size: size), url.path))
                }
            }
        }

        // 2. Paks, in name order; entries in central-directory order.
        var paks: [URL] = []
        var archives: [StoredZipArchive?] = []
        let paksDir = dataDirectory.appendingPathComponent("Paks", isDirectory: true)
        for name in Self.sortedNames(in: paksDir, fm) {
            let url = paksDir.appendingPathComponent(name)
            guard TagName.isZipName(name) else {
                if !name.contains(".DS_Store") {
                    alerts.append("\nFILE ALERT.  Skipping file.  (Only Zip files are supported in the Paks directory)\n"
                                  + "Offending File:  \"\(name)\"\nPath:  \"\(url.path)\"")
                }
                continue
            }
            let archiveIndex = paks.count
            paks.append(url)
            guard let archive = try? StoredZipArchive(contentsOf: url) else {
                archives.append(nil)
                alerts.append("\nFILE ALERT.  Skipping a file, as it could not be opened.  It may be an empty Zip file."
                              + "  (Only Zip files are supported in the Paks directory)\nOffending File:  \"\(name)\"\n")
                continue
            }
            archives.append(archive)
            for entry in archive.entries {
                // FUN_10049ca0 refuses, logs, and returns false: the pak's loop ends here.
                if entry.method != 0 {
                    alerts.append("\nFILE ERROR: Compressed Zip files are not supported!\n(NOTE: All files must be "
                                  + "archived using the Stored method only)\nOffending Zip Entry:  '\(entry.name)'\n"
                                  + "Offending File:       '\(url.path)'")
                    alerts.append(Self.failedOperation("unzip.c", line: 0xd8))
                    break
                }
                if entry.compressedSize != entry.uncompressedSize {
                    alerts.append("\nFILE ERROR: Zip Entry '\(entry.name)' compression size does not equal "
                                  + "uncompressed size, in Zip file '\(url.path)'")
                    alerts.append(Self.failedOperation("unzip.c", line: 0xb7))
                    break
                }
                guard !entry.isDirectory, entry.uncompressedSize > 0 else { continue }
                let stripped = Self.lastComponent(entry.name)
                switch TagName.parse(stripped) {
                case .failure(let f): if let a = Self.alertText(f, stripped) { alerts.append(a) }
                case .success(let tag):
                    list.append((Record(type: tag.type, id: tag.id, displayName: tag.displayName, isLocal: false,
                                        source: .pak(archiveIndex: archiveIndex, entry: entry),
                                        size: entry.uncompressedSize), url.path))
                }
            }
        }

        // 3. Duplicates: per record, the count of records with its (type, ID) and its Local flag.
        for (r, path) in list {
            let n = list.reduce(0) { $0 + ($1.record.type == r.type && $1.record.id == r.id
                                           && $1.record.isLocal == r.isLocal ? 1 : 0) }
            if n > 1 {
                alerts.append("Pak Error (non fatal): Duplicate (\(n)) tags found. Path: \"\(path)\", "
                              + "Tag ID: '\(r.id)', Tag Type: '\(r.type)'")
            }
        }

        // 4. Local overrides every non-Local record with the same (type, ID).
        var records = list.map(\.record)
        for r in records where r.isLocal {
            records.removeAll { other in
                guard !other.isLocal, other.type == r.type, other.id == r.id else { return false }
                if case .pak(let a, let entry) = other.source {
                    alerts.append("    Tag Overridden:  \"\(paks[a].path):\(Self.lastComponent(entry.name))\"")
                }
                return true
            }
        }

        // 5. Completeness (after the override pass).
        if records.count < Self.minimumTagCount { alerts.append("\n    Tag Index Incomplete!  Aborting.") }

        self.records = records
        self.alerts = alerts
        self.paks = paks
        self.archives = archives
    }

    /// The first record with (type, ID) in list order — what the game's lookup finds.
    public func record(type: FourCC, id: FourCC) -> Record? {
        records.first { $0.type == type && $0.id == id }
    }

    /// Every record of `type`, in index order ("i-th tag of type T": the unde/plde/wede master-list order).
    public func records(ofType type: FourCC) -> [Record] {
        records.filter { $0.type == type }
    }

    /// The record's bytes as a fresh, 0-based `Data` (rebased per entry; see the type comment).
    public func data(for record: Record) throws -> Data {
        switch record.source {
        case .local(let url):
            return try Data(contentsOf: url)
        case .pak(let archiveIndex, let entry):
            guard archives.indices.contains(archiveIndex), let archive = archives[archiveIndex] else {
                throw TagIndexError.archiveUnavailable(archiveIndex)
            }
            return Data(try archive.data(for: entry))
        }
    }

    // MARK: file system helpers

    /// `FUN_10004150`: the text after the last `/` (the whole name when there is none).
    static func lastComponent(_ name: String) -> String {
        name.split(separator: "/", omittingEmptySubsequences: false).last.map(String.init) ?? name
    }

    /// Directory entries sorted case-insensitively, then by raw name (stands in for the HFS catalog
    /// order the original's indexed enumeration returns). A missing folder is empty.
    static func sortedNames(in dir: URL, _ fm: FileManager) -> [String] {
        guard let names = try? fm.contentsOfDirectory(atPath: dir.path) else { return [] }
        return names.sorted { a, b in
            let la = a.lowercased(), lb = b.lowercased()
            return la != lb ? la < lb : a < b
        }
    }

    /// The size of a regular file (symlinks resolved), nil if it cannot be read as one.
    static func regularFileSize(_ url: URL, _ fm: FileManager) -> Int? {
        let resolved = url.resolvingSymlinksInPath()
        guard let attrs = try? fm.attributesOfItem(atPath: resolved.path),
              attrs[.type] as? FileAttributeType == .typeRegular,
              fm.isReadableFile(atPath: resolved.path) else { return nil }
        return (attrs[.size] as? NSNumber)?.intValue
    }
}

public enum TagIndexError: Error, Equatable {
    case archiveUnavailable(Int)
}
