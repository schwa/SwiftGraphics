import CoreGraphics

public enum Quadrant {
    case minXMinY
    case maxXMinY
    case minXMaxY
    case maxXMaxY
}

public extension Quadrant {
    static func from(point: CGPoint) -> Quadrant {
        if point.y >= 0 {
            if point.x >= 0 {
                return .maxXMaxY
            }
            else {
                return .minXMaxY
            }
        }
        else {
            if point.x >= 0 {
                return .maxXMinY
            }
            else {
                return .minXMinY
            }
        }
    }

    func toPoint() -> CGPoint {
        switch self {
        case .minXMinY:
            return CGPoint(x: -1, y: -1)
        case .maxXMinY:
            return CGPoint(x: 1, y: -1)
        case .minXMaxY:
            return CGPoint(x: -1, y: 1)
        case .maxXMaxY:
            return CGPoint(x: 1, y: 1)
        }
    }

    static func from(point: CGPoint, origin: CGPoint) -> Quadrant {
        Quadrant.from(point: point - origin)
    }

    static func from(point: CGPoint, rect: CGRect) -> Quadrant? {
        // TODO: can be outside
        Quadrant.from(point: point - rect.mid)
    }
}

public extension CGRect {
    func quadrant(_ quadrant: Quadrant) -> CGRect {
        let size = Size(width: size.width * 0.5, height: size.height * 0.5)
        switch quadrant {
        case .minXMinY:
            return CGRect(origin: CGPoint(x: minX, y: minY), size: size)
        case .maxXMinY:
            return CGRect(origin: CGPoint(x: midX, y: minY), size: size)
        case .minXMaxY:
            return CGRect(origin: CGPoint(x: minX, y: midY), size: size)
        case .maxXMaxY:
            return CGRect(origin: CGPoint(x: midX, y: midY), size: size)
        }
    }
}
