// The hero (plan §Task 6.1; Invariant 5; Research notes 23, 25, 26; hero-and-input.md §2–§4, §7), transcribed from
// `_ProcessHero @ 00022de0`, `_MoveHeroAligned @ 00022847`, `_MoveHeroNotAligned @ 000224c8`,
// `_HeroPushCrushCheck @ 000220d8` (with `_MyOffsetRect @ 0000c3d2` = `QDRect.offset`). Sounds are cued, `_AddRectToBgnd`
// (00022df5) is recorded (C3); `_DebugValues` is not modelled (no RNG). The licence-checksum blocks of `_ProcessHero` (state 4's `+0x24`
// recomputation, the push branch's `+0x44`) draw no RNG and are outside the modelled licence state (Decision 2).

extension GameState {
    /// `_ProcessHero @ 00022de0` (Research note 23). States 3 and 1 return; state 4 runs the death animation.
    /// Otherwise: latch `gLevelForEffect` (`_Get13To22()` = L) while it is 50; invisibility timeline; the speed-up
    /// timeline (never enabled in the shipped build, transcribed); balloon trap (returns — and the release call
    /// returns too, so it samples nothing, Invariant 5); push/pop freeze (returns; the ending call restores the
    /// walking sprite for the facing with the sprite-swap draw, frame 1); `_CheckHeroMovement` (state 2 — the only
    /// sample read); not aligned → `_MoveHeroNotAligned`; aligned + push held → `_HeroPushCrushCheck` FIRST (1 → push
    /// freeze, duration 2; 2 → pop freeze, duration 5; both return, so no turn draw that call); otherwise a held
    /// direction → `_MoveHeroAligned`.
    mutating func processHero<I: InputSource>(input: inout I) {
        addRectToBgnd(hero.prevRect)                            // 00022df5, first thing, every state
        switch hero.state {
        case 3, 1: return
        case 4:
            processHeroDying()
            return
        default: break
        }
        if levelForEffect == 0x32 {
            levelForEffect = config.latches.L                  // `_Get13To22()` — latched in `_Interface`, no draw
        }
        if hero.invisible {
            if Int(hero.invisibleStart) + 300 < Int(frame) {
                hero.invisible = false
                hero.drawTransparent = false
            } else if Int(hero.invisibleStart) + 0xd2 < Int(frame) {
                hero.blinkCounter &+= 1
                if 2 < hero.blinkCounter {
                    hero.blinkCounter = 0
                    hero.blinkToggle.toggle()
                }
                hero.drawTransparent = hero.blinkToggle
            }
        }
        if hero.speedUp {
            if Int(hero.speedUpStart) + 0x1c2 < Int(frame) {
                hero.speedUp = false
                hero.speed = 5
            } else if Int(hero.speedUpStart) + 0x168 < Int(frame) {
                hero.speedUpBlinkCounter &+= 1
                if 6 < hero.speedUpBlinkCounter {
                    hero.speedUpBlinkCounter = 0
                    hero.speedUpBlinkToggle.toggle()
                }
            }
        }
        if hero.trapped {
            if Int(frame) <= Int(hero.trapStart) + 0x5a { return }
            hero.trapped = false
            return
        }
        if hero.frozen {
            hero.freezeCounter &+= 1
            if hero.freezeCounter <= hero.freezeDuration { return }
            hero.frozen = false
            switch hero.facing {
            case .up:
                hero.spriteSet = 2
                if spriteSwapDraw() { hero.spriteSet = 3 }
            case .down:
                hero.spriteSet = 3
                if spriteSwapDraw() { hero.spriteSet = 2 }
            case .left:
                hero.spriteSet = 4
                if spriteSwapDraw() { hero.spriteSet = 5 }
            case .right:
                hero.spriteSet = 5
                if spriteSwapDraw() { hero.spriteSet = 4 }
            }
            hero.spriteFrame = 1
            return
        }
        if hero.state == 2 {
            checkHeroMovement(input: &input)
        }
        if !hero.aligned {
            moveHeroNotAligned()
            guard hero.speedUp, hero.speedUpBlinkToggle else { return }
            let group: Int
            switch hero.facing {
            case .up: group = 6
            case .down: group = 7
            case .left: group = 8
            case .right: group = 9
            }
            stars.newGroup(x: Int16(hero.col) &* 0x28, y: Int16(hero.row) &* 0x28, group: group, hero: heroAnchor,
                           frame: frame, prefs: config.prefs, rng: &rng)
            return
        }
        if heroKeys.push {
            switch heroPushCrushCheck() {
            case 1:
                hero.spriteSet = 6
                hero.registered = config.registeredValidLicence          // `+0x3a = RT3_IsRegistered()`
                hero.spriteFrame = Int16(hero.facing.rawValue)
                hero.frozen = true
                hero.freezeCounter = 0
                hero.freezeDuration = 2
                return
            case 2:
                hero.spriteSet = 6
                hero.spriteFrame = Int16(hero.facing.rawValue)
                hero.frozen = true
                hero.freezeCounter = 0
                // `+0x24 == 0 && licence code != 0` (a cracked copy) draws `GetRandomFast(0,0x1e)` above score 17923,
                // may toggle the speed 5 ↔ 1, and falls through to `_MoveHeroAligned`. The core models no licence
                // code (Decision 2: registered, valid), so the original's `bVar2` is always true here: duration 5,
                // return.
                hero.freezeDuration = 5
                return
            default: break
            }
        }
        if !heroMoveKeyDown { return }
        moveHeroAligned()
    }

