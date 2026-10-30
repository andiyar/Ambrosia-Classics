import Foundation

/// The fields of one 0x1fc-byte sprite record (`.MTNewSprite @ 10033060` table at `_DAT_100a01dc`, 700 entries) that
/// Phase 1 reads: what the class Setup leaves (`SetupFaces`) and what `.WrapDrawSprites @ 100144c8` reads per sprite
/// (draw-effects §1.1; physics §0 / §0.1 for the offsets). Defaults are `.MTNewSprite`'s `MemoryClear` + `.InitSprite
/// @ 1003d3bc` (decompile l. 35566–35688): `+0x88 = 1`, `+0x1c6 = 1`, clips 0 / 32000 / 32000 / 0, scale `+0x1ae =
/// 0x100` (and its last-frame copy `+0x1b0`), everything else 0. The still counter `+0x19c` (`.WrapDrawSprites`
/// `100145cc..100145f4`) has no reader among the routines Phase 1 builds and is not kept.
public struct SpriteSlot: Equatable, Sendable {
    /// The idle-test margins `+0x1c8` left, `+0x1ca` right, `+0x1cc` top, `+0x1ce` bottom (triggers-background-2 §8.3).
    public struct Margins: Equatable, Sendable {
        public var left: Int
        public var right: Int
        public var top: Int
        public var bottom: Int

        public init(left: Int = 0, right: Int = 0, top: Int = 0, bottom: Int = 0) {
            self.left = left; self.right = right; self.top = top; self.bottom = bottom
        }
    }

    /// The occluder rect `+0x1be` xmin / `+0x1c0` xmax / `+0x1c2` ymax / `+0x1c4` ymin in world px (`.InitSprite`
    /// 32000 each; physics §0.1, adjudication A11), consumed by `.StandardSpriteCleanup`'s horizontal clip.
    public struct Occluder: Equatable, Sendable {
        public var left: Int16
        public var right: Int16
        public var bottom: Int16
        public var top: Int16

        public init(left: Int16 = 32000, right: Int16 = 32000, bottom: Int16 = 32000, top: Int16 = 32000) {
            self.left = left; self.right = right; self.bottom = bottom; self.top = top
        }
    }

    /// A point (`+0x10` x / `+0xe` y for the hot-rect centre).
    public struct Point: Equatable, Sendable {
        public var x: Int
        public var y: Int

        public init(x: Int = 0, y: Int = 0) { self.x = x; self.y = y }
    }

    /// The linked sprites `+0x1d4` / `+0x1d8` (`ActiveList` ids; nil = 0). `.StandardSpriteHandles` carries both with
    /// a ridden sprite's dx.
    public struct Siblings: Equatable, Sendable {
        public var first: Int?
        public var second: Int?
        /// `+0x1dc` / `+0x1e0` (W1): the third and fourth links — the 4-wheel's S3 and its links, read by
        /// `.HitPlatformTileSprite`'s bounce. `.StandardSpriteHandles`' carry moves `+0x1d4`/`+0x1d8` only.
        public var third: Int?
        public var fourth: Int?

        public init(first: Int? = nil, second: Int? = nil, third: Int? = nil, fourth: Int? = nil) {
            self.first = first; self.second = second; self.third = third; self.fourth = fourth
        }
    }

