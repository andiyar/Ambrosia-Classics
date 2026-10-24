import Foundation

/// The status-bar calls as Core makes them (HU; spells-items §6, BC39): `.UpdateStatusBar(p1, p2, p3) @ 100095dc`
/// (M l. 4842–4921) at each named call site, and the direct `.UpdateItemStat()` / `.UpdateTextStats(0)`.
///
/// `.UpdateStatusBar` draws (Render's `StatusBar`) and, between `.UpdateTextStats` and `.UpdateItemStat`, runs the key
/// block on G (`GameGlobals.stepSelection`, M l. 4885–4912) — on **every** call, wherever it is made: the world map's
/// four calls and the mid-frame ones included (BC39). The 12-call repeat counter `*_DAT_1009fd9c` is this struct's.
/// The op is built after the step: `.UpdateHealthMagic` / `.UpdateTextStats` read nothing the step writes.
/// `.UpdateItemStat`'s one G write — slot id 2 with `+8 ≠ 0` becomes 3 (M l. 4748–4750) — is made here when the op
/// reaches it (`StatusBarState.drawsItems`), after the op has copied the inventory as read (its big icon, M l.
/// 4708–4718, is drawn from the slot before the loop stores).
///
/// Not made here (follow-ups, reported): `.UpdateHealthMagic`'s G writes (health / magic clamped to their maxima, the
/// breath to the health, M l. 4409–4415, 4426–4428) and its suffocation tick sound (snd 442 `*_DAT_1009fdb4`, M l.
/// 4489–4493), which plays only when its caches let the health part redraw.
public struct StatusBarCalls: Equatable, Sendable {
    /// `*_DAT_1009fd9c` (a byte): the selection key's repeat counter.
    public var repeatCounter = 0

    public init() {}

    /// The flash counters an op carries (`PlayerState` holds them; row 13 counts them down, M l. 44731–44736).
    public struct Flashes: Equatable, Sendable {
        /// `PTR_DAT_1009fdbc`, `_DAT_1009fdb8`, `PTR_DAT_1009fda8`, `_DAT_1009fda4`, `_DAT_1009fda0`.
        public var health: Int16, magic: Int16, item: Int16, itemSlot: Int16, itemMode: Int16

        public init(health: Int16 = 0, magic: Int16 = 0, item: Int16 = 0, itemSlot: Int16 = 0, itemMode: Int16 = 0) {
            self.health = health
            self.magic = magic
            self.item = item
            self.itemSlot = itemSlot
            self.itemMode = itemMode
        }

        public init(player p: PlayerState) {
            self.init(health: p.countdownFDBC, magic: p.countdownFDB8, item: p.countdownFDA8,
                      itemSlot: p.itemFlashSlot, itemMode: p.itemFlashMode)
        }
    }

    /// Every `.UpdateStatusBar` call site built so far, with the parameters the dump passes.
    public enum Site: Equatable, Sendable {
        /// `.GameLoop` M l. 5216 (0, 0, 0).
        case levelStart
        /// `.GameLoop` M l. 5280 (1, 0, 0).
        case loopIteration
        /// `.CheckGameLoopKeys`, Esc's Cancel after `.PaintFrameWrap(1, 1)` — M l. 3919 (0, 0, 0).
        case escapeCancel
        /// ⌘Q / ⌘W / Esc OK after `.PaintFrameWrap(1, 1)` — M l. 3928, 3986, 4011 (0, 0, 0).
        case confirmOK
        /// ⌘Q / ⌘W Cancel — M l. 4002, 3977 (0, 0, 0).
        case confirmCancel
        /// ⌘P after `.Options` — M l. 3956 (0, 0, 0).
        case optionsClosed
        /// `.ChapterScreen` after its fade-out — M l. 5087 (0, 0, 0).
        case chapterScreen
        /// `.SavePointSave` after `.SaveSG` — M l. 6492 (0, 0, 0).
        case savePointSave
        /// `.ShowWorldMap`: after PICT 129 (M l. 67505), after the first frame (67539), each idle iteration (67579),
        /// all (0, 0, 0); every iteration after the marker (67585) (1, 0, 0).
        case mapEntry, mapFirstFrame, mapIdle, mapIteration
        /// `.MoveSelectedItemToFront` — M l. 39704 (1, 1, 0) (its callers are later tasks').
        case moveSelectedItemToFront

        /// (param_1 ≠ 0, param_2 ≠ 0, param_3 ≠ 0).
        public var parameters: (p1: Bool, p2: Bool, p3: Bool) {
            switch self {
            case .levelStart, .escapeCancel, .confirmOK, .confirmCancel, .optionsClosed, .chapterScreen, .savePointSave,
                 .mapEntry, .mapFirstFrame, .mapIdle:
                return (false, false, false)
            case .loopIteration, .mapIteration:
                return (true, false, false)
            case .moveSelectedItemToFront:
                return (true, true, false)
            }
        }
    }

    /// `.UpdateStatusBar(p1, p2, p3)` at `site`: the key step on G with the live actions 8 (next) / 7 (previous), then
    /// the op (and, when it reaches `.UpdateItemStat`, that routine's G write).
    public mutating func update(_ site: Site, globals g: inout GameGlobals, actions: InputActions,
                                flashes: Flashes = Flashes(), levelName: String) -> DrawOp {
        let p = site.parameters
        let stepped = g.stepSelection(next: actions.contains(.nextItem), previous: actions.contains(.previousItem),
                                      repeat: &repeatCounter)
        var s = Self.state(g, flashes: flashes, levelName: levelName)
        s.call = StatusBarCall(partial: p.p1, forceItems: p.p2, forceBars: p.p3, stepped: stepped)
        if s.drawsItems { Self.itemStatStore(&g) }
        return .statusBar(s)
    }

    /// A direct `.UpdateItemStat()` (`.HandleLineActions` M l. 66311, 66325): the op, then its G write.
    public static func itemStat(globals g: inout GameGlobals, flashes: Flashes = Flashes(),
                                levelName: String) -> DrawOp {
        var s = state(g, flashes: flashes, levelName: levelName)
        s.call = StatusBarCall(itemsOnly: true)
        itemStatStore(&g)
        return .statusBar(s)
    }

    /// A direct `.UpdateTextStats(0)` (`.HandleLineActions` M l. 66284): score, coins and level name, uncached.
    public static func textStats(globals g: GameGlobals, flashes: Flashes = Flashes(), levelName: String) -> DrawOp {
        var s = state(g, flashes: flashes, levelName: levelName)
        s.call = StatusBarCall(textOnly: true)
        return .statusBar(s)
    }

    private static func state(_ g: GameGlobals, flashes f: Flashes, levelName: String) -> StatusBarState {
        var s = g.statusBar(levelName: levelName)
        s.healthFlash = Int(f.health)
        s.magicFlash = Int(f.magic)
        s.itemFlash = Int(f.item)
        s.itemFlashSlot = Int(f.itemSlot)
        s.itemFlashMode = Int(f.itemMode)
        return s
    }

    /// `.UpdateItemStat`'s loop store (M l. 4748–4750): `if (id == 2 && +8 != 0) id = 3`, every slot.
    static func itemStatStore(_ g: inout GameGlobals) {
        for k in g.inventory.indices where g.inventory[k].id == 2 && g.inventory[k].isSpell != 0 {
            g.inventory[k].id = 3
        }
    }
}
