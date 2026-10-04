// Bonus bubbles (plan §Task 7b.1; Research notes 41, 47; Invariants 8, 9, 18), transcribed from
// `_Bonus_Process @ 0001a92b`, `_Multiplier_Process @ 00019dae`, `_Bonus_DoesHeroTouch @ 00019a13`,
// `_Bonus_WasHit @ 0001a79a`, `_Bonus_Pop @ 0001a6fd`, `_Bonus_Reward @ 0001a2c5` (jump table 0x337f4). `_Bonus_Init`
// lives in `LevelBuild.swift`. Sounds are cued at their call sites (`Sounds.swift`); `_EXTRA_Draw` /
// `_Multiplier_Draw` and the background restore (`_AddRectToBgnd`) consume no RNG and are not modelled. Nothing here frees a slot — `dead` is
// set and the draw pass frees it (Invariant 8); a dead slot that is still armed keeps being processed, as in the
// original. The Toolbox `InsetRect` by 8 on a 40×40 rect never empties it, so `QDRect.inset` is exact here.

extension GameState {
    /// `_gBonus_SnakingLUT` (0x341c0, 19 shorts): the per-frame x step of a flying bonus bubble.
    static let bonusSnakingLUT: [Int16] = [1, 1, 1, 1, 0, -1, -1, -1, -1, -1, -1, -1, -1, 0, 1, 1, 1, 1, 0]

    /// `_Bonus_Process @ 0001a92b`, once per frame.
    ///
    /// 1. EXTRA blink (only while `gEXTRA_Animate` and `extraTimer + 5 < frame`): counter + 1, > 9 → 9 and the
    ///    animation stops; timer = frame; bit `1 << counter` in 0x155 → all five letter flags = 1, in 0xaa or 0x200 →
    ///    all = 0 (the flags double as the display state).
    /// 2. `_Multiplier_Process` (flash only).
    /// 3. Per armed slot 0, 1 (the frame counter read per slot): `frame == launch` → harp (sound); `frame <= launch` →
    ///    skip. Flying (not popped): rise `riseSpeed`, x += `LUT[snakeIndex]` (index + 1, > 18 → 0), then the drift
    ///    entry `bonusDrift[bonusDriftIndex]` (index + 1, ≥ 21 → 0): 0 none, 1 −1, 2 −2, 3 +1, 4 +2, any other value
    ///    returns from the whole function; top < 0 → dead; x clamp (left < 5 → (5, 45), else right > 635 →
    ///    (595, 635)); `animTimer + 2 < frame` → timer = frame, shell frame + 1 (≥ 4 → 1); hero touch → `_Bonus_Pop`.
    ///    Popped: `poppedFrame + 0x1e < frame` → dead, invisible; else rise, top < 0 → dead, x clamp.
    mutating func bonusProcess() {
        if extraAnimating && Int(extraTimer) + 5 < Int(frame) {
            let now = frame
            extraAnimCounter &+= 1
            if 9 < extraAnimCounter {
                extraAnimCounter = 9
                extraAnimating = false
            }
            extraTimer = now
            if extraAnimCounter <= 9 {
                let bit = 1 << (Int(extraAnimCounter) & 0x1f)
                if bit & 0x155 != 0 {
                    for k in extraLetters.indices { extraLetters[k] = true }
                    extraDraw(true)                         // 0001aa34
                } else if bit & 0xaa != 0 {
                    for k in extraLetters.indices { extraLetters[k] = false }
                    extraDraw(false)
                } else if bit & 0x200 != 0 {
                    for k in extraLetters.indices { extraLetters[k] = false }
                    extraDraw(true)
                }
            }
        }
        multiplierProcess()
        for i in bonus.indices {
            let now = frame
            guard bonus[i].armed else { continue }
            if now == bonus[i].launchFrame {
                playMySnd(0x13, priority: 10, delay: 5)     // 0001aa77 "Harp"
            }
            if now <= bonus[i].launchFrame { continue }
            if !bonus[i].popped {
                bonusRise(i)
                let index = Int(bonus[i].snakeIndex)
                let dx = Self.bonusSnakingLUT[index]
                var next = bonus[i].snakeIndex &+ 1
                if 0x12 < next { next = 0 }
                bonus[i].snakeIndex = next
                bonus[i].rect.offset(dx: dx, dy: 0)
                let driftIndex = bonusDriftIndex
                let nextDrift = bonusDriftIndex + 1
                bonusDriftIndex = nextDrift < 0x15 ? nextDrift : 0
                switch bonusDrift[driftIndex] {
                case 0: break
                case 1: bonus[i].rect.offset(dx: -1, dy: 0)
                case 2: bonus[i].rect.offset(dx: -2, dy: 0)
                case 3: bonus[i].rect.offset(dx: 1, dy: 0)
                case 4: bonus[i].rect.offset(dx: 2, dy: 0)
                default: return             // switchD_0001ab94_default: the whole function returns
                }
                bonusExitAndClamp(i)
                if Int(bonus[i].animTimer) + 2 < Int(now) {
                    bonus[i].animTimer = now
                    let shell = bonus[i].shellFrame &+ 1
                    bonus[i].shellFrame = shell < 4 ? shell : 1
                }
                if bonusDoesHeroTouch(i) {
                    bonusPop(i)
                }
            } else if Int(bonus[i].poppedFrame) + 0x1e < Int(now) {
                bonus[i].dead = true
                bonus[i].visible = false
            } else {
                bonusRise(i)
                bonusExitAndClamp(i)
            }
            addRectToBgnd(bonus[i].prevRect)                // 0001ac9a, every launched armed slot
        }
    }

