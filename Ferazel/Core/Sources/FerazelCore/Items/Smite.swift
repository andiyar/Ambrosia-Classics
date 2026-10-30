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

    /// The 15 Handles as `SpriteHandler` cases (EC): the eleven enemy classes of levels 1–5, the Warrior's included
    /// (0x100a0494 — Ruling 3a). The four bosses' Handles (Xichra, Wizard, Demon, Chief) have no case yet: those
    /// sprites are `.inert` and placed on no level 1–5 // later: Phase 6–7 (their Handles).
    public static let enemyHandlers: [SpriteHandler] = [.warrior, .walker, .salamander, .roach, .gremlin, .frog,
                                                        .floater, .dillo, .crawler, .blob, .bat]

    /// The walk (raw `10052964..10052b1c`): from the list head along `+0x68`, every sprite whose Handle is one of the
    /// 15 — no `+0xe9` test — counts n down from 0x10; while n ≥ 0: `MTNewSprite(0x5a01, +0x10 − 4, +0xe − 4, 0xb, −1,
    /// .SetupPlayerShotSprite)`, `+0xf0 = 0`, `+0xa6 = 0` (stores dropped when no record is free, Ruling 16). So the
    /// first 16 matches each get a seed at their stored centre − 4; the seeds (layer 0xb) are inserted into the list
    /// being walked and are passed over (their Handle is not an enemy's).
    ///
    /// The centre is the sprite's **stored** `+0x10` / `+0xe` (M l. 47036) — whatever the last `.CalcCenterPos` /
    /// `.StandardSpriteCleanup` left there — never recomputed here. An idled record (Handle 0, `handleCleared`) matches
    /// nothing; a sprite whose class is not mapped yet (`forClass` still `.inert`) matches nothing either.
    public static func smiteEnemies(_ w: SpriteWorld) {
        var n: Int16 = 0x10
        var cursor = w.active.sprites.first?.id
        while let id = cursor {
            if let s = w.active.record(id: id), isEnemy(s) {
                n -= 1
                if -1 < n {
                    let c = s.centre
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

    /// The Handle test: `+0x4c` is one of the 15 (a killed sprite keeps its Handle).
    static func isEnemy(_ s: SpriteSlot) -> Bool {
        !s.handleCleared && enemyHandlers.contains(s.handler)
    }
}
