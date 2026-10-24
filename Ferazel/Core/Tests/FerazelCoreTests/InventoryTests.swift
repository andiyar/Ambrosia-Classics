import XCTest
@testable import FerazelCore

/// IV (docs/plans/2026-10-24-ferazel-phase4.md): the inventory operations on `G+0x24` (27 × 10 B) and the selection
/// `G+0x172` — `.HasItem` / `.HaveItem` (M l. 43534–43557, 39710–39733), `.HasItemWhichSlot` (M l. 43558–43582),
/// `.RemoveItem` (M l. 39602–39663), `.MoveSelectedItemToFront` (M l. 39664–39709), `.UpdateStatusBar`'s key block
/// (M l. 4885–4912), the player's row-25 selection repair (M l. 45056–45063), the pickup arms' slot searches
/// (`.HitPlayerSprite` M l. 48670–48691, 48946–48967, 48987–49013) and conversation action 2 (M l. 66286–66313).
final class InventoryTests: XCTestCase {

    private static func spell(_ id: Int16, _ count: Int16 = 1) -> InventorySlot {
        InventorySlot(id: id, count: count, field4: -1, field6: 0, isSpell: 1)
    }

    private static func item(_ id: Int16, _ count: Int16 = 1) -> InventorySlot {
        InventorySlot(id: id, count: count, field4: -1, field6: 0, isSpell: 0)
    }

    /// G with every slot `.empty` and then `slots` from slot 0.
    private func globals(_ slots: [InventorySlot], selected: Int16 = 0) -> GameGlobals {
        var g = GameGlobals()
        g.inventory = [InventorySlot](repeating: .empty, count: GameGlobals.inventorySlots)
        for (k, s) in slots.enumerated() { g.inventory[k] = s }
        g.selectedSlot = selected
        return g
    }

    func testHasItemIgnoresSpells() {
        var g = globals([Self.spell(1)])
        XCTAssertFalse(g.hasItem(1))
        XCTAssertNil(g.hasItemWhichSlot(1))
        g.inventory[3] = Self.item(1)
        g.inventory[5] = Self.item(1, 7)
        XCTAssertTrue(g.hasItem(1))
        XCTAssertEqual(g.hasItemWhichSlot(1), 3)                     // the first item slot, not the later one
        XCTAssertFalse(g.hasItem(0))                                  // id 0 is nowhere; empty slots are id −1
        XCTAssertNil(g.hasItemWhichSlot(-2))
        // Any non-zero `+8` is a spell slot to `.HasItem` (`*(char *)(+0x2c) == '\0'`).
        var g2 = globals([InventorySlot(id: 9, count: 1, field4: -1, field6: 0, isSpell: 2), Self.item(9)])
        XCTAssertEqual(g2.hasItemWhichSlot(9), 1)

        // `learnSpell` — the scroll arm's search (M l. 48946–48967): the first slot empty or holding that spell with
        // `+8 ≠ 0`; id = spell, then 2 → 3; `+8` = 1; count untouched; −1 = no slot.
        XCTAssertEqual(g2.learnSpell(9), 0)                           // flag 2 counts as a spell slot
        XCTAssertEqual(g2.inventory[0], InventorySlot(id: 9, count: 1, field4: -1, field6: 0, isSpell: 1))
        g.inventory[1] = InventorySlot(id: -1, count: 4, field4: 7, field6: 8, isSpell: 0)
        XCTAssertEqual(g.learnSpell(1), 0)                            // spell 1 in slot 0, before the empty slot 1
        XCTAssertEqual(g.inventory[0], Self.spell(1))                 // count untouched
        XCTAssertEqual(g.learnSpell(2), 1)                            // item 1 at 3 is no match; slot 1 is empty
        XCTAssertEqual(g.inventory[1], InventorySlot(id: 3, count: 4, field4: 7, field6: 8, isSpell: 1))
        XCTAssertEqual(g.learnSpell(2), 2)                            // compared before the remap (BC48): a new slot
        XCTAssertEqual(g.inventory[2].id, 3)
        XCTAssertEqual(g.learnSpell(3), 1)                            // the remapped Ice Wall slot
        XCTAssertEqual(g.learnSpell(1), 0)
        var full = globals([InventorySlot](repeating: Self.item(4), count: GameGlobals.inventorySlots))
        let before = full
        XCTAssertEqual(full.learnSpell(4), -1)                        // item 4 everywhere: no spell slot, no empty
        XCTAssertEqual(full, before)
    }

