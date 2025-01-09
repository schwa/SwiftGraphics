import BaseSupport
import Widgets3D
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

    @Environment(GaussianSplatViewModel.self)
    private var viewModel

    @Environment(\.gpuCounters)
    private var gpuCounters

    @State
    private var options: OptionsView.Options = .init()

    @State
    private var showOptions: Bool = false

    internal init() {
    }

    internal var body: some View {
        @Bindable
        var viewModel = viewModel

        Group {
            GaussianSplatRenderView()
                #if os(iOS)
                .ignoresSafeArea()
                #endif

                .environment(\.gpuCounters, gpuCounters)
        }
        .background(.black)
        .toolbar {
            Button("Options") {
                showOptions.toggle()
            }
            .buttonStyle(.borderless)
            .padding()
            .popover(isPresented: $showOptions) {
                NavigationStack {
                    Form {
                        OptionsView(options: $options, configuration: $viewModel.configuration)
                    }
                    .toolbar {
                        Button("Close") {
                            showOptions = false
                        }
                    }
                }
                #if os(macOS)
                .padding()
                #endif
            }
        }
        .overlay(alignment: .top) {
            VStack {
                if options.showInfo {
                    InfoView()
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
