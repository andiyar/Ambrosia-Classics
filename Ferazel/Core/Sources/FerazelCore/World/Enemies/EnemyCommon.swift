import Foundation

/// The counting window and the live-enemy count (plan S2 `EnemyCounting`, EC; enemies-ground §2.5, enemies-flyers
/// §1.2, enemies-ground-2 §4). `window` is `*_DAT_1009fe8c`: `.SetupLevel` zeroes the three tallies, stores 1, calls
/// `.SetupLevelSprites` and stores 0 (M l. 2521–2526; raw `10004da4..10004dc0`). `live` is `*_DAT_1009ffb4`, which
/// `.SetupLevel` then copies into the level's total `G+0x6ee+2·L` on a first visit (M l. 2528–2536). Pipe children,
/// spawned shots and re-activated idle sprites (`.IdleToActiveSprite` runs no Setup) are never counted.
public struct EnemyCounting: Equatable, Sendable {
    /// `*_DAT_1009fe8c`.
    public var window: Bool
    /// `*_DAT_1009ffb4` (i32).
    public var live: Int32

    public init(window: Bool = false, live: Int32 = 0) {
        self.window = window
        self.live = live
    }

    /// The Setup idiom at the end of every counted class Setup (`.SetupWalkerSprite` M l. 57090–57094,
    /// `.SetupCrawlerSprite` M l. 56236–56240, …): only while the window is set, `+0x1b5 = 1` and live + 1.
    public mutating func countIfWindow(_ s: inout SpriteSlot) {
        guard window else { return }
        s.countedInTotals = true
        live &+= 1
    }

    /// The Kill idiom (`.KillCrawler` M l. 56695–56701, `.KillWalker` M l. 58624–58629, `.KillWarrior` M l.
    /// 73479–73485 and every other enemy Kill): `+0xe9 == 0 && +0x1b5 ≠ 0` → live − 1 and the enemies stat
    /// `G+0x306+2·L` + 1; then `+0xe9 = 1` unconditionally and `+0xea = 1` where the class's Kill stores it (`forGood`:
    /// every enemy Kill but `.KillWalker`'s — `killsForGood`). `.KillGremlinSprite` returns at once while `+0xe9 ≠ 0`
    /// (M l. 69736–69738) — its caller's guard.
    public mutating func kill(_ s: inout SpriteSlot, globals: inout GameGlobals, level: Int, forGood: Bool = false) {
        if s.killCount == 0 && s.countedInTotals {
            live &-= 1
            if (0..<GameGlobals.levelSlots).contains(level) { globals.achieved[0][level] &+= 1 }
        }
        s.killCount = 1
        if forGood { s.killedForGood = true }
    }

    /// The classes whose Kill stores `+0xea = 1` (scan of the 13 enemy Kills, M l. 56701 Crawler, 65218 Roach, 68052
    /// Blob, 69037 Bat, 69746 Gremlin, 70575 Frog, 70934 Salamander, 72935 Dillo, 73485 Warrior; not `.KillWalker`).
    /// The Floater, the swarm members, the Crab and the shots have no counting Kill.
    public static func killsForGood(_ h: SpriteHandler) -> Bool {
        switch h {
        case .crawler, .roach, .blob, .bat, .gremlin, .frog, .salamander, .dillo, .warrior: return true
        default: return false
        }
    }
}

/// What the enemy classes share (plan S2 `EnemyCommon`, EC): the Handle stand-in with the `+0x1b2` early return, the
/// Kill proc `+0x50`, the goblin voice helpers, `.HurtGoblin`, the crush tests, the environmental hazards, the
/// liquids table, the enemies' statue and the burn start. `.HurtSprite` is `HurtSprite.apply`.
public enum EnemyCommon {
    /// snd slots (`.InitSounds`, `SoundSlots`): 465 `_DAT_100a0350`, 466 `_DAT_100a034c`, 467 `_DAT_100a0348`,
    /// 468 `_DAT_100a0344` (goblingrowl1 / goblingrowl2 / goblintaunt / goblinhurt), 611 `_DAT_100a029c`, 612
    /// `_DAT_100a0298` (axgoblinhit1 / 2), 701 `_DAT_100a0274` (Crawler Ouch).
    public static let growl1: Int16 = 465, growl2: Int16 = 466, taunt: Int16 = 467, hurtCry: Int16 = 468
    public static let axHit1: Int16 = 611, axHit2: Int16 = 612, ouch: Int16 = 701

