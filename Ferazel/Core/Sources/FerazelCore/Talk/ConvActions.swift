import Foundation

/// `.HandleLineActions(&index, recIdx) @ 1007a0fc` (M l. 66164–66376; conversations-mcnv §3.4, BC30) and the target
/// conversion the three target fields share (§2.3). The line's condition, its two actions and its next, on the live
/// state: G (`_DAT_1009ffc0`: coins, inventory, world flags), the level's live records (`*_DAT_100a0058`), the talker
/// (`*PTR_DAT_100a0bec`) and the save block (`*_DAT_100a0054`, action 10).
enum ConvActions {
    /// `t == 20 → 999`; then `t > 0 → t − 1`, `t < 0 → t + 1` (raw `1007a078..1007a0b4`, `1007a264..1007a2a4`,
    /// `1007a58c..1007a5c8`).
    static func convert(_ t: Int16) -> Int16 {
        let v: Int16 = t == 0x14 ? 999 : t
        if 0 < v { return v - 1 }
        if v < 0 { return v + 1 }
        return v
    }

    /// The condition (M l. 66191–66232, raw `1007a148..1007a258`): 0 → none; 1 coins `G+0x10` ≥ A (signed, raw
    /// `1007a188..1007a1a0`); 2 some slot k < 27 holds item A (spell flag `+0x2c` 0) with count ≥ B (no early exit);
    /// 3 never (raw `1007a154..1007a160`); 4 `0 ≤ recIdx < 0x200` and the **low byte** of own record p(A+1) ≠ 0
    /// (`& 0xff`, raw `1007a200..1007a234`); 5 world flag `G+0xad8+2A == B`; < 0 or > 5 never.
    static func condition(_ line: Conversation.Line, record: Int, world w: SpriteWorld) -> Bool {
        let a = line.conditionA, b = line.conditionB
        switch line.conditionType {
        case 1:
            return a <= w.globals.coins
        case 2:
            var hit = false
            for slot in w.globals.inventory where slot.id == a && slot.isSpell == 0 && b <= slot.count { hit = true }
            return hit
        case 4:
            guard 0 <= record, record < 0x200 else { return false }
            return recordWord(w, offset: record * 16 + 4 + 2 * Int(a)) & 0xff != 0
        case 5:
            let i = Int(a)
            return w.globals.worldFlags.indices.contains(i) && w.globals.worldFlags[i] == b
        default:
            return false
        }
    }

    /// The two actions in order (M l. 66251–66357, jump table `0x100a6cd0`, raw `1007a2ac..1007a568`):
    /// - 1 coins −= A, floor 0; `.UpdateTextStats(0)` (the coin / score text — the status bar op);
    /// - 2 give item A × (B == 0 ? 1 : B) — a negative B is added as-is (BC30, M l. 66288–66290): the first slot that is
    ///   empty (id −1) or holds item A with spell flag 0; flag 0, id A, count += B, > 99 → 99; `.STPlayRegSound(snd 501,
    ///   1, 0x100)` (`*_DAT_100a02d4`, [MED] the loader); `.UpdateItemStat` (// later: Phase 4 ◇ — the HUD inventory);
    ///   `*0x1024b4cc = slot`, `*0x1024b4ca = 30` (no reader, conversations-mcnv NR 2: not kept). No slot → nothing;
    /// - 3 `.RemoveItem(A)` max(B, 1) times, `.UpdateItemStat`;
    /// - 4 `0 ≤ recIdx < 0x200` → own record p(A+1) = 1; 5 world flag A = B; 6 record A's p(B+1) = 1 (no range check);
    /// - 9 the talker ≠ 0 → its `+0xe9 = 1` (kill request) and its record's spawn byte (`+0`) = 0;
    /// - 10 the save block's level-B snapshot record A spawn byte (`+0x19998 + 0x2000·B + 16·A`) = 1;
    /// - 0, 7, 8 (and any other) nothing.
    /// Writes outside the modelled arrays (the original would write past them; no shipped line does) are dropped.
    static func run(_ act: Conversation.Action, record: Int, talker: Int?, world w: SpriteWorld, save: inout SaveBlock,
                    prefs: FerazelPrefs, levelName: String, into out: inout FrontOutput) {
        let a = act.a, b = act.b
        switch act.type {
        case 1:
            w.globals.coins = w.globals.coins &- a
            if w.globals.coins < 0 { w.globals.coins = 0 }
            out.draws.append(.statusBar(w.globals.statusBar(levelName: levelName)))
        case 2:
            let n: Int16 = b == 0 ? 1 : b
            var found: Int?
            for k in 0..<GameGlobals.inventorySlots {
                let s = w.globals.inventory[k]
                if s.id == -1 || (s.id == a && s.isSpell == 0) {
                    found = k
                    break
                }
            }
            guard let k = found else { return }
            var s = w.globals.inventory[k]
            s.isSpell = 0
            s.id = a
            s.count = s.count &+ n
            if 99 < s.count { s.count = 99 }
            w.globals.inventory[k] = s
            let call = PlayerState.SoundCall(cue: PlayerCue(call: .reg, snd: 501, priority: 1, volume: 0x100),
                                             scrollH: 0, scrollV: 0)
            if case .play(let cue)? = SoundCues.convert(call, prefs: prefs) { out.sounds.append(cue) }
            // later: Phase 4 ◇ — `.UpdateItemStat` (the HUD inventory).
        case 3:
            for _ in 0..<max(1, Int(b)) { removeItem(a, from: &w.globals) }
            // later: Phase 4 ◇ — `.UpdateItemStat`.
        case 4:
            if 0 <= record && record < 0x200 { setRecordWord(w, offset: record * 16 + 4 + 2 * Int(a), 1) }
        case 5:
            let i = Int(a)
            if w.globals.worldFlags.indices.contains(i) { w.globals.worldFlags[i] = b }
        case 6:
            setRecordWord(w, offset: Int(a) * 16 + 4 + 2 * Int(b), 1)
        case 9:
            guard let t = talker, let s = w.active.record(id: t) else { return }
            w.active.update(id: t) { $0.dead = true }
            let i = Int(s.recordIndex)
            if w.records.indices.contains(i) {
                let r = w.records[i]
                w.records[i] = Placement(index: r.index, flag: 0, byte1: r.byte1, type: r.type, p1: r.p1, p2: r.p2,
                                         p3: r.p3, p4: r.p4, y: r.y, x: r.x)
            }
        case 10:
            let L = Int(b), i = Int(a)
            guard save.snapshots.indices.contains(L), save.snapshots[L].indices.contains(i) else { return }
            let r = save.snapshots[L][i]
            save.snapshots[L][i] = Placement(index: r.index, flag: 1, byte1: r.byte1, type: r.type, p1: r.p1, p2: r.p2,
                                             p3: r.p3, p4: r.p4, y: r.y, x: r.x)
        default:
            break
        }
    }

