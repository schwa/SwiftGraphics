import CoreGraphicsSupport
import Projection
import Shapes3D
import simd
import SwiftUI

struct HalfEdgeView: View, DefaultInitializableView {
    var mesh: HalfEdgeMesh = .demo()

    @State
    var camera = Camera(transform: .translation([0, 0, -5]), target: [0, 0, 0], projection: .perspective(.init(fovy: .degrees(90), zClip: 0.01 ... 1000.0)))

    var body: some View {
        GeometryReader { proxy in
            Canvas { context, size in
                var projection = Projection3D(size: size)
                projection.viewTransform = camera.transform.matrix.inverse
                projection.projectionTransform = camera.projection.matrix(viewSize: .init(size))
                projection.clipTransform = simd_float4x4(scale: [Float(size.width) / 2, Float(size.height) / 2, 1])
                context.draw3DLayer(projection: projection) { _, context3D in
                    var rasterizer = context3D.rasterizer
                    for polygon in mesh.polygons {
                        rasterizer.submit(polygon: polygon.vertices, with: .color(.green))
                    }
                    rasterizer.rasterize()
                }
            }
            .onSpatialTap { location in
                let size = proxy.size
                var projection = Projection3D(size: size)
                projection.viewTransform = camera.transform.matrix.inverse
                projection.projectionTransform = camera.projection.matrix(viewSize: .init(size))
                projection.clipTransform = simd_float4x4(scale: [Float(size.width) / 2, Float(size.height) / 2, 1])

                var location = location
                location.x -= size.width / 2
                location.y -= size.height / 2

//                print(location)
                for polygon in mesh.polygons {
                    let points = polygon.vertices.map { projection.project($0) }
                    let path = Path(vertices: points, closed: true)
                    print(points)
                    if path.contains(location) {
                        print("HIT")
                    }
                }
            }
        }
    }
}

extension View {
    func onSpatialTap(count: Int = 1, coordinateSpace: some CoordinateSpaceProtocol = .local, handler: @escaping (CGPoint) -> Void) -> some View {
        gesture(SpatialTapGesture(count: count, coordinateSpace: coordinateSpace).onEnded({ value in
            handler(value.location)
        }))
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

    var polygons: [Shapes3D.Polygon3D<SIMD3<Float>>] {
        faces.map { face in
            var vertices: [SIMD3<Float>] = []
            var halfEdge: HalfEdge! = face.halfEdge
            repeat {
                vertices.append(halfEdge.vertex.position)
                halfEdge = halfEdge.next
            }
            while halfEdge !== face.halfEdge
            return .init(vertices: vertices)
        }
    }
}
