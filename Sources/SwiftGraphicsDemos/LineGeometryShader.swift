import BaseSupport
import CoreGraphicsSupport
import GaussianSplatSupport // for TypedMTLBuffer
@preconcurrency import Metal
import MetalSupport
import RenderKit
import Shapes3D
import SwiftGraphicsDemosShaders
import SwiftUI

struct LineGeometryShaderView: DemoView {
    @State
    var size: CGSize = .zero

    @Environment(\.displayScale)
    var displayScale

    @Environment(\.metalDevice)
    var device

    @State
    var buffer: TypedMTLBuffer<LineGeometrySegment>

    @State
    var count = 0

    @State
    private var points: [CGPoint] = [[50, 50], [250, 50], [300, 100]]

    init() {
        let device = MTLCreateSystemDefaultDevice()!
        buffer = try! device.makeTypedBuffer(count: 2).labelled("LineGeometrySegment")
    }

    var body: some View {
        ZStack {
            RenderView(depthStencilPixelFormat: .invalid, passes: [
                LineShaderRenderPass(id: "-", lineSegments: buffer, count: count, displayScale: Float(displayScale))
            ]) { configuration in
                configuration.clearColor = .init(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
            }
            LegacyPathEditor(points: $points)
        }
        .gesture(SpatialTapGesture().onEnded { value in
            points.append(value.location)
        })
        .onGeometryChange(for: CGSize.self, of: \.size) { size = $0 }
        .onChange(of: points, initial: true) {
            let segments = points.windows(ofCount: 2).enumerated().map { index, points in
                let points = Array(points)
                let color = kellyColors[index % kellyColors.count]
                return LineGeometrySegment(start: [Float(points[0].x), Float(points[0].y)], end: [Float(points[1].x), Float(points[1].y)], width: 5, color: [color.0, color.1, color.2, 1])
            }
            buffer = try! device.makeTypedBuffer(data: segments, options: []).labelled("LineGeometrySegment")
            count = buffer.count
        }
        .contextMenu {
            Button("Add 10") {
                for _ in 0..<1000 {
                    points.append(CGPoint.random(in: CGRect(origin: .zero, size: size)))
                }
            }
        }
    }
}

public struct LineShaderRenderPass: RenderPassProtocol {
    public struct State: Sendable {
        var renderPipelineState: MTLRenderPipelineState

        @MetalBindings
        struct Bindings {
            @MetalBinding(name: "segments", function: .object)
            var objectSegments: Int = -1

            @MetalBinding(name: "segmentCount", function: .object)
            var objectSegmentCount: Int = -1

            @MetalBinding(name: "drawableSize", function: .object)
            var objectDrawableSize: Int = -1

            @MetalBinding(name: "displayScale", function: .object)
            var objectDisplayScale: Int = -1

            @MetalBinding(name: "segments", function: .mesh)
            var meshSegments: Int = -1

            @MetalBinding(name: "segmentCount", function: .mesh)
            var meshSegmentCount: Int = -1

            @MetalBinding(name: "drawableSize", function: .mesh)
            var meshDrawableSize: Int = -1

            @MetalBinding(name: "displayScale", function: .mesh)
            var meshDisplayScale: Int = -1
        }
        var bindings: Bindings
    }

    struct Vertex: Equatable {
        var position: SIMD2<Float>
    }

    public var id: PassID
    var lineSegments: TypedMTLBuffer<LineGeometrySegment>
    var count: Int
    var displayScale: Float

    public func setup(device: MTLDevice, configuration: some MetalConfigurationProtocol) throws -> State {
        let library = try device.makeDebugLibrary(bundle: .swiftGraphicsDemosShaders)
        let meshPipelineDescriptor = MTLMeshRenderPipelineDescriptor()
        meshPipelineDescriptor.colorAttachments[0].pixelFormat = configuration.colorPixelFormat
        meshPipelineDescriptor.depthAttachmentPixelFormat = configuration.depthStencilPixelFormat
        meshPipelineDescriptor.objectFunction = library.makeFunction(name: "LineGeometryShaders::objectShader")
        meshPipelineDescriptor.meshFunction = library.makeFunction(name: "LineGeometryShaders::meshShader")
        meshPipelineDescriptor.fragmentFunction = library.makeFunction(name: "LineGeometryShaders::fragmentShader")
        meshPipelineDescriptor.payloadMemoryLength = MemoryLayout<LineGeometrySegment>.stride * 32
        // meshPipelineDescriptor.maxTotalThreadsPerObjectThreadgroup = 6
        meshPipelineDescriptor.label = "\(type(of: self))"
        let (renderPipelineState, reflection) = try device.makeRenderPipelineState(descriptor: meshPipelineDescriptor, options: [.bindingInfo])
        var bindings = State.Bindings()
        try bindings.updateBindings(with: reflection)
        return State(renderPipelineState: renderPipelineState, bindings: bindings)
    }

