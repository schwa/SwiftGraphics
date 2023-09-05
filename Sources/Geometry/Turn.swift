// TODO: Should be clockwise or anticlockwise
public enum Turn: Int {
    case left = 1
    case none = 0
    case right = -1
}

public extension Turn {
    // TODO: Swift 1.2 - can no longer init() enums via custom init methods. Workaround is to make the init failable. Fix this in fufture.
    init<Point: PointType>(_ p: Point, _ q: Point, _ r: Point) {
        // let c = (q.x - p.x) * (r.y - p.y) - (r.x - p.x) * (q.y - p.y)
        let c1 = (q.x - p.x) * (r.y - p.y)
        let c2 = (r.x - p.x) * (q.y - p.y)
        let c = c1 - c2
        let turn: Turn = c == 0 ? .none : (c > 0 ? .left : .right)
        self = turn
    }
}

extension Turn: Comparable {
    public static func < (lhs: Turn, rhs: Turn) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

extension Turn: CustomStringConvertible {
    public var description: String {
        switch self {
        case .none:
            return "none"
        case .left:
            return "left"
        case .right:
            return "right"
        }
    }
}
