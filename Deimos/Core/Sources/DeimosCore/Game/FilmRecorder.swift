import Foundation
import HectorResources

/// The Last Film recorder (Phase 4 S5; grounding B §4a): the film object's image while a non-film session records
/// into it, with the per-player cursors. ★ New in Phase 4.
///
/// Listing reads (`disasm-review3-all.txt`; the OS X build is the same, `docs/deimos/osx-build.md`):
/// - **Constructor** `FUN_10009390` (`100093a0..100093e0`, from the session's set-up at `10005634`, every session):
///   the 0x9d68-byte image zeroed (`FUN_1000cd90(+0x14, 0x9d68)`), version 0x2715 at image 0, the cursors 0
///   (`FUN_10009970`).
/// - **Set-up** `FUN_10009710(film, level, players, seed)` (`10009710..10009748`; called at `100057ec` on the not-a-film
///   branch only, after `srand(TickCount())` with the same `TickCount`): image 0x08 = the START level (the request's
///   +0), 0x0c = players (byte), 0x04 = seed; each block's frames 0, score 0 (raw — not biased), level `none`; both
///   cursors 0.
/// - **Write** `FUN_10009830(film, p, inputs, score)` (`10009830..10009964`; from `FUN_1002a3a0` at `1002a42c`, the
///   live input branch, life state 4): cursor = +4 + 4p; `cmplwi cursor, 0x4e20; bge` → nothing at all (the block
///   is frozen at 20,000); else the byte at block + 0xc + cursor = 0, then OR'd bit 0 left, 1 right, 2 up, 3 down,
///   4 fire ground, 5 fire air, 6 select (`1000986c..10009918`); cursor += 1; frames = cursor; score field = score +
///   0xb3ac2 (`addis 0xb; addi 0x3ac2`); level field = `FUN_10005cc0()` = G+0x18, the CURRENT level (`10009940`).
///   `score` is the decoded score (`+0xb0 − 0x5532a3e`, `1002a414..1002a428`) at the write.
public struct FilmRecorder: Equatable, Sendable {
    /// The film image (the file `FUN_100095b0` saves): `Film.size` bytes.
    public private(set) var image: [UInt8]
    /// The film object's cursors +0x04 / +0x08: the next input byte index per player.
    public private(set) var cursors: [Int] = [0, 0]

    /// `FUN_10009390` then `FUN_10009710(film, level, players, seed)`.
    public init(seed: UInt32, level: FourCC, players: Int) {
        var b = [UInt8](repeating: 0, count: Film.size)                      // 100093b4..100093b8 FUN_1000cd90
        Film.store(Film.version, at: 0, in: &b)                              // 100093c0..100093c4
        Film.store(level.rawValue, at: 8, in: &b)                            // 10009710 stw r4,0x1c(r3)
        b[0x0c] = UInt8(truncatingIfNeeded: players)                         // 1000971c stb r5,0x20(r3)
        Film.store(seed, at: 4, in: &b)                                      // 10009724 stw r6,0x18(r3)
        for base in Film.blockOffsets {                                      // 10009728..10009744
            Film.store(0, at: base, in: &b)                                  // frames
            Film.store(0, at: base + 4, in: &b)                              // score, raw 0
            Film.store(FourCC.none.rawValue, at: base + 8, in: &b)           // level `none`
        }
        image = b
    }

    /// `FUN_10009830(film, p, inputs, score)` with G+0x18 = `level`: player `p`'s (0 or 1) input byte for this tick,
    /// unless the block already holds 20,000 (then nothing changes).
    public mutating func record(player p: Int, input: PlayerInput, score: Int32, level: FourCC) {
        precondition(p == 0 || p == 1, "FilmRecorder.record: player \(p) is not 0 or 1")
        let cursor = cursors[p]                                              // 10009854
        guard cursor < Film.maxFrames else { return }                       // 10009858..1000985c (unsigned < 0x4e20)
        let base = Film.blockOffsets[p]
        image[base + 0xc + cursor] = input.rawValue & 0x7f                   // 1000986c..10009918
        cursors[p] = cursor + 1                                              // 1000991c..1000992c
        Film.store(UInt32(cursors[p]), at: base, in: &image)                 // 10009938 frames = cursor
        Film.store(UInt32(bitPattern: score) &+ Film.scoreBias, at: base + 4, in: &image)   // 10009920..1000993c
        Film.store(level.rawValue, at: base + 8, in: &image)                 // 10009940..1000994c FUN_10005cc0
    }
}
