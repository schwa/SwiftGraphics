import CoreGraphicsSupport
import Shapes3D
import Projection
import SwiftUI
import MetalSupport

struct MeshView: View, DefaultInitializableView {
    enum Source: Hashable {
        case file(String)
        case extrusion(String)
        case revolve(String)
    }

    static let sources: [Source] = [
        .file("Teapot"),
        .file("Monkey"),
        .file("Cube"),
        .file("Square"),
        .file("Icosphere"),
        .extrusion("star"),
        .extrusion("square"),
        .revolve("?"),
    ]

    @State
    var source: Source?

    @State
    var mesh: TrivialMesh<SimpleVertex>?

    @State
    var vertexNormals: Bool = false

    enum Mode {
        case model
        case vertices
        case source
    }

    @State
    var mode: Mode = .model

    var body: some View {
        ZStack {
            if let mesh {
                switch mode {
                case .model:
                    SoftwareRendererView { _, _, context3D in
                        var rasterizer = context3D.rasterizer
                        for (index, polygon) in mesh.toPolygons().enumerated() {
                            rasterizer.submit(polygon: polygon.map(\.position), with: .color(Color(rgb: kellyColors[index % kellyColors.count]).opacity(0.8)))
                        }
                        rasterizer.rasterize()
                        context3D.stroke(path: Path3D(box: mesh.boundingBox), with: .color(.purple))
                        if vertexNormals {
                            for vertex in mesh.vertices {
                                let path = Path3D { path in
                                    path.move(to: vertex.position)
                                    path.addLine(to: vertex.position + vertex.normal * 0.25)
                                }
                                context3D.stroke(path: path, with: .color(.blue))
                            }
                        }
                    }
                case .vertices:
                    EmptyView()
//                    Table(mesh.vertices.indices.map { Identified(id: $0, value: mesh.vertices[Int($0)]) }) {
// TODO: FIXME
                        //                        TableColumn("Position X") { Text(verbatim: "\($0.value.position.x)") }
//                        TableColumn("Position Y") { Text(verbatim: "\($0.value.position.y)") }
//                        TableColumn("Position Z") { Text(verbatim: "\($0.value.position.z)") }
//                        TableColumn("Normal X") { Text(verbatim: "\($0.value.normal.x)") }
//                        TableColumn("Normal Y") { Text(verbatim: "\($0.value.normal.y)") }
//                        TableColumn("Normal Z") { Text(verbatim: "\($0.value.normal.z)") }
//                        TableColumn("Texture X") { Text(verbatim: "\($0.value.textureCoordinate.x)") }
//                        TableColumn("Texture Y") { Text(verbatim: "\($0.value.textureCoordinate.y)") }
//                    }
                case .source:
                    Text(mesh.toPLY())
                }
            }
        }
        // TODO: Can't do this without exposing Projection3D somehow
//        .gesture(SpatialTapGesture().onEnded({ value in
//            let location = SIMD2<Float>(value.location)
//            //gluUnproject(win: SIMD3<Float>(location, 0.0), modelView: <#T##simd_float4x4#>, proj: <#T##simd_float4x4#>, viewOrigin: <#T##SIMD2<Float>#>, viewSize: <#T##SIMD2<Float>#>)
//        }))

        .onAppear {
            source = Self.sources.first
        }
        .toolbar {
            Picker("Source", selection: $source) {
                Text("None").tag(Source?.none)
                ForEach(Self.sources, id: \.self) { source in
                    switch source {
                    case .file(let name):
                        Label("File: \(name)", systemImage: "doc").tag(Optional(source))
                    case .extrusion(let name):
                        Label("Extrusion: \(name)", systemImage: "cube").tag(Optional(source))
                    case .revolve(let name):
                        Label("Revolve: \(name)", systemImage: "cube").tag(Optional(source))
                    }
                }
            }
            .fixedSize()

            Picker("Mode", selection: $mode) {
                Text(verbatim: "Render").tag(Mode.model)
                Text(verbatim: "Vertices").tag(Mode.vertices)
                Text(verbatim: "Source").tag(Mode.source)
            }
            .pickerStyle(.segmented)
            .fixedSize()

            Button("Renormalize") {
                mesh = mesh?.renormalize()
            }

            Toggle("Vertex Normals", isOn: $vertexNormals)
        }
        .onChange(of: source) {
            switch source {
            case .file(let name):
                let url = Bundle.main.url(forResource: name, withExtension: "ply")!
                mesh = try! TrivialMesh(url: url)
            case .extrusion(let name):
                let path: Path
                switch name {
                case "star":
                    path = Path.star(points: 12, innerRadius: 0.5, outerRadius: 1)
                case "square":
                    path = Path(CGRect(center: .zero, radius: 1))
                default:
                    fatalError()
                }
                fatalError()
//                let polygons = path.polygonalChains.map { Polygon3D(polygonalChain: PolygonalChain3D(vertices: $0)) }//.filter(\.isClosed) // TODO: TODO
//                var mesh = TrivialMesh(merging: polygons.map { $0.extrude(min: 0, max: 3, topCap: true, bottomCap: true) })
//                mesh = mesh.offset(by: -mesh.boundingBox.min)
//                self.mesh = mesh
            case .revolve:
                let polygonalChain = PolygonalChain3D<SIMD3<Float>>(vertices: [
                    [0, 0, 0],
                    [-1, 0, 0],
                    [-1, 2.5, 0],
                    [0, 2.5, 0],
                ])
                let axis = Line3D(point: [0, 0, 0], direction: [0, 1, 0])
                let mesh = revolve(polygonalChain: polygonalChain, axis: axis, range: .degrees(0) ... .degrees(360), segments: 12)
                self.mesh = TrivialMesh(other: mesh)
            default:
                break
            }
        }
    }
}

