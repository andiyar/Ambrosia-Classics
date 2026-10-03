import Foundation

/// Maze cell codes (data-formats.md §1). Only 0/10/15/16/52 occur in the shipped MAZEs; the rest are
/// produced at run time (20, 30, 40, 60), returned off-grid by `_GetNextObject`/`_GetDistantObject`
/// (50, never stored), or are passable balloon tags never stored in the maze (70, 80).
public enum CellCode {
    public static let empty: UInt8 = 0, normal: UInt8 = 10, blue: UInt8 = 15, purple: UInt8 = 16,
        jewel: UInt8 = 20, cluster: UInt8 = 30, popping: UInt8 = 40, wall: UInt8 = 50,
        dynamite: UInt8 = 52, egg: UInt8 = 60, passableF: UInt8 = 70, passableP: UInt8 = 80
}

/// One MAZE resource: 176 bytes, `cells[col + 16·row]`, col 0..15, row 0..10, row 0 = top
/// (`_LoadMaze @ 0002626e` memmoves 0xb0 bytes into `gMaze` and `gMazeCopy`).
public struct Maze: Equatable, Sendable {
    public static let columns = 16, rows = 11, byteCount = 176

    public var cells: [UInt8]

    public init(data: Data) throws {
        try self.init(data: data, id: 0)
    }

    init(data: Data, id: Int16) throws {
        guard data.count == Self.byteCount else {
            throw BTXDataError.badSize(type: "MAZE", id: id, size: data.count)
        }
        cells = [UInt8](data)
    }

    public subscript(col: Int, row: Int) -> UInt8 {
        get { cells[col + Self.columns * row] }
        set { cells[col + Self.columns * row] = newValue }
    }
}
