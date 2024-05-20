import CoreGraphicsSupport
import Projection
import Shapes3D
import simd
import SwiftUI
import SIMDSupport

struct HalfEdgeDemoView: View, DemoView {
    var mesh: HalfEdgeMesh

    @State
    var camera = Camera(transform: .translation([0, 0, -5]), target: [0, 0, 0], projection: .perspective(.init(fovy: .degrees(90), zClip: 0.01 ... 1_000.0)))

    @State
    var ballConstraint = BallConstraint()

    @State
    var rasterizerOptions = Rasterizer.Options.default

    init() {
        mesh = try! Box3D(min: [-1, -1, -1], max: [1, 1, 1]).toHalfEdgeMesh()
    }

    var body: some View {
        GeometryReader { proxy in
            let projection = Projection3D(size: proxy.size, camera: camera)
            Canvas { context, size in
                context.draw3DLayer(projection: projection) { _, context3D in
                    context3D.rasterize(options: rasterizerOptions) { rasterizer in
                        for polygon in mesh.polygons {
                            rasterizer.fill(polygon: polygon.vertices, with: .color(.green))
                        }
                    }
                }
            }
            .onSpatialTap { location in
                var location = location
                location.x -= proxy.size.width / 2
                location.y -= proxy.size.height / 2
                for face in mesh.faces {
                    let polygon = face.polygon
                    let points = polygon.vertices.map { projection.project($0) }
                    let path = Path(vertices: points, closed: true)
                    if path.contains(location) {
                        print(face)
                    }
                }
            }
            .ballRotation($ballConstraint.rollPitchYaw)
            .onChange(of: ballConstraint) {
                print("Ball constraint: \(ballConstraint)")
                camera.transform.matrix = ballConstraint.transform
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


extension HalfEdgeMesh {
    static func demo() -> HalfEdgeMesh {
        var mesh = HalfEdgeMesh()
        mesh.addFace(positions: [
            [0, 0, 0],
            [0, 1, 0],
            [1, 1, 0],
            [1, 0, 0],
        ])

        return mesh
    }

}
