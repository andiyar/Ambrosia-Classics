import Foundation
import HectorResources

/// `.HitPlayerSprite(player, other) @ 100556f4` (decompile l. 48450–49929), reached only through the player pass
/// `.MTCollideSpecialSprite(player, .HitPlayerSprite)` (platforms-ropes-radial-2 §8.3). The arms built so far: the
/// entry gates, the **Platform** arm (W1), the **Background** arm's pendulum (W2a) and passage (W2b) parts, and the
/// **Box / see-saw segment** arm up to its mechanism branches (W3, `box`) plus the save point (S1, `savePoint`, which
/// suspends the frame), and the **Bonus** arm (PK, `bonus`: every pickup; the upgrades suspend the frame). // later:
/// the other Box mechanisms (Phase 4), the enemy and shot arms (Phase 4–5).
public enum HitPlayerSprite {
    /// The test form: the light calls (`.KillBonus`'s `.RemoveLight`) go to a scratch table, Effects is the default
    /// prefs'.
    public static func hit(_ w: SpriteWorld, player pID: Int, other oID: Int, keys: InputActions = []) {
        var scratch = LightTable()
        hit(w, player: pID, other: oID, keys: keys, lights: &scratch, effects: FerazelPrefs().effects)
    }

    /// The entry gates (l. 48565–48570): dying (`_DAT_100a069c > 0`) → nothing; in spirit form (`_DAT_100a0578 > 0`)
    /// only a Bonus (`+0x4c == PTR_PTR_100a047c`) reaches its arm. A Bonus with `+0xa6 == 0` and `+0xb0 == 0` takes the
    /// Bonus arm (PK, M l. 48571–49123, `bonus`); any other Bonus matches no later arm. Then the Platform arm (l.
    /// 49124–49147; `+0x4c == .HandlePlatformSprite`, so an idled record — `+0x4c = 0` — is no Platform):
    /// - the player's hot-rect centre offset (x = left + (right − left) >> 1, y = top + (bottom − top) >> 1);
    ///   the bumped / landed latches `_DAT_100a0720` / `_DAT_100a0724` cleared;
    /// - a catapult 0x582 / 0x583 whose record p1 == 2 is walk-through: return;
    /// - `.PlatformBounce(player, platform, centre, 0, player rect, 0)` — the player is the mover (a landing sets his
    ///   `+0xdc` and the platform's `+0xe0`, `+0x186`, sag);
    /// - the spiked underside 0x57d: when the player's centre y is at or below the platform's (`+0xe`), or he rises
    ///   faster than 0x200, not invulnerable and not riding it → `.STPlayRegSound(450, 1, 0xab)` (`_DAT_100a02dc`), HP
    ///   −0x70, invulnerable 0x3c, flash 0xc, return;
    /// - `.CheckGroundCeilingHitEffects(player)`.
    /// - Parameter keys: the frame's `.IsInputKeyPressed` answers (the passage arm's UP; one snapshot per step — plan
    ///   hazard "live key reads"; the pickups' `.UpdateStatusBar` key step).
    /// - Parameter lights: the session's light table (`.KillBonus`'s `.RemoveLight`).
    /// - Parameter effects: prefs `+6` (`_DAT_1009fe44 + 6`, the Xichron burst).
    public static func hit(_ w: SpriteWorld, player pID: Int, other oID: Int, keys: InputActions = [],
                           lights: inout LightTable, effects: Int16) {
        guard w.player.dying <= 0 else { return }
        guard let o = w.active.record(id: oID) else { return }
        let isBonus = o.handler == .bonus && !o.handleCleared
        if 0 < w.player.spiritTimer && !isBonus { return }
        if isBonus && o.counterA6 == 0 && o.pickupDelay == 0 {
            bonus(w, player: pID, other: oID, keys: keys, lights: &lights, effects: effects)
            return
        }
        guard !o.handleCleared else { return }                          // `+0x4c == 0`: no arm
        switch o.handler {
        case .platform: break
        case .background:
            background(w, player: pID, other: oID, keys: keys)
            return
        case .box, .seeSawSegment:
            box(w, player: pID, other: oID, keys: keys)                 // `PTR_PTR_100a0484` / `_DAT_100a01c8` (W3)
            return
        default: return                                                 // later: the other arms
        }
        guard let p = w.active.record(id: pID) else { return }
        let r = p.hotRect
        let h = { (v: Int) in Int(Int16(truncatingIfNeeded: v)) }
        let centre = SpriteSlot.Point(x: h(r.left + h((r.right - r.left) >> 1)), y: h(r.top + h((r.bottom - r.top) >> 1)))
        w.player.bumpedLatch = false                                    // `*_DAT_100a0720 = 0`
        w.player.landedLatch = false                                    // `*_DAT_100a0724 = 0`
        if o.type == 0x582 || o.type == 0x583, PlatformSprite.record(w, o)?.p1 == 2 { return }
        w.platformBounce(mover: pID, solid: oID, centre: centre, factor: 0, rect: r, bounce: false)
        guard let p1 = w.active.record(id: pID), let o1 = w.active.record(id: oID) else { return }
        if o1.type == PlatformSprite.spiked,
           Int16(truncatingIfNeeded: o1.centre.y) <= Int16(truncatingIfNeeded: p1.centre.y) || p1.vy < -0x200,
           p1.invulnerable < 1, p1.ridden != oID {
            w.player.cue(PlayerCue(call: .reg, snd: 450, priority: 1, volume: 0xab))
            w.active.update(id: pID) { s in
                s.hp &-= 0x70
                s.invulnerable = 0x3c
                s.flash = 0xc
            }
            return
        }
        GroundCeilingEffects.check(w, id: pID)
    }
}

extension HitPlayerSprite {
    /// The Background arm (`+0x4c == PTR_PTR_100a0480`, decompile l. 49573–49592) as far as W2a builds it:
    /// - d = (player `+0x10` − other `+0xc`, player `+0xe` − other `+0xa`) — the player's centre against the other's
    ///   origin, as written (the point `.PlatformBounce` gets);
    /// - // later: fire 0x4b8 / 0x4bb…0x4bd → `.HurtPlayer(…, 0xe0, 1, 0x3c, 0)` unless `HasItem(0x18)` and
    ///   `+0x14c < 1` (Phase 4: the inventory) — none placed on levels 1–2;
    /// - **the pendulum arm** (0x5c8…0x5d1, l. 49583–49592): player `+0x116 == 0` and other `+0x170 == 1` →
    ///   `.HurtPlayer(player, other, 0xe0, blood 1, invul 0x3c, coins 5)` and then `+0x116 = 0x1e` — **whether or not
    ///   the hurt landed**; then, if the other's one-way `+0x185` is 0, `.PlatformBounce(player, other, d, 0, player
    ///   `+0x34`, 0)` (modes 10–14 set it, so only a mode-0 / 3–9 / 15+ bar is solid); return.
    /// - **the passage arm** (0xb54 / 0xb55, l. 49594–49683; W2b): `passage`.
    /// - **the level exit** 0xcb1 (l. 49733–49741; W4): `.STPlayRegSound(*_DAT_100a03dc = snd 421, 1, 0x100)` (no
    ///   draw), the exit index `uRam100a5116` = the record's p1 (`+8`), `_DAT_100a5118` = p2 when ≠ 0, level complete
    ///   `*_DAT_100a0088 = 1` — `.GameLoop` leaves its loop after this iteration (`FerazelSession`, `LevelFlow`).
    /// - // later: 0xbf4 and the other Background arms (Phase 4; none placed on levels 1–2). Cannons, springs and
    ///   tunnels have no arm here: their hit callback `.HitBackgroundSprite` runs in both passes.
    /// The level exit (PICT-less Background type 3249).
    public static let levelExit: Int16 = 0xcb1

