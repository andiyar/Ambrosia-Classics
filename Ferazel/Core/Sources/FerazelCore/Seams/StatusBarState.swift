import Foundation

/// The values `.UpdateStatusBar(1, 0, 0)` draws into the 640×88 status bar (engine §3; plan S3).
///
/// HU (plan S2, Invariant 9: fields added, all defaulted): G's inventory, maxima and suffocation, the three flash
/// counters with the item flash's slot and mode, and the call that made the op (`StatusBarCall`). The defaults are a
/// new game's values (`.InitGameGlobals`, M l. 616–814) and the level start's `.UpdateStatusBar(0, 0, 0)`.
public struct StatusBarState: Equatable, Sendable {
    public var score: Int
    public var coins: Int
    public var health: Int
    public var breath: Int
    public var magic: Int
    public var levelName: String
    public var selectedSlot: Int
    /// `G+0x24`: the 27 inventory slots as the call reads them (before `.UpdateItemStat`'s `== 2 ∧ +8 → 3` store).
    public var inventory: [InventorySlot]
    /// `G+0x0a` / `G+0x0c`.
    public var maxHealth: Int
    public var maxMagic: Int
    /// `G+0x08`: the suffocation countdown (the breath segment's tick colour while `G+6 < 1`).
    public var suffocation: Int
    /// `PTR_DAT_1009fdbc` / `_DAT_1009fdb8`: the health / magic flash counters (`PlayerState` row 13 counts them down).
    public var healthFlash: Int
    public var magicFlash: Int
    /// `PTR_DAT_1009fda8`: the item flash counter; `_DAT_1009fda4`: its slot; `_DAT_1009fda0`: its mode (0 grey, 1 red).
    public var itemFlash: Int
    public var itemFlashSlot: Int
    public var itemFlashMode: Int
    /// The call that made this op.
    public var call: StatusBarCall

    /// `.InitGameGlobals`' 27 slots (M l. 616–677): spell 0, item 0, then 25 empty.
    public static let newGameInventory: [InventorySlot] = GameGlobals.initGameGlobals(previous: nil).inventory

    public init(score: Int = 0, coins: Int = 0, health: Int = 0, breath: Int = 0, magic: Int = 0, levelName: String = "",
                selectedSlot: Int = 0, inventory: [InventorySlot] = StatusBarState.newGameInventory,
                maxHealth: Int = 0x230, maxMagic: Int = 0x230, suffocation: Int = 0, healthFlash: Int = 0,
                magicFlash: Int = 0, itemFlash: Int = 0, itemFlashSlot: Int = 0, itemFlashMode: Int = 0,
                call: StatusBarCall = StatusBarCall()) {
        self.score = score
        self.coins = coins
        self.health = health
        self.breath = breath
        self.magic = magic
        self.levelName = levelName
        self.selectedSlot = selectedSlot
        self.inventory = inventory
        self.maxHealth = maxHealth
        self.maxMagic = maxMagic
        self.suffocation = suffocation
        self.healthFlash = healthFlash
        self.magicFlash = magicFlash
        self.itemFlash = itemFlash
        self.itemFlashSlot = itemFlashSlot
        self.itemFlashMode = itemFlashMode
        self.call = call
    }

    /// `.UpdateStatusBar(…)` reaches `.UpdateItemStat` (M l. 4913–4917), or the op is a direct `.UpdateItemStat()`:
    /// unless (not stepped ∧ param_1 ≠ 0 ∧ param_2 == 0 ∧ `PTR_DAT_1009fda8` < 1). A direct `.UpdateTextStats(0)` never.
    public var drawsItems: Bool {
        if call.textOnly { return false }
        if call.itemsOnly { return true }
        return call.stepped || !call.partial || call.forceItems || 1 <= itemFlash
    }
}

/// Which status-bar routine made a `DrawOp.statusBar` and with what parameters (HU, plan S2).
public struct StatusBarCall: Equatable, Sendable {
    /// `.UpdateStatusBar`'s param_1 ≠ 0: no whole-port copy, and `.UpdateHealthMagic` / `.UpdateTextStats` skip what
    /// their caches say is unchanged. False = param_1 0 (the full redraw).
    public var partial: Bool
    /// param_2 ≠ 0: `.UpdateItemStat` runs even without a key step or an item flash.
    public var forceItems: Bool
    /// param_3 ≠ 0: `.UpdateHealthMagic(1)` instead of `.UpdateHealthMagic(param_1)` (M l. 4878–4883) — the bars take
    /// the cached (skip-if-unchanged) path whatever param_1 is. (The plan's name; the dump's effect is that one.)
    public var forceBars: Bool
    /// A direct `.UpdateItemStat()` (`.HandleLineActions` M l. 66311, 66325; `.RemoveItem` M l. 39658).
    public var itemsOnly: Bool
    /// A direct `.UpdateTextStats(0)` (`.HandleLineActions` M l. 66284).
    public var textOnly: Bool
    /// `.UpdateStatusBar`'s key block stepped the selection in this call (`bVar1`, M l. 4885–4912).
    public var stepped: Bool

    public init(partial: Bool = false, forceItems: Bool = false, forceBars: Bool = false, itemsOnly: Bool = false,
                textOnly: Bool = false, stepped: Bool = false) {
        self.partial = partial
        self.forceItems = forceItems
        self.forceBars = forceBars
        self.itemsOnly = itemsOnly
        self.textOnly = textOnly
        self.stepped = stepped
    }
}
