import Foundation
import HectorResources

/// One entity group (0xbc bytes, spawn-and-waves.md §1.2, HIGH) — also the record type of the pending
/// level-object list (level-scroll-objects.md §6.2, same 0xbc layout). ★ LOCKED (plan S2).
/// Not kept: +0x08 magic 0x499602d2 (checked only by the debug walker `FUN_100355b0`) and the G_GameObject
/// base the allocations construct (`FUN_100125d0`), which no group reader uses.
public struct EntityGroup: Equatable, Sendable {
    /// The permanent group's type (`10032fec lis r3,0x5045; addi r0,r3,0x524d`).
    public static let perm = FourCC("PERM")!
    /// The PERM group's id: the counter's first value (`10032f88 lis r3,0x131; addi r0,r3,0x2d00`). Also the
    /// literal `FUN_10033220` compares an owner's group id with (`100333c0 subis; cmplwi 0x2d00`).
    public static let permID: Int32 = 20_000_000

    /// +0x94: group id (−1 in a pending level-object record: serial not yet assigned).
    public var id: Int32 = -1
    /// +0x98: unit ID, or `PERM`.
    public var unit: FourCC = .none
    /// +0x9c / +0xa0: group position (float; a pending record holds the map row in y). Written by every request
    /// that opens or joins the group (`1003351c..1003357c`, PERM included). PERM's are never written by
    /// `FUN_10032e60`, so they are uninitialised heap until the first PERM request in the original; 0 here
    /// (no reader before that write is known).
    public var x: Float = 0
    public var y: Float = 0
    /// +0xa4: members requested (group size n; PERM: the last singleton request's n, stored).
    public var requested: Int32 = 0
    /// +0xa8: live members (decremented by `FUN_10036120`).
    public var live: Int32 = 0
    /// +0xac: members destroyed (not merely deleted).
    public var destroyed: Int32 = 0
    /// +0xb0: the member list — pool slot indices into `EntityWorld.entities`, appended at the tail
    /// (`FUN_100009e0`) and unlinked only by the reaper.
    public var members: [Int] = []
    /// +0xb4 / +0xb8 / +0xb9: editor heading / stationary / terrain-effects options of the request.
    public var editorHeading: Int32 = 0
    public var stationary = false
    public var terrainEffects = false

    public init() {}

    /// The tail of `FUN_10036120` (`10036378..100363a0`, after its `+0xa8 −= 1`): the group is reported empty
    /// (and freed by `FUN_10036610`) iff `+0xa8 < 1` and its type is not `PERM` — PERM persists all level.
    public var freedWhenEmpty: Bool { live < 1 && unit != Self.perm }
}