    static func background(_ w: SpriteWorld, player pID: Int, other oID: Int, keys: InputActions = []) {
        guard let p = w.active.record(id: pID), let o = w.active.record(id: oID) else { return }
        let h = { (v: Int) in Int(Int16(truncatingIfNeeded: v)) }
        let d = SpriteSlot.Point(x: h(p.centre.x - o.x), y: h(p.centre.y - o.y))
        if BackgroundSprite.passages.contains(o.type) {
            passage(w, player: pID, passage: oID, keys: keys)
            return
        }
        if o.type == levelExit {
            w.player.cue(PlayerCue(call: .reg, snd: 421, priority: 1, volume: 0x100))
            let r = BackgroundSprite.record(w, o)
            w.player.exitIndex = r?.p1 ?? 0
            if let p2 = r?.p2, p2 != 0 { w.player.exit2 = p2 }
            w.player.levelDone = true
            return
        }
        guard BackgroundSprite.maces.contains(o.type) else { return }    // later: 0xbf4 … (Phase 4)
        if p.invulnerable == 0 && o.classWord170 == 1 {
            HurtPlayer.hurt(w, player: pID, attacker: oID, damage: 0xe0, blood: true, invulnerable: 0x3c, coins: 5)
            w.active.update(id: pID) { $0.invulnerable = 0x1e }
        }
        guard let o1 = w.active.record(id: oID), !o1.oneWay, let p1 = w.active.record(id: pID) else { return }
        w.platformBounce(mover: pID, solid: oID, centre: d, factor: 0, rect: p1.hotRect, bounce: false)
    }
}

extension HitPlayerSprite {
    /// The Box / see-saw segment arm (`+0x4c == PTR_PTR_100a0484` or `_DAT_100a01c8`, decompile l. 49149–49362; raw
    /// `10057278..10057324` for the trampoline), up to the mechanism branches (pickups-boxes §2.1, §2.3, §2.4.11):
    /// 1. the entry vy `uVar38 = +0x2c` (l. 49150) — the trampoline's threshold reads it, not the post-landing 0;
    ///    `iStack_ac = (int)(−0.9·vy)` (l. 49153) is read only by the spin-stomp mechanism (// later: Phase 4);
    /// 2. a see-saw segment (l. 49155–49166): the player's x + (rect left + right) >> 1 outside the segment's
    ///    [x + left, x + right] → return; else the segment's `+0xb2 = 1`, `_DAT_100a067c = 1`;
    /// 3. d = (player `+0x10` − `+0xc`, `+0xe` − `+0xa`) (l. 49167–49168) — his own centre offset;
    /// 4. // later: Phase 4 — the special arms of l. 49170–49303: falling rocks 0x433/0x434 (`+0x160`, `.HurtPlayer` +
    ///    `.KillBox`), spiked balls 0x5c3/0x5c4 (`FastRand(100)` + `.HurtPlayer`), NPC `.Conversation`, doors
    ///    0xb5e/0xb5f and the chest 0x51c (keys, items), the timer 0xb5b, the sign / grave texts. None of their types is
    ///    placed on levels 1–2 except the NPCs, doors, chests and signs, whose arms need the item and conversation
    ///    systems. The NPC arm 0xb87…0xb99 (l. 49199–49210) returns on every path before `.PlatformBounce` — NPCs are
    ///    never solid; that early return is built. Everything else falls through to `.PlatformBounce`, so its solidity
    ///    is built: the doors and the chest after their key / item code, the timer 0xb5b, the graves 0xb11…0xb14 and
    ///    the signs after the text code (l. 49287–49303), and the falling rocks 0x433 / 0x434 (0x433 also with
    ///    `+0x160` < 0) except on the hurting drop (`+0x160` ≥ 0, the rock's `+0xe` above the player's, vy > 599:
    ///    `.HurtPlayer` + `.KillBox`, return) and 0x434 with `+0x160` < 0 (return, l. 49170); the spiked balls
    ///    0x5c3 / 0x5c4 return. C1 builds the NPC arm and the sign / grave arm (`talk`) — both suspend the frame
    ///    (`FrameSuspension.conversation` / `.sign`); the sign arm's rest (5–6) runs at the resume (`talkDone`);
    /// 5. signs 0xb56…0xb5d with `+0x15c == 0` → return (l. 49304–49307): only 2902 / 2907 (`+0x15c = 1`) are standable;
    /// 6. `.PlatformBounce(player, box, d, 0, player +0x34, 0)` (l. 49308); not a landing (≠ 1) → return. A Box with
    ///    a surface function (`+0x1e8`: only the unplaced rope bridge 1466) // later: Phase 4;
    /// 7. // later: Phase 4 — the geyser head 0x5a9 hurt (l. 49310–49335; made only by `.HandleGeyserColumn`);
    /// 8. the trampoline 0x5be (l. 49339–49361): `+0x46 = 1`; entry vy ≤ 0xa5a (`cmpwi r25,0xa5a; ble`) → return;
    ///    vy = max(−6500, −(0.6·g + vy)) — 0.6 is the **double** at `0x100a1a10` (`lfd f4,-0x5e30(r2)`), −6500 the
    ///    double at `0x100a1a08`, `fnmsub`, `fctiwz` truncates toward zero; `.STPlayRegSound(604, 1, 0x100)`
    ///    (`_DAT_100a027c`, no draw); the air counter `_DAT_100a0718 = 1`; `+0xce = 0`;
    /// 9. // later: Phase 4 — the mechanism branches from l. 49363: the spin stomp on switch blocks / crates (types
    ///    0x4e2…0x4ff / 0xc12…0xc1b), the teleporters 0x424…0x426;
    /// 10. the save point 0x429 (S1, `savePoint`) — reached past the not-built branches, whose type tests exclude it.
    static func box(_ w: SpriteWorld, player pID: Int, other oID: Int, keys: InputActions = []) {
        guard let p = w.active.record(id: pID), let o = w.active.record(id: oID) else { return }
        let h = { (v: Int) in Int(Int16(truncatingIfNeeded: v)) }
        let entryVY = p.vy                                              // `uVar38`
        if o.handler == .seeSawSegment {
            let cx = h(p.x + h((p.hotRect.left + p.hotRect.right) >> 1))
            if cx < h(o.x + o.hotRect.left) { return }
            if h(o.x + o.hotRect.right) < cx { return }
            w.active.update(id: oID) { $0.subState = 1 }
            w.player.seeSawTouch = true
        }
        let d = SpriteSlot.Point(x: h(p.centre.x - p.x), y: h(p.centre.y - p.y))
        if npcs.contains(o.type) {
            npc(w, other: oID)
            return
        }
        // later: Phase 4 — the doors 0xb5e / 0xb5f, the chest 0x51c, the timer 0xb5b (l. 49211–49286).
        if talk(w, other: oID, keys: keys) {
            w.player.talkTail = oID                                     // the rest runs at the resume (`talkDone`)
            return
        }
        boxTail(w, player: pID, other: oID, entryVY: entryVY, d: d, rect: p.hotRect)
    }

    /// The Box arm from the sign gate on (steps 5–10 above; l. 49304ff).
    private static func boxTail(_ w: SpriteWorld, player pID: Int, other oID: Int, entryVY: Int32, d: SpriteSlot.Point,
                                rect: IdleSprites.Rect) {
        guard let o = w.active.record(id: oID) else { return }
        if (0xb56...0xb5d).contains(o.type) && o.classWord15c == 0 { return }
        guard w.platformBounce(mover: pID, solid: oID, centre: d, factor: 0, rect: rect, bounce: false) == 1
        else { return }
        guard o.type == BoxSprite.trampoline else {                     // later: Phase 4 (7, 9)
            if o.type == BoxSprite.savePoint { savePoint(w, player: pID, other: oID) }
            return
        }
        w.active.update(id: oID) { $0.phase = 1 }
        guard 0xa5a < entryVY else { return }
        guard let p1 = w.active.record(id: pID) else { return }
        let v = -(trampolineFactor * Double(p1.gravity) - Double(0 &- entryVY))
        let vy = trampolineCap < v ? v : trampolineCap
        w.active.update(id: pID) { s in
            s.vy = Int32(vy)                                            // `fctiwz`: toward zero
            s.groundKind = 0
        }
        w.player.cue(PlayerCue(call: .reg, snd: 604, priority: 1, volume: 0x100))
        w.player.airCounter = 1
    }

