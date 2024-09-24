import BaseSupport
import Foundation
import Metal
import os
import RenderKitSceneGraph
import simd
import SIMDSupport

// swiftlint:disable force_unwrapping

internal func max(lhs: PackedFloat3, rhs: PackedFloat3) -> PackedFloat3 {
    [max(lhs[0], rhs[0]), max(lhs[1], rhs[1]), max(lhs[2], rhs[2])]
}

internal func min(lhs: PackedFloat3, rhs: PackedFloat3) -> PackedFloat3 {
    [min(lhs[0], rhs[0]), min(lhs[1], rhs[1]), min(lhs[2], rhs[2])]
}

internal extension Collection where Element == PackedFloat3 {
    var bounds: (min: PackedFloat3, max: PackedFloat3) {
        (
            // swiftlint:disable:next reduce_into
            reduce([Float.greatestFiniteMagnitude, Float.greatestFiniteMagnitude, Float.greatestFiniteMagnitude], GaussianSplatSupport.min),
            // swiftlint:disable:next reduce_into
            reduce([-Float.greatestFiniteMagnitude, -Float.greatestFiniteMagnitude, -Float.greatestFiniteMagnitude], GaussianSplatSupport.max)
        )
    }
}

// MARK: -

internal extension Node {
    func splats <Splat>(_ type: Splat.Type) -> SplatCloud<Splat>? where Splat: SplatProtocol {
        content as? SplatCloud<Splat>
    }
}

internal extension MTLRenderPassColorAttachmentDescriptor {
    var size: SIMD2<Float> {
        get throws {
            guard let texture else {
                throw BaseError.error(.invalidParameter)
            }
            return SIMD2<Float>(Float(texture.width), Float(texture.height))
        }
    }
}

internal func releaseAssert(_ condition: @autoclosure () -> Bool, _ message: @autoclosure () -> String = String(), file: StaticString = #file, line: UInt = #line) {
    if !condition() {
        fatalError(message(), file: file, line: line)
    }
}

@dynamicMemberLookup
public struct TupleBuffered<Element> {
    var keys: [String: Int]
    var elements: [Element]

    public init(keys: [String], elements: [Element]) {
        self.keys = Dictionary(uniqueKeysWithValues: zip(keys, keys.indices))
        self.elements = elements
    }

    public mutating func rotate() {
        let first = elements.removeFirst()
        elements.append(first)
    }

    public subscript(dynamicMember key: String) -> Element {
        get {
            guard let index = keys[key] else {
                fatalError("No index for key \(key)")
            }
            return elements[index]
        }
        set {
            guard let index = keys[key] else {
                fatalError("No index for key \(key)")
            }
            elements[index] = newValue
        }
    }
}

extension TupleBuffered: Sendable where Element: Sendable {
}
