import Foundation

/// A light face as Core holds it: `.Load1LightFaceFromPICT(pict, width, height)` — a reference, no pixels (plan
/// Invariant 1; FerazelRender loads the face, `LightFace.load`). `width` is the face's `+0x50`, `height` its `+0x54`.
public struct LightFaceRef: Equatable, Hashable, Sendable {
    public let pict: Int16
    public let width: Int
    public let height: Int

    public init(pict: Int16, width: Int, height: Int) {
        self.pict = pict
        self.width = width
        self.height = height
    }
}

/// The 200 light slots at `_DAT_100a0128` (0x30 bytes each) and their count `*_DAT_100a0124` (lighting-tables §7.4;
/// plan S2, LT) — Core's game state, the single source of truth: every `.AddLight`, `.RemoveLight`, `.ChangeLight*`,
/// `.SetLightPos` and `.HandleLights` of the binary is a call on this table at its call site. FerazelRender receives it
/// once per `.PaintFrameWrap` (`DrawOp.lightTable`) and runs the same `handleLights()` on its copy. The row-redraw
/// countdown `*_DAT_100a012c` that `.HandleLights` also reads is FerazelRender's (it has no writer in the binary).
public struct LightTable: Equatable, Sendable {
    public static let slotCount = 200

    /// One 0x30-byte slot.
    public struct Slot: Equatable, Sendable {
        /// `+0x00`.
        public var active = false
        /// `+0x01` (read by `.HasLightChanged`).
        public var isNew = false
        /// `+0x02`: removal pending — `+0` clears on the next `.HandleLights`.
        public var removing = false
        /// `+0x04`.
        public var face: LightFaceRef?
        /// `+0x08`.
        public var previousFace: LightFaceRef?
        /// `+0x0c` / `+0x0e`: the point (v, h).
        public var y: Int16 = 0
        public var x: Int16 = 0
        /// `+0x10` / `+0x12`.
        public var previousY: Int16 = 0
        public var previousX: Int16 = 0
        /// `+0x14`: the face width (`+0x50`) >> 1.
        public var radius: Int16 = 0
        /// `+0x16`.
        public var previousRadius: Int16 = 0
        /// `+0x18`: the colour group's first table row (g·11, lighting-tables §7.3).
        public var colour: Int16 = 0
        /// `+0x1a`.
        public var previousColour: Int16 = 0
        /// `+0x1c` / `+0x20`: the point ·256.
        public var x256: Int32 = 0
        public var y256: Int32 = 0
        /// `+0x24` / `+0x28`: the speed (·256 per frame).
        public var vx: Int32 = 0
        public var vy: Int32 = 0
        /// `+0x2c`: added to `vy` each `.HandleLights`.
        public var accelY: Int32 = 0

        public init() {}
    }

    /// `_DAT_100a0128`.
    public private(set) var slots = [Slot](repeating: Slot(), count: LightTable.slotCount)
    /// `*_DAT_100a0124`: +1 per `.AddLight`, −1 per in-range `.RemoveLight`, 0 after `.RemoveAllLights`.
    public private(set) var count: Int16 = 0

    /// A fresh table (= `.RemoveAllLights` over zeroed memory).
    public init() {}

    /// `(short)(*(int *)(face + 0x50) >> 1)`.
    private static func radius(_ f: LightFaceRef) -> Int16 { Int16(truncatingIfNeeded: f.width >> 1) }

    /// `.AddLight(face, (y, x), vx, vy, accelY, colour) @ 1001bc08` (M l. 14275–14322; raw `1001bc08..1001bd14`): the
    /// loop stores `i` and jumps to 200 at the first slot whose `+0` is 0, so the **first** free slot (a slot pending
    /// removal still has `+0` = 1 and is not free). With a nil face or no free slot: `ReportError(…, 200)`, nothing
    /// stored — and the return is still that index (`or r3,r31,r31` after either path): −1 when full, the first free
    /// slot when only the face is nil. Otherwise `+0 = 1`, `+1 = 1`, `+2 = 0`, `+4` face, `+0x18` colour, `+8` nil,
    /// `+0x14` = width >> 1, `+0xc` the point, `+0x24/+0x28/+0x2c` the speeds (sign-extended shorts), `+0x1c = x << 8`,
    /// `+0x20 = y << 8`, count + 1.
    @discardableResult
    public mutating func add(face: LightFaceRef?, x: Int16, y: Int16, vx: Int16, vy: Int16, accelY: Int16,
                             colour: Int16) -> Int16 {
        guard let i = slots.firstIndex(where: { !$0.active }) else { return -1 }
        guard let face else { return Int16(i) }
        var s = slots[i]
        s.active = true
        s.isNew = true
        s.removing = false
        s.face = face
        s.colour = colour
        s.previousFace = nil
        s.radius = Self.radius(face)
        s.y = y
        s.x = x
        s.vx = Int32(vx)
        s.vy = Int32(vy)
        s.accelY = Int32(accelY)
        s.x256 = Int32(x) << 8
        s.y256 = Int32(y) << 8
        slots[i] = s
        count &+= 1
        return Int16(i)
    }

