import Foundation

public enum SegmentOverlayError: Error, Equatable, Sendable {
    /// `write` needs a `MemorySegmentStore` in slot 0 (Phase 0 writes no file; the save file is Phase 4's).
    case slotZeroNotWritable
}

/// A mutable in-memory segment store: the Phase 0 stand-in for the scratch file `DoSave` pushes on top
/// (data-format §1.4). A reference type, so the overlay and its creator see the same contents.
public final class MemorySegmentStore: SegmentStore {
    private var segments: [UInt16: Data]

    public init(_ segments: [UInt16: Data] = [:]) {
        self.segments = segments.filter { !$0.value.isEmpty }
    }

    /// Offset is meaningless in memory (always 0); length 0 = absent.
    public func entry(_ id: UInt16) -> (offset: Int, length: Int)? {
        segments[id].map { (0, $0.count) }
    }

    public func segment(_ id: UInt16) -> Data? { segments[id] }

    /// Stores `data` (rebased to zero); empty data removes the segment ("absent = length 0", §1.1).
    public func write(_ id: UInt16, data: Data) {
        segments[id] = data.isEmpty ? nil : Data(data)
    }
}

/// The `TCachedSegFiles` model (data-format §1.4, HIGH): up to 16 stores, slot 0 on top. `AddFile` shifts
/// slots 0xF..1 down one and puts the new file in slot 0 — so a push onto a full stack drops the bottom
/// store. Reads come from the topmost store that has the id; writes always go to slot 0.
/// The drop models AddFile's slot shift only: the original's merged per-id directory (`SetEntry`) may
/// still point at a dropped file's segments. Only a 17th+ file is affected; here it is modelled as dropped.
public struct SegmentOverlay {
    public static let capacity = 16

    /// Slot 0 first.
    public private(set) var stores: [any SegmentStore] = []
    public var count: Int { stores.count }

    public init() {}

    public mutating func push(_ store: any SegmentStore) {
        stores.insert(store, at: 0)
        if stores.count > Self.capacity { stores.removeLast() }
    }

    public func segment(_ id: UInt16) -> Data? {
        for store in stores { if let data = store.segment(id) { return data } }
        return nil
    }

    public func write(_ id: UInt16, data: Data) throws {
        guard let top = stores.first as? MemorySegmentStore else { throw SegmentOverlayError.slotZeroNotWritable }
        top.write(id, data: data)
    }
}
