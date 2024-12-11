// periphery:ignore:all

import os

@preconcurrency import Metal

public protocol PassProtocol: Equatable, Sendable {
    typealias PassID = AnyHashableSendable
    var id: AnyHashableSendable { get }
}

public struct PassInfo: Sendable {
    public var drawableSize: SIMD2<Float>
    public var frame: Int
    public var start: TimeInterval
    public var time: TimeInterval
    public var deltaTime: TimeInterval
    public var configuration: any MetalConfigurationProtocol
    public var currentRenderPassDescriptor: MTLRenderPassDescriptor?
    public var gpuCounters: GPUCounters?
    public var logger: Logger?
}

// MARK: -

public protocol ShaderPassProtocol: PassProtocol {
    associatedtype State: Sendable
}

// MARK: -

public protocol ComputePassProtocol: ShaderPassProtocol {
    func setup(device: MTLDevice) throws -> State
    func compute(commandBuffer: MTLCommandBuffer, info: PassInfo, state: State) throws
}

// MARK: -

public protocol RenderPassProtocol: ShaderPassProtocol {
    func setup(device: MTLDevice, configuration: some MetalConfigurationProtocol) throws -> State
    func drawableSizeWillChange(device: MTLDevice, size: SIMD2<Float>, state: inout State) throws
    func render(commandBuffer: MTLCommandBuffer, renderPassDescriptor: MTLRenderPassDescriptor, info: PassInfo, state: State) throws
}

// MARK: -

public protocol GeneralPassProtocol: PassProtocol {
    associatedtype State: Sendable
    func setup(device: MTLDevice) throws -> State
    func encode(commandBuffer: MTLCommandBuffer, info: PassInfo, state: State) throws
}

// MARK: -

public struct GroupPass: PassProtocol {
    public var id: AnyHashableSendable
    internal var _children: PassCollection
    public var renderPassDescriptor: MTLRenderPassDescriptor?

    public init(id: PassID, renderPassDescriptor: MTLRenderPassDescriptor? = nil, @RenderPassBuilder content: () throws -> [any PassProtocol]) rethrows {
        self.id = id
        self.renderPassDescriptor = renderPassDescriptor
        self._children = try PassCollection(content())
    }

    public func children() throws -> [any PassProtocol] {
        _children.elements
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

// MARK:

public struct AnyHashableSendable: Hashable, Sendable {
    let base: any Hashable & Sendable
    let eq: @Sendable (any Hashable & Sendable) -> Bool

    public init<T>(_ base: T) where T: Hashable & Sendable {
        self.base = base
        self.eq = { other in
            guard let other = other as? T else {
                return false
            }
            return base == other
        }
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.eq(rhs.base)
    }

    public func hash(into hasher: inout Hasher) {
        base.hash(into: &hasher)
    }
}

extension AnyHashableSendable: CustomDebugStringConvertible {
    public var debugDescription: String {
        RenderKit.debugDescription(base)
    }
}

func debugDescription(_ value: some Any) -> String {
    if let value = value as? CustomDebugStringConvertible {
        return value.debugDescription
    }
    else if let value = value as? CustomStringConvertible {
        return value.description
    }
    else {
        return "\(value)"
    }
}

extension AnyHashableSendable: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(value)
    }
}
