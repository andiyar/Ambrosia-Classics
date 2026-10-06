import Foundation
import HectorResources

/// The game's tag index ("Building Tag Index", `FUN_100016c0`; bank pak-format.md §2.3,
/// app-pak-music-library.md §2, loose-ends-session.md §8.7), built the original's way:
///
/// 1. **Local first.** For each of the 15 types in table order, enumerate `Data/Local/<type>/`:
///    files that cannot be opened or have size ≤ 0 are dropped silently (the shipped `Icon\r`s);
///    a name containing `.tag` is a 0x40-byte tag-header file — none ship, so this port refuses it
///    with an alert (the header's field meanings are unread, bank MED); `.zip`/`.pak` files are
///    skipped with the original's alert; the rest are parsed by `TagName` and added under their
///    SUFFIX type, flagged Local. A file in the wrong folder logs the original's non-fatal
///    "Incorrect file location" alert and is still added.
/// 2. **Then every `.pak`/`.zip` in `Data/Paks`** in name order (the HFS catalog order the original
///    enumerates; shipped: Audio, Game, Interface, Music), entries in central-directory order.
///    Directory and size-0 entries are not indexed; an entry the reader rejects (method ≠ 0 or
///    compressed ≠ uncompressed size, `FUN_10049ca0`) logs "Compressed Zip files are not supported!"
///    and is skipped. Non-zip files log the original's alert (`.DS_Store` silently).
/// 3. **Overrides** (`FUN_10004300`/`FUN_100043c0`): each Local record removes every non-Local record
///    with the same (type, ID), logging "Tag Overridden". Pak duplicates are kept (only counted,
///    "Duplicate (%i) tags found"); the first in list order is the one found.
/// 4. Fewer than **100** records after the override pass → the non-fatal "Tag Index Incomplete!"
///    alert (threshold `_DAT_100e00ec` = 100).
///
/// `alerts` holds the original's log lines verbatim (strings from the 1.0.6 binary), in the order
/// they would be logged. Two arguments are this port's choice because the original's formatter was
/// not read: the duplicate count is "records already indexed with that (type, ID)" at the moment of
/// adding, and "Tag Overridden" prints `"<pak file>" ":" "<entry name>"` for its three `%s`. The
/// `.tag` refusal line is this port's own text.
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
    }

    public let records: [Record]
    public let alerts: [String]
    /// The archives opened from `Data/Paks`, in scan order (`Source.pak.archiveIndex` indexes this).
    public let paks: [URL]
    private let archives: [StoredZipArchive?]

    /// The tag-count threshold below which the "Tag Index Incomplete!" alert fires.
    public static let minimumTagCount = 100

    public init(dataDirectory: URL) throws {
        let fm = FileManager.default
        var list: [Record] = []
        var alerts: [String] = []

        func add(_ r: Record, path: String) {
            let existing = list.reduce(0) { $0 + ($1.type == r.type && $1.id == r.id ? 1 : 0) }
            if existing > 0 {
                alerts.append(" ZPak Error (non fatal): Duplicate (\(existing)) tags found. Path: \"\(path)\", "
                              + "Tag ID: '\(r.id)', Tag Type: '\(r.type)'")
            }
            list.append(r)
        }
        func nameAlert(_ failure: TagName.Failure, _ name: String) {
            switch failure {
            case .ignored: break
            case .noTagID: alerts.append("FILE ALERT.  Could not find Tag ID in file:  \(name)")
            case .noValidSuffix: alerts.append("FILE ALERT.  Could not find a valid suffix in file:  \(name)")
            }
        }

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
                if Self.isZipName(name) {
                    alerts.append("FILE ALERT.  Skipping file.  (Zip files are not supported in the Local directory)")
                    continue
                }
                switch TagName.parse(name) {
                case .failure(let f): nameAlert(f, name)
                case .success(let tag):
                    if tag.type != folderType {
                        alerts.append("\nFILE ALERT. Incorrect file location.  The file should be placed in the "
                                      + "\"\(tag.type)\" folder!")
                    }
                    add(Record(type: tag.type, id: tag.id, displayName: tag.displayName, isLocal: true,
                               source: .local(url), size: size), path: url.path)
                }
            }
        }

        // 2. Paks, in name order; entries in central-directory order.
        var paks: [URL] = []
        var archives: [StoredZipArchive?] = []
        let paksDir = dataDirectory.appendingPathComponent("Paks", isDirectory: true)
        for name in Self.sortedNames(in: paksDir, fm) {
            let url = paksDir.appendingPathComponent(name)
            guard Self.isZipName(name) else {
                if !name.contains(".DS_Store") {
                    alerts.append("FILE ALERT.  Skipping file.  (Only Zip files are supported in the Paks directory)")
                }
                continue
            }
            let archiveIndex = paks.count
            paks.append(url)
            guard let archive = try? StoredZipArchive(contentsOf: url) else {
                archives.append(nil)
                alerts.append("FILE ALERT.  Skipping a file, as it could not be opened.  It may be an empty Zip file."
                              + "  (Only Zip files are supported in the Paks directory)")
                continue
            }
            archives.append(archive)
            for entry in archive.entries where !entry.isDirectory && entry.uncompressedSize > 0 {
                guard entry.method == 0, entry.compressedSize == entry.uncompressedSize else {
                    alerts.append("FILE ERROR: Compressed Zip files are not supported!")
                    continue
                }
                switch TagName.parse(entry.name) {
                case .failure(let f): nameAlert(f, entry.name)
                case .success(let tag):
                    add(Record(type: tag.type, id: tag.id, displayName: tag.displayName, isLocal: false,
                               source: .pak(archiveIndex: archiveIndex, entry: entry), size: entry.uncompressedSize),
                        path: url.path)
                }
            }
        }

        // 3. Local overrides every non-Local record with the same (type, ID).
        for r in list where r.isLocal {
            list.removeAll { other in
                guard !other.isLocal, other.type == r.type, other.id == r.id else { return false }
                if case .pak(let a, let entry) = other.source {
                    alerts.append("    Tag Overridden:  \"\(paks[a].lastPathComponent):\(entry.name)\"")
                }
                return true
            }
        }

        // 4. Completeness (after the override pass).
        if list.count < Self.minimumTagCount { alerts.append("    Tag Index Incomplete!  Aborting.") }

        self.records = list
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

    /// `.zip` / `.pak` (`FUN_100040c0`; exact-case suffixes as the strings read).
    static func isZipName(_ name: String) -> Bool { name.hasSuffix(".zip") || name.hasSuffix(".pak") }

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
