import Constraints3D
import CoreGraphicsSupport
import Widgets3D
import Projection
import RenderKitUISupport
import SIMDSupport
import SwiftUI

struct PointCloudSoftwareRenderView: View, DemoView {
    @State
    private var cameraTransform: Transform = .translation([0, 0, -5])

    @State
    private var cameraProjection: Projection = .perspective(.init())

    @State
    private var rasterizerOptions = Rasterizer.Options.default

    @State
    private var points: [SIMD3<Float>]

    init() {
        let url: URL = try! Bundle.main.url(forResource: "cube_points", withExtension: "pointsply")
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
        .modifier(NewBallControllerViewModifier(constraint: .init(radius: 5), transform: $cameraTransform))
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
                    ProjectionEditor($cameraProjection)
                }
                Section("Camera Transform") {
                    TransformEditor($cameraTransform)
                }
            }
        }
    }
}
