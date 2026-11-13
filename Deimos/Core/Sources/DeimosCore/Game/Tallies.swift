import Foundation
import HectorResources

/// The end-of-level tallies (scoring-bonuses.md §6.3–§6.5; plan C17): the ground-accuracy tier and tally, the mission
/// bonus, each player's coin bonus, and the tally text draw. Index-based (plan invariant 13).
///
/// Listing reads (`disasm-review3-all.txt`; flli = `flli gafl` PermFloat, pgsl = game string, gaso = PermSoundID;
/// "wait N" = `timer + int(flli) < now`, strict `cmpw; ble`, so a wait of N lasts N + 1 ticks):
/// - `FUN_100072c0` (`100072c0..100075dc`): see `accuracyTier`.
/// - `FUN_100075e0` (`100075e0..10007d50`, jump table `r2−0x2660` = `0x100e3cd0` read from `mem/100de330.bin`:
///   0 → `10007624`, 1 → `1000762c`, 2 → `100076ac`, 3 → `10007770`, 4 → `10007804`, 5 → `100078cc`,
///   6 → `100079a0`, 7 → `10007ab8`, 8 → `10007af4`, 9 → `10007be4`, 10 → `10007c38`; > 10 → returns 0). Formats at
///   `r2−0x2634` + 0x40d `"%s%i%%"`, + 0x414 `"%s%i%%%s"`, + 0x41d `"%s%i%%%s%s"`, + 0x428 `"%s%i%%%s%i"`, + 0x433
///   `""`. Every sound is `FUN_10047670(gaso k, priority 50, volume 100, multiple 0)` except the mission's (priority
///   100). The waits and their flli values as read (states 1–5, 7, 9 were MED in the bank):
///   | state | per tick | wait (flli, value) | on exit |
///   |---|---|---|---|
///   | 0 | — | — | returns 1 (done) |
///   | 1 | — | 195 = 60 (196 = 1200 when G+0x0d) | → 2, timer, moco (gaso 20) |
///   | 2 | alpha −1 (not below 0) × int(flli 203 = 3) | 197 = 20 | → 3, timer, moco, text `"%s%i%%"` (pgsl 11, %) |
///   | 3 | — | 197 = 20 | → 4, timer, text `"%s%i%%%s"` (+ pgsl 12), moco |
///   | 4 | — | 197 = 20 | → 5, timer; % == 100 → G+0x44 += 1, acbo (22); else bonus == 0 → nobo (21); else moco |
///   | 5 | text: bonus == 0 → `"%s%i%%%s%s"` (+ pgsl 13 "None!"), else `"%s%i%%%s%i"` (+ bonus) | 197 = 20 | → 6, timer |
///   | 6 | bonus ≤ 0 → 7, timer (no wait); else every tick past tick timer + flli 198 (2): tick timer = now, remaining −= step (clamped ≥ 0), `FUN_10029a10(P1, step, 0)`, P2 likewise, moco, text with the remainder | — | — |
///   | 7 | — | 201 = 20 | → 8, timer |
///   | 8 | alpha < 32 (unsigned) → alpha += int(flli 204 = 3), capped 32 | 202 = 20 | G+0x44 == `FUN_10011de0` (12) → flag, payments 0, → 9, timer, alpha 0, text pgsl 10, miac (23, priority 100); else returns 1 (state stays 8) |
///   | 9 | — | 206 = 4 | → 10, timer, alpha 32, text `""` |
///   | 10 | flag clear → returns 1; else past flli 207 (3): payments += 1, `FUN_10029a10(Pn, int(flli 205) = 100000, raw 1)` for P1, P2; payments ≥ int(flli 208 = 10) → flag 0 (state stays 10); else → 9, timer, alpha 0, text pgsl 10 | 207 = 3 | — |
///   The tick timer is set only by the tier (to the level-end time) and by state 6, so state 6 pays on its first tick.
/// - `FUN_10027670` (`10027670..10027920`): see `coinTallySetup`. `FUN_10027db0` (`10027db0..10027dc0`): `+0xd8 ≠ 0`.
/// - `FUN_10027930` (`10027930..10027da8`, jump table `r2+0x3018` = `0x100e9348`: 0 → `10027970`, 1 → `10027978`,
///   2 → `100279d0`, 3 → `10027a8c`, 4 → `10027b20`, 5 → `10027bfc`, 6 → `10027c34`, 7 → `10027d30`,
///   8 → `10027d68`; > 8 → returns 0). Formats at `r2+0x30e8` + 0x538 `"%s%i"`, + 0x53d `"%s%i%s%i"`, + 0x546
///   `"%s%i%s%i%s%i"`. Sounds as above (priority 50):
///   | state | per tick | wait (flli, value) | on exit |
///   |---|---|---|---|
///   | 0 | — | — | returns 1 |
///   | 1 | — | 172 = 10 | → 2, timer, moco |
///   | 2 | alpha −1 (not below 0) × int(flli 177 = 3) | 173 = 20 | → 3, timer, moco, text `"%s%i"` (pgsl 14, money0) |
///   | 3 | — | 173 = 20 | → 4, timer, moco, text `"%s%i%s%i"` (+ pgsl 15, coin value) |
///   | 4 | — | 173 = 20 | → 5, timer; bonus ≤ 0 → nobo else moco; text `"%s%i%s%i%s%i"` (+ pgsl 16, bonus) |
///   | 5 | — | 173 = 20 | → 6, timer |
///   | 6 | bonus ≤ 0 → 7, timer; else past tick timer + flli 176 (2): tick timer = now, in game → money −= 1, `FUN_10029a10(p, step, 0)`, remaining −= step (not clamped), moco, text with the remainder | — | — |
///   | 7 | — | 174 = 30 | → 8, timer |
///   | 8 | — | 175 = 20 | returns 1 (state stays 8) |
/// - `FUN_10007d60` (`10007d60..10007df8`): see `tallyTextRequest`.
extension GameState {
    /// int(flli i) — `FUN_10020250(i)` then `fctiwz`.
    private func flliInt(_ i: Int) -> Int32 { EntityDraw.fctiwz(assets.floats[i]) }

