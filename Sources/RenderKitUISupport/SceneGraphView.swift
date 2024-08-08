import Constraints3D
import Fields3D
import Metal
import MetalKit
import RenderKit
import RenderKitSceneGraph
import simd
import SIMDSupport
import SwiftUI
import SwiftUISupport

public struct SceneGraphView: View {
    @Binding
    private var scene: SceneGraph

    let passes: [any PassProtocol]

    public init(scene: Binding<SceneGraph>, passes: [any PassProtocol]) {
        self._scene = scene
        self.passes = passes
    }

    public var body: some View {
        RenderView(passes: passes)
            .modifier(SceneGraphViewModifier(scene: $scene))
    }
}

// MARK: -

public struct SceneGraphViewModifier: ViewModifier {
    @Binding
    private var scene: SceneGraph

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

    @State
    private var ballConstraint = BallConstraint()

    @State
    private var smallMap = true

    @State
    private var isInspectorPresented = false

    public init(scene: Binding<SceneGraph>) {
        self._scene = scene
    }

    public func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem {
                    Toggle(isOn: $isInspectorPresented) {
                        Image(systemName: "sidebar.trailing")
                    }
                }
            }
            //            .firstPersonInteractive(camera: $scene.currentCameraNode.unsafeBinding())
            .onGeometryChange(for: CGSize.self, of: \.size) { drawableSize = SIMD2<Float>($0) }
            .showFrameEditor()
            .onChange(of: cameraRotation, initial: true) {
                ballConstraint.rollPitchYaw = cameraRotation
            }
            .onChange(of: ballConstraint, initial: true) {
                scene.currentCameraNode?.transform = ballConstraint.transform
            }
            .ballRotation($cameraRotation, updatesPitch: updatesPitch, updatesYaw: updatesYaw)
            .gesture(MagnifyGesture().onChanged { value in
                ballConstraint.radius = Float(5 * value.magnification)
            })
            .overlay(alignment: .bottomTrailing) {
                VStack {
                    HStack {
                        Toggle(updatesYaw ? "Yaw: On" : "Yaw: Off", isOn: $updatesYaw)
                        Toggle(updatesPitch ? "Pitch: On" : "Pitch: Off", isOn: $updatesPitch)
                        Toggle(smallMap ? "Big" : "Small", isOn: $smallMap)
                    }
                    .padding(2)
                    .toggleStyle(.button)
                    .controlSize(.mini)

                    ZStack {
                        if let drawableSize, drawableSize != .zero {
                            SceneGraphMapView(scene: $scene, ballConstraint: $ballConstraint, scale: mapScale, drawableSize: drawableSize)
                        }
                    }
                    .frame(width: smallMap ? 120 : 320, height: smallMap ? 120 : 320)
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
            .inspector(isPresented: $isInspectorPresented) {
                TabView {
                    Form {
                        Section("Camera") {
                            MatrixEditor($scene.currentCameraNode.unsafeBinding().transform.matrix)
                        }
                        Section("Projection") {
                            ProjectionEditor($scene.currentCamera.unsafeBinding().projection, drawableSize: drawableSize)
                        }
                    }
                    .formStyle(.grouped)
                    .tabItem {
                        Text("Camera")
                    }

                    SceneGraphInspector(scene: $scene)
                        .tabItem {
                            Text("Scene Graph")
                        }
                }
            }
    }
}
