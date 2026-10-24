import Foundation

/// The status bar's globals and its calls as Core makes them (HU; spells-items §6, BC39): `.UpdateStatusBar(p1, p2,
/// p3) @ 100095dc` (M l. 4842–4921) at each named call site, and the direct `.UpdateItemStat()` / `.UpdateTextStats(0)`.
///
/// **One instance for the whole flow** (HU review fix): the selection key's repeat counter `*_DAT_1009fd9c`,
/// `.UpdateHealthMagic`'s caches `_DAT_100ab9c8 / 9cc / 9d4 / 9d0` and the flash counters are globals no routine
/// re-initialises (only the data section, all 0: no store to any of them outside the routines below, the row-13
/// countdowns M l. 44728–44736 and the flash setters) — so the map, every level, the chapter card and the save point
/// share them: `LevelCarry.statusBar` carries them (the flow hands them to `WorldMapRun` and back), a session holds
/// them as `SpriteWorld.statusBar`.
///
/// `.UpdateStatusBar` in call order: the whole-port copy (param_1 0); `.UpdateHealthMagic(param_3 ? 1 : param_1)` —
/// its G writes, cache tests and suffocation tick are Core's (`healthMagic`), the op carries which parts draw;
/// `.UpdateTextStats(param_1)` (Render, its own score / coin caches: no G effect); the key block on G
/// (`GameGlobals.stepSelection`, M l. 4885–4912) on **every** call, the map's included (BC39); `.UpdateItemStat`
/// unless (not stepped ∧ param_1 ≠ 0 ∧ param_2 == 0 ∧ item flash < 1) — its one G write, slot id 2 with `+8 ≠ 0` → 3
/// (M l. 4748–4750), made after the op copied the inventory as read (its big icon, M l. 4708–4718, is drawn first).
public struct StatusBarCalls: Equatable, Sendable {
    /// `*_DAT_1009fd9c` (a byte): the selection key's repeat counter.
    public var repeatCounter = 0
    /// `.UpdateHealthMagic`'s caches (ints): `_DAT_100ab9c8` health, `…9cc` magic, `…9d4` suffocation, `…9d0` breath.
    public var healthCache: Int32 = 0, magicCache: Int32 = 0, suffocationCache: Int32 = 0, breathCache: Int32 = 0
    /// The flash counters.
    public var flashes = Flashes()

    public init() {}

    /// `PTR_DAT_1009fdbc` / `_DAT_1009fdb8` (health / magic flash), `PTR_DAT_1009fda8` (item flash), `_DAT_1009fda4`
    /// (its slot), `_DAT_1009fda0` (its mode: 0 grey, 1 red). Row 13 counts the three counters down (M l.
    /// 44728–44736); the pickups and item uses set them (M l. 45192–45201, 45459–45461, 47997–48003, 48970–49018).
    public struct Flashes: Equatable, Sendable {
        public var health: Int16, magic: Int16, item: Int16, itemSlot: Int16, itemMode: Int16

        public init(health: Int16 = 0, magic: Int16 = 0, item: Int16 = 0, itemSlot: Int16 = 0, itemMode: Int16 = 0) {
            self.health = health
            self.magic = magic
            self.item = item
            self.itemSlot = itemSlot
            self.itemMode = itemMode
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
        /// PK: `.HitPlayerSprite`'s pickup refreshes — the 100th Xichron's Red Xichron (M l. 48694), a scroll (M l.
        /// 48975), an item (M l. 49021) — (1, 1, 0).
        case pickup
        /// PK: the upgrade animation's bar calls (1340 / 1341, M l. 48849, 48871, 48888, 48908) — (1, 0, 1).
        case upgradeStep

        /// (param_1 ≠ 0, param_2 ≠ 0, param_3 ≠ 0).
        public var parameters: (p1: Bool, p2: Bool, p3: Bool) {
            switch self {
            case .levelStart, .escapeCancel, .confirmOK, .confirmCancel, .optionsClosed, .chapterScreen, .savePointSave,
                 .mapEntry, .mapFirstFrame, .mapIdle:
                return (false, false, false)
            case .loopIteration, .mapIteration:
                return (true, false, false)
            case .moveSelectedItemToFront, .pickup:
                return (true, true, false)
            case .upgradeStep:
                return (true, false, true)
            }
        }
    }

    /// What one call made: the op, and whether `.UpdateHealthMagic` played its suffocation tick —
    /// `_STPlayRegSound(*_DAT_1009fdb4, 1, 0x100)` = snd 442 (M l. 4492; no `FastRand` in `.STPlayRegSound`) — at
    /// that point of the call (the caller emits it as a `.reg` sound call).
    /// `*_DAT_1009fdb4` (SoundSlots).
    public static let suffocationSound: Int16 = 442

    public struct Made: Equatable, Sendable {
        public var op: DrawOp
        public var suffocationTick: Bool
    }

