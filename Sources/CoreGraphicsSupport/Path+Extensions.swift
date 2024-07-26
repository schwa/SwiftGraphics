import BaseSupport
import SwiftUI

// Treating SwiftUI.Path as part of CoreGraphics

public extension Path {
    init(lines: [CGPoint]) {
        self.init()
        addLines(lines)
    }

    init(lineSegments: [(CGPoint, CGPoint)]) {
        self.init()
        for lineSegment in lineSegments {
            move(to: lineSegment.0)
            addLine(to: lineSegment.1)
        }
    }

    init(vertices: [CGPoint], closed: Bool = false) {
        self.init()

        move(to: vertices[0])
        for vertex in vertices[1 ..< vertices.count] {
            addLine(to: vertex)
        }
        if closed {
            closeSubpath()
        }
    }

    init(strokedLineSegment lineSegment: (CGPoint, CGPoint), width: Double, lineCap: CGLineCap = .butt) {
        let path = Path { path in
            path.move(to: lineSegment.0)
            path.addLine(to: lineSegment.1)
        }
        self = path.strokedPath(StrokeStyle(lineWidth: width, lineCap: lineCap))
    }
}

public extension Path {
    init(paths: [Path]) {
        self.init()
        for path in paths {
            addPath(path)
        }
    }
}

public extension Path {
    mutating func moveTo(x: Double, y: Double, relative: Bool = false) {
        let point = CGPoint(x: x, y: y)
        move(to: relative ? (currentPoint ?? .zero) + point : point)
    }

    mutating func addLineTo(x: Double, y: Double, relative: Bool = false) {
        addLine(to: CGPoint(x: x, y: y), relative: relative)
    }

    mutating func addLine(to point: CGPoint, relative: Bool) {
        addLine(to: relative ? (currentPoint ?? .zero) + point : point)
    }

    mutating func addLine(from: CGPoint, to: CGPoint) {
        move(to: from)
        addLine(to: to)
    }

    mutating func addSCurve(from start: CGPoint, to end: CGPoint) {
        let mid = (end + start) * 0.5

        let c1 = CGPoint(x: mid.x, y: start.y)
        let c2 = CGPoint(x: mid.x, y: end.y)

        move(to: start)
        addQuadCurve(to: mid, control: c1)
        addQuadCurve(to: end, control: c2)
    }
}

public extension Path {
    static func + (lhs: Path, rhs: Path) -> Path {
        var result = lhs
        result.addPath(rhs)
        return result
    }

    static func += (lhs: inout Path, rhs: Path) {
        lhs.addPath(rhs)
    }
}

public extension Path {
    static func rect(x: Double = 0, y: Double = 0, w: Double, h: Double) -> Path {
        Path(CGRect(x: x, y: y, width: w, height: h))
    }

    static func rect(x: Double = 0, y: Double = 0, w: Double, h: Double, r: Double, style: RoundedCornerStyle = .circular) -> Path {
        Path(roundedRect: CGRect(x: x, y: y, width: w, height: h), cornerSize: CGSize(width: r, height: r), style: style)
    }

    static func rect(x: Double = 0, y: Double = 0, w: Double, h: Double, rx: Double, ry: Double, style: RoundedCornerStyle = .circular) -> Path {
        Path(roundedRect: CGRect(x: x, y: y, width: w, height: h), cornerSize: CGSize(width: rx, height: ry), style: style)
    }

    static func circle(center: CGPoint, radius: Double) -> Path {
        Path(ellipseIn: CGRect(center: center, radius: radius))
    }

    static func circle(cx: Double, cy: Double, r: Double) -> Path {
        Path(ellipseIn: CGRect(center: CGPoint(x: cx, y: cy), radius: r))
    }

    static func ellipse(center: CGPoint, radius: CGSize) -> Path {
        Path(ellipseIn: CGRect(center: center, size: radius * 2))
    }

    static func ellipse(center: CGPoint, rx: Double, ry: Double) -> Path {
        ellipse(center: center, radius: CGSize(width: rx, height: ry))
    }

    static func ellipse(cx: Double, cy: Double, rx: Double, ry: Double) -> Path {
        ellipse(center: CGPoint(x: cx, y: cy), radius: CGSize(width: rx, height: ry))
    }

    static func ellipse(cx: Double, cy: Double, r: Double) -> Path {
        ellipse(center: CGPoint(x: cx, y: cy), radius: CGSize(width: r, height: r))
    }

    static func lines(_ lines: [CGPoint], closed: Bool = false) -> Path {
        Path { path in
            path.addLines(lines)
            if closed {
                path.closeSubpath()
            }
        }
    }

    static func line(from: CGPoint, to: CGPoint) -> Path {
        Path { path in
            path.move(to: from)
            path.addLine(to: to)
        }
    }

    static func horizontalLine(from: CGPoint, length: Double) -> Path {
        line(from: from, to: CGPoint(x: from.x + length, y: from.y))
    }

    static func verticalLine(from: CGPoint, length: Double) -> Path {
        line(from: from, to: CGPoint(x: from.x, y: from.y + length))
    }

    // curve
    // arc
    // regular polygon
    // star
    // cross

    static func cross(_ rect: CGRect) -> Path {
        Path { path in
            path.moveTo(x: rect.minX, y: rect.midY)
            path.addLineTo(x: rect.maxX, y: rect.midY)
            path.moveTo(x: rect.midX, y: rect.minY)
            path.addLineTo(x: rect.midX, y: rect.maxY)
        }
    }

