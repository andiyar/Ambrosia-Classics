import Foundation

/// A film being played back: the decoded file and the film object's per-player cursors (+0x04 / +0x08,
/// reset to 0 by `FUN_10009970` at load) — engine-loop.md §7, loose-ends-session.md §7. ★ LOCKED (plan S2).
///
/// Listing reads for C7 (`disasm-review3-all.txt`): the film object holds the file image at +0x14, so
/// player p's frames are at +0x24 + p·0x4eac and its input bytes at +0x30 + p·0x4eac + cursor.
///
/// **How the recorder stored the score (plan G4.1).** While recording, the player update's input step
/// `FUN_1002a3a0` (life state 4 only) calls `FUN_10009830` (at `1002a42c`) instead of `FUN_100097a0`: it
/// writes the tick's input byte at the cursor, frames = cursor + 1 and +0x14 = score + 0xb3ac2 — all
/// rewritten on every recorded tick. So a film's stored score (`Film.Block.score`) is the player's score at
/// the instant the **last recorded byte** (index frames − 1) was written. The replay's equivalent instant is
/// the read that consumes that byte; `readScores[p][frames − 1]` holds the replica's score there. The read
/// at `cursor == frames` (one past the recording) is a different, later tick.
public struct FilmCursor: Equatable, Sendable {
    public let film: Film
    /// Film object +0x04 + 4·p: the next input byte index per player.
    public var cursors: [Int32] = [0, 0]
    /// The player's decoded score at the instant of its last film read (C14's input step), nil until the
    /// first read. Equal to `readScores[p].last`.
    public var scoreAtRead: [Int32?] = [nil, nil]
    /// The player's decoded score at every read, indexed by the byte index the read consumed
    /// (`readScores[p][n]` = the score when byte n was read; n = frames is the read past the recording).
    public var readScores: [[Int32]] = [[], []]

    public init(film: Film) { self.film = film }

    /// `FUN_100097a0(film, p, out) @ 100097a0` — player p's next input byte: `cursor > frames` (signed,
    /// `100097bc cmpw; bgtlr`) → no read and no advance (the caller has cleared the inputs, so 0); else the byte
    /// at the cursor (`lbz r0,0x30(r3)`, unpacked into the 7 input bytes) and cursor + 1 (`1000981c..10009824`).
    /// At `cursor == frames` the original reads the block's first byte past the recording (`bgtlr` is strict),
    /// not a hard 0. The decoded `Film.Block` keeps only the `frames` recorded bytes, so 0 is returned there; that
    /// is exact whenever `film.trailingBytesAreZero` (every shipped film — census; de01 included). A film with a
    /// non-zero trailing byte would need `Film` to expose it. The replay runs one tick past the recording, and that
    /// read still counts as a read (it advances to frames + 1).
    public mutating func next(player p: Int) -> UInt8 {
        let block = film.players[p]
        let c = cursors[p]
        if c > Int32(block.frames) { return 0 }
        cursors[p] = c &+ 1
        return c < Int32(block.frames) ? block.inputs[Int(c)] : 0
    }

    /// `next(player:)` for the player update (C14): when a read happens, `score` (the player's decoded score
    /// at that instant) is recorded at the consumed byte's index and as `scoreAtRead[p]`; no read, no record.
    public mutating func next(player p: Int, score: Int32) -> UInt8 {
        let before = cursors[p]
        let byte = next(player: p)
        if cursors[p] != before {
            readScores[p].append(score)
            scoreAtRead[p] = score
        }
        return byte
    }

    /// The score recorded at the read of byte `n` by player `p`, or nil if that read has not happened.
    public func score(player p: Int, atRead n: Int) -> Int32? {
        n >= 0 && n < readScores[p].count ? readScores[p][n] : nil
    }

    /// `FUN_10009750(film) @ 10009750` — the film is over: P1's cursor > P1's frames, signed (`xor; srawi;
    /// and; subf; rlwinm` — loose-ends-session §7). P2's frames are never checked.
    public var finished: Bool { cursors[0] > Int32(film.players[0].frames) }
}
