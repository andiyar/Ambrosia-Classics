import Foundation
import HectorResources

/// The player's life cycle (player-physics.md §3–§7, damage-health-death.md §5, loose-ends-session.md §4,
/// loose-ends-combat.md §3.3; plan C14): set-up, level start, the life-state step, respawn, hits, death, the
/// overload warnings and invulnerability. Index-based (plan invariant 13): every rule re-reads `players[i]`.
///
/// Listing reads (`disasm-review3-all.txt`):
/// - `FUN_1002a150 @ 1002a150(p, now, gate)` (`1002a17c..1002a378`): see `playerLifeStateStep`.
/// - `FUN_10029cc0 @ 10029cc0(p, now)` (`10029ce0..10029ef4`): see `respawnPlayer`.
/// - `FUN_10027100 @ 10027100(p, —, now; f1 damage)` (`1002712c..100273d4`): see `playerHit`.
/// - `FUN_10027e50 @ 10027e50(p, now)` (`10027e70..10028150`): see `killPlayer` — the order is the listing's
///   (plan Bank corrections 2): owner destruction, death spawn, shield zeroed if not in game, hit timers, the
///   displayed shield **and power** 0.0 (`10027f4c`/`10027f5c`), coins 50/10/5/1, money 0, state 3, invulnerable,
///   multiplier.
/// - `FUN_10026ee0 @ 10026ee0(p, now)` (`10026f0c..100270d8`): see `overloadTick` — the flash glow is the
///   object's glow `+0x58` (not `+0x214`, which only ever holds 0.0).
/// - `FUN_10027de0 @ 10027de0(p, set, sticky)` (`10027de0..10027e40`), `FUN_10026410` (`10026434..10026980`),
///   `FUN_100269a0` (`100269c4..10026af0`), `FUN_10027630` (`10027630..1002765c`).
extension GameState {
    /// `FUN_10026410(p, i, G+0x21, G+0x1c, G+0x14)` — `Player.setup` with the game's player count, time and sector,
    /// then the money-counter reset `FUN_10027630` (`100268f8`; no other effect between them depends on it).
    public mutating func setupPlayer(_ i: Int) throws {
        try players[i].setup(index: i, players: Int(flags.numPlayers), sector: Int(flags.sector),
                             now: flags.gameTime)
        resetCoinTally(i)
    }

    /// `FUN_100269a0(p, G+0x18, now)` — `Player.levelStart` (incl. its `R(400, 2000)` at `10026a9c`, drawn for every
    /// in-game player) and, for an in-game player, the money-counter reset `FUN_10027630` (`10026a48`).
    public mutating func playerLevelStart(_ i: Int) {
        players[i].levelStart(now: flags.gameTime, rng: &rng, levelRef: flags.level)
        if players[i].inGame { resetCoinTally(i) }
    }

    /// `FUN_10027630` — the player's coin-tally fields (`TallyState.coin[i]`, player +0xd8…+0x1f8): state 0,
    /// timers 0, alpha 0x20, value 0, text empty, money/bonus/step/offset 0.
    mutating func resetCoinTally(_ i: Int) {
        var c = TallyState.CoinTally()
        c.alpha = 0x20                                                       // 10027638..10027640
        tally.coin[i] = c
    }

