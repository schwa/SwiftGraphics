import Algorithms
import CoreGraphics
import CoreGraphicsSupport
import CoreText
import earcut
import Everything
import GeometryX
import ModelIO
import Projection
import simd
import SIMDSupport
import SwiftUI
import UniformTypeIdentifiers

public struct Camera {
    public var transform: Transform
    public var target: SIMD3<Float> {
        didSet {
            let position = transform.translation // TODO: Scale?
            transform = Transform(look(at: position + target, from: position, up: [0, 1, 0]))
        }
    }

    public var projection: Projection

    public init(transform: Transform, target: SIMD3<Float>, projection: Projection) {
        self.transform = transform
        self.target = target
        self.projection = projection
    }
}

extension Camera: Equatable {
}

extension Camera: Sendable {
}

public extension Camera {
    var heading: SIMDSupport.Angle<Float> {
        get {
            let degrees = Angle(from: .zero, to: target.xz).degrees
            return Angle(degrees: degrees)
        }
        set {
            let length = target.length
            target = SIMD3<Float>(xz: SIMD2<Float>(length: length, angle: newValue))
        }
    }
}

extension [LineSegment<CGPoint>] {
    func extrude(minY: Float, maxY: Float) -> TrivialMesh<SIMD3<Float>> {
        var quads: [Quad<SIMD3<Float>>] = []
        forEach { segment in
            let from = SIMD2<Float>(segment.start)
            let to = SIMD2<Float>(segment.end)
            let quad = Quad(vertices: (
                SIMD3<Float>(from, minY),
                SIMD3<Float>(from, maxY),
                SIMD3<Float>(to, minY),
                SIMD3<Float>(to, maxY)
            ))
            quads.append(quad)
        }
        let mesh = TrivialMesh<SIMD3<Float>>(quads: quads)
        return mesh
    }
}

// extension Path {
//    func scaled(x: CGFloat, y: CGFloat) -> Path {
//        let transform = CGAffineTransform(translationX: -boundingRect.midX, y: -boundingRect.midY)
//            .concatenating(CGAffineTransform(scaleX: x, y: y))
//            .concatenating(CGAffineTransform(translationX: boundingRect.midX, y: boundingRect.midY))
//        return applying(transform)
//    }
// }

// extension Array where Element == CGPoint {
//    var rectangleAndAngle: (CGRect, Angle)? {
//        guard count == 4 else {
//            return nil
//        }
//        let mid = (self[0] + self[2]) / 2
//        let angle = Angle.radians(atan2(self[1].y - self[0].y, self[1].x - self[0].x))
//        let transform = CGAffineTransform(translationX: -mid.x, y: -mid.y)
//            .concatenating(CGAffineTransform(rotationAngle: -angle.radians))
//        let transformed = self.map { $0.applying(transform) }
//        let rectangle = CGRect(points: transformed)
//        return (rectangle.offsetBy(dx: mid.x, dy: mid.y), angle)
//    }
//
//    func toSVGPolygon() -> String {
//        let points = map { "\($0.x) \($0.y)" }.joined(separator: ",\n")
//        return """
//        <svg xmlns="http://www.w3.org/2000/svg">
//          <polygon points="\(points)" fill="none" stroke="red" />
//        </svg>
//        """
//    }
//
//    func rotate(angle: Angle) -> [CGPoint] {
//        let transform = CGAffineTransform(rotationAngle: angle.radians)
//        return map { $0.applying(transform) }
//    }
// }

// extension CGRect {
//    init(points: [CGPoint]) {
//        guard let first = points.first else {
//            self = .null
//            return
//        }
//        var r = CGRect(origin: first, size: .zero)
//        points.dropFirst().forEach { point in
//            r = r.union(CGRect(origin: point, size: .zero))
//        }
//        self = r
//    }
//
//    var vertices: [CGPoint] {
//        return [
//            CGPoint(x: minX, y: maxY),
//            CGPoint(x: maxX, y: maxY),
//            CGPoint(x: maxX, y: minY),
//            CGPoint(x: minX, y: minY),
//        ]
//    }
//
////    func vertices(rotated angle: Angle) -> [CGPoint] {
////        let transform = CGAffineTransform(translationX: -midX, y: -midY)
////            .concatenating(CGAffineTransform(rotationAngle: angle.radians))
////            .concatenating(CGAffineTransform(translationX: midX, y: midY))
////        return vertices.map {
////            $0.applying(transform)
////        }
////    }
// }

extension [LineSegment<CGPoint>] {
    var polygon: [CGPoint] {
        guard let first else {
            return []
        }
        return [first.start] + dropFirst().map(\.end)
    }
}

extension Array {
    var mutableLast: Element? {
        get {
            last
        }
        set {
            precondition(last != nil)
            if let newValue {
                self[index(before: endIndex)] = newValue
            }
            else {
                _ = popLast()
            }
        }
    }
}

extension Path3D {
    init(path: Path) {
        let elements = path.elements
        self = Path3D { path in
            for element in elements {
                switch element {
                case .move(let point):
                    path.move(to: SIMD3(xy: SIMD2(point)))
                case .line(let point):
                    path.addLine(to: SIMD3(xy: SIMD2(point)))
                case .closeSubpath:
                    path.closePath()
                default:
                    fatalError("Unimplemented")
                }
            }
        }
    }
}

extension Path {
    static func star(points: Int, innerRadius: Double, outerRadius: Double) -> Path {
        var path = Path()
        assert(points > 1, "Number of points should be greater than 1 for a star")
        var angle = -0.5 * .pi // Starting from the top
        for n in 0 ..< points * 2 {
            let radius = n % 2 == 0 ? outerRadius : innerRadius
            let point = CGPoint(x: radius * cos(angle), y: radius * sin(angle))
            if path.isEmpty {
                path.move(to: point)
            }
            else {
                path.addLine(to: point)
            }
            angle += .pi / Double(points)
        }
        path.closeSubpath()
        return path
    }
}

public extension SIMD3 where Scalar: BinaryFloatingPoint {
    init(xy: SIMD2<Scalar>) {
        self = SIMD3(xy[0], xy[1], 0)
    }
}

extension UTType {
    static let plyFile = UTType(importedAs: "public.polygon-file-format")
}
