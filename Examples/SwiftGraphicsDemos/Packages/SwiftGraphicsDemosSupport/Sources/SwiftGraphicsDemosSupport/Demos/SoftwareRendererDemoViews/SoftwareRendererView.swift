import Algorithms
import CoreGraphicsSupport
import ModelIO
import Projection
import Shapes3D
import SIMDSupport
import SwiftFormats
import SwiftUI

struct SoftwareRendererView: View {
    struct Options: OptionSet {
        let rawValue: Int

        static let showAxisRules = Self(rawValue: 1 << 0)
    }

    @State
    var camera: Camera

    @State
    var modelTransform: Transform

    @State
    var ballConstraint: BallConstraint

    @State
    var pitchLimit: ClosedRange<SwiftUI.Angle> = .degrees(-.infinity) ... .degrees(.infinity)

    @State
    var yawLimit: ClosedRange<SwiftUI.Angle> = .degrees(-.infinity) ... .degrees(.infinity)

    @State
    var rasterizerOptions: Rasterizer.Options = .default

    @State
    var options = Options()

    @State
    var isInspectorPresented = true

    var renderer: (Projection3D, inout GraphicsContext, inout GraphicsContext3D) -> Void

    init(renderer: @escaping (Projection3D, inout GraphicsContext, inout GraphicsContext3D) -> Void) {
        camera = Camera(transform: .translation([0, 0, -5]), target: [0, 0, 0], projection: .perspective(.init(fovy: .degrees(90), zClip: 0.01 ... 1_000.0)))
        modelTransform = .init(rotation: simd_quatf(angle: .degrees(0), axis: [0, 1, 0]))
        ballConstraint = BallConstraint()
        self.renderer = renderer
    }

    var body: some View {
        Canvas { context, size in
            var projection = Projection3D(size: size)
            projection.viewTransform = camera.transform.matrix.inverse
            projection.projectionTransform = camera.projection.matrix(viewSize: .init(size))
            projection.clipTransform = simd_float4x4(scale: [Float(size.width) / 2, Float(size.height) / 2, 1])

            if options.contains(.showAxisRules) {
                context.draw3DLayer(projection: projection) { context, context3D in
                    context3D.stroke(path: Path3D { path in
                        path.move(to: [-5, 0, 0])
                        path.addLine(to: [5, 0, 0])
                    }, with: .color(.red))
                    context3D.stroke(path: Path3D { path in
                        path.move(to: [0, -5, 0])
                        path.addLine(to: [0, 5, 0])
                    }, with: .color(.green))
                    context3D.stroke(path: Path3D { path in
                        path.move(to: [0, 0, -5])
                        path.addLine(to: [0, 0, 5])
                    }, with: .color(.blue))

                    if let symbol = context.resolveSymbol(id: "-X") {
                        context.draw(symbol, at: projection.project([-5, 0, 0]))
                    }
                    if let symbol = context.resolveSymbol(id: "+X") {
                        context.draw(symbol, at: projection.project([5, 0, 0]))
                    }
                    if let symbol = context.resolveSymbol(id: "-Y") {
                        context.draw(symbol, at: projection.project([0, -5, 0]))
                    }
                    if let symbol = context.resolveSymbol(id: "+Y") {
                        context.draw(symbol, at: projection.project([0, 5, 0]))
                    }
                    if let symbol = context.resolveSymbol(id: "-Z") {
                        context.draw(symbol, at: projection.project([0, 0, -5]))
                    }
                    if let symbol = context.resolveSymbol(id: "+Z") {
                        context.draw(symbol, at: projection.project([0, 0, 5]))
                    }
                }
            }
            context.draw3DLayer(projection: projection) { context, context3D in
                context3D.rasterizerOptions = rasterizerOptions
                renderer(projection, &context, &context3D)
            }
        }
        symbols: {
            ForEach(["-X", "+X", "-Y", "+Y", "-Z", "+Z"], id: \.self) { value in
                Text(value).tag(value).font(.caption).background(.white.opacity(0.5))
            }
        }
        .ballRotation($ballConstraint.rollPitchYaw, pitchLimit: pitchLimit, yawLimit: yawLimit)
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
        .inspector(isPresented: $isInspectorPresented) {
            Form {
                Section("Map") {
                    MapInspector(camera: $camera, models: []).aspectRatio(1, contentMode: .fill)
                }
                Section("Rasterizer") {
                    // Toggle("Axis Rules", isOn: options.contains(.showAxisRules))
                    Toggle("Draw Polygon Normals", isOn: $rasterizerOptions.drawNormals)
                    TextField("Normals Length", value: $rasterizerOptions.normalsLength, format: .number)
                    Toggle("Shade Normals", isOn: $rasterizerOptions.shadeFragmentsWithNormals)
                    Toggle("Fill", isOn: $rasterizerOptions.fill)
                    Toggle("Stroke", isOn: $rasterizerOptions.stroke)
                    Toggle("Backface Culling", isOn: $rasterizerOptions.backfaceCulling)
                }
                Section("Track Ball") {
                    TextField("Pitch Limit", value: $pitchLimit, format: ClosedRangeFormatStyle(substyle: .angle))
                    TextField("Yaw Limit", value: $pitchLimit, format: ClosedRangeFormatStyle(substyle: .angle))
                }
                Section("Camera") {
                    CameraInspector(camera: $camera)
                }
                Section("Model Transform") {
                    TransformEditor(transform: $modelTransform)
                }
                Section("Ball Constraint") {
                    BallConstraintEditor(ballConstraint: $ballConstraint)
                }
            }
            .inspectorColumnWidth(min: 320, ideal: 320)
            .frame(maxWidth: .infinity)
            .controlSize(.small)
        }
        .toolbar {
            Toggle(isOn: $isInspectorPresented, label: { Label("Inspector", systemImage: "sidebar.right") })
                .toggleStyle(.button)
        }
    }
}

