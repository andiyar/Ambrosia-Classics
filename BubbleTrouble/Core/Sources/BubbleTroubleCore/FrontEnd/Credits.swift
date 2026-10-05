// The credits (plan 2026-10-04 btx-playable C7; FI §3a), transcribed from `_DisplayCredits @ 0002145a` and
// `_DrawCredit @ 0001eee4`; `_CreditsButton @ 0000ae16` (the modifier → secret set → sound, the return to the menu) is
// C6's `FrontEnd.creditsButtonSteps`.

/// `_DrawCredit`'s 34 pages, verbatim: every string, position, highlight and picture (the original's spellings kept).
enum Credits {
    /// One `_DrawCredit` call site, in call order.
    enum Item: Equatable, Sendable {
        /// `_DrawCustomString(text, h, v, highlighted, 0)` — the Letters font; `h` −1 = centred on 640.
        case line(String, h: Int, v: Int, highlighted: Bool)
        /// `_DrawPictInRect(id, r)` — PICT `id` into comp.
        case pict(Int, QDRect)
        /// `_DrawSecretPictInRect(id, r)` — resource `IMAG` `id` into comp.
        case imag(Int, QDRect)
    }

    /// `_DisplayCredits(secret)`: the first and last page of each set — 0 = the credits proper, 1 (control) the
    /// reading list, 2 (option) viewing / listening, 3 (⌘) the serious pages, 4 (shift) the personal ones.
    static func pageRange(secret: Int) -> ClosedRange<Int> {
        switch secret {
        case 1: 0xe...0x16
        case 2: 0x17...0x1a
        case 3: 0x1b...0x1d
        case 4: 0x1e...0x21
        default: 0...0xd            // 0; any other value `_CleanUp`s in the original (never passed)
        }
    }

    /// `TickCount() > pageStart + 0xf0` → the next page.
    static let pageTicks: UInt32 = 0xf0
    /// `_DrawCredit` ends with `_SetToScreen(); _WipeScreen(8)` (disasm 00021447).
    static let wipeStep = 8

    /// `_DrawCredit(page)`: `_PatternFillCompGWorld(0x390)` (PICT 912 centred into comp), the page's items into comp,
    /// `_WipeScreen(8)`.
    static func drawOps(page: Int, backdrop: QDRect) -> [DrawOp] {
        var ops: [DrawOp] = [.pict(id: MainMenu.compPatternPict, dst: backdrop, target: .comp)]
        for item in pages[page] {
            switch item {
            case let .line(text, h, v, hi):
                ops.append(.string(text: text, h: h, v: v, highlighted: hi, fixedPitch: nil, target: .comp))
            case let .pict(id, r):
                ops.append(.pict(id: id, dst: r, target: .comp))
            case let .imag(id, r):
                ops.append(.imag(id: id, dst: r, target: .comp))
            }
        }
        return ops + [.wipe(step: wipeStep)]
    }

