// Balloons (plan §Task 7a.1; Research note 40; Invariants 8, 9, 18; INDEX C4, C5, C12 / NR-6), transcribed from
// `_Balloons_New @ 000237f9`, `_Balloons_Process @ 00024394`, `_Balloons_MoveBalloon @ 00023b3d`,
// `_Balloons_CaptureHero @ 00023cbb`, `_Balloons_CheckBalloonEnemyHit @ 00023f90`,
// `_Balloons_CheckHardObjectHit @ 00023da7`, `_Balloons_CheckSquishes @ 00023ae8`,
// `_Balloons_CaptureAllEnemies @ 000240dd`. `_Balloons_PopBalloon` / `_Balloons_PopAll` live in
// `EnemyMutations.swift`. Slots are scanned 0…29 and claimed first-free; nothing here frees a slot or decrements
// `numActiveBalloons` — the draw pass does (Invariant 8). Sounds are cued (`Sounds.swift`); the background-restore
// (`_AddRectToBgnd`, 000243f0) is recorded at its site (C3, `DrawOps.swift`); no RNG.

extension GameState {
    /// `_Balloons_New(e) @ 000237f9` — the shark's bubble attack. Cap 30 (`numActive == 30` → return before any
    /// draw); first free slot; the frame counter is read first. By the enemy's direction (`+0x23`) the 17×17 box:
    /// down (eL+11, eB+20, eL+28, eB+37), up (eL+11, eT−37, eL+28, eT−20), left (eL−37, eT+11, eL−20, eT+28), right
    /// (eR+20, eT+11, eR+37, eT+28) as (left, top, right, bottom); any other direction returns without claiming the
    /// slot. Then state 1, start = frame, dead 0, sprite 0x31, frame 1, direction, counter 0, visible, anim timer =
    /// frame, anim period `GetRandomFast(4,7)`; rect = (eT, eL, eT+40, eL+40) offset 20 px in the direction; prevRect
    /// = rect; `numActive++`. Capture kind `+0x22` and holder `+0x23` are not written (stale, as in the original).
    mutating func balloonsNew(enemy e: Int) {
        guard numActiveBalloons != 0x1e else { return }
        let now = frame
        for i in balloons.indices where balloons[i].state == 0 {
            let er = enemies[e].rect
            guard let dir = enemies[e].direction else { return }
            var box = QDRect(top: 0, left: 0, bottom: 0, right: 0)
            switch dir {
            case .down:
                box.left = er.left &+ 0xb
                box.top = er.bottom &+ 0x14
                box.right = er.left &+ 0x1c
                box.bottom = er.bottom &+ 0x25
            case .up:
                box.left = er.left &+ 0xb
                box.top = er.top &- 0x25
                box.right = er.left &+ 0x1c
                box.bottom = er.top &- 0x14
            case .left:
                box.left = er.left &- 0x25
                box.top = er.top &+ 0xb
                box.right = er.left &- 0x14
                box.bottom = er.top &+ 0x1c
            case .right:
                box.left = er.right &+ 0x14
                box.top = er.top &+ 0xb
                box.right = er.right &+ 0x25
                box.bottom = er.top &+ 0x1c
            }
            balloons[i].box = box
            balloons[i].state = 1
            balloons[i].startFrame = now
            balloons[i].dead = false
            balloons[i].spriteSet = 0x31
            balloons[i].frame = 1
            balloons[i].direction = dir
            balloons[i].counter = 0
            balloons[i].visible = true
            balloons[i].animTimer = now
            balloons[i].animPeriod = Int16(truncatingIfNeeded: rng.fast(4, 7))
            var rect = QDRect(top: er.top, left: er.left, bottom: er.top &+ 0x28, right: er.left &+ 0x28)
            switch dir {
            case .down: rect.offset(dx: 0, dy: 0x14)
            case .up: rect.offset(dx: 0, dy: -0x14)
            case .left: rect.offset(dx: -0x14, dy: 0)
            case .right: rect.offset(dx: 0x14, dy: 0)
            }
            balloons[i].rect = rect
            balloons[i].prevRect = rect
            numActiveBalloons += 1
            playMySnd(0xe, priority: 10)                            // 00023a63 "Balloon Launch"
            return
        }
    }

