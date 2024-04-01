import CoreGraphicsSupport
import Foundation
import simd
import SIMDSupport
import SwiftFormats
import SwiftUI

struct CameraInspector: View {
    @Binding
    var camera: Camera

    var body: some View {
        Section("Transform") {
            TransformEditor(transform: $camera.transform, options: [.hideScale])
            TextField("Heading", value: $camera.heading.degrees, format: .number)
            TextField("Target", value: $camera.target, format: .vector)
        }
        Section("Projection") {
            ProjectionInspector(projection: $camera.projection)
        }
    }
}

struct ProjectionInspector: View {
    @State
    var type: Projection.Meta

    @Binding
    var projection: Projection

    init(projection: Binding<Projection>) {
        type = projection.wrappedValue.meta
        _projection = projection
    }

    var body: some View {
        Picker("Type", selection: $type) {
            ForEach(Projection.Meta.allCases, id: \.self) { type in
                Text(describing: type).tag(type)
            }
        }
        .labelsHidden()
        .onChange(of: type) {
            guard type != projection.meta else {
                return
            }
            switch type {
            case .matrix:
                projection = .matrix(.identity)
            case .perspective:
                projection = .perspective(.init(fovy: .degrees(90), zClip: 0.001 ... 1000))
            case .orthographic:
                projection = .orthographic(.init(left: -1, right: 1, bottom: -1, top: 1, near: -1, far: 1))
            }
        }
        switch projection {
        case .matrix(let projection):
            let projection = Binding {
                projection
            } set: { newValue in
                self.projection = .matrix(newValue)
            }
            Text("UNIMPLEMENTED")
        case .perspective(let projection):
            let projection = Binding {
                projection
            } set: { newValue in
                self.projection = .perspective(newValue)
            }
            //                    let fieldOfView = Binding<SwiftUI.Angle>(get: { .degrees(projection.fovy) }, set: { projection.fovy = $0.radians })
            HStack {
                let binding = Binding<SwiftUI.Angle>(radians: projection.fovy.radians)
                TextField("FOVY", value: binding, format: .angle)
                // SliderPopoverButton(value: projection.fovy.degrees, in: 0...180, minimumValueLabel: { Image(systemName: "field.of.view.wide") }, maximumValueLabel: { Image(systemName: "field.of.view.ultrawide") })
            }
            TextField("Clipping Distance", value: projection.zClip, format: ClosedRangeFormatStyle(substyle: .number))
        case .orthographic(let projection):
            let projection = Binding {
                projection
            } set: { newValue in
                self.projection = .orthographic(newValue)
            }
            TextField("Left", value: projection.left, format: .number)
            TextField("Right", value: projection.right, format: .number)
            TextField("Bottom", value: projection.bottom, format: .number)
            TextField("Top", value: projection.top, format: .number)
            TextField("Near", value: projection.near, format: .number)
            TextField("Far", value: projection.far, format: .number)
        }
    }
}

struct TransformEditor: View {
    struct Options: OptionSet {
        let rawValue: Int
        static let hideScale = Self(rawValue: 1 << 0)

        static let `default` = Self([])
    }

    @Binding
    var transform: Transform

    let options: Options

    init(transform: Binding<Transform>, options: Options = .default) {
        _transform = transform
        self.options = options
    }

    var body: some View {
        if !options.contains(.hideScale) {
            TextField("Scale", value: $transform.scale, format: .vector)
        }
        TextField("Rotation", value: $transform.rotation, format: .quaternion)
        TextField("Translation", value: $transform.translation, format: .vector)
    }
}

struct MapInspector: View {
    @Binding
    var camera: Camera

    var models: [SIMD3<Float>]

    var body: some View {
        Canvas { context, size in
            context.translateBy(x: size.width / 2, y: size.height / 2)
            context.stroke(Path { path in
                path.addLines([[-size.width / 2, 0], [size.width / 2, 0]])
            }, with: .color(.red))
            context.stroke(Path { path in
                path.addLines([[0, -size.height / 2], [0, size.height / 2]])
            }, with: .color(.blue))
            context.fill(Path(ellipseIn: CGRect(center: .zero, radius: 4)), with: .color(.red))

            let cameraPosition = CGPoint(camera.transform.translation.xz) * [5, 5]
            context.fill(Path(ellipseIn: CGRect(center: cameraPosition, radius: 4)), with: .color(.yellow))

            context.stroke(Path { path in
                path.move(to: cameraPosition)
                let unit = camera.transform.matrix * SIMD4<Float>(0, 1, 0, -1)
//                path.addLine(to: cameraPosition + CGPoint(unit.xz) * -2)
                path.addLine(to: CGPoint(unit.xz) * 2, relative: true)
            }, with: .color(.yellow), lineWidth: 2)
        }
        .background(.black)
    }
}

extension Path {
    mutating func addLine(to point: CGPoint, relative: Bool) {
        addLine(to: relative ? (currentPoint ?? .zero) + point : point)
    }
}

extension CGPoint {
    init(angle: SwiftUI.Angle, length: Double) {
        self = .init(x: cos(angle.radians) * length, y: sin(angle.radians) * length)
    }
}
