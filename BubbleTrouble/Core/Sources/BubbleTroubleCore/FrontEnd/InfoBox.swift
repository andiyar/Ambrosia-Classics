// The main menu's info text box (plan 2026-10-04 btx-playable C6; FI §1b), transcribed from `_DrawInterfaceText
// @ 0000898d`, `_Interface_GetOccasions @ 0000c1f6` and `_Interface @ 0000b500`'s refresh. Every message string is
// decoded from the little-endian immediates `_DrawInterfaceText` stores into its stack buffer (closes U3 / Q9 for
// messages 0–33 and the occasions); the registered-only branches are kept (Invariant 5).

/// `_DrawInterfaceText`'s message for `gMsgCounter`, and the `gInfoFlag` toggle message 3 makes.
public struct InfoBox: Equatable, Sendable {
    /// `gTextRect` (`_CreateSpriteGWorld @ 0001eb37`: `SetRect(157, 425, 482, 445)`).
    public static let textRect = QDRect(top: 425, left: 157, bottom: 445, right: 482)
    /// `gSrcTextRect` — the stash in the sprite GWorld: top 0x5c, left 0, right = width, bottom = 0x5c + height.
    public static let srcTextRect = QDRect(top: 0x5c, left: 0, bottom: 0x5c + 20, right: 325)
    /// `ForeColor(local_230)`: 0x111 (cyan) on every registered path; 0x45 (yellow) only for the unregistered nags.
    public static let colour = 0x111
    /// `_Interface`: a message lasts 0xb4 ticks (`gInfoTimer + 0xb4 < TickCount`).
    public static let cycleTicks: UInt32 = 0xb4
    /// The `CFBundleVersion` of the 1.1 UB app (`Info.plist`: "1.1.0"), formatted by `cf_Version__` "Version %@".
    public static let version = "Version 1.1.0"

    /// `RT3_GetDisplayName` (Q15 default: the macOS account's full name) and `RT3_GetLicenseCopies`.
    public var registeredName: String
    public var licenceCopies: Int
    /// `gInfoFlag` (bss, 0 at launch): message 3 on an ordinary day alternates its two texts.
    public var infoFlag = false

    public init(registeredName: String, licenceCopies: Int = 1) {
        self.registeredName = registeredName
        self.licenceCopies = licenceCopies
    }

    /// `_Interface_GetOccasions`: `GetTime` month/day → 1 Dec 24, 2 Dec 25, 5 Dec 31, 3 Jan 20, 6 Jan 1, 4 Sep 17,
    /// 7 Oct 31, else 0.
    public static func occasion(month: Int, day: Int) -> Int {
        switch (month, day) {
        case (12, 24): return 1
        case (12, 25): return 2
        case (12, 31): return 5
        case (1, 20): return 3
        case (1, 1): return 6
        case (9, 17): return 4
        case (10, 31): return 7
        default: return 0
        }
    }

    /// The message `_DrawInterfaceText` draws for `counter` on `occasion` (registered build), toggling `infoFlag`
    /// exactly as message 3 does.
    public mutating func message(_ counter: Int, occasion: Int) -> String {
        switch counter {
        case 0:
            return "Copyright 1995-2008 Alex Metcalf/David Wareing & Ambrosia"
        case 1:
            return Self.version
        case 2:
            // "Registered To:  " + name + "  [" + copies + (" copy]" | " copies]").
            let copies = licenceCopies == 1 ? " copy]" : " copies]"
            return "Registered To:  \(registeredName)  [\(licenceCopies)\(copies)"
        case 3:
            if occasion == 0 {
                if !infoFlag {
                    infoFlag = true
                    return "Thanks for supporting Shareware!"
                }
                infoFlag = false
                return "Visit us at http://www.AmbrosiaSW.com/games/bt/"
            }
            return Self.occasionMessages[occasion] ?? "Thank you for supporting Shareware!"
        default:
            return Self.eggMessages[counter] ?? Self.eggDefault
        }
    }

    /// Message 3 on an occasion (`switch(sVar4)` cases 1…7; `default` "Thank you for supporting Shareware!").
    static let occasionMessages: [Int: String] = [
        1: "Remember to hang up your stocking!",
        2: "Merry Christmas to your family!",
        3: "Happy Birthday David! Woot!",
        4: "Happy Birthday Alex! Woot!",
        5: "Drive safely tonight folks!",
        6: "Happy New Year to you and your family!",
        7: "Trick or Treat?",
    ]

    /// Messages 4…0x21 — the option-click easter eggs (`gMsgCounter = GetRandomFast(3, 0x21)`).
    static let eggMessages: [Int: String] = [
        4: "A man he hears what he wants to hear, and disregards the rest.",
        5: "War is peace. Freedom is slavery. Ignorance is strength.",
        6: "Never send to know for whom the bell tolls; It tolls for thee.",
        7: "Eagles may soar, but weasels don't get sucked into jet engines.",
        8: "The owls are not what they seem.",
        9: "Let's play Global Thermonuclear War.",
        10: "Coming next version... Harry Potter playing squidditch.",
        11: "Scientology, n. Religious system. (see: Scam, Mind Control)",
        12: "Patriot, n. The dupe of statesmen and the tool of conquerors.",
        13: "Philosophy, n. Route of many roads leading from nowhere to nothing.",
        14: "Positive, adj. Mistaken at the top of one's voice.",
        15: "Reverence, n. Spiritual attitude of a man to god and a dog to man.",
        16: "Saint, n. A dead sinner revised and edited.",
        17: "You're high maintenance masquerading as low maintenance.",
        18: "Do you ever have deja vu Mrs Lancaster?",
        19: "Two pieces of string: 'Feeling okay?' 'No, I'm a frayed knot.'",
        20: "I don't care what you smell, get in there!",
        21: "Ned the head, did the whistling bellybutton trick? Bing!",
        22: "One. How many psychics does it take to change a light bulb?",
        23: "Here's looking at you, squid.",
        24: "How long have you been looking at these messages? Have a game!",
        25: "There may be bubbles ahead... but while there's music...",
        26: "When you fish upon a star...",
        27: "All your fish are belong to us.",
        28: "Play it again, Salmon.",
        29: "You'll be playing another game in the Blinky of an eye",
        30: "Have you option clicked the title above? command? control? shift?",
        31: "You've lost that loving eeling...",
        32: "There's no plaice like home, there's no plaice like home...",
        33: "Pleased to meet you, hope you guess my name.",
    ]
    /// The switch's `default` (unreachable from the game's draws).
    static let eggDefault = "What's the fun in programming unless you get the occasional bug?"
}
