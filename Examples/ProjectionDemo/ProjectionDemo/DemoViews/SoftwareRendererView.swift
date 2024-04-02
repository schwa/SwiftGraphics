import Algorithms
import CoreGraphicsSupport
import LegacyGeometryX
import ModelIO
import Projection
import SIMDSupport
import SwiftFormats
import SwiftUI

struct SoftwareRendererView: View {
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
    var axisRules: Bool = true

    @State
    var isInspectorPresented: Bool = true

    var renderer: (Projection3D, inout GraphicsContext, inout GraphicsContext3D) -> Void

    init(renderer: @escaping (Projection3D, inout GraphicsContext, inout GraphicsContext3D) -> Void) {
        camera = Camera(transform: .translation([0, 0, -5]), target: [0, 0, 0], projection: .perspective(.init(fovy: .degrees(90), zClip: 0.01 ... 1000.0)))
        modelTransform = .init(rotation: .init(angle: .degrees(0), axis: [0, 1, 0]))
        ballConstraint = BallConstraint()
        self.renderer = renderer
    }

    var body: some View {
        Canvas { context, size in
            var projection = Projection3D(size: size)
            projection.viewTransform = camera.transform.matrix.inverse
            projection.projectionTransform = camera.projection.matrix(viewSize: .init(size))
            projection.clipTransform = simd_float4x4(scale: [Float(size.width) / 2, Float(size.height) / 2, 1])

            if axisRules {
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
        .ballRotation($ballConstraint.rotation, pitchLimit: pitchLimit, yawLimit: yawLimit)
        .onAppear() {
            camera.transform.matrix = ballConstraint.transform
        }
        .onChange(of: ballConstraint.transform) {
            camera.transform.matrix = ballConstraint.transform
        }
        .inspector(isPresented: $isInspectorPresented) {
            Form {
                Section("Map") {
                    MapInspector(camera: $camera, models: []).aspectRatio(1, contentMode: .fill)
                }
                Section("Rasterizer") {
                    Toggle("Axis Rules", isOn: $axisRules)
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

struct BallConstraint {
    var radius: Float = -5
    var lookAt: SIMD3<Float> = .zero
    var rotation: Rotation = .zero

    var transform: simd_float4x4 {
        rotation.matrix * simd_float4x4(translate: [0, 0, radius])
    }
}

struct BallConstraintEditor: View {
    @Binding
    var ballConstraint: BallConstraint

    var body: some View {
        TextField("Radius", value: $ballConstraint.radius, format: .number)
        TextField("Look AT", value: $ballConstraint.lookAt, format: .vector)
        TextField("Pitch", value: $ballConstraint.rotation.pitch, format: .angle)
        TextField("Yaw", value: $ballConstraint.rotation.yaw, format: .angle)
    }
}

extension TrivialMesh {
    func toPolygons() -> [[Vertex]] {
        indices.chunks(ofCount: 3).map {
            $0.map { vertices[Int($0)] }
        }
    }
}
