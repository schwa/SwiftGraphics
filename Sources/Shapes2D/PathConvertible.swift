import CoreGraphics
import Foundation
import SwiftUI

public protocol PathConvertible {
    var path: Path { get }
}

public extension Path {
    init(_ other: some PathConvertible) {
        self = other.path
    }
}

extension LineSegment: PathConvertible {
    public var path: Path {
        Path { path in
            path.addLines([start, end])
        }
    }
}

extension Circle: PathConvertible {
    public var path: Path {
        Path.circle(center: center, radius: radius)
    }
}

extension Polygon: PathConvertible {
    public var path: Path {
        Path.lines(vertices, closed: true)
    }
}

//extension RegularPolygon: PathConvertible {
//    public var path: Path {
//        Path.lines(vertices, closed: true)
//    }
//}

extension Triangle: PathConvertible {
    public var path: Path {
        Path.lines([vertices.0, vertices.1, vertices.2], closed: true)
    }
}
