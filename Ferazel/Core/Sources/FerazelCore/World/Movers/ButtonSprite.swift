import Foundation

/// The Button class 1320…1329 (BT; triggers-background §1, triggers-background-2 §8.5–§8.6): `.InitButtonSprite @
/// 10070c48` (M l. 61684–61700), `.SetupButtonSprite @ 10070d30` (M l. 61703–61739), `.HandleButtonSprite @ 10070e60`
/// (M l. 61742–61815) and `.HitButtonSprite @ 100710e4` (M l. 61818–61843). A Button's output is its own placement
/// record's p4 (1 while its level is ≥ 9); the gate 2940, the switch blocks 1250…1279 and the spouts 1450…1453 read it
/// (`BoxSprite`).
public enum ButtonSprite {
    /// The class's types (`SpriteClassTable`: 0x528…0x531); only 1320…1322 have a face and a hot rect.
    public static let types: ClosedRange<Int16> = 0x528...0x531
    /// `*_DAT_100a0264` = 4704 'buttondown1', `*_DAT_100a0260` = 4705 'buttonup1' (pickups-boxes-2 §1.2).
    static let downSound: Int16 = 4704, upSound: Int16 = 4705

    /// `.InitButtonSprite`'s boot sets (CLUT 200): 1320 and 1321 (6 × 0xe×0xc, 6 per row), 1322 (8 × 0x20×0x15).
    public static let sheets: [SetupFaces.Sheet] = [
        SetupFaces.Sheet(pict: 0x528, count: 6, cellWidth: 0xe, cellHeight: 0xc, columns: 6, clut: 200),
        SetupFaces.Sheet(pict: 0x529, count: 6, cellWidth: 0xe, cellHeight: 0xc, columns: 6, clut: 200),
        SetupFaces.Sheet(pict: 0x52a, count: 8, cellWidth: 0x20, cellHeight: 0x15, columns: 8, clut: 200),
    ]

    /// `.SetupButtonSprite` (M l. 61703–61739): `.InitSprite` (the slot's defaults), `+0x46 = 0`, the Button Handle
    /// and hit, no tile callback (`+0x1f8 = 0`), layer 1; the hot rect by type — 1320 `SetRect(0, −20, 20, 12)`, 1321
    /// `SetRect(−4, 0, 16, 12)`, 1322 `SetRect(8, 4, 24, 20)`, 1323…1329 none (the cleared record's empty rect: never
    /// pressed, triggers-background-2 §8.6); the position from the spawn copy (`+0xc ← +8`, `+0xa ← +6`), 24.8 from it;
    /// `+0xe4 = 0`. No face: `+0xc0` stays 0 until the first Handle.
    static func setup(_ s: inout SpriteSlot) {
        s.oldPosition = SpriteSlot.Point(x: s.x, y: s.y)                   // the spawn copy `+8` / `+6`
        s.phase = 0
        s.handler = .button
        s.hasHit = true
        s.hasTileHit = false
        s.layer = 1
        switch s.type {
        case 0x528: s.hotRect = BoxSprite.rect(0, -20, 0x14, 0xc)
        case 0x529: s.hotRect = BoxSprite.rect(-4, 0, 0x10, 0xc)
        case 0x52a: s.hotRect = BoxSprite.rect(8, 4, 0x18, 0x14)
        default: break
        }
        s.x = s.oldPosition.x
        s.y = s.oldPosition.y
        s.x256 = Int32(Int16(truncatingIfNeeded: s.x)) << 8
        s.y256 = Int32(Int16(truncatingIfNeeded: s.y)) << 8
        s.firstHandled = false
    }