    /// The NPC types 2951…2969 (`cmpwi r3,0xb87` / `0xb9a`, raw `10056d14..10056d20`).
    public static let npcs: ClosedRange<Int16> = 0xb87...0xb99
    /// The talk cooldown values (`li r0,0x96` raw `10056d44`; `li r0,0x5a` raw `10057070`).
    public static let npcCooldown: Int16 = 0x96
    public static let signCooldown: Int16 = 0x5a
    /// `.SimpleConv`'s portrait and name for the 2902 sign: PICT 4020 (`li r3,0xfb4`) and the pstr at `0x100a6254`.
    public static let signPortrait: Int16 = 0xfb4
    public static let signName = "Wooden Sign"

    /// The NPC arm (M l. 49199–49210, raw `10056d14..10056d68`): `+0xb0 ≠ 0` or the cooldown `*PTR_DAT_100a06cc ≠ 0`
    /// → nothing; else cooldown 150 and `.Conversation(p1 of the record, +0x48, the sprite)` — the frame suspends there.
    /// The caller returns on every path (never `.PlatformBounce`: NPCs are never solid). No `p1 > 100` test.
    static func npc(_ w: SpriteWorld, other oID: Int) {
        guard let o = w.active.record(id: oID), o.subtype == 0, w.player.countdown06cc == 0 else { return }
        w.player.countdown06cc = npcCooldown
        let i = Int(o.recordIndex)
        let p1 = w.records.indices.contains(i) ? w.records[i].p1 : 0
        w.suspension = .conversation(id: p1, record: i, sprite: oID)
    }

    /// The sign / grave arm (M l. 49287–49303, raw `10056fdc..10057134`): signs 0xb56…0xb5d except the timer 0xb5b, and
    /// the graves 0xb11…0xb14; (UP — `.IsInputKeyPressed(2)` — or the record's p4 == 0) ∧ p1 ≠ 0 ∧ cooldown 0 →
    /// cooldown 90, p4 ← 1 (raw `1005708c`, before the call), then the 2902 sign with p1 > 0 → `.SimpleConv(4020,
    /// "Wooden Sign", GetIndString(500, p1))` (`.sign`), any other type with p1 > 100 → `.Conversation(p1, +0x48, the
    /// sprite)` (`cmpwi r3,0x64` raw `10057124`; ≤ 100 nothing more). Returns true when the frame suspended.
    static func talk(_ w: SpriteWorld, other oID: Int, keys: InputActions) -> Bool {
        guard let o = w.active.record(id: oID) else { return false }
        let t = o.type
        guard ((0xb56...0xb5d).contains(t) && t != 0xb5b) || (0xb11...0xb14).contains(t) else { return false }
        let i = Int(o.recordIndex)
        guard w.records.indices.contains(i) else { return false }     // `+0x48` −1: no record (none on the levels)
        let r = w.records[i]
        guard keys.contains(.up) || r.p4 == 0, r.p1 != 0, w.player.countdown06cc == 0 else { return false }
        w.player.countdown06cc = signCooldown
        w.records[i] = Placement(index: r.index, flag: r.flag, byte1: r.byte1, type: r.type, p1: r.p1, p2: r.p2,
                                 p3: r.p3, p4: 1, y: r.y, x: r.x)
        if t == 0xb56 && 0 < r.p1 {
            let text = w.signTexts?.string(Int(r.p1)).map(MacRoman.bytes) ?? []
            w.suspension = .sign(text: text)
            return true
        }
        guard 100 < r.p1 else { return false }
        w.suspension = .conversation(id: r.p1, record: i, sprite: oID)
        return true
    }

    /// The rest of the sign / grave arm after its `.SimpleConv` / `.Conversation` returned (the frame's resume): the
    /// `+0x15c` gate and `.PlatformBounce` (step 5–6), with the player's centre offset and rect as they are — nothing
    /// moved while the frame was suspended.
    static func talkDone(_ w: SpriteWorld, player pID: Int) {
        guard let oID = w.player.talkTail else { return }
        w.player.talkTail = nil
        guard let p = w.active.record(id: pID) else { return }
        let h = { (v: Int) in Int(Int16(truncatingIfNeeded: v)) }
        let d = SpriteSlot.Point(x: h(p.centre.x - p.x), y: h(p.centre.y - p.y))
        boxTail(w, player: pID, other: oID, entryVY: p.vy, d: d, rect: p.hotRect)
    }

    /// The save point's arm (M l. 49471–49504, raw `10057714..10057858`; save-continue §2.1, §9.2), on a landing:
    /// 1. gate 1: `DAT_100a53d6` (no async gamma fade running, `AsyncGammaFade.done`) clear → return (raw `1005771c`);
    /// 2. gate 2: the record's p1 (`hdr + idx·16 + 8`, idx = `+0x48`) ≠ 0 → return (raw `10057740`);
    /// 3. the hold counter `*_DAT_100a0684 += 2` (raw `10057754..1005775c`); ≤ 15 → return (`cmpwi 0xf; ble`, raw
    ///    `10057768`) — `.HandlePlayerSprite` moves it one step toward 0 every frame (`Player.countdowns`, raw
    ///    `1004de68..1004de98`), so the 15th consecutive landing fires (BC22: the 65th after a cancel);
    /// 4. fire: counter −150 (`10057774`), `MTSetPortScreen` (no op), p1 ← `+0x17e` + 1 (`1005778c..100577a0`),
    ///    `ShowCursorSafe` (`100577a4`: the session's `.showCursor` with the suspension), `G+0x16` ← `+0x17e`
    ///    (`100577b0`), then `.SavePointSave()` (`100577b4`) — run by the flow: the frame **suspends** here
    ///    (`FrameSuspension.savePoint`) and `savePointDone` is the rest of the arm.
    static func savePoint(_ w: SpriteWorld, player pID: Int, other oID: Int) {
        guard w.gammaFade.done, let o = w.active.record(id: oID) else { return }
        let i = Int(o.recordIndex)
        guard w.records.indices.contains(i), w.records[i].p1 == 0 else { return }
        w.player.savePointHold &+= 2
        guard 0xf < w.player.savePointHold else { return }
        w.player.savePointHold = -0x96
        let facing: Int16 = (w.active.record(id: pID)?.mirrored ?? false) ? 1 : 0
        setP1(w, record: i, facing &+ 1)
        w.globals.startFacing = facing
        w.suspension = .savePoint(record: i)
    }

    /// The arm after `.SavePointSave` returns (raw `100577bc..10057858`): saved → `.STPlayRegSound(420, 1, 0x100)`
    /// (`_DAT_100a03e0`), `(421, 1, 0x100)` (`_DAT_100a03dc`), `GammaFadeOutAsync(2, white)` (the colour at `0x100a53ca`
    /// = FFFF ×3, BC1; r6/r7 0xc/0x10 unread; it calls `HideCursorSafe` when it arms, M l. 31905), three
    /// `HandleAsyncGammaFade` (0 %, 50 %, 100 %), `GammaFadeInAsync(0x2d)` — the frame's own `HandleAsyncGammaFade`
    /// then takes the first of its 46 steps (BC23); all gated on fading enabled (`DAT_100a53c2`), so with fading off
    /// there is no flash and gate 1 stays open. Not saved → p1 ← 0 (`1005783c..10057854`). Both: `HideCursorSafe`
    /// (`10057858`). Returns the draws and requests in call order.
    static func savePointDone(_ w: SpriteWorld, record i: Int, saved: Bool) -> (draws: [DrawOp], requests: [ShellRequest]) {
        var draws: [DrawOp] = [], requests: [ShellRequest] = []
        if saved {
            w.player.cue(PlayerCue(call: .reg, snd: 420, priority: 1, volume: 0x100))
            w.player.cue(PlayerCue(call: .reg, snd: 421, priority: 1, volume: 0x100))
            if w.gammaFade.fadeOut(steps: 2, toward: savePointFlashColour) { requests.append(.hideCursor) }
            for _ in 0..<3 { if let op = w.gammaFade.handle() { draws.append(op) } }
            w.gammaFade.fadeIn(steps: 0x2d)
        } else if w.records.indices.contains(i) {
            setP1(w, record: i, 0)
        }
        requests.append(.hideCursor)
        return (draws, requests)
    }

