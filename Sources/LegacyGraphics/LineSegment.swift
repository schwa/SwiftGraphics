import CoreGraphics
import LegacyGeometry

public struct LineSegment {
    public enum LineEnd {
        case first
        case second
    }

    public var first: CGPoint
    public var second: CGPoint

    public init(first: CGPoint, second: CGPoint) {
        self.first = first
        self.second = second
    }
}

extension LineSegment: Equatable {
    public static func == (lhs: LineSegment, rhs: LineSegment) -> Bool {
        lhs.first == rhs.first && lhs.second == rhs.second
    }
}

extension LineSegment: Hashable {
    public func hash(into hasher: inout Hasher) {
        first.x.hash(into: &hasher)
        first.y.hash(into: &hasher)
        second.x.hash(into: &hasher)
        second.y.hash(into: &hasher)
    }
}

public extension LineSegment {
    var points: [CGPoint] {
        [first, second]
    }
}

public extension LineSegment {
    func containsPoint(_ point: CGPoint) -> Bool {
        if first.x != second.x { // self is not vertical
            if first.x <= point.x && point.x <= second.x {
                return true
            }
            else if first.x >= point.x && point.x >= second.x {
                return true
            }
        }
        else { // self is vertical, so test y coordinate
            if first.y <= point.y && point.y <= second.y {
                return true
            }
            else if first.y >= point.y && point.y >= second.y {
                return true
            }
        }
        return false
    }
}

public extension LineSegment {
    var length: CGFloat {
        first.distance(to: second)
    }

    // TODO: Replace with enum?
    var slope: CGFloat? {
        if second.x == first.x {
            return nil
        }
        return (second.y - first.y) / (second.x - first.x)
    }

    var angle: CGFloat {
        (second - first).angle
    }

    func isParallel(other: LineSegment) -> Bool {
        slope == other.slope
    }

    func containsPoint(point: CGPoint) -> Bool {
        if first.x != second.x { // self is not vertical
            if first.x <= point.x && point.x <= second.x {
                return true
            }
            else if first.x >= point.x && point.x >= second.x {
                return true
            }
        }
        else { // self is vertical, so test y coordinate
            if first.y <= point.y && point.y <= second.y {
                return true
            }
            else if first.y >= point.y && point.y >= second.y {
                return true
            }
        }
        return false
    }

    var midpoint: CGPoint {
        (first + second) * 0.5
    }

    func rotated(angle: CGFloat) -> LineSegment {
        let transform = CGAffineTransform(rotation: angle)
        return LineSegment(first: first.applying(transform), second: second.applying(transform))
    }
}