    /// `.UpdateStatusBar(p1, p2, p3)` at `site` with the live actions 8 (next) / 7 (previous).
    public mutating func update(_ site: Site, globals g: inout GameGlobals, actions: InputActions,
                                levelName: String) -> Made {
        let p = site.parameters
        return update(p1: p.p1, p2: p.p2, p3: p.p3, globals: &g, actions: actions, levelName: levelName)
    }

    /// `.UpdateStatusBar(p1, p2, p3)` from its parameters (`update(_:…)`'s body; tests reach a (0, 0, 1) here).
    mutating func update(p1: Bool, p2: Bool, p3: Bool, globals g: inout GameGlobals, actions: InputActions,
                         levelName: String) -> Made {
        let bars = healthMagic(p3 ? true : p1, globals: &g)
        let stepped = g.stepSelection(next: actions.contains(.nextItem), previous: actions.contains(.previousItem),
                                      repeat: &repeatCounter)
        var s = state(g, levelName: levelName)
        s.call = StatusBarCall(partial: p1, forceItems: p2, forceBars: p3, stepped: stepped)
        s.call.healthBar = bars.health
        s.call.magicBar = bars.magic
        if s.drawsItems { Self.itemStatStore(&g) }
        return Made(op: .statusBar(s), suffocationTick: bars.tick)
    }

    /// `.UpdateHealthMagic(param) @ 10008430` (M l. 4361–4580), its state part. Every call: G+4 > G+0xa → G+4 = G+0xa,
    /// G+0xe > G+0xc → G+0xe = G+0xc (M l. 4409–4416). The routine returns when health, magic, G+8 and the (unclamped)
    /// breath equal the caches, `param` ≠ 0 and both flashes < 1 (M l. 4417–4422); the health part is skipped when
    /// health and breath equal theirs, `param` ≠ 0 and the health flash < 1 — G+8 not tested (M l. 4423–4424).
    /// The health part: G+6 > G+4 → G+6 = G+4 (M l. 4426–4428), the caches c8 / d0 / d4 (M l. 4429–4433), and with
    /// G+6 < 1, G+8 ≥ 1 and G+8 mod 10 == 9 the tick (M l. 4486–4493). The magic part (unless magic equals its cache,
    /// `param` ≠ 0 and the magic flash < 1, M l. 4517–4521): the cache cc.
    mutating func healthMagic(_ param: Bool, globals g: inout GameGlobals) -> (health: Bool, magic: Bool, tick: Bool) {
        if g.maxHealth < g.health { g.health = g.maxHealth }
        if g.maxMagic < g.magic { g.magic = g.maxMagic }
        let health = Int32(g.health)
        if health == healthCache && Int32(g.magic) == magicCache && Int32(g.suffocation) == suffocationCache
            && Int32(g.breath) == breathCache && param && flashes.health < 1 && flashes.magic < 1 {
            return (false, false, false)
        }
        var drewHealth = false, tick = false
        if !(health == healthCache && Int32(g.breath) == breathCache && param && flashes.health < 1) {
            if health < Int32(g.breath) { g.breath = g.health }
            healthCache = health
            breathCache = Int32(g.breath)
            suffocationCache = Int32(g.suffocation)
            drewHealth = true
            tick = g.breath < 1 && 1 <= g.suffocation && g.suffocation % 10 == 9
        }
        if Int32(g.magic) == magicCache && param && flashes.magic < 1 { return (drewHealth, false, tick) }
        magicCache = Int32(g.magic)
        return (drewHealth, true, tick)
    }

    /// A direct `.UpdateItemStat()` (`.HandleLineActions` M l. 66311, 66325; `.RemoveItem` M l. 39658): the op, then its
    /// G write.
    public func itemStat(globals g: inout GameGlobals, levelName: String) -> DrawOp {
        var s = state(g, levelName: levelName)
        s.call = StatusBarCall(itemsOnly: true)
        Self.itemStatStore(&g)
        return .statusBar(s)
    }

    /// A direct `.UpdateTextStats(0)` (`.HandleLineActions` M l. 66284): score, coins and level name, uncached.
    public func textStats(globals g: GameGlobals, levelName: String) -> DrawOp {
        var s = state(g, levelName: levelName)
        s.call = StatusBarCall(textOnly: true)
        return .statusBar(s)
    }

    private func state(_ g: GameGlobals, levelName: String) -> StatusBarState {
        var s = g.statusBar(levelName: levelName)
        s.healthFlash = Int(flashes.health)
        s.magicFlash = Int(flashes.magic)
        s.itemFlash = Int(flashes.item)
        s.itemFlashSlot = Int(flashes.itemSlot)
        s.itemFlashMode = Int(flashes.itemMode)
        return s
    }

    /// `.UpdateItemStat`'s loop store (M l. 4748–4750): `if (id == 2 && +8 != 0) id = 3`, every slot.
    static func itemStatStore(_ g: inout GameGlobals) {
        for k in g.inventory.indices where g.inventory[k].id == 2 && g.inventory[k].isSpell != 0 {
            g.inventory[k].id = 3
        }
    }
}