    func testRemoveItemShiftsAndKeepsFlag() {
        let start = [Self.spell(0), Self.item(0), Self.item(1), Self.item(4)]
        var g = globals(start, selected: 3)
        g.inventory[26] = InventorySlot(id: 12, count: 5, field4: 6, field6: 7, isSpell: 1)
        XCTAssertTrue(g.removeItem(1))
        XCTAssertEqual(Array(g.inventory[0..<3]), [Self.spell(0), Self.item(0), Self.item(4)])
        XCTAssertEqual(g.inventory[3], .empty)
        XCTAssertEqual(g.inventory[24], .empty)
        XCTAssertEqual(g.inventory[25], InventorySlot(id: 12, count: 5, field4: 6, field6: 7, isSpell: 1))
        XCTAssertEqual(g.inventory[26], InventorySlot(id: -1, count: 0, field4: -1, field6: 0, isSpell: 1))
        XCTAssertEqual(g.selectedSlot, 3)                             // not the removed slot: unchanged

        var h = globals(start, selected: 2)
        XCTAssertTrue(h.removeItem(1))
        XCTAssertEqual(h.selectedSlot, 1)
        XCTAssertEqual(h.inventory[2], Self.item(4))
        XCTAssertEqual(h.inventory[26].isSpell, 0)

        var z = globals([Self.item(5), Self.item(6)], selected: 0)
        XCTAssertTrue(z.removeItem(5))
        XCTAssertEqual(z.selectedSlot, 0)                             // −1 floored at 0
        XCTAssertEqual(z.inventory[0], Self.item(6))
        // The removed slot is the first ITEM slot holding the id: spell 4 at 0 is skipped, item 4 at 1 goes.
        var s = globals([Self.spell(4), Self.item(4), Self.item(4, 2)], selected: 1)
        XCTAssertTrue(s.removeItem(4))
        XCTAssertEqual(Array(s.inventory[0..<3]), [Self.spell(4), Self.item(4, 2), .empty])
        XCTAssertEqual(s.selectedSlot, 0)
    }

    func testRemoveItemCountAndMissing() {
        var g = globals([Self.spell(6), Self.item(2), Self.item(6, 3)], selected: 2)
        XCTAssertTrue(g.removeItem(6))
        XCTAssertEqual(g.inventory[2], Self.item(6, 2))
        XCTAssertEqual(g.inventory[0], Self.spell(6))
        XCTAssertEqual(g.inventory[3], .empty)
        XCTAssertEqual(g.selectedSlot, 2)
        let before = g
        XCTAssertFalse(g.removeItem(7))
        XCTAssertFalse(g.removeItem(0))                               // item 0 nowhere (spell 6, items 2 and 6)
        XCTAssertEqual(g, before)

        // `addItem` — the item / Red Xichron arms' search (M l. 48670–48691, 48987–49013) = action 2's
        // (M l. 66291–66309): the first slot empty or holding the item with `+8` 0; id, count + n, > 99 → 99, `+8` 0.
        var a = globals([Self.spell(6), InventorySlot(id: -1, count: 0, field4: -1, field6: 0, isSpell: 1),
                         Self.item(6, 3)])
        XCTAssertEqual(a.addItem(6, count: 1), 1)                     // the empty slot 1 comes before item 6 at 2
        XCTAssertEqual(a.inventory[1], Self.item(6, 1))               // `+8` 1 → 0
        XCTAssertEqual(a.addItem(6, count: 3), 1)
        XCTAssertEqual(a.inventory[1].count, 4)
        a.inventory[1].count = 98
        XCTAssertEqual(a.addItem(6, count: 3), 1)
        XCTAssertEqual(a.inventory[1].count, 99)
        XCTAssertEqual(a.addItem(6, count: -5), 1)                    // a negative count is added as-is (BC30)
        XCTAssertEqual(a.inventory[1].count, 94)
        XCTAssertEqual(a.inventory[2], Self.item(6, 3))
        var full = globals([InventorySlot](repeating: Self.spell(4), count: GameGlobals.inventorySlots))
        let fullBefore = full
        XCTAssertEqual(full.addItem(4, count: 1), -1)                 // spell 4 everywhere: no item slot, no empty
        XCTAssertEqual(full, fullBefore)
    }

