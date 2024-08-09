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
import SwiftUISupport
import UniformTypeIdentifiers
import Projection


// swiftlint:disable force_unwrapping

public struct GaussianSplatNewMinimalView: View {
    @State
    private var device: MTLDevice

    @State
    private var scene: SceneGraph

    @State
    private var cameraCone: CameraCone = .init(apex: [0, 0, 0], axis: [0, 1, 0], apexToTopBase: 0, topBaseRadius: 2, bottomBaseRadius: 2, height: 2)

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
            Node(label: "splats", content: splats).transformed(roll: .zero, pitch: .degrees(270), yaw: .zero).transformed(roll: .zero, pitch: .zero, yaw: .degrees(90))
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
            .overlay {
                Canvas { context, size in
                    let cameraProjection = scene.currentCamera!.projection
                    let cameraTransform = scene.currentCameraNode!.transform
                    let projection = Projection3DHelper(size: size, cameraProjection: cameraProjection, cameraTransform: cameraTransform)
                    context.draw3DLayer(projection: projection) { context2D, context3D in
                        context3D.drawAxisMarkers()
//                        context3D.draw(cone: cone)

//                        let p0 = projection.worldSpaceToScreenSpace(.zero)
//                        let position = cone.position(h: h, angle: angle)
//                        let p1 = projection.worldSpaceToScreenSpace(position)
//                        context2D.fill(Path.circle(center: p0, radius: 10), with: .color(.purple))
//                        context2D.fill(Path.circle(center: p1, radius: 10), with: .color(.purple))
//                        context2D.stroke(Path(lineSegments: [(p0, p1)]), with: .color(.purple), lineWidth: 2)
                    }
                }
                .allowsHitTesting(false)
            }
            .overlay(alignment: .topTrailing) {
                RotationWidget(rotation: $scene.unsafeCurrentCameraNode.transform.rotation)
                    .frame(width: 100, height: 100)
                    .padding()
            }
            .inspector(isPresented: .constant(true)) {
                Form {
                    Picker("Controller", selection: $controller) {
                        Text("None").tag(Controller.none)
                        Text("Ball").tag(Controller.ball)
                        Text("Cone").tag(Controller.cone)
                        Text("FPV").tag(Controller.fpv)
                    }

                    Section("Cone") {
                        TextField("Apex", value: $cameraCone.apex, format: .vector)
                        TextField("Axis", value: $cameraCone.axis, format: .vector)
                        TextField("H1", value: $cameraCone.apexToTopBase, format: .number)
                        TextField("H2", value: $cameraCone.height, format: .number)
                        TextField("R1", value: $cameraCone.topBaseRadius, format: .number)
                        TextField("R2", value: $cameraCone.bottomBaseRadius, format: .number)
                    }
                    .disabled(controller != .cone)
                    LabeledContent("Ball.Radius") {
                        TextField("Ball Radius", value: $ballConstraint.radius, format: .number)
                        Slider(value: $ballConstraint.radius, in: 0...10).frame(width: 120)
                    }
                }
            }
    }
}