    /// `_Balloons_Process @ 00024394`, once per frame; returns at once when `numActive == 0`. Slots 0…29 with a
    /// non-zero state (the dead flag is not tested — a dead slot is freed by the draw pass before the next frame):
    /// - **2 (holding):** anim step when `timer + period < frame` (frame + 1, back to 1 past 3; timer = frame); hero
    ///   not trapped and its rect overlapping the box → `_Balloons_PopBalloon` + `_PopEnemy(holder)` (holder −1 = the
    ///   hero's own balloon → no-op, C12 / NR-6); then, still state 2: `start + w15 < frame` → visible toggles;
    ///   `start + w16 < frame` → visible, `_Balloons_PopBalloon`, `_ReleaseEnemyFromBalloon(holder)` (−1 → no-op).
    /// - **3 (popping):** counter + 1 > 3 (unsigned) → dead, invisible.
    /// - **1 (flying):** move; the first enemy hit → captured (state 2, start = timer = frame, sprite 0x32, frame 1);
    ///   else hero not trapped, not invisible, overlapping the box → `_Balloons_CaptureHero`; then, still state 1:
    ///   hard object → pop, else the C4 growth (frame < 2: counter + 1 > 2 → counter 0, frame + 1, frame 2 → box =
    ///   (top+8, left+8, top+31, left+26) of the rect — reachable once; the frame-3/4 arms are transcribed but cannot
    ///   be reached from here).
    /// - **any other state:** the original returns from the whole function (remaining slots skipped) — replicated.
    mutating func balloonsProcess() {
        guard numActiveBalloons != 0 else { return }
        let now = frame
        for i in balloons.indices where balloons[i].state != 0 {
            addRectToBgnd(balloons[i].prevRect)                 // 000243f0, before the state switch
            switch balloons[i].state {
            case 2:
                if Int(balloons[i].animTimer) + Int(balloons[i].animPeriod) < Int(now) {
                    let next = balloons[i].frame &+ 1
                    balloons[i].frame = next < 4 ? next : 1
                    balloons[i].animTimer = now
                }
                if !hero.trapped && balloons[i].box.collides(hero.rect) {
                    balloonsPopBalloon(i)
                    popEnemy(Int(balloons[i].holder))
                }
                if balloons[i].state == 2 {
                    if Int(balloons[i].startFrame) + levelRecord.balloonFlash < Int(now) {
                        balloons[i].visible = !balloons[i].visible
                    }
                    if Int(balloons[i].startFrame) + levelRecord.balloonRelease < Int(now) {
                        balloons[i].visible = true
                        balloonsPopBalloon(i)
                        releaseEnemyFromBalloon(Int(balloons[i].holder))
                    }
                }
            case 3:
                balloons[i].counter &+= 1
                if 3 < UInt16(bitPattern: balloons[i].counter) {
                    balloons[i].dead = true
                    balloons[i].visible = false
                }
            case 1:
                balloonsMoveBalloon(i)
                if balloonsCheckBalloonEnemyHit(i) {
                    balloons[i].state = 2
                    balloons[i].startFrame = now
                    balloons[i].spriteSet = 0x32
                    balloons[i].frame = 1
                    balloons[i].animTimer = now
                    continue
                }
                if !hero.trapped && !hero.invisible && balloons[i].box.collides(hero.rect) {
                    balloonsCaptureHero(i)
                }
                guard balloons[i].state == 1 else { continue }
                if balloonsCheckHardObjectHit(i) {
                    balloonsPopBalloon(i)
                    continue
                }
                guard balloons[i].frame < 2 else { continue }
                balloons[i].counter &+= 1
                guard 2 < UInt16(bitPattern: balloons[i].counter) else { continue }
                balloons[i].counter = 0
                let old = balloons[i].frame
                let grown = old &+ 1
                balloons[i].frame = grown
                let r = balloons[i].rect
                switch grown {
                case 2:
                    balloons[i].box = QDRect(top: r.top &+ 8, left: r.left &+ 8, bottom: r.top &+ 0x1f,
                                             right: r.left &+ 0x1a)
                case 3:
                    balloons[i].box = QDRect(top: r.top &+ 3, left: r.left &+ 3, bottom: r.top &+ 0x20,
                                             right: r.left &+ 0x1a)
                case 4:
                    balloons[i].box = r
                default:
                    // `else if (sVar4 < 3) { if (sVar6 != 0) return; }`; `else if (sVar4 != 4) return;`
                    if grown < 3 {
                        if old != 0 { return }
                    } else {
                        return
                    }
                }
            default:
                return
            }
        }
    }

