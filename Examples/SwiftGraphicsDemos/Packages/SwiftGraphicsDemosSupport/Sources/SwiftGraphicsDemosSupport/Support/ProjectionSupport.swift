import Algorithms
import CoreGraphics
import CoreGraphicsSupport
import CoreText
import Earcut
import ModelIO
import Projection
import Shapes3D
import simd
import SIMDSupport
import SwiftUI
import UniformTypeIdentifiers

@available(*, deprecated, message: "Use scene graphs instead.")
public struct Camera {
    public var transform: Transform

    // TODO: Deprecate
    // @available(*, deprecated, message: "We can't generate this from any transform. Maybe move target into transform rotation?")
    public var target: SIMD3<Float> {
        didSet {
            let position = transform.translation // TODO: Scale?
            transform = Transform(look(at: position + target, from: position, up: [0, 1, 0]))
        }
    }

    public var projection: Projection
}

extension Camera: Equatable {
}

extension Camera: Sendable {
}

public extension Camera {
    var heading: Angle {
        get {
            let degrees = Angle(from: .zero, to: CGPoint(target.xz)).degrees
            return Angle(degrees: degrees)
        }
        set {
            let length = target.length
            target = SIMD3<Float>(xz: SIMD2<Float>(length: length, angle: newValue))
        }
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

extension UTType {
    static let plyFile = UTType(importedAs: "public.polygon-file-format")
}
