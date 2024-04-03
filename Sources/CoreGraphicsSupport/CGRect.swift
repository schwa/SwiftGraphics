import CoreGraphics

// MARK: CGRect

public extension CGRect {
    init(width: CGFloat, height: CGFloat) {
        self.init(x: 0, y: 0, width: width, height: height)
    }

    init(minX: CGFloat, minY: CGFloat, maxX: CGFloat, maxY: CGFloat) {
        self.init(x: min(minX, maxX), y: min(minY, maxY), width: abs(maxX - minX), height: abs(maxY - minY))
    }

    init(center: CGPoint, size: CGSize) {
        self.init(x: center.x - size.width * 0.5, y: center.y - size.height * 0.5, width: size.width, height: size.height)
    }

    init(center: CGPoint, radius: CGFloat) {
        self.init(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
    }

    init(points: (CGPoint, CGPoint)) {
        let r0 = Self(center: points.0, size: CGSize.zero)
        let r1 = Self(center: points.1, size: CGSize.zero)
        self = r0.union(r1)
    }
}

extension CGRect: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: CGFloat...) {
        assert(elements.count == 4)
        self = CGRect(x: elements[0], y: elements[1], width: elements[2], height: elements[3])
    }
}

public extension CGRect {
    // Note: Rename "Position" to something else?
    enum Position {
        case minXMinY
        case minXMaxY
        case maxXMinY
        case maxXMaxY

        case minXMidY
        case maxXMidY

        case midXMinY
        case midXMaxY

        case midXMidY
    }

    func point(for position: Position) -> CGPoint {
        switch position {
        case .minXMinY:
            minXMinY
        case .minXMaxY:
            minXMaxY
        case .maxXMinY:
            maxXMinY
        case .maxXMaxY:
            maxXMaxY
        case .minXMidY:
            minXMidY
        case .maxXMidY:
            maxXMidY
        case .midXMinY:
            midXMinY
        case .midXMaxY:
            midXMaxY
        case .midXMidY:
            midXMidY
        }
    }
}

// MARK: -

public extension CGRect {
    var mid: CGPoint {
        CGPoint(x: midX, y: midY)
    }

    var minXMinY: CGPoint {
        CGPoint(x: minX, y: minY)
    }

    var minXMidY: CGPoint {
        CGPoint(x: minX, y: midY)
    }

    var minXMaxY: CGPoint {
        CGPoint(x: minX, y: maxY)
    }

    var midXMinY: CGPoint {
        CGPoint(x: midX, y: minY)
    }

    var midXMidY: CGPoint {
        CGPoint(x: midX, y: midY)
    }

    var midXMaxY: CGPoint {
        CGPoint(x: midX, y: maxY)
    }

    var maxXMinY: CGPoint {
        CGPoint(x: maxX, y: minY)
    }

    var maxXMidY: CGPoint {
        CGPoint(x: maxX, y: midY)
    }

    var maxXMaxY: CGPoint {
        CGPoint(x: maxX, y: maxY)
    }
}