    /// `_ProcessHero`'s state-4 branch: sprite set 7, `+0x42++`; when it exceeds 1 → `+0x42 = 0`, frame `+0x3e++`;
    /// when the frame exceeds 16 → (visible `+0x4a` and not yet emitted `+0x4b`) `_Bubbles_NewGroup(hero.left,
    /// hero.top, 0xb)` and `+0x4b = 1`; frame = 16; `+0x48++`. From `_PlayGame`'s 3 → 4 values (frame 1, `+0x42` 0)
    /// the bubbles fire on the 32nd call.
    private mutating func processHeroDying() {
        hero.spriteSet = 7
        hero.freezeCounter &+= 1
        guard 1 < hero.freezeCounter else { return }
        hero.freezeCounter = 0
        hero.spriteFrame &+= 1
        guard 0x10 < hero.spriteFrame else { return }
        if hero.visible && !hero.deathBubblesEmitted {
            if let sound = airBubbles.newGroup(x: hero.rect.left, y: hero.rect.top, group: 0xb, frame: frame,
                                               prefs: config.prefs, rng: &rng) {
                playMySnd(sound.slot, priority: sound.priority)
            }
            hero.deathBubblesEmitted = true
        }
        hero.spriteFrame = 0x10
        hero.deathCounter &+= 1
    }

    /// The cosmetic sprite-swap test repeated at every direction (re)choice: `gLevelForEffect <= level` (unsigned
    /// compare) → `GetRandomFast(0,1)`; true only when that draw is 1 **and** `+0x3a == 0` (unregistered). The draw
    /// happens whatever `+0x3a` is.
    private mutating func spriteSwapDraw() -> Bool {
        guard UInt32(truncatingIfNeeded: levelForEffect) <= UInt32(truncatingIfNeeded: level) else { return false }
        return rng.fast(0, 1) == 1 && !hero.registered
    }

