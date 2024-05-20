import SwiftUI
import CoreGraphicsSupport
import Shapes3D
import simd

struct HalfEdge2DDemoView: View, DemoView {

    @State
    var mesh: HalfEdgeMesh

    @State
    var selection: HalfEdgeSelection?

    @State
    var faceColors: [HalfEdgeMesh.Face.ID: Color]

    init() {
//        let polygons: [Polygon3D<SIMD3<Float>>] = [
//            .init(vertices: [[0, 0, 0], [100, 0, 0], [100, 100, 0], [0, 100, 0]]),
//            .init(vertices: [[100, 0, 0], [200, 0, 0], [200, 100, 0], [100, 100, 0]]),
//        ]
        let polygons: [Polygon3D<SIMD3<Float>>] = [
            .init(vertices: [[0, 0, 0], [0, 100, 0], [100, 100, 0]]),
            .init(vertices: [[100, 0, 0], [0, 0, 0], [100, 100, 0]]),
        ]
        let mesh = HalfEdgeMesh(polygons: polygons)
        let faceColors = Dictionary(uniqueKeysWithValues: mesh.faces.map { ($0.id, Color(white: 0.8))})
        self.mesh = mesh
        self.faceColors = faceColors
    }

    var body: some View {
        Canvas { context, size in
            context.translateBy(x: 100, y: 100)
            for face in mesh.faces {
                let facePath = Path { path in
                    let points = face.vertices.map(\.position.xy).map(CGPoint.init)
                    path.addLines(points)
                    path.closeSubpath()
                }
                context.stroke(facePath, with: .color(.gray), lineWidth: 2)

                for halfEdges in face.halfEdges.circularPairs() {
                    let from = CGPoint(halfEdges.0.vertex.position.xy)
                    let to = CGPoint(halfEdges.1.vertex.position.xy)

                    let sideOffset = CGPoint(angle: Angle(from: from, to: to) + 90, length: 5)

                    let fromOffset: CGPoint = (to - from).normalized * 10
                    let toOffset = (from - to).normalized * 10

                    let path = Path.arrow(start: from + fromOffset + sideOffset, end: to + toOffset + sideOffset, endStyle: .simpleHalfRight)
                    context.stroke(path, with: .color(.red), style: .init(lineWidth: 2))
                }
            }
        }
        .background(Color.white)
        .inspector() {
            HalfEdgeMeshInspectorView(mesh: $mesh, selection: $selection, faceColors: $faceColors)
        }

    }
}
