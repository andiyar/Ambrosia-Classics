import Foundation

/// The front end's blocking waits (Phase 4, plan S1a; grounding A §1, §4, §7, B §1, D Part 2 §3). The original spins
/// in each — `TickCount` loops, the publisher-logo loop on its voice, the event loops, `Alert` — while the replica's
/// host turns each into a yield: Core puts `RenderOp.hostWait(_:)` in a pass's ops, and the host holds the op stream
/// there until the wait is over, as it holds a fade (`DeimosDriver`). The pass after the wait begins as usual.
///
/// **Input during a wait is queued, never dropped:** the events that arrive (`HeldKeys.typed`, `keyEvents`,
/// `mouseDowns`, `events`) all reach the next pass, as the original's events stay in the OS queue while it spins
/// (credits: "the fades and the 60-tick wait leave events queued", A §4). A wait that ends on input
/// (`clickOrKey`, `answer`) leaves that input queued too — the next pass reads it.
///
/// **No audio-thread read in Core** (standing rule 10): only the host asks whether a voice still sounds, and only to
/// end a wait; no logic decision in Core depends on it.
public enum HostWait: Equatable, Sendable {
    /// Until `TickCount ≥ t0 + n` (unsigned, the sum wrapping), `t0` = the tick at which the host reached the wait —
    /// the original's `t = TickCount(); while (TickCount() < t + n)` busy-waits (boot's 5, the credits' 60, the
    /// flash's F61 = 10, …). 0 releases at once.
    case ticks(UInt32)
    /// Until the named effect no longer sounds: `FUN_100476e0(id)` false — the id's last started voice has left the
    /// mixer (boot step 12, `100003b0..10000404`: the `publ` loop, no floor and no cap). With no sound system (no
    /// mixer) nothing sounds and the wait ends at once.
    case voiceEnd(FourCC)
    /// Until a mouseDown, keyDown or autoKey event is queued (the event loops that leave on "any key or click").
    case clickOrKey
    /// Until the shell answers the question the pass put (`ShellRequest.ask`): a `ShellEvent.answer` is queued.
    case answer
}
