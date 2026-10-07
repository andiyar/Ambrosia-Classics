import Foundation

/// A film being played back: the decoded file and the film object's per-player cursors (+0x04 / +0x08,
/// reset to 0 by `FUN_10009970` at load) — engine-loop.md §7, loose-ends-session.md §7. ★ LOCKED (plan S2).
///
/// Listing reads for C7 (`disasm-review3-all.txt`): the film object holds the file image at +0x14, so
/// player p's frames are at +0x24 + p·0x4eac and its input bytes at +0x30 + p·0x4eac + cursor.
public struct FilmCursor: Equatable, Sendable {
    public let film: Film
    /// Film object +0x04 + 4·p: the next input byte index per player.
    public var cursors: [Int32] = [0, 0]
    /// The player's decoded score at the instant of its last film read — written by the player update's input
    /// step (C14, `FUN_1002a3a0`), the value the recorder stored at that read (`FUN_10009830` at `1002a42c`,
    /// mid-tick — plan G4.1). nil until the first read.
    public var scoreAtRead: [Int32?] = [nil, nil]

    public init(film: Film) { self.film = film }

    /// `FUN_100097a0(film, p, out) @ 100097a0` — player p's next input byte: `cursor > frames` (signed,
    /// `100097bc cmpw; bgtlr`) → no read and no advance (the caller has cleared the inputs, so 0); else the byte
    /// at the cursor (`lbz r0,0x30(r3)`, unpacked into the 7 input bytes) and cursor + 1 (`1000981c..10009824`).
    /// At `cursor == frames` the byte read is the block's first byte past the recording — zero in every
    /// shipped film (`Film.trailingBytesAreZero`, census) — so the replay runs one tick past the recording.
    public mutating func next(player p: Int) -> UInt8 {
        let block = film.players[p]
        let c = cursors[p]
        if c > Int32(block.frames) { return 0 }
        cursors[p] = c &+ 1
        return c < Int32(block.frames) ? block.inputs[Int(c)] : 0
    }

    /// `FUN_10009750(film) @ 10009750` — the film is over: P1's cursor > P1's frames, signed (`xor; srawi;
    /// and; subf; rlwinm` — loose-ends-session §7). P2's frames are never checked.
    public var finished: Bool { cursors[0] > Int32(film.players[0].frames) }
}
