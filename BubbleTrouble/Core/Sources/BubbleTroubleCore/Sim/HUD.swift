// The score bar and the level-start picture (plan 2026-10-04 btx-playable C3), transcribed from `_DrawMaze
// @ 00025daa`, `_DrawScore @ 00028168`, `_TimeBonus_Draw @ 00006b3a`, `_DrawReserveInfo @ 00021bd2`,
// `_DrawReserveHeroNumber @ 000218e8`, `_DrawReserveHeroImage @ 00021a3c`, `_Multiplier_Draw @ 00019bb4` and
// `_EXTRA_Draw @ 00019e8a`, with `_RequestDrawReserveHero @ 000218c4`, `_InitHero`'s and `_TimeBonus_Reset`'s
// presentation halves.
//
// Every HUD routine has the same shape: `_SetToCompGWorld`; `_ScoreToComp(src, dst)` (the score-bar cache over its
// area, src = dst − 440, which erases the old digits); its sprites into COMP; `_CompToScreen(rect)` (own rect, which
// also sets the port to the window). The sprites below therefore target `.comp`. (`_OffsetRect` by the full-screen
// origin, `environment[8]`, only moves the screen-side rect in full-screen mode and is not modelled here.)
//
// The session-facing builders (`levelStartOps`, `reserveInfoOps`, `scoreOps`, `timeBonusOps`, `multiplierOps`,
// `extraOps`) are the seams C4 calls at `_NewLevel`'s and `_TimeBonus_CountDown`'s call points; each returns only
// the ops it recorded.

extension GameState {
    /// `_gMultiplier_Rect` (`_Bonus_Init`): (448, 601, 476, 629).
    static let multiplierRect = QDRect(top: 0x1c0, left: 0x259, bottom: 0x1dc, right: 0x275)
    /// `_EXTRA_Draw`'s rect (322, 446)…(423, 478).
    static let extraRect = QDRect(top: 0x1be, left: 0x142, bottom: 0x1de, right: 0x1a7)
    /// `_EXTRA_Draw`'s letter positions (E, X, T, R, A).
    static let extraLetterX = [0x142, 0x152, 0x167, 0x17d, 0x193]
    /// `_gReserveHero_ImageR` (445, 16, 477, 48) and `_gReserveHero_NumR` (446, 55, 476, 77) (`_InitHero`).
    static let reserveImageRect = QDRect(top: 0x1bd, left: 0x10, bottom: 0x1dd, right: 0x30)
    static let reserveNumberRect = QDRect(top: 0x1be, left: 0x37, bottom: 0x1dc, right: 0x4d)

    // MARK: Session seams

    /// `_NewLevel @ 0001735f`'s picture, called right after the level is built: the presentation halves of
    /// `_InitHero` (reserve hero: not drawing, frame 4, not animating, 0 cycles, timer = frame) and
    /// `_TimeBonus_Reset` (bonus unchanged, rect (446, 480, 476, 480)), then `_DrawMaze` — `.drawMaze(LEVL w1)`
    /// (paint bgnd + comp black, the centred PICT into both), `.prepareScoreBar`, and every maze cell 10 / 15 / 16 /
    /// 20 / 30 / 52 as set 0x11 / 0x14 / 0x15 / 0x16 / 0x17 / (0x12 below level 12, else 0x13), frame 1, into comp
    /// (rows outer, columns inner) — then `_RequestDrawReserveHero(0)`. `_NewLevel` continues with `_SetToScreen` +
    /// `_WipeScreen(12)` (the session's `.wipe`) and the score bar (`reserveInfoOps`…`extraOps`).
    public mutating func levelStartOps() -> [DrawOp] {
        let start = presentation.ops.count
        presentation.reserveHeroNeedsDrawing = false
        presentation.reserveHeroAnimFrame = 4
        presentation.reserveHeroAnimate = false
        presentation.reserveHeroNumAnimCycles = 0
        presentation.reserveHeroAnimTimer = frame
        presentation.timeBonusHasChanged = false
        presentation.timeBonusRect = QDRect(top: 0x1be, left: 0x1e0, bottom: 0x1dc, right: 0x1e0)

        presentation.ops.append(.drawMaze(pictID: Int(levelRecord.words[1])))
        presentation.ops.append(.prepareScoreBar)
        for row in 0..<Maze.rows {
            for col in 0..<Maze.columns {
                let set: Int
                switch maze[col, row] {
                case 10: set = 0x11
                case 0xf: set = 0x14
                case 0x10: set = 0x15
                case 0x14: set = 0x16
                case 0x1e: set = 0x17
                case 0x34: set = level < 0xc ? 0x12 : 0x13
                default: continue
                }
                spriteToComp(set, 1, h: col * 0x28, v: row * 0x28, target: .comp)
            }
        }
        requestDrawReserveHero(animate: false)
        return takeOps(from: start)
    }