    /// Identity in the `ActiveList` (the original's record pointer); assigned by `ActiveList.insert`.
    public internal(set) var id: Int = 0
    /// `+0x04`.
    public var type: Int16
    /// `+0x0c` / `+0x0a`: the face cell's top-left in world px — the **pixel copies** of the 24.8 position
    /// `x256`/`y256`. They are written from the 24.8 position only where the binary writes them: `.SeparateFromTiles2`
    /// at entry (raw `1003c82c..1003c844`, with `+8`/`+6`), `.ApplySpeedAndSeparateFromTiles`' steps, `.RectBounce` /
    /// `.PlatformBounce` (l. 36410–36415, 33059–33061), the carry in `.StandardSpriteHandles`, `.IdleToActiveSprite`,
    /// `.MTNewSprite` (its quirk: `newSprite`), and each class Handle's own stores. Between those writes the two may
    /// disagree, as in the original: the water current in `.StandardSpriteHandles` moves `x256` without `x`
    /// (decompile l. 32481) and that is faithful — the next integration re-derives the copy.
    public var x: Int
    public var y: Int
    /// `+0x48`: the placement record (−1 = none).
    public var recordIndex: Int16
    /// `+0x80`: the active-list sort key (read at insertion only; physics §0).
    public var layer: Int32
    /// `+0xc0`: the face (nil = 0, not drawn).
    public var face: FaceRef?
    /// `+0xb8`: the draw-effect word `mode << 16 | sub`.
    public var mode: UInt32 = 0
    /// `+0x17e`: the blitter's horizontal mirror.
    public var mirrored = false
    /// `+0x88`: the light-overlay pass gate.
    public var lightOverlay = true
    /// `+0x89`: dynamic lighting (`.WrapDrawSprites` rewrites `+0xb8` from the light map).
    public var dynamicLight = false
    /// `+0x1c6`: may go idle off-screen.
    public var mayIdle = true
    /// `+0x9a`: the light slot the Setup's `.AddLight` returned (`.InitSprite`'s 0xffff = −1, none); the Handles'
    /// `.ChangeLightFace` target.
    public var light: Int16 = -1
    /// `+0x46`: the Handle's animation counter.
    public var phase: Int16 = 0
    /// The Setups' `FastRand` draws (F1; plan "F1 ⚑ FastRand sites"), kept though no Phase-2 routine reads them yet.
    /// `+0x112` (i16): "slipperiness" / the `.WallBounce` kick (pickups-boxes field table).
    public var slip: Int16 = 0
    /// `+0x114` (i16): friction — a Bonus's vx decays by it per frame (pickups-boxes field table).
    public var friction: Int16 = 0
    /// `+0x14c` (i32): the class word — Bonus light-flicker timer (pickups-boxes §1.1), Walker decision distance
    /// (enemies-ground §3.1), the crumble overlay 1210's starting hp (its face = `+0x14c` − hp; P2).
    public var classTimer: Int32 = 0
    /// `+0x154` (i32): Walker `1000 + FastRand(400)` (enemies-ground §3.1: no reader in Walker code); the crumble
    /// overlay 1210's tile column (P2).
    public var classWord154: Int32 = 0
    /// `+0x150` / `+0x158` / `+0x15c` / `+0x16c` (i32): class words — the crumble overlay 1210 keeps its table slot,
    /// tile row, crunch direction nibble (not the tile kind, as triggers-background-2 §2.3 had it) and "armed" flag
    /// here (`.MakeCrunchSprite`, `.CrunchTile`; P2).
    public var classWord150: Int32 = 0
    public var classWord158: Int32 = 0
    public var classWord15c: Int32 = 0
    public var classWord16c: Int32 = 0
    /// `+0x170` (i32): the Background radial bars / balls' harmful flag — `.HandleBackgroundSprite` writes it every
    /// frame (modes 10–14), the pendulum arm of `.HitPlayerSprite` hurts only when it is 1 (W2a).
    public var classWord170: Int32 = 0
    /// `+0xb0` (i16): a class's sub-type word — the Background's p1, a Platform's base type (0x58c = springboard,
    /// read through the ridden `+0xdc` by `.CheckGroundCeilingHitEffects` and `.HandleKeys`; W1 writes it).
    public var subtype: Int16 = 0
    /// BN (the Bonus class's names for offsets `SpriteSlot` already holds — one storage per offset):
    /// `+0xb0` the pickup delay (`.HitPlayerSprite` collects only at 0; drops set 12, the Handles count it down; the
    /// torch's / candelabras' "unspent" flag) = `subtype`.
    public var pickupDelay: Int16 {
        get { subtype }
        set { subtype = newValue }
    }
    /// `+0x14c` the Bonus light-flicker timer (`.SetupBonusSprite`'s tail `FastRand(60)`) = `classTimer`.
    public var lightTimer: Int32 {
        get { classTimer }
        set { classTimer = newValue }
    }
    /// `+0x15c` a Xichron's in-water-at-spawn flag (`.HandleBonusSprite` then sets `+0x11c`/`+0x120` every frame); the
    /// upgrades 0x53c / 0x53d's light counter = `classWord15c`.
    public var inWaterAtSpawn: Int32 {
        get { classWord15c }
        set { classWord15c = newValue }
    }
    /// `+0x16c` a dropped coin's life (`.HurtPlayer` −240; the Handle counts up, blinks from −44, kills at 0) =
    /// `classWord16c`.
    public var coinLife: Int32 {
        get { classWord16c }
        set { classWord16c = newValue }
    }
    /// `+0x168` (i32): a Bonus's record p4 (`.SetupBonusSprite`, valid record only) — read by `.TurnIntoCannoned`
    /// (1 → never cannoned; pickups-boxes-2 §2).
    public var bonusP4: Int32 = 0
    /// `+0x160` (i32): a class word — a player shot's follower step x (`.SetupPlayerShotSprite`, CS).
    public var classWord160: Int32 = 0
    /// `+0xf4` (i32): a class word — a thrown seed 0x5a's Ziridium flag (`.HandlePlayerShotSprite`'s 0x5a arm reads
    /// it, M l. 50689; its writer is the seed thrower's, IU).
    public var classWordF4: Int32 = 0
    /// `+0x84` / `+0x86` (i16): the particle offsets the shot particles subtract (`.InitSprite`'s clear; every Setup
    /// that writes them stores 0 — `.SetupPlayerShotSprite` M l. 50289–50290 — so they read 0; enemies-flyers §7.1).
    public var particleOffsetY: Int16 = 0
    public var particleOffsetX: Int16 = 0

