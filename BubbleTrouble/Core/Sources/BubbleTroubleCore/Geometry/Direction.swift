/// The four movement directions with the original's numbering (1 up, 2 down, 3 left, 4 right).
public enum Direction: Int8, Sendable {
    case up = 1, down = 2, left = 3, right = 4

    public var opposite: Direction {
        switch self {
        case .up: .down
        case .down: .up
        case .left: .right
        case .right: .left
        }
    }
}
