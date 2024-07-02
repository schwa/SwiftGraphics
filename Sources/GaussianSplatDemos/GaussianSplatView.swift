import CoreGraphicsSupport
import MetalKit
import MetalSupport
import Observation
import simd
import SwiftFormats
import SwiftGraphicsSupport
import SwiftUI
import UniformTypeIdentifiers
import SIMDSupport
import RenderKit
import Everything
import GaussianSplatSupport
import Foundation

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

@Observable
class GaussianSplatViewModel {
    var splatCount: Int
    var splats: MTLBuffer
    var splatIndices: MTLBuffer
    var splatDistances: MTLBuffer

    init(device: MTLDevice, url: URL) throws {
        let data = try! Data(contentsOf: url)

        let splats: MTLBuffer
        let splatCount: Int
        if url.pathExtension == "splatc" {
            let splatSize = 26
            splatCount = data.count / splatSize
            splats = try device.makeBuffer(data: data, options: .storageModeShared).labelled("Splats")
        }
        else if url.pathExtension == "splat" {
            let splatArray = data.withUnsafeBytes { buffer in
                buffer.withMemoryRebound(to: SplatB.self) { buffer in
                    convert(buffer)
                }
            }
            splats = try device.makeBuffer(bytesOf: splatArray, options: .storageModeShared).labelled("Splats")
            splatCount = splatArray.count
        }
        else {
            fatalError()
        }

        let splatIndicesData = (0 ..< splatCount).map { UInt32($0) }.withUnsafeBytes {
            Data($0)
        }
        splatIndices = try device.makeBuffer(data: splatIndicesData, options: .storageModeShared).labelled("Splats-Indices")
        splatDistances = device.makeBuffer(length: MemoryLayout<Float>.size * splatCount, options: .storageModeShared)!.labelled("Splat-Distances")
        self.splats = splats
        self.splatCount = splatCount
    }
}

struct GaussianSplatRenderView: View {
    @State
    private var cameraTransform: Transform = .translation([0, 0, 3])

    @State
    private var cameraProjection: Projection = .perspective(.init())

    @State
    private var modelTransform = Transform(scale: [1, 1, 1])

    @State
    private var device: MTLDevice

    @State
    private var debugMode: Bool = false

    @State
    private var sortRate: Int = 1

    @Environment(GaussianSplatViewModel.self)
    var viewModel

    @State
    private var size: CGSize = .zero

    @Environment(\.displayScale)
    var displayScale

    init(device: MTLDevice) {
        self.device = device
    }

    var body: some View {
        RenderView(device: device, passes: passes)
            .onGeometryChange(for: CGSize.self) { proxy in
                proxy.size
            }
            action: { size in
                self.size = size
            }
            .ballRotation($modelTransform.rotation.rollPitchYaw, pitchLimit: .radians(-.infinity) ... .radians(.infinity))
            .overlay(alignment: .bottom) {
                VStack {
                    Text("Size: [\(size * displayScale, format: .size)]")
                    Text("#splats: \(viewModel.splatCount)")
                    HStack {
                        Slider(value: $cameraTransform.translation.z, in: 0.0 ... 20.0) { Text("Distance") }
                            .frame(maxWidth: 120)
                        TextField("Distance", value: $cameraTransform.translation.z, format: .number)
                            .labelsHidden()
                            .frame(maxWidth: 120)
                    }
                    Toggle("Debug Mode", isOn: $debugMode)
                    HStack {
                        Slider(value: $sortRate.toDouble, in: 1 ... 60) { Text("Sort Rate") }
                            .frame(maxWidth: 120)
                        Text("\(sortRate)")
                    }
                }
                .padding()
                .background(.ultraThickMaterial).cornerRadius(8)
                .padding()
            }
    }

    var passes: [any PassProtocol] {
        let preCalcComputePass = GaussianSplatPreCalcComputePass(
            splatCount: viewModel.splatCount,
            splatDistancesBuffer: Box(viewModel.splatDistances),
            splatBuffer: Box(viewModel.splats),
            modelMatrix: simd_float3x3(truncating: modelTransform.matrix),
            cameraPosition: cameraTransform.translation
        )

        let gaussianSplatSortComputePass = GaussianSplatBitonicSortComputePass(
            splatCount: viewModel.splatCount,
            splatIndicesBuffer: Box(viewModel.splatIndices),
            splatDistancesBuffer: Box(viewModel.splatDistances),
            sortRate: sortRate
        )

        let gaussianSplatRenderPass = GaussianSplatRenderPass(
            cameraTransform: cameraTransform,
            cameraProjection: cameraProjection,
            modelTransform: modelTransform,
            splatCount: viewModel.splatCount,
            splats: Box(viewModel.splats),
            splatIndices: Box(viewModel.splatIndices),
            debugMode: debugMode
        )

        return [
            preCalcComputePass,
            gaussianSplatSortComputePass,
            gaussianSplatRenderPass
        ]
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
