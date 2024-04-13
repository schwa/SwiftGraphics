import CoreGraphicsSupport
import Foundation
import SwiftUI

public extension Path {
    init(lines: [CGPoint]) {
        self = Path { path in
            path.addLines(lines)
        }
    }

    @available(*, deprecated, message: "REMOVE")
    init(lineSegment: (CGPoint, CGPoint), width: Double, lineCap: CGLineCap) {
        self = Path { path in
            let radius = width / 2
            let angle = CGPoint.angle(lineSegment.0, lineSegment.1)
            //            path.move(to: line.0 + CGPoint(distance: radius, angle: angle - .degrees(90)))
            path.addRelativeArc(center: lineSegment.0, radius: radius, startAngle: angle + .degrees(90), delta: .degrees(180))
            path.addLine(to: lineSegment.1 + CGPoint(distance: radius, angle: angle - .degrees(90)))
            path.addRelativeArc(center: lineSegment.1, radius: radius, startAngle: angle - .degrees(90), delta: .degrees(180))
            path.addLine(to: lineSegment.0 + CGPoint(distance: radius, angle: angle + .degrees(90)))
            path.closeSubpath()
        }
    }

    init(paths: [Path]) {
        self.init()
        for path in paths {
            self.addPath(path)
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

    static func + (lhs: Path, rhs: Path) -> Path {
        var result = lhs
        result.addPath(rhs)
        return result
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

    static func dots(_ dots: [CGPoint], radius: Double) -> Path {
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
            let radius = n % 2 == 0 ? outerRadius : innerRadius
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
    var elements: [Path.Element] {
        var elements: [Path.Element] = []
        forEach { element in
            elements.append(element)
        }
        return elements
    }
}

public extension Path {
    var polygonalChains: [PolygonalChain] {
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
                fatalError()
            case .curve:
                fatalError()
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
        return polygons.map { .init(vertices: $0) }
    }

}
