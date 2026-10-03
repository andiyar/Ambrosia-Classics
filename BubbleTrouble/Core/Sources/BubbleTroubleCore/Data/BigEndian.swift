import Foundation

/// Big-endian field reads over resource bytes. HectorResources' `ByteReader` is internal (plan
/// Invariant 12), so the core decodes its own fields. Offsets are relative to `data.startIndex`.
enum BigEndian {
    static func uint16(_ data: Data, at offset: Int) -> UInt16 {
        let i = data.startIndex + offset
        return UInt16(data[i]) << 8 | UInt16(data[i + 1])
    }

    static func int16(_ data: Data, at offset: Int) -> Int16 {
        Int16(bitPattern: uint16(data, at: offset))
    }

    static func uint32(_ data: Data, at offset: Int) -> UInt32 {
        let i = data.startIndex + offset
        return UInt32(data[i]) << 24 | UInt32(data[i + 1]) << 16 | UInt32(data[i + 2]) << 8 | UInt32(data[i + 3])
    }

    static func bytes(_ data: Data, at offset: Int, count: Int) -> [UInt8] {
        let i = data.startIndex + offset
        return [UInt8](data[i..<(i + count)])
    }
}
