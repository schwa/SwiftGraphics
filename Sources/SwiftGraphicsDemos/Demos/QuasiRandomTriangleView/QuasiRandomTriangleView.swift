import CoreGraphics
import Shapes2D
import SwiftUI

struct QuasiRandomTriangleView: View, DemoView {
    @State
    private var density = 0.01

    @State
    private var count = 0.01

    @State
    private var radius = 4.0

    @State
    private var jitter = 0.0

    @State
    private var saturation = 1.0

    @State
    private var bouncingBalls: BouncingBallsSimulation?

    var body: some View {
        VStack {
            Form {
                LabeledContent("density") {
                    Slider(value: $density, in: 0...1)
                        .frame(maxWidth: 200)
                    Text(density.formatted())
                        .frame(width: 120)
                        .monospacedDigit()
                }
                LabeledContent("Jitter") {
                    Slider(value: $jitter, in: 0...10)
                        .frame(maxWidth: 200)
                    Text(jitter.formatted())
                        .frame(width: 120)
                        .monospacedDigit()
                }
                LabeledContent("Radius") {
                    Slider(value: $radius, in: 0.1...10)
                        .frame(maxWidth: 200)
                }
                LabeledContent("Saturation") {
                    Slider(value: $saturation, in: 0...1)
                        .frame(maxWidth: 200)
                }
                Text("Count: \(Int(count))")
            }
            .padding()

            GeometryReader { proxy in
                TimelineView(.animation) { time in
                    Canvas { context, _ in
                        guard let vertices = bouncingBalls?.balls.map(\.position) else {
                            return
                        }
                        let triangle = Triangle(a: vertices[0], b: vertices[1], c: vertices[2])

                        let path = Path { path in
                            path.move(to: triangle.a)
                            path.addLine(to: triangle.b)
                            path.addLine(to: triangle.c)
                            path.closeSubpath()
                        }
                        context.fill(path, with: .color(.pink.opacity(0.06)))

                        let area = triangle.area
                        let count = area * density

                        for n in stride(from: 1.0, through: count, by: 1) {
                            let point = quasiRandomPointIn(triangle: triangle, n: Int(n))
                            let jitteredPoint = CGPoint(x: point.x + .random(in: -jitter...jitter), y: point.y + .random(in: -jitter...jitter))

                            let chosenPoint = triangle.contains(point: jitteredPoint) ? jitteredPoint : point

                            let color = Color(hue: n / (count + 1), saturation: saturation, brightness: 1.0)
                            let path = Path(ellipseIn: CGRect(x: chosenPoint.x - radius, y: chosenPoint.y - radius, width: radius * 2, height: radius * 2))
                            context.fill(path, with: .color(color))
                        }
                    }
                    .onChange(of: proxy.size, initial: true) {
                        guard proxy.size.width > 0 && proxy.size.height > 0 else {
                            return
                        }
                        bouncingBalls = BouncingBallsSimulation(size: proxy.size, numberOfBalls: 3)
                    }
                    .onChange(of: time.date, initial: true) {
                        bouncingBalls?.simulate(currentTime: time.date)

                        guard let vertices = bouncingBalls?.balls.map(\.position) else {
                            return
                        }

                        let triangle = Triangle(a: vertices[0], b: vertices[1], c: vertices[2])
                        let area = triangle.area
                        count = area * density
                    }
                }
            }
            .background(.white)
        }
    }
}
