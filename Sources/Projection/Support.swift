import simd
import SIMDSupport
import SwiftUI

//extension simd_float4x4 {
//    var translation: SIMD3<Float> {
//        columns.3.xyz
//    }
//}
//
//extension SIMD4 {
//    var xyz: SIMD3<Scalar> {
//        [x, y, z]
//    }
//}

extension GraphicsContext.Shading {
    static func color(_ rgb: SIMD3<Float>) -> Self {
        .color(Color(red: Double(rgb.x), green: Double(rgb.y), blue: Double(rgb.z)))
    }
}

public extension GraphicsContext3D {
    func drawAxisMarkers(labels: Bool = true) {
        // TODO: Really this should use line3d and clip to context.
        for axis in Axis3D.allCases {
            stroke(path: Path3D { path in
                path.move(to: axis.vector * -5)
                path.addLine(to: axis.vector * 5)
            }, with: .color(axis.color))
            if labels {
                let negativeAxisLabel = Text("-\(axis)").font(.caption)
                graphicsContext2D.draw(negativeAxisLabel, at: projection.worldSpaceToScreenSpace(axis.vector * -5))
                let positiveAxisLabel = Text("+\(axis)").font(.caption)
                graphicsContext2D.draw(positiveAxisLabel, at: projection.worldSpaceToScreenSpace(axis.vector * +5))
            }
        }
    }
}
