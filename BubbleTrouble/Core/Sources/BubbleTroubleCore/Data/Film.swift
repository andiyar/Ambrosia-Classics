import Foundation

/// One recorded input sample (FILM arrays; nonzero = held).
public struct FilmSample: Equatable, Sendable {
    public var up, down, left, right, push: Bool

    public init(up: Bool, down: Bool, left: Bool, right: Bool, push: Bool) {
        self.up = up; self.down = down; self.left = left; self.right = right; self.push = push
    }
}

/// One FILM resource (Research note 10, data-formats.md §3): 10012 bytes — u32 BE count, u32 BE seed,
/// u32 BE level-field (unused, NR-1), then five 2000-byte arrays up @12, down @2012, left @4012,
/// right @6012, push @8012. A sample is consumed only by `_CheckHeroMovement` (plan Invariant 5).
public struct Film: Equatable, Sendable {
    public static let byteCount = 10012, capacity = 2000

    public let id: Int, count: Int, seed: UInt32, levelField: UInt32
    public let up, down, left, right, push: [UInt8]

    public init(id: Int, data: Data) throws {
        guard data.count == Self.byteCount else {
            throw BTXDataError.badSize(type: "FILM", id: Int16(truncatingIfNeeded: id), size: data.count)
        }
        self.id = id
        count = Int(BigEndian.uint32(data, at: 0))
        seed = BigEndian.uint32(data, at: 4)
        levelField = BigEndian.uint32(data, at: 8)
        up = BigEndian.bytes(data, at: 12, count: Self.capacity)
        down = BigEndian.bytes(data, at: 2012, count: Self.capacity)
        left = BigEndian.bytes(data, at: 4012, count: Self.capacity)
        right = BigEndian.bytes(data, at: 6012, count: Self.capacity)
        push = BigEndian.bytes(data, at: 8012, count: Self.capacity)
    }

    public func sample(_ index: Int) -> FilmSample {
        precondition(index >= 0 && index < Self.capacity, "FILM sample index \(index) out of 0..<2000")
        return FilmSample(up: up[index] != 0, down: down[index] != 0, left: left[index] != 0,
                          right: right[index] != 0, push: push[index] != 0)
    }
}
