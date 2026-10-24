import Foundation

/// The inventory operations on `G+0x24` (27 slots × 10 B, `InventorySlot`) and the selection `G+0x172`
/// (spells-items §1, BC37). Status bar ops are the caller's: `removeItem` true → `.UpdateItemStat`,
/// `moveSelectedItemToFront` true → `.UpdateStatusBar(1,1,0)`.
extension GameGlobals {
    /// The i16 the code reads as "slot `k`'s id" (`G + 0x24 + 10·k`). Slot −1's id is `G+0x1a`, inside the
    /// never-written gap `+0x18..+0x1f` (Phase 3 Invariant 7) → 0; the selection never leaves −1…26 (`stepSelection`,
    /// `repairSelection`), any other value also reads 0 here (not modelled).
    private func slotWord(_ k: Int16) -> Int16 {
        inventory.indices.contains(Int(k)) ? inventory[Int(k)].id : 0
    }

    /// `.HasItem(A) @ 1004c0e0` (M l. 43534–43557) = `.HaveItem(A) @ 100457d0` (M l. 39710–39733): some slot holds
    /// item A (`+8 == 0`).
    public func hasItem(_ id: Int16) -> Bool {
        hasItemWhichSlot(id) != nil
    }

    /// `.HasItemWhichSlot(A, &slot) @ 1004c148` (M l. 43558–43582): the first slot with id A and `+8 == 0`.
    public func hasItemWhichSlot(_ id: Int16) -> Int? {
        inventory.firstIndex { $0.id == id && $0.isSpell == 0 }
    }

    /// `.RemoveItem(A) @ 10045594` (M l. 39602–39663): the first item slot (`+8 == 0`) holding A: count − 1; below 1
    /// the selection −1 (floor 0) **only when it is that slot**, the slots after it move down one (all 10 bytes, M l.
    /// 39637–39646) and slot 26 becomes id −1, count 0, `+4` −1, `+6` 0 with its `+8` byte as it was (M l.
    /// 39647–39650). True = found (the caller's `.UpdateItemStat`, M l. 39652); not held → nothing, false.
    @discardableResult
    public mutating func removeItem(_ id: Int16) -> Bool {
        guard let k = hasItemWhichSlot(id) else { return false }
        inventory[k].count = inventory[k].count &- 1
        guard inventory[k].count < 1 else { return true }
        if Int(selectedSlot) == k {
            selectedSlot -= 1
            if selectedSlot < 0 { selectedSlot = 0 }
        }
        let last = GameGlobals.inventorySlots - 1
        for j in k..<last { inventory[j] = inventory[j + 1] }
        inventory[last].id = -1
        inventory[last].count = 0
        inventory[last].field4 = -1
        inventory[last].field6 = 0
        return true
    }

    /// `.MoveSelectedItemToFront @ 100456e8` (M l. 39664–39709): selection ≠ 0 → its slot to slot 0, slots 0…sel−1
    /// down one, selection 0; true = moved (the caller's `.UpdateStatusBar(1,1,0)`). Selection 0 → nothing, false.
    /// A selection outside 1…26 (only −1 can occur: the empty inventory) would copy "slot −1" — `G+0x1a..+0x23`: the
    /// gap words at `+0x1a`/`+0x1c`/`+0x1e`, then `G+0x20` (as `+6`) and `G+0x22` (as the flag byte) — into slot 0 in
    /// the binary — not modelled: nothing, false.
    @discardableResult
    public mutating func moveSelectedItemToFront() -> Bool {
        let sel = Int(selectedSlot)
        guard sel != 0, inventory.indices.contains(sel) else { return false }
        let moved = inventory[sel]
        for j in stride(from: sel, to: 0, by: -1) { inventory[j] = inventory[j - 1] }
        inventory[0] = moved
        selectedSlot = 0
        return true
    }

    /// The item pickup search — `.HitPlayerSprite`'s Red Xichron arm (M l. 48670–48691, n = 1), its items arm 3200…
    /// (M l. 48987–49013, n = 1 or 3) and conversation action 2 (M l. 66286–66313, n = B or 1; a negative n is added
    /// as-is): the first slot that is empty (id −1) **or** holds item A with `+8 == 0`; id A, count + n, > 99 → 99,
    /// `+8` = 0. Returns the slot (the arms' highlight / sound need it), −1 = no slot (nothing written).
    @discardableResult
    public mutating func addItem(_ id: Int16, count n: Int16) -> Int {
        guard let k = inventory.firstIndex(where: { $0.id == -1 || ($0.id == id && $0.isSpell == 0) }) else {
            return -1
        }
        inventory[k].id = id
        inventory[k].count = inventory[k].count &+ n
        if 99 < inventory[k].count { inventory[k].count = 99 }
        inventory[k].isSpell = 0
        return k
    }

    /// The scroll arm's search (`.HitPlayerSprite` M l. 48946–48967): the first slot that is empty (id −1) **or**
    /// holds spell A with `+8 ≠ 0` — compared before the remap (BC48); id A, then 2 → 3; `+8` = 1; count untouched.
    /// Returns the slot, −1 = no slot (nothing written; the arm returns at once).
    @discardableResult
    public mutating func learnSpell(_ id: Int16) -> Int {
        guard let k = inventory.firstIndex(where: { $0.id == -1 || ($0.id == id && $0.isSpell != 0) }) else {
            return -1
        }
        inventory[k].id = id
        if inventory[k].id == 2 { inventory[k].id = 3 }
        inventory[k].isSpell = 1
        return k
    }

    /// `.UpdateStatusBar`'s key block (M l. 4885–4912): neither Next (key 8) nor Previous (7) → `counter`
    /// (`*_DAT_1009fd9c`, a byte) = 0; else counter 0 → counter 12 and the selection +1 (8 held) or −1 (only 7);
    /// below 0 → 0x1a, then down while that slot's id is −1; above 0x1a or an empty slot → 0; returns true ("stepped",
    /// `bVar1`). Counter > 0 → counter − 1.
    public mutating func stepSelection(next: Bool, previous: Bool, repeat counter: inout Int) -> Bool {
        guard next || previous else {
            counter = 0
            return false
        }
        guard counter == 0 else {
            counter -= 1
            return false
        }
        counter = 12
        selectedSlot = next ? selectedSlot &+ 1 : selectedSlot &- 1
        if selectedSlot < 0 {
            selectedSlot = 0x1a
            while slotWord(selectedSlot) == -1 { selectedSlot -= 1 }
        }
        if 0x1a < selectedSlot || slotWord(selectedSlot) == -1 { selectedSlot = 0 }
        return true
    }

    /// `.HandlePlayerSprite` row 25's repair (M l. 45056–45063): the selected slot's id −1 → the selection 0, or −1
    /// (0xffff) when slot 0 is empty too.
    public mutating func repairSelection() {
        guard slotWord(selectedSlot) == -1 else { return }
        selectedSlot = inventory[0].id == -1 ? -1 : 0
    }
}
