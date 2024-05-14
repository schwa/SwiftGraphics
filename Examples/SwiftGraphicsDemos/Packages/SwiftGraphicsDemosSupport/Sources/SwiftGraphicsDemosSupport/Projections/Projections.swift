import simd
import SIMDSupport
import SwiftUI

protocol ProjectionProtocol: Equatable, Sendable {
    func matrix(viewSize: SIMD2<Float>) -> simd_float4x4
}

struct PerspectiveProjection: ProjectionProtocol {
    var fovy: Angle
    var zClip: ClosedRange<Float>

    init(fovy: Angle, zClip: ClosedRange<Float>) {
        self.fovy = fovy
        self.zClip = zClip
    }

    func matrix(viewSize: SIMD2<Float>) -> simd_float4x4 {
        let aspect = viewSize.x / viewSize.y
        return .perspective(aspect: aspect, fovy: Float(fovy.radians), near: zClip.lowerBound, far: zClip.upperBound)
    }
}

struct OrthographicProjection: ProjectionProtocol {
    var left: Float
    var right: Float
    var bottom: Float
    var top: Float
    var near: Float
    var far: Float

    init(left: Float, right: Float, bottom: Float, top: Float, near: Float, far: Float) {
        self.left = left
        self.right = right
        self.bottom = bottom
        self.top = top
        self.near = near
        self.far = far
    }

    func matrix(viewSize: SIMD2<Float>) -> simd_float4x4 {
        .orthographic(left: left, right: right, bottom: bottom, top: top, near: near, far: far)
    }
}

enum Projection: ProjectionProtocol {
    case matrix(simd_float4x4)
    case perspective(PerspectiveProjection)
    case orthographic(OrthographicProjection)

    func matrix(viewSize: SIMD2<Float>) -> simd_float4x4 {
        switch self {
        case .matrix(let projection):
            projection
        case .perspective(let projection):
            projection.matrix(viewSize: viewSize)
        case .orthographic(let projection):
            projection.matrix(viewSize: viewSize)
        }
    }

    // TODO: Use that macro
    enum Meta: CaseIterable {
        case matrix
        case perspective
        case orthographic
    }

    var meta: Meta {
        switch self {
        case .matrix:
            .matrix
        case .perspective:
            .perspective
        case .orthographic:
            .orthographic
        }
    }
}

extension Projection: Sendable {
}