    // MARK: player shots (CS; `.SetupPlayerShotSprite @ 1005925c`, `.HandlePlayerShotSprite @ 10059704`) — the shot's
    // names for offsets the record already holds (one storage per offset).

    /// `+0x14c` the shot's age (−1 at Setup, +1 per Handle up to 200) = `classTimer`.
    public var shotAge: Int32 {
        get { classTimer }
        set { classTimer = newValue }
    }
    /// `+0x170` the shot's power (the low byte of the spawn type; ≤ 5 after Setup; 0 = a follower) = `classWord170`.
    public var power: Int32 {
        get { classWord170 }
        set { classWord170 = newValue }
    }
    /// `+0x158` the crunch strength `.CrunchTile` is passed (1 for shots, 2 for the seeds) = `classWord158`.
    public var crunchStrength: Int32 {
        get { classWord158 }
        set { classWord158 = newValue }
    }
    /// `+0x160` / `+0x164` the follower step (x, y): (10, 0) for ids 6 / 0x3c, else (0, 6) = `classWord160` /
    /// `launchSpeed` (the 0x50 orb's `+0x164` is its flash timer — the same storage).
    public var stepX: Int32 {
        get { classWord160 }
        set { classWord160 = newValue }
    }
    public var stepY: Int32 {
        get { launchSpeed }
        set { launchSpeed = newValue }
    }
    /// `+0x168` / `+0x16c` the stack offset (x, y) = (power − 1)·step / 2 (the 0x50 orb: hits left / tint phase) =
    /// `bonusP4` / `classWord16c`.
    public var stackX: Int32 {
        get { bonusP4 }
        set { bonusP4 = newValue }
    }
    public var stackY: Int32 {
        get { classWord16c }
        set { classWord16c = newValue }
    }
    /// `+0xf0` a thrown seed's "no fragments / invisible" flag (`.HandlePlayerShotSprite`'s 0x5a arm, M l. 50685) =
    /// `voicePitch`.
    public var seedHidden: Int32 {
        get { voicePitch }
        set { voicePitch = newValue }
    }
    /// `+0xf0` (i32): Walker (goblin) voice pitch `2·FastRand(0x5fff) + 0xbfff` (enemies-ground §3).
    public var voicePitch: Int32 = 0
    /// `+0x1c8..+0x1ce`.
    public var margins = Margins()
    /// `+0x1b6` left / `+0x1b8` right / `+0x1ba` bottom / `+0x1bc` top.
    public var clip = SpriteClip(left: 0, right: 32000, bottom: 32000, top: 0)
    /// `+0x1aa` rotation (degrees) / `+0x1ae` scale (0x100 = 1.0).
    public var rotation: Int16 = 0
    public var scale: Int16 = 0x100
    /// `+0x11c` water contact (0 in Phase 1).
    public var waterRow: Int32 = 0
    /// `+0xe9` (u8): the kill request / death count (US). Every writer in the dump stores 1 (the request), 0
    /// (`.InitSprite`, `.ActiveToIdleSprite`, `.IdleToActiveSprite`) or `+0xe9 + 1` (`.UpdateSprites`' count-up,
    /// M l. 4983); `.UpdateSprites` unlinks the sprite at 4 (`SpriteWorld.updateSprites`).
    public var killCount: UInt8 = 0
    /// `+0xe9` ≠ 0: the kill request, as the Handles and passes test it. Setting true stores 1 — the literal every
    /// `stb` of the dump writes (M l. 38830, 39174, 44154, …; none keeps a running count) — false stores 0.
    public var dead: Bool {
        get { killCount != 0 }
        set { killCount = newValue ? 1 : 0 }
    }
    /// `+0xea` (u8): killed for good — with `+0xe9` 0, `.UpdateSprites` clears the record's `+4` (M l. 4971–4977).
    public var killedForGood = false
    /// `+0x188` (u8): keep the record — no write-back and no `+4` clear on the count-up passes (`.UpdateSprites`
    /// M l. 4959, 4975, 4995); the Background modes 10…14 set it (M l. 62363).
    public var keepRecord = false
    /// `+0x189` (u8): no record write-back (`.UpdateSprites` M l. 4960).
    public var noWriteBack189 = false
    /// `+0x18a` (u8): no record write-back (`.UpdateSprites` M l. 4959).
    public var noWriteBack18a = false
    /// `+0x18b` (u8): keep the record's `+4` at the final kill (`.UpdateSprites` M l. 5021).
    public var keepRecordAtKill = false
    /// `+0x1b5` (u8): counted in the level totals (plan S2). No reader in `.UpdateSprites`.
    public var countedInTotals = false
    /// `+0xa8` (i16): the idle-table entry the sprite came from — `.InitSprite` −1 (M l. 35592), `.IdleToActiveSprite`
    /// the entry index (M l. 4265); `.UpdateSprites`' final kill frees entry 0…0x1ff (M l. 5024–5027).
    public var idleEntry: Int16 = -1

