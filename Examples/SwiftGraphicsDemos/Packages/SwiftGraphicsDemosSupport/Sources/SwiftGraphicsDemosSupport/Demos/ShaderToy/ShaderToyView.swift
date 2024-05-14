// import SwiftUI
// import MetalKit
// import ModelIO
// import simd
//  import MetalSupport
//
// struct ShaderToyView: View {
//    @State
//    var offscreen = ShaderToyRenderPass()
//
//    init() {
//    }
//
//    var body: some View {
//        MetalView { configuration in
//            configuration.preferredFramesPerSecond = 120
//            configuration.colorPixelFormat = .bgra10_xr_srgb
//            configuration.depthStencilPixelFormat = .depth32Float // TODO: Overkill
//            offscreen.setup(configuration: configuration)
//        }
//        draw: { configuration in
//            let commandQueue = configuration.device!.makeCommandQueue()
//            commandQueue?.withCommandBuffer(drawable: configuration.currentDrawable, block: { commandBuffer in
//                offscreen.draw(configuration: configuration, commandBuffer: commandBuffer)
//            })
//
//        }
//        .overlay(alignment: .bottom) {
//            Form {
//                TextField("Scale 1/X", value: $offscreen.scale.x, format: .number)
//                TextField("Scale 1/Y", value: $offscreen.scale.y, format: .number)
//                TextField("Speed", value: $offscreen.speed, format: .number)
//                Toggle("Pixelate", isOn: $offscreen.pixelate)
//            }
//            .frame(maxWidth: 120)
//            .padding()
//            .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.8)))
//            .padding()
//        }
//    }
// }
//
// struct ShaderToyRenderPass <UpdateConfiguration, DrawConfiguration>: RenderPass where UpdateConfiguration: RenderKitUpdateConfiguration, DrawConfiguration: RenderKitDrawConfiguration {
//
//    var shaderToyRenderPipelineState: MTLRenderPipelineState?
//    var plane: MTKMesh?
//    var pixelate = true
//    var scale = SIMD2<Float>(16, 16)
//    var speed = Float(1)
//
//    let start = Date.now
//
//    var time: Float {
//        return Float(Date.now.timeIntervalSince(start)) * speed
//    }
//
//    mutating func setup(configuration: inout UpdateConfiguration) {
//        guard let device = configuration.device else {
//            fatalError("No metal device")
//        }
//        let library = try! device.makeDefaultLibrary(bundle: .shaders)
//        let constants = MTLFunctionConstantValues()
//        constants.setConstantValue(bytes(of: pixelate), type: .bool, index: 0)
//
//        let vertexFunction = library.makeFunction(name: "shaderToyVertexShader")!
//        let fragmentFunction = try! library.makeFunction(name: "shaderToyFragmentShader", constantValues: constants)
//        let plane = try! MTKMesh(mesh: Plane().toMDLMesh(extent: [2, 2, 0], allocator: MTKMeshBufferAllocator(device: device)), device: device)
//        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
//        renderPipelineDescriptor.vertexFunction = vertexFunction
//        renderPipelineDescriptor.fragmentFunction = fragmentFunction
//        renderPipelineDescriptor.colorAttachments[0].pixelFormat = configuration.colorPixelFormat
//        renderPipelineDescriptor.depthAttachmentPixelFormat = configuration.depthStencilPixelFormat
//        renderPipelineDescriptor.vertexDescriptor = MTLVertexDescriptor(plane.vertexDescriptor)
//        let shaderToyRenderPipelineState = try! device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
//        self.plane = plane
//        self.shaderToyRenderPipelineState = shaderToyRenderPipelineState
//    }
//
//    func draw(configuration: UpdateConfiguration, commandBuffer: MTLCommandBuffer) {
//        guard let renderPassDescriptor = configuration.currentRenderPassDescriptor, let shaderToyRenderPipelineState, let plane else {
//            logger.warning("No current render pass descriptor.")
//            return
//        }
//        commandBuffer.withRenderCommandEncoder(descriptor: renderPassDescriptor) { encoder in
//            encoder.setRenderPipelineState(shaderToyRenderPipelineState)
//
//            encoder.setVertexBytes(of: simd_float4x3.identity, index: 1)
//
//            var fragmentUniforms: [UInt8] = []
//            fragmentUniforms.append(contentsOf: bytes(of: time), alignment: 8)
//            fragmentUniforms.append(contentsOf: bytes(of: 1 / scale), alignment: 8)
//            encoder.setFragmentBytes(fragmentUniforms, length: fragmentUniforms.count, index: 2)
//
//            encoder.draw(plane)
//        }
//    }
//
//
// }
