import CoreGraphicsSupport
import Projection
import Shapes3D
import simd
import SwiftUI
import SIMDSupport

struct HalfEdge3DDemoView: View, DemoView {
    @State
    var mesh: HalfEdgeMesh<SIMD3<Float>>

    @State
    var camera = Camera(transform: .translation([0, 0, -5]), target: [0, 0, 0], projection: .perspective(.init(fovy: .degrees(90), zClip: 0.01 ... 1_000.0)))

    @State
    var ballConstraint = BallConstraint()

    @State
    var rasterizerOptions = Rasterizer.Options.default

    @State
    var selection: HalfEdgeSelection?

    @State
    var faceColors: [HalfEdgeMesh<SIMD3<Float>>.Face.ID: Color]

    init() {
        let mesh = try! Box3D(min: [-1, -1, -1], max: [1, 1, 1]).toHalfEdgeMesh()
        let faceColors = Dictionary(uniqueKeysWithValues: mesh.faces.map { ($0.id, Color(white: 0.8))})

        self.mesh = mesh
        self.faceColors = faceColors
    }

    var body: some View {
        GeometryReader { proxy in
            let projection = Projection3D(size: proxy.size, camera: camera)
            Canvas { context, size in
                context.draw3DLayer(projection: projection) { _, context3D in
                    context3D.rasterize(options: rasterizerOptions) { rasterizer in
                        for face in mesh.faces {

                            var selected = false
                            if let selection, case .face(let index) = selection {
                                if mesh.faces[index] === face {
                                    selected = true
                                }
                            }

                            let color = faceColors[face.id]!

                            rasterizer.fill(polygon: face.polygon.vertices, with: .color(selected ? .accentColor : color))
                        }
                    }
                    context3D.rasterize(options: .init(backfaceCulling: false)) { rasterizer in
                        for polygon in mesh.polygons {
                            rasterizer.stroke(polygon: polygon.vertices, with: .color(.blue))
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
            TabView {
                HalfEdgeMeshInspectorView(mesh: $mesh, selection: $selection, faceColors: $faceColors)
                .tabItem { Text("Mesh") }

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
                .tabItem { Text("Stuff") }
            }
            .inspectorColumnWidth(min: 320, ideal: 320, max: 1000)
        }
    }
}

enum HalfEdgeSelection: Hashable {
    case face(Int)
    case halfEdge(Int)
}



struct HalfEdgeMeshInspectorView: View {

    @Binding
    var mesh: HalfEdgeMesh<SIMD3<Float>>

    @Binding
    var selection: HalfEdgeSelection?

    @Binding
    var faceColors: [HalfEdgeMesh<SIMD3<Float>>.Face.ID: Color]

    var body: some View {
        VStack {
            List(selection: $selection) {
                Section("Faces") {
                    ForEach(mesh.faces.indexed(), id: \.0) { index, face in
                        HStack {
                            Text("#\(index)")
                            let color = Binding<Color> {
                                faceColors[face.id]!
                            } set: { newValue in
                                faceColors[face.id] = newValue
                            }
                            Spacer()
                            ColorPicker(selection: color, label: {
                                Text("Color")
                            })
                            .labelsHidden()

                        }
                        .tag(HalfEdgeSelection.face(index))
                    }
                }
                Section("Half Edge") {
                    ForEach(mesh.halfEdges.indexed(), id: \.0) { index, halfEdge in
                        VStack(alignment: .leading) {
                            HStack {
                                Text("#\(index)")
                                Spacer()
                                Text(halfEdge.vertex.position, format: .vector)
                                //                            var next: HalfEdge?
                                //                            var twin: HalfEdge?
                                //                            var face: Face?
                            }
                            HStack {
                                if let faceIndex = halfEdge.face.map({ mesh.faces.firstIndex(identifiedBy: $0.id) }) {
                                    Text("Face: #\(faceIndex!)")
                                }
                                else {
                                    Text("No face").foregroundStyle(.red)
                                }
                                if let nextIndex = halfEdge.next.map({ mesh.halfEdges.firstIndex(identifiedBy: $0.id) }) {
                                    Text("Next: #\(nextIndex!)")
                                }
                                else {
                                    Text("No next").foregroundStyle(.red)
                                }
                                if let twinIndex = halfEdge.twin.map({ mesh.halfEdges.firstIndex(identifiedBy: $0.id) }) {
                                    Text("Twin: #\(twinIndex!)")
                                }
                                else {
                                    Text("No twin").foregroundStyle(.red)
                                }
                            }
                            .opacity(0.5)

                        }
                        .tag(HalfEdgeSelection.halfEdge(index))
                    }
                }
            }
        }
    }

}