    // MARK: The physics record (plan S2, F2). Defaults are `.MTNewSprite`'s `MemoryClear` + `.InitSprite`.

    /// `+0x4c` the Handle (`.MTHandleSprites` calls it) — every class Setup installs one (plan S2 `SpriteHandler`).
    public var handler: SpriteHandler
    /// `+0x5c` ≠ 0: the sprite has a hit callback (`.MTCollideSprites` outer gate, `C.hit` in the player pass). No
    /// Setups that set it are built: the platforms (W1), the Background cannons, springs and tunnels (W2b) and the
    /// Box solids (W3); the rope Setup clears it (W3).
    public var hasHit = false
    /// `+0x14` / `+0x1c`: x / y in 24.8 fixed point (`.MTNewSprite`: `x << 8`, `y << 8`).
    public var x256: Int32
    public var y256: Int32
    /// `+0x24` / `+0x2c`: vx / vy in 1/256 px per frame.
    public var vx: Int32 = 0
    public var vy: Int32 = 0
    /// `+0x110` (i16): gravity per frame.
    public var gravity: Int16 = 0
    /// `+0x34` (QuickDraw top, left, bottom, right in face-local px): the hot rect.
    public var hotRect = IdleSprites.Rect(top: 0, left: 0, bottom: 0, right: 0)
    /// `+0x3c..+0x42`: the hot rect offset by (x, y), built by `.CalcHotRect @ 10032614` during `.MTCollideSprites`.
    /// Stale outside that pass (and the `.InitSprite` zeros for a sprite never tested) — as in the original, where
    /// only `.CalcHotRect` (l. 30193–30200) writes it.
    public var hotRectWorld = IdleSprites.Rect(top: 0, left: 0, bottom: 0, right: 0)
    /// `+0x44`: `+0x3c` built this collision pass (cleared for every sprite at the pass start).
    public var hotRectBuilt = false
    /// `+0x10` / `+0xe`: the hot-rect centre in world px (`.CalcCenterPos`, `.StandardSpriteCleanup`). Computed only
    /// there (`.StandardSpriteCleanup` l. 32647–32652): a sprite whose Handle never runs Cleanup (an `inert` one, or
    /// before its first Handle) keeps the `.InitSprite` 0 or its last value, as the original's record does [LOW].
    public var centre = Point()
    /// `+0x8` x / `+0x6` y: the position copy every integration step writes with `+0xc`/`+0xa` (`.SeparateFromTiles2`
    /// at entry, raw `1003c82c..1003c844`); `.WallBounce` kinds 4–7 revert to it (F3; physics §0).
    public var oldPosition = Point()
    /// `+0x181` (u8): the ice-slide latch — cleared at every `.SeparateFromTiles2` entry, set by a `.WallBounce` /
    /// `.WallBounceBG` slide (F3; player-states-2 §9.2).
    public var slideLatch = false
    /// `+0xeb` (u8): crunches tiles on contact (`.SeparateFromTiles2` runs the crunch-nibble pass while set; F3).
    public var crunches: UInt8 = 0
    /// `+0xcd` (u8): `.StandardSpriteHandles` copies `+0xce` into it; `.PlatformBounce` sets 1 on a landing.
    public var onSprite: UInt8 = 0
    /// `+0xce` (u8): the ground / surface kind under the sprite this frame (0 airborne, 3 = a sprite).
    public var groundKind: UInt8 = 0
    /// `+0xcf` (u8): ceiling hit — the byte as written: `.WallBounce`/`.WallBounceBG` store the (base) kind byte
    /// (`uVar18`/`uVar9` = `(char)param_2`, decompile l. 33188, 34197), `.PlatformBounce` return 2 stores 1. Its
    /// reader tests ≠ 0 (`100546cc`).
    public var ceilingHit: UInt8 = 0
    /// `+0xd0` (u8): landed on a one-way top.
    public var oneWayLanded = false
    /// `+0xd2` / `+0xd4` (i16): the left / right surface heights of a sloped top (`.InitSprite` −1000 each = flat).
    public var surfaceLeft: Int16 = -1000
    public var surfaceRight: Int16 = -1000
    /// `+0xd6` (i16): the slope of the top the sprite stands on (`.RectBounce`, `.PlatformBounce`; cleared by
    /// `.StandardSpriteCleanup`).
    public var slope: Int16 = 0
    /// `+0xd8` (i16): surface material (FG kind / 100), zeroed by `.StandardSpriteHandles`.
    public var material: Int16 = 0
    /// `+0xdc`: the sprite being ridden (an `ActiveList` id; nil = 0).
    public var ridden: Int?
    /// `+0xe0`: the rider (an `ActiveList` id; nil = 0).
    public var rider: Int?
    /// `+0x186` (u8): ridden this frame (`.PlatformBounce`, `.RopeCollide`; cleared by the owner's Handle).
    public var ridingLatch = false
    /// `+0x185` (u8): one-way top.
    public var oneWay = false
    /// `+0x138` (i16): push mass; `+0x13a` (i16): landing sag; `+0x13c` (i16): pusher factor (`.RectBounce`).
    public var pushMass: Int16 = 0
    public var sag: Int16 = 0
    public var pushForce: Int16 = 0
    /// `+0x120` (i32): last frame's water contact (`+0x11c` copied by `.StandardSpriteHandles`).
    public var lastWater: Int32 = 0
    /// `+0x128` (i16): water kind (BG kind − 200).
    public var waterKind: Int16 = 0
    /// `+0x118` (i16): the water-reset gate (`< 0x1d` → `.StandardSpriteHandles` runs the current and the
    /// `+0x11c` reset). Every writer stores 0 (enemies-water-cave §0.1).
    public var waterGate: Int16 = 0
    /// `+0x8a` (u8): the water current applies (`.InitSprite` 1; the player clears it while clinging).
    public var currentApplies = true
    /// `+0x94` (i16): the water-current ramp counter (0 … 33).
    public var currentRamp: Int16 = 0
    /// `+0x90` (i16): wind scale /256 (≤ 0 immune). `+0x92` (u8): in wind this frame. `+0x96` / `+0x98` (i16): the
    /// wind ramp counter / last impulse x.
    public var windScale: Int16 = 0
    public var inWind = false
    public var windRamp: Int16 = 0
    public var windLast: Int16 = 0
    /// `+0x140` (u8): water handled this frame.
    public var underwaterDone = false
    /// `+0x144` (i32): quicksand depth (`.HandleFlotation` kind 5); zeroed on leaving the water.
    public var quicksandDepth: Int32 = 0
    /// `+0x148` (i32): the liquid surface y `.HandleUnderWater` stores on entering (`+0x120 == 0`); the quicksand floor
    /// line is `+0x148 + (+0x144 >> 8)` (P4).
    public var quicksandSurface: Int32 = 0
    /// `+0x116` (i16): invulnerability frames.
    public var invulnerable: Int16 = 0
    /// `+0xaa` (i16): hurt-flash frames.
    public var flash: Int16 = 0
    /// `+0x1b4` (u8): the hurt flash uses mode 4 instead of 3.
    public var flashTable: UInt8 = 0
    /// `+0x18c` (u8): drawn in one piece — no water split, the light pass without the water row (`.WrapDrawSprites`
    /// `10014800`, `10014960`); the player's teleporter charge sets it (draw-effects §2.3). No Phase-2 writer.
    public var noWaterSplit = false
    /// `+0xa4` (i16): hit points.
    public var hp: Int16 = 0
    /// `+0x19e` / `+0x1a0` (i16): buoyancy / float-line offset (`.HandleFlotation`).
    public var buoyancy: Int16 = 0
    public var floatOffset: Int16 = 0
    /// `+0x130` (i32): cannon hold timer; negative = re-entry block, counted up by `.StandardSpriteHandles`. SW: the
    /// same word is the Statue's countdown (`.TurnIntoStatue` stores 0x78, `.HandleStatueSprite` − 1 a frame).
    public var reentry: Int32 = 0
    /// `+0x134` (u32): the draw-effect word `+0xb8` `.TurnIntoStatue` saves (M l. 38264), restored by
    /// `.HandleStatueSprite` when its countdown runs out (M l. 56549; SW).
    public var statueSavedMode: UInt32 = 0
    /// `+0x180` (u8): radial wall-bounce latch, cleared every frame by `.StandardSpriteHandles`.
    public var radialLatch = false
    /// `+0x184` (u8): no collision with sprites of the same handler (`.MTCollideSprites`).
    public var sameHandlerExempt = false
    /// `+0x1b2` (u8): Handle skip — never the outer sprite of `.MTCollideSprites`.
    public var handleSkip = false
    /// EC (plan S2 `emerging`, added, Invariant 9): `+0x1b2` as the enemies name it — pipe emergence (written by PI);
    /// every class Handle returns at once while it is set (enemies-flyers §7.4). The same byte as `handleSkip` (one
    /// field per offset), so this is a second name for it, not a second store.
    public var emerging: Bool {
        get { handleSkip }
        set { handleSkip = newValue }
    }
    /// BT (added, Invariant 9): `+0xa0` (i32) — a Button's level as its last Handle left it (`.HandleButtonSprite`'s
    /// last store, M l. 61812; the 4705 test reads it, M l. 61772–61775). The doors' dead `+0xa0 = 0` is not kept.
    public var buttonPrevious: Int32 = 0
    /// BT (added, Invariant 9): `+0xe4` (u8) — a Button's first-Handle flag (`.SetupButtonSprite` 0, the first Handle
    /// 1 and the record-p4 restore, M l. 61755–61760). The player shots' write (`.SeparateFromTiles2`'s dead gate) is
    /// not kept.
    public var firstHandled = false
    /// `+0x1a2` (i16): burn-away row (≠ 0 → `.HandleBurn` from `.StandardSpriteCleanup`).
    public var burnRow: Int16 = 0
    /// EC (added, Invariant 9): `+0x8c` (u8) — the burn's sound is the pitched 462 (`.HandleBurn` M l. 38783–38791;
    /// set by `.SetupEnemyShotSprite` and the Wizard / Xichra hits, draw-effects §4.2). `.InitSprite` 0.
    public var burnPitched = false
    /// EC (added, Invariant 9): `+0x8d` (u8) — rows the burn consumes a frame, less one (`.SetupChiefSprite` 1).
    public var burnSpeed: UInt8 = 0
    /// EC (added, Invariant 9): `+0x8e` (u8) — the burn's particle kind 0xd instead of 1 (`.SetupFrogSprite` with
    /// hdr+0x26cd ≠ 0).
    public var burnStyle = false
    /// `+0x1a6` / `+0x1a8` (i16): glow particle kind / glow chance (`.ParticleGlow` from `.StandardSpriteCleanup`).
    public var glowKind: Int16 = 0
    public var glowChance: Int16 = 0
    /// `+0x1be..+0x1c4`.
    public var occluder = Occluder()
    /// `+0x1d4` / `+0x1d8`.
    public var siblings = Siblings()
    /// `+0x187` has-radial / `+0x198` the 0xa4-byte radial block (`.MakeRadial`; W1, plan S2). nil = `+0x187` 0.
    public var radial: Radial?
    /// `+0xa6` (i16): the platform's direction / cooldown / lifetime / phase word (`.SetupPlatformSprite` 1; W1).
    public var counterA6: Int16 = 0
    /// `+0xb2` (i16): the platform sub-state (modes 50/51 10 / 0xb) and the radial "driver" flag (W1).
    public var subState: Int16 = 0
    /// `+0x17c` (u8): the platform's first-frame `.DoSetupPlatformSprite` has run (W1).
    public var setupDone = false
    /// `+0x194` (i32): the jump bonus a rider's jump reads (`.HandleKeys`: J = ridden `+0x194`; W1 writes it).
    public var jumpBonus: Int32 = 0
    /// `+0x1f8` ≠ 0: the sprite has a tile callback (W1: platform modes 10/11 clear it; the handler picks the closure).
    public var hasTileHit = false
    /// `+0x4c` == 0: `.ActiveToIdleSprite` cleared the Handle of a live record it saved (raw `10007ed4..`, l. 4202);
    /// the record stays on the list — `.MTHandleSprites` skips it, `.UpdateSprites` kills it at the end of the
    /// iteration (W1 carry, F2 fix-round finding).
    public var handleCleared = false
    /// `+0x9c` the rope block (`.SetupRopeSegArray`, W3); its presence also stands for `+0x1e8`, the surface-height
    /// function `.GetRopeHeight` that routine installs (`RopeBlock`). // later: Phase 6 — the rope bridge 1466's
    /// `.GetRopeBridgeHeight` (unplaced).
    public var rope: RopeBlock?
    /// W2b (cannons, `.TurnIntoCannoned @ 10058594`, decompile l. 49930–49974): `+0x164` (i32) a cannon's launch speed S
    /// (9000 for p1 0, M l. 62114); `+0x1e4` the cannon holding a captive (an `ActiveList` id; nil = 0); `+0x1ec` /
    /// `+0x1f0` / `+0x1f4` the captive's saved Handle, hit and tile callbacks (restored at the launch). SW: the same
    /// three words hold a Statue's saved Handle and callbacks (`.TurnIntoStatue` M l. 38257–38262, restored by
    /// `.HandleStatueSprite` M l. 56546–56548).
    public var launchSpeed: Int32 = 0
    public var cannon: Int?
    public var savedHandler: SpriteHandler?
    /// The saved `+0x4c` was 0 (`handleCleared`: an idled record captured before `.UpdateSprites` killed it).
    public var savedHandleCleared = false
    public var savedHasHit = false
    public var savedHasTileHit = false
    /// `+0x1b3` burning (read by `.WrapEraseSprites`).
    public var burning = false
    /// Last frame's copies `.WrapDrawSprites` writes after each sprite (`+0xc8` face, `+0xc6`/`+0xc4` x/y, `+0x17f`,
    /// `+0xbc` mode, `+0x1ac`/`+0x1b0` rotation/scale, `+0x124` water row) — read by `.WrapEraseSprites`. nil while
    /// `+0xc8` is 0 (no face drawn); the drawn position itself is `drawnX`/`drawnY`, kept for every sprite.
    public var previous: SpriteDraw?
    /// `+0xc6` / `+0xc4`: the pixel position at the last `.WrapDrawSprites`, copied for **every** sprite on the list,
    /// face or not (`100149a4..10014a14`); `.InitSprite` 0. The carry in `.StandardSpriteHandles` reads the ridden
    /// solid's (F2 review fix: a faceless solid carries by its real drawn delta).
    public var drawnX = 0
    public var drawnY = 0
    public var previousRotation: Int16 = 0
    public var previousScale: Int16 = 0x100
    public var previousWaterRow: Int32 = 0
    /// `+0x12a` (i16): last frame's water kind (`+0x128` copied by `.WrapDrawSprites`' tail, l. 10391) — the kind of
    /// `.Splash(s, 4)`'s leaving particles (E1a).
    public var previousWaterKind: Int16 = 0
    /// `+0x13e` (u8): the sprite splashes (`.Splash` returns at once when 0): `.InitSprite` 1 (l. 35648), the Effect
    /// Setup 0 (l. 53734) — no other writer (E1a).
    public var splashes = true
    /// `+0x182` (u8): `.HitBoxSprite`'s pair latch — set on both sprites of a Box / Statue / Platform pair it bounces,
    /// tested on the Box (`self`) only, cleared by `.HandleBoxSprite` after `.StandardSpriteHandles` (M l. 60091) and
    /// `.InitSprite` (M l. 35664); no other writer (BX1).
    public var boxPairLatch = false

