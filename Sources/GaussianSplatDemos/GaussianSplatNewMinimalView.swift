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

    @State
    private var cameraCone: CameraCone = .init(apex: [0, 0, 0], axis: [1, 0, 0], apexToTopBase: 0, topBaseRadius: 2, bottomBaseRadius: 2, height: 2)

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
        GaussianSplatRenderView<SplatC>(scene: scene, debugMode: false, sortRate: 15, metalFXRate: 2)
            #if os(iOS)
            .ignoresSafeArea()
            #endif
            .modifier(CameraConeController(cameraCone: cameraCone, transform: $scene.unsafeCurrentCameraNode.transform))
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
            .inspector(isPresented: .constant(true)) {
                Form {
                    Section("Cone") {
                        TextField("Apex", value: $cameraCone.apex, format: .vector)
                        TextField("Axis", value: $cameraCone.axis, format: .vector)
                        TextField("H1", value: $cameraCone.apexToTopBase, format: .number)
                        TextField("H2", value: $cameraCone.height, format: .number)
                        TextField("R1", value: $cameraCone.topBaseRadius, format: .number)
                        TextField("R2", value: $cameraCone.bottomBaseRadius, format: .number)
                    }
                }
            }
    }
}
