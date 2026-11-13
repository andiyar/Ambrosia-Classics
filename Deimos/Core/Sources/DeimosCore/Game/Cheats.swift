import Foundation

/// The handlers of the ten registered console commands (messages-notices-console §5.2–§5.4, HIGH): `FPS`,
/// `VERSION`/`VERS`, the cheat word and the six cheats. The replica is the registered game (§6: `Please Register
/// Deimos Rising!` is not carried), so the registration flag −0x6234 is always set.
///
/// Listing reads for plan C19 (`disasm-review3-all.txt`; texts from the data image at r2 − 0x2634 + offset):
/// - FPS `0x10007eb0` (`10007ebc..10007f30`): byte pref 9 = !pref 9, then `Frame Rate Monitor Enabled` (+0x455) /
///   `…Disabled` (+0x470) by the new value, type 0; returns 1.
/// - VERSION `0x10008660` (`1000866c..100086a4`): `"Version: %s, %s, %s"` (+0x584) of `1.0.6` (+0x598), `Jan  2 2004`
///   (+0x59e), `11:55:08` (+0x5aa), type 0; returns 1.
/// - cheat word `0x10008990` (`1000899c..100089dc`): byte pref 11 = 1, `Cheat Codes Allowed` (+0x64f), type 0;
///   returns 1.
/// - the six cheats (`100089f0..10009228`), each returning 1 (no result sound — registered with r6 = 0): FUNDS tests
///   the film flag first, the others registration first; film (`G+0x20 == 1`) → `Not During a Film, Buddy!`
///   (+0x663, type 1); byte pref 11 == 0 → nothing. Then:
///   - LIFE (`10008a64..10008b48`): counter G+0x16c < 1 → += 1; for P1, P2: `FUN_10026c60(p, 4)` →
///     `FUN_10026d70(p, 0)`, `FUN_10029bf0(p, 1)`; if any → `Extra Life Awarded!` (+0x67d, type 0) + gaso 22.
///     Else `Tut tut!  What a greedy piggy!` (+0x691, type 1) + gaso 5.
///   - ACCURACY (`10008bec..10008c6c`): G+0x3c = G+0x40 = 100, `Ground Accuracy 100%` (+0x6b0) + gaso 22, then each
///     active player cheated. No counter.
///   - FUNDS (`10008cfc..10008dcc`): G+0x170 < 3 → += 1, `Money Money Money!` (+0x6c5) + gaso 22, active players:
///     `FUN_100275b0(p, 20)` + cheated. Else `Money Can't Buy You Love (Just a Porsche!)` (+0x6d8) + gaso 5.
///   - SCORE (`10008e5c..10008f30`): G+0x174 < 2 → `Points Points Points!` (+0x703), `FUN_10029a10(p, 10000, 0)`.
///     Else `I Think Not, Young Kitty!` (+0x719).
///   - SHIELDS (`10008fd4..100090a4`): G+0x178 < 1 → `Maximum Shields!` (+0x733), `FUN_10027490(p, 100.0)` (float
///     `0x100d6360` = `42c80000`). Else `Use The Force, Luke!` (+0x744).
///   - MULT (`1000913c..10009208`): G+0x17c < 1 → `Bonus Multiplier!` (+0x759), `FUN_10029b20(p)`. Else `Play
///     Bubble Trouble!` (+0x76b).
///   Every sound is `FUN_10047670(gaso n, 0x32, 100, 1)`; the counters' compares are signed (`cmpwi; bge`).
extension GameState {
    /// The command's handler; the result is the handler's return byte (`FUN_1002d770` picks gaso 4 / 5 by it).
    mutating func consoleCommand(_ h: Console.Handler) -> Bool {
        switch h {
        case .fps:
            prefs.bytePrefs[9] = prefs.bytePrefs[9] == 0 ? 1 : 0             // 10007ebc..10007ee0 (cntlzw)
            messages.post(text: prefs.bytePrefs[9] != 0 ? "Frame Rate Monitor Enabled" : "Frame Rate Monitor Disabled",
                          kind: .normal)                                     // 10007ee8..10007f28
        case .version:
            messages.post(text: "Version: 1.0.6, Jan  2 2004, 11:55:08", kind: .normal)   // 1000866c..1000869c
        case .cheatWord:
            prefs.bytePrefs[11] = 1                                          // 100089a8..100089b0
            messages.post(text: "Cheat Codes Allowed", kind: .normal)        // 100089b8..100089cc
        case .life:
            guard cheatGate() else { break }
            guard flags.cheatLife < 1 else { cheatRefused("Tut tut!  What a greedy piggy!"); break }
            flags.cheatLife &+= 1                                            // 10008a74..10008a78
            var any = false
            for p in 0..<2 where players[p].lifeState == 4 {                 // 10008a88..10008ad0
                addLife(p, showEffects: false)                               // 10008aa0..10008aa8
                players[p].cheated = true                                    // 10008ab0..10008ab8
                any = true
            }
            if any { cheatGranted("Extra Life Awarded!") }                   // 10008ad4..10008b0c
        case .accuracy:
            guard cheatGate() else { break }
            flags.groundCreated = 100                                        // 10008bec..10008bf0
            flags.groundDestroyed = 100                                      // 10008bfc
            cheatGranted("Ground Accuracy 100%")                             // 10008bf4..10008c28
            for p in 0..<2 where players[p].lifeState == 4 { players[p].cheated = true }   // 10008c38..10008c6c
        case .funds:
            guard cheatGate() else { break }
            guard flags.cheatFunds < 3 else { cheatRefused("Money Can't Buy You Love (Just a Porsche!)"); break }
            flags.cheatFunds &+= 1                                           // 10008d0c..10008d10
            cheatGranted("Money Money Money!")                               // 10008d14..10008d44
            for p in 0..<2 where players[p].lifeState == 4 {                 // 10008d50..10008d94
                addMoney(p, 20)                                              // 10008d68..10008d70
                players[p].cheated = true
            }
        case .score:
            guard cheatGate() else { break }
            guard flags.cheatScore < 2 else { cheatRefused("I Think Not, Young Kitty!"); break }
            flags.cheatScore &+= 1                                           // 10008e6c..10008e70
            cheatGranted("Points Points Points!")                            // 10008e74..10008ea4
            for p in 0..<2 where players[p].lifeState == 4 {                 // 10008eb0..10008ef8
                addScore(p, 10_000)                                          // 10008ec8..10008ed4 (raw 0)
                players[p].cheated = true
            }
        case .shields:
            guard cheatGate() else { break }
            guard flags.cheatShields < 1 else { cheatRefused("Use The Force, Luke!"); break }
            flags.cheatShields &+= 1                                         // 10008fe4..10008fe8
            cheatGranted("Maximum Shields!")                                 // 10008fec..1000901c
            for p in 0..<2 where players[p].lifeState == 4 {                 // 10009028..1000906c
                addShield(p, 100.0)                                          // 10009040..10009048
                players[p].cheated = true
            }
        case .mult:
            guard cheatGate() else { break }
            guard flags.cheatMult < 1 else { cheatRefused("Play Bubble Trouble!"); break }
            flags.cheatMult &+= 1                                            // 1000914c..10009150
            cheatGranted("Bonus Multiplier!")                                // 10009154..10009184
            for p in 0..<2 where players[p].lifeState == 4 {                 // 10009190..100091d0
                stepMultiplier(p)                                            // 100091a8..100091ac
                players[p].cheated = true
            }
        }
        return true                                                          // every handler: li r3,0x1
    }

    /// The common gate: (registered — always) film → the refusal text (type 1, no sound); byte pref 11 off →
    /// silently nothing. The order of the registration and film tests differs only for FUNDS and is invisible here.
    private mutating func cheatGate() -> Bool {
        if flags.filmPlaying {
            messages.post(text: "Not During a Film, Buddy!", kind: .error)
            return false
        }
        return prefs.bytePrefs[11] != 0
    }

    /// Success: the text (type 0), then gaso 22 `acbo`.
    private mutating func cheatGranted(_ text: String) {
        messages.post(text: text, kind: .normal)
        cues.sounds.append(SoundPlay.perm(assets.sounds[22], priority: 0x32, volume: 100, allowMultiple: true))
    }

    /// Refusal: the text (type 1), then gaso 5 `lsna`.
    private mutating func cheatRefused(_ text: String) {
        messages.post(text: text, kind: .error)
        cues.sounds.append(SoundPlay.perm(assets.sounds[5], priority: 0x32, volume: 100, allowMultiple: true))
    }
}