    public init(type: Int16, x: Int, y: Int, recordIndex: Int16 = -1, layer: Int32 = 0, face: FaceRef? = nil) {
        self.type = type
        self.x = x
        self.y = y
        self.recordIndex = recordIndex
        self.layer = layer
        self.face = face
        x256 = Int32(truncatingIfNeeded: x) << 8
        y256 = Int32(truncatingIfNeeded: y) << 8
        handler = SpriteHandler.forClass(type: type)
    }

    /// `.WrapDrawSprites` step 4's `+0x89` arm (raw `1001472c..100147bc`): with dynamic light and a face,
    /// L = `.GetLightTile(cx >> 5, cy >> 5)` (cx/cy = the hot-rect centre `+0x10`/`+0xe`) and F = `.GetFakeLight`;
    /// both < 1 → `+0xb8 = 0`, else `+0xb8 = 0xc0000 + L·0x100 + F` (`rlwinm 8; addis 0xc` — L = −1 with F ≥ 1 gives
    /// `0xbff00 + F`, mode 0xb). The result is written back to `+0xb8` and returned; without `+0x89` the stored word.
    public mutating func applyDynamicLight(lightTile L: Int, fakeLight F: Int) -> UInt32 {
        guard dynamicLight, face != nil else { return mode }
        if L < 1 && F < 1 {
            mode = 0
        } else {
            mode = UInt32(truncatingIfNeeded: L * 0x100 + 0xc0000 + F)
        }
        return mode
    }