struct BallConstraint: Equatable {
    var radius: Float = -5
    var lookAt: SIMD3<Float> = .zero
    var rollPitchYaw: RollPitchYaw = .zero

    var transform: simd_float4x4 {
        rollPitchYaw.matrix * simd_float4x4(translate: [0, 0, radius])
    }
}

struct BallConstraintEditor: View {
    @Binding
    var ballConstraint: BallConstraint

    var body: some View {
        TextField("Radius", value: $ballConstraint.radius, format: .number)
        TextField("Look AT", value: $ballConstraint.lookAt, format: .vector)
        TextField("Pitch", value: $ballConstraint.rollPitchYaw.pitch, format: .angle)
        TextField("Yaw", value: $ballConstraint.rollPitchYaw.yaw, format: .angle)
    }
}

extension TrivialMesh {
    func toPolygons() -> [[Vertex]] {
        indices.chunks(ofCount: 3).map {
            $0.map { vertices[Int($0)] }
        }
    }
}

 struct CameraRotationWidgetView: View {
    @Binding
    var ballConstraint: BallConstraint

    @State
    var camera = Camera(transform: .translation([0, 0, -5]), target: [0, 0, 0], projection: .orthographic(.init(left: -1, right: 1, bottom: -1, top: 1, near: -1, far: 1)))

    @State
    var isHovering = false

    var length: Float = 0.75

    enum Axis: CaseIterable {
        case x
        case y
        case z

        var vector: SIMD3<Float> {
            switch self {
            case .x:
                [1, 0, 0]
            case .y:
                [0, 1, 0]
            case .z:
                [0, 0, 1]
            }
        }

        var color: Color {
            switch self {
            case .x:
                .red
            case .y:
                .green
            case .z:
                .blue
            }
        }
    }

    init(ballConstraint: Binding<BallConstraint>) {
        self._ballConstraint = ballConstraint
    }

    var body: some View {
        GeometryReader { proxy in
            let projection = Projection3D(size: proxy.size, camera: camera)
            ZStack {
                Canvas { context, _ in
                    context.draw3DLayer(projection: projection) { _, context3D in
                        for axis in Axis.allCases {
                            context3D.stroke(path: Path3D { path in
                                path.move(to: axis.vector * -length)
                                path.addLine(to: axis.vector * length)
                            }, with: .color(axis.color), lineWidth: 2)
                        }
                    }
                }
                .zIndex(-.greatestFiniteMagnitude)

                ForEach(Axis.allCases, id: \.self) { axis in
                    Button("-\(axis)") {
                        ballConstraint.rollPitchYaw.setAxis(axis.vector * -1)
                    }
                    .buttonStyle(CameraWidgetButtonStyle())
                    .backgroundStyle(axis.color)
                    .offset(projection.project(axis.vector * -length))
                    .zIndex(Double(projection.worldSpaceToClipSpace(axis.vector * length).z))

                    Button("+\(axis)") {
                        ballConstraint.rollPitchYaw.setAxis(axis.vector)
                    }
                    .buttonStyle(CameraWidgetButtonStyle())
                    .backgroundStyle(axis.color)
                    .offset(projection.project(axis.vector * length))
                    .zIndex(Double(projection.worldSpaceToClipSpace(axis.vector * -length).z))
                }
            }
            .onChange(of: ballConstraint, initial: true) {
                camera.transform.matrix = ballConstraint.transform
            }
            .ballRotation($ballConstraint.rollPitchYaw)
            .background(isHovering ? .white.opacity(0.5) : .clear)
            .onHover { isHovering = $0 }
        }
    }
}

