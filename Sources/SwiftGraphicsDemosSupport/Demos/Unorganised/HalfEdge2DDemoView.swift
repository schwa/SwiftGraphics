import CoreGraphicsSupport
import CoreGraphicsUnsafeConformances
import Everything
import Shapes3D
import simd
import SwiftUI
import WrappingHStack

struct HalfEdge2DDemoView: View, DemoView {
    @State
    var mesh: HalfEdgeMesh<CGPoint>

    @State
    var selection: HalfEdgeSelection?

    @State
    var faceColors: [HalfEdgeMesh<CGPoint>.Face.ID: Color]

    init() {
//        let polygons: [Polygon3D<SIMD3<Float>>] = [
//            .init(vertices: [[0, 0, 0], [100, 0, 0], [100, 100, 0], [0, 100, 0]]),
//            .init(vertices: [[100, 0, 0], [200, 0, 0], [200, 100, 0], [100, 100, 0]]),
//        ]
        let polygons: [[CGPoint]] = [
            [[0, 0], [0, 100], [100, 100]],
            [[100, 0], [0, 0], [100, 100]],
        ]
        let mesh = HalfEdgeMesh<CGPoint>(polygons: polygons)
        let faceColors = Dictionary(uniqueKeysWithValues: mesh.faces.map { ($0.id, Color(white: 0.8)) })
        self.mesh = mesh
        self.faceColors = faceColors

        self.mesh.dump()
    }

    var body: some View {
        Canvas { context, _ in
            context.translateBy(x: 100, y: 100)
            for face in mesh.faces {
                let facePath = Path { path in
                    let points = face.vertices.map(\.position)
                    path.addLines(points)
                    path.closeSubpath()
                }
                context.stroke(facePath, with: .color(.gray), lineWidth: 2)

                for halfEdges in face.halfEdges.circularPairs() {
                    let from = halfEdges.0.vertex.position
                    let to = halfEdges.1.vertex.position

                    let sideOffset = CGPoint(angle: Angle(from: from, to: to) + 90, length: -5)

                    let fromOffset: CGPoint = (to - from).normalized * 15
                    let toOffset = (from - to).normalized * 15

                    let path = Path.arrow(start: from + fromOffset + sideOffset, end: to + toOffset + sideOffset, endStyle: .simpleHalfLeft)
                    context.stroke(path, with: .color(.red), style: .init(lineWidth: 2))
                }
            }
        }
        .background(Color.white)
        .inspector {
            BetterHalfEdgeMeshInspectorView(mesh: mesh)
        }
    }
}

struct BetterHalfEdgeMeshInspectorView <Position>: View where Position: Hashable {
    typealias Mesh = HalfEdgeMesh<Position>

    var mesh: Mesh

    var body: some View {
        List {
            DisclosureGroup2("Mesh") {
                DisclosureGroup2("Faces") {
                    ForEach(mesh.faces.indices, id: \.self) { index in
                        let face = mesh.faces[index]
                        DisclosureGroup2("#\(index)") {
                            DisclosureGroup2("Half Edges") {
                                WrappingHStack(alignment: .leading) {
                                    ForEach(face.halfEdges.indices, id: \.self) { index in
                                        let halfEdge = face.halfEdges[index]
                                        link(for: halfEdge)
                                    }
                                }
                            }
                        }
                    }
                }
                DisclosureGroup2("Half Edges") {
                    ForEach(mesh.halfEdges.indices, id: \.self) { index in
                        let halfEdge = mesh.halfEdges[index]
//                        var vertex: Vertex
//                        var next: HalfEdge?
//                        var twin: HalfEdge?
//                        var face: Face?

                        DisclosureGroup2("#\(index)") {
                            LabeledContent("Next") {
                                link(for: halfEdge.next)
                            }
                            if halfEdge.twin != nil {
                                LabeledContent("Twin") {
                                    link(for: halfEdge.twin)
                                }
                            }
                            LabeledContent("Face") {
                                link(for: halfEdge.face)
                            }
                            DisclosureGroup2("Vertex") {
                                let vertex = halfEdge.vertex
                                LabeledContent("Half-Edge") {
                                    link(for: vertex.halfEdge)
                                }
                                LabeledContent("Position") {
                                    Text(describing: vertex.position)
                                }
                            }
                        }
                    }
                }
            }
        }
        .toolbar {
            Button("Validate") {
                assert(mesh.isValid())
            }
        }
    }

    @ViewBuilder
    func link(for face: Mesh.Face?) -> some View {
        if let face {
        if let index = mesh.index(for: face) {
            Button("#\(index)") {
            }
            .buttonStyle(.link)
        }
        else {
            ContentUnavailableView("No face in mesh", systemImage: "exclamationmark.triangle")
        }
        }
        else {
            ContentUnavailableView("No face in mesh", systemImage: "exclamationmark.triangle")
        }
    }

    @ViewBuilder
    func link(for halfEdge: Mesh.HalfEdge?) -> some View {
        if let halfEdge {
            if let index = mesh.index(for: halfEdge) {
                Button("#\(index)") {
                }
                .buttonStyle(.link)
            }
            else {
                ContentUnavailableView("No half-edge in mesh", systemImage: "exclamationmark.triangle")
            }
        }
        else {
            Text("none").foregroundStyle(.secondary)
        }
    }
}

extension HalfEdgeMesh {
    func index(for face: Face) -> Int? {
        faces.firstIndex(identifiedBy: face.id)
    }
    func index(for halfEdge: HalfEdge) -> Int? {
        halfEdges.firstIndex(identifiedBy: halfEdge.id)
    }
}

/*
 Mesh:
   Faces:
     #0: Edges
   HalfEdges:
     #0
 */

struct DisclosureGroup2 <Label, Content>: View where Label: View, Content: View {
    @State
    var isExpanded: Bool

    var label: Label
    var content: Content

    init(isInitiallyExpanded: Bool = true, @ViewBuilder label: () -> Label, @ViewBuilder content: () -> Content) {
        self.isExpanded = isInitiallyExpanded
        self.label = label()
        self.content = content()
    }

    var body: some View {
        EmptyView()
        DisclosureGroup(
            isExpanded: $isExpanded,
            content: { content },
            label: { label }
        )
    }
}

extension DisclosureGroup2 where Label == Text {
    init(isInitiallyExpanded: Bool, label: String, @ViewBuilder content: () -> Content) {
        self.isExpanded = isInitiallyExpanded
        self.label = Text(label)
        self.content = content()
    }

    init(_ label: String, @ViewBuilder content: () -> Content) {
        self.isExpanded = true
        self.label = Text(label)
        self.content = content()
    }
}

struct MaybeLabeledContent <Value, PresentContent, AbsentContent> where PresentContent: View, AbsentContent: View {
    enum Content {
        case present(PresentContent)
        case absent(AbsentContent)
    }

    var content: Content

    init(_ value: Value?, @ViewBuilder present: (Value) -> PresentContent, @ViewBuilder absent: () -> AbsentContent) {
        if let value {
            content = .present(present(value))
        }
        else {
            content = .absent(absent())
        }
    }

    var body: some View {
        Group {
            if case let .present(content) = content {
                content
            }
            else if case let .absent(content) = content {
                content
            }
        }
    }
}
