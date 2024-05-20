import CoreGraphicsSupport
import Shapes3D
import SwiftUI
import Projection

struct SoftwareRendererBoxesDemoView: View, DemoView {
    @State
    var models: [any PolygonConvertable]

    @State
    var camera = Camera(transform: .translation([0, 0, -5]), target: [0, 0, 0], projection: .perspective(.init(fovy: .degrees(90), zClip: 0.01 ... 1_000.0)))

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
            let projection = Projection3D(size: size, camera: camera)
            context.draw3DLayer(projection: projection) { context, context3D in
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
        .onAppear {
            camera.transform.matrix = ballConstraint.transform
        }
        .onChange(of: ballConstraint.transform) {
            camera.transform.matrix = ballConstraint.transform
        }
        .overlay(alignment: .topTrailing) {
            CameraRotationWidgetView(ballConstraint: $ballConstraint)
                .frame(width: 120, height: 120)
        }
        .ballRotation($ballConstraint.rollPitchYaw)
        .inspector() {
            Form {
                Section("Map") {
                    MapInspector(camera: $camera, models: []).aspectRatio(1, contentMode: .fill)
                }
                Section("Rasterizer") {
                    RasterizerOptionsView(options: $rasterizerOptions)
                }
                Section("Camera") {
                    CameraInspector(camera: $camera)
                }
                Section("Ball Constraint") {
                    BallConstraintEditor(ballConstraint: $ballConstraint)
                }
            }
        }
    }
}
