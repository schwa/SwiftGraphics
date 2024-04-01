import simd
import SIMDSupport
import SwiftUI

public struct Projection3D {
    public var size: CGSize
    public var projectionTransform = simd_float4x4(diagonal: .init(repeating: 1))
    public var viewTransform = simd_float4x4(diagonal: .init(repeating: 1))
    public var clipTransform = simd_float4x4(diagonal: .init(repeating: 1))

    public init(size: CGSize, projectionTransform: simd_float4x4 = simd_float4x4(diagonal: [1, 1, 1, 1]), viewTransform: simd_float4x4 = simd_float4x4(diagonal: [1, 1, 1, 1]), clipTransform: simd_float4x4 = simd_float4x4(diagonal: [1, 1, 1, 1])) {
        self.size = size
        self.projectionTransform = projectionTransform
        self.viewTransform = viewTransform
        self.clipTransform = clipTransform
    }

    public func project(_ point: SIMD3<Float>) -> CGPoint {
        var point = clipTransform * projectionTransform * viewTransform * SIMD4<Float>(point, 1.0)
        point /= point.w
        return CGPoint(x: Double(point.x), y: Double(point.y))
    }

    public func unproject(_ point: CGPoint, z: Float) -> SIMD3<Float> {
        // We have no model. Just use view.
        let modelView = viewTransform
        return gluUnproject(win: SIMD3<Float>(Float(), Float(), z), modelView: modelView, proj: projectionTransform, viewOrigin: .zero, viewSize: SIMD2<Float>(size))
    }
}

// MARK: -

public extension GraphicsContext {
    func draw3DLayer(projection: Projection3D, content: (inout GraphicsContext, inout GraphicsContext3D) -> Void) {
        drawLayer { context in
            context.translateBy(x: projection.size.width / 2, y: projection.size.height / 2)
            var graphicsContext = GraphicsContext3D(graphicsContext2D: context, projection: projection)
            content(&context, &graphicsContext)
        }
    }
}

// https://registry.khronos.org/OpenGL-Refpages/gl2.1/xhtml/gluUnProject.xml
func gluUnproject(win: SIMD3<Float>, modelView: simd_float4x4, proj: simd_float4x4, viewOrigin: SIMD2<Float>, viewSize: SIMD2<Float>) -> SIMD3<Float> {
    let invPMV = (proj * modelView).inverse
    let v = SIMD4<Float>(
        (2 * (win.x * viewOrigin.x) / viewSize.x) - 1,
        (2 * (win.y * viewOrigin.y) / viewSize.y) - 1,
        (2 * (win.z)) - 1,
        1
    )
    let result = (invPMV * v).xyz
    print(result)
    return result
}

// https://registry.khronos.org/OpenGL-Refpages/gl2.1/xhtml/gluProject.xml
func gluProject(obj: SIMD3<Float>, modelView: simd_float4x4, proj: simd_float4x4, viewOrigin: SIMD2<Float>, viewSize: SIMD2<Float>) -> SIMD3<Float> {
    let obj = SIMD4<Float>(obj, 1)
    let v = proj * modelView * obj
    let winX = viewOrigin.x + (viewSize.x * v.x + 1) / 2
    let winY = viewOrigin.y + (viewSize.y * v.y + 1) / 2
    let winZ = (v.z + 1) / 2

    return [winX, winY, winZ]
}