    /// The success flash's colour: the 6 bytes at `0x100a53ca` (`subi r5,r2,0x2476` @ `100577f4`; FFFF FFFF FFFF).
    public static let savePointFlashColour = RGB16(red: 0xffff, green: 0xffff, blue: 0xffff)

    /// The live record's p1 (`sth …,0x8(r3)`).
    private static func setP1(_ w: SpriteWorld, record i: Int, _ v: Int16) {
        let p = w.records[i]
        w.records[i] = Placement(index: p.index, flag: p.flag, byte1: p.byte1, type: p.type, p1: v, p2: p.p2, p3: p.p3,
                                 p4: p.p4, y: p.y, x: p.x)
    }

    /// `dRam100a1a10` = 0.6 and `dRam100a1a08` = −6500 (doubles; `tools/const.py`).
    static let trampolineFactor = 0.6
    static let trampolineCap = -6500.0
}

extension HitPlayerSprite {
    /// `GammaFadeOutAsync`'s colours (`.InitPlayerSprite` M l. 42420–42426): 1340's `_DAT_100a07f4` = (0xffff, 0x5555,
    /// 0xffff), 1341's `_DAT_100a07f0` = (0x5555, 0xffff, 0xffff).
    public static let healthUpgradeColour = RGB16(red: 0xffff, green: 0x5555, blue: 0xffff)
    public static let magicUpgradeColour = RGB16(red: 0x5555, green: 0xffff, blue: 0xffff)
    /// The upgrade types 1340 (max health) / 1341 (max magic).
    public static let healthUpgrade: Int16 = 0x53c
    public static let magicUpgrade: Int16 = 0x53d

    /// The Bonus arm (PK; `.HitPlayerSprite` M l. 48571–49123; pickups-boxes §1.3, §1.6–§1.8, spells-items §3, §5;
    /// the sound ids pickups-boxes-2 §1.3). `+0xe9 = 1` is the arm's own store (the literal 1); "KillBonus" is the call
    /// through `+0x50` (`lwz r12,0x50(r30)` at `100559e8`, `10055c18`, `10055c64` = `.KillBonus`, BN). The 3D sounds
    /// are placed at the player's `+0xe` (y) / `+0x10` (x); every pitched call draws its rate `FastRand(10000)` at the
    /// call. By type:
    /// - 1293 (M l. 48575–48586): snd 501, 489 at R + 40000, 489 at R + 30000; score + 100, coins + 25; `+0xe9`.
    /// - 1059 (M l. 48589–48594): record p1 ≠ 0 → snd 505; KillBonus.
    /// - 69, the Mist body (M l. 48597–48615): the spirit timer > 0x167 → nothing; else timer −1, `_DAT_100a0574 = 14`,
    ///   `PTR_DAT_100a05a8 = 6`, snd 420, `+0xe9`, the player to the stored body (`+0xc`/`+0xa` from the i32s
    ///   `04d4`/`04d0`, 24.8 from them, v = 0).
    /// - 1058 (M l. 48619–48630): `G+0xad8 + 2·p1` = p2, or 1 when p2 is 0; KillBonus.
    /// - 1055 / 1056 (M l. 48631–48695): `xichron`.
    /// - 1290 / 1291 / 1292 (M l. 48697–48738), 1300 / 1301 / 1302 / 1305 / 1306 (M l. 48745–48795), 1350 (M l.
    ///   48799–48807): `crystalOrCoin`.
    /// - 1340 / 1341 (M l. 48810–48916): snd 451 vol 0xab, score + 2000, `+0xe9`, `GammaFadeOutAsync(2, colour)` (its
    ///   `HideCursorSafe` → `PlayerState.passRequests`); the frame suspends (`.upgrade`, `UpgradeAnimation`).
    /// - 3050 (M l. 48920–48936): the glider pickup (`glider`).
    /// - 2000…2049 (M l. 48939–48976): `scroll`; 3200… (M l. 48977–49022): `item`; 1330…1339 (M l. 49023–49121):
    ///   `sphere`. Every other type (0x4bf, 0x421, 0x517, 0x518, …) does nothing.
    static func bonus(_ w: SpriteWorld, player pID: Int, other oID: Int, keys: InputActions, lights: inout LightTable,
                      effects: Int16) {
        guard let o = w.active.record(id: oID) else { return }
        let t = o.type, ti = Int(t)
        func dead() { w.active.update(id: oID) { $0.killCount = 1 } }           // `*(+0xe9) = 1`
        switch ti {
        case 0x50d:
            reg(w, 501, 0x100)
            pitched(w, player: pID, 489, 40000)
            pitched(w, player: pID, 489, 30000)
            w.globals.score &+= 100
            w.globals.coins &+= 0x19
            dead()
        case 0x423:
            if record(w, o.recordIndex).p1 != 0 { reg(w, 505, 0x100) }
            BonusSprite.kill(w, id: oID, lights: &lights)
        case 0x45:
            guard w.player.spiritTimer <= 0x167 else { return }
            w.player.spiritTimer = -1
            w.player.spiritTransition = 0xe
            w.player.countdown05a8 = 6
            reg(w, 420, 0x100)
            dead()
            let bx = Int(Int16(truncatingIfNeeded: w.player.mistBodyX))
            let by = Int(Int16(truncatingIfNeeded: w.player.mistBodyY))
            w.active.update(id: pID) { p in
                p.x = bx
                p.y = by
                p.x256 = Int32(bx) << 8
                p.y256 = Int32(by) << 8
                p.vy = 0
                p.vx = 0
            }
        case 0x422:
            let r = record(w, o.recordIndex)
            let i = Int(r.p1)
            // Carry (PK review): a p1 outside `worldFlags` is dropped here; the binary writes `G+0xad8 + 2·p1` whatever
            // p1 is — past the array's end into the rest of G (or beyond). No shipped 1058 has such a p1.
            if w.globals.worldFlags.indices.contains(i) { w.globals.worldFlags[i] = r.p2 == 0 ? 1 : r.p2 }
            BonusSprite.kill(w, id: oID, lights: &lights)
        case 0x41f, 0x420:
            xichron(w, player: pID, other: oID, keys: keys, lights: &lights, effects: effects)
        case 0x50a...0x50c, 0x514...0x516, 0x519, 0x51a, 0x546:
            crystalOrCoin(w, player: pID, other: oID)
        case 0x53c, 0x53d:
            reg(w, 451, 0xab)
            w.globals.score &+= 2000
            dead()
            // `GammaFadeOutAsync` calls `HideCursorSafe` when it arms (M l. 31905), as at the save point.
            if w.gammaFade.fadeOut(steps: 2, toward: t == magicUpgrade ? magicUpgradeColour : healthUpgradeColour) {
                w.player.passRequests.append(.hideCursor)
            }
            w.suspension = .upgrade(type: t)
        case 0xbea:
            glider(w, player: pID, other: oID)
        case 2000..<0x802:
            scroll(w, other: oID, keys: keys)
        case 0xc80...:
            item(w, other: oID, keys: keys)
        case 0x532...0x53b:
            sphere(w, player: pID, other: oID)
        default:
            return
        }
    }

    /// The placement record at `i` as the arms read it (`hdr + 16·i + …`): zeros outside the live records (plan hazard
    /// "Record index 0x200").
    private static func record(_ w: SpriteWorld, _ i: Int16) -> (p1: Int16, p2: Int16) {
        guard w.records.indices.contains(Int(i)) else { return (0, 0) }
        return (w.records[Int(i)].p1, w.records[Int(i)].p2)
    }

