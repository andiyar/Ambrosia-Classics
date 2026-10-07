import Foundation

/// A `Lite` resource: byte n, then n × n intensity bytes, row-major (engine-classes §3.3, open-items §10 —
/// HIGH sizes). `Lite 140 + radius/100` is the party light stamped by `CopyLight` (`Lite 140` = 65 B = 1 + 8²,
/// `Lite 158` = 14,401 B = 1 + 120²); `Lite 128…133` are other light shapes whose use is NOT RESOLVED. All 25
/// ship in `Cythera.rsrc` (none in the data file; p07). The length must be exactly 1 + n².
public struct LightMask: Equatable, Sendable {
    /// n, the mask's width and height.
    public let size: Int
    /// n × n bytes, row-major, as stored.
    public let intensities: [UInt8]

    public init(data: Data) throws {
        let b = ArtBytes(data, type: "Lite")
        let n = Int(try b.u8(0, "size"))
        try b.require(1, n * n, "intensities")
        guard b.count == 1 + n * n else {
            throw ArtRecordError.length("Lite", expected: 1 + n * n, actual: b.count)
        }
        size = n
        intensities = Array(b.bytes[1...].prefix(n * n))
    }

    /// The intensity at (x, y); nil outside the mask.
    public func intensity(x: Int, y: Int) -> UInt8? {
        guard x >= 0, y >= 0, x < size, y < size else { return nil }
        return intensities[y * size + x]
    }
}