    /// `_Balloons_MoveBalloon @ 00023b3d`: 8 px in the direction for rect and box (up/down move top/bottom, left/right
    /// move left/right); no direction → return before the clamps. Then the rect (not the box) is clamped: left < 0 →
    /// (0, 40); else right > 640 → (600, 640); top < 0 → (0, 40); else bottom > 440 → (400, 440).
    private mutating func balloonsMoveBalloon(_ i: Int) {
        switch balloons[i].direction {
        case .down:
            balloons[i].rect.top &+= 8; balloons[i].rect.bottom &+= 8
            balloons[i].box.top &+= 8; balloons[i].box.bottom &+= 8
        case .up:
            balloons[i].rect.top &-= 8; balloons[i].rect.bottom &-= 8
            balloons[i].box.top &-= 8; balloons[i].box.bottom &-= 8
        case .left:
            balloons[i].rect.left &-= 8; balloons[i].rect.right &-= 8
            balloons[i].box.left &-= 8; balloons[i].box.right &-= 8
        case .right:
            balloons[i].rect.left &+= 8; balloons[i].rect.right &+= 8
            balloons[i].box.left &+= 8; balloons[i].box.right &+= 8
        case nil:
            return
        }
        if balloons[i].rect.left < 0 {
            balloons[i].rect.left = 0
            balloons[i].rect.right = 0x28
        } else if 0x280 < balloons[i].rect.right {
            balloons[i].rect.right = 0x280
            balloons[i].rect.left = 600
        }
        if balloons[i].rect.top < 0 {
            balloons[i].rect.top = 0
            balloons[i].rect.bottom = 0x28
        } else if 0x1b8 < balloons[i].rect.bottom {
            balloons[i].rect.bottom = 0x1b8
            balloons[i].rect.top = 400
        }
    }

    /// `_Balloons_CaptureHero(i) @ 00023cbb`: only when the hero is not trapped — state 2, start = anim timer =
    /// frame, sprite 0x32, frame 1, kind 0x46, holder −1 (0xff; C12), rect = (hT, hL, hT+40, hL+40), box = rect; the
    /// hero is trapped from this frame (`+0x4c` = 1, `+0x4e` = frame).
    mutating func balloonsCaptureHero(_ index: Int) {
        guard !hero.trapped else { return }
        let now = frame
        playMySnd(0xf, priority: 10)                                // 00023cf6 "Enemy Ballooned"
        playMySnd(0x27, priority: 10, delay: 5)                     // 00023d12 "Heyahoo" (+5)
        balloons[index].state = 2
        balloons[index].startFrame = now
        balloons[index].spriteSet = 0x32
        balloons[index].frame = 1
        balloons[index].captureKind = 0x46
        balloons[index].holder = -1
        balloons[index].animTimer = now
        let hr = hero.rect
        let rect = QDRect(top: hr.top, left: hr.left, bottom: hr.top &+ 0x28, right: hr.left &+ 0x28)
        balloons[index].rect = rect
        balloons[index].box = rect
        hero.trapped = true
        hero.trapStart = now
    }

    /// `_Balloons_CheckBalloonEnemyHit(i) @ 00023f90`: the first enemy (0…29) in state 1, 4 or 5 whose rect overlaps
    /// the box — the dead flag `+0x47` is not tested (replicated). It is captured: kind 0x50, holder = slot,
    /// `_CaptureEnemy(slot, i)`, rect = (eT, eL, eT+40, eL+40), box = rect → true. None → false. (The original also
    /// computes the rect inset by 6 into a local that nothing reads — no effect.)
    mutating func balloonsCheckBalloonEnemyHit(_ index: Int) -> Bool {
        for e in enemies.indices {
            let s = enemies[e].state
            guard s == 1 || s == 4 || s == 5 else { continue }
            guard balloons[index].box.collides(enemies[e].rect) else { continue }
            balloons[index].captureKind = 0x50
            balloons[index].holder = Int8(truncatingIfNeeded: e)
            captureEnemy(e, balloon: Int(Int8(truncatingIfNeeded: index)))
            playMySnd(0xf, priority: 10)                            // 00024068 "Enemy Ballooned"
            let er = enemies[e].rect
            let rect = QDRect(top: er.top, left: er.left, bottom: er.top &+ 0x28, right: er.left &+ 0x28)
            balloons[index].rect = rect
            balloons[index].box = rect
            return true
        }
        return false
    }