    static let pages: [[Item]] = [
        // 0
        [
            .line("Coding + Design Maestros", h: -1, v: 200, highlighted: true),
            .line("Alex Metcalf", h: -1, v: 230, highlighted: false),
            .line("David Wareing", h: -1, v: 260, highlighted: false),
        ],
        // 1
        [
            .line("Title + Background Artwork", h: -1, v: 215, highlighted: true),
            .line("Marcus Conge", h: -1, v: 245, highlighted: false),
        ],
        // 2
        [
            .line("Sprite Artwork", h: -1, v: 155, highlighted: true),
            .line("Marcus Conge", h: -1, v: 185, highlighted: false),
            .line("Additional Sprite Artwork", h: -1, v: 245, highlighted: true),
            .line("David Wareing", h: -1, v: 275, highlighted: false),
            .line("Alex Metcalf", h: -1, v: 305, highlighted: false),
        ],
        // 3
        [
            .line("OS X Transmogrifying", h: -1, v: 125, highlighted: true),
            .line("Alex Metcalf", h: -1, v: 155, highlighted: false),
            .line("David Wareing", h: -1, v: 185, highlighted: false),
            .line("Special Thanks", h: -1, v: 245, highlighted: true),
            .line("Sheryn Wareing", h: -1, v: 275, highlighted: false),
            .line("Thomas Metcalf", h: -1, v: 305, highlighted: false),
            .line("Luke Slot", h: -1, v: 335, highlighted: false),
        ],
        // 4
        [
            .line("Ambrosia Software Crew", h: -1, v: 140, highlighted: true),
            .line("Andrew Welch - El Presidente", h: -1, v: 170, highlighted: false),
            .line("David Dunham - Technical Support", h: -1, v: 200, highlighted: false),
            .line("Matt Slot - Bitwise Operator", h: -1, v: 230, highlighted: false),
            .line("David Cockhern - Money Man", h: -1, v: 260, highlighted: false),
            .line("Aaron Hunt - Operations", h: -1, v: 290, highlighted: false),
            .line("Ed Ota - Operations", h: -1, v: 320, highlighted: false),
        ],
        // 5
        [
            .line("Musicians", h: -1, v: 200, highlighted: true),
            .line("Matt Swoboda", h: -1, v: 230, highlighted: false),
            .line("Yannis Brown", h: -1, v: 260, highlighted: false),
        ],
        // 6
        [
            .line("Sound FX", h: -1, v: 170, highlighted: true),
            .line("Alex Metcalf", h: -1, v: 200, highlighted: false),
            .line("Ambrosia Labs", h: -1, v: 230, highlighted: false),
            .line("David Wareing", h: -1, v: 260, highlighted: false),
            .line("Matt Lee", h: -1, v: 290, highlighted: false),
        ],
        // 7
        [
            .line("Ambrosia Software Tools", h: -1, v: 95, highlighted: true),
            .line("Ambrosia Sound Tool", h: -1, v: 125, highlighted: false),
            .line("Ambrosia Registration Tool", h: -1, v: 155, highlighted: false),
            .line("Universal Binary", h: -1, v: 215, highlighted: true),
            .line("Kent Sutherland", h: -1, v: 245, highlighted: false),
            .line("OS X Icon Artistry", h: -1, v: 305, highlighted: true),
            .line("Marcus Conge", h: -1, v: 335, highlighted: false),
            .line("Markus Magnuson", h: -1, v: 365, highlighted: false),
        ],
        // 8
        [
            .line("OS X Testing Team", h: -1, v: 50, highlighted: true),
            .line("Fiyin 'Khaotic' Adewale", h: -1, v: 80, highlighted: false),
            .line("Matthew 'Anklebiter' Beedle", h: -1, v: 110, highlighted: false),
            .line("Patrick Bernardi", h: -1, v: 140, highlighted: false),
            .line("Light Blashpemy", h: -1, v: 170, highlighted: false),
            .line("Dominic 'Eytee' Dagradi", h: -1, v: 200, highlighted: false),
            .line("Roseann Devlin", h: -1, v: 230, highlighted: false),
            .line("Liam Doughty", h: -1, v: 260, highlighted: false),
            .line("Alex 'ARGH' Eiser", h: -1, v: 290, highlighted: false),
            .line("Jon Forst", h: -1, v: 320, highlighted: false),
            .line("Tim 'Musapi' Frede", h: -1, v: 350, highlighted: false),
            .line("David Evan Isom", h: -1, v: 380, highlighted: false),
            .line("Jan 'janski' Van Tol", h: -1, v: 410, highlighted: false),
        ],
        // 9
        [
            .line("OS X Testing Team", h: -1, v: 50, highlighted: true),
            .line("Ryan Junk", h: -1, v: 80, highlighted: false),
            .line("Matt 'Zebe' Lee", h: -1, v: 110, highlighted: false),
            .line("Markus 'superqult' Magnuson", h: -1, v: 140, highlighted: false),
            .line("Patrik Montgomery", h: -1, v: 170, highlighted: false),
            .line("Adam 'Juneappal' Price", h: -1, v: 200, highlighted: false),
            .line("Nick Robbins", h: -1, v: 230, highlighted: false),
            .line("Kyle 'niles' Rove", h: -1, v: 260, highlighted: false),
            .line("Luke Slot", h: -1, v: 290, highlighted: false),
            .line("Jeremy Sobczak", h: -1, v: 320, highlighted: false),
            .line("Adam 'Cyrus' Smith", h: -1, v: 350, highlighted: false),
            .line("Neal Staley", h: -1, v: 380, highlighted: false),
            .line("Benjamin 'Andiyar' Thomas", h: -1, v: 410, highlighted: false),
        ],
        // 10
        [
            .line("Original Testing Team", h: -1, v: 65, highlighted: true),
            .line("David Sie", h: -1, v: 95, highlighted: false),
            .line("Scott Lemon", h: -1, v: 125, highlighted: false),
            .line("Joshua Bruce", h: -1, v: 155, highlighted: false),
            .line("Justin Anderson", h: -1, v: 185, highlighted: false),
            .line("Michael Artz", h: -1, v: 215, highlighted: false),
            .line("David Bahr", h: -1, v: 245, highlighted: false),
            .line("Josh Barnes", h: -1, v: 275, highlighted: false),
            .line("Kenneth M. Berger", h: -1, v: 305, highlighted: false),
            .line("Mike Betzel", h: -1, v: 335, highlighted: false),
            .line("Erin Brown", h: -1, v: 365, highlighted: false),
            .line("Bryan Chan", h: -1, v: 395, highlighted: false),
        ],
        // 11
        [
            .line("Original Testing Team", h: -1, v: 65, highlighted: true),
            .line("James A. Collins", h: -1, v: 95, highlighted: false),
            .line("Jeremy Condit", h: -1, v: 125, highlighted: false),
            .line("Rose 'BamBam' Cooper", h: -1, v: 155, highlighted: false),
            .line("Jabob Cusack", h: -1, v: 185, highlighted: false),
            .line("Steffan Davies", h: -1, v: 215, highlighted: false),
            .line("Liam Doughty", h: -1, v: 245, highlighted: false),
            .line("Ken Dye", h: -1, v: 275, highlighted: false),
            .line("Andrew Feigenson", h: -1, v: 305, highlighted: false),
            .line("Pat Gardella", h: -1, v: 335, highlighted: false),
            .line("Ken Gerrard", h: -1, v: 365, highlighted: false),
            .line("Robert Goree", h: -1, v: 395, highlighted: false),
        ],
        // 12
        [
            .line("Original Testing Team", h: -1, v: 65, highlighted: true),
            .line("Kevin Griffiths", h: -1, v: 95, highlighted: false),
            .line("Sion Harris", h: -1, v: 125, highlighted: false),
            .line("Steffan Harris", h: -1, v: 155, highlighted: false),
            .line("Mark Headley", h: -1, v: 185, highlighted: false),
            .line("John Heitmann", h: -1, v: 215, highlighted: false),
            .line("Ryan Junk", h: -1, v: 245, highlighted: false),
            .line("Tony Kiefer", h: -1, v: 275, highlighted: false),
            .line("Matt Lee", h: -1, v: 305, highlighted: false),
            .line("Chris Littman", h: -1, v: 335, highlighted: false),
            .line("Barry Maggert", h: -1, v: 365, highlighted: false),
            .line("Steven Marcotte", h: -1, v: 395, highlighted: false),
        ],
        // 13
        [
            .line("Original Testing Team", h: -1, v: 65, highlighted: true),
            .line("Duncan McQueen", h: -1, v: 95, highlighted: false),
            .line("Ryan Moser", h: -1, v: 125, highlighted: false),
            .line("Etienne Pelaprat", h: -1, v: 155, highlighted: false),
            .line("Dan Pride", h: -1, v: 185, highlighted: false),
            .line("Jake Rodkin", h: -1, v: 215, highlighted: false),
            .line("David Rugge", h: -1, v: 245, highlighted: false),
            .line("Steve Sabol", h: -1, v: 275, highlighted: false),
            .line("Bruce E. Strange", h: -1, v: 305, highlighted: false),
            .line("Ken Taylor", h: -1, v: 335, highlighted: false),
            .line("Michael Thyen", h: -1, v: 365, highlighted: false),
            .line("The Students of Mr. Morley's Computer Lab", h: -1, v: 395, highlighted: false),
        ],
        // 14
        [
            .line("Recommended Reading Follows...", h: -1, v: 215, highlighted: true),
        ],
        // 15
        [
            .line("The Selfish Gene", h: -1, v: 215, highlighted: true),
            .line("Richard Dawkins", h: -1, v: 245, highlighted: false),
        ],
        // 16
        [
            .line("Hannibal", h: -1, v: 215, highlighted: true),
            .line("Thomas Harris", h: -1, v: 245, highlighted: false),
        ],
        // 17
        [
            .line("The Forge of God", h: -1, v: 215, highlighted: true),
            .line("Greg Bear", h: -1, v: 245, highlighted: false),
        ],
        // 18
        [
            .line("Fear and Loathing in Las Vegas", h: -1, v: 215, highlighted: true),
            .line("Hunter S. Thompson", h: -1, v: 245, highlighted: false),
        ],
        // 19
        [
            .line("Brave New World", h: -1, v: 215, highlighted: true),
            .line("Aldous Huxley", h: -1, v: 245, highlighted: false),
        ],
        // 20
        [
            .line("The Kraken Wakes", h: -1, v: 215, highlighted: true),
            .line("John Wyndham", h: -1, v: 245, highlighted: false),
        ],
        // 21
        [
            .line("All The Trouble in the World", h: -1, v: 215, highlighted: true),
            .line("P.J. O'Rourke", h: -1, v: 245, highlighted: false),
        ],
        // 22
        [
            .line("The Tao Of Pooh", h: -1, v: 215, highlighted: true),
            .line("Benjamin Hoff", h: -1, v: 245, highlighted: false),
        ],
        // 23
        [
            .line("David's Recommended Viewing", h: -1, v: 125, highlighted: true),
            .line("12 Monkeys", h: -1, v: 155, highlighted: false),
            .line("The Usual Suspects", h: -1, v: 185, highlighted: false),
            .line("Lost Highway", h: -1, v: 215, highlighted: false),
            .line("The Big Lebowski", h: -1, v: 245, highlighted: false),
            .line("Mars Attacks!", h: -1, v: 275, highlighted: false),
            .line("The Life of Brian", h: -1, v: 305, highlighted: false),
            .line("Forbidden Planet", h: -1, v: 335, highlighted: false),
        ],
        // 24
        [
            .line("Alex's Recommended Viewing", h: -1, v: 125, highlighted: true),
            .line("Some Like It Hot", h: -1, v: 155, highlighted: false),
            .line("When Harry Met Sally", h: -1, v: 185, highlighted: false),
            .line("2001", h: -1, v: 215, highlighted: false),
            .line("The Empire Strikes Back", h: -1, v: 245, highlighted: false),
            .line("The Naked Gun", h: -1, v: 275, highlighted: false),
            .line("Groundhog Day", h: -1, v: 305, highlighted: false),
            .line("Ocean's Eleven", h: -1, v: 335, highlighted: false),
        ],
        // 25
        [
            .line("David's Recommended Listening", h: -1, v: 125, highlighted: true),
            .line("Roxy Music", h: -1, v: 155, highlighted: false),
            .line("Neil Young", h: -1, v: 185, highlighted: false),
            .line("Bob Dylan", h: -1, v: 215, highlighted: false),
            .line("Pulp", h: -1, v: 245, highlighted: false),
            .line("Leonard Cohen", h: -1, v: 275, highlighted: false),
            .line("Lloyd Cole", h: -1, v: 305, highlighted: false),
            .line("Blondie", h: -1, v: 335, highlighted: false),
        ],
        // 26
        [
            .line("Alex's Recommended Listening", h: -1, v: 125, highlighted: true),
            .line("Muse", h: -1, v: 155, highlighted: false),
            .line("Red Hot Chili Peppers", h: -1, v: 185, highlighted: false),
            .line("Radiohead", h: -1, v: 215, highlighted: false),
            .line("Nina Simone", h: -1, v: 245, highlighted: false),
            .line("Barenaked Ladies", h: -1, v: 275, highlighted: false),
            .line("Propellerheads", h: -1, v: 305, highlighted: false),
            .line("The Police", h: -1, v: 335, highlighted: false),
        ],
        // 27
        [
            .line("Some Human Rights Abusers", h: -1, v: 125, highlighted: true),
            .line("China", h: -1, v: 155, highlighted: false),
            .line("Indonesia", h: -1, v: 185, highlighted: false),
            .line("Saudi Arabia", h: -1, v: 215, highlighted: false),
            .line("Iraq", h: -1, v: 245, highlighted: false),
            .line("Syria", h: -1, v: 275, highlighted: false),
            .line("North Korea", h: -1, v: 305, highlighted: false),
            .line("Burma", h: -1, v: 335, highlighted: false),
        ],
        // 28
        [
            .line("Some Things To Do On A Rainy Day or Night", h: -1, v: 125, highlighted: true),
            .line("Visit your local library.", h: -1, v: 155, highlighted: false),
            .line("Do some drawing.", h: -1, v: 185, highlighted: false),
            .line("Avoid joining Scientology.", h: -1, v: 215, highlighted: false),
            .line("Spend some quality time with your cat.", h: -1, v: 245, highlighted: false),
            .line("Read 'Cosmos' by Carl Sagan.", h: -1, v: 275, highlighted: false),
            .line("Play chess with a friend.", h: -1, v: 305, highlighted: false),
            .line("Gaze at the stars and ponder...", h: -1, v: 335, highlighted: false),
        ],
        // 29
        [
            .line("In memorium", h: -1, v: 112, highlighted: true),
            .line("Carl Sagan,  1934 - 1996", h: -1, v: 343, highlighted: true),
            .imag(128, QDRect(top: 166, left: 227, bottom: 313, right: 412)),
        ],
        // 30
        [
            .line("Alex's favourite things in life", h: -1, v: 125, highlighted: true),
            .line("Alto saxophone", h: -1, v: 155, highlighted: false),
            .line("Evenings out with friends", h: -1, v: 185, highlighted: false),
            .line("Skiing", h: -1, v: 215, highlighted: false),
            .line("Cheers (US TV)", h: -1, v: 245, highlighted: false),
            .line("Juggling", h: -1, v: 275, highlighted: false),
            .line("An alcoholic beverage", h: -1, v: 305, highlighted: false),
            .line("Marmite", h: -1, v: 335, highlighted: false),
        ],
        // 31
        [
            .line("Alex's reasons for you to pay shareware fee", h: 40, v: 125, highlighted: true),
            .line("1. You'll sleep better.", h: 40, v: 155, highlighted: false),
            .line("2. The development tools cost 400 pounds.", h: 40, v: 185, highlighted: false),
            .line("3. I can start saving up to ski this winter.", h: 40, v: 215, highlighted: false),
            .line("4. I'm still paying off student loans.", h: 40, v: 245, highlighted: false),
            .line("5. I'd like to fly and meet David again.", h: 40, v: 275, highlighted: false),
            .line("6. Bubble Trouble 2 needs funding?", h: 40, v: 305, highlighted: false),
            .line("7. Beer is expensive.", h: 40, v: 335, highlighted: false),
        ],
        // 32
        [
            .line("Some truly great people", h: -1, v: 110, highlighted: true),
            .line("Gary Larson (great cartoonist)", h: -1, v: 140, highlighted: false),
            .line("Orson Welles (great director)", h: -1, v: 170, highlighted: false),
            .line("Kevin Kline (great actor)", h: -1, v: 200, highlighted: false),
            .line("George Orwell (great writer)", h: -1, v: 230, highlighted: false),
            .line("Paul Davison (great teacher)", h: -1, v: 260, highlighted: false),
            .line("Tony Stott (great friend)", h: -1, v: 290, highlighted: false),
            .line("Mum, Dad, Harriet, Thomas (great family)", h: -1, v: 320, highlighted: false),
            .line("Registered Users (grate-ful)", h: -1, v: 350, highlighted: false),
        ],
        // 33
        [
            .line("Have you seen these (young looking) men?", h: -1, v: 90, highlighted: true),
            .line("Alex Metcalf", h: 95, v: 318, highlighted: true),
            .line("David Wareing", h: 390, v: 318, highlighted: true),
            .line("Responsible for crimes", h: -1, v: 370, highlighted: false),
            .line("against productivity", h: -1, v: 400, highlighted: false),
            .pict(29402, QDRect(top: 129, left: 100, bottom: 301, right: 248)),
            .pict(29401, QDRect(top: 129, left: 400, bottom: 301, right: 548)),
        ],
    ]
}