    func testMoveSelectedToFront() {
        let start = [Self.spell(0), Self.item(0), Self.item(1), Self.item(4)]
        var g = globals(start, selected: 3)
        XCTAssertTrue(g.moveSelectedItemToFront())
        XCTAssertEqual(Array(g.inventory[0..<5]), [Self.item(4), Self.spell(0), Self.item(0), Self.item(1), .empty])
        XCTAssertEqual(g.selectedSlot, 0)
        let before = g
        XCTAssertFalse(g.moveSelectedItemToFront())
        XCTAssertEqual(g, before)
        var one = globals(start, selected: 1)
        XCTAssertTrue(one.moveSelectedItemToFront())
        XCTAssertEqual(Array(one.inventory[0..<4]), [Self.item(0), Self.spell(0), Self.item(1), Self.item(4)])

        // Row 25's repair (M l. 45056–45063): the selected slot empty → 0, or −1 when slot 0 is empty too.
        var r = globals(start, selected: 5)
        r.repairSelection()
        XCTAssertEqual(r.selectedSlot, 0)
        r.selectedSlot = 3
        r.repairSelection()
        XCTAssertEqual(r.selectedSlot, 3)                             // a filled slot stays
        var e = globals([], selected: 4)
        e.repairSelection()
        XCTAssertEqual(e.selectedSlot, -1)
        e.inventory[0] = Self.item(2)
        e.repairSelection()
        XCTAssertEqual(e.selectedSlot, -1)                            // slot "−1" reads the zero gap at G+0x1a: kept
    }

    func testStepSelectionRepeat() {
        var g = globals([Self.spell(0), Self.item(0), Self.item(1)], selected: 0)
        var counter = 0
        var steps: [Int] = []
        var counters: [Int] = []
        for call in 1...14 {
            if g.stepSelection(next: true, previous: false, repeat: &counter) { steps.append(call) }
            counters.append(counter)
        }
        XCTAssertEqual(steps, [1, 14])
        XCTAssertEqual(counters, [12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0, 12])
        XCTAssertEqual(g.selectedSlot, 2)
        XCTAssertFalse(g.stepSelection(next: false, previous: false, repeat: &counter))
        XCTAssertEqual(counter, 0)
        XCTAssertEqual(g.selectedSlot, 2)
        XCTAssertTrue(g.stepSelection(next: false, previous: true, repeat: &counter))
        XCTAssertEqual(counter, 12)
        XCTAssertEqual(g.selectedSlot, 1)                             // only 7 held: −1
        XCTAssertFalse(g.stepSelection(next: true, previous: true, repeat: &counter))
        XCTAssertEqual(counter, 11)
        counter = 0
        XCTAssertTrue(g.stepSelection(next: true, previous: true, repeat: &counter))
        XCTAssertEqual(g.selectedSlot, 2)                             // both held: key 8 wins, +1
    }

    func testStepSelectionWraps() {
        var g = globals([Self.spell(0), Self.item(0), Self.item(1)], selected: 0)
        var counter = 0
        XCTAssertTrue(g.stepSelection(next: false, previous: true, repeat: &counter))
        XCTAssertEqual(g.selectedSlot, 2)                             // 0x1a, then down past the empty slots
        counter = 0
        XCTAssertTrue(g.stepSelection(next: true, previous: false, repeat: &counter))
        XCTAssertEqual(g.selectedSlot, 0)                             // slot 3 empty → 0
        var full = globals([InventorySlot](repeating: Self.item(1), count: GameGlobals.inventorySlots), selected: 26)
        counter = 0
        XCTAssertTrue(full.stepSelection(next: true, previous: false, repeat: &counter))
        XCTAssertEqual(full.selectedSlot, 0)                          // 27 > 0x1a → 0
        counter = 0
        XCTAssertTrue(full.stepSelection(next: false, previous: true, repeat: &counter))
        XCTAssertEqual(full.selectedSlot, 26)                         // −1 → 0x1a, filled: stays
        var e = globals([], selected: 0)
        counter = 0
        XCTAssertTrue(e.stepSelection(next: false, previous: true, repeat: &counter))
        XCTAssertEqual(e.selectedSlot, -1)                            // down to "slot −1", the zero gap ≠ −1: kept
    }
}