    /// `FUN_10047670(gaso k, priority, 100, 0)`.
    private mutating func tallySound(_ k: Int, priority: Int32 = 0x32) {
        cues.sounds.append(SoundPlay.perm(assets.sounds[k], priority: priority, volume: 100, allowMultiple: false))
    }

    /// The tallies' `sprintf` (`FUN_10055390`): pgsl strings (`FUN_10020260`) and `%i` integers, concatenated.
    private enum Piece { case string(Int), int(Int32), percent }
    private func format(_ pieces: [Piece]) -> [UInt8] {
        var out: [UInt8] = []
        for p in pieces {
            switch p {
            case .string(let i): out += assets.gameStrings[i].prefix { $0 != 0 }
            case .int(let v): out += Array(String(v).utf8)
            case .percent: out.append(0x25)
            }
        }
        return out
    }

    /// The step shared by both tallies (`100074fc..10007598`, `10027754..100277f8`): bonus ≤ 0 → 0; else f =
    /// (float)bonus × flli 200 (`fmuls`, single); f < (float)int(flli 199) → f = that; step = trunc(f).
    private func tallyStep(_ bonus: Int32) -> Int32 {
        guard bonus > 0 else { return 0 }                                    // 10007500..10007504 / 10027758..1002775c
        var f: Float = Float(bonus) * assets.floats[200]                     // 10007508..10007530 / 10027760..1002778c
        let floor = flliInt(199)                                             // 10007534..10007554 / 10027790..100277b4
        if !(f >= Float(floor)) { f = Float(floor) }                         // 10007558..1000757c (fcmpo; bge)
        return EntityDraw.fctiwz(f)                                          // 10007580..1000758c
    }

    // MARK: - Ground accuracy

