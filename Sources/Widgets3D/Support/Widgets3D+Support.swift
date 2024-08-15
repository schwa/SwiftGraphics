import BaseSupport
import CoreGraphicsSupport
import SwiftUI

struct GeometrySizeChangeViewModifier: ViewModifier {
    @Binding
    var size: CGSize

    func body(content: Content) -> some View {
        content
            .onGeometryChange(for: CGSize.self) { proxy in
                proxy.size
            }
            action: { size in
                self.size = size
            }
    }
}

extension View {
    func geometrySize(_ size: Binding<CGSize>) -> some View {
        self.modifier(GeometrySizeChangeViewModifier(size: size))
    }
}

#if os(macOS)
extension Image {
    @MainActor
    init(color: Color, size: CGSize) {
        guard let nsImage = ImageRenderer(content: color.frame(width: size.width, height: size.height)).nsImage else {
            fatalError("Failed to create image from color")
        }
        self = .init(nsImage: nsImage)
    }
}
#endif

extension ControlSize {
    var ratio: UnitPoint {
        switch self {
        case .mini:
            .init(x: 0.7, y: 0.65)
        case .small:
            .init(x: 0.8, y: 0.8)
        case .regular:
            .init(x: 1, y: 1)
        case .large:
            .init(x: 1, y: 1.4)
        case .extraLarge:
            .init(x: 1, y: 1.4)
        @unknown default:
            .init(x: 1, y: 1)
        }
    }
}

public extension Path {
    static func curve(from: CGPoint, to: CGPoint, control1: CGPoint, control2: CGPoint) -> Path {
        Path { path in
            path.move(to: from)
            path.addCurve(to: to, control1: control1, control2: control2)
        }
    }

    var firstPoint: CGPoint? {
        var firstPoint: CGPoint?
        forEach { element in
            guard firstPoint == nil else {
                return
            }
            switch element {
            case .move(let point):
                firstPoint = point
            default:
                firstPoint = .zero
            }
        }
        return firstPoint
    }
}

public extension Path {
    static func spiral(center: CGPoint, initialRadius: Double, finalRadius: Double, turns: Double) -> Path {
        var path = Path()

        let points = 500 // Increase for smoother spiral
        let angleIncrement = 2 * Double.pi * turns / Double(points)
        let radiusIncrement = (finalRadius - initialRadius) / Double(points)

        var angle = 0.0
        var radius = initialRadius

        var currentPoint = CGPoint(x: center.x + CGFloat(radius * cos(angle)),
                                   y: center.y + CGFloat(radius * sin(angle)))
        path.move(to: currentPoint)

        for _ in 0..<points {
            angle += angleIncrement
            radius += radiusIncrement
            let nextPoint = CGPoint(x: center.x + CGFloat(radius * cos(angle)),
                                    y: center.y + CGFloat(radius * sin(angle)))
            let controlPoint = CGPoint(x: (currentPoint.x + nextPoint.x) / 2,
                                       y: (currentPoint.y + nextPoint.y) / 2)
            path.addQuadCurve(to: nextPoint, control: controlPoint)
            currentPoint = nextPoint
        }

        return path
    }
}

public extension Path {
    func betterTrimedPath(from: Double, to: Double) -> Path {
        let from = from.wrapped(to: 0...1)
        let to = to.wrapped(to: 0...1)
        if from < to {
            return trimmedPath(from: from, to: to)
        } else {
            let a = trimmedPath(from: from, to: 1.0)
            let b = trimmedPath(from: 0, to: to)
            return a + b
        }
    }
}

public extension Path {
    static func hilbertCurve(in rect: CGRect, order: Int) -> Path {
        Path { path in
            let points = hilbertPoints(order: order)
            let scale = min(rect.width, rect.height) / CGFloat(1 << order)
            let offset = CGPoint(x: rect.minX, y: rect.minY)

            if let first = points.first {
                path.move(to: CGPoint(x: CGFloat(first.y) * scale, y: CGFloat(first.x) * scale) + offset)
            }

            for point in points.dropFirst() {
                path.addLine(to: CGPoint(x: CGFloat(point.y) * scale, y: CGFloat(point.x) * scale) + offset)
            }
        }
    }

    private static func hilbertPoints(order: Int) -> [(x: Int, y: Int)] {
        var points: [(x: Int, y: Int)] = []

        // swiftlint:disable:next function_parameter_count
        func hilbert(_ x: inout Int, _ y: inout Int, _ xi: Int, _ xj: Int, _ yi: Int, _ yj: Int, _ n: Int) {
            if n <= 0 {
                points.append((x: x, y: y))
            } else {
                hilbert(&x, &y, yi, yj, xi, xj, n - 1)
                x += xi
                y += yi
                points.append((x: x, y: y))
                hilbert(&x, &y, xi, xj, yi, yj, n - 1)
                x += xj
                y += yj
                points.append((x: x, y: y))
                hilbert(&x, &y, xi, xj, yi, yj, n - 1)
                x -= xi
                y -= yi
                points.append((x: x, y: y))
                hilbert(&x, &y, -yi, -yj, -xi, -xj, n - 1)
            }
        }

        var x = 0
        var y = 0
        hilbert(&x, &y, 0, 1, 1, 0, order)

        return points
    }
}

public struct PathMorpher {
    var points: [(CGPoint, CGPoint)]

    public init(a: Path, b: Path) {
        let count = 200
        points = (0 ..< count).map { n in
            let a = a.trimmedPath(from: 0, to: Double(n) / 200).currentPoint ?? a.firstPoint ?? .zero
            let b = b.trimmedPath(from: 0, to: Double(n) / 200).currentPoint ?? b.firstPoint ?? .zero
            return (a, b)
        }
    }

    public func morph(_ t: Double) -> Path {
        let lines = points.map { a, b in
            lerp(from: a, to: b, by: t)
        }
        return Path(lines: lines)
    }
}

public extension Path {
    static func smileyFace(in rect: CGRect) -> Path {
        var path = Path()

        // Face
        path.addEllipse(in: rect.insetBy(dx: rect.width * 0.1, dy: rect.height * 0.1))

        // Eyes
        let eyeOffsetX = rect.width * 0.15
        let eyeOffsetY = rect.height * 0.05
        let mouthOffsetY = rect.height * 0.05
        let eyeSize = CGSize(width: rect.width * 0.1, height: rect.height * 0.1)

        // Left Eye
        path.addEllipse(in: CGRect(x: rect.midX - eyeOffsetX - eyeSize.width / 2,
                                   y: rect.midY - eyeOffsetY - eyeSize.height / 2 - rect.height * 0.1,
                                   width: eyeSize.width, height: eyeSize.height))

        // Right Eye
        path.addEllipse(in: CGRect(x: rect.midX + eyeOffsetX - eyeSize.width / 2,
                                   y: rect.midY - eyeOffsetY - eyeSize.height / 2 - rect.height * 0.1,
                                   width: eyeSize.width, height: eyeSize.height))

        // Mouth
        path.addArc(center: CGPoint(x: rect.midX, y: rect.midY + mouthOffsetY),
                    radius: rect.width * 0.25,
                    startAngle: .degrees(0),
                    endAngle: .degrees(180),
                    clockwise: false)

        return path
    }
}