extension Projection3D {
    init(size: CGSize, camera: Camera) {
        var projection = Projection3D(size: size)
        projection.viewTransform = camera.transform.matrix.inverse
        projection.projectionTransform = camera.projection.matrix(viewSize: .init(size))
        projection.clipTransform = simd_float4x4(scale: [Float(size.width) / 2, Float(size.height) / 2, 1])
        self = projection
    }

    func worldSpaceToScreenSpace(_ point: SIMD3<Float>) -> CGPoint {
        var point = worldSpaceToClipSpace(point)
        point /= point.w
        return CGPoint(x: Double(point.x), y: Double(point.y))
    }

    func worldSpaceToClipSpace(_ point: SIMD3<Float>) -> SIMD4<Float> {
        clipTransform * projectionTransform * viewTransform * SIMD4<Float>(point, 1.0)
    }

    //    public func unproject(_ point: CGPoint, z: Float) -> SIMD3<Float> {
    //        // We have no model. Just use view.
    //        let modelView = viewTransform
    //        return gluUnproject(win: SIMD3<Float>(Float(point.x), Float(point.y), z), modelView: modelView, proj: projectionTransform, viewOrigin: .zero, viewSize: SIMD2<Float>(size))
    //    }

    func isVisible(_ point: SIMD3<Float>) -> Bool {
        worldSpaceToClipSpace(point).z >= 0
    }
}

struct CameraWidgetButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
        .foregroundColor(.white)
        .padding(2)
        .background {
            Circle().fill(.background)
                .opacity(configuration.isPressed ? 0.5 : 1.0)
        }
    }
}

extension RollPitchYaw {
    mutating func setAxis(_ vector: SIMD3<Float>) {
        switch vector {
        case [-1, 0, 0]:
            self = .init(roll: .degrees(0), pitch: .degrees(0), yaw: .degrees(90))
        case [1, 0, 0]:
            self = .init(roll: .degrees(0), pitch: .degrees(0), yaw: .degrees(270))
        case [0, -1, 0]:
            self = .init(roll: .degrees(0), pitch: .degrees(90), yaw: .degrees(0))
        case [0, 1, 0]:
            self = .init(roll: .degrees(0), pitch: .degrees(270), yaw: .degrees(0))
        case [0, 0, -1]:
            self = .init(roll: .degrees(0), pitch: .degrees(180), yaw: .degrees(0))
        case [0, 0, 1]:
            self = .init(roll: .degrees(0), pitch: .degrees(0), yaw: .degrees(0))
        default:
            break
        }
    }
}