    /// `FUN_100072c0 @ 100072c0(now)` — the accuracy tier, on the first level-end tick. State 1, state timer = tick
    /// timer = now; pct = created > 0 ? frsp((double)((float)destroyed / (float)created) × 100.0) (`fdivs`, then the
    /// double `fmul` by `0x100d6364`'s 100.0 and `frsp`) : 0.0; G+0x160 = trunc(pct); g = int(flli 188); pct ≥ 100 →
    /// tier flli 189 and G+0x0b = 1; ≥ 100 − g → 190; ≥ 100 − 2g → 191; ≥ 100 − 3g → 192; ≥ 100 − 4g → 193; else 194
    /// (every compare `fcmpo` + `cror eq,gt,eq` = ≥ on the untruncated float); bonus = int(tier) × G+0x14; step
    /// (`tallyStep`); text = pgsl 11 (`strcpy`); mission flag and payments 0. Alpha is not touched.
    public mutating func accuracyTier(now: Int32) {
        tally.state = 1                                                      // 100072dc..100072e4
        tally.stateTimer = now                                               // 100072e8
        tally.tickTimer = now                                                // 100072ec
        let created = flags.groundCreated, destroyed = flags.groundDestroyed // 100072f0..100072f4
        let pct: Float
        if created > 0 {                                                     // 100072f8..100072fc
            let q: Float = Float(destroyed) / Float(created)                 // 10007300..10007334 (fsubs ×2, fdivs)
            pct = Float(Double(q) * 100.0)                                   // 10007338..1000733c (fmul, frsp)
        } else {
            pct = 0                                                          // 10007344..10007348 (0x100d6354)
        }
        tally.percent = EntityDraw.fctiwz(pct)                               // 1000734c..1000735c
        let g = flliInt(188)                                                 // 10007350..10007378
        let tier: Int
        if Double(pct) >= 100.0 {                                            // 10007368..10007380
            flags.perfectThisLevel = true                                    // 10007384..10007388
            tier = 189                                                       // 1000738c
        } else if pct >= Float(100 &- g) {                                   // 100073ac..100073d4
            tier = 190
        } else if pct >= Float(100 &- (g &<< 1)) {                           // 100073f8..1000741c
            tier = 191
        } else if pct >= Float(100 &- g &* 3) {                              // 10007440..10007464
            tier = 192
        } else if pct >= Float(100 &- (g &<< 2)) {                           // 10007488..100074ac
            tier = 193
        } else {
            tier = 194                                                       // 100074d0
        }
        tally.bonusRemaining = flliInt(tier) &* flags.sector                 // 100074ec..100074f8
        tally.bonusStep = tallyStep(tally.bonusRemaining)                    // 100074fc..10007598
        tally.text = format([.string(11)])                                   // 1000759c..100075b0
        tally.missionBonus = false                                           // 100075bc
        tally.missionPayments = 0                                            // 100075c0
    }