extension Box3D where Vertex == SIMD3<Float> {
    var minXMinYMinZ: SIMD3<Float> { [min.x, min.y, min.z] }
    var minXMinYMaxZ: SIMD3<Float> { [min.x, min.y, max.z] }
    var minXMaxYMinZ: SIMD3<Float> { [min.x, max.y, min.z] }
    var minXMaxYMaxZ: SIMD3<Float> { [min.x, max.y, max.z] }
    var maxXMinYMinZ: SIMD3<Float> { [max.x, min.y, min.z] }
    var maxXMinYMaxZ: SIMD3<Float> { [max.x, min.y, max.z] }
    var maxXMaxYMinZ: SIMD3<Float> { [max.x, max.y, min.z] }
    var maxXMaxYMaxZ: SIMD3<Float> { [max.x, max.y, max.z] }
}

extension Path3D {
    init(box: Box3D<SIMD3<Float>>) {
        self = Path3D { path in
            path.move(to: box.minXMinYMinZ)
            path.addLine(to: box.maxXMinYMinZ)
            path.addLine(to: box.maxXMaxYMinZ)
            path.addLine(to: box.minXMaxYMinZ)
            path.closePath()

            path.move(to: box.minXMinYMaxZ)
            path.addLine(to: box.maxXMinYMaxZ)
            path.addLine(to: box.maxXMaxYMaxZ)
            path.addLine(to: box.minXMaxYMaxZ)
            path.closePath()

            path.move(to: box.minXMinYMinZ)
            path.addLine(to: box.minXMinYMaxZ)

            path.move(to: box.maxXMinYMinZ)
            path.addLine(to: box.maxXMinYMaxZ)

            path.move(to: box.maxXMaxYMinZ)
            path.addLine(to: box.maxXMaxYMaxZ)

            path.move(to: box.minXMaxYMinZ)
            path.addLine(to: box.minXMaxYMaxZ)
        }
    }
}

extension TrivialMesh where Vertex == SimpleVertex {
    init(other: TrivialMesh<SIMD3<Float>>) {
        let vertices = other.vertices.map {
            SimpleVertex(position: $0, normal: .zero)
        }
        let mesh = TrivialMesh(indices: other.indices, vertices: vertices)
        self = mesh.renormalize()
    }
}