    static func saltire(_ rect: CGRect) -> Path {
        Path { path in
            path.moveTo(x: rect.minX, y: rect.minY)
            path.addLineTo(x: rect.maxX, y: rect.maxY)
            path.moveTo(x: rect.minX, y: rect.maxY)
            path.addLineTo(x: rect.maxX, y: rect.minY)
        }
    }

    static func dot(_ point: CGPoint, radius: Double = 4) -> Path {
        Path.circle(center: point, radius: radius)
    }

    static func dots(_ dots: [CGPoint], radius: Double = 4) -> Path {
        Path { path in
            for dot in dots {
                path.addEllipse(in: CGRect(center: dot, radius: radius))
            }
        }
    }

    static func star(points: Int, innerRadius: Double, outerRadius: Double) -> Path {
        var path = Path()
        assert(points > 1, "Number of points should be greater than 1 for a star")
        var angle = -0.5 * .pi // Starting from the top
        for n in 0 ..< points * 2 {
            let radius = n.isMultiple(of: 2) ? outerRadius : innerRadius
            let point = CGPoint(x: radius * cos(angle), y: radius * sin(angle))
            if path.isEmpty {
                path.move(to: point)
            }
            else {
                path.addLine(to: point)
            }
            angle += .pi / Double(points)
        }
        path.closeSubpath()
        return path
    }
}

public extension Path {
    func scaled(x: CGFloat, y: CGFloat) -> Path {
        let transform = CGAffineTransform(translationX: -boundingRect.midX, y: -boundingRect.midY)
            .concatenating(CGAffineTransform(scaleX: x, y: y))
            .concatenating(CGAffineTransform(translationX: boundingRect.midX, y: boundingRect.midY))
        return applying(transform)
    }
}

public extension Path {
    var polygonalChains: [[CGPoint]] {
        var polygons: [[CGPoint]] = []
        var current: [CGPoint] = []
        var lastPoint: CGPoint?
        for element in elements {
            switch element {
            case .move(let point):
                current.append(point)
                lastPoint = point
            case .line(let point):
                if current.isEmpty {
                    current = [lastPoint ?? .zero]
                }
                current.append(point)
                lastPoint = point
            case .quadCurve:
                unimplemented()
            case .curve:
                unimplemented()
            case .closeSubpath:
                if let first = current.first {
                    current.append(first)
                    polygons.append(current)
                }
                current = []
            }
        }
        if !current.isEmpty {
            polygons.append(current)
        }
        return polygons
    }
}

public extension Path {
    var elements: [Element] {
        var elements: [Element] = []
        forEach { elements.append($0) }
        return elements
    }

    init(elements: [Element]) {
        self = Path { path in
            for element in elements {
                switch element {
                case .move(let point):
                    path.move(to: point)
                case .line(let point):
                    path.addLine(to: point)
                case .quadCurve(let to, let control):
                    path.addQuadCurve(to: to, control: control)
                case .curve(let to, let control1, let control2):
                    path.addCurve(to: to, control1: control1, control2: control2)
                case .closeSubpath:
                    path.closeSubpath()
                }
            }
        }
    }
}

public extension Path {
    struct Corners: OptionSet, Sendable {
        public let rawValue: UInt8

        public static let topLeft = Self(rawValue: 0b0001)
        public static let topRight = Self(rawValue: 0b0010)
        public static let bottomLeft = Self(rawValue: 0b0100)
        public static let bottomRight = Self(rawValue: 0b1000)

        public static let all: Corners = [.topLeft, .topRight, .bottomLeft, .bottomRight]

        public init(rawValue: UInt8) {
            self.rawValue = rawValue
        }
    }

    init(roundedRect rect: CGRect, cornerRadius: CGFloat, style: RoundedCornerStyle = .circular, corners: Corners) {
        let elements = Path(roundedRect: rect, cornerRadius: cornerRadius, style: style).elements

        assert(elements.count == 10)

        self = Path(elements: elements
                        .enumerated()
                        // swiftlint:disable:next closure_body_length
                        .map { index, element in
                            let corner: Corners
                            switch (index, element) {
                            case (2, .curve):
                                corner = .bottomRight
                            case (4, .curve):
                                corner = .bottomLeft
                            case (6, .curve):
                                corner = .topLeft
                            case (8, .curve):
                                corner = .topRight
                            default:
                                return element
                            }
                            if !corners.contains(corner) {
                                switch corner {
                                case .topLeft:
                                    return .line(to: rect.minXMinY)
                                case .topRight:
                                    return .line(to: rect.maxXMinY)
                                case .bottomLeft:
                                    return .line(to: rect.minXMaxY)
                                case .bottomRight:
                                    return .line(to: rect.maxXMaxY)
                                default:
                                    unreachable()
                                }
                            }
                            else {
                                return element
                            }
                        })
    }
}

public extension Path {
    static func arc(center: CGPoint, radius: CGFloat, midAngle: SwiftUI.Angle, width: SwiftUI.Angle) -> Path {
        Path { path in
            path.move(to: center)
            path.addArc(center: center, radius: radius, startAngle: midAngle - width / 2, endAngle: midAngle + width / 2, clockwise: false)
            path.closeSubpath()
        }
    }
}
