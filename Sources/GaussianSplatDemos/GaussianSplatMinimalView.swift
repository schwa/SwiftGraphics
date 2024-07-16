import CoreGraphicsSupport
import Everything
import Foundation
import GaussianSplatSupport
import MetalKit
import MetalSupport
import Observation
import RenderKit
import RenderKitUISupport
import simd
import SIMDSupport
import SwiftFormats
import SwiftUI
import UniformTypeIdentifiers

// swiftlint:disable force_unwrapping

public struct GaussianSplatMinimalView: View {
    @State
    private var device: MTLDevice

    @State
    private var scene: SceneGraph

    @State
    private var cameraRotation = RollPitchYaw()

    @State
    private var ballConstraint = BallConstraint(radius: 0.4)

    @State
    private var isTargeted = false

    @State
    private var metalFXRate: Float = 1

    public init() {
        let device = MTLCreateSystemDefaultDevice()!
        let url = Bundle.module.url(forResource: "train", withExtension: "splat")!
        self.device = device
        let splats = try! SplatCloud(device: device, url: url)
        let root = Node(label: "root") {
            Node(label: "ball") {
                Node(label: "camera")
                    .content(Camera())
            }
            Node(label: "splats").content(splats)
        }
        self.scene = SceneGraph(root: root)
    }

    public var body: some View {
        GaussianSplatRenderView(scene: scene, debugMode: false, sortRate: 30, metalFXRate: metalFXRate)
            .onChange(of: cameraRotation, initial: true) {
                ballConstraint.rollPitchYaw = cameraRotation
            }
            .onChange(of: ballConstraint, initial: true) {
                scene.currentCameraNode?.transform = ballConstraint.transform
            }
            .ballRotation($cameraRotation, pitchLimit: .degrees(-.infinity) ... .degrees(.infinity))
            .gesture(MagnifyGesture().onChanged { value in
                ballConstraint.radius = Float(5 * value.magnification)
            })
            .onDrop(of: [.splat], isTargeted: $isTargeted) { items in
                if let item = items.first {
                    item.loadItem(forTypeIdentifier: UTType.splat.identifier, options: nil) { data, _ in
                        guard let url = data as? URL else {
                            fatalError("No url")
                            return
                        }
                        Task {
                            await MainActor.run {
                                scene.splatsNode.content = try! SplatCloud(device: device, url: url)
                            }
                        }
                    }
                    return true
                } else {
                    return false
                }
            }
            .border(isTargeted ? Color.accentColor : .clear, width: isTargeted ? 4 : 0)
            .toolbar {
                Button("1") {
                    metalFXRate = 1
                }
                Button("2") {
                    metalFXRate = 2
                }
                Button("4") {
                    metalFXRate = 4
                }
                Button("8") {
                    metalFXRate = 8
                }
            }
    }
}
