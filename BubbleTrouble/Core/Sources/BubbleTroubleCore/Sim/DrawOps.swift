// The frame's QuickDraw calls as `DrawOp`s (plan 2026-10-04 btx-playable C3; Invariant 2: recorded at the original's
// call site, in order, before any slot is freed; Invariant 3: no RNG draw, no simulation outcome changes).
//
// The OS X path of `_PlayGame @ 00018247` (orchestrator ruling after R1's fidelity review; every branch checked in
// the i386 disassembly): `_IsDoubleBuffered()` = `_IsOSX()` is true, so the frame takes `_SetToScreen` (00018bac–
// 00018bc8) and every playfield call lands in the WINDOW:
//   - `_RestoreBgnd(0)` → `_RestoreBgndRect(r, 0)` → (`_UsingQDPlotting` = `gUsePlotIcon` = 1 on OS X,
//     `_InitSpritePlottingTechnique @ 00014ab5`) → `_BgndToScreen` (branch at 00015cda) → `.restoreBgnd(r, .screen)`;
//   - `_SpriteToComp` / `_TransSpriteToComp` plot into the current port (`_ASWPlotCIcon` → `PlotCIcon`) = the window
//     → `.sprite(…, target: .screen)`;
//   - `_DrawRectsToScreen` is skipped (00018c30) — so the `_AddRectToScreen @ 0002635a` list is never consumed on
//     OS X and is NOT recorded; the window is flushed whole (`_FlushIfNecessary` → `QDFlushPortBuffer`);
//   - only the HUD goes through comp (`HUD.swift`): `_SetToCompGWorld`, `_ScoreToComp`, sprites into comp, then
//     `_CompToScreen` of its own rect (which itself calls `_SetToScreen`).
//   - the conditional `_ScreenToComp` after the flush (00018c6c, the pause entry) and on game exit (000192ed) are
//     the session's (C4): they follow the pause / exit decisions it owns.
//
// `_AddRectToBgnd @ 00015e09` (22 call sites; the 21 reachable from the frame body — all but `_DisplayHiScores`
// 00025961 — are wired in at their sites, each caller says which) both queues a restore rect and, through `_CheckBlock @ 0001b842`, puts every stationary
// maze bubble the rect touches on the hurt-block list (`_NewHurtBlock @ 0001b6d0`), which `_DrawHurtBlocksToComp`
// redraws right after the restore: `_DrawMaze` paints the maze bubbles into comp only, never into bgnd, so a restore
// would otherwise wipe them.

/// The draw-only globals of the frame (no RNG, never read by the simulation).
public struct Presentation: Equatable, Sendable {
    /// `_sNumBgndRects` (`__data` 0x34148 = 80): the list appends while the count is below 79.
    public static let bgndRectCapacity = 80

    /// This frame's (or this call's) recorded ops, in call order.
    public internal(set) var ops: [DrawOp] = []
    /// `_sBgndRectList` / `_sBgndRectCount` — emptied by `_ResetNumBgndRects` at the top of each frame.
    public internal(set) var bgndRects: [QDRect] = []

    /// `gScoreHasChanged` (`_AddToScore`, `_ResetScore`; cleared by `_DrawScore`).
    public internal(set) var scoreHasChanged = false
    /// `gScoreRect`: `_DrawScore` leaves its right edge after the last digit; the next draw erases up to it.
    /// `_ResetScore @ 00028085`: (446, 132, 476, 132).
    public internal(set) var scoreRect = QDRect(top: 0x1be, left: 0x84, bottom: 0x1dc, right: 0x84)
    /// `_gTimeBonusHasChanged`.
    public internal(set) var timeBonusHasChanged = false
    /// `_gTimeBonusRect` (`_TimeBonus_Reset @ 00006930`: (446, 480, 476, 480)).
    public internal(set) var timeBonusRect = QDRect(top: 0x1be, left: 0x1e0, bottom: 0x1dc, right: 0x1e0)

