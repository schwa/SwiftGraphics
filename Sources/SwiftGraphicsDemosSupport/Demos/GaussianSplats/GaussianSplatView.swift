import SwiftUI
import RenderKit
import SIMDSupport
import SwiftGraphicsSupport
import RenderKitShaders
import MetalSupport
import Shapes3D
import MetalKit
import simd
import Observation
import Everything
import UniformTypeIdentifiers
import SwiftFormats

extension UTType {
    static let splatC = UTType(filenameExtension: "splatc")!
}

struct GaussianSplatView: View, DemoView {

    @State
    var device = MTLCreateSystemDefaultDevice()!

    @State
    var viewModel: GaussianSplatViewModel?

    var body: some View {
        ZStack {
            Color.white
            if let viewModel {
                GaussianSplatRenderView(device: device).environment(viewModel)
            }
        }
        .toolbar {
            ValueView(value: false) { isPresented in
                Toggle("Load", isOn: isPresented)
                .fileImporter(isPresented: isPresented, allowedContentTypes: [.splatC]) { result in
                    if case let .success(url) = result {
                        viewModel = try! GaussianSplatViewModel(device: device, url: url)
                    }
                }
            }
        }
        .onAppear {
            let url = Bundle.module.url(forResource: "train.splatc", withExtension: "data")!
            viewModel = try! GaussianSplatViewModel(device: device, url: url)
        }

    }
}

@Observable
class GaussianSplatViewModel {
    var splatCount: Int
    var splats: MTLBuffer
    var splatIndices: MTLBuffer
    var splatDistances: MTLBuffer
    var cube: MTKMesh // TODO: RENAME

    init(device: MTLDevice, url: URL) throws {
        let data = try! Data(contentsOf: url)
        let splatSize = 26
        let splatCount = data.count / splatSize
        splats = device.makeBuffer(data: data, options: .storageModeShared)!.labelled("Splats")
        let splatIndicesData = (0 ..< splatCount).map { UInt32($0) }.withUnsafeBytes {
            Data($0)
        }
        splatIndices = device.makeBuffer(data: splatIndicesData, options: .storageModeShared)!.labelled("Splats-Indices")
        splatDistances = device.makeBuffer(length: MemoryLayout<Float>.size * splatCount, options: .storageModeShared)!.labelled("Splat-Distances")
        self.splatCount = splatCount

        let allocator = MTKMeshBufferAllocator(device: device)
        cube = try! MTKMesh(mesh: MDLMesh(planeWithExtent: [2, 2, 0], segments: [1, 1], geometryType: .triangles, allocator: allocator), device: device)
    }

}


struct GaussianSplatRenderView: View {
    @State
    var cameraTransform: Transform = .translation([0, 0, 3])

    @State
    var cameraProjection: Projection = .perspective(.init())

    @State
    var modelTransform: Transform = .init(scale: [1, 1, 1])

    @State
    var device: MTLDevice

    @State
    var debugMode: Bool = false

    @State
    var sortRate: Int = 1

    @Environment(GaussianSplatViewModel.self)
    var viewModel

    @State
    var size: CGSize = .zero

    var body: some View {
        RenderView(device: device, passes: passes)
        .onGeometryChange(for: CGSize.self) { proxy in
            return proxy.size
        }
        action: { size in
            self.size = size
        }


        .ballRotation($modelTransform.rotation.rollPitchYaw, pitchLimit: .radians(-.infinity) ... .radians(.infinity))
        .overlay(alignment: .bottom) {
            VStack {
                Text("Size: \(size, format: .size)")
                Text("#splats: \(viewModel.splatCount)")
                Slider(value: $cameraTransform.translation.z, in: 0.0 ... 20.0) { Text("Distance") }
                    .frame(maxWidth: 120)
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
            splatDistances: Box(viewModel.splatDistances),
            pointMesh: viewModel.cube,
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
