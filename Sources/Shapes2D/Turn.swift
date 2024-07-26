import CoreGraphics

public enum Turn: Int {
    case left = 1
    case none = 0
    case right = -1
}

public extension Turn {
    init(_ p: CGPoint, _ q: CGPoint, _ r: CGPoint) {
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
            "none"
        case .left:
            "left"
        case .right:
            "right"
        }
    }
}
