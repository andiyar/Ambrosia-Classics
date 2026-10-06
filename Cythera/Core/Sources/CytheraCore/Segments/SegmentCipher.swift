/// The id-keyed segment cipher, `Encrypt__8TSegFileFPvlUsl @ 1007ba30` (data-format §1.3, HIGH; `Decrypt`
/// just calls it). A 32-bit LCG keyed only by the segment id; each byte is XORed with the low byte of the
/// next state, so the transform is its own inverse:
///
///     mult = (id & 0x3f)·4 + 1;  inc = (id >> 6) & 0xff;  seed = ((id & 0xffff) >> 8) ^ id
///     skip × { seed = inc + seed·mult }
///     each byte { seed = inc + seed·mult; byte ^= low byte of seed }
public enum SegmentCipher {
    /// XORs `bytes` with the key stream of segment `id`. `skip` advances the LCG that many steps first
    /// (the original's `offset` loop): ciphering bytes [k...] with `skip: k` continues the whole-buffer stream.
    public static func apply(_ bytes: inout [UInt8], id: UInt16, skip: Int = 0) {
        let key = UInt32(id)
        let mult = (key & 0x3F) &* 4 &+ 1
        let inc = (key >> 6) & 0xFF
        var state = (key >> 8) ^ key
        if skip > 0 { for _ in 0..<skip { state = inc &+ state &* mult } }
        for i in bytes.indices {
            state = inc &+ state &* mult
            bytes[i] ^= UInt8(truncatingIfNeeded: state)
        }
    }
}
