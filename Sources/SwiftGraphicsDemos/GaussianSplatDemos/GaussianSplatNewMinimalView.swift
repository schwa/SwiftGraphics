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

struct GaussianSplatNewMinimalView: View {
    @Environment(\.metalDevice)
    var device

    @Environment(GaussianSplatViewModel<SplatC>.self)
    var viewModel

    @State
    private var cameraCone: CameraCone = .init(apex: [0, 0, 0], axis: [0, 1, 0], h1: 0, r1: 0.5, r2: 0.75, h2: 0.5)

    @State
    private var gpuCounters: GPUCounters?

    internal var body: some View {
        @Bindable
        var viewModel = viewModel

        GaussianSplatRenderView<SplatC>()
        #if os(iOS)
        .ignoresSafeArea()
        #endif
        .modifier(CameraConeController(cameraCone: cameraCone, transform: $viewModel.scene.unsafeCurrentCameraNode.transform))
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
