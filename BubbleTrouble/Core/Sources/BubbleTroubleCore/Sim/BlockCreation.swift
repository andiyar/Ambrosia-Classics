// Block creation (plan §Task 5b.1; Research notes 26, 35; Invariant 8), transcribed from `_NewBlock @ 0001b94b`,
// `_PushBlock @ 0001bd62`, `_CrushBlock @ 0001bc14`, `_KillEggBlock @ 0001be3b`, `_IsActiveBombBlock @ 0001c9c6`,
// `_ActivateBombBlock @ 0001c1c4`. Sounds are not modelled (no RNG).

extension GameState {
    /// `_NewBlock(col, row, dir, type, enemy, moving) @ 0001b94b`: the first slot (0…34) whose state byte is 0. None
    /// free → the original returns 0 and its callers quit (`_CrushBlock`/`_PushBlock` `_CleanUp`, `_CheckNewEnemies`
    /// `_StdError`) — the replica stops with a precondition failure (Research note 35). The slot gets rect = prevRect
    /// = the cell, type, direction, aligned, chain count 0, col/row, offsets 0, egg toggle 0, anim counter 0, retired 0,
    /// enemy, bouncing 0, bounces 0, bounce step 0; then by type: 10/15/16 → state 1, moving, sprite 0x11/0x14/0x15,
    /// frame 1; 20 → state 1, moving, 0x16, frame 1, jewel cell; 30 → state 1, static, 0x17, frame 1, jewel cell;
    /// 40 → state 2, static, 0x18, frame 1; 51 → nothing (state stays 0); 52 → `moving` ? state 1, moving, frame 1
    /// : state 3, static, frame 2, sprite 0x12 below level 12 else 0x13; 60 → state 3, static, 0x1f, frame = the
    /// enemy's type, egg pop delay 15; any other type is the original's "Unknown block type" quit (precondition).
    /// Finally start = frame and `_gNumActiveBlocks++`. Returns the slot (the original returns 1).
    @discardableResult
    mutating func newBlock(col: Int, row: Int, direction: Direction?, type: UInt8, enemy: Int8, moving: Bool) -> Int {
        guard let i = blocks.firstIndex(where: { $0.state == 0 }) else {
            preconditionFailure("NewBlock() - none free (35 slots): the original quits here")
        }
        let c = Int8(truncatingIfNeeded: col), r = Int8(truncatingIfNeeded: row)
        let rect = QDRect(top: Int16(r) &* 0x28, left: Int16(c) &* 0x28,
                          bottom: Int16(r) &* 0x28 &+ 0x28, right: Int16(c) &* 0x28 &+ 0x28)
        blocks[i].rect = rect
        blocks[i].prevRect = rect
        blocks[i].type = type
        blocks[i].direction = direction
        blocks[i].aligned = true
        blocks[i].squishCount = 0
        blocks[i].col = c
        blocks[i].row = r
        blocks[i].xOffset = 0
        blocks[i].yOffset = 0
        blocks[i].eggToggle = false
        blocks[i].animCounter = 0
        blocks[i].retired = false
        blocks[i].enemy = enemy
        blocks[i].bouncing = false
        blocks[i].bounces = 0
        blocks[i].bounceStep = 0
        switch type {
        case 10, 0xf, 0x10:
            blocks[i].state = 1
            blocks[i].moving = true
            blocks[i].spriteSet = type == 10 ? 0x11 : (type == 0xf ? 0x14 : 0x15)
            blocks[i].frame = 1
        case 0x14, 0x1e:
            blocks[i].state = 1
            blocks[i].moving = type == 0x14
            blocks[i].spriteSet = type == 0x14 ? 0x16 : 0x17
            blocks[i].frame = 1
            blocks[i].jewelCol = c
            blocks[i].jewelRow = r
        case 0x28:
            blocks[i].state = 2
            blocks[i].moving = false
            blocks[i].spriteSet = 0x18
            blocks[i].frame = 1
        case 0x33:
            break
        case 0x34:
            if moving {
                blocks[i].state = 1
                blocks[i].moving = true
                blocks[i].frame = 1
            } else {
                blocks[i].state = 3
                blocks[i].moving = false
                blocks[i].frame = 2
            }
            blocks[i].spriteSet = level < 0xc ? 0x12 : 0x13
        case 0x3c:
            blocks[i].state = 3
            blocks[i].moving = false
            blocks[i].spriteSet = 0x1f
            blocks[i].frame = Int16(enemies[Int(enemy)].type)
            blocks[i].eggPopDelay = 0xf
        default:
            preconditionFailure("NewBlock() - Unknown block type: \(type): the original quits here")
        }
        blocks[i].startFrame = frame
        numActiveBlocks += 1
        return i
    }

    /// `_PushBlock(col, row, dir, type) @ 0001bd62` (the hero at (col, row) pushes the cell in `dir`):
    /// `_NewBlock(next cell, dir, type, −1, moving 1)`, then that maze cell = 0.
    mutating func pushBlock(col: Int, row: Int, direction: Direction, type: UInt8) {
        let next = Self.adjacentCell(col: col, row: row, direction)
        newBlock(col: next.col, row: next.row, direction: direction, type: type, enemy: -1, moving: true)
        maze.cells[next.col + next.row * Maze.columns] = 0
    }