    /// `_DrawReserveInfo` (`_NewLevel`, `_TimeBonus_CountDown`).
    mutating func reserveInfoOps() -> [DrawOp] {
        let start = presentation.ops.count
        drawReserveInfo()
        return takeOps(from: start)
    }

    /// `_DrawScore(1)`.
    mutating func scoreOps() -> [DrawOp] {
        let start = presentation.ops.count
        drawScore(force: true)
        return takeOps(from: start)
    }

    /// `_TimeBonus_Draw(1)`.
    mutating func timeBonusOps() -> [DrawOp] {
        let start = presentation.ops.count
        timeBonusDraw(force: true)
        return takeOps(from: start)
    }

    /// `_Multiplier_Draw(1)` (no sprite at 1×).
    mutating func multiplierOps() -> [DrawOp] {
        let start = presentation.ops.count
        multiplierDraw(true)
        return takeOps(from: start)
    }

    /// `_EXTRA_Draw(1)`.
    mutating func extraOps() -> [DrawOp] {
        let start = presentation.ops.count
        extraDraw(true)
        return takeOps(from: start)
    }

    private mutating func takeOps(from start: Int) -> [DrawOp] {
        let out = Array(presentation.ops[start...])
        presentation.ops.removeSubrange(start...)
        return out
    }

    // MARK: Routines

    /// `_DrawScore(force) @ 00028168`: when forced or `gScoreHasChanged`: score cache over (446, 132)…(old right,
    /// 476); the score's decimal digits, least significant first, into an 8-byte buffer pre-set to 0,0,0,0,0,−1,−1,−1
    /// (so at least FIVE digits draw — leading zeros up to 5, none beyond); from index 7 down to 0, every entry ≠ −1
    /// → set 0x21 frame digit+1 at (right, 446), right += 24 (right starts at 132); `_CompToScreen(scoreRect)`;
    /// flag cleared.
    mutating func drawScore(force: Bool) {
        guard force || presentation.scoreHasChanged else { return }
        let oldRight = presentation.scoreRect.right
        presentation.ops.append(.scoreToComp(QDRect(top: 0x1be, left: 0x84, bottom: 0x1dc, right: oldRight)))
        var digits: [Int8] = [0, 0, 0, 0, 0, -1, -1, -1, 0]       // [8] = the stack byte a 9th digit lands on
        var n = score
        var i: Int8 = 0
        repeat {
            let q = n / 10
            digits[Int(i)] = Int8(truncatingIfNeeded: n) &- Int8(truncatingIfNeeded: q) &* 10
            let next = i &+ 1
            if next < 9 { i = next }
            n = q
        } while n != 0
        var rect = QDRect(top: 0x1be, left: 0x84, bottom: 0x1dc, right: 0x84)
        for k in stride(from: 7, through: 0, by: -1) where digits[k] != -1 {
            spriteToComp(0x21, Int(Int16(digits[k]) + 1), h: Int(rect.right), v: 0x1be, target: .comp)
            rect.right &+= 0x18
        }
        presentation.scoreRect = rect
        presentation.ops.append(.compToScreen(rect))
        presentation.scoreHasChanged = false
    }

    /// `_TimeBonus_Draw(force) @ 00006b3a`: when forced or `_gTimeBonusHasChanged`: score cache over (446, 480)…(old
    /// right, 476); the bonus's digits into a 5-byte zeroed buffer; from the ten-thousands down, skipping ONLY a zero
    /// ten-thousands digit (so 2500 draws "2500", 0 draws "0000"): set 0x21 (0x22 while flashing) frame digit+1 at
    /// (right, +22 when bonus < 10000; 446), right += 23; then right += 22 when bonus < 10000;
    /// `_CompToScreen(rect)`; flag cleared — and while the flash is on: it stays on only while `frame <= flash timer
    /// + 4`, and the flag is set again (one more redraw after it ends).
    mutating func timeBonusDraw(force: Bool) {
        guard force || presentation.timeBonusHasChanged else { return }
        let oldRight = presentation.timeBonusRect.right
        presentation.ops.append(.scoreToComp(QDRect(top: 0x1be, left: 0x1e0, bottom: 0x1dc, right: oldRight)))
        var digits: [Int8] = [0, 0, 0, 0, 0, 0]
        var n = timeBonus
        var i: Int8 = 0
        repeat {
            let q = n / 10
            digits[Int(i)] = Int8(truncatingIfNeeded: n) &- Int8(truncatingIfNeeded: q) &* 10
            let next = i &+ 1
            if next < 6 { i = next }
            n = q
        } while 0 < n
        var rect = QDRect(top: 0x1be, left: 0x1e0, bottom: 0x1dc, right: 0x1e0)
        for k in stride(from: 4, through: 0, by: -1) {
            let d = digits[k]
            guard (k != 4 || d != 0) && d != -1 else { continue }
            var h = rect.right
            if timeBonus < 10000 { h &+= 0x16 }
            spriteToComp(timeBonusFlash ? 0x22 : 0x21, Int(Int16(d) + 1), h: Int(h), v: 0x1be, target: .comp)
            rect.right &+= 0x17
        }
        if timeBonus < 10000 { rect.right &+= 0x16 }
        presentation.timeBonusRect = rect
        presentation.ops.append(.compToScreen(rect))
        presentation.timeBonusHasChanged = false
        if timeBonusFlash {
            if !(Int(frame) <= Int(timeBonusFlashTimer) + 4) {
                timeBonusFlash = false
            }
            presentation.timeBonusHasChanged = true
        }
    }

