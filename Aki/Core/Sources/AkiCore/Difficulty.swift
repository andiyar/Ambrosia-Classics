/// The game difficulty, `_p`+0x20c (docs/aki/file-formats.md §2.2): 0 Hard, 1 Medium, 2 Easy, 3 Practice.
public enum Difficulty: Int16, CaseIterable, Sendable {
    case hard = 0, medium = 1, easy = 2, practice = 3

    /// The map's difficulty step up (`_SelectMenuOptions`): wraps Practice → Hard.
    public var next: Difficulty { Difficulty(rawValue: rawValue + 1) ?? .hard }

    /// The map's difficulty step down: wraps Hard → Practice.
    public var previous: Difficulty { Difficulty(rawValue: rawValue - 1) ?? .practice }
}
