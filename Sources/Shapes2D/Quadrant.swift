import CoreGraphics
import CoreGraphicsSupport

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
                .maxXMaxY
            } else {
                .minXMaxY
            }
        } else {
            if point.x >= 0 {
                .maxXMinY
            } else {
                .minXMinY
            }
        }
    }

    func toPoint() -> CGPoint {
        switch self {
        case .minXMinY:
            CGPoint(x: -1, y: -1)
        case .maxXMinY:
            CGPoint(x: 1, y: -1)
        case .minXMaxY:
            CGPoint(x: -1, y: 1)
        case .maxXMaxY:
            CGPoint(x: 1, y: 1)
        }
    }

    static func from(point: CGPoint, origin: CGPoint) -> Quadrant {
        Quadrant.from(point: point - origin)
    }

    static func from(point: CGPoint, rect: CGRect) -> Quadrant? {
        if !rect.contains(point) {
            return nil
        }
        return Quadrant.from(point: point - rect.mid)
    }
}

public extension CGRect {
    func quadrant(_ quadrant: Quadrant) -> CGRect {
        let size = CGSize(width: size.width * 0.5, height: size.height * 0.5)
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