    /// `FUN_100075e0 @ 100075e0(now) -> Bool` — the accuracy tally and mission bonus, one state per tick (the table in
    /// the type comment); true = done.
    public mutating func accuracyTally(now: Int32) -> Bool {
        switch tally.state {                                                 // 10007604..10007620
        case 0:
            return true                                                      // 10007624
        case 1:
            var wait = flliInt(195)                                          // 1000762c..10007648
            if flags.allLevels { wait = flliInt(196) }                       // 1000763c..10007664
            if now > tally.stateTimer &+ wait {                              // 10007668..10007678
                tally.state = 2                                              // 1000767c..10007680
                tally.stateTimer = now                                       // 10007688
                tallySound(20)                                               // 10007684..100076a0
            }
        case 2:
            let n = flliInt(203)                                             // 100076ac..100076c4
            if n > 0 {                                                       // 100076c8..100076d0
                for _ in 0..<n where tally.alpha != 0 { tally.alpha &-= 1 }  // 100076d8..100076ec
            }
            if now > tally.stateTimer &+ flliInt(197) {                      // 100076f0..10007718
                tally.state = 3                                              // 1000771c..10007720
                tally.stateTimer = now                                       // 10007728
                tallySound(20)                                               // 10007724..10007740
                tally.text = format([.string(11), .int(tally.percent), .percent])   // 10007748..10007764
            }
        case 3:
            if now > tally.stateTimer &+ flliInt(197) {                      // 10007770..10007798
                tally.state = 4                                              // 1000779c..100077a0
                tally.stateTimer = now                                       // 100077a8
                tally.text = format([.string(11), .int(tally.percent), .percent, .string(12)])   // 100077a4..100077d8
                tallySound(20)                                               // 100077e0..100077f8
            }
        case 4:
            if now > tally.stateTimer &+ flliInt(197) {                      // 10007804..1000782c
                tally.state = 5                                              // 10007830..10007834
                tally.stateTimer = now                                       // 10007838
                if tally.percent == 100 {                                    // 1000783c..10007844
                    flags.perfectLevels &+= 1                                // 10007848..10007854
                    tallySound(22)                                           // 1000784c..1000786c
                } else if tally.bonusRemaining == 0 {                        // 10007878..10007880
                    tallySound(21)                                           // 10007884..1000789c
                } else {
                    tallySound(20)                                           // 100078a8..100078c0
                }
            }
        case 5:
            let bonus = tally.bonusRemaining                                 // 100078cc..100078d4
            if bonus == 0 {
                tally.text = format([.string(11), .int(tally.percent), .percent, .string(12), .string(13)])   // 100078d8..1000791c
            } else {
                tally.text = format([.string(11), .int(tally.percent), .percent, .string(12), .int(bonus)])   // 10007928..1000795c
            }
            if now > tally.stateTimer &+ flliInt(197) {                      // 10007964..1000798c
                tally.state = 6                                              // 10007990..10007994
                tally.stateTimer = now                                       // 10007998
            }
        case 6:
            guard tally.bonusRemaining > 0 else {                            // 100079a0..100079ac
                tally.state = 7                                              // 10007aa8..10007aac
                tally.stateTimer = now                                       // 10007ab0
                return false
            }
            guard now > tally.tickTimer &+ flliInt(198) else { return false } // 100079b0..100079d8
            tally.tickTimer = now                                            // 100079dc
            tally.bonusRemaining &-= tally.bonusStep                         // 100079e0..100079f0
            if tally.bonusRemaining < 0 { tally.bonusRemaining = 0 }         // 100079f4..10007a04
            for p in 0..<2 { addScore(p, tally.bonusStep) }                  // 10007a08..10007a44 (re-reads +0x5c)
            tallySound(20)                                                   // 10007a48..10007a60
            tally.text = format([.string(11), .int(tally.percent), .percent, .string(12),
                                 .int(tally.bonusRemaining)])                // 10007a68..10007a9c
        case 7:
            if now > tally.stateTimer &+ flliInt(201) {                      // 10007ab8..10007ae0
                tally.state = 8                                              // 10007ae4..10007ae8
                tally.stateTimer = now                                       // 10007aec
            }
        case 8:
            if UInt32(bitPattern: tally.alpha) < 0x20 {                      // 10007af4..10007b00
                tally.alpha &+= flliInt(204)                                 // 10007b04..10007b24
                if UInt32(bitPattern: tally.alpha) > 0x20 { tally.alpha = 0x20 }   // 10007b28..10007b38
            }
            guard now > tally.stateTimer &+ flliInt(202) else { return false } // 10007b3c..10007b64
            guard flags.perfectLevels == Int32(assets.levelOrder.levels.count) else { return true }   // 10007b68..10007b78, 10007bdc
            tally.missionBonus = true                                        // 10007b7c..10007b80
            tally.missionPayments = 0                                        // 10007b84, 10007b8c
            tally.state = 9                                                  // 10007b88, 10007b94
            tally.stateTimer = now                                           // 10007b98
            tally.alpha = 0                                                  // 10007b9c
            tally.text = format([.string(10)])                               // 10007b90..10007bb0
            tallySound(23, priority: 100)                                    // 10007bb8..10007bd0
        case 9:
            if now > tally.stateTimer &+ flliInt(206) {                      // 10007be4..10007c0c
                tally.state = 10                                             // 10007c10..10007c14
                tally.stateTimer = now                                       // 10007c20
                tally.alpha = 0x20                                           // 10007c18, 10007c28
                tally.text = []                                              // 10007c1c..10007c2c ("")
            }
        case 10:
            guard tally.missionBonus else { return true }                    // 10007c38..10007c44, 10007d38
            guard now > tally.stateTimer &+ flliInt(207) else { return false } // 10007c48..10007c70
            tally.missionPayments &+= 1                                      // 10007c74..10007c84
            for p in 0..<2 { addScore(p, flliInt(205), raw: true) }          // 10007c88..10007cd0
            if tally.missionPayments >= flliInt(208) {                       // 10007cd4..10007cf4
                tally.missionBonus = false                                   // 10007cf8..10007cfc
            } else {
                tally.state = 9                                              // 10007d04..10007d08
                tally.stateTimer = now                                       // 10007d14
                tally.alpha = 0                                              // 10007d0c, 10007d18
                tally.text = format([.string(10)])                           // 10007d10..10007d2c
            }
        default:
            break                                                            // 1000760c (> 10 → 0)
        }
        return false
    }

