// The end-of-level time-bonus count-down (plan 2026-10-04 btx-playable C4 item 4, amendment R3; FI §3c), transcribed
// from `_TimeBonus_CountDown @ 00006dcb` and `_Multiplier_Flash @ 00019d23`. The original runs it as one blocking
// call inside `_PlayGame`'s frame (no frames run; `_WaitFor @ 0000c604` busy-waits on TickCount, input ignored); the
// session steps it from `tick(now:)` so the App keeps its run loop. Each `_WaitFor(n)` starts at the tick it is
// reached and ends once `TickCount >= start + n` — exactly the original's test.
//
// Sound sites (slot, priority, delay): `_Multiplier_Flash` 00019d90 (32, 30, 0) after each restore;
// `_TimeBonus_CountDown` 00006e16 (9, 30, 0) after the multiply; 00006e8c (42 if bonus 0 / 41 if ≥ 10001, 30, 0);
// 00006f07 (17, 30, 0) every third chunk.
//
// `_AddToScore` may award a life → `_AddHero`'s two snd 13 cues (C2, `Scoring.swift`) land in the sim's buffer; each
// chunk drains them (`takeSounds`) into its output right after the transfer, before the chunk's snd 17.

/// One `_TimeBonus_CountDown` run, stepped by ticks.
struct TimeBonusCountdown {
    private enum Step {
        /// `_Multiplier_Flash`: `gBonusMultiplier = 1`, `_Multiplier_Draw(1)`.
        case flashOff
        /// `gBonusMultiplier = m`, `_Multiplier_Draw(1)`, snd 32.
        case flashOn(Int16)
        /// bonus ×= mult (cap 99950), snd 9, flash on, `_TimeBonus_Draw(1)`.
        case applyMultiplier
        /// snd 42 when the bonus is 0, snd 41 when it is ≥ 10001 (`< 0x2711` skips).
        case ohSound
        /// `while (0 < _gTimeBonus)`.
        case loopHead
        /// One chunk to the score, snd 17 on every third, `_TimeBonus_Draw(1)`, `_DrawScore(1)`.
        case chunk
        /// `_AdvanceFrameCounter` + `_DrawReserveInfo`.
        case advanceAndReserve
        /// `_DrawReserveInfo`.
        case reserve
        /// `_WaitFor(n)`.
        case wait(Int)
        case done
    }

    private var queue: [Step] = []
    private var deadline: UInt32?
    /// The loop's `sVar2` (snd 17 every third chunk).
    private var chunkCount: Int16 = 0
    private(set) var isDone = false

    /// Starts the count-down for the state as it stands (`_Multiplier_Get()` read now).
    init(state: GameState) {
        let mult = state.multiplier
        if 1 < mult {
            // `_Multiplier_Flash` (it re-tests `!= 1`; always true here): three 8-tick off/on pairs.
            for _ in 0..<3 {
                queue += [.flashOff, .wait(8), .flashOn(mult), .wait(8)]
            }
            queue += [.applyMultiplier, .wait(0x3c)]
        }
        queue += [.ohSound, .loopHead]
    }

    /// Runs every step whose wait has elapsed at `now`; returns what they emitted.
    mutating func run(now: UInt32, state: inout GameState) -> SessionOutput {
        var out = SessionOutput()
        while !isDone {
            if let d = deadline {
                guard now >= d else { break }
                deadline = nil
            }
            guard !queue.isEmpty else { break }
            let step = queue.removeFirst()
            switch step {
            case .flashOff:
                state.setMultiplierForFlash(1)
                out.drawOps += state.multiplierOps()
            case .flashOn(let mult):
                state.setMultiplierForFlash(mult)
                out.drawOps += state.multiplierOps()
                out.sounds.append(SoundCue(slot: 0x20, priority: 0x1e, delayFrames: 0))     // 00019d90
            case .applyMultiplier:
                state.countdownApplyMultiplier()
                out.sounds.append(SoundCue(slot: 9, priority: 0x1e, delayFrames: 0))        // 00006e16
                out.drawOps += state.timeBonusOps()
            case .ohSound:
                if state.timeBonus == 0 {
                    out.sounds.append(SoundCue(slot: 0x2a, priority: 0x1e, delayFrames: 0)) // 00006e8c "Oh No"
                } else if 0x2711 <= state.timeBonus {
                    out.sounds.append(SoundCue(slot: 0x29, priority: 0x1e, delayFrames: 0)) // 00006e8c "Oh My"
                }
            case .loopHead:
                if 0 < state.timeBonus {
                    queue += [.chunk, .wait(1), .advanceAndReserve, .wait(1), .reserve, .wait(1), .reserve, .loopHead]
                } else {
                    queue += [.wait(0xf), .done]
                }
            case .chunk:
                state.countdownTransferChunk()
                out.sounds += state.takeSounds()                                     // _AddToScore → _AddHero
                chunkCount += 1
                if 2 < chunkCount {
                    out.sounds.append(SoundCue(slot: 0x11, priority: 0x1e, delayFrames: 0)) // 00006f07 "Bloop"
                    chunkCount = 0
                }
                out.drawOps += state.timeBonusOps() + state.scoreOps()
            case .advanceAndReserve:
                state.advanceFrameCounter()
                out.drawOps += state.reserveInfoOps()
            case .reserve:
                out.drawOps += state.reserveInfoOps()
            case .wait(let n):
                deadline = now &+ UInt32(n)
            case .done:
                isDone = true
            }
        }
        return out
    }
}
