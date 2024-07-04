import CoreGraphicsSupport
import simd
import SIMDSupport
import SwiftUI

struct MapInspector: View {
    @Binding
    var cameraTransform: Transform

    var models: [SIMD3<Float>]

    var body: some View {
        Canvas { context, size in
            context.translateBy(x: size.width / 2, y: size.height / 2)
            context.stroke(Path { path in
                path.addLines([[-size.width / 2, 0], [size.width / 2, 0]])
            }, with: .color(.red))
            context.stroke(Path { path in
                path.addLines([[0, -size.height / 2], [0, size.height / 2]])
            }, with: .color(.blue))
            context.fill(Path(ellipseIn: CGRect(center: .zero, radius: 4)), with: .color(.red))

            let cameraPosition = CGPoint(cameraTransform.translation.xz) * [5, 5]
            context.fill(Path(ellipseIn: CGRect(center: cameraPosition, radius: 4)), with: .color(.yellow))

            context.stroke(Path { path in
                path.move(to: cameraPosition)
                let unit = cameraTransform.matrix * SIMD4<Float>(0, 1, 0, -1)
                //                path.addLine(to: cameraPosition + CGPoint(unit.xz) * -2)
                path.addLine(to: CGPoint(unit.xz) * 2, relative: true)
            }, with: .color(.yellow), lineWidth: 2)
        }
        .background(.black)
    }
}
