/// The two resource-search chains the original walks (plan S2). Search stops at the first file that
/// holds the (type, id); the order below is the whole contract.
public enum ResourceChain: Sendable, Equatable {
    /// Sprites → Sounds → Titles → app (engine §2, rendering §4).
    case frontEnd
    /// World → Backgrounds → Sprites → Sounds → Titles → app (sprites-backgrounds §1).
    case level
}
