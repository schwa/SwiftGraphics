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

struct PackedHalf3: Hashable {
    var x: Float16
    var y: Float16
    var z: Float16
}

struct PackedHalf4: Hashable {
    var x: Float16
    var y: Float16
    var z: Float16
    var w: Float16
}

struct SplatC: Equatable {
    var position: PackedHalf3
    var color: PackedHalf4
    var cov_a: PackedHalf3
    var cov_b: PackedHalf3
};

struct SingleSplatView: View, DemoView {

    @State
    var cameraTransform: Transform = .translation([0, 0, 10])

    @State
    var cameraProjection: Projection = .perspective(.init())

    @State
    var modelTransform: Transform = .init(scale: [1, 1, 1])

    @State
    var device: MTLDevice

    @State
    var debugMode: Bool = false

    @State
    var splats: MTLBuffer

    @State
    var splatDistances: MTLBuffer

    @State
    var splatIndices: MTLBuffer

    @State
    var mesh: MTKMesh // TODO: RENAME

    @State
    var splat: SplatC


    init() {
        let device = MTLCreateSystemDefaultDevice()!

        assert(MemoryLayout<SplatC>.size == 26)

        let splat = SplatC(position: .init(x: 0, y: 0, z: 0), color: .init(x: 1, y: 0, z: 1, w: 1), cov_a: .init(x: 1, y: 0, z: 0), cov_b: .init(x: 1, y: 0, z: 0))

        let splats = device.makeBuffer(bytesOf: [splat], options: .storageModeShared)!
        let splatIndices = device.makeBuffer(bytesOf: [UInt32.zero], options: .storageModeShared)!
        let splatDistances = device.makeBuffer(bytesOf: [Float32.zero], options: .storageModeShared)!

        self.device = device
        self.splat = splat
        self.splats = splats
        self.splatIndices = splatIndices
        self.splatDistances = splatDistances
        let allocator = MTKMeshBufferAllocator(device: device)
        self.mesh = try! MTKMesh(mesh: MDLMesh(planeWithExtent: [2, 2, 0], segments: [1, 1], geometryType: .triangles, allocator: allocator), device: device)
    }

    var body: some View {
        RenderView(device: device, passes: passes)
        .onChange(of: splat) {
            let splats = device.makeBuffer(bytesOf: [splat], options: .storageModeShared)!
            self.splats = splats
        }
        .inspector(isPresented: .constant(true)) {
            Form {
                Section("Position") {
                    TextField("X", value: $splat.position.x, format: .number)
                    TextField("Y", value: $splat.position.y, format: .number)
                    TextField("Z", value: $splat.position.z, format: .number)
                }
                Section("Color") {
                    TextField("R", value: $splat.color.x, format: .number)
                    TextField("G", value: $splat.color.y, format: .number)
                    TextField("B", value: $splat.color.z, format: .number)
                    TextField("A", value: $splat.color.w, format: .number)
                }
                Section("COV_A") {
                    TextField("0", value: $splat.cov_a.x, format: .number)
                    TextField("1", value: $splat.cov_a.y, format: .number)
                    TextField("2", value: $splat.cov_a.z, format: .number)
                }
                Section("COV_B") {
                    TextField("0", value: $splat.cov_b.x, format: .number)
                    TextField("1", value: $splat.cov_b.y, format: .number)
                    TextField("2", value: $splat.cov_b.z, format: .number)
                }
            }
            Toggle(isOn: $debugMode) {
                Text("Debug")
            }
        }
    }

    var passes: [any PassProtocol] {
        let gaussianSplatRenderPass = GaussianSplatRenderPass(
            cameraTransform: cameraTransform,
            cameraProjection: cameraProjection,
            modelTransform: modelTransform,
            splatCount: 1,
            splats: Box(splats),
            splatIndices: Box(splatIndices),
            splatDistances: Box(splatDistances),
            pointMesh: mesh,
            debugMode: debugMode
        )
        return [
            gaussianSplatRenderPass
        ]
    }
}