    public func render(commandBuffer: MTLCommandBuffer, renderPassDescriptor: MTLRenderPassDescriptor, info: PassInfo, state: State) throws {
        try commandBuffer.withRenderCommandEncoder(descriptor: renderPassDescriptor, label: "\(type(of: self))") { commandEncoder in
            commandEncoder.withDebugGroup("Start encoding for \(type(of: self))") {
                commandEncoder.setRenderPipelineState(state.renderPipelineState)
                commandEncoder.withDebugGroup("ObjectShader") {
                    lineSegments.withUnsafeMTLBuffer { lineSegments in
                        commandEncoder.setObjectBuffer(lineSegments, offset: 0, index: state.bindings.objectSegments)
                    }
                    commandEncoder.setObjectBytes(of: UInt32(count), index: state.bindings.objectSegmentCount)
                    commandEncoder.setObjectBytes(of: info.drawableSize, index: state.bindings.objectDrawableSize)
                    commandEncoder.setObjectBytes(of: displayScale, index: state.bindings.objectDisplayScale)
                }
                commandEncoder.withDebugGroup("MeshShader") {
                    lineSegments.withUnsafeMTLBuffer { lineSegments in
                        commandEncoder.setMeshBuffer(lineSegments, offset: 0, index: state.bindings.meshSegments)
                    }
                    commandEncoder.setMeshBytes(of: UInt32(count), index: state.bindings.meshSegmentCount)
                    commandEncoder.setMeshBytes(of: info.drawableSize, index: state.bindings.meshDrawableSize)
                    commandEncoder.setMeshBytes(of: displayScale, index: state.bindings.meshDisplayScale)
                }
            }
            //            commandEncoder.drawMeshThreads(MTLSize(width: count), threadsPerObjectThreadgroup: MTLSize(width: 1), threadsPerMeshThreadgroup: MTLSize(width: count))

            commandEncoder.drawMesh(threadgroupsPerGrid: count, threadsPerObjectThreadgroup: 1, threadsPerMeshThreadgroup: 6)
        }
    }
}

extension MTLRenderCommandEncoder {
    func drawMesh(threadgroupsPerGrid: Int, threadsPerObjectThreadgroup: Int, threadsPerMeshThreadgroup: Int) {
        drawMeshThreadgroups(MTLSize(width: threadgroupsPerGrid), threadsPerObjectThreadgroup: MTLSize(width: threadsPerObjectThreadgroup), threadsPerMeshThreadgroup: MTLSize(width: threadsPerMeshThreadgroup))
    }
    func drawMesh(threadsPerGrid: Int, threadsPerObjectThreadgroup: Int, threadsPerMeshThreadgroup: Int) {
        drawMeshThreads(MTLSize(width: threadsPerGrid), threadsPerObjectThreadgroup: MTLSize(width: threadsPerObjectThreadgroup), threadsPerMeshThreadgroup: MTLSize(width: threadsPerMeshThreadgroup))
    }
}

extension YAMesh {
    init <Vertex>(device: MTLDevice, vertexDescriptor: VertexDescriptor, mesh: TrivialMesh<Vertex>) throws where Vertex: Equatable {
        let indexBuffer = try device.makeBuffer(bytesOf: mesh.indices.map { UInt16($0) }, options: [])
        let indexBufferView = BufferView(buffer: indexBuffer, offset: 0)
        let submesh = Submesh(indexType: .uint16, indexBufferView: indexBufferView, indexCount: mesh.indices.count, primitiveType: .triangle)
        let vertexBuffer = try device.makeBuffer(bytesOf: mesh.vertices, options: [])
        let vertexBufferView = BufferView(buffer: vertexBuffer, offset: 0)
        self = YAMesh(submeshes: [submesh], vertexDescriptor: vertexDescriptor, vertexBufferViews: [vertexBufferView])
    }
}

extension MTLRenderCommandEncoder {
    func draw <Vertex>(_ mesh: TrivialMesh<Vertex>) where Vertex: Equatable {
        setVertexBytes(of: mesh.vertices, index: 0)

        drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: mesh.vertices.count)
    }
}

extension LineGeometrySegment: @retroactive Equatable, UnsafeMemoryEquatable {
}
