import CoreGraphics
import Foundation
import Shapes2D
import SwiftUI

enum MyShape: Codable {
    case line(LineSegment)
    case circle(Shapes2D.Circle)
}

extension MyShape: PathConvertible {
    var path: Path {
        switch self {
        case .line(let shape):
            Path(shape)
        case .circle(let shape):
            Path(shape)
        }
    }
}

extension MyShape {
    func contains(_ point: CGPoint) -> Bool {
        Path(self).contains(point)
    }

    func contains(_ point: CGPoint, lineWidth: Double) -> Bool {
        Path(self).strokedPath(.init(lineWidth: lineWidth)).contains(point)
    }
}

extension MyShape {
    var controlPoints: [CGPoint] {
        get {
            switch self {
            case .line(let shape):
                [shape.start, shape.end]
            case .circle(let shape):
                [shape.center]
            }
        }
        set {
            switch self {
            case .line:
                self = .line(.init(newValue[0], newValue[1]))
            case .circle(let shape):
                self = .circle(.init(center: newValue[0], radius: shape.radius))
            }
        }
    }
}