    /// The class Handles (`+0x4c`) of the enemy cases. Every one returns at once while `+0x1b2` is set (pipe
    /// emergence; the sprite is still drawn and still collidable as the inner sprite of `.MTCollideSprites`,
    /// enemies-flyers §7.4). Each body is a named no-op until its task — the Phase-1 `.inert` behaviour, drawn, no
    /// Handle, no hit.
    public static func handle(world w: SpriteWorld, id: Int) {
        guard let s = w.active.record(id: id), !s.emerging else { return }   // `+0x1b2` → return
        switch s.handler {
        case .walker: break                             // the session dispatches `Walker.handle` (WK1)
        case .crawler, .roach: break                    // later: CR — `.HandleCrawlerSprite` / `.HandleRoachSprite`
        case .dillo: break                              // later: DL — `.HandleDilloSprite`
        case .bat, .swarmMember, .insectBody: break     // later: BA — the Bat class, the swarm members, the insect body
        case .gremlin, .floater: break                  // later: GF — `.HandleGremlinSprite` / `.HandleFloaterSprite`
        case .frog, .salamander: break                  // later: FR — `.HandleFrogSprite` / `.HandleSalamanderSprite`
        case .blob, .deadBlob, .crab, .crabSegment: break   // later: BL — the Blob, the dead Blob, the Crab, its segments
        case .geyserSegment: break                      // later: GY — `.HandleGeyserSegSprite`
        case .warrior: break                            // later: LV5 ◇ — the Warrior stand-in (Ruling 3)
        default: break
        }
    }

    /// The Kill proc `+0x50` (`FUN_1009f80c(s)`, ptr-glue) for `s`'s class, as `.HandleBurn` calls it at the opaque
    /// bottom: the enemy Kills' counting part (`EnemyCounting.kill`); with no Kill proc `+0xe9 = 1` (M l. 38834–38838).
    /// The classes' own parts (score `G+0`, sounds, children) are their tasks'. It runs against the world by id
    /// (`SpriteWorld` rule 2: a Kill tail writes other sprites and spawns) — a caller holding a copy of the slot writes
    /// it back first and re-reads after (`Burn.handle`).
    public static func killProc(_ w: SpriteWorld, id: Int) {
        guard var s = w.active.record(id: id) else { return }
        switch s.walkerCallbacks ? SpriteHandler.walker : s.handler {     // WK1: the corpse raft keeps `.KillWalker`
        case .walker, .crawler, .roach, .dillo, .bat, .frog, .salamander, .blob, .warrior:
            w.enemies.kill(&s, globals: &w.globals, level: w.levelIndex, forGood: EnemyCounting.killsForGood(s.handler))
            // `.KillWalker` is this alone (WK1). // later: CR / DL / BA / FR / BL / LV5 — each other Kill's own tail
        case .gremlin:
            guard s.killCount == 0 else { return }      // `+0xe9 ≠ 0` → return (M l. 69736–69738, raw 100810e0 bnelr)
            w.enemies.kill(&s, globals: &w.globals, level: w.levelIndex, forGood: true)
            // later: GF — `.KillGremlinSprite`'s score and rider
        default:
            // `+0x50 == 0` → `+0xe9 = 1` — the EnemyShot class too: `.SetupEnemyShotSprite` stores no `+0x50` (ES; a
            // shield-reflected dart burns away to this, never to `.KillEnemyShot`).
            s.dead = true
        }
        w.active.update(id: id) { $0 = s }
    }

    // MARK: - goblin voices (enemies-ground §2.6, enemies-ground-2 §3)

    /// `.STPlay3DSoundPitchedGob(s, snd, prio, vol, pos, p) @ 10066ef4` (M l. 56773–56785): `.STPlay3DSoundPitched`
    /// at `+0xf0 + p − 0xffff`; no draw.
    public static func playPitchedGob(_ w: SpriteWorld, _ s: SpriteSlot, snd: Int16, priority: Int16, volume: Int16,
                                      pitch: Int32) {
        w.player.cue(PlayerCue(call: .threeDPitched, snd: snd, priority: priority, volume: volume, position: s.centre,
                               rate: s.voicePitch &+ pitch &- 0xffff))
    }

    /// `.STPlay3DSoundRandGob(s, snd, prio, vol, pos) @ 10066f6c` (M l. 56786–56801): `FastRand(10000)` drawn at the
    /// call (sound on or off, Invariant 4), then `.STPlay3DSoundPitched` at `+0xf0 + R − 5000`.
    public static func playRandGob(_ w: SpriteWorld, _ s: SpriteSlot, snd: Int16, priority: Int16, volume: Int16) {
        let r = Int32(w.rng.next(10000))
        w.player.cue(PlayerCue(call: .threeDPitched, snd: snd, priority: priority, volume: volume, position: s.centre,
                               rate: s.voicePitch &+ r &- 5000))
    }