    /// `.RemoveItem(A) @ 10045594` (M l. 39602–39655): the first item slot (spell flag 0) holding A: count − 1; below 1
    /// the selection `G+0x172` moves back one when it was that slot (floor 0), the slots after it move up one (10 bytes
    /// each, through slot 26) and slot 26 becomes {−1, 0, −1, 0} (its `+8` byte as it was). Not held → nothing.
    static func removeItem(_ id: Int16, from g: inout GameGlobals) {
        guard let k = g.inventory.firstIndex(where: { $0.id == id && $0.isSpell == 0 }) else { return }
        g.inventory[k].count = g.inventory[k].count &- 1
        guard g.inventory[k].count < 1 else { return }
        if Int(g.selectedSlot) == k {
            g.selectedSlot -= 1
            if g.selectedSlot < 0 { g.selectedSlot = 0 }
        }
        let last = GameGlobals.inventorySlots - 1
        for j in k..<last { g.inventory[j] = g.inventory[j + 1] }
        g.inventory[last].id = -1
        g.inventory[last].count = 0
        g.inventory[last].field4 = -1
        g.inventory[last].field6 = 0
    }

    // MARK: The live records as the code addresses them

    /// The i16 at `offset` bytes from record 0 (`hdr + 4`; the code's `*hdl + 16·r + 8 + 2·k` = record r's p(k+1) at
    /// `16·r + 4 + 2·k`): +0 flag/byte1, +2 type, +4 p1 … +0xa p4, +0xc y, +0xe x. Outside the 511 records → 0.
    static func recordWord(_ w: SpriteWorld, offset o: Int) -> Int16 {
        guard 0 <= o, o / 16 < w.records.count else { return 0 }
        let r = w.records[o / 16]
        switch o % 16 {
        case 0: return Int16(bitPattern: UInt16(r.flag) << 8 | UInt16(r.byte1))
        case 2: return r.type
        case 4: return r.p1
        case 6: return r.p2
        case 8: return r.p3
        case 10: return r.p4
        case 12: return r.y
        case 14: return r.x
        default: return 0
        }
    }

    /// Stores `v` at `offset` (see `recordWord`); outside the records → dropped.
    static func setRecordWord(_ w: SpriteWorld, offset o: Int, _ v: Int16) {
        guard 0 <= o, o / 16 < w.records.count else { return }
        let r = w.records[o / 16]
        var flag = r.flag, byte1 = r.byte1, type = r.type, p1 = r.p1, p2 = r.p2, p3 = r.p3, p4 = r.p4, y = r.y, x = r.x
        switch o % 16 {
        case 0:
            flag = UInt8(UInt16(bitPattern: v) >> 8)
            byte1 = UInt8(UInt16(bitPattern: v) & 0xff)
        case 2: type = v
        case 4: p1 = v
        case 6: p2 = v
        case 8: p3 = v
        case 10: p4 = v
        case 12: y = v
        case 14: x = v
        default: return
        }
        w.records[o / 16] = Placement(index: r.index, flag: flag, byte1: byte1, type: type, p1: p1, p2: p2, p3: p3,
                                      p4: p4, y: y, x: x)
    }
}
