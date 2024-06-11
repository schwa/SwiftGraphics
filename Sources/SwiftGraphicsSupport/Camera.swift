import Foundation
import simd
import SIMDSupport
import SwiftUI

public struct Camera: Equatable, Sendable {
    public var projection: Projection

    public init(projection: Projection = .perspective(.init())) {
        self.projection = projection
    }

    public func projectionMatrix(for viewSize: SIMD2<Float>) -> simd_float4x4 {
        projection.projectionMatrix(for: viewSize)
    }
}