    /// `.GoblinHurtCry(s) @ 10067018` (M l. 56802–56847): R = `FastRand(100)`; R ≥ 86 → 465 at 65000, 71…85 → 466 at
    /// 65000, 56…70 → 468 at 55000 (+ `FastRand(10000)`, vol 0xab), each after stopping every voice of 465, 466 and
    /// 468 (`FUN_10091504`, global over all goblins); R < 56: nothing.
    public static func goblinHurtCry(_ w: SpriteWorld, id: Int) {
        guard let s = w.active.record(id: id) else { return }
        let r = w.rng.next(100)
        let (snd, base): (Int16, Int32)
        if 0x55 < r { (snd, base) = (growl1, 65000) }
        else if 0x46 < r { (snd, base) = (growl2, 65000) }
        else if 0x37 < r { (snd, base) = (hurtCry, 55000) }
        else { return }
        for k in [growl1, growl2, hurtCry] { w.player.cue(PlayerCue(call: .stop, snd: k)) }
        let p = Int32(w.rng.next(10000))
        playPitchedGob(w, s, snd: snd, priority: 1, volume: 0xab, pitch: p + base)
    }

    /// `.GoblinRandomCry(s) @ 100671b0` (M l. 56848–56897): R = `FastRand(100)`, then `FastRand(500)`; only at 50 and
    /// with no voice playing 465, 466 or 467 (`FUN_100916dc`, global — `SpriteWorld.isSoundPlaying`, tested in that
    /// order): R < 41 → 467 vol 0xab; 41…70 → 466 vol 0x55; ≥ 71 → 465 vol 0x55; pitch 55000 + `FastRand(10000)`.
    public static func goblinRandomCry(_ w: SpriteWorld, id: Int) {
        guard let s = w.active.record(id: id) else { return }
        let r = w.rng.next(100)
        guard w.rng.next(500) == 0x32 else { return }
        guard !w.isSoundPlaying(growl1), !w.isSoundPlaying(growl2), !w.isSoundPlaying(taunt) else { return }
        let (snd, vol): (Int16, Int16) = r < 0x29 ? (taunt, 0xab) : r < 0x47 ? (growl2, 0x55) : (growl1, 0x55)
        let p = Int32(w.rng.next(10000))
        playPitchedGob(w, s, snd: snd, priority: 1, volume: vol, pitch: p + 55000)
    }

    /// `.HurtGoblin(s, attacker, dmg, dvx, dvy, invul, flash) @ 1006a128` (M l. 58472–58505): `.HurtSprite`; on a hurt:
    /// `.GoblinHurtCry`; type 0x6d6 → `FastRand(100)` ≥ 76 → `.STPlay3DSoundRandGob(611, 1, 0x100)`, 51…75 → 612;
    /// `.BloodSpray(s, attacker, 0x28, 400, 0x96, 2)`; HP still > 0 → `.STPlay3DSound(701, 1, 0x55)` (no draw).
    @discardableResult
    public static func hurtGoblin(_ w: SpriteWorld, id: Int, attacker aID: Int, damage: Int16, dvx: Int16, dvy: Int16,
                                  invulnerable: Int16, flash: Int16) -> Bool {
        guard HurtSprite.apply(w, id: id, damage: damage, dvx: dvx, dvy: dvy, invulnerable: invulnerable,
                               flash: flash) else { return false }
        goblinHurtCry(w, id: id)
        if let s = w.active.record(id: id), s.type == 0x6d6 {
            let r = w.rng.next(100)
            if 0x4b < r { playRandGob(w, s, snd: axHit1, priority: 1, volume: 0x100) }
            else if 0x32 < r { playRandGob(w, s, snd: axHit2, priority: 1, volume: 0x100) }
        }
        BloodSpray.spray(w, victim: id, attacker: aID, count: 0x28, speed: 400, spread: 0x96, kind: 2)
        if let s = w.active.record(id: id), 0 < s.hp {
            w.player.cue(PlayerCue(call: .threeD, snd: ouch, priority: 1, volume: 0x55, position: s.centre))
        }
        return true
    }

    // MARK: - hit tests (enemies-ground §2.3)

    /// The crush of a Crawler / Roach / Dillo (`.HitCrawlerSprite` M l. 56625–56634): against a Statue or Box solid,
    /// `.PlatformBounce` returned 2 (contact from below) and the solid falls (`+0x2c > 0`) or the enemy stands on
    /// ground (`+0xce ≠ 0`) — the caller then sets HP 0 and `+0x150 = 0x16`.
    public static func crushesSmall(bounce: Int16, solid: SpriteSlot, mover: SpriteSlot) -> Bool {
        bounce == 2 && (0 < solid.vy || mover.groundKind != 0)
    }

