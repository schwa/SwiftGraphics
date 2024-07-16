import CoreGraphicsSupport
import MetalKit
import MetalSupport
import MetalUISupport
import ModelIO
import RenderKitShadersLegacy
import SwiftUI

struct TextureDemoView: View, DemoView {
    @State
    private var showDebugView = false

    var body: some View {
        TextureView(named: "seamless-foods-mixed-0020", bundle: .module, options: showDebugView ? [.showInfo] : [])
            .overlay(alignment: .bottomTrailing) {
                Image(systemName: "contextualmenu.and.cursorarrow")
                    .foregroundColor(.white)
                    .padding()
                    .background(Circle().fill(.regularMaterial))
                    .padding()
            }
            .contextMenu {
                Button("Show Info") {
                    showDebugView.toggle()
                }
            }
    }
}

struct TextureView: View {
    struct Bindings {
        var vertexBufferIndex: Int = -1
        var vertexCameraIndex: Int = -1
        var vertexModelTransformsIndex: Int = -1
        var fragmentMaterialsIndex: Int = -1
        var fragmentTexturesIndex: Int = -1
    }

    struct RenderState {
        var mesh: YAMesh
        var commandQueue: MTLCommandQueue
        var bindings: Bindings
        var renderPipelineState: MTLRenderPipelineState
    }

    struct Options: OptionSet {
        let rawValue: Int

        static let showInfo = Self(rawValue: 1 << 0)
    }

    let texture: MTLTexture

    @State
    private var renderState: RenderState?

    @State
    private var size: CGSize?

    var options: Options

    init(texture: MTLTexture, options: Options = []) {
        self.texture = texture
        self.options = options
    }

