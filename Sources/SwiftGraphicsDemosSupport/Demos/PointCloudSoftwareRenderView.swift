import CoreGraphicsSupport
import Projection
import Shapes3D
import SIMDSupport
import SwiftUI

struct PointCloudSoftwareRenderView: View, DemoView {
    @State
    var cameraTransform: Transform = .translation([0, 0, -5])

    @State
    var cameraProjection: Projection = .perspective(.init())

    @State
    var ballConstraint = BallConstraint()

    @State
    var rasterizerOptions = Rasterizer.Options.default

    @State
    var points: [SIMD3<Float>]

    init() {
        let url = Bundle.main.url(forResource: "cube_points", withExtension: "pointsply")!
        var ply = try! Ply(url: url)
        points = try! ply.points
    }

    var body: some View {
        Canvas { context, size in
            let projection = Projection3DHelper(size: size, cameraProjection: cameraProjection, cameraTransform: cameraTransform)
            context.draw3DLayer(projection: projection) { context2D, context3D in
                context3D.drawAxisMarkers()
                context3D.rasterize(options: rasterizerOptions) { _ in
                    for position in points {
                        let position2D = projection.worldSpaceToScreenSpace(position)

                        let path = Path(ellipseIn: CGRect(center: position2D, radius: 0.5))
                        context2D.fill(path, with: .color(.pink))
                    }
                }
            }
        }
        .onChange(of: ballConstraint.transform, initial: true) {
            cameraTransform = ballConstraint.transform
        }
        .overlay(alignment: .topTrailing) {
            CameraRotationWidgetView(ballConstraint: $ballConstraint)
                .frame(width: 120, height: 120)
        }
        .ballRotation($ballConstraint.rollPitchYaw, updatesPitch: false, updatesYaw: true)
        .toolbar {
            Button("Spin") {
                withAnimation {
                    cameraTransform.rotation.rollPitchYaw.yaw += .degrees(90)
                }
            }
        }
        .inspector(isPresented: .constant(true)) {
            Form {

                Section("Camera Projection") {
                    ProjectionEditor(projection: $cameraProjection)
                }

                Section("Ball Constraint") {
                    BallConstraintEditor(ballConstraint: $ballConstraint)
                }

                Section("Camera Transform") {
                    TransformEditor(transform: $cameraTransform)
                }
            }
        }
    }
}
