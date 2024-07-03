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
    private var device = MTLCreateSystemDefaultDevice()!

    @State
    private var viewModel: GaussianSplatViewModel?

    public init() {
    }

    public var body: some View {
        ZStack {
            Color.white
            if let viewModel {
                GaussianSplatRenderView(device: device).environment(viewModel)
            }
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
        .onAppear {
            let url = Bundle.module.url(forResource: "train", withExtension: "splatc")!
            viewModel = try! GaussianSplatViewModel(device: device, url: url)
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
