import BaseSupport
@preconcurrency import Metal
import MetalSupport
import RenderKit
import Shapes3D
import SwiftUI
import SwiftGraphicsDemosShaders
import GaussianSplatSupport // for TypedMTLBuffer

struct LineGeometryShaderView: DemoView {

    @State
    var size: CGSize = .zero

    @Environment(\.displayScale)
    var displayScale

    @Environment(\.metalDevice)
    var device


    @State
    var buffer: TypedMTLBuffer<LineGeometryShadersInstance>

    @State
    var count = 0

    init() {
        let device = MTLCreateSystemDefaultDevice()!
        buffer = try! device.makeTypedBuffer(count: 5000)
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            RenderView(depthStencilPixelFormat: .invalid, passes: [
                LineShaderRenderPass(id: "-", instances: buffer, count: count)
            ])
            .onGeometryChange(for: CGSize.self, of: \.size, action: { size = $0; print($0) })
            .onChange(of: timeline.date, initial: true) {
                buffer.withUnsafeMutableBufferPointer { buffer in
                    for (index, instance) in buffer.enumerated() {
                        buffer[index] = LineGeometryShadersInstance(start: [Float.random(in: 0...Float(size.width * displayScale * 2)), Float.random(in: 0...Float(size.height * displayScale * 2))], end: [Float.random(in: 0...Float(size.width * displayScale * 2)), Float.random(in: 0...Float(size.height * displayScale * 2))], width: 5, color: [Float.random(in: 0...1), Float.random(in: 0...1), Float.random(in: 0...1), 1])
                    }
                }
                count = buffer.count
            }
        }
    }
}

public struct LineShaderRenderPass: RenderPassProtocol {
    public struct State: Sendable {
        var renderPipelineState: MTLRenderPipelineState

        @MetalBindings
        struct Bindings {
            @MetalBinding(function: .vertex)
            var drawableSize: Int = -1

            @MetalBinding(function: .vertex)
            var instances: Int = -1
        }
        var bindings: Bindings

        var mesh: YAMesh
    }

    struct Vertex: Equatable {
        var position: SIMD2<Float>
    }

    public var id: PassID
    var instances: TypedMTLBuffer<LineGeometryShadersInstance>
    var count: Int

    public func setup(device: MTLDevice, renderPipelineDescriptor: () -> MTLRenderPipelineDescriptor) throws -> State {
        let library = try device.makeDebugLibrary(bundle: .swiftGraphicsDemosShaders)
        let renderPipelineDescriptor = renderPipelineDescriptor()
        renderPipelineDescriptor.vertexFunction = library.makeFunction(name: "LineGeometryShaders::vertexShader")
        renderPipelineDescriptor.fragmentFunction = library.makeFunction(name: "LineGeometryShaders::fragmentShader")
        renderPipelineDescriptor.label = "\(type(of: self))"

        var vertexDescriptor = VertexDescriptor(layouts: [
            .init(attributes: [
                .init(semantic: .position, format: .float2, offset: 0)
            ])
        ])
        vertexDescriptor.setPackedOffsets()
        vertexDescriptor.setPackedStrides()
        renderPipelineDescriptor.vertexDescriptor = MTLVertexDescriptor(vertexDescriptor)
        let (renderPipelineState, reflection) = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor, options: [.bindingInfo])
        var bindings = State.Bindings()
        try bindings.updateBindings(with: reflection)

        var trivialMesh = TrivialMesh<Vertex>()
        trivialMesh.append(vertex: .init(position: [0, 0]))
        trivialMesh.append(vertex: .init(position: [1, 1]))
        trivialMesh.append(vertex: .init(position: [1, 0]))

        trivialMesh.append(vertex: .init(position: [0, 0]))
        trivialMesh.append(vertex: .init(position: [1, 1]))
        trivialMesh.append(vertex: .init(position: [0, 1]))

        let mesh = try YAMesh(device: device, vertexDescriptor: vertexDescriptor, mesh: trivialMesh)
        return State(renderPipelineState: renderPipelineState, bindings: bindings, mesh: mesh)
    }

    public func render(commandBuffer: MTLCommandBuffer, renderPassDescriptor: MTLRenderPassDescriptor, info: PassInfo, state: State) throws {
        try commandBuffer.withRenderCommandEncoder(descriptor: renderPassDescriptor, label: "\(type(of: self))") { commandEncoder in
            commandEncoder.withDebugGroup("Start encoding for \(type(of: self))") {
                commandEncoder.setRenderPipelineState(state.renderPipelineState)
                commandEncoder.withDebugGroup("VertexShader") {
                    commandEncoder.setVertexBytes(of: info.drawableSize, index: state.bindings.drawableSize)
                    instances.withUnsafeMTLBuffer { instances in
                        commandEncoder.setVertexBuffer(instances, offset: 0, index: state.bindings.instances)
                    }
                }
                commandEncoder.withDebugGroup("FragmentShader") {
                }
                commandEncoder.setVertexBuffers(state.mesh)
                commandEncoder.draw(state.mesh, instanceCount: instances.count)
            }
        }
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

extension LineGeometryShadersInstance: @retroactive Equatable, UnsafeMemoryEquatable {
}
