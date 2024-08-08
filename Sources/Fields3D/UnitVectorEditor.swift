import Shapes2D
import simd
import SwiftUI
import SwiftUISupport

public struct UnitVectorEditor: View {
    @Binding
    var vector: SIMD3<Float>

    @State
    private var size: CGSize = .zero

    public init(vector: Binding<SIMD3<Float>>) {
        self._vector = vector
    }

    public var body: some View {
        let rect = CGRect(origin: .zero, size: size).insetBy(dx: 5, dy: 5)
        let triangle = Triangle(CGPoint(rect.minX, rect.maxY), CGPoint(rect.midX, rect.minY), CGPoint(rect.maxX, rect.maxY))

        Canvas { context, _ in
            context.fill(triangle.path, with: .color(.secondary.opacity(0.5)))
            context.stroke(triangle.path, with: .color(.white.opacity(0.9)))
        }
        .coordinateSpace(NamedCoordinateSpace.named("FOO"))
        .overlay {
            Circle()
            .fill(Color.accentColor)
            .frame(width: 8)
            .padding()
            .contentShape(Circle())
            .position(triangle.toCartesian((Double(vector.x), Double(vector.y), Double(vector.z))))
            .gesture(drag(triangle: triangle))
        }
        .onGeometryChange(for: CGSize.self, of: \.size, action: { size = $0 })
        .aspectRatio(sqrt(3 / 2), contentMode: .fit)
        .onSpatialTapGesture { value in
            let location = triangle.clamp(value.location)
            let trilinear = triangle.toTrilinear(location)
            vector = SIMD3<Float>(Float(trilinear.0), Float(trilinear.1), Float(trilinear.2)).normalized
        }
    }

    func drag(triangle: Triangle) -> some Gesture {
        DragGesture(coordinateSpace: NamedCoordinateSpace.named("FOO")).onChanged { value in
            let location = triangle.clamp(value.location)
            let trilinear = triangle.toTrilinear(location)
            vector = SIMD3<Float>(Float(trilinear.0), Float(trilinear.1), Float(trilinear.2)).normalized
        }
    }
}

#Preview {
    @Previewable @State var vector: SIMD3<Float> = [0, 1, 0]

    VStack {
        UnitVectorEditor(vector: $vector)
        .frame(width: 60)
        Text("Vector: (\(vector.x), \(vector.y), \(vector.z))")
    }
}
