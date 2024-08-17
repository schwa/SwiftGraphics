import BaseSupport
import Foundation
import Metal
import simd
import SIMDSupport

// swiftlint:disable force_unwrapping

public func max(lhs: PackedFloat3, rhs: PackedFloat3) -> PackedFloat3 {
    [max(lhs[0], rhs[0]), max(lhs[1], rhs[1]), max(lhs[2], rhs[2])]
}

public func min(lhs: PackedFloat3, rhs: PackedFloat3) -> PackedFloat3 {
    [min(lhs[0], rhs[0]), min(lhs[1], rhs[1]), min(lhs[2], rhs[2])]
}

public extension Collection where Element == PackedFloat3 {
    var bounds: (min: PackedFloat3, max: PackedFloat3) {
        (
            // swiftlint:disable:next reduce_into
            reduce([Float.greatestFiniteMagnitude, Float.greatestFiniteMagnitude, Float.greatestFiniteMagnitude], GaussianSplatSupport.min),
            // swiftlint:disable:next reduce_into
            reduce([-Float.greatestFiniteMagnitude, -Float.greatestFiniteMagnitude, -Float.greatestFiniteMagnitude], GaussianSplatSupport.max)
        )
    }
}

public extension Bundle {
    // GaussianSplatTests.xctest/Contents/Resources/SwiftGraphics_GaussianSplatSupport.bundle
    static let gaussianSplatShaders: Bundle = {
        Bundle.module.peerBundle(named: "SwiftGraphics_GaussianSplatShaders", withExtension: "bundle").forceUnwrap("Could not find bundle.")
    }()
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

extension TupleBuffered: Equatable where Element: Equatable {
}

extension TupleBuffered: Hashable where Element: Hashable {
}
