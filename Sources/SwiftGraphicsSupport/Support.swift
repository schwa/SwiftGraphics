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

public extension Rotation {
    func apply(_ p: SIMD3<Float>) -> SIMD3<Float> {
        (matrix * SIMD4<Float>(p, 1)).xyz
    }
}

public enum Axis3 {
    case x
    case y
    case z
}

public extension Axis3 {
    var positiveVector: SIMD3<Float> {
        switch self {
        case .x:
            [1, 0, 0]
        case .y:
            [0, 1, 0]
        case .z:
            [0, 0, 1]
        }
    }
}

public extension SIMD3<Float> {
    func angle(along axis: Axis3) -> Angle {
        let axisVector = axis.positiveVector

        // Project the vector onto the plane perpendicular to the axis
        let projectedVector: SIMD3<Float>
        switch axis {
        case .x:
            projectedVector = [0, self.y, self.z]
        case .y:
            projectedVector = [self.x, 0, self.z]
        case .z:
            projectedVector = [self.x, self.y, 0]
        }

        // Calculate the angle using atan2
        let angle: Float
        switch axis {
        case .x:
            angle = atan2(projectedVector.z, projectedVector.y)
        case .y:
            angle = atan2(projectedVector.x, projectedVector.z)
        case .z:
            angle = atan2(projectedVector.y, projectedVector.x)
        }

        // Convert to the desired Angle type
        return .radians(Double(angle))
    }
}
