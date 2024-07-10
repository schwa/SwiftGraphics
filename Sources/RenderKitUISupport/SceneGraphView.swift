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

    @State
    private var ballConstraint = BallConstraint()

    @State
    private var smallMap = false

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
                ballConstraint.rollPitchYaw = cameraRotation
            }
            .onChange(of: ballConstraint, initial: true) {
                scene.currentCameraNode?.transform = ballConstraint.transform
            }
            .ballRotation($cameraRotation, updatesPitch: updatesPitch, updatesYaw: updatesYaw)
            .gesture(MagnifyGesture().onChanged({ value in
                ballConstraint.radius = Float(5 * value.magnification)
            }))
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
            .inspector(isPresented: .constant(true)) {
                TabView {
                    Color.clear
                    .tabItem {
                        Text("Empty!")
                    }
                    Form {
                        Section("Ball Constaint") {
                            BallConstraintEditor(ballConstraint: $ballConstraint)
                                .controlSize(.small)
                            Button("Reset") {
                                ballConstraint.rollPitchYaw = .zero
                            }
                        }
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