    /// `.WrapDrawSprites`' tail for every sprite on the list, drawn or not (`100149a4..10014a14`): `+0xc8 ← +0xc0`,
    /// `+0xc6`/`+0xc4 ← +0xc`/`+0xa`, `+0xbc ← +0xb8`, `+0x1ac ← +0x1aa`, `+0x1b0 ← +0x1ae`, `+0x124 ← +0x11c`,
    /// `+0x17f ← +0x17e`, `+0x12a ← +0x128` (l. 10391; E1a) (the fixed-point and velocity copies are not kept).
    public mutating func recordDrawn() {
        previous = face == nil ? nil : makeDraw()
        drawnX = x
        drawnY = y
        previousRotation = rotation
        previousScale = scale
        previousWaterRow = waterRow
        previousWaterKind = waterKind
    }

    /// What `.WrapDrawSprites` hands the blitters for this sprite: nil when `+0xe9` is set or `+0xc0` is 0 (step 1,
    /// `1001452c`, `10014538`). `mode` is the stored `+0xb8` (call `applyDynamicLight` first for a `+0x89` sprite);
    /// the blitter derives the hurt-flash word from `flash`/`flashTable` (step 4), except for a `+0x89` sprite, whose
    /// light word overwrites the flash (`1001472c..100147bc`) — its `flash` is passed as 0. `+0x1aa`/`+0x1ae`, the
    /// water row/kind `+0x11c`/`+0x128`, `+0x18c` and the occluder (nil while the `.InitSprite` 32000s) ride along.
    public var draw: SpriteDraw? {
        guard !dead, face != nil else { return nil }
        return makeDraw()
    }

