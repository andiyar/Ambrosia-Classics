// Enemy mutations (plan §Task 5b.1; Research notes 34, 40; Invariants 7, 8; INDEX C12 / NR-6), transcribed from
// `_SquishEnemy @ 0001131b`, `_PopEnemy @ 00011254`, `_KillEnemy @ 00010f57`, `_CaptureEnemy @ 00010fa6`,
// `_ReleaseEnemyFromBalloon @ 00010ff3`, `_MakeAllEnemiesDisappear @ 000117d7`, `_WasEnemySquished @ 00010eca`,
// `_Balloons_PopBalloon @ 00023a84`, `_Balloons_PopAll @ 00023f54`. These only mark `dead`; slots are freed by the
// draw pass (Invariant 8). Sounds are cued (`Sounds.swift`); the anti-crack `gTopRef`/`gSavedRef` counters are not
// modelled (no RNG).

extension GameState {
    /// `_SquishEnemy(i, n) @ 0001131b`. Ignored when the enemy is dead (`+0x47`) or free (state 0). Marker `+0x3e`
    /// > 0x13 → += 2 (anti-crack, replicated). Score by n (all `_AddToScore(v, 1)`, ×mult), then
    /// `_NewPoint(rect.left, rect.top, sprite, 0xc)`: 1 → 200 / sprite 2; 2 → 400 / 4; 3 → 800 / 8; 4 → 1600 / 0xb;
    /// any other n → 3200 / 0x18. Only n ≠ 1, 2 then calls `_Bonus_SetNumEnemySquishes(n)` (3 and 4 pass 3 / 4, the
    /// default passes n itself). Then dead, drawn 0, `gNumEnemiesSquished++`, maze cell (col, row) = 0, enemy splat
    /// (kind 0) at (left, top), and `_NewStarGroup(col·40, row·40, g)`: state 6 → type 1 → 3, type 3 → 5, else 4;
    /// otherwise sprite set 0x1c / 0x1e → 4, 0x1b → 3, else 5.
    mutating func squishEnemy(_ slot: Int, count: Int) {
        if enemies[slot].dead || enemies[slot].state == 0 { return }
        if 0x13 < enemies[slot].marker {
            enemies[slot].marker &+= 2
        }
        playMySnd(0, priority: 10)                                  // 0001139d "Squish"
        let n = Int8(truncatingIfNeeded: count)
        let x = enemies[slot].rect.left, y = enemies[slot].rect.top
        switch n {
        case 1:
            addToScore(200, multiply: true)
            points.newPoint(x: x, y: y, sprite: 2, delay: 0xc, level: level, notRegistered: config.pointsNotRegistered)
        case 2:
            addToScore(400, multiply: true)
            points.newPoint(x: x, y: y, sprite: 4, delay: 0xc, level: level, notRegistered: config.pointsNotRegistered)
        case 3:
            addToScore(800, multiply: true)
            playMySnd(0x26, priority: 10, delay: 0xf)               // 00011541 "Eat Seaweed…" (+15)
            points.newPoint(x: x, y: y, sprite: 8, delay: 0xc, level: level, notRegistered: config.pointsNotRegistered)
            bonusSetNumEnemySquishes(3)
        case 4:
            addToScore(0x640, multiply: true)
            points.newPoint(x: x, y: y, sprite: 0xb, delay: 0xc, level: level,
                            notRegistered: config.pointsNotRegistered)
            bonusSetNumEnemySquishes(4)
        default:
            addToScore(0xc80, multiply: true)
            points.newPoint(x: x, y: y, sprite: 0x18, delay: 0xc, level: level,
                            notRegistered: config.pointsNotRegistered)
            bonusSetNumEnemySquishes(Int(n))
        }
        enemies[slot].dead = true
        enemies[slot].drawn = false
        numEnemiesSquished &+= 1
        clearEnemyCell(slot)
        let e = enemies[slot]
        splats.newSplat(x: e.rect.left, y: e.rect.top, kind: 0, frame: frame)
        let group: Int
        if e.state == 6 {
            switch e.type {
            case 1: group = 3
            case 3: group = 5
            default: group = 4
            }
        } else {
            switch e.spriteSet {
            case 0x1c, 0x1e: group = 4
            case 0x1b: group = 3
            default: group = 5
            }
        }
        stars.newGroup(x: Int16(e.col) &* 0x28, y: Int16(e.row) &* 0x28, group: group, hero: heroAnchor,
                       frame: frame, prefs: config.prefs, rng: &rng)
    }

    /// `_PopEnemy(i) @ 00011254` (a held enemy's balloon touched by the hero): unless dead or free —
    /// `_AddToScore(100, 1)`, `_NewPoint(rect.left, rect.top, 1, 0xc)`, dead, drawn 0, `gNumEnemiesSquished++`, maze
    /// cell 0. Slot −1 (the hero's own balloon, C12) reads below the enemy array in the original — a no-op here (NR-6).
    mutating func popEnemy(_ slot: Int) {
        guard enemies.indices.contains(slot) else { return }      // NR-6 / C12: slot −1 → no-op
        if enemies[slot].dead || enemies[slot].state == 0 { return }
        playMySnd(0, priority: 10)                                  // 0001129c "Squish"
        addToScore(100, multiply: true)
        points.newPoint(x: enemies[slot].rect.left, y: enemies[slot].rect.top, sprite: 1, delay: 0xc, level: level,
                        notRegistered: config.pointsNotRegistered)
        enemies[slot].dead = true
        enemies[slot].drawn = false
        numEnemiesSquished &+= 1
        clearEnemyCell(slot)
    }

