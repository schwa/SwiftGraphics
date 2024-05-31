import CoreGraphicsSupport
import SwiftFormats
import SwiftUI

struct AngleDemoView: View, DemoView {
    @State
    var p0 = CGPoint(x: 100, y: 400)

    @State
    var p1 = CGPoint(x: 200, y: 400)

    @State
    var p2 = CGPoint(x: 300, y: 400)

    init() {
    }

    var body: some View {
        ZStack {
            Path { path in
                path.move(to: p0)
                path.addLine(to: p1)
                path.addLine(to: p2)
            }
            .stroke(Color.black, style: .init(lineWidth: 2))

            Path { path in
                let radius = max(min(p1.distance(to: p0), p1.distance(to: p2)) * 0.25, 20)
                path.addArc(center: p1, radius: radius, startAngle: .init(from: p1, to: p0), endAngle: .init(from: p1, to: p2), clockwise: true)
            }
            .stroke(Color.green, style: .init(lineWidth: 4))

            Path { path in
                let a = (p1 - p0).normalized
                let b = (p1 - p2).normalized
                let c = (a + b).normalized
                print(a, b, c)

                path.move(to: p1)
                path.addLine(to: p1 + c * 50)
            }
            .stroke(Color.red, style: .init(lineWidth: 2))

            Handle($p0)
            Handle($p1)
            Handle($p2)
        }
        .inspector(isPresented: .constant(true)) {
            Form {
                TextField("p0", value: $p0, format: .point)
                TextField("p1", value: $p1, format: .point)
                TextField("p2", value: $p2, format: .point)
                LabeledContent("Angle p0", value: ((Angle(vertex: p1, p1: p0, p2: p2) + 360)).truncatingRemainder(dividingBy: 360), format: .angle)
            }
        }
    }
}

func abs(_ point: CGPoint) -> CGPoint {
    .init(x: abs(point.x), y: abs(point.y))
}