    /// `_MoveHeroAligned @ 00022847`, entered only with a direction held: priority Up > Down > Left > Right sets the
    /// facing and sprite set (2/3/4/5, swapped to the opposite on the sprite-swap draw), frame 1; then moves only if
    /// `_GetNextObject(dir, col, row)` is 0 or 'P' — otherwise it just turns (and stays aligned).
    mutating func moveHeroAligned() {
        let dir: Direction
        if heroKeys.up {
            hero.spriteSet = 2
            if spriteSwapDraw() { hero.spriteSet = 3 }
            dir = .up
        } else if heroKeys.down {
            hero.spriteSet = 3
            if spriteSwapDraw() { hero.spriteSet = 2 }
            dir = .down
        } else if heroKeys.left {
            hero.spriteSet = 4
            if spriteSwapDraw() { hero.spriteSet = 5 }
            dir = .left
        } else if heroKeys.right {
            hero.spriteSet = 5
            if spriteSwapDraw() { hero.spriteSet = 4 }
            dir = .right
        } else {
            // "MoveHeroAligned() - No movement key was down!" then facing 0 — unreachable: `_ProcessHero` calls this
            // only with `gHero_MoveKeyDown` set, and `Direction` cannot hold 0.
            return
        }
        hero.facing = dir
        hero.spriteFrame = 1
        let next = getNextObject(dir, col: Int(hero.col), row: Int(hero.row))
        if next != CellCode.empty && next != CellCode.passableP { return }
        stepHero(dir)
    }

    /// `_MoveHeroNotAligned @ 000224c8`: keeps the facing; only the exact opposite key reverses (down ← Up, up ← Down,
    /// right ← Left, left ← Right) with the sprite-swap draw — the horizontal reversals "swap" to the same sprite
    /// (5 → 5, 4 → 4; replicated). Steps 5 px in the (new) facing; walk frame −1 on a reversal call (below 1 → 8), else
    /// +1 (9 → 1).
    mutating func moveHeroNotAligned() {
        var reversed = false
        switch hero.facing {
        case .down where heroKeys.up:
            hero.facing = .up
            hero.spriteSet = 2
            if spriteSwapDraw() { hero.spriteSet = 3 }
            reversed = true
        case .up where heroKeys.down:
            hero.facing = .down
            hero.spriteSet = 3
            if spriteSwapDraw() { hero.spriteSet = 2 }
            reversed = true
        case .right where heroKeys.left:
            hero.facing = .left
            hero.spriteSet = 4
            if spriteSwapDraw() { hero.spriteSet = 4 }
            reversed = true
        case .left where heroKeys.right:
            hero.facing = .right
            hero.spriteSet = 5
            if spriteSwapDraw() { hero.spriteSet = 5 }
            reversed = true
        default: break
        }
        stepHero(hero.facing)
        if reversed {
            hero.spriteFrame &-= 1
            if hero.spriteFrame < 1 { hero.spriteFrame = 8 }
        } else {
            let f = hero.spriteFrame &+ 1
            hero.spriteFrame = f < 9 ? f : 1
        }
    }

    /// The step shared by `_MoveHeroAligned` and `_MoveHeroNotAligned` (identical in both): offset the rect by the speed, accumulate the offset; at exactly ±40 the col/row steps
    /// and that offset resets; then aligned = both offsets 0.
    private mutating func stepHero(_ dir: Direction) {
        let s = hero.speed
        switch dir {
        case .down:
            hero.rect.offset(dx: 0, dy: s)
            hero.yOffset &+= s
            if hero.yOffset == 0x28 { hero.row &+= 1; hero.yOffset = 0 }
        case .up:
            hero.rect.offset(dx: 0, dy: 0 &- s)
            hero.yOffset &-= s
            if hero.yOffset == -0x28 { hero.row &-= 1; hero.yOffset = 0 }
        case .left:
            hero.rect.offset(dx: 0 &- s, dy: 0)
            hero.xOffset &-= s
            if hero.xOffset == -0x28 { hero.col &-= 1; hero.xOffset = 0 }
        case .right:
            hero.rect.offset(dx: s, dy: 0)
            hero.xOffset &+= s
            if hero.xOffset == 0x28 { hero.col &+= 1; hero.xOffset = 0 }
        }
        hero.aligned = hero.xOffset == 0 && hero.yOffset == 0
    }