    /// `_gReserveHero_NeedsDrawing` / `_Animate` / `_AnimFrame` / `_AnimTimer` / `_NumAnimCycles` (`_InitHero`).
    public internal(set) var reserveHeroNeedsDrawing = false
    public internal(set) var reserveHeroAnimate = false
    public internal(set) var reserveHeroAnimFrame: Int16 = 4
    public internal(set) var reserveHeroAnimTimer: UInt16 = 0
    public internal(set) var reserveHeroNumAnimCycles: Int16 = 0

    /// `_gOuchR` / `_gOuchSpriteFace` (`_NewOuch @ 00021d2f`).
    public internal(set) var ouchRect = QDRect(top: 0, left: 0, bottom: 0, right: 0)
    public internal(set) var ouchFace: Int16 = 0

    /// `gGhostIcons` (the ghost-icons cheat, C8; `_PlayGame` zeroes it on entry): `_SpriteToComp` then plots with
    /// `_PlotCIconHandle(…, 3, …)`.
    public internal(set) var ghostIcons = false

    public init() {}
}

extension GameState {
    // MARK: Primitives

    /// `_SpriteToComp(0, h, v, set, frame) @ 00015398` into `target` (the current port): `.ghost` while
    /// `gGhostIcons`, else `.normal`.
    mutating func spriteToComp(_ set: Int, _ frame: Int, h: Int, v: Int, target: DrawTarget) {
        presentation.ops.append(.sprite(set: set, frame: frame, h: h, v: v,
                                        mode: presentation.ghostIcons ? .ghost : .normal, target: target))
    }

    /// `_TransSpriteToComp @ 0001566e` (ghost icons do not apply).
    mutating func transSpriteToComp(_ set: Int, _ frame: Int, h: Int, v: Int, target: DrawTarget) {
        presentation.ops.append(.sprite(set: set, frame: frame, h: h, v: v, mode: .transparent, target: target))
    }

    /// `_AddRectToBgnd(r) @ 00015e09` with `gUsePlotIcon` = 1 (OS X): left rounded down and right up to a multiple
    /// of 4; left / top clamped to ≥ 0, right to ≤ 640, bottom to ≤ 440; `_CheckBlock` for every cell from
    /// (left / 40, top / 40) to (min((right − 1) / 40, 15), min((bottom − 1) / 40, 10)) — columns outer, rows inner,
    /// counts in `char`; then the adjusted rect is appended while the count is below 79, else merged into the entry
    /// whose bounding union grows least (`(union area) − (entry area)`, unsigned, first minimum wins).
    mutating func addRectToBgnd(_ r: QDRect) {
        var top = r.top, left = r.left, bottom = r.bottom, right = r.right
        left = Int16(bitPattern: UInt16(bitPattern: left) & 0xfffc)
        right = Int16(bitPattern: (UInt16(bitPattern: right) &+ 3) & 0xfffc)
        let c0: Int8
        if left < 0 {
            left = 0
            c0 = 0
        } else {
            c0 = Int8(truncatingIfNeeded: Int(left) / 0x28)
        }
        let rightEdge: Int
        if right < 0x281 {
            rightEdge = Int(right)
        } else {
            right = 0x280
            rightEdge = 0x280
        }
        let r0: Int8
        if top < 0 {
            top = 0
            r0 = 0
        } else {
            r0 = Int8(truncatingIfNeeded: Int(top) / 0x28)
        }
        let bottomEdge: Int
        if bottom < 0x1b9 {
            bottomEdge = Int(bottom)
        } else {
            bottom = 0x1b8
            bottomEdge = 0x1b8
        }
        let c1 = Int16(truncatingIfNeeded: (rightEdge - 1) / 0x28)
        let r1 = Int16(truncatingIfNeeded: (bottomEdge - 1) / 0x28)
        let cLast: Int16 = c1 < 0x10 ? c1 : 0xf
        let rLast: Int16 = r1 < 0xb ? r1 : 10
        let nCols = Int8(truncatingIfNeeded: Int(Int8(truncatingIfNeeded: cLast)) - Int(c0) + 1)
        let nRows = Int8(truncatingIfNeeded: Int(Int8(truncatingIfNeeded: rLast)) - Int(r0) + 1)
        var i: Int16 = 0
        while i < Int16(nCols) {
            var j: Int16 = 0
            while j < Int16(nRows) {
                checkBlock(col: c0 &+ Int8(truncatingIfNeeded: i), row: r0 &+ Int8(truncatingIfNeeded: j))
                j += 1
            }
            i += 1
        }
        let adjusted = QDRect(top: top, left: left, bottom: bottom, right: right)
        if presentation.bgndRects.count < Presentation.bgndRectCapacity - 1 {
            presentation.bgndRects.append(adjusted)
            return
        }
        var best = 0
        var bestCost = UInt32.max
        var bestUnion = adjusted
        for (k, e) in presentation.bgndRects.enumerated() {
            let minL = e.left < left ? e.left : left
            let minT = e.top <= top ? e.top : top
            let maxR = right <= e.right ? e.right : right
            let maxB = bottom <= e.bottom ? e.bottom : bottom
            let cost = (Int(maxB) - Int(minT)) * (Int(maxR) - Int(minL))
                - (Int(e.right) - Int(e.left)) * (Int(e.bottom) - Int(e.top))
            let u = UInt32(truncatingIfNeeded: cost)
            if u < bestCost {
                bestCost = u
                best = k
                bestUnion = QDRect(top: minT, left: minL, bottom: maxB, right: maxR)
            }
        }
        presentation.bgndRects[best] = bestUnion
    }

