import Foundation
import HectorResources

/// The settings file (`U_Prefs.cc`): the original's 0x34f0-byte prefs block, read and written as one raw image
/// (grounding C §1a layout, §1b I/O; Phase 4 plan ruling 6). `image` is the block as it sits in memory — names plain,
/// scores real — so every byte the typed `DeimosPrefs` does not carry (ints 4–99, both reserved blocks, the pad, the
/// dead ints, bytes after a name's NUL) survives a read and a write untouched.
///
/// - Read (`FUN_10004f80`): `FSRead` 0x34f0 bytes into the block, the count ignored — the block is a static array in
///   the zero-filled data (X: TOC slot 100e4844 → 100fdbf4, next symbol 101010e4 = +0x34f0), so whatever a short
///   file does not reach stays 0 (grounding C §6a item 3). Then, for k in 0…14: unscramble name k and sector name k
///   over the C `strlen` of their stored bytes, score k −0x24A8903, dead int k +0x5969FBD0; THEN the version test.
/// - Write (`FUN_10004640`): a copy of the block, the same loop inverted (scramble over `strlen` of the plain bytes,
///   +0x24A8903, −0x5969FBD0), 0x34f0 bytes out.
/// - Fresh (`FUN_10004540`): a zeroed block, version 0x2714, then the defaults (`DeimosPrefs.fresh`).
public struct PrefsFile: Equatable, Sendable {
    /// The record's size, read and written whole.
    public static let byteCount = 0x34f0
    /// +0x0000: the only version a read accepts.
    public static let currentVersion: UInt32 = 0x2714

    static let bytePrefsOffset = 0x0004
    static let intPrefsOffset = 0x0068, intPrefCount = 100
    static let namesOffset = 0x10f8, nameWidth = 21, scoreCount = 15
    static let playerNamesOffset = 0x1233, playerCount = 2
    static let scoresOffset = 0x1260
    static let deadIntsOffset = 0x129c
    static let sectorNamesOffset = 0x12d8, sectorNameWidth = 32
    static let keyTableOffset = 0x14b8, keyCount = 14
    static let scoreBias: UInt32 = 0x024A_8903
    static let deadBias: UInt32 = 0x5969_FBD0

    /// The block in memory (decoded form), always `byteCount` bytes.
    public private(set) var image: [UInt8]

    private init(image: [UInt8]) { self.image = image }

    /// `FUN_10004f80`: the file's bytes as the original loads them; nil when the version is not 0x2714 (the caller
    /// then makes the fresh record and writes it at once, `FUN_10004540`).
    public init?(fileBytes: [UInt8]) {
        let image = Self.decodedImage(fileBytes: fileBytes)
        guard Self.readBE(image, 0) == Self.currentVersion else { return nil }
        self.init(image: image)
    }

    /// The block after `FUN_10004f80`'s read and unscrambling loop, before its version test: at most 0x34f0 bytes of
    /// the file, the rest 0, names and sector names unscrambled, scores and dead ints un-biased.
    public static func decodedImage(fileBytes: [UInt8]) -> [UInt8] {
        var image = [UInt8](repeating: 0, count: byteCount)
        let n = min(fileBytes.count, byteCount)
        image.replaceSubrange(0..<n, with: fileBytes[0..<n])
        for k in 0..<scoreCount {
            scramble(&image, at: namesOffset + nameWidth * k)
            scramble(&image, at: sectorNamesOffset + sectorNameWidth * k)
            addBE(&image, scoresOffset + 4 * k, 0 &- scoreBias)
            addBE(&image, deadIntsOffset + 4 * k, deadBias)
        }
        return image
    }

    /// The fresh record (`FUN_10004540`): a zeroed block, the version, the defaults.
    public static let fresh: PrefsFile = {
        var file = PrefsFile(image: [UInt8](repeating: 0, count: byteCount))
        file.apply(.fresh)
        return file
    }()

    /// `FUN_10004640`: the bytes written to disk.
    public var fileBytes: [UInt8] {
        var out = image
        for k in 0..<Self.scoreCount {
            Self.scramble(&out, at: Self.namesOffset + Self.nameWidth * k)
            Self.scramble(&out, at: Self.sectorNamesOffset + Self.sectorNameWidth * k)
            Self.addBE(&out, Self.scoresOffset + 4 * k, Self.scoreBias)
            Self.addBE(&out, Self.deadIntsOffset + 4 * k, 0 &- Self.deadBias)
        }
        return out
    }

