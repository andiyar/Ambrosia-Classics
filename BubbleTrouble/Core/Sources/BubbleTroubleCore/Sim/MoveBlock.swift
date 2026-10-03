// Moving blocks (plan §Task 8.1; Research note 36; Invariants 7, 8, 18; B11; INDEX C5), transcribed from
// `_MoveBlock @ 0001cccb`. Sounds (`_PlayMySnd(0x14)` on the squash — the blue/purple asymmetry: the `dir = 3`
// branch has none at step 4) are not modelled (no RNG).

extension GameState {
    /// `_MoveBlock(i) @ 0001cccb`, once per frame for every block with `+0x1a` (moving) set, from `_ProcessBlocks`.
    ///
    /// 1. A jewel (20) or cluster (30) with `_TimeBonus_GetBonus() < 1` becomes a normal bubble: type 10, state 1,
    ///    moving, sprite set 0x11, frame 1.
    /// 2. Unless bouncing (`+0x2c`): offset the rect 10 px in the direction (down +y, up −y, left −x, right +x); the
    ///    matching offset (`char`) ±10, and when it reaches ±40 the col/row steps by ±1 and the offset is 0.
    /// 3. aligned = both offsets 0.
    /// 4. On the rect inset by 3: `_WasEnemySquished` → `n = ++block.squishCount` (a `char`) and `_SquishEnemy(e, n)` —
    ///    the dead flag is not tested, so a dead, unfreed enemy advances the count (Invariant 7);
    ///    `_IsHeroCaught(block rect, 1, 0)` (the plain rect — it insets by 4 itself) → `_HeroCaught(2)`;
    ///    `_Balloons_CheckSquishes` (flying balloons only — C5); `_Bonus_WasHit`.
    /// 5. Not aligned → done. A jewel (20) → `_CheckJewelMovement(i, col, row)`, done. Else `next =
    ///    _GetNextObject(dir, col, row)`; next 0 or 'P' (80) and not bouncing → done (keep going).
    /// 6. Not blue/purple (`1 < (byte)(type − 15)`): retired, `gMaze[col, row] = type`, and dynamite (52) →
    ///    `_ExplodeBombBlock(i)` (which zeroes the cell — after the maze write).
    /// 7. Blue (15) / purple (16): bouncing = 1, step = step + 1; by direction (a, b) = up (2, 3), down (4, 5),
    ///    left (6, 7), right (8, 9): step 2 → frame b; step < 3 → old step ≠ 0 ? (frame 1, bouncing 0, retired —
    ///    no maze write; unreachable in play) : frame a; step 3 → frame a; step ≠ 4 → as the old-step case; step 4 →
    ///    frame 1, direction reversed, bouncing 0, step 0, `bounces++`, and `bounces > 1` (blue) / `> 2` (purple,
    ///    signed `short` compares) → retired, `gMaze[col, row] = type`.
    mutating func moveBlock(_ slot: Int) {
        let i = slot
        if blocks[i].type == CellCode.jewel || blocks[i].type == CellCode.cluster, timeBonus < 1 {
            blocks[i].type = CellCode.normal
            blocks[i].state = 1
            blocks[i].moving = true
            blocks[i].spriteSet = 0x11
            blocks[i].frame = 1
        }
        if !blocks[i].bouncing {
            switch blocks[i].direction {
            case .down:
                blocks[i].rect.offset(dx: 0, dy: 10)
                blocks[i].yOffset &+= 10
                if blocks[i].yOffset == 0x28 {
                    blocks[i].row &+= 1
                    blocks[i].yOffset = 0
                }
            case .up:
                blocks[i].rect.offset(dx: 0, dy: -10)
                blocks[i].yOffset &-= 10
                if blocks[i].yOffset == -0x28 {
                    blocks[i].row &-= 1
                    blocks[i].yOffset = 0
                }
            case .left:
                blocks[i].rect.offset(dx: -10, dy: 0)
                blocks[i].xOffset &-= 10
                if blocks[i].xOffset == -0x28 {
                    blocks[i].col &-= 1
                    blocks[i].xOffset = 0
                }
            case .right:
                blocks[i].rect.offset(dx: 10, dy: 0)
                blocks[i].xOffset &+= 10
                if blocks[i].xOffset == 0x28 {
                    blocks[i].col &+= 1
                    blocks[i].xOffset = 0
                }
            case nil:
                break
            }
        }
        blocks[i].aligned = blocks[i].xOffset == 0 && blocks[i].yOffset == 0

        var hitRect = blocks[i].rect
        hitRect.inset(dx: 3, dy: 3)
        let e = wasEnemySquished(hitRect)
        if e != -1 {
            blocks[i].squishCount &+= 1
            squishEnemy(e, count: Int(blocks[i].squishCount))
        }
        if isHeroCaught(blocks[i].rect, protectInvisible: true, bigInset: false) {
            heroCaught(kind: 2)
        }
        balloonsCheckSquishes(hitRect)
        _ = bonusWasHit(hitRect)

        guard blocks[i].aligned else { return }
        let col = Int(blocks[i].col), row = Int(blocks[i].row)
        if blocks[i].type == CellCode.jewel {
            checkJewelMovement(i, col: col, row: row)
            return
        }
        guard let dir = blocks[i].direction else {
            // `_GetNextObject` with direction 0: the original's `_DebugValues` + `_CleanUp` (quit). A moving block
            // always carries a direction, so this cannot arise from the modelled callers.
            pendingStops.insert(.originalWouldAbort("GetNextObject - bad direction"))
            return
        }
        let next = getNextObject(dir, col: col, row: row)
        if next == 0 || next == CellCode.passableP, !blocks[i].bouncing {
            return
        }
        let type = blocks[i].type
        if !(type == CellCode.blue || type == CellCode.purple) {
            blocks[i].retired = true
            maze.cells[col + row * Maze.columns] = type
            if type == CellCode.dynamite {
                explodeBombBlock(i)
            }
            return
        }

        blocks[i].bouncing = true
        let oldStep = blocks[i].bounceStep
        let step = oldStep &+ 1
        blocks[i].bounceStep = step
        let frames: (a: Int16, b: Int16)
        switch dir {
        case .up: frames = (2, 3)
        case .down: frames = (4, 5)
        case .left: frames = (6, 7)
        case .right: frames = (8, 9)
        }
        if step == 2 {
            blocks[i].frame = frames.b
            return
        }
        if step < 3 {
            if oldStep != 0 {
                abandonBounce(i)
                return
            }
            blocks[i].frame = frames.a
            return
        }
        if step == 3 {
            blocks[i].frame = frames.a
            return
        }
        if step != 4 {
            abandonBounce(i)
            return
        }
        blocks[i].frame = 1
        blocks[i].direction = dir.opposite
        blocks[i].bouncing = false
        blocks[i].bounceStep = 0
        blocks[i].bounces &+= 1
        let limit: Int16 = type == CellCode.blue ? 1 : 2
        if blocks[i].bounces <= limit {
            return
        }
        blocks[i].retired = true
        maze.cells[col + row * Maze.columns] = blocks[i].type
    }

    /// `code_r0x0001d049` in `_MoveBlock`: frame 1, bouncing 0, retired — the maze is not written.
    private mutating func abandonBounce(_ i: Int) {
        blocks[i].frame = 1
        blocks[i].bouncing = false
        blocks[i].retired = true
    }
}
