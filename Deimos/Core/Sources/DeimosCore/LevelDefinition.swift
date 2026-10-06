import Foundation
import HectorResources

/// A level (`leve`, G_Level.cc; bank waves-and-enemies.md §1, level-scroll-objects.md §6.1), parsed as
/// `FUN_100122f0(buf, levelInfo, objectList)`: the header keys in reader call order, then — only when
/// an object list is passed — `numObjects` 0x18-byte placements. Always de-obfuscated. Token errors are
/// reported (no strict mode for `leve` in the bank), never thrown.
public struct LevelDefinition: Sendable, Equatable {
    /// One placement (0x18 bytes, `FUN_1004d320(0x18)`).
    public struct Object: Sendable, Equatable {
        /// `#unit_ID` (+0x00; read into a stack local first and checked against the `unde` tags)
        public var unit: FourCC = .none
        /// `#layer_ID` (+0x04; `air ` / `grnd` — never read at run time, level-scroll-objects.md §6.1)
        public var layer: FourCC = .none
        /// `#xLoc_INT` (+0x08)
        public var xLoc: Int32 = 0
        /// `#yLoc_INT` (+0x0c; map row, 0 = top)
        public var yLoc: Int32 = 0
        /// `#headingDegrees_INT` (+0x10)
        public var headingDegrees: Int32 = 0
        /// `#isStationary_BOOL` (+0x14)
        public var isStationary = false
        /// `#enableTerrainEffects_BOOL` (+0x15)
        public var enableTerrainEffects = false

        public init() {}
    }

    /// The leve tag ID (not part of the original's level info).
    public var id: FourCC = .none
    /// `#name_STR` (+0x000, ≤ 0x20)
    public var name: String = ""
    /// `#indentifier_STR` (sic; +0x020, ≤ 0x40) — matched by the level-order table
    public var indentifier: String = ""
    /// `#description_STR` (+0x078, ≤ 0x100)
    public var description: String = ""
    /// `#copyright_STR` (+0x178, ≤ 0x100)
    public var copyright: String = ""
    /// `#background_RECT` (+0x060), text (left, top, right, bottom)
    public var background = MacRect(top: 0, left: 0, bottom: 0, right: 0)
    /// `#backgroundImage_ID` (+0x070) — `im16` map
    public var backgroundImage: FourCC = .none
    /// `#previewImage_ID` (+0x074) — `im16` preview
    public var previewImage: FourCC = .none
    /// `#music_ID` (+0x27c) — `soun`
    public var music: FourCC = .none
    /// `#mediaMask_ID` (+0x280) — `im16` media mask
    public var mediaMask: FourCC = .none
    /// `#briefing_ID` (+0x284)
    public var briefing: FourCC = .none
    /// `#numObjects_INT` (+0x278) — after the object pass, decremented once per dropped object.
    public var numObjects: Int32 = 0
    /// The placements kept, file order (empty for a header-only parse).
    public var objects: [Object] = []
    /// Non-fatal log lines (dropped objects). Not part of the original's struct.
    public var notes: [String] = []

    public init() {}

    /// Header and objects. Object loop (`1001257c…1001258c`): `numObjects` is re-read every iteration;
    /// an object whose unit is not an `unde` tag is dropped (logged) AND `numObjects` is decremented
    /// while the index still advances — so each dropped object also loses the file's last object
    /// (level-scroll-objects.md §6.1 landmine).
    public static func parse(id: FourCC, text raw: [UInt8], unitExists: (FourCC) -> Bool)
        -> (LevelDefinition, errors: [String]) {
        parse(id: id, text: raw, objects: true, unitExists: unitExists)
    }

    /// Header only (`objectList == 0`: the order list and the level-select screen) — objects not built.
    public static func parseHeaderOnly(id: FourCC, text raw: [UInt8]) -> (LevelDefinition, errors: [String]) {
        parse(id: id, text: raw, objects: false, unitExists: { _ in true })
    }

    private static func parse(id: FourCC, text raw: [UInt8], objects buildObjects: Bool,
                              unitExists: (FourCC) -> Bool) -> (LevelDefinition, errors: [String]) {
        var p = DefinitionReader(DeimosText.decodeCString(raw))
        var l = LevelDefinition()
        l.id = id
        p.str(&l.name, "#name_STR", maxLength: 0x20)
        p.str(&l.indentifier, "#indentifier_STR", maxLength: 0x40)
        p.str(&l.description, "#description_STR", maxLength: 0x100)
        p.str(&l.copyright, "#copyright_STR", maxLength: 0x100)
        p.rect(&l.background, "#background_RECT")
        p.id(&l.backgroundImage, "#backgroundImage_ID")
        p.id(&l.previewImage, "#previewImage_ID")
        p.id(&l.music, "#music_ID")
        p.id(&l.mediaMask, "#mediaMask_ID")
        p.id(&l.briefing, "#briefing_ID")
        p.int(&l.numObjects, "#numObjects_INT")
        if buildObjects {
            var i: Int32 = 0
            while i < l.numObjects {
                var o = Object()
                p.id(&o.unit, "#unit_ID")
                if unitExists(o.unit) {
                    p.id(&o.layer, "#layer_ID")
                    p.int(&o.xLoc, "#xLoc_INT")
                    p.int(&o.yLoc, "#yLoc_INT")
                    p.int(&o.headingDegrees, "#headingDegrees_INT")
                    p.bool(&o.isStationary, "#isStationary_BOOL")
                    p.bool(&o.enableTerrainEffects, "#enableTerrainEffects_BOOL")
                    l.objects.append(o)
                } else {
                    // This port's own line (the bank records no log in the parser for this case).
                    l.notes.append("object \(i): unit '\(o.unit)' is not an unde tag — dropped, numObjects decremented")
                    l.numObjects -= 1
                }
                i += 1
            }
        }
        return (l, p.errors)
    }
}