    /// `FUN_1002a150` — the life-state step. Not in game → nothing (`1002a17c`). State 2: `now > enter +
    /// entry_InitialDelay` → `respawnPlayer`, else displayed shield 0.0 (`FUN_10031710`). State 4: invulnerable ∧
    /// ¬G+0x39 ∧ `now > enter + entry_InvulnerabilityTime` ∧ in game ∧ ¬sticky → both flags cleared. State 1: `now >
    /// enter + gameOverTime` → out of the game. State 3: displayed shield and power 0.0 every tick; duration =
    /// `finalDyingTime` when lives == 1 else `dyingTime`; past it: gate ∧ in game → lives = max(lives − 1, 0); lives
    /// > 0 → `respawnPlayer` then shield = default (0 when not in game), hit timers 0, `+0xd1` = 0; else state 1 at now.
    mutating func playerLifeStateStep(_ i: Int, now: Int32, gate: Bool) {
        guard players[i].inGame else { return }                              // 1002a17c..1002a184
        let d = players[i].definition
        let idx = Int(players[i].index)
        switch players[i].lifeState {                                        // 1002a188..1002a1b0
        case 2:
            if now > players[i].stateEntered &+ d.entryInitialDelay {        // 1002a1b4..1002a1c8
                respawnPlayer(i, now: now)                                   // 1002a1cc
            } else {
                scoreBar.setShownShield(index: idx, 0)                       // 1002a1d4..1002a1dc
            }
        case 4:
            if players[i].invulnerable && !flags.levelEnding                 // 1002a1e8..1002a200
                && now > players[i].stateEntered &+ d.entryInvulnerabilityTime   // 1002a204..1002a218
                && players[i].inGame && !players[i].invulnerableSticky {     // 1002a21c..1002a230
                players[i].invulnerable = false                              // 1002a234
                players[i].invulnerableSticky = false                        // 1002a238
            }
        case 1:
            if now > players[i].stateEntered &+ d.gameOverTime {             // 1002a24c..1002a260
                players[i].inGame = false                                    // 1002a264..1002a268
            }
        case 3:
            scoreBar.setShownShield(index: idx, 0)                           // 1002a270..1002a278
            scoreBar.setShownPower(index: idx, 0)                            // 1002a280..1002a288
            let lives = players[i].lives
            let duration = lives == 1 ? d.finalDyingTime : d.dyingTime       // 1002a290..1002a2b4
            guard now > players[i].stateEntered &+ duration else { return }  // 1002a2b8..1002a2c4
            if gate && players[i].inGame {                                   // 1002a2c8..1002a2d8
                let n = lives &- 1                                           // 1002a2dc subic.
                players[i].lives = n < 0 ? 0 : n                             // 1002a2e0..1002a2f0
            }
            if players[i].lives > 0 {                                        // 1002a2f4..1002a300
                respawnPlayer(i, now: now)                                   // 1002a30c
                if !players[i].inGame {                                      // 1002a310..1002a320
                    players[i].shield = 0
                } else {
                    players[i].shield = Float(players[i].definition.defaultShieldPercentage)   // 1002a328..1002a358
                }
                players[i].lastHit = 0                                       // 1002a35c..1002a368
                players[i].lastHitSpawn = 0
                players[i].shieldWarningShown = false
            } else {
                players[i].setLifeState(1, now: now)                         // 1002a370..1002a378
            }
        default:
            break                                                            // 0, ≥ 5
        }
    }

    /// `FUN_10029cc0` — become active / respawn (player-physics §4.1): in game → ship sprite `FUN_10029f10`, size,
    /// start position + velocity 0 + crosshair 0 + overload cleared (`10029d00..10029dfc`), `+0xc5` = 1, **state 4 at
    /// now** (`10029e04`/`10029e08`), appear fade flli 163/164/165, the `entry_Spawn_ID` request at the ship owned by
    /// the player (`10029e38..10029ed8`), the multiplier indicator `FUN_10029fe0` (`10029ee4`), the handler reset
    /// `FUN_1003af90(h, 0)` (`10029ef4`).
    mutating func respawnPlayer(_ i: Int, now: Int32) {
        guard players[i].inGame else { return }                              // 10029ce0..10029ce8
        players[i].resetShipSprite()                                         // 10029cec FUN_10029f10
        players[i].refreshSize()                                             // 10029cf8 FUN_10012940
        players[i].placeAtStart()                                            // 10029d00..10029dfc
        players[i].appearing = true                                          // 10029e00
        players[i].setLifeState(4, now: now)                                 // 10029e04..10029e08
        players[i].setAppearFade()                                           // 10029e0c..10029e34
        spawnAtPlayer(i, players[i].definition.entrySpawn, owned: true)      // 10029e38..10029ed8
        showMultiplierIndicator(i)                                           // 10029ee4 FUN_10029fe0
        players[i].resetHandler(levelStart: false)                           // 10029ef4 FUN_1003af90(h, 0)
    }

