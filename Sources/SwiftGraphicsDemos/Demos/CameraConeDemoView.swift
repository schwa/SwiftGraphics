import Constraints3D
import Fields3D
import Projection
import RenderKitSceneGraph
import RenderKitUISupport
import simd
import SIMDSupport
import SwiftUI

struct CameraConeDemoView: DemoView {
    @State
    private var cameraTransform: Transform = .translation([0, 0, -5])

    @State
    private var cameraProjection: Projection = .perspective(.init())

    @State
    private var angle: Angle = .zero

    @State
    private var h: Float = 0.5

    @State
    private var cone = CameraCone(apex: [0, -1, 0], axis: [0, 1, 0], apexToTopBase: 1, topBaseRadius: 0.5, bottomBaseRadius: 1, height: 2)

    var body: some View {
        Canvas { context, size in
            let projection = Projection3DHelper(size: size, cameraProjection: cameraProjection, cameraTransform: cameraTransform)
            context.draw3DLayer(projection: projection) { context2D, context3D in
                context3D.drawAxisMarkers()
                context3D.draw(cone: cone)

                let p0 = projection.worldSpaceToScreenSpace(.zero)
                let position = cone.position(h: h, angle: angle)
                let p1 = projection.worldSpaceToScreenSpace(position)
                context2D.fill(Path.circle(center: p0, radius: 10), with: .color(.purple))
                context2D.fill(Path.circle(center: p1, radius: 10), with: .color(.purple))
                context2D.stroke(Path(lineSegments: [(p0, p1)]), with: .color(.purple), lineWidth: 2)
            }
        }
        .modifier(NewBallControllerViewModifier(constraint: .init(radius: 5), transform: $cameraTransform))
        .inspector {
            Form {
                Section("Camera") {
                    LabeledContent("Angle") {
                        VStack {
                            Slider(value: $angle.degrees, in: 0...360)
                            TextField("Angle", value: $angle.degrees, format: .number)
                                .labelsHidden()
                        }
                    }
                    LabeledContent("H") {
                        VStack {
                            Slider(value: $h, in: 0...1)
                            TextField("H", value: $h, format: .number)
                                .labelsHidden()
                        }
                    }
                }
                Section("Cone") {
                    LabeledContent("Y") {
                        UnitVectorEditor(vector: $cone.axis)
                    }

                    LabeledContent("Y") {
                        VStack {
                            Slider(value: $cone.apex.y, in: -10...10)
                            TextField("Y", value: $cone.apex.y, format: .number)
                                .labelsHidden()
                        }
                    }
                    LabeledContent("apexToTopBase") {
                        VStack {
                            Slider(value: $cone.apexToTopBase, in: 0...10)
                            TextField("apexToTopBase", value: $cone.apexToTopBase, format: .number)
                                .labelsHidden()
                        }
                    }

                    LabeledContent("topBaseRadius") {
                        VStack {
                            Slider(value: $cone.topBaseRadius, in: 0...5)
                            TextField("topBaseRadius", value: $cone.topBaseRadius, format: .number)
                                .labelsHidden()
                        }
                    }

                    LabeledContent("bottomBaseRadius") {
                        VStack {
                            Slider(value: $cone.bottomBaseRadius, in: 0...5)
                            TextField("bottomBaseRadius", value: $cone.bottomBaseRadius, format: .number)
                                .labelsHidden()
                        }
                    }

                    LabeledContent("height") {
                        VStack {
                            Slider(value: $cone.height, in: 0...10)
                            TextField("height", value: $cone.height, format: .number)
                                .labelsHidden()
                        }
                    }
                }
            }
        }
    }
}

extension ClosedRange where Bound == Angle {
    static let unlimited: Self = .degrees(-.infinity) ... .degrees(.infinity)
}

extension Path3D {
    static func circle(center: SIMD3<Float>, axis: SIMD3<Float>, radius: Float, segments: Int) -> Path3D {
        Path3D { path in
            // Ensure we have a valid axis and radius
            guard length(axis) > 0 && radius > 0 else {
                // Return an empty path if we can't create a valid circle
                return
            }

            // Normalize the axis vector
            let normalizedAxis = normalize(axis)

            // Create two perpendicular vectors to the axis
            var perpendicular1 = SIMD3<Float>(1, 0, 0)
            if abs(dot(normalizedAxis, perpendicular1)) > 0.99 {
                perpendicular1 = SIMD3<Float>(0, 1, 0)
            }
            perpendicular1 = normalize(cross(normalizedAxis, perpendicular1))
            let perpendicular2 = cross(normalizedAxis, perpendicular1)

            // Calculate the angle step
            let angleStep = 2 * Float.pi / Float(max(segments, 3))

            // Calculate the first point on the circle
            let firstPoint = center + radius * perpendicular1
            path.move(to: firstPoint)

            // Draw the circle
            for i in 1...segments {
                let angle = Float(i) * angleStep
                let circlePoint = center + radius * (cos(angle) * perpendicular1 + sin(angle) * perpendicular2)
                path.addLine(to: circlePoint)
            }

            // Close the circle by connecting back to the first point
            path.addLine(to: firstPoint)
        }
    }
}

extension GraphicsContext3D {
    func draw(cone: CameraCone) {
        var path = Path3D()

        // Calculate the centers of the top and bottom bases
        let topCenter = cone.apex + cone.axis * cone.apexToTopBase
        let bottomCenter = topCenter + cone.axis * cone.height

        // Draw the top base circle
        let topCircle = Path3D.circle(center: topCenter, axis: cone.axis, radius: cone.topBaseRadius, segments: 32)
        path.addPath(topCircle)

        // Draw the bottom base circle
        let bottomCircle = Path3D.circle(center: bottomCenter, axis: cone.axis, radius: cone.bottomBaseRadius, segments: 32)
        path.addPath(bottomCircle)

        // Draw lines connecting top and bottom bases
        for i in 0..<32 {
            let angle = Float(i) * 2 * .pi / 32
            let topX = cos(angle) * cone.topBaseRadius
            let topZ = sin(angle) * cone.topBaseRadius
            let topPoint = topCenter + SIMD3<Float>(topX, 0, topZ)

            let bottomX = cos(angle) * cone.bottomBaseRadius
            let bottomZ = sin(angle) * cone.bottomBaseRadius
            let bottomPoint = bottomCenter + SIMD3<Float>(bottomX, 0, bottomZ)

            path.move(to: topPoint)
            path.addLine(to: bottomPoint)
        }

        // Draw the path
        stroke(path: path, with: .color(.cyan))
    }
}
