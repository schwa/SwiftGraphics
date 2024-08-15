import BaseSupport
import Constraints3D
import CoreGraphicsUnsafeConformances
import Everything
import Foundation
import GaussianSplatSupport
import MetalKit
import Observation
import Projection
import RenderKit
import RenderKitSceneGraph
import RenderKitUISupport
import simd
import SIMDSupport
import SwiftFormats
import SwiftUI
import SwiftUISupport
import UniformTypeIdentifiers

// swiftlint:disable force_unwrapping

public struct GaussianSplatNewMinimalView: View {
    @State
    private var device: MTLDevice

    @State
    private var scene: SceneGraph

    @State
    private var cameraCone: CameraCone = .init(apex: [0, 0, 0], axis: [0, 1, 0], h1: 0, r1: 0.5, r2: 0.75, h2: 0.5)

    enum Controller {
        case none
        case cone
        case fpv
        case ball
    }

    @State
    private var controller = Controller.cone

    @State
    private var ballConstraint: NewBallConstraint = .init(radius: 0.25)

    public init() {
        let device = MTLCreateSystemDefaultDevice()!
        let url = Bundle.module.url(forResource: "vision_dr", withExtension: "splat")!
        let splats = try! SplatCloud<SplatC>(device: device, url: url)
        self.device = device
        let root = Node(label: "root") {
            Node(label: "camera", content: Camera())
            Node(label: "splats", content: splats).transformed(roll: .zero, pitch: .degrees(270), yaw: .zero).transformed(roll: .zero, pitch: .zero, yaw: .degrees(90)).transformed(translation: [0, 0.25, 0.5])
        }
        self.scene = SceneGraph(root: root)
    }

    public var body: some View {
        GaussianSplatRenderView<SplatC>(scene: scene, debugMode: false, sortRate: 15, metalFXRate: 2)
            #if os(iOS)
            .ignoresSafeArea()
            #endif
            .modifier {
                switch controller {
                case .none:
                    EmptyViewModifier()
                case .cone:
                    CameraConeController(cameraCone: cameraCone, transform: $scene.unsafeCurrentCameraNode.transform)
                case .fpv:
                    FirstPerson3DGameControllerViewModifier(transform: $scene.unsafeCurrentCameraNode.transform)
                case .ball:
                    NewBallControllerViewModifier(constraint: ballConstraint, transform: $scene.unsafeCurrentCameraNode.transform)
                }
            }
            .toolbar {
                Picker("Controller", selection: $controller) {
                    Text("None").tag(Controller.none)
                    Text("Ball").tag(Controller.ball)
                    Text("Cone").tag(Controller.cone)
                    Text("FPV").tag(Controller.fpv)
                }
            }
    }
}