    /// The Walker's crush (`.HitWalkerSprite` M l. 58578–58589): against a Statue, Box or Platform solid, the Walker's
    /// `+0xb0 ≠ 4` (M l. 58584, tested before `.PlatformBounce` is called — `bounce` runs only past it),
    /// `.PlatformBounce` returned 2, the solid is not one-way (`+0x185 == 0`) and not an enemy pipe 0x5d2…0x5d6 — the
    /// caller then sets HP 0.
    public static func crushesWalker(mover: SpriteSlot, solid: SpriteSlot, bounce: () -> Int16) -> Bool {
        mover.subtype != 4 && bounce() == 2 && !solid.oneWay && !(0x5d2...0x5d6).contains(solid.type)
    }

    /// The environmental hazards of the enemy Hit routines (`.HitWalkerSprite` M l. 58590–58595, `.HitCrawlerSprite`
    /// M l. 56636–56640): an Effect (`+0x4c == PTR_PTR_100a0460`) of type 0x4b7 at `+0x46 < 8`, or a sprite of type
    /// 0x5a0 (a geyser base or segment) with `+0x14c` 1 or 2 — the Crawler's test is `+0x14c == 1 || +0x150 == 2`
    /// (`crawlerFields`, raw `1006687c`, as read).
    public static func environmentalHazard(_ o: SpriteSlot, crawlerFields: Bool = false) -> Bool {
        if o.handler == .effect && !o.handleCleared && o.type == EffectSprite.bigExplosion && o.phase < 8 { return true }
        guard o.type == 0x5a0 else { return false }
        return crawlerFields ? (o.classTimer == 1 || o.classWord150 == 2) : (o.classTimer == 1 || o.classTimer == 2)
    }

    /// The liquids rows of the ground classes (enemies-ground §2.4), after `.ApplyGravityAndSeparateFromTiles`.
    public enum LiquidClass: Sendable { case walker, crawler, roach, dillo }

    /// The liquids test (Walker M l. 58426–58450, Crawler 56497–56512, Roach 65103–65110, Dillo 72828–72842):
    /// in liquid (`+0x11c ≠ 0`) and fully under plain water (`+0x11c == 1`, kind `+0x128 == 0`) or in any other liquid
    /// (kind > 0). Kind 3 (brine) heals 4 a frame below 500 HP (not the Roach); a hurt (with `+0x116 == 0`) sets
    /// `+0x116`, HP and `+0xaa` and plays 701 vol 0x55 (`.STPlay3DSound`, no draw): Walker kind 0 → 0xc / −0x96 / 0xc;
    /// Walker and Crawler kinds 1–2, Dillo kind 2, Roach every kind → 0x13 / −100 / 0x11.
    public static func liquids(_ w: SpriteWorld, id: Int, class c: LiquidClass) {
        guard var s = w.active.record(id: id) else { return }
        guard s.waterRow != 0, (s.waterRow == 1 && s.waterKind == 0) || 0 < s.waterKind else { return }
        let k = s.waterKind
        var hurt: (invul: Int16, damage: Int16, flash: Int16)?
        if c == .roach {
            hurt = (0x13, 100, 0x11)
        } else if k == 3 {
            if s.hp < 500 { s.hp &+= 4 }
        } else if k < 3 {
            switch c {
            case .walker: hurt = k == 0 ? (0xc, 0x96, 0xc) : (0x13, 100, 0x11)
            case .crawler: if 0 < k { hurt = (0x13, 100, 0x11) }
            case .dillo: if 1 < k { hurt = (0x13, 100, 0x11) }
            case .roach: break
            }
        }
        if let h = hurt, s.invulnerable == 0 {
            s.invulnerable = h.invul
            s.hp &-= h.damage
            s.flash = h.flash
            w.player.cue(PlayerCue(call: .threeD, snd: ouch, priority: 1, volume: 0x55, position: s.centre))
        }
        w.active.update(id: id) { $0 = s }
    }

    /// The Statue spell on an enemy (`.TurnIntoStatue`, M l. 38244–38272) — the enemies' Hit sites call it for a
    /// player shot of type 1 (`StatueSprite.turnIntoStatue`).
    public static func turnIntoStatue(_ w: SpriteWorld, id: Int) { StatueSprite.turnIntoStatue(w, id: id) }

    /// The burn start (`+0x1a2 = 1`, draw-effects §4.2 writers): `.HandleBurn` runs from the next
    /// `.StandardSpriteCleanup` (`Burn`).
    public static func startBurn(_ s: inout SpriteSlot) { s.burnRow = 1 }
}