    /// `.RemoveLight(&slot) @ 1001bd34` (M l. 14326–14348): a slot in 0…199 → `+2 = 1`, `+4` nil, `+0x14 = 0`, count − 1
    /// (`+0` stays until the next `.HandleLights`); always `slot = −1`.
    public mutating func remove(_ slot: inout Int16) {
        if (0..<Self.slotCount).contains(Int(slot)) {
            let i = Int(slot)
            slots[i].removing = true
            slots[i].face = nil
            slots[i].radius = 0
            count &-= 1
        }
        slot = -1
    }

    /// `.ChangeLightFace(slot, face) @ 1001bdbc` (M l. 14351–14372): `+4` face, `+0x14` = width >> 1; a slot outside
    /// 0…199 is ignored. (The binary dereferences the face unchecked — a nil face is a later phase's call site.)
    public mutating func changeFace(_ slot: Int16, _ face: LightFaceRef) {
        guard (0..<Self.slotCount).contains(Int(slot)) else { return }
        slots[Int(slot)].face = face
        slots[Int(slot)].radius = Self.radius(face)
    }

    /// `.SetLightPos(slot, x, y) @ 1001be18` (M l. 14375–14396): `+0x1c = x << 8`, `+0x20 = y << 8`, `+0xe = x`,
    /// `+0xc = y`; a slot outside 0…199 is ignored.
    public mutating func setPos(_ slot: Int16, x: Int16, y: Int16) {
        guard (0..<Self.slotCount).contains(Int(slot)) else { return }
        let i = Int(slot)
        slots[i].x256 = Int32(x) << 8
        slots[i].y256 = Int32(y) << 8
        slots[i].x = x
        slots[i].y = y
    }

    /// `.ChangeLightSpeed(slot, vx, vy) @ 1001be7c` (M l. 14399–14418): `+0x24`, `+0x28` (32-bit); a slot outside
    /// 0…199 is ignored.
    public mutating func changeSpeed(_ slot: Int16, vx: Int32, vy: Int32) {
        guard (0..<Self.slotCount).contains(Int(slot)) else { return }
        slots[Int(slot)].vx = vx
        slots[Int(slot)].vy = vy
    }

    /// `.ChangeLightColor(slot, colour) @ 1001becc` (M l. 14421–14435): `+0x18`; a slot outside 0…199 is ignored.
    public mutating func changeColor(_ slot: Int16, _ colour: Int16) {
        guard (0..<Self.slotCount).contains(Int(slot)) else { return }
        slots[Int(slot)].colour = colour
    }

    /// `.RemoveAllLights @ 1001bf18` (M l. 14439–14486): for every slot `+0 = 0`, `+2 = 0`, `+4 = nil`, `+0x14 = 0`
    /// (the other fields keep their contents), then the count 0. Called by `.SetupLevel` (M l. 2269, and through
    /// `.InitLighting`, M l. 13611) before `.SetupLevelSprites`.
    public mutating func removeAll() {
        for i in slots.indices {
            slots[i].active = false
            slots[i].removing = false
            slots[i].face = nil
            slots[i].radius = 0
        }
        count = 0
    }

    /// The slot loop of `.HandleLights @ 1001bff0` (M l. 14488–14520): every active slot — pending removal → `+0 = 0`;
    /// else `+1 = 0`, the previous fields ← the current face, point, radius and colour, `x256 += vx`, `y256 += vy`,
    /// `vy += accelY`, and the point = (`x256 >> 8`, `y256 >> 8`) as shorts. (Its row redraws from `*_DAT_100a012c`
    /// are FerazelRender's.)
    public mutating func handleLights() {
        for i in slots.indices where slots[i].active {
            if slots[i].removing {
                slots[i].active = false
                continue
            }
            var s = slots[i]
            s.isNew = false
            s.previousFace = s.face
            s.previousY = s.y
            s.previousX = s.x
            s.previousRadius = s.radius
            s.previousColour = s.colour
            s.x256 = s.x256 &+ s.vx
            s.y256 = s.y256 &+ s.vy
            s.vy = s.vy &+ s.accelY
            // `(short)((uint)x256 >> 8)`: bits 8…23 — the same as an arithmetic shift truncated to 16 bits.
            s.x = Int16(truncatingIfNeeded: s.x256 >> 8)
            s.y = Int16(truncatingIfNeeded: s.y256 >> 8)
            slots[i] = s
        }
    }
}