    var body: some View {
        MetalView { device, configuration in
            configuration.colorPixelFormat = .bgra8Unorm_srgb
            configuration.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
            configuration.depthStencilPixelFormat = .invalid
            configuration.preferredFramesPerSecond = 0
            configuration.enableSetNeedsDisplay = true
            let commandQueue = device.makeCommandQueue()!

            let library = try! device.makeDefaultLibrary(bundle: .renderKitShadersLegacy)
            let vertexFunction = library.makeFunction(name: "unlitVertexShader")!
            let fragmentFunction = library.makeFunction(name: "unlitFragmentShader")!

            let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
            renderPipelineDescriptor.vertexFunction = vertexFunction
            renderPipelineDescriptor.fragmentFunction = fragmentFunction
            renderPipelineDescriptor.colorAttachments[0].pixelFormat = configuration.colorPixelFormat

            let mesh = try YAMesh.simpleMesh(label: "rectangle", primitiveType: .triangle, device: device) {
                let indices: [UInt16] = [
                    0, 1, 2, 0, 3, 2,
                ]
                let vertices = [SIMD2<Float>]([
                    [0, 0],
                    [1, 0],
                    [1, 1],
                    [0, 1],
                ])
                .map {
                    SimpleVertex(position: SIMD3<Float>($0, 0), normal: .zero, textureCoordinate: $0)
                }
                return (indices, vertices)
            }
            let descriptor = mesh.vertexDescriptor
            renderPipelineDescriptor.vertexDescriptor = MTLVertexDescriptor(descriptor)
            let (renderPipelineState, reflection) = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor, options: [.bindingInfo])
            guard let reflection else {
                fatalError()
            }

            var bindings = Bindings()
            bindings.vertexBufferIndex = try reflection.binding(for: "vertexBuffer.0", of: .vertex)
            bindings.vertexCameraIndex = try reflection.binding(for: "camera", of: .vertex)
            bindings.vertexModelTransformsIndex = try reflection.binding(for: "models", of: .vertex)
            bindings.fragmentMaterialsIndex = try reflection.binding(for: "materials", of: .vertex)
            bindings.fragmentTexturesIndex = try reflection.binding(for: "", of: .vertex)

            renderState = RenderState(mesh: mesh, commandQueue: commandQueue, bindings: bindings, renderPipelineState: renderPipelineState)
        } drawableSizeWillChange: { _, _, size in
            self.size = size
        } draw: { _, _, size, currentDrawable, renderPassDescriptor in
            guard let renderState else {
                fatalError("Draw called before command queue set up. This should be impossible.")
            }
            renderState.commandQueue.withCommandBuffer(drawable: currentDrawable) { commandBuffer in
                commandBuffer.label = "RendererView-CommandBuffer"
                commandBuffer.withRenderCommandEncoder(descriptor: renderPassDescriptor) { renderCommandEncoder in
                    renderCommandEncoder.setRenderPipelineState(renderState.renderPipelineState)
                    renderCommandEncoder.setVertexBuffers(renderState.mesh)
                    let displayScale: Float = 2
                    let size = SIMD2<Float>(size) / displayScale
                    let size2 = size / 2

                    var view = simd_float4x4.identity
                    view *= simd_float4x4.scaled([1 / size2.x, -1 / size2.y, 1])
                    view *= simd_float4x4.translation([-min(size.x, size.y) / 2, -min(size.x, size.y) / 2, 1])
                    view *= simd_float4x4.scaled([min(size.x, size.y), min(size.x, size.y), 1])
                    // view *= simd_float4x4.translation([-size2.x, -size2.y, 0])
                    //                    view *= simd_float4x4.translation([-Float(texture.width) / 2, -Float(texture.height) / 2, 0])
                    let cameraUniforms = CameraUniforms(projectionMatrix: view)

                    let modelTransforms = ModelTransforms(modelViewMatrix: .identity, modelNormalMatrix: .identity)
                    renderCommandEncoder.setVertexBytes(of: [modelTransforms], index: renderState.bindings.vertexModelTransformsIndex)

                    renderCommandEncoder.setVertexBytes(of: cameraUniforms, index: renderState.bindings.vertexCameraIndex)

                    let material = RenderKitShadersLegacy.UnlitMaterial(color: [1, 0, 0, 1], textureIndex: 0)
                    renderCommandEncoder.setFragmentBytes(of: [material], index: renderState.bindings.fragmentMaterialsIndex)
                    renderCommandEncoder.setFragmentTextures([texture], range: 0 ..< 1)

                    // renderCommandEncoder.setTriangleFillMode(.fill)

                    renderCommandEncoder.draw(renderState.mesh, instanceCount: 1)
                }
            }
        }
        .aspectRatio(Double(texture.height) / Double(texture.width), contentMode: .fit)
        .overlay(alignment: .topTrailing) {
            if options.contains(.showInfo) {
                Form {
                    LabeledContent("Label", value: "\(texture.label ?? "")")
                    LabeledContent("Type", value: "\(texture.textureType)")
                    LabeledContent("Usage", value: "\(texture.usage)")
                    LabeledContent("Width", value: texture.width, format: .number)
                    LabeledContent("Height", value: texture.height, format: .number)
                    LabeledContent("Depth", value: texture.depth, format: .number)
                    LabeledContent("Mipmap Level Count", value: texture.mipmapLevelCount, format: .number)
                    LabeledContent("Sample Count", value: texture.sampleCount, format: .number)
                    LabeledContent("Array Length", value: texture.arrayLength, format: .number)
                    LabeledContent("Pixel Format", value: "\(texture.pixelFormat)")
                    LabeledContent("Compression Type", value: "\(texture.compressionType)")
                    LabeledContent("Framebuffer Only?", value: texture.isFramebufferOnly, format: .bool)
                    #if os(macOS) // TODO: Fix on iOS
                    LabeledContent("Is Sparse?", value: texture.isSparse ?? false, format: .bool)
                    #endif
                    LabeledContent("Has Parent?", value: texture.parent != nil, format: .bool)
                    LabeledContent("Has Buffer?", value: texture.buffer != nil, format: .bool)
                    if let size {
                        LabeledContent("View Size", value: size, format: .size)
                        LabeledContent("Texels per Pixel", value: CGSize(width: Double(texture.width), height: Double(texture.height)) / size, format: .size)
                    }
                }
                .monospacedDigit()
                .font(.caption)
                .padding()
                .background(.regularMaterial)
                .cornerRadius(8)
                .padding()
            }
        }
    }
}

extension TextureView {
    init(named name: String, bundle: Bundle = .main, options: Options = []) {
        let device = MTLCreateSystemDefaultDevice()!
        let loader = MTKTextureLoader(device: device)
        let texture = try! loader.newTexture(name: name, scaleFactor: 1.0, bundle: bundle)
        self.init(texture: texture, options: options)
    }
}