    /// `_RequestDrawReserveHero(animate) @ 000218c4`: needs drawing; animate = animate || animate-already.
    mutating func requestDrawReserveHero(animate: Bool) {
        presentation.reserveHeroNeedsDrawing = true
        if animate { presentation.reserveHeroAnimate = true }
    }

    /// `_DrawReserveInfo @ 00021bd2`: while the reserve hero needs drawing, the number then the image.
    mutating func drawReserveInfo() {
        guard presentation.reserveHeroNeedsDrawing else { return }
        drawReserveHeroNumber()
        drawReserveHeroImage()
    }

    /// `_DrawReserveHeroNumber @ 000218e8`: score cache over (445, 55)…(476, 77); lives above 9 → `_SetLives(9)`
    /// (unreachable: `_AddHero` caps at 9); set 0x21 frame max(lives, 1) at (55, 446) — digit frames are digit+1, so
    /// it shows the SPARE lives, lives − 1; `_CompToScreen` (446, 55, 476, 77).
    mutating func drawReserveHeroNumber() {
        presentation.ops.append(.scoreToComp(QDRect(top: 0x1bd, left: 0x37, bottom: 0x1dc, right: 0x4d)))
        if 9 < lives { lives = 9 }
        spriteToComp(0x21, lives < 1 ? 1 : Int(lives), h: 0x37, v: 0x1be, target: .comp)
        presentation.ops.append(.compToScreen(Self.reserveNumberRect))
    }

    /// `_DrawReserveHeroImage @ 00021a3c`: score cache over (444, 16)…(477, 48); not animating → needs-drawing
    /// cleared; animating and `timer < frame` → frame − 1 (≤ 0 → 12), timer = frame, and on reaching frame 4 a cycle
    /// counts — the 2nd ends the animation and the drawing; set 8 at (16, 445); `_CompToScreen` (445, 16, 477, 48).
    mutating func drawReserveHeroImage() {
        presentation.ops.append(.scoreToComp(QDRect(top: 0x1bc, left: 0x10, bottom: 0x1dd, right: 0x30)))
        if !presentation.reserveHeroAnimate {
            presentation.reserveHeroNeedsDrawing = false
        } else if presentation.reserveHeroAnimTimer < frame {
            let next = presentation.reserveHeroAnimFrame &- 1
            presentation.reserveHeroAnimFrame = 0 < next ? next : 0xc
            presentation.reserveHeroAnimTimer = frame
            if presentation.reserveHeroAnimFrame == 4 {
                presentation.reserveHeroNumAnimCycles &+= 1
                if presentation.reserveHeroNumAnimCycles == 2 {
                    presentation.reserveHeroNeedsDrawing = false
                    presentation.reserveHeroAnimate = false
                    presentation.reserveHeroNumAnimCycles = 0
                }
            }
        }
        spriteToComp(8, Int(presentation.reserveHeroAnimFrame), h: 0x10, v: 0x1bd, target: .comp)
        presentation.ops.append(.compToScreen(Self.reserveImageRect))
    }

    /// `_Multiplier_Draw(on) @ 00019bb4`: score cache over (446, 601)…(476, 629); on and multiplier ≠ 1 → set 0x23
    /// frame multiplier − 1 (x2…x5) at (601, 448); `_CompToScreen` (448, 601, 476, 629).
    mutating func multiplierDraw(_ on: Bool) {
        presentation.ops.append(.scoreToComp(QDRect(top: 0x1be, left: 0x259, bottom: 0x1dc, right: 0x275)))
        if on && multiplier != 1 {
            spriteToComp(0x23, Int(multiplier) - 1, h: 0x259, v: 0x1c0, target: .comp)
        }
        presentation.ops.append(.compToScreen(Self.multiplierRect))
    }

    /// `_EXTRA_Draw(on) @ 00019e8a`: score cache over (446, 322)…(478, 423); on → E, X, T, R, A as frames 1…5 of
    /// set 0x24 (lit) / 0x25 (unlit) at x 322, 338, 359, 381, 403, y 446; `_CompToScreen` of the same rect.
    mutating func extraDraw(_ on: Bool) {
        presentation.ops.append(.scoreToComp(Self.extraRect))
        if on {
            for k in 0..<5 {
                spriteToComp(extraLetters[k] ? 0x24 : 0x25, k + 1, h: Self.extraLetterX[k], v: 0x1be, target: .comp)
            }
        }
        presentation.ops.append(.compToScreen(Self.extraRect))
    }
}
