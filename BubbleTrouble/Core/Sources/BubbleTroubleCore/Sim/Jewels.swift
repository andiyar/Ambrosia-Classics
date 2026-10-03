// Jewel joining and the jewel bonus (plan §Task 8.1; Research note 39; bubbles-items-scoring.md §3), transcribed
// from `_CheckJewelMovement @ 0001ca05` and `_Jewels_GiveBonus @ 0001c7c5`. Sounds are not modelled (no RNG).

extension GameState {
    /// `_CheckJewelMovement(i, col, row) @ 0001ca05` — a moving jewel block aligned on (col, row) (the original's
    /// three `char` parameters; the replica takes the slot and the cell as `Int`).
    /// - `gMaze[col, row]` is a cluster (30): count + 1, the join tail, retired; the maze keeps 30.
    /// - It is a jewel (20): if no target yet, `gJewelFound` = 1, target = (col, row), this block's type = 30, and
    ///   `_NewBlock(col, row, 1, 30, 0, 1)` (a static cluster; a full pool is ignored); count + 1, the join tail;
    ///   then retired and `gMaze[col, row]` = this block's type (30 after a first join).
    /// - Otherwise next = `_GetNextObject(dir, col, row)`: 0 or 'P' → keep going; one of 10, 50, 40, 60, 15, 16, 51,
    ///   52 → stop; a jewel/cluster with a target found whose cell (one step in dir) is the target → keep going,
    ///   any other jewel/cluster → stop; no target yet → keep going (into the jewel); any other code → keep going.
    ///   Stop = retired, `gMaze[col, row]` = type.
    /// The join tail: `(char)count < (char)gNumJewels − 1` → partial: when `(short)(char)gNumEnemiesActive < w7`,
    /// w6 (total enemies) + 1 and w21 (the starfish pool) + 1; `_NewStarGroup(target·40, 0)`; else `_Jewels_GiveBonus`.
    mutating func checkJewelMovement(_ slot: Int, col: Int, row: Int) {
        let cell = col + row * Maze.columns
        if maze.cells[cell] == CellCode.cluster {
            jewelCount += 1
            jewelJoined()
            blocks[slot].retired = true
            return
        }
        if maze.cells[cell] == CellCode.jewel {
            if !jewelFound {
                jewelFound = true
                targetJewel = CellRef(col: Int8(truncatingIfNeeded: col), row: Int8(truncatingIfNeeded: row))
                blocks[slot].type = CellCode.cluster
                newBlock(col: col, row: row, direction: .up, type: CellCode.cluster, enemy: 0, moving: true)
            }
            jewelCount += 1
            jewelJoined()
        } else {
            guard let dir = blocks[slot].direction else {
                pendingStops.insert(.originalWouldAbort("GetNextObject - bad direction"))   // see `moveBlock`
                return
            }
            let next = getNextObject(dir, col: col, row: row)
            if next == 0 || next == CellCode.passableP { return }
            let stops: [UInt8] = [CellCode.normal, CellCode.wall, CellCode.popping, CellCode.egg, CellCode.blue,
                                  CellCode.purple, 0x33, CellCode.dynamite]
            if !stops.contains(next) {
                guard next == CellCode.jewel || next == CellCode.cluster else { return }
                guard jewelFound else { return }
                var c = Int8(truncatingIfNeeded: col), r = Int8(truncatingIfNeeded: row)
                switch dir {
                case .left: c &-= 1
                case .right: c &+= 1
                case .up: r &-= 1
                case .down: r &+= 1
                }
                if CellRef(col: c, row: r) == targetJewelOrNone { return }
            }
        }
        blocks[slot].retired = true
        maze.cells[cell] = blocks[slot].type
    }

    /// The shared join tail of `_CheckJewelMovement` (after `gJewelCount++`).
    private mutating func jewelJoined() {
        if Int(Int8(truncatingIfNeeded: jewelCount)) < Int(Int8(truncatingIfNeeded: numJewels)) - 1 {
            if Int16(numEnemiesActive) < levelRecord.words[7] {
                levelRecord.words[6] &+= 1
                levelRecord.words[21] &+= 1
            }
            let t = targetJewelOrNone
            stars.newGroup(x: Int16(t.col) &* 0x28, y: Int16(t.row) &* 0x28, group: 0, hero: heroAnchor,
                           frame: frame, prefs: config.prefs, rng: &rng)
        } else {
            jewelsGiveBonus()
        }
    }

    /// `_Jewels_GiveBonus @ 0001c7c5`: target on the border (col 0 or 15, row 0 or 10) → 1000, point sprite 10; else
    /// by `_GetLevel()`: 1 → 5000 / 0xf, 2 → 6000 / 0x10, 3 → 7000 / 0x11, 4 → 8000 / 0x12, 5 → 9000 / 0x13, any other
    /// → 10000 / 0x14. Then (decompile order) `_AddToScore(v, 1)` (×mult), `_NewStarGroup(target·40, 2)`,
    /// `_NewPoint(target·40, sprite, 10)`, `gJewelsDone` = 1, `_Balloons_CaptureAllEnemies`.
    mutating func jewelsGiveBonus() {
        let t = targetJewelOrNone
        let value: Int32, sprite: Int16
        if t.col == 0 || t.col == 0xf || t.row == 0 || t.row == 10 {
            (value, sprite) = (1000, 10)
        } else {
            switch level {
            case 1: (value, sprite) = (5000, 0xf)
            case 2: (value, sprite) = (6000, 0x10)
            case 3: (value, sprite) = (7000, 0x11)
            case 4: (value, sprite) = (8000, 0x12)
            case 5: (value, sprite) = (9000, 0x13)
            default: (value, sprite) = (10000, 0x14)
            }
        }
        addToScore(value, multiply: true)
        let x = Int16(t.col) &* 0x28, y = Int16(t.row) &* 0x28
        stars.newGroup(x: x, y: y, group: 2, hero: heroAnchor, frame: frame, prefs: config.prefs, rng: &rng)
        points.newPoint(x: x, y: y, sprite: sprite, delay: 10, level: level, notRegistered: config.pointsNotRegistered)
        jewelsDone = true
        balloonsCaptureAllEnemies()
    }

    /// (`gTargetJewelXLoc`, `gTargetJewelYLoc`) as `char`s; `nil` is (0xff, 0xff) = (−1, −1).
    private var targetJewelOrNone: CellRef {
        targetJewel ?? CellRef(col: -1, row: -1)
    }
}
