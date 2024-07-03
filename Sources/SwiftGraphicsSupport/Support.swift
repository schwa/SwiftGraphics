import CoreGraphicsSupport
import Foundation
import Metal
import MetalKit
import MetalPerformanceShaders
import ModelIO
import os
import simd
import SIMDSupport
import SwiftFormats
import SwiftUI

public enum RenderKitError: Error {
    case generic(String)
}

public protocol Labeled {
    var label: String? { get }
}

// TODO: Rename to be something less generic.
public struct Box <Content>: Hashable where Content: AnyObject {
    public var content: Content

    public init(_ content: Content) {
        self.content = content
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.content === rhs.content
    }

    public func hash(into hasher: inout Hasher) {
        ObjectIdentifier(content).hash(into: &hasher)
    }
}

public protocol UnsafeMemoryEquatable: Equatable {
}

// swiftlint:disable:next extension_access_modifier
extension UnsafeMemoryEquatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        withUnsafeBytes(of: lhs) { lhs in
            withUnsafeBytes(of: rhs) { rhs in
                guard lhs.count == rhs.count else {
                    return false
                }
                let count = lhs.count
                guard let lhs = lhs.baseAddress, let rhs = rhs.baseAddress else {
                    return true
                }
                return memcmp(lhs, rhs, count) == 0
            }
        }
    }
}

public func max(lhs: SIMD3<Float>, rhs: SIMD3<Float>) -> SIMD3<Float> {
    [max(lhs[0], rhs[0]), max(lhs[1], rhs[1]), max(lhs[2], rhs[2])]
}

public func min(lhs: SIMD3<Float>, rhs: SIMD3<Float>) -> SIMD3<Float> {
    [min(lhs[0], rhs[0]), min(lhs[1], rhs[1]), min(lhs[2], rhs[2])]
}

public func nextPowerOfTwo(_ value: Double) -> Double {
    let logValue = log2(Double(value))
    return pow(2.0, ceil(logValue))
}

public func nextPowerOfTwo(_ value: Int) -> Int {
    Int(nextPowerOfTwo(Double(value)))
}

public extension MTLSize {
    init(width: Int) {
        self = MTLSize(width: width, height: 1, depth: 1)
    }
}

public extension MTLComputeCommandEncoder {
    func setBytes(_ bytes: UnsafeRawBufferPointer, index: Int) {
        setBytes(bytes.baseAddress!, length: bytes.count, index: index)
    }

    func setBytes(of value: some Any, index: Int) {
        withUnsafeBytes(of: value) { buffer in
            setBytes(buffer, index: index)
        }
    }

    func setBytes(of value: [some Any], index: Int) {
        value.withUnsafeBytes { buffer in
            setBytes(buffer, index: index)
        }
    }
}
