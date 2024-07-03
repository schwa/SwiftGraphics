import CoreGraphicsSupport
import Everything
import Foundation
import GaussianSplatSupport
import MetalKit
import MetalSupport
import Observation
import RenderKit
import simd
import SIMDSupport
import SwiftFormats
import SwiftGraphicsSupport
import SwiftUI
import UniformTypeIdentifiers

// swiftlint:disable force_try

extension UTType {
    static let splat = UTType(filenameExtension: "splat")!
    static let splatC = UTType(filenameExtension: "splatc")!
}

public struct GaussianSplatView: View {
    @State
    private var device: MTLDevice

    @State
    private var viewModel: GaussianSplatViewModel

    @State
    private var size: CGSize = .zero

    @Environment(\.displayScale)
    var displayScale

    public init() {
        let device = MTLCreateSystemDefaultDevice()!
        self.device = device
        let url = Bundle.module.url(forResource: "train", withExtension: "splatc")!
        _viewModel = .init(initialValue: try! .init(device: device, url: url))
    }

    public var body: some View {
        GaussianSplatRenderView(device: device)
            .environment(viewModel)
        .onGeometryChange(for: CGSize.self) { proxy in
            proxy.size
        }
        action: { size in
            self.size = size
        }
        .ballRotation($viewModel.modelTransform.rotation.rollPitchYaw, pitchLimit: .radians(-.infinity) ... .radians(.infinity))
        .overlay(alignment: .bottom) {
            VStack {
                Text("Size: [\(size * displayScale, format: .size)]")
                Text("#splats: \(viewModel.splats.splatBuffer.count)")
                HStack {
                    Slider(value: $viewModel.cameraTransform.translation.z, in: 0.0 ... 20.0) { Text("Distance") }
                        .frame(maxWidth: 120)
                    TextField("Distance", value: $viewModel.cameraTransform.translation.z, format: .number)
                        .labelsHidden()
                        .frame(maxWidth: 120)
                }
                Toggle("Debug Mode", isOn: $viewModel.debugMode)
                HStack {
                    Slider(value: $viewModel.sortRate.toDouble, in: 1 ... 60) { Text("Sort Rate") }
                        .frame(maxWidth: 120)
                    Text("\(viewModel.sortRate)")
                }
            }
            .padding()
            .background(.ultraThickMaterial).cornerRadius(8)
            .padding()
        }
        .toolbar {
            ValueView(value: false) { isPresented in
                Toggle("Load", isOn: isPresented)
                    .fileImporter(isPresented: isPresented, allowedContentTypes: [.splatC, .splat]) { result in
                        if case let .success(url) = result {
                            viewModel = try! GaussianSplatViewModel(device: device, url: url)
                        }
                    }
            }
            ForEach(try! Bundle.module.urls(withExtension: "splatc"), id: \.self) { url in
                Button(url.lastPathComponent) {
                    viewModel = try! GaussianSplatViewModel(device: device, url: url)
                }
            }
        }
    }
}

extension Bundle {
    func urls(withExtension extension: String) throws -> [URL] {
        try FileManager().contentsOfDirectory(at: resourceURL!, includingPropertiesForKeys: nil).filter {
            $0.pathExtension == `extension`
        }
    }
}

// MARK: -

extension Int {
    var toDouble: Double {
        get {
            Double(self)
        }
        set {
            self = Int(newValue)
        }
    }
}