    /// `.STPlayRegSound(snd, 1, vol)` (no draw).
    private static func reg(_ w: SpriteWorld, _ snd: Int16, _ vol: Int16) {
        w.player.cue(PlayerCue(call: .reg, snd: snd, priority: 1, volume: vol))
    }

    /// `.STPlay3DSoundPitched(snd, 1, 0x100, player +0xe, FastRand(10000) + base)`.
    private static func pitched(_ w: SpriteWorld, player pID: Int, _ snd: Int16, _ base: Int32) {
        let rate = Int32(w.rng.next(10000)) + base
        let pos = w.active.record(id: pID)?.centre
        w.player.cue(PlayerCue(call: .threeDPitched, snd: snd, priority: 1, volume: 0x100, position: pos, rate: rate))
    }

    /// An arm's `.UpdateStatusBar(1, 1, 0)` inside the special pass (`StatusBarCalls.Site.pickup`): the key step reads
    /// the frame's actions; the op goes to `PlayerState.passDraws`, its suffocation tick (snd 442) joins the frame's
    /// sound calls at this point.
    static func statusBar(_ w: SpriteWorld, keys: InputActions) {
        var g = w.globals
        let made = w.statusBar.update(.pickup, globals: &g, actions: keys, levelName: w.level.header.name)
        w.globals = g
        w.player.passDraws.append(made.op)
        if made.suffocationTick {
            w.player.soundCalls.append(PlayerState.SoundCall(
                cue: PlayerCue(call: .reg, snd: StatusBarCalls.suffocationSound, priority: 1, volume: 0x100),
                scrollH: w.player.scrollH, scrollV: w.player.scrollV))
        }
    }

    /// 1055 / 1056 (M l. 48631–48695): 1055 score + 10, `G+0x14` + 1, snd 501 vol 0x55; 1056 score + 1000, `G+0x14`
    /// + 100, 489 at R + 40000 and R + 30000, snd 501 vol 0x55; KillBonus; the burst `.ExplodeFaceIntoParticles(face,
    /// (+0xa, +0xc), …, 0x28, 0x65)` — face `*PTR_DAT_100a0478` (set 0x421 face 0), `*_DAT_100a0474` (set 0x422 face 0)
    /// when `G+0x14 > 99`; Effects 1 with the particle count `*_DAT_100a019c` < 1000 → (1, 1, 1), 2 with < 0x5dc →
    /// (2, 1, 7), else (2, 2, 7). `G+0x14 < 100` → return; else `G+0x14 = 0` (raw `10055ac4..acc`), snd 451, 445, the
    /// Red Xichron item 0x16 + 1 (`GameGlobals.addItem`; no slot → return), `+0xe9`, snd 501, `.UpdateStatusBar(1, 1,
    /// 0)`. No item flash.
    private static func xichron(_ w: SpriteWorld, player pID: Int, other oID: Int, keys: InputActions,
                                lights: inout LightTable, effects: Int16) {
        guard let o = w.active.record(id: oID) else { return }
        if o.type == 0x41f {
            w.globals.score &+= 10
            w.globals.xichrons &+= 1
            reg(w, 501, 0x55)
        } else {
            w.globals.score &+= 1000
            w.globals.xichrons &+= 100
            pitched(w, player: pID, 489, 40000)
            pitched(w, player: pID, 489, 30000)
            reg(w, 501, 0x55)
        }
        BonusSprite.kill(w, id: oID, lights: &lights)
        let face = FaceRef(pict: 99 < w.globals.xichrons ? 0x422 : 0x421, index: 0, set: .encoded)
        let count = w.particles.counters.count
        let step: (x: Int16, y: Int16, shape: Int16)
        if effects == 1 && count < 1000 {
            step = (1, 1, 1)
        } else if effects == 2 && count < 0x5dc {
            step = (2, 1, 7)
        } else {
            step = (2, 2, 7)
        }
        ExplodeFace.explode(w, face: w.particleFaces.sprite(face), v: Int16(truncatingIfNeeded: o.y),
                            h: Int16(truncatingIfNeeded: o.x), xStep: step.x, yStep: step.y, shape: step.shape,
                            gravity: 0x28, style: 0x65)
        guard 100 <= w.globals.xichrons else { return }
        w.globals.xichrons = 0
        reg(w, 451, 0x100)
        reg(w, 445, 0x100)
        guard w.globals.addItem(0x16, count: 1) != -1 else { return }
        w.active.update(id: oID) { $0.killCount = 1 }
        reg(w, 501, 0x100)
        statusBar(w, keys: keys)
    }

    /// The crystals, money bag, coins and the air bubble (each `+0xe9 = 1`; the clamps as written):
    /// - 1290 (M l. 48699–48707): snd 500; score + 100; magic `G+0xe` + 0x2a0, > `G+0xc` → `G+0xc`.
    /// - 1291 (M l. 48720–48737): snd 502; score + 100; health `G+4` and breath `G+6` + 0x2a0, the player's `+0xa4` +
    ///   0xe0; each > max health `G+0xa` → `G+0xa`.
    /// - 1292 (M l. 48711–48718): snd 501, 489 at R + 40000; score + 25, coins + 5.
    /// - 1300 (M l. 48763–48772): snd 500 vol 0xab; score + 25; magic + 0xe0, clamped.
    /// - 1301 (M l. 48774–48788): snd 502; score + 25; `+0xa4` + 0xe0, breath + 0xe0, `G+8 = 30`, breath then `+0xa4`
    ///   clamped to `G+0xa`, health = `+0xa4`.
    /// - 1302 / 1305 / 1306 (M l. 48754–48760, 48790–48795, 48746–48752): snd 501 vol 0xab; score + 5; coins + 1 / 10 /
    ///   100.
    /// - 1350 (M l. 48799–48807): snd 456; breath + 0x230, > health → health.
    private static func crystalOrCoin(_ w: SpriteWorld, player pID: Int, other oID: Int) {
        guard let o = w.active.record(id: oID) else { return }
        func dead() { w.active.update(id: oID) { $0.killCount = 1 } }
        var g = w.globals
        switch o.type {
        case 0x50a:
            dead()
            reg(w, 500, 0x100)
            g.score &+= 100
            g.magic &+= 0x2a0
            if g.maxMagic < g.magic { g.magic = g.maxMagic }
        case 0x50b:
            dead()
            reg(w, 502, 0x100)
            g.score &+= 100
            g.health &+= 0x2a0
            g.breath &+= 0x2a0
            let max = g.maxHealth
            w.active.update(id: pID) { $0.hp &+= 0xe0 }
            if max < g.health { g.health = max }
            if max < g.breath { g.breath = max }
            w.active.update(id: pID) { p in if max < p.hp { p.hp = max } }
        case 0x50c:
            reg(w, 501, 0x100)
            pitched(w, player: pID, 489, 40000)
            g.score &+= 0x19
            g.coins &+= 5
            dead()
        case 0x514:
            dead()
            reg(w, 500, 0xab)
            g.score &+= 0x19
            g.magic &+= 0xe0
            if g.maxMagic < g.magic { g.magic = g.maxMagic }
        case 0x515:
            dead()
            reg(w, 502, 0x100)
            g.score &+= 0x19
            w.active.update(id: pID) { $0.hp &+= 0xe0 }
            g.breath &+= 0xe0
            g.suffocation = 0x1e
            let max = g.maxHealth
            if max < g.breath { g.breath = max }
            w.active.update(id: pID) { p in if max < p.hp { p.hp = max } }
            g.health = w.active.record(id: pID)?.hp ?? g.health
        case 0x516, 0x519, 0x51a:
            reg(w, 501, 0xab)
            g.score &+= 5
            g.coins &+= o.type == 0x516 ? 1 : o.type == 0x519 ? 10 : 100
            dead()
        case 0x546:
            reg(w, 456, 0x100)
            g.breath &+= 0x230
            if g.health < g.breath { g.breath = g.health }
            dead()
        default:
            return
        }
        w.globals = g
    }

