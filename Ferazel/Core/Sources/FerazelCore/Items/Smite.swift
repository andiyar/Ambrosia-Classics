import Foundation

/// `.SmiteEnemies @ 10052964` (M l. 46981–47046): the Ring of Smiting's strike, called by `.HandleKeys`' item switch
/// (case 0x10, M l. 47591–47595) after `.RemoveItem`, the flash 3 and snd 421.
public enum Smite {
    /// The 15 Handles the walk compares `+0x4c` with — TOC 0x100a048c…0x100a04c4, resolved with `pef.py tocfunc`
    /// (TVector → code → name) to their classes:
    /// `048c` `.HandleXichraSprite` 1008e4ec · `0490` `.HandleWizardSprite` 1008c8e8 · `0494` `.HandleWarriorSprite`
    /// 10087c04 · `0498` `.HandleWalkerSprite` 100683b8 · `049c` `.HandleSalamanderSprite` 10083074 · `04a0`
    /// `.HandleRoachSprite` 10077a88 · `04a4` `.HandleGremlinSprite` 1007feec · `04a8` `.HandleFrogSprite` 1008214c ·
    /// `04ac` `.HandleFloaterSprite` 100816d8 · `04b0` `.HandleDemonSprite` 1008a630 · `04b4` `.HandleDilloSprite`
    /// 1008697c · `04b8` `.HandleCrawlerSprite` 10065c00 · `04bc` `.HandleChiefSprite` 1008b878 · `04c0`
    /// `.HandleBlobSprite` 1007d044 · `04c4` `.HandleBatSprite` 1007e6b0. Not listed: the Crab, the Buttons.
    public static let enemyClasses: [SpriteClass] = [.xichra, .wizard, .warrior, .walker, .salamander, .roach, .gremlin,
                                                     .frog, .floater, .demon, .dillo, .crawler, .chief, .blob, .bat]

    /// The walk (raw `10052964..10052b1c`): from the list head along `+0x68`, every sprite whose Handle is one of the
    /// 15 — no `+0xe9` test — counts n down from 0x10; while n ≥ 0: `MTNewSprite(0x5a01, +0x10 − 4, +0xe − 4, 0xb, −1,
    /// .SetupPlayerShotSprite)`, `+0xf0 = 0`, `+0xa6 = 0` (stores dropped when no record is free, Ruling 16). So the
    /// first 16 matches each get a seed at their hot-rect centre − 4; the seeds (layer 0xb) are inserted into the list
    /// being walked and are passed over (their Handle is not an enemy's).
    ///
    /// The enemy Handles are not built (Phase 5): the Phase-1 enemies are `.inert` and match by their class (plan
    /// Ruling 3); an idled record (Handle 0, `handleCleared`) matches nothing. Their centre `+0x10`/`+0xe` is the one
    /// their own Handle's `.StandardSpriteCleanup` keeps every frame — for the inert stand-in it is computed here as
    /// `.CalcCenterPos` would (x + left + (right − left) / 2, y + top + (bottom − top) / 2). // later: Phase 5 — read
    /// the stored centre once the enemy Handles keep it.
    public static func smiteEnemies(_ w: SpriteWorld) {
        var n: Int16 = 0x10
        var cursor = w.active.sprites.first?.id
        while let id = cursor {
            if let s = w.active.record(id: id), isEnemy(s) {
                n -= 1
                if -1 < n {
                    let c = centre(s)
                    if let k = PlayerShot.spawn(w, type: HeldItem.seedType, x: c.x - 4, y: c.y - 4) {
                        w.active.update(id: k) { t in
                            t.seedHidden = 0
                            t.counterA6 = 0
                        }
                    }
                }
            }
            cursor = w.active.next(after: id)
        }
    }

    /// The Handle test: an inert record of one of the 15 classes (a killed sprite's type is −|type|; its Handle stays).
    static func isEnemy(_ s: SpriteSlot) -> Bool {
        guard s.handler == .inert, !s.handleCleared else { return false }
        let t = s.type < 0 ? 0 &- s.type : s.type
        guard let c = SpriteClassTable.classify(type: t, p1Negative: false)?.0 else { return false }
        return enemyClasses.contains(c)
    }

    /// The centre as the enemy's Handle would leave it (see `smiteEnemies`), 16-bit.
    static func centre(_ s: SpriteSlot) -> SpriteSlot.Point {
        let r = s.hotRect
        let h = { (v: Int) in Int(Int16(truncatingIfNeeded: v)) }
        return SpriteSlot.Point(x: h(s.x + r.left + h((r.right - r.left) >> 1)),
                                y: h(s.y + r.top + h((r.bottom - r.top) >> 1)))
    }
}
