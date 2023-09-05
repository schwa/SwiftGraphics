import CoreGraphics
import Foundation
import SwiftUI
import Geometry

public protocol Pathable {
    func toPath() throws -> Path
}

// MARK: -

extension Arc: Pathable {
    public func toPath() -> Path {
        toBezierChain().toPath()
    }
}

extension BezierCurve: Pathable {
    public func toPath() -> Path {
        guard let start else {
            fatalError("Unimplemented")
        }
        var path = Path()
        path.move(to: start)
        path.add(curve: self)
        return path
    }
}

extension BezierCurveChain: Pathable {
}

extension Circle: Pathable {
    public func toPath() -> Path {
        toBezierChain().toPath()

//        // TODO: It would be better if we didn't move _and_ we closed this path!!!
//
//        let curves = toBezierCurves()
//
//        var path = Path()
//
//        path.move(curves.0.start!)
//        path.add(curve: curves.0)
//
//        path.move(curves.1.start!)
//        path.add(curve: curves.1)
//
//        path.move(curves.2.start!)
//        path.add(curve: curves.2)
//
//        path.move(curves.3.start!)
//        path.add(curve: curves.3)
//        return path
    }
}

extension Ellipse: Pathable {
    public func toPath() -> Path {
        toBezierChain().toPath()
    }
}

// Line

//extension LineSegment: Pathable {
//    public func toPath() -> Path {
//        Path(vertices: [first, second])
//    }
//}
//
//extension LineString: Pathable {
//    public func toPath() -> Path {
//        Path(vertices: points)
//    }
//}

// TODO: FIXME

//extension Polygon: Pathable {
//    public func toPath() -> Path {
//        Path(vertices: points, closed: true)
//    }
//}

// TODO: FIXME
//extension RegularPolygon: Pathable {
//    public func toPath() -> Path {
//        Path(vertices: points, closed: true)
//    }
//}

//extension Triangle: Pathable {
//    public func toPath() -> Path {
//        Path(vertices: points, closed: true)
//    }
//}
//
//public extension CGContext {
//    @available(*, deprecated, message: "Use SwiftUI.Canvas")
//    func add(_ element: some Pathable) {
//        forceTry {
//            let path = try element.toPath()
//            let cgPath = path.cgPath
//            addPath(cgPath)
//        }
//    }
//}