    /// `_Balloons_CheckHardObjectHit(i) @ 00023da7`: true when the box leaves (1,1)…(639,439) (`left < 1 || 639 <
    /// right || top < 1 || 439 < bottom`), else when the cell in front holds 10…60 (`(byte)(cell − 10) < 0x33`):
    /// down → (right/40, bottom/40), up → (right/40, top/40), left → (left/40, top/40), right → (right/40, top/40);
    /// no direction → false.
    mutating func balloonsCheckHardObjectHit(_ index: Int) -> Bool {
        let box = balloons[index].box
        if box.left < 1 || 0x27f < box.right || box.top < 1 || 0x1b7 < box.bottom { return true }
        let col: Int16, row: Int16
        switch balloons[index].direction {
        case .down: col = box.right / 0x28; row = box.bottom / 0x28
        case .up: col = box.right / 0x28; row = box.top / 0x28
        case .left: col = box.left / 0x28; row = box.top / 0x28
        case .right: col = box.right / 0x28; row = box.top / 0x28
        case nil: return false
        }
        let c = Int(Int8(truncatingIfNeeded: col)), r = Int(Int8(truncatingIfNeeded: row))
        return maze.cells[c + r * Maze.columns] &- 10 < 0x33
    }

    /// `_Balloons_CheckSquishes(rect) @ 00023ae8` (a moving block): every flying (state 1) balloon whose rect (not
    /// the box) overlaps `rect` → `_Balloons_PopBalloon`. Holding balloons are untouched (C5).
    mutating func balloonsCheckSquishes(_ rect: QDRect) {
        guard numActiveBalloons != 0 else { return }
        for i in balloons.indices where balloons[i].state == 1 {
            if rect.collides(balloons[i].rect) {
                balloonsPopBalloon(i)
            }
        }
    }

    /// `_Balloons_CaptureAllEnemies @ 000240dd` (capture bonus, EXTRA): the frame counter is read once; per enemy
    /// 0…29 in state 1, 4 or 5: `29 < numActive` → return (whole function); the first free slot → `numActive++`,
    /// state 2, start = anim timer = frame, dead 0, sprite 0x32, frame 1, direction = the hero's facing, counter 0,
    /// visible, kind = the enemy's `+0x04`, holder = enemy slot, anim period `GetRandomFast(4,7)`,
    /// `_CaptureEnemy(e, slot)`, rect = (eT, eL, eT+40, eL+40), box = rect. Eggs (states 2/3) are skipped.
    mutating func balloonsCaptureAllEnemies() {
        let now = frame
        for e in enemies.indices {
            let s = enemies[e].state
            guard s == 1 || s == 4 || s == 5 else { continue }
            if 0x1d < numActiveBalloons { return }
            guard let i = balloons.firstIndex(where: { $0.state == 0 }) else { continue }
            numActiveBalloons += 1
            balloons[i].state = 2
            balloons[i].startFrame = now
            balloons[i].dead = false
            balloons[i].spriteSet = 0x32
            balloons[i].frame = 1
            balloons[i].direction = hero.facing
            balloons[i].counter = 0
            balloons[i].visible = true
            balloons[i].captureKind = enemies[e].unknown04
            balloons[i].holder = Int8(truncatingIfNeeded: e)
            balloons[i].animTimer = now
            balloons[i].animPeriod = Int16(truncatingIfNeeded: rng.fast(4, 7))
            captureEnemy(e, balloon: i)
            let er = enemies[e].rect
            let rect = QDRect(top: er.top, left: er.left, bottom: er.top &+ 0x28, right: er.left &+ 0x28)
            balloons[i].rect = rect
            balloons[i].box = rect
        }
        playMySnd(0xf, priority: 10)                                // 00024253 (not on the early return)
    }
}