    /// `_CrushBlock(col, row, dir, score) @ 0001bc14`: `_NewBlock(next cell, dir, 0x28, −1, 0)` (a pop block); the
    /// maze cell becomes 0x28 unless it holds dynamite (0x34); when `score`, `_AddToScore(1, 1)` (×mult). (The
    /// licence-checksum mismatch branch — `GetRandomFast(0,0x28)`, −5120 — is outside the modelled licence state.)
    mutating func crushBlock(col: Int, row: Int, direction: Direction, score: Bool) {
        let next = Self.adjacentCell(col: col, row: row, direction)
        newBlock(col: next.col, row: next.row, direction: direction, type: 0x28, enemy: -1, moving: false)
        let i = next.col + next.row * Maze.columns
        if maze.cells[i] != CellCode.dynamite {
            maze.cells[i] = CellCode.popping
        }
        if score {
            addToScore(1, multiply: true)
        }
    }

    /// `_KillEggBlock(col, row, dir) @ 0001be3b` (the hero pushes an egg cell): the first block (0…34) of type 0x3c
    /// at the next cell — the state byte is not tested — becomes type 0x28, state 2, start = frame, static, sprite
    /// 0x18, frame 1, egg toggle 0, anim counter 0; maze cell = 0x28; `_AddToScore(50, 1)`; `_NewPoint(block.left,
    /// block.top, 0x15, 0xc)`; `_KillEnemy(block.enemy, 0)`; `_NewStarGroup(block.col·40, block.row·40, g)` with g by
    /// the enemy's sprite set: 0x1c / 0x1e → 4, 0x1b → 3, else 5 (otool 0001bf86–0001c008). No egg block → nothing.
    mutating func killEggBlock(col: Int, row: Int, direction: Direction) {
        let next = Self.adjacentCell(col: col, row: row, direction)
        let c = Int8(truncatingIfNeeded: next.col), r = Int8(truncatingIfNeeded: next.row)
        guard let i = blocks.firstIndex(where: { $0.type == CellCode.egg && $0.col == c && $0.row == r }) else {
            return
        }
        blocks[i].type = CellCode.popping
        blocks[i].state = 2
        blocks[i].startFrame = frame
        blocks[i].moving = false
        blocks[i].spriteSet = 0x18
        blocks[i].frame = 1
        blocks[i].eggToggle = false
        blocks[i].animCounter = 0
        maze.cells[Int(blocks[i].col) + Int(blocks[i].row) * Maze.columns] = CellCode.popping
        addToScore(0x32, multiply: true)
        points.newPoint(x: blocks[i].rect.left, y: blocks[i].rect.top, sprite: 0x15, delay: 0xc, level: level,
                        notRegistered: config.pointsNotRegistered)
        let enemy = Int(blocks[i].enemy)
        killEnemy(enemy, clearCell: false)
        let group: Int
        switch enemies[enemy].spriteSet {
        case 0x1c, 0x1e: group = 4
        case 0x1b: group = 3
        default: group = 5
        }
        stars.newGroup(x: Int16(blocks[i].col) &* 0x28, y: Int16(blocks[i].row) &* 0x28, group: group,
                       hero: heroAnchor, frame: frame, prefs: config.prefs, rng: &rng)
    }

    /// `_IsActiveBombBlock(col, row) @ 0001c9c6`: some block (0…34) with a non-zero state, type 0x34, at (col, row).
    /// The retire flag is not tested.
    func isActiveBombBlock(col: Int, row: Int) -> Bool {
        let c = Int8(truncatingIfNeeded: col), r = Int8(truncatingIfNeeded: row)
        return blocks.contains { $0.state != 0 && $0.type == CellCode.dynamite && $0.col == c && $0.row == r }
    }

    /// `_ActivateBombBlock(col, row, dir) @ 0001c1c4` (the hero pushes a blocked dynamite cell): the first block with
    /// a non-zero state, type 0x34, at the next cell (retire flag not tested): `frame <= start + 0x1e` → nothing,
    /// else `_ExplodeBombBlock(slot)` now (otool 0001c23b–0001c25c). None → `_NewBlock(next cell, dir, 0x34, −1, 0)`
    /// — a static, lit fuse (state 3, frame 2).
    mutating func activateBombBlock(col: Int, row: Int, direction: Direction) {
        let next = Self.adjacentCell(col: col, row: row, direction)
        let c = Int8(truncatingIfNeeded: next.col), r = Int8(truncatingIfNeeded: next.row)
        if let i = blocks.firstIndex(where: {
            $0.state != 0 && $0.type == CellCode.dynamite && $0.col == c && $0.row == r
        }) {
            if Int(frame) <= Int(blocks[i].startFrame) + 0x1e { return }
            explodeBombBlock(i)
            return
        }
        newBlock(col: next.col, row: next.row, direction: direction, type: CellCode.dynamite, enemy: -1, moving: false)
    }

    /// The cell one step from (col, row) in `dir` — the `char` adjustments at the top of `_PushBlock`, `_CrushBlock`,
    /// `_KillEggBlock`, `_ActivateBombBlock` (up row − 1, down row + 1, left col − 1, right col + 1).
    static func adjacentCell(col: Int, row: Int, _ dir: Direction) -> (col: Int, row: Int) {
        switch dir {
        case .up: (col, row - 1)
        case .down: (col, row + 1)
        case .left: (col - 1, row)
        case .right: (col + 1, row)
        }
    }
}
