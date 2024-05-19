import simd
import SwiftUI

public protocol ProjectionProtocol: Equatable, Sendable {
    func matrix(viewSize: SIMD2<Float>) -> simd_float4x4
}

public struct PerspectiveProjection: ProjectionProtocol {
    public var fovy: Angle
    public var zClip: ClosedRange<Float>

    public init(fovy: Angle, zClip: ClosedRange<Float>) {
        self.fovy = fovy
        self.zClip = zClip
    }

    public func matrix(viewSize: SIMD2<Float>) -> simd_float4x4 {
        let aspect = viewSize.x / viewSize.y
        return .perspective(aspect: aspect, fovy: Float(fovy.radians), near: zClip.lowerBound, far: zClip.upperBound)
    }
}

public struct OrthographicProjection: ProjectionProtocol {
    public var left: Float
    public var right: Float
    public var bottom: Float
    public var top: Float
    public var near: Float
    public var far: Float

    public init(left: Float, right: Float, bottom: Float, top: Float, near: Float, far: Float) {
        self.left = left
        self.right = right
        self.bottom = bottom
        self.top = top
        self.near = near
        self.far = far
    }

    public func matrix(viewSize: SIMD2<Float>) -> simd_float4x4 {
        .orthographic(left: left, right: right, bottom: bottom, top: top, near: near, far: far)
    }
}

public enum Projection: ProjectionProtocol {
    case matrix(simd_float4x4)
    case perspective(PerspectiveProjection)
    case orthographic(OrthographicProjection)

    public func matrix(viewSize: SIMD2<Float>) -> simd_float4x4 {
        switch self {
        case .matrix(let projection):
            projection
        case .perspective(let projection):
            projection.matrix(viewSize: viewSize)
        case .orthographic(let projection):
            projection.matrix(viewSize: viewSize)
        }
    }

    public enum Meta: CaseIterable {
        case matrix
        case perspective
        case orthographic
    }

    public var meta: Meta {
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

// TODO: Too much duplication here. Deprecate what isn't used.

public extension simd_float4x4 {
    // swiftlint:disable:next function_parameter_count
    static func orthographic(left: Float, right: Float, bottom: Float, top: Float, near: Float, far: Float) -> simd_float4x4 {
        simd_float4x4(rows: (
            [2 / (right - left), 0, 0, -((right + left) / (right - left))],
            [0, 2 / (top - bottom), 0, -((top + bottom) / (top - bottom))],
            [0, 0, -2 / (far - near), -((far + near) / (far - near))],
            [0, 0, 0, 1]
        ))
    }

    static func perspective(aspect: Float, fovy: Float, near: Float, far: Float) -> Self {
        let yScale = 1 / tan(fovy * 0.5)
        let xScale = yScale / aspect
        let zRange = far - near
        let zScale = -(far + near) / zRange
        let wzScale = -2 * far * near / zRange

        let P: SIMD4<Float> = [xScale, 0, 0, 0]
        let Q: SIMD4<Float> = [0, yScale, 0, 0]
        let R: SIMD4<Float> = [0, 0, zScale, -1]
        let S: SIMD4<Float> = [0, 0, wzScale, 0]

        return simd_float4x4([P, Q, R, S])
    }

    static func viewport(x: Float, y: Float, w: Float, h: Float, depth: Float) -> simd_float4x4 {
        var m = simd_float4x4.identity
        m[0][3] = x + w / 2
        m[1][3] = y + h / 2
        m[2][3] = depth / 2

        m[0][0] = w / 2
        m[1][1] = h / 2
        m[2][2] = depth / 2
        return m
    }
}

// https://www.khronos.org/opengl/wiki/GluLookAt_code
public func look(at target: SIMD3<Float>, from eye: SIMD3<Float>, up: SIMD3<Float>) -> simd_float4x4 {
    let forward: SIMD3<Float> = (target - eye).normalized

    // Side = forward x up
    let side = simd_cross(forward, up).normalized

    // Recompute up as: up = side x forward
    let up_ = simd_cross(side, forward).normalized

    var matrix2: simd_float4x4 = .identity

    matrix2[0] = SIMD4<Float>(side, 0)
    matrix2[1] = SIMD4<Float>(up_, 0)
    matrix2[2] = SIMD4<Float>(-forward, 0)
    matrix2[3] = [0, 0, 0, 1]

    let result = .init(translate: eye) * matrix2
    return result
}

// https://docs.microsoft.com/en-us/windows/win32/direct3d9/d3dxmatrixlookatlh
public func dx_look(at target: SIMD3<Float>, from eye: SIMD3<Float>, up: SIMD3<Float>) -> simd_float4x4 {
    let zaxis = simd_normalize(target - eye)
    let xaxis = simd_normalize(simd_cross(up, zaxis))
    let yaxis = simd_cross(zaxis, xaxis)

    return simd_float4x4([
        SIMD4<Float>(xaxis, -simd_dot(xaxis, eye)),
        SIMD4<Float>(yaxis, -simd_dot(yaxis, eye)),
        SIMD4<Float>(zaxis, -simd_dot(zaxis, eye)),
        SIMD4<Float>(0, 0, 0, 1),
    ])
}