    /// A request for `unit` at the player's position (`FUN_100128d0` into req+4/+8) from the player template
    /// `0x100e91d4` (runtime: +0x14 = 0xff, +0x24 = −1, +0x28 = 1.0), with +0x14 = the player index when `owned`;
    /// `none` → no request. Returns the out-parameter.
    @discardableResult
    mutating func spawnAtPlayer(_ i: Int, _ unit: FourCC, owned: Bool) -> SpawnResult? {
        guard unit != .none else { return nil }
        var req = SpawnRequest(unit: unit, x: players[i].object.x, y: players[i].object.y)
        if owned { req.player = players[i].index }
        return spawn(req)
    }

    /// `FUN_10027100` — the player is hit by `damage` (the colliding unit's `damage_FLOAT`) at game time now
    /// (damage-health-death §5.2): state 4 only; `now ≥ lastHit + shieldHitDelay` (**≥**) else ignored; lastHit =
    /// now; not invulnerable → loss = damage × float(shieldBaseHitPercentage) (`fmuls`), shield = shield − loss,
    /// loss > 0.0 → `+0xd0`; shield < 0.0 → `killPlayer`, return; hit glow (colour, speed, not forced); damage > 0.0
    /// → the spawn-on-hit unit (when `now ≥ lastSpawn + trunc(flli 162)`) and, once per life, the shield-warning
    /// unit when shield ≤ shieldWarningPercentage (`+0xd1` set even when the unit is `none`).
    public mutating func playerHit(_ i: Int, damage: Float) {
        let now = flags.gameTime
        guard players[i].lifeState == 4 else { return }                      // 1002712c..10027134
        let d = players[i].definition
        guard now >= players[i].lastHit &+ d.shieldHitDelay else { return }  // 10027138..1002714c
        players[i].lastHit = now                                             // 10027150
        if !players[i].invulnerable {                                        // 10027154..10027160
            let loss: Float = damage * Float(d.shieldBaseHitPercentage)      // 10027164..1002718c
            let v: Float = players[i].shield - loss                          // 10027190..1002719c
            if loss > 0 { players[i].hitThisLevel = true }                   // 100271a0..100271ac
            players[i].shield = v                                            // 100271b4
        }
        if players[i].shield < 0 {                                           // 100271bc..100271d0
            killPlayer(i)                                                    // 100271dc
            return
        }
        players[i].object.startHitGlow(colour: d.hitGlowColor, step: d.hitGlowSpeed, force: false)   // 100271e8..100271fc
        guard damage > 0 else { return }                                     // 10027204..1002720c
        if d.activeSpawnOnHit != .none                                       // 10027210..10027220
            && now >= players[i].lastHitSpawn &+ EntityDraw.fctiwz(assets.floats[162]) {   // 10027224..10027248
            players[i].lastHitSpawn = now                                    // 1002724c
            spawnAtPlayer(i, d.activeSpawnOnHit, owned: true)                // 10027250..100272e0
        }
        if !players[i].shieldWarningShown                                    // 100272e8..100272f0
            && players[i].shield <= Float(d.shieldWarningPercentage) {      // 100272f4..1002732c (cror eq,lt,eq)
            spawnAtPlayer(i, d.activeShieldWarningObject, owned: true)       // 10027330..100273c8
            players[i].shieldWarningShown = true                             // 100273d0..100273d4
        }
    }