    /// `_CheckBlock(col, row) @ 0001b842`: a maze cell holding 10…60 (`(byte)(cell − 10) < 0x33`) that no non-free
    /// block occupies (block `+0x17`/`+0x18`) → `_NewHurtBlock(col, row, cell)`.
    mutating func checkBlock(col: Int8, row: Int8) {
        let index = Int(col) + Int(row) * Maze.columns
        guard maze.cells.indices.contains(index) else { return }      // outside gMaze: unreachable from real rects
        let cell = maze.cells[index]
        guard cell &- 10 < 0x33 else { return }
        if blocks.contains(where: { $0.state != 0 && $0.col == col && $0.row == row }) { return }
        newHurtBlock(col: col, row: row, cell: cell)
    }

    /// `_NewHurtBlock(col, row, cell) @ 0001b6d0`: scans all 50 entries — an active one already at (col, row) →
    /// nothing; else the first free entry: active, col/row, left = col·40, top = row·40, then by cell: 10 → set 0x11,
    /// 15 → 0x14, 16 → 0x15, 60 → 0x1f (frame LEVL w3); 20 → 0x16, 30 → 0x17 (frame LEVL w4); 52 → 0x12 below level
    /// 12 else 0x13, frame 1; any other cell leaves the entry's set and frame as they were (stale — replicated).
    mutating func newHurtBlock(col: Int8, row: Int8, cell: UInt8) {
        var free: Int?
        for k in hurtBlocks.indices {
            if !hurtBlocks[k].active {
                if free == nil { free = k }
            } else if hurtBlocks[k].col == col && hurtBlocks[k].row == row {
                return
            }
        }
        guard let k = free else { return }
        hurtBlocks[k].active = true
        hurtBlocks[k].col = col
        hurtBlocks[k].row = row
        hurtBlocks[k].left = Int16(col) &* 0x28
        hurtBlocks[k].top = Int16(row) &* 0x28
        switch cell {
        case 10: hurtBlocks[k].spriteSet = 0x11; hurtBlocks[k].frame = levelRecord.words[3]
        case 0xf: hurtBlocks[k].spriteSet = 0x14; hurtBlocks[k].frame = levelRecord.words[3]
        case 0x10: hurtBlocks[k].spriteSet = 0x15; hurtBlocks[k].frame = levelRecord.words[3]
        case 0x14: hurtBlocks[k].spriteSet = 0x16; hurtBlocks[k].frame = levelRecord.words[4]
        case 0x1e: hurtBlocks[k].spriteSet = 0x17; hurtBlocks[k].frame = levelRecord.words[4]
        case 0x34:
            hurtBlocks[k].spriteSet = level < 0xc ? 0x12 : 0x13
            hurtBlocks[k].frame = 1
        case 0x3c: hurtBlocks[k].spriteSet = 0x1f; hurtBlocks[k].frame = levelRecord.words[3]
        default: break
        }
    }

