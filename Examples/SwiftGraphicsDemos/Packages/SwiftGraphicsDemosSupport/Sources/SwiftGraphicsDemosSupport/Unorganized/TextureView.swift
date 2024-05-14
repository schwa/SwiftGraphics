import MetalKit
import MetalSupport
import ModelIO
import RenderKit
import RenderKitShaders
import SwiftUI

public struct TextureView: View {
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

    let texture: MTLTexture

    @State
    var renderState: RenderState?

    @State
    var showDebugView = false

    @State
    var size: CGSize?

    public init(texture: MTLTexture) {
        self.texture = texture
    }

    public var body: some View {
        MetalView { device, configuration in
            configuration.colorPixelFormat = .bgra8Unorm_srgb
            configuration.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
            configuration.depthStencilPixelFormat = .invalid
            configuration.preferredFramesPerSecond = 0
            configuration.enableSetNeedsDisplay = true
            let commandQueue = device.makeCommandQueue()!

            let library = try! device.makeDefaultLibrary(bundle: .shadersBundle)
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
            let (renderPipelineState, reflection) = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor, options: [.argumentInfo])

            var bindings = Bindings()
            resolveBindings(reflection: reflection!, bindable: &bindings, [
                (\.vertexBufferIndex, .vertex, "vertexBuffer.0"),
                (\.vertexCameraIndex, .vertex, "camera"),
                (\.vertexModelTransformsIndex, .vertex, "models"),
                (\.fragmentMaterialsIndex, .fragment, "materials"),
            ])
            renderState = RenderState(mesh: mesh, commandQueue: commandQueue, bindings: bindings, renderPipelineState: renderPipelineState)
        } drawableSizeWillChange: { _, _, size in
            self.size = size
        } draw: { _, _, size, currentDrawable, renderPassDescriptor in
            guard let renderState else {
                fatalError("Draw called before command queue set up. This should be impossible.")
            }
            renderState.commandQueue.withCommandBuffer(drawable: currentDrawable, block: { commandBuffer in
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

                    let material = RenderKitShaders.UnlitMaterial(color: [1, 0, 0, 1], textureIndex: 0)
                    renderCommandEncoder.setFragmentBytes(of: [material], index: renderState.bindings.fragmentMaterialsIndex)
                    renderCommandEncoder.setFragmentTextures([texture], range: 0 ..< 1)

                    // renderCommandEncoder.setTriangleFillMode(.fill)

                    renderCommandEncoder.draw(renderState.mesh, instanceCount: 1)
                }
            })
        }
        .contextMenu {
            Button("Show Info") {
                showDebugView.toggle()
            }
        }
        .aspectRatio(Double(texture.height) / Double(texture.width), contentMode: .fit)
        .overlay(alignment: .topTrailing) {
            if showDebugView {
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
                    LabeledContent("Is Sparse?", value: texture.isSparse ?? false, format: .bool)
                    LabeledContent("Has Parent?", value: texture.parent != nil, format: .bool)
                    LabeledContent("Has Buffer?", value: texture.buffer != nil, format: .bool)
                    LabeledContent("View Size", value: "\(size ?? .zero)")
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
    init(named name: String, bundle: Bundle = .main) {
        let device = MTLCreateSystemDefaultDevice()!
        let loader = MTKTextureLoader(device: device)
        let texture = try! loader.newTexture(name: name, scaleFactor: 1.0, bundle: bundle)
        self.init(texture: texture)
    }
}

extension MTLTextureType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .type1D:
            return "1D"
        case .type1DArray:
            return "1DArray"
        case .type2D:
            return "2D"
        case .type2DArray:
            return "2DArray"
        case .type2DMultisample:
            return "2DMultisample"
        case .typeCube:
            return "Cube"
        case .typeCubeArray:
            return "CubeArray"
        case .type3D:
            return "3D"
        case .type2DMultisampleArray:
            return "2DMultisample"
        case .typeTextureBuffer:
            return "TextureBuffer"
        @unknown default:
            fatalError()
        }
    }
}

extension MTLTextureUsage: CustomStringConvertible {
    public var description: String {
        var atoms: [String] = []
        if self == .unknown {
            return "unknown"
        }
        else if contains(.shaderRead) {
            atoms.append("shaderRead")
        }
        else if contains(.shaderWrite) {
            atoms.append("shaderWrite")
        }
        else if contains(.renderTarget) {
            atoms.append("renderTarget")
        }
        else if contains(.pixelFormatView) {
            atoms.append("pixelFormatView")
        }
        return atoms.joined(separator: ", ")
    }
}

extension MTLTextureCompressionType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .lossless:
            return "lossless"
        case .lossy:
            return "lossy"
        @unknown default:
            fatalError()
        }
    }
}
