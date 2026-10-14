import Foundation
import HectorResources

/// Why a saved game could not be opened (`.OpenSG @ 10048608`, M l. 41315ff) — `ReportDialog`'s text.
public enum SavedGameError: Error, Equatable, Sendable {
    /// No `'FWSg'` 0 in the file (`GetResource` nil).
    case notASavedGame
    /// `CloseResFile` failed after the block was read (`ResError() ≠ 0`). Nothing in the replica's read path
    /// corresponds to that close, so `SavedGameFile.read` never throws it; the case carries the original's string.
    case openFailed

    /// "Sorry, this does not appear to be a saved game file." (`0x100a5a3d`) / "Error opening the saved game."
    /// (`0x100a5a1f`).
    public var message: String {
        switch self {
        case .notASavedGame: "Sorry, this does not appear to be a saved game file."
        case .openFailed: "Error opening the saved game."
        }
    }
}

/// A saved-game file: one `'FWSg'` id 0 named "Ferazel Saved Game" holding the 966,232-byte `SaveBlock` (`.SaveSG
/// @ 10048294`: `FSpDelete`, `FSpCreate(spec, 'Msct', 'FWSg', 0)`, `FSpCreateResFile`, `AddResource(block, 'FWSg', 0,
/// 0x100a586c)`, `WriteResource`; M l. 41179ff). The replica writes the classic resource map into the **data fork**
/// (D35 ruling 7, Known deviation 2) and reads the data fork or — on macOS — the file's resource fork, so a save from
/// a real Mac resumes (Known deviation 9: elsewhere the data fork is the only fork and type/creator are skipped).
public enum SavedGameFile {
    public static let resourceType = "FWSg"
    public static let resourceID: Int16 = 0
    /// "Ferazel Saved Game" (pstr `0x100a586c`).
    public static let resourceName = SaveName.defaultName
    /// HFS file type `'FWSg'` and creator `'Msct'`.
    public static let fileType: UInt32 = 0x4657_5367
    public static let creator: UInt32 = 0x4d73_6374

    /// `.SaveSG`'s file part: delete the old file (`FSpDelete` — its resource fork goes with it), create it, write
    /// the map, set type/creator (macOS). Throws the Foundation error of the failing step; `writeErrorReport(osErr:)`
    /// holds the original's texts for the App's mapping.
    public static func write(_ block: SaveBlock, to url: URL) throws {
        let map = ClassicResourceMap.serialize([Resource(type: resourceType, id: resourceID, name: resourceName,
                                                         data: block.image())])
        let fm = FileManager.default
        if fm.fileExists(atPath: url.path) { try fm.removeItem(at: url) }
        try map.write(to: url)
        #if os(macOS)
        try fm.setAttributes([.hfsTypeCode: NSNumber(value: fileType), .hfsCreatorCode: NSNumber(value: creator)],
                             ofItemAtPath: url.path)
        #endif
    }

    /// `.OpenSG`'s read: the `'FWSg'` 0 body from the data fork's map, else (macOS) the resource fork's; none →
    /// `.notASavedGame` (an unreadable or missing file too: the original's `FSpOpenResFile` fails and `GetResource`
    /// finds nothing). The original uses `GetResource` (the whole resource chain); the replica looks only in the
    /// file — nothing else in the chain holds `'FWSg'`. No size check (the original makes none): a short body is
    /// read as if 0-padded to 0xebe58 (the original would read past the handle; 0 is the replica's choice).
    public static func read(from url: URL) throws(SavedGameError) -> SaveBlock {
        guard var body = resource(in: try? Data(contentsOf: url)) ?? resourceForkBody(url) else {
            throw .notASavedGame
        }
        if body.count < SaveBlock.byteCount { body.append(Data(count: SaveBlock.byteCount - body.count)) }
        guard let block = try? SaveBlock(image: body) else { throw .notASavedGame }
        return block
    }

    /// `.SaveSG`'s error mapping (M l. 41275–41296; `ReportError(text, code)`): −34 (disk full, `0x100a58d1`), −33
    /// (directory full, `0x100a5908`), −44 (volume locked, `0x100a5944`), anything else → the general text
    /// (`0x100a597f`), the only one whose report carries the code (`code` nil for the other three).
    public static func writeErrorReport(osErr: Int16) -> (message: String, code: Int16?) {
        switch osErr {
        case -34: ("The game could not be saved, because the disk is full.", nil)
        case -33: ("The game could not be saved, because the directory is full.", nil)
        case -44: ("The game could not be saved, because the volume is locked.", nil)
        default: ("The game could not be saved. Check that there is enough space and the volume is not locked.", osErr)
        }
    }

    private static func resource(in data: Data?) -> Data? {
        guard let data, ClassicResourceMap.sniff(data), let map = try? ClassicResourceMap.parse(data) else { return nil }
        return map.resource(type: resourceType, id: resourceID)?.data
    }

    private static func resourceForkBody(_ url: URL) -> Data? {
        #if os(macOS)
        return resource(in: try? Data(contentsOf: url.appendingPathComponent("..namedfork/rsrc")))
        #else
        return nil
        #endif
    }
}