/// `_DisplayCredits(secret) @ 0002145a`: `pageStart = TickCount()`, the first page (with its wipe), `FlushEvents(0x3e)`;
/// then each pass: when `TickCount() > pageStart + 240` the next page (past the last → back, no sound) with its wipe
/// and `pageStart = TickCount()` after it; one `WaitNextEvent(0x800a)`: a key → snd 17, N / n → new game, else back;
/// a click → snd 17, back; suspend → `_SuspendGame`; resume → `_ResumeGame` and `pageStart = TickCount() − 240` (the
/// next page at the next tick). Only the first page's wipe is followed by a flush: input during later wipes stays
/// queued.
final class CreditsScreen: ScriptedScreen {
    private let range: ClosedRange<Int>
    private var page: Int
    private var pageStart: UInt32 = 0

    init(frontEnd: FrontEnd, secret: Int) {
        range = Credits.pageRange(secret: secret)
        page = range.lowerBound
        super.init(frontEnd: frontEnd)
        steps = [.run { [unowned self] in
                    pageStart = now
                    return SessionOutput(drawOps: pageOps())
                 },
                 .advances(DrawOp.wipeSteps(Credits.wipeStep)),
                 .run { [unowned self] in flushEvents(); return SessionOutput() },
                 .loop { [unowned self] _, out in pass(out: &out) }]
    }

    private func pageOps() -> [DrawOp] {
        Credits.drawOps(page: page, backdrop: frontEnd.menu.compPatternRect)
    }

    private func pass(out: inout SessionOutput) -> Bool {
        if pageStart &+ Credits.pageTicks < now {
            page += 1
            if page > range.upperBound {
                finish(.finished)
                return true
            }
            push([.run { [unowned self] in
                     SessionOutput(drawOps: pageOps())
                  },
                  .advances(DrawOp.wipeSteps(Credits.wipeStep)),
                  .run { [unowned self] in pageStart = now; return SessionOutput() }])     // then this pass's event
            return false
        }
        out.append(eventPass())
        return result != nil
    }

    private func eventPass() -> SessionOutput {
        var out = SessionOutput()
        guard !events.isEmpty else { return out }
        handleLeavingEvent(events.removeFirst(), out: &out) { [unowned self] in pageStart = now &- Credits.pageTicks }
        return out
    }
}
