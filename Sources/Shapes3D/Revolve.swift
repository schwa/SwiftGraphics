import CoreGraphicsUnsafeConformances
import Foundation
import simd
import SIMDSupport
import SwiftUI

// TODO: Experimental

public func revolve(polygonalChain: PolygonalChain3D, axis: Line3D, range: ClosedRange<Angle>) -> TrivialMesh<SIMD3<Float>> {
    let quads = polygonalChain.segments.map {
        revolve(lineSegment: $0, axis: axis, range: range)
    }
    return TrivialMesh(quads: quads)
}

public func revolve(polygonalChain: PolygonalChain3D, axis: Line3D, range: ClosedRange<Angle>, segments: Int) -> TrivialMesh<SIMD3<Float>> {
    let by = Angle(radians: (range.upperBound.radians - range.lowerBound.radians) / Double(segments))
    let quads = stride(from: range.lowerBound, to: range.upperBound, by: by).flatMap { start in
        let range = start ... start + by
        let quads = polygonalChain.segments.map {
            revolve(lineSegment: $0, axis: axis, range: range)
        }
        return quads
    }
    return TrivialMesh(quads: quads)
}

public func revolve(lineSegment: LineSegment3D, axis: Line3D, range: ClosedRange<Angle>) -> Quad<SIMD3<Float>> {
    let p1 = revolve(point: lineSegment.start, axis: axis, range: range)
    let p2 = revolve(point: lineSegment.end, axis: axis, range: range)
    return .init(vertices: (p1.start, p1.end, p2.end, p2.start))
}

public func revolve(point: SIMD3<Float>, axis: Line3D, range: ClosedRange<Angle>) -> LineSegment3D {
    let center = axis.closest(to: point)
    let p1 = simd_quatf(angle: range.lowerBound, axis: axis.direction).act(point - center) + center
    let p2 = simd_quatf(angle: range.upperBound, axis: axis.direction).act(point - center) + center
    return .init(start: p1, end: p2)
}

public extension Line3D {
    func closest(to 𝑝0: SIMD3<Float>) -> SIMD3<Float> {
        // from: https://math.stackexchange.com/a/3223089
        let 𝑙0 = point
        let 𝑙 = direction
        let 𝑡𝑐𝑙𝑜𝑠𝑒𝑠𝑡 = simd.dot(𝑝0 - 𝑙0, 𝑙) / simd.dot(𝑙, 𝑙)
        let 𝑥𝑐𝑙𝑜𝑠𝑒𝑠𝑡 = 𝑙0 + 𝑡𝑐𝑙𝑜𝑠𝑒𝑠𝑡 * 𝑙
        return 𝑥𝑐𝑙𝑜𝑠𝑒𝑠𝑡
    }

    func intersects(plane: Plane3D) -> SIMD3<Float> {
        fatalError()
    }
}
