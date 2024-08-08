import BaseSupport
import Constraints3D
import Everything
import Foundation
import GaussianSplatSupport
import MetalKit
import Observation
import RenderKit
import RenderKitSceneGraph
import RenderKitUISupport
import simd
import SIMDSupport
import SwiftFormats
import SwiftUI
import UniformTypeIdentifiers

// swiftlint:disable force_unwrapping

public struct GaussianSplatNewMinimalView: View {
    @State
    private var device: MTLDevice

    @State
    private var scene: SceneGraph

    @State
    private var pitch = Angle.zero

    public init() {
        let device = MTLCreateSystemDefaultDevice()!
        let url = Bundle.module.url(forResource: "vision_dr", withExtension: "splat")!
        let splats = try! SplatCloud<SplatC>(device: device, url: url)
        self.device = device
        let root = Node(label: "root") {
            Node(label: "camera", content: Camera())
            Node(label: "splats", content: splats)
        }
        self.scene = SceneGraph(root: root)
    }

    public var body: some View {
        GaussianSplatRenderView<SplatC>(scene: scene, debugMode: false, sortRate: 15, metalFXRate: 1)
            #if os(iOS)
            .ignoresSafeArea()
            #endif
            .modifier(FirstPerson3DGameControllerViewModifier(transform: $scene.unsafeCurrentCameraNode.transform))
            .onChange(of: pitch) {
                try! scene.modify(label: "splats") { node in
                    node?.transform.rotation = .rollPitchYaw(.init(pitch: pitch))
                }
            }
            .overlay(alignment: .bottom) {
                VStack {
                    Slider(value: $pitch.degrees, in: 0...360).frame(width: 120)
                }
                .padding()
                .background(Color.white)
                .padding()
            }
    }
}