    /// The typed fields the game uses, read from the block. A name is its field's bytes up to the first NUL, at most
    /// the field's width.
    public var prefs: DeimosPrefs {
        DeimosPrefs(
            version: Self.readBE(image, 0),
            bytePrefs: Array(image[Self.bytePrefsOffset..<Self.bytePrefsOffset + DeimosPrefs.bytePrefCount]),
            intPrefs: (0..<DeimosPrefs.fresh.intPrefs.count).map {
                Int32(bitPattern: Self.readBE(image, Self.intPrefsOffset + 4 * $0))
            },
            keyTable: (0..<Self.keyCount).map {
                UInt16(truncatingIfNeeded: Self.readBE(image, Self.keyTableOffset + 4 * $0))
            },
            highScores: (0..<Self.scoreCount).map {
                Int32(bitPattern: Self.readBE(image, Self.scoresOffset + 4 * $0))
            },
            highScoreNames: (0..<Self.scoreCount).map {
                name(at: Self.namesOffset + Self.nameWidth * $0, width: Self.nameWidth)
            },
            highScoreSectorNames: (0..<Self.scoreCount).map {
                name(at: Self.sectorNamesOffset + Self.sectorNameWidth * $0, width: Self.sectorNameWidth)
            },
            playerNames: (0..<Self.playerCount).map {
                name(at: Self.playerNamesOffset + Self.nameWidth * $0, width: Self.nameWidth)
            })
    }

    /// Put the typed fields into the block. A field whose value already reads back as `prefs` holds is left as it is
    /// (so its raw bytes survive); a changed name is written as the original's only name writer does
    /// (`FUN_10004ae0`: zero the field, then copy the C string), cut to the field's width less its NUL.
    public mutating func apply(_ prefs: DeimosPrefs) {
        Self.writeBE(&image, 0, prefs.version)
        for (i, b) in prefs.bytePrefs.prefix(DeimosPrefs.bytePrefCount).enumerated() {
            image[Self.bytePrefsOffset + i] = b
        }
        for (i, v) in prefs.intPrefs.prefix(Self.intPrefCount).enumerated() {
            Self.writeBE(&image, Self.intPrefsOffset + 4 * i, UInt32(bitPattern: v))
        }
        for (i, key) in prefs.keyTable.prefix(Self.keyCount).enumerated() {
            let at = Self.keyTableOffset + 4 * i
            if UInt16(truncatingIfNeeded: Self.readBE(image, at)) != key { Self.writeBE(&image, at, UInt32(key)) }
        }
        for (i, v) in prefs.highScores.prefix(Self.scoreCount).enumerated() {
            Self.writeBE(&image, Self.scoresOffset + 4 * i, UInt32(bitPattern: v))
        }
        for (i, s) in prefs.highScoreNames.prefix(Self.scoreCount).enumerated() {
            setName(s, at: Self.namesOffset + Self.nameWidth * i, width: Self.nameWidth)
        }
        for (i, s) in prefs.highScoreSectorNames.prefix(Self.scoreCount).enumerated() {
            setName(s, at: Self.sectorNamesOffset + Self.sectorNameWidth * i, width: Self.sectorNameWidth)
        }
        for (i, s) in prefs.playerNames.prefix(Self.playerCount).enumerated() {
            setName(s, at: Self.playerNamesOffset + Self.nameWidth * i, width: Self.nameWidth)
        }
    }

    // MARK: - Fields

    private func name(at offset: Int, width: Int) -> String {
        let field = image[offset..<offset + width]
        return MacRoman.decode(field.prefix { $0 != 0 })
    }

    private mutating func setName(_ s: String, at offset: Int, width: Int) {
        guard name(at: offset, width: width) != s else { return }
        // Lossy Mac Roman: an unrepresentable character becomes one '?'. The encoder refuses a whole string in one
        // case (Foundation's composed-plus-mark quirk); then encode character by character under the same rule.
        let encoded = MacRoman.encode(s, lossy: true)
            ?? s.flatMap { MacRoman.encode(String($0), lossy: true) ?? [0x3F] }
        let bytes = encoded.prefix { $0 != 0 }.prefix(width - 1)
        for i in 0..<width { image[offset + i] = 0 }
        image.replaceSubrange(offset..<offset + bytes.count, with: bytes)
    }

    // MARK: - The original's arithmetic

    /// `FUN_10046470(p, strlen(p))`: swap the nibbles and invert each byte up to the first NUL — C's `strlen`, so a
    /// field with no NUL runs on into the next one (bounded here by the block's end). An involution.
    static func scramble(_ image: inout [UInt8], at offset: Int) {
        var i = offset
        while i < image.count, image[i] != 0 {
            let b = image[i]
            image[i] = ~(b >> 4 | b << 4)
            i += 1
        }
    }

    static func readBE(_ image: [UInt8], _ at: Int) -> UInt32 {
        UInt32(image[at]) << 24 | UInt32(image[at + 1]) << 16 | UInt32(image[at + 2]) << 8 | UInt32(image[at + 3])
    }

    static func writeBE(_ image: inout [UInt8], _ at: Int, _ v: UInt32) {
        image[at] = UInt8(truncatingIfNeeded: v >> 24)
        image[at + 1] = UInt8(truncatingIfNeeded: v >> 16)
        image[at + 2] = UInt8(truncatingIfNeeded: v >> 8)
        image[at + 3] = UInt8(truncatingIfNeeded: v)
    }

    static func addBE(_ image: inout [UInt8], _ at: Int, _ delta: UInt32) {
        writeBE(&image, at, readBE(image, at) &+ delta)
    }
}
