import Everything
import Foundation
import SIMDSupport
import SwiftFormats
import SwiftUI

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
        // TextField("Position", value: $light.position, format: .vector)
        TransformEditor(transform: $light.position, options: [.hideScale])
    }
}