    /// 3050, the hang glider (M l. 48920–48936): only with `PTR_DAT_100a05c4 == 0`: `+0xe9`, on the glider
    /// `_DAT_100a05e0 = 1`, `_DAT_100a05d4 = 1`, `PTR_DAT_100a05c8 = 0`; the player's 24.8 position = the glider's, its
    /// `+0xc` / `+0xa` from them (`>> 8`, i16); `+0xc0` = the cached set `_DAT_100a0778` face 0 (PICT 0x41a,
    /// `.InitPlayerSprite` M l. 42486); `SetRect(+0x34, 0x37, 0x3e, 99, 0x6e)`. // later: GL — the glider's row and
    /// the 0x41a faces (renderer sheet).
    private static func glider(_ w: SpriteWorld, player pID: Int, other oID: Int) {
        guard w.player.countdown05c4 == 0, let o = w.active.record(id: oID) else { return }
        w.active.update(id: oID) { $0.killCount = 1 }
        w.player.glider = true
        w.player.gliderExit = 1
        w.player.glider05c8 = 0
        w.active.update(id: pID) { p in
            p.x256 = o.x256
            p.y256 = o.y256
            p.x = Int(Int16(truncatingIfNeeded: p.x256 >> 8))
            p.y = Int(Int16(truncatingIfNeeded: p.y256 >> 8))
            p.face = FaceRef(pict: gliderFaceSet, index: 0, set: .encoded)
            p.hotRect = IdleSprites.Rect(top: 0x3e, left: 0x37, bottom: 0x6e, right: 99)
        }
    }

    /// `_DAT_100a0778`'s PICT (`_CacheEncFaceSetFromPICT(…, 0x41a, 6, 0xa0, 0xa0, …)`, M l. 42486).
    public static let gliderFaceSet: Int16 = 0x41a

    /// 2000…2049 (M l. 48939–48976): spell = record p1 for 2000, else type − 2000; `GameGlobals.learnSpell` (the first
    /// slot empty or holding that spell, compared before the 2 → 3 remap — BC48); no slot → return (no sound, not
    /// killed); `+0xe9`, snd 503, the item flash `PTR_DAT_1009fda8 = 0x20` on the slot (`_DAT_1009fda4`), mode
    /// `_DAT_1009fda0 = 0`; `.UpdateStatusBar(1, 1, 0)`.
    private static func scroll(_ w: SpriteWorld, other oID: Int, keys: InputActions) {
        guard let o = w.active.record(id: oID) else { return }
        let spell = o.type == 2000 ? record(w, o.recordIndex).p1 : o.type &- 2000
        let k = w.globals.learnSpell(spell)
        guard k != -1 else { return }
        w.active.update(id: oID) { $0.killCount = 1 }
        reg(w, 503, 0x100)
        flash(w, slot: k)
        statusBar(w, keys: keys)
    }

    /// The item flash a scroll / item pickup sets (M l. 48970–48974, 49016–49020).
    private static func flash(_ w: SpriteWorld, slot k: Int) {
        w.statusBar.flashes.item = 0x20
        w.statusBar.flashes.itemSlot = Int16(k)
        w.statusBar.flashes.itemMode = 0
    }

    /// 3200… (M l. 48977–49022): 3221 first `.RemoveItem(0)` (the dagger), 3215 first `.RemoveItem(0xe)` (the wooden
    /// shield) — each `.UpdateItemStat` when found (M l. 39658); `GameGlobals.addItem(type − 3200, 3 for 3206 else 1)`;
    /// no slot → return; `+0xe9`, snd 506, the item flash as a scroll's, `.UpdateStatusBar(1, 1, 0)`.
    private static func item(_ w: SpriteWorld, other oID: Int, keys: InputActions) {
        guard let o = w.active.record(id: oID) else { return }
        func remove(_ id: Int16) {
            guard w.globals.removeItem(id) else { return }
            var g = w.globals
            w.player.passDraws.append(w.statusBar.itemStat(globals: &g, levelName: w.level.header.name))
            w.globals = g
        }
        if o.type == 0xc95 { remove(0) }
        if o.type == 0xc8f { remove(0xe) }
        let k = w.globals.addItem(o.type &- 0xc80, count: o.type == 0xc86 ? 3 : 1)
        guard k != -1 else { return }
        w.active.update(id: oID) { $0.killCount = 1 }
        reg(w, 506, 0x100)
        flash(w, slot: k)
        statusBar(w, keys: keys)
    }

    /// 1330…1339 (M l. 49023–49121; spells-items §5): the sphere stays (except 1339) and hides for its duration
    /// (`sphere+0xa6`, M l. 49120). 1330: `064c` = 600, `0654` = 1, snd 447. 1331…1333: `0640` = 600, `0648` = 1,
    /// `0644` = 1, `063c` = type − 0x533, snd 444. 1334: `0630` = 600, `0634` = 1, `0638` = 1, snd 449. 1335: the
    /// player's `+0x116` = 0x1c2, `0650` = 0x1c2, snd 446; hides 32000 when the record's p2 is 0, else 0x1c2. 1336:
    /// `0624` = 900, `0628`, `062c` = 1, snd 445. 1337: `0618` = 600, `061c`, `0620` = 1, snd 447. 1338: `053c` + 5 (≤ 8);
    /// orbs 0…n−1: angle i·(360 / n)·256, radius 0x30, speed 0xa00, in use, a live orb sprite `+0xe9 = 1` and dropped;
    /// orbs n…7 not in use (their sprites likewise); `0614 = 1`; 32000; snd 444. 1339: `+0xe9`, snd 450 vol 0xab, the
    /// player's `+0xa4` − 0x380, `+0x116 = 30`, `+0xaa = 30`; 0. // later: PU / SD — the timers' `.TickTock`s, the
    /// double and the orbs.
    private static func sphere(_ w: SpriteWorld, player pID: Int, other oID: Int) {
        guard let o = w.active.record(id: oID) else { return }
        var duration: Int16 = 0
        switch o.type {
        case 0x532:
            w.player.shadowTimer = 600
            duration = 600
            w.player.shadowDouble = true
            reg(w, 447, 0x100)
        case 0x533...0x535:
            w.player.walkOnLiquidTimer = 600
            duration = 600
            w.player.walkOnLiquid = true
            w.player.tint0644 = true
            w.player.walkOnLiquidKind = o.type &- 0x533
            reg(w, 444, 0x100)
        case 0x536:
            w.player.highJumpTimer = 600
            duration = 600
            w.player.tint0634 = true
            w.player.highJump = true
            reg(w, 449, 0x100)
        case 0x537:
            w.active.update(id: pID) { $0.invulnerable = 0x1c2 }
            w.player.invincibleTimer = 0x1c2
            duration = record(w, o.recordIndex).p2 == 0 ? 32000 : 0x1c2
            reg(w, 446, 0x100)
        case 0x538:
            w.player.featherFallTimer = 900
            duration = 900
            w.player.tint0628 = true
            w.player.featherFall = true
            reg(w, 445, 0x100)
        case 0x539:
            w.player.doubleSpeedTimer = 600
            duration = 600
            w.player.tint061c = true
            w.player.doubleSpeed = true
            reg(w, 447, 0x100)
        case 0x53a:
            w.player.pentashieldCount &+= 5
            if 8 < w.player.pentashieldCount { w.player.pentashieldCount = 8 }
            let n = Int(w.player.pentashieldCount)
            for i in 0..<8 {
                var orb = w.player.orbs[i]
                if i < n {
                    orb.angle = Int32(i) * Int32(0x168 / n) * 0x100
                    orb.radius = 0x30
                    orb.speed = 0xa00
                    orb.active = true
                } else {
                    orb.active = false
                }
                if let sprite = orb.sprite {
                    w.active.update(id: sprite) { $0.killCount = 1 }
                    orb.sprite = nil
                }
                w.player.orbs[i] = orb
            }
            duration = 32000
            w.player.flag0614 = true
            reg(w, 444, 0x100)
        case 0x53b:
            w.active.update(id: oID) { $0.killCount = 1 }
            reg(w, 450, 0xab)
            w.active.update(id: pID) { p in
                p.hp &-= 0x380
                p.invulnerable = 0x1e
                p.flash = 0x1e
            }
        default:
            return
        }
        w.active.update(id: oID) { $0.counterA6 = duration }
    }
}

