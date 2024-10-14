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
import Traces
import UniformTypeIdentifiers

// swiftlint:disable force_unwrapping

internal struct GaussianSplatView: View {
    @Environment(\.metalDevice)
    private var device

    @Environment(GaussianSplatViewModel<SplatC>.self)
    private var viewModel

    @Environment(\.gpuCounters)
    private var gpuCounters

    @State
    private var options: OptionsView.Options = .init()

    @State
    private var showOptions: Bool = false

    internal var body: some View {
        Group {
            @Bindable
            var viewModel = viewModel
            GaussianSplatRenderView<SplatC>()
                #if os(iOS)
                .ignoresSafeArea()
                #endif
                .modifier(CameraConeController(cameraCone: viewModel.configuration.bounds, transform: $viewModel.scene.unsafeCurrentCameraNode.transform))
                .environment(\.gpuCounters, gpuCounters)
        }
        .background(.black)
        .overlay(alignment: .topTrailing) {
            Button(systemImage: "gear") {
                showOptions.toggle()
            }
            .buttonStyle(.borderless)
            .padding()
            .popover(isPresented: $showOptions) {
                OptionsView(options: $options)
                    .padding()
            }
        }
        .overlay(alignment: .top) {
            VStack {
                if options.showInfo {
                    VStack {
                        Text(viewModel.splatResource.name).font(.title)
                        Link(viewModel.splatResource.url.absoluteString, destination: viewModel.splatResource.url)
                        Text(viewModel.splatCloud.capacity, format: .number)
                    }
                    .padding()
                    .background(.thinMaterial)
                    .cornerRadius(8)
                    .padding()
                }
                if options.showCounters {
                    if let gpuCounters {
                        TimelineView(.periodic(from: .now, by: 0.25)) { _ in
                            PerformanceHUD(measurements: gpuCounters.current())
                        }
                    }
                }
                if options.showTraces {
                    TracesView(traces: .shared)
                        .allowsHitTesting(false)
                        .padding()
                        .background(.thinMaterial)
                        .padding()
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

struct OptionsView: View {
    struct Options {
        var showInfo: Bool = true
        var showTraces: Bool = true
        var showCounters: Bool = true
    }

    @Binding
    var options: Options

    var body: some View {
        Form {
            Toggle("Show Info", isOn: $options.showInfo)
            Toggle("Show Traces", isOn: $options.showTraces)
            Toggle("Show Counters", isOn: $options.showCounters)
        }
    }
}
