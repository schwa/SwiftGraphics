import SwiftUI
import Shapes2D
import CoreGraphicsSupport

struct ShapesDemoView: View {
    let triangle = Triangle([0, 150], [125, 0], [250, 150])

    var body: some View {
        HStack {
            ZStack {
                Path(triangle).stroke()
                Path.dot(triangle.vertices.0)
                Path.dot(triangle.vertices.1)
                Path.dot(triangle.vertices.2)
                Path.dot((triangle.vertices.0 + triangle.vertices.1) / 2).fill(.gray)
                Path.dot((triangle.vertices.1 + triangle.vertices.2) / 2).fill(.gray)
                Path.dot((triangle.vertices.2 + triangle.vertices.0) / 2).fill(.gray)
                Path(triangle.incircle).stroke(.indigo.opacity(0.5))
                Path(triangle.circumcircle).stroke(.pink.opacity(0.5))
                Path.dot(triangle.circumcenter).fill(.pink)
                Path.dot(triangle.incenter).fill(.indigo)
            }
            Form {
                Text("lengths.0: \(triangle.lengths.0, format: .number)")
                Text("lengths.1: \(triangle.lengths.1, format: .number)")
                Text("lengths.2: \(triangle.lengths.2, format: .number)")
                Text("angles.0: \(Angle.radians(triangle.angles.0), format: .angle)")
                Text("angles.1: \(Angle.radians(triangle.angles.1), format: .angle)")
                Text("angles.2: \(Angle.radians(triangle.angles.2), format: .angle)")
                Text("inradius: \(triangle.inradius, format: .number)")
                Text("area: \(triangle.area, format: .number)")
                Text("isAcute: \(triangle.isAcute, format: .bool)")
                Text("isObtuse: \(triangle.isObtuse, format: .bool)")
                Text("isOblique: \(triangle.isOblique, format: .bool)")
                Text("isScalene: \(triangle.isScalene, format: .bool)")
                Text("isIsosceles: \(triangle.isIsosceles, format: .bool)")
                Text("isDegenerate: \(triangle.isDegenerate, format: .bool)")
                Text("isEquilateral: \(triangle.isEquilateral, format: .bool)")
                Text("isRightAngled: \(triangle.isRightAngled, format: .bool)")
            }
        }
        .padding()
    }
}

#Preview {
    ShapesDemoView()
}

extension Path {
    static func dot(_ point: CGPoint) -> Path {
        Path.circle(center: point, radius: 4)
    }
    static func dot(x: Double, y: Double) -> Path {
        dot(CGPoint(x: x, y:y))
    }
}
