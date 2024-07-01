import CoreGraphicsSupport
import SwiftUI

public struct PathSlider: View {
    @Binding
    var value: Double

    var range: ClosedRange<Double>
    var path: Path

    @State
    private var cachedPoints: [(Double, CGPoint)] = []

    public init(value: Binding<Double>, in range: ClosedRange<Double> = 0...1, path: Path) {
        self._value = value
        self.range = range
        self.path = path
    }

    public var body: some View {
        let path = path.strokedPath(.init(lineWidth: 4, lineCap: .round))
        let bounds = path.boundingRect.insetBy(dx: -10, dy: -10)

        Canvas { context, _ in
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
        .gesture(DragGesture(minimumDistance: 0).onChanged { value in
            let points = cachedPoints.sorted { lhs, rhs in
                lhs.1.distance(to: value.location) < rhs.1.distance(to: value.location)
            }
            self.value = points.first!.0
        })
        .frame(width: bounds.width, height: bounds.height)
    }
}

#Preview {
    @Previewable @State
    var value = 0.5

    @Previewable @State
    var path = Path.spiral(center: CGPoint(x: 50, y: 50), initialRadius: 0, finalRadius: 50, turns: 3)

    VStack {
//        PathSlider(value: $value, in: 0...1, path: path)
//        Slider(value: $value)
        Path.smileyFace(in: CGRect(x: 0, y: 0, width: 100, height: 100)).stroke()
    }
    .padding()
}