/// The session's part of a passage jump (`.HitPlayerSprite` l. 49659–49682; W2b), called by `HitPlayerSprite.passage`
/// at the binary's call sites — a world without a session (nil) skips them.
public struct PassageView {
    /// Per matching idle entry, after the player has moved: the camera snap (`Camera.snap`), `*_DAT_1009fec4` saved /
    /// 0 / restored around 90 `.FindUpperLeftCorner` passes, the scroll location `_DAT_1009fe74/fe70` from the scroll
    /// point, `.RedrawEntireScrollGrid`.
    public var snap: (SpriteWorld) -> Void
    /// After the scan: `.HandleIdleSprites`, `.WrapDrawSprites`, `.RedrawEntireScrollGrid`.
    public var redraw: (SpriteWorld) -> Void

    public init(snap: @escaping (SpriteWorld) -> Void, redraw: @escaping (SpriteWorld) -> Void) {
        self.snap = snap
        self.redraw = redraw
    }
}

extension HitPlayerSprite {
    /// The fade colour `.GammaFadeOutAsync` gets at a passage: the 6 bytes at `0x100a5f60` (`subi r5,r2,0x18e0` @
    /// `10057f44`; data (0, 0, 0) in the PEF image, no writer) — black.
    public static let passageFadeColour = RGB16(red: 0, green: 0, blue: 0)

    /// The passage arm (0xb54 / 0xb55, decompile l. 49594–49683; triggers-background §2.11, -2 §8.2):
    /// 1. the door counter `_DAT_100a06f0` 0 and UP (action 2) not pressed → return; at 0: the walk counter
    ///    `_DAT_100a05f8 = 1` and `.GammaFadeOutAsync(0x14, black)` (its arm's `HideCursorSafe` → `passRequests`);
    /// 2. `06f0` += 1; 0x15 → the look-ahead `_DAT_100a0680 = 0`; not 0x16 → return (frozen meanwhile: `.HandlePlayerSprite`
    ///    skips `.HandleKeys` and zeroes v while `06f0` ≠ 0);
    /// 3. at 0x16: d = the player's origin − the passage's (i16); `0680 = 0`; the record's p2 (darkness) — // later: the
    ///    level darkness override (`G+0x20`, hdr 0x2706; every shipped passage has p2 0); then every used idle entry of
    ///    0 … 510 whose record index `+0xe` is this passage's p1 (all scanned, no early exit) moves the player to the
    ///    entry's (x, y) + d: `+0xc = fe68`, `+0xa = fe64`, the centre from the hot rect into `+0x10/+0xe` and
    ///    `fd94/fd90`, the camera focus `fd44/fd40` = the centre, 24.8 from the origin; then `PassageView.snap`;
    /// 4. `PassageView.redraw`, `.GammaFadeInAsync(0x14)`, `05f8 = −15`, `06f0 = −0x16`.
    /// The counter climbs back to 0 one contact at a time — the player, frozen with the offset kept, touches the
    /// partner (triggers-background-2 §8.2).
    static func passage(_ w: SpriteWorld, player pID: Int, passage oID: Int, keys: InputActions) {
        if w.player.doorTransit == 0 && !keys.contains(.up) { return }
        if w.player.doorTransit == 0 {
            w.player.animation05f8 = 1
            // `GammaFadeOutAsync` calls `HideCursorSafe` when it arms (M l. 31905), as at the upgrade.
            if w.gammaFade.fadeOut(steps: 0x14, toward: passageFadeColour) { w.player.passRequests.append(.hideCursor) }
        }
        w.player.doorTransit &+= 1
        if w.player.doorTransit == 0x15 { w.player.lookAhead = 0 }
        guard w.player.doorTransit == 0x16,
              let p = w.active.record(id: pID), let o = w.active.record(id: oID) else { return }
        w.player.lookAhead = 0
        // later: Phase 4 — p2 ≠ 0: −1 → `G+0x20 = 0`, hdr 0x2706 = `G+0x22`; 10 → 0; else hdr 0x2706 = p2, `G+0x20 = 1`.
        let h = { (v: Int) in Int(Int16(truncatingIfNeeded: v)) }
        let dx = h(p.x - o.x), dy = h(p.y - o.y)
        let partner = BackgroundSprite.record(w, o)?.p1
        for i in 0..<IdleSprites.scanned {
            guard let e = w.idle.entries[i], let partner, e.saved.recordIndex == partner else { continue }
            w.active.update(id: pID) { s in
                s.x = h(dx + e.saved.x)
                s.y = h(dy + e.saved.y)
                let r = s.hotRect
                s.centre.x = h(s.x + r.left + h((r.right - r.left) >> 1))
                s.centre.y = h(s.y + r.top + h((r.bottom - r.top) >> 1))
                s.x256 = Int32(s.x) << 8
                s.y256 = Int32(s.y) << 8
            }
            guard let s = w.active.record(id: pID) else { return }
            w.player.pixelX = Int16(truncatingIfNeeded: s.x)
            w.player.pixelY = Int16(truncatingIfNeeded: s.y)
            w.player.centreX = Int16(truncatingIfNeeded: s.centre.x)
            w.player.centreY = Int16(truncatingIfNeeded: s.centre.y)
            w.player.focusX = w.player.centreX
            w.player.focusY = w.player.centreY
            w.passageView?.snap(w)
        }
        w.passageView?.redraw(w)
        w.gammaFade.fadeIn(steps: 0x14)
        w.player.animation05f8 = -15
        w.player.doorTransit = -0x16
    }
}

