import Constraints3D
import CoreGraphicsSupport
import Everything
import MetalSupport
import Projection
import RenderKitUISupport
import Shapes2D
import Shapes3D
import Shapes3DTessellation
import SIMDSupport
import SwiftFormats
import SwiftUI
import Widgets3D

struct SoftwareRendererMeshDemoView: View, DemoView {
    enum Source: Hashable {
        case file(String)
        case extrusion(String)
        case revolve(String)
    }

    static let sources: [Source] = [
        .file("Models/Teapot"),
        .file("Models/Icosphere"),
        .file("Models/Monkey"),
        .file("Models/Cube"),
        .file("Models/Square"),
        .extrusion("star"),
        .extrusion("square"),
        .revolve("?")
    ]

    @State
    private var source: Source?

    @State
    private var mesh: TrivialMesh<SimpleVertex>?

    @State
    private var fill = true

    @State
    private var stroke = false

    @State
    private var cameraTransform: Transform = .translation([0, 0, -5])

    @State
    private var cameraProjection: Projection = .perspective(.init())

    @State
    private var pitchLimit: ClosedRange<SwiftUI.Angle> = .degrees(-.infinity) ... .degrees(.infinity)

    @State
    private var yawLimit: ClosedRange<SwiftUI.Angle> = .degrees(-.infinity) ... .degrees(.infinity)

    @State
    private var rasterizerOptions = Rasterizer.Options.default

    init() {
    }

    var body: some View {
        ZStack {
            Canvas { context, size in
                let projection = Projection3DHelper(size: size, cameraProjection: cameraProjection, cameraTransform: cameraTransform)
                context.draw3DLayer(projection: projection) { _, context3D in
                    context3D.drawAxisMarkers()
                    if let mesh {
                        context3D.rasterize(options: rasterizerOptions) { rasterizer in
                            for (index, polygon) in mesh.toPolygons().enumerated() {
                                if fill {
                                    rasterizer.fill(polygon: polygon.map(\.position), with: .color(Color(rgb: kellyColors[index % kellyColors.count]).opacity(0.8)))
                                }
                                if stroke {
                                    rasterizer.stroke(polygon: polygon.map(\.position), with: .color(Color(rgb: kellyColors[index % kellyColors.count]).opacity(0.8)))
                                }
                            }
                        }
                        context3D.stroke(path: Path3D(box: mesh.boundingBox), with: .color(.purple))
                    }
                }
            }
        }
        .onAppear {
            source = Self.sources.first
        }
        .onChange(of: source, initial: true) {
            switch source {
            case .file(let name):
                let url: URL = try! Bundle.module.url(forResource: name, withExtension: "ply")
                mesh = try! TrivialMesh(url: url)
            case .extrusion(let name):
                let path: Path
                switch name {
                case "star":
                    path = Path.star(points: 12, innerRadius: 0.5, outerRadius: 1)
                case "square":
                    path = Path(CGRect(center: .zero, radius: 1))
                default:
                    fatalError("Unknown name.")
                }
                let polygons = path.polygonalChains.map { vertices in Shapes2D.Polygon(vertices) } // .filter(\.isClosed) // TODO: TODO
                var mesh = TrivialMesh(merging: polygons.map { $0.extrude(min: 0, max: 3, topCap: true, bottomCap: true) })
                mesh = mesh.offset(by: -mesh.boundingBox.min)
                self.mesh = mesh
            case .revolve:
                let polygonalChain = PolygonalChain3D(vertices: [
                    [0, 0, 0],
                    [-1, 0, 0],
                    [-1, 2.5, 0],
                    [0, 2.5, 0]
                ])
                let axis = Line3D(point: [0, 0, 0], direction: [0, 1, 0])
                let mesh = revolve(polygonalChain: polygonalChain, axis: axis, range: .degrees(0) ... .degrees(360), segments: 12)
                self.mesh = TrivialMesh(other: mesh)
            default:
                break
            }
        }
        .modifier(NewBallControllerViewModifier(constraint: .init(radius: 5), transform: $cameraTransform))

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
            Button("Renormalize") {
                mesh = mesh?.renormalize()
            }
        }
        .inspector {
            Form {
                Section("Map") {
                    MapInspector(cameraTransform: $cameraTransform, models: []).aspectRatio(1, contentMode: .fill)
                }
                Section("Rasterizer") {
                    RasterizerOptionsView(options: $rasterizerOptions)
                }
                Section("Track Ball") {
                    TextField("Pitch Limit", value: $pitchLimit, format: ClosedRangeFormatStyle(substyle: .angle))
                    TextField("Yaw Limit", value: $pitchLimit, format: ClosedRangeFormatStyle(substyle: .angle))
                }
                Section("Camera") {
                    ProjectionEditor($cameraProjection)
                }
            }
        }
    }
}
