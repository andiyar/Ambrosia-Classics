import Foundation
import HectorResources

/// The three resource files the original opened (plan S2): the application's fork `Cythera.rsrc`, the
/// scenario file's fork `Cythera Data.rsrc`, the documentation viewer's `Cythera Documentation.rsrc` —
/// all stored as data-fork resource maps (INDEX "Resource census") — plus the segment file's location.
public struct CytheraResources {
    public let app: ResourceCollection
    public let data: ResourceCollection
    public let documentation: ResourceCollection
    /// `Cythera Data`, the segment file (data-format §1).
    public let segmentFileURL: URL

    /// Opens the three resource maps through `ResourceReader.read(fileAt:)`. Every file (the segment file
    /// included) is checked before any is parsed, so a missing one is named, not masked.
    public init(directory: URL) throws {
        let fm = FileManager.default
        let dir = directory.resolvingSymlinksInPath()
        for name in [CytheraData.appFile, CytheraData.dataResourceFile, CytheraData.documentationFile,
                     CytheraData.segmentFile]
        where !CytheraData.isFile(dir.appendingPathComponent(name).resolvingSymlinksInPath(), fm) {
            throw CytheraDataError.notFound(name)
        }

        func load(_ name: String) throws -> ResourceCollection {
            let url = dir.appendingPathComponent(name).resolvingSymlinksInPath()
            guard let collection = try ResourceReader.read(fileAt: url) else {
                throw CytheraDataError.notFound("\(name) (not a resource map)")
            }
            return collection
        }
        app = try load(CytheraData.appFile)
        data = try load(CytheraData.dataResourceFile)
        documentation = try load(CytheraData.documentationFile)
        segmentFileURL = dir.appendingPathComponent(CytheraData.segmentFile)
    }

    /// The scenario file first, then the application: the original opened the scenario file after the
    /// application, so `GetResource` searched it first (app-shell.md §1.3, HIGH for the chain; MED for
    /// which of the two different `clut 256` the original's chain returned — plan Research note 12).
    /// The documentation file is the viewer's own and is not on this chain.
    public func resource(type: String, id: Int16) -> Resource? {
        data.resource(type: type, id: id) ?? app.resource(type: type, id: id)
    }
}
