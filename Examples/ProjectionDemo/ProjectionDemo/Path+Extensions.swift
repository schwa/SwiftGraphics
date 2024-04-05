import Shapes3D
import SwiftUI

extension Path {
    var polygonalChains: [PolygonalChain<CGPoint>] {
        var polygons: [[CGPoint]] = []
        var current: [CGPoint] = []
        var lastPoint: CGPoint?
        for element in elements {
            switch element {
            case .move(let point):
                current.append(point)
                lastPoint = point
            case .line(let point):
                if current.isEmpty {
                    current = [lastPoint ?? .zero]
                }
                current.append(point)
                lastPoint = point
            case .quadCurve:
                fatalError()
            case .curve:
                fatalError()
            case .closeSubpath:
                if let first = current.first {
                    current.append(first)
                    polygons.append(current)
                }
                current = []
            }
        }
        if !current.isEmpty {
            polygons.append(current)
        }
        return polygons.map { .init(vertices: $0) }
    }
}
