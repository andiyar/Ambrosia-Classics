// EXTRA letters (plan §Task 7b.1; Research note 42), transcribed from `_EXTRA_Change @ 0001a163` and
// `_EXTRA_Reset @ 0001a128`. The blink animation runs in `_Bonus_Process` (`Bonus.swift`). `_EXTRA_Draw`, the
// sounds and the debug message consume no RNG and are not modelled.

extension GameState {
    /// `_EXTRA_Change(letter, bonusSlot) @ 0001a163`: letter 1…5 sets E/X/T/R/A (any other value: a debug message,
    /// nothing set). Then, only when no EXTRA animation is running and all five are set: animate on, timer = frame,
    /// counter 0, all five cleared, `_AddHero(1,1)`; if bonus slot `bonusSlot` is armed its type becomes 14 with icon
    /// set 0x1a / frame 0x15 (cosmetic — the reward already ran); `_AddToScore(10000, 1)`;
    /// `_Balloons_CaptureAllEnemies`.
    mutating func extraChange(letter: Int, bonusSlot: Int) {
        if (1...5).contains(letter) {
            extraLetters[letter - 1] = true
        }
        guard !extraAnimating, extraLetters.allSatisfy({ $0 }) else { return }
        extraAnimating = true
        extraTimer = frame
        extraAnimCounter = 0
        for k in extraLetters.indices { extraLetters[k] = false }
        addHero()
        if bonus[bonusSlot].armed {
            bonus[bonusSlot].type = 0xe
            bonus[bonusSlot].iconSet = 0x1a
            bonus[bonusSlot].iconFrame = 0x15
        }
        addToScore(10000, multiply: true)
        balloonsCaptureAllEnemies()
    }

    /// `_EXTRA_Reset(draw) @ 0001a128`: all five letters cleared (the flag only redraws).
    mutating func extraReset() {
        for k in extraLetters.indices { extraLetters[k] = false }
    }
}
