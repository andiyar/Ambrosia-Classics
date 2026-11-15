import Foundation
@testable import DeimosCore

/// The campaign bundle's own data locator and asset cache (plan standing rule 4): the committed
/// `Resources/Deimos/Data`, or `DEIMOS_DATA` when set. A missing directory or record is a failure that names the path
/// — never a skip. The assets and the twelve levels (definitions and masks) are loaded once per test process and
/// handed to every session (`DeimosSession.init(… levels:)`).
enum CampaignTestData {
    struct Missing: Error, CustomStringConvertible {
        let description: String
    }

    static let directory: Result<URL, Error> = Result { try DeimosData.dataDirectory() }

    static let assets: Result<DeimosAssets, Error> = Result {
        try DeimosAssets.load(index: TagIndex(dataDirectory: directory.get()))
    }

    static let levels: Result<LevelSet, Error> = Result { try LevelSet(assets: assets.get()) }

    static func getAssets() throws -> DeimosAssets { try assets.get() }

    static func getLevels() throws -> LevelSet { try levels.get() }

    /// The decoded text of the `type` record `id` (as its parser reads it), or a failure naming the data path.
    static func text(type: String, id: FourCC) throws -> [UInt8] {
        let assets = try getAssets()
        guard let t = FourCC(type), let record = assets.index.record(type: t, id: id) else {
            throw Missing(description: "no \(type) record '\(id)' in \(try directory.get().path)")
        }
        let raw = [UInt8](try assets.index.data(for: record))
        switch type {
        case "unde": return DefinitionReader.plainText(raw, unlessContains: "#name_STR")   // UnitDefinition.parse
        case "wede": return DefinitionReader.plainText(raw, unlessContains: "#type_ID")    // WeaponDefinition.parse
        default: return DeimosText.decodeCString(raw)                                     // PlayerDefinition.parse
        }
    }
}