/// `.HurtPlayer(player, attacker, damage, blood, invul, coins) @ 1005473c` (decompile l. 47955–48105;
/// enemy-shots-and-damage §3.7). Returns whether the hurt landed.
/// 1. **The attacker gate** (l. 47983–47985, raw `10054768..10054794`): an attacker with HP `+0xa4` < 1 whose Handle is
///    neither `.HandleEnemyShotSprite` (`PTR_PTR_100a0488`) nor `.HandleBoxSprite` (`PTR_PTR_100a0484`) hurts not at
///    all (0, no draw). [Plan W2a named "Platform / Background" — the dump and the bank (review A3) say EnemyShot /
///    Box.] Core has no EnemyShot Handle yet: // later: Phase 4 (enemy shots are `inert` until then).
/// 2. `.HurtSprite(player, damage, (i16) attacker vx, −1000, invul, 0xc)` (`HurtSprite.apply`); 0 → return 0.
/// 3. // later: Phase 4 — item 0x13 (`HasItemWhichSlot(0x13)`, the attacker not a Blob nor a Background 0x730…0x733):
///    `_DAT_100a073c = 0xf`, snd 507, `PTR_DAT_1009fda8 = 0xf`, four 0x4bf + i sprites with 3 draws each. No Phase-2
///    inventory holds it.
/// 4. `_DAT_100a059c = 5`; on a magic carpet (`PTR_DAT_100a05a4`) a rising ridden sprite (`PTR_DAT_100a0558`
///    `+0x2c < 0`) stops; `_DAT_100a05b0 = 0`, stun `_DAT_100a0748 = 1`, spin `PTR_DAT_100a0668 = 0`, pull-up
///    `_DAT_100a06a0 = 0`, climb `_DAT_100a0758 = 0`, exertion `_DAT_100a06a4 += 0x50`.
/// 5. blood → `.BloodSpray(player, attacker, 0x28, 500, 0x96, 2)` (`bloodSpray`, the E1a seam).
/// 6. The cues (snd slots: 508 `a02b8`, 450 `a02dc`, 401 `a0414`, 402 `a0410`, 403 `a040c`): damage < 0xe0 →
///    `.STPlayRegSoundPitched(508, 1, 0x97, FastRand(10000) + 65000)`, then R = `FastRand(3)`: 1 → `.STPlayRegSound(402,
///    1, 0xab)`, 0 → 401, 2 → 403; else `.STPlayRegSound(450, 1, 0xab)`, `.STPlayRegSoundPitched(508, 1, 0x100,
///    FastRand(10000) + 50000)`, `…(508, 1, 0x100, FastRand(10000) + 65000)`. The rates are drawn here, sound on or
///    off (Invariant 4; S1 does the volume arithmetic only).
/// 7. coins n ≠ 0: n > 2 → n = FastRand(3) + n − 1; capped at `G+0x10`; `G+0x10 −= n`; n > 0 →
///    `.STPlay3DSoundRand(489, 1, 0x100, player +0xe)`; per coin `FastRand(8)` (dy), `FastRand(8)` (dx), the Bonus
///    0x516 at (cx + dx − 8, cy + dy − 2), layer 0x14, `+0xb0 = 0xc`, vx = `FastRand(0x640)` + 600 (negated when
///    `FastRand(100)` > 0x31), vy = −2000 − `FastRand(0xdac)`, `+0x16c = −0xf0` (M l. 48088–48104). PK: each coin is
///    spawned — `.MTNewSprite(0x516, …, 0x14, −1, .SetupBonusSprite)` runs the Bonus Setup inside the call
///    (`BonusSprite.setup`: its R(9), R(6), R(3) — arm `LAB_1005e02c`, M l. 52576–52581 — and R(0x3c), tail
///    `LAB_1005e8bc`, M l. 52795) and the Setup's `+0x80 = 1` (M l. 52383) is the layer the insert uses, not the 0x14
///    passed; nine draws per coin. With all 700 records in use `.MTNewSprite` returns 0 without running the Setup
///    (Ruling 16, BC46): five draws — R(8), R(8), R(0x640), R(100), R(0xdac) — and the stores go nowhere. The count is
///    also summed in `PlayerState.coinsLost`.
public enum HurtPlayer {
    /// The coin `.HurtPlayer` knocks out (1302).
    public static let lostCoin: Int16 = 0x516

    @discardableResult
    public static func hurt(_ w: SpriteWorld, player pID: Int, attacker aID: Int, damage: Int16, blood: Bool,
                            invulnerable: Int16, coins: Int16) -> Bool {
        guard let a = w.active.record(id: aID) else { return false }
        if a.hp < 1 && a.handler != .box { return false }               // later: Phase 4 — or the EnemyShot Handle
        guard HurtSprite.apply(w, id: pID, damage: damage, dvx: Int16(truncatingIfNeeded: a.vx), dvy: -1000,
                               invulnerable: invulnerable, flash: 0xc) else { return false }
        // later: Phase 4 — the item-0x13 arm (no Phase-2 inventory).
        w.player.carpetLock = 5
        if w.player.carpet, let r = w.player.ridden, let rs = w.active.record(id: r), rs.vy < 0 {
            w.active.update(id: r) { $0.vy = 0 }
        }
        w.player.potion = 0
        w.player.stun = 1
        w.player.spin = false
        w.player.pullUp = 0
        w.player.climb = 0
        w.player.exertion &+= 0x50
        if blood { bloodSpray(w, player: pID, attacker: aID, count: 0x28, speed: 500, spread: 0x96, kind: 2) }
        func cue(_ c: PlayerCue.Call, _ snd: Int16, _ vol: Int16, rate: Int32? = nil, pos: SpriteSlot.Point? = nil) {
            w.player.cue(PlayerCue(call: c, snd: snd, priority: 1, volume: vol, position: pos, rate: rate))
        }
        if damage < 0xe0 {
            cue(.regPitched, 508, 0x97, rate: Int32(w.rng.next(10000)) + 65000)
            switch w.rng.next(3) {
            case 1: cue(.reg, 402, 0xab)
            case 0: cue(.reg, 401, 0xab)
            case 2: cue(.reg, 403, 0xab)
            default: break
            }
        } else {
            cue(.reg, 450, 0xab)
            cue(.regPitched, 508, 0x100, rate: Int32(w.rng.next(10000)) + 50000)
            cue(.regPitched, 508, 0x100, rate: Int32(w.rng.next(10000)) + 65000)
        }
        if coins != 0 {
            var n = coins
            if 2 < n { n = w.rng.next(3) &+ n &- 1 }
            if w.globals.coins < n { n = w.globals.coins }
            w.globals.coins &-= n
            if 0 < n {
                let pos = w.active.record(id: pID)?.centre
                cue(.threeDRand, 489, 0x100, rate: w.rng.soundRate(), pos: pos)
            }
            var k: Int16 = 0
            while k < n {
                let dy = Int(w.rng.next(8))
                let cy = w.active.record(id: pID)?.centre.y ?? 0
                let dx = Int(w.rng.next(8))
                let cx = w.active.record(id: pID)?.centre.x ?? 0
                let layer = w.active.record(id: pID)?.layer ?? 0
                let x = Int(Int16(truncatingIfNeeded: cx + dx - 8)), y = Int(Int16(truncatingIfNeeded: cy + dy - 2))
                let coin = w.newSprite(type: lostCoin, x: x, y: y, layer: 0x14, handler: .bonus) { s in
                    // Cannot throw: `BonusSprite.setup` throws only for the candelabra 0xc25 and an item id outside
                    // 0xc80…0xc9a (`SetupFaces.Error.notTranscribed`) — never for the coin 0x516 (arm `LAB_1005e02c`).
                    _ = try! BonusSprite.setup(&s, x: x, y: y, level: w.level, records: w.records, effects: 0,
                                               lightCount: 0, counting: false, playerLayer: layer, rng: &w.rng) {
                        _, _, _, _ in -1                                // the coin arm adds no light (M l. 52571–52581)
                    }
                }
                let vx = Int32(w.rng.next(0x640)) + 600
                let sign = w.rng.next(100)
                let vy = -2000 - Int32(w.rng.next(0xdac))
                if let coin {
                    w.active.update(id: coin) { s in
                        s.pickupDelay = 0xc
                        s.vx = 0x31 < sign ? -vx : vx
                        s.vy = vy
                        s.coinLife = -0xf0
                    }
                }
                k += 1
            }
            w.player.coinsLost &+= n
        }
        return true
    }

    /// `.BloodSpray(s, attacker, count, speed, spread, kind) @ 100425f8` (particles §5.3; E1a): 40 particles and their
    /// 80 `FastRand` draws when the hot rects overlap (`BloodSpray`).
    static func bloodSpray(_ w: SpriteWorld, player: Int, attacker: Int, count: Int16, speed: Int16, spread: Int16,
                           kind: Int16) {
        BloodSpray.spray(w, victim: player, attacker: attacker, count: count, speed: speed, spread: spread, kind: kind)
    }
}

/// `.HurtSprite(s, damage, dvx, dvy, invul, flash) @ 10037034` (decompile l. 32705–32726): damage < 1 or HP `+0xa4`
/// < 1 or `+0x116` ≠ 0 → 0; else HP −= damage, vx += dvx, vy += dvy, `+0x116 = invul`, `+0xaa = flash`, 1.
public enum HurtSprite {
    @discardableResult
    public static func apply(_ w: SpriteWorld, id: Int, damage: Int16, dvx: Int16, dvy: Int16, invulnerable: Int16,
                             flash: Int16) -> Bool {
        guard 0 < damage, let s = w.active.record(id: id), 0 < s.hp, s.invulnerable == 0 else { return false }
        w.active.update(id: id) { c in
            c.hp &-= damage
            c.vx &+= Int32(dvx)
            c.vy &+= Int32(dvy)
            c.invulnerable = invulnerable
            c.flash = flash
        }
        return true
    }
}