    /// The `SpriteDraw` of the current fields (`face` non-nil).
    private func makeDraw() -> SpriteDraw {
        SpriteDraw(face: face!, x: x, y: y, mode: mode, mirrored: mirrored, clip: clip, lightOverlay: lightOverlay,
                   waterRow: Int(waterRow), rotation: rotation, scale: scale, flash: dynamicLight ? 0 : flash,
                   flashTable: flashTable, occluder: occluder == Occluder() ? nil : occluder, waterKind: waterKind,
                   noWaterSplit: noWaterSplit)
    }
}

/// The Handle a sprite's `+0x4c` names (plan S2, LOCKED). `inert` = the Phase 5 classes (enemies): no Handle
/// built yet and no hit callback; still drawn, idled and erased. `bonus` (BN) = `.HandleBonusSprite` (`BonusSprite`).
public enum SpriteHandler: Equatable, Hashable, Sendable {
    case player, platform, chain, background, box, effect, rope, ropeSegment, inert
    /// W1 (added, Invariant 9): `.HandleSeeSawSegSprite @ 100655c8` (`_DAT_100a01c8`) — the see-saw segments 0x59b
    /// `.SetupSeeSawSegSprite` installs (the player pass's see-saw test, `SpriteWorld.isSeeSawSegment`).
    case seeSawSegment
    /// W2b (added, Invariant 9): `.HandleCannonedSprite @ 10058710` (`PTR_PTR_100a045c`) — the Handle
    /// `.TurnIntoCannoned` installs on a cannon's captive until the launch restores the saved one (`+0x1ec`).
    case cannoned
    /// BN (added, Invariant 9): `.HandleBonusSprite @ 1005e934` (`PTR_PTR_100a047c`), installed by `.SetupBonusSprite`.
    case bonus
    /// CS (added, Invariant 9): `.HandlePlayerShotSprite @ 10059704` (`PTR_PTR_100a04e8`), installed by
    /// `.SetupPlayerShotSprite` (`PlayerShot`).
    case playerShot
    /// PU (added, Invariant 9): `.HandleTrailSprite @ 1004b354` (`PTR_PTR_100a0508`, M l. 42986–42994) =
    /// `.StandardSpriteHandles` + `.StandardSpriteCleanup`, installed by `.SetupTrailSprite` on the player's five
    /// Double-Speed trail sprites (`Player.spawn`).
    case trail
    /// IU (added, Invariant 9): `.HandleHeldItemSprite @ 1004be74` (`PTR_PTR_100a04f8`, M l. 43431–43458), installed by
    /// `.SetupHeldItemSprite` on the player's held-item sprite (`Player.spawn`) and re-installed by `.HandleItemUse` at
    /// c ∉ {3, 4, 5} (`HeldItem`); at c 3…5 the held sprite carries `.playerShot` instead.
    case heldItem
    /// SD (added, Invariant 9): `.HandleShadowSprite @ 1004b4f0` (M l. 43052–43166), installed by `.SetupShadowSprite`
    /// on the Shadow Double 0x1b39 row 11 makes (`ShadowDouble`).
    case shadow
    /// BT (added, Invariant 9): `.HandleButtonSprite @ 10070e60` (`PTR_PTR_100a0ac4`, M l. 61742–61815) with the hit
    /// `.HitButtonSprite @ 100710e4` (`PTR_PTR_100a0ac0`), installed by `.SetupButtonSprite` (`ButtonSprite`).
    case button
    /// SW (added, Invariant 9): `.HandleStatueSprite @ 100664a8` (`PTR_PTR_100a01f8`, M l. 56521–56555), installed by
    /// `.TurnIntoStatue @ 10043138` (M l. 38244–38272) with the Box class's hit `.HitBoxSprite` (`PTR_PTR_100a01f4`) and
    /// tile callback `.HitBoxTileSprite` (`PTR_PTR_100a01f0`) — `StatueSprite`. The enemies' statue sites are Phase 5's.
    case statue
    /// EC (added at once, plan S2, Invariant 9): the enemy Handles — each a named no-op (`EnemyCommon.handle`, drawn like
    /// `.inert`, no hit) until its class's task fills it and maps its `forClass` row. TOC slots (`pef.py tocfunc`):
    /// `.walker` 0x100a0498 (WK1), `.crawler` 04b8 / `.roach` 04a0 (CR), `.dillo` 04b4 (DL), `.bat` 04c4,
    /// `.swarmMember` 0470 and the insect body (BA), `.gremlin` 04a4 / `.floater` 04ac (GF), `.frog` 04a8 /
    /// `.salamander` 049c (FR), `.blob` 04c0, the dead Blob, `.crab` 046c and its segments (BL), `.enemyShot` 0488 (ES),
    /// `.geyserSegment` (`.HandleGeyserSegSprite`, GY), `.warrior` 0494 (◇ LV5, Ruling 3). `.inert` stays for the four
    /// bosses not placed on levels 1–5 (Demon 04b0, Chief 04bc, Wizard 0490, Xichra 048c).
    case walker, crawler, roach, dillo, bat, swarmMember, insectBody, gremlin, floater, frog, salamander, blob,
         deadBlob, crab, crabSegment, enemyShot, geyserSegment, warrior

    /// The Handle the class Setup `.GenerateSprite` selects for `type` installs (`SpriteClassTable`). The player
    /// (`.SetupPlayerSprite`), chain spokes (`.SetupChainSprite`, W1) and rope segments (W3) are set by their makers.
    public static func forClass(type: Int16) -> SpriteHandler {
        switch SpriteClassTable.classify(type: type, p1Negative: false)?.0 {
        case .platform: return .platform
        case .box: return .box
        case .background: return .background
        case .effect: return .effect
        case .rope: return .rope
        case .bonus: return .bonus
        case .button: return .button
        default: return .inert
        }
    }
}