    /// `FUN_10027e50` — the ship is destroyed at game time now (see the type's comment for the order).
    public mutating func killPlayer(_ i: Int) {
        let now = flags.gameTime
        let idx = players[i].index
        destroyEntitiesOwned(byPlayer: idx)                                  // 10027e70..10027e74 FUN_10034b90
        spawnAtPlayer(i, players[i].definition.deathSpawn, owned: true)      // 10027e7c..10027f18
        if !players[i].inGame { players[i].shield = 0 }                      // 10027f20..10027f30
        players[i].lastHit = 0                                               // 10027f34..10027f44
        players[i].lastHitSpawn = 0
        players[i].shieldWarningShown = false
        scoreBar.setShownShield(index: Int(idx), 0)                          // 10027f48..10027f4c FUN_10031710
        scoreBar.setShownPower(index: Int(idx), 0)                           // 10027f54..10027f5c FUN_10031760
        let coins: [FourCC] = [2, 3, 4, 5].map {                             // 10027f64..10027f98 FUN_100201f0
            assets.objects.indices.contains($0) ? assets.objects[$0] : .none
        }
        var m = players[i].money                                             // 10027fa0..10027fc0
        var req = SpawnRequest.template                                      // 10027fa8..10028010 (+0x14 = 0xff)
        req.x = players[i].object.x; req.y = players[i].object.y             // 10028014..10028020
        for (k, value) in [Int32(50), 10, 5, 1].enumerated() {               // 10028024..100280f8
            while m >= value {
                m = m &- value
                if coins[k] != .none {
                    req.unit = coins[k]
                    spawn(req)
                }
            }
        }
        players[i].money = 0                                                 // 100280fc..10028104
        players[i].setLifeState(3, now: now)                                 // 10028108..10028110
        if players[i].inGame { players[i].invulnerable = true }              // 10028114..10028124
        if players[i].multiplier != 1 {                                      // 10028128..1002813c
            removeEntity(serial: players[i].multiplierIndicator)             // 10028140..10028144 FUN_10034de0
            players[i].multiplier = 1                                        // 1002814c..10028150 FUN_10029fd0
        }
    }

    /// `FUN_10026ee0` — the overload warning tick (player-physics §6.2). Not state 4: a running overload is
    /// cleared. State 4 and running: G+0x39 → cleared; phase 1 → when `now > last + interval`: last = now, glow
    /// `+0x58` += 100.0 and, when ≥ 100.0: glow 100.0, phase 0, interval − 1 (not below the minimum), count + 1,
    /// count == NumWarnings → `killPlayer` (return), else the overload sound (`FUN_100475e0(rec, 1)`); phase 0 →
    /// glow −= WarningFadePercent, ≤ 0.0 → 0.0 and phase 1. Then `+0x54` = 0, `+0x5c` = glow, `+0x60` = 0.0,
    /// `+0x64` = the Hilite colour.
    mutating func overloadTick(_ i: Int, now: Int32) {
        guard players[i].lifeState == 4 else {                               // 10026f0c..10026f14
            if players[i].overloadActive { players[i].clearOverload() }      // 10026f18..10026f58
            return
        }
        guard players[i].overloadActive else { return }                      // 10026f60..10026f68
        if flags.levelEnding {                                               // 10026f6c..10026f78
            players[i].clearOverload()                                       // 10026f7c..10026fb0
            return
        }
        let d = players[i].definition
        if players[i].overloadPhase != 0 {                                   // 10026fb8..10026fc0
            if now > players[i].overloadLast &+ players[i].overloadInterval {   // 10026fc4..10026fd4
                players[i].overloadLast = now                                // 10026fd8
                players[i].object.glow = players[i].object.glow + 100        // 10026fdc..10026fec (fadd; frsp)
                if players[i].object.glow >= 100 {                           // 10026ff0..10026ffc
                    players[i].object.glow = 100                             // 10027000..10027008
                    players[i].overloadPhase = 0                             // 1002700c
                    var interval = players[i].overloadInterval &- 1          // 10027010..10027018
                    if interval < d.powerupOverloadMinimumTimeBetweenWarnings {   // 1002701c..1002702c
                        interval = d.powerupOverloadMinimumTimeBetweenWarnings
                    }
                    players[i].overloadInterval = interval
                    players[i].overloadCount &+= 1                           // 10027034..1002703c
                    if players[i].overloadCount == d.powerupOverloadNumWarnings {   // 10027040..10027050
                        killPlayer(i)                                        // 1002705c
                        return
                    }
                    if let cue = SoundPlay.record(d.powerupOverloadSound, allowMultiple: true, rng: &rng) {   // 10027068..10027070
                        cues.sounds.append(cue)
                    }
                }
            }
        } else {
            let g: Float = players[i].object.glow - d.powerupOverloadWarningFadePercent   // 1002707c..10027090
            players[i].object.glow = g
            if g <= 0 {                                                      // 10027094..100270a0
                players[i].object.glow = 0                                   // 100270a4..100270ac
                players[i].overloadPhase = 1                                 // 100270b0
            }
        }
        players[i].object.hideSprite = false                                 // 100270b4..100270bc
        players[i].object.glowTarget = players[i].object.glow                // 100270c0..100270c4
        players[i].object.glowStep = 0                                       // 100270c8
        players[i].object.glowTintColour = d.powerupOverloadHilite           // 100270cc..100270d8
    }

