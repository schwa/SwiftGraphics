import CoreGraphicsSupport
import Fields3D
import Metal
import MetalKit
import MetalSupport
import RenderKit
import simd
import SIMDSupport
import SwiftUI
import SwiftUISupport

public struct SceneGraphView: View {
    let device: MTLDevice

    @Binding
    private var scene: SceneGraph

    let passes: [any PassProtocol]

    public init(device: MTLDevice, scene: Binding<SceneGraph>, passes: [any PassProtocol]) {
        self.device = device
        self._scene = scene
        self.passes = passes
    }

    public var body: some View {
        RenderView(device: device, passes: passes)
            .modifier(SceneGraphViewModifier(device: device, scene: $scene, passes: passes))
    }
}

public struct SceneGraphViewModifier: ViewModifier {
    let device: MTLDevice

    @Binding
    private var scene: SceneGraph

    let passes: [any PassProtocol]

    @State
    private var cameraRotation = RollPitchYaw()

    @State
    private var drawableSize: SIMD2<Float>?

    @State
    private var updatesPitch: Bool = true

    @State
    private var updatesYaw: Bool = true

    @State
    private var mapScale: Double = 10

    public init(device: MTLDevice, scene: Binding<SceneGraph>, passes: [any PassProtocol]) {
        self.device = device
        self._scene = scene
        self.passes = passes
    }

    public func body(content: Content) -> some View {
        content
            //            .firstPersonInteractive(camera: $scene.currentCameraNode.unsafeBinding())
            .onGeometryChange(for: CGSize.self, of: \.size) { drawableSize = SIMD2<Float>($0) }
            .showFrameEditor()
            .onChange(of: cameraRotation, initial: true) {
                let b = BallConstraint(radius: 10, rollPitchYaw: cameraRotation)
                scene.currentCameraNode?.transform = b.transform
            }
            .ballRotation($cameraRotation, updatesPitch: updatesPitch, updatesYaw: updatesYaw)
            .overlay(alignment: .bottomTrailing) {
                VStack {
                    HStack {
                        Toggle(updatesYaw ? "Yaw: On" : "Yaw: Off", isOn: $updatesYaw)
                        Toggle(updatesPitch ? "Pitch: On" : "Pitch: Off", isOn: $updatesPitch)
                    }
                    .padding(2)
                    .toggleStyle(.button)
                    .controlSize(.mini)

                    ZStack {
                        if let drawableSize, drawableSize != .zero {
                            SceneGraphMapView(scene: $scene, scale: mapScale, drawableSize: drawableSize)
                        }
                    }
                    .frame(width: 320, height: 320)
                    .fixedSize()

                    HStack {
                        Button("-") {
                            mapScale = max(mapScale - 1, 1)
                        }
                        TextField("Scale", value: $mapScale, format: .number)
                            .labelsHidden()
                            .frame(maxWidth: 30)
                        Button("+") {
                            mapScale += 1
                        }
                    }
                    .controlSize(.mini)
                    .padding(.bottom, 4)
                }
                .background(Color.black)
                .cornerRadius(8)
                .border(Color.white)
                .padding()
            }
            .inspector(isPresented: .constant(true)) {
                SceneGraphInspector(scene: $scene)
            }
    }
}

struct SceneGraphInspector: View {
    @Binding
    var scene: SceneGraph

    @State
    private var selection: Node.ID?

    var body: some View {
        VSplitView {
            List([scene.root], children: \.optionalChildren, selection: $selection) { node in
                if !node.label.isEmpty {
                    Text("Node: \"\(node.label)\"")
                }
                else {
                    Text("Node: <unnamed>")
                }
            }
            .frame(minHeight: 320)
            Group {
                if let selection, let indexPath = scene.firstIndexPath(id: selection) {
                    let node: Binding<Node> = $scene.binding(for: indexPath)
                    //                let node = scene.root[indexPath: indexPath]
                    List {
                        Form {
                            LabeledContent("ID", value: "\(node.wrappedValue.id)")
                            LabeledContent("Label", value: node.wrappedValue.label)
                            TransformEditor(node.transform)
                            VectorEditor(node.transform.translation)
                        }
                    }
                }
            }
            .frame(minHeight: 320)
        }
    }
}

extension Node {
    var optionalChildren: [Node]? {
        children.isEmpty ? nil : children
    }
}
