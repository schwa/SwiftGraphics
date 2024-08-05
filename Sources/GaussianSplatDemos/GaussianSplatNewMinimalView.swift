import BaseSupport
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
        let splats = try! SplatCloud(device: device, url: url)
        self.device = device
        let root = Node(label: "root") {
            Node(label: "camera", content: Camera())
            Node(label: "splats", content: splats)
        }
        self.scene = SceneGraph(root: root)
    }

    public var body: some View {
        GaussianSplatRenderView(scene: scene, debugMode: false, sortRate: 15, metalFXRate: 1)
            #if os(iOS)
            .ignoresSafeArea()
            #endif
            .draggableParameter($cameraConeConstraint.height, axis: .vertical, range: 0...1, scale: 0.01, behavior: .clamping)
            .draggableParameter($cameraConeConstraint.angle.degrees, axis: .horizontal, range: 0...360, scale: 0.1, behavior: .wrapping)
            .onChange(of: cameraConeConstraint.position, initial: true) {
                let cameraPosition = cameraConeConstraint.position
                scene.currentCameraNode!.transform.matrix = look(at: cameraConeConstraint.lookAt, from: cameraPosition, up: [0, 1, 0])
            }
            .overlay(alignment: .bottom) {
                VStack {
                    Text("\(cameraConeConstraint.height)")
                    Text("\(cameraConeConstraint.angle)")
                    Slider(value: $pitch.degrees, in: 0...360).frame(width: 120)
                }
                .padding()
                .background(Color.white)
                .padding()
            }
            .onChange(of: pitch) {
                try! scene.modify(label: "splats") { node in
                    node?.transform.rotation = .rollPitchYaw(.init(pitch: pitch))
                }
            }
    }

    @State
    private var cameraConeConstraint = CameraConeConstraint(cameraCone: .init(apex: [0, 0, 0], axis: [0, 1, 0], apexToTopBase: 0, topBaseRadius: 2, bottomBaseRadius: 2, height: 2))
}