    // MARK: - Coin bonus

    /// `FUN_10027db0(p)` — player p's coin tally has started (`+0xd8 ≠ 0`).
    public func coinTallyStarted(_ i: Int) -> Bool { tally.coin[i].state != 0 }

    /// `FUN_10027670 @ 10027670(p, now, stacked) -> Bool` — the coin-bonus setup. Not in game → false. State 1, state
    /// timer = tick timer = now, text = pgsl 14; coin value = int(flli 170) ≠ 0 ? sector × int(flli 171) : int(flli
    /// 171); money0 = money; bonus = money0 × value; step (`tallyStep`); `active_MoneyCounterSpawn_ID` (plde +0xc4)
    /// unless `none`: the player template (`0x100e91d4`) at (flli 179, flli 180) with +0x14 = the player index
    /// (`+0xcc`); stacked → +0x1f8 = int(flli 181) and y += (float)+0x1f8 (`fadds`). Returns true (the caller's next
    /// `stacked`).
    public mutating func coinTallySetup(_ i: Int, now: Int32, stacked: Bool) -> Bool {
        guard players[i].inGame else { return false }                        // 1002768c..10027698
        tally.coin[i].state = 1                                              // 1002769c..100276a0
        tally.coin[i].stateTimer = now                                       // 100276a8
        tally.coin[i].tickTimer = now                                        // 100276ac
        tally.coin[i].text = format([.string(14)])                           // 100276a4..100276c0
        let base = flliInt(171)                                              // 100276f4..10027730
        tally.coin[i].coinValue = flliInt(170) != 0 ? flags.sector &* base : base   // 100276c8..10027730 (FUN_10005cd0)
        tally.coin[i].moneyAtStart = players[i].money                        // 10027734..10027740
        tally.coin[i].bonusRemaining = tally.coin[i].moneyAtStart &* tally.coin[i].coinValue   // 10027744..10027750
        tally.coin[i].bonusStep = tallyStep(tally.coin[i].bonusRemaining)    // 10027754..100277f8
        let unit = players[i].definition.activeMoneyCounterSpawn             // 100277fc..10027800
        if unit != .none {                                                   // 10027804..1002780c
            var req = SpawnRequest(unit: unit, x: assets.floats[179], y: assets.floats[180])   // 10027810..10027898
            if stacked {                                                     // 10027894..1002789c
                tally.coin[i].textYOffset = flliInt(181)                     // 100278a0..100278c8
                req.y = req.y + Float(tally.coin[i].textYOffset)             // 100278cc..100278e8
            }
            req.player = players[i].index                                    // 100278ec..100278f8
            spawn(req)                                                       // 100278f0..10027900 FUN_10033220(req, 0, 0)
        }
        return true                                                          // 10027908
    }