    /// `_HeroPushCrushCheck @ 000220d8` (hero-and-input.md §4, Research note 26), on the **facing**: N = next object,
    /// D = distant object. Returns 1 push / thud, 2 pop / egg, 0 nothing.
    /// - N ∈ {10, 15, 16, 52}: D ∈ {0, 'P'} → (52 already lit at N → 0) `_PushBlock` → 1; D ∈ 10…60 → `_CrushBlock`
    ///   (+1 point), 52 also `_ActivateBombBlock` → 2; any other D → 0.
    /// - N = 20: no target yet → push if D ∈ {0, 'P'} or D = 20, else thud; target found → N is the target → thud,
    ///   else push if D ∈ {0, 'P'}, or D ∈ {20, 30} and D is the target, else thud. Always 1.
    /// - N = 30 or 50 (wall) → thud, 1. N = 60 → `_KillEggBlock`, 2. N = 51 (dead, never stored) → 2. Else 0.
    mutating func heroPushCrushCheck() -> Int {
        let col = Int(hero.col), row = Int(hero.row), face = hero.facing
        let n = getNextObject(face, col: col, row: row)
        var pushed = false          // the original's bVar2
        var popped = false          // bVar3
        let isBubble = n == CellCode.normal || n == CellCode.blue || n == CellCode.purple || n == CellCode.dynamite
        if isBubble {
            let d = getDistantObject(face, col: col, row: row)
            if d == CellCode.empty || d == CellCode.passableP {
                let next = Self.adjacentCell(col: col, row: row, face)
                if n == CellCode.dynamite && isActiveBombBlock(col: next.col, row: next.row) {
                    return 0
                }
                pushBlock(col: col, row: row, direction: face, type: n)
                pushed = true
            } else if UInt16(truncatingIfNeeded: Int16(Int8(bitPattern: d)) &- 10) > 0x32 {
                // `(ushort)((short)D - 10) > 50`: D outside 10…60 → nothing (falls to the tail with bVar2 = bVar3 = 0).
            } else {
                crushBlock(col: col, row: row, direction: face, score: true)
                if n == CellCode.dynamite {
                    activateBombBlock(col: col, row: row, direction: face)
                    return 2
                }
                popped = true
            }
        } else if n == CellCode.jewel {
            let c = hero.col, r = hero.row
            if !isTargetJewelFound() {
                let d = getDistantObject(face, col: col, row: row)
                if d == CellCode.empty || d == CellCode.passableP {
                    pushBlock(col: col, row: row, direction: face, type: n)
                    pushed = true
                }
                if d == CellCode.jewel {
                    pushBlock(col: col, row: row, direction: face, type: n)
                    pushed = true
                }
                if !pushed {                                     // LAB_0002234b: thud
                    pushed = true
                    playMySnd(7, priority: 10)                   // 00022367 "Push - Failed"
                }
            } else if !isJewelTheTarget(face, col: c, row: r) {
                let d = getDistantObject(face, col: col, row: row)
                if d == CellCode.empty || d == CellCode.passableP {
                    pushBlock(col: col, row: row, direction: face, type: n)
                    pushed = true
                }
                if (d == CellCode.jewel || d == CellCode.cluster) && isJewelTheDistantTarget(face, col: c, row: r) {
                    pushBlock(col: col, row: row, direction: face, type: n)
                    pushed = true
                }
                if !pushed {                                     // LAB_0002234b: thud
                    pushed = true
                    playMySnd(7, priority: 10)                   // 00022367 "Push - Failed"
                }
            } else {
                pushed = true                                    // the target itself: thud
                playMySnd(7, priority: 10)                       // 00022367 "Push - Failed"
            }
        }
        switch n {
        case CellCode.wall, CellCode.cluster:
            playMySnd(7, priority: 10)                           // 00022285 "Push - Failed" (LAB_0002226e)
            return 1
        case 0x33:
            popped = true
        case CellCode.egg:
            killEggBlock(col: col, row: row, direction: face)
            popped = true
        default: break
        }
        if pushed { return 1 }
        return popped ? 2 : 0
    }
}
