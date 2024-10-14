import BaseSupport
import Foundation
import Metal
import os
import RenderKitSceneGraph
import simd
import SIMDSupport

// swiftlint:disable force_unwrapping

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

extension OSAllocatedUnfairLock where State == Int {
    func postIncrement() -> State {
        withLock { state in
            defer {
                state += 1
            }
            return state
        }
    }
}
