import Foundation
import SwiftUI
import SIMDSupport
import SwiftFormats

struct SimpleSceneInspector: View {
    @Binding
    var scene: SimpleScene

    let colorSpace = CGColorSpace(name: CGColorSpace.linearSRGB)!

    var body: some View {
        Form {
            Section("Camera") {
                CameraInspector(camera: $scene.camera)
            }
            Section("Light #0") {
                LightInspector(light: $scene.light)
            }
            Section("Ambient Light") {
                ColorPicker("Ambient Light", selection: Binding<CGColor>(simd: $scene.ambientLightColor, colorSpace: colorSpace), supportsOpacity: false)
            }
            Section("Models") {
                Text(String(describing: scene.models.count))
            }
        }
    }
}

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
        self.type = projection.wrappedValue.meta
        self._projection = projection
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
            Text("Unimplemented")
        case .perspective(let projection):
            let projection = Binding {
                return projection
            } set: { newValue in
                self.projection = .perspective(newValue)
            }
            //                    let fieldOfView = Binding<SwiftUI.Angle>(get: { .degrees(projection.fovy) }, set: { projection.fovy = $0.radians })
            HStack {
                let binding = Binding<SwiftUI.Angle>(radians: projection.fovy.radians)
                TextField("FOVY", value: binding, format: .angle)
                SliderPopoverButton(value: projection.fovy.degrees, in: 0...180, minimumValueLabel: { Image(systemName: "field.of.view.wide") }, maximumValueLabel: { Image(systemName: "field.of.view.ultrawide") })
            }
            TextField("Clipping Distance", value: projection.zClip, format: ClosedRangeFormatStyle(substyle: .number))
        case .orthographic(let projection):
            let projection = Binding {
                return projection
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

struct LightInspector: View {
    @Binding
    var light: Light

    let colorSpace = CGColorSpace(name: CGColorSpace.linearSRGB)!

    var body: some View {
        LabeledContent("Power") {
            HStack {
                TextField("Power", value: $light.power, format: .number)
                    .labelsHidden()
                SliderPopoverButton(value: $light.power)
            }
        }
        ColorPicker("Color", selection: Binding<CGColor>(simd: $light.color, colorSpace: colorSpace), supportsOpacity: false)
        //TextField("Position", value: $light.position, format: .vector)
        TransformEditor(transform: $light.position, options: [.hideScale])
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
        self._transform = transform
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
