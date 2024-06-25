import SwiftUI
import CoreGraphicsUnsafeConformances

public struct PathSlider: View {
    @Binding
    var value: Double

    var path: Path

    var range: ClosedRange<Double>

    @State
    var cachedPoints: [(Double, CGPoint)] = []

    public init(value: Binding<Double>, path: Path, range: ClosedRange<Double>) {
        self._value = value
        self.path = path
        self.range = range
    }

    public var body: some View {
        let path = path.strokedPath(.init(lineWidth: 4, lineCap: .round))
        let bounds = path.boundingRect.insetBy(dx: -10, dy: -10)

        Canvas { context, size in
            context.translateBy(x: 10, y: 10)
            context.fill(path, with: .color(.gray.opacity(0.2)))
            let value = range.normalize(value)
            let activePath = self.path.trimmedPath(from: 0, to: value)
            let path = activePath.strokedPath(.init(lineWidth: 4, lineCap: .round))
            context.fill(path, with: .color(.accentColor))

            if let thumbPoint = activePath.currentPoint ?? self.path.firstPoint {
                let thumb = Path(ellipseIn: CGRect(center: thumbPoint, radius: 8))
                context.fill(thumb, with: .color(.white))
                context.stroke(thumb, with: .color(.init(white: 0.8)))
            }
        }
        .onChange(of: path, initial: true) {
            cachedPoints = stride(from: 0.0, through: 1.0, by: 0.005).compactMap { n in
                let path = self.path.trimmedPath(from: 0, to: n)
                return (n, path.currentPoint ?? self.path.firstPoint ?? .zero)
            }
        }
        .gesture(DragGesture(minimumDistance: 0).onChanged({ value in
            let points = cachedPoints.sorted { lhs, rhs in
                lhs.1.distance(to: value.location) < rhs.1.distance(to: value.location)
            }
            self.value = points.first!.0
        }))
        .frame(width: bounds.width, height: bounds.height)
    }

}

#Preview {
    @Previewable @State
    var value = 0.5

    @Previewable @State
    var path = Path.spiral2(center: [50, 50], initialRadius: 0, finalRadius: 50, turns: 3)

    VStack {
        PathSlider(value: $value, path: path, range: 0...1)
        Slider(value: $value)
    }
    .padding()
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

    static func spiral2(center: CGPoint, initialRadius: Double, finalRadius: Double, turns: Double) -> Path {
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

    static func spiral(center: CGPoint, initialRadius: Double, finalRadius: Double, turns: Double) -> Path {
        var path = Path()

        let points = 500 // Increase for smoother spiral
        let angleIncrement = 2 * Double.pi * turns / Double(points)
        let radiusIncrement = (finalRadius - initialRadius) / Double(points)

        var angle = 0.0
        var radius = initialRadius

        for n in 0..<points {
            let x = center.x + CGFloat(radius * cos(angle))
            let y = center.y + CGFloat(radius * sin(angle))
            if n == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
            angle += angleIncrement
            radius += radiusIncrement
        }

        return path
    }
}
