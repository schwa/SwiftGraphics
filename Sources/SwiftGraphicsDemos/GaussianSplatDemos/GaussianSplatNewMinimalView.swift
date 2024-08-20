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
    private var cameraCone: CameraCone = .init(apex: [0, 0, 0], axis: [0, 1, 0], h1: 0, r1: 0.5, r2: 0.75, h2: 0.5)

    @State
    private var gpuCounters: GPUCounters?

    let sortRate: Int
    let metalFXRate: Float
    let discardRate: Float

    @State
    private var nextFrame: Int = 0

    @State
    private var viewModel: GaussianSplatViewModel<SplatC>

    @Environment(\.logger)
    var logger

    public init(url: URL, sortRate: Int = 15, metalFXRate: Float = 2, discardRate: Float = 0, useGPUCounters: Bool = false) throws {
        let device = MTLCreateSystemDefaultDevice()!
        let splats = try SplatCloud<SplatC>(device: device, url: url)
        if useGPUCounters {
            let gpuCounters = try GPUCounters(device: device)
            self.gpuCounters = gpuCounters
        }
        self.sortRate = sortRate
        self.metalFXRate = metalFXRate
        self.discardRate = discardRate
        self.device = device
        let root = Node(label: "root") {
            Node(label: "camera", content: Camera())
            Node(label: "splats", content: splats).transformed(roll: .zero, pitch: .degrees(270), yaw: .zero).transformed(roll: .zero, pitch: .zero, yaw: .degrees(90)).transformed(translation: [0, 0.25, 0.5])
        }
        let scene = SceneGraph(root: root)

        self.viewModel = try GaussianSplatViewModel<SplatC>(device: device, scene: scene, debugMode: false, sortRate: sortRate, metalFXRate: metalFXRate, discardRate: discardRate)
    }

    public var body: some View {
        GaussianSplatRenderView<SplatC>()
            .environment(viewModel)
            #if os(iOS)
            .ignoresSafeArea()
            #endif
            .modifier(CameraConeController(cameraCone: cameraCone, transform: $viewModel.scene.unsafeCurrentCameraNode.transform))
            .task {
                viewModel.logger = logger
            }
            .environment(\.gpuCounters, gpuCounters)
            .overlay(alignment: .top) {
                if let gpuCounters {
                    TimelineView(.periodic(from: .now, by: 0.25)) { _ in
                        PerformanceHUD(measurements: gpuCounters.current())
                    }
                }
            }
    }
}
