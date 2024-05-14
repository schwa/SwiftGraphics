// import SwiftUI
// // import CoreGraphicsSupport
// import Geometry
// import RenderKit
// import simd
// import RenderKitShaders
// import ModelIO
//
// struct ScreenSpaceDemoView: View {
//    @Environment(\.displayScale)
//    var displayScale
//
//    @State
//    var renderPass: any RenderPass
//
//    init() {
//        var depthStencilState: MTLDepthStencilState?
//        var renderPipelineState: MTLRenderPipelineState?
//        var circleMesh: YAMesh?
//        var rectangleMesh: YAMesh?
//
//        renderPass = AnyRenderPass<MetalViewConfiguration> { device, configuration in
//            let library = try! device.makeDefaultLibrary(bundle: .shadersBundle)
//            let vertexFunction = library.makeFunction(name: "reallyFlatVertexShader")!
//            let fragmentFunction = library.makeFunction(name: "reallyFlatFragmentShader")
//
//            depthStencilState = device.makeDepthStencilState(descriptor: MTLDepthStencilDescriptor(depthCompareFunction: .lessEqual, isDepthWriteEnabled: true))
//
//            let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
//            renderPipelineDescriptor.vertexFunction = vertexFunction
//            renderPipelineDescriptor.fragmentFunction = fragmentFunction
//            renderPipelineDescriptor.colorAttachments[0].pixelFormat = configuration.colorPixelFormat
//            renderPipelineDescriptor.colorAttachments[0].enableStandardAlphaBlending()
//            renderPipelineDescriptor.depthAttachmentPixelFormat = configuration.depthStencilPixelFormat
//
//            let descriptor = VertexDescriptor.packed(semantics: [.position, .normal, .textureCoordinate])
//            renderPipelineDescriptor.vertexDescriptor = MTLVertexDescriptor(descriptor)
//            renderPipelineState = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
//
//            circleMesh = try YAMesh.simpleMesh(label: "circle", primitiveType: .lineStrip, device: device) {
//                let indices = (0 ..< 36).map { UInt16($0) } + [0]
//                let vertices = (0 ..< 36).map { n in
//                    return (CGPoint(length: 1, angle: Angle(degrees: Double(n) * 360 / 36).radians))
//                }
//                .map {
//                    let position = SIMD3<Float>(Float($0.x), Float($0.y), 0) * 100
//                    let textureCoordinate = SIMD2<Float>($0) / 2 + 0.5
//                    return SimpleVertex(position: position, normal: .zero, textureCoordinate: textureCoordinate)
//                }
//                return (indices, vertices)
//            }
//
//            rectangleMesh = try YAMesh.simpleMesh(label: "rectangle", primitiveType: .lineStrip, device: device) {
//                let indices: [UInt16] = [
//                    0, 1, 2, 3, 0
//                ]
//                let vertices = [SIMD2<Float>]([
//                    [0, 0],
//                    [1, 0],
//                    [1, 1],
//                    [0, 1],
//                ])
//                .map {
//                    let position = SIMD3<Float>($0, 0) * 100
//                    return SimpleVertex(position: position, normal: .zero, textureCoordinate: $0)
//                }
//                return (indices, vertices)
//            }
//        }
//        draw: { _, _, size, renderPassDescriptor, commandBuffer in
//            printOnce(size)
//            guard let renderPipelineState, let depthStencilState else {
//                return
//            }
//            commandBuffer.withRenderCommandEncoder(descriptor: renderPassDescriptor) { encoder in
//                encoder.withDebugGroup("Circle") {
//                    encoder.setRenderPipelineState(renderPipelineState)
//                    encoder.setDepthStencilState(depthStencilState)
//                    let displayScale: Float = 2
//                    let size = SIMD2<Float>(size) / displayScale
//                    let size2 = size / 2
//                    var view = simd_float4x4.identity
//                    view *= simd_float4x4.scaled([1 / size2.x, -1 / size2.y, 1])
//                    view *= simd_float4x4.translation([-size2.x, -size2.y, 0])
//                    let cameraUniforms = CameraUniforms(projectionMatrix: view)
//
//                    encoder.setVertexBytes(of: cameraUniforms, index: 1)
//                    encoder.setTriangleFillMode(.lines)
//
//                    if let circleMesh {
//                        encoder.setVertexBuffers(circleMesh)
//                        encoder.setVertexBytes(of: size2, index: 2)
//                        encoder.draw(circleMesh, instanceCount: 1)
//                    }
//
//                    if let rectangleMesh {
//                        encoder.setVertexBuffers(rectangleMesh)
//                        encoder.setVertexBytes(of: SIMD2<Float>(20, 20), index: 2)
//                        encoder.draw(rectangleMesh, instanceCount: 1)
//                    }
//                }
//            }
//        }
//    }
//
//    var body: some View {
//        ZStack {
//            RendererView(renderPass: $renderPass)
//            Canvas { context, size in
//                let rect = CGRect(size: size)
//                let color = Color.blue
//                context.stroke(Path(rect), with: .color(color), style: .init(lineWidth: 1))
//                context.stroke(Path(lines: [(rect.midXMinY, rect.midXMaxY), (rect.minXMidY, rect.maxXMidY)]), with: .color(color), style: .init(lineWidth: 1))
//                context.stroke(Path(ellipseIn: CGRect(center: rect.midXMidY, radius: 100)), with: .color(color), style: .init(lineWidth: 1))
//                context.stroke(Path(CGRect(origin: [20, 20], size: [100, 100])), with: .color(color), style: .init(lineWidth: 1))
//            }
//            .opacity(0.5)
//        }
//        .overlay {
//            infoOverlays()
//        }
//    }
//
//    func infoOverlays() -> some View {
//        GeometryReader { proxy in
//            Color.clear
//            .overlay(alignment: .center) {
//                Form {
//                    Text("100 px radius")
//                }
//                .padding()
//                .background(.regularMaterial)
//                .clipShape(RoundedRectangle(cornerRadius: 8))
//                .padding()
//            }
//            .overlay(alignment: .top) {
//                Form {
//                    LabeledContent("Display Scale", value: "\(displayScale)")
//                }
//                .padding()
//                .background(.regularMaterial)
//                .clipShape(RoundedRectangle(cornerRadius: 8))
//                .padding()
//            }
//            .overlay(alignment: .bottom) {
//                Form {
//                    LabeledContent("Size", value: "\(proxy.size)")
//                }
//                .padding()
//                .background(.regularMaterial)
//                .clipShape(RoundedRectangle(cornerRadius: 8))
//                .padding()
//            }
//        }
//        .showOnHover()
//    }
//
//    class _RenderPass: RenderPass {
//        func setup<Configuration>(device: MTLDevice, configuration: inout Configuration) throws where Configuration : RenderKit.MetalConfiguration {
//        }
//
//        func draw(device: MTLDevice, size: CGSize, renderPassDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer) throws {
//        }
//    }
// }