    /// `FUN_10027930 @ 10027930(p, now) -> Bool` — player p's coin tally, one state per tick (the table in the type
    /// comment); true = done.
    public mutating func coinTally(_ i: Int, now: Int32) -> Bool {
        let wait = flliInt(173)
        switch tally.coin[i].state {                                         // 10027950..1002796c
        case 0:
            return true                                                      // 10027970
        case 1:
            if now > tally.coin[i].stateTimer &+ flliInt(172) {              // 10027978..1002799c
                tally.coin[i].state = 2                                      // 100279a0..100279a4
                tally.coin[i].stateTimer = now                               // 100279ac
                tallySound(20)                                               // 100279a8..100279c4
            }
        case 2:
            let n = flliInt(177)                                             // 100279d0..100279e4
            if n > 0 {                                                       // 100279e8..100279f0
                for _ in 0..<n where tally.coin[i].alpha != 0 { tally.coin[i].alpha &-= 1 }   // 100279f8..10027a0c
            }
            if now > tally.coin[i].stateTimer &+ wait {                      // 10027a10..10027a34
                tally.coin[i].state = 3                                      // 10027a38..10027a3c
                tally.coin[i].stateTimer = now                               // 10027a44
                tallySound(20)                                               // 10027a40..10027a5c
                tally.coin[i].text = format([.string(14), .int(tally.coin[i].moneyAtStart)])   // 10027a64..10027a80
            }
        case 3:
            if now > tally.coin[i].stateTimer &+ wait {                      // 10027a8c..10027ab0
                tally.coin[i].state = 4                                      // 10027ab4..10027ab8
                tally.coin[i].stateTimer = now                               // 10027ac0
                tallySound(20)                                               // 10027abc..10027ad8
                tally.coin[i].text = format([.string(14), .int(tally.coin[i].moneyAtStart), .string(15),
                                             .int(tally.coin[i].coinValue)]) // 10027ae0..10027b14
            }
        case 4:
            if now > tally.coin[i].stateTimer &+ wait {                      // 10027b20..10027b44
                tally.coin[i].state = 5                                      // 10027b48..10027b4c
                tally.coin[i].stateTimer = now                               // 10027b50
                tallySound(tally.coin[i].bonusRemaining > 0 ? 20 : 21)       // 10027b54..10027ba0
                tally.coin[i].text = format([.string(14), .int(tally.coin[i].moneyAtStart), .string(15),
                                             .int(tally.coin[i].coinValue), .string(16),
                                             .int(tally.coin[i].bonusRemaining)])   // 10027ba4..10027bf0
            }
        case 5:
            if now > tally.coin[i].stateTimer &+ wait {                      // 10027bfc..10027c20
                tally.coin[i].state = 6                                      // 10027c24..10027c28
                tally.coin[i].stateTimer = now                               // 10027c2c
            }
        case 6:
            guard tally.coin[i].bonusRemaining > 0 else {                    // 10027c34..10027c3c
                tally.coin[i].state = 7                                      // 10027d20..10027d24
                tally.coin[i].stateTimer = now                               // 10027d28
                return false
            }
            guard now > tally.coin[i].tickTimer &+ flliInt(176) else { return false }   // 10027c40..10027c64
            tally.coin[i].tickTimer = now                                    // 10027c68
            if players[i].inGame { players[i].money &-= 1 }                  // 10027c6c..10027c80 (stored − 1)
            addScore(i, tally.coin[i].bonusStep)                             // 10027c84..10027c90
            tally.coin[i].bonusRemaining &-= tally.coin[i].bonusStep         // 10027c98..10027ca8 (not clamped)
            tallySound(20)                                                   // 10027c9c..10027cc0
            tally.coin[i].text = format([.string(14), .int(tally.coin[i].moneyAtStart), .string(15),
                                         .int(tally.coin[i].coinValue), .string(16),
                                         .int(tally.coin[i].bonusRemaining)])   // 10027cc8..10027d14
        case 7:
            if now > tally.coin[i].stateTimer &+ flliInt(174) {              // 10027d30..10027d54
                tally.coin[i].state = 8                                      // 10027d58..10027d5c
                tally.coin[i].stateTimer = now                               // 10027d60
            }
        case 8:
            if now > tally.coin[i].stateTimer &+ flliInt(175) { return true } // 10027d68..10027d90
        default:
            break                                                            // 10027958 (> 8 → 0)
        }
        return false
    }

    // MARK: - Draw

    /// `FUN_10007d60` — the accuracy tally's text record, or nil when nothing is drawn: state ≠ 0 and alpha < 32
    /// (unsigned) → format 53 (`FUN_1000d130(0x35)`), the text (`strcpy` of G+0x60), BlendAmount (+0x114) = alpha,
    /// +0x10d = 1 (template clip), +0x110 = 0 (queued), +0x10c = 15 (layer); drawn by `FUN_1000d380(rec, 0)`.
    public func tallyTextRequest() -> TextRequest? {
        guard tally.state != 0, UInt32(bitPattern: tally.alpha) < 0x20 else { return nil }   // 10007d78..10007d90
        var t = TextRequest(format: assets.formats[0x35], text: tally.text)  // 10007d94..10007db4
        t.format.blendAmount = tally.alpha                                   // 10007da4..10007db0
        t.keepTemplateClip = true                                            // 10007dbc..10007dc4
        t.drawNow = false                                                    // 10007dc0..10007dcc
        t.layer = 15                                                         // 10007dc8..10007dd8
        return t
    }

    /// `FUN_10007d60` — the world draw's tally text (`FUN_1000d380`: strip, then glyphs).
    public func tallyTextCommands(text layout: TextLayout) -> [DrawCommand] {
        tallyTextRequest().map { layout.draw($0) } ?? []
    }
}
