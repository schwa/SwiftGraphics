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

internal struct GaussianSplatNewMinimalView: View {
    @Environment(\.metalDevice)
    private var device

    @Environment(GaussianSplatViewModel<SplatC>.self)
    private var viewModel

    @Environment(\.gpuCounters)
    private var gpuCounters

    private let bounds: ConeBounds

    internal init(bounds: ConeBounds) {
        self.bounds = bounds
    }

    internal var body: some View {
        Group {
            @Bindable
            var viewModel = viewModel
            GaussianSplatRenderView<SplatC>()
                #if os(iOS)
                .ignoresSafeArea()
                #endif
                .modifier(CameraConeController(cameraCone: bounds, transform: $viewModel.scene.unsafeCurrentCameraNode.transform))
                .environment(\.gpuCounters, gpuCounters)
        }
        .background(.black)
        .overlay(alignment: .top) {
            if let gpuCounters {
                TimelineView(.periodic(from: .now, by: 0.25)) { _ in
                    PerformanceHUD(measurements: gpuCounters.current())
                }
            }
        }
        .overlay(alignment: .bottom) {
            if !viewModel.loadProgress.isFinished {
                ProgressView(viewModel.loadProgress)
                    .frame(maxWidth: 320)
                    .padding()
                    .background(.thinMaterial)
                    .cornerRadius(8)
                    .padding()
            }
        }
    }
}
