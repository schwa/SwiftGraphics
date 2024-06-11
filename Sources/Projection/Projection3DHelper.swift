import simd
import SIMDSupport
import SwiftUI

public struct Projection3DHelper: Sendable {
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

    // TODO: rename (screenspace to worldspace?)
    public func unproject(_ point: CGPoint, z: Float) -> SIMD3<Float> {
        // We have no model. Just use view.
        let modelView = viewTransform
        return gluUnproject(win: SIMD3<Float>(Float(point.x), Float(point.y), z), modelView: modelView, proj: projectionTransform, viewOrigin: .zero, viewSize: SIMD2<Float>(size))
    }

    public func worldSpaceToScreenSpace(_ point: SIMD3<Float>) -> CGPoint {
        var point = worldSpaceToClipSpace(point)
        point /= point.w
        return CGPoint(x: Double(point.x), y: Double(point.y))
    }

    public func worldSpaceToClipSpace(_ point: SIMD3<Float>) -> SIMD4<Float> {
        clipTransform * projectionTransform * viewTransform * SIMD4<Float>(point, 1.0)
    }

    public func isVisible(_ point: SIMD3<Float>) -> Bool {
        worldSpaceToClipSpace(point).z >= 0
    }
}

// MARK: -

public extension GraphicsContext {
    func draw3DLayer(projection: Projection3DHelper, content: (inout GraphicsContext, inout GraphicsContext3D) -> Void) {
        drawLayer { context in
            context.translateBy(x: projection.size.width / 2, y: projection.size.height / 2)
            var graphicsContext = GraphicsContext3D(graphicsContext2D: context, projection: projection)
            content(&context, &graphicsContext)
        }
    }
}

// https://registry.khronos.org/OpenGL-Refpages/gl2.1/xhtml/gluUnProject.xml
public func gluUnproject(win: SIMD3<Float>, modelView: simd_float4x4, proj: simd_float4x4, viewOrigin: SIMD2<Float>, viewSize: SIMD2<Float>) -> SIMD3<Float> {
    let invPMV = (proj * modelView).inverse
    let v = SIMD4<Float>(
        (2 * (win.x * viewOrigin.x) / viewSize.x) - 1,
        (2 * (win.y * viewOrigin.y) / viewSize.y) - 1,
        (2 * (win.z)) - 1,
        1
    )
    let result = (invPMV * v).xyz
    return result
}

// https://registry.khronos.org/OpenGL-Refpages/gl2.1/xhtml/gluProject.xml
public func gluProject(obj: SIMD3<Float>, modelView: simd_float4x4, proj: simd_float4x4, viewOrigin: SIMD2<Float>, viewSize: SIMD2<Float>) -> SIMD3<Float> {
    let obj = SIMD4<Float>(obj, 1)
    let v = proj * modelView * obj
    let winX = viewOrigin.x + (viewSize.x * v.x + 1) / 2
    let winY = viewOrigin.y + (viewSize.y * v.y + 1) / 2
    let winZ = (v.z + 1) / 2

    return [winX, winY, winZ]
}

// MARK:

struct Projection3DPreferenceKey: PreferenceKey {
    static func reduce(value: inout Projection3DHelper?, nextValue: () -> Projection3DHelper?) {
        value = value ?? nextValue()
    }

    static let defaultValue: Projection3DHelper? = nil
}

internal struct Projection3DOverlayViewModifier <OverlayContent>: ViewModifier where OverlayContent: View {
    var alignment: Alignment
    var overlayContent: (Projection3DHelper?) -> OverlayContent

    func body(content: Content) -> some View {
        content.overlayPreferenceValue(Projection3DPreferenceKey.self, alignment: alignment) { value in
            overlayContent(value)
        }
    }
}

public extension View {
    func projection3DOverlay <Content>(alignment: Alignment = .center, @ViewBuilder _ content: @escaping (Projection3DHelper?) -> Content) -> some View where Content: View {
        modifier(Projection3DOverlayViewModifier(alignment: alignment, overlayContent: content))
    }
}