    /// The shared rise: top and bottom −= `riseSpeed` (`+0x18`).
    private mutating func bonusRise(_ i: Int) {
        bonus[i].rect.top &-= bonus[i].riseSpeed
        bonus[i].rect.bottom &-= bonus[i].riseSpeed
    }

    /// The shared exit test and x clamp: top < 0 → dead + "Pop" (0001aad9 / 0001ac1c); left < 5 → left 5, right 0x2d; else right > 0x27b →
    /// right 0x27b, left 0x253.
    private mutating func bonusExitAndClamp(_ i: Int) {
        if bonus[i].rect.top < 0 {
            bonus[i].dead = true
            playMySnd(6, priority: 10)
        }
        if bonus[i].rect.left < 5 {
            bonus[i].rect.left = 5
            bonus[i].rect.right = 0x2d
        } else if 0x27b < bonus[i].rect.right {
            bonus[i].rect.right = 0x27b
            bonus[i].rect.left = 0x253
        }
    }

    /// `_Multiplier_Process @ 00019dae` — the multiplier's flash animation: while animating and `timer + 5 < frame`:
    /// counter + 1, > 9 → 9 and the animation stops; timer = frame; counter < 9: draw on bits 0x155 (with sound 32,
    /// 00019e5d) / off on 0xaa. The multiplier itself never changes here.
    mutating func multiplierProcess() {
        guard multiplierAnimating else { return }
        let now = frame
        guard Int(multiplierTimer) + 5 < Int(now) else { return }
        multiplierAnimCounter &+= 1
        if 9 < multiplierAnimCounter {
            multiplierAnimCounter = 9
            multiplierAnimating = false
        }
        multiplierTimer = now
        guard multiplierAnimCounter < 9 else { return }
        let bit = 1 << (Int(multiplierAnimCounter) & 0x1f)
        if bit & 0x155 != 0 {
            multiplierDraw(true)                            // 00019e41
            playMySnd(0x20, priority: 0x1e)                 // 00019e5d "Bonus Multiplier Flash"
        } else if bit & 0xaa != 0 {
            multiplierDraw(false)                           // 00019e33
        }
    }

    /// `_Bonus_DoesHeroTouch(slot) @ 00019a13`: armed, hero state 2 and not popped; the bonus rect inset by 8 on both
    /// axes collides (strictly) with the hero rect. The dead flag is not tested.
    func bonusDoesHeroTouch(_ slot: Int) -> Bool {
        guard bonus[slot].armed, hero.state == 2, !bonus[slot].popped else { return false }
        var r = bonus[slot].rect
        r.inset(dx: 8, dy: 8)
        return r.collides(hero.rect)
    }

