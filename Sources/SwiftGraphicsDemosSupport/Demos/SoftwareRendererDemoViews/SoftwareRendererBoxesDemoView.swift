import CoreGraphicsSupport
import Projection
import Shapes3D
import SwiftUI
import SIMDSupport

struct SoftwareRendererBoxesDemoView: View, DemoView {
    @State
    var models: [any PolygonConvertable]

    @State
    var cameraTransform: Transform = .translation([0, 0, -5])

    @State
    var cameraProjection: Projection = .perspective(.init())

    @State
    var ballConstraint = BallConstraint()

    @State
    var rasterizerOptions = Rasterizer.Options.default

    init() {
        models = [
            Box3D(min: [-1, -0.5, -0.5], max: [-2.0, 0.5, 0.5]),
            Sphere3D(center: .zero, radius: 0.5),
            Box3D(min: [1, -0.5, -0.5], max: [2.0, 0.5, 0.5]),
        ]
    }

    var body: some View {
        Canvas { context, size in
            let projection = Projection3DHelper(size: size, cameraProjection: cameraProjection, cameraTransform: cameraTransform)
            context.draw3DLayer(projection: projection) { _, context3D in
                context3D.drawAxisMarkers()
                context3D.rasterize(options: rasterizerOptions) { rasterizer in
                    for model in models {
                        for (index, polygon) in try! model.toPolygons().enumerated() {
                            rasterizer.fill(polygon: polygon.vertices.map(\.position), with: .color(Color(rgb: kellyColors[index % kellyColors.count]).opacity(0.8)))
                        }
                    }
                }
            }
        }
        .onChange(of: ballConstraint.transform, initial: true) {
            cameraTransform.matrix = ballConstraint.transform
        }
        .overlay(alignment: .topTrailing) {
            CameraRotationWidgetView(ballConstraint: $ballConstraint)
                .frame(width: 120, height: 120)
        }
        .ballRotation($ballConstraint.rollPitchYaw)
        .inspector {
            Form {
                Section("Map") {
                    MapInspector(cameraTransform: $cameraTransform, models: []).aspectRatio(1, contentMode: .fill)
                }
                Section("Rasterizer") {
                    RasterizerOptionsView(options: $rasterizerOptions)
                }
                Section("Camera") {
                    ProjectionInspector(projection: $cameraProjection)
                }
                Section("Ball Constraint") {
                    BallConstraintEditor(ballConstraint: $ballConstraint)
                }
            }
        }
    }
}