    /// `_KillEnemy(i, clearCell) @ 00010f57`: dead, drawn 0, `gNumEnemiesSquished++`; the maze cell is cleared only
    /// when the second argument is non-zero (its only caller, `_KillEggBlock`, passes 0). No dead/free test.
    mutating func killEnemy(_ slot: Int, clearCell: Bool) {
        enemies[slot].dead = true
        enemies[slot].drawn = false
        numEnemiesSquished &+= 1
        if clearCell {
            clearEnemyCell(slot)
        }
    }

    /// `_CaptureEnemy(i, balloon) @ 00010fa6`: state 6, stateStart = frame, sprite set 0x20, animation frame = type,
    /// `+0x43` = the balloon index.
    mutating func captureEnemy(_ slot: Int, balloon: Int) {
        enemies[slot].state = 6
        enemies[slot].stateStart = frame
        enemies[slot].spriteSet = 0x20
        enemies[slot].animFrame = Int16(enemies[slot].type)
        enemies[slot].balloonIndex = Int8(truncatingIfNeeded: balloon)
    }

    /// `_ReleaseEnemyFromBalloon(i) @ 00010ff3`: a frozen (state 5) enemy stays put; otherwise state 1, stateStart =
    /// frame, sprite set from the type (1 → 0x1b, 2 → 0x1c, 3 → 0x1d, 4 → 0x1e; other types keep it); then the
    /// animation frame: starfish (0x1e) → 1; else by direction 1 → 1, 2 → 4, 3 → 7, 4 → 10, none → unchanged.
    /// `+0x43` is not cleared. Slot −1 (C12 residual path) is a no-op here (NR-6).
    mutating func releaseEnemyFromBalloon(_ slot: Int) {
        guard enemies.indices.contains(slot) else { return }      // NR-6 / C12: slot −1 → no-op
        if enemies[slot].state == 5 { return }
        enemies[slot].state = 1
        enemies[slot].stateStart = frame
        switch enemies[slot].type {
        case 1: enemies[slot].spriteSet = 0x1b
        case 2: enemies[slot].spriteSet = 0x1c
        case 3: enemies[slot].spriteSet = 0x1d
        case 4: enemies[slot].spriteSet = 0x1e
        default: break
        }
        if enemies[slot].spriteSet == 0x1e {
            enemies[slot].animFrame = 1
            return
        }
        switch enemies[slot].direction {
        case .up: enemies[slot].animFrame = 1
        case .down: enemies[slot].animFrame = 4
        case .left: enemies[slot].animFrame = 7
        case .right: enemies[slot].animFrame = 10
        case nil: break
        }
    }

    /// `_MakeAllEnemiesDisappear @ 000117d7` (hero death, state 4): `_Balloons_PopAll`, then per slot 0…29: state 5 →
    /// (a licence check that writes `+0x42`, no RNG — not modelled) dead, `level.pool[type]++`, drawn 0; any other
    /// non-free state → state 5, dead, `level.pool[type]++`, drawn 0. No dead-flag test (an already-squished,
    /// unfreed enemy is returned to the pool too — replicated). `gNumEnemiesSquished` is not touched. The pool word
    /// is `level + 0x22 + 2·type` = LEVL word 17 + type.
    mutating func makeAllEnemiesDisappear() {
        balloonsPopAll()
        for i in enemies.indices where enemies[i].state != 0 {
            if enemies[i].state != 5 {
                enemies[i].state = 5
            }
            enemies[i].dead = true
            let word = 17 + Int(enemies[i].type)
            levelRecord.words[word] &+= 1
            enemies[i].drawn = false
        }
    }

    /// `_WasEnemySquished(rect) @ 00010eca`: the first enemy (slots 0…29) in state 1, 4, 5, 6 or 3 whose rect
    /// strictly overlaps `rect` — the dead flag `+0x47` is **not** tested (Invariant 7, B7: a squished enemy keeps
    /// its state until the draw pass, so it is handed out again). A state-6 enemy's balloon (`+0x43`) is popped
    /// (`_Balloons_PopBalloon`). Returns the slot, or −1.
    mutating func wasEnemySquished(_ rect: QDRect) -> Int {
        for i in enemies.indices {
            let s = enemies[i].state
            guard s == 1 || s == 4 || s == 5 || s == 6 || s == 3 else { continue }
            guard rect.collides(enemies[i].rect) else { continue }
            if s == 6 {
                balloonsPopBalloon(Int(enemies[i].balloonIndex))
            }
            return i
        }
        return -1
    }

    /// `_Balloons_PopBalloon(i) @ 00023a84`: state 3, start = frame, sprite set 0x33, frame 1, counter 0 (whatever
    /// the balloon's state was). An index outside the 30 slots (never produced by the callers) is ignored.
    mutating func balloonsPopBalloon(_ index: Int) {
        guard balloons.indices.contains(index) else { return }
        popBalloonFields(index)
        playMySnd(0x10, priority: 10)                               // 00023add "Enemy Hatch"
    }

    /// `_Balloons_PopAll @ 00023f54`: every holding (state 2) balloon → the `_Balloons_PopBalloon` fields with one
    /// frame-counter read; flying balloons are untouched.
    mutating func balloonsPopAll() {
        for i in balloons.indices where balloons[i].state == 2 {
            popBalloonFields(i)
        }
    }

    private mutating func popBalloonFields(_ i: Int) {
        balloons[i].state = 3
        balloons[i].startFrame = frame
        balloons[i].spriteSet = 0x33
        balloons[i].frame = 1
        balloons[i].counter = 0
    }

    /// `gMaze[(char)col + (char)row · 16] = 0` for the enemy's cell.
    private mutating func clearEnemyCell(_ slot: Int) {
        maze.cells[Int(enemies[slot].col) + Int(enemies[slot].row) * Maze.columns] = 0
    }
}