    /// The overload start in `FUN_10028170` (`10029168..1002919c`): `+0x210` = 1, phase 1, `+0x214` = 0.0, last =
    /// now, interval = `powerupOverload_InitialTimeBetweenWarnings`, count 0, `+0x64` = the Hilite colour.
    mutating func startOverload(_ i: Int, now: Int32) {
        let d = players[i].definition
        players[i].overloadActive = true
        players[i].overloadPhase = 1
        players[i].overloadGlow = 0
        players[i].overloadLast = now
        players[i].overloadInterval = d.powerupOverloadInitialTimeBetweenWarnings
        players[i].overloadCount = 0
        players[i].object.glowTintColour = d.powerupOverloadHilite
    }

    /// `FUN_10027de0(p, set, sticky)`: not in game → nothing; set → (sticky → `+0xcf`) and `+0xce`; clear → both
    /// cleared unless `+0xcf` is set, in which case only a sticky clear clears them.
    public mutating func setInvulnerable(_ i: Int, _ set: Bool, sticky: Bool) {
        guard players[i].inGame else { return }                              // 10027de0..10027de8
        if set {
            if sticky { players[i].invulnerableSticky = true }               // 10027df4..10027e00
            players[i].invulnerable = true                                   // 10027e04..10027e08
        } else if !players[i].invulnerableSticky || sticky {                 // 10027e10..10027e20
            players[i].invulnerable = false
            players[i].invulnerableSticky = false
        }
    }

    // MARK: - ◇ removal walkers (C11b owns FUN_10036120; these walk as the listing does)

    /// `FUN_10034b90 @ 10034b90(player)` (`10034ba4..10034cc0`): player −1 → nothing; every group member (group list
    /// order, member order) whose `+0xd8` == player: its state's `canBeDestroyedOnOwnerDestruction` (+0x329) →
    /// `FUN_10036120(group, e, 1, 0)`, else `canBeDeletedOnOwnerDeletion` (+0x32a) → `FUN_10036120(group, e, 0, 0)`.
    mutating func destroyEntitiesOwned(byPlayer player: Int8) {
        guard player != -1 else { return }                                   // 10034ba4..10034bb0
        var g = 0
        while g < world.groups.count {
            var k = 0
            while k < world.groups[g].members.count {
                let e = world.groups[g].members[k]
                if world.entities[e].ownerPlayer == player, let st = currentState(e) {   // 10034c48..10034c60
                    if st.canBeDestroyedOnOwnerDestruction {                 // 10034c68..10034c84
                        removeMemberStub(group: g, entity: e, destroyed: true)
                    } else if st.canBeDeletedOnOwnerDeletion {               // 10034c8c..10034ca8
                        removeMemberStub(group: g, entity: e, destroyed: false)
                    }
                }
                k += 1
            }
            g += 1
        }
    }

    /// `FUN_10034de0 @ 10034de0(serial)` (`10034df8..10034ec4`): the first group member (group list order, member
    /// order) whose serial `+0x9c` matches → `FUN_10036120(group, e, 0, 0)`, then return. No deleted-flag test.
    mutating func removeEntity(serial: Int32) {
        for g in world.groups.indices {
            for e in world.groups[g].members where world.entities[e].serial == serial {   // 10034e88..10034e94
                removeMemberStub(group: g, entity: e, destroyed: false)      // 10034e98..10034ea4
                return
            }
        }
    }

    /// `FUN_10036120(group, e, destroyed, 0)` — ◇ stub — C11b fills (Combat/Removal): only the common tail
    /// (`10036370..10036380`: +0xcb = 1, group +0xa8 −= 1), as `removeEntities(ofUnit:ownedBy:)` (C8) does. The
    /// destroyed path's accuracy decrement, coins, deletion spawn and child handling are not run here.
    mutating func removeMemberStub(group g: Int, entity e: Int, destroyed: Bool) {
        world.entities[e].deleted = true
        world.groups[g].live &-= 1
    }
}
