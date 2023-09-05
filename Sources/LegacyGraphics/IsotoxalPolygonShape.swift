import SwiftUI

public struct IsotoxalPolygonShape: InsettableShape {
    let startAngle: Angle
    let vertexCount: Int
    let ratio: Double
    let inset: CGFloat

    public init(vertexCount: Int, ratio: Double = 0.666, startAngle: Angle = .zero) {
        self.startAngle = startAngle
        self.vertexCount = vertexCount
        self.ratio = ratio
        inset = 0
    }

    init(vertexCount: Int, ratio: Double = 0.666, startAngle: Angle = .zero, inset: CGFloat = 0) {
        self.startAngle = startAngle
        self.vertexCount = vertexCount
        self.ratio = ratio
        self.inset = inset
    }

    public var vertices: [CGPoint] {
        (0 ..< (vertexCount)).map { index in
            let angle = Double(index) / Double(vertexCount) * .pi * 2 + startAngle.radians
            let ratio = index.isMultiple(of: 2) ? self.ratio : 1.0
            let x = cos(angle) * ratio
            let y = sin(angle) * ratio
            return CGPoint(x: x, y: y)
        }
    }

    public func inset(by amount: CGFloat) -> IsotoxalPolygonShape {
        IsotoxalPolygonShape(vertexCount: vertexCount, ratio: ratio, startAngle: startAngle, inset: amount)
    }

    public func path(in rect: CGRect) -> Path {
        fatalError()
        // TODO: FIXME
//        Path { path in
//            let rect = rect.inset(dx: inset, dy: inset)
//            path.addLines(vertices.map { vertex in
//                ((vertex * CGPoint(rect.size)) * 0.5) + rect.midXMidY
//            })
//            path.closeSubpath()
//        }
    }
}
