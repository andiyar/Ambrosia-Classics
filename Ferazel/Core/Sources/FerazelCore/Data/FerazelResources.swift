import Foundation
import HectorResources

/// The six opened resource files and the music folder (plan S2). Music tracks are the files named
/// `NN` in `musicDirectory` (AIFC; decoded by a later task, not here).
public struct FerazelResources {
    public let app: ResourceCollection
    public let world: ResourceCollection
    public let backgrounds: ResourceCollection
    public let sprites: ResourceCollection
    public let sounds: ResourceCollection
    public let titles: ResourceCollection
    public let musicDirectory: URL

    public init(app: ResourceCollection, world: ResourceCollection, backgrounds: ResourceCollection,
                sprites: ResourceCollection, sounds: ResourceCollection, titles: ResourceCollection,
                musicDirectory: URL) {
        self.app = app
        self.world = world
        self.backgrounds = backgrounds
        self.sprites = sprites
        self.sounds = sounds
        self.titles = titles
        self.musicDirectory = musicDirectory
    }

    /// The first file on `chain` that holds (type, id), or nil.
    public func resource(type: String, id: Int16, chain: ResourceChain) -> Resource? {
        for file in files(on: chain) {
            if let r = file.resource(type: type, id: id) { return r }
        }
        return nil
    }

    func files(on chain: ResourceChain) -> [ResourceCollection] {
        switch chain {
        case .frontEnd: return [sprites, sounds, titles, app]
        case .level: return [world, backgrounds, sprites, sounds, titles, app]
        }
    }
}
