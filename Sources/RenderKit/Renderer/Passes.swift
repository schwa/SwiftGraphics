import Metal

public struct PassID: Hashable, Sendable {
    var rawValue: String
}

extension PassID: CustomDebugStringConvertible {
    public var debugDescription: String {
        rawValue
    }
}

extension PassID: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.rawValue = value
    }
}

public protocol PassProtocol: Equatable/*, Sendable*/ {
    var id: PassID { get }
}

// TODO: Make sendable.
// TODO: Allow for empty state - make Never or () conform to PassState???
public protocol PassState /*: Sendable*/ {
}

public struct PassInfo: Sendable {
    public var drawableSize: SIMD2<Float>
    public var frame: Int
    public var start: TimeInterval
    public var time: TimeInterval
    public var deltaTime: TimeInterval
}

// MARK: -

public protocol ShaderPassProtocol: PassProtocol {
    associatedtype State: PassState
}

// MARK: -

public protocol ComputePassProtocol: ShaderPassProtocol {
    func setup(device: MTLDevice) throws -> State
    func compute(commandBuffer: MTLCommandBuffer, info: PassInfo, state: State) throws
}

// MARK: -

public protocol RenderPassProtocol: ShaderPassProtocol {
    func setup(device: MTLDevice, renderPipelineDescriptor: () -> MTLRenderPipelineDescriptor) throws -> State
    func sizeWillChange(device: MTLDevice, size: SIMD2<Float>, state: inout State) throws
    func render(commandBuffer: MTLCommandBuffer, renderPassDescriptor: MTLRenderPassDescriptor, info: PassInfo, state: State) throws
    func encode(commandEncoder: MTLRenderCommandEncoder, info: PassInfo, state: State) throws
}

// MARK: -

public protocol GeneralPassProtocol: PassProtocol {
    associatedtype State: PassState
    func setup(device: MTLDevice) throws -> State
    func encode(commandBuffer: MTLCommandBuffer, info: PassInfo, state: State) throws // TODO: Rename
}

// MARK: -

public protocol GroupPassProtocol: PassProtocol {
    func children() throws -> [any PassProtocol]
}
