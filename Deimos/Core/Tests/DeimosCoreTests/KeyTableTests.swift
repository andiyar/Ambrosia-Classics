import XCTest
@testable import DeimosCore

/// The prefs key table → `PlayerInput` (timing-frame §6, design §7.3).
final class KeyTableTests: XCTestCase {
    /// Fresh prefs (`1000515c..10005194`): P1 ↑ ← → ↓ ⌘ ⌥ Space, P2 kp8 kp4 kp6 kp5 End Fwd-Del PgDn; slots up,
    /// left, right, down, fire air, fire ground, select.
    func testKeyTableDefaults() {
        let table = KeyTable(prefs: .fresh)
        XCTAssertEqual(table.codes, [0x7E, 0x7B, 0x7C, 0x7D, 0x37, 0x3A, 0x31, 0x5B, 0x56, 0x58, 0x57, 0x77, 0x75, 0x79])
        let bits: [PlayerInput] = [.up, .left, .right, .down, .fireAir, .fireGround, .select]
        let p1: [UInt16] = [0x7E, 0x7B, 0x7C, 0x7D, 0x37, 0x3A, 0x31]
        let p2: [UInt16] = [0x5B, 0x56, 0x58, 0x57, 0x77, 0x75, 0x79]
        for (slot, bit) in bits.enumerated() {
            XCTAssertEqual(table.inputs(HeldKeys(held: [p1[slot]])), [bit, PlayerInput()] as [PlayerInput], "P1 slot \(slot)")
            XCTAssertEqual(table.inputs(HeldKeys(held: [p2[slot]])), [PlayerInput(), bit] as [PlayerInput], "P2 slot \(slot)")
        }
        XCTAssertEqual(table.input(HeldKeys(held: Set(p1 + p2)), player: 0).rawValue, 0x7F)
        XCTAssertEqual(table.input(HeldKeys(held: Set(p1 + p2)), player: 1).rawValue, 0x7F)
        // Keys outside the table (Esc, A) map to nothing; a short table leaves the missing slots unmapped.
        XCTAssertEqual(table.inputs(HeldKeys(held: [0x35, 0x00])), [PlayerInput(), PlayerInput()])
        XCTAssertEqual(KeyTable(codes: [0x7E]).inputs(HeldKeys(held: [0x7E, 0x7B])), [PlayerInput.up, PlayerInput()])
    }
}
