import CoreGraphics

public protocol VerticesConvertible {
    var vertices: [CGPoint] { get }
}

extension LineSegment: VerticesConvertible {
    public var vertices: [CGPoint] {
        [start, end]
    }
}

extension Polygon: VerticesConvertible {
}