    /// `_RestoreBgnd(0) @ 00015dbe` on OS X: one `.restoreBgnd(entry, target: .screen)` per dirty-list entry, in
    /// list order (`_RestoreBgndRect`'s clip to 640×440 and empty-rect skip are the renderer's).
    mutating func restoreBgndToScreen() {
        for r in presentation.bgndRects {
            presentation.ops.append(.restoreBgnd(r, target: .screen))
        }
    }

    /// `_NewOuch @ 00021d2f` ("Erk!", called by `_HeroCaught` after `_StopAllEnemies`): facing right (4) → face 2,
    /// left = hero.right − 8; else face 1, left = hero.left − 37; left clamped to 0…595, top = hero.top − 30 clamped
    /// to 0…391; rect = (top, left, top + 49, left + 45).
    mutating func newOuch() {
        let face: Int16
        var left: Int16
        if hero.facing == .right {
            face = 2
            left = hero.rect.right &- 8
        } else {
            face = 1
            left = hero.rect.left &- 0x25
        }
        if left < 0 { left = 0 }
        if 0x253 < left { left = 0x253 }
        var top: Int16 = 0
        if hero.rect.top &- 0x1e >= 0 { top = hero.rect.top &- 0x1e }
        if 0x187 < top { top = 0x187 }
        presentation.ouchFace = face
        presentation.ouchRect = QDRect(top: top, left: left, bottom: top &+ 0x31, right: left &+ 0x2d)
    }

    /// `_EraseOuch @ 00022ce3` (state 3 → 4): `_AddRectToBgnd(gOuchR)` (+ the unused screen list).
    mutating func eraseOuch() {
        addRectToBgnd(presentation.ouchRect)
    }

    /// `_DrawOuchToComp @ 00022d03`: hero state 3 → the "Erk!" bubble (set 0x10, frame = face) at the ouch rect.
    mutating func drawOuch() {
        guard hero.state == 3 else { return }
        spriteToComp(0x10, Int(presentation.ouchFace), h: Int(presentation.ouchRect.left),
                     v: Int(presentation.ouchRect.top), target: .screen)
    }

    /// `_EraseNotice @ 0002784e` (after `_Sounds_CheckDelayedSounds`, before the draw pass): the erased notice's
    /// rects onto the bgnd list (NoticeBoard's transcription; its screen-list half is unused on OS X).
    mutating func eraseNotice() {
        for r in notices.erase().restore {
            addRectToBgnd(r)
        }
    }

    /// `_DrawNotice @ 00027948` in the frame: the notice's `_SpriteToComp`s plot into the current port — the window
    /// on OS X — and PAUSED's `_DrawPictInRect`s go to the port `_IsDoubleBuffered` selects (`_SetToScreen`).
    /// NoticeBoard records comp-targeted ops; the frame retargets them to `.screen` (and applies ghost icons).
    mutating func drawNotice() {
        for op in notices.draw(level: level).ops {
            switch op {
            case let .sprite(set, frame, h, v, _, _):
                spriteToComp(set, frame, h: h, v: v, target: .screen)
            case let .pict(id, dst, _):
                presentation.ops.append(.pict(id: id, dst: dst, target: .screen))
            default:
                preconditionFailure("NoticeBoard.draw emits only .sprite and .pict")
            }
        }
    }

    /// `_PrepareNotice(n) @ 00027829` — the frame's own sites call it; the session uses it for `_NewLevel` / pause.
    public mutating func prepareNotice(_ n: Int) {
        notices.prepare(n)
    }

    /// `_ResetNotices @ 000276d8`.
    public mutating func resetNotices() {
        notices.reset()
    }

}
