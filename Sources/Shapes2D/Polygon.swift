import Foundation

struct Polygon {
    var vertices: [CGPoint]

    init(_ vertices: [CGPoint]) {
        self.vertices = vertices
    }
}

extension Polygon {
    func transformed(by transform: CGAffineTransform) -> Polygon {
        .init(vertices.map { $0.applying(transform) })
    }
}

//- Boolean algebra
//- Offset
//- Mirror
//- "Fill" spine
//- Extrude
//- isSimple
//- isConvex
//- isConcave
//- Equiangular: all corner angles are equal.
//- Equilateral: all edges are of the same length.
//- Regular: both equilateral and equiangular.
//- cyclic
