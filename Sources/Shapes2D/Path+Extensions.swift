import CoreGraphicsSupport
import Foundation
import SwiftUI

public extension Path {
    init(lines: [CGPoint]) {
        self = Path { path in
            path.addLines(lines)
        }
    }

    init(lineSegment: (CGPoint, CGPoint)) {
        self = Path { path in
            path.move(to: lineSegment.0)
            path.addLine(to: lineSegment.1)
        }
    }

    init(lineSegment: (CGPoint, CGPoint), width: CGFloat, lineCap: CGLineCap) {
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

    static func circle(center: CGPoint, radius: CGFloat) -> Path {
        Path(ellipseIn: CGRect(center: center, radius: radius))
    }

    init(lineSegment: LineSegment) {
        self = Path { path in
            path.move(to: lineSegment.start)
            path.addLine(to: lineSegment.end)
        }
    }


    static func line(from: CGPoint, to: CGPoint) -> Path {
        .init(lines: [from, to])
    }

    static func horizontalLine(from: CGPoint, length: CGFloat) -> Path {
        .init(lines: [from, from + [length, 0]])
    }

    static func verticalLine(from: CGPoint, length: CGFloat) -> Path {
        .init(lines: [from, from + [0, length]])
    }

    static func + (lhs: Path, rhs: Path) -> Path {
        var result = lhs
        result.addPath(rhs)
        return result
    }

    mutating func addLine(to point: CGPoint, relative: Bool) {
        addLine(to: relative ? (currentPoint ?? .zero) + point : point)
    }

    var elements: [Path.Element] {
        var elements: [Path.Element] = []
        forEach { element in
            elements.append(element)
        }
        return elements
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

extension Path {
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

public extension Path {
    init(dots: [CGPoint], radius: Double) {
        self = Path { path in
            for dot in dots {
                path.addEllipse(in: CGRect(center: dot, radius: radius))
            }
        }
    }
}