    /// `_Bonus_WasHit(rect) @ 0001a79a` (a moving block's rect): every slot 0, 1 that is armed and not popped whose
    /// rect inset by 8 collides with `rect` is popped (`_Bonus_Pop`) — both slots can pop in one call. Neither the
    /// launch frame nor the dead flag is tested. Returns whether any popped.
    mutating func bonusWasHit(_ rect: QDRect) -> Bool {
        var hit = false
        for i in bonus.indices where bonus[i].armed && !bonus[i].popped {
            var r = bonus[i].rect
            r.inset(dx: 8, dy: 8)
            if rect.collides(r) {
                bonusPop(i)
                hit = true
            }
        }
        return hit
    }

    /// `_Bonus_Pop(slot) @ 0001a6fd` (regparm: the slot in EAX): two sounds; popped; poppedFrame = frame;
    /// `_NewStarGroup(left, top, 2)`; `_Bonus_Reward(slot)`.
    mutating func bonusPop(_ slot: Int) {
        playMySnd(6, priority: 10)                          // 0001a71e "Pop"
        playMySnd(0x1a, priority: 0x14)                     // 0001a73a "Get Bonus"
        bonus[slot].popped = true
        bonus[slot].poppedFrame = frame
        addRectToBgnd(bonus[slot].rect)                     // 0001a764
        stars.newGroup(x: bonus[slot].rect.left, y: bonus[slot].rect.top, group: 2, hero: heroAnchor, frame: frame,
                       prefs: config.prefs, rng: &rng)
        bonusReward(slot)
    }

    /// `_Bonus_Reward(slot) @ 0001a2c5`, by type (jump table 0x337f4): 1 `_Balloons_CaptureAllEnemies`;
    /// 2 `_RegenerateBlocks`; 4 `_SetHeroInvisibility(1)`; 5/6/7/8 `_Multiplier_Change(2/3/4/5)` (unreachable —
    /// `_Bonus_Init` remaps 5…8); 9…13 `_EXTRA_Change(1…5, slot)`; 14 by the time value: 500/800/1000/2000/3000/4000/
    /// 5000/10000 → `_TimeBonus_Increase(v, 1)` and `_NewPoint(left, top, 5/8/10/0xc/0xd/0xe/0xf/0x14, 3)`, any other
    /// value → nothing; 0, 3 and anything else → nothing.
    mutating func bonusReward(_ slot: Int) {
        let type = bonus[slot].type
        switch type {
        case 1:
            playMySnd(0xf, priority: 10)
            balloonsCaptureAllEnemies()
        case 2:
            playMySnd(0x1f, priority: 0x14)
            playMySnd(4, priority: 0x14)
            playMySnd(0xf, priority: 10)
            regenerateBlocks()
        case 4:
            playMySnd(0x1f, priority: 0x14)
            playMySnd(4, priority: 0x14)
            setHeroInvisibility(true)
        case 5, 6, 7, 8:
            playMySnd(0x2c, priority: 0x14)
            multiplierChange(type - 3)
        case 9, 10, 11, 12, 13:
            playMySnd(0x1f, priority: 0x14)
            extraChange(letter: Int(type) - 8, bonusSlot: slot)
        case 0xe:
            playMySnd(0x1a, priority: 0x14)
            let sprite: Int16
            switch bonus[slot].timeValue {
            case 500: sprite = 5
            case 800: sprite = 8
            case 1000: sprite = 10
            case 2000: sprite = 0xc
            case 3000: sprite = 0xd
            case 4000: sprite = 0xe
            case 5000: sprite = 0xf
            case 10000: sprite = 0x14
            default: return
            }
            if sprite == 0xf || sprite == 0x14 {
                playMySnd(0x28, priority: 0x14, delay: 5)   // 5000 / 10000: "Hooley Dooleys" (+5)
            }
            timeBonusIncrease(Int32(bonus[slot].timeValue))
            points.newPoint(x: bonus[slot].rect.left, y: bonus[slot].rect.top, sprite: sprite, delay: 3, level: level,
                            notRegistered: config.pointsNotRegistered)
        default:
            break
        }
    }
}