    /// `.HandleButtonSprite` (M l. 61742–61815; triggers-background §1):
    /// - `.StandardSpriteHandles`; the first Handle (`+0xe4` 0): `+0xe4 = 1` and, when the live record's p4 ≠ 0, the
    ///   level `+0x46 = 10` (a pressed state restored from the record — a save-point resume, a revisit);
    /// - `+0xe9` or `+0x1b2` → nothing more;
    /// - unless (level ≥ 9 ∧ the live record's p1 == 1 — latching) the level − 1; clamped to 0…11;
    /// - level < the last Handle's `+0xa0` and that was 5 → `.STPlay3DSound(4705, 10, 0x100, centre)`;
    /// - the face: 1320 / 1321 their set's cell `level >> 1`; 1322 the level clamped to ≤ 9 (stored), cell
    ///   clamp(level − 2, 0, 7); 1323…1329 none;
    /// - a record index 0…0x1ff: the record's p4 = level ≥ 9 ? 1 : 0;
    /// - `.StandardSpriteCleanup`; `+0xa0` = the level.
    /// The record index −1 reads as zeros (the binary reads before the table; no Button is spawned without one).
    public static func handle(world w: SpriteWorld, id: Int, faceWidth: (FaceRef) -> Int) {
        w.standardSpriteHandles(id)
        guard let s0 = w.active.record(id: id) else { return }
        if !s0.firstHandled {
            let p4 = BoxSprite.liveRecord(w, s0.recordIndex)?.p4 ?? 0
            w.active.update(id: id) { s in
                s.firstHandled = true
                if p4 != 0 { s.phase = 10 }
            }
        }
        guard let s1 = w.active.record(id: id), !s1.dead, !s1.handleSkip else { return }
        let latching = (BoxSprite.liveRecord(w, s1.recordIndex)?.p1 ?? 0) == 1
        var level = s1.phase
        if level < 9 || !latching { level &-= 1 }
        if level < 0 { level = 0 } else if 0xb < level { level = 0xb }
        if Int32(level) < s1.buttonPrevious && s1.buttonPrevious == 5 {
            w.player.cue(PlayerCue(call: .threeD, snd: upSound, priority: 10, volume: 0x100, position: s1.centre))
        }
        var face = s1.face
        switch s1.type {
        case 0x528, 0x529:
            face = FaceRef(pict: s1.type, index: Int(level >> 1), set: .encoded)
        case 0x52a:
            if 9 < level { level = 9 }
            face = FaceRef(pict: s1.type, index: Int(min(max(level - 2, 0), 7)), set: .encoded)
        default:
            break
        }
        let stored = level
        w.active.update(id: id) { s in
            s.phase = stored
            s.face = face
        }
        if 0 <= s1.recordIndex && s1.recordIndex < 0x200 {
            BoxSprite.setRecord(w, s1.recordIndex, p4: stored < 9 ? 0 : 1)
        }
        w.standardSpriteCleanup(id, faceWidth: faceWidth)
        w.active.update(id: id) { $0.buttonPrevious = Int32(stored) }
    }

    /// `.HitButtonSprite(self, other)` (M l. 61818–61843): neither `+0xe9` set →
    /// - other's Handle the player's (`PTR_PTR_100a052c`), a Platform's (`_DAT_100a0200`), a Box's (`PTR_PTR_100a0484`)
    ///   or a Statue's (`PTR_PTR_100a01f8` // later: SW — no Statue Handle yet): level 0 → `.STPlay3DSound(4704, 10,
    ///   0x100, centre)`; level + 8;
    /// - an enemy shot's (`PTR_PTR_100a0488` // later: Phase 5) or a player shot's (`PTR_PTR_100a04e8`): 4704, level 11;
    /// - anything else (an idled record's Handle 0 included): nothing.
    /// Both collision passes call it: a player standing on a Button presses it twice a frame (`.MTCollideSprites`, the
    /// Button the outer sprite; `.MTCollideSpecialSprite`, after `.HitPlayerSprite`), a Box or a Platform twice too
    /// (each pair is visited from both ends).
    public static func hit(_ w: SpriteWorld, id: Int, other oID: Int) {
        guard let s = w.active.record(id: id), let o = w.active.record(id: oID), !s.dead, !o.dead else { return }
        let runs = BackgroundSprite.runs
        if runs(o, .player) || runs(o, .platform) || runs(o, .box) {
            if s.phase == 0 {
                w.player.cue(PlayerCue(call: .threeD, snd: downSound, priority: 10, volume: 0x100, position: s.centre))
            }
            w.active.update(id: id) { $0.phase &+= 8 }
        } else if runs(o, .playerShot) {
            w.player.cue(PlayerCue(call: .threeD, snd: downSound, priority: 10, volume: 0x100, position: s.centre))
            w.active.update(id: id) { $0.phase = 0xb }
        }
    }
}
