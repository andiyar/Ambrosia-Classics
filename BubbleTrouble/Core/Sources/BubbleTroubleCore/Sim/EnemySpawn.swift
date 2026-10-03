// Enemy spawning (plan §Task 9a.1; Research note 29; Invariants 8, 9), transcribed from `_CheckNewEnemies @ 000124fa`
// and the folded `_NewEnemy @ 00012172` (Ghidra folds it into `_CheckNewEnemies` — tail `jmp` at 00012586;
// enemies-ai.md header). The licence copies `_NewEnemy` stores (`RT3_GetLicenseName` → `+0x34`,
// `RT3_GetLicenseCopies` → `+0x54`, `RT3_GetLicenseCode` → `+0x08/+0x0c`) and the magic words at `+0x28/+0x2c`
// draw no RNG and are not modelled (Entities.swift header).

extension GameState {
    /// `_CheckNewEnemies @ 000124fa` (+ folded `_NewEnemy`). Gates, in order: hero state 2; `gNumNormalBlocks < 1`
    /// → if no enemy is active, `gNumEnemiesSquished = (char)total` — return either way; `_TimeBonus_GetBonus() < 1`
    /// → `gNumEnemiesSquished = (char)total − active` (and carry on); `total <= squished + active` → return;
    /// `max (w7) <= active` → return; the first free slot of 30 (state byte 0), none → return; `gNumNormalBlocks < 1`
    /// re-tested (the original repeats gate 2 here). Then `c = GetRandomFast(0,15)`, `r = GetRandomFast(0,10)` and
    /// the forward row-major scan from (c+1, r) — col wraps 15 → 0 with row + 1, row wraps 10 → 0 — to the first
    /// normal bubble (10); the start cell is tested last. The enemy: rect = prevRect = the cell, tier 4, state 2,
    /// stateStart = frame, marker 0x14, `dir = GetRandomFast(1,4)`, aligned, `+0x42 = 1`, col/row, offsets 0,
    /// lastPop = frame. Pool: w18…w23 all zero → w18 = 1; `do i = GetRandomFast(0,5) while pool[i] == 0`;
    /// `pool[i]--`; type i+1, sprite set 0x1b/0x1c/0x1d/0x1e; anim frame 1 for the starfish, else by dir 1→1,
    /// 2→4, 3→7, 4→10; anim tick 0, balloon −1, post-hatch counter 0, drawn 0, dead 0, stuck 0, paused 0, speed
    /// counter 0, speed 0, action wait 0, pending action 0 (the post-hatch flag `+0x4b` is NOT reset). Maze cell =
    /// 0x3c, `gNumNormalBlocks--`, `_NewBlock(c, r, 0, 0x3c, slot, 0)` — none free is the original's
    /// `_StdError("Internal error: NewBlock() - none free. Increase max count.")` → `_CleanUp` (quit) →
    /// `.originalWouldAbort`, before `gNumEnemiesActive++`. Finally `gNumEnemiesActive++`.
    mutating func checkNewEnemies() {
        if hero.state != 2 { return }
        let total = levelRecord.words[6], maxActive = levelRecord.words[7]
        if numNormalBlocks < 1 {
            if 0 < numEnemiesActive { return }
            numEnemiesSquished = Int8(truncatingIfNeeded: total)
            return
        }
        if timeBonus < 1 {
            numEnemiesSquished = Int8(truncatingIfNeeded: total) &- numEnemiesActive
        }
        if Int(total) <= Int(numEnemiesSquished) + Int(numEnemiesActive) { return }
        if maxActive <= Int16(numEnemiesActive) { return }
        let now = frame
        guard let slot = enemies.firstIndex(where: { $0.state == 0 }) else { return }
        if numNormalBlocks < 1 {
            if numEnemiesActive < 1 {
                numEnemiesSquished = Int8(truncatingIfNeeded: total)
            }
            return
        }

        // _NewEnemy @ 00012172 (folded).
        var c = Int8(truncatingIfNeeded: rng.fast(0, 0xf))
        var r = Int8(truncatingIfNeeded: rng.fast(0, 10))
        var col = 0, row = 0
        var scanned = 0
        repeat {
            c &+= 1
            if c < 0x10 {
                row = Int(r)
                col = Int(c)
            } else {
                r &+= 1
                if r < 0xb {
                    row = Int(r)
                } else {
                    r = 0
                    row = 0
                }
                c = 0
                col = 0
            }
            scanned += 1
            // `gNumNormalBlocks` ≥ 1 with no normal bubble in the maze: the original spins here forever.
            precondition(scanned <= Maze.byteCount, "NewEnemy: no normal bubble to lay in — the original hangs")
        } while maze.cells[col + row * 0x10] != CellCode.normal

        var e = enemies[slot]
        e.rect = QDRect.cell(col: col, row: row)
        e.prevRect = e.rect
        e.tier = 4
        e.state = 2
        e.stateStart = now
        e.marker = 0x14
        e.direction = Direction(rawValue: Int8(truncatingIfNeeded: rng.fast(1, 4)))
        e.aligned = true
        e.unknown42 = 1
        e.col = c
        e.row = r
        e.xOffset = 0
        e.yOffset = 0
        e.lastPop = now
        enemies[slot] = e

        if levelRecord.words[18...23].allSatisfy({ $0 == 0 }) {
            levelRecord.words[18] = 1
        }
        var i: Int
        repeat {
            i = rng.fast(0, 5)
        } while levelRecord.words[18 + i] == 0
        levelRecord.words[18 + i] &-= 1
        let type = Int8(i + 1)
        enemies[slot].type = type
        switch type {
        case 2: enemies[slot].spriteSet = 0x1c
        case 1: enemies[slot].spriteSet = 0x1b
        case 3: enemies[slot].spriteSet = 0x1d
        case 4: enemies[slot].spriteSet = 0x1e
        default: break                       // types 5/6 (pool words 22/23) leave the sprite set as it was
        }
        if enemies[slot].spriteSet == 0x1e {
            enemies[slot].animFrame = 1
        } else {
            switch enemies[slot].direction {
            case .up: enemies[slot].animFrame = 1
            case .down: enemies[slot].animFrame = 4
            case .left: enemies[slot].animFrame = 7
            case .right: enemies[slot].animFrame = 10
            case nil: break
            }
        }
        enemies[slot].animTick = 0
        enemies[slot].balloonIndex = -1
        enemies[slot].postHatchCounter = 0
        enemies[slot].drawn = false
        enemies[slot].dead = false
        enemies[slot].stuck = 0
        enemies[slot].paused = false
        enemies[slot].speedCounter = 0
        enemies[slot].speed = 0
        enemies[slot].actionWait = 0
        enemies[slot].pendingAction = 0

        maze.cells[col + row * 0x10] = CellCode.egg
        numNormalBlocks &-= 1
        if newBlock(col: col, row: row, direction: nil, type: CellCode.egg, enemy: Int8(slot), moving: false) < 0 {
            pendingStops.insert(.originalWouldAbort("Internal error: NewBlock() - none free. Increase max count."))
            return
        }
        numEnemiesActive &+= 1
    }
}
