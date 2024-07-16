@preconcurrency import Metal

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

public protocol PassProtocol: Equatable, Sendable {
    var id: PassID { get }
}

// TODO: Make sendable.
// TODO: Allow for empty state - make Never or () conform to PassState???
public protocol PassState: Sendable {
}

public struct PassInfo: Sendable {
    public var drawableSize: SIMD2<Float>
    public var frame: Int
    public var start: TimeInterval
    public var time: TimeInterval
    public var deltaTime: TimeInterval
    public var configuration: any MetalConfigurationProtocol
    public var currentRenderPassDescriptor: MTLRenderPassDescriptor?
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
    var renderPassDescriptor: MTLRenderPassDescriptor? { get }
    func children() throws -> [any PassProtocol]
}

public struct GroupPass: GroupPassProtocol {
    public var id: PassID
    internal var _children: PassCollection
    public var renderPassDescriptor: MTLRenderPassDescriptor?

//    public init(id: PassID, renderPassDescriptor: MTLRenderPassDescriptor? = nil, children: [any PassProtocol]) {
//        self.id = id
//        self.renderPassDescriptor = renderPassDescriptor
//        self._children = PassCollection(children)
//    }

    public func children() throws -> [any PassProtocol] {
        _children.elements
    }
}

//public struct EmptyPass: GeneralPassProtocol {
//    public struct State {
//    }
//
//    public let id = PassID(rawValue: "\(UUID())")
//}

public extension GroupPass {
    init(id: PassID, renderPassDescriptor: MTLRenderPassDescriptor? = nil, @RenderPassBuilder content: () -> [any PassProtocol]) {
        self.id = id
        self.renderPassDescriptor = renderPassDescriptor
        self._children = PassCollection(content())
    }
}

@MainActor
@resultBuilder
public enum RenderPassBuilder {

    public static func buildBlock(_ passes: [any PassProtocol]...) -> [any PassProtocol] {
        Array(passes.joined())
    }

    public static func buildExpression(_ pass: any PassProtocol) -> [any PassProtocol] {
        [pass]
    }

    public static func buildExpression(_ passes: [any PassProtocol]) -> [any PassProtocol] {
        passes
    }


    public static func buildOptional(_ passes: [any PassProtocol]?) -> [any PassProtocol] {
        passes ?? []
    }

    public static func buildEither(first passes: [any PassProtocol]) -> [any PassProtocol] {
        passes
    }

    public static func buildEither(second passes: [any PassProtocol]) -> [any PassProtocol] {
        passes
    }
}
