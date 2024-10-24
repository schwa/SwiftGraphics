import Foundation
import MetalKit
import Observation
import PanoramaSupport
import simd
import SwiftUI

// swiftlint:disable force_unwrapping

@available(iOS 17, macOS 14, visionOS 1, *)
public struct UFOView: View {
    @Environment(\.metalDevice)
    private var device

    @Environment(GaussianSplatViewModel<SplatC>.self)
    private var viewModel

    @State
    private var bounds: ConeBounds

    public init(bounds: ConeBounds) {
        self.bounds = bounds
    }

    public var body: some View {
        @Bindable
        var viewModel = viewModel

        return GaussianSplatRenderView<SplatC>()
#if os(iOS)
            .ignoresSafeArea()
#endif
            .modifier(CameraConeController(cameraCone: bounds, transform: $viewModel.scene.unsafeCurrentCameraNode.transform))
    }
}
